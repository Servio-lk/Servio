package com.servio.catalog.service;


import com.servio.catalog.entity.Offer;
import com.servio.catalog.repository.OfferRepository;
import com.servio.admin.dto.OfferRequest;
import com.servio.common.event.OfferPublishedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminOfferService {

    private final OfferRepository offerRepository;
    private final ApplicationEventPublisher eventPublisher;

    public List<Offer> getAllOffers() {
        return offerRepository.findAll();
    }

    public Offer getOfferById(Long id) {
        return offerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Offer not found with id: " + id));
    }

    @Transactional
    public Offer createOffer(OfferRequest request) {
        Offer offer = new Offer();
        offer.setTitle(request.getTitle());
        offer.setSubtitle(request.getSubtitle());
        offer.setDescription(request.getDescription());
        offer.setDiscountType(request.getDiscountType());
        offer.setDiscountValue(request.getDiscountValue());
        offer.setImageUrl(request.getImageUrl());
        offer.setPromoCode(blankToNull(request.getPromoCode()));
        offer.setCategory(blankToNull(request.getCategory()));
        offer.setApplicableService(blankToNull(request.getApplicableService()));
        offer.setValidFrom(request.getValidFrom());
        offer.setValidUntil(request.getValidUntil());
        offer.setIsActive(request.getIsActive() == null || request.getIsActive());

        Offer saved = offerRepository.save(offer);
        if (Boolean.TRUE.equals(saved.getIsActive())) {
            eventPublisher.publishEvent(new OfferPublishedEvent(
                    this, saved.getId(), saved.getTitle(), saved.getPromoCode()));
        }
        return saved;
    }

    @Transactional
    public Offer updateOffer(Long id, OfferRequest request) {
        Offer offer = getOfferById(id);

        if (request.getTitle() != null) {
            offer.setTitle(request.getTitle());
        }
        if (request.getSubtitle() != null) {
            offer.setSubtitle(request.getSubtitle());
        }
        if (request.getDescription() != null) {
            offer.setDescription(request.getDescription());
        }
        if (request.getDiscountType() != null) {
            offer.setDiscountType(request.getDiscountType());
        }
        if (request.getDiscountValue() != null) {
            offer.setDiscountValue(request.getDiscountValue());
        }
        if (request.getImageUrl() != null) {
            offer.setImageUrl(request.getImageUrl());
        }
        if (request.getPromoCode() != null) {
            offer.setPromoCode(blankToNull(request.getPromoCode()));
        }
        if (request.getCategory() != null) {
            offer.setCategory(blankToNull(request.getCategory()));
        }
        offer.setApplicableService(blankToNull(request.getApplicableService()));
        if (request.getValidFrom() != null) {
            offer.setValidFrom(request.getValidFrom());
        }
        if (request.getValidUntil() != null) {
            offer.setValidUntil(request.getValidUntil());
        }
        if (request.getIsActive() != null) {
            offer.setIsActive(request.getIsActive());
        }

        return offerRepository.save(offer);
    }

    @Transactional
    public void deleteOffer(Long id) {
        if (!offerRepository.existsById(id)) {
            throw new RuntimeException("Offer not found with id: " + id);
        }
        offerRepository.deleteById(id);
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
