const express=require('express');
const multer=require('multer');
const pool=require('../config/database');
const{autenticar,autorizarPerfis}=require('../middleware/auth');
const{parseOFX,parseCSV,parsePDF}=require('../utils/extrato_parsers');
const{categorizarLancamentos,detectarDuplicatas}=require('../utils/categorizador');
const router=express.Router();
router.use(autenticar);
const upload=multer({storage:multer.memoryStorage(),limits:{fileSize:10*1024*1024},fileFilter:(_req,file,cb)=>{const ext=file.originalname.split('.').pop().toLowerCase();if(['ofx','qif','csv','pdf'].includes(ext))return cb(null,true);cb(new Error('Formato invalido'));},});

// POST /api/extrato/upload
router.post('/upload',autorizarPerfis('admin','financeiro'),upload.single('arquivo'),async(req,res)=>{
  if(!req.file)return res.status(400).json({erro:'Nenhum arquivo enviado'});
  const{conta_bancaria_id}=req.body;
  const ext=req.file.originalname.split('.').pop().toLowerCase();
  const formato=ext==='ofx'||ext==='qif'?'OFX':ext==='pdf'?'PDF':'CSV';
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    let raw=[];
    if(formato==='OFX') raw=parseOFX(req.file.buffer.toString('latin1'));
    else if(formato==='CSV') raw=parseCSV(req.file.buffer.toString('utf-8'));
    else raw=await parsePDF(req.file.buffer);
    if(raw.length===0){await client.query('ROLLBACK');return res.status(422).json({erro:'Nenhum lancamento encontrado'});}
    const semDup=detectarDuplicatas(raw);
    const cat=await categorizarLancamentos(pool,semDup);
    const datas=cat.map(l=>l.data_lancamento).sort();
    const cred=cat.filter(l=>l.tipo==='receita').reduce((s,l)=>s+l.valor,0);
    const deb=cat.filter(l=>l.tipo==='despesa').reduce((s,l)=>s+l.valor,0);
    const ir=await client.query('INSERT INTO importacoes_extrato (conta_bancaria_id,nome_arquivo,formato,total_lancamentos,valor_total_credito,valor_total_debito,periodo_inicio,periodo_fim,importado_por) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id',[conta_bancaria_id||null,req.file.originalname,formato,cat.length,cred,deb,datas[0]||null,datas[datas.length-1]||null,req.usuario.id]);
    const iid=ir.rows[0].id;
    for(const l of cat){
      await client.query('INSERT INTO lancamentos_importados (importacao_id,data_lancamento,descricao,valor,tipo,referencia_banco,saldo_apos,categoria_id,categoria_sugerida_id,confianca_sugestao,keywords_match,status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)',[iid,l.data_lancamento,l.descricao,l.valor,l.tipo,l.referencia_banco||null,l.saldo_apos||null,null,l.categoria_sugerida_id||null,l.confianca_sugestao||0,l.keywords_match||null,l.duplicado?'ignorado':'pendente']);
    }
    await client.query('COMMIT');
    const result=await pool.query('SELECT i.*,cb.nome AS conta_nome FROM importacoes_extrato i LEFT JOIN contas_bancarias cb ON cb.id=i.conta_bancaria_id WHERE i.id=$1',[iid]);
    const lancs=await pool.query('SELECT li.*,c.nome AS categoria_nome,c.cor AS categoria_cor,c.icone AS categoria_icone,cs.nome AS categoria_sugerida_nome FROM lancamentos_importados li LEFT JOIN categorias_financeiras c ON c.id=li.categoria_id LEFT JOIN categorias_financeiras cs ON cs.id=li.categoria_sugerida_id WHERE li.importacao_id=$1 ORDER BY li.data_lancamento,li.id',[iid]);
    res.status(201).json({importacao:result.rows[0],lancamentos:lancs.rows});
  }catch(err){await client.query('ROLLBACK');console.error(err);res.status(500).json({erro:'Erro ao processar extrato bancário.'});}
  finally{client.release();}
});

// GET /api/extrato
router.get('/',async(req,res)=>{
  try{const r=await pool.query('SELECT i.*,cb.nome AS conta_nome FROM importacoes_extrato i LEFT JOIN contas_bancarias cb ON cb.id=i.conta_bancaria_id ORDER BY i.created_at DESC LIMIT 50');res.json({importacoes:r.rows});}
  catch(err){res.status(500).json({erro:'Erro'});}
});

