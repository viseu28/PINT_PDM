const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('projeto_pint', 'postgres', 'root', {
  host: 'localhost',
  dialect: 'postgres',
  logging: false
});

(async () => {
  try {
    await sequelize.authenticate();
    
    const [results] = await sequelize.query(`
      SELECT id, titulo, tipo, estado 
      FROM cursos 
      WHERE titulo ILIKE '%desenvolvimento%mobile%' OR titulo ILIKE '%mobile%'
    `);
    
    console.log('🔍 Cursos com Mobile encontrados:');
    results.forEach(curso => {
      console.log(`ID: ${curso.id}, Título: ${curso.titulo}, Tipo: '${curso.tipo}', Estado: '${curso.estado}'`);
    });
    
    // Também buscar todos os tipos únicos
    const [tiposResults] = await sequelize.query(`
      SELECT DISTINCT tipo, COUNT(*) as count
      FROM cursos 
      GROUP BY tipo
    `);
    
    console.log('\n📊 Tipos de curso encontrados:');
    tiposResults.forEach(tipo => {
      console.log(`Tipo: '${tipo.tipo}' (${tipo.count} cursos)`);
    });
    
  } catch (error) {
    console.error('Erro:', error.message);
  } finally {
    await sequelize.close();
  }
})();
