-- ERP SAF Schema: Scout / Banco de Talentos

CREATE TABLE jogadores_scout (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(200) NOT NULL,
  data_nascimento DATE,
  nacionalidade VARCHAR(80),
  pe_dominante VARCHAR(10) DEFAULT 'direito' CHECK (pe_dominante IN ('direito','esquerdo','ambidestro')),
  altura_cm INTEGER,
  peso_kg NUMERIC(5,1),
  foto_url VARCHAR(500),
  posicao_principal VARCHAR(30) NOT NULL,
  posicao_secundaria VARCHAR(30),
  clube_atual VARCHAR(150),
  liga VARCHAR(100),
  pais_clube VARCHAR(80),
  salario_estimado NUMERIC(14,2),
  contrato_fim DATE,
  temporada VARCHAR(10) DEFAULT '2025/26',
  jogos INTEGER DEFAULT 0,
  gols INTEGER DEFAULT 0,
  assistencias INTEGER DEFAULT 0,
  minutos_jogados INTEGER DEFAULT 0,
  nota_sofascore NUMERIC(3,1),
  nota_whoscored NUMERIC(3,1),
  nota_scout INTEGER CHECK (nota_scout BETWEEN 1 AND 10),
  pontos_fortes TEXT,
  pontos_fracos TEXT,
  observacoes TEXT,
  video_url_1 VARCHAR(500),
  video_url_2 VARCHAR(500),
  video_url_3 VARCHAR(500),
  status VARCHAR(30) NOT NULL DEFAULT 'monitorando' CHECK (status IN ('monitorando','interesse','negociacao','proposta','contratado','descartado')),
  adicionado_por INTEGER REFERENCES usuarios(id),
  prioridade VARCHAR(10) DEFAULT 'normal' CHECK (prioridade IN ('baixa','normal','alta','urgente')),
  orcamento_max NUMERIC(14,2),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scout_posicao ON jogadores_scout(posicao_principal);
CREATE INDEX idx_scout_status ON jogadores_scout(status);
CREATE INDEX idx_scout_nota ON jogadores_scout(nota_scout DESC);
CREATE TRIGGER trg_scout_updated_at BEFORE UPDATE ON jogadores_scout FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();

-- Dados demo
INSERT INTO jogadores_scout (nome,data_nascimento,nacionalidade,pe_dominante,altura_cm,posicao_principal,posicao_secundaria,clube_atual,liga,pais_clube,salario_estimado,contrato_fim,jogos,gols,assistencias,nota_sofascore,nota_scout,pontos_fortes,pontos_fracos,observacoes,status,prioridade) VALUES
('Matheus Cunha','1999-05-27','Brasileiro','direito',181,'centroavante','meia_atacante','Wolverhampton','Premier League','Inglaterra',85000,'2027-06-30',28,12,7,7.4,9,'Finalização, velocidade, dribles','Consistência defensiva','Momento ideal para contratar.',  'negociacao','urgente'),
('Vitor Roque','2005-02-28','Brasileiro','direito',174,'centroavante',NULL,'Real Betis','La Liga','Espanha',40000,'2029-06-30',22,8,3,6.9,8,'Mobilidade, presença no box','Experiência','Emprestado pelo Barcelona.','interesse','alta'),
('André Trindade','2001-07-11','Brasileiro','direito',188,'volante','meia_central','Wolverhampton','Premier League','Inglaterra',65000,'2028-06-30',25,2,4,7.1,8,'Recuperação de bola, distribuição','Finalização','Um dos melhores volantes no exterior.','monitorando','alta'),
('Kaio Jorge','2002-01-24','Brasileiro','direito',180,'centroavante','ponta_esquerda','Cremonese','Serie B','Itália',15000,'2026-06-30',20,9,4,7.0,7,'Finalização, movimentação','Constância','Contrato vencendo — oportunidade.','interesse','normal'),
('Marlon Gomes','2004-01-05','Brasileiro','direito',176,'meia_central','volante','Schalke 04','Bundesliga 2','Alemanha',8000,'2026-06-30',25,5,8,7.3,8,'Visão de jogo, passe filtrado','Físico','Contrato vencendo, prioridade na janela.','negociacao','alta'),
('Nathan Mendes','2003-09-10','Brasileiro','esquerdo',180,'ponta_esquerda','meia_atacante','Lorient','Ligue 1','França',12000,'2027-06-30',26,7,9,7.2,8,'Velocidade, drible, assistências','Finalização','Clube em dificuldades — oportunidade.','interesse','alta');
