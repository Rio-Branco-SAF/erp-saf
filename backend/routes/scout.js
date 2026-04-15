const express=require('express');
const pool=require('../config/database');
const{autenticar}=require('../middleware/auth');
const router=express.Router();
router.use(autenticar);

router.get('/',async(req,res)=>{
  try{
    const{status,posicao,prioridade,busca}=req.query;
    const params=[];const filtros=[];let i=1;
    if(status){filtros.push('status=$'+i++);params.push(status);}
    if(posicao){filtros.push('posicao_principal=$'+i++);params.push(posicao);}
    if(prioridade){filtros.push('prioridade=$'+i++);params.push(prioridade);}
    if(busca){filtros.push('(nome ILIKE $'+i+' OR clube_atual ILIKE $'+i+')');params.push('%'+busca+'%');i++;}
    const where=filtros.length?'WHERE '+filtros.join(' AND '):'';
    const r=await pool.query('SELECT * FROM jogadores_scout '+where+' ORDER BY nota_scout DESC NULLS LAST,created_at DESC',params);
    res.json({jogadores:r.rows,total:r.rows.length});
  }catch(e){res.status(500).json({erro:'Erro ao listar scout'});}
});

router.get('/stats/resumo',async(req,res)=>{
  try{
    const r=await pool.query("SELECT COUNT(*) FILTER(WHERE status='monitorando') AS monitorando,COUNT(*) FILTER(WHERE status='interesse') AS interesse,COUNT(*) FILTER(WHERE status='negociacao') AS negociacao,COUNT(*) FILTER(WHERE status='proposta') AS proposta,COUNT(*) FILTER(WHERE status='contratado') AS contratado,COUNT(*) FILTER(WHERE status='descartado') AS descartado,COUNT(*) AS total FROM jogadores_scout");
    res.json(r.rows[0]);
  }catch(e){res.status(500).json({erro:'Erro'});}
});

router.get('/:id',async(req,res)=>{
  try{const r=await pool.query('SELECT * FROM jogadores_scout WHERE id=$1',[req.params.id]);if(!r.rows.length)return res.status(404).json({erro:'Nao encontrado'});res.json({jogador:r.rows[0]});}
  catch(e){res.status(500).json({erro:'Erro'});}
});

router.post('/',async(req,res)=>{
  try{
    const{nome,data_nascimento,nacionalidade,pe_dominante,altura_cm,posicao_principal,posicao_secundaria,clube_atual,liga,pais_clube,salario_estimado,contrato_fim,jogos,gols,assistencias,nota_sofascore,nota_scout,pontos_fortes,pontos_fracos,observacoes,video_url_1,video_url_2,video_url_3,status,prioridade,orcamento_max}=req.body;
    if(!nome||!posicao_principal)return res.status(400).json({erro:'Nome e posicao obrigatorios'});
    const r=await pool.query('INSERT INTO jogadores_scout(nome,data_nascimento,nacionalidade,pe_dominante,altura_cm,posicao_principal,posicao_secundaria,clube_atual,liga,pais_clube,salario_estimado,contrato_fim,jogos,gols,assistencias,nota_sofascore,nota_scout,pontos_fortes,pontos_fracos,observacoes,video_url_1,video_url_2,video_url_3,status,prioridade,orcamento_max,adicionado_por) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27) RETURNING *',[nome,data_nascimento||null,nacionalidade||null,pe_dominante||'direito',altura_cm||null,posicao_principal,posicao_secundaria||null,clube_atual||null,liga||null,pais_clube||null,salario_estimado||null,contrato_fim||null,jogos||0,gols||0,assistencias||0,nota_sofascore||null,nota_scout||null,pontos_fortes||null,pontos_fracos||null,observacoes||null,video_url_1||null,video_url_2||null,video_url_3||null,status||'monitorando',prioridade||'normal',orcamento_max||null,req.usuario.id]);
    res.status(201).json({jogador:r.rows[0]});
  }catch(e){res.status(500).json({erro:e.message});}
});

router.put('/:id',async(req,res)=>{
  try{
    const keys=Object.keys(req.body);const vals=Object.values(req.body);
    const sets=keys.map((k,i)=>k+'=$'+(i+1)).join(',');
    vals.push(req.params.id);
    const r=await pool.query('UPDATE jogadores_scout SET '+sets+',updated_at=NOW() WHERE id=$'+vals.length+' RETURNING *',vals);
    res.json({jogador:r.rows[0]});
  }catch(e){res.status(500).json({erro:e.message});}
});

router.delete('/:id',async(req,res)=>{
  try{await pool.query('DELETE FROM jogadores_scout WHERE id=$1',[req.params.id]);res.json({mensagem:'Removido'});}
  catch(e){res.status(500).json({erro:'Erro'});}
});

module.exports=router;
