package com.servio.auth.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.io.IOException;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class RateLimitingFilterAdversarialTest {

    private RateLimitingFilter filter;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper().findAndRegisterModules();
        filter = new RateLimitingFilter(objectMapper);
    }

    @Test
    @DisplayName("Stress Test: 10 requests allowed, 11th rejected with 429 and RFC 7807 ErrorResponse")
    void testRateLimitExhaustion_returnsRfc7807Payload() throws ServletException, IOException {
        String clientIp = "10.0.0.42";

        for (int i = 0; i < 10; i++) {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
            request.setRemoteAddr(clientIp);
            MockHttpServletResponse response = new MockHttpServletResponse();
            FilterChain chain = mock(FilterChain.class);

            filter.doFilter(request, response, chain);
            verify(chain, times(1)).doFilter(request, response);
            assertEquals(200, response.getStatus());
        }

        // 11th attempt
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        request.setRemoteAddr(clientIp);
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);
        verify(chain, never()).doFilter(request, response);

        assertEquals(429, response.getStatus());
        assertEquals("60", response.getHeader("Retry-After"));
        assertEquals("application/json", response.getContentType());

        // Parse and validate RFC 7807 JSON structure
        JsonNode json = objectMapper.readTree(response.getContentAsString());
        assertEquals(429, json.get("status").asInt());
        assertEquals("Too Many Requests", json.get("error").asText());
        assertTrue(json.get("message").asText().contains("Too many requests"));
        assertEquals("/api/auth/login", json.get("path").asText());
        assertNotNull(json.get("traceId"));
        assertDoesNotThrow(() -> UUID.fromString(json.get("traceId").asText()));
        assertNotNull(json.get("timestamp"));
    }

    @Test
    @DisplayName("IP Isolation: IP A exhaustion does NOT block IP B")
    void testIpIsolation_separateBuckets() throws ServletException, IOException {
        String ipA = "192.168.1.10";
        String ipB = "192.168.1.20";

        // Exhaust IP A
        for (int i = 0; i < 10; i++) {
            MockHttpServletRequest reqA = new MockHttpServletRequest("POST", "/api/auth/signup");
            reqA.setRemoteAddr(ipA);
            MockHttpServletResponse resA = new MockHttpServletResponse();
            filter.doFilter(reqA, resA, mock(FilterChain.class));
            assertEquals(200, resA.getStatus());
        }

        // IP A 11th request fails
        MockHttpServletRequest reqA = new MockHttpServletRequest("POST", "/api/auth/signup");
        reqA.setRemoteAddr(ipA);
        MockHttpServletResponse resA = new MockHttpServletResponse();
        filter.doFilter(reqA, resA, mock(FilterChain.class));
        assertEquals(429, resA.getStatus());

        // IP B request succeeds (separate bucket)
        MockHttpServletRequest reqB = new MockHttpServletRequest("POST", "/api/auth/signup");
        reqB.setRemoteAddr(ipB);
        MockHttpServletResponse resB = new MockHttpServletResponse();
        FilterChain chainB = mock(FilterChain.class);
        filter.doFilter(reqB, resB, chainB);
        verify(chainB, times(1)).doFilter(reqB, resB);
        assertEquals(200, resB.getStatus());
    }

    @Test
    @DisplayName("X-Forwarded-For Parsing: multiple IPs (client, proxy1, proxy2) correctly extracts first client IP")
    void testXForwardedFor_multipleProxies() throws ServletException, IOException {
        String clientIp = "203.0.113.195";
        String headerVal = clientIp + ", 70.41.3.18, 150.172.238.178";

        // Exhaust 10 requests using X-Forwarded-For
        for (int i = 0; i < 10; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/auth/supabase-login");
            req.addHeader("X-Forwarded-For", headerVal);
            req.setRemoteAddr("127.0.0.1"); // Load balancer IP
            MockHttpServletResponse res = new MockHttpServletResponse();
            filter.doFilter(req, res, mock(FilterChain.class));
            assertEquals(200, res.getStatus());
        }

        // 11th request with same client IP via X-Forwarded-For should be rate-limited
        MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/auth/supabase-login");
        req.addHeader("X-Forwarded-For", headerVal);
        req.setRemoteAddr("127.0.0.1");
        MockHttpServletResponse res = new MockHttpServletResponse();
        filter.doFilter(req, res, mock(FilterChain.class));
        assertEquals(429, res.getStatus());
    }

    @Test
    @DisplayName("X-Forwarded-For Whitespace & Empty Handling: gracefully trims and falls back")
    void testXForwardedFor_whitespaceAndFallback() throws ServletException, IOException {
        // Whitespace trimming
        MockHttpServletRequest req1 = new MockHttpServletRequest("POST", "/api/auth/login");
        req1.addHeader("X-Forwarded-For", "   198.51.100.5   , 10.0.0.1");
        req1.setRemoteAddr("127.0.0.1");
        MockHttpServletResponse res1 = new MockHttpServletResponse();
        FilterChain chain1 = mock(FilterChain.class);
        filter.doFilter(req1, res1, chain1);
        verify(chain1, times(1)).doFilter(req1, res1);

        // Blank X-Forwarded-For falls back to remoteAddr
        MockHttpServletRequest req2 = new MockHttpServletRequest("POST", "/api/auth/login");
        req2.addHeader("X-Forwarded-For", "   ");
        req2.setRemoteAddr("198.51.100.99");
        MockHttpServletResponse res2 = new MockHttpServletResponse();
        FilterChain chain2 = mock(FilterChain.class);
        filter.doFilter(req2, res2, chain2);
        verify(chain2, times(1)).doFilter(req2, res2);
    }

    @Test
    @DisplayName("Non-Auth Endpoints are completely immune to rate limiting even after 100 requests")
    void testNonAuthEndpoints_neverRateLimited() throws ServletException, IOException {
        String clientIp = "192.168.1.50";
        String[] nonAuthPaths = {
                "/api/services",
                "/api/services/1",
                "/api/appointments/booked-slots",
                "/api/vehicles/my",
                "/api/repairs/1/conversation",
                "/actuator/health",
                "/actuator/info",
                "/api/health",
                "/api/offers"
        };

        for (String path : nonAuthPaths) {
            for (int i = 0; i < 20; i++) {
                MockHttpServletRequest request = new MockHttpServletRequest("GET", path);
                request.setRemoteAddr(clientIp);
                MockHttpServletResponse response = new MockHttpServletResponse();
                FilterChain chain = mock(FilterChain.class);

                filter.doFilter(request, response, chain);
                verify(chain, times(1)).doFilter(request, response);
                assertEquals(200, response.getStatus());
            }
        }
    }
}
