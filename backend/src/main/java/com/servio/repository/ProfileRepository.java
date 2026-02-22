package com.servio.repository;

import com.servio.entity.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProfileRepository extends JpaRepository<Profile, UUID> {

    List<Profile> findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(
            String fullName, String email);
}
