

destring *,replace force

*Calculando a distância entre municípios: matriz simétrica diagonal zero

use "\\path\Geodist_munic_Br.dta"

local tam =5507
set matsize 10000
mkmat ID
mkmat LATITUDE
mkmat LONGITUDE
matrix dist = J(`tam',`tam',0)
forvalues i= 1(1)`tam'{
display `i'
local k = `i'+1
forvalues j= `k'(1)`tam'{
quietly scalar LAT`i'=LATITUDE[`i',1]
quietly scalar LONG`i'=LONGITUDE[`i',1]
quietly scalar LAT`j'=LATITUDE[`j',1]
quietly scalar LONG`j'=LONGITUDE[`j',1]
quietly geodist LAT`i' LONG`i' LAT`j' LONG`j'
quietly scalar dist`i'_`j'= r(distance)
quietly matrix dist[`i',`j']=dist`i'_`j'
}
}

set mem 100m
set maxvar 12000
import delimited C:path\munic_dist_Br.csv, delimiter(";") varnames(1) 
destring v6-v5575, replace ignore(",") force
save "path\Base_Dados_Municipios_destring.dta", replace



***Criando matrizes binárias: Matriz 1
clear
set maxvar 12000
use "path\Base_Dados_Municipios_destring.dta"
local dist_1 = 50
foreach var of varlist v6-v5575 {
gen `var'_1 = 0
replace `var'_1 = 1 if `var'<=`dist_1'
}

drop v6-v5575
nsplit Codigo, digits(6 1) generate(Code one)
drop Codigo one
rename Code Codigo
save "path\Winicius\Matriz_1.dta"

*Criando matrizes binárias: Matriz 2
clear 
use "path\Base_Dados_Municipios_destring.dta"
local dist_1 = 50
foreach var of varlist v6-v5575 {
gen `var'_2 = 0
replace `var'_2 = 1 if `var'>`dist_1' & `var'<=2*`dist_1'
}

drop v6-v5575
nsplit Codigo, digits(6 1) generate(Code one)
drop Codigo one
rename Code Codigo
save "path\Matriz_2.dta"


*******************************************************************************************************************************************
*******************************************************************************************************************************************


*Concatenar duas variáveis
egen Conc_1 = concat (Codigo Ano)

*How to identify and remove duplicate observations
duplicates list (varname)
duplicates report (varname)


*******************************************************************************************************************************************
*******************************************************************************************************************************************

*Completando os dados faltantes da base:
set maxvar 12000
import excel "path\Royalties.xlsx", sheet("Planilha1") firstrow 
destring *,replace force 
nsplit Codigo, digits(6 1) generate(Code one) 
drop codigoIBGE one 
rename Code Codigo
rename ano Ano 
sort Ano Codigo 
save "path\Royalties.xlsx", replace

chdir path
foreach i in 1 2 3 4 5 6 7 8 {
clear
use "path\Royalties.xlsx"
merge m:m Codigo using merge_`i'.dta
tsfill, full
tsset Codigo Ano
save merge_`i', replace
}

set maxvar 12000
use "path\Apoio.dta"
merge m:m Conc_1 using "path\Royalties_v2.dta"  
*Preenchendo lacunas nos dados com novas observações, que contêm valores faltantes
tsfill, full
*Alterando os nomes das variáveis
rename ProdutoInternoBrutoapreços Pib
rename VABdaAgropecuáriaapreçosco VAB_Agro
rename VABdaIndústriaapreçoscorre VAB_Ind
rename VABdosServiçosapreçoscorre VAB_Serv
rename VABdaAdministraçãodefesaed VAB_AdmEDef
rename VABtotalapreçoscorrentesR  VABtotal
rename TotalCFEM Total_CFEM
rename COBRE Cobre_CFEM
rename MINÉRIODEFERRO MinFerro_CFEM
rename FERRO Ferro_CFEM
rename BAUXITA Bauxita_CFEM
rename CALCÁRIO Calcario_CFEM
rename MANGANÊS Manganes_CFEM
rename TotalQtdecomercializ Total_qtde
rename COBREQtdecomercializton Cobre_qtde
rename MINÉRIODEFERROQtdecomerci MinFerro_qtde
rename FERROQtdecomercializton Ferro_qtde
rename BAUXITAQtdecomercializt Bauxita_qtde
rename CALCÁRIOQtdecomercializt Calcario_qtde
rename MANGANÊSQtdecomercializt Manganes_qtde
rename OutrosQtdecomercializton Outros_qtde
rename BD Outros_CFEM

*Substituindo missing por zero
foreach v in total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem {
replace `v'=0 if `v'==.
}
replace Royalties=0 if Royalties==.
replace RoyaltiesPE=0 if RoyaltiesPE==.
replace Pib=0 if Pib==.
replace VAB_Agro=0 if VAB_Agro==.
replace VAB_Ind=0 if VAB_Ind==.
replace VAB_Serv=0 if VAB_Serv==.
replace VAB_AdmEDef=0 if VAB_AdmEDef==.
replace VABtotal=0 if VABtotal==.
replace Pop=0 if Pop==.
save "C:\Users\winicius.faquieri\Desktop\Winicius\Apoio.dta", replace


************************************************** ### ***************************************************

clear
set maxvar 12000
use "C:\Users\winicius.faquieri\Desktop\Winicius\Apoio.dta"
*alterar o nome de acordo com o arquivo: Matriz_w tal que w={1,2,...,8}
merge m:m Codigo using "C:\Users\winicius.faquieri\Desktop\Winicius\Matriz_w.dta"
tsfill, full

foreach v in total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem {
replace `v'=0 if `v'==.
}

foreach v in Petroleo Gas area{
replace `v'=0 if `v'==.
}

sort Ano variável
drop if _merge==1
*alterar o nome de acordo com o arquivo: merge_w tal que w={1,2,...,8}
save "C:\Users\winicius.faquieri\Desktop\Winicius\merge_w.dta", replace

*Transformando variáveis em matriz
*alterar o 'w' de acordo com o arquivo: merge_w
set matsize 11000
forvalues i= 1999(1)2016{
*mkmat v6_w-v5575_w if Ano==`i', matrix(B)
mkmat Royalties if Ano==`i', matrix(A1)
mkmat RoyaltiesPE if Ano==`i', matrix(A2)
mkmat Pib if Ano==`i', matrix(A3)
mkmat VAB_Agro if Ano==`i', matrix(A4)
mkmat VAB_Ind if Ano==`i', matrix(A5)
mkmat VAB_Serv if Ano==`i', matrix(A6)
mkmat VAB_AdmEDef if Ano==`i', matrix(A7)
mkmat VABtotal if Ano==`i', matrix(A8)
mkmat Pop if Ano==`i', matrix(A9)
mkmat total_cfem if Ano==`i', matrix(A10)
mkmat cobre_cfem if Ano==`i', matrix(A11)
mkmat minferro_cfem if Ano==`i', matrix(A12)
mkmat ferro_cfem if Ano==`i', matrix(A13)
mkmat bauxita_cfem if Ano==`i', matrix(A14)
mkmat calcario_cfem if Ano==`i', matrix(A15)
mkmat manganes_cfem if Ano==`i', matrix(A16)
mkmat outros_cfem if Ano==`i', matrix(A17)
mkmat Petroleo if Ano==`i', matrix(A18)
mkmat Gas if Ano==`i', matrix(A19)
mkmat area if Ano==`i', matrix(A20)
mkmat minferro_qtde if Ano==`i', matrix(A21)
matrix C_`i'=B*A1
matrix D_`i'=B*A2
matrix E_`i'=B*A3
matrix F_`i'=B*A4
matrix G_`i'=B*A5
matrix H_`i'=B*A6
matrix I_`i'=B*A7
matrix J_`i'=B*A8
matrix K_`i'=B*A9
matrix L_`i'=B*A10
matrix M_`i'=B*A11
matrix N_`i'=B*A12
matrix O_`i'=B*A13
matrix P_`i'=B*A14
matrix Q_`i'=B*A15
matrix R_`i'=B*A16
matrix S_`i'=B*A17
matrix T_`i'=B*A18
matrix U_`i'=B*A19
matrix V_`i'=B*A20
matrix X_`i'=B*A21
}

*To list matrix example year 1999
matrix list C_1999
matrix list D_1999
...
  
*Creating variables from matrix C, D, E, ..., U.
forvalues i= 1999(1)2016{
svmat C_`i', names(soma_Royalties_`i')
svmat D_`i', names(soma_RoyaltiesPE_`i')
svmat E_`i', names(soma_PIB_`i')
svmat F_`i', names(soma_VAB_Agro_`i')
svmat G_`i', names(soma_VAB_Ind_`i')
svmat H_`i', names(soma_VAB_Serv_`i')
svmat I_`i', names(soma_VAB_AdmEDef_`i')
svmat J_`i', names(soma_VABtotal_`i')
svmat K_`i', names(soma_Pop_`i')
svmat L_`i', names(soma_total_cfem_`i')
svmat M_`i', names(soma_cobre_cfem_`i')
svmat N_`i', names(soma_minferro_cfem_`i')
svmat O_`i', names(soma_ferro_cfem_`i')
svmat P_`i', names(soma_bauxita_cfem_`i')
svmat Q_`i', names(soma_calcario_cfem_`i')
svmat R_`i', names(soma_manganes_cfem_`i')
svmat S_`i', names(soma_outros_cfem_`i')
svmat T_`i', names(soma_Petroleo_`i')
svmat U_`i', names(soma_Gas_`i')
svmat V_`i', names(soma_area_`i')
svmat X_`i', names(soma_minferro_`i')
}

*Separando as variáveis de forma sequencial
sort Codigo Ano
tsset Codigo Ano
foreach v in Pop Royalties RoyaltiesPE PIB VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem Petroleo Gas area minferro{
gen soma_`v'_1999 = soma_`v'_19991
forvalues i= 2000(1)2016{
local j = `i'-1999
gen soma_`v'_`i' = L`j'.soma_`v'_`i'1
}
}

sort Ano Codigo
*Substituindo missing por zeros nas variáveis criadas
foreach v in Pop Royalties RoyaltiesPE PIB VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem Petroleo Gas area minferro{
forvalues i= 1999(1)2016{
replace soma_`v'_`i'=0 if soma_`v'_`i'==.
}
}

*Ordenando as variáveis (variables out of order)
foreach v in Pop Royalties RoyaltiesPE PIB VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem Petroleo Gas area minferro {
order soma_`v'_1999, b(soma_`v'_2000) 
}

*Criando variáveis que são a soma de outras variáveis
foreach v in Pop Royalties RoyaltiesPE PIB VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem Petroleo Gas area minferro {
egen `v'_total = rowtotal( soma_`v'_1999-soma_`v'_2016 )
}

