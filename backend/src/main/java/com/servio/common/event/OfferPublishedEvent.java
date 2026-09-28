package com.servio.common.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class OfferPublishedEvent extends ApplicationEvent {
    private final Long offerId;
    private final String title;
    private final String promoCode;

    public OfferPublishedEvent(Object source, Long offerId, String title, String promoCode) {
        super(source);
        this.offerId = offerId;
        this.title = title;
        this.promoCode = promoCode;
    }
}