package com.servio.service;

import com.servio.dto.PaymentDto;
import com.servio.dto.PaymentRequest;
import com.servio.dto.PaymentStatsDto;
import com.servio.entity.Appointment;
import com.servio.entity.Payment;
import com.servio.entity.User;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.PaymentRepository;
import com.servio.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PaymentService {
    
    private final PaymentRepository paymentRepository;
    private final UserRepository userRepository;
    private final AppointmentRepository appointmentRepository;
    
    @Transactional
    public PaymentDto createPayment(PaymentRequest request) {
        User user = userRepository.findById(request.getUserId())
            .orElseThrow(() -> new RuntimeException("User not found with id: " + request.getUserId()));
        
        Appointment appointment = null;
        if (request.getAppointmentId() != null) {
            appointment = appointmentRepository.findById(request.getAppointmentId())
                .orElseThrow(() -> new RuntimeException("Appointment not found with id: " + request.getAppointmentId()));
        }
        
        Payment payment = Payment.builder()
            .user(user)
            .appointment(appointment)
            .amount(request.getAmount())
            .paymentMethod(request.getPaymentMethod())
            .paymentStatus("PENDING")
            .transactionId(generateTransactionId())
            .build();
        
        payment = paymentRepository.save(payment);
        return convertToDto(payment);
    }
    
    @Transactional
    public PaymentDto processPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found with id: " + paymentId));
        
        // Simulate payment processing
        payment.setPaymentStatus("COMPLETED");
        payment.setPaymentDate(LocalDateTime.now());
        
        // Update appointment if linked
        if (payment.getAppointment() != null) {
            Appointment appointment = payment.getAppointment();
            appointment.setActualCost(payment.getAmount());
            appointmentRepository.save(appointment);
        }
        
        payment = paymentRepository.save(payment);
        return convertToDto(payment);
    }
    
    @Transactional
    public PaymentDto refundPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
            .orElseThrow(() -> new RuntimeException("Payment not found with id: " + paymentId));
        
        if (!"COMPLETED".equals(payment.getPaymentStatus())) {
            throw new RuntimeException("Can only refund completed payments");
        }
        
        payment.setPaymentStatus("REFUNDED");
        payment = paymentRepository.save(payment);
        return convertToDto(payment);
    }
    
    public List<PaymentDto> getAllPayments() {
        return paymentRepository.findAll().stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<PaymentDto> getPaymentsByUserId(Long userId) {
        return paymentRepository.findUserPaymentsOrderByDate(userId).stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<PaymentDto> getPaymentsByStatus(String status) {
        return paymentRepository.findByPaymentStatus(status).stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public PaymentDto getPaymentById(Long id) {
        Payment payment = paymentRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Payment not found with id: " + id));
        return convertToDto(payment);
    }
    
    public PaymentStatsDto getPaymentStats(Long userId) {
        List<Payment> payments = paymentRepository.findUserPaymentsOrderByDate(userId);
        
        Long totalPayments = (long) payments.size();
        
        BigDecimal totalAmount = payments.stream()
            .filter(p -> "COMPLETED".equals(p.getPaymentStatus()))
            .map(Payment::getAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        Long pendingPayments = payments.stream()
            .filter(p -> "PENDING".equals(p.getPaymentStatus()))
            .count();
        
        Long completedPayments = payments.stream()
            .filter(p -> "COMPLETED".equals(p.getPaymentStatus()))
            .count();
        
        return PaymentStatsDto.builder()
            .userId(userId)
            .totalPayments(totalPayments)
            .totalAmount(totalAmount)
            .pendingPayments(pendingPayments)
            .completedPayments(completedPayments)
            .build();
    }
    
    public BigDecimal getRevenueByPeriod(LocalDateTime startDate, LocalDateTime endDate) {
        BigDecimal revenue = paymentRepository.getRevenueForPeriod(startDate, endDate);
        return revenue != null ? revenue : BigDecimal.ZERO;
    }
    
    private String generateTransactionId() {
        return "TXN" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
    
    private PaymentDto convertToDto(Payment payment) {
        return PaymentDto.builder()
            .id(payment.getId())
            .userId(payment.getUser().getId())
            .userName(payment.getUser().getFullName())
            .appointmentId(payment.getAppointment() != null ? payment.getAppointment().getId() : null)
            .amount(payment.getAmount())
            .paymentMethod(payment.getPaymentMethod())
            .paymentStatus(payment.getPaymentStatus())
            .transactionId(payment.getTransactionId())
            .paymentDate(payment.getPaymentDate())
            .createdAt(payment.getCreatedAt())
            .updatedAt(payment.getUpdatedAt())
            .build();
    }
}
