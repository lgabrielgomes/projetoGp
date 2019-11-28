#include "CNTA300R.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "GCTXDEF.CH"

Static __aUsrCpo := Nil

//------------------------------------------------------------------
/*/{Protheus.doc} CNTA300R
Programa responsável pela revisão e aprovação do contrato.
@since 18/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------

//-------------------------------------------------------------------
/*/{Protheus.doc} A300IniRev()
Inicializaçao do processo de revisão
@author guilherme.pimentel
@since 21/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------

Function A300IniRev(oModel,lBlock)
Local lRet		:= .T.
Local aModels 	:= MTGetAllMd({"CALC_CNS","CALC_CNF"})
Local nX 		:= 0
Local oModelCN9 := oModel:GetModel('CN9MASTER')
Local oModelCNA := oModel:GetModel('CNADETAIL')
Local oModelCNB := oModel:GetModel('CNBDETAIL')
Local oStruCN9  := oModelCN9:GetStruct()
Local aArea 	:= GetArea()
Local lPrevF	:= Cn300RetSt("PREVFINANC")
Local lAlterRev	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE .And. !Empty(A300GTpRev()) .And. !IsInCallStack('GCPXGerCt')
Local oStruCNC 	:= oModel:GetModel("CNCDETAIL"):GetStruct()
Local lFusao   	:= .F.

Default lBlock := .F.

A300CLnCNF()
For nX := 1 To oModel:GetModel('CNADETAIL'):Length()
	oModel:GetModel('CNADETAIL'):GoLine(nX)
	A300SLnCNF(oModel:GetModel('CNFDETAIL'):Length())
Next nX

//Não permite gravar modelos que não tem revisao
cn300ModQr(oModel)
oModelCN9:LoadValue('CN9_NUMERO',CN9->CN9_NUMERO)

If !lAlterRev
	oModelCN9:LoadValue('CN9_REVISA',Soma1(CN9->CN9_REVISA))	//Atualização da revisão
EndIf

oModelCN9:LoadValue('CN9_DTREV',dDatabase)					//Atualização da Data da Revisão
oModelCN9:LoadValue('CN9_SITUAC','09')						//Atualização da Sitaução "Em Revisão"
oModelCN9:LoadValue('CN9_DREFRJ',CTOD(''))
oModelCN9:LoadValue('CN9_DTREAJ',CTOD(''))
If !A300GRevis() .And. !lAlterRev // Somente Limpa o Campo Caso seja a primeira execução ou não for alteração da revisão
	oModelCN9:LoadValue('CN9_TIPREV','')
	//Remoção da justificativa
	oModelCN9:LoadValue('CN9_JUSTIF','')
	oModelCN9:LoadValue('CN9_CODJUS','')
EndIf

If !lAlterRev
	// Salva valores originais da tabela cnb
	A300CNBOri(oModel)
EndIf

//Bloqueio total dos modelos
If lBlock
	MtBCMod(oModel,aModels,{||.T.})
Else
	MtBCMod(oModel,aModels,{||.F.})
EndIf

// Liberar Para Todos os tipos de revisao
oStruCN9:SetProperty("CN9_JUSTIF",MODEL_FIELD_WHEN,{||.T.})
oStruCN9:SetProperty("CN9_AUTO"	 ,MODEL_FIELD_WHEN,{||.T.})
oStruCN9:SetProperty("CN9_TIPREV",MODEL_FIELD_WHEN,{||!lAlterRev})
oStruCN9:SetProperty("CN9_ARRAST",MODEL_FIELD_WHEN,{||.T.})

//-- Posiciona no edital para ver se esta definido o campo de fusão
CO1->(dbSetOrder(1))
If CO1->(dbSeek(xFilial("CO1")+CN9->(CN9_CODED+CN9_NUMPR)))
	If CO1->CO1_FUSAO = "1"
		lFusao   := .T.
	EndIf
EndIf

// Habilita a alteração do fornecedor quando o edital permitir fusão, cisão e incorporação de empresas
If  lFusao .And. (A300GTpRev() == DEF_REV_FORCL .Or. A300GTpRev() == DEF_REV_ABERT)
	oStruCNC:SetProperty("CNC_CODIGO"	,MODEL_FIELD_WHEN,{||.T.})
	oStruCNC:SetProperty("CNC_LOJA"		,MODEL_FIELD_WHEN,{||.T.})
	oStruCNC:SetProperty("CNC_NOME"		,MODEL_FIELD_WHEN,{||.T.})
EndIf

If (A300GTpRev() == DEF_REV_FORCL .Or. A300GTpRev() == DEF_REV_ABERT)
	CNTA300BlMd(oModelCNA,,.T.)
	CNTA300BlMd(oModelCNB,.T.)
EndIf

A300SUsrBt(.F.)
RestArea(aArea)

If lAlterRev
	A300Revisa(oModel, A300GTpRev())
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300Revisa()
Função responsável pelo controle das revisões.

@author guilherme.pimentel
@since 21/01/2014
@version 1.0

|-------------------------------------------------------------------------------	|
|Ex: Para cada revisão deverá ser liberado determinados campos de alguns modelos	|
|Para isso iremos liberar o campo na revisão desejada, segue exemplo				|
|																							|
|  ***Não é necessário liberar os campos de justificativa e tipo de revisão***		|
|																							|
|Local oStruCNB := oModel:GetModel("CNBDETAIL"):GetStruct()							|
|If A300GTpRev() == DEF_REV_ADITI														|
|	oStruCNB:SetProperty("CNB_PRODUT",MODEL_FIELD_WHEN,{||.T.})						|
|	oStruCNB:SetProperty("CNB_DESCRI",MODEL_FIELD_WHEN,{||.T.})						|
|EndIf																						|
|																							|
|Assim desbloquearemos somente o determinado campo da estrutura						|
|-------------------------------------------------------------------------------	|
/*/
//-------------------------------------------------------------------
Function A300Revisa(oModel, cTpRev)
Local oStruCN9 	:= oModel:GetModel('CN9MASTER'):GetStruct()
Local oStruCNA 	:= oModel:GetModel('CNADETAIL'):GetStruct()
Local oStruCNC 	:= oModel:GetModel('CNCDETAIL'):GetStruct()
Local oModelCN9	:= oModel:GetModel('CN9MASTER')
Local oView		:= FwViewActive()
Local aCampos  	:= {}
Local aUsrCpo	:= {}
Local aCTBEnt	:= {}
Local aModels  	:= MtGetAllMd({"CALC_CNS","CALC_CNF"})
Local aMdDelLine:= MtGetAllMd({"CN9MASTER","CALC_CNS","CALC_CNF"})
Local lFixo	   	:= Cn300RetSt("FIXO")
Local lAlterRev	:= oModel:GetOperation() == MODEL_OPERATION_UPDATE .And. !Empty(A300GTpRev())
Local lFusao   	:= .F.
Local cTipRev	:= 	A300GTpRev()
Local nX		:= 0
Local cCodTpRev	:= oModel:GetValue('CN9MASTER','CN9_TIPREV')

//Bloqueio total dos modelos
MtBCMod(oModel,aModels,{||.F.})

//Bloqueio os modelos para não permitir deletar as linhas.
If cTipRev <> DEF_REV_ADITI .And. cTipRev <> DEF_REV_REAJU .And. cTipRev <> DEF_REV_REALI ;
 	.And. cTipRev <> DEF_REV_READE .And. cTipRev <> DEF_REV_RENOV .And. cTipRev <> DEF_REV_ORCGS .And. cTipRev <> DEF_REV_ABERT // .And.  cTipRev <> DEF_REV_FORCL
	For nX := 1 to Len(aMdDelLine)
		CNTA300BlMd(oModel:GetModel(aMdDelLine[nX]),.T.)
	Next nX
EndIf

// Liberar Para Todos os tipos de revisao
oStruCN9:SetProperty("CN9_JUSTIF",MODEL_FIELD_WHEN,{||.T.})
oStruCN9:SetProperty("CN9_TIPREV",MODEL_FIELD_WHEN,{||!lAlterRev})
oStruCN9:SetProperty("CN9_ARRAST",MODEL_FIELD_WHEN,{||.T.})

//-- Ponto de Entrada para liberação de campos do usuário na revisão do contrato.
If ExistBlock("A300USRF")
	aUsrCpo := ExecBlock("A300USRF",.F.,.F.,{cTipRev})
	A300CpoUsr(@aUsrCpo)
Else //- Caso não exista ponto de entrada, todos campos do usuario devem ser liberados.
	If __aUsrCpo == Nil
		__aUsrCpo := CnGetUsrCp( oModel )
	EndIf
	aUsrCpo := __aUsrCpo
EndIf

If Len(aUsrCpo) > 0
	MtBCMod(oModel,aUsrCpo,{||.T.},'2')
EndIf

//-- Posiciona no edital para ver se esta definido o campo de fusão
CO1->(dbSetOrder(1))
If CO1->(dbSeek(xFilial("CO1")+CN9->(CN9_CODED+CN9_NUMPR)))
	If CO1->CO1_FUSAO = "1"
		lFusao   := .T.
	EndIf
EndIf

If cTipRev == DEF_REV_ADITI
	cn300EspVld(oModel,cTpRev)
	CN300VdArr()
	A300RevCtb(oModel)

	// Partes Envolvidas do Contrato
	aCampos := {}
	aAdd(aCampos,{'CXIDETAIL',{'CXI_TIPO','CXI_CODCLI','CXI_LOJACL','CXI_NOMCLI','CXI_FILRES','CXI_DESFIL','CXI_PERRAT'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')

ElseIf cTipRev == DEF_REV_REAJU

	If !A300GUsrBt() // Reajuste ja executado.

		If	A300ApReRet(cCodTpRev)
			MtBCMod(oModel,{ {"CN9MASTER",{"CN9_DTREAJ","CN9_DREFRJ","CN9_DTRRDE","CN9_DTRRAT"}} },{||.T.},'2')
			oModel:getModel("CN9MASTER"):ClearField('CN9_DTRRDE')
			oModel:getModel("CN9MASTER"):ClearField('CN9_DTRRAT')
		Else
		    MtBCMod(oModel,{ {"CN9MASTER",{"CN9_DTREAJ","CN9_DREFRJ"}} },{||.T.},'2')
		EndIf

		If !IsInCallStack('CN300REAJU')
			oModel:getModel("CN9MASTER"):LoadValue('CN9_DTREAJ',dDataBase)
		EndIf

	EndIf

	A300RevCtb(oModel)

ElseIf cTipRev == DEF_REV_REALI
	aCampos := {}
	If lFixo
		If	A300ApReRet(cCodTpRev)
			aAdd(aCampos,{'CN9MASTER',{'CN9_CONDPG','CN9_DESCPG','CN9_ARRAST','CN9_REDVAL', 'CN9_QTDPAR','CN9_TPCRON', 'CN9_CSLD', 'CN9_MPLA', 'CN9_CPARCA', 'CN9_CPARCV','CN9_DREFRJ','CN9_DTRRDE','CN9_DTRRAT'}})
			oModel:getModel("CN9MASTER"):ClearField('CN9_DTRRDE')
			oModel:getModel("CN9MASTER"):ClearField('CN9_DTRRAT')
		Else
			aAdd(aCampos,{'CN9MASTER',{'CN9_CONDPG','CN9_DESCPG','CN9_ARRAST','CN9_REDVAL', 'CN9_QTDPAR','CN9_TPCRON', 'CN9_CSLD', 'CN9_MPLA', 'CN9_CPARCA', 'CN9_CPARCV','CN9_DREFRJ'}})
		EndIf

		aAdd(aCampos,{'CNBDETAIL',{'CNB_REALI','CNB_DTREAL','CNB_VLUNIT','CNB_VLTOT','CNB_VLTOTR','CNB_DESC','CNB_VLDESC','CNB_CONTA','CNB_ITEMCT','CNB_CC','CNB_CLVL' }})
		aAdd(aCampos,{'CNFDETAIL',{'CNF_COMPET','CNF_VLPREV','CNF_DTVENC','CNF_PRUMED','CNF_TXMOED','CNF_CONDPG', 'CNF_SALDO'}})
		aAdd(aCampos,{'CNTDETAIL',{'CNT_VLRET' }})
		aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
		MtBCMod(oModel,aCampos,{||.T.},'2')
		CN300VdCrf(oModel)
		CN300VdArr()
	Else
		aAdd(aCampos,{'CN9MASTER',{'CN9_CONDPG','CN9_DESCPG'}})

		If Cn300RetSt("PREVFINANC")
			aAdd(aCampos,{'CNADETAIL',{'CNA_VLTOT'}})
		EndIf

		If Cn300RetSt("SEMIPROD")
			aAdd(aCampos,{'CNBDETAIL',{'CNB_REALI','CNB_DTREAL','CNB_VLUNIT','CNB_VLTOT','CNB_VLTOTR','CNB_DESC','CNB_VLDESC','CNB_CONTA','CNB_ITEMCT','CNB_CC','CNB_CLVL' }})
			aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
		ElseIf Cn300RetSt('SEMIAGRUP')
			aAdd(aCampos,{'CXMDETAIL',{'CXM_VLMAX','CXM_CC'}})
		EndIf
		
		MtBCMod(oModel,aCampos,{||.T.},'2')
	EndIf

	A300RevCtb(oModel)
	CN300CNZVD(oModel)
	CNTA300BlMd(oModel:GetModel("CNBDETAIL"),.T.,.T.)

ElseIf cTipRev == DEF_REV_READE
	aCampos := {}
    aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL'}})
	aAdd(aCampos,{'CNBDETAIL',{'CNB_VLTOT','CNB_DESC','CNB_VLDESC','CNB_QTREAD','CNB_SLDMED','CNB_SLDREC'}})
	If !CN300RetSt('SEMIPROD') .And. !CN300RetSt('SERVIÇO')
		aAdd(aCampos,{'CNBDETAIL',{'CNB_QUANT'}})
	EndIf
	MtBCMod(oModel,aCampos,{||.T.},'2')
	CN300VdCrf(oModel)
	CN300CNZVD(oModel)

ElseIf cTipRev == DEF_REV_PARAL
	aCampos := {}
	aAdd(aCampos,{'CN9MASTER',{'CN9_MOTPAR','CN9_DESMTP','CN9_DTFIMP'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')

ElseIf cTipRev == DEF_REV_REINI
	oModel:GetModel("CN9MASTER"):LoadValue('CN9_DTREIN',dDataBase)
	aCampos := {}
	aAdd(aCampos,{'CNFDETAIL',{'CNF_COMPET','CNF_VLPREV','CNF_SALDO', 'CNF_DTVENC', 'CNF_PRUMED', 'CNF_TXMOED', 'CNF_CONDPG'}})
	aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL','CN9_QTDPAR', 'CN9_TPCRON'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')
	CN300VdCrf(oModel)
	A300RevCtb(oModel)

ElseIf cTipRev == DEF_REV_CLAUS		//Revisão de cláusulas
	oStruCN9:SetProperty('CN9_ALTCLA',MODEL_FIELD_WHEN,{||.T.})

ElseIf cTipRev == DEF_REV_CONTA
	CNLibConta(oModel)

ElseIf cTipRev == DEF_REV_INDIC
	aCampos := {}
	aAdd(aCampos,{'CN9MASTER',{'CN9_INDICE','CN9_INDDES','CN9_PERI','CN9_UNPERI','CN9_MODORJ','CN9_PRORAT'}})
	aAdd(aCampos,{'CNADETAIL',{'CNA_INDICE','CNA_PERI','CNA_UNPERI','CNA_MODORJ','CNA_PRORAT', 'CNA_PROXRJ'}})
	aAdd(aCampos,{'CNBDETAIL',{'CNB_INDICE','CNB_MODORJ'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')
	CNTA300BlMd(oModel:GetModel("CNADETAIL"),.T.,.T.)
	CNTA300BlMd(oModel:GetModel("CNBDETAIL"),.T.,.T.)

ElseIf cTipRev == DEF_REV_FORCL

	CNLibForCl(oModel,lFusao)

ElseIf cTipRev == DEF_REV_GRAPR								//= Revisão de grupo de aprovador
	aCampos := {}
	aAdd(aCampos,{'CN9MASTER',{'CN9_GRPAPR','CN9_APROV'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')

ElseIf cTipRev == DEF_REV_RENOV	//= Renovação
	Cn300EspVld(oModel,cTpRev)
	Cn300VdArr()
	A300RevCtb(oModel)

	// Partes Envolvidas do Contrato
	aCampos := {}
	aAdd(aCampos,{'CXIDETAIL',{'CXI_TIPO','CXI_CODCLI','CXI_LOJACL','CXI_NOMCLI','CXI_FILRES','CXI_DESFIL','CXI_PERRAT'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')

	//- Agrupadores
	If Cn300RetSt('SEMIAGRUP')
		aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRGRP','CXM_AGRCAT','CXM_VLMAX'}})
		MtBCMod(oModel,aCampos,{||.T.},'2')
	Endif

ElseIf cTipRev == DEF_REV_MULBON // Multa e Bonificação
	aCampos := {}
	aAdd(aCampos,{'CNHDETAIL',{'CNH_CODIGO','CNH_DESCRI','CNH_AVALIA'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')
	CNTA300BlMd(oModel:GetModel("CNHDETAIL"),.F.,.F.)

ElseIf cTipRev == DEF_REV_ORCGS //= Orçamento de Serviço GS
	Cn300EspVld(oModel,cTpRev)
	Cn300VdArr()
	A300RevCtb(oModel)

	//-- Parâmetro que permite revisão de caução
	If SuperGetMV("MV_CNRVCAU",.F.,.F.)
		//-- Somente libera o percentual de caução caso a flag esteja como 1=SIM
		aAdd(aCampos,{'CN9MASTER',{'CN9_MINCAU'}})
		MtBCMod(oModel,aCampos,{||FwFldGet('CN9_FLGCAU') == '1'},'2')
		aCampos := {}
	EndIf	
	
	aAdd(aCampos,{'CNADETAIL',{'CNA_NUMERO','CNA_DTFIM'}})
	aAdd(aCampos,{'CNBDETAIL',{'CNB_NUMERO','CNB_ITEM', 'CNB_TS','CNB_IDPED','CNB_CC'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')

ElseIf cTipRev == DEF_REV_CAUCA								//= Revisão de caução
	aAdd(aCampos,{'CN9MASTER',{'CN9_MINCAU'}})
	MtBCMod(oModel,aCampos,{||.T.},'2')
	oModel:LoadValue('CN9MASTER','CN9_FLGCAU','1')
	oModel:LoadValue('CN9MASTER','CN9_TPCAUC','1')

ElseIf cTipRev == DEF_REV_ABERT		//Revisão Aberta

	CNLibConta(oModel)	//Libera campos relacionados ao contábel
	Cn300EspVld(oModel,cTpRev)
	CN300VdCrf(oModel)
	A300RevCtb(oModel)	
	Cn300VdArr()
	
	If CNTGetFun() == 'CNTA300'
		oStruCNC:SetProperty('CNC_CODIGO',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
		oStruCNC:SetProperty('CNC_LOJA',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
		oStruCNC:SetProperty('CNC_NOME',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
		oStruCNA:SetProperty('CNA_FORNEC',	MODEL_FIELD_WHEN,{||.T.})
		oStruCNA:SetProperty('CNA_LJFORN',	MODEL_FIELD_WHEN,{||.T.})
	Else
		oStruCNC:SetProperty('CNC_CLIENT',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
		oStruCNC:SetProperty('CNC_LOJACL',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
		oStruCNC:SetProperty('CNC_NOMECL',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
		oStruCNA:SetProperty('CNA_CLIENT',	MODEL_FIELD_WHEN,{||.T.})
		oStruCNA:SetProperty('CNA_LOJACL',	MODEL_FIELD_WHEN,{||.T.})
	EndIf
	
	aCampos := {}
	
	aAdd(aCampos,{'CN9MASTER',{'CN9_INDICE','CN9_INDDES','CN9_PERI','CN9_UNPERI','CN9_MODORJ','CN9_PRORAT','CN9_VIGE','CN9_FLGREJ'}})
	aAdd(aCampos,{'CNADETAIL',{'CNA_FLREAJ','CNA_INDICE','CNA_PERI','CNA_UNPERI','CNA_MODORJ','CNA_PRORAT', 'CNA_PROXRJ'}})
	aAdd(aCampos,{'CNBDETAIL',{'CNB_INDICE','CNB_MODORJ'}})
	
	aAdd(aCampos,{'CNADETAIL',{'CNA_DESCPL'}})
	aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL','CN9_QTDPAR', 'CN9_TPCRON','CN9_ALTCLA','CN9_OBJCTO','CN9_GRPAPR','CN9_APROV','CN9_DEPART','CN9_GESTC','CN9_DESC', 'CN9_DESCRI'}})
	aAdd(aCampos,{'CN9MASTER',{'CN9_MOTPAR','CN9_DESMTP','CN9_DTFIMP'}})
	
	If oModelCN9:GetValue('CN9_FLGCAU') == '1' .And. oModelCN9:GetValue('CN9_TPCAUC') == '1'		
		aAdd(aCampos,{'CN9MASTER',{'CN9_MINCAU'}})
	ElseIf oModelCN9:GetValue('CN9_FLGCAU') == '2'
		aAdd(aCampos,{'CN9MASTER',{'CN9_MINCAU','CN9_FLGCAU', 'CN9_TPCAUC'}})
	EndIf
	
	aAdd(aCampos,{'CNFDETAIL',{'CNF_NUMERO','CNF_PARCEL','CNF_COMPET','CNF_VLPREV','CNF_VLREAL','CNF_SALDO', 'CNF_DTVENC', 'CNF_PRUMED', 'CNF_TXMOED', 'CNF_CONDPG'}})
	
	aAdd(aCampos,{'CXIDETAIL',{'CXI_TIPO','CXI_CODCLI','CXI_LOJACL','CXI_NOMCLI','CXI_FILRES','CXI_DESFIL','CXI_PERRAT'}})
	
	aAdd(aCampos,{'CNBDETAIL',{'CNB_ITEM','CNB_VLTOT','CNB_DESC','CNB_VLDESC','CNB_QTREAD','CNB_SLDMED','CNB_SLDREC'}})
	
	MtBCMod(oModel,aCampos,{||.T.},'2')

	//- Agrupadores
	If Cn300RetSt('SEMIAGRUP')
		aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRGRP','CXM_AGRCAT','CXM_VLMAX'}})
		MtBCMod(oModel,aCampos,{||.T.},'2')
	Endif	
	
	CNTA300BlMd(oModel:GetModel("CNADETAIL"),.F.)
	CNTA300BlMd(oModel:GetModel("CNBDETAIL"),.F.)
		
EndIf

//- Chamada de função para liberação de campos de multiplas naturezas. 
CnRevMNat(oModel)

If oModel:CanSetValue('CN9MASTER','CN9_VIGE')
	oModel:GetModel('CN9MASTER'):GetStruct():SetProperty('CN9_VIGE',MODEL_FIELD_WHEN,{|| FwFldGet("CN9_UNVIGE") != '4'})
EndIf

If !oModel:GetModel("CNADETAIL"):CanUpdateLine()
	oModel:GetModel("CNADETAIL"):SetNoUpdateLine(.F.)
EndIf

If !oModel:GetModel("CNBDETAIL"):CanUpdateLine() .And. (Cn300RetSt('FIXO') .Or. Cn300RetSt('SEMIFIXO'))
	oModel:GetModel("CNBDETAIL"):SetNoUpdateLine(.F.)
EndIf

If Cn300RetSt('SERVIÇO')
	oModel:GetModel("CNBDETAIL"):GetStruct():SetProperty('CNB_QUANT',MODEL_FIELD_OBRIGAT,.F. )
	oModel:GetModel("CNBDETAIL"):GetStruct():SetProperty('CNB_QUANT',MODEL_FIELD_WHEN,{||.F.})
EndIf

//-- Ponto de Entrada para liberação dos Modelos para edição, de acordo com a Revisão que deseja customizar
If ExistBlock("A300MLDR")
	// Passa o tipo de Revisão e o Modelo
	ExecBlock("A300MLDR",.F.,.F.,{cTipRev,oModel})
EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300ModQr()
Não permite que modelos sem o campo revisao, seja duplicado na revisão

@author alexandre.gimenez
@since 21/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function cn300ModQr(oModel)
Local aModels := {'CNK','CNX','CNU','CNI','CPD','CNN','CNT','CNG','AGW'}
Local nX := 0

For nX := 1 to Len(aModels)
	oModel:GetModel(aModels[nX]+'DETAIL'):SetOnlyQuery(.T.)
Next nX

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300vldtpr()
Validação do tipo da revisão

@author
@since
@version 1.0
/*/
//-------------------------------------------------------------------
Function cn300VldTpR()
Local oModel	:= FwModelActive()
Local oView	:= FwViewActive()
Local oModCN9	:= oModel:GetModel("CN9MASTER")
Local cTipRev	:= oModCN9:GetValue("CN9_TIPREV")
Local aArea 	:= GetArea()
Local lRet		:= .F.

DbSelectArea("CN0")
CN0->(DbSetOrder(1))

//Validação de tipo de contrato X tipo de revisão
If CN0->(DbSeek(xFilial("CN0")+cTipRev))
	lRet := CN0->CN0_TIPO == A300GTpRev()
EndIf

//Verificação se acontecerá refresh dos valores
If lRet .And. A300GRevis() .And. MsgYesNo(STR0022)	//"A alteração impactará na oerda dos dados, deseja continuar?"

    //-- Trecho alterado por instruções do FrameWork 
	A300IniRev(oModel,.T.)
	oModel:Deactivate()
   	oModel:nOperation := 3
 	oModel:Activate(.T.)   
    oModCN9:LoadValue("CN9_TIPREV",cTipRev)
    A300IniRev(oModel,.F.)
	If ValType(oView) == "O" .And. oView:IsActive()
		oView:Refresh()
	EndIf
EndIf

//Função de controle das revisões
If lRet
	A300Revisa(oModel,cTipRev)
	A300SRevis(.T.)
EndIf

RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} cnFilRev(cContra,cRev)
Função para filtrar consulta padrao dependo do tipo de revisao

@author alexandre.gimenez
@since 23/01/2014
@version 1.0
@return lRet
/*/
//-------------------------------------------------------------------
Function cnFilRev()
Local lRet := Nil

If Empty(A300GTpRev())
	lRet := .T.
Else
	lRet := CN0->CN0_TIPO == A300GTpRev()
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300IniApr()
Inicializaçao do processo da aprovação

@author aline.sebrian
@since 20/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300IniApr(oModel)
Local aModels	:= MTGetAllMd({"CALC_CNS","CALC_CNF"})
Local oModelCN9	:= oModel:GetModel('CN9MASTER')
Local oStruCN9 	:= oModelCN9:GetStruct()

If oModel:GetOperation() == MODEL_OPERATION_INSERT  .OR. oModel:GetOperation() == MODEL_OPERATION_UPDATE
	If A300GATpRv() == DEF_REV_PARAL .Or. (A300GATpRv() == DEF_REV_ABERT .And. !Empty(oModelCN9:GetValue('CN9_MOTPAR')) .And. Empty(oModelCN9:GetValue('CN9_DTREIN')))
		oModelCN9:SetValue('CN9_SITUAC','06')	//Atualização da Situação "Paralisado"
	Else
		oModelCN9:SetValue('CN9_SITUAC','05')	//Atualização da Situação "Vigente"
	EndIf

	//-- Atualizaça retencao de caução retida em revisão de reajuste ou realinhamento.
	A300AtCauR(oModel)
	oStruCN9:SetProperty('*',MODEL_FIELD_WHEN,{||.F.}) 	//Desabilita os campos do contrato

	//Bloqueio total dos modelos
	MtBCMod(oModel,aModels,{||.F.})
EndIf
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300ApArF
Função que aplica o arrasto no cronograma fisico e automaticamente
no financeiro

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300ApArF(oModel)
Local aSaveLines := FWSaveRows()
Local oCN9Master := oModel:GetModel('CN9MASTER')
Local oCNFDetail := oModel:GetModel('CNFDETAIL')
Local oCNADetail := oModel:GetModel('CNADETAIL')
Local oCNSDetail := oModel:GetModel('CNSDETAIL')
Local oStruCNF 	 := oModel:GetModel('CNFDETAIL'):GetStruct()

Local lRedVlrs	 := oCN9Master:GetValue('CN9_REDVAL') == '1'
Local lIncParcs	 := oCN9Master:GetValue('CN9_TPCRON') == '1'

Local nI			:= 0
Local nI2			:= 0
Local nI3			:= 0 
Local nRound		:= TamSX3('CNS_PRVQTD')[2]
Local nDifArr		:= 0
Local nSldDist	:= 0
Local nQuant		:= 0

Local aNewSlds	:= {}
Local aProd		:= {}
Local aLinhas 	:= {}
Local aItens		:= {}
Local aSld		:= {}
Local nSaldo := 0 

//-- Libera os campos do cronograma Financeiro.
oStruCNF:SetProperty("CNF_VLPREV",MODEL_FIELD_WHEN,{||.T.})
oStruCNF:SetProperty("CNF_VLREAL",MODEL_FIELD_WHEN,{||.T.})

For nI := 1 To oCNFDetail:Length()
	oCNFDetail:GoLine(nI)
	If oCNFDetail:IsDeleted()
		Loop
	EndIf

	For nI2 := 1 To oCNSDetail:Length()
		oCNSDetail:GoLine(nI2)

		If oCNSDetail:IsDeleted()
			Loop
		EndIf

		//-- O array aItens guarda o código do produto e o saldo total que será arrastado
		If oCNSDetail:GetValue('CNS_RLZQTD') > 0 .And. oCNSDetail:GetValue('CNS_SLDQTD') > 0
			nPos := aScan(aItens,{|x| x[1] == oCNSDetail:GetValue('CNS_ITEM')})
			//-- Zero o saldo e atualizo a quantidade prevista igual a realizada
			nSaldo := oCNSDetail:GetValue('CNS_DISTSL') + oCNSDetail:GetValue('CNS_SLDQTD')	
			oCNSDetail:SetValue('CNS_PRVQTD', oCNSDetail:GetValue('CNS_RLZQTD'))
			oCNSDetail:LoadValue('CNS_SLDQTD', 0)
		EndIf

		//-- Se não estiver trabalhando com a redistribuição de valores guardo a primeira linha não medida,
		//-- para posteriormente atualiza-la com os valores do arrasto.
		If !lRedVlrs
			If oCNSDetail:GetValue('CNS_RLZQTD') == 0
				nPos := aScan(aProd,{|x| x[1] == oCNSDetail:GetValue('CNS_ITEM')})
				If nPos == 0 .And. oCNSDetail:GetValue('CNS_DISTSL') > 0
					oCNSDetail:SetValue('CNS_PRVQTD', oCNSDetail:GetValue('CNS_PRVQTD') + oCNSDetail:GetValue('CNS_DISTSL'))
					Aadd(aProd, {oCNSDetail:GetValue('CNS_ITEM')})
				EndIF
			EndIf

			//-- Se não, além de guardar todas as linhas não medidas, se faz necessário guardar os valores de todas
			//-- as parcelas para que sejam resdistribuidos.
		ElseIf oCNSDetail:GetValue('CNS_RLZQTD') == 0
			nPos := aScan(aLinhas,{|x| x[1] == oCNSDetail:GetValue('CNS_ITEM')})

			If nPos == 0
				Aadd(aLinhas, {oCNSDetail:GetValue('CNS_ITEM'), 1, {}})
			Else
				aLinhas[nPos, 2]  += 1
			EndIf

			nPos := aScan(aItens,{|x| x[1] == oCNSDetail:GetValue('CNS_ITEM')})
			If nPos == 0
				Aadd(aItens, {oCNSDetail:GetValue('CNS_ITEM'), oCNSDetail:GetValue('CNS_SLDQTD') + If(Ascan(aSld,{|x| Alltrim(x[1]) == oCNSDetail:GetValue('CNS_ITEM')}) == 0, oCNSDetail:GetValue('CNS_DISTSL'), 0)})
			Else
				aItens[nPos, 2]  += oCNSDetail:GetValue('CNS_SLDQTD') + If(Ascan(aSld,{|x| Alltrim(x[1]) == oCNSDetail:GetValue('CNS_ITEM')}) == 0, oCNSDetail:GetValue('CNS_DISTSL'), 0)
			EndIf

			If Ascan(aSld,{|x| Alltrim(x[1]) == oCNSDetail:GetValue('CNS_ITEM')}) == 0
				Aadd(aSld,{oCNSDetail:GetValue('CNS_ITEM')})
			EndIf

		ElseIf oCNSDetail:GetValue('CNS_RLZQTD') > 0
			//-- O vetor aLinhas (com redistribuição de valores) guarda as linhas que não irei atualizar
			//-- no momento de aplicar o arrasto, ou seja, as parcelas já medidas
			nPos := aScan(aLinhas,{|x| x[1] == oCNSDetail:GetValue('CNS_ITEM')})
			If nPos == 0
				Aadd(aLinhas, {oCNSDetail:GetValue('CNS_ITEM'),0 , {oCNFDetail:GetLine()} })
			Else
				Aadd(aLinhas[nPos, 3], oCNFDetail:GetLine())
			EndIf
		EndIf
	Next nI2
Next nI
If lRedVlrs
	For nI := 1 To Len(aItens)
		nPos 	:= aScan(aLinhas,{|x| x[1] == aItens[nI, 1]})
		nQuant := aItens[nI,2] / aLinhas[nPos,2]
		nDifArr:= aItens[nI,2] - (Round(nQuant,nRound) * aLinhas[nPos,2])

		For nI2 := 1 To oCNFDetail:Length()
			oCNFDetail:GoLine(nI2)
			If Ascan(aLinhas[nPos, 3], oCNFDetail:GetLine()) == 0
				For nI3 := 1 To oCNSDetail:Length()
					oCNSDetail:GoLine(nI3)
					If oCNSDetail:GetValue('CNS_ITEM') == aItens[nI, 1]
						If nI2 == oCNFDetail:Length()
							oCNSDetail:SetValue('CNS_PRVQTD', Round(nQuant, nRound) + nDifArr)
						Else
							oCNSDetail:SetValue('CNS_PRVQTD', Round(nQuant, nRound))
						EndIf
					EndIf
				Next nI3
			EndIf
		Next nI2

	Next nI
EndIf


//-- Atualiza o Financeiro
A300FscTFn(oModel)

oStruCNF:SetProperty("CNF_VLPREV",MODEL_FIELD_WHEN,{||.F.})
oStruCNF:SetProperty("CNF_VLREAL",MODEL_FIELD_WHEN,{||.F.})

FWRestRows(aSaveLines)
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CN300RevPd
Tratamentos no pedido de compra/venda

@param oModel Modelo de dados ativo

@author guilherme.pimentel
@since 06/03/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------
Function CN300RevPd(oModel)
Local lRet := A300RevMed()
Local cQuery := ''
Local aItAtd := {}
Local cContra	:= oModel:GetValue('CN9MASTER','CN9_NUMERO')
Local cRevisa := oModel:GetValue('CN9MASTER','CN9_REVISA')

If lRet
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Retorna total dos itens medidos mas nao recebidos    ³
	//³ antes da data de inicio do reajuste                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cQuery := "SELECT CNE.CNE_NUMERO, CNE.CNE_ITEM, CNE.CNE_QUANT "
	cQuery += "  FROM "+RetSQLName("CNE")+" CNE,"+RetSQLName("CND")+" CND"
	cQuery += " WHERE CNE.CNE_FILIAL = '"+xFilial("CNE")+"'"
	cQuery += "   AND CND.CND_FILIAL = '"+xFilial("CND")+"'"
	cQuery += "   AND CNE.CNE_CONTRA = '"+cContra+"'"
	cQuery += "   AND CNE.CNE_REVISA = '"+cRevisa+"'"
	If !Empty(oModel:GetValue('CN9MASTER','CN9_DTREAJ'))
		cQuery += "   AND CND.CND_DTFIM  >= '"+DTOS(oModel:GetValue('CN9MASTER','CN9_DTREAJ'))+"'"
	EndIf
	cQuery += "   AND "
	If Cn300RetSt("COMPRA")
		cQuery += "   (SELECT SUM(SC7.C7_QUJE) AS C7_QUJE "
		cQuery += "      FROM "+RetSQLName("SC7")+" SC7 "
		cQuery += "     WHERE SC7.C7_MEDICAO = CND.CND_NUMMED "
		cQuery += "       AND SC7.C7_FILIAL = '"+xFilial("SC7")+"'"
		cQuery += "       AND SC7.D_E_L_E_T_ = ' ') = 0 "
	Else
		cQuery += "(SELECT SUM(SC6.C6_QTDENT) AS C6_QTDENT FROM " +RetSQLName("SC6")+ " SC6 "
		cQuery += " Join " +RetSQLName("SC5")+ " SC5 ON SC5.C5_NUM = SC6.C6_NUM "
		cQuery += " WHERE SC5.C5_FILIAL = '"+ xFilial("SC5") +"' AND SC6.C6_FILIAL = '"+ xFilial("SC6")+"'"
		cQuery += " AND SC5.C5_MDNUMED = CND.CND_NUMMED AND SC5.D_E_L_E_T_ = ''  AND SC6.D_E_L_E_T_ = '' ) = 0"
	EndIf
	cQuery += "   AND CNE.CNE_CONTRA = CND.CND_CONTRA "
	cQuery += "   AND CNE.CNE_REVISA = CND.CND_REVISA "
	cQuery += "   AND CNE.CNE_NUMMED = CND.CND_NUMMED "
	cQuery += "   AND CNE.D_E_L_E_T_ = '' "
	cQuery += "   AND CND.D_E_L_E_T_ = '' "

	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCND",.F.,.T.)

	While !TRBCND->(Eof())
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Preenche array com os itens medidos que ainda nao    ³
		//³ possuem entrada                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nx := aScan(aItAtd,{|x| x[1,1] = TRBCND->CNE_NUMERO})
		If nx == 0
			aAdd(aItAtd,{})
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Estrutura do aItAtd                                  ³
		//³ aItAtd[x][1] - Numero da planilha                    ³
		//³ aItAtd[x][2] - Item da medicao                       ³
		//³ aItAtd[x][3] - Quantidade medida                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aAdd(aItAtd[len(aItAtd)],{TRBCND->CNE_NUMERO,TRBCND->CNE_ITEM,TRBCND->CNE_QUANT})
		TRBCND->(dbSkip())
	EndDo

	TRBCND->(dbCloseArea())

	//³ Seleciona planilhas que permitem reajuste            ³
	cQuery := " SELECT CNA.CNA_NUMERO,CNA.CNA_FLREAJ,CNA.R_E_C_N_O_ as RECNO "
	cQuery += " FROM "+RetSQLName("CNA")+" CNA "
	cQuery += " WHERE CNA.CNA_FILIAL  = '"+xFilial("CNA")+"'"
	cQuery += " AND CNA.CNA_CONTRA  = '"+cContra+"'"
	cQuery += " AND CNA.CNA_REVISA  = '"+cRevisa+"'"
	cQuery += " AND CNA.D_E_L_E_T_ <> '*'"

	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCNA",.F.,.T.)

	While !TRBCNA->(Eof())
		If  A300GATpRv() == DEF_REV_REALI .Or. ( TRBCNA->CNA_FLREAJ == '1' .And.  A300GATpRv() == DEF_REV_REAJU)
			//³ Seleciona medicoes nao zeradas e nao recebidas       ³
			cQuery := "SELECT CND.R_E_C_N_O_ as RECNO,CND.CND_NUMMED "
			cQuery += "  FROM "+RetSQLName("CND")+" CND "
			cQuery += " WHERE CND.CND_FILIAL = '"+xFilial("CND")+"'"
			If !Empty(oModel:GetValue('CN9MASTER','CN9_DTREAJ'))
				cQuery += "   AND CND.CND_DTFIM >= '"+DTOS(oModel:GetValue('CN9MASTER','CN9_DTREAJ'))+"'"
			EndIf
			cQuery += "   AND CND.CND_NUMERO IN('"+TRBCNA->CNA_NUMERO+"','"+ space(TAMSX3("CND_NUMERO")[1]) +"')"
			cQuery += "   AND CND.CND_CONTRA = '"+cContra+"'"
			cQuery += "   AND CND.CND_REVISA = '"+cRevisa+"'"
			cQuery += "   AND CND.CND_ZERO   = '2'"
			cQuery += "   AND "
			If Cn300RetSt("COMPRA")
				cQuery += "   (SELECT SUM(SC7.C7_QUJE) AS C7_QUJE "
				cQuery += "      FROM "+RetSQLName("SC7")+" SC7 "
				cQuery += "     WHERE SC7.C7_MEDICAO = CND.CND_NUMMED "
				cQuery += "       AND SC7.C7_FILIAL = '"+xFilial("SC7")+"'"
				cQuery += "       AND SC7.D_E_L_E_T_ = ' ') = 0 "
				cQuery += " AND "
			Else
				cQuery += "(SELECT SUM(SC6.C6_QTDENT) AS C6_QTDENT FROM " +RetSQLName("SC6")+ " SC6 "
				cQuery += " Join " +RetSQLName("SC5")+ " SC5 ON SC5.C5_NUM = SC6.C6_NUM "
				cQuery += " WHERE SC5.C5_FILIAL = '"+ xFilial("SC5") +"' AND SC6.C6_FILIAL = '"+ xFilial("SC6")+"'"
				cQuery += " AND SC5.C5_MDNUMED = CND.CND_NUMMED AND SC5.D_E_L_E_T_ = ''  AND SC6.D_E_L_E_T_ = '' ) = 0"
				cQuery += " AND "
			EndIf
			cQuery += "CND.D_E_L_E_T_ = ' '"

			cQuery := ChangeQuery(cQuery)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBCND",.F.,.T.)

			While !TRBCND->(Eof())
				CND->(dbGoTo(TRBCND->RECNO))
				If IsNewMed(cContra,cRevisa,TRBCND->CND_NUMMED) //Verifica se a medição foi gerada pela rotina CNTA121
					lRet := CN121Estorn(.T.,.T.)	//- Executa o estorno da medição.
					//- Atualiza CNE_VLLIQD
					If CNE->(Columnpos('CNE_VLLIQD')) > 0
						Cn300AtLiq(TRBCND->CND_NUMMED,cContra,cRevisa,.T.)
					EndIf
					lRet := CN121Encerr(.T.,.T.)	//- Executa o encerramento da medição.
				Else
					lRet := CN120Estor("CND",TRBCND->RECNO,7,.T.)
					//- Atualiza CNE_VLLIQD
					If CNE->(Columnpos('CNE_VLLIQD')) > 0
						Cn300AtLiq(TRBCND->CND_NUMMED,cContra,cRevisa,.F.)
					EndIf
					lRet := CN120Ence("CND",TRBCND->RECNO,6,.T.)
				EndIf
				TRBCND->(dbSkip())
			End
			TRBCND->(dbCloseArea())
		EndIf
		TRBCNA->(dbSkip())
	EndDo
	TRBCNA->(dbCloseArea())
EndIf

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN300ClDt
Função recursiva para calcular o valor a ser redistribuido

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300ClDt(oCNFDetail, nSldADis, nMont ,nDescParc, aLinhas)
Local nI 			:= 0
Local aSaveLines	:= FWSaveRows()
Local nVlrDesc    := 0

For nI := 1 To oCNFDetail:Length()
	oCNFDetail:GoLine(nI)
	If Ascan(aLinhas, oCNFDetail:GetLine()) == 0
		If oCNFDetail:GetValue('CNF_VLREAL') > nSldADis
			nDescParc := nDescParc + 1
			nVlrDesc  := nVlrDesc + oCNFDetail:GetValue('CNF_VLPREV')
			Aadd(aLinhas, oCNFDetail:GetLine())
			nSldADis := (nMont - nVlrDesc) / (oCNFDetail:Length(.T.) - nDescParc)
			CN300ClDt(oCNFDetail, @nSldADis, nMont,@nDescParc, @aLinhas)
		EndIf
	EndIf
Next nI

FWRestRows(aSaveLines)
Return aLinhas


//-------------------------------------------------------------------
/*/{Protheus.doc} A300OpenMd()
Funcao abrir todo o modelo e fazer processamento e bloquear novamente.

