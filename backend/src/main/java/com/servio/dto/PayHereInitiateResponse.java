package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * All form fields the frontend needs to POST to PayHere's checkout endpoint.
 * Includes the backend-generated hash so the merchant secret is never exposed
 * to the client.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PayHereInitiateResponse {
    private String merchantId;
    private String orderId;
    private String amount;
    private String currency;
    private String hash;
    private String returnUrl;
    private String cancelUrl;
    private String notifyUrl;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private String address;
    private String city;
    private String country;
    private String items;
    /** Full checkout URL (sandbox or live) the frontend should POST to. */
    private String checkoutUrl;
    private boolean sandboxMode;
}
