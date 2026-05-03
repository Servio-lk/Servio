package com.servio.backend.service;

import com.servio.backend.entity.ServiceCategory;
import com.servio.backend.entity.ServiceOption;
import com.servio.backend.entity.ServicePhoto;
import com.servio.backend.entity.ServiceStatus;
import com.servio.backend.repository.ServiceCategoryRepository;
import com.servio.backend.repository.ServiceRepository;
import com.servio.dto.NotificationRequest;
import com.servio.dto.admin.AdminServiceDto;
import com.servio.dto.admin.ServiceRequest;
import com.servio.dto.admin.ServiceOptionRequest;
import com.servio.dto.admin.ServicePhotoDto;
import com.servio.dto.admin.ServiceToggleRequest;
import com.servio.entity.Role;
import com.servio.entity.User;
import com.servio.repository.UserRepository;
import com.servio.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@org.springframework.stereotype.Service
@RequiredArgsConstructor
public class AdminServiceService {

    private final ServiceRepository serviceRepository;
    private final ServiceCategoryRepository categoryRepository;
    private final NotificationService notificationService;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<AdminServiceDto> getAllServices() {
        return serviceRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public AdminServiceDto convertToDto(com.servio.backend.entity.Service service) {
        return AdminServiceDto.builder()
                .id(service.getId())
                .categoryId(service.getCategory() != null ? service.getCategory().getId() : null)
                .categoryName(service.getCategory() != null ? service.getCategory().getName() : null)
                .name(service.getName())
                .description(service.getDescription())
                .basePrice(service.getBasePrice())
                .priceRange(service.getPriceRange())
                .durationMinutes(service.getDurationMinutes())
                .imageUrl(service.getImageUrl())
                .iconUrl(service.getIconUrl())
                .status(service.getStatus() != null ? service.getStatus().name() : null)
                .warrantyIncluded(service.getWarrantyIncluded())
                .isFeatured(service.getIsFeatured())
                .isActive(service.getIsActive())
                .publishedAt(service.getPublishedAt())
                .customerNotifiedAt(service.getCustomerNotifiedAt())
                .includedItems(service.getIncludedItems() != null ? service.getIncludedItems() : List.of())
                .options(mapOptionRequests(service.getOptions()))
                .photos(mapPhotoDtos(service.getPhotos()))
                .createdAt(service.getCreatedAt())
                .updatedAt(service.getUpdatedAt())
                .build();
    }

    private List<ServiceOptionRequest> mapOptionRequests(List<ServiceOption> options) {
        if (options == null) return List.of();
        return options.stream()
                .sorted(Comparator.comparing(o -> o.getDisplayOrder() != null ? o.getDisplayOrder() : 0))
                .map(option -> {
                    ServiceOptionRequest dto = new ServiceOptionRequest();
                    dto.setId(option.getId());
                    dto.setName(option.getName());
                    dto.setDescription(option.getDescription());
                    dto.setPriceAdjustment(option.getPriceAdjustment());
                    dto.setIsDefault(option.getIsDefault());
                    dto.setDisplayOrder(option.getDisplayOrder());
                    return dto;
                })
                .collect(Collectors.toList());
    }

    private List<ServicePhotoDto> mapPhotoDtos(List<ServicePhoto> photos) {
        if (photos == null) return List.of();
        return photos.stream()
                .sorted(Comparator.comparing(p -> p.getDisplayOrder() != null ? p.getDisplayOrder() : 0))
                .map(photo -> ServicePhotoDto.builder()
                        .id(photo.getId())
                        .url(photo.getUrl())
                        .publicId(photo.getPublicId())
                        .displayOrder(photo.getDisplayOrder())
                        .isPrimary(photo.getIsPrimary())
                        .build())
                .collect(Collectors.toList());
    }

    public com.servio.backend.entity.Service getServiceById(Long id) {
        return serviceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service not found with id: " + id));
    }

    @Transactional
    public com.servio.backend.entity.Service createService(ServiceRequest request) {
        ServiceCategory category = resolveCategory(request.getCategoryId());

        com.servio.backend.entity.Service service = new com.servio.backend.entity.Service();
        service.setCategory(category);
        service.setName(request.getName());
        service.setDescription(request.getDescription());
        service.setBasePrice(request.getBasePrice());
        service.setPriceRange(request.getPriceRange());
        service.setDurationMinutes(request.getDurationMinutes());
        service.setImageUrl(request.getImageUrl());
        service.setIconUrl(request.getIconUrl());
        service.setStatus(parseStatus(request.getStatus(), request.getIsActive()));
        service.setWarrantyIncluded(request.getWarrantyIncluded());
        service.setIsFeatured(request.getIsFeatured());
        service.setIsActive(service.getStatus() == ServiceStatus.PUBLISHED);
        if (service.getStatus() == ServiceStatus.PUBLISHED) {
            service.setPublishedAt(LocalDateTime.now());
        }
        syncIncludedItems(service, request.getIncludedItems());
        syncOptions(service, request.getOptions());
        syncPhotos(service, request.getPhotos());
        syncPrimaryImage(service);

        com.servio.backend.entity.Service saved = serviceRepository.save(service);
        if (saved.getStatus() == ServiceStatus.PUBLISHED) {
            notifyCustomersIfNeeded(saved);
        }
        return saved;
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
        if (request.getIconUrl() != null) {
            service.setIconUrl(request.getIconUrl());
        }
        if (request.getStatus() != null) {
            ServiceStatus previousStatus = service.getStatus();
            service.setStatus(parseStatus(request.getStatus(), request.getIsActive()));
            if (previousStatus != ServiceStatus.PUBLISHED && service.getStatus() == ServiceStatus.PUBLISHED && service.getPublishedAt() == null) {
                service.setPublishedAt(LocalDateTime.now());
            }
        }
        if (request.getWarrantyIncluded() != null) {
            service.setWarrantyIncluded(request.getWarrantyIncluded());
        }
        if (request.getIsFeatured() != null) {
            service.setIsFeatured(request.getIsFeatured());
        }
        service.setIsActive(service.getStatus() == ServiceStatus.PUBLISHED);
        if (request.getIncludedItems() != null) {
            syncIncludedItems(service, request.getIncludedItems());
        }
        if (request.getOptions() != null) {
            syncOptions(service, request.getOptions());
        }
        if (request.getPhotos() != null) {
            syncPhotos(service, request.getPhotos());
            syncPrimaryImage(service);
        }

        com.servio.backend.entity.Service saved = serviceRepository.save(service);
        if (saved.getStatus() == ServiceStatus.PUBLISHED) {
            notifyCustomersIfNeeded(saved);
        }
        return saved;
    }

    @Transactional
    public com.servio.backend.entity.Service toggleServiceStatus(Long id, ServiceToggleRequest request) {
        com.servio.backend.entity.Service service = getServiceById(id);
        service.setStatus(Boolean.TRUE.equals(request.getIsActive()) ? ServiceStatus.PUBLISHED : ServiceStatus.HIDDEN);
        service.setIsActive(service.getStatus() == ServiceStatus.PUBLISHED);
        if (service.getStatus() == ServiceStatus.PUBLISHED && service.getPublishedAt() == null) {
            service.setPublishedAt(LocalDateTime.now());
        }
        com.servio.backend.entity.Service saved = serviceRepository.save(service);
        if (saved.getStatus() == ServiceStatus.PUBLISHED) {
            notifyCustomersIfNeeded(saved);
        }
        return saved;
    }

    @Transactional
    public com.servio.backend.entity.Service publishService(Long id) {
        com.servio.backend.entity.Service service = getServiceById(id);
        service.setStatus(ServiceStatus.PUBLISHED);
        service.setIsActive(true);
        if (service.getPublishedAt() == null) {
            service.setPublishedAt(LocalDateTime.now());
        }
        com.servio.backend.entity.Service saved = serviceRepository.save(service);
        notifyCustomersIfNeeded(saved);
        return saved;
    }

    @Transactional
    public com.servio.backend.entity.Service hideService(Long id) {
        com.servio.backend.entity.Service service = getServiceById(id);
        service.setStatus(ServiceStatus.HIDDEN);
        service.setIsActive(false);
        return serviceRepository.save(service);
    }

    @Transactional
    public void deleteService(Long id) {
        if (!serviceRepository.existsById(id)) {
            throw new RuntimeException("Service not found with id: " + id);
        }
        serviceRepository.deleteById(id);
    }

    private ServiceStatus parseStatus(String status, Boolean isActive) {
        if (status != null && !status.isBlank()) {
            try {
                return ServiceStatus.valueOf(status.toUpperCase());
            } catch (IllegalArgumentException ignored) {
                throw new RuntimeException("Invalid service status: " + status);
            }
        }
        return Boolean.FALSE.equals(isActive) ? ServiceStatus.HIDDEN : ServiceStatus.PUBLISHED;
    }

    private ServiceCategory resolveCategory(Long categoryId) {
        if (categoryId != null) {
            return categoryRepository.findById(categoryId)
                    .orElseThrow(() -> new RuntimeException("Category not found with id: " + categoryId));
        }

        return categoryRepository.findByIsActiveTrueOrderByDisplayOrderAsc().stream()
                .findFirst()
                .orElseThrow(() -> new RuntimeException("No active service category found"));
    }

    private void syncIncludedItems(com.servio.backend.entity.Service service, List<String> includedItems) {
        List<String> cleaned = includedItems == null
                ? new ArrayList<>()
                : includedItems.stream()
                    .filter(Objects::nonNull)
                    .map(String::trim)
                    .filter(item -> !item.isEmpty())
                    .collect(Collectors.toList());
        service.setIncludedItems(cleaned);
    }

    private void syncOptions(com.servio.backend.entity.Service service, List<ServiceOptionRequest> optionRequests) {
        List<ServiceOptionRequest> cleanedRequests = optionRequests == null
                ? List.of()
                : optionRequests.stream()
                    .filter(o -> o.getName() != null && !o.getName().trim().isEmpty())
                    .collect(Collectors.toList());

        if (!cleanedRequests.isEmpty()) {
            java.util.LinkedHashMap<String, ServiceOptionRequest> deduped = new java.util.LinkedHashMap<>();
            for (ServiceOptionRequest request : cleanedRequests) {
                String key = request.getName().trim().toLowerCase();
                deduped.putIfAbsent(key, request);
            }
            cleanedRequests = new java.util.ArrayList<>(deduped.values());
        }

        if (service.getOptions() == null) {
            service.setOptions(new ArrayList<>());
        }

        // Remove options that are no longer in the request
        List<String> requestNames = cleanedRequests.stream()
                .map(r -> r.getName().trim().toLowerCase())
                .collect(Collectors.toList());
        service.getOptions().removeIf(existing -> 
                !requestNames.contains(existing.getName().trim().toLowerCase()));

        boolean hasDefault = cleanedRequests.stream().anyMatch(o -> Boolean.TRUE.equals(o.getIsDefault()));
        for (int i = 0; i < cleanedRequests.size(); i++) {
            ServiceOptionRequest request = cleanedRequests.get(i);
            String requestName = request.getName().trim();

            ServiceOption existingOption = service.getOptions().stream()
                    .filter(o -> o.getName().trim().equalsIgnoreCase(requestName))
                    .findFirst()
                    .orElse(null);

            if (existingOption != null) {
                existingOption.setDescription(request.getDescription());
                existingOption.setPriceAdjustment(request.getPriceAdjustment() != null ? request.getPriceAdjustment() : BigDecimal.ZERO);
                existingOption.setIsDefault(hasDefault ? Boolean.TRUE.equals(request.getIsDefault()) : i == 0);
                existingOption.setDisplayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : i);
            } else {
                ServiceOption newOption = new ServiceOption();
                newOption.setService(service);
                newOption.setName(requestName);
                newOption.setDescription(request.getDescription());
                newOption.setPriceAdjustment(request.getPriceAdjustment() != null ? request.getPriceAdjustment() : BigDecimal.ZERO);
                newOption.setIsDefault(hasDefault ? Boolean.TRUE.equals(request.getIsDefault()) : i == 0);
                newOption.setDisplayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : i);
                service.getOptions().add(newOption);
            }
        }
    }

    private void syncPhotos(com.servio.backend.entity.Service service, List<ServicePhotoDto> photoDtos) {
        List<ServicePhotoDto> cleanedPhotos = photoDtos == null
                ? List.of()
                : photoDtos.stream()
                    .filter(p -> p.getUrl() != null && !p.getUrl().trim().isEmpty())
                    .collect(Collectors.toList());

        if (service.getPhotos() == null) {
            service.setPhotos(new ArrayList<>());
        }
        service.getPhotos().clear();

        boolean hasPrimary = cleanedPhotos.stream().anyMatch(p -> Boolean.TRUE.equals(p.getIsPrimary()));
        for (int i = 0; i < cleanedPhotos.size(); i++) {
            ServicePhotoDto dto = cleanedPhotos.get(i);
            ServicePhoto photo = new ServicePhoto();
            photo.setService(service);
            photo.setUrl(dto.getUrl().trim());
            photo.setPublicId(dto.getPublicId());
            photo.setDisplayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : i);
            photo.setIsPrimary(hasPrimary ? Boolean.TRUE.equals(dto.getIsPrimary()) : i == 0);
            service.getPhotos().add(photo);
        }
    }

    private void syncPrimaryImage(com.servio.backend.entity.Service service) {
        if (service.getPhotos() == null || service.getPhotos().isEmpty()) {
            return;
        }
        service.getPhotos().stream()
                .filter(photo -> Boolean.TRUE.equals(photo.getIsPrimary()))
                .findFirst()
                .or(() -> service.getPhotos().stream().min(Comparator.comparing(p -> p.getDisplayOrder() != null ? p.getDisplayOrder() : 0)))
                .ifPresent(photo -> service.setImageUrl(photo.getUrl()));
    }

    private void notifyCustomersIfNeeded(com.servio.backend.entity.Service service) {
        if (service.getCustomerNotifiedAt() != null) {
            return;
        }
        String price = service.getBasePrice() != null
                ? "from LKR " + service.getBasePrice().setScale(0, java.math.RoundingMode.HALF_UP).toPlainString()
                : service.getPriceRange();
        String message = String.format("%s is now available%s.", service.getName(), price != null ? " " + price : "");

        List<User> customers = userRepository.findAll().stream()
                .filter(user -> user.getRole() == Role.USER || user.getRole() == Role.CUSTOMER)
                .collect(Collectors.toList());
        for (User user : customers) {
            notificationService.createNotification(NotificationRequest.builder()
                    .userId(user.getId())
                    .title("New service available")
                    .message(message)
                    .type("SERVICE")
                    .build());
        }
        service.setCustomerNotifiedAt(LocalDateTime.now());
    }
}
