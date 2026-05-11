import assert from "node:assert/strict";
import test from "node:test";
import {
  element_dispatch_mhx_event,
  element_dispatch_swap_event,
  element_insert_adjacent_html,
  element_remove,
  element_set_inner_html,
  element_set_outer_html,
} from "../../src/ffi/mhx_ffi.js";

class FixtureElement {
  constructor() {
    this.innerHTML = "<old>content</old>";
    this.outerHTML = "<section id=\"target\"><old>content</old></section>";
    this.removed = false;
    this.insertions = [];
    this.events = [];
  }

  insertAdjacentHTML(position, html) {
    this.insertions.push({ position, html });
  }

  remove() {
    this.removed = true;
  }

  dispatchEvent(event) {
    this.events.push(event);
    return true;
  }
}

globalThis.CustomEvent = class CustomEvent {
  constructor(type, init = {}) {
    this.type = type;
    this.detail = init.detail;
    this.bubbles = Boolean(init.bubbles);
    this.cancelable = Boolean(init.cancelable);
  }
};

test("swap DOM primitive contract covers all strategies", () => {
  const response = "<p>new</p>";

  const inner = new FixtureElement();
  element_set_inner_html(inner, response);
  assert.equal(inner.innerHTML, response);

  const outer = new FixtureElement();
  element_set_outer_html(outer, response);
  assert.equal(outer.outerHTML, response);

  for (const position of [
    "beforebegin",
    "afterbegin",
    "beforeend",
    "afterend",
  ]) {
    const target = new FixtureElement();
    element_insert_adjacent_html(target, position, response);
    assert.deepEqual(target.insertions, [{ position, html: response }]);
    assert.equal(target.innerHTML, "<old>content</old>");
    assert.equal(target.outerHTML, "<section id=\"target\"><old>content</old></section>");
  }

  const deleted = new FixtureElement();
  element_remove(deleted);
  assert.equal(deleted.removed, true);
  assert.equal(deleted.innerHTML, "<old>content</old>");

  const none = new FixtureElement();
  assert.equal(none.innerHTML, "<old>content</old>");
  assert.equal(none.outerHTML, "<section id=\"target\"><old>content</old></section>");
  assert.equal(none.removed, false);
  assert.deepEqual(none.insertions, []);
});

test("swap lifecycle event names and details are stable", () => {
  const source = new FixtureElement();

  assert.equal(
    element_dispatch_swap_event(
      source,
      "swapping",
      "click",
      "outerHTML",
      "button#save",
      "section#target",
    ),
    "",
  );
  assert.equal(
    element_dispatch_swap_event(
      source,
      "completed",
      "click",
      "outerHTML",
      "button#save",
      "section#target",
    ),
    "",
  );
  assert.deepEqual(
    source.events.map((event) => ({
      type: event.type,
      bubbles: event.bubbles,
      cancelable: event.cancelable,
      detail: event.detail,
    })),
    [
      {
        type: "mhx:beforeSwap",
        bubbles: true,
        cancelable: false,
        detail: {
          phase: "swapping",
          trigger: "click",
          strategy: "outerHTML",
          sourceElement: "button#save",
          target: "section#target",
        },
      },
      {
        type: "mhx:afterSwap",
        bubbles: true,
        cancelable: false,
        detail: {
          phase: "completed",
          trigger: "click",
          strategy: "outerHTML",
          sourceElement: "button#save",
          target: "section#target",
        },
      },
    ],
  );
});

test("missing target errors use structured mhx:error detail", () => {
  const source = new FixtureElement();
  const detail = {
    error: {
      category: "selector",
      code: "MHX_SELECTOR_TARGET_NOT_FOUND",
      message: "No DOM element matched the requested swap target",
    },
    sourceElement: "button#save",
  };

  assert.equal(
    element_dispatch_mhx_event(source, "mhx:error", JSON.stringify(detail)),
    "",
  );

  assert.deepEqual(
    source.events.map((event) => ({
      type: event.type,
      bubbles: event.bubbles,
      cancelable: event.cancelable,
      detail: event.detail,
    })),
    [
      {
        type: "mhx:error",
        bubbles: true,
        cancelable: false,
        detail,
      },
    ],
  );
});
