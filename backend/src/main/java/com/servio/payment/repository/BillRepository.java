package com.servio.payment.repository;

import com.servio.payment.entity.Bill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BillRepository extends JpaRepository<Bill, Long> {
    Optional<Bill> findByInvoiceNo(String invoiceNo);
    
    @org.springframework.data.jpa.repository.Query("SELECT MAX(b.id) FROM Bill b")
    Long findMaxId();
}
