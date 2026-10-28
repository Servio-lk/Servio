import { useEffect, useState } from 'react';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import { financeApi, currency } from '@/services/financeApi';
import type { Job, Charge, Invoice } from '@/services/financeApi';
import { Field, Panel, Feedback } from './FinanceComponents';
import { useFinanceAction, inputClass, buttonClass, secondaryClass } from '@/services/financeForm';

export function AdminBilling() {
  const action=useFinanceAction();
  const [jobs,setJobs]=useState<Job[]>([]),[jobId,setJobId]=useState(''),[charges,setCharges]=useState<Charge[]>([]);
  const [inventory,setInventory]=useState<Awaited<ReturnType<typeof financeApi.inventory>>>([]);
  const [partId,setPartId]=useState(''),[quantity,setQuantity]=useState('1'),[discount,setDiscount]=useState('0');
  const [invoices,setInvoices]=useState<Invoice[]>([]),[selected,setSelected]=useState<Invoice|null>(null);
  const [amount,setAmount]=useState(''),[method,setMethod]=useState('CASH'),[reference,setReference]=useState('');
  const [refundPayment,setRefundPayment]=useState(''),[refundAmount,setRefundAmount]=useState(''),[refundReason,setRefundReason]=useState(''),[refundReference,setRefundReference]=useState('');
  const [bookingPayments,setBookingPayments]=useState<{id:number;appointment_id:number;amount:number;available_amount:number;customer_name:string;appointment_status:string;payment_method:string}[]>([]);
  const [advancePayment,setAdvancePayment]=useState(''),[advanceRefundAmount,setAdvanceRefundAmount]=useState(''),[advanceRefundReason,setAdvanceRefundReason]=useState(''),[advanceRefundReference,setAdvanceRefundReference]=useState('');
  const [appointments,setAppointments]=useState<{id:number;serviceType:string;userName:string|null;estimatedCost:number}[]>([]);
  const [walkIns,setWalkIns]=useState<{id:number;fullName:string;licensePlate:string}[]>([]);
  const [services,setServices]=useState<{id:number;name:string;basePrice:number}[]>([]);
  const [source,setSource]=useState('APPOINTMENT'),[appointmentId,setAppointmentId]=useState(''),[walkInId,setWalkInId]=useState(''),[serviceId,setServiceId]=useState('');
  const [voidReason,setVoidReason]=useState('');
  async function refresh() {
    const [j,i,b,a,w,s]=await Promise.all([financeApi.get<Job[]>('/jobs'),financeApi.inventory(),financeApi.get<Invoice[]>('/invoices'),financeApi.resource<typeof appointments>('/admin/appointments'),financeApi.resource<typeof walkIns>('/admin/walk-in-customers'),financeApi.resource<typeof services>('/services')]);
    setJobs(j);setInventory(i);setInvoices(b);setAppointments(a);setWalkIns(w);setServices(s);
    setBookingPayments(await financeApi.get<typeof bookingPayments>('/booking-payments'));
    if(jobId)setCharges(await financeApi.get<Charge[]>(`/jobs/${jobId}/charges`));
  }
  useEffect(()=>{void action.act(refresh,'');},[]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(()=>{
    let active=true;setCharges([]);
    if(jobId)void financeApi.get<Charge[]>(`/jobs/${jobId}/charges`).then(c=>{if(active)setCharges(c);}).catch(e=>{void action.act(async()=>{throw e;});});
    return ()=>{active=false;};
  },[jobId]); // eslint-disable-line react-hooks/exhaustive-deps
  const job=jobs.find(j=>j.id===Number(jobId));
  const subtotal=charges.reduce((sum,c)=>sum+Number(c.amount),0);
  async function addPart(inventoryItemId:number|null) {
    await financeApi.post('/charges',{jobCardId:Number(jobId),inventoryItemId,quantity:inventoryItemId===null?1:Number(quantity)});
    await refresh();
  }
  async function selectInvoice(id:number) {
    const invoice=await financeApi.get<Invoice>(`/invoices/${id}`);setSelected(invoice);setAmount(String(invoice.balance_due));setReference('');
  }
  async function updateInvoice(path:string,body:Record<string,unknown>={}) {
    const invoice=await financeApi.post<Invoice>(path,body);setSelected(invoice);setAmount(String(invoice.balance_due));await refresh();
  }
  function pdf(b:Invoice) {
    const doc=new jsPDF();doc.setFontSize(20);doc.text('SERVIO',14,20);doc.setFontSize(11);
    doc.text(`${b.status==='DRAFT'?'DRAFT ':''}Invoice ${b.invoice_no}`,14,30);
    doc.text(`${b.customer_name} | ${b.vehicle_no||'Vehicle not recorded'}`,14,38);
    doc.text(`Date: ${String(b.date).slice(0,10)} | Status: ${b.status}`,14,46);
    autoTable(doc,{startY:54,head:[['Description','Qty','Rate (LKR)','Amount (LKR)']],body:(b.items??[]).map(i=>[i.description,i.quantity,Number(i.rate).toFixed(2),Number(i.amount).toFixed(2)])});
    const y=(doc as jsPDF & {lastAutoTable:{finalY:number}}).lastAutoTable.finalY+12;
    autoTable(doc,{startY:y,body:[['Subtotal',currency(b.sub_total)],['Discount',currency(b.discount)],['Total',currency(b.net_total)],['Payments less refunds',currency(b.paid_amount)],['Balance due',currency(b.balance_due)]]});
    if(b.payments?.length)autoTable(doc,{head:[['Payment ID','Method','Allocated (LKR)','Reference']],body:b.payments.map(p=>[p.id,p.payment_method,Number(p.allocated_amount).toFixed(2),p.transaction_id||''])});
    doc.save(`Servio_${b.invoice_no}.pdf`);
  }
  return <div className="mx-auto max-w-7xl p-4 md:p-8 space-y-6">
    <div><h1 className="text-3xl font-bold">Billing</h1><p className="text-black/60 mt-1">Create job invoices, apply booking advances, and record balance payments.</p></div>
    <Feedback error={action.error} message={action.message}/>
    <fieldset disabled={action.busy} className="space-y-6 min-w-0">
      <Panel title="Create or open a job card">
        <div className="grid gap-3 md:grid-cols-3 items-end"><Field label="Customer source"><select className={inputClass} value={source} onChange={e=>setSource(e.target.value)}><option value="APPOINTMENT">Appointment</option><option value="WALK_IN">Walk-in customer</option></select></Field>
        {source==='APPOINTMENT'?<Field label="Appointment"><select className={inputClass} value={appointmentId} onChange={e=>setAppointmentId(e.target.value)}><option value="">Select appointment</option>{appointments.map(a=><option key={a.id} value={a.id}>#{a.id} {a.userName||'Customer'} ? {a.serviceType}</option>)}</select></Field>:<><Field label="Walk-in customer"><select className={inputClass} value={walkInId} onChange={e=>setWalkInId(e.target.value)}><option value="">Select registered walk-in</option>{walkIns.map(w=><option key={w.id} value={w.id}>{w.fullName} ? {w.licensePlate}</option>)}</select></Field><Field label="Service package"><select className={inputClass} value={serviceId} onChange={e=>setServiceId(e.target.value)}><option value="">Select service</option>{services.map(s=><option key={s.id} value={s.id}>{s.name} ? {currency(s.basePrice)}</option>)}</select></Field></>}
        <button disabled={source==='APPOINTMENT'?!appointmentId:!walkInId||!serviceId} className={buttonClass} onClick={()=>void action.act(async()=>{const j=await financeApi.post<Job>('/jobs',{appointmentId:source==='APPOINTMENT'?Number(appointmentId):null,walkInCustomerId:source==='WALK_IN'?Number(walkInId):null,serviceId:source==='WALK_IN'?Number(serviceId):null});await refresh();setJobId(String(j.id));},'Job card ready for billing')}>Create / open job</button></div>
        <p className="text-sm text-black/60">Register new walk-in customers in the Walk-in screen before creating their job.</p>
      </Panel>
      <Panel title="Job charges">
        <Field label="Job card"><select className={inputClass} value={jobId} onChange={e=>setJobId(e.target.value)}><option value="">Select a job card</option>{jobs.map(j=><option key={j.id} value={j.id}>{j.job_number} ? {j.service_type}</option>)}</select></Field>
        {job&&<><div className="flex flex-wrap items-center gap-3"><button className={secondaryClass} onClick={()=>void action.act(()=>addPart(null),'Service package recorded')}>Add job service ({currency(job.actual_cost??job.estimated_cost??0)})</button><span className="text-sm text-black/60">Uses the job card?s recorded service cost.</span></div>
        <div className="grid gap-3 md:grid-cols-[1fr_140px_auto] items-end"><Field label="Inventory part"><select className={inputClass} value={partId} onChange={e=>setPartId(e.target.value)}><option value="">Select a part</option>{inventory.map(i=><option key={i.id} value={i.id}>{i.name} ? {currency(i.sellingPricePerUnit)} / stock {i.currentStock}</option>)}</select></Field><Field label="Quantity"><input className={inputClass} type="number" min="0.01" step="0.01" value={quantity} onChange={e=>setQuantity(e.target.value)}/></Field><button disabled={!partId||Number(quantity)<=0} className={secondaryClass} onClick={()=>void action.act(()=>addPart(Number(partId)),'Part issued and stock updated')}>Issue part</button></div>
        <p className="text-sm text-black/60">Stock decreases when you issue parts. Returning a charge restores its stock.</p>
        <div className="overflow-x-auto"><table className="w-full text-sm text-left"><thead><tr><th>Description</th><th>Qty</th><th>Rate</th><th>Amount</th><th/></tr></thead><tbody>{charges.map(c=><tr key={c.id} className="border-t"><td className="py-3">{c.description}</td><td>{c.quantity}</td><td>{currency(c.rate)}</td><td>{currency(c.amount)}</td><td><button className={secondaryClass} onClick={()=>void action.act(async()=>{await financeApi.post(`/charges/${c.id}/reverse`);await refresh();},'Charge returned')}>Return / remove</button></td></tr>)}</tbody></table></div>
        <div className="flex flex-wrap gap-4 items-end"><p className="py-2 font-semibold">Subtotal: {currency(subtotal)}</p><Field label="Invoice discount (LKR)"><input className={inputClass} type="number" min="0" max={subtotal} step="0.01" value={discount} onChange={e=>setDiscount(e.target.value)}/></Field><button disabled={!charges.length||Number(discount)<0||Number(discount)>subtotal} className={buttonClass} onClick={()=>void action.act(async()=>{const b=await financeApi.post<Invoice>('/invoices',{jobCardId:Number(jobId),discount:Number(discount)});setSelected(b);await refresh();},'Draft saved')}>Save draft invoice</button></div></>}
      </Panel>
      <Panel title="Booking advances and unapplied money">
        <div className="overflow-x-auto"><table className="w-full text-sm text-left"><thead><tr><th>Payment</th><th>Customer / appointment</th><th>Method</th><th>Received</th><th>Unapplied</th></tr></thead><tbody>{bookingPayments.filter(p=>p.available_amount>0).map(p=><tr key={p.id} className="border-t"><td className="py-2">#{p.id}</td><td>{p.customer_name} ? #{p.appointment_id} ({p.appointment_status})</td><td>{p.payment_method}</td><td>{currency(p.amount)}</td><td>{currency(p.available_amount)}</td></tr>)}</tbody></table></div>
        <details className="space-y-3"><summary className="cursor-pointer font-medium">Record a completed advance refund</summary><p className="text-sm text-black/60">Use this for cancelled bookings or excess advance money after returning the money through its payment channel.</p><div className="grid gap-3 md:grid-cols-2"><Field label="Original advance"><select className={inputClass} value={advancePayment} onChange={e=>setAdvancePayment(e.target.value)}><option value="">Select payment</option>{bookingPayments.filter(p=>p.available_amount>0).map(p=><option key={p.id} value={p.id}>#{p.id} {p.customer_name} ? {currency(p.available_amount)}</option>)}</select></Field><Field label="Amount refunded"><input className={inputClass} type="number" min="0.01" step="0.01" value={advanceRefundAmount} onChange={e=>setAdvanceRefundAmount(e.target.value)}/></Field><Field label="Reason"><input className={inputClass} value={advanceRefundReason} onChange={e=>setAdvanceRefundReason(e.target.value)}/></Field><Field label="Refund reference"><input className={inputClass} value={advanceRefundReference} onChange={e=>setAdvanceRefundReference(e.target.value)}/></Field></div><button disabled={!advancePayment||Number(advanceRefundAmount)<=0||!advanceRefundReason.trim()||!advanceRefundReference.trim()} className={secondaryClass} onClick={()=>void action.act(async()=>{await financeApi.post(`/booking-payments/${advancePayment}/refunds`,{paymentId:Number(advancePayment),amount:Number(advanceRefundAmount),reason:advanceRefundReason,reference:advanceRefundReference});setAdvancePayment('');setAdvanceRefundAmount('');await refresh();},'Advance refund recorded')}>Record completed advance refund</button></details>
      </Panel>
      <Panel title="Invoices"><div className="overflow-x-auto"><table className="w-full text-sm text-left"><thead><tr><th>Invoice</th><th>Customer</th><th>Status</th><th>Total</th><th>Paid</th><th>Balance</th></tr></thead><tbody>{invoices.map(b=><tr className="border-t" key={b.id}><td className="py-3"><button className="text-[#ff5d2e] font-semibold" onClick={()=>void action.act(()=>selectInvoice(b.id),'')}>{b.invoice_no}</button></td><td>{b.customer_name}</td><td>{b.status}</td><td>{currency(b.net_total)}</td><td>{currency(b.paid_amount)}</td><td>{b.status==='VOID'?'?':currency(b.balance_due)}</td></tr>)}</tbody></table>{!invoices.length&&<p className="py-4 text-black/60">No invoices yet.</p>}</div></Panel>
      {selected&&<Panel title={selected.invoice_no}>
        <p>{selected.customer_name} ? {selected.status} ? {selected.settlement_status}</p>
        <div className="overflow-x-auto"><table className="w-full text-sm text-left"><tbody>{selected.items?.map(i=><tr key={i.id} className="border-t"><td className="py-2">{i.description}</td><td>{i.quantity} ? {currency(i.rate)}</td><td>{currency(i.amount)}</td></tr>)}</tbody></table></div>
        <p className="font-semibold">Total {currency(selected.net_total)} ? Paid {currency(selected.paid_amount)} ? Balance {currency(selected.balance_due)}</p>
        <div className="flex flex-wrap gap-3"><button className={secondaryClass} onClick={()=>pdf(selected)}>Download invoice / payment history</button>{selected.status==='DRAFT'&&<button className={buttonClass} onClick={()=>void action.act(()=>updateInvoice(`/invoices/${selected.id}/issue`),'Invoice issued and advances applied')}>Issue invoice</button>}{selected.status==='ISSUED'&&<button className={secondaryClass} onClick={()=>void action.act(()=>updateInvoice(`/invoices/${selected.id}/allocate`),'Available advances applied')}>Apply available advances</button>}</div>
        {selected.status==='ISSUED'&&<>
          <div className="grid gap-3 md:grid-cols-4 items-end"><Field label="Amount received (LKR)"><input className={inputClass} type="number" min="0.01" max={selected.balance_due} step="0.01" value={amount} onChange={e=>setAmount(e.target.value)}/></Field><Field label="Method"><select className={inputClass} value={method} onChange={e=>setMethod(e.target.value)}><option>CASH</option><option>CARD</option><option>BANK_TRANSFER</option></select></Field><Field label="Receipt / terminal reference"><input className={inputClass} value={reference} onChange={e=>setReference(e.target.value)}/></Field><button disabled={Number(amount)<=0||Number(amount)>selected.balance_due||!reference.trim()} className={buttonClass} onClick={()=>void action.act(()=>updateInvoice(`/invoices/${selected.id}/payments`,{amount:Number(amount),method,reference}),'Payment recorded')}>Record received payment</button></div>
          <p className="text-sm text-black/60">Record cash, card-terminal, or bank payments after receiving them. Online booking payments arrive through PayHere.</p>
          {!!selected.payments?.length&&<details className="space-y-3"><summary className="cursor-pointer font-medium">Record money already refunded</summary><div className="grid gap-3 md:grid-cols-2"><Field label="Original payment"><select className={inputClass} value={refundPayment} onChange={e=>setRefundPayment(e.target.value)}><option value="">Select payment</option>{selected.payments.map(p=><option key={p.id} value={p.id}>#{p.id} {p.payment_method} ? {currency(p.allocated_amount)}</option>)}</select></Field><Field label="Refund amount"><input className={inputClass} type="number" min="0.01" step="0.01" value={refundAmount} onChange={e=>setRefundAmount(e.target.value)}/></Field><Field label="Reason"><input className={inputClass} value={refundReason} onChange={e=>setRefundReason(e.target.value)}/></Field><Field label="Refund receipt / gateway reference"><input className={inputClass} value={refundReference} onChange={e=>setRefundReference(e.target.value)}/></Field></div><button disabled={!refundPayment||Number(refundAmount)<=0||!refundReason.trim()||!refundReference.trim()} className={secondaryClass} onClick={()=>void action.act(()=>updateInvoice(`/invoices/${selected.id}/refunds`,{paymentId:Number(refundPayment),amount:Number(refundAmount),reason:refundReason,reference:refundReference}),'Refund recorded')}>Record completed refund</button></details>}
          {selected.refunds?.map(r=><p key={r.id} className="text-sm">Refund {currency(r.amount)} ? {r.reason} ({r.reference})</p>)}
        </>}
        {selected.status!=='VOID'&&<div className="flex flex-wrap gap-3 items-end"><Field label="Reason to void invoice"><input className={inputClass} value={voidReason} onChange={e=>setVoidReason(e.target.value)}/></Field><button disabled={!voidReason.trim()||selected.paid_amount>0} className={secondaryClass} onClick={()=>void action.act(()=>updateInvoice(`/invoices/${selected.id}/void`,{reason:voidReason}),'Invoice voided')}>Void invoice</button></div>}
      </Panel>}
    </fieldset>
  </div>;
}
export default AdminBilling;
