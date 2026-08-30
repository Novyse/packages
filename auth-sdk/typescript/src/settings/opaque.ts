import { AxiosInstance } from "axios";
import * as opaqueLib from "react-native-opaque";
import { OPAQUE_SERVER_IDENTITY } from "../config";
import { TokenManager } from "../token-manager";

export class OpaqueSettings {
  constructor(
    private api: AxiosInstance,
    private tokenManager: TokenManager,
  ) {}

  async setup(password: string) {
    try {
      const token = await this.tokenManager.getAuthToken();
      await opaqueLib.ready;

      const { clientRegistrationState, registrationRequest } =
        opaqueLib.client.startRegistration({ password });

      const challengeRes = await this.api.post(
        `/settings/opaque/setup/challenge`,
        { registrationRequest },
        { headers: { Authorization: `Bearer ${token}` } },
      );

      const registrationResponse = challengeRes.data.registrationResponse;
      if (!registrationResponse)
        throw new Error("Registration response missing");

      const { registrationRecord } = opaqueLib.client.finishRegistration({
        password,
        clientRegistrationState,
        registrationResponse,
        identifiers: { server: OPAQUE_SERVER_IDENTITY },
      });

      const completeRes = await this.api.post(
        `/settings/opaque/setup/complete`,
        { registrationRecord },
        { headers: { Authorization: `Bearer ${token}` } },
      );

      return { success: true, data: completeRes.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || error.message,
      };
    }
  }
}
