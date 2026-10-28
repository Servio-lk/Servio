package com.servio.finance;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;

public final class FinanceRequests {
    private FinanceRequests() {}
    public record Job(Long appointmentId, Long walkInCustomerId, Long serviceId, @NotBlank @Size(max=100) String requestKey) {}
    public record Charge(@NotNull Long jobCardId, Long inventoryItemId,
        @NotNull @DecimalMin("0.01") BigDecimal quantity, @NotBlank @Size(max=100) String requestKey) {}
    public record Draft(@NotNull Long jobCardId, @NotNull @DecimalMin("0") BigDecimal discount,
        @NotBlank @Size(max=100) String requestKey) {}
    public record Collection(@NotNull @DecimalMin("0.01") BigDecimal amount,
        @NotBlank @Pattern(regexp="CASH|CARD|BANK_TRANSFER") String method,
        @NotBlank @Size(max=255) String reference, @NotBlank @Size(max=100) String requestKey) {}
    public record Refund(@NotNull Long paymentId, @NotNull @DecimalMin("0.01") BigDecimal amount,
        @NotBlank String reason, @NotBlank @Size(max=255) String reference,
        @NotBlank @Size(max=100) String requestKey) {}
    public record Reason(@NotBlank String reason) {}
    public record Agreement(@NotNull Long mechanicId, @NotNull LocalDate effectiveFrom,
        @NotNull @DecimalMin("0") BigDecimal basicSalary, @NotNull @DecimalMin("0") BigDecimal allowances,
        @NotNull @DecimalMin("0") BigDecimal overtimeRate,
        @NotNull @DecimalMin("1") @DecimalMax("31") BigDecimal leaveDivisor) {}
    public record Attendance(@NotNull Long mechanicId, @NotNull LocalDate workDate,
        @NotBlank @Pattern(regexp="PRESENT|PAID_LEAVE|UNPAID_LEAVE|OFF") String status,
        @NotNull @DecimalMin("0") @DecimalMax("24") BigDecimal overtimeHours, boolean approved) {}
    public record AttendanceBatch(@NotEmpty java.util.List<@jakarta.validation.Valid Attendance> entries) {}
    public record Advance(@NotNull Long mechanicId, @NotNull @DecimalMin("0.01") BigDecimal amount,
        @NotNull LocalDate paidDate, @NotBlank @Size(max=255) String reference,
        @NotBlank @Size(max=100) String requestKey) {}
    public record Month(@NotBlank @Pattern(regexp="\\d{4}-\\d{2}") String month) {}
    public record Adjustment(@NotNull @DecimalMin("0") BigDecimal advanceRecovery,
        @NotNull @DecimalMin("0") BigDecimal otherDeduction, @NotBlank String reason) {}
    public record SalaryPayment(@NotNull @DecimalMin("0.01") BigDecimal amount,
        @NotBlank @Pattern(regexp="CASH|BANK_TRANSFER") String method,
        @NotBlank @Size(max=255) String reference, @NotBlank @Size(max=100) String requestKey) {}
}
