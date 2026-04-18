package com.servio.repository;

import com.servio.entity.StockTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StockTransactionRepository extends JpaRepository<StockTransaction, Long> {
    List<StockTransaction> findByInventoryItemIdOrderByCreatedAtDesc(Long inventoryItemId);
}
