package com.servio.service;

import com.servio.dto.admin.AppointmentUpdateRequest;
import com.servio.dto.admin.PaymentCollectionRequest;
import com.servio.entity.Appointment;
import com.servio.entity.Payment;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminAppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final PaymentRepository paymentRepository;

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
        if (appointment.getProfile() != null) appointment.getProfile().getId();
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
                .build();

        // Link payment to the owning user/profile
        if (appointment.getUser() != null) {
            payment.setUser(appointment.getUser());
        } else if (appointment.getProfile() != null) {
            payment.setProfile(appointment.getProfile());
        }

        // Set actual cost from payment amount if not already recorded
        if (appointment.getActualCost() == null) {
            appointment.setActualCost(request.getAmount());
            appointmentRepository.save(appointment);
        }

        paymentRepository.save(payment);
    }
}
