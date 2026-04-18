package com.servio.service;

import com.servio.dto.admin.BillItemRequest;
import com.servio.dto.admin.BillRequest;
import com.servio.dto.admin.StockUpdateRequest;
import com.servio.entity.Bill;
import com.servio.entity.BillItem;
import com.servio.repository.BillRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BillService {
    private final BillRepository billRepository;
    private final InventoryService inventoryService;

    @Transactional
    public Bill createBill(BillRequest request, String adminUsername) {
        String invoiceNo = generateInvoiceNumber();

        Bill bill = Bill.builder()
                .invoiceNo(invoiceNo)
                .date(LocalDateTime.now())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerPhone(request.getCustomerPhone())
                .vehicleType(request.getVehicleType())
                .vehicleNo(request.getVehicleNo())
                .paymentMode(request.getPaymentMode())
                .subTotal(request.getSubTotal())
                .discount(request.getDiscount())
                .netTotal(request.getNetTotal())
                .currentMeterReading(request.getCurrentMeterReading())
                .nextServiceDue(request.getNextServiceDue())
                .issuedBy(adminUsername)
                .build();

        List<BillItem> items = request.getItems().stream()
                .map(itemRequest -> {
                    BillItem item = BillItem.builder()
                            .bill(bill)
                            .inventoryItemId(itemRequest.getInventoryItemId())
                            .description(itemRequest.getDescription())
                            .quantity(itemRequest.getQuantity())
                            .rate(itemRequest.getRate())
                            .amount(itemRequest.getAmount())
                            .build();

                    // If it's an inventory item, deduct stock
                    if (itemRequest.getInventoryItemId() != null) {
                        StockUpdateRequest stockRequest = StockUpdateRequest.builder()
                                .type("CONSUME")
                                .quantity(itemRequest.getQuantity())
                                .notes("Issued in Invoice: " + invoiceNo)
                                .build();
                        inventoryService.updateStock(itemRequest.getInventoryItemId(), stockRequest, adminUsername);
                    }

                    return item;
                })
                .collect(Collectors.toList());

        bill.setItems(items);
        return billRepository.save(bill);
    }

    public List<Bill> getAllBills() {
        return billRepository.findAll();
    }

    public Bill getBillById(Long id) {
        return billRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Bill not found"));
    }

    private String generateInvoiceNumber() {
        Long maxId = billRepository.findMaxId();
        long nextId = (maxId == null) ? 1 : maxId + 1;
        String year = String.valueOf(LocalDateTime.now().getYear());
        return String.format("INV-%s-%04d", year, nextId);
    }
}
