package com.servio.service;

import com.servio.dto.JobCardPhotoDto;
import com.servio.entity.JobCardPhoto;
import com.servio.entity.PhotoType;
import com.servio.entity.JobCard;
import com.servio.entity.User;
import com.servio.repository.JobCardPhotoRepository;
import com.servio.repository.JobCardRepository;
import com.servio.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JobCardPhotoService {
    private final JobCardPhotoRepository photoRepository;
    private final JobCardRepository jobCardRepository;
    private final UserRepository userRepository;

    public JobCardPhotoDto addPhoto(JobCardPhotoDto dto) {
        JobCard jobCard = jobCardRepository.findById(dto.getJobCardId())
                .orElseThrow(() -> new RuntimeException("Job card not found"));

        User uploadedBy = null;
        if (dto.getUploadedById() != null) {
            uploadedBy = userRepository.findById(dto.getUploadedById())
                    .orElseThrow(() -> new RuntimeException("User not found"));
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
        JobCardPhoto photo = photoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Photo not found"));
        return convertToDto(photo);
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
