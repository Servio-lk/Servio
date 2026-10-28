package com.servio.payment.controller;
import com.servio.common.dto.ApiResponse;
import com.servio.finance.FinanceRequests;
import com.servio.finance.InvoiceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/** Compatibility route; all invoice writes now use the linked billing workflow. */
@RestController
@RequestMapping("/api/admin/bills")
@PreAuthorize("hasAuthority('ADMIN')")
@RequiredArgsConstructor
public class BillController {
    private final InvoiceService invoices;
    @PostMapping public Object create(@Valid @RequestBody FinanceRequests.Draft r,Authentication a) {
        return ApiResponse.success("Draft invoice created",invoices.draft(r,a.getName()));
    }
    @GetMapping public Object list() { return ApiResponse.success("Invoices",invoices.invoices()); }
    @GetMapping("/{id}") public Object get(@PathVariable long id) { return ApiResponse.success("Invoice",invoices.invoice(id)); }
}
