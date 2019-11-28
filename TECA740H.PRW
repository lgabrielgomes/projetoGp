#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA740E.CH"

//Definição das Posições retornadas pela função At740EGTP()
#Define tpbABA				1
#Define tpbIDENTIFICACAO		2
#Define tpbTITULO				3
#Define tpbDESCRICAO			4
#Define tpbMODO				5
#DEFINE tpbTAMANHO			6
#DEFINE tpbDECIMAL			7
#Define tpbEDICAO				8
#Define tpbFORMULA			9
#Define tpbVALIDACAO			10
#Define tpbINICIALIZADOR		11
#Define tpbCONTEUDO			12

//Fonte para criação das tabelas da GP
Function TECA740H()
Local aRet	:= {}
Local nX	:= 0

Processa( { || aRet := CriaEstru() }, "Aguarde","Criando tabela ",.F.) //"Aguarde"###"Criando tabela "

For nX	:= 1 to Len(aRet)
	If !aRet[nX][1]
		MsgAlert(aRet[nX][2])
	Else
		MsgAlert(aRet[nX][2])
	EndIf
Next nX

Return

Static Function CriaEstru()
Local aTabPrcf	:= {}
Local lRet		:= .T.
Local lFer		:= .T.
Local lReci		:= .T.
Local lMarc		:= .T.
Local lTrinf	:= .T.
Local cDesc		:= ""
Local cDesc1	:= ""
Local cDesc2	:= ""
Local cDesc3	:= ""

AAdd( aTabPrcf, {'Ferias','VLR_SAL','SALARIO','SALÁRIO','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_AD','AD.','ADICIONAL','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','DEP_IR','DEP IR','DEPENDENTES I.R','1',2, 0,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_PEN','%PENSAO','%PENSAO','1',2, 0,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_DIAS','DIAS FERIAS','DIAS DE FERIAS','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_ABON','ABONO','ABONO','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_MEDIA','MEDIAS HORAS','MEDIAS HORAS','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_MEDIA','MEDIAS','MEDIAS','1',12, 2,'2','=VLR_MEDIA/12',' ','',' '})
AAdd( aTabPrcf, {'Ferias','TOT_VLR_MED','VL. MEDIA','VL. MEDIAS','1',12, 2,'2','=((VLR_SAL+VLR_AD)/220)*((TOT_MEDIA/30)*VLR_DIAS)',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_TER_MED','1/3 S/MEDIA','1/3 S/MEDIAS','1',12, 2,'2','=TOT_VLR_MED/3',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_MED_ABON','VL MED S/ABO','VL MEDIAS S/ABONO','1',12, 2,'2','=((VLR_SAL+VLR_AD)/220)*((TOT_MEDIA/30)*VLR_ABON)',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_TER_ABON','1/3 S/MED AB','1/3 S/MEDIAS ABONO','1',12, 2,'2','=TOT_MED_ABON/3',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_GER_MED','TOTAL HR MED','TOTAL DE HORAS MEDIAS','1',12, 2,'2','=TOT_VLR_MED+TOT_TER_MED+TOT_MED_ABON+TOT_TER_ABON',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_FERIAS','VLR FERIAS','VLR FERIAS','1',12, 2,'2','=VLR_SAL/30*VLR_DIAS',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_ABONO','VLR ABONO','VLR ABONO','1',12, 2,'2','=VLR_SAL/30*VLR_ABON',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_TER_FER','TOT_TER_FER','1/3 S/FERIAS','1',12, 2,'2','=VLR_FERIAS/3',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_TER_AB','1/3 S/ABONO','1/3 S/ABONO','1',12, 2,'2','=VLR_ABONO/3',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','TOT_GER_FERIAS','SOMA FERIAS','VALOR DA SOMA DAS FERIAS','1',12, 2,'2','=VLR_FERIAS+VLR_ABONO+TOT_TER_FER+TOT_TER_AB',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_ANT','ANT. 13° SAL','ANT. 13° SALARIO','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Ferias','VLR_ARREND','ARREDOND','ARREDONDAMENTO','1',12, 2,'1',' ',' ','0,73',' '})
AAdd( aTabPrcf, {'Ferias','TOTAL_RH','TOTAL GERAL','TOTAL GERAL','1',12, 2,'2','=TOT_GER_MED+TOT_GER_FERIAS+VLR_ANT+VLR_ARREND',' ',' ',' '})

//Chama a função para criação da tabela
lRet := GravaTabGP(aTabPrcf,"Planilha para Validação 01.2017")

