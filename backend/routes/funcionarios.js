const express = require('express');
const pool    = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');

const router = express.Router();

// Todos os endpoints exigem login
router.use(autenticar);

// ============================================================
// GET /api/funcionarios
// Lista todos com filtros, busca e paginação
// Query params: busca, departamento_id, tipo_contrato, status, pagina, limite
// ============================================================
router.get('/', async (req, res) => {
  try {
    const {
      busca        = '',
      departamento_id,
      tipo_contrato,
      status,
      pagina  = 1,
      limite  = 20,
    } = req.query;

    const params  = [];
    const filtros = [];
    let   i       = 1;

    if (busca) {
      filtros.push(`(
        f.nome_completo ILIKE $${i} OR
        f.cargo         ILIKE $${i} OR
        f.email         ILIKE $${i} OR
        f.cpf           ILIKE $${i}
      )`);
      params.push(`%${busca}%`);
      i++;
    }

    if (departamento_id) {
      filtros.push(`f.departamento_id = $${i++}`);
      params.push(departamento_id);
    }

    if (tipo_contrato) {
      filtros.push(`f.tipo_contrato = $${i++}`);
      params.push(tipo_contrato);
    }

    if (status) {
      filtros.push(`f.status = $${i++}`);
      params.push(status);
    }

    const where = filtros.length > 0 ? 'WHERE ' + filtros.join(' AND ') : '';

    // Total de registros para paginação
    const totalRes = await pool.query(
      `SELECT COUNT(*) FROM funcionarios f ${where}`,
      params
    );
    const total = parseInt(totalRes.rows[0].count);

    // Dados paginados
    const offset = (parseInt(pagina) - 1) * parseInt(limite);
    params.push(parseInt(limite), offset);

    const resultado = await pool.query(
      `SELECT
         f.id, f.nome_completo, f.email, f.email_corporativo,
         f.telefone, f.cargo, f.tipo_contrato, f.salario,
         f.data_admissao, f.status, f.foto_url,
         d.nome AS departamento, d.id AS departamento_id,
         g.nome_completo AS gestor_nome
       FROM funcionarios f
       JOIN departamentos d ON d.id = f.departamento_id
       LEFT JOIN funcionarios g ON g.id = f.gestor_id
       ${where}
       ORDER BY f.status ASC, f.nome_completo ASC
       LIMIT $${i} OFFSET $${i+1}`,
      params
    );

    res.json({
      dados:       resultado.rows,
      total,
      pagina:      parseInt(pagina),
      limite:      parseInt(limite),
      totalPaginas: Math.ceil(total / parseInt(limite)),
    });

  } catch (err) {
    console.error('Erro ao listar funcionários:', err);
    res.status(500).json({ erro: 'Erro ao buscar funcionários.' });
  }
});

// ============================================================
// GET /api/funcionarios/resumo
// Totais para o dashboard
// ============================================================
router.get('/resumo', async (req, res) => {
  try {
    const resultado = await pool.query(`
      SELECT
        COUNT(*)                                                  AS total,
        COUNT(*) FILTER (WHERE status = 'ativo')                 AS ativos,
        COUNT(*) FILTER (WHERE status = 'ferias')                AS ferias,
        COUNT(*) FILTER (WHERE status = 'afastado')              AS afastados,
        COUNT(*) FILTER (WHERE status = 'desligado')             AS desligados,
        COUNT(*) FILTER (WHERE tipo_contrato = 'CLT')            AS clt,
        COUNT(*) FILTER (WHERE tipo_contrato = 'PJ')             AS pj,
        COALESCE(SUM(salario) FILTER (WHERE status = 'ativo'), 0) AS folha_mensal
      FROM funcionarios
    `);

    const porDepartamento = await pool.query(`
      SELECT d.nome AS departamento, COUNT(f.id) AS total,
             COALESCE(SUM(f.salario), 0) AS folha
      FROM departamentos d
      LEFT JOIN funcionarios f ON f.departamento_id = d.id AND f.status = 'ativo'
      GROUP BY d.id, d.nome
      ORDER BY total DESC
    `);

    res.json({
      ...resultado.rows[0],
      por_departamento: porDepartamento.rows,
    });

  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar resumo.' });
  }
});

