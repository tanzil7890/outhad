import { outhadFetch } from './common';

export type ProfileAPIResponse = {
  data?: {
    id: number;
    type: string;
    attributes: {
      name: string;
      email: string;
    };
  };
};

export type LogoutAPIResponse = {
  data?: {
    type: string;
    id: string;
    attributes: {
      message: string;
    };
  };
  error?: string;
};

export const getUserProfile = async (): Promise<ProfileAPIResponse> =>
  outhadFetch<null, ProfileAPIResponse>({
    method: 'get',
    url: '/users/me',
  });

export const logout = async (): Promise<LogoutAPIResponse> =>
  outhadFetch<null, LogoutAPIResponse>({
    method: 'delete',
    url: '/logout',
  });
