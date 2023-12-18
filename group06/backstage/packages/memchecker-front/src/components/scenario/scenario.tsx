import {component$, useStyles$, $} from "@builder.io/qwik";
import {Scenario} from "~/model/scenario";
import {ScenarioStatus} from "~/components/scenario/scenario-status";

export const ScenarioComponent = component$((props: {
                                               scenario: Scenario
                                             }
) => {
  const {scenario} = props;
  useStyles$(ScenariosCss);

  return (
    <div className="card card-1">
      <div className="card-top">{scenario.name}</div>
      <div className="card-info">
        <div className="card-cost">
          <div className="card-value">Last Updated:</div>
          <div className="card-value"> {scenario.lastResult?.created?.toLocaleString() || 'Not yet'}</div>
        </div>

        <div className="card-lines" onClick$={$(() => scenario.showReport = !scenario.showReport)  }>
          <div
            className={`status-container`}>
            <ScenarioStatus label="Prod" status={scenario.lastResult?.passed}/>
          </div>
          <div className="card-line" style="width: 80px;"></div>
          <div className="card-line" style="width: 50px;"></div>
          <div className="card-line" style="width: 90px;"></div>
          <div className="card-line" style="width: 70px;"></div>
        </div>
      </div>
      <div className={!scenario.showReport? 'hidden': 'shown'}>{JSON.stringify(scenario.lastResult?.fullReport)}</div>
    </div>
  )
})

export const ScenariosCss = `

.card {
box-shadow: rgba(0, 0, 0, 0.16) 0px 10px 36px 0px, rgba(0, 0, 0, 0.06) 0px 0px 0px 1px;
background: white;
height: 15rem;
width: 25rem;
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
.status-container {
width: 100%;
display: flex;
flex-direction: row;
justify-content: space-around;
}

.hidden {
    display: none;
}
`
