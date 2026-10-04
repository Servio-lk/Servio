package com.servio.catalog.repository;

import com.servio.catalog.entity.Offer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OfferRepository extends JpaRepository<Offer, Long> {
    @Query("""
            SELECT o FROM Offer o
            WHERE (o.isActive IS NULL OR o.isActive = true)
              AND (o.validFrom IS NULL OR o.validFrom <= :now)
              AND (o.validUntil IS NULL OR o.validUntil >= :now)
              AND (:category IS NULL OR o.category = :category)
            ORDER BY o.id DESC
            """)
    List<Offer> findActiveOffers(@Param("now") LocalDateTime now, @Param("category") String category);
}
