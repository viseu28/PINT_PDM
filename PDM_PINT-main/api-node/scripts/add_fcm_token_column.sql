-- Script SQL para adicionar coluna fcm_token à tabela utilizador
-- Execute este script na sua base de dados PostgreSQL

-- Adicionar coluna fcm_token à tabela utilizador
ALTER TABLE utilizador 
ADD COLUMN fcm_token TEXT DEFAULT NULL;

-- Comentário da coluna para documentação
COMMENT ON COLUMN utilizador.fcm_token IS 'Token FCM para notificações push do Firebase';

-- Verificar se a coluna foi adicionada com sucesso
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'utilizador' AND column_name = 'fcm_token';

-- Query de exemplo para verificar a estrutura atualizada
-- SELECT idutilizador, nome, email, fcm_token FROM utilizador LIMIT 5;
