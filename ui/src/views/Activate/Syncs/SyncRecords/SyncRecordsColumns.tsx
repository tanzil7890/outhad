import { SyncRecordResponse, SyncRecordStatus } from '../types';
import StatusTag from '@/components/StatusTag';
import { StatusTagVariants } from '@/components/StatusTag/StatusTag';
import ErrorLogsModal from './ErrorLogsModal';
import { CellContext, ColumnDef } from '@tanstack/react-table';
import { Text } from '@chakra-ui/react';
import { useMemo } from 'react';

export const useDynamicSyncColumns = (data: SyncRecordResponse[]) => {
  return useMemo(() => {
    if (!data || data.length === 0) return [];
    return Object.keys(data[0].attributes.record).map((key) => ({
      accessorKey: `attributes.record.${key}`,
      header: () => <span>{key}</span>,
      cell: (info: CellContext<SyncRecordResponse, string | null>) => (
        <Text size='sm' color='gray.700' fontWeight={500}>
          {info.getValue()}
        </Text>
      ),
    }));
  }, [data]);
};

export const SyncRecordsColumns: ColumnDef<SyncRecordResponse>[] = [
  {
    accessorKey: `attributes.status`,
    header: () => <span>status</span>,
    cell: (info) =>
      info.getValue() === SyncRecordStatus.success ? (
        <StatusTag variant={StatusTagVariants.success} status='Added' />
      ) : (
        <StatusTag variant={StatusTagVariants.failed} status='Failed' />
      ),
  },
  {
    accessorKey: 'attributes',
    header: () => <h1>LOGS</h1>,
    cell: (info) => {
      const syncRecord = info.getValue() as SyncRecordResponse['attributes'];
      if (syncRecord?.logs?.request) {
        return (
          <ErrorLogsModal
            request={syncRecord?.logs?.request}
            response={syncRecord?.logs?.response}
            level={syncRecord?.logs?.level}
            status={syncRecord?.status}
          />
        );
      } else {
        return <></>;
      }
    },
  },
];
