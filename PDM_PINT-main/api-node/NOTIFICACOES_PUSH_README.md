# 🔥 Configuração Completa das Notificações Push Automáticas

## ✅ O que foi implementado:

### 1. **Sistema de Notificações Automáticas** 
- ✅ Notificação quando novo curso é publicado
- ✅ Notificação quando novo material/vídeo é adicionado a um curso
- ✅ Notificação quando comentário é denunciado
- ✅ Notificação para respostas no fórum (estrutura pronta)

### 2. **Backend (API Node.js)**
- ✅ Firebase Admin SDK instalado
- ✅ Serviço de notificações push (`firebase-push.service.js`)
- ✅ Endpoint para gerenciar tokens FCM (`fcm-token.endpoint.js`)
- ✅ Integração nos endpoints existentes:
  - `denuncia.endpoint.js` - notifica quando comentário é denunciado
  - `curso.endpoint.js` - notifica novo curso e novos materiais
  - `forum.endpoint.js` - estrutura para notificar respostas

### 3. **Frontend (Flutter)**
- ✅ Firebase Messaging Service atualizado
- ✅ Envio automático de token FCM para servidor no login
- ✅ Remoção de token FCM no logout
- ✅ Tratamento de notificações em todos os estados da app

## 🚀 Passos para Ativar Completamente:

### Passo 1: Executar Script SQL
```sql
-- Execute o arquivo setup_push_notifications.sql na sua base de dados
-- Ele adicionará a coluna fcm_token na tabela utilizador
```

### Passo 2: Configurar Firebase Admin SDK (Opcional para funcionalidade completa)

1. **No Firebase Console:**
   - Vá para Project Settings > Service Accounts
   - Clique em "Generate new private key"
   - Baixe o arquivo JSON

2. **No servidor:**
   - Coloque o arquivo na pasta `api-node/config/`
   - Renomeie para `firebase-service-account.json`
   - Ou configure variáveis de ambiente

3. **Método alternativo com variáveis de ambiente:**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/firebase-service-account.json"
   ```

### Passo 3: Testar o Sistema

1. **Compile e execute a app:**
   ```bash
   cd projeto_pint
   flutter run
   ```

2. **Faça login na app** - O token FCM será enviado automaticamente

3. **Teste as notificações:**
   - Crie um novo curso via API → Todos os utilizadores recebem notificação
   - Adicione material a um curso → Utilizadores inscritos recebem notificação
   - Denuncie um comentário → Autor recebe notificação

## 📱 Como Testar Cada Tipo de Notificação:

### 1. Novo Curso Publicado
```bash
curl -X POST http://172.201.108.53:3000/cursos \
  -H "Content-Type: application/json" \
  -d '{
    "titulo": "Curso de Teste Push",
    "descricao": "Teste das notificações",
    "data_inicio": "2025-08-21",
    "data_fim": "2025-09-21",
    "tema": "Tecnologia"
  }'
```

### 2. Novo Material Adicionado
```bash
curl -X POST http://172.201.108.53:3000/cursos/1/materiais \
  -H "Content-Type: application/json" \
  -d '{
    "titulo": "Novo Vídeo Tutorial",
    "descricao": "Tutorial sobre notificações",
    "video_url": "https://example.com/video"
  }'
```

### 3. Comentário Denunciado
```bash
curl -X POST http://172.201.108.53:3000/denuncia \
  -H "Content-Type: application/json" \
  -d '{
    "idpost": 1,
    "motivo": "Conteúdo inapropriado",
    "idutilizador": 2
  }'
```

## 🔧 Resolução de Problemas:

### Se as notificações não chegam:
1. Verifique se o token FCM está sendo salvo na base de dados
2. Verifique logs do servidor para erros do Firebase Admin
3. Confirme que o Firebase Admin SDK está configurado
4. Teste envio manual pelo Firebase Console primeiro

### Logs úteis:
- **Frontend:** Procure por mensagens com 🔔 e 🔥
- **Backend:** Procure por mensagens sobre Firebase e notificações

## 📊 Monitorização:

### Verificar tokens FCM na base de dados:
```sql
SELECT idutilizador, nome, fcm_token IS NOT NULL as tem_token 
FROM utilizador 
WHERE fcm_token IS NOT NULL;
```

### Estatísticas de notificações:
- No Firebase Console > Cloud Messaging
- Pode ver quantas notificações foram enviadas e entregues

## 🔮 Próximas Funcionalidades Possíveis:
- Notificações por categorias/temas
- Notificações de lembretes de cursos
- Notificações de progresso nos cursos
- Agendamento de notificações
- Notificações personalizadas por utilizador

## ⚡ Estado Atual:
✅ **Sistema funcionando** - As notificações são enviadas mesmo sem Firebase Admin SDK (modo simulação)
🔧 **Para produção** - Configure Firebase Admin SDK para envio real
