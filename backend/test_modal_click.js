'use strict';
// Carrega index.html, faz login fake (token no localStorage), aguarda
// React montar, simula clique em "+ Novo Funcionário" e captura erros.
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const FRONT = path.join(__dirname, '..', 'frontend');
const NM = path.join(__dirname, '..', 'node_modules');
const REACT_JS = fs.readFileSync(NM + '/react/umd/react.development.js', 'utf8');
const RDOM_JS  = fs.readFileSync(NM + '/react-dom/umd/react-dom.development.js', 'utf8');
const BABEL_JS = fs.readFileSync(NM + '/@babel/standalone/babel.min.js', 'utf8');

(async () => {
  const erros = [];
  const vc = new VirtualConsole();
  vc.on('jsdomError', e => erros.push(String(e.detail || e.message).slice(0,400)));
  vc.on('error',    m => erros.push('error: '+String(m).slice(0,400)));

  // Le HTML e substitui os scripts CDN por inline
  let html = fs.readFileSync(path.join(FRONT, 'index.html'), 'utf8');
  html = html.replace(/<script[^>]*src="[^"]*react-dom[^"]*"[^>]*><\/script>/, '<script>' + RDOM_JS + '</script>');
  html = html.replace(/<script[^>]*src="[^"]*react[^"]*\.js"[^>]*><\/script>/, '<script>' + REACT_JS + '</script>');
  html = html.replace(/<script[^>]*src="[^"]*babel[^"]*"[^>]*><\/script>/, '<script>' + BABEL_JS + '</script>');

  const dom = new JSDOM(html, {
    runScripts: 'dangerously',
    virtualConsole: vc, pretendToBeVisual: true,
    url: 'https://erp-saf-three.vercel.app/index.html',
    beforeParse(win) {
      // Mocka localStorage com token/user
      win.localStorage.setItem('erp_access', 'fake-token');
      win.localStorage.setItem('erp_user', JSON.stringify({id:1,nome:'Admin',email:'ceo@saf.com.br',perfil:'admin'}));
      // Mocka fetch pra retornar respostas vazias
      win.fetch = async (url) => ({
        ok: true, status: 200,
        json: async () => {
          if (/\/funcionarios\/resumo/.test(url)) return {ativos:"0",clt:"0",pj:"0",ferias:"0",afastados:"0",folha_mensal:"0",total:"0"};
          if (/\/funcionarios\/aux\/departamentos/.test(url)) return [];
          if (/\/funcionarios/.test(url)) return {dados:[],total:0};
          if (/\/auth\/me/.test(url)) return {usuario:{id:1,nome:'Admin',perfil:'admin'}};
          return [];
        }
      });
    }
  });
  await new Promise(r => setTimeout(r, 4000));

  const win = dom.window;
  const root = win.document.getElementById('root');
  console.log('root content size:', root?.innerHTML.length || 0);

  // Tenta clicar no botão "Novo Funcionário"
  const btns = [...win.document.querySelectorAll('button')];
  const novoBtn = btns.find(b => /novo funcion/i.test(b.textContent));
  if (novoBtn) {
    console.log('Achou botao "Novo Funcionario", clicando...');
    novoBtn.click();
    await new Promise(r => setTimeout(r, 1500));
    const root2 = win.document.getElementById('root');
    console.log('root depois do clique:', root2?.innerHTML.length || 0);
  } else {
    console.log('Nao achou botao Novo Funcionario (modulo nao montou?)');
  }

  console.log('\n=== ERROS CAPTURADOS ===');
  erros.slice(0, 10).forEach(e => console.log('-', e));
  if (erros.length === 0) console.log('(nenhum)');
  dom.window.close();
})().catch(e => { console.error('JSDOM_FATAL:', e.message); process.exit(1); });
