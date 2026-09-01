package com.servio.admin.service;


import com.servio.admin.dto.JobCardPhotoDto;
import com.servio.admin.entity.JobCardPhoto;
import com.servio.admin.entity.PhotoType;
import com.servio.admin.entity.JobCard;
import com.servio.auth.entity.User;
import com.servio.admin.repository.JobCardPhotoRepository;
import com.servio.admin.repository.JobCardRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.admin.dto.ServicePhotoUploadResponse;
import com.servio.catalog.service.CloudinaryService;
import com.servio.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JobCardPhotoService {
    private final JobCardPhotoRepository photoRepository;
    private final JobCardRepository jobCardRepository;
    private final UserRepository userRepository;
    private final CloudinaryService cloudinaryService;

    public JobCardPhotoDto uploadPhoto(Long jobCardId, MultipartFile file, PhotoType photoType, String description, UUID uploadedById) {
        JobCard jobCard = jobCardRepository.findById(jobCardId)
                .orElseThrow(() -> new ResourceNotFoundException("Job card not found with id: " + jobCardId));

        ServicePhotoUploadResponse uploadResponse = cloudinaryService.uploadInspectionPhoto(file, jobCardId);

        User uploadedBy = null;
        if (uploadedById != null) {
            uploadedBy = userRepository.findById(uploadedById).orElse(null);
        }

        JobCardPhoto photo = JobCardPhoto.builder()
                .jobCard(jobCard)
                .photoUrl(uploadResponse.getUrl())
                .description(description)
                .photoType(photoType != null ? photoType : PhotoType.WORK_IN_PROGRESS)
                .uploadedBy(uploadedBy)
                .build();

        JobCardPhoto saved = photoRepository.save(photo);
        return convertToDto(saved);
    }

    public JobCardPhotoDto addPhoto(JobCardPhotoDto dto) {
        JobCard jobCard = jobCardRepository.findById(dto.getJobCardId())
                .orElseThrow(() -> new ResourceNotFoundException("Job card not found with id: " + dto.getJobCardId()));

        User uploadedBy = null;
        if (dto.getUploadedById() != null) {
            uploadedBy = userRepository.findById(dto.getUploadedById())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + dto.getUploadedById()));
        }

        JobCardPhoto photo = JobCardPhoto.builder()
                .jobCard(jobCard)
                .photoUrl(dto.getPhotoUrl())
                .description(dto.getDescription())
                .photoType(PhotoType.valueOf(dto.getPhotoType() != null ? dto.getPhotoType() : "WORK_IN_PROGRESS"))
                .uploadedBy(uploadedBy)
                .build();

        JobCardPhoto saved = photoRepository.save(photo);
        return convertToDto(saved);
    }

    public JobCardPhotoDto getPhotoById(Long id) {
        JobCard photo = null;
        JobCardPhoto photoEntity = photoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Photo not found with id: " + id));
        return convertToDto(photoEntity);
    }

    public List<JobCardPhotoDto> getPhotosByJobCard(Long jobCardId) {
        return photoRepository.findByJobCardId(jobCardId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public void deletePhoto(Long id) {
        photoRepository.deleteById(id);
    }

    private JobCardPhotoDto convertToDto(JobCardPhoto photo) {
        return JobCardPhotoDto.builder()
                .id(photo.getId())
                .jobCardId(photo.getJobCard().getId())
                .photoUrl(photo.getPhotoUrl())
                .description(photo.getDescription())
                .photoType(photo.getPhotoType().toString())
                .uploadedById(photo.getUploadedBy() != null ? photo.getUploadedBy().getId() : null)
                .uploadedByName(photo.getUploadedBy() != null ? photo.getUploadedBy().getFullName() : "System")
                .createdAt(photo.getCreatedAt())
                .build();
    }
}