foreach v in Pop Royalties RoyaltiesPE PIB VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal total_cfem cobre_cfem minferro_cfem ferro_cfem bauxita_cfem calcario_cfem manganes_cfem outros_cfem Petroleo Gas area minferro{
rename `v'_total `v'_donut_w
}

*Limpando a base.
drop v6_w- soma_minferro_2016
drop _merge
save "C:\Users\winicius.faquieri\Desktop\Winicius\merge_w.dta", replace

clear
use "C:\Users\winicius.faquieri\Desktop\Winicius\Nova_Base_M.dta"
merge m:m Codigo using "C:\Users\winicius.faquieri\Desktop\Winicius\merge_w.dta"
sort Ano variável
save "C:\Users\winicius.faquieri\Desktop\Winicius\Nova_Base.dta", replace

clear
use "C:\Users\winicius.faquieri\Desktop\Painel_v32_oil.dta"
merge m:m Codigo Ano using "C:\Users\winicius.faquieri\Desktop\Winicius\Nova_Base.dta"
drop if _merge==1


***********************************************************************************************************
***********************************************************************************************************

set excelxlsxlargefile on

import excel "path\1-Data\Painel_v31_2.xlsx", sheet("Database") firstrow

destring *,replace force

xtset Codigo Ano 

*deflacionando a série
gen ipca=0
replace ipca=0.320043833 if Ano==1999
replace ipca=0.342588172 if Ano==2000
replace ipca=0.366022433 if Ano==2001
replace ipca=0.39695193  if Ano==2002
replace ipca=0.455363088 if Ano==2003
replace ipca=0.485404234 if Ano==2004
replace ipca=0.518749258 if Ano==2005
replace ipca=0.54045148  if Ano==2006
replace ipca=0.560130801 if Ano==2007
replace ipca=0.591938355 if Ano==2008
replace ipca=0.620872507 if Ano==2009
replace ipca=0.652156577 if Ano==2010
replace ipca=0.69543662  if Ano==2011
replace ipca=0.733014532 if Ano==2012
replace ipca=0.778493031 if Ano==2013
replace ipca=0.827764167 if Ano==2014
replace ipca=0.902510452 if Ano==2015
replace ipca=0.981382136 if Ano==2016

