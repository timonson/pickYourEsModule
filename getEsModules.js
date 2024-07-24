import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.46/deno-dom-wasm.ts";

const file = Deno.args[0];

// Create a global window object using DOMParser
const window = new DOMParser().parseFromString(
  "<!DOCTYPE html><html><body></body></html>",
  "text/html",
);

// Mock global objects
globalThis.document = window;
globalThis.window = window;
globalThis.location = new URL("https://zaubrik.de");
globalThis.HTMLElement = class {
  constructor() {
    this.style = {};
  }
};
globalThis.window.customElements = {};
globalThis.window.customElements.define = function () {
  return;
};

import(file)
  .then((module) => {
    const modulesString = Object.entries(module)
      .reduce((acc, [key, value]) => {
        acc += key === "default" ? `${value.name} (default)\n` : `${key}\n`;
        return acc;
      }, "")
      .trim();
    console.log(modulesString);
  })
  .catch((err) => {
    console.log(err);
  });
