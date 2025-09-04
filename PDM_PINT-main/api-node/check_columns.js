const { Pool } = require('pg');

const pool = new Pool({
  user: 'grupo',
  host: '172.201.108.53',
  database: 'pint',
  password: 'paswwordpint',
  port: 5432,
});

async function checkColumns() {
  try {
    const result = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'cursos' 
      ORDER BY column_name
    `);
    
    console.log('📋 Colunas da tabela cursos:');
    result.rows.forEach(col => console.log('  -', col.column_name));
    
    // Verificar se existe algo relacionado com sincrono/tipo
    const syncColumns = result.rows.filter(col => 
      col.column_name.includes('sinc') || 
      col.column_name.includes('tipo') ||
      col.column_name.includes('async')
    );
    
    console.log('\n🔍 Colunas relacionadas com tipo/sincrono:');
    syncColumns.forEach(col => console.log('  ✅', col.column_name));
    
  } catch (err) {
    console.error('❌ Erro:', err.message);
  }
  
  await pool.end();
  process.exit(0);
}

checkColumns();
