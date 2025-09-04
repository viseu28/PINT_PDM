-- Adicionar colunas para anexos e URLs na tabela resposta
ALTER TABLE resposta 
ADD COLUMN url TEXT,
ADD COLUMN anexo TEXT;

-- Comentário sobre as novas colunas:
-- url: Para armazenar URLs anexados às respostas
-- anexo: Para armazenar o caminho/nome do arquivo anexado
