import js from "@eslint/js"
import lit from "eslint-plugin-lit"
import tseslint from "typescript-eslint"

/**
 * A comment inside a Lit template is a comment in the rendered document.
 *
 * `html` does not strip `<!-- -->`: the comment node is cloned into the page along with
 * everything else in the literal, where a viewer reading source finds rationale addressed to
 * whoever was editing the component. Rationale belongs in a docstring on `render`.
 */
const noCommentInTemplate = {
  meta: {
    type: "problem",
    docs: { description: "disallow HTML comments inside a Lit template literal" },
    messages: {
      comment:
        "An HTML comment inside a Lit template survives into the rendered document. Move it to a docstring on the surrounding member.",
    },
    schema: [],
  },
  create(context) {
    const TEMPLATE_TAGS = new Set(["html", "svg", "mathml"])
    return {
      TaggedTemplateExpression(node) {
        const tag = node.tag
        const name =
          tag.type === "Identifier"
            ? tag.name
            : tag.type === "MemberExpression" && tag.property.type === "Identifier"
              ? tag.property.name
              : null
        if (name === null || !TEMPLATE_TAGS.has(name)) {
          return
        }
        for (const quasi of node.quasi.quasis) {
          if (quasi.value.raw.includes("<!--")) {
            context.report({ node: quasi, messageId: "comment" })
          }
        }
      },
    }
  },
}

export default tseslint.config(
  js.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  lit.configs["flat/recommended"],
  {
    files: ["src/**/*.ts"],
    languageOptions: {
      parserOptions: { project: "./tsconfig.json", tsconfigRootDir: import.meta.dirname },
    },
    plugins: { plutodeck: { rules: { "no-comment-in-template": noCommentInTemplate } } },
    rules: {
      "plutodeck/no-comment-in-template": "error",

      // A cast asserts what the compiler could not check, and the deck's inputs are a websocket
      // and two JSON endpoints — exactly where an assertion is a runtime error in waiting.
      "@typescript-eslint/consistent-type-assertions": [
        "error",
        { assertionStyle: "never" },
      ],
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

      // A Lit event handler is `@click=${() => this.#move(1)}`, and the alternative the rule
      // asks for is a brace and a return on every one of them.
      "@typescript-eslint/no-confusing-void-expression": ["error", { ignoreArrowShorthand: true }],

      // A slide number in a heading is a number, and every other interpolation stays checked.
      "@typescript-eslint/restrict-template-expressions": ["error", { allowNumber: true }],
    },
  },
  {
    // `render.painter.ts` draws through Preact, not Lit: Rainbow exports htm's `html`, whose
    // `<${Component}>` is the tag-name binding the Lit rules exist to reject. The rules cannot
    // tell the two tags apart, and the deck is not porting that renderer — see DESIGN.md
    // § Cards render through Pluto's own renderer.
    files: ["src/render.painter.ts"],
    rules: {
      "lit/binding-positions": "off",
      "lit/no-invalid-html": "off",
    },
  },
  {
    // `node:test` returns a promise per case and its own runner awaits them.
    files: ["src/**/*.test.ts"],
    rules: { "@typescript-eslint/no-floating-promises": "off" },
  },
  {
    files: ["build.mjs", "eslint.config.js"],
    ...tseslint.configs.disableTypeChecked,
    languageOptions: { globals: { process: "readonly", console: "readonly" } },
  },
)
