package com.servio.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AppointmentUpdateRequest {

    @NotBlank(message = "Status is required")
    @Pattern(regexp = "PENDING|CONFIRMED|IN_PROGRESS|COMPLETED|CANCELLED",
             message = "Status must be PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, or CANCELLED")
    private String status;

    private String notes;

    private BigDecimal actualCost;
}
