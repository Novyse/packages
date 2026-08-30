import { AxiosInstance } from "axios";
import { TokenManager } from "../token-manager";

export class SessionSettings {
  constructor(
    private api: AxiosInstance,
    private tokenManager: TokenManager,
  ) {}

  async getCurrent() {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.get(`/session`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return { success: true, data: response.data.session };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  async list() {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.get(`/session/list`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return { success: true, data: response.data.sessions };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  async revoke(sessionID: number) {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.post(
        `/session/revoke`,
        { id: sessionID },
        {
          headers: { Authorization: `Bearer ${token}` },
        },
      );
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  async revokeOther() {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.post(
        `/session/revokeOther`,
        {},
        {
          headers: { Authorization: `Bearer ${token}` },
        },
      );
      return { success: true, data: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }
}
