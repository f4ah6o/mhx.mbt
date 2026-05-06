import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";
import { pathToFileURL } from "node:url";
import vm from "node:vm";

const root = process.cwd();
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));

class FakeElement {
  constructor(tagName = "DIV", id = "") {
    this.tagName = tagName;
    this.id = id;
    this.children = [];
    this.attributes = new Map();
    this.classList = {
      add() {},
      remove() {},
      toggle() {
        return false;
      },
      contains() {
        return false;
      },
    };
    this.parentElement = null;
    this.innerHTML = "";
    this.outerHTML = `<${tagName.toLowerCase()}></${tagName.toLowerCase()}>`;
    this.textContent = "";
    this.value = "";
  }

  appendChild(child) {
    child.parentElement = this;
    this.children.push(child);
  }

  getAttribute(name) {
    return this.attributes.get(name) ?? "";
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  hasAttribute(name) {
    return this.attributes.has(name);
  }

  querySelector() {
    return null;
  }

  closest() {
    return null;
  }

  matches() {
    return false;
  }

  insertAdjacentHTML(_position, html) {
    this.innerHTML += html;
  }

  remove() {}
  focus() {}
  blur() {}
  dispatchEvent() {
    return true;
  }
}

class FakeMutationObserver {
  constructor() {}
  observe() {}
  disconnect() {}
}

function installGlobals(target) {
  const body = new FakeElement("BODY");
  const documentElement = new FakeElement("HTML");
  documentElement.appendChild(body);
  target.console = console;
  target.setTimeout = setTimeout;
  target.clearTimeout = clearTimeout;
  target.setInterval = setInterval;
  target.clearInterval = clearInterval;
  target.fetch = async () => ({
    ok: true,
    status: 200,
    statusText: "OK",
    redirected: false,
    url: "https://example.invalid/",
    headers: { get: () => "", has: () => false },
    text: async () => "",
    json: async () => ({}),
  });
  target.AbortController = globalThis.AbortController;
  target.FormData = class FormData {
    constructor() {}
    append() {}
  };
  target.URLSearchParams = globalThis.URLSearchParams;
  target.MutationObserver = FakeMutationObserver;
  target.CustomEvent = class CustomEvent {
    constructor(type, init = {}) {
      this.type = type;
      this.detail = init.detail;
      this.bubbles = Boolean(init.bubbles);
      this.cancelable = Boolean(init.cancelable);
    }
  };
  target.document = {
    body,
    head: new FakeElement("HEAD"),
    documentElement,
    title: "",
    URL: "https://example.invalid/",
    activeElement: body,
    addEventListener() {},
    querySelector() {
      return null;
    },
    querySelectorAll() {
      return [];
    },
    getElementById() {
      return null;
    },
    createElement(tag) {
      return new FakeElement(tag.toUpperCase());
    },
  };
  target.location = { href: "https://example.invalid/" };
  target.history = {
    pushState() {},
    replaceState() {},
    back() {},
    forward() {},
  };
  target.window = target;
  target.globalThis = target;
  target.self = target;
}

test("esm export contract", async () => {
  installGlobals(globalThis);
  const mod = await import(
    `${pathToFileURL(join(root, "dist", "mhx.esm.js")).href}?t=${Date.now()}`
  );

  assert.equal(typeof mod.default, "object");
  assert.equal(typeof mod.init_mhx, "function");
  assert.equal(typeof mod.process, "function");
  assert.equal(typeof mod.handle_event, "function");
  assert.equal(mod.version, packageJson.version);
  assert.equal(mod.default.version, packageJson.version);
  assert.ok(!("on_fetch_success" in mod));
  assert.ok(!("on_fetch_error" in mod));
  assert.ok(!("on_mutation_observed" in mod));
  assert.ok(!("get_instance" in mod));
});

test("umd global contract", async () => {
  const code = readFileSync(join(root, "dist", "mhx.umd.js"), "utf8");
  const context = {};
  installGlobals(context);
  vm.createContext(context);
  vm.runInContext(code, context);

  assert.equal(typeof context.mhx, "object");
  assert.equal(typeof context.mhx.init_mhx, "function");
  assert.equal(typeof context.mhx.process, "function");
  assert.equal(typeof context.mhx.handle_event, "function");
  assert.equal(context.mhx.version, packageJson.version);
  assert.ok(!("on_fetch_success" in context.mhx));
  assert.ok(!("on_fetch_error" in context.mhx));
  assert.ok(!("on_mutation_observed" in context.mhx));
  assert.ok(!("get_instance" in context.mhx));
});
