const http = require('http');

// Teste do endpoint de percurso formativo
function testPercursoFormativo(userId = 8) {
  const options = {
    hostname: '192.168.1.68',
    port: 3000,
    path: `/percursoformativo/${userId}`,
    method: 'GET'
  };

  const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      try {
        const jsonResponse = JSON.parse(data);
        console.log('🎯 Teste do endpoint Percurso Formativo');
        console.log('═══════════════════════════════════════════════════');
        console.log(`Status: ${res.statusCode}`);
        console.log(`Cursos encontrados: ${jsonResponse.data?.length || 0}`);
        console.log('');
        
        if (jsonResponse.data && jsonResponse.data.length > 0) {
          jsonResponse.data.forEach((curso, index) => {
            console.log(`📚 Curso ${index + 1}: ${curso.nome_curso}`);
            console.log(`Tema: ${curso.tipo_curso || curso.tema}`);
            console.log(`Imagem URL: ${curso.imagem_url || 'SEM IMAGEM'}`);
            console.log(`Tipo de URL: ${detectUrlType(curso.imagem_url)}`);
            console.log('───────────────────────────────────────────────────');
          });
        } else {
          console.log('❌ Nenhum curso encontrado ou erro na resposta');
          console.log('Resposta completa:', JSON.stringify(jsonResponse, null, 2));
        }
      } catch (error) {
        console.error('❌ Erro ao fazer parse da resposta:', error);
        console.log('Resposta bruta:', data);
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Erro na requisição:', error);
  });

  req.end();
}

function detectUrlType(url) {
  if (!url) return 'SEM URL';
  if (url.startsWith('data:image')) return 'BASE64';
  if (url.startsWith('http')) return 'URL EXTERNA';
  if (url.includes('/uploads/')) return 'ARQUIVO LOCAL';
  return 'OUTRO';
}

// Executar teste
testPercursoFormativo(8);
