package com.servio.backend.service;

import com.servio.backend.entity.ServiceCategory;
import com.servio.backend.repository.ServiceCategoryRepository;
import com.servio.backend.repository.ServiceRepository;
import com.servio.dto.admin.ServiceRequest;
import com.servio.dto.admin.ServiceToggleRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@org.springframework.stereotype.Service
@RequiredArgsConstructor
public class AdminServiceService {

    private final ServiceRepository serviceRepository;
    private final ServiceCategoryRepository categoryRepository;

    public List<com.servio.backend.entity.Service> getAllServices() {
        return serviceRepository.findAll();
    }

    public com.servio.backend.entity.Service getServiceById(Long id) {
        return serviceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service not found with id: " + id));
    }

    @Transactional
    public com.servio.backend.entity.Service createService(ServiceRequest request) {
        ServiceCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + request.getCategoryId()));

        com.servio.backend.entity.Service service = new com.servio.backend.entity.Service();
        service.setCategory(category);
        service.setName(request.getName());
        service.setDescription(request.getDescription());
        service.setBasePrice(request.getBasePrice());
        service.setPriceRange(request.getPriceRange());
        service.setDurationMinutes(request.getDurationMinutes());
        service.setImageUrl(request.getImageUrl());
        service.setIsFeatured(request.getIsFeatured());
        service.setIsActive(request.getIsActive());

        return serviceRepository.save(service);
    }

    @Transactional
    public com.servio.backend.entity.Service updateService(Long id, ServiceRequest request) {
        com.servio.backend.entity.Service service = getServiceById(id);

        if (request.getCategoryId() != null) {
            ServiceCategory category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found with id: " + request.getCategoryId()));
            service.setCategory(category);
        }

        if (request.getName() != null) {
            service.setName(request.getName());
        }
        if (request.getDescription() != null) {
            service.setDescription(request.getDescription());
        }
        if (request.getBasePrice() != null) {
            service.setBasePrice(request.getBasePrice());
        }
        if (request.getPriceRange() != null) {
            service.setPriceRange(request.getPriceRange());
        }
        if (request.getDurationMinutes() != null) {
            service.setDurationMinutes(request.getDurationMinutes());
        }
        if (request.getImageUrl() != null) {
            service.setImageUrl(request.getImageUrl());
        }
        if (request.getIsFeatured() != null) {
            service.setIsFeatured(request.getIsFeatured());
        }
        if (request.getIsActive() != null) {
            service.setIsActive(request.getIsActive());
        }

        return serviceRepository.save(service);
    }

    @Transactional
    public com.servio.backend.entity.Service toggleServiceStatus(Long id, ServiceToggleRequest request) {
        com.servio.backend.entity.Service service = getServiceById(id);
        service.setIsActive(request.getIsActive());
        return serviceRepository.save(service);
    }

    @Transactional
    public void deleteService(Long id) {
        if (!serviceRepository.existsById(id)) {
            throw new RuntimeException("Service not found with id: " + id);
        }
        serviceRepository.deleteById(id);
    }
}
