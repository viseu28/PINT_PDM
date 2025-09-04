const axios = require('axios');

async function testarImagens() {
  const baseUrl = 'http://192.168.1.68:3000/uploads/';
  const imagens = [
    'Python3.jpg',
    'frontend.jpg', 
    'html_css.jpg',
    'python_financas.jpg'
  ];
  
  console.log('🔍 Testando acessibilidade das imagens...\n');
  
  for (const imagem of imagens) {
    try {
      const url = baseUrl + imagem;
      console.log(`Testando: ${url}`);
      const response = await axios.head(url, { timeout: 5000 });
      console.log(`✅ ${imagem} - Status: ${response.status} - Tamanho: ${response.headers['content-length']} bytes`);
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        console.log(`❌ ${imagem} - Servidor não está acessível`);
      } else if (error.response && error.response.status === 404) {
        console.log(`❌ ${imagem} - Arquivo não encontrado (404)`);
      } else {
        console.log(`❌ ${imagem} - Erro: ${error.message}`);
      }
    }
    console.log('');
  }
}

testarImagens();
