// Teste direto de notificação - simular adição de material via API
const axios = require('axios');

async function testarNotificacao() {
  try {
    console.log('🧪 === TESTE DE NOTIFICAÇÃO ===\n');

    // 1. Verificar se o servidor está rodando
    console.log('1️⃣ Testando conectividade...');
    const health = await axios.get('http://localhost:3000/health');
    console.log('✅ Servidor respondendo:', health.status === 200);

    // 2. Verificar se o utilizador 8 está inscrito no curso 37
    console.log('\n2️⃣ Verificando inscrição...');
    const inscricoes = await axios.get('http://localhost:3000/inscricoes/8');
    const cursoTeste = inscricoes.data.find(insc => insc.idcurso === 37);
    
    if (cursoTeste) {
      console.log('✅ Utilizador 8 está inscrito no curso 37:', cursoTeste.titulo);
    } else {
      console.log('❌ Utilizador 8 NÃO está inscrito no curso 37');
      return;
    }

    // 3. Testar adição de material via API
    console.log('\n3️⃣ Adicionando material via API...');
    const novoMaterial = {
      titulo: 'Teste de Notificação - ' + new Date().toLocaleTimeString(),
      tipo_mime: 'application/pdf',
      nome_arquivo: 'teste_notificacao.pdf',
      caminho_arquivo: '/uploads/teste_notificacao.pdf'
    };

    const response = await axios.post('http://localhost:3000/cursos/37/materiais', novoMaterial);
    
    if (response.status === 200 || response.status === 201) {
      console.log('✅ Material adicionado com sucesso!');
      console.log('📄 Resposta:', response.data);
      console.log('\n🔔 Se o sistema estiver correto, o utilizador 8 deveria receber uma notificação AGORA!');
    } else {
      console.log('❌ Erro ao adicionar material:', response.status);
    }

  } catch (error) {
    console.error('❌ Erro no teste:', error.response?.data || error.message);
  }
}

testarNotificacao();
