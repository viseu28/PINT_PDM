const http = require('http');

// Função para fazer pedidos HTTP
function makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let responseData = '';
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    data: responseData
                });
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        if (data) {
            req.write(data);
        }
        req.end();
    });
}

async function testAPI() {
    console.log('🧪 Iniciando testes da API de Pedidos de Tópicos...\n');

    try {
        // Teste 1: GET categorias
        console.log('1️⃣ Testando GET /api/forum-pedidos/categorias');
        const categorias = await makeRequest({
            hostname: 'localhost',
            port: 3000,
            path: '/api/forum-pedidos/categorias',
            method: 'GET'
        });
        console.log(`Status: ${categorias.statusCode}`);
        console.log(`Resposta: ${categorias.data.substring(0, 200)}...`);
        console.log('');

        // Teste 2: GET areas/1
        console.log('2️⃣ Testando GET /api/forum-pedidos/areas/1');
        const areas = await makeRequest({
            hostname: 'localhost',
            port: 3000,
            path: '/api/forum-pedidos/areas/1',
            method: 'GET'
        });
        console.log(`Status: ${areas.statusCode}`);
        console.log(`Resposta: ${areas.data.substring(0, 200)}...`);
        console.log('');

        // Teste 3: POST pedido
        console.log('3️⃣ Testando POST /api/forum-pedidos/pedidos');
        const novoPedido = JSON.stringify({
            user_id: 1,
            categoria_id: 1,
            area_id: 1,
            topico_sugerido: 'Teste API Automatizado',
            descricao: 'Descrição de teste para verificar funcionamento da API'
        });

        const postPedido = await makeRequest({
            hostname: 'localhost',
            port: 3000,
            path: '/api/forum-pedidos/pedidos',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(novoPedido)
            }
        }, novoPedido);
        console.log(`Status: ${postPedido.statusCode}`);
        console.log(`Resposta: ${postPedido.data}`);
        console.log('');

        // Teste 4: GET pedidos do usuário
        console.log('4️⃣ Testando GET /api/forum-pedidos/pedidos/usuario/1');
        const pedidosUsuario = await makeRequest({
            hostname: 'localhost',
            port: 3000,
            path: '/api/forum-pedidos/pedidos/usuario/1',
            method: 'GET'
        });
        console.log(`Status: ${pedidosUsuario.statusCode}`);
        console.log(`Resposta: ${pedidosUsuario.data.substring(0, 300)}...`);
        console.log('');

        // Teste 5: GET todos os pedidos (admin)
        console.log('5️⃣ Testando GET /api/forum-pedidos/pedidos');
        const todosPedidos = await makeRequest({
            hostname: 'localhost',
            port: 3000,
            path: '/api/forum-pedidos/pedidos',
            method: 'GET'
        });
        console.log(`Status: ${todosPedidos.statusCode}`);
        console.log(`Resposta: ${todosPedidos.data.substring(0, 300)}...`);
        console.log('');

        console.log('✅ Todos os testes concluídos!');

    } catch (error) {
        console.error('❌ Erro durante os testes:', error.message);
    }
}

// Executar testes
testAPI();