//Limpa o array para gravar a proxima tabela
aTabPrcf	:= {}

If !lRet
	lFer := .F.
	cDesc := "Erro na criação da Tabela Planilha para Validação 01.2017"
Else
	cDesc := "Sucesso na Criação da Tabela Planilha para Validação 01.2017"
EndIf

AAdd( aTabPrcf, {'RECISÃO','VLR_BASE','VALOR BASE','VALOR BASE','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','VLR_ENCAR','ENC. 38,17%','ENCARGOS 38,17%','1',12, 2,'2','=VLR_BASE*(38,17/100)',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','TOT_DESP','TOT DESP ENC','TOTAL DAS DESPESAS COM ENCARGOS','1',12, 2,'2','=VLR_ENCAR+VLR_BASE',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','TOT_TX_ADM','TX. ADM 12%','TAXA ADMINISTRATIVA DE 12%','1',12, 2,'2','=TOT_DESP*(12/100)',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','TOT_LUCRO','2% DE LUCRO','2% DE LUCRO','1',12, 2,'2','=TOT_DESP*(2/100)',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','TOT_GERAL','TOT DESPESA','TOTAL DE DESPESAS','1',12, 2,'2','=TOT_DESP+TOT_TX_ADM+TOT_LUCRO',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','TOT_IMP','IMP=0,9235','IMPOSTOS=0,9235','1',12, 2,'2','=(TOT_GERAL/0,9235)-TOT_GERAL',' ',' ',' '})
AAdd( aTabPrcf, {'RECISÃO','TOTAL_RH','VLR. FATURAR','VALOR A FATURAR','1',12, 2,'2','=TOT_GERAL+TOT_IMP',' ','',' '})

//Chama a função para criação da tabela
lRet := GravaTabGP(aTabPrcf,"Rescisão Haroldo")

//Limpa o array para gravar a proxima tabela
aTabPrcf	:= {}

If !lRet
	lReci := .F.
	cDesc1 := "Erro na criação da Tabela Rescisão Haroldo"
Else
	cDesc1 := "Sucesso na Criação da Tabela Rescisão Haroldo"
EndIf

AAdd( aTabPrcf, {'Valor','VLR_SAL','SALARIO','VALOR DO SALÁRIO','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_HE_60','HE 60%','HORA EXTRA 60%','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_DSR','INT. DSR','INT DSR','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_HE_100','HE 100%','HORA EXTRA 100%','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_INTR','HE INTR','HORA EXTRA INTR','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_ADIC','ADC. NOT','ADICIONAL NOTURNO','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_BASE_INSS','BASE INSS','VALOR DE BASE DO INSS','1',12, 2,'2','=VLR_SAL+VLR_HE_60+VLR_DSR+VLR_HE_100+VLR_INTR+VLR_ADIC',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_INSS','INSS','VALOR INSS','1',12, 2,'2','=VLR_BASE_INSS*0,302',' ','',' '})
AAdd( aTabPrcf, {'Valor','VLR_FGTS','FGTS','VALOR FGTS','1',12, 2,'2','=VLR_BASE_INSS*0,08',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TOT_DESP','T. DESP','TOTAL DE DESPESA','1',12, 2,'2','=VLR_BASE_INSS+VLR_INSS+VLR_FGTS',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TX_ADM','TAXA ADM','TAXA ADMINISTRATIVA','1',12, 2,'2','=TOT_DESP*0,1',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','SOMA_TOT','S. TOTAL','SOMA TOTAL','1',12, 2,'2','=TOT_DESP+TX_ADM',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TOT_IMP_1','IMPOST','IMPOSTO','1',12, 2,'2','=SOMA_TOT*0,09469',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TOT_FAT_1','T. FATURA','TOTAL DA FATURA','1',12, 2,'2','=SOMA_TOT+TOT_IMP_1',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TOT_OPER','DESP. OPER','DESPESA OPERACIONAL','1',12, 2,'1','',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','SOMA_OPER','S. TOTAL','SOMA TOTAL DO OPERACIONAL','1',12, 2,'2','=TOT_OPER',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TX_ADM_OPER','TX. ADM','TAXA ADM OPERACIONAL','1',12, 2,'2','=TOT_OPER*0,1',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','SUB_TOT_OPER','SUB. TOTAL','SUB. TOTAL','1',12, 2,'2','=SOMA_OPER+TX_ADM_OPER',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TOT_IMP_2','IMPOSTO','IMPOSTO OPERACIONAL','1',12, 2,'2','=SUB_TOT_OPER*0,09469',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','VLR_FAT_OPER','VL. A FATURA','VALOR A FATURAR OPERACIONAL','1',12, 2,'2','=SUB_TOT_OPER+TOT_IMP_2',' ',' ',' '})
AAdd( aTabPrcf, {'Valor','TOTAL_RH','TOTAL GERAL','TOTAL DO VALOR A FATURAR','1',12, 2,'2','=TOT_FAT_1+VLR_FAT_OPER',' ',' ',' '})

//Chama a função para criação da tabela
lRet := GravaTabGP(aTabPrcf,"03.MARÇO - 2017")

//Limpa o array para gravar a proxima tabela
aTabPrcf	:= {}

If !lRet
	lMarc := .F.
	cDesc2 := "Erro na criação da Tabela de 03.MARÇO - 2017"
Else
	cDesc2 := "Sucesso na Criação da Tabela de 03.MARÇO - 2017"
EndIf

AAdd( aTabPrcf, {'FERIAS','VLR_BASE','VALOR BASE','VALOR BASE','1',12, 2,'1',' ',' ',' ',' '})
AAdd( aTabPrcf, {'FERIAS','VLR_ENCARGO','ENC 38,08%','ENCARGOS 38,08%','1',12, 2,'2','=VLR_BASE*(38,08/100)',' ',' ',' '})
AAdd( aTabPrcf, {'FERIAS','TOT_ENCARG','TOT DESP ENC','TOTAL DAS DESPESAS COM ENCARGOS','1',12, 2,'2','=VLR_BASE+VLR_ENCARGO',' ',' ',' '})
AAdd( aTabPrcf, {'FERIAS','TX_ADM','TX ADM 9%','TAXA ADMINISTRATIVA 9%','1',12, 2,'2','=TOT_ENCARG*(9/100)',' ',' ',' '})
AAdd( aTabPrcf, {'FERIAS','TOT_DESP','TOT DESPESAS','TOTAL DAS DESPESAS + TX ADMINISTRATIVAS','1',12, 2,'2','=TOT_ENCARG+TX_ADM',' ',' ',' '})
AAdd( aTabPrcf, {'FERIAS','TOT_IMP','IMP 0,8135','IMPOSTOS = 0,8135','1',12, 2,'2','=(TOT_DESP/0,8135)-TOT_DESP',' ',' ',' '})
AAdd( aTabPrcf, {'FERIAS','TOTAL_RH','TOTAL GERAL','TOTAL DO VALOR A FATURAR','1',12, 2,'2','=(TOT_DESP/0,8135)',' ',' ',' '})

//Chama a função para criação da tabela
lRet := GravaTabGP(aTabPrcf,"FERIAS  - TRIUNFO - SIVALDO CARVALHO BASTOS DE SOUZA")

//Limpa o array para gravar a proxima tabela
aTabPrcf	:= {}

If !lRet
	lTrinf := .F.
	cDesc3 := "Erro na criação da Tabela de FERIAS  - TRIUNFO - SIVALDO CARVALHO BASTOS DE SOUZA"
Else
	cDesc3 := "Sucesso na Criação da Tabela de FERIAS  - TRIUNFO - SIVALDO CARVALHO BASTOS DE SOUZA"
EndIf

Return {{lFer,cDesc},{lReci,cDesc1},{lMarc,cDesc2},{lTrinf,cDesc3}}

Static Function GravaTabGP(aRecTPB,cDesc)
Local oModelTPB		:= NIL
Local oDSMaster		:= NIL
Local oDSGridRH		:= NIL
Local oDSGridImp	:= NIL
Local nI			:= 0
Local nLinesI		:= 0
Local nLinesR		:= 0
Local nOrdImp		:= 0
Local nOrdRH		:= 0
Local cAba			:= ""
Local cCodigo		:= GETSXENUM("TV6", "TV6_CODIGO")  

// Destino dos Dados	
oModelTPB := FwLoadModel('TECA740E')		
oModelTPB:SetOperation( MODEL_OPERATION_INSERT )

If oModelTPB:Activate()

	// Cabeçalho da Tabela de Precificação
	oDSMaster	:= oModelTPB:GetModel("TV6MASTER")
	oDSMaster:SetValue("TV6_NUMERO",cCodigo)
	oDSMaster:SetValue("TV6_DESC",cDesc)
	oDSMaster:SetValue("TV6_STATUS","1")
	oDSMaster:SetValue("TV6_TPAPUR","2")
	
	// Detalhes da Tabela de Precificação
	oDSGridRH	:= oModelTPB:GetModel("TV7RDETAIL")
	oDSGridImp	:= oModelTPB:GetModel("TV7IDETAIL")

	cAba := aRecTPB[1][tpbABA]
	For nI := 1 To Len(aRecTPB)
		If AllTrim(Upper(aRecTPB[nI][tpbABA])) == "IMPOSTOS" 
			
			If oDSGridImp:Length() < ++nLinesI
				 oDSGridImp:AddLine()
			EndIf
			oDSGridImp:GoLine(nLinesI)

			oDSGridImp:SetValue("TV7_FILIAL",XFilial("TV7"))
			oDSGridImp:SetValue("TV7_GRUPO","2")	// Informação é gravada na função At740ECmt()
			oDSGridImp:SetValue("TV7_ORDEM",StrZero(++nOrdImp,TamSX3("TV7_ORDEM")[1]))
			oDSGridImp:SetValue("TV7_IDENT",aRecTPB[nI][tpbIDENTIFICACAO])
			oDSGridImp:SetValue("TV7_TITULO",aRecTPB[nI][tpbTITULO])
			oDSGridImp:SetValue("TV7_DESC",aRecTPB[nI][tpbDESCRICAO])
			oDSGridImp:SetValue("TV7_MODO",aRecTPB[nI][tpbMODO])
			oDSGridImp:SetValue("TV7_TAM",aRecTPB[nI][tpbTAMANHO])
			oDSGridImp:SetValue("TV7_DEC",aRecTPB[nI][tpbDECIMAL])
			oDSGridImp:SetValue("TV7_EDICAO",aRecTPB[nI][tpbEDICAO])
			oDSGridImp:SetValue("TV7_VALID",aRecTPB[nI][tpbVALIDACAO])
			oDSGridImp:SetValue("TV7_INIT",aRecTPB[nI][tpbINICIALIZADOR])
			oDSGridImp:SetValue("TV7_FORM",aRecTPB[nI][tpbFORMULA])
			
		Else
			
			If oDSGridRH:Length() < ++nLinesR
				 oDSGridRH:AddLine()
			EndIf
			oDSGridRH:GoLine(nLinesR)

			nOrdRH := If( cAba <> aRecTPB[nI][tpbABA], 1, ++nOrdRH )
			cAba := aRecTPB[nI][tpbABA]
			
			oDSGridRH:SetValue("TV7_FILIAL",XFilial("TV7"))
			oDSGridRH:SetValue("TV7_GRUPO","1")	// Informação é gravada na função At740ECmt() 
			oDSGridRH:SetValue("TV7_ORDEM",StrZero(nOrdRH,TamSX3("TV7_ORDEM")[1]))
			oDSGridRH:SetValue("TV7_ABA",aRecTPB[nI][tpbABA])
			oDSGridRH:SetValue("TV7_IDENT",aRecTPB[nI][tpbIDENTIFICACAO])
			oDSGridRH:SetValue("TV7_TITULO",aRecTPB[nI][tpbTITULO])
			oDSGridRH:SetValue("TV7_DESC",aRecTPB[nI][tpbDESCRICAO])
			oDSGridRH:SetValue("TV7_MODO",aRecTPB[nI][tpbMODO])
			oDSGridRH:SetValue("TV7_TAM",aRecTPB[nI][tpbTAMANHO])
			oDSGridRH:SetValue("TV7_DEC",aRecTPB[nI][tpbDECIMAL])
			oDSGridRH:SetValue("TV7_EDICAO",aRecTPB[nI][tpbEDICAO])
			oDSGridRH:SetValue("TV7_VALID",aRecTPB[nI][tpbVALIDACAO])
			oDSGridRH:SetValue("TV7_INIT",aRecTPB[nI][tpbINICIALIZADOR])
			oDSGridRH:SetValue("TV7_FORM",aRecTPB[nI][tpbFORMULA])
			
		EndIf
	Next nI
	
	// Valida todas as informações
	If (lRet := oModelTPB:VldData())
		// Grava as informações
		lRet := At740ECmt(oModelTPB) 
	Endif
		
	If !lRet	   
		// Rollback das informações do objeto
		oModelTPB:CancelData()
	EndIf
   
	oModelTPB:DeActivate() ; oModelTPB:Destroy()
EndIf

Return(lRet)