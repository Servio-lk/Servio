package com.servio.service;

import com.servio.entity.Profile;
import com.servio.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminCustomerService {

    private final ProfileRepository profileRepository;

    public List<Profile> getAllCustomers() {
        return profileRepository.findAll();
    }

    public Profile getCustomerById(String id) {
        UUID uuid = UUID.fromString(id);
        return profileRepository.findById(uuid)
                .orElseThrow(() -> new RuntimeException("Customer not found with id: " + id));
    }

    public List<Profile> searchCustomers(String query) {
        return profileRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(query, query);
    }
}