gen VABtotal = VABtotalapreçoscorrentesR/ipca
gen VABindustria = VABdaIndústriaapreçoscorre/ipca
gen VABagro = VABdaAgropecuáriaapreçosco/ipca
gen VABserv = VABdosServiçosapreçoscorre /ipca
gen Wage = Salariostotais /ipca

gen ln_minferro = ln(Minériodeferro)
gen D_ln_minferro=D.ln_minferro
gen ln_PetróleoegásnaturalSCNp = ln(PetróleoegásnaturalSCNp)
gen D_ln_PetróleoegásnaturalSCNp = D.ln_PetróleoegásnaturalSCNp

 
****************************  importando microdados RAIS > 
*Utilizei microdados da RAIS para gerar a informação quantidade de vínculos ativos para o setor de Oil&gas e de minério de ferro, a nível nacional. Ou seja, somar ano e repetir para todos os municípios naquele ano. 
*Fonte: ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/

clear
import delimited "path\1-Data\pdet microdados RAIS\ESTB`i'.txt", delimiter(";") 
gen codigo=.
replace codigo = 8 if cnae20classe==6000 
replace codigo = 9 if cnae20classe==7103
*De 2005 a 1999 é preciso utilizar o CNAE 95. Os valores que correspondem aos códigos 7103 e 6000 no cnae 2.0 são 13102 e 11100 na classificação CNAE/95 (CNAE 1.0, revisada em 2002), respectivamente. 
replace codigo = 8 if cnae95classe==11100 
replace codigo = 9 if cnae95classe==13102
gen Ano=.
replace Ano=`i'
save "path\1-Data\pdet microdados RAIS\`i'.dta"
*De 1999 a 2001 utilizei a variável "estoque" ao invés de "qtdevincativ".  Estoque é definido como "Estoque de vínculos ativos em 31/12 (quando acumulada representa a soma dos vinculos ativos)"

use "path\1-Data\pdet microdados RAIS\1999.dta"

rename clascnae95 cnae
rename estoque qntvincativos
rename codigo cod_setor

rename cnae20classe cnae 
rename qtdvínculosativos qntvincativos 
rename município municipio 
rename codigo cod_setor 

append using "path\1-Data\pdet microdados RAIS\`i'.dta"
save "\\path\1-Data\pdet microdados RAIS\Append_1999-2016.dta"


******* Utilizei microdados da RAIS para gerar a informação quantidade de vínculos ativos para 7 setores, a nível municipal, vide legenda. Fonte: ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/

****************   De 2006 a 2016, utilizar cnae20classe (CNAE 2.0)
use "path\1-Data\pdet microdados RAIS\`Ano'.dta"
gen cod_setor=.
replace cod_setor = 1 if cnae>=01113 & cnae<=05003
replace cod_setor = 2 if cnae>3221 & cnae<=9904
replace cod_setor = 3 if cnae>9904 & cnae<=33295
replace cod_setor = 4 if cnae>33295 & cnae<=39005 
replace cod_setor = 5 if cnae>82997 & cnae<=84302
replace cod_setor = 6 if cnae>=45111 & cnae<=82997 
replace cod_setor = 6 if cnae>84302
replace cod_setor = 7 if cnae>39005 & cnae<45111
sum cod_setor
save "path\1-Data\pdet microdados RAIS\`Ano'.dta", replace
clear

gen Ano=.
replace Ano=2016

****************   De 1995 a 2005, utilizar clascnae95 (CNAE 1.0): 
use "path\1-Data\pdet microdados RAIS\`Ano'.dta"
gen cod_setor=.
replace cod_setor = 1 if cnae>=01112 & cnae<10006
replace cod_setor = 2 if cnae>=10006 & cnae<15113
replace cod_setor = 3 if cnae>15113 & cnae<40118
replace cod_setor = 4 if cnae>=40118 & cnae<45110
replace cod_setor = 5 if cnae>=75116 & cnae<80136
replace cod_setor = 6 if cnae>=50105 & cnae<=74993
replace cod_setor = 6 if cnae>75302
replace cod_setor = 7 if cnae>=45110 & cnae<50105
save "path\1-Data\pdet microdados RAIS\`Ano'.dta", replace
clear

*setor de oil&gas e minério de ferro
replace codigo = 8 if cnae20classe==6000 
replace codigo = 9 if cnae20classe==7103


******* Criar variável, a nível municipal, quantidade de vínculos ativos para (i) petróleo e gas, (ii) minério de ferro; (iii) petróleo & gas + atividades de apoio à extração de oil&gas e (iv) mineração, exceto oil&gas.

*************************  De 1995 a 2005, utilizar clascnae95 (CNAE 1.0): 
clear
use "path\1-Data\pdet microdados RAIS\"ANO".dta"
drop qtd_vinc_setor_1- qtd_vinc_setor_7
drop if municipio==-1
egen concat = concat ( municipio cod_setor )
sort concat
forvalues i = 1(1)7{
gen qtd_vinc_ativ_`i' = .
replace qtd_vinc_ativ_`i' = qntvincativos if cod_setor ==`i'
egen qtd_vinc_setor_`i' = sum( qtd_vinc_ativ_`i' ), by ( concat )
}

