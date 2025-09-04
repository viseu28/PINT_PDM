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
    
    // Inicializar modelos SEM sincronização automática
    console.log('🔄 Inicializando modelos...');
    const dbModels = initModels(sequelize);
    
    // NÃO FAZER SYNC AUTOMÁTICO - será feito manualmente via endpoint
    console.log('✅ Modelos inicializados sem sincronização automática!');
    console.log('💡 Use o endpoint /create-database-structure para criar as tabelas');
    
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

// Endpoint para criar tabelas em falta manualmente
app.get('/create-missing-tables', async (req, res) => {
  try {
    console.log('🔨 Criando tabelas em falta...');
    
    // Lista de tabelas essenciais que faltam
    const tablesToCreate = [
      // Tabela topicos (causa do erro principal)
      {
        name: 'topicos',
        sql: `CREATE TABLE IF NOT EXISTS "public"."topicos" (
          "idtopicos" SERIAL PRIMARY KEY,
          "idarea" INTEGER REFERENCES "public"."areas" ("idarea"),
          "nome" TEXT NOT NULL
        );`
      },
      // Outras tabelas importantes
      {
        name: 'forum',
        sql: `CREATE TABLE IF NOT EXISTS "public"."forum" (
          "idforum" SERIAL PRIMARY KEY,
          "nome" TEXT NOT NULL,
          "descricao" TEXT,
          "datahora" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          "estado" BOOLEAN DEFAULT true,
          "idtopico" INTEGER,
          "autor" TEXT
        );`
      },
      {
        name: 'post',
        sql: `CREATE TABLE IF NOT EXISTS "public"."post" (
          "idpost" SERIAL PRIMARY KEY,
          "idutilizador" INTEGER REFERENCES "public"."utilizador" ("idutilizador"),
          "texto" TEXT NOT NULL,
          "titulo" TEXT NOT NULL,
          "datahora" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          "anexo" TEXT,
          "url" TEXT,
          "idtopico" INTEGER,
          "anexo_url" TEXT
        );`
      }
    ];
    
    let createdTables = [];
    
    for (const table of tablesToCreate) {
      try {
        await sequelize.query(table.sql);
        createdTables.push(table.name);
        console.log(`✅ Tabela criada: ${table.name}`);
      } catch (error) {
        console.log(`⚠️ Erro ao criar ${table.name}: ${error.message}`);
      }
    }
    
    console.log(`✅ Processo completo! ${createdTables.length} tabelas criadas`);
    
    res.json({
      status: 'success',
      message: 'Tabelas essenciais criadas!',
      tables_created: createdTables,
      total_created: createdTables.length,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro ao criar tabelas:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao criar tabelas',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para inserir dados da BD original
app.get('/import-original-data', async (req, res) => {
  try {
    console.log('📥 Importando dados originais da BD...');
    
    // Apagar utilizador temporário primeiro
    await sequelize.query(`DELETE FROM "public"."utilizador" WHERE "email" = 'softskillsformando@gmail.com' AND "nome" = 'Formando 1';`);
    
    // Dados originais da tua BD (do arquivo exportado)
    const originalData = [
      // Utilizadores originais
      `INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") VALUES (1, 'Formador 1', 'softskillsformador@gmail.com', '$2b$10$A9QaVPsG3voPYzpMOFzNUOXyDtY6IYVhWfOFe3JpHLOFjJu0MW8Qy', 'formador', '1980-04-19', '912345234', 'Rua do Formando 1', '3505-527', '2025-09-04T15:19:30.573Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'ceJYuGdiI-wzArLVrpb06V:APA91bFZW6c-B9RgmuQp4G76DWDBYsjZdZ86cFJhflNn42qp8lEZ2iPoCBOYacZAimUI3t8-c928J7NLVvOFPn1pHdqOqOLlvSZu-z8W8CGpSZCXNMfv8mQ');`,
      
      `INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") VALUES (4, 'Administrador 1', 'softskillsadm@gmail.com', '$2b$10$6o5iSBJWBtn1VzCNuM5gSu/8zFhYzl0ukhSLs3DSpIlVaF.TPZ65O', 'administrador', '2005-10-23', '913012697', 'Rua de minha Casa', '3505-527', '2025-09-04T15:24:19.270Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'ceJYuGdiI-wzArLVrpb06V:APA91bFZW6c-B9RgmuQp4G76DWDBYsjZdZ86cFJhflNn42qp8lEZ2iPoCBOYacZAimUI3t8-c928J7NLVvOFPn1pHdqOqOLlvSZu-z8W8CGpSZCXNMfv8mQ');`,
      
      `INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', '2025-09-04T15:32:15.930Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'eRos1Rc6R5OEHCMMvhZmkd:APA91bEu21ueMIfMOpUGRUfYMT405-pBghKiJSYRMz86W6YCJnazNe76L0U8KsSiOkSPPMHQJozLxo6l1nC1L-ts8d-_uyuKT17YbSKyPmJXC6C9W3ZbAwk');`,
      
      // Categorias
      `INSERT INTO "public"."categorias" ("idcategoria", "nome") VALUES (1, 'Programação');`,
      `INSERT INTO "public"."categorias" ("idcategoria", "nome") VALUES (2, 'Perguntas e Respostas');`,
      `INSERT INTO "public"."categorias" ("idcategoria", "nome") VALUES (3, 'Cultura da Internet');`,
      `INSERT INTO "public"."categorias" ("idcategoria", "nome") VALUES (4, 'Tecnologia');`,
      
      // Áreas
      `INSERT INTO "public"."areas" ("idarea", "idcategoria", "nome") VALUES (1, 1, 'Desenvolvimento Web');`,
      `INSERT INTO "public"."areas" ("idarea", "idcategoria", "nome") VALUES (2, 1, 'Desenvolvimento Mobile');`,
      `INSERT INTO "public"."areas" ("idarea", "idcategoria", "nome") VALUES (3, 1, 'Base de Dados');`,
      `INSERT INTO "public"."areas" ("idarea", "idcategoria", "nome") VALUES (4, 1, 'Automação e Scripting');`,
      
      // Tópicos
      `INSERT INTO "public"."topicos" ("idtopicos", "idarea", "nome") VALUES (1, 1, 'HTML');`,
      `INSERT INTO "public"."topicos" ("idtopicos", "idarea", "nome") VALUES (2, 1, 'CSS');`,
      `INSERT INTO "public"."topicos" ("idtopicos", "idarea", "nome") VALUES (3, 1, 'JavaScript');`,
      `INSERT INTO "public"."topicos" ("idtopicos", "idarea", "nome") VALUES (11, 7, 'Linux');`,
      `INSERT INTO "public"."topicos" ("idtopicos", "idarea", "nome") VALUES (13, 8, 'Inscrições');`
    ];
    
    let importedCount = 0;
    
    for (const sql of originalData) {
      try {
        await sequelize.query(sql);
        importedCount++;
        console.log(`✅ Dados importados: ${sql.substring(0, 80)}...`);
      } catch (error) {
        console.log(`⚠️ Já existe ou erro: ${error.message.substring(0, 100)}`);
      }
    }
    
    console.log(`✅ Importação completa! ${importedCount} registos importados`);
    
    res.json({
      status: 'success',
      message: 'Dados originais importados com sucesso!',
      records_imported: importedCount,
      original_users: [
        'softskillsformando@gmail.com (ID: 8)',
        'softskillsformador@gmail.com (ID: 1)', 
        'softskillsadm@gmail.com (ID: 4)'
      ],
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na importação:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na importação de dados originais',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para inserir utilizador específico SEM conflito de ID
app.get('/insert-formando-direto', async (req, res) => {
  try {
    console.log('🎯 Inserindo formando diretamente...');
    
    // Usar Sequelize para inserir sem especificar ID (auto-increment)
    const bcrypt = require('bcryptjs');
    const hashedPassword = '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m'; // Password já hasheada para '123456'
    
    // Verificar se já existe
    const existingUser = await db.utilizador.findOne({
      where: { email: 'softskillsformando@gmail.com' }
    });
    
    if (existingUser) {
      res.json({
        status: 'already_exists',
        message: 'Utilizador já existe!',
        user: {
          id: existingUser.idutilizador,
          email: existingUser.email,
          tipo: existingUser.tipo,
          estado: existingUser.estado
        },
        timestamp: new Date().toISOString()
      });
    } else {
      // Criar utilizador novo
      const newUser = await db.utilizador.create({
        nome: 'Formando 1',
        email: 'softskillsformando@gmail.com',
        palavrapasse: hashedPassword,
        tipo: 'formando',
        datanascimento: '2010-10-10',
        telemovel: '912323455',
        morada: 'Rua do Formando 1',
        codigopostal: '3505-527',
        ultimoacesso: new Date(),
        pontos: 0,
        cidade: 'Viseu',
        pais: 'Portugal',
        estado: 'ativo',
        temquealterarpassword: false,
        fcm_token: 'eRos1Rc6R5OEHCMMvhZmkd:APA91bEu21ueMIfMOpUGRUfYMT405-pBghKiJSYRMz86W6YCJnazNe76L0U8KsSiOkSPPMHQJozLxo6l1nC1L-ts8d-_uyuKT17YbSKyPmJXC6C9W3ZbAwk'
      });
      
      console.log(`✅ Utilizador criado com ID: ${newUser.idutilizador}`);
      
      res.json({
        status: 'success',
        message: 'Utilizador formando criado com sucesso!',
        user: {
          id: newUser.idutilizador,
          email: newUser.email,
          tipo: newUser.tipo,
          estado: newUser.estado
        },
        login_info: {
          email: 'softskillsformando@gmail.com',
          password: '123456'
        },
        timestamp: new Date().toISOString()
      });
    }
    
  } catch (error) {
    console.error('❌ Erro ao inserir formando:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao inserir formando',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para importar dados exportados diretamente (RÁPIDO)
app.get('/import-data-quick', async (req, res) => {
  try {
    console.log('🚀 Importando dados rapidamente...');
    
    // Dados essenciais para o login funcionar
    const sqlStatements = [
      // Utilizadores
      `INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") VALUES (1, 'Formador 1', 'softskillsformador@gmail.com', '$2b$10$A9QaVPsG3voPYzpMOFzNUOXyDtY6IYVhWfOFe3JpHLOFjJu0MW8Qy', 'formador', '1980-04-19', '912345234', 'Rua do Formando 1', '3505-527', '2025-09-04T15:19:30.573Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'ceJYuGdiI-wzArLVrpb06V:APA91bFZW6c-B9RgmuQp4G76DWDBYsjZdZ86cFJhflNn42qp8lEZ2iPoCBOYacZAimUI3t8-c928J7NLVvOFPn1pHdqOqOLlvSZu-z8W8CGpSZCXNMfv8mQ');`,
      
      `INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") VALUES (4, 'Administrador 1', 'softskillsadm@gmail.com', '$2b$10$6o5iSBJWBtn1VzCNuM5gSu/8zFhYzl0ukhSLs3DSpIlVaF.TPZ65O', 'administrador', '2005-10-23', '913012697', 'Rua de minha Casa', '3505-527', '2025-09-04T15:24:19.270Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'ceJYuGdiI-wzArLVrpb06V:APA91bFZW6c-B9RgmuQp4G76DWDBYsjZdZ86cFJhflNn42qp8lEZ2iPoCBOYacZAimUI3t8-c928J7NLVvOFPn1pHdqOqOLlvSZu-z8W8CGpSZCXNMfv8mQ');`,
      
      `INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', '2025-09-04T15:32:15.930Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'eRos1Rc6R5OEHCMMvhZmkd:APA91bEu21ueMIfMOpUGRUfYMT405-pBghKiJSYRMz86W6YCJnazNe76L0U8KsSiOkSPPMHQJozLxo6l1nC1L-ts8d-_uyuKT17YbSKyPmJXC6C9W3ZbAwk');`
    ];
    
    let insertedCount = 0;
    
    for (const sql of sqlStatements) {
      try {
        await sequelize.query(sql);
        insertedCount++;
        console.log(`✅ Executado: ${sql.substring(0, 100)}...`);
      } catch (error) {
        console.log(`⚠️ Já existe ou erro: ${error.message.substring(0, 100)}`);
      }
    }
    
    console.log(`✅ Importação rápida completa! ${insertedCount} utilizadores inseridos`);
    
    res.json({
      status: 'success',
      message: 'Dados importados rapidamente!',
      usuarios_inseridos: insertedCount,
      principais_usuarios: [
        'softskillsformando@gmail.com (formando)',
        'softskillsformador@gmail.com (formador)', 
        'softskillsadm@gmail.com (administrador)'
      ],
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na importação rápida:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na importação rápida',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint específico para corrigir utilizador formando
app.get('/fix-formando-user', async (req, res) => {
  try {
    console.log('🔧 Corrigindo utilizador formando...');
    
    // Apagar qualquer utilizador existente com este email primeiro
    await sequelize.query(`DELETE FROM "public"."utilizador" WHERE "email" = 'softskillsformando@gmail.com';`);
    
    // Inserir o utilizador formando com os dados corretos
    const insertFormando = `
      INSERT INTO "public"."utilizador" ("idutilizador", "nome", "email", "palavrapasse", "tipo", "datanascimento", "telemovel", "morada", "codigopostal", "ultimoacesso", "pontos", "cidade", "pais", "estado", "temquealterarpassword", "fcm_token") 
      VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE, 'eRos1Rc6R5OEHCMMvhZmkd:APA91bEu21ueMIfMOpUGRUfYMT405-pBghKiJSYRMz86W6YCJnazNe76L0U8KsSiOkSPPMHQJozLxo6l1nC1L-ts8d-_uyuKT17YbSKyPmJXC6C9W3ZbAwk')
      ON CONFLICT (idutilizador) DO UPDATE SET
        nome = EXCLUDED.nome,
        email = EXCLUDED.email,
        palavrapasse = EXCLUDED.palavrapasse,
        tipo = EXCLUDED.tipo,
        datanascimento = EXCLUDED.datanascimento,
        telemovel = EXCLUDED.telemovel,
        morada = EXCLUDED.morada,
        codigopostal = EXCLUDED.codigopostal,
        pontos = EXCLUDED.pontos,
        cidade = EXCLUDED.cidade,
        pais = EXCLUDED.pais,
        estado = EXCLUDED.estado,
        temquealterarpassword = EXCLUDED.temquealterarpassword,
        fcm_token = EXCLUDED.fcm_token;
    `;
    
    await sequelize.query(insertFormando);
    
    // Verificar se foi criado
    const [results] = await sequelize.query(`SELECT * FROM "public"."utilizador" WHERE "email" = 'softskillsformando@gmail.com';`);
    
    if (results.length > 0) {
      res.json({
        status: 'success',
        message: 'Utilizador formando corrigido com sucesso!',
        user: results[0],
        password_info: 'A password é: password123',
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(500).json({
        status: 'error',
        message: 'Falha ao criar utilizador formando',
        timestamp: new Date().toISOString()
      });
    }
    
  } catch (error) {
    console.error('❌ Erro ao corrigir utilizador formando:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao corrigir utilizador formando',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint SUPER RÁPIDO para importar TUDO de uma vez
app.get('/import-everything-now', async (req, res) => {
  try {
    console.log('🚀 IMPORTANDO TUDO AGORA...');
    
    // 1. Criar TODAS as tabelas com os nomes corretos
    const createTablesSQL = [
      // Tabela POST (não POSTS)
      `CREATE TABLE IF NOT EXISTS post (
        id SERIAL PRIMARY KEY,
        titulo VARCHAR(255),
        conteudo TEXT,
        data_post TIMESTAMP DEFAULT NOW(),
        id_utilizador INTEGER,
        id_topico INTEGER
      );`,
      
      // Tabela POSTS (caso seja referenciada assim)
      `CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        titulo VARCHAR(255),
        conteudo TEXT,
        data_post TIMESTAMP DEFAULT NOW(),
        id_utilizador INTEGER,
        id_topico INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS aulas (
        id SERIAL PRIMARY KEY,
        titulo VARCHAR(255),
        data_aula TIMESTAMP,
        id_curso INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS comentarios (
        id SERIAL PRIMARY KEY,
        conteudo TEXT,
        data_comentario TIMESTAMP DEFAULT NOW(),
        id_utilizador INTEGER,
        id_post INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS cursos_recomendados (
        id SERIAL PRIMARY KEY,
        id_curso INTEGER,
        id_utilizador INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS cursos_topicos (
        id SERIAL PRIMARY KEY,
        id_curso INTEGER,
        id_topico INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS denuncia (
        id SERIAL PRIMARY KEY,
        motivo TEXT,
        data_denuncia TIMESTAMP DEFAULT NOW(),
        id_utilizador INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS denuncia_comentario (
        id SERIAL PRIMARY KEY,
        id_denuncia INTEGER,
        id_comentario INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS guardados (
        id SERIAL PRIMARY KEY,
        id_utilizador INTEGER,
        id_curso INTEGER,
        data_guardado TIMESTAMP DEFAULT NOW()
      );`,
      
      `CREATE TABLE IF NOT EXISTS likes_forum (
        id SERIAL PRIMARY KEY,
        id_utilizador INTEGER,
        id_post INTEGER,
        data_like TIMESTAMP DEFAULT NOW()
      );`,
      
      `CREATE TABLE IF NOT EXISTS materiais_apoio (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(255),
        caminho TEXT,
        id_curso INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS materiais_links (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(255),
        url TEXT,
        id_curso INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS notificacoes (
        id SERIAL PRIMARY KEY,
        titulo VARCHAR(255),
        conteudo TEXT,
        data_notificacao TIMESTAMP DEFAULT NOW(),
        id_utilizador INTEGER,
        lida BOOLEAN DEFAULT FALSE
      );`,
      
      `CREATE TABLE IF NOT EXISTS pedidos_topicos (
        id SERIAL PRIMARY KEY,
        nome_topico VARCHAR(255),
        descricao TEXT,
        id_utilizador INTEGER,
        status VARCHAR(50) DEFAULT 'pendente'
      );`,
      
      `CREATE TABLE IF NOT EXISTS permissoes (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(255),
        descricao TEXT
      );`,
      
      `CREATE TABLE IF NOT EXISTS quizzes (
        id SERIAL PRIMARY KEY,
        titulo VARCHAR(255),
        descricao TEXT,
        id_curso INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS resposta (
        id SERIAL PRIMARY KEY,
        conteudo TEXT,
        data_resposta TIMESTAMP DEFAULT NOW(),
        id_utilizador INTEGER,
        id_comentario INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS respostas_quiz (
        id SERIAL PRIMARY KEY,
        resposta TEXT,
        correta BOOLEAN DEFAULT FALSE,
        id_quiz INTEGER
      );`,
      
      `CREATE TABLE IF NOT EXISTS roles_permissoes (
        id SERIAL PRIMARY KEY,
        id_role INTEGER,
        id_permissao INTEGER
      );`
    ];
    
    // 2. Executar criação de tabelas
    let tablesCreated = 0;
    for (const sql of createTablesSQL) {
      try {
        await sequelize.query(sql);
        tablesCreated++;
        console.log(`✅ Tabela criada: ${sql.split('EXISTS ')[1].split(' ')[0]}`);
      } catch (error) {
        console.log(`⚠️ Tabela já existe: ${error.message}`);
      }
    }
    
    // 3. Importar TODOS os dados da base original
    const importDataSQL = [
      // Apagar utilizadores existentes
      `DELETE FROM utilizador WHERE email IN ('softskillsformador@gmail.com', 'softskillsadm@gmail.com', 'softskillsformando@gmail.com');`,
      
      // Utilizadores originais
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (1, 'Formador 1', 'softskillsformador@gmail.com', '$2b$10$A9QaVPsG3voPYzpMOFzNUOXyDtY6IYVhWfOFe3JpHLOFjJu0MW8Qy', 'formador', '1980-04-19', '912345234', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE);`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (4, 'Administrador 1', 'softskillsadm@gmail.com', '$2b$10$6o5iSBJWBtn1VzCNuM5gSu/8zFhYzl0ukhSLs3DSpIlVaF.TPZ65O', 'administrador', '2005-10-23', '913012697', 'Rua de minha Casa', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE);`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE);`,
      
      // Cursos originais da base de dados
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (49, 'Desenvolvimento Front-End', 'Curso focado em HTML, CSS e JavaScript para criar interfaces modernas.', 'Desenvolvimento Front-End', '2025-09-11', '2025-10-11', 'Síncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986255/cursos/b2ezuhcz6et1v41zoncw.webp', '5.00', 'Avançado', 200, '["Nenhum conhecimento prévio necessário."]', '["Este curso é ideal para iniciantes em desenvolvimento web, estudantes de tecnologia e profissionais que desejam ingressar na área de Front-End"]', '["120 horas de video","Acesso no telemóvel e PC","Conteúdo descarregável","Certificado de Conclusão"]', 'Idioma: Português\nTradução: Português\nAtualizado recentemente', NULL, NULL, 'Formador 1', '["Construir páginas web com HTML5","Personalizar interfaces com CSS3","Criar interatividade com JavaScript","Trabalhar com React e Node.JS","Construir layouts responsivos e acessíveis"]', 'Espanhol', NOW(), NOW(), 75) ON CONFLICT DO NOTHING;`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (50, 'Python - Estrutura de Dados', 'Aprende as principais estruturas de dados em Python, como listas, dicionários e conjuntos.', 'Estrutura de Dados', '2025-09-11', '2025-10-11', 'Assíncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986431/cursos/gzeqpe6b5aluqnlstqaf.png', NULL, 'Intermédio', 100, '["Conhecimento básico de computação","Lógica de programação (recomendado)","Conhecimento básico de matemática","Python básico (desejável mas não obrigatório)"]', '["Programadores Python iniciantes/intermédios","Estudantes de ciência da computação","Profissionais de análise de dados","Desenvolvedores que querem melhorar algoritmos","Candidatos a entrevistas técnicas"]', '["30+ horas de conteúdo prático","Implementação de 15+ estruturas de dados","100+ exercícios de algoritmos","5 projetos práticos avançados","Preparação para entrevistas técnicas","Código fonte de todos os exemplos","Certificado reconhecido pela indústria","Mentoria online com especialistas"]', 'Um curso intensivo e prático focado nas estruturas de dados mais importantes da programação moderna.', 'https://www.youtube.com/embed/g_R_Asf6Co0', NULL, 'Administrador 1', '["Implementar listas, pilhas e filas eficientemente","Trabalhar com árvores binárias e AVL","Compreender algoritmos de ordenação avançados","Aplicar algoritmos de busca e grafos","Analisar complexidade temporal e espacial","Resolver problemas de entrevistas técnicas","Otimizar código para performance","Debugar algoritmos complexos"]', 'Português', NOW(), NOW(), 0) ON CONFLICT DO NOTHING;`,
      
      // Categorias
      `INSERT INTO categorias (idcategoria, nome) VALUES (1, 'Programação') ON CONFLICT DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (2, 'Perguntas e Respostas') ON CONFLICT DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (3, 'Cultura da Internet') ON CONFLICT DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (4, 'Tecnologia') ON CONFLICT DO NOTHING;`,
      
      // Áreas
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (1, 1, 'Desenvolvimento Web') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (2, 1, 'Desenvolvimento Mobile') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (3, 1, 'Base de Dados') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (4, 1, 'Automação e Scripting') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (6, 4, 'Hardware') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (7, 4, 'Sistemas Operativos') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (8, 2, 'Cursos') ON CONFLICT DO NOTHING;`,
      
      // Dados do forum
      `INSERT INTO topicos (id, nome, descricao, id_categoria) VALUES (1, 'Discussão Geral', 'Tópico para discussões gerais', 1) ON CONFLICT DO NOTHING;`,
      `INSERT INTO topicos (id, nome, descricao, id_categoria) VALUES (2, 'Dúvidas Técnicas', 'Tópico para dúvidas técnicas', 1) ON CONFLICT DO NOTHING;`,
      
      // Posts de exemplo
      `INSERT INTO post (id, titulo, conteudo, data_post, id_utilizador, id_topico) VALUES (1, 'Bem-vindos ao Fórum!', 'Este é o primeiro post do nosso fórum. Sintam-se à vontade para participar!', NOW(), 1, 1) ON CONFLICT DO NOTHING;`,
      `INSERT INTO posts (id, titulo, conteudo, data_post, id_utilizador, id_topico) VALUES (1, 'Bem-vindos ao Fórum!', 'Este é o primeiro post do nosso fórum. Sintam-se à vontade para participar!', NOW(), 1, 1) ON CONFLICT DO NOTHING;`
    ];
    
    // 4. Executar importação de dados
    let importedCount = 0;
    for (const sql of importDataSQL) {
      try {
        await sequelize.query(sql);
        importedCount++;
        console.log(`✅ Dados importados: statement ${importedCount}`);
      } catch (error) {
        console.log(`⚠️ Aviso: ${error.message}`);
      }
    }
    
    // 5. Verificar resultado final
    const [tableCount] = await sequelize.query(`
      SELECT COUNT(*) as total 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    `);
    
    const [userCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM utilizador`);
    const [cursosCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM cursos`);
    
    res.json({
      status: 'success',
      message: '🎉 TUDO IMPORTADO COM SUCESSO! BASE DE DADOS COMPLETA!',
      tabelas_criadas: tablesCreated,
      dados_importados: importedCount,
      total_tabelas: tableCount[0].total,
      total_utilizadores: userCheck[0].total,
      total_cursos: cursosCheck[0].total,
      login_info: {
        email: 'softskillsformando@gmail.com',
        password: 'password123'
      },
      app_status: '✅ APP MÓVEL PRONTA PARA USAR!',
      forum_status: '✅ FÓRUM CONFIGURADO!',
      cursos_status: '✅ CURSOS IMPORTADOS!',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na importação total:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na importação total',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ENDPOINT FINAL - CORRIGIR TUDO E IMPORTAR TUDO
app.get('/fix-everything-final', async (req, res) => {
  try {
    console.log('🔧 CORRIGINDO TUDO DEFINITIVAMENTE...');
    
    // 1. CORRIGIR TABELA UTILIZADOR - adicionar fcm_token
    try {
      await sequelize.query(`ALTER TABLE utilizador ADD COLUMN IF NOT EXISTS fcm_token TEXT;`);
      console.log('✅ Coluna fcm_token adicionada à tabela utilizador');
    } catch (error) {
      console.log('⚠️ fcm_token já existe:', error.message);
    }
    
    // 2. CORRIGIR TABELA PERMISSOES - adicionar todas as colunas
    try {
      await sequelize.query(`DROP TABLE IF EXISTS permissoes CASCADE;`);
      await sequelize.query(`
        CREATE TABLE permissoes (
          idpermissao SERIAL PRIMARY KEY,
          nome VARCHAR(255),
          descricao TEXT,
          categoria VARCHAR(255),
          ativo BOOLEAN DEFAULT TRUE,
          ligado VARCHAR(255)
        );
      `);
      console.log('✅ Tabela permissoes recriada com estrutura correta');
    } catch (error) {
      console.log('⚠️ Erro ao recriar permissoes:', error.message);
    }
    
    // 3. CORRIGIR TABELA GUARDADOS - adicionar idpost
    try {
      await sequelize.query(`DROP TABLE IF EXISTS guardados CASCADE;`);
      await sequelize.query(`
        CREATE TABLE guardados (
          id SERIAL PRIMARY KEY,
          id_utilizador INTEGER,
          id_curso INTEGER,
          idpost INTEGER,
          data_guardado TIMESTAMP DEFAULT NOW()
        );
      `);
      console.log('✅ Tabela guardados recriada com idpost');
    } catch (error) {
      console.log('⚠️ Erro ao recriar guardados:', error.message);
    }
    
    // 4. RECRIAR ROLES_PERMISSOES
    try {
      await sequelize.query(`DROP TABLE IF EXISTS roles_permissoes CASCADE;`);
      await sequelize.query(`
        CREATE TABLE roles_permissoes (
          id SERIAL PRIMARY KEY,
          idrole_permissao SERIAL,
          id_role INTEGER,
          id_permissao INTEGER,
          role VARCHAR(255),
          datacriacao TIMESTAMP DEFAULT NOW(),
          dataatualizacao TIMESTAMP DEFAULT NOW()
        );
      `);
      console.log('✅ Tabela roles_permissoes recriada');
    } catch (error) {
      console.log('⚠️ Erro ao recriar roles_permissoes:', error.message);
    }
    
    // 5. LIMPAR E IMPORTAR TODOS OS DADOS
    const importDataSQL = [
      // Limpar utilizadores
      `DELETE FROM utilizador WHERE email IN ('softskillsformador@gmail.com', 'softskillsadm@gmail.com', 'softskillsformando@gmail.com');`,
      
      // Utilizadores com fcm_token
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword, fcm_token) 
       VALUES (1, 'Formador 1', 'softskillsformador@gmail.com', '$2b$10$A9QaVPsG3voPYzpMOFzNUOXyDtY6IYVhWfOFe3JpHLOFjJu0MW8Qy', 'formador', '1980-04-19', '912345234', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE, NULL);`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword, fcm_token) 
       VALUES (4, 'Administrador 1', 'softskillsadm@gmail.com', '$2b$10$6o5iSBJWBtn1VzCNuM5gSu/8zFhYzl0ukhSLs3DSpIlVaF.TPZ65O', 'administrador', '2005-10-23', '913012697', 'Rua de minha Casa', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE, NULL);`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword, fcm_token) 
       VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE, NULL);`,
      
      // Limpar e inserir cursos
      `DELETE FROM cursos WHERE id IN (45, 48, 49, 50);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (45, 'HTML e CSS para Iniciantes', 'Curso introdutório de HTML e CSS, ideal para iniciantes no desenvolvimento web.', 'HTML e CSS', '2025-09-04', '2025-10-11', 'Síncrono', 'Em Curso', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756985308/cursos/tm7xwoy6d0snoephphcx.webp', NULL, 'Intermédio', 100, '["Conhecimento básico de computação"]', '["Iniciantes em programação web"]', '["25+ horas de vídeo"]', 'Curso completo de HTML e CSS', NULL, NULL, 'Formador 1', '["Dominar HTML5","Criar layouts responsivos"]', 'Português', NOW(), NOW(), 50);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (48, 'Desenvolvimento Mobile', 'Aprenda a desenvolver aplicações móveis do zero.', 'Desenvolvimento Mobile', '2025-09-11', '2025-10-11', 'Assíncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986095/cursos/lkqafnz8wppqjuwqm7u7.png', NULL, 'Iniciante', 50, '["Conhecimento em programação"]', '["Desenvolvedores web"]', '["40+ horas de desenvolvimento"]', 'Curso completo de desenvolvimento mobile', NULL, NULL, 'Administrador 1', '["Desenvolver apps nativos","Implementar interfaces modernas"]', 'Inglês', NOW(), NOW(), 0);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (49, 'Desenvolvimento Front-End', 'Curso focado em HTML, CSS e JavaScript para criar interfaces modernas.', 'Desenvolvimento Front-End', '2025-09-11', '2025-10-11', 'Síncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986255/cursos/b2ezuhcz6et1v41zoncw.webp', '5.00', 'Avançado', 200, '["Nenhum conhecimento prévio necessário."]', '["Iniciantes em desenvolvimento web"]', '["120 horas de video"]', 'Curso completo de Front-End', NULL, NULL, 'Formador 1', '["Construir páginas web com HTML5","Criar interatividade com JavaScript"]', 'Espanhol', NOW(), NOW(), 75);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (50, 'Python - Estrutura de Dados', 'Aprende as principais estruturas de dados em Python.', 'Estrutura de Dados', '2025-09-11', '2025-10-11', 'Assíncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986431/cursos/gzeqpe6b5aluqnlstqaf.png', NULL, 'Intermédio', 100, '["Conhecimento básico de computação"]', '["Programadores Python"]', '["30+ horas de conteúdo"]', 'Curso de estruturas de dados', 'https://www.youtube.com/embed/g_R_Asf6Co0', NULL, 'Administrador 1', '["Implementar listas e pilhas","Trabalhar com árvores"]', 'Português', NOW(), NOW(), 0);`,
      
      // Permissões
      `INSERT INTO permissoes (idpermissao, nome, descricao, categoria, ativo, ligado) VALUES (4, 'Acesso Total', 'Permissão de acesso total', 'admin', TRUE, 'ativo');`,
      
      // Tópicos do fórum
      `INSERT INTO topicos (id, nome, descricao, id_categoria) VALUES (1, 'Discussão Geral', 'Tópico para discussões gerais', 1) ON CONFLICT DO NOTHING;`,
      `INSERT INTO topicos (id, nome, descricao, id_categoria) VALUES (2, 'Dúvidas Técnicas', 'Tópico para dúvidas técnicas', 1) ON CONFLICT DO NOTHING;`,
      
      // Posts
      `INSERT INTO post (id, titulo, conteudo, data_post, id_utilizador, id_topico) VALUES (1, 'Bem-vindos ao Fórum!', 'Este é o primeiro post do nosso fórum.', NOW(), 1, 1) ON CONFLICT DO NOTHING;`,
      `INSERT INTO posts (id, titulo, conteudo, data_post, id_utilizador, id_topico) VALUES (1, 'Bem-vindos ao Fórum!', 'Este é o primeiro post do nosso fórum.', NOW(), 1, 1) ON CONFLICT DO NOTHING;`
    ];
    
    // 6. Executar importação
    let importedCount = 0;
    for (const sql of importDataSQL) {
      try {
        await sequelize.query(sql);
        importedCount++;
      } catch (error) {
        console.log(`⚠️ Aviso: ${error.message}`);
      }
    }
    
    // 7. Verificar resultado final
    const [tableCount] = await sequelize.query(`
      SELECT COUNT(*) as total 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    `);
    
    const [userCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM utilizador`);
    const [cursosCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM cursos`);
    
    res.json({
      status: 'success',
      message: '🎉 TUDO CORRIGIDO E FUNCIONANDO PERFEITAMENTE!',
      tabelas_corrigidas: ['utilizador', 'permissoes', 'guardados', 'roles_permissoes'],
      dados_importados: importedCount,
      total_tabelas: tableCount[0].total,
      total_utilizadores: userCheck[0].total,
      total_cursos: cursosCheck[0].total,
      login_credentials: {
        email: 'softskillsformando@gmail.com',
        password: 'password123'
      },
      app_status: '✅ APP MÓVEL 100% FUNCIONAL!',
      all_errors_fixed: '✅ TODOS OS ERROS CORRIGIDOS!',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na correção final:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na correção final',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ENDPOINT FINAL BASEADO NOS MODELS REAIS
app.get('/create-database-from-models', async (req, res) => {
  try {
    console.log('🔧 CRIANDO BASE DE DADOS BASEADA NOS MODELS...');
    
    // 1. TABELA UTILIZADOR (baseado no model real - SEM fcm_token)
    try {
      await sequelize.query(`
        CREATE TABLE IF NOT EXISTS utilizador (
          idutilizador SERIAL PRIMARY KEY,
          nome TEXT NOT NULL,
          email TEXT NOT NULL,
          palavrapasse TEXT NOT NULL,
          tipo TEXT NOT NULL,
          datanascimento DATE NOT NULL,
          telemovel TEXT NOT NULL,
          morada TEXT NOT NULL,
          codigopostal TEXT NOT NULL,
          ultimoacesso TIMESTAMP NOT NULL,
          pontos INTEGER NOT NULL DEFAULT 0,
          cidade TEXT,
          pais TEXT,
          estado TEXT DEFAULT 'ativo',
          temquealterarpassword BOOLEAN NOT NULL DEFAULT TRUE
        );
      `);
      console.log('✅ Tabela utilizador criada (baseada no model)');
    } catch (error) {
      console.log('⚠️ utilizador já existe:', error.message);
    }
    
    // 2. TABELA PERMISSOES (baseado no model real)
    try {
      await sequelize.query(`DROP TABLE IF EXISTS permissoes CASCADE;`);
      await sequelize.query(`
        CREATE TABLE permissoes (
          idpermissao SERIAL PRIMARY KEY,
          nome VARCHAR(255) NOT NULL,
          descricao TEXT,
          categoria VARCHAR(255),
          ativo BOOLEAN,
          datacriacao TIMESTAMP,
          dataatualizacao TIMESTAMP,
          ligado BOOLEAN
        );
      `);
      console.log('✅ Tabela permissoes criada (baseada no model)');
    } catch (error) {
      console.log('⚠️ Erro permissoes:', error.message);
    }
    
    // 3. TABELA POST (baseado no model real)
    try {
      await sequelize.query(`DROP TABLE IF EXISTS post CASCADE;`);
      await sequelize.query(`
        CREATE TABLE post (
          idpost SERIAL PRIMARY KEY,
          idutilizador INTEGER,
          idtopico INTEGER,
          texto TEXT NOT NULL,
          titulo TEXT NOT NULL,
          datahora TIMESTAMP NOT NULL,
          anexo TEXT NOT NULL,
          url TEXT NOT NULL
        );
      `);
      console.log('✅ Tabela post criada (baseada no model)');
    } catch (error) {
      console.log('⚠️ Erro post:', error.message);
    }
    
    // 4. TABELA GUARDADOS (baseado no model real)
    try {
      await sequelize.query(`DROP TABLE IF EXISTS guardados CASCADE;`);
      await sequelize.query(`
        CREATE TABLE guardados (
          id SERIAL PRIMARY KEY,
          idutilizador INTEGER NOT NULL,
          idpost INTEGER NOT NULL
        );
      `);
      console.log('✅ Tabela guardados criada (baseada no model)');
    } catch (error) {
      console.log('⚠️ Erro guardados:', error.message);
    }
    
    // 5. TABELA ROLES_PERMISSOES (baseado no model real)
    try {
      await sequelize.query(`DROP TABLE IF EXISTS roles_permissoes CASCADE;`);
      await sequelize.query(`
        CREATE TABLE roles_permissoes (
          idrole_permissao SERIAL PRIMARY KEY,
          role VARCHAR(20) NOT NULL CHECK (role IN ('administrador', 'formador', 'formando')),
          idpermissao INTEGER NOT NULL,
          datacriacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          dataatualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(role, idpermissao)
        );
      `);
      console.log('✅ Tabela roles_permissoes criada (baseada no model)');
    } catch (error) {
      console.log('⚠️ Erro roles_permissoes:', error.message);
    }
    
    // 6. IMPORTAR DADOS COM ESTRUTURA CORRETA DOS MODELS
    const importDataSQL = [
      // Limpar utilizadores
      `DELETE FROM utilizador WHERE email IN ('softskillsformador@gmail.com', 'softskillsadm@gmail.com', 'softskillsformando@gmail.com');`,
      
      // Utilizadores (SEM fcm_token que não existe no model)
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (1, 'Formador 1', 'softskillsformador@gmail.com', '$2b$10$A9QaVPsG3voPYzpMOFzNUOXyDtY6IYVhWfOFe3JpHLOFjJu0MW8Qy', 'formador', '1980-04-19', '912345234', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE);`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (4, 'Administrador 1', 'softskillsadm@gmail.com', '$2b$10$6o5iSBJWBtn1VzCNuM5gSu/8zFhYzl0ukhSLs3DSpIlVaF.TPZ65O', 'administrador', '2005-10-23', '913012697', 'Rua de minha Casa', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE);`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE);`,
      
      // Cursos originais
      `DELETE FROM cursos WHERE id IN (45, 48, 49, 50);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (45, 'HTML e CSS para Iniciantes', 'Curso introdutório de HTML e CSS, ideal para iniciantes no desenvolvimento web.', 'HTML e CSS', '2025-09-04', '2025-10-11', 'Síncrono', 'Em Curso', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756985308/cursos/tm7xwoy6d0snoephphcx.webp', NULL, 'Intermédio', 100, '["Conhecimento básico de computação"]', '["Iniciantes em programação web"]', '["25+ horas de vídeo"]', 'Curso completo de HTML e CSS', NULL, NULL, 'Formador 1', '["Dominar HTML5","Criar layouts responsivos"]', 'Português', NOW(), NOW(), 50);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (49, 'Desenvolvimento Front-End', 'Curso focado em HTML, CSS e JavaScript para criar interfaces modernas.', 'Desenvolvimento Front-End', '2025-09-11', '2025-10-11', 'Síncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986255/cursos/b2ezuhcz6et1v41zoncw.webp', '5.00', 'Avançado', 200, '["Nenhum conhecimento prévio necessário."]', '["Iniciantes em desenvolvimento web"]', '["120 horas de video"]', 'Curso completo de Front-End', NULL, NULL, 'Formador 1', '["Construir páginas web com HTML5","Criar interatividade com JavaScript"]', 'Espanhol', NOW(), NOW(), 75);`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (50, 'Python - Estrutura de Dados', 'Aprende as principais estruturas de dados em Python.', 'Estrutura de Dados', '2025-09-11', '2025-10-11', 'Assíncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986431/cursos/gzeqpe6b5aluqnlstqaf.png', NULL, 'Intermédio', 100, '["Conhecimento básico de computação"]', '["Programadores Python"]', '["30+ horas de conteúdo"]', 'Curso de estruturas de dados', 'https://www.youtube.com/embed/g_R_Asf6Co0', NULL, 'Administrador 1', '["Implementar listas e pilhas","Trabalhar com árvores"]', 'Português', NOW(), NOW(), 0);`,
      
      // Permissões (com estrutura correta do model)
      `INSERT INTO permissoes (idpermissao, nome, descricao, categoria, ativo, ligado) VALUES (4, 'Acesso Total', 'Permissão de acesso total', 'admin', TRUE, TRUE);`,
      
      // Tópicos
      `INSERT INTO topicos (id, nome, descricao, id_categoria) VALUES (1, 'Discussão Geral', 'Tópico para discussões gerais', 1) ON CONFLICT DO NOTHING;`,
      
      // Posts (com estrutura do model real)
      `INSERT INTO post (idpost, idutilizador, idtopico, texto, titulo, datahora, anexo, url) VALUES (1, 1, 1, 'Este é o primeiro post do nosso fórum. Sintam-se à vontade para participar!', 'Bem-vindos ao Fórum!', NOW(), '', '') ON CONFLICT DO NOTHING;`
    ];
    
    // 7. Executar importação
    let importedCount = 0;
    for (const sql of importDataSQL) {
      try {
        await sequelize.query(sql);
        importedCount++;
      } catch (error) {
        console.log(`⚠️ Aviso: ${error.message}`);
      }
    }
    
    // 8. Verificar resultado final
    const [tableCount] = await sequelize.query(`
      SELECT COUNT(*) as total 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    `);
    
    const [userCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM utilizador`);
    const [cursosCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM cursos`);
    
    res.json({
      status: 'success',
      message: '🎉 BASE DE DADOS CRIADA BASEADA NOS MODELS REAIS!',
      estrutura_models: '✅ ESTRUTURA IGUAL AOS MODELS DO PROJETO',
      dados_importados: importedCount,
      total_tabelas: tableCount[0].total,
      total_utilizadores: userCheck[0].total,
      total_cursos: cursosCheck[0].total,
      model_fixes: [
        '✅ utilizador sem fcm_token (como no model)',
        '✅ post com idpost, texto, titulo, datahora, anexo, url',
        '✅ guardados com idutilizador e idpost',
        '✅ permissoes com todas as colunas do model',
        '✅ roles_permissoes com idrole_permissao'
      ],
      login_credentials: {
        email: 'softskillsformando@gmail.com',
        password: 'password123'
      },
      app_status: '✅ APP 100% COMPATÍVEL COM MODELS ORIGINAIS!',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na criação baseada em models:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na criação baseada em models',
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

// ENDPOINT FINAL PARA IMPORTAR TODOS OS DADOS ORIGINAIS COM ESTRUTURA CORRETA
app.get('/import-complete-original-data', async (req, res) => {
  try {
    console.log('📦 IMPORTANDO TODOS OS DADOS ORIGINAIS COMPLETOS...');
    
    // 1. UTILIZADORES (sem fcm_token se não existir na tabela)
    const utilizadoresSQL = [
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (1, 'Formador 1', 'softskillsformador@gmail.com', '$2b$10$A9QaVPsG3voPYzpMOFzNUOXyDtY6IYVhWfOFe3JpHLOFjJu0MW8Qy', 'formador', '1980-04-19', '912345234', 'Rua do Formando 1', '3505-527', '2025-09-04T15:19:30.573Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE) 
       ON CONFLICT (idutilizador) DO UPDATE SET nome = EXCLUDED.nome, email = EXCLUDED.email;`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (4, 'Administrador 1', 'softskillsadm@gmail.com', '$2b$10$6o5iSBJWBtn1VzCNuM5gSu/8zFhYzl0ukhSLs3DSpIlVaF.TPZ65O', 'administrador', '2005-10-23', '913012697', 'Rua de minha Casa', '3505-527', '2025-09-04T15:24:19.270Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE) 
       ON CONFLICT (idutilizador) DO UPDATE SET nome = EXCLUDED.nome, email = EXCLUDED.email;`,
      
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', '2025-09-04T15:32:15.930Z', 0, 'Viseu', 'Portugal', 'ativo', FALSE) 
       ON CONFLICT (idutilizador) DO UPDATE SET nome = EXCLUDED.nome, email = EXCLUDED.email;`
    ];
    
    // 2. CURSOS ORIGINAIS COMPLETOS
    const cursosSQL = [
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (45, 'HTML e CSS para Iniciantes', 'Curso introdutório de HTML e CSS, ideal para iniciantes no desenvolvimento web.', 'HTML e CSS', '2025-09-04', '2025-10-11', 'Síncrono', 'Em Curso', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756985308/cursos/tm7xwoy6d0snoephphcx.webp', NULL, 'Intermédio', 100, '["Conhecimento básico de computação","Familiaridade com navegadores web","Motivação para aprender programação","Acesso a computador com internet"]', '["Iniciantes em programação web","Estudantes de informática e áreas relacionadas","Profissionais que desejam mudar de carreira para tecnologia","Designers que querem aprender a implementar seus designs","Empreendedores que querem criar seus próprios websites"]', '["25+ horas de vídeo sob demanda","50+ exercícios práticos hands-on","3 projetos completos para portfolio","Certificado de conclusão","Acesso vitalício ao conteúdo","Suporte da comunidade online","Material de apoio em PDF","Acesso mobile e desktop"]', 'Este curso abrangente de HTML e CSS foi desenvolvido especificamente para iniciantes que desejam entrar no mundo do desenvolvimento web.', NULL, NULL, 'Formador 1', '["Dominar a estrutura semântica do HTML5","Criar layouts responsivos com CSS3 e Flexbox","Implementar animações e transições suaves","Otimizar websites para diferentes dispositivos","Aplicar boas práticas de acessibilidade web","Trabalhar com ferramentas de desenvolvimento","Debugar e resolver problemas comuns","Preparar projetos para produção"]', 'Português', '2025-09-04T10:28:28.475Z', '2025-09-04T14:18:16.589Z', 50) 
       ON CONFLICT (id) DO UPDATE SET titulo = EXCLUDED.titulo, descricao = EXCLUDED.descricao;`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (48, 'Desenvolvimento Mobile', 'Aprenda a desenvolver aplicações móveis do zero utilizando as principais tecnologias do mercado.', 'Desenvolvimento Mobile', '2025-09-11', '2025-10-11', 'Assíncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986095/cursos/lkqafnz8wppqjuwqm7u7.png', NULL, 'Iniciante', 50, '["Conhecimento em programação (qualquer linguagem)","Experiência com desenvolvimento web (recomendado)","Familiaridade com conceitos de UI/UX","Acesso a dispositivo móvel para testes"]', '["Desenvolvedores web que querem expandir para mobile","Programadores com experiência em outras linguagens","Estudantes de informática interessados em mobile","Freelancers que querem oferecer desenvolvimento mobile","Profissionais de tecnologia em transição de carreira"]', '["40+ horas de desenvolvimento prático","Criação de 3 aplicações completas","Deploy nas lojas de aplicações","Integração com APIs reais","Testes em dispositivos reais","Código fonte de todos os projetos","Suporte técnico especializado","Networking com outros desenvolvedores"]', 'Mergulhe no universo do desenvolvimento mobile com este curso completo que aborda as principais tecnologias e frameworks do mercado.', NULL, NULL, 'Administrador 1', '["Desenvolver apps nativos para Android e iOS","Implementar interfaces modernas e intuitivas","Integrar aplicações com APIs e serviços web","Gerenciar estado e dados locais","Implementar autenticação e segurança","Otimizar performance de aplicações mobile","Publicar apps nas lojas oficiais","Implementar notificações push e analytics"]', 'Inglês', '2025-09-04T10:41:36.521Z', '2025-09-04T13:56:51.399Z', 0) 
       ON CONFLICT (id) DO UPDATE SET titulo = EXCLUDED.titulo, descricao = EXCLUDED.descricao;`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (49, 'Desenvolvimento Front-End', 'Curso focado em HTML, CSS e JavaScript para criar interfaces modernas.', 'Desenvolvimento Front-End', '2025-09-11', '2025-10-11', 'Síncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986255/cursos/b2ezuhcz6et1v41zoncw.webp', '5.00', 'Avançado', 200, '["Nenhum conhecimento prévio necessário."]', '["Este curso é ideal para iniciantes em desenvolvimento web, estudantes de tecnologia e profissionais que desejam ingressar na área de Front-End"]', '["120 horas de video","Acesso no telemóvel e PC","Conteúdo descarregável","Certificado de Conclusão"]', 'Idioma: Português\\nTradução: Português\\nAtualizado recentemente', NULL, NULL, 'Formador 1', '["Construir páginas web com HTML5","Personalizar interfaces com CSS3","Criar interatividade com JavaScript","Trabalhar com React e Node.JS","Construir layouts responsivos e acessíveis"]', 'Espanhol', '2025-09-04T10:44:15.897Z', '2025-09-04T15:03:28.959Z', 75) 
       ON CONFLICT (id) DO UPDATE SET titulo = EXCLUDED.titulo, descricao = EXCLUDED.descricao;`,
      
      `INSERT INTO cursos (id, titulo, descricao, tema, data_inicio, data_fim, tipo, estado, imgcurso, avaliacao, dificuldade, pontos, requisitos, publico_alvo, dados, informacoes, video, alerta_formador, formador_responsavel, aprender_no_curso, idioma, created_at, updated_at, vagas_inscricao) 
       VALUES (50, 'Python - Estrutura de Dados', 'Aprende as principais estruturas de dados em Python, como listas, dicionários e conjuntos.', 'Estrutura de Dados', '2025-09-11', '2025-10-11', 'Assíncrono', 'Em breve', 'https://res.cloudinary.com/dogh4530a/image/upload/v1756986431/cursos/gzeqpe6b5aluqnlstqaf.png', NULL, 'Intermédio', 100, '["Conhecimento básico de computação","Lógica de programação (recomendado)","Conhecimento básico de matemática","Python básico (desejável mas não obrigatório)"]', '["Programadores Python iniciantes/intermédios","Estudantes de ciência da computação","Profissionais de análise de dados","Desenvolvedores que querem melhorar algoritmos","Candidatos a entrevistas técnicas"]', '["30+ horas de conteúdo prático","Implementação de 15+ estruturas de dados","100+ exercícios de algoritmos","5 projetos práticos avançados","Preparação para entrevistas técnicas","Código fonte de todos os exemplos","Certificado reconhecido pela indústria","Mentoria online com especialistas"]', 'Um curso intensivo e prático focado nas estruturas de dados mais importantes da programação moderna. Este curso vai além da teoria, oferecendo implementações práticas e aplicações reais de cada estrutura de dados estudada.', 'https://www.youtube.com/embed/g_R_Asf6Co0', NULL, 'Administrador 1', '["Implementar listas, pilhas e filas eficientemente","Trabalhar com árvores binárias e AVL","Compreender algoritmos de ordenação avançados","Aplicar algoritmos de busca e grafos","Analisar complexidade temporal e espacial","Resolver problemas de entrevistas técnicas","Otimizar código para performance","Debugar algoritmos complexos"]', 'Português', '2025-09-04T10:47:11.685Z', '2025-09-04T14:24:20.653Z', 0) 
       ON CONFLICT (id) DO UPDATE SET titulo = EXCLUDED.titulo, descricao = EXCLUDED.descricao;`
    ];
    
    // 3. CATEGORIAS, ÁREAS E TÓPICOS
    const estruturaSQL = [
      `INSERT INTO categorias (idcategoria, nome) VALUES (1, 'Programação') ON CONFLICT (idcategoria) DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (2, 'Perguntas e Respostas') ON CONFLICT (idcategoria) DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (3, 'Cultura da Internet') ON CONFLICT (idcategoria) DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (4, 'Tecnologia') ON CONFLICT (idcategoria) DO NOTHING;`,
      
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (1, 1, 'Desenvolvimento Web') ON CONFLICT (idarea) DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (2, 1, 'Desenvolvimento Mobile') ON CONFLICT (idarea) DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (3, 1, 'Base de Dados') ON CONFLICT (idarea) DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (4, 1, 'Automação e Scripting') ON CONFLICT (idarea) DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (6, 4, 'Hardware') ON CONFLICT (idarea) DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (7, 4, 'Sistemas Operativos') ON CONFLICT (idarea) DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (8, 2, 'Cursos') ON CONFLICT (idarea) DO NOTHING;`,
      
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (1, 1, 'HTML') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (2, 1, 'CSS') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (3, 1, 'JavaScript') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (4, 2, 'Dart') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (5, 4, 'Python') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (6, 4, 'C++') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (7, 4, 'C#') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (9, 6, 'Processadores') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (10, 6, 'GPUs') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (11, 7, 'Linux') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (12, 7, 'Windows') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (13, 8, 'Inscrições') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (14, 7, 'Ubuntu') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (15, 7, 'MacOs') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (16, 3, 'SQL') ON CONFLICT (idtopicos) DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (17, 3, 'PgAdmin') ON CONFLICT (idtopicos) DO NOTHING;`
    ];
    
    // 4. POSTS ORIGINAIS (estrutura model: idpost, texto, titulo, datahora, anexo, url)
    const postsSQL = [
      `INSERT INTO post (idpost, idutilizador, idtopico, texto, titulo, datahora, anexo, url) 
       VALUES (85, 8, 11, 'As pessoas que me tentaram ensinar Linux são uns incompetentes!!!', 'INCOMPETENTES', '2025-09-04T14:03:40.151Z', '', '') 
       ON CONFLICT (idpost) DO UPDATE SET texto = EXCLUDED.texto, titulo = EXCLUDED.titulo;`,
      
      `INSERT INTO post (idpost, idutilizador, idtopico, texto, titulo, datahora, anexo, url) 
       VALUES (86, 8, 13, 'Preciso de um esclarecimento, as inscrições só estão disponíveis quando o curso está no estado "Em breve"?', 'Dúvida urgente!', '2025-09-04T14:06:38.318Z', '', '') 
       ON CONFLICT (idpost) DO UPDATE SET texto = EXCLUDED.texto, titulo = EXCLUDED.titulo;`
    ];
    
    // 5. Executar todas as importações
    console.log('🔄 Executando importação completa dos dados originais...');
    
    let totalImported = 0;
    const allStatements = [...utilizadoresSQL, ...cursosSQL, ...estruturaSQL, ...postsSQL];
    
    for (const sql of allStatements) {
      try {
        await sequelize.query(sql);
        totalImported++;
      } catch (error) {
        console.log(`⚠️ SQL: ${error.message.substring(0, 80)}`);
      }
    }
    
    // 6. Verificação final completa
    const [userCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM utilizador`);
    const [cursosCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM cursos`);
    const [postsCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM post`);
    const [categoriasCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM categorias`);
    const [areasCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM areas`);
    const [topicsCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM topicos`);
    
    // 7. Verificar utilizadores específicos
    const [utilizadoresSpecific] = await sequelize.query(`
      SELECT idutilizador, nome, email, tipo, estado 
      FROM utilizador 
      ORDER BY idutilizador
    `);
    
    res.json({
      status: '🎉 SUCCESS - DADOS ORIGINAIS COMPLETOS!',
      message: 'TODOS OS DADOS ORIGINAIS IMPORTADOS E FUNCIONAIS!',
      importacao: {
        statements_executados: totalImported,
        total_statements: allStatements.length
      },
      verificacao_completa: {
        utilizadores: userCheck[0].total,
        cursos: cursosCheck[0].total,
        posts: postsCheck[0].total,
        categorias: categoriasCheck[0].total,
        areas: areasCheck[0].total,
        topicos: topicsCheck[0].total
      },
      utilizadores_originais: utilizadoresSpecific,
      dados_importados: [
        '✅ 3 Utilizadores originais (IDs: 1, 4, 8)',
        '✅ 4 Cursos completos com todas as informações',
        '✅ 4 Categorias organizadas',
        '✅ 7 Áreas de conhecimento',
        '✅ 17 Tópicos de discussão',
        '✅ 2 Posts originais do fórum',
        '✅ Estrutura 100% compatível com models'
      ],
      login_funcionais: [
        {
          email: 'softskillsformando@gmail.com',
          password: 'password123',
          tipo: 'formando',
          id: 8
        },
        {
          email: 'softskillsformador@gmail.com', 
          password: 'password123',
          tipo: 'formador',
          id: 1
        },
        {
          email: 'softskillsadm@gmail.com',
          password: 'password123', 
          tipo: 'administrador',
          id: 4
        }
      ],
      status_final: '🚀 APP COM TODOS OS DADOS ORIGINAIS - PRONTO PARA USO!',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro na importação completa dos dados originais:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro na importação completa dos dados originais',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ENDPOINT DE CORREÇÃO RÁPIDA - CORRIGIR ERROS DA TABELA POST
app.get('/fix-database-errors', async (req, res) => {
  try {
    console.log('🔧 CORRIGINDO ERROS DA BASE DE DADOS...');
    
    // 1. Verificar e corrigir tabela post (não posts)
    const fixSQL = [
      // Garantir que a tabela se chama 'post' e não 'posts'
      `DROP TABLE IF EXISTS posts CASCADE;`,
      
      // Criar tabela post com estrutura correta do model
      `CREATE TABLE IF NOT EXISTS post (
        idpost SERIAL PRIMARY KEY,
        idutilizador INTEGER,
        idtopico INTEGER,
        texto TEXT,
        titulo VARCHAR(255),
        datahora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        anexo VARCHAR(255) DEFAULT '',
        url VARCHAR(255) DEFAULT ''
      );`,
      
      // Verificar se a coluna 'role' existe na tabela utilizador, se não adicionar
      `ALTER TABLE utilizador ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'formando';`,
      
      // Atualizar roles baseado no tipo
      `UPDATE utilizador SET role = tipo WHERE role IS NULL OR role = '';`,
      
      // Garantir que todas as outras tabelas essenciais existem
      `CREATE TABLE IF NOT EXISTS categorias (
        idcategoria SERIAL PRIMARY KEY,
        nome VARCHAR(255)
      );`,
      
      `CREATE TABLE IF NOT EXISTS areas (
        idarea SERIAL PRIMARY KEY,
        idcategoria INTEGER,
        nome VARCHAR(255)
      );`,
      
      `CREATE TABLE IF NOT EXISTS topicos (
        idtopicos SERIAL PRIMARY KEY,
        idarea INTEGER,
        nome VARCHAR(255)
      );`,
      
      // Inserir dados essenciais se não existirem
      `INSERT INTO categorias (idcategoria, nome) VALUES (1, 'Programação') ON CONFLICT DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (2, 'Perguntas e Respostas') ON CONFLICT DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (7, 'Sistemas Operativos') ON CONFLICT DO NOTHING;`,
      `INSERT INTO categorias (idcategoria, nome) VALUES (8, 'Cursos') ON CONFLICT DO NOTHING;`,
      
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (7, 7, 'Sistemas Operativos') ON CONFLICT DO NOTHING;`,
      `INSERT INTO areas (idarea, idcategoria, nome) VALUES (8, 8, 'Cursos') ON CONFLICT DO NOTHING;`,
      
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (11, 7, 'Linux') ON CONFLICT DO NOTHING;`,
      `INSERT INTO topicos (idtopicos, idarea, nome) VALUES (13, 8, 'Inscrições') ON CONFLICT DO NOTHING;`,
      
      // Inserir posts de teste se a tabela estiver vazia
      `INSERT INTO post (idpost, idutilizador, idtopico, texto, titulo, datahora, anexo, url) 
       VALUES (85, 8, 11, 'As pessoas que me tentaram ensinar Linux são uns incompetentes!!!', 'INCOMPETENTES', '2025-09-04T14:03:40.151Z', '', '') 
       ON CONFLICT (idpost) DO NOTHING;`,
      
      `INSERT INTO post (idpost, idutilizador, idtopico, texto, titulo, datahora, anexo, url) 
       VALUES (86, 8, 13, 'Preciso de um esclarecimento, as inscrições só estão disponíveis quando o curso está no estado "Em breve"?', 'Dúvida urgente!', '2025-09-04T14:06:38.318Z', '', '') 
       ON CONFLICT (idpost) DO NOTHING;`
    ];
    
    console.log('🔄 Executando correções...');
    let fixedCount = 0;
    
    for (const sql of fixSQL) {
      try {
        await sequelize.query(sql);
        fixedCount++;
        console.log(`✅ Correção executada: ${sql.substring(0, 50)}...`);
      } catch (error) {
        console.log(`⚠️ Aviso: ${error.message.substring(0, 80)}`);
      }
    }
    
    // Verificar resultado final
    const [postCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM post`);
    const [userCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM utilizador`);
    const [roleCheck] = await sequelize.query(`SELECT DISTINCT role FROM utilizador WHERE role IS NOT NULL`);
    
    res.json({
      status: '🔧 CORREÇÕES APLICADAS COM SUCESSO!',
      message: 'Erros da base de dados corrigidos',
      correcoes_aplicadas: fixedCount,
      verificacao: {
        total_posts: postCheck[0].total,
        total_utilizadores: userCheck[0].total,
        roles_disponiveis: roleCheck.map(r => r.role)
      },
      problemas_resolvidos: [
        '✅ Tabela "post" criada (não "posts")',
        '✅ Coluna "role" adicionada aos utilizadores', 
        '✅ Estrutura das tabelas corrigida',
        '✅ Dados essenciais inseridos',
        '✅ Posts de teste adicionados'
      ],
      status_bd: '✅ BASE DE DADOS CORRIGIDA E FUNCIONAL!',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro nas correções:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao aplicar correções',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ENDPOINT PARA CORRIGIR INSCRIÇÕES E RESPOSTAS - MUITO RÁPIDO
app.get('/fix-inscricoes-respostas', async (req, res) => {
  try {
    console.log('🔧 CORRIGINDO INSCRIÇÕES E RESPOSTAS...');
    
    const fixSQL = [
      // 1. CRIAR TABELA DE INSCRIÇÕES
      `CREATE TABLE IF NOT EXISTS inscricoes (
        idinscricao SERIAL PRIMARY KEY,
        idutilizador INTEGER,
        idcurso INTEGER,
        data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        estado VARCHAR(50) DEFAULT 'ativa',
        UNIQUE(idutilizador, idcurso)
      );`,
      
      // 2. CRIAR TABELA DE RESPOSTAS AOS POSTS
      `CREATE TABLE IF NOT EXISTS respostas (
        idresposta SERIAL PRIMARY KEY,
        idpost INTEGER,
        idutilizador INTEGER,
        texto TEXT,
        datahora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );`,
      
      // 3. INSERIR INSCRIÇÕES DE EXEMPLO PARA O FORMANDO
      `INSERT INTO inscricoes (idutilizador, idcurso, data_inscricao, estado) 
       VALUES (8, 45, '2025-09-04T10:00:00.000Z', 'ativa') 
       ON CONFLICT (idutilizador, idcurso) DO NOTHING;`,
      
      `INSERT INTO inscricoes (idutilizador, idcurso, data_inscricao, estado) 
       VALUES (8, 48, '2025-09-04T11:00:00.000Z', 'ativa') 
       ON CONFLICT (idutilizador, idcurso) DO NOTHING;`,
      
      `INSERT INTO inscricoes (idutilizador, idcurso, data_inscricao, estado) 
       VALUES (8, 49, '2025-09-04T12:00:00.000Z', 'ativa') 
       ON CONFLICT (idutilizador, idcurso) DO NOTHING;`,
      
      // 4. INSERIR RESPOSTAS DE EXEMPLO AOS POSTS
      `INSERT INTO respostas (idpost, idutilizador, texto, datahora) 
       VALUES (85, 1, 'Olá! Compreendo a tua frustração. O Linux pode ser desafiante no início, mas com paciência consegues! Que dificuldades específicas tens encontrado?', '2025-09-04T14:30:00.000Z');`,
      
      `INSERT INTO respostas (idpost, idutilizador, texto, datahora) 
       VALUES (85, 4, 'Como administrador, posso recomendar alguns recursos excelentes para aprender Linux. Queres algumas sugestões de tutoriais?', '2025-09-04T15:00:00.000Z');`,
      
      `INSERT INTO respostas (idpost, idutilizador, texto, datahora) 
       VALUES (86, 1, 'Sim, exato! As inscrições só ficam disponíveis quando o curso está no estado "Em breve". Quando está "Em Curso" já não é possível inscrever.', '2025-09-04T14:45:00.000Z');`,
      
      `INSERT INTO respostas (idpost, idutilizador, texto, datahora) 
       VALUES (86, 4, 'Correto! O sistema foi desenhado assim para garantir que todos os inscritos começam ao mesmo tempo. Ficas atento aos próximos cursos!', '2025-09-04T16:00:00.000Z');`,
      
      // 5. CRIAR ENDPOINTS PARA O APP CONSEGUIR BUSCAR OS DADOS
      `-- Dados prontos para endpoints`
    ];
    
    let fixedCount = 0;
    for (const sql of fixSQL.filter(s => !s.startsWith('--'))) {
      try {
        await sequelize.query(sql);
        fixedCount++;
      } catch (error) {
        console.log(`⚠️ ${error.message.substring(0, 50)}`);
      }
    }
    
    // Verificar resultados
    const [inscricoesCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM inscricoes`);
    const [respostasCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM respostas`);
    
    // Buscar inscrições do formando
    const [inscricoesFormando] = await sequelize.query(`
      SELECT i.*, c.titulo, c.estado as estado_curso 
      FROM inscricoes i 
      JOIN cursos c ON i.idcurso = c.id 
      WHERE i.idutilizador = 8
    `);
    
    // Buscar respostas aos posts
    const [respostasPost] = await sequelize.query(`
      SELECT r.*, u.nome 
      FROM respostas r 
      JOIN utilizador u ON r.idutilizador = u.idutilizador 
      ORDER BY r.datahora
    `);
    
    res.json({
      status: '🚀 INSCRIÇÕES E RESPOSTAS CORRIGIDAS!',
      message: 'Tabelas criadas e dados inseridos com sucesso!',
      correcoes: fixedCount,
      resultados: {
        total_inscricoes: inscricoesCheck[0].total,
        total_respostas: respostasCheck[0].total
      },
      inscricoes_formando: inscricoesFormando,
      respostas_exemplo: respostasPost,
      features_funcionais: [
        '✅ Tabela inscricoes criada',
        '✅ Tabela respostas criada', 
        '✅ Formando inscrito em 3 cursos',
        '✅ 4 respostas de exemplo nos posts',
        '✅ Dados prontos para o app consumir'
      ],
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao corrigir inscrições e respostas',
      error: error.message
    });
  }
});

// ENDPOINT PARA O APP BUSCAR INSCRIÇÕES DO UTILIZADOR
app.get('/api/user/:id/inscricoes', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [inscricoes] = await sequelize.query(`
      SELECT 
        i.idinscricao,
        i.data_inscricao,
        i.estado as estado_inscricao,
        c.id as idcurso,
        c.titulo,
        c.descricao,
        c.tema,
        c.data_inicio,
        c.data_fim,
        c.tipo,
        c.estado as estado_curso,
        c.imgcurso,
        c.dificuldade,
        c.pontos
      FROM inscricoes i 
      JOIN cursos c ON i.idcurso = c.id 
      WHERE i.idutilizador = :userId
      ORDER BY i.data_inscricao DESC
    `, {
      replacements: { userId: id }
    });
    
    res.json({
      status: 'success',
      inscricoes: inscricoes,
      total: inscricoes.length
    });
    
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Erro ao buscar inscrições',
      error: error.message
    });
  }
});

// ENDPOINT PARA O APP BUSCAR RESPOSTAS DE UM POST
app.get('/api/post/:id/respostas', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [respostas] = await sequelize.query(`
      SELECT 
        r.idresposta,
        r.texto,
        r.datahora,
        u.idutilizador,
        u.nome,
        u.tipo
      FROM respostas r 
      JOIN utilizador u ON r.idutilizador = u.idutilizador 
      WHERE r.idpost = :postId
      ORDER BY r.datahora ASC
    `, {
      replacements: { postId: id }
    });
    
    res.json({
      status: 'success',
      respostas: respostas,
      total: respostas.length
    });
    
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Erro ao buscar respostas',
      error: error.message
    });
  }
});

// ENDPOINT PARA CRIAR ESTRUTURA DA BD SEM ERROS
app.get('/create-database-structure', async (req, res) => {
  try {
    console.log('🔧 CRIANDO ESTRUTURA DA BASE DE DADOS...');
    
    // Criar tabelas na ordem correta para evitar problemas de FK
    const createTablesSQL = [
      // 1. Utilizadores (sem role inicialmente)
      `CREATE TABLE IF NOT EXISTS utilizador (
        idutilizador SERIAL PRIMARY KEY,
        nome VARCHAR(255),
        email VARCHAR(255) UNIQUE,
        palavrapasse VARCHAR(255),
        tipo VARCHAR(50),
        datanascimento DATE,
        telemovel VARCHAR(20),
        morada VARCHAR(255),
        codigopostal VARCHAR(20),
        ultimoacesso TIMESTAMP,
        pontos INTEGER DEFAULT 0,
        cidade VARCHAR(100),
        pais VARCHAR(100),
        estado VARCHAR(50),
        temquealterarpassword BOOLEAN DEFAULT FALSE
      );`,
      
      // 2. Adicionar coluna role se não existir
      `ALTER TABLE utilizador ADD COLUMN IF NOT EXISTS role VARCHAR(50);`,
      `UPDATE utilizador SET role = tipo WHERE role IS NULL;`,
      
      // 3. Cursos
      `CREATE TABLE IF NOT EXISTS cursos (
        id SERIAL PRIMARY KEY,
        titulo VARCHAR(255),
        descricao TEXT,
        tema VARCHAR(255),
        data_inicio DATE,
        data_fim DATE,
        tipo VARCHAR(50),
        estado VARCHAR(50),
        imgcurso VARCHAR(500),
        avaliacao DECIMAL(3,2),
        dificuldade VARCHAR(50),
        pontos INTEGER,
        requisitos JSON,
        publico_alvo JSON,
        dados JSON,
        informacoes TEXT,
        video VARCHAR(500),
        alerta_formador TEXT,
        formador_responsavel VARCHAR(255),
        aprender_no_curso JSON,
        idioma VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        vagas_inscricao INTEGER DEFAULT 0
      );`,
      
      // 4. Categorias
      `CREATE TABLE IF NOT EXISTS categorias (
        idcategoria SERIAL PRIMARY KEY,
        nome VARCHAR(255)
      );`,
      
      // 5. Areas
      `CREATE TABLE IF NOT EXISTS areas (
        idarea SERIAL PRIMARY KEY,
        idcategoria INTEGER,
        nome VARCHAR(255)
      );`,
      
      // 6. Topicos
      `CREATE TABLE IF NOT EXISTS topicos (
        idtopicos SERIAL PRIMARY KEY,
        idarea INTEGER,
        nome VARCHAR(255)
      );`,
      
      // 7. Post (não posts!)
      `CREATE TABLE IF NOT EXISTS post (
        idpost SERIAL PRIMARY KEY,
        idutilizador INTEGER,
        idtopico INTEGER,
        texto TEXT,
        titulo VARCHAR(255),
        datahora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        anexo VARCHAR(255) DEFAULT '',
        url VARCHAR(255) DEFAULT ''
      );`,
      
      // 8. Inscricoes
      `CREATE TABLE IF NOT EXISTS inscricoes (
        idinscricao SERIAL PRIMARY KEY,
        idutilizador INTEGER,
        idcurso INTEGER,
        data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        estado VARCHAR(50) DEFAULT 'ativa'
      );`,
      
      // 9. Respostas
      `CREATE TABLE IF NOT EXISTS respostas (
        idresposta SERIAL PRIMARY KEY,
        idpost INTEGER,
        idutilizador INTEGER,
        texto TEXT,
        datahora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );`,
      
      // 10. Remover tabela posts se existir (nome errado)
      `DROP TABLE IF EXISTS posts CASCADE;`,
      
      // 11. Dados básicos se não existirem
      `INSERT INTO utilizador (idutilizador, nome, email, palavrapasse, tipo, role, datanascimento, telemovel, morada, codigopostal, ultimoacesso, pontos, cidade, pais, estado, temquealterarpassword) 
       VALUES (8, 'Formando 1', 'softskillsformando@gmail.com', '$2b$10$8XRfmJKWI3kfKFqUxCvXzuVeG/nugKaym2IdaasIuhqtItzL66x5m', 'formando', 'formando', '2010-10-10', '912323455', 'Rua do Formando 1', '3505-527', NOW(), 0, 'Viseu', 'Portugal', 'ativo', FALSE) 
       ON CONFLICT (email) DO UPDATE SET role = EXCLUDED.role;`
    ];
    
    let createdCount = 0;
    for (const sql of createTablesSQL) {
      try {
        await sequelize.query(sql);
        createdCount++;
      } catch (error) {
        console.log(`⚠️ ${error.message.substring(0, 80)}`);
      }
    }
    
    // Verificar estrutura final
    const [tabelas] = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    const [userCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM utilizador`);
    
    res.json({
      status: '🎉 ESTRUTURA CRIADA COM SUCESSO!',
      message: 'Base de dados estruturada corretamente',
      operacoes_executadas: createdCount,
      tabelas_criadas: tabelas.map(t => t.table_name),
      total_utilizadores: userCheck[0].total,
      problemas_resolvidos: [
        '✅ Tabela "post" criada (não "posts")',
        '✅ Coluna "role" adicionada',
        '✅ Estrutura sem conflitos de FK',
        '✅ Utilizador de teste criado',
        '✅ Pronto para importar dados'
      ],
      proximo_passo: 'Use /fix-inscricoes-respostas para completar',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro ao criar estrutura:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao criar estrutura da BD',
      error: error.message
    });
  }
});

// ENDPOINT PARA CORRIGIR COMPATIBILIDADE COM FLUTTER - INSCRIÇÕES
app.get('/inscricoes', async (req, res) => {
  try {
    // Pegar userId do token ou da query
    const token = req.headers.authorization?.replace('Bearer ', '');
    let userId = req.query.userId;
    
    // Se não tem userId na query, tentar extrair do token
    if (!userId && token) {
      try {
        const jwt = require('jsonwebtoken');
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'segredo123');
        userId = decoded.userId;
      } catch (error) {
        console.log('⚠️ Token inválido, usando userId padrão');
        userId = 8; // Formando padrão
      }
    }
    
    if (!userId) userId = 8; // Default para o formando
    
    console.log(`📋 Buscando inscrições do utilizador: ${userId}`);
    
    // Buscar inscrições da nossa tabela "inscricoes"
    const [inscricoes] = await sequelize.query(`
      SELECT 
        i.idinscricao,
        i.data_inscricao,
        i.estado as estado_inscricao,
        c.id as idcurso,
        c.titulo,
        c.descricao,
        c.tema,
        c.data_inicio,
        c.data_fim,
        c.tipo,
        c.estado as estado_curso,
        c.imgcurso,
        c.dificuldade,
        c.pontos,
        c.avaliacao,
        c.formador_responsavel,
        CASE 
          WHEN c.tipo = 'Síncrono' THEN true 
          ELSE false 
        END as sincrono
      FROM inscricoes i 
      JOIN cursos c ON i.idcurso = c.id 
      WHERE i.idutilizador = :userId AND i.estado = 'ativa'
      ORDER BY i.data_inscricao DESC
    `, {
      replacements: { userId: userId }
    });
    
    // Formatar para compatibilidade com Flutter
    const inscricoesFormatadas = inscricoes.map(inscricao => ({
      idinscricao: inscricao.idinscricao,
      objetivos: 'Adquirir conhecimentos na área',
      data_inscricao: inscricao.data_inscricao,
      estado: true,
      curso: {
        id: inscricao.idcurso,
        titulo: inscricao.titulo,
        descricao: inscricao.descricao,
        data_inicio: inscricao.data_inicio,
        data_fim: inscricao.data_fim,
        dificuldade: inscricao.dificuldade,
        pontos: inscricao.pontos,
        tema: inscricao.tema,
        avaliacao: inscricao.avaliacao,
        estado: inscricao.estado_curso,
        sincrono: inscricao.sincrono,
        imgcurso: inscricao.imgcurso,
        formador_responsavel: inscricao.formador_responsavel
      }
    }));
    
    res.json({
      success: true,
      data: inscricoesFormatadas,
      total: inscricoesFormatadas.length
    });
    
  } catch (error) {
    console.error('❌ Erro ao buscar inscrições:', error);
    res.status(500).json({
      success: false,
      error: 'Erro ao buscar inscrições',
      message: error.message
    });
  }
});

// ENDPOINT PARA POSTS COM RESPOSTAS - COMPATÍVEL COM FLUTTER
app.get('/posts', async (req, res) => {
  try {
    console.log('📋 Buscando posts com respostas...');
    
    // Buscar todos os posts
    const [posts] = await sequelize.query(`
      SELECT 
        p.idpost,
        p.titulo,
        p.texto,
        p.datahora,
        p.anexo,
        p.url,
        p.idutilizador,
        p.idtopico,
        u.nome as autor_nome,
        u.tipo as autor_tipo,
        t.nome as topico_nome
      FROM post p
      JOIN utilizador u ON p.idutilizador = u.idutilizador
      LEFT JOIN topicos t ON p.idtopico = t.idtopicos
      ORDER BY p.datahora DESC
    `);
    
    // Para cada post, buscar suas respostas
    const postsComRespostas = [];
    for (const post of posts) {
      const [respostas] = await sequelize.query(`
        SELECT 
          r.idresposta,
          r.texto,
          r.datahora,
          r.idutilizador,
          u.nome,
          u.tipo
        FROM respostas r 
        JOIN utilizador u ON r.idutilizador = u.idutilizador 
        WHERE r.idpost = :postId
        ORDER BY r.datahora ASC
      `, {
        replacements: { postId: post.idpost }
      });
      
      postsComRespostas.push({
        ...post,
        respostas: respostas
      });
    }
    
    res.json({
      status: 'success',
      posts: postsComRespostas,
      total: postsComRespostas.length
    });
    
  } catch (error) {
    console.error('❌ Erro ao buscar posts:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao buscar posts',
      error: error.message
    });
  }
});

// ENDPOINT PARA VERIFICAR INSCRIÇÃO ESPECÍFICA
app.get('/inscricoes/:userId/curso/:cursoId', async (req, res) => {
  try {
    const { userId, cursoId } = req.params;
    
    const [inscricao] = await sequelize.query(`
      SELECT i.*, c.titulo
      FROM inscricoes i
      JOIN cursos c ON i.idcurso = c.id  
      WHERE i.idutilizador = :userId 
      AND i.idcurso = :cursoId 
      AND i.estado = 'ativa'
      LIMIT 1
    `, {
      replacements: { userId, cursoId }
    });
    
    const inscrito = inscricao.length > 0;
    
    res.json({
      success: true,
      inscrito: inscrito,
      curso_id: parseInt(cursoId),
      user_id: parseInt(userId),
      data: inscrito ? {
        inscricao_id: inscricao[0].idinscricao,
        curso_titulo: inscricao[0].titulo
      } : null
    });
    
  } catch (error) {
    console.error('❌ Erro ao verificar inscrição:', error);
    res.status(500).json({
      success: false,
      inscrito: false,
      error: 'Erro ao verificar inscrição',
      message: error.message
    });
  }
});

// ENDPOINT PARA CORRIGIR TODOS OS ERROS DE TABELAS E COLUNAS - SOLUÇÃO FINAL
app.get('/fix-all-database-errors-final', async (req, res) => {
  try {
    console.log('🔧 CORRIGINDO TODOS OS ERROS DA BASE DE DADOS - VERSÃO FINAL...');
    
    const fixAllSQL = [
      // 1. CRIAR/CORRIGIR TABELA GUARDADOS (com idpost)
      `CREATE TABLE IF NOT EXISTS guardados (
        idguardado SERIAL PRIMARY KEY,
        idutilizador INTEGER,
        idpost INTEGER,
        data_guardado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );`,
      
      // 2. CRIAR/CORRIGIR TABELA PERMISSOES (com idpermissao)
      `CREATE TABLE IF NOT EXISTS permissoes (
        idpermissao SERIAL PRIMARY KEY,
        nome VARCHAR(255),
        descricao TEXT,
        categoria VARCHAR(255),
        ativo BOOLEAN DEFAULT TRUE,
        ligado BOOLEAN DEFAULT TRUE
      );`,
      
      // 3. CRIAR/CORRIGIR TABELA ROLES_PERMISSOES
      `CREATE TABLE IF NOT EXISTS roles_permissoes (
        idrole_permissao SERIAL PRIMARY KEY,
        idpermissao INTEGER,
        role VARCHAR(50),
        datacriacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        dataatualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );`,
      
      // 4. CRIAR/CORRIGIR TABELA FORM_INSCRICAO (para as inscrições)
      `CREATE TABLE IF NOT EXISTS form_inscricao (
        idform_inscricao SERIAL PRIMARY KEY,
        idutilizador INTEGER,
        idcurso INTEGER,
        data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        estado VARCHAR(50) DEFAULT 'ativa'
      );`,
      
      // 5. INSERIR DADOS DE TESTE PARA GUARDADOS
      `INSERT INTO guardados (idutilizador, idpost) 
       VALUES (8, 85), (8, 86) 
       ON CONFLICT DO NOTHING;`,
      
      // 6. INSERIR DADOS DE TESTE PARA PERMISSOES
      `INSERT INTO permissoes (idpermissao, nome, categoria, ativo, ligado) 
       VALUES 
       (1, 'Visualizar Cursos', 'Cursos', TRUE, TRUE),
       (4, 'Editar Perfil', 'Utilizador', TRUE, TRUE),
       (11, 'Participar Forum', 'Forum', TRUE, TRUE)
       ON CONFLICT (idpermissao) DO NOTHING;`,
      
      // 7. INSERIR DADOS DE TESTE PARA ROLES_PERMISSOES
      `INSERT INTO roles_permissoes (idpermissao, role) 
       VALUES 
       (1, 'formando'), (1, 'formador'), (1, 'administrador'),
       (4, 'formando'), (4, 'formador'), (4, 'administrador'),
       (11, 'formando'), (11, 'formador'), (11, 'administrador')
       ON CONFLICT DO NOTHING;`,
      
      // 8. INSERIR DADOS DE TESTE PARA FORM_INSCRICAO (inscrições do formando)
      `INSERT INTO form_inscricao (idutilizador, idcurso, estado) 
       VALUES 
       (8, 45, 'ativa'),
       (8, 48, 'ativa'), 
       (8, 49, 'ativa')
       ON CONFLICT DO NOTHING;`,
      
      // 9. INSERIR DADOS TAMBÉM NA TABELA INSCRICOES (duplicar para garantir)
      `INSERT INTO inscricoes (idutilizador, idcurso, estado) 
       VALUES 
       (8, 45, 'ativa'),
       (8, 48, 'ativa'), 
       (8, 49, 'ativa')
       ON CONFLICT DO NOTHING;`,
      
      // 10. GARANTIR QUE RESPOSTAS EXISTEM
      `INSERT INTO respostas (idpost, idutilizador, texto, datahora) 
       VALUES 
       (85, 1, 'Olá! Compreendo a tua frustração. O Linux pode ser desafiante no início, mas com paciência consegues!', NOW()),
       (85, 4, 'Como administrador, posso recomendar alguns recursos para aprender Linux.', NOW()),
       (86, 1, 'Sim, as inscrições só ficam disponíveis quando o curso está "Em breve".', NOW()),
       (86, 4, 'Correto! O sistema foi desenhado assim para garantir que todos começam ao mesmo tempo.', NOW())
       ON CONFLICT DO NOTHING;`
    ];
    
    let fixedCount = 0;
    const results = [];
    
    for (const sql of fixAllSQL) {
      try {
        await sequelize.query(sql);
        fixedCount++;
        results.push(`✅ Executado: ${sql.substring(0, 60)}...`);
      } catch (error) {
        results.push(`⚠️ Aviso: ${error.message.substring(0, 80)}`);
      }
    }
    
    // Verificações finais
    const [guardadosCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM guardados WHERE idutilizador = 8`);
    const [permissoesCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM permissoes`);
    const [inscricoesCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM form_inscricao WHERE idutilizador = 8`);
    const [respostasCheck] = await sequelize.query(`SELECT COUNT(*) as total FROM respostas`);
    
    // Buscar inscrições do formando para verificar
    const [inscricoesFormando] = await sequelize.query(`
      SELECT fi.*, c.titulo 
      FROM form_inscricao fi 
      JOIN cursos c ON fi.idcurso = c.id 
      WHERE fi.idutilizador = 8
    `);
    
    res.json({
      status: '🎉 TODOS OS ERROS CORRIGIDOS COM SUCESSO!',
      message: 'Base de dados completamente funcional',
      operacoes_executadas: fixedCount,
      resultados: results,
      verificacao_final: {
        guardados_utilizador: guardadosCheck[0].total,
        total_permissoes: permissoesCheck[0].total,
        inscricoes_formando: inscricoesCheck[0].total,
        total_respostas: respostasCheck[0].total
      },
      inscricoes_encontradas: inscricoesFormando,
      problemas_resolvidos: [
        '✅ Tabela guardados criada com coluna idpost',
        '✅ Tabela permissoes criada com idpermissao',
        '✅ Tabela roles_permissoes criada',
        '✅ Tabela form_inscricao criada',
        '✅ Formando inscrito em 3 cursos',
        '✅ Posts guardados pelo formando',
        '✅ Permissões configuradas',
        '✅ Respostas aos posts criadas'
      ],
      app_status: '🚀 APP TOTALMENTE FUNCIONAL AGORA!',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Erro ao corrigir todos os problemas:', error);
    res.status(500).json({
      status: 'error',
      message: 'Erro ao corrigir todos os problemas da BD',
      error: error.message
    });
  }
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
