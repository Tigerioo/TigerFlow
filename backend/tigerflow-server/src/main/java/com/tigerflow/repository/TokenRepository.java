package com.tigerflow.repository;

import com.tigerflow.entity.Token;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TokenRepository extends JpaRepository<Token, Long> {

    Optional<Token> findByToken(String token);

    Optional<Token> findByRefreshToken(String refreshToken);

    Optional<Token> findByUserIdAndDeviceId(Long userId, String deviceId);

    void deleteByUserId(Long userId);
}