@author alexandre.gimenez
@since 14/03/2014
@version 1.0
/*/
//--------------------------------------------------------------------
Function A300OpenMd(bCodeBlock,lClose)
Local oModel	:= FwModelActive()
Local aModels	:= Nil

Default lClose:= .T.

//-- Adicionado todos os modelos de contratos
aModels := {'CN9MASTER','CNCDETAIL','CN8DETAIL','CNIDETAIL','CNADETAIL','CNBDETAIL',;
		     'CNFDETAIL','CNHDETAIL','CNKDETAIL','CNXDETAIL','CNUDETAIL','CPDDETAIL',;
		     'CNZDETAIL','CNSDETAIL','CNNDETAIL','CNVDETAIL','CNWDETAIL','CNTDETAIL','CXMDETAIL'}
//-- Abre o Modelo
MtBCMod(oModel,aModels,{||.T.})
//-- Processa o Bloco Abre o Modelo
If !Empty(bCodeBlock)
	Eval(bCodeBlock)
EndIf
//-- Fecha o Modelo de acordo com a revisao
If lClose
	A300Revisa(oModel,A300GTpRev())
EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} a300refresh(cCampo)
Gatilho para dar refresh na view

@author alexandre.gimenez
@since 14/03/2014
@version 1.0
/*/
//--------------------------------------------------------------------
Function a300refresh(cCampo)
	Local oView		:= FwViewActive()
	Local oModel 	:= FwModelActive()
	Local oModelCNB := Nil
	Local cRet      := Nil

	If ValType(oView) == "O" .And. oView:IsActive() .And. !(oView:GetModel():GetId()=="BROWSE") .And. !IsInCallStack("A300DivCNB") .And. !IsInCallStack("TECA850")
		oView:Refresh()
	EndIf

	If oModel:GetId() == "CNTA300" .and. !Empty(cCampo)
		oModelCNB := oModel:GetModel("CNBDETAIL")
		cRet := oModelCNB:GetValue(cCampo)
	Else
		cRet := FwFldGet(cCampo)
	EndIf

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300AtCauR()
Funcao para atualizar retencao de caução retida em revisão de reajuste
ou realinhamento..

@author alexandre.gimenez
@since 13/03/2014
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function A300AtCauR(oModel)
Local oModCN9	:= oModel:GetModel("CN9MASTER")
Local oModCNT	:= oModel:GetModel("CNTDETAIL")
Local oModCNA	:= oModel:GetModel("CNADETAIL")
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local lCaucaoR:= oModCN9:GetValue("CN9_TPCAUC") == '2'
Local nVlrCauc:= oModCN9:GetValue("CN9_MINCAU")
Local cIndice	:= oModCN9:GetValue("CN9_INDICE")
Local cDataRef	:= oModCN9:GetValue("CN9_DREFRJ")
Local lCnRevMd	:= SuperGetMV("MV_CNREVMD",.F.,.T.)
Local nX		:= 0
Local nVlrReaj:= 0
Local nVLrRetC:= 0
Local nPos		:= 0
Local lRevMed	:= A300RevMed()
Local aMed		:= Nil
Local aVLrRetC:={}
Local lAtualiz:= .F.
Local lFixo	:= Cn300RetSt("FIXO",2)
Local nLineCNB:= oModCNB:GetLine()

If lRevMed .And. lCaucaoR
	If (A300GATpRv() == DEF_REV_REAJU .Or. A300GATpRv() == DEF_REV_REALI)
		aMed := A300SldRec('a2','',.F.)
		lAtualiz := .T.
	ElseIf A300GTpRev() == DEF_REV_REAJU
		aMed := A300SldRec('a2',oModCNB:GetValue("CNB_ITEM"),.T.)
		lAtualiz := .T.
	ElseIf A300GTpRev() == DEF_REV_REALI .Or. A300GTpRev() == DEF_REV_RENOV .Or. A300GTpRev() == DEF_REV_ORCGS
		aMed := A300SldRec('a2','',.T.)
		lAtualiz := .T.
	EndIf
EndIf

If lAtualiz .And. !lFixo .And. (A300GTpRev() == DEF_REV_REALI .Or.  A300GATpRv() == DEF_REV_REALI )
	lAtualiz := .F.
EndIf

If lAtualiz .And. !Empty(aMed)
	DbSelectArea("CND")
	CND->(DbSetOrder(1))
	DbSelectArea("CNE")
	CNE->(DbSetOrder(1))
	DbSelectArea("CNT")
	CNT->(DbSetOrder(1))
	oModCNT:SetNoUpdateLine(.F.)
	For nX := 1 to Len(aMed)
		oModCNT:GoLine(MTFindMVC(oModCNT,{{'CNT_NUMMED',aMed[nX,2]}}))
		//-- Posiciona planilha
		If lFixo
			oModCNA:GoLine(MTFindMVC(oModCNA,{{'CNA_NUMERO',aMed[nX,1]}})) //Posiciona planilha
			//Busca Item
			oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',aMed[nX,3]}})) // Posiciona no Item
			If !Empty(oModCNB:GetValue("CNB_ITMDST")) // o Item foi quebrado, posciona no novo item
				oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',oModCNB:GetValue("CNB_ITMDST")}}))
			EndIf

		EndIf
		If lCnRevMd  .And. empty(A300GTpRev())
			//Busca medicao ja revisada
			If CND->(DbSeek(xFilial('CND')+oModCN9:GetValue("CN9_NUMERO")+oModCN9:GetValue("CN9_REVISA")+aMed[nX,1]+aMed[nX,2]))
				oModCNT:SetValue("CNT_VLRET",CND->CND_RETCAC)
			EndIf
		Else
			//Busca medicao nao revisada ainda
			If CNE->(DbSeek(xFilial('CNE')+oModCN9:GetValue("CN9_NUMERO")+CnRevAnt()+aMed[nX,1]+aMed[nX,2]+aMed[nX,3]))
				If (A300GTpRev() == DEF_REV_REALI .Or.  A300GATpRv() == DEF_REV_REALI )
					nVlrReaj := Round(( oModCNB:GetValue("CNB_VLUNIT") - CNE->CNE_VLUNIT ) * CNE->CNE_QUANT,TamSx3("CNB_VLUNIT")[2] )
					nVLrRetC := Round(nVlrReaj*nVlrCauc/100*(1-(CNE->CNE_PDESC/100)),TamSx3("CNB_VLUNIT")[2])
					If !Empty(aVLrRetC) .And. ( nPos := aScan(aVLrRetC,{|x| x[1] == CNE->CNE_NUMMED  })) > 0
						aVLrRetC[nPos,2] += nVLrRetC
					Else
						aAdd(aVLrRetC,{CNE->CNE_NUMMED,nVLrRetC})
					EndIf
				Else
					nVlrReaj := Round(( CNE->CNE_VLUNIT*A300VlrInd(cIndice,cDataRef) - CNE->CNE_VLUNIT ) * CNE->CNE_QUANT,TamSx3("CNB_VLUNIT")[2] )
					nVLrRetC := Round(nVlrReaj*nVlrCauc/100*(1-(CNE->CNE_PDESC/100)),TamSx3("CNB_VLUNIT")[2])
					oModCNT:SetValue("CNT_VLRET",oModCNT:GetValue("CNT_VLRET")+nVLrRetC)
				EndIf


			EndIf
		EndIf
	Next nX
	If !Empty(aVLrRetC)
		For nX := 1 to Len(aVLrRetC)
			oModCNT:GoLine(MTFindMVC(oModCNT,{{'CNT_NUMMED',aVLrRetC[nX,1]}}))
			If CNT->(DbSeek(xFilial('CNT')+oModCN9:GetValue("CN9_NUMERO")+aVLrRetC[nX,1]))
				oModCNT:SetValue("CNT_VLRET",CNT->CNT_VLRET+aVLrRetC[nX,2])
			EndIf
		Next nX
	EndIf
	oModCNT:SetNoUpdateLine(.T.)
EndIf


Return


//-------------------------------------------------------------------
/*/{Protheus.doc} A300AtuMed()
Funcao para atualizar a medicao conforme reajuste ou realinhamento.

@author alexandre.gimenez
@since 10/03/2014
@version 1.0
/*/
//--------------------------------------------------------------------
Function A300AtuMed(oModel)
Local aArea 	:= GetArea()
Local oModCN9	:= oModel:GetModel("CN9MASTER")
Local oModCNA	:= oModel:GetModel("CNADETAIL")
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local oModCNF 	:= oModel:GetModel("CNFDETAIL")
Local lCnRevMd	:= SuperGetMV("MV_CNREVMD",.F.,.T.)
Local lRevMed 	:= A300RevMed()
Local nX		:= 0
Local nY		:= 0
Local aDados	:= {}
Local lAtualiz	:= .F.
Local cIndice	:= oModCN9:GetValue("CN9_INDICE")
Local cDataRef	:= oModCN9:GetValue("CN9_DREFRJ")
Local lCaucaoR	:= oModCN9:GetValue("CN9_TPCAUC") == '2'
Local nVlrCauc	:= oModCN9:GetValue("CN9_MINCAU")
Local nAtuCauc	:= IIF(Cn300RetSt("COMPRA"),-1,1)
Local cNewItem	:= ''
Local nVlrReaj	:= 0
Local nVLrRetC	:= 0
Local lFixo		:= Cn300RetSt("FIXO",2)
Local lSemiProd	:= Cn300RetSt('SEMIFIXO',2) .And. Cn300RetSt("SEMIPROD",2)
Local nTotAnt	:= 0
Local lCnaUpd	:= oModCNA:CanUpdateLine()
Local lReajMed	:= Cn300RetSt("REVREAJU")

If lRevMed
	If !Empty(A300GATpRv()) .And. (A300GATpRv() == DEF_REV_REAJU .Or. A300GATpRv() == DEF_REV_REALI ) .And. lCnRevMd
		lAtualiz := .T.
	EndIf
EndIf

If lAtualiz .And. !lFixo .And. !lSemiProd .And. (A300GTpRev() == DEF_REV_REALI .Or.  A300GATpRv() == DEF_REV_REALI )
	lAtualiz := .F.
EndIf

If lAtualiz
	DbSelectArea("CND")
	CND->(DbSetOrder(1))
	DbSelectArea("CNE")
	CNE->(DbSetOrder(1))

	aDados := A300SldRec('a2','',.F.)
	If !Empty(aDados)
		CNTA300BlMd(oModCNF,.F.)
		For nX := 1 to Len(aDados)
		//-- Prepara informações do item reajustado/realinhado
			If Empty(aDados[nX,1]) // nao tem planilha
				cNewItem	:= ''
				cIndice	:= oModCN9:GetValue("CN9_INDICE")
			Else // tem planilha
				oModCNA:GoLine(MTFindMVC(oModCNA,{{'CNA_NUMERO',aDados[nX,1]}})) //Posiciona planilha
				If ((A300GTpRev() == DEF_REV_REAJU .And. oModCNA:GetValue("CNA_FLREAJ") == '2') .Or. !A300RevMed(0)) .Or.;
					(Cn300RetSt('SEMIFIXO') .And. Cn300RetSt('SEMIAGRUP')) // não permite reajuste
					Loop
				Endif
				//Busca Item
				oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',aDados[nX,3]}})) // Posiciona no Item
				If !Empty(oModCNB:GetValue("CNB_ITMDST")) // o Item foi quebrado, posciona no novo item
					oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',oModCNB:GetValue("CNB_ITMDST")}}))
				EndIf
				cNewItem := oModCNB:GetValue("CNB_ITEM") // Atualiza Item caso tenha sido quebrado
				cIndice := oModCNB:GetValue("CNB_INDICE") // atualiza indice da planilha
			EndIf

			If CNE->(DbSeek(xFilial('CNE')+oModCN9:GetValue("CN9_NUMERO")+oModCN9:GetValue("CN9_REVISA")+aDados[nX,1]+aDados[nX,2]+aDados[nX,3]))
				nTotAnt := CNE->CNE_VLTOT

				RecLock("CNE",.F.)
					CNE->CNE_ITEM		:= IIF(Empty(cNewItem),CNE->CNE_ITEM,cNewItem)
					CNE->CNE_QTDORI 	:= CNE->CNE_QUANT
					CNE->CNE_VUNORI		:= CNE->CNE_VLUNIT
					If (A300GTpRev() == DEF_REV_REALI .Or.  A300GATpRv() == DEF_REV_REALI )
						CNE->CNE_VLUNIT	:= Round(oModCNB:GetValue("CNB_VLUNIT"),TamSx3("CNB_VLUNIT")[2])
					Else
						CNE->CNE_VLUNIT	:= Round(CNE->CNE_VLUNIT*A300VlrInd(cIndice,cDataRef),TamSx3("CNB_VLUNIT")[2])
					EndIf
					CNE->CNE_VLTOT	:= Round(CNE->CNE_VLUNIT * CNE->CNE_QUANT		,TamSx3("CNB_VLTOT")[2] )
					CNE->CNE_VLDESC	:= Round(CNE->CNE_VLTOT  * CNE->CNE_PDESC / 100	,TamSx3("CNB_VLDESC")[2])
				MsUnlock()

				nVlrReaj := Round(CNE->CNE_VLTOT - nTotAnt , TamSx3("CNB_VLUNIT")[2] )
				nVLrRetC := IIF(lCaucaoR,Round( (nVlrReaj*(nVlrCauc/100))*(1-(CNE->CNE_PDESC/100)) ,TamSx3("CNB_VLUNIT")[2]),0)
			EndIf

			If IsNewMed(oModCN9:GetValue("CN9_NUMERO"),oModCN9:GetValue("CN9_REVISA"),aDados[nX,2])
				CXN->(dbSetOrder(1))
				If CXN->(DbSeek(xFilial('CND')+oModCN9:GetValue("CN9_NUMERO")+oModCN9:GetValue("CN9_REVISA")+aDados[nX,2]+aDados[nX,1]))
					RecLock("CXN",.F.)
					CXN->CXN_VLSALD	+= oModCNA:GetValue('CNA_VLTOT') - oModCNA:GetValue('CNA_SALDO')
					CXN->CXN_VLPREV += nVlrReaj
					CXN->CXN_VLLIQD += nVlrReaj
					CXN->CXN_VLTOT 	+= nVlrReaj
					MsUnlock()
				EndIf
				cPlanilha := SPACE(TAMSX3('CND_NUMERO')[1])
			Else
				cPlanilha := aDados[nX,1]
			EndIf

			If CND->(DbSeek(xFilial('CND')+oModCN9:GetValue("CN9_NUMERO")+oModCN9:GetValue("CN9_REVISA")+cPlanilha+aDados[nX,2]))
				RecLock("CND",.F.)
				CND->CND_VLREAJ	+= nVlrReaj
				CND->CND_VLTOT	+= nVlrReaj + (nVLrRetC*nAtuCauc)
				CND->CND_VLPREV	+= nVlrReaj
				CND->CND_VLLIQD	+= nVlrReaj
				CND->CND_RETCAC	+= nVLrRetC
				CND->CND_VLCONT	:= oModCN9:GetValue("CN9_VLATU")
				MsUnlock()
			EndIf

			//ajusta parcelas do cronograma financeiro e saldo do contrato
			For nY := 1 To oModCNF:Length()
				oModCNF:GoLine(nY)
				If oModCNF:GetValue("CNF_COMPET") == CND->CND_COMPET
					oModCNA:SetNoUpdateLine(.F.)
					IF ( !(A300GTpRev() == DEF_REV_REAJU .And. lFixo) .OR. lReajMed ) .And. !(A300GTpRev() == DEF_REV_REALI .And. lFixo) .And. !Empty(oModCNF:GetValue("CNF_COMPET"))
						oModCNF:LoadValue("CNF_VLREAL",oModCNF:GetValue("CNF_VLREAL")+nVlrReaj)
						oModCNF:LoadValue("CNF_SALDO",oModCNF:GetValue("CNF_SALDO")-nVlrReaj)
					EndIf
					oModCN9:LoadValue("CN9_SALDO",oModCN9:GetValue("CN9_SALDO")-nVlrReaj)
					oModCNA:LoadValue("CNA_SALDO",oModCNA:GetValue("CNA_SALDO")-nVlrReaj)
					Exit
				EndIf
			Next nY
			oModCNA:SetNoUpdateLine(lCnaUpd)
		Next nX
		CNTA300BlMd(oModCNF,.T.)
	EndIf
EndIf

RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} A300FscTFn()
Funcao para atualizar o cronograma financeiro pelo fisico.

@author alexandre.gimenez
@since 10/03/2014
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function A300FscTFn(oModel)
Local nF 		:= 0
Local nS		:= 0
Local nVlrPre	:= 0
Local nVlrRlz	:= 0
Local oModCNS	:= oModel:GetModel("CNSDETAIL")
Local oModCNF	:= oModel:GetModel("CNFDETAIL")
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local aSavelines:= FWSaveRows()

oModCNF:SetNoUpdateLine(.F.)
oModCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})

For nF := 1 To oModCNF:Length()
	oModCNF:Goline(nF)
	If !oModCNF:IsDeleted()
		nVlrPre	:= 0
		nVlrRlz	:= 0
		For nS := 1 To oModCNS:Length()
			oModCNS:GoLine(nS)
			If !oModCNS:IsDeleted()
				nVlrPre += Round(oModCNS:GetValue("CNS_PRVQTD") * oModCNB:GetValue("CNB_VLUNIT",nS) * (1-(oModCNB:GetValue("CNB_DESC",nS)/100)),TamSX3('CNF_VLPREV')[2])
				nVlrRlz += Round(oModCNS:GetValue("CNS_RLZQTD") * oModCNB:GetValue("CNB_VLUNIT",nS) * (1-(oModCNB:GetValue("CNB_DESC",nS)/100)),TamSX3('CNF_VLPREV')[2])
				oModel:GetModel("CALC_CNS"):SetValue("TCNS_VTOT",nVlrPre)
			EndIf
		Next nS
		oModCNF:SetValue("CNF_VLPREV",nVlrPre)
		oModCNF:SetValue("CNF_VLREAL",nVlrRlz)
		oModCNF:LoadValue("CNF_SALDO",Round(nVlrPre - nVlrRlz, TamSX3('CNF_SALDO')[2]))
	EndIf
Next nF

CN300AjSld(oModel,oModel:GetModel('CNADETAIL'):GetValue("CNA_VLTOT"))

FwRestRows(aSaveLines)
oModCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.F.})

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} A300SldRec()
Query para verificar se existem item medidos nao recebidos.
retorna o saldo

@author alexandre.gimenez
@since 10/03/2014
@version 1.0
/*/
//----------------------------------±--------------------------------
Static Function A300SldRec(cTipRet,cItem,lFilterPla)

Local oModel	:= FwModelActive()
Local cDatReaj	:= DTOS(oModel:GetValue("CN9MASTER","CN9_DTREAJ"))
Local cRevAnt := Tira1(oModel:GetValue("CN9MASTER","CN9_REVISA"))
Local cFilIt	:= ""
Local cFilPed	:= ""
Local cAliasSql := ""

Local lCnRevMd	:= SuperGetMV("MV_CNREVMD",.F.,.T.)
Local lFixo		:= Cn300RetSt("FIXO",0)

Local nPos		:= 0
Local xRet 		:= Nil

Default lFilterPla := .T.

If cRevAnt = Replicate('0',TamSX3("CN9_REVISA")[1]) // Ajusta Tira1
	cRevAnt = Replicate(' ',TamSX3("CN9_REVISA")[1])
EndIf

cFilIt	:= Iif(Empty(cItem)," "," AND CNE.CNE_ITEM = '"+cItem+"'")

If lFixo .And. lFilterPla
	cFilIt +=" AND CNE.CNE_NUMERO = '"+oModel:GetValue("CNADETAIL","CNA_NUMERO")+"'"
EndIf

If (A300GTpRev() == DEF_REV_REAJU .Or. A300GATpRv() == DEF_REV_REAJU )
	cFilIt += " AND CND.CND_DTFIM  >= '"+cDatReaj+"'"
EndIf

cFilIt := '%'+cFilIt+'%'

If Cn300RetSt("COMPRA")
	cFilPed := " SELECT SUM(SC7.C7_QUJE) AS C7_QUJE "
	cFilPed += " FROM "+ RetSQLName("SC7") +" SC7 "
	cFilPed += " WHERE "
	cFilPed += " SC7.C7_FILIAL = CND.CND_FILIAL "
	cFilPed += " AND SC7.C7_MEDICAO = CND.CND_NUMMED "
	cFilPed += " AND SC7.D_E_L_E_T_ = ' '"
Else
	cFilPed := " SELECT SUM(SC6.C6_QTDENT) AS C6_QTDENT "
	cFilPed += " FROM "+ RetSQLName("SC6") +" SC6 "
	cFilPed += " JOIN "+ RetSQLName("SC5") +" SC5 ON SC5.C5_NUM = SC6.C6_NUM "
	cFilPed += " WHERE SC5.C5_FILIAL = CND.CND_FILIAL "
	cFilPed += " AND SC6.C6_FILIAL = SC5.C5_FILIAL "
	cFilPed += " AND SC5.C5_MDNUMED = CND.CND_NUMMED "
	cFilPed += " AND SC5.D_E_L_E_T_ = ' ' "
	cFilPed += " AND SC6.D_E_L_E_T_ = ' ' "
EndIf
cFilPed := '%'+ cFilPed + '%'

cAliasSql 	:= GetNextAlias()

BeginSQL Alias cAliasSql

	SELECT CND.CND_NUMMED NUMMED,
			CND.CND_PARCEL PARCEL,
			CNE.CNE_NUMERO NUMERO,
			CNE.CNE_ITEM	ITEM,
			CNE.CNE_QUANT QUANT,
			CNE.CNE_VLTOT VLTOT,
			CNE.CNE_VLDESC VLDESC,
			CND.CND_PEDIDO PEDIDO
	FROM
			%Table:CND% CND,
			%Table:CNE% CNE

	WHERE
			    CND.CND_FILCTR = %Exp:oModel:GetValue('CN9MASTER','CN9_FILCTR')%
			AND CND.CND_CONTRA = %Exp:oModel:GetValue("CN9MASTER","CN9_NUMERO")%
			AND CND.CND_REVISA = %Exp:cRevAnt%
			AND CND.CND_PARCEL != %Exp:Space(TamSX3("CND_PARCEL")[1])%
			AND CNE.CNE_FILIAL = CND.CND_FILIAL
			AND CNE.CNE_CONTRA = CND.CND_CONTRA
			AND CNE.CNE_REVISA = CND.CND_REVISA
			AND CNE.CNE_NUMMED = CND.CND_NUMMED
			%Exp:cFilIt%
			AND CNE.%NotDel%
			AND CND.%NotDel%
			AND (%Exp:cFilPed%) = 0

	UNION

	SELECT CND.CND_NUMMED NUMMED,
			CXN.CXN_PARCEL PARCEL,
			CNE.CNE_NUMERO NUMERO,
			CNE.CNE_ITEM	ITEM,
			CNE.CNE_QUANT QUANT,
			CNE.CNE_VLTOT VLTOT,
			CNE.CNE_VLDESC VLDESC,
			CXJ.CXJ_NUMPED PEDIDO

	FROM
			%Table:CND% CND,
			%Table:CNE% CNE,
	 	 	%Table:CXN% CXN,
	 	 	%Table:CXJ% CXJ

	WHERE
				 CND.CND_FILCTR = %Exp:oModel:GetValue('CN9MASTER','CN9_FILCTR')%
			AND CND.CND_CONTRA = %Exp:oModel:GetValue("CN9MASTER","CN9_NUMERO")%
			AND CND.CND_REVISA = %Exp:cRevAnt%
			AND CND.%NotDel%

			AND CXN.CXN_FILIAL = CND.CND_FILIAL
			AND CXN.CXN_CONTRA = CND.CND_CONTRA
			AND CXN.CXN_REVISA = CND.CND_REVISA
			AND CXN.CXN_NUMMED = CND.CND_NUMMED
			AND CXN.%NotDel%

			AND CNE.CNE_FILIAL = CXN.CXN_FILIAL
			AND CNE.CNE_NUMMED = CXN.CXN_NUMMED
			AND CNE.CNE_CONTRA = CXN.CXN_CONTRA
			AND CNE.CNE_REVISA = CXN.CXN_REVISA
			AND CNE.CNE_NUMERO = CXN.CXN_NUMPLA
			AND CNE.%NotDel%

			AND CXJ.CXJ_FILIAL = CND.CND_FILIAL
			AND CXJ.CXJ_CONTRA = CND.CND_CONTRA
			AND CXJ.CXJ_NUMMED = CND.CND_NUMMED
			AND CXJ.CXJ_NUMPLA = CXN.CXN_NUMPLA
			AND CXJ.CXJ_ITEMPL = CNE.CNE_ITEM
			AND CXJ.%NotDel%

			%Exp:cFilIt%
			AND (%Exp:cFilPed%) = 0
EndSQL

If cTipRet == 'n'
	xRet := 0
ElseIf cTipRet == 'a'
	xRet := {/*Parcela , Quantidade*/}
ElseIf cTipRet == 'a2'
	xRet := {/*Planilha, NumeroMed, Item*/}
ElseIf cTipRet == 'a3'
	xRet := {/*Pedido*/}
ElseIf cTipRet == 'a4'
	xRet := {/*Parcela , valor*/}
ElseIf cTipRet == 'n2'
	xRet := 0
EndIf

While (cAliasSql)->(!EOF())
	If cTipRet == 'n' // Soma quantidade
		xRet += (cAliasSql)->QUANT
	ElseIf cTipRet == 'a' .And. !Empty(cItem)// Monta array com parcelas
		If !Empty(xRet) .And. ( nPos := aScan(xRet,{|x| x[1] == (cAliasSql)->PARCEL }) ) > 0
			xRet[nPos,2] += (cAliasSql)->QUANT
		Else
			aAdd(xRet,{(cAliasSql)->PARCEL,(cAliasSql)->QUANT })
		EndIf
	ElseIf cTipRet == 'a2'
		aAdd(xRet,{(cAliasSql)->NUMERO,(cAliasSql)->NUMMED,(cAliasSql)->ITEM })
	ElseIf cTipRet == 'a3'
		If Empty(xRet) .Or. ( nPos := aScan(xRet,(cAliasSql)->PEDIDO ))  == 0
			aAdd(xRet,(cAliasSql)->PEDIDO)
		EndIf
	ElseIf cTipRet == 'a4' // Monta array com parcelas
		If !Empty(xRet) .And. ( nPos := aScan(xRet,{|x| x[1] == (cAliasSql)->PARCEL }) ) > 0
			xRet[nPos,2] += (cAliasSql)->VLTOT - (cAliasSql)->VLDESC
		Else
			aAdd(xRet,{(cAliasSql)->PARCEL , (cAliasSql)->VLTOT - (cAliasSql)->VLDESC })
		EndIf
	ElseIf cTipRet == 'n2'
		xRet += ((cAliasSql)->VLTOT 	- (cAliasSql)->VLDESC )
	EndIf
	(cAliasSql)->(DbSkip())
End

(cAliasSql)->(dbCloseArea())

Return xRet

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300BlqLn()
Bloqueia e desbloqueia inserir linhas nos modelos de acordo com a revisão

@author José Eulálio
@since 06/03/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------
Function cn300BlqLn(oModel)

Local cTpRev	:= A300GTpRev()

Default oModel := Nil

If !VALTYPE(oModel) == 'O'
	oModel	:= FWModelActive()
EndIf

//Bloqueia adição de linhas nos Modelos
oModel:GetModel('CNADETAIL'):SetNoInsertLine(.T.)
oModel:GetModel('CNBDETAIL'):SetNoInsertLine(.T.)
oModel:GetModel('CNCDETAIL'):SetNoInsertLine(.T.)

//Libera Planilha e Itens e Cronograma Físico
If cTpRev == DEF_REV_ADITI .Or. cTpRev == DEF_REV_RENOV .Or. cTpRev == DEF_REV_ORCGS .Or. cTpRev == DEF_REV_ABERT
	//Libera linhas
	oModel:GetModel('CNADETAIL'):SetNoInsertLine(.F.)
	oModel:GetModel('CNBDETAIL'):SetNoInsertLine(.F.)
EndIf

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300DlPrc()
Função que deleta parcelas do cronograma Financeiro, na revisão de
aditivo ou reajuste.

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300DlPrc(oModel)
Local oCN9Master 	:= oModel:GetModel('CN9MASTER')
Local oCNFDetail 	:= oModel:GetModel('CNFDETAIL')
Local oCNSDetail 	:= oModel:GetModel('CNSDETAIL')
Local nQtdParcs  	:= oCN9Master:GetValue('CN9_QTDPAR')
Local nI    	    := 0
Local nI2    	    := 0
Local aSaveLines	:= FWSaveRows()
Local nNMed      	:= 0
Local nMed			:= 0
Local lRet 		:= .T.
Local aSldFis		:= {}
Local nPos 		:= 0

