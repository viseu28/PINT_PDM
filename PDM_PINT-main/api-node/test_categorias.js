const http = require('http');

function testEndpoint() {
    console.log('🧪 Testando endpoint de categorias...');
    
    const options = {
        hostname: 'localhost',
        port: 3000,
        path: '/api/forum-pedidos/categorias',
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
            data += chunk;
        });

        res.on('end', () => {
            console.log(`Status: ${res.statusCode}`);
            console.log('Resposta:');
            try {
                const json = JSON.parse(data);
                console.log(JSON.stringify(json, null, 2));
            } catch (e) {
                console.log(data);
            }
        });
    });

    req.on('error', (err) => {
        console.log('❌ Erro:', err.message);
    });

    req.end();
}

// Aguardar um pouco para garantir que o servidor está ativo
setTimeout(testEndpoint, 1000);
