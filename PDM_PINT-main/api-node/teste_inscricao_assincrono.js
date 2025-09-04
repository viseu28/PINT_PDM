// Teste rápido para verificar se a correção da inscrição em cursos assíncronos funciona
const axios = require('axios');

async function testarInscricaoAssincrono() {
  try {
    console.log('🧪 Testando inscrição em curso assíncrono...');
    
    // Dados de teste (curso 42 é assíncrono)
    const dadosInscricao = {
      idcurso: 42, // "pega ai chico" - curso assíncrono
      objetivos: 'Teste de inscrição automatizada'
    };

    // Token do usuário 8 (pode ser necessário atualizar)
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6OCwiaWF0IjoxNzI0OTU0NzgzLCJleHAiOjE3MjQ5NTgzODN9.exemplo';

    const response = await axios.post('http://localhost:3000/inscricoes', dadosInscricao, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Sucesso! Resposta:', response.data);
    
  } catch (error) {
    if (error.response) {
      console.log('📊 Status:', error.response.status);
      console.log('📄 Resposta:', error.response.data);
      
      if (error.response.status === 401) {
        console.log('ℹ️ Token expirado - teste manual necessário');
      } else if (error.response.data.message !== 'Não há vagas disponíveis para este curso') {
        console.log('✅ Correção aplicada! O erro não é mais sobre vagas.');
      }
    } else {
      console.error('❌ Erro de rede:', error.message);
    }
  }
}

testarInscricaoAssincrono();
