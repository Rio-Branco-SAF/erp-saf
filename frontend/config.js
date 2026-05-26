// ============================================================
// ERP SAF — Configuração de Ambiente
//
// Backend e frontend estão no MESMO projeto Vercel.
// A API é exposta em /api/* via serverless function (api/index.js).
// Por isso usamos URL relativa: sem CORS, sem subdomínio extra.
//
// Em desenvolvimento local, rode o backend em http://localhost:3001
// e troque API_URL para "http://localhost:3001/api".
// ============================================================
window.ERP_CONFIG = {
  API_URL: "/api",

  NOME_SAF: "Rio Branco SAF — Sistema de Gestão",

  VERSAO: "1.0.0",
};
