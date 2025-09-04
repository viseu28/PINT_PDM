const http = require('http');

const options = {
  hostname: '192.168.1.68',
  port: 3000,
  path: '/cursos',
  method: 'GET',
  headers: { 'Content-Type': 'application/json' }
};

console.log('🧪 Testando endpoint /cursos após correção...\n');

const req = http.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    try {
      const data = JSON.parse(body);
      console.log('✅ STATUS:', res.statusCode);
      console.log('📊 TOTAL CURSOS:', data.length);
      
      if (data.length > 0) {
        console.log('\n🔍 ANÁLISE DE IMAGENS:');
        console.log('=' .repeat(50));
        
        for (let i = 0; i < Math.min(3, data.length); i++) {
          const curso = data[i];
          console.log(`\n📚 CURSO ${i + 1}: ${curso.titulo}`);
          console.log(`   imgcurso: ${curso.imgcurso}`);
          
          if (curso.imgcurso) {
            const isHttpUrl = curso.imgcurso.startsWith('http');
            const isCloudinary = curso.imgcurso.includes('cloudinary');
            const isMalformed = curso.imgcurso.includes('data:image/jpeg;base64,http');
            
            console.log(`   ✅ URL HTTP válida: ${isHttpUrl}`);
            console.log(`   🌤️  URL Cloudinary: ${isCloudinary}`);
            console.log(`   ❌ URL malformada: ${isMalformed}`);
            
            if (isMalformed) {
              console.log('   🔧 CORREÇÃO NECESSÁRIA: Esta URL ainda está malformada!');
            } else if (isHttpUrl && isCloudinary) {
              console.log('   ✅ PERFEITO: URL está correta!');
            }
          } else {
            console.log('   ⚠️  Sem imagem');
          }
        }
        
        console.log('\n📊 RESUMO:');
        const totalComImagem = data.filter(c => c.imgcurso).length;
        const urlsCorretas = data.filter(c => c.imgcurso && c.imgcurso.startsWith('http') && !c.imgcurso.includes('data:image')).length;
        const urlsMalformadas = data.filter(c => c.imgcurso && c.imgcurso.includes('data:image/jpeg;base64,http')).length;
        
        console.log(`   Total com imagem: ${totalComImagem}`);
        console.log(`   URLs corretas: ${urlsCorretas}`);
        console.log(`   URLs malformadas: ${urlsMalformadas}`);
        
        if (urlsMalformadas > 0) {
          console.log('\n❌ PROBLEMA: Ainda existem URLs malformadas!');
          console.log('   A correção no servidor não foi aplicada corretamente.');
        } else {
          console.log('\n✅ SUCESSO: Todas as URLs estão corretas!');
        }
      }
    } catch (e) {
      console.log('❌ ERROR:', e.message);
    }
  });
});

req.on('error', (e) => {
  console.log('❌ REQUEST ERROR:', e.message);
});

req.end();
