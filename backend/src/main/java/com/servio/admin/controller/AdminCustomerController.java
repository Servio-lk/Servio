package com.servio.admin.controller;

import com.servio.admin.dto.AdminCustomerDetailsDto;
import com.servio.common.dto.ApiResponse;
import com.servio.auth.entity.Profile;
import com.servio.admin.service.AdminCustomerService;
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
    public ResponseEntity<ApiResponse<List<Profile>>> getAllCustomers(
            @RequestParam(required = false) String search) {
        List<Profile> customers = search != null && !search.isEmpty()
                ? adminCustomerService.searchCustomers(search)
                : adminCustomerService.getAllCustomers();
        return ResponseEntity.ok(ApiResponse.success("Customers retrieved successfully", customers));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Profile>> getCustomerById(@PathVariable String id) {
        Profile customer = adminCustomerService.getCustomerById(id);
        return ResponseEntity.ok(ApiResponse.success("Customer retrieved successfully", customer));
    }

    @GetMapping("/{id}/details")
    public ResponseEntity<ApiResponse<AdminCustomerDetailsDto>> getCustomerDetails(@PathVariable String id) {
        AdminCustomerDetailsDto details = adminCustomerService.getCustomerDetails(id);
        return ResponseEntity.ok(ApiResponse.success("Customer details retrieved successfully", details));
    }
}
