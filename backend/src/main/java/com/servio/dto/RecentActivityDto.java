package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecentActivityDto {
    private String activityType; // APPOINTMENT, PAYMENT, REVIEW, USER_SIGNUP
    private String description;
    private String userName;
    private LocalDateTime timestamp;
}
