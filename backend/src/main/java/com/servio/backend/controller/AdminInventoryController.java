package com.servio.backend.controller;

import com.servio.backend.entity.InventoryItem;
import com.servio.backend.repository.InventoryItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/admin/inventory")
@RequiredArgsConstructor
public class AdminInventoryController {

    private final InventoryItemRepository inventoryItemRepository;

    @GetMapping
    public ResponseEntity<List<InventoryItem>> getAllInventory() {
        return ResponseEntity.ok(inventoryItemRepository.findAll());
    }

    @PostMapping
    public ResponseEntity<InventoryItem> createInventoryItem(@RequestBody InventoryItem item) {
        return ResponseEntity.ok(inventoryItemRepository.save(item));
    }

    @PutMapping("/{id}")
    public ResponseEntity<InventoryItem> updateInventoryItem(@PathVariable Long id,
            @RequestBody InventoryItem itemDetails) {
        InventoryItem item = inventoryItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Inventory item not found"));

        item.setName(itemDetails.getName());
        item.setDescription(itemDetails.getDescription());
        item.setQuantity(itemDetails.getQuantity());
        item.setUnit(itemDetails.getUnit());
        item.setPrice(itemDetails.getPrice());
        item.setMinStockLevel(itemDetails.getMinStockLevel());
        item.setUpdatedAt(LocalDateTime.now());

        return ResponseEntity.ok(inventoryItemRepository.save(item));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteInventoryItem(@PathVariable Long id) {
        InventoryItem item = inventoryItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Inventory item not found"));

        inventoryItemRepository.delete(item);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/stock")
    public ResponseEntity<InventoryItem> updateStock(@PathVariable Long id,
            @RequestBody java.util.Map<String, java.math.BigDecimal> update) {
        InventoryItem item = inventoryItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Inventory item not found"));

        item.setQuantity(update.get("quantity"));
        item.setUpdatedAt(LocalDateTime.now());

        return ResponseEntity.ok(inventoryItemRepository.save(item));
    }
}
