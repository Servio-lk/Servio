package com.servio.catalog.controller;

import com.servio.catalog.dto.OfferResponse;
import com.servio.catalog.service.ServiceService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/offers")
@RequiredArgsConstructor
public class OfferController {

    private final ServiceService serviceService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<OfferResponse>>> getActiveOffers(
            @RequestParam(required = false) String category) {
        List<OfferResponse> offers = serviceService.getActiveOffers(category);
        return ResponseEntity.ok(ApiResponse.success("Offers retrieved successfully", offers));
    }
}