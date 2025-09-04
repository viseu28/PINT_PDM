const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
    user: 'grupo',
    host: '172.201.108.53',
    database: 'pint',
    password: 'paswwordpint',
    port: 5432,
});

async function criarTabelaPedidos() {
    try {
        console.log('🏗️ Criando tabela pedidos_topicos...\n');
        
        // Ler o arquivo SQL
        const sqlFile = path.join(__dirname, 'criar_tabela_pedidos_topicos.sql');
        const sql = fs.readFileSync(sqlFile, 'utf8');
        
        // Executar o SQL
        await pool.query(sql);
        
        console.log('✅ Tabela pedidos_topicos criada com sucesso!');
        
        // Verificar se a tabela foi criada
        const verificacao = await pool.query(`
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'pedidos_topicos'
            ORDER BY ordinal_position;
        `);
        
        console.log('\n📋 Estrutura da tabela criada:');
        console.log('─'.repeat(70));
        verificacao.rows.forEach(col => {
            const defaultVal = col.column_default ? ` (default: ${col.column_default})` : '';
            console.log(`  ${col.column_name.padEnd(20)} | ${col.data_type.padEnd(15)} | ${col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}${defaultVal}`);
        });
        
    } catch (error) {
        if (error.code === '42P07') {
            console.log('⚠️ Tabela pedidos_topicos já existe!');
        } else {
            console.error('❌ Erro ao criar tabela:', error);
        }
    } finally {
        await pool.end();
    }
}

criarTabelaPedidos();
