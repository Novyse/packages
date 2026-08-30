import axios, { AxiosInstance } from "axios";

export const OPAQUE_SERVER_IDENTITY = "novyse-auth-service";

export const getAuthDomain = (branch: string) => {
  const suffix =
    branch === "production" ? "" : branch === "preview" ? ".preview" : ".dev";
  return `auth${suffix}.novyse.com`;
};

export const createAuthApi = (branch: string): AxiosInstance => {
  const baseURL = `https://${getAuthDomain(branch)}`;
  const authApi = axios.create({
    baseURL,
    timeout: 10000,
  });

  authApi.interceptors.request.use(
    (config) => {
      if (branch !== "production") {
        console.log(
          `[Auth API] Request: ${config.method?.toUpperCase()} ${config.url}`,
        );
      }
      return config;
    },
    (error) => Promise.reject(error),
  );

  return authApi;
};
