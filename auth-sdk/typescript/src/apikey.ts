import { AxiosInstance } from "axios";
import { TokenManager } from "./token-manager";

export class ApiKey {
  constructor(
    private api: AxiosInstance,
    private tokenManager: TokenManager,
  ) {}

  async list() {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.get(`/apikey`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  async create(
    name: string,
    permissions: object = {},
    expiresIn: string | number = -1,
  ) {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.post(
        `/apikey`,
        { name, permissions, expiresIn },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  async toggleActive(id: number, active: boolean) {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.patch(
        `/apikey/${id}`,
        { active },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  async revoke(id: number) {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.delete(`/apikey/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }
}
