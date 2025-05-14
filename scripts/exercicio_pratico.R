## Instalando pacotes
install.packages("dados")
install.packages("tidyverse")
install.packages("dplyr")
install.packages("ggthemes")
install.packages("naniar")
install.packages("ggplot2")
install.packages("janitor")

## Chamando esses pacotes 
library(dados)
library(tidyverse)
library(dplyr)
library(ggthemes)
library(naniar)
library(ggplot2)
library(janitor)

## Identificação de casos ausentes

set.seed(123)

dados <- tibble(
  nome = c("Ana", "Bruno", "Carla", "Diego", "Eduarda", "Fernanda"),
  idade = c(23, NA, 35, 40, NA, 30),
  sexo = c("F", "M", "F", "M", "F", "F"),
  peso = c(60, 80, NA, 90, NA, 70)
)

print(dados)

# Montando a matriz sombra e visualizando 
dados_sombra <- bind_shadow(dados)
print(dados_sombra)
vis_miss(dados)

# Montando um gráfico -> Vamos ver se a ausência de peso está associada ao sexo:
dados %>%
  bind_shadow() %>%
  count(sexo, peso_NA) %>%
  ggplot(aes(x = sexo, y = n, fill = peso_NA)) +
  geom_col(position = "dodge") +
  labs(title = "Presença/Ausência de Peso por Sexo")

# A ausência pode ser informativa. Vamos ver como a ausência de peso afeta a idade média:
dados %>%
  bind_shadow() %>%
  group_by(peso_NA) %>%
  summarise(media_idade = mean(idade, na.rm = TRUE))

# Esse gráfico mostra quais combinações de variáveis estão ausentes ao mesmo tempo.
gg_miss_upset(dados)


### Trabalhando com o PIB ------------------------------------------------------
## Medidas de tendência central ------------------------------------------------

pib <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "pib_2") %>%
  janitor::clean_names() %>%
  mutate(municipio = gsub("\\(.*\\)", "", municipio),  
         municipio = toupper(municipio), 
         municipio = str_trim(municipio)) %>%
  filter(municipio != "PERNAMBUCO") %>%
  filter(ano == 2021)

# Média
mean(pib$pib, na.rm = TRUE)

# Mediana
median(pib$pib, na.rm = TRUE)

# Moda (função auxiliar)
moda <- function(x) {
  ux <- unique(na.omit(x))
  ux[which.max(tabulate(match(x, ux)))]
}

moda(pib$pib)

## Identificando a simetria dos dados ------------------------------------------

# Remover valores NA
populacao <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "populacao") %>%
  janitor::clean_names() %>%
  mutate(municipio = gsub("\\(.*\\)", "", municipio),  
         municipio = toupper(municipio), 
         municipio = str_trim(municipio)) %>%
  filter(municipio != "PERNAMBUCO") %>%
  filter(!is.na(populacao))

# Calcular média e desvio padrão
media <- mean(populacao$populacao)
desvio <- sd(populacao$populacao)

# Plotando o histograma com curva normal
ggplot(populacao, aes(x = populacao)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "skyblue", color = "white") +
  stat_function(fun = dnorm, args = list(mean = media, sd = desvio), 
                color = "red", size = 1) +
  labs(
    title = "Distribuição da população com Curva Normal",
    x = "PIB",
    y = "Densidade"
  ) +
  theme_minimal()

## Se tiver valores extremos, podemos utilizar uma escala logaritmica
ggplot(populacao, aes(x = log10(populacao))) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "lightgreen", color = "white") +
  stat_function(
    fun = dnorm,
    args = list(mean = mean(log10(populacao$populacao)), sd = sd(log10(populacao$populacao))),
    color = "darkgreen",
    size = 1
  ) +
  labs(
    title = "Distribuição Logarítmica da população com Curva Normal",
    x = "log10(PIB)",
    y = "Densidade"
  ) +
  theme_minimal()

# Análise exploratória dos dados -----------------------------------------------
# Leitura e limpeza dos dados

pib_per_capita <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "pib_per_capita") %>%
  clean_names() %>%
  mutate(
    municipio = gsub("\\(.*\\)", "", municipio),
    municipio = toupper(municipio),
    municipio = str_trim(municipio)
  ) %>%
  filter(municipio != "PERNAMBUCO") %>%
  mutate(valor = as.numeric(str_replace_all(as.character(valor), ",", "."))) %>%
  group_by(ano) %>%
  summarise(soma = sum(valor, na.rm = TRUE))

# Plotando
ggplot(pib_per_capita, aes(x = factor(ano), y = soma)) +
  geom_col(fill = "steelblue") +
  labs(
    title = "Soma do PIB per capita por Ano",
    x = "Ano",
    y = "Soma do PIB per capita"
  ) +
  theme_minimal()

