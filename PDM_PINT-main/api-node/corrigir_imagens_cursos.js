const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function corrigirImagensCursos() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    // 1. Corrigir o curso sem imagem (ID 37)
    await sequelize.query(`
      UPDATE cursos 
      SET imgcurso = 'Python3.jpg' 
      WHERE id = 37
    `);
    console.log('✅ Curso ID 37 atualizado com imagem Python3.jpg');
    
    // 2. Corrigir nomes de arquivo com caracteres especiais
    const cursosParaCorrigir = [
      { id: 4, novoNome: 'python_financas.jpg' }, // Remover ç
      { id: 3, novoNome: 'Python3.jpg' }, // python_estruturas.jpg não existe
      { id: 5, novoNome: 'frontend.jpg' } // Desenvolvimento_mobile.jpg não existe
    ];
    
    for (const curso of cursosParaCorrigir) {
      await sequelize.query(`
        UPDATE cursos 
        SET imgcurso = ? 
        WHERE id = ?
      `, {
        replacements: [curso.novoNome, curso.id]
      });
      console.log(`✅ Curso ID ${curso.id} atualizado com imagem ${curso.novoNome}`);
    }
    
    // 3. Verificar o resultado
    const [results] = await sequelize.query(`
      SELECT id, titulo, imgcurso 
      FROM cursos 
      WHERE imgcurso LIKE '%.jpg' OR imgcurso LIKE '%.png'
      ORDER BY id
    `);
    
    console.log('\n📚 Cursos com arquivos locais:');
    results.forEach(curso => {
      console.log(`   ID ${curso.id}: ${curso.titulo} -> ${curso.imgcurso}`);
    });
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

corrigirImagensCursos();
