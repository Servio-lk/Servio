package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "billing_invoices")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Bill {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "invoice_no", unique = true, nullable = false)
    private String invoiceNo;

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime date = LocalDateTime.now();

    @Column(name = "customer_name")
    private String customerName;

    @Column(name = "customer_address")
    private String customerAddress;

    @Column(name = "customer_phone")
    private String customerPhone;

    @Column(name = "vehicle_type")
    private String vehicleType;

    @Column(name = "vehicle_no")
    private String vehicleNo;

    @Column(name = "payment_mode")
    private String paymentMode;

    @Column(name = "sub_total", precision = 19, scale = 2, columnDefinition = "NUMERIC(19,2)")
    private BigDecimal subTotal;

    @Column(precision = 19, scale = 2, columnDefinition = "NUMERIC(19,2)")
    private BigDecimal discount;

    @Column(name = "net_total", precision = 19, scale = 2, columnDefinition = "NUMERIC(19,2)")
    private BigDecimal netTotal;

    @Column(name = "current_meter_reading")
    private String currentMeterReading;

    @Column(name = "next_service_due")
    private String nextServiceDue;

    @Column(name = "issued_by")
    private String issuedBy;

    @OneToMany(mappedBy = "bill", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    private List<BillItem> items = new ArrayList<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
