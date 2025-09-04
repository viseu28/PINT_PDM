const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', { 
  host: '172.201.108.53', 
  dialect: 'postgres', 
  port: 5432,
  logging: false 
});

async function checkImageContent() {
  try {
    console.log('🔍 Verificando conteúdo das imagens...\n');
    
    // Verificar os cursos que funcionam vs não funcionam
    const result = await sequelize.query(`
      SELECT id, titulo, tema, imgcurso,
             CASE WHEN imgcurso IS NOT NULL THEN LENGTH(imgcurso) ELSE 0 END as tamanho_bytes
      FROM cursos 
      WHERE id IN (1, 2, 3, 4, 5, 6, 35, 36, 37)
      ORDER BY id
    `);
    
    console.log('🔍 Conteúdo das imagens (primeiros 100 caracteres):');
    console.log('═══════════════════════════════════════════════════════════════');
    
    result[0].forEach(curso => {
      console.log(`\n📚 ID ${curso.id}: ${curso.titulo}`);
      console.log(`Tema: ${curso.tema}`);
      console.log(`Tamanho: ${curso.tamanho_bytes} bytes`);
      
      if (curso.imgcurso) {
        // Converter o buffer para string para ver o conteúdo
        const content = curso.imgcurso.toString();
        console.log(`Conteúdo (primeiros 100 chars): "${content.substring(0, 100)}"`);
        console.log(`Tipo de dados: ${typeof curso.imgcurso}`);
        
        // Verificar se é base64
        const isBase64 = /^[A-Za-z0-9+/]*={0,2}$/.test(content);
        console.log(`Parece Base64: ${isBase64}`);
        
        // Verificar se é um nome de arquivo
        const isFilename = content.includes('.') && content.length < 100;
        console.log(`Parece nome de arquivo: ${isFilename}`);
        
      } else {
        console.log('Sem imagem');
      }
      console.log('───────────────────────────────────────────────────────────────');
    });
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    process.exit();
  }
}

checkImageContent();
