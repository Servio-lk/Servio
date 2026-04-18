import { apiFetch } from './apiFetch';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export interface BillItemRequest {
  inventoryItemId?: number;
  description: string;
  quantity: number;
  rate: number;
  amount: number;
}

export interface BillRequest {
  customerName: string;
  customerAddress: string;
  customerPhone: string;
  vehicleType: string;
  vehicleNo: string;
  paymentMode: string;
  subTotal: number;
  discount: number;
  netTotal: number;
  currentMeterReading?: string;
  nextServiceDue?: string;
  items: BillItemRequest[];
}

class BillingApiService {
  private getHeaders(): Record<string, string> {
    const token = localStorage.getItem('token');
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  async createBill(payload: BillRequest) {
    const response = await apiFetch(`${API_BASE_URL}/admin/bills`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || 'Failed to create bill');
    }
    return data;
  }

  async getAllBills() {
    const response = await apiFetch(`${API_BASE_URL}/admin/bills`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getBillById(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/bills/${id}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return response.json();
  }
}

export const billingApi = new BillingApiService();
