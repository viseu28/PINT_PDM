const http = require('http');

// Função para fazer requisições HTTP
function makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(body);
                    resolve({ status: res.statusCode, data: response });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });

        req.on('error', reject);
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        
        req.end();
    });
}

async function testarSistemaPedidos() {
    console.log('🧪 TESTANDO SISTEMA DE PEDIDOS DE TÓPICOS\n');

    const baseOptions = {
        hostname: '192.168.1.68',
        port: 3000,
        headers: {
            'Content-Type': 'application/json'
        }
    };

    try {
        // 1. Testar criação de pedido
        console.log('📝 1. Testando criação de pedido...');
        const novoPedido = {
            user_id: 1,
            categoria_id: 1,
            area_id: 1,
            topico_sugerido: 'Teste de Tópico Automatizado'
        };

        const createOptions = {
            ...baseOptions,
            path: '/forum-pedidos/pedidos',
            method: 'POST'
        };

        const createResult = await makeRequest(createOptions, novoPedido);
        console.log(`Status: ${createResult.status}`);
        console.log('Resposta:', createResult.data);

        if (createResult.status === 200 && createResult.data.success) {
            const pedidoId = createResult.data.pedido.id;
            console.log(`✅ Pedido criado com ID: ${pedidoId}\n`);

            // 2. Testar listagem de pedidos
            console.log('📋 2. Testando listagem de pedidos...');
            const listOptions = {
                ...baseOptions,
                path: '/forum-pedidos/pedidos',
                method: 'GET'
            };

            const listResult = await makeRequest(listOptions);
            console.log(`Status: ${listResult.status}`);
            console.log(`Número de pedidos: ${listResult.data.pedidos?.length || 0}`);
            
            if (listResult.data.pedidos?.length > 0) {
                console.log('Último pedido:', listResult.data.pedidos[0]);
            }
            console.log('');

            // 3. Testar atualização do estado (aceitar pedido)
            console.log('✅ 3. Testando aceitação de pedido...');
            const updateOptions = {
                ...baseOptions,
                path: `/forum-pedidos/pedidos/${pedidoId}/estado`,
                method: 'PUT'
            };

            const updateData = {
                estado: 'aceite',
                admin_responsavel: 1,
                observacoes: 'Pedido aceite automaticamente pelo teste'
            };

            const updateResult = await makeRequest(updateOptions, updateData);
            console.log(`Status: ${updateResult.status}`);
            console.log('Resposta:', updateResult.data);
            console.log('');

            // 4. Verificar se o estado foi atualizado
            console.log('🔍 4. Verificando estado atualizado...');
            const checkResult = await makeRequest(listOptions);
            const pedidoAtualizado = checkResult.data.pedidos?.find(p => p.id === pedidoId);
            
            if (pedidoAtualizado) {
                console.log(`Estado atual: ${pedidoAtualizado.estado}`);
                console.log(`Admin responsável: ${pedidoAtualizado.admin_responsavel}`);
                console.log(`Observações: ${pedidoAtualizado.observacoes}`);
            }

        } else {
            console.log('❌ Falha na criação do pedido');
        }

        // 5. Testar filtros
        console.log('\n📊 5. Testando filtros...');
        const filterOptions = {
            ...baseOptions,
            path: '/forum-pedidos/pedidos?estado=pendente',
            method: 'GET'
        };

        const filterResult = await makeRequest(filterOptions);
        console.log(`Pedidos pendentes: ${filterResult.data.pedidos?.length || 0}`);

    } catch (error) {
        console.error('❌ Erro durante os testes:', error.message);
    }

    console.log('\n🏁 Testes concluídos!');
}

// Executar os testes
testarSistemaPedidos();
