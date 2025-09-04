// Teste simples para verificar se as correções foram aplicadas
const { Pool } = require('pg');
const http = require('http');

const pool = new Pool({
  user: 'grupo',
  host: '172.201.108.53',
  database: 'pint',
  password: 'paswwordpint',
  port: 5432,
});

async function testImageUrls() {
  try {
    console.log('🔍 Verificando URLs de imagem diretamente da BD...\n');
    
    // Buscar dados diretamente da BD
    const bdResult = await pool.query('SELECT id, titulo, imgcurso FROM cursos WHERE imgcurso IS NOT NULL LIMIT 3');
    
    console.log('📊 DADOS DA BASE DE DADOS:');
    bdResult.rows.forEach((row, i) => {
      console.log(`${i + 1}. ${row.titulo}`);
      console.log(`   BD imgcurso: ${row.imgcurso}`);
      console.log(`   Tipo: ${typeof row.imgcurso}`);
      console.log(`   É URL HTTP: ${row.imgcurso.toString().startsWith('http')}`);
      console.log('');
    });
    
    // Testar endpoint da API
    console.log('🔗 Testando endpoint /cursos...\n');
    
    const options = {
      hostname: '192.168.1.68',
      port: 3000,
      path: '/cursos',
      method: 'GET',
      headers: { 'Content-Type': 'application/json' }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const data = JSON.parse(body);
          console.log('📊 DADOS DA API:');
          
          for (let i = 0; i < Math.min(3, data.length); i++) {
            const curso = data[i];
            console.log(`${i + 1}. ${curso.titulo}`);
            console.log(`   API imgcurso: ${curso.imgcurso}`);
            
            if (curso.imgcurso) {
              const isMalformed = curso.imgcurso.includes('data:image/jpeg;base64,http');
              const isCorrect = curso.imgcurso.startsWith('http') && !isMalformed;
              
              console.log(`   ✅ Correto: ${isCorrect}`);
              console.log(`   ❌ Malformado: ${isMalformed}`);
            }
            console.log('');
          }
          
          const malformed = data.filter(c => c.imgcurso && c.imgcurso.includes('data:image/jpeg;base64,http')).length;
          const correct = data.filter(c => c.imgcurso && c.imgcurso.startsWith('http') && !c.imgcurso.includes('data:image')).length;
          
          console.log('📈 RESUMO:');
          console.log(`   URLs corretas: ${correct}`);
          console.log(`   URLs malformadas: ${malformed}`);
          
          if (malformed > 0) {
            console.log('\\n❌ PROBLEMA: Endpoint ainda retorna URLs malformadas!');
            console.log('   Verifique se o servidor foi reiniciado completamente.');
          } else {
            console.log('\\n✅ SUCESSO: Todas as URLs estão corretas!');
          }
          
        } catch (e) {
          console.log('❌ Erro ao processar resposta da API:', e.message);
        }
        
        pool.end();
      });
    });

    req.on('error', (e) => {
      console.log('❌ Erro na requisição:', e.message);
      pool.end();
    });

    req.end();
    
  } catch (e) {
    console.error('❌ Erro:', e.message);
    pool.end();
  }
}

testImageUrls();
