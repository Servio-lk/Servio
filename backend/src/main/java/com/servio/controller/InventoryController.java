package com.servio.controller;

import com.servio.dto.admin.InventoryItemDto;
import com.servio.dto.admin.InventoryItemRequest;
import com.servio.dto.admin.StockTransactionDto;
import com.servio.dto.admin.StockUpdateRequest;
import com.servio.dto.ApiResponse;
import com.servio.service.InventoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<List<InventoryItemDto>>> getAllItems() {
        return ResponseEntity.ok(ApiResponse.<List<InventoryItemDto>>builder()
                .success(true)
                .data(inventoryService.getAllItems())
                .build());
    }

    @GetMapping("/low-stock")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<List<InventoryItemDto>>> getLowStockItems() {
        return ResponseEntity.ok(ApiResponse.<List<InventoryItemDto>>builder()
                .success(true)
                .data(inventoryService.getLowStockItems())
                .build());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<InventoryItemDto>> getItemById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.<InventoryItemDto>builder()
                .success(true)
                .data(inventoryService.getItemById(id))
                .build());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<InventoryItemDto>> createItem(
            @Valid @RequestBody InventoryItemRequest request,
            Authentication authentication) {
        String performedBy = authentication != null ? authentication.getName() : "System";
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.<InventoryItemDto>builder()
                .success(true)
                .message("Inventory item created successfully")
                .data(inventoryService.createItem(request, performedBy))
                .build());
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<InventoryItemDto>> updateItem(
            @PathVariable Long id,
            @Valid @RequestBody InventoryItemRequest request) {
        return ResponseEntity.ok(ApiResponse.<InventoryItemDto>builder()
                .success(true)
                .message("Inventory item updated successfully")
                .data(inventoryService.updateItem(id, request))
                .build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteItem(@PathVariable Long id) {
        inventoryService.deleteItem(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Inventory item deleted successfully")
                .build());
    }

    @PostMapping("/{id}/stock")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<InventoryItemDto>> updateStock(
            @PathVariable Long id,
            @Valid @RequestBody StockUpdateRequest request,
            Authentication authentication) {
        String performedBy = authentication != null ? authentication.getName() : "System";
        return ResponseEntity.ok(ApiResponse.<InventoryItemDto>builder()
                .success(true)
                .message("Stock updated successfully")
                .data(inventoryService.updateStock(id, request, performedBy))
                .build());
    }

    @GetMapping("/{id}/transactions")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<List<StockTransactionDto>>> getTransactionHistory(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.<List<StockTransactionDto>>builder()
                .success(true)
                .data(inventoryService.getTransactionHistory(id))
                .build());
    }
}
