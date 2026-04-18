import { apiFetch } from './apiFetch';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export interface InventoryItem {
  id: number;
  name: string;
  category: string;
  unit: string;
  currentStock: number;
  minimumStock: number;
  costPerUnit: number;
  sellingPricePerUnit: number;
  serviceType?: string;
  lowStock: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface InventoryItemRequest {
  name: string;
  category: string;
  unit: string;
  currentStock: number;
  minimumStock: number;
  costPerUnit: number;
  sellingPricePerUnit: number;
  serviceType?: string;
}

export interface StockTransaction {
  id: number;
  inventoryItemId: number;
  itemName: string;
  type: 'RECEIVE' | 'CONSUME' | 'ADJUST';
  quantity: number;
  notes?: string;
  performedBy: string;
  createdAt: string;
}

export interface StockUpdateRequest {
  type: 'RECEIVE' | 'CONSUME' | 'ADJUST';
  quantity: number;
  notes?: string;
}

class InventoryApiService {
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

  async getAllItems() {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getLowStockItems() {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory/low-stock`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getItemById(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory/${id}`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getTransactionHistory(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory/${id}/transactions`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async createItem(payload: InventoryItemRequest) {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    return response.json();
  }

  async updateItem(id: number, payload: InventoryItemRequest) {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory/${id}`, {
      method: 'PUT',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    return response.json();
  }

  async deleteItem(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory/${id}`, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async updateStock(id: number, payload: StockUpdateRequest) {
    const response = await apiFetch(`${API_BASE_URL}/admin/inventory/${id}/stock`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    return response.json();
  }
}

export const inventoryApi = new InventoryApiService();
