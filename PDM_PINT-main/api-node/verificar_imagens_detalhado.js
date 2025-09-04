const { Sequelize } = require('sequelize');

// Conexão à base de dados
const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', {
  host: '172.201.108.53',
  dialect: 'postgres',
  port: 5432,
  logging: false
});

async function verificarImagensCursos() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado à base de dados');
    
    const [results] = await sequelize.query(`
      SELECT id, titulo, imgcurso, estado, tipo 
      FROM cursos 
      ORDER BY id
    `);
    
    console.log('\n📚 Status das imagens dos cursos:');
    console.log('====================================');
    
    let comImagem = 0;
    let semImagem = 0;
    
    results.forEach(curso => {
      const temImagem = curso.imgcurso && curso.imgcurso.trim() !== '';
      if (temImagem) comImagem++;
      else semImagem++;
      
      console.log(`ID: ${curso.id} | ${curso.titulo}`);
      console.log(`   Estado: ${curso.estado} | Tipo: ${curso.tipo}`);
      console.log(`   Imagem: ${temImagem ? '✅ ' + curso.imgcurso : '❌ Sem imagem'}`);
      console.log('   ---');
    });
    
    console.log(`\n📊 Resumo:`);
    console.log(`   Com imagem: ${comImagem}`);
    console.log(`   Sem imagem: ${semImagem}`);
    console.log(`   Total: ${results.length}`);
    
    // Mostrar cursos sem imagem para corrigir
    const cursosSemImagem = results.filter(c => !c.imgcurso || c.imgcurso.trim() === '');
    if (cursosSemImagem.length > 0) {
      console.log('\n🔧 Cursos que precisam de imagem:');
      cursosSemImagem.forEach(curso => {
        console.log(`   - ID ${curso.id}: ${curso.titulo}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    await sequelize.close();
  }
}

verificarImagensCursos();
