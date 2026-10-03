package com.servio.booking.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppointmentQrCheckInRequest {
    @NotBlank(message = "QR data is required")
    private String qrData;

    private String notes;
}
