package com.servio.repair.controller;

import com.servio.common.dto.ApiResponse;
import com.servio.repair.dto.RepairPartDto;
import com.servio.repair.dto.RepairPartRequest;
import com.servio.repair.entity.RepairJob;
import com.servio.repair.entity.RepairPart;
import com.servio.repair.service.RepairJobService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RepairJobControllerPartsTest {

    @Mock
    private RepairJobService repairJobService;

    @InjectMocks
    private RepairJobController repairJobController;

    @Test
    @DisplayName("logPartUsed should return 201 CREATED with mapped RepairPartDto")
    void testLogPartUsed() {
        Long appointmentId = 88L;
        RepairPartRequest request = RepairPartRequest.builder()
                .partName("Engine Oil 5W-30")
                .quantity(4)
                .unitCost(BigDecimal.valueOf(2500))
                .totalCost(BigDecimal.valueOf(10000))
                .status("INSTALLED")
                .build();

        RepairJob mockJob = RepairJob.builder().id(20L).build();
        RepairPart savedPart = RepairPart.builder()
                .id(1L)
                .repairJob(mockJob)
                .partName("Engine Oil 5W-30")
                .quantity(4)
                .unitCost(BigDecimal.valueOf(2500))
                .totalCost(BigDecimal.valueOf(10000))
                .status("INSTALLED")
                .build();

        when(repairJobService.logPartUsed(eq(appointmentId), any(RepairPartRequest.class)))
                .thenReturn(savedPart);

        ResponseEntity<ApiResponse<RepairPartDto>> response = repairJobController.logPartUsed(appointmentId, request);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("Part logged successfully", response.getBody().getMessage());
        assertEquals(1L, response.getBody().getData().getId());
        assertEquals("Engine Oil 5W-30", response.getBody().getData().getPartName());
        verify(repairJobService, times(1)).logPartUsed(appointmentId, request);
    }

    @Test
    @DisplayName("getPartsByAppointment should return 200 OK with list of parts")
    void testGetPartsByAppointment() {
        Long appointmentId = 88L;
        RepairJob mockJob = RepairJob.builder().id(20L).build();
        RepairPart part1 = RepairPart.builder()
                .id(1L)
                .repairJob(mockJob)
                .partName("Oil Filter")
                .quantity(1)
                .unitCost(BigDecimal.valueOf(1500))
                .totalCost(BigDecimal.valueOf(1500))
                .status("INSTALLED")
                .build();

        when(repairJobService.getPartsForAppointment(appointmentId)).thenReturn(List.of(part1));

        ResponseEntity<ApiResponse<List<RepairPartDto>>> response = repairJobController.getPartsByAppointment(appointmentId);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("Oil Filter", response.getBody().getData().get(0).getPartName());
    }
}
