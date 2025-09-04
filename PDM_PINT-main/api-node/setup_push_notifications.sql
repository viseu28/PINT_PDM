-- Script SQL para adicionar suporte a notificações push
-- Execute este script na sua base de dados PostgreSQL

-- Adicionar coluna fcm_token na tabela utilizador (se não existir)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilizador' 
        AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE utilizador ADD COLUMN fcm_token TEXT;
        RAISE NOTICE 'Coluna fcm_token adicionada à tabela utilizador';
    ELSE
        RAISE NOTICE 'Coluna fcm_token já existe na tabela utilizador';
    END IF;
END $$;

-- Criar índice para melhorar performance das consultas por token (opcional)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'utilizador' 
        AND indexname = 'idx_utilizador_fcm_token'
    ) THEN
        CREATE INDEX idx_utilizador_fcm_token ON utilizador(fcm_token);
        RAISE NOTICE 'Índice idx_utilizador_fcm_token criado';
    ELSE
        RAISE NOTICE 'Índice idx_utilizador_fcm_token já existe';
    END IF;
END $$;

-- Verificar a estrutura atualizada
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'utilizador' 
AND column_name = 'fcm_token';
