package com.servio.admin.service;


import com.servio.admin.dto.JobCardNoteDto;
import com.servio.admin.entity.JobCardNote;
import com.servio.admin.entity.NoteType;
import com.servio.admin.entity.JobCard;
import com.servio.auth.entity.User;
import com.servio.admin.repository.JobCardNoteRepository;
import com.servio.admin.repository.JobCardRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JobCardNoteService {
    private final JobCardNoteRepository noteRepository;
    private final JobCardRepository jobCardRepository;
    private final UserRepository userRepository;

    public JobCardNoteDto addNote(JobCardNoteDto dto) {
        JobCard jobCard = jobCardRepository.findById(dto.getJobCardId())
                .orElseThrow(() -> new ResourceNotFoundException("Job card not found with id: " + dto.getJobCardId()));

        User createdBy = null;
        if (dto.getCreatedById() != null) {
            createdBy = userRepository.findById(dto.getCreatedById())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + dto.getCreatedById()));
        }

        JobCardNote note = JobCardNote.builder()
                .jobCard(jobCard)
                .createdBy(createdBy)
                .noteText(dto.getNoteText())
                .noteType(NoteType.valueOf(dto.getNoteType() != null ? dto.getNoteType() : "GENERAL"))
                .build();

        JobCardNote saved = noteRepository.save(note);
        return convertToDto(saved);
    }

    public JobCardNoteDto getNoteById(Long id) {
        JobCardNote note = noteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Note not found with id: " + id));
        return convertToDto(note);
    }

    public List<JobCardNoteDto> getNotesByJobCard(Long jobCardId) {
        return noteRepository.findByJobCardIdOrderByCreatedAtDesc(jobCardId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public void deleteNote(Long id) {
        noteRepository.deleteById(id);
    }

    private JobCardNoteDto convertToDto(JobCardNote note) {
        return JobCardNoteDto.builder()
                .id(note.getId())
                .jobCardId(note.getJobCard().getId())
                .createdById(note.getCreatedBy() != null ? note.getCreatedBy().getId() : null)
                .createdByName(note.getCreatedBy() != null ? note.getCreatedBy().getFullName() : "System")
                .noteText(note.getNoteText())
                .noteType(note.getNoteType().toString())
                .createdAt(note.getCreatedAt())
                .build();
    }
}
