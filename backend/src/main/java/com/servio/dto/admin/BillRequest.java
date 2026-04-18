package com.servio.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillRequest {
    private String customerName;
    private String customerAddress;
    private String customerPhone;
    private String vehicleType;
    private String vehicleNo;
    private String paymentMode;
    private BigDecimal subTotal;
    private BigDecimal discount;
    private BigDecimal netTotal;
    private String currentMeterReading;
    private String nextServiceDue;
    private List<BillItemRequest> items;
}