# Gráfico de dispersão mostra a relação entre duas variáveis quantitativas.

pib_dispersao <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "pib_2") %>%
  janitor::clean_names() %>%
mutate(municipio = gsub("\\(.*\\)", "", municipio),  
       municipio = toupper(municipio), 
       municipio = str_trim(municipio)) %>%
  filter(municipio != "PERNAMBUCO") %>%
  filter(ano == 2021) %>%
  select(municipio, pib)

populacao_dispersao <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "populacao") %>%
  janitor::clean_names() %>%
  mutate(municipio = gsub("\\(.*\\)", "", municipio),  
         municipio = toupper(municipio), 
         municipio = str_trim(municipio)) %>%
  filter(municipio != "PERNAMBUCO") %>%
  filter(!is.na(populacao))

join_pib_populacao <- left_join(pib_dispersao, populacao_dispersao)

## Sem logaritimo
ggplot(join_pib_populacao, aes(x = populacao, y = pib)) +
  geom_point(alpha = 0.7, color = "blue") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  labs(
    title = "Relação entre População e PIB dos Municípios",
    x = "População",
    y = "PIB"
  ) +
  theme_minimal()

## Com logaritimo -> escala logarítmica é usada em gráficos para facilitar a visualização de dados com grande variação de valores
# Reduzir o efeito de valores extremos (outliers)
# A escala logarítmica "comprime" os maiores valores, permitindo comparar todos mais claramente.
# Usamos Quando os dados têm variação de ordens de magnitude (milhares a milhões).
# Quando quer ver proporções e crescimentos relativos em vez de absolutos.
# Quando muitos valores estão aglomerados na base do eixo em escala linear.

ggplot(join_pib_populacao, aes(x = populacao, y = pib)) +
  geom_point(alpha = 0.7, color = "darkgreen") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Relação entre População e PIB (Escala Log)",
    x = "População (log10)",
    y = "PIB (log10)"
  ) +
  theme_minimal()


# Aplicando a Lei de Benford ---------------------------------------------------

pib_freq <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "pib_2") %>%
  janitor::clean_names() %>%
  mutate(municipio = gsub("\\(.*\\)", "", municipio),  
         municipio = toupper(municipio), 
         municipio = str_trim(municipio)) %>%
  filter(municipio != "PERNAMBUCO") %>%
  filter(ano == 2021) %>%
  mutate(
    primeiro_digito = as.numeric(str_extract(as.character(pib), "[1-9]"))
  ) %>%
  filter(!is.na(primeiro_digito)) %>%
  count(primeiro_digito) %>%
  mutate(freq_observada = n / sum(n))


# Frequência esperada segundo a Lei de Benford
benford <- tibble(
  primeiro_digito = 1:9,
  freq_esperada = log10(1 + 1 / primeiro_digito)
)

# Unindo os dados
comparacao <- left_join(pib_freq, benford, by = "primeiro_digito")

# Plotando o gráfico
ggplot(comparacao, aes(x = factor(primeiro_digito))) +
  geom_bar(aes(y = freq_observada), stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_line(aes(y = freq_esperada, group = 1), color = "red", size = 1.2) +
  geom_point(aes(y = freq_esperada), color = "red", size = 2) +
  labs(
    title = "Comparação com a Lei de Benford",
    x = "Primeiro Dígito",
    y = "Frequência",
    caption = "Barra: Frequência observada | Linha: Frequência esperada (Benford)"
  ) +
  theme_minimal()


## Identificando a distribuição do PIB em Pernambuco ---------------------------

pib_data <- readxl::read_excel("data/dados_municipios.xlsx", sheet = "pib_2") %>%
  janitor::clean_names() %>%
  filter(municipio != "PERNAMBUCO") %>%
  filter(ano == 2021) %>%
  mutate(
    municipio = gsub("\\(.*\\)", "", municipio),
    municipio = toupper(municipio),
    municipio = str_trim(municipio)
    )

# Verifique se a conversão funcionou
summary(pib_data$pib)


## Se a maioria dos valores são iguais ou muito próximos (ou mesmo zero), o boxplot pode não formar a "caixa" e mostrar só uma linha de pontos.

# Criando o boxplot
ggplot(pib_data, aes(y = pib)) +
  geom_boxplot(fill = "lightblue", outlier.color = "red") +
  labs(
    title = "Distribuição do PIB dos Municípios",
    y = "PIB",
    x = ""
  ) +
  theme_minimal()

## Usando uma escala logaritmica
ggplot(pib_data, aes(y = pib)) +
  geom_boxplot(fill = "lightblue", outlier.color = "red") +
  scale_y_log10() +
  labs(
    title = "Distribuição do PIB dos Municípios (Escala Log)",
    y = "PIB (log10)",
    x = ""
  ) +
  theme_minimal()

