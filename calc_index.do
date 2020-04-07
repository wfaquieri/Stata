

*** Calculo do Indice (calculo para a frente)

* Verificar se o pacote "InGaP" estah instalado, c.c. instalar (DESCOMENTAR LINHA 15).
*ssc install InGaP


*** Importando arquivo do Excel 
import excel "path\Database.xlsx", sheet("main") firstrow

*** set more off diz ao Stata para não pausar ou exibir a mensagem --more--.
set more off

*** Indicar qual o novo MES que deve ser calculado tal que 1=jan/2019 (Ano-Base), 2=fev/2019, 3=mar/2019 e, assim por diante.
*** "x" e "s" sao variaveis de apoio para o calculo da ponderacao. 

*** Looping para o calculo 
local m =8 

forvalues i = 1(1)`m'{
local j = `i'+1
gen x_`i' = pond_`i' * r_`i'
egen s_`i' = total(x_`i')
gen pond_`j' = (x_`i'/ s_`i')*100
gen ind_`j' = ind_`i' * r_`j'
gen var_`j' =  (r_`j' - 1)*100
gen infl_`j' = (pond_`j' * var_`j')/100
}


*** Organizando as variaveis geradas
forvalues i = 1(1)`m'{
order (r_`i'), after(var_`i')
}
order (var_1), before (r_1)


*** Excluindo as variaveis de apoio. 
forvalues i = 1(1)`m'{
drop x_`i'
drop s_`i'
}


***Criando a linha "Beneficios Mensais e Diarios"
ingap 2
replace descr = "Beneficios Mensais e Diarios" in 2

foreach v in pond_1 infl_1{
replace `v' =  ( `v'[3] + `v'[4] + `v'[5] + `v'[6] + `v'[7] + `v'[8] + `v'[9]) in 2
}
replace var_1 = (infl_1[2] / pond_1[2])*100 in 2
replace r_1 = (var_1[2] / 100)+1 in 2
replace ind_1 = 100 in 2


***Criando a linha "Insumos diversos"
ingap 10
replace descr = "Insumos diversos" in 10
foreach v in pond_1 infl_1{
replace `v' =  ( `v'[11] + `v'[12] + `v'[13]) in 10
}
replace var_1 = (infl_1[10] / pond_1[10])*100 in 10
replace r_1 = (var_1[10] / 100) + 1 in 10
replace ind_1 = 100 in 10


***Criando a linha "ISSVS"
ingap 1
replace descr = "ISSVS" in 1
foreach v in pond_1 infl_1{
replace `v' =  ( `v'[2] + `v'[3] + `v'[11]  + `v'[15]) in 1
}
replace var_1 = (infl_1[1] / pond_1[1])*100 in 1
replace r_1 = (var_1[1] / 100) + 1 in 1
replace ind_1 = 100 in 1


***Looping for "Beneficios Mensais e Diarios"
forvalues i = 1(1)`m'{
foreach v in pond_`i' infl_`i'{
replace `v' =  (`v'[4] + `v'[5] + `v'[6] + `v'[7] + `v'[8] + `v'[9] + `v'[10]) in 3
replace var_`i' = (infl_`i'[3] / pond_`i'[3]) * 100 in 3
replace r_`i' = (var_`i'[3] / 100)+1 in 3
}
}
forvalues i = 1(1)`m'{
local j = `i'+ 1
replace ind_`j' = ind_`i' * r_`j' in 3
}


***Looping for "Insumos diversos"
forvalues i = 1(1)`m'{
foreach v in pond_`i' infl_`i'{
replace `v' =  (`v'[12] + `v'[13] + `v'[14]) in 11
replace var_`i' = (infl_`i'[11] / pond_`i'[11])*100 in 11
replace r_`i' = (var_`i'[11] / 100)+1 in 11
}
}
forvalues i = 1(1)`m'{
local j = `i'+ 1
replace ind_`j' = ind_`i' * r_`j' in 11
}
}


***Looping for "ISSVS"
forvalues i = 1(1)`m'{
foreach v in pond_`i' infl_`i'{
replace `v' =  (`v'[2] + `v'[3] + `v'[11]  + `v'[15]) in 1
replace var_`i' = (infl_`i'[1] / pond_`i'[1]) * 100 in 1
replace r_`i' = (var_`i'[1] / 100)+1 in 1
}
}
forvalues i = 1(1)`m'{
local j = `i'+ 1
replace ind_`j' = ind_`i' * r_`j' in 1
}

# Reponderação ------------------------------------------------------------

***Reponderar: necessário sempre que a ponderação não for igual a 100. Verificar através do comando "sum pond*"
forvalues j = 1(1)`m'{
gen w_`j'=.
forvalues i = 1(1)15{
replace w_`j'= (pond_`j'[`i'] / pond_`j'[1]) * 100 in `i'
}
}

***Reordenando as variaveis.
forvalues i = 1(1)`m'{
order w_`i', after (pond_`i')
}

***Arredondamento.
forvalues i = 1(1)`m'{
replace w_`i' =round(w_`i', 0.0001)
}

***Substituindo e renomeando.
forvalues i = 1(1)`m'{
drop pond_`i'
rename w_`i' pond_`i'
}

# Fim da reponderação -----------------------------------------------------


* Alterando a classe/tipo das variaveis para decimal
recast double pond_1-infl_`m'

*** Arredondamento das variaveis
replace ind_1 =round(ind_1, 0.0001)
replace pond_1 =round(pond_1, 0.0001)
replace var_1 =round(var_1, 0.00001)
replace r_1 =round(r_1, 0.00001)
replace infl_1 = round(infl_1,0.0000001)

forvalues i = 1(1)`m'{
replace ind_`i' =round(ind_`i', 0.0001)
replace pond_`i' =round(pond_`i', 0.0001)
replace var_`i' =round(var_`i', 0.00001)
replace r_`i' =round(r_`i', 0.00001)
replace infl_`i' =round(infl_`i',0.0000001)
}

*Salvando os arquivos com a data de hoje.
display c(current_date)
local date = c(current_date)
local date = subinstr(trim("`date'"), " ", "_", .)
display "`date'"

*** Exportando para excel
export excel "path\1-Outputs\Output_2_`date'.xls", firstrow(variables)



**************************************************** Gerar arquivo output_1_AAMMDD "Visao dos Indices".
recast double ind_1-ind_`m'

***Organizando as variaveis geradas
forvalues i = 1(1)`m'{
order ( ind_`i' ), before ( pond_1 )
}


***Organizando as variaveis geradas
forvalues i = 2(1)`m'{
local j=`i'-1
order ( ind_`i' ), before ( ind_`j' )
}


***Limpando a base, deixando apenas as informacoes necessarias para a aba "Carga"
drop varname


*** Exportando para excel
export excel "path\1-Outputs\Output_1_`date'.xlsx", firstrow(variables)








