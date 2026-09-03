package com.servio.common.audit;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Aspect
@Component
@RequiredArgsConstructor
public class AuditAspect {
    private static final Logger logger = LoggerFactory.getLogger(AuditAspect.class);
    private final AuditLogRepository auditLogRepository;

    @Pointcut("execution(* com.servio.controller..*.*(..)) && (@annotation(org.springframework.web.bind.annotation.PostMapping) || @annotation(org.springframework.web.bind.annotation.PutMapping) || @annotation(org.springframework.web.bind.annotation.DeleteMapping) || @annotation(org.springframework.web.bind.annotation.PatchMapping))")
    public void stateChangingMethods() {}

    @AfterReturning(pointcut = "stateChangingMethods()", returning = "result")
    public void logAfter(JoinPoint joinPoint, Object result) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = (auth != null && auth.isAuthenticated()) ? auth.getName() : "anonymous";

            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            String ipAddress = "unknown";
            String path = "unknown";
            String method = "unknown";
            
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                ipAddress = request.getRemoteAddr();
                path = request.getRequestURI();
                method = request.getMethod();
            }

            String action = method + " " + path;
            String details = "Method: " + joinPoint.getSignature().getName();

            AuditLog logEntry = AuditLog.builder()
                    .username(username)
                    .action(action)
                    .resource(joinPoint.getSignature().getDeclaringTypeName())
                    .details(details)
                    .ipAddress(ipAddress)
                    .build();

            auditLogRepository.save(logEntry);
        } catch (Exception e) {
            logger.error("Failed to log audit entry", e);
        }
    }
}
