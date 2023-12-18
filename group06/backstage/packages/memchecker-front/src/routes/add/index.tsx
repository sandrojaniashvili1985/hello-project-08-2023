import { component$, useStyles$ } from '@builder.io/qwik';
import { AddComponent } from '~/components/add/add';
export default component$(() => {
  useStyles$(ScenariosCss);
  return (
    <>
      <AddComponent />
    </>
  );
});


export const ScenariosCss = `.scenarios {
    display: flex;
    gap: 1px;
}`
