package com.servio.common.config;

import com.servio.auth.entity.Role;

import com.servio.auth.security.RateLimitingFilter;
import com.servio.common.security.JwtAuthenticationFilter;
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
    private final RateLimitingFilter rateLimitingFilter;
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
<<<<<<< HEAD:backend/src/main/java/com/servio/config/SecurityConfig.java
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
=======
                        .requestMatchers("/api/auth/signup", "/api/auth/login", "/api/auth/supabase-login",
                                "/api/auth/mechanic-registration", "/api/auth/mechanic-registration/report-error", "/api/health", "/error")
                        .permitAll()
                        // Swagger OpenAPI
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        // Actuator public
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        .requestMatchers("/api/services/**", "/api/offers/**").permitAll()
                        .requestMatchers("/api/dashboard/**").permitAll()
>>>>>>> 1ccc2b6040efed7e3791fe659e47d80b5c2a31b5:backend/src/main/java/com/servio/common/config/SecurityConfig.java
                        // Public availability endpoint — no auth needed to check free slots
                        .requestMatchers(new AntPathRequestMatcher("/api/appointments/booked-slots")).permitAll()
                        // PayHere server-to-server payment notification (no JWT, verified by md5sig)
                        .requestMatchers(new AntPathRequestMatcher("/api/payments/payhere/notify")).permitAll()
                        // WebSocket handshake and SockJS fallback endpoints
<<<<<<< HEAD:backend/src/main/java/com/servio/config/SecurityConfig.java
                        .requestMatchers(
                                new AntPathRequestMatcher("/ws"),
                                new AntPathRequestMatcher("/ws/**"),
                                new AntPathRequestMatcher("/ws-sockjs/**"))
                        .permitAll()
                        // Updated Role-Based Access Control
                        .requestMatchers(new AntPathRequestMatcher("/api/admin/**")).hasAuthority("ADMIN")
                        .requestMatchers(new AntPathRequestMatcher("/api/servicerecords/**")).authenticated()
=======
                        .requestMatchers("/api/ws", "/api/ws/**", "/api/ws-sockjs/**", "/ws", "/ws/**", "/ws-sockjs/**").permitAll()
                        // Updated Role-Based Access Control
                        .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                        .requestMatchers("/actuator/metrics/**", "/actuator/prometheus").hasAuthority("ADMIN")
                        .requestMatchers("/api/servicerecords/**").authenticated()
>>>>>>> 1ccc2b6040efed7e3791fe659e47d80b5c2a31b5:backend/src/main/java/com/servio/common/config/SecurityConfig.java
                        .anyRequest().authenticated())
                .addFilterBefore(rateLimitingFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
