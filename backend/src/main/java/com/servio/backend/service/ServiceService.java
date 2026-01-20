package com.servio.backend.service;

import com.servio.backend.dto.*;
import com.servio.backend.entity.*;
import com.servio.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ServiceService {
    
    private final ServiceCategoryRepository categoryRepository;
    private final ServiceRepository serviceRepository;
    private final ServiceOptionRepository optionRepository;
    private final ServiceProviderRepository providerRepository;
    private final OfferRepository offerRepository;

    public List<ServiceCategoryResponse> getAllCategoriesWithServices() {
        List<ServiceCategory> categories = categoryRepository.findAllActiveWithServices();
        return categories.stream()
                .map(this::mapToCategoryResponse)
                .collect(Collectors.toList());
    }

    public List<ServiceResponse> getAllServices() {
        List<com.servio.backend.entity.Service> services = serviceRepository.findByIsActiveTrueOrderByNameAsc();
        return services.stream()
                .map(this::mapToServiceResponse)
                .collect(Collectors.toList());
    }

    public List<ServiceResponse> getFeaturedServices() {
        List<com.servio.backend.entity.Service> services = serviceRepository.findByIsFeaturedTrueAndIsActiveTrue();
        return services.stream()
                .map(this::mapToServiceResponse)
                .collect(Collectors.toList());
    }

    public ServiceResponse getServiceById(Long id) {
        com.servio.backend.entity.Service service = serviceRepository.findByIdWithOptions(id)
                .orElseThrow(() -> new RuntimeException("Service not found"));
        return mapToServiceResponseWithOptions(service);
    }

    public List<ServiceResponse> searchServices(String query) {
        List<com.servio.backend.entity.Service> services = serviceRepository.searchServices(query);
        return services.stream()
                .map(this::mapToServiceResponse)
                .collect(Collectors.toList());
    }

    public List<ServiceProviderResponse> getAllProviders() {
        List<ServiceProvider> providers = providerRepository.findByIsActiveTrueOrderByRatingDesc();
        return providers.stream()
                .map(this::mapToProviderResponse)
                .collect(Collectors.toList());
    }

    public List<OfferResponse> getActiveOffers() {
        List<Offer> offers = offerRepository.findActiveOffers(LocalDateTime.now());
        return offers.stream()
                .map(this::mapToOfferResponse)
                .collect(Collectors.toList());
    }

    private ServiceCategoryResponse mapToCategoryResponse(ServiceCategory category) {
        ServiceCategoryResponse response = new ServiceCategoryResponse();
        response.setId(category.getId());
        response.setName(category.getName());
        response.setDescription(category.getDescription());
        
        if (category.getServices() != null) {
            List<ServiceResponse> services = category.getServices().stream()
                    .filter(s -> s.getIsActive())
                    .map(this::mapToServiceResponse)
                    .collect(Collectors.toList());
            response.setServices(services);
        }
        
        return response;
    }

    private ServiceResponse mapToServiceResponse(com.servio.backend.entity.Service service) {
        ServiceResponse response = new ServiceResponse();
        response.setId(service.getId());
        response.setCategoryId(service.getCategory().getId());
        response.setCategoryName(service.getCategory().getName());
        response.setName(service.getName());
        response.setDescription(service.getDescription());
        response.setBasePrice(service.getBasePrice());
        response.setPriceRange(service.getPriceRange());
        response.setDurationMinutes(service.getDurationMinutes());
        response.setImageUrl(service.getImageUrl());
        response.setIsFeatured(service.getIsFeatured());
        return response;
    }

    private ServiceResponse mapToServiceResponseWithOptions(com.servio.backend.entity.Service service) {
        ServiceResponse response = mapToServiceResponse(service);
        
        if (service.getOptions() != null && !service.getOptions().isEmpty()) {
            List<ServiceOptionResponse> options = service.getOptions().stream()
                    .map(this::mapToOptionResponse)
                    .collect(Collectors.toList());
            response.setOptions(options);
        }
        
        return response;
    }

    private ServiceOptionResponse mapToOptionResponse(ServiceOption option) {
        ServiceOptionResponse response = new ServiceOptionResponse();
        response.setId(option.getId());
        response.setName(option.getName());
        response.setDescription(option.getDescription());
        response.setPriceAdjustment(option.getPriceAdjustment());
        response.setIsDefault(option.getIsDefault());
        return response;
    }

    private ServiceProviderResponse mapToProviderResponse(ServiceProvider provider) {
        ServiceProviderResponse response = new ServiceProviderResponse();
        response.setId(provider.getId());
        response.setName(provider.getName());
        response.setAddress(provider.getAddress());
        response.setCity(provider.getCity());
        response.setPhone(provider.getPhone());
        response.setRating(provider.getRating());
        return response;
    }

    private OfferResponse mapToOfferResponse(Offer offer) {
        OfferResponse response = new OfferResponse();
        response.setId(offer.getId());
        response.setTitle(offer.getTitle());
        response.setSubtitle(offer.getSubtitle());
        response.setDescription(offer.getDescription());
        response.setDiscountType(offer.getDiscountType());
        response.setDiscountValue(offer.getDiscountValue());
        response.setImageUrl(offer.getImageUrl());
        response.setValidUntil(offer.getValidUntil());
        return response;
    }
}