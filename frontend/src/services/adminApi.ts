// Admin API Service
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class AdminApiService {
  private getHeaders(): HeadersInit {
    const token = localStorage.getItem('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': token ? `Bearer ${token}` : '',
    };
  }

  async getAllServices() {
    const response = await fetch(`${API_BASE_URL}/admin/services`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async toggleServiceStatus(id: number, isActive: boolean) {
    const response = await fetch(`${API_BASE_URL}/admin/services/${id}/toggle`, {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: JSON.stringify({ isActive }),
    });
    return response.json();
  }

  async getAllOffers() {
    const response = await fetch(`${API_BASE_URL}/admin/offers`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async getAllAppointments(status?: string) {
    const url = status ? `${API_BASE_URL}/admin/appointments?status=${status}` : `${API_BASE_URL}/admin/appointments`;
    const response = await fetch(url, { headers: this.getHeaders() });
    return response.json();
  }

  async getAllCustomers() {
    const response = await fetch(`${API_BASE_URL}/admin/customers`, {
      headers: this.getHeaders(),
    });
    return response.json();
  }
}

export const adminApi = new AdminApiService();
