package com.servio.admin.service;

import com.servio.admin.dto.JobCardPhotoDto;
import com.servio.admin.dto.ServicePhotoUploadResponse;
import com.servio.admin.entity.JobCard;
import com.servio.admin.entity.JobCardPhoto;
import com.servio.admin.entity.PhotoType;
import com.servio.admin.repository.JobCardPhotoRepository;
import com.servio.admin.repository.JobCardRepository;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.catalog.service.CloudinaryService;
import com.servio.common.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JobCardPhotoServiceAdversarialTest {

    @Mock
    private JobCardPhotoRepository photoRepository;
    @Mock
    private JobCardRepository jobCardRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private CloudinaryService cloudinaryService;

    @InjectMocks
    private JobCardPhotoService jobCardPhotoService;

    private Long jobCardId;
    private JobCard jobCard;
    private UUID uploaderId;
    private User uploader;

    @BeforeEach
    void setUp() {
        jobCardId = 123L;
        jobCard = JobCard.builder().id(jobCardId).jobNumber("JC-123").build();
        uploaderId = UUID.randomUUID();
        uploader = User.builder().id(uploaderId).fullName("Technician Mike").build();
    }

    @Test
    @DisplayName("uploadPhoto successfully uploads to Cloudinary and persists JobCardPhoto with uploader UUID")
    void testUploadPhoto_success() {
        MockMultipartFile file = new MockMultipartFile("file", "tire.jpg", "image/jpeg", "image-bytes".getBytes());
        ServicePhotoUploadResponse uploadResponse = ServicePhotoUploadResponse.builder()
                .url("https://res.cloudinary.com/servio/image/upload/v123/tire.jpg")
                .publicId("servio/inspections/job-card-123/tire")
                .build();

        when(jobCardRepository.findById(jobCardId)).thenReturn(Optional.of(jobCard));
        when(cloudinaryService.uploadInspectionPhoto(file, jobCardId)).thenReturn(uploadResponse);
        when(userRepository.findById(uploaderId)).thenReturn(Optional.of(uploader));

        JobCardPhoto savedPhoto = JobCardPhoto.builder()
                .id(1L)
                .jobCard(jobCard)
                .photoUrl(uploadResponse.getUrl())
                .description("Tire tread inspection")
                .photoType(PhotoType.BEFORE)
                .uploadedBy(uploader)
                .build();
        when(photoRepository.save(any(JobCardPhoto.class))).thenReturn(savedPhoto);

        JobCardPhotoDto result = jobCardPhotoService.uploadPhoto(jobCardId, file, PhotoType.BEFORE, "Tire tread inspection", uploaderId);

        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals(jobCardId, result.getJobCardId());
        assertEquals("https://res.cloudinary.com/servio/image/upload/v123/tire.jpg", result.getPhotoUrl());
        assertEquals(uploaderId, result.getUploadedById());
        assertEquals("Technician Mike", result.getUploadedByName());

        ArgumentCaptor<JobCardPhoto> captor = ArgumentCaptor.forClass(JobCardPhoto.class);
        verify(photoRepository).save(captor.capture());
        assertEquals(uploader, captor.getValue().getUploadedBy());
        assertEquals(PhotoType.BEFORE, captor.getValue().getPhotoType());
    }

    @Test
    @DisplayName("uploadPhoto throws ResourceNotFoundException when JobCard does not exist")
    void testUploadPhoto_jobCardNotFound_throwsResourceNotFound() {
        MockMultipartFile file = new MockMultipartFile("file", "tire.jpg", "image/jpeg", "image-bytes".getBytes());
        when(jobCardRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class,
                () -> jobCardPhotoService.uploadPhoto(999L, file, PhotoType.BEFORE, "desc", uploaderId));

        verify(cloudinaryService, never()).uploadInspectionPhoto(any(), any());
        verify(photoRepository, never()).save(any());
    }
}
