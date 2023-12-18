import { component$, useStyles$, useStore} from "@builder.io/qwik";
import {scenariosService} from "~/services/scenarios-service";
import {ScenarioDetails} from "~/model/scenario-details";

export const AddComponent = component$(() => {
    const state = useStore({
      scenario: {
        path: '',
        click: '',
        back: '',
      } as ScenarioDetails,
      success: false,
      error: false
    });
    useStyles$(AddCss);
    useStyles$(FieldCss);
    useStyles$(InputCss);
    useStyles$(ButtonCss);
    useStyles$(ErrorCss);
    useStyles$(GeneralCss);
    useStyles$(SuccessCss);

    return (
      <>
       <a className="settings-link" href="/scenarios">
        <img className="settings-icon" src="/home.png" />
        <span>Home</span>
      </a>

    <div class="add-scenario">

<div className="card card-1">
      <div className="card-top">
      <h1>Add Scenario</h1>

      </div>
      <div className="card-info">
        <div className="card-cost">

        <div class="field">
        <label for="path">Path</label>
        <input type="text" id="path" name="path" value={state.scenario.path} onChange$={(event) => state.scenario.path = event.target.value}/>
      </div>

      <div class="field">
        <label for="click">Click selector</label>
        <input type="text" id="click" name="click" value={state.scenario.click} onChange$={(event) => state.scenario.click = event.target.value}/>
      </div>

      <div class="field">
        <label for="back">Back selector</label>
        <input type="text" id="back" name="back" value={state.scenario.back} onChange$={(event) => state.scenario.back = event.target.value}/>
      </div>

      <button
        type="button"
        onClick$={async() => {
            try {
                await scenariosService().addScenario(state.scenario);
            } catch (e) {
                state.error = true;
                console.error(e);
            }
            state.success = true;
            state.scenario.path = ''
            state.scenario.click = '';
            state.scenario.back = '';
        }}
      >Save</button>

        </div>

        <div className="card-lines">

          <div className="card-line" style="width: 80px;"></div>
          <div className="card-line" style="width: 50px;"></div>
          <div className="card-line" style="width: 90px;"></div>
          <div className="card-line" style="width: 70px;"></div>
        </div>
      </div>
    </div>




      { state.error && <div class="error">Adding scenario failed</div> }
      { state.success && <div class="success">Scenario added</div> }
    </div>
    </>
    )
})

export const GeneralCss = `

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
  width: 600px;
  }

  .add-scenario {
    min-height: calc(100vh - 100px);
    display: flex;
    align-items: center;
    justify-content: center;
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
  }`;

export const AddCss = `.add-scenario {
    width: 350px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    align-items: center;
    border-radius: 5px;
}`

export const FieldCss = `.field {
    font-size: 18px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 10px 0;
}`

export const InputCss = `input {
    font-size: 16px;
    padding: 5px;
}`

export const ButtonCss = `button {
    font-size: 16px;
    padding: 10px;
    margin: 20px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    box-shadow: 0 0 4px rgba(0, 0, 0, 0.15);
    transition: all 0.3s ease-in-out;
}
button:hover {
  background: #ebebeb;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.3);
}`

export const ErrorCss = `.error {
    font-size: 12px;
    color: red;
}`

export const SuccessCss = `.success {
    font-size: 12px;
    color: green;
}`
