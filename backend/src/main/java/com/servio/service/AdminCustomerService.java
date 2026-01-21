package com.servio.service;

import com.servio.entity.User;
import com.servio.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminCustomerService {

    private final UserRepository userRepository;

    public List<User> getAllCustomers() {
        return userRepository.findAll();
    }

    public User getCustomerById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found with id: " + id));
    }

    public List<User> searchCustomers(String query) {
        // Simple search by email or name
        return userRepository.findAll().stream()
                .filter(user -> user.getEmail().toLowerCase().contains(query.toLowerCase()) ||
                                user.getFullName().toLowerCase().contains(query.toLowerCase()))
                .toList();
    }
}