// ============================================================
// GET /api/funcionarios/:id
// Busca um funcionário completo (com histórico de salários)
// ============================================================
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const funcRes = await pool.query(
      `SELECT
         f.*,
         d.nome AS departamento,
         g.nome_completo AS gestor_nome,
         EXTRACT(YEAR FROM AGE(NOW(), f.data_admissao))::INTEGER AS anos_casa
       FROM funcionarios f
       JOIN departamentos d ON d.id = f.departamento_id
       LEFT JOIN funcionarios g ON g.id = f.gestor_id
       WHERE f.id = $1`,
      [id]
    );

    if (funcRes.rows.length === 0) {
      return res.status(404).json({ erro: 'Funcionário não encontrado.' });
    }

    const historicoRes = await pool.query(
      `SELECT h.*, reg.nome_completo AS registrado_por_nome
       FROM historico_salarios h
       LEFT JOIN funcionarios reg ON reg.id = h.registrado_por
       WHERE h.funcionario_id = $1
       ORDER BY h.data_alteracao DESC`,
      [id]
    );

    const documentosRes = await pool.query(
      `SELECT * FROM documentos_funcionarios WHERE funcionario_id = $1 ORDER BY data_upload DESC`,
      [id]
    );

    res.json({
      ...funcRes.rows[0],
      historico_salarios: historicoRes.rows,
      documentos:         documentosRes.rows,
    });

  } catch (err) {
    console.error('Erro ao buscar funcionário:', err);
    res.status(500).json({ erro: 'Erro ao buscar funcionário.' });
  }
});

