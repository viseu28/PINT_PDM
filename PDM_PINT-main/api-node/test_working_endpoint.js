const http = require('http');

function testWorkingEndpoint() {
    console.log('🧪 Testando endpoint que funciona...');
    
    const options = {
        hostname: 'localhost',
        port: 3000,
        path: '/forum-pedidos/categorias',
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
                
                if (json.success && json.categorias) {
                    console.log('\n📊 Categorias encontradas:');
                    json.categorias.forEach(cat => {
                        console.log(`  - ID: ${cat.id}, Nome: ${cat.nome}`);
                    });
                }
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

setTimeout(testWorkingEndpoint, 1000);
