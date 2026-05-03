package com.servio.backend.service;

import com.servio.dto.admin.ServicePhotoUploadResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.TreeMap;

@Service
@RequiredArgsConstructor
public class CloudinaryService {
    private final RestTemplate restTemplate;

    @Value("${cloudinary.cloud-name:}")
    private String cloudName;

    @Value("${cloudinary.api-key:}")
    private String apiKey;

    @Value("${cloudinary.api-secret:}")
    private String apiSecret;

    public ServicePhotoUploadResponse uploadServicePhoto(MultipartFile file) {
        return uploadImage(file, "servio/services/photos", "service-photo");
    }

    public ServicePhotoUploadResponse uploadServiceIcon(MultipartFile file) {
        return uploadImage(file, "servio/services/icons", "service-icon");
    }

    private ServicePhotoUploadResponse uploadImage(MultipartFile file, String folder, String fallbackName) {
        if (cloudName == null || cloudName.isBlank() || apiKey == null || apiKey.isBlank() || apiSecret == null || apiSecret.isBlank()) {
            throw new RuntimeException("Cloudinary configuration is missing");
        }

        try {
            long timestamp = System.currentTimeMillis() / 1000L;

            Map<String, String> signatureParams = new TreeMap<>();
            signatureParams.put("folder", folder);
            signatureParams.put("timestamp", String.valueOf(timestamp));
            String signature = sign(signatureParams);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("api_key", apiKey);
            body.add("timestamp", String.valueOf(timestamp));
            body.add("folder", folder);
            body.add("signature", signature);
            body.add("file", new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename() != null ? file.getOriginalFilename() : fallbackName;
                }
            });

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            String url = "https://api.cloudinary.com/v1_1/" + cloudName + "/image/upload";
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(url, new HttpEntity<>(body, headers), Map.class);

            if (response == null || response.get("secure_url") == null || response.get("public_id") == null) {
                throw new RuntimeException("Cloudinary upload did not return an image URL");
            }

            return ServicePhotoUploadResponse.builder()
                    .url(response.get("secure_url").toString())
                    .publicId(response.get("public_id").toString())
                    .build();
        } catch (Exception e) {
            throw new RuntimeException("Failed to upload image to Cloudinary: " + e.getMessage(), e);
        }
    }

    private String sign(Map<String, String> params) throws Exception {
        StringBuilder payload = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (payload.length() > 0) {
                payload.append("&");
            }
            payload.append(entry.getKey()).append("=").append(entry.getValue());
        }
        payload.append(apiSecret);

        MessageDigest digest = MessageDigest.getInstance("SHA-1");
        byte[] hash = digest.digest(payload.toString().getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) {
            hex.append(String.format("%02x", b));
        }
        return hex.toString();
    }
}
