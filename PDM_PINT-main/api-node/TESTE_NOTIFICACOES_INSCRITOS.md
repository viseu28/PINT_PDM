# 🔔 Teste das Notificações Push para Utilizadores Inscritos

## 📋 Cenários de Teste

### 1. **📚 Novo Material Adicionado**
```bash
# Adicionar material a um curso
POST http://172.201.108.53:3000/cursos/1/materiais
Content-Type: application/json

{
  "titulo": "Tutorial Avançado de CSS",
  "descricao": "Aprenda técnicas avançadas de CSS",
  "video_url": "https://exemplo.com/video-css",
  "duracao": "25 min"
}
```
**Resultado**: Utilizadores inscritos no curso 1 recebem: *"📚 Novo vídeo disponível! Tutorial Avançado de CSS foi adicionado ao curso [Nome do Curso]"*

---

### 2. **👨‍🏫 Alteração de Formador**
```bash
# Atualizar formador do curso
PUT http://172.201.108.53:3000/cursos/1
Content-Type: application/json

{
  "formador": "Prof. João Silva"
}
```
**Resultado**: Utilizadores inscritos recebem: *"👨‍🏫 Alteração de formador. Prof. João Silva é agora o formador do curso [Nome do Curso]"*

---

### 3. **📅 Alteração de Datas**
```bash
# Atualizar datas do curso
PUT http://172.201.108.53:3000/cursos/1
Content-Type: application/json

{
  "data_inicio": "2025-09-15",
  "data_fim": "2025-12-15"
}
```
**Resultado**: Utilizadores inscritos recebem: *"📅 Alteração de datas do curso. O curso [Nome] decorrerá de 15/09/2025 a 15/12/2025"*

---

### 4. **📢 Alteração de Estado**
```bash
# Suspender curso
PUT http://172.201.108.53:3000/cursos/1
Content-Type: application/json

{
  "estado": false
}
```
**Resultado**: Utilizadores inscritos recebem: *"⏸️ Curso suspenso. O curso [Nome] foi temporariamente suspenso"*

---

### 5. **📝 Alteração de Informações**
```bash
# Alterar dificuldade e categoria
PUT http://172.201.108.53:3000/cursos/1
Content-Type: application/json

{
  "dificuldade": "Avançado",
  "tema": "Desenvolvimento Web"
}
```
**Resultado**: Utilizadores inscritos recebem: *"📝 Curso atualizado. O nível de dificuldade foi alterado para: Avançado"*

---

## 🎯 Verificação do Sistema

### **Verificar inscrições de um utilizador:**
```sql
-- Ver cursos em que o utilizador está inscrito
SELECT c.titulo, c.idcurso, i.data_inscricao, i.estado
FROM inscricoes i
JOIN cursos c ON i.idcurso = c.idcurso
WHERE i.idutilizador = 1 AND i.estado = true;
```

### **Verificar token FCM de um utilizador:**
```sql
-- Ver se o utilizador tem token FCM
SELECT nome, email, fcm_token
FROM utilizador
WHERE idutilizador = 1;
```

---

## 🔧 Fluxo Completo de Teste

1. **📱 Certifica-te que tens a app instalada e fizeste login**
2. **📝 Inscreve-te num curso através da app**
3. **🖥️ Via web/API, faz alterações ao curso**
4. **🔔 Verifica se recebes a notificação no telemóvel**

---

## 🚨 Tipos de Notificações Implementadas

| Tipo | Trigger | Quem Recebe | Exemplo |
|------|---------|-------------|---------|
| `novo_material` | Material adicionado | Inscritos no curso | 📚 Novo vídeo disponível! |
| `alteracao_formador` | Formador alterado | Inscritos no curso | 👨‍🏫 Alteração de formador |
| `alteracao_datas` | Datas alteradas | Inscritos no curso | 📅 Alteração de datas |
| `alteracao_estado` | Estado alterado | Inscritos no curso | ⏸️ Curso suspenso |
| `alteracao_informacoes` | Info geral alterada | Inscritos no curso | 📝 Curso atualizado |
| `denuncia` | Comentário denunciado | Autor do comentário | ⚠️ Comentário denunciado |
| `resposta_forum` | Resposta no fórum | Autor do post original | 💬 Nova resposta |

---

## ✅ Confirmação

**ANTES:** Todos os utilizadores recebiam notificações de novos cursos  
**AGORA:** ✅ Apenas utilizadores **inscritos** recebem notificações sobre **os seus cursos**
