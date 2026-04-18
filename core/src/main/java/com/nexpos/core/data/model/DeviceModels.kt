package com.nexpos.core.data.model

data class DeviceListResponse(
    val devices: List<DeviceInfo>
)

data class HeartbeatRequest(
    val deviceId: String
)

data class ForceLogoutRequest(
    val deviceId: String,
    val id: String = ""
)

data class UpdateDeviceRequest(
    val deviceName: String
)

data class MessageResponse(
    val message: String
)
