// Teste para verificar cálculo correto de notas
require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false,
});

async function testarCalculoNota() {
  try {
    await sequelize.authenticate();
    
    // Quiz ID 12: "mostrar ao chico como funciona"
    const quiz = await sequelize.query(`
      SELECT questoes FROM quizzes WHERE id_quiz = 12
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    const questoes = quiz[0].questoes;
    console.log('📋 Quiz: "mostrar ao chico como funciona"');
    console.log('🔍 Questões e respostas corretas:');
    
    questoes.forEach((questao, index) => {
      console.log(`   ${index + 1}. ${questao.pergunta}`);
      console.log(`      Opções: ${questao.opcoes.join(', ')}`);
      console.log(`      Resposta correta (índice): ${questao.resposta_correta}`);
      console.log(`      Resposta correta (texto): ${questao.opcoes[questao.resposta_correta]}`);
    });

    // Resposta submetida
    const resposta = await sequelize.query(`
      SELECT respostas, nota FROM respostas_quiz WHERE id_quiz = 12 LIMIT 1
    `, {
      type: Sequelize.QueryTypes.SELECT
    });

    console.log('\n🎯 Resposta submetida:');
    console.log('   Respostas do usuário:', resposta[0].respostas);
    console.log('   Nota salva na BD:', resposta[0].nota);

    // Calcular manualmente
    const respostasUsuario = resposta[0].respostas;
    let acertos = 0;
    
    console.log('\n🧮 Cálculo manual:');
    questoes.forEach((questao, index) => {
      const respostaUsuario = respostasUsuario[index];
      const respostaCorreta = questao.resposta_correta;
      const acertou = parseInt(respostaUsuario) === parseInt(respostaCorreta);
      
      console.log(`   Questão ${index + 1}:`);
      console.log(`     Usuário escolheu: ${respostaUsuario} (${questao.opcoes[respostaUsuario]})`);
      console.log(`     Resposta correta: ${respostaCorreta} (${questao.opcoes[respostaCorreta]})`);
      console.log(`     Resultado: ${acertou ? '✅ CORRETO' : '❌ ERRADO'}`);
      
      if (acertou) acertos++;
    });

    const percentualCorreto = Math.round((acertos / questoes.length) * 100);
    console.log(`\n📊 Resultado final:`);
    console.log(`   Acertos: ${acertos}/${questoes.length}`);
    console.log(`   Percentual: ${percentualCorreto}%`);
    console.log(`   Nota na BD: ${resposta[0].nota} (deveria ser ${acertos})`);

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

testarCalculoNota();
