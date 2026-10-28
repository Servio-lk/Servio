package com.servio.finance;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;
class MoneyTest {
    private BigDecimal n(String n) { return new BigDecimal(n); }
    @Test void fractionalPartsRoundOnceAtLineLevel() {
        assertEquals(n("100.01"),Money.line(n("0.75"),n("133.34")));
        assertEquals(n("6500.00"),Money.net(n("7000"),n("500")));
    }
    @Test void invoiceDiscountCannotCreateNegativeInvoice() {
        assertThrows(IllegalArgumentException.class,()->Money.net(n("10"),n("11")));
        assertThrows(IllegalArgumentException.class,()->Money.line(n("-1"),n("20")));
        assertThrows(IllegalArgumentException.class,()->Money.positive(n("0.004"),"Payment"));
    }
    @Test void monthlySalaryUsesApprovedHoursAndUnpaidLeave() {
        var s=Money.salary(n("60000"),n("5000"),n("6"),n("500"),n("1"),n("30"),n("5000"),n("0"));
        assertEquals(n("3000.00"),s.overtimePay()); assertEquals(n("2000.00"),s.leaveDeduction());
        assertEquals(n("68000.00"),s.gross()); assertEquals(n("61000.00"),s.net());
    }
    @Test void paidLeaveDoesNotReduceSalaryAndLeaveCannotExceedBasic() {
        assertEquals(n("60000.00"),Money.salary(n("60000"),n("0"),n("0"),n("0"),n("0"),n("26"),n("0"),n("0")).net());
        assertEquals(n("60000.00"),Money.salary(n("60000"),n("0"),n("0"),n("0"),n("31"),n("26"),n("0"),n("0")).leaveDeduction());
    }
    @Test void invalidPoliciesAndExcessDeductionsAreRejected() {
        assertThrows(IllegalArgumentException.class,()->Money.salary(n("100"),n("0"),n("0"),n("0"),n("0"),n("0"),n("0"),n("0")));
        assertThrows(IllegalArgumentException.class,()->Money.salary(n("100"),n("0"),n("0"),n("0"),n("0"),n("26"),n("101"),n("0")));
    }
}
