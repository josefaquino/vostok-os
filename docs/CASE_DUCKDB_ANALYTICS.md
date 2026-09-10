# CASE: Data Science at CLI com DuckDB

## Descoberta
O rush do sistema (GNU rush 2.4) eh restricted shell, nao a ferramenta R.
Pivot: usar DuckDB como engine de data science (recomendado pelo proprio Jeroen).

## Arquitetura
yoda-stats: wrapper bash usando DuckDB para analise estatistica.

## Comandos
- ./yoda-stats stats          (descritivas)
- ./yoda-stats outliers       (z-score > 3)
- ./yoda-stats distribution   (percentis)

## Vantagens
- Zero dependencias adicionais
- SQL universal (mais portavel que R)
- Performance C++ (vs R overhead)
- Filosofia Unix mantida (100% bash + pipes)
