const http = require('http');

function testarAPI() {
    console.log('🧪 Testando API de pedidos de tópicos...\n');
    
    // Fazer requisição simples para categorias
    const options = {
        hostname: 'localhost',
        port: 3000,
        path: '/forum-pedidos/categorias',
        method: 'GET',
        headers: {
            'Content-Type': 'application/json'
        }
    };

    const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
            data += chunk;
        });
        
        res.on('end', () => {
            try {
                const response = JSON.parse(data);
                console.log('✅ GET /forum-pedidos/categorias:');
                console.log('Status:', res.statusCode);
                console.log('Response:', response);
                
                if (response.success && response.categorias) {
                    console.log(`📁 Encontradas ${response.categorias.length} categorias:`);
                    response.categorias.forEach(cat => {
                        console.log(`  - ${cat.id}: ${cat.nome}`);
                    });
                }
                
                // Testar áreas da primeira categoria
                if (response.categorias && response.categorias.length > 0) {
                    testarAreas(response.categorias[0].id);
                }
                
            } catch (e) {
                console.log('❌ Erro ao parsear resposta:', e.message);
                console.log('Raw response:', data);
            }
        });
    });

    req.on('error', (e) => {
        console.log('❌ Erro de conexão:', e.message);
    });

    req.end();
}

function testarAreas(categoriaId) {
    console.log(`\n🧪 Testando áreas para categoria ${categoriaId}...`);
    
    const options = {
        hostname: 'localhost',
        port: 3000,
        path: `/forum-pedidos/areas/${categoriaId}`,
        method: 'GET',
        headers: {
            'Content-Type': 'application/json'
        }
    };

    const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
            data += chunk;
        });
        
        res.on('end', () => {
            try {
                const response = JSON.parse(data);
                console.log('✅ GET /forum-pedidos/areas/' + categoriaId + ':');
                console.log('Status:', res.statusCode);
                
                if (response.success && response.areas) {
                    console.log(`📂 Encontradas ${response.areas.length} áreas:`);
                    response.areas.forEach(area => {
                        console.log(`  - ${area.id}: ${area.nome}`);
                    });
                } else {
                    console.log('Response:', response);
                }
                
                console.log('\n🎉 Teste da API concluído com sucesso!');
                
            } catch (e) {
                console.log('❌ Erro ao parsear resposta:', e.message);
                console.log('Raw response:', data);
            }
        });
    });

    req.on('error', (e) => {
        console.log('❌ Erro de conexão:', e.message);
    });

    req.end();
}

// Executar teste
testarAPI();
