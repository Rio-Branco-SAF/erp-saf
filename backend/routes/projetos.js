const express = require('express');
const pool    = require('../config/database');
const { autenticar, autorizarPerfis } = require('../middleware/auth');
const router = express.Router();
router.use(autenticar);

async function notif(client, d) {
  if (!d.usuario_id) return;
  await client.query('INSERT INTO notificacoes (usuario_id,tarefa_id,projeto_id,tipo,mensagem) VALUES ($1,$2,$3,$4,$5)',[d.usuario_id,d.tarefa_id||null,d.projeto_id||null,d.tipo,d.mensagem]);
}

router.get('/', async (req, res) => {
  try {
    const r = await pool.query('SELECT p.*,COUNT(DISTINCT t.id)::int AS total_tarefas,COUNT(DISTINCT t.id) FILTER (WHERE t.status=$$concluido$$)::int AS tarefas_concluidas,COUNT(DISTINCT e.id)::int AS total_epics FROM projetos p LEFT JOIN tarefas t ON t.projeto_id=p.id LEFT JOIN epics e ON e.projeto_id=p.id GROUP BY p.id ORDER BY p.created_at DESC');
    res.json({ projetos: r.rows });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.post('/', async (req, res) => {
  try {
    const { nome, descricao, cor, data_inicio, data_fim } = req.body;
    if (!nome) return res.status(400).json({ erro: 'Nome obrigatorio' });
    const r = await pool.query('INSERT INTO projetos (nome,descricao,cor,data_inicio,data_fim,criado_por) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',[nome,descricao||null,cor||'#3B82F6',data_inicio||null,data_fim||null,req.usuario.id]);
    res.status(201).json({ projeto: r.rows[0] });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.get('/:id', async (req, res) => {
  try { const r = await pool.query('SELECT * FROM projetos WHERE id=$1',[req.params.id]); res.json({ projeto: r.rows[0] }); }
  catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.put('/:id', async (req, res) => {
  try {
    const { nome, descricao, cor, status, data_inicio, data_fim } = req.body;
    const r = await pool.query('UPDATE projetos SET nome=COALESCE($1,nome),descricao=COALESCE($2,descricao),cor=COALESCE($3,cor),status=COALESCE($4,status),updated_at=NOW() WHERE id=$5 RETURNING *',[nome,descricao,cor,status,req.params.id]);
    res.json({ projeto: r.rows[0] });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.delete('/:id', autorizarPerfis('admin','gestor'), async (req, res) => {
  try { await pool.query('DELETE FROM projetos WHERE id=$1',[req.params.id]); res.json({ mensagem: 'OK' }); }
  catch(e) { res.status(500).json({ erro: 'Erro' }); }
});

router.get('/:id/epics', async (req, res) => {
  try {
    const r = await pool.query('SELECT e.*,COUNT(t.id)::int AS total_tarefas FROM epics e LEFT JOIN tarefas t ON t.epic_id=e.id WHERE e.projeto_id=$1 GROUP BY e.id ORDER BY e.created_at',[req.params.id]);
    res.json({ epics: r.rows });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.post('/:id/epics', async (req, res) => {
  try {
    const { nome, descricao, cor } = req.body;
    if (!nome) return res.status(400).json({ erro: 'Nome obrigatorio' });
    const r = await pool.query('INSERT INTO epics (projeto_id,nome,descricao,cor,criado_por) VALUES ($1,$2,$3,$4,$5) RETURNING *',[req.params.id,nome,descricao||null,cor||'#8B5CF6',req.usuario.id]);
    res.status(201).json({ epic: r.rows[0] });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.put('/:pId/epics/:eId', async (req, res) => {
  try {
    const { nome, descricao, cor } = req.body;
    const r = await pool.query('UPDATE epics SET nome=COALESCE($1,nome),descricao=COALESCE($2,descricao),cor=COALESCE($3,cor) WHERE id=$4 AND projeto_id=$5 RETURNING *',[nome,descricao,cor,req.params.eId,req.params.pId]);
    res.json({ epic: r.rows[0] });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.delete('/:pId/epics/:eId', async (req, res) => {
  try { await pool.query('DELETE FROM epics WHERE id=$1 AND projeto_id=$2',[req.params.eId,req.params.pId]); res.json({ mensagem: 'OK' }); }
  catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.get('/:id/tarefas', async (req, res) => {
  try {
    const { epic_id } = req.query;
    const params = [req.params.id]; let extra = '';
    if (epic_id) { extra = 'AND t.epic_id=$2'; params.push(epic_id); }
    const r = await pool.query('SELECT * FROM tarefas_completo t WHERE t.projeto_id=$1 '+extra+' ORDER BY t.posicao,t.created_at', params);
    const colunas = { a_fazer:r.rows.filter(t=>t.status==='a_fazer'), em_andamento:r.rows.filter(t=>t.status==='em_andamento'), em_revisao:r.rows.filter(t=>t.status==='em_revisao'), concluido:r.rows.filter(t=>t.status==='concluido') };
    res.json({ colunas, total: r.rows.length });
  } catch(e) { console.error(e); res.status(500).json({ erro: 'Erro' }); }
});

router.post('/:id/tarefas', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { titulo, descricao, epic_id, prioridade, responsavel_id, data_prazo } = req.body;
    if (!titulo) return res.status(400).json({ erro: 'Titulo obrigatorio' });
    const posR = await client.query("SELECT COALESCE(MAX(posicao),-1)+1 AS pos FROM tarefas WHERE projeto_id=$1 AND status='a_fazer'",[req.params.id]);
    const r = await client.query('INSERT INTO tarefas (projeto_id,epic_id,titulo,descricao,prioridade,responsavel_id,data_prazo,posicao,criado_por) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *',[req.params.id,epic_id||null,titulo,descricao||null,prioridade||'media',responsavel_id||null,data_prazo||null,posR.rows[0].pos,req.usuario.id]);
    const tarefa = r.rows[0];
    if (responsavel_id) {
      const uRes = await client.query('SELECT u.id FROM usuarios u JOIN funcionarios f ON f.id=u.funcionario_id WHERE f.id=$1 AND u.ativo=true LIMIT 1',[responsavel_id]);
      if (uRes.rows.length) await notif(client,{usuario_id:uRes.rows[0].id,tarefa_id:tarefa.id,projeto_id:parseInt(req.params.id),tipo:'atribuicao',mensagem:'Voce foi atribuido a: '+titulo});
    }
    await client.query('COMMIT');
    const completa = await pool.query('SELECT * FROM tarefas_completo WHERE id=$1',[tarefa.id]);
    res.status(201).json({ tarefa: completa.rows[0] });
  } catch(e) { await client.query('ROLLBACK'); console.error(e); res.status(500).json({ erro: 'Erro' }); }
  finally { client.release(); }
});
router.put('/tarefas/:id', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { titulo, descricao, epic_id, prioridade, responsavel_id, data_prazo, status, posicao } = req.body;
    const at = await client.query('SELECT * FROM tarefas WHERE id=$1',[req.params.id]);
    if (!at.rows.length) return res.status(404).json({ erro: 'Nao encontrada' });
    const old = at.rows[0];
    const r = await client.query("UPDATE tarefas SET titulo=COALESCE($1,titulo),descricao=COALESCE($2,descricao),epic_id=CASE WHEN $3::int IS NOT NULL THEN $3::int ELSE epic_id END,prioridade=COALESCE($4,prioridade),responsavel_id=CASE WHEN $5::int IS NOT NULL THEN $5::int ELSE responsavel_id END,data_prazo=COALESCE($6,data_prazo),status=COALESCE($7,status),posicao=COALESCE($8,posicao),data_conclusao=CASE WHEN $7='concluido' AND status<>'concluido' THEN CURRENT_DATE ELSE data_conclusao END,updated_at=NOW() WHERE id=$9 RETURNING *",[titulo,descricao,epic_id,prioridade,responsavel_id,data_prazo,status,posicao,req.params.id]);
    const t = r.rows[0];
    if (responsavel_id && responsavel_id!=old.responsavel_id) {
      const uRes = await client.query('SELECT u.id FROM usuarios u JOIN funcionarios f ON f.id=u.funcionario_id WHERE f.id=$1 AND u.ativo=true LIMIT 1',[responsavel_id]);
      if (uRes.rows.length) await notif(client,{usuario_id:uRes.rows[0].id,tarefa_id:t.id,projeto_id:t.projeto_id,tipo:'atribuicao',mensagem:'Nova tarefa atribuida: '+t.titulo});
    }
    if (status==='concluido'&&old.status!=='concluido'&&old.criado_por)
      await notif(client,{usuario_id:old.criado_por,tarefa_id:t.id,projeto_id:t.projeto_id,tipo:'conclusao',mensagem:'Tarefa concluida: '+t.titulo});
    await client.query('COMMIT');
    const completa = await pool.query('SELECT * FROM tarefas_completo WHERE id=$1',[t.id]);
    res.json({ tarefa: completa.rows[0] });
  } catch(e) { await client.query('ROLLBACK'); console.error(e); res.status(500).json({ erro: 'Erro' }); }
  finally { client.release(); }
});
router.delete('/tarefas/:id', async (req, res) => {
  try { await pool.query('DELETE FROM tarefas WHERE id=$1',[req.params.id]); res.json({ mensagem: 'OK' }); }
  catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.get('/notificacoes/minhas', async (req, res) => {
  try {
    const r = await pool.query('SELECT n.*,t.titulo AS tarefa_titulo,p.nome AS projeto_nome,p.cor AS projeto_cor FROM notificacoes n LEFT JOIN tarefas t ON t.id=n.tarefa_id LEFT JOIN projetos p ON p.id=n.projeto_id WHERE n.usuario_id=$1 ORDER BY n.created_at DESC LIMIT 50',[req.usuario.id]);
    res.json({ notificacoes: r.rows, nao_lidas: r.rows.filter(n=>!n.lida).length });
  } catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.put('/notificacoes/ler-todas', async (req, res) => {
  try { await pool.query('UPDATE notificacoes SET lida=true WHERE usuario_id=$1',[req.usuario.id]); res.json({ mensagem: 'OK' }); }
  catch(e) { res.status(500).json({ erro: 'Erro' }); }
});
router.put('/notificacoes/:id/ler', async (req, res) => {
  try { await pool.query('UPDATE notificacoes SET lida=true WHERE id=$1 AND usuario_id=$2',[req.params.id,req.usuario.id]); res.json({ mensagem: 'OK' }); }
  catch(e) { res.status(500).json({ erro: 'Erro' }); }
});

module.exports = router;
