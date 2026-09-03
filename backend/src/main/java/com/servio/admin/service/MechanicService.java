package com.servio.admin.service;


import com.servio.admin.dto.MechanicDto;
import com.servio.admin.dto.MechanicDocumentDto;
import com.servio.admin.dto.MechanicRegistrationLookupDto;
import com.servio.admin.dto.MechanicStaffDetailsDto;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.entity.MechanicDocument;
import com.servio.admin.entity.MechanicStaffDetails;
import com.servio.admin.entity.MechanicStatus;
import com.servio.admin.repository.MechanicDocumentRepository;
import com.servio.admin.repository.MechanicRepository;
import com.servio.admin.repository.MechanicStaffDetailsRepository;
import com.servio.repair.repository.RepairJobRepository;
import com.servio.common.exception.ConflictException;
import com.servio.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import com.servio.auth.repository.UserRepository;
import com.servio.auth.entity.Role;
import com.servio.notification.repository.NotificationRepository;
import com.servio.notification.entity.Notification;
import com.servio.auth.entity.User;

@Service
@RequiredArgsConstructor
@Transactional
public class MechanicService {
    private static final Pattern TRAILING_NUMBER = Pattern.compile("(\\d+)$");

    private final MechanicRepository mechanicRepository;
    private final RepairJobRepository repairJobRepository;
    private final MechanicStaffDetailsRepository staffDetailsRepository;
    private final MechanicDocumentRepository documentRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    public MechanicDto createMechanic(MechanicDto dto) {
        validateMechanic(dto);
        validateEmployeeCode(dto.getDetails(), null);

        Mechanic mechanic = Mechanic.builder()
                .fullName(dto.getFullName())
                .email(dto.getEmail())
                .phone(dto.getPhone())
                .specialization(dto.getSpecialization())
                .experienceYears(dto.getExperienceYears())
                .status(dto.getStatus() == null ? MechanicStatus.AVAILABLE : MechanicStatus.valueOf(dto.getStatus()))
                .isActive(dto.getIsActive() == null || dto.getIsActive())
                .build();

        Mechanic saved = mechanicRepository.save(mechanic);
        syncStaffDetails(saved, dto.getDetails());
        syncDocuments(saved, dto.getDocuments());
        return convertToDto(saved);
    }

