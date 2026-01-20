package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.entity.User;
import com.servio.service.AdminCustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/customers")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminCustomerController {

    private final AdminCustomerService adminCustomerService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<User>>> getAllCustomers(
            @RequestParam(required = false) String search) {
        List<User> customers = search != null && !search.isEmpty()
                ? adminCustomerService.searchCustomers(search)
                : adminCustomerService.getAllCustomers();
        return ResponseEntity.ok(ApiResponse.success("Customers retrieved successfully", customers));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<User>> getCustomerById(@PathVariable Long id) {
        User customer = adminCustomerService.getCustomerById(id);
        return ResponseEntity.ok(ApiResponse.success("Customer retrieved successfully", customer));
    }
}
