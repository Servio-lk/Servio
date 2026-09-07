package com.servio.agent.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "gemini")
public class GeminiConfig {
    private String apiKey;
    private String model = "gemini-1.5-flash";

    public boolean isConfigured() {
        return apiKey != null && !apiKey.trim().isEmpty();
    }
}
