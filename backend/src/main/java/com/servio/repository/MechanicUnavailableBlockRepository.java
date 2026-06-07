package com.servio.repository;

import com.servio.entity.MechanicUnavailableBlock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MechanicUnavailableBlockRepository extends JpaRepository<MechanicUnavailableBlock, Long> {
    List<MechanicUnavailableBlock> findByMechanicIdOrderByStartsAtAsc(Long mechanicId);

    void deleteByMechanicId(Long mechanicId);
}
