package com.servio.admin.controller;

import com.servio.admin.dto.JobTaskDto;
import com.servio.admin.service.JobTaskService;
import com.servio.common.dto.ApiResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminJobTaskControllerAppointmentTest {

    @Mock
    private JobTaskService jobTaskService;

    @InjectMocks
    private AdminJobTaskController adminJobTaskController;

    @Test
    @DisplayName("getTasksByAppointment should delegate to JobTaskService and return 200 OK")
    void testGetTasksByAppointment() {
        Long appointmentId = 15L;
        List<JobTaskDto> tasks = List.of(
                JobTaskDto.builder().id(1L).appointmentId(appointmentId).description("Inspect vehicle").build(),
                JobTaskDto.builder().id(2L).appointmentId(appointmentId).description("Check brakes").build()
        );

        when(jobTaskService.getTasksByAppointment(appointmentId)).thenReturn(tasks);

        ResponseEntity<ApiResponse<List<JobTaskDto>>> response = adminJobTaskController.getTasksByAppointment(appointmentId);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(2, response.getBody().getData().size());
        verify(jobTaskService, times(1)).getTasksByAppointment(appointmentId);
    }
}
