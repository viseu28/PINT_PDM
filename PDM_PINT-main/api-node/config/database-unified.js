// CONFIGURAÇÃO UNIFICADA DE BASE DE DADOS
// Esta configuração permite usar a mesma base de dados tanto no localhost quanto no Render

const { Sequelize } = require('sequelize');

// Detectar ambiente
const isProduction = process.env.NODE_ENV === 'production';
const isRender = !!process.env.RENDER;

let sequelizeConfig;

if (isRender || process.env.DATABASE_URL) {
  // RENDER (Produção) - usar base de dados do Render
  sequelizeConfig = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    },
    logging: false
  });
} else {
  // LOCALHOST - conectar DIRETAMENTE à base de dados do Render
  // Assim localhost e Render usam a MESMA base de dados!
  sequelizeConfig = new Sequelize({
    database: process.env.DB_NAME || 'pint',
    username: process.env.DB_USER || 'grupo', 
    password: process.env.DB_PASSWORD || 'paswwordpint',
    host: process.env.DB_HOST || '172.201.108.53', // IP da base remota
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: false,
    pool: {
      max: 5,
      min: 1,
      acquire: 30000,
      idle: 10000,
    }
  });
}

module.exports = sequelizeConfig;
