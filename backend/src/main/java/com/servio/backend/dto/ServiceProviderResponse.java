package com.servio.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceProviderResponse {
    private Long id;
    private String name;
    private String address;
    private String city;
    private String phone;
    private BigDecimal rating;
}