// ERP SAF - Categorizador Automatico de Lancamentos

async function categorizarLancamentos(pool, lancamentos) {
  const regras = await pool.query(`SELECT r.id,r.keyword,r.categoria_id,r.tipo_transacao,r.prioridade,c.nome AS categoria_nome FROM regras_categorizacao r JOIN categorias_financeiras c ON c.id=r.categoria_id WHERE r.ativo=true ORDER BY r.prioridade ASC,LENGTH(r.keyword) DESC`);
  const fallback = await pool.query("SELECT id,tipo FROM categorias_financeiras WHERE nome IN ('Outras Receitas','Outras Despesas') AND ativo=true");
  const fallbackReceita = fallback.rows.find(r=>r.tipo==='receita')?.id||null;
  const fallbackDespesa = fallback.rows.find(r=>r.tipo==='despesa')?.id||null;
  return lancamentos.map(lanc => {
    const descNorm = normalizar(lanc.descricao);
    let melhorMatch=null,melhorKw=null,melhorConf=0;
    for(const regra of regras.rows){
      if(regra.tipo_transacao&&regra.tipo_transacao!=='ambos'&&regra.tipo_transacao!==lanc.tipo) continue;
      const kw=normalizar(regra.keyword);
      if(!descNorm.includes(kw)) continue;
      const posScore=descNorm.indexOf(kw)===0?0.2:0;
      const lenScore=Math.min(kw.length/20,0.5);
      const priScore=(10-regra.prioridade)/10*0.3;
      const confianca=Math.min(0.5+posScore+lenScore+priScore,0.98);
      if(!melhorMatch||confianca>melhorConf){melhorMatch=regra;melhorKw=regra.keyword;melhorConf=confianca;}
    }
    if(!melhorMatch||melhorConf<0.3){
      return {...lanc,categoria_sugerida_id:lanc.tipo==='receita'?fallbackReceita:fallbackDespesa,confianca_sugestao:0.10,keywords_match:null};
    }
    return {...lanc,categoria_sugerida_id:melhorMatch.categoria_id,confianca_sugestao:melhorConf,keywords_match:melhorKw};
  });
}

function detectarDuplicatas(lancamentos){
  const vistos=new Map();
  return lancamentos.map(l=>{
    const chave=`${l.data_lancamento}|${l.tipo}|${l.valor}|${normalizar(l.descricao).slice(0,30)}`;
    const duplicado=vistos.has(chave);
    if(!duplicado) vistos.set(chave,true);
    return{...l,duplicado};
  });
}

function normalizar(str){
  if(!str) return '';
  return str.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^a-z0-9\s]/g,' ').replace(/\s+/g,' ').trim();
}

module.exports={categorizarLancamentos,detectarDuplicatas,normalizar};
