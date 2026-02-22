package com.servio.repository;

import com.servio.entity.WalkInCustomer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface WalkInCustomerRepository extends JpaRepository<WalkInCustomer, Long> {
    List<WalkInCustomer> findByIsRegisteredFalse();

    List<WalkInCustomer> findByIsRegisteredTrue();

    List<WalkInCustomer> findByPhone(String phone);
}
