import { Scenario } from '~/model/scenario';
import {ScenarioDetails} from "~/model/scenario-details";


const BASE_URL = 'http://localhost:5173'
let originUrl = BASE_URL;



export const scenariosService = () => {

  const setOrigin = (origin: string) => {
    originUrl = origin;
  }

  const getScenarios: () => Promise<Scenario[]> = async () => {
    try {
    const response = await fetch(`${originUrl}/api/scenarios`);
    return response.json();
    } catch (e) {
        console.error(e);
        return [];
    }
  };

  const addScenario = (scenario: ScenarioDetails) => {
      const scenarioAPIModel = {
          name: scenario.path,
          link: scenario.path,
          action: scenario.click,
          back: scenario.back,
          created: Date.now(),
      };
      return fetch(`${BASE_URL}/api/scenarios`, {
          method: 'POST',
          body: JSON.stringify(scenarioAPIModel),
          headers: {'Content-Type': 'application/json'}
      }).then(response => response.json());
  };
  return {
    getScenarios,
    setOrigin,
    addScenario,
  };
};
