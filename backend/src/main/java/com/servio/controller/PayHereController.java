package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.PayHereInitiateRequest;
import com.servio.dto.PayHereInitiateResponse;
import com.servio.service.PayHereService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * PayHere Checkout API endpoints.
 *
 * POST /api/payments/payhere/initiate  — authenticated; generates checkout form data + hash
 * POST /api/payments/payhere/notify    — public; server-to-server callback from PayHere
 */
@RestController
@RequestMapping("/api/payments/payhere")
@RequiredArgsConstructor
@Slf4j
public class PayHereController {

    private final PayHereService payHereService;

    /**
     * Returns all PayHere form fields (including the server-generated hash) so
     * the frontend can submit them directly to PayHere's checkout page.
     *
     * The merchant_secret never leaves the server.
     */
    @PostMapping("/initiate")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PayHereInitiateResponse>> initiatePayment(
            @RequestBody PayHereInitiateRequest request,
            Authentication authentication) {
        PayHereInitiateResponse data = payHereService.initiatePayment(request, authentication);
        return ResponseEntity.ok(ApiResponse.<PayHereInitiateResponse>builder()
                .success(true)
                .message("PayHere payment initiated")
                .data(data)
                .build());
    }

    /**
     * Server-to-server payment notification callback from PayHere.
     *
     * IMPORTANT: This endpoint must remain publicly accessible (no JWT required)
     * because PayHere's servers POST here directly.  The md5sig parameter is
     * verified inside PayHereService before any database changes are made.
     *
     * Parameters are received as application/x-www-form-urlencoded (not JSON).
     */
    @PostMapping("/notify")
    public ResponseEntity<Void> handleNotification(
            @RequestParam("merchant_id")       String merchantId,
            @RequestParam("order_id")          String orderId,
            @RequestParam("payhere_amount")    String payhereAmount,
            @RequestParam("payhere_currency")  String payhereCurrency,
            @RequestParam("status_code")       String statusCode,
            @RequestParam("md5sig")            String md5sig,
            @RequestParam(value = "payment_id",     required = false) String paymentId,
            @RequestParam(value = "method",         required = false) String method) {
        try {
            payHereService.handleNotification(
                    merchantId, orderId, payhereAmount, payhereCurrency,
                    statusCode, md5sig, paymentId, method);
            return ResponseEntity.ok().build();
        } catch (SecurityException e) {
            // md5sig mismatch — reject silently with 400 (do not expose internals)
            log.warn("PayHere notify rejected: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            log.error("PayHere notify error: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
