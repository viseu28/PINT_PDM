// Simular a lógica de conversão localmente
console.log('🧪 Testando conversão de respostas localmente...\n');

// Dados de teste (igual ao que vem do app)
const respostasRecebidas = [
  {"resposta": "B", "pergunta_id": 0},  // B = índice 1
  {"resposta": "A", "pergunta_id": 1},  // A = índice 0  
  {"resposta": "A", "pergunta_id": 2}   // A = índice 0
];

// Respostas corretas (todas são índice 0)
const respostasCorretas = [0, 0, 0];

console.log('📝 Respostas recebidas:', respostasRecebidas);
console.log('🎯 Respostas corretas:', respostasCorretas);

// Processar as respostas conforme o formato
let respostasProcessadas = [];

if (Array.isArray(respostasRecebidas)) {
  // Se as respostas vêm como array de objetos {"resposta":"A","pergunta_id":0}
  if (respostasRecebidas.length > 0 && typeof respostasRecebidas[0] === 'object' && respostasRecebidas[0].resposta) {
    console.log(`\n📝 Formato detectado: Array de objetos com campo 'resposta'`);
    
    // Ordenar por pergunta_id e converter resposta de letra para índice
    respostasProcessadas = respostasRecebidas
      .sort((a, b) => a.pergunta_id - b.pergunta_id)
      .map(resp => {
        // Converter A=0, B=1, C=2, D=3, etc.
        const letraResposta = resp.resposta.toUpperCase();
        const indiceResposta = letraResposta.charCodeAt(0) - 65; // A=0, B=1, C=2...
        console.log(`   Convertendo "${letraResposta}" para índice ${indiceResposta}`);
        return indiceResposta;
      });
  } else {
    // Se já vêm como array de números [0, 1, 2...]
    console.log(`\n📝 Formato detectado: Array de índices numéricos`);
    respostasProcessadas = respostasRecebidas;
  }
} else {
  console.log(`\n❌ Formato de respostas não reconhecido`);
  respostasProcessadas = [];
}

console.log(`\n✅ Respostas processadas:`, respostasProcessadas);

// Calcular pontuação
let pontuacao = 0;
console.log(`\n🧮 Calculando pontuação:`);

respostasCorretas.forEach((respostaCorreta, index) => {
  const respostaUsuario = respostasProcessadas[index];
  
  console.log(`   Questão ${index + 1}:`);
  console.log(`     Resposta do usuário: ${respostaUsuario} (tipo: ${typeof respostaUsuario})`);
  console.log(`     Resposta correta: ${respostaCorreta} (tipo: ${typeof respostaCorreta})`);
  
  // Converter ambos para numbers para comparação
  if (parseInt(respostaUsuario) === parseInt(respostaCorreta)) {
    pontuacao++;
    console.log(`     ✅ CORRETO!`);
  } else {
    console.log(`     ❌ ERRADO`);
  }
});

// Calcular nota final (escala 0-20)
const notaFinal = (pontuacao / respostasCorretas.length) * 20;

console.log(`\n📊 RESULTADO FINAL:`);
console.log(`   Pontuação: ${pontuacao}/${respostasCorretas.length}`);
console.log(`   Nota final: ${notaFinal.toFixed(2)}/20`);
console.log(`   Percentagem: ${((pontuacao / respostasCorretas.length) * 100).toFixed(1)}%`);

// Resultado esperado: 2/3 corretas = 13.33/20
console.log(`\n🎯 RESULTADO ESPERADO: 2/3 corretas = 13.33/20`);
if (Math.abs(notaFinal - 13.33) < 0.01) {
  console.log('🎉 SUCESSO! A conversão está a funcionar corretamente!');
} else {
  console.log('⚠️  Há ainda um problema na conversão...');
}
