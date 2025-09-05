const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = process.env.DATABASE_URL 
  ? new Sequelize(process.env.DATABASE_URL, {
      dialect: 'postgres',
      logging: false,
      dialectOptions: {
        ssl: false
      }
    })
  : new Sequelize(
      process.env.DB_NAME || 'pint', 
      process.env.DB_USER || 'grupo', 
      process.env.DB_PASSWORD || 'passwordpint', {
        host: process.env.DB_HOST || '172.201.108.53',
        dialect: 'postgres',
        port: process.env.DB_PORT || 5432,
        dialectOptions: {
          ssl: false
        }
      }
    );

(async () => {
  try {
    console.log('🔍 Verificando inscrições existentes...');
    
    // Buscar todas as inscrições
    const inscricoes = await sequelize.query(`
      SELECT i.idinscricao, i.idutilizador, i.idcurso, i.estado, i.datacriacao,
             u.nome as nome_usuario, c.nome as nome_curso
      FROM form_inscricao i
      LEFT JOIN utilizador u ON i.idutilizador = u.idutilizador
      LEFT JOIN curso c ON i.idcurso = c.idcurso
      ORDER BY i.datacriacao DESC
      LIMIT 20
    `, { type: sequelize.QueryTypes.SELECT });
    
    console.log('📊 Últimas 20 inscrições:');
    inscricoes.forEach(i => {
      console.log(`ID: ${i.idinscricao}, User: ${i.nome_usuario} (ID:${i.idutilizador}), Curso: ${i.nome_curso} (ID:${i.idcurso}), Estado: ${i.estado}, Data: ${i.datacriacao}`);
    });
    
    console.log('\n🔍 Verificando cursos mais recentes...');
    const cursosRecentes = await sequelize.query(`
      SELECT idcurso, nome, datacriacao, tipo
      FROM curso
      ORDER BY datacriacao DESC
      LIMIT 10
    `, { type: sequelize.QueryTypes.SELECT });
    
    console.log('📊 Últimos 10 cursos criados:');
    cursosRecentes.forEach(c => {
      console.log(`ID: ${c.idcurso}, Nome: ${c.nome}, Tipo: ${c.tipo}, Data: ${c.datacriacao}`);
    });
    
    await sequelize.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
})();