For nI := 1 To oCNFDetail:Length()
	oCNFDetail:GoLine(nI)
	If !oCNFDetail:IsDeleted()
		If oCNFDetail:GetValue('CNF_VLREAL') == 0
			nNMed := nNMed + 1
		Else
			nMed := nMed + 1
		EndIf
	EndIf
Next nI

If (nQtdParcs >= nNMed) .And. (nMed == 0)
	Help('',1,'CNT300DCPC')// O número de redução de parcelas não pode ser maior ou igual ao o número de parcelas.
	lRet := .F.
EndIf

If lRet
	oCNFDetail:SetNoDeleteLine(.F.)
	For nI := oCNFDetail:Length() To 1 Step -1
		oCNFDetail:GoLine(nI)
		If !oCNFDetail:IsDeleted()

			If nQtdParcs == 0
				Exit
			EndIf

			If oCNFDetail:GetValue('CNF_VLREAL') == 0
				oCNFDetail:DeleteLine()

				nQtdParcs := nQtdParcs - 1

				If CN300RetSt('FISICO')
					For nI2 := 1 To oCNSDetail:Length()
						oCNSDetail:GoLine(nI2)
						oCNSDetail:DeleteLine()
						nPos := Ascan(aSldFis,{|x| x[1] == oCNSDetail:GetValue('CNS_PRODUT')})

						If nPos > 0
							aSldFis[nPos, 2] += oCNSDetail:GetValue('CNS_SLDQTD')
						Else
							Aadd(aSldFis, {oCNSDetail:GetValue('CNS_PRODUT'), oCNSDetail:GetValue('CNS_SLDQTD')})
						EndIf
					Next nI2
				EndIf
			EndIf
		EndIf
	Next nI
	oCNFDetail:SetNoDeleteLine(.T.)

	If Cn300RetSt("SERVIÇO")
		CN300ItSrv(3,oCN9Master:GetValue('CN9_QTDPAR')-nQtdParcs)
    EndIf
EndIf
FWRestRows(aSaveLines)

Return aSldFis

//------------------------------------------------------------------
/*/{Protheus.doc} CNA300RvMd()
Se o parametro lCnRevMd = True, será inserido registro na tabela,
senão será alterado o registro.

@author Taniel Balsanelli
@since 05/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CNA300RvMd(cContra,cRevisa,cNRevisa,cFilCtr,lExclui)
Local oModel	:= FwModelActive()
Local nX		:= 0
Local nZ		:= 0
Local nMemo		:= 0
Local aAreaCN9	:= CN9->(GetArea())
Local aStruCND	:= {}
Local aStruCNE	:= {}
Local aStruTab	:= {}
Local aMemos	:= {}
Local cField	:= ""
Local lCnRevMd	:= SuperGetMV("MV_CNREVMD",.F.,.T.)
Local oModelCN9 := Nil 
Local cAliasCND := GetNextAlias()

Default lExclui := oModel:GetOperation() == MODEL_OPERATION_DELETE 

If !IsInCallStack('CNDRPROCES')
	oModelCN9 := oModel:GetModel('CN9MASTER')
	CN9->(dbSetOrder(1))
	CN9->(dbSeek(oModelCN9:GetValue('CN9_FILIAL')+oModelCN9:GetValue('CN9_NUMERO')))
EndIf

Default cFilCtr := CN9->CN9_FILCTR

//- Seleciona medições que devem ser alteradas.
cQuery := " SELECT CND.*,CND.R_E_C_N_O_ as RECNO "
cQuery += " FROM "+RetSQLName("CND")+" CND "
cQuery += " WHERE CND.CND_FILCTR 	= '"+cFilCtr+"'"
cQuery += " AND CND.CND_CONTRA 		= '"+cContra+"'"
cQuery += " AND CND.CND_REVISA 		= '"+Iif(lExclui,cNRevisa,cRevisa)+"'"
cQuery += " AND CND.D_E_L_E_T_		 = ' '"

cQuery := ChangeQuery( cQuery )
dbUseArea( .T., "TopConn", TCGenQry(,,cQuery), cAliasCND, .F., .F. )

//== Revisão da tabela CND ==================================================================================================
dbSelectArea("CND")
While !(cAliasCND)->(Eof())
	CND->(dbGoto((cAliasCND)->RECNO))
	aStruCND := CND->(dbStruct())

	//- Obtem conteudo dos campos do tipo memo
	For nZ:=1 to len(aStruCND)
		If aStruCND[nZ][2]=="M"
			Aadd(aMemos,{aStruCND[nZ][1],&("CND->"+(aStruCND[nZ][1]))})
		EndIf
	Next nZ

	If lExclui
		If lCnRevMd
			RecLock("CND", .F.)
			dbDelete()
		Else
			RecLock("CND",.F.)
			CND->CND_REVISA := cRevisa
		EndIf
	Else
		If lCnRevMd
			RecLock("CND",.T.)
			For nX:=1 to CND->(FCount())
				cField := FieldName(nX)
				If  Type(cAliasCND+"->"+cField)!= "U"
					FieldPut(nX,(cAliasCND)->&(CND->(cField)))
				EndIf

				//Grava conteudo dos campos do tipo memo
				If  Type("CND->"+cField)== "M"
					nMemo:= aScan(aMemos,{|x| x[1]==cField})
					If nMemo>0
						FieldPut(nx,aMemos[nMemo][2])
					EndIf
				EndIf
			Next nX
		Else
		 	RecLock("CND",.F.)
		EndIf
		CND->CND_REVISA := cNRevisa
	EndIf

	MsUnlock()
	aMemos := {}

	//== Revisão TABELA CXN ================================================================================================
	//oModel:SetRelation('CXNDETAIL', {{'CXN_FILIAL','xFilial("CXN")'},{'CXN_CONTRA','CND_CONTRA'},{'CXN_REVISA','CND_REVISA'},{'CXN_NUMMED','CND_NUMMED'}},CXN->(IndexKey(1)))

	cQuery := " SELECT CXN.*,CXN.R_E_C_N_O_ as RECNO "
	cQuery += " FROM "+RetSQLName("CXN")+" CXN "
	cQuery += " WHERE CXN.CXN_FILIAL 	= '"+(cAliasCND)->CND_FILIAL+"'"
	cQuery += " AND CXN.CXN_CONTRA 		= '"+cContra+"'"
	cQuery += " AND CXN.CXN_REVISA 		= '"+IIF(lExclui,cNRevisa,cRevisa)+"'"
	cQuery += " AND CXN.CXN_NUMMED 		= '"+(cAliasCND)->CND_NUMMED+"'"
	cQuery += " AND CXN.D_E_L_E_T_ 		= ' '"

	cQuery := ChangeQuery( cQuery )
	dbUseArea( .T., "TopConn", TCGenQry(,,cQuery), "CXNTMP", .F., .F. )

	dbSelectArea("CXN")
	While !CXNTMP->(EOF())
		CXN->(dbGoto(CXNTMP->RECNO))
		aStruCXN := CXN->(dbStruct())

		For nZ:=1 to Len(aStruCXN)
			If aStruCXN[nZ][2]=="M"
				Aadd(aMemos,{aStruCXN[nZ][1],&("CXN->"+(aStruCXN[nZ][1]))})
			EndIf
		Next nZ

		If lExclui
			If lCnRevMd
				RecLock("CXN",.F.)
				dbDelete()
			Else
				RecLock("CXN",.F.)
				CXN->CXN_REVISA := cRevisa
			EndIf
		Else
			If lCnRevMd
				RecLock("CXN",.T.)
				For nX:=1 to CXN->(FCount())
					cField := FieldName(nX)
					If  Type("CXNTMP->"+cField)!= "U"
						If  Type("CXN->"+cField) <> "L"
							FieldPut(nx,CXNTMP->&(CXN->(cField)))
						Else
							If CXNTMP->&(CXN->(cField)) == "T"
								FieldPut(nx,.T.)
							ElseIf CXNTMP->&(CXN->(cField)) == "F"
								FieldPut(nx,.F.)
							EndIf
						EndIf
					EndIf

					If Type("CXN->"+cField)== "M"
						nMemo:= aScan(aMemos,{|x| x[1]==cField})
						If nMemo > 0
							FieldPut(nx,aMemos[nMemo][2])
						EndIf
					EndIf
				Next nX
			Else
				RecLock("CXN",.F.)
			EndIf
			CXN->CXN_REVISA := cNRevisa
		EndIf
		MsUnlock()
		aMemos:= {}

		CXNTMP->(dbSkip())
	EndDo
	CXNTMP->(dbCloseArea())

	//== Revisão TABELA CNE ================================================================================================
	//oModel:SetRelation('CNEDETAIL', {{'CNE_FILIAL','xFilial("CNE")'},{'CNE_CONTRA','CND_CONTRA'},{'CNE_REVISA','CND_REVISA'},{'CNE_NUMERO','CXN_NUMPLA'},{'CNE_NUMMED','CND_NUMMED'}},CNE->(IndexKey(1)))

		cQuery := " SELECT CNE.*,CNE.R_E_C_N_O_ as RECNO "
		cQuery += " FROM "+RetSQLName("CNE")+" CNE "
	    cQuery += " WHERE CNE.CNE_FILIAL 	= '"+(cAliasCND)->CND_FILIAL+"'"
		cQuery += " AND CNE.CNE_CONTRA = '"+cContra+"'"
		cQuery += " AND CNE.CNE_REVISA = '"+IIF(lExclui,cNRevisa,cRevisa)+"'"
		cQuery += " AND CNE.CNE_NUMMED = '"+(cAliasCND)->CND_NUMMED+"'"
		cQuery += " AND CNE.D_E_L_E_T_ = ' '"

		cQuery := ChangeQuery( cQuery )
		dbUseArea( .T., "TopConn", TCGenQry(,,cQuery), "CNETMP", .F., .F. )

		dbSelectArea("CNE")
		While !CNETMP->(EOF())
			CNE->(dbGoto(CNETMP->RECNO))
			aStruCNE := CNE->(dbStruct())

			//Obtem conteudo dos campos do tipo memo
			For nZ:=1 to len(aStruCNE)
				If aStruCNE[nZ][2]=="M"
					Aadd(aMemos,{aStruCNE[nZ][1],&("CNE->"+(aStruCNE[nZ][1]))})
				EndIf
			Next nZ

			If lExclui
				If lCnRevMd
					RecLock("CNE",.F.)
					dbDelete()
				Else
					RecLock("CNE",.F.)
					CNE->CNE_REVISA := cRevisa
				EndIf
			Else
				If lCnRevMd
					RecLock("CNE",.T.)
				    For nX:=1 to CNE->(FCount())
						cField := FieldName(nX)
						If  Type("CNETMP->"+cField)!= "U"
						    FieldPut(nx,CNETMP->&(CNE->(cField)))
						EndIf
						//Grava conteudo dos campos do tipo memo
						If  Type("CNE->"+cField)== "M"
						    nMemo:= aScan(aMemos,{|x| x[1]==cField})
							If nMemo>0
								FieldPut(nx,aMemos[nMemo][2])
							EndIf
						EndIf
				Next nX
				Else
				 	RecLock("CNE",.F.)
				EndIf
				CNE->CNE_REVISA := cNRevisa
			EndIf
			MsUnlock()
			aMemos:= {}
			CNETMP->(dbSkip())
		EndDo
		CNETMP->(dbCloseArea())

	//== Revisão TABELA CNZ ================================================================================================
	//oModel:SetRelation('CNZDETAIL' ,{{'CNZ_FILIAL','xFilial("CNZ")'},{'CNZ_CONTRA','CND_CONTRA'},{'CNZ_REVISA','CND_REVISA'},{'CNZ_NUMMED','CND_NUMMED'},{'CNZ_CODPLA','CXN_NUMPLA'},{'CNZ_FORNEC','CXN_FORNEC'},{'CNZ_LJFORN','CXN_LJFORN'},{'CNZ_CLIENT','CXN_CLIENT'},{'CNZ_LOJACL','CXN_LJCLI'},{'CNZ_ITCONT','CNE_ITEM'}},CNZ->(IndexKey(5)))

	cQuery := " SELECT CNZ.*,CNZ.R_E_C_N_O_ as RECNO "
	cQuery += " FROM "+RetSQLName("CNZ")+" CNZ "
	cQuery += " WHERE "
	If !Empty(xFilial('CNZ')) //- Gestão corporativa
		cQuery += " CNZ.CNZ_FILIAL 	= '"+(cAliasCND)->CND_FILIAL+"' AND "
	EndIf
	cQuery += " CNZ.CNZ_CONTRA 		= '"+cContra+"'"
	cQuery += " AND CNZ.CNZ_REVISA 		= '"+IIF(lExclui,cNRevisa,cRevisa)+"'"
	cQuery += " AND CNZ.CNZ_NUMMED 		= '"+(cAliasCND)->CND_NUMMED+"'"
	cQuery += " AND CNZ.D_E_L_E_T_ 		= ' '"

	cQuery := ChangeQuery( cQuery )
	dbUseArea( .T., "TopConn", TCGenQry(,,cQuery), "CNZTMP", .F., .F. )

	dbSelectArea("CNZ")
	While !CNZTMP->(EOF())
		CNZ->(dbGoto(CNZTMP->RECNO))
		aStruTab := CNZ->(dbStruct())

		//Obtem conteudo dos campos do tipo memo
		For nZ:=1 to len(aStruTab)
			If aStruTab[nZ][2]=="M"
				Aadd(aMemos,{aStruTab[nZ][1],&("CNZ->"+(aStruTab[nZ][1]))})
			EndIf
		Next nZ

		If lExclui
			If lCnRevMd
				RecLock("CNZ",.F.)
				dbDelete()
			Else
				RecLock("CNZ",.F.)
				CNZ->CNZ_REVISA := cRevisa
			EndIf
		Else
			If lCnRevMd
				RecLock("CNZ",.T.)
				For nX:=1 to CNZ->(FCount())
					cField := FieldName(nX)
					If  Type("CNZTMP->"+cField)!= "U"
						FieldPut(nx,CNZTMP->&(CNZ->(cField)))
					EndIf
					//Grava conteudo dos campos do tipo memo
					If  Type("CNZ->"+cField)== "M"
						nMemo:= aScan(aMemos,{|x| x[1]==cField})
						If nMemo > 0
							FieldPut(nx,aMemos[nMemo][2])
						EndIf
					EndIf
				Next nX
			Else
			 	RecLock("CNZ",.F.)
			EndIf
			CNZ->CNZ_REVISA := cNRevisa
		EndIf
		MsUnlock()
		aMemos:= {}
		CNZTMP->(dbSkip())
	EndDo
	CNZTMP->(dbCloseArea())

	//== Revisão dos Pedidos gerados ================================================================================================
	If lExclui
		CNA300RvPd(cContra,cNRevisa,cRevisa,(cAliasCND)->CND_FILIAL)
	Else
		CNA300RvPd(cContra,cRevisa,cNRevisa,(cAliasCND)->CND_FILIAL)
	EndIf
		(cAliasCND)->(dbSkip())
	EndDo
	(cAliasCND)->(dbCloseArea())

CN9->(RestArea(aAreaCN9))

Return Nil

//------------------------------------------------------------------
/*/{Protheus.doc} CNA300RvPd()
Atualiza numero da revisão do pedido gerado pela medição na revisão
de contratos

@author Israel Escorizza
@since 02/09/2016
@version 1.0
/*/
//-------------------------------------------------------------------
Function CNA300RvPd(cContra,cRevisa,cNRevisa,cFilMed)
Default cContra	:= ""
Default cRevisa	:= ""
Default cNRevisa	:= ""
Default cFilMed	:= ""

// --Ajusta campo de revisao dos pedidos de compra
BeginSQL Alias "TRBSC7"
	SELECT 	R_E_C_N_O_ SC7RECNO
	FROM 		%Table:SC7% SC7
	WHERE 		SC7.%NotDel% 						AND
				SC7.C7_FILIAL	= %Exp:cFilMed%	AND
				SC7.C7_CONTRA	= %Exp:cContra% 	AND
				SC7.C7_CONTREV= %Exp:cRevisa%
EndSQL

// -- Migra os itens de medicoes para a nova revisao
While !TRBSC7->(Eof())
	SC7->(dbGoTo(TRBSC7->SC7RECNO))
	RecLock("SC7",.F.)
		SC7->C7_CONTREV := cNRevisa
	MsUnlock()
	TRBSC7->(dbSkip())
EndDo

TRBSC7->(dbCloseArea())
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} a300dtAniv()
Atualiza a data de aniversário dos itens da planilha inclusos durante uma revisão

@author José eulálio
@since 28/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function a300dtAniv()

Local oModel     	:= FwModelActive()
Local oModelCNA  	:= oModel:GetModel("CNADETAIL")
Local oModelCNB  	:= oModel:GetModel("CNBDETAIL")
Local nForA 		:= 0
Local nForB 		:= 0
Local lUpd			:= .T.

For nForA := 1 to oModelCNA:Length()
	oModelCNA:GoLine(nForA)
	If !oModelCNA:IsDeleted()
		For nForB := 1 To oModelCNB:Length()
			oModelCNB:GoLine(nForB)
			If Empty(oModelCNB:GetValue('CNB_DTANIV')) .And. !Empty(oModelCNB:GetValue('CNB_PRODUT')) .And. !oModelCNB:IsDeleted()
				lUpd := oModelCNB:CanUpdateLine()
				If !lUpd
					oModelCNB:SetNoUpdateLine(.F.)
				EndIf
				oModelCNB:LoadValue('CNB_DTANIV',dDataBase)
				oModelCNB:SetNoUpdateLine(!lUpd)
			EndIf
		Next nForB
	EndIf
Next nForA

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300VdArr()
Validações nos campos CN9_ARRAST (valid)
que deverão ser consideradas na revisão de realinhamento, aditivo de prazo e quantidade/prazo

@author Antenor Silva
@since 27/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300VdArr()
Local oModel		:= FWModelActive()
Local oStruCN9 	:= oModel:GetModel('CN9MASTER'):GetStruct()
Local oModelCN9	:= oModel:GetModel('CN9MASTER')
Local lRet			:= .T.
Local cTipRevisa 	:= A300GTpRev()

If !Empty(A300GTpRev())
	If (cTipRevisa == DEF_REV_ADITI .Or. cTipRevisa == DEF_REV_REALI .Or. cTipRevisa == DEF_REV_READE .Or. cTipRevisa == DEF_REV_REINI .Or. cTipRevisa == DEF_REV_RENOV .Or. cTipRevisa == DEF_REV_ORCGS .Or. cTipRevisa == DEF_REV_ABERT)
		If oModelCN9:GetValue('CN9_ARRAST') == "2"
			oStruCN9:SetProperty('CN9_REDVAL',MODEL_FIELD_WHEN,{||.T.})
			oModelCN9:SetValue('CN9_REDVAL',"2")
			oStruCN9:SetProperty('CN9_REDVAL',MODEL_FIELD_WHEN,{||.F.})
		Else
			oStruCN9:SetProperty('CN9_REDVAL',MODEL_FIELD_WHEN,{||.T.})
		EndIf
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300VArrC()
Validações no campo CN9_ARRASC (valid)
que deverão ser consideradas na revisão de realinhamento, aditivo de prazo e quantidade/prazo

@author jose.delmondes
@since 15/02/2016
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300VArrC()
Local oModel		:= FWModelActive()
Local oStruCN9 		:= oModel:GetModel('CN9MASTER'):GetStruct()
Local oModelCN9		:= oModel:GetModel('CN9MASTER')
Local lRet			:= .T.
Local cTipRevisa 	:= A300GTpRev()
Local lContabil		:= Cn300RetSt("CONTABIL",2)

If !Empty(cTipRevisa) .And. lContabil
	If (cTipRevisa == DEF_REV_ADITI .Or. cTipRevisa == DEF_REV_REALI .Or. cTipRevisa == DEF_REV_READE .Or. cTipRevisa == DEF_REV_REINI .Or. cTipRevisa == DEF_REV_ABERT)
		If oModelCN9:GetValue('CN9_ARRASC') == "2"
			oModelCN9:SetValue('CN9_REDVAC',"2")
			oStruCN9:SetProperty('CN9_REDVAC',MODEL_FIELD_WHEN,{||.F.})
		Else
			oStruCN9:SetProperty('CN9_REDVAC',MODEL_FIELD_WHEN,{||.T.})
		EndIf
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300CalRat()
Função que atualiza os campos do Valor do Rateio do itens da planilha

@param oModelCNZ, Submodelo da CNZ (Cuja CNB pai já esteja posicionada)
@param nVlTotCNB, Valor total da planilha (CNB)

@author antenor.silva
@since 25/02/2014
@version 1.0
/*/
//----------------------------------±--------------------------------
Function  A300CalRat( oModelCNZ, nVlTotCNB )
	Local nPerc := 0
	Local nZ := 0
	Local nValPerc := 0
	Default oModelCNZ := Nil
	Default nVlTotCNB := 0
	
	If oModelCNZ <> Nil
		For nZ := 1 To oModelCNZ:Length()
			oModelCNZ:GoLine( nZ )
			If !oModelCNZ:IsDeleted()
				nPerc := oModelCNZ:GetValue( "CNZ_PERC" )
				nValPerc := (nPerc * nVlTotCNB) / 100
				oModelCNZ:SetValue( "CNZ_VALOR1", nValPerc )
				oModelCNZ:SetValue( "CNZ_VALOR2", xMoeda( nValPerc, 1, 2, dDatabase ) )
				oModelCNZ:SetValue( "CNZ_VALOR3", xMoeda( nValPerc, 1, 3, dDatabase ) )
				oModelCNZ:SetValue( "CNZ_VALOR4", xMoeda( nValPerc, 1, 4, dDatabase ) )
				oModelCNZ:SetValue( "CNZ_VALOR5", xMoeda( nValPerc, 1, 5, dDatabase ) )
			EndIf
		Next nZ
	EndIf
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} A300CalSum()
Calcular a soma(CNB_QTRDAC) – soma(CNB_QTRDRZ) em qualquer alteração CNB
e atualizar os valores de rateio dos itens da planilha

@author antenor.silva
@since 25/02/2014
@version 1.0
/*/
//----------------------------------±--------------------------------
Function A300CalSum(oModel)
Local oModelCN9	:= oModel:GetModel('CN9MASTER')
Local oModelCNA	:= oModel:GetModel('CNADETAIL')
Local oModelCNB	:= oModel:GetModel('CNBDETAIL')
Local oModelCNZ	:= oModel:GetModel('CNZDETAIL')
Local aSaveLines:= FWSaveRows()
Local aCampos	:= {}
Local cRevAnt	:= CnRevAnt()
Local lLineIns	:= .F.
Local lExiste	:= .F.
Local nSldMed	:= 0
Local nSldRec	:= 0
Local nA		:= 0
Local nB		:= 0

dbSelectArea("CNB")
CNB->(dbSetOrder(1))

CNTA300BlMd(oModelCNB,.F.)
CNTA300BlMd(oModelCNZ,.F.)

aAdd(aCampos,{'CNZDETAIL',{'CNZ_VALOR1','CNZ_VALOR2','CNZ_VALOR3','CNZ_VALOR4','CNZ_VALOR5'}})
MtBCMod(oModel,aCampos,{||.T.},'2')

For nA := 1 To oModelCNA:Length()
	oModelCNA:GoLine(nA)
	If !oModelCNA:IsDeleted()
		For nB := 1 To oModelCNB:Length()
			oModelCNB:GoLine(nB)
			If !oModelCNB:IsDeleted()
				
				lLineIns := oModelCNB:IsInserted()
				lExiste := CNB->(dbSeek(xFilial("CNB")+oModelCNB:GetValue('CNB_CONTRA')+cRevAnt+oModelCNB:GetValue('CNB_NUMERO')+oModelCNB:GetValue('CNB_ITEM')))
				
				//Se Está em Revisão, o saldo é igual à nova quantidade
				If oModelCN9:GetValue("CN9_SITUAC")=="09" .And. ((oModelCNB:GetOperation() == MODEL_OPERATION_UPDATE .And. !lExiste) .Or. lLineIns)
					oModelCNB:SetValue("CNB_SLDMED",oModelCNB:GetValue('CNB_QUANT'))
					oModelCNB:SetValue("CNB_SLDREC",oModelCNB:GetValue('CNB_QUANT'))
				EndIf
				
				If (lExiste)
					nSldMed := CNB->CNB_SLDMED
					nSldRec := CNB->CNB_SLDREC
				Else
					nSldMed := oModelCNB:GetValue("CNB_SLDMED")
					nSldRec := oModelCNB:GetValue("CNB_SLDREC")
				EndIf

				If oModelCNB:GetValue("CNB_QUANT") < oModelCNB:GetValue("CNB_QTDORI") // Se houve decréscimo

					oModelCNB:LoadValue("CNB_QTRDRZ",oModelCNB:GetValue("CNB_QTDORI") - oModelCNB:GetValue("CNB_QUANT"))
					oModelCNB:SetValue("CNB_QTRDAC",0)
					oModelCNB:SetValue("CNB_SLDMED",nSldMed - IIf(lLineIns .Or. !lExiste,0,oModelCNB:GetValue("CNB_QTRDRZ")))
					oModelCNB:SetValue("CNB_SLDREC",nSldRec - IIf(lLineIns .Or. !lExiste,0,oModelCNB:GetValue("CNB_QTRDRZ")))

				ElseIf oModelCNB:GetValue("CNB_QUANT") > oModelCNB:GetValue("CNB_QTDORI") // Se houve acréscimo

					//Se Está em Revisão, desconsidera a qtde adicionada
					If oModelCN9:GetValue("CN9_SITUAC")=="09" .And. oModelCNB:GetOperation() == MODEL_OPERATION_UPDATE .And. !lExiste .And. !lLineIns
						nSldMed -= oModelCNB:GetValue("CNB_QTRDAC")
						nSldRec -= oModelCNB:GetValue("CNB_QTRDAC")
					EndIf

					oModelCNB:LoadValue("CNB_QTRDAC",oModelCNB:GetValue("CNB_QUANT") - oModelCNB:GetValue("CNB_QTDORI"))
					oModelCNB:SetValue("CNB_QTRDRZ",0)
					oModelCNB:SetValue("CNB_SLDMED",nSldMed + IIf(lLineIns,0,oModelCNB:GetValue("CNB_QTRDAC")))
					oModelCNB:SetValue("CNB_SLDREC",nSldRec + IIf(lLineIns,0,oModelCNB:GetValue("CNB_QTRDAC")))
				EndIf
				
				//Tratamentos para o rateio do item 
				A300CalRat( oModelCNZ, oModelCNB:GetValue("CNB_VLTOT") )
				
			EndIf
		Next nB
	EndIf
Next nA

CNTA300BlMd(oModelCNZ,.T.)
CNTA300BlMd(oModelCNB,.T.)
FWRestRows(aSaveLines)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} A300CalcVl()
Calcula o valor adicionado ou reduzido no caso de aditivo, readequamento - (qtde)
O mesmo conceito se aplica as funções de valor, ao alterar o cnb_vlunit – calcular o valor reajustado, aditivado ou realinhado

@author antenor.silva
@since 25/02/2014
@version 1.0
/*/
//----------------------------------±--------------------------------
Function  A300CalcVl( oModelCNB )
	Local lRet := .T.
	Local cTipRev := A300GTpRev()
	Local nCNBQuant := 0
	Local nCNBQtOri := 0
	
	If !Empty(cTipRev)
		nCNBQuant := oModelCNB:GetValue("CNB_QUANT")
		nCNBQtOri := oModelCNB:GetValue("CNB_QTDORI")
		
		If cTipRev == DEF_REV_ADITI
			If nCNBQuant < nCNBQtOri //se for decréscimo
				oModelCNB:LoadValue( "CNB_QTRDRZ", nCNBQtOri - nCNBQuant )
				oModelCNB:LoadValue( "CNB_QTRDAC", 0 )
			Else //se for acréscimo
				oModelCNB:LoadValue( "CNB_QTRDAC", nCNBQuant - nCNBQtOri )
				oModelCNB:LoadValue( "CNB_QTRDRZ", 0 )
			EndIf
	
		ElseIf cTipRev == DEF_REV_READE //tipo readequação
			oModelCNB:SetValue( "CNB_QTREAD", nCNBQuant - nCNBQtOri )
			oModelCNB:SetValue( "CNB_SLDMED", oModelCNB:GetValue("CNB_SLDMED") + (nCNBQuant - nCNBQtOri) )
			oModelCNB:SetValue( "CNB_SLDREC", oModelCNB:GetValue("CNB_SLDREC") + (nCNBQuant - nCNBQtOri) )
	
		ElseIf cTipRev == DEF_REV_REALI //tipo realinhamento
			oModelCNB:SetValue( "CNB_REALI", oModelCNB:GetValue("CNB_VLUNIT") - oModelCNB:GetValue("CNB_PRCORI") )
			oModelCNB:SetValue( "CNB_VLTOTR", nCNBQtOri * oModelCNB:GetValue("CNB_REALI") )
			oModelCNB:SetValue( "CNB_DTREAL", dDataBase )
	
		ElseIf cTipRev == DEF_REV_RENOV .Or. cTipRev == DEF_REV_ORCGS //- Tipo Renovação / Orçamento Serviços GS
			//Tratamento dos Aditivos
			If nCNBQuant < nCNBQtOri //se for decréscimo
				oModelCNB:LoadValue( "CNB_QTRDRZ", nCNBQtOri - nCNBQuant )
				oModelCNB:LoadValue( "CNB_QTRDAC", 0 )
			Else //se for acréscimo
				oModelCNB:LoadValue( "CNB_QTRDAC", nCNBQuant - nCNBQtOri )
				oModelCNB:LoadValue( "CNB_QTRDRZ", 0 )
			EndIf
		ElseIf cTipRev == DEF_REV_ABERT //- Tipo Aberta
			If nCNBQuant < nCNBQtOri //se for decréscimo
				oModelCNB:LoadValue( "CNB_QTRDRZ", nCNBQtOri - nCNBQuant )
				oModelCNB:LoadValue( "CNB_QTRDAC", 0 )
			Else //se for acréscimo
				oModelCNB:LoadValue( "CNB_QTRDAC", nCNBQuant - nCNBQtOri )
				oModelCNB:LoadValue( "CNB_QTRDRZ", 0 )
			EndIf			
			oModelCNB:SetValue( "CNB_REALI", oModelCNB:GetValue("CNB_VLUNIT") - oModelCNB:GetValue("CNB_PRCORI") )
			oModelCNB:SetValue( "CNB_VLTOTR", nCNBQtOri * oModelCNB:GetValue("CNB_REALI") )
			oModelCNB:SetValue( "CNB_DTREAL", dDataBase )
		EndIf
	EndIf
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300VlBas()
Valida base instalada no Gestao de Servicos

@author aline.sebrian
@since 27/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300VlBas()
Local lRet := .T.
Local oModel     := FwModelActive()
Local oModelCNB  := oModel:GetModel("CNBDETAIL")

If oModelCNB:GetValue("CNB_BASINS") == '1' .And. oModelCNB:GetValue("CNB_QTDMED")>0
	Help( " ", 1, "CN300NBASE") //Este item não poderá gerar base instalada pois já foi movimentado.
	lRet := .F.
Else
	If CNB->CNB_GERBIN == '1'
		Help( " ", 1, "CN300GBASE") //Este item da planilha já gerou base instalada e por isso este campo não pode ser alterado.
		lRet := .F.
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300AprPl(oModel,oModelCN8)
Libera equipamentos dos itens do contrato que foram removidos:
 processo de troca ou substituicao.

@author aline.sebrian
@since 24/02/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------
Function cn300AprPl(cContra,cRev)
Local oModel     := FwModelActive()
Local oModelCNA  := oModel:GetModel("CNADETAIL")
Local oModelCNB  := oModel:GetModel("CNBDETAIL")
Local cPlanil    := ""
Local nFor       := 0
Local nForCab    := 0
Local lCNINTFS   := SuperGetMV("MV_CNINTFS",.F.,.F.)
Local cTipRev	   := A300GATpRv()

If VALTYPE(oModelCNA) == 'O' .AND. VALTYPE(oModelCNB) == 'O'
	For nForCab := 1 to oModelCNA:Length()
		oModelCNA:GoLine(nForCab)
		cPlanil := oModelCNA:GetValue("CNA_NUMERO")
		For nFor := 1 To oModelCNB:Length()
			oModelCNB:GoLine(nFor)
			If !oModelCNB:IsDeleted()
				If lCNINTFS .And. ( cTipRev == DEF_REV_ADITI .Or. cTipRev == DEF_REV_RENOV .Or. cTipRev == DEF_REV_ORCGS .Or. cTipRev == DEF_REV_ABERT)
					cn300AdtFS(cContra,cRev,cPlanil,oModelCNB)
				EndIf
			EndIf
		Next nFor
	Next nForCab
EndIf

Return

//------------------------------------------------------------------
/*/{Protheus.doc} A300AtuCrF()
Função para atualizar cronograma fisico

@author alexandre.gimenez
@since 05/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function A300AtuCrF(oModel,nQuant,aQntMed,nLinha,nLineOri)
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local oModCNF	:= oModel:GetModel("CNFDETAIL")
Local oModCNS	:= oModel:GetModel("CNSDETAIL")
Local nSomaCNS	:= 0
Local nNewSum	:= 0
Local nOldVlr	:= 0
Local nDif		:= 0
Local nX		:= 0
Local nPos		:= 0
Local lRevMed 	:= A300RevMed(0)
Local aSaveLines:= FWSaveRows()
Local nY		:= 0
Local nPosCNS	:= 0
Local nValCNS	:= 0

Default nLineOri := nLinha

oModCNS:GetStruct():SetProperty("CNS_PRVQTD",MODEL_FIELD_WHEN,{||.T.})
oModCNS:GetStruct():SetProperty("CNS_DISTSL",MODEL_FIELD_WHEN,{||.T.})
oModCNS:GetStruct():SetProperty("CNS_SLDQTD",MODEL_FIELD_WHEN,{||.T.})
oModCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})

//Soma CNS
For nX := 1 to oModCNF:Length()
	oModCNF:GoLine(nX)
	If !oModCNF:IsDeleted() .And. oModCNS:Length() >= nLinha .And. oModCNS:GoLine(nLinha) == nLinha
		nSomaCNS += oModCNS:GetValue("CNS_PRVQTD",nLineOri)
	EndIf
Next nX

//Atualiza CNS
For nX := 1 to oModCNF:Length()
	nValCNS := 0
	oModCNF:GoLine(nX)
	If !oModCNF:IsDeleted() .And. oModCNS:Length() >= nLinha .And. oModCNS:GoLine(nLinha) == nLinha
		//Atualizar valor medido
		If lRevMed
			nPos := aScan(aQntMed,{|x| x[1] == oModCNS:GetValue("CNS_PARCEL") })
			QtdeRec := If(nPos > 0,aQntMed[nPos,2],0)

			oModCNS:GoLine(nLineOri)
			If (oModCNS:GetValue("CNS_RLZQTD") - QtdeRec) < oModCNS:GetValue("CNS_PRVQTD")
				oModCNF:SetNoUpdateLine(.F.)

				oModCNB:GoLine(nLinha)
				If nLineOri <> nLinha
					oModCNS:GoLine(nLineOri)
					nAux := oModCNS:GetValue("CNS_PRVQTD") - oModCNS:GetValue("CNS_RLZQTD") + QtdeRec

					oModCNS:GoLine(nLinha)
					oModCNS:LoadValue("CNS_RLZQTD",QtdeRec)
					oModCNF:LoadValue("CNF_VLREAL",(QtdeRec * oModCNB:GetValue("CNB_VLUNIT")) * (1 - (oModCNB:GetValue("CNB_DESC")/100)))
					oModCNS:SetValue("CNS_PRVQTD",nAux)
				Else
					nAux 	:= oModCNS:GetValue("CNS_RLZQTD") - QtdeRec
					nOldVlr := oModCNS:GetValue("CNS_PRVQTD")

					oModCNS:LoadValue("CNS_RLZQTD",nAux)

					nPosCNS:= oModCNS:GetLine()
					For nY := 1 To oModCNS:Length()
						oModCNS:GoLine(nY)
						nValCNS += oModCNS:GetValue('CNS_RLZQTD') * oModCNB:GetValue("CNB_VLUNIT",nY)
					Next
					oModCNF:SetValue("CNF_VLREAL",nValCNS)
					oModCNS:GoLine(nPosCNS)

					oModCNS:SetValue("CNS_PRVQTD",nAux)

				EndIf
				nNewSum += oModCNS:GetValue("CNS_PRVQTD")
			ElseIf nLineOri == nLinha
				nNewSum += oModCNS:GetValue("CNS_PRVQTD")
			EndIf
		Else
			If nLineOri <> nLinha
				oModCNS:LoadValue("CNS_RLZQTD",0)
				If oModCNS:GetValue("CNS_PRVQTD",nLineOri) > oModCNS:GetValue("CNS_RLZQTD",nLineOri)
					oModCNS:SetValue("CNS_PRVQTD",oModCNS:GetValue("CNS_PRVQTD",nLineOri) - oModCNS:GetValue("CNS_RLZQTD",nLineOri))
				Else
					oModCNS:SetValue("CNS_PRVQTD",0)
				EndIf
			ElseIf oModCNS:GetValue("CNS_PRVQTD") > oModCNS:GetValue("CNS_RLZQTD")
				nOldVlr := oModCNS:GetValue("CNS_PRVQTD")
				oModCNS:SetValue("CNS_PRVQTD",oModCNS:GetValue("CNS_RLZQTD"))

			EndIf
			nNewSum += oModCNS:GetValue("CNS_PRVQTD")
		EndIf
	EndIf
Next nX

//Arredonda
If nNewSum <> nQuant
	nDif := Round(nQuant - nNewSum,TamSX3('CNS_PRVQTD')[2])
	For nX := oModCNF:Length() to 1 step -1
		oModCNF:GoLine(nX)
		If !oModCNF:IsDeleted()
			oModCNS:GoLine(nLinha)
			oModCNS:SetValue("CNS_PRVQTD",oModCNS:GetValue("CNS_PRVQTD")+nDif)
			Exit
		EndIf
	Next nX
EndIf

oModCNS:GetStruct():SetProperty("CNS_PRVQTD",MODEL_FIELD_WHEN,{||.F.})
oModCNS:GetStruct():SetProperty("CNS_DISTSL",MODEL_FIELD_WHEN,{||.F.})
oModCNS:GetStruct():SetProperty("CNS_SLDQTD",MODEL_FIELD_WHEN,{||.F.})


FWRestRows(aSaveLines)
Return .T.

//------------------------------------------------------------------
/*/{Protheus.doc} A300ReajCr()
Função para reajustar cronograma financeiro

