var EOL = {},
    EOF = {},
    QUOTE = 34,
    NEWLINE = 10,
    RETURN = 13;

function objectConverter(columns) {
  return new Function("d", "return {" + columns.map(function(name, i) {
    return JSON.stringify(name) + ": d[" + i + "] || \"\"";
  }).join(",") + "}");
}

function customConverter(columns, f) {
  var object = objectConverter(columns);
  return function(row, i) {
    return f(object(row), i, columns);
  };
}

// Compute unique columns in order of discovery.
function inferColumns(rows) {
  var columnSet = Object.create(null),
      columns = [];

  rows.forEach(function(row) {
    for (var column in row) {
      if (!(column in columnSet)) {
        columns.push(columnSet[column] = column);
      }
    }
  });

  return columns;
}

function pad(value, width) {
  var s = value + "", length = s.length;
  return length < width ? new Array(width - length + 1).join(0) + s : s;
}

function formatYear(year) {
  return year < 0 ? "-" + pad(-year, 6)
    : year > 9999 ? "+" + pad(year, 6)
    : pad(year, 4);
}

function formatDate(date) {
  var hours = date.getUTCHours(),
      minutes = date.getUTCMinutes(),
      seconds = date.getUTCSeconds(),
      milliseconds = date.getUTCMilliseconds();
  return isNaN(date) ? "Invalid Date"
      : formatYear(date.getUTCFullYear()) + "-" + pad(date.getUTCMonth() + 1, 2) + "-" + pad(date.getUTCDate(), 2)
      + (milliseconds ? "T" + pad(hours, 2) + ":" + pad(minutes, 2) + ":" + pad(seconds, 2) + "." + pad(milliseconds, 3) + "Z"
      : seconds ? "T" + pad(hours, 2) + ":" + pad(minutes, 2) + ":" + pad(seconds, 2) + "Z"
      : minutes || hours ? "T" + pad(hours, 2) + ":" + pad(minutes, 2) + "Z"
      : "");
}

function dsv$1(delimiter) {
  var reFormat = new RegExp("[\"" + delimiter + "\n\r]"),
      DELIMITER = delimiter.charCodeAt(0);

  function parse(text, f) {
    var convert, columns, rows = parseRows(text, function(row, i) {
      if (convert) return convert(row, i - 1);
      columns = row, convert = f ? customConverter(row, f) : objectConverter(row);
    });
    rows.columns = columns || [];
    return rows;
  }

  function parseRows(text, f) {
    var rows = [], // output rows
        N = text.length,
        I = 0, // current character index
        n = 0, // current line number
        t, // current token
        eof = N <= 0, // current token followed by EOF?
        eol = false; // current token followed by EOL?

    // Strip the trailing newline.
    if (text.charCodeAt(N - 1) === NEWLINE) --N;
    if (text.charCodeAt(N - 1) === RETURN) --N;

    function token() {
      if (eof) return EOF;
      if (eol) return eol = false, EOL;

      // Unescape quotes.
      var i, j = I, c;
      if (text.charCodeAt(j) === QUOTE) {
        while (I++ < N && text.charCodeAt(I) !== QUOTE || text.charCodeAt(++I) === QUOTE);
        if ((i = I) >= N) eof = true;
        else if ((c = text.charCodeAt(I++)) === NEWLINE) eol = true;
        else if (c === RETURN) { eol = true; if (text.charCodeAt(I) === NEWLINE) ++I; }
        return text.slice(j + 1, i - 1).replace(/""/g, "\"");
      }

      // Find next delimiter or newline.
      while (I < N) {
        if ((c = text.charCodeAt(i = I++)) === NEWLINE) eol = true;
        else if (c === RETURN) { eol = true; if (text.charCodeAt(I) === NEWLINE) ++I; }
        else if (c !== DELIMITER) continue;
        return text.slice(j, i);
      }

      // Return last token before EOF.
      return eof = true, text.slice(j, N);
    }

    while ((t = token()) !== EOF) {
      var row = [];
      while (t !== EOL && t !== EOF) row.push(t), t = token();
      if (f && (row = f(row, n++)) == null) continue;
      rows.push(row);
    }

    return rows;
  }

  function preformatBody(rows, columns) {
    return rows.map(function(row) {
      return columns.map(function(column) {
        return formatValue(row[column]);
      }).join(delimiter);
    });
  }

  function format(rows, columns) {
    if (columns == null) columns = inferColumns(rows);
    return [columns.map(formatValue).join(delimiter)].concat(preformatBody(rows, columns)).join("\n");
  }

  function formatBody(rows, columns) {
    if (columns == null) columns = inferColumns(rows);
    return preformatBody(rows, columns).join("\n");
  }

  function formatRows(rows) {
    return rows.map(formatRow).join("\n");
  }

  function formatRow(row) {
    return row.map(formatValue).join(delimiter);
  }

  function formatValue(value) {
    return value == null ? ""
        : value instanceof Date ? formatDate(value)
        : reFormat.test(value += "") ? "\"" + value.replace(/"/g, "\"\"") + "\""
        : value;
  }

  return {
    parse: parse,
    parseRows: parseRows,
    format: format,
    formatBody: formatBody,
    formatRows: formatRows,
    formatRow: formatRow,
    formatValue: formatValue
  };
}

var csv = dsv$1(",");

var csvParse = csv.parse;
var csvParseRows = csv.parseRows;

var tsv = dsv$1("\t");

var tsvParse = tsv.parse;
var tsvParseRows = tsv.parseRows;

function autoType(object) {
  for (var key in object) {
    var value = object[key].trim(), number, m;
    if (!value) value = null;
    else if (value === "true") value = true;
    else if (value === "false") value = false;
    else if (value === "NaN") value = NaN;
    else if (!isNaN(number = +value)) value = number;
    else if (m = value.match(/^([-+]\d{2})?\d{4}(-\d{2}(-\d{2})?)?(T\d{2}:\d{2}(:\d{2}(\.\d{3})?)?(Z|[-+]\d{2}:\d{2})?)?$/)) {
      if (fixtz && !!m[4] && !m[7]) value = value.replace(/-/g, "/").replace(/T/, " ");
      value = new Date(value);
    }
    else continue;
    object[key] = value;
  }
  return object;
}

// https://github.com/d3/d3-dsv/issues/45
const fixtz = new Date("2019-01-01T00:00").getHours() || new Date("2019-07-01T00:00").getHours();

function dependency(name, version, main) {
  return {
    resolve(path = main) {
      return `${name}@${version}/${path}`;
    }
  };
}

const d3 = dependency("d3", "7.6.1", "dist/d3.min.js");
const inputs = dependency("@observablehq/inputs", "0.10.4", "dist/inputs.min.js");
const plot = dependency("@observablehq/plot", "0.6.0", "dist/plot.umd.min.js");
const graphviz = dependency("@observablehq/graphviz", "0.2.1", "dist/graphviz.min.js");
const highlight = dependency("@observablehq/highlight.js", "2.0.0", "highlight.min.js");
const katex = dependency("@observablehq/katex", "0.11.1", "dist/katex.min.js");
const lodash = dependency("lodash", "4.17.21", "lodash.min.js");
const htl = dependency("htl", "0.3.1", "dist/htl.min.js");
const jszip = dependency("jszip", "3.10.0", "dist/jszip.min.js");
const marked = dependency("marked", "0.3.12", "marked.min.js");
const sql = dependency("sql.js", "1.7.0", "dist/sql-wasm.js");
const vega = dependency("vega", "5.22.1", "build/vega.min.js");
const vegalite = dependency("vega-lite", "5.5.0", "build/vega-lite.min.js");
const vegaliteApi = dependency("vega-lite-api", "5.0.0", "build/vega-lite-api.min.js");
const arrow = dependency("apache-arrow", "4.0.1", "Arrow.es2015.min.js");
const arquero = dependency("arquero", "4.8.8", "dist/arquero.min.js");
const topojson = dependency("topojson-client", "3.1.0", "dist/topojson-client.min.js");
const exceljs = dependency("exceljs", "4.3.0", "dist/exceljs.min.js");
const mermaid$1 = dependency("mermaid", "9.1.6", "dist/mermaid.min.js");
const leaflet$1 = dependency("leaflet", "1.8.0", "dist/leaflet.js");

const metas = new Map;
const queue$2 = [];
const map$1 = queue$2.map;
const some = queue$2.some;
const hasOwnProperty$1 = queue$2.hasOwnProperty;
const identifierRe = /^((?:@[^/@]+\/)?[^/@]+)(?:@([^/]+))?(?:\/(.*))?$/;
const versionRe = /^\d+\.\d+\.\d+(-[\w-.+]+)?$/;
const extensionRe = /(?:\.[^/]*|\/)$/;

class RequireError extends Error {
  constructor(message) {
    super(message);
  }
}

RequireError.prototype.name = RequireError.name;

function parseIdentifier(identifier) {
  const match = identifierRe.exec(identifier);
  return match && {
    name: match[1],
    version: match[2],
    path: match[3]
  };
}

function resolveFrom(origin = "https://cdn.jsdelivr.net/npm/", mains = ["unpkg", "jsdelivr", "browser", "main"]) {
  if (!/\/$/.test(origin)) throw new Error("origin lacks trailing slash");

  function main(meta) {
    for (const key of mains) {
      let value = meta[key];
      if (typeof value === "string") {
        if (value.startsWith("./")) value = value.slice(2);
        return extensionRe.test(value) ? value : `${value}.js`;
      }
    }
  }

  function resolveMeta(target) {
    const url = `${origin}${target.name}${target.version ? `@${target.version}` : ""}/package.json`;
    let meta = metas.get(url);
    if (!meta) metas.set(url, meta = fetch(url).then(response => {
      if (!response.ok) throw new RequireError("unable to load package.json");
      if (response.redirected && !metas.has(response.url)) metas.set(response.url, meta);
      return response.json();
    }));
    return meta;
  }

  return async function resolve(name, base) {
    if (name.startsWith(origin)) name = name.substring(origin.length);
    if (/^(\w+:)|\/\//i.test(name)) return name;
    if (/^[.]{0,2}\//i.test(name)) return new URL(name, base == null ? location : base).href;
    if (!name.length || /^[\s._]/.test(name) || /\s$/.test(name)) throw new RequireError("illegal name");
    const target = parseIdentifier(name);
    if (!target) return `${origin}${name}`;
    if (!target.version && base != null && base.startsWith(origin)) {
      const meta = await resolveMeta(parseIdentifier(base.substring(origin.length)));
      target.version = meta.dependencies && meta.dependencies[target.name] || meta.peerDependencies && meta.peerDependencies[target.name];
    }
    if (target.path && !extensionRe.test(target.path)) target.path += ".js";
    if (target.path && target.version && versionRe.test(target.version)) return `${origin}${target.name}@${target.version}/${target.path}`;
    const meta = await resolveMeta(target);
    return `${origin}${meta.name}@${meta.version}/${target.path || main(meta) || "index.js"}`;
  };
}

var require$1 = requireFrom(resolveFrom());

function requireFrom(resolver) {
  const cache = new Map;
  const requireBase = requireRelative(null);

  function requireAbsolute(url) {
    if (typeof url !== "string") return url;
    let module = cache.get(url);
    if (!module) cache.set(url, module = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.onload = () => {
        try { resolve(queue$2.pop()(requireRelative(url))); }
        catch (error) { reject(new RequireError("invalid module")); }
        script.remove();
      };
      script.onerror = () => {
        reject(new RequireError("unable to load module"));
        script.remove();
      };
      script.async = true;
      script.src = url;
      window.define = define;
      document.head.appendChild(script);
    }));
    return module;
  }

  function requireRelative(base) {
    return name => Promise.resolve(resolver(name, base)).then(requireAbsolute);
  }

  function requireAlias(aliases) {
    return requireFrom((name, base) => {
      if (name in aliases) {
        name = aliases[name], base = null;
        if (typeof name !== "string") return name;
      }
      return resolver(name, base);
    });
  }

  function require(name) {
    return arguments.length > 1
        ? Promise.all(map$1.call(arguments, requireBase)).then(merge)
        : requireBase(name);
  }

  require.alias = requireAlias;
  require.resolve = resolver;

  return require;
}

function merge(modules) {
  const o = {};
  for (const m of modules) {
    for (const k in m) {
      if (hasOwnProperty$1.call(m, k)) {
        if (m[k] == null) Object.defineProperty(o, k, {get: getter(m, k)});
        else o[k] = m[k];
      }
    }
  }
  return o;
}

function getter(object, name) {
  return () => object[name];
}

function isbuiltin(name) {
  name = name + "";
  return name === "exports" || name === "module";
}

function define(name, dependencies, factory) {
  const n = arguments.length;
  if (n < 2) factory = name, dependencies = [];
  else if (n < 3) factory = dependencies, dependencies = typeof name === "string" ? [] : name;
  queue$2.push(some.call(dependencies, isbuiltin) ? require => {
    const exports$1 = {};
    const module = {exports: exports$1};
    return Promise.all(map$1.call(dependencies, name => {
      name = name + "";
      return name === "exports" ? exports$1 : name === "module" ? module : require(name);
    })).then(dependencies => {
      factory.apply(null, dependencies);
      return module.exports;
    });
  } : require => {
    return Promise.all(map$1.call(dependencies, require)).then(dependencies => {
      return typeof factory === "function" ? factory.apply(null, dependencies) : factory;
    });
  });
}

define.amd = {};

let requireDefault = require$1;

function setDefaultRequire(require) {
  requireDefault = require;
}

function requirer(resolve) {
  return resolve == null ? requireDefault : requireFrom(resolve);
}

async function sqlite(require) {
  const [init, dist] = await Promise.all([require(sql.resolve()), require.resolve(sql.resolve("dist/"))]);
  return init({locateFile: file => `${dist}${file}`});
}

class SQLiteDatabaseClient {
  constructor(db) {
    Object.defineProperties(this, {
      _db: {value: db}
    });
  }
  static async open(source) {
    const [SQL, buffer] = await Promise.all([sqlite(requireDefault), Promise.resolve(source).then(load)]);
    return new SQLiteDatabaseClient(new SQL.Database(buffer));
  }
  async query(query, params) {
    return await exec(this._db, query, params);
  }
  async queryRow(query, params) {
    return (await this.query(query, params))[0] || null;
  }
  async explain(query, params) {
    const rows = await this.query(`EXPLAIN QUERY PLAN ${query}`, params);
    return element$1("pre", {className: "observablehq--inspect"}, [
      text$2(rows.map(row => row.detail).join("\n"))
    ]);
  }
  async describeTables({schema} = {}) {
    return this.query(`SELECT NULLIF(schema, 'main') AS schema, name FROM pragma_table_list() WHERE type = 'table'${schema == null ? "" : ` AND schema = ?`} AND name NOT LIKE 'sqlite_%'`, schema == null ? [] : [schema]);
  }
  async describeColumns({schema, table} = {}) {
    if (table == null) throw new Error(`missing table`);
    const rows = await this.query(`SELECT name, type, "notnull" FROM pragma_table_info(?${schema == null ? "" : `, ?`}) ORDER BY cid`, schema == null ? [table] : [table, schema]);
    if (!rows.length) throw new Error(`table not found: ${table}`);
    return rows.map(({name, type, notnull}) => ({name, type: sqliteType(type), databaseType: type, nullable: !notnull}));
  }
  async describe(object) {
    const rows = await (object === undefined
      ? this.query(`SELECT name FROM sqlite_master WHERE type = 'table'`)
      : this.query(`SELECT * FROM pragma_table_info(?)`, [object]));
    if (!rows.length) throw new Error("Not found");
    const {columns} = rows;
    return element$1("table", {value: rows}, [
      element$1("thead", [element$1("tr", columns.map(c => element$1("th", [text$2(c)])))]),
      element$1("tbody", rows.map(r => element$1("tr", columns.map(c => element$1("td", [text$2(r[c])])))))
    ]);
  }
  async sql() {
    return this.query(...this.queryTag.apply(this, arguments));
  }
  queryTag(strings, ...params) {
    return [strings.join("?"), params];
  }
}

Object.defineProperty(SQLiteDatabaseClient.prototype, "dialect", {
  value: "sqlite"
});

// https://www.sqlite.org/datatype3.html
function sqliteType(type) {
  switch (type) {
    case "NULL":
      return "null";
    case "INT":
    case "INTEGER":
    case "TINYINT":
    case "SMALLINT":
    case "MEDIUMINT":
    case "BIGINT":
    case "UNSIGNED BIG INT":
    case "INT2":
    case "INT8":
      return "integer";
    case "TEXT":
    case "CLOB":
      return "string";
    case "REAL":
    case "DOUBLE":
    case "DOUBLE PRECISION":
    case "FLOAT":
    case "NUMERIC":
      return "number";
    case "BLOB":
      return "buffer";
    case "DATE":
    case "DATETIME":
      return "string"; // TODO convert strings to Date instances in sql.js
    default:
      return /^(?:(?:(?:VARYING|NATIVE) )?CHARACTER|(?:N|VAR|NVAR)CHAR)\(/.test(type) ? "string"
        : /^(?:DECIMAL|NUMERIC)\(/.test(type) ? "number"
        : "other";
  }
}

function load(source) {
  return typeof source === "string" ? fetch(source).then(load)
    : source instanceof Response || source instanceof Blob ? source.arrayBuffer().then(load)
    : source instanceof ArrayBuffer ? new Uint8Array(source)
    : source;
}

async function exec(db, query, params) {
  const [result] = await db.exec(query, params);
  if (!result) return [];
  const {columns, values} = result;
  const rows = values.map(row => Object.fromEntries(row.map((value, i) => [columns[i], value])));
  rows.columns = columns;
  return rows;
}

function element$1(name, props, children) {
  if (arguments.length === 2) children = props, props = undefined;
  const element = document.createElement(name);
  if (props !== undefined) for (const p in props) element[p] = props[p];
  if (children !== undefined) for (const c of children) element.appendChild(c);
  return element;
}

function text$2(value) {
  return document.createTextNode(value);
}

class Workbook {
  constructor(workbook) {
    Object.defineProperties(this, {
      _: {value: workbook},
      sheetNames: {
        value: workbook.worksheets.map((s) => s.name),
        enumerable: true
      }
    });
  }
  sheet(name, options) {
    const sname =
      typeof name === "number"
        ? this.sheetNames[name]
        : this.sheetNames.includes((name += ""))
        ? name
        : null;
    if (sname == null) throw new Error(`Sheet not found: ${name}`);
    const sheet = this._.getWorksheet(sname);
    return extract(sheet, options);
  }
}

function extract(sheet, {range, headers} = {}) {
  let [[c0, r0], [c1, r1]] = parseRange(range, sheet);
  const headerRow = headers ? sheet._rows[r0++] : null;
  let names = new Set(["#"]);
  for (let n = c0; n <= c1; n++) {
    const value = headerRow ? valueOf(headerRow.findCell(n + 1)) : null;
    let name = (value && value + "") || toColumn(n);
    while (names.has(name)) name += "_";
    names.add(name);
  }
  names = new Array(c0).concat(Array.from(names));

  const output = new Array(r1 - r0 + 1);
  for (let r = r0; r <= r1; r++) {
    const row = (output[r - r0] = Object.create(null, {"#": {value: r + 1}}));
    const _row = sheet.getRow(r + 1);
    if (_row.hasValues)
      for (let c = c0; c <= c1; c++) {
        const value = valueOf(_row.findCell(c + 1));
        if (value != null) row[names[c + 1]] = value;
      }
  }

  output.columns = names.filter(() => true); // Filter sparse columns
  return output;
}

function valueOf(cell) {
  if (!cell) return;
  const {value} = cell;
  if (value && typeof value === "object" && !(value instanceof Date)) {
    if (value.formula || value.sharedFormula) {
      return value.result && value.result.error ? NaN : value.result;
    }
    if (value.richText) {
      return richText(value);
    }
    if (value.text) {
      let {text} = value;
      if (text.richText) text = richText(text);
      return value.hyperlink && value.hyperlink !== text
        ? `${value.hyperlink} ${text}`
        : text;
    }
    return value;
  }
  return value;
}

function richText(value) {
  return value.richText.map((d) => d.text).join("");
}

function parseRange(specifier = ":", {columnCount, rowCount}) {
  specifier += "";
  if (!specifier.match(/^[A-Z]*\d*:[A-Z]*\d*$/))
    throw new Error("Malformed range specifier");
  const [[c0 = 0, r0 = 0], [c1 = columnCount - 1, r1 = rowCount - 1]] =
    specifier.split(":").map(fromCellReference);
  return [
    [c0, r0],
    [c1, r1]
  ];
}

// Returns the default column name for a zero-based column index.
// For example: 0 -> "A", 1 -> "B", 25 -> "Z", 26 -> "AA", 27 -> "AB".
function toColumn(c) {
  let sc = "";
  c++;
  do {
    sc = String.fromCharCode(64 + (c % 26 || 26)) + sc;
  } while ((c = Math.floor((c - 1) / 26)));
  return sc;
}

// Returns the zero-based indexes from a cell reference.
// For example: "A1" -> [0, 0], "B2" -> [1, 1], "AA10" -> [26, 9].
function fromCellReference(s) {
  const [, sc, sr] = s.match(/^([A-Z]*)(\d*)$/);
  let c = 0;
  if (sc)
    for (let i = 0; i < sc.length; i++)
      c += Math.pow(26, sc.length - i - 1) * (sc.charCodeAt(i) - 64);
  return [c ? c - 1 : undefined, sr ? +sr - 1 : undefined];
}

async function remote_fetch(file) {
  const response = await fetch(await file.url());
  if (!response.ok) throw new Error(`Unable to load file: ${file.name}`);
  return response;
}

async function dsv(file, delimiter, {array = false, typed = false} = {}) {
  const text = await file.text();
  return (delimiter === "\t"
      ? (array ? tsvParseRows : tsvParse)
      : (array ? csvParseRows : csvParse))(text, typed && autoType);
}

class AbstractFile {
  constructor(name, mimeType) {
    Object.defineProperty(this, "name", {value: name, enumerable: true});
    if (mimeType !== undefined) Object.defineProperty(this, "mimeType", {value: mimeType + "", enumerable: true});
  }
  async blob() {
    return (await remote_fetch(this)).blob();
  }
  async arrayBuffer() {
    return (await remote_fetch(this)).arrayBuffer();
  }
  async text() {
    return (await remote_fetch(this)).text();
  }
  async json() {
    return (await remote_fetch(this)).json();
  }
  async stream() {
    return (await remote_fetch(this)).body;
  }
  async csv(options) {
    return dsv(this, ",", options);
  }
  async tsv(options) {
    return dsv(this, "\t", options);
  }
  async image(props) {
    const url = await this.url();
    return new Promise((resolve, reject) => {
      const i = new Image();
      if (new URL(url, document.baseURI).origin !== new URL(location).origin) {
        i.crossOrigin = "anonymous";
      }
      Object.assign(i, props);
      i.onload = () => resolve(i);
      i.onerror = () => reject(new Error(`Unable to load file: ${this.name}`));
      i.src = url;
    });
  }
  async arrow() {
    const [Arrow, response] = await Promise.all([requireDefault(arrow.resolve()), remote_fetch(this)]);
    return Arrow.Table.from(response);
  }
  async sqlite() {
    return SQLiteDatabaseClient.open(remote_fetch(this));
  }
  async zip() {
    const [JSZip, buffer] = await Promise.all([requireDefault(jszip.resolve()), this.arrayBuffer()]);
    return new ZipArchive(await JSZip.loadAsync(buffer));
  }
  async xml(mimeType = "application/xml") {
    return (new DOMParser).parseFromString(await this.text(), mimeType);
  }
  async html() {
    return this.xml("text/html");
  }
  async xlsx() {
    const [ExcelJS, buffer] = await Promise.all([requireDefault(exceljs.resolve()), this.arrayBuffer()]);
    return new Workbook(await new ExcelJS.Workbook().xlsx.load(buffer));
  }
}

class FileAttachment extends AbstractFile {
  constructor(url, name, mimeType) {
    super(name, mimeType);
    Object.defineProperty(this, "_url", {value: url});
  }
  async url() {
    return (await this._url) + "";
  }
}

function NoFileAttachments(name) {
  throw new Error(`File not found: ${name}`);
}

class ZipArchive {
  constructor(archive) {
    Object.defineProperty(this, "_", {value: archive});
    this.filenames = Object.keys(archive.files).filter(name => !archive.files[name].dir);
  }
  file(path) {
    const object = this._.file(path += "");
    if (!object || object.dir) throw new Error(`file not found: ${path}`);
    return new ZipArchiveEntry(object);
  }
}

class ZipArchiveEntry extends AbstractFile {
  constructor(object) {
    super(object.name);
    Object.defineProperty(this, "_", {value: object});
    Object.defineProperty(this, "_url", {writable: true});
  }
  async url() {
    return this._url || (this._url = this.blob().then(URL.createObjectURL));
  }
  async blob() {
    return this._.async("blob");
  }
  async arrayBuffer() {
    return this._.async("arraybuffer");
  }
  async text() {
    return this._.async("text");
  }
  async json() {
    return JSON.parse(await this.text());
  }
}

function canvas(width, height) {
  var canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  return canvas;
}

function context2d(width, height, dpi) {
  if (dpi == null) dpi = devicePixelRatio;
  var canvas = document.createElement("canvas");
  canvas.width = width * dpi;
  canvas.height = height * dpi;
  canvas.style.width = width + "px";
  var context = canvas.getContext("2d");
  context.scale(dpi, dpi);
  return context;
}

function download(value, name = "untitled", label = "Save") {
  const a = document.createElement("a");
  const b = a.appendChild(document.createElement("button"));
  b.textContent = label;
  a.download = name;

  async function reset() {
    await new Promise(requestAnimationFrame);
    URL.revokeObjectURL(a.href);
    a.removeAttribute("href");
    b.textContent = label;
    b.disabled = false;
  }

  a.onclick = async event => {
    b.disabled = true;
    if (a.href) return reset(); // Already saved.
    b.textContent = "Saving…";
    try {
      const object = await (typeof value === "function" ? value() : value);
      b.textContent = "Download";
      a.href = URL.createObjectURL(object); // eslint-disable-line require-atomic-updates
    } catch (ignore) {
      b.textContent = label;
    }
    if (event.eventPhase) return reset(); // Already downloaded.
    b.disabled = false;
  };

  return a;
}

var namespaces = {
  math: "http://www.w3.org/1998/Math/MathML",
  svg: "http://www.w3.org/2000/svg",
  xhtml: "http://www.w3.org/1999/xhtml",
  xlink: "http://www.w3.org/1999/xlink",
  xml: "http://www.w3.org/XML/1998/namespace",
  xmlns: "http://www.w3.org/2000/xmlns/"
};

function element(name, attributes) {
  var prefix = name += "", i = prefix.indexOf(":"), value;
  if (i >= 0 && (prefix = name.slice(0, i)) !== "xmlns") name = name.slice(i + 1);
  var element = namespaces.hasOwnProperty(prefix) // eslint-disable-line no-prototype-builtins
      ? document.createElementNS(namespaces[prefix], name)
      : document.createElement(name);
  if (attributes) for (var key in attributes) {
    prefix = key, i = prefix.indexOf(":"), value = attributes[key];
    if (i >= 0 && (prefix = key.slice(0, i)) !== "xmlns") key = key.slice(i + 1);
    if (namespaces.hasOwnProperty(prefix)) element.setAttributeNS(namespaces[prefix], key, value); // eslint-disable-line no-prototype-builtins
    else element.setAttribute(key, value);
  }
  return element;
}

function input$1(type) {
  var input = document.createElement("input");
  if (type != null) input.type = type;
  return input;
}

function range$1(min, max, step) {
  if (arguments.length === 1) max = min, min = null;
  var input = document.createElement("input");
  input.min = min = min == null ? 0 : +min;
  input.max = max = max == null ? 1 : +max;
  input.step = step == null ? "any" : step = +step;
  input.type = "range";
  return input;
}

function select(values) {
  var select = document.createElement("select");
  Array.prototype.forEach.call(values, function(value) {
    var option = document.createElement("option");
    option.value = option.textContent = value;
    select.appendChild(option);
  });
  return select;
}

function svg$1(width, height) {
  var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", [0, 0, width, height]);
  svg.setAttribute("width", width);
  svg.setAttribute("height", height);
  return svg;
}

function text$1(value) {
  return document.createTextNode(value);
}

var count = 0;

function uid(name) {
  return new Id("O-" + (name == null ? "" : name + "-") + ++count);
}

function Id(id) {
  this.id = id;
  this.href = new URL(`#${id}`, location) + "";
}

Id.prototype.toString = function() {
  return "url(" + this.href + ")";
};

var DOM = {
  canvas: canvas,
  context2d: context2d,
  download: download,
  element: element,
  input: input$1,
  range: range$1,
  select: select,
  svg: svg$1,
  text: text$1,
  uid: uid
};

function buffer(file) {
  return new Promise(function(resolve, reject) {
    var reader = new FileReader;
    reader.onload = function() { resolve(reader.result); };
    reader.onerror = reject;
    reader.readAsArrayBuffer(file);
  });
}

function text(file) {
  return new Promise(function(resolve, reject) {
    var reader = new FileReader;
    reader.onload = function() { resolve(reader.result); };
    reader.onerror = reject;
    reader.readAsText(file);
  });
}

function url(file) {
  return new Promise(function(resolve, reject) {
    var reader = new FileReader;
    reader.onload = function() { resolve(reader.result); };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

var Files = {
  buffer: buffer,
  text: text,
  url: url
};

function that() {
  return this;
}

function disposable(value, dispose) {
  let done = false;
  if (typeof dispose !== "function") {
    throw new Error("dispose is not a function");
  }
  return {
    [Symbol.iterator]: that,
    next: () => done ? {done: true} : (done = true, {done: false, value}),
    return: () => (done = true, dispose(value), {done: true}),
    throw: () => ({done: done = true})
  };
}

function* filter$1(iterator, test) {
  var result, index = -1;
  while (!(result = iterator.next()).done) {
    if (test(result.value, ++index)) {
      yield result.value;
    }
  }
}

function observe(initialize) {
  let stale = false;
  let value;
  let resolve;
  const dispose = initialize(change);

  if (dispose != null && typeof dispose !== "function") {
    throw new Error(typeof dispose.then === "function"
        ? "async initializers are not supported"
        : "initializer returned something, but not a dispose function");
  }

  function change(x) {
    if (resolve) resolve(x), resolve = null;
    else stale = true;
    return value = x;
  }

  function next() {
    return {done: false, value: stale
        ? (stale = false, Promise.resolve(value))
        : new Promise(_ => (resolve = _))};
  }

  return {
    [Symbol.iterator]: that,
    throw: () => ({done: true}),
    return: () => (dispose != null && dispose(), {done: true}),
    next
  };
}

function input(input) {
  return observe(function(change) {
    var event = eventof(input), value = valueof(input);
    function inputted() { change(valueof(input)); }
    input.addEventListener(event, inputted);
    if (value !== undefined) change(value);
    return function() { input.removeEventListener(event, inputted); };
  });
}

function valueof(input) {
  switch (input.type) {
    case "range":
    case "number": return input.valueAsNumber;
    case "date": return input.valueAsDate;
    case "checkbox": return input.checked;
    case "file": return input.multiple ? input.files : input.files[0];
    case "select-multiple": return Array.from(input.selectedOptions, o => o.value);
    default: return input.value;
  }
}

function eventof(input) {
  switch (input.type) {
    case "button":
    case "submit":
    case "checkbox": return "click";
    case "file": return "change";
    default: return "input";
  }
}

function* map(iterator, transform) {
  var result, index = -1;
  while (!(result = iterator.next()).done) {
    yield transform(result.value, ++index);
  }
}

function queue$1(initialize) {
  let resolve;
  const queue = [];
  const dispose = initialize(push);

  if (dispose != null && typeof dispose !== "function") {
    throw new Error(typeof dispose.then === "function"
        ? "async initializers are not supported"
        : "initializer returned something, but not a dispose function");
  }

  function push(x) {
    queue.push(x);
    if (resolve) resolve(queue.shift()), resolve = null;
    return x;
  }

  function next() {
    return {done: false, value: queue.length
        ? Promise.resolve(queue.shift())
        : new Promise(_ => (resolve = _))};
  }

  return {
    [Symbol.iterator]: that,
    throw: () => ({done: true}),
    return: () => (dispose != null && dispose(), {done: true}),
    next
  };
}

function* range(start, stop, step) {
  start = +start;
  stop = +stop;
  step = (n = arguments.length) < 2 ? (stop = start, start = 0, 1) : n < 3 ? 1 : +step;
  var i = -1, n = Math.max(0, Math.ceil((stop - start) / step)) | 0;
  while (++i < n) {
    yield start + i * step;
  }
}

function valueAt(iterator, i) {
  if (!isFinite(i = +i) || i < 0 || i !== i | 0) return;
  var result, index = -1;
  while (!(result = iterator.next()).done) {
    if (++index === i) {
      return result.value;
    }
  }
}

function worker(source) {
  const url = URL.createObjectURL(new Blob([source], {type: "text/javascript"}));
  const worker = new Worker(url);
  return disposable(worker, () => {
    worker.terminate();
    URL.revokeObjectURL(url);
  });
}

var Generators = {
  disposable: disposable,
  filter: filter$1,
  input: input,
  map: map,
  observe: observe,
  queue: queue$1,
  range: range,
  valueAt: valueAt,
  worker: worker
};

function template(render, wrapper) {
  return function(strings) {
    var string = strings[0],
        parts = [], part,
        root = null,
        node, nodes,
        walker,
        i, n, j, m, k = -1;

    // Concatenate the text using comments as placeholders.
    for (i = 1, n = arguments.length; i < n; ++i) {
      part = arguments[i];
      if (part instanceof Node) {
        parts[++k] = part;
        string += "<!--o:" + k + "-->";
      } else if (Array.isArray(part)) {
        for (j = 0, m = part.length; j < m; ++j) {
          node = part[j];
          if (node instanceof Node) {
            if (root === null) {
              parts[++k] = root = document.createDocumentFragment();
              string += "<!--o:" + k + "-->";
            }
            root.appendChild(node);
          } else {
            root = null;
            string += node;
          }
        }
        root = null;
      } else {
        string += part;
      }
      string += strings[i];
    }

    // Render the text.
    root = render(string);

    // Walk the rendered content to replace comment placeholders.
    if (++k > 0) {
      nodes = new Array(k);
      walker = document.createTreeWalker(root, NodeFilter.SHOW_COMMENT, null, false);
      while (walker.nextNode()) {
        node = walker.currentNode;
        if (/^o:/.test(node.nodeValue)) {
          nodes[+node.nodeValue.slice(2)] = node;
        }
      }
      for (i = 0; i < k; ++i) {
        if (node = nodes[i]) {
          node.parentNode.replaceChild(parts[i], node);
        }
      }
    }

    // Is the rendered content
    // … a parent of a single child? Detach and return the child.
    // … a document fragment? Replace the fragment with an element.
    // … some other node? Return it.
    return root.childNodes.length === 1 ? root.removeChild(root.firstChild)
        : root.nodeType === 11 ? ((node = wrapper()).appendChild(root), node)
        : root;
  };
}

var html = template(function(string) {
  var template = document.createElement("template");
  template.innerHTML = string.trim();
  return document.importNode(template.content, true);
}, function() {
  return document.createElement("span");
});

async function leaflet(require) {
  const L = await require(leaflet$1.resolve());
  if (!L._style) {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = await require.resolve(leaflet$1.resolve("dist/leaflet.css"));
    L._style = document.head.appendChild(link);
  }
  return L;
}

function md(require) {
  return require(marked.resolve()).then(function(marked) {
    return template(
      function(string) {
        var root = document.createElement("div");
        root.innerHTML = marked(string, {langPrefix: ""}).trim();
        var code = root.querySelectorAll("pre code[class]");
        if (code.length > 0) {
          require(highlight.resolve()).then(function(hl) {
            code.forEach(function(block) {
              function done() {
                hl.highlightBlock(block);
                block.parentNode.classList.add("observablehq--md-pre");
              }
              if (hl.getLanguage(block.className)) {
                done();
              } else {
                require(highlight.resolve("async-languages/index.js"))
                  .then(index => {
                    if (index.has(block.className)) {
                      return require(highlight.resolve("async-languages/" + index.get(block.className))).then(language => {
                        hl.registerLanguage(block.className, language);
                      });
                    }
                  })
                  .then(done, done);
              }
            });
          });
        }
        return root;
      },
      function() {
        return document.createElement("div");
      }
    );
  });
}

async function mermaid(require) {
  const mer = await require(mermaid$1.resolve());
  mer.initialize({securityLevel: "loose", theme: "neutral"});
  return function mermaid() {
    const root = document.createElement("div");
    root.innerHTML = mer.render(uid().id, String.raw.apply(String, arguments));
    return root.removeChild(root.firstChild);
  };
}

function Mutable(value) {
  let change;
  Object.defineProperties(this, {
    generator: {value: observe(_ => void (change = _))},
    value: {get: () => value, set: x => change(value = x)} // eslint-disable-line no-setter-return
  });
  if (value !== undefined) change(value);
}

function* now$1() {
  while (true) {
    yield Date.now();
  }
}

function delay(duration, value) {
  return new Promise(function(resolve) {
    setTimeout(function() {
      resolve(value);
    }, duration);
  });
}

var timeouts = new Map;

function timeout(now, time) {
  var t = new Promise(function(resolve) {
    timeouts.delete(time);
    var delay = time - now;
    if (!(delay > 0)) throw new Error("invalid time");
    if (delay > 0x7fffffff) throw new Error("too long to wait");
    setTimeout(resolve, delay);
  });
  timeouts.set(time, t);
  return t;
}

function when(time, value) {
  var now;
  return (now = timeouts.get(time = +time)) ? now.then(() => value)
      : (now = Date.now()) >= time ? Promise.resolve(value)
      : timeout(now, time).then(() => value);
}

function tick(duration, value) {
  return when(Math.ceil((Date.now() + 1) / duration) * duration, value);
}

var Promises$1 = {
  delay: delay,
  tick: tick,
  when: when
};

function resolve$1(name, base) {
  if (/^(\w+:)|\/\//i.test(name)) return name;
  if (/^[.]{0,2}\//i.test(name)) return new URL(name, base == null ? location : base).href;
  if (!name.length || /^[\s._]/.test(name) || /\s$/.test(name)) throw new Error("illegal name");
  return "https://unpkg.com/" + name;
}

var svg = template(function(string) {
  var root = document.createElementNS("http://www.w3.org/2000/svg", "g");
  root.innerHTML = string.trim();
  return root;
}, function() {
  return document.createElementNS("http://www.w3.org/2000/svg", "g");
});

var raw = String.raw;

function style(href) {
  return new Promise(function(resolve, reject) {
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    link.onerror = reject;
    link.onload = resolve;
    document.head.appendChild(link);
  });
}

function tex(require) {
  return Promise.all([
    require(katex.resolve()),
    require.resolve(katex.resolve("dist/katex.min.css")).then(style)
  ]).then(function(values) {
    var katex = values[0], tex = renderer();

    function renderer(options) {
      return function() {
        var root = document.createElement("div");
        katex.render(raw.apply(String, arguments), root, options);
        return root.removeChild(root.firstChild);
      };
    }

    tex.options = renderer;
    tex.block = renderer({displayMode: true});
    return tex;
  });
}

async function vl(require) {
  const [v, vl, api] = await Promise.all([vega, vegalite, vegaliteApi].map(d => require(d.resolve())));
  return api.register(v, vl);
}

function width() {
  return observe(function(change) {
    var width = change(document.body.clientWidth);
    function resized() {
      var w = document.body.clientWidth;
      if (w !== width) change(width = w);
    }
    window.addEventListener("resize", resized);
    return function() {
      window.removeEventListener("resize", resized);
    };
  });
}

// These are copied from d3-array; TODO import once this package adopts type: module.

function descending(a, b) {
  return a == null || b == null ? NaN : b < a ? -1 : b > a ? 1 : b >= a ? 0 : NaN;
}

function ascending(a, b) {
  return a == null || b == null ? NaN : a < b ? -1 : a > b ? 1 : a >= b ? 0 : NaN;
}

function reverse(values) {
  if (typeof values[Symbol.iterator] !== "function") throw new TypeError("values is not iterable");
  return Array.from(values).reverse();
}

const nChecks = 20; // number of values to check in each array

// We support two levels of DatabaseClient. The simplest DatabaseClient
// implements only the client.sql tagged template literal. More advanced
// DatabaseClients implement client.query and client.queryStream, which support
// streaming and abort, and the client.queryTag tagged template literal is used
// to translate the contents of a SQL cell or Table cell into the appropriate
// arguments for calling client.query or client.queryStream. For table cells, we
// additionally require client.describeColumns. The client.describeTables method
// is optional.
function isDatabaseClient(value, mode) {
  return (
    value &&
    (typeof value.sql === "function" ||
      (typeof value.queryTag === "function" &&
        (typeof value.query === "function" ||
          typeof value.queryStream === "function"))) &&
    (mode !== "table") &&
    value !== __query // don’t match our internal helper
  );
}

// Returns true if the value is a typed array (for a single-column table), or if
// it’s an array. In the latter case, the elements of the array must be
// consistently typed: either plain objects or primitives or dates.
function isDataArray(value) {
  return (
    (Array.isArray(value) &&
      (isQueryResultSetSchema(value.schema) ||
        isQueryResultSetColumns(value.columns) ||
        arrayContainsObjects(value) ||
        arrayContainsPrimitives(value) ||
        arrayContainsDates(value))) ||
    isTypedArray(value)
  );
}

// Given an array, checks that the given value is an array that does not contain
// any primitive values (at least for the first few values that we check), and
// that the first object contains enumerable keys (see computeSchema for how we
// infer the columns). We assume that the contents of the table are homogenous,
// but we don’t currently enforce this.
// https://observablehq.com/@observablehq/database-client-specification#§1
function arrayContainsObjects(value) {
  const n = Math.min(nChecks, value.length);
  for (let i = 0; i < n; ++i) {
    const v = value[i];
    if (v === null || typeof v !== "object") return false;
  }
  return n > 0 && objectHasEnumerableKeys(value[0]);
}

// Using a for-in loop here means that we can abort after finding at least one
// enumerable key (whereas Object.keys would require materializing the array of
// all keys, which would be considerably slower if the value has many keys!).
// This function assumes that value is an object; see arrayContainsObjects.
function objectHasEnumerableKeys(value) {
  for (const _ in value) return true;
  return false;
}

function isQueryResultSetSchema(schemas) {
  return (Array.isArray(schemas) && schemas.every((s) => s && typeof s.name === "string"));
}

function isQueryResultSetColumns(columns) {
  return (Array.isArray(columns) && columns.every((name) => typeof name === "string"));
}

// Returns true if the value represents an array of primitives (i.e., a
// single-column table). This should only be passed values for which
// isDataArray returns true.
function arrayIsPrimitive(value) {
  return (
    isTypedArray(value) ||
    arrayContainsPrimitives(value) ||
    arrayContainsDates(value)
  );
}

// Given an array, checks that the first n elements are primitives (number,
// string, boolean, bigint) of a consistent type.
function arrayContainsPrimitives(value) {
  const n = Math.min(nChecks, value.length);
  if (!(n > 0)) return false;
  let type;
  let hasPrimitive = false; // ensure we encounter 1+ primitives
  for (let i = 0; i < n; ++i) {
    const v = value[i];
    if (v == null) continue; // ignore null and undefined
    const t = typeof v;
    if (type === undefined) {
      switch (t) {
        case "number":
        case "boolean":
        case "string":
        case "bigint":
          type = t;
          break;
        default:
          return false;
      }
    } else if (t !== type) {
      return false;
    }
    hasPrimitive = true;
  }
  return hasPrimitive;
}

// Given an array, checks that the first n elements are dates.
function arrayContainsDates(value) {
  const n = Math.min(nChecks, value.length);
  if (!(n > 0)) return false;
  let hasDate = false; // ensure we encounter 1+ dates
  for (let i = 0; i < n; ++i) {
    const v = value[i];
    if (v == null) continue; // ignore null and undefined
    if (!(v instanceof Date)) return false;
    hasDate = true;
  }
  return hasDate;
}

function isTypedArray(value) {
  return (
    value instanceof Int8Array ||
    value instanceof Int16Array ||
    value instanceof Int32Array ||
    value instanceof Uint8Array ||
    value instanceof Uint8ClampedArray ||
    value instanceof Uint16Array ||
    value instanceof Uint32Array ||
    value instanceof Float32Array ||
    value instanceof Float64Array
  );
}

// __query is used by table cells; __query.sql is used by SQL cells.
const __query = Object.assign(
  async (source, operations, invalidation) => {
    source = await loadDataSource(await source, "table");
    if (isDatabaseClient(source)) return evaluateQuery(source, makeQueryTemplate(operations, source), invalidation);
    if (isDataArray(source)) return __table(source, operations);
    if (!source) throw new Error("missing data source");
    throw new Error("invalid data source");
  },
  {
    sql(source, invalidation) {
      return async function () {
        return evaluateQuery(await loadDataSource(await source, "sql"), arguments, invalidation);
      };
    }
  }
);

async function loadDataSource(source, mode) {
  if (source instanceof FileAttachment) {
    if (mode === "table") {
      switch (source.mimeType) {
        case "text/csv": return source.csv({typed: true});
        case "text/tab-separated-values": return source.tsv({typed: true});
        case "application/json": return source.json();
      }
    }
    if (mode === "table" || mode === "sql") {
      switch (source.mimeType) {
        case "application/x-sqlite3": return source.sqlite();
      }
    }
    throw new Error(`unsupported file type: ${source.mimeType}`);
  }
  return source;
}

async function evaluateQuery(source, args, invalidation) {
  if (!source) throw new Error("missing data source");

  // If this DatabaseClient supports abort and streaming, use that.
  if (typeof source.queryTag === "function") {
    const abortController = new AbortController();
    const options = {signal: abortController.signal};
    invalidation.then(() => abortController.abort("invalidated"));
    if (typeof source.queryStream === "function") {
      return accumulateQuery(
        source.queryStream(...source.queryTag.apply(source, args), options)
      );
    }
    if (typeof source.query === "function") {
      return source.query(...source.queryTag.apply(source, args), options);
    }
  }

  // Otherwise, fallback to the basic sql tagged template literal.
  if (typeof source.sql === "function") {
    return source.sql.apply(source, args);
  }

  // TODO: test if source is a file attachment, and support CSV etc.
  throw new Error("source does not implement query, queryStream, or sql");
}

// Generator function that yields accumulated query results client.queryStream
async function* accumulateQuery(queryRequest) {
  const queryResponse = await queryRequest;
  const values = [];
  values.done = false;
  values.error = null;
  values.schema = queryResponse.schema;
  try {
    const iterator = queryResponse.readRows();
    do {
      const result = await iterator.next();
      if (result.done) {
        values.done = true;
      } else {
        for (const value of result.value) {
          values.push(value);
        }
      }
      yield values;
    } while (!values.done);
  } catch (error) {
    values.error = error;
    yield values;
  }
}

/**
 * Returns a SQL query in the form [[parts], ...params] where parts is an array
 * of sub-strings and params are the parameter values to be inserted between each
 * sub-string.
 */
function makeQueryTemplate(operations, source) {
  const escaper =
    typeof source.escape === "function" ? source.escape : (i) => i;
  const {select, from, filter, sort, slice} = operations;
  if (!from.table)
    throw new Error("missing from table");
  if (select.columns && select.columns.length === 0)
    throw new Error("at least one column must be selected");
  const columns = select.columns ? select.columns.map((c) => `t.${escaper(c)}`) : "*";
  const args = [
    [`SELECT ${columns} FROM ${formatTable(from.table, escaper)} t`]
  ];
  for (let i = 0; i < filter.length; ++i) {
    appendSql(i ? `\nAND ` : `\nWHERE `, args);
    appendWhereEntry(filter[i], args, escaper);
  }
  for (let i = 0; i < sort.length; ++i) {
    appendSql(i ? `, ` : `\nORDER BY `, args);
    appendOrderBy(sort[i], args, escaper);
  }
  if (source.dialect === "mssql") {
    if (slice.to !== null || slice.from !== null) {
      if (!sort.length) {
        if (!select.columns)
          throw new Error(
              "at least one column must be explicitly specified. Received '*'."
          );
        appendSql(`\nORDER BY `, args);
        appendOrderBy(
          {column: select.columns[0], direction: "ASC"},
          args,
          escaper
        );
      }
      appendSql(`\nOFFSET ${slice.from || 0} ROWS`, args);
      appendSql(
        `\nFETCH NEXT ${
          slice.to !== null ? slice.to - (slice.from || 0) : 1e9
        } ROWS ONLY`,
        args
      );
    }
  } else {
    if (slice.to !== null || slice.from !== null) {
      appendSql(
        `\nLIMIT ${slice.to !== null ? slice.to - (slice.from || 0) : 1e9}`,
        args
      );
    }
    if (slice.from !== null) {
      appendSql(` OFFSET ${slice.from}`, args);
    }
  }
  return args;
}

function formatTable(table, escaper) {
  if (typeof table === "object") { // i.e., not a bare string specifier
    let from = "";
    if (table.database != null) from += escaper(table.database) + ".";
    if (table.schema != null) from += escaper(table.schema) + ".";
    from += escaper(table.table);
    return from;
  }
  return table;
}

function appendSql(sql, args) {
  const strings = args[0];
  strings[strings.length - 1] += sql;
}

function appendOrderBy({column, direction}, args, escaper) {
  appendSql(`t.${escaper(column)} ${direction.toUpperCase()}`, args);
}

function appendWhereEntry({type, operands}, args, escaper) {
  if (operands.length < 1) throw new Error("Invalid operand length");

  // Unary operations
  if (operands.length === 1) {
    appendOperand(operands[0], args, escaper);
    switch (type) {
      case "n":
        appendSql(` IS NULL`, args);
        return;
      case "nn":
        appendSql(` IS NOT NULL`, args);
        return;
      default:
        throw new Error("Invalid filter operation");
    }
  }

  // Binary operations
  if (operands.length === 2) {
    if (["in", "nin"].includes(type)) ; else if (["c", "nc"].includes(type)) {
      // TODO: Case (in)sensitive?
      appendOperand(operands[0], args, escaper);
      switch (type) {
        case "c":
          appendSql(` LIKE `, args);
          break;
        case "nc":
          appendSql(` NOT LIKE `, args);
          break;
      }
      appendOperand(likeOperand(operands[1]), args, escaper);
      return;
    } else {
      appendOperand(operands[0], args, escaper);
      switch (type) {
        case "eq":
          appendSql(` = `, args);
          break;
        case "ne":
          appendSql(` <> `, args);
          break;
        case "gt":
          appendSql(` > `, args);
          break;
        case "lt":
          appendSql(` < `, args);
          break;
        case "gte":
          appendSql(` >= `, args);
          break;
        case "lte":
          appendSql(` <= `, args);
          break;
        default:
          throw new Error("Invalid filter operation");
      }
      appendOperand(operands[1], args, escaper);
      return;
    }
  }

  // List operations
  appendOperand(operands[0], args, escaper);
  switch (type) {
    case "in":
      appendSql(` IN (`, args);
      break;
    case "nin":
      appendSql(` NOT IN (`, args);
      break;
    default:
      throw new Error("Invalid filter operation");
  }
  appendListOperands(operands.slice(1), args);
  appendSql(")", args);
}

function appendOperand(o, args, escaper) {
  if (o.type === "column") {
    appendSql(`t.${escaper(o.value)}`, args);
  } else {
    args.push(o.value);
    args[0].push("");
  }
}

// TODO: Support column operands here?
function appendListOperands(ops, args) {
  let first = true;
  for (const op of ops) {
    if (first) first = false;
    else appendSql(",", args);
    args.push(op.value);
    args[0].push("");
  }
}

function likeOperand(operand) {
  return {...operand, value: `%${operand.value}%`};
}

// This function applies table cell operations to an in-memory table (array of
// objects); it should be equivalent to the corresponding SQL query.
function __table(source, operations) {
  const input = source;
  let {schema, columns} = source;
  let primitive = arrayIsPrimitive(source);
  if (primitive) source = Array.from(source, (value) => ({value}));
  for (const {type, operands} of operations.filter) {
    const [{value: column}] = operands;
    const values = operands.slice(1).map(({value}) => value);
    switch (type) {
      case "eq": {
        const [value] = values;
        if (value instanceof Date) {
          const time = +value; // compare as primitive
          source = source.filter((d) => +d[column] === time);
        } else {
          source = source.filter((d) => d[column] === value);
        }
        break;
      }
      case "ne": {
        const [value] = values;
        source = source.filter((d) => d[column] !== value);
        break;
      }
      case "c": {
        const [value] = values;
        source = source.filter(
          (d) => typeof d[column] === "string" && d[column].includes(value)
        );
        break;
      }
      case "nc": {
        const [value] = values;
        source = source.filter(
          (d) => typeof d[column] === "string" && !d[column].includes(value)
        );
        break;
      }
      case "in": {
        const set = new Set(values); // TODO support dates?
        source = source.filter((d) => set.has(d[column]));
        break;
      }
      case "nin": {
        const set = new Set(values); // TODO support dates?
        source = source.filter((d) => !set.has(d[column]));
        break;
      }
      case "n": {
        source = source.filter((d) => d[column] == null);
        break;
      }
      case "nn": {
        source = source.filter((d) => d[column] != null);
        break;
      }
      case "lt": {
        const [value] = values;
        source = source.filter((d) => d[column] < value);
        break;
      }
      case "lte": {
        const [value] = values;
        source = source.filter((d) => d[column] <= value);
        break;
      }
      case "gt": {
        const [value] = values;
        source = source.filter((d) => d[column] > value);
        break;
      }
      case "gte": {
        const [value] = values;
        source = source.filter((d) => d[column] >= value);
        break;
      }
      default:
        throw new Error(`unknown filter type: ${type}`);
    }
  }
  for (const {column, direction} of reverse(operations.sort)) {
    const compare = direction === "desc" ? descending : ascending;
    if (source === input) source = source.slice(); // defensive copy
    source.sort((a, b) => compare(a[column], b[column]));
  }
  let {from, to} = operations.slice;
  from = from == null ? 0 : Math.max(0, from);
  to = to == null ? Infinity : Math.max(0, to);
  if (from > 0 || to < Infinity) {
    source = source.slice(Math.max(0, from), Math.max(0, to));
  }
  if (operations.select.columns) {
    if (schema) {
      const schemaByName = new Map(schema.map((s) => [s.name, s]));
      schema = operations.select.columns.map((c) => schemaByName.get(c));
    }
    if (columns) {
      columns = operations.select.columns;
    }
    source = source.map((d) =>
      Object.fromEntries(operations.select.columns.map((c) => [c, d[c]]))
    );
  }
  if (primitive) source = source.map((d) => d.value);
  if (source !== input) {
    if (schema) source.schema = schema;
    if (columns) source.columns = columns;
  }
  return source;
}

var Library = Object.assign(Object.defineProperties(function Library(resolver) {
  const require = requirer(resolver);
  Object.defineProperties(this, properties({
    FileAttachment: () => NoFileAttachments,
    Mutable: () => Mutable,
    now: now$1,
    width,

    // Tagged template literals
    dot: () => require(graphviz.resolve()),
    htl: () => require(htl.resolve()),
    html: () => html,
    md: () => md(require),
    svg: () => svg,
    tex: () => tex(require),

    // Recommended libraries
    // https://observablehq.com/@observablehq/recommended-libraries
    _: () => require(lodash.resolve()),
    aq: () => require.alias({"apache-arrow": arrow.resolve()})(arquero.resolve()),
    Arrow: () => require(arrow.resolve()),
    d3: () => require(d3.resolve()),
    Inputs: () => require(inputs.resolve()).then(Inputs => ({...Inputs, file: Inputs.fileOf(AbstractFile)})),
    L: () => leaflet(require),
    mermaid: () => mermaid(require),
    Plot: () => require(plot.resolve()),
    __query: () => __query,
    require: () => require,
    resolve: () => resolve$1, // deprecated; use async require.resolve instead
    SQLite: () => sqlite(require),
    SQLiteDatabaseClient: () => SQLiteDatabaseClient,
    topojson: () => require(topojson.resolve()),
    vl: () => vl(require),

    // Sample datasets
    // https://observablehq.com/@observablehq/datasets
    aapl: () => new FileAttachment("https://static.observableusercontent.com/files/3ccff97fd2d93da734e76829b2b066eafdaac6a1fafdec0faf6ebc443271cfc109d29e80dd217468fcb2aff1e6bffdc73f356cc48feb657f35378e6abbbb63b9").csv({typed: true}),
    alphabet: () => new FileAttachment("https://static.observableusercontent.com/files/75d52e6c3130b1cae83cda89305e17b50f33e7420ef205587a135e8562bcfd22e483cf4fa2fb5df6dff66f9c5d19740be1cfaf47406286e2eb6574b49ffc685d").csv({typed: true}),
    cars: () => new FileAttachment("https://static.observableusercontent.com/files/048ec3dfd528110c0665dfa363dd28bc516ffb7247231f3ab25005036717f5c4c232a5efc7bb74bc03037155cb72b1abe85a33d86eb9f1a336196030443be4f6").csv({typed: true}),
    citywages: () => new FileAttachment("https://static.observableusercontent.com/files/39837ec5121fcc163131dbc2fe8c1a2e0b3423a5d1e96b5ce371e2ac2e20a290d78b71a4fb08b9fa6a0107776e17fb78af313b8ea70f4cc6648fad68ddf06f7a").csv({typed: true}),
    diamonds: () => new FileAttachment("https://static.observableusercontent.com/files/87942b1f5d061a21fa4bb8f2162db44e3ef0f7391301f867ab5ba718b225a63091af20675f0bfe7f922db097b217b377135203a7eab34651e21a8d09f4e37252").csv({typed: true}),
    flare: () => new FileAttachment("https://static.observableusercontent.com/files/a6b0d94a7f5828fd133765a934f4c9746d2010e2f342d335923991f31b14120de96b5cb4f160d509d8dc627f0107d7f5b5070d2516f01e4c862b5b4867533000").csv({typed: true}),
    industries: () => new FileAttachment("https://static.observableusercontent.com/files/76f13741128340cc88798c0a0b7fa5a2df8370f57554000774ab8ee9ae785ffa2903010cad670d4939af3e9c17e5e18e7e05ed2b38b848ac2fc1a0066aa0005f").csv({typed: true}),
    miserables: () => new FileAttachment("https://static.observableusercontent.com/files/31d904f6e21d42d4963ece9c8cc4fbd75efcbdc404bf511bc79906f0a1be68b5a01e935f65123670ed04e35ca8cae3c2b943f82bf8db49c5a67c85cbb58db052").json(),
    olympians: () => new FileAttachment("https://static.observableusercontent.com/files/31ca24545a0603dce099d10ee89ee5ae72d29fa55e8fc7c9ffb5ded87ac83060d80f1d9e21f4ae8eb04c1e8940b7287d179fe8060d887fb1f055f430e210007c").csv({typed: true}),
    penguins: () => new FileAttachment("https://static.observableusercontent.com/files/715db1223e067f00500780077febc6cebbdd90c151d3d78317c802732252052ab0e367039872ab9c77d6ef99e5f55a0724b35ddc898a1c99cb14c31a379af80a").csv({typed: true}),
    weather: () => new FileAttachment("https://static.observableusercontent.com/files/693a46b22b33db0f042728700e0c73e836fa13d55446df89120682d55339c6db7cc9e574d3d73f24ecc9bc7eb9ac9a1e7e104a1ee52c00aab1e77eb102913c1f").csv({typed: true}),

    // Note: these are namespace objects, and thus exposed directly rather than
    // being wrapped in a function. This allows library.Generators to resolve,
    // rather than needing module.value.
    DOM,
    Files,
    Generators,
    Promises: Promises$1
  }));
}, {
  resolve: {
    get: () => requireDefault.resolve,
    enumerable: true,
    configurable: true
  },
  require: {
    get: () => requireDefault,
    set: setDefaultRequire,
    enumerable: true,
    configurable: true
  }
}), {
  resolveFrom,
  requireFrom
});

function properties(values) {
  return Object.fromEntries(Object.entries(values).map(property));
}

function property([key, value]) {
  return [key, ({value, writable: true, enumerable: true})];
}

// @ts-ignore

const make_library = () => {
    // @ts-ignore
    const library = new Library();
    return {
        DOM: library.DOM,
        Files: library.Files,
        Generators: library.Generators,
        Promises: library.Promises,
        now: library.now,
        svg: library.svg(),
        html: library.html(),
        require: library.require(),
    }

    // TODO
    // observablehq.md and observablehq.tex will call d3-require, which will create a conflict if something else is using d3-require
    // in particular, plotly.js will break

    // observablehq.md(observablehq.require()).then((md) => (observablehq_exports.md = md))
    // observablehq.tex().then(tex => observablehq_exports.tex = tex)
};

// We use two different observable stdlib instances: one for ourselves and one for the JS code in cell outputs
const observablehq_for_myself = make_library();
make_library();
const Promises = observablehq_for_myself.Promises;

const msgpack = ((silly_function) => silly_function())(function(){return function t(r,e,n){function i(f,u){if(!e[f]){if(!r[f]){var a="function"==typeof require&&require;if(!u&&a)return a(f,true);if(o)return o(f,true);var s=new Error("Cannot find module '"+f+"'");throw s.code="MODULE_NOT_FOUND",s}var c=e[f]={exports:{}};r[f][0].call(c.exports,function(t){var e=r[f][1][t];return i(e?e:t)},c,c.exports,t,r,e,n);}return e[f].exports}for(var o="function"==typeof require&&require,f=0;f<n.length;f++)i(n[f]);return i}({1:[function(t,r,e){e.encode=t("./encode").encode,e.decode=t("./decode").decode,e.Encoder=t("./encoder").Encoder,e.Decoder=t("./decoder").Decoder,e.createCodec=t("./ext").createCodec,e.codec=t("./codec").codec;},{"./codec":10,"./decode":12,"./decoder":13,"./encode":15,"./encoder":16,"./ext":20}],2:[function(t,r,e){(function(Buffer){function t(t){return t&&t.isBuffer&&t}r.exports=t("undefined"!=typeof Buffer&&Buffer)||t(this.Buffer)||t("undefined"!=typeof window&&window.Buffer)||this.Buffer;}).call(this,t("buffer").Buffer);},{buffer:29}],3:[function(t,r,e){function n(t,r){for(var e=this,n=r||(r|=0),i=t.length,o=0,f=0;f<i;)o=t.charCodeAt(f++),o<128?e[n++]=o:o<2048?(e[n++]=192|o>>>6,e[n++]=128|63&o):o<55296||o>57343?(e[n++]=224|o>>>12,e[n++]=128|o>>>6&63,e[n++]=128|63&o):(o=(o-55296<<10|t.charCodeAt(f++)-56320)+65536,e[n++]=240|o>>>18,e[n++]=128|o>>>12&63,e[n++]=128|o>>>6&63,e[n++]=128|63&o);return n-r}function i(t,r,e){var n=this,i=0|r;e||(e=n.length);for(var o="",f=0;i<e;)f=n[i++],f<128?o+=String.fromCharCode(f):(192===(224&f)?f=(31&f)<<6|63&n[i++]:224===(240&f)?f=(15&f)<<12|(63&n[i++])<<6|63&n[i++]:240===(248&f)&&(f=(7&f)<<18|(63&n[i++])<<12|(63&n[i++])<<6|63&n[i++]),f>=65536?(f-=65536,o+=String.fromCharCode((f>>>10)+55296,(1023&f)+56320)):o+=String.fromCharCode(f));return o}function o(t,r,e,n){var i;e||(e=0),n||0===n||(n=this.length),r||(r=0);var o=n-e;if(t===this&&e<r&&r<n)for(i=o-1;i>=0;i--)t[i+r]=this[i+e];else for(i=0;i<o;i++)t[i+r]=this[i+e];return o}e.copy=o,e.toString=i,e.write=n;},{}],4:[function(t,r,e){function n(t){return new Array(t)}function i(t){if(!o.isBuffer(t)&&o.isView(t))t=o.Uint8Array.from(t);else if(o.isArrayBuffer(t))t=new Uint8Array(t);else {if("string"==typeof t)return o.from.call(e,t);if("number"==typeof t)throw new TypeError('"value" argument must not be a number')}return Array.prototype.slice.call(t)}var o=t("./bufferish"),e=r.exports=n(0);e.alloc=n,e.concat=o.concat,e.from=i;},{"./bufferish":8}],5:[function(t,r,e){function n(t){return new Buffer(t)}function i(t){if(!o.isBuffer(t)&&o.isView(t))t=o.Uint8Array.from(t);else if(o.isArrayBuffer(t))t=new Uint8Array(t);else {if("string"==typeof t)return o.from.call(e,t);if("number"==typeof t)throw new TypeError('"value" argument must not be a number')}return Buffer.from&&1!==Buffer.from.length?Buffer.from(t):new Buffer(t)}var o=t("./bufferish"),Buffer=o.global,e=r.exports=o.hasBuffer?n(0):[];e.alloc=o.hasBuffer&&Buffer.alloc||n,e.concat=o.concat,e.from=i;},{"./bufferish":8}],6:[function(t,r,e){function n(t,r,e,n){var o=a.isBuffer(this),f=a.isBuffer(t);if(o&&f)return this.copy(t,r,e,n);if(c||o||f||!a.isView(this)||!a.isView(t))return u.copy.call(this,t,r,e,n);var s=e||null!=n?i.call(this,e,n):this;return t.set(s,r),s.length}function i(t,r){var e=this.slice||!c&&this.subarray;if(e)return e.call(this,t,r);var i=a.alloc.call(this,r-t);return n.call(this,i,0,t,r),i}function o(t,r,e){var n=!s&&a.isBuffer(this)?this.toString:u.toString;return n.apply(this,arguments)}function f(t){function r(){var r=this[t]||u[t];return r.apply(this,arguments)}return r}var u=t("./buffer-lite");e.copy=n,e.slice=i,e.toString=o,e.write=f("write");var a=t("./bufferish"),Buffer=a.global,s=a.hasBuffer&&"TYPED_ARRAY_SUPPORT"in Buffer,c=s&&!Buffer.TYPED_ARRAY_SUPPORT;},{"./buffer-lite":3,"./bufferish":8}],7:[function(t,r,e){function n(t){return new Uint8Array(t)}function i(t){if(o.isView(t)){var r=t.byteOffset,n=t.byteLength;t=t.buffer,t.byteLength!==n&&(t.slice?t=t.slice(r,r+n):(t=new Uint8Array(t),t.byteLength!==n&&(t=Array.prototype.slice.call(t,r,r+n))));}else {if("string"==typeof t)return o.from.call(e,t);if("number"==typeof t)throw new TypeError('"value" argument must not be a number')}return new Uint8Array(t)}var o=t("./bufferish"),e=r.exports=o.hasArrayBuffer?n(0):[];e.alloc=n,e.concat=o.concat,e.from=i;},{"./bufferish":8}],8:[function(t,r,e){function n(t){return "string"==typeof t?u.call(this,t):a(this).from(t)}function i(t){return a(this).alloc(t)}function o(t,r){function n(t){r+=t.length;}function o(t){a+=w.copy.call(t,u,a);}r||(r=0,Array.prototype.forEach.call(t,n));var f=this!==e&&this||t[0],u=i.call(f,r),a=0;return Array.prototype.forEach.call(t,o),u}function f(t){return t instanceof ArrayBuffer||E(t)}function u(t){var r=3*t.length,e=i.call(this,r),n=w.write.call(e,t);return r!==n&&(e=w.slice.call(e,0,n)),e}function a(t){return d(t)?g:y(t)?b:p(t)?v:h?g:l?b:v}function s(){return  false}function c(t,r){return t="[object "+t+"]",function(e){return null!=e&&{}.toString.call(r?e[r]:e)===t}}var Buffer=e.global=t("./buffer-global"),h=e.hasBuffer=Buffer&&!!Buffer.isBuffer,l=e.hasArrayBuffer="undefined"!=typeof ArrayBuffer,p=e.isArray=t("isarray");e.isArrayBuffer=l?f:s;var d=e.isBuffer=h?Buffer.isBuffer:s,y=e.isView=l?ArrayBuffer.isView||c("ArrayBuffer","buffer"):s;e.alloc=i,e.concat=o,e.from=n;var v=e.Array=t("./bufferish-array"),g=e.Buffer=t("./bufferish-buffer"),b=e.Uint8Array=t("./bufferish-uint8array"),w=e.prototype=t("./bufferish-proto"),E=c("ArrayBuffer");},{"./buffer-global":2,"./bufferish-array":4,"./bufferish-buffer":5,"./bufferish-proto":6,"./bufferish-uint8array":7,isarray:34}],9:[function(t,r,e){function n(t){return this instanceof n?(this.options=t,void this.init()):new n(t)}function i(t){for(var r in t)n.prototype[r]=o(n.prototype[r],t[r]);}function o(t,r){function e(){return t.apply(this,arguments),r.apply(this,arguments)}return t&&r?e:t||r}function f(t){function r(t,r){return r(t)}return t=t.slice(),function(e){return t.reduce(r,e)}}function u(t){return s(t)?f(t):t}function a(t){return new n(t)}var s=t("isarray");e.createCodec=a,e.install=i,e.filter=u;var c=t("./bufferish");n.prototype.init=function(){var t=this.options;return t&&t.uint8array&&(this.bufferish=c.Uint8Array),this},e.preset=a({preset:true});},{"./bufferish":8,isarray:34}],10:[function(t,r,e){t("./read-core"),t("./write-core"),e.codec={preset:t("./codec-base").preset};},{"./codec-base":9,"./read-core":22,"./write-core":25}],11:[function(t,r,e){function n(t){if(!(this instanceof n))return new n(t);if(t&&(this.options=t,t.codec)){var r=this.codec=t.codec;r.bufferish&&(this.bufferish=r.bufferish);}}e.DecodeBuffer=n;var i=t("./read-core").preset,o=t("./flex-buffer").FlexDecoder;o.mixin(n.prototype),n.prototype.codec=i,n.prototype.fetch=function(){return this.codec.decode(this)};},{"./flex-buffer":21,"./read-core":22}],12:[function(t,r,e){function n(t,r){var e=new i(r);return e.write(t),e.read()}e.decode=n;var i=t("./decode-buffer").DecodeBuffer;},{"./decode-buffer":11}],13:[function(t,r,e){function n(t){return this instanceof n?void o.call(this,t):new n(t)}e.Decoder=n;var i=t("event-lite"),o=t("./decode-buffer").DecodeBuffer;n.prototype=new o,i.mixin(n.prototype),n.prototype.decode=function(t){arguments.length&&this.write(t),this.flush();},n.prototype.push=function(t){this.emit("data",t);},n.prototype.end=function(t){this.decode(t),this.emit("end");};},{"./decode-buffer":11,"event-lite":31}],14:[function(t,r,e){function n(t){if(!(this instanceof n))return new n(t);if(t&&(this.options=t,t.codec)){var r=this.codec=t.codec;r.bufferish&&(this.bufferish=r.bufferish);}}e.EncodeBuffer=n;var i=t("./write-core").preset,o=t("./flex-buffer").FlexEncoder;o.mixin(n.prototype),n.prototype.codec=i,n.prototype.write=function(t){this.codec.encode(this,t);};},{"./flex-buffer":21,"./write-core":25}],15:[function(t,r,e){function n(t,r){var e=new i(r);return e.write(t),e.read()}e.encode=n;var i=t("./encode-buffer").EncodeBuffer;},{"./encode-buffer":14}],16:[function(t,r,e){function n(t){return this instanceof n?void o.call(this,t):new n(t)}e.Encoder=n;var i=t("event-lite"),o=t("./encode-buffer").EncodeBuffer;n.prototype=new o,i.mixin(n.prototype),n.prototype.encode=function(t){this.write(t),this.emit("data",this.read());},n.prototype.end=function(t){arguments.length&&this.encode(t),this.flush(),this.emit("end");};},{"./encode-buffer":14,"event-lite":31}],17:[function(t,r,e){function n(t,r){return this instanceof n?(this.buffer=i.from(t),void(this.type=r)):new n(t,r)}e.ExtBuffer=n;var i=t("./bufferish");},{"./bufferish":8}],18:[function(t,r,e){function n(t){t.addExtPacker(14,Error,[u,i]),t.addExtPacker(1,EvalError,[u,i]),t.addExtPacker(2,RangeError,[u,i]),t.addExtPacker(3,ReferenceError,[u,i]),t.addExtPacker(4,SyntaxError,[u,i]),t.addExtPacker(5,TypeError,[u,i]),t.addExtPacker(6,URIError,[u,i]),t.addExtPacker(10,RegExp,[f,i]),t.addExtPacker(11,Boolean,[o,i]),t.addExtPacker(12,String,[o,i]),t.addExtPacker(13,Date,[Number,i]),t.addExtPacker(15,Number,[o,i]),"undefined"!=typeof Uint8Array&&(t.addExtPacker(17,Int8Array,c),t.addExtPacker(18,Uint8Array,c),t.addExtPacker(19,Int16Array,c),t.addExtPacker(20,Uint16Array,c),t.addExtPacker(21,Int32Array,c),t.addExtPacker(22,Uint32Array,c),t.addExtPacker(23,Float32Array,c),"undefined"!=typeof Float64Array&&t.addExtPacker(24,Float64Array,c),"undefined"!=typeof Uint8ClampedArray&&t.addExtPacker(25,Uint8ClampedArray,c),t.addExtPacker(26,ArrayBuffer,c),t.addExtPacker(29,DataView,c)),s.hasBuffer&&t.addExtPacker(27,Buffer,s.from);}function i(r){return a||(a=t("./encode").encode),a(r)}function o(t){return t.valueOf()}function f(t){t=RegExp.prototype.toString.call(t).split("/"),t.shift();var r=[t.pop()];return r.unshift(t.join("/")),r}function u(t){var r={};for(var e in h)r[e]=t[e];return r}e.setExtPackers=n;var a,s=t("./bufferish"),Buffer=s.global,c=s.Uint8Array.from,h={name:1,message:1,stack:1,columnNumber:1,fileName:1,lineNumber:1};},{"./bufferish":8,"./encode":15}],19:[function(t,r,e){function n(t){t.addExtUnpacker(14,[i,f(Error)]),t.addExtUnpacker(1,[i,f(EvalError)]),t.addExtUnpacker(2,[i,f(RangeError)]),t.addExtUnpacker(3,[i,f(ReferenceError)]),t.addExtUnpacker(4,[i,f(SyntaxError)]),t.addExtUnpacker(5,[i,f(TypeError)]),t.addExtUnpacker(6,[i,f(URIError)]),t.addExtUnpacker(10,[i,o]),t.addExtUnpacker(11,[i,u(Boolean)]),t.addExtUnpacker(12,[i,u(String)]),t.addExtUnpacker(13,[i,u(Date)]),t.addExtUnpacker(15,[i,u(Number)]),"undefined"!=typeof Uint8Array&&(t.addExtUnpacker(17,u(Int8Array)),t.addExtUnpacker(18,u(Uint8Array)),t.addExtUnpacker(19,[a,u(Int16Array)]),t.addExtUnpacker(20,[a,u(Uint16Array)]),t.addExtUnpacker(21,[a,u(Int32Array)]),t.addExtUnpacker(22,[a,u(Uint32Array)]),t.addExtUnpacker(23,[a,u(Float32Array)]),"undefined"!=typeof Float64Array&&t.addExtUnpacker(24,[a,u(Float64Array)]),"undefined"!=typeof Uint8ClampedArray&&t.addExtUnpacker(25,u(Uint8ClampedArray)),t.addExtUnpacker(26,a),t.addExtUnpacker(29,[a,u(DataView)])),c.hasBuffer&&t.addExtUnpacker(27,u(Buffer));}function i(r){return s||(s=t("./decode").decode),s(r)}function o(t){return RegExp.apply(null,t)}function f(t){return function(r){var e=new t;for(var n in h)e[n]=r[n];return e}}function u(t){return function(r){return new t(r)}}function a(t){return new Uint8Array(t).buffer}e.setExtUnpackers=n;var s,c=t("./bufferish"),Buffer=c.global,h={name:1,message:1,stack:1,columnNumber:1,fileName:1,lineNumber:1};},{"./bufferish":8,"./decode":12}],20:[function(t,r,e){t("./read-core"),t("./write-core"),e.createCodec=t("./codec-base").createCodec;},{"./codec-base":9,"./read-core":22,"./write-core":25}],21:[function(t,r,e){function n(){if(!(this instanceof n))return new n}function i(){if(!(this instanceof i))return new i}function o(){function t(t){var r=this.offset?p.prototype.slice.call(this.buffer,this.offset):this.buffer;this.buffer=r?t?this.bufferish.concat([r,t]):r:t,this.offset=0;}function r(){for(;this.offset<this.buffer.length;){var t,r=this.offset;try{t=this.fetch();}catch(t){if(t&&t.message!=v)throw t;this.offset=r;break}this.push(t);}}function e(t){var r=this.offset,e=r+t;if(e>this.buffer.length)throw new Error(v);return this.offset=e,r}return {bufferish:p,write:t,fetch:a,flush:r,push:c,pull:h,read:s,reserve:e,offset:0}}function f(){function t(){var t=this.start;if(t<this.offset){var r=this.start=this.offset;return p.prototype.slice.call(this.buffer,t,r)}}function r(){for(;this.start<this.offset;){var t=this.fetch();t&&this.push(t);}}function e(){var t=this.buffers||(this.buffers=[]),r=t.length>1?this.bufferish.concat(t):t[0];return t.length=0,r}function n(t){var r=0|t;if(this.buffer){var e=this.buffer.length,n=0|this.offset,i=n+r;if(i<e)return this.offset=i,n;this.flush(),t=Math.max(t,Math.min(2*e,this.maxBufferSize));}return t=Math.max(t,this.minBufferSize),this.buffer=this.bufferish.alloc(t),this.start=0,this.offset=r,0}function i(t){var r=t.length;if(r>this.minBufferSize)this.flush(),this.push(t);else {var e=this.reserve(r);p.prototype.copy.call(t,this.buffer,e);}}return {bufferish:p,write:u,fetch:t,flush:r,push:c,pull:e,read:s,reserve:n,send:i,maxBufferSize:y,minBufferSize:d,offset:0,start:0}}function u(){throw new Error("method not implemented: write()")}function a(){throw new Error("method not implemented: fetch()")}function s(){var t=this.buffers&&this.buffers.length;return t?(this.flush(),this.pull()):this.fetch()}function c(t){var r=this.buffers||(this.buffers=[]);r.push(t);}function h(){var t=this.buffers||(this.buffers=[]);return t.shift()}function l(t){function r(r){for(var e in t)r[e]=t[e];return r}return r}e.FlexDecoder=n,e.FlexEncoder=i;var p=t("./bufferish"),d=2048,y=65536,v="BUFFER_SHORTAGE";n.mixin=l(o()),n.mixin(n.prototype),i.mixin=l(f()),i.mixin(i.prototype);},{"./bufferish":8}],22:[function(t,r,e){function n(t){function r(t){var r=s(t),n=e[r];if(!n)throw new Error("Invalid type: "+(r?"0x"+r.toString(16):r));return n(t)}var e=c.getReadToken(t);return r}function i(){var t=this.options;return this.decode=n(t),t&&t.preset&&a.setExtUnpackers(this),this}function o(t,r){var e=this.extUnpackers||(this.extUnpackers=[]);e[t]=h.filter(r);}function f(t){function r(r){return new u(r,t)}var e=this.extUnpackers||(this.extUnpackers=[]);return e[t]||r}var u=t("./ext-buffer").ExtBuffer,a=t("./ext-unpacker"),s=t("./read-format").readUint8,c=t("./read-token"),h=t("./codec-base");h.install({addExtUnpacker:o,getExtUnpacker:f,init:i}),e.preset=i.call(h.preset);},{"./codec-base":9,"./ext-buffer":17,"./ext-unpacker":19,"./read-format":23,"./read-token":24}],23:[function(t,r,e){function n(t){var r=k.hasArrayBuffer&&t&&t.binarraybuffer,e=t&&t.int64,n=T&&t&&t.usemap,B={map:n?o:i,array:f,str:u,bin:r?s:a,ext:c,uint8:h,uint16:p,uint32:y,uint64:g(8,e?E:b),int8:l,int16:d,int32:v,int64:g(8,e?A:w),float32:g(4,m),float64:g(8,x)};return B}function i(t,r){var e,n={},i=new Array(r),o=new Array(r),f=t.codec.decode;for(e=0;e<r;e++)i[e]=f(t),o[e]=f(t);for(e=0;e<r;e++)n[i[e]]=o[e];return n}function o(t,r){var e,n=new Map,i=new Array(r),o=new Array(r),f=t.codec.decode;for(e=0;e<r;e++)i[e]=f(t),o[e]=f(t);for(e=0;e<r;e++)n.set(i[e],o[e]);return n}function f(t,r){for(var e=new Array(r),n=t.codec.decode,i=0;i<r;i++)e[i]=n(t);return e}function u(t,r){var e=t.reserve(r),n=e+r;return _.toString.call(t.buffer,"utf-8",e,n)}function a(t,r){var e=t.reserve(r),n=e+r,i=_.slice.call(t.buffer,e,n);return k.from(i)}function s(t,r){var e=t.reserve(r),n=e+r,i=_.slice.call(t.buffer,e,n);return k.Uint8Array.from(i).buffer}function c(t,r){var e=t.reserve(r+1),n=t.buffer[e++],i=e+r,o=t.codec.getExtUnpacker(n);if(!o)throw new Error("Invalid ext type: "+(n?"0x"+n.toString(16):n));var f=_.slice.call(t.buffer,e,i);return o(f)}function h(t){var r=t.reserve(1);return t.buffer[r]}function l(t){var r=t.reserve(1),e=t.buffer[r];return 128&e?e-256:e}function p(t){var r=t.reserve(2),e=t.buffer;return e[r++]<<8|e[r]}function d(t){var r=t.reserve(2),e=t.buffer,n=e[r++]<<8|e[r];return 32768&n?n-65536:n}function y(t){var r=t.reserve(4),e=t.buffer;return 16777216*e[r++]+(e[r++]<<16)+(e[r++]<<8)+e[r]}function v(t){var r=t.reserve(4),e=t.buffer;return e[r++]<<24|e[r++]<<16|e[r++]<<8|e[r]}function g(t,r){return function(e){var n=e.reserve(t);return r.call(e.buffer,n,S)}}function b(t){return new P(this,t).toNumber()}function w(t){return new R(this,t).toNumber()}function E(t){return new P(this,t)}function A(t){return new R(this,t)}function m(t){return B.read(this,t,false,23,4)}function x(t){return B.read(this,t,false,52,8)}var B=t("ieee754"),U=t("int64-buffer"),P=U.Uint64BE,R=U.Int64BE;e.getReadFormat=n,e.readUint8=h;var k=t("./bufferish"),_=t("./bufferish-proto"),T="undefined"!=typeof Map,S=true;},{"./bufferish":8,"./bufferish-proto":6,ieee754:32,"int64-buffer":33}],24:[function(t,r,e){function n(t){var r=s.getReadFormat(t);return t&&t.useraw?o(r):i(r)}function i(t){var r,e=new Array(256);for(r=0;r<=127;r++)e[r]=f(r);for(r=128;r<=143;r++)e[r]=a(r-128,t.map);for(r=144;r<=159;r++)e[r]=a(r-144,t.array);for(r=160;r<=191;r++)e[r]=a(r-160,t.str);for(e[192]=f(null),e[193]=null,e[194]=f(false),e[195]=f(true),e[196]=u(t.uint8,t.bin),e[197]=u(t.uint16,t.bin),e[198]=u(t.uint32,t.bin),e[199]=u(t.uint8,t.ext),e[200]=u(t.uint16,t.ext),e[201]=u(t.uint32,t.ext),e[202]=t.float32,e[203]=t.float64,e[204]=t.uint8,e[205]=t.uint16,e[206]=t.uint32,e[207]=t.uint64,e[208]=t.int8,e[209]=t.int16,e[210]=t.int32,e[211]=t.int64,e[212]=a(1,t.ext),e[213]=a(2,t.ext),e[214]=a(4,t.ext),e[215]=a(8,t.ext),e[216]=a(16,t.ext),e[217]=u(t.uint8,t.str),e[218]=u(t.uint16,t.str),e[219]=u(t.uint32,t.str),e[220]=u(t.uint16,t.array),e[221]=u(t.uint32,t.array),e[222]=u(t.uint16,t.map),e[223]=u(t.uint32,t.map),r=224;r<=255;r++)e[r]=f(r-256);return e}function o(t){var r,e=i(t).slice();for(e[217]=e[196],e[218]=e[197],e[219]=e[198],r=160;r<=191;r++)e[r]=a(r-160,t.bin);return e}function f(t){return function(){return t}}function u(t,r){return function(e){var n=t(e);return r(e,n)}}function a(t,r){return function(e){return r(e,t)}}var s=t("./read-format");e.getReadToken=n;},{"./read-format":23}],25:[function(t,r,e){function n(t){function r(t,r){var n=e[typeof r];if(!n)throw new Error('Unsupported type "'+typeof r+'": '+r);n(t,r);}var e=s.getWriteType(t);return r}function i(){var t=this.options;return this.encode=n(t),t&&t.preset&&a.setExtPackers(this),this}function o(t,r,e){function n(r){return e&&(r=e(r)),new u(r,t)}e=c.filter(e);var i=r.name;if(i&&"Object"!==i){var o=this.extPackers||(this.extPackers={});o[i]=n;}else {var f=this.extEncoderList||(this.extEncoderList=[]);f.unshift([r,n]);}}function f(t){var r=this.extPackers||(this.extPackers={}),e=t.constructor,n=e&&e.name&&r[e.name];if(n)return n;for(var i=this.extEncoderList||(this.extEncoderList=[]),o=i.length,f=0;f<o;f++){var u=i[f];if(e===u[0])return u[1]}}var u=t("./ext-buffer").ExtBuffer,a=t("./ext-packer"),s=t("./write-type"),c=t("./codec-base");c.install({addExtPacker:o,getExtPacker:f,init:i}),e.preset=i.call(c.preset);},{"./codec-base":9,"./ext-buffer":17,"./ext-packer":18,"./write-type":27}],26:[function(t,r,e){function n(t){return t&&t.uint8array?i():m||E.hasBuffer&&t&&t.safe?f():o()}function i(){var t=o();return t[202]=c(202,4,p),t[203]=c(203,8,d),t}function o(){var t=w.slice();return t[196]=u(196),t[197]=a(197),t[198]=s(198),t[199]=u(199),t[200]=a(200),t[201]=s(201),t[202]=c(202,4,x.writeFloatBE||p,true),t[203]=c(203,8,x.writeDoubleBE||d,true),t[204]=u(204),t[205]=a(205),t[206]=s(206),t[207]=c(207,8,h),t[208]=u(208),t[209]=a(209),t[210]=s(210),t[211]=c(211,8,l),t[217]=u(217),t[218]=a(218),t[219]=s(219),t[220]=a(220),t[221]=s(221),t[222]=a(222),t[223]=s(223),t}function f(){var t=w.slice();return t[196]=c(196,1,Buffer.prototype.writeUInt8),t[197]=c(197,2,Buffer.prototype.writeUInt16BE),t[198]=c(198,4,Buffer.prototype.writeUInt32BE),t[199]=c(199,1,Buffer.prototype.writeUInt8),t[200]=c(200,2,Buffer.prototype.writeUInt16BE),t[201]=c(201,4,Buffer.prototype.writeUInt32BE),t[202]=c(202,4,Buffer.prototype.writeFloatBE),t[203]=c(203,8,Buffer.prototype.writeDoubleBE),t[204]=c(204,1,Buffer.prototype.writeUInt8),t[205]=c(205,2,Buffer.prototype.writeUInt16BE),t[206]=c(206,4,Buffer.prototype.writeUInt32BE),t[207]=c(207,8,h),t[208]=c(208,1,Buffer.prototype.writeInt8),t[209]=c(209,2,Buffer.prototype.writeInt16BE),t[210]=c(210,4,Buffer.prototype.writeInt32BE),t[211]=c(211,8,l),t[217]=c(217,1,Buffer.prototype.writeUInt8),t[218]=c(218,2,Buffer.prototype.writeUInt16BE),t[219]=c(219,4,Buffer.prototype.writeUInt32BE),t[220]=c(220,2,Buffer.prototype.writeUInt16BE),t[221]=c(221,4,Buffer.prototype.writeUInt32BE),t[222]=c(222,2,Buffer.prototype.writeUInt16BE),t[223]=c(223,4,Buffer.prototype.writeUInt32BE),t}function u(t){return function(r,e){var n=r.reserve(2),i=r.buffer;i[n++]=t,i[n]=e;}}function a(t){return function(r,e){var n=r.reserve(3),i=r.buffer;i[n++]=t,i[n++]=e>>>8,i[n]=e;}}function s(t){return function(r,e){var n=r.reserve(5),i=r.buffer;i[n++]=t,i[n++]=e>>>24,i[n++]=e>>>16,i[n++]=e>>>8,i[n]=e;}}function c(t,r,e,n){return function(i,o){var f=i.reserve(r+1);i.buffer[f++]=t,e.call(i.buffer,o,f,n);}}function h(t,r){new g(this,r,t);}function l(t,r){new b(this,r,t);}function p(t,r){y.write(this,t,r,false,23,4);}function d(t,r){y.write(this,t,r,false,52,8);}var y=t("ieee754"),v=t("int64-buffer"),g=v.Uint64BE,b=v.Int64BE,w=t("./write-uint8").uint8,E=t("./bufferish"),Buffer=E.global,A=E.hasBuffer&&"TYPED_ARRAY_SUPPORT"in Buffer,m=A&&!Buffer.TYPED_ARRAY_SUPPORT,x=E.hasBuffer&&Buffer.prototype||{};e.getWriteToken=n;},{"./bufferish":8,"./write-uint8":28,ieee754:32,"int64-buffer":33}],27:[function(t,r,e){function n(t){function r(t,r){var e=r?195:194;_[e](t,r);}function e(t,r){var e,n=0|r;return r!==n?(e=203,void _[e](t,r)):(e=-32<=n&&n<=127?255&n:0<=n?n<=255?204:n<=65535?205:206:-128<=n?208:-32768<=n?209:210,void _[e](t,n))}function n(t,r){var e=207;_[e](t,r.toArray());}function o(t,r){var e=211;_[e](t,r.toArray());}function v(t){return t<32?1:t<=255?2:t<=65535?3:5}function g(t){return t<32?1:t<=65535?3:5}function b(t){function r(r,e){var n=e.length,i=5+3*n;r.offset=r.reserve(i);var o=r.buffer,f=t(n),u=r.offset+f;n=s.write.call(o,e,u);var a=t(n);if(f!==a){var c=u+a-f,h=u+n;s.copy.call(o,o,c,u,h);}var l=1===a?160+n:a<=3?215+a:219;_[l](r,n),r.offset+=n;}return r}function w(t,r){if(null===r)return A(t,r);if(I(r))return Y(t,r);if(i(r))return m(t,r);if(f.isUint64BE(r))return n(t,r);if(u.isInt64BE(r))return o(t,r);var e=t.codec.getExtPacker(r);return e&&(r=e(r)),r instanceof l?U(t,r):void D(t,r)}function E(t,r){return I(r)?k(t,r):void w(t,r)}function A(t,r){var e=192;_[e](t,r);}function m(t,r){var e=r.length,n=e<16?144+e:e<=65535?220:221;_[n](t,e);for(var i=t.codec.encode,o=0;o<e;o++)i(t,r[o]);}function x(t,r){var e=r.length,n=e<255?196:e<=65535?197:198;_[n](t,e),t.send(r);}function B(t,r){x(t,new Uint8Array(r));}function U(t,r){var e=r.buffer,n=e.length,i=y[n]||(n<255?199:n<=65535?200:201);_[i](t,n),h[r.type](t),t.send(e);}function P(t,r){var e=Object.keys(r),n=e.length,i=n<16?128+n:n<=65535?222:223;_[i](t,n);var o=t.codec.encode;e.forEach(function(e){o(t,e),o(t,r[e]);});}function R(t,r){if(!(r instanceof Map))return P(t,r);var e=r.size,n=e<16?128+e:e<=65535?222:223;_[n](t,e);var i=t.codec.encode;r.forEach(function(r,e,n){i(t,e),i(t,r);});}function k(t,r){var e=r.length,n=e<32?160+e:e<=65535?218:219;_[n](t,e),t.send(r);}var _=c.getWriteToken(t),T=t&&t.useraw,S=p&&t&&t.binarraybuffer,I=S?a.isArrayBuffer:a.isBuffer,Y=S?B:x,C=d&&t&&t.usemap,D=C?R:P,O={boolean:r,function:A,number:e,object:T?E:w,string:b(T?g:v),symbol:A,undefined:A};return O}var i=t("isarray"),o=t("int64-buffer"),f=o.Uint64BE,u=o.Int64BE,a=t("./bufferish"),s=t("./bufferish-proto"),c=t("./write-token"),h=t("./write-uint8").uint8,l=t("./ext-buffer").ExtBuffer,p="undefined"!=typeof Uint8Array,d="undefined"!=typeof Map,y=[];y[1]=212,y[2]=213,y[4]=214,y[8]=215,y[16]=216,e.getWriteType=n;},{"./bufferish":8,"./bufferish-proto":6,"./ext-buffer":17,"./write-token":26,"./write-uint8":28,"int64-buffer":33,isarray:34}],28:[function(t,r,e){function n(t){return function(r){var e=r.reserve(1);r.buffer[e]=t;}}for(var i=e.uint8=new Array(256),o=0;o<=255;o++)i[o]=n(o);},{}],29:[function(t,r,e){(function(r){function n(){try{var t=new Uint8Array(1);return t.__proto__={__proto__:Uint8Array.prototype,foo:function(){return 42}},42===t.foo()&&"function"==typeof t.subarray&&0===t.subarray(1,1).byteLength}catch(t){return  false}}function i(){return Buffer.TYPED_ARRAY_SUPPORT?2147483647:1073741823}function o(t,r){if(i()<r)throw new RangeError("Invalid typed array length");return Buffer.TYPED_ARRAY_SUPPORT?(t=new Uint8Array(r),t.__proto__=Buffer.prototype):(null===t&&(t=new Buffer(r)),t.length=r),t}function Buffer(t,r,e){if(!(Buffer.TYPED_ARRAY_SUPPORT||this instanceof Buffer))return new Buffer(t,r,e);if("number"==typeof t){if("string"==typeof r)throw new Error("If encoding is specified then the first argument must be a string");return s(this,t)}return f(this,t,r,e)}function f(t,r,e,n){if("number"==typeof r)throw new TypeError('"value" argument must not be a number');return "undefined"!=typeof ArrayBuffer&&r instanceof ArrayBuffer?l(t,r,e,n):"string"==typeof r?c(t,r,e):p(t,r)}function u(t){if("number"!=typeof t)throw new TypeError('"size" argument must be a number');if(t<0)throw new RangeError('"size" argument must not be negative')}function a(t,r,e,n){return u(r),r<=0?o(t,r):void 0!==e?"string"==typeof n?o(t,r).fill(e,n):o(t,r).fill(e):o(t,r)}function s(t,r){if(u(r),t=o(t,r<0?0:0|d(r)),!Buffer.TYPED_ARRAY_SUPPORT)for(var e=0;e<r;++e)t[e]=0;return t}function c(t,r,e){if("string"==typeof e&&""!==e||(e="utf8"),!Buffer.isEncoding(e))throw new TypeError('"encoding" must be a valid string encoding');var n=0|v(r,e);t=o(t,n);var i=t.write(r,e);return i!==n&&(t=t.slice(0,i)),t}function h(t,r){var e=r.length<0?0:0|d(r.length);t=o(t,e);for(var n=0;n<e;n+=1)t[n]=255&r[n];return t}function l(t,r,e,n){if(r.byteLength,e<0||r.byteLength<e)throw new RangeError("'offset' is out of bounds");if(r.byteLength<e+(n||0))throw new RangeError("'length' is out of bounds");return r=void 0===e&&void 0===n?new Uint8Array(r):void 0===n?new Uint8Array(r,e):new Uint8Array(r,e,n),Buffer.TYPED_ARRAY_SUPPORT?(t=r,t.__proto__=Buffer.prototype):t=h(t,r),t}function p(t,r){if(Buffer.isBuffer(r)){var e=0|d(r.length);return t=o(t,e),0===t.length?t:(r.copy(t,0,0,e),t)}if(r){if("undefined"!=typeof ArrayBuffer&&r.buffer instanceof ArrayBuffer||"length"in r)return "number"!=typeof r.length||H(r.length)?o(t,0):h(t,r);if("Buffer"===r.type&&Q(r.data))return h(t,r.data)}throw new TypeError("First argument must be a string, Buffer, ArrayBuffer, Array, or array-like object.")}function d(t){if(t>=i())throw new RangeError("Attempt to allocate Buffer larger than maximum size: 0x"+i().toString(16)+" bytes");return 0|t}function y(t){return +t!=t&&(t=0),Buffer.alloc(+t)}function v(t,r){if(Buffer.isBuffer(t))return t.length;if("undefined"!=typeof ArrayBuffer&&"function"==typeof ArrayBuffer.isView&&(ArrayBuffer.isView(t)||t instanceof ArrayBuffer))return t.byteLength;"string"!=typeof t&&(t=""+t);var e=t.length;if(0===e)return 0;for(var n=false;;)switch(r){case "ascii":case "latin1":case "binary":return e;case "utf8":case "utf-8":case void 0:return q(t).length;case "ucs2":case "ucs-2":case "utf16le":case "utf-16le":return 2*e;case "hex":return e>>>1;case "base64":return X(t).length;default:if(n)return q(t).length;r=(""+r).toLowerCase(),n=true;}}function g(t,r,e){var n=false;if((void 0===r||r<0)&&(r=0),r>this.length)return "";if((void 0===e||e>this.length)&&(e=this.length),e<=0)return "";if(e>>>=0,r>>>=0,e<=r)return "";for(t||(t="utf8");;)switch(t){case "hex":return I(this,r,e);case "utf8":case "utf-8":return k(this,r,e);case "ascii":return T(this,r,e);case "latin1":case "binary":return S(this,r,e);case "base64":return R(this,r,e);case "ucs2":case "ucs-2":case "utf16le":case "utf-16le":return Y(this,r,e);default:if(n)throw new TypeError("Unknown encoding: "+t);t=(t+"").toLowerCase(),n=true;}}function b(t,r,e){var n=t[r];t[r]=t[e],t[e]=n;}function w(t,r,e,n,i){if(0===t.length)return  -1;if("string"==typeof e?(n=e,e=0):e>2147483647?e=2147483647:e<-2147483648&&(e=-2147483648),e=+e,isNaN(e)&&(e=i?0:t.length-1),e<0&&(e=t.length+e),e>=t.length){if(i)return  -1;e=t.length-1;}else if(e<0){if(!i)return  -1;e=0;}if("string"==typeof r&&(r=Buffer.from(r,n)),Buffer.isBuffer(r))return 0===r.length?-1:E(t,r,e,n,i);if("number"==typeof r)return r=255&r,Buffer.TYPED_ARRAY_SUPPORT&&"function"==typeof Uint8Array.prototype.indexOf?i?Uint8Array.prototype.indexOf.call(t,r,e):Uint8Array.prototype.lastIndexOf.call(t,r,e):E(t,[r],e,n,i);throw new TypeError("val must be string, number or Buffer")}function E(t,r,e,n,i){function o(t,r){return 1===f?t[r]:t.readUInt16BE(r*f)}var f=1,u=t.length,a=r.length;if(void 0!==n&&(n=String(n).toLowerCase(),"ucs2"===n||"ucs-2"===n||"utf16le"===n||"utf-16le"===n)){if(t.length<2||r.length<2)return  -1;f=2,u/=2,a/=2,e/=2;}var s;if(i){var c=-1;for(s=e;s<u;s++)if(o(t,s)===o(r,c===-1?0:s-c)){if(c===-1&&(c=s),s-c+1===a)return c*f}else c!==-1&&(s-=s-c),c=-1;}else for(e+a>u&&(e=u-a),s=e;s>=0;s--){for(var h=true,l=0;l<a;l++)if(o(t,s+l)!==o(r,l)){h=false;break}if(h)return s}return  -1}function A(t,r,e,n){e=Number(e)||0;var i=t.length-e;n?(n=Number(n),n>i&&(n=i)):n=i;var o=r.length;if(o%2!==0)throw new TypeError("Invalid hex string");n>o/2&&(n=o/2);for(var f=0;f<n;++f){var u=parseInt(r.substr(2*f,2),16);if(isNaN(u))return f;t[e+f]=u;}return f}function m(t,r,e,n){return G(q(r,t.length-e),t,e,n)}function x(t,r,e,n){return G(W(r),t,e,n)}function B(t,r,e,n){return x(t,r,e,n)}function U(t,r,e,n){return G(X(r),t,e,n)}function P(t,r,e,n){return G(J(r,t.length-e),t,e,n)}function R(t,r,e){return 0===r&&e===t.length?Z.fromByteArray(t):Z.fromByteArray(t.slice(r,e))}function k(t,r,e){e=Math.min(t.length,e);for(var n=[],i=r;i<e;){var o=t[i],f=null,u=o>239?4:o>223?3:o>191?2:1;if(i+u<=e){var a,s,c,h;switch(u){case 1:o<128&&(f=o);break;case 2:a=t[i+1],128===(192&a)&&(h=(31&o)<<6|63&a,h>127&&(f=h));break;case 3:a=t[i+1],s=t[i+2],128===(192&a)&&128===(192&s)&&(h=(15&o)<<12|(63&a)<<6|63&s,h>2047&&(h<55296||h>57343)&&(f=h));break;case 4:a=t[i+1],s=t[i+2],c=t[i+3],128===(192&a)&&128===(192&s)&&128===(192&c)&&(h=(15&o)<<18|(63&a)<<12|(63&s)<<6|63&c,h>65535&&h<1114112&&(f=h));}}null===f?(f=65533,u=1):f>65535&&(f-=65536,n.push(f>>>10&1023|55296),f=56320|1023&f),n.push(f),i+=u;}return _(n)}function _(t){var r=t.length;if(r<=$)return String.fromCharCode.apply(String,t);for(var e="",n=0;n<r;)e+=String.fromCharCode.apply(String,t.slice(n,n+=$));return e}function T(t,r,e){var n="";e=Math.min(t.length,e);for(var i=r;i<e;++i)n+=String.fromCharCode(127&t[i]);return n}function S(t,r,e){var n="";e=Math.min(t.length,e);for(var i=r;i<e;++i)n+=String.fromCharCode(t[i]);return n}function I(t,r,e){var n=t.length;(!r||r<0)&&(r=0),(!e||e<0||e>n)&&(e=n);for(var i="",o=r;o<e;++o)i+=V(t[o]);return i}function Y(t,r,e){for(var n=t.slice(r,e),i="",o=0;o<n.length;o+=2)i+=String.fromCharCode(n[o]+256*n[o+1]);return i}function C(t,r,e){if(t%1!==0||t<0)throw new RangeError("offset is not uint");if(t+r>e)throw new RangeError("Trying to access beyond buffer length")}function D(t,r,e,n,i,o){if(!Buffer.isBuffer(t))throw new TypeError('"buffer" argument must be a Buffer instance');if(r>i||r<o)throw new RangeError('"value" argument is out of bounds');if(e+n>t.length)throw new RangeError("Index out of range")}function O(t,r,e,n){r<0&&(r=65535+r+1);for(var i=0,o=Math.min(t.length-e,2);i<o;++i)t[e+i]=(r&255<<8*(n?i:1-i))>>>8*(n?i:1-i);}function L(t,r,e,n){r<0&&(r=4294967295+r+1);for(var i=0,o=Math.min(t.length-e,4);i<o;++i)t[e+i]=r>>>8*(n?i:3-i)&255;}function M(t,r,e,n,i,o){if(e+n>t.length)throw new RangeError("Index out of range");if(e<0)throw new RangeError("Index out of range")}function N(t,r,e,n,i){return i||M(t,r,e,4),K.write(t,r,e,n,23,4),e+4}function F(t,r,e,n,i){return i||M(t,r,e,8),K.write(t,r,e,n,52,8),e+8}function j(t){
if(t=z(t).replace(tt,""),t.length<2)return "";for(;t.length%4!==0;)t+="=";return t}function z(t){return t.trim?t.trim():t.replace(/^\s+|\s+$/g,"")}function V(t){return t<16?"0"+t.toString(16):t.toString(16)}function q(t,r){r=r||1/0;for(var e,n=t.length,i=null,o=[],f=0;f<n;++f){if(e=t.charCodeAt(f),e>55295&&e<57344){if(!i){if(e>56319){(r-=3)>-1&&o.push(239,191,189);continue}if(f+1===n){(r-=3)>-1&&o.push(239,191,189);continue}i=e;continue}if(e<56320){(r-=3)>-1&&o.push(239,191,189),i=e;continue}e=(i-55296<<10|e-56320)+65536;}else i&&(r-=3)>-1&&o.push(239,191,189);if(i=null,e<128){if((r-=1)<0)break;o.push(e);}else if(e<2048){if((r-=2)<0)break;o.push(e>>6|192,63&e|128);}else if(e<65536){if((r-=3)<0)break;o.push(e>>12|224,e>>6&63|128,63&e|128);}else {if(!(e<1114112))throw new Error("Invalid code point");if((r-=4)<0)break;o.push(e>>18|240,e>>12&63|128,e>>6&63|128,63&e|128);}}return o}function W(t){for(var r=[],e=0;e<t.length;++e)r.push(255&t.charCodeAt(e));return r}function J(t,r){for(var e,n,i,o=[],f=0;f<t.length&&!((r-=2)<0);++f)e=t.charCodeAt(f),n=e>>8,i=e%256,o.push(i),o.push(n);return o}function X(t){return Z.toByteArray(j(t))}function G(t,r,e,n){for(var i=0;i<n&&!(i+e>=r.length||i>=t.length);++i)r[i+e]=t[i];return i}function H(t){return t!==t}var Z=t("base64-js"),K=t("ieee754"),Q=t("isarray");e.Buffer=Buffer,e.SlowBuffer=y,e.INSPECT_MAX_BYTES=50,Buffer.TYPED_ARRAY_SUPPORT=void 0!==r.TYPED_ARRAY_SUPPORT?r.TYPED_ARRAY_SUPPORT:n(),e.kMaxLength=i(),Buffer.poolSize=8192,Buffer._augment=function(t){return t.__proto__=Buffer.prototype,t},Buffer.from=function(t,r,e){return f(null,t,r,e)},Buffer.TYPED_ARRAY_SUPPORT&&(Buffer.prototype.__proto__=Uint8Array.prototype,Buffer.__proto__=Uint8Array,"undefined"!=typeof Symbol&&Symbol.species&&Buffer[Symbol.species]===Buffer&&Object.defineProperty(Buffer,Symbol.species,{value:null,configurable:true})),Buffer.alloc=function(t,r,e){return a(null,t,r,e)},Buffer.allocUnsafe=function(t){return s(null,t)},Buffer.allocUnsafeSlow=function(t){return s(null,t)},Buffer.isBuffer=function(t){return !(null==t||!t._isBuffer)},Buffer.compare=function(t,r){if(!Buffer.isBuffer(t)||!Buffer.isBuffer(r))throw new TypeError("Arguments must be Buffers");if(t===r)return 0;for(var e=t.length,n=r.length,i=0,o=Math.min(e,n);i<o;++i)if(t[i]!==r[i]){e=t[i],n=r[i];break}return e<n?-1:n<e?1:0},Buffer.isEncoding=function(t){switch(String(t).toLowerCase()){case "hex":case "utf8":case "utf-8":case "ascii":case "latin1":case "binary":case "base64":case "ucs2":case "ucs-2":case "utf16le":case "utf-16le":return  true;default:return  false}},Buffer.concat=function(t,r){if(!Q(t))throw new TypeError('"list" argument must be an Array of Buffers');if(0===t.length)return Buffer.alloc(0);var e;if(void 0===r)for(r=0,e=0;e<t.length;++e)r+=t[e].length;var n=Buffer.allocUnsafe(r),i=0;for(e=0;e<t.length;++e){var o=t[e];if(!Buffer.isBuffer(o))throw new TypeError('"list" argument must be an Array of Buffers');o.copy(n,i),i+=o.length;}return n},Buffer.byteLength=v,Buffer.prototype._isBuffer=true,Buffer.prototype.swap16=function(){var t=this.length;if(t%2!==0)throw new RangeError("Buffer size must be a multiple of 16-bits");for(var r=0;r<t;r+=2)b(this,r,r+1);return this},Buffer.prototype.swap32=function(){var t=this.length;if(t%4!==0)throw new RangeError("Buffer size must be a multiple of 32-bits");for(var r=0;r<t;r+=4)b(this,r,r+3),b(this,r+1,r+2);return this},Buffer.prototype.swap64=function(){var t=this.length;if(t%8!==0)throw new RangeError("Buffer size must be a multiple of 64-bits");for(var r=0;r<t;r+=8)b(this,r,r+7),b(this,r+1,r+6),b(this,r+2,r+5),b(this,r+3,r+4);return this},Buffer.prototype.toString=function(){var t=0|this.length;return 0===t?"":0===arguments.length?k(this,0,t):g.apply(this,arguments)},Buffer.prototype.equals=function(t){if(!Buffer.isBuffer(t))throw new TypeError("Argument must be a Buffer");return this===t||0===Buffer.compare(this,t)},Buffer.prototype.inspect=function(){var t="",r=e.INSPECT_MAX_BYTES;return this.length>0&&(t=this.toString("hex",0,r).match(/.{2}/g).join(" "),this.length>r&&(t+=" ... ")),"<Buffer "+t+">"},Buffer.prototype.compare=function(t,r,e,n,i){if(!Buffer.isBuffer(t))throw new TypeError("Argument must be a Buffer");if(void 0===r&&(r=0),void 0===e&&(e=t?t.length:0),void 0===n&&(n=0),void 0===i&&(i=this.length),r<0||e>t.length||n<0||i>this.length)throw new RangeError("out of range index");if(n>=i&&r>=e)return 0;if(n>=i)return  -1;if(r>=e)return 1;if(r>>>=0,e>>>=0,n>>>=0,i>>>=0,this===t)return 0;for(var o=i-n,f=e-r,u=Math.min(o,f),a=this.slice(n,i),s=t.slice(r,e),c=0;c<u;++c)if(a[c]!==s[c]){o=a[c],f=s[c];break}return o<f?-1:f<o?1:0},Buffer.prototype.includes=function(t,r,e){return this.indexOf(t,r,e)!==-1},Buffer.prototype.indexOf=function(t,r,e){return w(this,t,r,e,true)},Buffer.prototype.lastIndexOf=function(t,r,e){return w(this,t,r,e,false)},Buffer.prototype.write=function(t,r,e,n){if(void 0===r)n="utf8",e=this.length,r=0;else if(void 0===e&&"string"==typeof r)n=r,e=this.length,r=0;else {if(!isFinite(r))throw new Error("Buffer.write(string, encoding, offset[, length]) is no longer supported");r=0|r,isFinite(e)?(e=0|e,void 0===n&&(n="utf8")):(n=e,e=void 0);}var i=this.length-r;if((void 0===e||e>i)&&(e=i),t.length>0&&(e<0||r<0)||r>this.length)throw new RangeError("Attempt to write outside buffer bounds");n||(n="utf8");for(var o=false;;)switch(n){case "hex":return A(this,t,r,e);case "utf8":case "utf-8":return m(this,t,r,e);case "ascii":return x(this,t,r,e);case "latin1":case "binary":return B(this,t,r,e);case "base64":return U(this,t,r,e);case "ucs2":case "ucs-2":case "utf16le":case "utf-16le":return P(this,t,r,e);default:if(o)throw new TypeError("Unknown encoding: "+n);n=(""+n).toLowerCase(),o=true;}},Buffer.prototype.toJSON=function(){return {type:"Buffer",data:Array.prototype.slice.call(this._arr||this,0)}};var $=4096;Buffer.prototype.slice=function(t,r){var e=this.length;t=~~t,r=void 0===r?e:~~r,t<0?(t+=e,t<0&&(t=0)):t>e&&(t=e),r<0?(r+=e,r<0&&(r=0)):r>e&&(r=e),r<t&&(r=t);var n;if(Buffer.TYPED_ARRAY_SUPPORT)n=this.subarray(t,r),n.__proto__=Buffer.prototype;else {var i=r-t;n=new Buffer(i,void 0);for(var o=0;o<i;++o)n[o]=this[o+t];}return n},Buffer.prototype.readUIntLE=function(t,r,e){t=0|t,r=0|r,e||C(t,r,this.length);for(var n=this[t],i=1,o=0;++o<r&&(i*=256);)n+=this[t+o]*i;return n},Buffer.prototype.readUIntBE=function(t,r,e){t=0|t,r=0|r,e||C(t,r,this.length);for(var n=this[t+--r],i=1;r>0&&(i*=256);)n+=this[t+--r]*i;return n},Buffer.prototype.readUInt8=function(t,r){return r||C(t,1,this.length),this[t]},Buffer.prototype.readUInt16LE=function(t,r){return r||C(t,2,this.length),this[t]|this[t+1]<<8},Buffer.prototype.readUInt16BE=function(t,r){return r||C(t,2,this.length),this[t]<<8|this[t+1]},Buffer.prototype.readUInt32LE=function(t,r){return r||C(t,4,this.length),(this[t]|this[t+1]<<8|this[t+2]<<16)+16777216*this[t+3]},Buffer.prototype.readUInt32BE=function(t,r){return r||C(t,4,this.length),16777216*this[t]+(this[t+1]<<16|this[t+2]<<8|this[t+3])},Buffer.prototype.readIntLE=function(t,r,e){t=0|t,r=0|r,e||C(t,r,this.length);for(var n=this[t],i=1,o=0;++o<r&&(i*=256);)n+=this[t+o]*i;return i*=128,n>=i&&(n-=Math.pow(2,8*r)),n},Buffer.prototype.readIntBE=function(t,r,e){t=0|t,r=0|r,e||C(t,r,this.length);for(var n=r,i=1,o=this[t+--n];n>0&&(i*=256);)o+=this[t+--n]*i;return i*=128,o>=i&&(o-=Math.pow(2,8*r)),o},Buffer.prototype.readInt8=function(t,r){return r||C(t,1,this.length),128&this[t]?(255-this[t]+1)*-1:this[t]},Buffer.prototype.readInt16LE=function(t,r){r||C(t,2,this.length);var e=this[t]|this[t+1]<<8;return 32768&e?4294901760|e:e},Buffer.prototype.readInt16BE=function(t,r){r||C(t,2,this.length);var e=this[t+1]|this[t]<<8;return 32768&e?4294901760|e:e},Buffer.prototype.readInt32LE=function(t,r){return r||C(t,4,this.length),this[t]|this[t+1]<<8|this[t+2]<<16|this[t+3]<<24},Buffer.prototype.readInt32BE=function(t,r){return r||C(t,4,this.length),this[t]<<24|this[t+1]<<16|this[t+2]<<8|this[t+3]},Buffer.prototype.readFloatLE=function(t,r){return r||C(t,4,this.length),K.read(this,t,true,23,4)},Buffer.prototype.readFloatBE=function(t,r){return r||C(t,4,this.length),K.read(this,t,false,23,4)},Buffer.prototype.readDoubleLE=function(t,r){return r||C(t,8,this.length),K.read(this,t,true,52,8)},Buffer.prototype.readDoubleBE=function(t,r){return r||C(t,8,this.length),K.read(this,t,false,52,8)},Buffer.prototype.writeUIntLE=function(t,r,e,n){if(t=+t,r=0|r,e=0|e,!n){var i=Math.pow(2,8*e)-1;D(this,t,r,e,i,0);}var o=1,f=0;for(this[r]=255&t;++f<e&&(o*=256);)this[r+f]=t/o&255;return r+e},Buffer.prototype.writeUIntBE=function(t,r,e,n){if(t=+t,r=0|r,e=0|e,!n){var i=Math.pow(2,8*e)-1;D(this,t,r,e,i,0);}var o=e-1,f=1;for(this[r+o]=255&t;--o>=0&&(f*=256);)this[r+o]=t/f&255;return r+e},Buffer.prototype.writeUInt8=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,1,255,0),Buffer.TYPED_ARRAY_SUPPORT||(t=Math.floor(t)),this[r]=255&t,r+1},Buffer.prototype.writeUInt16LE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,2,65535,0),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=255&t,this[r+1]=t>>>8):O(this,t,r,true),r+2},Buffer.prototype.writeUInt16BE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,2,65535,0),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=t>>>8,this[r+1]=255&t):O(this,t,r,false),r+2},Buffer.prototype.writeUInt32LE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,4,4294967295,0),Buffer.TYPED_ARRAY_SUPPORT?(this[r+3]=t>>>24,this[r+2]=t>>>16,this[r+1]=t>>>8,this[r]=255&t):L(this,t,r,true),r+4},Buffer.prototype.writeUInt32BE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,4,4294967295,0),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=t>>>24,this[r+1]=t>>>16,this[r+2]=t>>>8,this[r+3]=255&t):L(this,t,r,false),r+4},Buffer.prototype.writeIntLE=function(t,r,e,n){if(t=+t,r=0|r,!n){var i=Math.pow(2,8*e-1);D(this,t,r,e,i-1,-i);}var o=0,f=1,u=0;for(this[r]=255&t;++o<e&&(f*=256);)t<0&&0===u&&0!==this[r+o-1]&&(u=1),this[r+o]=(t/f>>0)-u&255;return r+e},Buffer.prototype.writeIntBE=function(t,r,e,n){if(t=+t,r=0|r,!n){var i=Math.pow(2,8*e-1);D(this,t,r,e,i-1,-i);}var o=e-1,f=1,u=0;for(this[r+o]=255&t;--o>=0&&(f*=256);)t<0&&0===u&&0!==this[r+o+1]&&(u=1),this[r+o]=(t/f>>0)-u&255;return r+e},Buffer.prototype.writeInt8=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,1,127,-128),Buffer.TYPED_ARRAY_SUPPORT||(t=Math.floor(t)),t<0&&(t=255+t+1),this[r]=255&t,r+1},Buffer.prototype.writeInt16LE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,2,32767,-32768),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=255&t,this[r+1]=t>>>8):O(this,t,r,true),r+2},Buffer.prototype.writeInt16BE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,2,32767,-32768),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=t>>>8,this[r+1]=255&t):O(this,t,r,false),r+2},Buffer.prototype.writeInt32LE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,4,2147483647,-2147483648),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=255&t,this[r+1]=t>>>8,this[r+2]=t>>>16,this[r+3]=t>>>24):L(this,t,r,true),r+4},Buffer.prototype.writeInt32BE=function(t,r,e){return t=+t,r=0|r,e||D(this,t,r,4,2147483647,-2147483648),t<0&&(t=4294967295+t+1),Buffer.TYPED_ARRAY_SUPPORT?(this[r]=t>>>24,this[r+1]=t>>>16,this[r+2]=t>>>8,this[r+3]=255&t):L(this,t,r,false),r+4},Buffer.prototype.writeFloatLE=function(t,r,e){return N(this,t,r,true,e)},Buffer.prototype.writeFloatBE=function(t,r,e){return N(this,t,r,false,e)},Buffer.prototype.writeDoubleLE=function(t,r,e){return F(this,t,r,true,e)},Buffer.prototype.writeDoubleBE=function(t,r,e){return F(this,t,r,false,e)},Buffer.prototype.copy=function(t,r,e,n){if(e||(e=0),n||0===n||(n=this.length),r>=t.length&&(r=t.length),r||(r=0),n>0&&n<e&&(n=e),n===e)return 0;if(0===t.length||0===this.length)return 0;if(r<0)throw new RangeError("targetStart out of bounds");if(e<0||e>=this.length)throw new RangeError("sourceStart out of bounds");if(n<0)throw new RangeError("sourceEnd out of bounds");n>this.length&&(n=this.length),t.length-r<n-e&&(n=t.length-r+e);var i,o=n-e;if(this===t&&e<r&&r<n)for(i=o-1;i>=0;--i)t[i+r]=this[i+e];else if(o<1e3||!Buffer.TYPED_ARRAY_SUPPORT)for(i=0;i<o;++i)t[i+r]=this[i+e];else Uint8Array.prototype.set.call(t,this.subarray(e,e+o),r);return o},Buffer.prototype.fill=function(t,r,e,n){if("string"==typeof t){if("string"==typeof r?(n=r,r=0,e=this.length):"string"==typeof e&&(n=e,e=this.length),1===t.length){var i=t.charCodeAt(0);i<256&&(t=i);}if(void 0!==n&&"string"!=typeof n)throw new TypeError("encoding must be a string");if("string"==typeof n&&!Buffer.isEncoding(n))throw new TypeError("Unknown encoding: "+n)}else "number"==typeof t&&(t=255&t);if(r<0||this.length<r||this.length<e)throw new RangeError("Out of range index");if(e<=r)return this;r>>>=0,e=void 0===e?this.length:e>>>0,t||(t=0);var o;if("number"==typeof t)for(o=r;o<e;++o)this[o]=t;else {var f=Buffer.isBuffer(t)?t:q(new Buffer(t,n).toString()),u=f.length;for(o=0;o<e-r;++o)this[o+r]=f[o%u];}return this};var tt=/[^+\/0-9A-Za-z-_]/g;}).call(this,"undefined"!=typeof global?global:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{});},{"base64-js":30,ieee754:32,isarray:34}],30:[function(t,r,e){function n(t){var r=t.length;if(r%4>0)throw new Error("Invalid string. Length must be a multiple of 4");return "="===t[r-2]?2:"="===t[r-1]?1:0}function i(t){return 3*t.length/4-n(t)}function o(t){var r,e,i,o,f,u,a=t.length;f=n(t),u=new h(3*a/4-f),i=f>0?a-4:a;var s=0;for(r=0,e=0;r<i;r+=4,e+=3)o=c[t.charCodeAt(r)]<<18|c[t.charCodeAt(r+1)]<<12|c[t.charCodeAt(r+2)]<<6|c[t.charCodeAt(r+3)],u[s++]=o>>16&255,u[s++]=o>>8&255,u[s++]=255&o;return 2===f?(o=c[t.charCodeAt(r)]<<2|c[t.charCodeAt(r+1)]>>4,u[s++]=255&o):1===f&&(o=c[t.charCodeAt(r)]<<10|c[t.charCodeAt(r+1)]<<4|c[t.charCodeAt(r+2)]>>2,u[s++]=o>>8&255,u[s++]=255&o),u}function f(t){return s[t>>18&63]+s[t>>12&63]+s[t>>6&63]+s[63&t]}function u(t,r,e){for(var n,i=[],o=r;o<e;o+=3)n=(t[o]<<16)+(t[o+1]<<8)+t[o+2],i.push(f(n));return i.join("")}function a(t){for(var r,e=t.length,n=e%3,i="",o=[],f=16383,a=0,c=e-n;a<c;a+=f)o.push(u(t,a,a+f>c?c:a+f));return 1===n?(r=t[e-1],i+=s[r>>2],i+=s[r<<4&63],i+="=="):2===n&&(r=(t[e-2]<<8)+t[e-1],i+=s[r>>10],i+=s[r>>4&63],i+=s[r<<2&63],i+="="),o.push(i),o.join("")}e.byteLength=i,e.toByteArray=o,e.fromByteArray=a;for(var s=[],c=[],h="undefined"!=typeof Uint8Array?Uint8Array:Array,l="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",p=0,d=l.length;p<d;++p)s[p]=l[p],c[l.charCodeAt(p)]=p;c["-".charCodeAt(0)]=62,c["_".charCodeAt(0)]=63;},{}],31:[function(t,r,e){function n(){if(!(this instanceof n))return new n}!function(t){function e(t){for(var r in s)t[r]=s[r];return t}function n(t,r){return u(this,t).push(r),this}function i(t,r){function e(){o.call(n,t,e),r.apply(this,arguments);}var n=this;return e.originalListener=r,u(n,t).push(e),n}function o(t,r){function e(t){return t!==r&&t.originalListener!==r}var n,i=this;if(arguments.length){if(r){if(n=u(i,t,true)){if(n=n.filter(e),!n.length)return o.call(i,t);i[a][t]=n;}}else if(n=i[a],n&&(delete n[t],!Object.keys(n).length))return o.call(i)}else delete i[a];return i}function f(t,r){function e(t){t.call(o);}function n(t){t.call(o,r);}function i(t){t.apply(o,s);}var o=this,f=u(o,t,true);if(!f)return  false;var a=arguments.length;if(1===a)f.forEach(e);else if(2===a)f.forEach(n);else {var s=Array.prototype.slice.call(arguments,1);f.forEach(i);}return !!f.length}function u(t,r,e){if(!e||t[a]){var n=t[a]||(t[a]={});return n[r]||(n[r]=[])}}"undefined"!=typeof r&&(r.exports=t);var a="listeners",s={on:n,once:i,off:o,emit:f};e(t.prototype),t.mixin=e;}(n);},{}],32:[function(t,r,e){e.read=function(t,r,e,n,i){var o,f,u=8*i-n-1,a=(1<<u)-1,s=a>>1,c=-7,h=e?i-1:0,l=e?-1:1,p=t[r+h];for(h+=l,o=p&(1<<-c)-1,p>>=-c,c+=u;c>0;o=256*o+t[r+h],h+=l,c-=8);for(f=o&(1<<-c)-1,o>>=-c,c+=n;c>0;f=256*f+t[r+h],h+=l,c-=8);if(0===o)o=1-s;else {if(o===a)return f?NaN:(p?-1:1)*(1/0);f+=Math.pow(2,n),o-=s;}return (p?-1:1)*f*Math.pow(2,o-n)},e.write=function(t,r,e,n,i,o){var f,u,a,s=8*o-i-1,c=(1<<s)-1,h=c>>1,l=23===i?Math.pow(2,-24)-Math.pow(2,-77):0,p=n?0:o-1,d=n?1:-1,y=r<0||0===r&&1/r<0?1:0;for(r=Math.abs(r),isNaN(r)||r===1/0?(u=isNaN(r)?1:0,f=c):(f=Math.floor(Math.log(r)/Math.LN2),r*(a=Math.pow(2,-f))<1&&(f--,a*=2),r+=f+h>=1?l/a:l*Math.pow(2,1-h),r*a>=2&&(f++,a/=2),f+h>=c?(u=0,f=c):f+h>=1?(u=(r*a-1)*Math.pow(2,i),f+=h):(u=r*Math.pow(2,h-1)*Math.pow(2,i),f=0));i>=8;t[e+p]=255&u,p+=d,u/=256,i-=8);for(f=f<<i|u,s+=i;s>0;t[e+p]=255&f,p+=d,f/=256,s-=8);t[e+p-d]|=128*y;};},{}],33:[function(t,r,e){(function(Buffer){!function(e){function o(t,r,n){function i(t,r,e,n){return this instanceof i?v(this,t,r,e,n):new i(t,r,e,n)}function o(t){return !(!t||!t[F])}function v(t,r,e,n,i){if(E&&A&&(r instanceof A&&(r=new E(r)),n instanceof A&&(n=new E(n))),!(r||e||n||g))return void(t.buffer=h(m,0));if(!s(r,e)){var o=g||Array;i=e,n=r,e=0,r=new o(8);}t.buffer=r,t.offset=e|=0,b!==typeof n&&("string"==typeof n?x(r,e,n,i||10):s(n,i)?c(r,e,n,i):"number"==typeof i?(k(r,e+T,n),k(r,e+S,i)):n>0?O(r,e,n):n<0?L(r,e,n):c(r,e,m,0));}function x(t,r,e,n){var i=0,o=e.length,f=0,u=0;"-"===e[0]&&i++;for(var a=i;i<o;){var s=parseInt(e[i++],n);if(!(s>=0))break;u=u*n+s,f=f*n+Math.floor(u/B),u%=B;}a&&(f=~f,u?u=B-u:f++),k(t,r+T,f),k(t,r+S,u);}function P(){var t=this.buffer,r=this.offset,e=_(t,r+T),i=_(t,r+S);return n||(e|=0),e?e*B+i:i}function R(t){var r=this.buffer,e=this.offset,i=_(r,e+T),o=_(r,e+S),f="",u=!n&&2147483648&i;for(u&&(i=~i,o=B-o),t=t||10;;){var a=i%t*B+o;if(i=Math.floor(i/t),o=Math.floor(a/t),f=(a%t).toString(t)+f,!i&&!o)break}return u&&(f="-"+f),f}function k(t,r,e){t[r+D]=255&e,e>>=8,t[r+C]=255&e,e>>=8,t[r+Y]=255&e,e>>=8,t[r+I]=255&e;}function _(t,r){return t[r+I]*U+(t[r+Y]<<16)+(t[r+C]<<8)+t[r+D]}var T=r?0:4,S=r?4:0,I=r?0:3,Y=r?1:2,C=r?2:1,D=r?3:0,O=r?l:d,L=r?p:y,M=i.prototype,N="is"+t,F="_"+N;return M.buffer=void 0,M.offset=0,M[F]=true,M.toNumber=P,M.toString=R,M.toJSON=P,M.toArray=f,w&&(M.toBuffer=u),E&&(M.toArrayBuffer=a),i[N]=o,e[t]=i,i}function f(t){var r=this.buffer,e=this.offset;return g=null,t!==false&&0===e&&8===r.length&&x(r)?r:h(r,e)}function u(t){var r=this.buffer,e=this.offset;if(g=w,t!==false&&0===e&&8===r.length&&Buffer.isBuffer(r))return r;var n=new w(8);return c(n,0,r,e),n}function a(t){var r=this.buffer,e=this.offset,n=r.buffer;if(g=E,t!==false&&0===e&&n instanceof A&&8===n.byteLength)return n;var i=new E(8);return c(i,0,r,e),i.buffer}function s(t,r){var e=t&&t.length;return r|=0,e&&r+8<=e&&"string"!=typeof t[r]}function c(t,r,e,n){r|=0,n|=0;for(var i=0;i<8;i++)t[r++]=255&e[n++];}function h(t,r){return Array.prototype.slice.call(t,r,r+8)}function l(t,r,e){for(var n=r+8;n>r;)t[--n]=255&e,e/=256;}function p(t,r,e){var n=r+8;for(e++;n>r;)t[--n]=255&-e^255,e/=256;}function d(t,r,e){for(var n=r+8;r<n;)t[r++]=255&e,e/=256;}function y(t,r,e){var n=r+8;for(e++;r<n;)t[r++]=255&-e^255,e/=256;}function v(t){return !!t&&"[object Array]"==Object.prototype.toString.call(t)}var g,b="undefined",w=b!==typeof Buffer&&Buffer,E=b!==typeof Uint8Array&&Uint8Array,A=b!==typeof ArrayBuffer&&ArrayBuffer,m=[0,0,0,0,0,0,0,0],x=Array.isArray||v,B=4294967296,U=16777216;o("Uint64BE",true,true),o("Int64BE",true,false),o("Uint64LE",false,true),o("Int64LE",false,false);}("object"==typeof e&&"string"!=typeof e.nodeName?e:this||{});}).call(this,t("buffer").Buffer);},{buffer:29}],34:[function(t,r,e){var n={}.toString;r.exports=Array.isArray||function(t){return "[object Array]"==n.call(t)};},{}]},{},[1])(1)});

// ES6 import for msgpack-lite, we use the fonsp/msgpack-lite fork to make it ES6-importable (without nodejs)

// based on https://github.com/kawanet/msgpack-lite/blob/5b71d82cad4b96289a466a6403d2faaa3e254167/lib/ext-packer.js
const codec = msgpack.createCodec();
const packTypedArray = (x) => new Uint8Array(x.buffer, x.byteOffset, x.byteLength);
codec.addExtPacker(0x11, Int8Array, packTypedArray);
codec.addExtPacker(0x12, Uint8Array, packTypedArray);
codec.addExtPacker(0x13, Int16Array, packTypedArray);
codec.addExtPacker(0x14, Uint16Array, packTypedArray);
codec.addExtPacker(0x15, Int32Array, packTypedArray);
codec.addExtPacker(0x16, Uint32Array, packTypedArray);
codec.addExtPacker(0x17, Float32Array, packTypedArray);
codec.addExtPacker(0x18, Float64Array, packTypedArray);

codec.addExtPacker(0x12, Uint8ClampedArray, packTypedArray);
codec.addExtPacker(0x12, ArrayBuffer, (x) => new Uint8Array(x));
codec.addExtPacker(0x12, DataView, packTypedArray);

// Pack and unpack dates. However, encoding a date does throw on Safari because it doesn't have BigInt64Array.
// This isn't too much a problem, as Safari doesn't even support <input type=date /> yet...
// But it does throw when I create a custom @bind that has a Date value...
// For decoding I now also use a "Invalid Date", but the code in https://stackoverflow.com/a/55338384/2681964 did work in Safari.
// Also there is no way now to send an "Invalid Date", so it just does nothing
codec.addExtPacker(0x0d, Date, (d) => new BigInt64Array([BigInt(+d)]));
codec.addExtUnpacker(0x0d, (uintarray) => {
    if ("getBigInt64" in DataView.prototype) {
        let dataview = new DataView(uintarray.buffer, uintarray.byteOffset, uintarray.byteLength);
        let bigint = dataview.getBigInt64(0, true); // true here is "littleEndianes", not sure if this only Works On My Machine©
        if (bigint > Number.MAX_SAFE_INTEGER) {
            throw new Error(`Can't read too big number as date (how far in the future is this?!)`)
        }
        return new Date(Number(bigint))
    } else {
        return new Date(NaN)
    }
});

codec.addExtUnpacker(0x11, (x) => new Int8Array(x.buffer));
codec.addExtUnpacker(0x12, (x) => new Uint8Array(x.buffer));
codec.addExtUnpacker(0x13, (x) => new Int16Array(x.buffer));
codec.addExtUnpacker(0x14, (x) => new Uint16Array(x.buffer));
codec.addExtUnpacker(0x15, (x) => new Int32Array(x.buffer));
codec.addExtUnpacker(0x16, (x) => new Uint32Array(x.buffer));
codec.addExtUnpacker(0x17, (x) => new Float32Array(x.buffer));
codec.addExtUnpacker(0x18, (x) => new Float64Array(x.buffer));

/** @param {any} x */
const pack = (x) => {
    return msgpack.encode(x, { codec: codec })
};

/** @param {Uint8Array} x */
const unpack = (x) => {
    return msgpack.decode(x, { codec: codec })
};

const checkBehavior = (behavior) => {
    return behavior === undefined || behavior === "auto" || behavior === "instant" || behavior === "smooth";
};
function elementScrollXY(x, y) {
    this.scrollLeft = x;
    this.scrollTop = y;
}
const failedExecute = (method, object, reason = "cannot convert to dictionary.") => `Failed to execute '${method}' on '${object}': ${reason}`;
const failedExecuteInvalidEnumValue = (method, object, value) => failedExecute(method, object, `The provided value '${value}' is not a valid enum value of type ScrollBehavior.`);
/* eslint-disable */
const backupMethod = (proto, method, fallback) => {
    var _a;
    const backup = `__SEAMLESS.BACKUP$${method}`;
    if (!proto[backup] && proto[method] && !((_a = proto[method]) === null || _a === void 0 ? void 0 : _a.__isPolyfill)) {
        proto[backup] = proto[method];
    }
    return proto[backup] || fallback;
};
/* eslint-enable */
const isObject$1 = (value) => {
    const type = typeof value;
    return value !== null && (type === "object" || type === "function");
};
const isScrollBehaviorSupported = (config) => "scrollBehavior" in window.document.documentElement.style && (config === null || config === void 0 ? void 0 : config.forcePolyfill) !== true;
const markPolyfill = (method) => {
    Object.defineProperty(method, "__isPolyfill", { value: true });
};
const modifyPrototypes = (prop, func) => {
    markPolyfill(func);
    [HTMLElement.prototype, SVGElement.prototype, Element.prototype].forEach((prototype) => {
        backupMethod(prototype, prop);
        prototype[prop] = func;
    });
};
/**
 * - On Chrome and Firefox, document.scrollingElement will return the <html> element.
 * - Safari, document.scrollingElement will return the <body> element.
 * - On Edge, document.scrollingElement will return the <body> element.
 * - IE11 does not support document.scrollingElement, but you can assume its <html>.
 */
const scrollingElement = (element) => element.ownerDocument.scrollingElement || element.ownerDocument.documentElement;

function scrollEndEvent(bubbles) {
    if (typeof Event === "function") {
        return new Event("scrollend", {
            bubbles,
            cancelable: false,
        });
    }
    const event = document.createEvent("Event");
    event.initEvent("scrollend", bubbles, false);
    return event;
}

const ease = (k) => {
    return 0.5 * (1 - Math.cos(Math.PI * k));
};
/* eslint-disable */
function now() {
    var _a;
    let fn;
    if ((_a = window.performance) === null || _a === void 0 ? void 0 : _a.now) {
        fn = () => window.performance.now();
    }
    else {
        fn = () => window.Date.now();
    }
    // @ts-ignore
    now = fn;
    return fn();
}
/* eslint-enable */
const DURATION = 500;
const step = (context) => {
    const currentTime = now();
    const elapsed = (currentTime - context.timeStamp) / (context.duration || DURATION);
    if (elapsed > 1) {
        context.method(context.targetX, context.targetY);
        context.callback();
        return;
    }
    const value = (context.timingFunc || ease)(elapsed);
    const currentX = context.startX + (context.targetX - context.startX) * value;
    const currentY = context.startY + (context.targetY - context.startY) * value;
    context.method(currentX, currentY);
    context.rafId = window.requestAnimationFrame(() => {
        step(context);
    });
};

// https://drafts.csswg.org/cssom-view/#normalize-non-finite-values
const nonFinite = (value) => {
    if (!isFinite(value)) {
        return 0;
    }
    return Number(value);
};
const isConnected = (node) => {
    var _a;
    return ((_a = node.isConnected) !== null && _a !== void 0 ? _a : (!node.ownerDocument ||
        // eslint-disable-next-line no-bitwise
        !(node.ownerDocument.compareDocumentPosition(node) & /** DOCUMENT_POSITION_DISCONNECTED */ 1)));
};
const scrollWithOptions = (element, options, config) => {
    var _a, _b;
    if (!isConnected(element)) {
        return;
    }
    const startX = element.scrollLeft;
    const startY = element.scrollTop;
    const targetX = nonFinite((_a = options.left) !== null && _a !== void 0 ? _a : startX);
    const targetY = nonFinite((_b = options.top) !== null && _b !== void 0 ? _b : startY);
    if (targetX === startX && targetY === startY) {
        return;
    }
    const fallback = backupMethod(HTMLElement.prototype, "scroll", elementScrollXY);
    const method = backupMethod(Object.getPrototypeOf(element), "scroll", fallback).bind(element);
    if (options.behavior !== "smooth") {
        method(targetX, targetY);
        return;
    }
    const removeEventListener = () => {
        window.removeEventListener("wheel", cancelScroll);
        window.removeEventListener("touchmove", cancelScroll);
    };
    const callback = () => {
        removeEventListener();
        const isDocument = element.nodeType === /** Node.DOCUMENT_NODE */ 9;
        element.dispatchEvent(scrollEndEvent(isDocument));
    };
    const context = Object.assign(Object.assign({}, config), { timeStamp: now(), startX,
        startY,
        targetX,
        targetY, rafId: 0, method,
        callback });
    const cancelScroll = () => {
        window.cancelAnimationFrame(context.rafId);
        removeEventListener();
    };
    window.addEventListener("wheel", cancelScroll, {
        passive: true,
        once: true,
    });
    window.addEventListener("touchmove", cancelScroll, {
        passive: true,
        once: true,
    });
    step(context);
};
const isWindow = (obj) => obj.window === obj;
const createScroll = (scrollName) => (target, scrollOptions, config) => {
    const [element, scrollType] = isWindow(target)
        ? [scrollingElement(target.document.documentElement), "Window"]
        : [target, "Element"];
    const options = scrollOptions !== null && scrollOptions !== void 0 ? scrollOptions : {};
    if (!isObject$1(options)) {
        throw new TypeError(failedExecute(scrollName, scrollType));
    }
    if (!checkBehavior(options.behavior)) {
        throw new TypeError(failedExecuteInvalidEnumValue(scrollName, scrollType, options.behavior));
    }
    if (scrollName === "scrollBy") {
        options.left = nonFinite(options.left) + element.scrollLeft;
        options.top = nonFinite(options.top) + element.scrollTop;
    }
    scrollWithOptions(element, options, config);
};
const scroll = /* #__PURE__ */ createScroll("scroll");
const scrollTo = /* #__PURE__ */ createScroll("scrollTo");
const scrollBy = /* #__PURE__ */ createScroll("scrollBy");
const elementScroll = scroll;

const createPolyfill = (scrollName, patch) => (config) => {
    if (isScrollBehaviorSupported(config)) {
        return;
    }
    const scrollMethod = {
        scroll,
        scrollTo,
        scrollBy,
    }[scrollName];
    patch(scrollName, function () {
        const args = arguments;
        if (arguments.length === 1) {
            scrollMethod(this, args[0], config);
            return;
        }
        const left = args[0];
        const top = args[1];
        scrollMethod(this, { left, top });
    });
};
const elementScrollPolyfill = /* #__PURE__ */ createPolyfill("scroll", modifyPrototypes);
const elementScrollToPolyfill = /* #__PURE__ */ createPolyfill("scrollTo", modifyPrototypes);
const elementScrollByPolyfill = /* #__PURE__ */ createPolyfill("scrollBy", modifyPrototypes);
const modifyWindow = (prop, func) => {
    markPolyfill(func);
    backupMethod(window, prop);
    window[prop] = func;
};
const windowScrollPolyfill = /* #__PURE__ */ createPolyfill("scroll", modifyWindow);
const windowScrollToPolyfill = /* #__PURE__ */ createPolyfill("scrollTo", modifyWindow);
const windowScrollByPolyfill = /* #__PURE__ */ createPolyfill("scrollBy", modifyWindow);

/* eslint-disable no-bitwise */
// https://drafts.csswg.org/css-writing-modes-4/#block-flow
const normalizeWritingMode = (writingMode) => {
    switch (writingMode) {
        case "horizontal-tb":
        case "lr":
        case "lr-tb":
        case "rl":
        case "rl-tb":
            return 0 /* WritingMode.HorizontalTb */;
        case "vertical-rl":
        case "tb":
        case "tb-rl":
            return 1 /* WritingMode.VerticalRl */;
        case "vertical-lr":
        case "tb-lr":
            return 2 /* WritingMode.VerticalLr */;
        case "sideways-rl":
            return 3 /* WritingMode.SidewaysRl */;
        case "sideways-lr":
            return 4 /* WritingMode.SidewaysLr */;
    }
    return 0 /* WritingMode.HorizontalTb */;
};
const calcPhysicalAxis = (writingMode, isLTR, hPos, vPos) => {
    /**  0b{vertical}{horizontal}  0: normal, 1: reverse */
    let layout = 0b00;
    /**
     * WritingMode.VerticalLr: ↓→
     * | 1 | 4 |   |
     * | 2 | 5 |   |
     * | 3 |   |   |
     *
     * RTL: ↑→
     * | 3 |   |   |
     * | 2 | 5 |   |
     * | 1 | 4 |   |
     */
    if (!isLTR) {
        layout ^= 2 /* OP.ReverseVertical */;
    }
    switch (writingMode) {
        /**
         * ↓→
         * | 1 | 2 | 3 |
         * | 4 | 5 |   |
         * |   |   |   |
         *
         * RTL: ↓←
         * | 3 | 2 | 1 |
         * |   | 5 | 4 |
         * |   |   |   |
         */
        case 0 /* WritingMode.HorizontalTb */:
            // swap horizontal and vertical
            layout = (layout >> 1) | ((layout & 1) << 1);
            [hPos, vPos] = [vPos, hPos];
            break;
        /**
         * ↓←
         * |   | 4 | 1 |
         * |   | 5 | 2 |
         * |   |   | 3 |
         *
         * RTL: ↑←
         * |   |   | 3 |
         * |   | 5 | 2 |
         * |   | 4 | 1 |
         */
        case 1 /* WritingMode.VerticalRl */:
        case 3 /* WritingMode.SidewaysRl */:
            //  reverse horizontal
            layout ^= 1 /* OP.ReverseHorizontal */;
            break;
        /**
         * ↑→
         * | 3 |   |   |
         * | 2 | 5 |   |
         * | 1 | 4 |   |
         *
         * RTL: ↓→
         * | 1 | 4 |   |
         * | 2 | 5 |   |
         * | 3 |   |   |
         */
        case 4 /* WritingMode.SidewaysLr */:
            // reverse vertical
            layout ^= 2 /* OP.ReverseVertical */;
            break;
    }
    return [layout, hPos, vPos];
};
const isXReversed = (computedStyle) => {
    const layout = calcPhysicalAxis(normalizeWritingMode(computedStyle.writingMode), computedStyle.direction !== "rtl", undefined, undefined)[0];
    return (layout & 1) === 1;
};
// https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/core/dom/element.cc;l=1097-1189;drc=6a7533d4a1e9f2372223a9d912a9e53a6fa35ae0
const toPhysicalAlignment = (options, writingMode, isLTR) => {
    const [layout, hPos, vPos] = calcPhysicalAxis(writingMode, isLTR, options.block || "start", options.inline || "nearest");
    return [hPos, vPos].map((value, index) => {
        switch (value) {
            case "center":
                return 1 /* ScrollAlignment.CenterAlways */;
            case "nearest":
                return 0 /* ScrollAlignment.ToEdgeIfNeeded */;
            default: {
                const reverse = (layout >> index) & 1;
                return (value === "start") === !reverse ? 2 /* ScrollAlignment.LeftOrTop */ : 3 /* ScrollAlignment.RightOrBottom */;
            }
        }
    });
};
// code from stipsan/compute-scroll-into-view
// https://github.com/stipsan/compute-scroll-into-view/blob/5396c6b78af5d0bbce11a7c4e93cc3146546fcd3/src/index.ts
/**
 * Find out which edge to align against when logical scroll position is "nearest"
 * Interesting fact: "nearest" works similarily to "if-needed", if the element is fully visible it will not scroll it
 *
 * Legends:
 * ┌────────┐ ┏ ━ ━ ━ ┓
 * │ target │   frame
 * └────────┘ ┗ ━ ━ ━ ┛
 */
const mapNearest = (align, scrollingEdgeStart, scrollingEdgeEnd, scrollingSize, elementEdgeStart, elementEdgeEnd, elementSize) => {
    if (align !== 0 /* ScrollAlignment.ToEdgeIfNeeded */) {
        return align;
    }
    /**
     * If element edge A and element edge B are both outside scrolling box edge A and scrolling box edge B
     *
     *          ┌──┐
     *        ┏━│━━│━┓
     *          │  │
     *        ┃ │  │ ┃        do nothing
     *          │  │
     *        ┗━│━━│━┛
     *          └──┘
     *
     *  If element edge C and element edge D are both outside scrolling box edge C and scrolling box edge D
     *
     *    ┏ ━ ━ ━ ━ ┓
     *   ┌───────────┐
     *   │┃         ┃│        do nothing
     *   └───────────┘
     *    ┗ ━ ━ ━ ━ ┛
     */
    if ((elementEdgeStart < scrollingEdgeStart && elementEdgeEnd > scrollingEdgeEnd) ||
        (elementEdgeStart > scrollingEdgeStart && elementEdgeEnd < scrollingEdgeEnd)) {
        return null;
    }
    /**
     * If element edge A is outside scrolling box edge A and element height is less than scrolling box height
     *
     *          ┌──┐
     *        ┏━│━━│━┓         ┏━┌━━┐━┓
     *          └──┘             │  │
     *  from  ┃      ┃     to  ┃ └──┘ ┃
     *
     *        ┗━ ━━ ━┛         ┗━ ━━ ━┛
     *
     * If element edge B is outside scrolling box edge B and element height is greater than scrolling box height
     *
     *        ┏━ ━━ ━┓         ┏━┌━━┐━┓
     *                           │  │
     *  from  ┃ ┌──┐ ┃     to  ┃ │  │ ┃
     *          │  │             │  │
     *        ┗━│━━│━┛         ┗━│━━│━┛
     *          │  │             └──┘
     *          │  │
     *          └──┘
     *
     * If element edge C is outside scrolling box edge C and element width is less than scrolling box width
     *
     *       from                 to
     *    ┏ ━ ━ ━ ━ ┓         ┏ ━ ━ ━ ━ ┓
     *  ┌───┐                 ┌───┐
     *  │ ┃ │       ┃         ┃   │     ┃
     *  └───┘                 └───┘
     *    ┗ ━ ━ ━ ━ ┛         ┗ ━ ━ ━ ━ ┛
     *
     * If element edge D is outside scrolling box edge D and element width is greater than scrolling box width
     *
     *       from                 to
     *    ┏ ━ ━ ━ ━ ┓         ┏ ━ ━ ━ ━ ┓
     *        ┌───────────┐   ┌───────────┐
     *    ┃   │     ┃     │   ┃         ┃ │
     *        └───────────┘   └───────────┘
     *    ┗ ━ ━ ━ ━ ┛         ┗ ━ ━ ━ ━ ┛
     */
    if ((elementEdgeStart <= scrollingEdgeStart && elementSize <= scrollingSize) ||
        (elementEdgeEnd >= scrollingEdgeEnd && elementSize >= scrollingSize)) {
        return 2 /* ScrollAlignment.LeftOrTop */;
    }
    /**
     * If element edge B is outside scrolling box edge B and element height is less than scrolling box height
     *
     *        ┏━ ━━ ━┓         ┏━ ━━ ━┓
     *
     *  from  ┃      ┃     to  ┃ ┌──┐ ┃
     *          ┌──┐             │  │
     *        ┗━│━━│━┛         ┗━└━━┘━┛
     *          └──┘
     *
     * If element edge A is outside scrolling box edge A and element height is greater than scrolling box height
     *
     *          ┌──┐
     *          │  │
     *          │  │             ┌──┐
     *        ┏━│━━│━┓         ┏━│━━│━┓
     *          │  │             │  │
     *  from  ┃ └──┘ ┃     to  ┃ │  │ ┃
     *                           │  │
     *        ┗━ ━━ ━┛         ┗━└━━┘━┛
     *
     * If element edge C is outside scrolling box edge C and element width is greater than scrolling box width
     *
     *           from                 to
     *        ┏ ━ ━ ━ ━ ┓         ┏ ━ ━ ━ ━ ┓
     *  ┌───────────┐           ┌───────────┐
     *  │     ┃     │   ┃       │ ┃         ┃
     *  └───────────┘           └───────────┘
     *        ┗ ━ ━ ━ ━ ┛         ┗ ━ ━ ━ ━ ┛
     *
     * If element edge D is outside scrolling box edge D and element width is less than scrolling box width
     *
     *           from                 to
     *        ┏ ━ ━ ━ ━ ┓         ┏ ━ ━ ━ ━ ┓
     *                ┌───┐             ┌───┐
     *        ┃       │ ┃ │       ┃     │   ┃
     *                └───┘             └───┘
     *        ┗ ━ ━ ━ ━ ┛         ┗ ━ ━ ━ ━ ┛
     *
     */
    if ((elementEdgeEnd > scrollingEdgeEnd && elementSize < scrollingSize) ||
        (elementEdgeStart < scrollingEdgeStart && elementSize > scrollingSize)) {
        return 3 /* ScrollAlignment.RightOrBottom */;
    }
    return null;
};
const canOverflow = (overflow) => {
    return overflow !== "visible" && overflow !== "clip";
};
const getFrameElement = (element) => {
    var _a;
    try {
        return ((_a = element.ownerDocument.defaultView) === null || _a === void 0 ? void 0 : _a.frameElement) || null;
    }
    catch (_b) {
        return null;
    }
};
const isScrollable = (element, computedStyle) => {
    if (element.clientHeight < element.scrollHeight || element.clientWidth < element.scrollWidth) {
        return (canOverflow(computedStyle.overflowY) ||
            canOverflow(computedStyle.overflowX) ||
            element === scrollingElement(element));
    }
    return false;
};
const parentElement = (element) => {
    const pNode = element.parentNode;
    const pElement = element.parentElement;
    if (pElement === null && pNode !== null) {
        if (pNode.nodeType === /** Node.DOCUMENT_FRAGMENT_NODE */ 11) {
            return pNode.host;
        }
        if (pNode.nodeType === /** Node.DOCUMENT_NODE */ 9) {
            return getFrameElement(element);
        }
    }
    return pElement;
};
const clamp = (value, min, max) => {
    if (value < min) {
        return min;
    }
    if (value > max) {
        return max;
    }
    return value;
};
const getSupportedScrollMarginProperty = (ownerDocument) => {
    // Webkit uses "scroll-snap-margin" https://bugs.webkit.org/show_bug.cgi?id=189265.
    return ["scroll-margin", "scroll-snap-margin"].filter((property) => property in ownerDocument.documentElement.style)[0];
};
const getElementScrollSnapArea = (element, elementRect, computedStyle) => {
    const { top, right, bottom, left } = elementRect;
    const scrollProperty = getSupportedScrollMarginProperty(element.ownerDocument);
    if (!scrollProperty) {
        return [top, right, bottom, left];
    }
    const scrollMarginValue = (edge) => {
        const value = computedStyle.getPropertyValue(`${scrollProperty}-${edge}`);
        return parseInt(value, 10) || 0;
    };
    return [
        top - scrollMarginValue("top"),
        right + scrollMarginValue("right"),
        bottom + scrollMarginValue("bottom"),
        left - scrollMarginValue("left"),
    ];
};
const calcAlignEdge = (align, start, end) => {
    switch (align) {
        case 1 /* ScrollAlignment.CenterAlways */:
            return (start + end) / 2;
        case 3 /* ScrollAlignment.RightOrBottom */:
            return end;
        case 2 /* ScrollAlignment.LeftOrTop */:
        case 0 /* ScrollAlignment.ToEdgeIfNeeded */:
            return start;
    }
};
const getFrameViewport = (frame, frameRect) => {
    var _a, _b, _c;
    const visualViewport = (_a = frame.ownerDocument.defaultView) === null || _a === void 0 ? void 0 : _a.visualViewport;
    const [x, y, width, height] = frame === scrollingElement(frame)
        ? [0, 0, (_b = visualViewport === null || visualViewport === void 0 ? void 0 : visualViewport.width) !== null && _b !== void 0 ? _b : frame.clientWidth, (_c = visualViewport === null || visualViewport === void 0 ? void 0 : visualViewport.height) !== null && _c !== void 0 ? _c : frame.clientHeight]
        : [frameRect.left, frameRect.top, frame.clientWidth, frame.clientHeight];
    const left = x + frame.clientLeft;
    const top = y + frame.clientTop;
    const right = left + width;
    const bottom = top + height;
    return [top, right, bottom, left];
};
const computeScrollIntoView = (element, options) => {
    // Collect all the scrolling boxes, as defined in the spec: https://drafts.csswg.org/cssom-view/#scrolling-box
    const actions = [];
    let ownerDocument = element.ownerDocument;
    let ownerWindow = ownerDocument.defaultView;
    if (!ownerWindow) {
        return actions;
    }
    const computedStyle = window.getComputedStyle(element);
    const isLTR = computedStyle.direction !== "rtl";
    const writingMode = normalizeWritingMode(computedStyle.writingMode ||
        computedStyle.getPropertyValue("-webkit-writing-mode") ||
        computedStyle.getPropertyValue("-ms-writing-mode"));
    const [alignH, alignV] = toPhysicalAlignment(options, writingMode, isLTR);
    let [top, right, bottom, left] = getElementScrollSnapArea(element, element.getBoundingClientRect(), computedStyle);
    for (let frame = parentElement(element); frame !== null; frame = parentElement(frame)) {
        if (ownerDocument !== frame.ownerDocument) {
            ownerDocument = frame.ownerDocument;
            ownerWindow = ownerDocument.defaultView;
            if (!ownerWindow) {
                break;
            }
            const { left: dX, top: dY } = frame.getBoundingClientRect();
            top += dY;
            right += dX;
            bottom += dY;
            left += dX;
        }
        const frameStyle = ownerWindow.getComputedStyle(frame);
        if (frameStyle.position === "fixed") {
            break;
        }
        if (!isScrollable(frame, frameStyle)) {
            continue;
        }
        const frameRect = frame.getBoundingClientRect();
        const [frameTop, frameRight, frameBottom, frameLeft] = getFrameViewport(frame, frameRect);
        const eAlignH = mapNearest(alignH, frameLeft, frameRight, frame.clientWidth, left, right, right - left);
        const eAlignV = mapNearest(alignV, frameTop, frameBottom, frame.clientHeight, top, bottom, bottom - top);
        const diffX = eAlignH === null ? 0 : calcAlignEdge(eAlignH, left, right) - calcAlignEdge(eAlignH, frameLeft, frameRight);
        const diffY = eAlignV === null ? 0 : calcAlignEdge(eAlignV, top, bottom) - calcAlignEdge(eAlignV, frameTop, frameBottom);
        const moveX = isXReversed(frameStyle)
            ? clamp(diffX, -frame.scrollWidth + frame.clientWidth - frame.scrollLeft, -frame.scrollLeft)
            : clamp(diffX, -frame.scrollLeft, frame.scrollWidth - frame.clientWidth - frame.scrollLeft);
        const moveY = clamp(diffY, -frame.scrollTop, frame.scrollHeight - frame.clientHeight - frame.scrollTop);
        actions.push([
            frame,
            { left: frame.scrollLeft + moveX, top: frame.scrollTop + moveY, behavior: options.behavior },
        ]);
        top = Math.max(top - moveY, frameTop);
        right = Math.min(right - moveX, frameRight);
        bottom = Math.min(bottom - moveY, frameBottom);
        left = Math.max(left - moveX, frameLeft);
    }
    return actions;
};
const scrollIntoView = (element, scrollIntoViewOptions, config) => {
    const options = scrollIntoViewOptions || {};
    if (!checkBehavior(options.behavior)) {
        throw new TypeError(failedExecuteInvalidEnumValue("scrollIntoView", "Element", options.behavior));
    }
    const actions = computeScrollIntoView(element, options);
    actions.forEach(([frame, scrollToOptions]) => {
        elementScroll(frame, scrollToOptions, config);
    });
};
const elementScrollIntoView = scrollIntoView;

function elementScrollIntoViewBoolean(alignToTop) {
    elementScrollIntoView(this, {
        block: (alignToTop !== null && alignToTop !== void 0 ? alignToTop : true) ? "start" : "end",
        inline: "nearest",
    });
}
const elementScrollIntoViewPolyfill = (config) => {
    if (isScrollBehaviorSupported(config)) {
        return;
    }
    const originalFunc = backupMethod(window.HTMLElement.prototype, "scrollIntoView", elementScrollIntoViewBoolean);
    modifyPrototypes("scrollIntoView", function scrollIntoView() {
        const args = arguments;
        const options = args[0];
        if (args.length === 1 && isObject$1(options)) {
            elementScrollIntoView(this, options, config);
            return;
        }
        originalFunc.apply(this, args);
    });
};

const polyfill = (config) => {
    if (isScrollBehaviorSupported(config)) {
        return;
    }
    elementScrollPolyfill(config);
    elementScrollToPolyfill(config);
    elementScrollByPolyfill(config);
    elementScrollIntoViewPolyfill(config);
    windowScrollPolyfill(config);
    windowScrollToPolyfill(config);
    windowScrollByPolyfill(config);
};

// Polyfill for Blob::text when there is none (safari)
// This is not "officialy" supported
if (Blob.prototype.text == null) {
    Blob.prototype.text = function () {
        const reader = new FileReader();
        const promise = new Promise((resolve, reject) => {
            // on read success
            reader.onload = () => {
                resolve(reader.result);
            };
            // on failure
            reader.onerror = (e) => {
                reader.abort();
                reject(e);
            };
        });
        reader.readAsText(this);
        return promise
    };
}

// Polyfill for Blob::arrayBuffer when there is none (safari)
// This is not "officialy" supported
if (Blob.prototype.arrayBuffer == null) {
    Blob.prototype.arrayBuffer = function () {
        return new Response(this).arrayBuffer()
    };
}

polyfill();

/**
 * @template T
 * @type {Stack<T>}
 */
class Stack {
    /**
     * @param {number} max_size
     */
    constructor(max_size) {
        this.max_size = max_size;
        this.arr = [];
    }
    /**
     * @param {T} item
     * @returns {void}
     */
    push(item) {
        this.arr.push(item);
        if (this.arr.length > this.max_size) {
            this.arr.shift();
        }
    }
    /**
     * @returns {T[]}
     */
    get() {
        return this.arr
    }
}

const with_query_params = (/** @type {String | URL} */ url_str, /** @type {Record<string,string | null | undefined>} */ params) => {
    const fake_base = "http://delete-me.com/";
    const url = new URL(url_str, fake_base);
    Object.entries(params).forEach(([key, val]) => {
        if (val != null) url.searchParams.append(key, val);
    });
    return url.toString().replace(fake_base, "")
};

console.assert(with_query_params("https://example.com/", { a: "b c" }) === "https://example.com/?a=b+c");
console.assert(with_query_params(new URL("https://example.com/"), { a: "b c" }) === "https://example.com/?a=b+c");
console.assert(with_query_params(new URL("https://example.com/"), { a: "b c", asdf: null, xx: "123" }) === "https://example.com/?a=b+c&xx=123");
console.assert(with_query_params("index.html", { a: "b c" }) === "index.html?a=b+c");
console.assert(with_query_params("index.html?x=123", { a: "b c" }) === "index.html?x=123&a=b+c");
console.assert(with_query_params("index.html?x=123#asdf", { a: "b c" }) === "index.html?x=123&a=b+c#asdf");

const reconnect_after_close_delay = 500;
const retry_after_connect_failure_delay = 5000;

/**
 * @template T
 * @returns {{current: Promise<T>, resolve: (value: T) => void, reject: (error: any) => void }}
 */
const resolvable_promise = () => {
    let resolve = () => {};
    let reject = () => {};
    const p = new Promise((_resolve, _reject) => {
        //@ts-ignore
        resolve = _resolve;
        reject = _reject;
    });
    return {
        current: p,
        resolve: resolve,
        reject: reject,
    }
};

/**
 * @returns {string}
 */
const get_unique_short_id = () => crypto.getRandomValues(new Uint32Array(1))[0].toString(36);

const socket_is_alright = (socket) => socket.readyState == WebSocket.OPEN || socket.readyState == WebSocket.CONNECTING;

const socket_is_alright_with_grace_period = (socket) =>
    new Promise((res) => {
        if (socket_is_alright(socket)) {
            res(true);
        } else {
            setTimeout(() => {
                res(socket_is_alright(socket));
            }, 1000);
        }
    });

const try_close_socket_connection = (/** @type {WebSocket} */ socket) => {
    socket.onopen = () => {
        try_close_socket_connection(socket);
    };
    socket.onmessage = socket.onclose = socket.onerror = null;
    try {
        socket.close(1000, "byebye");
    } catch (ex) {}
};

/**
 * Open a 'raw' websocket connection to an API with MessagePack serialization. The method is asynchonous, and resolves to a @see WebsocketConnection when the connection is established.
 * @typedef {{socket: WebSocket, send: Function}} WebsocketConnection
 * @param {string} address The WebSocket URL
 * @param {{on_message: Function, on_socket_close:Function}} callbacks
 * @param {number} timeout_s Timeout for creating the websocket connection (seconds)
 * @returns {Promise<WebsocketConnection>}
 */
const create_ws_connection = (address, { on_message, on_socket_close }, timeout_s = 30) => {
    return new Promise((resolve, reject) => {
        const socket = new WebSocket(address);

        let has_been_open = false;

        const timeout_handle = setTimeout(() => {
            console.warn("Creating websocket timed out", new Date().toLocaleTimeString());
            try_close_socket_connection(socket);
            reject("Socket timeout");
        }, timeout_s * 1000);

        const send_encoded = (message) => {
            const encoded = pack(message);
            if (socket.readyState === WebSocket.CLOSED || socket.readyState === WebSocket.CLOSING) throw new Error("Socket is closed")
            socket.send(encoded);
        };

        let last_task = Promise.resolve();
        socket.onmessage = (event) => {
            // we read and deserialize the incoming messages asynchronously
            // they arrive in order (WS guarantees this), i.e. this socket.onmessage event gets fired with the message events in the right order
            // but some message are read and deserialized much faster than others, because of varying sizes, so _after_ async read & deserialization, messages are no longer guaranteed to be in order
            //
            // the solution is a task queue, where each task includes the deserialization and the update handler
            last_task = last_task.then(async () => {
                try {
                    const buffer = await event.data.arrayBuffer();
                    const message = unpack(new Uint8Array(buffer));

                    try {
                        on_message(message);
                    } catch (process_err) {
                        console.error("Failed to process message from websocket", process_err, { message });
                        // prettier-ignore
                        alert(`Something went wrong! You might need to refresh the page.\n\nPlease open an issue on https://github.com/fonsp/Pluto.jl with this info:\n\nFailed to process update\n${process_err.message}\n\n${JSON.stringify(event)}`);
                    }
                } catch (unpack_err) {
                    console.error("Failed to unpack message from websocket", unpack_err, { event });

                    // prettier-ignore
                    alert(`Something went wrong! You might need to refresh the page.\n\nPlease open an issue on https://github.com/fonsp/Pluto.jl with this info:\n\nFailed to unpack message\n${unpack_err}\n\n${JSON.stringify(event)}`);
                }
            });
        };

        socket.onerror = async (e) => {
            console.error(`Socket did an oopsie - ${e.type}`, new Date().toLocaleTimeString(), "was open:", has_been_open, e);

            if (await socket_is_alright_with_grace_period(socket)) {
                console.log("The socket somehow recovered from an error?! Onbegrijpelijk");
                console.log(socket);
                console.log(socket.readyState);
            } else {
                if (has_been_open) {
                    on_socket_close();
                    try_close_socket_connection(socket);
                } else {
                    reject(e);
                }
            }
        };
        socket.onclose = async (e) => {
            console.warn(`Socket did an oopsie - ${e.type}`, new Date().toLocaleTimeString(), "was open:", has_been_open, e);

            if (has_been_open) {
                on_socket_close();
                try_close_socket_connection(socket);
            } else {
                reject(e);
            }
        };
        socket.onopen = () => {
            console.log("Socket opened", new Date().toLocaleTimeString());
            clearInterval(timeout_handle);
            has_been_open = true;
            resolve({
                socket: socket,
                send: send_encoded,
            });
        };
        console.log("Waiting for socket to open...", new Date().toLocaleTimeString());
    })
};

let next_tick_promise = () => {
    return new Promise((resolve) => setTimeout(resolve, 0))
};

/**
 * batched_updates(send) creates a wrapper around the real send, and understands the update_notebook messages.
 * Whenever those are sent, it will wait for a "tick" (basically the end of the code running now)
 * and then send all updates from this tick at once. We use this to fix https://github.com/fonsp/Pluto.jl/issues/928
 *
 * I need to put it here so other code,
 * like running cells, will also wait for the updates to complete.
 * I SHALL MAKE IT MORE COMPLEX! (https://www.youtube.com/watch?v=aO3JgPUJ6iQ&t=195s)
 * @param {import("./PlutoConnectionSendFn").SendFn} send
 * @returns {import("./PlutoConnectionSendFn").SendFn}
 */
const batched_updates = (send) => {
    let current_combined_updates_promise = null;
    let current_combined_updates = [];
    let current_combined_notebook_id = null;

    let batched = async (message_type, body, metadata, no_broadcast) => {
        if (message_type === "update_notebook") {
            if (current_combined_notebook_id != null && current_combined_notebook_id != metadata.notebook_id) {
                // prettier-ignore
                throw new Error("Switched notebook inbetween same-tick updates??? WHAT?!?!")
            }
            current_combined_updates = [...current_combined_updates, ...body.updates];
            current_combined_notebook_id = metadata.notebook_id;

            if (current_combined_updates_promise == null) {
                current_combined_updates_promise = next_tick_promise().then(async () => {
                    let sending_current_combined_updates = current_combined_updates;
                    current_combined_updates_promise = null;
                    current_combined_updates = [];
                    current_combined_notebook_id = null;
                    return await send(message_type, { updates: sending_current_combined_updates }, metadata, no_broadcast)
                });
            }

            return await current_combined_updates_promise
        } else {
            return await send(message_type, body, metadata, no_broadcast)
        }
    };

    return batched
};

const ws_address_from_base = (/** @type {string | URL} */ base_url) => {
    const ws_url = new URL("./", base_url);
    ws_url.protocol = ws_url.protocol.replace("http", "ws");

    // if the original URL had a secret in the URL, we can also add it here:
    const ws_url_with_secret = with_query_params(ws_url, { secret: new URL(base_url).searchParams.get("secret") });

    return ws_url_with_secret
};

const auth_check_url_from_ws = (/** @type {string | URL} */ ws_url) => {
    const auth_url = new URL("./auth-check", ws_url);
    auth_url.protocol = auth_url.protocol.replace("ws", "http");
    return auth_url.toString()
};

const default_ws_address = () => ws_address_from_base(window.location.href);

/**
 * @typedef PlutoConnection
 * @type {{
 *  session_options: Record<string,any>,
 *  send: import("./PlutoConnectionSendFn").SendFn,
 *  kill: (allow_reconnect?: boolean) => void,
 *  version_info: {
 *      julia: string,
 *      pluto: string,
 *      dismiss_update_notification: boolean,
 *  },
 *  notebook_exists: boolean,
 *  message_log: import("./Stack.js").Stack<any>,
 * }}
 */

/**
 * @typedef PlutoMessage
 * @type {any}
 */

/**
 * Open a connection with Pluto, that supports a question-response mechanism. The method is asynchonous, and resolves to a @see PlutoConnection when the connection is established.
 *
 * The server can also send messages to all clients, without being requested by them. These end up in the @see on_unrequested_update callback.
 *
 * @param {{
 *  on_unrequested_update: (message: PlutoMessage, by_me: boolean) => void,
 *  on_reconnect: () => Promise<boolean>,
 *  on_connection_status: (connection_status: boolean, hopeless: boolean) => void,
 *  connect_metadata?: Object,
 *  ws_address?: String,
 * }} options
 * @return {Promise<PlutoConnection>}
 */
const create_pluto_connection = async ({
    on_unrequested_update,
    on_reconnect,
    on_connection_status,
    connect_metadata = {},
    ws_address = default_ws_address(),
}) => {
    let ws_connection = /** @type {WebsocketConnection?} */ (null); // will be defined later i promise
    const message_log = new Stack(100);
    // @ts-ignore
    window.pluto_get_message_log = () => message_log.get();
    let auto_reconnect = true;

    const client = {
        // send: null,
        // session_options: null,
        version_info: {
            julia: "unknown",
            pluto: "unknown",
            dismiss_update_notification: false,
        },
        notebook_exists: true,
        // kill: null,
        message_log,
    }; // same

    const client_id = get_unique_short_id();
    const sent_requests = new Map();

    /** @type {import("./PlutoConnectionSendFn").SendFn} */
    const send = async (message_type, body = {}, metadata = {}, no_broadcast = true) => {
        if (ws_connection == null) {
            throw new Error("No connection established yet")
        }
        const request_id = get_unique_short_id();

        // This data will be sent:
        const message = {
            type: message_type,
            client_id: client_id,
            request_id: request_id,
            body: body,
            ...metadata,
        };

        let p = resolvable_promise();

        sent_requests.set(request_id, (response_message) => {
            p.resolve(response_message);
            if (no_broadcast === false) {
                on_unrequested_update(response_message, true);
            }
        });

        ws_connection.send(message);
        return await p.current
    };

    client.send = batched_updates(send);

    const connect = async () => {
        let update_url_with_binder_token = async () => {
            try {
                const on_a_binder_server = window.location.href.includes("binder");
                if (!on_a_binder_server) return
                const url = new URL(window.location.href);
                const response = await fetch("possible_binder_token_please");
                if (!response.ok) {
                    return
                }
                const possible_binder_token = await response.text();
                if (possible_binder_token !== "" && url.searchParams.get("token") !== possible_binder_token) {
                    url.searchParams.set("token", possible_binder_token);
                    history.replaceState({}, "", url.toString());
                }
            } catch (error) {
                console.warn("Error while setting binder url:", error);
            }
        };
        update_url_with_binder_token();

        try {
            ws_connection = await create_ws_connection(String(ws_address), {
                on_message: (update) => {
                    message_log.push(update);

                    const by_me = update.initiator_id == client_id;
                    const request_id = update.request_id;

                    if (by_me && request_id) {
                        const request = sent_requests.get(request_id);
                        if (request) {
                            request(update);
                            sent_requests.delete(request_id);
                            return
                        }
                    }
                    on_unrequested_update(update, by_me);
                },
                on_socket_close: async () => {
                    on_connection_status(false, false);
                    if (!auto_reconnect) {
                        console.log("Auto-reconnect is disabled, so we're not reconnecting");
                        on_connection_status(false, true);
                        return
                    }

                    console.log(`Starting new websocket`, new Date().toLocaleTimeString());
                    await Promises.delay(reconnect_after_close_delay);
                    await connect(); // reconnect!

                    console.log(`Starting state sync`, new Date().toLocaleTimeString());
                    const accept = await on_reconnect();
                    console.log(`State sync ${accept ? "" : "not "}successful`, new Date().toLocaleTimeString());
                    on_connection_status(accept, false);
                    if (!accept) {
                        alert("Connection out of sync 😥\n\nRefresh the page to continue");
                    }
                },
            });

            // let's say hello
            console.log("Hello?");
            const u = await send("connect", {}, connect_metadata);
            console.log("Hello!");
            client.kill = (allow_reconnect = true) => {
                auto_reconnect = allow_reconnect;
                if (ws_connection) ws_connection.socket.close();
            };
            client.session_options = u.message.session_options;
            client.version_info = u.message.version_info;
            client.notebook_exists = u.message.notebook_exists;

            console.log("Client object: ", client);

            if (connect_metadata.notebook_id != null && !u.message.notebook_exists) {
                on_connection_status(false, true);
                return {}
            }
            on_connection_status(true, false);

            const ping = () => {
                send("ping", {}, {})
                    .then(() => {
                        // Ping faster than timeout?
                        setTimeout(ping, 28 * 1000);
                    })
                    .catch(() => undefined);
            };
            ping();

            return u.message
        } catch (ex) {
            console.error("connect() failed", ex);
            alert_if_not_authenticated(ws_address, ex).catch(() => null); // No await, we want this to run in the background
            await Promises.delay(retry_after_connect_failure_delay);
            return await connect()
        }
    };
    await connect();

    return /** @type {PlutoConnection} */ (client)
};

const alert_if_not_authenticated = async (/** @type {string | URL} */ ws_url, ex) => {
    if (ex instanceof CloseEvent) {
        if (ex.code === 1006) {
            const auth_url = auth_check_url_from_ws(ws_url);
            const response = await fetch(auth_url);
            if (response.status === 403 || response.status === 401) {
                alert("This window has lost authentication to the Pluto server. Please refresh the page to continue.");
            }
        }
    }
};

const ProcessStatus = {
    starting: "starting"};

// src/utils/env.ts
var NOTHING = Symbol.for("immer-nothing");
var DRAFTABLE = Symbol.for("immer-draftable");
var DRAFT_STATE = Symbol.for("immer-state");

// src/utils/errors.ts
var errors = process.env.NODE_ENV !== "production" ? [
  // All error codes, starting by 0:
  function(plugin) {
    return `The plugin for '${plugin}' has not been loaded into Immer. To enable the plugin, import and call \`enable${plugin}()\` when initializing your application.`;
  },
  function(thing) {
    return `produce can only be called on things that are draftable: plain objects, arrays, Map, Set or classes that are marked with '[immerable]: true'. Got '${thing}'`;
  },
  "This object has been frozen and should not be mutated",
  function(data) {
    return "Cannot use a proxy that has been revoked. Did you pass an object from inside an immer function to an async process? " + data;
  },
  "An immer producer returned a new value *and* modified its draft. Either return a new value *or* modify the draft.",
  "Immer forbids circular references",
  "The first or second argument to `produce` must be a function",
  "The third argument to `produce` must be a function or undefined",
  "First argument to `createDraft` must be a plain object, an array, or an immerable object",
  "First argument to `finishDraft` must be a draft returned by `createDraft`",
  function(thing) {
    return `'current' expects a draft, got: ${thing}`;
  },
  "Object.defineProperty() cannot be used on an Immer draft",
  "Object.setPrototypeOf() cannot be used on an Immer draft",
  "Immer only supports deleting array indices",
  "Immer only supports setting array indices and the 'length' property",
  function(thing) {
    return `'original' expects a draft, got: ${thing}`;
  }
  // Note: if more errors are added, the errorOffset in Patches.ts should be increased
  // See Patches.ts for additional errors
] : [];
function die(error, ...args) {
  if (process.env.NODE_ENV !== "production") {
    const e = errors[error];
    const msg = typeof e === "function" ? e.apply(null, args) : e;
    throw new Error(`[Immer] ${msg}`);
  }
  throw new Error(
    `[Immer] minified error nr: ${error}. Full error at: https://bit.ly/3cXEKWf`
  );
}

// src/utils/common.ts
var getPrototypeOf = Object.getPrototypeOf;
function isDraft(value) {
  return !!value && !!value[DRAFT_STATE];
}
function isDraftable(value) {
  if (!value)
    return false;
  return isPlainObject(value) || Array.isArray(value) || !!value[DRAFTABLE] || !!value.constructor?.[DRAFTABLE] || isMap(value) || isSet(value);
}
var objectCtorString = Object.prototype.constructor.toString();
var cachedCtorStrings = /* @__PURE__ */ new WeakMap();
function isPlainObject(value) {
  if (!value || typeof value !== "object")
    return false;
  const proto = Object.getPrototypeOf(value);
  if (proto === null || proto === Object.prototype)
    return true;
  const Ctor = Object.hasOwnProperty.call(proto, "constructor") && proto.constructor;
  if (Ctor === Object)
    return true;
  if (typeof Ctor !== "function")
    return false;
  let ctorString = cachedCtorStrings.get(Ctor);
  if (ctorString === void 0) {
    ctorString = Function.toString.call(Ctor);
    cachedCtorStrings.set(Ctor, ctorString);
  }
  return ctorString === objectCtorString;
}
function each(obj, iter, strict = true) {
  if (getArchtype(obj) === 0 /* Object */) {
    const keys = strict ? Reflect.ownKeys(obj) : Object.keys(obj);
    keys.forEach((key) => {
      iter(key, obj[key], obj);
    });
  } else {
    obj.forEach((entry, index) => iter(index, entry, obj));
  }
}
function getArchtype(thing) {
  const state = thing[DRAFT_STATE];
  return state ? state.type_ : Array.isArray(thing) ? 1 /* Array */ : isMap(thing) ? 2 /* Map */ : isSet(thing) ? 3 /* Set */ : 0 /* Object */;
}
function has(thing, prop) {
  return getArchtype(thing) === 2 /* Map */ ? thing.has(prop) : Object.prototype.hasOwnProperty.call(thing, prop);
}
function get(thing, prop) {
  return getArchtype(thing) === 2 /* Map */ ? thing.get(prop) : thing[prop];
}
function set(thing, propOrOldValue, value) {
  const t = getArchtype(thing);
  if (t === 2 /* Map */)
    thing.set(propOrOldValue, value);
  else if (t === 3 /* Set */) {
    thing.add(value);
  } else
    thing[propOrOldValue] = value;
}
function is(x, y) {
  if (x === y) {
    return x !== 0 || 1 / x === 1 / y;
  } else {
    return x !== x && y !== y;
  }
}
function isMap(target) {
  return target instanceof Map;
}
function isSet(target) {
  return target instanceof Set;
}
function latest(state) {
  return state.copy_ || state.base_;
}
function shallowCopy(base, strict) {
  if (isMap(base)) {
    return new Map(base);
  }
  if (isSet(base)) {
    return new Set(base);
  }
  if (Array.isArray(base))
    return Array.prototype.slice.call(base);
  const isPlain = isPlainObject(base);
  if (strict === true || strict === "class_only" && !isPlain) {
    const descriptors = Object.getOwnPropertyDescriptors(base);
    delete descriptors[DRAFT_STATE];
    let keys = Reflect.ownKeys(descriptors);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const desc = descriptors[key];
      if (desc.writable === false) {
        desc.writable = true;
        desc.configurable = true;
      }
      if (desc.get || desc.set)
        descriptors[key] = {
          configurable: true,
          writable: true,
          // could live with !!desc.set as well here...
          enumerable: desc.enumerable,
          value: base[key]
        };
    }
    return Object.create(getPrototypeOf(base), descriptors);
  } else {
    const proto = getPrototypeOf(base);
    if (proto !== null && isPlain) {
      return { ...base };
    }
    const obj = Object.create(proto);
    return Object.assign(obj, base);
  }
}
function freeze(obj, deep = false) {
  if (isFrozen(obj) || isDraft(obj) || !isDraftable(obj))
    return obj;
  if (getArchtype(obj) > 1) {
    Object.defineProperties(obj, {
      set: dontMutateMethodOverride,
      add: dontMutateMethodOverride,
      clear: dontMutateMethodOverride,
      delete: dontMutateMethodOverride
    });
  }
  Object.freeze(obj);
  if (deep)
    Object.values(obj).forEach((value) => freeze(value, true));
  return obj;
}
function dontMutateFrozenCollections() {
  die(2);
}
var dontMutateMethodOverride = {
  value: dontMutateFrozenCollections
};
function isFrozen(obj) {
  if (obj === null || typeof obj !== "object")
    return true;
  return Object.isFrozen(obj);
}

// src/utils/plugins.ts
var plugins = {};
function getPlugin(pluginKey) {
  const plugin = plugins[pluginKey];
  if (!plugin) {
    die(0, pluginKey);
  }
  return plugin;
}
function loadPlugin(pluginKey, implementation) {
  if (!plugins[pluginKey])
    plugins[pluginKey] = implementation;
}

// src/core/scope.ts
var currentScope;
function getCurrentScope() {
  return currentScope;
}
function createScope(parent_, immer_) {
  return {
    drafts_: [],
    parent_,
    immer_,
    // Whenever the modified draft contains a draft from another scope, we
    // need to prevent auto-freezing so the unowned draft can be finalized.
    canAutoFreeze_: true,
    unfinalizedDrafts_: 0
  };
}
function usePatchesInScope(scope, patchListener) {
  if (patchListener) {
    getPlugin("Patches");
    scope.patches_ = [];
    scope.inversePatches_ = [];
    scope.patchListener_ = patchListener;
  }
}
function revokeScope(scope) {
  leaveScope(scope);
  scope.drafts_.forEach(revokeDraft);
  scope.drafts_ = null;
}
function leaveScope(scope) {
  if (scope === currentScope) {
    currentScope = scope.parent_;
  }
}
function enterScope(immer2) {
  return currentScope = createScope(currentScope, immer2);
}
function revokeDraft(draft) {
  const state = draft[DRAFT_STATE];
  if (state.type_ === 0 /* Object */ || state.type_ === 1 /* Array */)
    state.revoke_();
  else
    state.revoked_ = true;
}

// src/core/finalize.ts
function processResult(result, scope) {
  scope.unfinalizedDrafts_ = scope.drafts_.length;
  const baseDraft = scope.drafts_[0];
  const isReplaced = result !== void 0 && result !== baseDraft;
  if (isReplaced) {
    if (baseDraft[DRAFT_STATE].modified_) {
      revokeScope(scope);
      die(4);
    }
    if (isDraftable(result)) {
      result = finalize(scope, result);
      if (!scope.parent_)
        maybeFreeze(scope, result);
    }
    if (scope.patches_) {
      getPlugin("Patches").generateReplacementPatches_(
        baseDraft[DRAFT_STATE].base_,
        result,
        scope.patches_,
        scope.inversePatches_
      );
    }
  } else {
    result = finalize(scope, baseDraft, []);
  }
  revokeScope(scope);
  if (scope.patches_) {
    scope.patchListener_(scope.patches_, scope.inversePatches_);
  }
  return result !== NOTHING ? result : void 0;
}
function finalize(rootScope, value, path) {
  if (isFrozen(value))
    return value;
  const useStrictIteration = rootScope.immer_.shouldUseStrictIteration();
  const state = value[DRAFT_STATE];
  if (!state) {
    each(
      value,
      (key, childValue) => finalizeProperty(rootScope, state, value, key, childValue, path),
      useStrictIteration
    );
    return value;
  }
  if (state.scope_ !== rootScope)
    return value;
  if (!state.modified_) {
    maybeFreeze(rootScope, state.base_, true);
    return state.base_;
  }
  if (!state.finalized_) {
    state.finalized_ = true;
    state.scope_.unfinalizedDrafts_--;
    const result = state.copy_;
    let resultEach = result;
    let isSet2 = false;
    if (state.type_ === 3 /* Set */) {
      resultEach = new Set(result);
      result.clear();
      isSet2 = true;
    }
    each(
      resultEach,
      (key, childValue) => finalizeProperty(
        rootScope,
        state,
        result,
        key,
        childValue,
        path,
        isSet2
      ),
      useStrictIteration
    );
    maybeFreeze(rootScope, result, false);
    if (path && rootScope.patches_) {
      getPlugin("Patches").generatePatches_(
        state,
        path,
        rootScope.patches_,
        rootScope.inversePatches_
      );
    }
  }
  return state.copy_;
}
function finalizeProperty(rootScope, parentState, targetObject, prop, childValue, rootPath, targetIsSet) {
  if (childValue == null) {
    return;
  }
  if (typeof childValue !== "object" && !targetIsSet) {
    return;
  }
  const childIsFrozen = isFrozen(childValue);
  if (childIsFrozen && !targetIsSet) {
    return;
  }
  if (process.env.NODE_ENV !== "production" && childValue === targetObject)
    die(5);
  if (isDraft(childValue)) {
    const path = rootPath && parentState && parentState.type_ !== 3 /* Set */ && // Set objects are atomic since they have no keys.
    !has(parentState.assigned_, prop) ? rootPath.concat(prop) : void 0;
    const res = finalize(rootScope, childValue, path);
    set(targetObject, prop, res);
    if (isDraft(res)) {
      rootScope.canAutoFreeze_ = false;
    } else
      return;
  } else if (targetIsSet) {
    targetObject.add(childValue);
  }
  if (isDraftable(childValue) && !childIsFrozen) {
    if (!rootScope.immer_.autoFreeze_ && rootScope.unfinalizedDrafts_ < 1) {
      return;
    }
    if (parentState && parentState.base_ && parentState.base_[prop] === childValue && childIsFrozen) {
      return;
    }
    finalize(rootScope, childValue);
    if ((!parentState || !parentState.scope_.parent_) && typeof prop !== "symbol" && (isMap(targetObject) ? targetObject.has(prop) : Object.prototype.propertyIsEnumerable.call(targetObject, prop)))
      maybeFreeze(rootScope, childValue);
  }
}
function maybeFreeze(scope, value, deep = false) {
  if (!scope.parent_ && scope.immer_.autoFreeze_ && scope.canAutoFreeze_) {
    freeze(value, deep);
  }
}

// src/core/proxy.ts
function createProxyProxy(base, parent) {
  const isArray = Array.isArray(base);
  const state = {
    type_: isArray ? 1 /* Array */ : 0 /* Object */,
    // Track which produce call this is associated with.
    scope_: parent ? parent.scope_ : getCurrentScope(),
    // True for both shallow and deep changes.
    modified_: false,
    // Used during finalization.
    finalized_: false,
    // Track which properties have been assigned (true) or deleted (false).
    assigned_: {},
    // The parent draft state.
    parent_: parent,
    // The base state.
    base_: base,
    // The base proxy.
    draft_: null,
    // set below
    // The base copy with any updated values.
    copy_: null,
    // Called by the `produce` function.
    revoke_: null,
    isManual_: false
  };
  let target = state;
  let traps = objectTraps;
  if (isArray) {
    target = [state];
    traps = arrayTraps;
  }
  const { revoke, proxy } = Proxy.revocable(target, traps);
  state.draft_ = proxy;
  state.revoke_ = revoke;
  return proxy;
}
var objectTraps = {
  get(state, prop) {
    if (prop === DRAFT_STATE)
      return state;
    const source = latest(state);
    if (!has(source, prop)) {
      return readPropFromProto(state, source, prop);
    }
    const value = source[prop];
    if (state.finalized_ || !isDraftable(value)) {
      return value;
    }
    if (value === peek(state.base_, prop)) {
      prepareCopy(state);
      return state.copy_[prop] = createProxy(value, state);
    }
    return value;
  },
  has(state, prop) {
    return prop in latest(state);
  },
  ownKeys(state) {
    return Reflect.ownKeys(latest(state));
  },
  set(state, prop, value) {
    const desc = getDescriptorFromProto(latest(state), prop);
    if (desc?.set) {
      desc.set.call(state.draft_, value);
      return true;
    }
    if (!state.modified_) {
      const current2 = peek(latest(state), prop);
      const currentState = current2?.[DRAFT_STATE];
      if (currentState && currentState.base_ === value) {
        state.copy_[prop] = value;
        state.assigned_[prop] = false;
        return true;
      }
      if (is(value, current2) && (value !== void 0 || has(state.base_, prop)))
        return true;
      prepareCopy(state);
      markChanged(state);
    }
    if (state.copy_[prop] === value && // special case: handle new props with value 'undefined'
    (value !== void 0 || prop in state.copy_) || // special case: NaN
    Number.isNaN(value) && Number.isNaN(state.copy_[prop]))
      return true;
    state.copy_[prop] = value;
    state.assigned_[prop] = true;
    return true;
  },
  deleteProperty(state, prop) {
    if (peek(state.base_, prop) !== void 0 || prop in state.base_) {
      state.assigned_[prop] = false;
      prepareCopy(state);
      markChanged(state);
    } else {
      delete state.assigned_[prop];
    }
    if (state.copy_) {
      delete state.copy_[prop];
    }
    return true;
  },
  // Note: We never coerce `desc.value` into an Immer draft, because we can't make
  // the same guarantee in ES5 mode.
  getOwnPropertyDescriptor(state, prop) {
    const owner = latest(state);
    const desc = Reflect.getOwnPropertyDescriptor(owner, prop);
    if (!desc)
      return desc;
    return {
      writable: true,
      configurable: state.type_ !== 1 /* Array */ || prop !== "length",
      enumerable: desc.enumerable,
      value: owner[prop]
    };
  },
  defineProperty() {
    die(11);
  },
  getPrototypeOf(state) {
    return getPrototypeOf(state.base_);
  },
  setPrototypeOf() {
    die(12);
  }
};
var arrayTraps = {};
each(objectTraps, (key, fn) => {
  arrayTraps[key] = function() {
    arguments[0] = arguments[0][0];
    return fn.apply(this, arguments);
  };
});
arrayTraps.deleteProperty = function(state, prop) {
  if (process.env.NODE_ENV !== "production" && isNaN(parseInt(prop)))
    die(13);
  return arrayTraps.set.call(this, state, prop, void 0);
};
arrayTraps.set = function(state, prop, value) {
  if (process.env.NODE_ENV !== "production" && prop !== "length" && isNaN(parseInt(prop)))
    die(14);
  return objectTraps.set.call(this, state[0], prop, value, state[0]);
};
function peek(draft, prop) {
  const state = draft[DRAFT_STATE];
  const source = state ? latest(state) : draft;
  return source[prop];
}
function readPropFromProto(state, source, prop) {
  const desc = getDescriptorFromProto(source, prop);
  return desc ? `value` in desc ? desc.value : (
    // This is a very special case, if the prop is a getter defined by the
    // prototype, we should invoke it with the draft as context!
    desc.get?.call(state.draft_)
  ) : void 0;
}
function getDescriptorFromProto(source, prop) {
  if (!(prop in source))
    return void 0;
  let proto = getPrototypeOf(source);
  while (proto) {
    const desc = Object.getOwnPropertyDescriptor(proto, prop);
    if (desc)
      return desc;
    proto = getPrototypeOf(proto);
  }
  return void 0;
}
function markChanged(state) {
  if (!state.modified_) {
    state.modified_ = true;
    if (state.parent_) {
      markChanged(state.parent_);
    }
  }
}
function prepareCopy(state) {
  if (!state.copy_) {
    state.copy_ = shallowCopy(
      state.base_,
      state.scope_.immer_.useStrictShallowCopy_
    );
  }
}

// src/core/immerClass.ts
var Immer2 = class {
  constructor(config) {
    this.autoFreeze_ = true;
    this.useStrictShallowCopy_ = false;
    this.useStrictIteration_ = true;
    /**
     * The `produce` function takes a value and a "recipe function" (whose
     * return value often depends on the base state). The recipe function is
     * free to mutate its first argument however it wants. All mutations are
     * only ever applied to a __copy__ of the base state.
     *
     * Pass only a function to create a "curried producer" which relieves you
     * from passing the recipe function every time.
     *
     * Only plain objects and arrays are made mutable. All other objects are
     * considered uncopyable.
     *
     * Note: This function is __bound__ to its `Immer` instance.
     *
     * @param {any} base - the initial state
     * @param {Function} recipe - function that receives a proxy of the base state as first argument and which can be freely modified
     * @param {Function} patchListener - optional function that will be called with all the patches produced here
     * @returns {any} a new state, or the initial state if nothing was modified
     */
    this.produce = (base, recipe, patchListener) => {
      if (typeof base === "function" && typeof recipe !== "function") {
        const defaultBase = recipe;
        recipe = base;
        const self = this;
        return function curriedProduce(base2 = defaultBase, ...args) {
          return self.produce(base2, (draft) => recipe.call(this, draft, ...args));
        };
      }
      if (typeof recipe !== "function")
        die(6);
      if (patchListener !== void 0 && typeof patchListener !== "function")
        die(7);
      let result;
      if (isDraftable(base)) {
        const scope = enterScope(this);
        const proxy = createProxy(base, void 0);
        let hasError = true;
        try {
          result = recipe(proxy);
          hasError = false;
        } finally {
          if (hasError)
            revokeScope(scope);
          else
            leaveScope(scope);
        }
        usePatchesInScope(scope, patchListener);
        return processResult(result, scope);
      } else if (!base || typeof base !== "object") {
        result = recipe(base);
        if (result === void 0)
          result = base;
        if (result === NOTHING)
          result = void 0;
        if (this.autoFreeze_)
          freeze(result, true);
        if (patchListener) {
          const p = [];
          const ip = [];
          getPlugin("Patches").generateReplacementPatches_(base, result, p, ip);
          patchListener(p, ip);
        }
        return result;
      } else
        die(1, base);
    };
    this.produceWithPatches = (base, recipe) => {
      if (typeof base === "function") {
        return (state, ...args) => this.produceWithPatches(state, (draft) => base(draft, ...args));
      }
      let patches, inversePatches;
      const result = this.produce(base, recipe, (p, ip) => {
        patches = p;
        inversePatches = ip;
      });
      return [result, patches, inversePatches];
    };
    if (typeof config?.autoFreeze === "boolean")
      this.setAutoFreeze(config.autoFreeze);
    if (typeof config?.useStrictShallowCopy === "boolean")
      this.setUseStrictShallowCopy(config.useStrictShallowCopy);
    if (typeof config?.useStrictIteration === "boolean")
      this.setUseStrictIteration(config.useStrictIteration);
  }
  createDraft(base) {
    if (!isDraftable(base))
      die(8);
    if (isDraft(base))
      base = current(base);
    const scope = enterScope(this);
    const proxy = createProxy(base, void 0);
    proxy[DRAFT_STATE].isManual_ = true;
    leaveScope(scope);
    return proxy;
  }
  finishDraft(draft, patchListener) {
    const state = draft && draft[DRAFT_STATE];
    if (!state || !state.isManual_)
      die(9);
    const { scope_: scope } = state;
    usePatchesInScope(scope, patchListener);
    return processResult(void 0, scope);
  }
  /**
   * Pass true to automatically freeze all copies created by Immer.
   *
   * By default, auto-freezing is enabled.
   */
  setAutoFreeze(value) {
    this.autoFreeze_ = value;
  }
  /**
   * Pass true to enable strict shallow copy.
   *
   * By default, immer does not copy the object descriptors such as getter, setter and non-enumrable properties.
   */
  setUseStrictShallowCopy(value) {
    this.useStrictShallowCopy_ = value;
  }
  /**
   * Pass false to use faster iteration that skips non-enumerable properties
   * but still handles symbols for compatibility.
   *
   * By default, strict iteration is enabled (includes all own properties).
   */
  setUseStrictIteration(value) {
    this.useStrictIteration_ = value;
  }
  shouldUseStrictIteration() {
    return this.useStrictIteration_;
  }
  applyPatches(base, patches) {
    let i;
    for (i = patches.length - 1; i >= 0; i--) {
      const patch = patches[i];
      if (patch.path.length === 0 && patch.op === "replace") {
        base = patch.value;
        break;
      }
    }
    if (i > -1) {
      patches = patches.slice(i + 1);
    }
    const applyPatchesImpl = getPlugin("Patches").applyPatches_;
    if (isDraft(base)) {
      return applyPatchesImpl(base, patches);
    }
    return this.produce(
      base,
      (draft) => applyPatchesImpl(draft, patches)
    );
  }
};
function createProxy(value, parent) {
  const draft = isMap(value) ? getPlugin("MapSet").proxyMap_(value, parent) : isSet(value) ? getPlugin("MapSet").proxySet_(value, parent) : createProxyProxy(value, parent);
  const scope = parent ? parent.scope_ : getCurrentScope();
  scope.drafts_.push(draft);
  return draft;
}

// src/core/current.ts
function current(value) {
  if (!isDraft(value))
    die(10, value);
  return currentImpl(value);
}
function currentImpl(value) {
  if (!isDraftable(value) || isFrozen(value))
    return value;
  const state = value[DRAFT_STATE];
  let copy;
  let strict = true;
  if (state) {
    if (!state.modified_)
      return state.base_;
    state.finalized_ = true;
    copy = shallowCopy(value, state.scope_.immer_.useStrictShallowCopy_);
    strict = state.scope_.immer_.shouldUseStrictIteration();
  } else {
    copy = shallowCopy(value, true);
  }
  each(
    copy,
    (key, childValue) => {
      set(copy, key, currentImpl(childValue));
    },
    strict
  );
  if (state) {
    state.finalized_ = false;
  }
  return copy;
}

// src/plugins/patches.ts
function enablePatches() {
  const errorOffset = 16;
  if (process.env.NODE_ENV !== "production") {
    errors.push(
      'Sets cannot have "replace" patches.',
      function(op) {
        return "Unsupported patch operation: " + op;
      },
      function(path) {
        return "Cannot apply patch, path doesn't resolve: " + path;
      },
      "Patching reserved attributes like __proto__, prototype and constructor is not allowed"
    );
  }
  const REPLACE = "replace";
  const ADD = "add";
  const REMOVE = "remove";
  function generatePatches_(state, basePath, patches, inversePatches) {
    switch (state.type_) {
      case 0 /* Object */:
      case 2 /* Map */:
        return generatePatchesFromAssigned(
          state,
          basePath,
          patches,
          inversePatches
        );
      case 1 /* Array */:
        return generateArrayPatches(state, basePath, patches, inversePatches);
      case 3 /* Set */:
        return generateSetPatches(
          state,
          basePath,
          patches,
          inversePatches
        );
    }
  }
  function generateArrayPatches(state, basePath, patches, inversePatches) {
    let { base_, assigned_ } = state;
    let copy_ = state.copy_;
    if (copy_.length < base_.length) {
      [base_, copy_] = [copy_, base_];
      [patches, inversePatches] = [inversePatches, patches];
    }
    for (let i = 0; i < base_.length; i++) {
      if (assigned_[i] && copy_[i] !== base_[i]) {
        const path = basePath.concat([i]);
        patches.push({
          op: REPLACE,
          path,
          // Need to maybe clone it, as it can in fact be the original value
          // due to the base/copy inversion at the start of this function
          value: clonePatchValueIfNeeded(copy_[i])
        });
        inversePatches.push({
          op: REPLACE,
          path,
          value: clonePatchValueIfNeeded(base_[i])
        });
      }
    }
    for (let i = base_.length; i < copy_.length; i++) {
      const path = basePath.concat([i]);
      patches.push({
        op: ADD,
        path,
        // Need to maybe clone it, as it can in fact be the original value
        // due to the base/copy inversion at the start of this function
        value: clonePatchValueIfNeeded(copy_[i])
      });
    }
    for (let i = copy_.length - 1; base_.length <= i; --i) {
      const path = basePath.concat([i]);
      inversePatches.push({
        op: REMOVE,
        path
      });
    }
  }
  function generatePatchesFromAssigned(state, basePath, patches, inversePatches) {
    const { base_, copy_ } = state;
    each(state.assigned_, (key, assignedValue) => {
      const origValue = get(base_, key);
      const value = get(copy_, key);
      const op = !assignedValue ? REMOVE : has(base_, key) ? REPLACE : ADD;
      if (origValue === value && op === REPLACE)
        return;
      const path = basePath.concat(key);
      patches.push(op === REMOVE ? { op, path } : { op, path, value });
      inversePatches.push(
        op === ADD ? { op: REMOVE, path } : op === REMOVE ? { op: ADD, path, value: clonePatchValueIfNeeded(origValue) } : { op: REPLACE, path, value: clonePatchValueIfNeeded(origValue) }
      );
    });
  }
  function generateSetPatches(state, basePath, patches, inversePatches) {
    let { base_, copy_ } = state;
    let i = 0;
    base_.forEach((value) => {
      if (!copy_.has(value)) {
        const path = basePath.concat([i]);
        patches.push({
          op: REMOVE,
          path,
          value
        });
        inversePatches.unshift({
          op: ADD,
          path,
          value
        });
      }
      i++;
    });
    i = 0;
    copy_.forEach((value) => {
      if (!base_.has(value)) {
        const path = basePath.concat([i]);
        patches.push({
          op: ADD,
          path,
          value
        });
        inversePatches.unshift({
          op: REMOVE,
          path,
          value
        });
      }
      i++;
    });
  }
  function generateReplacementPatches_(baseValue, replacement, patches, inversePatches) {
    patches.push({
      op: REPLACE,
      path: [],
      value: replacement === NOTHING ? void 0 : replacement
    });
    inversePatches.push({
      op: REPLACE,
      path: [],
      value: baseValue
    });
  }
  function applyPatches_(draft, patches) {
    patches.forEach((patch) => {
      const { path, op } = patch;
      let base = draft;
      for (let i = 0; i < path.length - 1; i++) {
        const parentType = getArchtype(base);
        let p = path[i];
        if (typeof p !== "string" && typeof p !== "number") {
          p = "" + p;
        }
        if ((parentType === 0 /* Object */ || parentType === 1 /* Array */) && (p === "__proto__" || p === "constructor"))
          die(errorOffset + 3);
        if (typeof base === "function" && p === "prototype")
          die(errorOffset + 3);
        base = get(base, p);
        if (typeof base !== "object")
          die(errorOffset + 2, path.join("/"));
      }
      const type = getArchtype(base);
      const value = deepClonePatchValue(patch.value);
      const key = path[path.length - 1];
      switch (op) {
        case REPLACE:
          switch (type) {
            case 2 /* Map */:
              return base.set(key, value);
            case 3 /* Set */:
              die(errorOffset);
            default:
              return base[key] = value;
          }
        case ADD:
          switch (type) {
            case 1 /* Array */:
              return key === "-" ? base.push(value) : base.splice(key, 0, value);
            case 2 /* Map */:
              return base.set(key, value);
            case 3 /* Set */:
              return base.add(value);
            default:
              return base[key] = value;
          }
        case REMOVE:
          switch (type) {
            case 1 /* Array */:
              return base.splice(key, 1);
            case 2 /* Map */:
              return base.delete(key);
            case 3 /* Set */:
              return base.delete(patch.value);
            default:
              return delete base[key];
          }
        default:
          die(errorOffset + 1, op);
      }
    });
    return draft;
  }
  function deepClonePatchValue(obj) {
    if (!isDraftable(obj))
      return obj;
    if (Array.isArray(obj))
      return obj.map(deepClonePatchValue);
    if (isMap(obj))
      return new Map(
        Array.from(obj.entries()).map(([k, v]) => [k, deepClonePatchValue(v)])
      );
    if (isSet(obj))
      return new Set(Array.from(obj).map(deepClonePatchValue));
    const cloned = Object.create(getPrototypeOf(obj));
    for (const key in obj)
      cloned[key] = deepClonePatchValue(obj[key]);
    if (has(obj, DRAFTABLE))
      cloned[DRAFTABLE] = obj[DRAFTABLE];
    return cloned;
  }
  function clonePatchValueIfNeeded(obj) {
    if (isDraft(obj)) {
      return deepClonePatchValue(obj);
    } else
      return obj;
  }
  loadPlugin("Patches", {
    applyPatches_,
    generatePatches_,
    generateReplacementPatches_
  });
}

// src/immer.ts
var immer = new Immer2();
immer.produce;
var produceWithPatches = /* @__PURE__ */ immer.produceWithPatches.bind(
  immer
);
var setAutoFreeze = /* @__PURE__ */ immer.setAutoFreeze.bind(immer);
var applyPatches = /* @__PURE__ */ immer.applyPatches.bind(immer);

// @ts-nocheck

enablePatches();

// we have some Editor.setState functions that use immer, so Editor.this.state becomes an "immer immutable frozen object". But we also have some Editor.setState functions that don't use immer, and they try to _mutate_ Editor.this.state. This gives errors like https://github.com/immerjs/immer/issues/576

// The solution is to tell immer not to create immutable objects

setAutoFreeze(false);

const PROGRESS_LOG_LEVEL = "LogLevel(-1)";
const STDOUT_LOG_LEVEL = "LogLevel(-555)";
const terminalSet = new Set(["errored", "done"]);
const isTerminalStatus = (status) => {
    return terminalSet.has(status);
};
function getResult(worker, cell_id) {
    return worker.notebook_state.cell_results[cell_id];
}
function getSnippetLogs(worker, cell_id) {
    return worker.notebook_state.cell_results[cell_id]?.logs ?? [];
}
function getProgressLogs(worker, cell_id) {
    return (getSnippetLogs(worker, cell_id).filter((log) => {
        return (log.level ?? "").toString() === PROGRESS_LOG_LEVEL;
    }) ?? []);
}
function getTerminalLogs(worker, cell_id) {
    return (getSnippetLogs(worker, cell_id).filter((log) => {
        return (log.level ?? "").toString() === STDOUT_LOG_LEVEL;
    }) ?? []);
}
function getOutput(worker, cell_id) {
    return worker.notebook_state.cell_results[cell_id].output;
}
function getStatus(worker, cell_id) {
    const r = getResult(worker, cell_id);
    return r.queued ? "queued" : r.running ? "running" : r.errored ? "errored" : r.runtime > 0 ? "done" : "pending";
}
function getMime(worker, cell_id) {
    const result = getResult(worker, cell_id);
    return [result.output.mime, result.output.body];
}

/**
 * @fileoverview client.js - Programmatic Interface for Pluto Notebooks
 *
 * This module provides a JavaScript API for interacting with Pluto notebooks
 * without requiring the full Editor UI. It's designed for:
 *
 * - Automated notebook execution
 * - Testing and CI/CD pipelines
 * - Custom notebook interfaces
 * - Headless Pluto workflows
 *
 * The API maintains compatibility with Pluto's internal state structures
 * and uses the same WebSocket protocol as the Editor.js component.
 *
 * ## Basic Usage
 *
 * ```javascript
 * import { Host } from '@plutojl/rainbow';
 *
 * // Connect to Pluto server
 * const host = new Host("http://localhost:1234");
 *
 * // Create a new notebook
 * const worker = await host.createWorker("x = 1 + 1");
 *
 * // Add and run cells
 * const cellId = await worker.addSnippet(0, "println(x)");
 *
 * // Listen for updates
 * worker.onUpdate((event) => {
 *   console.log("Update:", event.type, event.data);
 * });
 * ```
 *
 * ## State Compatibility
 *
 * The notebook state structure matches Editor.js exactly:
 * - `notebook_state.cell_order` - Array of cell IDs in execution order
 * - `notebook_state.cell_inputs` - Map of cell IDs to input data
 * - `notebook_state.cell_results` - Map of cell IDs to execution results
 * - `notebook_state.status_tree` - Execution status hierarchy
 *
 * @author Pluto.jl Team
 * @version 1.0.0
 */


// vendored to drop unshakeable import
const empty_notebook_state = ({ notebook_id }) => ({
    metadata: {},
    notebook_id: notebook_id,
    path: "",
    shortpath: "",
    in_temp_dir: true,
    process_status: ProcessStatus.starting,
    last_save_time: 0.0,
    last_hot_reload_time: 0.0,
    cell_inputs: {},
    cell_results: {},
    cell_dependencies: {},
    cell_order: [],
    cell_execution_order: [],
    published_objects: {},
    bonds: {},
    nbpkg: null,
    status_tree: null,
});

/**
 * @typedef CellData
 * @type {{
 *  input: import("../components/Editor.js").CellInputData,
 *  result: import("../components/Editor.js").CellResultData,
 * }}
 */

// Be sure to keep this in sync with DEFAULT_CELL_METADATA in Cell.jl
const DEFAULT_CELL_METADATA$1 = {
    disabled: false,
    show_logs: true,
    skip_as_script: false,
};

// from our friends at https://stackoverflow.com/a/2117523
// i checked it and it generates Julia-legal UUIDs and that's all we need -SNOF
const uuidv4 = () =>
    "10000000-1000-4000-8000-100000000000".replace(/[018]/g, (c) => (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16));

/**
 * Host - Main class for connecting to a Pluto server and managing notebooks
 *
 * This class provides high-level operations for interacting with a Pluto server:
 * - Discovering running notebooks
 * - Creating new notebooks from text content
 * - Managing Worker instances
 *
 * @example
 * const host = new Host("http://localhost:1234");
 * const workers = await host.workers();
 * const worker = await host.createWorker(``);
 */
class Host {
    /**
     * Create a new Host instance
     * @param {string} [server_url="http://localhost:1234"] - Pluto server URL
     */
    constructor(server_url = "http://localhost:1234") {
        /** @type {string} */
        this.server_url = server_url;
        /** @type {string} */
        this.ws_address = ws_address_from_base(server_url);
        /** @type {Map<string, Worker>} */
        this._notebooks = new Map();
    }

    /**
     * Get list of currently running notebooks on the server
     * @returns {Promise<Array<Worker>>} Array of worker information objects
     * @throws {Error} If connection to server fails
     */
    async workers() {
        try {
            // Create a temporary connection to get server info
            const temp_client = await create_pluto_connection({
                ws_address: this.ws_address,
                on_unrequested_update: () => {},
                on_connection_status: () => {},
                on_reconnect: async () => true,
            });

            // Request server status to get running notebooks
            const response = await temp_client.send("get_all_notebooks", {}, {}, false);
            temp_client.kill();

            return response.message?.notebooks || []
        } catch (error) {
            console.error("Failed to get running notebooks:", error);
            return []
        }
    }

    /**
     * Get or create a Worker instance for the given notebook ID
     *
     * This method implements a cache pattern - multiple calls with the same
     * notebook_id will return the same Worker instance.
     *
     * @param {string} notebook_id - Notebook UUID
     * @returns {Worker} Worker instance (may be cached)
     */
    worker(notebook_id) {
        if (!this._notebooks.has(notebook_id)) {
            this._notebooks.set(notebook_id, new Worker$1(this.ws_address, notebook_id));
        }
        return this._notebooks.get(notebook_id)
    }

    /**
     * Create a new notebook from text content
     *
     * This method uploads notebook content to the server via /notebookupload,
     * creates a Worker instance, connects to it, and restarts it for
     * proper initialization.
     *
     * @param {string} notebook_text - Pluto notebook text content (.jl format)
     * @returns {Promise<Worker>} Connected and initialized Worker instance
     * @throws {Error} If upload fails, connection fails, or restart fails
     *
     * @example
     * const worker = await host.createWorker(`
     *   ### A Pluto.jl notebook ###
     *   # v0.19.40
     *
     *   x = 1 + 1
     * `);
     */
    async createWorker(notebook_text) {
        try {
            // Upload notebook text to server using /notebookupload endpoint
            const response = await fetch(`${this.server_url}/notebookupload`, {
                method: "POST",
                body: notebook_text.trim(),
            });

            if (!response.ok) {
                throw new Error(`Failed to upload notebook: ${response.status} ${response.statusText}`)
            }

            // Get the notebook ID from the response
            const notebook_id = await response.text();

            // Create and connect to the new notebook
            const notebook = this.worker(notebook_id);
            if (!notebook) {
                throw new Error(`Notebook ${notebook_id} could not be created properly`)
            }
            const connected = await notebook.connect();

            if (!connected) {
                throw new Error("Failed to connect to newly created notebook")
            }

            // Restart the notebook to ensure proper initialization
            await notebook.restart();

            return notebook
        } catch (error) {
            console.error("Failed to create notebook:", error);
            throw error
        }
    }
}

/**
 * Worker - A programmatic interface to interact with a specific Pluto notebook
 * without the full Editor UI component.
 *
 * This class provides the core functionality of the Editor.js component:
 * 1. Connection management to Pluto backend via WebSocket
 * 2. Notebook state management (mirroring Editor.js state structure)
 * 3. Cell code updates and execution
 * 4. Real-time state synchronization
 *
 * The state management is designed to be compatible with Editor.js:
 * - Uses the same notebook state structure
 * - Handles patches the same way
 * - Maintains the same cell lifecycle
 *
 * @example
 * const worker = host.worker("notebook-uuid");
 * await worker.connect();
 *
 * // Add and run a cell
 * const cellId = await worker.addSnippet(0, "x = 1 + 1");
 *
 * // Update cell code
 * await worker.updateSnippetCode(cellId, "x = 2 + 2");
 *
 * // Listen for updates
 * const unsubscribe = worker.onUpdate((event) => {
 *   console.log("Notebook updated:", event);
 * });
 */
let Worker$1 = class Worker {
    /**
     * Create a new Worker instance
     *
     * Note: This constructor only creates the instance. You must call connect()
     * to establish the WebSocket connection and initialize the notebook state.
     *
     * @param {string} ws_address - WebSocket address to connect to
     * @param {string} notebook_id - Specific notebook ID to connect to
     */
    constructor(ws_address, notebook_id) {
        /** @type {string} */
        this.ws_address = ws_address;
        /** @type {string} */
        this.notebook_id = notebook_id;
        /** @type {boolean} */
        this.connected = false;
        /** @type {boolean} */
        this.initializing = true;
        /** @type {*} */
        this.notebook_status = null;

        /** @type {Record<string, import("../components/Editor.js").CellInputData>} */
        this.cell_inputs_local = {};

        /** @type {import("../components/Editor.js").NotebookData*/
        this.notebook_state = empty_notebook_state({
            notebook_id: this.notebook_id,
        });

        /** @type {number} */
        this.last_update_time = 0;
        /** @type {number} */
        this.pending_local_updates = 0;
        /** @type {number} */
        this.last_update_counter = -1;
        /** @type {import("../common/PlutoConnection.js").PlutoConnection | null} */
        this.client = null;

        /** @type {Set<Function>} */
        this._update_handlers = new Set();
        /** @type {Set<Function>} */
        this._connection_status_handlers = new Set();
        /** @type {Promise<void>} */
        this._update_queue_promise = Promise.resolve();

        /** @type {Promise<void>} */
        this.notebook_ready_promise = Promise.resolve();

        // Initialize notebook state
        this.cell_inputs_local = {};
        this.last_update_time = 0;
    }

    async wait(ready = true) {
        // Sleep for 35ms
        await new Promise((r) => setTimeout(r, 35));
        if (this.isIdle() === ready) {
            return
        }

        return new Promise((resolve, reject) => {
            const cleanup = this.onUpdate(() => {
                if (this.isIdle() === ready) {
                    cleanup();
                    resolve();
                }
            });
        })
    }

    /**
     * Connect to the Pluto backend WebSocket for this notebook
     *
     * This method establishes the WebSocket connection, initializes the notebook
     * state, and syncs with the server. Must be called before other operations.
     *
     * @returns {Promise<boolean>} True if connection and initialization successful
     * @throws {Error} If connection fails or notebook doesn't exist
     */
    async connect() {
        if (this.connected) {
            return true
        }

        try {
            this.client = await create_pluto_connection({
                ws_address: this.ws_address,
                on_unrequested_update: this._handle_update.bind(this),
                on_connection_status: this._handle_connection_status.bind(this),
                on_reconnect: this._handle_reconnect.bind(this),
                connect_metadata: { notebook_id: this.notebook_id },
            });

            // Initialize notebook state
            if (this.client.notebook_exists) {
                this.notebook_state = empty_notebook_state({
                    notebook_id: this.notebook_id,
                });

                // Ensure required structures exist for patches
                if (!this.notebook_state.cell_results) {
                    this.notebook_state.cell_results = {};
                }
                if (!this.notebook_state.status_tree) {
                    this.notebook_state.status_tree = {
                        subtasks: {},
                        finished_at: 0,
                        name: "noop",
                        started_at: Date.now(),
                        success: true,
                        timing: "local",
                    };
                }
            }

            if (!this.client.notebook_exists) {
                console.error("Notebook does not exist. Not connecting.");
                return false
            }

            // Send initial update_notebook request to sync state
            console.debug("Sending update_notebook request...");
            const response = await this.client.send("update_notebook", { updates: [] }, { notebook_id: this.notebook_id }, false);
            console.debug({ response });
            console.debug("Received update_notebook request");

            this.initializing = false;

            return true
        } catch (error) {
            console.error("Failed to connect to Pluto backend:", error);
            return false
        }
    }

    /**
     * Close the connection to this notebook
     */
    close() {
        if (this.client && this.client.kill) {
            this.client.kill();
        }
        this.connected = false;
        this.client = null;
        this.notebook_state = empty_notebook_state();
        this._update_handlers.clear();
        this._connection_status_handlers.clear();
    }

    /**
     * Shutdown the running notebook on the server
     *
     * This terminates the notebook process and removes it from the server.
     * After shutdown, the notebook instance becomes unusable and should be discarded.
     *
     * @returns {Promise<boolean>} True if shutdown successful
     * @throws {Error} If not connected to notebook
     */
    async shutdown() {
        if (!this.client) {
            throw new Error("Not connected to notebook")
        }

        try {
            // Send shutdown command to the server
            await this.client.send("shutdown_notebook", { keep_in_session: false }, { notebook_id: this.notebook_id }, false);

            // Close the local connection
            this.close();

            return true
        } catch (error) {
            console.error("Failed to shutdown notebook:", error);
            return false
        }
    }

    /**
     * Restart the notebook process
     *
     * This clears risky file metadata and sends a restart_process command to the server.
     * All cell execution state is reset, but cell code is preserved.
     *
     * @param {boolean} [maybe_confirm=false] - Whether to require confirmation for risky files (unused in API context)
     * @returns {Promise<void>}
     * @throws {Error} If not connected to notebook or restart fails
     */
    async restart(maybe_confirm = false) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        try {
            // Clear risky file metadata if present
            await this._update_notebook_state((nb) => {
                if (nb.metadata?.risky_file_source) {
                    delete nb.metadata.risky_file_source;
                }
            });

            // Send restart command to server
            // Awaiting this is futile, I think (@pankgeorg, 2/8/2025)
            this.client.send(
                "restart_process",
                {},
                {
                    notebook_id: this.notebook_id,
                }
            );

            this._notify_update("notebook_restarted", {
                notebook_id: this.notebook_id,
            });
        } catch (error) {
            console.error("Failed to restart notebook:", error);
            throw error
        }
    }

    /**
     * Execute a function within the Julia context
     *
     * @param {string} symbol - Function symbol to execute
     * @param {Array<any>} [arguments=[]] - Arguments to pass to the function
     * @returns {Promise<[boolean, any]>} Function result
     * @throws {Error} Not implemented
     */
    async execute(input) {
        const cell_id = "00000000-0000-0208-1991-000000000000";
        try {
            if (!this.notebook_state.cell_results[cell_id]) {
                console.log();
                await this.waitSnippet(
                    this.notebook_state.cell_execution_order.length - 2,
                    `begin
    using AbstractPlutoDingetjes
	function eval_in_pluto(x::String)
		id = PlutoRunner.moduleworkspace_count[]
		new_workspace_name = Symbol("workspace#", id)
		Core.eval(getproperty(Main, new_workspace_name), Meta.parse(x))
	end
	AbstractPlutoDingetjes.Display.with_js_link(eval_in_pluto)
end`,
                    { ...DEFAULT_CELL_METADATA$1, code_folded: true },
                    "00000000-0000-0208-1991-000000000000"
                );
            }
            const link_id = this.notebook_state.cell_results[cell_id].output.body.split('", "')[1].substr(0, 16);
            return this.client
                .send(
                    "request_js_link_response",
                    {
                        cell_id,
                        link_id,
                        input,
                    },
                    { notebook_id: this.notebook_id }
                )
                .then((r) => r.message)
        } catch (ex) {
            console.error(ex);
            throw ex
        }
    }

    getBonds() {
        return this.notebook_state.bonds
    }

    /**
     *
     * @param {string} name name of bound variable
     * @param {*} value value (not in wrapper object)
     */
    async setBond(name, value) {
        await this._update_notebook_state((notebook) => {
            let new_bond = { value };
            notebook.bonds[name] = new_bond;
        });
    }

    /**
     *
     * @param {string} symbol: the symbol to query for
     */
    async getDocs(symbol) {
        const { message } = await this.client.send("docs", { query: symbol.replace(/^\?/, "") }, { notebook_id: this.notebook_id });
        if (message.status === "👍") {
            return message.doc
        }
        if (message.status === "⌛") {
            return
        }
    }

    /**
     * Get the current notebook state (equivalent to Editor.js this.state.notebook)
     *
     * Returns the complete notebook state structure including cell_inputs,
     * cell_results, cell_order, and metadata. This matches the structure
     * used by Editor.js.
     *
     * @returns {NotebookData|null} Current notebook state, or null if not connected
     */
    getState() {
        return this.notebook_state
    }

    /**
     * Get specific cell data
     *
     * @param {string} cell_id - Cell UUID
     * @returns {CellData|null} Cell data object with input, result, and local state
     */
    getSnippet(cell_id) {
        if (!this.notebook_state) return null

        return {
            input: this.notebook_state.cell_inputs?.[cell_id],
            result: this.notebook_state.cell_results?.[cell_id],
        }
    }

    /**
     * Get all cells in order
     *
     * Returns cells in the order specified by cell_order, with complete
     * input and result data for each cell.
     *
     * @returns {Array<{cell_id: string} & CellData>} Array of cell data objects in execution order
     */
    getSnippets() {
        if (!this.notebook_state || !this.notebook_state.cell_order) return []

        return this.notebook_state.cell_order.map((cell_id) => ({
            cell_id,
            ...this.getSnippet(cell_id),
        }))
    }

    /**
     * Update cell code and optionally run it
     *
     * This updates the cell's code and optionally triggers execution.
     * The change is first stored locally, then sent to the server.
     *
     * @param {string} cell_id - Cell UUID
     * @param {string} code - New cell code
     * @param {boolean} [run=true] - Whether to run the cell after updating
     * @param {Object} [metadata={}] - Additional cell metadata
     * @returns {Promise<Object|undefined>} Response from backend if run=true
     * @throws {Error} If not connected to notebook
     */
    async updateSnippetCode(cell_id, code, run = true, metadata = {}) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        // Update local state
        this.cell_inputs_local[cell_id] = {
            ...this.cell_inputs_local[cell_id],
            code,
            metadata: { ...this.cell_inputs_local[cell_id]?.metadata, ...metadata },
        };
        this._notify_update("cell_local_update", { cell_id, code });

        if (run) {
            return await this.setSnippetsAndRun([cell_id], { cell_id: metadata })
        }
    }

    /**
     * Submit local cell changes to backend and run cells
     * @param {Array<string>} cell_ids - Array of cell UUIDs to update and run
     * @param {Record<string, Object>} metadata_record - Metadata for each cell
     * @returns {Promise<Object>} - Response from backend
     */
    async setSnippetsAndRun(cell_ids, metadata_record) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        if (cell_ids.length === 0) {
            return { disabled_cells: {} }
        }

        const new_task = this._update_queue_promise.then(async () => {
            // Create patches for the cell code changes
            const [new_notebook, changes] = produceWithPatches(this.notebook_state, (notebook) => {
                for (let cell_id of cell_ids) {
                    if (this.cell_inputs_local[cell_id]) {
                        notebook.cell_inputs[cell_id] = {
                            ...notebook.cell_inputs[cell_id],
                            code: this.cell_inputs_local[cell_id].code,
                            metadata: {
                                ...notebook.cell_inputs[cell_id].metadata,
                                ...metadata_record[cell_id],
                            },
                        };
                    }
                }
            });

            if (changes.length === 0) {
                return { disabled_cells: {} }
            }

            this.pending_local_updates++;

            try {
                // Send the update to the backend
                const response = await this.client.send("update_notebook", { updates: changes }, { notebook_id: this.notebook_id }, false);

                if (response.message?.response?.update_went_well === "👎") {
                    throw new Error(`Pluto update_notebook error: (from Julia: ${response.message.response.why_not})`)
                }

                // Update local state
                this.notebook_state = new_notebook;
                this.last_update_time = Date.now();

                // Clear local changes for updated cells
                for (let cell_id of cell_ids) {
                    delete this.cell_inputs_local[cell_id];
                }

                // Run the cells
                const run_response = await this.client.send("run_multiple_cells", { cells: cell_ids }, { notebook_id: this.notebook_id });

                this._notify_update("cells_updated", {
                    cell_ids,
                    response: run_response,
                });

                return run_response.message
            } finally {
                this.pending_local_updates--;
            }
        });

        this._update_queue_promise = new_task.catch(console.error);
        return await new_task
    }

    /**
     * Add a new cell to the notebook and wait for its result.
     *
     * Creates a new cell with a generated UUID, inserts it at the specified
     * position, and immediately runs it. The cell is added to both cell_inputs
     * and cell_results with appropriate initial state. Waits
     *
     * @param {number} [index=0] - Position to insert the cell (0-based)
     * @param {string} [code=""] - Initial cell code
     * @param {Object} [metadata={}] - Additional cell metadata
     * @param {string} [cell_id=uuidv4()] - Snippet's UUID, if you need to specifically set one     * @param {number} [timeout=-1] - Timeout to reject the results. defaults to -1 which disables the timeout
     * @returns {Promise<import("../components/Editor.js").CellResultData>} The output of the added cell
     * @throws {Error} If not connected to notebook
     *
     * @example
     * const cellOutput = await worker.waitSnippet(0, "println(\"Hello World\")");
     */

    async waitSnippet(index = 0, code = "", metadata = {}, cell_id = uuidv4(), timeout = -1) {
        await this.addSnippet(index, code, metadata, cell_id);
        return await new Promise((resolve, reject) => {
            let t = 0;
            const cleanup = this.onUpdate((v) => {
                if (v.type === "notebook_updated" && isTerminalStatus(getStatus(this, cell_id))) {
                    resolve(getResult(this, cell_id));
                    cleanup();
                    clearTimeout(t);
                }
            });
            if (timeout > 0) {
                t = setTimeout(() => {
                    cleanup();
                    reject(null);
                }, timeout);
            }
        })
    }
    /**
     * Add a new cell to the notebook
     *
     * Creates a new cell with a generated UUID, inserts it at the specified
     * position, and immediately runs it. The cell is added to both cell_inputs
     * and cell_results with appropriate initial state.
     *
     * @param {number} [index=0] - Position to insert the cell (0-based)
     * @param {string} [code=""] - Initial cell code
     * @param {Object} [metadata={}] - Additional cell metadata
     * @param {string} [cell_id=uuidv4()] - Snippet's UUID, if you need to specifically set one
     * @returns {Promise<string>} UUID of the newly created cell
     * @throws {Error} If not connected to notebook
     *
     * @example
     * const cellId = await worker.addSnippet(0, "println(\"Hello World\")");
     */
    async addSnippet(index = 0, code = "", metadata = {}, cell_id = uuidv4()) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        await this._update_notebook_state((notebook) => {
            notebook.cell_inputs[cell_id] = {
                cell_id: cell_id,
                code,
                code_folded: false,
                metadata: { ...DEFAULT_CELL_METADATA$1, ...metadata },
            };

            // Add to cell_order
            notebook.cell_order = [...notebook.cell_order.slice(0, index), cell_id, ...notebook.cell_order.slice(index, Infinity)];
        });

        // Wait for the server to confirm the cell addition
        await this.client.send("run_multiple_cells", { cells: [cell_id] }, { notebook_id: this.notebook_id });

        // Update local state to match server response
        // this.notebook_state = new_notebook;

        this._notify_update("cell_added", { cell_id, index });

        return cell_id
    }

    /**
     * Move cells to a new position in the notebook. The order of `cell_ids` is preserved in the result.
     *
     * @param {Array<string>} cell_ids - Cell UUIDs to move, in desired order
     * @param {number} index - Target position in the current cell order (before removing the moved cells)
     * @returns {Promise<void>}
     *
     * @example
     * // Given cell_order [A, B, C, D, E], move C and A to position 1 (in that order):
     * await worker.moveSnippets(["C", "A"], 1)
     * // Result: [B, C, A, D, E]
     */
    async moveSnippets(cell_ids, index) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        index = Math.max(0, index);
        const cell_ids_set = new Set(cell_ids);

        await this._update_notebook_state((notebook) => {
            let before = notebook.cell_order.slice(0, index).filter((x) => !cell_ids_set.has(x));
            let after = notebook.cell_order.slice(index, Infinity).filter((x) => !cell_ids_set.has(x));
            notebook.cell_order = [...before, ...cell_ids, ...after];
        });

        this._notify_update("cells_moved", { cell_ids, index });
    }

    /**
     * Delete cells from the notebook
     * @param {Array<string>} cell_ids - Array of cell UUIDs to delete
     * @returns {Promise<void>}
     */
    async deleteSnippets(cell_ids) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        await this._update_notebook_state((notebook) => {
            for (let cell_id of cell_ids) {
                delete notebook.cell_inputs[cell_id];
            }
            notebook.cell_order = notebook.cell_order.filter((cell_id) => !cell_ids.includes(cell_id));
        });

        // Clear local state for deleted cells
        for (let cell_id of cell_ids) {
            delete this.cell_inputs_local[cell_id];
        }

        // Run empty cells array to trigger dependency updates
        await this.client.send("run_multiple_cells", { cells: [] }, { notebook_id: this.notebook_id });

        this._notify_update("cells_deleted", { cell_ids });
    }

    /**
     * Move the notebook to a new file path. The backend will save the notebook to the new path,
     * delete the old file, move any associated `.assets` directory, and update the Julia process's
     * working directory.
     *
     * @param {string} new_path - Absolute path for the notebook file
     * @returns {Promise<void>}
     * @throws {Error} If the new path already exists on the server
     *
     * @example
     * await worker.moveTo("/home/user/notebooks/analysis.jl")
     */
    async moveTo(new_path) {
        if (!this.client || !this.notebook_state) {
            throw new Error("Not connected to notebook")
        }

        await this._update_notebook_state((notebook) => {
            notebook.in_temp_dir = false;
            notebook.path = new_path;
        });

        this._notify_update("notebook_moved", { path: new_path });
    }

    /**
     * Interrupt notebook execution
     * @returns {Promise<void>}
     */
    async interrupt() {
        if (!this.client) {
            throw new Error("Not connected to notebook")
        }

        await this.client.send("interrupt_all", {}, { notebook_id: this.notebook_id }, false);
    }

    /**
     * Register a callback for updates from the WebSocket
     *
     * This callback will be called every time a state update comes from the websocket.
     * Use this to react to cell execution results, notebook state changes, etc.
     *
     * @param {function(event: import("./index.js").UpdateEvent): void} callback - Function to call on updates
     * @returns {function(): void} Unsubscribe function to stop receiving updates
     *
     * @example
     * const unsubscribe = worker.onUpdate((event) => {
     *   if (event.type === 'notebook_updated') {
     *     console.log('Notebook state changed');
     *   }
     * });
     *
     * // Later, stop listening
     * unsubscribe();
     */
    onUpdate(callback) {
        this._update_handlers.add(callback);
        return () => this._update_handlers.delete(callback)
    }

    /**
     * Register a handler for connection status changes
     * @param {Function} handler - Function to call on connection status changes
     * @returns {function(): void} Unsubscribe function
     */
    onConnectionStatus(handler) {
        this._connection_status_handlers.add(handler);
        return () => this._connection_status_handlers.delete(handler)
    }

    /**
     * Check if notebook is currently idle (not running any cells)
     *
     * A notebook is considered idle when:
     * - No local updates are pending
     * - No cells are currently running or queued
     *
     * @returns {boolean} True if notebook is idle
     */
    isIdle() {
        if (!this.notebook_state) return true

        return !(this.pending_local_updates > 0 || Object.values(this.notebook_state.cell_results).some((cell) => cell.running || cell.queued))
    }

    // Private methods

    /**
     * Handle update from WebSocket
     * @param {Object} update - Update object from server
     * @param {boolean} by_me - Whether update was triggered by this client
     * @private
     */
    _handle_update(update, by_me) {
        if (this.notebook_state?.notebook_id === update.notebook_id) {
            const message = update.message;
            switch (update.type) {
                case "notebook_diff":
                    this._handle_notebook_diff(message);
                    break
                default:
                    console.warn("Received unknown update type!", update);
                    break
            }
        }
    }

    /**
     * Handle notebook diff message
     * @param {Object} message - Notebook diff message
     * @private
     */
    _handle_notebook_diff(message) {
        if (message?.counter != null) {
            if (message.counter <= this.last_update_counter) {
                console.error("State update out of order", message.counter, this.last_update_counter);
                return
            }
            this.last_update_counter = message.counter;
        }

        if (message.patches && message.patches.length > 0) {
            // Serialize patch application through the update queue to avoid race conditions
            // This ensures patches are applied sequentially, matching Editor.js behavior
            const new_task = this._update_queue_promise.then(() => {
                return this._apply_patches(message.patches)
            });

            // Update the queue promise, catching any errors to prevent breaking the chain
            this._update_queue_promise = new_task.catch((error) => {
                console.error("Error in patch application queue:", error);
            });
        }
    }

    /**
     * Apply patches to notebook state
     * @param {Array} patches - Array of patches to apply
     * @returns {Promise<void>} Promise that resolves when patches are applied
     * @private
     */
    _apply_patches(patches) {
        return new Promise((resolve, reject) => {
            try {
                // Ensure we have a valid notebook state before applying patches
                if (!this.notebook_state) {
                    console.warn("No notebook state available, skipping patch application");
                    resolve();
                    return
                }

                // Validate patches before applying
                if (!Array.isArray(patches) || patches.length === 0) {
                    console.warn("Invalid or empty patches, skipping application");
                    resolve();
                    return
                }

                let new_notebook = applyPatches(this.notebook_state, patches);

                this.notebook_state = new_notebook;
                this.last_update_time = Date.now();

                // Notify handlers after successful patch application
                this._notify_update("notebook_updated", {
                    patches,
                    notebook_id: this.notebook_id,
                });

                resolve();
            } catch (exception) {
                console.error("Failed to apply patches:", exception);
                console.error("Notebook state:", this.notebook_state);
                console.error("Patches:", patches);

                // Request state reset from server
                if (this.client && this.connected) {
                    console.info("Resetting state");
                    this.client.send("reset_shared_state", {}, { notebook_id: this.notebook_id }, false);
                }

                reject(exception);
            }
        })
    }

    /**
     * Handle connection status change
     * @param {boolean} connected - Whether connection is active
     * @param {boolean} hopeless - Whether connection is hopeless
     * @private
     */
    _handle_connection_status(connected, hopeless) {
        this.connected = connected;
        this._notify_connection_status_change(connected, hopeless);
    }

    /**
     * Handle reconnect event
     * @returns {Promise<boolean>} Whether reconnect was successful
     * @private
     */
    async _handle_reconnect() {
        console.warn("Reconnected! Checking states");

        if (this.client) {
            await this.client.send("reset_shared_state", {}, { notebook_id: this.notebook_id }, false);
        }

        return true
    }

    /**
     * Update notebook state using a mutate function
     * @param {Function} mutate_fn - Function to mutate the notebook state
     * @returns {Promise<void>}
     * @private
     */
    async _update_notebook_state(mutate_fn) {
        if (!this.notebook_state) return

        const [notebook, changes] = produceWithPatches(this.notebook_state, (notebook) => {
            mutate_fn(notebook);
        });

        if (changes.length === 0) return

        this.pending_local_updates++;

        try {
            // The changes to be sent should already exist locally
            // because patches are going to be diffed against that
            this.notebook_state = notebook;
            const response = await this.client.send("update_notebook", { updates: changes }, { notebook_id: this.notebook_id }, false);

            if (response.message?.response?.update_went_well === "👎") {
                throw new Error(`Pluto update_notebook error: (from Julia: ${response.message.response.why_not})`)
            }
            this.last_update_time = Date.now();
        } finally {
            this.pending_local_updates--;
        }
    }

    /**
     * Notify update handlers
     * @param {string} event_type - Type of event
     * @param {*} data - Event data
     * @private
     */
    _notify_update(event_type, data) {
        this._update_handlers.forEach((handler) => {
            try {
                handler({
                    type: event_type,
                    data,
                    timestamp: Date.now(),
                    notebook: this.notebook_state,
                });
            } catch (error) {
                console.error("Error in update handler:", error);
            }
        });
    }

    /**
     * Notify connection status handlers
     * @param {boolean} connected - Whether connection is active
     * @param {boolean} hopeless - Whether connection is hopeless
     * @private
     */
    _notify_connection_status_change(connected, hopeless) {
        this._connection_status_handlers.forEach((handler) => {
            try {
                handler({ connected, hopeless, timestamp: Date.now() });
            } catch (error) {
                console.error("Error in connection status handler:", error);
            }
        });
    }
};

// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length - 1; i >= 0; i--) {
    var last = parts[i];
    if (last === '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Split a filename into [root, dir, basename, ext], unix version
// 'root' is just a slash, or nothing.
var splitPathRe =
    /^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
var splitPath = function(filename) {
  return splitPathRe.exec(filename).slice(1);
};

// path.resolve([from ...], to)
// posix version
function resolve() {
  var resolvedPath = '',
      resolvedAbsolute = false;

  for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
    var path = (i >= 0) ? arguments[i] : '/';

    // Skip empty and invalid entries
    if (typeof path !== 'string') {
      throw new TypeError('Arguments to path.resolve must be strings');
    } else if (!path) {
      continue;
    }

    resolvedPath = path + '/' + resolvedPath;
    resolvedAbsolute = path.charAt(0) === '/';
  }

  // At this point the path should be resolved to a full absolute path, but
  // handle relative paths to be safe (might happen when process.cwd() fails)

  // Normalize the path
  resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
}
function dirname(path) {
  var result = splitPath(path),
      root = result[0],
      dir = result[1];

  if (!root && !dir) {
    // No dirname whatsoever
    return '.';
  }

  if (dir) {
    // It has a dirname, strip trailing slash
    dir = dir.substr(0, dir.length - 1);
  }

  return root + dir;
}
function filter (xs, f) {
    if (xs.filter) return xs.filter(f);
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (f(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

/**
 * File System Interface for resolving Julia include() statements
 *
 * This module provides functionality to recursively resolve all include() statements
 * in Julia files, replacing them with the actual file contents.
 */

/**
 * Resolve an include path relative to the current file's directory
 * @param {string} includePath - The path specified in the include() statement
 * @param {string} currentDir - Directory of the file containing the include
 * @returns {string} Absolute path to the included file
 */
function _resolveIncludePath(includePath, currentDir) {
    // Handle relative paths
    if (includePath.startsWith("./") || includePath.startsWith("../")) {
        return resolve(currentDir, includePath);
    }

    // Handle absolute paths
    if (includePath.startsWith("/")) {
        return includePath;
    }

    // Handle paths relative to current directory (no ./ prefix)
    return resolve(currentDir, includePath);
}

/**
 * Recursively resolve includes for a file
 * @param {import("memfs").IFs} fs - File system instance
 * @param {Set<string>} processedFiles - Set of already processed file paths
 * @param {RegExp} includePattern - Pattern to match include statements
 * @param {string} filePath - Current file path
 * @param {string} rootPath - Root file path (for cycle detection)
 * @returns {string} Resolved file content
 */
function _resolveIncludesRecursive(fs, processedFiles, includePattern, filePath, rootPath) {
    // Resolve to absolute path
    const absolutePath = resolve(filePath);

    // Check for circular includes
    if (processedFiles.has(absolutePath)) {
        console.warn(`Circular include detected: ${absolutePath}`);
        return `# Circular include detected: ${filePath}`;
    }

    // Add to processed files
    processedFiles.add(absolutePath);

    try {
        // Read the file content
        const content = fs.readFileSync(absolutePath, "utf8");

        // Process line by line to check for commented includes
        const lines = content.split("\n");
        const resolvedLines = lines.map((line) => {
            // Check if the line contains an include
            const includeMatch = line.match(includePattern);
            if (!includeMatch) {
                return line;
            }

            // Check if the line is commented out (starts with # after trimming)
            const trimmedLine = line.trim();
            if (trimmedLine.startsWith("#")) {
                // This is a commented include, leave it as is
                return line;
            }

            // Process the include
            return line.replace(includePattern, (_, includePath) => {
                try {
                    // Resolve the include path relative to the current file's directory
                    const currentDir = dirname(absolutePath);
                    const resolvedIncludePath = _resolveIncludePath(includePath, currentDir);

                    // Add a comment to mark where the include was resolved
                    const includeComment = `\n# ===== Included from: ${includePath} =====\n`;
                    const endComment = `\n# ===== End of ${includePath} =====\n`;

                    // Recursively resolve the included file
                    const includedContent = _resolveIncludesRecursive(fs, processedFiles, includePattern, resolvedIncludePath, rootPath);

                    return includeComment + includedContent + endComment;
                } catch (error) {
                    console.error(`Error resolving include "${includePath}" in ${filePath}:`, error.message);
                    return `# Error resolving include: ${includePath} - ${error.message}`;
                }
            });
        });

        return resolvedLines.join("\n");
    } catch (error) {
        console.error(`Error reading file ${filePath}:`, error.message);
        return `# Error reading file: ${filePath} - ${error.message}`;
    } finally {
        // Remove from processed files when done (allows for includes in different contexts)
        processedFiles.delete(absolutePath);
    }
}

/**
 * Read a file and recursively resolve all include() statements
 * @param {import("memfs").IFs} fs - File system instance
 * @param {string} filePath - Absolute path to the file to process
 * @returns {string} File content with all includes resolved
 */
function resolveIncludes(fs, filePath) {
    const processedFiles = new Set();
    const includePattern = /include\(\s*["']([^"']+)["']\s*\)/g;

    return _resolveIncludesRecursive(fs, processedFiles, includePattern, filePath, filePath);
}

var commonjsGlobal = typeof globalThis !== 'undefined' ? globalThis : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

function getAugmentedNamespace(n) {
  if (Object.prototype.hasOwnProperty.call(n, '__esModule')) return n;
  var f = n.default;
	if (typeof f == "function") {
		var a = function a () {
			var isInstance = false;
      try {
        isInstance = this instanceof a;
      } catch {}
			if (isInstance) {
        return Reflect.construct(f, arguments, this.constructor);
			}
			return f.apply(this, arguments);
		};
		a.prototype = f.prototype;
  } else a = {};
  Object.defineProperty(a, '__esModule', {value: true});
	Object.keys(n).forEach(function (k) {
		var d = Object.getOwnPropertyDescriptor(n, k);
		Object.defineProperty(a, k, d.get ? d : {
			enumerable: true,
			get: function () {
				return n[k];
			}
		});
	});
	return a;
}

var toml = {};

var parse$1 = {exports: {}};

var tomlParser = {exports: {}};

var parser;
var hasRequiredParser;

function requireParser () {
	if (hasRequiredParser) return parser;
	hasRequiredParser = 1;
	const ParserEND = 0x110000;
	class ParserError extends Error {
	  /* istanbul ignore next */
	  constructor (msg, filename, linenumber) {
	    super('[ParserError] ' + msg, filename, linenumber);
	    this.name = 'ParserError';
	    this.code = 'ParserError';
	    if (Error.captureStackTrace) Error.captureStackTrace(this, ParserError);
	  }
	}
	class State {
	  constructor (parser) {
	    this.parser = parser;
	    this.buf = '';
	    this.returned = null;
	    this.result = null;
	    this.resultTable = null;
	    this.resultArr = null;
	  }
	}
	class Parser {
	  constructor () {
	    this.pos = 0;
	    this.col = 0;
	    this.line = 0;
	    this.obj = {};
	    this.ctx = this.obj;
	    this.stack = [];
	    this._buf = '';
	    this.char = null;
	    this.ii = 0;
	    this.state = new State(this.parseStart);
	  }

	  parse (str) {
	    /* istanbul ignore next */
	    if (str.length === 0 || str.length == null) return

	    this._buf = String(str);
	    this.ii = -1;
	    this.char = -1;
	    let getNext;
	    while (getNext === false || this.nextChar()) {
	      getNext = this.runOne();
	    }
	    this._buf = null;
	  }
	  nextChar () {
	    if (this.char === 0x0A) {
	      ++this.line;
	      this.col = -1;
	    }
	    ++this.ii;
	    this.char = this._buf.codePointAt(this.ii);
	    ++this.pos;
	    ++this.col;
	    return this.haveBuffer()
	  }
	  haveBuffer () {
	    return this.ii < this._buf.length
	  }
	  runOne () {
	    return this.state.parser.call(this, this.state.returned)
	  }
	  finish () {
	    this.char = ParserEND;
	    let last;
	    do {
	      last = this.state.parser;
	      this.runOne();
	    } while (this.state.parser !== last)

	    this.ctx = null;
	    this.state = null;
	    this._buf = null;

	    return this.obj
	  }
	  next (fn) {
	    /* istanbul ignore next */
	    if (typeof fn !== 'function') throw new ParserError('Tried to set state to non-existent state: ' + JSON.stringify(fn))
	    this.state.parser = fn;
	  }
	  goto (fn) {
	    this.next(fn);
	    return this.runOne()
	  }
	  call (fn, returnWith) {
	    if (returnWith) this.next(returnWith);
	    this.stack.push(this.state);
	    this.state = new State(fn);
	  }
	  callNow (fn, returnWith) {
	    this.call(fn, returnWith);
	    return this.runOne()
	  }
	  return (value) {
	    /* istanbul ignore next */
	    if (this.stack.length === 0) throw this.error(new ParserError('Stack underflow'))
	    if (value === undefined) value = this.state.buf;
	    this.state = this.stack.pop();
	    this.state.returned = value;
	  }
	  returnNow (value) {
	    this.return(value);
	    return this.runOne()
	  }
	  consume () {
	    /* istanbul ignore next */
	    if (this.char === ParserEND) throw this.error(new ParserError('Unexpected end-of-buffer'))
	    this.state.buf += this._buf[this.ii];
	  }
	  error (err) {
	    err.line = this.line;
	    err.col = this.col;
	    err.pos = this.pos;
	    return err
	  }
	  /* istanbul ignore next */
	  parseStart () {
	    throw new ParserError('Must declare a parseStart method')
	  }
	}
	Parser.END = ParserEND;
	Parser.Error = ParserError;
	parser = Parser;
	return parser;
}

var createDatetime;
var hasRequiredCreateDatetime;

function requireCreateDatetime () {
	if (hasRequiredCreateDatetime) return createDatetime;
	hasRequiredCreateDatetime = 1;
	createDatetime = value => {
	  const date = new Date(value);
	  /* istanbul ignore if */
	  if (isNaN(date)) {
	    throw new TypeError('Invalid Datetime')
	  } else {
	    return date
	  }
	};
	return createDatetime;
}

var formatNum;
var hasRequiredFormatNum;

function requireFormatNum () {
	if (hasRequiredFormatNum) return formatNum;
	hasRequiredFormatNum = 1;
	formatNum = (d, num) => {
	  num = String(num);
	  while (num.length < d) num = '0' + num;
	  return num
	};
	return formatNum;
}

var createDatetimeFloat;
var hasRequiredCreateDatetimeFloat;

function requireCreateDatetimeFloat () {
	if (hasRequiredCreateDatetimeFloat) return createDatetimeFloat;
	hasRequiredCreateDatetimeFloat = 1;
	const f = requireFormatNum();

	class FloatingDateTime extends Date {
	  constructor (value) {
	    super(value + 'Z');
	    this.isFloating = true;
	  }
	  toISOString () {
	    const date = `${this.getUTCFullYear()}-${f(2, this.getUTCMonth() + 1)}-${f(2, this.getUTCDate())}`;
	    const time = `${f(2, this.getUTCHours())}:${f(2, this.getUTCMinutes())}:${f(2, this.getUTCSeconds())}.${f(3, this.getUTCMilliseconds())}`;
	    return `${date}T${time}`
	  }
	}

	createDatetimeFloat = value => {
	  const date = new FloatingDateTime(value);
	  /* istanbul ignore if */
	  if (isNaN(date)) {
	    throw new TypeError('Invalid Datetime')
	  } else {
	    return date
	  }
	};
	return createDatetimeFloat;
}

var createDate;
var hasRequiredCreateDate;

function requireCreateDate () {
	if (hasRequiredCreateDate) return createDate;
	hasRequiredCreateDate = 1;
	const f = requireFormatNum();
	const DateTime = commonjsGlobal.Date;

	class Date extends DateTime {
	  constructor (value) {
	    super(value);
	    this.isDate = true;
	  }
	  toISOString () {
	    return `${this.getUTCFullYear()}-${f(2, this.getUTCMonth() + 1)}-${f(2, this.getUTCDate())}`
	  }
	}

	createDate = value => {
	  const date = new Date(value);
	  /* istanbul ignore if */
	  if (isNaN(date)) {
	    throw new TypeError('Invalid Datetime')
	  } else {
	    return date
	  }
	};
	return createDate;
}

var createTime;
var hasRequiredCreateTime;

function requireCreateTime () {
	if (hasRequiredCreateTime) return createTime;
	hasRequiredCreateTime = 1;
	const f = requireFormatNum();

	class Time extends Date {
	  constructor (value) {
	    super(`0000-01-01T${value}Z`);
	    this.isTime = true;
	  }
	  toISOString () {
	    return `${f(2, this.getUTCHours())}:${f(2, this.getUTCMinutes())}:${f(2, this.getUTCSeconds())}.${f(3, this.getUTCMilliseconds())}`
	  }
	}

	createTime = value => {
	  const date = new Time(value);
	  /* istanbul ignore if */
	  if (isNaN(date)) {
	    throw new TypeError('Invalid Datetime')
	  } else {
	    return date
	  }
	};
	return createTime;
}

var hasRequiredTomlParser;

function requireTomlParser () {
	if (hasRequiredTomlParser) return tomlParser.exports;
	hasRequiredTomlParser = 1;
	/* eslint-disable no-new-wrappers, no-eval, camelcase, operator-linebreak */
	tomlParser.exports = makeParserClass(requireParser());
	tomlParser.exports.makeParserClass = makeParserClass;

	class TomlError extends Error {
	  constructor (msg) {
	    super(msg);
	    this.name = 'TomlError';
	    /* istanbul ignore next */
	    if (Error.captureStackTrace) Error.captureStackTrace(this, TomlError);
	    this.fromTOML = true;
	    this.wrapped = null;
	  }
	}
	TomlError.wrap = err => {
	  const terr = new TomlError(err.message);
	  terr.code = err.code;
	  terr.wrapped = err;
	  return terr
	};
	tomlParser.exports.TomlError = TomlError;

	const createDateTime = requireCreateDatetime();
	const createDateTimeFloat = requireCreateDatetimeFloat();
	const createDate = requireCreateDate();
	const createTime = requireCreateTime();

	const CTRL_I = 0x09;
	const CTRL_J = 0x0A;
	const CTRL_M = 0x0D;
	const CTRL_CHAR_BOUNDARY = 0x1F; // the last non-character in the latin1 region of unicode, except DEL
	const CHAR_SP = 0x20;
	const CHAR_QUOT = 0x22;
	const CHAR_NUM = 0x23;
	const CHAR_APOS = 0x27;
	const CHAR_PLUS = 0x2B;
	const CHAR_COMMA = 0x2C;
	const CHAR_HYPHEN = 0x2D;
	const CHAR_PERIOD = 0x2E;
	const CHAR_0 = 0x30;
	const CHAR_1 = 0x31;
	const CHAR_7 = 0x37;
	const CHAR_9 = 0x39;
	const CHAR_COLON = 0x3A;
	const CHAR_EQUALS = 0x3D;
	const CHAR_A = 0x41;
	const CHAR_E = 0x45;
	const CHAR_F = 0x46;
	const CHAR_T = 0x54;
	const CHAR_U = 0x55;
	const CHAR_Z = 0x5A;
	const CHAR_LOWBAR = 0x5F;
	const CHAR_a = 0x61;
	const CHAR_b = 0x62;
	const CHAR_e = 0x65;
	const CHAR_f = 0x66;
	const CHAR_i = 0x69;
	const CHAR_l = 0x6C;
	const CHAR_n = 0x6E;
	const CHAR_o = 0x6F;
	const CHAR_r = 0x72;
	const CHAR_s = 0x73;
	const CHAR_t = 0x74;
	const CHAR_u = 0x75;
	const CHAR_x = 0x78;
	const CHAR_z = 0x7A;
	const CHAR_LCUB = 0x7B;
	const CHAR_RCUB = 0x7D;
	const CHAR_LSQB = 0x5B;
	const CHAR_BSOL = 0x5C;
	const CHAR_RSQB = 0x5D;
	const CHAR_DEL = 0x7F;
	const SURROGATE_FIRST = 0xD800;
	const SURROGATE_LAST = 0xDFFF;

	const escapes = {
	  [CHAR_b]: '\u0008',
	  [CHAR_t]: '\u0009',
	  [CHAR_n]: '\u000A',
	  [CHAR_f]: '\u000C',
	  [CHAR_r]: '\u000D',
	  [CHAR_QUOT]: '\u0022',
	  [CHAR_BSOL]: '\u005C'
	};

	function isDigit (cp) {
	  return cp >= CHAR_0 && cp <= CHAR_9
	}
	function isHexit (cp) {
	  return (cp >= CHAR_A && cp <= CHAR_F) || (cp >= CHAR_a && cp <= CHAR_f) || (cp >= CHAR_0 && cp <= CHAR_9)
	}
	function isBit (cp) {
	  return cp === CHAR_1 || cp === CHAR_0
	}
	function isOctit (cp) {
	  return (cp >= CHAR_0 && cp <= CHAR_7)
	}
	function isAlphaNumQuoteHyphen (cp) {
	  return (cp >= CHAR_A && cp <= CHAR_Z)
	      || (cp >= CHAR_a && cp <= CHAR_z)
	      || (cp >= CHAR_0 && cp <= CHAR_9)
	      || cp === CHAR_APOS
	      || cp === CHAR_QUOT
	      || cp === CHAR_LOWBAR
	      || cp === CHAR_HYPHEN
	}
	function isAlphaNumHyphen (cp) {
	  return (cp >= CHAR_A && cp <= CHAR_Z)
	      || (cp >= CHAR_a && cp <= CHAR_z)
	      || (cp >= CHAR_0 && cp <= CHAR_9)
	      || cp === CHAR_LOWBAR
	      || cp === CHAR_HYPHEN
	}
	const _type = Symbol('type');
	const _declared = Symbol('declared');

	const hasOwnProperty = Object.prototype.hasOwnProperty;
	const defineProperty = Object.defineProperty;
	const descriptor = {configurable: true, enumerable: true, writable: true, value: undefined};

	function hasKey (obj, key) {
	  if (hasOwnProperty.call(obj, key)) return true
	  if (key === '__proto__') defineProperty(obj, '__proto__', descriptor);
	  return false
	}

	const INLINE_TABLE = Symbol('inline-table');
	function InlineTable () {
	  return Object.defineProperties({}, {
	    [_type]: {value: INLINE_TABLE}
	  })
	}
	function isInlineTable (obj) {
	  if (obj === null || typeof (obj) !== 'object') return false
	  return obj[_type] === INLINE_TABLE
	}

	const TABLE = Symbol('table');
	function Table () {
	  return Object.defineProperties({}, {
	    [_type]: {value: TABLE},
	    [_declared]: {value: false, writable: true}
	  })
	}
	function isTable (obj) {
	  if (obj === null || typeof (obj) !== 'object') return false
	  return obj[_type] === TABLE
	}

	const _contentType = Symbol('content-type');
	const INLINE_LIST = Symbol('inline-list');
	function InlineList (type) {
	  return Object.defineProperties([], {
	    [_type]: {value: INLINE_LIST},
	    [_contentType]: {value: type}
	  })
	}
	function isInlineList (obj) {
	  if (obj === null || typeof (obj) !== 'object') return false
	  return obj[_type] === INLINE_LIST
	}

	const LIST = Symbol('list');
	function List () {
	  return Object.defineProperties([], {
	    [_type]: {value: LIST}
	  })
	}
	function isList (obj) {
	  if (obj === null || typeof (obj) !== 'object') return false
	  return obj[_type] === LIST
	}

	// in an eval, to let bundlers not slurp in a util proxy
	let _custom;
	try {
	  const utilInspect = eval("require('util').inspect");
	  _custom = utilInspect.custom;
	} catch (_) {
	  /* eval require not available in transpiled bundle */
	}
	/* istanbul ignore next */
	const _inspect = _custom || 'inspect';

	class BoxedBigInt {
	  constructor (value) {
	    try {
	      this.value = commonjsGlobal.BigInt.asIntN(64, value);
	    } catch (_) {
	      /* istanbul ignore next */
	      this.value = null;
	    }
	    Object.defineProperty(this, _type, {value: INTEGER});
	  }
	  isNaN () {
	    return this.value === null
	  }
	  /* istanbul ignore next */
	  toString () {
	    return String(this.value)
	  }
	  /* istanbul ignore next */
	  [_inspect] () {
	    return `[BigInt: ${this.toString()}]}`
	  }
	  valueOf () {
	    return this.value
	  }
	}

	const INTEGER = Symbol('integer');
	function Integer (value) {
	  let num = Number(value);
	  // -0 is a float thing, not an int thing
	  if (Object.is(num, -0)) num = 0;
	  /* istanbul ignore else */
	  if (commonjsGlobal.BigInt && !Number.isSafeInteger(num)) {
	    return new BoxedBigInt(value)
	  } else {
	    /* istanbul ignore next */
	    return Object.defineProperties(new Number(num), {
	      isNaN: {value: function () { return isNaN(this) }},
	      [_type]: {value: INTEGER},
	      [_inspect]: {value: () => `[Integer: ${value}]`}
	    })
	  }
	}
	function isInteger (obj) {
	  if (obj === null || typeof (obj) !== 'object') return false
	  return obj[_type] === INTEGER
	}

	const FLOAT = Symbol('float');
	function Float (value) {
	  /* istanbul ignore next */
	  return Object.defineProperties(new Number(value), {
	    [_type]: {value: FLOAT},
	    [_inspect]: {value: () => `[Float: ${value}]`}
	  })
	}
	function isFloat (obj) {
	  if (obj === null || typeof (obj) !== 'object') return false
	  return obj[_type] === FLOAT
	}

	function tomlType (value) {
	  const type = typeof value;
	  if (type === 'object') {
	    /* istanbul ignore if */
	    if (value === null) return 'null'
	    if (value instanceof Date) return 'datetime'
	    /* istanbul ignore else */
	    if (_type in value) {
	      switch (value[_type]) {
	        case INLINE_TABLE: return 'inline-table'
	        case INLINE_LIST: return 'inline-list'
	        /* istanbul ignore next */
	        case TABLE: return 'table'
	        /* istanbul ignore next */
	        case LIST: return 'list'
	        case FLOAT: return 'float'
	        case INTEGER: return 'integer'
	      }
	    }
	  }
	  return type
	}

	function makeParserClass (Parser) {
	  class TOMLParser extends Parser {
	    constructor () {
	      super();
	      this.ctx = this.obj = Table();
	    }

	    /* MATCH HELPER */
	    atEndOfWord () {
	      return this.char === CHAR_NUM || this.char === CTRL_I || this.char === CHAR_SP || this.atEndOfLine()
	    }
	    atEndOfLine () {
	      return this.char === Parser.END || this.char === CTRL_J || this.char === CTRL_M
	    }

	    parseStart () {
	      if (this.char === Parser.END) {
	        return null
	      } else if (this.char === CHAR_LSQB) {
	        return this.call(this.parseTableOrList)
	      } else if (this.char === CHAR_NUM) {
	        return this.call(this.parseComment)
	      } else if (this.char === CTRL_J || this.char === CHAR_SP || this.char === CTRL_I || this.char === CTRL_M) {
	        return null
	      } else if (isAlphaNumQuoteHyphen(this.char)) {
	        return this.callNow(this.parseAssignStatement)
	      } else {
	        throw this.error(new TomlError(`Unknown character "${this.char}"`))
	      }
	    }

	    // HELPER, this strips any whitespace and comments to the end of the line
	    // then RETURNS. Last state in a production.
	    parseWhitespaceToEOL () {
	      if (this.char === CHAR_SP || this.char === CTRL_I || this.char === CTRL_M) {
	        return null
	      } else if (this.char === CHAR_NUM) {
	        return this.goto(this.parseComment)
	      } else if (this.char === Parser.END || this.char === CTRL_J) {
	        return this.return()
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected only whitespace or comments till end of line'))
	      }
	    }

	    /* ASSIGNMENT: key = value */
	    parseAssignStatement () {
	      return this.callNow(this.parseAssign, this.recordAssignStatement)
	    }
	    recordAssignStatement (kv) {
	      let target = this.ctx;
	      let finalKey = kv.key.pop();
	      for (let kw of kv.key) {
	        if (hasKey(target, kw) && (!isTable(target[kw]) || target[kw][_declared])) {
	          throw this.error(new TomlError("Can't redefine existing key"))
	        }
	        target = target[kw] = target[kw] || Table();
	      }
	      if (hasKey(target, finalKey)) {
	        throw this.error(new TomlError("Can't redefine existing key"))
	      }
	      // unbox our numbers
	      if (isInteger(kv.value) || isFloat(kv.value)) {
	        target[finalKey] = kv.value.valueOf();
	      } else {
	        target[finalKey] = kv.value;
	      }
	      return this.goto(this.parseWhitespaceToEOL)
	    }

	    /* ASSSIGNMENT expression, key = value possibly inside an inline table */
	    parseAssign () {
	      return this.callNow(this.parseKeyword, this.recordAssignKeyword)
	    }
	    recordAssignKeyword (key) {
	      if (this.state.resultTable) {
	        this.state.resultTable.push(key);
	      } else {
	        this.state.resultTable = [key];
	      }
	      return this.goto(this.parseAssignKeywordPreDot)
	    }
	    parseAssignKeywordPreDot () {
	      if (this.char === CHAR_PERIOD) {
	        return this.next(this.parseAssignKeywordPostDot)
	      } else if (this.char !== CHAR_SP && this.char !== CTRL_I) {
	        return this.goto(this.parseAssignEqual)
	      }
	    }
	    parseAssignKeywordPostDot () {
	      if (this.char !== CHAR_SP && this.char !== CTRL_I) {
	        return this.callNow(this.parseKeyword, this.recordAssignKeyword)
	      }
	    }

	    parseAssignEqual () {
	      if (this.char === CHAR_EQUALS) {
	        return this.next(this.parseAssignPreValue)
	      } else {
	        throw this.error(new TomlError('Invalid character, expected "="'))
	      }
	    }
	    parseAssignPreValue () {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else {
	        return this.callNow(this.parseValue, this.recordAssignValue)
	      }
	    }
	    recordAssignValue (value) {
	      return this.returnNow({key: this.state.resultTable, value: value})
	    }

	    /* COMMENTS: #...eol */
	    parseComment () {
	      do {
	        if (this.char === Parser.END || this.char === CTRL_J) {
	          return this.return()
	        }
	      } while (this.nextChar())
	    }

	    /* TABLES AND LISTS, [foo] and [[foo]] */
	    parseTableOrList () {
	      if (this.char === CHAR_LSQB) {
	        this.next(this.parseList);
	      } else {
	        return this.goto(this.parseTable)
	      }
	    }

	    /* TABLE [foo.bar.baz] */
	    parseTable () {
	      this.ctx = this.obj;
	      return this.goto(this.parseTableNext)
	    }
	    parseTableNext () {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else {
	        return this.callNow(this.parseKeyword, this.parseTableMore)
	      }
	    }
	    parseTableMore (keyword) {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else if (this.char === CHAR_RSQB) {
	        if (hasKey(this.ctx, keyword) && (!isTable(this.ctx[keyword]) || this.ctx[keyword][_declared])) {
	          throw this.error(new TomlError("Can't redefine existing key"))
	        } else {
	          this.ctx = this.ctx[keyword] = this.ctx[keyword] || Table();
	          this.ctx[_declared] = true;
	        }
	        return this.next(this.parseWhitespaceToEOL)
	      } else if (this.char === CHAR_PERIOD) {
	        if (!hasKey(this.ctx, keyword)) {
	          this.ctx = this.ctx[keyword] = Table();
	        } else if (isTable(this.ctx[keyword])) {
	          this.ctx = this.ctx[keyword];
	        } else if (isList(this.ctx[keyword])) {
	          this.ctx = this.ctx[keyword][this.ctx[keyword].length - 1];
	        } else {
	          throw this.error(new TomlError("Can't redefine existing key"))
	        }
	        return this.next(this.parseTableNext)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected whitespace, . or ]'))
	      }
	    }

	    /* LIST [[a.b.c]] */
	    parseList () {
	      this.ctx = this.obj;
	      return this.goto(this.parseListNext)
	    }
	    parseListNext () {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else {
	        return this.callNow(this.parseKeyword, this.parseListMore)
	      }
	    }
	    parseListMore (keyword) {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else if (this.char === CHAR_RSQB) {
	        if (!hasKey(this.ctx, keyword)) {
	          this.ctx[keyword] = List();
	        }
	        if (isInlineList(this.ctx[keyword])) {
	          throw this.error(new TomlError("Can't extend an inline array"))
	        } else if (isList(this.ctx[keyword])) {
	          const next = Table();
	          this.ctx[keyword].push(next);
	          this.ctx = next;
	        } else {
	          throw this.error(new TomlError("Can't redefine an existing key"))
	        }
	        return this.next(this.parseListEnd)
	      } else if (this.char === CHAR_PERIOD) {
	        if (!hasKey(this.ctx, keyword)) {
	          this.ctx = this.ctx[keyword] = Table();
	        } else if (isInlineList(this.ctx[keyword])) {
	          throw this.error(new TomlError("Can't extend an inline array"))
	        } else if (isInlineTable(this.ctx[keyword])) {
	          throw this.error(new TomlError("Can't extend an inline table"))
	        } else if (isList(this.ctx[keyword])) {
	          this.ctx = this.ctx[keyword][this.ctx[keyword].length - 1];
	        } else if (isTable(this.ctx[keyword])) {
	          this.ctx = this.ctx[keyword];
	        } else {
	          throw this.error(new TomlError("Can't redefine an existing key"))
	        }
	        return this.next(this.parseListNext)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected whitespace, . or ]'))
	      }
	    }
	    parseListEnd (keyword) {
	      if (this.char === CHAR_RSQB) {
	        return this.next(this.parseWhitespaceToEOL)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected whitespace, . or ]'))
	      }
	    }

	    /* VALUE string, number, boolean, inline list, inline object */
	    parseValue () {
	      if (this.char === Parser.END) {
	        throw this.error(new TomlError('Key without value'))
	      } else if (this.char === CHAR_QUOT) {
	        return this.next(this.parseDoubleString)
	      } if (this.char === CHAR_APOS) {
	        return this.next(this.parseSingleString)
	      } else if (this.char === CHAR_HYPHEN || this.char === CHAR_PLUS) {
	        return this.goto(this.parseNumberSign)
	      } else if (this.char === CHAR_i) {
	        return this.next(this.parseInf)
	      } else if (this.char === CHAR_n) {
	        return this.next(this.parseNan)
	      } else if (isDigit(this.char)) {
	        return this.goto(this.parseNumberOrDateTime)
	      } else if (this.char === CHAR_t || this.char === CHAR_f) {
	        return this.goto(this.parseBoolean)
	      } else if (this.char === CHAR_LSQB) {
	        return this.call(this.parseInlineList, this.recordValue)
	      } else if (this.char === CHAR_LCUB) {
	        return this.call(this.parseInlineTable, this.recordValue)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expecting string, number, datetime, boolean, inline array or inline table'))
	      }
	    }
	    recordValue (value) {
	      return this.returnNow(value)
	    }

	    parseInf () {
	      if (this.char === CHAR_n) {
	        return this.next(this.parseInf2)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected "inf", "+inf" or "-inf"'))
	      }
	    }
	    parseInf2 () {
	      if (this.char === CHAR_f) {
	        if (this.state.buf === '-') {
	          return this.return(-Infinity)
	        } else {
	          return this.return(Infinity)
	        }
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected "inf", "+inf" or "-inf"'))
	      }
	    }

	    parseNan () {
	      if (this.char === CHAR_a) {
	        return this.next(this.parseNan2)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected "nan"'))
	      }
	    }
	    parseNan2 () {
	      if (this.char === CHAR_n) {
	        return this.return(NaN)
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected "nan"'))
	      }
	    }

	    /* KEYS, barewords or basic, literal, or dotted */
	    parseKeyword () {
	      if (this.char === CHAR_QUOT) {
	        return this.next(this.parseBasicString)
	      } else if (this.char === CHAR_APOS) {
	        return this.next(this.parseLiteralString)
	      } else {
	        return this.goto(this.parseBareKey)
	      }
	    }

	    /* KEYS: barewords */
	    parseBareKey () {
	      do {
	        if (this.char === Parser.END) {
	          throw this.error(new TomlError('Key ended without value'))
	        } else if (isAlphaNumHyphen(this.char)) {
	          this.consume();
	        } else if (this.state.buf.length === 0) {
	          throw this.error(new TomlError('Empty bare keys are not allowed'))
	        } else {
	          return this.returnNow()
	        }
	      } while (this.nextChar())
	    }

	    /* STRINGS, single quoted (literal) */
	    parseSingleString () {
	      if (this.char === CHAR_APOS) {
	        return this.next(this.parseLiteralMultiStringMaybe)
	      } else {
	        return this.goto(this.parseLiteralString)
	      }
	    }
	    parseLiteralString () {
	      do {
	        if (this.char === CHAR_APOS) {
	          return this.return()
	        } else if (this.atEndOfLine()) {
	          throw this.error(new TomlError('Unterminated string'))
	        } else if (this.char === CHAR_DEL || (this.char <= CTRL_CHAR_BOUNDARY && this.char !== CTRL_I)) {
	          throw this.errorControlCharInString()
	        } else {
	          this.consume();
	        }
	      } while (this.nextChar())
	    }
	    parseLiteralMultiStringMaybe () {
	      if (this.char === CHAR_APOS) {
	        return this.next(this.parseLiteralMultiString)
	      } else {
	        return this.returnNow()
	      }
	    }
	    parseLiteralMultiString () {
	      if (this.char === CTRL_M) {
	        return null
	      } else if (this.char === CTRL_J) {
	        return this.next(this.parseLiteralMultiStringContent)
	      } else {
	        return this.goto(this.parseLiteralMultiStringContent)
	      }
	    }
	    parseLiteralMultiStringContent () {
	      do {
	        if (this.char === CHAR_APOS) {
	          return this.next(this.parseLiteralMultiEnd)
	        } else if (this.char === Parser.END) {
	          throw this.error(new TomlError('Unterminated multi-line string'))
	        } else if (this.char === CHAR_DEL || (this.char <= CTRL_CHAR_BOUNDARY && this.char !== CTRL_I && this.char !== CTRL_J && this.char !== CTRL_M)) {
	          throw this.errorControlCharInString()
	        } else {
	          this.consume();
	        }
	      } while (this.nextChar())
	    }
	    parseLiteralMultiEnd () {
	      if (this.char === CHAR_APOS) {
	        return this.next(this.parseLiteralMultiEnd2)
	      } else {
	        this.state.buf += "'";
	        return this.goto(this.parseLiteralMultiStringContent)
	      }
	    }
	    parseLiteralMultiEnd2 () {
	      if (this.char === CHAR_APOS) {
	        return this.return()
	      } else {
	        this.state.buf += "''";
	        return this.goto(this.parseLiteralMultiStringContent)
	      }
	    }

	    /* STRINGS double quoted */
	    parseDoubleString () {
	      if (this.char === CHAR_QUOT) {
	        return this.next(this.parseMultiStringMaybe)
	      } else {
	        return this.goto(this.parseBasicString)
	      }
	    }
	    parseBasicString () {
	      do {
	        if (this.char === CHAR_BSOL) {
	          return this.call(this.parseEscape, this.recordEscapeReplacement)
	        } else if (this.char === CHAR_QUOT) {
	          return this.return()
	        } else if (this.atEndOfLine()) {
	          throw this.error(new TomlError('Unterminated string'))
	        } else if (this.char === CHAR_DEL || (this.char <= CTRL_CHAR_BOUNDARY && this.char !== CTRL_I)) {
	          throw this.errorControlCharInString()
	        } else {
	          this.consume();
	        }
	      } while (this.nextChar())
	    }
	    recordEscapeReplacement (replacement) {
	      this.state.buf += replacement;
	      return this.goto(this.parseBasicString)
	    }
	    parseMultiStringMaybe () {
	      if (this.char === CHAR_QUOT) {
	        return this.next(this.parseMultiString)
	      } else {
	        return this.returnNow()
	      }
	    }
	    parseMultiString () {
	      if (this.char === CTRL_M) {
	        return null
	      } else if (this.char === CTRL_J) {
	        return this.next(this.parseMultiStringContent)
	      } else {
	        return this.goto(this.parseMultiStringContent)
	      }
	    }
	    parseMultiStringContent () {
	      do {
	        if (this.char === CHAR_BSOL) {
	          return this.call(this.parseMultiEscape, this.recordMultiEscapeReplacement)
	        } else if (this.char === CHAR_QUOT) {
	          return this.next(this.parseMultiEnd)
	        } else if (this.char === Parser.END) {
	          throw this.error(new TomlError('Unterminated multi-line string'))
	        } else if (this.char === CHAR_DEL || (this.char <= CTRL_CHAR_BOUNDARY && this.char !== CTRL_I && this.char !== CTRL_J && this.char !== CTRL_M)) {
	          throw this.errorControlCharInString()
	        } else {
	          this.consume();
	        }
	      } while (this.nextChar())
	    }
	    errorControlCharInString () {
	      let displayCode = '\\u00';
	      if (this.char < 16) {
	        displayCode += '0';
	      }
	      displayCode += this.char.toString(16);

	      return this.error(new TomlError(`Control characters (codes < 0x1f and 0x7f) are not allowed in strings, use ${displayCode} instead`))
	    }
	    recordMultiEscapeReplacement (replacement) {
	      this.state.buf += replacement;
	      return this.goto(this.parseMultiStringContent)
	    }
	    parseMultiEnd () {
	      if (this.char === CHAR_QUOT) {
	        return this.next(this.parseMultiEnd2)
	      } else {
	        this.state.buf += '"';
	        return this.goto(this.parseMultiStringContent)
	      }
	    }
	    parseMultiEnd2 () {
	      if (this.char === CHAR_QUOT) {
	        return this.return()
	      } else {
	        this.state.buf += '""';
	        return this.goto(this.parseMultiStringContent)
	      }
	    }
	    parseMultiEscape () {
	      if (this.char === CTRL_M || this.char === CTRL_J) {
	        return this.next(this.parseMultiTrim)
	      } else if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return this.next(this.parsePreMultiTrim)
	      } else {
	        return this.goto(this.parseEscape)
	      }
	    }
	    parsePreMultiTrim () {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else if (this.char === CTRL_M || this.char === CTRL_J) {
	        return this.next(this.parseMultiTrim)
	      } else {
	        throw this.error(new TomlError("Can't escape whitespace"))
	      }
	    }
	    parseMultiTrim () {
	      // explicitly whitespace here, END should follow the same path as chars
	      if (this.char === CTRL_J || this.char === CHAR_SP || this.char === CTRL_I || this.char === CTRL_M) {
	        return null
	      } else {
	        return this.returnNow()
	      }
	    }
	    parseEscape () {
	      if (this.char in escapes) {
	        return this.return(escapes[this.char])
	      } else if (this.char === CHAR_u) {
	        return this.call(this.parseSmallUnicode, this.parseUnicodeReturn)
	      } else if (this.char === CHAR_U) {
	        return this.call(this.parseLargeUnicode, this.parseUnicodeReturn)
	      } else {
	        throw this.error(new TomlError('Unknown escape character: ' + this.char))
	      }
	    }
	    parseUnicodeReturn (char) {
	      try {
	        const codePoint = parseInt(char, 16);
	        if (codePoint >= SURROGATE_FIRST && codePoint <= SURROGATE_LAST) {
	          throw this.error(new TomlError('Invalid unicode, character in range 0xD800 - 0xDFFF is reserved'))
	        }
	        return this.returnNow(String.fromCodePoint(codePoint))
	      } catch (err) {
	        throw this.error(TomlError.wrap(err))
	      }
	    }
	    parseSmallUnicode () {
	      if (!isHexit(this.char)) {
	        throw this.error(new TomlError('Invalid character in unicode sequence, expected hex'))
	      } else {
	        this.consume();
	        if (this.state.buf.length >= 4) return this.return()
	      }
	    }
	    parseLargeUnicode () {
	      if (!isHexit(this.char)) {
	        throw this.error(new TomlError('Invalid character in unicode sequence, expected hex'))
	      } else {
	        this.consume();
	        if (this.state.buf.length >= 8) return this.return()
	      }
	    }

	    /* NUMBERS */
	    parseNumberSign () {
	      this.consume();
	      return this.next(this.parseMaybeSignedInfOrNan)
	    }
	    parseMaybeSignedInfOrNan () {
	      if (this.char === CHAR_i) {
	        return this.next(this.parseInf)
	      } else if (this.char === CHAR_n) {
	        return this.next(this.parseNan)
	      } else {
	        return this.callNow(this.parseNoUnder, this.parseNumberIntegerStart)
	      }
	    }
	    parseNumberIntegerStart () {
	      if (this.char === CHAR_0) {
	        this.consume();
	        return this.next(this.parseNumberIntegerExponentOrDecimal)
	      } else {
	        return this.goto(this.parseNumberInteger)
	      }
	    }
	    parseNumberIntegerExponentOrDecimal () {
	      if (this.char === CHAR_PERIOD) {
	        this.consume();
	        return this.call(this.parseNoUnder, this.parseNumberFloat)
	      } else if (this.char === CHAR_E || this.char === CHAR_e) {
	        this.consume();
	        return this.next(this.parseNumberExponentSign)
	      } else {
	        return this.returnNow(Integer(this.state.buf))
	      }
	    }
	    parseNumberInteger () {
	      if (isDigit(this.char)) {
	        this.consume();
	      } else if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnder)
	      } else if (this.char === CHAR_E || this.char === CHAR_e) {
	        this.consume();
	        return this.next(this.parseNumberExponentSign)
	      } else if (this.char === CHAR_PERIOD) {
	        this.consume();
	        return this.call(this.parseNoUnder, this.parseNumberFloat)
	      } else {
	        const result = Integer(this.state.buf);
	        /* istanbul ignore if */
	        if (result.isNaN()) {
	          throw this.error(new TomlError('Invalid number'))
	        } else {
	          return this.returnNow(result)
	        }
	      }
	    }
	    parseNoUnder () {
	      if (this.char === CHAR_LOWBAR || this.char === CHAR_PERIOD || this.char === CHAR_E || this.char === CHAR_e) {
	        throw this.error(new TomlError('Unexpected character, expected digit'))
	      } else if (this.atEndOfWord()) {
	        throw this.error(new TomlError('Incomplete number'))
	      }
	      return this.returnNow()
	    }
	    parseNoUnderHexOctBinLiteral () {
	      if (this.char === CHAR_LOWBAR || this.char === CHAR_PERIOD) {
	        throw this.error(new TomlError('Unexpected character, expected digit'))
	      } else if (this.atEndOfWord()) {
	        throw this.error(new TomlError('Incomplete number'))
	      }
	      return this.returnNow()
	    }
	    parseNumberFloat () {
	      if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnder, this.parseNumberFloat)
	      } else if (isDigit(this.char)) {
	        this.consume();
	      } else if (this.char === CHAR_E || this.char === CHAR_e) {
	        this.consume();
	        return this.next(this.parseNumberExponentSign)
	      } else {
	        return this.returnNow(Float(this.state.buf))
	      }
	    }
	    parseNumberExponentSign () {
	      if (isDigit(this.char)) {
	        return this.goto(this.parseNumberExponent)
	      } else if (this.char === CHAR_HYPHEN || this.char === CHAR_PLUS) {
	        this.consume();
	        this.call(this.parseNoUnder, this.parseNumberExponent);
	      } else {
	        throw this.error(new TomlError('Unexpected character, expected -, + or digit'))
	      }
	    }
	    parseNumberExponent () {
	      if (isDigit(this.char)) {
	        this.consume();
	      } else if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnder)
	      } else {
	        return this.returnNow(Float(this.state.buf))
	      }
	    }

	    /* NUMBERS or DATETIMES  */
	    parseNumberOrDateTime () {
	      if (this.char === CHAR_0) {
	        this.consume();
	        return this.next(this.parseNumberBaseOrDateTime)
	      } else {
	        return this.goto(this.parseNumberOrDateTimeOnly)
	      }
	    }
	    parseNumberOrDateTimeOnly () {
	      // note, if two zeros are in a row then it MUST be a date
	      if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnder, this.parseNumberInteger)
	      } else if (isDigit(this.char)) {
	        this.consume();
	        if (this.state.buf.length > 4) this.next(this.parseNumberInteger);
	      } else if (this.char === CHAR_E || this.char === CHAR_e) {
	        this.consume();
	        return this.next(this.parseNumberExponentSign)
	      } else if (this.char === CHAR_PERIOD) {
	        this.consume();
	        return this.call(this.parseNoUnder, this.parseNumberFloat)
	      } else if (this.char === CHAR_HYPHEN) {
	        return this.goto(this.parseDateTime)
	      } else if (this.char === CHAR_COLON) {
	        return this.goto(this.parseOnlyTimeHour)
	      } else {
	        return this.returnNow(Integer(this.state.buf))
	      }
	    }
	    parseDateTimeOnly () {
	      if (this.state.buf.length < 4) {
	        if (isDigit(this.char)) {
	          return this.consume()
	        } else if (this.char === CHAR_COLON) {
	          return this.goto(this.parseOnlyTimeHour)
	        } else {
	          throw this.error(new TomlError('Expected digit while parsing year part of a date'))
	        }
	      } else {
	        if (this.char === CHAR_HYPHEN) {
	          return this.goto(this.parseDateTime)
	        } else {
	          throw this.error(new TomlError('Expected hyphen (-) while parsing year part of date'))
	        }
	      }
	    }
	    parseNumberBaseOrDateTime () {
	      if (this.char === CHAR_b) {
	        this.consume();
	        return this.call(this.parseNoUnderHexOctBinLiteral, this.parseIntegerBin)
	      } else if (this.char === CHAR_o) {
	        this.consume();
	        return this.call(this.parseNoUnderHexOctBinLiteral, this.parseIntegerOct)
	      } else if (this.char === CHAR_x) {
	        this.consume();
	        return this.call(this.parseNoUnderHexOctBinLiteral, this.parseIntegerHex)
	      } else if (this.char === CHAR_PERIOD) {
	        return this.goto(this.parseNumberInteger)
	      } else if (isDigit(this.char)) {
	        return this.goto(this.parseDateTimeOnly)
	      } else {
	        return this.returnNow(Integer(this.state.buf))
	      }
	    }
	    parseIntegerHex () {
	      if (isHexit(this.char)) {
	        this.consume();
	      } else if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnderHexOctBinLiteral)
	      } else {
	        const result = Integer(this.state.buf);
	        /* istanbul ignore if */
	        if (result.isNaN()) {
	          throw this.error(new TomlError('Invalid number'))
	        } else {
	          return this.returnNow(result)
	        }
	      }
	    }
	    parseIntegerOct () {
	      if (isOctit(this.char)) {
	        this.consume();
	      } else if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnderHexOctBinLiteral)
	      } else {
	        const result = Integer(this.state.buf);
	        /* istanbul ignore if */
	        if (result.isNaN()) {
	          throw this.error(new TomlError('Invalid number'))
	        } else {
	          return this.returnNow(result)
	        }
	      }
	    }
	    parseIntegerBin () {
	      if (isBit(this.char)) {
	        this.consume();
	      } else if (this.char === CHAR_LOWBAR) {
	        return this.call(this.parseNoUnderHexOctBinLiteral)
	      } else {
	        const result = Integer(this.state.buf);
	        /* istanbul ignore if */
	        if (result.isNaN()) {
	          throw this.error(new TomlError('Invalid number'))
	        } else {
	          return this.returnNow(result)
	        }
	      }
	    }

	    /* DATETIME */
	    parseDateTime () {
	      // we enter here having just consumed the year and about to consume the hyphen
	      if (this.state.buf.length < 4) {
	        throw this.error(new TomlError('Years less than 1000 must be zero padded to four characters'))
	      }
	      this.state.result = this.state.buf;
	      this.state.buf = '';
	      return this.next(this.parseDateMonth)
	    }
	    parseDateMonth () {
	      if (this.char === CHAR_HYPHEN) {
	        if (this.state.buf.length < 2) {
	          throw this.error(new TomlError('Months less than 10 must be zero padded to two characters'))
	        }
	        this.state.result += '-' + this.state.buf;
	        this.state.buf = '';
	        return this.next(this.parseDateDay)
	      } else if (isDigit(this.char)) {
	        this.consume();
	      } else {
	        throw this.error(new TomlError('Incomplete datetime'))
	      }
	    }
	    parseDateDay () {
	      if (this.char === CHAR_T || this.char === CHAR_SP) {
	        if (this.state.buf.length < 2) {
	          throw this.error(new TomlError('Days less than 10 must be zero padded to two characters'))
	        }
	        this.state.result += '-' + this.state.buf;
	        this.state.buf = '';
	        return this.next(this.parseStartTimeHour)
	      } else if (this.atEndOfWord()) {
	        return this.returnNow(createDate(this.state.result + '-' + this.state.buf))
	      } else if (isDigit(this.char)) {
	        this.consume();
	      } else {
	        throw this.error(new TomlError('Incomplete datetime'))
	      }
	    }
	    parseStartTimeHour () {
	      if (this.atEndOfWord()) {
	        return this.returnNow(createDate(this.state.result))
	      } else {
	        return this.goto(this.parseTimeHour)
	      }
	    }
	    parseTimeHour () {
	      if (this.char === CHAR_COLON) {
	        if (this.state.buf.length < 2) {
	          throw this.error(new TomlError('Hours less than 10 must be zero padded to two characters'))
	        }
	        this.state.result += 'T' + this.state.buf;
	        this.state.buf = '';
	        return this.next(this.parseTimeMin)
	      } else if (isDigit(this.char)) {
	        this.consume();
	      } else {
	        throw this.error(new TomlError('Incomplete datetime'))
	      }
	    }
	    parseTimeMin () {
	      if (this.state.buf.length < 2 && isDigit(this.char)) {
	        this.consume();
	      } else if (this.state.buf.length === 2 && this.char === CHAR_COLON) {
	        this.state.result += ':' + this.state.buf;
	        this.state.buf = '';
	        return this.next(this.parseTimeSec)
	      } else {
	        throw this.error(new TomlError('Incomplete datetime'))
	      }
	    }
	    parseTimeSec () {
	      if (isDigit(this.char)) {
	        this.consume();
	        if (this.state.buf.length === 2) {
	          this.state.result += ':' + this.state.buf;
	          this.state.buf = '';
	          return this.next(this.parseTimeZoneOrFraction)
	        }
	      } else {
	        throw this.error(new TomlError('Incomplete datetime'))
	      }
	    }

	    parseOnlyTimeHour () {
	      /* istanbul ignore else */
	      if (this.char === CHAR_COLON) {
	        if (this.state.buf.length < 2) {
	          throw this.error(new TomlError('Hours less than 10 must be zero padded to two characters'))
	        }
	        this.state.result = this.state.buf;
	        this.state.buf = '';
	        return this.next(this.parseOnlyTimeMin)
	      } else {
	        throw this.error(new TomlError('Incomplete time'))
	      }
	    }
	    parseOnlyTimeMin () {
	      if (this.state.buf.length < 2 && isDigit(this.char)) {
	        this.consume();
	      } else if (this.state.buf.length === 2 && this.char === CHAR_COLON) {
	        this.state.result += ':' + this.state.buf;
	        this.state.buf = '';
	        return this.next(this.parseOnlyTimeSec)
	      } else {
	        throw this.error(new TomlError('Incomplete time'))
	      }
	    }
	    parseOnlyTimeSec () {
	      if (isDigit(this.char)) {
	        this.consume();
	        if (this.state.buf.length === 2) {
	          return this.next(this.parseOnlyTimeFractionMaybe)
	        }
	      } else {
	        throw this.error(new TomlError('Incomplete time'))
	      }
	    }
	    parseOnlyTimeFractionMaybe () {
	      this.state.result += ':' + this.state.buf;
	      if (this.char === CHAR_PERIOD) {
	        this.state.buf = '';
	        this.next(this.parseOnlyTimeFraction);
	      } else {
	        return this.return(createTime(this.state.result))
	      }
	    }
	    parseOnlyTimeFraction () {
	      if (isDigit(this.char)) {
	        this.consume();
	      } else if (this.atEndOfWord()) {
	        if (this.state.buf.length === 0) throw this.error(new TomlError('Expected digit in milliseconds'))
	        return this.returnNow(createTime(this.state.result + '.' + this.state.buf))
	      } else {
	        throw this.error(new TomlError('Unexpected character in datetime, expected period (.), minus (-), plus (+) or Z'))
	      }
	    }

	    parseTimeZoneOrFraction () {
	      if (this.char === CHAR_PERIOD) {
	        this.consume();
	        this.next(this.parseDateTimeFraction);
	      } else if (this.char === CHAR_HYPHEN || this.char === CHAR_PLUS) {
	        this.consume();
	        this.next(this.parseTimeZoneHour);
	      } else if (this.char === CHAR_Z) {
	        this.consume();
	        return this.return(createDateTime(this.state.result + this.state.buf))
	      } else if (this.atEndOfWord()) {
	        return this.returnNow(createDateTimeFloat(this.state.result + this.state.buf))
	      } else {
	        throw this.error(new TomlError('Unexpected character in datetime, expected period (.), minus (-), plus (+) or Z'))
	      }
	    }
	    parseDateTimeFraction () {
	      if (isDigit(this.char)) {
	        this.consume();
	      } else if (this.state.buf.length === 1) {
	        throw this.error(new TomlError('Expected digit in milliseconds'))
	      } else if (this.char === CHAR_HYPHEN || this.char === CHAR_PLUS) {
	        this.consume();
	        this.next(this.parseTimeZoneHour);
	      } else if (this.char === CHAR_Z) {
	        this.consume();
	        return this.return(createDateTime(this.state.result + this.state.buf))
	      } else if (this.atEndOfWord()) {
	        return this.returnNow(createDateTimeFloat(this.state.result + this.state.buf))
	      } else {
	        throw this.error(new TomlError('Unexpected character in datetime, expected period (.), minus (-), plus (+) or Z'))
	      }
	    }
	    parseTimeZoneHour () {
	      if (isDigit(this.char)) {
	        this.consume();
	        // FIXME: No more regexps
	        if (/\d\d$/.test(this.state.buf)) return this.next(this.parseTimeZoneSep)
	      } else {
	        throw this.error(new TomlError('Unexpected character in datetime, expected digit'))
	      }
	    }
	    parseTimeZoneSep () {
	      if (this.char === CHAR_COLON) {
	        this.consume();
	        this.next(this.parseTimeZoneMin);
	      } else {
	        throw this.error(new TomlError('Unexpected character in datetime, expected colon'))
	      }
	    }
	    parseTimeZoneMin () {
	      if (isDigit(this.char)) {
	        this.consume();
	        if (/\d\d$/.test(this.state.buf)) return this.return(createDateTime(this.state.result + this.state.buf))
	      } else {
	        throw this.error(new TomlError('Unexpected character in datetime, expected digit'))
	      }
	    }

	    /* BOOLEAN */
	    parseBoolean () {
	      /* istanbul ignore else */
	      if (this.char === CHAR_t) {
	        this.consume();
	        return this.next(this.parseTrue_r)
	      } else if (this.char === CHAR_f) {
	        this.consume();
	        return this.next(this.parseFalse_a)
	      }
	    }
	    parseTrue_r () {
	      if (this.char === CHAR_r) {
	        this.consume();
	        return this.next(this.parseTrue_u)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }
	    parseTrue_u () {
	      if (this.char === CHAR_u) {
	        this.consume();
	        return this.next(this.parseTrue_e)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }
	    parseTrue_e () {
	      if (this.char === CHAR_e) {
	        return this.return(true)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }

	    parseFalse_a () {
	      if (this.char === CHAR_a) {
	        this.consume();
	        return this.next(this.parseFalse_l)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }

	    parseFalse_l () {
	      if (this.char === CHAR_l) {
	        this.consume();
	        return this.next(this.parseFalse_s)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }

	    parseFalse_s () {
	      if (this.char === CHAR_s) {
	        this.consume();
	        return this.next(this.parseFalse_e)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }

	    parseFalse_e () {
	      if (this.char === CHAR_e) {
	        return this.return(false)
	      } else {
	        throw this.error(new TomlError('Invalid boolean, expected true or false'))
	      }
	    }

	    /* INLINE LISTS */
	    parseInlineList () {
	      if (this.char === CHAR_SP || this.char === CTRL_I || this.char === CTRL_M || this.char === CTRL_J) {
	        return null
	      } else if (this.char === Parser.END) {
	        throw this.error(new TomlError('Unterminated inline array'))
	      } else if (this.char === CHAR_NUM) {
	        return this.call(this.parseComment)
	      } else if (this.char === CHAR_RSQB) {
	        return this.return(this.state.resultArr || InlineList())
	      } else {
	        return this.callNow(this.parseValue, this.recordInlineListValue)
	      }
	    }
	    recordInlineListValue (value) {
	      if (this.state.resultArr) {
	        const listType = this.state.resultArr[_contentType];
	        const valueType = tomlType(value);
	        if (listType !== valueType) {
	          throw this.error(new TomlError(`Inline lists must be a single type, not a mix of ${listType} and ${valueType}`))
	        }
	      } else {
	        this.state.resultArr = InlineList(tomlType(value));
	      }
	      if (isFloat(value) || isInteger(value)) {
	        // unbox now that we've verified they're ok
	        this.state.resultArr.push(value.valueOf());
	      } else {
	        this.state.resultArr.push(value);
	      }
	      return this.goto(this.parseInlineListNext)
	    }
	    parseInlineListNext () {
	      if (this.char === CHAR_SP || this.char === CTRL_I || this.char === CTRL_M || this.char === CTRL_J) {
	        return null
	      } else if (this.char === CHAR_NUM) {
	        return this.call(this.parseComment)
	      } else if (this.char === CHAR_COMMA) {
	        return this.next(this.parseInlineList)
	      } else if (this.char === CHAR_RSQB) {
	        return this.goto(this.parseInlineList)
	      } else {
	        throw this.error(new TomlError('Invalid character, expected whitespace, comma (,) or close bracket (])'))
	      }
	    }

	    /* INLINE TABLE */
	    parseInlineTable () {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else if (this.char === Parser.END || this.char === CHAR_NUM || this.char === CTRL_J || this.char === CTRL_M) {
	        throw this.error(new TomlError('Unterminated inline array'))
	      } else if (this.char === CHAR_RCUB) {
	        return this.return(this.state.resultTable || InlineTable())
	      } else {
	        if (!this.state.resultTable) this.state.resultTable = InlineTable();
	        return this.callNow(this.parseAssign, this.recordInlineTableValue)
	      }
	    }
	    recordInlineTableValue (kv) {
	      let target = this.state.resultTable;
	      let finalKey = kv.key.pop();
	      for (let kw of kv.key) {
	        if (hasKey(target, kw) && (!isTable(target[kw]) || target[kw][_declared])) {
	          throw this.error(new TomlError("Can't redefine existing key"))
	        }
	        target = target[kw] = target[kw] || Table();
	      }
	      if (hasKey(target, finalKey)) {
	        throw this.error(new TomlError("Can't redefine existing key"))
	      }
	      if (isInteger(kv.value) || isFloat(kv.value)) {
	        target[finalKey] = kv.value.valueOf();
	      } else {
	        target[finalKey] = kv.value;
	      }
	      return this.goto(this.parseInlineTableNext)
	    }
	    parseInlineTableNext () {
	      if (this.char === CHAR_SP || this.char === CTRL_I) {
	        return null
	      } else if (this.char === Parser.END || this.char === CHAR_NUM || this.char === CTRL_J || this.char === CTRL_M) {
	        throw this.error(new TomlError('Unterminated inline array'))
	      } else if (this.char === CHAR_COMMA) {
	        return this.next(this.parseInlineTable)
	      } else if (this.char === CHAR_RCUB) {
	        return this.goto(this.parseInlineTable)
	      } else {
	        throw this.error(new TomlError('Invalid character, expected whitespace, comma (,) or close bracket (])'))
	      }
	    }
	  }
	  return TOMLParser
	}
	return tomlParser.exports;
}

var parsePrettyError;
var hasRequiredParsePrettyError;

function requireParsePrettyError () {
	if (hasRequiredParsePrettyError) return parsePrettyError;
	hasRequiredParsePrettyError = 1;
	parsePrettyError = prettyError;

	function prettyError (err, buf) {
	  /* istanbul ignore if */
	  if (err.pos == null || err.line == null) return err
	  let msg = err.message;
	  msg += ` at row ${err.line + 1}, col ${err.col + 1}, pos ${err.pos}:\n`;

	  /* istanbul ignore else */
	  if (buf && buf.split) {
	    const lines = buf.split(/\n/);
	    const lineNumWidth = String(Math.min(lines.length, err.line + 3)).length;
	    let linePadding = ' ';
	    while (linePadding.length < lineNumWidth) linePadding += ' ';
	    for (let ii = Math.max(0, err.line - 1); ii < Math.min(lines.length, err.line + 2); ++ii) {
	      let lineNum = String(ii + 1);
	      if (lineNum.length < lineNumWidth) lineNum = ' ' + lineNum;
	      if (err.line === ii) {
	        msg += lineNum + '> ' + lines[ii] + '\n';
	        msg += linePadding + '  ';
	        for (let hh = 0; hh < err.col; ++hh) {
	          msg += ' ';
	        }
	        msg += '^\n';
	      } else {
	        msg += lineNum + ': ' + lines[ii] + '\n';
	      }
	    }
	  }
	  err.message = msg + '\n';
	  return err
	}
	return parsePrettyError;
}

var parseString_1;
var hasRequiredParseString;

function requireParseString () {
	if (hasRequiredParseString) return parseString_1;
	hasRequiredParseString = 1;
	parseString_1 = parseString;

	const TOMLParser = requireTomlParser();
	const prettyError = requireParsePrettyError();

	function parseString (str) {
	  if (commonjsGlobal.Buffer && commonjsGlobal.Buffer.isBuffer(str)) {
	    str = str.toString('utf8');
	  }
	  const parser = new TOMLParser();
	  try {
	    parser.parse(str);
	    return parser.finish()
	  } catch (err) {
	    throw prettyError(err, str)
	  }
	}
	return parseString_1;
}

var parseAsync_1;
var hasRequiredParseAsync;

function requireParseAsync () {
	if (hasRequiredParseAsync) return parseAsync_1;
	hasRequiredParseAsync = 1;
	parseAsync_1 = parseAsync;

	const TOMLParser = requireTomlParser();
	const prettyError = requireParsePrettyError();

	function parseAsync (str, opts) {
	  if (!opts) opts = {};
	  const index = 0;
	  const blocksize = opts.blocksize || 40960;
	  const parser = new TOMLParser();
	  return new Promise((resolve, reject) => {
	    setImmediate(parseAsyncNext, index, blocksize, resolve, reject);
	  })
	  function parseAsyncNext (index, blocksize, resolve, reject) {
	    if (index >= str.length) {
	      try {
	        return resolve(parser.finish())
	      } catch (err) {
	        return reject(prettyError(err, str))
	      }
	    }
	    try {
	      parser.parse(str.slice(index, index + blocksize));
	      setImmediate(parseAsyncNext, index + blocksize, blocksize, resolve, reject);
	    } catch (err) {
	      reject(prettyError(err, str));
	    }
	  }
	}
	return parseAsync_1;
}

var domain;

// This constructor is used to store event handlers. Instantiating this is
// faster than explicitly calling `Object.create(null)` to get a "clean" empty
// object (tested with v8 v4.9).
function EventHandlers() {}
EventHandlers.prototype = Object.create(null);

function EventEmitter() {
  EventEmitter.init.call(this);
}

// nodejs oddity
// require('events') === require('events').EventEmitter
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.usingDomains = false;

EventEmitter.prototype.domain = undefined;
EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

EventEmitter.init = function() {
  this.domain = null;
  if (EventEmitter.usingDomains) {
    // if there is an active domain, then attach to it.
    if (domain.active && !(this instanceof domain.Domain)) {
      this.domain = domain.active;
    }
  }

  if (!this._events || this._events === Object.getPrototypeOf(this)._events) {
    this._events = new EventHandlers();
    this._eventsCount = 0;
  }

  this._maxListeners = this._maxListeners || undefined;
};

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function setMaxListeners(n) {
  if (typeof n !== 'number' || n < 0 || isNaN(n))
    throw new TypeError('"n" argument must be a positive number');
  this._maxListeners = n;
  return this;
};

function $getMaxListeners(that) {
  if (that._maxListeners === undefined)
    return EventEmitter.defaultMaxListeners;
  return that._maxListeners;
}

EventEmitter.prototype.getMaxListeners = function getMaxListeners() {
  return $getMaxListeners(this);
};

// These standalone emit* functions are used to optimize calling of event
// handlers for fast cases because emit() itself often has a variable number of
// arguments and can be deoptimized because of that. These functions always have
// the same number of arguments and thus do not get deoptimized, so the code
// inside them can execute faster.
function emitNone(handler, isFn, self) {
  if (isFn)
    handler.call(self);
  else {
    var len = handler.length;
    var listeners = arrayClone(handler, len);
    for (var i = 0; i < len; ++i)
      listeners[i].call(self);
  }
}
function emitOne(handler, isFn, self, arg1) {
  if (isFn)
    handler.call(self, arg1);
  else {
    var len = handler.length;
    var listeners = arrayClone(handler, len);
    for (var i = 0; i < len; ++i)
      listeners[i].call(self, arg1);
  }
}
function emitTwo(handler, isFn, self, arg1, arg2) {
  if (isFn)
    handler.call(self, arg1, arg2);
  else {
    var len = handler.length;
    var listeners = arrayClone(handler, len);
    for (var i = 0; i < len; ++i)
      listeners[i].call(self, arg1, arg2);
  }
}
function emitThree(handler, isFn, self, arg1, arg2, arg3) {
  if (isFn)
    handler.call(self, arg1, arg2, arg3);
  else {
    var len = handler.length;
    var listeners = arrayClone(handler, len);
    for (var i = 0; i < len; ++i)
      listeners[i].call(self, arg1, arg2, arg3);
  }
}

function emitMany(handler, isFn, self, args) {
  if (isFn)
    handler.apply(self, args);
  else {
    var len = handler.length;
    var listeners = arrayClone(handler, len);
    for (var i = 0; i < len; ++i)
      listeners[i].apply(self, args);
  }
}

EventEmitter.prototype.emit = function emit(type) {
  var er, handler, len, args, i, events, domain;
  var doError = (type === 'error');

  events = this._events;
  if (events)
    doError = (doError && events.error == null);
  else if (!doError)
    return false;

  domain = this.domain;

  // If there is no 'error' event listener then throw.
  if (doError) {
    er = arguments[1];
    if (domain) {
      if (!er)
        er = new Error('Uncaught, unspecified "error" event');
      er.domainEmitter = this;
      er.domain = domain;
      er.domainThrown = false;
      domain.emit('error', er);
    } else if (er instanceof Error) {
      throw er; // Unhandled 'error' event
    } else {
      // At least give some kind of context to the user
      var err = new Error('Uncaught, unspecified "error" event. (' + er + ')');
      err.context = er;
      throw err;
    }
    return false;
  }

  handler = events[type];

  if (!handler)
    return false;

  var isFn = typeof handler === 'function';
  len = arguments.length;
  switch (len) {
    // fast cases
    case 1:
      emitNone(handler, isFn, this);
      break;
    case 2:
      emitOne(handler, isFn, this, arguments[1]);
      break;
    case 3:
      emitTwo(handler, isFn, this, arguments[1], arguments[2]);
      break;
    case 4:
      emitThree(handler, isFn, this, arguments[1], arguments[2], arguments[3]);
      break;
    // slower
    default:
      args = new Array(len - 1);
      for (i = 1; i < len; i++)
        args[i - 1] = arguments[i];
      emitMany(handler, isFn, this, args);
  }

  return true;
};

function _addListener(target, type, listener, prepend) {
  var m;
  var events;
  var existing;

  if (typeof listener !== 'function')
    throw new TypeError('"listener" argument must be a function');

  events = target._events;
  if (!events) {
    events = target._events = new EventHandlers();
    target._eventsCount = 0;
  } else {
    // To avoid recursion in the case that type === "newListener"! Before
    // adding it to the listeners, first emit "newListener".
    if (events.newListener) {
      target.emit('newListener', type,
                  listener.listener ? listener.listener : listener);

      // Re-assign `events` because a newListener handler could have caused the
      // this._events to be assigned to a new object
      events = target._events;
    }
    existing = events[type];
  }

  if (!existing) {
    // Optimize the case of one listener. Don't need the extra array object.
    existing = events[type] = listener;
    ++target._eventsCount;
  } else {
    if (typeof existing === 'function') {
      // Adding the second element, need to change to array.
      existing = events[type] = prepend ? [listener, existing] :
                                          [existing, listener];
    } else {
      // If we've already got an array, just append.
      if (prepend) {
        existing.unshift(listener);
      } else {
        existing.push(listener);
      }
    }

    // Check for listener leak
    if (!existing.warned) {
      m = $getMaxListeners(target);
      if (m && m > 0 && existing.length > m) {
        existing.warned = true;
        var w = new Error('Possible EventEmitter memory leak detected. ' +
                            existing.length + ' ' + type + ' listeners added. ' +
                            'Use emitter.setMaxListeners() to increase limit');
        w.name = 'MaxListenersExceededWarning';
        w.emitter = target;
        w.type = type;
        w.count = existing.length;
        emitWarning(w);
      }
    }
  }

  return target;
}
function emitWarning(e) {
  typeof console.warn === 'function' ? console.warn(e) : console.log(e);
}
EventEmitter.prototype.addListener = function addListener(type, listener) {
  return _addListener(this, type, listener, false);
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.prependListener =
    function prependListener(type, listener) {
      return _addListener(this, type, listener, true);
    };

function _onceWrap(target, type, listener) {
  var fired = false;
  function g() {
    target.removeListener(type, g);
    if (!fired) {
      fired = true;
      listener.apply(target, arguments);
    }
  }
  g.listener = listener;
  return g;
}

EventEmitter.prototype.once = function once(type, listener) {
  if (typeof listener !== 'function')
    throw new TypeError('"listener" argument must be a function');
  this.on(type, _onceWrap(this, type, listener));
  return this;
};

EventEmitter.prototype.prependOnceListener =
    function prependOnceListener(type, listener) {
      if (typeof listener !== 'function')
        throw new TypeError('"listener" argument must be a function');
      this.prependListener(type, _onceWrap(this, type, listener));
      return this;
    };

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener =
    function removeListener(type, listener) {
      var list, events, position, i, originalListener;

      if (typeof listener !== 'function')
        throw new TypeError('"listener" argument must be a function');

      events = this._events;
      if (!events)
        return this;

      list = events[type];
      if (!list)
        return this;

      if (list === listener || (list.listener && list.listener === listener)) {
        if (--this._eventsCount === 0)
          this._events = new EventHandlers();
        else {
          delete events[type];
          if (events.removeListener)
            this.emit('removeListener', type, list.listener || listener);
        }
      } else if (typeof list !== 'function') {
        position = -1;

        for (i = list.length; i-- > 0;) {
          if (list[i] === listener ||
              (list[i].listener && list[i].listener === listener)) {
            originalListener = list[i].listener;
            position = i;
            break;
          }
        }

        if (position < 0)
          return this;

        if (list.length === 1) {
          list[0] = undefined;
          if (--this._eventsCount === 0) {
            this._events = new EventHandlers();
            return this;
          } else {
            delete events[type];
          }
        } else {
          spliceOne(list, position);
        }

        if (events.removeListener)
          this.emit('removeListener', type, originalListener || listener);
      }

      return this;
    };

EventEmitter.prototype.removeAllListeners =
    function removeAllListeners(type) {
      var listeners, events;

      events = this._events;
      if (!events)
        return this;

      // not listening for removeListener, no need to emit
      if (!events.removeListener) {
        if (arguments.length === 0) {
          this._events = new EventHandlers();
          this._eventsCount = 0;
        } else if (events[type]) {
          if (--this._eventsCount === 0)
            this._events = new EventHandlers();
          else
            delete events[type];
        }
        return this;
      }

      // emit removeListener for all listeners on all events
      if (arguments.length === 0) {
        var keys = Object.keys(events);
        for (var i = 0, key; i < keys.length; ++i) {
          key = keys[i];
          if (key === 'removeListener') continue;
          this.removeAllListeners(key);
        }
        this.removeAllListeners('removeListener');
        this._events = new EventHandlers();
        this._eventsCount = 0;
        return this;
      }

      listeners = events[type];

      if (typeof listeners === 'function') {
        this.removeListener(type, listeners);
      } else if (listeners) {
        // LIFO order
        do {
          this.removeListener(type, listeners[listeners.length - 1]);
        } while (listeners[0]);
      }

      return this;
    };

EventEmitter.prototype.listeners = function listeners(type) {
  var evlistener;
  var ret;
  var events = this._events;

  if (!events)
    ret = [];
  else {
    evlistener = events[type];
    if (!evlistener)
      ret = [];
    else if (typeof evlistener === 'function')
      ret = [evlistener.listener || evlistener];
    else
      ret = unwrapListeners(evlistener);
  }

  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  if (typeof emitter.listenerCount === 'function') {
    return emitter.listenerCount(type);
  } else {
    return listenerCount$1.call(emitter, type);
  }
};

EventEmitter.prototype.listenerCount = listenerCount$1;
function listenerCount$1(type) {
  var events = this._events;

  if (events) {
    var evlistener = events[type];

    if (typeof evlistener === 'function') {
      return 1;
    } else if (evlistener) {
      return evlistener.length;
    }
  }

  return 0;
}

EventEmitter.prototype.eventNames = function eventNames() {
  return this._eventsCount > 0 ? Reflect.ownKeys(this._events) : [];
};

// About 1.5x faster than the two-arg version of Array#splice().
function spliceOne(list, index) {
  for (var i = index, k = i + 1, n = list.length; k < n; i += 1, k += 1)
    list[i] = list[k];
  list.pop();
}

function arrayClone(arr, i) {
  var copy = new Array(i);
  while (i--)
    copy[i] = arr[i];
  return copy;
}

function unwrapListeners(arr) {
  var ret = new Array(arr.length);
  for (var i = 0; i < ret.length; ++i) {
    ret[i] = arr[i].listener || arr[i];
  }
  return ret;
}

var global$1 = (typeof global !== "undefined" ? global :
  typeof self !== "undefined" ? self :
  typeof window !== "undefined" ? window : {});

var lookup = [];
var revLookup = [];
var Arr = typeof Uint8Array !== 'undefined' ? Uint8Array : Array;
var inited = false;
function init () {
  inited = true;
  var code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  for (var i = 0, len = code.length; i < len; ++i) {
    lookup[i] = code[i];
    revLookup[code.charCodeAt(i)] = i;
  }

  revLookup['-'.charCodeAt(0)] = 62;
  revLookup['_'.charCodeAt(0)] = 63;
}

function toByteArray (b64) {
  if (!inited) {
    init();
  }
  var i, j, l, tmp, placeHolders, arr;
  var len = b64.length;

  if (len % 4 > 0) {
    throw new Error('Invalid string. Length must be a multiple of 4')
  }

  // the number of equal signs (place holders)
  // if there are two placeholders, than the two characters before it
  // represent one byte
  // if there is only one, then the three characters before it represent 2 bytes
  // this is just a cheap hack to not do indexOf twice
  placeHolders = b64[len - 2] === '=' ? 2 : b64[len - 1] === '=' ? 1 : 0;

  // base64 is 4/3 + up to two characters of the original data
  arr = new Arr(len * 3 / 4 - placeHolders);

  // if there are placeholders, only get up to the last complete 4 chars
  l = placeHolders > 0 ? len - 4 : len;

  var L = 0;

  for (i = 0, j = 0; i < l; i += 4, j += 3) {
    tmp = (revLookup[b64.charCodeAt(i)] << 18) | (revLookup[b64.charCodeAt(i + 1)] << 12) | (revLookup[b64.charCodeAt(i + 2)] << 6) | revLookup[b64.charCodeAt(i + 3)];
    arr[L++] = (tmp >> 16) & 0xFF;
    arr[L++] = (tmp >> 8) & 0xFF;
    arr[L++] = tmp & 0xFF;
  }

  if (placeHolders === 2) {
    tmp = (revLookup[b64.charCodeAt(i)] << 2) | (revLookup[b64.charCodeAt(i + 1)] >> 4);
    arr[L++] = tmp & 0xFF;
  } else if (placeHolders === 1) {
    tmp = (revLookup[b64.charCodeAt(i)] << 10) | (revLookup[b64.charCodeAt(i + 1)] << 4) | (revLookup[b64.charCodeAt(i + 2)] >> 2);
    arr[L++] = (tmp >> 8) & 0xFF;
    arr[L++] = tmp & 0xFF;
  }

  return arr
}

function tripletToBase64 (num) {
  return lookup[num >> 18 & 0x3F] + lookup[num >> 12 & 0x3F] + lookup[num >> 6 & 0x3F] + lookup[num & 0x3F]
}

function encodeChunk (uint8, start, end) {
  var tmp;
  var output = [];
  for (var i = start; i < end; i += 3) {
    tmp = (uint8[i] << 16) + (uint8[i + 1] << 8) + (uint8[i + 2]);
    output.push(tripletToBase64(tmp));
  }
  return output.join('')
}

function fromByteArray (uint8) {
  if (!inited) {
    init();
  }
  var tmp;
  var len = uint8.length;
  var extraBytes = len % 3; // if we have 1 byte left, pad 2 bytes
  var output = '';
  var parts = [];
  var maxChunkLength = 16383; // must be multiple of 3

  // go through the array every three bytes, we'll deal with trailing stuff later
  for (var i = 0, len2 = len - extraBytes; i < len2; i += maxChunkLength) {
    parts.push(encodeChunk(uint8, i, (i + maxChunkLength) > len2 ? len2 : (i + maxChunkLength)));
  }

  // pad the end with zeros, but make sure to not forget the extra bytes
  if (extraBytes === 1) {
    tmp = uint8[len - 1];
    output += lookup[tmp >> 2];
    output += lookup[(tmp << 4) & 0x3F];
    output += '==';
  } else if (extraBytes === 2) {
    tmp = (uint8[len - 2] << 8) + (uint8[len - 1]);
    output += lookup[tmp >> 10];
    output += lookup[(tmp >> 4) & 0x3F];
    output += lookup[(tmp << 2) & 0x3F];
    output += '=';
  }

  parts.push(output);

  return parts.join('')
}

function read (buffer, offset, isLE, mLen, nBytes) {
  var e, m;
  var eLen = nBytes * 8 - mLen - 1;
  var eMax = (1 << eLen) - 1;
  var eBias = eMax >> 1;
  var nBits = -7;
  var i = isLE ? (nBytes - 1) : 0;
  var d = isLE ? -1 : 1;
  var s = buffer[offset + i];

  i += d;

  e = s & ((1 << (-nBits)) - 1);
  s >>= (-nBits);
  nBits += eLen;
  for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  m = e & ((1 << (-nBits)) - 1);
  e >>= (-nBits);
  nBits += mLen;
  for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  if (e === 0) {
    e = 1 - eBias;
  } else if (e === eMax) {
    return m ? NaN : ((s ? -1 : 1) * Infinity)
  } else {
    m = m + Math.pow(2, mLen);
    e = e - eBias;
  }
  return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
}

function write (buffer, value, offset, isLE, mLen, nBytes) {
  var e, m, c;
  var eLen = nBytes * 8 - mLen - 1;
  var eMax = (1 << eLen) - 1;
  var eBias = eMax >> 1;
  var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0);
  var i = isLE ? 0 : (nBytes - 1);
  var d = isLE ? 1 : -1;
  var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0;

  value = Math.abs(value);

  if (isNaN(value) || value === Infinity) {
    m = isNaN(value) ? 1 : 0;
    e = eMax;
  } else {
    e = Math.floor(Math.log(value) / Math.LN2);
    if (value * (c = Math.pow(2, -e)) < 1) {
      e--;
      c *= 2;
    }
    if (e + eBias >= 1) {
      value += rt / c;
    } else {
      value += rt * Math.pow(2, 1 - eBias);
    }
    if (value * c >= 2) {
      e++;
      c /= 2;
    }

    if (e + eBias >= eMax) {
      m = 0;
      e = eMax;
    } else if (e + eBias >= 1) {
      m = (value * c - 1) * Math.pow(2, mLen);
      e = e + eBias;
    } else {
      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen);
      e = 0;
    }
  }

  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}

  e = (e << mLen) | m;
  eLen += mLen;
  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}

  buffer[offset + i - d] |= s * 128;
}

var toString = {}.toString;

var isArray$1 = Array.isArray || function (arr) {
  return toString.call(arr) == '[object Array]';
};

/*!
 * The buffer module from node.js, for the browser.
 *
 * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>
 * @license  MIT
 */

var INSPECT_MAX_BYTES = 50;

/**
 * If `Buffer.TYPED_ARRAY_SUPPORT`:
 *   === true    Use Uint8Array implementation (fastest)
 *   === false   Use Object implementation (most compatible, even IE6)
 *
 * Browsers that support typed arrays are IE 10+, Firefox 4+, Chrome 7+, Safari 5.1+,
 * Opera 11.6+, iOS 4.2+.
 *
 * Due to various browser bugs, sometimes the Object implementation will be used even
 * when the browser supports typed arrays.
 *
 * Note:
 *
 *   - Firefox 4-29 lacks support for adding new properties to `Uint8Array` instances,
 *     See: https://bugzilla.mozilla.org/show_bug.cgi?id=695438.
 *
 *   - Chrome 9-10 is missing the `TypedArray.prototype.subarray` function.
 *
 *   - IE10 has a broken `TypedArray.prototype.subarray` function which returns arrays of
 *     incorrect length in some situations.

 * We detect these buggy browsers and set `Buffer.TYPED_ARRAY_SUPPORT` to `false` so they
 * get the Object implementation, which is slower but behaves correctly.
 */
Buffer.TYPED_ARRAY_SUPPORT = global$1.TYPED_ARRAY_SUPPORT !== undefined
  ? global$1.TYPED_ARRAY_SUPPORT
  : true;

/*
 * Export kMaxLength after typed array support is determined.
 */
kMaxLength();

function kMaxLength () {
  return Buffer.TYPED_ARRAY_SUPPORT
    ? 0x7fffffff
    : 0x3fffffff
}

function createBuffer (that, length) {
  if (kMaxLength() < length) {
    throw new RangeError('Invalid typed array length')
  }
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    // Return an augmented `Uint8Array` instance, for best performance
    that = new Uint8Array(length);
    that.__proto__ = Buffer.prototype;
  } else {
    // Fallback: Return an object instance of the Buffer class
    if (that === null) {
      that = new Buffer(length);
    }
    that.length = length;
  }

  return that
}

/**
 * The Buffer constructor returns instances of `Uint8Array` that have their
 * prototype changed to `Buffer.prototype`. Furthermore, `Buffer` is a subclass of
 * `Uint8Array`, so the returned instances will have all the node `Buffer` methods
 * and the `Uint8Array` methods. Square bracket notation works as expected -- it
 * returns a single octet.
 *
 * The `Uint8Array` prototype remains unmodified.
 */

function Buffer (arg, encodingOrOffset, length) {
  if (!Buffer.TYPED_ARRAY_SUPPORT && !(this instanceof Buffer)) {
    return new Buffer(arg, encodingOrOffset, length)
  }

  // Common case.
  if (typeof arg === 'number') {
    if (typeof encodingOrOffset === 'string') {
      throw new Error(
        'If encoding is specified then the first argument must be a string'
      )
    }
    return allocUnsafe(this, arg)
  }
  return from(this, arg, encodingOrOffset, length)
}

Buffer.poolSize = 8192; // not used by this implementation

// TODO: Legacy, not needed anymore. Remove in next major version.
Buffer._augment = function (arr) {
  arr.__proto__ = Buffer.prototype;
  return arr
};

function from (that, value, encodingOrOffset, length) {
  if (typeof value === 'number') {
    throw new TypeError('"value" argument must not be a number')
  }

  if (typeof ArrayBuffer !== 'undefined' && value instanceof ArrayBuffer) {
    return fromArrayBuffer(that, value, encodingOrOffset, length)
  }

  if (typeof value === 'string') {
    return fromString(that, value, encodingOrOffset)
  }

  return fromObject(that, value)
}

/**
 * Functionally equivalent to Buffer(arg, encoding) but throws a TypeError
 * if value is a number.
 * Buffer.from(str[, encoding])
 * Buffer.from(array)
 * Buffer.from(buffer)
 * Buffer.from(arrayBuffer[, byteOffset[, length]])
 **/
Buffer.from = function (value, encodingOrOffset, length) {
  return from(null, value, encodingOrOffset, length)
};

if (Buffer.TYPED_ARRAY_SUPPORT) {
  Buffer.prototype.__proto__ = Uint8Array.prototype;
  Buffer.__proto__ = Uint8Array;
}

function assertSize (size) {
  if (typeof size !== 'number') {
    throw new TypeError('"size" argument must be a number')
  } else if (size < 0) {
    throw new RangeError('"size" argument must not be negative')
  }
}

function alloc (that, size, fill, encoding) {
  assertSize(size);
  if (size <= 0) {
    return createBuffer(that, size)
  }
  if (fill !== undefined) {
    // Only pay attention to encoding if it's a string. This
    // prevents accidentally sending in a number that would
    // be interpretted as a start offset.
    return typeof encoding === 'string'
      ? createBuffer(that, size).fill(fill, encoding)
      : createBuffer(that, size).fill(fill)
  }
  return createBuffer(that, size)
}

/**
 * Creates a new filled Buffer instance.
 * alloc(size[, fill[, encoding]])
 **/
Buffer.alloc = function (size, fill, encoding) {
  return alloc(null, size, fill, encoding)
};

function allocUnsafe (that, size) {
  assertSize(size);
  that = createBuffer(that, size < 0 ? 0 : checked(size) | 0);
  if (!Buffer.TYPED_ARRAY_SUPPORT) {
    for (var i = 0; i < size; ++i) {
      that[i] = 0;
    }
  }
  return that
}

/**
 * Equivalent to Buffer(num), by default creates a non-zero-filled Buffer instance.
 * */
Buffer.allocUnsafe = function (size) {
  return allocUnsafe(null, size)
};
/**
 * Equivalent to SlowBuffer(num), by default creates a non-zero-filled Buffer instance.
 */
Buffer.allocUnsafeSlow = function (size) {
  return allocUnsafe(null, size)
};

function fromString (that, string, encoding) {
  if (typeof encoding !== 'string' || encoding === '') {
    encoding = 'utf8';
  }

  if (!Buffer.isEncoding(encoding)) {
    throw new TypeError('"encoding" must be a valid string encoding')
  }

  var length = byteLength(string, encoding) | 0;
  that = createBuffer(that, length);

  var actual = that.write(string, encoding);

  if (actual !== length) {
    // Writing a hex string, for example, that contains invalid characters will
    // cause everything after the first invalid character to be ignored. (e.g.
    // 'abxxcd' will be treated as 'ab')
    that = that.slice(0, actual);
  }

  return that
}

function fromArrayLike (that, array) {
  var length = array.length < 0 ? 0 : checked(array.length) | 0;
  that = createBuffer(that, length);
  for (var i = 0; i < length; i += 1) {
    that[i] = array[i] & 255;
  }
  return that
}

function fromArrayBuffer (that, array, byteOffset, length) {
  array.byteLength; // this throws if `array` is not a valid ArrayBuffer

  if (byteOffset < 0 || array.byteLength < byteOffset) {
    throw new RangeError('\'offset\' is out of bounds')
  }

  if (array.byteLength < byteOffset + (length || 0)) {
    throw new RangeError('\'length\' is out of bounds')
  }

  if (byteOffset === undefined && length === undefined) {
    array = new Uint8Array(array);
  } else if (length === undefined) {
    array = new Uint8Array(array, byteOffset);
  } else {
    array = new Uint8Array(array, byteOffset, length);
  }

  if (Buffer.TYPED_ARRAY_SUPPORT) {
    // Return an augmented `Uint8Array` instance, for best performance
    that = array;
    that.__proto__ = Buffer.prototype;
  } else {
    // Fallback: Return an object instance of the Buffer class
    that = fromArrayLike(that, array);
  }
  return that
}

function fromObject (that, obj) {
  if (internalIsBuffer(obj)) {
    var len = checked(obj.length) | 0;
    that = createBuffer(that, len);

    if (that.length === 0) {
      return that
    }

    obj.copy(that, 0, 0, len);
    return that
  }

  if (obj) {
    if ((typeof ArrayBuffer !== 'undefined' &&
        obj.buffer instanceof ArrayBuffer) || 'length' in obj) {
      if (typeof obj.length !== 'number' || isnan(obj.length)) {
        return createBuffer(that, 0)
      }
      return fromArrayLike(that, obj)
    }

    if (obj.type === 'Buffer' && isArray$1(obj.data)) {
      return fromArrayLike(that, obj.data)
    }
  }

  throw new TypeError('First argument must be a string, Buffer, ArrayBuffer, Array, or array-like object.')
}

function checked (length) {
  // Note: cannot use `length < kMaxLength()` here because that fails when
  // length is NaN (which is otherwise coerced to zero.)
  if (length >= kMaxLength()) {
    throw new RangeError('Attempt to allocate Buffer larger than maximum ' +
                         'size: 0x' + kMaxLength().toString(16) + ' bytes')
  }
  return length | 0
}
Buffer.isBuffer = isBuffer;
function internalIsBuffer (b) {
  return !!(b != null && b._isBuffer)
}

Buffer.compare = function compare (a, b) {
  if (!internalIsBuffer(a) || !internalIsBuffer(b)) {
    throw new TypeError('Arguments must be Buffers')
  }

  if (a === b) return 0

  var x = a.length;
  var y = b.length;

  for (var i = 0, len = Math.min(x, y); i < len; ++i) {
    if (a[i] !== b[i]) {
      x = a[i];
      y = b[i];
      break
    }
  }

  if (x < y) return -1
  if (y < x) return 1
  return 0
};

Buffer.isEncoding = function isEncoding (encoding) {
  switch (String(encoding).toLowerCase()) {
    case 'hex':
    case 'utf8':
    case 'utf-8':
    case 'ascii':
    case 'latin1':
    case 'binary':
    case 'base64':
    case 'ucs2':
    case 'ucs-2':
    case 'utf16le':
    case 'utf-16le':
      return true
    default:
      return false
  }
};

Buffer.concat = function concat (list, length) {
  if (!isArray$1(list)) {
    throw new TypeError('"list" argument must be an Array of Buffers')
  }

  if (list.length === 0) {
    return Buffer.alloc(0)
  }

  var i;
  if (length === undefined) {
    length = 0;
    for (i = 0; i < list.length; ++i) {
      length += list[i].length;
    }
  }

  var buffer = Buffer.allocUnsafe(length);
  var pos = 0;
  for (i = 0; i < list.length; ++i) {
    var buf = list[i];
    if (!internalIsBuffer(buf)) {
      throw new TypeError('"list" argument must be an Array of Buffers')
    }
    buf.copy(buffer, pos);
    pos += buf.length;
  }
  return buffer
};

function byteLength (string, encoding) {
  if (internalIsBuffer(string)) {
    return string.length
  }
  if (typeof ArrayBuffer !== 'undefined' && typeof ArrayBuffer.isView === 'function' &&
      (ArrayBuffer.isView(string) || string instanceof ArrayBuffer)) {
    return string.byteLength
  }
  if (typeof string !== 'string') {
    string = '' + string;
  }

  var len = string.length;
  if (len === 0) return 0

  // Use a for loop to avoid recursion
  var loweredCase = false;
  for (;;) {
    switch (encoding) {
      case 'ascii':
      case 'latin1':
      case 'binary':
        return len
      case 'utf8':
      case 'utf-8':
      case undefined:
        return utf8ToBytes(string).length
      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return len * 2
      case 'hex':
        return len >>> 1
      case 'base64':
        return base64ToBytes(string).length
      default:
        if (loweredCase) return utf8ToBytes(string).length // assume utf8
        encoding = ('' + encoding).toLowerCase();
        loweredCase = true;
    }
  }
}
Buffer.byteLength = byteLength;

function slowToString (encoding, start, end) {
  var loweredCase = false;

  // No need to verify that "this.length <= MAX_UINT32" since it's a read-only
  // property of a typed array.

  // This behaves neither like String nor Uint8Array in that we set start/end
  // to their upper/lower bounds if the value passed is out of range.
  // undefined is handled specially as per ECMA-262 6th Edition,
  // Section 13.3.3.7 Runtime Semantics: KeyedBindingInitialization.
  if (start === undefined || start < 0) {
    start = 0;
  }
  // Return early if start > this.length. Done here to prevent potential uint32
  // coercion fail below.
  if (start > this.length) {
    return ''
  }

  if (end === undefined || end > this.length) {
    end = this.length;
  }

  if (end <= 0) {
    return ''
  }

  // Force coersion to uint32. This will also coerce falsey/NaN values to 0.
  end >>>= 0;
  start >>>= 0;

  if (end <= start) {
    return ''
  }

  if (!encoding) encoding = 'utf8';

  while (true) {
    switch (encoding) {
      case 'hex':
        return hexSlice(this, start, end)

      case 'utf8':
      case 'utf-8':
        return utf8Slice(this, start, end)

      case 'ascii':
        return asciiSlice(this, start, end)

      case 'latin1':
      case 'binary':
        return latin1Slice(this, start, end)

      case 'base64':
        return base64Slice(this, start, end)

      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return utf16leSlice(this, start, end)

      default:
        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
        encoding = (encoding + '').toLowerCase();
        loweredCase = true;
    }
  }
}

// The property is used by `Buffer.isBuffer` and `is-buffer` (in Safari 5-7) to detect
// Buffer instances.
Buffer.prototype._isBuffer = true;

function swap (b, n, m) {
  var i = b[n];
  b[n] = b[m];
  b[m] = i;
}

Buffer.prototype.swap16 = function swap16 () {
  var len = this.length;
  if (len % 2 !== 0) {
    throw new RangeError('Buffer size must be a multiple of 16-bits')
  }
  for (var i = 0; i < len; i += 2) {
    swap(this, i, i + 1);
  }
  return this
};

Buffer.prototype.swap32 = function swap32 () {
  var len = this.length;
  if (len % 4 !== 0) {
    throw new RangeError('Buffer size must be a multiple of 32-bits')
  }
  for (var i = 0; i < len; i += 4) {
    swap(this, i, i + 3);
    swap(this, i + 1, i + 2);
  }
  return this
};

Buffer.prototype.swap64 = function swap64 () {
  var len = this.length;
  if (len % 8 !== 0) {
    throw new RangeError('Buffer size must be a multiple of 64-bits')
  }
  for (var i = 0; i < len; i += 8) {
    swap(this, i, i + 7);
    swap(this, i + 1, i + 6);
    swap(this, i + 2, i + 5);
    swap(this, i + 3, i + 4);
  }
  return this
};

Buffer.prototype.toString = function toString () {
  var length = this.length | 0;
  if (length === 0) return ''
  if (arguments.length === 0) return utf8Slice(this, 0, length)
  return slowToString.apply(this, arguments)
};

Buffer.prototype.equals = function equals (b) {
  if (!internalIsBuffer(b)) throw new TypeError('Argument must be a Buffer')
  if (this === b) return true
  return Buffer.compare(this, b) === 0
};

Buffer.prototype.inspect = function inspect () {
  var str = '';
  var max = INSPECT_MAX_BYTES;
  if (this.length > 0) {
    str = this.toString('hex', 0, max).match(/.{2}/g).join(' ');
    if (this.length > max) str += ' ... ';
  }
  return '<Buffer ' + str + '>'
};

Buffer.prototype.compare = function compare (target, start, end, thisStart, thisEnd) {
  if (!internalIsBuffer(target)) {
    throw new TypeError('Argument must be a Buffer')
  }

  if (start === undefined) {
    start = 0;
  }
  if (end === undefined) {
    end = target ? target.length : 0;
  }
  if (thisStart === undefined) {
    thisStart = 0;
  }
  if (thisEnd === undefined) {
    thisEnd = this.length;
  }

  if (start < 0 || end > target.length || thisStart < 0 || thisEnd > this.length) {
    throw new RangeError('out of range index')
  }

  if (thisStart >= thisEnd && start >= end) {
    return 0
  }
  if (thisStart >= thisEnd) {
    return -1
  }
  if (start >= end) {
    return 1
  }

  start >>>= 0;
  end >>>= 0;
  thisStart >>>= 0;
  thisEnd >>>= 0;

  if (this === target) return 0

  var x = thisEnd - thisStart;
  var y = end - start;
  var len = Math.min(x, y);

  var thisCopy = this.slice(thisStart, thisEnd);
  var targetCopy = target.slice(start, end);

  for (var i = 0; i < len; ++i) {
    if (thisCopy[i] !== targetCopy[i]) {
      x = thisCopy[i];
      y = targetCopy[i];
      break
    }
  }

  if (x < y) return -1
  if (y < x) return 1
  return 0
};

// Finds either the first index of `val` in `buffer` at offset >= `byteOffset`,
// OR the last index of `val` in `buffer` at offset <= `byteOffset`.
//
// Arguments:
// - buffer - a Buffer to search
// - val - a string, Buffer, or number
// - byteOffset - an index into `buffer`; will be clamped to an int32
// - encoding - an optional encoding, relevant is val is a string
// - dir - true for indexOf, false for lastIndexOf
function bidirectionalIndexOf (buffer, val, byteOffset, encoding, dir) {
  // Empty buffer means no match
  if (buffer.length === 0) return -1

  // Normalize byteOffset
  if (typeof byteOffset === 'string') {
    encoding = byteOffset;
    byteOffset = 0;
  } else if (byteOffset > 0x7fffffff) {
    byteOffset = 0x7fffffff;
  } else if (byteOffset < -2147483648) {
    byteOffset = -2147483648;
  }
  byteOffset = +byteOffset;  // Coerce to Number.
  if (isNaN(byteOffset)) {
    // byteOffset: it it's undefined, null, NaN, "foo", etc, search whole buffer
    byteOffset = dir ? 0 : (buffer.length - 1);
  }

  // Normalize byteOffset: negative offsets start from the end of the buffer
  if (byteOffset < 0) byteOffset = buffer.length + byteOffset;
  if (byteOffset >= buffer.length) {
    if (dir) return -1
    else byteOffset = buffer.length - 1;
  } else if (byteOffset < 0) {
    if (dir) byteOffset = 0;
    else return -1
  }

  // Normalize val
  if (typeof val === 'string') {
    val = Buffer.from(val, encoding);
  }

  // Finally, search either indexOf (if dir is true) or lastIndexOf
  if (internalIsBuffer(val)) {
    // Special case: looking for empty string/buffer always fails
    if (val.length === 0) {
      return -1
    }
    return arrayIndexOf(buffer, val, byteOffset, encoding, dir)
  } else if (typeof val === 'number') {
    val = val & 0xFF; // Search for a byte value [0-255]
    if (Buffer.TYPED_ARRAY_SUPPORT &&
        typeof Uint8Array.prototype.indexOf === 'function') {
      if (dir) {
        return Uint8Array.prototype.indexOf.call(buffer, val, byteOffset)
      } else {
        return Uint8Array.prototype.lastIndexOf.call(buffer, val, byteOffset)
      }
    }
    return arrayIndexOf(buffer, [ val ], byteOffset, encoding, dir)
  }

  throw new TypeError('val must be string, number or Buffer')
}

function arrayIndexOf (arr, val, byteOffset, encoding, dir) {
  var indexSize = 1;
  var arrLength = arr.length;
  var valLength = val.length;

  if (encoding !== undefined) {
    encoding = String(encoding).toLowerCase();
    if (encoding === 'ucs2' || encoding === 'ucs-2' ||
        encoding === 'utf16le' || encoding === 'utf-16le') {
      if (arr.length < 2 || val.length < 2) {
        return -1
      }
      indexSize = 2;
      arrLength /= 2;
      valLength /= 2;
      byteOffset /= 2;
    }
  }

  function read (buf, i) {
    if (indexSize === 1) {
      return buf[i]
    } else {
      return buf.readUInt16BE(i * indexSize)
    }
  }

  var i;
  if (dir) {
    var foundIndex = -1;
    for (i = byteOffset; i < arrLength; i++) {
      if (read(arr, i) === read(val, foundIndex === -1 ? 0 : i - foundIndex)) {
        if (foundIndex === -1) foundIndex = i;
        if (i - foundIndex + 1 === valLength) return foundIndex * indexSize
      } else {
        if (foundIndex !== -1) i -= i - foundIndex;
        foundIndex = -1;
      }
    }
  } else {
    if (byteOffset + valLength > arrLength) byteOffset = arrLength - valLength;
    for (i = byteOffset; i >= 0; i--) {
      var found = true;
      for (var j = 0; j < valLength; j++) {
        if (read(arr, i + j) !== read(val, j)) {
          found = false;
          break
        }
      }
      if (found) return i
    }
  }

  return -1
}

Buffer.prototype.includes = function includes (val, byteOffset, encoding) {
  return this.indexOf(val, byteOffset, encoding) !== -1
};

Buffer.prototype.indexOf = function indexOf (val, byteOffset, encoding) {
  return bidirectionalIndexOf(this, val, byteOffset, encoding, true)
};

Buffer.prototype.lastIndexOf = function lastIndexOf (val, byteOffset, encoding) {
  return bidirectionalIndexOf(this, val, byteOffset, encoding, false)
};

function hexWrite (buf, string, offset, length) {
  offset = Number(offset) || 0;
  var remaining = buf.length - offset;
  if (!length) {
    length = remaining;
  } else {
    length = Number(length);
    if (length > remaining) {
      length = remaining;
    }
  }

  // must be an even number of digits
  var strLen = string.length;
  if (strLen % 2 !== 0) throw new TypeError('Invalid hex string')

  if (length > strLen / 2) {
    length = strLen / 2;
  }
  for (var i = 0; i < length; ++i) {
    var parsed = parseInt(string.substr(i * 2, 2), 16);
    if (isNaN(parsed)) return i
    buf[offset + i] = parsed;
  }
  return i
}

function utf8Write (buf, string, offset, length) {
  return blitBuffer(utf8ToBytes(string, buf.length - offset), buf, offset, length)
}

function asciiWrite (buf, string, offset, length) {
  return blitBuffer(asciiToBytes(string), buf, offset, length)
}

function latin1Write (buf, string, offset, length) {
  return asciiWrite(buf, string, offset, length)
}

function base64Write (buf, string, offset, length) {
  return blitBuffer(base64ToBytes(string), buf, offset, length)
}

function ucs2Write (buf, string, offset, length) {
  return blitBuffer(utf16leToBytes(string, buf.length - offset), buf, offset, length)
}

Buffer.prototype.write = function write (string, offset, length, encoding) {
  // Buffer#write(string)
  if (offset === undefined) {
    encoding = 'utf8';
    length = this.length;
    offset = 0;
  // Buffer#write(string, encoding)
  } else if (length === undefined && typeof offset === 'string') {
    encoding = offset;
    length = this.length;
    offset = 0;
  // Buffer#write(string, offset[, length][, encoding])
  } else if (isFinite(offset)) {
    offset = offset | 0;
    if (isFinite(length)) {
      length = length | 0;
      if (encoding === undefined) encoding = 'utf8';
    } else {
      encoding = length;
      length = undefined;
    }
  // legacy write(string, encoding, offset, length) - remove in v0.13
  } else {
    throw new Error(
      'Buffer.write(string, encoding, offset[, length]) is no longer supported'
    )
  }

  var remaining = this.length - offset;
  if (length === undefined || length > remaining) length = remaining;

  if ((string.length > 0 && (length < 0 || offset < 0)) || offset > this.length) {
    throw new RangeError('Attempt to write outside buffer bounds')
  }

  if (!encoding) encoding = 'utf8';

  var loweredCase = false;
  for (;;) {
    switch (encoding) {
      case 'hex':
        return hexWrite(this, string, offset, length)

      case 'utf8':
      case 'utf-8':
        return utf8Write(this, string, offset, length)

      case 'ascii':
        return asciiWrite(this, string, offset, length)

      case 'latin1':
      case 'binary':
        return latin1Write(this, string, offset, length)

      case 'base64':
        // Warning: maxLength not taken into account in base64Write
        return base64Write(this, string, offset, length)

      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return ucs2Write(this, string, offset, length)

      default:
        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
        encoding = ('' + encoding).toLowerCase();
        loweredCase = true;
    }
  }
};

Buffer.prototype.toJSON = function toJSON () {
  return {
    type: 'Buffer',
    data: Array.prototype.slice.call(this._arr || this, 0)
  }
};

function base64Slice (buf, start, end) {
  if (start === 0 && end === buf.length) {
    return fromByteArray(buf)
  } else {
    return fromByteArray(buf.slice(start, end))
  }
}

function utf8Slice (buf, start, end) {
  end = Math.min(buf.length, end);
  var res = [];

  var i = start;
  while (i < end) {
    var firstByte = buf[i];
    var codePoint = null;
    var bytesPerSequence = (firstByte > 0xEF) ? 4
      : (firstByte > 0xDF) ? 3
      : (firstByte > 0xBF) ? 2
      : 1;

    if (i + bytesPerSequence <= end) {
      var secondByte, thirdByte, fourthByte, tempCodePoint;

      switch (bytesPerSequence) {
        case 1:
          if (firstByte < 0x80) {
            codePoint = firstByte;
          }
          break
        case 2:
          secondByte = buf[i + 1];
          if ((secondByte & 0xC0) === 0x80) {
            tempCodePoint = (firstByte & 0x1F) << 0x6 | (secondByte & 0x3F);
            if (tempCodePoint > 0x7F) {
              codePoint = tempCodePoint;
            }
          }
          break
        case 3:
          secondByte = buf[i + 1];
          thirdByte = buf[i + 2];
          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80) {
            tempCodePoint = (firstByte & 0xF) << 0xC | (secondByte & 0x3F) << 0x6 | (thirdByte & 0x3F);
            if (tempCodePoint > 0x7FF && (tempCodePoint < 0xD800 || tempCodePoint > 0xDFFF)) {
              codePoint = tempCodePoint;
            }
          }
          break
        case 4:
          secondByte = buf[i + 1];
          thirdByte = buf[i + 2];
          fourthByte = buf[i + 3];
          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80 && (fourthByte & 0xC0) === 0x80) {
            tempCodePoint = (firstByte & 0xF) << 0x12 | (secondByte & 0x3F) << 0xC | (thirdByte & 0x3F) << 0x6 | (fourthByte & 0x3F);
            if (tempCodePoint > 0xFFFF && tempCodePoint < 0x110000) {
              codePoint = tempCodePoint;
            }
          }
      }
    }

    if (codePoint === null) {
      // we did not generate a valid codePoint so insert a
      // replacement char (U+FFFD) and advance only 1 byte
      codePoint = 0xFFFD;
      bytesPerSequence = 1;
    } else if (codePoint > 0xFFFF) {
      // encode to utf16 (surrogate pair dance)
      codePoint -= 0x10000;
      res.push(codePoint >>> 10 & 0x3FF | 0xD800);
      codePoint = 0xDC00 | codePoint & 0x3FF;
    }

    res.push(codePoint);
    i += bytesPerSequence;
  }

  return decodeCodePointsArray(res)
}

// Based on http://stackoverflow.com/a/22747272/680742, the browser with
// the lowest limit is Chrome, with 0x10000 args.
// We go 1 magnitude less, for safety
var MAX_ARGUMENTS_LENGTH = 0x1000;

function decodeCodePointsArray (codePoints) {
  var len = codePoints.length;
  if (len <= MAX_ARGUMENTS_LENGTH) {
    return String.fromCharCode.apply(String, codePoints) // avoid extra slice()
  }

  // Decode in chunks to avoid "call stack size exceeded".
  var res = '';
  var i = 0;
  while (i < len) {
    res += String.fromCharCode.apply(
      String,
      codePoints.slice(i, i += MAX_ARGUMENTS_LENGTH)
    );
  }
  return res
}

function asciiSlice (buf, start, end) {
  var ret = '';
  end = Math.min(buf.length, end);

  for (var i = start; i < end; ++i) {
    ret += String.fromCharCode(buf[i] & 0x7F);
  }
  return ret
}

function latin1Slice (buf, start, end) {
  var ret = '';
  end = Math.min(buf.length, end);

  for (var i = start; i < end; ++i) {
    ret += String.fromCharCode(buf[i]);
  }
  return ret
}

function hexSlice (buf, start, end) {
  var len = buf.length;

  if (!start || start < 0) start = 0;
  if (!end || end < 0 || end > len) end = len;

  var out = '';
  for (var i = start; i < end; ++i) {
    out += toHex(buf[i]);
  }
  return out
}

function utf16leSlice (buf, start, end) {
  var bytes = buf.slice(start, end);
  var res = '';
  for (var i = 0; i < bytes.length; i += 2) {
    res += String.fromCharCode(bytes[i] + bytes[i + 1] * 256);
  }
  return res
}

Buffer.prototype.slice = function slice (start, end) {
  var len = this.length;
  start = ~~start;
  end = end === undefined ? len : ~~end;

  if (start < 0) {
    start += len;
    if (start < 0) start = 0;
  } else if (start > len) {
    start = len;
  }

  if (end < 0) {
    end += len;
    if (end < 0) end = 0;
  } else if (end > len) {
    end = len;
  }

  if (end < start) end = start;

  var newBuf;
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    newBuf = this.subarray(start, end);
    newBuf.__proto__ = Buffer.prototype;
  } else {
    var sliceLen = end - start;
    newBuf = new Buffer(sliceLen, undefined);
    for (var i = 0; i < sliceLen; ++i) {
      newBuf[i] = this[i + start];
    }
  }

  return newBuf
};

/*
 * Need to make sure that buffer isn't trying to write out of bounds.
 */
function checkOffset (offset, ext, length) {
  if ((offset % 1) !== 0 || offset < 0) throw new RangeError('offset is not uint')
  if (offset + ext > length) throw new RangeError('Trying to access beyond buffer length')
}

Buffer.prototype.readUIntLE = function readUIntLE (offset, byteLength, noAssert) {
  offset = offset | 0;
  byteLength = byteLength | 0;
  if (!noAssert) checkOffset(offset, byteLength, this.length);

  var val = this[offset];
  var mul = 1;
  var i = 0;
  while (++i < byteLength && (mul *= 0x100)) {
    val += this[offset + i] * mul;
  }

  return val
};

Buffer.prototype.readUIntBE = function readUIntBE (offset, byteLength, noAssert) {
  offset = offset | 0;
  byteLength = byteLength | 0;
  if (!noAssert) {
    checkOffset(offset, byteLength, this.length);
  }

  var val = this[offset + --byteLength];
  var mul = 1;
  while (byteLength > 0 && (mul *= 0x100)) {
    val += this[offset + --byteLength] * mul;
  }

  return val
};

Buffer.prototype.readUInt8 = function readUInt8 (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 1, this.length);
  return this[offset]
};

Buffer.prototype.readUInt16LE = function readUInt16LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length);
  return this[offset] | (this[offset + 1] << 8)
};

Buffer.prototype.readUInt16BE = function readUInt16BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length);
  return (this[offset] << 8) | this[offset + 1]
};

Buffer.prototype.readUInt32LE = function readUInt32LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length);

  return ((this[offset]) |
      (this[offset + 1] << 8) |
      (this[offset + 2] << 16)) +
      (this[offset + 3] * 0x1000000)
};

Buffer.prototype.readUInt32BE = function readUInt32BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length);

  return (this[offset] * 0x1000000) +
    ((this[offset + 1] << 16) |
    (this[offset + 2] << 8) |
    this[offset + 3])
};

Buffer.prototype.readIntLE = function readIntLE (offset, byteLength, noAssert) {
  offset = offset | 0;
  byteLength = byteLength | 0;
  if (!noAssert) checkOffset(offset, byteLength, this.length);

  var val = this[offset];
  var mul = 1;
  var i = 0;
  while (++i < byteLength && (mul *= 0x100)) {
    val += this[offset + i] * mul;
  }
  mul *= 0x80;

  if (val >= mul) val -= Math.pow(2, 8 * byteLength);

  return val
};

Buffer.prototype.readIntBE = function readIntBE (offset, byteLength, noAssert) {
  offset = offset | 0;
  byteLength = byteLength | 0;
  if (!noAssert) checkOffset(offset, byteLength, this.length);

  var i = byteLength;
  var mul = 1;
  var val = this[offset + --i];
  while (i > 0 && (mul *= 0x100)) {
    val += this[offset + --i] * mul;
  }
  mul *= 0x80;

  if (val >= mul) val -= Math.pow(2, 8 * byteLength);

  return val
};

Buffer.prototype.readInt8 = function readInt8 (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 1, this.length);
  if (!(this[offset] & 0x80)) return (this[offset])
  return ((0xff - this[offset] + 1) * -1)
};

Buffer.prototype.readInt16LE = function readInt16LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length);
  var val = this[offset] | (this[offset + 1] << 8);
  return (val & 0x8000) ? val | 0xFFFF0000 : val
};

Buffer.prototype.readInt16BE = function readInt16BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length);
  var val = this[offset + 1] | (this[offset] << 8);
  return (val & 0x8000) ? val | 0xFFFF0000 : val
};

Buffer.prototype.readInt32LE = function readInt32LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length);

  return (this[offset]) |
    (this[offset + 1] << 8) |
    (this[offset + 2] << 16) |
    (this[offset + 3] << 24)
};

Buffer.prototype.readInt32BE = function readInt32BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length);

  return (this[offset] << 24) |
    (this[offset + 1] << 16) |
    (this[offset + 2] << 8) |
    (this[offset + 3])
};

Buffer.prototype.readFloatLE = function readFloatLE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length);
  return read(this, offset, true, 23, 4)
};

Buffer.prototype.readFloatBE = function readFloatBE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length);
  return read(this, offset, false, 23, 4)
};

Buffer.prototype.readDoubleLE = function readDoubleLE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 8, this.length);
  return read(this, offset, true, 52, 8)
};

Buffer.prototype.readDoubleBE = function readDoubleBE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 8, this.length);
  return read(this, offset, false, 52, 8)
};

function checkInt (buf, value, offset, ext, max, min) {
  if (!internalIsBuffer(buf)) throw new TypeError('"buffer" argument must be a Buffer instance')
  if (value > max || value < min) throw new RangeError('"value" argument is out of bounds')
  if (offset + ext > buf.length) throw new RangeError('Index out of range')
}

Buffer.prototype.writeUIntLE = function writeUIntLE (value, offset, byteLength, noAssert) {
  value = +value;
  offset = offset | 0;
  byteLength = byteLength | 0;
  if (!noAssert) {
    var maxBytes = Math.pow(2, 8 * byteLength) - 1;
    checkInt(this, value, offset, byteLength, maxBytes, 0);
  }

  var mul = 1;
  var i = 0;
  this[offset] = value & 0xFF;
  while (++i < byteLength && (mul *= 0x100)) {
    this[offset + i] = (value / mul) & 0xFF;
  }

  return offset + byteLength
};

Buffer.prototype.writeUIntBE = function writeUIntBE (value, offset, byteLength, noAssert) {
  value = +value;
  offset = offset | 0;
  byteLength = byteLength | 0;
  if (!noAssert) {
    var maxBytes = Math.pow(2, 8 * byteLength) - 1;
    checkInt(this, value, offset, byteLength, maxBytes, 0);
  }

  var i = byteLength - 1;
  var mul = 1;
  this[offset + i] = value & 0xFF;
  while (--i >= 0 && (mul *= 0x100)) {
    this[offset + i] = (value / mul) & 0xFF;
  }

  return offset + byteLength
};

Buffer.prototype.writeUInt8 = function writeUInt8 (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 1, 0xff, 0);
  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value);
  this[offset] = (value & 0xff);
  return offset + 1
};

function objectWriteUInt16 (buf, value, offset, littleEndian) {
  if (value < 0) value = 0xffff + value + 1;
  for (var i = 0, j = Math.min(buf.length - offset, 2); i < j; ++i) {
    buf[offset + i] = (value & (0xff << (8 * (littleEndian ? i : 1 - i)))) >>>
      (littleEndian ? i : 1 - i) * 8;
  }
}

Buffer.prototype.writeUInt16LE = function writeUInt16LE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value & 0xff);
    this[offset + 1] = (value >>> 8);
  } else {
    objectWriteUInt16(this, value, offset, true);
  }
  return offset + 2
};

Buffer.prototype.writeUInt16BE = function writeUInt16BE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 8);
    this[offset + 1] = (value & 0xff);
  } else {
    objectWriteUInt16(this, value, offset, false);
  }
  return offset + 2
};

function objectWriteUInt32 (buf, value, offset, littleEndian) {
  if (value < 0) value = 0xffffffff + value + 1;
  for (var i = 0, j = Math.min(buf.length - offset, 4); i < j; ++i) {
    buf[offset + i] = (value >>> (littleEndian ? i : 3 - i) * 8) & 0xff;
  }
}

Buffer.prototype.writeUInt32LE = function writeUInt32LE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset + 3] = (value >>> 24);
    this[offset + 2] = (value >>> 16);
    this[offset + 1] = (value >>> 8);
    this[offset] = (value & 0xff);
  } else {
    objectWriteUInt32(this, value, offset, true);
  }
  return offset + 4
};

Buffer.prototype.writeUInt32BE = function writeUInt32BE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 24);
    this[offset + 1] = (value >>> 16);
    this[offset + 2] = (value >>> 8);
    this[offset + 3] = (value & 0xff);
  } else {
    objectWriteUInt32(this, value, offset, false);
  }
  return offset + 4
};

Buffer.prototype.writeIntLE = function writeIntLE (value, offset, byteLength, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) {
    var limit = Math.pow(2, 8 * byteLength - 1);

    checkInt(this, value, offset, byteLength, limit - 1, -limit);
  }

  var i = 0;
  var mul = 1;
  var sub = 0;
  this[offset] = value & 0xFF;
  while (++i < byteLength && (mul *= 0x100)) {
    if (value < 0 && sub === 0 && this[offset + i - 1] !== 0) {
      sub = 1;
    }
    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF;
  }

  return offset + byteLength
};

Buffer.prototype.writeIntBE = function writeIntBE (value, offset, byteLength, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) {
    var limit = Math.pow(2, 8 * byteLength - 1);

    checkInt(this, value, offset, byteLength, limit - 1, -limit);
  }

  var i = byteLength - 1;
  var mul = 1;
  var sub = 0;
  this[offset + i] = value & 0xFF;
  while (--i >= 0 && (mul *= 0x100)) {
    if (value < 0 && sub === 0 && this[offset + i + 1] !== 0) {
      sub = 1;
    }
    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF;
  }

  return offset + byteLength
};

Buffer.prototype.writeInt8 = function writeInt8 (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 1, 0x7f, -128);
  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value);
  if (value < 0) value = 0xff + value + 1;
  this[offset] = (value & 0xff);
  return offset + 1
};

Buffer.prototype.writeInt16LE = function writeInt16LE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -32768);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value & 0xff);
    this[offset + 1] = (value >>> 8);
  } else {
    objectWriteUInt16(this, value, offset, true);
  }
  return offset + 2
};

Buffer.prototype.writeInt16BE = function writeInt16BE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -32768);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 8);
    this[offset + 1] = (value & 0xff);
  } else {
    objectWriteUInt16(this, value, offset, false);
  }
  return offset + 2
};

Buffer.prototype.writeInt32LE = function writeInt32LE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -2147483648);
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value & 0xff);
    this[offset + 1] = (value >>> 8);
    this[offset + 2] = (value >>> 16);
    this[offset + 3] = (value >>> 24);
  } else {
    objectWriteUInt32(this, value, offset, true);
  }
  return offset + 4
};

Buffer.prototype.writeInt32BE = function writeInt32BE (value, offset, noAssert) {
  value = +value;
  offset = offset | 0;
  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -2147483648);
  if (value < 0) value = 0xffffffff + value + 1;
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 24);
    this[offset + 1] = (value >>> 16);
    this[offset + 2] = (value >>> 8);
    this[offset + 3] = (value & 0xff);
  } else {
    objectWriteUInt32(this, value, offset, false);
  }
  return offset + 4
};

function checkIEEE754 (buf, value, offset, ext, max, min) {
  if (offset + ext > buf.length) throw new RangeError('Index out of range')
  if (offset < 0) throw new RangeError('Index out of range')
}

function writeFloat (buf, value, offset, littleEndian, noAssert) {
  if (!noAssert) {
    checkIEEE754(buf, value, offset, 4);
  }
  write(buf, value, offset, littleEndian, 23, 4);
  return offset + 4
}

Buffer.prototype.writeFloatLE = function writeFloatLE (value, offset, noAssert) {
  return writeFloat(this, value, offset, true, noAssert)
};

Buffer.prototype.writeFloatBE = function writeFloatBE (value, offset, noAssert) {
  return writeFloat(this, value, offset, false, noAssert)
};

function writeDouble (buf, value, offset, littleEndian, noAssert) {
  if (!noAssert) {
    checkIEEE754(buf, value, offset, 8);
  }
  write(buf, value, offset, littleEndian, 52, 8);
  return offset + 8
}

Buffer.prototype.writeDoubleLE = function writeDoubleLE (value, offset, noAssert) {
  return writeDouble(this, value, offset, true, noAssert)
};

Buffer.prototype.writeDoubleBE = function writeDoubleBE (value, offset, noAssert) {
  return writeDouble(this, value, offset, false, noAssert)
};

// copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
Buffer.prototype.copy = function copy (target, targetStart, start, end) {
  if (!start) start = 0;
  if (!end && end !== 0) end = this.length;
  if (targetStart >= target.length) targetStart = target.length;
  if (!targetStart) targetStart = 0;
  if (end > 0 && end < start) end = start;

  // Copy 0 bytes; we're done
  if (end === start) return 0
  if (target.length === 0 || this.length === 0) return 0

  // Fatal error conditions
  if (targetStart < 0) {
    throw new RangeError('targetStart out of bounds')
  }
  if (start < 0 || start >= this.length) throw new RangeError('sourceStart out of bounds')
  if (end < 0) throw new RangeError('sourceEnd out of bounds')

  // Are we oob?
  if (end > this.length) end = this.length;
  if (target.length - targetStart < end - start) {
    end = target.length - targetStart + start;
  }

  var len = end - start;
  var i;

  if (this === target && start < targetStart && targetStart < end) {
    // descending copy from end
    for (i = len - 1; i >= 0; --i) {
      target[i + targetStart] = this[i + start];
    }
  } else if (len < 1000 || !Buffer.TYPED_ARRAY_SUPPORT) {
    // ascending copy from start
    for (i = 0; i < len; ++i) {
      target[i + targetStart] = this[i + start];
    }
  } else {
    Uint8Array.prototype.set.call(
      target,
      this.subarray(start, start + len),
      targetStart
    );
  }

  return len
};

// Usage:
//    buffer.fill(number[, offset[, end]])
//    buffer.fill(buffer[, offset[, end]])
//    buffer.fill(string[, offset[, end]][, encoding])
Buffer.prototype.fill = function fill (val, start, end, encoding) {
  // Handle string cases:
  if (typeof val === 'string') {
    if (typeof start === 'string') {
      encoding = start;
      start = 0;
      end = this.length;
    } else if (typeof end === 'string') {
      encoding = end;
      end = this.length;
    }
    if (val.length === 1) {
      var code = val.charCodeAt(0);
      if (code < 256) {
        val = code;
      }
    }
    if (encoding !== undefined && typeof encoding !== 'string') {
      throw new TypeError('encoding must be a string')
    }
    if (typeof encoding === 'string' && !Buffer.isEncoding(encoding)) {
      throw new TypeError('Unknown encoding: ' + encoding)
    }
  } else if (typeof val === 'number') {
    val = val & 255;
  }

  // Invalid ranges are not set to a default, so can range check early.
  if (start < 0 || this.length < start || this.length < end) {
    throw new RangeError('Out of range index')
  }

  if (end <= start) {
    return this
  }

  start = start >>> 0;
  end = end === undefined ? this.length : end >>> 0;

  if (!val) val = 0;

  var i;
  if (typeof val === 'number') {
    for (i = start; i < end; ++i) {
      this[i] = val;
    }
  } else {
    var bytes = internalIsBuffer(val)
      ? val
      : utf8ToBytes(new Buffer(val, encoding).toString());
    var len = bytes.length;
    for (i = 0; i < end - start; ++i) {
      this[i + start] = bytes[i % len];
    }
  }

  return this
};

// HELPER FUNCTIONS
// ================

var INVALID_BASE64_RE = /[^+\/0-9A-Za-z-_]/g;

function base64clean (str) {
  // Node strips out invalid characters like \n and \t from the string, base64-js does not
  str = stringtrim(str).replace(INVALID_BASE64_RE, '');
  // Node converts strings with length < 2 to ''
  if (str.length < 2) return ''
  // Node allows for non-padded base64 strings (missing trailing ===), base64-js does not
  while (str.length % 4 !== 0) {
    str = str + '=';
  }
  return str
}

function stringtrim (str) {
  if (str.trim) return str.trim()
  return str.replace(/^\s+|\s+$/g, '')
}

function toHex (n) {
  if (n < 16) return '0' + n.toString(16)
  return n.toString(16)
}

function utf8ToBytes (string, units) {
  units = units || Infinity;
  var codePoint;
  var length = string.length;
  var leadSurrogate = null;
  var bytes = [];

  for (var i = 0; i < length; ++i) {
    codePoint = string.charCodeAt(i);

    // is surrogate component
    if (codePoint > 0xD7FF && codePoint < 0xE000) {
      // last char was a lead
      if (!leadSurrogate) {
        // no lead yet
        if (codePoint > 0xDBFF) {
          // unexpected trail
          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD);
          continue
        } else if (i + 1 === length) {
          // unpaired lead
          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD);
          continue
        }

        // valid lead
        leadSurrogate = codePoint;

        continue
      }

      // 2 leads in a row
      if (codePoint < 0xDC00) {
        if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD);
        leadSurrogate = codePoint;
        continue
      }

      // valid surrogate pair
      codePoint = (leadSurrogate - 0xD800 << 10 | codePoint - 0xDC00) + 0x10000;
    } else if (leadSurrogate) {
      // valid bmp char, but last char was a lead
      if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD);
    }

    leadSurrogate = null;

    // encode utf8
    if (codePoint < 0x80) {
      if ((units -= 1) < 0) break
      bytes.push(codePoint);
    } else if (codePoint < 0x800) {
      if ((units -= 2) < 0) break
      bytes.push(
        codePoint >> 0x6 | 0xC0,
        codePoint & 0x3F | 0x80
      );
    } else if (codePoint < 0x10000) {
      if ((units -= 3) < 0) break
      bytes.push(
        codePoint >> 0xC | 0xE0,
        codePoint >> 0x6 & 0x3F | 0x80,
        codePoint & 0x3F | 0x80
      );
    } else if (codePoint < 0x110000) {
      if ((units -= 4) < 0) break
      bytes.push(
        codePoint >> 0x12 | 0xF0,
        codePoint >> 0xC & 0x3F | 0x80,
        codePoint >> 0x6 & 0x3F | 0x80,
        codePoint & 0x3F | 0x80
      );
    } else {
      throw new Error('Invalid code point')
    }
  }

  return bytes
}

function asciiToBytes (str) {
  var byteArray = [];
  for (var i = 0; i < str.length; ++i) {
    // Node's code seems to be doing this and not & 0x7F..
    byteArray.push(str.charCodeAt(i) & 0xFF);
  }
  return byteArray
}

function utf16leToBytes (str, units) {
  var c, hi, lo;
  var byteArray = [];
  for (var i = 0; i < str.length; ++i) {
    if ((units -= 2) < 0) break

    c = str.charCodeAt(i);
    hi = c >> 8;
    lo = c % 256;
    byteArray.push(lo);
    byteArray.push(hi);
  }

  return byteArray
}


function base64ToBytes (str) {
  return toByteArray(base64clean(str))
}

function blitBuffer (src, dst, offset, length) {
  for (var i = 0; i < length; ++i) {
    if ((i + offset >= dst.length) || (i >= src.length)) break
    dst[i + offset] = src[i];
  }
  return i
}

function isnan (val) {
  return val !== val // eslint-disable-line no-self-compare
}


// the following is from is-buffer, also by Feross Aboukhadijeh and with same lisence
// The _isBuffer check is for Safari 5-7 support, because it's missing
// Object.prototype.constructor. Remove this eventually
function isBuffer(obj) {
  return obj != null && (!!obj._isBuffer || isFastBuffer(obj) || isSlowBuffer(obj))
}

function isFastBuffer (obj) {
  return !!obj.constructor && typeof obj.constructor.isBuffer === 'function' && obj.constructor.isBuffer(obj)
}

// For Node v0.10 support. Remove this eventually.
function isSlowBuffer (obj) {
  return typeof obj.readFloatLE === 'function' && typeof obj.slice === 'function' && isFastBuffer(obj.slice(0, 0))
}

// shim for using process in browser
// based off https://github.com/defunctzombie/node-process/blob/master/browser.js

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
var cachedSetTimeout = defaultSetTimout;
var cachedClearTimeout = defaultClearTimeout;
if (typeof global$1.setTimeout === 'function') {
    cachedSetTimeout = setTimeout;
}
if (typeof global$1.clearTimeout === 'function') {
    cachedClearTimeout = clearTimeout;
}

function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}
function nextTick(fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
}
// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
var env = {};

// from https://github.com/kumavis/browser-process-hrtime/blob/master/index.js
var performance = global$1.performance || {};
performance.now        ||
  performance.mozNow     ||
  performance.msNow      ||
  performance.oNow       ||
  performance.webkitNow  ||
  function(){ return (new Date()).getTime() };

var browser$1 = {
  env: env};

var inherits;
if (typeof Object.create === 'function'){
  inherits = function inherits(ctor, superCtor) {
    // implementation from standard node.js 'util' module
    ctor.super_ = superCtor;
    ctor.prototype = Object.create(superCtor.prototype, {
      constructor: {
        value: ctor,
        enumerable: false,
        writable: true,
        configurable: true
      }
    });
  };
} else {
  inherits = function inherits(ctor, superCtor) {
    ctor.super_ = superCtor;
    var TempCtor = function () {};
    TempCtor.prototype = superCtor.prototype;
    ctor.prototype = new TempCtor();
    ctor.prototype.constructor = ctor;
  };
}
var inherits$1 = inherits;

var formatRegExp = /%[sdj%]/g;
function format(f) {
  if (!isString(f)) {
    var objects = [];
    for (var i = 0; i < arguments.length; i++) {
      objects.push(inspect(arguments[i]));
    }
    return objects.join(' ');
  }

  var i = 1;
  var args = arguments;
  var len = args.length;
  var str = String(f).replace(formatRegExp, function(x) {
    if (x === '%%') return '%';
    if (i >= len) return x;
    switch (x) {
      case '%s': return String(args[i++]);
      case '%d': return Number(args[i++]);
      case '%j':
        try {
          return JSON.stringify(args[i++]);
        } catch (_) {
          return '[Circular]';
        }
      default:
        return x;
    }
  });
  for (var x = args[i]; i < len; x = args[++i]) {
    if (isNull(x) || !isObject(x)) {
      str += ' ' + x;
    } else {
      str += ' ' + inspect(x);
    }
  }
  return str;
}

// Mark that a method should not be used.
// Returns a modified function which warns once by default.
// If --no-deprecation is set, then it is a no-op.
function deprecate(fn, msg) {
  // Allow for deprecating things in the process of starting up.
  if (isUndefined(global$1.process)) {
    return function() {
      return deprecate(fn, msg).apply(this, arguments);
    };
  }

  if (browser$1.noDeprecation === true) {
    return fn;
  }

  var warned = false;
  function deprecated() {
    if (!warned) {
      if (browser$1.throwDeprecation) {
        throw new Error(msg);
      } else if (browser$1.traceDeprecation) {
        console.trace(msg);
      } else {
        console.error(msg);
      }
      warned = true;
    }
    return fn.apply(this, arguments);
  }

  return deprecated;
}

var debugs = {};
var debugEnviron;
function debuglog(set) {
  if (isUndefined(debugEnviron))
    debugEnviron = browser$1.env.NODE_DEBUG || '';
  set = set.toUpperCase();
  if (!debugs[set]) {
    if (new RegExp('\\b' + set + '\\b', 'i').test(debugEnviron)) {
      var pid = 0;
      debugs[set] = function() {
        var msg = format.apply(null, arguments);
        console.error('%s %d: %s', set, pid, msg);
      };
    } else {
      debugs[set] = function() {};
    }
  }
  return debugs[set];
}

/**
 * Echos the value of a value. Trys to print the value out
 * in the best way possible given the different types.
 *
 * @param {Object} obj The object to print out.
 * @param {Object} opts Optional options object that alters the output.
 */
/* legacy: obj, showHidden, depth, colors*/
function inspect(obj, opts) {
  // default options
  var ctx = {
    seen: [],
    stylize: stylizeNoColor
  };
  // legacy...
  if (arguments.length >= 3) ctx.depth = arguments[2];
  if (arguments.length >= 4) ctx.colors = arguments[3];
  if (isBoolean(opts)) {
    // legacy...
    ctx.showHidden = opts;
  } else if (opts) {
    // got an "options" object
    _extend(ctx, opts);
  }
  // set default options
  if (isUndefined(ctx.showHidden)) ctx.showHidden = false;
  if (isUndefined(ctx.depth)) ctx.depth = 2;
  if (isUndefined(ctx.colors)) ctx.colors = false;
  if (isUndefined(ctx.customInspect)) ctx.customInspect = true;
  if (ctx.colors) ctx.stylize = stylizeWithColor;
  return formatValue(ctx, obj, ctx.depth);
}

// http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
inspect.colors = {
  'bold' : [1, 22],
  'italic' : [3, 23],
  'underline' : [4, 24],
  'inverse' : [7, 27],
  'white' : [37, 39],
  'grey' : [90, 39],
  'black' : [30, 39],
  'blue' : [34, 39],
  'cyan' : [36, 39],
  'green' : [32, 39],
  'magenta' : [35, 39],
  'red' : [31, 39],
  'yellow' : [33, 39]
};

// Don't use 'blue' not visible on cmd.exe
inspect.styles = {
  'special': 'cyan',
  'number': 'yellow',
  'boolean': 'yellow',
  'undefined': 'grey',
  'null': 'bold',
  'string': 'green',
  'date': 'magenta',
  // "name": intentionally not styling
  'regexp': 'red'
};


function stylizeWithColor(str, styleType) {
  var style = inspect.styles[styleType];

  if (style) {
    return '\u001b[' + inspect.colors[style][0] + 'm' + str +
           '\u001b[' + inspect.colors[style][1] + 'm';
  } else {
    return str;
  }
}


function stylizeNoColor(str, styleType) {
  return str;
}


function arrayToHash(array) {
  var hash = {};

  array.forEach(function(val, idx) {
    hash[val] = true;
  });

  return hash;
}


function formatValue(ctx, value, recurseTimes) {
  // Provide a hook for user-specified inspect functions.
  // Check that value is an object with an inspect function on it
  if (ctx.customInspect &&
      value &&
      isFunction(value.inspect) &&
      // Filter out the util module, it's inspect function is special
      value.inspect !== inspect &&
      // Also filter out any prototype objects using the circular check.
      !(value.constructor && value.constructor.prototype === value)) {
    var ret = value.inspect(recurseTimes, ctx);
    if (!isString(ret)) {
      ret = formatValue(ctx, ret, recurseTimes);
    }
    return ret;
  }

  // Primitive types cannot have properties
  var primitive = formatPrimitive(ctx, value);
  if (primitive) {
    return primitive;
  }

  // Look up the keys of the object.
  var keys = Object.keys(value);
  var visibleKeys = arrayToHash(keys);

  if (ctx.showHidden) {
    keys = Object.getOwnPropertyNames(value);
  }

  // IE doesn't make error fields non-enumerable
  // http://msdn.microsoft.com/en-us/library/ie/dww52sbt(v=vs.94).aspx
  if (isError(value)
      && (keys.indexOf('message') >= 0 || keys.indexOf('description') >= 0)) {
    return formatError(value);
  }

  // Some type of object without properties can be shortcutted.
  if (keys.length === 0) {
    if (isFunction(value)) {
      var name = value.name ? ': ' + value.name : '';
      return ctx.stylize('[Function' + name + ']', 'special');
    }
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    }
    if (isDate(value)) {
      return ctx.stylize(Date.prototype.toString.call(value), 'date');
    }
    if (isError(value)) {
      return formatError(value);
    }
  }

  var base = '', array = false, braces = ['{', '}'];

  // Make Array say that they are Array
  if (isArray(value)) {
    array = true;
    braces = ['[', ']'];
  }

  // Make functions say that they are functions
  if (isFunction(value)) {
    var n = value.name ? ': ' + value.name : '';
    base = ' [Function' + n + ']';
  }

  // Make RegExps say that they are RegExps
  if (isRegExp(value)) {
    base = ' ' + RegExp.prototype.toString.call(value);
  }

  // Make dates with properties first say the date
  if (isDate(value)) {
    base = ' ' + Date.prototype.toUTCString.call(value);
  }

  // Make error with message first say the error
  if (isError(value)) {
    base = ' ' + formatError(value);
  }

  if (keys.length === 0 && (!array || value.length == 0)) {
    return braces[0] + base + braces[1];
  }

  if (recurseTimes < 0) {
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    } else {
      return ctx.stylize('[Object]', 'special');
    }
  }

  ctx.seen.push(value);

  var output;
  if (array) {
    output = formatArray(ctx, value, recurseTimes, visibleKeys, keys);
  } else {
    output = keys.map(function(key) {
      return formatProperty(ctx, value, recurseTimes, visibleKeys, key, array);
    });
  }

  ctx.seen.pop();

  return reduceToSingleString(output, base, braces);
}


function formatPrimitive(ctx, value) {
  if (isUndefined(value))
    return ctx.stylize('undefined', 'undefined');
  if (isString(value)) {
    var simple = '\'' + JSON.stringify(value).replace(/^"|"$/g, '')
                                             .replace(/'/g, "\\'")
                                             .replace(/\\"/g, '"') + '\'';
    return ctx.stylize(simple, 'string');
  }
  if (isNumber(value))
    return ctx.stylize('' + value, 'number');
  if (isBoolean(value))
    return ctx.stylize('' + value, 'boolean');
  // For some reason typeof null is "object", so special case here.
  if (isNull(value))
    return ctx.stylize('null', 'null');
}


function formatError(value) {
  return '[' + Error.prototype.toString.call(value) + ']';
}


function formatArray(ctx, value, recurseTimes, visibleKeys, keys) {
  var output = [];
  for (var i = 0, l = value.length; i < l; ++i) {
    if (hasOwnProperty(value, String(i))) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          String(i), true));
    } else {
      output.push('');
    }
  }
  keys.forEach(function(key) {
    if (!key.match(/^\d+$/)) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          key, true));
    }
  });
  return output;
}


function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
  var name, str, desc;
  desc = Object.getOwnPropertyDescriptor(value, key) || { value: value[key] };
  if (desc.get) {
    if (desc.set) {
      str = ctx.stylize('[Getter/Setter]', 'special');
    } else {
      str = ctx.stylize('[Getter]', 'special');
    }
  } else {
    if (desc.set) {
      str = ctx.stylize('[Setter]', 'special');
    }
  }
  if (!hasOwnProperty(visibleKeys, key)) {
    name = '[' + key + ']';
  }
  if (!str) {
    if (ctx.seen.indexOf(desc.value) < 0) {
      if (isNull(recurseTimes)) {
        str = formatValue(ctx, desc.value, null);
      } else {
        str = formatValue(ctx, desc.value, recurseTimes - 1);
      }
      if (str.indexOf('\n') > -1) {
        if (array) {
          str = str.split('\n').map(function(line) {
            return '  ' + line;
          }).join('\n').substr(2);
        } else {
          str = '\n' + str.split('\n').map(function(line) {
            return '   ' + line;
          }).join('\n');
        }
      }
    } else {
      str = ctx.stylize('[Circular]', 'special');
    }
  }
  if (isUndefined(name)) {
    if (array && key.match(/^\d+$/)) {
      return str;
    }
    name = JSON.stringify('' + key);
    if (name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)) {
      name = name.substr(1, name.length - 2);
      name = ctx.stylize(name, 'name');
    } else {
      name = name.replace(/'/g, "\\'")
                 .replace(/\\"/g, '"')
                 .replace(/(^"|"$)/g, "'");
      name = ctx.stylize(name, 'string');
    }
  }

  return name + ': ' + str;
}


function reduceToSingleString(output, base, braces) {
  var length = output.reduce(function(prev, cur) {
    if (cur.indexOf('\n') >= 0) ;
    return prev + cur.replace(/\u001b\[\d\d?m/g, '').length + 1;
  }, 0);

  if (length > 60) {
    return braces[0] +
           (base === '' ? '' : base + '\n ') +
           ' ' +
           output.join(',\n  ') +
           ' ' +
           braces[1];
  }

  return braces[0] + base + ' ' + output.join(', ') + ' ' + braces[1];
}


// NOTE: These type checking functions intentionally don't use `instanceof`
// because it is fragile and can be easily faked with `Object.create()`.
function isArray(ar) {
  return Array.isArray(ar);
}

function isBoolean(arg) {
  return typeof arg === 'boolean';
}

function isNull(arg) {
  return arg === null;
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isString(arg) {
  return typeof arg === 'string';
}

function isUndefined(arg) {
  return arg === void 0;
}

function isRegExp(re) {
  return isObject(re) && objectToString(re) === '[object RegExp]';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isDate(d) {
  return isObject(d) && objectToString(d) === '[object Date]';
}

function isError(e) {
  return isObject(e) &&
      (objectToString(e) === '[object Error]' || e instanceof Error);
}

function isFunction(arg) {
  return typeof arg === 'function';
}

function objectToString(o) {
  return Object.prototype.toString.call(o);
}

function _extend(origin, add) {
  // Don't do anything if add isn't an object
  if (!add || !isObject(add)) return origin;

  var keys = Object.keys(add);
  var i = keys.length;
  while (i--) {
    origin[keys[i]] = add[keys[i]];
  }
  return origin;
}
function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

function BufferList() {
  this.head = null;
  this.tail = null;
  this.length = 0;
}

BufferList.prototype.push = function (v) {
  var entry = { data: v, next: null };
  if (this.length > 0) this.tail.next = entry;else this.head = entry;
  this.tail = entry;
  ++this.length;
};

BufferList.prototype.unshift = function (v) {
  var entry = { data: v, next: this.head };
  if (this.length === 0) this.tail = entry;
  this.head = entry;
  ++this.length;
};

BufferList.prototype.shift = function () {
  if (this.length === 0) return;
  var ret = this.head.data;
  if (this.length === 1) this.head = this.tail = null;else this.head = this.head.next;
  --this.length;
  return ret;
};

BufferList.prototype.clear = function () {
  this.head = this.tail = null;
  this.length = 0;
};

BufferList.prototype.join = function (s) {
  if (this.length === 0) return '';
  var p = this.head;
  var ret = '' + p.data;
  while (p = p.next) {
    ret += s + p.data;
  }return ret;
};

BufferList.prototype.concat = function (n) {
  if (this.length === 0) return Buffer.alloc(0);
  if (this.length === 1) return this.head.data;
  var ret = Buffer.allocUnsafe(n >>> 0);
  var p = this.head;
  var i = 0;
  while (p) {
    p.data.copy(ret, i);
    i += p.data.length;
    p = p.next;
  }
  return ret;
};

// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var isBufferEncoding = Buffer.isEncoding
  || function(encoding) {
       switch (encoding && encoding.toLowerCase()) {
         case 'hex': case 'utf8': case 'utf-8': case 'ascii': case 'binary': case 'base64': case 'ucs2': case 'ucs-2': case 'utf16le': case 'utf-16le': case 'raw': return true;
         default: return false;
       }
     };


function assertEncoding(encoding) {
  if (encoding && !isBufferEncoding(encoding)) {
    throw new Error('Unknown encoding: ' + encoding);
  }
}

// StringDecoder provides an interface for efficiently splitting a series of
// buffers into a series of JS strings without breaking apart multi-byte
// characters. CESU-8 is handled as part of the UTF-8 encoding.
//
// @TODO Handling all encodings inside a single object makes it very difficult
// to reason about this code, so it should be split up in the future.
// @TODO There should be a utf8-strict encoding that rejects invalid UTF-8 code
// points as used by CESU-8.
function StringDecoder(encoding) {
  this.encoding = (encoding || 'utf8').toLowerCase().replace(/[-_]/, '');
  assertEncoding(encoding);
  switch (this.encoding) {
    case 'utf8':
      // CESU-8 represents each of Surrogate Pair by 3-bytes
      this.surrogateSize = 3;
      break;
    case 'ucs2':
    case 'utf16le':
      // UTF-16 represents each of Surrogate Pair by 2-bytes
      this.surrogateSize = 2;
      this.detectIncompleteChar = utf16DetectIncompleteChar;
      break;
    case 'base64':
      // Base-64 stores 3 bytes in 4 chars, and pads the remainder.
      this.surrogateSize = 3;
      this.detectIncompleteChar = base64DetectIncompleteChar;
      break;
    default:
      this.write = passThroughWrite;
      return;
  }

  // Enough space to store all bytes of a single character. UTF-8 needs 4
  // bytes, but CESU-8 may require up to 6 (3 bytes per surrogate).
  this.charBuffer = new Buffer(6);
  // Number of bytes received for the current incomplete multi-byte character.
  this.charReceived = 0;
  // Number of bytes expected for the current incomplete multi-byte character.
  this.charLength = 0;
}

// write decodes the given buffer and returns it as JS string that is
// guaranteed to not contain any partial multi-byte characters. Any partial
// character found at the end of the buffer is buffered up, and will be
// returned when calling write again with the remaining bytes.
//
// Note: Converting a Buffer containing an orphan surrogate to a String
// currently works, but converting a String to a Buffer (via `new Buffer`, or
// Buffer#write) will replace incomplete surrogates with the unicode
// replacement character. See https://codereview.chromium.org/121173009/ .
StringDecoder.prototype.write = function(buffer) {
  var charStr = '';
  // if our last write ended with an incomplete multibyte character
  while (this.charLength) {
    // determine how many remaining bytes this buffer has to offer for this char
    var available = (buffer.length >= this.charLength - this.charReceived) ?
        this.charLength - this.charReceived :
        buffer.length;

    // add the new bytes to the char buffer
    buffer.copy(this.charBuffer, this.charReceived, 0, available);
    this.charReceived += available;

    if (this.charReceived < this.charLength) {
      // still not enough chars in this buffer? wait for more ...
      return '';
    }

    // remove bytes belonging to the current character from the buffer
    buffer = buffer.slice(available, buffer.length);

    // get the character that was split
    charStr = this.charBuffer.slice(0, this.charLength).toString(this.encoding);

    // CESU-8: lead surrogate (D800-DBFF) is also the incomplete character
    var charCode = charStr.charCodeAt(charStr.length - 1);
    if (charCode >= 0xD800 && charCode <= 0xDBFF) {
      this.charLength += this.surrogateSize;
      charStr = '';
      continue;
    }
    this.charReceived = this.charLength = 0;

    // if there are no more bytes in this buffer, just emit our char
    if (buffer.length === 0) {
      return charStr;
    }
    break;
  }

  // determine and set charLength / charReceived
  this.detectIncompleteChar(buffer);

  var end = buffer.length;
  if (this.charLength) {
    // buffer the incomplete character bytes we got
    buffer.copy(this.charBuffer, 0, buffer.length - this.charReceived, end);
    end -= this.charReceived;
  }

  charStr += buffer.toString(this.encoding, 0, end);

  var end = charStr.length - 1;
  var charCode = charStr.charCodeAt(end);
  // CESU-8: lead surrogate (D800-DBFF) is also the incomplete character
  if (charCode >= 0xD800 && charCode <= 0xDBFF) {
    var size = this.surrogateSize;
    this.charLength += size;
    this.charReceived += size;
    this.charBuffer.copy(this.charBuffer, size, 0, size);
    buffer.copy(this.charBuffer, 0, 0, size);
    return charStr.substring(0, end);
  }

  // or just emit the charStr
  return charStr;
};

// detectIncompleteChar determines if there is an incomplete UTF-8 character at
// the end of the given buffer. If so, it sets this.charLength to the byte
// length that character, and sets this.charReceived to the number of bytes
// that are available for this character.
StringDecoder.prototype.detectIncompleteChar = function(buffer) {
  // determine how many bytes we have to check at the end of this buffer
  var i = (buffer.length >= 3) ? 3 : buffer.length;

  // Figure out if one of the last i bytes of our buffer announces an
  // incomplete char.
  for (; i > 0; i--) {
    var c = buffer[buffer.length - i];

    // See http://en.wikipedia.org/wiki/UTF-8#Description

    // 110XXXXX
    if (i == 1 && c >> 5 == 0x06) {
      this.charLength = 2;
      break;
    }

    // 1110XXXX
    if (i <= 2 && c >> 4 == 0x0E) {
      this.charLength = 3;
      break;
    }

    // 11110XXX
    if (i <= 3 && c >> 3 == 0x1E) {
      this.charLength = 4;
      break;
    }
  }
  this.charReceived = i;
};

StringDecoder.prototype.end = function(buffer) {
  var res = '';
  if (buffer && buffer.length)
    res = this.write(buffer);

  if (this.charReceived) {
    var cr = this.charReceived;
    var buf = this.charBuffer;
    var enc = this.encoding;
    res += buf.slice(0, cr).toString(enc);
  }

  return res;
};

function passThroughWrite(buffer) {
  return buffer.toString(this.encoding);
}

function utf16DetectIncompleteChar(buffer) {
  this.charReceived = buffer.length % 2;
  this.charLength = this.charReceived ? 2 : 0;
}

function base64DetectIncompleteChar(buffer) {
  this.charReceived = buffer.length % 3;
  this.charLength = this.charReceived ? 3 : 0;
}

Readable.ReadableState = ReadableState;

var debug = debuglog('stream');
inherits$1(Readable, EventEmitter);

function prependListener(emitter, event, fn) {
  // Sadly this is not cacheable as some libraries bundle their own
  // event emitter implementation with them.
  if (typeof emitter.prependListener === 'function') {
    return emitter.prependListener(event, fn);
  } else {
    // This is a hack to make sure that our error handler is attached before any
    // userland ones.  NEVER DO THIS. This is here only because this code needs
    // to continue to work with older versions of Node.js that do not include
    // the prependListener() method. The goal is to eventually remove this hack.
    if (!emitter._events || !emitter._events[event])
      emitter.on(event, fn);
    else if (Array.isArray(emitter._events[event]))
      emitter._events[event].unshift(fn);
    else
      emitter._events[event] = [fn, emitter._events[event]];
  }
}
function listenerCount (emitter, type) {
  return emitter.listeners(type).length;
}
function ReadableState(options, stream) {

  options = options || {};

  // object stream flag. Used to make read(n) ignore n and to
  // make all the buffer merging and length checks go away
  this.objectMode = !!options.objectMode;

  if (stream instanceof Duplex) this.objectMode = this.objectMode || !!options.readableObjectMode;

  // the point at which it stops calling _read() to fill the buffer
  // Note: 0 is a valid value, means "don't call _read preemptively ever"
  var hwm = options.highWaterMark;
  var defaultHwm = this.objectMode ? 16 : 16 * 1024;
  this.highWaterMark = hwm || hwm === 0 ? hwm : defaultHwm;

  // cast to ints.
  this.highWaterMark = ~ ~this.highWaterMark;

  // A linked list is used to store data chunks instead of an array because the
  // linked list can remove elements from the beginning faster than
  // array.shift()
  this.buffer = new BufferList();
  this.length = 0;
  this.pipes = null;
  this.pipesCount = 0;
  this.flowing = null;
  this.ended = false;
  this.endEmitted = false;
  this.reading = false;

  // a flag to be able to tell if the onwrite cb is called immediately,
  // or on a later tick.  We set this to true at first, because any
  // actions that shouldn't happen until "later" should generally also
  // not happen before the first write call.
  this.sync = true;

  // whenever we return null, then we set a flag to say
  // that we're awaiting a 'readable' event emission.
  this.needReadable = false;
  this.emittedReadable = false;
  this.readableListening = false;
  this.resumeScheduled = false;

  // Crypto is kind of old and crusty.  Historically, its default string
  // encoding is 'binary' so we have to make this configurable.
  // Everything else in the universe uses 'utf8', though.
  this.defaultEncoding = options.defaultEncoding || 'utf8';

  // when piping, we only care about 'readable' events that happen
  // after read()ing all the bytes and not getting any pushback.
  this.ranOut = false;

  // the number of writers that are awaiting a drain event in .pipe()s
  this.awaitDrain = 0;

  // if true, a maybeReadMore has been scheduled
  this.readingMore = false;

  this.decoder = null;
  this.encoding = null;
  if (options.encoding) {
    this.decoder = new StringDecoder(options.encoding);
    this.encoding = options.encoding;
  }
}
function Readable(options) {

  if (!(this instanceof Readable)) return new Readable(options);

  this._readableState = new ReadableState(options, this);

  // legacy
  this.readable = true;

  if (options && typeof options.read === 'function') this._read = options.read;

  EventEmitter.call(this);
}

// Manually shove something into the read() buffer.
// This returns true if the highWaterMark has not been hit yet,
// similar to how Writable.write() returns true if you should
// write() some more.
Readable.prototype.push = function (chunk, encoding) {
  var state = this._readableState;

  if (!state.objectMode && typeof chunk === 'string') {
    encoding = encoding || state.defaultEncoding;
    if (encoding !== state.encoding) {
      chunk = Buffer.from(chunk, encoding);
      encoding = '';
    }
  }

  return readableAddChunk(this, state, chunk, encoding, false);
};

// Unshift should *always* be something directly out of read()
Readable.prototype.unshift = function (chunk) {
  var state = this._readableState;
  return readableAddChunk(this, state, chunk, '', true);
};

Readable.prototype.isPaused = function () {
  return this._readableState.flowing === false;
};

function readableAddChunk(stream, state, chunk, encoding, addToFront) {
  var er = chunkInvalid(state, chunk);
  if (er) {
    stream.emit('error', er);
  } else if (chunk === null) {
    state.reading = false;
    onEofChunk(stream, state);
  } else if (state.objectMode || chunk && chunk.length > 0) {
    if (state.ended && !addToFront) {
      var e = new Error('stream.push() after EOF');
      stream.emit('error', e);
    } else if (state.endEmitted && addToFront) {
      var _e = new Error('stream.unshift() after end event');
      stream.emit('error', _e);
    } else {
      var skipAdd;
      if (state.decoder && !addToFront && !encoding) {
        chunk = state.decoder.write(chunk);
        skipAdd = !state.objectMode && chunk.length === 0;
      }

      if (!addToFront) state.reading = false;

      // Don't add to the buffer if we've decoded to an empty string chunk and
      // we're not in object mode
      if (!skipAdd) {
        // if we want the data now, just emit it.
        if (state.flowing && state.length === 0 && !state.sync) {
          stream.emit('data', chunk);
          stream.read(0);
        } else {
          // update the buffer info.
          state.length += state.objectMode ? 1 : chunk.length;
          if (addToFront) state.buffer.unshift(chunk);else state.buffer.push(chunk);

          if (state.needReadable) emitReadable(stream);
        }
      }

      maybeReadMore(stream, state);
    }
  } else if (!addToFront) {
    state.reading = false;
  }

  return needMoreData(state);
}

// if it's past the high water mark, we can push in some more.
// Also, if we have no data yet, we can stand some
// more bytes.  This is to work around cases where hwm=0,
// such as the repl.  Also, if the push() triggered a
// readable event, and the user called read(largeNumber) such that
// needReadable was set, then we ought to push more, so that another
// 'readable' event will be triggered.
function needMoreData(state) {
  return !state.ended && (state.needReadable || state.length < state.highWaterMark || state.length === 0);
}

// backwards compatibility.
Readable.prototype.setEncoding = function (enc) {
  this._readableState.decoder = new StringDecoder(enc);
  this._readableState.encoding = enc;
  return this;
};

// Don't raise the hwm > 8MB
var MAX_HWM = 0x800000;
function computeNewHighWaterMark(n) {
  if (n >= MAX_HWM) {
    n = MAX_HWM;
  } else {
    // Get the next highest power of 2 to prevent increasing hwm excessively in
    // tiny amounts
    n--;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    n++;
  }
  return n;
}

// This function is designed to be inlinable, so please take care when making
// changes to the function body.
function howMuchToRead(n, state) {
  if (n <= 0 || state.length === 0 && state.ended) return 0;
  if (state.objectMode) return 1;
  if (n !== n) {
    // Only flow one buffer at a time
    if (state.flowing && state.length) return state.buffer.head.data.length;else return state.length;
  }
  // If we're asking for more than the current hwm, then raise the hwm.
  if (n > state.highWaterMark) state.highWaterMark = computeNewHighWaterMark(n);
  if (n <= state.length) return n;
  // Don't have enough
  if (!state.ended) {
    state.needReadable = true;
    return 0;
  }
  return state.length;
}

// you can override either this method, or the async _read(n) below.
Readable.prototype.read = function (n) {
  debug('read', n);
  n = parseInt(n, 10);
  var state = this._readableState;
  var nOrig = n;

  if (n !== 0) state.emittedReadable = false;

  // if we're doing read(0) to trigger a readable event, but we
  // already have a bunch of data in the buffer, then just trigger
  // the 'readable' event and move on.
  if (n === 0 && state.needReadable && (state.length >= state.highWaterMark || state.ended)) {
    debug('read: emitReadable', state.length, state.ended);
    if (state.length === 0 && state.ended) endReadable(this);else emitReadable(this);
    return null;
  }

  n = howMuchToRead(n, state);

  // if we've ended, and we're now clear, then finish it up.
  if (n === 0 && state.ended) {
    if (state.length === 0) endReadable(this);
    return null;
  }

  // All the actual chunk generation logic needs to be
  // *below* the call to _read.  The reason is that in certain
  // synthetic stream cases, such as passthrough streams, _read
  // may be a completely synchronous operation which may change
  // the state of the read buffer, providing enough data when
  // before there was *not* enough.
  //
  // So, the steps are:
  // 1. Figure out what the state of things will be after we do
  // a read from the buffer.
  //
  // 2. If that resulting state will trigger a _read, then call _read.
  // Note that this may be asynchronous, or synchronous.  Yes, it is
  // deeply ugly to write APIs this way, but that still doesn't mean
  // that the Readable class should behave improperly, as streams are
  // designed to be sync/async agnostic.
  // Take note if the _read call is sync or async (ie, if the read call
  // has returned yet), so that we know whether or not it's safe to emit
  // 'readable' etc.
  //
  // 3. Actually pull the requested chunks out of the buffer and return.

  // if we need a readable event, then we need to do some reading.
  var doRead = state.needReadable;
  debug('need readable', doRead);

  // if we currently have less than the highWaterMark, then also read some
  if (state.length === 0 || state.length - n < state.highWaterMark) {
    doRead = true;
    debug('length less than watermark', doRead);
  }

  // however, if we've ended, then there's no point, and if we're already
  // reading, then it's unnecessary.
  if (state.ended || state.reading) {
    doRead = false;
    debug('reading or ended', doRead);
  } else if (doRead) {
    debug('do read');
    state.reading = true;
    state.sync = true;
    // if the length is currently zero, then we *need* a readable event.
    if (state.length === 0) state.needReadable = true;
    // call internal read method
    this._read(state.highWaterMark);
    state.sync = false;
    // If _read pushed data synchronously, then `reading` will be false,
    // and we need to re-evaluate how much data we can return to the user.
    if (!state.reading) n = howMuchToRead(nOrig, state);
  }

  var ret;
  if (n > 0) ret = fromList(n, state);else ret = null;

  if (ret === null) {
    state.needReadable = true;
    n = 0;
  } else {
    state.length -= n;
  }

  if (state.length === 0) {
    // If we have nothing in the buffer, then we want to know
    // as soon as we *do* get something into the buffer.
    if (!state.ended) state.needReadable = true;

    // If we tried to read() past the EOF, then emit end on the next tick.
    if (nOrig !== n && state.ended) endReadable(this);
  }

  if (ret !== null) this.emit('data', ret);

  return ret;
};

function chunkInvalid(state, chunk) {
  var er = null;
  if (!Buffer.isBuffer(chunk) && typeof chunk !== 'string' && chunk !== null && chunk !== undefined && !state.objectMode) {
    er = new TypeError('Invalid non-string/buffer chunk');
  }
  return er;
}

function onEofChunk(stream, state) {
  if (state.ended) return;
  if (state.decoder) {
    var chunk = state.decoder.end();
    if (chunk && chunk.length) {
      state.buffer.push(chunk);
      state.length += state.objectMode ? 1 : chunk.length;
    }
  }
  state.ended = true;

  // emit 'readable' now to make sure it gets picked up.
  emitReadable(stream);
}

// Don't emit readable right away in sync mode, because this can trigger
// another read() call => stack overflow.  This way, it might trigger
// a nextTick recursion warning, but that's not so bad.
function emitReadable(stream) {
  var state = stream._readableState;
  state.needReadable = false;
  if (!state.emittedReadable) {
    debug('emitReadable', state.flowing);
    state.emittedReadable = true;
    if (state.sync) nextTick(emitReadable_, stream);else emitReadable_(stream);
  }
}

function emitReadable_(stream) {
  debug('emit readable');
  stream.emit('readable');
  flow(stream);
}

// at this point, the user has presumably seen the 'readable' event,
// and called read() to consume some data.  that may have triggered
// in turn another _read(n) call, in which case reading = true if
// it's in progress.
// However, if we're not ended, or reading, and the length < hwm,
// then go ahead and try to read some more preemptively.
function maybeReadMore(stream, state) {
  if (!state.readingMore) {
    state.readingMore = true;
    nextTick(maybeReadMore_, stream, state);
  }
}

function maybeReadMore_(stream, state) {
  var len = state.length;
  while (!state.reading && !state.flowing && !state.ended && state.length < state.highWaterMark) {
    debug('maybeReadMore read 0');
    stream.read(0);
    if (len === state.length)
      // didn't get any data, stop spinning.
      break;else len = state.length;
  }
  state.readingMore = false;
}

// abstract method.  to be overridden in specific implementation classes.
// call cb(er, data) where data is <= n in length.
// for virtual (non-string, non-buffer) streams, "length" is somewhat
// arbitrary, and perhaps not very meaningful.
Readable.prototype._read = function (n) {
  this.emit('error', new Error('not implemented'));
};

Readable.prototype.pipe = function (dest, pipeOpts) {
  var src = this;
  var state = this._readableState;

  switch (state.pipesCount) {
    case 0:
      state.pipes = dest;
      break;
    case 1:
      state.pipes = [state.pipes, dest];
      break;
    default:
      state.pipes.push(dest);
      break;
  }
  state.pipesCount += 1;
  debug('pipe count=%d opts=%j', state.pipesCount, pipeOpts);

  var doEnd = (!pipeOpts || pipeOpts.end !== false);

  var endFn = doEnd ? onend : cleanup;
  if (state.endEmitted) nextTick(endFn);else src.once('end', endFn);

  dest.on('unpipe', onunpipe);
  function onunpipe(readable) {
    debug('onunpipe');
    if (readable === src) {
      cleanup();
    }
  }

  function onend() {
    debug('onend');
    dest.end();
  }

  // when the dest drains, it reduces the awaitDrain counter
  // on the source.  This would be more elegant with a .once()
  // handler in flow(), but adding and removing repeatedly is
  // too slow.
  var ondrain = pipeOnDrain(src);
  dest.on('drain', ondrain);

  var cleanedUp = false;
  function cleanup() {
    debug('cleanup');
    // cleanup event handlers once the pipe is broken
    dest.removeListener('close', onclose);
    dest.removeListener('finish', onfinish);
    dest.removeListener('drain', ondrain);
    dest.removeListener('error', onerror);
    dest.removeListener('unpipe', onunpipe);
    src.removeListener('end', onend);
    src.removeListener('end', cleanup);
    src.removeListener('data', ondata);

    cleanedUp = true;

    // if the reader is waiting for a drain event from this
    // specific writer, then it would cause it to never start
    // flowing again.
    // So, if this is awaiting a drain, then we just call it now.
    // If we don't know, then assume that we are waiting for one.
    if (state.awaitDrain && (!dest._writableState || dest._writableState.needDrain)) ondrain();
  }

  // If the user pushes more data while we're writing to dest then we'll end up
  // in ondata again. However, we only want to increase awaitDrain once because
  // dest will only emit one 'drain' event for the multiple writes.
  // => Introduce a guard on increasing awaitDrain.
  var increasedAwaitDrain = false;
  src.on('data', ondata);
  function ondata(chunk) {
    debug('ondata');
    increasedAwaitDrain = false;
    var ret = dest.write(chunk);
    if (false === ret && !increasedAwaitDrain) {
      // If the user unpiped during `dest.write()`, it is possible
      // to get stuck in a permanently paused state if that write
      // also returned false.
      // => Check whether `dest` is still a piping destination.
      if ((state.pipesCount === 1 && state.pipes === dest || state.pipesCount > 1 && indexOf(state.pipes, dest) !== -1) && !cleanedUp) {
        debug('false write response, pause', src._readableState.awaitDrain);
        src._readableState.awaitDrain++;
        increasedAwaitDrain = true;
      }
      src.pause();
    }
  }

  // if the dest has an error, then stop piping into it.
  // however, don't suppress the throwing behavior for this.
  function onerror(er) {
    debug('onerror', er);
    unpipe();
    dest.removeListener('error', onerror);
    if (listenerCount(dest, 'error') === 0) dest.emit('error', er);
  }

  // Make sure our error handler is attached before userland ones.
  prependListener(dest, 'error', onerror);

  // Both close and finish should trigger unpipe, but only once.
  function onclose() {
    dest.removeListener('finish', onfinish);
    unpipe();
  }
  dest.once('close', onclose);
  function onfinish() {
    debug('onfinish');
    dest.removeListener('close', onclose);
    unpipe();
  }
  dest.once('finish', onfinish);

  function unpipe() {
    debug('unpipe');
    src.unpipe(dest);
  }

  // tell the dest that it's being piped to
  dest.emit('pipe', src);

  // start the flow if it hasn't been started already.
  if (!state.flowing) {
    debug('pipe resume');
    src.resume();
  }

  return dest;
};

function pipeOnDrain(src) {
  return function () {
    var state = src._readableState;
    debug('pipeOnDrain', state.awaitDrain);
    if (state.awaitDrain) state.awaitDrain--;
    if (state.awaitDrain === 0 && src.listeners('data').length) {
      state.flowing = true;
      flow(src);
    }
  };
}

Readable.prototype.unpipe = function (dest) {
  var state = this._readableState;

  // if we're not piping anywhere, then do nothing.
  if (state.pipesCount === 0) return this;

  // just one destination.  most common case.
  if (state.pipesCount === 1) {
    // passed in one, but it's not the right one.
    if (dest && dest !== state.pipes) return this;

    if (!dest) dest = state.pipes;

    // got a match.
    state.pipes = null;
    state.pipesCount = 0;
    state.flowing = false;
    if (dest) dest.emit('unpipe', this);
    return this;
  }

  // slow case. multiple pipe destinations.

  if (!dest) {
    // remove all.
    var dests = state.pipes;
    var len = state.pipesCount;
    state.pipes = null;
    state.pipesCount = 0;
    state.flowing = false;

    for (var _i = 0; _i < len; _i++) {
      dests[_i].emit('unpipe', this);
    }return this;
  }

  // try to find the right one.
  var i = indexOf(state.pipes, dest);
  if (i === -1) return this;

  state.pipes.splice(i, 1);
  state.pipesCount -= 1;
  if (state.pipesCount === 1) state.pipes = state.pipes[0];

  dest.emit('unpipe', this);

  return this;
};

// set up data events if they are asked for
// Ensure readable listeners eventually get something
Readable.prototype.on = function (ev, fn) {
  var res = EventEmitter.prototype.on.call(this, ev, fn);

  if (ev === 'data') {
    // Start flowing on next tick if stream isn't explicitly paused
    if (this._readableState.flowing !== false) this.resume();
  } else if (ev === 'readable') {
    var state = this._readableState;
    if (!state.endEmitted && !state.readableListening) {
      state.readableListening = state.needReadable = true;
      state.emittedReadable = false;
      if (!state.reading) {
        nextTick(nReadingNextTick, this);
      } else if (state.length) {
        emitReadable(this);
      }
    }
  }

  return res;
};
Readable.prototype.addListener = Readable.prototype.on;

function nReadingNextTick(self) {
  debug('readable nexttick read 0');
  self.read(0);
}

// pause() and resume() are remnants of the legacy readable stream API
// If the user uses them, then switch into old mode.
Readable.prototype.resume = function () {
  var state = this._readableState;
  if (!state.flowing) {
    debug('resume');
    state.flowing = true;
    resume(this, state);
  }
  return this;
};

function resume(stream, state) {
  if (!state.resumeScheduled) {
    state.resumeScheduled = true;
    nextTick(resume_, stream, state);
  }
}

function resume_(stream, state) {
  if (!state.reading) {
    debug('resume read 0');
    stream.read(0);
  }

  state.resumeScheduled = false;
  state.awaitDrain = 0;
  stream.emit('resume');
  flow(stream);
  if (state.flowing && !state.reading) stream.read(0);
}

Readable.prototype.pause = function () {
  debug('call pause flowing=%j', this._readableState.flowing);
  if (false !== this._readableState.flowing) {
    debug('pause');
    this._readableState.flowing = false;
    this.emit('pause');
  }
  return this;
};

function flow(stream) {
  var state = stream._readableState;
  debug('flow', state.flowing);
  while (state.flowing && stream.read() !== null) {}
}

// wrap an old-style stream as the async data source.
// This is *not* part of the readable stream interface.
// It is an ugly unfortunate mess of history.
Readable.prototype.wrap = function (stream) {
  var state = this._readableState;
  var paused = false;

  var self = this;
  stream.on('end', function () {
    debug('wrapped end');
    if (state.decoder && !state.ended) {
      var chunk = state.decoder.end();
      if (chunk && chunk.length) self.push(chunk);
    }

    self.push(null);
  });

  stream.on('data', function (chunk) {
    debug('wrapped data');
    if (state.decoder) chunk = state.decoder.write(chunk);

    // don't skip over falsy values in objectMode
    if (state.objectMode && (chunk === null || chunk === undefined)) return;else if (!state.objectMode && (!chunk || !chunk.length)) return;

    var ret = self.push(chunk);
    if (!ret) {
      paused = true;
      stream.pause();
    }
  });

  // proxy all the other methods.
  // important when wrapping filters and duplexes.
  for (var i in stream) {
    if (this[i] === undefined && typeof stream[i] === 'function') {
      this[i] = function (method) {
        return function () {
          return stream[method].apply(stream, arguments);
        };
      }(i);
    }
  }

  // proxy certain important events.
  var events = ['error', 'close', 'destroy', 'pause', 'resume'];
  forEach(events, function (ev) {
    stream.on(ev, self.emit.bind(self, ev));
  });

  // when we try to consume some more bytes, simply unpause the
  // underlying stream.
  self._read = function (n) {
    debug('wrapped _read', n);
    if (paused) {
      paused = false;
      stream.resume();
    }
  };

  return self;
};

// exposed for testing purposes only.
Readable._fromList = fromList;

// Pluck off n bytes from an array of buffers.
// Length is the combined lengths of all the buffers in the list.
// This function is designed to be inlinable, so please take care when making
// changes to the function body.
function fromList(n, state) {
  // nothing buffered
  if (state.length === 0) return null;

  var ret;
  if (state.objectMode) ret = state.buffer.shift();else if (!n || n >= state.length) {
    // read it all, truncate the list
    if (state.decoder) ret = state.buffer.join('');else if (state.buffer.length === 1) ret = state.buffer.head.data;else ret = state.buffer.concat(state.length);
    state.buffer.clear();
  } else {
    // read part of list
    ret = fromListPartial(n, state.buffer, state.decoder);
  }

  return ret;
}

// Extracts only enough buffered data to satisfy the amount requested.
// This function is designed to be inlinable, so please take care when making
// changes to the function body.
function fromListPartial(n, list, hasStrings) {
  var ret;
  if (n < list.head.data.length) {
    // slice is the same for buffers and strings
    ret = list.head.data.slice(0, n);
    list.head.data = list.head.data.slice(n);
  } else if (n === list.head.data.length) {
    // first chunk is a perfect match
    ret = list.shift();
  } else {
    // result spans more than one buffer
    ret = hasStrings ? copyFromBufferString(n, list) : copyFromBuffer(n, list);
  }
  return ret;
}

// Copies a specified amount of characters from the list of buffered data
// chunks.
// This function is designed to be inlinable, so please take care when making
// changes to the function body.
function copyFromBufferString(n, list) {
  var p = list.head;
  var c = 1;
  var ret = p.data;
  n -= ret.length;
  while (p = p.next) {
    var str = p.data;
    var nb = n > str.length ? str.length : n;
    if (nb === str.length) ret += str;else ret += str.slice(0, n);
    n -= nb;
    if (n === 0) {
      if (nb === str.length) {
        ++c;
        if (p.next) list.head = p.next;else list.head = list.tail = null;
      } else {
        list.head = p;
        p.data = str.slice(nb);
      }
      break;
    }
    ++c;
  }
  list.length -= c;
  return ret;
}

// Copies a specified amount of bytes from the list of buffered data chunks.
// This function is designed to be inlinable, so please take care when making
// changes to the function body.
function copyFromBuffer(n, list) {
  var ret = Buffer.allocUnsafe(n);
  var p = list.head;
  var c = 1;
  p.data.copy(ret);
  n -= p.data.length;
  while (p = p.next) {
    var buf = p.data;
    var nb = n > buf.length ? buf.length : n;
    buf.copy(ret, ret.length - n, 0, nb);
    n -= nb;
    if (n === 0) {
      if (nb === buf.length) {
        ++c;
        if (p.next) list.head = p.next;else list.head = list.tail = null;
      } else {
        list.head = p;
        p.data = buf.slice(nb);
      }
      break;
    }
    ++c;
  }
  list.length -= c;
  return ret;
}

function endReadable(stream) {
  var state = stream._readableState;

  // If we get here before consuming all the bytes, then that is a
  // bug in node.  Should never happen.
  if (state.length > 0) throw new Error('"endReadable()" called on non-empty stream');

  if (!state.endEmitted) {
    state.ended = true;
    nextTick(endReadableNT, state, stream);
  }
}

function endReadableNT(state, stream) {
  // Check that we didn't get one last unshift.
  if (!state.endEmitted && state.length === 0) {
    state.endEmitted = true;
    stream.readable = false;
    stream.emit('end');
  }
}

function forEach(xs, f) {
  for (var i = 0, l = xs.length; i < l; i++) {
    f(xs[i], i);
  }
}

function indexOf(xs, x) {
  for (var i = 0, l = xs.length; i < l; i++) {
    if (xs[i] === x) return i;
  }
  return -1;
}

// A bit simpler than readable streams.
// Implement an async ._write(chunk, encoding, cb), and it'll handle all
// the drain event emission and buffering.

Writable.WritableState = WritableState;
inherits$1(Writable, EventEmitter);

function nop() {}

function WriteReq(chunk, encoding, cb) {
  this.chunk = chunk;
  this.encoding = encoding;
  this.callback = cb;
  this.next = null;
}

function WritableState(options, stream) {
  Object.defineProperty(this, 'buffer', {
    get: deprecate(function () {
      return this.getBuffer();
    }, '_writableState.buffer is deprecated. Use _writableState.getBuffer ' + 'instead.')
  });
  options = options || {};

  // object stream flag to indicate whether or not this stream
  // contains buffers or objects.
  this.objectMode = !!options.objectMode;

  if (stream instanceof Duplex) this.objectMode = this.objectMode || !!options.writableObjectMode;

  // the point at which write() starts returning false
  // Note: 0 is a valid value, means that we always return false if
  // the entire buffer is not flushed immediately on write()
  var hwm = options.highWaterMark;
  var defaultHwm = this.objectMode ? 16 : 16 * 1024;
  this.highWaterMark = hwm || hwm === 0 ? hwm : defaultHwm;

  // cast to ints.
  this.highWaterMark = ~ ~this.highWaterMark;

  this.needDrain = false;
  // at the start of calling end()
  this.ending = false;
  // when end() has been called, and returned
  this.ended = false;
  // when 'finish' is emitted
  this.finished = false;

  // should we decode strings into buffers before passing to _write?
  // this is here so that some node-core streams can optimize string
  // handling at a lower level.
  var noDecode = options.decodeStrings === false;
  this.decodeStrings = !noDecode;

  // Crypto is kind of old and crusty.  Historically, its default string
  // encoding is 'binary' so we have to make this configurable.
  // Everything else in the universe uses 'utf8', though.
  this.defaultEncoding = options.defaultEncoding || 'utf8';

  // not an actual buffer we keep track of, but a measurement
  // of how much we're waiting to get pushed to some underlying
  // socket or file.
  this.length = 0;

  // a flag to see when we're in the middle of a write.
  this.writing = false;

  // when true all writes will be buffered until .uncork() call
  this.corked = 0;

  // a flag to be able to tell if the onwrite cb is called immediately,
  // or on a later tick.  We set this to true at first, because any
  // actions that shouldn't happen until "later" should generally also
  // not happen before the first write call.
  this.sync = true;

  // a flag to know if we're processing previously buffered items, which
  // may call the _write() callback in the same tick, so that we don't
  // end up in an overlapped onwrite situation.
  this.bufferProcessing = false;

  // the callback that's passed to _write(chunk,cb)
  this.onwrite = function (er) {
    onwrite(stream, er);
  };

  // the callback that the user supplies to write(chunk,encoding,cb)
  this.writecb = null;

  // the amount that is being written when _write is called.
  this.writelen = 0;

  this.bufferedRequest = null;
  this.lastBufferedRequest = null;

  // number of pending user-supplied write callbacks
  // this must be 0 before 'finish' can be emitted
  this.pendingcb = 0;

  // emit prefinish if the only thing we're waiting for is _write cbs
  // This is relevant for synchronous Transform streams
  this.prefinished = false;

  // True if the error was already emitted and should not be thrown again
  this.errorEmitted = false;

  // count buffered requests
  this.bufferedRequestCount = 0;

  // allocate the first CorkedRequest, there is always
  // one allocated and free to use, and we maintain at most two
  this.corkedRequestsFree = new CorkedRequest(this);
}

WritableState.prototype.getBuffer = function writableStateGetBuffer() {
  var current = this.bufferedRequest;
  var out = [];
  while (current) {
    out.push(current);
    current = current.next;
  }
  return out;
};
function Writable(options) {

  // Writable ctor is applied to Duplexes, though they're not
  // instanceof Writable, they're instanceof Readable.
  if (!(this instanceof Writable) && !(this instanceof Duplex)) return new Writable(options);

  this._writableState = new WritableState(options, this);

  // legacy.
  this.writable = true;

  if (options) {
    if (typeof options.write === 'function') this._write = options.write;

    if (typeof options.writev === 'function') this._writev = options.writev;
  }

  EventEmitter.call(this);
}

// Otherwise people can pipe Writable streams, which is just wrong.
Writable.prototype.pipe = function () {
  this.emit('error', new Error('Cannot pipe, not readable'));
};

function writeAfterEnd(stream, cb) {
  var er = new Error('write after end');
  // TODO: defer error events consistently everywhere, not just the cb
  stream.emit('error', er);
  nextTick(cb, er);
}

// If we get something that is not a buffer, string, null, or undefined,
// and we're not in objectMode, then that's an error.
// Otherwise stream chunks are all considered to be of length=1, and the
// watermarks determine how many objects to keep in the buffer, rather than
// how many bytes or characters.
function validChunk(stream, state, chunk, cb) {
  var valid = true;
  var er = false;
  // Always throw error if a null is written
  // if we are not in object mode then throw
  // if it is not a buffer, string, or undefined.
  if (chunk === null) {
    er = new TypeError('May not write null values to stream');
  } else if (!Buffer.isBuffer(chunk) && typeof chunk !== 'string' && chunk !== undefined && !state.objectMode) {
    er = new TypeError('Invalid non-string/buffer chunk');
  }
  if (er) {
    stream.emit('error', er);
    nextTick(cb, er);
    valid = false;
  }
  return valid;
}

Writable.prototype.write = function (chunk, encoding, cb) {
  var state = this._writableState;
  var ret = false;

  if (typeof encoding === 'function') {
    cb = encoding;
    encoding = null;
  }

  if (Buffer.isBuffer(chunk)) encoding = 'buffer';else if (!encoding) encoding = state.defaultEncoding;

  if (typeof cb !== 'function') cb = nop;

  if (state.ended) writeAfterEnd(this, cb);else if (validChunk(this, state, chunk, cb)) {
    state.pendingcb++;
    ret = writeOrBuffer(this, state, chunk, encoding, cb);
  }

  return ret;
};

Writable.prototype.cork = function () {
  var state = this._writableState;

  state.corked++;
};

Writable.prototype.uncork = function () {
  var state = this._writableState;

  if (state.corked) {
    state.corked--;

    if (!state.writing && !state.corked && !state.finished && !state.bufferProcessing && state.bufferedRequest) clearBuffer(this, state);
  }
};

Writable.prototype.setDefaultEncoding = function setDefaultEncoding(encoding) {
  // node::ParseEncoding() requires lower case.
  if (typeof encoding === 'string') encoding = encoding.toLowerCase();
  if (!(['hex', 'utf8', 'utf-8', 'ascii', 'binary', 'base64', 'ucs2', 'ucs-2', 'utf16le', 'utf-16le', 'raw'].indexOf((encoding + '').toLowerCase()) > -1)) throw new TypeError('Unknown encoding: ' + encoding);
  this._writableState.defaultEncoding = encoding;
  return this;
};

function decodeChunk(state, chunk, encoding) {
  if (!state.objectMode && state.decodeStrings !== false && typeof chunk === 'string') {
    chunk = Buffer.from(chunk, encoding);
  }
  return chunk;
}

// if we're already writing something, then just put this
// in the queue, and wait our turn.  Otherwise, call _write
// If we return false, then we need a drain event, so set that flag.
function writeOrBuffer(stream, state, chunk, encoding, cb) {
  chunk = decodeChunk(state, chunk, encoding);

  if (Buffer.isBuffer(chunk)) encoding = 'buffer';
  var len = state.objectMode ? 1 : chunk.length;

  state.length += len;

  var ret = state.length < state.highWaterMark;
  // we must ensure that previous needDrain will not be reset to false.
  if (!ret) state.needDrain = true;

  if (state.writing || state.corked) {
    var last = state.lastBufferedRequest;
    state.lastBufferedRequest = new WriteReq(chunk, encoding, cb);
    if (last) {
      last.next = state.lastBufferedRequest;
    } else {
      state.bufferedRequest = state.lastBufferedRequest;
    }
    state.bufferedRequestCount += 1;
  } else {
    doWrite(stream, state, false, len, chunk, encoding, cb);
  }

  return ret;
}

function doWrite(stream, state, writev, len, chunk, encoding, cb) {
  state.writelen = len;
  state.writecb = cb;
  state.writing = true;
  state.sync = true;
  if (writev) stream._writev(chunk, state.onwrite);else stream._write(chunk, encoding, state.onwrite);
  state.sync = false;
}

function onwriteError(stream, state, sync, er, cb) {
  --state.pendingcb;
  if (sync) nextTick(cb, er);else cb(er);

  stream._writableState.errorEmitted = true;
  stream.emit('error', er);
}

function onwriteStateUpdate(state) {
  state.writing = false;
  state.writecb = null;
  state.length -= state.writelen;
  state.writelen = 0;
}

function onwrite(stream, er) {
  var state = stream._writableState;
  var sync = state.sync;
  var cb = state.writecb;

  onwriteStateUpdate(state);

  if (er) onwriteError(stream, state, sync, er, cb);else {
    // Check if we're actually ready to finish, but don't emit yet
    var finished = needFinish(state);

    if (!finished && !state.corked && !state.bufferProcessing && state.bufferedRequest) {
      clearBuffer(stream, state);
    }

    if (sync) {
      /*<replacement>*/
        nextTick(afterWrite, stream, state, finished, cb);
      /*</replacement>*/
    } else {
        afterWrite(stream, state, finished, cb);
      }
  }
}

function afterWrite(stream, state, finished, cb) {
  if (!finished) onwriteDrain(stream, state);
  state.pendingcb--;
  cb();
  finishMaybe(stream, state);
}

// Must force callback to be called on nextTick, so that we don't
// emit 'drain' before the write() consumer gets the 'false' return
// value, and has a chance to attach a 'drain' listener.
function onwriteDrain(stream, state) {
  if (state.length === 0 && state.needDrain) {
    state.needDrain = false;
    stream.emit('drain');
  }
}

// if there's something in the buffer waiting, then process it
function clearBuffer(stream, state) {
  state.bufferProcessing = true;
  var entry = state.bufferedRequest;

  if (stream._writev && entry && entry.next) {
    // Fast case, write everything using _writev()
    var l = state.bufferedRequestCount;
    var buffer = new Array(l);
    var holder = state.corkedRequestsFree;
    holder.entry = entry;

    var count = 0;
    while (entry) {
      buffer[count] = entry;
      entry = entry.next;
      count += 1;
    }

    doWrite(stream, state, true, state.length, buffer, '', holder.finish);

    // doWrite is almost always async, defer these to save a bit of time
    // as the hot path ends with doWrite
    state.pendingcb++;
    state.lastBufferedRequest = null;
    if (holder.next) {
      state.corkedRequestsFree = holder.next;
      holder.next = null;
    } else {
      state.corkedRequestsFree = new CorkedRequest(state);
    }
  } else {
    // Slow case, write chunks one-by-one
    while (entry) {
      var chunk = entry.chunk;
      var encoding = entry.encoding;
      var cb = entry.callback;
      var len = state.objectMode ? 1 : chunk.length;

      doWrite(stream, state, false, len, chunk, encoding, cb);
      entry = entry.next;
      // if we didn't call the onwrite immediately, then
      // it means that we need to wait until it does.
      // also, that means that the chunk and cb are currently
      // being processed, so move the buffer counter past them.
      if (state.writing) {
        break;
      }
    }

    if (entry === null) state.lastBufferedRequest = null;
  }

  state.bufferedRequestCount = 0;
  state.bufferedRequest = entry;
  state.bufferProcessing = false;
}

Writable.prototype._write = function (chunk, encoding, cb) {
  cb(new Error('not implemented'));
};

Writable.prototype._writev = null;

Writable.prototype.end = function (chunk, encoding, cb) {
  var state = this._writableState;

  if (typeof chunk === 'function') {
    cb = chunk;
    chunk = null;
    encoding = null;
  } else if (typeof encoding === 'function') {
    cb = encoding;
    encoding = null;
  }

  if (chunk !== null && chunk !== undefined) this.write(chunk, encoding);

  // .end() fully uncorks
  if (state.corked) {
    state.corked = 1;
    this.uncork();
  }

  // ignore unnecessary end() calls.
  if (!state.ending && !state.finished) endWritable(this, state, cb);
};

function needFinish(state) {
  return state.ending && state.length === 0 && state.bufferedRequest === null && !state.finished && !state.writing;
}

function prefinish(stream, state) {
  if (!state.prefinished) {
    state.prefinished = true;
    stream.emit('prefinish');
  }
}

function finishMaybe(stream, state) {
  var need = needFinish(state);
  if (need) {
    if (state.pendingcb === 0) {
      prefinish(stream, state);
      state.finished = true;
      stream.emit('finish');
    } else {
      prefinish(stream, state);
    }
  }
  return need;
}

function endWritable(stream, state, cb) {
  state.ending = true;
  finishMaybe(stream, state);
  if (cb) {
    if (state.finished) nextTick(cb);else stream.once('finish', cb);
  }
  state.ended = true;
  stream.writable = false;
}

// It seems a linked list but it is not
// there will be only 2 of these for each stream
function CorkedRequest(state) {
  var _this = this;

  this.next = null;
  this.entry = null;

  this.finish = function (err) {
    var entry = _this.entry;
    _this.entry = null;
    while (entry) {
      var cb = entry.callback;
      state.pendingcb--;
      cb(err);
      entry = entry.next;
    }
    if (state.corkedRequestsFree) {
      state.corkedRequestsFree.next = _this;
    } else {
      state.corkedRequestsFree = _this;
    }
  };
}

inherits$1(Duplex, Readable);

var keys = Object.keys(Writable.prototype);
for (var v = 0; v < keys.length; v++) {
  var method = keys[v];
  if (!Duplex.prototype[method]) Duplex.prototype[method] = Writable.prototype[method];
}
function Duplex(options) {
  if (!(this instanceof Duplex)) return new Duplex(options);

  Readable.call(this, options);
  Writable.call(this, options);

  if (options && options.readable === false) this.readable = false;

  if (options && options.writable === false) this.writable = false;

  this.allowHalfOpen = true;
  if (options && options.allowHalfOpen === false) this.allowHalfOpen = false;

  this.once('end', onend);
}

// the no-half-open enforcer
function onend() {
  // if we allow half-open state, or if the writable side ended,
  // then we're ok.
  if (this.allowHalfOpen || this._writableState.ended) return;

  // no more data can be written.
  // But allow more writes to happen in this tick.
  nextTick(onEndNT, this);
}

function onEndNT(self) {
  self.end();
}

// a transform stream is a readable/writable stream where you do
// something with the data.  Sometimes it's called a "filter",
// but that's not a great name for it, since that implies a thing where
// some bits pass through, and others are simply ignored.  (That would
// be a valid example of a transform, of course.)
//
// While the output is causally related to the input, it's not a
// necessarily symmetric or synchronous transformation.  For example,
// a zlib stream might take multiple plain-text writes(), and then
// emit a single compressed chunk some time in the future.
//
// Here's how this works:
//
// The Transform stream has all the aspects of the readable and writable
// stream classes.  When you write(chunk), that calls _write(chunk,cb)
// internally, and returns false if there's a lot of pending writes
// buffered up.  When you call read(), that calls _read(n) until
// there's enough pending readable data buffered up.
//
// In a transform stream, the written data is placed in a buffer.  When
// _read(n) is called, it transforms the queued up data, calling the
// buffered _write cb's as it consumes chunks.  If consuming a single
// written chunk would result in multiple output chunks, then the first
// outputted bit calls the readcb, and subsequent chunks just go into
// the read buffer, and will cause it to emit 'readable' if necessary.
//
// This way, back-pressure is actually determined by the reading side,
// since _read has to be called to start processing a new chunk.  However,
// a pathological inflate type of transform can cause excessive buffering
// here.  For example, imagine a stream where every byte of input is
// interpreted as an integer from 0-255, and then results in that many
// bytes of output.  Writing the 4 bytes {ff,ff,ff,ff} would result in
// 1kb of data being output.  In this case, you could write a very small
// amount of input, and end up with a very large amount of output.  In
// such a pathological inflating mechanism, there'd be no way to tell
// the system to stop doing the transform.  A single 4MB write could
// cause the system to run out of memory.
//
// However, even in such a pathological case, only a single written chunk
// would be consumed, and then the rest would wait (un-transformed) until
// the results of the previous transformed chunk were consumed.

inherits$1(Transform, Duplex);

function TransformState(stream) {
  this.afterTransform = function (er, data) {
    return afterTransform(stream, er, data);
  };

  this.needTransform = false;
  this.transforming = false;
  this.writecb = null;
  this.writechunk = null;
  this.writeencoding = null;
}

function afterTransform(stream, er, data) {
  var ts = stream._transformState;
  ts.transforming = false;

  var cb = ts.writecb;

  if (!cb) return stream.emit('error', new Error('no writecb in Transform class'));

  ts.writechunk = null;
  ts.writecb = null;

  if (data !== null && data !== undefined) stream.push(data);

  cb(er);

  var rs = stream._readableState;
  rs.reading = false;
  if (rs.needReadable || rs.length < rs.highWaterMark) {
    stream._read(rs.highWaterMark);
  }
}
function Transform(options) {
  if (!(this instanceof Transform)) return new Transform(options);

  Duplex.call(this, options);

  this._transformState = new TransformState(this);

  // when the writable side finishes, then flush out anything remaining.
  var stream = this;

  // start out asking for a readable event once data is transformed.
  this._readableState.needReadable = true;

  // we have implemented the _read method, and done the other things
  // that Readable wants before the first _read call, so unset the
  // sync guard flag.
  this._readableState.sync = false;

  if (options) {
    if (typeof options.transform === 'function') this._transform = options.transform;

    if (typeof options.flush === 'function') this._flush = options.flush;
  }

  this.once('prefinish', function () {
    if (typeof this._flush === 'function') this._flush(function (er) {
      done(stream, er);
    });else done(stream);
  });
}

Transform.prototype.push = function (chunk, encoding) {
  this._transformState.needTransform = false;
  return Duplex.prototype.push.call(this, chunk, encoding);
};

// This is the part where you do stuff!
// override this function in implementation classes.
// 'chunk' is an input chunk.
//
// Call `push(newChunk)` to pass along transformed output
// to the readable side.  You may call 'push' zero or more times.
//
// Call `cb(err)` when you are done with this chunk.  If you pass
// an error, then that'll put the hurt on the whole operation.  If you
// never call cb(), then you'll never get another chunk.
Transform.prototype._transform = function (chunk, encoding, cb) {
  throw new Error('Not implemented');
};

Transform.prototype._write = function (chunk, encoding, cb) {
  var ts = this._transformState;
  ts.writecb = cb;
  ts.writechunk = chunk;
  ts.writeencoding = encoding;
  if (!ts.transforming) {
    var rs = this._readableState;
    if (ts.needTransform || rs.needReadable || rs.length < rs.highWaterMark) this._read(rs.highWaterMark);
  }
};

// Doesn't matter what the args are here.
// _transform does all the work.
// That we got here means that the readable side wants more data.
Transform.prototype._read = function (n) {
  var ts = this._transformState;

  if (ts.writechunk !== null && ts.writecb && !ts.transforming) {
    ts.transforming = true;
    this._transform(ts.writechunk, ts.writeencoding, ts.afterTransform);
  } else {
    // mark that we need a transform, so that any data that comes in
    // will get processed, now that we've asked for it.
    ts.needTransform = true;
  }
};

function done(stream, er) {
  if (er) return stream.emit('error', er);

  // if there's nothing in the write buffer, then that means
  // that nothing more will ever be provided
  var ws = stream._writableState;
  var ts = stream._transformState;

  if (ws.length) throw new Error('Calling transform done when ws.length != 0');

  if (ts.transforming) throw new Error('Calling transform done when still transforming');

  return stream.push(null);
}

inherits$1(PassThrough, Transform);
function PassThrough(options) {
  if (!(this instanceof PassThrough)) return new PassThrough(options);

  Transform.call(this, options);
}

PassThrough.prototype._transform = function (chunk, encoding, cb) {
  cb(null, chunk);
};

inherits$1(Stream, EventEmitter);
Stream.Readable = Readable;
Stream.Writable = Writable;
Stream.Duplex = Duplex;
Stream.Transform = Transform;
Stream.PassThrough = PassThrough;

// Backwards-compat with node 0.4.x
Stream.Stream = Stream;

// old-style streams.  Note that the pipe method (the only relevant
// part of this class) is overridden in the Readable class.

function Stream() {
  EventEmitter.call(this);
}

Stream.prototype.pipe = function(dest, options) {
  var source = this;

  function ondata(chunk) {
    if (dest.writable) {
      if (false === dest.write(chunk) && source.pause) {
        source.pause();
      }
    }
  }

  source.on('data', ondata);

  function ondrain() {
    if (source.readable && source.resume) {
      source.resume();
    }
  }

  dest.on('drain', ondrain);

  // If the 'end' option is not supplied, dest.end() will be called when
  // source gets the 'end' or 'close' events.  Only dest.end() once.
  if (!dest._isStdio && (!options || options.end !== false)) {
    source.on('end', onend);
    source.on('close', onclose);
  }

  var didOnEnd = false;
  function onend() {
    if (didOnEnd) return;
    didOnEnd = true;

    dest.end();
  }


  function onclose() {
    if (didOnEnd) return;
    didOnEnd = true;

    if (typeof dest.destroy === 'function') dest.destroy();
  }

  // don't leave dangling pipes when there are errors.
  function onerror(er) {
    cleanup();
    if (EventEmitter.listenerCount(this, 'error') === 0) {
      throw er; // Unhandled stream error in pipe.
    }
  }

  source.on('error', onerror);
  dest.on('error', onerror);

  // remove all the event listeners that were added.
  function cleanup() {
    source.removeListener('data', ondata);
    dest.removeListener('drain', ondrain);

    source.removeListener('end', onend);
    source.removeListener('close', onclose);

    source.removeListener('error', onerror);
    dest.removeListener('error', onerror);

    source.removeListener('end', cleanup);
    source.removeListener('close', cleanup);

    dest.removeListener('close', cleanup);
  }

  source.on('end', cleanup);
  source.on('close', cleanup);

  dest.on('close', cleanup);

  dest.emit('pipe', source);

  // Allow for unix-like usage: A.pipe(B).pipe(C)
  return dest;
};

var stream = /*#__PURE__*/Object.freeze({
  __proto__: null,
  Duplex: Duplex,
  PassThrough: PassThrough,
  Readable: Readable,
  Stream: Stream,
  Transform: Transform,
  Writable: Writable,
  default: Stream
});

var require$$0 = /*@__PURE__*/getAugmentedNamespace(stream);

var parseStream_1;
var hasRequiredParseStream;

function requireParseStream () {
	if (hasRequiredParseStream) return parseStream_1;
	hasRequiredParseStream = 1;
	parseStream_1 = parseStream;

	const stream = require$$0;
	const TOMLParser = requireTomlParser();

	function parseStream (stm) {
	  if (stm) {
	    return parseReadable(stm)
	  } else {
	    return parseTransform()
	  }
	}

	function parseReadable (stm) {
	  const parser = new TOMLParser();
	  stm.setEncoding('utf8');
	  return new Promise((resolve, reject) => {
	    let readable;
	    let ended = false;
	    let errored = false;
	    function finish () {
	      ended = true;
	      if (readable) return
	      try {
	        resolve(parser.finish());
	      } catch (err) {
	        reject(err);
	      }
	    }
	    function error (err) {
	      errored = true;
	      reject(err);
	    }
	    stm.once('end', finish);
	    stm.once('error', error);
	    readNext();

	    function readNext () {
	      readable = true;
	      let data;
	      while ((data = stm.read()) !== null) {
	        try {
	          parser.parse(data);
	        } catch (err) {
	          return error(err)
	        }
	      }
	      readable = false;
	      /* istanbul ignore if */
	      if (ended) return finish()
	      /* istanbul ignore if */
	      if (errored) return
	      stm.once('readable', readNext);
	    }
	  })
	}

	function parseTransform () {
	  const parser = new TOMLParser();
	  return new stream.Transform({
	    objectMode: true,
	    transform (chunk, encoding, cb) {
	      try {
	        parser.parse(chunk.toString(encoding));
	      } catch (err) {
	        this.emit('error', err);
	      }
	      cb();
	    },
	    flush (cb) {
	      try {
	        this.push(parser.finish());
	      } catch (err) {
	        this.emit('error', err);
	      }
	      cb();
	    }
	  })
	}
	return parseStream_1;
}

var hasRequiredParse;

function requireParse () {
	if (hasRequiredParse) return parse$1.exports;
	hasRequiredParse = 1;
	parse$1.exports = requireParseString();
	parse$1.exports.async = requireParseAsync();
	parse$1.exports.stream = requireParseStream();
	parse$1.exports.prettyError = requireParsePrettyError();
	return parse$1.exports;
}

var stringify = {exports: {}};

var hasRequiredStringify;

function requireStringify () {
	if (hasRequiredStringify) return stringify.exports;
	hasRequiredStringify = 1;
	stringify.exports = stringify$1;
	stringify.exports.value = stringifyInline;

	function stringify$1 (obj) {
	  if (obj === null) throw typeError('null')
	  if (obj === void 0) throw typeError('undefined')
	  if (typeof obj !== 'object') throw typeError(typeof obj)

	  if (typeof obj.toJSON === 'function') obj = obj.toJSON();
	  if (obj == null) return null
	  const type = tomlType(obj);
	  if (type !== 'table') throw typeError(type)
	  return stringifyObject('', '', obj)
	}

	function typeError (type) {
	  return new Error('Can only stringify objects, not ' + type)
	}

	function arrayOneTypeError () {
	  return new Error("Array values can't have mixed types")
	}

	function getInlineKeys (obj) {
	  return Object.keys(obj).filter(key => isInline(obj[key]))
	}
	function getComplexKeys (obj) {
	  return Object.keys(obj).filter(key => !isInline(obj[key]))
	}

	function toJSON (obj) {
	  let nobj = Array.isArray(obj) ? [] : Object.prototype.hasOwnProperty.call(obj, '__proto__') ? {['__proto__']: undefined} : {};
	  for (let prop of Object.keys(obj)) {
	    if (obj[prop] && typeof obj[prop].toJSON === 'function' && !('toISOString' in obj[prop])) {
	      nobj[prop] = obj[prop].toJSON();
	    } else {
	      nobj[prop] = obj[prop];
	    }
	  }
	  return nobj
	}

	function stringifyObject (prefix, indent, obj) {
	  obj = toJSON(obj);
	  var inlineKeys;
	  var complexKeys;
	  inlineKeys = getInlineKeys(obj);
	  complexKeys = getComplexKeys(obj);
	  var result = [];
	  var inlineIndent = indent || '';
	  inlineKeys.forEach(key => {
	    var type = tomlType(obj[key]);
	    if (type !== 'undefined' && type !== 'null') {
	      result.push(inlineIndent + stringifyKey(key) + ' = ' + stringifyAnyInline(obj[key], true));
	    }
	  });
	  if (result.length > 0) result.push('');
	  var complexIndent = prefix && inlineKeys.length > 0 ? indent + '  ' : '';
	  complexKeys.forEach(key => {
	    result.push(stringifyComplex(prefix, complexIndent, key, obj[key]));
	  });
	  return result.join('\n')
	}

	function isInline (value) {
	  switch (tomlType(value)) {
	    case 'undefined':
	    case 'null':
	    case 'integer':
	    case 'nan':
	    case 'float':
	    case 'boolean':
	    case 'string':
	    case 'datetime':
	      return true
	    case 'array':
	      return value.length === 0 || tomlType(value[0]) !== 'table'
	    case 'table':
	      return Object.keys(value).length === 0
	    /* istanbul ignore next */
	    default:
	      return false
	  }
	}

	function tomlType (value) {
	  if (value === undefined) {
	    return 'undefined'
	  } else if (value === null) {
	    return 'null'
	  /* eslint-disable valid-typeof */
	  } else if (typeof value === 'bigint' || (Number.isInteger(value) && !Object.is(value, -0))) {
	    return 'integer'
	  } else if (typeof value === 'number') {
	    return 'float'
	  } else if (typeof value === 'boolean') {
	    return 'boolean'
	  } else if (typeof value === 'string') {
	    return 'string'
	  } else if ('toISOString' in value) {
	    return isNaN(value) ? 'undefined' : 'datetime'
	  } else if (Array.isArray(value)) {
	    return 'array'
	  } else {
	    return 'table'
	  }
	}

	function stringifyKey (key) {
	  var keyStr = String(key);
	  if (/^[-A-Za-z0-9_]+$/.test(keyStr)) {
	    return keyStr
	  } else {
	    return stringifyBasicString(keyStr)
	  }
	}

	function stringifyBasicString (str) {
	  return '"' + escapeString(str).replace(/"/g, '\\"') + '"'
	}

	function stringifyLiteralString (str) {
	  return "'" + str + "'"
	}

	function numpad (num, str) {
	  while (str.length < num) str = '0' + str;
	  return str
	}

	function escapeString (str) {
	  return str.replace(/\\/g, '\\\\')
	    .replace(/[\b]/g, '\\b')
	    .replace(/\t/g, '\\t')
	    .replace(/\n/g, '\\n')
	    .replace(/\f/g, '\\f')
	    .replace(/\r/g, '\\r')
	    /* eslint-disable no-control-regex */
	    .replace(/([\u0000-\u001f\u007f])/, c => '\\u' + numpad(4, c.codePointAt(0).toString(16)))
	    /* eslint-enable no-control-regex */
	}

	function stringifyMultilineString (str) {
	  let escaped = str.split(/\n/).map(str => {
	    return escapeString(str).replace(/"(?="")/g, '\\"')
	  }).join('\n');
	  if (escaped.slice(-1) === '"') escaped += '\\\n';
	  return '"""\n' + escaped + '"""'
	}

	function stringifyAnyInline (value, multilineOk) {
	  let type = tomlType(value);
	  if (type === 'string') {
	    if (multilineOk && /\n/.test(value)) {
	      type = 'string-multiline';
	    } else if (!/[\b\t\n\f\r']/.test(value) && /"/.test(value)) {
	      type = 'string-literal';
	    }
	  }
	  return stringifyInline(value, type)
	}

	function stringifyInline (value, type) {
	  /* istanbul ignore if */
	  if (!type) type = tomlType(value);
	  switch (type) {
	    case 'string-multiline':
	      return stringifyMultilineString(value)
	    case 'string':
	      return stringifyBasicString(value)
	    case 'string-literal':
	      return stringifyLiteralString(value)
	    case 'integer':
	      return stringifyInteger(value)
	    case 'float':
	      return stringifyFloat(value)
	    case 'boolean':
	      return stringifyBoolean(value)
	    case 'datetime':
	      return stringifyDatetime(value)
	    case 'array':
	      return stringifyInlineArray(value.filter(_ => tomlType(_) !== 'null' && tomlType(_) !== 'undefined' && tomlType(_) !== 'nan'))
	    case 'table':
	      return stringifyInlineTable(value)
	    /* istanbul ignore next */
	    default:
	      throw typeError(type)
	  }
	}

	function stringifyInteger (value) {
	  /* eslint-disable security/detect-unsafe-regex */
	  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, '_')
	}

	function stringifyFloat (value) {
	  if (value === Infinity) {
	    return 'inf'
	  } else if (value === -Infinity) {
	    return '-inf'
	  } else if (Object.is(value, NaN)) {
	    return 'nan'
	  } else if (Object.is(value, -0)) {
	    return '-0.0'
	  }
	  var chunks = String(value).split('.');
	  var int = chunks[0];
	  var dec = chunks[1] || 0;
	  return stringifyInteger(int) + '.' + dec
	}

	function stringifyBoolean (value) {
	  return String(value)
	}

	function stringifyDatetime (value) {
	  return value.toISOString()
	}

	function isNumber (type) {
	  return type === 'float' || type === 'integer'
	}
	function arrayType (values) {
	  var contentType = tomlType(values[0]);
	  if (values.every(_ => tomlType(_) === contentType)) return contentType
	  // mixed integer/float, emit as floats
	  if (values.every(_ => isNumber(tomlType(_)))) return 'float'
	  return 'mixed'
	}
	function validateArray (values) {
	  const type = arrayType(values);
	  if (type === 'mixed') {
	    throw arrayOneTypeError()
	  }
	  return type
	}

	function stringifyInlineArray (values) {
	  values = toJSON(values);
	  const type = validateArray(values);
	  var result = '[';
	  var stringified = values.map(_ => stringifyInline(_, type));
	  if (stringified.join(', ').length > 60 || /\n/.test(stringified)) {
	    result += '\n  ' + stringified.join(',\n  ') + '\n';
	  } else {
	    result += ' ' + stringified.join(', ') + (stringified.length > 0 ? ' ' : '');
	  }
	  return result + ']'
	}

	function stringifyInlineTable (value) {
	  value = toJSON(value);
	  var result = [];
	  Object.keys(value).forEach(key => {
	    result.push(stringifyKey(key) + ' = ' + stringifyAnyInline(value[key], false));
	  });
	  return '{ ' + result.join(', ') + (result.length > 0 ? ' ' : '') + '}'
	}

	function stringifyComplex (prefix, indent, key, value) {
	  var valueType = tomlType(value);
	  /* istanbul ignore else */
	  if (valueType === 'array') {
	    return stringifyArrayOfTables(prefix, indent, key, value)
	  } else if (valueType === 'table') {
	    return stringifyComplexTable(prefix, indent, key, value)
	  } else {
	    throw typeError(valueType)
	  }
	}

	function stringifyArrayOfTables (prefix, indent, key, values) {
	  values = toJSON(values);
	  validateArray(values);
	  var firstValueType = tomlType(values[0]);
	  /* istanbul ignore if */
	  if (firstValueType !== 'table') throw typeError(firstValueType)
	  var fullKey = prefix + stringifyKey(key);
	  var result = '';
	  values.forEach(table => {
	    if (result.length > 0) result += '\n';
	    result += indent + '[[' + fullKey + ']]\n';
	    result += stringifyObject(fullKey + '.', indent, table);
	  });
	  return result
	}

	function stringifyComplexTable (prefix, indent, key, value) {
	  var fullKey = prefix + stringifyKey(key);
	  var result = '';
	  if (getInlineKeys(value).length > 0) {
	    result += indent + '[' + fullKey + ']\n';
	  }
	  return result + stringifyObject(fullKey + '.', indent, value)
	}
	return stringify.exports;
}

var hasRequiredToml;

function requireToml () {
	if (hasRequiredToml) return toml;
	hasRequiredToml = 1;
	toml.parse = requireParse();
	toml.stringify = requireStringify();
	return toml;
}

var tomlExports = requireToml();

/**
 * Pluto Notebook Parser
 *
 * Parses Pluto notebook (.jl) files and extracts NotebookData structure
 * compatible with the frontend Editor component.
 */


const NOTEBOOK_HEADER = "### A Pluto.jl notebook ###";
const CELL_ID_DELIMITER = "# ╔═╡ ";
const CELL_METADATA_PREFIX = "# ╠═╡ ";
const ORDER_DELIMITER = "# ╠═";
const ORDER_DELIMITER_FOLDED = "# ╟─";
const CELL_SUFFIX = "\n\n";
const DISABLED_PREFIX = "#=╠═╡\n";
const DISABLED_SUFFIX = "\n  ╠═╡ =#";

// Special cell IDs for package info
const PTOML_CELL_ID = "00000000-0000-0000-0000-000000000001";
const MTOML_CELL_ID$1 = "00000000-0000-0000-0000-000000000002";

/**
 * Default cell metadata structure
 */
const DEFAULT_CELL_METADATA = {
  disabled: false,
  show_logs: true,
  skip_as_script: false,
};

/**
 * Parse a Pluto notebook file content and return NotebookData structure
 * @param {string} content - The raw content of the .jl notebook file
 * @param {string} [path=""] - The file path for the notebook
 * @returns {import("../components/Editor.js").NotebookData} NotebookData structure compatible with Pluto frontend
 */
function parse(content, path = "") {
  const lines = content.split("\n");

  // Validate header
  if (lines[0] !== NOTEBOOK_HEADER) {
    throw new Error("Invalid Pluto notebook file - missing header");
  }

  // Extract version (line 1 starts with "# ")
  const versionLine = lines[1] || "";
  const plutoVersion = versionLine.startsWith("# ")
    ? versionLine.slice(2)
    : "unknown";

  // Parse notebook metadata and find first cell delimiter
  const { notebookMetadata, firstCellIndex, hasBindMacro } = parseHeader(lines);

  if (firstCellIndex === -1) {
    throw new Error("No cells found in notebook");
  }

  // Parse cells (this gives us cells in their file order - topological order)
  const { cellInputs, cellResults, topologicalOrder, packageCells } =
    parseCells(lines, firstCellIndex);

  // Parse cell order (this gives us the display order)
  const cellOrder = parseCellOrder(lines, cellInputs);

  // Generate a notebook ID (in real usage, this would come from the server)
  const notebookId = generateUUID();

  // Create NotebookData structure
  /** @type import("../components/Editor.js").NotebookData  */
  const notebookData = {
    pluto_version: plutoVersion,
    notebook_id: notebookId,
    path: path,
    shortpath: path.split("/").pop() || "notebook.jl",
    in_temp_dir: false,
    process_status: "no_process",
    last_save_time: Date.now(),
    last_hot_reload_time: 0,
    cell_inputs: cellInputs,
    cell_results: cellResults,
    cell_dependencies: {},
    cell_order: cellOrder,
    cell_execution_order: [],
    published_objects: {},
    bonds: {},
    nbpkg: null,
    metadata: notebookMetadata,
    status_tree: null,
    // Store additional data needed for serialization
    _topological_order: topologicalOrder,
    _has_bind_macro: hasBindMacro,
    _package_cells: packageCells,
  };

  return notebookData;
}

/**
 * Parse header section and extract notebook metadata
 * @param {string[]} lines - Array of file lines
 * @returns {Object} Object with notebookMetadata, firstCellIndex, and hasBindMacro
 */
function parseHeader(lines) {
  let notebookMetadata = {};
  let firstCellIndex = -1;
  let hasBindMacro = false;

  // Look for notebook metadata (lines starting with #>) and first cell
  for (let i = 2; i < lines.length; i++) {
    const line = lines[i];

    if (line.startsWith(CELL_ID_DELIMITER)) {
      firstCellIndex = i;
      break;
    }

    // Check if this line mentions @bind (crude check for now)
    if (line.includes("@bind")) {
      hasBindMacro = true;
    }
  }

  // Extract notebook metadata lines (simple approach - could be enhanced)
  const metadataLines = [];
  for (
    let i = 2;
    i < (firstCellIndex === -1 ? lines.length : firstCellIndex);
    i++
  ) {
    const line = lines[i];
    if (line.startsWith("#> ")) {
      metadataLines.push(line.slice(3)); // Remove "#> " prefix
    }
  }

  // Store raw metadata for serialization
  if (metadataLines.length > 0) {
    notebookMetadata._raw_metadata_lines = metadataLines;
  }

  return { notebookMetadata, firstCellIndex, hasBindMacro };
}

/**
 * Create default cell result structure
 * @param {string} cellId - Cell ID
 * @returns {Object} Default cell result object
 */
function createDefaultCellResult(cellId) {
  return {
    cell_id: cellId,
    queued: false,
    running: false,
    errored: false,
    runtime: null,
    downstream_cells_map: {},
    upstream_cells_map: {},
    precedence_heuristic: null,
    depends_on_disabled_cells: false,
    depends_on_skipped_cells: false,
    output: {
      body: "",
      persist_js_state: false,
      last_run_timestamp: 0,
      mime: "text/plain",
      rootassignee: null,
      has_pluto_hook_features: false,
    },
    logs: [],
    published_object_keys: [],
  };
}

/**
 * Parse cell metadata from lines
 * @param {string[]} lines - Array of file lines
 * @param {number} startIndex - Starting index
 * @returns {{metadata: Object, hasExplicitDisabledMetadata: boolean, endIndex: number}}
 */
function parseCellMetadata(lines, startIndex) {
  const metadata = { ...DEFAULT_CELL_METADATA };
  let hasExplicitDisabledMetadata = false;
  let i = startIndex;

  // Collect all metadata lines
  const metadataLines = [];
  while (i < lines.length && lines[i].startsWith(CELL_METADATA_PREFIX)) {
    const metadataLine = lines[i].slice(CELL_METADATA_PREFIX.length);
    metadataLines.push(metadataLine);
    i++;
  }

  // Parse TOML if we have any metadata lines
  if (metadataLines.length > 0) {
    try {
      const tomlString = metadataLines.join("\n");
      const parsed = tomlExports.parse(tomlString);

      // Apply parsed values to metadata
      if (parsed.disabled !== undefined) {
        metadata.disabled = parsed.disabled;
        hasExplicitDisabledMetadata = true;
      }
      if (parsed.show_logs !== undefined) {
        metadata.show_logs = parsed.show_logs;
      }
      if (parsed.skip_as_script !== undefined) {
        metadata.skip_as_script = parsed.skip_as_script;
      }

      // Store any other metadata fields
      for (const [key, value] of Object.entries(parsed)) {
        if (!["disabled", "show_logs", "skip_as_script"].includes(key)) {
          metadata[key] = value;
        }
      }
    } catch (e) {
      console.error("Failed to parse cell metadata TOML:", e);
      // Fall back to keeping default metadata
    }
  }

  return { metadata, hasExplicitDisabledMetadata, endIndex: i };
}

/**
 * Collect lines until the next cell delimiter
 * @param {string[]} lines - Array of file lines
 * @param {number} startIndex - Starting index
 * @returns {{code: string, endIndex: number}}
 */
function collectCellCode(lines, startIndex) {
  const codeLines = [];
  let i = startIndex;

  while (i < lines.length && !lines[i].startsWith(CELL_ID_DELIMITER)) {
    codeLines.push(lines[i]);
    i++;
  }

  let code = codeLines.join("\n");
  if (code.endsWith(CELL_SUFFIX)) {
    code = code.slice(0, -CELL_SUFFIX.length);
  }

  return { code: code.trimEnd(), endIndex: i };
}

/**
 * Parse cells from notebook content
 * @param {string[]} lines - Array of file lines
 * @param {number} startIndex - Index where cells start
 * @returns {Object} Object with cellInputs, cellResults, and topologicalOrder
 */
function parseCells(lines, startIndex) {
  const cellInputs = {};
  const cellResults = {};
  const topologicalOrder = []; // Track the order cells appear in the file
  const packageCells = {}; // Store package management cells separately

  let i = startIndex;

  while (i < lines.length) {
    const line = lines[i];

    // Check for cell order section
    if (line === CELL_ID_DELIMITER + "Cell order:") {
      break;
    }

    // Check for cell delimiter
    if (line.startsWith(CELL_ID_DELIMITER)) {
      const cellIdStr = line.slice(CELL_ID_DELIMITER.length);
      i++; // Move past cell delimiter

      // Handle special package cells differently
      if (cellIdStr === PTOML_CELL_ID || cellIdStr === MTOML_CELL_ID$1) {
        const { code, endIndex } = collectCellCode(lines, i);
        packageCells[cellIdStr] = code;
        i = endIndex;
        continue;
      }

      // Parse cell metadata (optional)
      const {
        metadata,
        hasExplicitDisabledMetadata,
        endIndex: metadataEndIndex,
      } = parseCellMetadata(lines, i);
      i = metadataEndIndex;

      // Collect cell code
      const { code: rawCode, endIndex } = collectCellCode(lines, i);
      i = endIndex;

      // Handle disabled cells
      let code = rawCode;
      const trimmedCode = rawCode.trim();
      const isDisabledByWrapper =
        trimmedCode.startsWith(DISABLED_PREFIX.trim()) &&
        trimmedCode.endsWith(DISABLED_SUFFIX.trim());
      if (isDisabledByWrapper) {
        code = rawCode.slice(
          rawCode.indexOf(DISABLED_PREFIX.trim()) + DISABLED_PREFIX.length,
          rawCode.lastIndexOf(DISABLED_SUFFIX.trim())
        );
        metadata.disabled = true;
        // If there was no explicit disabled metadata, this is an implicit disabled cell
        if (!hasExplicitDisabledMetadata) {
          metadata._implicit_disabled = true;
        }
      }

      // Create cell input data
      cellInputs[cellIdStr] = {
        cell_id: cellIdStr,
        code: code,
        code_folded: false, // Will be set during order parsing
        metadata: metadata,
      };

      // Create corresponding cell result data
      cellResults[cellIdStr] = createDefaultCellResult(cellIdStr);

      // Track topological order
      topologicalOrder.push(cellIdStr);
    } else {
      i++;
    }
  }

  return { cellInputs, cellResults, topologicalOrder, packageCells };
}

/**
 * Parse cell order from notebook content
 * @param {string[]} lines - Array of file lines
 * @param {Object} cellInputs - Cell inputs map to update folded state
 * @returns {string[]} Array of cell IDs in order
 */
function parseCellOrder(lines, cellInputs) {
  const cellOrder = [];

  // Find cell order section
  let orderStartIndex = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i] === CELL_ID_DELIMITER + "Cell order:") {
      orderStartIndex = i + 1;
      break;
    }
  }

  if (orderStartIndex === -1) {
    // If no explicit order, use the order cells appeared in file
    return Object.keys(cellInputs);
  }

  // Parse order lines
  for (let i = orderStartIndex; i < lines.length; i++) {
    const line = lines[i];

    if (
      line.startsWith(ORDER_DELIMITER) ||
      line.startsWith(ORDER_DELIMITER_FOLDED)
    ) {
      // Extract cell ID (last 36 characters should be the UUID)
      if (line.length >= 36) {
        const cellId = line.slice(-36);

        // Skip special package cells
        if (cellId === PTOML_CELL_ID || cellId === MTOML_CELL_ID$1) {
          continue;
        }

        // Check if cell exists
        if (cellInputs[cellId]) {
          // Set folded state
          cellInputs[cellId].code_folded = line.startsWith(
            ORDER_DELIMITER_FOLDED
          );
          cellOrder.push(cellId);
        }
      }
    }
  }

  return cellOrder;
}

/**
 * Generate a simple UUID (not cryptographically secure, for demo purposes)
 * @returns {string} UUID string
 */
function generateUUID() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Generate @bind macro lines
 * @returns {string[]} Array of lines for the @bind macro
 */
function generateBindMacro() {
  return [
    "",
    "# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).",
    "macro bind(def, element)",
    "    quote",
    '        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end',
    "        local el = $(esc(element))",
    "        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)",
    "        el",
    "    end",
    "end",
  ];
}

/**
 * Serialize cell metadata to lines
 * @param {Object} metadata - Cell metadata object
 * @returns {string[]} Array of metadata lines
 */
function serializeCellMetadata(metadata) {
  const tomlData = {};

  // Only serialize non-default values (excluding internal fields)
  if (metadata.disabled && !metadata._implicit_disabled) {
    tomlData.disabled = metadata.disabled;
  }
  if (
    metadata.show_logs !== undefined &&
    metadata.show_logs !== DEFAULT_CELL_METADATA.show_logs
  ) {
    tomlData.show_logs = metadata.show_logs;
  }
  if (
    metadata.skip_as_script !== undefined &&
    metadata.skip_as_script !== DEFAULT_CELL_METADATA.skip_as_script
  ) {
    tomlData.skip_as_script = metadata.skip_as_script;
  }

  // Add any other metadata fields (excluding internal fields starting with _)
  for (const [key, value] of Object.entries(metadata)) {
    if (
      !["disabled", "show_logs", "skip_as_script"].includes(key) &&
      !key.startsWith("_")
    ) {
      tomlData[key] = value;
    }
  }

  // Serialize to TOML and convert to lines
  if (Object.keys(tomlData).length > 0) {
    const tomlString = tomlExports.stringify(tomlData);
    return tomlString
      .split("\n")
      .filter((line) => line.trim() !== "")
      .map((line) => CELL_METADATA_PREFIX + line);
  }

  return [];
}

/**
 * Serialize NotebookData back to Pluto notebook file format
 * @param {import("../components/Editor.js").NotebookData} notebookData - NotebookData structure
 * @returns {string} Notebook file content
 */
function serialize(notebookData) {
  const lines = [];

  // Header
  lines.push(NOTEBOOK_HEADER);
  lines.push(`# ${notebookData.pluto_version || "v0.20.10"}`);
  lines.push("");

  // Notebook metadata
  if (notebookData.metadata && notebookData.metadata._raw_metadata_lines) {
    for (const metadataLine of notebookData.metadata._raw_metadata_lines) {
      lines.push("#> " + metadataLine);
    }
    lines.push("");
  }

  // Standard imports
  lines.push("using Markdown");
  lines.push("using InteractiveUtils");

  // Add @bind macro if needed
  if (notebookData._has_bind_macro) {
    lines.push(...generateBindMacro());
  }

  lines.push("");

  // Serialize cells in topological order (file order), not display order
  const topologicalOrder =
    notebookData._topological_order || notebookData.cell_order || [];
  const cellInputs = notebookData.cell_inputs || {};

  for (const cellId of topologicalOrder) {
    const cellInput = cellInputs[cellId];
    if (!cellInput) continue;

    // Cell delimiter
    lines.push(CELL_ID_DELIMITER + cellId);

    // Cell metadata (if not default)
    const metadata = cellInput.metadata || {};
    const metadataLines = serializeCellMetadata(metadata);
    lines.push(...metadataLines);

    // Cell code
    let code = cellInput.code || "";

    // Handle disabled cells - only add wrapper if not already present
    if (metadata.disabled && !code.startsWith(DISABLED_PREFIX)) {
      code = DISABLED_PREFIX + code + DISABLED_SUFFIX;
    }

    // Add code and suffix
    lines.push(code);
    lines.push("");
  }

  // Add package cells if they exist
  const packageCells = notebookData._package_cells || {};
  if (packageCells[PTOML_CELL_ID]) {
    lines.push(CELL_ID_DELIMITER + PTOML_CELL_ID);
    lines.push(packageCells[PTOML_CELL_ID]);
    lines.push("");
  }
  if (packageCells[MTOML_CELL_ID$1]) {
    lines.push(CELL_ID_DELIMITER + MTOML_CELL_ID$1);
    lines.push(packageCells[MTOML_CELL_ID$1]);
    lines.push("");
  }

  // Cell order section (display order)
  lines.push(CELL_ID_DELIMITER + "Cell order:");

  const cellOrder = notebookData.cell_order || [];
  for (const cellId of cellOrder) {
    const cellInput = cellInputs[cellId];
    if (!cellInput) continue;

    const delimiter = cellInput.code_folded
      ? ORDER_DELIMITER_FOLDED
      : ORDER_DELIMITER;
    lines.push(delimiter + cellId);
  }

  // Add package cells to order if they exist
  if (packageCells[PTOML_CELL_ID]) {
    lines.push(ORDER_DELIMITER_FOLDED + PTOML_CELL_ID);
  }
  if (packageCells[MTOML_CELL_ID$1]) {
    lines.push(ORDER_DELIMITER_FOLDED + MTOML_CELL_ID$1);
  }

  return lines.join("\n") + "\n";
}

/**
 * @fileoverview Converts Julia code from dyad codegen to Pluto notebook format
 *
 * This module provides functionality to transform plain Julia code into a complete
 * Pluto notebook structure with predefined package dependencies and execution helpers.
 * The generated notebooks include:
 * - Package management cell with standard scientific computing dependencies
 * - User code wrapped in a module cell for proper scoping
 * - Execution helper cell for interactive Pluto features
 *
 * @author Pluto.jl Frontend Team
 */


const MODULE_CELL_ID = "00000000-c0de-ce11-0000-000000000000";

const PKG_CELL_ID = "00000000-de95-ce11-0000-000000000000";
const PKG_CELL_CODE = `# Dyad·Pluto Notebook
begin
  using DyadEcosystemDependencies
  using DyadInterface
  using Plots, CSV, DataFrames

  using AbstractPlutoDingetjes
end`;

// Code that enables using pluto links and `worker.execute`
const EXECUTION_CELL_ID = "00000000-0000-0208-1991-000000000000";
const EXECUTION_CELL_ID_CODE = `begin
	function eval_in_pluto(x::String)
    try
		  id = PlutoRunner.moduleworkspace_count[]
		  new_workspace_name = Symbol("workspace#", id)
		  Core.eval(getproperty(Main, new_workspace_name), Meta.parse(x))
    catch
      return "failed to evaluate $x in latest module"
    end
	end
	AbstractPlutoDingetjes.Display.with_js_link(eval_in_pluto)
end`;

function from_dyadgen(code, defaultPackages = {}) {
  return serialize({
    cell_inputs: {
      [PKG_CELL_ID]: {
        cell_id: PKG_CELL_ID,
        code: PKG_CELL_CODE,
        code_folded: false,
        metadata: {
          disabled: false,
          show_logs: true,
          skip_as_script: false,
          name: "usings cell",
        },
      },
      [MODULE_CELL_ID]: {
        cell_id: MODULE_CELL_ID,
        code,
        code_folded: true,
        metadata: {
          disabled: false,
          show_logs: true,
          skip_as_script: false,
        },
      },
      [EXECUTION_CELL_ID]: {
        cell_id: EXECUTION_CELL_ID,
        code: EXECUTION_CELL_ID_CODE,
        code_folded: true,
        metadata: {
          disabled: false,
          show_logs: true,
          skip_as_script: false,
        },
      },
    },
    cell_order: [PKG_CELL_ID, MODULE_CELL_ID, EXECUTION_CELL_ID],
    _topological_order: [PKG_CELL_ID, MODULE_CELL_ID, EXECUTION_CELL_ID],
    _package_cells: {
      [MTOML_CELL_ID]: `PLUTO_MANIFEST_TOML_CONTENTS = """"""`,
      [PTOML_CELL_ID]: `PLUTO_PROJECT_TOML_CONTENTS = """
name = "DyadAnalysis"

[deps]
AbstractPlutoDingetjes = "6e696c72-6542-2067-7265-42206c756150"
${Object.entries(defaultPackages)
  .map(([name, { uuid }]) => `${name} = "${uuid}"`)
  .join("\n")}

[compat]
${
  defaultPackages.DyadEcosystemDependencies
    ? `DyadEcosystemDependencies = "${defaultPackages.DyadEcosystemDependencies.compat}"`
    : ""
}

[extras]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
"""`,
    },
  });
}

const packageReviseWorker = (packageName, path) => `### A Pluto.jl notebook ###
# v0.20.16

using Markdown
using InteractiveUtils

# ╔═╡ 7735b275-295d-42ce-8d17-19a10b494320
begin
    import Pkg
    Pkg.add("PlutoLinks")
    Pkg.add("Revise")
	Pkg.add("AbstractPlutoDingetjes")
    Pkg.develop(path="${path}")
	using PlutoLinks, Revise

    function 🪟(a)
        io = IOBuffer()
        show(io, a)
        return String(take!(io))
    end
end

# ╔═╡ 37f18ca2-d376-4dad-acb5-b21639355488
@revise using ${packageName}

# ╔═╡ 00000000-0000-0208-1991-000000000000
begin
    using AbstractPlutoDingetjes
	function eval_in_pluto(x::String)
		id = PlutoRunner.moduleworkspace_count[]
		new_workspace_name = Symbol("workspace#", id)
		Core.eval(getproperty(Main, new_workspace_name), Meta.parse(x))
	end
	AbstractPlutoDingetjes.Display.with_js_link(eval_in_pluto)
end

# ╔═╡ 17640727-380e-4c1b-8f0c-dbea48bb3098

# ╔═╡ Cell order:
# ╠═7735b275-295d-42ce-8d17-19a10b494320
# ╠═37f18ca2-d376-4dad-acb5-b21639355488
# ╠═17640727-380e-4c1b-8f0c-dbea48bb3098
# ╠═00000000-0000-0208-1991-000000000000`;

export { DEFAULT_CELL_METADATA, EXECUTION_CELL_ID, Host, MODULE_CELL_ID, MTOML_CELL_ID$1 as MTOML_CELL_ID, PKG_CELL_ID, PROGRESS_LOG_LEVEL, PTOML_CELL_ID, STDOUT_LOG_LEVEL, Worker$1 as Worker, from_dyadgen as from_julia, getMime, getOutput, getProgressLogs, getResult, getSnippetLogs, getStatus, getTerminalLogs, isTerminalStatus, packageReviseWorker, parse, resolveIncludes, serialize };
//# sourceMappingURL=index.esm.js.map
