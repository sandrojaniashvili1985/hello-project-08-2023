import React from 'react';
import {
  Page,
  Content,
} from '@backstage/core-components';

const IFRAME_URL = 'http://localhost:5173/scenarios';
export const ReactContainerComponent = () => (
  <Page themeId="tool">
    <Content>
        <iframe style={{height: '100%', width: '100%'}} src={IFRAME_URL}/>
    </Content>
  </Page>
);