replace cod_setor = 8 if cnae ==11100

gen qtd_vinc_ativ_10 = .
replace qtd_vinc_ativ_10 = qntvincativos if cod_setor ==2
egen qtd_vinc_setor_10 = sum( qtd_vinc_ativ_10 ), by ( concat )

replace cod_setor = 9 if cnae ==13102

forvalues i = 8(1)9{
gen qtd_vinc_ativ_`i' = .
replace qtd_vinc_ativ_`i' = qntvincativos if cod_setor ==`i'
egen qtd_vinc_setor_`i' = sum( qtd_vinc_ativ_`i' ), by ( concat )
}

order qtd_vinc_setor_8 qtd_vinc_setor_9, before ( qtd_vinc_setor_10 )

drop qtd_vinc_ativ_1 qtd_vinc_ativ_2 qtd_vinc_ativ_3 qtd_vinc_ativ_4 qtd_vinc_ativ_5 qtd_vinc_ativ_6 qtd_vinc_ativ_7 qtd_vinc_ativ_8 qtd_vinc_ativ_9 qtd_vinc_ativ_10

duplicates drop concat, force

save "path\1-Data\pdet microdados RAIS\'ANO'.dta", replace


**************************************************************************************************************  De 2006 a 2016, utilizar cnae20classe (CNAE 2.0)


