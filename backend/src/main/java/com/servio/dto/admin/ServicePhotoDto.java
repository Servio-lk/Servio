package com.servio.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ServicePhotoDto {
    private Long id;
    private String url;
    private String publicId;
    private Integer displayOrder;
    private Boolean isPrimary;
}
