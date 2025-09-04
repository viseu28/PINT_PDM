const express = require('express');

// Função para processar URLs de imagem baseado no tipo de conteúdo
function processImageUrl(imgcurso) {
  if (!imgcurso) return null;
  
  const imageString = imgcurso.toString();
  
  // Se já é uma URL completa (Cloudinary), usar diretamente
  if (imageString.startsWith('http')) {
    return imageString;
  }
  
  // Se é um nome de arquivo, verificar se existe e mapear nomes corretos
  if (imageString.includes('.') && imageString.length < 100) {
    // Mapear nomes de ficheiros que podem ter diferenças
    const fileNameMapping = {
      'python_finanças.jpg': 'python_financas.jpg',
      'python_estruturas.jpg': 'Python3.jpg', // Usar Python3.jpg como fallback
      'Desenvolvimento_mobile.jpg': 'frontend.jpg' // Usar frontend.jpg como fallback
    };
    
    const mappedFileName = fileNameMapping[imageString] || imageString;
    return `http://192.168.1.68:3000/uploads/${mappedFileName}`;
  }
  
  // Se for Base64 (buffer), converter
  if (Buffer.isBuffer(imgcurso)) {
    return `data:image/jpeg;base64,${imgcurso.toString('base64')}`;
  }
  
  // Fallback: tentar como Base64 string
  return `data:image/jpeg;base64,${imageString}`;
}

module.exports = (db) => {
  const router = express.Router();
  const { sequelize } = db;

  // GET /percursoformativo/:idutilizador - percurso formativo do utilizador
  router.get('/:idutilizador', async (req, res) => {
    try {
      const { idutilizador } = req.params;
      console.log('🔍 Buscando percurso formativo para utilizador:', idutilizador);
      
      // Primeiro vamos verificar os tipos de dados das colunas
      console.log('🔍 Verificando tipos de dados das colunas...');
      
      const columnInfo = await sequelize.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'cursos' 
        AND column_name IN ('data_inicio', 'data_fim')
      `, {
        type: sequelize.QueryTypes.SELECT
      });
      
      console.log('📊 Tipos de dados das colunas:', columnInfo);

      // Consulta simples primeiro (sem cálculo de horas)
      const percurso = await sequelize.query(`
        SELECT 
          c.id as idcurso,
          c.titulo as nome_curso,
          c.tema as tipo_curso,
          c.data_fim as data_fim,
          c.data_inicio,
          c.imgcurso,
          40 as horas_totais,
          fi.nota,
          fi.estado as inscricao_ativa,
          fi.idinscricao
        FROM form_inscricao fi
        INNER JOIN cursos c ON fi.idcurso = c.id
        WHERE fi.idutilizador = :idutilizador
      `, {
        replacements: { idutilizador: Number(idutilizador) },
        type: sequelize.QueryTypes.SELECT
      });

      console.log('✅ Query executada com sucesso, encontrados:', percurso.length, 'cursos');

      // Para cada curso, mostrar as horas de presença igual às horas totais e a URL do certificado
      const result = percurso.map(curso => {
        const processedImageUrl = curso.imgcurso ? processImageUrl(curso.imgcurso) : null;
        
        console.log(`🖼️ Processando curso: ${curso.nome_curso}`);
        console.log(`📄 Imagem original: ${curso.imgcurso}`);
        console.log(`🔗 URL processada: ${processedImageUrl}`);
        console.log('───────────────────────────────────────────────────');
        
        return {
          ...curso,
          horas_presenca: curso.horas_totais || 40, // Usar horas calculadas ou 40 como fallback
          certificado: `/percursoformativo/certificado/${curso.idinscricao}`,
          // Processar imagem corretamente baseado no tipo de conteúdo
          imagem_url: processedImageUrl,
          tema: curso.tipo_curso || curso.tema // Garantir que o tema está disponível
        };
      });

      console.log('📤 Enviando resposta de sucesso');
      res.json({
        success: true,
        data: result,
        total: result.length
      });
    } catch (error) {
      console.error('❌ Erro ao buscar percurso formativo:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar percurso formativo',
        message: error.message
      });
    }
  });

  // (Opcional) GET /percursoformativo/test - Teste de conectividade
  router.get('/test', (req, res) => {
    res.json({
      success: true,
      message: 'API de percurso formativo está funcionando',
      timestamp: new Date().toISOString()
    });
  });

  // GET /certificado/:idinscricao - Gera e devolve o PDF do certificado
  router.get('/certificado/:idinscricao', async (req, res) => {
    const PDFDocument = require('pdfkit');
    try {
      const { idinscricao } = req.params;
      // Exemplo: busca dados do formando e curso (ajusta conforme a tua BD)
      const [dados] = await sequelize.query(`
        SELECT fi.idinscricao, fi.nota, fi.data, fi.idutilizador, fi.idcurso, u.nome as nome_utilizador, c.titulo as nome_curso
        FROM form_inscricao fi
        INNER JOIN utilizador u ON fi.idutilizador = u.idutilizador
        INNER JOIN cursos c ON fi.idcurso = c.id
        WHERE fi.idinscricao = :idinscricao
      `, {
        replacements: { idinscricao: Number(idinscricao) },
        type: sequelize.QueryTypes.SELECT
      });
      if (!dados) {
        return res.status(404).json({ success: false, error: 'Inscrição não encontrada' });
      }
      // Gerar PDF
      const doc = new PDFDocument();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'inline; filename=certificado.pdf');
      doc.fontSize(24).text('Certificado de Conclusão', { align: 'center' });
      doc.moveDown();
      doc.fontSize(16).text(`Formando: ${dados.nome_utilizador}`);
      doc.text(`Curso: ${dados.nome_curso}`);
      doc.text(`Nota Final: ${dados.nota ?? '---'}`);
      doc.text(`Data de Inscrição: ${new Date(dados.data).toLocaleDateString()}`);
      doc.text(`Data de Emissão: ${new Date().toLocaleDateString()}`);
      doc.end();
      doc.pipe(res);
    } catch (error) {
      console.error('❌ Erro ao gerar certificado:', error);
      res.status(500).json({ success: false, error: 'Erro ao gerar certificado', message: error.message });
    }
  });

  return router;
};