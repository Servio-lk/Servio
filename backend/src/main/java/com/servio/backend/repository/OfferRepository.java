package com.servio.backend.repository;

import com.servio.backend.entity.Offer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OfferRepository extends JpaRepository<Offer, Long> {
    @Query("SELECT o FROM Offer o WHERE o.isActive = true AND o.validFrom <= :now AND (o.validUntil IS NULL OR o.validUntil >= :now)")
    List<Offer> findActiveOffers(LocalDateTime now);
}