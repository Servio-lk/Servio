package com.servio.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
@RequiredArgsConstructor
@Slf4j
public class SupabaseAdminService {

    private final RestTemplate restTemplate;

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.service-role-key}")
    private String supabaseServiceRoleKey;

    /**
     * Deletes a user from Supabase Auth completely.
     * Requires the Supabase Service Role Key.
     */
    public void deleteUser(String supabaseUserId) {
        if (supabaseServiceRoleKey == null || supabaseServiceRoleKey.isEmpty()) {
            throw new IllegalStateException("SUPABASE_SERVICE_ROLE_KEY is not configured. Cannot delete user from Supabase Auth.");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + supabaseServiceRoleKey);
        headers.set("apikey", supabaseServiceRoleKey);

        HttpEntity<String> entity = new HttpEntity<>(headers);

        try {
            // Call Supabase Admin API to delete the user
            ResponseEntity<String> response = restTemplate.exchange(
                    supabaseUrl + "/auth/v1/admin/users/" + supabaseUserId,
                    HttpMethod.DELETE,
                    entity,
                    String.class
            );

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Successfully deleted user {} from Supabase Auth", supabaseUserId);
            } else {
                log.error("Failed to delete user {} from Supabase Auth. Status: {}", supabaseUserId, response.getStatusCode());
                throw new RuntimeException("Failed to delete user from Supabase Auth");
            }
        } catch (Exception e) {
            log.error("Error deleting user {} from Supabase Auth: {}", supabaseUserId, e.getMessage());
            throw new RuntimeException("Error deleting user from Supabase Auth: " + e.getMessage(), e);
        }
    }
}
