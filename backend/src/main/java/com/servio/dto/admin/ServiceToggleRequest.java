package com.servio.dto.admin;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceToggleRequest {

    @NotNull(message = "isActive field is required")
    private Boolean isActive;
}
