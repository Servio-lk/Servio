package com.servio.service;

import com.servio.dto.PayHereInitiateRequest;
import com.servio.dto.PayHereInitiateResponse;
import com.servio.entity.Appointment;
import com.servio.entity.Payment;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Handles PayHere Checkout API integration.
 *
 * SECURITY NOTE: All hash generation and signature verification happen here on
 * the server. The merchant_secret is never sent to the frontend.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PayHereService {

    private final AppointmentRepository appointmentRepository;
    private final PaymentRepository paymentRepository;

    @Value("${payhere.merchant.id}")
    private String merchantId;

    @Value("${payhere.merchant.secret}")
    private String merchantSecret;

    @Value("${payhere.sandbox:true}")
    private boolean sandbox;

    @Value("${payhere.notify.url:http://localhost:3001/api/payments/payhere/notify}")
    private String notifyUrl;

    @Value("${app.frontend.url:http://localhost:5173}")
    private String frontendUrl;

    /**
     * Builds the PayHere checkout form data (including the secure hash) for a
     * given appointment.  Called by the authenticated user who owns the appointment.
     * Also marks the appointment as PENDING_PAYMENT so the slot is reserved for
     * up to 10 minutes while the user completes the payment flow.
     */
    @Transactional
    public PayHereInitiateResponse initiatePayment(PayHereInitiateRequest request,
                                                   Authentication authentication) {
        Appointment appointment = appointmentRepository.findById(request.getAppointmentId())
                .orElseThrow(() -> new RuntimeException(
                        "Appointment not found: " + request.getAppointmentId()));

        verifyOwnership(appointment, authentication);

        // Reserve the time slot for the payment window — auto-expires after 10 minutes
        // if the user doesn't complete payment (see PaymentExpiryScheduler).
        appointment.setStatus("PENDING_PAYMENT");
        appointmentRepository.save(appointment);

        // Resolve customer details from whichever auth path was used
        String fullName  = resolveFullName(appointment);
        String email     = resolveEmail(appointment);
        String phone     = resolvePhone(appointment);

        String firstName = fullName.contains(" ")
                ? fullName.substring(0, fullName.indexOf(' '))
                : fullName;
        String lastName  = fullName.contains(" ")
                ? fullName.substring(fullName.indexOf(' ') + 1)
                : ".";

        BigDecimal amount         = appointment.getEstimatedCost() != null
                ? appointment.getEstimatedCost() : BigDecimal.ZERO;
        String currency           = request.getCurrency() != null ? request.getCurrency() : "LKR";
        String orderId            = "ORD-" + appointment.getId();
        String formattedAmount    = String.format("%.2f", amount.doubleValue());
        String hash               = generateHash(merchantId, orderId, formattedAmount, currency);

        String returnUrl  = frontendUrl + "/confirmed/" + appointment.getId();
        String cancelUrl  = (request.getServiceId() != null && !request.getServiceId().isBlank())
                ? frontendUrl + "/book/" + request.getServiceId()
                : frontendUrl + "/services";
        String checkoutUrl = sandbox
                ? "https://sandbox.payhere.lk/pay/checkout"
                : "https://www.payhere.lk/pay/checkout";

        return PayHereInitiateResponse.builder()
                .merchantId(merchantId)
                .orderId(orderId)
                .amount(formattedAmount)
                .currency(currency)
                .hash(hash)
                .returnUrl(returnUrl)
                .cancelUrl(cancelUrl)
                .notifyUrl(notifyUrl)
                .firstName(firstName)
                .lastName(lastName)
                .email(email)
                .phone(phone)
                .address("Sri Lanka")
                .city("Colombo")
                .country("Sri Lanka")
                .items(appointment.getServiceType())
                .checkoutUrl(checkoutUrl)
                .sandboxMode(sandbox)
                .build();
    }

    /**
     * Processes the server-to-server payment notification from PayHere.
     * Verifies the md5sig checksum before taking any action to ensure the
     * notification genuinely originated from PayHere.
     *
     * @throws SecurityException if the md5sig verification fails
     */
    @Transactional
    public void handleNotification(String merchantIdParam,
                                   String orderId,
                                   String payhereAmount,
                                   String payhereCurrency,
                                   String statusCode,
                                   String md5sig,
                                   String paymentId,
                                   String method) {
        // 1. Verify signature BEFORE touching the database
        if (!verifyNotification(merchantIdParam, orderId, payhereAmount,
                payhereCurrency, statusCode, md5sig)) {
            log.warn("PayHere md5sig verification FAILED — orderId={} statusCode={}", orderId, statusCode);
            throw new SecurityException("PayHere notification md5sig verification failed");
        }

        // 2. Parse appointmentId from orderId (format: "ORD-{id}")
        Long appointmentId;
        try {
            appointmentId = Long.parseLong(orderId.replace("ORD-", ""));
        } catch (NumberFormatException e) {
            log.error("Unrecognised orderId from PayHere: {}", orderId);
            throw new RuntimeException("Invalid order_id format: " + orderId);
        }

        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new RuntimeException("Appointment not found: " + appointmentId));

        // 3. Act on payment status
        if ("2".equals(statusCode)) {
            // Successful payment — confirm the appointment and record payment
            appointment.setStatus("CONFIRMED");
            appointmentRepository.save(appointment);

            Payment payment = Payment.builder()
                    .appointment(appointment)
                    .user(appointment.getUser())       // null for Supabase profile users
                    .profile(appointment.getProfile()) // null for local users
                    .amount(new BigDecimal(payhereAmount))
                    .paymentMethod("PAYHERE")
                    .paymentStatus("COMPLETED")
                    .transactionId(paymentId)
                    .paymentDate(LocalDateTime.now())
                    .build();
            paymentRepository.save(payment);
            log.info("PayHere payment CONFIRMED — appointmentId={} paymentId={} method={}",
                    appointmentId, paymentId, method);
        } else {
            log.info("PayHere notification received — orderId={} statusCode={}", orderId, statusCode);
        }
    }

    /**
     * Verifies the md5sig received in a PayHere notification.
     * Logic: UPPER(MD5(merchant_id + order_id + payhere_amount + payhere_currency
     *                   + status_code + UPPER(MD5(merchant_secret))))
     */
    public boolean verifyNotification(String merchantIdParam, String orderId,
                                      String payhereAmount, String payhereCurrency,
                                      String statusCode, String md5sig) {
        String hashedSecret = md5(merchantSecret).toUpperCase();
        String localSig = md5(merchantIdParam + orderId + payhereAmount
                + payhereCurrency + statusCode + hashedSecret).toUpperCase();
        return localSig.equals(md5sig);
    }

    /**
     * Generates the PayHere checkout hash.
     * Logic: UPPER(MD5(merchant_id + order_id + amount + currency + UPPER(MD5(merchant_secret))))
     */
    public String generateHash(String merchantIdParam, String orderId,
                               String formattedAmount, String currency) {
        String hashedSecret = md5(merchantSecret).toUpperCase();
        return md5(merchantIdParam + orderId + formattedAmount + currency + hashedSecret).toUpperCase();
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private void verifyOwnership(Appointment appointment, Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new SecurityException("Authentication required");
        }
        String principal = authentication.getPrincipal().toString();
        try {
            UUID profileId = UUID.fromString(principal);
            if (appointment.getProfile() == null
                    || !appointment.getProfile().getId().equals(profileId)) {
                throw new SecurityException(
                        "Access denied: appointment does not belong to this user");
            }
        } catch (IllegalArgumentException e) {
            try {
                Long userId = Long.parseLong(principal);
                if (appointment.getUser() == null
                        || !appointment.getUser().getId().equals(userId)) {
                    throw new SecurityException(
                            "Access denied: appointment does not belong to this user");
                }
            } catch (NumberFormatException nfe) {
                throw new SecurityException("Invalid principal format: " + principal);
            }
        }
    }

    private String resolveFullName(Appointment appointment) {
        if (appointment.getUser() != null
                && appointment.getUser().getFullName() != null) {
            return appointment.getUser().getFullName();
        }
        if (appointment.getProfile() != null
                && appointment.getProfile().getFullName() != null) {
            return appointment.getProfile().getFullName();
        }
        return "Customer";
    }

    private String resolveEmail(Appointment appointment) {
        if (appointment.getUser() != null) return appointment.getUser().getEmail();
        if (appointment.getProfile() != null) return appointment.getProfile().getEmail();
        return "";
    }

    private String resolvePhone(Appointment appointment) {
        String phone = null;
        if (appointment.getUser() != null) phone = appointment.getUser().getPhone();
        if (phone == null && appointment.getProfile() != null) {
            phone = appointment.getProfile().getPhone();
        }
        return (phone != null && !phone.isBlank()) ? phone : "0000000000";
    }

    private String md5(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] hashBytes = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(32);
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("MD5 algorithm not available", e);
        }
    }
}
