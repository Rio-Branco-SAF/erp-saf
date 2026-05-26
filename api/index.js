// Entry point para a Vercel: importa o app Express do backend e
// exporta como serverless function. Todas as requisições /api/* (e
// subrotas) são handleadas por este arquivo via vercel.json.
module.exports = require('../backend/server.js');
