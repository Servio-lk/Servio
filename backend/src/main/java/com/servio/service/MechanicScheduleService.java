package com.servio.service;

import com.servio.dto.*;
import com.servio.entity.*;
import com.servio.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class MechanicScheduleService {
    private final MechanicRepository mechanicRepository;
    private final MechanicScheduleRepository scheduleRepository;
    private final MechanicUnavailableBlockRepository unavailableBlockRepository;

    public MechanicScheduleResponse getSchedule(Long mechanicId) {
        mechanicRepository.findById(mechanicId)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));

        return MechanicScheduleResponse.builder()
                .mechanicId(mechanicId)
                .workingHours(scheduleRepository.findByMechanicIdOrderByDayOfWeekAscShiftStartAsc(mechanicId)
                        .stream().map(this::toScheduleDto).toList())
                .unavailableBlocks(unavailableBlockRepository.findByMechanicIdOrderByStartsAtAsc(mechanicId)
                        .stream().map(this::toUnavailableDto).toList())
                .build();
    }

    public MechanicScheduleResponse updateSchedule(Long mechanicId, MechanicScheduleRequest request) {
        Mechanic mechanic = mechanicRepository.findById(mechanicId)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));
        validate(request);

        scheduleRepository.deleteByMechanicId(mechanicId);
        unavailableBlockRepository.deleteByMechanicId(mechanicId);

        if (request.getWorkingHours() != null) {
            for (MechanicScheduleDto dto : request.getWorkingHours()) {
                scheduleRepository.save(MechanicSchedule.builder()
                        .mechanic(mechanic)
                        .dayOfWeek(DayOfWeek.valueOf(dto.getDayOfWeek()))
                        .shiftStart(dto.getShiftStart())
                        .shiftEnd(dto.getShiftEnd())
                        .build());
            }
        }

        if (request.getUnavailableBlocks() != null) {
            for (MechanicUnavailableBlockDto dto : request.getUnavailableBlocks()) {
                unavailableBlockRepository.save(MechanicUnavailableBlock.builder()
                        .mechanic(mechanic)
                        .startsAt(dto.getStartsAt())
                        .endsAt(dto.getEndsAt())
                        .reason(dto.getReason())
                        .build());
            }
        }

        return getSchedule(mechanicId);
    }

    private void validate(MechanicScheduleRequest request) {
        if (request.getWorkingHours() != null) {
            for (MechanicScheduleDto dto : request.getWorkingHours()) {
                if (dto.getDayOfWeek() == null || dto.getShiftStart() == null || dto.getShiftEnd() == null) {
                    throw new RuntimeException("Working days require dayOfWeek, shiftStart, and shiftEnd");
                }
                DayOfWeek.valueOf(dto.getDayOfWeek());
                if (!dto.getShiftStart().isBefore(dto.getShiftEnd())) {
                    throw new RuntimeException("Shift start must be before shift end");
                }
            }
        }

        List<MechanicUnavailableBlockDto> blocks = request.getUnavailableBlocks() == null
                ? List.of()
                : request.getUnavailableBlocks().stream()
                .sorted(Comparator.comparing(MechanicUnavailableBlockDto::getStartsAt))
                .toList();
        for (int i = 0; i < blocks.size(); i++) {
            MechanicUnavailableBlockDto current = blocks.get(i);
            if (current.getStartsAt() == null || current.getEndsAt() == null) {
                throw new RuntimeException("Unavailable blocks require startsAt and endsAt");
            }
            if (!current.getStartsAt().isBefore(current.getEndsAt())) {
                throw new RuntimeException("Unavailable block start must be before end");
            }
            if (i > 0 && current.getStartsAt().isBefore(blocks.get(i - 1).getEndsAt())) {
                throw new RuntimeException("Unavailable blocks cannot overlap");
            }
        }
    }

    private MechanicScheduleDto toScheduleDto(MechanicSchedule schedule) {
        return MechanicScheduleDto.builder()
                .id(schedule.getId())
                .dayOfWeek(schedule.getDayOfWeek().name())
                .shiftStart(schedule.getShiftStart())
                .shiftEnd(schedule.getShiftEnd())
                .build();
    }

    private MechanicUnavailableBlockDto toUnavailableDto(MechanicUnavailableBlock block) {
        return MechanicUnavailableBlockDto.builder()
                .id(block.getId())
                .startsAt(block.getStartsAt())
                .endsAt(block.getEndsAt())
                .reason(block.getReason())
                .build();
    }
}
