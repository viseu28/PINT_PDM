const { Pool } = require('pg');

const pool = new Pool({
    user: 'grupo',
    host: '172.201.108.53',
    database: 'pint',
    password: 'paswwordpint',
    port: 5432,
});

async function verificarTabelasExistentes() {
    try {
        console.log('🔍 Verificando tabelas na base de dados...\n');
        
        // Listar todas as tabelas
        const tabelas = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        `);
        
        console.log('📋 Tabelas existentes:');
        tabelas.rows.forEach(table => {
            console.log(`  - ${table.table_name}`);
        });
        
        // Procurar tabelas relacionadas a users/utilizadores
        console.log('\n🔍 Procurando tabelas de utilizadores:');
        const userTables = tabelas.rows.filter(table => 
            table.table_name.toLowerCase().includes('user') || 
            table.table_name.toLowerCase().includes('utilizador')
        );
        
        if (userTables.length > 0) {
            userTables.forEach(table => {
                console.log(`  ✅ ${table.table_name}`);
            });
        } else {
            console.log('  ❌ Nenhuma tabela de utilizadores encontrada com nomes óbvios');
        }
        
    } catch (error) {
        console.error('❌ Erro:', error);
    } finally {
        await pool.end();
    }
}

verificarTabelasExistentes();