clear
use "path\1-Data\pdet microdados RAIS\"ANO".dta"
drop qtd_vinc_setor_1- qtd_vinc_setor_7
drop if municipio==-1
egen concat = concat ( municipio cod_setor )
sort concat
forvalues i = 1(1)7{
gen qtd_vinc_ativ_`i' = .
replace qtd_vinc_ativ_`i' = qntvincativos if cod_setor ==`i'
egen qtd_vinc_setor_`i' = sum( qtd_vinc_ativ_`i' ), by ( concat )
}

replace cod_setor = 8 if cnae==6000 

gen qtd_vinc_ativ_10 = .
replace qtd_vinc_ativ_10 = qntvincativos if cod_setor ==2
egen qtd_vinc_setor_10 = sum( qtd_vinc_ativ_10 ), by ( concat )

replace cod_setor = 9 if cnae==7103

forvalues i = 8(1)9{
gen qtd_vinc_ativ_`i' = .
replace qtd_vinc_ativ_`i' = qntvincativos if cod_setor ==`i'
egen qtd_vinc_setor_`i' = sum( qtd_vinc_ativ_`i' ), by ( concat )
}

order qtd_vinc_setor_8 qtd_vinc_setor_9, before ( qtd_vinc_setor_10 )

drop qtd_vinc_ativ_1 qtd_vinc_ativ_2 qtd_vinc_ativ_3 qtd_vinc_ativ_4 qtd_vinc_ativ_5 qtd_vinc_ativ_6 qtd_vinc_ativ_7 qtd_vinc_ativ_8 qtd_vinc_ativ_9 qtd_vinc_ativ_10

duplicates drop concat, force

save "\\path\1-Data\pdet microdados RAIS\'ANO'.dta", replace

use "\\path\1-Data\pdet microdados RAIS\`ano'.dta"
append using "\\path\1-Data\pdet microdados RAIS\`i'.dta"
save "\\path\1-Data\pdet microdados RAIS\Append_1999-2016.dta"

*Codigo 1 AGRICULTURA, PECUÁRIA E SERVIÇOS RELACIONADOS
*Codigo 2 INDÚSTRIAS EXTRATIVAS
*Codigo 3 INDÚSTRIA DE TRANSFORMAÇÃO
*Codigo 4 ELETRICIDADE, GÁS E ÁGUA QUENTE
*Codigo 5 ADMINISTRAÇÃO PÚBLICA, DEFESA E SEGURIDADE SOCIAL
*Codigo 6 SERVIÇOS: (i) comercio; (ii) transporte, armazenagem e correio; (iii) alojamento e alimentação; (iv) informação e comunicação; (v) ATIVIDADES FINANCEIRAS, DE SEGUROS E SERVIÇOS RELACIONADOS, (vi) ATIVIDADES IMOBILIÁRIAS; (vii) ATIVIDADES PROFISSIONAIS, CIENTÍFICAS E TÉCNICAS; (viii) ATIVIDADES ADMINISTRATIVAS E SERVIÇOS COMPLEMENTARES
*Codigo 7 CONSTRUÇÃO
*Codigo 8 PETROLEO & GAS
*Codigo 9 MINERIO DE FERRO
*codigo 10 EXTRATIVA, EXCETO OIL & GAS.
*Codigo 11 PETROLEO & GAS_MAIS

*Atividades de apoio à extração de petróleo e gás natural: 09106


*****************

nsplit Codigo, digits(6 1) generate(Code one)

drop one
rename Code Codigo

*Combinando base de dados
merge m:1 Codigo Ano using "\\path\1-Data\pdet microdados RAIS\DB_2002-2016_v2.dta"

