package com.servio.service;

import com.servio.dto.admin.AppointmentUpdateRequest;
import com.servio.entity.Appointment;
import com.servio.repository.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminAppointmentService {

    private final AppointmentRepository appointmentRepository;

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
        if (appointment.getUser() != null) {
            appointment.getUser().getId();
        }
        if (appointment.getProfile() != null) {
            appointment.getProfile().getId();
        }
        if (appointment.getVehicle() != null) {
            appointment.getVehicle().getId();
        }
        return appointment;
    }

    @Transactional
    public Appointment updateAppointment(Long id, AppointmentUpdateRequest request) {
        Appointment appointment = getAppointmentById(id);

        if (request.getStatus() != null) {
            appointment.setStatus(request.getStatus());
        }
        if (request.getNotes() != null) {
            appointment.setNotes(request.getNotes());
        }
        if (request.getActualCost() != null) {
            appointment.setActualCost(request.getActualCost());
        }

        return appointmentRepository.save(appointment);
    }
}
