package com.tigerflow.repository;

import com.tigerflow.entity.FlowEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FlowEntityRepository extends JpaRepository<FlowEntity, Long> {

    List<FlowEntity> findByUserIdAndDeletedAtIsNull(Long userId);

    List<FlowEntity> findByUserIdAndTypeAndDeletedAtIsNull(Long userId, String type);

    @Query("SELECT e FROM FlowEntity e WHERE e.userId = :userId AND e.updatedAt > :since AND e.deletedAt IS NULL")
    List<FlowEntity> findByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);

    @Query("SELECT e FROM FlowEntity e WHERE e.userId = :userId AND e.updatedAt > :since AND e.deletedAt IS NOT NULL")
    List<FlowEntity> findDeletedByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);
}
