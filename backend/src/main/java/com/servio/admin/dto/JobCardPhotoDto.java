package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobCardPhotoDto {
    private Long id;
    private Long jobCardId;
    private String photoUrl;
    private String description;
    private String photoType;
    private UUID uploadedById;
    private String uploadedByName;
    private LocalDateTime createdAt;
}
