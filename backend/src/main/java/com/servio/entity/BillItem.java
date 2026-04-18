package com.servio.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "billing_invoice_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bill_id", nullable = false)
    @JsonIgnore
    private Bill bill;

    @Column(name = "inventory_item_id")
    private Long inventoryItemId;

    @Column(nullable = false)
    private String description;

    @Column(nullable = false, precision = 19, scale = 2, columnDefinition = "NUMERIC(19,2)")
    private BigDecimal quantity;

    @Column(nullable = false, precision = 19, scale = 2, columnDefinition = "NUMERIC(19,2)")
    private BigDecimal rate;

    @Column(nullable = false, precision = 19, scale = 2, columnDefinition = "NUMERIC(19,2)")
    private BigDecimal amount;
}
