package com.servio.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockTransactionDto {
    private Long id;
    private Long inventoryItemId;
    private String itemName;
    private String type; // RECEIVE, CONSUME, ADJUST
    private BigDecimal quantity;
    private String notes;
    private String performedBy;
    private LocalDateTime createdAt;
}
