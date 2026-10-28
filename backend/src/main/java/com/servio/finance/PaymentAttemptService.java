package com.servio.finance;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional
public class PaymentAttemptService {
    private final FinanceStore db;
    public String reserve(long appointmentId,BigDecimal amount,String currency) {
        db.one("SELECT id FROM appointments WHERE id=? FOR UPDATE",appointmentId);
        if(!"LKR".equals(currency)) throw new IllegalArgumentException("Servio checkout supports LKR");
        Money.positive(amount,"Checkout amount");
        if(!db.rows("SELECT id FROM payments WHERE appointment_id=? AND payment_status='COMPLETED'",appointmentId).isEmpty())
            throw new IllegalStateException("A booking payment has already been received; collect any final balance through its invoice");
        db.update("UPDATE payment_attempts SET status='EXPIRED' WHERE appointment_id=? AND status='PENDING' AND expires_at<CURRENT_TIMESTAMP",appointmentId);
        var pending=db.rows("SELECT * FROM payment_attempts WHERE appointment_id=? AND status='PENDING'",appointmentId);
        if(!pending.isEmpty()) {
            var p=pending.get(0);
            if(FinanceStore.decimal(p,"expected_amount").compareTo(amount)!=0) throw new IllegalStateException("Checkout amount changed; wait for the current payment attempt to expire");
            return p.get("order_id").toString();
        }
        String order="ORD-"+appointmentId+"-"+UUID.randomUUID();
        db.update("INSERT INTO payment_attempts(order_id,appointment_id,expected_amount,currency,expires_at) VALUES(?,?,?,?,CURRENT_TIMESTAMP+INTERVAL '10' MINUTE)",order,appointmentId,Money.round(amount),currency);
        return order;
    }
    public Map<String,Object> validate(String order,String amount,String currency) {
        var lookup=db.one("SELECT * FROM payment_attempts WHERE order_id=?",order);
        db.one("SELECT id FROM appointments WHERE id=? FOR UPDATE",lookup.get("appointment_id"));
        var attempt=db.one("SELECT * FROM payment_attempts WHERE order_id=? FOR UPDATE",order);
        if(!currency.equals(attempt.get("currency"))||FinanceStore.decimal(attempt,"expected_amount").compareTo(new BigDecimal(amount))!=0)
            throw new SecurityException("Payment amount or currency differs from checkout");
        return attempt;
    }
    public void complete(String order,String transactionId) {
        if(transactionId==null||transactionId.isBlank()) throw new SecurityException("Payment transaction reference is required");
        db.update("UPDATE payment_attempts SET status='COMPLETED',transaction_id=? WHERE order_id=?",transactionId,order);
    }
    public void failed(String order,String status) {
        if(!"0".equals(status)) db.update("UPDATE payment_attempts SET status='FAILED' WHERE order_id=? AND status<>'COMPLETED'",order);
    }
}
