package com.servio.inventory.repository;

import com.servio.inventory.entity.StockTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StockTransactionRepository extends JpaRepository<StockTransaction, Long> {
    List<StockTransaction> findByInventoryItemIdOrderByCreatedAtDesc(Long inventoryItemId);
}
