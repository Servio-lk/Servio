package com.servio.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@NoArgsConstructor
@AllArgsConstructor
public class AppointmentUpdateRequest {

    @NotBlank(message = "Status is required")
    @Pattern(regexp = "PENDING|CONFIRMED|IN_PROGRESS|COMPLETED|CANCELLED",
             message = "Status must be PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, or CANCELLED")
    private String status;

    private String notes;

    private BigDecimal actualCost;

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public BigDecimal getActualCost() { return actualCost; }
    public void setActualCost(BigDecimal actualCost) { this.actualCost = actualCost; }
}


