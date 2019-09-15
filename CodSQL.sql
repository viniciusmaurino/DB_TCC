-- CRIAÇÃO DAS TABELAS

CREATE TABLE Usuario (
	id INT IDENTITY(100,1) PRIMARY KEY,
	nome VARCHAR(64) NOT NULL,
	email VARCHAR(64) NOT NULL,
	celular VARCHAR(15) NOT NULL
);

CREATE TABLE Fornecedor (
	cnpj VARCHAR(18) PRIMARY KEY,
	senha VARCHAR(12) NOT NULL,
	razaoSocial VARCHAR(256) NOT NULL,
	nomeFantasia VARCHAR(128) NOT NULL,
	endereco VARCHAR(128) NOT NULL,
	representanteComercial VARCHAR(64) NOT NULL,
	telefone VARCHAR(14) NOT NULL,
	email VARCHAR(64) NOT NULL,
	ativo BIT NOT NULL
);

CREATE TABLE Ingrediente (
	codigo INT IDENTITY(1000,1) PRIMARY KEY,
	descricao VARCHAR(100) NOT NULL,
	categoria VARCHAR(100) NOT NULL,
	valorCalorico INT NOT NULL,
	unidadeMedida VARCHAR(2) NOT NULL
);

CREATE TABLE Receita (
	codigo INT IDENTITY(100,1) PRIMARY KEY,
	descricao VARCHAR(100) NOT NULL, 
	categoria VARCHAR(45) NOT NULL,
	custoInfraestrutura DECIMAL(5,2) NOT NULL,
	modoPreparo TEXT NOT NULL,
	custoMaoObra DECIMAL(5,2) NOT NULL
);

CREATE TABLE Pedido (
	codigo INT IDENTITY(1,1) PRIMARY KEY,
	dataHora DATETIME NOT NULL
);

CREATE TABLE nivelAcesso (
	idUsuario INT PRIMARY KEY, 
	logon VARCHAR(45) NOT NULL,
	senha VARCHAR(12) NOT NULL,
	tipo VARCHAR(13) NOT NULL,

	CONSTRAINT chave_idUsuario FOREIGN KEY (idUsuario) REFERENCES Usuario(id)
);

CREATE UNIQUE INDEX ix_nivelAcesso ON nivelAcesso(logon);

CREATE TABLE FornecedorIngrediente (
	cnpjFornecedor VARCHAR(18),
	codigoIngrediente INT,
	fabricante VARCHAR(128) NOT NULL,
	valorUnitario DECIMAL(9,2) NOT NULL,
	quantidadeMedida INT NOT NULL,
	siglaMedida VARCHAR(2) NOT NULL,

	CONSTRAINT primariakey_FornecedorIngrediente PRIMARY KEY (cnpjFornecedor, codigoIngrediente),

	CONSTRAINT chave_cnpjFornecedor FOREIGN KEY (cnpjFornecedor) REFERENCES Fornecedor(cnpj),
	CONSTRAINT chave_codigoIngrediente3 FOREIGN KEY (codigoIngrediente) REFERENCES Ingrediente(codigo)
);

CREATE TABLE Lote (
	codigo INT IDENTITY(1,1) PRIMARY KEY,
	dataCompra DATE NOT NULL,
	dataValidade DATE NOT NULL,
	valorTotalLote DECIMAL(9,2) NOT NULL, 
	pesoPeca INT NOT NULL, 
	siglaMedida VARCHAR(2) NOT NULL,
	rendimentoPeca FLOAT NOT NULL,
	quantidadeComprada INT NOT NULL,
	codigoIngrediente INT NOT NULL,
	cnpjFornecedor VARCHAR(18) NOT NULL,

	CONSTRAINT chave_cnpjFornecedor2 FOREIGN KEY (cnpjFornecedor, codigoIngrediente) REFERENCES FornecedorIngrediente(cnpjFornecedor, codigoIngrediente)
);

CREATE TABLE Estoque (
	codigoOperacao INT IDENTITY(1,1) PRIMARY KEY,
	quantidade INT NOT NULL,
	siglaMedida VARCHAR(2) NOT NULL,
	codigoLote INT NOT NULL,

	CONSTRAINT chave_codigoLote FOREIGN KEY (codigoLote) REFERENCES Lote(codigo)
);

CREATE TABLE Produto (
	codigo INT IDENTITY(10000,1) PRIMARY KEY,
	nome VARCHAR(100) NOT NULL,
	descricao TEXT NULL,
	margemLucro DECIMAL(6,2) NOT NULL,
	codigoReceita INT NULL,
	codigoIngrediente INT NULL,

	CONSTRAINT chave_codigoReceita FOREIGN KEY (codigoReceita) REFERENCES Receita(codigo),
	CONSTRAINT chave_codigoIngrediente2 FOREIGN KEY (codigoIngrediente) REFERENCES Ingrediente(codigo)
);

CREATE TABLE ItensPedido (
	codigoPedido INT, 
	codigoProduto INT,
	quantidadeProduto INT NOT NULL,

	CONSTRAINT primariakey_ItensPedido PRIMARY KEY (codigoPedido, codigoProduto),

	CONSTRAINT chave_codigoPedido FOREIGN KEY (codigoPedido) REFERENCES Pedido(codigo),
	CONSTRAINT chave_codigoProduto FOREIGN KEY (codigoProduto) REFERENCES Produto(codigo)
);

