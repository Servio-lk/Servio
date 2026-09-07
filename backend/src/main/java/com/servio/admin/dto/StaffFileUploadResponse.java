package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StaffFileUploadResponse {
    private String url;
    private String publicId;
    private String resourceType;
    private String originalFilename;
    private String contentType;
    private Long bytes;
    private String documentType;
}
