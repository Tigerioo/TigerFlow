package com.tigerflow.controller;

import com.tigerflow.dto.request.DomainRequest;
import com.tigerflow.dto.response.ApiResponse;
import com.tigerflow.dto.response.DomainResponse;
import com.tigerflow.entity.Domain;
import com.tigerflow.entity.User;
import com.tigerflow.repository.DomainRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Domain 领域控制器
 */
@RestController
@RequestMapping("/api/v1/domains")
@RequiredArgsConstructor
@Tag(name = "领域管理", description = "Domain 领域的 CRUD 接口")
public class DomainController {

    private final DomainRepository domainRepository;

    @Operation(summary = "获取当前用户的所有 Domain")
    @GetMapping
    public ApiResponse<List<DomainResponse>> getDomains(Authentication authentication) {
        Long userId = getUserId(authentication);
        List<Domain> domains = domainRepository.findByUserIdOrderBySortOrderAsc(userId);
        List<DomainResponse> responses = domains.stream()
                .map(DomainResponse::fromEntity)
                .collect(Collectors.toList());
        return ApiResponse.success(responses);
    }

    @Operation(summary = "获取单个 Domain")
    @GetMapping("/{id}")
    public ApiResponse<DomainResponse> getDomain(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);
        Domain domain = domainRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (domain == null) {
            return ApiResponse.error(404, "Domain 不存在");
        }
        return ApiResponse.success(DomainResponse.fromEntity(domain));
    }

    @Operation(summary = "创建 Domain")
    @PostMapping
    public ApiResponse<DomainResponse> createDomain(
            @RequestBody DomainRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        Domain domain = new Domain();
        domain.setUserId(userId);
        domain.setName(request.getName());
        domain.setIcon(request.getIcon());
        domain.setColor(request.getColor());
        domain.setSortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0);

        domain = domainRepository.save(domain);
        return ApiResponse.success(DomainResponse.fromEntity(domain));
    }

    @Operation(summary = "更新 Domain")
    @PutMapping("/{id}")
    public ApiResponse<DomainResponse> updateDomain(
            @PathVariable Long id,
            @RequestBody DomainRequest request,
            Authentication authentication) {
        Long userId = getUserId(authentication);

        Domain domain = domainRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (domain == null) {
            return ApiResponse.error(404, "Domain 不存在");
        }

        if (request.getName() != null) domain.setName(request.getName());
        if (request.getIcon() != null) domain.setIcon(request.getIcon());
        if (request.getColor() != null) domain.setColor(request.getColor());
        if (request.getSortOrder() != null) domain.setSortOrder(request.getSortOrder());

        domain = domainRepository.save(domain);
        return ApiResponse.success(DomainResponse.fromEntity(domain));
    }

    @Operation(summary = "删除 Domain")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteDomain(@PathVariable Long id, Authentication authentication) {
        Long userId = getUserId(authentication);

        Domain domain = domainRepository.findByIdAndUserId(id, userId)
                .orElse(null);
        if (domain == null) {
            return ApiResponse.error(404, "Domain 不存在");
        }

        domainRepository.delete(domain);
        return ApiResponse.success(null);
    }

    private Long getUserId(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return user.getId();
    }
}
