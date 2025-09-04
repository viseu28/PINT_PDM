require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: 'localhost',
  dialect: 'postgres',
  logging: false
});

async function verificarTokens() {
  try {
    console.log('🔍 Verificando FCM tokens e inscrições...\n');

    // 1. FCM tokens registrados
    const tokens = await sequelize.query(`
      SELECT id, nome, email, fcm_token 
      FROM utilizador 
      WHERE fcm_token IS NOT NULL AND fcm_token != ''
    `, { type: sequelize.QueryTypes.SELECT });

    console.log(`📱 FCM Tokens registrados: ${tokens.length}`);
    tokens.forEach(user => {
      console.log(`   👤 ${user.nome} (ID: ${user.id}) - Token: ${user.fcm_token.substring(0, 30)}...`);
    });

    // 2. Inscrições ativas com tokens
    const inscricoes = await sequelize.query(`
      SELECT fi.utilizador_id, fi.curso_id, u.nome, u.fcm_token, c.nome as curso_nome
      FROM form_inscricao fi
      JOIN utilizador u ON fi.utilizador_id = u.id
      JOIN cursos c ON fi.curso_id = c.id
      WHERE fi.estado = 'ativa' AND u.fcm_token IS NOT NULL
    `, { type: sequelize.QueryTypes.SELECT });

    console.log(`\n✅ Inscrições ativas com FCM token: ${inscricoes.length}`);
    inscricoes.forEach(insc => {
      console.log(`   📚 ${insc.nome} inscrito em "${insc.curso_nome}" (Curso ID: ${insc.curso_id})`);
    });

    if (tokens.length === 0) {
      console.log('\n❌ PROBLEMA: Nenhum FCM token registrado!');
      console.log('   Solução: O app Flutter precisa registrar o token primeiro.');
    } else if (inscricoes.length === 0) {
      console.log('\n❌ PROBLEMA: Nenhuma inscrição ativa com FCM token!');
      console.log('   Solução: Utilizador precisa estar inscrito no curso e ter token FCM.');
    } else {
      console.log('\n✅ Configuração OK! Tokens e inscrições existem.');
      console.log('   Se não recebe notificações, pode ser:');
      console.log('   1. Interface web não usa endpoint POST /cursos/:id/materiais');
      console.log('   2. Erro na configuração do Firebase');
      console.log('   3. Token FCM inválido/expirado');
    }

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarTokens();
