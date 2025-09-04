const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function simularAlteracaoFormador() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // Verificar dados atuais do curso 36
    console.log('\n📚 Estado atual do curso 36:');
    const [cursoAtual] = await sequelize.query(`
      SELECT id, titulo, formador_responsavel 
      FROM cursos 
      WHERE id = 36
    `);
    console.table(cursoAtual);
    
    // Verificar utilizadores inscritos com token FCM
    console.log('\n👥 Utilizadores inscritos com token FCM:');
    const [utilizadoresInscritos] = await sequelize.query(`
      SELECT u.idutilizador, u.nome, u.email, u.fcm_token,
             i.data as data_inscricao, i.estado as inscricao_ativa
      FROM form_inscricao i
      JOIN utilizador u ON i.idutilizador = u.idutilizador
      WHERE i.idcurso = 36 
      AND i.estado = true
      AND u.fcm_token IS NOT NULL
    `);
    console.table(utilizadoresInscritos);
    
    if (utilizadoresInscritos.length === 0) {
      console.log('⚠️ Não há utilizadores inscritos com token FCM!');
      console.log('\n🔧 Vamos garantir que o utilizador 8 tem token FCM...');
      
      await sequelize.query(`
        UPDATE utilizador 
        SET fcm_token = 'TOKEN_REAL_DEVICE' 
        WHERE idutilizador = 8
      `);
      console.log('✅ Token FCM atualizado para utilizador 8');
    }
    
    // Simular alteração do formador
    const novoFormador = 'Prof. João Silva';
    console.log(`\n🔄 Simulando alteração de formador para: ${novoFormador}`);
    
    await sequelize.query(`
      UPDATE cursos 
      SET formador_responsavel = :novoFormador, 
          updated_at = NOW()
      WHERE id = 36
    `, { replacements: { novoFormador } });
    
    console.log('✅ Formador atualizado na base de dados');
    
    // Verificar estado final
    console.log('\n📚 Estado final do curso 36:');
    const [cursoFinal] = await sequelize.query(`
      SELECT id, titulo, formador_responsavel, updated_at
      FROM cursos 
      WHERE id = 36
    `);
    console.table(cursoFinal);
    
    console.log('\n🎯 Para testar as notificações:');
    console.log('1. Inicie a API: node index.js');
    console.log('2. Use a app Flutter para registar um token FCM real');
    console.log('3. Altere o formador via API PUT /cursos/36');
    console.log('4. Verifique se recebe a notificação no telemóvel');
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

simularAlteracaoFormador();