// GET /api/extrato/aux/categorias
router.get('/aux/categorias',async(req,res)=>{
  try{const c=await pool.query('SELECT id,nome,tipo,icone,cor FROM categorias_financeiras WHERE ativo=true ORDER BY tipo,nome');const ct=await pool.query('SELECT id,nome,banco FROM contas_bancarias WHERE ativo=true ORDER BY nome');res.json({categorias:c.rows,contas:ct.rows});}
  catch(err){res.status(500).json({erro:'Erro'});}
});

// GET /api/extrato/:id
router.get('/:id',async(req,res)=>{
  try{
    const i=await pool.query('SELECT i.*,cb.nome AS conta_nome FROM importacoes_extrato i LEFT JOIN contas_bancarias cb ON cb.id=i.conta_bancaria_id WHERE i.id=$1',[req.params.id]);
    if(!i.rows.length)return res.status(404).json({erro:'Nao encontrado'});
    const l=await pool.query('SELECT li.*,c.nome AS categoria_nome,c.cor AS categoria_cor,c.icone AS categoria_icone,cs.nome AS categoria_sugerida_nome,cs.cor AS categoria_sugerida_cor FROM lancamentos_importados li LEFT JOIN categorias_financeiras c ON c.id=li.categoria_id LEFT JOIN categorias_financeiras cs ON cs.id=li.categoria_sugerida_id WHERE li.importacao_id=$1 ORDER BY li.data_lancamento,li.id',[req.params.id]);
    res.json({importacao:i.rows[0],lancamentos:l.rows});
  }catch(err){res.status(500).json({erro:'Erro'});}
});

// PUT /api/extrato/:id/lancamentos/bulk
router.put('/:id/lancamentos/bulk',async(req,res)=>{
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    const{atualizacoes}=req.body;
    if(!Array.isArray(atualizacoes))return res.status(400).json({erro:'atualizacoes deve ser array'});
    for(const u of atualizacoes) await client.query('UPDATE lancamentos_importados SET categoria_id=COALESCE($1,categoria_id),status=COALESCE($2,status) WHERE id=$3 AND importacao_id=$4',[u.categoria_id||null,u.status||null,u.id,req.params.id]);
    await client.query('COMMIT');
    res.json({mensagem:atualizacoes.length+' atualizados'});
  }catch(err){await client.query('ROLLBACK');res.status(500).json({erro:'Erro'});}
  finally{client.release();}
});

// POST /api/extrato/:id/confirmar
router.post('/:id/confirmar',autorizarPerfis('admin','financeiro'),async(req,res)=>{
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    const imp=await client.query('SELECT * FROM importacoes_extrato WHERE id=$1',[req.params.id]);
    if(!imp.rows.length)return res.status(404).json({erro:'Nao encontrado'});
    if(imp.rows[0].status==='confirmado')return res.status(400).json({erro:'Ja confirmado'});
    const lancs=await client.query("SELECT * FROM lancamentos_importados WHERE importacao_id=$1 AND status='confirmado' AND categoria_id IS NOT NULL",[req.params.id]);
    let criados=0;
    for(const l of lancs.rows){
      const lf=await client.query("INSERT INTO lancamentos_financeiros (tipo,descricao,valor,categoria_id,conta_bancaria_id,data_competencia,data_pagamento,status,origem_tipo,origem_id,criado_por) VALUES ($1,$2,$3,$4,$5,$6,$6,'realizado','importacao_extrato',$7,$8) RETURNING id",[l.tipo,l.descricao,l.valor,l.categoria_id,imp.rows[0].conta_bancaria_id,l.data_lancamento,imp.rows[0].id,req.usuario.id]);
      await client.query('UPDATE lancamentos_importados SET lancamento_financeiro_id=$1 WHERE id=$2',[lf.rows[0].id,l.id]);
      criados++;
    }
    await client.query("UPDATE importacoes_extrato SET status='confirmado',total_confirmados=$1 WHERE id=$2",[criados,req.params.id]);
    await client.query('COMMIT');
    res.json({mensagem:criados+' confirmados',total_confirmados:criados});
  }catch(err){await client.query('ROLLBACK');console.error(err);res.status(500).json({erro:'Erro'});}
  finally{client.release();}
});

// DELETE /api/extrato/:id
router.delete('/:id',autorizarPerfis('admin','financeiro'),async(req,res)=>{
  try{const i=await pool.query('SELECT status FROM importacoes_extrato WHERE id=$1',[req.params.id]);if(!i.rows.length)return res.status(404).json({erro:'Nao encontrado'});if(i.rows[0].status==='confirmado')return res.status(400).json({erro:'Nao pode excluir confirmado'});await pool.query('DELETE FROM importacoes_extrato WHERE id=$1',[req.params.id]);res.json({mensagem:'Removido'});}
  catch(err){res.status(500).json({erro:'Erro'});}
});

module.exports=router;
