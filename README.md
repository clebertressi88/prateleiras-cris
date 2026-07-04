# Expositor desmontavel 40 x 30 x 40 cm

Conjunto tecnico em escala 1:1 para corte a laser em MDF nominal de 3 mm. O expositor possui tres prateleiras inclinadas, frentes de contencao, duas travessas traseiras, base, fundo, duas laterais e travas tipo cunha.

## Arquivos entregues

- `prateleira_40x30_corte.svg`: corte limpo em linhas pretas, sem textos, para LightBurn e similares
- `prateleira_40x30_corte.dxf`: corte na camada `CORTE` e identificacao na camada `GRAVACAO`
- `prateleira_40x30_corte_corrigido.svg`: copia identificada da revisao com `L1/L2` de 310 mm e `T1/T2` niveladas
- `prateleira_40x30_corte_corrigido.dxf`: DXF correspondente a revisao corrigida
- `plano_corte_numerado.svg`: plano tecnico organizado e numerado; usar como referencia
- `manual_montagem.svg`: manual vertical importavel no Canva
- `prateleira_40x30_preview.svg`: vista esquematica do produto montado
- `gerar_arquivos.ps1`: gerador parametrico para alterar MDF, folga e kerf

## Dimensoes montadas

- largura externa: 40 cm
- altura: 40 cm
- profundidade da base: 30 cm
- profundidade total das laterais: 31 cm (reforco traseiro de 10 mm)
- largura interna das prateleiras: 39,4 cm
- profundidade de cada prateleira: 16 cm
- inclinacao: 7,83 graus, com elevacao traseira de aproximadamente 2,2 cm
- frente de contencao: 7 cm

## Lista de pecas

- `L1-L2`: duas laterais de 31 x 40 cm; o centimetro traseiro reforca o rasgo de `F1`
- `F1`: fundo de 39,4 x 40 cm
- `B1`: base de 39,4 x 29,7 cm
- `P1-P3`: tres prateleiras inclinadas de 39,4 x 16 cm
- `FR1-FR3`: tres frentes de 39,4 x 7 cm
- `T1-T2`: duas travessas de reforco de 39,4 x 3,5 cm
- `TR1-TR8`: oito travas tipo cunha
- um cupom para calibracao dos encaixes

## Folga e kerf configuraveis

O gerador calcula a largura desenhada do rasgo por:

`rasgo CAD = espessura real do MDF + folga desejada - kerf do laser`

Os valores padrao sao MDF 3,00 mm, folga 0,10 mm e kerf 0,10 mm, resultando em rasgo CAD de 3,00 mm. Meça o MDF com paquimetro e corte o cupom antes do plano completo.

Para regenerar com outros valores:

```powershell
powershell -ExecutionPolicy Bypass -File .\gerar_arquivos.ps1 -EspessuraMdf 3.10 -FolgaMontagem 0.08 -KerfLaser 0.12
```

Se a compensacao de kerf ja estiver ativada no LightBurn, use `-KerfLaser 0` no gerador para nao compensar duas vezes.

## Montagem

1. Encaixe o fundo e a base na lateral `L1`.
2. Encaixe `T1` em `P1` e `T2` em `P2`.
3. Encaixe `FR1-FR3` nas respectivas prateleiras.
4. Coloque `P1-P3` nos rasgos inclinados de `L1`; `P3` tambem encaixa no fundo.
5. Feche com a lateral `L2` e introduza as oito travas nas abas passantes.

Uma pequena quantidade de cola para madeira pode ser aplicada apos um teste de montagem a seco, mas as prateleiras e a base possuem travas mecanicas.

As abas de `T1` e `T2` possuem comprimento igual a espessura configurada do MDF, ficando niveladas com as pecas encaixadas.