use "C:\Users\winicius.faquieri\Desktop\Winicius\Painel_v34.dta"
rename Petroleo oil_prod
rename Gas gas_prod

replace oil_prod=0 if oil_prod==.
*gerando uma nova variável normalizada pela área
gen oil_prod_norm = oil_prod/area
replace oil_prod_norm =0 if oil_prod_norm ==.

gen gas_prod_norm = gas_prod/area
replace gas_prod_norm =0 if gas_prod_norm ==.

gen miner_ferr_prod_norm = minferro_qtde/area
replace miner_ferr_prod_norm =0 if miner_ferr_prod_norm ==.

forvalues i = 1(1)8{
gen oil_prod_norm_donut_`i' = Petroleo_donut_`i' / area_donut_`i'
}

*Substituindo missing por zeros.
forvalues i = 1(1)8{
replace oil_prod_norm_donut_`i' = 0 if oil_prod_norm_donut_`i'==.
}

forvalues i = 1(1)8{
gen miner_ferr_norm_donut_`i' = minferro_donut_`i' / area_donut_`i'
}

forvalues i = 1(1)8{
replace miner_ferr_norm_donut_`i' = 0 if miner_ferr_norm_donut_`i'==.
}

merge m:1 Codigo Ano using "C:\Users\winicius.faquieri\Desktop\Winicius\BD_qtd.dta"

*gen ln_employOilGas = ln(employOilGas)
*gen D_ln_employOilGas = D.ln_employOilGas

replace vincativ_oilgas=0 if vincativ_oilgas==.
replace vincativ_minerferr =0 if vincativ_minerferr ==.

*Passei a utilizar as variáveis abaixo para o emprego no setor:
gen ln_vincativ_oilgas = ln(vincativ_oilgas)
gen D_ln_vincativ_oilgas = D.ln_vincativ_oilgas

gen ln_qtd_vinc_setor_8 = ln(qtd_vinc_setor_8)
gen D_ln_qtd_vinc_setor_8 = D.ln_qtd_vinc_setor_8

gen ln_vincativ_minerferr = ln(vincativ_minerferr)
gen D_ln_vincativ_minerferr = D.ln_vincativ_minerferr

gen ln_vincativ_oilgas_mais = ln(vincativ_oilgas_mais)
gen D_ln_vincativ_oilgas_mais = D.ln_vincativ_oilgas_mais

tsfill, full
save "C:\Users\winicius.faquieri\Desktop\Winicius\Painel_v35.dta"

*********************

use "C:\Users\winicius.faquieri\Desktop\Winicius\Painel_v36_eq1.dta"

*ordenar colunas
order varname , before( varname )

egen Conc_1 = concat (Codigo Ano)

forvalues i = 1(1)7{
egen nova_vinc_setor_`i' = sum( qtd_vinc_setor_`i'), by (Codigo Ano)
} 

duplicates drop Conc_1, force
drop Conc_1 qtd_vinc_ativ_1 qtd_vinc_ativ_2 qtd_vinc_ativ_3 qtd_vinc_ativ_4 qtd_vinc_ativ_5 qtd_vinc_ativ_6 qtd_vinc_ativ_7


********************************** Criando uma nova variável a partir das var "qtd_vinc_setor_8" "qtd_vinc_setor_8_mais" e "qtd_vinc_setor_9"


egen nova_qtd_vinc_setor_8 = sum (qtd_vinc_setor_8), by (Ano)
egen nova_qtd_vinc_setor_8_mais = sum (qtd_vinc_setor_8_mais), by (Ano)
egen nova_qtd_vinc_setor_9 = sum (qtd_vinc_setor_9), by (Ano)

order nova_qtd_vinc_setor_8 nova_qtd_vinc_setor_8_mais nova_qtd_vinc_setor_9, before (Royalties)



**********************************      Equation (1) 

* Oil & Gas: variável vincativ_oilgas é emprego no setor de oil & gas
foreach v in Pop Empregostotais Salariostotais VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal qtd_vinc_setor_1 qtd_vinc_setor_2 qtd_vinc_setor_3 qtd_vinc_setor_4 qtd_vinc_setor_5 qtd_vinc_setor_6 qtd_vinc_setor_7 qtd_vinc_setor_10 qtd_vinc_setor_10_Br {
gen inicial_`v'= .
replace inicial_`v'= `v' if Ano == 1999
forvalues i = 1(1)17{
replace inicial_`v' = L`i'.`v' if Ano == 1999+ `i'
}
gen ln`v'= ln(`v')
gen ln_inicial_`v' = ln(inicial_`v')
xtreg D.ln`v' c.oil_prod_norm#c.D_ln_vincativ_oilgas oil_prod_norm i.Ano i.Ano#c.ln_inicial_`v' , fe cluster(Codigo)
*vincativ_oilgas: qtde de vínculos ativos para (i) petróleo e gas, a nível agregado.
*qtd_vinc_setor_8: quantidade de vínculos ativos para (i) petróleo e gas, a nível municipal. 
}

