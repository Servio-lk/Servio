package com.servio.finance;
import java.math.BigDecimal;
import java.math.RoundingMode;

/** Shared two-decimal monetary calculations; incoming totals are never authoritative. */
public final class Money {
    private Money() {}
    public static BigDecimal nonNegative(BigDecimal value, String name) {
        if (value == null || value.signum() < 0) throw new IllegalArgumentException(name + " must be non-negative");
        return value.setScale(2, RoundingMode.HALF_UP);
    }
    public static BigDecimal positive(BigDecimal value, String name) {
        BigDecimal result = nonNegative(value, name);
        if (result.signum() == 0) throw new IllegalArgumentException(name + " must be greater than zero");
        return result;
    }
    public static BigDecimal round(BigDecimal value) { return value.setScale(2, RoundingMode.HALF_UP); }
    public static BigDecimal line(BigDecimal quantity, BigDecimal rate) {
        return round(positive(quantity,"Quantity").multiply(nonNegative(rate,"Rate")));
    }
    public static BigDecimal net(BigDecimal subtotal, BigDecimal discount) {
        BigDecimal result = nonNegative(subtotal,"Subtotal").subtract(nonNegative(discount,"Discount"));
        if (result.signum() < 0) throw new IllegalArgumentException("Discount exceeds subtotal");
        return round(result);
    }
    public record Salary(BigDecimal overtimePay, BigDecimal leaveDeduction, BigDecimal gross, BigDecimal net) {}
    public static Salary salary(BigDecimal basic, BigDecimal allowances, BigDecimal hours, BigDecimal rate,
                                BigDecimal unpaidDays, BigDecimal divisor, BigDecimal advance, BigDecimal deductions) {
        basic=nonNegative(basic,"Basic salary"); allowances=nonNegative(allowances,"Allowances");
        BigDecimal overtime = round(nonNegative(hours,"Overtime hours").multiply(nonNegative(rate,"Overtime rate")));
        BigDecimal leave = basic.multiply(nonNegative(unpaidDays,"Unpaid days"))
            .divide(positive(divisor,"Leave divisor"),2,RoundingMode.HALF_UP);
        if (leave.compareTo(basic)>0) leave=basic;
        BigDecimal gross=basic.add(allowances).add(overtime);
        BigDecimal net=gross.subtract(leave).subtract(nonNegative(advance,"Advance recovery")).subtract(nonNegative(deductions,"Deductions"));
        if(net.signum()<0) throw new IllegalArgumentException("Deductions exceed payable salary");
        return new Salary(overtime,leave,round(gross),round(net));
    }
}
