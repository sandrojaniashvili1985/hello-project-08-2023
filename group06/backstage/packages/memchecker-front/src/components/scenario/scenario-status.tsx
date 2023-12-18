import {component$, useStylesScoped$} from "@builder.io/qwik";

export const ScenarioStatus = component$((props: { status: boolean, label: string }) => {
  useStylesScoped$(styles);
  return <div class={`chip ${!props.status ? 'fail' : 'success'}`}>
    {props.label}
  </div>
});

export const styles = `
   @keyframes blinking-red {
        0% {
          background-color: #f87171;
        }
        50% {
          background-color: #dc2626;
        }
        100% {
          background-color: #f87171;
        }
      }


  .chip {
    padding: 0.5rem 1rem;
    width: 80%;
    height: 25px;
    text-align: center;
    border-radius: 5px;
    color: white;
    animation: blinking 1s infinite;
  }

  .fail {
    animation: blinking-red 1s infinite;
  }

  .success {
    background: #16a34a;
  }
  `
