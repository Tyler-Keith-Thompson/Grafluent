// @ts-check
import { instantiate } from './instantiate.js';
import { defaultBrowserSetup } from './platforms/browser.js';


/** @type {import('./index.d').init} */
async function initBrowser(_options) {
    /** @type {import('./index.d').Options} */
    const options = _options || {
        /** @returns {import('./instantiate.d').Imports} */
        getImports() { (() => { throw new Error("No imports provided") })() }
    };
    let module = options.module;
    if (!module) {
        module = fetch(new URL("Explore.wasm", import.meta.url))
    }
    const instantiateOptions = await defaultBrowserSetup({
        module,
        getImports: () => options.getImports(),
    })
    return await instantiate(instantiateOptions);
}


/** @type {import('./index.d').init} */
export async function init(options) {
        return initBrowser(options);
    }