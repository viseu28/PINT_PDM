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
