import { component$ } from '@builder.io/qwik';
import type { DocumentHead, RequestHandler } from '@builder.io/qwik-city';



export default component$(() => {
  return (
    <div>
      <h1>
        Welcome to Memchecker <span class="lightning">⚡️</span>
      </h1>
    </div>
  );
});

export const head: DocumentHead = {
  title: 'Welcome to Memchecker',
  meta: [
    {
      name: 'Memchecker plugin for Backstage',
      content: 'Find your memory leaks',
    },
  ],
};