CREATE TABLE FichaTecnica (
	codigoReceita INT,
	codigoIngrediente INT,
	porcaoIngrediente INT NOT NULL,
	siglaMedida VARCHAR(2) NOT NULL,
	valorCaloricoIngrediente INT NOT NULL,
	custoPorcaoIngrediente DECIMAL(5,2) NOT NULL,

	CONSTRAINT primariakey_FichaTecnica PRIMARY KEY (codigoReceita, codigoIngrediente),

	CONSTRAINT chave_codigoReceita2 FOREIGN KEY (codigoReceita) REFERENCES Receita(codigo),
	CONSTRAINT chave_codigoIngrediente4 FOREIGN KEY (codigoIngrediente) REFERENCES Ingrediente(codigo)
);

-- Códigos SQL

-- Função que criará um login para o Usuário que foi cadastrado, seguindo o padrão: primeiroNome.ultimoNome

CREATE FUNCTION criaUsuario(@nomeCompleto VARCHAR(64)) RETURNS VARCHAR(45)
BEGIN
	DECLARE @primeiroNome VARCHAR(32);
	DECLARE @ultimoNome VARCHAR(32);
	DECLARE @indicePrimeiroEspaco INT;
	DECLARE @indiceUltimoEspaco INT;
	DECLARE @nomeUsuario VARCHAR(64);
	DECLARE @sequencialNomeUsuario INT;
	DECLARE @nomeUsuarioFinal VARCHAR(45);
	DECLARE @semAcento VARCHAR(45);

	SET @indicePrimeiroEspaco = CHARINDEX(' ', @nomeCompleto) - 1;
	SET @indiceUltimoEspaco = CHARINDEX(' ', REVERSE(@nomeCompleto)) - 1;
	SET @primeiroNome = (SELECT SUBSTRING(@nomeCompleto, 1, @indicePrimeiroEspaco));
	SET @ultimoNome = (SELECT SUBSTRING(REVERSE(@nomeCompleto), 1, @indiceUltimoEspaco));
	SET @nomeUsuario = LOWER(CONCAT(@primeiroNome, '.', REVERSE(@ultimoNome)));
	SET @nomeUsuario = dbo.tiraAcentos(@nomeUsuario);
	SET @sequencialNomeUsuario = 2;
	SET @nomeUsuarioFinal = @nomeUsuario; 

	WHILE (SELECT COUNT(idUsuario) FROM nivelAcesso WHERE logon = @nomeUsuarioFinal) > 0
	BEGIN
		SET @nomeUsuarioFinal = CONCAT(@nomeUsuario, @sequencialNomeUsuario);
		SET @sequencialNomeUsuario += 1;
	END;

	RETURN @nomeUsuarioFinal;
END

-- Função que tratará o login que foi criado para o Usuário, para deixá-lo sem caracteres especiais

CREATE FUNCTION tiraAcentos (@usuario VARCHAR(45)) RETURNS VARCHAR(45)

BEGIN
DECLARE @semAcento VARCHAR(45);
DECLARE @usuarioTratar VARCHAR(45);

SET @usuarioTratar = @usuario

	SET @semAcento = replace(@usuarioTratar,'á','a')   
    SET @semAcento = replace(@semAcento,'à','a')   
    SET @semAcento = replace(@semAcento,'ã','a')   
    SET @semAcento = replace(@semAcento,'â','a')   
    SET @semAcento = replace(@semAcento,'é','e')   
    SET @semAcento = replace(@semAcento,'è','e')   
    SET @semAcento = replace(@semAcento,'ê','e')   
    SET @semAcento = replace(@semAcento,'í','i')   
    SET @semAcento = replace(@semAcento,'ì','i')   
    SET @semAcento = replace(@semAcento,'î','i')   
    SET @semAcento = replace(@semAcento,'ó','o')   
    SET @semAcento = replace(@semAcento,'ò','o')   
    SET @semAcento = replace(@semAcento,'ô','o')   
    SET @semAcento = replace(@semAcento,'õ','o')   
    SET @semAcento = replace(@semAcento,'ú','u')   
    SET @semAcento = replace(@semAcento,'ù','u')   
    SET @semAcento = replace(@semAcento,'û','u')   
    SET @semAcento = replace(@semAcento,'ü','u')   
    SET @semAcento = replace(@semAcento,'ç','c')

	RETURN (@semAcento);
END

-- Trigger que fará um INSERT automático na tabela "nivelAcesso", logo após um Usuário ter sido cadastrado no sistema, gerando seu login, senha e tipo de acesso, sendo que estes dois últimos poderão ser alterados posteriormente. 

CREATE TRIGGER criaAcesso ON Usuario AFTER INSERT AS
	DECLARE @id INT, @nome VARCHAR(64)
