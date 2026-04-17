package com.nexpos.admin.ui.screens.devices

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.nexpos.admin.ui.viewmodel.DeviceViewModel
import com.nexpos.core.data.model.DeviceInfo
import com.nexpos.core.ui.components.LoadingScreen
import com.nexpos.core.ui.components.StatusChip

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DevicesScreen(
    onNavigateBack: () -> Unit,
    viewModel: DeviceViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    var deviceToLogout by remember { mutableStateOf<DeviceInfo?>(null) }
    var deviceToDelete by remember { mutableStateOf<DeviceInfo?>(null) }
    var deviceToEdit by remember { mutableStateOf<DeviceInfo?>(null) }
    var editName by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        viewModel.loadDevices()
    }

    LaunchedEffect(state.message) {
        if (state.message != null) viewModel.clearMessage()
    }

    // Dialog Force Logout
    deviceToLogout?.let { device ->
        AlertDialog(
            onDismissRequest = { deviceToLogout = null },
            title = { Text("Force Logout Device") },
            text = { Text("Yakin ingin paksa logout device '${device.deviceName}'? Token device akan dihapus dan device harus login ulang.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.forceLogout(device.id)
                        deviceToLogout = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) { Text("Force Logout") }
            },
            dismissButton = {
                TextButton(onClick = { deviceToLogout = null }) { Text("Batal") }
            }
        )
    }

    // Dialog Hapus Device
    deviceToDelete?.let { device ->
        AlertDialog(
            onDismissRequest = { deviceToDelete = null },
            title = { Text("Hapus Device") },
            text = { Text("Yakin ingin menghapus device '${device.deviceName}'? Tindakan ini tidak dapat dibatalkan.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteDevice(device.id)
                        deviceToDelete = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) { Text("Hapus") }
            },
            dismissButton = {
                TextButton(onClick = { deviceToDelete = null }) { Text("Batal") }
            }
        )
    }

    // Dialog Edit Nama Device
    deviceToEdit?.let { device ->
        AlertDialog(
            onDismissRequest = { deviceToEdit = null },
            title = { Text("Edit Nama Device") },
            text = {
                OutlinedTextField(
                    value = editName,
                    onValueChange = { editName = it },
                    label = { Text("Nama Device") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.updateDevice(device.id, editName)
                        deviceToEdit = null
                    },
                    enabled = editName.isNotBlank()
                ) { Text("Simpan") }
            },
            dismissButton = {
                TextButton(onClick = { deviceToEdit = null }) { Text("Batal") }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Monitor Device") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Kembali")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary,
                    navigationIconContentColor = MaterialTheme.colorScheme.onPrimary
                ),
                actions = {
                    IconButton(onClick = { viewModel.loadDevices() }) {
                        Icon(Icons.Default.Refresh, "Refresh", tint = MaterialTheme.colorScheme.onPrimary)
                    }
                }
            )
        }
    ) { padding ->
        if (state.isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(padding)) {
                LoadingScreen("Memuat device...")
            }
        } else if (state.devices.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.PhoneAndroid, null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Belum ada device terdaftar")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        val online = state.devices.count { it.status == "online" }
                        val offline = state.devices.count { it.status != "online" }
                        Surface(shape = MaterialTheme.shapes.small, color = MaterialTheme.colorScheme.secondaryContainer) {
                            Text("Online: $online", modifier = Modifier.padding(8.dp, 4.dp), color = MaterialTheme.colorScheme.onSecondaryContainer, style = MaterialTheme.typography.labelMedium)
                        }
                        Surface(shape = MaterialTheme.shapes.small, color = MaterialTheme.colorScheme.errorContainer) {
                            Text("Offline: $offline", modifier = Modifier.padding(8.dp, 4.dp), color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.labelMedium)
                        }
                    }
                }

                state.error?.let { err ->
                    item {
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                            Text(err, modifier = Modifier.padding(12.dp), color = MaterialTheme.colorScheme.onErrorContainer)
                        }
                    }
                }

                state.message?.let { msg ->
                    item {
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer)) {
                            Text(msg, modifier = Modifier.padding(12.dp), color = MaterialTheme.colorScheme.onSecondaryContainer)
                        }
                    }
                }

                items(state.devices) { device ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.PhoneAndroid,
                                    null,
                                    tint = if (device.status == "online") MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.error,
                                    modifier = Modifier.size(32.dp)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(device.deviceName, fontWeight = FontWeight.Bold)
                                    Text(
                                        device.outletName ?: "Outlet tidak diketahui",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    device.lastSeen?.let {
                                        Text("Terakhir: $it", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                                StatusChip(status = device.status)
                            }

                            Spacer(modifier = Modifier.height(12.dp))
                            Divider()
                            Spacer(modifier = Modifier.height(8.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                // Tombol Edit
                                OutlinedButton(
                                    onClick = {
                                        editName = device.deviceName
                                        deviceToEdit = device
                                    },
                                    modifier = Modifier.weight(1f),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp)
                                ) {
                                    Icon(Icons.Default.Edit, null, modifier = Modifier.size(14.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Edit", style = MaterialTheme.typography.labelSmall)
                                }

                                // Tombol Force Logout (semua device, online maupun offline)
                                OutlinedButton(
                                    onClick = { deviceToLogout = device },
                                    modifier = Modifier.weight(1f),
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp)
                                ) {
                                    Icon(Icons.Default.Logout, null, modifier = Modifier.size(14.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Force Logout", style = MaterialTheme.typography.labelSmall)
                                }

                                // Tombol Hapus
                                OutlinedButton(
                                    onClick = { deviceToDelete = device },
                                    modifier = Modifier.weight(1f),
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp)
                                ) {
                                    Icon(Icons.Default.Delete, null, modifier = Modifier.size(14.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Hapus", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
