package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicDto {
    private Long id;
    private String fullName;
    private String email;
    private String phone;
    private String specialization;
    private Integer experienceYears;
    private String status;
    private Boolean isActive;
    private Long activeJobCount;
    private String employeeCode;
    private String branch;
    private String jobTitle;
    private String profilePhotoUrl;
    private MechanicStaffDetailsDto details;
    private List<MechanicDocumentDto> documents;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
