const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
    user: 'grupo',
    host: '172.201.108.53',
    database: 'pint',
    password: 'paswwordpint',
    port: 5432,
});

async function adicionarColunaTopicoId() {
    try {
        console.log('📋 Adicionando coluna topico_id...');
        
        // Ler o arquivo SQL
        const sql = fs.readFileSync('add_topico_id_column.sql', 'utf8');
        
        // Executar o SQL
        await pool.query(sql);
        
        console.log('✅ Coluna topico_id adicionada com sucesso!');
        
        // Verificar se a coluna foi adicionada
        const result = await pool.query(`
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'pedidos_topicos' 
            AND column_name = 'topico_id'
        `);
        
        if (result.rows.length > 0) {
            console.log('✅ Verificação: Coluna topico_id encontrada!');
            console.log('📊 Detalhes:', result.rows[0]);
        } else {
            console.log('❌ Erro: Coluna topico_id não encontrada!');
        }
        
    } catch (error) {
        console.error('❌ Erro ao adicionar coluna:', error.message);
    } finally {
        await pool.end();
    }
}

adicionarColunaTopicoId();
