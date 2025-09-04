const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  user: 'grupo',
  host: '172.201.108.53', 
  database: 'pint',
  password: 'paswwordpint',
  port: 5432,
});

async function addColumns() {
  try {
    // Verificar se as colunas já existem
    const checkResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'resposta' 
      AND column_name IN ('url', 'anexo')
    `);
    
    if (checkResult.rows.length > 0) {
      console.log('⚠️  Colunas já existem:', checkResult.rows.map(r => r.column_name));
      process.exit(0);
    }
    
    // Ler e executar o SQL
    const sql = fs.readFileSync('add_resposta_columns.sql', 'utf8');
    await pool.query(sql);
    
    console.log('✅ Colunas adicionadas com sucesso!');
    
    // Verificar se foram adicionadas
    const verifyResult = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'resposta' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Estrutura atual da tabela resposta:');
    verifyResult.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
  } catch (err) {
    console.error('❌ Erro:', err.message);
  } finally {
    await pool.end();
  }
}

addColumns();
