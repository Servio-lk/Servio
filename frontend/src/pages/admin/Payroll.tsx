import { useEffect, useState } from 'react';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import { financeApi, currency, localToday } from '@/services/financeApi';
import type { Mechanic, Agreement, Attendance, Advance, PayrollRun, PayrollItem, Payslip, Summary } from '@/services/financeApi';
import { Field, Panel, Feedback } from './FinanceComponents';
import { useFinanceAction, inputClass, buttonClass, secondaryClass } from '@/services/financeForm';

function PayrollRow({item,run,busy,onAdjust,onPay,onPayslip}:{item:PayrollItem;run:PayrollRun;busy:boolean;onAdjust:(id:number,recovery:number,deduction:number,reason:string)=>void;onPay:(id:number,amount:number,method:string,reference:string)=>void;onPayslip:(id:number)=>void}) {
  const [recovery,setRecovery]=useState(String(item.advance_recovery)),[deduction,setDeduction]=useState(String(item.other_deduction));
  const [reason,setReason]=useState(item.adjustment_reason??''),[amount,setAmount]=useState(String(item.balance_due)),[method,setMethod]=useState('BANK_TRANSFER'),[reference,setReference]=useState('');
  return <article className="border border-black/10 rounded-lg p-4 space-y-3">
    <h3 className="font-semibold">{item.mechanic_name}</h3>
    <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4 text-sm">
      <p>Basic: {currency(item.basic_salary)}</p><p>Allowances: {currency(item.allowances)}</p><p>Overtime: {item.overtime_hours} h ? {currency(item.overtime_rate)} = {currency(item.overtime_pay)}</p><p>Unpaid leave: {item.unpaid_days} days / {item.leave_divisor} = {currency(item.leave_deduction)}</p>
      <p>Advance recovery: {currency(item.advance_recovery)}</p><p>Other deductions: {currency(item.other_deduction)}</p><p className="font-semibold">Net payable: {currency(item.net_payable)}</p><p>Paid: {currency(item.paid_amount)} ? Balance: {currency(item.balance_due)}</p>
    </div>
    {run.status==='DRAFT'?<div className="grid gap-3 md:grid-cols-4 items-end"><Field label="Advance recovery"><input className={inputClass} type="number" min="0" step="0.01" value={recovery} onChange={e=>setRecovery(e.target.value)}/></Field><Field label="Other approved deduction"><input className={inputClass} type="number" min="0" step="0.01" value={deduction} onChange={e=>setDeduction(e.target.value)}/></Field><Field label="Adjustment reason"><input className={inputClass} value={reason} onChange={e=>setReason(e.target.value)}/></Field><button disabled={busy||!reason.trim()||Number(recovery)<0||Number(deduction)<0} className={secondaryClass} onClick={()=>onAdjust(item.id,Number(recovery),Number(deduction),reason)}>Save adjustment</button></div>:<>
      <button className={secondaryClass} disabled={busy} onClick={()=>onPayslip(item.id)}>Download payslip</button>
      {item.balance_due>0&&<div className="grid gap-3 md:grid-cols-4 items-end"><Field label="Salary paid (LKR)"><input className={inputClass} type="number" min="0.01" max={item.balance_due} step="0.01" value={amount} onChange={e=>setAmount(e.target.value)}/></Field><Field label="Payment method"><select className={inputClass} value={method} onChange={e=>setMethod(e.target.value)}><option>BANK_TRANSFER</option><option>CASH</option></select></Field><Field label="Payment reference"><input className={inputClass} value={reference} onChange={e=>setReference(e.target.value)}/></Field><button disabled={busy||!reference.trim()||Number(amount)<=0||Number(amount)>item.balance_due} className={buttonClass} onClick={()=>onPay(item.id,Number(amount),method,reference)}>Record salary payment</button></div>}
    </>}
  </article>;
}

