package com.servio.admin.service;


import com.servio.common.event.PaymentCompletedEvent;
import com.servio.admin.dto.AppointmentUpdateRequest;
import com.servio.admin.dto.PaymentCollectionRequest;
import com.servio.booking.entity.Appointment;
import com.servio.payment.entity.Payment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminAppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final PaymentRepository paymentRepository;
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional(readOnly = true)
    public List<Appointment> getAllAppointments() {
        return appointmentRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<Appointment> getAppointmentsByStatus(String status) {
        return appointmentRepository.findByStatus(status);
    }

    @Transactional
    public Appointment getAppointmentById(Long id) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Appointment not found with id: " + id));
        // Initialize lazy-loaded relationships
        if (appointment.getUser() != null) appointment.getUser().getId();
        if (appointment.getVehicle() != null) appointment.getVehicle().getId();
        return appointment;
    }

    @Transactional
    public Appointment updateAppointment(Long id, AppointmentUpdateRequest request) {
        Appointment appointment = getAppointmentById(id);
        if (request.getStatus() != null) appointment.setStatus(request.getStatus());
        if (request.getNotes() != null) appointment.setNotes(request.getNotes());
        if (request.getActualCost() != null) appointment.setActualCost(request.getActualCost());
        return appointmentRepository.save(appointment);
    }

    @Transactional
    public void recordPayment(Long appointmentId, PaymentCollectionRequest request) {
        Appointment appointment = getAppointmentById(appointmentId);

        Payment payment = Payment.builder()
                .appointment(appointment)
                .amount(request.getAmount())
                .paymentMethod(request.getPaymentMethod())
                .paymentStatus("COMPLETED")
                .paymentDate(LocalDateTime.now())
                .user(appointment.getUser())
                .build();

        // Set actual cost from payment amount if not already recorded
        if (appointment.getActualCost() == null) {
            appointment.setActualCost(request.getAmount());
            appointmentRepository.save(appointment);
        }

        paymentRepository.save(payment);

        UUID userId = appointment.getUser() != null ? appointment.getUser().getId() : null;
        applicationEventPublisher.publishEvent(new PaymentCompletedEvent(
                this,
                appointmentId,
                userId,
                request.getAmount() != null ? request.getAmount().doubleValue() : 0.0,
                request.getPaymentMethod() != null ? request.getPaymentMethod() : "CASH"
        ));
    }
}
