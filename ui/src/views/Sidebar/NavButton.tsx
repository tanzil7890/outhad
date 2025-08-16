import Badge from '@/components/Badge';
import { As, Button, ButtonProps, HStack, Icon, Text } from '@chakra-ui/react';

interface NavButtonProps extends ButtonProps {
  icon: As;
  label: string;
  disabled?: boolean;
  isCollapsed?: boolean;
}

export const NavButton = (props: NavButtonProps): JSX.Element => {
  const { icon, label, isActive, disabled, isCollapsed = false } = props;
  return (
    <Button
      variant='tertiary'
      justifyContent={isCollapsed ? 'center' : 'start'}
      backgroundColor={isActive ? 'gray.300' : 'none'}
      _hover={!disabled ? { bg: 'gray.300' } : {}}
      marginBottom='10px'
      width='100%'
      size='sm'
      isDisabled={disabled}
      height='36px'
      title={isCollapsed ? label : undefined}
    >
      {isCollapsed ? (
        <Icon as={icon} boxSize='4' color={isActive ? 'black.500' : 'gray.600'} />
      ) : (
        <HStack spacing='2'>
          <Icon as={icon} boxSize='4' color={isActive ? 'black.500' : 'gray.600'} />
          <Text color='black.500' fontWeight={isActive ? 'semibold' : 'medium'} size='sm'>
            {label}
          </Text>
          {disabled ? <Badge text='weaving soon' variant='default' /> : <></>}
        </HStack>
      )}
    </Button>
  );
};

export default NavButton;
