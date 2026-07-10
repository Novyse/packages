import { AxiosInstance } from "axios";

export interface StorageAdapter {
  getItem: (key: string) => Promise<string | null>;
  setItem: (key: string, value: string) => Promise<void>;
  removeItem: (key: string) => Promise<void>;
}

export class TokenManager {
  private currentToken: string | null = null;
  private currentTokenExpiry = 0;
  private tokenRequestPromise: Promise<string | null> | null = null;
  public onInvalidSession?: () => void;

  constructor(
    private api: AxiosInstance,
    private platform: string,
    private storage?: StorageAdapter,
  ) {}

  setCurrentToken(token: string | null) {
    this.currentToken = token;
    this.currentTokenExpiry = Date.now() + 15 * 60 * 1000;
  }

  async fetchToken(): Promise<string | null> {
    try {
      const headers: Record<string, string> = {
        "x-platform": this.platform,
      };

      if (this.platform !== "web" && this.storage) {
        const sessionId = await this.storage.getItem("sessionId");
        if (sessionId) {
          headers["x-session-id"] = sessionId;
        }
      }

      const response = await this.api.post("/token", null, {
        headers,
        withCredentials: true,
      });

      if (response.data.success) {
        if (
          this.platform !== "web" &&
          this.storage &&
          response.data.sessionId
        ) {
          await this.storage.setItem(
            "sessionId",
            String(response.data.sessionId),
          );
        }
        return response.data.token;
      }
      return null;
    } catch (error) {
      console.error("Error fetching token:", error);
      throw error;
    }
  }

  async getAuthToken(): Promise<string | null> {
    if (this.currentToken && Date.now() < this.currentTokenExpiry - 10000) {
      return this.currentToken;
    }

    if (this.tokenRequestPromise) {
      return this.tokenRequestPromise;
    }

    this.tokenRequestPromise = (async () => {
      try {
        const token = await this.fetchToken();
        if (token) {
          this.currentToken = token;
          this.currentTokenExpiry = Date.now() + 15 * 60 * 1000;
        } else {
          this.currentToken = null;
          this.currentTokenExpiry = 0;
          if (this.onInvalidSession) this.onInvalidSession();
        }
        return this.currentToken;
      } catch (error: any) {
        if (error.response && error.response.status === 401) {
          this.currentToken = null;
          this.currentTokenExpiry = 0;
          if (this.onInvalidSession) this.onInvalidSession();
        }
        return this.currentToken;
      } finally {
        this.tokenRequestPromise = null;
      }
    })();

    return this.tokenRequestPromise;
  }

  clearAuthToken() {
    this.currentToken = null;
    this.currentTokenExpiry = 0;
  }
}
