const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarDados() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Verificar estrutura das tabelas primeiro
    console.log('\n� Verificando estrutura da tabela utilizador:');
    const [utilizadorCols] = await sequelize.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'utilizador' 
      AND table_schema = 'public'
      ORDER BY ordinal_position
    `);
    console.log('Colunas da tabela utilizador:', utilizadorCols.map(c => c.column_name).join(', '));
    
    console.log('\n� Verificando estrutura da tabela cursos:');
    const [cursosCols] = await sequelize.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'cursos' 
      AND table_schema = 'public'
      ORDER BY ordinal_position
    `);
    console.log('Colunas da tabela cursos:', cursosCols.map(c => c.column_name).join(', '));
    
    // Verificar utilizadores com tokens FCM
    console.log('\n� Utilizadores com tokens FCM:');
    const [tokensResult] = await sequelize.query(`
      SELECT *, 
             CASE WHEN fcm_token IS NOT NULL THEN 'TEM TOKEN' ELSE 'SEM TOKEN' END as token_status
      FROM utilizador 
      WHERE fcm_token IS NOT NULL
      LIMIT 5
    `);
    
    if (tokensResult.length > 0) {
      console.table(tokensResult.map(u => ({
        id: u.idutilizador,
        nome: u.nome,
        email: u.email,
        token_status: u.token_status
      })));
    } else {
      console.log('⚠️ Nenhum utilizador tem token FCM registado!');
      
      // Mostrar alguns utilizadores para ver a estrutura
      const [someUsers] = await sequelize.query(`
        SELECT * FROM utilizador LIMIT 3
      `);
      console.log('\n👥 Primeiros utilizadores:');
      console.table(someUsers);
    }
    
    // Verificar cursos
    console.log('\n📚 Procurando cursos:');
    const [cursosResult] = await sequelize.query(`
      SELECT * FROM cursos 
      WHERE titulo ILIKE '%teste%'
      ORDER BY titulo
      LIMIT 10
    `);
    
    if (cursosResult.length > 0) {
      console.table(cursosResult);
    } else {
      console.log('⚠️ Nenhum curso com "teste" no nome encontrado!');
      console.log('\n📋 Todos os cursos:');
      const [todosCursos] = await sequelize.query(`
        SELECT * FROM cursos 
        ORDER BY titulo
        LIMIT 10
      `);
      console.table(todosCursos);
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarDados();
