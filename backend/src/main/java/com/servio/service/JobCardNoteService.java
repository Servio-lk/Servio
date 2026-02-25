package com.servio.service;

import com.servio.dto.JobCardNoteDto;
import com.servio.entity.JobCardNote;
import com.servio.entity.NoteType;
import com.servio.entity.JobCard;
import com.servio.entity.User;
import com.servio.repository.JobCardNoteRepository;
import com.servio.repository.JobCardRepository;
import com.servio.repository.UserRepository;
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
                .orElseThrow(() -> new RuntimeException("Job card not found"));

        User createdBy = null;
        if (dto.getCreatedById() != null) {
            createdBy = userRepository.findById(dto.getCreatedById())
                    .orElseThrow(() -> new RuntimeException("User not found"));
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
                .orElseThrow(() -> new RuntimeException("Note not found"));
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
