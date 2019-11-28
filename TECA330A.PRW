#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PONCALEN.CH"
#INCLUDE "TECA330A.CH"

#DEFINE _ZZXGRUPO	1
#DEFINE _ZZXDATA	2
#DEFINE _ZZXSEMANA	3
#DEFINE _ZZXENTRADA	4
#DEFINE _ZZXSAIDA	5
#DEFINE _ZZXATEND 	6
#DEFINE _ZZXNOME  	7
#DEFINE _ZZXSITALO  8
#DEFINE _ZZXTIPO	9
#DEFINE _ZZXCODABB	10
#DEFINE _ZZXATEAGE	11
#DEFINE _ZZXTURNO 	12
#DEFINE _ZZXSEQ   	13

#DEFINE _ULTALOC_KEYTGY		1
#DEFINE _ULTALOC_DATA		2
#DEFINE _ULTALOC_SEQ		3
#DEFINE _ULTALOC_ITEMTGY	4
#DEFINE _ULTALOC_GRUPO		5
#DEFINE _ULTALOC_LINHA		6
#DEFINE _ULTALOC_PREV		6
#DEFINE _ULTALOC_ATEND		7

#DEFINE _TDV_DTREF		1
#DEFINE _TDV_TURNO		2
#DEFINE _TDV_TPEXT		3
#DEFINE _TDV_TPEXTN		4
#DEFINE _TDV_NONHOR		5
#DEFINE _TDV_CODREF		6
#DEFINE _TDV_INSREP		7
#DEFINE _TDV_HRMEN		8
#DEFINE _TDV_HRMAI		9
#DEFINE _TDV_FERIAD		10
#DEFINE _TDV_FTPEXT		11
#DEFINE _TDV_FEXTN		12
#DEFINE _TDV_FEXTN		13
#DEFINE _TDV_FERSAI		14
#DEFINE _TDV_FSTPEX		15
#DEFINE _TDV_FSEXTN		16
#DEFINE _TDV_INTVL1		17
#DEFINE _TDV_INTVL2		18
#DEFINE _TDV_INTVL3		19
#DEFINE _TDV_PREV		19


STATIC aFilGrp := {}
STATIC aFilAte := {}
STATIC aAtend  := {}
STATIC lLegend := .T.
STATIC nGrpFil := 0
STATIC cAteFil  := ""
STATIC nTamCdAte := TAMSX3("AA1_CODTEC")[1]

STATIC aCfltHead	:= {'AA1_FILIAL','AA1_CODTEC','AA1_NOMTEC','ABB_DTINI','ABB_HRINI','ABB_DTFIM',;
						'ABB_HRFIM','RA_SITFOLH','RA_DEMISSA','RF_DATAINI','RF_DFEPRO1','RF_DATINI2',;
						'RF_DFEPRO2','RF_DATINI3','RF_DFEPRO3','R8_DATAINI','R8_DATAFIM','RH_DATABAS',;
						'RH_DBASEAT'}
STATIC aCfltAtnd	:= {}

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Model - Alocação por escala

@Return 	nil
@author	Serviços
@since 		03/07/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel

Local oStruTFF := FWFormStruct(1,"TFF")
Local oStruTGY := FWFormStruct(1,"TGY")
Local oStruZZX := FWFormModelStruct():New()
Local bLoad    := { || At330AStru( .T. ) }
Local bCommit  := { |oModel| At330ACmt(oModel) }
Local bLinePre := { |oMdlG,nLine,cAcao,cCampo| PreLinZZX(oMdlG, nLine, cAcao, cCampo, .T.) }
Local bLinePos := { |oMdlG,nLine,cAcao,cCampo| PosLinZZX(oMdlG, nLine, cAcao, cCampo) }
Local bPosVal  := { |oModel| At330APosZZX(oModel) }
Local bPos330Val:={ |oModel| At330AVal(oModel) }
Local aAux     := {}	

nGrpFil := 0
cAteFil := ""

oStruZZX:AddTable("ZZX",{},STR0001) // "Efetivos"

// Altera as estruturas da tabela para montar a tela
At330AStru( .F., oStruTFF, "TFF", .T. )
At330AStru( .F., oStruTGY, "TGY", .T. )                    		
At330AStru( .F., oStruZZX, "ZZX", .T. )

aAux := FwStruTrigger("ZZX_ATEND","ZZX_NOME","AA1->AA1_NOMTEC",.T.,"AA1",1,;
'xFilial("AA1")+FwFldGet("ZZX_ATEND")')
oStruZZX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

oStruZZX:SetProperty( "ZZX_ENTRADA", MODEL_FIELD_VALID, { |oModel| At330AVldInf(oModel,"ZZX_ENTRADA") } )
oStruZZX:SetProperty( "ZZX_SAIDA"  , MODEL_FIELD_VALID, { |oModel| At330AVldInf(oModel,"ZZX_SAIDA")   } )
oStruZZX:SetProperty( "ZZX_ATEND"  , MODEL_FIELD_VALID, { |oModel| At330AVldInf(oModel,"ZZX_ATEND")   } )
oStruZZX:SetProperty( "ZZX_TIPO"   , MODEL_FIELD_VALID, { |oModel| At330AVldInf(oModel,"ZZX_TIPO")    } )

oStruTGY:SetProperty( "TGY_CODTFF", MODEL_FIELD_OBRIGAT, .F. )
oStruTFF:SetProperty( "TFF_PRCVEN", MODEL_FIELD_OBRIGAT, .F. ) // Se esse campo for obrigatório, é impossível vincular um funcionário em um posto de cobertura.

oModel := MPFormModel():New("TECA330A", /*bPreValidacao*/,bPos330Val, bCommit, /*bCancel*/ )

