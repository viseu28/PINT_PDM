-- Adicionar coluna topico_id à tabela pedidos_topicos
ALTER TABLE pedidos_topicos 
ADD COLUMN topico_id INTEGER NULL;

-- Adicionar foreign key para a tabela topicos
ALTER TABLE pedidos_topicos 
ADD CONSTRAINT fk_pedidos_topicos_topico_id 
FOREIGN KEY (topico_id) REFERENCES topicos(idtopicos);

-- Adicionar índice para performance
CREATE INDEX idx_pedidos_topicos_topico_id ON pedidos_topicos(topico_id);

-- Comentário para documentação
COMMENT ON COLUMN pedidos_topicos.topico_id IS 'ID do tópico existente selecionado (opcional, usado quando não é um tópico novo)';
