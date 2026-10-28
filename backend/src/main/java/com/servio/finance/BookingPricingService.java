package com.servio.finance;
import com.servio.booking.dto.AppointmentRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import static com.servio.finance.FinanceStore.*;

@Service
@RequiredArgsConstructor
public class BookingPricingService {
    private final FinanceStore db;
    @Transactional(readOnly=true)
    public void price(AppointmentRequest request) {
        var service=request.getServiceId()!=null
            ? db.one("SELECT id,name,base_price FROM services WHERE id=? AND is_active=true",request.getServiceId())
            : db.one("SELECT id,name,base_price FROM services WHERE LOWER(name)=LOWER(?) AND is_active=true",request.getServiceType());
        BigDecimal subtotal=Money.nonNegative(decimal(service,"base_price"),"Service price");
        if(request.getOptionId()!=null) {
            var option=db.one("SELECT price_adjustment FROM service_options WHERE id=? AND service_id=?",request.getOptionId(),service.get("id"));
            subtotal=Money.nonNegative(subtotal.add(decimal(option,"price_adjustment")),"Package price");
        }
        BigDecimal discount=BigDecimal.ZERO;
        if(request.getPromoCode()!=null&&!request.getPromoCode().isBlank()) {
            var now=LocalDateTime.now();
            var offer=db.one("SELECT * FROM offers WHERE UPPER(promo_code)=UPPER(?) AND (is_active=true OR is_active IS NULL) AND (valid_from IS NULL OR valid_from<=?) AND (valid_until IS NULL OR valid_until>=?)",request.getPromoCode().trim(),now,now);
            Object applicable=offer.get("applicable_service");
            if(applicable!=null&&!applicable.toString().isBlank()&&!applicable.toString().equalsIgnoreCase(service.get("name").toString()))
                throw new IllegalArgumentException("Promo code is not valid for this service");
            BigDecimal value=Money.nonNegative(decimal(offer,"discount_value"),"Offer discount");
            if("FIXED_AMOUNT".equals(offer.get("discount_type"))) discount=value.min(subtotal);
            else if("PERCENTAGE".equals(offer.get("discount_type"))) {
                if(value.compareTo(new BigDecimal("100"))>0) throw new IllegalArgumentException("Invalid percentage discount");
                discount=Money.round(subtotal.multiply(value).divide(new BigDecimal("100")));
            } else throw new IllegalArgumentException("Unsupported promo discount type");
        }
        request.setServiceType(service.get("name").toString());
        request.setEstimatedCost(Money.net(subtotal,discount));
    }
}
