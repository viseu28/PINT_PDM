require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: 'localhost',
  dialect: 'postgres',
  logging: false
});

async function debugNotificacoes() {
  try {
    console.log('🔍 === DEBUG NOTIFICAÇÕES ===\n');

    // 1. Verificar FCM tokens registrados
    console.log('1️⃣ FCM TOKENS REGISTRADOS:');
    const tokens = await sequelize.query(`
      SELECT id, nome, email, fcm_token 
      FROM utilizador 
      WHERE fcm_token IS NOT NULL AND fcm_token != ''
      ORDER BY id
    `, { type: sequelize.QueryTypes.SELECT });

    if (tokens.length === 0) {
      console.log('❌ NENHUM FCM TOKEN ENCONTRADO!');
      console.log('   - Certifique-se que o app Flutter registrou o token');
      console.log('   - Use POST /fcm-token para registrar\n');
    } else {
      tokens.forEach(user => {
        console.log(`   👤 ${user.nome} (ID: ${user.id})`);
        console.log(`      📧 ${user.email}`);
        console.log(`      🔑 Token: ${user.fcm_token.substring(0, 20)}...`);
      });
      console.log('');
    }

    // 2. Verificar inscrições ativas
    console.log('2️⃣ INSCRIÇÕES ATIVAS:');
    const inscricoes = await sequelize.query(`
      SELECT fi.id, fi.utilizador_id, fi.curso_id, fi.estado,
             u.nome as nome_utilizador, u.email, u.fcm_token,
             c.nome as nome_curso
      FROM form_inscricao fi
      JOIN utilizador u ON fi.utilizador_id = u.id
      JOIN cursos c ON fi.curso_id = c.id
      WHERE fi.estado = 'ativa'
      ORDER BY fi.curso_id, fi.utilizador_id
    `, { type: sequelize.QueryTypes.SELECT });

    if (inscricoes.length === 0) {
      console.log('❌ NENHUMA INSCRIÇÃO ATIVA ENCONTRADA!');
    } else {
      const inscricoesPorCurso = {};
      inscricoes.forEach(insc => {
        if (!inscricoesPorCurso[insc.curso_id]) {
          inscricoesPorCurso[insc.curso_id] = {
            nome_curso: insc.nome_curso,
            formandos: []
          };
        }
        inscricoesPorCurso[insc.curso_id].formandos.push({
          id: insc.utilizador_id,
          nome: insc.nome_utilizador,
          email: insc.email,
          tem_token: insc.fcm_token ? '✅' : '❌'
        });
      });

      Object.keys(inscricoesPorCurso).forEach(cursoId => {
        const curso = inscricoesPorCurso[cursoId];
        console.log(`   📚 Curso ${cursoId}: ${curso.nome_curso}`);
        curso.formandos.forEach(formando => {
          console.log(`      👤 ${formando.nome} (ID: ${formando.id}) ${formando.tem_token}`);
        });
        console.log('');
      });
    }

    // 3. Verificar últimos materiais adicionados
    console.log('3️⃣ ÚLTIMOS MATERIAIS ADICIONADOS (últimas 24h):');
    const materiaisRecentes = await sequelize.query(`
      SELECT ma.id, ma.titulo, ma.curso_id, ma.created_at,
             c.nome as nome_curso
      FROM materiais_apoio ma
      JOIN cursos c ON ma.curso_id = c.id
      WHERE ma.created_at > NOW() - INTERVAL '24 hours'
      ORDER BY ma.created_at DESC
      LIMIT 10
    `, { type: sequelize.QueryTypes.SELECT });

    if (materiaisRecentes.length === 0) {
      console.log('❌ NENHUM MATERIAL ADICIONADO NAS ÚLTIMAS 24h');
    } else {
      materiaisRecentes.forEach(material => {
        console.log(`   📎 ${material.titulo}`);
        console.log(`      📚 Curso: ${material.nome_curso} (ID: ${material.curso_id})`);
        console.log(`      ⏰ Adicionado: ${material.created_at}`);
        console.log('');
      });
    }

    // 4. Verificar últimas aulas adicionadas
    console.log('4️⃣ ÚLTIMAS AULAS ADICIONADAS (últimas 24h):');
    const aulasRecentes = await sequelize.query(`
      SELECT a.id, a.titulo, a.curso_id, a.created_at,
             c.nome as nome_curso
      FROM aulas a
      JOIN cursos c ON a.curso_id = c.id
      WHERE a.created_at > NOW() - INTERVAL '24 hours'
      ORDER BY a.created_at DESC
      LIMIT 10
    `, { type: sequelize.QueryTypes.SELECT });

    if (aulasRecentes.length === 0) {
      console.log('❌ NENHUMA AULA ADICIONADA NAS ÚLTIMAS 24h');
    } else {
      aulasRecentes.forEach(aula => {
        console.log(`   🎥 ${aula.titulo}`);
        console.log(`      📚 Curso: ${aula.nome_curso} (ID: ${aula.curso_id})`);
        console.log(`      ⏰ Adicionado: ${aula.created_at}`);
        console.log('');
      });
    }

    console.log('5️⃣ POSSÍVEIS PROBLEMAS:');
    const problemas = [];
    
    if (tokens.length === 0) {
      problemas.push('❌ Nenhum FCM token registrado');
    }
    
    if (inscricoes.length === 0) {
      problemas.push('❌ Nenhuma inscrição ativa');
    }

    const inscricoesComToken = inscricoes.filter(i => i.fcm_token);
    if (inscricoesComToken.length === 0 && inscricoes.length > 0) {
      problemas.push('❌ Utilizadores inscritos não têm FCM token');
    }

    if (materiaisRecentes.length === 0 && aulasRecentes.length === 0) {
      problemas.push('⚠️ Nenhum conteúdo novo adicionado (talvez via interface web?)');
    }

    if (problemas.length === 0) {
      console.log('✅ Configuração parece correta');
      console.log('   - Verifique se usou o endpoint correto: POST /cursos/:id/materiais');
      console.log('   - Verifique logs do servidor para erros de notificação');
    } else {
      problemas.forEach(problema => console.log(`   ${problema}`));
    }

  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await sequelize.close();
  }
}

debugNotificacoes();
