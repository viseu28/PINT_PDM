const { Sequelize } = require('sequelize');
const fs = require('fs');

// Configuração da base de dados LOCAL (ajusta conforme a tua configuração)
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function exportarDados() {
  try {
    console.log('🔄 Conectando à base de dados local...');
    await sequelize.authenticate();
    console.log('✅ Conectado com sucesso!');

    // Lista de tabelas importantes para exportar
    const tabelasImportantes = [
      'utilizador', 'cursos', 'categorias', 'areas', 'topicos',
      'formador', 'formando', 'post', 'forum', 'favoritos'
    ];

    const sqlStatements = [];

    for (const tabela of tabelasImportantes) {
      try {
        console.log(`📤 Exportando ${tabela}...`);
        
        // Obter dados da tabela
        const dados = await sequelize.query(`SELECT * FROM "public"."${tabela}"`, {
          type: Sequelize.QueryTypes.SELECT
        });

        if (dados.length > 0) {
          // Obter colunas da tabela
          const colunas = Object.keys(dados[0]);
          const colunasStr = colunas.map(col => `"${col}"`).join(', ');
          
          // Criar INSERT statements
          for (const registro of dados) {
            const valores = colunas.map(col => {
              const valor = registro[col];
              if (valor === null) return 'NULL';
              if (typeof valor === 'string') return `'${valor.replace(/'/g, "''")}'`;
              if (typeof valor === 'boolean') return valor ? 'TRUE' : 'FALSE';
              if (valor instanceof Date) return `'${valor.toISOString()}'`;
              return valor;
            }).join(', ');

            sqlStatements.push(`INSERT INTO "public"."${tabela}" (${colunasStr}) VALUES (${valores}) ON CONFLICT DO NOTHING;`);
          }
          
          console.log(`✅ ${dados.length} registos exportados de ${tabela}`);
        } else {
          console.log(`⚠️ Tabela ${tabela} está vazia`);
        }
      } catch (error) {
        console.log(`❌ Erro ao exportar ${tabela}: ${error.message}`);
      }
    }

    // Salvar SQL em arquivo
    const sqlContent = sqlStatements.join('\n');
    fs.writeFileSync('export_dados.sql', sqlContent);
    
    // Salvar também como JSON para o endpoint
    const exportData = {
      sqlStatements: sqlStatements,
      totalStatements: sqlStatements.length,
      exportDate: new Date().toISOString()
    };
    
    fs.writeFileSync('export_dados.json', JSON.stringify(exportData, null, 2));
    
    console.log(`🎉 Exportação concluída!`);
    console.log(`📁 Arquivos criados:`);
    console.log(`   - export_dados.sql (${sqlStatements.length} comandos SQL)`);
    console.log(`   - export_dados.json (para importação via API)`);
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await sequelize.close();
  }
}

exportarDados();
