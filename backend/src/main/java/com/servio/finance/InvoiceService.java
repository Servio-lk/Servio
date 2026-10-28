package com.servio.finance;
import com.servio.admin.dto.StockUpdateRequest;
import com.servio.admin.repository.JobCardRepository;
import com.servio.inventory.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.Year;
import java.util.*;
import static com.servio.finance.FinanceStore.*;

@Service
@RequiredArgsConstructor
@Transactional
public class InvoiceService {
    private final FinanceStore db;
    private final JobCardRepository jobs;
    private final com.servio.admin.service.JobCardService jobCards;
    private final InventoryService inventory;
    private final org.springframework.context.ApplicationEventPublisher events;

    public List<Map<String,Object>> jobs() {
        return db.rows("SELECT j.id,j.job_number,j.service_type,j.estimated_cost,j.actual_cost,j.appointment_id FROM job_cards j ORDER BY j.id DESC");
    }
    public Map<String,Object> createJob(FinanceRequests.Job r,String actor) {
        if((r.appointmentId()==null)==(r.walkInCustomerId()==null)) throw new IllegalArgumentException("Select either an appointment or a walk-in customer");
        var dto=new com.servio.admin.dto.JobCardDto();dto.setBillingRequestKey(r.requestKey());
        if(r.appointmentId()!=null) {
            var a=db.one("SELECT * FROM appointments WHERE id=? FOR UPDATE",r.appointmentId());
            var current=db.rows("SELECT * FROM job_cards WHERE appointment_id=? AND status<>'CANCELLED' ORDER BY id",r.appointmentId());
            if(!current.isEmpty()) return current.get(0);
            if("CANCELLED".equals(a.get("status"))) throw new IllegalArgumentException("Cannot create a job for a cancelled appointment");
            dto.setAppointmentId(r.appointmentId());dto.setServiceType(a.get("service_type").toString());
            dto.setEstimatedCost(decimal(a,"estimated_cost"));
        } else {
            db.one("SELECT id FROM walk_in_customers WHERE id=? FOR UPDATE",r.walkInCustomerId());
            if(r.serviceId()==null) throw new IllegalArgumentException("Select a service package for a walk-in job");
            var service=db.one("SELECT name,base_price FROM services WHERE id=? AND is_active=true",r.serviceId());
            dto.setWalkInCustomerId(r.walkInCustomerId());dto.setServiceType(service.get("name").toString());
            dto.setEstimatedCost(Money.nonNegative(decimal(service,"base_price"),"Service price"));
        }
        var existing=db.rows("SELECT * FROM job_cards WHERE billing_request_key=?",r.requestKey());
        if(!existing.isEmpty()) {
            var j=existing.get(0);
            if(r.appointmentId()!=null ? !Objects.equals(j.get("appointment_id"),r.appointmentId()) : !Objects.equals(j.get("walk_in_customer_id"),r.walkInCustomerId()))
                throw new IllegalArgumentException("Job request key belongs to another customer");
            return j;
        }
        var job=jobCards.createJobCard(dto);db.audit("JOB",job.getId(),"CREATE",actor,"Created for billing");
        return db.one("SELECT * FROM job_cards WHERE id=?",job.getId());
    }
    public List<Map<String,Object>> charges(long jobId) {
        return db.rows("SELECT * FROM job_charges WHERE job_card_id=? AND reversed_at IS NULL ORDER BY id",jobId);
    }
    private void editableJob(long jobId) {
        db.one("SELECT id FROM job_cards WHERE id=? FOR UPDATE",jobId);
        if(!db.rows("SELECT id FROM billing_invoices WHERE job_card_id=? AND status='ISSUED'",jobId).isEmpty())
            throw new IllegalStateException("Issued invoices are immutable. Void the invoice before changing job charges.");
    }
    public Map<String,Object> charge(FinanceRequests.Charge r,String actor) {
        editableJob(r.jobCardId());
        var existing=db.rows("SELECT * FROM job_charges WHERE request_key=?",r.requestKey());
        if(!existing.isEmpty()) {
            var old=existing.get(0);
            if(id(old,"job_card_id")!=r.jobCardId() || !Objects.equals(old.get("inventory_item_id"),r.inventoryItemId()) || decimal(old,"quantity").compareTo(r.quantity())!=0)
                throw new IllegalArgumentException("Charge request key was already used with different details");
            return old;
        }
        var job=jobs.findById(r.jobCardId()).orElseThrow(()->new IllegalArgumentException("Job not found"));
        BigDecimal quantity=Money.positive(r.quantity(),"Quantity"), rate;
        String description;
        if(r.inventoryItemId()!=null) {
            var item=db.one("SELECT * FROM inventory_items WHERE id=? FOR UPDATE",r.inventoryItemId());
            rate=Money.nonNegative(decimal(item,"selling_price_per_unit"),"Selling price");
            description=item.get("name").toString();
            inventory.updateStock(r.inventoryItemId(),StockUpdateRequest.builder().type("CONSUME")
                .quantity(quantity).notes("Issued to job " + job.getJobNumber()).build(),actor);
        } else {
            if(quantity.compareTo(BigDecimal.ONE)!=0) throw new IllegalArgumentException("Service package quantity must be one");
            if(!db.rows("SELECT id FROM job_charges WHERE job_card_id=? AND inventory_item_id IS NULL AND reversed_at IS NULL",r.jobCardId()).isEmpty())
                throw new IllegalArgumentException("Service package already recorded");
            BigDecimal cost=job.getActualCost()!=null ? job.getActualCost() : job.getEstimatedCost();
            rate=Money.nonNegative(cost,"Job service cost"); description=job.getServiceType();
        }
        long charge=db.insert("INSERT INTO job_charges(job_card_id,inventory_item_id,description,quantity,rate,amount,request_key,created_by) VALUES(?,?,?,?,?,?,?,?) RETURNING id",
            r.jobCardId(),r.inventoryItemId(),description,quantity,rate,Money.line(quantity,rate),r.requestKey(),actor);
        db.audit("JOB_CHARGE",charge,"CREATE",actor,description);
        return db.one("SELECT * FROM job_charges WHERE id=?",charge);
    }
    public void reverseCharge(long chargeId,String actor) {
        var c=db.one("SELECT * FROM job_charges WHERE id=?",chargeId);
        editableJob(id(c,"job_card_id"));
        c=db.one("SELECT * FROM job_charges WHERE id=? FOR UPDATE",chargeId);
        if(c.get("reversed_at")!=null) return;
        if(c.get("inventory_item_id")!=null) {
            db.one("SELECT id FROM inventory_items WHERE id=? FOR UPDATE",c.get("inventory_item_id"));
            inventory.updateStock(id(c,"inventory_item_id"),StockUpdateRequest.builder().type("RECEIVE")
                .quantity(decimal(c,"quantity")).notes("Returned from job charge " + chargeId).build(),actor);
        }
        db.update("UPDATE job_charges SET reversed_at=CURRENT_TIMESTAMP,reversed_by=? WHERE id=?",actor,chargeId);
        db.audit("JOB_CHARGE",chargeId,"REVERSE",actor,"Parts returned / charge removed");
    }
    public Map<String,Object> draft(FinanceRequests.Draft r,String actor) {
        editableJob(r.jobCardId());
        var existing=db.rows("SELECT id,job_card_id FROM billing_invoices WHERE request_key=?",r.requestKey());
        if(!existing.isEmpty()) {
            if(id(existing.get(0),"job_card_id")!=r.jobCardId()) throw new IllegalArgumentException("Request key belongs to another job");
            return invoice(id(existing.get(0),"id"));
        }
        var job=jobs.findById(r.jobCardId()).orElseThrow(()->new IllegalArgumentException("Job not found"));
        var a=job.getAppointment();
        if(a==null) throw new IllegalArgumentException("Job must have an appointment");
        db.one("SELECT id FROM appointments WHERE id=? FOR UPDATE",a.getId());
        var lines=charges(r.jobCardId());
        if(lines.isEmpty()) throw new IllegalArgumentException("Record job charges first");
        BigDecimal subtotal=lines.stream().map(x->decimal(x,"amount")).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal discount=Money.nonNegative(r.discount(),"Discount"),net=Money.net(subtotal,discount);
        var active=db.rows("SELECT * FROM billing_invoices WHERE appointment_id=? AND status<>'VOID' FOR UPDATE",a.getId());
        long invoiceId;
        if(!active.isEmpty()) {
            var old=active.get(0);
            if(!"DRAFT".equals(old.get("status")) || id(old,"job_card_id")!=r.jobCardId()) throw new IllegalStateException("Appointment already has an invoice");
            invoiceId=id(old,"id");
            db.update("UPDATE billing_invoices SET sub_total=?,discount=?,net_total=? WHERE id=?",subtotal,discount,net,invoiceId);
            db.update("DELETE FROM billing_invoice_items WHERE bill_id=?",invoiceId);
        } else {
            var walk=job.getWalkInCustomer(); var user=a.getUser(); var vehicle=a.getVehicle();
            String name=walk!=null ? walk.getFullName() : user!=null ? user.getFullName() : "Customer";
            String phone=walk!=null ? walk.getPhone() : user!=null ? user.getPhone() : "";
            String plate=walk!=null ? walk.getLicensePlate() : vehicle!=null ? vehicle.getLicensePlate() : "";
            long serial=db.amount("SELECT nextval('billing_invoice_number_seq')").longValue();
            invoiceId=db.insert("INSERT INTO billing_invoices(invoice_no,date,customer_name,customer_phone,vehicle_no,payment_mode,sub_total,discount,net_total,issued_by,created_at,job_card_id,appointment_id,status,request_key) VALUES(?,CURRENT_TIMESTAMP,?,?,?,'UNPAID',?,?,?,?,CURRENT_TIMESTAMP,?,?,'DRAFT',?) RETURNING id",
                String.format("INV-%s-%06d",Year.now(),serial),name,phone,plate,subtotal,discount,net,actor,r.jobCardId(),a.getId(),r.requestKey());
        }
        for(var line:lines) db.update("INSERT INTO billing_invoice_items(bill_id,inventory_item_id,description,quantity,rate,amount) VALUES(?,?,?,?,?,?)",
            invoiceId,line.get("inventory_item_id"),line.get("description"),line.get("quantity"),line.get("rate"),line.get("amount"));
        db.audit("INVOICE",invoiceId,"DRAFT",actor,"Totals calculated from job charges");
        return invoice(invoiceId);
    }
    public List<Map<String,Object>> invoices() {
        return db.rows("SELECT b.*, COALESCE(p.paid,0)-COALESCE(r.refunded,0) AS paid_amount, b.net_total-COALESCE(p.paid,0)+COALESCE(r.refunded,0) AS balance_due FROM billing_invoices b LEFT JOIN (SELECT bill_id,SUM(amount) paid FROM payment_allocations GROUP BY bill_id) p ON p.bill_id=b.id LEFT JOIN (SELECT bill_id,SUM(amount) refunded FROM billing_refunds GROUP BY bill_id) r ON r.bill_id=b.id ORDER BY b.id DESC");
    }
    public Map<String,Object> invoice(long invoiceId) {
        var b=db.one("SELECT * FROM billing_invoices WHERE id=?",invoiceId);
        BigDecimal allocated=db.amount("SELECT COALESCE(SUM(amount),0) FROM payment_allocations WHERE bill_id=?",invoiceId);
        BigDecimal refunded=db.amount("SELECT COALESCE(SUM(amount),0) FROM billing_refunds WHERE bill_id=?",invoiceId);
        BigDecimal paid=allocated.subtract(refunded),total=decimal(b,"net_total");
        b.put("paid_amount",paid); b.put("balance_due",total.subtract(paid));
        b.put("settlement_status",paid.compareTo(total)>=0 ? "PAID" : paid.signum()>0 ? "PARTIALLY_PAID" : "UNPAID");
        b.put("items",db.rows("SELECT * FROM billing_invoice_items WHERE bill_id=? ORDER BY id",invoiceId));
        b.put("payments",db.rows("SELECT p.id,p.amount,p.payment_method,p.payment_date,COALESCE(p.reference,p.transaction_id) AS transaction_id,a.amount AS allocated_amount FROM payment_allocations a JOIN payments p ON p.id=a.payment_id WHERE a.bill_id=? ORDER BY p.id",invoiceId));
        b.put("refunds",db.rows("SELECT * FROM billing_refunds WHERE bill_id=? ORDER BY id",invoiceId));
        return b;
    }
    public Map<String,Object> issue(long invoiceId,String actor) {
        var b=db.one("SELECT * FROM billing_invoices WHERE id=?",invoiceId);
        if(b.get("job_card_id")!=null) editableJobForIssue(id(b,"job_card_id"));
        b=db.one("SELECT * FROM billing_invoices WHERE id=? FOR UPDATE",invoiceId);
        if("ISSUED".equals(b.get("status"))) return invoice(invoiceId);
        if(!"DRAFT".equals(b.get("status"))) throw new IllegalStateException("Only drafts can be issued");
        // Re-snapshot current job charges so a draft cannot issue stale amounts.
        var lines=charges(id(b,"job_card_id"));
        if(lines.isEmpty()) throw new IllegalArgumentException("No job charges");
        BigDecimal subtotal=lines.stream().map(x->decimal(x,"amount")).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal net=Money.net(subtotal,decimal(b,"discount"));
        db.update("DELETE FROM billing_invoice_items WHERE bill_id=?",invoiceId);
        for(var l:lines) db.update("INSERT INTO billing_invoice_items(bill_id,inventory_item_id,description,quantity,rate,amount) VALUES(?,?,?,?,?,?)",invoiceId,l.get("inventory_item_id"),l.get("description"),l.get("quantity"),l.get("rate"),l.get("amount"));
        db.update("UPDATE billing_invoices SET status='ISSUED',issued_at=CURRENT_TIMESTAMP,issued_by=?,sub_total=?,net_total=? WHERE id=?",actor,subtotal,net,invoiceId);
        db.update("UPDATE appointments SET actual_cost=? WHERE id=?",net,b.get("appointment_id"));
        allocate(invoiceId,actor);
        db.audit("INVOICE",invoiceId,"ISSUE",actor,"Invoice snapshot frozen");
        return invoice(invoiceId);
    }
    private void editableJobForIssue(long jobId) { db.one("SELECT id FROM job_cards WHERE id=? FOR UPDATE",jobId); }
    public Map<String,Object> allocate(long invoiceId,String actor) {
        var b=db.one("SELECT * FROM billing_invoices WHERE id=? FOR UPDATE",invoiceId);
        if(!"ISSUED".equals(b.get("status"))) throw new IllegalStateException("Issue invoice before applying payments");
        if(b.get("appointment_id")==null) return invoice(invoiceId);
        BigDecimal balance=decimal(invoice(invoiceId),"balance_due");
        for(var p:db.rows("SELECT * FROM payments WHERE appointment_id=? AND payment_status='COMPLETED' AND currency=? ORDER BY id FOR UPDATE",b.get("appointment_id"),b.get("currency"))) {
            BigDecimal used=db.amount("SELECT COALESCE(SUM(amount),0) FROM payment_allocations WHERE payment_id=?",p.get("id"));
            BigDecimal refundedAdvance=db.amount("SELECT COALESCE(SUM(amount),0) FROM billing_refunds WHERE payment_id=? AND bill_id IS NULL",p.get("id"));
            BigDecimal available=decimal(p,"amount").subtract(used).subtract(refundedAdvance),amount=available.min(balance);
            if(amount.signum()>0) {
                int updated=db.update("UPDATE payment_allocations SET amount=amount+? WHERE bill_id=? AND payment_id=?",amount,invoiceId,p.get("id"));
                if(updated==0) db.update("INSERT INTO payment_allocations(bill_id,payment_id,amount,created_by) VALUES(?,?,?,?)",invoiceId,p.get("id"),amount,actor);
                balance=balance.subtract(amount);
            }
        }
        return invoice(invoiceId);
    }
    public Map<String,Object> collect(long invoiceId,FinanceRequests.Collection r,String actor) {
        var b=db.one("SELECT * FROM billing_invoices WHERE id=? FOR UPDATE",invoiceId);
        var duplicate=db.rows("SELECT p.*,a.bill_id FROM payments p JOIN payment_allocations a ON a.payment_id=p.id WHERE p.request_key=?",r.requestKey());
        if(!duplicate.isEmpty()) {
            var old=duplicate.get(0);
            if(id(old,"bill_id")!=invoiceId || decimal(old,"amount").compareTo(r.amount())!=0 || !r.method().equals(old.get("payment_method")))
                throw new IllegalArgumentException("Payment request key was already used with different details");
            return invoice(invoiceId);
        }
        if(!"ISSUED".equals(b.get("status"))) throw new IllegalStateException("Invoice must be issued");
        allocate(invoiceId,actor);
        BigDecimal amount=Money.positive(r.amount(),"Payment"),balance=decimal(invoice(invoiceId),"balance_due");
        if(amount.compareTo(balance)>0) throw new IllegalArgumentException("Payment exceeds outstanding balance");
        Object user=null;
        if(b.get("appointment_id")!=null) user=db.one("SELECT user_id FROM appointments WHERE id=?",b.get("appointment_id")).get("user_id");
        long payment=db.insert("INSERT INTO payments(appointment_id,user_id,amount,payment_method,payment_status,transaction_id,payment_date,created_at,currency,request_key,reference) VALUES(?,?,?,?,'COMPLETED',?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,?,?,?) RETURNING id",
            b.get("appointment_id"),user,amount,r.method(),"MANUAL-"+r.requestKey(),b.get("currency"),r.requestKey(),r.reference());
        db.update("INSERT INTO payment_allocations(bill_id,payment_id,amount,created_by) VALUES(?,?,?,?)",invoiceId,payment,amount,actor);
        if(b.get("appointment_id")!=null) publishPayment(id(b,"appointment_id"),user,amount,r.method());
        db.audit("INVOICE",invoiceId,"PAYMENT",actor,amount+" "+r.method()+" "+r.reference());
        return invoice(invoiceId);
    }
    /** Existing appointment collection route records an advance, or settles its issued invoice. */
    public void appointmentPayment(long appointmentId,com.servio.admin.dto.PaymentCollectionRequest r,String actor) {
        var a=db.one("SELECT * FROM appointments WHERE id=? FOR UPDATE",appointmentId);
        BigDecimal amount=Money.positive(r.getAmount(),"Payment");
        var existing=db.rows("SELECT * FROM payments WHERE request_key=?",r.getRequestKey());
        if(!existing.isEmpty()) {
            var old=existing.get(0);
            if(id(old,"appointment_id")!=appointmentId || decimal(old,"amount").compareTo(amount)!=0 || !r.getPaymentMethod().equals(old.get("payment_method")))
                throw new IllegalArgumentException("Payment request key was already used with different details");
            return;
        }
        var issued=db.rows("SELECT id FROM billing_invoices WHERE appointment_id=? AND status='ISSUED'",appointmentId);
        if(!issued.isEmpty()) {
            collect(id(issued.get(0),"id"),new FinanceRequests.Collection(amount,r.getPaymentMethod(),"Appointment collection",r.getRequestKey()),actor);
            return;
        }
        BigDecimal paid=db.amount("SELECT COALESCE(SUM(amount),0) FROM payments WHERE appointment_id=? AND payment_status='COMPLETED' AND currency='LKR'",appointmentId);
        BigDecimal refunded=db.amount("SELECT COALESCE(SUM(r.amount),0) FROM billing_refunds r JOIN payments p ON p.id=r.payment_id WHERE p.appointment_id=?",appointmentId);
        BigDecimal expected=a.get("actual_cost")!=null ? decimal(a,"actual_cost") : decimal(a,"estimated_cost");
        if(amount.compareTo(expected.subtract(paid).add(refunded))>0) throw new IllegalArgumentException("Payment exceeds remaining appointment estimate; issue the final invoice to collect its balance");
        long payment=db.insert("INSERT INTO payments(appointment_id,user_id,amount,payment_method,payment_status,transaction_id,payment_date,created_at,currency,request_key) VALUES(?,?,?,?,'COMPLETED',?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'LKR',?) RETURNING id",
            appointmentId,a.get("user_id"),amount,r.getPaymentMethod(),"ADVANCE-"+r.getRequestKey(),r.getRequestKey());
        publishPayment(appointmentId,a.get("user_id"),amount,r.getPaymentMethod());
        db.audit("PAYMENT",payment,"ADVANCE",actor,amount+" "+r.getPaymentMethod());
    }
    public List<Map<String,Object>> bookingPayments() {
        return db.rows("SELECT p.id,p.appointment_id,p.amount,p.payment_method,p.transaction_id,p.payment_date,a.status AS appointment_status,COALESCE(u.full_name,'Walk-in customer') AS customer_name,p.amount-COALESCE(alloc.used,0)-COALESCE(ref.refunded,0) AS available_amount FROM payments p LEFT JOIN appointments a ON a.id=p.appointment_id LEFT JOIN users u ON u.id=p.user_id LEFT JOIN (SELECT payment_id,SUM(amount) used FROM payment_allocations GROUP BY payment_id) alloc ON alloc.payment_id=p.id LEFT JOIN (SELECT payment_id,SUM(amount) refunded FROM billing_refunds WHERE bill_id IS NULL GROUP BY payment_id) ref ON ref.payment_id=p.id WHERE p.payment_status='COMPLETED' AND p.currency='LKR' ORDER BY p.id DESC");
    }
    public void refundAdvance(long paymentId,FinanceRequests.Refund r,String actor) {
        if(paymentId!=r.paymentId()) throw new IllegalArgumentException("Incorrect original payment");
        var p=db.one("SELECT * FROM payments WHERE id=? FOR UPDATE",paymentId);
        var old=db.rows("SELECT * FROM billing_refunds WHERE request_key=?",r.requestKey());
        if(!old.isEmpty()) {
            var refund=old.get(0);
            if(refund.get("bill_id")!=null || id(refund,"payment_id")!=paymentId || decimal(refund,"amount").compareTo(r.amount())!=0)
                throw new IllegalArgumentException("Refund request key was already used with different details");
            return;
        }
        if(!"COMPLETED".equals(p.get("payment_status"))) throw new IllegalArgumentException("Only completed payments can be refunded");
        BigDecimal used=db.amount("SELECT COALESCE(SUM(amount),0) FROM payment_allocations WHERE payment_id=?",paymentId);
        BigDecimal refunded=db.amount("SELECT COALESCE(SUM(amount),0) FROM billing_refunds WHERE payment_id=? AND bill_id IS NULL",paymentId);
        BigDecimal amount=Money.positive(r.amount(),"Refund");
        if(amount.compareTo(decimal(p,"amount").subtract(used).subtract(refunded))>0)
            throw new IllegalArgumentException("Refund exceeds unallocated advance; refund allocated money from its invoice");
        db.update("INSERT INTO billing_refunds(bill_id,payment_id,amount,reason,reference,request_key,recorded_by) VALUES(NULL,?,?,?,?,?,?)",paymentId,amount,r.reason(),r.reference(),r.requestKey(),actor);
        db.audit("PAYMENT",paymentId,"REFUND_ADVANCE",actor,amount+" "+r.reason()+" "+r.reference());
    }
    private void publishPayment(long appointmentId,Object user,BigDecimal amount,String method) {
        java.util.UUID userId=user==null ? null : java.util.UUID.fromString(user.toString());
        events.publishEvent(new com.servio.common.event.PaymentCompletedEvent(this,appointmentId,userId,amount.doubleValue(),method));
    }
    public Map<String,Object> refund(long invoiceId,FinanceRequests.Refund r,String actor) {
        db.one("SELECT id FROM billing_invoices WHERE id=? FOR UPDATE",invoiceId);
        var old=db.rows("SELECT * FROM billing_refunds WHERE request_key=?",r.requestKey());
        if(!old.isEmpty()) {
            if(id(old.get(0),"bill_id")!=invoiceId || id(old.get(0),"payment_id")!=r.paymentId() || decimal(old.get(0),"amount").compareTo(r.amount())!=0)
                throw new IllegalArgumentException("Refund request key was already used with different details");
            return invoice(invoiceId);
        }
        db.one("SELECT id FROM payments WHERE id=? FOR UPDATE",r.paymentId());
        BigDecimal allocated=db.amount("SELECT COALESCE(SUM(amount),0) FROM payment_allocations WHERE bill_id=? AND payment_id=?",invoiceId,r.paymentId());
        BigDecimal refunded=db.amount("SELECT COALESCE(SUM(amount),0) FROM billing_refunds WHERE bill_id=? AND payment_id=?",invoiceId,r.paymentId());
        BigDecimal amount=Money.positive(r.amount(),"Refund");
        if(amount.compareTo(allocated.subtract(refunded))>0) throw new IllegalArgumentException("Refund exceeds payment allocated to this invoice");
        db.update("INSERT INTO billing_refunds(bill_id,payment_id,amount,reason,reference,request_key,recorded_by) VALUES(?,?,?,?,?,?,?)",invoiceId,r.paymentId(),amount,r.reason(),r.reference(),r.requestKey(),actor);
        db.audit("INVOICE",invoiceId,"REFUND",actor,amount+" "+r.reason()+" "+r.reference());
        return invoice(invoiceId);
    }
    public Map<String,Object> voidInvoice(long invoiceId,String reason,String actor) {
        db.one("SELECT id FROM billing_invoices WHERE id=? FOR UPDATE",invoiceId);
        if(decimal(invoice(invoiceId),"paid_amount").signum()>0) throw new IllegalStateException("Refund allocated payments before voiding");
        db.update("UPDATE billing_invoices SET status='VOID',void_reason=? WHERE id=?",reason,invoiceId);
        db.audit("INVOICE",invoiceId,"VOID",actor,reason); return invoice(invoiceId);
    }
}
