
# MODELO DE SIMILARIDADE DE CLIENTES

# Importar Bibliotecas
import pyodbc
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity


# Criar conexão com Banco de Dados
dados_conexao = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=LAPTOP-RAFA;"
    "Database=PinskiDatabase;"
    "UID=localhost;"
    "PWD=senha;"
)

# Abrir conexão, executar comandos SQL e fechar conexão com segurança
conexao = pyodbc.connect(dados_conexao)
cursor = conexao.cursor()

cursor.execute("SELECT * FROM fVendas")
valores = cursor.fetchall()
descricao = cursor.description

cursor.close()

# Transformar a query em Data Frame
colunas = [tupla[0] for tupla in descricao]
ft_vendas = pd.DataFrame.from_records(valores, columns=colunas)

# Aplicando filtro ao DataFrame para obter dados mais recentes
ft_vendas['data'] = pd.to_datetime(ft_vendas['data'])
max_ano = ft_vendas['data'].dt.year.max()

ft_vendas = ft_vendas.loc[ft_vendas['data'].dt.year == max_ano]
ft_vendas = ft_vendas[['cliente_id', 'produto_id', 'item_quantidade']]

ft_vendas = ft_vendas.groupby(['cliente_id', 'produto_id'], as_index=False)[
    'item_quantidade'].sum()
matriz_utilidade = ft_vendas.pivot_table(
    index='cliente_id',
    columns='produto_id',
    values='item_quantidade',
    fill_value=0)

# Aplicando modelo de similaridade com Machine Learning
matriz_similaridade = cosine_similarity(matriz_utilidade)
df_similaridade = pd.DataFrame(
    matriz_similaridade, index=matriz_utilidade.index, columns=matriz_utilidade.index)

# Tratando o resultado do modelo e filtrando as colunas que seram utilizadas
df_similaridade['cliente_id'] = df_similaridade.index
cols = ['cliente_id'] + [col for col in df_similaridade if col != 'cliente_id']
df_similaridade = df_similaridade[cols]

df_similaridade = pd.melt(
    df_similaridade,
    id_vars=['cliente_id'],
    var_name='similar_id',
    value_name='valor'
)

# Escolhendo as 3 maiores similaridades de cada cliente
df_similaridade = df_similaridade.loc[df_similaridade['valor'] < 0.999]
df_similaridade = df_similaridade.sort_values(
    by=['cliente_id', 'valor'], ascending=[True, False])
top3 = df_similaridade.sort_values(by=['cliente_id', 'valor'], ascending=[
                                   True, False]).groupby('cliente_id', group_keys=False).head(3)

# Salvando em Excel
top3.to_excel('similaridade_clientes.xlsx', index=False)
