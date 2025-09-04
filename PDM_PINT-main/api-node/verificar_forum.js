const { Sequelize } = require('sequelize');

// Configuração da base de dados
const sequelize = new Sequelize('projeto_pint_bd', 'postgres', 'postgres', {
  host: 'localhost',
  port: 5432,
  dialect: 'postgres',
  logging: false
});

async function verificarEstrutura() {
  try {
    console.log('🔍 Verificando estrutura das tabelas do fórum...');
    
    // Verificar estrutura da tabela post
    const [estruturaPost] = await sequelize.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'post' 
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Estrutura da tabela POST:');
    estruturaPost.forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'})`);
    });
    
    // Verificar alguns posts de exemplo
    const [posts] = await sequelize.query('SELECT * FROM post ORDER BY datahora DESC LIMIT 3');
    
    console.log('\n📊 Exemplos de posts:');
    posts.forEach((post, index) => {
      console.log(`   Post ${index + 1}:`);
      console.log(`     - ID: ${post.idpost}`);
      console.log(`     - Título: ${post.titulo}`);
      console.log(`     - Texto: ${post.texto?.substring(0, 100)}...`);
      console.log(`     - Anexo: ${post.anexo || 'NULL'}`);
      console.log(`     - URL: ${post.url || 'NULL'}`);
      console.log(`     - Data: ${post.datahora}`);
    });
    
    await sequelize.close();
  } catch (error) {
    console.error('❌ Erro:', error.message);
  }
}

verificarEstrutura();
