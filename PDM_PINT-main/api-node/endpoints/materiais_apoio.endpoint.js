// const express = require('express');
// const router = express.Router();
// const path = require('path');
// const db = require('../models'); // Ajusta conforme teu projeto

// router.get('/:id/download', async (req, res) => {
//   const id = req.params.id;

//   try {
//     const material = await db.materiais_apoio.findByPk(id);

//     if (!material) {
//       return res.status(404).send('Material não encontrado');
//     }

//     const filePath = path.resolve('uploads/materiais', material.caminho_arquivo);
//     res.download(filePath, material.nome_arquivo);
//   } catch (err) {
//     console.error('Erro ao fazer download:', err);
//     res.status(500).send('Erro ao fazer download');
//   }
// });

// module.exports = router;
