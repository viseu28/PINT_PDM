const http = require('http');

const options = {
  hostname: '192.168.1.68',
  port: 3000,
  path: '/percursoformativo/8',
  method: 'GET'
};

console.log('🔍 Testando endpoint /percursoformativo/8...\n');

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    try {
      const jsonData = JSON.parse(data);
      console.log('\n📊 Resposta recebida:');
      console.log(`Total de cursos: ${jsonData.data ? jsonData.data.length : 0}`);
      
      if (jsonData.data && jsonData.data.length > 0) {
        jsonData.data.forEach((curso, index) => {
          console.log(`\n📚 Curso ${index + 1}:`);
          console.log(`Nome: ${curso.nome_curso}`);
          console.log(`Tema: ${curso.tipo_curso}`);
          console.log(`Imagem URL: ${curso.imagem_url}`);
          
          if (curso.imagem_url) {
            if (curso.imagem_url.startsWith('http://192.168.1.68:3000/uploads/')) {
              console.log('✅ Tipo: Arquivo local');
            } else if (curso.imagem_url.startsWith('https://res.cloudinary.com')) {
              console.log('✅ Tipo: Cloudinary URL');
            } else if (curso.imagem_url.startsWith('data:image')) {
              console.log('✅ Tipo: Base64');
            } else {
              console.log('❌ Tipo: Desconhecido');
            }
          } else {
            console.log('❌ Sem imagem');
          }
        });
      } else {
        console.log('❌ Nenhum curso encontrado');
      }
    } catch (error) {
      console.error('❌ Erro ao fazer parse:', error.message);
      console.log('Raw data:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Erro na requisição:', error);
});

req.end();
