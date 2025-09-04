const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function investigarProblema() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // 1. Encontrar o curso "Curso Teste - Em Breve"
    console.log('\n📚 Procurando curso "Curso Teste - Em Breve":');
    const [cursoTeste] = await sequelize.query(`
      SELECT id, titulo, formador_responsavel, estado
      FROM cursos 
      WHERE titulo ILIKE '%Curso Teste%Em Breve%' 
      OR titulo ILIKE '%Curso Teste - Em Breve%'
    `);
    
    if (cursoTeste.length === 0) {
      console.log('❌ Curso não encontrado! Mostrando todos os cursos:');
      const [todosCursos] = await sequelize.query(`
        SELECT id, titulo FROM cursos ORDER BY id
      `);
      console.table(todosCursos);
      return;
    }
    
    console.table(cursoTeste);
    const idCursoTeste = cursoTeste[0].id;
    
    // 2. Verificar se Formando 1 está inscrito
    console.log(`\n👤 Verificando inscrição do Formando 1 no curso ${idCursoTeste}:`);
    const [inscricao] = await sequelize.query(`
      SELECT i.*, u.nome, u.fcm_token
      FROM form_inscricao i
      JOIN utilizador u ON i.idutilizador = u.idutilizador
      WHERE i.idcurso = :idCurso 
      AND u.nome ILIKE '%Formando 1%'
    `, { replacements: { idCurso: idCursoTeste } });
    
    if (inscricao.length === 0) {
      console.log('❌ Formando 1 NÃO está inscrito neste curso!');
      
      // Mostrar em que cursos está inscrito
      console.log('\n📋 Cursos onde Formando 1 está inscrito:');
      const [inscricoes] = await sequelize.query(`
        SELECT c.id, c.titulo, i.estado as inscricao_ativa
        FROM form_inscricao i
        JOIN cursos c ON i.idcurso = c.id
        JOIN utilizador u ON i.idutilizador = u.idutilizador
        WHERE u.nome ILIKE '%Formando 1%'
        ORDER BY i.data DESC
      `);
      console.table(inscricoes);
    } else {
      console.table(inscricao);
      console.log('✅ Formando 1 está inscrito no curso!');
      
      // 3. Verificar token FCM
      if (!inscricao[0].fcm_token) {
        console.log('❌ PROBLEMA: Formando 1 não tem token FCM registado!');
      } else {
        console.log('✅ Token FCM encontrado:', inscricao[0].fcm_token);
      }
    }
    
    // 4. Verificar se a API está a usar o endpoint correto
    console.log('\n🔧 Para investigar mais:');
    console.log('1. Verifique se a API está a funcionar (node index.js)');
    console.log('2. Verifique se o endpoint de materiais dispara notificações');
    console.log('3. Verifique se o Firebase está configurado corretamente');
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

investigarProblema();
