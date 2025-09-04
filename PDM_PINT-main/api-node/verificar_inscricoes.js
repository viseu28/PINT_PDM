const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarInscricoes() {
  try {
    await sequelize.authenticate();
    
    // Verificar estrutura da tabela
    console.log('🔍 Estrutura da tabela inscricao_curso:');
    const [estrutura] = await sequelize.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'inscricao_curso' 
      AND table_schema = 'public'
      ORDER BY ordinal_position
    `);
    console.table(estrutura);
    
    // Verificar inscrições no curso 36 (teste1)
    console.log('\n👥 Inscrições no curso teste1 (ID: 36):');
    const [inscricoes] = await sequelize.query(`
      SELECT i.*, u.nome, u.email
      FROM inscricao_curso i
      JOIN utilizador u ON i.idutilizador = u.idutilizador
      WHERE i.idcurso = 36
      ORDER BY i.idutilizador
    `);
    
    if (inscricoes.length > 0) {
      console.table(inscricoes);
    } else {
      console.log('⚠️ Nenhum utilizador inscrito no curso teste1!');
      
      // Verificar todas as inscrições
      console.log('\n📋 Todas as inscrições:');
      const [todasInscricoes] = await sequelize.query(`
        SELECT i.idcurso, c.titulo, i.idutilizador, u.nome, i.estado
        FROM inscricao_curso i
        JOIN utilizador u ON i.idutilizador = u.idutilizador
        JOIN cursos c ON i.idcurso = c.id
        ORDER BY i.idcurso, i.idutilizador
        LIMIT 10
      `);
      console.table(todasInscricoes);
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarInscricoes();
