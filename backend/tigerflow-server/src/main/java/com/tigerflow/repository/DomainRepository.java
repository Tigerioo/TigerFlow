package com.tigerflow.repository;

import com.tigerflow.entity.Domain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DomainRepository extends JpaRepository<Domain, Long> {

    List<Domain> findByUserIdAndDeletedAtIsNull(Long userId);
}
