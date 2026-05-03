package com.servio.backend.config;

import com.servio.backend.entity.Service;
import com.servio.backend.entity.ServiceCategory;
import com.servio.backend.entity.ServiceOption;
import com.servio.backend.repository.ServiceCategoryRepository;
import com.servio.backend.repository.ServiceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final ServiceCategoryRepository categoryRepository;
    private final ServiceRepository serviceRepository;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Checking if database seeding is required...");

        if (categoryRepository.count() == 0) {
            log.info("Database is empty. Seeding initial categories and services...");
            seedServices();
            log.info("Database seeding completed successfully.");
        } else {
            log.info("Database is already seeded. Skipping.");
        }
    }

    private void seedServices() {
        // 1. Periodic Maintenance
        ServiceCategory periodic = new ServiceCategory();
        periodic.setName("Periodic Maintenance");
        periodic.setDescription("Regular maintenance to keep your vehicle running smoothly");
        periodic.setDisplayOrder(1);
        periodic = categoryRepository.save(periodic);

        createService(periodic, "Washing Packages", "from LKR 500", new BigDecimal("500"));
        createLubeService(periodic);
        createService(periodic, "Exterior & Interior Detailing", "from LKR 3,000", new BigDecimal("3000"));
        createEngineTuneUps(periodic);
        createService(periodic, "Inspection Reports", "from LKR 1,000", new BigDecimal("1000"));
        createService(periodic, "Tyre Services", "from LKR 800", new BigDecimal("800"));
        createService(periodic, "Waxing", "from LKR 1,200", new BigDecimal("1200"));
        createService(periodic, "Undercarriage Degreasing", "from LKR 2,000", new BigDecimal("2000"));
        createService(periodic, "Windscreen Treatments", "from LKR 1,500", new BigDecimal("1500"));
        createService(periodic, "Battery Services", "from LKR 500", new BigDecimal("500"));

        createService(periodic, "AC Services", "from LKR 1,200", new BigDecimal("1200"));
        createService(periodic, "Hybrid Services", "from LKR 3,500", new BigDecimal("3500"));

        // 2. Nano Coating
        ServiceCategory nano = new ServiceCategory();
        nano.setName("Nano Coating");
        nano.setDescription("Premium protection for your vehicle's exterior");
        nano.setDisplayOrder(2);
        nano = categoryRepository.save(nano);

        createService(nano, "Packages", "from LKR 15,000", new BigDecimal("15000"));
        createService(nano, "Treatments", "from LKR 8,000", new BigDecimal("8000"));

        // 3. Collision Repairs
        ServiceCategory collision = new ServiceCategory();
        collision.setName("Collision Repairs");
        collision.setDescription("Expert repair services for vehicle damage");
        collision.setDisplayOrder(3);
        collision = categoryRepository.save(collision);

        createService(collision, "Insurance Claims", "Quote required", BigDecimal.ZERO);
        createService(collision, "Wheel Alignment", "from LKR 2,000", new BigDecimal("2000"));
        createService(collision, "Full Paints", "from LKR 50,000", new BigDecimal("50000"));
        createService(collision, "Part Replacements", "Quote required", BigDecimal.ZERO);
        createService(collision, "Repair & Modifications", "from LKR 2,000", new BigDecimal("2000"));
    }

    private void createService(ServiceCategory category, String name, String priceRange, BigDecimal basePrice) {
        Service service = new Service();
        service.setCategory(category);
        service.setName(name);
        service.setPriceRange(priceRange);
        if (basePrice.compareTo(BigDecimal.ZERO) > 0) {
            service.setBasePrice(basePrice);
        }
        service.setIsActive(true);
        service.setIsFeatured(false);
        serviceRepository.save(service);
    }

    private void createEngineTuneUps(ServiceCategory category) {
        Service service = baseService(category, "Engine Tune ups", "from LKR 2,500", new BigDecimal("2500"));
        service.setDescription("Keep your engine running at peak performance with our professional tune-up service. We inspect and adjust all critical components.");
        service.setDurationMinutes(120);
        service.setWarrantyIncluded(true);
        service.setIncludedItems(List.of(
                "Spark plug check",
                "Air filter replacement",
                "Fuel injector cleaning",
                "Performance diagnostics"
        ));
        serviceRepository.save(service);
    }

    private void createLubeService(ServiceCategory category) {
        Service service = baseService(category, "Lube Services", "from LKR 1,500", new BigDecimal("1500"));
        service.setDescription("Professional oil change with premium lubricants to protect your engine. Our certified technicians use only high-quality filters.");
        service.setDurationMinutes(45);
        service.setWarrantyIncluded(true);
        service.setIncludedItems(List.of(
                "Premium quality oil",
                "Oil filter replacement",
                "Multi-point inspection",
                "Fluid level check"
        ));

        List<ServiceOption> options = new ArrayList<>();
        options.add(option(service, "Standard/Conventional Oil", "Basic protection for everyday driving", new BigDecimal("4000"), true, 0));
        options.add(option(service, "Synthetic Blend Oil", "Enhanced protection and performance", new BigDecimal("5500"), false, 1));
        options.add(option(service, "Full Synthetic Oil", "Maximum protection for high-performance engines", new BigDecimal("7000"), false, 2));
        service.setOptions(options);

        serviceRepository.save(service);
    }

    private Service baseService(ServiceCategory category, String name, String priceRange, BigDecimal basePrice) {
        Service service = new Service();
        service.setCategory(category);
        service.setName(name);
        service.setPriceRange(priceRange);
        service.setBasePrice(basePrice);
        service.setIsActive(true);
        service.setIsFeatured(false);
        return service;
    }

    private ServiceOption option(Service service, String name, String description, BigDecimal price, boolean isDefault, int order) {
        ServiceOption option = new ServiceOption();
        option.setService(service);
        option.setName(name);
        option.setDescription(description);
        option.setPriceAdjustment(price);
        option.setIsDefault(isDefault);
        option.setDisplayOrder(order);
        return option;
    }
}
