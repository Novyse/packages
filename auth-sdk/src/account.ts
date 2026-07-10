import { AxiosInstance } from "axios";
import { TokenManager } from "./token-manager";

export class Account {
  constructor(
    private api: AxiosInstance,
    private tokenManager: TokenManager,
  ) {}

  async deleteAccount(): Promise<boolean> {
    try {
      const token = await this.tokenManager.getAuthToken();
      const response = await this.api.delete("/account", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      return !!(response.data && response.data.success);
    } catch (error) {
      console.error("Error deleting account:", error);
      return false;
    }
  }
}
