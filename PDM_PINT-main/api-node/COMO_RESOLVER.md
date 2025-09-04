# 🚀 COMO RESOLVER O PROBLEMA DAS AULAS E MATERIAIS

## ❌ PROBLEMA IDENTIFICADO:
O servidor Node.js não está rodando, por isso os endpoints `/cursos/25/aulas` e `/cursos/25/materiais-apoio` retornam erro 404.

## ✅ SOLUÇÕES (faça na ordem):

### 1. **INICIAR O SERVIDOR NODE.JS**

**Opção A - Clique duplo no arquivo:**
```
📁 c:\Users\user\Desktop\projeto_pint\projeto_pint\api-node\start_server.bat
```

**Opção B - Terminal/Prompt:**
```bash
cd "c:\Users\user\Desktop\projeto_pint\projeto_pint\api-node"
node index.js
```

**O que deve aparecer:**
```
Ligação à base de dados (Postgres) bem sucedida.
Servidor a correr em http://0.0.0.0:3000
```

### 2. **TESTAR SE ESTÁ FUNCIONANDO**

**Opção A - No navegador, abra:**
```
http://localhost:3000
```
Deve aparecer: "API SoftSkills a funcionar 🚀"

**Opção B - Execute o teste:**
```bash
cd "c:\Users\user\Desktop\projeto_pint\projeto_pint\api-node"
node test_endpoints.js
```

### 3. **TESTAR NO FLUTTER**

Depois que o servidor estiver rodando:
1. 🔄 Restart da app Flutter (Ctrl+Shift+F5)
2. 📱 Abrir o curso "asdasd"
3. 👀 Verificar se aparecem as aulas e materiais

---

## 🔧 PROBLEMAS COMUNS:

### "node não é reconhecido"
```bash
# Instalar Node.js em: https://nodejs.org/
node --version  # Deve mostrar a versão
```

### "Porta 3000 já está em uso"
```bash
# Windows - matar processo na porta 3000:
netstat -ano | findstr :3000
taskkill /PID [NÚMERO_DO_PID] /F
```

### "Erro de conexão com base de dados"
- Verificar se PostgreSQL está rodando
- Verificar credenciais em `index.js` linha 20

---

## 📊 O QUE OS LOGS MOSTRAM:

✅ **Funcionando:**
- Curso "asdasd" encontrado (ID: 25)
- API principal funcionando (outros endpoints ok)

❌ **Problema:**
- Status 404 nos endpoints `/cursos/25/aulas` e `/cursos/25/materiais-apoio`
- Servidor Node.js não está rodando

---

## 🎯 APÓS RESOLVER:

Quando funcionar, você deve ver nos logs:
```
📡 Status da resposta (aulas): 200
✅ X aulas recebidas com sucesso
📡 Status da resposta (materiais): 200  
✅ X materiais de apoio recebidos com sucesso
```

E no app Flutter:
- ✅ Aulas carregadas na aba "Aulas"
- ✅ Materiais carregados na aba "Materiais"
