package com.servio.common.exception;

import com.servio.common.dto.ErrorResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class GlobalExceptionHandlerAdversarialTest {

    private GlobalExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
    }

    @Test
    @DisplayName("Invalid UUID format: IllegalArgumentException returns 400 Bad Request RFC 7807")
    void testIllegalArgumentException_invalidUuid() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/customers/invalid-uuid-format");
        IllegalArgumentException ex = new IllegalArgumentException("Invalid UUID string: invalid-uuid-format");

        ResponseEntity<ErrorResponse> response = handler.handleIllegalArgumentException(ex, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        ErrorResponse body = response.getBody();
        assertNotNull(body);
        assertEquals(400, body.getStatus());
        assertEquals("Bad Request", body.getError());
        assertTrue(body.getMessage().contains("invalid-uuid-format"));
        assertEquals("/api/admin/customers/invalid-uuid-format", body.getPath());
        assertNotNull(body.getTraceId());
        assertDoesNotThrow(() -> UUID.fromString(body.getTraceId()));
        assertNotNull(body.getTimestamp());
    }

    @Test
    @DisplayName("ResourceNotFoundException returns 404 Not Found RFC 7807")
    void testResourceNotFoundException() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/customers/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11");
        ResourceNotFoundException ex = new ResourceNotFoundException("Customer not found with id: a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11");

        ResponseEntity<ErrorResponse> response = handler.handleResourceNotFoundException(ex, request);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        ErrorResponse body = response.getBody();
        assertNotNull(body);
        assertEquals(404, body.getStatus());
        assertEquals("Not Found", body.getError());
        assertEquals("Customer not found with id: a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", body.getMessage());
    }

    @Test
    @DisplayName("PaymentException returns 402 Payment Required RFC 7807")
    void testPaymentException() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/payments/charge");
        PaymentException ex = new PaymentException("Card declined");

        ResponseEntity<ErrorResponse> response = handler.handlePaymentException(ex, request);

        assertEquals(HttpStatus.PAYMENT_REQUIRED, response.getStatusCode());
        ErrorResponse body = response.getBody();
        assertNotNull(body);
        assertEquals(402, body.getStatus());
        assertEquals("Payment Required", body.getError());
        assertEquals("Card declined", body.getMessage());
    }

    @Test
    @DisplayName("DataIntegrityViolationException returns 409 Conflict RFC 7807")
    void testDataIntegrityViolationException() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/appointments");
        DataIntegrityViolationException ex = new DataIntegrityViolationException("duplicate key value violates unique constraint");

        ResponseEntity<ErrorResponse> response = handler.handleDataIntegrityException(ex, request);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        ErrorResponse body = response.getBody();
        assertNotNull(body);
        assertEquals(409, body.getStatus());
        assertEquals("Conflict", body.getError());
        assertEquals("This time slot is already booked. Please choose another time.", body.getMessage());
    }

    @Test
    @DisplayName("AccessDeniedException and SecurityException return 403 Forbidden RFC 7807")
    void testSecurityExceptions() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/dashboard");
        
        AccessDeniedException accessDenied = new AccessDeniedException("Access is denied");
        ResponseEntity<ErrorResponse> resp1 = handler.handleAccessDeniedException(accessDenied, request);
        assertEquals(HttpStatus.FORBIDDEN, resp1.getStatusCode());
        assertEquals(403, resp1.getBody().getStatus());

        SecurityException secEx = new SecurityException("User not authenticated");
        ResponseEntity<ErrorResponse> resp2 = handler.handleSecurityException(secEx, request);
        assertEquals(HttpStatus.FORBIDDEN, resp2.getStatusCode());
        assertEquals(403, resp2.getBody().getStatus());
    }

    @Test
    @DisplayName("AuthenticationException returns 401 Unauthorized RFC 7807")
    void testAuthenticationException() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        BadCredentialsException ex = new BadCredentialsException("Invalid username or password");

        ResponseEntity<ErrorResponse> response = handler.handleAuthenticationException(ex, request);

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
        assertEquals(401, response.getBody().getStatus());
        assertEquals("Unauthorized", response.getBody().getError());
    }

    @Test
    @DisplayName("MethodArgumentNotValidException formats field errors cleanly")
    void testValidationException() throws NoSuchMethodException {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/signup");
        org.springframework.validation.BeanPropertyBindingResult bindingResult = 
                new org.springframework.validation.BeanPropertyBindingResult(new Object(), "signupRequest");

        FieldError fieldError1 = new FieldError("signupRequest", "email", "must be a well-formed email address");
        FieldError fieldError2 = new FieldError("signupRequest", "password", "must not be blank");
        bindingResult.addError(fieldError1);
        bindingResult.addError(fieldError2);

        MethodArgumentNotValidException ex = new MethodArgumentNotValidException(
                new org.springframework.core.MethodParameter(this.getClass().getDeclaredMethod("setUp"), -1),
                bindingResult
        );

        ResponseEntity<ErrorResponse> response = handler.handleValidationException(ex, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        ErrorResponse body = response.getBody();
        assertNotNull(body);
        assertEquals(400, body.getStatus());
        assertTrue(body.getMessage().contains("email: must be a well-formed email address"));
        assertTrue(body.getMessage().contains("password: must not be blank"));
    }

    @Test
    @DisplayName("Generic Exception returns 500 with sanitized message")
    void testGenericException() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/unknown");
        RuntimeException ex = new RuntimeException("Sensitive internal database connection string leaked");

        ResponseEntity<ErrorResponse> response = handler.handleGenericException(ex, request);

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        ErrorResponse body = response.getBody();
        assertNotNull(body);
        assertEquals(500, body.getStatus());
        assertEquals("An unexpected error occurred", body.getMessage());
        assertFalse(body.getMessage().contains("Sensitive internal database"));
    }
}
