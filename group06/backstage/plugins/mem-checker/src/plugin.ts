import { createPlugin, createRoutableExtension } from '@backstage/core-plugin-api';

import { rootRouteRef } from './routes';

export const memCheckerPlugin = createPlugin({
  id: 'mem-checker',
  routes: {
    root: rootRouteRef,
  },
});

export const MemCheckerPage = memCheckerPlugin.provide(
  createRoutableExtension({
    name: 'MemCheckerPage',
    component: () =>
      import('./components/ReactContainerComponent').then(m => m.ReactContainerComponent),
    mountPoint: rootRouteRef,
  }),
);