@author alexandre.gimenez
@since 27/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function A300ReajCr(oModel,nVlrReaj,lFisico)
Local oModCNF	:= oModel:GetModel("CNFDETAIL")
Local nX		:= 0
Local nSldFin	:= 0
Local nPercRj	:= 0
Local nVlrRjP	:= 0
Local nTotCro	:= 0
Local nTotPla	:= oModel:getModel("CNADETAIL"):GetValue("CNA_VLTOT")
Local nLine	:= oModCNF:Length()
Local nPos		:= 0
Local aSaveLines	:= FWSaveRows()
Local aVlrMed	:= {}
Local lReajMed	:= Cn300RetSt("REVREAJU")

Default lFisico := .F.

//-- Calcula Saldo da Planilha
For nX:= 1 To nLine
	oModCNF:GoLine(nX)
	If !oModCNF:IsDeleted()
		nSldFin += oModCNF:GetValue("CNF_SALDO")
	EndIf
Next nX

//Valores medidos e não recebidos
If	lReajMed	
nSldFin += A300SldRec('n2','')
Endif 
aVlrMed := A300sldRec('a4','')

oModCNF:SetNoUpdateLine(.F.)
//- Distribui valor reajustado proporcionalmente
For nX:= 1 To nLine
	oModCNF:GoLine(nX)
	If !oModCNF:IsDeleted()
		If !Empty(aVlrMed) .And. (nPos := aScan(aVlrMed, {|x| x[1] = oModCNF:GetValue("CNF_PARCEL")})) > 0 .AND. lReajMed
			nPercRj := aVlrMed[nPos][2] / nSldFin
		Else
		nPercRj := oModCNF:GetValue("CNF_SALDO") / nSldFin
		EndIf
		nVlrRjP := Round((nPercRj * nVlrReaj), TamSX3('CNF_VLPREV')[2])
		oModCNF:SetValue("CNF_VLPREV",oModCNF:GetValue("CNF_VLPREV")+nVlrRjP)
		nTotCro += Round(oModCNF:GetValue('CNF_VLPREV'), TamSX3('CNF_VLPREV')[2])
	EndIf
Next nX

//Arredonda ultima parcela caso necessario.
CN300AjSld(oModel,nTotPla,nTotCro)

FWRestRows(aSaveLines)
Return

//------------------------------------------------------------------
/*/{Protheus.doc} A300ReajCt()
Função para reajustar cronograma Contabil

@author alexandre.gimenez
@since 13/05/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function A300ReajCt(oModel,nVlrReaj)
Local oModCNW	:= oModel:GetModel("CNWDETAIL")
Local nX		:= 0
Local nSldCtb	:= 0
Local nPercRj	:= 0
Local nVlrRjP	:= 0
Local nTotCro	:= 0
Local nTotPla	:= oModel:getModel("CNADETAIL"):GetValue("CNA_VLTOT")
Local nLine	:= oModCNW:Length()
Local nDifCtb	:= 0
Local nRound	:= TamSX3('CNW_VLPREV')[2]
Local aSaveLines	:= FWSaveRows()

//-- Calcula Saldo disponivel para atualizar
For nX:= 1 To nLine
	oModCNW:GoLine(nX)
	If !oModCNW:IsDeleted() .And. oModCNW:GetValue("CNW_DTPREV") >= oModel:GetValue("CN9MASTER","CN9_DTREAJ")
		nSldCtb += oModCNW:GetValue("CNW_VLPREV")
	EndIf
Next nX

oModCNW:GetStruct():SetProperty('CNW_VLPREV',MODEL_FIELD_WHEN,{||.T.})

//- Distribui valor reajustado proporcionalmente
For nX:= 1 To nLine
	oModCNW:GoLine(nX)
	If !oModCNW:IsDeleted() .And. oModCNW:GetValue("CNW_DTPREV") >= oModel:GetValue("CN9MASTER","CN9_DTREAJ")
		nPercRj := oModCNW:GetValue("CNW_VLPREV") / nSldCtb
		nVlrRjP := Round((nPercRj * nVlrReaj), nRound)
		oModCNW:SetValue("CNW_VLPREV",oModCNW:GetValue("CNW_VLPREV")+nVlrRjP)
	EndIf
	nTotCro += Round(oModCNW:GetValue("CNW_VLPREV"), nRound)
Next nX

//--Arredonda ultima parcela caso necessario
nDifCtb := nTotPla - nTotCro
If nDifCtb # 0
	For nX:= nLine To 1 Step -1
		oModCNW:GoLine(nX)
		If !oModCNW:IsDeleted() .And. oModCNW:GetValue("CNW_DTPREV") >= oModel:GetValue("CN9MASTER","CN9_DTREAJ")
			oModCNW:SetValue("CNW_VLPREV",Round(oModCNW:GetValue("CNW_VLPREV"),nRound)+ Round(nDifCtb,nRound))
			Exit
		EndIf
	Next nX
EndIf

FWRestRows(aSaveLines)
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300AjSld()
Função para ajustar o saldo, caso de diferença de casas decimais

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300AjSld(oModel, nTotal, nTotCrg)
Local oCNFDetail 	:= oModel:GetModel('CNFDETAIL')
Local nDif  	   	:= 0
Local nI			:= 0
Local nRound		:= TamSX3('CNF_VLPREV')[2]
Local aSavelines	:= FWSaveRows()
Local lFisico 	:= Cn300RetSt("FISICO",0)
Local cTipRev		:= A300GTpRev()
Default nTotCrg	:= 0

If lFisico .And. !(cTipRev == DEF_REV_REAJU .Or. cTipRev == DEF_REV_REALI .Or. cTipRev == DEF_REV_RENOV .Or. cTipRev == DEF_REV_ORCGS .Or. cTipRev == DEF_REV_ABERT)// e nao for Reajuste/Realinhamento/Renovação/Orcamento Serviço/Aberta
	CN300AjSlF(oModel)
Else
	If nTotCrg == 0
		For nI := 1 To oCNFDetail:Length()
			oCNFDetail:GoLine(nI)
			If !oCNFDetail:IsDeleted()
				nTotCrg += Round(oCNFDetail:GetValue('CNF_VLPREV'),nRound)
			EndIf
		Next nI
	EndIf

	nDif := nTotal - nTotCrg

	If nDif > -5  .And. nDif < 5
		For nI:= oCNFDetail:Length() To 1 Step -1
			oCNFDetail:GoLine(nI)
			If !oCNFDetail:IsDeleted()
				oCNFDetail:SetValue('CNF_VLPREV', Round(oCNFDetail:GetValue('CNF_VLPREV'), nRound) + Round(nDif,nRound))
				Exit
			EndIf
		Next nI
	EndIf
EndIf

FWRestRows(aSaveLines)

Return
//------------------------------------------------------------------
/*/{Protheus.doc} CN300RdSld()
Função para redistribuir o saldo aditivado de acordo com
os parametros selecionados

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300RdSld()
Local oModel 		:= FwModelActive()
Local oCN9Master 	:= oModel:GetModel('CN9MASTER')
Local oCNADetail 	:= oModel:GetModel('CNADETAIL')
Local oCNFDetail 	:= oModel:GetModel('CNFDETAIL')
Local nMontPla   	:= oCNADetail:GetValue('CNA_VLTOT')
Local nSldReal   	:= 0
Local nSldDistr  	:= 0
Local nSldDif		:= 0
Local nTotDif		:= 0
Local nVlrPrv		:= 0
Local nI		   	:= 0
Local nTotCrg 		:= 0
Local nParLoc		:= 0
Local aLinhas    	:= {}
Local lSaldo     	:= oCN9Master:GetValue('CN9_CSLD')
Local lMnPla     	:= oCN9Master:GetValue('CN9_MPLA')
Local lParAnt		:= oCN9Master:GetValue('CN9_CPARCA')
Local lParRea		:= oCN9Master:GetValue('CN9_CPARCV')
Local lFisico		:= Cn300RetSt("FISICO")
Local lServico		:= Cn300RetSt("SERVIÇO")
Local lRet		   	:= .T.
Local nLNovas    	:= 0
Local aSaveLines	:= FWSaveRows()
Local nMont      	:= 0
Local cEspec   	:= Cn300RetSt("REVESPECIE")

CNTA300BlMd(oCNFDetail, .F.)

If Empty(oCN9Master:GetValue("CN9_TIPREV"))
	lRet := .F.
	Help(" ",1,"CN300TREV")
ElseIf Cn300RetSt("MEDEVE") .Or. Cn300RetSt("RECORRENTE")
	lRet := .F.
	Help('',1,'CN300NOFIN') //-- A planilha não possui cronograma financeiro.
ElseIf lFisico
	lRet := .F.
	Help( " ", 1, "CN300PLFIS") //Para planilhas com cronograma fisico, utilize a opção atualizar cronograma Financeiro/Fisico
ElseIf !(cEspec $ '1|2|4|5')
	lRet := .F.
	Help('',1,'A300NQT') //Função não disponível para este tipo de revisão
ElseIf oCN9MASTER:GetValue('CN9_CSLD') .And. oCN9MASTER:GetValue('CN9_MPLA')
	lRet := .F.
	Help( " ", 1, "CN300NPLN") // Não é possível considerar o saldo a distribuir e o montante da planilha ao mesmo tempo
ElseIf !oCN9MASTER:GetValue('CN9_CSLD') .And. !oCN9MASTER:GetValue('CN9_MPLA')
	lRet := .F.
	Help( " ", 1, "CN300NPL") //É necessário considerar o saldo a distribuir ou o montante da planilha
ElseIf !lParAnt .And. lParRea
	lRet := .F.
	Help( " ", 1, "CN300NPLC") //Para considerar as parcelas com valor realizado é necessário considerar também as parcelas anteriores
ElseIf !lParAnt .And. lParRea
	lRet := .F.
	Help( " ", 1, "CN300NPLC") //Para considerar as parcelas com valor realizado é necessário considerar também as parcelas anteriores
EndIf

If lRet .And. lServico
	lSaldo  := .F.
	lMnPla  := .T.

	If !lParRea .And. !IsBlind()
		lRet := MsgYesNo(STR0012)
    EndIf
    lParRea := .T.
EndIf

If lRet
	For nI := 1 To oCNFDetail:Length()
		oCNFDetail:GoLine(nI)
		If !oCNFDetail:IsDeleted()
			If lServico .And. lMnPla
				If A300SrvRec(oModel,1,oCNFDetail:GetValue('CNF_NUMERO'),oCNFDetail:GetValue('CNF_PARCEL'))
					nTotCrg += Round(oCNFDetail:GetValue('CNF_VLPREV'), TamSX3('CNF_VLPREV')[2])
				EndIf
			Else
				nTotCrg += Round(oCNFDetail:GetValue('CNF_VLPREV'), TamSX3('CNF_VLPREV')[2])
			EndIf
		EndIf
	Next nI

	If lMnPla .And. (nMontPla - nTotCrg) < 0
		lRet := .F.
		Help(" ",1,"CN300RMONT",,STR0013,4,0)
	EndIf
EndIf

If lRet
	If lSaldo .Or. (lServico .And. lMnPla)
		nMont := nMontPla - nTotCrg
	ElseIf lMnPla
		nMont := nMontPla
	EndIf

	If nMont != 0
		If lParAnt .And. lParRea
			If lServico
				nParLoc	:= A300SrvRec(oModel,0,oCNFDetail:GetValue('CNF_NUMERO'))
			Else
				nParLoc := 0
			EndIf
			nSldReal	:= nMont / (oCNFDetail:Length( .T. ) - nParLoc )
			nSldDistr 	:= Round(nSldReal,TamSX3('CNF_VLPREV')[2])
			nSldDif		:= nSldReal - nSldDistr

			If nMont < 0
				aLinhas := CN300ClDt(oCNFDetail, @nSldDistr, nMont ,0, aLinhas)
			EndIf

			For nI := 1 To oCNFDetail:Length()
				oCNFDetail:GoLine(nI)
				If Ascan(aLinhas, oCNFDetail:GetLine()) == 0 .And. !oCNFDetail:IsDeleted()
					If lMnPla
						If !lServico .Or. (lServico .And. !A300SrvRec(oModel,1,oCNFDetail:GetValue('CNF_NUMERO'),oCNFDetail:GetValue('CNF_PARCEL')))
						oCNFDetail:SetValue( 'CNF_VLPREV' , nSldReal )
						EndIf
					Else
						nTotDif += nSldDif
						nVlrPrv := oCNFDetail:GetValue('CNF_VLPREV') + nSldDistr
						If nTotDif >= 0.01 .Or. nTotDif <= -0.01
							nVlrPrv += Round(nTotDif,TamSX3("CNF_VLPREV")[2])
							nTotDif -= Round(nTotDif,TamSX3("CNF_VLPREV")[2])
						EndIf
						If nI == oCNFDetail:Length()
							nTotDif := Round(nTotDif,TamSX3("CNF_VLPREV")[2])
							nVlrPrv += nTotDif
						EndIf
						If Cn300RetSt('SERVIÇO') .And. nVlrPrv == 0
							oCNFDetail:DeleteLine()
						ElseIf nVlrPrv <= 0
							Help(" ",1,"CN300RVLPR",,STR0007,4,0) //'Não é possível zerar o valor de uma parcela. Reduza a quantidade de parcelas do cronograma ou redistribua o saldo manualmente.'
							Exit
						Else
							If !lServico .Or. !A300SrvRec(oModel,1,oCNFDetail:GetValue('CNF_NUMERO'),oCNFDetail:GetValue('CNF_PARCEL'))
					    	oCNFDetail:SetValue('CNF_VLPREV', If(lMnPla, 0, nVlrPrv))
							EndIf
						EndIf
					EndIf
				EndIf
			Next nI

		//-- Considera parcelas antigas
		ElseIf lParAnt
			For nI := 1 To oCNFDetail:Length()
				oCNFDetail:GoLine(nI)
				If oCNFDetail:IsDeleted()
					Loop
				EndIf
				If oCNFDetail:GetValue('CNF_VLREAL') == 0 .And. !oCNFDetail:IsDeleted()
					Aadd(aLinhas, oCNFDetail:GetLine())
				EndIf
			Next nI

			nSldReal	:= nMont / Len(aLinhas)
			nSldDistr 	:= Round(nSldReal,TamSX3('CNF_VLPREV')[2])
			nSldDif		:= nSldReal - nSldDistr

			For nI := 1 To Len(aLinhas)
				oCNFDetail:GoLine(aLinhas[nI])
					nTotDif += nSldDif
					If lServico
						nVlrPrv := nSldDistr
					Else
						nVlrPrv := oCNFDetail:GetValue('CNF_VLPREV') +  nSldDistr
					EndIf
					If nTotDif >= 0.01 .Or. nTotDif <= -0.01
						nVlrPrv += Round(nTotDif,TamSX3("CNF_VLPREV")[2])
						nTotDif -= Round(nTotDif,TamSX3("CNF_VLPREV")[2])
					EndIf
					If nI == Len(aLinhas)
						nTotDif := Round(nTotDif,TamSX3("CNF_VLPREV")[2])
						nVlrPrv += nTotDif
					EndIf
				If Cn300RetSt('SERVIÇO') .And. nVlrPrv == 0
					oCNFDetail:DeleteLine()
				ElseIf nVlrPrv <= 0
						Help(" ",1,"CN300RVLPR",,STR0007,4,0) //'Não é possível zerar o valor de uma parcela. Reduza a quantidade de parcelas do cronograma ou redistribua o saldo manualmente.'
						Exit
					Else
					oCNFDetail:SetValue('CNF_VLPREV', If(lMnPla, 0, nVlrPrv))
				EndIf
			Next nI
		Else
			//-- Redistribui somente para as linhas novas
			nLNovas := CN300LenNw(oCNFDetail)
			If nLNovas > 0
				nSldReal	:= nMont / nLNovas
				nSldDistr 	:= Round(nSldReal,TamSX3('CNF_VLPREV')[2])
				nSldDif	:= nSldReal - nSldDistr

				For nI := 1 To oCNFDetail:Length()
					oCNFDetail:GoLine(nI)
					If oCNFDetail:IsInserted() .And. !oCNFDetail:IsDeleted()
							nTotDif += nSldDif
							If lServico
								nVlrPrv := nSldDistr
							Else
							nVlrPrv := oCNFDetail:GetValue('CNF_VLPREV') +  nSldDistr
							EndIf
							If nTotDif >= 0.01 .Or. nTotDif <= -0.01
								nVlrPrv += Round(nTotDif,TamSX3("CNF_VLPREV")[2])
								nTotDif -= Round(nTotDif,TamSX3("CNF_VLPREV")[2])
							EndIf
							If nI == oCNFDetail:Length()
								nTotDif := Round(nTotDif,TamSX3("CNF_VLPREV")[2])
								nVlrPrv += nTotDif
							EndIf
						If Cn300RetSt('SERVIÇO') .And. nVlrPrv == 0
							oCNFDetail:DeleteLine()
						ElseIf nVlrPrv <= 0
								Help(" ",1,"CN300RVLPR",,STR0007,4,0) //'Não é possível zerar o valor de uma parcela. Reduza a quantidade de parcelas do cronograma ou redistribua o saldo manualmente.'
								Exit
							Else
							oCNFDetail:SetValue('CNF_VLPREV', If(lMnPla, 0, nVlrPrv))
						EndIf
					EndIf

				Next nI
			EndIf
		EndIf
	EndIf
	//-- Se eu não estiver considerando parcelas antigas nem parcelas realizadas e não tiver nenhuma linha nova não executo o Ajuste de Saldo
	//-- Pois jogará todo o valor para última parcela e ficará sem sentido.
	If !(!lParAnt .And. !lParRea .And. nLNovas == 0)
		CN300AjSld(oModel, nMontPla)
	EndIf
EndIf
CNTA300BlMd(oCNFDetail, ,.T.)
FWRestRows(aSaveLines)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300VlCau(oModel,oModelCN8)
Função para validar o percentual minimo da caução manual

@author aline.sebrian
@since 24/02/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------
Function cn300VlCau()
Local lRet      := .T.
Local nFor      := 0
Local nValor    := 0
Local nMinimo   := NoRound((CN9->CN9_VLATU*CN9->CN9_MINCAU)/100,MsDecimais())
Local oModel    := FwModelActive()
Local oModelCN8 := oModel:GetModel("CN8DETAIL")
Local oModelCN9	:= oModel:GetModel("CN9MASTER")
Local lCaucaoR  := oModelCN9:GetValue("CN9_TPCAUC") == '2'

For nFor := 1 To oModelCN8:Length()
	oModelCN8:GoLine(nFor)
    nValor += oModelCN8:GetValue("CN8_VLEFET")
Next nFor

If !lCaucaoR .And. nMinimo > nValor
	Help("",1,"CNTA100MINVM",, STR0001 + AllTrim(Str(nMinimo)) + "." ,4)//'O valor mínimo é de '
	lRet := .F.
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300CheckM()
Verifica se existe medicao em aberto para o contrato

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300CheckM()
Local cAlias 	:= GetNextAlias()
Local oModel    := FwModelActive()
Local oModelCN9 := Nil
Local cContra	:= ""
Local cQuery 	:= ""
local lRet 		:= .T.
Local cFilCPD 	:= xFilial("CPD")
Local aComp		:= {xFilial("CND")}
Local nX		:= 0
Local lCN300RCM := ExistBlock("CN300RCM")

If IsInCallStack("CN300TOK")
	oModelCN9	:= oModel:GetModel("CN9MASTER")
	cContra		:= oModelCN9:GetValue("CN9_NUMERO")
Else
	cContra	:= CN9->CN9_NUMERO
EndIf

If CPD->(dbSeek(cFilCPD+cContra))
	While CPD->(CPD_FILIAL+CPD_CONTRA) == cFilCPD+cContra .and. CPD->(! Eof())

		if Ascan(aComp,CPD->CPD_FILAUT) = 0
			aAdd(aComp,CPD->CPD_FILAUT)
		EndIf
		CPD->(dbSkip())
	Enddo
EndIf

cQuery := " SELECT COUNT(*) AS QTD "
cQuery += " FROM "+RetSQLName("CND")+" CND "
cQuery += " WHERE CND.CND_FILIAL IN ('"

For nX := 1 to Len(aComp)
	If nX>1
		cQuery += ",'"
	EndIf
	cQuery += aComp[nX]+"'"
Next nX

cQuery += ")  AND CND.CND_CONTRA = '"+cContra+"'"
cQuery += "   AND CND.CND_DTFIM  = ''"
cQuery += "   AND CND.D_E_L_E_T_ = ' '"

If lCN300RCM
	lRet := ExecBlock("CN300RCM",.F.,.F.,{cContra,cQuery})
	lCN300RCM := ValType(lRet) == "L"
EndIf

If !lCN300RCM
	lRet := .T.
cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.F.,.T.)

If (cAlias)->QTD > 0
	Help("",1,"A300CheckM") //O contrato selecionado possui medição em aberto. Encerre a medição antes de gerar a revisão.
	lRet := .F.
EndIf

(cAlias)->(dbCloseArea())
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300CNBOri()
Salva valor original dos campos quantidade e preco

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300CNBOri(oModel)
Local nX	:= 0
Local nY	:= 0
Local oModelCNA	:= oModel:GetModel("CNADETAIL")
Local oModelCNB	:= oModel:GetModel("CNBDETAIL")
Local aSaveLines:= FWSaveRows()
Local aPropCNB	:= GetPropMdl(oModelCNB)

CNTA300BlMd(oModelCNB,,.T.)

// Roda Planilhas
For nX := 1 to oModelCNA:Length()
	oModelCNA:GoLine(nX)
	If Cn300RetSt("FIXO")
		For nY := 1 to oModelCNB:Length() //Roda Itens
			oModelCNB:GoLine(nY)
			oModelCNB:LoadValue("CNB_PRCORI",oModelCNB:GetValue("CNB_VLUNIT"))
			oModelCNB:LoadValue("CNB_QTDORI",oModelCNB:GetValue("CNB_QUANT"))
		Next nY
	Endif
Next nX

RstPropMdl(oModelCNB,aPropCNB)
FWRestRows(aSaveLines)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} A300RevMed()
Função para analisar os antigos parametro CNREAJM e CNREALM disponiveis
no tipo de contrato

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300RevMed(nModo)
Local lRet		:= 	.F.
Local aArea	    := 	GetArea()
Local lReajMd := 	.F.		//- Reajusta Medição
Local lRealMd := 	.F.		//- Realinha Medição
Local cTipRev	:= 	A300GTpRev()+"|"+A300GATpRv()

Default nModo	:= 2

lReajMd := Cn300RetSt("REVREAJU",nModo)
lRealMd := Cn300RetSt("REVREALI",nModo)

If ( lReajMd .And. DEF_REV_REAJU $ cTipRev ) .Or. ( lRealMd .And. DEF_REV_REALI $ cTipRev )
	lRet := .T.
EndIf

RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300VlrCnb()
Função para validar o campo cnb_vlunit na revisao e identificar a
necessidade de dividir o mesmo.

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300VlrCNB(cField,nNewValue,nOldValue)
Local aArea		:= GetArea()
Local aWhenCNF	:= {}
Local aWhenCNB	:= {}
Local oModel	:= FwModelActive()
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local oModCNF	:= oModel:GetModel("CNFDETAIL")
Local oModCN9	:= oModel:GetModel("CN9MASTER")
local cModo		:= Cn300RetSt("MODALIDADE")
Local lServico	:= Cn300RetSt("SERVIÇO")
Local cTipRev	:= A300GTpRev()
Local lRevMed 	:= A300RevMed(0) .And. cTipRev <> DEF_REV_RENOV
Local lQuebra 	:= .F.
Local lRet		:= .T.
Local lMsmVlr	:= nNewValue <> nOldValue .Or. cTipRev == DEF_REV_ORCGS
Local nQtdNRec	:= 0
Local nVlrDes	:= 0
Local nValue	:= 0
Local lDivItem	:= .F.
Local lAuto		:= IsBlind()

// Verifica se é revisão
If !IsInCallStack('CNAddItRt') .And. lMsmVlr

	If ExistFunc('GCTGetWhen')
		aWhenCNF := GCTGetWhen(oModCNF)
		aWhenCNB := GCTGetWhen(oModCNB)
	EndIf

	oModCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})
	oModCNB:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})

	//-- Validação de acrescimo ou decrescimo
	If !Empty(cTipRev) .And. !IsInCallStack("A300DivCNB") .And. !oModCNB:IsInserted()
		If lRet .And. cTipRev == DEF_REV_REALI .And. cModo <> "3" /*Quando Ambos não valida*/
			DbSelectArea("CNB")
			CNB->(DbSetorder(1))
			If CNB->(DbSeek(xFilial("CNB")+oModCN9:GetValue("CN9_NUMERO")+CN9->CN9_REVISA+oModCNB:GetValue("CNB_NUMERO")+oModCNB:GetValue("CNB_ITEM")))
				If cField == "CNB_VLUNIT"
					//Quando for apenas acrescimo
					If cModo == "1"
						lRet	:= ( nNewValue * (1-(oModCNB:GetValue("CNB_DESC")/100)) >= oModCNB:GetValue("CNB_PRCORI")*(1-(CNB->CNB_DESC/100)) )
					//Quando for apenas decrescimo
					ElseIf cModo == "2"
						lRet	:= (nNewValue * (1-(oModCNB:GetValue("CNB_DESC")/100)) <= oModCNB:GetValue("CNB_PRCORI")*(1-(CNB->CNB_DESC/100)) )
					EndIf
				ElseIf cField == "CNB_DESC"
					//Quando for apenas acrescimo
					If cModo == "1"
						lRet	:= ( oModCNB:GetValue("CNB_VLUNIT") * (1-(nNewValue/100)) >= oModCNB:GetValue("CNB_PRCORI")*(1-(CNB->CNB_DESC/100)) )
					//Quando for apenas decrescimo
					ElseIf cModo == "2"
						lRet	:= ( oModCNB:GetValue("CNB_VLUNIT") * (1-(nNewValue/100)) <= oModCNB:GetValue("CNB_PRCORI")*(1-(CNB->CNB_DESC/100)) )
					EndIf
				EndIf
			EndIf

			If !lRet
				Help("",1,"A300MODREALI") //Modalidade da revisão (Acrescimo/Decrescimo) não respeitado
			EndIf
		EndIf
	EndIf

	If lRet .And. !Empty(cTipRev) .And. !IsInCallStack("A300DivCNB") .And. Cn300RetSt("FIXO") .And. !Cn300RetSt("RECORRENTE")
		// Valida somente Reajuste, Realinhamento, Renovação e planilhas de serviços.
		If !oModCNB:IsInserted() .And. (cTipRev $ DEF_REV_REAJU+"|"+DEF_REV_REALI+"|"+DEF_REV_RENOV+"|"+DEF_REV_ORCGS .Or. lServico)
			If oModCNB:GetValue("CNB_SLDREC") == 0 .And. !(cTipRev $ DEF_REV_RENOV+"|"+DEF_REV_ORCGS)
				lRet := .F.
				Help("",1,"A300TOTRECEBI") //Item totalmente recebido, sem saldo para ser alterado.
			ElseIf !Empty(oModCNB:GetValue("CNB_ITMDST")) // Item ja quebrado, nao pode ser alterado novamente.
				lRet := .F.
				Help("",1,"A300DIVIDIDO") // Item dividido, nao pode ser alterado novamente.
			EndIf

			//-----------------------------------------------------------
			// Ponto de entrada na validação do campo CNB_VLUNIT
			//-----------------------------------------------------------
			If lRet .And. ExistBlock("A300RVUN")
				lRet := ExecBlock("A300RVUN",.F.,.F.,{oModel,lQuebra,nOldValue,nNewValue})
				If ValType( lRet ) <> "L"
					lRet := .F.
				EndIf
			Endif

			If lRet
				nQtdNRec := A300SldRec('n',oModel:GetModel("CNBDETAIL"):GetValue("CNB_ITEM"))
				If !lRevMed // Parametro de Revisar medição (Inativo)
					If oModCNB:GetValue("CNB_SLDMED") == 0 .And. !(cTipRev $ DEF_REV_RENOV+"|"+DEF_REV_ORCGS) // Sem Saldo a Medir
						lRet := .F.
						Help("",1,"A300TOTMEDI") // Item totalmente medido, sem saldo para ser alterado.
					ElseIf (oModCNB:GetValue("CNB_QTDORI") <>  oModCNB:GetValue("CNB_SLDMED") .Or.;
						 	oModCNB:GetValue("CNB_QTDORI") <>  oModCNB:GetValue("CNB_QUANT")) .And.;
						 	oModCNB:GetValue("CNB_QTDMED") > 0  // Item teve movimentação, tem que quebrar
						lQuebra := .T.
					EndIf
				Else // Parametro de Revisar medição (Ativo)
					If oModCNB:GetValue("CNB_QTDMED") > nQtdNRec
						lQuebra := .T.
					EndIf
				EndIf
			EndIf
		EndIf

		If lRet
			If lQuebra .And. !oModCNB:IsInserted()
				If cTipRev == DEF_REV_REALI
				//-- Efetuar tratamento para não dar a mensagem quando não tiver view
				 	If lAuto
				 		lDivItem := .T.
					Else
				 		lDivItem := MsgYesNo(STR0009,STR0008) //- "Para essa alteração será necessário dividir o item, pois há medições para essa planilha. Deseja prosseguir?"
				 	EndIf
				ElseIf cTipRev == DEF_REV_RENOV
					If lAuto
				 		lDivItem := .T.
				 	Else
				 		lDivItem := MsgYesNo(STR0009,STR0008)
				 	EndIf
				ElseIf cTipRev == DEF_REV_ABERT
					If lAuto
				 		lDivItem := .T.
				 	Else
				 		lDivItem := MsgYesNo(STR0009,STR0008)
				 	EndIf
				ElseIf cTipRev == DEF_REV_REAJU .Or. cTipRev == DEF_REV_ORCGS //Para Reajuste não precisa realizar a pergunta, sempre vai dividir o item
					lDivItem := .T.
				EndIf

				If lDivItem
					A300OpenMd({||}, .F.)
				Else
					lRet := .F.
					oModel:SetErrorMessage( "CNBDETAIL", "CNB_VLUNIT", "CNBDETAIL", "CNB_VLUNIT", "", STR0033) // Ação cancelada pelo usuário
				EndIf

				If lRet
					If cField == "CNB_VLUNIT"
						oModCNB:LoadValue("CNB_VLUNIT",nOldValue)
						oModCNB:SetValue("CNB_VLTOT",nOldValue*oModCNB:GetValue('CNB_QUANT'))
					ElseIf cField == "CNB_DESC"
						oModel:GetModel("CNBDETAIL"):LoadValue("CNB_DESC",nOldValue)
					EndIf
					lRet := A300DivCNB(oModel,lRevMed,nNewValue,nQtdNRec,cField)
				EndIf
			EndIf
			nValue := oModCNB:GetValue("CNB_DESC")

			//--Atualiza Valor do Desconto.
			If lRet
				If Positivo(nValue) .And. nValue < 100
					If Cn300RetSt("COMPRA")
						nVlrDes := (nValue / 100) * oModCNB:GetValue("CNB_VLTOT")
					Else
						FtDescItem(0,oModCNB:GetValue("CNB_VLUNIT"),oModCNB:GetValue("CNB_QUANT"),0,@nValue,@nVlrDes,0,1)
					EndIf
				Else
					nVlrDes := oModCNB:GetValue("CNB_VLDESC")
				EndIf
				oModCNB:GetStruct():SetProperty("CNB_VLDESC",MODEL_FIELD_WHEN,{||.T.})
				oModCNB:SetValue("CNB_VLDESC", nVlrDes)

			EndIf

			A300AtCauR(oModel)
			If cTipRev $ DEF_REV_REALI+'|'+DEF_REV_RENOV+'|'+DEF_REV_ORCGS+'|'+DEF_REV_ABERT
				A300Revisa(oModel, cTipRev) //-- trava modelo novamente
			EndIf
		EndIf
	EndIf

	If ExistFunc('GCTRstWhen')
		GCTRstWhen( oModCNF , aWhenCNF )
		GCTRstWhen( oModCNB , aWhenCNB )
	EndIf
EndIf

RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300DivCNB()
Funcao para dividir o item da tabela CNB quando é alterado o item na revisao
e o mesmo ja possua medições

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300DivCNB(oModel,lRevMed,nNewValue,nQtdNRec,cField)
Local lRet		:= .T.
Local lFisico 	:= Cn300RetSt("FISICO",0)
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local oModCNS	:= oModel:GetModel("CNSDETAIL")
Local oModelCNZ := oModel:GetModel("CNZDETAIL")
Local lRateio   := !Empty(oModelCNZ:GetValue("CNZ_CODPLA"))
Local nR        := 0
Local nLineOri	:= oModCNB:GetLine()
Local nLineDst	:= 0
Local nX		:= 0
Local aHeader	:= oModCNB:GetStruct():GetFields()
Local aDados	:= {}
Local cCampo	:= ""
Local nQtdRec	:= 0
Local nNaoRec	:= 0
Local nSldRec	:= 0
Local nForaDt	:= 0
Local nDecQuant	:= TamSX3("CNB_QUANT")[2]
Local nQuant	:= 0
Local aQntMed	:= Nil
Local nVlrProd	:= oModCNB:GetValue("CNB_VLTOT")
Local aRateio   := {}

// copia dados da origem
For nX := 1 to Len(aHeader)
	cCampo := AllTrim(aHeader[nX][MODEL_FIELD_IDFIELD])
	If cCampo $ "CNB_QUANT|CNB_QTDMED"
		aAdd(aDados,{cCampo,oModCNB:GetValue("CNB_QUANT") - oModCNB:GetValue("CNB_SLDREC"),oModCNB:GetValue("CNB_QUANT") - oModCNB:GetValue("CNB_SLDREC")})
	ElseIf cCampo $ "CNB_SLDMED|CNB_SLDREC"
		aAdd(aDados,{cCampo,0,0})
	Else
		aAdd(aDados,{cCampo,oModCNB:GetValue(cCampo),oModCNB:GetValue(cCampo)})
	EndIf
Next nX

oModCNB:SetNoInsertLine(.F.)
nLineDst := oModCNB:AddLine()
If nLineDst == nLineOri // Não foi possivel adicionar linha
	lRet := .F.
