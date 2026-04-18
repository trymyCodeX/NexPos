package com.nexpos.core.data.api

import com.nexpos.core.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface NexPosApi {

    @GET("/api/healthz")
    suspend fun healthCheck(): Response<HealthResponse>

    @POST("/api/auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST("/api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @POST("/api/auth/login-device")
    suspend fun loginDevice(@Body request: DeviceLoginRequest): Response<AuthResponse>

    @POST("/api/auth/forgot-password")
    suspend fun forgotPassword(@Body request: ForgotPasswordRequest): Response<ForgotPasswordResponse>

    @POST("/api/auth/verify-otp")
    suspend fun verifyOtp(@Body request: VerifyOtpRequest): Response<VerifyOtpResponse>

    @POST("/api/auth/reset-password")
    suspend fun resetPassword(@Body request: ResetPasswordRequest): Response<MessageResponse>

    @DELETE("/api/auth/account")
    suspend fun deleteAccount(@Header("Authorization") token: String): Response<MessageResponse>

    @PUT("/api/auth/change-password")
    suspend fun changePassword(
        @Header("Authorization") token: String,
        @Body request: ChangePasswordRequest
    ): Response<MessageResponse>

    @GET("/api/outlets")
    suspend fun getOutlets(@Header("Authorization") token: String): Response<OutletListResponse>

    @POST("/api/outlets")
    suspend fun createOutlet(
        @Header("Authorization") token: String,
        @Body request: CreateOutletRequest
    ): Response<OutletResponse>

    @PUT("/api/outlets/{id}")
    suspend fun updateOutlet(
        @Header("Authorization") token: String,
        @Path("id") outletId: Int,
        @Body request: UpdateOutletRequest
    ): Response<MessageResponse>

    @DELETE("/api/outlets/{id}")
    suspend fun deleteOutlet(
        @Header("Authorization") token: String,
        @Path("id") outletId: Int
    ): Response<MessageResponse>

    @GET("/api/devices")
    suspend fun getDevices(@Header("Authorization") token: String): Response<DeviceListResponse>

    @POST("/api/devices/heartbeat")
    suspend fun sendHeartbeat(
        @Header("Authorization") token: String,
        @Body request: HeartbeatRequest
    ): Response<MessageResponse>

    @POST("/api/devices/force-logout")
    suspend fun forceLogout(
        @Header("Authorization") token: String,
        @Body request: ForceLogoutRequest
    ): Response<MessageResponse>

    @PUT("/api/devices/{id}")
    suspend fun updateDevice(
        @Header("Authorization") token: String,
        @Path("id") deviceId: String,
        @Body request: UpdateDeviceRequest
    ): Response<MessageResponse>

    @DELETE("/api/devices/{id}")
    suspend fun deleteDevice(
        @Header("Authorization") token: String,
        @Path("id") deviceId: String
    ): Response<MessageResponse>

    @GET("/api/transactions")
    suspend fun getTransactions(
        @Header("Authorization") token: String,
        @Query("outletId") outletId: Int? = null
    ): Response<TransactionListResponse>

    @POST("/api/transactions")
    suspend fun createTransaction(
        @Header("Authorization") token: String,
        @Body request: CreateTransactionRequest
    ): Response<TransactionInfo>

    @DELETE("/api/transactions/{id}")
    suspend fun deleteTransaction(
        @Header("Authorization") token: String,
        @Path("id") transactionId: Int
    ): Response<MessageResponse>

    @GET("/api/services")
    suspend fun getServices(
        @Header("Authorization") token: String,
        @Query("outletId") outletId: Int? = null
    ): Response<ServiceListResponse>

    @POST("/api/services")
    suspend fun createService(
        @Header("Authorization") token: String,
        @Body request: CreateServiceRequest
    ): Response<ServiceResponse>

    @PUT("/api/services/{id}")
    suspend fun updateService(
        @Header("Authorization") token: String,
        @Path("id") serviceId: String,
        @Body request: UpdateServiceRequest
    ): Response<ServiceResponse>

    @DELETE("/api/services/{id}")
    suspend fun deleteService(
        @Header("Authorization") token: String,
        @Path("id") serviceId: String
    ): Response<MessageResponse>

    @GET("/api/customers")
    suspend fun getCustomers(
        @Header("Authorization") token: String,
        @Query("outletId") outletId: Int? = null
    ): Response<CustomerListResponse>

    @POST("/api/customers")
    suspend fun createCustomer(
        @Header("Authorization") token: String,
        @Body request: CreateCustomerRequest
    ): Response<CustomerResponse>

    @PUT("/api/customers/{id}")
    suspend fun updateCustomer(
        @Header("Authorization") token: String,
        @Path("id") customerId: String,
        @Body request: UpdateCustomerRequest
    ): Response<CustomerResponse>

    @DELETE("/api/customers/{id}")
    suspend fun deleteCustomer(
        @Header("Authorization") token: String,
        @Path("id") customerId: String
    ): Response<MessageResponse>

    @PUT("/api/transactions/status")
    suspend fun updateTransactionStatus(
        @Header("Authorization") token: String,
        @Body request: UpdateStatusRequest
    ): Response<TransactionInfo>

    @PUT("/api/transactions/{id}/status")
    suspend fun updateTransactionStatusById(
        @Header("Authorization") token: String,
        @Path("id") transactionId: Int,
        @Body request: StatusOnlyRequest
    ): Response<MessageResponse>

    @GET("/api/notifications")
    suspend fun getNotifications(@Header("Authorization") token: String): Response<NotificationListResponse>

    @POST("/api/notifications/{id}/read")
    suspend fun markNotificationRead(
        @Header("Authorization") token: String,
        @Path("id") notificationId: Int
    ): Response<MessageResponse>

    @GET("/api/reports/summary")
    suspend fun getReportSummary(
        @Header("Authorization") token: String,
        @Query("outletId") outletId: Int? = null
    ): Response<ReportSummary>

    @GET("/api/reports/daily")
    suspend fun getReportDaily(
        @Header("Authorization") token: String,
        @Query("outletId") outletId: Int? = null
    ): Response<DailySummaryResponse>

    @POST("/api/super-admin/login")
    suspend fun superAdminLogin(@Body request: SuperAdminLoginRequest): Response<SuperAdminLoginResponse>

    @GET("/api/super-admin/stats")
    suspend fun getSuperAdminStats(@Header("Authorization") token: String): Response<SuperAdminStatsResponse>

    @GET("/api/super-admin/users")
    suspend fun getSuperAdminUsers(@Header("Authorization") token: String): Response<SuperAdminUsersResponse>

    @GET("/api/super-admin/otp-requests")
    suspend fun getSuperAdminOtpRequests(@Header("Authorization") token: String): Response<OtpRequestsResponse>

    @POST("/api/super-admin/users/{id}/ban")
    suspend fun banSuperAdminUser(
        @Header("Authorization") token: String,
        @Path("id") userId: String,
        @Body request: BanUserRequest
    ): Response<MessageResponse>

    @POST("/api/super-admin/users/{id}/unban")
    suspend fun unbanSuperAdminUser(
        @Header("Authorization") token: String,
        @Path("id") userId: String
    ): Response<MessageResponse>

    @DELETE("/api/super-admin/users/{id}")
    suspend fun deleteSuperAdminUser(
        @Header("Authorization") token: String,
        @Path("id") userId: String
    ): Response<MessageResponse>

    @POST("/api/super-admin/notifications")
    suspend fun createSuperAdminNotification(
        @Header("Authorization") token: String,
        @Body request: CreateNotificationRequest
    ): Response<MessageResponse>
}
