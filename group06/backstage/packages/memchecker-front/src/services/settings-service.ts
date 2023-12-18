import {Settings} from "~/model/settings";

const API_URL = 'http://localhost:5173';

let baseUrl = API_URL;

export const settingsService = () => {
    const getSettings = () =>
        fetch(API_URL + '/api/settings')
            .then((response) => response.json())
    ;

    const setBaseUrl = (url: string) => {
        baseUrl = url;
    }

    const setSettings = (newSettings:Settings) => {
        return fetch(baseUrl + '/api/settings', {
            method: 'POST',
            body: JSON.stringify(newSettings),
            headers: {
                'Content-Type': 'application/json'
            }
        },
    )
            .then((response) => response.json())
    };

    return {
        getSettings,
        setSettings,
        setBaseUrl
    };
}