Else // Duplica Linha
	nQtdRec := oModCNB:GetValue("CNB_QTDMED",nLineOri) - nQtdNRec 									// Valor Recebido
	nNaoRec := oModCNB:GetValue("CNB_SLDREC",nLineOri) - oModCNB:GetValue("CNB_SLDMED",nLineOri) 	// Valor medido nao recebido ainda.
	nSldRec := oModCNB:GetValue("CNB_SLDMED",nLineOri) + nQtdNRec 									// Saldo recebido considerando valor fora de data
	nForaDt := oModCNB:GetValue("CNB_SLDREC",nLineOri) - oModCNB:GetValue("CNB_SLDMED",nLineOri) - nQtdNRec

	For nX := 1 to len(aDados)
		If !(aDados[nX,1]) $ "CNB_REALI|CNB_VLTOTR|CNB_VLDESC" // Campos Calculados
			If	aDados[nX,1] == "CNB_VLUNIT"
				oModCNB:SetValue(aDados[nX,1],IIF(cField == "CNB_VLUNIT",nNewValue,aDados[nX,2]))
			ElseIf aDados[nX,1] == "CNB_ITEM"
				//Quantidade Nova
				oModCNB:LoadValue(aDados[nX,1],soma1(oModCNB:GetValue("CNB_ITEM",oModCNB:GetLine()-1)))
				//Quantidade Origem
			ElseIf aDados[nX,1] == "CNB_QUANT"
				//Quantidade Nova
				If !(A300GTpRev() $ DEF_REV_RENOV+"|"+DEF_REV_ORCGS+'|'+DEF_REV_ABERT)
					nQuant	:= Round( IIF( lRevMed , nSldRec , oModCNB:GetValue( "CNB_SLDMED" , nLineOri ) ) , nDecQuant )
					oModCNB:SetValue( aDados[nX,1] , nQuant )
				Else
					nQuant	:= Round( oModCNB:GetValue( 'CNB_QUANT' , nLineOri ) - ( oModCNB:GetValue( "CNB_QTDMED" , nLineOri ) + Iif( lRevMed , nQtdNRec , 0 ) ) , nDecQuant )
					oModCNB:SetValue( aDados[nX,1] , nQuant )
				Endif
				//Quantidade Origem
				aDados[nX,3] := Round ( IIF( lRevMed , nQtdRec , oModCNB:GetValue( "CNB_QTDMED" , nLineOri ) ) , nDecQuant )
			ElseIf aDados[nX,1] == "CNB_QTDMED"
				//Quantidade Medida Nova
				oModCNB:LoadValue(aDados[nX,1],IIF(lRevMed,nQtdNRec,0))
				//Quantidade Medida Origem
				aDados[nX,3] := IIF(lRevMed,nQtdRec,oModCNB:GetValue("CNB_QTDMED",nLineOri))
			ElseIf aDados[nX,1] == "CNB_SLDMED"
				//Saldo a Medir Novo
				oModCNB:LoadValue(aDados[nX,1],oModCNB:GetValue("CNB_QUANT")-oModCNB:GetValue("CNB_QTDMED") )
				//Saldo a Medir Origem
				aDados[nX,3] := 0
			ElseIf aDados[nX,1] == "CNB_SLDREC"
				//Saldo a Receber Novo
				oModCNB:LoadValue(aDados[nX,1],IIF(lRevMed,nSldRec,oModCNB:GetValue("CNB_SLDMED",nLineOri)))
				//Saldo a Receber Origem
				aDados[nX,3] := IIF(lRevMed,nForaDt,nNaoRec)
			ElseIf aDados[nX,1] == "CNB_ITMDST"
				// Deixa item novo em branco
				oModCNB:LoadValue(aDados[nX,1],"")
				// Atualiza linha origem - vincula item destino
				aDados[nX,3] := oModCNB:GetValue("CNB_ITEM")
			ElseIf aDados[nX,1] == "CNB_QTDORI"
				// Quantidade Origem nova, igual o quantidade do registro
				oModCNB:LoadValue(aDados[nX,1],oModCNB:GetValue("CNB_QUANT"))
				// Quantidade Origem Origem, Mantem a mesma
			ElseIf aDados[nX,1] == "CNB_VLTOT"
				// Valor Total Novo
					//Calculado
				//Valor Total Origem
				aDados[nX,3] := oModCNB:GetValue("CNB_QUANT",nLineOri)*oModCNB:GetValue("CNB_VLUNIT",nLineOri)
			ElseIf aDados[nX,1] == "CNB_DESC"
				// Desconto Novo
				oModCNB:SetValue(aDados[nX,1],IIF(cField == "CNB_DESC",nNewValue,oModCNB:GetValue(aDados[nX,1],nLineOri)))
			Else
				oModCNB:LoadValue(aDados[nX,1],aDados[nX,2])
			EndIf
		EndIf
	Next nX

	oModCNB:GoLine(nLineOri)

	//Atualiza linha origem com dados recalculados
	oModCNB:GetStruct():SetProperty("CNB_QUANT",MODEL_FIELD_WHEN,{|| .T.})
	For nX := Len(aDados) To 1 Step -1
		If !(aDados[nX,1]) $ "CNB_VLTOT"
			If aDados[nX,1] $ "CNB_QUANT|CNB_VLUNIT|CNB_DESC"
				oModCNB:SetValue(aDados[nX,1],aDados[nX,3])
			Else
				oModCNB:LoadValue(aDados[nX,1],aDados[nX,3])
			EndIf
		EndIf
	Next nX

	oModCNB:GetStruct():SetProperty("CNB_QUANT",MODEL_FIELD_WHEN,{|| .F.})
EndIf

//Ajusta cronograma fisico
If lFisico
	aQntMed := A300SldRec('a', oModCNB:GetValue("CNB_ITEM"))

	//Linha Nova
	oModCNB:GoLine(nLineDst)
	CN300AddFis(oModel,oModCNB:GetValue("CNB_ITEM"),oModCNB:GetValue("CNB_PRODUT"),oModCNB:GetValue("CNB_QUANT"))
	A300AtuCrF(oModel,oModCNB:GetValue("CNB_QUANT"),aQntMed,oModCNB:GetLine(),nLineOri)

	//Linha Origem
	oModCNB:GoLine(nLineOri)
	A300AtuCrF(oModel,oModCNB:GetValue("CNB_QUANT"),aQntMed,oModCNB:GetLine())
EndIf

//-----------------------------------------------------------
// Ponto de entrada na divisão de linhas dos itens
//-----------------------------------------------------------
If ExistBlock("A300RDVI")
   ExecBlock("A300RDVI",.F.,.F.,{oModel,nLineDst,nLineOri,nNewValue})
Endif

If lRateio
 For nR := 1 To  oModelCNZ:Length() 
   
    oModelCNZ:GoLine(nR)
	aAdd(aRateio,{oModelCNZ:Getvalue("CNZ_CONTRA"),;
	              oModelCNZ:Getvalue("CNZ_REVISA"),;
	              oModelCNZ:Getvalue("CNZ_CODPLA"),;
	              StrZero(oModCNB:length(),TamSX3("CNZ_ITCONT")[1]),;
	 			  oModelCNZ:Getvalue("CNZ_NUMMED"),;
	              oModelCNZ:Getvalue("CNZ_FORNEC"),;
			      oModelCNZ:Getvalue("CNZ_LJFORN"),;
			      oModelCNZ:Getvalue("CNZ_CLIENT"),;
			      oModelCNZ:Getvalue("CNZ_LOJACL"),;
    			  oModelCNZ:Getvalue("CNZ_ITEM"),;
	 			  oModelCNZ:Getvalue("CNZ_PERC"),;
   			      oModelCNZ:Getvalue("CNZ_CC"),;
				  oModelCNZ:Getvalue("CNZ_CONTA"),;
				  oModelCNZ:Getvalue("CNZ_ITEMCT"),;
				  oModelCNZ:Getvalue("CNZ_CLVL")})

  Next

   oModCNB:GoLine(oModCNB:length())
   
  For nR:= 1 to Len(aRateio)

    If nR > 1
	   oModelCNZ:AddLine()
   	EndIf

	oModelCNZ:LoadValue("CNZ_CONTRA",aRateio[nR][1])
	oModelCNZ:LoadValue("CNZ_REVISA",aRateio[nR][2])
	oModelCNZ:LoadValue("CNZ_CODPLA",aRateio[nR][3])
	oModelCNZ:LoadValue("CNZ_ITCONT",aRateio[nR][4])
	oModelCNZ:LoadValue("CNZ_NUMMED",aRateio[nR][5])
		
    If !Empty(aRateio[nR][6])
		oModelCNZ:SetValue("CNZ_FORNEC",aRateio[nR][6])
		oModelCNZ:SetValue("CNZ_LJFORN",aRateio[nR][7])
	Else
		oModelCNZ:SetValue("CNZ_CLIENT",aRateio[nR][8])
		oModelCNZ:SetValue("CNZ_LOJACL",aRateio[nR][9])
	EndIf
	oModelCNZ:SetValue('CNZ_ITEM',aRateio[nR][10])
	oModelCNZ:SetValue('CNZ_PERC',aRateio[nR][11])
	oModelCNZ:SetValue('CNZ_CC',aRateio[nR][12])
	oModelCNZ:SetValue('CNZ_CONTA',aRateio[nR][13])
	oModelCNZ:SetValue('CNZ_ITEMCT',aRateio[nR][14])
	oModelCNZ:SetValue('CNZ_CLVL',aRateio[nR][15])
    
	nPerc := (aRateio[nR][11] / 100)
	nVlrRat := nVlrProd * nPerc

	oModelCNZ:SetValue("CNZ_VALOR1",nVlrRat)
	oModelCNZ:SetValue("CNZ_VALOR2",xMoeda(nVlrRat,1,2,dDatabase))
	oModelCNZ:SetValue("CNZ_VALOR3",xMoeda(nVlrRat,1,3,dDatabase))
	oModelCNZ:SetValue("CNZ_VALOR4",xMoeda(nVlrRat,1,4,dDatabase))
	oModelCNZ:SetValue("CNZ_VALOR5",xMoeda(nVlrRat,1,5,dDatabase)) 
  Next

Endif 

cn300BlqLn()
//Linha Origem
oModCNB:GoLine(nLineOri)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300VlrInd()
Busca Valor do indice na tabela de historico

@author alexandre.gimenez
@since 24/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300VlrInd(cIndice, dDataRef, lProRat, dDataApl, dDtRjAnt, dDtPrxRj,lPercent)
Local nRet		 := 0
Local nPercProRat:= 0
Local aArea	     := GetArea()

Default lProRat  := .F.
Default lPercent := .F.

// Caso não seja informado o indice busca o indice do contrato.
If Empty(cIndice)
	cIndice := CN9->CN9_INDICE
EndIf

// Seleciona indice do contrato
If Posicione("CN6",1,xFilial("CN6")+cIndice,"CN6_TIPO") == "1"//Diario
	//Seleciona historico do indice diario
	dbSelectArea("CN7")
	CN7->(dbSetOrder(1))
	If dbSeek(xFilial("CN7")+cIndice+DTOS(dDataRef))
		nRet := CN7->CN7_VLREAL
	EndIf
Else
	//Seleciona historico do indice mensal
	dbSelectArea("CN7")
	CN7->(dbSetOrder(2))	//- CN7_FILIAL+CN7_CODIGO+CN7_COMPET
	If dbSeek(xFilial("CN7")+cIndice+strzero(Month(dDataRef),2)+"/"+strzero(Year(dDataRef),4))
		nRet := CN7->CN7_VLREAL
	EndIf
EndIf

//Se for Pro Rata, resgata o índice proporcional para o cálculo do reajuste do periodo
If lProRat .And. !Empty(dDtPrxRj) .And. !Empty(dDtrjAnt)
	If Int( dDtPrxRj - dDtRjAnt ) > 0
		nPercProRat := Int( dDataApl - dDtRjAnt ) / Int( dDtPrxRj - dDtRjAnt ) //Calcula  a proporcionalidade do período parcial pelo o período integral do reajuste
		If nPercProRat > 0 .And. nPercProRat < 1 //Não deve zerar o índice nem aumentá-lo
			nRet := nRet * nPercProRat
		Endif
	EndIf
EndIf

// Transforma indice em percentual.
If !lPercent
	nRet := (nRet/100) + 1
EndIf
RestArea(aArea)
Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300ApAr(oModel)
Aplica o arrasto nas parcelas.

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*///-------------------------------------------------------------------
Function CN300ApAr(oModel)
Local oCN9Master := oModel:GetModel('CN9MASTER')
Local oCNFDetail := oModel:GetModel('CNFDETAIL')
Local oCNADetail := oModel:GetModel('CNADETAIL')
Local lRedVlrs   := oCN9Master:GetValue('CN9_REDVAL') == '1'
Local nI := 0
Local nSldDist := 0
Local nSldReal := 0
Local nSldDif	 := 0
Local nTotDif	 := 0
Local nVlrPrv	 := 0
Local aLinhas := {}
Local aSaveLines	:= FWSaveRows()

For nI := 1 To oCNFDetail:Length()
	oCNFDetail:GoLine(nI)
	If oCNFDetail:IsDeleted()
		Loop
	EndIf

	If oCNFDetail:GetValue('CNF_SALDO') <> oCNFDetail:GetValue('CNF_VLPREV')
		nSldDist += oCNFDetail:GetValue('CNF_SALDO')
		oCNFDetail:SetValue('CNF_VLPREV', oCNFDetail:GetValue('CNF_VLREAL'))
		oCNFDetail:SetValue('CNF_SALDO', 0)
	EndIf

	If !lRedVlrs
		If oCNFDetail:GetValue('CNF_VLREAL') == 0 .And. Len(aLinhas) == 0
			Aadd(aLinhas, oCNFDetail:GetLine())
		EndIf
	ElseIf oCNFDetail:GetValue('CNF_VLREAL') == 0
		Aadd(aLinhas, oCNFDetail:GetLine())
		nSldDist += oCNFDetail:GetValue('CNF_SALDO')  
	EndIf
Next nI

If !Empty(aLinhas)
	If !lRedVlrs
		oCNFDetail:GoLine(aLinhas[1])
		oCNFDetail:SetValue('CNF_VLPREV', oCNFDetail:GetValue('CNF_VLPREV') + nSldDist)
	Else
		nSldReal :=  oCNADetail:GetValue('CNA_SALDO') / Len(aLinhas)
		nSldDist := Round(nSldReal,TamSX3('CNF_VLPREV')[2])
		nSldDif  := nSldReal - nSldDist

		For nI := 1 To Len(aLinhas)
			oCNFDetail:GoLine(aLinhas[nI])
			nTotDif += nSldDif
			nVlrPrv := nSldDist
			If nTotDif >= 0.01 .Or. nTotDif <= -0.01
				nVlrPrv += Round(nTotDif,TamSX3("CNF_VLPREV")[2])
				nTotDif -= Round(nTotDif,TamSX3("CNF_VLPREV")[2])
			EndIf
			If nI == Len(aLinhas)
				nTotDif := Round(nTotDif,TamSX3("CNF_VLPREV")[2])
				nVlrPrv += nTotDif
			EndIf

			oCNFDetail:SetValue('CNF_VLPREV', nVlrPrv)
		Next nI
	EndIf
EndIf

CN300AjSld(oModel, oModel:GetModel("CALC_CNF"):GetValue('CNF_CALC'))
oCNADetail:LoadValue('CNA_SADIST', CN300SdDt(oModel))

FWRestRows(aSaveLines)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300IcPrc(oModel)
Inclui parcelas no contrato.

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300IcPrc(oModel, aSldsFis)
Local aSaveLines	:= FWSaveRows()
Local oCN9Master:= oModel:GetModel('CN9MASTER')
Local oCNFDetail:= oModel:GetModel('CNFDETAIL')
Local oCNBDetail:= oModel:GetModel('CNBDETAIL')
Local oCNSDetail:= oModel:GetModel('CNSDETAIL')
Local cParce		:= strzero(0,TamSx3("CNF_PARCEL")[1])//Controla a Sequencia das parcelas
Local cTpRev		:= Posicione("CN0",1,xFilial("CN0")+oCN9Master:GetValue("CN9_TIPREV"),"CN0_TIPO")
Local cCronog		:= oCNFDetail:GetValue('CNF_NUMERO')
Local cCond			:= oCN9Master:GetValue('CN9_CONDPG')
Local nQtdParcs := oCN9Master:GetValue('CN9_QTDPAR')
local nDiaPar		:= 30
Local nI    	:= 0
Local nI2    	:= 0
Local lVldVige   	:= GetNewPar("MV_CNFVIGE","N") == "N"
Local lUltimoDia:= oCN9Master:GetValue('CN9_UDMES')
Local lFisico		:= Cn300RetSt("FISICO",0)
Local lAjFim		:= .F.
Local lAjFev	:= .F.
Local lAjFimC	:= .F.
Local lAjFevC	:= .F.
Local lOk			:= .T.
Local aModels	:= {}

If lUltimoDia // Verifica se utiliza ultimo dia do mes
	lAjFim := .T.
	lAjFev := .T.
	lAjFimC:= .T.
	lAjFevC:= .T.
Endif

//Ultima linha não deletada
For nI := oCNFDetail:Length() To 1 Step -1
	oCNFDetail:GoLine(nI)
	If !oCNFDetail:IsDeleted()
		Exit
	EndIf
Next nI

//oCNFDetail:GoLine(oCNFDetail:Length())
dPrevista := oCNFDetail:GetValue('CNF_PRUMED')//Seleciona ultima data
dComp	  := oCNFDetail:GetValue('CNF_COMPET')//Seleciona ultima competencia
dComp	  := CTOD(Str(Day(dPrevista))+"/"+dComp)
cParce   := oCNFDetail:GetValue('CNF_PARCEL')

//oCNFDetail:GoLine(1)
nDiaIni   := Day(oCNFDetail:GetValue('CNF_PRUMED')) //Seleciona o dia da última parcela do cronograma

cParce := Soma1(cParce)
cCompet := strzero(Month(dComp),2)+"/"+str(Year(dComp),4)

aCond := Condicao(0,cCond,,dPrevista)//Calcula data de acordo com a condicao

nDiaPar  := oCNFDetail:GetValue('CNF_DIAPAR')

For nI := 1 To nQtdParcs

	//--Calcula data da proxima parcela                      ³
	nMes := Month(dPrevista)
	nAno := Year(dPrevista)

	If nDiaPar == 30 .OR. nDiaPar == 0
		nAvanco  := CalcAvanco(dPrevista,lAjFim,lAjFev,nDiaIni)
	Else
		nAvanco := nDiaPar
	EndIf

	dPrevista += nAvanco
	If nDiaPar == 30 .OR. nDiaPar == 0
		nAvanco  := CalcAvanco(dComp,lAjFimC,lAjFevC,nDiaIni)
	Else
		nAvanco := nDiaPar
	EndIf
	dComp    += nAvanco

	//-- Verifica data final do cronograma x data final da planilha
	If lVldVige .And. dPrevista > oModel:GetModel("CNADETAIL"):GetValue("CNA_DTFIM")
		Help(" ",1,"CNTA300ULT") //-- A quantidade de parcelas é inválida pois ultrapassou a data final do contrato
		lOk := .F.
		Exit
	Else
		If Cn300RetSt("SERVIÇO")
			CN300ItSrv(2,1)
		EndIf

		oCNFDetail:AddLine()
		oCNFDetail:LoadValue('CNF_TXMOED', 1)
		oCNFDetail:LoadValue('CNF_NUMERO', cCronog)
		oCNFDetail:LoadValue('CNF_PARCEL', cParce)
		oCNFDetail:LoadValue('CNF_COMPET', strzero(Month(dComp),2)+"/"+str(Year(dComp),4))
		oCNFDetail:LoadValue('CNF_PRUMED', dPrevista)
		oCNFDetail:LoadValue('CNF_DIAPAR', nDiaPar)
		oCNFDetail:LoadValue('CNF_DTVENC', If(len(aCond)>0,aCond[1][1],dPrevista))

		dPrevista := oCNFDetail:GetValue('CNF_PRUMED')//Seleciona ultima data
		dComp	  := oCNFDetail:GetValue('CNF_COMPET')//Seleciona ultima competencia
		dComp	  := CTOD(Str(Day(dPrevista))+"/"+dComp)
		cParce := Soma1(cParce)

		If lFisico
			aModels := {'CNSDETAIL'}
			MtBCMod(oModel,aModels,{||.T.})
			For nI2 := 1 To oCNBDetail:Length()
				oCNBDetail:GoLine(nI2)
				nPos := aScan(aSldsFis,{|x| x[1] == oCNBDetail:GetValue("CNB_ITEM")})
				If nPos > 0
					CN300AddFis(oModel,oCNBDetail:GetValue("CNB_ITEM") ,oCNBDetail:GetValue("CNB_PRODUT"), aSldsFis[nPos, 2], ,oCNFDetail:GetLine())
				Else
					CN300AddFis(oModel,oCNBDetail:GetValue("CNB_ITEM"),oCNBDetail:GetValue("CNB_PRODUT"),oCNBDetail:GetValue("CNB_QUANT"), ,oCNFDetail:GetLine())
				EndIf
			Next nI2
		EndIf
	EndIf
Next nI

If lOk
	If nQtdparcs == 0
		For nI := 1 To oCNBDetail:Length()
			oCNBDetail:GoLine(nI)
			nPos := aScan(aSldsFis,{|x| x[1] == oCNBDetail:GetValue("CNB_ITEM")})
			If nPos == 0
				CN300AddFis(oModel,oCNBDetail:GetValue("CNB_ITEM"),oCNBDetail:GetValue("CNB_PRODUT"),oCNBDetail:GetValue("CNB_QUANT"))
			EndIf
		Next nI
	else
		If lFisico
			For nI := 1 To oCNBDetail:Length()
				oCNBDetail:GoLine(nI)
				nPos := aScan(aSldsFis,{|x| x[1] == oCNBDetail:GetValue("CNB_ITEM")})
				If nPos == 0
				CN300AddFis(oModel,oCNBDetail:GetValue("CNB_ITEM"),oCNBDetail:GetValue("CNB_PRODUT"),oCNBDetail:GetValue("CNB_QUANT"))
				EndIf
			Next nI
	    endIf
	EndIf
EndIf

FWRestRows(aSaveLines)
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300AtCrgs()
Função para atualizar os cronogramas.

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300AtCrs(oModel)
Local aSaveLines	:= FWSaveRows()
Local aSldFis	 	:= {}
Local aOldSldFis	:= {}

Local oCN9Master 	:= Nil
Local oCNFDetail 	:= Nil
Local oCNSDetail 	:= Nil
Local oCNADetail 	:= Nil
Local oCNBDetail	:= Nil

Local lCont 	:= .T.
Local lArrasto	:= .F.
Local lIncParcs := .F.
Local lFisico 	:= Cn300RetSt("FISICO")
Local lOk		:= .F.

Local cEspec   	:= Cn300RetSt("REVESPECIE")
Local cTpRev    := Cn300RetSt("TIPREV")

//DEFAULT oModel	:= IIF(nModulo==28,FwModelActive(),oModel)

If nModulo == 28 .Or. nModulo==87
	oModel := FwModelActive()
EndIf

oCN9Master	:= oModel:GetModel('CN9MASTER')
oCNFDetail	:= oModel:GetModel('CNFDETAIL')
oCNSDetail	:= oModel:GetModel('CNSDETAIL')
oCNADetail	:= oModel:GetModel('CNADETAIL')
oCNBDetail	:= oModel:GetModel('CNBDETAIL')

If oModel:IsActive()
	lArrasto	:= oCN9Master:GetValue('CN9_ARRAST') == '1'
	lIncParcs 	:= oCN9Master:GetValue('CN9_TPCRON') == '1'

	If Cn300RetSt("MEDEVE") .Or. Cn300RetSt("RECORRENTE")
		Help('',1,'CN300NOFIN') //-- A planilha não possui cronograma financeiro.
		lCont := .F.
	ElseIf oCNADetail:IsInserted()
		Help('',1,'A300NPLAN') //Função não disponível para novas planilhas
		lCont := .F.
	EndIf

	If lCont
		CNTA300BlMd(oCNFDetail, .F.)
		CNTA300BlMd(oCNSDetail, .F.)
		A300OpenMd({||}, .F.)

		aSldFis := CN300SAdF(oModel)

		If lIncParcs
			lOk := CN300IcPrc(oModel, aSldFis)
		Else
			aOldSldFis := CN300DlPrc(oModel)
		EndIf

		If lOk .Or. Len(aOldSldFis) > 0
			If lFisico .And. !lIncParcs .And. Len(aOldSldFis) > 0
				CN300RecFis(oModel,aOldSldFis)
			EndIf

			If lArrasto
				If lFisico
					If oCNFDetail:Length(.T.) > 1
						CN300ApArF(oModel)
					EndIf
				Else
					CN300ApAr(oModel)
					CNTA300BlMd(oCNFDetail, ,.T.)
				EndIf
			EndIf

			CNTA300BlMd(oCNFDetail, ,.T.)

			oCNFDetail:GoLine(1)
			A300Revisa(oModel, cTpRev)

			oCN9Master:LoadValue('CN9_QTDPAR', 0)
			MsgInfo(STR0005,"CN300ATU")
		EndIf
	EndIf
EndIf

FWRestRows(aSaveLines)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} A300Titulo(oModel)
Função para processar os titulos provisórios

@author aline.sebrian
@since 24/02/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------
Function A300Titulo(cContra,cRev,lMedeve,lRecorre)
Local aArea 	:= GetArea()
Local cRevAnt  	:= CnRevAnt()
Local oModel	:= FwModelActive()
Local oModelCNA	:= oModel:GetModel("CNADETAIL")
Local oModelCNF	:= oModel:GetModel("CNFDETAIL")
Local lTemCrg	:= .F.
Local nX		:= 0

Default lRecorre:= .F.

//Verifica se alguma das planilhas possui cronograma financeiro
For nX := 1 To oModelCNA:Length()
	oModelCNA:GoLine(nX)
	If !Empty(oModelCNF:GetValue("CNF_NUMERO"))
		lTemCrg := .T.
		Exit
	EndIf
Next nX

If (lTemCrg .Or. lRecorre) .And. (GetNewPar( "MV_CNPROVI" ,  "S" ) == "S")
	MsAguarde({||CN100ETit(cContra,cRevAnt)}, STR0026)//"Processando títulos provisórios"
	//-- Nao gera titulos quando a revisao for paralisacao
	If A300GATpRv() != DEF_REV_PARAL
		MsAguarde({||CN100CTit(cContra,cRev)}, STR0026)//"Processando títulos provisórios"
		MsAguarde({||CN100RecTi(cContra,cRev)},STR0026)//"Processando títulos recorrentes"
	EndIf
EndIf

RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} A300NwLine()
Verificação se a linha nos modelos CNA ou CNB são novas

@param cModel - modelo que será validado

@author guilherme.pimentel
@since 25/02/2014
@version 1.1
/*/
//-------------------------------------------------------------------
Function A300NwLine(cModel)
	Local oModel	:= FWModelActive()
	Local oGrid	:= oModel:GetModel(cModel)
	Local lRet		:= oGrid:IsInserted()
	Local cRevAnt	:= '   '
	Local aAreaCNB	:= {}

	/*Para novos itens, caso a linha esteja inserida, retorna .T.
	Caso a linha não seja nova - o que ocorre se não for uma inclusão de item - verifica se existia na versão anterior.*/	
	If ! lRet .And. oModel:GetOperation() == MODEL_OPERATION_UPDATE
		If cModel == 'CNBDETAIL'
			aAreaCNB := CNB->(GetArea())
			cRevAnt	:= CnRevAnt() //Novos itens - liberado
			lExiste := CNB->(dbSeek(xFilial("CNB")+oGrid:GetValue('CNB_CONTRA')+cRevAnt+oGrid:GetValue('CNB_NUMERO')+oGrid:GetValue('CNB_ITEM')))
			lRet	:= !lExiste
			CNB->(RestArea(aAreaCNB))
		EndIf	
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300DtRei(oModel)
Função para validar a data prevista para o reinicio do contrato

@author aline.sebrian
@since 24/02/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------
Function A300DtRei()
Local lRet := .T.
If M->CN9_DTFIMP <= ddatabase
	Help('',1,'CNTA300DTREI')
	lRet := .F.
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300Aprov(oModel,cRev,lMedeve,lRecorre)
Função para atualizar a aprovação do contrato