BEGIN
	SELECT @id = id FROM INSERTED
	SELECT @nome = nome FROM INSERTED

	IF @id = 100
		BEGIN
			INSERT INTO nivelAcesso VALUES (@id, dbo.tiraAcentos(dbo.criaUsuario(@nome)), '4dm1n1str4d0r', 'ADMINISTRADOR')
		END
	ELSE
		BEGIN
			INSERT INTO nivelAcesso VALUES (@id, dbo.tiraAcentos(dbo.criaUsuario(@nome)), '123mudar', 'OPERADOR')
		END
		
END

-- Trigger que fará um INSERT automático na tabela "Estoque" logo após um Lote ter sido cadastrado no sistema.

CREATE TRIGGER lancaEstoque ON Lote AFTER INSERT AS
	DECLARE @siglaMedida VARCHAR(2), @codigoLote INT, @quantidadeComprada INT, @rendimento FLOAT, @peso INT, @quantidadeEstoque INT
BEGIN
	SELECT @siglaMedida = siglaMedida FROM INSERTED
	SELECT @codigoLote = codigo FROM INSERTED
	SELECT @rendimento = rendimentoPeca FROM INSERTED
	SELECT @quantidadeComprada = quantidadeComprada FROM INSERTED
	SELECT @peso = pesoPeca FROM INSERTED
	SELECT @quantidadeEstoque = @quantidadeComprada * (@peso * (@rendimento/100))

	INSERT INTO Estoque VALUES (@quantidadeEstoque, @siglaMedida, @codigoLote)
END

-- View que mostrará a quantidade total em estoque de cada ingrediente

CREATE VIEW mostraQuantidadeTotalEstoque AS

SELECT FI.codigoIngrediente AS CódigoIngrediente, I.descricao AS Ingrediente, F.nomeFantasia AS Fornecedor, (L.pesoPeca * (L.rendimentoPeca/100)) AS pesoRendimento, SUM(E.quantidade) AS quantidadeEstoque 
FROM FornecedorIngrediente FI
JOIN Ingrediente I ON FI.codigoIngrediente = I.codigo
JOIN Fornecedor F ON FI.cnpjFornecedor = F.cnpj
JOIN Lote L ON FI.codigoIngrediente = L.codigoIngrediente
JOIN Estoque E ON L.codigo = E.codigoLote
GROUP BY FI.codigoIngrediente, I.descricao, F.nomeFantasia, L.pesoPeca, L.rendimentoPeca;

-- Trigger que calculará automaticamente o valor calórico e o custo de um ingrediente inserido na tabela "FichaTecnica", de acordo com a porção em gramas em sua respectiva receita

CREATE TRIGGER calculaCaloriaECusto ON FichaTecnica INSTEAD OF INSERT AS
	DECLARE @receita INT, @ingrediente INT, @porcaoIngrediente INT, @valorCaloricoPorcao DECIMAL(6,2), @custoPorcao DECIMAL(5,2), @valorCaloricoOriginal INT, @custoFornecedor DECIMAL(9,2), @qtdComprada INT, @pesoUnitario INT
BEGIN
	SELECT @receita = codigoReceita FROM INSERTED
	SELECT @ingrediente = codigoIngrediente FROM INSERTED
	SELECT @porcaoIngrediente = porcaoIngrediente FROM INSERTED
	SELECT @valorCaloricoOriginal = I.valorCalorico FROM Ingrediente I WHERE I.codigo = @ingrediente
	SELECT @custoFornecedor = L.valorTotalLote FROM Lote L WHERE L.codigoIngrediente = @ingrediente
	SELECT @qtdComprada = L.quantidadeComprada FROM Lote L WHERE L.codigoIngrediente = @ingrediente
	SELECT @pesoUnitario  = L.pesoPeca FROM Lote L WHERE L.codigoIngrediente = @ingrediente

	SET @valorCaloricoPorcao = (@porcaoIngrediente * @valorCaloricoOriginal) / 100
	SET @custoPorcao = (@custoFornecedor / (@qtdComprada * @pesoUnitario)) * @porcaoIngrediente

	INSERT INTO FichaTecnica VALUES (@receita, @ingrediente, @porcaoIngrediente, 'g', @valorCaloricoPorcao, @custoPorcao)
END

-- Trigger que irá atualizar automaticamente os dados do valor calórico e do custo de um ingrediente que teve o valor da sua porção em gramas alterado

CREATE TRIGGER atualizaCaloriaECusto ON FichaTecnica AFTER UPDATE AS
	DECLARE @receita INT, @ingrediente INT, @porcaoIngrediente INT, @valorCaloricoPorcao DECIMAL(6,2), @custoPorcao DECIMAL(5,2), @valorCaloricoOriginal INT, @custoFornecedor DECIMAL(9,2), @qtdComprada INT, @pesoUnitario INT
