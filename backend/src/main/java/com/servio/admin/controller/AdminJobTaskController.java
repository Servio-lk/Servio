package com.servio.admin.controller;

import com.servio.admin.dto.JobTaskDto;
import com.servio.admin.service.JobTaskService;
import com.servio.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/job-tasks")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminJobTaskController {
    private final JobTaskService jobTaskService;

    @PostMapping
    public ResponseEntity<ApiResponse<JobTaskDto>> createJobTask(@RequestBody JobTaskDto dto) {
        JobTaskDto created = jobTaskService.createJobTask(dto);
        return ResponseEntity.ok(ApiResponse.success("Job task created successfully", created));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<JobTaskDto>> getJobTaskById(@PathVariable Long id) {
        JobTaskDto task = jobTaskService.getJobTaskById(id);
        return ResponseEntity.ok(ApiResponse.success("Job task retrieved successfully", task));
    }

    @GetMapping("/job-card/{jobCardId}")
    public ResponseEntity<ApiResponse<List<JobTaskDto>>> getTasksByJobCard(@PathVariable Long jobCardId) {
        List<JobTaskDto> tasks = jobTaskService.getTasksByJobCard(jobCardId);
        return ResponseEntity.ok(ApiResponse.success("Job tasks retrieved successfully", tasks));
    }

    @GetMapping("/mechanic/{mechanicId}")
    public ResponseEntity<ApiResponse<List<JobTaskDto>>> getTasksByMechanic(@PathVariable Long mechanicId) {
        List<JobTaskDto> tasks = jobTaskService.getTasksByMechanic(mechanicId);
        return ResponseEntity.ok(ApiResponse.success("Job tasks retrieved successfully", tasks));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<JobTaskDto>>> getTasksByStatus(@PathVariable String status) {
        List<JobTaskDto> tasks = jobTaskService.getTasksByStatus(status);
        return ResponseEntity.ok(ApiResponse.success("Job tasks retrieved successfully", tasks));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<JobTaskDto>> updateJobTask(@PathVariable Long id, @RequestBody JobTaskDto dto) {
        JobTaskDto updated = jobTaskService.updateJobTask(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Job task updated successfully", updated));
    }

    @PatchMapping("/{id}/status/{status}")
    public ResponseEntity<ApiResponse<JobTaskDto>> updateTaskStatus(@PathVariable Long id, @PathVariable String status) {
        JobTaskDto updated = jobTaskService.updateTaskStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Job task status updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteJobTask(@PathVariable Long id) {
        jobTaskService.deleteJobTask(id);
        return ResponseEntity.ok(ApiResponse.success("Job task deleted successfully", null));
    }
}
