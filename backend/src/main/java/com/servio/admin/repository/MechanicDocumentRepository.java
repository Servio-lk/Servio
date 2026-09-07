package com.servio.admin.repository;

import com.servio.admin.entity.MechanicDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MechanicDocumentRepository extends JpaRepository<MechanicDocument, Long> {
    List<MechanicDocument> findByMechanicIdOrderByUploadedAtDesc(Long mechanicId);

    void deleteByMechanicId(Long mechanicId);
}
