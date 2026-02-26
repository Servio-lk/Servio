// Admin API Service — all endpoints require auth, so all calls go through apiFetch()
import { apiFetch } from './apiFetch';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class AdminApiService {
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

  async getAllServices() {
    const response = await apiFetch(`${API_BASE_URL}/admin/services`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async toggleServiceStatus(id: number, isActive: boolean) {
    const response = await apiFetch(`${API_BASE_URL}/admin/services/${id}/toggle`, {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: JSON.stringify({ isActive }),
    });
    return response.json();
  }

  async getAllOffers() {
    const response = await apiFetch(`${API_BASE_URL}/admin/offers`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getAllAppointments(status?: string) {
    const url = status
      ? `${API_BASE_URL}/admin/appointments?status=${status}`
      : `${API_BASE_URL}/admin/appointments`;
    const response = await apiFetch(url, { headers: this.getHeaders() });
    return response.json();
  }

  async getAllCustomers() {
    const response = await apiFetch(`${API_BASE_URL}/admin/customers`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getCustomerDetails(id: string) {
    const response = await apiFetch(`${API_BASE_URL}/admin/customers/${id}/details`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getWalkInCustomers() {
    const response = await apiFetch(`${API_BASE_URL}/admin/walk-in-customers`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async createWalkInCustomer(payload: Record<string, unknown>) {
    const response = await apiFetch(`${API_BASE_URL}/admin/walk-in-customers`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    return response.json();
  }

  async updateAppointmentStatus(id: number, status: string) {
    const response = await apiFetch(`${API_BASE_URL}/appointments/${id}/status?status=${status}`, {
      method: 'PATCH',
      headers: this.getHeaders(),
    });
    return response.json();
  }
}

export const adminApi = new AdminApiService();
