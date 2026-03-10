package com.servio.dto;

import lombok.Data;

@Data
public class PayHereInitiateRequest {
    private Long appointmentId;
    private String currency = "LKR";
    /** The frontend service route id — used to build cancel_url back to the booking page. */
    private String serviceId;
}
