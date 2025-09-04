const { Pool } = require('pg');

const pool = new Pool({
    user: 'grupo',
    host: '172.201.108.53',
    database: 'pint',
    password: 'paswwordpint',
    port: 5432,
});

async function verificarEstruturaForum() {
    try {
        console.log('🔍 Verificando estrutura do fórum...\n');
        
        // Verificar tabelas relacionadas ao fórum
        const tabelasQuery = `
            SELECT table_name, column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name IN ('categorias', 'areas', 'topicos', 'posts')
            ORDER BY table_name, ordinal_position;
        `;
        
        const result = await pool.query(tabelasQuery);
        
        let currentTable = '';
        result.rows.forEach(row => {
            if (row.table_name !== currentTable) {
                console.log(`\n📋 Tabela: ${row.table_name}`);
                console.log('─'.repeat(50));
                currentTable = row.table_name;
            }
            console.log(`  ${row.column_name} (${row.data_type}) - ${row.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}`);
        });
        
        // Verificar categorias existentes
        console.log('\n📁 Categorias existentes:');
        const categorias = await pool.query('SELECT * FROM categorias ORDER BY idcategoria');
        categorias.rows.forEach(cat => {
            console.log(`  ${cat.idcategoria}: ${cat.nome}`);
        });
        
        // Verificar áreas existentes
        console.log('\n📂 Áreas existentes:');
        const areas = await pool.query(`
            SELECT a.*, c.nome as categoria_nome 
            FROM areas a 
            JOIN categorias c ON a.idcategoria = c.idcategoria 
            ORDER BY c.nome, a.nome
        `);
        areas.rows.forEach(area => {
            console.log(`  ${area.idarea}: ${area.nome} (Categoria: ${area.categoria_nome})`);
        });
        
        // Verificar tópicos existentes
        console.log('\n📝 Tópicos existentes:');
        const topicos = await pool.query(`
            SELECT t.*, a.nome as area_nome, c.nome as categoria_nome 
            FROM topicos t 
            JOIN areas a ON t.idarea = a.idarea 
            JOIN categorias c ON a.idcategoria = c.idcategoria 
            ORDER BY c.nome, a.nome, t.nome
        `);
        topicos.rows.forEach(topico => {
            console.log(`  ${topico.idtopicos}: ${topico.nome} (${topico.categoria_nome} > ${topico.area_nome})`);
        });
        
    } catch (error) {
        console.error('❌ Erro ao verificar estrutura:', error);
    } finally {
        await pool.end();
    }
}

verificarEstruturaForum();
