package com.nexpos.admin.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nexpos.core.data.api.NexPosApi
import com.nexpos.core.data.local.SessionManager
import com.nexpos.core.data.model.DeviceInfo
import com.nexpos.core.data.model.ForceLogoutRequest
import com.nexpos.core.data.model.UpdateDeviceRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.io.IOException
import javax.inject.Inject

data class DeviceUiState(
    val isLoading: Boolean = false,
    val devices: List<DeviceInfo> = emptyList(),
    val error: String? = null,
    val message: String? = null
)

@HiltViewModel
class DeviceViewModel @Inject constructor(
    private val api: NexPosApi,
    private val session: SessionManager
) : ViewModel() {

    private val _state = MutableStateFlow(DeviceUiState())
    val state: StateFlow<DeviceUiState> = _state

    init { loadDevices() }

    private fun deviceKey(device: DeviceInfo): String {
        // Gunakan device_id (UUID) jika tersedia, fallback ke numeric id
        val byDeviceId = device.deviceId.takeIf { it.isNotBlank() }
        val byId = if (device.id > 0) device.id.toString() else null
        return byDeviceId ?: byId ?: device.id.toString()
    }

    private fun makeForceLogoutRequest(device: DeviceInfo): ForceLogoutRequest {
        val numericId = if (device.id > 0) device.id.toString() else ""
        val deviceUuid = device.deviceId.trim()
        // Kirim keduanya agar server bisa pilih yang cocok
        return ForceLogoutRequest(deviceId = deviceUuid.ifBlank { numericId }, id = numericId)
    }

    fun loadDevices() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val tokenRaw = session.getToken()
                if (tokenRaw.isNullOrEmpty()) {
                    _state.value = DeviceUiState(error = "Sesi tidak valid")
                    return@launch
                }
                val token = "Bearer $tokenRaw"
                val res = api.getDevices(token)
                if (res.isSuccessful) {
                    _state.value = DeviceUiState(devices = res.body()?.devices ?: emptyList())
                } else {
                    _state.value = DeviceUiState(error = "Gagal memuat daftar device (${res.code()})")
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: IOException) {
                _state.value = _state.value.copy(isLoading = false, error = "Gagal terhubung ke server. Periksa koneksi internet.")
            } catch (e: Exception) {
                val detail = e.message?.take(120) ?: e.javaClass.simpleName
                _state.value = _state.value.copy(isLoading = false, error = "Gagal memuat device: $detail")
            }
        }
    }

    fun forceLogout(device: DeviceInfo) {
        viewModelScope.launch {
            _state.value = _state.value.copy(error = null)
            try {
                val tokenRaw = session.getToken()
                if (tokenRaw.isNullOrEmpty()) {
                    _state.value = _state.value.copy(error = "Sesi tidak valid")
                    return@launch
                }
                val token = "Bearer $tokenRaw"
                val res = api.forceLogout(token, makeForceLogoutRequest(device))
                if (res.isSuccessful) {
                    _state.value = _state.value.copy(message = "Device berhasil di-force logout")
                    loadDevices()
                } else {
                    val msg = when (res.code()) {
                        404 -> "Device tidak ditemukan"
                        else -> "Gagal force logout device (${res.code()})"
                    }
                    _state.value = _state.value.copy(error = msg)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: IOException) {
                _state.value = _state.value.copy(error = "Gagal terhubung ke server. Periksa koneksi internet.")
            } catch (e: Exception) {
                val detail = e.message?.take(120) ?: e.javaClass.simpleName
                _state.value = _state.value.copy(error = "Gagal force logout: $detail")
            }
        }
    }

    fun deleteDevice(device: DeviceInfo) {
        viewModelScope.launch {
            _state.value = _state.value.copy(error = null)
            try {
                val tokenRaw = session.getToken()
                if (tokenRaw.isNullOrEmpty()) {
                    _state.value = _state.value.copy(error = "Sesi tidak valid")
                    return@launch
                }
                val token = "Bearer $tokenRaw"
                val res = api.deleteDevice(token, deviceKey(device))
                if (res.isSuccessful) {
                    _state.value = _state.value.copy(message = "Device berhasil dihapus")
                    loadDevices()
                } else {
                    val msg = when (res.code()) {
                        404 -> "Device tidak ditemukan"
                        else -> "Gagal menghapus device (${res.code()})"
                    }
                    _state.value = _state.value.copy(error = msg)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: IOException) {
                _state.value = _state.value.copy(error = "Gagal terhubung ke server. Periksa koneksi internet.")
            } catch (e: Exception) {
                val detail = e.message?.take(120) ?: e.javaClass.simpleName
                _state.value = _state.value.copy(error = "Gagal menghapus device: $detail")
            }
        }
    }

    fun updateDevice(device: DeviceInfo, newName: String) {
        if (newName.isBlank()) {
            _state.value = _state.value.copy(error = "Nama device tidak boleh kosong")
            return
        }
        viewModelScope.launch {
            _state.value = _state.value.copy(error = null)
            try {
                val tokenRaw = session.getToken()
                if (tokenRaw.isNullOrEmpty()) {
                    _state.value = _state.value.copy(error = "Sesi tidak valid")
                    return@launch
                }
                val token = "Bearer $tokenRaw"
                val res = api.updateDevice(token, deviceKey(device), UpdateDeviceRequest(newName.trim()))
                if (res.isSuccessful) {
                    _state.value = _state.value.copy(message = "Nama device berhasil diperbarui")
                    loadDevices()
                } else {
                    val msg = when (res.code()) {
                        404 -> "Device tidak ditemukan"
                        400 -> "Nama device tidak valid"
                        else -> "Gagal memperbarui device (${res.code()})"
                    }
                    _state.value = _state.value.copy(error = msg)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: IOException) {
                _state.value = _state.value.copy(error = "Gagal terhubung ke server. Periksa koneksi internet.")
            } catch (e: Exception) {
                val detail = e.message?.take(120) ?: e.javaClass.simpleName
                _state.value = _state.value.copy(error = "Gagal memperbarui device: $detail")
            }
        }
    }

    fun clearMessage() { _state.value = _state.value.copy(message = null, error = null) }
}
