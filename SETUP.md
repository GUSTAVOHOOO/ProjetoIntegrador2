# 🏙️ urbana-app — Setup do Ambiente de Desenvolvimento

Guia completo para configurar o ambiente local do projeto em qualquer máquina.
Tempo estimado: **20-30 minutos** na primeira vez.

---

## Pré-requisitos

Antes de começar, verifique se você tem as seguintes ferramentas instaladas:

| Ferramenta | Versão mínima | Como verificar | Download |
|---|---|---|---|
| **Node.js** | 20 LTS | `node -v` | [nodejs.org](https://nodejs.org) |
| **npm** | 10.x | `npm -v` | Vem com o Node.js |
| **Docker Desktop** | 4.x | `docker -v` | [docker.com](https://www.docker.com/products/docker-desktop) |
| **Git** | 2.x | `git -v` | [git-scm.com](https://git-scm.com) |

> **Importante:** Use o Node.js 20 LTS — não use versões superiores ou inferiores.
> Se tiver o `nvm` instalado: `nvm use 20`

---

## 1. Clonar o repositório

```bash
git clone https://github.com/[org]/urbana-app.git
cd urbana-app
```

---

## 2. Instalar dependências

Execute na **raiz do monorepo** — o Turborepo instala tudo de uma vez:

```bash
npm install
```

> Isso instala as dependências de todos os workspaces:
> `apps/web`, `apps/admin`, `apps/api`, `packages/types`, `packages/db`

---

## 3. Configurar variáveis de ambiente

O projeto usa arquivos `.env` que **não são commitados** no repositório por segurança.
Você precisa criá-los a partir dos arquivos de exemplo:

### 3.1 API (apps/api)

```bash
cp apps/api/.env.example apps/api/.env
```

Abra `apps/api/.env` e preencha as variáveis:

```bash
# ── BANCO ────────────────────────────────────────────────────────────────────
# Usado automaticamente pelo docker-compose — não alterar para desenvolvimento
DATABASE_URL=postgresql://urbana:urbana_dev@localhost:5432/urbana_db

# ── AUTH ─────────────────────────────────────────────────────────────────────
# Gere uma string aleatória segura:
# node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=COLE_AQUI_A_STRING_GERADA_ACIMA
JWT_EXPIRES_IN=15m

# ── EMAIL ─────────────────────────────────────────────────────────────────────
# Obtenha com o responsável DevOps do projeto
RESEND_API_KEY=re_XXXXXXXXXXXXXXXXXXXX

# ── UPLOAD ───────────────────────────────────────────────────────────────────
# Obtenha com o responsável DevOps do projeto
CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME

# ── WHATSAPP ─────────────────────────────────────────────────────────────────
# URL da instância Evolution API local (docker-compose já sobe em 8080)
EVOLUTION_API_URL=http://localhost:8080
# Obtenha com o responsável DevOps do projeto
EVOLUTION_API_KEY=SEU_API_KEY_AQUI
EVOLUTION_INSTANCE=urbana-dev

# ── APP ──────────────────────────────────────────────────────────────────────
PORT=3001
NODE_ENV=development
```

### 3.2 PWA do cidadão (apps/web)

```bash
cp apps/web/.env.example apps/web/.env.local
```

`apps/web/.env.local` já vem pronto para desenvolvimento — não precisa alterar:

```bash
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_MUNICIPIO_SLUG=dev
```

### 3.3 Painel da prefeitura (apps/admin)

```bash
cp apps/admin/.env.example apps/admin/.env.local
```

`apps/admin/.env.local` já vem pronto para desenvolvimento:

```bash
NEXT_PUBLIC_API_URL=http://localhost:3001
```

> **⚠️ Nunca commite arquivos `.env`, `.env.local` ou quaisquer arquivos com senhas reais.**
> Eles estão no `.gitignore` por segurança.

---

## 4. Subir os serviços com Docker

```bash
docker compose up
```

Isso sobe **5 serviços**:

| Serviço | Porta | O que é |
|---|---|---|
| `postgres` | 5432 | PostgreSQL 16 + PostGIS 3.4 |
| `api` | 3001 | Backend Fastify |
| `web` | 3000 | PWA do cidadão (Next.js) |
| `admin` | 3002 | Painel da prefeitura (Next.js) |
| `evolution-api` | 8080 | WhatsApp Business API |

> **Primeira vez:** o Docker vai baixar as imagens (~2-3 minutos).
> Próximas vezes: sobe em segundos.

Aguarde até ver no terminal:

```
api    | 🚀 API rodando em http://localhost:3001
web    | ✓ Ready on http://localhost:3000
admin  | ✓ Ready on http://localhost:3002
```

---

## 5. Configurar o banco de dados

Com o Docker rodando, abra um **novo terminal** e execute:

### 5.1 Rodar as migrations

```bash
cd packages/db
npx prisma migrate dev
```

> Cria todas as tabelas no banco local.
> Se perguntar um nome para a migration: `init`

### 5.2 Popular com dados de desenvolvimento

```bash
npx prisma db seed
```

Isso cria:
- Município piloto: **Santa Helena, PR**
- 5 categorias: Buraco na via, Iluminação pública, Entulho, Árvore caída, Capina
- Admin de desenvolvimento: `admin@santahelena.pr.gov.br` / `admin123`

### 5.3 Verificar o banco (opcional)

```bash
npx prisma studio
```

Abre uma interface visual em `http://localhost:5555` para inspecionar os dados.

---

## 6. Verificar que tudo está funcionando

Execute cada verificação abaixo. Todas devem passar:

```bash
# ✅ API respondendo
curl http://localhost:3001/health
# Esperado: {"status":"ok","ts":"..."}

# ✅ PWA do cidadão
# Abra no browser: http://localhost:3000

# ✅ Painel da prefeitura
# Abra no browser: http://localhost:3002

# ✅ Swagger da API
# Abra no browser: http://localhost:3001/docs

# ✅ TypeScript sem erros
npx turbo typecheck

# ✅ Linting
npx turbo lint

# ✅ Testes unitários
npx turbo test

# ✅ Testes de integração (banco real)
DATABASE_URL=postgresql://urbana:urbana_dev@localhost:5432/urbana_db npx turbo test:integration
```

> Se todos passarem: **seu ambiente está pronto para o Sprint 1.** ✅

---

## Comandos do dia a dia

### Desenvolvimento

```bash
# Subir todos os serviços
docker compose up

# Subir apenas o banco (para rodar a API fora do Docker)
docker compose up postgres evolution-api

# Parar tudo
docker compose down

# Reset completo (apaga dados do banco)
docker compose down -v && docker compose up
```

### Turborepo

```bash
# Rodar todos os apps em modo desenvolvimento
npx turbo dev

# Typecheck em todos os workspaces
npx turbo typecheck

# Lint em todos os workspaces
npx turbo lint

# Build de produção
npx turbo build

# Testes unitários
npx turbo test

# Testes de integração
npx turbo test:integration
```

### Workspace específico

```bash
# Rodar comando só na API
npx turbo dev --filter=api

# Rodar comando só no web
npx turbo dev --filter=web

# Rodar comando só no admin
npx turbo dev --filter=admin
```

### Prisma

```bash
# Criar nova migration após alterar schema.prisma
cd packages/db && npx prisma migrate dev --name nome-da-migration

# Aplicar migrations existentes
cd packages/db && npx prisma migrate deploy

# Regenerar o Prisma Client
cd packages/db && npx prisma generate

# Popular banco com dados de desenvolvimento
cd packages/db && npx prisma db seed

# Interface visual do banco
cd packages/db && npx prisma studio
```

---

## Estrutura do projeto

```
urbana-app/
├── apps/
│   ├── web/          → PWA do cidadão      (http://localhost:3000)
│   ├── admin/        → Painel prefeitura   (http://localhost:3002)
│   └── api/          → Backend REST        (http://localhost:3001)
│       └── src/
│           ├── env.ts          → Validação de variáveis de ambiente
│           ├── geo-queries.ts  → ⚠️ ÚNICO arquivo com queries PostGIS
│           └── __tests__/      → Testes de integração obrigatórios
├── packages/
│   ├── types/        → DTOs compartilhados (sem tipos Prisma!)
│   └── db/           → Prisma Client centralizado
│       └── prisma/
│           └── schema.prisma  → Fonte da verdade do banco
├── docker-compose.yml
├── turbo.json
└── .github/
    └── workflows/ci.yml
```

---

## Regras críticas do projeto

Leia antes de fazer o primeiro commit:

### ❌ Nunca faça

```bash
# Commitar arquivos de ambiente
git add .env
git add .env.local

# Escrever queries PostGIS fora de geo-queries.ts
prisma.$queryRaw`...`  # em qualquer arquivo que não seja geo-queries.ts

# Importar tipos do Prisma diretamente no frontend
import { Chamado } from '@prisma/client'  # em apps/web ou apps/admin

# Fazer commit direto na main ou develop
git push origin main
```

### ✅ Sempre faça

```bash
# Criar uma branch para cada tarefa
git checkout -b feat/nome-da-feature

# Abrir PR para develop (nunca para main diretamente)
# PR precisa de: 1 aprovação + CI verde

# TypeScript strict sem warnings
npx turbo typecheck  # deve estar verde antes de abrir PR

# Testes passando
npx turbo test  # deve estar verde antes de abrir PR
```

---

## Git — fluxo de trabalho

```
main         ← produção — merge apenas via PR aprovado + CI verde
develop      ← integração — merge dos PRs das features
feat/nome    ← sua feature
fix/nome     ← correção de bug
```

```bash
# 1. Sempre partir do develop atualizado
git checkout develop
git pull origin develop

# 2. Criar branch para sua tarefa
git checkout -b feat/S1-04-endpoint-cadastro

# 3. Desenvolver, commitar
git add .
git commit -m "feat(auth): implementar endpoint POST /auth/cadastro"

# 4. Push e abrir PR para develop
git push origin feat/S1-04-endpoint-cadastro
# Abrir PR no GitHub para develop
```

### Convenção de commits

```
feat(escopo): descrição     → nova funcionalidade
fix(escopo): descrição      → correção de bug
test(escopo): descrição     → adição/ajuste de testes
refactor(escopo): descrição → refatoração sem mudança de comportamento
docs(escopo): descrição     → documentação
chore(escopo): descrição    → configuração, dependências
```

---

## Solução de problemas

### Docker não sobe o banco

```bash
# Verificar se a porta 5432 está ocupada
lsof -i :5432

# Se estiver: parar o processo ou mudar a porta no docker-compose.yml
# Reset completo
docker compose down -v && docker compose up
```

### `npm install` falha

```bash
# Limpar cache e reinstalar
rm -rf node_modules
rm -rf apps/*/node_modules
rm -rf packages/*/node_modules
npm install
```

### Migration falha com erro de schema

```bash
# Verificar se o banco está rodando
docker compose ps

# Aplicar migration forçando reset (⚠️ apaga dados locais)
cd packages/db
npx prisma migrate reset
npx prisma db seed
```

### TypeScript com erros após pull

```bash
# Regenerar Prisma Client após mudanças no schema
cd packages/db && npx prisma generate

# Reinstalar dependências se novos pacotes foram adicionados
npm install
```

### Porta já em uso

```
Error: listen EADDRINUSE :::3001
```

```bash
# Matar processo na porta
kill $(lsof -t -i:3001)
# ou no Windows
netstat -ano | findstr :3001
taskkill /PID [PID] /F
```

---

## Precisa de ajuda?

1. **Verifique primeiro** se o problema está descrito na seção de solução acima
2. **Poste no canal** `#bloqueios` do Discord com:
   - O que você estava tentando fazer
   - O erro completo (copie o stack trace)
   - O que já tentou
3. **Não fique travado sozinho** por mais de 30 minutos — pergunte no canal

---

*urbana-app · UTFPR-SH · Projeto de Extensão · Gestão de Demandas Urbanas · 2026*
