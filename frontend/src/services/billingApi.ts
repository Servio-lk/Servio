import { financeApi } from './financeApi';
import type { Invoice } from './financeApi';
export interface BillRequest { jobCardId:number; discount:number; }
export const billingApi={
  createBill:async(payload:BillRequest)=>({success:true,data:await financeApi.post<Invoice>('/invoices',payload as unknown as Record<string,unknown>)}),
  getAllBills:async()=>({success:true,data:await financeApi.get<Invoice[]>('/invoices')}),
  getBillById:async(id:number)=>({success:true,data:await financeApi.get<Invoice>(`/invoices/${id}`)}),
};
