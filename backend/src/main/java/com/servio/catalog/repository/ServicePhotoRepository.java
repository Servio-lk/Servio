package com.servio.catalog.repository;

import com.servio.catalog.entity.ServicePhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServicePhotoRepository extends JpaRepository<ServicePhoto, Long> {
    List<ServicePhoto> findByServiceIdOrderByDisplayOrderAsc(Long serviceId);
}
