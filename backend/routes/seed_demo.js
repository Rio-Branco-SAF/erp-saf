const express=require('express');
const pool=require('../config/database');
const fs=require('fs');
const path=require('path');
const router=express.Router();

router.get('/',async(req,res)=>{
  const secret=req.query.secret;
  if(secret!=='saf2026seed') return res.status(403).json({erro:'Nao autorizado'});
  const results={};
  const seeds=['seed_pedidos.sql','seed_atletas.sql','seed_financeiro.sql','seed_investidores.sql','seed_metas.sql','seed_jogos.sql'];
  for(const sf of seeds){
    const fp=path.join(__dirname,'../db',sf);
    if(!fs.existsSync(fp)){results[sf]='nao encontrado';continue;}
    try{const sql=fs.readFileSync(fp,'utf8');await pool.query(sql);results[sf]='ok';}
    catch(err){results[sf]=err.message.slice(0,80);}
  }
  res.json({mensagem:'Seeds executados',resultados:results});
});

module.exports=router;
