package com.servio.admin.controller;

import com.servio.admin.dto.JobCardNoteDto;
import com.servio.admin.service.JobCardNoteService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/job-card-notes")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminJobCardNoteController {
    private final JobCardNoteService jobCardNoteService;

    @PostMapping
    public ResponseEntity<ApiResponse<JobCardNoteDto>> addNote(@RequestBody JobCardNoteDto dto) {
        JobCardNoteDto created = jobCardNoteService.addNote(dto);
        return ResponseEntity.ok(ApiResponse.success("Note added successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<JobCardNoteDto>> getNoteById(@PathVariable Long id) {
        JobCardNoteDto note = jobCardNoteService.getNoteById(id);
        return ResponseEntity.ok(ApiResponse.success("Note retrieved successfully", note));
    }

    @GetMapping("/job-card/{jobCardId}")
    public ResponseEntity<ApiResponse<List<JobCardNoteDto>>> getNotesByJobCard(@PathVariable Long jobCardId) {
        List<JobCardNoteDto> notes = jobCardNoteService.getNotesByJobCard(jobCardId);
        return ResponseEntity.ok(ApiResponse.success("Notes retrieved successfully", notes));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteNote(@PathVariable Long id) {
        jobCardNoteService.deleteNote(id);
        return ResponseEntity.ok(ApiResponse.success("Note deleted successfully", null));
    }
}
