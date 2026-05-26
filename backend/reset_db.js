'use strict';
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

(async () => {
  const client = await pool.connect();
  try {
    console.log('Dropping schema public CASCADE...');
    await client.query('DROP SCHEMA IF EXISTS public CASCADE');
    await client.query('CREATE SCHEMA public');
    await client.query('GRANT ALL ON SCHEMA public TO public');
    console.log('OK — schema public recriado, vazio.');
  } finally {
    client.release();
    pool.end();
  }
})().catch(e => { console.error(e.message); process.exit(1); });