oModel:AddFields("TFFMASTER",/*cOwner*/,oStruTFF, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid( "TGYDETAIL", "TFFMASTER", oStruTGY, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*bLoad*/ )
oModel:AddGrid( "ZZXDETAIL", "TFFMASTER", oStruZZX, bLinePre, bLinePos, /*bPreVal*/, bPosVal, bLoad )

oModel:SetDescription(STR0002) // "Alocacao por escala"

oModel:GetModel("ZZXDETAIL"):SetOptional(.T.)

//Aumenta o numero máximo de linhas
oModel:GetModel("TGYDETAIL"):SetMaxLine(99999)

oModel:SetVldActivate( {|oModel| At330AVld(oModel)} ) 
oModel:SetActivate( {|oModel| InitDados( oModel ) } )


Return(oModel)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
View - Alocação por escala

@Return 	view
@author 	Serviços
@since 		04/07/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel := FWLoadModel("TECA330A")

Local oStruTFF := FwFormStruct( 2, "TFF", {|cCpo| AllTrim(cCpo)$"TFF_CONTRT+TFF_PRODUT+TFF_DESCRI+TFF_LOCAL+TFF_ESCALA+TFF_NOMESC" } )
Local oStruTGY := FwFormStruct( 2, "TGY", {|cCpo| AllTrim(cCpo)$"TGY_TURNO+TGY_DESC+TGY_SEQ+TGY_ATEND+TGY_NOME+TGY_DTINI+TGY_DTFIM+TGY_GRUPO+TGY_ULTALO+TGY_TIPALO" } )
Local oStruZZX := FWFormViewStruct():New()

At330AStru( .F., oStruTFF, "TFF", .F. )
At330AStru( .F., oStruTGY, "TGY", .F. )
At330AStru( .F., oStruZZX, "ZZX", .F. )     		
					
oStruTFF:SetProperty( "*", MVC_VIEW_CANCHANGE, .F. )
oStruTGY:SetProperty( "*", MVC_VIEW_CANCHANGE, .F. )		
oStruTGY:SetProperty( "TGYSTATUS", MVC_VIEW_CANCHANGE, .T. )	//Legenda: Conflito Atendente

oStruZZX:SetProperty( "ZZX_ENTRADA", MVC_VIEW_CANCHANGE, .T. )
oStruZZX:SetProperty( "ZZX_SAIDA"  , MVC_VIEW_CANCHANGE, .T. )
oStruZZX:SetProperty( "ZZX_ATEND"  , MVC_VIEW_CANCHANGE, .T. )
oStruZZX:SetProperty( "ZZX_TIPO"   , MVC_VIEW_CANCHANGE, .T. )

// Legenda Alocacao por Escala														
oStruZZX:SetProperty( "ZZX_SITABB" , MVC_VIEW_CANCHANGE, .T. )
oStruZZX:SetProperty( "ZZX_SITALO" , MVC_VIEW_CANCHANGE, .T. )														
														
oView := FWFormView():New()
oView:SetModel( oModel )

oView:SetDescription( STR0002 ) // "Alocacao por escala"
oView:SetCloseOnOk({|| .T. } )

oView:AddField("TFF_CABEC", oStruTFF, "TFFMASTER" )
oView:AddGrid( "TGY_GRID" , oStruTGY, "TGYDETAIL" )
oView:AddGrid( "ZZX_GRID" , oStruZZX, "ZZXDETAIL" )

//--------------------------------------
//		Cria os Box's
//--------------------------------------
oView:CreateHorizontalBox( "TOP"   , 22 )  
oView:CreateHorizontalBox( "MIDDLE", 25 )  
oView:CreateHorizontalBox( "FILDWN", 15 )
oView:CreateHorizontalBox( "DOWN"	, 38 )

oView:AddOtherObject("FIL_MESC", {|oPanel,oView| At330AFil(oPanel,oView) })  

oView:AddUserButton( STR0003, "", {|oView| At330AEsc(oView)   }, Nil, Nil, Nil ) // "Visualizar Escala"
oView:AddUserButton( STR0004, "", {|oView| At330ATotHor(oView)}, Nil, Nil, Nil ) // "Horas de Alocação"
oView:AddUserButton( STR0069, "", {|oView| At330Desaloc(oView)}, Nil, Nil, Nil ) // "Remoção de Agenda"
oView:AddUserButton( STR0078, "", {|oView| At330ADtCfl(oView) }, Nil, Nil, Nil ) // "Detalhar Conflito"
oView:AddUserButton( STR0090, "", {|oView| At330MntAge(oView) }, Nil, Nil, Nil ) // "Manut. Agenda"

//--------------------------------------
//		Associa os componentes ao Box
//--------------------------------------
oView:SetOwnerView( "TFF_CABEC", "TOP"   ) 
oView:SetOwnerView( "TGY_GRID", "MIDDLE" )
oView:SetOwnerView( "FIL_MESC", "FILDWN" )
oView:SetOwnerView( "ZZX_GRID", "DOWN" )

oView:EnableTitleView( "TGY_GRID", STR0005 ) 			// "Atendentes da escala"
oView:EnableTitleView( "FIL_MESC", STR0006 ) 			// "Agenda"

Return(oView)


/*/{Protheus.doc} At330AVld
Pre validação para a ativação do model

@since 06/03/2015
@version 1.0
@param oModel, objeto, Model
@return lRet

/*/
Static Function At330AVld(oModel)
Local lRet := .T.
If MV_PAR01 >= TFF->TFF_PERINI .AND. (MV_PAR02 <= TFF->TFF_PERFIM .OR. Empty(TFF->TFF_PERFIM))
	lRet := .T.
Else
	Help(,,"At330AVld",,STR0074 + " ("+DTOC(TFF->TFF_PERINI)+" - "+DTOC(TFF->TFF_PERFIM)+")",1,0) // "Periodo de alocação inicial e/ou final fora do periodo do contrato!"
	lRet := .F.
EndIf

//verificar se o local / posto esta encerrado
If empty(TFF->TFF_ENCE) .OR. TFF->TFF_ENCE <> '1' 
	lRet := .T.
Else
	Help(,,"At330AVld",,STR0088,1,0) // "Posto Encerrado, não poderá gerar novas agendas" 
	lRet := .F.
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados()
Inicializa as informações da visualização da escala

@sample 	InitDados()

@param  	oModel, Objeto, objeto geral do model que será alterado

@author 	Serviços
@since 		09/06/2014
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function InitDados(oModel)

Local oMdlTFF  	:= oModel:GetModel("TFFMASTER")
Local oMdlTGY  	:= oModel:GetModel("TGYDETAIL")
Local oMdlZZX  	:= oModel:GetModel("ZZXDETAIL")
Local dDataIni 	:= MV_PAR01
Local dDataFim 	:= MV_PAR02
Local cApeAge 	:= MV_PAR03
Local cApeFol 	:= MV_PAR04
Local aAteEsc   	:= {}
Local aAteEfe    	:= {}
Local aAteCob    	:= {}
Local aAteAge    	:= {}
Local nPos    	:= 0
Local lAgenda    	:= .F.
Local lDemis		:= .F.
Local lAfast		:= .F.
Local lFerias		:= .F.
Local lCursoVenc	:= .F.
Local aCnflt		:= nil
Local dDtIni		:= CToD('')
Local dDtFin		:= CToD('')
Local nI, lRetCalend, cCalend, cEscala, cCodTFF, cContrato, cFilTFF
Local cTipoRest 	:=""
Local cTpResLoc 	:=""
Local cTpResCli 	:=""
Local lGesHr	:= SuperGetMV('MV_GSGEHOR',,.F.) .And. at330ColHR()   

// Cabecalho da alocacao 
oMdlTFF:SetValue( "TFF_DATINI", MV_PAR01 )
oMdlTFF:SetValue( "TFF_DATFIM", MV_PAR02 )
oMdlTFF:SetValue( "TFF_DSCABS", Posicione( "ABS", 1, xFilial("ABS")+oMdlTFF:GetValue("TFF_LOCAL"), "ABS_DESCRI" ) )
oMdlTFF:SetValue( "TFF_DESCRI", Left( Posicione( "SB1", 1, xFilial("SB1")+oMdlTFF:GetValue("TFF_PRODUT"), "B1_DESC" ), 30 ) )
oMdlTFF:SetValue( "TFF_NOMESC", Posicione( "TDW", 1, xFilial("TDW")+oMdlTFF:GetValue("TFF_ESCALA"), "TDW_DESC" ) )

aAtend  := {}
aFilAte := {}
aFilGrp := {}

// Grid de atendentes da escala
aFilGrp := { STR0009 } // "Todos"
aFilAte := { STR0009 } // "Todos"

MsgRun(STR0007, STR0008,; //"Gerando lista dos atendentes da escala..."#"Processando" 
{ || aAteEsc := At330AAtend( oMdlTFF:GetValue("TFF_COD"), oMdlTFF:GetValue("TFF_ESCALA"), MV_PAR01, MV_PAR02 ) } )
	
oMdlZZX:SetNoInsertLine(.F.)
oMdlTGY:SetNoInsertLine(.F.)
oMdlTGY:SetNoDeleteLine(.F.)

// Ordena a lista dos atendentes
aSort( aAteEsc, Nil, Nil, { |x,y| AllTrim(Str(x[1]))+x[3]+x[5]+DtoS(x[8])<AllTrim(Str(y[1]))+y[3]+y[5]+DtoS(y[8]) } ) 

For nI:=1 To Len(aAteEsc)

	If nI > 1
		oMdlTGY:AddLine()
	EndIf	
	
	oMdlTGY:LoadValue( "TGY_GRUPO"	, aAteEsc[nI,1] )
	oMdlTGY:LoadValue( "TGY_TIPO"	, aAteEsc[nI,2] )
	oMdlTGY:LoadValue( "TGY_TURNO"	, aAteEsc[nI,3] )
	oMdlTGY:LoadValue( "TGY_DESC"	, aAteEsc[nI,4] )
	oMdlTGY:LoadValue( "TGY_SEQ"	, aAteEsc[nI,5] )
	oMdlTGY:LoadValue( "TGY_ATEND" 	, aAteEsc[nI,6] )
	oMdlTGY:LoadValue( "TGY_NOME"	, aAteEsc[nI,7] )	
	If !Empty(aAteEsc[nI,8])
		oMdlTGY:LoadValue( "TGY_DTINI"	, aAteEsc[nI,8] )
	EndIf
	If !Empty(aAteEsc[nI,9])
		oMdlTGY:LoadValue( "TGY_DTFIM"	, aAteEsc[nI,9] )
	EndIf

	// Consulta Possíveis conflitos do atendente atual
	// Se a data oMdlTGY:GetValue("TGY_DTINI") for branco pegar a data do parâmetro
	If Empty(oMdlTGY:GetValue("TGY_DTINI")) 
		dDtIni := MV_PAR01
	Else
		dDtIni := Max(oMdlTGY:GetValue("TGY_DTINI"),MV_PAR01)
	EndIf
	
	If Empty(oMdlTGY:GetValue("TGY_DTFIM")) 
		dDtFin := MV_PAR02
	Else
		dDtFin := Min(oMdlTGY:GetValue("TGY_DTFIM"),MV_PAR02)
	EndIf
	oMdlTGY:LoadValue( "TGY_ULTALO"	, aAteEsc[nI,14] )
	oMdlTGY:LoadValue( "TGY_TIPALO"	, aAteEsc[nI,15] )
			
	// Consulta e Atualiza o Status: Conflito Atendente
	aCnflt := ChkCfltAlc(dDtIni, dDtFin, oMdlTGY:GetValue("TGY_ATEND"))
	lDemis	:= aCnflt[1]
	lAfast	:= aCnflt[2]
	lFerias:= aCnflt[3]
	lCursoVenc  := !At020VlDtC({oMdlTGY:GetValue("TGY_ATEND")},.F.)//Alerta para vencimento do curso do atendente
	cTpResLoc:=at012ResLoc(oMdlTGY:GetValue("TGY_ATEND"),dDtIni,dDtFin,oMdlTFF:GetValue("TFF_LOCAL"))
	If cTpResLoc == "0"
		cTpResCli:=at012ResCli(oMdlTGY:GetValue("TGY_ATEND"),dDtIni,dDtFin,oMdlTFF:GetValue("TFF_LOCAL"))
		cTipoRest:=cTpResCli
	Else
		cTipoRest:=cTpResLoc	
	Endif
	oMdlTGY:LoadValue( "TGYSTATUS"	, At330ALgGS(lDemis,lAfast,lFerias,lCursoVenc,cTipoRest) )
	
	If aAteEsc[nI,2] == "Efetivo" 
		nPos := aScan( aAteEfe, { |x|	x[1] == aAteEsc[nI,3] .And. x[2] == aAteEsc[nI,5] .And.	x[3] == aAteEsc[nI,12] } )//TDX_TURNO//TGY_SEQ//TDX_COD

		If nPos == 0
			aAdd( aAteEfe, { aAteEsc[nI,3], aAteEsc[nI,5], aAteEsc[nI,12], {} } )
			nPos := Len(aAteEfe)
		EndIf

		If !lGesHr
			aAdd( aAteEfe[nPos,4], {	aAteEsc[nI,1],;//TGY_GRUPO
			 							aAteEsc[nI,6],;//TGY_ATEND
										aAteEsc[nI,8],;//TGY_DTINI
										aAteEsc[nI,9],;//TGY_DTFIM
										aAteEsc[nI,11],;//TGY_ITEM
										aAteEsc[nI,14]} )//TGY_ULTALO				
		Else
			aAdd( aAteEfe[nPos,4], {	aAteEsc[nI,1],;//TGY_GRUPO
			 							aAteEsc[nI,6],;//TGY_ATEND
										aAteEsc[nI,8],;//TGY_DTINI
										aAteEsc[nI,9],;//TGY_DTFIM
										aAteEsc[nI,11],;//TGY_ITEM
										aAteEsc[nI,14],;//TGY_ULTALO										
										aAteEsc[nI,15],;
										aAteEsc[nI,16]}) //Array com a gestão dos horarios																													
		EndIf

	Else // Cobertura
		nPos := aScan( aAteCob, { |x| x[1] == aAteEsc[nI,10] .And. x[2] == aAteEsc[nI,11] } )
		If nPos == 0
			aAdd( aAteCob, { aAteEsc[nI,10], aAteEsc[nI,11], {} } )
			nPos := Len(aAteCob)
		EndIf
		aAdd( aAteCob[nPos,3], {	aAteEsc[nI,1], aAteEsc[nI,6],; 
									aAteEsc[nI,8], aAteEsc[nI,9] } )			
	EndIf		

Next nI



cEscala 	:= oMdlTFF:GetValue("TFF_ESCALA")
cCalend 	:= oMdlTFF:GetValue("TFF_CALEND")
cCodTFF 	:= oMdlTFF:GetValue("TFF_COD")
cContrato 	:= oMdlTFF:GetValue("TFF_CONTRT")

// Carrega a Filial da Conf. Recursos Humanos
cFilTFF := oMdlTFF:GetValue("TFF_FILIAL")

// Grid da agenda dos atendentes
MsgRun(STR0011, STR0008,;	// "Gerando agenda dos atendentes da escala selecionados..."#"Processando"
{ || aAteAge := At330AAgAt( aAteEfe, aAteCob, dDataIni, dDataFim, cEscala, cCalend, cCodTFF, cFilTFF ) } )

MsgRun(STR0012, STR0008,;	// "Gerando agenda dos atendentes fora da escala selecionados..."#"Processando"
{ || At330AAtEsp( @aAteAge, cCodTFF, cContrato, dDataIni, dDataFim, cFilTFF ) } )

MsgRun(STR0013, STR0008,;	// "Alimentando a lista de agenda dos atendentes selecionados..."#"Processando"
{ || At330AZZX( oModel, aAteAge, cApeAge, cApeFol ) } ) 

oMdlZZX:SetNoInsertLine(.T.)
oMdlTGY:SetNoInsertLine(.T.)
oMdlTGY:SetNoDeleteLine(.T.)

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ABtn
Criação do botão para as acoes da alocacao

@sample 	At330ABtn(oPanel)

@param		oPanel - Painel onde deverá ser criado e exibido o botão
	
@return	Nil 
@author	Serviços
@since		04/07/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330ABtn( oPanel, cTipo )

Local oButton

Local oModel  := FwModelActive()
Local cEscala := oModel:GetModel("TFFMASTER"):GetValue("TFF_ESCALA")
Local cTitulo := If( cTipo == "1", STR0003, STR0014 ) // "Vis. Escala" # "Montar Escala"

@ 000, 000 Button oButton Prompt cTitulo Of oPanel Size 060, 012 Pixel 
oButton:Align := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
oButton:bAction := { || At330AEsc( cEscala, cTipo ) }

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AEsc
Criação do botão para as acoes da alocacao

@sample 	At330AEsc( cEscala, cTipo )

@param		oModel - Model que contem a informação da escala
@param		cTipo - Tipo do processo 1 = Visualizar / 2 = Montar
	
@return	Nil 
@author	Serviços
@since		07/07/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330AEsc( oModel )

Local lConfirm

Local aArea   := GetArea()
Local cEscala := oModel:GetModel("TFFMASTER"):GetValue("TFF_ESCALA") 

dbSelectArea("TDW")
TDW->(dbSetOrder(1)) //TDW_FILIAL+TDW_COD

If TDW->(dbSeek(xFilial("TDW")+cEscala))	
	lConfirm := ( FWExecView( STR0015,"VIEWDEF.TECA580", MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // "Visualização da Escala" 
								{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
EndIf

RestArea( aArea )

Return(.T.)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AAtend
Retorna a lista de atendentes configurados na escala

@sample 	At330AAtend( cEscala, dDatIni, dDAtFim )

@param		cCodTFF - Código do recurso humano para a escala
@param		cEscala - Código da escala para gerar a lista
@param		dDatIni - Data Inicial para verificacao dos atendentes
@param		dDatFim - Data Final para verificacao dos atendentes
@param		nQtdVen - Quantidade vendida no orcamento de servicos
	
@return	aRet - Array com as informacoes dos atendentes da escala
 
@author	Serviços
@since		08/07/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330AAtend( cCodTFF, cEscala, dDatIni, dDAtFim, cCodAtend, lAteCob )

Local aRet 	  := {}
Local aAtendEsc := {}
Local aAteFil     := {}
Local cAliasEfe := GetNextAlias()
Local cAliasCob := GetNextAlias()
Local aSeqs		  := {} //Controle para sequencia do turno
Local cChvTGY    := ""
Local cChvTGZ    := ""
Local cTGY_ATEND	:= Space(TamSx3("TGY_ATEND")[1])
Local lGesHr		:= SuperGetMV('MV_GSGEHOR',,.F.) .And. at330ColHR()  

DEFAULT cCodAtend := ""
Default lAteCob   := .F.

If !Empty(cCodAtend)
	If lAteCob
		cChvTGY := "%%"
		cChvTGZ := "%AND TGZ.TGZ_ATEND = '"+cCodAtend+"'%"
		cChvTGZ := "%AA1.AA1_CODTEC = '"+cCodAtend+"' AND%"
	Else
		cChvTGY := "%AND TGY.TGY_ATEND = '"+cCodAtend+"'%"
		cChvTGZ := "%AA1.AA1_CODTEC = TGZ.TGZ_ATEND AND%"
	EndIf
Else
	cChvTGY := "%%"
	cChvTGZ := "%AA1.AA1_CODTEC = TGZ.TGZ_ATEND AND%"
EndIf

// Efetivos
If !lGesHr
	BeginSql Alias cAliasEfe
		COLUMN TGY_DTINI AS DATE
		COLUMN TGY_DTFIM AS DATE
		SELECT 
			TDX.TDX_COD,TGY.TGY_ITEM, TDX.TDX_TURNO, SR6.R6_DESC, TGY.TGY_SEQ, TGY.TGY_ULTALO, 
			TDX.TDX_TIPO, TGY.TGY_GRUPO, TGY.TGY_ATEND, 
			AA1.AA1_NOMTEC, TGY.TGY_DTINI, TGY.TGY_DTFIM, TGY.TGY_TIPALO
		FROM 
			%table:TDW% TDW 
		JOIN %table:TDX% TDX ON
			TDX.TDX_FILIAL = %xFilial:TDX% AND 
			TDX.TDX_CODTDW = TDW.TDW_COD AND 
			TDX.%NotDel%
		JOIN %table:TGY% TGY ON
			TGY.TGY_FILIAL = %xFilial:TGY% AND 
			TGY.TGY_CODTDX = TDX.TDX_COD AND
			TGY.%NotDel%
			%Exp:cChvTGY%
		LEFT JOIN %table:SR6% SR6 ON 
			SR6.R6_FILIAL = %xFilial:SR6% AND 
			SR6.R6_TURNO = TDX.TDX_TURNO AND
			SR6.%NotDel%
		LEFT JOIN %table:AA1% AA1 ON
			AA1.AA1_FILIAL = %xFilial:AA1% AND 
			AA1.AA1_CODTEC = TGY.TGY_ATEND AND
			AA1.%NotDel%
		WHERE 
			TDW.TDW_FILIAL = %xFilial:TDW% AND 
			TDW.TDW_COD = %Exp:cEscala% AND
			TGY.TGY_CODTFF = %Exp:cCodTFF% AND
			((TGY.TGY_DTINI BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%) OR
			(TGY.TGY_DTFIM <> %exp:Space(8)% AND 
			TGY.TGY_DTFIM BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%) OR
			(TGY.TGY_DTINI < %Exp:dDatIni% AND 
			(TGY.TGY_DTFIM=%exp:Space(8)% OR TGY.TGY_DTFIM > %Exp:dDatFim%))) AND 
			TDW.%NotDel%
		GROUP BY 
			TDX.TDX_COD, TDX.TDX_TURNO, SR6.R6_DESC, TGY.TGY_SEQ, TGY.TGY_ULTALO,
			TDX.TDX_TIPO, TGY.TGY_ITEM, TGY.TGY_GRUPO, TGY.TGY_ATEND, 
			AA1.AA1_NOMTEC, TGY.TGY_DTINI, TGY.TGY_DTFIM, TGY.TGY_TIPALO
	EndSql
Else
	BeginSql Alias cAliasEfe
		COLUMN TGY_DTINI AS DATE
		COLUMN TGY_DTFIM AS DATE
		SELECT 
			TDX.TDX_COD,TGY.TGY_ITEM, TDX.TDX_TURNO, SR6.R6_DESC, TGY.TGY_SEQ, TGY.TGY_ULTALO, 
			TDX.TDX_TIPO, TGY.TGY_GRUPO, TGY.TGY_ATEND, 
			AA1.AA1_NOMTEC, TGY.TGY_DTINI, TGY.TGY_DTFIM, TGY.TGY_TIPALO, TGY.TGY_ENTRA1, TGY.TGY_SAIDA1, TGY.TGY_ENTRA2, TGY.TGY_SAIDA2,
			TGY.TGY_ENTRA3, TGY.TGY_SAIDA3, TGY.TGY_ENTRA4, TGY.TGY_SAIDA4 		
		FROM 
			%table:TDW% TDW 
		JOIN %table:TDX% TDX ON
			TDX.TDX_FILIAL = %xFilial:TDX% AND 
			TDX.TDX_CODTDW = TDW.TDW_COD AND 
			TDX.%NotDel%
		JOIN %table:TGY% TGY ON
			TGY.TGY_FILIAL = %xFilial:TGY% AND 
			TGY.TGY_CODTDX = TDX.TDX_COD AND
			TGY.%NotDel%
			%Exp:cChvTGY%
		LEFT JOIN %table:SR6% SR6 ON 
			SR6.R6_FILIAL = %xFilial:SR6% AND 
			SR6.R6_TURNO = TDX.TDX_TURNO AND
			SR6.%NotDel%
		LEFT JOIN %table:AA1% AA1 ON
			AA1.AA1_FILIAL = %xFilial:AA1% AND 
			AA1.AA1_CODTEC = TGY.TGY_ATEND AND
			AA1.%NotDel%
		WHERE 
			TDW.TDW_FILIAL = %xFilial:TDW% AND 
			TDW.TDW_COD = %Exp:cEscala% AND
			TGY.TGY_CODTFF = %Exp:cCodTFF% AND
			TGY.TGY_ATEND <> %exp:cTGY_ATEND% AND
			((TGY.TGY_DTINI BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%) OR
			(TGY.TGY_DTFIM <> %exp:Space(8)% AND 
			TGY.TGY_DTFIM BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%) OR
			(TGY.TGY_DTINI < %Exp:dDatIni% AND 
			(TGY.TGY_DTFIM=%exp:Space(8)% OR TGY.TGY_DTFIM > %Exp:dDatFim%))) AND 
			TDW.%NotDel%
		GROUP BY 
			TDX.TDX_COD, TDX.TDX_TURNO, SR6.R6_DESC, TGY.TGY_SEQ, TGY.TGY_ULTALO,
			TDX.TDX_TIPO, TGY.TGY_ITEM, TGY.TGY_GRUPO, TGY.TGY_ATEND, 
			AA1.AA1_NOMTEC, TGY.TGY_DTINI, TGY.TGY_DTFIM, TGY.TGY_TIPALO, TGY.TGY_ENTRA1, TGY.TGY_SAIDA1, TGY.TGY_ENTRA2, TGY.TGY_SAIDA2,
			TGY.TGY_ENTRA3, TGY.TGY_SAIDA3, TGY.TGY_ENTRA4, TGY.TGY_SAIDA4 		
	 
	EndSql
	
	
EndIf

While (cAliasEfe)->(!Eof())

	If !lGesHr
		aAdd( aAtendEsc, { (cAliasEfe)->TGY_GRUPO,;
							 X3Combo("TDX_TIPO",(cAliasEfe)->TDX_TIPO),;
							 (cAliasEfe)->TDX_TURNO,;
							 (cAliasEfe)->R6_DESC,;
							 (cAliasEfe)->TGY_SEQ,;
							 (cAliasEfe)->TGY_ATEND,;
							 (cAliasEfe)->AA1_NOMTEC,;
							 (cAliasEfe)->TGY_DTINI,;
							 (cAliasEfe)->TGY_DTFIM,;
							 (cAliasEfe)->TDX_TIPO,;
							 (cAliasEfe)->TGY_ITEM,;
							 (cAliasEfe)->TDX_COD,;
							  .T.,;
							  STOD((cAliasEfe)->TGY_ULTALO),;
							 (cAliasEfe)->TGY_TIPALO} )			
	Else
		aAdd( aAtendEsc, { (cAliasEfe)->TGY_GRUPO,;
							 X3Combo("TDX_TIPO",(cAliasEfe)->TDX_TIPO),;
							 (cAliasEfe)->TDX_TURNO,;
							 (cAliasEfe)->R6_DESC,;
							 (cAliasEfe)->TGY_SEQ,;
							 (cAliasEfe)->TGY_ATEND,;
							 (cAliasEfe)->AA1_NOMTEC,;
							 (cAliasEfe)->TGY_DTINI,;
							 (cAliasEfe)->TGY_DTFIM,;
							 (cAliasEfe)->TDX_TIPO,;
							 (cAliasEfe)->TGY_ITEM,;
							 (cAliasEfe)->TDX_COD,;
							  .T.,;
							  STOD((cAliasEfe)->TGY_ULTALO),;
							 (cAliasEfe)->TGY_TIPALO,;
							 {{(cAliasEfe)->TGY_ENTRA1,;
							 (cAliasEfe)->TGY_SAIDA1},;
							 {(cAliasEfe)->TGY_ENTRA2,;
							 (cAliasEfe)->TGY_SAIDA2},;
							 {(cAliasEfe)->TGY_ENTRA3,;
							 (cAliasEfe)->TGY_SAIDA3},;
							 {(cAliasEfe)->TGY_ENTRA4,;
							 (cAliasEfe)->TGY_SAIDA4}}} )
		
		
	EndIf				

	If aScan(aFilGrp,Str((cAliasEfe)->TGY_GRUPO,3)) == 0
		aAdd( aFilGrp, Str((cAliasEfe)->TGY_GRUPO,3) )
	EndIf	
	
	If aScan(aFilAte,	(cAliasEfe)->TGY_ATEND+" - "+(cAliasEfe)->AA1_NOMTEC ) == 0
		aAdd( aFilAte,(cAliasEfe)->TGY_ATEND+" - "+(cAliasEfe)->AA1_NOMTEC )	
	EndIf	

	(cAliasEfe)->(dbSkip())
 
EndDo

// Cobertura
BeginSql Alias cAliasCob
	COLUMN TGZ_DTINI AS DATE
	COLUMN TGZ_DTFIM AS DATE
	SELECT 
		TGX.TGX_TIPO, TGX.TGX_ITEM, TGZ.TGZ_GRUPO, TGZ.TGZ_ATEND, 
		AA1.AA1_NOMTEC, TGZ.TGZ_DTINI, TGZ.TGZ_DTFIM
	FROM 
		%table:TDW% TDW 
	JOIN %table:TGX% TGX ON
		TGX.TGX_FILIAL = %xFilial:TGX% AND 
		TGX.TGX_CODTDW = TDW.TDW_COD AND 
		TGX.%NotDel%
	JOIN %table:TGZ% TGZ ON
		TGZ.TGZ_FILIAL = %xFilial:TGZ% AND 
		TGZ.TGZ_CODTDX = TGX.TGX_COD AND 
		TGZ.%NotDel%
	LEFT JOIN %table:AA1% AA1 ON
		AA1.AA1_FILIAL = %xFilial:AA1% AND 
		%Exp:cChvTGZ%
		AA1.%NotDel%
	WHERE 
		TDW.TDW_FILIAL = %xFilial:TDW% AND 
		TDW.TDW_COD = %Exp:cEscala% AND
		TGZ.TGZ_CODTFF = %Exp:cCodTFF% AND
		((TGZ.TGZ_DTINI BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%) OR
		(TGZ.TGZ_DTFIM <> %exp:Space(8)% AND 
		TGZ.TGZ_DTFIM BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%) OR
		(TGZ.TGZ_DTINI < %Exp:dDatIni% AND 
		(TGZ.TGZ_DTFIM=%exp:Space(8)% OR TGZ.TGZ_DTFIM > %Exp:dDatFim%))) AND				 
		TDW.%NotDel%	
	GROUP BY 
		TGX.TGX_TIPO, TGX.TGX_ITEM, TGZ.TGZ_GRUPO, TGZ.TGZ_ATEND, 
		AA1.AA1_NOMTEC, TGZ.TGZ_DTINI, TGZ.TGZ_DTFIM
 
EndSql

While (cAliasCob)->(!Eof())

	aAdd( aAtendEsc, { (cAliasCob)->TGZ_GRUPO,;
						 X3Combo("TGX_TIPO",(cAliasCob)->TGX_TIPO),;
						 "",;
						 "",;
						 "",;
						 (cAliasCob)->TGZ_ATEND,;
						 (cAliasCob)->AA1_NOMTEC,;
						 (cAliasCob)->TGZ_DTINI,;
						 (cAliasCob)->TGZ_DTFIM,;
						 (cAliasCob)->TGX_TIPO,;
						 (cAliasCob)->TGX_ITEM,;
						 "",;
						  .T.,;
						  STOD(""),;
						  "" } )
						 
	If aScan(aFilGrp,Str((cAliasCob)->TGZ_GRUPO,3)) == 0
		aAdd( aFilGrp, Str((cAliasCob)->TGZ_GRUPO,3) )
	EndIf	
		
	If aScan(aFilAte,	(cAliasCob)->TGZ_ATEND + " - " + (cAliasCob)->AA1_NOMTEC ) == 0
		aAdd( aFilAte,(cAliasCob)->TGZ_ATEND + " - " + (cAliasCob)->AA1_NOMTEC )	
	EndIf		
	
	(cAliasCob)->(dbSkip())
EndDo

aSort( aFilAte  , 2, Nil, { |x,y| x < y } )
aSort( aAtendEsc, Nil, Nil, { |x,y| x[1]<y[1] .And. x[3]+x[5]<y[3]+y[5] .And. DtoS(x[8])<DtoS(y[8]) } )

aRet := aAtendEsc

(cAliasEfe)->(dbCloseArea())
(cAliasCob)->(dbCloseArea())

Return(aRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AAtEsp
Retorna a lista de atendentes alocados fora da escala

@sample 	At330AAtEsp( aAteEfe, cCodTFF, cContrato )

@param		aAteEfe   - Array com os atendentes da escala
@param		cCodTFF   - Código do recurso humano para o filtro das alocações
@param		cContrato - Código do contrato para o filtro das alocações
 
@author	Serviços
@since		05/08/2014       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330AAtEsp( aAteEfe, cCodTFF, cContrato, dLimIni, dLimFim, cFilTFF )

Local cDscTip   := ""
Local nLenAte   := 0
Local cAliasABB := GetNextAlias()
Local aLimMai	:= {STOD(""), 0}
Local aLimMen	:= {STOD(""), 0}
Local nSerial	:= 0
Local lSum444 := TDV->(FieldPos("TDV_FERSAI")) > 0 .AND. TDV->(FieldPos("TDV_FSTPEX")) > 0 .AND. TDV->(FieldPos("TDV_FSEXTN")) > 0 // Verificação de campos para sumula 444
Local cCampos := If(lSum444,"%, TDV_FERSAI, TDV_FSTPEX, TDV_FSEXTN%", "%%")

Default cFilTFF := xFilial("TFF", cFilAnt )

// Atendentes fora da escala
BeginSql Alias cAliasABB	
		
	SELECT 
		ABB.ABB_DTINI, ABB.ABB_DTFIM, ABB.ABB_HRINI, 	ABB.ABB_HRFIM, 
		ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABB.ABB_CODIGO, ABB.ABB_ATENDE, ABB.ABB_MANUT,
		TDV.TDV_CODABB, TDV.TDV_DTREF, TDV.TDV_TURNO, TDV.TDV_SEQTRN, 
		TDV.TDV_TPEXT, TDV.TDV_TPEXTN,	TDV.TDV_NONHOR, TDV.TDV_CODREF, 
		TDV.TDV_INSREP, TDV.TDV_TPDIA, TDV.TDV_HRMEN, TDV.TDV_HRMAI,
		TDV.TDV_INTVL1, TDV.TDV_INTVL2, TDV.TDV_INTVL3, TDV.TDV_FERIAD, 
		TDV.TDV_FTPEXT, TDV.TDV_FEXTN, TDV.TDV_GRUPO %Exp:cCampos%
	FROM 
		%table:ABQ% ABQ
	JOIN %table:ABB% ABB ON
		ABB.ABB_FILIAL = %xFilial:ABB% AND 
		ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM AND 
		ABB.%NotDel%
	JOIN %table:TDV% TDV ON 
		TDV.TDV_FILIAL = %xFilial:TDV% AND 
		TDV.TDV_CODABB = ABB.ABB_CODIGO AND 
		TDV.%NotDel% 
	LEFT JOIN %table:AA1% AA1 ON
		AA1.AA1_FILIAL = %xFilial:AA1% AND 
		AA1.AA1_CODTEC = ABB.ABB_CODTEC AND
		AA1.%NotDel%
	WHERE 
		ABQ.%NotDel% AND
		ABQ.ABQ_FILIAL = %xFilial:ABQ% AND
		ABQ.ABQ_FILTFF = %Exp:cFilTFF% AND 
		ABQ.ABQ_CODTFF = %Exp:cCodTFF% AND  
		ABQ.ABQ_CONTRT = %Exp:cContrato% AND
		TDV.TDV_DTREF BETWEEN %Exp:DTOS(dLimIni)% AND %Exp:DTOS(dLimFim)% AND
		( SELECT 
			Count(*) 
		FROM 
			%table:TGZ% TGZ 
		WHERE 
			TGZ.TGZ_FILIAL = %xFilial:TGZ% AND 
			TGZ.TGZ_ATEND = ABB.ABB_CODTEC AND
			TGZ.TGZ_CODTFF = %Exp:cCodTFF% AND 
			TGZ.%NotDel% ) = 0 AND 
		( SELECT 
			Count(*) 
		FROM 
			%table:TGY% TGY 
		WHERE 
			TGY.TGY_FILIAL = %xFilial:TGY% AND 
			TGY.TGY_ATEND = ABB.ABB_CODTEC AND
			TGY.TGY_CODTFF = %Exp:cCodTFF% AND 
			TGY.%NotDel% ) = 0
		
EndSql

While (cAliasABB)->(!Eof())
	
	Do Case
		Case (cAliasABB)->TDV_TPDIA == "S" ; cDscTip := STR0016		// "Trabalhado"
		Case (cAliasABB)->TDV_TPDIA == "C" ; cDscTip := STR0017		// "Compensado"
		Case (cAliasABB)->TDV_TPDIA == "D" ; cDscTip := STR0018		// "D.S.R."
		Case (cAliasABB)->TDV_TPDIA == "N" ; cDscTip := STR0019		// "Nao Trabalhado"
		Case (cAliasABB)->TDV_TPDIA == "E" ; cDscTip := STR0020		// "Hora Extra"
		OtherWise 								; cDscTip := ""
	EndCase	
		
	aAdd( aAtend, { (cAliasABB)->TDV_GRUPO,;							// Grupo 
					  StoD((cAliasABB)->ABB_DTINI),;					// Data
					  DiaSemana(StoD((cAliasABB)->ABB_DTINI)),; 		// Dia da Semana
					  (cAliasABB)->ABB_HRINI,; 							// Horario Inicial
					  (cAliasABB)->ABB_HRFIM,;							// Horario Final
					  (cAliasABB)->ABB_CODTEC,;							// Código do atendente
					  (cAliasABB)->AA1_NOMTEC,; 						// Nome do Atendente
					  (cAliasABB)->TDV_TPDIA,;							// Tipo do dia trabalhado
					  cDscTip,; 											// Descrição do dia trabalhado
					  (cAliasABB)->ABB_CODIGO,;							// Código da Agenda do atendente
					  (cAliasABB)->ABB_ATENDE,;							// Se agenda foi atendida
					  (cAliasABB)->TDV_TURNO,;							// Turno do atendente
					  (cAliasABB)->TDV_SEQTRN,;							// Sequencia do turno do atendente
					  {}, Len(aAtend)+1,;								// Dados para a tabela TDV
					  StoD((cAliasABB)->TDV_DTREF),;					// Data de referencia
					  "",;													//chave para posicionamento TGY	(TGY_ESCALA + TGY_CODTDX + TGY_CODTFF)
					  "",;													//Item TGY
					  (cAliasABB)->ABB_MANUT} ) 							//Agenda com manutenção	


					  					  
	nLenAte := Len(aAtend) 					  					  
			
	aAdd( aAtend[nLenAte,14], { (cAliasABB)->TDV_CODABB,;
									StoD((cAliasABB)->TDV_DTREF),;
									(cAliasABB)->TDV_TURNO,;
									(cAliasABB)->TDV_SEQTRN,;
									(cAliasABB)->TDV_TPEXT,;
									(cAliasABB)->TDV_TPEXTN,;
									(cAliasABB)->TDV_NONHOR,;
									(cAliasABB)->TDV_CODREF,;
									(cAliasABB)->TDV_INSREP,;
									(cAliasABB)->TDV_TPDIA,;
									Nil,;											
									(cAliasABB)->TDV_INTVL1,;
									(cAliasABB)->TDV_INTVL2,; 
									(cAliasABB)->TDV_INTVL3,;
									(cAliasABB)->TDV_FERIAD,;
									(cAliasABB)->TDV_FTPEXT,;
									(cAliasABB)->TDV_FEXTN,;
									(cAliasABB)->TDV_HRMEN,;
									(cAliasABB)->TDV_HRMAI,;
									(cAliasABB)->TDV_GRUPO,;
									If(lSum444, (cAliasABB)->TDV_FERSAI, ""),;
									If(lSum444, (cAliasABB)->TDV_FSTPEX, ""),;
									If(lSum444, (cAliasABB)->TDV_FSEXTN, "");
									 } )			  										

	(cAliasABB)->(dbSkip())
 
EndDo

aSort( aAtend, Nil, Nil, { |x,y| DtoS(x[2])+x[4]<DtoS(y[2])+y[4] } )

aAteEfe := aAtend

(cAliasABB)->(dbCloseArea())

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AFil
Filtro para o grid da agenda dos atendentes

@sample 	At330AFil( oPanel, oView )

@param		oPanel - Painel onde deverá ser criado e exibido o botão
	
@return	Nil 
@author	Serviços
@since		10/07/2014       
@version	P12   admin	
/*/
//------------------------------------------------------------------------------
Function At330AFil( oPanel, oView )

Local oMdlFull := oView:GetModel()

Local oFonte
Local oCombo, cCombo

DEFINE FONT oFonte NAME "Arial" BOLD 

@ 014,005 SAY STR0021 SIZE 50, 08 OF oPanel Pixel FONT oFonte	//"Filtro por Grupo"

oCombo := TComboBox():New(022,005,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
                         aFilGrp,55,10,oPanel,,{||At330AMFil(1,oMdlFull,cCombo)};
                         ,,,,.T.,,,,,,,,,"cCombo")
                         
@ 014,075 SAY STR0022 SIZE 80, 08 OF oPanel Pixel FONT oFonte	//"Filtro por Atendente" 

oCombo := TComboBox():New(022,075,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
                         aFilAte,145,10,oPanel,,{||At330AMFil(2,oMdlFull,cCombo)};
                         ,,,,.T.,,,,,,,,,"cCombo")                         
                         
Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AStru
Carrega as estruturas para os grids da alocação

@sample 	At330AStru( oStruct, cTipo, lView )

@param		oStruct - Estrutura a ser alterada com os novos campos
@param		oPanel - Painel onde deverá ser criado e exibido o botão
@param		oPanel - Painel onde deverá ser criado e exibido o botão
	
@return	Nil 
@author	Serviços
@since		10/07/2014       
@version	P12   admin	
/*/
//------------------------------------------------------------------------------
Function At330AStru( lEstr, oStruct, cTipo, lModel )

Local aCols := {}

Local nI, xRet
Local nTamKeyTGY := 0
Local nTamItTGY := 0

Default oStruct := Nil
Default cTipo   := "TFF"
Default lModel  := .T.

If lEstr

	xRet := {}	
	For nI:=1 To 18 // Total de campos da ZZX
		aAdd( aCols, Nil )
	Next nI	
	aAdd( xRet, { 1, aCols } )
		 
Else 

	If lModel
		
		/* Estutura para a criação de campos no model
	
			[01] C Titulo do campo
			[02] C ToolTip do campo
			[03] C identificador (ID) do Field
			[04] C Tipo do campo
			[05] N Tamanho do campo
			[06] N Decimal do campo
			[07] B Code-block de validação do campo
			[08] B Code-block de validação When do campo
			[09] A Lista de valores permitido do campo
			[10] L Indica se o campo tem preenchimento obrigatório
			[11] B Code-block de inicializacao do campo
			[12] L Indica se trata de um campo chave
			[13] L Indica se o campo pode receber valor em uma operação de update.
			[14] L Indica se o campo é virtual
	                    	
		*/  
	
		If cTipo == "TFF"
		
			oStruct:AddField( STR0023, STR0023, "TFF_DATINI", "D", 8, 0, Nil, Nil, Nil, Nil,;  // "Alocação de"
								Nil, Nil, .F., .T. )
			
			oStruct:AddField( STR0024, STR0024, "TFF_DATFIM", "D", 8, 0, Nil, Nil, Nil, Nil,; // "Alocação Ate"
			                    		Nil, Nil, .F., .T. )
			
			oStruct:AddField( STR0025, STR0025, "TFF_DSCABS", "C", 50, 0, Nil, Nil, Nil, Nil,; // "Descrição"
			                    		Nil, Nil, .F., .T. )
		
		ElseIf cTipo == "TGY"
		
			// Legenda do Status de Alocação
			oStruct:AddField( STR0079, STR0079, "TGYSTATUS", "BT", 1, 0, {||At330ALgSt()}, Nil, Nil,.F.,;
								{||At330ALgGS()}, Nil, Nil, .T., Nil ) //"Alocação"

			oStruct:AddField( STR0026, STR0026, "TGY_TIPO", "C", 12, 0, Nil, Nil, Nil, Nil,; // "Tipo" # "Efetivo" # "Cobertura"
			                    		Nil, Nil, .F., .T. )
		
		ElseIf cTipo == "ZZX"
		
			nTamKeyTGY := TamSX3("TGY_ESCALA")[1] + TamSX3("TGY_CODTDX")[1] + TamSX3("TGY_CODTFF")[1]
			nTamItTGY := TamSX3("TGY_ITEM")[1]
			
			// Legenda de agenda gerada
			oStruct:AddField( STR0027, STR0027, "ZZX_SITABB", "BT", 1, 0, {||At330AGtLA()}, Nil, Nil,.F.,;
								{||At330ACLgA()}, Nil, Nil, .T., Nil ) //"Agenda"
			
			// Legenda do tipo da alocação
			oStruct:AddField( STR0028, STR0028, "ZZX_SITALO", "BT", 1, 0, {||At330AGtLS()}, Nil, Nil,.F.,;
								{||At330ACLgS()}, Nil, Nil, .T., Nil ) //"Status"
		
			oStruct:AddField( STR0029, STR0029, "ZZX_GRUPO", "N", 3, 0, Nil, Nil, Nil, Nil,;  // "Grupo"
								Nil, Nil, .F., .T. )

			oStruct:AddField( STR0030, STR0030, "ZZX_DATREF", "D", 8, 0, Nil, Nil, Nil, Nil,;  // "Dt.Referência"
								Nil, Nil, .F., .T. )
		
			oStruct:AddField( STR0031, STR0031, "ZZX_DATA", "D", 8, 0, Nil, Nil, Nil, Nil,;  // "Data"
								Nil, Nil, .F., .T. )

			oStruct:AddField(	STR0032, STR0032, "ZZX_SEMANA", "C", 14, 0, Nil, Nil,;	// "Semana" 
								Nil, Nil, Nil, Nil, Nil, .T. )
								
			oStruct:AddField(	STR0033, STR0033, "ZZX_ENTRADA", "C", 8, 0, Nil, Nil, Nil, Nil,; // "Entrada"
								Nil, Nil, Nil, .F. )			
								
			oStruct:AddField(	STR0034, STR0034, "ZZX_SAIDA", "C", 8, 0, Nil, Nil, Nil, Nil,; // "Saida"
								Nil, Nil, Nil, .F. )
	
			oStruct:AddField(	STR0035, STR0035, "ZZX_ATEND", "C", nTamCdAte, 0, Nil, Nil, Nil, Nil,; // "Cod. Atend"
								{||At330ACLgA()}, Nil, Nil, .F. )
								
			oStruct:AddField(	STR0036, STR0036, "ZZX_NOME", "C", 30, 0, Nil, Nil, Nil, Nil,; // "Nome Atend."
								Nil, Nil, Nil, .T. )
			
			//"S=Trabalhado", "C=Compensado", "D=D.S.R.", "E=Hora Extra", "I=Intervalo", "N=Nao Trabalhado"
			oStruct:AddField(	STR0037, STR0037, "ZZX_TIPO", "C", 1, 0, Nil, Nil, { "S="+STR0016, "C="+STR0017, "D="+STR0018,; 
								"E="+STR0020, "I="+STR0046, "N="+STR0019 }, Nil,; // "Tipo"
								Nil, Nil, Nil, .F. )
																			
			oStruct:AddField(	STR0038, STR0038, "ZZX_ATEAGE", "C", 1, 0, Nil, Nil, Nil, Nil,; // "Atendeu"
								Nil, Nil, Nil, .T. )
								
			oStruct:AddField(	STR0039, STR0039, "ZZX_CODABB", "C", 12, 0, Nil, Nil, Nil, Nil,; // "Cod. Agenda"
								Nil, Nil, Nil, .T. )
								
			oStruct:AddField(	STR0040, STR0040, "ZZX_TURNO", "C", 3, 0, Nil, Nil, Nil, Nil,; // "Turno"
								Nil, Nil, Nil, .T. )
								
			oStruct:AddField(	STR0041, STR0041, "ZZX_SEQ", "C", 2, 0, Nil, Nil, Nil, Nil,; // "Sequencia"
								Nil, Nil, Nil, .T. )
								
			oStruct:AddField(	STR0042, STR0042, "ZZX_ITEM", "N", 6, 0, Nil, Nil, Nil, Nil,; // "Item"
								Nil, Nil, Nil, .T. )	
									
			oStruct:AddField(	"", "", "ZZX_KEYTGY", "C", nTamKeyTGY, 0, Nil, Nil, Nil, Nil,; // "KeyTGY"
								Nil, Nil, Nil, .T. )
								
			oStruct:AddField(	"", "", "ZZX_ITTGY", "C", nTamItTGY, 0, Nil, Nil, Nil, Nil,; // "KeyTGY"
								Nil, Nil, Nil, .T. )					
								
																																																																																
		
		EndIf	                    		
			
	Else
	
	
		/* Estutura para a criação de campos na view	
		
			[01] C Nome do Campo
			[02] C Ordem
			[03] C Titulo do campo  
			[04] C Descrição do campo  
			[05] A Array com Help
			[06] C Tipo do campo
			[07] C Picture
			[08] B Bloco de Picture Var
			[09] C Consulta F3
			[10] L Indica se o campo é editável
			[11] C Pasta do campo
			[12] C Agrupamento do campo
			[13] A Lista de valores permitido do campo (Combo)
			[14] N Tamanho Maximo da maior opção do combo
			[15] C Inicializador de Browse
			[16] L Indica se o campo é virtual
			[17] C Picture Variável
	
		*/
	
		If cTipo == "TFF"
		
			oStruct:AddField( "TFF_DATINI", "01", STR0023, STR0023, Nil, "D", "@!", NIL, "", .F.,; // "Alocação de" 
								NIL	, NIL, NIL, NIL, NIL, .T., NIL )
								
			oStruct:AddField( "TFF_DATFIM", "02", STR0024, STR0024, Nil, "D", "@!", NIL, "", .F.,; // "Alocação Ate" 
								NIL	, NIL, NIL, NIL, NIL, .T., NIL )
								
			oStruct:AddField( "TFF_DSCABS", "04", STR0025, STR0025, Nil, "C", "@!", NIL, "", .F.,;		// "Descrição" 
								NIL	, NIL, NIL, NIL, NIL, .T., NIL )
								
			// Ordena a visualização correta do cabecalho da alocacao
			oStruct:SetProperty( "TFF_LOCAL"	, MVC_VIEW_ORDEM, "03" )
			oStruct:SetProperty( "TFF_CONTRT"	, MVC_VIEW_ORDEM, "05" )
			oStruct:SetProperty( "TFF_PRODUT"	, MVC_VIEW_ORDEM, "06" )
			oStruct:SetProperty( "TFF_DESCRI"	, MVC_VIEW_ORDEM, "07" )
			oStruct:SetProperty( "TFF_ESCALA"	, MVC_VIEW_ORDEM, "08" )
			oStruct:SetProperty( "TFF_NOMESC"	, MVC_VIEW_ORDEM, "09" )									
	
		ElseIf cTipo == "TGY"
	
			oStruct:AddField( "TGYSTATUS", "01", STR0079, STR0079, {}, "BT", "", Nil, Nil, .T.,;
								 "", Nil, Nil, Nil, Nil, .T., Nil ) // "Alocação"


			oStruct:AddField( "TGY_TIPO", "02", STR0026, STR0026, Nil, "C", "", NIL, "", .F.,;		// "Tipo" 
								NIL	, NIL, Nil, NIL, NIL, .T., NIL )
	
			// Ordena a visualização correta do grid de atendentes da escala
			oStruct:SetProperty( "TGY_GRUPO"	, MVC_VIEW_ORDEM, "01" )
			oStruct:SetProperty( "TGY_TURNO"	, MVC_VIEW_ORDEM, "03" )
			oStruct:SetProperty( "TGY_DESC"		, MVC_VIEW_ORDEM, "04" )
			oStruct:SetProperty( "TGY_SEQ"		, MVC_VIEW_ORDEM, "05" )
			oStruct:SetProperty( "TGY_ATEND"	, MVC_VIEW_ORDEM, "06" )
			oStruct:SetProperty( "TGY_NOME"		, MVC_VIEW_ORDEM, "07" )
			oStruct:SetProperty( "TGY_DTINI"	, MVC_VIEW_ORDEM, "08" )
			oStruct:SetProperty( "TGY_DTFIM"	, MVC_VIEW_ORDEM, "09" )
			oStruct:SetProperty( "TGY_ULTALO"	, MVC_VIEW_ORDEM, "10" )										
						
		ElseIf cTipo == "ZZX"
		
			oStruct:AddField( "ZZX_SITABB", "01", STR0027, STR0027, {}, "BT", "", Nil, Nil, .T.,;
								 "", Nil, Nil, Nil, Nil, .T., Nil ) // "Agenda"
			
			oStruct:AddField( "ZZX_SITALO", "02", STR0028, STR0028, {}, "BT", "", Nil, Nil, .F.,;
								 "", Nil, Nil, Nil, Nil, .T., Nil ) // "Status"
			
			oStruct:AddField( "ZZX_GRUPO", "03", STR0029, STR0029, Nil, "N", "@E 999", NIL, "", .F.,;		// "Grupo" 
								NIL	, NIL, NIL, NIL, NIL, .T., NIL )	
		
			oStruct:AddField( "ZZX_DATREF", "04", STR0030, STR0030, Nil, "D", "@!", NIL, "", .F.,; // "Dt.Referência" 
								NIL	, NIL, NIL, NIL, NIL, .T., NIL )
		
			oStruct:AddField( "ZZX_DATA", "05", STR0031, STR0031, Nil, "D", "@!", NIL, "", .F.,; // "Data" 
								NIL	, NIL, NIL, NIL, NIL, .T., NIL )	
	
			oStruct:AddField( "ZZX_SEMANA", "06", STR0032, STR0032, Nil, "C", "", NIL, "", .F.,;		// "Semana" 
								NIL	, NIL, Nil, NIL, NIL, .T., NIL )									
								
			oStruct:AddField( "ZZX_ENTRADA", "07", STR0033, STR0033, Nil, "C", "@!", NIL, "", .F.,;		// "Entrada" 
								NIL	, NIL, NIL, NIL, NIL, .F., NIL )
								
			oStruct:AddField( "ZZX_SAIDA", "08", STR0034, STR0034, Nil, "C", "@!", NIL, "", .F.,;		// "Saida" 
								NIL	, NIL, NIL, NIL, NIL, .F., NIL )
								
			oStruct:AddField( "ZZX_ATEND", "09", STR0035, STR0035, Nil, "C", "@!", NIL, "AA1ABB", .F.,;		// "Cod. Atend" 
								NIL	, NIL, Nil, NIL, NIL, .F., NIL )
								
			oStruct:AddField( "ZZX_NOME", "10", STR0036, STR0036, Nil, "C", "@!", NIL, "", .F.,;		// "Nome Atend." 
								NIL	, NIL, Nil, NIL, NIL, .T., NIL )

			//"S=Trabalhado", "C=Compensado", "D=D.S.R.", "E=Hora Extra", "I=Intervalo", "N=Nao Trabalhado"
			oStruct:AddField( "ZZX_TIPO", "11", STR0037, STR0037, Nil, "C", "", NIL, "", .F.,;		// "Tipo" 
								NIL	, NIL, { "S="+STR0016, "C="+STR0017, "D="+STR0018,; 
								"E="+STR0020, "I="+STR0046, "N="+STR0019 }, NIL, NIL, .F., NIL )																	
		
		EndIf
		
	EndIf	
		
EndIf	
	
Return(xRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330AGtLA			   
Cria as informações referentes a legenda da agenda gerada pela ABB.

@sample 	At330AGtLA()

@author  	Serviços
@since 	  	16/07/2014
@version 	P12

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330AGtLA()	
		  
Local	oLegABB := FwLegend():New()

If	lLegend
	oLegABB:Add( "", "BR_VERMELHO", STR0043 )		//"Agenda Gerada"
	oLegABB:Add( "", "BR_AMARELO" , STR0044 )		//"Agenda Atendida"
	oLegABB:Add( "", "BR_VERDE"	  , STR0045 )		//"Agenda Não Gerada"
	oLegABB:Add( "", "BR_LARANJA" , STR0075 )		//"Agenda com Manutenção"
	oLegABB:Add( "", "BR_PRETO"	  , STR0077 )		//"Conflito de Alocação"
	oLegABB:View()
	DelClassIntf()		
EndIf
                                                                                                                                          
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330ALgSt
Cria as informações referentes a legenda de conflitos de alocação do Atendente (RH).

@sample 	At330ALgSt()

@author  	Serviços
@since 	  	18/05/2015
@version 	P12

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330ALgSt()
		  
Local	oLegTDY := FwLegend():New()

If	lLegend
	oLegTDY:Add( "", "BR_VERDE"		, STR0080 )	//"Atendente Sem conflito de Alocação"
	oLegTDY:Add( "", "BR_VERMELHO"	, STR0081 )	//"Atendente Com Demissão no Período"
	oLegTDY:Add( "", "BR_AZUL"		, STR0082 )	//"Atendente Com Férias no Período"
	oLegTDY:Add( "", "BR_AMARELO"	, STR0083 )	//"Atendente Com Afastamento no Período"
	oLegTDY:Add( "", "BR_CINZA"		, STR0089 )	//"Atendente Com Curso Vencido"
	oLegTDY:Add( "", "BR_LARANJA"	, STR0098 )	//"Atendente com restrição operacional de aviso."
	oLegTDY:Add( "", "BR_PRETO"		, STR0099 )	//"Atendente com restrição operacional para o local/cliente"
	oLegTDY:View()
	DelClassIntf()		
EndIf
                                                                                                                                          
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330AGtLS			   
Cria as informações referentes a legenda do status do dia trabalhado no grid.

@sample 	At330AGtLS()

@author  	Serviços
@since 	  	16/07/2014
@version 	P12

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330AGtLS()

Local oLegSTA := FwLegend():New()

If	lLegend
	oLegSTA:Add( "", "BR_VERDE"   , STR0016 )		//"Trabalhado"
	oLegSTA:Add( "", "BR_AMARELO" , STR0017 )		//"Compensado"
	oLegSTA:Add( "", "BR_AZUL"	  , STR0018 )		//"D.S.R."
	oLegSTA:Add( "", "BR_LARANJA" , STR0020 )		//"Hora Extra"
	oLegSTA:Add( "", "BR_PRETO"   , STR0046 )		//"Hora Extra"
	oLegSTA:Add( "", "BR_VERMELHO", STR0019 )		//"Não Trabalhado"
			
	oLegSTA:View()
	DelClassIntf()	
EndIf
                                                                                                                                          
Return(.T.)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330ALgGS
Atribui a cor nas legendas do grid de Rel. Escala x Func. Efetivo.

@sample 	At330ALgGS()

@author  	Serviços
@since 	  	18/05/2015
@version	P12

@return 	cRet: Cor da legenda conforme a configuração do efetivo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330ALgGS( lDemis, lAfast, lFerias,lCursoVenc,cTipoRest )		  
Local cRet := ""

Default lDemis := .F.
Default lAfast := .F.
Default lFerias := .F.
Default lCursoVenc:= .F. 

If		lDemis
	cRet := "BR_VERMELHO"
ElseIf	lAfast
	cRet := "BR_AMARELO"
ElseIf	lFerias
	cRet := "BR_AZUL"
ElseIf lCursoVenc
	cRet := "BR_CINZA"	
ElseIf cTipoRest == '1' // aviso de restricao
	cRet := "BR_LARANJA"
ElseIf cTipoRest == '2' // bloqueio de restricao
	cRet := "BR_PRETO"
Else
	cRet := "BR_VERDE"	
EndIf
	
Return(cRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330ACLgA
Atribui a cor nas legendas do grid de atendentes.

@sample 	At330ACLgA()

@author  	Serviços
@since 	  	16/07/2014
@version	P12

@return 	cRet: Cor da legenda conforme a configuração do efetivo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330ACLgA( lAgenda, cAtend, lManut, lConflAloc  )		  

Local cRet

Default lAgenda := .F.
Default cAtend  := ""
Default lManut := .F.
Default lConflAloc := .F.

If lConflAloc
	cRet := "BR_PRETO"
ElseIf lAgenda
	If cAtend == "1"
		cRet := "BR_AMARELO"
	ElseIf lManut
		cRet := "BR_LARANJA"	
	Else
		cRet := "BR_VERMELHO"
	EndIf
Else
	cRet := "BR_VERDE"
EndIf
	
Return(cRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330ACLgS
Atribui a cor nas legendas do grid de atendentes.

@sample 	At330ACLgS()

@author  	Serviços
@since 	  	16/07/2014
@version	P12

@return 	cRet: Cor da legenda conforme a configuração do efetivo
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330ACLgS( cStatus )

Local cRet

Default cStatus := ""
	
If cStatus == "S" 		// Trabalhado
	cRet := "BR_VERDE"
ElseIf cStatus == "C" 	// Compensado
	cRet := "BR_AMARELO"	
ElseIf cStatus == "D" 	// D.S.R.
	cRet := "BR_AZUL"
ElseIf cStatus == "E" 	// Hora Extra
	cRet := "BR_LARANJA"
ElseIf cStatus == "I" 	// Intervalo
	cRet := "BR_PRETO"			
Else 						// Nao Trabalhado
	cRet := "BR_VERMELHO"		 	
EndIf

Return(cRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330AAgAt				   
Carrega todos atendentes do posto para o periodo de agenda selecionado

@sample 	At330AAgAt( aAteEfe, aAteCob, dDatIni, dDatFim, cEscala, cCalend )

@param		aAteEfe - Lista com as informações dos efetivos
@param		aAteCob - Lista com as informações das coberturas
@param		dDatIni - Data Inicial para a consistencia das agendas
@param		dDatFim - Data Final para a consistencias das agendas
@param		cEscala - Escala a ser utilizada na agenda
@param		cCalend - Calendario de feriados a ser utilizado na agenda
@param 		cCodTFF - ID do recurso humano
@param 		cFilTFF - Filial do recurso humano 

@author  	Serviços
@since 	  	17/07/2014
@version	P12

@return 	aRet: Lista com os atendentes efetivos e de cobertura para o periodo da agenda 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330AAgAt( aAteEfe, aAteCob, dDatIni, dDatFim, cEscala, cCalend, cCodTFF, cFilTFF, cRtTipo )

Local aTabPadrao	:= {}
Local aTabCalend	:= {}
Local cFilSR6		:= xFilial("SR6")
Local aRet			:= {}
Local aCfgCob		:= {}
Local aAteABB		:= {}
Local nPos			:= 0
Local nPosCob		:= 0
Local nPosABB		:= 0
Local nPosAte		:= 0
Local nIntHor		:= 0
Local nHorIni		:= 0
Local nHorFim		:= 0
Local nItem			:= 0
Local cTipo			:= ""
Local cDscTip		:= ""
Local cHorIni		:= ""
Local cHorFim		:= ""
Local cOrdem		:= ""
Local cIntVl1		:= ""
Local cIntVl2		:= ""
Local cIntVl3		:= ""
Local aArea			:= GetArea()
Local dUltAloc		:= STOD("")
Local cSeqTrn		:= ""
Local nHorMen		:= 0
Local nHorMai		:= 0

Local nI, nJ, nX, nY, nW, nZ, nLenAte
Local lRetCalend, cTurno, cSeq, dDatCob, dAteCob
Local dDtCobIni, dDtCobFim

Local nLenAteEfe := Len(aAteEfe)
Local nLenTbCalend
Local nLenAteEf2
Local nLenCfgCob
Local nLenCalend:= 0
Local aAbbAtend	:= {}
Local aNewAtend	:= {}
Local aCalend	:= {}

Local aRefCalend	:= {}
Local dDtRef		:= SToD("")
Local nDias	 		:= 0
Local aTipo			:= { "1E" , "1S" , "2E" , "2S" , "3E" , "3S" , "4E" , "4S" }
Local nTipo			:= 0
Local nHorasTrab	:= 0
Local lDiaTrab		:= .F.
Local lAfast		:= .F.
Local dIniAfas		:= SToD("")
Local dFimAfas		:= SToD("")
Local cTipAfas		:= ""
Local aAfasta		:= {}
Local cIdAfas		:= "" 
Local cTpHENor		:= ""
Local cTpHENot		:= ""
Local lFeriado		:= .F.
Local cFeriado		:= ""
Local cTpFerHENor	:= ""
Local cTpFerHENot	:= ""
Local nHora			:= ""
Local aFolgas		:= {}
Local cNonaHora 	:= "N"
Local nLimiteIni	:= 0
Local cCodRef		:= ""	
Local cRegra		:= ""
Local aMarcId		:= {Nil, Nil}
Local nIniHNot		:= 0
Local nFimHNot		:= 0
Local nMinHNot		:= 0
Local lTrbFeriado	:= .F.
Local cPagInt		:= ""
Local lAponFer		:= .F.
Local cTpExNorFer	:= ""
Local cTpExNotFer	:= ""
Local lHeAutoFer	:= .F.		
Local cTpDia		:= ""		
Local lTrabDom 		:= .F.
Local lTrabSeg 		:= .F.
Local lTrabTer 		:= .F.
Local lTrabQua 		:= .F.
Local lTrabQui 		:= .F.
Local lTrabSex 		:= .F.
Local lTrabSab 		:= .F.
Local aAreaTDX		:= TDX->(GetArea())
Local aAreaRR0		:= RR0->(GetArea())
Local aAreaSPJ		:= SPJ->(GetArea())
Local aAreaSRA		:= SRA->(GetArea())
Local aAreaAA1		:= AA1->(GetArea())
Local aAreaSR8		:= SR8->(GetArea())
Local aAreaSR6		:= SR6->(GetArea())
Local aAreaTW4		:= TW4->(GetArea())
Local aAreaT44		:= T44->(GetArea())
Local aAreaTFF		:= TFF->(GetArea())
Local cAliasQry		:= ""	
Local lMovJob   	:= IsInCallStack("TECM330ATD")
Local cCodAtend		:= ""
Local cFilAA1		:= ""
Local aRtFer		:= {}
Local aChkFe		:= {}
Default cFilTFF := xFilial( "TFF", cFilAnt )
Default cRtTipo		:= ""

aAteABB := At330AVerABB( dDatIni, dDatFim, cCodTFF, cFilTFF )//Informações da Agenda (ABB) Ordenada por Data de Referencia (TDV_DTREF)

dbSelectArea("ABB")
ABB->(dbSetOrder(1))	//ABB_FILIAL+ABB_CODTEC+DTOS(ABB_DTINI)+ABB_HRINI+DTOS(ABB_DTFIM)+ABB_HRFIM

For nI:=1 To nLenAteEfe
	
	//Buscar por matrícula do funcionário
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))	//AA1_FILIAL+AA1_CODTEC

	cCodAtend := aAteEfe[nI,4,1,2] //Codigo do Atendente.
	cFilAA1   := xFilial("AA1")    //Filial do Atendente.

	If AA1->(DbSeek(cFilAA1 + cCodAtend ))					
		cMatricula	:= AA1->AA1_CDFUNC
	Else
		cMatricula	:= ""
	EndIf

	DbSelectArea("TW4")
    TW4->(DbSetOrder(3))    //TW4_FILIAL+TW4_CODTFF
    If TW4->(DbSeek(xFilial("TW4") + cCodTFF))    //Se encontrar registros nesta tabela vinculadas ao posto, significa que a criação de agenda é personalizada (Por exemplo, usado na rotina de reforço)   
        //Dias de trabalho
        lTrabDom := TW4->TW4_DOM
        lTrabSeg := TW4->TW4_SEG
        lTrabTer := TW4->TW4_TER
        lTrabQua := TW4->TW4_QUA
        lTrabQui := TW4->TW4_QUI
        lTrabSex := TW4->TW4_SEX
        lTrabSab := TW4->TW4_SAB
        lTrabFer := TW4->TW4_FER 
		
		//Buscar o código do turno
		DbSelectArea("TDX")
		TDX->(DbSetOrder(2))	//TDX_FILIAL+TDX_CODTDW+TDX_TURNO
		If TDX->(DbSeek(xFilial("TDX") + cEscala))
			cTurno	:= TDX->TDX_TURNO
			cSeq	:= TDX->TDX_SEQTUR
		Else
			cTurno	:= ""
			cSeq	:= ""
		EndIf
		
		//Executar rotina por dia
		nDias 		:= ( dDatFim - dDatIni )
		cOrdem		:= StrZero(Val(cOrdem)+1,2)	
		For nX:= 0 To nDias
			dDtRef	:= ( dDatIni + nX ) 
			
			//Analisar se dia é feriado
			DbSelectArea("RR0")
			RR0->(DbSetOrder(1))	//RR0_FILIAL+DTOS(RR0_DATA)+RR0_CODCAL
			If RR0->(DbSeek(xFilial("RR0") + DToS(dDtRef) + cCalend))					
				lFeriado 	:= .T.
				cFeriado 	:= RR0->RR0_DESC
				cTpFerHENor := RR0->RR0_TPEXT
				cTpFerHENot := RR0->RR0_TPEXTN
			Else
				lFeriado 	:= .F.
				cFeriado 	:= ""
				cTpFerHENor := ""
				cTpFerHENot := ""
			EndIf	
			
			//Procurar se dia é de trabalho
			lDiaTrab := ( Dow(dDtRef)==1 .And. lTrabDom ) .Or.;
						( Dow(dDtRef)==2 .And. lTrabSeg ) .Or.;
						( Dow(dDtRef)==3 .And. lTrabTer ) .Or.;
						( Dow(dDtRef)==4 .And. lTrabQua ) .Or.;
						( Dow(dDtRef)==5 .And. lTrabQui ) .Or.;
						( Dow(dDtRef)==6 .And. lTrabSex ) .Or.;
						( Dow(dDtRef)==7 .And. lTrabSab ) .Or.;
						( lFeriado       .And. lTrabFer )
						
			//Buscar informações em horário padrão	
			DbSelectArea("SPJ")
			SPJ->(DbSetOrder(1))	//PJ_FILIAL+PJ_TURNO+PJ_SEMANA+PJ_DIA
			If SPJ->(DbSeek(xFilial("SPJ") + cTurno + cSeq + Alltrim(Str(Dow(dDtRef)))))					
				cNonaHora 	:= SPJ->PJ_NONAHOR
				nLimiteIni	:= SPJ->PJ_HORMENO
				cCodRef		:= SPJ->PJ_CODREF 
				cTpHENor	:= SPJ->PJ_TPEXT
				cTpHENot	:= SPJ->PJ_TPEXTN
				cIntSREP	:= SPJ->PJ_INTSREP
				cTpDia		:= SPJ->PJ_TPDIA
			Else
				cNonaHora 	:= ""
				nLimiteIni	:= 0
				cCodRef		:= "" 
				cTpHENor	:= ""
				cTpHENot	:= ""
				cIntSREP	:= ""
				cTpDia		:= ""
			EndIf

			//Buscar regra de apontamento do funcionário
			DbSelectArea("SRA")
			SRA->(DbSetOrder(1))	//RA_FILIAL+RA_MAT
			If SRA->(DbSeek(xFilial("SRA") + cMatricula))					
				cRegra 	:= SRA->RA_REGRA
			Else
				cRegra	:= ""
			EndIf
				
			//Buscar dados no cadastro de regras do apontamento
			DbSelectArea("SPA")
			SPA->(DbSetOrder(1))	//PA_FILIAL+PA_CODIGO
			If SPA->(DbSeek(xFilial("SPA") + cRegra))					
				lTrbFeriado := SPA->PA_FERIADO
				cPagInt		:= SPA->PA_PAGINT
			Else
				lTrbFeriado := .F.
				cPagInt		:= ""
			EndIf	

			//Buscar dados no cadastro de turnos
			DbSelectArea("SR6")
			SR6->(DbSetOrder(1))	//R6_FILIAL+R6_TURNO
			If SR6->(DbSeek(xFilial("SR6") + cTurno))					
				nIniHNot	:= SR6->R6_INIHNOT
				nFimHNot	:= SR6->R6_FIMHNOT
				nMinHNot	:= SR6->R6_MINHNOT
				lAponFer	:= SR6->R6_APODFER
				cTpExNorFer	:= SR6->R6_TPEXFER
				cTpExNotFer	:= SR6->R6_TPEXFEN
				lHeAutoFer	:= SR6->R6_AUTOHEF
			Else
				nIniHNot	:= 0
				nFimHNot	:= 0
				nMinHNot	:= 0
				lAponFer	:= .F.
				cTpExNorFer	:= ""
				cTpExNotFer	:= ""
				lHeAutoFer	:= .F.
			EndIf
	
			//Executar CriaCalend para identificar se é dia de folga do atendente e grava em array aFolgas
			aFolgas		:= {}
			U_PNMSEsc(cEscala) // informar escala
			U_PNMSCal(cCalend) // informar calendario     
			lRetCalend	:= CriaCalend( 	dDatIni    ,;    //01 -> Data Inicial do Periodo
            	          	 			dDatFim    ,;    //02 -> Data Final do Periodo
       	        	        			cTurno     ,;    //03 -> Turno Para a Montagem do Calendario
           	        	    			cSeq       ,;    //04 -> Sequencia Inicial para a Montagem Calendario
               	        				@aTabPadrao,;    //05 -> Array Tabela de Horario Padrao
                   	    				@aTabCalend,;    //06 -> Array com o Calendario de Marcacoes  
                       					cFilSR6    ,;    //07 -> Filial para a Montagem da Tabela de Horario
                       					Nil, Nil )
			U_PNMSEsc(Nil) // Limpar as variáveis estáticas
			U_PNMSCal(Nil) 

			For nY := 1 To Len(aTabCalend)
				If Len(aTabCalend[1])>=6           
					If aTabCalend[1][6] <> "S"
						AAdd(aFolgas, aTabCalend[nY])	//Data
					EndIf        
    			EndIf		
    		Next nY
			If aScan(aFolgas,{|X| X[1] = dDtRef }) == 0
				cTipoDia := "S"
			Else
				cTipoDia :=	"N"	
			EndIf
			
			//Verifica se atendente afastado
			lAfast := fAfasta( xFilial("SRA"), cMatricula , dDtRef , @dIniAfas , @dFimAfas , @cTipAfas , aAfasta , @cIdAfas )
											
			//Query com os dias da semana e horários de trabalho do reforço
			cAliasQry := GetNextAlias()
			BeginSql Alias cAliasQry
				SELECT T44.T44_SEQUEN, T44.T44_HORAIN, T44.T44_HORAFI 
				FROM %table:TW4% TW4
				JOIN %table:T44% T44
			  	ON (T44.T44_FILIAL=%xFilial:T44% AND T44.T44_CODTW4=TW4.TW4_COD AND T44.%NotDel%)
				WHERE TW4.TW4_FILIAL=%xFilial:TW4%
  			  	  AND TW4.%NotDel%
  			  	  AND TW4.TW4_CODTFF=%Exp:cCodTFF%
				ORDER BY T44.T44_SEQUEN
			EndSql
		
			nTipo := 1
			Do While (cAliasQry)->(!EOF())
				If Mod(nTipo,2)<>0	//Elementos em posição ímpar são elementos de entrada
					nHora		:= Val(StrTran((cAliasQry)->T44_HORAIN, ":", "."))
					aMarcId[1]	:= dDtRef
					aMarcId[2]	:= nLimiteIni
					nHorasTrab	:= SubtHoras( dDtRef, (cAliasQry)->T44_HORAIN, dDtRef, (cAliasQry)->T44_HORAFI )
				Else
					nHora		:= Val(StrTran((cAliasQry)->T44_HORAFI, ":", "."))
					aMarcId[1]	:= Ctod("//")
					aMarcId[2]	:= 0
					nHorasTrab	:= 0
				EndIf	

				//Preencher array aTabCalend
				AAdd(	aRefCalend, Array( ELEMENTOS_ATABCALEND ) )
						nLenCalend := Len( aRefCalend )
						aRefCalend[	nLenCalend	,	CALEND_POS_DATA				] := dDtRef							// 01 - Data
						aRefCalend[	nLenCalend	,	CALEND_POS_DATA_APO			] := dDtRef							// 48 - Data de Apontamento
						aRefCalend[	nLenCalend	,	CALEND_POS_ORDEM			] := cOrdem							// 02 - Ordem
						aRefCalend[	nLenCalend	,	CALEND_POS_HORA				] := nHora				      		// 03 - Hora
						aRefCalend[	nLenCalend	,	CALEND_POS_TIPO_MARC		] := aTipo[ nTipo ]        			// 04 - Tipo Marc
						aRefCalend[	nLenCalend	,	CALEND_POS_NUM_MARC			] := 0					    		// 05 - No Marc.
						aRefCalend[	nLenCalend	,	CALEND_POS_TIPO_DIA			] := cTipoDia     					// 06 - Tipo Dia
						aRefCalend[	nLenCalend	,	CALEND_POS_HRS_TRABA		] := nHorasTrab						// 07 - Horas Trabalhada no Periodo
						aRefCalend[	nLenCalend	,	CALEND_POS_SEQ_TURNO		] := "01"					   		// 08 - Sequência de Turno
						aRefCalend[	nLenCalend	,	CALEND_POS_HRS_INTER		] := 0								// 09 - Horas de Intervalo
						aRefCalend[	nLenCalend	,	CALEND_POS_EXCECAO			] := "N"							// 10 - Excecao ( E-Excecao, # E - nao e excecao )
						aRefCalend[	nLenCalend	,	CALEND_POS_MOT_EXECAO		] := ""								// 11 - Motivo da Excecao
						aRefCalend[	nLenCalend	,	CALEND_POS_TIPO_HE_NOR		] := cTpHENor						// 12 - Tipo de hora extra normal
						aRefCalend[	nLenCalend	,	CALEND_POS_TIPO_HE_NOT		] := cTpHENot						// 13 - Tipo de hora extra noturna
						aRefCalend[	nLenCalend	,	CALEND_POS_TURNO			] := cTurno							// 14 - Turno de Trabalho
						aRefCalend[	nLenCalend	,	CALEND_POS_CC				] := ""								// 15 - Centro de Custo do Periodo 
						aRefCalend[	nLenCalend	,	CALEND_POS_PG_NONA_HORA		] := cNonaHora						// 16 - Pagamento de Nona Hora
						aRefCalend[	nLenCalend	,	CALEND_POS_LIM_MARCACAO		] := aClone( aMarcId )				// 17 - Limite de Marcacao Inicial
						aRefCalend[	nLenCalend	,	CALEND_POS_COD_REFEICAO		] := cCodRef						// 18 - Codigo da Refeicao
						aRefCalend[	nLenCalend	,	CALEND_POS_FERIADO			] := lFeriado						// 19 - Dia e Feriado
						aRefCalend[	nLenCalend	,	CALEND_POS_TP_HE_FER_NR		] := cTpFerHENor					// 20 - Tipo de Hora Extra Feriado Normal
						aRefCalend[	nLenCalend	,	CALEND_POS_TP_HE_FER_NT 	] := cTpFerHENot					// 21 - Tipo de Hora Extra Feriado Noturna
						aRefCalend[	nLenCalend	,	CALEND_POS_DESC_FERIADO		] := cFeriado						// 22 - Descricao do Feriado
						aRefCalend[	nLenCalend	,	CALEND_POS_REGRA			] := cRegra							// 23 - Regra de Apontamento
						aRefCalend[	nLenCalend	,	CALEND_POS_AFAST			] := lAfast							// 24 - Funcionario Afastado
						aRefCalend[	nLenCalend	,	CALEND_POS_TIP_AFAST		] := cTipAfas						// 25 - Tipo de Afastamento
						aRefCalend[	nLenCalend	,	CALEND_POS_INI_AFAST		] := dIniAfas						// 26 - Data Inicial do Afastamento
						aRefCalend[	nLenCalend	,	CALEND_POS_FIM_AFAST		] := dFimAfas						// 27 - Data Final do Afastamento
						aRefCalend[	nLenCalend	,	CALEND_POS_R8ID				] := cIdAfas						// 47 - Identificacao afastamento
						aRefCalend[	nLenCalend	,	CALEND_POS_INI_H_NOT		] := nIniHNot						// 28 - Inicio da Hora Noturna
						aRefCalend[	nLenCalend	,	CALEND_POS_FIM_H_NOT		] := nFimHNot						// 29 - Final da Hora Noturna
						aRefCalend[	nLenCalend	,	CALEND_POS_MIN_H_NOT		] := nMinHNot						// 30 - Minutos da Hora Noturna
						aRefCalend[	nLenCalend	,	CALEND_POS_TRAB_FERIADO		] := lTrbFeriado					// 31 - Se funcionario Trabalha em Dias Feriados
						aRefCalend[ nLenCalend	,   CALEND_POS_TIPO_ORIG_DIA    ] := cTpDia							// 36 - Tipo Original do Dia conforme excecao mas sem considerar a regra e/ou afastamentos
						aRefCalend[	nLenCalend	,	CALEND_POS_APON_FERIAS		] := lAponFer						// 32 - Se Aponta Quando Afastamento em Ferias
						aRefCalend[	nLenCalend	,	CALEND_POS_TP_HE_NR_FER		] := cTpExNorFer					// 33 - Tipo de hora extra normal (Ferias)
						aRefCalend[	nLenCalend	,	CALEND_POS_TP_HE_NT_FER		] := cTpExNotFer					// 34 - Tipo de hora extra noturna (Ferias)	
						aRefCalend[	nLenCalend	,	CALEND_POS_PAGINT			] := cPagInt						// 35 - Tipos de Intervalos Que sao Pagos conforme Regra
						aRefCalend[ nLenCalend	,   CALEND_POS_HE_AUTO_FER      ] := lHeAutoFer						// 37 - Se H.Extras são autorizadas para funcionario em ferias				
						aRefCalend[ nLenCalend	,   CALEND_POS_INTSREP 		    ] := cIntSREP						// 38 - Intervalo para geracao do ACJEF
			
				If Mod(nTipo,2)==0	//Elementos em posição par são elementos de saída, então pode ir para próximo registro
					(cAliasQry)->(DbSkip())
				EndIf
					
				nTipo++
			EndDo	
		
		Next nX
    	
    	aTabCalend := aClone(aRefCalend)
    	
    	(cAliasQry)->(DbCloseArea())
    	RestArea(aAreaTDX)
		RestArea(aAreaRR0)
		RestArea(aAreaSPJ)
		RestArea(aAreaSRA)
		RestArea(aAreaAA1)	
		RestArea(aAreaSR8)
		RestArea(aAreaSR6)
		RestArea(aAreaTW4)
		RestArea(aAreaT44)
		RestArea(aAreaTFF)
    	    	
	Else
	
		// Ordena as datas a serem consistidas para gerar as informações
		aSort( aAteEfe[nI,4],,, { |x,y| x[1]<y[1] } )
	
		cTurno := aAteEfe[nI,1] 
		cSeq   := aAteEfe[nI,2]
		
		U_PNMSEsc(cEscala) // informar escala
		U_PNMSCal(cCalend) // informar calendario     
	
		lRetCalend := CriaCalend( 	dDatIni    ,;    //01 -> Data Inicial do Periodo
        	                   		dDatFim    ,;    //02 -> Data Final do Periodo
            	                	cTurno     ,;    //03 -> Turno Para a Montagem do Calendario
                	            	cSeq       ,;    //04 -> Sequencia Inicial para a Montagem Calendario
                    	        	@aTabPadrao,;    //05 -> Array Tabela de Horario Padrao
                        	    	@aTabCalend,;    //06 -> Array com o Calendario de Marcacoes  
                            		cFilSR6    ,;    //07 -> Filial para a Montagem da Tabela de Horario
                            		Nil, Nil )
                            	
		U_PNMSEsc(Nil) // Limpar as variaveis estaticas
		U_PNMSCal(Nil) 
		//Ordena por data, entrada e saída.
		If lRetCalend
			aSort( aTabCalend,,, { |x,y| dTos(x[1])+x[4] < dTos(y[1])+y[4] } )
		Endif
	EndIf
	
	// Lista com as possiveis coberturas do efetivo
	aCfgCob := At330ACob( cCodTFF, cEscala, cTurno, cSeq)
	
	cOrdem  := ""
	nIntHor := 0
	nLenTbCalend := Len(aTabCalend)
	
	For nJ:=1 To nLenTbCalend Step 2
	
		nLenAteEf2 := Len(aAteEfe[nI,4])//Quantidade de atendentes dentro da configuração da escala		
		
		// Efetivos
		For nX:=1 To nLenAteEf2 											
			
			// Verifica se o atendente esta dentro do periodo			
			If !Empty(aAteEfe[nI,4,nX,3]) .And. !Empty(aAteEfe[nI,4,nX,4])
				If	!( aTabCalend[nJ,CALEND_POS_DATA] >= aAteEfe[nI,4,nX,3] .And. ; 
					 aTabCalend[nJ+1,CALEND_POS_DATA] <= aAteEfe[nI,4,nX,4] ) 						
					Loop
				EndIf
			ElseIf Empty(aAteEfe[nI,4,nX,4]) // Verifica os atendentes sem data final de atendimento
				If ! aTabCalend[nJ,CALEND_POS_DATA] >= aAteEfe[nI,4,nX,3]
					Loop
				EndIf	
			EndIf
						
			If aTabCalend[nJ, CALEND_POS_TIPO_MARC] == "1E" 				
				
				dDatCob    := Nil

				//Recupera todas agendas já geradas com base na data de referencia
				aAbbAtend := At330AAbb(aTabCalend[nJ,CALEND_POS_DATA_APO], aAteABB, aAteEfe[nI,4,nX,2])
				
				//Recupera conjunto de marcações do aTabCalend para o data de referencia				
				aCalend := At330ACal(aTabCalend, nJ)
								
				//Recupera estrutura do atendente  a ser apresentada na alocação
				aNewAtend := getInfoAtend(aAbbAtend, aCalend, aAteEfe[nI,4,nX], cTurno, cSeq, cEscala+aAteEfe[nI][3]+cCodTFF)
			
				//Adiciona itens na estrutura do aAtend					
				For nZ := 1 To Len(aNewAtend)
					nItem++
					aAdd(aAtend, aNewAtend[nZ])	
					aAtend[Len(aAtend)][15] := nItem//Ajusta Item										
				Next nZ
				
			EndIf
	
			
			//Cobertura			
			If dDatCob <> aTabCalend[nJ,CALEND_POS_DATA]
				
				dDatCob := aTabCalend[nJ,CALEND_POS_DATA]	
				nPosCob := aScan(	aCfgCob, { |x| x[1] == Str(Dow(aTabCalend[nJ,CALEND_POS_DATA]),1) } )	
				
				If nPosCob > 0
				
					For nY:=1 To Len(aCfgCob[nPosCob,2])
						
						If aCfgCob[nPosCob,2,nY,5] == "1"	// Trabalha
							cTipo := "S"
						ElseIf aCfgCob[nPosCob,2,nY,5] == "3" // Intervalo
							cTipo := "I"
						Else 	
							If (HoraToInt(aCfgCob[nPosCob,2,nY,4])+HoraToInt(aCfgCob[nPosCob,2,nY,3])) > 0
								cTipo := "S"
							Else
								cTipo := "N"
							EndIf
						EndIf
						
						cDscTip := At330ADTip(cTipo)//Descricação do tipo
						
						
						cHorIni := aCfgCob[nPosCob,2,nY,3]
						cHorFim := aCfgCob[nPosCob,2,nY,4]
					
						// Ordena as datas a serem consistidas para gerar as informações da cobertura
						aSort( aCfgCob[nPosCob,2,nY,6],,, { |x,y| x[1]<y[1] } )
						nLenCfgCob := Len(aCfgCob[nPosCob,2,nY,6])
						
						For nW:=1 To nLenCfgCob 
						
							//Quando for ferista busca o atendente e a data na rota de cobertura.
							If aCfgCob[nPosCob,2,nY,2] == "4" .And. At581Rota(,,aAteEfe[nI,4,nX,2],,aTabCalend[nJ,CALEND_POS_DATA],1) .And. (Empty(cRtTipo) .OR. cRtTipo == "4"  ) 
								aRtFer := At581Feris(aAteEfe[nI,4,nX,2],aTabCalend[nJ,CALEND_POS_DATA],aTabCalend[nJ,CALEND_POS_DATA]) //Seleciona quem fara a cobertura de ferias.
								aChkFe := At581ChkFe(aAteEfe[nI,4,nX,2],aTabCalend[nJ,CALEND_POS_DATA],aTabCalend[nJ,CALEND_POS_DATA]) //Seleciona quem sairá de ferias. 
								//Se existir na rota de cobertura e for ferias efetivas do atendente.
								If !Empty(aRtFer) .And. aChkFe[4] .And. !(aChkFe[5] > aRtFer[3] .OR. aChkFe[6] < aRtFer[2]) 
									//Seleciona o atendente e as datas de cobertura
									aCfgCob[nPosCob,2,nY,6,nW,1] :=	aRtFer[1]
									aCfgCob[nPosCob,2,nY,6,nW,2] := aRtFer[2]
									aCfgCob[nPosCob,2,nY,6,nW,3] := aRtFer[3]
								Else
									Loop
								Endif
							//Quando for almocista, jantista e folguista busca o atendente e o horário na lista de cobertura do efetivo.
							Elseif  (aCfgCob[nPosCob,2,nY,2] == "1"  .And. At581Rota(cCodTFF,aAteEfe[nI][3],aAteEfe[nI,4,nX,2],aAteEfe[nI,4,nX,1],,2)) .And. (Empty(cRtTipo) .OR. cRtTipo == "1"  ) .OR.;
									(aCfgCob[nPosCob,2,nY,2] $ "2|3" .And. At581Rota(cCodTFF,aAteEfe[nI][3],aAteEfe[nI,4,nX,2],aAteEfe[nI,4,nX,1],,3)) .And. (Empty(cRtTipo) .OR. cRtTipo $ "2|3" )
								aRtFer := {}
								aChkFe := {}
							Else
							//Se não houver cadastro na rota de cobertura não realiza a cobertura.
								Loop
							Endif

							// Verifica se o atendente esta dentro do periodo
							If !Empty(aCfgCob[nPosCob,2,nY,6,nW,2]) .And. !Empty(aCfgCob[nPosCob,2,nY,6,nW,3])			
								If	!( aTabCalend[nJ,CALEND_POS_DATA] >= aCfgCob[nPosCob,2,nY,6,nW,2] .And. ; 
									 aTabCalend[nJ+1,CALEND_POS_DATA] <= aCfgCob[nPosCob,2,nY,6,nW,3] ) 						
									Loop
								EndIf
							ElseIf Empty(aCfgCob[nPosCob,2,nY,6,nW,3]) // Verifica os atendentes sem data final de atendimento
								If ! aTabCalend[nJ,CALEND_POS_DATA] >= aCfgCob[nPosCob,2,nY,6,nW,2]
									Loop
								EndIf								
							EndIf
							
							nItem++							
							
							nPosABB := aScan( aAteABB, { |x| x[1] 	== aTabCalend[nJ,CALEND_POS_DATA] .And.;
																	x[5] == aCfgCob[nPosCob,2,nY,6,nW,1] .And. x[7] == .T. .And. ;
																	(x[3] == cHorIni .Or. x[4] == cHorFim) } )
				
							If nPosABB == 0
								nPosABB := aScan( aAteABB, { |x| x[1] 	== aTabCalend[nJ,CALEND_POS_DATA] .And.;
																  x[5] == aCfgCob[nPosCob,2,nY,6,nW,1] .And. x[7] == .T. } )							 
							EndIf
																  												  
							If nPosABB > 0
								
								cHorIni := aAteABB[ nPosABB, 3 ]				
								cHorFim := aAteABB[ nPosABB, 4 ]
				
								If cTipo == "N" .And. ( HoraToInt( cHorIni ) + HoraToInt( cHorFim ) ) > 0
									cTipo := "E"									
								EndIf		
																								
								aAteABB[ nPosABB, 7 ] := .F.				
								
							EndIf		
														
							dAteCob := aTabCalend[nJ,CALEND_POS_DATA]
							
							// Verifica quando a cobertura entra no meio do turno no dia seguinte
							If aTabCalend[nJ,CALEND_POS_DATA] <> aTabCalend[nJ+1,CALEND_POS_DATA]
								If HoraToInt(cHorIni) >= 0
									dAteCob := aTabCalend[nJ+1,CALEND_POS_DATA]		
								EndIf
							EndIf	
							
							dDtCobIni := dAteCob
							dDtCobFim := Iif( HoraToInt(cHorFim) < HoraToInt(cHorIni), dAteCob + 1, dAteCob ) 				
							
							aAdd( aAtend, { 	aAteEfe[nI,4,nX,1],;								// Grupo 
								  				dAteCob,;					// Data
								  				DiaSemana(dAteCob),; 	// Dia da Semana
								  				cHorIni,; 								 			// Horario Inicial
								  				cHorFim,;											// Horario Final
								  				aCfgCob[nPosCob,2,nY,6,nW,1],;					// Código do atendente
								  				Posicione("AA1",1,xFilial("AA1")+aCfgCob[nPosCob,2,nY,6,nW,1],"AA1_NOMTEC"),; // Nome do Atendente
								  				cTipo,;												// Tipo do dia trabalhado
								  				cDscTip,; 											// Descrição do dia trabalhado
								  				If(nPosABB>0,aAteABB[nPosABB][9], ""),; 												// Código da Agenda do atendente
								  				If(nPosABB>0,aAteABB[nPosABB][10],""),; 												// Se agenda foi atendida
								  				"",;												// Turno do atendente
								  				"",; 												// Sequencia do turno do atendente
								  				{},;
								  				nItem,;										// Dados para a tabela TDV
								  				aTabCalend[nJ,CALEND_POS_DATA_APO],;			// Data de referencia
								  				"",;	//chave para posicionamento TGY	(TGY_ESCALA + TGY_CODTDX + TGY_CODTFF)
								  				"",;//Item TGY
								  				If(nPosABB>0,aAteABB[nPosABB][12],"2")} ) //Agenda Ativa

							nLenAte := Len(aAtend)	
							
							
							// Calculo para os limites de entrada
							If Len(aTabCalend[nJ,CALEND_POS_LIM_MARCACAO]) > 0
								If !Empty(DTOS(aTabCalend[nJ,CALEND_POS_LIM_MARCACAO][1]))
									nHorMen := SubtHoras(aTabCalend[nJ,CALEND_POS_LIM_MARCACAO][1],AtConvHora(aTabCalend[nJ,CALEND_POS_LIM_MARCACAO][2]),aTabCalend[nJ,CALEND_POS_DATA],If(cHorIni=="FOLGA", "00:00",cHorIni ),.T.)
								EndIf
							EndIf
					
							// Calculo para os limites de saida
							If Len(aTabCalend[nJ+1,CALEND_POS_LIM_MARCACAO]) > 0
								If !Empty(DTOS(aTabCalend[nJ+1,CALEND_POS_LIM_MARCACAO][1]))
									nHorMai := SubtHoras(aTabCalend[nJ+1,CALEND_POS_DATA],If(cHorFim=="FOLGA", "00:00",cHorIni ), aTabCalend[nJ+1,CALEND_POS_LIM_MARCACAO][1],AtConvHora(aTabCalend[nJ+1,CALEND_POS_LIM_MARCACAO][2]),.T.)
								EndIf
							EndIf
							
							aAdd( aAtend[nLenAte,14], { Nil,;
															aTabCalend[nJ,CALEND_POS_DATA_APO],;
															aTabCalend[nJ,CALEND_POS_TURNO],;
															cSeqTrn,;
															aTabCalend[nJ,CALEND_POS_TIPO_HE_NOR],;
															aTabCalend[nJ,CALEND_POS_TIPO_HE_NOT],;
															aTabCalend[nJ,CALEND_POS_PG_NONA_HORA],;
															aTabCalend[nJ,CALEND_POS_COD_REFEICAO],;
															aTabCalend[nJ,CALEND_POS_INTSREP],;
															aTabCalend[nJ,CALEND_POS_TIPO_DIA],;
															aTabCalend[nJ,CALEND_POS_LIM_MARCACAO],;
															"N", "N", "N",;
															aTabCalend[nJ,CALEND_POS_DESC_FERIADO],;
															aTabCalend[nJ,CALEND_POS_TP_HE_FER_NR],;
															aTabCalend[nJ,CALEND_POS_TP_HE_FER_NT],;
															nHorMen,;
															nHorMai,;
															aAteEfe[nI,4,nX,1],;
															aTabCalend[nJ+1,CALEND_POS_DESC_FERIADO],;//Feriado Saída
															aTabCalend[nJ+1,CALEND_POS_TP_HE_FER_NR],;//Tipo Hora extra saida
															aTabCalend[nJ+1,CALEND_POS_TP_HE_FER_NT];//Tipo Hora extra saida 
														} )
															
							If ABB->(MsSeek( xFilial("ABB") + ; 
								 				aCfgCob[nPosCob,2,nY,6,nW,1] + ;
								 				DtoS(dDtCobIni) + ;
								 				cHorIni + ;
								 				DtoS(dDtCobFim) + ;
								 				cHorFim ) )
								
								nPosABB := aScan( aAtend, { |x| x[10] == ABB->ABB_CODIGO .And.;
								   							    x[11] == ABB->ABB_ATENDE } )
			
								If nPosABB == 0
									aAtend[nLenAte,10]     := ABB->ABB_CODIGO
									aAtend[nLenAte,11]     := ABB->ABB_ATENDE		
									aAtend[nLenAte,14,1,1] := ABB->ABB_CODIGO
								EndIf
														
							EndIf
																						  								
						
						Next nW				
					
					Next nY 
				
				EndIf
				
			EndIf			
							  
		Next nX		
		 
	Next nJ

Next nI

aSort( aAtend, Nil, Nil, { |x,y| DtoS(x[2])+x[4]<DtoS(y[2])+y[4] } )//Ordena atendentes 

RestArea(aArea)

aRet := aAtend

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330AAbb
Recupera agendas existentes em aAteAbb considerando a data de referencia e o codigo do tecnico
@since 17/03/2015
@version 1.0
@param dDataRef, Date, Data de referencia
@param aAteAbb, Array, Array com Agendas a serem filtradas
@param cCodtec, String, Código do tecnico
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At330AAbb(dDataRef, aAteAbb, cCodtec)
Local nPos := 1
Local aAbb := {}
Local nI := 1

//Busca agenda que ainda não foi apresentada pela data de referencia e codigo do atendente
nPos := aScan(aAteAbb, {|x| STOD(x[11][_TDV_DTREF]) == dDataRef .AND. x[7] .AND. x[5]==cCodTec })	

If nPos > 0
	For nI := nPos To Len(aAteAbb)
					
		If STOD(aAteAbb[nI][11][_TDV_DTREF])  == dDataref .AND. aAteAbb[nI][5] == cCodTec
			If aAteAbb[nI][7]//Agenda ainda não apresentada
				aAdd(aAbb, aAteAbb[nI])
				aAteAbb[nI][7] := .F.//Indicação de agenda já utilizada
			EndIf
		Else
			Exit//Interrompe a repetição						
		EndIf
	Next nI
EndIf
Return aAbb

//--------------------------------------------------------------------------------------------------------------------
Static Function At330ACal(aTabCalend, nIndCalend)
	Local aCalend := {}
	Local nOrdem := 0
	Local nI := 1
	
	If Len(aTabCalend) >= nIndCalend
		nOrdem := aTabCalend[nIndCalend][CALEND_POS_ORDEM]
		
		For nI:=nIndCalend To Len(aTabCalend)
			If nOrdem ==  aTabCalend[nI][CALEND_POS_ORDEM]	
				aAdd(aCalend, aTabCalend[nI])	
			Else
				Exit
			EndIf
		Next nI
	EndIf
	
Return aCalend


//--------------------------------------------------------------------------------------------------------------------
Static Function getInfoAtend(aAbb, aCalend, aAteEfe, cTurno, cSeq, cKeyTGY)
	Local nI := 1
	Local cTipo := ""
	Local aNewAtend:= {}
	Local cIntVl1 := "N"
	Local cIntVl2 := "N"
	Local cIntVl3 := "N"
	Local cSeqTrn	:= ""
	Local nIntHor := 0
	Local nPosHora	:= 0
	Local lHrs :=  .F.
	
	lHrs :=  Len(aAteEfe[8]) > 0
	
	If Len(aAbb) > 0
		For nI := 1 To Len(aAbb)

			cTipo := At330ATip(aAbb[nI][6], HoraToInt(aAbb[nI][3]), HoraToInt(aAbb[nI][4]))

			aAdd( aNewAtend, { aAteEfe[1],;						// Grupo 
							  aAbb[nI][1],;						// Data
							  DiaSemana(aAbb[nI][1]),;			// Dia da Semana
							  aAbb[nI][3],; 						// Horario Inicial
							  aAbb[nI][4],;						// Horario Final
							  aAteEfe[2],;						// Código do atendente
							  Posicione("AA1",1,xFilial("AA1")+aAteEfe[2],"AA1_NOMTEC"),; // Nome do Atendente
							  cTipo,;								// Tipo do dia trabalhado
							  At330ADTip(cTipo),; 				// Descrição do dia trabalhado
							  aAbb[nI][9],;						// Código da Agenda do atendente
							  aAbb[nI][10],;						// Se agenda foi atendida
							  aAbb[nI][11][_TDV_TURNO],;					// Turno do atendente
							  aAbb[nI][8],;						// Sequenci do turno do atendente
							  {},;									// Dados para a tabela TDV
							  0,;								//Item
							  STOD(aAbb[nI][11][_TDV_DTREF]),;	// Data de referencia
							  cKeyTGY,;							//chave para posicionamento TGY	(TGY_ESCALA + TGY_CODTDX + TGY_CODTFF)
							  aAteEfe[5],;						//Item TGY
							  aAbb[nI][12]} )					//Agenda com manutenção												  

			
			cIntVl1 := aAbb[nI][11][_TDV_INTVL1]
			cIntVl2 := aAbb[nI][11][_TDV_INTVL2]
			cIntVl3 := aAbb[nI][11][_TDV_INTVL3]
			
			//Adiciona informações da TDV na estrutura do atendente
			aAdd( aNewAtend[Len(aNewAtend),14], getInfoTDV(NIl, NIl, aAbb[nI],aAbb[nI][3], aAbb[nI][4], cTipo, cIntVl1, cIntVl2, cIntVl3, aAteEfe[1] ))					  
						
		Next nI
	Else		
		
		//Percorre aCalend, considerando a estrutura do aTabCalend.
		//Obrigatoriamente deve existir linha para horário de entrada e linha para horário de saída
		For nI:=1 To Len(aCalend) Step 2
			nPosHora += 1
			//Não gera nova agenda para dias anteriores a data da ultima alocação.
			//para realizar este procedimento é necessário excluir as alocações				
			If aCalend[nI][CALEND_POS_DATA_APO] > aAteEfe[6]
				If Len(aCalend) >= nI + 1
					cTipo := At330ATip(aCalend[nI][CALEND_POS_TIPO_DIA], aCalend[nI][CALEND_POS_HORA], aCalend[nI+1][CALEND_POS_HORA])
				Else
					cTipo := ''
				EndIf
						
				If cTipo == "S" .Or. cTipo == "E"
					If lHrs .And. !Empty(StrTran(aAteEfe[8,nPosHora,1], ':','')) .And. !Empty(StrTran(aAteEfe[8,nPosHora,2], ':', ''))
						cHorIni := aAteEfe[8,nPosHora,1] 
						cHorFim := aAteEfe[8,nPosHora,2]
					Else										
						cHorIni := AtConvHora(aCalend[ nI ,CALEND_POS_HORA])
						cHorFim := AtConvHora(aCalend[ nI+1 ,CALEND_POS_HORA])
					EndIf	
				Else
					cHorIni := "FOLGA"	// "FOLGA"
					cHorFim := "FOLGA"
				EndIf
				
				cSeqTrn := 	aCalend[nI,CALEND_POS_SEQ_TURNO]
					
			Else //Não existe agenda (ABB) e data inferior a ultima alocação realizada				
				cTipo := "N"
				cHorIni := "FOLGA"
				cHorFim := "FOLGA"
				
				cSeqTrn := ""//Deixa sequencia do turno vazia para recuperar quando salvar a alocação
					
			EndIf

			aAdd( aNewAtend, { aAteEfe[1],;								// Grupo 
							  aCalend[nI,CALEND_POS_DATA],;					// Data
							  DiaSemana(aCalend[nI,CALEND_POS_DATA]),; 	// Dia da Semana
							  cHorIni,; 								 			// Horario Inicial
							  cHorFim,;											// Horario Final
							  aAteEfe[2],;								// Código do atendente
							  Posicione("AA1",1,xFilial("AA1")+aAteEfe[2],"AA1_NOMTEC"),; // Nome do Atendente
							  cTipo,;												// Tipo do dia trabalhado
							  At330ADTip(cTipo),; 											// Descrição do dia trabalhado
							  "",;				// Código da Agenda do atendente
							  "",;				// Se agenda foi atendida
							  aCalend[nI][CALEND_POS_TURNO],;												// Turno do atendente
							  cSeqTrn,;												// Sequencia do turno do atendente
							  {},;											// Dados para a tabela TDV
							  0,;										//Item
							  aCalend[nI,CALEND_POS_DATA_APO],;// Data de referencia
							  cKeyTGY,;	//chave para posicionamento TGY	(TGY_ESCALA + TGY_CODTDX + TGY_CODTFF)
							  aAteEfe[5],;//Item TGY
							  "2" } ) 									//Agenda com Manutenção	
							  
							  
			// Verifica se existe intervalo entre as marcações
			nIntHor++
			
			cIntVl1 := "N"
			cIntVl2 := "N"
			cIntVl3 := "N"
			
			If Len(aCalend) >= nI + 1
				If aCalend[nI+1,CALEND_POS_HRS_INTER] > 0
					Do Case
						Case nIntHor == 1	; cIntVl1 := "S"
						Case nIntHor == 2	; cIntVl2 := "S"
						OtherWise			; cIntVl3 := "S"
					EndCase  
				EndIf
			EndIf	
			//Adiciona informações da TDV na estrutura do atendente
			aAdd( aNewAtend[Len(aNewAtend),14], getInfoTDV(aCalend, nI,  Nil,cHorIni, cHorFim, cTipo,cIntVl1, cIntVl2, cIntVl3, aAteEfe[1] ))	
			
			
			/*If ABB->(MsSeek( xFilial("ABB") + ; 
					 aAteEfe[2] + ;
					 DtoS(aCalend[nI,CALEND_POS_DATA]) + ;
					 cHorIni + ;
					 DtoS(aCalend[nI+1,CALEND_POS_DATA]) + ;
					 cHorFim ) )
								 
				nPosABB := aScan( aAtend, { |x| x[10] == ABB->ABB_CODIGO .And.;
									  			x[11] == ABB->ABB_ATENDE } )
			
				If nPosABB == 0
					aAtend[nLenAte,10] 	  := ABB->ABB_CODIGO
					aAtend[nLenAte,11] 	  := ABB->ABB_ATENDE
					aAtend[nLenAte,14,1,1] := ABB->ABB_CODIGO
				EndIf
								 
			EndIf	*/
					
		Next nI

	EndIf

Return aNewAtend


//--------------------------------------------------------------------------------------------------------------------
Static Function At330ATip(cTipo, nHorIni, nHorFim)

If cTipo == "N"			
	If (nHorIni + nHorFim) > 0
		cTipo := "E"
	EndIf
ElseIf (nHorIni + nHorFim) == 0
	cTipo := "D"			 				
EndIf			

Return cTipo

Static Function At330ADTip(cTipo)
	Local cDscTip := ""
	Do Case
		Case cTipo == "S" ; cDscTip := STR0016	 	//"Trabalhado"
		Case cTipo == "C" ; cDscTip := STR0017	 	//"Compensado"
		Case cTipo == "D" ; cDscTip := STR0018 	//"D.S.R."
		Case cTipo == "N" ; cDscTip := STR0019 	//"Nao Trabalhado"
		Case cTipo == "E" ; cDscTip := STR0020		//"Hora Extra"
		Case cTipo == "I" ; cDscTip := STR0046		// "Intervalo"
		OtherWise 			; cDscTip := ""
	EndCase
	
Return cDscTip

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} getInfoTDV
Recupera informações relativas a TDV, seja pelo aTabCalend (Nova alocação) ou através da ABB/TDV (Alocação já realizada) 
@since 04/03/2015
@version 11.8
@param aTabCalend, Array, aTabCalend do ponto
@param nIndCalend, Integer, indice do aTabCalend a ser considerado
@param aInfoABB, Array, INformações da agenda (ABB)
@param cHorIni, String, Horario inicial
@param cHorFim, String, Horario Final
@param cIntVl1, String, Indicação de primeiro intervalo
@param cIntVl2, String, Indicação de segundo intervalo
@param cIntVl3, String, Indicação de terceiro intervalo
@param nGrupo, Integer, Grupo de alocação do atendente

@return aInfoTDV, Estrutura com informações da TDV da agenda baseada no aTAbCalend ou então na alocação já realizada (ABB/TDV)

/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function getInfoTDV(aTabCalend, nIndCalend, aInfoABB, cHorIni, cHorFim, cTipo,cIntVl1, cIntVl2, cIntVl3, nGrupo)

	Local aInfoTDV := {}
	Local nHorMen	:= 0
	Local nHorMai := 0		
	Local aTDV := {}
	
	
	If aInfoABB == Nil .OR. Len(aInfoABB[11]) == 0//considera informações provenientes do aTabCalend
	
		// Calculo para os limites de entrada
		If Len(aTabCalend[nIndCalend,CALEND_POS_LIM_MARCACAO]) > 0
			If !Empty(DTOS(aTabCalend[nIndCalend,CALEND_POS_LIM_MARCACAO][1]))
				nHorMen := SubtHoras(aTabCalend[nIndCalend,CALEND_POS_LIM_MARCACAO][1],AtConvHora(aTabCalend[nIndCalend,CALEND_POS_LIM_MARCACAO][2]),aTabCalend[nIndCalend,CALEND_POS_DATA],If(cHorIni=="FOLGA", "00:00",cHorIni ),.T.)
			EndIf
		EndIf			
		
		// Calculo para os limites de saida
		//If Len(aTabCalend[nIndCalend+1,CALEND_POS_LIM_MARCACAO]) > 0
		If Len(aTabCalend) > nIndCalend+1
			If !Empty(DTOS(aTabCalend[nIndCalend+1,CALEND_POS_LIM_MARCACAO][1]))
				nHorMai := SubtHoras(aTabCalend[nIndCalend+1,CALEND_POS_DATA],If(cHorFim=="FOLGA", "00:00",cHorFim ), aTabCalend[nIndCalend+1,CALEND_POS_LIM_MARCACAO][1],AtConvHora(aTabCalend[nIndCalend+1,CALEND_POS_LIM_MARCACAO][2]),.T.)
			EndIf
		EndIf	
							
		aInfoTDV := { If(aInfoABB == Nil,"", aInfoABB[9]),;
											aTabCalend[nIndCalend,CALEND_POS_DATA_APO],;
											aTabCalend[nIndCalend,CALEND_POS_TURNO],;
											aTabCalend[nIndCalend,CALEND_POS_SEQ_TURNO],;
											aTabCalend[nIndCalend,CALEND_POS_TIPO_HE_NOR],;
											aTabCalend[nIndCalend,CALEND_POS_TIPO_HE_NOT],;
											aTabCalend[nIndCalend,CALEND_POS_PG_NONA_HORA],;
											aTabCalend[nIndCalend,CALEND_POS_COD_REFEICAO],;
											aTabCalend[nIndCalend,CALEND_POS_INTSREP],;
											cTipo,;
											aTabCalend[nIndCalend,CALEND_POS_LIM_MARCACAO],;											
											cIntVl1, cIntVl2, cIntVl3,;
											aTabCalend[nIndCalend,CALEND_POS_DESC_FERIADO],;//Feriado Entrada
											aTabCalend[nIndCalend,CALEND_POS_TP_HE_FER_NR],;//Tipo Hora extra entrada
											aTabCalend[nIndCalend,CALEND_POS_TP_HE_FER_NT],;//Tipo Hora extra entrada
											nHorMen,;//Limite Inferior
											nHorMai,;//Limite Superior
											nGrupo,;
											Iif (Len(aTabCalend) >= nIndCalend+1, aTabCalend[nIndCalend+1,CALEND_POS_DESC_FERIADO],''),;//Feriado Saída
											Iif (Len(aTabCalend) >= nIndCalend+1, aTabCalend[nIndCalend+1,CALEND_POS_TP_HE_FER_NR],''),;//Tipo Hora extra saida
											Iif (Len(aTabCalend) >= nIndCalend+1, aTabCalend[nIndCalend+1,CALEND_POS_TP_HE_FER_NT],'');//Tipo Hora extra saida
											 } 	
											 
	Else//Considera Informações provenientes da TDV
		
		aTDV := aInfoABB[11]
		
		// Calculo para os limites de entrada
		nHorMen := aTdv[_TDV_HRMEN]
		nHorMai := aTdv[_TDV_HRMAI]
					
					
					
		aInfoTDV := { aInfoABB[9],;
						Stod(aTdv[_TDV_DTREF]),;//Data referencia
						aTdv[_TDV_TURNO],;//Turno
						aInfoABB[8],;//Sequencia do turno
						aTdv[_TDV_TPEXT],;//Tipo hora extra normal
						aTdv[_TDV_TPEXTN],;//tipo hora extra noturna
						aTdv[_TDV_NONHOR],;//paga nona hora
						aTdv[_TDV_CODREF],;//codigo v. refeição
						aTdv[_TDV_INSREP],;//
						cTipo,;//Tipo
						{},;//Limite marcação											
						cIntVl1, cIntVl2, cIntVl3,;//intervalos
						aTdv[_TDV_FERIAD],;//Feriado Entrada
						aTdv[_TDV_FTPEXT],;//Tipo Hora extra entrada
						aTdv[_TDV_FSEXTN],;//Tipo Hora extra entrada
						nHorMen,;//Limite Inferior
						nHorMai,;//Limite Superior
						nGrupo,;//Grupo
						aTdv[_TDV_FERSAI],;//Feriado Saída
						aTdv[_TDV_FSTPEX],;//Tipo Hora extra saida
						aTdv[_TDV_FSEXTN];//Tipo Hora extra saida
					} 
	EndIf

Return aInfoTDV

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330ACob				   
Retorna as coberturas do efetivo.

@sample 	At330ACob( cCodTFF, cCodEfe, cEscala)

@param		cCodTFF - Codigo do recurso humano para filtro
@param		cEscala - Codigo da Escala para a listagem das coberturas
@param		cTurno 	- Codigo do Turno para a listagem das coberturas
@param		cSeq 	- Codigo da Sequência para a listagem das coberturas

@author  	Serviços
@since 	  	17/07/2014
@version	P12

@return 	aRet: Lista com as coberturas do efetivo 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330ACob( cCodTFF, cEscala, cTurno, cSeq )

Local aRet 	  := {}
Local cAliasTGW := GetNextAlias()
Local aCobEfe   := {}
Local nPos      := 0
Local nPosAte   := 0

BeginSql Alias cAliasTGW

	SELECT 
		TGW.TGW_DIASEM, TGW.TGW_HORINI, TGW.TGW_HORFIM, 
		TGW.TGW_STATUS, TGW.TGW_COBTDX, TGW.TGW_COBTIP,
		TGZ.TGZ_ATEND, TGZ.TGZ_DTINI, TGZ.TGZ_DTFIM, TGZ.TGZ_HORINI, TGZ.TGZ_HORFIM
	FROM 
		%table:TGW% TGW
	JOIN %table:TDX% TDX ON 
		TDX.TDX_FILIAL = %xFilial:TDX% AND
		TDX.TDX_CODTDW = %Exp:cEscala% AND
		TDX.TDX_TURNO  = %Exp:cTurno%  AND
		TDX.TDX_SEQTUR = %Exp:cSeq%	   AND
		TDX.%NotDel%
	JOIN %table:TGX% TGX ON
		TGX.TGX_FILIAL = %xFilial:TGX% AND
		TGX.TGX_CODTDW = %Exp:cEscala% AND 
		TGX.TGX_ITEM = TGW.TGW_COBTDX AND
		TGX.%NotDel%
	LEFT JOIN %table:TGZ% TGZ ON 
		TGZ.TGZ_FILIAL = %xFilial:TGZ% AND
		TGZ.TGZ_CODTDX = TGX.TGX_COD AND 
		TGZ.TGZ_ESCALA = %Exp:cEscala% AND
		TGZ.TGZ_CODTFF = %Exp:cCodTFF% AND
		TGZ.%NotDel%
	WHERE 
		TGW.TGW_FILIAL = %xFilial:TGW% AND 
		TGW.TGW_EFETDX = TDX.TDX_COD   AND 
		TGW.TGW_COBTDX <> ' ' AND 
		TGW.%NotDel%	

EndSql

While (cAliasTGW)->(!Eof())

	nPos := aScan( aCobEfe, { |x| x[1] == (cAliasTGW)->TGW_DIASEM } )
		
	If nPos == 0
		aAdd( aCobEfe, { 	(cAliasTGW)->TGW_DIASEM, {} } )		
		nPos := Len(aCobEfe)
	EndIf		
	
	If !Empty((cAliasTGW)->TGZ_HORINI) .OR. !Empty((cAliasTGW)->TGZ_HORFIM) //busca horario da cobertura 
		nPosAte := aScan( aCobEfe[nPos,2], { |x| 	x[1] == (cAliasTGW)->TGW_COBTDX .And. ; 
														x[2] == (cAliasTGW)->TGW_COBTIP .And. ;
														x[3] == AtConvHora((cAliasTGW)->TGZ_HORINI) .And. ; 
														x[4] == AtConvHora((cAliasTGW)->TGZ_HORFIM) } )
		
		If nPosAte == 0	
			aAdd( aCobEfe[nPos,2], {	(cAliasTGW)->TGW_COBTDX,; 
										(cAliasTGW)->TGW_COBTIP,; 
										AtConvHora((cAliasTGW)->TGZ_HORINI),; 
										AtConvHora((cAliasTGW)->TGZ_HORFIM),; 
										(cAliasTGW)->TGW_STATUS, {} } )
			nPosAte := Len(aCobEfe[nPos,2])		
		EndIf									
	Else //busca horario da escala
		nPosAte := aScan( aCobEfe[nPos,2], { |x| 	x[1] == (cAliasTGW)->TGW_COBTDX .And. ; 
														x[2] == (cAliasTGW)->TGW_COBTIP .And. ;
														x[3] == AtConvHora((cAliasTGW)->TGW_HORINI) .And. ; 
														x[4] == AtConvHora((cAliasTGW)->TGW_HORFIM) } )
		
		If nPosAte == 0	
			aAdd( aCobEfe[nPos,2], {	(cAliasTGW)->TGW_COBTDX,; 
										(cAliasTGW)->TGW_COBTIP,; 
										AtConvHora((cAliasTGW)->TGW_HORINI),; 
										AtConvHora((cAliasTGW)->TGW_HORFIM),; 
										(cAliasTGW)->TGW_STATUS, {} } )
			nPosAte := Len(aCobEfe[nPos,2])		
		EndIf
	Endif
	
	aAdd( aCobEfe[nPos,2,nPosAte,6], { (cAliasTGW)->TGZ_ATEND,;
											StoD((cAliasTGW)->TGZ_DTINI),;
											StoD((cAliasTGW)->TGZ_DTFIM) } )		 
		
	(cAliasTGW)->(dbSkip())

EndDo

(cAliasTGW)->(dbCloseArea())

aRet := aCobEfe

Return(aRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At330ACmt				   
Efetiva a alocação dos atendentes

@sample 	At330ACmt( oModel )

@param		oModel - Model para a gravação da alocação dos atendentes

@author  	Serviços
@since 	  	21/07/2014
@version	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At330ACmt( oModel )

Local oMdlTFF 	:= oModel:GetModel("TFFMASTER")
Local oMdlZZX 	:= oModel:GetModel("ZZXDETAIL")
Local aDesalocar 	:= {}
Local aAlocar 	:= {}
Local aCalAtd 	:= {}
Local aAgenda    	:= {}
Local aSaldoCfg	:= {}
Local aAloTDV		:= {}
Local aDesTDV		:= {}
Local aAlocTipMov   := {}
Local nPosTipMov    := 0
Local nPosAtend  	:= 0
Local nTotHor  	:= 0
Local cIdCFal    	:= ""
Local cHorIni    	:= ""
Local cHorFim    	:= ""
Local aIteABQ    	:= {}
Local lChange    	:= .F.
Local aUltAloc		:= {} //Array com ultima alocação válida
Local nPosUltAlo	:= 0//nPos do array de ultima alocação
Local aPriDes		:= {} //Array com primeira desalocação
Local nPosPriDes	:= 0//nPos do array de primeira desalocação
Local cCodTFJ       := ""
Local nI := 0
Local dAloFim
Local dAloFimOri := STOD("")//Data fim da agenda original
Local lSrvExt       := .F.
Local cOrcSrv       := ""
Local cTpMovAloc 	:= ""

dbSelectArea("ABQ")
ABQ->(dbSetOrder(3))

For nI:=1 To oMdlZZX:Length()

	oMdlZZX:GoLine(nI)
	
	// Posiciona no array estatico de atendentes
	nPosAtend := aScan( aAtend, { |x| x[15] == oMdlZZX:GetValue("ZZX_ITEM") } )
	
	If nPosAtend > 0
		
		cHorIni := StrHora(oMdlZZX:GetValue("ZZX_ENTRADA"))
		cHorFim := StrHora(oMdlZZX:GetValue("ZZX_SAIDA"))
		
		oMdlZZX:SetValue( "ZZX_ENTRADA", cHorIni )
		oMdlZZX:SetValue( "ZZX_SAIDA", cHorFim )
		
		dAloFim := Iif( HoraToInt(oMdlZZX:GetValue("ZZX_SAIDA")) < HoraToInt(oMdlZZX:GetValue("ZZX_ENTRADA")),; 
						oMdlZZX:GetValue("ZZX_DATA")+1, oMdlZZX:GetValue("ZZX_DATA"))
						
		If oMdlZZX:IsDeleted()	
					
			// Verifica se existe alocação para o atendente
			If TxExistAloc( AllTrim(oMdlZZX:GetValue("ZZX_ATEND")),;
							  oMdlZZX:GetValue("ZZX_DATA"),;
							  oMdlZZX:GetValue("ZZX_ENTRADA"),;
							  dAloFim,;
							  oMdlZZX:GetValue("ZZX_SAIDA"),0, Nil, .F.,;
							  oMdlTFF:GetValue("TFF_LOCAL"))
				
				nTotHrsTrb := SubtHoras(	oMdlZZX:GetValue("ZZX_DATA"), oMdlZZX:GetValue("ZZX_ENTRADA"),;
											dAloFim, oMdlZZX:GetValue("ZZX_SAIDA") )
				
				aCalAtd := {}			 
				
				aAdd( aCalAtd, { 	.T., oMdlZZX:GetValue("ZZX_DATA"),;									
									AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")),;
									dAloFim,;
									AllTrim(oMdlZZX:GetValue("ZZX_SAIDA")),;
									AtConvHora(nTotHrsTrb) } ) 
			
				aAgenda := { aCalAtd, nTotHrsTrb, 1 } 
													
				If Len(aAgenda) > 0
				
					aAdd( aDesalocar, { 	oMdlZZX:GetValue("ZZX_ATEND"),;
											oMdlZZX:GetValue("ZZX_NOME"),;
											Posicione("AA1",1,xFilial("AA1")+oMdlZZX:GetValue("ZZX_ATEND"), "AA1_CDFUNC"),;
											oMdlZZX:GetValue("ZZX_TURNO"),;
											oMdlTFF:GetValue("TFF_FUNCAO"),;
											oMdlTFF:GetValue("TFF_CARGO"),;
											aAgenda[1]                   ,;
											aAgenda[2]                   ,;
											aAgenda[3] } )
	
					aAdd( aDesTDV, {	oMdlZZX:GetValue("ZZX_ATEND"),;
			  		 					oMdlZZX:GetValue("ZZX_DATA"),;
			  	    					AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")),;
			        					dAloFim,;
			       					AllTrim(oMdlZZX:GetValue("ZZX_SAIDA")), {} } )						       	
									
					aAdd( aDesTDV[Len(aDesTDV),6], aAtend[nPosAtend,14,1] )										
	
				EndIf
							  
			EndIf
			
			//Controle de primeira alocação
			nPosPriDes := aScan(aPriDes, {|x| x[_ULTALOC_KEYTGY] == oMdlZZX:GetValue("ZZX_KEYTGY") .AND. x[_ULTALOC_ITEMTGY] == oMdlZZX:GetValue("ZZX_ITTGY")})
			If nPosPriDes > 0
				//Inclui primeira data e sequencia
				If (oMdlZZX:GetValue("ZZX_DATREF") < aPriDes[nPosPriDes][_ULTALOC_DATA])
					aPriDes[nPosPriDes][_ULTALOC_DATA] := oMdlZZX:GetValue("ZZX_DATREF")
					aPriDes[nPosPriDes][_ULTALOC_SEQ] 	:= oMdlZZX:GetValue("ZZX_SEQ")
					aPriDes[nPosPriDes][_ULTALOC_LINHA]	:= oMdlZZX:GetLine()
				EndIf
			Else
				//Inicia data e sequencia
				aAdd(aPriDes, Array(_ULTALOC_ATEND))
				nPosPriDes := Len(aPriDes)
				aPriDes[nPosPriDes][_ULTALOC_KEYTGY]:= oMdlZZX:GetValue("ZZX_KEYTGY")
				aPriDes[nPosPriDes][_ULTALOC_DATA]	:= oMdlZZX:GetValue("ZZX_DATREF")
				aPriDes[nPosPriDes][_ULTALOC_SEQ]	:= oMdlZZX:GetValue("ZZX_SEQ")
				aPriDes[nPosPriDes][_ULTALOC_ITEMTGY]:= oMdlZZX:GetValue("ZZX_ITTGY")
				aPriDes[nPosPriDes][_ULTALOC_GRUPO]	:= oMdlZZX:GetValue("ZZX_GRUPO")
				aPriDes[nPosPriDes][_ULTALOC_LINHA]	:= oMdlZZX:GetLine()
				aPriDes[nPosPriDes][_ULTALOC_ATEND]	:= oMdlZZX:GetValue("ZZX_ATEND")

			EndIf						  	
			
		Else
			
			lChange := AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")) <> AllTrim(aAtend[nPosAtend,_ZZXENTRADA]) .Or. ;
						AllTrim(oMdlZZX:GetValue("ZZX_SAIDA")) <> AllTrim(aAtend[nPosAtend,_ZZXSAIDA]) .Or. ;
						oMdlZZX:GetValue("ZZX_ATEND") <> aAtend[nPosAtend,_ZZXATEND] .Or. ;
						oMdlZZX:GetValue("ZZX_TIPO") <> aAtend[nPosAtend,_ZZXSITALO] 
			
			// Verifica se a agenda foi editada, avaliando a necessidade de cancelar a agenda antiga
			If 	lChange
				
				dAloFimOri := If( HoraToInt(aAtend[nPosAtend,_ZZXSAIDA]) < HoraToInt(aAtend[nPosAtend,_ZZXENTRADA]),; 
								aAtend[nPosAtend,_ZZXDATA]+1, aAtend[nPosAtend,_ZZXDATA])						  				
				
				If TxExistAloc( aAtend[nPosAtend,_ZZXATEND],;
					  				aAtend[nPosAtend,_ZZXDATA],;
					  				aAtend[nPosAtend,_ZZXENTRADA],;
					  				dAloFimOri,;
					  				aAtend[nPosAtend,_ZZXSAIDA],0, Nil, .F.,;
					  				oMdlTFF:GetValue("TFF_LOCAL") )						  		
	
					nTotHrsTrb := SubtHoras(	aAtend[nPosAtend,_ZZXDATA], aAtend[nPosAtend,_ZZXENTRADA],;
												dAloFimOri, aAtend[nPosAtend,_ZZXSAIDA] )
					
					aCalAtd := {}
				
					aAdd( aCalAtd, { 	.T., aAtend[nPosAtend,_ZZXDATA],;									
										AllTrim(aAtend[nPosAtend,_ZZXENTRADA]),;
										dAloFimOri,;
										AllTrim(aAtend[nPosAtend,_ZZXSAIDA]),;
										AtConvHora(nTotHrsTrb) } ) 
				
					aAgenda := { aCalAtd, nTotHrsTrb, 1 } 
														
					If Len(aAgenda) > 0
					
						aAdd( aDesalocar, { 	aAtend[nPosAtend,_ZZXATEND],;
												aAtend[nPosAtend,_ZZXNOME],;
												Posicione("AA1",1,xFilial("AA1")+aAtend[nPosAtend,_ZZXATEND], "AA1_CDFUNC"),;
												aAtend[nPosAtend,_ZZXTURNO],;
												oMdlTFF:GetValue("TFF_FUNCAO"),;
												oMdlTFF:GetValue("TFF_CARGO"),;
												aAgenda[1]                   ,;
												aAgenda[2]                   ,;
												aAgenda[3] } )
		
						aAdd( aDesTDV, {	aAtend[nPosAtend,_ZZXATEND],;
				  		 					aAtend[nPosAtend,_ZZXDATA],;
				  	    					AllTrim(aAtend[nPosAtend,_ZZXENTRADA]),;
				        					dAloFimOri,;
				       					AllTrim(aAtend[nPosAtend,_ZZXSAIDA]), {} } )						       	
										
						aAdd( aDesTDV[Len(aDesTDV),6], aAtend[nPosAtend,14,1] )
						
					EndIf							  				
					  				
				EndIf	
				
			EndIf				
		
			If !AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")) == "FOLGA" .AND. ;
				!AllTrim(oMdlZZX:GetValue("ZZX_SAIDA")) == "FOLGA"
					  					
				// Verifica se não existe alocação para o atendente
				If ! TxExistAloc( oMdlZZX:GetValue("ZZX_ATEND"),;
								  oMdlZZX:GetValue("ZZX_DATA"),;
								  oMdlZZX:GetValue("ZZX_ENTRADA"),;
								  dAloFim,;
								  oMdlZZX:GetValue("ZZX_SAIDA"),0, Nil, .F.,;
								  oMdlTFF:GetValue("TFF_LOCAL")) .Or. lChange		
					
					cCodTFJ := Posicione("TFL",1,FwxFilial("TFL")+oMdlTFF:GetValue("TFF_CODPAI"),"TFL_CODPAI")
					lSrvExt := Posicione("TFJ",1,FwxFilial("TFJ")+cCodTFJ,"TFJ_SRVEXT") == "1"
					
					If lSrvExt
						cOrcSrv := cCodTFJ
					EndIf

					aIteABQ := At330AABQ( 	oMdlTFF:GetValue("TFF_CONTRT"),;			 						
											oMdlTFF:GetValue("TFF_PRODUT"),;
											oMdlTFF:GetValue("TFF_LOCAL"),;
											oMdlTFF:GetValue("TFF_FUNCAO"),;  
											oMdlTFF:GetValue("TFF_TURNO"),;
											oMdlTFF:GetValue("TFF_COD"),;
											oMdlTFF:GetValue("TFF_FILIAL"),;
											lSrvExt,;
											cOrcSrv )
					
					If Len(aIteABQ) > 0
							
						cIdCFal := aIteABQ[1][1]+aIteABQ[1][2]+aIteABQ[1][3]
						
						nTotHrsTrb := SubtHoras(	oMdlZZX:GetValue("ZZX_DATA"), oMdlZZX:GetValue("ZZX_ENTRADA"),;
													dAloFim, oMdlZZX:GetValue("ZZX_SAIDA") )								
						
						nTotHor += nTotHrsTrb
						aCalAtd := {}
						
						aAdd( aCalAtd, { 	oMdlZZX:GetValue("ZZX_DATA"),;
											TxRtDiaSem(oMdlZZX:GetValue("ZZX_DATA")),;
											AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")),;
											AllTrim(oMdlZZX:GetValue("ZZX_SAIDA")),;
											AtConvHora(nTotHrsTrb),;
											oMdlZZX:GetValue("ZZX_SEQ") } ) 
								
						dbSelectArea("TGY")
						TGY->(dbSetOrder(1))
						If !Empty( oMdlZZX:GetValue("ZZX_KEYTGY") )
							TGY->(dbSeek(xFilial("TGY")+oMdlZZX:GetValue("ZZX_KEYTGY") ))
							cTpMovAloc := TGY->TGY_TIPALO
							nPosTipMov := AScan(aAlocTipMov,{|x| x[1] == cTpMovAloc })
						Else
							// Quando é qualquer agenda de apoio, procura pelo tipo de cobertura
							cTpMovAloc := "002"
							nPosTipMov := AScan(aAlocTipMov,{|x| x[1] == cTpMovAloc })
						EndIf

						If nPosTipMov <= 0
							AAdd( aAlocTipMov,{ cTpMovAloc, { } } )
							nPosTipMov := Len( aAlocTipMov )
						EndIf
						
						AAdd(aAlocTipMov[nPosTipMov,2],{ 	oMdlZZX:GetValue("ZZX_ATEND")	,;
															oMdlZZX:GetValue("ZZX_NOME")	,;
															Posicione("AA1",1,xFilial("AA1")+oMdlZZX:GetValue("ZZX_ATEND"), "AA1_CDFUNC"),;
															oMdlZZX:GetValue("ZZX_TURNO")	,;
															oMdlTFF:GetValue("TFF_FUNCAO")	,;
															oMdlTFF:GetValue("TFF_CARGO")	,;
															Alltrim(cIdCFal),;
															""		,;
															""		,;
															aCalAtd							,;
															{} 						,;
															oMdlTFF:GetValue("TFF_LOCAL") ,;
															TGY->TGY_CODTW3})
	
														
						aAdd( aAloTDV, {	oMdlZZX:GetValue("ZZX_ATEND"),;
								  		 	oMdlZZX:GetValue("ZZX_DATA"),;
								  	    	AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")),;
								        	dAloFim,;
								       	AllTrim(oMdlZZX:GetValue("ZZX_SAIDA")), {} } )
								       	
						If Empty(aAtend[nPosAtend,14,1,2])
							aAtend[nPosAtend,14,1,2] := oMdlZZX:GetValue("ZZX_DATREF")
						EndIf										       	
								       	
						aAdd( aAloTDV[Len(aAloTDV),6], aAtend[nPosAtend,14,1] )
														
						If oMdlZZX:GetValue("ZZX_TIPO") == "E"
							aAloTDV[Len(aAloTDV),6,1,10] := "N"
						ElseIf oMdlZZX:GetValue("ZZX_TIPO") == "I"
							aAloTDV[Len(aAloTDV),6,1,10] := "S"
						ElseIf oMdlZZX:GetValue("ZZX_TIPO") <> aAtend[nPosAtend,_ZZXSITALO]
							aAloTDV[Len(aAloTDV),6,1,10] := oMdlZZX:GetValue("ZZX_TIPO") 
						Endif
											
					EndIf								
								
				EndIf	
			EndIf
			
			//Controle de ultima alocação
			nPosUltAlo := aScan(aUltAloc, {|x| x[_ULTALOC_KEYTGY] == oMdlZZX:GetValue("ZZX_KEYTGY") .AND. x[_ULTALOC_ITEMTGY] == oMdlZZX:GetValue("ZZX_ITTGY")})
			If nPosUltAlo > 0
				//Inclui ultima data e sequencia
				If (oMdlZZX:GetValue("ZZX_DATREF") > aUltALoc[nPosUltAlo][_ULTALOC_DATA])
					aUltALoc[nPosUltAlo][_ULTALOC_DATA] := oMdlZZX:GetValue("ZZX_DATREF")
					aUltALoc[nPosUltAlo][_ULTALOC_SEQ] 	:= oMdlZZX:GetValue("ZZX_SEQ")
					aUltALoc[nPosUltAlo][_ULTALOC_LINHA]	:= oMdlZZX:GetLine()
				EndIf
			Else
				//Inicia data e sequencia
				aAdd(aUltAloc, Array(_ULTALOC_ATEND))
				nPosUltAlo := Len(aUltAloc)
				aUltAloc[nPosUltAlo][_ULTALOC_KEYTGY]	:= oMdlZZX:GetValue("ZZX_KEYTGY")
				aUltAloc[nPosUltAlo][_ULTALOC_DATA]		:= oMdlZZX:GetValue("ZZX_DATREF")
				aUltAloc[nPosUltAlo][_ULTALOC_SEQ]		:= oMdlZZX:GetValue("ZZX_SEQ")			
				aUltAloc[nPosUltAlo][_ULTALOC_ITEMTGY]	:= oMdlZZX:GetValue("ZZX_ITTGY")
				aUltAloc[nPosUltAlo][_ULTALOC_GRUPO]	:= oMdlZZX:GetValue("ZZX_GRUPO")
				aUltALoc[nPosUltAlo][_ULTALOC_LINHA]	:= oMdlZZX:GetLine()
				aUltALoc[nPosUltAlo][_ULTALOC_ATEND]	:= oMdlZZX:GetValue("ZZX_ATEND")
			EndIf
		
		EndIf 	
	EndIf
Next nI

At330UpTGY(aUltAloc, aPriDes, oMdlZZX, Nil)//Atualiza informações do Efetivo(TGY) com base nas alocações e desalocações realizadas

If Len(aDesalocar) > 0

	MsgRun(STR0048, STR0008,; 	//"Desalocando os atendentes..."###"Processando"
			{ || aSaldoCfg := At330GvDes(aDesalocar) } ) 
			
	MsgRun( STR0049, STR0008,; 	//"Removendo informações da escala..."###"Processando"
			{ || At330AUpTDV( .T., aDesTDV ) } ) 
						
EndIf

If Len(aAlocTipMov) > 0

	For nI := 1 To Len(aAlocTipMov)
		MsgRun(STR0050, STR0008,; 	//"Gerando agenda dos atendentes..."###"Processando"
				{ || At330GvAlo(aAlocTipMov[nI,2],"CN9",aAlocTipMov[nI,1]) } ) 
	Next nI
			
	dbSelectArea("ABB")
	ABB->(dbSetOrder(1))

	For nI:=1 To Len(aAloTDV)
		If ABB->( dbSeek( xFilial("ABB") + ; 
			 				aAloTDV[nI,1] + ;
			 				DtoS(aAloTDV[nI,2]) + ;
			 				aAloTDV[nI,3] + ;
			 				DtoS(aAloTDV[nI,4]) + ;
			 				aAloTDV[nI,5] ) )
			aAloTDV[nI,6,1,1] := ABB->ABB_CODIGO						 				
		EndIf		
	Next nI
	
	// Atualiza o saldo de horas do configurador de alocação	
	TxSaldoCfg( cIdCFal, nTotHor, .F. )			

	MsgRun( STR0051, STR0008,; 	//"Gerando informações sobre a escala..."###"Processando"
			{ || At330AUpTDV( .F., aAloTDV ) } ) 
				
EndIf

aFilGrp := {}
aFilAte := {}
aAtend  := {}
nGrpFil := 0
cAteFil := ""

Return( .T. )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330UpTGY
Realiza a atualização da sequencia e data de alocação dos efetivos (TGY)


@since 08/01/2015
@version 11.8
@param aUltAloc - Array com as informações de ultima alocação do grupo de funcionários
@param aPriDes - Array com as informações de primeira desalocação do grupo de funcionários
@param oMdlZZX - Model com as informações da alocação por escala
@param aAteAge - Array com as informações da alocação automatica

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At330UpTGY(aUltAloc, aPriDes, oMdlZZX, aAteAge)
	Local nI := 1
	Local nY := 1
	Local aArea := GetArea()
	Local aAreaTGY := TGY->(GetArea())
	Local aInfo := {}
	Local nPos := 0
	Local nPosDes := 0 //nPos para identifição de desalocar
	Local nPosAloc := 0//nPos para identifição de desalocar
	Local nSeqPrev := 0 //quantidade de sequencia 
	Local cTurno := ""
	Local nPosTurno := ""
	Local aSeqs	:= {}
	Local cSeq := ""
	Local dUltDatRef := STOD("")//COntrole da ultima data de referencia verificada	
	Local aLinhaAg := {}//Linha da agenda
	
	//Verifica sequencia por Escala e Grupo para atualizar controle de ultima alocação
	For nI := 1 To Len(aUltAloc)
		
		nPos := aScan(aInfo, {|x| x[_ULTALOC_KEYTGY] == aUltAloc[nI][_ULTALOC_KEYTGY] .AND.  x[_ULTALOC_GRUPO] == aUltAloc[nI][_ULTALOC_GRUPO]})
		
		If nPos > 0
			//considera maior data
			If aInfo[nPos][_ULTALOC_DATA] < aUltAloc[nI][_ULTALOC_DATA]
				aInfo[nPos] := aUltAloc[nI]
			EndIf
		Else
			aAdd(aInfo, aUltAloc[nI])
		EndIf		
		
	Next nI
	
	If aPriDes != Nil
		//verifica sequencia dos itens desalocados para atualizar controle de ultima alocação
		For nI := 1 To Len(aPriDes)
			
			//Caso não encontra alocação verifica a sequencia da primeira desalocação		
			If 0 == aScan(aUltAloc, {|x| x[_ULTALOC_KEYTGY] == aPriDes[nI][_ULTALOC_KEYTGY] .AND. x[_ULTALOC_ITEMTGY] == aPriDes[nI][_ULTALOC_ITEMTGY]})
				
				nPos := aScan(aInfo, {|x| x[_ULTALOC_KEYTGY] == aPriDes[nI][_ULTALOC_KEYTGY] .AND. x[_ULTALOC_GRUPO] == aPriDes[nI][_ULTALOC_GRUPO] })
				
				If nPos > 0
					//considera menor data
					If aInfo[nPos][_ULTALOC_DATA] > aPriDes[nI][_ULTALOC_DATA]
						aInfo[nPos] := aPriDes[nI]					
					EndIf
				Else
					aAdd(aInfo, aPriDes[nI])
				EndIf
			EndIf
			
		Next nI	
	EndIf	
	
	//Processamento das informações de efetivos
	For nI:=1 To Len(aInfo)
				
		nPosDes := aScan(aPriDes, {|x| x[_ULTALOC_KEYTGY] == aInfo[nI][_ULTALOC_KEYTGY] .AND. x[_ULTALOC_GRUPO] == aInfo[nI][_ULTALOC_GRUPO]  .AND. x[_ULTALOC_DATA] == aInfo[nI][_ULTALOC_DATA]})
		nPosAloc := aScan(aUltAloc, {|x| x[_ULTALOC_KEYTGY] == aInfo[nI][_ULTALOC_KEYTGY] .AND. x[_ULTALOC_GRUPO] == aInfo[nI][_ULTALOC_GRUPO]  .AND. x[_ULTALOC_DATA] == aInfo[nI][_ULTALOC_DATA]})
			
		nSeq := 0
		dUltDatRef := STOD("")
		
		//Tratamento para alocação realizada por tela
		If oMdlZZX != Nil 
			//tratamento para inicio da desalocação em dia de folga
			If nPosDes > 0 .AND. Empty(aInfo[nI][_ULTALOC_SEQ]) 
				
				oMdlZZX:GoLine(aInfo[nI][_ULTALOC_LINHA])
				cTurno := oMdlZZX:GetValue("ZZX_TURNO")
				cSeq := oMdlZZX:GetValue("ZZX_SEQ")
							
				//posiciona na primeira data de folga e percorre model contando a continuação da sequencia até encontrar primeiro dia trabalhado
				For nY:=aInfo[nI][_ULTALOC_LINHA] To  oMdlZZX:Length()
					oMdlZZX:GoLine(nY)
					
					If oMdlZZx:GetValue("ZZX_KEYTGY") == aInfo[nI][_ULTALOC_KEYTGY]
						If dUltDatRef != oMdlZZX:GetValue("ZZX_DATREF") .AND. Dow(oMdlZZX:GetValue("ZZX_DATREF")) == 2//considera nova sequencia toda segunda-feira
							nSeq++
						EndIf
							
						If oMdlZZX:GetValue("ZZX_ENTRADA") != "FOLGA" .AND.  oMdlZZX:GetValue("ZZX_SAIDA") != "FOLGA"	
							cSeq := oMdlZZX:GetValue("ZZX_SEQ")
							Exit
						EndIf
						
						dUltDatRef := oMdlZZX:GetValue("ZZX_DATREF")
							
					EndIf			
				Next nY
	
				//Busca sequencia anterior conforme nSeq
				If nSeq > 0				
					nPosSeq := LoadSeqs(aSeqs, cTurno)	//Recupera aSeq							
					aInfo[nI][_ULTALOC_SEQ] := GetSeq(aSeqs[nPosSeq][2],cSeq,nSeq, .F.)//Busca sequencia	
				Else
					aInfo[nI][_ULTALOC_SEQ] := cSeq
				EndIf
				
			ElseIf nPosAloc > 0 .AND.  Empty(aInfo[nI][_ULTALOC_SEQ])//Tratamento para final da alocação com folga 
	
				oMdlZZX:GoLine(aInfo[nI][_ULTALOC_LINHA])
				cTurno := oMdlZZX:GetValue("ZZX_TURNO")
				cSeq := oMdlZZX:GetValue("ZZX_SEQ")
						
				//posiciona na ultima data de folga e percorre o model contando a sequencia até a ultima alocação
				For nY:=aInfo[nI][_ULTALOC_LINHA] To  1 Step -1
					oMdlZZX:GoLine(nY)
					
					If oMdlZZx:GetValue("ZZX_KEYTGY") == aInfo[nI][_ULTALOC_KEYTGY]
						If dUltDatRef != oMdlZZX:GetValue("ZZX_DATREF") .AND. Dow(oMdlZZX:GetValue("ZZX_DATREF")) == 2//considera nova sequencia toda segunda-feira
							nSeq++
						EndIf
							
						If oMdlZZX:GetValue("ZZX_ENTRADA") != "FOLGA" .AND.  oMdlZZX:GetValue("ZZX_SAIDA") != "FOLGA"	
							cSeq := oMdlZZX:GetValue("ZZX_SEQ")
							Exit
						EndIf
						
						dUltDatRef := oMdlZZX:GetValue("ZZX_DATREF")
							
					EndIf			
				Next nY
				
				//Busca sequencia posterior conforme nSeq
				If nSeq > 0				
					nPosSeq := LoadSeqs(aSeqs, cTurno)//Recupera aSeq				
					aInfo[nI][_ULTALOC_SEQ] := GetSeq(aSeqs[nPosSeq][2],cSeq,nSeq, .T.)	
				Else
					aInfo[nI][_ULTALOC_SEQ] := cSeq			
				EndIf
				
			EndIf
	
			//Aplica regras para troca de sequencia para o dia posterior ou anterior
			If nPosAloc > 0
				If Dow(aInfo[nI][_ULTALOC_DATA]) == 1//Ultima Alocação no domingo
					oMdlZZX:GoLine(aInfo[nI][_ULTALOC_LINHA])
					nPosSeq := LoadSeqs(aSeqs, oMdlZZX:GetValue("ZZX_TURNO"))
					aInfo[nI][_ULTALOC_SEQ] := GetSeq(aSeqs[nPosSeq][2],aInfo[nI][_ULTALOC_SEQ], 1, .T. )//Recupera proxima Sequencia
				EndIf
			EndIf
			
		//Tratamento para alocação automatica	
		ElseIf aAteAge != Nil 
						
			If nPosAloc > 0 .AND.  Empty(aInfo[nI][_ULTALOC_SEQ])//Tratamento para final da alocação com folga 
				
				aLinhaAg := aAteAge[aInfo[nI][_ULTALOC_LINHA]]
				cTurno := aLinhaAg[12]
				cSeq := aLinhaAg[13]
						
				//posiciona na ultima data de folga e percorre o model contando a sequencia até a ultima alocação
				For nY:=aInfo[nI][_ULTALOC_LINHA] To  1 Step -1
					aLinhaAg := aAteAge[nY]				
					
					If aLinhaAg[17] == aInfo[nI][_ULTALOC_KEYTGY]
						If dUltDatRef != aLinhaAg[16] .AND. Dow(aLinhaAg[16]) == 2//considera nova sequencia toda segunda-feira
							nSeq++
						EndIf
							
						If aLinhaAg[4] != "FOLGA" .AND.  aLinhaAg[5] != "FOLGA"	
							cSeq := aLinhaAg[13]
							Exit
						EndIf
						
						dUltDatRef := aLinhaAg[16]
							
					EndIf			
				Next nY
				
				//Busca sequencia posterior conforme nSeq
				If nSeq > 0				
					nPosSeq := LoadSeqs(aSeqs, cTurno)//Recupera aSeq				
					aInfo[nI][_ULTALOC_SEQ] := GetSeq(aSeqs[nPosSeq][2],cSeq,nSeq, .T.)	
				Else
					aInfo[nI][_ULTALOC_SEQ] := cSeq			
				EndIf
				
			EndIf
	
			//Aplica regras para troca de sequencia para o dia posterior ou anterior
			If nPosAloc > 0
				If Dow(aInfo[nI][_ULTALOC_DATA]) == 1//Ultima Alocação no domingo
					nPosSeq := LoadSeqs(aSeqs, aAteAge[aInfo[nI][_ULTALOC_LINHA]][12]/*Turno*/ )
					aInfo[nI][_ULTALOC_SEQ] := GetSeq(aSeqs[nPosSeq][2],aInfo[nI][_ULTALOC_SEQ], 1, .T. )//Recupera proxima Sequencia
				EndIf
			EndIf
			
		EndIf

		
		//Atualiza informações do efetivo		
		TGY->(DbSetOrder(1))//TGY_FILIAL + TGY_ESCALA + TGY_CODTDX + TGY_CODTFF + TGY_ITEM
		TGY->( DbSeek(xFilial("TGY")+aInfo[nI][_ULTALOC_KEYTGY]) )
		
		While (TGY->(!EOF()) .AND. xFilial("TGY")+aInfo[nI][_ULTALOC_KEYTGY] == TGY->TGY_FILIAL + TGY->TGY_ESCALA + TGY->TGY_CODTDX+ TGY->TGY_CODTFF)
			
			If TGY->TGY_GRUPO == aInfo[nI][_ULTALOC_GRUPO] .And. TGY->TGY_ATEND == aInfo[nI][_ULTALOC_ATEND]
				RecLock("TGY", .F.)									
					
					If !Empty(aInfo[nI][_ULTALOC_SEQ])
						TGY->TGY_SEQ	:= aInfo[nI][_ULTALOC_SEQ]
					Endif
					
					If nPosDes > 0//ao desalocar considera ultima data valida como a anterior a desalocação
						TGY->TGY_ULTALO	:= aInfo[nI][_ULTALOC_DATA]-1
					Else
						TGY->TGY_ULTALO	:= aInfo[nI][_ULTALOC_DATA]
					EndIf
				MsUnlock()
			EndIf			
			
			TGY->(DbSkip())
		End

	Next nI	
	
	RestArea(aAreaTGY)
	RestArea(aArea)
Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} LoadSeqs
Carrega sequencias do turno por demanda e retorna posição do turno das seqeuncias do turno

@since 14/01/2015

@param aSeqs Array com sequencias dos turnos
@param cTurno Turno a ser consultado no aSeqs

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function LoadSeqs(aSeqs, cTurno)
	Local nPosSeq := 0

	//Carrega aSeqs por demanda
	nPosSeq := aScan(aSeqs, {|x| x[1] == cTurno})
	If nPosSeq == 0
		aAdd(aSeqs, {cTurno, At580GtSeq(cTurno)})
		nPosSeq := Len(aSeqs)
	EndIf
	
Return nPosSeq

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetSeq
Retorna numero da sequencia conforme parametros

@since 13/01/2015
@version 11.8
@param aSeqs
@param cSeqAtu Sequencia atual
@param nNumSeq - Quantidade de sequencias a ser recuperada
@param lNext - Indica se deverá ser recuperada proximas sequencias, ou sequencias anteriores
@return String numero da sequencia
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetSeq(aSeqs, cSeqAtu, nNumSeq, lNext)
	Local cSeq := cSeqAtu
	Local nPos := 0
	Local nCount := 0
	
	If Len(aSeqs) > 0
		nPos := aScan(aSeqs, {|x| x[2]==cSeqAtu})
		If nPos > 0
		
			//Raliza calculo para percorrer a sequencia até achar a correspondente
			If lNext
				nCount := nNumSeq + nPos
				While (nCount>Len(aSeqs))
					nCount -= Len(aSeqs)			
				End
			Else
				nCount := nPos - nNumSeq						
				While (nCount<=0)
					nCount += Len(aSeqs)			
				End
			EndIf
			
			cSeq := aSeqs[nCount][2]
			
		EndIf
	EndIf
	
	
Return cSeq


//-------------------------------------------------------------------
/*/{Protheus.doc} At330AUpTDV				  
Efetua a manuntenção da tabela com as informações da escala

@sample 	At330AUpTDV(lDeleta,aEscAte)

@param		lDeleta, Boolean, Verifica se a operação é exclusao 
@param		aEscAte, Array, Lista com as informações dos atendentes para
							  gravação

@since		22/07/2014
@version	P11.9
/*/
//-------------------------------------------------------------------
Function At330AUpTDV( lDeleta, aEscAte )

Local lNoFound := .T.
Local aSave    := GetArea()
Local aSaveTDV := TDV->(GetArea())
Local nHorMEN  := 0
Local nHorMAI  := 0

Local nI
Local lSum444 := TDV->(FieldPos("TDV_FERSAI")) > 0 .AND. TDV->(FieldPos("TDV_FSTPEX")) > 0 .AND. TDV->(FieldPos("TDV_FSEXTN")) > 0 // Verificação de campos para sumula 444

DEFAULT lDeleta := .F.

DbSelectArea('TDV')
TDV->(DbSetOrder(1)) //TDV_FILIAL+TDV_CODABB

For nI:=1 To Len(aEscAte)

	nHorMen := 0
	nHorMai := 0

	If Empty(aEscAte[nI,6,1,01])
		Loop
	EndIf
	
	lNoFound := !TDV->(DbSeek(xFilial('TDV')+aEscAte[nI,6,1,01]))
	
	If ! lDeleta
	
		Reclock( "TDV", lNoFound )
		
		TDV_FILIAL	:= xFilial("TDV")
		TDV_CODABB	:= aEscAte[nI,6,1,01] 
		
		If !Empty(aEscAte[nI,6,1,02])
			TDV_DTREF	:= aEscAte[nI,6,1,02]
		EndIf
		
		TDV_TURNO	:= aEscAte[nI,6,1,03]
		TDV_SEQTRN	:= aEscAte[nI,6,1,04]
		TDV_TPEXT	:= aEscAte[nI,6,1,05]
		TDV_TPEXTN	:= aEscAte[nI,6,1,06]
		TDV_NONHOR	:= aEscAte[nI,6,1,07]
		TDV_CODREF	:= aEscAte[nI,6,1,08]
		TDV_INSREP	:= aEscAte[nI,6,1,09]
		TDV_TPDIA	:= aEscAte[nI,6,1,10]
		TDV_HRMEN	:= aEscAte[nI,6,1,18]
		TDV_HRMAI	:= aEscAte[nI,6,1,19]
		TDV_INTVL1	:= aEscAte[nI,6,1,12]
		TDV_INTVL2	:= aEscAte[nI,6,1,13]
		TDV_INTVL3	:= aEscAte[nI,6,1,14]
		TDV_FERIAD	:= aEscAte[nI,6,1,15]
		TDV_FTPEXT	:= aEscAte[nI,6,1,16]
		TDV_FEXTN	:= aEscAte[nI,6,1,17]		
		TDV_GRUPO	:= aEscAte[nI,6,1,20]
		If lSum444
			TDV_FERSAI	:= aEscAte[nI,6,1,21]
			TDV_FSTPEX	:= aEscAte[nI,6,1,22]
			TDV_FSEXTN	:= aEscAte[nI,6,1,23]
		EndIf		
		
		TDV->(MsUnlock())
	
	Else 

		If !lNoFound
			Reclock('TDV',.F.)
			TDV->(DbDelete())
			TDV->(MsUnlock())
		EndIf	
		
	EndIf		

Next nI

RestArea(aSaveTDV)
RestArea(aSave)

Return(Nil)


//-------------------------------------------------------------------
/*/{Protheus.doc} At330AloAut
Efetua a alocação automatica dos atendentes

@sample 	At330AloAut( cEscIni, cEscFim, cCntIni, cCntFim, cLocIni, cLocFim, dDataIni, dDataFim, cConfirma, cMemorando )

@param		cEscIni - Escala Inicial para a alocação
@param		cEscFim - Escala Final para a alocação
@param		cCntIni - Contrato Inicial para a alocação
@param		cCntFim - Contrato Final para a alocação
@param		cLocIni - Local Inicial para alocação
@param		cLocFim - Local Final para alocação
@param		dDataIni - Data inicial para a alocação
@param		dDataFim - Data final para a alocação
@param		cClienteDe - Contrato Inicial para a alocação
@param		cLojaDe - Contrato Final para a alocação
@param		cClienteAt - Local Inicial para alocação
@param		cLojaAte - Local Final para alocação
@param		cSupDe - Supervisor de
@param		cSupAte - Supervisor ate
@param 		lExibeHelp - Indica se as mensagens serão exibidas em tela 
@param		cConfirma  - "0" - Não Confirma       , "1" - Confirma       , " " - Efetua pergunta de confirmação
@param 		cMemorando - "0" - Não gera memorandos, "1" - Gera memorandos, " " - Efetua pergunta de confirmação	
@param 		lSrvExt    - Quando verdadeiro indica que se trata de alocação de um item da TFF oriundo de um orçamento de serviços extra.
@param      cCodAtend  - Utilizado para a geração de agenda pelo movimentar (TECA336).
@param		cCodigoTFF - Utilizado para a geração de agenda pelo movimentar (TECA336).

@since		22/07/2014
@version	P11.9
@history 	16/09/2016, Ana Utsumi, Inclusão de parâmetros para tratar as mensagens de decisão quando a função utilizada via job 

/*/
//-------------------------------------------------------------------
Function At330AloAut( cEscIni, cEscFim, cCntIni, cCntFim, cLocIni, cLocFim, dDataIni, dDataFim, cClienteDe, cLojaDe, cClienteAt, cLojaAte, cSupDe, cSupAte, lExibeHelp, cConfirma, cMemorando, lSrvExt, cCodAtend, cCodigoTFF, lAteCob, lLibSit, cSituacao , cTW3Int, cRtTipo)

Local aArea		:= GetArea()
Local lRet 	    := .T.
Local cAliasTFF := GetNextAlias()
Local cAliasABB := ""
Local cCodTW3	:= ""
Local aAteEsc   := {}
Local aAteAge   := {}
Local aAteCob   := {}
Local aAteEfe   := {}
Local aCalAtd   := {}
Local aAloTDV   := {}
Local aAlocar   := {}
Local aMotAlocar:= {}
Local aIteABQ   := {}
Local cIdCFal   := ""
Local nTotHor  	:= 0
Local nPosMot   := 0
Local nPosUltAlo:= 0
Local aUltAloc	:= {}
Local dDtIniAlo	:= STOD("")
Local dDtFimAlo	:= STOD("")
Local lHasCnflt	:= .F.
Local aLstCnflt	:= {}
Local aCnflt	:= nil
Local aRestrOp 	:= {}
Local nPosRest  := 0
Local lMovimentar   := FindFunction("TECA336") .AND. (IsInCallStack("TECA336") .Or. IsInCallStack('TEC335CSV'))
Local cTipAlo   := ""

Local nPos, nTotHrsTrb, cEscala, cCalend, nI, dAloFim, cCodTFF, cFilTFF, nX
Local aFerias		:= {.F.,.F.,.F.,.F.}
Local aCobFer		:= {}
Local lGesHr	:= SuperGetMV('MV_GSGEHOR',,.F.) .And. at330ColHR()  

Default lExibeHelp	:= .T. 
Default cConfirma	:= " "	
Default cMemorando	:= " "
Default lSrvExt     := .F.
Default cCodAtend   := ""
DEFAULT cCodigoTFF  := "" // Passado pelo movimentar (TECA336).
Default lAteCob     := .F. // Passado pelo movimentar (TECA336). Indica se está sendo feita movimentação de atendente de posto de cobertura.
Default	cTW3Int		:= ""
If cEscIni == Nil
	cEscIni := " "
EndIf
If cEscFim == Nil
	cEscFim := " "
EndIf
If cCntIni == Nil
	cCntIni := " "	
EndIf
If cCntFim == Nil
	cCntFim := " "
EndIf
If cLocIni == Nil
	cLocIni := " "
EndIf
If cLocFim == Nil
	cLocFim := " "
EndIf
If dDataIni == Nil
	dDataIni := CtoD("  /  /    ")
EndIf
If dDataFim == Nil
	dDataFim := CtoD("  /  /    ")
EndIf
If cClienteDe == Nil
	cClienteDe := " "
EndIf
If cLojaDe == Nil
	cLojaDe := " "
EndIf
If cClienteAt == Nil
	cClienteAt := " "
EndIf
If cLojaAte == Nil
	cLojaAte := " "
EndIf
If cSupDe == Nil
	cSupDe := " "
EndIf
If cSupAte == Nil
	cSupAte := " "
EndIf

If lMovimentar .Or. lAteCob
	BeginSql Alias cAliasTFF
		
		SELECT 
			TFF.TFF_FILIAL, TFF.TFF_COD, TFF.TFF_ESCALA, 
			TFF.TFF_CALEND, TFF.TFF_CONTRT, TFF.TFF_LOCAL, 
			TFF.TFF_PRODUT, TFF.TFF_PERINI,	TFF.TFF_PERFIM, 
			TFF.TFF_FUNCAO, TFF.TFF_CARGO,  TFF.TFF_TURNO, 
			TFJ.TFJ_CODENT, TFJ.TFJ_LOJA ,  TFJ.TFJ_CODIGO,
			TFJ_SRVEXT, ABS.ABS_DESCRI
		FROM 
			%table:TFF% TFF
		JOIN %table:ABS% ABS 
			   ON ABS.ABS_FILIAL = %xFilial:ABS%
			   AND ABS.ABS_LOCAL  = TFF.TFF_LOCAL	      
			   AND ABS.D_E_L_E_T_ = ' '
		JOIN %table:TFL% TFL ON 
			TFL.TFL_FILIAL = %xFilial:TFL%    AND 
			TFL.TFL_CODIGO = TFF.TFF_CODPAI   AND 
			TFL.%NotDel%
		JOIN %table:TFJ% TFJ ON 
			TFJ.TFJ_FILIAL = %xFilial:TFJ%    AND 
			TFJ.TFJ_CODIGO = TFL.TFL_CODPAI   AND 
			TFJ.%NotDel%		
		WHERE 
			TFF.TFF_FILIAL = %xFilial:TFF%    AND 
			TFF.TFF_COD    = %Exp:cCodigoTFF% AND
			TFF.%NotDel%
	EndSql
Else

	BeginSql Alias cAliasTFF
	
	SELECT 
		TFF.TFF_FILIAL, TFF.TFF_COD, TFF.TFF_ESCALA, 
		TFF.TFF_CALEND, TFF.TFF_CONTRT, TFF.TFF_LOCAL, 
		TFF.TFF_PRODUT, TFF.TFF_PERINI,	TFF.TFF_PERFIM, 
		TFF.TFF_FUNCAO, TFF.TFF_CARGO, TFF.TFF_TURNO, 
		TFJ.TFJ_CODENT, TFJ.TFJ_LOJA ,  TFJ.TFJ_CODIGO,
		TFJ_SRVEXT, ABS.ABS_DESCRI
	FROM 
		%table:TFF% TFF
	JOIN %table:ABS% ABS 
		   ON ABS.ABS_FILIAL = %xFilial:ABS%
		   AND ABS.ABS_LOCAL  = TFF.TFF_LOCAL	      
		   AND ABS.D_E_L_E_T_ = ' '
	JOIN %table:TFL% TFL ON 
		TFL.TFL_FILIAL = %xFilial:TFL% AND 
		TFL.TFL_CODIGO = TFF.TFF_CODPAI AND 
		TFL.%NotDel%
	JOIN %table:TFJ% TFJ ON 
		TFJ.TFJ_FILIAL = %xFilial:TFJ% AND 
		TFJ.TFJ_CODIGO = TFL.TFL_CODPAI AND 
		TFJ.%NotDel%
	LEFT JOIN %table:TGS% TGS ON 
		TGS.TGS_FILIAL = %xFilial:TGS% AND 
		TGS.TGS_REGIAO = ABS.ABS_REGIAO AND
		TGS.TGS_SUPERV >= %Exp:cSupDe% 	AND 
		TGS.TGS_SUPERV <= %Exp:cSupAte% AND
		TGS.%NotDel%		
	WHERE 
		TFF.TFF_FILIAL = %xFilial:TFF%  AND 
		TFF.TFF_CODSUB = '      '		AND
		TFF.TFF_ESCALA >= %Exp:cEscIni% AND 
		TFF.TFF_ESCALA <= %Exp:cEscFim% AND 
		TFF.TFF_CONTRT >= %Exp:cCntIni% AND 
		TFF.TFF_CONTRT <= %Exp:cCntFim% AND
		(LTRIM(RTRIM(TFF.TFF_CONTRT)) <> ' ' OR LTRIM(RTRIM(TFF.TFF_CONTRT)) = ' ' AND TFJ.TFJ_SRVEXT = '1') AND  
		TFF.TFF_LOCAL >= %Exp:cLocIni% AND 
		TFF.TFF_LOCAL <= %Exp:cLocFim% AND 
		((TFF.TFF_PERINI BETWEEN %Exp:dDataIni% AND %Exp:dDataFim%) OR
		(LTRIM(RTRIM(TFF.TFF_PERFIM)) <> ' ' AND 
		TFF.TFF_PERFIM BETWEEN %Exp:dDataIni% AND %Exp:dDataFim%) OR
		(TFF.TFF_PERINI < %Exp:dDataIni% AND 
		(LTRIM(RTRIM(TFF.TFF_PERFIM))=' ' OR TFF.TFF_PERFIM > %Exp:dDataFim%))) AND
		(TFJ.TFJ_CODENT >= %Exp:cClienteDe% AND TFJ.TFJ_CODENT <= %Exp:cClienteAt%) AND
		(TFJ.TFJ_LOJA >= %Exp:cLojaDe% AND TFJ.TFJ_LOJA <= %Exp:cLojaAte%) AND		
		TFF.%NotDel% 
	EndSql
EndIf

If (cAliasTFF)->(Eof()) .And. (cAliasTFF)->(Bof()) 
	
	If lExibeHelp
		Help(,,"At330ALOAUT",,STR0052,1,0) // "Não existem agendas disponiveis com essas informações!"
	EndIf
	
Else
	If lMovimentar .OR. ((cConfirma=="1") .Or. (cConfirma==" " .And. MsgYesNo(STR0053, STR0054))) //"Deseja realmente gerar todas as alocações ?"#"Atenção"
		 
		dbSelectArea("ABQ")
		ABQ->(dbSetOrder(3))
		
		While (cAliasTFF)->(!Eof())
		
			aAtend  := {}	
			aAteCob := {}
			aAteEfe := {}
			aAloTDV := {}
			aMotAlocar := {}
			nPosMot    := 0
			nTotHor := 0
			aUltAloc := {}
			//recupera data real de alocação dentro do periodo informado considerando inicio e fim de alocação
			dDtIniAlo := If(dDataIni > STOD((cAliasTFF)->TFF_PERINI), dDataIni, STOD((cAliasTFF)->TFF_PERINI))
			dDtFimAlo := If(dDataFim < STOD((cAliasTFF)->TFF_PERFIM), dDataFim, STOD((cAliasTFF)->TFF_PERFIM))
			
			MsgRun( STR0007, STR0008,; 	// "Gerando lista dos atendentes da escala..."#"Processando" 
			{ || aAteEsc := At330AAtend( (cAliasTFF)->TFF_COD, (cAliasTFF)->TFF_ESCALA, dDtIniAlo, dDtFimAlo, cCodAtend, lAteCob ) } )  

			// Verifica se existe restrição operacional para os atendentes
			// TECXFUNA->TxRestri(cLocAloc)
			aRestrOp := TxRestri((cAliasTFF)->TFF_LOCAL)
			
			For nI:=1 To Len(aAteEsc)
				// Verifica se a restrição é de bloqueio
				nPosRest:= aScan(aRestrOp,{|x| x[1] == aAteEsc[nI][_ZZXATEND]})
				IF nPosRest > 0
					IF aRestrOp[nPosRest][8] == '2'
						If AScan(aLstCnflt,{|e| e[1] == (cAliasTFF)->TFF_LOCAL}) > 0
							Loop
						EndIf
						// Adiciona no log de conflito
						AAdd(aLstCnflt,;
							{	(cAliasTFF)->TFF_LOCAL,;
								(cAliasTFF)->ABS_DESCRI,;
								(cAliasTFF)->TFF_CONTRT,;
								(cAliasTFF)->TFF_ESCALA,;
								aAteEsc[Ni,_ZZXATEND],;
								aAteEsc[Ni,_ZZXNOME],;
								STR0102,; // "BLOQUEIO"
								STOD( (cAliasTFF)->TFF_PERINI ) } )

						Loop
					ENDIF 
				ENDIF
			
				// Consulta e Atualiza o Status: Conflito Atendente Demmisão, Afastamento, programação de férias e ferias efetivas.
				aCnflt := ChkCfltAlc(dDataIni, dDataFim, aAteEsc[nI,_ZZXATEND])
				
				//lLibSit	  := IIF(ExistBlock("A330ACNF") , ExecBlock("A330ACNF",.F.,.F.,{aAteEsc[nI,_ZZXATEND],dDataIni,aCnflt}), .F. )
				
				// Consulta e Atualiza o Status: Conflito Atendente Ferias
				aFerias := At581ChkFe(aAteEsc[nI,_ZZXATEND],dDataIni,dDataFim)
				
				// Consulta se existe cobertura na rota do ferista.
				aCobFer := At581Feris(aAteEsc[nI,_ZZXATEND],dDataIni,dDataFim)
				
				// Se existir algum confito não gera agenda.
				If aCnflt[1] .Or. (aFerias[4] .And. !Empty(aCobFer))
					
					AAdd(aLstCnflt,;
						{(cAliasTFF)->TFF_LOCAL,;
							(cAliasTFF)->ABS_DESCRI,;
							(cAliasTFF)->TFF_CONTRT,;
							(cAliasTFF)->TFF_ESCALA,;
							aAteEsc[Ni,_ZZXATEND],;
							aAteEsc[Ni,_ZZXNOME],;
							STR0103,; // "CONFLITO"
							STOD( (cAliasTFF)->TFF_PERINI ) } )
					
				EndIf
				
				If aAteEsc[nI,2] == "Efetivo" 
					nPos := aScan( aAteEfe, { |x|	x[1] == aAteEsc[nI,3] .And. ; //TDX_TURNO
												      	x[2] == aAteEsc[nI,5] .And. ;//TGY_SEQ
												      	x[3] == aAteEsc[nI,12] } )//TDX_COD
					If nPos == 0
						aAdd( aAteEfe, { aAteEsc[nI,3], aAteEsc[nI,5], aAteEsc[nI,12], {} } )
						nPos := Len(aAteEfe)
					EndIf
					
					If !lGesHr 
						aAdd( aAteEfe[nPos,4], {	aAteEsc[nI,1],;  //TGY_GRUPO
					 								aAteEsc[nI,6],;  //TGY_ATEND
													aAteEsc[nI,8],;  //TGY_DTINI
													aAteEsc[nI,9],;  //TGY_DTFIM
													aAteEsc[nI,11],; //TGY_ITEM
													aAteEsc[nI,14],; //TGY_ULTALO
													aAteEsc[nI,15]}) //TGY_TIPALO
					Else
						aAdd( aAteEfe[nPos,4], {	aAteEsc[nI,1],;  //TGY_GRUPO
					 								aAteEsc[nI,6],;  //TGY_ATEND
													aAteEsc[nI,8],;  //TGY_DTINI
													aAteEsc[nI,9],;  //TGY_DTFIM
													aAteEsc[nI,11],; //TGY_ITEM
													aAteEsc[nI,14],; //TGY_ULTALO
													aAteEsc[nI,15],; //TGY_ULTALO													
													aAteEsc[nI,16]}) //Array com a gestão dos horarios
					
					EndIf												
									
				Else // Cobertura
					nPos := aScan( aAteCob, { |x| x[1] == aAteEsc[nI,10] .And. x[2] == aAteEsc[nI,11] } )
					If nPos == 0
						aAdd( aAteCob, { aAteEsc[nI,10], aAteEsc[nI,11], {} } )
						nPos := Len(aAteCob)
					EndIf
					aAdd( aAteCob[nPos,3], {	aAteEsc[nI,1], aAteEsc[nI,6],; 
												aAteEsc[nI,8], aAteEsc[nI,9] } )			
				EndIf		
			
			Next nI
			
			cEscala := (cAliasTFF)->TFF_ESCALA
			cCalend := (cAliasTFF)->TFF_CALEND
			cCodTFF := (cAliasTFF)->TFF_COD

			cFilTFF := (cAliasTFF)->TFF_FILIAL
			
			MsgRun(STR0011, STR0008,;	 // "Gerando agenda dos atendentes da escala selecionados..."#"Processando"
			{ || aAteAge := At330AAgAt( aAteEfe, aAteCob, dDtIniAlo, dDtFimAlo, cEscala, cCalend, cCodTFF, cFilTFF, cRtTipo ) } )
		
			For nI:=1 To Len(aAteAge)
			
				//Quando for folga ou existir alguma restrição não gera agenda.
				If !AllTrim(aAteAge[nI,_ZZXENTRADA]) == "FOLGA" .AND. !AllTrim(aAteAge[nI,_ZZXSAIDA]) == "FOLGA" .AND. ;
				    At330Confl(aLstCnflt,(cAliasTFF)->TFF_LOCAL,AllTrim(aAteAge[nI,_ZZXATEND]),(cAliasTFF)->TFF_PERINI)
				    
				    dAloFim := If( HoraToInt(aAteAge[nI,_ZZXSAIDA]) < HoraToInt(aAteAge[nI,_ZZXENTRADA]),; 
				    						 aAteAge[nI,_ZZXDATA]+1, aAteAge[nI,_ZZXDATA])
				    						 
					// Verifica se não existe alocação para o atendente
					If ! TxExistAloc( AllTrim(aAteAge[nI,_ZZXATEND]),;
									  aAteAge[nI,_ZZXDATA],;
									  aAteAge[nI,_ZZXENTRADA],;
									  dAloFim,;
									  aAteAge[nI,_ZZXSAIDA],0,,,(cAliasTFF)->TFF_LOCAL)	
						
                        lSrvExt := (cAliasTFF)->TFJ_SRVEXT == "1"
                    
    					aIteABQ := At330AABQ( 	(cAliasTFF)->TFF_CONTRT,;
						 						(cAliasTFF)->TFF_PRODUT,;
						 						(cAliasTFF)->TFF_LOCAL,;
						 						(cAliasTFF)->TFF_FUNCAO,;  
						 						(cAliasTFF)->TFF_TURNO,;
						 						(cAliasTFF)->TFF_COD,;
						 					    (cAliasTFF)->TFF_FILIAL,;
						 					  	lSrvExt,;
						 					  	(cAliasTFF)->TFJ_CODIGO )
						
						If Len(aIteABQ) > 0
						
							cIdCFal := ABQ->ABQ_CONTRT+ABQ->ABQ_ITEM+ABQ->ABQ_ORIGEM 
						
							nTotHrsTrb := SubtHoras(	aAteAge[nI,_ZZXDATA], aAteAge[nI,_ZZXENTRADA],;
														aAteAge[nI,_ZZXDATA], aAteAge[nI,_ZZXSAIDA] )
																											
							nTotHor += nTotHrsTrb
							aCalAtd := {}
							
							aAdd( aCalAtd, { 	aAteAge[nI,_ZZXDATA],;
												TxRtDiaSem(aAteAge[nI,_ZZXDATA]),;
												AllTrim(aAteAge[nI,_ZZXENTRADA]),;
												AllTrim(aAteAge[nI,_ZZXSAIDA]),;
												AtConvHora(nTotHrsTrb),;
												aAteAge[nI,_ZZXSEQ] } ) 
												
							nPosMot := AScan(aMotAlocar,{|x| x[1] == aAteAge[nI,17]+aAteAge[nI,18] })	
							If nPosMot <= 0
								AAdd(aMotAlocar,{aAteAge[nI,17]+aAteAge[nI,18],{}})
								nPosMot := Len(aMotAlocar)
							EndIf
							dbSelectArea("TGY")
							TGY->(dbSetOrder(1))	//TGY_FILIAL+TGY_ESCALA+TGY_CODTDX+TGY_CODTFF+TGY_ITEM
							If aAteAge[nI][8] == "I"
								cCodTW3 := cTW3Int
							ElseIf !Empty(aMotAlocar[nPosMot,1]) .And. TGY->(dbSeek(xFilial("TGY")+aMotAlocar[nPosMot,1] ))	
								cCodTW3 := TGY->TGY_CODTW3
							Else
								cCodTW3 := ""
							EndIf
							
							AAdd(aMotAlocar[nPosMot,2],{ 	aAteAge[nI,_ZZXATEND]	,;
															aAteAge[nI,_ZZXNOME]		,;
															Posicione("AA1",1,xFilial("AA1")+aAteAge[nI,_ZZXATEND], "AA1_CDFUNC"),;
															aAteAge[nI,_ZZXTURNO]	,;
															(cAliasTFF)->TFF_FUNCAO	,;
															(cAliasTFF)->TFF_CARGO	,;
															Alltrim(ABQ->ABQ_CONTRT+ABQ->ABQ_ITEM+ABQ->ABQ_ORIGEM),;
															""		,;
															""		,;
															aCalAtd							,;
															{} 						,;
															(cAliasTFF)->TFF_LOCAL  ,;
															cCodTW3} )
																			
							aAdd( aAloTDV, {	aAteAge[nI,_ZZXATEND],;
									  		 	aAteAge[nI,_ZZXDATA],;
									  	    	AllTrim(aAteAge[nI,_ZZXENTRADA]),;
									        	dAloFim,;
									       	AllTrim(aAteAge[nI,_ZZXSAIDA]), {} } )
									       	
							aAdd( aAloTDV[Len(aAloTDV),6], aAteAge[nI,14,1] )
							
						EndIf
					EndIf
				EndIf
								
				//Controle de ultima alocação
				nPosUltAlo := aScan(aUltAloc, {|x| x[_ULTALOC_KEYTGY] == aAteAge[nI,17] .AND. x[_ULTALOC_ITEMTGY] == aAteAge[nI,18]})
				If nPosUltAlo > 0
					//Inclui ultima data e sequencia
					If (aAteAge[nI,16] > aUltALoc[nPosUltAlo][_ULTALOC_DATA])
						aUltALoc[nPosUltAlo][_ULTALOC_DATA]	:= aAteAge[nI,16]
						aUltALoc[nPosUltAlo][_ULTALOC_SEQ]	:= aAteAge[nI,13]
						aUltALoc[nPosUltAlo][_ULTALOC_LINHA]:= nI///AJUSTAR
					EndIf
				Else
					//Inicia data e sequencia
					aAdd(aUltAloc, Array(_ULTALOC_ATEND))
					nPosUltAlo := Len(aUltAloc)
					aUltAloc[nPosUltAlo][_ULTALOC_KEYTGY]	:= aAteAge[nI,17]
					aUltAloc[nPosUltAlo][_ULTALOC_DATA]		:= aAteAge[nI,16]
					aUltAloc[nPosUltAlo][_ULTALOC_SEQ]		:= aAteAge[nI,13]		
					aUltAloc[nPosUltAlo][_ULTALOC_ITEMTGY]	:= aAteAge[nI,18]
					aUltAloc[nPosUltAlo][_ULTALOC_GRUPO]	:= aAteAge[nI,01]
					aUltALoc[nPosUltAlo][_ULTALOC_LINHA]	:= nI
					aUltALoc[nPosUltAlo][_ULTALOC_ATEND]	:= aAteAge[nI,06]
				EndIf
			
			Next nI
			
			At330UpTGY(aUltAloc, Nil, Nil, aAteAge)//Atualiza informações do Efetivo(TGY) com base nas alocações e desalocações realizadas
			
			If Len(aMotAlocar) > 0
		
				For nPosMot := 1 To Len(aMotAlocar)
					If (lMovimentar .AND. nPosMot > 1) .Or. IsInCallStack('TEC335CSV')
						cMemorando := "2" // Caso a alocação seja gerada pelo movimentar, permite que a pergunta sobre o memorando seja apresentada apenas na primeira vez.
					EndIf
					dbSelectArea("TGY")
					TGY->(dbSetOrder(1))	//TGY_FILIAL+TGY_ESCALA+TGY_CODTDX+TGY_CODTFF+TGY_ITEM
					// Quando não recebe chave da TGY usa "002-Cobertura"
					If Empty(aMotAlocar[nPosMot,1])
						cTipAlo := "002"
					// Procura pelo tipo associado na TGY
					ElseIf TGY->(dbSeek(xFilial("TGY")+aMotAlocar[nPosMot,1] ))
						cTipAlo := TGY->TGY_TIPALO
					// Caso não encontre deixa vazio para gerar como outros
					Else 
						cTipAlo := ""
					EndIf
					
					MsgRun( STR0050, STR0008,; 	//"Gerando agenda dos atendentes..."###"Processando"
							{ || At330GvAlo(aMotAlocar[nPosMot,2],"CN9",cTipAlo, cMemorando,cSituacao) } )
							
				Next nPosMot 
						
				dbSelectArea("ABB")
				ABB->(dbSetOrder(1))  // ABB_FILIAL+ABB_CODTEC+ABB_DTINI+ABB_HRINI+ABB_DTFIM+ABB_HRFIM
				
				For nI:=1 To Len(aAloTDV)
					
					cAliasABB := GetNextAlias()
					
					BeginSql Alias cAliasABB
						SELECT *
						FROM %table:ABB% ABB
						WHERE ABB.ABB_FILIAL = %xFilial:ABB%
						  AND ABB.ABB_CODTEC = %Exp:aAloTDV[nI,1]%
						  AND ABB.ABB_DTINI  = %Exp:DtoS(aAloTDV[nI,2])%
						  AND ABB.ABB_DTFIM  = %Exp:DtoS(aAloTDV[nI,4])%
						  AND ABB.ABB_HRINI  = %Exp:aAloTDV[nI,3]%
						  AND ABB.ABB_HRFIM  = %Exp:aAloTDV[nI,5]%
						  AND ABB.ABB_ATIVO  = '1'
						  AND ABB.%NotDel%
						ORDER BY %Order:ABB%
					EndSql
					
					(cAliasABB)->(DbGoTop())
					
					If (cAliasABB)->(!EOF())
						aAloTDV[nI,6,1,1] := (cAliasABB)->ABB_CODIGO
					EndIf		
					
					(cAliasABB)->(DbCloseArea())
					
					If aAloTDV[nI,6,1,10] == "E"
						aAloTDV[nI,6,1,10] := "N"
					ElseIf aAloTDV[nI,6,1,10] == "I"
						aAloTDV[nI,6,1,10] := "S"
					EndIf					
				Next nI				
					
				// Atualiza o saldo de horas do configurador de alocação	
				TxSaldoCfg( cIdCFal, nTotHor, .F. )
			
				MsgRun( STR0051, STR0008,; 	//"Gerando informações sobre a escala..."###"Processando"
						{ || At330AUpTDV( .F., aAloTDV ) } ) 
						
			EndIf
		
			(cAliasTFF)->(dbSkip())
		
		EndDo

		If !Empty(aLstCnflt) .And. lExibeHelp
			aSort(aLstCnflt,,,{|x,y| x[7]+x[1] < y[7]+y[1]})
			At330AGvLg({'TFF_LOCAL','ABS_DESCRI','TFF_CONTR','TFF_ESCALA','AA1_CODTEC','AA1_NOMTEC','TW2_RESTRI','ABB_DTINI'},aLstCnflt)
		EndIf
		
	EndIf		
		
EndIf
	
RestArea(aArea)

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ATotHor				  	
Tela das informações de horarios de alocação por atendente

@sample 	At330ATotHor(oModel)

@return	Nil 
@author 	Serviços
@since		06/11/2013
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330ATotHor(oModel)

Local aArea     := GetArea()
Local oMdlTFF   := oModel:GetModel("TFFMASTER")
Local oMdlTGY   := oModel:GetModel("TGYDETAIL")
Local oMdlZZX   := oModel:GetModel("ZZXDETAIL")
Local aCmpDet	:= {}
Local nTotal    := 0
Local nLinTGY   := oMdlTGY:GetLine()  
Local nLinZZX   := oMdlZZX:GetLine()

Local nTotHor, nPosAte, nI, oViewZZX, dDatFim

Local oListBox			//Grid campos
Local oOk					//Objeto Confirma
Local oTop 				//Objeto Panel
Local oMiddle
Local oBottom
Local oDlgCmp

For nI:=1 To oMdlZZX:Length()

	oMdlZZX:GoLine(nI)
	
	If AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")) == "FOLGA" .And. ;
	   AllTrim(oMdlZZX:GetValue("ZZX_ENTRADA")) == "FOLGA"
	   Loop
	EndIf		 		
	
	If Empty(oMdlZZX:GetValue("ZZX_SAIDA")) .Or. Empty(oMdlZZX:GetValue("ZZX_SAIDA"))
		Loop
	EndIf 
	
	dDatFim := If( HoraToInt(oMdlZZX:GetValue("ZZX_SAIDA")) < HoraToInt(oMdlZZX:GetValue("ZZX_ENTRADA")),;
					oMdlZZX:GetValue("ZZX_DATA")+1, oMdlZZX:GetValue("ZZX_DATA"))
	
	nTotHor := SubtHoras(oMdlZZX:GetValue("ZZX_DATA"), oMdlZZX:GetValue("ZZX_ENTRADA"),;
							dDatFim, oMdlZZX:GetValue("ZZX_SAIDA") )	 
				
	nPosAte := aScan( aCmpDet, { |x| x[1] == oMdlZZX:GetValue("ZZX_ATEND") } )
	
	If nPosAte == 0				
		aAdd( aCmpDet, { 	oMdlZZX:GetValue("ZZX_ATEND")	,;
							oMdlZZX:GetValue("ZZX_NOME")	,;
							nTotHor, AtConvHora(nTotHor) } )
	Else
		aCmpDet[nPosAte,3] := aCmpDet[nPosAte,3] + nTotHor
		aCmpDet[nPosAte,4] := AtConvHora(aCmpDet[nPosAte,3]) 				
	EndIf							
						
	nTotal += nTotHor
								
Next nI

If Len(aCmpDet) > 0

	Define MsDialog oDlgCmp TITLE STR0055 FROM 000, 000 To 450, 540 Pixel // "Total de Horas de Alocação"		
	
	@ 000, 000 MsPanel oTop Of oDlgCmp Size 000, 070 // Coordenada para o panel
	oTop:Align := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
	@ 005,005 SAY STR0023 OF oTop PIXEL SIZE 60,9 // "Alocação de"
	@ 015,005 MsGet oMdlTFF:GetValue("TFF_DATINI") OF oTop SIZE 45,10 PIXEL WHEN .F.
	@ 005,060 SAY STR0024 OF oTop PIXEL SIZE 60,9 // "Alocação Ate"
	@ 015,060 MsGet oMdlTFF:GetValue("TFF_DATFIM") OF oTop SIZE 45,10 PIXEL WHEN .F.
	@ 005,115 SAY STR0056 OF oTop PIXEL SIZE 60,9 // "Local"
	@ 015,115 MsGet oMdlTFF:GetValue("TFF_LOCAL") OF oTop SIZE 50,10 PIXEL WHEN .F.
	@ 035,005 SAY STR0025 OF oTop PIXEL SIZE 120,9 // "Descrição"
	@ 045,005 MsGet oMdlTFF:GetValue("TFF_DSCABS") OF oTop SIZE 190,10 PIXEL WHEN .F.
	
	@ 035,205 SAY STR0057 OF oTop PIXEL SIZE 120,9 // "Total de Horas"
	@ 045,205 MsGet AtConvHora(nTotal) OF oTop SIZE 60,10 PIXEL WHEN .F.
				
	@ 000, 000 MsPanel oMiddle Of oDlgCmp Size 000, 150 // Coordenada para o panel
	oMiddle:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)	
		
	// Criação do grid para o panel	
	oListBox := TWBrowse():New(000,000,000,000,,{STR0035,STR0036,STR0058};
													,,oMiddle,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
												      //"Cod. Atend"#"Nome Atend."#"Horas Alocação"	
												       	  
	oListBox:SetArray(aCmpDet) // Atrela os dados do grid com a matriz
	oListBox:bLine := { ||{aCmpDet[oListBox:nAT][1],;
							  aCmpDet[oListBox:nAT][2],;
							  aCmpDet[oListBox:nAT][4]}} // Indica as linhas do grid	
	oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
	
	// Cria o panel para o botao OK	
	@ 000, 000 MsPanel oBottom Of oDlgCmp Size 000, 012 // Corrdenada para o panel dos botoes (size)
	oBottom:Align := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
	// Botao de acao OK	
	@ 000, 000 Button oOk Prompt STR0059  Of oBottom Size 030, 000 Pixel //"Fechar"
	oOk:bAction := { || oDlgCmp:End() }
	oOk:Align   := CONTROL_ALIGN_RIGHT
			
	// Ativa a tela exibindo conforme a coordenada
	Activate MsDialog oDlgCmp Centered
	
Else
	
	Help(,,"At330ATOTH",,STR0060,1,0) // "Não existem atendentes para essa escala!"

EndIf

RestArea(aArea)

//  Atualiza o grid da agenda dos atendentes
oViewZZX := FwViewActive()
oMdlTGY:GoLine(nLinTGY)
oMdlZZX:GoLine(nLinZZX)
oViewZZX:Refresh("ZZX_GRID")
		
Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} PreLinZZX				  	
Executa a verificação da edição da linha no grido dos atendentes

@sample 	PreLinZZX(oMdlG, nLine, cAcao, cCampo)

@param 		oMdlG, Objeto, objeto do grid em validação
@param 		nLine, Numerico, linha em ação
@param 		cAcao, Caracter, tipo da ação (DELETE, UNDELETE, etc)
@param 		cCampo, Caracter, campo da ação

@return	Nil 
@author 	Serviços
@since		23/07/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function PreLinZZX(oMdlG, nLine, cAcao, cCampo, lHelp)

Local lOk			:= .T.
Local lOkInat		:= .T.
Local lConteudo		:= .T.
Local cTipoCampo	:= ""
  
If cAcao == "DELETE"			 
	If oMdlG:GetValue("ZZX_ATEAGE") == "1"	 	
		lOk := .F.
	EndIf	
	
ElseIf cAcao == "UNDELETE"
	If oMdlG:GetValue("ZZX_ATEAGE") == "1"	 	
		lOk := .F.
	EndIf									
ElseIf cAcao == "SETVALUE"		 
	If !(cCampo == "ZZX_SITABB" .Or. cCampo == "ZZX_SITALO")
		If oMdlG:GetValue("ZZX_ATEAGE") == "1"				
			lOk := .F.
		EndIf	
		
		If 	oMdlG:GetValue("ZZX_SITABB") == "BR_LARANJA"//Valida alteração de agendas com manutenção
			lOkInat := .F.
		EndIf	
		
	EndIf
ElseIf cAcao == "CANSETVALUE"
	If nLine == 1 .And. Empty( oMdlG:GetValue("ZZX_DATA") )
		lConteudo := .F.
		If oMdlG:GetValue(cCampo) == Nil
			cTipoCampo := oMdlG:GetStruct():GetProperty(cCampo, MODEL_FIELD_TIPO)
			// atribui um valor padrão quando o conteúdo estiver nulo no campo
			If cTipoCampo $ "C#BT"
				oMdlG:LoadValue(cCampo,"")
			ElseIf cTipoCampo == "N"
				oMdlG:LoadValue(cCampo,0)
			ElseIf cTipoCampo == "D"
				oMdlG:LoadValue(cCampo,CTOD(""))
			ElseIf cTipoCampo == "L"
				oMdlG:LoadValue(cCampo,.F.)
			EndIf
		EndIf 
	EndIf
EndIf	

If !lOk
	If lHelp
	Help(,,"AT330AOK",,STR0061,1,0) // "Não é possivel efetuar esta operação para uma agenda atendida!"
	Endif
ElseIf !lOkInat
	If lHelp
	Help(,,"AT330AOK",,STR0076,1,0) // "Não é possivel efetuar esta operação para uma agenda com manutenção!"
	Endif
EndIf

Return(lOk .AND. lOkInat .AND. lConteudo)


//------------------------------------------------------------------------------
/*/{Protheus.doc} PosLinZZX				  	
Executa a verificação dos valores inclusos na linha

@sample 	PosLinZZX(oMdlG, nLine, cAcao, cCampo)

@param 		oMdlG, Objeto, objeto do grid em validação
@param 		nLine, Numerico, linha em ação
@param 		cAcao, Caracter, tipo da ação (DELETE, UNDELETE, etc)
@param 		cCampo, Caracter, campo da ação

@return	Nil 
@author 	Serviços
@since		01/08/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function PosLinZZX(oMdlG, nLine, cAcao, cCampo)

Local lOk      := .T.
  
If cAcao == "SETVALUE"
	If cCampo == "ZZX_TIPO" .And. !Empty(oMdlG:GetValue("ZZX_TIPO"))
		If oMdlG:GetValue("ZZX_TIPO") == "D"
			lOk := (oMdlG:GetValue("ZZX_ENTRADA") == "FOLGA" .And. oMdlG:GetValue("ZZX_ENTRADA") == "FOLGA") 
		EndIf
	EndIf		
EndIf	

If !lOk
	Help(,,"AT330APL",,STR0062,1,0) // "Horario de entrada e saida invalido para esse tipo de alocação!"
EndIf

Return(lOk)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AMFil				  	
Executa os filtros do grid da agenda dos atendentes

@sample 	At330AMFil( nTipo, oView, oMdlZZX, cOpcCmb )

@param 		nTipo, Numerico, 1 = Filtro por grupo ou 2 = Filtro por atendente
@param 		oMdlZZX, Objeto, Model utilizado para atualizar os dados
@param 		cOpcCmb, Caracter, Opção do combo para realizar o filtro

@return	Nil 
@author 	Serviços
@since		23/07/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330AMFil( nTipo, oModel, cOpcCmb )

Local oMdlTGY  := oModel:GetModel("TGYDETAIL")
Local oMdlZZX  := oModel:GetModel("ZZXDETAIL")

Local oViewZZX 

If AllTrim(cOpcCmb) == STR0009	// "Todos"
	If nTipo == 1
		nGrpFil  := 0
	Else
		cAteFil  := ""
	EndIf
Else
	If nTipo == 1
		nGrpFil  := Val(cOpcCmb)	
	Else		
		cAteFil := Left(cOpcCmb,nTamCdAte)			
	EndIf
EndIf	
	
// Recria o model para o novo filtro	
oModel:CancelData()
oModel:DeActivate()
oModel:Activate()

//  Atualiza o grid da agenda dos atendentes
oViewZZX := FwViewActive()
oMdlTGY:GoLine(1)
oMdlZZX:GoLine(1)
oViewZZX:Refresh()

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AVldInf				  	
Valida as informaçoes editadas no grid de alocações de atendentes

@sample 	At330AVldInf( oModel, cCampo )

@param 		oModel, Objeto, Model utilizado para verificar as informações
@param 		cCamp, Caracter, Campo para a consistencia das informações

@return	Nil 
@author 	Serviços
@since		23/07/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330AVldInf( oModel, cCampo )

Local aArea := GetArea()
Local cCor  := ""
Local lRet  := .T.

Local oViewZZX
Local aCnflt := nil

dbSelectArea("ABB")
ABB->(dbSetOrder(1))

If oModel <> Nil .And. oModel:GetId() == "ZZXDETAIL" .And. !IsInCallStack("InitDados")
	
	lLegend := .F.
			
	If cCampo == "ZZX_ENTRADA" .Or. cCampo == "ZZX_SAIDA"
			
		If oModel:GetValue(cCampo) <> "FOLGA"
			lRet := AtVldHora(AllTrim(oModel:GetValue(cCampo)))
		EndIf
				
	ElseIf cCampo == "ZZX_ATEND"
			
		lRet := ExistCpo( "AA1", oModel:GetValue(cCampo) )
			
	ElseIf cCampo == "ZZX_TIPO"
			
		Do Case
		Case oModel:GetValue(cCampo) == "S" 	; cCor := "BR_VERDE"
		Case oModel:GetValue(cCampo) == "C" 	; cCor := "BR_AMARELO"
		Case oModel:GetValue(cCampo) == "D" 	; cCor := "BR_AZUL"
		Case oModel:GetValue(cCampo) == "E" 	; cCor := "BR_LARANJA"
		Case oModel:GetValue(cCampo) == "I" 	; cCor := "BR_PRETO"
		OtherWise			   						; cCor := "BR_VERMELHO"
		EndCase
					 					 		
		oModel:SetValue( "ZZX_SITALO", cCor )
				
	EndIf
			
	If lRet .And. (!Empty(oModel:GetValue("ZZX_ATEND")) .And. ;
					!Empty(oModel:GetValue("ZZX_DATA")) .And. ;
					!Empty(oModel:GetValue("ZZX_ENTRADA")).And. ;
					!Empty(oModel:GetValue("ZZX_DATA")) .And. ;
					Empty(oModel:GetValue("ZZX_SAIDA")))
			 
		If ABB->( dbSeek( xFilial("ABB") + ;
				oModel:GetValue("ZZX_ATEND") + ;
				DtoS(oModel:GetValue("ZZX_DATA")) + ;
				AllTrim(oModel:GetValue("ZZX_ENTRADA")) + ;
				DtoS(oModel:GetValue("ZZX_DATA")) + ;
				AllTrim(oModel:GetValue("ZZX_SAIDA")) ) )
			cCor := "BR_VERMELHO"
		Else
			cCor := "BR_VERDE"
		EndIf
				
				// Consulta e Atualiza o Status: Conflito Atendente
		aCnflt := ChkCfltAlc(oModel:GetValue("ZZX_DATA"), oModel:GetValue("ZZX_DATA"), oModel:GetValue("ZZX_ATEND"))
		If (aCnflt[1] .or. aCnflt[2] .or. aCnflt[3])
			cCor := "BR_PRETO"
		EndIf
				
		oModel:SetValue( "ZZX_SITABB", cCor )
				
		//  Atualiza o grid da agenda dos atendentes
		oViewZZX := FwViewActive()
		oViewZZX:Refresh("ZZX_GRID")
				
	Else
		lRet := .F.
		oModel:GetModel():SetErrorMessage(oModel:GetId(),cCampo,oModel:GetModel():GetId(),cCampo,'At330AVldInf',; 
														STR0104, STR0105 ) //"Não há dados na agenda para gravação"
	EndIf
				
	lLegend := .T.
EndIf

RestArea(aArea)

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AZZX				  	
Alimenta as informações do grid das agendas dos atendentes

@sample 	At330AZZX(oModel, aAteAge )

@param 		oModel, Objeto, Model utilizado para verificar as informações
@param 		aAteAge, Array, Lista com as informações a serem preenchidas no model

@return	Nil 
@author 	Serviços
@since		31/07/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330AZZX( oModel, aAteAge, cApeAge, cApeFol )

Local lAgenda	:= .F.
Local oMdlZZX	:= oModel:GetModel("ZZXDETAIL")
Local oMdlTFF	:= oModel:GetModel("TFFMASTER")

Local nI
Local nLenAteAge := Len(aAteAge) 

Local lDemis		:= .F.
Local lAfast		:= .F.
Local lFerias		:= .F.
Local aCnflt		:= nil

For nI:=1 To nLenAteAge

	// Verifica o parametro para exibição da agenda
	If cApeAge <> 3 // Todas	
		If (cApeAge == 1 .And.  Empty(aAteAge[nI,10])) .Or. ; // Geradas 
		   (cApeAge == 2 .And. !Empty(aAteAge[nI,10])) // Não Geradas
			Loop
		EndIf				
	EndIf
	
	// Verifica o parametro para exibicao da folga
	If cApeAge <> 1 .And. cApeFol == 2 // Geradas # Apresenta folgas = Nao
		If Upper(AllTrim(aAteAge[nI,04])) == "FOLGA" .Or. ;
		   Upper(AllTrim(aAteAge[nI,05])) == "FOLGA"
			Loop
		EndIf		   
	EndIf
	
	If nGrpFil > 0 .And. nGrpFil <> aAteAge[nI,01]
		Loop
	EndIf
	
	If !Empty(cAteFil) .And. cAteFil <> aAteAge[nI,06]
		Loop
	EndIf	
	
	//Verifica se já existe informação no Grid
	If oMdlZZX:SeekLine({{"ZZX_DATREF", aAteAge[nI,16]}, {"ZZX_ENTRADA", aAteAge[nI,04]}, {"ZZX_SAIDA", aAteAge[nI,05]}, {"ZZX_ATEND", aAteAge[nI,06]}})
		Loop
	EndIf
	
	If nI > 1 .And. !Empty(oMdlZZX:GetValue("ZZX_SITABB")) 
		oMdlZZX:AddLine()
	EndIf
	
	lAgenda := !Empty(aAteAge[nI,10])
	
	lLegend := .F.
	
	// Consulta e Atualiza o Status: Conflito Atendente
	aCnflt := ChkCfltAlc(aAteAge[nI,02], aAteAge[nI,02], aAteAge[nI,06])
	
	oMdlZZX:LoadValue( "ZZX_SITABB"	, 	At330ACLgA(lAgenda,aAteAge[nI,11],(aAteAge[nI,19]=="1"),(aCnflt[1] .or. aCnflt[2] .or. aCnflt[3])))
	oMdlZZX:LoadValue( "ZZX_SITALO"	, 	At330ACLgS(aAteAge[nI,8]) )
	
	lLegend := .T.
	
	oMdlZZX:LoadValue( "ZZX_GRUPO"	, 	aAteAge[nI,01] ) 
	oMdlZZX:LoadValue( "ZZX_DATA"	, 	aAteAge[nI,02] ) 
	oMdlZZX:LoadValue( "ZZX_SEMANA"	, 	aAteAge[nI,03] ) 
	oMdlZZX:LoadValue( "ZZX_ENTRADA", 	aAteAge[nI,04] ) 
	oMdlZZX:LoadValue( "ZZX_SAIDA"	, 	aAteAge[nI,05] ) 
	oMdlZZX:LoadValue( "ZZX_ATEND"	, 	aAteAge[nI,06] ) 
	oMdlZZX:LoadValue( "ZZX_NOME"	, 	aAteAge[nI,07] ) 
	oMdlZZX:LoadValue( "ZZX_TIPO"	, 	aAteAge[nI,08] ) 
	oMdlZZX:LoadValue( "ZZX_CODABB"	, 	aAteAge[nI,10] )
	oMdlZZX:LoadValue( "ZZX_TURNO"	, 	aAteAge[nI,12] )
	oMdlZZX:LoadValue( "ZZX_SEQ"	, 	aAteAge[nI,13] )
	oMdlZZX:LoadValue( "ZZX_ITEM"	, 	aAteAge[nI,15] )
	oMdlZZX:LoadValue( "ZZX_DATREF"	, 	aAteAge[nI,16] )
	oMdlZZX:LoadValue( "ZZX_ATEAGE"	, 	aAteAge[nI,11] )  // campo fica por último por existir pré valid da linha consistindo o conteúdo dele
	oMdlZZX:LoadValue( "ZZX_KEYTGY"	, 	aAteAge[nI,17] )
	oMdlZZX:LoadValue( "ZZX_ITTGY"	, 	aAteAge[nI,18] )  
Next nI

oMdlZZX:GoLine(1)//GoLine necessário para que ao realizar o commit não ocorra divergencias internas do framework

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330APosZZX				  	
Verifica se as informações inclusas estão corretas

@sample 	At330APosZZX(oModel)

@param 		oModel, Objeto, Model utilizado para verificar as informações

@return	Nil 
@author 	Serviços
@since		01/08/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330APosZZX(oModel)

Local lRet 	 := .T.
Local cEntrada := ""
Local cSaida   := ""
Local lHasConfl := .F.
Local lPermConfl:= AT680Perm(NIL, __cUserID, "017") 
Local nI        := 0

For	nI:=1 To oModel:Length()

	oModel:GoLine(nI)
	
	If !oModel:IsDeleted()
	
		lHasConfl:= oModel:GetValue("ZZX_SITABB") == "BR_PRETO"
		
		// Se existe algum tipo de conflito para a alocação e 
		// caso o usuário atual não tenha permissão de alocação para estes casos
		// invalida a operação e encerra o processo. 
		If lHasConfl .and. !lPermConfl
			Help( ' ', 1, 'TECA330A', , STR0084, 1, 0 )	//"Usuário não tem permissão para realizar alocações com conflitos."
			lRet := .F.
			Exit
		EndIf  
		
		cEntrada := AllTrim(oModel:GetValue("ZZX_ENTRADA"))
		cSaida   := AllTrim(oModel:GetValue("ZZX_SAIDA"))
				
		If 	(cEntrada == "FOLGA" .And. cSaida <> "FOLGA") .Or. ; 
			(cEntrada <> "FOLGA" .And. cSaida == "FOLGA")
			Help(,,"At330APF",,STR0063 + DtoC(oModel:GetValue("ZZX_DATA")) + STR0064 + ;
									oModel:GetValue("ZZX_ATEND"),1,0) // "Tipo de intervalo incorreto para alocação! Dia:" ## " Atendente :"
			lRet := .F.			
		ElseIf (cEntrada == "FOLGA" .And. cSaida == "FOLGA") .And. ;
				oModel:GetValue("ZZX_TIPO") <> "D" .And. ;
				oModel:GetValue("ZZX_TIPO") <> "N" 
			Help(,,"At330APFS",,STR0065 + DtoC(oModel:GetValue("ZZX_DATA")) + STR0064 + ;
									oModel:GetValue("ZZX_ATEND"),1,0) // "Tipo de trabalho invalido para o intervalo de horarios! Dia:" ## " Atendente :"

			lRet := .F.				
		ElseIf (cEntrada <> "FOLGA" .And. cSaida <> "FOLGA") .And. ;
				oModel:GetValue("ZZX_TIPO") == "D"
			Help(,,"At330APSF",,STR0066 + DtoC(oModel:GetValue("ZZX_DATA")) + STR0064 + ;
									oModel:GetValue("ZZX_ATEND"),1,0) // "Tipo de intervalo incorreto para esse tipo de trabalho! Dia:" ## " Atendente :"				
			lRet := .F.
		EndIf
						
	EndIf

Next nI

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330APosZZX				  	
Verifica se as informações inclusas estão corretas

@sample 	At330APosZZX(oModel)

@param 		oModel, Objeto, Model utilizado para verificar as informações

@return	Nil 
@author 	Serviços
@since		01/08/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330AABQ( cContrato, cProduto, cLocal, cFuncao, cTurno, cCodTFF, cFilTFF, lSrvExt, cOrcSrv )

Local aRet  := {} 
Local aArea := GetArea()

Default cFilTFF := xFilial("TFF", cFilAnt )
Default lSrvExt := .F.

dbSelectArea("ABQ")
ABQ->(dbSetOrder(1)) //ABQ_FILIAL+ABQ_CONTRT+ABQ_ITEM+ABQ_ORIGEM 

If lSrvExt
	cContrato := cOrcSrv
EndIf

If ABQ->( dbSeek( xFilial("ABQ") + cContrato ) )

 	While ABQ->(!EoF()) .And. ;
 		  AllTrim(ABQ->ABQ_CONTRT) == AllTrim(cContrato)
 	
 		If ABQ->ABQ_PRODUT <> cProduto
 			ABQ->(dbSkip())
 			Loop 			
 		EndIf
 		
 		If ABQ->ABQ_LOCAL <> cLocal
 			ABQ->(dbSkip())
 			Loop 			
 		EndIf
 		
 		If ABQ->ABQ_FUNCAO <> cFuncao
 			ABQ->(dbSkip())
 			Loop 			
 		EndIf
 		
 		If ABQ->ABQ_TURNO <> cTurno
 			ABQ->(dbSkip())
 			Loop 			
 		EndIf

		If (ABQ->ABQ_FILTFF <> cFilTFF)
			ABQ->(dbSkip())
			Loop
		EndIf	 		
		If (ABQ->ABQ_CODTFF <> cCodTFF)  
			ABQ->(dbSkip())
			Loop
		EndIf
 		
 		aAdd( aRet, { ABQ->ABQ_CONTRT, ABQ->ABQ_ITEM, ABQ->ABQ_ORIGEM } ) 		
 		Exit
 		 	
 	EndDo

EndIf

RestArea(aArea)

Return(aRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ADtCfl				  	
	Realiza uma consulta detalhada dos conflitos de alocação, caso existam.

@sample 	At330ADtCfl(oView)
@param 		oView, Objeto, view sendo utilizada na alocação por escala

@return 	Nil 
@author 	Serviços
@since		20/05/2015
@version	P12

/*/
//------------------------------------------------------------------------------
Static Function At330ADtCfl(oView)
Local uRet			:= Nil
Local oMdlGeral 	:= oView:GetModel()
Local oMdlTGY  	:= oMdlGeral:GetModel("TGYDETAIL")
Local cCodAte		:= oMdlTGY:GetValue("TGY_ATEND")
Local dDtIni		:= CToD('')
Local dDtFin		:= CToD('')
Local lHasConfl	:= (oMdlTGY:GetValue("TGYSTATUS") <> "BR_VERDE")

If Empty(oMdlTGY:GetValue("TGY_DTINI")) 
	dDtIni := MV_PAR01
Else
	dDtIni := Max(oMdlTGY:GetValue("TGY_DTINI"),MV_PAR01)
EndIf

If Empty(oMdlTGY:GetValue("TGY_DTFIM")) 
	dDtFin := MV_PAR02
Else
	dDtFin := Min(oMdlTGY:GetValue("TGY_DTFIM"),MV_PAR02)
EndIf

At570Detal(cCodAte,{{dDtIni,"",dDtFin,""}})

Return uRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330Desaloc				  	
	Realiza a remoção da alocação de todos os recursos dentro do período

@sample 	At330Desaloc(oView)
@param 		oView, Objeto, view sendo utilizada na alocação por escala

@return 	Nil 
@author 	Serviços
@since		01/09/2014
@version	P11.90

/*/
//------------------------------------------------------------------------------
Static Function At330Desaloc(oView)

Local oMdlGeral 	:= oView:GetModel()
Local oMdlAgd  	:= oMdlGeral:GetModel("ZZXDETAIL")
Local cPergAnt  	:= "TEC580BE"
Local cPergDes    	:= "TEC330A1"

Local lOk      	:= .F.
Local cTxtStatus 	:= STR0067 // "As seguintes alocações não puderam ser desfeitas"
Local cLogStatus 	:= ""
Local nLinMdl  	:= 0

If Pergunte(cPergDes,.T.) .And. ;
	MsgNoYes(STR0068) // "Confirma a exclusão das agendas com a data de referência dentro do período?"
	
	// valida se o período informado pelo usuário está dentro do fornecido inicialmente na pesquisa
	If !(FwFldGet("TFF_DATINI") > MV_PAR02 .Or. FwFldGet("TFF_DATFIM") < MV_PAR01 ) 
	
		For nLinMdl := 1 To oMdlAgd:Length()
		
			oMdlAgd:GoLine(nLinMdl)
			
			If !oMdlAgd:IsDeleted() .And. ;
				oMdlAgd:GetValue("ZZX_DATREF") >= MV_PAR01 .And. ;
				oMdlAgd:GetValue("ZZX_DATREF") <= MV_PAR02
				
				If PreLinZZX(oMdlAgd, nLinMdl,"DELETE",,.F.)
					lOk := oMdlAgd:DeleteLine()
				Else
					lOk := .F.
				Endif
				
				If !lOk
					cLogStatus += I18N( STR0070, ; // "Atendente: #1[codAtd]# - #2[cAtdNome]# Dia Inicial: #3[dInicial]# - Hora Inicial: #4[hInicial]#"
						{ oMdlAgd:GetValue("ZZX_ATEND"), oMdlAgd:GetValue("ZZX_NOME"), ;
							oMdlAgd:GetValue("ZZX_DATA"),oMdlAgd:GetValue("ZZX_ENTRADA") } ) + CRLF
				EndIf
				
			EndIf
			
		Next nLinMdl
	
		If !Empty(cLogStatus)
			Aviso(STR0069,cLogStatus,{STR0072},2,cTxtStatus,,,.T.) // "Remoção de Agenda" ### "OK"
		EndIf
	
	Else
		MsgAlert( STR0071,; // "Período inserido para o cancelamento não está dentro do período definido para geração das agendas"
					STR0069 ) // "Remoção de Agenda"
	EndIf
EndIf

//  elimina eventuais erros identificados durante o processamento
// das exclusões para não bloquear o usuário na tela
oMdlAgd:DiffuseVoid()  
Pergunte(cPergAnt,.F.)

oView:Refresh() // Atualiza as views

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtConvHora
Realiza conversão de hora para formato utilizado pela rotina
@since 21/11/2014
@version 12
@param nHora, numérico, Hora no formato Inteiro
@return String, Hora em String no formato utilizado pela rotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AtConvHora(nHoras)
	Local nHora := Int(nHoras)//recupera somente a hora
	Local nMinuto := (nHoras - nHora)*100//recupera somento os minutos	
Return(StrZero(nHora, 2) + ":" + StrZero(nMinuto, 2))


//------------------------------------------------------------------------------
/*/{Protheus.doc} StrHora
	Ajusta o horario para receber o formato correto

@sample 	StrHora(cHora)

@return	cRet - Horario com o formato correto  
@author	Serviços
@since		29/12/2014       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function StrHora(cHora)

Local cRet    := ""
Local cHorRet := AllTrim( cHora )

If cHorRet <> "FOLGA"
	If Len( cHorRet ) < 4
		cHorRet := PadL( cHorRet, 4, "0" )
	EndIf
	
	If At( ":", cHorRet ) == 0
		cHorRet := Left( cHorRet, 2 ) + ":" + Right( cHorRet, 2 )
	EndIf
EndIf	

cRet := cHorRet

Return(cRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AVerABB				  
	Verifica todas as agendas gravadas na ABB para o item do contrato 

@sample 	At330AVerABB(dDatIni, dDatFim, cCodTFF)

@param		dDatIni - Data Inicial para a agenda dos atendentes
@param		dDatFim - Data Final para a agenda dos atendentes
@param		cCodTFF - Codigo do recurso humano para o contrato
@param		cFilTFF - Filial do recurso humano para o contrato

@return	aRet - Lista com todas as agendas geradas no contrato.  
@author	Serviços
@since		30/12/2014       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function At330AVerABB( dDatIni, dDatFim, cCodTFF, cFilTFF )

Local aRet 	  := {}
Local cAliasABB := GetNextAlias()
Local cCampos := "%%"
Local lSum444 := TDV->(FieldPos("TDV_FERSAI")) > 0 .AND. TDV->(FieldPos("TDV_FSTPEX")) > 0 .AND. TDV->(FieldPos("TDV_FSEXTN")) > 0 // Verificação de campos para sumula 444
Local aTDV := Array(_TDV_PREV)

Default cFilTFF := xFilial("TFF", cFilAnt)
If lSum444
	cCampos := "%, TDV.TDV_FERSAI, TDV.TDV_FSTPEX, TDV.TDV_FSEXTN%"
EndIf

BeginSql Alias cAliasABB
	
	COLUMN ABB_DTINI AS DATE
	COLUMN ABB_DTFIM AS DATE	
	
	SELECT 
		ABB.ABB_DTINI, ABB.ABB_DTFIM, ABB.ABB_HRINI, 
		ABB.ABB_HRFIM, ABB.ABB_CODTEC, TDV.TDV_TPDIA, TDV_SEQTRN, ABB_CODIGO, ABB_ATENDE, ABB_MANUT,
		TDV.TDV_DTREF, TDV.TDV_TURNO, TDV.TDV_TPEXT, TDV.TDV_TPEXTN, TDV.TDV_NONHOR, TDV.TDV_CODREF, TDV.TDV_INSREP, TDV.TDV_HRMEN, TDV.TDV_HRMAI,
		TDV.TDV_INTVL1, TDV.TDV_INTVL2, TDV.TDV_INTVL3, TDV.TDV_FERIAD, TDV.TDV_FTPEXT, TDV.TDV_FEXTN %Exp:cCampos%	
	FROM 
		%table:ABQ% ABQ		
	JOIN %table:ABB% ABB ON 
		ABB.ABB_FILIAL = %xFilial:ABB% AND 
		ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM AND 
		ABB.ABB_DTINI >= %Exp:dDatIni% AND ABB.ABB_DTFIM <= %Exp:dDatFim% AND
		ABB.ABB_ATIVO  = '1' AND
		ABB.%NotDel% 
	JOIN %table:TDV% TDV ON 
		TDV.TDV_FILIAL = %xFilial:TDV% AND
		TDV.TDV_CODABB = ABB.ABB_CODIGO AND 
		TDV.%NotDel% 
	WHERE 
		ABQ.ABQ_CODTFF = %Exp:cCodTFF% AND 
		ABQ.ABQ_FILTFF = %Exp:cFilTFF% AND
		ABQ.ABQ_FILIAL = %xFilial:ABQ% AND
		ABQ.%NotDel%  			
	GROUP BY 
		ABB.ABB_DTINI, ABB.ABB_DTFIM, ABB.ABB_HRINI, 
		ABB.ABB_HRFIM, ABB.ABB_CODTEC, TDV.TDV_TPDIA, TDV_SEQTRN, ABB_CODIGO, ABB_ATENDE, ABB_MANUT,
		TDV.TDV_DTREF, TDV.TDV_TURNO, TDV.TDV_TPEXT, TDV.TDV_TPEXTN, TDV.TDV_NONHOR, TDV.TDV_CODREF, TDV.TDV_INSREP, TDV.TDV_HRMEN, TDV.TDV_HRMAI,
		TDV.TDV_INTVL1, TDV.TDV_INTVL2, TDV.TDV_INTVL3, TDV.TDV_FERIAD, TDV.TDV_FTPEXT, TDV.TDV_FEXTN %Exp:cCampos%
	ORDER BY
		TDV.TDV_DTREF, ABB.ABB_CODTEC
		
EndSql

While (cAliasABB)->(!Eof())

	aTdv := Array(_TDV_PREV)
	aTdv[_TDV_DTREF] := (cAliasABB)->TDV_DTREF
	aTdv[_TDV_TURNO] := (cAliasABB)->TDV_TURNO
	aTdv[_TDV_TPEXT] := (cAliasABB)->TDV_TPEXT
	aTdv[_TDV_TPEXTN] := (cAliasABB)->TDV_TPEXTN
	aTdv[_TDV_NONHOR] := (cAliasABB)->TDV_NONHOR
	aTdv[_TDV_CODREF] := (cAliasABB)->TDV_CODREF
	aTdv[_TDV_INSREP] := (cAliasABB)->TDV_INSREP
	aTdv[_TDV_HRMEN] := (cAliasABB)->TDV_HRMEN
	aTdv[_TDV_HRMAI] := (cAliasABB)->TDV_HRMAI
	aTdv[_TDV_FERIAD] := (cAliasABB)->TDV_FERIAD
	aTdv[_TDV_FTPEXT] := (cAliasABB)->TDV_FTPEXT
	aTdv[_TDV_FEXTN] := (cAliasABB)->TDV_FEXTN
	aTdv[_TDV_INTVL1] := (cAliasABB)->TDV_INTVL1
	aTdv[_TDV_INTVL2] := (cAliasABB)->TDV_INTVL2
	aTdv[_TDV_INTVL3] := (cAliasABB)->TDV_INTVL3

	If lSum444
		aTdv[_TDV_FERSAI] := (cAliasABB)->TDV_FERSAI
		aTdv[_TDV_FSTPEX] := (cAliasABB)->TDV_FSTPEX
		aTdv[_TDV_FSEXTN] := (cAliasABB)->TDV_FSEXTN
	EndIf	

	aAdd( aRet, { (cAliasABB)->ABB_DTINI,;						 
					(cAliasABB)->ABB_DTFIM,;
					(cAliasABB)->ABB_HRINI,;
					(cAliasABB)->ABB_HRFIM,;
					(cAliasABB)->ABB_CODTEC,;
					(cAliasABB)->TDV_TPDIA,;
					.T.,;
					(cAliasABB)->TDV_SEQTRN,;
					(cAliasABB)->ABB_CODIGO,;
					(cAliasABB)->ABB_ATENDE,;
					aTdv,;
					(cAliasABB)->ABB_MANUT } )
										

	(cAliasABB)->(dbSkip())
 
EndDo

(cAliasABB)->(dbCloseArea())

Return(aRet) 

//------------------------------------------------------------------------------
/*/{Protheus.doc} ChkCfltAlc
	Pesquisa por conflitos de alocação

@sample 	ChkCfltAlc(dAlocDe, dAlocAte, cAtend)

@return	aRet,array,
Estrutura do array:
	[1]-Se possui data de demissão no periodo
	[2]-Se possui data de afastamento no periodo
	[3]-Se possui programação de férias ou férias processadas no periodo
	[4] - Data inicial programação de férias ou férias processadas no periodo
	[5] - Data final programação de férias ou férias processadas no periodo

@author	Serviços
@since		22/05/2015       
@version	P12
/*/
//------------------------------------------------------------------------------
Function ChkCfltAlc(dAlocDe, dAlocAte, cAtend )
// Ambiente
Local aRet 		:= { .F., .F., .F. }	// Demissão ; Afastamento ; Ferias ; Data inicial ; Data final
Local aArea		:= nil
Local cAliasRA	:= ""
Local cQuerie		:= ""

// Ponteiros usados pela função
Local nPosCodTec	:= AScan(aCfltHead,{|e| e == 'AA1_CODTEC'}) 
Local nPosDTINI	:= AScan(aCfltHead,{|e| e == 'ABB_DTINI'})
Local nPosDTFIM	:= AScan(aCfltHead,{|e| e == 'ABB_DTFIM'})
Local nPosAtnd	:= 0

//Filtro usado em pesquisa no array aCfltAtnd
Local bFilter		:= {|e| e[nPosCodTec] == cAtend .and. dAlocDe >= e[nPosDTINI] .and. dAlocAte <= e[nPosDTFIM] }

// Regra para verificação de conflito, onde:
// dFA -> Data Final da Alocação;
// dIA -> Data Inicial da Alocação; 
// dIE -> Data Inicial do Evento: (Afastamento ou Férias);
// dFE -> Data Final do Evento: (Afastamento ou Férias);
Local bCnflt		:= {|dIA,dFA,dIE,dFE| (( Empty(dFE) .And. dIE <= dIA ) .Or. ( !Empty(dFE) .And. !( dIA > dFE .Or. dFA < dIE ) ) ) }

// Contadores
Local nI			:= 0
Local nJ			:= 0

// Auxiliares da Função
Local aAux			:= {}

nPosAtnd := AScan(aCfltAtnd, bFilter)

If (nPosAtnd == 0)
	aArea		:= GetArea()
	cAliasRA	:= GetNextAlias() 
	cQuerie	:= AT570QryPC(dAlocDe, dAlocAte, cAtend, cAtend)
	
	// Recurso utilizado para executar no Embedded SQL
	// Retira-se apenas a primeira ocorrência do termo SELECT
	// E introduz o sinal de percent para a expansão da expressão.
	cQuerie	:= "% " + StrTran(cQuerie, "SELECT", "" , 1 , 1 ) + " %"
	
	// Envia consulta ao banco
	BeginSQL Alias cAliasRA
		
		column ABB_DTINI as Date
		column ABB_DTFIM as Date
		column RA_DEMISSA as Date
		column RF_DATAINI as Date
		column RF_DATINI2 as Date
		column RF_DATINI3 as Date
		column R8_DATAINI as Date
		column R8_DATAFIM as Date
		column RH_DATABAS as Date
		column RH_DBASEAT as Date
		column RF_DFEPRO1 as Numeric(5,0)
		column RF_DFEPRO2 as Numeric(5,0)
		column RF_DFEPRO3 as Numeric(5,0)
		
		SELECT %exp:cQuerie%
		
	EndSQL
	
	// Avalia o resultado da consulta  
	While !(cAliasRA)->(EOF())
		For nI := 1 To Len(aCfltHead)
			If FieldPos(aCfltHead[nI]) > 0
				AAdd(aAux,FieldGet(FieldPos(aCfltHead[nI])))
			EndIf
		Next nI
		
		AAdd(aCfltAtnd, aClone(aAux))	// Adiciona à variável estática 
		aAux := {}	// Limpa a variável auxiliar 
		
		(cAliasRA)->(DbSkip())
	EndDo
	
	(cAliasRA)->(DbCloseArea())
	
	RestArea(aArea)
	
EndIf

// Verifica se a data de alocação possúi algum conflito: Demissão, Afastamento ou Férias
If (nPosAtnd := AScan(aCfltAtnd, bFilter)) > 0
	// Demissao
	dAuxI := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RA_DEMISSA'})]
	dAuxF := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RA_DEMISSA'})]
	aRet[1] := (dAuxI >= dAlocDe .and. dAuxF <= dAlocAte)
	
	// Afastamento
	dAuxI := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'R8_DATAINI'})]
	dAuxF := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'R8_DATAFIM'})]

	If !Empty(dAuxI)
		aRet[2] :=	Eval(bCnflt,dAlocDe,dAlocAte,dAuxI,dAuxF)	// Verificando regras de conflito (bCnflt)
	Endif

	//Férias processadas
	If !aRet[3]
		dAuxI := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RH_DATABAS'})]
		dAuxF := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RH_DBASEAT'})]
		If !Empty(dAuxI)
			aRet[3] :=	Eval(bCnflt,dAlocDe,dAlocAte,dAuxI,dAuxF)	// Verificando regras de conflito (bCnflt)
		Endif
	EndIf

	// Ferias - Verificação dos períodos de férias: 1º 
	If !aRet[3]
		dAuxI := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RF_DATAINI'})]
		dAuxF := dAuxI + (ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RF_DFEPRO1'})] - 1)
		If !Empty(dAuxI)
			aRet[3] :=	Eval(bCnflt,dAlocDe,dAlocAte,dAuxI,dAuxF)	// Verificando regras de conflito (bCnflt)
		Endif
	EndIf
	
	// Ferias - Verificação dos períodos de férias: 2º
	If !aRet[3]
		dAuxI := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RF_DATINI2'})]
		dAuxF := dAuxI + (ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RF_DFEPRO2'})] - 1)
		If !Empty(dAuxI)
			aRet[3] :=	Eval(bCnflt,dAlocDe,dAlocAte,dAuxI,dAuxF)	// Verificando regras de conflito (bCnflt)
		Endif
	EndIf
		
	// Ferias - Verificação dos períodos de férias: 3º
	If !aRet[3]
		dAuxI := ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RF_DATINI3'})]
		dAuxF := dAuxI + (ACFLTATND[nPosAtnd][AScan(aCfltHead,{|e| e == 'RF_DFEPRO3'})] - 1)
		If !Empty(dAuxI)
			aRet[3] :=	Eval(bCnflt,dAlocDe,dAlocAte,dAuxI,dAuxF)	// Verificando regras de conflito (bCnflt)
		Endif
	EndIf	

EndIf

Return(aRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AGvLg
	Gera Log de operação e apresenta diálogo ao usuário com possibilidade de gravação.

@sample 	At330AGvLg(aHeader,aValues)

@param		aHeader,array,Nome dos campos relativos aos valores do array aValues
@param		aValues,array,Conjunto de dados contendo os valores relativos aos titulos de aHeaders
@return	nil  
@author	Serviços
@since		25/05/2015       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At330AGvLg(aHeader,aValues)
Local cFileLog	:= ""
Local cPath		:= ""
Local aArea		:= GetArea()
Local nI        := 0
Local nJ        := 0
Local bPosSX3   := {|cField| (POSICIONE('SX3', 2, cField, 'X3_TITULO'), X3TITULO()) }
Local cMsg1     := ""
Local cMsg2     := ""

dbSelectArea("SX3")
dbSetOrder(2)

AutoGrLog(STR0085)	//"LOG - Conflitos/Restrições Operacionais na Alocação Automática"
AutoGrLog(STR0086 + SM0->M0_CODIGO + "/" + SM0->M0_CODFIL)	//"EMPRESA / FILIAL: "
AutoGrLog("-------------------------------------------------------------------------------")

For nI := 1 To Len(aValues)
	For nJ := 1 To Len(aHeader)
		cMsg1 := Eval(bPosSX3,aHeader[nJ])
		cMsg2 := aValues[nI][nJ]
		If ValType(cMsg1) == "C" .AND. ValType(cMsg2) == "C"
			AutoGrLog( cMsg1 + ": " + cMsg2 )
		EndIf
	Next nJ
	AutoGrLog("-------------------------------------------------------------------------------")
Next nI

AutoGrLog(STR0087 + ': ' + SubStr(cUsuario,7,15))	//"USUÁRIO"

cFileLog := NomeAutoLog()

If cFileLog <> ""
   // A função MostraErro() apaga o arquivo que leu, por isso salve-o.
   MostraErro(cPath,cFileLog)
Endif

RestArea(aArea)
Return nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330MntAge
Prepara e executa a chamada da tela de manutenção da agenda do atendente.
@sample 	At330MntAge(oView)
@param 		oView, Objeto, view sendo utilizada na alocação por escala
@return	.T. = Processamento OK / .F. = Processamento com críticas  
@author 	Alexandre da Costa
@since		24/09/2015       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At330MntAge(oView)	  
Local aArea		:=	GetArea()
Local aAreaABB	:=	ABB->(GetArea())
Local oMdlGeral 	:=	oView:GetModel()
Local oMdlTFF  	:=	oMdlGeral:GetModel("TFFMASTER")
Local oMdlZZX  	:=	oMdlGeral:GetModel("ZZXDETAIL")
Local cContrato	:=	oMdlTFF:GetValue("TFF_CONTRT")
Local cCodAtend	:=	oMdlZZX:GetValue("ZZX_ATEND")
Local dDt			:=	oMdlZZX:GetValue("ZZX_DATA")
Local nOldLinZZX	:=	oMdlZZX:GetLine()
Local nLinZZX		:=	0
Local nInd			:=	0
Local aMntAgenda	:=	{}	
Local lRet			:=	.T.
Local cMemoLOG	:=	""
Local cContrAnt	:=	""
Local dDataAnt	:=	CtoD(Space(08))
Local cSeparador	:=	" - "

//Valida se a agenda do atendente já foi gerada ou se sofreu manutenção
If	oMdlZZX:GetValue("ZZX_SITABB") == "BR_VERMELHO"	.or.;
	oMdlZZX:GetValue("ZZX_SITABB") == "BR_LARANJA"
	
	//Se houver agenda gerada ou com manutenção prévia, então será possível realizar novas manutenções na mesma...
	ABB->(dBSetOrder(1))	//ABB_FILIAL+ABB_CODTEC+DTOS(ABB_DTINI)+ABB_HRINI+DTOS(ABB_DTFIM)+ABB_HRFIM
	ABB->(dBSeek(xFilial("ABB")+cCodAtend+DtoS(dDt)))	//Posiciona no primeiro horário da data selecionada no GRID
	//
	At540SetAge("0")				//Força a inicialização do array da manutenção da agenda do atendente
	TECA540()						//Executa a rotina de manutenção da agenda, trazendo a agenda do atendente/data posicionados no GRID
	aMntAgenda := At540GetAge()	//Carrega o conteúdo do array da manutenção da agenda do atendente
	aSort( aMntAgenda, Nil, Nil, { |x,y| x[07]+DtoS(x[02])+x[03]+x[06] < y[07]+DtoS(y[02])+y[03]+y[06] } )
	//
	//=====================================================================================================
	//	Atualiza o status da agenda conforme a última posição da sua manutenção
	//	Atualiza o GRID da agenda dos atendentes
	//=====================================================================================================
	oViewZZX	:=	FwViewActive()
	For nInd := 1 to Len(aMntAgenda)
	 	//Certifica-se que a manutenção da agenda é referente ao contrato que está sendo trabalhado no momento
		If	Left(aMntAgenda[nInd,07],Len(cContrato)) == cContrato	//Contrato a qual a agenda que fora selecionada pertence
			If	(nLinZZX := aScan(aAtend,{|x|	x[02] == aMntAgenda[nInd,02] .and.;	//Data inicial
													x[04] == aMntAgenda[nInd,03] .and.;	//Hora inicial
													x[05] == aMntAgenda[nInd,05] .and.;	//Hora final
													x[06] == cCodAtend			 .and.;	//Código do atendente
													x[10] == aMntAgenda[nInd,06] }) ) > 0	//Código da agenda do atendente
				aAtend[nLinZZX,19]	:=	aMntAgenda[nInd,08]	//Agenda ativa?
				oMdlZZX:GoLine(nLinZZX)
				// Atualiza o sinalizador (legenda) da manutenção da agenda do atendente
				If	aAtend[nLinZZX,19] == "1"
					oMdlZZX:LoadValue("ZZX_SITABB","BR_LARANJA")	// Sinaliza que houve uma MANUTENÇÃO DA AGENDA
				Else
					oMdlZZX:LoadValue("ZZX_SITABB","BR_VERMELHO")	// Não há manutenção (Retorna o status p/AGENDA GERADA)
				EndIf			
			EndIf
		Else
			cMemoLOG	:=	If(	Empty(cMemoLOG),;
								STR0092+CRLF,;	//"Algumas agendas que foram selecionadas para manutenção pertencem a outros contratos. Verifique a atualização destas agendas."
								cMemoLOG)
			If	Empty(cContrAnt) .or. Left(aMntAgenda[nInd,07],Len(cContrato)) <> cContrAnt
				cMemoLOG	+=	CRLF+STR0093+Left(aMntAgenda[nInd,07],Len(cContrato))+":"+CRLF	//"Contrato "
				cContrAnt	:=	Left(aMntAgenda[nInd,07],Len(cContrato))
			EndIf
			If	Empty(dDataAnt) .or. aMntAgenda[nInd,02] <> dDataAnt
				cMemoLOG	+=	Space(03)+STR0094+DtoC(aMntAgenda[nInd,02])+CRLF	//"Data: "
				dDataAnt	:=	aMntAgenda[nInd,02]
			EndIf
			cMemoLOG	+=	Space(09)+	STR0095+aMntAgenda[nInd,03]+cSeparador+;	//"Hora inicial: "
										STR0096+aMntAgenda[nInd,05]+CRLF			//"Hora final: "
		EndIf												
	Next nInd
	oMdlZZX:GoLine(nOldLinZZX)
	oViewZZX:Refresh("ZZX_GRID")
	//
	If	!Empty(cMemoLOG)
		AtShowLog(cMemoLog,STR0097)	//"Alocação por escala x Manutenção da agenda do atendente"
	EndIf
	//
Else
	Help(,,"At330MntAge",,STR0091,1,0) // "Não foi possível a execução da manutenção da agenda, pois ela não foi gerada!"
	lRet	:=	.F.
EndIf
RestArea(aAreaABB)
RestArea(aArea)
Return	lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AVal				  	
Verifica se as informações inclusas estão corretas

@sample 	At330AVal(oModel)

@param 		oModel, Objeto, Model utilizado para verificar as informações

@return	Nil 
@author 	Serviços
@since		06/11/2015
@version	P12

/*/
//------------------------------------------------------------------------------
Static Function At330AVal(oModel)

Local lRet		:= .T.
Local oMdlTGY	:=oModel:GetModel("TGYDETAIL")
Local xI		:= 0
Local lAviso	:= .F.
Local lBloq		:= .F.

//verifica status dos atendentes
For	xI:=1 To oMdlTGY:Length()

	oMdlTGY:GoLine(xI)
	
	If !oMdlTGY:IsDeleted()
		//status do atendente
		
		If oMdlTGY:GetValue("TGYSTATUS") == "BR_LARANJA"
			lAviso := .T.
		Elseif oMdlTGY:GetValue("TGYSTATUS") == "BR_PRETO"	
			lBloq := .T.
			EXIT
		Endif
	Endif
Next xI

If lBloq
	lRet := .F.
	Help("",1,"At330AVal",,STR0099,2,0) //"Atendente com restrição operacional para o local/cliente"
ElseIf lAviso
	lRet := msgYesNo(STR0098,STR0100) //"Atendente com restrição operacional de aviso."##"Deseja Continuar?"
	IF !lRet
		Help("",1,"At330AVal",,STR0101,2,0) //"Alocação Cancelada"
	ENDIF 
EndIf

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330Confl				  	
Verifica se existe algum conflito com o atendente na geração da agenda.

@return		Nil 
@author 	Serviços
@since		09/08/2018
@version	P12

/*/
//------------------------------------------------------------------------------
Static Function At330Confl(aLstCnflt,cLocal,cCodTec,dPerIni)
Local lRet := .T.

If AScan(aLstCnflt,{|e| e[1] == cLocal  .And. ;
						e[5] == cCodTec .And. ;
						e[8] == sTod(dPerIni) } ) > 0
	lRet := .F.	
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} at330ColHR				  	
Verifica se existe a coluna TGY_ENTRA1

@sample 	at330ColHR(oModel)

@param 		

@return	Booleano 
@author 	Matheus Lando Raimundo
@since		24/08/201
@version	P12

/*/
//------------------------------------------------------------------------------
Function at330ColHR()
Local lRet := .F.

lRet := TGY->(ColumnPos("TGY_ENTRA1")) > 0

Return lRet