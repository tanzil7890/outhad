import {
  Connector,
  ConnectorInfoResponse,
  ConnectorListResponse,
  CreateConnectorPayload,
  CreateConnectorResponse,
  TestConnectionPayload,
  TestConnectionResponse,
} from '@/views/Connectors/types';
import { apiRequest, outhadFetch } from './common';
import { RJSFSchema } from '@rjsf/utils';
import { buildUrlWithParams } from './utils';

export type ConnectorsDefinationApiResponse = {
  success: boolean;
  data?: Connector[];
};

type ConnectorDefinationApiResponse = {
  success: boolean;
  data?: {
    icon: string;
    name: string;
    connector_spec: {
      documentation_url: string;
      connection_specification: RJSFSchema;
      supports_normalization: boolean;
      supports_dbt: boolean;
      stream_type: string;
    };
  };
};

export const getConnectorsDefintions = async (connectorType: string): Promise<Connector[]> =>
  outhadFetch<null, Connector[]>({
    method: 'get',
    url: buildUrlWithParams('/connector_definitions', {
      type: connectorType,
    }),
  });

export const getConnectorDefinition = async (
  connectorType: string,
  connectorName: string,
): Promise<ConnectorDefinationApiResponse> => {
  return apiRequest(
    buildUrlWithParams(`/connector_definitions/${connectorName}`, { type: connectorType }),
    null,
  );
};

export const getConnectionStatus = async (payload: TestConnectionPayload) =>
  outhadFetch<TestConnectionPayload, TestConnectionResponse>({
    method: 'post',
    url: '/connector_definitions/check_connection',
    data: payload,
  });

export const createNewConnector = async (
  payload: CreateConnectorPayload,
): Promise<CreateConnectorResponse> =>
  outhadFetch<CreateConnectorPayload, CreateConnectorResponse>({
    method: 'post',
    url: '/connectors',
    data: payload,
  });

export const getConnectorInfo = async (id: string): Promise<ConnectorInfoResponse> =>
  outhadFetch<null, ConnectorInfoResponse>({
    method: 'get',
    url: `/connectors/${id}`,
  });

export const updateConnector = async (
  payload: CreateConnectorPayload,
  id: string,
): Promise<CreateConnectorResponse> =>
  outhadFetch<CreateConnectorPayload, CreateConnectorResponse>({
    method: 'put',
    url: `/connectors/${id}`,
    data: payload,
  });

export const getUserConnectors = async (connectorType: string): Promise<ConnectorListResponse> => {
  return outhadFetch<null, ConnectorListResponse>({
    method: 'get',
    url: buildUrlWithParams('/connectors', {
      type: connectorType,
    }),
    data: null,
  });
};

export const deleteConnector = async (id: string): Promise<ConnectorInfoResponse> =>
  outhadFetch<null, ConnectorInfoResponse>({
    method: 'delete',
    url: `/connectors/${id}`,
  });

export const getAllConnectors = async (): Promise<ConnectorListResponse> =>
  outhadFetch<null, ConnectorListResponse>({
    method: 'get',
    url: '/connectors',
  });
