'use strict';
// Carrega cada HTML do frontend num jsdom e captura qualquer erro de
// runtime que aconteceria no browser.
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole, ResourceLoader } = require('jsdom');

const FRONT = path.join(__dirname, '..', 'frontend');
const PAGES = ['atletas','investidores','metas','jogos','pedidos','projetos'];

// ResourceLoader que intercepta requests pros CDNs do React/Babel
// e serve as cópias locais (jsdom falha ao baixar via rede).
const NM = path.join(__dirname, '..', 'node_modules');
const BABEL_LOCAL = path.join(NM, '@babel/standalone/babel.min.js');
const REACT_LOCAL = path.join(NM, 'react/umd/react.development.js');
const RDOM_LOCAL  = path.join(NM, 'react-dom/umd/react-dom.development.js');

class LocalLoader extends ResourceLoader {
  fetch(url, opts) {
    let local = null;
    if (/babel(\.min)?\.js$/.test(url) || /babel\/standalone/.test(url)) local = BABEL_LOCAL;
    else if (/react(\.production\.min|\.development)?\.js$/.test(url)) local = REACT_LOCAL;
    else if (/react-dom(\.production\.min|\.development)?\.js$/.test(url)) local = RDOM_LOCAL;
    if (local && fs.existsSync(local)) return Promise.resolve(fs.readFileSync(local));
    return super.fetch(url, opts);
  }
}

(async () => {
  for (const page of PAGES) {
    const file = path.join(FRONT, page + '.html');
    const errors = [];
    const vc = new VirtualConsole();
    vc.on('jsdomError', e => errors.push('jsdom: '+ (e.detail ? e.detail.toString() : e.message)));
    vc.on('error', m => errors.push('error: '+ m));
    try {
      const dom = await JSDOM.fromFile(file, {
        runScripts: 'dangerously',
        resources: new LocalLoader(),
        virtualConsole: vc,
        url: 'https://erp-saf-three.vercel.app/' + page + '.html',
        pretendToBeVisual: true,
      });
      await new Promise(r => setTimeout(r, 2500));
      const root = dom.window.document.getElementById('root');
      const rendered = root ? root.innerHTML.length : 0;
      console.log(`${page.padEnd(15)} rendered=${rendered} chars  errors=${errors.length}`);
      errors.slice(0,3).forEach(e => console.log('   '+ e.slice(0,200)));
      dom.window.close();
    } catch (e) {
      console.log(`${page.padEnd(15)} JSDOM_FATAL: ${e.message.slice(0,200)}`);
    }
  }
})();
