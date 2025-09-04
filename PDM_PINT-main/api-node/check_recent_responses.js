const { Pool } = require('pg');

const pool = new Pool({
  user: 'grupo',
  host: '172.201.108.53', 
  database: 'pint',
  password: 'paswwordpint',
  port: 5432,
});

async function checkRecentResposta() {
  try {
    const result = await pool.query(`
      SELECT idresposta, texto, url, anexo, datahora
      FROM resposta 
      ORDER BY datahora DESC 
      LIMIT 5
    `);
    
    console.log('Últimas 5 respostas:');
    result.rows.forEach(row => {
      console.log(`ID: ${row.idresposta}, Texto: ${row.texto ? row.texto.substring(0, 50) : 'null'}, URL: ${row.url || 'null'}, Anexo: ${row.anexo || 'null'}`);
    });
    
    process.exit(0);
  } catch (err) {
    console.error('Erro:', err.message);
    process.exit(1);
  }
}

checkRecentResposta();