BEGIN
	SELECT @receita = codigoReceita FROM INSERTED
	SELECT @ingrediente = codigoIngrediente FROM INSERTED
	SELECT @porcaoIngrediente = porcaoIngrediente FROM INSERTED
	SELECT @valorCaloricoOriginal = I.valorCalorico FROM Ingrediente I WHERE I.codigo = @ingrediente
	SELECT @custoFornecedor = L.valorTotalLote FROM Lote L WHERE L.codigoIngrediente = @ingrediente
	SELECT @qtdComprada = L.quantidadeComprada FROM Lote L WHERE L.codigoIngrediente = @ingrediente
	SELECT @pesoUnitario  = L.pesoPeca FROM Lote L WHERE L.codigoIngrediente = @ingrediente

	SET @valorCaloricoPorcao = (@porcaoIngrediente * @valorCaloricoOriginal) / 100
	SET @custoPorcao = (@custoFornecedor / (@qtdComprada * @pesoUnitario)) * @porcaoIngrediente

	UPDATE FichaTecnica SET valorCaloricoIngrediente = @valorCaloricoPorcao, custoPorcaoIngrediente = @custoPorcao WHERE codigoReceita = @receita AND codigoIngrediente = @ingrediente
END

-- Trigger que calculará automaticamente o custo total de um lote de ingrediente que foi comprado de um determinado fornecedor

CREATE TRIGGER atualizaCustoLote ON Lote AFTER INSERT AS
	DECLARE @codigo INT, @valorTotalLote DECIMAL(9,2), @ingrediente INT, @fornecedor VARCHAR(18), @qtdComprada INT, @valorUnitarioIngrediente DECIMAL(9,2)
	BEGIN
		SELECT @codigo = codigo FROM INSERTED
		SELECT @ingrediente = codigoIngrediente FROM INSERTED
		SELECT @fornecedor = cnpjFornecedor FROM INSERTED
		SELECT @qtdComprada = quantidadeComprada FROM INSERTED
		SELECT @valorUnitarioIngrediente = FI.valorUnitario FROM FornecedorIngrediente FI WHERE FI.codigoIngrediente = @ingrediente AND FI.cnpjFornecedor = @fornecedor
		
		SET @valorTotalLote = @qtdComprada * @valorUnitarioIngrediente

		UPDATE Lote SET valorTotalLote = @valorTotalLote WHERE codigo = @codigo
	END

-- Trigger que colocará no campo "nome" da tabela "Produto" exatamente a mesma descrição inserida para um ingrediente ou receita em suas respectivas tabelas

CREATE TRIGGER copiaDescricao ON Produto INSTEAD OF INSERT AS
	DECLARE @nome VARCHAR(100), @margemLucro DECIMAL(6,2), @descricaoProduto VARCHAR(100), @descricaoIng VARCHAR(100), @descricaoRec VARCHAR(100), @codIngrediente INT, @codReceita INT, @codProduto INT

	BEGIN
		SELECT @codProduto = codigo FROM INSERTED
		SELECT @codIngrediente = codigoIngrediente FROM INSERTED
		SELECT @codReceita = codigoReceita FROM INSERTED
		SELECT @margemLucro = margemLucro FROM INSERTED
		SELECT @descricaoProduto = descricao FROM INSERTED
		SELECT @descricaoIng = I.descricao FROM Ingrediente I WHERE I.codigo = @codIngrediente
		SELECT @descricaoRec = R.descricao FROM Receita R WHERE R.codigo = @codReceita

		IF @codReceita IS NOT NULL
		BEGIN
			SET @nome = @descricaoRec
		END
		ELSE
		BEGIN
			SET @nome = @descricaoIng
		END

		INSERT INTO Produto VALUES (@nome, @descricaoProduto, @margemLucro, @codReceita, @codIngrediente);

	END

-- CRIAÇÃO DO USUÁRIO MASTER

INSERT INTO Usuario VALUES ('Admin Master', 'usermaster@database', '(00) 00000-0000');

-- INSERT DOS INGREDIENTES

