import {
  component$,
  Resource,
  useResource$,
  useStyles$,
} from '@builder.io/qwik';
import {Scenario} from '~/model/scenario';
import {scenariosService} from '~/services/scenarios-service';
import {ScenarioComponent} from '../../components/scenario/scenario';

export default component$(() => {
  useStyles$(ScenariosCss);

  const resource = useResource$<Scenario[]>(() => {
    console.log('resource');
    return scenariosService().getScenarios();
  });

  return (

    <div className="main-wrapper">
     <div className="header-wrapper">
        <img className="logo" src="/memcheckerlogo.png" alt="logo" />
        <div className="actions-container">
          <a className="settings-link" href="/settings">
            <span>Settings</span>
            <img className="settings-icon" src="/settings.png" />
          </a>
          <a className="settings-link" href="/add">
            <span>Add New Scenario</span>
            <img className="settings-icon" src="/plus.png" />
          </a>
        </div>
      </div>
      <img
        className="illustration"
        src="/memcheckerill.jpg"
        alt="illustration"
      />


      <div className={'scenarios'}>
        <Resource
          value={resource}
          onResolved={(scenarios) => {
            return (<>{scenarios.map(scenario => {
              return <ScenarioComponent scenario={scenario}/>;
            })}</>);
          }}
        />
      </div>
    </div>
  );
});

export const ScenariosCss = `

.header-wrapper {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.main-wrapper{
  padding: 2rem;
  height: 100%;
  width: calc(95% - 4rem);
  margin: 0 auto;

}
.illustration{
  position: absolute;
  width: 80vw;
  bottom: -20%;
  right:-20%;
  z-index: 0;
  opacity: 0.2;
}

.actions-container {
  z-index: 55;
}

.settings-link {
  z-index: 1;
  display: block;
  text-decoration: none;
  color: #0D0E6F !important;
  cursor: pointer;
  display: flex;
  justify-content: flex-end;
  padding: 0.5rem;
  gap: 1rem;
  align-items: center;
}

.settings-link:hover {
text-decoration: underline;
opacity: 0.8;
transition: opacity 0.2s ease-in-out;
}

.logo {
  width: 550px;
  margin-left:-1rem;
  z-index: 1;
}
.settings-icon{
  width: 30px;
  filter: invert(9%) sepia(65%) saturate(4384%) hue-rotate(238deg) brightness(93%) contrast(112%);
}

.scenarios {
  margin-top: 2rem;
    display: flex;
    gap: 2rem;
    flex-wrap: wrap;
}`;
