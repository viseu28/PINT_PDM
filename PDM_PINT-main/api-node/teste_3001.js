const axios = require('axios');

async function testarPorta3001() {
    try {
        console.log('🧪 Testando servidor na porta 3001...');
        
        // Testar rota básica
        const test = await axios.get('http://localhost:3001/test');
        console.log('✅ Rota /test:', test.data);
        
        // Testar rota de categorias
        const categorias = await axios.get('http://localhost:3001/forum-pedidos/categorias');
        console.log('✅ Rota /forum-pedidos/categorias:', categorias.data);
        
    } catch (error) {
        console.log('❌ Erro:', error.message);
    }
}

testarPorta3001();
