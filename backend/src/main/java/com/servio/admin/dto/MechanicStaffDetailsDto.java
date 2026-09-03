package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicStaffDetailsDto {
    private Long id;
    private String employeeCode;
    private String branch;
    private String jobTitle;
    private String employmentType;
    private LocalDate joiningDate;
    private String skillTags;
    private String nicNumber;
    private String passportNumber;
    private LocalDate dateOfBirth;
    private String gender;
    private String drivingLicenseNumber;
    private String licenseClasses;
    private LocalDate licenseExpiryDate;
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String district;
    private String postalCode;
    private String emergencyContactName;
    private String emergencyContactRelationship;
    private String emergencyContactPhone;
    private String bankName;
    private String bankBranch;
    private String accountHolderName;
    private String accountNumber;
    private String epfNumber;
    private String etfNumber;
}
