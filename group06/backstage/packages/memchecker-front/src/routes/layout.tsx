import { component$, Slot } from '@builder.io/qwik';
import { RequestHandler } from '@builder.io/qwik-city';
import { scenariosService } from '~/services/scenarios-service';
import { settingsService } from '~/services/settings-service';
import Header from '~/components/header/header';

interface RequestHandlerObj {
  request: {
    headers: any;
  };
  url: any;
  params: any;
  platform: any;
  next: () => void;
  abort: () => void;
}

export const onGet: RequestHandler<any> = async (args: RequestHandlerObj) => {
  const { url } = args;
  scenariosService().setOrigin(url.origin);
  settingsService().setBaseUrl(url.origin);
};

export default component$(() => {
  return (
    <>
      <main>
        <Header></Header>
          <Slot />
      </main>
    </>
  );
});
