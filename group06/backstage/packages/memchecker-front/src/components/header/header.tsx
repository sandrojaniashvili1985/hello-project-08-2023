import { component$, useStylesScoped$ } from '@builder.io/qwik';
import styles from './header.css?inline';

export default component$(() => {
  useStylesScoped$(styles);
  useStylesScoped$(headerStyle);

  return (
    <header>
      
    </header>
  );
});

export const headerStyle = `.header-wrapper {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
`;
