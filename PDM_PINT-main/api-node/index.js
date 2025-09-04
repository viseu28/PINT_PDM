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

// Endpoint para importar dados via SQL (POST)
app.post('/import-data', async (req, res) => {
  try {
    console.log('📥 Iniciando importação de dados...');
    const { sqlStatements } = req.body;
    
    if (!sqlStatements || !Array.isArray(sqlStatements)) {
      return res.status(400).json({
        status: 'error',
        message: 'sqlStatements deve ser um array de comandos SQL'
      });
    }
    
    const results = [];
    const errors = [];
    
    // Executar cada comando SQL
    for (let i = 0; i < sqlStatements.length; i++) {
      const sql = sqlStatements[i].trim();
      if (sql.length === 0) continue;
      
      try {
        console.log(`📝 Executando SQL ${i + 1}/${sqlStatements.length}: ${sql.substring(0, 100)}...`);
        const result = await sequelize.query(sql);
        results.push({
          index: i,
          sql: sql.substring(0, 200) + '...',
          status: 'success',
          affectedRows: result[1]?.rowCount || 0
        });
      } catch (error) {
        console.error(`❌ Erro no SQL ${i + 1}:`, error.message);
        errors.push({
          index: i,
          sql: sql.substring(0, 200) + '...',
          error: error.message
        });
      }
    }
    
    console.log(`✅ Importação concluída: ${results.length} sucessos, ${errors.length} erros`);
    
    res.json({
      status: 'completed',
      message: `Importação concluída: ${results.length} sucessos, ${errors.length} erros`,
      successful_imports: results.length,
      failed_imports: errors.length,
      results: results,
      errors: errors,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na importação:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na importação de dados',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para exportar dados de uma tabela específica
app.get('/export-table/:tableName', async (req, res) => {
  try {
    const { tableName } = req.params;
    console.log(`📤 Exportando dados da tabela: ${tableName}`);
    
    // Verificar se a tabela existe
    const tableExists = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = :tableName
    `, {
      replacements: { tableName },
      type: sequelize.QueryTypes.SELECT
    });
    
    if (tableExists.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: `Tabela '${tableName}' não encontrada`
      });
    }
    
    // Obter dados da tabela
    const data = await sequelize.query(`SELECT * FROM "public"."${tableName}"`, {
      type: sequelize.QueryTypes.SELECT
    });
    
    console.log(`✅ ${data.length} registos exportados da tabela ${tableName}`);
    
    res.json({
      status: 'success',
      table: tableName,
      total_records: data.length,
      data: data,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na exportação:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na exportação de dados',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para verificar utilizador específico
app.get('/check-user/:email', async (req, res) => {
  try {
    const { email } = req.params;
    console.log(`🔍 Verificando utilizador: ${email}`);
    
    // Procurar utilizador na base de dados
    const user = await db.utilizador.findOne({
      where: { email: email }
    });
    
    if (user) {
      res.json({
        status: 'found',
        user: {
          id: user.idutilizador,
          nome: user.nome,
          email: user.email,
          tipo: user.tipo,
          estado: user.estado,
          temquealterarpassword: user.temquealterarpassword
        },
        login_conditions: {
          email_match: user.email === email,
          tipo_formando: user.tipo === 'formando',
          estado_ativo: user.estado === 'ativo',
          can_login: user.email === email && user.tipo === 'formando' && user.estado === 'ativo'
        },
        timestamp: new Date().toISOString()
      });
    } else {
      res.json({
        status: 'not_found',
        message: `Utilizador ${email} não encontrado`,
        timestamp: new Date().toISOString()
      });
    }
    
  } catch (error) {
    console.error('❌ Erro ao verificar utilizador:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao verificar utilizador',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para verificar todas as tabelas existentes
app.get('/check-tables', async (req, res) => {
  try {
    console.log('🔍 Verificando tabelas existentes...');
    
    // Listar todas as tabelas no schema public
    const tablesQuery = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
    
    const existingTables = tablesQuery[0].map(row => row.table_name);
    
    // Lista das tabelas esperadas (baseada na imagem do pgAdmin - 51 tabelas)
    const expectedTables = [
      'administra', 'administrador', 'analisa', 'areas', 'assincrono', 'aulas',
      'avaliacoes', 'categorias', 'comentarios', 'conteudo', 'curriculopendente',
      'cursos', 'cursos_recomendados', 'cursos_topicos', 'cursospendentes', 
      'denuncia', 'denuncia_comentario', 'disponibiliza', 'favoritos',
      'form_curriculo', 'form_inscricao', 'formador', 'formando', 'forum',
      'gerir_conteudo', 'gerir_curso', 'guardados', 'horariopessoal', 
      'horariosemanal', 'inscricao_curso', 'likes_forum', 'materiais_apoio',
      'materiais_links', 'material', 'notificacao', 'notificacoes',
      'pedidos_topicos', 'percursoformativo', 'permissoes', 'post', 'projetos',
      'projetos_submissoes', 'quizzes', 'recebe', 'resposta', 'respostas_quiz',
      'roles_permissoes', 'sincronos', 'tem_conteudo', 'topicos', 'utilizador'
    ];
    
    const missingTables = expectedTables.filter(table => !existingTables.includes(table));
    
    console.log(`✅ Encontradas ${existingTables.length} tabelas`);
    if (missingTables.length > 0) {
      console.log(`⚠️ Faltam ${missingTables.length} tabelas:`, missingTables);
    }
    
    res.json({
      status: 'success',
      total_existing: existingTables.length,
      total_expected: expectedTables.length,
      existing_tables: existingTables,
      missing_tables: missingTables,
      all_tables_present: missingTables.length === 0,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro ao verificar tabelas:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao verificar tabelas',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para forçar sincronização completa de TODAS as tabelas
app.get('/force-sync-all-tables', async (req, res) => {
  try {
    console.log('🔄 Forçando sincronização completa de TODAS as tabelas...');
    
    // Sincronizar com logging detalhado
    console.log('🔄 Iniciando sync com alter: true...');
    await sequelize.sync({ 
      force: false,  // Não apagar dados existentes
      alter: true,   // Permitir alterações de estrutura
      logging: (sql) => console.log('SQL:', sql)  // Ver todos os comandos SQL
    });
    
    // Verificar quantas tabelas foram criadas
    const tablesQuery = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
    
    const createdTables = tablesQuery[0].map(row => row.table_name);
    
    console.log(`✅ Sincronização completa! ${createdTables.length} tabelas disponíveis`);
    console.log('📋 Tabelas criadas:', createdTables.join(', '));
    
    res.json({
      status: 'success',
      message: 'Sincronização completa realizada com sucesso!',
      total_tables: createdTables.length,
      tables: createdTables,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na sincronização completa:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na sincronização completa',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para inserir dados de teste
app.get('/insert-test-data', async (req, res) => {
  try {
    console.log('🔄 Inserindo dados de teste...');
    
    // Usar Sequelize diretamente para inserir dados
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash('123456', 10);
    
    // Verificar se utilizador já existe
    const existingUser = await db.utilizador.findOne({
      where: { email: 'softskillsformando@gmail.com' }
    });
    
    if (!existingUser) {
      // Inserir utilizador de teste
      await db.utilizador.create({
        nome: 'Utilizador Teste',
        email: 'softskillsformando@gmail.com',
        palavrapasse: hashedPassword,
        tipo: 'formando',
        datanascimento: '1990-01-01',
        telemovel: '123456789',
        morada: 'Rua Teste',
        codigopostal: '1234-567',
        ultimoacesso: new Date(),
        pontos: 0,
        cidade: 'Lisboa',
        pais: 'Portugal',
        estado: 'ativo',
        temquealterarpassword: false
      });
    }
    
    // Verificar se curso já existe
    const existingCourse = await db.cursos.findOne({
      where: { titulo: 'Curso de Teste' }
    });
    
    if (!existingCourse) {
      await db.cursos.create({
        titulo: 'Curso de Teste',
        descricao: 'Descrição do curso de teste',
        tema: 'Soft Skills',
        data_inicio: new Date(),
        data_fim: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 dias
        tipo: 'online',
        estado: 'ativo',
        pontos: 100
      });
    }
    
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
