// The lodash a plot cell imports. See the import map in `index.html`.
//
// The version served is 4.18.1 rather than the 4.17.21 the specifier names: a specifier is what
// a plot asks for, and what satisfies it is the deck's to choose. Every release through 4.17.23
// carries advisories on `_.template`, `_.unset` and `_.omit`
// (https://github.com/advisories/GHSA-r5fr-rjxr-66jc, GHSA-f23m-r3pf-42rh, GHSA-xxjr-mmjv-4gpg);
// nothing a plot script calls is among them, so the bump is for the deck's own audit rather
// than for a plot.

import * as lodash from "lodash-es"

export * from "lodash-es"

export default lodash
