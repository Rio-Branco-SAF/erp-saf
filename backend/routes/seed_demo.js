/**
 * ERP SAF — Endpoint temporário para popular banco com dados demo
 * REMOVER após uso!
 */
const express = require('express');
const pool    = require('../config/database');
const fs      = require('fs');
const path    = require('path');

const router = express.Router();

// GET /api/seed-demo — executa todos os seeds de módulos
router.get('/', async (req, res) => {
  // Proteção básica
  const secret = req.query.secret;
  if (secret !== process.env.SEED_SECRET && secret !== 'saf2026seed') {
    return res.status(403).json({ erro: 'Não autorizado' });
  }

  const results = {};
  const seeds = [
    'schema_scout.sql',
    'seed_pedidos.sql',
    'seed_atletas.sql',
    'seed_financeiro.sql',
    'seed_investidores.sql',
    'seed_metas.sql',
    'seed_jogos.sql',
  ];

  for (const seedFile of seeds) {
    const filePath = path.join(__dirname, '../db', seedFile);
    if (!fs.existsSync(filePath)) {
      results[seedFile] = 'arquivo não encontrado';
      continue;
    }
    try {
      const sql = fs.readFileSync(filePath, 'utf8');
      await pool.query(sql);
      results[seedFile] = '✅ ok';
    } catch (err) {
      results[seedFile] = `⚠️ ${err.message.slice(0, 100)}`;
    }
  }

  return res.json({
    mensagem: 'Seeds executados',
    resultados: results,
  });
});

module.exports = router;
