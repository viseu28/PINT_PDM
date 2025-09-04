const http = require('http');

function testNotificationEndpoint() {
  console.log('🌐 Testando endpoint: GET /notificacoes/8\n');
  
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/notificacoes/8',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    }
  };

  const req = http.request(options, (res) => {
    console.log(`📊 Status: ${res.statusCode}`);
    console.log(`📋 Headers:`, res.headers);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('\n📱 Response Body:');
      try {
        const jsonData = JSON.parse(data);
        console.log(JSON.stringify(jsonData, null, 2));
        console.log(`\n🔢 Total de notificações: ${jsonData.length}`);
        console.log('✅ Endpoint funcionando corretamente!');
      } catch (e) {
        console.log('Raw response:', data);
        console.log('❌ Erro ao parsear JSON:', e.message);
      }
    });
  });

  req.on('error', (e) => {
    console.error('❌ Erro na requisição:', e.message);
  });

  req.end();
}

// Aguardar um pouco para o servidor estar pronto
setTimeout(testNotificationEndpoint, 2000);
