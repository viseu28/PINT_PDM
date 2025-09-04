# 🚀 Guia Completo de Deploy no Render - PINT PDM

## ⏱️ Tempo Estimado: 2-3 horas

### 📋 Pré-requisitos
- [ ] Conta no Render (render.com)
- [ ] Repositório no GitHub com o código
- [ ] Node.js e Flutter instalados localmente (para testes)

---

## 🗄️ PARTE 1: Configurar Base de Dados (45-60 min)

### 1.1. Criar PostgreSQL Database no Render
1. Aceda ao dashboard do Render
2. Clique em "New +" → "PostgreSQL"
3. Configure:
   - **Name**: `pint-pdm-database`
   - **Database Name**: `pint`
   - **User**: `pint_user`
   - **Plan**: Free (para testes)
4. Clique em "Create Database"
5. **Importante**: Guarde as credenciais geradas!

### 1.2. Obter Dados de Conexão
Após criação, anote:
```
Database URL: postgresql://username:password@hostname:port/database_name
Host: hostname
Port: 5432
Database: pint
Username: username
Password: password
```

---

## 🔧 PARTE 2: Deploy da API Node.js (30-45 min)

### 2.1. Criar Web Service
1. No Render Dashboard → "New +" → "Web Service"
2. Conectar repositório GitHub: `viseu28/PINT_PDM`
3. Configure o serviço:
   - **Name**: `pint-pdm-api`
   - **Root Directory**: `PDM_PINT-main/api-node`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

### 2.2. Configurar Variáveis de Ambiente
Adicione na seção "Environment Variables":

```bash
# Database (usar os dados da base criada no passo 1)
DATABASE_URL=postgresql://[user]:[password]@[host]:[port]/[database]
DB_HOST=[host da base criada]
DB_USER=[user da base criada]
DB_PASSWORD=[password da base criada]
DB_NAME=pint
DB_PORT=5432

# Application
NODE_ENV=production
PORT=3000
JWT_SECRET=sua-chave-secreta-jwt-aqui

# Cloudinary (das configurações atuais)
CLOUDINARY_CLOUD_NAME=de3xeyh4u
CLOUDINARY_API_KEY=819929135217463
CLOUDINARY_API_SECRET=XvpF8HgE8S3zSrObksS0hvHNGoc

# Email (das configurações atuais)
EMAIL_USER=softskillsnotifier@gmail.com
EMAIL_PASS=nqqgdzhdbtmhzcsr

# Firebase (configure conforme seu projeto)
FIREBASE_PROJECT_ID=seu-projeto-firebase
FIREBASE_PRIVATE_KEY=sua-chave-privada-firebase
FIREBASE_CLIENT_EMAIL=seu-email-firebase
```

### 2.3. Deploy
1. Clique "Create Web Service"
2. Aguarde o deploy (5-10 minutos)
3. Teste: `https://seu-servico.onrender.com/health`

---

## 📱 PARTE 3: Deploy Flutter Web (30-45 min)

### 3.1. Preparar Flutter para Web
No seu ambiente local:

```bash
# Navegar para o projeto Flutter
cd PDM_PINT-main/projeto_pint

# Ativar suporte web
flutter config --enable-web

# Instalar dependências
flutter pub get

# Build para web
flutter build web --release --web-renderer html
```

### 3.2. Criar Serviço Static Site
1. Render Dashboard → "New +" → "Static Site"
2. Conectar mesmo repositório
3. Configure:
   - **Name**: `pint-pdm-app`
   - **Root Directory**: `PDM_PINT-main/projeto_pint`
   - **Build Command**: `flutter build web --release`
   - **Publish Directory**: `build/web`

### 3.3. Configurar API URL
No código Flutter, atualizar URL da API para:
```dart
static const String baseUrl = 'https://pint-pdm-api.onrender.com';
```

---

## 🔄 PARTE 4: Configuração e Testes (30 min)

### 4.1. Atualizar Código Flutter
1. Encontrar ficheiros com URLs da API hardcoded
2. Atualizar para usar a URL do Render
3. Commit e push para GitHub

### 4.2. Verificar Funcionamento
- [ ] API responde: `https://pint-pdm-api.onrender.com/health`
- [ ] Base de dados conecta corretamente
- [ ] App Flutter carrega: `https://pint-pdm-app.onrender.com`
- [ ] App consegue comunicar com API

### 4.3. Configurar Domínio Personalizado (Opcional)
- Se tiver domínio próprio, configure nas configurações do Render

---

## 🚨 Problemas Comuns e Soluções

### API não conecta à base de dados
- Verificar `DATABASE_URL` está correto
- Confirmar que serviços estão na mesma região
- Verificar logs: Render Dashboard → Service → Logs

### Flutter não consegue conectar à API
- Verificar URL da API no código Flutter
- Confirmar CORS está configurado corretamente
- Verificar se API está online

### Build Flutter falha
```bash
# Limpar cache e tentar novamente
flutter clean
flutter pub get
flutter build web --release
```

### Falta de memória no Free Plan
- O plano gratuito tem limitações
- Considerar upgrade para plan pago se necessário

---

## 💡 Dicas Importantes

1. **Free Plan Limitations**:
   - Services adormecem após 15 min de inatividade
   - 750h/mês de uptime
   - Limited resources

2. **Monitorização**:
   - Use Render logs para debug
   - Configure health checks
   - Monitor database connections

3. **Segurança**:
   - Nunca commitar credentials no git
   - Usar sempre variáveis de ambiente
   - Configurar CORS adequadamente

4. **Performance**:
   - Free services podem ser lentos
   - Considerar CDN para assets estáticos
   - Otimizar queries da base de dados

---

## ✅ Checklist Final

- [ ] PostgreSQL database criada e configurada
- [ ] API Node.js deployed e funcional
- [ ] Flutter web app built e deployed
- [ ] Variáveis de ambiente configuradas
- [ ] URLs atualizadas no Flutter
- [ ] Health checks funcionam
- [ ] App completo funciona end-to-end

**Tempo total estimado: 2-3 horas**

Se seguir este guia passo a passo, terá a aplicação completa funcionando no Render!
