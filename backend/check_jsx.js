'use strict';
// Extrai os <script type="text/babel"> de cada HTML do frontend e tenta
// transformar via @babel/standalone (mesmo que o browser usa). Erros de
// parsing aparecem aqui mesmo (e não vão acontecer no console do user).
const fs = require('fs');
const path = require('path');
const babel = require('@babel/core');
const preset = require('@babel/preset-react');

const FRONT = path.join(__dirname, '..', 'frontend');
const files = ['atletas.html','investidores.html','metas.html','jogos.html',
               'pedidos.html','projetos.html','prospeccao.html','relatorios.html',
               'financeiro.html','index.html'];

for (const file of files) {
  const html = fs.readFileSync(path.join(FRONT, file), 'utf8');
  const m = html.match(/<script[^>]*type=["']text\/babel["'][^>]*>([\s\S]*?)<\/script>/);
  if (!m) { console.log(`${file.padEnd(22)} NO BABEL SCRIPT`); continue; }
  const src = m[1];
  try {
    babel.transformSync(src, { presets: [preset], filename: file });
    console.log(`${file.padEnd(22)} OK (${src.length} chars)`);
  } catch (e) {
    const line = (e.loc && e.loc.line) || '?';
    const col = (e.loc && e.loc.column) || '?';
    console.log(`${file.padEnd(22)} ERRO L${line}:${col} ${e.message.split('\n')[0]}`);
  }
}
