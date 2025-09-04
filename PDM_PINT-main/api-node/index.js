require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Sequelize } = require('sequelize');
const initModels = require('./models/init-models');
const { FirebasePushService, initializeFirebase } = require('./services/firebase-push.service');

const app = express();
app.use(cors());
app.use(express.json());

// Servir arquivos estáticos da pasta uploads
app.use('/uploads', express.static('public/uploads'));

// Middleware para log de todas as requisições
app.use((req, res, next) => {
  console.log(`📨 ${req.method} ${req.url} - ${new Date().toISOString()}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('📤 Body:', req.body);
  }
  next();
});

// Configuração da base de dados usando variáveis de ambiente
const sequelize = process.env.DATABASE_URL 
  ? new Sequelize(process.env.DATABASE_URL, {
      dialect: 'postgres',
      pool: {
        max: 5,          // Máximo 5 conexões simultâneas
        min: 1,          // Mínimo 1 conexão
        acquire: 30000,  // Timeout para adquirir conexão (30s)
        idle: 10000,     // Tempo antes de fechar conexão inativa (10s)
      },
      logging: false,    // Desativar logs SQL para reduzir overhead
      retry: {
        max: 3,          // Máximo 3 tentativas de reconexão
      },
      dialectOptions: {
        ssl: process.env.NODE_ENV === 'production' ? {
          require: true,
          rejectUnauthorized: false
        } : false
      }
    })
  : new Sequelize(
      process.env.DB_NAME || 'pint', 
      process.env.DB_USER || 'grupo', 
      process.env.DB_PASSWORD || 'paswwordpint', {
        host: process.env.DB_HOST || '172.201.108.53',
        dialect: 'postgres',
        port: process.env.DB_PORT || 5432,
        pool: {
          max: 5,          // Máximo 5 conexões simultâneas
          min: 1,          // Mínimo 1 conexão
          acquire: 30000,  // Timeout para adquirir conexão (30s)
          idle: 10000,     // Tempo antes de fechar conexão inativa (10s)
        },
        logging: false,    // Desativar logs SQL para reduzir overhead
        retry: {
          max: 3,          // Máximo 3 tentativas de reconexão
        },
      }
    );

sequelize.authenticate()
  .then(async () => {
    console.log('Ligação à base de dados (Postgres) bem sucedida.');
    
    // Inicializar modelos
    console.log('🔄 Inicializando modelos...');
    const dbModels = initModels(sequelize);
    
    // Sincronizar base de dados (criar tabelas se não existirem)
    // Usar alter: true para modificar tabelas existentes sem apagar dados
    console.log('🔄 Sincronizando base de dados...');
    try {
      await sequelize.sync({ 
        force: false,
        alter: true,
        logging: console.log
      });
      console.log('✅ Base de dados sincronizada com sucesso!');
    } catch (syncError) {
      console.log('⚠️ Erro na sincronização inicial, tentando sincronização simples...');
      console.log('Erro:', syncError.message);
      
      // Se falhar, tentar sem foreign keys primeiro
      try {
        await sequelize.query('SET foreign_key_checks = 0;').catch(() => {});
        await sequelize.sync({ 
          force: false,
          logging: false
        });
        await sequelize.query('SET foreign_key_checks = 1;').catch(() => {});
        console.log('✅ Base de dados sincronizada com sucesso (modo alternativo)!');
      } catch (alternativeError) {
        console.log('❌ Erro na sincronização alternativa:', alternativeError.message);
      }
    }
    
    initializeFirebase();
  })
  .catch((err) => console.log('Erro ao ligar à base de dados (Postgres): ', err));

// Inicializar modelos
const dbModels = initModels(sequelize);

// Criar objeto db com modelos + sequelize
const db = {
  ...dbModels,
  sequelize
};

// Endpoint básico
app.get('/', (req, res) => {
  res.send('API SoftSkills a funcionar 🚀');
});

// Endpoint para verificar status da API e BD
app.get('/status', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.json({
      status: 'OK',
      database: 'Conectada ✅',
      api: 'SoftSkills funcionando',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      database: 'Desconectada ❌',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Health check endpoint para Flutter
app.get('/health', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.json({
      status: 'healthy',
      api: 'SoftSkills API',
      database: 'Conectada ✅',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      api: 'SoftSkills API', 
      database: 'Desconectada ❌',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para sincronizar/criar tabelas da base de dados
app.get('/sync-database', async (req, res) => {
  try {
    console.log('🔄 Iniciando sincronização da base de dados...');
    
    // Sincronizar todos os modelos (criar tabelas se não existirem)
    await sequelize.sync({ force: false }); // force: false para não apagar dados existentes
    
    console.log('✅ Base de dados sincronizada com sucesso!');
    res.json({
      status: 'success',
      message: 'Base de dados sincronizada com sucesso!',
      tables_created: 'Todas as tabelas foram criadas/verificadas',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Erro ao sincronizar base de dados:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao sincronizar base de dados',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para criar tabelas principais manualmente
app.get('/create-main-tables', async (req, res) => {
  try {
    console.log('🔄 Criando tabelas principais...');
    
    // Criar tabela utilizador primeiro
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS "public"."utilizador" (
        "idutilizador" SERIAL PRIMARY KEY,
        "nome" TEXT NOT NULL,
        "email" TEXT NOT NULL,
        "palavrapasse" TEXT NOT NULL,
        "tipo" TEXT NOT NULL,
        "datanascimento" DATE NOT NULL,
        "telemovel" TEXT NOT NULL,
        "morada" TEXT NOT NULL,
        "codigopostal" TEXT NOT NULL,
        "ultimoacesso" TIMESTAMP WITH TIME ZONE NOT NULL,
        "pontos" INTEGER NOT NULL DEFAULT 0,
        "cidade" TEXT,
        "pais" TEXT,
        "estado" TEXT DEFAULT 'ativo',
        "temquealterarpassword" BOOLEAN NOT NULL DEFAULT true
      );
    `);
    
    // Criar tabela cursos
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS "public"."cursos" (
        "id" SERIAL PRIMARY KEY,
        "titulo" VARCHAR(255) NOT NULL,
        "descricao" TEXT NOT NULL,
        "tema" VARCHAR(100) NOT NULL,
        "data_inicio" TIMESTAMP WITH TIME ZONE NOT NULL,
        "data_fim" TIMESTAMP WITH TIME ZONE NOT NULL,
        "tipo" VARCHAR(50) NOT NULL,
        "estado" VARCHAR(50) NOT NULL,
        "imgcurso" VARCHAR(255),
        "avaliacao" DECIMAL(3,2),
        "dificuldade" VARCHAR(50),
        "pontos" INTEGER DEFAULT 0
      );
    `);
    
    console.log('✅ Tabelas principais criadas com sucesso!');
    res.json({
      status: 'success',
      message: 'Tabelas principais criadas com sucesso!',
      tables_created: ['utilizador', 'cursos'],
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Erro ao criar tabelas principais:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao criar tabelas principais',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para inserir dados de teste
app.get('/insert-test-data', async (req, res) => {
  try {
    console.log('🔄 Inserindo dados de teste...');
    
    // Inserir utilizador de teste
    await sequelize.query(`
      INSERT INTO "public"."utilizador" 
      (nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword)
      VALUES 
      ('Utilizador Teste', 'softskillsformando@gmail.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'formando', '1990-01-01', '123456789', 'Rua Teste', '1234-567', NOW(), 0, 'Lisboa', 'Portugal', 'ativo', false)
      ON CONFLICT (email) DO NOTHING;
    `);
    
    // Inserir curso de teste
    await sequelize.query(`
      INSERT INTO "public"."cursos" 
      (titulo, descricao, tema, data_inicio, data_fim, tipo, estado, pontos)
      VALUES 
      ('Curso de Teste', 'Descrição do curso de teste', 'Soft Skills', NOW(), NOW() + INTERVAL '30 days', 'online', 'ativo', 100)
      ON CONFLICT DO NOTHING;
    `);
    
    console.log('✅ Dados de teste inseridos com sucesso!');
    res.json({
      status: 'success',
      message: 'Dados de teste inseridos com sucesso!',
      data_inserted: {
        user: 'softskillsformando@gmail.com',
        password: '123456',
        curso: 'Curso de Teste'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Erro ao inserir dados de teste:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao inserir dados de teste',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Percurso formativo endpoint
const percursoFormativoRoutes = require('./endpoints/percurso_formativo.endpoint')(db);
app.use('/percursoformativo', percursoFormativoRoutes);

// Rotas
const utilizadorRoutes = require('./endpoints/utilizador.endpoint')(db);
app.use('/utilizadores', utilizadorRoutes);

const cursoRoutes = require('./endpoints/curso.endpoint')(db);
app.use('/cursos', cursoRoutes);

const comentariosRoutes = require('./endpoints/comentarios.endpoint')(db);
app.use('/comentarios', comentariosRoutes);

const forumRoutes = require('./endpoints/forum.endpoint')(db);
app.use('/forum', forumRoutes);

const favoritosRoutes = require('./endpoints/favoritos.endpoint')(db);
app.use('/favoritos', favoritosRoutes);

const inscricoesRoutes = require('./endpoints/inscricoes.endpoint')(db);
app.use('/inscricoes', inscricoesRoutes);

const notificacoesRoutes = require('./endpoints/notificacoes.endpoint')(db);
app.use('/notificacoes', notificacoesRoutes);

const projetosRoutes = require('./endpoints/projetos.endpoint')(db);
app.use('/projetos', projetosRoutes);

const quizzesRoutes = require('./endpoints/quizzes.endpoint')(db);
app.use('/quizzes', quizzesRoutes);

// const materiaisRouter = require('./endpoints/materiais_apoio')(db);
// app.use('/materiais_apoio', materiaisRouter);

const respostaRoutes = require('./endpoints/resposta.endpoint')(db);
app.use('/respostas', respostaRoutes);

const guardadosRoutes = require('./endpoints/guardados.endpoint')(db);
app.use('/guardados', guardadosRoutes);

const likesForumRoutes = require('./endpoints/likes_forum.endpoint')(db);
app.use('/likes_forum', likesForumRoutes);

const denunciaRoutes = require('./endpoints/denuncia.endpoint')(db);
app.use('/denuncia', denunciaRoutes);

const fcmTokenRoutes = require('./endpoints/fcm-token.endpoint')(db);
app.use('/fcm-token', fcmTokenRoutes);

const forumPedidosRoutes = require('./endpoints/forum-pedidos.endpoint')(db);
app.use('/forum-pedidos', forumPedidosRoutes);

const projetosRouter = require('./endpoints/projetos.endpoint')(db);
app.use('/projetos', projetosRouter);

const permissoesRoutes = require('./endpoints/permissoes.endpoint')(db);
app.use('/permissoes', permissoesRoutes);

// Health check endpoint para Render
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    service: 'PINT PDM API'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'PINT PDM API está a funcionar!', 
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor a correr em http://0.0.0.0:${PORT}`);
});

// Graceful shutdown para fechar conexões adequadamente
process.on('SIGTERM', async () => {
  console.log('🔄 Encerrando servidor...');
  await sequelize.close();
  console.log('✅ Conexões fechadas');
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🔄 Encerrando servidor...');
  await sequelize.close();
  console.log('✅ Conexões fechadas');
  process.exit(0);
});
