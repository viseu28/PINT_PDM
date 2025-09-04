const http = require('http');

console.log('🔄 Aguardando 2 segundos para o servidor inicializar...');

setTimeout(() => {
  console.log('🧪 Testando submissão de quiz corrigida...\n');
  
  // Simular as mesmas respostas que o usuário enviou
  const respostasUsuario = [
    {"resposta": "B", "pergunta_id": 0},  // B = índice 1
    {"resposta": "A", "pergunta_id": 1},  // A = índice 0  
    {"resposta": "A", "pergunta_id": 2}   // A = índice 0
  ];
  
  console.log('📝 Respostas enviadas:', respostasUsuario);
  
  const postData = JSON.stringify({
    id_utilizador: 8,
    respostas: respostasUsuario
  });
  
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/quizzes/19/submeter',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  const req = http.request(options, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      try {
        const result = JSON.parse(data);
        console.log('\n📊 Resultado da submissão:', result);
        
        if (result.success && result.data) {
          const nota = result.data.nota_final;
          console.log(`\n✅ Nota final: ${nota}/20`);
          console.log(`📈 Percentagem: ${(nota / 20 * 100).toFixed(1)}%`);
          console.log(`🎯 Pontuação: ${result.data.pontuacao}/${result.data.total_questoes}`);
          
          // Verificar se o resultado está correto
          // Respostas: [B,A,A] = [1,0,0], corretas: [0,0,0], logo 2/3 = 13.33/20
          const esperado = 13.33;
          console.log(`🎯 Nota esperada: ${esperado}/20`);
          
          if (Math.abs(nota - esperado) < 0.01) {
            console.log('🎉 SUCESSO! A correção funcionou perfeitamente!');
          } else {
            console.log('⚠️  A nota ainda não está correta...');
          }
        }
        
      } catch (error) {
        console.error('❌ Erro ao parsear resposta:', error.message);
        console.log('Raw response:', data);
      }
    });
  });
  
  req.on('error', (error) => {
    console.error('❌ Erro na requisição:', error.message, error.code);
  });
  
  req.write(postData);
  req.end();

}, 2000);
