import { apiFetch } from './apiFetch';

const getApiBaseUrl = () => {
  let envApi = import.meta.env.VITE_API_URL;

  // Ignore hardcoded localhost env vars if we are deployed on a real domain
  const isLocalEnvApi = envApi && (envApi.includes('localhost') || envApi.includes('127.0.0.1'));
  const isLocalHost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
  
  if (isLocalEnvApi && !isLocalHost) {
    envApi = undefined;
  } else if (envApi && envApi.startsWith('http://') && window.location.protocol === 'https:') {
    envApi = undefined;
  }

  if (envApi) return envApi;

  const host = window.location.hostname;
  if (host === 'localhost' || host === '127.0.0.1') {
    return `http://${host}:3001/api`;
  }

  return `${window.location.origin}/api`;
};

const API_BASE_URL = getApiBaseUrl();

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

  async getDashboardStats() {
    const response = await apiFetch(`${API_BASE_URL}/admin/dashboard`, {
      headers: this.getHeaders(),
    });
    return response.json();
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

  async createService(payload: Record<string, unknown>) {
    const response = await apiFetch(`${API_BASE_URL}/admin/services`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    return response.json();
  }

  async updateService(id: number, payload: Record<string, unknown>) {
    const response = await apiFetch(`${API_BASE_URL}/admin/services/${id}`, {
      method: 'PUT',
      headers: this.getHeaders(),
      body: JSON.stringify(payload),
    });
    return response.json();
  }

  async publishService(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/services/${id}/publish`, {
      method: 'PATCH',
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async hideService(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/services/${id}/hide`, {
      method: 'PATCH',
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async deleteService(id: number) {
    const response = await apiFetch(`${API_BASE_URL}/admin/services/${id}`, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });
    return response.json();
  }

  async uploadServicePhoto(file: File) {
    const token = localStorage.getItem('token');
    const headers: Record<string, string> = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const body = new FormData();
    body.append('file', file);

    const response = await apiFetch(`${API_BASE_URL}/admin/services/photos/upload`, {
      method: 'POST',
      headers,
      body,
    });
    return response.json();
  }

  async uploadServiceIcon(file: File) {
    const token = localStorage.getItem('token');
    const headers: Record<string, string> = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const body = new FormData();
    body.append('file', file);

    const response = await apiFetch(`${API_BASE_URL}/admin/services/icons/upload`, {
      method: 'POST',
      headers,
      body,
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

  async recordPayment(id: number, amount: number, paymentMethod: string) {
    const response = await apiFetch(`${API_BASE_URL}/admin/appointments/${id}/payments`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({ amount, paymentMethod }),
    });
    return response.json();
  }
}

export const adminApi = new AdminApiService();
