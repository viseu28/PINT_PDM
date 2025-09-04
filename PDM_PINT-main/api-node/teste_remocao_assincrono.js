// Script para testar a remoção de cursos assíncronos terminados
// Execute este script para simular um curso assíncrono terminado

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function testarRemocaoAssincronoTerminado() {
  try {
    console.log('🔍 Testando remoção de cursos assíncronos terminados...\n');

    // 1. Buscar cursos assíncronos ativos
    const cursosAssincronos = await pool.query(`
      SELECT id, titulo, estado, sincrono, data_fim 
      FROM cursos 
      WHERE sincrono = false 
      AND estado != 'Terminado'
      LIMIT 1
    `);

    if (cursosAssincronos.rows.length === 0) {
      console.log('❌ Nenhum curso assíncrono ativo encontrado para teste');
      return;
    }

    const curso = cursosAssincronos.rows[0];
    console.log(`📚 Curso selecionado: ${curso.titulo} (ID: ${curso.id})`);
    console.log(`📊 Estado atual: ${curso.estado}`);
    console.log(`⏰ Tipo: ${curso.sincrono ? 'Síncrono' : 'Assíncrono'}\n`);

    // 2. Verificar se alguém está inscrito neste curso
    const inscricoes = await pool.query(`
      SELECT COUNT(*) as total 
      FROM inscricoes 
      WHERE idcurso = $1
    `, [curso.id]);

    console.log(`👥 Inscrições encontradas: ${inscricoes.rows[0].total}\n`);

    if (inscricoes.rows[0].total == 0) {
      console.log('⚠️ Nenhuma inscrição encontrada. O teste seria mais efetivo com inscrições.');
    }

    // 3. Alterar estado para "Terminado" temporariamente
    console.log('🔄 Alterando estado para "Terminado"...');
    await pool.query(`
      UPDATE cursos 
      SET estado = 'Terminado' 
      WHERE id = $1
    `, [curso.id]);

    console.log('✅ Estado alterado com sucesso!');
    console.log('📱 Agora teste na aplicação:');
    console.log('   1. Vá para "Meus Cursos"');
    console.log('   2. Verifique se o curso assíncrono terminado não aparece');
    console.log('   3. Compare com cursos síncronos terminados que devem aparecer\n');

    // 4. Aguardar input do usuário
    console.log('⏳ Pressione qualquer tecla para restaurar o estado original...');
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.on('data', async () => {
      // 5. Restaurar estado original
      console.log('\n🔄 Restaurando estado original...');
      await pool.query(`
        UPDATE cursos 
        SET estado = $1 
        WHERE id = $2
      `, [curso.estado, curso.id]);

      console.log('✅ Estado restaurado!');
      console.log(`📚 Curso "${curso.titulo}" voltou ao estado: ${curso.estado}`);
      
      process.exit(0);
    });

  } catch (error) {
    console.error('❌ Erro durante o teste:', error);
  }
}

// Executar teste
testarRemocaoAssincronoTerminado();
