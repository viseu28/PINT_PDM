const http = require('http');

function testEndpoint(path, method = 'GET', data = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => {
                body += chunk;
            });
            res.on('end', () => {
                resolve({
                    status: res.statusCode,
                    data: body,
                    headers: res.headers
                });
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function runTests() {
    const tests = [
        {
            name: 'Buscar categorias',
            path: '/api/forum-pedidos/categorias'
        },
        {
            name: 'Buscar áreas da categoria 1',
            path: '/api/forum-pedidos/areas/1'
        },
        {
            name: 'Criar pedido de tópico',
            path: '/api/forum-pedidos/pedidos',
            method: 'POST',
            data: {
                user_id: 1,
                categoria_id: 1,
                area_id: 1,
                topico_sugerido: 'Teste API Simples',
                descricao: 'Teste de criação de pedido via API'
            }
        },
        {
            name: 'Buscar pedidos do usuário 1',
            path: '/api/forum-pedidos/pedidos/usuario/1'
        }
    ];

    for (let i = 0; i < tests.length; i++) {
        const test = tests[i];
        console.log(`\n${i + 1}. ${test.name}`);
        console.log(`   ${test.method || 'GET'} ${test.path}`);
        
        try {
            const result = await testEndpoint(test.path, test.method, test.data);
            console.log(`   ✅ Status: ${result.status}`);
            
            if (result.data) {
                try {
                    const jsonData = JSON.parse(result.data);
                    if (Array.isArray(jsonData)) {
                        console.log(`   📊 Retornou ${jsonData.length} item(s)`);
                    } else if (jsonData.message) {
                        console.log(`   📝 Mensagem: ${jsonData.message}`);
                    } else {
                        console.log(`   📋 Dados: ${JSON.stringify(jsonData).substring(0, 100)}...`);
                    }
                } catch {
                    console.log(`   📄 Resposta: ${result.data.substring(0, 100)}...`);
                }
            }
        } catch (error) {
            console.log(`   ❌ Erro: ${error.message}`);
        }
    }
    
    console.log('\n✨ Testes concluídos!');
}

runTests();
