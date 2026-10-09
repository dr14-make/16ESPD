import js from "@eslint/js"
import tseslint from "typescript-eslint"

export default tseslint.config(
  { ignores: ["**/node_modules/", "dist/", "**/.slidev/"] },
  {
    files: ["addons/pluto/{src,test}/**/*.ts"],
    extends: [
      js.configs.recommended,
      tseslint.configs.strictTypeChecked,
      tseslint.configs.stylisticTypeChecked,
    ],
    languageOptions: {
      parserOptions: { project: "./addons/pluto/tsconfig.json", tsconfigRootDir: import.meta.dirname },
    },
    rules: {
      // A cast asserts what the compiler could not check, and the addon's inputs are a websocket
      // and a session file — exactly where an assertion is a runtime error in waiting.
      "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports", fixStyle: "separate-type-imports" },
      ],
      "@typescript-eslint/no-import-type-side-effects": "error",

      // Nothing here has a console to log to: a deck is watched by a room, not by a developer.
      "no-console": "error",
      "no-var": "error",
      curly: "error",
      eqeqeq: ["error", "always"],
      "@typescript-eslint/no-confusing-void-expression": ["error", { ignoreArrowShorthand: true }],
      "@typescript-eslint/restrict-template-expressions": ["error", { allowNumber: true }],
    },
  },
  {
    // `node:test` returns a promise per case and its own runner awaits them.
    files: ["addons/pluto/{src,test}/**/*.test.ts"],
    rules: { "@typescript-eslint/no-floating-promises": "off" },
  },
)
