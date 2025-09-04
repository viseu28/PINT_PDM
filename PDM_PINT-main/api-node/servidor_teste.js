const express = require('express');

const app = express();
app.use(express.json());

// Rota de teste simples
app.get('/test', (req, res) => {
    res.json({ message: 'API está funcionando!' });
});

// Rota de teste para categorias (sem base de dados)
app.get('/forum-pedidos/categorias', (req, res) => {
    res.json({
        success: true,
        categorias: [
            { id: 1, nome: 'Programação' },
            { id: 2, nome: 'Perguntas e Respostas' }
        ]
    });
});

const PORT = 3001; // Usar porta diferente
app.listen(PORT, () => {
    console.log(`🚀 Servidor de teste a correr na porta ${PORT}`);
});

console.log('Teste: pressione Ctrl+C para parar');
