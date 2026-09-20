// @plutojl/rainbow ships an ESM build meant to be fed to a bundler, not a browser: immer
// reads `process.env.NODE_ENV`, and the embedded browserify bundles (msgpack-lite, the
// `path` polyfill) reference `process` and `global`. Nothing defines them in a page, so
// importing the bundle directly throws `ReferenceError: process is not defined`.
//
// ESM evaluates imports in order, so this must stay the first import in rainbow-bridge.js.
globalThis.global ??= globalThis
globalThis.process ??= {}
globalThis.process.env ??= { NODE_ENV: "production" }
globalThis.process.cwd ??= () => "/"