@author aline.sebrian
@since 21/02/2014
@version 1.0
@return Nil
/*/
//-------------------------------------------------------------------

Function A300Aprov(oModel,cRev,lMedeve,lRecorre)
Local aArea     	:= GetArea()
Local aAreaCND		:= {} 
Local cContra		:= Iif(!Empty(CN9->CN9_NUMERO),CN9->CN9_NUMERO, oModel:GetValue("CN9MASTER","CN9_NUMERO"))
Local lFluig		:= !Empty(AllTrim(GetNewPar("MV_ECMURL",""))) .And. FWWFFluig()
Local lAvlFor		:= (GetNewPar( "MV_CNSITAL", "S" ) == "S") .And. !lFluig

Default lRecorre:= .F.

CnCauAtu(oModel,cRev) //Atualiza caução manual

CnSitAtu(cContra,cRev)//Atualiza situacao da revisao anterior para 10-Revisado

CNContab("69G")	//Lançamento Contábil na Aprovação da Revisao

A300Titulo(cContra,cRev,lMedeve,lRecorre)//Processa titulos provisorios das parcelas

//Caso alguma aplicação tenha trocado o modelo de dados ativo, reativa o modelo em uso.
FwModelActive(oModel)

cn300AprPl(cContra,cRev) //Rotina para tratamentos na gravacao das planilhas na aprovacao

If lAvlFor	 .And. (A300GATpRv() == DEF_REV_PARAL .OR. A300GATpRv() == DEF_REV_REINI) .And. CN9->CN9_ESPCTR <> '2'
	CN220Aval("CNM",,MODEL_OPERATION_UPDATE,,.F.,IF(A300GATpRv()==DEF_REV_PARAL,DEF_SPARA,DEF_SVIGE),,,cContra,cRev)
EndIf

dbSelectArea("CND")
aAreaCND := CND->(GetArea())
CND->(dbSetOrder(1))

//-- Verifica se a medicao ja foi revisada na inclusao da revisao, devido ao legado.
If !dbSeek( xFilial("CND",oModel:GetValue("CN9MASTER","CN9_FILCTR"))+oModel:GetValue("CN9MASTER","CN9_NUMERO")+oModel:GetValue("CN9MASTER","CN9_REVISA"))
	
	//-- Tratamento de revisao de contrato, na inclusão ou exclusao de revisao
	CNA300RvMd(oModel:GetValue("CN9MASTER","CN9_NUMERO"),CnRevAnt(),oModel:GetValue("CN9MASTER","CN9_REVISA"),oModel:GetValue("CN9MASTER","CN9_FILCTR"))
	
	//-- Função para reajustar ou realinhar medição.
	A300AtuMed(oModel)
	
EndIf

//Tratamento no pedido de Compra/Venda
CN300RevPd(oModel)

//Atualiza a data de aniversário dos itens da planilha Incluidos durante a revisao
a300dtAniv()

//Chama a contabilização da aprovação da revisão, por item da planilha
CN100ConIt( "69N" )

//Caso alguma aplicação tenha trocado o modelo de dados ativo, reativa o modelo em uso.
FwModelActive(oModel)

RestArea(aAreaCND)
RestArea(aArea)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300VDCRF()
Valida cronograma físico

@author Antenor Silva
@since 30/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300VdCrf(oModel)
Local oStruCNS 	:= oModel:GetModel('CNSDETAIL'):GetStruct()
Local oStruCNF 	:= oModel:GetModel('CNFDETAIL'):GetStruct()

If Cn300RetSt("FISICO",2)
	oStruCNS:SetProperty('CNS_PRVQTD',MODEL_FIELD_WHEN,{||.T.})
	oStruCNS:SetProperty('CNS_DISTSL',MODEL_FIELD_WHEN,{||.T.})
	oStruCNS:SetProperty('CNS_SLDQTD',MODEL_FIELD_WHEN,{||.T.})
	oStruCNS:SetProperty('CNS_TOTQTD',MODEL_FIELD_WHEN,{||.T.})
	oStruCNS:SetProperty('CNS_TOTQTD',MODEL_FIELD_WHEN,{||.T.})
	CNTA300BlMd(oModel:GetModel('CNFDETAIL'), .T.,.T.)

	oStruCNF:SetProperty('CNF_SALDO',MODEL_FIELD_WHEN,{||.T.})
Else
	oStruCNF:SetProperty('CNF_SALDO',MODEL_FIELD_WHEN,{||.T.})
	oStruCNS:SetProperty('CNS_PRVQTD',MODEL_FIELD_WHEN,{||.F.})
EndIf

oStruCNF:SetProperty('CNF_VLPREV',MODEL_FIELD_WHEN,{||!Cn300RetSt("FISICO")})

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300EspVld()
Bloqueia e desbloqueia campos de acordo com a especie da Revisão de Aditivo

@author Aline Sebrian
@since 29/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function cn300EspVld( oModel, cTpRev )
Local oModCN9	:= oModel:GetModel('CN9MASTER')
Local oModCNB 	:= oModel:GetModel('CNBDETAIL')
Local oModCNA 	:= oModel:GetModel('CNADETAIL')
Local oModCNF 	:= oModel:GetModel('CNFDETAIL')
Local oModCXM 	:= oModel:GetModel('CXMDETAIL')
Local oStruCN9 	:= oModCN9:GetStruct()
Local aCTBEnt	:= CTBEntArr()
Local cTipoCtr  := ""
Local cModo     := Cn300RetSt("MODALIDADE")
Local cEspec    := Cn300RetSt("REVESPECIE")
Local lEventual	:= Cn300RetSt("EVENTUAL")
Local lSemiProd := Cn300RetSt("SEMIPROD")
Local lSemiAgru := Cn300RetSt("SEMIAGRUP")
Local lServico	:= CN300RetSt('SERVIÇO')
Local lNovCrgFin:= Empty(oModel:GetValue('CNFDETAIL','CNF_NUMERO'))
Local aCampos   := {}
Local cAutom	:= oModel:GetValue("CN9MASTER","CN9_AUTO") // -- 0 - Default; 1 - Vindo da Automação (Robô)
Local nX 		:= 0

Default cTpRev  := ""

If !Empty(cEspec)
	If cModo == '2'
		oModCNA:SetNoInsertLine(.T.)
		oModCNB:SetNoInsertLine(.T.)
	EndIf

    If cEspec == '1' //Aditivo de Quantidade

		//Se tipo do contrato for CN1_MEDEVE = "1", CN1_CTRFIX = "2" a revisão de aditivo de quantidade não será permitida (bloqueio planilha, libera apenas cabecalho).
		If lEventual .And. CN0->CN0_ESPEC $ '1|4'
			//Modelos e campos a serem alterados
			aAdd(aCampos,{'CN9MASTER',{'CN9_UNVIGE','CN9_DTFIM', 'CN9_GRPAPR'}})
			If oModCN9:GetValue('CN9_UNVIGE') != '4'
				aAdd(aCampos,{'CN9MASTER',{'CN9_VIGE'}})
			EndIf

			aAdd(aCampos,{'CNWDETAIL',{'CNW_COMPET','CNW_DTPREV','CNW_VLPREV','CNW_HIST','CNW_CC', 'CNW_ITEMCT', 'CNW_CLVL'}})
			MtBCMod(oModel,aCampos,{||FwFldGet("CNW_FLGAPR")<>"1"},'2')
			//Limpeza do array para uso posterior
			aCampos := {}

		Else
			//Modelos e campos a serem alterados a qualquer momento
			oStruCN9:SetProperty('CN9_REDVAL',MODEL_FIELD_WHEN,{|| oModCN9:GetValue("CN9_ARRAST") == '1' })
			aCampos := {}
			aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL','CN9_QTDPAR','CN9_TPCRON','CN9_CSLD', 'CN9_MPLA', 'CN9_CPARCA', 'CN9_CPARCV', 'CN9_TPCROC', 'CN9_QTPARC', 'CN9_UDMES', 'CN9_GRPAPR'}})
			aAdd(aCampos,{'CNFDETAIL',{'CNF_VLPREV','CNF_SALDO'}})
			If lSemiProd .Or. lEventual
				aAdd(aCampos,{'CNADETAIL',{'CNA_VLTOT'}})
			EndIf
			If cAutom == '0'
				aAdd(aCampos,{'CNZDETAIL',{'CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
			Else
				aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
			EndIf

			If lSemiAgru
				aAdd(aCampos,{'CXMDETAIL',{'CXM_VLMAX'}})
			Else
				aAdd(aCampos,{'CNBDETAIL',{'CNB_VLTOT','CNB_QTRDAC','CNB_QTRDRZ','CNB_SLDREC','CNB_SLDMED','CNB_DESC','CNB_VLDESC','CNB_CONTA','CNB_ITEMCT','CNB_CC','CNB_CLVL'}})
				If !lSemiProd .And. !lServico
					aAdd(aCampos,{'CNBDETAIL',{'CNB_QUANT'}})
				EndIf
				If CNB->( ColumnPos( "CNB_ARREND" ) ) > 0
					aAdd( aCampos, { "CNBDETAIL", {"CNB_ARREND"} } )
				EndIf
			EndIf

			For nX := 1 To Len(aCTBEnt)
				aAdd(aCampos,{'CNZDETAIL', {"CNZ_EC" +aCTBEnt[nX] +"CR" }})
				aAdd(aCampos,{'CNZDETAIL', {"CNZ_EC" +aCTBEnt[nX] +"DB" }})
			Next nX
			MtBCMod(oModel,aCampos,{||.T.},'2')

			//Liberação da inclusão de Planilhas
			aCampos := {}
			aAdd(aCampos,{'CNADETAIL',{'CNA_FORNEC','CNA_LJFORN','CNA_CLIENT', 'CNA_LOJACL', 'CNA_TIPPLA','CNA_FLREAJ','CNA_DESCRI','CNA_INDICE','CNA_UNPERI','CNA_PERI','CNA_DTINI','CNA_DTFIM'}})
			MtBCMod(oModel,aCampos,{||A300NwLine('CNADETAIL')},'2')

			If lSemiAgru
				//- Liberação dos Agrupadores
				aCampos := {}
				aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRTIP','CXM_AGRGRP','CXM_AGRCAT','CXM_CC'}})
				MtBCMod(oModel,aCampos,{||A300NwLine('CXMDETAIL')},'2')
			Else
				//Liberação da inclusão de Itens da planilha
				aCampos := {}
				aAdd(aCampos,{'CNBDETAIL',{'CNB_PRODUT','CNB_DESCRI','CNB_UM','CNB_VLUNIT','CNB_TE','CNB_TS','CNB_PEDTIT','CNB_TABPRC','CNB_INDICE','CNB_MODORJ','CNB_FLREAJ','CNB_CONTA','CNB_ITEMCT','CNB_CC','CNB_CLVL'}})
				For nX := 1 To Len(aCTBEnt)
					If CNB->(FieldPos("CNB_EC" +aCTBEnt[nX] +"CR")) > 0
						aAdd(aCampos,{'CNBDETAIL', {"CNB_EC" +aCTBEnt[nX] +"CR" }})
						aAdd(aCampos,{'CNBDETAIL', {"CNB_EC" +aCTBEnt[nX] +"DB" }})
					EndIf
				Next nX
				MtBCMod(oModel,aCampos,{||A300NwLine('CNBDETAIL')},'2')
			EndIf

			//Verificação no cronograma físico
			CN300VdCrf(oModel)
			aCampos := {}
			aAdd(aCampos,{'CNWDETAIL',{'CNW_DTPREV'}})
			MtBCMod(oModel,aCampos,{||.F.},'2')
			
		EndIf

    ElseIf cEspec == '3' //Aditivo de Prazo
		//Modelos e campos a serem alterados a qualquer momento
		aCampos := {}
		aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL','CN9_QTDPAR','CN9_TPCRON','CN9_UDMES','CN9_UNVIGE','CN9_VIGE','CN9_DTFIM','CN9_SALDO','CN9_GRPAPR'/*Remover campos dos parâmetros*/}})
		aAdd(aCampos,{'CNFDETAIL',{'CNF_VLPREV','CNF_SALDO','CNF_COMPET','CNF_DTVENC','CNF_PRUMED','CNF_TXMOED','CNF_CONDPG'}})
		aAdd(aCampos,{'CNADETAIL',{'CNA_DTINI','CNA_DTFIM','CNA_PERIOD','CNA_PERREC','CNA_QTDREC','CNA_DIASEM','CNA_DIAMES','CNA_PROMED'}})
		If !lSemiAgru
			aAdd(aCampos,{'CNBDETAIL',{'CNB_ATIVO','CNB_PARPRO'}})
		EndIf
		MtBCMod(oModel,aCampos,{||.T.},'2')

	ElseIf cEspec =='4' //Aditivo de Quantidade/Prazo
		//Modelos e campos a serem alterados a qualquer momento
		oStruCN9:SetProperty('CN9_REDVAL',MODEL_FIELD_WHEN,{|| oModCN9:GetValue("CN9_ARRAST") == '1' })
		aCampos := {}
		aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL','CN9_QTDPAR','CN9_TPCRON', 'CN9_UDMES','CN9_UNVIGE','CN9_VIGE','CN9_DTFIM','CN9_DTFIM', 'CN9_CSLD', 'CN9_MPLA', 'CN9_CPARCA', 'CN9_CPARCV','CN9_GRPAPR'}})
		aAdd(aCampos,{'CNFDETAIL',{'CNF_VLPREV','CNF_SALDO','CNF_COMPET','CNF_DTVENC','CNF_PRUMED','CNF_TXMOED','CNF_CONDPG'}})
		aAdd(aCampos,{'CNADETAIL',{'CNA_DTINI','CNA_DTFIM','CNA_PERIOD','CNA_PERREC','CNA_QTDREC','CNA_DIASEM','CNA_DIAMES','CNA_PROMED'}})
		If lSemiProd .Or. lEventual
			aAdd(aCampos,{'CNADETAIL',{'CNA_VLTOT'}})
		EndIf

		If cAutom == '0'
			aAdd(aCampos,{'CNZDETAIL',{'CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
		Else
			aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
		EndIf

		If lSemiAgru
			aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRGRP','CXM_AGRCAT','CXM_VLMAX'}})
		Else
			aAdd(aCampos,{'CNBDETAIL',{'CNB_VLTOT','CNB_QTRDAC','CNB_QTRDRZ','CNB_SLDREC','CNB_SLDMED','CNB_DESC','CNB_VLDESC','CNB_ATIVO','CNB_PARPRO','CNB_CONTA','CNB_CC','CNB_ITEMCT','CNB_CLVL'}})
			If !lSemiProd .And. !lServico
				aAdd(aCampos,{'CNBDETAIL',{'CNB_QUANT'}})
			EndIf
			If CNB->( ColumnPos( "CNB_ARREND" ) ) > 0
				aAdd( aCampos, { "CNBDETAIL", {"CNB_ARREND"} } )
			EndIf
		EndIf
		For nX := 1 To Len(aCTBEnt)
			aAdd(aCampos,{'CNZDETAIL', {"CNZ_EC" +aCTBEnt[nX] +"CR" }})
			aAdd(aCampos,{'CNZDETAIL', {"CNZ_EC" +aCTBEnt[nX] +"DB" }})
		Next nX

		MtBCMod(oModel,aCampos,{||.T.},'2')

		//Liberação da inclusão de Planilhas
		aCampos := {}
		aAdd(aCampos,{'CNADETAIL',{'CNA_FORNEC','CNA_LJFORN','CNA_CLIENT', 'CNA_LOJACL','CNA_TIPPLA','CNA_FLREAJ','CNA_DESCRI','CNA_INDICE','CNA_UNPERI','CNA_PERI'}})
		MtBCMod(oModel,aCampos,{||A300NwLine('CNADETAIL')},'2')

		If lSemiAgru
			//- Liberação dos Agrupadores
			aCampos := {}
			aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRTIP','CXM_CC'}})
			MtBCMod(oModel,aCampos,{||A300NwLine('CXMDETAIL')},'2')
		Else
		//Liberação da inclusão de Itens da planilha
		aCampos := {}
		aAdd(aCampos,{'CNBDETAIL',{'CNB_PRODUT','CNB_DESCRI','CNB_UM','CNB_VLUNIT','CNB_TE','CNB_TS','CNB_PEDTIT','CNB_TABPRC','CNB_INDICE','CNB_MODORJ','CNB_FLREAJ','CNB_CONTA','CNB_ITEMCT','CNB_CC','CNB_CLVL'}})
		For nX := 1 To Len(aCTBEnt)
			If CNB->(FieldPos("CNB_EC" +aCTBEnt[nX] +"CR")) > 0
				aAdd(aCampos,{'CNBDETAIL', {"CNB_EC" +aCTBEnt[nX] +"CR" }})
				aAdd(aCampos,{'CNBDETAIL', {"CNB_EC" +aCTBEnt[nX] +"DB" }})
			EndIf
		Next nX

		MtBCMod(oModel,aCampos,{||A300NwLine('CNBDETAIL')},'2')
		EndIf

		//Verificação no cronograma físico
		CN300VdCrf(oModel)

	ElseIf cEspec =='5' // Todos

		//Modelos e campos a serem alterados a qualquer momento
		oStruCN9:SetProperty('CN9_REDVAL',MODEL_FIELD_WHEN,{|| oModCN9:GetValue("CN9_ARRAST") == '1' })
		aCampos := {}
		aAdd(aCampos,{'CN9MASTER',{'CN9_ARRAST','CN9_REDVAL','CN9_QTDPAR','CN9_TPCRON', 'CN9_UDMES','CN9_UNVIGE','CN9_DTFIM','CN9_CSLD', 'CN9_MPLA', 'CN9_CPARCA', 'CN9_CPARCV',  'CN9_TPCROC', 'CN9_QTPARC', 'CN9_CONDPG','CN9_DESCPG','CN9_VLATU'}})
		If oModCN9:GetValue('CN9_UNVIGE') != '4'
			aAdd(aCampos,{'CN9MASTER',{'CN9_VIGE'}})
		EndIf
		aAdd(aCampos,{'CNFDETAIL',{'CNF_VLPREV','CNF_SALDO','CNF_COMPET','CNF_DTVENC','CNF_PRUMED','CNF_TXMOED','CNF_CONDPG'}})
		aAdd(aCampos,{'CNTDETAIL',{'CNT_VLRET' }})
		aAdd(aCampos,{'CNADETAIL',{'CNA_DTINI','CNA_DTFIM','CNA_PERIOD','CNA_PERREC','CNA_QTDREC','CNA_DIASEM','CNA_DIAMES','CNA_PROMED'}})
		If lSemiProd .Or. lEventual
			aAdd(aCampos,{'CNADETAIL',{'CNA_VLTOT'}})
		EndIf
		aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})

		If lSemiAgru
			aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRGRP','CXM_AGRCAT','CXM_VLMAX'}})
		Else
			aAdd(aCampos,{'CNBDETAIL',{'CNB_VLUNIT','CNB_VLTOT','CNB_QTRDAC','CNB_QTRDRZ','CNB_SLDREC','CNB_SLDMED','CNB_DESC','CNB_VLDESC','CNB_REALI','CNB_DTREAL','CNB_VLTOTR','CNB_ATIVO','CNB_PARPRO','CNB_CONTA' ,'CNB_CC','CNB_CLVL','CNB_ITEMCT'}})
			If !lSemiProd .AND. !lServico
				aAdd(aCampos,{'CNBDETAIL',{'CNB_QUANT'}})
			EndIf
			If CNB->( ColumnPos( "CNB_ARREND" ) ) > 0
				aAdd( aCampos, { "CNBDETAIL", {"CNB_ARREND"} } )
			EndIf
		EndIf

		MtBCMod(oModel,aCampos,{||.T.},'2')

		//Liberação da inclusão de Planilhas
		aCampos := {}
		aAdd(aCampos,{'CNADETAIL',{'CNA_FORNEC','CNA_LJFORN','CNA_CLIENT', 'CNA_LOJACL','CNA_TIPPLA','CNA_FLREAJ','CNA_DESCRI','CNA_INDICE','CNA_UNPERI','CNA_PERI','CNA_RPGANT'}})
		MtBCMod(oModel,aCampos,{||A300NwLine('CNADETAIL')},'2')

		//Liberação da inclusão de Itens da planilha
		If lSemiAgru
			aCampos := {}
			aAdd(aCampos,{'CXMDETAIL',{'CXM_AGRTIP','CXM_CC'}})
			MtBCMod(oModel,aCampos,{||A300NwLine('CXMDETAIL')},'2')
		Else
		aCampos := {}
			aAdd(aCampos,{'CNBDETAIL',{'CNB_PRODUT','CNB_DESCRI','CNB_UM','CNB_TE','CNB_TS','CNB_PEDTIT','CNB_TABPRC','CNB_INDICE','CNB_MODORJ','CNB_FLREAJ'}})
			MtBCMod(oModel,aCampos,{||A300NwLine('CNBDETAIL')},'2')
		EndIf

		//Verificação no cronograma físico
		CN300VdCrf(oModel)
	EndIf

	If lEventual
		CNTA300BlMd( oModCNB, .T. )
		CNTA300BlMd( oModel:GetModel("CNZDETAIL"), .T. )
		If cEspec == '3'
			oModCNA:SetNoInsertLine(.T.)
		EndIf

	ElseIf cEspec $ "1|4|5" .And. !lSemiAgru
		CNTA300BlMd( oModCNB, .F. )
		CNTA300BlMd( oModel:GetModel("CNZDETAIL"), .F. )
	EndIf

	If lNovCrgFin
		oModCNF:SetNoUpdateLine(.T.)
	EndIf

	If cModo == '2'
		oModCNA:SetNoInsertLine(.T.)
		oModCNB:SetNoInsertLine(.T.)
		oModCXM:SetNoInsertLine(.T.)
	EndIf
	If lServico
		MtBCMod(oModel,{{'CNBDETAIL',{'CNB_QUANT'}}},{||.F.},'2')
    EndIf
	If !Empty(oModCN9:GetValue("CN9_CODED"))
		CNTA300BlMd(oModCNB,.F.,)
	EndIf
EndIf
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300vlMod()
Valida a quantidade de acordo com a Modalidade da Revisão

@author José Eulálio
@since 29/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function cn300vlMod()
Local aArea	:= GetArea()
Local lRet     := .T.
Local cModo    := Cn300RetSt("MODALIDADE")
Local cEspec   := Cn300RetSt("REVESPECIE")
Local oModel	:= FwModelActive()
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local cTipRev	:= A300GTpRev()

If cTipRev $ DEF_REV_ADITI+'|'+DEF_REV_RENOV+'|'+DEF_REV_ORCGS+'|'+DEF_REV_ABERT
	If cEspec == '3'
		lRet	:= .F.
	Else
		//Quando for apenas acrescimo
		If cModo == "1"
			lRet	:= (oModCNB:GetValue("CNB_QUANT") >= oModCNB:GetValue("CNB_QTDORI"))
		//Quando for apenas decrescimo
		ElseIf cModo == "2"
			lRet	:= (oModCNB:GetValue("CNB_QUANT") <= oModCNB:GetValue("CNB_QTDORI"))
		//Quando for ambos
		ElseIf cModo == "3"
			lRet	:= .T.
		EndIf
	EndIf
EndIf

RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} cn300ParLoad()
Acrescimo e Decrescimo das parcelas durante a revisão do contrato

@author aline.sebrian
@since 27/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function cn300ParLoad()
Local lConfirm 	:= .F.

lConfirm 	:= MsgYesNo(STR0023)	//"Deseja acrescentar parcelas  " # "?")

Return lConfirm

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300REAJU()
Função de cálculo para a revisão de reajuste

@author guilherme.pimentel
@since 23/01/2014
@version 1.1
/*/
//-------------------------------------------------------------------
Function CN300REAJU(oModel, nValorRj)
Local aSaveLines:= FWSaveRows()

Local oModelCN9	:= oModel:GetModel('CN9MASTER')
Local oModelCNA	:= oModel:GetModel('CNADETAIL')
Local oModelCNB	:= oModel:GetModel('CNBDETAIL')
Local oModelCNF := oModel:GetModel('CNFDETAIL')
Local oModelCXM := oModel:GetModel('CXMDETAIL')

Local nVlrInd	 := 0
Local nVlrUn	 := 0
Local nVlrReaj	 := 0
Local nSldReaj	 := 0
Local nVlrNRec	 := 0
Local nVlTotOri	 := 0
Local nLineCNB	 := 0
Local nCN300VRJ	 := 0
Local nX		 := 0
Local nY		 := 0

Local lRevMed 	 := .F.
Local lFisico 	 := .F.
Local lFixo		 := .F.
Local lPrevF	 := .F.
Local lContabil	 := .F.
Local lSemiFixo	 := .F.
Local lSemiAgru	 := .F.
Local lSemiProd	 := .F.
Local lVldReaj 	 := .F.
Local lAgrZer	 := .F.
Local lRet 		 := .T.

Local cTipoCtr 	 := oModelCN9:GetValue("CN9_TPCTO")
Local cIndice	 := oModelCN9:GetValue("CN9_INDICE")
Local cIndCabec	 := ""
Local cTipPla	 := ""
Local cModoReaj	 := ""
Local cMdRjCabec := ""
Local cItemDest	 := ""

Local dDataRef	 := oModelCN9:GetValue("CN9_DREFRJ")
Local dDataApl	 := oModelCN9:GetValue("CN9_DTREAJ")
Local dDtRjAnt   := CtoD("")
Local dDtPrxRj   := CtoD("")
Local cCodTpRev	 := oModel:GetValue('CN9MASTER','CN9_TIPREV')

//Variaveis para calculo de Pro Rata
Local cProRatCN9 := oModelCN9:GetValue("CN9_PRORAT")
Local lProRata 	 := .F.
Local cProRatCNA := ""
Local cUniPeri	 := ""
Local nPeri		 := 0

Default nValorRj := 0

If A300GUsrBt()
	lRet := .F.
	Help('',1,'A300Unic') //Funcao somente pode ser executada 1 vez
ElseIf A300GTpRev() <> DEF_REV_REAJU
	lRet := .F.
	Help('',1,'A300REVREAJ') //Somente revisao de reajuste
ElseIf Empty(dDataRef)
	lRet := .F.
	Help('',1,'A300REF') //Data de referencia nao preenchida
ElseIf Empty(dDataApl)
	lRet := .F.
	Help('',1,'A300REAJ') //Data do reajuste nao preenchida
ElseIf Empty(oModelCN9:GetValue("CN9_TIPREV"))
	lRet := .F.
	Help('',1,'A300TIPREV') // Deve ser informado o tipo de revisão
ElseIf A300ApReRet(cCodTpRev) .And.(A300GTpRev() == DEF_REV_REAJU .Or. A300GTpRev() == DEF_REV_REALI )
	If (!Empty(oModelCN9:GetValue('CN9_DTRRDE')) .And. Empty(oModelCN9:GetValue('CN9_DTRRAT'))) .Or.;
		(Empty(oModelCN9:GetValue('CN9_DTRRDE')) .And. !Empty(oModelCN9:GetValue('CN9_DTRRAT'))) .Or. ;
		oModelCN9:GetValue('CN9_DTRRDE') > oModelCN9:GetValue('CN9_DTRRAT')
		lRet := .F.
		Help(" ",1,"A300EMPTDT",,STR0014,1,1)
	EndIf
EndIf

If lRet
	cUniPeri := oModelCN9:GetValue('CN9_UNPERI')
	nPeri 	 := oModelCN9:GetValue('CN9_PERI')
	
	//Efetua cálculo da data do próximo reajuste
	dDtPrxRj := CN300DtPrxRj(dDataApl, cUniPeri, nPeri)
	If CN9->(Columnpos('CN9_PROXRJ')) > 0
		oModelCN9:GetStruct():SetProperty('CN9_PROXRJ',MODEL_FIELD_WHEN,{||.T.})
		oModelCN9:SetValue('CN9_PROXRJ',dDtPrxRj)
		oModelCN9:GetStruct():SetProperty('CN9_PROXRJ',MODEL_FIELD_WHEN,{||.F.})
	EndIf
	
	// Roda Planilhas e aplica Reajuste
	For nX := 1 to oModelCNA:Length()
		oModelCNA:GoLine(nX)
		A300OpenMd({||},.F.) //-- Abre o Modelo

		//Efetua reajuste apenas para planilhas habilitadas
		If oModelCNA:GetValue('CNA_FLREAJ') <> '2' .And. (Empty(oModelCNA:GetValue('CNA_PROXRJ')) .Or. oModelCNA:GetValue('CNA_PROXRJ') <= dDataApl .Or.  oModelCNA:GetValue('CNA_PRORAT') == '1' )
			cTipPla		:= oModelCNA:GetValue("CNA_TIPPLA")
			lRevMed 	:= A300RevMed(0)

			lFisico		:= CN300PlaSt("FISICO"		,cTipoCtr,cTipPla)
			lFixo		:= CN300PlaSt("FIXO"		,cTipoCtr,cTipPla)
			lPrevF		:= CN300PlaSt("PREVFINANC"	,cTipoCtr,cTipPla)
			lContabil	:= CN300PlaSt("CONTABIL"	,cTipoCtr,cTipPla)
			lSemiFixo	:= Cn300PlaSt("SEMIFIXO"	,cTipoCtr,cTipPla)
			lSemiAgru	:= Cn300PlaSt("SEMIAGRUP"	,cTipoCtr,cTipPla)
			lSemiProd	:= Cn300PlaSt("SEMIPROD"	,cTipoCtr,cTipPla)

			nVlrReaj	:= 0
			nVlTotOri	:= oModelCNA:GetValue("CNA_VLTOT") // Guarda valor inicial da CNA para usar no cronograma
			cProRatCNA	:= oModelCNA:GetValue('CNA_PRORAT')

			// Resgata parâmetros para o reajuste
			cIndCabec	:= If(Empty(oModelCNA:GetValue("CNA_INDICE")), oModelCN9:GetValue("CN9_INDICE"), oModelCNA:GetValue("CNA_INDICE"))
			cMdRjCabec 	:= If(Empty(oModelCNA:GetValue("CNA_MODORJ")), oModelCN9:GetValue("CN9_MODORJ"), oModelCNA:GetValue("CNA_MODORJ"))
			cUniPeri 	:= oModelCNA:GetValue('CNA_UNPERI')
			nPeri 	 	:= oModelCNA:GetValue('CNA_PERI')

			If Empty(cUniPeri)
				cUniPeri := oModelCN9:GetValue('CN9_UNPERI')
			EndIf

			If Empty(nPeri)
				nPeri 	 := oModelCN9:GetValue('CN9_PERI')
			EndIf

			// Se for contrato não FIXO e não SEMIFIXO(PRODUTO) atualizará apenas as  planilhas, pois  esta não possuem itens
			If (!lFixo .And. !lSemiProd)
				If lPrevF //- Se sem previsão financeira, não é necessário reajustar.
					dDtRjAnt := If( Empty(oModelCNA:GetValue("CNA_DTREAJ")) , oModelCNA:GetValue('CNA_DTINI') , oModelCNA:GetValue("CNA_DTREAJ") )
					dDtPrxRj := oModelCNA:GetValue("CNA_PROXRJ")

					// Validar se efetuará o reajuste
					lVldReaj := CN300RjVld(cMdRjCabec, dDataApl, dDtRjAnt, dDtPrxRj)

					//Efetua o reajuste da planilha
					If lVldReaj
						If lRevMed
							nVlrNRec := A300SldRec('n2','')
						EndIf

						If lSemiAgru
							oModelCXM:SetNoUpdateLine(.F.)
							lAgrZer := .F.
							For nY := 1 to oModelCXM:Length()
								oModelCXM:GoLine(nY)
								nVlrInd	:= A300VlrInd(cIndCabec,dDataRef)
								nVlrUn 	:= Round( oModelCXM:GetValue('CXM_VLMAX') * nVlrInd, TamSx3("CXM_VLMAX")[2] )
								If NVlrUn != 0
									oModelCXM:SetValue('CXM_VLMAX',nVlrUn)
								Else
									lAgrZer := .T.
								EndIf
							Next nY
							oModelCXM:SetNoUpdateLine(.T.)
						EndIf

						If !lSemiAgru .Or. lAgrZer
							nSldReaj := (oModelCNA:GetValue("CNA_SALDO")+nVlrNRec)
							nVlrReaj := Round(nSldReaj*A300VlrInd(cIndCabec,dDataRef),TamSx3("CNA_VLTOT")[2]) - nSldReaj

							oModelCNA:SetValue("CNA_VLTOT",oModelCNA:GetValue("CNA_VLTOT")+nVlrReaj)

							//Efetua cálculo da data do próximo reajuste
							dDtPrxRj := CN300DtPrxRj(dDataApl, cUniPeri, nPeri)
							oModelCNA:SetValue('CNA_DTREAJ',dDataApl)
							oModelCNA:SetValue('CNA_PROXRJ',dDtPrxRj)
						EndIf
					EndIf
				EndIf
			Else //Do Contrário, atualizará os itens da planilha
				// Verifica se reajuste utilizará Pro Rata
				If cProRatCN9 == "1" //Contrato aceita Pro Rata
					lProRata := .T.
				EndIf

				If cProRatCNA == "2" //Planilha NÃO aceita Pro Rata
					lProRata := .F.
				EndIf

				//Reajusta Itens habilitados
				For nY := 1 to oModelCNB:Length()
					oModelCNB:GoLine(nY)
					If Empty(oModelCNB:GetValue('CNB_ITMDST'))
						If oModelCNB:GetValue('CNB_FLREAJ') <> "2" //Verifica se item da planilha aceita reajuste
							oModelCNB:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})

							dDtRjAnt := If( Empty(oModelCNB:GetValue("CNB_DTREAJ")) , oModelCNA:GetValue('CNA_DTINI') , oModelCNB:GetValue("CNB_DTREAJ") )
							dDtPrxRj := oModelCNB:GetValue("CNB_PROXRJ")
							cModoReaj := If(Empty(oModelCNB:GetValue("CNB_MODORJ")), cMdRjCabec, oModelCNB:GetValue("CNB_MODORJ"))

							// Validar se efetuará o reajuste
							lVldReaj := CN300RjVld(cModoReaj, dDataApl, dDtRjAnt, dDtPrxRj)

							// Se item não se enquadra no reajuste, verifica se ele não utilizará Reajuste Pro Rata
							If !lVldReaj
								If lProRata
									If dDataApl > dDtRjAnt .And. dDataApl < dDtPrxRj //Data de próximo reajuste maior que a data de aplicação
										lVldReaj := .T.
									EndIf
								EndIf
							EndIf

							//Efetua o reajuste do valor unitário
							If lVldReaj
								cIndice:= If(Empty(oModelCNB:GetValue('CNB_INDICE')), cIndCabec, oModelCNB:GetValue('CNB_INDICE'))
								nVlrInd	:= A300VlrInd(cIndice, dDataRef, lProRata, dDataApl, dDtRjAnt, dDtPrxRj)
								nVlrUn := Round( oModelCNB:GetValue('CNB_VLUNIT') * nVlrInd, TamSx3("CNB_VLUNIT")[2] )

								//-- Ponto de entrada para customização do cálculo do índice
								If ExistBlock("CN300VRJ")
									nCN300VRJ := Execblock("CN300VRJ",.F.,.F.,{oModelCNA,oModelCNB,nVlrInd,dDataRef, lProRata, dDataApl, dDtRjAnt, dDtPrxRj, cIndice})
									If ValType(nCN300VRJ) == "N"
										nVlrUn := nCN300VRJ
									EndIf
								EndIf

								oModelCNB:SetValue('CNB_VLUNIT',nVlrUn)

								// Verifica se nao existe item destino de reajuste criado a partir do saldo para medição
								cItemDest	:= oModelCNB:GetValue('CNB_ITMDST')
								If !Empty(cItemDest) .And. (nLineCNB := MTFindMVC(oModelCNB,{{'CNB_ITEM',cItemDest}}) ) > 0
									oModelCNB:GoLine(nLineCNB)
								EndIf

								//Efetua cálculo da data do próximo reajuste
								dDtPrxRj := CN300DtPrxRj(dDataApl, cUniPeri, nPeri)
								oModelCNB:SetValue('CNB_DTREAJ',dDataApl)
								oModelCNB:SetValue('CNB_PROXRJ',dDtPrxRj)

								oModelCNA:SetValue('CNA_DTREAJ',dDataApl)
								oModelCNA:SetValue('CNA_PROXRJ',dDtPrxRj)

							EndIf
						EndIf
					EndIf
				Next nY

				If lSemiProd
					dDtRjAnt := If( Empty(oModelCNB:GetValue("CNB_DTREAJ")) , oModelCNA:GetValue('CNA_DTINI') , oModelCNB:GetValue("CNB_DTREAJ") )
					dDtPrxRj := oModelCNA:GetValue("CNA_PROXRJ")

					// Validar se efetuará o reajuste
					lVldReaj := CN300RjVld(cMdRjCabec, dDataApl, dDtRjAnt, dDtPrxRj)

					//Efetua o reajuste da planilha
					If lVldReaj
						If lRevMed
							nVlrNRec := A300SldRec('n2','')
						EndIf
						nSldReaj := (oModelCNA:GetValue("CNA_SALDO")+nVlrNRec)
						nVlrReaj := Round(nSldReaj*A300VlrInd(cIndCabec,dDataRef),TamSx3("CNA_VLTOT")[2]) - nSldReaj

						oModelCNA:SetValue("CNA_VLTOT",oModelCNA:GetValue("CNA_VLTOT")+nVlrReaj)

						//Efetua cálculo da data do próximo reajuste
						dDtPrxRj := CN300DtPrxRj(dDataApl, cUniPeri, nPeri)
						oModelCNA:SetValue('CNA_DTREAJ',dDataApl)
						oModelCNA:SetValue('CNA_PROXRJ',dDtPrxRj)
					EndIf
				EndIf
			EndIf

			// Reajusta Cronogramas
			nVlrReaj := oModelCNA:GetValue("CNA_VLTOT") - nVlTotOri
			nValorRj := nVlrReaj
			If nVlrReaj != 0
				If lFisico
					A300FscTFn(oModel) // Atualiza Cronograma Finaceiro pelo cronograma fisico
				Else
					A300ReajCr(oModel,nVlrReaj,lFisico)
				EndIf
				//-- Atualiza Cronograma contabil
				If lContabil
					A300ReajCt(oModel,nVlrReaj)
				EndIf
			EndIf
			oModelCNB:GoLine(1)
		EndIf
	Next nX

	oModelCNA:GoLine(1)
	A300SUsrBt(.T.)
	//-- Fecha o Modelo
	A300Revisa(oModel,A300GTpRev())
	CNAddItRt()
	If !IsBlind() .And. !IsInCallStack("CNTA310")
		MsgInfo(STR0006,"CN300REAJ") //Reajuste realizado com sucesso!
	EndIf
EndIf

oModelCNA:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.F.})
oModelCNB:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.F.})
oModelCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.F.})
FWRestRows(aSaveLines)

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} CN300RjVld()
Efetua a validação se item será reajustado

@author Marcelo Ferreira
@since  01/09/2015
@version 1.0
@return lRet
/*/
//--------------------------------------------------------------------
Function CN300RjVld(cModoReaj, dDataApl, dDtRjAnt, dDtPrxRj)
Local lRet := .F.

	//Validação se item está  dentro da data ou da competência de reajuste
	Do Case
		Case cModoReaj == "1" // Modo de Reajuste "Por Competência"
			If Left(DtoS(dDataApl), 6) >= Left(DtoS(dDtPrxRj), 6) //Data de próximo reajuste dentro ou maior que o "AnoMes" da data de aplicação
				lRet := .T.
			EndIf

		Case cModoReaj == "2" // Modo de Reajuste "Por Data"
			If dDataApl >= dDtPrxRj //Data de próximo reajuste maior ou igual a data de aplicação
				lRet := .T.
			EndIf

		Case Alltrim(cModoReaj) == "" // Modo de Reajuste "Em Branco"
			lRet := .T.
	End Case

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} CN300DtPrxRj()
Define data de próximo reajuste

@author Marcelo Ferreira
@since  01/09/2015
@version 1.0
@return dDtPrxRj
/*/
//--------------------------------------------------------------------
Function CN300DtPrxRj(dDataApl, cUniPeri, nPeri)
Local dDtPrxRj := CtoD("")

If cUniPeri == '1' //Dias
	dDtPrxRj := DaySum( dDataApl, nPeri )
ElseIf cUniPeri == '2' //Meses
	dDtPrxRj := MonthSum( dDataApl, nPeri )
ElseIf cUniPeri == '3' //Anos
	dDtPrxRj := YearSum( dDataApl, nPeri )
EndIf

Return dDtPrxRj

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300VldRV()
Validações das revisões

@param oModel - Modelo ativo

@author guilherme.pimentel
@since 21/01/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300VldRV(oModel)
Local lRet 		:= .T.
Local oModelCN9	:= oModel:GetModel('CN9MASTER')
Local cEdital 	:= oModelCN9:GetValue('CN9_CODED') //Codigo do edital
Local cProcesso	:= oModelCN9:GetValue('CN9_NUMPR') //Numero do Processo

//Verificação padrão para todas as revisões
lRet :=  !(Empty(oModelCN9:GetValue('CN9_JUSTIF')) .Or. Empty(oModelCN9:GetValue('CN9_TIPREV')))

If lRet
	If A300GTpRev() == DEF_REV_ADITI
		lRet := CN300VdCrg(oModel)
		If lRet .And. !Empty(cEdital) .And. !Empty(cProcesso) .And. A300RvPrz(oModel)
			lRet := A300RvCnEd(oModel,cEdital,cProcesso)
		EndIf
	ElseIf A300GTpRev() == DEF_REV_REAJU
		If !A300GUsrBt()
			lRet := .F.
			Help("",1,"CN300NOREAJU") // É necessario executar o reajuste para concluir a revisão. Verifique "Ações relacionadas
		Else
			oModel:GetModel("CN9MASTER"):LoadValue("CN9_VLREAJ",oModel:GetModel("CN9MASTER"):GetValue("CN9_VLATU") - CN9->CN9_VLATU )
		EndIf

		If lRet .And. !Empty(cEdital) .And. !Empty(cProcesso)
			lRet := A300RvCnEd(oModel,cEdital,cProcesso)
		EndIf

	ElseIf A300GTpRev() == DEF_REV_REALI //Realinhamento
		lRet := CN300VdCrg(oModel)
		If lRet .And. !Empty(cEdital) .And. !Empty(cProcesso)
			lRet := A300RvCnEd(oModel,cEdital,cProcesso)
		EndIf
	ElseIf A300GTpRev() == DEF_REV_READE //Readequação
		lRet := CN300VdCrg(oModel)
		If lRet
			If (oModelCN9:GetValue('CN9_VLATU') <> CN9->CN9_VLATU)
				lRet := .F.
				Help("",1,"CN300VldRV") //O valor atual é diferente do anterior. Favor verificar.
			EndIf
		EndIf

		If lRet .And. !Empty(cEdital) .And. !Empty(cProcesso)
			lRet := A300RvCnEd(oModel,cEdital,cProcesso)
		EndIf
	ElseIf A300GTpRev() == DEF_REV_PARAL
		If (oModelCN9:GetValue('CN9_DTFIMP'))<= dDatabase
			lRet := .F.
			Help("",1,"CN300VldPAR") // Data Termino Paralisação deve ser maior que a data atual do sistema.
		EndIf

		If lRet .And. Empty(oModelCN9:GetValue('CN9_MOTPAR'))
			lRet := .F.
			Help("",1,"CN300VldRVMPAR") // Favor preencher o campo Motivo da Paralisação.
		EndIf

	ElseIf A300GTpRev() == DEF_REV_REINI

	ElseIf A300GTpRev() == DEF_REV_CLAUS

		If Empty(oModelCN9:GetValue('CN9_ALTCLA'))
			lRet := .F.
			Help("",1,"CN300VldRVCL") // Favor preencher o campo Cláusula.
		EndIf

	ElseIf A300GTpRev() == DEF_REV_CONTA
		lRet := CN300VdCrg(oModel)
	ElseIf A300GTpRev() == DEF_REV_INDIC

		If Empty(oModelCN9:GetValue('CN9_INDICE'))
			lRet := .F.
			Help("",1,"CN300VldRVIND") // Favor preencher o campo Índice do cabeçalho do contrato.
		EndIf

	//ElseIf A300GTpRev() == DEF_REV_FORCL

	ElseIf A300GTpRev() == DEF_REV_RENOV .Or. A300GTpRev() == DEF_REV_ORCGS // Renovação / Orç. Serviço
		lRet := CN300VdCrg(oModel)
		If lRet .And. !Empty(cEdital) .And. !Empty(cProcesso)
			lRet := A300RvCnEd(oModel,cEdital,cProcesso)
		EndIf
		
		//-- A Validação deve ser feita tbm para revisões do tipo DEF_REV_ORCGS (Gestão de serviços)
		If lRet .And. oModelCN9:GetValue("CN9_FLGCAU") == "1" .And. A300GTpRev() == DEF_REV_ORCGS
			If 	Empty(oModelCN9:GetValue("CN9_MINCAU"))
				Help(" ",1,"CNTA300PER")	//-- Preencha o percentual minimo de caucao
				lRet := .F.
			ElseIf oModelCN9:GetValue("CN9_MINCAU") < CN9->CN9_MINCAU
				Help(" ",1,"CN300PERMN")	//-- Percentual da caução deve ser maior que o original
				lRet := .F.
			EndIf
		EndIf

	ElseIf A300GTpRev() == DEF_REV_CAUCA 
		If lRet .And. oModelCN9:GetValue("CN9_FLGCAU") == "1"
			If 	Empty(oModelCN9:GetValue("CN9_MINCAU"))
				Help(" ",1,"CNTA300PER")	//-- Preencha o percentual minimo de caucao
				lRet := .F.
			ElseIf oModelCN9:GetValue("CN9_MINCAU") <= CN9->CN9_MINCAU
				Help(" ",1,"CN300PERMN")	//-- Percentual da caução deve ser maior que o original
				lRet := .F.
			EndIf
		EndIf
	EndIf

Else
	Help("",1,"CN300VldRVJUS") // Favor preencher o campo Justificativa e/ou Tipo da Revisão.
EndIf

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN300RecFis()
Função que recupera o saldo cronog fisico depois de deletar as
linhas

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300RecFis(oModel, aOldSlds)
Local nI 		 := 0
Local nI2 		 := 0
Local aNewSlds := {}
Local oCNFDetail 	:= oModel:GetModel('CNFDETAIL')
Local oCNSDetail 	:= oModel:GetModel('CNSDETAIL')
Local aSavelines	:= FWSaveRows()


For nI := 1 To oCNFDetail:Length()
	oCNFDetail:Goline(nI)
	If !oCNFDetail:IsDeleted()
		For nI2 := 1 To oCNSDetail:Length()
			oCNSDetail:GoLine(nI2)
			nPos := aScan(aOldSlds,{|x| x[1] == oCNSDetail:GetValue('CNS_PRODUT')})
			oCNSDetail:LoadValue('CNS_DISTSL', (oCNSDetail:GetValue('CNS_DISTSL')) +  aOldSlds[nPos, 2])
		Next nI2
	EndIf
Next nI
FwRestRows(aSaveLines)
Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300SAdF()
Função que recupera o saldo a distribuir dos itens do cronog Fisico

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300SAdF(oModel)
Local aSldFis 		:= {}
Local oCNFDetail 	:= oModel:GetModel('CNFDETAIL')
Local oCNSDetail 	:= oModel:GetModel('CNSDETAIL')
Local nI 		 	:= 0
Local nI2 		 	:= 0
Local lExit  	 	:= .F.
Local aSavelines	:= FWSaveRows()

//-- Como o campo de saldo a distribuir tem o valor identico para todos os itens do Fisico, pego o da primeira linha
For nI := 1 To oCNFDetail:Length()
	If lExit
		Exit
	EndIf
	oCNFDetail:Goline(nI)

	If !oCNFDetail:IsDeleted() .And. (Empty(oCNFDetail:Getvalue("CNF_DTREAL")) .Or. nI == oCNFDetail:Length())
		For nI2 := 1 To oCNSDetail:Length()
			oCNSDetail:GoLine(nI2)
			Aadd(aSldFis, {oCNSDetail:GetValue('CNS_ITEM'), oCNSDetail:GetValue('CNS_DISTSL')})
		Next nI2
		lExit := .T.
	EndIf
Next nI
FwRestRows(aSaveLines)

Return aSldFis

//------------------------------------------------------------------
/*/{Protheus.doc} CN300AtCrC()
Função que atualiza Cronog. Contábil

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300AtCrC()
Local oModel 		:= FwModelActive()
Local oCN9Master 	:= oModel:GetModel('CN9MASTER')
Local oCNWDetail 	:= oModel:GetModel('CNWDETAIL')
Local cModo		:= 	oCN9Master:GetValue('CN9_TPCROC')
Local lCont		:= .T.
Local lArrasto	:= If(oCN9Master:HasField("CN9_ARRASC"),oCN9Master:GetValue('CN9_ARRASC') == '1',.F.)