*Variável quantidade de vínculos ativos, a nível municipal, para (i) petróleo e gaS: qtd_vinc_setor_8 

* Oil&Gas_MAIS: variável vincativ_oilgas_mais é emprego no setor de oil & gas + atividades de apoio à extração de petróleo e gás natural
drop inicial_Pop- ln_inicial_nova_vinc_setor_7
foreach v in Pop Empregostotais Salariostotais VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal qtd_vinc_setor_1 qtd_vinc_setor_2 qtd_vinc_setor_3 qtd_vinc_setor_4 qtd_vinc_setor_5 qtd_vinc_setor_6 qtd_vinc_setor_7 qtd_vinc_setor_10 qtd_vinc_setor_10_Br{
gen inicial_`v'= .
replace inicial_`v'= `v' if Ano == 1999
forvalues i = 1(1)17{
replace inicial_`v' = L`i'.`v' if Ano == 1999+ `i'
}
gen ln`v'= ln(`v')
gen ln_inicial_`v' = ln(inicial_`v')
xtreg D.ln`v' c.oil_prod_norm#c.D_ln_vincativ_oilgas_mais oil_prod_norm i.Ano i.Ano#c.ln_inicial_`v' , fe cluster(Codigo)
*vincativ_oilgas_mais: qtde de vínculos ativos para petróleo e gas + atividades de apoio à extração de oil&gas, a nível agregado.
*qtd_vinc_setor_8_mais: quantidade de vínculos ativos para petróleo e gas + atividades de apoio à extração de oil&gas, a nível municipal.
}

*Variável quantidade de vínculos ativos, a nível municipal, para (ii) petróleo & gas + atividades de apoio à extração de oil&gas: qtd_vinc_setor_8_mais 

* Minerio de Ferro
drop inicial_Pop- ln_inicial_nova_vinc_setor_7
foreach v in Pop Empregostotais Salariostotais VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal qtd_vinc_setor_1 qtd_vinc_setor_2 qtd_vinc_setor_3 qtd_vinc_setor_4 qtd_vinc_setor_5 qtd_vinc_setor_6 qtd_vinc_setor_7 qtd_vinc_setor_10 qtd_vinc_setor_10_Br {
gen inicial_`v'= .
replace inicial_`v'= `v' if Ano == 1999
forvalues i = 1(1)17{
replace inicial_`v' = L`i'.`v' if Ano == 1999+ `i'
}
gen ln`v'= ln(`v')
gen ln_inicial_`v' = ln(inicial_`v')
xtreg D.ln`v' c.miner_ferr_prod_norm#c.D_ln_vincativ_minerferr miner_ferr_prod_norm i.Ano i.Ano#c.ln_inicial_`v' , fe cluster(Codigo)
*vincativ_minerferr: qtde de vínculos ativos para minério de ferro, a nível agregado.
*qtd_vinc_setor_9: quantidade de vínculos ativos para minério de ferro, a nível municipal. 
}

*Variável quantidade de vínculos ativos, a nível municipal, para (iii) minério de ferro: qtd_vinc_setor_9


*********************   Equation (2)

*******   Eq. (2), leva em consideração a possibilidade de a atividade extrativa gerar transbordamentos nos municípios vizinhos > donuts <
* Oil & Gas
foreach v in Pop Empregostotais Salariostotais VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal qtd_vinc_setor_1 qtd_vinc_setor_2 qtd_vinc_setor_3 qtd_vinc_setor_4 qtd_vinc_setor_5 qtd_vinc_setor_6 qtd_vinc_setor_7 qtd_vinc_setor_10 qtd_vinc_setor_10_Br {
gen inicial_`v'= .
replace inicial_`v'= `v' if Ano == 1999
forvalues i = 1(1)17{
replace inicial_`v' = L`i'.`v' if Ano == 1999+ `i'
}
gen ln`v'= ln(`v')
gen ln_inicial_`v' = ln(inicial_`v')
xtreg D.ln`v' c.oil_prod_norm#c.D_ln_vincativ_oilgas oil_prod_norm i.Ano i.Ano#c.ln_inicial_`v' c.oil_prod_norm_donut_1#c.D_ln_vincativ_oilgas oil_prod_norm_donut_1 c.oil_prod_norm_donut_2#c.D_ln_vincativ_oilgas oil_prod_norm_donut_2 c.oil_prod_norm_donut_3#c.D_ln_vincativ_oilgas oil_prod_norm_donut_3 c.oil_prod_norm_donut_4#c.D_ln_vincativ_oilgas oil_prod_norm_donut_4 c.oil_prod_norm_donut_5#c.D_ln_vincativ_oilgas oil_prod_norm_donut_5 c.oil_prod_norm_donut_6#c.D_ln_vincativ_oilgas oil_prod_norm_donut_6 c.oil_prod_norm_donut_7#c.D_ln_vincativ_oilgas oil_prod_norm_donut_7 c.oil_prod_norm_donut_8#c.D_ln_vincativ_oilgas oil_prod_norm_donut_8, fe cluster(Codigo)
*vincativ_oilgas: qtde de vínculos ativos para (i) petróleo e gas, a nível agregado.
*qtd_vinc_setor_8: quantidade de vínculos ativos para (i) petróleo e gas, a nível municipal.
}

