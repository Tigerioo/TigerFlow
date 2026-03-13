package com.tigerflow.repository;

import com.tigerflow.entity.FlowItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface FlowItemRepository extends JpaRepository<FlowItem, Long> {

    List<FlowItem> findByUserIdAndDeletedAtIsNull(Long userId);

    List<FlowItem> findByUserIdAndFlowTypeAndDeletedAtIsNull(Long userId, String flowType);

    List<FlowItem> findByUserIdAndFlowIdAndDeletedAtIsNull(Long userId, String flowId);

    Optional<FlowItem> findByIdAndUserId(Long id, Long userId);

    List<FlowItem> findByUserIdAndOccurredAtBetweenAndDeletedAtIsNull(Long userId, LocalDateTime startDate, LocalDateTime endDate);

    @Query("SELECT f FROM FlowItem f WHERE f.userId = :userId AND f.updatedAt > :since AND f.deletedAt IS NULL")
    List<FlowItem> findByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);

    @Query("SELECT f FROM FlowItem f WHERE f.userId = :userId AND f.updatedAt > :since AND f.deletedAt IS NOT NULL")
    List<FlowItem> findDeletedByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);
}
