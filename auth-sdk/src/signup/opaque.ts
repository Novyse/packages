import * as opaque from "react-native-opaque";
import { AxiosInstance } from "axios";
import { OPAQUE_SERVER_IDENTITY } from "../config";

export class OpaqueSignUp {
  constructor(private api: AxiosInstance) {}

  async signUp(
    username: string,
    password: string,
    name: string,
    gdpr: { tos: boolean; privacy: boolean; isOver16: boolean },
    turnstileToken: string,
  ) {
    try {
      await opaque.ready;

      const { clientRegistrationState, registrationRequest } =
        opaque.client.startRegistration({ password });

      const challengeRes = await this.api.post(
        `/signup/opaque/challenge`,
        { username, registrationRequest, turnstileToken },
        { withCredentials: true },
      );

      const challengeData = challengeRes.data;
      const signupId = challengeData.signupId;
      const registrationResponse = challengeData.registrationResponse;

      if (!registrationResponse) {
        throw new Error("Registration response missing from server");
      }

      const { registrationRecord } = opaque.client.finishRegistration({
        password,
        clientRegistrationState,
        registrationResponse,
        identifiers: { server: OPAQUE_SERVER_IDENTITY },
      });

      const completeRes = await this.api.post(
        `/signup/opaque/complete`,
        {
          signupId,
          username,
          name,
          registrationRecord,
          privacyPolicyAccepted: gdpr.privacy,
          termsOfServiceAccepted: gdpr.tos,
          isOver16: gdpr.isOver16,
        },
        { withCredentials: true },
      );

      return { success: true, data: completeRes.data };
    } catch (err: any) {
      console.error("Signup OPAQUE error:", err);
      return { success: false, error: err.message };
    }
  }
}
