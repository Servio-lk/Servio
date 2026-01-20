package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceReminderDto {
    private String serviceType;
    private String description;
    private LocalDate dueDate;
    private String priority; // HIGH, MEDIUM, LOW
}
