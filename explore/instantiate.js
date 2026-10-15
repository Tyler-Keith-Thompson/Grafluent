// @ts-check
import { SwiftRuntime } from "./runtime.js";

export const MODULE_PATH = "Explore.wasm";

// @ts-expect-error Substituted by PackageToJS preprocessor
import { createInstantiator } from "./bridge-js.js";

/** @type {import('./instantiate.d').instantiate} */
export async function instantiate(options) {
    const { instantiator, ...result } = await _instantiate(options);
        options.wasi.initialize(result.instance);
        result.swift.main();
    return result;
}

/** @type {import('./instantiate.d').instantiateForThread} */
export async function instantiateForThread(tid, startArg, options) {
    const { instantiator, ...result } = await _instantiate(options);
        options.wasi.setInstance(result.instance);
        result.swift.startThread(tid, startArg);
    return result;
}

/** @param {import('./instantiate.d').InstantiateOptions} options */
async function _instantiate(options) {
    const _WebAssembly = options.WebAssembly || WebAssembly;
    const moduleSource = options.module;
        const { wasi } = options;
        const swift = new SwiftRuntime({
            });
    const instantiator = await createInstantiator(options, swift);

    /** @type {WebAssembly.Imports} */
    const importObject = {
        javascript_kit: swift.wasmImports,
                wasi_snapshot_preview1: wasi.wasiImport,
                    };
    const importsContext = {
        getInstance: () => instance,
        getExports: () => exports,
        _swift: swift,
    };
    instantiator.addImports(importObject, importsContext);
    options.addToCoreImports?.(importObject, importsContext);

    let module;
    let instance;
    let exports;
    if (moduleSource instanceof _WebAssembly.Module) {
        module = moduleSource;
        instance = await _WebAssembly.instantiate(module, importObject);
    } else if (
        typeof Response === "function" &&
        (moduleSource instanceof Response || moduleSource instanceof Promise)
    ) {
        if (typeof _WebAssembly.instantiateStreaming === "function") {
            const result = await _WebAssembly.instantiateStreaming(
                moduleSource,
                importObject,
            );
            module = result.module;
            instance = result.instance;
        } else {
            const moduleBytes = await (await moduleSource).arrayBuffer();
            module = await _WebAssembly.compile(moduleBytes);
            instance = await _WebAssembly.instantiate(module, importObject);
        }
    } else {
        // @ts-expect-error: Type 'Response' is not assignable to type 'BufferSource'
        module = await _WebAssembly.compile(moduleSource);
        instance = await _WebAssembly.instantiate(module, importObject);
    }
    instance =
        options.instrumentInstance?.(instance, { _swift: swift }) ?? instance;

    swift.setInstance(instance);
    instantiator.setInstance(instance);
    exports = instantiator.createExports(instance);

    return {
        instance,
        swift,
        exports,
        instantiator,
    };
}
