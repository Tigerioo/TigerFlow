package com.tigerflow.repository;

import com.tigerflow.entity.Flow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface FlowRepository extends JpaRepository<Flow, Long> {

    List<Flow> findByUserIdAndDeletedAtIsNull(Long userId);

    List<Flow> findByUserIdAndTypeAndDeletedAtIsNull(Long userId, String type);

    List<Flow> findByUserIdOrderBySortOrderAsc(Long userId);

    Optional<Flow> findByIdAndUserId(Long id, Long userId);

    @Query("SELECT MAX(f.sortOrder) FROM Flow f WHERE f.userId = :userId")
    Integer findMaxSortOrderByUserId(Long userId);

    @Query("SELECT f FROM Flow f WHERE f.userId = :userId AND f.updatedAt > :since AND f.deletedAt IS NULL")
    List<Flow> findByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);

    @Query("SELECT f FROM Flow f WHERE f.userId = :userId AND f.updatedAt > :since AND f.deletedAt IS NOT NULL")
    List<Flow> findDeletedByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);
}
