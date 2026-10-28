import { apiFetch } from './apiFetch';
import { API_BASE_URL } from './api';
export interface Job { id:number; job_number:string; service_type:string; estimated_cost:number|null; actual_cost:number|null; appointment_id:number }
export interface Charge { id:number; description:string; quantity:number; rate:number; amount:number; inventory_item_id:number|null }
export interface InvoiceItem { id:number; description:string; quantity:number; rate:number; amount:number }
export interface InvoicePayment { id:number; amount:number; allocated_amount:number; payment_method:string; payment_date:string; transaction_id:string|null }
export interface InvoiceRefund { id:number; payment_id:number; amount:number; reason:string; reference:string }
export interface Invoice { id:number; invoice_no:string; date:string; customer_name:string; customer_phone:string; vehicle_no:string; currency:string; status:string; sub_total:number; discount:number; net_total:number; paid_amount:number; balance_due:number; settlement_status?:string; job_card_id:number|null; items?:InvoiceItem[]; payments?:InvoicePayment[]; refunds?:InvoiceRefund[] }
export interface Mechanic { id:number; full_name:string; is_active:boolean }
export interface Agreement { id:number; mechanic_id:number; full_name:string; effective_from:string; basic_salary:number; allowances:number; overtime_rate:number; leave_divisor:number }
export interface Attendance { mechanic_id:number; work_date:string; status:string; overtime_hours:number; approved:boolean }
export interface Advance { id:number; mechanic_id:number; full_name:string; amount:number; remaining:number; paid_date:string; reference:string }
export interface PayrollItem { id:number; mechanic_id:number; mechanic_name:string; basic_salary:number; allowances:number; overtime_hours:number; overtime_rate:number; overtime_pay:number; unpaid_days:number; leave_divisor:number; leave_deduction:number; gross_salary:number; advance_recovery:number; other_deduction:number; adjustment_reason:string|null; net_payable:number; paid_amount:number; balance_due:number }
export interface PayrollRun { id:number; payroll_month:string; status:string; items?:PayrollItem[] }
export interface SalaryPayment { amount:number; method:string; reference:string; paid_at:string }
export interface Payslip extends PayrollItem { payroll_month:string; payroll_status:string; payments:SalaryPayment[] }
export interface Summary { invoiced:number; collected:number; refunded:number; salaries_approved:number; salaries_paid:number; advances_paid:number }

async function request<T>(path:string, method='GET', body?:unknown):Promise<T> {
  const response=await apiFetch(`${API_BASE_URL}${path}`, {method, headers:{'Content-Type':'application/json'}, ...(body===undefined?{}:{body:JSON.stringify(body)})});
  const result=await response.json();
  if(!response.ok || result.success===false) throw new Error(result.message || 'Request failed');
  return result.data as T;
}
export const financeApi={
  resource:<T>(path:string)=>request<T>(path),
  get:<T>(path:string)=>request<T>(`/admin/finance${path}`),
  post:<T>(path:string, body:Record<string,unknown>={})=>{
    // Retain the key through ambiguous network failures; clear only after success.
    const signature=`servio.finance:${path}:${JSON.stringify(body)}`;
    let key=sessionStorage.getItem(signature);
    if(!key) { key=globalThis.crypto.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`; sessionStorage.setItem(signature,key); }
    return request<T>(`/admin/finance${path}`,'POST',{...body,requestKey:key}).then(data=>{sessionStorage.removeItem(signature);return data;});
  },
  inventory:()=>request<{id:number;name:string;currentStock:number;sellingPricePerUnit:number}[]>('/admin/inventory'),
};
export const currency=(value:number)=>`Rs. ${Number(value??0).toLocaleString('en-LK',{minimumFractionDigits:2,maximumFractionDigits:2})}`;
export const localToday=()=>{ const d=new Date(); return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`; };
