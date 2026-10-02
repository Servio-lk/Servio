package com.servio.inventory.service;

import com.servio.admin.dto.PartRequestDto;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.repository.MechanicRepository;
import com.servio.booking.entity.Appointment;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.inventory.entity.PartRequest;
import com.servio.inventory.repository.PartRequestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PartRequestServiceTest {

    @Mock
    private PartRequestRepository partRequestRepository;

    @Mock
    private MechanicRepository mechanicRepository;

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private PartRequestService partRequestService;

    private Mechanic testMechanic;
    private Appointment testAppointment;
    private Vehicle testVehicle;

    @BeforeEach
    void setUp() {
        testMechanic = Mechanic.builder()
                .id(10L)
                .fullName("Kamal Perera")
                .email("kamal@servio.lk")
                .phone("0771234567")
                .build();

        testVehicle = Vehicle.builder()
                .id(5L)
                .make("Toyota")
                .model("Corolla")
                .year(2020)
                .build();

        testAppointment = Appointment.builder()
                .id(100L)
                .vehicle(testVehicle)
                .serviceType("Major Service")
                .build();
    }

    @Test
    @DisplayName("createRequest should link provided mechanic and appointment, saving request with default PENDING status")
    void testCreateRequest_SuccessWithIds() {
        PartRequestDto inputDto = PartRequestDto.builder()
                .mechanicId(10L)
                .appointmentId(100L)
                .partName("Brake Pads")
                .partNumber("BP-102")
                .quantity(BigDecimal.valueOf(2))
                .unit("sets")
                .urgency("URGENT")
                .notes("Front axle replacement needed")
                .build();

        when(mechanicRepository.findById(10L)).thenReturn(Optional.of(testMechanic));
        when(appointmentRepository.findById(100L)).thenReturn(Optional.of(testAppointment));

        PartRequest savedEntity = PartRequest.builder()
                .id(1L)
                .mechanic(testMechanic)
                .appointment(testAppointment)
                .partName("Brake Pads")
                .partNumber("BP-102")
                .quantity(BigDecimal.valueOf(2))
                .unit("sets")
                .urgency("URGENT")
                .notes("Front axle replacement needed")
                .status("PENDING")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(partRequestRepository.save(any(PartRequest.class))).thenReturn(savedEntity);

        PartRequestDto result = partRequestService.createRequest(inputDto, null);

        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("Brake Pads", result.getPartName());
        assertEquals(10L, result.getMechanicId());
        assertEquals("Kamal Perera", result.getMechanicName());
        assertEquals(100L, result.getAppointmentId());
        assertEquals("2020 Toyota Corolla", result.getVehicleDisplay());
        assertEquals("PENDING", result.getStatus());
        verify(partRequestRepository, times(1)).save(any(PartRequest.class));
    }

    @Test
    @DisplayName("createRequest should resolve mechanic from Authentication principal when mechanicId is omitted")
    void testCreateRequest_ResolvesMechanicFromAuth() {
        PartRequestDto inputDto = PartRequestDto.builder()
                .partName("Oil Filter")
                .quantity(BigDecimal.ONE)
                .urgency("STANDARD")
                .build();

        when(authentication.getName()).thenReturn("kamal@servio.lk");
        when(mechanicRepository.findByEmailIgnoreCase("kamal@servio.lk")).thenReturn(Optional.of(testMechanic));

        PartRequest savedEntity = PartRequest.builder()
                .id(2L)
                .mechanic(testMechanic)
                .partName("Oil Filter")
                .quantity(BigDecimal.ONE)
                .status("PENDING")
                .createdAt(LocalDateTime.now())
                .build();

        when(partRequestRepository.save(any(PartRequest.class))).thenReturn(savedEntity);

        PartRequestDto result = partRequestService.createRequest(inputDto, authentication);

        assertNotNull(result);
        assertEquals(2L, result.getId());
        assertEquals(10L, result.getMechanicId());
        assertEquals("Kamal Perera", result.getMechanicName());
    }

    @Test
    @DisplayName("getRequestsByAppointment should return sorted list of requests with vehicle display populated")
    void testGetRequestsByAppointment() {
        PartRequest req1 = PartRequest.builder()
                .id(1L)
                .appointment(testAppointment)
                .mechanic(testMechanic)
                .partName("Spark Plugs")
                .quantity(BigDecimal.valueOf(4))
                .status("PENDING")
                .createdAt(LocalDateTime.now())
                .build();

        when(partRequestRepository.findByAppointmentIdOrderByCreatedAtDesc(100L))
                .thenReturn(List.of(req1));

        List<PartRequestDto> results = partRequestService.getRequestsByAppointment(100L);

        assertEquals(1, results.size());
        assertEquals("Spark Plugs", results.get(0).getPartName());
        assertEquals("2020 Toyota Corolla", results.get(0).getVehicleDisplay());
    }

    @Test
    @DisplayName("updateStatus should update request status to uppercase")
    void testUpdateStatus() {
        PartRequest req = PartRequest.builder()
                .id(1L)
                .partName("Fuel Filter")
                .status("PENDING")
                .build();

        when(partRequestRepository.findById(1L)).thenReturn(Optional.of(req));
        when(partRequestRepository.save(any(PartRequest.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PartRequestDto updated = partRequestService.updateStatus(1L, "approved");

        assertEquals("APPROVED", updated.getStatus());
        verify(partRequestRepository, times(1)).save(req);
    }
}
