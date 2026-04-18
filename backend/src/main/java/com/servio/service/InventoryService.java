package com.servio.service;

import com.servio.dto.admin.InventoryItemDto;
import com.servio.dto.admin.InventoryItemRequest;
import com.servio.dto.admin.StockTransactionDto;
import com.servio.dto.admin.StockUpdateRequest;
import com.servio.entity.InventoryItem;
import com.servio.entity.StockTransaction;
import com.servio.repository.InventoryRepository;
import com.servio.repository.StockTransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryRepository inventoryRepository;
    private final StockTransactionRepository stockTransactionRepository;

    public List<InventoryItemDto> getAllItems() {
        return inventoryRepository.findAll().stream()
                .map(this::mapToItemDto)
                .collect(Collectors.toList());
    }

    public InventoryItemDto getItemById(Long id) {
        InventoryItem item = findItemById(id);
        return mapToItemDto(item);
    }

    public List<InventoryItemDto> getLowStockItems() {
        return inventoryRepository.findLowStockItems().stream()
                .map(this::mapToItemDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public InventoryItemDto createItem(InventoryItemRequest request, String adminUsername) {
        InventoryItem item = InventoryItem.builder()
                .name(request.getName())
                .category(request.getCategory())
                .unit(request.getUnit())
                .currentStock(request.getCurrentStock() != null ? request.getCurrentStock() : BigDecimal.ZERO)
                .minimumStock(request.getMinimumStock() != null ? request.getMinimumStock() : BigDecimal.ZERO)
                .costPerUnit(request.getCostPerUnit())
                .sellingPricePerUnit(request.getSellingPricePerUnit())
                .serviceType(request.getServiceType())
                .build();
        
        InventoryItem savedItem = inventoryRepository.save(item);

        // Record initial stock if greater than 0
        if (savedItem.getCurrentStock().compareTo(BigDecimal.ZERO) > 0) {
            StockTransaction transaction = StockTransaction.builder()
                    .inventoryItem(savedItem)
                    .type("RECEIVE")
                    .quantity(savedItem.getCurrentStock())
                    .notes("Initial stock on creation")
                    .performedBy(adminUsername)
                    .build();
            stockTransactionRepository.save(transaction);
        }

        return mapToItemDto(savedItem);
    }

    @Transactional
    public InventoryItemDto updateItem(Long id, InventoryItemRequest request) {
        InventoryItem item = findItemById(id);
        item.setName(request.getName());
        item.setCategory(request.getCategory());
        item.setUnit(request.getUnit());
        item.setMinimumStock(request.getMinimumStock());
        item.setCostPerUnit(request.getCostPerUnit());
        item.setSellingPricePerUnit(request.getSellingPricePerUnit());
        item.setServiceType(request.getServiceType());
        // Note: currentStock is not updated directly here, use updateStock instead

        return mapToItemDto(inventoryRepository.save(item));
    }

    @Transactional
    public void deleteItem(Long id) {
        if (!inventoryRepository.existsById(id)) {
            throw new IllegalArgumentException("Inventory item not found");
        }
        inventoryRepository.deleteById(id);
    }

    @Transactional
    public InventoryItemDto updateStock(Long id, StockUpdateRequest request, String adminUsername) {
        InventoryItem item = findItemById(id);

        BigDecimal quantity = request.getQuantity();
        String type = request.getType().toUpperCase();

        if (type.equals("CONSUME")) {
            if (item.getCurrentStock().compareTo(quantity) < 0) {
                throw new IllegalArgumentException("Insufficient stock to consume");
            }
            item.setCurrentStock(item.getCurrentStock().subtract(quantity));
        } else if (type.equals("RECEIVE") || type.equals("ADJUST")) {
            // For RECEIVE, we add to current stock. For ADJUST, we add positive or subtract negative
            item.setCurrentStock(item.getCurrentStock().add(quantity));
        } else {
            throw new IllegalArgumentException("Invalid transaction type: " + type);
        }

        InventoryItem savedItem = inventoryRepository.save(item);

        StockTransaction transaction = StockTransaction.builder()
                .inventoryItem(savedItem)
                .type(type)
                .quantity(quantity)
                .notes(request.getNotes())
                .performedBy(adminUsername)
                .build();
        stockTransactionRepository.save(transaction);

        return mapToItemDto(savedItem);
    }

    public List<StockTransactionDto> getTransactionHistory(Long itemId) {
        // verify item exists
        findItemById(itemId);

        return stockTransactionRepository.findByInventoryItemIdOrderByCreatedAtDesc(itemId).stream()
                .map(this::mapToTransactionDto)
                .collect(Collectors.toList());
    }

    private InventoryItem findItemById(Long id) {
        return inventoryRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Inventory item not found"));
    }

    private InventoryItemDto mapToItemDto(InventoryItem item) {
        boolean lowStock = item.getCurrentStock().compareTo(item.getMinimumStock()) < 0;
        return InventoryItemDto.builder()
                .id(item.getId())
                .name(item.getName())
                .category(item.getCategory())
                .unit(item.getUnit())
                .currentStock(item.getCurrentStock())
                .minimumStock(item.getMinimumStock())
                .costPerUnit(item.getCostPerUnit())
                .sellingPricePerUnit(item.getSellingPricePerUnit())
                .serviceType(item.getServiceType())
                .lowStock(lowStock)
                .createdAt(item.getCreatedAt())
                .updatedAt(item.getUpdatedAt())
                .build();
    }

    private StockTransactionDto mapToTransactionDto(StockTransaction tx) {
        return StockTransactionDto.builder()
                .id(tx.getId())
                .inventoryItemId(tx.getInventoryItem().getId())
                .itemName(tx.getInventoryItem().getName())
                .type(tx.getType())
                .quantity(tx.getQuantity())
                .notes(tx.getNotes())
                .performedBy(tx.getPerformedBy())
                .createdAt(tx.getCreatedAt())
                .build();
    }
}
