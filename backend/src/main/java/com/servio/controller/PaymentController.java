package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PaymentController {
    
    private final PaymentService paymentService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<PaymentDto>> createPayment(@RequestBody PaymentRequest request) {
        PaymentDto payment = paymentService.createPayment(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.<PaymentDto>builder()
                .success(true)
                .message("Payment initiated successfully")
                .data(payment)
                .build());
    }
    
    @PostMapping("/{id}/process")
    public ResponseEntity<ApiResponse<PaymentDto>> processPayment(@PathVariable Long id) {
        PaymentDto payment = paymentService.processPayment(id);
        return ResponseEntity.ok(ApiResponse.<PaymentDto>builder()
            .success(true)
            .message("Payment processed successfully")
            .data(payment)
            .build());
    }
    
    @PostMapping("/{id}/refund")
    public ResponseEntity<ApiResponse<PaymentDto>> refundPayment(@PathVariable Long id) {
        PaymentDto payment = paymentService.refundPayment(id);
        return ResponseEntity.ok(ApiResponse.<PaymentDto>builder()
            .success(true)
            .message("Payment refunded successfully")
            .data(payment)
            .build());
    }
    
    @GetMapping
    public ResponseEntity<ApiResponse<List<PaymentDto>>> getAllPayments() {
        List<PaymentDto> payments = paymentService.getAllPayments();
        return ResponseEntity.ok(ApiResponse.<List<PaymentDto>>builder()
            .success(true)
            .message("Payments retrieved successfully")
            .data(payments)
            .build());
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<PaymentDto>>> getPaymentsByUserId(@PathVariable Long userId) {
        List<PaymentDto> payments = paymentService.getPaymentsByUserId(userId);
        return ResponseEntity.ok(ApiResponse.<List<PaymentDto>>builder()
            .success(true)
            .message("User payments retrieved successfully")
            .data(payments)
            .build());
    }
    
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<PaymentDto>>> getPaymentsByStatus(@PathVariable String status) {
        List<PaymentDto> payments = paymentService.getPaymentsByStatus(status);
        return ResponseEntity.ok(ApiResponse.<List<PaymentDto>>builder()
            .success(true)
            .message("Payments retrieved successfully")
            .data(payments)
            .build());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PaymentDto>> getPaymentById(@PathVariable Long id) {
        PaymentDto payment = paymentService.getPaymentById(id);
        return ResponseEntity.ok(ApiResponse.<PaymentDto>builder()
            .success(true)
            .message("Payment retrieved successfully")
            .data(payment)
            .build());
    }
    
    @GetMapping("/user/{userId}/stats")
    public ResponseEntity<ApiResponse<PaymentStatsDto>> getPaymentStats(@PathVariable Long userId) {
        PaymentStatsDto stats = paymentService.getPaymentStats(userId);
        return ResponseEntity.ok(ApiResponse.<PaymentStatsDto>builder()
            .success(true)
            .message("Payment statistics retrieved successfully")
            .data(stats)
            .build());
    }
    
    @GetMapping("/revenue")
    public ResponseEntity<ApiResponse<BigDecimal>> getRevenueByPeriod(
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate
    ) {
        BigDecimal revenue = paymentService.getRevenueByPeriod(startDate, endDate);
        return ResponseEntity.ok(ApiResponse.<BigDecimal>builder()
            .success(true)
            .message("Revenue retrieved successfully")
            .data(revenue)
            .build());
    }
}
