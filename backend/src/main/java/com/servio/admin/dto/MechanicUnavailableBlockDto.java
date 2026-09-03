package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicUnavailableBlockDto {
    private Long id;
    private LocalDateTime startsAt;
    private LocalDateTime endsAt;
    private String reason;
}
