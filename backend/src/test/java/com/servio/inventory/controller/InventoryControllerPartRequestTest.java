package com.servio.inventory.controller;

import com.servio.admin.dto.PartRequestDto;
import com.servio.common.dto.ApiResponse;
import com.servio.inventory.service.InventoryService;
import com.servio.inventory.service.PartRequestService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InventoryControllerPartRequestTest {

    @Mock
    private InventoryService inventoryService;

    @Mock
    private PartRequestService partRequestService;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private InventoryController inventoryController;

    @Test
    @DisplayName("createPartRequest should delegate to PartRequestService and return 201 CREATED")
    void testCreatePartRequest() {
        PartRequestDto request = PartRequestDto.builder()
                .partName("Brake Pads")
                .quantity(BigDecimal.valueOf(2))
                .build();

        PartRequestDto created = PartRequestDto.builder()
                .id(1L)
                .partName("Brake Pads")
                .quantity(BigDecimal.valueOf(2))
                .status("PENDING")
                .build();

        when(partRequestService.createRequest(any(PartRequestDto.class), eq(authentication)))
                .thenReturn(created);

        ResponseEntity<ApiResponse<PartRequestDto>> response = inventoryController.createPartRequest(request, authentication);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(created, response.getBody().getData());
        verify(partRequestService, times(1)).createRequest(request, authentication);
    }

    @Test
    @DisplayName("getAllPartRequests should return 200 OK with list of all requests")
    void testGetAllPartRequests() {
        List<PartRequestDto> requests = List.of(
                PartRequestDto.builder().id(1L).partName("Oil Filter").build(),
                PartRequestDto.builder().id(2L).partName("Air Filter").build()
        );

        when(partRequestService.getAllRequests()).thenReturn(requests);

        ResponseEntity<ApiResponse<List<PartRequestDto>>> response = inventoryController.getAllPartRequests();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(2, response.getBody().getData().size());
    }

    @Test
    @DisplayName("getRequestsByAppointment should return requests for appointment with 200 OK")
    void testGetRequestsByAppointment() {
        List<PartRequestDto> requests = List.of(
                PartRequestDto.builder().id(1L).appointmentId(42L).partName("Spark Plug").build()
        );

        when(partRequestService.getRequestsByAppointment(42L)).thenReturn(requests);

        ResponseEntity<ApiResponse<List<PartRequestDto>>> response = inventoryController.getRequestsByAppointment(42L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("Spark Plug", response.getBody().getData().get(0).getPartName());
    }
}
