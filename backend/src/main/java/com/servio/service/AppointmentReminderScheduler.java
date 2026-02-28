package com.servio.service;

import com.servio.entity.Appointment;
import com.servio.repository.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Runs two scheduled jobs:
 *
 *  1. 24-hour reminder  — fires every hour, checks for appointments
 *     that are between 23h and 25h away and sends a reminder.
 *
 *  2. 1-hour reminder   — fires every 15 minutes, checks for appointments
 *     that are between 55 min and 65 min away and sends a reminder.
 *
 * Both jobs only notify users who are stored in the local `users` table
 * (i.e. appointments with a non-null user_id).  Supabase-profile-only
 * bookings are excluded until a profile-based notification pathway is added.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AppointmentReminderScheduler {

    private final AppointmentRepository appointmentRepository;
    private final NotificationService notificationService;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MMM d, yyyy 'at' h:mm a");

    /** Send 24-hour reminders — runs every hour on the hour. */
    @Scheduled(cron = "0 0 * * * *")
    public void send24HourReminders() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime windowStart = now.plusHours(23);
        LocalDateTime windowEnd   = now.plusHours(25);

        List<Appointment> upcoming = appointmentRepository
                .findUpcomingAppointmentsInWindow(windowStart, windowEnd);

        for (Appointment appt : upcoming) {
            if (appt.getUser() == null) continue;   // skip Supabase-only profiles
            try {
                String dateStr = appt.getAppointmentDate().format(FMT);
                notificationService.createReminderNotification(
                    appt.getUser().getId(),
                    "Reminder: Your " + appt.getServiceType() +
                    " appointment is tomorrow at " + dateStr + ". We'll see you soon!"
                );
                log.info("[Scheduler] 24h reminder sent → user={}, service={}, date={}",
                        appt.getUser().getId(), appt.getServiceType(), dateStr);
            } catch (Exception e) {
                log.warn("[Scheduler] Failed to send 24h reminder for appointment {}: {}",
                        appt.getId(), e.getMessage());
            }
        }
    }

    /** Send 1-hour reminders — runs every 15 minutes. */
    @Scheduled(cron = "0 0/15 * * * *")
    public void send1HourReminders() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime windowStart = now.plusMinutes(55);
        LocalDateTime windowEnd   = now.plusMinutes(65);

        List<Appointment> upcoming = appointmentRepository
                .findUpcomingAppointmentsInWindow(windowStart, windowEnd);

        for (Appointment appt : upcoming) {
            if (appt.getUser() == null) continue;
            try {
                String dateStr = appt.getAppointmentDate().format(FMT);
                notificationService.createReminderNotification(
                    appt.getUser().getId(),
                    "Your " + appt.getServiceType() +
                    " appointment is in about 1 hour (" + dateStr + "). Please be ready!"
                );
                log.info("[Scheduler] 1h reminder sent → user={}, service={}, date={}",
                        appt.getUser().getId(), appt.getServiceType(), dateStr);
            } catch (Exception e) {
                log.warn("[Scheduler] Failed to send 1h reminder for appointment {}: {}",
                        appt.getId(), e.getMessage());
            }
        }
    }
}

