package com.servio.repository;

import com.servio.entity.MechanicSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MechanicScheduleRepository extends JpaRepository<MechanicSchedule, Long> {
    List<MechanicSchedule> findByMechanicIdOrderByDayOfWeekAscShiftStartAsc(Long mechanicId);

    void deleteByMechanicId(Long mechanicId);
}
