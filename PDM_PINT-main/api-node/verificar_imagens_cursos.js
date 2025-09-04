const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarImagensCursos() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    const [results] = await sequelize.query('SELECT id, titulo, imagem_url FROM cursos ORDER BY id');
    
    console.log('\n📚 Cursos e suas imagens:');
    console.log('=================================');
    
    results.forEach(row => {
      console.log(`ID: ${row.id}`);
      console.log(`Título: ${row.titulo}`);
      console.log(`Imagem URL: ${row.imagem_url || 'NULL'}`);
      console.log('---------------------------------');
    });
    
    // Verificar quais imagens estão NULL
    const cursosNulls = results.filter(r => !r.imagem_url);
    if (cursosNulls.length > 0) {
      console.log('\n⚠️ Cursos sem imagem:');
      cursosNulls.forEach(curso => {
        console.log(`- ${curso.titulo} (ID: ${curso.id})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarImagensCursos();
