const { Pool } = require('pg');

const pool = new Pool({
  user: 'grupo',
  host: '172.201.108.53', 
  database: 'pint',
  password: 'paswwordpint',
  port: 5432,
});

async function checkResposta() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'resposta' 
      ORDER BY ordinal_position
    `);
    
    console.log('Colunas da tabela resposta:');
    result.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    process.exit(0);
  } catch (err) {
    console.error('Erro:', err.message);
    process.exit(1);
  }
}

checkResposta();
