CREATE VIEW dCliente AS
SELECT 
	cl.id AS cliente_id,
	cl.descricao AS nome_cliente,
	cl.geografia_id,
	ge.cidade,
	ge.estado,
	ge.uf,
	rb.Regiao AS regiao
FROM Cliente cl
JOIN Geografia ge
	ON cl.geografia_id = ge.id
JOIN RegioesBrasil rb
	ON ge.uf = rb.UF


CREATE VIEW dProduto AS
SELECT 
	pr.id AS produto_id,
	pr.descricao AS nome_produto,
	pr.tamanho,
	pr.custoUnitario AS custo_unitario,
	pr.categoria_id,
	cp.descricao AS nome_categoria,
	fp.URL AS foto_produto
FROM Produto pr
JOIN CategoriaProduto cp
	ON pr.categoria_id = cp.id
JOIN FotosProdutos fp
	ON pr.descricao = fp.produto


CREATE VIEW dVendedor AS
SELECT 
	ve.id AS vendedor_id,
	ve.descricao AS nome_vendedor,
	ve.supervisor_id,
	sp.descricao AS nome_supervisor,
	sp.gerente_id,
	sp.gerente_descricao AS nome_gerente,
	fv.URL AS foto_vendedor
FROM Vendedor ve
JOIN Supervisor sp
	ON ve.supervisor_id = sp.id
JOIN FotoVendedor fv
	ON ve.id = fv.id_vendedor


CREATE VIEW fVendas AS
WITH rateio_descontos AS(

SELECT 
	ve.nfe,
	ve.data,
	ve.cliente_id,
	cv.vendedor_id,
	ve.valor_bruto AS valor_nota,
	ve.nf_desconto,
	ve.valor_venda,
	iv.produto_id,
	iv.valor_unitario,
	iv.item_quantidade,
	iv.valor_bruto AS total_item,
	(iv.valor_bruto/ve.valor_bruto) AS rateio_desconto,
	ROUND(ve.nf_desconto * (iv.valor_bruto/ve.valor_bruto),2) AS desconto_item
FROM Vendas ve
JOIN ItensVendas iv
	ON ve.id = iv.vendas_id
JOIN ClientesVendedores cv
	ON ve.cliente_id = cv.cliente_id

), arredondamento AS(
SELECT 
	nfe,
	data,
	vendedor_id,
	cliente_id,
	produto_id,
	valor_unitario,
	item_quantidade,
	total_item,
	desconto_item,
	ROW_NUMBER() OVER(PARTITION BY nfe ORDER BY total_item DESC) AS seq_ranking,
	valor_venda,
	valor_venda - SUM(total_item - desconto_item) OVER(PARTITION BY nfe) AS dif_final
FROM rateio_descontos
)

SELECT 
	nfe,
	data,
	vendedor_id,
	cliente_id,
	produto_id,valor_unitario,
	item_quantidade,
	total_item,
	CASE
		WHEN seq_ranking = 1
		THEN desconto_item - dif_final
		ELSE desconto_item
	END AS valor_desconto,
	total_item - 
	CASE 
		WHEN seq_ranking = 1
		THEN desconto_item - dif_final
		ELSE desconto_item
	END AS valor_liquido
FROM arredondamento




    

