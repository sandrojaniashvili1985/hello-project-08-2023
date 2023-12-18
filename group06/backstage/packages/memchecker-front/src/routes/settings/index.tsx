import {
  component$,
  useStyles$,
  useStore,
  Resource,
  useResource$,
  $,
} from '@builder.io/qwik';
import BlobButton from '~/components/buttons/blob-button';
import { Settings } from '~/model/settings';
import { settingsService } from '~/services/settings-service';

interface SettingsStore extends Settings {}

export default component$(() => {
  useStyles$(ScenariosCss);
  const store = useStore<SettingsStore>({
    prodUrl: '',
    stageUrl: '',
    interval: 100,
  });
  const resource = useResource$(() => {
    return settingsService().getSettings();
  });
  const onClick = $(() => {
    const { stageUrl, prodUrl, interval } = store;
    settingsService()
      .setSettings({
        stageUrl,
        prodUrl,
        interval,
      })
      .then(() => {
        console.log('changed');
      });
  });
  return (
    <>
      <a className="settings-link" href="/scenarios">
        <img className="settings-icon" src="/home.png" />
        <span>Home</span>
      </a>

      <div class="settings">
        <div className="card card-1">
          <div className="card-top">
            <h1>Settings</h1>
          </div>
          <div className="card-info">
            <div className="card-cost">
              <div className="card-value">
                <Resource
                  value={resource}
                  onResolved={(settings: Settings) => {
                    console.log(settings);
                    store.prodUrl = settings?.prodUrl;
                    store.interval = settings?.interval;
                    store.stageUrl = settings?.stageUrl;

                    return (
                      <div className="form">
                        <div className="field">
                          <span>Prod URL</span>{' '}
                          <input
                            value={store.prodUrl}
                            onChange$={event =>
                              (store.prodUrl = event.target.value)
                            }
                          />
                        </div>
                        <div className="field">
                          <span>Stage URL</span>{' '}
                          <input
                            value={store.stageUrl}
                            onChange$={event =>
                              (store.stageUrl = event.target.value)
                            }
                          />
                        </div>
                        <div className="field">
                          <span>Interval</span>{' '}
                          <input
                            value={store.interval}
                            type="number"
                            onChange$={event =>
                              (store.interval = event.target.valueAsNumber)
                            }
                          />
                        </div>
                      </div>
                    );
                  }}
                />
              </div>
            </div>
            <BlobButton label="Send" onClick={onClick}></BlobButton>

            <div className="card-lines">
              <div className="card-line" style="width: 80px;"></div>
              <div className="card-line" style="width: 50px;"></div>
              <div className="card-line" style="width: 90px;"></div>
              <div className="card-line" style="width: 70px;"></div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
});

export const ScenariosCss = `

.settings-link {
  z-index: 1;
  display: block;
  text-decoration: none;
  color: #0D0E6F !important;
  cursor: pointer;
  display: flex;
  justify-content: flex-start;
  padding: 0.5rem;
  gap: 1rem;
  align-items: center;
  margin-top: 2rem;
  margin-left: 2rem;
}

.settings-link:hover {
text-decoration: underline;
opacity: 0.8;
transition: opacity 0.2s ease-in-out;
}

.settings-icon{
  width: 30px;
  filter: invert(9%) sepia(65%) saturate(4384%) hue-rotate(238deg) brightness(93%) contrast(112%);
}

.settings {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1px;
    min-height: calc(100vh - 100px);
}
.form {
    display: flex;
    flex-direction: column;
    width: 600px;
}
.field {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin: 10px;
}

.field > * {
    font-size: 24px;
}

input {
  width: 400px;
  border-radius:10px;
  border: 1px solid #eee;
  transition: .3s border-color;
  padding: 5px;
}

input:hover {
  border: 1px solid #aaa;
}

.card {
box-shadow: rgba(0, 0, 0, 0.16) 0px 10px 36px 0px, rgba(0, 0, 0, 0.06) 0px 0px 0px 1px;
background: white;
justify-self: center;
display: flex;
flex-direction: column;
border-radius: 0.3rem;
cursor: pointer;
transition: all 0.3s ease-in-out;
z-index: 999;
}

.card:hover {
transform: scale(1.08);
}

.card-top:hover {
background: darken($orange, 20%);
}

.card-value:hover {
color: darken($orange, 20%);
}

.card-1:hover ~ .bars > .stat > .bar-1 > span {
width: 10%;
}

.card-top {
height: 25%;
width: 100%;
background-color: #0093E9;
background-image: linear-gradient(160deg, #0093E9 0%, #80D0C7 100%);
color: white;
font-weight: 300;
font-size: 1.2rem;
letter-spacing: 0.1rem;
text-transform: uppercase;
border-top-left-radius: 0.3rem;
border-top-right-radius: 0.3rem;

display: flex;
justify-content: center;
align-items: center;
}

.card-info {
height: 75%;
padding: 1rem;
display: flex;
flex-direction: column;
justify-content: space-between;
text-align: left;
font-weight: 300;
}

.card-lines {
width: 100%;
}
`;