// ============================================================
// POST /api/funcionarios
// Cria um novo funcionário (apenas admin e rh)
// ============================================================
router.post('/', autorizarPerfis('admin', 'rh'), async (req, res) => {
  const {
    nome_completo, cpf, rg, data_nascimento, email, email_corporativo,
    telefone, endereco, cargo, departamento_id, tipo_contrato, salario,
    data_admissao, gestor_id, cnpj, razao_social, observacoes,
  } = req.body;

  // Validações básicas
  if (!nome_completo || !cargo || !departamento_id || !tipo_contrato || !salario || !data_admissao) {
    return res.status(400).json({
      erro: 'Campos obrigatórios faltando: nome_completo, cargo, departamento_id, tipo_contrato, salario, data_admissao.'
    });
  }

  if (!['CLT', 'PJ'].includes(tipo_contrato)) {
    return res.status(400).json({ erro: 'tipo_contrato deve ser CLT ou PJ.' });
  }

  if (tipo_contrato === 'PJ' && !cnpj) {
    return res.status(400).json({ erro: 'CNPJ é obrigatório para contratos PJ.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const resultado = await client.query(
      `INSERT INTO funcionarios
         (nome_completo, cpf, rg, data_nascimento, email, email_corporativo,
          telefone, endereco, cargo, departamento_id, tipo_contrato, salario,
          data_admissao, gestor_id, cnpj, razao_social, observacoes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
       RETURNING *`,
      [
        nome_completo, cpf || null, rg || null, data_nascimento || null,
        email || null, email_corporativo || null, telefone || null,
        endereco || null, cargo, departamento_id, tipo_contrato,
        parseFloat(salario), data_admissao, gestor_id || null,
        cnpj || null, razao_social || null, observacoes || null,
      ]
    );

    const novoFunc = resultado.rows[0];

    // Registra o salário inicial no histórico
    await client.query(
      `INSERT INTO historico_salarios (funcionario_id, salario_anterior, salario_novo, data_alteracao, motivo, registrado_por)
       VALUES ($1, NULL, $2, $3, 'Admissão', $4)`,
      [novoFunc.id, parseFloat(salario), data_admissao, req.usuario.funcionario_id]
    );

    await client.query('COMMIT');

    res.status(201).json({
      mensagem: 'Funcionário cadastrado com sucesso.',
      funcionario: novoFunc,
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro ao criar funcionário:', err);

    if (err.code === '23505') { // unique violation
      return res.status(409).json({ erro: 'CPF ou e-mail já cadastrado no sistema.' });
    }

    res.status(500).json({ erro: 'Erro ao cadastrar funcionário.' });
  } finally {
    client.release();
  }
});

// ============================================================
// PUT /api/funcionarios/:id
// Atualiza dados de um funcionário
// Se n salário mudar, registra no histórico automaticamente
// ============================================================
router.put('/:id', autorizarPerfis('admin', 'rh'), async (req, res) => {
  const { id } = req.params;
  const {
    nome_completo, cpf, rg, data_nascimento, email, email_corporativo,
    telefone, endereco, cargo, departamento_id, tipo_contrato, salario,
    data_admissao, gestor_id, cnpj, razao_social, status, observacoes,
    motivo_alteracao_salario,
  } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Busca salário atual para comparar
    const atualRes = await client.query('SELECT salario FROM funcionarios WHERE id = $1', [id]);
    if (atualRes.rows.length === 0) {
      return res.status(404).json({ erro: 'Funcionário não encontrado.' });
    }

    const salarioAtual = parseFloat(atualRes.rows[0].salario);
    const salarioNovo  = salario ? parseFloat(salario) : salarioAtual;

    const resultado = await client.query(
      `UPDATE funcionarios SET
         nome_completo     = COALESCE($1, nome_completo),
         cpf               = COALESCE($2, cpf),
         rg                = COALESCE($3, rg),
         data_nascimento   = COALESCE($4, data_nascimento),
         email             = COALESCE($5, email),
         email_corporativo = COALESCE($6, email_corporativo),
         telefone          = COALESCE($7, telefone),
         endereco          = COALESCE($8, endereco),
         cargo             = COALESCE($9, cargo),
         departamento_id   = COALESCE($10, departamento_id),
         tipo_contrato     = COALESCE($11, tipo_contrato),
         salario           = COALESCE($12, salario),
         data_admissao     = COALESCE($13, data_admissao),
         gestor_id         = $14,
         cnpj              = COALESCE($15, cnpj),
         razao_social      = COALESCE($16, razao_social),
         status            = COALESCE($17, status),
         observacoes       = COALESCE($18, observacoes)
       WHERE id = $19
       RETURNING *`,
      [
        nome_completo || null, cpf || null, rg || null, data_nascimento || null,
        email || null, email_corporativo || null, telefone || null,
        endereco || null, cargo || null, departamento_id || null,
        tipo_contrato || null, salarioNovo, data_admissao || null,
        gestor_id || null, cnpj || null, razao_social || null,
        status || null, observacoes || null, id,
      ]
    );

    // Se o salário mudou, registra no histórico
    if (salario && salarioNovo !== salarioAtual) {
      await client.query(
        `INSERT INTO historico_salarios (funcionario_id, salario_anterior, salario_novo, data_alteracao, motivo, registrado_por)
         VALUES ($1, $2, $3, CURRENT_DATE, $4, $5)`,
        [
          id, salarioAtual, salarioNovo,
          motivo_alteracao_salario || 'Atualização cadastral',
          req.usuario.funcionario_id,
        ]
      );
    }

    await client.query('COMMIT');
    res.json({
      mensagem: 'Funcionário atualizado com sucesso.',
      funcionario: resultado.rows[0],
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro ao atualizar funcionário:', err);

    if (err.code === '23505') {
      return res.status(409).json({ erro: 'CPF ou e-mail já cadastrado para outro funcionário.' });
    }

    res.status(500).json({ erro: 'Erro ao atualizar funcionário.' });
  } finally {
    client.release();
  }
});

// ============================================================
// PATCH /api/funcionarios/:id/status
// Altera apenas o status (ativo, ferias, afastado, desligado)
// ============================================================
router.patch('/:id/status', autorizarPerfis('admin', 'rh'), async (req, res) => {
  const { id } = req.params;
  const { status, data_demissao, motivo } = req.body;

  const statusValidos = ['ativo', 'ferias', 'afastado', 'desligado'];
  if (!status || !statusValidos.includes(status)) {
    return res.status(400).json({ erro: `Status inválido. Use: ${statusValidos.join(', ')}.` });
  }

  try {
    await pool.query(
      `UPDATE funcionarios
       SET status = $1, data_demissao = $2
       WHERE id = $3`,
      [status, status === 'desligado' ? (data_demissao || new Date()) : null, id]
    );

    res.json({ mensagem: `Status atualizado para "${status}" com sucesso.` });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar status.' });
  }
});

// ============================================================
// GET /api/funcionarios/:id/historico-salarios
// ============================================================
router.get('/:id/historico-salarios', async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT h.*, reg.nome_completo AS registrado_por_nome
       FROM historico_salarios h
       LEFT JOIN funcionarios reg ON reg.id = h.registrado_por
       WHERE h.funcionario_id = $1
       ORDER BY h.data_alteracao DESC`,
      [req.params.id]
    );
    res.json(resultado.rows);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar histórico de salários.' });
  }
});

// ============================================================
// GET /api/departamentos
// ============================================================
router.get('/aux/departamentos', async (req, res) => {
  try {
    const resultado = await pool.query(
      'SELECT id, nome, descricao FROM departamentos WHERE ativo = true ORDER BY nome'
    );
    res.json(resultado.rows);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar departamentos.' });
  }
});

module.exports = router;
