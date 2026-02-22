package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.JobCardNoteDto;
import com.servio.service.JobCardNoteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/job-card-notes")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminJobCardNoteController {
    private final JobCardNoteService jobCardNoteService;

    @PostMapping
    public ResponseEntity<?> addNote(@RequestBody JobCardNoteDto dto) {
        try {
            JobCardNoteDto created = jobCardNoteService.addNote(dto);
            return ResponseEntity.ok(ApiResponse.success("Note added successfully", created));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to add note", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getNoteById(@PathVariable Long id) {
        try {
            JobCardNoteDto note = jobCardNoteService.getNoteById(id);
            return ResponseEntity.ok(ApiResponse.success("Note retrieved successfully", note));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve note", e.getMessage()));
        }
    }

    @GetMapping("/job-card/{jobCardId}")
    public ResponseEntity<?> getNotesByJobCard(@PathVariable Long jobCardId) {
        try {
            List<JobCardNoteDto> notes = jobCardNoteService.getNotesByJobCard(jobCardId);
            return ResponseEntity.ok(ApiResponse.success("Notes retrieved successfully", notes));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve notes", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNote(@PathVariable Long id) {
        try {
            jobCardNoteService.deleteNote(id);
            return ResponseEntity.ok(ApiResponse.success("Note deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to delete note", e.getMessage()));
        }
    }
}