If lCont
	CNTA300BlMd(oCNWDetail,.F.)

	If cModo == "1"
		lCont := CN300IncCb(oModel)
	ElseIf cModo == "2"
		CN300DelCb(oModel)
	EndIf

	If lCont
		If lArrasto
			CN300ArrCb(oModel)
		EndIf

		oCN9Master:LoadValue('CN9_QTPARC', 0)

		MsgInfo(STR0005,"CN300ATU")

		CNTA300BlMd(oCNWDetail, ,.T.)
		oCNWDetail:GoLine(1)
	EndIf
EndIf

Return lCont


//------------------------------------------------------------------
/*/{Protheus.doc} CN300AtCont()
Função que atualiza Cronog. Contábil

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300AtCont()

If Cn300RetSt("CONTABIL")
	A300OpenMd({||CN300AtCrC()}, .T.)
Else
	Help(" ",1,"CN300NOCON")
EndIf

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300ArrCb()
Função responsável pelo arrasto e redistribuição de saldo do
cronograma contábil.

@author jose.delmondes
@since 15/02/2016
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300ArrCb(oModel)
Local oCN9Master	:= oModel:GetModel('CN9MASTER')
Local oCNADetail	:= oModel:GetModel('CNADETAIL')
Local oCNWDetail	:= oModel:GetModel('CNWDETAIL')
Local oCNVDetail	:= oModel:Getmodel('CNVDETAIL')
Local lRedVlr   	:= oCN9Master:GetValue('CN9_REDVAC') == '1'
Local nTotPlan		:= oCNADetail:GetValue('CNA_VLTOT')
Local nTotCron		:= oCNVDetail:GetValue('CNV_TOTCRG')
Local nVlrArr		:= nTotPlan - nTotCron
Local nUltParc		:= oCNWDetail:Length()
Local nVlrParc		:= 0
Local nQtdParc		:= 0
Local nResto		:= 0
Local nI			:= 0

If !lRedVlr
	//Se não utilizar a redistribuição de valores, a diferença entre o total da planilha e o
	//total do cronograma será somada a primeira parcela não apropriada do cronograma contábil.
	For nI := 1 To nUltParc
		oCNWDetail:GoLine(nI)

		//Se a linha estiver deletada pula para a próxima
		If oCNWDetail:IsDeleted()
			Loop
		EndIf

		//Atualiza primeira parcela não apropriada com o valor de arrasto
		If oCNWDetail:GetValue('CNW_FLGAPR') == '2'
			oCNWDetail:SetValue('CNW_VLPREV', oCNWDetail:GetValue('CNW_VLPREV')+nVlrArr)
			Exit
		EndIf
	Next nI
Else

	//Soma valores das parcelas não apropriadas ao valor de arrasto
	For nI := 1 To nUltParc
		oCNWDetail:GoLine(nI)

		//Se a linha estiver deletada pula para a próxima
		If oCNWDetail:IsDeleted()
			Loop
		EndIf

		//Soma valor da parcela
		If oCNWDetail:GetValue('CNW_FLGAPR') == '2'
			nVlrArr += oCNWDetail:GetValue('CNW_VLPREV')
			nQtdParc ++
		EndIf
	 Next nI

	 //Obtem valor das parcelas e a sobra
	 nVlrParc	:= NoRound(nVlrArr/nQtdParc,TamSX3('CNW_VLPREV')[2])
	 nResto	:= nVlrArr - (nQtdparc * nVlrParc)

	 //Atualiza valores das parcelas
	 For nI := 1 To nUltParc
		oCNWDetail:GoLine(nI)

		//Se a linha estiver deletada pula para a próxima
		If oCNWDetail:IsDeleted()
			Loop
		EndIf

		//Atualiza parcelas, a sobra será somada a última parcela.
		If oCNWDetail:GetValue('CNW_FLGAPR') == '2' .And. nI <> nUltParc
			oCNWDetail:SetValue('CNW_VLPREV', nVlrParc)
		ElseIf oCNWDetail:GetValue('CNW_FLGAPR') == '2' .And. nI == nUltParc
			oCNWDetail:SetValue('CNW_VLPREV', nVlrParc + nResto )
		EndIf
	 Next nI
EndIf

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300DelCb()
Função que deleta as linhas do cronog. Contábil

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300DelCb(oModel)
Local oCN9Master 	:= oModel:GetModel('CN9MASTER')
Local oCNWDetail 	:= oModel:GetModel('CNWDETAIL')
Local nQtdParcs  	:= oCN9Master:GetValue('CN9_QTPARC')
Local nI    	    := 0
Local aSaveLines	:= FWSaveRows()
Local lRet 		:= .T.

If (nQtdParcs >= oCNWDetail:Length(.T.))
	Help('',1,'CNT300DCPC')// O número de redução de parcelas não pode ser maior ou igual ao o número de parcelas.
	lRet := .F.
EndIf

If lRet
	oCNWDetail:SetNoDeleteLine(.F.)
	For nI := oCNWDetail:Length() To 1 Step -1
		oCNWDetail:GoLine(nI)
		If !oCNWDetail:IsDeleted() .And. oCNWDetail:GetValue("CNW_FLGAPR") <> "1"
			If nQtdParcs == 0
				Exit
			EndIf

			oCNWDetail:DeleteLine()
			nQtdParcs := nQtdParcs - 1
		EndIf
	Next nI
	oCNWDetail:SetNoDeleteLine(.T.)
EndIf

FWRestRows(aSaveLines)

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300IncCb()
Função que inclui as linhas no cronog. Contábil

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300IncCb(oModel)
Local oCN9Master 	:= oModel:GetModel('CN9MASTER')
Local oCNWDetail 	:= oModel:GetModel('CNWDETAIL')
Local oCNVDetail 	:= oModel:GetModel('CNVDETAIL')
Local nX		   	:= 0
Local nDiaPar   	:= 30
Local nAvanco	 	:= 0
Local cNrParcela 	:= 0
Local nParcelas 	:= oCN9Master:GetValue('CN9_QTPARC')
Local dUltData   	:= CtoD("")
Local aSaveLines	:= FWSaveRows()
Local lRet			:= .T.

//Ultima linha não deletada
For nX := oCNWDetail:Length() To 1 Step -1
	oCNWDetail:GoLine(nX)
	If !oCNWDetail:IsDeleted()
		Exit
	EndIf
Next nI


dUltData   := oCNWDetail:GetValue("CNW_DTPREV")
cNrParcela := oCNWDetail:GetValue("CNW_PARCEL")
nDiaPar := oCNVDetail:GetValue('CNV_DIAPAR')

For nX :=1 to nParcelas
	cNrParcela := Soma1(cNrParcela)

	If nDiaPar == 30
		nAvanco  := Day(LastDay(dUltData))
	Else
		nAvanco := nDiaPar
	EndIf

	dUltData := dUltData + nAvanco
	cCompete := Strzero(Month(dUltData),2)+"/"+str(Year(dUltData),4)

	If dUltData > oModel:GetModel("CNADETAIL"):GetValue("CNA_DTFIM")
		Help(" ",1,"CNTA300ULT") //-- A quantidade de parcelas é inválida pois ultrapassou a data final do contrato
		lRet := .F.
	Else
		oCNWDetail:AddLine()
		oCNWDetail:LoadValue("CNW_PARCEL",cNrParcela)
		oCNWDetail:SetValue("CNW_COMPET",cCompete)//StrZero(Month(dUltData),2)+"/"+Str(Year(dUltData),4))

		oCNWDetail:SetValue("CNW_DTPREV",dUltData)
		oCNWDetail:SetValue("CNW_VLPREV",0)
		dPrevista 	:= oCNWDetail:GetValue('CNW_DTPREV')//Seleciona ultima data
		dUltData	:= oCNWDetail:GetValue('CNW_COMPET')//Seleciona ultima competencia
		dUltData	:= CTOD(Str(Day(dPrevista))+"/"+dUltData)
	EndIf
Next nX

FWRestRows(aSaveLines)
Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} CN300VlPrz()
Retirada do Valid do campo CN9_VIGE e CN9_UNVIGE e
colocada no tudoOk do CNTA300

@author matheus.raimundo
@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300VlPrz()
Local lRet 	:= .T.
Local dData 	:= CtoD("")
Local oModel	:= FwModelActive()
Local oModelCN9	:= oModel:GetModel("CN9MASTER")
Local lEdital	:= !Empty(oModelCN9:GetValue('CN9_CODED'))
Local cTipRev	:= A300GTpRev()
Local nMeses	:= 0
Local dDatai	:=  oModelCN9:GetValue('CN9_DTINIC')

dData := CN300DtFim(oModelCN9:GetValue('CN9_UNVIGE'),dDatai,oModelCN9:GetValue('CN9_VIGE'))


dData := CN300DtFim(oModelCN9:GetValue('CN9_UNVIGE'),oModelCN9:GetValue('CN9_DTINIC'),oModelCN9:GetValue('CN9_VIGE'))

If !Empty(cTipRev) .And. !Empty(oModelCN9:GetValue('CN9_DTINIC'))
	If cTipRev == DEF_REV_ADITI .And. Cn300RetSt("REVESPECIE") $ '3|4'  .Or.;
	 ((cTipRev == DEF_REV_RENOV .Or. cTipRev == DEF_REV_ORCGS .Or. cTipRev == DEF_REV_ABERT) .And. Cn300RetSt("REVESPECIE") $ '5')

		If Cn300RetSt("MODALIDADE") == '1'
			If oModelCN9:GetValue("CN9_DTFIM") > dData
				Help('',1,'CNTA300IDTI') // A data final deve ser maior do que a data final da última revisão, revisão de Acresicmo.
				lRet := .F.
			EndIf
		ElseIf Cn300RetSt("MODALIDADE") == '2'
			If oModelCN9:GetValue("CN9_DTFIM") < dData
				Help('',1,'CNTA300IDTF') // A data final deve ser menor do que a data final da última revisão, revisão de Decrescimo.
				lRet := .F.
			EndIf
		EndIf
		If lRet .And. lEdital .And. ( (dData - CN9->CN9_DTINIC) > 1826 .Or. oModelCN9:GetValue("CN9_UNVIGE") == "4" ) //Bloquear aditivos que excedem 60/72 meses.
			nMeses := ATFMESES(dDatai,dData,2)
			If (nMeses > 72 .Or. oModelCN9:GetValue("CN9_UNVIGE") == "4")
				Help('',1,'CN300EXC72') // Não é possivel aditivo de prazo maior que 72 meses, em contratos vinculados ao edital.
				lRet := .F.
			ElseIf !CN300ExcArt(oModel,"PRAZO")
				Help('',1,'CNTA300EXC') // Não é possivel aditivo de prazo maior que 60 meses, em contratos vinculados ao edital.
				lRet := .F.
			EndIf
		EndIf
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300DtFim()
Retorna a data conforme unidade de vigencia e quantidade.

@author matheus.raimundo
@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300DtFim(cTipV,dDtIni,nVig)
Local nX			:= 0
Local nDiaIni		:= 1

If (!Empty(nVig) .Or. cTipV == "4") .And. !Empty(dDtIni)
	Do Case
		Case cTipV == "1"  //Dia
			dDtIni += nVig
		Case cTipV == "2"  //Mes
			nDiaIni := Day(dDtIni) //Dia do início do contrato.
			For nX := 1 to nVig
				dDtIni += CalcAvanco(dDtIni,.F.,.F.,nDiaIni)
			Next
		Case cTipV == "3"  //Ano
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Valida ano bissexto                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Day(dDtIni) == 29 .And. Month(dDtIni) == 2 .And. ((Year(dDtIni)+nVig) % 4 != 0)
				dDtIni := cTod("28/02/"+str(Year(dDtIni)+nVig))
			Else
				dDtIni := cTod(str(Day(dDtIni))+"/"+str(Month(dDtIni))+"/"+str(Year(dDtIni)+nVig))
			EndIf
		Case cTipV == "4"  //Indeterminada
			dDtIni := CTOD("31/12/49")//Retorna data limite do sistema
	EndCase
EndIf

Return dDtIni

//-------------------------------------------------------------------
/*/{Protheus.doc} A300RevCtb()
Função para liberar cronograma contabil

@author alexandre.gimenez
@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300RevCtb( oModel )
Local oModCN9   := oModel:GetModel('CN9MASTER')
Local oModCNV   := oModel:GetModel('CNVDETAIL')
Local oModCNW   := oModel:GetModel('CNWDETAIL')
Local oStruCN9 	:= oModCN9:GetStruct()
Local oStruCNV	:= oModCNV:GetStruct()
Local aCampos 	:= {}
Local cEspec    := Cn300RetSt("REVESPECIE")

oStruCNV:SetProperty("CNV_NUMERO",MODEL_FIELD_OBRIGAT,.F.)

If Cn300RetSt( "CONTABIL", 2 )

	aAdd(aCampos,{'CNVDETAIL',{'CNV_CONTA','CNV_TXMOED'}})

	If oStruCN9:HasField("CN9_REDVAC") .And. oStruCN9:HasField("CN9_ARRASC")
		aAdd(aCampos,{'CN9MASTER',{'CN9_ARRASC','CN9_TPCROC','CN9_QTPARC'}})
		oStruCN9:SetProperty('CN9_REDVAC',MODEL_FIELD_WHEN,{|| oModCN9:GetValue("CN9_ARRASC") == '1' })
	Else
		aAdd(aCampos,{'CN9MASTER',{'CN9_TPCROC','CN9_QTPARC'}})
	EndIf

	MtBCMod(oModel,aCampos,{||.T.},'2')

	aCampos := {}

	If A300GTpRev() == DEF_REV_ADITI .And. cEspec == '1' //Aditivo de Quantidade
		aAdd(aCampos,{'CNWDETAIL',{'CNW_VLPREV','CNW_HIST','CNW_CC','CNW_ITEMCT', 'CNW_CLVL'}})
	Else
		aAdd(aCampos,{'CNWDETAIL',{'CNW_VLPREV','CNW_DTPREV','CNW_HIST','CNW_CC','CNW_ITEMCT', 'CNW_CLVL'}})
	EndIf

	MtBCMod(oModel,aCampos,{||FwFldGet("CNW_FLGAPR")<>"1"},'2')

	oModCNV:SetNoUpdateLine(!CN300RetSt('CONTABIL'))
	oModCNW:SetNoUpdateLine(!CN300RetSt('CONTABIL'))

EndIf

Return
//-------------------------------------------------------------------
/*/{Protheus.doc} A300IsRFor()
Função para verificar se esta sendo executada a revisao de fornecedor

@author Alexandre.gimenez
@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300IsRFor()
Return (A300GTpRev() == DEF_REV_FORCL .Or. A300GTpRev() == DEF_REV_ABERT)

//-------------------------------------------------------------------
/*/{Protheus.doc} CN300LenNw()
Função que retorna as linhas novas de um modelo

@author matheus.raimundo
@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300LenNw(oModel)
Local nLen 			:= 0
Local nI 			:= 0
Local aSaveLines	:= FWSaveRows()

For nI := 1 To oModel:Length()
	oModel:GoLine(nI)
	If oModel:IsInserted() .And. !oModel:IsDeleted()
		nLen := nLen + 1
	EndIf
Next nI

FWRestRows(aSaveLines)
Return nLen

//------------------------------------------------------------------
/*/{Protheus.doc} CN300AjSlF()
Função para ajustar o saldo, caso de diferença de casas decimais

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function CN300AjSlF(oModel)
Local oCNFDetail 	:= oModel:GetModel('CNFDETAIL')
Local oCNSDetail 	:= oModel:GetModel('CNSDETAIL')
Local oCNBDetail 	:= oModel:GetModel('CNBDETAIL')
Local oStruCNF 		:= oModel:GetModel('CNFDETAIL'):GetStruct()
Local nDif  	   	:= 0
Local nValor		:= 0
Local nI			:= 0
Local nI2			:= 0
Local nI3			:= 0
Local nRound		:= TamSX3('CNS_PRVQTD')[2]
Local aSavelines	:= FWSaveRows()
Local aItens		:= {}
Local nPos			:= 0
Local aDifs		:= {}

CNTA300BlMd(oCNFDetail, .T., .T. )

For nI := 1 To oCNFDetail:Length()
	oCNFDetail:GoLine(nI)
	If !oCNFDetail:IsDeleted()

		For nI2 := 1 To oCNSDetail:Length()
			oCNSDetail:GoLine(nI2)
			If !oCNSDetail:IsDeleted()
				nPos := aScan(aItens,{|x| x[1] == oCNSDetail:GetValue('CNS_PRODUT')})
				If nPos == 0
					Aadd(aItens, {oCNSDetail:GetValue('CNS_PRODUT'), oCNSDetail:GetValue('CNS_PRVQTD')})
				Else
					aItens[nPos, 2]  += oCNSDetail:GetValue('CNS_PRVQTD')
				EndIf
			EndIf
		Next nI2

	EndIf
Next nI

nDif := oModel:GetModel('CNADETAIL'):GetValue('CNA_VLTOT') -  oModel:GetModel("CALC_CNF"):GetValue('CNF_CALC')
If nDif > -5 .And. nDif < 5
	For nI := 1 To oCNBDetail:Length()
		oCNBDetail:GoLine(nI)
		If !oCNBDetail:IsDeleted()
			nPos := Ascan(aItens,{|x| x[1] == oCNBDetail:GetValue('CNB_PRODUT')})
			nDif := oCNBDetail:GetValue('CNB_QUANT') - aItens[nPos, 2]
			Aadd(aDifs,{oCNBDetail:GetValue('CNB_PRODUT'), nDif})
		EndIf
	Next nI

	For nI2	:= oCNFDetail:Length() To 1 Step -1
		oCNFDetail:GoLine(nI2)
		If !oCNFDetail:IsDeleted()
			For nI3 := oCNSDetail:Length() To 1 Step -1
				oCNSDetail:GoLine(nI3)
				nPos := Ascan(aDifs,{|x| x[1] == oCNSDetail:GetValue('CNS_PRODUT')})
				If nPos > 0
					If !oCNSDetail:IsDeleted()
						oCNSDetail:SetValue('CNS_PRVQTD', Round(oCNSDetail:GetValue('CNS_PRVQTD') + aDifs[nPos, 2],nRound))
						Loop
					EndIf
				EndIf
			Next nI3
			Exit
		EndIf
	Next nI2
EndIf

//-Insere na ultima parcela divergencia financeira
nDif := oModel:GetModel('CNADETAIL'):GetValue('CNA_VLTOT') -  oModel:GetModel("CALC_CNF"):GetValue('CNF_CALC')
If nDif <> 0.00
	For nI := oCNFDetail:Length() To 1 Step -1
		oCNFDetail:GoLine(nI)
		If !oCNFDetail:IsDeleted() .And. oCNFDetail:GetValue('CNF_VLPREV') > 0
			nValor := oCNFDetail:GetValue('CNF_VLPREV') + nDif
			oCNFDetail:SetValue('CNF_VLPREV',nValor)
			Exit
		EndIf
	Next nI
EndIf

FWRestRows(aSaveLines)

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CN300CAprv(cContr)
Função que valida se o contrato não está pendente de aprovação e pode

@author Matheus Lando Raimundo
@since 03/02/2014
@version 1.0
/*/
//------------------------------------------------------------------
Function CN300CAprv(cContr, lMostraHelp)
Local lRet := .T.
Local cRevAtu := ""

Default lMostraHelp := .F.

DbSelectArea("CN9")
CN9->(DbSetOrder(1))
If CN9->(dbSeek(xFilial("CN9")+cContr))
	cRevAtu := CN9->CN9_REVATU
	If CN9->(dbSeek( xFilial("CN9") + cContr + cRevAtu )) .And. (CN9->CN9_SITUAC == '09')
		DbSelectArea("CN1")
		CN1->(DbSetOrder(1))
		If CN1->(DbSeek(xFilial("CN1") + CN9->CN9_TPCTO))
			DbSelectArea("CN0")
			CN0->(DbSetOrder(1))
			If CN0->(DbSeek(xFilial("CN0") + CN9->CN9_TIPREV))
				If CN0->CN0_TIPO == '2'							//Revisão de Reajuste
				lRet := Cn300RetSt("REVREAJU",2)
			ElseIf CN0->CN0_TIPO == '3'							//Revisão de Realinhamento
					lRet := Cn300RetSt("REVREALI",2)
				EndIf
			EndIf
		EndIf
	EndIf
EndIf

If !lRet .And. lMostraHelp
	Help('',1,'CNTA300NSEL')//"Este Item não poderá ser selecionado pois o contrato que o originou encontra-se em processo de revisão, fazendo-se necessária sua aprovação ou cancelamento para realização deste procedimento"
EndIf

Return lRet


//------------------------------------------------------------------
/*/{Protheus.doc} A300EstPVL()
Funcao para estornar pedido de venda

@author alexandre.gimenez
@since 30/04/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300EstPVL()
Local lRet 		:= .T.
Local aPedidos		:= {}
Local nX			:= 0
Local lContinua	:= .F.

If Cn300RetSt("VENDA") .And. A300RevMed()
	//Retorna Pedidos nao entregues
	aPedidos := A300SldRec('a3','', .F. )
	If Len(aPedidos) > 0
		DbSelectArea( 'SC9' )
		SC9->( DbSetOrder(1) )	//C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN + C9_PRODUTO
		SC9->( DbGoTop() )
		Begin Transaction
			For nX:= 1 to Len(aPedidos)
				//Busca o pedido no SC9 - Pedidos Liberados
				If ( SC9->( MsSeek( xFilial('SC9') + aPedidos[nX] ) ) )
					If !lContinua .And. MSGYESNO(STR0024,STR0008)
						lContinua := .T.
					Else
						lContinua := .F.
						lRet := .F.
					EndIf
					If lContinua
						While SC9->( !Eof() ) .And. SC9->C9_PEDIDO == aPedidos[nX]
							lRet := A460Estorna(.F.,.T.,0)
							If !lRet
								DisarmTransaction()
								Exit
							EndIf
							SC9->(DbSkip())
						End
					EndIf
				EndIf
				If !lRet
					Exit
				EndIf
			Next nX
		End Transaction
	EndIf
EndIf

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} A300RvCnEd()
Funcao revisar contratos vinculados à um edital

@author Leonardo Quintania
@since 16/10/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300RvCnEd(oModel,cEdital,cProcesso)
Local aArea      := GetArea()
Local aAreaCN9   := CN9->(GetArea())
Local aSaveLines := FWSaveRows()
Local nVlTot     := oModel:GetValue('CN9MASTER','CN9_VLATU') //Valor Atualizado do Contrato
Local cNumero    := oModel:GetValue('CN9MASTER','CN9_NUMERO')
Local cTpRevi    := oModel:GetValue('CN9MASTER','CN9_TIPREV')
Local cPicture   := PesqPict("CN9","CN9_VLINI")
Local nVlMax     := 0
Local nVlMin     := 0
Local nPerc      := 0
Local nPorc      := 0
Local nPercant   := 0
Local nVrAdit    := 0
Local nValAnt    := 0
Local nUltValAtu := nVlTot
Local cTexto     := ""
Local lRet		   := .T.
Local lInclui	   := oModel:GetOperation() == MODEL_OPERATION_INSERT
Local nPorcRev   := 0

//-- Posiciona no edital para ver qual é a espécie
CO1->(dbSetOrder(1))
If CO1->(dbSeek(xFilial("CO1")+cEdital+cProcesso))
	If CO1->CO1_REFORM == "1" //-- Reformas: 50%
		nPerc := 0.50
	ElseIf CO1->CO1_REFORM == "2" //-- Obras e servicos: 25%
		nPerc := 0.25
	EndIf
EndIf
CN9->(DbSetOrder(1))
If CN9->(DbSeek(xFilial("CN9")+cNumero))
	While CN9->(!EOF()) .And. CN9->CN9_NUMERO == cNumero
		If lInclui .Or. !(CN9->CN9_SITUAC == '09') //não considera alteração da revisão antes da aprovação
    		If Empty(CN9->CN9_REVISA) //Quando for o primeiro registro
    			nUltValAtu:= CN9->CN9_VLATU
    		Else
        		CN0->(DbSetOrder(1)) //Posicionar para verificar o tipo de revisão
        		CN0->(DbSeek(xFilial("CN0")+ CN9->CN9_TIPREV))
        		If CN0->CN0_REPACT == "1"
					nVrAdit := 0
					nUltValAtu := CN9->CN9_VLATU
					nPorc := 0
        		Else
					nVrAdit += (CN9->CN9_VLATU - nUltValAtu)//
                    nPercant := nPorc
					nPorcRev := ((CN9->CN9_VLATU-nUltValAtu)/nUltValAtu)
					nPorc += nPorcRev //
        			If nPorc > nPerc
        				nVlMax := nUltValAtu  * (1+nPercAnt+nPerc)
        				nVlMin := nUltValAtu * (1-nPerc)
        				If (nVlTot > nVlMax .Or. nVlTot < nVlMin)
        					lRet := .F.
                            cTexto := STR0030 + LTrim(STR(nPorc * 100)) + STR0031 +Transform(nUltValAtu,cPicture)+;
                                      STR0032 + LTrim(Transform(nVlMin,cPicture)) + STR0017 + LTrim(Transform(nVlMax,cPicture)) +"."
                            Help('',1,'CN300PORCENT',,cTexto,4)
        				EndIf
        				Exit
        			EndIf
        		EndIf
            EndIf
            nValAnt   := CN9->CN9_VLATU
        EndIf
		CN9->(DbSkip())
	EndDo

    //Verifica valor atual - inclusão ou alteração
    CN0->(dbSetOrder(1))
    CN0->(dbSeek(xFilial("CN0")+ cTpRevi))
    If CN0->CN0_REPACT == "2"
        nPercant := nPorc
        nPorc   += ((nVlTot - nUltValAtu)/nUltValAtu)
        If nPorc > nPerc
            nVlMax := nUltValAtu  * (1-nPercAnt+nPerc)
            nVlMin := nUltValAtu  * (1-nPerc)
            If (nVlTot > nVlMax .Or. nVlTot < nVlMin)
                lRet := .F.
                cTexto := STR0030 + LTrim(STR(nPorc * 100)) + STR0031 +Transform(nUltValAtu,cPicture)+;
                          STR0032 + LTrim(Transform(nVlMin,cPicture)) + STR0017 + LTrim(Transform(nVlMax,cPicture)) +"."
                Help('',1,'CN300PORCENT',,cTexto,4)
            EndIf
        EndIf
    EndIf
EndIf

RestArea(aAreaCN9)
RestArea(aArea)
FWRestRows( aSaveLines )
Return lRet

//-------------------------------------------------------------------
/*{Protheus.doc} CN300GerApr
Realiza a geração de registros para aprovação SCR

@author Leonardo Quintania
@since 25/02/2015
@version P12.1.4
*/
//-------------------------------------------------------------------
Function CN300GerApr(oModelCN9,nOper,nTipOpr)
Local cDoc     	:= ""   	// Documento composto de numero do contrato + revisao
Local cTipoDoc 	:= "RV"		// Indica que o documento é do tipo revisao de contrato

Local cContra	:= oModelCN9:GetValue("CN9_NUMERO")
Local cRevisa	:= oModelCN9:GetValue("CN9_REVISA")
Local cGrpApr	:= oModelCN9:GetValue("CN9_APROV")

Local nVlrApr	:= Cn300VlApr(oModelCN9)
Local nTxMoeda 	:= 0

Local lRet	   	:= .T.

Local aCampos	:= {}
Default nOper	:= 1

cDoc     := cContra + cRevisa					//Contrato + Revisão
nTxMoeda := RecMoeda(dDataBase,CN9->CN9_MOEDA) 	// Taxa da moeda

If nOper == 1
	aAdd(aCampos, {cDoc,cTipoDoc,nVlrApr,"","",cGrpApr,"",CN9->CN9_MOEDA,nTxMoeda,dDataBase,""})
	lRet := !GCTAlcEnt(oModelCN9:GetModel(),nTipOpr,1,cTipoDoc,cDoc,,aCampos)
Else
	aAdd(aCampos, {cDoc,cTipoDoc,nVlrApr,"","",cGrpApr,"","","",dDataBase,""})
	lRet := !GCTAlcEnt(oModelCN9:GetModel(),nTipOpr,3,cTipoDoc,cDoc,,aCampos)
EndIf

Return lRet
//------------------------------------------------------------------
/*/{Protheus.doc} A300AtuNE()
Funcao para atualizar a nota de empenho na revisão do contrato

@param oModel Modelo de dados
@author Flavio Lopes Rasta
@since 30/01/2015
@version 1.0
/*/
//-------------------------------------------------------------------
Function A300AtuNE(oModel)
Local oModelCN9		:= oModel:GetModel('CN9MASTER')
Local oModelCNA		:= oModel:GetModel('CNADETAIL')
Local oModelCNB		:= oModel:GetModel('CNBDETAIL')
Local aItensAnt		:= {}
Local aItensDep		:= {}
Local aItens		:= {}
Local aDados		:= {}
Local aDadosNew	:= {}
Local nPos			:= 0
Local nPosRep		:= 1
Local nX 			:= 1
Local nY 			:= 1
Local nZ			:= 0
Local cContrato		:= oModelCN9:GetValue('CN9_NUMERO')
Local cRevisa		:= oModelCN9:GetValue('CN9_REVISA')
Local cRevAtu		:= ""
Local cNotaEmp
Local cItNotaEmp
Local nValor		:= 0
Local lRet			:= .T.

//-- Adiciona ao array os dados novos da CNB
For nX:=1 To oModelCNA:Length()
	oModelCNA:GoLine(nX)
	If !oModelCNA:IsDeleted()
		For nY:=1 To oModelCNB:Length()
			oModelCNB:GoLine(nY)
			If !Empty(oModelCNB:GetValue('CNB_CODNE'))
				cNotaEmp 	:= oModelCNB:GetValue('CNB_CODNE')
				cItNotaEmp 	:= oModelCNB:GetValue('CNB_ITEMNE')
				nValor		:= oModelCNB:GetValue('CNB_QUANT') * oModelCNB:GetValue('CNB_VLUNIT')
				If (nPosRep := aScan(aItensDep,{|x| AllTrim(x[1]) + AllTrim(x[2]) ==  AllTrim(cNotaEmp) + AllTrim(cItNotaEmp)}) ) > 0
					aItensDep[nPosRep][3] := aItensDep[nPosRep][3]+nValor
				Else
					aAdd(aItens,cNotaEmp)
					aAdd(aItens,cItNotaEmp)
					aAdd(aItens,nValor)
					aAdd(aItensDep, aItens)
				Endif
				aItens:={}
			Endif
		Next nY
	Endif
Next nX


If !Empty(aItensDep)
	aSort(aItensDep, , , { | x,y | x[1]+x[2] < y[1]+y[2] } )

	//-- Obtem a revisão anterior
	CN9->(DbSetOrder(8))
	CN9->(DbSeek(xFilial("CN9")+cContrato+cRevisa))


	cRevAtu := CN9->CN9_REVISA+Space(TamSX3("CN9_REVISA")[1]-Len(CN9->CN9_REVISA))

	//-- Seleciona o contrato vigente anterior a revisão
	CNB->(DbSetOrder(1))
	CNB->(DbSeek(xFilial("CNB")+cContrato+cRevAtu))
	While !CNB->(Eof()) .And. CNB->(CNB_CONTRA+CNB_REVISA) == cContrato+cRevAtu
		If !Empty(CNB->CNB_CODNE)
			cNotaEmp 	:= CNB->CNB_CODNE
			cItNotaEmp 	:= CNB->CNB_ITEMNE
			nValor		:= CNB->CNB_QUANT * CNB->CNB_VLUNIT
			//-- Adiciona ao array os dados antigos da CNB
			If (nPosRep := aScan(aItensAnt,{|x| AllTrim(x[1]) + AllTrim(x[2]) ==  AllTrim(cNotaEmp) + AllTrim(cItNotaEmp)}) ) > 0
				aAdd(aItensAnt[nPosRep][3],aItensAnt[nPosRep][3]+nValor)
			Else
				aAdd(aItens,cNotaEmp)
				aAdd(aItens,cItNotaEmp)
				aAdd(aItens,nValor)
				aAdd(aItensAnt,aItens)
			Endif
			aItens:={}
		Endif
		CNB->(DbSkip())
	End

	aSort(aItensAnt, , , { | x,y | x[1]+x[2] < y[1]+y[2] } )

	//-- Compara os valores

	For nX:=1 To Len(aItensDep)
		For nY:=1 To Len(aItensAnt)
			If aItensDep[nX][1]+aItensDep[nX][2] == aItensAnt[nY][1]+aItensAnt[nY][2]
				If aItensAnt[nX][3] <> aItensDep[nY][3]
					aAdd(aDados,{})
		  			aAdd(aTail(aDados),aItensDep[nX][1])
					aAdd(aTail(aDados),aItensDep[nX][2])
					aAdd(aTail(aDados),aItensAnt[nY][3])
					aAdd(aTail(aDados),aItensDep[nX][3])
				Endif
			EndIf
		Next nY
	Next nX

	//Aglutina por nota de empenho
	For nZ := 1 To Len(aDados)
	 	nPos := aScan(aDadosNew,{|x| AllTrim(x[1])== AllTrim(aDados[nZ][1])})
	 	If nPos > 0
			aAdd(aDadosNew[nPos],{aDados[nZ][2],aDados[nZ][3],aDados[nZ][4]})
		Else
			aAdd(aDadosNew,{})
			aAdd(aTail(aDadosNew),aDados[nZ][1])
  			aAdd(aTail(aDadosNew),{aDados[nZ][2],aDados[nZ][3],aDados[nZ][4]})
		EndIf
	Next nZ

	If !Empty(aDadosNew)
		lRet := GCPXRefCan(aDadosNew)
	EndIf
