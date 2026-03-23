# ============================================================
# ERP SAF — Dockerfile (Backend)
# ============================================================
FROM node:20-alpine

# Diretório de trabalho dentro do container
WORKDIR /app

# Copia só os arquivos de dependências primeiro (otimiza cache)
COPY package*.json ./

# Instala dependências de produção
RUN npm install --omit=dev

# Copia o restante do código
COPY . .

# Porta que o Express usa
EXPOSE 3001

# Comando de inicialização
CMD ["node", "server.js"]
