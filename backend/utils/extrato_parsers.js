// ERP SAF - Parsers de Extrato Bancario (OFX, CSV Sicoob, PDF)

function parseOFX(conteudo) {
  const lancamentos = [];
  const transacoes = conteudo.match(/<STMTTRN>([\s\S]*?)<\/STMTTRN>/gi) || [];
  for(const trn of transacoes){
    const g = t => { const m=trn.match(new RegExp('<'+t+'>([^<\\n\\r]+)','i')); return m?m[1].trim():null; };
    const dtposted=g('DTPOSTED')||'';
    const trnamt=g('TRNAMT')||'0';
    const memo=g('MEMO')||g('NAME')||'';
    const fitid=g('FITID')||'';
    const ds=dtposted.substring(0,8);
    if(ds.length!==8) continue;
    const data=`${ds.slice(0,4)}-${ds.slice(4,6)}-${ds.slice(6,8)}`;
    const valorNum=parseFloat(trnamt.replace(',','.'));
    if(isNaN(valorNum)||valorNum===0) continue;
    lancamentos.push({data_lancamento:data,descricao:memo||'',valor:Math.abs(valorNum),tipo:valorNum>0?'receita':'despesa',referencia_banco:fitid});
  }
  return lancamentos;
}

function parseCSV(conteudo){
  const lancamentos=[];
  const linhas=conteudo.replace(/\r\n/g,'\n').replace(/\r/g,'\n').split('\n').map(l=>l.trim()).filter(l=>l);
  const sep=linhas[0]?.includes(';')?';':',';
  let headerIdx=-1;
  for(let i=0;i<Math.min(10,linhas.length);i++){
    const l=linhas[i].toLowerCase();
    if(l.includes('data')&&(l.includes('valor')||l.includes('hist'))){headerIdx=i;break;}
  }
  if(headerIdx===-1) headerIdx=0;
  const header=linhas[headerIdx].split(sep).map(h=>h.toLowerCase().trim().replace(/"/g,''));
  const idxData=header.findIndex(h=>h.includes('data'));
  const idxDesc=header.findIndex(h=>h.includes('hist')||h.includes('descri'));
  const idxValor=header.findIndex(h=>h.includes('valor')&&!h.includes('saldo'));
  const idxSaldo=header.findIndex(h=>h.includes('saldo'));
  const idxTipo=header.findIndex(h=>h.includes('tipo')||h.includes('d/c'));
  for(let i=headerIdx+1;i<linhas.length;i++){
    const cols=linhas[i].split(sep).map(c=>c.trim().replace(/^"|"$/g,''));
    if(cols.length<3) continue;
    const dataRaw=idxData>=0?cols[idxData]:cols[0];
    const data=parseDateBR(dataRaw);
    if(!data) continue;
    const descricao=(idxDesc>=0?cols[idxDesc]:cols[1]||'').trim();
    if(!descricao||descricao.toLowerCase()==='saldo') continue;
    const valorRaw=idxValor>=0?cols[idxValor]:cols[cols.length-2];
    const valor=parseValorBR(valorRaw);
    if(valor===null||valor===0) continue;
    let tipo='despesa';
    if(idxTipo>=0){const t=cols[idxTipo]?.toUpperCase().trim();tipo=(t==='C'||t==='CR'||t==='CREDITO'||t==='CRÉDITO')?'receita':'despesa';}
    else tipo=valor>0?'receita':'despesa';
    const saldo=idxSaldo>=0?parseValorBR(cols[idxSaldo]):null;
    lancamentos.push({data_lancamento:data,descricao,valor:Math.abs(valor),tipo,referencia_banco:null,saldo_apos:saldo});
  }
  return lancamentos;
}

async function parsePDF(buffer){
  let texto='';
  try{const pdfParse=require('pdf-parse');const d=await pdfParse(buffer);texto=d.text;}
  catch(err){throw new Error('Falha ao ler PDF: '+err.message);}
  const lancamentos=[];
  const linhas=texto.split('\n').map(l=>l.trim()).filter(l=>l);
  const re=/^(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+([\d.,]+)\s*([DC])?$/i;
  for(const linha of linhas){
    const m=linha.match(re);
    if(!m) continue;
    const data=parseDateBR(m[1]);if(!data) continue;
    const descricao=m[2]?.trim();
    const valor=parseValorBR(m[3]);
    if(valor===null||valor===0) continue;
    const dc=m[4]?.toUpperCase();
    const tipo=dc==='C'?'receita':dc==='D'?'despesa':valor>0?'receita':'despesa';
    lancamentos.push({data_lancamento:data,descricao,valor:Math.abs(valor),tipo,referencia_banco:null,saldo_apos:null});
  }
  return lancamentos;
}

function parseDateBR(str){
  if(!str) return null;
  str=str.trim();
  let m=str.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  if(m) return `${m[3]}-${m[2]}-${m[1]}`;
  if(/^\d{4}-\d{2}-\d{2}$/.test(str)) return str;
  m=str.match(/^(\d{2})-(\d{2})-(\d{4})$/);
  if(m) return `${m[3]}-${m[2]}-${m[1]}`;
  return null;
}

function parseValorBR(str){
  if(!str) return null;
  str=str.replace(/\s/g,'').replace(/R\$\s?/gi,'');
  if(str.includes(',')) str=str.replace(/\./g,'').replace(',','.');
  const v=parseFloat(str);
  return isNaN(v)?null:v;
}

module.exports={parseOFX,parseCSV,parsePDF,parseDateBR,parseValorBR};
