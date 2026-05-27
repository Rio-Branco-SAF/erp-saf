'use strict';
const fs = require('fs');
const path = require('path');

const file = process.argv[2] || path.join(__dirname, '..', 'frontend', 'jogos.html');
const html = fs.readFileSync(file, 'utf8');

// Pega só o conteúdo do script type=text/babel
const m = html.match(/<script[^>]*type=["']text\/babel["'][^>]*>([\s\S]*?)<\/script>/);
if (!m) { console.error('No babel script'); process.exit(2); }
const src = m[1];
const scriptStartLine = html.slice(0, m.index).split('\n').length + 1;

// Stack-based scan procurando div abertura/fechamento.
// Ignora dentro de strings JSX (mas é simples; pode ter falsos positivos).
const re = /<(\/)?div\b([^>]*)>/g;
const stack = [];
let match;
while ((match = re.exec(src)) !== null) {
  const isClose = match[1] === '/';
  const attrs = match[2];
  const selfClose = attrs && attrs.trim().endsWith('/');
  const pos = match.index;
  const lineInScript = src.slice(0, pos).split('\n').length;
  const fileLine = scriptStartLine + lineInScript - 1;
  if (isClose) {
    if (stack.length === 0) {
      console.log(`UNMATCHED </div> at file line ${fileLine}`);
    } else {
      stack.pop();
    }
  } else if (!selfClose) {
    stack.push({ fileLine, snippet: src.slice(pos, pos + 100).replace(/\n/g, ' ').slice(0, 80) });
  }
}
console.log(`\nDivs abertas sem fechamento (${stack.length}):`);
stack.forEach(s => console.log(`  line ${s.fileLine}: ${s.snippet}`));
