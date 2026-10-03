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

import com.servio.auth.entity.Profile;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

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
                            .orElseGet(() -> repairJobRepository.findFirstByAppointmentId(repairId)
                                    .orElseGet(() -> repairJobService.getOrCreateRepairJobForAppointment(repairId)));
                    if (repairJob == null) {
                        throw new RuntimeException("Repair job not found");
                    }
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
        RepairJob repairJob = repairJobService.getOrCreateRepairJobForAppointment(appointmentId);
        RepairConversation conversation = getOrCreateConversation(repairJob.getId());
        requireReadAccess(conversation, authentication);
        return toConversationDto(conversation);
    }

    public List<RepairMessageDto> getMessages(Long repairId, Authentication authentication) {
        RepairConversation conversation = getOrCreateConversation(repairId);
        requireReadAccess(conversation, authentication);
        
        // Auto mark unread messages as read
        markMessagesRead(conversation.getId(), authentication);

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
        if (isAdmin(authentication) || isMechanic(authentication) || ownsRepair(conversation, authentication)
                || memberRepository.existsByConversationIdAndMemberUserIdAndCanWriteTrue(
                conversation.getId(), authentication.getName())) {
            ensureMechanicEnrolled(conversation, authentication);
            return;
        }
        throw new RuntimeException("You do not have access to this repair conversation");
    }

    private void requireWriteAccess(RepairConversation conversation, Authentication authentication) {
        if (isAdmin(authentication) || isMechanic(authentication) || ownsRepair(conversation, authentication)
                || memberRepository.existsByConversationIdAndMemberUserIdAndCanWriteTrue(
                conversation.getId(), authentication.getName())) {
            ensureMechanicEnrolled(conversation, authentication);
            return;
        }
        throw new RuntimeException("You cannot send messages in this repair conversation");
    }

    private void ensureMechanicEnrolled(RepairConversation conversation, Authentication authentication) {
        if (!isMechanic(authentication) || authentication == null || authentication.getName() == null) {
            return;
        }
        String userId = authentication.getName();
        boolean alreadyMember = memberRepository.findByConversationId(conversation.getId()).stream()
                .anyMatch(m -> userId.equalsIgnoreCase(m.getMemberUserId()));
        if (!alreadyMember) {
            Long mechanicId = null;
            try {
                UUID userUuid = UUID.fromString(userId);
                String email = profileRepository.findById(userUuid)
                        .map(Profile::getEmail)
                        .orElse(null);
                if (email != null) {
                    mechanicId = mechanicRepository.findByEmailIgnoreCase(email)
                            .map(Mechanic::getId)
                            .orElse(null);
                }
            } catch (Exception ignored) {
            }

            ensureMember(
                    conversation,
                    ConversationMemberRole.MECHANIC,
                    "user:" + userId,
                    userId,
                    mechanicId,
                    true
            );
        }
    }

    private boolean ownsRepair(RepairConversation conversation, Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return false;
        }
        String authName = authentication.getName().trim();
        if (conversation.getRepairJob().getUser() != null) {
            String uid = conversation.getRepairJob().getUser().getId().toString();
            if (uid.equalsIgnoreCase(authName)) return true;
        }
        if (conversation.getRepairJob().getAppointment() != null && conversation.getRepairJob().getAppointment().getUser() != null) {
            String uid = conversation.getRepairJob().getAppointment().getUser().getId().toString();
            if (uid.equalsIgnoreCase(authName)) return true;
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
        if (authentication == null) {
            return false;
        }
        boolean hasAdminAuth = authentication.getAuthorities().stream()
                .anyMatch(a -> "ADMIN".equalsIgnoreCase(a.getAuthority())
                        || "ROLE_ADMIN".equalsIgnoreCase(a.getAuthority()));
        if (hasAdminAuth) {
            return true;
        }
        String userId = authentication.getName();
        if (userId != null && !userId.isBlank()) {
            try {
                UUID userUuid = UUID.fromString(userId);
                Profile profile = profileRepository.findById(userUuid).orElse(null);
                if (profile != null && Boolean.TRUE.equals(profile.getIsAdmin())) {
                    return true;
                }
            } catch (Exception ignored) {
            }
        }
        return false;
    }

    private boolean isMechanic(Authentication authentication) {
        if (authentication == null) {
            return false;
        }
        boolean hasAuthority = authentication.getAuthorities().stream()
                .anyMatch(a -> "MECHANIC".equalsIgnoreCase(a.getAuthority())
                        || "ROLE_MECHANIC".equalsIgnoreCase(a.getAuthority())
                        || "STAFF".equalsIgnoreCase(a.getAuthority()));
        if (hasAuthority) {
            return true;
        }
        String userId = authentication.getName();
        if (userId != null && !userId.isBlank()) {
            try {
                UUID userUuid = UUID.fromString(userId);
                Profile profile = profileRepository.findById(userUuid).orElse(null);
                if (profile != null) {
                    if ("MECHANIC".equalsIgnoreCase(profile.getRole())
                            || "STAFF".equalsIgnoreCase(profile.getRole())
                            || Boolean.TRUE.equals(profile.getIsAdmin())) {
                        return true;
                    }
                    if (profile.getEmail() != null && mechanicRepository.findByEmailIgnoreCase(profile.getEmail()).isPresent()) {
                        return true;
                    }
                }
            } catch (Exception ignored) {
                if (mechanicRepository.findByEmailIgnoreCase(userId).isPresent()) {
                    return true;
                }
            }
        }
        return false;
    }

    private String resolveSenderRole(RepairConversation conversation, Authentication authentication) {
        if (isAdmin(authentication)) {
            return "ADMIN";
        }
        if (isMechanic(authentication)) {
            return "MECHANIC";
        }
        if (ownsRepair(conversation, authentication)) {
            return "CLIENT";
        }
        return "MECHANIC";
    }

    private boolean isClosed(RepairJob repairJob) {
        boolean jobClosed = "COMPLETED".equalsIgnoreCase(repairJob.getStatus())
                || "CANCELLED".equalsIgnoreCase(repairJob.getStatus());
        if (jobClosed) return true;

        if (repairJob.getAppointment() != null) {
            String apptStatus = repairJob.getAppointment().getStatus();
            return "COMPLETED".equalsIgnoreCase(apptStatus)
                    || "CANCELLED".equalsIgnoreCase(apptStatus);
        }
        return false;
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

    public List<RepairConversationDto> getAdminConversationList() {
        return conversationRepository.findAllOrderByUpdatedAtDesc().stream()
                .map(this::toAdminConversationDto)
                .toList();
    }

    private RepairConversationDto toAdminConversationDto(RepairConversation conversation) {
        RepairConversationDto dto = toConversationDto(conversation);
        RepairJob job = conversation.getRepairJob();
        if (job != null && job.getAppointment() != null) {
            dto.setAppointmentId(job.getAppointment().getId());
            if (job.getAppointment().getUser() != null) {
                dto.setCustomerName(job.getAppointment().getUser().getFullName());
            }
            if (job.getAppointment().getVehicle() != null) {
                dto.setVehicleInfo(job.getAppointment().getVehicle().getMake() + " " + job.getAppointment().getVehicle().getModel());
            }
        }
        
        messageRepository.findTopByConversationIdOrderByCreatedAtDesc(conversation.getId())
                .ifPresent(msg -> dto.setLastMessage(msg.getBody()));
                
        dto.setUnreadCount(messageRepository.countUnreadForRole(conversation.getId(), "ADMIN"));
        return dto;
    }

    public void markMessagesRead(Long conversationId, Authentication authentication) {
        RepairConversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new RuntimeException("Conversation not found"));
        requireReadAccess(conversation, authentication);
        
        String readerRole = resolveSenderRole(conversation, authentication);
        messageRepository.markReadForRole(conversationId, readerRole, java.time.LocalDateTime.now());
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

    public long getGlobalUnreadCount(Authentication authentication) {
        if (isAdmin(authentication)) {
            return messageRepository.countGlobalUnreadForAdmin();
        } else {
            return messageRepository.countGlobalUnreadForClient(authentication.getName());
        }
    }
}
