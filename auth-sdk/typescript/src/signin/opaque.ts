import * as opaque from "react-native-opaque";
import { AxiosInstance } from "axios";
import { OPAQUE_SERVER_IDENTITY } from "../config";
import { TokenManager } from "../token-manager";

export class OpaqueSignIn {
  constructor(
    private api: AxiosInstance,
    private tokenManager: TokenManager,
    private platform: string,
  ) {}

  async signIn(username: string, password: string, turnstileToken: string) {
    try {
      await opaque.ready;

      const { clientLoginState, startLoginRequest } = opaque.client.startLogin({
        password,
      });

      const challengeRes = await this.api.post(
        `/signin/opaque/challenge`,
        { username, ke1: startLoginRequest, turnstileToken },
        { withCredentials: true },
      );

      const challengeData = challengeRes.data;
      const challengeId = challengeData.challengeId;
      const ke2 = challengeData.ke2;

      if (!ke2) throw new Error("(KE2) missing response from server");

      const finishLoginResult = opaque.client.finishLogin({
        clientLoginState,
        loginResponse: ke2,
        password,
        identifiers: { server: OPAQUE_SERVER_IDENTITY },
      });

      if (!finishLoginResult) throw new Error("Failed to finish login");

      const { finishLoginRequest } = finishLoginResult;

      const completeRes = await this.api.post(
        `/signin/opaque/complete`,
        { challengeId, ke3: finishLoginRequest },
        {
          withCredentials: true,
          headers: { "x-platform": this.platform },
        },
      );

      const completeData = completeRes.data;

      if (completeData.requires2FA) {
        return {
          success: true,
          requires2FA: true,
          twoFactorToken: completeData.twoFactorToken,
        };
      } else {
        this.tokenManager.setCurrentToken(completeData.token);
        return { success: true, requires2FA: false, data: completeData };
      }
    } catch (err: any) {
      console.error("Signin OPAQUE error:", err);
      return { success: false, error: err.message };
    }
  }
}
