package com.servio.backend.service;

import com.servio.backend.entity.Offer;
import com.servio.backend.repository.OfferRepository;
import com.servio.dto.admin.OfferRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminOfferService {

    private final OfferRepository offerRepository;

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
        offer.setValidFrom(request.getValidFrom());
        offer.setValidUntil(request.getValidUntil());
        offer.setIsActive(request.getIsActive());

        return offerRepository.save(offer);
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
}
