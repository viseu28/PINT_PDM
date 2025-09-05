const { Sequelize } = require('sequelize');
const axios = require('axios');

// Configuração da base de dados localhost
const localhostDB = new Sequelize('projeto_pint', 'postgres', 'root', {
  host: 'localhost',
  dialect: 'postgres',
  logging: false
});

// URL do Render
const RENDER_URL = 'https://pint-pdm.onrender.com';

// Função para sincronizar cursos do localhost para o Render
async function syncToRender() {
  try {
    console.log('🔄 Iniciando sincronização localhost → Render...');
    
    // Buscar todos os cursos do localhost
    const [courses] = await localhostDB.query('SELECT * FROM cursos ORDER BY id');
    console.log(`📚 Encontrados ${courses.length} cursos no localhost`);
    
    // Enviar para o Render
    const response = await axios.post(`${RENDER_URL}/sync-courses-from-localhost`, {
      courses: courses
    });
    
    console.log('✅ Sincronização concluída:', response.data);
    return response.data;
    
  } catch (error) {
    console.error('❌ Erro na sincronização:', error.message);
    throw error;
  }
}

// Função para monitorizar mudanças e sincronizar automaticamente
async function startAutoSync() {
  console.log('🚀 Iniciando monitorização automática...');
  
  let lastCourseCount = 0;
  
  setInterval(async () => {
    try {
      const [courses] = await localhostDB.query('SELECT COUNT(*) as count FROM cursos');
      const currentCount = parseInt(courses[0].count);
      
      if (currentCount !== lastCourseCount) {
        console.log(`📊 Detectada mudança: ${lastCourseCount} → ${currentCount} cursos`);
        await syncToRender();
        lastCourseCount = currentCount;
      }
    } catch (error) {
      console.error('⚠️ Erro na monitorização:', error.message);
    }
  }, 10000); // Verificar a cada 10 segundos
}

// Executar se chamado diretamente
if (require.main === module) {
  // Sincronização manual
  if (process.argv[2] === 'sync') {
    syncToRender().then(() => process.exit(0)).catch(() => process.exit(1));
  }
  // Monitorização automática
  else if (process.argv[2] === 'auto') {
    startAutoSync();
  }
  else {
    console.log('Uso:');
    console.log('  node sync-client.js sync   # Sincronização manual');
    console.log('  node sync-client.js auto   # Monitorização automática');
  }
}

module.exports = { syncToRender, startAutoSync };
