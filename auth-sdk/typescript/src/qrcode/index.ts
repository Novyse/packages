import { AxiosInstance } from "axios";
import { TokenManager } from "../token-manager";

export class QrCode {
  constructor(
    private api: AxiosInstance,
    private tokenManager: TokenManager,
    private platform: string,
  ) {}

  async new() {
    try {
      const response = await this.api.post("/signin/qrcode/new");
      return { success: true, data: response.data };
    } catch (err: any) {
      return {
        success: false,
        error: err.response?.data?.message || err.message,
      };
    }
  }

  async status(token: string) {
    try {
      const response = await this.api.get(`/signin/qrcode/status/${token}`, {
        headers: { "x-platform": this.platform },
        withCredentials: true,
      });
      return { success: true, data: response.data };
    } catch (err: any) {
      return {
        success: false,
        error: err.response?.data?.message || err.message,
      };
    }
  }

  async authenticate(token: string) {
    try {
      const userJwt = await this.tokenManager.getAuthToken();
      const response = await this.api.post(
        `/signin/qrcode/authenticate/${token}`,
        {},
        { headers: { Authorization: `Bearer ${userJwt}` } },
      );
      return { success: true, data: response.data };
    } catch (err: any) {
      return {
        success: false,
        error: err.response?.data?.message || err.message,
      };
    }
  }
}
