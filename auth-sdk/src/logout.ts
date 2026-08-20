import { AxiosInstance } from "axios";

export class Logout {
  constructor(private api: AxiosInstance) {}

  async logout(): Promise<boolean> {
    try {
      const response = await this.api.post("/logout", null, {
        withCredentials: true,
      });

      return !!response.data.success;
    } catch (error) {
      console.error("Error logging out:", error);
      return false;
    }
  }
}
