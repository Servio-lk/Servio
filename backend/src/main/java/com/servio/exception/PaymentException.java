package com.servio.exception;

public class PaymentException extends RuntimeException {
    public PaymentException(String message) {
        super(message);
    }
}
