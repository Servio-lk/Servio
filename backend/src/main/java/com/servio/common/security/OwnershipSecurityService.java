package com.servio.common.security;

import com.servio.booking.entity.Appointment;
import com.servio.booking.entity.Vehicle;
import com.servio.notification.entity.Notification;
import com.servio.repair.entity.RepairJob;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.notification.repository.NotificationRepository;
import com.servio.repair.repository.RepairJobRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component("ownershipSecurity")
@RequiredArgsConstructor
public class OwnershipSecurityService {

    private final VehicleRepository vehicleRepository;
    private final AppointmentRepository appointmentRepository;
    private final NotificationRepository notificationRepository;
    private final RepairJobRepository repairJobRepository;

    public boolean isVehicleOwner(Authentication authentication, Long vehicleId) {
        if (authentication == null || authentication.getName() == null) return false;
        Optional<Vehicle> opt = vehicleRepository.findById(vehicleId);
        return opt.isPresent() && opt.get().getUser() != null 
               && authentication.getName().equals(opt.get().getUser().getId().toString());
    }

    public boolean isAppointmentOwner(Authentication authentication, Long appointmentId) {
        if (authentication == null || authentication.getName() == null) return false;
        Optional<Appointment> opt = appointmentRepository.findById(appointmentId);
        return opt.isPresent() && opt.get().getUser() != null 
               && authentication.getName().equals(opt.get().getUser().getId().toString());
    }

    public boolean isNotificationOwner(Authentication authentication, Long notificationId) {
        if (authentication == null || authentication.getName() == null) return false;
        Optional<Notification> opt = notificationRepository.findById(notificationId);
        return opt.isPresent() && opt.get().getUser() != null 
               && authentication.getName().equals(opt.get().getUser().getId().toString());
    }

    public boolean isRepairJobOwner(Authentication authentication, Long repairJobId) {
        if (authentication == null || authentication.getName() == null) return false;
        Optional<RepairJob> opt = repairJobRepository.findById(repairJobId);
        return opt.isPresent() && opt.get().getUser() != null 
               && authentication.getName().equals(opt.get().getUser().getId().toString());
    }
}
