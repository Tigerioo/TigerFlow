package com.tigerflow.repository;

import com.tigerflow.entity.Domain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface DomainRepository extends JpaRepository<Domain, Long> {

    List<Domain> findByUserIdAndDeletedAtIsNull(Long userId);

    List<Domain> findByUserIdOrderBySortOrderAsc(Long userId);

    Optional<Domain> findByIdAndUserId(Long id, Long userId);

    @Query("SELECT d FROM Domain d WHERE d.userId = :userId AND d.updatedAt > :since AND d.deletedAt IS NULL")
    List<Domain> findByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);

    @Query("SELECT d FROM Domain d WHERE d.userId = :userId AND d.updatedAt > :since AND d.deletedAt IS NOT NULL")
    List<Domain> findDeletedByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);
}
