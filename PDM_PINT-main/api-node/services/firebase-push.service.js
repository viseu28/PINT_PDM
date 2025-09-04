const admin = require('firebase-admin');

// Configuração do Firebase Admin
// NOTA: Você precisará baixar o service account key do Firebase Console
// e colocar o arquivo no diretório config/
let firebaseInitialized = false;

function initializeFirebase() {
  if (firebaseInitialized) return;
  
  try {
    // Carregar service account key do arquivo
    const serviceAccount = require('../config/firebase-service-account.json');
    
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    
    firebaseInitialized = true;
    console.log('🔥 Firebase Admin SDK inicializado com credenciais reais');
  } catch (error) {
    console.log('⚠️ Erro ao inicializar Firebase Admin SDK:', error.message);
    console.log('📝 Tentando modo de fallback...');
    
    // Fallback para applicationDefault se o arquivo não existir
    try {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
      }
      firebaseInitialized = true;
      console.log('🔥 Firebase Admin SDK inicializado em modo fallback');
    } catch (fallbackError) {
      console.log('❌ Firebase não conseguiu inicializar:', fallbackError.message);
    }
  }
}

class FirebasePushService {
  constructor(db) {
    this.db = db;
    initializeFirebase();
  }

  // Enviar notificação para um utilizador específico
  async enviarNotificacaoParaUtilizador(idUtilizador, titulo, corpo, dados = {}) {
    try {
      // Buscar o token FCM do utilizador na base de dados
      const utilizador = await this.db.utilizador.findByPk(idUtilizador);
      
      if (!utilizador || !utilizador.fcm_token) {
        console.log(`⚠️ Token FCM não encontrado para o utilizador ${idUtilizador}`);
        return false;
      }

      const message = {
        token: utilizador.fcm_token,
        notification: {
          title: titulo,
          body: corpo,
        },
        data: {
          // Converter todos os valores para string (Firebase requirement)
          ...Object.fromEntries(
            Object.entries(dados).map(([key, value]) => [key, String(value)])
          ),
          timestamp: new Date().toISOString(),
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#2196F3',
            channelId: 'firebase_messaging_channel',
          },
        },
      };

      if (admin.apps.length > 0) {
        try {
          const response = await admin.messaging().send(message);
          console.log('✅ Notificação enviada com sucesso:', response);
          return true;
        } catch (error) {
          if (error.message.includes('Project Id')) {
            console.log('🔧 Simulação: Firebase não configurado, mas notificação seria enviada');
            console.log(`📱 Para: ${utilizador.nome} (${utilizador.email})`);
            console.log(`📢 Título: ${titulo}`);
            console.log(`📝 Corpo: ${corpo}`);
            console.log(`📊 Dados:`, dados);
            return true;
          }
          throw error;
        }
      } else {
        console.log('📝 Simulação: Notificação seria enviada para', utilizador.nome, ':', titulo);
        return true;
      }
    } catch (error) {
      console.error('❌ Erro ao enviar notificação:', error);
      return false;
    }
  }

  // Enviar notificação para múltiplos utilizadores
  async enviarNotificacaoParaVarios(idUtilizadores, titulo, corpo, dados = {}) {
    const resultados = [];
    
    for (const idUtilizador of idUtilizadores) {
      const resultado = await this.enviarNotificacaoParaUtilizador(idUtilizador, titulo, corpo, dados);
      resultados.push({ idUtilizador, sucesso: resultado });
    }
    
    return resultados;
  }

  // Enviar notificação para todos os utilizadores inscritos num curso
  async enviarNotificacaoParaCurso(idCurso, titulo, corpo, dados = {}) {
    try {
      // Buscar todos os utilizadores inscritos no curso
      const inscricoes = await this.db.sequelize.query(`
        SELECT DISTINCT i.idutilizador 
        FROM form_inscricao i 
        WHERE i.idcurso = :idCurso 
        AND i.estado = true
      `, {
        replacements: { idCurso },
        type: this.db.sequelize.QueryTypes.SELECT
      });

      const idUtilizadores = inscricoes.map(i => i.idutilizador);
      
      if (idUtilizadores.length === 0) {
        console.log(`⚠️ Nenhum utilizador inscrito no curso ${idCurso}`);
        return [];
      }

      console.log(`📢 Enviando notificação para ${idUtilizadores.length} utilizadores do curso ${idCurso}`);
      
      return await this.enviarNotificacaoParaVarios(idUtilizadores, titulo, corpo, {
        ...dados,
        tipo: 'curso',
        idCurso: idCurso.toString()
      });
    } catch (error) {
      console.error('❌ Erro ao enviar notificação para curso:', error);
      return [];
    }
  }

  // Eventos específicos de notificação

  // 1. Novo material/vídeo publicado num curso (apenas inscritos)
  async notificarNovoMaterial(idCurso, tipoMaterial, tituloMaterial) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = `📚 Novo ${tipoMaterial} disponível!`;
    const corpo = `"${tituloMaterial}" foi adicionado ao curso "${curso.titulo}"`;
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'novo_material',
      idCurso: idCurso.toString(),
      tipoMaterial,
      tituloMaterial
    });
  }

  // 2. Alteração de formador (apenas inscritos)
  async notificarAlteracaoFormador(idCurso, nomeNovoFormador, nomeAntigoFormador = null) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) {
      console.log(`❌ Curso ${idCurso} não encontrado!`);
      return false;
    }

    const titulo = '👨‍🏫 Alteração de formador';
    const corpo = nomeAntigoFormador 
      ? `O formador do curso "${curso.titulo}" foi alterado de ${nomeAntigoFormador} para ${nomeNovoFormador}`
      : `${nomeNovoFormador} é agora o formador do curso "${curso.titulo}"`;
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'alteracao_formador',
      idCurso: idCurso.toString(),
      nomeNovoFormador,
      nomeAntigoFormador
    });
  }

  // 3. Alteração de datas do curso (apenas inscritos)
  async notificarAlteracaoDatas(idCurso, novaDataInicio, novaDataFim, dataInicioAntiga = null, dataFimAntiga = null) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '📅 Alteração de datas do curso';
    let corpo = `As datas do curso "${curso.titulo}" foram atualizadas.`;
    
    if (novaDataInicio && novaDataFim) {
      const inicio = new Date(novaDataInicio).toLocaleDateString('pt-PT');
      const fim = new Date(novaDataFim).toLocaleDateString('pt-PT');
      corpo = `O curso "${curso.titulo}" decorrerá de ${inicio} a ${fim}`;
    }
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'alteracao_datas',
      idCurso: idCurso.toString(),
      novaDataInicio,
      novaDataFim
    });
  }

  // 4. Alteração de estado do curso (apenas inscritos)
  async notificarAlteracaoEstado(idCurso, novoEstado, estadoAnterior = null) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    let titulo = '📢 Atualização do curso';
    let corpo = '';

    switch (novoEstado) {
      case 'ativo':
      case true:
        titulo = '✅ Curso ativado';
        corpo = `O curso "${curso.titulo}" foi ativado e está disponível`;
        break;
      case 'inativo':
      case false:
        titulo = '⏸️ Curso suspenso';
        corpo = `O curso "${curso.titulo}" foi temporariamente suspenso`;
        break;
      case 'cancelado':
        titulo = '❌ Curso cancelado';
        corpo = `O curso "${curso.titulo}" foi cancelado`;
        break;
      case 'concluido':
        titulo = '🎓 Curso concluído';
        corpo = `O curso "${curso.titulo}" foi concluído com sucesso`;
        break;
      default:
        corpo = `O estado do curso "${curso.titulo}" foi atualizado`;
    }
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'alteracao_estado',
      idCurso: idCurso.toString(),
      novoEstado,
      estadoAnterior
    });
  }

  // 5. Alteração de informações gerais do curso (apenas inscritos)
  async notificarAlteracaoInformacoes(idCurso, tipoAlteracao, detalhes = '') {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '📝 Curso atualizado';
    let corpo = `O curso "${curso.titulo}" foi atualizado`;
    
    switch (tipoAlteracao) {
      case 'descricao':
        corpo = `A descrição do curso "${curso.titulo}" foi atualizada`;
        break;
      case 'dificuldade':
        corpo = `O nível de dificuldade do curso "${curso.titulo}" foi alterado`;
        break;
      case 'pontos':
        corpo = `A pontuação do curso "${curso.titulo}" foi atualizada`;
        break;
      case 'tema':
        corpo = `A categoria do curso "${curso.titulo}" foi alterada`;
        break;
      default:
        if (detalhes) {
          corpo += `: ${detalhes}`;
        }
    }
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'alteracao_informacoes',
      idCurso: idCurso.toString(),
      tipoAlteracao,
      detalhes
    });
  }

  // 1.2. Nova aula adicionada ao curso (apenas inscritos)
  async notificarNovaAula(idCurso, tituloAula, dataAula = null) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '🎓 Nova aula disponível';
    let corpo = `Nova aula "${tituloAula}" foi adicionada ao curso "${curso.titulo}"`;
    
    if (dataAula) {
      const data = new Date(dataAula).toLocaleDateString('pt-PT', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
      corpo += ` - Agendada para ${data}`;
    }
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'nova_aula',
      idCurso: idCurso.toString(),
      tituloAula,
      dataAula: dataAula || null
    });
  }

  // 1.3. Aula removida do curso (apenas inscritos)
  async notificarAulaRemovida(idCurso, tituloAula) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '🗑️ Aula removida';
    const corpo = `A aula "${tituloAula}" foi removida do curso "${curso.titulo}"`;
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'aula_removida',
      idCurso: idCurso.toString(),
      tituloAula
    });
  }

  // 1.4. Material removido do curso (apenas inscritos)
  async notificarMaterialRemovido(idCurso, tituloMaterial, tipoMaterial = 'material') {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '🗑️ Material removido';
    const corpo = `O ${tipoMaterial} "${tituloMaterial}" foi removido do curso "${curso.titulo}"`;
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'material_removido',
      idCurso: idCurso.toString(),
      tituloMaterial,
      tipoMaterial
    });
  }

  // 1.5. Novo link adicionado ao curso (apenas inscritos)
  async notificarNovoLink(idCurso, tituloLink, urlLink) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '🔗 Novo link disponível';
    const corpo = `Novo link "${tituloLink}" foi adicionado ao curso "${curso.titulo}"`;
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'novo_link',
      idCurso: idCurso.toString(),
      tituloLink,
      urlLink
    });
  }

  // 1.6. Link removido do curso (apenas inscritos)
  async notificarLinkRemovido(idCurso, tituloLink) {
    const curso = await this.db.cursos.findByPk(idCurso);
    if (!curso) return false;

    const titulo = '🗑️ Link removido';
    const corpo = `O link "${tituloLink}" foi removido do curso "${curso.titulo}"`;
    
    return await this.enviarNotificacaoParaCurso(idCurso, titulo, corpo, {
      tipo: 'link_removido',
      idCurso: idCurso.toString(),
      tituloLink
    });
  }

  // 6. Comentário foi denunciado
  async notificarComentarioDenunciado(idUtilizador, tipoComentario, motivo) {
    const titulo = '⚠️ Comentário denunciado';
    const corpo = `O seu ${tipoComentario} foi denunciado. Motivo: ${motivo}`;
    
    return await this.enviarNotificacaoParaUtilizador(idUtilizador, titulo, corpo, {
      tipo: 'denuncia',
      tipoComentario,
      motivo
    });
  }

  // 7. REMOVER: Novo curso publicado (não deve notificar todos)
  // Esta funcionalidade foi removida pois só devemos notificar inscritos

  // 8. Resposta no fórum
  async notificarRespostaForum(idUtilizadorOriginal, tituloPost) {
    const titulo = '💬 Nova resposta no fórum';
    const corpo = `Alguém respondeu ao seu post "${tituloPost}"`;
    
    return await this.enviarNotificacaoParaUtilizador(idUtilizadorOriginal, titulo, corpo, {
      tipo: 'resposta_forum',
      tituloPost
    });
  }
}

module.exports = { FirebasePushService, initializeFirebase };
