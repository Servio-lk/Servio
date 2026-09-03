package com.servio.admin.service;

import com.servio.admin.dto.AdminCustomerDetailsDto;
import com.servio.auth.entity.Profile;
import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.ProfileRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.repository.ServiceRecordRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.common.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminCustomerServiceAdversarialTest {

    @Mock
    private ProfileRepository profileRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private VehicleRepository vehicleRepository;
    @Mock
    private ServiceRecordRepository serviceRecordRepository;

    @InjectMocks
    private AdminCustomerService adminCustomerService;

    private UUID validUuid;
    private User testUser;
    private Profile testProfile;

    @BeforeEach
    void setUp() {
        validUuid = UUID.randomUUID();
        testUser = User.builder()
                .id(validUuid)
                .email("customer@example.com")
                .fullName("John Doe")
                .phone("+1234567890")
                .role(Role.CUSTOMER)
                .createdAt(LocalDateTime.now())
                .build();

        testProfile = Profile.builder()
                .id(validUuid)
                .email("customer@example.com")
                .fullName("John Doe")
                .phone("+1234567890")
                .role("CUSTOMER")
                .build();
    }

    @Test
    @DisplayName("Invalid UUID string passed to getCustomerById throws IllegalArgumentException")
    void testGetCustomerById_invalidUuid_throwsIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class, () -> adminCustomerService.getCustomerById("invalid-not-a-uuid"));
    }

    @Test
    @DisplayName("Invalid UUID string passed to getCustomerDetails throws ResourceNotFoundException cleanly")
    void testGetCustomerDetails_invalidUuid_throwsResourceNotFoundException() {
        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class,
                () -> adminCustomerService.getCustomerDetails("invalid-uuid-string"));
        assertTrue(ex.getMessage().contains("Invalid customer ID format"));
    }

    @Test
    @DisplayName("Valid UUID resolves user from UserRepository if ProfileRepository is missing")
    void testGetCustomerById_fallbackToUserRepository() {
        when(profileRepository.findById(validUuid)).thenReturn(Optional.empty());
        when(userRepository.findById(validUuid)).thenReturn(Optional.of(testUser));

        Profile profile = adminCustomerService.getCustomerById(validUuid.toString());

        assertNotNull(profile);
        assertEquals(validUuid, profile.getId());
        assertEquals("John Doe", profile.getFullName());
        assertEquals("customer@example.com", profile.getEmail());
    }

    @Test
    @DisplayName("Valid UUID not found in either repository throws ResourceNotFoundException")
    void testGetCustomerById_notFound_throwsResourceNotFoundException() {
        when(profileRepository.findById(validUuid)).thenReturn(Optional.empty());
        when(userRepository.findById(validUuid)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> adminCustomerService.getCustomerById(validUuid.toString()));
    }

    @Test
    @DisplayName("getCustomerDetails loads user, profile, and vehicles linked by UUID")
    void testGetCustomerDetails_successWithVehicles() {
        when(userRepository.findById(validUuid)).thenReturn(Optional.of(testUser));
        Vehicle vehicle = Vehicle.builder()
                .id(10L)
                .user(testUser)
                .make("Toyota")
                .model("Camry")
                .year(2022)
                .licensePlate("ABC-1234")
                .build();

        when(vehicleRepository.findByUserId(validUuid)).thenReturn(List.of(vehicle));
        when(serviceRecordRepository.findByVehicleId(10L)).thenReturn(Collections.emptyList());

        AdminCustomerDetailsDto details = adminCustomerService.getCustomerDetails(validUuid.toString());

        assertNotNull(details);
        assertNotNull(details.getUser());
        assertEquals(validUuid, details.getUser().getId());
        assertEquals(1, details.getVehicles().size());
        assertEquals("Toyota", details.getVehicles().get(0).getVehicle().getMake());
        assertEquals(validUuid, details.getVehicles().get(0).getVehicle().getUserId());
    }
}
