package com.servio.backend.controller;

import com.servio.backend.entity.Offer;
import com.servio.backend.service.AdminOfferService;
import com.servio.dto.ApiResponse;
import com.servio.dto.admin.OfferRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/offers")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminOfferController {

    private final AdminOfferService adminOfferService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Offer>>> getAllOffers() {
        List<Offer> offers = adminOfferService.getAllOffers();
        return ResponseEntity.ok(ApiResponse.success("Offers retrieved successfully", offers));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Offer>> getOfferById(@PathVariable Long id) {
        Offer offer = adminOfferService.getOfferById(id);
        return ResponseEntity.ok(ApiResponse.success("Offer retrieved successfully", offer));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Offer>> createOffer(@Valid @RequestBody OfferRequest request) {
        Offer offer = adminOfferService.createOffer(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Offer created successfully", offer));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Offer>> updateOffer(
            @PathVariable Long id,
            @Valid @RequestBody OfferRequest request) {
        Offer offer = adminOfferService.updateOffer(id, request);
        return ResponseEntity.ok(ApiResponse.success("Offer updated successfully", offer));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteOffer(@PathVariable Long id) {
        adminOfferService.deleteOffer(id);
        return ResponseEntity.ok(ApiResponse.success("Offer deleted successfully", null));
    }
}
