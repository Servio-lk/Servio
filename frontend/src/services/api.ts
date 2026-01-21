// Dynamically determine API URL based on current host
const getApiBaseUrl = () => {
  // If environment variable is set, use it
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  
  // For local development and mobile access, use the same host but different port
  const host = window.location.hostname;
  return `http://${host}:8080/api`;
};

const API_BASE_URL = getApiBaseUrl();

interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: Array<{ field: string; message: string }>;
}

interface SignupData {
  fullName: string;
  email: string;
  phone: string;
  password: string;
}

interface LoginData {
  email: string;
  password: string;
}

interface User {
  id: number;
  fullName: string;
  email: string;
  phone: string | null;
  role: string;
  createdAt: string;
}

interface AuthResponse {
  user: User;
  token: string;
}

interface ServiceCategory {
  id: number;
  name: string;
  description: string;
  services: ServiceItem[];
}

interface ServiceItem {
  id: number;
  categoryId: number;
  categoryName: string;
  name: string;
  description: string;
  basePrice: number | null;
  priceRange: string;
  durationMinutes: number | null;
  imageUrl: string | null;
  isFeatured: boolean;
  options?: ServiceOption[];
}

interface ServiceOption {
  id: number;
  name: string;
  description: string;
  priceAdjustment: number;
  isDefault: boolean;
}

interface ServiceProvider {
  id: number;
  name: string;
  address: string;
  city: string;
  phone: string;
  rating: number;
}

interface Offer {
  id: number;
  title: string;
  subtitle: string;
  description: string;
  discountType: string;
  discountValue: number;
  imageUrl: string | null;
  validUntil: string;
}

interface AppointmentRequest {
  userId: number;
  vehicleId?: number | null;
  serviceType: string;
  appointmentDate: string; // ISO datetime string
  location?: string;
  notes?: string;
  estimatedCost?: number;
}

interface VehicleDto {
  id: number;
  make: string;
  model: string;
  year: number;
  licensePlate: string;
  vin: string | null;
}

interface AppointmentDto {
  id: number;
  userId: number;
  vehicleId: number | null;
  serviceType: string;
  appointmentDate: string;
  status: 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
  location: string | null;
  notes: string | null;
  estimatedCost: number | null;
  actualCost: number | null;
  createdAt: string;
  updatedAt: string;
  user?: {
    id: number;
    fullName: string;
    email: string;
    phone: string;
  };
  vehicle?: VehicleDto;
}

class ApiService {
  private getHeaders(includeAuth = false): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      const token = localStorage.getItem('token');
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    return headers;
  }

  private async handleResponse<T>(response: Response): Promise<ApiResponse<T>> {
    const data = await response.json();
    
    if (!response.ok) {
      throw data;
    }

    return data;
  }

  // Authentication endpoints
  async signup(userData: SignupData): Promise<ApiResponse<AuthResponse>> {
    const response = await fetch(`${API_BASE_URL}/auth/signup`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(userData),
    });

    const data = await this.handleResponse<AuthResponse>(response);
    
    if (data.success && data.data?.token) {
      localStorage.setItem('token', data.data.token);
      localStorage.setItem('user', JSON.stringify(data.data.user));
    }

    return data;
  }

  async login(credentials: LoginData): Promise<ApiResponse<AuthResponse>> {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(credentials),
    });

    const data = await this.handleResponse<AuthResponse>(response);
    
    if (data.success && data.data?.token) {
      localStorage.setItem('token', data.data.token);
      localStorage.setItem('user', JSON.stringify(data.data.user));
    }

    return data;
  }

  async getProfile(): Promise<ApiResponse<User>> {
    const response = await fetch(`${API_BASE_URL}/auth/profile`, {
      method: 'GET',
      headers: this.getHeaders(true),
    });

    return this.handleResponse<User>(response);
  }

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  }

  isAuthenticated(): boolean {
    return !!localStorage.getItem('token');
  }

  getCurrentUser(): User | null {
    const userStr = localStorage.getItem('user');
    return userStr ? JSON.parse(userStr) : null;
  }

  // Service endpoints
  async getServiceCategories(): Promise<ApiResponse<ServiceCategory[]>> {
    const response = await fetch(`${API_BASE_URL}/services/categories`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<ServiceCategory[]>(response);
  }

  async getAllServices(): Promise<ApiResponse<ServiceItem[]>> {
    const response = await fetch(`${API_BASE_URL}/services`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<ServiceItem[]>(response);
  }

  async getFeaturedServices(): Promise<ApiResponse<ServiceItem[]>> {
    const response = await fetch(`${API_BASE_URL}/services/featured`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<ServiceItem[]>(response);
  }

  async getServiceById(id: number): Promise<ApiResponse<ServiceItem>> {
    const response = await fetch(`${API_BASE_URL}/services/${id}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<ServiceItem>(response);
  }

  async searchServices(query: string): Promise<ApiResponse<ServiceItem[]>> {
    const response = await fetch(`${API_BASE_URL}/services/search?q=${encodeURIComponent(query)}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<ServiceItem[]>(response);
  }

  async getServiceProviders(): Promise<ApiResponse<ServiceProvider[]>> {
    const response = await fetch(`${API_BASE_URL}/services/providers`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<ServiceProvider[]>(response);
  }

  async getActiveOffers(): Promise<ApiResponse<Offer[]>> {
    const response = await fetch(`${API_BASE_URL}/services/offers`, {
      method: 'GET',
      headers: this.getHeaders(),
    });
    return this.handleResponse<Offer[]>(response);
  }

  // Appointment endpoints
  async createAppointment(appointmentData: AppointmentRequest): Promise<ApiResponse<AppointmentDto>> {
    const response = await fetch(`${API_BASE_URL}/appointments`, {
      method: 'POST',
      headers: this.getHeaders(true),
      body: JSON.stringify(appointmentData),
    });
    return this.handleResponse<AppointmentDto>(response);
  }

  async getAppointmentById(id: number): Promise<ApiResponse<AppointmentDto>> {
    const response = await fetch(`${API_BASE_URL}/appointments/${id}`, {
      method: 'GET',
      headers: this.getHeaders(true),
    });
    return this.handleResponse<AppointmentDto>(response);
  }

  async getUserAppointments(): Promise<ApiResponse<AppointmentDto[]>> {
    const user = this.getCurrentUser();
    if (!user) {
      throw new Error('User not authenticated');
    }
    
    const response = await fetch(`${API_BASE_URL}/appointments`, {
      method: 'GET',
      headers: this.getHeaders(true),
    });
    
    const data = await this.handleResponse<AppointmentDto[]>(response);
    
    // Filter appointments by current user (backend returns all, so we filter client-side)
    if (data.success && data.data) {
      data.data = data.data.filter(apt => apt.userId === user.id);
    }
    
    return data;
  }

  async updateAppointmentStatus(id: number, status: string): Promise<ApiResponse<AppointmentDto>> {
    const response = await fetch(`${API_BASE_URL}/appointments/${id}/status?status=${encodeURIComponent(status)}`, {
      method: 'PUT',
      headers: this.getHeaders(true),
    });
    return this.handleResponse<AppointmentDto>(response);
  }
}

export const apiService = new ApiService();
export type { 
  User, 
  SignupData, 
  LoginData, 
  AuthResponse, 
  ApiResponse,
  ServiceCategory,
  ServiceItem,
  ServiceOption,
  ServiceProvider,
  Offer,
  AppointmentRequest,
  AppointmentDto,
  VehicleDto
};
