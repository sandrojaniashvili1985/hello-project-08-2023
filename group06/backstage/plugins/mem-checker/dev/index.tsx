import React from 'react';
import { createDevApp } from '@backstage/dev-utils';
import { memCheckerPlugin, MemCheckerPage } from '../src/plugin';

createDevApp()
  .registerPlugin(memCheckerPlugin)
  .addPage({
    element: <MemCheckerPage />,
    title: 'Root Page',
    path: '/mem-checker'
  })
  .render();
