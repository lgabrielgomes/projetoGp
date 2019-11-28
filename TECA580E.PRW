#include "TECA580E.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "MOVIMENTACAO.CH"

STATIC lLegend 	:= .T.
STATIC cFolder	:= ""
STATIC lCheck	:= .F.
STATIC lGesHora := .F.

//----------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Relacionamentos - Gestão de Escalas 

@Return 	model
@author 	Serviços
@since 		14/05/2014
/*/
//----------------------------------------------------------
Static Function ModelDef()

Local oModel		:= Nil
Local oStrTFF 	:= FWFormStruct(1,"TFF")
Local oStrTDX 	:= FWFormStruct(1,"TDX")
Local oStrTGX 	:= FWFormStruct(1,"TGX") 
Local oStrTGY 	:= FWFormStruct(1,"TGY")
Local oStrTGZ 	:= FWFormStruct(1,"TGZ") 
Local aAux			:= {}
Local lMV_GSGEHOR := SuperGetMV("MV_GSGEHOR",,.F.) .AND. At580EGHor()
Local nX 		:= 0
Local aArea
Local lHasTGYGeH := (TGY->( ColumnPos('TGY_ENTRA1')) > 0 )

Local bPosValidacao := {|oModel| At580EVdGr(oModel)}
Local bLinePre	:= {|oModel, nLIne, cAction| At580EVlDe(oModel, cAction) }

lLegend := .T.
lCheck	:= .F.

// Legenda do Efetivo
oStrTDX:AddField("","","TDX_SIT","BT",1,0,{||At580EGetLE()}/*bValid*/,/*bWhen*/, /*aValues*/,.F.,{||At580ELeg(1)},/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Status"

