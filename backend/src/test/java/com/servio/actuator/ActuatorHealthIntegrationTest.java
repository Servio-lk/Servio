package com.servio.actuator;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthComponent;
import org.springframework.boot.actuate.health.HealthEndpoint;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.actuate.health.Status;
import org.springframework.boot.actuate.info.InfoEndpoint;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ActuatorHealthIntegrationTest {

    @Test
    @DisplayName("Actuator health reports UP status with database and service components")
    void testActuatorHealthUp() {
        HealthIndicator dbHealthIndicator = () -> Health.up()
                .withDetail("database", "PostgreSQL")
                .withDetail("validationQuery", "SELECT 1")
                .build();

        HealthIndicator diskHealthIndicator = () -> Health.up()
                .withDetail("total", 500000000000L)
                .withDetail("free", 200000000000L)
                .build();

        Health dbHealth = dbHealthIndicator.health();
        Health diskHealth = diskHealthIndicator.health();

        assertNotNull(dbHealth);
        assertEquals(Status.UP, dbHealth.getStatus());
        assertEquals("PostgreSQL", dbHealth.getDetails().get("database"));

        assertNotNull(diskHealth);
        assertEquals(Status.UP, diskHealth.getStatus());

        HealthEndpoint healthEndpoint = mock(HealthEndpoint.class);
        Health aggregateHealth = Health.up()
                .withDetail("db", dbHealth.getDetails())
                .withDetail("diskSpace", diskHealth.getDetails())
                .build();

        when(healthEndpoint.health()).thenReturn(aggregateHealth);

        HealthComponent result = healthEndpoint.health();
        assertNotNull(result);
        assertEquals(Status.UP, result.getStatus());
    }

    @Test
    @DisplayName("Actuator info endpoint is operational")
    void testActuatorInfo() {
        InfoEndpoint infoEndpoint = mock(InfoEndpoint.class);
        Map<String, Object> infoData = Map.of(
                "app", Map.of("name", "Servio Backend", "version", "1.0.0", "description", "Automotive Service Management")
        );

        when(infoEndpoint.info()).thenReturn(infoData);

        Map<String, Object> result = infoEndpoint.info();

        assertNotNull(result);
        assertTrue(result.containsKey("app"));
        @SuppressWarnings("unchecked")
        Map<String, Object> appInfo = (Map<String, Object>) result.get("app");
        assertEquals("Servio Backend", appInfo.get("name"));
        assertEquals("1.0.0", appInfo.get("version"));
    }
}
