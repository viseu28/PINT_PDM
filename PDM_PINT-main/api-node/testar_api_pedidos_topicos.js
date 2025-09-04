const axios = require('axios');

const baseURL = 'http://localhost:3000';

async function testarAPIForumPedidos() {
    try {
        console.log('🧪 Testando API de Pedidos de Tópicos...\n');
        
        // 1. Testar obter categorias
        console.log('1️⃣ Testando GET /forum-pedidos/categorias');
        try {
            const categorias = await axios.get(`${baseURL}/forum-pedidos/categorias`);
            console.log('✅ Categorias obtidas:', categorias.data.categorias);
        } catch (error) {
            console.log('❌ Erro ao obter categorias:', error.response?.data || error.message);
        }
        
        // 2. Testar obter áreas de uma categoria
        console.log('\n2️⃣ Testando GET /forum-pedidos/areas/1 (Programação)');
        try {
            const areas = await axios.get(`${baseURL}/forum-pedidos/areas/1`);
            console.log('✅ Áreas obtidas:', areas.data.areas);
        } catch (error) {
            console.log('❌ Erro ao obter áreas:', error.response?.data || error.message);
        }
        
        // 3. Testar criar pedido de tópico
        console.log('\n3️⃣ Testando POST /forum-pedidos/pedidos');
        const novoPedido = {
            user_id: 1, // Assumindo que existe um utilizador com ID 1
            categoria_id: 1, // Programação
            area_id: 1, // Desenvolvimento Web
            topico_sugerido: 'React Native vs Flutter',
            descricao: 'Discussão sobre as vantagens e desvantagens entre React Native e Flutter para desenvolvimento mobile.'
        };
        
        try {
            const pedidoCriado = await axios.post(`${baseURL}/forum-pedidos/pedidos`, novoPedido);
            console.log('✅ Pedido criado:', pedidoCriado.data);
            
            // Guardar ID do pedido para testes posteriores
            const pedidoId = pedidoCriado.data.pedido.id;
            
            // 4. Testar obter pedidos de um utilizador
            console.log('\n4️⃣ Testando GET /forum-pedidos/pedidos/usuario/1');
            try {
                const pedidosUser = await axios.get(`${baseURL}/forum-pedidos/pedidos/usuario/1`);
                console.log('✅ Pedidos do utilizador:', pedidosUser.data.pedidos);
            } catch (error) {
                console.log('❌ Erro ao obter pedidos do utilizador:', error.response?.data || error.message);
            }
            
            // 5. Testar obter todos os pedidos
            console.log('\n5️⃣ Testando GET /forum-pedidos/pedidos');
            try {
                const todosPedidos = await axios.get(`${baseURL}/forum-pedidos/pedidos`);
                console.log('✅ Todos os pedidos:', todosPedidos.data.pedidos);
            } catch (error) {
                console.log('❌ Erro ao obter todos os pedidos:', error.response?.data || error.message);
            }
            
            // 6. Testar atualizar estado do pedido
            console.log('\n6️⃣ Testando PUT /forum-pedidos/pedidos/:id/estado');
            try {
                const estadoAtualizado = await axios.put(`${baseURL}/forum-pedidos/pedidos/${pedidoId}/estado`, {
                    estado: 'aceite',
                    admin_responsavel: 1,
                    observacoes: 'Tópico aprovado. Muito relevante para a comunidade.'
                });
                console.log('✅ Estado atualizado:', estadoAtualizado.data);
            } catch (error) {
                console.log('❌ Erro ao atualizar estado:', error.response?.data || error.message);
            }
            
        } catch (error) {
            console.log('❌ Erro ao criar pedido:', error.response?.data || error.message);
        }
        
        // 7. Testar criar pedido com categoria/área sugerida
        console.log('\n7️⃣ Testando POST com categoria e área sugeridas');
        const pedidoSugerido = {
            user_id: 1,
            categoria_sugerida: 'Inteligência Artificial',
            area_sugerida: 'Machine Learning',
            topico_sugerido: 'Introdução ao TensorFlow',
            descricao: 'Discussão sobre primeiros passos com TensorFlow para iniciantes.'
        };
        
        try {
            const pedidoSugeridoCriado = await axios.post(`${baseURL}/forum-pedidos/pedidos`, pedidoSugerido);
            console.log('✅ Pedido com sugestões criado:', pedidoSugeridoCriado.data);
        } catch (error) {
            console.log('❌ Erro ao criar pedido com sugestões:', error.response?.data || error.message);
        }
        
        console.log('\n🎉 Testes da API concluídos!');
        
    } catch (error) {
        console.error('❌ Erro geral nos testes:', error);
    }
}

testarAPIForumPedidos();
