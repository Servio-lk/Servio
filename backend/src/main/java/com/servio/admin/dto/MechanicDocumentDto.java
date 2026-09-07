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
public class MechanicDocumentDto {
    private Long id;
    private String documentType;
    private String originalFilename;
    private String url;
    private String publicId;
    private String resourceType;
    private String contentType;
    private Long bytes;
    private LocalDateTime uploadedAt;
}