* Oil & Gas_MAIS
drop inicial_Pop- ln_inicial_qtd_vinc_setor_10_Br
foreach v in Pop Empregostotais Salariostotais VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal qtd_vinc_setor_1 qtd_vinc_setor_2 qtd_vinc_setor_3 qtd_vinc_setor_4 qtd_vinc_setor_5 qtd_vinc_setor_6 qtd_vinc_setor_7 qtd_vinc_setor_10 qtd_vinc_setor_10_Br {
gen inicial_`v'= .
replace inicial_`v'= `v' if Ano == 1999
forvalues i = 1(1)17{
replace inicial_`v' = L`i'.`v' if Ano == 1999+ `i'
}
gen ln`v'= ln(`v')
gen ln_inicial_`v' = ln(inicial_`v')
xtreg D.ln`v' c.oil_prod_norm#c.D_ln_vincativ_oilgas_mais oil_prod_norm i.Ano i.Ano#c.ln_inicial_`v' c.oil_prod_norm_donut_1#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_1 c.oil_prod_norm_donut_2#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_2 c.oil_prod_norm_donut_3#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_3 c.oil_prod_norm_donut_4#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_4 c.oil_prod_norm_donut_5#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_5 c.oil_prod_norm_donut_6#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_6 c.oil_prod_norm_donut_7#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_7 c.oil_prod_norm_donut_8#c.D_ln_vincativ_oilgas_mais oil_prod_norm_donut_8, fe cluster(Codigo)
*vincativ_oilgas_mais: qtde de vínculos ativos para petróleo e gas + atividades de apoio à extração de oil&gas, a nível agregado.
*qtd_vinc_setor_8_mais: quantidade de vínculos ativos para petróleo e gas + atividades de apoio à extração de oil&gas, a nível municipal.
}

* Minerio de Ferro
drop inicial_Pop- ln_inicial_qtd_vinc_setor_10_Br
foreach v in Pop Empregostotais Salariostotais  VAB_Agro VAB_Ind VAB_Serv VAB_AdmEDef VABtotal qtd_vinc_setor_1 qtd_vinc_setor_2 qtd_vinc_setor_3 qtd_vinc_setor_4 qtd_vinc_setor_5 qtd_vinc_setor_6 qtd_vinc_setor_7 qtd_vinc_setor_10 qtd_vinc_setor_10_Br {
gen inicial_`v'= .
replace inicial_`v'= `v' if Ano == 1999
forvalues i = 1(1)17{
replace inicial_`v' = L`i'.`v' if Ano == 1999+ `i'
}
gen ln`v'= ln(`v')
gen ln_inicial_`v' = ln(inicial_`v')
xtreg D.ln`v' c.miner_ferr_prod_norm#c.D_ln_vincativ_minerferr miner_ferr_prod_norm i.Ano i.Ano#c.ln_inicial_`v' c.miner_ferr_norm_donut_1#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_1 c.miner_ferr_norm_donut_2#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_2 c.miner_ferr_norm_donut_3#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_3 c.miner_ferr_norm_donut_4#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_4 c.miner_ferr_norm_donut_5#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_5 c.miner_ferr_norm_donut_6#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_6 c.miner_ferr_norm_donut_7#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_7 c.miner_ferr_norm_donut_8#c.D_ln_vincativ_minerferr miner_ferr_norm_donut_8, fe cluster(Codigo)
}


*Use nocons to drop constants.
outreg2 using table_results.xls, nocons keep (D.ln`v' c.oil_prod#c.D_ln_vincativ_oilgas oil_prod i.Ano i.Ano#c.ln_inicial_`v' )



***end of do-file