// Legenda de Efetivo
oStrTGX:AddField("","","TGX_SIT","BT",1,0,{||At580EGetLE()}/*bValid*/,/*bWhen*/, /*aValues*/,.F.,{||At580ELeg(2)},/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Status"

If lMV_GSGEHOR .AND. lHasTGYGeH
	oStrTDX:AddField(STR0081,STR0081,"TDX_ENTRA1","C",5,0,{||AtVldHora(FwFldGet("TDX_ENTRA1"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	oStrTDX:AddField(STR0082,STR0082,"TDX_SAIDA1","C",5,0,{||AtVldHora(FwFldGet("TDX_SAIDA1"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	
	oStrTDX:AddField(STR0083,STR0083,"TDX_ENTRA2","C",5,0,{||AtVldHora(FwFldGet("TDX_ENTRA2"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	oStrTDX:AddField(STR0084,STR0084,"TDX_SAIDA2","C",5,0,{||AtVldHora(FwFldGet("TDX_SAIDA2"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	
	oStrTDX:AddField(STR0085,STR0085,"TDX_ENTRA3","C",5,0,{||AtVldHora(FwFldGet("TDX_ENTRA3"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	oStrTDX:AddField(STR0086,STR0086,"TDX_SAIDA3","C",5,0,{||AtVldHora(FwFldGet("TDX_SAIDA3"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	
	oStrTDX:AddField(STR0087,STR0087,"TDX_ENTRA4","C",5,0,{||AtVldHora(FwFldGet("TDX_ENTRA4"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
	oStrTDX:AddField(STR0088,STR0088,"TDX_SAIDA4","C",5,0,{||AtVldHora(FwFldGet("TDX_SAIDA4"))},/*bWhen*/, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/)
EndIf

aAux := FwStruTrigger("TGY_TIPALO","TGY_DESMOV","Posicione('TCU', 1, xFilial('TCU')+M->TGY_TIPALO, 'TCU_DESC' )",.F.,Nil,Nil,Nil)
oStrTGY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TGY_ATEND","TGY_TURNO","At580ETrn(1)",.F.,Nil,Nil,Nil)
oStrTGY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TGZ_ATEND","TGZ_TURNO","At580ETrn(2)",.F.,Nil,Nil,Nil)
oStrTGZ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

If lMV_GSGEHOR .AND. lHasTGYGeH
	For nX := 1 to 4
		aAux := FwStruTrigger( ("TDX_ENTRA" + cValToChar(nX) ),("TDX_ENTRA" + cValToChar(nX) ),"AT580eUpdt('" + ("ENTRA" + cValToChar(nX)) + "')",.F.,Nil,Nil,Nil)
		oStrTDX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

		aAux := FwStruTrigger( ("TDX_SAIDA" + cValToChar(nX) ),("TDX_SAIDA" + cValToChar(nX) ),"AT580eUpdt('" + ("SAIDA" + cValToChar(nX)) + "')",.F.,Nil,Nil,Nil)
		oStrTDX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
	Next
	aAux := FwStruTrigger("TGY_ATEND","TGY_ATEND","At580EHor()",.F.,Nil,Nil,Nil)
	oStrTGY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
EndIf

oStrTDX:SetProperty("*", MODEL_FIELD_WHEN, {||.F.})
oStrTDX:SetProperty("TDX_SIT", MODEL_FIELD_WHEN, {||.T.})

oStrTGX:SetProperty("*", MODEL_FIELD_WHEN, {||.F.})
oStrTGX:SetProperty("TGX_SIT", MODEL_FIELD_WHEN, {||.T.})

oStrTFF:SetProperty( "TFF_PRODUT", MODEL_FIELD_WHEN, {|| .F. } )
oStrTFF:SetProperty( "TFF_ESCALA", MODEL_FIELD_WHEN, {|| .F. } )

If lMV_GSGEHOR .AND. lHasTGYGeH
	oStrTDX:SetProperty("TDX_ENTRA1", MODEL_FIELD_WHEN, {||At580eWhen('1')})
	oStrTDX:SetProperty("TDX_ENTRA2", MODEL_FIELD_WHEN, {||At580eWhen('2')})
	oStrTDX:SetProperty("TDX_ENTRA3", MODEL_FIELD_WHEN, {||At580eWhen('3')})
	oStrTDX:SetProperty("TDX_ENTRA4", MODEL_FIELD_WHEN, {||At580eWhen('4')})
	
	oStrTDX:SetProperty("TDX_SAIDA1", MODEL_FIELD_WHEN, {||At580eWhen('1')})
	oStrTDX:SetProperty("TDX_SAIDA2", MODEL_FIELD_WHEN, {||At580eWhen('2')})
	oStrTDX:SetProperty("TDX_SAIDA3", MODEL_FIELD_WHEN, {||At580eWhen('3')})
	oStrTDX:SetProperty("TDX_SAIDA4", MODEL_FIELD_WHEN, {||At580eWhen('4')})
	
	oStrTGY:SetProperty("TGY_ENTRA1", MODEL_FIELD_WHEN, {||At580eWhen('1')})
	oStrTGY:SetProperty("TGY_ENTRA2", MODEL_FIELD_WHEN, {||At580eWhen('2')})
	oStrTGY:SetProperty("TGY_ENTRA3", MODEL_FIELD_WHEN, {||At580eWhen('3')})
	oStrTGY:SetProperty("TGY_ENTRA4", MODEL_FIELD_WHEN, {||At580eWhen('4')})
	
	oStrTGY:SetProperty("TGY_SAIDA1", MODEL_FIELD_WHEN, {||At580eWhen('1')})
	oStrTGY:SetProperty("TGY_SAIDA2", MODEL_FIELD_WHEN, {||At580eWhen('2')})
	oStrTGY:SetProperty("TGY_SAIDA3", MODEL_FIELD_WHEN, {||At580eWhen('3')})
	oStrTGY:SetProperty("TGY_SAIDA4", MODEL_FIELD_WHEN, {||At580eWhen('4')})
EndIf

oStrTFF:SetProperty( "TFF_DESCRI"	, MODEL_FIELD_INIT, {|| Posicione("SB1",1,xFilial("SB1")+TFF->TFF_PRODUT,"B1_DESC") } )
oStrTFF:SetProperty( "TFF_NOMESC"	, MODEL_FIELD_INIT, {|| Posicione("TDW",1,xFilial("TDW")+TFF->TFF_ESCALA,"TDW_DESC") } )
oStrTDX:SetProperty( "TDX_SIT"		, MODEL_FIELD_INIT, {|| At580ELeg(1) } )
oStrTGX:SetProperty( "TGX_SIT"	  	, MODEL_FIELD_INIT, {|| At580ELeg(2) } )

oStrTGY:SetProperty( "TGY_ATEND"  	, MODEL_FIELD_VALID, {|oModel, cCampo, cAtend, nLine, cAtOld| At580EVlAl(oModel, cAtOld, oModel:GetValue("TGY_DTINI"), oModel:GetValue("TGY_DTFIM")) } )
oStrTGY:SetProperty( "TGY_DTINI"  	, MODEL_FIELD_VALID, {|oModel| At580EVlDt("TGYDETAIL","TGY_DTINI","TGY_DTINI","TGY_DTFIM") } )
oStrTGY:SetProperty( "TGY_DTFIM"  	, MODEL_FIELD_VALID, {|oModel| At580EVlDt("TGYDETAIL","TGY_DTFIM","TGY_DTINI","TGY_DTFIM") } )
oStrTGY:SetProperty( "TGY_GRUPO"  	, MODEL_FIELD_VALID, {|oModel| At580EVlGr("TGYDETAIL","TGY_GRUPO") } )
oStrTGY:SetProperty( "TGY_TIPALO"  	, MODEL_FIELD_VALID, {|oModel| At580TipAlo() } )
oStrTGY:SetProperty( "TGY_NOME"	  	, MODEL_FIELD_INIT , {|oModel| At580EInit(oModel)  })
oStrTGY:SetProperty( "TGY_DESC"	  	, MODEL_FIELD_INIT , {|oModel| At580ETur(oModel) 	 })
oStrTGY:SetProperty( "TGY_SEQ"	  	, MODEL_FIELD_INIT , {|| FwFldGet("TDX_SEQTUR") })
oStrTGY:SetProperty( "TGY_DESMOV"	, MODEL_FIELD_INIT , {|oModel| IIf(!oModel:GetOperation()==MODEL_OPERATION_INSERT,Posicione('TCU',1,xFilial('TCU')+TGY->TGY_TIPALO,'TCU_DESC'),"") } )


If !lMV_GSGEHOR .AND. lHasTGYGeH
	oStrTGY:RemoveField("TGY_ENTRA1")
	oStrTGY:RemoveField("TGY_ENTRA2")
	oStrTGY:RemoveField("TGY_ENTRA3")
	oStrTGY:RemoveField("TGY_ENTRA4")
	
	oStrTGY:RemoveField("TGY_SAIDA1")
	oStrTGY:RemoveField("TGY_SAIDA2")
	oStrTGY:RemoveField("TGY_SAIDA3")
	oStrTGY:RemoveField("TGY_SAIDA4")
EndIf

oStrTGZ:SetProperty( "TGZ_ATEND"  	, MODEL_FIELD_VALID, {|oModel, cCampo, cAtend, nLine, cAtOld| At580EVlAl(oModel, cAtOld, oModel:GetValue("TGZ_DTINI"), oModel:GetValue("TGZ_DTFIM")) } )
oStrTGZ:SetProperty( "TGZ_DTINI"  	, MODEL_FIELD_VALID, {|oModel| At580EVlDt("TGZDETAIL","TGZ_DTINI","TGZ_DTINI","TGZ_DTFIM") } )
oStrTGZ:SetProperty( "TGZ_DTFIM"  	, MODEL_FIELD_VALID, {|oModel| At580EVlDt("TGZDETAIL","TGZ_DTFIM","TGZ_DTINI","TGZ_DTFIM") } )
oStrTGZ:SetProperty( "TGZ_GRUPO"  	, MODEL_FIELD_VALID, {|oModel| At580EVlGr("TGZDETAIL","TGZ_GRUPO") } )
oStrTGZ:SetProperty( "TGZ_NOME"		, MODEL_FIELD_INIT , {|oModel| IIf(!oModel:GetOperation()==MODEL_OPERATION_INSERT,AllTrim(Posicione("AA1",1,xFilial("AA1")+TGZ->TGZ_ATEND,"AA1_NOMTEC")),"")	})
oStrTGZ:SetProperty( "TGZ_DESC"		, MODEL_FIELD_INIT , {|oMOdel| IIf(!oModel:GetOperation()==MODEL_OPERATION_INSERT,AllTrim(Posicione("SR6",1,xFilial("SR6")+TGZ->TGZ_TURNO,"R6_DESC")),"")  	})

oStrTFF:SetProperty( "TFF_PRCVEN", MODEL_FIELD_OBRIGAT, .F. ) // Se esse campo for obrigatório, é impossível vincular um funcionário em um posto de cobertura.
oStrTGY:SetProperty( "TGY_CODTFF", MODEL_FIELD_OBRIGAT, .F. )
oStrTGZ:SetProperty( "TGZ_CODTFF", MODEL_FIELD_OBRIGAT, .F. )

oModel := MPFormModel():New("TECA580E", /*bPreValidacao*/,bPosValidacao,/*bCommit*/,/*bCancel*/ )

oModel:AddFields("TFFMASTER",/*cOwner*/,oStrTFF, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid( "TDXDETAIL", "TFFMASTER", oStrTDX, /*bPreValid*/, /*bPosValid*/)
oModel:SetRelation( "TDXDETAIL", { { "TDX_FILIAL", "xFilial('TDX')" }, { "TDX_CODTDW", "TFF_ESCALA" } }, TDX->(IndexKey(2)) )

oModel:AddGrid( "TGXDETAIL", "TFFMASTER", oStrTGX )
oModel:SetRelation( "TGXDETAIL", { { "TGX_FILIAL", "xFilial('TGX')" }, { "TGX_CODTDW", "TFF_ESCALA" } }, TGX->(IndexKey(2)) )

oModel:AddGrid( "TGYDETAIL", "TDXDETAIL", oStrTGY, bLinePre, {|oMdlTGY,nLine| AT580ePosV(oMdlTGY,nLine,"TGY")}/*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*bLoad*/ )
oModel:SetRelation( "TGYDETAIL", { { "TGY_FILIAL", "xFilial('TGY')" }, { "TGY_ESCALA", "TFF_ESCALA" }, { "TGY_CODTDX", "TDX_COD" }, { "TGY_CODTFF", "TFF_COD" } }, TGY->( IndexKey(1)) )

oModel:AddGrid('TGZDETAIL','TGXDETAIL',oStrTGZ, bLinePre,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*bLoad*/ )
oModel:SetRelation( "TGZDETAIL", { { "TGZ_FILIAL", "xFilial('TGZ')" }, { "TGZ_ESCALA","TFF_ESCALA" }, { "TGZ_CODTDX", "TGX_COD" } , { "TGZ_CODTFF", "TFF_COD"} }, TGZ->( IndexKey(1)) )

oModel:SetDescription(STR0002) // "Relacionamento"

oModel:GetModel('TDXDETAIL'):SetOptional(.T.)
oModel:GetModel('TGXDETAIL'):SetOptional(.T.)
oModel:GetModel('TGYDETAIL'):SetOptional(.T.)
oModel:GetModel('TGZDETAIL'):SetOptional(.T.)

//Desabilita qualquer edição no grid
oModel:GetModel("TDXDETAIL"):SetNoDeleteLine()
oModel:GetModel("TDXDETAIL"):SetNoInsertLine()
oModel:GetModel("TGXDETAIL"):SetNoDeleteLine()
oModel:GetModel("TGXDETAIL"):SetNoInsertLine()
oModel:GetModel("TGXDETAIL"):SetNoUpdateLine()

//Aumenta o numero máximo de linhas
oModel:GetModel("TGYDETAIL"):SetMaxLine(99999)
oModel:GetModel("TGZDETAIL"):SetMaxLine(99999)


If lMV_GSGEHOR .AND. lHasTGYGeH
	oModel:SetActivate( {|oModel| InitDados( oModel ) } )
EndIF

Return(oModel)

//----------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Relacionamentos - Gestão de Escalas 

@Return 	view
@author 	Serviços
@since 		15/05/2014
/*/
//----------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel  := FWLoadModel("TECA580E")  
Local oStrTFF	:= FwFormStruct( 2, "TFF", {|cCpo| AllTrim(cCpo)$"TFF_CONTRT+TFF_PRODUT+TFF_DESCRI+TFF_LOCAL+TFF_ESCALA+TFF_NOMESC+TFF_QTDVEN+TFF_PERINI+TFF_PERFIM" } )
Local oStrTDX := FWFormStruct( 2, "TDX", {|cCpo| !( Alltrim(cCpo)$"TDX_CODTDW#TDX_TIPO#TDX_STATUS#TDX_QUANT" ) })
Local oStrTGX := FWFormStruct( 2, "TGX", {|cCpo| !( Alltrim(cCpo)$"TGX_QUANT" ) } )
Local oStrTGY := FWFormStruct( 2, "TGY", {|cCpo| !AllTrim(cCpo)$"TGY_CODTDX+TGY_ESCALA+TGY_CODTFF" } )
Local oStrTGZ := FWFormStruct( 2, "TGZ", {|cCpo| !AllTrim(cCpo)$"TGZ_CODTDX+TGZ_ESCALA+TGZ_CODTFF" } )
Local lMV_GSGEHOR := SuperGetMV("MV_GSGEHOR",,.F.) .AND. At580EGHor()
Local lHasTGYGeH := (TGY->( ColumnPos('TGY_ENTRA1')) > 0 )

oView := FWFormView():New()
oView:SetModel(oModel)

//Adiciona a rotina de consulta da agenda do atendente
oView:AddUserButton( STR0003, "", {|oView| At580List(oView) } ) //STR0003//"Consulta da Agenda"

//Adiciona a rotina de seleção do atendente
oView:AddUserButton( "Selec. Atend.", "", {|oView| At580Sele(oView) } ) //"Selec. Atend."

//Campo virtual que indicará se o apontamento do material de consumo foi ou não apurado. 
oStrTDX:AddField("TDX_SIT","01","","",{},"BT","",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil) // "Status"

//Campo virtual que indicará se o apontamento do material de consumo foi ou não apurado. 
oStrTGX:AddField("TGX_SIT","01","","",{},"BT","",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil) // "Status"


If lMV_GSGEHOR .AND. lHasTGYGeH
	oStrTDX:AddField("TDX_ENTRA1",Soma1(oStrTDX:GetProperty('TDX_SEQTUR', MVC_VIEW_ORDEM)),"Entrada 1","Entrada 1",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	oStrTDX:AddField("TDX_SAIDA1",Soma1(oStrTDX:GetProperty('TDX_ENTRA1', MVC_VIEW_ORDEM)),"Saida 1","Saida 1",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	
	oStrTDX:AddField("TDX_ENTRA2",Soma1(oStrTDX:GetProperty('TDX_SAIDA1', MVC_VIEW_ORDEM)),"Entrada 2","Entrada 2",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	oStrTDX:AddField("TDX_SAIDA2",Soma1(oStrTDX:GetProperty('TDX_ENTRA2', MVC_VIEW_ORDEM)),"Saida 2","Saida 2",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	
	oStrTDX:AddField("TDX_ENTRA3",Soma1(oStrTDX:GetProperty('TDX_SAIDA2', MVC_VIEW_ORDEM)),"Entrada 3","Entrada 3",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	oStrTDX:AddField("TDX_SAIDA3",Soma1(oStrTDX:GetProperty('TDX_ENTRA3', MVC_VIEW_ORDEM)),"Saida 3","Saida 3",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	
	oStrTDX:AddField("TDX_ENTRA4",Soma1(oStrTDX:GetProperty('TDX_SAIDA3', MVC_VIEW_ORDEM)),"Entrada 4","Entrada 4",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
	oStrTDX:AddField("TDX_SAIDA4",Soma1(oStrTDX:GetProperty('TDX_ENTRA4', MVC_VIEW_ORDEM)),"Saida 4","Saida 4",{},"C","99:99",Nil,Nil,.T.,"",Nil,Nil,Nil,Nil,.T.,Nil)
EndIf

oView:AddField( "VIEW_TFF", oStrTFF, "TFFMASTER" )

oView:AddGrid( "VIEW_TDX", oStrTDX, "TDXDETAIL" )
oView:AddGrid( "VIEW_TGX", oStrTGX, "TGXDETAIL" )
oView:AddGrid( "VIEW_TGY", oStrTGY, "TGYDETAIL" )
oView:AddGrid( "VIEW_TGZ", oStrTGZ, "TGZDETAIL" )

oStrTFF:SetProperty( "*"			  	, MVC_VIEW_CANCHANGE	, .F.  )
oStrTFF:SetProperty( "TFF_CONTRT"	, MVC_VIEW_ORDEM	   	, "01" )
oStrTFF:SetProperty( "TFF_PRODUT"	, MVC_VIEW_ORDEM	   	, "02" )
oStrTFF:SetProperty( "TFF_DESCRI"	, MVC_VIEW_ORDEM	   	, "03" )
oStrTFF:SetProperty( "TFF_LOCAL"	, MVC_VIEW_ORDEM	   	, "04" )
oStrTFF:SetProperty( "TFF_ESCALA"	, MVC_VIEW_ORDEM	   	, "05" )
oStrTFF:SetProperty( "TFF_NOMESC"	, MVC_VIEW_ORDEM	   	, "06" )
oStrTFF:SetProperty( "TFF_QTDVEN"	, MVC_VIEW_ORDEM	   	, "07" )
oStrTFF:SetProperty( "TFF_PERINI"	, MVC_VIEW_ORDEM		, "08" )
oStrTFF:SetProperty( "TFF_PERFIM"	, MVC_VIEW_ORDEM		, "09" )

oStrTGY:SetProperty( "TGY_SEQ"	, MVC_VIEW_CANCHANGE		, .T. )
oStrTGY:SetProperty( "TGY_ATEND", MVC_VIEW_CANCHANGE		, .F. )
oStrTGZ:SetProperty( "TGZ_ATEND", MVC_VIEW_CANCHANGE		, .T. )

If !lMV_GSGEHOR .AND. lHasTGYGeH
	oStrTGY:RemoveField("TGY_ENTRA1")
	oStrTGY:RemoveField("TGY_ENTRA2")
	oStrTGY:RemoveField("TGY_ENTRA3")
	oStrTGY:RemoveField("TGY_ENTRA4")
	
	oStrTGY:RemoveField("TGY_SAIDA1")
	oStrTGY:RemoveField("TGY_SAIDA2")
	oStrTGY:RemoveField("TGY_SAIDA3")
	oStrTGY:RemoveField("TGY_SAIDA4")
EndIf

oView:CreateHorizontalBox( "TELA"    , 23 )
oView:CreateHorizontalBox( "INFERIOR", 77 )

oView:CreateFolder( "ABAS", "INFERIOR" )
oView:AddSheet( "ABAS", "ABA02", STR0004,{|| At580VdFolder(oView:GetFolderActive("ABAS",2))})  // STR0004//"Efetivo"
oView:AddSheet( "ABAS", "ABA03", STR0005,{|| At580VdFolder(oView:GetFolderActive("ABAS",2))})  // STR0005//"Cobertura"

oView:CreateHorizontalBox( "ID_ABA02" , 030, Nil, Nil, "ABAS", "ABA02" ) // Define a área de Efetivo
oView:CreateHorizontalBox( "ID_ABA02A", 070, Nil, Nil, "ABAS", "ABA02" ) // área dos acionais relacionados com Efetivo

oView:CreateHorizontalBox( "ID_ABA03" , 030, Nil, Nil, "ABAS", "ABA03" ) // Define a área de Cobertura
oView:CreateHorizontalBox( "ID_ABA03A", 070, Nil, Nil, "ABAS", "ABA03" )
	
oView:SetOwnerView( "VIEW_TFF", "TELA"      ) 
oView:SetOwnerView( "VIEW_TDX", "ID_ABA02"  )  // Grid Efetivo
oView:SetOwnerView( "VIEW_TGY", "ID_ABA02A" )  // Grid Efetivos TGY

oView:SetOwnerView( "VIEW_TGX", "ID_ABA03"  )  // Grid Cobertura
oView:SetOwnerView( "VIEW_TGZ", "ID_ABA03A" ) //Grid Cobertura TGZ

oView:AddIncrementField( "VIEW_TGY", "TGY_ITEM" )		// Item Incremental do Grid Atendentes
oView:AddIncrementField( "VIEW_TGZ", "TGZ_ITEM" )		// Item Incremental do Grid Atendentes

oView:EnableTitleView( "VIEW_TGZ", STR0007 )  // STR0007//"Cobertura"
oView:EnableTitleView( "VIEW_TGY", STR0006 )  // STR0006//"Efetivo"

//Ação para a condição de pagamento
oView:SetFieldAction( "TGY_ATEND", { |oView,cIDView,cField,xValue| At580EPosLin(oView,cIdView,cField,xValue),oView:Refresh('VIEW_TGY') } )

//Fechar a janela apos a gravação
oView:SetCloseOnOk( {|| .T. } )

Return(oView)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580VdFolder

Verifica qual aba está aberta para posicionar no atendente correto
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580VdFolder(aFolSel)
Local lRet := .T.

If 	aFolSel[1] == 1 //Aba de Efetivo
	cFolder := Upper("EFETIVO")
ElseIf aFolSel[1] == 2 //Aba de Cobertura
	cFolder := Upper("COBERTURA")
EndIf

Return( lRet )


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ETrn

Gatilho do Turno

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ETrn(nPos)

Local cTurno := ""

Default nPos := 0

If nPos > 0
	If nPos == 1
		cTurno := ALLTRIM(POSICIONE("AA1",1,XFILIAL("AA1") + FwFldGet("TGY_ATEND"),"AA1_TURNO"))
	ElseIf nPos == 2
		cTurno := ALLTRIM(POSICIONE("AA1",1,XFILIAL("AA1") + FwFldGet("TGZ_ATEND"),"AA1_TURNO"))
	EndIf
EndIf

Return(cTurno)



//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At580ELeg
Atribui a cor na legenda dos efetivos, conforme a necessidade.

@author  	Serviços
@since 	  	20/06/2014
@version	P12

@return 	cRet: Cor da legenda conforme a configuração do efetivo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ELeg(nPos)

Local cRet	 	:= ""
Local aArea	:= GetArea()

Default nPos := 0

If nPos > 0
	If nPos == 1
		DbSelectArea("TGY")
		TGY->(DbSetOrder(1))//TGY_FILIAL+TGY_ESCALA+TGY_CODTDX+TGY_CODTFF+TGY_ITEM
		
		If TGY->(DbSeek(xFilial("TGY") + TFF->TFF_ESCALA + TDX->TDX_COD + TFF->TFF_COD))
			While TGY->(!Eof()) .And. TGY->TGY_FILIAL == xFilial("TGY") .And. ;
				  	TGY->TGY_ESCALA == TFF->TFF_ESCALA .And. TGY->TGY_CODTDX == TDX->TDX_COD .AND. TGY->TGY_CODTFF == TFF->TFF_COD
					cRet := "BR_VERDE"
			
				TGY->(DbSkip())
			End
		EndIf
	ElseIf nPos == 2
		DbSelectArea("TGZ")
		TGZ->(DbSetOrder(1))//TGZ_FILIAL+TGZ_ESCALA+TGZ_CODTDX+TGZ_CODTFF+TGZ_ITEM 
		
		If TGZ->(DbSeek(xFilial("TGZ") + TFF->TFF_ESCALA + TGX->TGX_COD + TFF->TFF_COD))
			While TGZ->(!Eof()) .And. TGZ->TGZ_FILIAL == xFilial("TGZ") .And. ;
				  	TGZ->TGZ_ESCALA == TFF->TFF_ESCALA .And. TGZ->TGZ_CODTDX == TGX->TGX_COD .And. TGZ->TGZ_CODTFF == TFF->TFF_COD
					cRet := "BR_VERDE"
			
				TGZ->(DbSkip())
			End
		EndIf	
	EndIf	
EndIf

If Empty(cRet)
	cRet := "BR_AMARELO"
EndIf

RestArea(aArea)

Return(cRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At580EGetLE			   
Cria as informações referentes a legenda do grid de efetivos.

@author  	Serviços
@since 	  	20/06/2014
@version 	P12

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580EGetLE()

Local oLegenda := FwLegend():New()

If	lLegend         
	oLegenda:Add( "", "BR_VERDE" , STR0008 			  	)		//STR0008 //"Alocado"
	oLegenda:Add( "", "BR_AMARELO"   , STR0009 					)		//STR0009 //"Não Alocado"
	oLegenda:View()
	DelClassIntf()
EndIf
                                                                                                                                          
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EPosLin

Validação do turno do funcinario

@author 	Serviços
@since 		08/04/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580EPosLin(oView,cIdView,cField,xValue)
Local lRet			:= .T.
Local aArea		:= GetArea()
Local cTurno		:= ""

If Upper(cIdView) == "VIEW_TGY"
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))
	If AA1->(DbSeek(xFilial("AA1") + FwFldGet("TGY_ATEND")))
		cTurno := AA1->AA1_TURNO
	EndIf
	
	If FwFldGet("TDX_TURNO") <> cTurno
		Aviso( STR0011, I18N( STR0012 + ' #1 ' + STR0010 + ' #2 ' ,{ cValToChar( Alltrim(AA1->AA1_NOMTEC) ), cValToChar( FwFldGet("TDX_COD")) } ), {STR0013} , 1 )			   		//" está diferente do que está configurado na escala "//"Atenção"//"O turno do Funcionario "//"OK"
	EndIf
EndIf

RestArea(aArea)

Return(lRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EVdGr
Validação do grupo de atendentes

@author 	Serviços
@since 		15/07/2014
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580EVdGr(oModel)

Local oMdlTFF := oModel:GetModel("TFFMASTER")
Local oMdlTDX := oModel:GetModel("TDXDETAIL")
Local oMdlTGX := oModel:GetModel("TGXDETAIL")
Local oMdlTGY := oModel:GetModel("TGYDETAIL")
Local oMdlTGZ := oModel:GetModel("TGZDETAIL")
Local aQtdAte := {}
Local nPosAte := 0
Local cMsg    := ""
Local lRet		:= .T.

Local nI, nJ, nK

Local dDtFinal

Local lExcede := At680Perm( Nil, __cUserID, "005" )

// Verifica os efetivos
For nI:=1 To oMdlTDX:Length()

	oMdlTDX:GoLine(nI)
			
	If !oMdlTDX:IsDeleted()
		
		aQtdAte := {}
		
		For nJ:=1 To oMdlTGY:Length()	
			oMdlTGY:GoLine(nJ)
			If !oMdlTGY:IsDeleted()
				If !Empty(oMdlTGY:GetValue("TGY_ATEND")) .And. (Empty(oMdlTGY:GetValue("TGY_GRUPO")) .Or. oMdlTGY:GetValue("TGY_GRUPO") == 0)
					cMsg := STR0052	// "Grupo de atendentes não preenchido no grid de efetivos!"				
					lRet := .F.
					Exit
				Else 
					nPosAte := aScan( aQtdAte, { |x| x[1]== oMdlTGY:GetValue("TGY_GRUPO") } )
					If nPosAte == 0					
						aAdd( aQtdAte, { oMdlTGY:GetValue("TGY_GRUPO"), {} } )
						nPosAte := Len(aQtdAte)
					EndIf							
					
					//Se valor estiver em branco ele atribui a data final do contrato TFF_PERFIM
					If !Empty(oMdlTGY:GetValue("TGY_ATEND")) .And. Empty(oMdlTGY:GetValue("TGY_DTFIM"))
						oMdlTGY:SetValue("TGY_DTFIM",oMdlTFF:GetValue("TFF_PERFIM"))		
					EndIf
					
					aAdd( aQtdAte[nPosAte,2], { oMdlTGY:GetValue("TGY_DTINI"), oMdlTGY:GetValue("TGY_DTFIM") } )				 
				EndIf		
			EndIf
		Next nJ
		
		// Verifica a quantidade de atendentes cadastrados
		If lRet .And. Len(aQtdAte) > 0	
			For nK:=1 To Len(aQtdAte)
				aSort( aQtdAte[nK,2],,, { |x,y| x[1]<y[1] } )
				dDtFinal := aQtdAte[nK,2,1,2]
				For nJ:=2 To Len(aQtdAte[nK,2])
					If aQtdAte[nK,2,nJ,1] <= dDtFinal
						lRet := .F.
						cMsg := STR0053 +  AllTrim(Str(aQtdAte[nK,1],3)) // "A quantidade de atendentes excedeu o permitido do grupo "
						Exit
					EndIf 								
					dDtFinal := aQtdAte[nK,2,nJ,2]				
				Next nJ
				If !lRet
					Exit
				EndIf
			Next nK			
			If !lRet
				Exit
			EndIf				
		EndIf
	EndIf
			
Next nI

If lRet .And. Len(aQtdAte) > 0	
	If Len(aQtdAte) > oMdlTFF:GetValue("TFF_QTDVEN")
		lRet := .F.
		cMsg := STR0054 // "A quantidade de atendentes (grupos) ultrapassou o permitido no contrato!"
	EndIf	
EndIf

// Verifica as coberturas
If lRet
	For nI:=1 To oMdlTGX:Length()
	
		oMdlTGX:GoLine(nI)
		
		If Empty(oMdlTGZ:GetValue("TGZ_ATEND")) .And. Empty(oMdlTGZ:GetValue("TGZ_GRUPO"))
			Loop
		EndIf
		
		If !oMdlTGX:IsDeleted()
		
			aQtdAte := {}
							
			For nJ:=1 To oMdlTGZ:Length()		
				oMdlTGZ:GoLine(nJ)
				If !oMdlTGZ:IsDeleted()				
					If oMdlTGZ:Length() == 1 .And. Empty(oMdlTGZ:GetValue("TGZ_ATEND"))
						Exit
					EndIf				
					If Empty(oMdlTGZ:GetValue("TGZ_GRUPO")) .Or. oMdlTGZ:GetValue("TGZ_GRUPO") == 0
						lRet := .F.
						cMsg := STR0055 // "Grupo de atendentes não preenchido no grid de cobertura!"						
						Exit 
					Else 
						nPosAte := aScan( aQtdAte, { |x| x[1]== oMdlTGZ:GetValue("TGZ_GRUPO") } )
						If nPosAte == 0	
							aAdd( aQtdAte, { oMdlTGZ:GetValue("TGZ_GRUPO"), {} } )
							nPosAte := Len(aQtdAte)
						EndIf							
						
						//Se valor estiver em branco ele atribui a data final do contrato TFF_PERFIM
						If Empty(oMdlTGZ:GetValue("TGZ_DTFIM"))
							oMdlTGZ:SetValue("TGZ_DTFIM",oMdlTFF:GetValue("TFF_PERFIM"))		
						EndIf							
						
						aAdd( aQtdAte[nPosAte,2], { oMdlTGZ:GetValue("TGZ_DTINI"), oMdlTGZ:GetValue("TGZ_DTFIM") } )
					EndIf		
				EndIf 	
			Next nJ	
			
			// Verifica a quantidade de atendentes cadastrados
			If lRet .And. Len(aQtdAte) > 0	
				For nK:=1 To Len(aQtdAte)
					aSort( aQtdAte[nK,2],,, { |x,y| x[1]<y[1] } )
					dDtFinal := aQtdAte[nK,2,1,2]
					For nJ:=2 To Len(aQtdAte[nK,2])
						If aQtdAte[nK,2,nJ,1] <= dDtFinal
							lRet := .F.
							cMsg := STR0056 +  AllTrim(Str(aQtdAte[nK,1],3)) // "A quantidade de atendentes excedeu o permitido do grupo "
							Exit
						EndIf 								
						dDtFinal := aQtdAte[nK,2,nJ,2]				
					Next nJ
					If !lRet
						Exit
					EndIf
				Next nK			
				If !lRet
					Exit
				EndIf				
			EndIf			
						
		EndIf
		
	Next nI
	 
EndIf

If lRet .And. Len(aQtdAte) > 0
	If Len(aQtdAte) > oMdlTFF:GetValue("TFF_QTDVEN")
		lRet := .F.
		cMsg := STR0057 // "A quantidade de atendentes (grupos) ultrapassou o permitido no contrato!"
	EndIf	
EndIf

If !lRet .And. !lExcede
	Help(,,"AT580EVDGR",,cMsg,1,0) 
Else
	//Permite alocar excedentes
	If !lRet .And. lExcede
		lRet := .T.
	EndIf
EndIf

Return(lRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580List

Função para consulta da agenda do atendente
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580List(oModel)

Local oDlg			:= Nil								// Dialog Principal
Local aSize		:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local oBrw			:= Nil								// Objeto do Browse
Local oBrwM		:= Nil								// Objeto do Browse
Local aColumns	:= {}								// Array com as colunas para o browse
Local aList		:= {}								// Array com os dados a serem apresentados
Local oColumns	:= Nil
Local lPerg		:= .T.
Local cAtend		:= ""
Local oMdl			:= FwModelActive()

If cFolder == Upper(STR0014)//"EFETIVO"
	cAtend := oMdl:GetModel("TGYDETAIL"):GetValue("TGY_ATEND")
ElseIf cFolder == Upper("COBERTURA")	
	cAtend := oMdl:GetModel("TGZDETAIL"):GetValue("TGZ_ATEND")
EndIf

If Empty(cAtend)
	MsgAlert(STR0015)//"Selecione um atendente para realizar a consulta"
	Return
EndIf
	
//Ativa o Pergunte
lPerg := Pergunte("TECA580E",.T.)

If !lPerg
	Return
Else
	If Empty(MV_PAR01) .Or. Empty(MV_PAR02)
		MsgAlert(STR0016)//"Selecione uma data de inicio e fim para realizar a consulta"
		Return
	ElseIf MV_PAR02 < MV_PAR01
		MsgAlert(STR0017)//"A data de Fim deve ser maior que a data de inicio"
		Return	
	EndIf
EndIf

//Cria o Array para exibição dos dados
MsgRun(STR0019,STR0018,{ || aList := At580EQry(cAtend) }) //"Montando a Agenda do Atendente"//"Aguarde"//"Montando a Agenda do Atendente..."

//Ordena o Array por Data
asort(aList,,, {|x,y| x[4] < y[4] }) 

//Cria a tela para o browse
DEFINE DIALOG oDlg TITLE STR0020 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL //STR0020//"Agenda do Atendente"
	
	DEFINE FWFORMBROWSE oBrw DATA ARRAY ARRAY aList LINE BEGIN 1 OF oDlg
		
		ADD STATUSCOLUMN oColumn DATA &("{ || aList[oBrw:At()][1] }") DOUBLECLICK { |oBrw| At580ELeg1() } OF oBrw
		nCpo := Len(oBrw:aColumns)
		oBrw:aColumns[nCpo]:SetTitle(STR0021)//"Agenda"
		ADD STATUSCOLUMN oColumn DATA &("{ || aList[oBrw:At()][2] }") DOUBLECLICK { |oBrw| At580ELeg2() } OF oBrw
		nCpo := Len(oBrw:aColumns)
		oBrw:aColumns[nCpo]:SetTitle(STR0022)//"Situação"
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][3] }") TITLE STR0023	SIZE 20 PICTURE "@!" 						OF oBrw//"Dia da Semana"
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][4] }") TITLE TxSX3Campo("ABB_DTINI")[1] 	SIZE TamSX3("ABB_DTINI")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][5] }") TITLE TxSX3Campo("ABB_HRINI")[1] 	SIZE TamSX3("ABB_HRINI")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][6] }") TITLE TxSX3Campo("ABB_DTFIM")[1] 	SIZE TamSX3("ABB_DTFIM")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][7] }") TITLE TxSX3Campo("ABB_HRFIM")[1]	SIZE TamSX3("ABB_HRFIM")[1] 	OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][8] }") TITLE TxSX3Campo("ABB_LOCAL")[1]	SIZE TamSX3("ABS_LOCAL")[1]		OF oBrw
		ADD COLUMN oColumns DATA &("{ || aList[oBrw:At()][9] }") TITLE TxSX3Campo("ABS_DESCRI")[1]	SIZE TamSX3("ABS_DESCRI")[1] 	OF oBrw
				
		//Adiciona o Botão para atualizar a consulta
		ADD Button oBtRefresh Title STR0024 Action {|| At580ERefresh(aList,oBrw,cAtend)} Of oBrw //STR0024//"Atualizar"
			
	ACTIVATE FWFORMBROWSE oBrw
		
	
ACTIVATE DIALOG oDlg CENTERED

	
Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EArray

Cria Array com todas as datas do intervalo informado no parametro
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580EArray()
Local aRet  := {}
Local dData 

If !Empty(MV_PAR01) .And. !Empty(MV_PAR02)
	dData := MV_PAR01
	While 	MV_PAR02 >= dData
		AAdd( aRet, { 	"BR_BRANCO",;	 	//Agenda
							"BR_BRANCO" ,; 	 	//Situação
							dData,; 	//Data Inicial
							"",;		//Hora Inicial
							dData,;	//Data Final
							"",;		//Hora Final
							"" ,;		//Local 		
							" " } )	//Descrição do Local
		dData := dData+1
	End
EndIf

Return(aRet)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ERefresh

Cria a lista dos dias para exibição no browse
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580EDia(dData)
Local cData 	:= ""
Local nTipo	:= 0

nTipo := Dow(dData)

Do Case
	Case nTipo == 2
		cData := STR0025//"Segunda-Feira"
	Case nTipo == 3
		cData := STR0026//"Terça-Feira"
	Case nTipo == 4
		cData := STR0027//"Quarta-Feira"
	Case nTipo == 5
		cData := STR0028//"Quinta-Feira"
	Case nTipo == 6
		cData := STR0029//"Sexta-Feira"
	Case nTipo	== 7
		cData := STR0030		//"Sábado"
	Case nTipo == 1
		cData := STR0031		//"Domingo"
EndCase

Return(cData)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ESit
Função que executa a query e seleciona os dados a serem exibidos no browse 

@since		24/04/2014 
@version 	P12

@param		dDtFiltro, Data, data de referência para apuração das situações dos atendentes.
@return 	aList, Array, retorna a lista de atendentes e suas situações para o dia da consulta

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580ESit( dDtFiltro,cAtend )
Local aRet		:= {}
Local cAliasTmp	:= GetNextAlias()
Local cDtUse    := ''
Local cExpWhere := ''
Local lSRAOk    := .T.
Local cSituacao := ''
Local cCorLeg   := ''
Local lDiaTrab  := .F.
Local nPosData  := 0
Local nPosTec   := 0

Default dDtFiltro 	:= dDataBase
Default cAtend		:= ""

If Select("cAlias") > 0 
	(cAliasTmp)->(DbCloseArea())
Endif

cDtUse := DTOS(dDtFiltro)

BeginSql Alias cAliasTmp
	
	COLUMN RF_DATAINI AS DATE
	COLUMN RF_DATINI2 AS DATE
	COLUMN RF_DATINI3 AS DATE
	COLUMN RH_DATABAS AS DATE
	COLUMN RH_DBASEAT AS DATE
	COLUMN R8_DATAINI AS DATE
	COLUMN R8_DATAFIM AS DATE
	
	SELECT DISTINCT
		AA1.AA1_CODTEC
		, AA1.AA1_NOMTEC
		, AA1.R_E_C_N_O_ AA1_RECNO
		, AA1.AA1_FUNCAO
		, COALESCE( SRA.RA_MAT		, ' ' ) RA_MAT
		, COALESCE( SRA.RA_CODFUNC	, ' ' ) RA_CODFUNC
		, COALESCE( SRA.RA_CARGO	, ' ' ) RA_CARGO
		, COALESCE( SRA.R_E_C_N_O_	, 0 ) RA_RECNO
		, COALESCE( SRF.RF_MAT		, ' ' ) RF_MAT
		, COALESCE( SRF.RF_DATAINI	, ' ' ) RF_DATAINI
		, COALESCE( SRF.RF_DFEPRO1	, 0 ) RF_DFEPRO1
		, COALESCE( SRF.RF_DATINI2	, ' ' ) RF_DATINI2
		, COALESCE( SRF.RF_DFEPRO2	, 0 ) RF_DFEPRO2
		, COALESCE( SRF.RF_DATINI3	, ' ' ) RF_DATINI3
		, COALESCE( SRF.RF_DFEPRO3	, 0 ) RF_DFEPRO3
		, COALESCE( SRH.RH_MAT		, ' ' ) RH_MAT
		, COALESCE( SRH.RH_DATABAS	, ' ' ) RH_DATABAS
		, COALESCE( SRH.RH_DBASEAT	, ' ' ) RH_DBASEAT
		, COALESCE( SR8.R8_MAT		, ' ' ) R8_MAT
		, COALESCE( SR8.R8_DATAINI	, ' ' ) R8_DATAINI
		, COALESCE( SR8.R8_DATAFIM	, ' ' ) R8_DATAFIM
		, COALESCE( ABB.ABB_CODTEC	, ' ' ) ABB_CODTEC
	FROM %Table:AA1% AA1 
		LEFT JOIN %Table:SRA% SRA ON SRA.RA_FILIAL=AA1.AA1_FUNFIL AND SRA.RA_MAT=AA1.AA1_CDFUNC AND SRA.D_E_L_E_T_=' '
		
		LEFT JOIN %Table:SRH% SRH ON SRH.RH_FILIAL=%xFilial:SRH% AND SRH.RH_MAT=SRA.RA_MAT AND SRH.D_E_L_E_T_ = ' ' 
			AND %Exp:cDtUse% BETWEEN SRH.RH_DATABAS AND SRH.RH_DBASEAT
		
		LEFT JOIN %Table:SRF% SRF ON SRF.RF_FILIAL=%xFilial:SRF% AND SRF.RF_MAT=SRA.RA_MAT AND SRF.D_E_L_E_T_ = ' '
		
		LEFT JOIN %Table:SR8% SR8 ON SR8.R8_FILIAL=%xFilial:SR8% AND SR8.R8_MAT=SRA.RA_MAT AND SR8.D_E_L_E_T_ = ' ' 
			AND %Exp:cDtUse% BETWEEN SR8.R8_DATAINI AND SR8.R8_DATAFIM

		LEFT JOIN %Table:ABB% ABB ON ABB.ABB_FILIAL=%xFilial:ABB% AND ABB.ABB_CODTEC=AA1.AA1_CODTEC AND ABB.ABB_ATIVO='1' 
			AND ABB.D_E_L_E_T_=' ' AND ABB.ABB_DTINI = %Exp:cDtUse%
		
		LEFT JOIN %Table:AAY% AAY ON AAY.AAY_FILIAL=%xFilial:AAY% AND AAY.AAY_CODTEC=AA1.AA1_CODTEC AND AAY.%NotDel%
		
		LEFT JOIN %Table:AAX% AAX ON AAX.AAX_FILIAL=%xFilial:AAX% AND AAX.AAX_CODEQU=AAY.AAY_CODEQU AND AAX.%NotDel%
		
	WHERE
		AA1.AA1_FILIAL=%xFilial:AA1% AND AA1.AA1_CODTEC=%Exp:cAtend% AND AA1.%NotDel%
	ORDER BY AA1_CODTEC
		
EndSql

DbSelectArea('AA1')
AA1->(DbSetOrder(1)) //RA_FILIAL+RA_MAT

DbSelectArea('SRA')
SRA->(DbSetOrder(1)) //RA_FILIAL+RA_MAT

//----------------------------------------------------------
//  Avalia o retorno da consulta para adicionar ao array de retorno
// e atribuir a situação de cada atendente
While (cAliasTmp)->(!EOF())
	
	cSituacao := '' // caso não identifique o status
	cCorLeg   := ''
	
	//----------------------------------------------
	//  Posiciona nos registros relacionados ao atendente
	// quando existir vínculo com funcionário, ttbm realiza o posicionamento na SRA
	AA1->(DbGoTo((cAliasTmp)->AA1_RECNO))
	
	If ( lSRAOk := !Empty((cAliasTmp)->RA_MAT) )
		SRA->(DbGoTo((cAliasTmp)->RA_RECNO))
	EndIf
	
	//---------------------------------------------
	//  Verifica se é um dia trabalhado
	lDiaTrab := ( lSRAOk .And. TxDiaTrab(dDtFiltro, SRA->RA_TNOTRAB, SRA->RA_SEQTURN, SRA->RA_MAT, SRA->RA_CC) ) .Or. ;
				(!lSRAOk .And. TxDiaTrab(dDtFiltro, AA1->AA1_TURNO, '01') )
	
	If !Empty((cAliasTmp)->RH_MAT) .And. ;  // Exista informação na SRH: Férias processadas
		!Empty((cAliasTmp)->RH_DATABAS) .And. !Empty((cAliasTmp)->RH_DBASEAT) .And. ;  // os campos estejam preenchidos
		( dDtFiltro >= (cAliasTmp)->RH_DATABAS .And. dDtFiltro <= (cAliasTmp)->RH_DBASEAT ) // esteja entre a data inicial e final das férias
		
		cSituacao := STR0032//"Férias Processada"
		cCorLeg   := "BR_PRETO"
	
	ElseIf !Empty((cAliasTmp)->RF_MAT) .And. ;  // Exista informação na SRF
		( !Empty((cAliasTmp)->RF_DATAINI) .Or. !Empty((cAliasTmp)->RF_DATINI2) .Or. !Empty((cAliasTmp)->RF_DATINI3) ) .And.;  // alguma das datas esteja preenchida
		( ( dDtFiltro >= (cAliasTmp)->RF_DATAINI .And. dDtFiltro <= ( (cAliasTmp)->RF_DATAINI + (cAliasTmp)->RF_DFEPRO1 ) ) .Or. ;
		( dDtFiltro >= (cAliasTmp)->RF_DATINI2 .And. dDtFiltro <= ( (cAliasTmp)->RF_DATINI2 + (cAliasTmp)->RF_DFEPRO2 ) ) .Or. ;
		( dDtFiltro >= (cAliasTmp)->RF_DATINI3 .And. dDtFiltro <= ( (cAliasTmp)->RF_DATINI3 + (cAliasTmp)->RF_DFEPRO3 ) ) )  
		// verifica para cada período/saída da programação se a data está entre o período
		
		cSituacao := STR0033//"Férias Programada"
		cCorLeg   := "BR_BRANCO"
	
	ElseIf !Empty((cAliasTmp)->R8_MAT) .And. ;  // Exista informação na SR8
		!Empty((cAliasTmp)->R8_DATAINI) .And. !Empty((cAliasTmp)->R8_DATAFIM) .And. ; // período de afastamento preenchido
		dDtFiltro >= (cAliasTmp)->R8_DATAINI .And. dDtFiltro <= (cAliasTmp)->R8_DATAFIM
		
		cSituacao := STR0034//"Afastamento"
		cCorLeg   := "BR_LARANJA"
		
	ElseIf !lDiaTrab  // não é dia trabalhado?
		cSituacao := STR0035//"Folga"
		cCorLeg   := "BR_AZUL"
		
	
	ElseIf lDiaTrab
		If !Empty((cAliasTmp)->ABB_CODTEC)
			cSituacao := STR0036//"Dia de Trabalho com Agenda"
			cCorLeg   := "BR_VERDE"
		Else
			cSituacao := STR0037//"Dia de Trabalho sem Agenda"
			cCorLeg   := "BR_PINK"
		EndIf
	
	EndIf
	
	//-----------------------------------------
	//  Atenção ao alterar a ordem dos campos
	// para não gerar erro na ordenação do array
	// DIA + CÓDIGO ATENDENTE
	nPosData := 3
	nPosTec := 4
	
	aAdd( aRet, { cCorLeg,;  // Legenda
					cSituacao,;  // Situação
					dDtFiltro,;  // dia da consulta
					(cAliasTmp)->AA1_CODTEC	,; // Código Técnico
					(cAliasTmp)->RA_MAT		,; // Matrícula
					(cAliasTmp)->AA1_NOMTEC	,; // Nome Técnico
					IIF(!Empty((cAliasTmp)->RA_CODFUNC),(cAliasTmp)->RA_CODFUNC,(cAliasTmp)->AA1_FUNCAO)	,; // Função
					(cAliasTmp)->RA_CARGO	; // Cargo
				} )
	
	(cAliasTmp)->(DbSkip())
End

(cAliasTmp)->(DbCloseArea())

//Ordena o array Data+Código Técnico
aSort(aRet,,, {|x,y| DTOS(x[nPosData])+x[nPosTec] < DTOS(y[nPosData])+y[nPosTec]})

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ELeg1
Legenda da Agenda
@since		24/04/2014 
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ELeg1()
Local oLegenda  :=  FWLegend():New() 	// Objeto FwLegend.
                                                  	
oLegenda:Add("","BR_VERDE"		, STR0038) // STR0038//"Agendada"
oLegenda:Add("","BR_AMARELO"	, STR0039) // STR0039//"Atendida"
oLegenda:Add("","BR_BRANCO"		, STR0040) // STR0040//"Sem Agenda"

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190Leg
Legenda da situação do funcionario
@since		24/04/2014 
@version 	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ELeg2()
Local oLegenda  :=  FWLegend():New() 	// Objeto FwLegend.
                                                  	
oLegenda:Add("","BR_VERDE"		, STR0041) 	// STR0041//"Dia de Trabalho com Agenda"
oLegenda:Add("","BR_PRETO"		, STR0042) 	// STR0042//"Férias Processada"
oLegenda:Add("","BR_BRANCO"		, STR0043) 	// STR0043//"Férias Programada"
oLegenda:Add("","BR_LARANJA"	, STR0044) 	// STR0044//"Afastado"
oLegenda:Add("","BR_AZUL"		, STR0045) 	// STR0045//"Folga"
oLegenda:Add("","BR_PINK"		, STR0051) 	//"Dia de Trabalho sem Agenda"
oLegenda:Add("","BR_VERMELHO"	, STR0046) 	// STR0046//"Demitido"

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ERefresh

Atualiza os parametros e atualiza o Browse
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ERefresh(aList,oBrw,cAtend)
Local lPerg		:= .F.
Local lContinua	:= .T.

//Ativa o Pergunte
lPerg := Pergunte("TECA580E",.T.)

If lPerg
	If Empty(MV_PAR01) .Or. Empty(MV_PAR02)
		MsgAlert(STR0047)//"Selecione uma data de inicio e fim para realizar a consulta"
		lContinua := .F.
		Return
	ElseIf MV_PAR02 < MV_PAR01
		MsgAlert(STR0048)//"A data de Fim deve ser maior que a data de inicio"
		lContinua := .F.
		Return	
	EndIf
EndIf

If lContinua
	//Cria o Array para exibição dos dados
	MsgRun(STR0049,STR0050,{ || aList := At580EQry(cAtend) }) //"Montando a Agenda do Atendente"//"Montando a Agenda do Atendente..."//"Aguarde"
		
	//Ordena o Array por Data
	asort(aList,,, {|x,y| x[4] < y[4] }) 
	
	oBrw:SetArray(aList)
	
	oBrw:Refresh(.T.)
EndIf
	
Return Nil

//Verifica se o funcionario está demitido
Static Function At580EDmt(cCod)
Local aRet  	:= {}
Local aArea 	:= GetArea()
Local cAlias	:= GetNextAlias()

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

BeginSQL alias cAlias
	SELECT DISTINCT 
		SRA.RA_MAT,
		SRA.RA_NOME,
		SRA.RA_SITFOLH,
		SRA.RA_DEMISSA
		FROM
			%Table:SRA% SRA
		INNER JOIN 
			%Table:AA1% AA1  
		ON 
			AA1.AA1_FILIAL = %xfilial:AA1% 
		AND 
			AA1.AA1_CDFUNC = SRA.RA_MAT
		AND
      		AA1.AA1_CODTEC = %Exp:cCod%
     	AND 
      		AA1.%NotDel%
		WHERE
			SRA.RA_FILIAL = %xfilial:SRA%
		AND
			SRA.RA_SITFOLH = 'D'
		AND 
			SRA.RA_DEMISSA <> ' '	
		AND
			SRA.%NotDel%
EndSQL

While (cAlias)->(!Eof())
	Aadd(aRet,{.T.,(cAlias)->RA_DEMISSA}) 

(cAlias)->(DbSkip())
				
EndDo

If Empty(aRet)
	Aadd(aRet,{.F.,""})
EndIf

RestArea(aArea)

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EQry

Cria a Query e o array para listagem da agenda
@since		29/11/2013 
@version P11 R9
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At580EQry(cCod)
Local aRet 		:= {}
Local aAgenda		:= {}
Local aDatas		:= {}
Local aArea		:= GetArea()
Local cAlias		:= GetNextAlias()
Local cWhere		:= ""
Local nX			:= 0
Local nY			:= 0
Local aSituação	:= {}
Local aDtDmt								//Data de Demissão

Default cCod := ""

//Monta o Array com o intevalo de datas
aDatas := At580EArray()

//Verifica se o funcionario está demitido
aDtDmt := At580EDmt(cCod)


If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

cWhere := "% ABB.ABB_CODTEC ='" + cCod + "' AND "
cWhere += " ABB.ABB_DTINI  BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' " 
cWhere += " %"

BeginSQL alias cAlias
	SELECT DISTINCT 
				ABB.ABB_CODTEC,
				ABB.ABB_DTINI,
				ABB.ABB_HRINI,
				ABB.ABB_DTFIM,
				ABB.ABB_HRFIM,
				ABB.ABB_CHEGOU,
				ABB.ABB_ATENDE,
				ABB.ABB_IDCFAL,
				ABB.ABB_CODIGO,
				ABB.ABB_ATIVO,
				ABS.ABS_LOCAL,
				ABS.ABS_DESCRI
				FROM
					%Table:ABB% ABB
				INNER JOIN 
					%Table:ABS% ABS  
			       ON 
			       	ABS.ABS_FILIAL = %xfilial:ABS% 
			      	AND 
			      		ABS.ABS_LOCAL = ABB.ABB_LOCAL
			      	AND 
			      		ABS.%NotDel%
				WHERE
					ABB.ABB_FILIAL = %xfilial:ABB%
				AND
					%Exp:cWhere%
				AND
					ABB.%NotDel%
EndSQL

cData := ""

While (cAlias)->(!Eof())
	If (cAlias)->ABB_CHEGOU == "S" .And. (cAlias)->ABB_ATENDE == "1"
		//Monta o Array com as datas da agenda do atendente
		AAdd( aAgenda, { "BR_AMARELO",; //Atendida
						"BR_VERDE",;
						At580EDia(sToD((cAlias)->ABB_DTINI)),;
						sToD((cAlias)->ABB_DTINI),;
						(cAlias)->ABB_HRINI,;
						SToD((cAlias)->ABB_DTFIM),;
						(cAlias)->ABB_HRFIM,;
						(cAlias)->ABS_LOCAL,;
						(cAlias)->ABS_DESCRI,;
						(cAlias)->ABB_CHEGOU,;
						(cAlias)->ABB_ATENDE } )			
	Else
		If !aDtDmt[1][1] //Verifica se o funcionario está demitido
			//Monta o Array com as datas da agenda do atendente
			AAdd( aAgenda, { "BR_VERDE",; //Agendada
							"BR_VERDE",;
							At580EDia(sToD((cAlias)->ABB_DTINI)),;
							sToD((cAlias)->ABB_DTINI),;
							(cAlias)->ABB_HRINI,;
							SToD((cAlias)->ABB_DTFIM),;
							(cAlias)->ABB_HRFIM,;
							(cAlias)->ABS_LOCAL,;
							(cAlias)->ABS_DESCRI,;
							(cAlias)->ABB_CHEGOU,;
							(cAlias)->ABB_ATENDE } )				
		Else
			If aDtDmt[1][2] > (cAlias)->ABB_DTINI 
					//Monta o Array com as datas da agenda do atendente
					AAdd( aAgenda, { "BR_VERDE",; //Agendada
							"BR_VERDE",;
							At580EDia(sToD((cAlias)->ABB_DTINI)),;
							sToD((cAlias)->ABB_DTINI),;
							(cAlias)->ABB_HRINI,;
							SToD((cAlias)->ABB_DTFIM),;
							(cAlias)->ABB_HRFIM,;
							(cAlias)->ABS_LOCAL,;
							(cAlias)->ABS_DESCRI,;
							(cAlias)->ABB_CHEGOU,;
							(cAlias)->ABB_ATENDE } )			
			Else
				//Monta o Array com as datas da agenda do atendente
				AAdd( aAgenda, { "BR_VERDE",; //Agendada
							"BR_VERMELHO",;
							At580EDia(sToD((cAlias)->ABB_DTINI)),;
							sToD((cAlias)->ABB_DTINI),;
							(cAlias)->ABB_HRINI,;
							SToD((cAlias)->ABB_DTFIM),;
							(cAlias)->ABB_HRFIM,;
							(cAlias)->ABS_LOCAL,;
							(cAlias)->ABS_DESCRI,;
							(cAlias)->ABB_CHEGOU,;
							(cAlias)->ABB_ATENDE } )		
			EndIf
		EndIf
	EndIf
	
	(cAlias)->(DbSkip())
				
EndDo

(cAlias)->(DbCloseArea())

//Verifica as data e os status da agenda
If Len(aDatas) > 0
	For nY := 1 To Len(aDatas)
		nX := aScan(aAgenda,{|x| x[4] == aDatas[nY][3]})
		If nX == 0		
			//Verifica se o funcionario está demitido
			If aDtDmt[1][1]
				If SToD(aDtDmt[1][2]) > aDatas[nY][3] 
					aSituacao := At580ESit( aDatas[nY][3], cCod )
					AAdd( aAgenda, { 	"BR_BRANCO",; //"Sem Agenda"
						aSituacao[1][1],;
						At580EDia(aDatas[nY][3]),;
						aDatas[nY][3],;
						"",;
						aDatas[nY][5],;
						"",;
						"",;				
						"" } )
								
				Else
					//Monta o Array com as datas da agenda do atendente
					AAdd( aAgenda, { "BR_BRANCO",; //Agendada
								"BR_VERMELHO",;
								At580EDia(aDatas[nY][3]),;
								aDatas[nY][3],;
								"",;
								aDatas[nY][5],;
								"",;
								"",;				
								"" } )
				EndIf	
			Else
				//Monta o Array com as datas da agenda do atendente
				aSituacao := At580ESit( aDatas[nY][3], cCod )
				AAdd( aAgenda, { 	"BR_BRANCO",; //"Sem Agenda"
						aSituacao[1][1],;
						At580EDia(aDatas[nY][3]),;
						aDatas[nY][3],;
						"",;
						aDatas[nY][5],;
						"",;
						"",;				
						"" } )
				
			
			EndIf
		Else
			//Atualiza situação dos dias com agenda
			aSituacao := At580ESit( aDatas[nY][3], cCod )
			aAgenda[nX][2] := aSituacao[1][1]
		EndIf
		aSituacao := {}
	Next nY
EndIf

aRet := aClone(aAgenda)

RestArea(aArea)

Return(aRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At580EVlDt
Função para validação dos períodos iniciais e finais dos atendentes no posto.

@sample 	At580EVlDt(cModelo,cCpoSelec,cCpoDtIn,cCpoDtFm)

@since		14/07/2014      
@version	P12

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	oModel, Objeto, Model utilizado para a consistencia das informações.
@param  	cModelo, Caracter, nome do modelo de dados principal.
@param  	cCpoSelec, Caracter, nome do campo da data selecionada para validação.
@param  	cCpoDtIn, Caracter, nome do campo da data inicial.
@param  	cCpoDtFm, Caracter, nome do campo da data final.
/*/
//------------------------------------------------------------------------------
Function At580EVlDt(cModelo,cCpoSelec,cCpoDtIn,cCpoDtFm)

Local oModel  := FwModelActive()
Local oMdl		:= oModel:GetModel(cModelo)
Local oMdlTFF := oModel:GetModel("TFFMASTER")
Local lRet		:= .F.

If Right(cCpoSelec,3) == "INI" 

	If Empty(oMdl:GetValue(cCpoDtIn)) .Or.; 
		((DtoS(oMdl:GetValue(cCpoDtIn))>=DtoS(oMdlTFF:GetValue("TFF_PERINI"))) .And. (DtoS(oMdl:GetValue(cCpoDtIn)) <= DtoS(oMdlTFF:GetValue("TFF_PERFIM")))) .Or.; 
		Empty(oMdlTFF:GetValue("TFF_PERFIM"))  	
		lRet := .T.
	EndIf	
		
ElseIf Right(cCpoSelec,3) == "FIM"

	If !Empty(oMdl:GetValue(cCpoDtIn))		
		If DtoS(oMdl:GetValue(cCpoDtFm)) >= DtoS(oMdl:GetValue(cCpoDtIn)) .AND. (DtoS(oMdl:GetValue(cCpoDtFm)) <= DtoS(oMdlTFF:GetValue("TFF_PERFIM") ) .OR. ;
		  Empty(oMdlTFF:GetValue("TFF_PERFIM") ) ) 
			lRet := .T.
		EndIf		
	ElseIf Empty(oMdl:GetValue(cCpoDtFm))	
		lRet := .T.				
	Elseif	Empty(oMdl:GetValue(cCpoDtIn))
		If DtoS(oMdl:GetValue(cCpoDtFm)) >= DtoS(oMdl:GetValue(cCpoDtIn)) .AND. ( DtoS(oMdl:GetValue(cCpoDtFm)) <= DtoS(oMdlTFF:GetValue("TFF_PERFIM") ) .OR. ;
		  Empty(oMdlTFF:GetValue("TFF_PERFIM") ) ) 
			lRet := .T.
		EndIf		
	Endif
EndIf

If !lRet
	Help(,,"AT580VLDDT",,STR0058,1,0) // "Data inicial/final fora do periodo do contrato!"
Else
	If cModelo == "TGYDETAIL"
		//Data final não pode ser menor que a data de ultima alocação	
		If  TGY->(FieldPos("TGY_ULTALO") > 0) .AND. !Empty(oMdl:GetValue(cCpoDtFm)) .AND. oMdl:GetValue(cCpoDtFm) < oMdl:GEtValue("TGY_ULTALO")
			Help(,,"AT580VLDDT",,STR0063,1,0) // "Data final deve ser maior que a data da ultima alocação"
			lRet := .F.
		EndIf 
	EndIf
EndIf

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At580EVlGr
Função para validação do grupo dos atendentes

@sample 	At580EVlGr(cModelo,cCpoSelec)

@since		14/07/2014      
@version	P12

@return 	lRet, Lógico, retorna .T. se data for válida.

@param  	cModelo, Caracter, nome do modelo de dados principal.
@param  	cCpoSelec, Caracter, nome do campo da data selecionada para validação.

/*/
//------------------------------------------------------------------------------
Function At580EVlGr(cModelo,cCpoSelec)

Local oModel  := FwModelActive()
Local oMdl		:= oModel:GetModel(cModelo)
Local oMdlTFF := oModel:GetModel("TFFMASTER")
Local lMovimentar := IsInCallStack("TECA336")
Local lExcedente  := lMovimentar .AND. ValType(M->TW3_SITCOD) <> Nil .And. M->TW3_SITCOD $ SIT_MOV_EXCEDEN + '|' + SIT_MOV_TREINAM
Local lRet		:= .F.

If !Empty(oMdl:GetValue(cCpoSelec))
	If oMdl:GetValue(cCpoSelec) > 0 .And. ;
		(oMdl:GetValue(cCpoSelec) <= oMdlTFF:GetValue("TFF_QTDVEN") .Or. lExcedente)
		lRet := .T. 
	EndIf	
EndIf

If !lRet
	Help(,,"AT580VLDGR",,STR0059 + AllTrim(Str(oMdlTFF:GetValue("TFF_QTDVEN"),3)),1,0) // "O grupo deve ser maior do que 0 e menor do que "
EndIf

Return(lRet)
///------------------------------------------------------------------------------
/*/{Protheus.doc} At580EVlAl

Função para validação Campo Atendente  

@sample 	At580EVlAl(oModel, cAtend)

@since		23/09/2014      
@version	P12

@return 	lRet.

/*/
//------------------------------------------------------------------------------
Function At580EVlAl(oModel, cAtend, dDtIni, dDtFim)
Local lRet 	  	:= .T. 
Local cLocal		:= FWFLDGET("TFF_LOCAL")
Local lMovimentar   := IsInCallStack("TECA336") .Or. IsInCallStack("TECM330")

If Empty (dDtIni)								// Caso TGY_DTINI esteja vazio será atribuido a query TFF_PERINI (data inicio da TFF)
	dDtIni:= FWFLDGET("TFF_PERINI")  
Endif

If Empty (dDtFim)								// Caso TGY_DTFIM esteja vazio será atribuido a query TFF_PERFIM (data inicio da TFF) 
	dDtFim:= FWFLDGET("TFF_PERFIM")
Endif

If !lMovimentar
	If TxExistAloc(cAtend,dDtIni,"00:00",dDtFim,"23:59",Nil ,cLocal)
		Help(,,"At580EVlAl",,STR0060,1,0) // "Não é permitido fazer a ALTERAÇÃO de atendente já Alocado"
		lRet:= .F. 
	Endif
Else
	If cFolder == Upper("COBERTURA")
		If Empty(cAtend)
			cAtend := FwFldGet("TGZ_ATEND")
		Endif

		If TxExistAloc(cAtend,dDtIni,"00:00",dDtFim,"23:59",Nil ,cLocal)
			Help(,,"At580EVlAl",,STR0060,1,0) // "Não é permitido fazer a ALTERAÇÃO de atendente já Alocado"
			lRet:= .F. 
		Endif
	Endif
Endif

If lRet .And. !lMovimentar
	IF cFolder == Upper("EFETIVO")	 
		lRet:= At020VlDtC({oModel:GetValue("TGY_ATEND")})//Alerta para vencimento do curso do atendente	
	ELSE
		lRet:= At020VlDtC({oModel:GetValue("TGZ_ATEND")})//Alerta para vencimento do curso do atendente
	ENDIF
EndIf

Return(lRet)

Function At580EVlDe(oModel, cAction, cAtend)
	Local lRet := .T.
	
	//Valida alocação do atendente ao deletar a linha
	If cAction == "DELETE"			
		If oModel:GetId() == "TGYDETAIL"
			lRet := At580EVlAl(oModel, oModel:GetValue("TGY_ATEND"), oModel:GEtValue("TGY_DTINI"), oModel:GEtValue("TGY_DTFIM"))
		ElseIf oModel:GetId() == "TGZDETAIL"
			lRet := At580EVlAl(oModel, oModel:GetValue("TGZ_ATEND"), oModel:GEtValue("TGZ_DTINI"), oModel:GEtValue("TGZ_DTFIM"))
		EndIf		
	EndIf
	
	
Return lRet

///------------------------------------------------------------------------------
/*/{Protheus.doc} At580TipAlo

Validacao do campo TIPO DE ALOCACAO  

@since		27/07/2015      
@version	P12
@return 	lRet.
/*/
//------------------------------------------------------------------------------

Static Function At580TipAlo()
Local lRet     := .T.
Local aAreaBkp := GetArea()
Local oModel   := FwModelActive()

oModel := oModel:GetModel("TGYDETAIL")

dbSelectArea("ABS")
ABS->(dbSetOrder(1))
If ABS->(dbSeek(xFilial("ABS")+FwFldGet("TFF_LOCAL") ))

	//Valida o tipo de alocacao x Local (reserva tecnica ou nao)
	dbSelectArea("TCU")
	TCU->(dbSetOrder(1))
	If TCU->(dbSeek(xFilial("TCU")+oModel:GetValue("TGY_TIPALO") )) 
		If ((TCU->TCU_RESTEC == "1" .And. ABS->ABS_RESTEC <> "1") .Or. (TCU->TCU_RESTEC <> "1" .And. ABS->ABS_RESTEC == "1"))
			Help(,,"At580EVlAl",,STR0064,1,0) // "Esse local nao e compativel com reserva tecnica"
			lRet := .F.
		EndIf
	Else
		Help(,,"AT580ENOTCU",,STR0069,1,0) //"Tipo de movimentação não existe na tabela TCU"
		lRet := .F.
	EndIf
	
EndIf

RestArea(aAreaBKP)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580Sele

Função para seleção do atendente
@since		09/10/2015 
@version P12.1.8
     
@return lRet, Retorna .T.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580Sele(oModel)

Local aArea		:= GetArea()
Local oMdl		:= FwModelActive()
Local aCarga	:= {}
Local cCodAtend	:= ""
Local cDtIni	:= '' //DTOS(oMdl:GetModel("TGYDETAIL"):GetValue("TGY_DTINI")) 
Local cDtFim	:= '' //DTOS(oMdl:GetModel("TGYDETAIL"):GetValue("TGY_DTFIM"))

IF cFolder == Upper("EFETIVO")
	cDtIni	:= DTOS(oMdl:GetModel("TGYDETAIL"):GetValue("TGY_DTINI"))
	cDtFim	:= DTOS(oMdl:GetModel("TGYDETAIL"):GetValue("TGY_DTFIM"))
ELSE
	cDtIni	:= DTOS(oMdl:GetModel("TGZDETAIL"):GetValue("TGZ_DTINI"))
	cDtFim	:= DTOS(oMdl:GetModel("TGZDETAIL"):GetValue("TGZ_DTFIM"))
ENDIF

IF Empty(cDtIni)
	cDtIni	:= DTOS(oMdl:GetModel("TFFMASTER"):GetValue("TFF_PERINI"))
ENDIF
IF Empty(cDtFim)
	cDtFim	:= DTOS(oMdl:GetModel("TFFMASTER"):GetValue("TFF_PERFIM"))
ENDIF

// Alimenta o vetor da carga
aAdd(aCarga,{/*cCodAtend*/, /*cNrContr*/ ,/*cNrOs*/, cDtIni, "", cDtFim, ""})

// Chama rotina de seleção de atendente
If TECA560( aCarga, @cCodAtend, /*cOrigem*/,/*aCargaRes*/,oMdl:GetModel("TFFMASTER"):GetValue("TFF_COD") )
	IF cFolder == Upper("EFETIVO")
		oMdl:GetModel("TGYDETAIL"):SetValue("TGY_ATEND",cCodAtend)
	ELSE
		oMdl:GetModel("TGZDETAIL"):SetValue("TGZ_ATEND",cCodAtend)
	ENDIF
Endif

RestArea(aArea)

Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EInit

Função para inicializar o atendente
@since		09/10/2015 
@version P12.1.8
     
@return cDesc, Retorna a descrição do atendente
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580EInit(oModel)
Local cDesc	:= ""
Local oMdl	:= FwModelActive()

If !oMdl:GetOperation()==MODEL_OPERATION_INSERT .And. At580ECheck()
	cDesc := AllTrim(Posicione("AA1",1,xFilial("AA1")+TGY->TGY_ATEND,"AA1_NOMTEC"))
Else
	cDesc := ""
EndIf	

Return cDesc

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ETur

Função para inicializar o turno
@since		09/10/2015 
@version P12.1.8
     
@return cDesc, Retorna a descrição do turno
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ETur(oModel)
Local cDesc	:= ""
Local oMdl	:= FwModelActive()

If !oMdl:GetOperation()==MODEL_OPERATION_INSERT .And. lCheck
	cDesc := AllTrim(Posicione("SR6",1,xFilial("SR6")+TGY->TGY_TURNO,"R6_DESC"))
Else
	cDesc := ""
EndIf	 

Return cDesc

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580ECheck

Verifica se a TGY tem ligação com a TFF selecionada
@since		09/10/2015 
@version P12.1.8
     
@return lRet, Retorna .T. se tem ligação com a TFF
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580ECheck()
Local cAliasTmp := GetNextAlias()
Local cCodTFF	:= TFF->TFF_COD

BeginSql Alias cAliasTmp

	COLUMN TGY_DTINI AS DATE
	COLUMN TGY_DTFIM AS DATE

	SELECT TGY.TGY_CODTFF
		FROM %Table:TGY% TGY
	
	WHERE TGY_FILIAL = %xFilial:ABB%
			AND TGY.TGY_CODTFF = %Exp:cCodTFF%
			AND TGY.%NotDel%

EndSql

While (cAliasTmp)->(!Eof())
	lCheck	:= .T.
	(cAliasTmp)->(DbSkip())	
		   
EndDo

(cAliasTmp)->(DbCloseArea())


Return lCheck

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT580eUpdt
@description Função executada na trigger dos campos da TGY
@author       Mateus Boiani
@since        27/08/2018
@param        cField, string, campo que está sendo atualizado (ENTRA1,SAIDA1,etc..)
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AT580eUpdt(cField)
Local oModel := FwModelActive()
Local oModelTGY := oModel:GetModel("TGYDETAIL")
Local oModelTDX := oModel:GetModel("TDXDETAIL")
Local nX
Local cUpdtTGY := "TGY_" + cField
Local cUpdtTDX := "TDX_" + cField

For nX := 1 to oModelTGY:Length()
	oModelTGY:GoLine(nX)
	oModelTGY:SetValue( cUpdtTGY , oModelTDX:GetValue(cUpdtTDX) )
Next

Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT580ePosV
@description PósValid dos grids de horário
@author       Mateus Boiani
@since        27/08/2018
@param        oModelGrd, obj, modelo da grid
@param        nLine, int, número da linha
@param        cTabela, string, tabela da grid (TDX, TGY...)
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AT580ePosV(oModelGrd,nLine,cTabela,lVarMem)
Local lRet 		 := .T.
Local aTurnosMod := ARRAY(4,.F.)
Local aTurnosGrd := ARRAY(4,.F.)
Local aStrTGY	 := ARRAY(4, .F.)
Local aArrHors 	 := Array(4, {})
Local cAux1		 := ""
Local cAux2		 := ""
Local nTotTrab 	 := 0
Local nTotGrd  	 := 0
Local nAux1		 := 0
Local nAux2		 := 0
Local nX
Local lMV_GSGEHOR := SuperGetMV("MV_GSGEHOR",,.F.) .AND. At580EGHor()
Local lHasTGYGeH := (TGY->( ColumnPos('TGY_ENTRA1')) > 0 )
Local nMaxMin	 := SuperGetMV("MV_GSMAXMI",, 0) 
Local nHorAux
Local nViradaTb  := 0
Local nViradaTGY := 0

Default lVarMem := .F.

If lMV_GSGEHOR .AND. lHasTGYGeH

	If lVarMem
		For nX := 1 To 4
			aArrHors[nX] := {  M->&(cTabela + "_ENTRA"+cValTOChar(nX)) , M->&(cTabela + "_SAIDA"+cValTOChar(nX)) }
		Next nX
	Else
		For nX := 1 To 4
			aArrHors[nX]  := { oModelGrd:GetValue(cTabela + "_ENTRA" + cValToChar(nX)), oModelGrd:GetValue(cTabela + "_SAIDA" + cValToChar(nX))}
		Next nX
	EndIf

	For nX := 1 to LEN(aTurnosMod)
		If ( At580bHGet(( "PJ_ENTRA" + cValToChar(nX) )) != 0 .OR. At580bHGet(("PJ_SAIDA" + cValToChar(nX))) != 0 ) .OR.;
				At580bHGet(("PJ_JND" + cValToChar(nX) + "CON")) == 'S'
			aTurnosMod[nX] := .T.
		EndIf
	Next
	
	For nX := 1 to LEN(aTurnosGrd)
		If !EMPTY(Alltrim(STRTRAN( aArrHors[nX][1] , ":"))) .OR.;
				!EMPTY(Alltrim(STRTRAN( aArrHors[nX][2], ":")))
			aTurnosGrd[nX] := .T.
		EndIf

		If !EMPTY(Alltrim(STRTRAN( aArrHors[nX][1], ":"))) .OR.;
				!EMPTY(Alltrim(STRTRAN( aArrHors[nX][2], ":")))
		Endif

		If aTurnosGrd[nX] <> aTurnosMod[nX]
			Help(,,'At580eAddInter',,STR0070+" "+STR0071 + " " + (cTabela + "_ENTRA" + cValToChar(nX)) + " ; " + (cTabela + "_SAIDA" + cValToChar(nX)),1,0, NIL, NIL, NIL, NIL, NIL,;
				{STR0072 + " " + IIF(cTabela == "TDX", STR0073, STR0074)})
			lRet := .F.
			Exit
		EndIf
	Next
	For	nX	:= 1 TO LEN(aSTRTGY)
		If ( At580bHGet(( "PJ_ENTRA" + cValToChar(nX) )) != 0 .OR. At580bHGet(("PJ_SAIDA" + cValToChar(nX))) != 0 )
			If nX <> 4 .AND. (At580bHGet(( "PJ_ENTRA" + cValToChar(nX+1) )) != 0 .OR. At580bHGet(("PJ_SAIDA" + cValToChar(nX+1))) != 0 )
			

				IF DifHor(At580bHGet("PJ_SAIDA" + cValToChar(nX)), At580bHGet("PJ_ENTRA" + cValToChar(nX +1))) <> DifHor(VAL(Alltrim(STRTRAN(aArrHors[nX][2], ":","."))) ,;
																			VAL(Alltrim(STRTRAN(aArrHors[nX+1][1], ":","."))))
					lRet := .F.
					Help( " ", 1, "DifHor", Nil, STR0093, 1 ) // "Intervalo inserido é diferente do intervalo cadastrado na tabela de horário padrão"
				EndIf
			EndiF
		EndIf
	Next nX
	
	If lRet
		For nX := 1 To 4
			If aArrHors[nX][1] > aArrHors[nX][2] .OR. (nX < 4 .AND. aTurnosMod[nX+1] .AND. aArrHors[nX][2] > aArrHors[nX+1][1] )
				nViradaTGY := nX
			EndIf
			If At580bHGet(( "PJ_ENTRA" + cValToChar(nX) )) > At580bHGet("PJ_SAIDA" +;
			 		cValToChar(nX)) .OR. (nX < 4 .AND. aTurnosMod[nX+1] .AND. At580bHGet("PJ_SAIDA" + cValToChar(nX)) > At580bHGet(( "PJ_ENTRA" + cValToChar(nX+1) )) )
				nViradaTb := nX
				If At580bHGet("PJ_SAIDA" + cValToChar(nX)) > At580bHGet(( "PJ_ENTRA" + cValToChar(nX+1)))
					nAux1 := nX
					nAux2 := nX + 1
				Else
					nAux1 := nX + 1
					nAux2 := nX 
				EndIf
			EndIf
		Next nX
		If nViradaTb <> nViradaTGY
			Help(" ", 1, "VIRADATGY",,;
				STR0099,; // "A virada de dia não pode ocorrer em lugar diferente da escala padrão."
				1,0, NIL, NIL, NIL, NIL, NIL,;
				{IIF(nAux2 < nAux1, STR0094 + STR0100 + cValToChar(nAux2) + "'" + STR0101 + STR0097 + cValToChar(nAux1) + "'",;
				  STR0094 + STR0097 + cValToChar(nAux1) + "'" + STR0101 + STR0100 + cValToChar(nAux2) + "'")}) // "Deve ocorrer entre: " ## "'Hora Ini" ## "'Hora Fim"			
			lRet := .F.
		EndIf
	EndIf
	
	If lRet .AND. nMaxMin <> 0
		nMaxMIn := Min2Hrs(nMaxMin)
		nHorAux	:= VAL(Alltrim(STRTRAN(aArrHors[1][1], ":",".")))
		nAux1 := SomaHoras(nMaxMin, At580bHGet("PJ_ENTRA1"))
		nAux2 := SubHoras( At580bHGet("PJ_ENTRA1"),nMaxMin)
		
		If nAux1 >= 24
			nAux1 := 23.59
		Else 
			If length(cValtoChar(nAux2)) < 5
				cAux1 := "0"
			EndIf
		Endif 
		
		If nAux2 < 0
			nAux2 := 00.00
		EndIf
		
		If (nHorAux > nAux1) .OR. (nHorAux < nAux2)
			lRet	:= .F.
			If length(cValtoChar(nAux2)) < 5
				cAux2 := "0"
			EndIf
			Help(" ", 1, "MV_GSMAXMI",,;
				STR0095,;
				1,0, NIL, NIL, NIL, NIL, NIL,;
				{STR0098 + STRTRAN(cValToChar(nAux1), ".", ":") + cAux1 + STR0101 + STR0096 + STRTRAN(cValToChar(nAux2), ".", ":") + cAux2 }) // "Intervalo inserido não é permitido pois ultrapassa o limite inserido no parametro 'MV_GSMAXMI'. ## valor máximo: " ## " valor minimo: " ## " e "
		EndIF
	EndIf
	
	If lRet
		For nX := 1 to 4
			If ( !EMPTY(Alltrim(STRTRAN( aArrHors[nX][2], ":"))) .AND.;
					EMPTY(Alltrim(STRTRAN( aArrHors[nX][1], ":"))) ) .OR.;
						( EMPTY(Alltrim(STRTRAN( aArrHors[nX][2], ":"))) .AND.;
							!EMPTY(Alltrim(STRTRAN( aArrHors[nX][1], ":"))) )
				lRet := .F.
				Help(,,'At580eFaltaHora',,STR0076+" "+STR0071 + " " + (cTabela + "_ENTRA" + cValToChar(nX)) + " ; " + (cTabela + "_SAIDA" + cValToChar(nX)),1,0, NIL, NIL, NIL, NIL, NIL,;
				{STR0072 + " " + IIF(cTabela == "TDX", STR0073, STR0074)})
				Exit
			EndIf
		Next
	EndIf
	
	If lRet
		nTotTrab := At580bHGet("PJ_HRTOTAL")
		nTotGrd  := TotHoras(At580bHGet("PJ_TURNO"),;
						VAL(Alltrim(STRTRAN(aArrHors[1][1], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[1][2], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[2][1], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[2][2], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[3][1], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[3][2], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[4][1], ":","."))),;
						VAL(Alltrim(STRTRAN(aArrHors[4][2], ":","."))),;
						At580bHGet("PJ_JND1CON"),;
						At580bHGet("PJ_JND2CON"),;
						At580bHGet("PJ_JND3CON"),;
						At580bHGet("PJ_JND4CON"),;
						At580bHGet("PJ_INTERV1"),;
						At580bHGet("PJ_INTERV2"),;
						At580bHGet("PJ_INTERV3");
						)
		If nTotTrab <> nTotGrd
			lRet := .F.
			Help(,,'At580eQtdHoras',,;
				STR0078+" "+;
				cValToChar(nTotTrab) + " " + STR0079+ " " + STR0080 + " " + cValToChar(nTotGrd) + " " + STR0079,1,0, NIL, NIL, NIL, NIL, NIL,;
				{STR0072 + " " + IIF(cTabela == "TDX", STR0073, STR0074)})
		EndIf
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EGHor
@description Função de Get/Set da variavel static lGesHora
@author       Mateus Boiani
@since        27/08/2018
@param        lSetValue, bool, valor que será atribuido para a variavel
@return       lGesHora, bool, valor atualizado da variavel
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580EGHor(lSetValue)
If VALTYPE(lSetValue) == 'L'
	lGesHora := lSetValue
EndIf
Return lGesHora

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
@description Função executada no SetActivate do modelo
@author       Mateus Boiani
@since        27/08/2018
@param        oModel, obj, modelo que será alterado
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function InitDados(oModel)
Local oMdlTDX	:= oModel:GetModel("TDXDETAIL")
Local oMdlTGY	:= oModel:GetModel("TGYDETAIL")
Local nX
Local nY
Local nK

If oModel:GetOperation() == MODEL_OPERATION_UPDATE .AND. VALTYPE( (At580bHash()) ) == 'O'
	For nX := 1 to oMdlTDX:Length()
		oMdlTDX:GoLine(nX)
		For nK := 1 To 4
			If ( At580bHGet(( "PJ_ENTRA" + cValToChar(nK) )) != 0 .OR. At580bHGet(("PJ_SAIDA" + cValToChar(nK))) != 0 ) .OR.;
					At580bHGet(("PJ_JND" + cValToChar(nK) + "CON")) == 'S'
					
				oMdlTDX:LoadValue(("TDX_ENTRA"+ cValToChar(nK) ) ,TxValToHor(At580bHGet(("PJ_ENTRA"+ cValToChar(nK)))))	
				oMdlTDX:LoadValue(("TDX_SAIDA"+ cValToChar(nK) ) ,TxValToHor(At580bHGet(("PJ_SAIDA"+ cValToChar(nK)))))
			EndIf
		Next
	Next
	oMdlTDX:GoLine(1)
EndIf

Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TxValToHor
@description Converte a hora salva na SPJ em horário string
Exemplo:
	8     -> "08:00"
	10    -> "10:00"
	10,2  -> "10:20"
	12,34 -> "12:34"
@author       Mateus Boiani
@since        27/08/2018
@param        nVal, int, valor do horário salvo na SPJ
@return       cRet, String, valor em hora no format HH:MM
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TxValToHor(nVal)
Local cRet := Alltrim(cValToChar(nVal))
If nVal < 10 
	cRet := "0" + cRet
EndIf
If AT(".",cRet) > 0 .AND. LEN(cRet) == 4
	cRet := cRet + "0"
EndIf
If AT(".",cRet) == 0
	cRet := cRet + ".00"
EndIf
Return STRTRAN(cRet,".",":")
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TotHoras
@description Similar a função fHrsTrabGat do PONXFUN.PRX, porém recebe por parâmetros os dados da SPJ
ara o cálculo total das horas
@author       Mateus Boiani
@since        27/08/2018
@param        cTurno, string, código do turno (PJ_TURNO)
@param        nE1, int, horário de entrada 1 (PJ_ENTRA1)
@param        nS1, int, horário de saída 1 (PJ_SAIDA1)
@param        nE2, int, horário de entrada 2 (PJ_ENTRA2)
@param        nS2, int, horário de saída 2 (PJ_SAIDA2)
@param        nE3, int, horário de entrada 3 (PJ_ENTRA3)
@param        nS3, int, horário de saída 3 (PJ_SAIDA3)
@param        nE4, int, horário de entrada 4 (PJ_ENTRA4)
@param        nS4, int, horário de saída 4 (PJ_SAIDA4)
@param        cJn1, string, jornada contínua 1 (PJ_JND1CON)
@param        cJn2, string, jornada contínua 2 (PJ_JND2CON)
@param        cJn3, string, jornada contínua 3 (PJ_JND3CON)
@param        cJn4, string, jornada contínua 4 (PJ_JND4CON)
@param        cI1c, string, indica se o intervalo 1 soma no total de horas (PJ_INTERV1)
@param        cI2c, string, indica se o intervalo 2 soma no total de horas (PJ_INTERV2)
@param        cI3c, string, indica se o intervalo 3 soma no total de horas (PJ_INTERV3)

@return       nRet, int, total de horas cálculadas
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function TotHoras(cTurno,nE1,nS1,nE2,nS2,nE3,nS3,nE4,nS4,cJn1,cJn2,cJn3,cJn4,cI1c,cI2c,cI3c, aHorasI)
Local nRet := 0
Local aArea := GetArea()
Local lHnotTab := .F.
Local lHnotTbI := .F.
Local nIniHnot := 0
Local nFimHnot := 0
Local nMinHnot := 0
Local dE1 := dDataBase
Local dS1	:= Ctod('//')
Local dE2	:= Ctod('//')
Local dS2	:= Ctod('//')
Local dE3	:= Ctod('//')
Local dS3	:= Ctod('//')
Local dE4	:= Ctod('//')
Local dS4	:= Ctod('//')

Local nI1 := 0
Local nI2 := 0
Local nI3 := 0
Local nHr1 := 0
Local nHr2 := 0
Local nHr3 := 0
Local nHr4 := 0

Default nE1 := 0
Default nS1 := 0
Default nE2 := 0
Default nS2 := 0
Default nE3 := 0
Default nS3 := 0
Default nE4 := 0
Default nS4 := 0

Default cJn1 := ""
Default cJn2 := ""
Default cJn3 := ""
Default cJn4 := ""

Default cI1c := ""
Default cI2c := ""
Default cI3c := ""
Default aHorasI := Array(3, 0)

DbSelectArea("SR6")
DbSetOrder(1)

If MsSeek(xFilial("SR6") + cTurno)
	lHnotTab	:= ( SR6->R6_HNOTTAB == "S" )
	lHnotTbI	:= ( SR6->R6_HNOTTBI == "S" )
	nIniHnot	:= SR6->R6_INIHNOT
	nFimHnot	:= SR6->R6_FIMHNOT
	nMinHnot	:= SR6->R6_MINHNOT
	
	dS1		:= IF( nS1 >= nE1 , dE1 , dE1 + 1 )
	dS1		:= IF( nS1 >= nE1 .and. cJn1 == "S", dS1 + 1 , dS1 )
	dE2		:= IF( nE2 >= nS1 , dS1 , dS1 + 1 )
	dS2		:= IF( nS2 >= nE2 , dE2 , dE2 + 1 )
	dS2		:= IF( nS2 >= nE2 .and. cJn2 == "S", dS2 + 1 , dS2 )
	dE3		:= IF( nE3 >= nS2 , dS2 , dS2 + 1 )
	dS3		:= IF( nS3 >= nE3 , dE3 , dE3 + 1 )
	dS3		:= IF( nS3 >= nE3 .and. cJn3 == "S", dS3 + 1 , dS3 )
	dE4		:= IF( nE4 >= nS3 , dS3 , dS3 + 1 )
	dS4		:= IF( nS4 >= nE4 , dE4 , dE4 + 1 )
	dS4		:= IF( nS4 >= nE4 .and. cJn4 == "S", dS4 + 1 , dS4 )
	
	nHr1 := (__TimeSum(__TimeSum(fCalHoras( dE1 , nE1 , dS1 , nS1 , NIL , NIL , lHnotTab , dE1 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	nHr2 := (__TimeSum(__TimeSum(fCalHoras( dE2 , nE2 , dS2 , nS2 , NIL , NIL , lHnotTab , dE2 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	nHr3 := (__TimeSum(__TimeSum(fCalHoras( dE3 , nE3 , dS3 , nS3 , NIL , NIL , lHnotTab , dE3 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	nHr4 := (__TimeSum(__TimeSum(fCalHoras( dE4 , nE4 , dS4 , nS4 , NIL , NIL , lHnotTab , dE4 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	
	If cI1c == "S"
		nI1 := (__TimeSum(__TimeSum(fCalHoras( dS1 , nS1 , dE2 , nE2 , NIL , NIL , lHnotTbI , dE1 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	EndIf
	
	If cI2c == "S"
		nI2 := (__TimeSum(__TimeSum(fCalHoras( dS2 , nS2 , dE3 , nE3 , NIL , NIL , lHnotTbI , dE2 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	EndIf
	
	If cI3c == "S"
		nI3 := (__TimeSum(__TimeSum(fCalHoras( dS3 , nS3 , dE4 , nE4 , NIL , NIL , lHnotTbI , dE3 , NIL , nIniHnot , nFimHnot , nMinHnot ), 0 ), 0) )
	EndIf
	
	nRet := nI1+nI2+nI3+nHr1+nHr2+nHr3+nHr4
	
	aHorasI[01] := nI1
	aHorasI[02] := nI2
	aHorasI[03] := nI3

EndIf

RestArea( aArea )
Return(__TimeSum(__TimeSum( nRet, 0 ), 0) )
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580eWhen
@description Função utilizada no When dos campos de Hora Entrada / Saída
@author       Mateus Boiani
@since        27/08/2018
@param        cNro, string, utilizado para definir qual campo de entrada/saída o when será criado

@return       lRet, bool, se permite alteração
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580eWhen(cNro)
Local lRet := (( At580bHGet(( "PJ_ENTRA" + cNro )) != 0 .OR. At580bHGet(("PJ_SAIDA" + cNro)) != 0 ) .OR.;
					At580bHGet(("PJ_JND" + cNro + "CON")) == 'S')
Return lRet
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At580EHor
@description Gatilho executado quando o campo de Atendente é preenchido
@author       Mateus Boiani
@since        27/08/2018
@return       cRet, strng vazia
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At580EHor()
Local cRet := ""
Local nX
Local oMdl   := FwModelActive()

For nX := 1 to 4
	If !EMPTY(STRTRAN(oMdl:GetModel("TDXDETAIL"):GetValue(("TDX_ENTRA" + cValToChar(nX))),":")) .AND.;
			EMPTY(STRTRAN( oMdl:GetModel("TGYDETAIL"):GetValue(("TGY_ENTRA" + cValToChar(nX))), ":"))
		oMdl:GetModel("TGYDETAIL"):SetValue(("TGY_ENTRA" + cValToChar(nX)),oMdl:GetModel("TDXDETAIL"):GetValue(("TDX_ENTRA" + cValToChar(nX))))
	EndIf
	If !EMPTY(STRTRAN(oMdl:GetModel("TDXDETAIL"):GetValue(("TDX_SAIDA" + cValToChar(nX))),":")) .AND.;
			EMPTY(STRTRAN( oMdl:GetModel("TGYDETAIL"):GetValue(("TGY_SAIDA" + cValToChar(nX))), ":"))
		oMdl:GetModel("TGYDETAIL"):SetValue(("TGY_SAIDA" + cValToChar(nX)),oMdl:GetModel("TDXDETAIL"):GetValue(("TDX_SAIDA" + cValToChar(nX))))
	EndIf
Next

Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} DifHor
@description Retorna a diferença de horario, apartir de da saida e a proxima entrada
@author      augusto.albuquerque
@since        25/07/2019
@param 		nHoraI - Saida
@param		nHoraF - Entrada
@return       nRet - Diferença
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function DifHor(nHoraI, nHoraF)
Local nRet := 0

If nHoraI > nHoraF
	nHoraF += 24
EndIF
nRet := nHoraF - nHoraI
Return nRet
