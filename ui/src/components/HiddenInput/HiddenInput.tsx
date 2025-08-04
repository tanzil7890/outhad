import {
  IconButton,
  Input,
  InputGroup,
  InputProps,
  InputRightElement,
  useDisclosure,
} from '@chakra-ui/react';
import { FiEye, FiEyeOff } from 'react-icons/fi';

const HiddenInput = (props: InputProps): JSX.Element => {
  const { isOpen, onToggle } = useDisclosure();

  const onClickReveal = () => {
    onToggle();
  };

  return (
    <InputGroup>
      <Input
        id={props.id}
        name='password'
        autoComplete='current-password'
        required
        {...props}
        type={isOpen ? 'text' : 'password'}
      />
      <InputRightElement>
        <IconButton
          variant='text'
          aria-label={isOpen ? 'Mask password' : 'Reveal password'}
          icon={isOpen ? <FiEyeOff /> : <FiEye />}
          onClick={onClickReveal}
        />
      </InputRightElement>
    </InputGroup>
  );
};

export default HiddenInput;
