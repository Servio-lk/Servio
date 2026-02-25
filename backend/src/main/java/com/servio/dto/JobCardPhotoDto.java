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
public class JobCardPhotoDto {
    private Long id;
    private Long jobCardId;
    private String photoUrl;
    private String description;
    private String photoType;
    private Long uploadedById;
    private String uploadedByName;
    private LocalDateTime createdAt;
}
