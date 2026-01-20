package com.servio.backend.controller;

import com.servio.backend.dto.*;
import com.servio.backend.service.ServiceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/services")
@RequiredArgsConstructor
public class ServiceController {

    private final ServiceService serviceService;

    @GetMapping("/categories")
    public ResponseEntity<Map<String, Object>> getServiceCategories() {
        List<ServiceCategoryResponse> categories = serviceService.getAllCategoriesWithServices();
        return ResponseEntity.ok(createSuccessResponse(categories));
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllServices() {
        List<ServiceResponse> services = serviceService.getAllServices();
        return ResponseEntity.ok(createSuccessResponse(services));
    }

    @GetMapping("/featured")
    public ResponseEntity<Map<String, Object>> getFeaturedServices() {
        List<ServiceResponse> services = serviceService.getFeaturedServices();
        return ResponseEntity.ok(createSuccessResponse(services));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getServiceById(@PathVariable Long id) {
        ServiceResponse service = serviceService.getServiceById(id);
        return ResponseEntity.ok(createSuccessResponse(service));
    }

    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchServices(@RequestParam String q) {
        List<ServiceResponse> services = serviceService.searchServices(q);
        return ResponseEntity.ok(createSuccessResponse(services));
    }

    @GetMapping("/providers")
    public ResponseEntity<Map<String, Object>> getServiceProviders() {
        List<ServiceProviderResponse> providers = serviceService.getAllProviders();
        return ResponseEntity.ok(createSuccessResponse(providers));
    }

    @GetMapping("/offers")
    public ResponseEntity<Map<String, Object>> getActiveOffers() {
        List<OfferResponse> offers = serviceService.getActiveOffers();
        return ResponseEntity.ok(createSuccessResponse(offers));
    }

    private Map<String, Object> createSuccessResponse(Object data) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", data);
        return response;
    }
}