package com.tigerflow.repository;

import com.tigerflow.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TagRepository extends JpaRepository<Tag, Long> {

    List<Tag> findByUserIdAndDeletedAtIsNull(Long userId);
}
