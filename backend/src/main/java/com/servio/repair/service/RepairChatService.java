package com.servio.repair.service;

import com.servio.repair.dto.RepairConversationDto;
import com.servio.repair.entity.RepairConversation;
import com.servio.repair.entity.RepairJob;
import com.servio.repair.entity.RepairMessage;
import com.servio.repair.repository.RepairConversationMemberRepository;
import com.servio.repair.repository.RepairMessageRepository;
import com.servio.repair.repository.RepairJobRepository;
import com.servio.repair.dto.RepairConversationMemberDto;
import com.servio.repair.entity.ConversationMemberRole;
import com.servio.admin.entity.Mechanic;
import com.servio.repair.repository.RepairConversationRepository;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.dto.RepairMessageDto;
import com.servio.admin.repository.MechanicRepository;
import com.servio.auth.repository.ProfileRepository;
import com.servio.repair.entity.RepairConversationMember;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class RepairChatService {
    private final RepairConversationRepository conversationRepository;
    private final RepairConversationMemberRepository memberRepository;
    private final RepairMessageRepository messageRepository;
    private final RepairJobRepository repairJobRepository;
    private final MechanicRepository mechanicRepository;
    private final ProfileRepository profileRepository;
    private final RepairJobService repairJobService;
    private final SimpMessagingTemplate messagingTemplate;

    public RepairConversation getOrCreateConversation(Long repairId) {
        return conversationRepository.findByRepairJobId(repairId)
                .orElseGet(() -> {
                    RepairJob repairJob = repairJobRepository.findById(repairId)
                            .orElseThrow(() -> new RuntimeException("Repair job not found"));
                    RepairConversation conversation = conversationRepository.save(RepairConversation.builder()
                            .repairJob(repairJob)
                            .isReadOnly(isClosed(repairJob))
                            .build());

                    String clientUserId = repairJob.getUser() != null
                            ? repairJob.getUser().getId().toString()
                            : (repairJob.getAppointment() != null && repairJob.getAppointment().getUser() != null
                                ? repairJob.getAppointment().getUser().getId().toString() : null);
                    if (clientUserId != null) {
                        ensureMember(
                                conversation,
                                ConversationMemberRole.CLIENT,
                                "user:" + clientUserId,
                                clientUserId,
                                null,
                                true
                        );
                    }
                    if (repairJob.getAssignedTechnicianId() != null) {
                        assignMechanic(repairId, repairJob.getAssignedTechnicianId());
                    }
                    return conversation;
                });
    }

    public RepairConversationDto getConversationDto(Long repairId, Authentication authentication) {
        RepairConversation conversation = getOrCreateConversation(repairId);
        requireReadAccess(conversation, authentication);
        return toConversationDto(conversation);
    }

    public RepairConversationDto getConversationByAppointment(Long appointmentId, Authentication authentication) {
        RepairJob repairJob = repairJobRepository.findFirstByAppointmentId(appointmentId)
                .orElseThrow(() -> new RuntimeException("Repair chat is not available for this appointment yet"));
        RepairConversation conversation = getOrCreateConversation(repairJob.getId());
        requireReadAccess(conversation, authentication);
        return toConversationDto(conversation);
    }

    public List<RepairMessageDto> getMessages(Long repairId, Authentication authentication) {
        RepairConversation conversation = getOrCreateConversation(repairId);
        requireReadAccess(conversation, authentication);
        return messageRepository.findByConversationIdOrderByCreatedAtAsc(conversation.getId()).stream()
                .map(this::toMessageDto)
                .toList();
    }

    public RepairMessageDto sendMessage(Long repairId, RepairMessageRequest request, Authentication authentication) {
        if (request == null || request.getBody() == null || request.getBody().trim().isEmpty()) {
            throw new RuntimeException("Message body is required");
        }

        RepairConversation conversation = getOrCreateConversation(repairId);
        requireWriteAccess(conversation, authentication);
        if (Boolean.TRUE.equals(conversation.getIsReadOnly()) || isClosed(conversation.getRepairJob())) {
            throw new RuntimeException("This repair conversation is read-only");
        }

        String senderRole = resolveSenderRole(conversation, authentication);
        RepairMessage saved = messageRepository.save(RepairMessage.builder()
                .conversation(conversation)
                .repairJob(conversation.getRepairJob())
                .senderId(authentication.getName())
                .senderRole(senderRole)
                .body(request.getBody().trim())
                .build());

        RepairMessageDto dto = toMessageDto(saved);

        // Broadcast over STOMP WebSocket
        try {
            messagingTemplate.convertAndSend("/topic/repairs/" + repairId + "/messages", dto);
            if (conversation.getRepairJob() != null && conversation.getRepairJob().getAppointment() != null) {
                Long appointmentId = conversation.getRepairJob().getAppointment().getId();
                if (appointmentId != null) {
                    messagingTemplate.convertAndSend("/topic/appointments/" + appointmentId + "/messages", dto);
                }
            }
        } catch (Exception e) {
            log.error("Failed to broadcast WebSocket chat message for repairId={}: {}", repairId, e.getMessage());
        }

        return dto;
    }

    public RepairConversationDto assignMechanic(Long repairId, Long mechanicId) {
        RepairJob repairJob = repairJobRepository.findById(repairId)
                .orElseThrow(() -> new RuntimeException("Repair job not found"));
        Mechanic mechanic = mechanicRepository.findById(mechanicId)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));

        repairJob.setAssignedTechnicianId(mechanicId);
        repairJobRepository.save(repairJob);

        RepairConversation conversation = getOrCreateConversation(repairId);
        List<RepairConversationMember> existingMembers = memberRepository.findByConversationId(conversation.getId());
        for (RepairConversationMember member : existingMembers) {
            if (member.getRole() == ConversationMemberRole.MECHANIC
                    && !mechanicId.equals(member.getMechanicId())) {
                member.setCanWrite(false);
            }
        }

        ensureMember(
                conversation,
                ConversationMemberRole.MECHANIC,
                "mechanic:" + mechanicId,
                resolveProfileUserId(mechanic.getEmail()),
                mechanicId,
                true
        );
        return toConversationDto(conversation);
    }

    public RepairConversationDto assignMechanicToAppointment(Long appointmentId, Long mechanicId) {
        RepairJob repairJob = repairJobService.getOrCreateRepairJobForAppointment(appointmentId);
        return assignMechanic(repairJob.getId(), mechanicId);
    }

    private RepairConversationMember ensureMember(
            RepairConversation conversation,
            ConversationMemberRole role,
            String memberRef,
            String memberUserId,
            Long mechanicId,
            boolean canWrite
    ) {
        return memberRepository.findByConversationIdAndRoleAndMemberRef(conversation.getId(), role, memberRef)
                .map(existing -> {
                    existing.setMemberUserId(memberUserId);
                    existing.setMechanicId(mechanicId);
                    existing.setCanWrite(canWrite);
                    return existing;
                })
                .orElseGet(() -> memberRepository.save(RepairConversationMember.builder()
                        .conversation(conversation)
                        .role(role)
                        .memberRef(memberRef)
                        .memberUserId(memberUserId)
                        .mechanicId(mechanicId)
                        .canWrite(canWrite)
                        .build()));
    }

    private void requireReadAccess(RepairConversation conversation, Authentication authentication) {
        if (isAdmin(authentication) || ownsRepair(conversation, authentication)
                || memberRepository.existsByConversationIdAndMemberUserIdAndCanWriteTrue(
                conversation.getId(), authentication.getName())) {
            return;
        }
        throw new RuntimeException("You do not have access to this repair conversation");
    }

    private void requireWriteAccess(RepairConversation conversation, Authentication authentication) {
        if (isAdmin(authentication) || ownsRepair(conversation, authentication)
                || memberRepository.existsByConversationIdAndMemberUserIdAndCanWriteTrue(
                conversation.getId(), authentication.getName())) {
            return;
        }
        throw new RuntimeException("You cannot send messages in this repair conversation");
    }

    private boolean ownsRepair(RepairConversation conversation, Authentication authentication) {
        if (conversation.getRepairJob().getUser() != null) {
            return conversation.getRepairJob().getUser().getId().toString().equals(authentication.getName());
        }
        if (conversation.getRepairJob().getAppointment() != null && conversation.getRepairJob().getAppointment().getUser() != null) {
            return conversation.getRepairJob().getAppointment().getUser().getId().toString().equals(authentication.getName());
        }
        return false;
    }

    private String resolveProfileUserId(String email) {
        if (email == null) {
            return null;
        }
        return profileRepository.findByEmail(email)
                .map(profile -> profile.getId().toString())
                .orElse(email);
    }

    private boolean isAdmin(Authentication authentication) {
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(a -> "ADMIN".equals(a.getAuthority()));
    }

    private String resolveSenderRole(RepairConversation conversation, Authentication authentication) {
        if (isAdmin(authentication)) {
            return "ADMIN";
        }
        if (ownsRepair(conversation, authentication)) {
            return "CLIENT";
        }
        return "MECHANIC";
    }

    private boolean isClosed(RepairJob repairJob) {
        return "COMPLETED".equalsIgnoreCase(repairJob.getStatus())
                || "CANCELLED".equalsIgnoreCase(repairJob.getStatus());
    }

    private RepairConversationDto toConversationDto(RepairConversation conversation) {
        List<RepairConversationMemberDto> members = memberRepository.findByConversationId(conversation.getId()).stream()
                .map(member -> RepairConversationMemberDto.builder()
                        .id(member.getId())
                        .conversationId(conversation.getId())
                        .role(member.getRole().name())
                        .memberRef(member.getMemberRef())
                        .memberUserId(member.getMemberUserId())
                        .mechanicId(member.getMechanicId())
                        .canWrite(member.getCanWrite())
                        .build())
                .toList();

        return RepairConversationDto.builder()
                .id(conversation.getId())
                .conversationId(conversation.getId())
                .repairId(conversation.getRepairJob().getId())
                .realtimeChannel("repair-conversation:" + conversation.getId())
                .isReadOnly(conversation.getIsReadOnly())
                .members(members)
                .createdAt(conversation.getCreatedAt())
                .updatedAt(conversation.getUpdatedAt())
                .build();
    }

    private RepairMessageDto toMessageDto(RepairMessage message) {
        return RepairMessageDto.builder()
                .id(message.getId())
                .conversationId(message.getConversation().getId())
                .repairId(message.getRepairJob().getId())
                .senderId(message.getSenderId())
                .senderRole(message.getSenderRole())
                .body(message.getBody())
                .createdAt(message.getCreatedAt())
                .readAt(message.getReadAt())
                .build();
    }
}