export default function AdminPayroll() {
  const action=useFinanceAction();
  const [month,setMonth]=useState(localToday().slice(0,7)),[mechanics,setMechanics]=useState<Mechanic[]>([]),[mechanicId,setMechanicId]=useState('');
  const [agreements,setAgreements]=useState<Agreement[]>([]),[advances,setAdvances]=useState<Advance[]>([]),[runs,setRuns]=useState<PayrollRun[]>([]),[run,setRun]=useState<PayrollRun|null>(null),[summary,setSummary]=useState<Summary|null>(null);
  const [effective,setEffective]=useState(localToday().slice(0,7)),[basic,setBasic]=useState(''),[allowances,setAllowances]=useState('0'),[overtimeRate,setOvertimeRate]=useState('0'),[divisor,setDivisor]=useState('26');
  const [attendance,setAttendance]=useState<Attendance[]>([]),[fillStatus,setFillStatus]=useState('PRESENT');
  const [advanceAmount,setAdvanceAmount]=useState(''),[advanceDate,setAdvanceDate]=useState(localToday()),[advanceReference,setAdvanceReference]=useState('');
  async function refresh() {
    const [m,a,v,r,s]=await Promise.all([financeApi.get<Mechanic[]>('/mechanics'),financeApi.get<Agreement[]>('/agreements'),financeApi.get<Advance[]>('/advances'),financeApi.get<PayrollRun[]>('/payroll'),financeApi.get<Summary>(`/summary?month=${month}`)]);
    setMechanics(m);setAgreements(a);setAdvances(v);setRuns(r);setSummary(s);
  }
  useEffect(()=>{void action.act(refresh,'');setRun(null);},[month]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(()=>{
    let active=true;setAttendance([]);
    if(mechanicId)void financeApi.get<Attendance[]>(`/attendance?month=${month}`).then(rows=>{if(active)setAttendance(rows.filter(r=>r.mechanic_id===Number(mechanicId)));}).catch(e=>{void action.act(async()=>{throw e;});});
    return()=>{active=false;};
  },[month,mechanicId]); // eslint-disable-line react-hooks/exhaustive-deps
  const [year,monthNumber]=month.split('-').map(Number);
  const days=Array.from({length:new Date(year,monthNumber,0).getDate()},(_,i)=>`${month}-${String(i+1).padStart(2,'0')}`);
  const monthRun=runs.find(r=>r.payroll_month.slice(0,7)===month);
  const locked=monthRun&&monthRun.status!=='DRAFT';
  function updateDay(date:string,patch:Partial<Attendance>) {
    setAttendance(rows=>{const old=rows.find(r=>r.work_date===date);const changed={mechanic_id:Number(mechanicId),work_date:date,status:old?.status??'',overtime_hours:old?.overtime_hours??0,approved:old?.approved??false,...patch};return [...rows.filter(r=>r.work_date!==date),changed];});
  }
  async function saveAttendance() {
    const entries=attendance.filter(r=>r.status&&r.work_date<=localToday()).map(r=>({mechanicId:Number(mechanicId),workDate:r.work_date,status:r.status,overtimeHours:Number(r.overtime_hours),approved:r.approved}));
    if(!entries.length)throw new Error('Record attendance first');
    await financeApi.post('/attendance/batch',{entries});
  }
  async function updateRun(path:string,body:Record<string,unknown>={}) { const r=await financeApi.post<PayrollRun>(path,body);setRun(r);await refresh(); }
  async function payslip(id:number) {
    const p=await financeApi.get<Payslip>(`/payroll-items/${id}/payslip`);const doc=new jsPDF();doc.setFontSize(20);doc.text('SERVIO PAYSLIP',14,20);doc.setFontSize(11);doc.text(`${p.mechanic_name} ? ${p.payroll_month.slice(0,7)}`,14,32);
    autoTable(doc,{startY:42,head:[['Component','Amount (LKR)']],body:[['Basic salary',currency(p.basic_salary)],['Allowances',currency(p.allowances)],['Overtime pay',currency(p.overtime_pay)],['Gross salary',currency(p.gross_salary)],['Unpaid leave deduction',currency(p.leave_deduction)],['Advance recovery',currency(p.advance_recovery)],['Other approved deductions',currency(p.other_deduction)],['Net payable',currency(p.net_payable)]]});
    autoTable(doc,{head:[['Paid date','Method','Amount','Reference']],body:p.payments.map(payment=>[String(payment.paid_at).slice(0,10),payment.method,currency(payment.amount),payment.reference])});
    doc.save(`Servio_Payslip_${p.mechanic_name}_${p.payroll_month.slice(0,7)}.pdf`);
  }
  return <div className="mx-auto max-w-7xl p-4 md:p-8 space-y-6">
    <div><h1 className="text-3xl font-bold">Mechanic payroll</h1><p className="mt-1 text-black/60">Calculate monthly salaries from agreements and attendance, then approve and record payments.</p></div>
    <Feedback error={action.error} message={action.message}/>
    <fieldset disabled={action.busy} className="space-y-6 min-w-0">
      <div className="grid gap-4 sm:grid-cols-2"><Field label="Payroll month"><input className={inputClass} type="month" value={month} onChange={e=>{if(e.target.value)setMonth(e.target.value);}}/></Field><Field label="Mechanic for salary settings and attendance"><select className={inputClass} value={mechanicId} onChange={e=>setMechanicId(e.target.value)}><option value="">Select a mechanic</option>{mechanics.map(m=><option key={m.id} value={m.id}>{m.full_name}{m.is_active?'':' (inactive)'}</option>)}</select></Field></div>
      {summary&&<Panel title="Monthly income and salary payments"><div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{([['Issued invoices',summary.invoiced],['Customer payments received',summary.collected],['Refunds recorded',summary.refunded],['Net salaries approved',summary.salaries_approved],['Salary payments made',summary.salaries_paid],['Salary advances paid',summary.advances_paid]] as [string,number][]).map(([label,value])=><div key={label} className="rounded-lg bg-[#fff7f5] p-3"><p className="text-sm text-black/60">{label}</p><p className="text-xl font-semibold">{currency(value)}</p></div>)}</div><p className="text-sm text-black/60">Invoices and approved salaries use the selected month; payments show money moved during that month. Salary advances are shown separately.</p></Panel>}
      <Panel title="Salary agreements"><p className="text-sm text-black/60">Agreements start on the first day of a month. Enter the agreed unpaid-leave divisor; paid leave does not reduce salary.</p>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5"><Field label="Effective month"><input className={inputClass} type="month" value={effective} onChange={e=>setEffective(e.target.value)}/></Field><Field label="Basic monthly salary"><input className={inputClass} type="number" min="0" step="0.01" value={basic} onChange={e=>setBasic(e.target.value)}/></Field><Field label="Monthly allowances"><input className={inputClass} type="number" min="0" step="0.01" value={allowances} onChange={e=>setAllowances(e.target.value)}/></Field><Field label="Overtime hourly rate"><input className={inputClass} type="number" min="0" step="0.01" value={overtimeRate} onChange={e=>setOvertimeRate(e.target.value)}/></Field><Field label="Unpaid-leave divisor (days)"><input className={inputClass} type="number" min="1" max="31" step="0.01" value={divisor} onChange={e=>setDivisor(e.target.value)}/></Field></div>
        <button disabled={!mechanicId||basic===''||!effective||Number(basic)<0||Number(allowances)<0||Number(overtimeRate)<0||Number(divisor)<1||Number(divisor)>31} className={buttonClass} onClick={()=>void action.act(async()=>{await financeApi.post('/agreements',{mechanicId:Number(mechanicId),effectiveFrom:`${effective}-01`,basicSalary:Number(basic),allowances:Number(allowances),overtimeRate:Number(overtimeRate),leaveDivisor:Number(divisor)});await refresh();},'Salary agreement saved')}>Save new agreement</button>
        <div className="overflow-x-auto"><table className="w-full text-sm text-left"><thead><tr><th>Mechanic</th><th>Effective</th><th>Basic</th><th>Allowances</th><th>OT / hour</th><th>Divisor</th></tr></thead><tbody>{agreements.filter(a=>!mechanicId||a.mechanic_id===Number(mechanicId)).map(a=><tr key={a.id} className="border-t"><td className="py-2">{a.full_name}</td><td>{a.effective_from}</td><td>{currency(a.basic_salary)}</td><td>{currency(a.allowances)}</td><td>{currency(a.overtime_rate)}</td><td>{a.leave_divisor}</td></tr>)}</tbody></table></div>
      </Panel>
      {mechanicId&&<Panel title={`Attendance ? ${month}`}><p className="text-sm text-black/60">Record every day, including off days. Only approved attendance enters payroll. Regenerate a draft after changing attendance.</p>
        {!locked&&<div className="flex flex-wrap gap-3"><select aria-label="Status for unrecorded days" className={inputClass+' max-w-xs'} value={fillStatus} onChange={e=>setFillStatus(e.target.value)}><option>PRESENT</option><option>OFF</option><option>PAID_LEAVE</option><option>UNPAID_LEAVE</option></select><button className={secondaryClass} onClick={()=>setAttendance(rows=>[...rows,...days.filter(date=>date<=localToday()&&!rows.some(r=>r.work_date===date)).map(date=>({mechanic_id:Number(mechanicId),work_date:date,status:fillStatus,overtime_hours:0,approved:false}))])}>Fill unrecorded days</button><button className={secondaryClass} onClick={()=>setAttendance(rows=>rows.map(r=>({...r,approved:true})))}>Approve recorded days</button></div>}
        <div className="max-h-96 overflow-auto"><table className="w-full text-sm text-left"><thead><tr><th>Date</th><th>Status</th><th>Overtime hours</th><th>Approved</th></tr></thead><tbody>{days.map(date=>{const row=attendance.find(r=>r.work_date===date);return <tr key={date} className="border-t"><td className="py-2 pr-3 whitespace-nowrap">{date}</td><td><select disabled={!!locked||date>localToday()} className={inputClass} value={row?.status??''} onChange={e=>updateDay(date,{status:e.target.value,overtime_hours:0})}><option value="" disabled={!!row?.status}>Not recorded</option><option>PRESENT</option><option>PAID_LEAVE</option><option>UNPAID_LEAVE</option><option>OFF</option></select></td><td><input aria-label={`Overtime ${date}`} disabled={!!locked||row?.status!=='PRESENT'} className={inputClass} type="number" min="0" max="24" step="0.25" value={row?.overtime_hours??0} onChange={e=>updateDay(date,{overtime_hours:Number(e.target.value)})}/></td><td className="text-center"><input aria-label={`Approve ${date}`} disabled={!!locked||!row?.status} type="checkbox" checked={row?.approved??false} onChange={e=>updateDay(date,{approved:e.target.checked})}/></td></tr>;})}</tbody></table></div>
        <button disabled={!!locked} className={buttonClass} onClick={()=>void action.act(saveAttendance,'Attendance saved')}>Save attendance</button>
      </Panel>}
      <Panel title="Salary advances"><div className="grid gap-3 md:grid-cols-4 items-end"><Field label="Amount already paid"><input className={inputClass} type="number" min="0.01" step="0.01" value={advanceAmount} onChange={e=>setAdvanceAmount(e.target.value)}/></Field><Field label="Paid date"><input className={inputClass} type="date" max={localToday()} value={advanceDate} onChange={e=>setAdvanceDate(e.target.value)}/></Field><Field label="Payment reference"><input className={inputClass} value={advanceReference} onChange={e=>setAdvanceReference(e.target.value)}/></Field><button disabled={!mechanicId||Number(advanceAmount)<=0||!advanceReference.trim()} className={buttonClass} onClick={()=>void action.act(async()=>{await financeApi.post('/advances',{mechanicId:Number(mechanicId),amount:Number(advanceAmount),paidDate:advanceDate,reference:advanceReference});setAdvanceAmount('');setAdvanceReference('');await refresh();},'Advance recorded')}>Record advance</button></div>
        {advances.filter(a=>!mechanicId||a.mechanic_id===Number(mechanicId)).map(a=><p key={a.id} className="text-sm">{a.full_name} ? {a.paid_date} ? Paid {currency(a.amount)} ? Remaining recovery {currency(a.remaining)} ? {a.reference}</p>)}
      </Panel>
      <Panel title="Monthly payroll"><div className="flex flex-wrap gap-3"><button disabled={!!locked} className={buttonClass} onClick={()=>void action.act(()=>updateRun('/payroll',{month}),'Draft calculated; review deductions before approval')}>{monthRun?'Regenerate draft':'Generate draft'}</button>{monthRun&&<button className={secondaryClass} onClick={()=>void action.act(async()=>setRun(await financeApi.get<PayrollRun>(`/payroll/${monthRun.id}`)),'')}>Open {monthRun.status.toLowerCase()} payroll</button>}</div><p className="text-sm text-black/60">Generating again resets draft adjustments. Approval freezes the monthly salary breakdown and requires complete approved attendance.</p>
        {run&&<><p className="font-semibold">{run.payroll_month.slice(0,7)} ? {run.status}</p>{run.items?.map(item=><PayrollRow key={`${item.id}-${item.net_payable}-${item.paid_amount}`} item={item} run={run} busy={action.busy} onAdjust={(id,advanceRecovery,otherDeduction,reason)=>void action.act(()=>updateRun(`/payroll-items/${id}/adjust`,{advanceRecovery,otherDeduction,reason}),'Adjustment saved')} onPay={(id,amount,method,reference)=>void action.act(()=>updateRun(`/payroll-items/${id}/payments`,{amount,method,reference}),'Salary payment recorded')} onPayslip={id=>void action.act(()=>payslip(id),'Payslip downloaded')}/>)}{run.status==='DRAFT'&&<button className={buttonClass} onClick={()=>void action.act(()=>updateRun(`/payroll/${run.id}/approve`),'Payroll approved')}>Approve monthly payroll</button>}</>}
      </Panel>
    </fieldset>
  </div>;
}
