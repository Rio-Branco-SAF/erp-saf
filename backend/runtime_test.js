'use strict';
const fs = require('fs');
const path = require('path');
const babel = require('@babel/core');
const preset = require('@babel/preset-react');
const vm = require('vm');

const FRONT = path.join(__dirname, '..', 'frontend');
const PAGES = ['atletas','investidores','metas','jogos','pedidos','projetos'];

// Mock minimo de React que coleta TODAS as chamadas para detectar
// erros de referencia durante a inicializacao do modulo.
function makeMockReact() {
  const useState = (init) => [typeof init === 'function' ? init() : init, () => {}];
  const useEffect = () => {};
  const useCallback = (fn) => fn;
  const useMemo = (fn) => fn();
  const useRef = (init) => ({ current: init });
  const useContext = () => ({});
  const useReducer = (r, init) => [init, () => {}];
  const createElement = (...args) => ({ type: args[0], props: args[1], children: args.slice(2) });
  const Fragment = Symbol('Fragment');
  return {
    useState, useEffect, useCallback, useMemo, useRef, useContext, useReducer,
    createElement, Fragment,
  };
}

for (const page of PAGES) {
  const file = path.join(FRONT, page + '.html');
  const html = fs.readFileSync(file, 'utf8');
  const m = html.match(/<script[^>]*type=["']text\/babel["'][^>]*>([\s\S]*?)<\/script>/);
  if (!m) { console.log(`${page.padEnd(15)} SKIP (no babel script)`); continue; }
  let compiled;
  try {
    compiled = babel.transformSync(m[1], { presets: [preset], filename: page }).code;
  } catch (e) {
    console.log(`${page.padEnd(15)} BABEL ERROR: ${e.message.split('\n')[0]}`);
    continue;
  }

  // Tenta executar o modulo top-level. Falhas aqui pegam reference errors
  // em definicoes de componente / variaveis globais do script.
  const sandbox = {
    React: makeMockReact(),
    ReactDOM: {
      createRoot: () => ({ render: () => {} }),
    },
    window: { ERP_CONFIG: { API_URL: '/api' }, location: { href: '' } },
    document: { getElementById: () => ({}) },
    localStorage: { getItem: () => null, setItem: () => {}, removeItem: () => {} },
    console: { log: () => {}, error: () => {}, warn: () => {} },
    fetch: () => Promise.resolve({ json: () => ({}), ok: true }),
    setTimeout, clearTimeout, setInterval, clearInterval,
    Promise, JSON, Date, Math, Number, String, Array, Object, parseInt, parseFloat,
    URLSearchParams, FormData: function(){}, URL: function(){},
    alert: () => {},
  };

  try {
    vm.createContext(sandbox);
    vm.runInContext(compiled, sandbox, { timeout: 3000 });
    console.log(`${page.padEnd(15)} OK (module initializes)`);
  } catch (e) {
    console.log(`${page.padEnd(15)} RUNTIME ERROR: ${e.message.split('\n')[0]}`);
  }
}
