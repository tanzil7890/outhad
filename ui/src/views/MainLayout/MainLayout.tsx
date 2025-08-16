import { Outlet, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';

import Loader from '@/components/Loader';
import { useUiConfig } from '@/utils/hooks';
import Sidebar from '@/views/Sidebar/Sidebar';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import ServerError from '../ServerError';
import getTitle from '@/utils/getPageTitle';

import { Box, IconButton } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { FiMenu } from 'react-icons/fi';

import { getWorkspaces } from '@/services/settings';
import { useStore } from '@/stores';

const MainLayout = (): JSX.Element => {
  const [isLoading, setIsLoading] = useState(true);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const { contentContainerId } = useUiConfig();
  const location = useLocation();
  useEffect(() => {
    const title = getTitle(location.pathname);
    document.title = title;
  }, [location.pathname]);

  const setActiveWorkspaceId = useStore((state) => state.setActiveWorkspaceId);
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const showToast = useCustomToast();

  const {
    data,
    isLoading: workspaceDataIsLoading,
    isError,
    isFetched,
  } = useQuery({
    queryKey: ['workspace'],
    queryFn: () => getWorkspaces(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const workspaceData = data?.data;

  useEffect(() => {
    if (workspaceData && workspaceData.length > 0 && +activeWorkspaceId === 0) {
      setActiveWorkspaceId(workspaceData[0]?.id);
    }
    setIsLoading(false);
  }, [workspaceData]);

  useEffect(() => {
    if (isError || (!data && isFetched)) {
      showToast({
        title: 'Error: Failed to fetch workspace details.',
        description: 'Failed to fetch workspace details.',
        status: CustomToastStatus.Error,
        position: 'bottom-right',
      });
    }
  }, [isError, data, isFetched, showToast]);

  if (isError || (!data && isFetched)) {
    return <ServerError />;
  }

  if (workspaceDataIsLoading || isLoading) {
    return <Loader />;
  }

  return (
    <Box display='flex' width={'100%'} overflow='hidden' maxHeight='100vh'>
      <Sidebar isCollapsed={isSidebarCollapsed} />
      <IconButton
        aria-label='Toggle sidebar'
        icon={<FiMenu />}
        position='absolute'
        top={1}
        left={isSidebarCollapsed ? '72px' : '252px'}
        zIndex={1000}
        bg='white'
        border='2px solid'
        borderColor='gray.400'
        borderRadius='md'
        size='md'
        minW='auto'
        h='30px'
        w='30px'
        p={1}
        onClick={() => setIsSidebarCollapsed(!isSidebarCollapsed)}
        _hover={{ bg: 'gray.100', borderColor: 'gray.500' }}
        shadow='lg'
        color='gray.700'
        transition='left 0.3s ease'
      />
      <Box
        pl={0}
        width={'100%'}
        maxW={'100%'}
        display='flex'
        flex={1}
        flexDir='column'
        className='flex'
        overflow='scroll'
        id={contentContainerId}
        backgroundColor='gray.200'
        position='relative'
      >
        <Outlet />
      </Box>
    </Box>
  );
};

export default MainLayout;
