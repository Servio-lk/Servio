package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.admin.BillRequest;
import com.servio.entity.Bill;
import com.servio.service.BillService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/bills")
@RequiredArgsConstructor
public class BillController {
    private final BillService billService;

    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<Bill>> createBill(
            @Valid @RequestBody BillRequest request,
            Authentication authentication) {
        String adminUsername = (authentication != null) ? authentication.getName() : "System";
        Bill bill = billService.createBill(request, adminUsername);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.<Bill>builder()
                .success(true)
                .message("Bill created successfully")
                .data(bill)
                .build());
    }

    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<List<Bill>>> getAllBills() {
        return ResponseEntity.ok(ApiResponse.<List<Bill>>builder()
                .success(true)
                .data(billService.getAllBills())
                .build());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<Bill>> getBillById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.<Bill>builder()
                .success(true)
                .data(billService.getBillById(id))
                .build());
    }
}
