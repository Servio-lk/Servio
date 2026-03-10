package com.servio.service;

import com.servio.entity.Appointment;
import com.servio.repository.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Automatically cancels appointments that have been in PENDING_PAYMENT status
 * for more than 10 minutes.  This releases the reserved time slot back into
 * the pool so other customers (or the same customer) can book it.
 *
 * The happy path (payment completed) is handled by PayHereController's notify
 * endpoint, which marks the appointment CONFIRMED via PayHereService.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentExpiryScheduler {

    private static final int PAYMENT_TIMEOUT_MINUTES = 10;

    private final AppointmentRepository appointmentRepository;

    @Scheduled(fixedDelay = 60_000) // runs every 60 seconds
    @Transactional
    public void expireStalePayments() {
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(PAYMENT_TIMEOUT_MINUTES);
        List<Appointment> expired = appointmentRepository.findExpiredPendingPayments(cutoff);

        if (expired.isEmpty()) {
            return;
        }

        for (Appointment a : expired) {
            a.setStatus("CANCELLED");
            log.info("Auto-cancelled expired PENDING_PAYMENT appointment id={} createdAt={}",
                    a.getId(), a.getCreatedAt());
        }
        appointmentRepository.saveAll(expired);
        log.info("Expired {} stale PENDING_PAYMENT appointment(s)", expired.size());
    }
}
