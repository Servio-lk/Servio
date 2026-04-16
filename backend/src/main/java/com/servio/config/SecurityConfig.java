package com.servio.config;

import com.servio.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsConfigurationSource corsConfigurationSource;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // Return 401 (not 403) when authentication is missing/invalid so the
                // frontend apiFetch retry logic can trigger a token refresh
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .authorizeHttpRequests(authz -> authz
                        .requestMatchers(
                                new AntPathRequestMatcher("/api/auth/signup"),
                                new AntPathRequestMatcher("/api/auth/login"),
                                new AntPathRequestMatcher("/api/auth/supabase-login"),
                                new AntPathRequestMatcher("/api/health"),
                                new AntPathRequestMatcher("/error"))
                        .permitAll()
                        .requestMatchers(
                                new AntPathRequestMatcher("/api/services/**"),
                                new AntPathRequestMatcher("/api/offers/**"))
                        .permitAll()
                        .requestMatchers(new AntPathRequestMatcher("/api/dashboard/**")).permitAll()
                        // Public availability endpoint — no auth needed to check free slots
                        .requestMatchers(new AntPathRequestMatcher("/api/appointments/booked-slots")).permitAll()
                        // PayHere server-to-server payment notification (no JWT, verified by md5sig)
                        .requestMatchers(new AntPathRequestMatcher("/api/payments/payhere/notify")).permitAll()
                        // WebSocket handshake and SockJS fallback endpoints
                        .requestMatchers(
                                new AntPathRequestMatcher("/ws"),
                                new AntPathRequestMatcher("/ws/**"),
                                new AntPathRequestMatcher("/ws-sockjs/**"))
                        .permitAll()
                        // Updated Role-Based Access Control
                        .requestMatchers(new AntPathRequestMatcher("/api/admin/**")).hasAuthority("ADMIN")
                        .requestMatchers(new AntPathRequestMatcher("/api/servicerecords/**")).authenticated()
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}