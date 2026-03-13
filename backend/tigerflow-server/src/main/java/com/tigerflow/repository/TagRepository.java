package com.tigerflow.repository;

import com.tigerflow.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TagRepository extends JpaRepository<Tag, Long> {

    List<Tag> findByUserIdAndDeletedAtIsNull(Long userId);

    List<Tag> findByUserIdOrderByUsageCountDesc(Long userId);

    Optional<Tag> findByIdAndUserId(Long id, Long userId);

    List<Tag> findByUserIdAndNameAndDeletedAtIsNull(Long userId, String name);

    @Query("SELECT t FROM Tag t WHERE t.userId = :userId AND t.updatedAt > :since AND t.deletedAt IS NULL")
    List<Tag> findByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);

    @Query("SELECT t FROM Tag t WHERE t.userId = :userId AND t.updatedAt > :since AND t.deletedAt IS NOT NULL")
    List<Tag> findDeletedByUserIdAndUpdatedAtAfter(Long userId, LocalDateTime since);
}
