package com.servio.notification.repository;

import com.servio.notification.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    List<DeviceToken> findByUserId(UUID userId);
    Optional<DeviceToken> findByToken(String token);
    void deleteByToken(String token);
    void deleteByUserId(UUID userId);
}
