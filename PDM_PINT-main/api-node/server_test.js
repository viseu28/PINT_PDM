require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Endpoint básico para teste
app.get('/', (req, res) => {
  res.send('Servidor de teste a funcionar 🚀');
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    api: 'SoftSkills API Test',
    timestamp: new Date().toISOString()
  });
});

// Iniciar servidor
const PORT = 3001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor de teste a correr em http://0.0.0.0:${PORT}`);
});
