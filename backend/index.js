import http from 'http';
import pkg from 'pg';
const { Client } = pkg;

const port = process.env.PORT || 3000;

// Configuração do cliente
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'desafio_db'
};

// Conexão com retry simples
let client = null;
let dbConnected = false;

async function connectWithRetry(retries = 5, delay = 5000) {
  for (let i = 1; i <= retries; i++) {
    const currentClient = new Client(dbConfig);
    
    try {
      await currentClient.connect();
      console.log(`✅ Banco de dados conectado (tentativa ${i})`);
      return { client: currentClient, connected: true };
    } catch (err) {
      console.log(`⏳ Tentativas ${i}/${retries}: ${err.message}`);
      await currentClient.end().catch(() => {});
      
      if (i === retries) {
        console.warn('⚠️ Número máximo de tentativas atingido, iniciando sem banco de dados.');
        return { client: null, connected: false };
      }
      
      await new Promise(r => setTimeout(r, delay));
    }
  }
}

// Configuração CORS completa
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400'); // 24 horas
}

// Handler para requisições OPTIONS (preflight)
function handleOptions(req, res) {
  setCorsHeaders(res);
  res.writeHead(204); // No Content
  res.end();
}

// Healthcheck endpoint
function handleHealth(req, res) {
  setCorsHeaders(res);
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ 
    status: 'OK',
    database: dbConnected,
    timestamp: new Date().toISOString() 
  }));
}

// API endpoint
async function handleApi(req, res) {
  setCorsHeaders(res);
  
  if (!dbConnected || !client) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ 
      error: 'Serviço indisponível',
      database: false 
    }));
  }

  try {
    const result = await client.query('SELECT * FROM users LIMIT 1');
    const user = result.rows[0];
    
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      database: true,
      userAdmin: user?.role === 'admin'
    }));
  } catch (error) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      error: 'Erro no banco de dados',
      details: error.message 
    }));
  }
}

// Inicia conexão em background
(async () => {
  const result = await connectWithRetry();
  client = result.client;
  dbConnected = result.connected;
})();

// Servidor principal
const server = http.createServer(async (req, res) => {
  // Trata preflight OPTIONS
  if (req.method === 'OPTIONS') {
    return handleOptions(req, res);
  }
  
  // Configura CORS para todas as respostas
  setCorsHeaders(res);
  
  if (req.url === '/health' && req.method === 'GET') {
    return handleHealth(req, res);
  }
  
  if (req.url === '/api' && req.method === 'GET') {
    return await handleApi(req, res);
  }
  
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not Found');
});

server.listen(port, () => {
  console.log(`🚀 Servidor em execução na porta ${port}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Encerrando com elegância...');
  server.close(async () => {
    if (client) {
      await client.end().catch(() => {});
    }
    console.log('Servidor fechado');
    process.exit(0);
  });
});