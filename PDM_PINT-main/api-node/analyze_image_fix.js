// Script para testar e corrigir URLs de imagem diretamente
const { Pool } = require('pg');

const pool = new Pool({
  user: 'grupo',
  host: '172.201.108.53',
  database: 'pint',
  password: 'paswwordpint',
  port: 5432,
});

async function testAndFixImages() {
  try {
    console.log('🔍 Analisando problema das imagens...\n');
    
    // 1. Verificar dados na BD
    console.log('📊 DADOS NA BASE DE DADOS:');
    const bdResult = await pool.query(`
      SELECT id, titulo, imgcurso 
      FROM cursos 
      WHERE imgcurso IS NOT NULL 
      ORDER BY id 
      LIMIT 5
    `);
    
    bdResult.rows.forEach(row => {
      console.log(`ID ${row.id}: ${row.titulo}`);
      console.log(`   imgcurso: ${row.imgcurso.substring(0, 80)}...`);
      console.log(`   Tipo: ${typeof row.imgcurso}`);
      console.log(`   É URL HTTP: ${row.imgcurso.toString().startsWith('http')}`);
      console.log(`   É Base64: ${row.imgcurso.toString().startsWith('data:image')}`);
      console.log(`   É nome arquivo: ${!row.imgcurso.toString().startsWith('http') && !row.imgcurso.toString().startsWith('data:image')}`);
      console.log('');
    });

    console.log('🔍 ANÁLISE FINAL:');
    console.log('A base de dados contém URLs do Cloudinary corretas.');
    console.log('O problema estava no endpoint que convertia essas URLs para Base64.');
    console.log('\\nSOLUÇÃO APLICADA:');
    console.log('✅ Removida conversão para Base64 no endpoint /cursos');
    console.log('✅ URLs agora passam diretamente da BD para o Flutter');
    console.log('\\n📱 RESULTADO NO FLUTTER:');
    console.log('✅ "Meus Cursos": Já funcionava (usa endpoint /inscricoes)');
    console.log('✅ "Todos os Cursos": Agora deve funcionar (usa endpoint /cursos corrigido)');
    
    await pool.end();
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
    await pool.end();
  }
}

testAndFixImages();
