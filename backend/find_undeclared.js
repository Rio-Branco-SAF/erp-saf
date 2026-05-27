'use strict';
// Procura em cada arquivo do frontend padroes do tipo "setX(...)" sendo
// chamado dentro de uma funcao que NAO declara "[x, setX] = useState".
// Esses sao os bugs que crasham o page silenciosamente em React production.
const fs = require('fs');
const path = require('path');
const parser = require('@babel/parser');
const traverse = require('@babel/traverse').default;

const FRONT = path.join(__dirname, '..', 'frontend');
const PAGES = ['atletas','investidores','metas','jogos','pedidos','projetos','prospeccao','relatorios','financeiro','index'];

for (const page of PAGES) {
  const file = path.join(FRONT, page + '.html');
  const html = fs.readFileSync(file, 'utf8');
  const m = html.match(/<script[^>]*type=["']text\/babel["'][^>]*>([\s\S]*?)<\/script>/);
  if (!m) continue;
  const src = m[1];
  const scriptStart = html.slice(0, m.index).split('\n').length + 1;

  let ast;
  try {
    ast = parser.parse(src, { sourceType: 'script', plugins: ['jsx'] });
  } catch (e) {
    console.log(`${page.padEnd(15)} PARSE ERR: ${e.message.split('\n')[0]}`);
    continue;
  }

  // Walk: para cada FunctionDeclaration/Expression/ArrowFunction, coleta
  // todos os identificadores declarados (params, var/let/const, destructure)
  // e todos os identificadores REFERENCIADOS. Os referenciados que nao
  // existem no escopo da funcao OU em qualquer escopo pai sao suspeitos.
  const REACT_BUILTINS = new Set(['React','ReactDOM','useState','useEffect','useCallback','useMemo','useRef','useContext','useReducer','Fragment','console','window','document','localStorage','fetch','setTimeout','clearTimeout','setInterval','clearInterval','Promise','JSON','Date','Math','Number','String','Array','Object','Boolean','RegExp','Error','parseInt','parseFloat','isNaN','isFinite','URLSearchParams','URL','FormData','alert','confirm','prompt','undefined','null','true','false','this','arguments','Symbol','Map','Set','WeakMap','WeakSet']);

  const issues = [];

  traverse(ast, {
    Function(p) {
      const fnName = p.node.id?.name || (p.parent?.id?.name) || '<anon>';
      // Coleta identifiers declarados na funcao e em escopos pais
      const declared = new Set();
      let scope = p.scope;
      while (scope) {
        for (const k of Object.keys(scope.bindings)) declared.add(k);
        scope = scope.parent;
      }
      // tambem coleta nomes top-level (globals via let/var/const/function/class)
      ast.program.body.forEach(n => {
        if (n.type === 'VariableDeclaration') n.declarations.forEach(d => {
          if (d.id.type === 'Identifier') declared.add(d.id.name);
        });
        if (n.type === 'FunctionDeclaration' && n.id) declared.add(n.id.name);
        if (n.type === 'ClassDeclaration' && n.id) declared.add(n.id.name);
      });

      // Encontra setX( calls
      p.traverse({
        CallExpression(cp) {
          if (cp.node.callee.type === 'Identifier') {
            const name = cp.node.callee.name;
            if (/^set[A-Z]/.test(name) && !declared.has(name) && !REACT_BUILTINS.has(name)) {
              const lineInScript = cp.node.loc.start.line;
              const fileLine = scriptStart + lineInScript - 1;
              issues.push(`fn=${fnName} line=${fileLine} CALL ${name}() undeclared`);
            }
          }
        }
      });
    }
  });

  if (issues.length === 0) {
    console.log(`${page.padEnd(15)} OK`);
  } else {
    console.log(`${page.padEnd(15)} ${issues.length} issues:`);
    [...new Set(issues)].forEach(i => console.log('   ' + i));
  }
}
