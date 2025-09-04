-- Criar tabela para pedidos de tópicos
CREATE TABLE pedidos_topicos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    categoria_id INTEGER NULL,
    categoria_sugerida VARCHAR(255) NULL,
    area_id INTEGER NULL, 
    area_sugerida VARCHAR(255) NULL,
    topico_sugerido VARCHAR(255) NOT NULL,
    descricao TEXT NULL,
    estado VARCHAR(50) DEFAULT 'pendente', -- pendente, aceite, recusado
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_resposta TIMESTAMP NULL,
    admin_responsavel INTEGER NULL,
    observacoes TEXT NULL,
    
    -- Foreign keys baseadas na estrutura atual
    FOREIGN KEY (user_id) REFERENCES utilizador(idutilizador),
    FOREIGN KEY (categoria_id) REFERENCES categorias(idcategoria),
    FOREIGN KEY (area_id) REFERENCES areas(idarea),
    FOREIGN KEY (admin_responsavel) REFERENCES utilizador(idutilizador)
);

-- Índices para performance
CREATE INDEX idx_pedidos_topicos_user_id ON pedidos_topicos(user_id);
CREATE INDEX idx_pedidos_topicos_estado ON pedidos_topicos(estado);
CREATE INDEX idx_pedidos_topicos_data_pedido ON pedidos_topicos(data_pedido);

-- Comentários para documentação
COMMENT ON TABLE pedidos_topicos IS 'Tabela para armazenar pedidos de criação de novos tópicos no fórum';
COMMENT ON COLUMN pedidos_topicos.user_id IS 'ID do utilizador que fez o pedido';
COMMENT ON COLUMN pedidos_topicos.categoria_id IS 'ID da categoria existente (NULL se sugerir nova)';
COMMENT ON COLUMN pedidos_topicos.categoria_sugerida IS 'Nome da nova categoria sugerida';
COMMENT ON COLUMN pedidos_topicos.area_id IS 'ID da área existente (NULL se sugerir nova)';
COMMENT ON COLUMN pedidos_topicos.area_sugerida IS 'Nome da nova área sugerida';
COMMENT ON COLUMN pedidos_topicos.topico_sugerido IS 'Nome do tópico sugerido';
COMMENT ON COLUMN pedidos_topicos.estado IS 'Estado do pedido: pendente, aceite, recusado';
COMMENT ON COLUMN pedidos_topicos.admin_responsavel IS 'ID do admin que processou o pedido';
