package com.servio.common.exception;

import com.servio.common.dto.ErrorResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.context.request.ServletWebRequest;

import static org.junit.jupiter.api.Assertions.*;

class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler exceptionHandler;

    @BeforeEach
    void setUp() {
        exceptionHandler = new GlobalExceptionHandler();
    }

    @Test
    void testHandleConflictException() {
        ConflictException ex = new ConflictException("Time slot is already booked");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/appointments");
        request.setRequestURI("/api/appointments");

        ResponseEntity<ErrorResponse> response = exceptionHandler.handleConflictException(ex, request);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(409, response.getBody().getStatus());
        assertEquals("Conflict", response.getBody().getError());
        assertEquals("Time slot is already booked", response.getBody().getMessage());
        assertEquals("/api/appointments", response.getBody().getPath());
        assertNotNull(response.getBody().getTraceId());
    }

    @Test
    void testHandleResourceNotFoundException() {
        ResourceNotFoundException ex = new ResourceNotFoundException("User not found with ID: 123");
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/users/123");
        request.setRequestURI("/api/users/123");

        ResponseEntity<ErrorResponse> response = exceptionHandler.handleResourceNotFoundException(ex, request);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(404, response.getBody().getStatus());
        assertEquals("Not Found", response.getBody().getError());
        assertEquals("User not found with ID: 123", response.getBody().getMessage());
        assertEquals("/api/users/123", response.getBody().getPath());
    }

    @Test
    void testHandleBusinessException() {
        BusinessException ex = new BusinessException("Cannot cancel completed repair job");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/repairs/1/cancel");
        request.setRequestURI("/api/repairs/1/cancel");

        ResponseEntity<ErrorResponse> response = exceptionHandler.handleBusinessException(ex, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(400, response.getBody().getStatus());
        assertEquals("Bad Request", response.getBody().getError());
        assertEquals("Cannot cancel completed repair job", response.getBody().getMessage());
    }
}