    public MechanicDto getMechanicById(Long id) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found with id: " + id));
        return convertToDto(mechanic);
    }

    public List<MechanicDto> getAllMechanics() {
        return mechanicRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<MechanicDto> getMechanicsByStatus(String status) {
        try {
            MechanicStatus mechanicStatus = MechanicStatus.valueOf(status);
            return mechanicRepository.findByStatus(mechanicStatus).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid status: " + status);
        }
    }

    public List<MechanicDto> getAvailableMechanics() {
        return mechanicRepository.findByStatus(MechanicStatus.AVAILABLE).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public Optional<MechanicRegistrationLookupDto> findActiveRegistrationByEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return Optional.empty();
        }

        return mechanicRepository.findByEmailIgnoreCase(email.trim())
                .filter(mechanic -> !Boolean.FALSE.equals(mechanic.getIsActive()))
                .map(this::convertToRegistrationLookupDto);
    }

    public Optional<MechanicRegistrationLookupDto> findRegistrationByEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return Optional.empty();
        }

        return mechanicRepository.findByEmailIgnoreCase(email.trim())
                .map(this::convertToRegistrationLookupDto);
    }

    public String generateNextEmployeeCode() {
        int max = 0;
        for (String code : staffDetailsRepository.findAllEmployeeCodes()) {
            Matcher matcher = TRAILING_NUMBER.matcher(code == null ? "" : code.trim());
            if (matcher.find()) {
                max = Math.max(max, Integer.parseInt(matcher.group(1)));
            }
        }

        int next = max + 1;
        String candidate;
        do {
            candidate = String.format("EMP%04d", next++);
        } while (staffDetailsRepository.existsByEmployeeCode(candidate));
        return candidate;
    }

    public MechanicDto updateMechanic(Long id, MechanicDto dto) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found with id: " + id));
        validateEmployeeCode(dto.getDetails(), id);

        if (dto.getFullName() != null) {
            mechanic.setFullName(dto.getFullName());
        }
        if (dto.getEmail() != null) {
            mechanic.setEmail(dto.getEmail());
        }
        if (dto.getPhone() != null) {
            mechanic.setPhone(dto.getPhone());
        }
        if (dto.getSpecialization() != null) {
            mechanic.setSpecialization(dto.getSpecialization());
        }
        if (dto.getExperienceYears() != null) {
            mechanic.setExperienceYears(dto.getExperienceYears());
        }
        if (dto.getStatus() != null) {
            mechanic.setStatus(MechanicStatus.valueOf(dto.getStatus()));
        }
        if (dto.getIsActive() != null) {
            mechanic.setIsActive(dto.getIsActive());
        }

        Mechanic updated = mechanicRepository.save(mechanic);
        if (dto.getDetails() != null) {
            syncStaffDetails(updated, dto.getDetails());
        }
        if (dto.getDocuments() != null) {
            syncDocuments(updated, dto.getDocuments());
        }
        return convertToDto(updated);
    }

    public void deleteMechanic(Long id) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found with id: " + id));
        mechanic.setIsActive(false);
        mechanicRepository.save(mechanic);
    }

    public void updateMechanicStatus(Long id, String status) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found with id: " + id));
        mechanic.setStatus(MechanicStatus.valueOf(status));
        mechanicRepository.save(mechanic);
    }

    private MechanicDto convertToDto(Mechanic mechanic) {
        MechanicStaffDetails details = staffDetailsRepository.findByMechanicId(mechanic.getId()).orElse(null);
        List<MechanicDocumentDto> documents = documentRepository.findByMechanicIdOrderByUploadedAtDesc(mechanic.getId()).stream()
                .map(this::convertDocumentToDto)
                .collect(Collectors.toList());
        String profilePhotoUrl = documents.stream()
                .filter(document -> "PROFILE_PHOTO".equals(document.getDocumentType()))
                .findFirst()
                .map(MechanicDocumentDto::getUrl)
                .orElse(null);

        return MechanicDto.builder()
                .id(mechanic.getId())
                .fullName(mechanic.getFullName())
                .email(mechanic.getEmail())
                .phone(mechanic.getPhone())
                .specialization(mechanic.getSpecialization())
                .experienceYears(mechanic.getExperienceYears())
                .status(mechanic.getStatus().toString())
                .isActive(mechanic.getIsActive())
                .activeJobCount(repairJobRepository.countByAssignedTechnicianIdAndStatusNotIn(
                        mechanic.getId(),
                        List.of("COMPLETED", "CANCELLED")
                ))
                .employeeCode(details != null ? details.getEmployeeCode() : null)
                .branch(details != null ? details.getBranch() : null)
                .jobTitle(details != null ? details.getJobTitle() : null)
                .profilePhotoUrl(profilePhotoUrl)
                .details(details != null ? convertDetailsToDto(details) : null)
                .documents(documents)
                .createdAt(mechanic.getCreatedAt())
                .updatedAt(mechanic.getUpdatedAt())
                .build();
    }

    private MechanicRegistrationLookupDto convertToRegistrationLookupDto(Mechanic mechanic) {
        return MechanicRegistrationLookupDto.builder()
                .id(mechanic.getId())
                .fullName(mechanic.getFullName())
                .email(mechanic.getEmail())
                .phone(mechanic.getPhone())
                .specialization(mechanic.getSpecialization())
                .experienceYears(mechanic.getExperienceYears())
                .status(mechanic.getStatus() != null ? mechanic.getStatus().toString() : null)
                .isActive(mechanic.getIsActive())
                .build();
    }

    private void validateMechanic(MechanicDto dto) {
        if (isBlank(dto.getFullName()) || isBlank(dto.getEmail()) || isBlank(dto.getPhone())) {
            throw new IllegalArgumentException("Name, email, and phone are required");
        }
    }

    private void validateEmployeeCode(MechanicStaffDetailsDto details, Long mechanicId) {
        if (details == null) {
            return;
        }
        if (isBlank(details.getEmployeeCode())) {
            throw new IllegalArgumentException("Employee code is required");
        }
        boolean duplicate = mechanicId == null
                ? staffDetailsRepository.existsByEmployeeCode(details.getEmployeeCode())
                : staffDetailsRepository.existsByEmployeeCodeAndMechanicIdNot(details.getEmployeeCode(), mechanicId);
        if (duplicate) {
            throw new ConflictException("Employee code already exists");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void syncStaffDetails(Mechanic mechanic, MechanicStaffDetailsDto dto) {
        if (dto == null) {
            return;
        }
        MechanicStaffDetails details = staffDetailsRepository.findByMechanicId(mechanic.getId())
                .orElseGet(() -> MechanicStaffDetails.builder().mechanic(mechanic).build());
        details.setEmployeeCode(dto.getEmployeeCode());
        details.setBranch(dto.getBranch());
        details.setJobTitle(dto.getJobTitle());
        details.setEmploymentType(dto.getEmploymentType());
        details.setJoiningDate(dto.getJoiningDate());
        details.setSkillTags(dto.getSkillTags());
        details.setNicNumber(dto.getNicNumber());
        details.setPassportNumber(dto.getPassportNumber());
        details.setDateOfBirth(dto.getDateOfBirth());
        details.setGender(dto.getGender());
        details.setDrivingLicenseNumber(dto.getDrivingLicenseNumber());
        details.setLicenseClasses(dto.getLicenseClasses());
        details.setLicenseExpiryDate(dto.getLicenseExpiryDate());
        details.setAddressLine1(dto.getAddressLine1());
        details.setAddressLine2(dto.getAddressLine2());
        details.setCity(dto.getCity());
        details.setDistrict(dto.getDistrict());
        details.setPostalCode(dto.getPostalCode());
        details.setEmergencyContactName(dto.getEmergencyContactName());
        details.setEmergencyContactRelationship(dto.getEmergencyContactRelationship());
        details.setEmergencyContactPhone(dto.getEmergencyContactPhone());
        details.setBankName(dto.getBankName());
        details.setBankBranch(dto.getBankBranch());
        details.setAccountHolderName(dto.getAccountHolderName());
        details.setAccountNumber(dto.getAccountNumber());
        details.setEpfNumber(dto.getEpfNumber());
        details.setEtfNumber(dto.getEtfNumber());
        staffDetailsRepository.save(details);
    }

    private void syncDocuments(Mechanic mechanic, List<MechanicDocumentDto> documents) {
        documentRepository.deleteByMechanicId(mechanic.getId());
        if (documents == null || documents.isEmpty()) {
            return;
        }
        List<MechanicDocument> entities = new ArrayList<>();
        for (MechanicDocumentDto dto : documents) {
            if (isBlank(dto.getUrl()) || isBlank(dto.getPublicId()) || isBlank(dto.getDocumentType())) {
                continue;
            }
            entities.add(MechanicDocument.builder()
                    .mechanic(mechanic)
                    .documentType(dto.getDocumentType())
                    .originalFilename(dto.getOriginalFilename())
                    .url(dto.getUrl())
                    .publicId(dto.getPublicId())
                    .resourceType(dto.getResourceType())
                    .contentType(dto.getContentType())
                    .bytes(dto.getBytes())
                    .build());
        }
        documentRepository.saveAll(entities);
    }

    private MechanicStaffDetailsDto convertDetailsToDto(MechanicStaffDetails details) {
        return MechanicStaffDetailsDto.builder()
                .id(details.getId())
                .employeeCode(details.getEmployeeCode())
                .branch(details.getBranch())
                .jobTitle(details.getJobTitle())
                .employmentType(details.getEmploymentType())
                .joiningDate(details.getJoiningDate())
                .skillTags(details.getSkillTags())
                .nicNumber(details.getNicNumber())
                .passportNumber(details.getPassportNumber())
                .dateOfBirth(details.getDateOfBirth())
                .gender(details.getGender())
                .drivingLicenseNumber(details.getDrivingLicenseNumber())
                .licenseClasses(details.getLicenseClasses())
                .licenseExpiryDate(details.getLicenseExpiryDate())
                .addressLine1(details.getAddressLine1())
                .addressLine2(details.getAddressLine2())
                .city(details.getCity())
                .district(details.getDistrict())
                .postalCode(details.getPostalCode())
                .emergencyContactName(details.getEmergencyContactName())
                .emergencyContactRelationship(details.getEmergencyContactRelationship())
                .emergencyContactPhone(details.getEmergencyContactPhone())
                .bankName(details.getBankName())
                .bankBranch(details.getBankBranch())
                .accountHolderName(details.getAccountHolderName())
                .accountNumber(details.getAccountNumber())
                .epfNumber(details.getEpfNumber())
                .etfNumber(details.getEtfNumber())
                .build();
    }

    private MechanicDocumentDto convertDocumentToDto(MechanicDocument document) {
        return MechanicDocumentDto.builder()
                .id(document.getId())
                .documentType(document.getDocumentType())
                .originalFilename(document.getOriginalFilename())
                .url(document.getUrl())
                .publicId(document.getPublicId())
                .resourceType(document.getResourceType())
                .contentType(document.getContentType())
                .bytes(document.getBytes())
                .uploadedAt(document.getUploadedAt())
                .build();
    }

    public void reportRegistrationError(String email) {
        List<User> admins = userRepository.findByRole(Role.ADMIN);
        if (admins.isEmpty()) {
            return;
        }

        List<Notification> notifications = admins.stream()
                .map(admin -> Notification.builder()
                        .user(admin)
                        .title("Mechanic Info Correction Requested")
                        .message("Mechanic " + email + " reported incorrect pre-registered information.")
                        .type("ALERT")
                        .isRead(false)
                        .build())
                .collect(Collectors.toList());

        notificationRepository.saveAll(notifications);
    }
}
