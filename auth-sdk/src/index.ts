import { AxiosInstance } from "axios";
import { createAuthApi } from "./config";
import { OpaqueSettings } from "./settings/opaque";
import { SessionSettings } from "./settings/session";
import { OpaqueSignIn } from "./signin/opaque";
import { OpaqueSignUp } from "./signup/opaque";
import { Account } from "./account";
import { ApiKey } from "./apikey";
import { Logout } from "./logout";
import { QrCode } from "./qrcode";
import { TokenManager, StorageAdapter } from "./token-manager";

export type Branch = "development" | "preview" | "production";

export interface NovyseAuthOptions {
  platform: "mobile" | "desktop" | "web";
  branch?: Branch;
  storageAdapter?: StorageAdapter;
}

export class NovyseAuth {
  public api: AxiosInstance;
  public tokenManager: TokenManager;

  public signin: { opaque: OpaqueSignIn["signIn"] };
  public signup: { opaque: OpaqueSignUp["signUp"] };
  public settings: {
    opaque: OpaqueSettings["setup"];
    session: SessionSettings;
  };
  public account: { delete: Account["deleteAccount"] };
  public apikey: ApiKey;
  public qrcode: QrCode;
  public logout: Logout["logout"];

  constructor(options: NovyseAuthOptions) {
    const branch = options.branch || "production";
    const platform = options.platform;

    this.api = createAuthApi(branch);
    this.tokenManager = new TokenManager(
      this.api,
      platform,
      options.storageAdapter,
    );

    const signinOpaque = new OpaqueSignIn(
      this.api,
      this.tokenManager,
      platform,
    );
    this.signin = { opaque: signinOpaque.signIn.bind(signinOpaque) };

    const signupOpaque = new OpaqueSignUp(this.api);
    this.signup = { opaque: signupOpaque.signUp.bind(signupOpaque) };

    const settingsOpaque = new OpaqueSettings(this.api, this.tokenManager);
    this.settings = {
      opaque: settingsOpaque.setup.bind(settingsOpaque),
      session: new SessionSettings(this.api, this.tokenManager),
    };

    const account = new Account(this.api, this.tokenManager);
    this.account = { delete: account.deleteAccount.bind(account) };

    this.apikey = new ApiKey(this.api, this.tokenManager);
    this.qrcode = new QrCode(this.api, this.tokenManager, platform);

    const logoutInstance = new Logout(this.api);
    this.logout = logoutInstance.logout.bind(logoutInstance);
  }
}

export { TokenManager, StorageAdapter };
