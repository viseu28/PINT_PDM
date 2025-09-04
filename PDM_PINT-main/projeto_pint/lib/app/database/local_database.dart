import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _database;

  // Versão da BD local. Incrementar quando houver mudanças de schema
  static const int _dbVersion = 6;

  // Getter para obter a base de dados (ou criar se não existir)
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    final String path = join(await getDatabasesPath(), 'softskills.db');

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE cursos (
            id INTEGER PRIMARY KEY,
            titulo TEXT,
            descricao TEXT,
            data_inicio TEXT,
            data_fim TEXT,
            dificuldade TEXT,
            pontos INTEGER,
            tema TEXT,
            categoria TEXT,
            avaliacao REAL,
            inscrito INTEGER,
            imgcurso TEXT,
            progresso INTEGER,
            sincrono INTEGER,
            estado TEXT,
            formador_responsavel TEXT,
            informacoes TEXT,
            video TEXT,
            alerta_formador TEXT,
            aprender_no_curso TEXT,
            requisitos TEXT,
            publico_alvo TEXT,
            dados TEXT,
            duracao TEXT,
            idioma TEXT,
            favorito INTEGER,
            sincronizado INTEGER DEFAULT 0
          );
        ''');
        // Fórum - Tópicos
        await db.execute('''
          CREATE TABLE forum_topicos (
            id INTEGER PRIMARY KEY,
            nome TEXT,
            descricao TEXT,
            estado TEXT,
            autor TEXT,
            datahora TEXT
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_forum_topicos_datahora ON forum_topicos(datahora DESC)');

        // Fórum - Posts (mensagens dentro de um tópico)
        await db.execute('''
          CREATE TABLE forum_posts (
            id INTEGER PRIMARY KEY,
            topico_id INTEGER,
            titulo TEXT,
            conteudo TEXT,
            autor_id INTEGER,
            autor_nome TEXT,
            datahora TEXT,
            url TEXT,
            ficheiro TEXT
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_forum_posts_topico ON forum_posts(topico_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_forum_posts_datahora ON forum_posts(datahora ASC)');

        // Fórum - Likes/Dislikes
        await db.execute('''
          CREATE TABLE forum_likes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idutilizador INTEGER,
            idpost INTEGER,
            tipo TEXT,
            UNIQUE(idutilizador, idpost)
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_forum_likes_user ON forum_likes(idutilizador)');

        // Fórum - Respostas (comentários dos posts)
        await db.execute('''
          CREATE TABLE forum_respostas (
            id INTEGER PRIMARY KEY,
            post_id INTEGER,
            autor_id INTEGER,
            autor_nome TEXT,
            texto TEXT,
            datahora TEXT,
            url TEXT,
            ficheiro TEXT,
            parent_id INTEGER
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_forum_respostas_post ON forum_respostas(post_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_forum_respostas_datahora ON forum_respostas(datahora ASC)');

        // Tabela para cache de notas finais
        await db.execute('''
          CREATE TABLE notas_finais (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idcurso INTEGER,
            idutilizador INTEGER,
            nota REAL,
            data_atualizacao TEXT,
            sincronizado INTEGER DEFAULT 0,
            UNIQUE(idcurso, idutilizador)
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notas_finais_curso_user ON notas_finais(idcurso, idutilizador)');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          final batch = db.batch();
          const cols = <String, String>{
            'categoria': 'TEXT',
            'avaliacao': 'REAL',
            'inscrito': 'INTEGER',
            'imgcurso': 'TEXT',
            'progresso': 'INTEGER',
            'sincrono': 'INTEGER',
            'formador_responsavel': 'TEXT',
            'informacoes': 'TEXT',
            'video': 'TEXT',
            'alerta_formador': 'TEXT',
            'aprender_no_curso': 'TEXT',
            'requisitos': 'TEXT',
            'publico_alvo': 'TEXT',
            'dados': 'TEXT',
            'duracao': 'TEXT',
            'idioma': 'TEXT',
            'favorito': 'INTEGER'
          };
          cols.forEach((name, type) {
            batch.execute('ALTER TABLE cursos ADD COLUMN $name $type');
          });
          await batch.commit(noResult: true);
        }
        if (oldVersion < 3) {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE IF NOT EXISTS forum_topicos (
              id INTEGER PRIMARY KEY,
              nome TEXT,
              descricao TEXT,
              estado TEXT,
              autor TEXT,
              datahora TEXT
            );
          ''');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_forum_topicos_datahora ON forum_topicos(datahora DESC)');

          batch.execute('''
            CREATE TABLE IF NOT EXISTS forum_posts (
              id INTEGER PRIMARY KEY,
              topico_id INTEGER,
              conteudo TEXT,
              autor_id INTEGER,
              autor_nome TEXT,
              datahora TEXT,
              url TEXT,
              ficheiro TEXT
            );
          ''');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_forum_posts_topico ON forum_posts(topico_id)');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_forum_posts_datahora ON forum_posts(datahora ASC)');

          batch.execute('''
            CREATE TABLE IF NOT EXISTS forum_likes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              idutilizador INTEGER,
              idpost INTEGER,
              tipo TEXT,
              UNIQUE(idutilizador, idpost)
            );
          ''');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_forum_likes_user ON forum_likes(idutilizador)');
          await batch.commit(noResult: true);
        }
        if (oldVersion < 4) {
          final batch = db.batch();
          // Adicionar coluna de título aos posts do fórum
          batch.execute('ALTER TABLE forum_posts ADD COLUMN titulo TEXT');
          await batch.commit(noResult: true);
        }
        if (oldVersion < 5) {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE IF NOT EXISTS forum_respostas (
              id INTEGER PRIMARY KEY,
              post_id INTEGER,
              autor_id INTEGER,
              autor_nome TEXT,
              texto TEXT,
              datahora TEXT,
              url TEXT,
              ficheiro TEXT,
              parent_id INTEGER
            );
          ''');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_forum_respostas_post ON forum_respostas(post_id)');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_forum_respostas_datahora ON forum_respostas(datahora ASC)');
          await batch.commit(noResult: true);
        }
        if (oldVersion < 6) {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE IF NOT EXISTS notas_finais (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              idcurso INTEGER,
              idutilizador INTEGER,
              nota REAL,
              data_atualizacao TEXT,
              sincronizado INTEGER DEFAULT 0,
              UNIQUE(idcurso, idutilizador)
            );
          ''');
          batch.execute('CREATE INDEX IF NOT EXISTS idx_notas_finais_curso_user ON notas_finais(idcurso, idutilizador)');
          await batch.commit(noResult: true);
        }
      },
    );

    return _database!;
  }



  /// Inserir curso simples (modo antigo - compatível com ApiService atual)
  static Future<void> inserirCurso(
    String titulo,
    String descricao,
    String dataInicio,
    String dataFim,
    String dificuldade,
    int pontos,
    String tema,
    String estado,
  ) async {
    final db = await getDatabase();
    await db.insert('cursos', {
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'dificuldade': dificuldade,
      'pontos': pontos,
      'tema': tema,
      'estado': estado,
      'sincronizado': 0,
    });
  }

  /// Upsert de um curso (insere ou atualiza com base em id ou título)
  static Future<void> upsertCurso(Map<String, dynamic> data) async {
    final db = await getDatabase();

    final int? id = data['id'] is int ? data['id'] as int : null;
    final String? titulo = data['titulo'] as String?;
    if (titulo == null || titulo.trim().isEmpty) return;

    // Preparar linha para inserir/atualizar
    final Map<String, Object?> row = {
      'titulo': data['titulo'],
      'descricao': data['descricao'],
      'data_inicio': data['data_inicio'],
      'data_fim': data['data_fim'],
      'dificuldade': data['dificuldade'],
      'pontos': data['pontos'],
      'tema': data['tema'],
      'categoria': data['categoria'],
      'avaliacao': data['avaliacao'],
      'inscrito': data['inscrito'],
      'imgcurso': data['imgcurso'],
      'progresso': data['progresso'],
      'sincrono': data['sincrono'],
      'estado': data['estado'],
      'formador_responsavel': data['formador_responsavel'],
      'informacoes': data['informacoes'],
      'video': data['video'],
      'alerta_formador': data['alerta_formador'],
      'aprender_no_curso': data['aprender_no_curso'],
      'requisitos': data['requisitos'],
      'publico_alvo': data['publico_alvo'],
      'dados': data['dados'],
      'duracao': data['duracao'],
      'idioma': data['idioma'],
      'favorito': data['favorito'],
      'sincronizado': data['sincronizado'] ?? 1,
    };
    row.removeWhere((k, v) => v == null);

    // Verificar existência por id ou por título
    Map<String, dynamic>? existing;
    if (id != null) {
      final rows = await db.query('cursos', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) existing = rows.first;
    }
    if (existing == null) {
      final rows = await db.query('cursos', where: 'titulo = ?', whereArgs: [titulo], limit: 1);
      if (rows.isNotEmpty) existing = rows.first;
    }

    if (existing == null) {
      if (id != null) row['id'] = id;
      await db.insert('cursos', row);
    } else {
      await db.update('cursos', row, where: 'id = ?', whereArgs: [existing['id']]);
    }
  }

  /// Obter todos os cursos
  static Future<List<Map<String, dynamic>>> obterCursos() async {
    final db = await getDatabase();
    return db.query('cursos', orderBy: 'titulo COLLATE NOCASE ASC');
  }

  /// Obter curso por id
  static Future<Map<String, dynamic>?> obterCursoPorId(int id) async {
    final db = await getDatabase();
    final rows = await db.query('cursos', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Verificar existência por título
  static Future<bool> existeCursoPorTitulo(String titulo) async {
    final db = await getDatabase();
    final resultado = await db.query(
      'cursos',
      where: 'titulo = ?',
      whereArgs: [titulo],
      limit: 1,
    );
    return resultado.isNotEmpty;
  }

  /// Marcar curso como sincronizado
  static Future<void> marcarCursoComoSincronizado(int id) async {
    final db = await getDatabase();
    await db.update(
      'cursos',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obter cursos não sincronizados
  static Future<List<Map<String, dynamic>>> obterCursosNaoSincronizados() async {
    final db = await getDatabase();
    return db.query('cursos', where: 'sincronizado = ?', whereArgs: [0]);
  }

  /// Atualizar flag de inscrição de um curso
  static Future<int> atualizarInscrito(int id, bool inscrito) async {
    final db = await getDatabase();
    return db.update(
      'cursos',
      {'inscrito': inscrito ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obter cursos marcados como inscritos localmente
  static Future<List<Map<String, dynamic>>> obterCursosInscritosLocais() async {
    final db = await getDatabase();
    return db.query('cursos', where: 'inscrito = 1', orderBy: 'titulo COLLATE NOCASE ASC');
  }

  /// Atualizar favorito
  static Future<int> atualizarFavorito(int id, bool favorito) async {
    final db = await getDatabase();
    return db.update(
      'cursos',
      {'favorito': favorito ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obter apenas favoritos locais
  static Future<List<Map<String, dynamic>>> obterFavoritosLocais() async {
    final db = await getDatabase();
    return db.query('cursos', where: 'favorito = 1');
  }

  // ------------------------
  // Fórum - Métodos mínimos
  // ------------------------

  /// Upsert de tópicos do fórum
  static Future<void> upsertTopicosForum(List<Map<String, dynamic>> topicos) async {
    if (topicos.isEmpty) return;
    final db = await getDatabase();
    final batch = db.batch();
    for (final t in topicos) {
      if (t['id'] == null) continue;
      final row = <String, Object?>{
        'id': t['id'],
        'nome': t['nome'] ?? t['titulo'],
        'descricao': t['descricao'],
        'estado': t['estado'],
        'autor': t['autor'] ?? t['autor_nome'],
        'datahora': t['datahora']
      }..removeWhere((k, v) => v == null);
      batch.insert('forum_topicos', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Listar tópicos localmente (ordenados por data desc)
  static Future<List<Map<String, dynamic>>> listarTopicosForum() async {
    final db = await getDatabase();
    return db.query('forum_topicos', orderBy: 'datetime(datahora) DESC');
  }

  /// Upsert de posts do fórum
  static Future<void> upsertPostsForum(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return;
    final db = await getDatabase();
    final batch = db.batch();
    for (final p in posts) {
      final dynamic pid = p['id'] ?? p['idpost'];
      if (pid == null) continue;
      final row = <String, Object?>{
        'id': pid,
        'topico_id': p['topico_id'] ?? p['idtopico'],
        'titulo': p['titulo'],
        'conteudo': p['conteudo'] ?? p['descricao'] ?? p['mensagem'] ?? p['texto'],
        'autor_id': p['autor_id'] ?? p['idutilizador'],
        'autor_nome': p['autor_nome'] ?? p['autor'],
        'datahora': p['datahora'],
        'url': p['url'],
        'ficheiro': p['ficheiro']
      }..removeWhere((k, v) => v == null);
      batch.insert('forum_posts', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Listar posts de um tópico
  static Future<List<Map<String, dynamic>>> listarPostsPorTopico(int topicoId) async {
    final db = await getDatabase();
    return db.query(
      'forum_posts',
      where: 'topico_id = ?',
      whereArgs: [topicoId],
      orderBy: 'datetime(datahora) ASC',
    );
  }

  /// Listar todos os posts (ordenados por data asc)
  static Future<List<Map<String, dynamic>>> listarTodosPostsForum() async {
    final db = await getDatabase();
    return db.query('forum_posts', orderBy: 'datetime(datahora) ASC');
  }

  /// Registar/atualizar like/dislike localmente
  static Future<void> salvarLikeForum(int userId, int postId, String tipo) async {
    final db = await getDatabase();
    await db.insert(
      'forum_likes',
      {
        'idutilizador': userId,
        'idpost': postId,
        'tipo': tipo,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remover like/dislike local
  static Future<int> removerLikeForum(int userId, int postId) async {
    final db = await getDatabase();
    return db.delete(
      'forum_likes',
      where: 'idutilizador = ? AND idpost = ?',
      whereArgs: [userId, postId],
    );
  }

  /// Obter likes do utilizador
  static Future<List<Map<String, dynamic>>> obterLikesDoUtilizador(int userId) async {
    final db = await getDatabase();
    return db.query('forum_likes', where: 'idutilizador = ?', whereArgs: [userId]);
  }

  // ------------------------
  // Fórum - Respostas
  // ------------------------

  /// Upsert de respostas do fórum
  static Future<void> upsertRespostasForum(List<Map<String, dynamic>> respostas) async {
    print('[LocalDatabase] upsertRespostasForum: ${respostas.length} respostas');
    if (respostas.isEmpty) return;
    final db = await getDatabase();
    final batch = db.batch();
    for (final r in respostas) {
      print('[LocalDatabase] Processando resposta: $r');
      final dynamic rid = r['id'] ?? r['idresposta'];
      if (rid == null) {
        print('[LocalDatabase] Resposta sem ID, ignorando: $r');
        continue;
      }
      // Garantir que o post_id não é null
      final postId = r['idpost'] ?? r['post_id'];
      if (postId == null) {
        print('[LocalDatabase] ERRO: post_id é null para resposta $rid');
        print('[LocalDatabase] Dados da resposta: $r');
        continue;
      }
      
      final row = <String, Object?>{
        'id': rid,
        'post_id': postId,
        'autor_id': r['idutilizador'] ?? r['autor_id'],
        'autor_nome': r['autor'] ?? r['autor_nome'],
        'texto': r['texto'] ?? r['conteudo'],
        'datahora': r['datahora'],
        'url': r['url'],
        'ficheiro': r['ficheiro'],
        'parent_id': r['idrespostapai'] ?? r['parent_id'],
      };
      print('[LocalDatabase] post_id guardado: ${row['post_id']}');
      // Não remover post_id mesmo se for null, para debug
      row.removeWhere((k, v) => v == null && k != 'post_id');
      print('[LocalDatabase] Row para inserir: $row');
      batch.insert('forum_respostas', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    print('[LocalDatabase] Respostas inseridas com sucesso');
  }

  /// Listar respostas por post
  static Future<List<Map<String, dynamic>>> listarRespostasPorPost(int postId) async {
    print('[LocalDatabase] listarRespostasPorPost: postId=$postId');
    final db = await getDatabase();
    
    // Verificar todas as respostas na base de dados
    final todasRespostas = await db.query('forum_respostas');
    print('[LocalDatabase] Total de respostas na BD: ${todasRespostas.length}');
    for (final resp in todasRespostas) {
      print('[LocalDatabase] Resposta na BD: id=${resp['id']}, post_id=${resp['post_id']}, texto=${resp['texto']}');
    }
    
    final result = await db.query(
      'forum_respostas',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'datetime(datahora) ASC',
    );
    print('[LocalDatabase] listarRespostasPorPost retornou: ${result.length} respostas');
    for (final row in result) {
      print('[LocalDatabase] Resposta local: $row');
    }
    return result;
  }

  // ------------------------
  // Notas Finais
  // ------------------------

  /// Inserir ou atualizar nota final
  static Future<void> upsertNotaFinal(int idcurso, int idutilizador, double nota) async {
    final db = await getDatabase();
    await db.insert(
      'notas_finais',
      {
        'idcurso': idcurso,
        'idutilizador': idutilizador,
        'nota': nota,
        'data_atualizacao': DateTime.now().toIso8601String(),
        'sincronizado': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obter nota final local
  static Future<double?> obterNotaFinalLocal(int idcurso, int idutilizador) async {
    final db = await getDatabase();
    final rows = await db.query(
      'notas_finais',
      where: 'idcurso = ? AND idutilizador = ?',
      whereArgs: [idcurso, idutilizador],
      limit: 1,
    );
    return rows.isNotEmpty ? (rows.first['nota'] as num?)?.toDouble() : null;
  }

  /// Obter todas as notas finais de um utilizador
  static Future<List<Map<String, dynamic>>> obterNotasFinaisDoUtilizador(int idutilizador) async {
    final db = await getDatabase();
    return db.query(
      'notas_finais',
      where: 'idutilizador = ?',
      whereArgs: [idutilizador],
      orderBy: 'data_atualizacao DESC',
    );
  }

  /// Marcar nota como sincronizada
  static Future<void> marcarNotaComoSincronizada(int idcurso, int idutilizador) async {
    final db = await getDatabase();
    await db.update(
      'notas_finais',
      {'sincronizado': 1},
      where: 'idcurso = ? AND idutilizador = ?',
      whereArgs: [idcurso, idutilizador],
    );
  }

  /// Obter notas não sincronizadas
  static Future<List<Map<String, dynamic>>> obterNotasNaoSincronizadas() async {
    final db = await getDatabase();
    return db.query('notas_finais', where: 'sincronizado = ?', whereArgs: [0]);
  }

}