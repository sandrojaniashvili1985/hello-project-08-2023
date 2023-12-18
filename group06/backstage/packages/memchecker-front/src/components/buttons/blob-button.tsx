import {component$, useStylesScoped$, QRL } from '@builder.io/qwik';
import styles from './blob-button.css?inline';

export default component$<{ label: string, onClick: QRL<() => {}>  }>(({ label, onClick}) => {
    useStylesScoped$(styles);

    return (
        <button className="blob-btn" onClick$={onClick}>
            {label}
            <span className="blob-btn__inner">
                  <span className="blob-btn__blobs">
                        <span className="blob-btn__blob"></span>
                        <span className="blob-btn__blob"></span>
                        <span className="blob-btn__blob"></span>
                        <span className="blob-btn__blob"></span>
                  </span>
            </span>
        </button>
    );
});
