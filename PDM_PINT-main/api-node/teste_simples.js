const axios = require('axios');

async function testeSimples() {
    try {
        console.log('🧪 Teste simples da API...');
        
        const response = await axios.get('http://localhost:3000/forum-pedidos/categorias');
        console.log('✅ Sucesso:', response.data);
        
    } catch (error) {
        if (error.response) {
            console.log('❌ Erro HTTP:', error.response.status, error.response.data);
        } else if (error.request) {
            console.log('❌ Erro de conexão - servidor não está a responder');
        } else {
            console.log('❌ Erro:', error.message);
        }
    }
}

testeSimples();
