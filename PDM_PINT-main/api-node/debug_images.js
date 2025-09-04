const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('pint', 'grupo', 'paswwordpint', { 
  host: '172.201.108.53', 
  dialect: 'postgres', 
  port: 5432,
  logging: false 
});

async function checkImages() {
  try {
    console.log('🔍 Verificando imagens dos cursos...\n');
    
    const result = await sequelize.query(`
      SELECT id, titulo, tema, imgcurso IS NOT NULL as has_image, 
             CASE WHEN imgcurso IS NOT NULL THEN LENGTH(imgcurso) ELSE 0 END as image_size
      FROM cursos 
      ORDER BY id LIMIT 15
    `);
    
    console.log('📊 Status das imagens dos cursos:');
    console.log('═══════════════════════════════════════════════════════════════');
    
    result[0].forEach(curso => {
      console.log(`ID: ${curso.id}`);
      console.log(`Título: ${curso.titulo}`);
      console.log(`Tema: ${curso.tema}`);
      console.log(`Tem imagem: ${curso.has_image}`);
      console.log(`Tamanho: ${curso.image_size} bytes`);
      console.log('───────────────────────────────────────────────────────────────');
    });
    
    // Verificar especificamente os cursos que funcionam vs não funcionam
    console.log('\n🎯 Verificando cursos específicos que funcionam/não funcionam:');
    
    const specificCourses = await sequelize.query(`
      SELECT id, titulo, tema, 
             CASE WHEN imgcurso IS NOT NULL THEN 'SIM' ELSE 'NÃO' END as tem_imagem,
             CASE WHEN imgcurso IS NOT NULL THEN LENGTH(imgcurso) ELSE 0 END as tamanho_bytes
      FROM cursos 
      WHERE titulo ILIKE '%front%' 
         OR titulo ILIKE '%python%'
         OR titulo ILIKE '%estrutura%'
         OR titulo ILIKE '%dados%'
      ORDER BY id
    `);
    
    console.log('Cursos específicos mencionados:');
    specificCourses[0].forEach(curso => {
      console.log(`✅ ${curso.titulo} - Imagem: ${curso.tem_imagem} (${curso.tamanho_bytes} bytes)`);
    });
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    process.exit();
  }
}

checkImages();
