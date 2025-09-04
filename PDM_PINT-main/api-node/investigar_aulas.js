const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function investigarAulas() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // 1. Verificar estrutura da tabela aulas
    console.log('\n📋 Estrutura da tabela aulas:');
    const [estrutura] = await sequelize.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'aulas'
      ORDER BY ordinal_position
    `);
    console.table(estrutura);
    
    // 2. Verificar aulas adicionadas HOJE ao curso 37
    console.log('\n📚 Aulas adicionadas HOJE ao curso 37 (Curso Teste - Em Breve):');
    const [aulasHoje] = await sequelize.query(`
      SELECT * FROM aulas 
      WHERE curso_id = 37 
      AND DATE(created_at) = CURRENT_DATE
      ORDER BY created_at DESC
    `);
    
    if (aulasHoje.length === 0) {
      console.log('❌ Nenhuma aula foi adicionada hoje ao curso 37');
      
      // Ver todas as aulas do curso 37
      console.log('\n📖 Todas as aulas do curso 37:');
      const [todasAulas] = await sequelize.query(`
        SELECT id, titulo, duracao, created_at FROM aulas 
        WHERE curso_id = 37 
        ORDER BY created_at DESC
      `);
      console.table(todasAulas);
    } else {
      console.table(aulasHoje);
      console.log('✅ Aula foi adicionada, MAS pode não ter disparado notificação!');
    }
    
    // 3. Verificar se há coluna created_at
    const hasCreatedAt = estrutura.some(col => col.column_name === 'created_at');
    if (!hasCreatedAt) {
      console.log('\n⚠️ Tabela aulas não tem coluna created_at - vou tentar com outras colunas');
      
      const [ultimasAulas] = await sequelize.query(`
        SELECT * FROM aulas 
        WHERE curso_id = 37 
        ORDER BY id DESC 
        LIMIT 5
      `);
      console.table(ultimasAulas);
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

investigarAulas();
