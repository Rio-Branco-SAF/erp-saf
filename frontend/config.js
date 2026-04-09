// ============================================================
// ERP SAF — Configuração de Ambiente
//
// ⚠️  ANTES DO DEPLOY:
//   1. Faça deploy do backend no Railway
//   2. Copie a URL pública gerada pelo Railway
//   3. Substitua o valor de API_URL abaixo
//   4. Exemplo: https://erp-saf-production.up.railway.app
//   5. Faça commit e push → Netlify republicará automaticamente
//
// EM DESENVOLVIMENTO: troque para http://localhost:3001
// ============================================================
window.ERP_CONFIG = {
  // URL do backend no Railway:
  API_URL: "https://backend-production-7c51.up.railway.app",

  // Nome da SAF (aparece na tela de login e no topo do sistema)
  NOME_SAF: "SAF — Sistema de Gestão",

  // Versão do sistema
  VERSAO: "1.0.0",
};