Endif

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} A300CpoUsr()
Funcao para validação do array informado pelo usuario no ponto de entrada CN300USRFD

@param 		aCpoUsr
@author 	Israel.Escorizza
@since 		24/04/2015
@version 	1.0
/*/
//-------------------------------------------------------------------

Function A300CpoUsr(aUsrCpo)
Local nIndex 	:= 1
Local nIndCpo	:= 1
Local nIndErr	:= 1
Local aErros	:= {}
Local cError	:= CRLF

Default aUsrCpo	:= ""

If ValType(aUsrCpo)=="A"
	While nIndex <= Len(aUsrCpo)
		//- Verifica se a posição do array contem um array
		If ValType(aUsrCpo[nIndex]) != "A"
			aAdd(aErros,STR0002)
			aDel(aUsrCpo,nIndex)
			aSize(aUsrCpo,Len(aUsrCpo)-1)
		Else
			//- Verifica se tabela informada faz parte do modelo
			If aUsrCpo[nIndex][1] $ "AGW|CN8|CNA|CNB|CNC|CNF|CNG|CNH|CNI|CNK|CNN|CNS|CNT|CNU|CNV|CNW|CNX|CNZ|CPD|CXI|CXL|CXM|CN9|CND"
				If aUsrCpo[nIndex][1] == "CN9"
					aUsrCpo[nIndex][1]=aUsrCpo[nIndex][1]+"MASTER"
				Else
					aUsrCpo[nIndex][1]=aUsrCpo[nIndex][1]+"DETAIL"
				EndIf

				//- Verifica se campos do usuario foram informados em um array.
				If ValType(aUsrCpo[nIndex][2]) != "A"
					aAdd(aErros,STR0002)
					aDel(aUsrCpo,nIndex)
					aSize(aUsrCpo,Len(aUsrCpo)-1)
				Else
					nIndCpo := 1
					SX3->(dbSetOrder(2))
					While nIndCpo <= Len(aUsrCpo[nIndex][2])
						If !SX3->(dbSeek(aUsrCpo[nIndex][2][nIndCpo]))
							aAdd(aErros,STR0003+aUsrCpo[nIndex][2][nIndCpo])
							aDel(aUsrCpo[nIndex][2],nIndCpo)
							aSize(aUsrCpo[nIndex][2],Len(aUsrCpo[nIndex][2])-1)
						Else
							//- Verifica se campo é do usuario.
							If Empty(GetSX3Cache(aUsrCpo[nIndex][2][nIndCpo],'X3_PROPRI'))
								aAdd(aErros,STR0003+aUsrCpo[nIndex][2][nIndCpo])
								aDel(aUsrCpo[nIndex][2],nIndCpo)
								aSize(aUsrCpo[nIndex][2],Len(aUsrCpo[nIndex][2])-1)
							Else
								nIndCpo++
							EndIf
						EndIf
					EndDo
					If Len(aUsrCpo[nIndex][2]) == 0
						aDel(aUsrCpo,nIndex)
						aSize(aUsrCpo,Len(aUsrCpo)-1)
						nIndex--
					EndIf
				EndIf
			Else
				aAdd(aErros,STR0004+aUsrCpo[nIndex][1])
				aDel(aUsrCpo,nIndex)
				aSize(aUsrCpo,Len(aUsrCpo)-1)
			EndIf
		EndIf

		nIndex++
	EndDo
Else
	aAdd(aErros,STR0002)
EndIf

While nIndErr <= Len(aErros)
	cError+=aErros[nIndErr]+CRLF
	nIndErr++
EndDo
If Len(aErros) > 0
	Help("",1,cError)
EndIf

Return

//=============================================================================
/*/{Protheus.doc} A300RevSrv()
Função responsável pela atualização do campo “CNB_QUANT” na revisão de novo item
contido na planilha quando esta for de serviços.

@author israel.escorizza
@since 10/05/2016
@return
/*/
//=============================================================================
Function A300RevSrv()
Local oModel	:= FwModelActive()
Local oModelCNF	:= oModel:GetModel('CNFDETAIL')

Local nQtdAbert	:= 0
Local nX		:= 0

If 	oModel:IsActive() .And. oModel:GetId() == 'CNTA300'	.And.;
	!Empty(oModel:GetValue('CN9MASTER','CN9_REVISA')) 	.And.;
	Empty(oModel:GetValue('CNBDETAIL','CNB_QUANT'))	 	.And.;
	!Empty(oModelCNF:GetValue('CNF_NUMERO'))			.And.;
	Cn300RetSt('SERVIÇO')

	For nX := 1 To oModelCNF:Length()
		oModelCNF:GoLine(nX)
		If !oModelCNF:IsDeleted() .And. Empty(oModelCNF:GetValue('CNF_DTREAL'))
			nQtdAbert++
		EndIf
	Next nX

	oModel:GetModel('CNBDETAIL'):GetStruct():SetProperty('CNB_QUANT'  ,MODEL_FIELD_WHEN,{||.T.})
	oModel:GetModel('CNBDETAIL'):GetStruct():SetProperty('CNB_SLDMED' ,MODEL_FIELD_WHEN,{||.T.})
	oModel:SetValue('CNBDETAIL','CNB_QUANT' ,nQtdAbert)
	oModel:SetValue('CNBDETAIL','CNB_SLDMED',nQtdAbert)
	oModel:GetModel('CNBDETAIL'):GetStruct():SetProperty('CNB_QUANT'  ,MODEL_FIELD_WHEN,{||.F.})
	oModel:GetModel('CNBDETAIL'):GetStruct():SetProperty('CNB_SLDMED' ,MODEL_FIELD_WHEN,{||.F.})
EndIf

Return
//------------------------------------------------------------------
/*/{Protheus.doc} CNQtRRetro()
Função que retorna array com os itens a serem considerados no
reajuste retroativo.

@author 	Matheus Lando
@since 		04/02/2016
/*/
//-------------------------------------------------------------------
Function CNQtRRetro(cContra,cRevisa)
Local cAliasSql := GetNextAlias()
Local aProd	  := {}
Local dDtDe	  := CtoD("")
Local dDtAte	  := CtoD("")
Local oModel	  := FwModelActive()
Local oModCN9	  := oModel:GetModel('CN9MASTER')
Local lCposRet  := (CN9->(ColumnPos('CN9_DTRRDE')) > 0) .And. (CN9->(ColumnPos('CN9_DTRRAT')) > 0)

If lCposRet
	dDtDe 	 := oModCN9:GetValue("CN9_DTRRDE")
	dDtAte	 := oModCN9:GetValue("CN9_DTRRAT")
	If !Empty(dDtDe)
		BeginSQL Alias cAliasSql

		SELECT C7_PLANILH, C7_ITEMED,SUM(C7_QUJE) C7_QUJE FROM %Table:SC7% SC7
			INNER JOIN %Table:SD1% SD1 ON D1_FILIAL = %xFilial:SD1% AND  D1_PEDIDO = C7_NUM AND D1_ITEMPC = C7_ITEM AND SD1.%NotDel%
			INNER JOIN %Table:CNA% CNA ON CNA_FILIAL = %xFilial:CNA% AND CNA_CONTRA = C7_CONTRA AND CNA_NUMERO = C7_PLANILH AND CNA.%NotDel%
			WHERE  C7_FILIAL = %xFilial:SC7%
				AND SC7.%NotDel%
				AND C7_CONTRA = %Exp:cContra%
				AND D1_EMISSAO BETWEEN %Exp:dDtDe% AND %Exp:dDtAte%
				AND C7_CONTREV = %Exp:cRevisa%
				AND C7_QUJE > 0
			GROUP BY C7_PLANILH, C7_ITEMED
		EndSQL

	EndIf
EndIf

If Select(cAliasSql) > 0
	While !(cAliasSql)->(Eof())
		Aadd(aProd, {(cAliasSql)->(C7_PLANILH),(cAliasSql)->(C7_ITEMED),(cAliasSql)->(C7_QUJE)})
		(cAliasSql)->(DbSkip())
	EndDo
	(cAliasSql)->(dbCloseArea())
EndIf

Return aProd
//------------------------------------------------------------------
/*/{Protheus.doc} CNAddItRt()
Função que adiciona os itens referentes ao reajustes retroativo

@author 	Matheus Lando
@since 		04/02/2016
/*/
//-------------------------------------------------------------------
Function CNAddItRt()
Local oModel 	:= FwModelActive()
Local oModCN9 	:= oModel:GetModel('CN9MASTER')
Local oModCNB 	:= oModel:GetModel('CNBDETAIL')
Local oModCNA 	:= oModel:GetModel('CNADETAIL')
Local nX		:= 0
Local nY		:= 0
Local aHeader	:= oModCNB:GetStruct():GetFields()
Local cIndice	:= oModCN9:GetValue("CN9_INDICE")
Local cContra	:= oModCN9:GetValue("CN9_NUMERO")
Local cDataRef	:= oModCN9:GetValue("CN9_DREFRJ")
Local oStruCNB 	:= oModCNB:GetStruct()
Local oStruCNA 	:= oModCNA:GetStruct()
Local aDados	:= {}
Local aProds	:= {}
Local aItem		:= {}

Local aSaveLines:= FWSaveRows()
Local nIndice	:= A300VlrInd(cIndice,cDataRef,.T.)
Local nQuant	:= 0
Local nVlrAtu	:= 0
Local nVlrOri	:= 0
Local cTipRev	:= Cn300RetSt('TIPREV',1)
Local cCodTpRev	:= oModel:GetValue('CN9MASTER','CN9_TIPREV')

If  A300ApReRet(cCodTpRev) .And. !Cn300RetSt('FISICO',1) 
	oStruCNB:SetProperty("*",MODEL_FIELD_WHEN,{||.T.})
	oStruCNA:SetProperty("*",MODEL_FIELD_WHEN,{||.T.})

	aProds := CNQtRRetro(cContra,CnRevAnt())

	For nX := 1 To Len(aProds)
		oModCNA:GoLine(MTFindMVC(oModCNA,{{'CNA_NUMERO',aProds[nX,1]}}))
		oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',aProds[nX,2]}}))

		// Recupera valor antigo, o atual e devolve posicionamento para o antigo
		nVlrOri := oModCNB:getValue("CNB_VLUNIT")
		oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',oModCNB:GetValue('CNB_ITMDST')}}))

		nVlrAtu := oModCNB:getValue("CNB_VLUNIT")
		oModCNB:GoLine(MTFindMVC(oModCNB,{{'CNB_ITEM',aProds[nX,2]}}))

		// copia dados da origem
		If ((oModCNA:GetValue('CNA_FLREAJ') == '1' .And. cTipRev == DEF_REV_REAJU) .Or. cTipRev == DEF_REV_REALI) .And. (nVlrAtu-nVlrOri > 0)

			For nY := 1 to Len(aHeader)
				cCampo := AllTrim(aHeader[nY][MODEL_FIELD_IDFIELD])
				aAdd(aItem,{cCampo,oModCNB:GetValue(cCampo)})
			Next nY

			oModCNB:SetNoInsertLine(.F.)
			oModCNA:SetNoUpdateLine(.F.)

		 	For nY := 1 To Len(aItem)
				If nY == 1
					oModCNB:AddLine()
				EndIf
		 		If !(aItem[nY,1]) $ "CNB_REALI|CNB_VLTOTR|CNB_VLDESC" // Campos Calculados
					If aItem[nY,1] == "CNB_ITEM"
						oModCNB:LoadValue("CNB_ITEM",StrZero(oModCNB:GetLine(),TamSX3("CNB_ITEM")[1]))
					ElseIf aItem[nY,1] == "CNB_QUANT"
						oModCNB:SetValue("CNB_QUANT", aProds[nX,3] )
						//Quantidade Medida Origem
					ElseIf aItem[nY,1] == "CNB_QTDMED"
						//Quantidade Medida Nova
						oModCNB:LoadValue("CNB_QTDMED",0)
						//Quantidade Medida Origem
					ElseIf aItem[nY,1] == "CNB_SLDMED"
						//Saldo a Medir Novo
						oModCNB:LoadValue("CNB_SLDMED",oModCNB:GetValue("CNB_QUANT"))
						//Saldo a Medir Origem
					ElseIf aItem[nY,1] == "CNB_SLDREC"
						//Saldo a Receber Novo
						oModCNB:LoadValue("CNB_SLDREC",0)
						//Saldo a Receber Origem
					ElseIf aItem[nY,1] == "CNB_ITMDST"
						// Deixa item novo em branco
						oModCNB:LoadValue("CNB_ITMDST","")
					ElseIf aItem[nY,1] == "CNB_QTDORI"
						oModCNB:LoadValue("CNB_QTDORI",0)
					ElseIf aItem[nY,1] == "CNB_RJRTO"
						oModCNB:LoadValue("CNB_RJRTO",.T.)
					ElseIf aItem[nY,1] == "CNB_VLUNIT"
						oModCNB:SetValue("CNB_VLUNIT",nVlrAtu-nVlrOri)
					Else
						oModCNB:SetValue(aItem[nY,1],aItem[nY,2])
					EndIf
				EndIf
			Next nY

			A300AtCrRj(oModCNB:GetValue('CNB_QUANT'),oModCNB:GetValue('CNB_VLUNIT'))

			aItem := {}
		EndIf

	Next nX

	oStruCNB:SetProperty("*",MODEL_FIELD_WHEN,{||.F.})
	oStruCNA:SetProperty("*",MODEL_FIELD_WHEN,{||.F.})

	oModCNB:SetNoInsertLine(.T.)
	oModCNA:SetNoUpdateLine(.T.)

	FWRestRows(aSaveLines)
EndIf
Return


//------------------------------------------------------------------
/*/{Protheus.doc} A300AtCrRj()
Função que atualiza o cronograma financeiro refente ao
reajuste retroativo.

@author 	Matheus Lando
@since 		04/02/2016
/*/
//-------------------------------------------------------------------
Function A300AtCrRj(nQuant,nVlrUnit)
Local oModel := FwModelActive()
Local oModCNS	:= oModel:GetModel("CNSDETAIL")
Local oModCNF	:= oModel:GetModel("CNFDETAIL")
Local oModCNB	:= oModel:GetModel("CNBDETAIL")
Local nX		:= 0
Local nY		:= 0
Local aSavelines	:= FWSaveRows()


oModCNF:SetNoUpdateLine(.F.)
oModCNS:SetNoUpdateLine(.F.)

oModCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})
oModCNS:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.T.})

For nX := 1 To oModCNF:Length()
	oModCNF:Goline(nX)
	If !oModCNF:IsDeleted() .And. oModCNF:GetValue("CNF_VLREAL") == 0
		oModCNF:SetValue("CNF_VLPREV",oModCNF:GetValue("CNF_VLPREV")+(nQuant*nVlrUnit))
		Exit
	EndIf
Next nX

oModCNF:SetNoUpdateLine(.T.)
oModCNS:SetNoUpdateLine(.T.)

oModCNF:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.F.})
oModCNS:GetStruct():SetProperty("*",MODEL_FIELD_WHEN,{||.F.})

FwRestRows(aSaveLines)

Return

//=============================================================================
/*/{Protheus.doc} Cn300VlApr
Função responsável por retornar o valor que será enviado para aprovação da revisão
baseado nos parametros MV_CNRVDIF e MV_CNRVSAL

@author israel.escorizza
@since 23/01/2017
@return nRet
/*/
//=============================================================================
Function Cn300VlApr(oModelCN9)
Local aAreaCN9	:= CN9->(GetArea())
Local aSaveLines:= FWSaveRows()

Local cAprRvDif	:= SuperGetMV('MV_CNRVDIF',.F.,"")	//- Tipos de revisão aprovação por dif. valor total
Local cAprRvSal	:= SuperGetMV('MV_CNRVSAL',.F.,"")	//- Tipos de revisão aprovação por valor do saldo

Local cNumDoc	:= ""
Local cTipRev	:= ""
Local cRevVal	:= "1|2|3|C" //- Aditivo|Reajuste|Realinhamento|Renovação

Local nSaldo	:= 0
Local nVlAtu	:= 0
Local nRet		:= 0

If !Empty(oModelCN9)
	cNumDoc	:= oModelCN9:GetValue("CN9_NUMERO")+oModelCN9:GetValue("CN9_REVISA")
	nSaldo	:= oModelCN9:GetValue("CN9_SALDO")
	nVlAtu	:= oModelCN9:GetValue("CN9_VLATU")
Else
	cNumDoc := CN9->(CN9_NUMERO+CN9_REVISA)
	nSaldo 	:= CN9->CN9_SALDO
	nVlAtu	:= CN9->CN9_VLATU
EndIf

cTipRev	:= Cn300RetSt("TIPREV",,,CnGetCtNum(cNumDoc,"RV"))
cRevVg	:= CnGetRevVg(CN9->CN9_NUMERO, CN9->CN9_FILCTR)

If cTipRev $ cRevVal
	If cTipRev $ cAprRvSal 			//- Aprovação por saldo
		nRet := nSaldo
	ElseIf cTipRev $ cAprRvDif		//- Aprovação por diferença de valor do contrato
		dbSelectArea('CN9')
		CN9->(dbSetOrder(1))
		CN9->(MsSeek(xFilial('CN9')+CN9->(CN9_NUMERO)+cRevVg))
		nRet := nVlAtu - CN9->CN9_VLATU
		nRet := Iif(nRet > 0,nRet,0.01)
	Else							//- Aprovação por valor do contrato
		nRet := nVlAtu
	EndIf
Else
	nRet := 0
EndIf
FWRestRows(aSaveLines)
RestArea(aAreaCN9)

Return nRet

//------------------------------------------------------------------
/*/{Protheus.doc} A300RvPrz()
Funcao para validação referente ao art. 57 da lei 8666. Caso exista adição
de prazo, não será validado o valor aditivado. Funçao utilizada em contratos
gerados pelo modulo Gestão de Compras Públicas.

@author 	Jose.Delmondes
@since 		09/06/2016
@version 	1.0
/*/
//-------------------------------------------------------------------
Function A300RvPrz(oModel)
Local lRet			:= .T.
Local cTpRev		:= oModel:GetValue('CN9MASTER','CN9_TIPREV')
Local cRevAnt		:= Tira1(oModel:GetModel("CN9MASTER"):GetValue("CN9_REVISA"))
Local aArea		:= GetArea()
Local aAreaCN0	:= {}
Local aAreaCN9	:= {}


If cRevAnt = Replicate('0',TamSX3("CN9_REVISA")[1]) // Ajusta Tira1
	cRevAnt = Replicate(' ',TamSX3("CN9_REVISA")[1])
EndIf

dbSelectArea("CN0")
aAreaCN0 := CN0->(GetArea())
CN0->(dbsetOrder(1))

If CN0->(dbSeek(xFilial("CN0")+cTpRev)) .And. CN0->CN0_ESPEC $ '3*4' .And. CN0->CN0_MODO $ '1*3'
	dbSelectArea("CN9")
	aAreaCN9 := CN9->(GetArea())
	CN9->(dbSetorder(1))
	If CN9->(dbSeek(xFilial("CN9")+oModel:GetValue('CN9MASTER','CN9_NUMERO')+cRevAnt))
		If DateDiffDay(CN9->CN9_DTFIM,oModel:GetValue('CN9MASTER','CN9_DTFIM')) > 0
			lRet := .F.
		EndIf
	EndIf
	RestArea(aAreaCN9)
EndIf

RestArea(aAreaCN0)
RestArea(aArea)

Return lRet

//------------------------------------------------------------------
/*/{Protheus.doc} CN300CNZVD()
Função para liberar o modelo da CNZ quando feita alterações na quantidade

@author 	filipe.goncalves
@since 		17/04/2017
@version 	1.0
/*/
//-------------------------------------------------------------------
Function CN300CNZVD(oModel)
Local aCTBEnt	:= CTBEntArr()
Local aCampos   := {}
Local cAutom	:= oModel:GetModel("CN9MASTER"):GetValue("CN9_AUTO") // -- 0 - Default; 1 - Vindo da Automação (Robô)
Local nX		:= 0

aCampos := {}

If cAutom == '0'
	aAdd(aCampos,{'CNZDETAIL',{'CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
Else
	aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})
EndIf

For nX := 1 To Len(aCTBEnt)
	aAdd(aCampos,{'CNZDETAIL', {"CNZ_EC" +aCTBEnt[nX] +"CR" }})
	aAdd(aCampos,{'CNZDETAIL', {"CNZ_EC" +aCTBEnt[nX] +"DB" }})
Next nX

MtBCMod(oModel,aCampos,{||.T.},'2')

Return

//------------------------------------------------------------------
/*/{Protheus.doc} A300SrvRec(cNumCrg,cNumPar)
Função que valida se itens já medidos foram recebidos para planilha de serviço

@author 	Israel.escorizza
@since 		08/06/2017
@version 	1.0
/*/
//-------------------------------------------------------------------
Function A300SrvRec(oModel,nModo,cNumCrg,cNumPar)
Local xRet		:= .F.
Local cRevAnt	:= Tira1(oModel:GetValue("CN9MASTER","CN9_REVISA"))
Local cQtdNRec 	:= ""
Local cSelPar	:= ""
Local cAliasSql	:= ""

Default oModel	:= FwModelActive()
Default nModo	:= 0
Default cNumCrg	:= ""
Default cNumPar := ""

If cRevAnt = Replicate('0',TamSX3("CN9_REVISA")[1]) // Ajusta Tira1
	cRevAnt = Replicate(' ',TamSX3("CN9_REVISA")[1])
EndIf

If nModo == 0
	cSelect := "% Count(*) %"
	cSelPar := "% 1 = 1 AND %"
Else
	cSelect := "% 'T' %"
	cSelPar := "% CXN.CXN_PARCEL = '"+ cNumPar + "' AND %"
EndIf

If Cn300RetSt("COMPRA")
	cQtdNRec := " SELECT SUM(SC7.C7_QUJE) AS C7_QUJE "
	cQtdNRec += " FROM "+ RetSQLName("SC7") +" SC7 "
	cQtdNRec += " WHERE "
	cQtdNRec += " SC7.C7_FILIAL = CND.CND_FILIAL "
	cQtdNRec += " AND SC7.C7_MEDICAO = CND.CND_NUMMED "
	cQtdNRec += " AND SC7.D_E_L_E_T_ = ' '"
Else
	cQtdNRec := " SELECT SUM(SC6.C6_QTDENT) AS C6_QTDENT "
	cQtdNRec := " FROM "+ RetSQLName("SC6") +" SC6 "
	cQtdNRec += " JOIN "+ RetSQLName("SC5") +" SC5 ON SC5.C5_NUM = SC6.C6_NUM "
	cQtdNRec += " WHERE SC5.C5_FILIAL = CND.CND_FILIAL "
	cQtdNRec += " AND SC6.C6_FILIAL = SC5.C5_FILIAL "
	cQtdNRec += " AND SC5.C5_MDNUMED = CND.CND_NUMMED "
	cQtdNRec += " AND SC5.D_E_L_E_T_ = ' ' "
	cQtdNRec += " AND SC6.D_E_L_E_T_ = ' ' "
EndIf
cQtdNRec := '%'+ cQtdNRec +'%'

cAliasSql := GetNextAlias()
BeginSQL Alias cAliasSql
	SELECT (%Exp:cSelect%) AS ATUALIZA

	FROM %Table:CND% CND,
	 	 %Table:CXN% CXN,
	 	 %Table:CNE% CNE

	WHERE
		CND.CND_FILCTR = %Exp:oModel:GetValue('CN9MASTER','CN9_FILCTR')%
	AND CND.CND_CONTRA = %Exp:oModel:GetValue("CN9MASTER","CN9_NUMERO")%
	AND CND.CND_REVISA = %Exp:cRevAnt%
	AND CND.D_E_L_E_T_ = ' '

	AND CXN.CXN_FILIAL = CND.CND_FILIAL
	AND CXN.CXN_CONTRA = CND.CND_CONTRA
	AND CXN.CXN_REVISA = CND.CND_REVISA
	AND CXN.CXN_NUMMED = CND.CND_NUMMED
	AND CXN.CXN_NUMPLA = %Exp:oModel:GetValue("CNADETAIL","CNA_NUMERO")%
	AND CXN.CXN_CRONOG = %Exp:cNumCrg%
	AND %Exp:cSelPar%
	CXN.D_E_L_E_T_ = ''

	AND CNE.CNE_FILIAL = CXN.CXN_FILIAL
	AND CNE.CNE_NUMMED = CXN.CXN_NUMMED
	AND CNE.CNE_CONTRA = CXN.CXN_CONTRA
	AND CNE.CNE_REVISA = CXN.CXN_REVISA
	AND CNE.CNE_NUMERO = CXN.CXN_NUMPLA
	AND CNE.D_E_L_E_T_= ' '

	AND (%Exp:cQtdNRec%) > 0
EndSQL

If (cAliasSql)->(!EOF())
	If nModo == 0
		xRet := (cAliasSql)->ATUALIZA
	ElseIf nModo == 1 .And. (cAliasSql)->ATUALIZA == 'T'
		XRet := .T.
	EndIf
EndIf

(cAliasSql)->(dbCloseArea())

Return xRet
//------------------------------------------------------------------
/*/{Protheus.doc} Cn300AtLiq(cNumMed,cRevisa)
Função que atualiza o valor liquido dos itens da medição na aprovação de revisão.

@author 	Israel.escorizza
@since 		24/11/2017
@version 	1.0
/*/
//-------------------------------------------------------------------
Function Cn300AtLiq(cNumMed,cContra,cRevisa,l121)
Local lRet 		:= .T.
Local aArea		:= GetArea()
Local aAreaCNE	:= CNE->(GetArea())
Local aSaveLines:= FWSaveRows()
Local cEspCtr	:= Iif(	Cn300RetSt('COMPRA',1,"",cContra+cRevisa,,.F.),'1','2')
Local cAliasCNE := GetNextAlias()

Default l121 := .F.

BeginSQL Alias cAliasCNE

SELECT	CNE.R_E_C_N_O_ as RECNO,
		CNE.CNE_VLTOT,
		CNE.CNE_VLDESC,
		CNE.CNE_EXCEDE,
		CXN.CXN_VLLIQD,
		CXN.CXN_VLMULT,
		CXN.CXN_VLBONI,
		CXN.CXN_VLDESC,
		CXN.CXN_VLRADI

FROM %Table:CNE% CNE
LEFT JOIN %Table:CXN% CXN ON

CNE.CNE_CONTRA = CXN.CXN_CONTRA AND
CNE.CNE_REVISA = CXN.CXN_REVISA AND
CNE.CNE_NUMMED = CXN.CXN_NUMMED

WHERE
CNE.CNE_CONTRA = %Exp:cContra% AND
CNE.CNE_REVISA = %Exp:cRevisa% AND
CNE.CNE_NUMMED = %Exp:cNumMed%

EndSql

While !(cAliasCNE)->(EOF())
	If (cAliasCNE)->CNE_EXCEDE == '1'
		nVlLiqd	:= (cAliasCNE)->CNE_VLTOT
	Else
		If l121
			nVlLiqd := CN130Liq(cEspCtr, (cAliasCNE)->CNE_VLTOT, (cAliasCNE)->CNE_VLDESC, (cAliasCNE)->CXN_VLLIQD, (cAliasCNE)->CXN_VLMULT, (cAliasCNE)->CXN_VLBONI, (cAliasCNE)->CXN_VLDESC, CND->CND_RETCAC * ((cAliasCNE)->CXN_VLLIQD / CND->CND_VLLIQD) ,(cAliasCNE)->CXN_VLRADI)
		Else
			nVlLiqd := CN130Liq(cEspCtr, (cAliasCNE)->CNE_VLTOT, (cAliasCNE)->CNE_VLDESC, CND->CND_VLTOT, CND->CND_VLMULT, CND->CND_VLBONI, CND->CND_DESCME, CND->CND_RETCAC, CND->CND_TOTADT)
		EndIf
	EndIf

	CNE->(dbGoTo((cAliasCNE)->RECNO))
	RecLock("CNE",.F.)
	CNE->CNE_VLLIQD := nVlLiqd
	MsUnlock()
	(cAliasCNE)->(dbSkip())
EndDo
(cAliasCNE)->(dbCloseArea())

FWRestRows(aSaveLines)
RestArea(aAreaCNE)
RestArea(aArea)
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A300ApReRet
Valida se tipo de revisão aplica reajuste retroativo. 
@param cCodTpRev, Caracter,  Tipo de revisão
@return lRet, Lógico, Verdadeiro/Falso
@author Eduardo Gomes Júnior
@since 16/03/2018
/*/
//-------------------------------------------------------------------
Function A300ApReRet(cCodTpRev)

Local aArea	:= GetArea()
Local lRet  := .F.

dbSelectArea("CN0")
dbSetOrder(1)
If	dbSeek(xFilial("CN0")+cCodTpRev)
	If	CN0_RETRO == "1"
		lRet  := .T.
	Endif 		 
Endif 

RestArea(aArea)

Return lRet

/*/{Protheus.doc} ClrVCpoUsr
Função para limpar a variável estática, com os campos de usuário do model  

@author pedro.alencar
@since 05/09/2018
/*/
Function ClrVCpoUsr ()

	If __aUsrCpo <> Nil
		aSize( __aUsrCpo, 0 )
		__aUsrCpo := Nil
	EndIf
	
Return Nil

/*/{Protheus.doc} CNLibForCl
Função que libera os campos relacionados a alteração de fornecedor e cliente 
@param oModel, modelo de dados
@param lFusao, logico
@author janaina.jesus
@since 23/11/2018
/*/
Function CNLibForCl(oModel,lFusao)
	Local cEspec     := Cn300RetSt("REVESPECIE")
	Local aCampos    := {}
	Local oStruCNA   := oModel:GetModel('CNADETAIL'):GetStruct()
	Local oStruCNC   := oModel:GetModel('CNCDETAIL'):GetStruct()
	
	CNTA300BlMd(oModel:GetModel("CNCDETAIL"),.F.,.F.)
	CNTA300BlMd(oModel:GetModel("CPDDETAIL"),.F.,.F.)
	
	If cEspec <> "5"		
		CNTA300BlMd(oModel:GetModel("CNADETAIL"), ,.T.)		
	EndIf
	
	If lFusao
		If CNTGetFun() == 'CNTA300'
			oStruCNC:SetProperty("CNC_CODIGO",	MODEL_FIELD_WHEN,{||.T.})
			oStruCNC:SetProperty("CNC_LOJA",	MODEL_FIELD_WHEN,{||.T.})
			oStruCNC:SetProperty("CNC_NOME",	MODEL_FIELD_WHEN,{||.T.})
			oStruCNA:SetProperty('CNA_FORNEC',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNA:SetProperty('CNA_LJFORN',	MODEL_FIELD_WHEN,{||.T.})
		Else
			oStruCNC:SetProperty('CNC_CLIENT',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNC:SetProperty('CNC_LOJACL',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNC:SetProperty('CNC_NOMECL',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNA:SetProperty('CNA_CLIENT',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNA:SetProperty('CNA_LOJACL',	MODEL_FIELD_WHEN,{||.T.})

		    // Partes Envolvidas do Contrato
		   aCampos := {}
		   aAdd(aCampos,{'CXIDETAIL',{'CXI_TIPO','CXI_CODCLI','CXI_LOJACL','CXI_NOMCLI','CXI_FILRES','CXI_DESFIL','CXI_PERRAT'}})
		   MtBCMod(oModel,aCampos,{||.T.},'2')
		   CNTA300BlMd(oModel:GetModel("CXIDETAIL"),.F.,.F.)
		EndIf
	Else
		If CNTGetFun() == 'CNTA300'
			oStruCNC:SetProperty('CNC_CODIGO',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
			oStruCNC:SetProperty('CNC_LOJA',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
			oStruCNC:SetProperty('CNC_NOME',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
			oStruCNA:SetProperty('CNA_FORNEC',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNA:SetProperty('CNA_LJFORN',	MODEL_FIELD_WHEN,{||.T.})
		Else
			oStruCNC:SetProperty('CNC_CLIENT',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
			oStruCNC:SetProperty('CNC_LOJACL',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
			oStruCNC:SetProperty('CNC_NOMECL',	MODEL_FIELD_WHEN,{||A300NwLine("CNCDETAIL")})
			oStruCNA:SetProperty('CNA_CLIENT',	MODEL_FIELD_WHEN,{||.T.})
			oStruCNA:SetProperty('CNA_LOJACL',	MODEL_FIELD_WHEN,{||.T.})

			// Partes Envolvidas do Contrato
			aCampos := {}
			aAdd(aCampos,{'CXIDETAIL',{'CXI_TIPO','CXI_CODCLI','CXI_LOJACL','CXI_NOMCLI','CXI_FILRES','CXI_DESFIL','CXI_PERRAT'}})
			MtBCMod(oModel,aCampos,{||.T.},'2')
			CNTA300BlMd(oModel:GetModel("CXIDETAIL"),.F.,.F.)
		EndIf
	EndIf
Return

/*/{Protheus.doc} CNLibConta
Função que libera os campos relacionados ao Contábel 
@param oModel, modelo de dados
@author janaina.jesus
@since 03/12/2018
/*/
Function CNLibConta(oModel)

	Local aCampos    := {}
	Local aCTBEnt    := {}
	Local nX         := 0

	aCTBEnt := CTBEntArr()

	If Cn300RetSt('SEMIAGRUP')
		CNTA300BlMd(oModel:GetModel("CXMDETAIL"),,.T.)
		aAdd(aCampos,{'CXMDETAIL',{'CXM_CC'}})

			For nX := 1 To Len(aCTBEnt)
			If CXM->(FieldPos("CXM_EC" +aCTBEnt[nX] +"CR")) > 0
				aAdd(aCampos[Len(aCampos),2],"CXM_EC" +aCTBEnt[nX] +"CR")
				aAdd(aCampos[Len(aCampos),2],"CXM_EC" +aCTBEnt[nX] +"DB")
			EndIf
		Next nX
		MtBCMod(oModel,aCampos,{||.T.},'2')
	Else
		CNTA300BlMd(oModel:GetModel("CNBDETAIL"),,.T.)
		CNTA300BlMd(oModel:GetModel("CNZDETAIL"),.F.)

		aAdd(aCampos,{'CNBDETAIL',{'CNB_CONTA','CNB_ITEMCT','CNB_CC','CNB_CLVL'}})

		For nX := 1 To Len(aCTBEnt)
			If CNB->(FieldPos("CNB_EC" +aCTBEnt[nX] +"CR")) > 0
				aAdd(aCampos[Len(aCampos),2],"CNB_EC" +aCTBEnt[nX] +"CR")
				aAdd(aCampos[Len(aCampos),2],"CNB_EC" +aCTBEnt[nX] +"DB")
			EndIf
		Next nX

		aAdd(aCampos,{'CNZDETAIL',{'CNZ_ITEM','CNZ_PERC','CNZ_CC','CNZ_CONTA','CNZ_ITEMCT','CNZ_CLVL'}})

		For nX := 1 To Len(aCTBEnt)
			aAdd(aCampos[Len(aCampos),2],"CNZ_EC" +aCTBEnt[nX] +"CR")
			aAdd(aCampos[Len(aCampos),2],"CNZ_EC" +aCTBEnt[nX] +"DB")
		Next nX
		MtBCMod(oModel,aCampos,{||.T.},'2')
		A300RevCtb(oModel)
	EndIf

Return
