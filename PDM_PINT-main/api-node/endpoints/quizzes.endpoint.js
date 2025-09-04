const express = require('express');
const router = express.Router();
const { Sequelize, Op } = require('sequelize');

// Função para exportar o router com acesso ao banco
module.exports = (db) => {
  
  // Buscar quizzes de um curso específico
  router.get('/curso/:idCurso/:idUtilizador', async (req, res) => {
    try {
      const { idCurso, idUtilizador } = req.params;

      console.log(`🔍 Buscando quizzes para curso ${idCurso} e utilizador ${idUtilizador}`);

    // Buscar todos os quizzes ativos do curso
    const quizzes = await db.sequelize.query(`
      SELECT 
        q.id_quiz,
        q.titulo,
        q.descricao,
        q.questoes,
        q.created_at,
        rq.nota,
        rq.data_submissao,
        rq.tentativa,
        CASE 
          WHEN rq.id_resposta IS NOT NULL THEN true 
          ELSE false 
        END as completo
      FROM quizzes q
      LEFT JOIN respostas_quiz rq ON q.id_quiz = rq.id_quiz 
        AND rq.id_utilizador = :idUtilizador
        AND rq.tentativa = (
          SELECT MAX(tentativa) 
          FROM respostas_quiz 
          WHERE id_quiz = q.id_quiz 
          AND id_utilizador = :idUtilizador
        )
      WHERE q.id_curso = :idCurso 
        AND q.ativo = true
      ORDER BY q.created_at ASC
    `, {
      replacements: { idCurso, idUtilizador },
      type: Sequelize.QueryTypes.SELECT
    });

    // Processar os dados para o formato esperado pelo mobile
    const quizzesFormatados = quizzes.map(quiz => {
      let questoesArray = [];
      try {
        // Se questoes já é um objeto/array (JSONB), usar diretamente
        if (typeof quiz.questoes === 'object' && quiz.questoes !== null) {
          questoesArray = Array.isArray(quiz.questoes) ? quiz.questoes : [];
        } else {
          // Se for string, fazer parse
          questoesArray = JSON.parse(quiz.questoes || '[]');
        }
      } catch (e) {
        console.error('❌ Erro ao processar questões do quiz:', e);
        questoesArray = [];
      }

      return {
        id: quiz.id_quiz,
        titulo: quiz.titulo,
        descricao: quiz.descricao,
        total_perguntas: questoesArray.length,
        questoes: questoesArray,
        completo: quiz.completo,
        pontuacao: quiz.nota ? parseFloat(quiz.nota) : null, // quiz.nota já está na escala 0-20
        data_submissao: quiz.data_submissao,
        tentativa: quiz.tentativa || 0,
        created_at: quiz.created_at
      };
    });

    console.log(`✅ Encontrados ${quizzesFormatados.length} quizzes`);

    res.json({
      success: true,
      data: quizzesFormatados
    });

  } catch (error) {
    console.error('❌ Erro ao buscar quizzes:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Buscar um quiz específico com suas questões
router.get('/:idQuiz/:idUtilizador', async (req, res) => {
  try {
    const { idQuiz, idUtilizador } = req.params;

    console.log(`🔍 Buscando quiz ${idQuiz} para utilizador ${idUtilizador}`);

    // Buscar o quiz e verificar se já foi respondido
    const quiz = await db.sequelize.query(`
      SELECT 
        q.id_quiz,
        q.titulo,
        q.descricao,
        q.questoes,
        q.created_at,
        rq.nota,
        rq.data_submissao,
        rq.tentativa,
        rq.respostas,
        CASE 
          WHEN rq.id_resposta IS NOT NULL THEN true 
          ELSE false 
        END as completo
      FROM quizzes q
      LEFT JOIN respostas_quiz rq ON q.id_quiz = rq.id_quiz 
        AND rq.id_utilizador = :idUtilizador
        AND rq.tentativa = (
          SELECT MAX(tentativa) 
          FROM respostas_quiz 
          WHERE id_quiz = q.id_quiz 
          AND id_utilizador = :idUtilizador
        )
      WHERE q.id_quiz = :idQuiz 
        AND q.ativo = true
    `, {
      replacements: { idQuiz, idUtilizador },
      type: Sequelize.QueryTypes.SELECT
    });

    if (!quiz || quiz.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Quiz não encontrado'
      });
    }

    const quizData = quiz[0];
    let questoesArray = [];
    let respostasArray = [];

    try {
      // Se questoes já é um objeto/array (JSONB), usar diretamente
      if (typeof quizData.questoes === 'object' && quizData.questoes !== null) {
        questoesArray = Array.isArray(quizData.questoes) ? quizData.questoes : [];
      } else {
        // Se for string, fazer parse
        questoesArray = JSON.parse(quizData.questoes || '[]');
      }
      
      if (quizData.respostas) {
        if (typeof quizData.respostas === 'object') {
          respostasArray = quizData.respostas;
        } else {
          respostasArray = JSON.parse(quizData.respostas);
        }
      }
    } catch (e) {
      console.error('Erro ao processar dados do quiz:', e);
    }

    const quizFormatado = {
      id: quizData.id_quiz,
      titulo: quizData.titulo,
      descricao: quizData.descricao,
      questoes: questoesArray,
      completo: quizData.completo,
      pontuacao: quizData.nota ? parseFloat(quizData.nota) : null, // quizData.nota já está na escala 0-20
      data_submissao: quizData.data_submissao,
      tentativa: quizData.tentativa || 0,
      respostas_anteriores: respostasArray,
      total_perguntas: questoesArray.length
    };

    console.log(`✅ Quiz encontrado: ${quizFormatado.titulo}`);

    res.json({
      success: true,
      data: quizFormatado
    });

  } catch (error) {
    console.error('❌ Erro ao buscar quiz:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

// Submeter respostas do quiz
router.post('/:idQuiz/submeter', async (req, res) => {
  try {
    const { idQuiz } = req.params;
    const { id_utilizador, respostas } = req.body;

    console.log(`📝 Submetendo respostas do quiz ${idQuiz} para utilizador ${id_utilizador}`);

    // Buscar o quiz para calcular a nota
    const quiz = await db.sequelize.query(`
      SELECT questoes FROM quizzes WHERE id_quiz = :idQuiz AND ativo = true
    `, {
      replacements: { idQuiz },
      type: Sequelize.QueryTypes.SELECT
    });

    if (!quiz || quiz.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Quiz não encontrado'
      });
    }

    let questoes = [];
    try {
      // Se questoes já é um objeto/array (JSONB), usar diretamente
      if (typeof quiz[0].questoes === 'object' && quiz[0].questoes !== null) {
        questoes = Array.isArray(quiz[0].questoes) ? quiz[0].questoes : [];
      } else {
        // Se for string, fazer parse
        questoes = JSON.parse(quiz[0].questoes || '[]');
      }
    } catch (e) {
      console.error('Erro ao processar questões para cálculo:', e);
      questoes = [];
    }
    
    // Calcular a nota
    let pontuacao = 0;
    console.log(`🧮 Calculando nota:`);
    console.log(`   Respostas recebidas:`, respostas);
    console.log(`   Total de questões: ${questoes.length}`);
    
    // Processar as respostas conforme o formato
    let respostasProcessadas = [];
    
    if (Array.isArray(respostas)) {
      // Se as respostas vêm como array de objetos {"resposta":"A","pergunta_id":0}
      if (respostas.length > 0 && typeof respostas[0] === 'object' && respostas[0].resposta) {
        console.log(`   📝 Formato detectado: Array de objetos com campo 'resposta'`);
        
        // Ordenar por pergunta_id e converter resposta de letra para índice
        respostasProcessadas = respostas
          .sort((a, b) => a.pergunta_id - b.pergunta_id)
          .map(resp => {
            // Converter A=0, B=1, C=2, D=3, etc.
            const letraResposta = resp.resposta.toUpperCase();
            const indiceResposta = letraResposta.charCodeAt(0) - 65; // A=0, B=1, C=2...
            console.log(`     Convertendo "${letraResposta}" para índice ${indiceResposta}`);
            return indiceResposta;
          });
      } else {
        // Se já vêm como array de números [0, 1, 2...]
        console.log(`   📝 Formato detectado: Array de índices numéricos`);
        respostasProcessadas = respostas;
      }
    } else {
      console.log(`   ❌ Formato de respostas não reconhecido`);
      respostasProcessadas = [];
    }
    
    console.log(`   ✅ Respostas processadas:`, respostasProcessadas);
    
    questoes.forEach((questao, index) => {
      const respostaUsuario = respostasProcessadas[index];
      const respostaCorreta = questao.resposta_correta;
      
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
    
    console.log(`📊 Pontuação final: ${pontuacao}/${questoes.length}`);

    // Calcular nota na escala 0-20
    const notaFinal = (pontuacao / questoes.length) * 20;
    console.log(`🎯 Nota convertida para escala 0-20: ${notaFinal.toFixed(2)}/20`);

    // Verificar qual é a próxima tentativa
    const tentativaAtual = await db.sequelize.query(`
      SELECT COALESCE(MAX(tentativa), 0) + 1 as proxima_tentativa
      FROM respostas_quiz 
      WHERE id_quiz = :idQuiz AND id_utilizador = :id_utilizador
    `, {
      replacements: { idQuiz, id_utilizador },
      type: Sequelize.QueryTypes.SELECT
    });

    const proximaTentativa = tentativaAtual[0].proxima_tentativa;

    // Inserir a resposta
    await db.sequelize.query(`
      INSERT INTO respostas_quiz (id_quiz, id_utilizador, respostas, nota, data_submissao, tentativa, created_at, updated_at)
      VALUES (:idQuiz, :id_utilizador, :respostas, :nota, NOW(), :tentativa, NOW(), NOW())
    `, {
      replacements: {
        idQuiz,
        id_utilizador,
        respostas: JSON.stringify(respostas),
        nota: notaFinal.toFixed(2), // Guardar a nota na escala 0-20
        tentativa: proximaTentativa
      }
    });

    console.log(`✅ Quiz submetido - Pontuação: ${pontuacao}/${questoes.length} = ${notaFinal.toFixed(2)}/20`);

    res.json({
      success: true,
      data: {
        pontuacao,
        total_questoes: questoes.length,
        nota_final: parseFloat(notaFinal.toFixed(2)),
        tentativa: proximaTentativa
      }
    });

  } catch (error) {
    console.error('❌ Erro ao submeter quiz:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

  return router;
};
