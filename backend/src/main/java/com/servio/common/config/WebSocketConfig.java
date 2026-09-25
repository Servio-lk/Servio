package com.servio.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import com.servio.common.util.JwtTokenProvider;
import com.servio.common.security.OwnershipSecurityService;
import lombok.RequiredArgsConstructor;

import java.security.Principal;
import java.util.ArrayList;
import java.util.List;

@Configuration
@EnableWebSocketMessageBroker
@Order(Ordered.HIGHEST_PRECEDENCE + 99)
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtTokenProvider jwtTokenProvider;
    private final OwnershipSecurityService ownershipSecurityService;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // In-memory broker for topics the client can subscribe to
        config.enableSimpleBroker("/topic");
        // Prefix for messages sent FROM client TO server (if needed)
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Pure WebSocket endpoint (ideal for @stomp/stompjs natively in React)
        // Moved under /api to allow CloudFront proxying
        registry.addEndpoint("/api/ws")
                .setAllowedOriginPatterns("*");
                
        // Fallback SockJS endpoint (if needed)
        registry.addEndpoint("/api/ws-sockjs")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    String authToken = accessor.getFirstNativeHeader("Authorization");
                    if (authToken != null && authToken.startsWith("Bearer ")) {
                        String token = authToken.substring(7);
                        if (jwtTokenProvider.validateToken(token)) {
                            String userId = jwtTokenProvider.getUserIdFromToken(token);
                            String role = jwtTokenProvider.getRoleFromToken(token);

                            List<GrantedAuthority> authorities = new ArrayList<>();
                            if (role != null) {
                                authorities.add(new SimpleGrantedAuthority(role));
                            }
                            UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                                    userId, null, authorities);
                            accessor.setUser(auth);
                        } else {
                            throw new IllegalArgumentException("Invalid JWT Token");
                        }
                    } else {
                        throw new IllegalArgumentException("Missing JWT Token");
                    }
                } else if (accessor != null && StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
                    Principal user = accessor.getUser();
                    if (user == null) {
                        throw new IllegalArgumentException("User must be authenticated to subscribe");
                    }
                    String destination = accessor.getDestination();
                    if (destination != null && destination.startsWith("/topic/repairs/")) {
                        // Extract repair ID
                        // Format: /topic/repairs/{repairId}/messages
                        String[] parts = destination.split("/");
                        if (parts.length >= 4) {
                            try {
                                Long repairId = Long.parseLong(parts[3]);
                                Authentication auth = (Authentication) user;
                                boolean isAdminOrMechanic = auth.getAuthorities().stream()
                                        .anyMatch(a -> a.getAuthority().equals("ADMIN") || a.getAuthority().equals("MECHANIC"));
                                if (!isAdminOrMechanic && !ownershipSecurityService.isRepairJobOwner(auth, repairId)) {
                                    throw new IllegalArgumentException("Unauthorized to subscribe to this repair job");
                                }
                            } catch (NumberFormatException e) {
                                throw new IllegalArgumentException("Invalid repair ID format");
                            }
                        }
                    }
                }
                return message;
            }
        });
    }
}
