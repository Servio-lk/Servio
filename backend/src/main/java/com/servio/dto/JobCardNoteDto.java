package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobCardNoteDto {
    private Long id;
    private Long jobCardId;
    private Long createdById;
    private String createdByName;
    private String noteText;
    private String noteType;
    private LocalDateTime createdAt;
}
