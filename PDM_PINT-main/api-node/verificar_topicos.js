const { Pool } = require('pg');

const pool = new Pool({
    user: 'grupo',
    host: '172.201.108.53',
    database: 'pint',
    password: 'paswwordpint',
    port: 5432,
});

async function verificarEstrutura() {
    try {
        console.log('📋 Verificando estrutura da tabela topicos...');
        
        const result = await pool.query(`
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'topicos' 
            ORDER BY ordinal_position
        `);
        
        console.log('📊 Colunas da tabela topicos:');
        result.rows.forEach(row => {
            console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
        });
        
    } catch (error) {
        console.error('❌ Erro:', error.message);
    } finally {
        await pool.end();
    }
}

verificarEstrutura();
