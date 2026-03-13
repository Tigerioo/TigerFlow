package com.tigerflow.repository;

import com.tigerflow.entity.FlowEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FlowEntityRepository extends JpaRepository<FlowEntity, Long> {

    List<FlowEntity> findByUserIdAndDeletedAtIsNull(Long userId);

    List<FlowEntity> findByUserIdAndTypeAndDeletedAtIsNull(Long userId, String type);
}