INSERT INTO Ingrediente VALUES ('Arroz, integral', 'CEREAIS E DERIVADOS', 124, 'Kg'), ('Arroz, tipo 1', 'CEREAIS E DERIVADOS', 128, 'Kg'), ('Aveia, flocos', 'CEREAIS E DERIVADOS', 394, 'Kg'), ('Biscoito, doce, maisena', 'CEREAIS E DERIVADOS', 443, 'Kg'), ('Farinha, de centeio, integral', 'CEREAIS E DERIVADOS', 336, 'Kg'), ('Farinha, de milho, amarela', 'CEREAIS E DERIVADOS', 351, 'Kg'), ('Farinha, de rosca', 'CEREAIS E DERIVADOS', 371, 'Kg'), ('Farinha, de trigo', 'CEREAIS E DERIVADOS', 360, 'Kg'), ('Farinha, láctea, de cereais', 'CEREAIS E DERIVADOS', 415, 'Kg'), ('Lasanha, massa fresca', 'CEREAIS E DERIVADOS', 164, 'Kg'), ('Macarrão, instantâneo', 'CEREAIS E DERIVADOS', 436, 'Kg'), ('Macarrão, trigo', 'CEREAIS E DERIVADOS', 371, 'Kg'), ('Macarrão, trigo, com ovos', 'CEREAIS E DERIVADOS', 371, 'Kg'), ('Milho, verde, enlatado, drenado', 'CEREAIS E DERIVADOS', 98, 'Kg'), ('Mingau tradicional, pó', 'CEREAIS E DERIVADOS', 373, 'Kg'), ('Pão, aveia, forma', 'CEREAIS E DERIVADOS', 343, 'Kg'), ('Pão, de soja', 'CEREAIS E DERIVADOS', 309, 'Kg'), ('Pão, glúten, forma', 'CEREAIS E DERIVADOS', 253, 'Kg'), ('Pão, milho, forma', 'CEREAIS E DERIVADOS', 292, 'Kg'), ('Pão, trigo, forma, integral', 'CEREAIS E DERIVADOS', 253, 'Kg'), ('Pão, trigo, francês', 'CEREAIS E DERIVADOS', 300, 'Kg'), ('Pão, trigo, sovado', 'CEREAIS E DERIVADOS', 311, 'Kg'), ('Polenta, pré-cozida', 'CEREAIS E DERIVADOS', 103, 'Kg'), ('Torrada, pão francês', 'CEREAIS E DERIVADOS', 377, 'Kg'), ('Abóbora, cabotian', 'VERDURAS, HORTALIÇAS E DERIVADOS', 48, 'Kg'), ('Abobrinha, italiana', 'VERDURAS, HORTALIÇAS E DERIVADOS', 24, 'Kg'), ('Abobrinha, paulista', 'VERDURAS, HORTALIÇAS E DERIVADOS', 31, 'Kg'), ('Acelga', 'VERDURAS, HORTALIÇAS E DERIVADOS', 21, 'Kg'), ('Agrião', 'VERDURAS, HORTALIÇAS E DERIVADOS', 17, 'Kg'), ('Aipo', 'VERDURAS, HORTALIÇAS E DERIVADOS', 19, 'Kg'), ('Alface, americana', 'VERDURAS, HORTALIÇAS E DERIVADOS', 9, 'Kg'), ('Alface, crespa', 'VERDURAS, HORTALIÇAS E DERIVADOS', 11, 'Kg'), ('Alface, lisa', 'VERDURAS, HORTALIÇAS E DERIVADOS', 14, 'Kg'), ('Alface, roxa', 'VERDURAS, HORTALIÇAS E DERIVADOS', 13, 'Kg'), ('Alho', 'VERDURAS, HORTALIÇAS E DERIVADOS', 113, 'Kg'), ('Alho-poró', 'VERDURAS, HORTALIÇAS E DERIVADOS', 32, 'Kg'), ('Almeirão', 'VERDURAS, HORTALIÇAS E DERIVADOS', 65, 'Kg'), ('Batata, doce', 'VERDURAS, HORTALIÇAS E DERIVADOS', 77, 'Kg'), ('Batata, inglesa', 'VERDURAS, HORTALIÇAS E DERIVADOS', 52, 'Kg'), ('Berinjela', 'VERDURAS, HORTALIÇAS E DERIVADOS', 19, 'Kg'), ('Beterraba', 'VERDURAS, HORTALIÇAS E DERIVADOS', 32, 'Kg'), ('Brócolis', 'VERDURAS, HORTALIÇAS E DERIVADOS', 25, 'Kg'), ('Cebola', 'VERDURAS, HORTALIÇAS E DERIVADOS', 39, 'Kg'), ('Cebolinha', 'VERDURAS, HORTALIÇAS E DERIVADOS', 20, 'Kg'), ('Cenoura', 'VERDURAS, HORTALIÇAS E DERIVADOS', 30, 'Kg'), ('Chicória', 'VERDURAS, HORTALIÇAS E DERIVADOS', 14, 'Kg'), ('Chuchu', 'VERDURAS, HORTALIÇAS E DERIVADOS', 19, 'Kg'), ('Coentro, folhas desidratadas', 'VERDURAS, HORTALIÇAS E DERIVADOS', 309, 'Kg'), ('Couve, manteiga', 'VERDURAS, HORTALIÇAS E DERIVADOS', 90, 'Kg'), ('Couve-flor', 'VERDURAS, HORTALIÇAS E DERIVADOS', 19, 'Kg'), ('Espinafre', 'VERDURAS, HORTALIÇAS E DERIVADOS', 67, 'Kg'), ('Farinha, de mandioca, torrada', 'VERDURAS, HORTALIÇAS E DERIVADOS', 365, 'Kg'), ('Fécula, de mandioca', 'VERDURAS, HORTALIÇAS E DERIVADOS', 331, 'Kg'), ('Mandioca', 'VERDURAS, HORTALIÇAS E DERIVADOS', 125, 'Kg'), ('Manjericão', 'VERDURAS, HORTALIÇAS E DERIVADOS', 21, 'g'), ('Mostarda, folha', 'VERDURAS, HORTALIÇAS E DERIVADOS', 18, 'g'), ('Nhoque', 'VERDURAS, HORTALIÇAS E DERIVADOS', 181, 'Kg'), ('Nabo', 'VERDURAS, HORTALIÇAS E DERIVADOS', 18, 'Kg'), ('Palmito, juçara, em conserva', 'VERDURAS, HORTALIÇAS E DERIVADOS', 23, 'Kg'), ('Pepino', 'VERDURAS, HORTALIÇAS E DERIVADOS', 10, 'Kg'), ('Pimentão, amarelo', 'VERDURAS, HORTALIÇAS E DERIVADOS', 28, 'Kg'), ('Pimentão, verde', 'VERDURAS, HORTALIÇAS E DERIVADOS', 21, 'Kg'), ('Pimentão, vermelho', 'VERDURAS, HORTALIÇAS E DERIVADOS', 23, 'Kg'), ('Polvilho, doce', 'VERDURAS, HORTALIÇAS E DERIVADOS', 351, 'Kg'), ('Quiabo', 'VERDURAS, HORTALIÇAS E DERIVADOS', 30, 'Kg'), ('Rabanete', 'VERDURAS, HORTALIÇAS E DERIVADOS', 14, 'Kg'), ('Repolho, branco', 'VERDURAS, HORTALIÇAS E DERIVADOS', 17, 'Kg'), ('Repolho, roxo', 'VERDURAS, HORTALIÇAS E DERIVADOS', 42, 'Kg'), ('Rúcula', 'VERDURAS, HORTALIÇAS E DERIVADOS', 13, 'Kg'), ('Salsa', 'VERDURAS, HORTALIÇAS E DERIVADOS', 33, 'Kg'), ('Tomate, com semente', 'VERDURAS, HORTALIÇAS E DERIVADOS', 15, 'Kg'), ('Tomate, extrato', 'VERDURAS, HORTALIÇAS E DERIVADOS', 61, 'Kg'), ('Tomate, molho industrializado', 'VERDURAS, HORTALIÇAS E DERIVADOS', 38, 'Kg'), ('Vagem', 'VERDURAS, HORTALIÇAS E DERIVADOS', 25, 'Kg'), ('Abacate', 'FRUTAS E DERIVADOS', 96, 'Kg'), ('Abacaxi', 'FRUTAS E DERIVADOS', 48, 'Kg'), ('Açaí, polpa, congelada', 'FRUTAS E DERIVADOS', 58, 'Kg'), ('Ameixa, calda, enlatada', 'FRUTAS E DERIVADOS', 183, 'Kg'), ('Banana, maçã', 'FRUTAS E DERIVADOS', 87, 'Kg'), ('Banana, nanica', 'FRUTAS E DERIVADOS', 92, 'Kg'), ('Banana, prata', 'FRUTAS E DERIVADOS', 98, 'Kg'), ('Caju, polpa, congelada', 'FRUTAS E DERIVADOS', 37, 'Kg'), ('Caju, suco concentrado, envasado', 'FRUTAS E DERIVADOS', 45, 'ml'), ('Carambola', 'FRUTAS E DERIVADOS', 46, 'Kg'), ('Figo', 'FRUTAS E DERIVADOS', 41, 'Kg'), ('Figo, enlatado, em calda', 'FRUTAS E DERIVADOS', 184, 'Kg'), ('Goiaba, branca, com casca', 'FRUTAS E DERIVADOS', 52, 'Kg'), ('Goiaba, vermelha, com casca', 'FRUTAS E DERIVADOS', 54, 'Kg'), ('Jabuticaba', 'FRUTAS E DERIVADOS', 58, 'Kg'), ('Jaca', 'FRUTAS E DERIVADOS', 88, 'Kg'), ('Kiwi', 'FRUTAS E DERIVADOS', 51, 'Kg'), ('Laranja, lima, suco', 'FRUTAS E DERIVADOS', 39, 'ml'), ('Limão, galego, suco', 'FRUTAS E DERIVADOS', 22, 'ml'), ('Maçã, Fuji, com casca', 'FRUTAS E DERIVADOS', 56, 'Kg'), ('Mamão, Formosa', 'FRUTAS E DERIVADOS', 45, 'Kg'), ('Manga, polpa, congelada', 'FRUTAS E DERIVADOS', 48, 'Kg'), ('Maracujá, polpa, congelada', 'FRUTAS E DERIVADOS', 39, 'Kg'), ('Maracujá, suco concentrado, envasado', 'FRUTAS E DERIVADOS', 42, 'ml'), ('Melancia', 'FRUTAS E DERIVADOS', 33, 'Kg'), ('Melão', 'FRUTAS E DERIVADOS', 29, 'Kg'), ('Morango', 'FRUTAS E DERIVADOS', 30, 'Kg'), ('Pêra, Williams', 'FRUTAS E DERIVADOS', 53, 'Kg'), ('Pêssego, Aurora', 'FRUTAS E DERIVADOS', 36, 'Kg'), ('Pêssego, enlatado, em calda', 'FRUTAS E DERIVADOS', 63, 'Kg'), ('Uva, Itália', 'FRUTAS E DERIVADOS', 53, 'Kg'), ('Uva, suco concentrado, envasado', 'FRUTAS E DERIVADOS', 58, 'ml'), ('Azeite, de oliva, extra virgem', 'GORDURAS E ÓLEOS', 884, 'L'), ('Manteiga, com sal', 'GORDURAS E ÓLEOS', 726, 'Kg'), ('Margarina, com sal', 'GORDURAS E ÓLEOS', 596, 'Kg'), ('Óleo, de soja', 'GORDURAS E ÓLEOS', 884, 'L'), ('Atum, conserva em óleo', 'PESCADOS E FRUTOS DO MAR', 166, 'Kg'), ('Bacalhau, salgado', 'PESCADOS E FRUTOS DO MAR', 136, 'Kg'), ('Camarão, Sete Barbas, sem cabeça, com casca', 'PESCADOS E FRUTOS DO MAR', 231, 'Kg'), ('Caranguejo', 'PESCADOS E FRUTOS DO MAR', 83, 'Kg'), ('Lambari, congelado', 'PESCADOS E FRUTOS DO MAR', 327, 'Kg'), ('Salmão, sem pele, fresco', 'PESCADOS E FRUTOS DO MAR', 243, 'Kg'), ('Sardinha', 'PESCADOS E FRUTOS DO MAR', 257, 'Kg'), ('Apresuntado', 'CARNES E DERIVADOS', 129, 'Kg'), ('Caldo de carne, tablete', 'CARNES E DERIVADOS', 241, 'g'), ('Caldo de galinha, tablete', 'CARNES E DERIVADOS', 251, 'g'), ('Carne, bovina, acém, sem gordura', 'CARNES E DERIVADOS', 215, 'Kg'), ('Carne, bovina, almôndegas', 'CARNES E DERIVADOS', 272, 'Kg'), ('Carne, bovina, bucho', 'CARNES E DERIVADOS', 133, 'Kg'), ('Carne, bovina, capa de contra-filé, sem gordura', 'CARNES E DERIVADOS', 239, 'Kg'), ('Carne, bovina, contra-filé, sem gordura', 'CARNES E DERIVADOS', 194, 'Kg'), ('Carne, bovina, costela', 'CARNES E DERIVADOS', 373, 'Kg'), ('Carne, bovina, coxão duro, sem gordura', 'CARNES E DERIVADOS', 217, 'Kg'), ('Carne, bovina, coxão mole, sem gordura', 'CARNES E DERIVADOS', 219, 'Kg'), ('Carne, bovina, cupim', 'CARNES E DERIVADOS', 330, 'Kg'), ('Carne, bovina, filé mingnon, sem gordura', 'CARNES E DERIVADOS', 220, 'Kg'), ('Carne, bovina, fraldinha, com gordura', 'CARNES E DERIVADOS', 338, 'Kg'), ('Carne, bovina, maminha', 'CARNES E DERIVADOS', 153, 'Kg'), ('Carne, bovina, miolo de alcatra, sem gordura', 'CARNES E DERIVADOS', 241, 'Kg'), ('Carne, bovina, músculo, sem gordura', 'CARNES E DERIVADOS', 194, 'Kg'), ('Carne, bovina, patinho, sem gordura', 'CARNES E DERIVADOS', 219, 'Kg'), ('Carne, bovina, picanha, sem gordura', 'CARNES E DERIVADOS', 238, 'Kg'), ('Carne, bovina, seca', 'CARNES E DERIVADOS', 313, 'Kg'), ('Coxinha de frango', 'CARNES E DERIVADOS', 283, 'Kg'), ('Croquete, de carne', 'CARNES E DERIVADOS', 347, 'Kg'), ('Frango, caipira, inteiro, com pele', 'CARNES E DERIVADOS', 243, 'Kg'), ('Frango, caipira, inteiro, sem pele', 'CARNES E DERIVADOS', 196, 'Kg'), ('Frango, coração', 'CARNES E DERIVADOS', 207, 'Kg'), ('Frango, coxa, sem pele', 'CARNES E DERIVADOS', 167, 'Kg'), ('Frango, filé', 'CARNES E DERIVADOS', 221, 'Kg'), ('Frango, inteiro, sem pele', 'CARNES E DERIVADOS', 187, 'Kg'), ('Frango, peito, com pele', 'CARNES E DERIVADOS', 212, 'Kg'), ('Frango, peito, sem pele', 'CARNES E DERIVADOS', 159, 'Kg'), ('Frango, sobrecoxa, com pele', 'CARNES E DERIVADOS', 260, 'Kg'), ('Hambúrguer, bovino', 'CARNES E DERIVADOS', 210, 'Kg'), ('Linguiça, porco', 'CARNES E DERIVADOS', 296, 'Kg'), ('Mortadela', 'CARNES E DERIVADOS', 269, 'Kg'), ('Peru, inteiro', 'CARNES E DERIVADOS', 163, 'Kg'), ('Porco, bisteca', 'CARNES E DERIVADOS', 311, 'Kg'), ('Porco, costela', 'CARNES E DERIVADOS', 402, 'Kg'), ('Porco, lombo', 'CARNES E DERIVADOS', 210, 'Kg'), ('Porco, pernil', 'CARNES E DERIVADOS', 262, 'Kg'), ('Presunto, sem capa de gordura', 'CARNES E DERIVADOS', 94, 'Kg'), ('Quibe', 'CARNES E DERIVADOS', 254, 'Kg'), ('Salame', 'CARNES E DERIVADOS', 398, 'Kg'), ('Toucinho', 'CARNES E DERIVADOS', 697, 'Kg'), ('Creme de Leite', 'LEITE E DERIVADOS', 221, 'Kg'), ('Iogurte, natural', 'LEITE E DERIVADOS', 51, 'Kg'), ('Leite, condensado', 'LEITE E DERIVADOS', 313, 'Kg'), ('Leite, de vaca, desnatado, pó', 'LEITE E DERIVADOS', 362, 'Kg'), ('Leite, de vaca, desnatado, UHT', 'LEITE E DERIVADOS', 0, 'L'), ('Leite, de vaca, integral, pó', 'LEITE E DERIVADOS', 497, 'Kg'), ('Queijo, minas, frescal', 'LEITE E DERIVADOS', 264, 'Kg'), ('Queijo, mozarela', 'LEITE E DERIVADOS', 330, 'Kg'), ('Queijo, prato', 'LEITE E DERIVADOS', 360, 'Kg'), ('Queijo, ricota', 'LEITE E DERIVADOS', 140, 'Kg'), ('Pão, de queijo', 'LEITE E DERIVADOS', 363, 'Kg'), ('Coco, água de', 'BEBIDAS', 22, 'ml'), ('Refrigerante, tipo água tônica', 'BEBIDAS', 31, 'ml'), ('Refrigerante, tipo cola', 'BEBIDAS', 34, 'ml'), ('Refrigerante, tipo guaraná', 'BEBIDAS', 39, 'ml'), ('Refrigerante, tipo limão', 'BEBIDAS', 40, 'ml'), ('Água, mineral', 'BEBIDAS', 0, 'ml'), ('Ovo, de codorna, inteiro', 'OVOS E DERIVADOS', 177, 'un'), ('Ovo, de galinha, inteiro', 'OVOS E DERIVADOS', 240, 'un'), ('Achocolatado, pó', 'PRODUTOS AÇUCARADOS', 401, 'Kg'), ('Açúcar, cristal', 'PRODUTOS AÇUCARADOS', 387, 'Kg'), ('Açúcar, mascavo', 'PRODUTOS AÇUCARADOS', 369, 'Kg'), ('Açúcar, refinado', 'PRODUTOS AÇUCARADOS', 387, 'Kg'), ('Chocolate, ao leite', 'PRODUTOS AÇUCARADOS', 540, 'Kg'), ('Chocolate, meio amargo', 'PRODUTOS AÇUCARADOS', 475, 'Kg'), ('Doce, de leite, cremoso', 'PRODUTOS AÇUCARADOS', 306, 'Kg'), ('Mel, de abelha', 'PRODUTOS AÇUCARADOS', 309, 'Kg'), ('Melado', 'PRODUTOS AÇUCARADOS', 297, 'Kg'), ('Quindim', 'PRODUTOS AÇUCARADOS', 411, 'un'), ('Fermento em pó, químico', 'MISCELÂNEAS', 90, 'Kg'), ('Fermento, biológico, levedura, tablete', 'MISCELÂNEAS', 90, 'Kg'), ('Gelatina, sabores variados, pó', 'MISCELÂNEAS', 380, 'Kg'), ('Sal, dietético', 'MISCELÂNEAS', 0, 'Kg'), ('Sal, grosso', 'MISCELÂNEAS', 0, 'Kg'), ('Azeitona, preta, conserva', 'OUTROS - INDUSTRIALIZADOS', 194, 'Kg'), ('Azeitona, verde, conserva', 'OUTROS - INDUSTRIALIZADOS', 137, 'Kg'), ('Chantilly, spray, com gordura vegetal', 'OUTROS - INDUSTRIALIZADOS', 315, 'Kg'), ('Batata, frita, tipo chips, industrializada', 'OUTROS - INDUSTRIALIZADOS', 543, 'Kg'), ('Amendoim, torrado, salgado', 'LEGUMINOSAS E DERIVADOS', 606, 'Kg'), ('Ervilha, enlatada, drenada', 'LEGUMINOSAS E DERIVADOS', 74, 'Kg'), ('Feijão, carioca', 'LEGUMINOSAS E DERIVADOS', 76, 'Kg'), ('Feijão, preto', 'LEGUMINOSAS E DERIVADOS', 77, 'Kg'), ('Grão-de-bico', 'LEGUMINOSAS E DERIVADOS', 355, 'Kg'), ('Lentilha', 'LEGUMINOSAS E DERIVADOS', 93, 'Kg'), ('Paçoca, amendoim', 'LEGUMINOSAS E DERIVADOS', 487, 'un'), ('Pé-de-moleque, amendoim', 'LEGUMINOSAS E DERIVADOS', 503, 'un'), ('Soja, farinha', 'LEGUMINOSAS E DERIVADOS', 404, 'Kg'), ('Amêndoa, torrada, salgada', 'NOZES E SEMENTES', 581, 'Kg'), ('Castanha-de-caju, torrada, salgada', 'NOZES E SEMENTES', 570, 'Kg'), ('Gergelim, semente', 'NOZES E SEMENTES', 584, 'Kg'), ('Linhaça, semente', 'NOZES E SEMENTES', 495, 'Kg'), ('Pinhão', 'NOZES E SEMENTES', 174, 'Kg'), ('Noz', 'NOZES E SEMENTES', 620, 'Kg');
