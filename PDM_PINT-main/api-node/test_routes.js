const http = require('http');

function listRoutes() {
    console.log('🧪 Listando todas as rotas...');
    
    const routes = [
        '/api/forum-pedidos/categorias',
        '/forum-pedidos/categorias',
        '/categorias',
        '/api/categorias'
    ];

    routes.forEach(path => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: path,
            method: 'GET'
        };

        const req = http.request(options, (res) => {
            console.log(`${path}: Status ${res.statusCode}`);
        });

        req.on('error', (err) => {
            console.log(`${path}: Erro - ${err.message}`);
        });

        req.end();
    });
}

setTimeout(listRoutes, 1000);
