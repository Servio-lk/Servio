package com.servio.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceCategoryResponse {
    private Long id;
    private String name;
    private String description;
    private List<ServiceResponse> services;
}