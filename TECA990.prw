#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA990.CH"
#INCLUDE "MSOLE.Ch"

STATIC lLegend := .T.

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA990
Browse para manutenção de devolução de materiais (EPI/UNIFORMES) - Funcionários x Materiais Entregues
@param  Nenhum
@return Nehhum
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function TECA990()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('T4A')
oBrowse:SetDescription(STR0001)	//"Funcionários x Materiais entregues"
oBrowse:Activate()

Return NIL

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Função para criação do menu
@param  Nenhum
@return aRotina, Array, Opções disponíveis no MENU
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina 	:= {}

ADD OPTION aRotina TITLE STR0002 	ACTION 'VIEWDEF.TECA990' 		OPERATION 2 ACCESS 0//"Visualizar"
ADD OPTION aRotina TITLE STR0003	ACTION 'TA0990EView()'			OPERATION 4 ACCESS 0//"Alterar"

Return aRotina

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados (MODEL)
@param  Nenhum
@return oModel, Objeto, oModel 
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel
Local CposCab		:= "T4A_TIPDEV, T4A_ITEM, T4A_CODEPI, T4A_CODEPI, T4A_DESC, T4A_DFOLHA, T4A_FORNEC, T4A_LOJA, T4A_NUMCAP, T4A_DTVENC,T4A_DTENTR, T4A_HRENTR, T4A_QTDENT,T4A_PRV1,T4A_CODTFS,T4A_NREDUZ,T4A_TPMAT,T4A_MOTIVO, T4A_CODTFL, T4A_LOCAL, T4A_CODPAI, T4A_DSCGFH" 
Local CposIte		:= "T4A_MAT, T4A_NOME, T4A_CODTEC, T4A_NOMTEC" 
Local oStMT4A 		:= FWFormStruct(1,'T4A',{|cCampo| !AllTrim(cCampo) $ CposCab })
Local oStDT4A		:= FWFormStruct(1,'T4A',{|cCampo| !AllTrim(cCampo) $ CposIte })
Local bPosValidacao	:= { |oModel| AT990DesRH(oModel) }

oModel := MPFormModel():New( "TECA990", /*bPreValidacao*/, bPosValidacao, /*bCommit*/ , /*bCancel*/ )

aAux := FwStruTrigger("T4A_TIPDEV","T4A_STATUS","AT990LgEfe()",.F.,Nil,Nil,Nil) 				
oStDT4A:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

lLegend := .T.

oStDT4A:AddField("","","T4A_STATUS","BT",1,0,{|| AT990GetLE() }/*bValid*/,/*bWhen*/, /*aValues*/,.F.,{||AT990LgEfe()},/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Status"

oModel:AddFields('T4AMASTER',/*cOwner*/ , oStMT4A)
oModel:AddGrid( 'T4ADETAIL', 'T4AMASTER', oStDT4A, {|oModelGrid, nLine, cAction, cField, xValue, xOldValue|AT990VldEPI(oModelGrid, nLine, cAction, cField, xValue, xOldValue)}/*bPreValidacao*/, /*{|oModel|A200PVlCO2(oModel)}*//*bPosValidacao*/, /*bCarga*/ )

oModel:SetRelation('T4ADETAIL', { { 'T4A_FILIAL', 'xFilial("T4A")' } , { 'T4A_MAT', 'T4A_MAT' } }, T4A->(IndexKey(1)) )

oModel:GetModel('T4AMASTER'):SetDescription(STR0004)	//"Funcionário"
oModel:GetModel('T4ADETAIL'):SetDescription(STR0005)	//"Materais"

oModel:GetModel('T4ADETAIL'):SetOptional( .T. )

oModel:GetModel( 'T4ADETAIL' ):SetNoInsertLine( .T. )	//Bloqueia inclusão de novas linhas 
oModel:GetModel( 'T4ADETAIL' ):SetNoDeleteLine( .T. )	//Bloqueia exclusão de registros

oModel:SetPrimaryKey({'T4A_FILIAL', 'T4A_MAT', 'T4A_CODEPI', 'T4A_ITEM' })

oModel:SetDescription(STR0006)	//"Funcionários x Materais"

Return oModel

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição da Interface (View)
@param  Nenhum
@return oView, Objeto, oView 
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel 	:= ModelDef()
Local CposCab	:= "T4A_TIPDEV, T4A_ITEM, T4A_CODEPI, T4A_CODEPI, T4A_DESC, T4A_DFOLHA, T4A_FORNEC, T4A_LOJA, T4A_NUMCAP, T4A_DTVENC,T4A_DTENTR, T4A_HRENTR, T4A_QTDENT,T4A_PRV1,T4A_CODTFS,T4A_NREDUZ,T4A_TPMAT,T4A_MOTIVO,T4A_CODTFL,T4A_LOCAL, T4A_CODPAI, T4A_DSCGFH" 
Local CposIte	:= "T4A_MAT, T4A_NOME, T4A_CODTEC, T4A_NOMTEC" 
Local oStMT4A 	:= FWFormStruct(2,'T4A',{|cCampo| !AllTrim(cCampo) $ CposCab })
Local oStDT4A	:= FWFormStruct(2,'T4A',{|cCampo| !AllTrim(cCampo) $ CposIte })

oView := FWFormView():New()

oView:SetModel(oModel)

//Campo virtual usado para habilitar STATUS/Legenda do item
oStDT4A:AddField("T4A_STATUS","01",STR0016,STR0016,{},"BT","",Nil,Nil,.F.,"",Nil,Nil,Nil,Nil,.T.,Nil)	//"Status"###"Status"	

oView:AddField('VIEW_T4A_C', oStMT4A, 'T4AMASTER')
oView:AddGrid( 'VIEW_T4A_I', oStDT4A, 'T4ADETAIL')

oView:CreateHorizontalBox('SUPERIOR', 30)
oView:CreateHorizontalBox('INFERIOR', 70)

oView:SetOwnerView('VIEW_T4A_C', 'SUPERIOR')
oView:SetOwnerView('VIEW_T4A_I', 'INFERIOR')

oView:EnableTitleView("VIEW_T4A_C",STR0004)	//"Funcionário"	
oView:EnableTitleView("VIEW_T4A_I",STR0005)	//"Materiais"

oView:AddIncrementField( 'VIEW_T4A_I', 'T4A_ITEM' )

oView:SetViewProperty("VIEW_T4A_I", "GRIDDOUBLECLICK", {{|oFormulario,cFieldName,nLineGrid,nLineModel| AT990DClck(oFormulario,cFieldName)}})

oView:AddUserButton( STR0020 ,"CLIPS",{|oView| AT990IntWord(oModel,.T.) })	//"Impressão de Documentos"

Return oView

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990GetLE
Exibe legendas disponiveis para o itens
@param  Nenhum
@return .T., Lógico, Verdadeiro 
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT990GetLE()

Local	oLegenda := FwLegend():New()

If	lLegend         

	oLegenda:Add( "", "BR_VERDE"   	, STR0007 )	//"Entregue Supervisor"
	oLegenda:Add( "", "BR_AMARELO" 	, STR0008 )	//"Entregue Funcionário"
	oLegenda:Add( "", "BR_VERMELHO"	, STR0009 )	//"Devolvido Operacional"
	oLegenda:Add( "", "BR_AZUL"		, STR0010 )	//"Devolução Concluída"	
	
	oLegenda:View()
	DelClassIntf()
	
EndIf

lLegend := .F.
                                                                                                                                          
Return(.T.)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990LgEfe
Atualiza o campo T4A_STATUS (Legenda)  
@param  Nenhum
@return cRetorno, Caracter, Cor da LEGENDA que será atualizada no campo T4A_STATUS 
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT990LgEfe()

Local oModel	:= FWModelActive()
Local oStDT4A 	
Local cStatus 	:= ""
Local cRetorno	:= "BR_VERDE"

lLegend := .F.

If	oModel <> NIL 

	If oModel:GetId() == "TECA990"
	
		oStDT4A 	:= oModel:GetModel("T4ADETAIL")
	
		If oStDT4A:GetLine() == 0
			cStatus := T4A->T4A_TIPDEV 
		Else
			cStatus := oStDT4A:GetValue("T4A_TIPDEV") 
		EndIf
		
		If cStatus == "1" 
			cRetorno := "BR_VERDE"
		ElseIf cStatus == "2"
			cRetorno := "BR_AMARELO"
		ElseIf cStatus == "3"
			cRetorno := "BR_VERMELHO"
		Else		 
			cRetorno := "BR_AZUL"
		EndIf
		
	EndIf	

Endif 

Return(cRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990DClck
Quando DUPLO CLICK em cima do campo T4A_STATUS aciona tela de legenda (AT990GetLE)
@param  oFormulario, Objeto, Formulário posicionado  
@param  cField, Caracter, Nome do campo   
@return .T., Lógico, Verdadeiro
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT990DClck(oFormulario,cField)

Local oModel := FwModelActive()
 
If !oModel:GetModel('T4ADETAIL'):IsEmpty()
      If  cField == 'T4A_STATUS'
      		lLegend := .T.
            AT990GetLE()
      EndIf 
EndIf

Return .T.

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990VldEPI
Realiza PRE-VALIDACAO no campos T4A_TIPDEV para saber se pode ou não realizar alteração
@param  oModelGrid, Objeto, Modelo posicionado  
@param  nLine, Númerico, Linha posicionada
@param  cAction, Caracter, Ação realizada 
@param  cField, Caracter, Nome do campo sendo alterado
@param  xValue, Caracter, Conteudo a ser aplicado no campo
@param  xOldValue, Caracter, Conteudo antes da alteração do campo
@return lRetorno, Lógico, Verdadeiro ou Falso
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT990VldEPI(oModelGrid, nLine, cAction, cField, xValue, xOldValue)

Local lRetorno 	:= .T.

oModelGrid:GoLine(nLine)

If	cField == "T4A_TIPDEV"   

	If	xOldValue == "4" .AND. oModelGrid:GetValue("T4A_DFOLHA") == "1"
		MsgAlert(STR0012,STR0011)	//"Alteração de tipo de devolução não permitida. Motivo: devolução já concluída!"###"Atenção"	
		lRetorno := .F.
	Endif
	
	If	xValue == "4" 
		IF	MsgYesNo(STR0013,STR0011)	//"Gerar lançamento de desconto em folha de pagamento ?"###"Atenção"
			oModelGrid:SetValue("T4A_DFOLHA", "1" )
		Endif 
	Endif 	

Endif 

Return(lRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990DesRH
 Realiza gravação de verda de desconto no modulo de gestão de pessoas durante a pós-validação da gravação
@param  oModel, Objeto, Model posicionado   
@return lRetorno, Lógico, Verdadeiro
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT990DesRH(oModel)

Local aArea			:= GetArea()
Local aSaveLines  	:= FWSaveRows()
Local lRetorno  	:= .T.
Local oStMT4A 		:= oModel:GetModel("T4AMASTER")
Local oStDT4A 		:= oModel:GetModel("T4ADETAIL")
Local nI			:= 0
Local nOpc			:= 3 
Local aCabec		:= {}
Local aItens		:= {}
Local cPeriodo 		:= ""
Local cRoteiro 		:= ""
Local cTxtLog		:= ""
Local aPerAtual 	:= {}
Local cNumPagto		:= ""
Local aDesVerba		:= {}
Local cVerba		:= SuperGetMv("MV_TECVBGP",,"648")	//Verba usada para desconto de EPI em folha de pagamento 
Local lGera			:= .T.
Local nSomaDesc		:= 0

Private lMsErroAuto := .F. 			// Informa a ocorrência de erros no ExecAuto

dbSelectARea("SRA")
dbSetOrder(1)
If	dbSeek(xFilial("SRA")+oStMT4A:GetValue("T4A_MAT"))

	cRoteiro 	:= At353GtRot()
	
	//Verifica roteiro da Folha		
	If	Empty(cRoteiro)	
		cTxtLog := STR0042 + STR0044 + CRLF	//"Erro ao carregar roteiro de calculo."###" Geração de desconto cancelada.  Solicitei a correção e refaça a gravação."
		Aviso(STR0041, cTxtLog ,{STR0040})	//"Inconsistência""###"Ok"
		lGera := .F.	
	EndIF
	
	If	lGera

		//Verifica periodo
		If	fGetPerAtual( @aPerAtual, NIL, SRA->RA_PROCES, cRoteiro )					
			cPeriodo 	:= aPerAtual[1,1]
			cNumPagto	:= aPerAtual[1,2]				
		Else
			cTxtLog := STR0043 + STR0044 + CRLF	//"Erro ao carregar período atual.###"Geração de desconto cancelada.  Solicitei a correção e refaça a gravação."
			Aviso(STR0041, cTxtLog ,{STR0040})	//"Inconsistência"###"Ok"
			lGera := .F.	
		EndIf
		
	Endif 		

	If	lGera

		dbSelectArea("RGB")
		dbSetOrder(1)
		If	dbSeek(SRA->RA_FILIAL + SRA->RA_MAT)
			nOpc := 4
		Else
			nOpc := 3
		EndIf
		
	Endif 		
	
	For nI:=1 To oStDT4A:Length()

		oStDT4A:GoLine(nI)
	
		If	oStDT4A:GetValue("T4A_TIPDEV") == "4" .AND. oStDT4A:GetValue("T4A_DFOLHA") == "1" .AND. oStDT4A:GetValue("T4A_DSCGFH") == "2"
			nSomaDesc += ( oStDT4A:GetValue("T4A_QTDENT") * oStDT4A:GetValue("T4A_PRV1") )
			If	lGera
				oStDT4A:SetValue("T4A_DSCGFH", "1" )	//Grava 1=SIM para informar a gravação da verba	
			Else 
				oStDT4A:SetValue("T4A_DFOLHA", "2" ) 	//Retorna STATUS para 2=NÃO indicando que não houve desconto em folha
			Endif 				
		Endif
		
	Next nI		
	
	If	nSomaDesc > 0 .AND. lGera 
	
		aadd(aCabec,{'RA_FILIAL' , SRA->RA_FILIAL		, Nil })
		aadd(aCabec,{'RA_MAT'    , SRA->RA_MAT			, Nil })
		aadd(aCabec,{'CPERIODO'  , cPeriodo            	, Nil })
		aadd(aCabec,{'CROTEIRO'  , cRoteiro            	, Nil })
		aadd(aCabec,{'CNUMPAGTO' , cNumPagto           	, Nil })

		aAdd(aDesVerba,{"RGB_FILIAL" , xFilial("RGB")	, Nil })
		aAdd(aDesVerba,{"RGB_MAT"    , SRA->RA_MAT    	, Nil })
		aAdd(aDesVerba,{"RGB_PROCESS", SRA->RA_PROCES 	, Nil })
		aAdd(aDesVerba,{"RGB_PD"     , cVerba         	, Nil })
		aAdd(aDesVerba,{"RGB_TIPO1"  , "V"            	, Nil })
		aAdd(aDesVerba,{"RGB_HORAS"  , 0				, Nil })
		aAdd(aDesVerba,{"RGB_VALOR"  , nSomaDesc		, Nil })			
		aAdd(aDesVerba,{"RGB_CC"     , SRA->RA_CC	   	, Nil })
		aAdd(aDesVerba,{"RGB_CODFUN" , SRA->RA_CODFUNC	, Nil })
		aAdd(aDesVerba,{"RGB_SEMANA" , cNumPagto		, Nil })
		Aadd(aDesVerba,{"RGB_ROTORI" , "IGS"			, Nil })
		Aadd(aDesVerba,{"RGB_TIPO2"	 , "G"				, Nil })
		Aadd(aDesVerba,{"RGB_DTREF"	 , dDataBase		, Nil })	
		aadd(aItens, aDesVerba)			

		If	Len(aItens)> 0 	
		
			MsExecAuto( {|w,x,y,z| GPEA580(Nil,w,x,y,z)}, aCabec ,aItens, nOpc, 2)
		
			If	lMsErroAuto
				MostraErro()
				DisarmTransaction()
				Return .F.
			EndIf
		
		Endif 		

	Endif 

Endif 

FWRestRows( aSaveLines )

RestArea(aARea)
	
Return(lRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} TA0990EView
Habilita opções do botão OUTRAS AÇÃOES (com opção SALVAR/CANCELAR) e chama VIEW MANUALMENTE 
no modo de alteração.
@param  Nenhum 
@return Nenhum
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function TA0990EView()

Local aArea			:= GetArea()
	
Local aButtons 	:= { {.F.,Nil},;        //- Copiar
                	 {.F.,Nil},;        //- Recortar
                   	 {.F.,Nil},;        //- Colar
                   	 {.F.,Nil},;        //- Calculadora
                   	 {.F.,Nil},;        //- Spool
                   	 {.F.,Nil},;        //- Imprimir
                   	 {.T.,STR0014},;	//- Salvar
                   	 {.T.,STR0015},;  	//- Cancelar
                   	 {.F.,Nil},;        //- WalkThrough
                   	 {.F.,Nil},;        //- Ambiente
                   	 {.F.,Nil},;        //- Mashup
                   	 {.F.,Nil},;        //- Help
                   	 {.F.,Nil},;        //- Formulário HTML
                   	 {.F.,Nil};         //- ECM
            		}
            		
FWExecView( STR0003 , "TECA990", MODEL_OPERATION_UPDATE ,,,,,aButtons,,,,)	//"Alterar"

RestArea(aArea)

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990IntWord
Interface para marcação (seleção) de modelo a ser impresso (integração) 
@param  oModel, Objeto, oModel Posicionado 
@param  lVisible, Lógico, Quando .T. (verdadeiro) durante a integração o Word fica aberto, caso contrario não é exibido para o usuário  
@return Nenhum
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function AT990IntWord(oModel,lVisible)

Local oDlgWord
Local oCheMd1 
Local oCheMd2
Local lCheMd1 	:= .F. 
Local lCheMd2 	:= .F.

DEFINE MSDIALOG oDlgWord TITLE STR0020 From 145,0 To 290,305 OF oMainWnd PIXEL	//"Impressão de Documentos"

@ 05,05 TO 050,150 LABEL STR0021 OF oDlgWord  PIXEL	//"Marque o(s) documento(s) para impressão:"

@ 021, 013 CHECKBOX oCheMd1 VAR lCheMd1 PROMPT STR0022	SIZE 100, 010 OF oDlgWord PIXEL	//"Termo de Responsabilidade"
@ 033, 013 CHECKBOX oCheMd2 VAR lCheMd2 PROMPT STR0023	SIZE 100, 010 OF oDlgWord PIXEL	//"Solicitação de Uniforme"

DEFINE SBUTTON FROM 055,092 TYPE 1 ACTION ( AT990ModSel(lCheMd1,lCheMd2,oModel,lVisible,oDlgWord)  ) ENABLE OF oDlgWord
DEFINE SBUTTON FROM 055,122 TYPE 2 ACTION oDlgWord:End() ENABLE OF oDlgWord

ACTIVATE MSDIALOG oDlgWord CENTERED
	
RETURN 

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990ModSel
Realiza a impressão (integração) do modelo marcado. 
@param  lMod01, Lógico, Variável usada para marcar modelo 1 - Termo de Responsabilidade
@param  lMod02, Lógico, Variável usada para marcar modelo 2 - Solicitação de Uniforme 
@param  oModel, Objeto, oModel Posicionado 
@param  lVisible, Lógico, Quando .T. (verdadeiro) durante a integração o Word fica aberto, caso contrario não é exibido para o usuário  
@param  oDlgWord, Objeto, Objeto da interface de seleção
@return lRetorno, Lógico, Verdadeiro ou Falso
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function AT990ModSel(lMod01,lMod02,oModel,lVisible,oDlgWord)

Local lRetorno		:= .T.
Local cPathFinal 	:= AllTrim(SuperGetMv("MV_PATTERM"))	//Diretorio que sera gravado o documento final ( c:\wordtmp )
Local cDocumentos	:= ""

If	lMod01
	MsgRun( STR0018 + STR0022 , STR0019 ,{|| lRetorno := AT990ImpWord(STR0022,oModel,lVisible) } )	//"Imprimindo: "###""Termo de Responsabilidade"###""Aguarde"	
Endif 	

If	lMod02	
	MsgRun( STR0018 + STR0023 , STR0019 ,{|| lRetorno := AT990ImpWord(STR0023,oModel,lVisible) } )	//"Imprimindo: "###""Solicitação de Uniforme"###Aguarde"
Endif 	

If	!lMod01 .AND. !lMod02
	MsgAlert(STR0024,STR0025)	//"Nenhum modelo selecionado para impressão"###"Atenção"
	lRetorno := .F.
Else

	If	lRetorno
	
		cDocumentos := Alltrim ( STR0037 + If(lMod01,STR0022,"") + If(lMod01 .AND. lMod02 , STR0038 , "") + Chr(13) + Chr(10) +If(lMod02,STR0023,"") )	//"Documento(s): "###" e "
		cDocumentos += Chr(13) + Chr(10)
		cDocumentos += STR0039 + cPathFinal	//"Salvo(s) na pasta: "   
	
		Aviso(STR0020, cDocumentos ,{STR0040})	//"Ok"
		
	Endif 

	oDlgWord:End()	
	
Endif  	

Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990ImpWord
Aciona integração com o Word (impressão do modelo selecionado) 
@param  cModWord, Caracter, Nome do Modelo
@param  oModel, Objeto, oModel Posicionado 
@param  lVisible, Lógico, Quando .T. (verdadeiro) durante a integração o Word fica aberto, caso contrario não é exibido para o usuário
@return lRetorno, Lógico, Verdadeiro ou Falso
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function AT990ImpWord(cModWord,oModel,lVisible)

Local aArea			:= GetArea()
Local lRetorno     	:= .F.
Local cPathOri		:= AllTrim(SuperGetMv("MV_PATWORD"))	//Diretorio que esta todos componentes ( c:\wordstd )
Local cPathServer	:= Alltrim(SuperGetMv("MV_TECPATH"))	//Diretorio que estao os DOTS originais
Local cPathFinal 	:= AllTrim(SuperGetMv("MV_PATTERM"))	//Diretorio que sera gravado o documento final ( c:\wordtmp )
Local aWord			:= {}
Local aFuncVincula	:= {}
Local nAp			:= 1
Local nFu			:= 1
Local cLocalModelo	:= ""
Local cLocalSalva	:= ""
Local cArquivo		:= ""
Local lIntegra		:= .T.

lIntegra := At990TstGrv(cPathServer,cPathOri,cPathFinal,cModWord)

If	lIntegra

	aFuncVincula := At990CrVinc(oModel,cModWord)
	
	For nAp:=1 To Len(aFuncVincula)
	
		cLocalModelo 	:= cPathOri
		cLocalSalva		:= cPathFinal
		
		If	!ExistDir(cLocalSalva)	
			If	MAKEDIR(cLocalSalva) <> 0
				lIntegra := .F.			
			Endif  
		Endif
		
		If	lIntegra	 			
		
			For nFu:=1 To Len(aFuncVincula[nAp,2])
		
				aAdd(aWord,OLE_CreateLink('TMsOleWord97',,.T.))
			
				If ValType(aWord[nFu]) == "C" .AND. (aWord[nFu] >= "0")

					OLE_NewFile( aWord[nFu], cLocalModelo+cModWord+".DOT" )
		
					OLE_SetProperty(aWord[nFu], oleWdWindowState,"MAX" )
					OLE_SetProperty(aWord[nFu], oleWdVisible  ,lVisible)
					OLE_SetProperty(aWord[nFu], oleWdPrintBack,.T. )
		    
					//Atualiza variaveis e tabelas do DOT
					AT990Vari(	aWord[nFu],;
								aFuncVincula[nAp,02][nFu],; 
								aFuncVincula[nAp,03],;
								aFuncVincula[nAp,04],;
								aFuncVincula[nAp,05],;
								aFuncVincula[nAp,06],;
								aFuncVincula[nAp,07],;
								aFuncVincula[nAp,08],;
								aFuncVincula[nAp,09],;
								aFuncVincula[nAp,10],;
								cModWord )	
				
					OLE_UpdateFields(aWord[nFu])
		
					OLE_SetProperty( aWord[nFu], '208', .F. )
				
					cArquivo := cModWord +" - "+ aFuncVincula[nAp,2][nFu][1] + " - " + aFuncVincula[nAp,2][nFu][2]
				
					OLE_SaveAsFile(aWord[nFu],cLocalSalva+"\"+cArquivo+".DOC",,,.F.,oleWdFormatDocument)
		
					If	!lVisible
						OLE_CloseLink(aWord[nFu])
					Endif 						
		
					lRetorno := .T.
				
				Else
					Help( ,, "AT990ImpWord",, STR0026 , 1, 0 )	//"Integração com Word não realizada.  Ocorreram problemas na comunicação com o Word. Refaça a impressão. "
					lRetorno := .F.
				Endif
			
			Next nFu
			
		Else
		
			MsgAlert(STR0026,STR0025)	//"Impressão cancelada. Usuário sem permissão para salvar arquivos na unidade!"###"Atenção"
			lRetorno := .F.
			Exit 			
			
		Endif 			 			

	Next nAp
	
	If	Len(aFuncVincula) == 0
		MsgInfo( STR0027 + cModWord ,STR0028 )	//"Não encontrado nenhum vinculo de funcionário incluído ou alterado liberado para impressão do: "###"Impressão Cancelada"
		lRetorno := .F.
	Else
		lRetorno := .T.	
		OLE_CloseLink(aWord[1])	
	Endif  
	 
Endif 	

RestArea(aArea)

Return lRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT990Vari
Preenche as variáveis e tabelas usadas no modelo 
@param  cModWord, Caracter, Nome do Modelo
@param  aFuncVincula, Array, Array contendo os vinculos dos funcionarios e produtos (EPI/UNIFORMES) feitos para ao apontamento
@param  cCodEnt, Caracter, Codigo da Entidade (cliente/prospect)
@param  cLojEnt, Caracter, Loja da Entidade
@param  cNomeEnt, Caracter, Nome da Entidade
@return Nenhum
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function AT990Vari(cModelo, aFuncVincula, cOrcamento, cCodEnt, cLojEnt, cNomeEnt, cDposto, cNomePosto, cDarea, cNomeArea, cModWord)

Local nProd			:= 1
Local cNomeEmp		:= Upper(Rtrim(SM0->M0_NOMECOM))
Local cEndeEmp		:= STR0033 + Upper(Rtrim(SM0->M0_ENDCOB))	//"Endereço: "
Local cLocalDtAss	:= Upper(Rtrim(SM0->M0_CIDCOB))+", " + StrZero(Day(dDataBase),2)+ STR0034 + MesExtenso(dDataBase)+ STR0034 + StrZero(Year(dDataBase),4)	//" de "###" de "
Local nModSel		:= If(cModWord == STR0022 ,1,2)	//"Termo de Responsabilidade"
Local nTotSomPro	:= 0 

///---> As variáveis abaixo são preenchidas através da inclusão de DOCVARIABLE feitas no modelo (DOT): Termo de Responsabilidade.DOT / Solicitação de Uniforme.DOT 
OLE_SetDocumentVar(cModelo, "cNomeEmp"   			, cNomeEmp 					)	//Nome da empresa (CABEÇALHO)
OLE_SetDocumentVar(cModelo, "cEndeEmp"   			, cEndeEmp  				)	//Endereço da empresa (CABEÇALHO)
OLE_SetDocumentVar(cModelo, "cNumTermo"   			, "*"+cOrcamento+"*"		)	//Número do Termo de Responsabilidade
OLE_SetDocumentVar(cModelo, "cDataImp"   			, dDataBase  				)	//Data da Impressão
OLE_SetDocumentVar(cModelo, "cHoraImp"    			, Time()	  				)	//Hora da Impressão
OLE_SetDocumentVar(cModelo, "cLocalDtAss"   		, cLocalDtAss 				)	//Local e Data de Assinatura
OLE_SetDocumentVar(cModelo, "cdMatricula"    		, aFuncVincula[1]           )	//Código do Funcionário (matricula)
OLE_SetDocumentVar(cModelo, "cNomeFuncionario"   	, aFuncVincula[2]           )	//Nome do Funcionário
OLE_SetDocumentVar(cModelo, "cdCliente"  		    , cCodEnt + " " + cLojEnt	)	//Código da entidade (cliente/Prospect)
OLE_SetDocumentVar(cModelo, "cNomeCliente"    		, cNomeEnt		          	)	//Loja da entidade (cliente/Prospect)
OLE_SetDocumentVar(cModelo, "cdPosto"      			, cDposto  				  	)	//Código do Posto (Código da Função)
OLE_SetDocumentVar(cModelo, "cNomePosto"      		, cNomePosto         		)	//Nome do Posto (Nome da Função)
OLE_SetDocumentVar(cModelo, "cdArea"  	    		, cDarea        			)	//Código do local de atendimento
OLE_SetDocumentVar(cModelo, "cNomeArea"      		, cNomeArea          		)	//Nome  do local de atendimento

///---> A tabela abaixo é preenchida no modelo (DOT: Termo de Responsabilidade) através do indicado: nProdutos e MACRO: Produtos()
If	nModSel == 1

	For nProd:=1 To Len(aFuncVincula[3])
		
		OLE_SetDocumentVar(cModelo,"cDesc"		+Alltrim(str(nProd))+"1" 	,If( !Empty(aFuncVincula[3][nProd][1]) , aFuncVincula[3][nProd][1] , "-"))
		OLE_SetDocumentVar(cModelo,"cNumcap"	+Alltrim(str(nProd))+"2" 	,If( !Empty(aFuncVincula[3][nProd][2]) , aFuncVincula[3][nProd][2] , "-"))
		OLE_SetDocumentVar(cModelo,"cDtvenc"	+Alltrim(str(nProd))+"3" 	,If( !Empty(aFuncVincula[3][nProd][3]) , Dtoc(aFuncVincula[3][nProd][3]) , "-"))
		OLE_SetDocumentVar(cModelo,"cTpMat"		+Alltrim(str(nProd))+"4"	,If( !Empty(aFuncVincula[3][nProd][4]) , aFuncVincula[3][nProd][4] , "-"))
		OLE_SetDocumentVar(cModelo,"cQtdent"	+Alltrim(str(nProd))+"5" 	,If( !Empty(aFuncVincula[3][nProd][5]) , Transform(aFuncVincula[3][nProd][5],"@E 999.99") , "-"))
		OLE_SetDocumentVar(cModelo,"cDtentr"	+Alltrim(str(nProd))+"6" 	,If( !Empty(aFuncVincula[3][nProd][6]) , aFuncVincula[3][nProd][6] , "-"))
		
	Next nProd 	
	
	OLE_SetDocumentVar(cModelo,'nProdutos',alltrim(Str(nProd-1)))
	OLE_ExecuteMacro(cModelo,"Produtos")
	
Endif 	

///---> A tabela abaixo é preenchida no modelo (DOT: Solicitação de Uniforme) através do indicado: nUniformes e MACRO: Uniformes()
If	nModSel == 2

	For nProd:=1 To Len(aFuncVincula[3])
		
		OLE_SetDocumentVar(cModelo,"cCodEPI"	+Alltrim(str(nProd))+"1" 	,If( !Empty(aFuncVincula[3][nProd][1]) , aFuncVincula[3][nProd][1] , "-"))
		OLE_SetDocumentVar(cModelo,"cDesEPI"	+Alltrim(str(nProd))+"2" 	,If( !Empty(aFuncVincula[3][nProd][2]) , aFuncVincula[3][nProd][2] , "-"))
		OLE_SetDocumentVar(cModelo,"cQtdent"	+Alltrim(str(nProd))+"3" 	,If( !Empty(aFuncVincula[3][nProd][3]) , Transform(aFuncVincula[3][nProd][3],"@E 999.99") , "-"))
		OLE_SetDocumentVar(cModelo,"cPrcVen"	+Alltrim(str(nProd))+"4" 	,If( !Empty(aFuncVincula[3][nProd][4]) , Transform(aFuncVincula[3][nProd][4],"@E 999,999,999.99") , "-"))
		OLE_SetDocumentVar(cModelo,"cSomPro"	+Alltrim(str(nProd))+"5" 	,If( !Empty(aFuncVincula[3][nProd][5]) , Transform(aFuncVincula[3][nProd][5],"@E 999,999,999.99") , "-"))		
		OLE_SetDocumentVar(cModelo,"cDtentr"	+Alltrim(str(nProd))+"6" 	,If( !Empty(aFuncVincula[3][nProd][6]) , aFuncVincula[3][nProd][6] , "-"))
		
		nTotSomPro += aFuncVincula[3][nProd][5]
		
	Next nProd
	
	OLE_SetDocumentVar(cModelo, "cTotSomPro"  	, Transform(nTotSomPro,"@E 999,999,999.99") )
	
	OLE_SetDocumentVar(cModelo,'nUniformes',alltrim(Str(nProd-1)))
	OLE_ExecuteMacro(cModelo,"Uniformes")
	
Endif

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At990CrVinc

@param  oModel, Objeto, oModel Posicionado
@return aFuncVincula, Array, Array contendo os vinculos dos funcionarios e produtos (EPI/UNIFORMES) feitos para ao apontamento
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At990CrVinc(oModel,cModWord) 

Local aArea			:= GetArea()
Local aSaveLines  	:= FWSaveRows()
Local lRetorno		:= .T.
Local nITFS			:= 1
Local nIT4A			:= 1
Local oModelTFS 	:= oModel:GetModel('TFSGRID')
Local oModelT4A   	
Local aFuncVincula	:= {} 
Local aFuncionarios	:= {}
Local aProdutos		:= {}
Local aUniformes	:= {}
Local cFuncAnt		:= ""
Local cTpMaterial	:= ""
Local aRetFuncao	:= {}
Local cCodTFL 		:= ""
Local cCodTFS		:= ""
Local cCodLocal		:= ""
Local cOrcamento	:= ""
Local cCodMat		:= ""
Local cCodEnt 		:= ""
Local cLojEnt 		:= ""
Local cNomeEnt 		:= ""
Local aPreMAT		:= {}
Local nPre			:= 1
Local nModSel		:= If(cModWord == STR0022 ,1,2)	//"Termo de Responsabilidade"	
Local nTotProd		:= 0

If	oModel:GetId()=='TECA890'	//Rotina de Apontamento de Materiais

	oModelT4A:= oModel:GetModel('T4AGRID')
	
	For nITFS :=1 To oModelTFS:Length() 
		
		oModelTFS:GoLine(nITFS)
			
		If	!oModelTFS:IsDeleted() .AND. oModelTFS:GetValue("TFS_TPMAT") $ "2|3"
		
			For nIT4A :=1 To oModelT4A:Length()
			
				oModelT4A:GoLine(nIT4A)
				
				If	oModelT4A:IsInserted() .OR. oModelT4A:IsUpdated() 
				
					aAdd(aPreMAT,{	oModelTFS:GetValue("TFS_CODTFG"),; 
									oModelT4A:GetValue("T4A_MAT"),;
									oModelT4A:GetValue("T4A_CODTFL"),;
									oModelT4A:GetValue("T4A_LOCAL"),;
									oModelT4A:GetValue("T4A_CODPAI"),;
									oModelT4A:GetValue("T4A_NOME"),;
									oModelT4A:GetValue("T4A_TPMAT"),; 
									oModelT4A:GetValue("T4A_DESC"),;									
									oModelT4A:GetValue("T4A_NUMCAP"),;									  
									oModelT4A:GetValue("T4A_DTVENC"),;									  
									If(oModelT4A:GetValue("T4A_TPMAT") == "2" , STR0035 , STR0036 )	,;	
									oModelT4A:GetValue("T4A_QTDENT"),;									
									oModelT4A:GetValue("T4A_DTENTR"),;									
									oModelT4A:GetValue("T4A_CODEPI"),;
									oModelT4A:GetValue("T4A_PRV1")	})
									
				Endif 									
		
			Next nIT4A 		
		
		Endif
		
	Next nITFS 	
	
	If	Len(aPreMAT) > 0
	
		aSort(aPreMAT,,,{|x,y| x[2]<y[2]})
		
		cTFSANT := ""
	
		For	nPre:= 1 To Len(aPreMAT)
		
			If	cFuncAnt <> aPreMAT[nPre,2]
			
				If	Len(aFuncionarios) > 0
				
					aFuncionarios[Len(aFuncionarios)][03]	:= If( nModSel == 1 , aClone(aProdutos), aClone(aUniformes) )
					
					aRetFuncao 	:= At990Funcao(aPreMAT[nPre,3],aPreMAT[nPre,4],aPreMAT[nPre,5],cTFSANT)
					aRetLocal 	:= At990Local(aPreMAT[nPre,4])
					
					aAdd(aFuncVincula,{"",aClone(aFuncionarios),aPreMAT[nPre,5],aRetLocal[1,1],aRetLocal[1,2],aRetLocal[1,4],aRetFuncao[1,1],aRetFuncao[1,2],aPreMAT[nPre,4],aRetLocal[1,3]})
				
					aProdutos 		:= {}
					aUniformes		:= {}
					aFuncionarios	:= {}
					
				Endif 														
			
				aAdd(aFuncionarios	,{	aPreMAT[nPre,2]		,;		//Matricula
										aPreMAT[nPre,6]		,;		//Nome do Funcionario
										{}					})
																	
			Endif
			
			If	nModSel == 1
			
				aAdd(aProdutos		,{	aPreMAT[nPre,08],;		
										aPreMAT[nPre,09],;		  
										aPreMAT[nPre,10],;		  
										aPreMAT[nPre,11],;		
										aPreMAT[nPre,12],;		
										aPreMAT[nPre,13] })		
										
			Else
			
				nTotProd := ( aPreMAT[nPre,12] * oModelT4A:GetValue("T4A_PRV1") )
									
				aAdd(aUniformes		,{	aPreMAT[nPre,14]	,; 
										aPreMAT[nPre,08]	,; 									     
										aPreMAT[nPre,12]	,; 
										aPreMAT[nPre,15]	,; 
										nTotProd			,; 
										aPreMAT[nPre,13]	}) 
			 
			Endif 										
									
			cFuncAnt := aPreMAT[nPre,2]	
			cTFSANT	 := aPreMAT[nPre,1]
			
			If	nPre == Len(aPreMAT)	
				aFuncionarios[Len(aFuncionarios)][03]	:= If( nModSel == 1 , aClone(aProdutos), aClone(aUniformes) )
				
				aRetFuncao 	:= At990Funcao(aPreMAT[nPre,3],aPreMAT[nPre,4],aPreMAT[nPre,5],,cTFSANT)
				aRetLocal 	:= At990Local(aPreMAT[nPre,4])
				
				aAdd(aFuncVincula,{"",aClone(aFuncionarios),aPreMAT[nPre,5],aRetLocal[1,1],aRetLocal[1,2],aRetLocal[1,4],aRetFuncao[1,1],aRetFuncao[1,2],aPreMAT[nPre,4],aRetLocal[1,3]})
			
			Endif 
			
		Next nPre
									     
	Endif 								  
	
Else

	//Quando rotina de Funcionários x Materiais entregues  
	
	oModelT4A 	:= oModel:GetModel('T4ADETAIL')
	oModelT4M 	:= oModel:GetModel('T4AMASTER')

	cCodMat	:= oModelT4M:GetValue("T4A_MAT")
	cCodTFL 	:= oModelT4A:GetValue("T4A_CODTFL")
	cCodTFS 	:= oModelT4A:GetValue("T4A_CODTFS")
	cCodLocal	:= oModelT4A:GetValue("T4A_LOCAL")
	cOrcamento	:= oModelT4A:GetValue("T4A_CODPAI")
	
	aRetFuncao := At990Funcao(cCodTFL,cCodLocal,cOrcamento,cCodTFS)
	
	aAdd(aFuncVincula,{cCodTFL,{},"","","","","","","",""})	// Adiciona apontamento
	
	aAdd(aFuncionarios	,{	oModelT4M:GetValue("T4A_MAT")		,;		//Matricula
							oModelT4M:GetValue("T4A_NOME")		,;		//Nome do Funcionario
							{}									})
		
	For nIT4A :=1 To oModelT4A:Length()
			
		oModelT4A:GoLine(nIT4A)
		
		If	oModelT4M:GetValue("T4A_MAT") == cCodMat .AND. oModelT4A:GetValue("T4A_CODTFL") == cCodTFL .AND. oModelT4A:GetValue("T4A_LOCAL") == cCodLocal .AND. oModelT4A:GetValue("T4A_CODPAI") == cOrcamento  
		
			If	oModelT4A:GetValue("T4A_TPMAT") == "2"
				cTpMaterial := STR0035	//"EPI"
			Else
				cTpMaterial := STR0036	//"UNIFORME"				
			Endif 
			
			If	nModSel == 1 					
		
				aAdd(aProdutos		,{	oModelT4A:GetValue("T4A_DESC")		,;		
										oModelT4A:GetValue("T4A_NUMCAP")	,;		  
										oModelT4A:GetValue("T4A_DTVENC")	,;		  
										cTpMaterial							,;		
										oModelT4A:GetValue("T4A_QTDENT")	,;		
										oModelT4A:GetValue("T4A_DTENTR")	})		
										
			Else										

				nTotProd := ( oModelT4A:GetValue("T4A_QTDENT") * oModelT4A:GetValue("T4A_PRV1") )
									
				aAdd(aUniformes		,{	oModelT4A:GetValue("T4A_CODEPI")	,;
										oModelT4A:GetValue("T4A_DESC")		,;									     
										oModelT4A:GetValue("T4A_QTDENT")	,;
										oModelT4A:GetValue("T4A_PRV1")		,;
										nTotProd							,;
										oModelT4A:GetValue("T4A_DTENTR")	})
										
			Endif
													
		Endif 
				
	Next nIT4A
			
	aFuncionarios[Len(aFuncionarios)][3]	:= If( nModSel == 1 , aClone(aProdutos), aClone(aUniformes) )
	aFuncVincula[nITFS][2] 					:= aClone(aFuncionarios)
	
	aRetLocal := At990Local(cCodLocal)
	
	aFuncVincula[nITFS][03] := cOrcamento
	aFuncVincula[nITFS][04] := aRetLocal[1,1]
	aFuncVincula[nITFS][05] := aRetLocal[1,2]
	aFuncVincula[nITFS][06] := aRetLocal[1,4]
	aFuncVincula[nITFS][07] := aRetFuncao[1,1]
	aFuncVincula[nITFS][08] := aRetFuncao[1,2]
	aFuncVincula[nITFS][09] := cCodLocal
	aFuncVincula[nITFS][10] := aRetLocal[1,3]
			
Endif 				 			

FWRestRows( aSaveLines )
RestArea(aArea)

Return aFuncVincula

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At990Funcao
Retorna array contendo código da função e descrição (nome) que foram informados no orçamento de serviço.
@param  cCodTFL, Caracter, Código TFL
@param  cCodLocal, Caracter, Código do local de atendimento
@param  cOrcamento, Caracter, Código (número) do orçamento de serviço
@param  cCodTFS, Caracter, Código TFS
@return aFuncVincula, Array, Array contendo os vinculos dos funcionarios e produtos (EPI/UNIFORMES) feitos para ao apontamento
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At990Funcao(cCodTFL,cCodLocal,cOrcamento,cCodTFS,cCodTFG)

Local aArea		:= GetArea()
Local cQueryFUN	:= GetNextAlias()
Local aRetorno	:= {}
Local cNomeEnt	:= ""
Local cInner 		:= "%"
	
Default cCodTFS := ""
Default cCodTFG := ""

If !Empty(cCodTFS) 
	cInner += "INNER JOIN TFS010 TFS ON (TFS_FILIAL = '" +   xFilial('TFJ') + "' AND TFS_CODTFL 	= TFL_CODIGO AND TFS_CODIGO = '" +   cCodTFS + "' AND TFS.D_E_L_E_T_ <> '*' )
	cInner += "INNER JOIN TFG010 TFG ON (TFG_FILIAL = '" +   xFilial('TFG') + "' AND TFG_COD   	= TFS_CODTFG AND TFG.D_E_L_E_T_ <> '*' )
ElseIf !Empty(cCodTFG)
	cInner += "INNER JOIN TFG010 TFG ON (TFG_FILIAL = '" +   xFilial('TFG') + "' AND TFG_COD   	= '" +   cCodTFG + "'	 AND TFG.D_E_L_E_T_ <> '*' )
EndIf

cInner += "%"

BeginSql Alias cQueryFUN

	SELECT TFF_FUNCAO, RJ_DESC
	
	FROM %Table:TFL% TFL
	
    %exp:cInner%
	INNER JOIN TFF010 TFF ON (TFF_FILIAL = %exp:xFilial('TFF')% AND TFF_COD		= TFG_CODPAI AND TFF.%NotDel% )
	INNER JOIN SRJ010 SRJ ON (RJ_FILIAL  = %exp:xFilial('SRJ')% AND RJ_FUNCAO  	= TFF_FUNCAO AND SRJ.%NotDel% )
		
	WHERE	

		TFL_FILIAL = %exp:xFilial('TFL')%	AND  
		TFL_CODIGO = %exp:cCodTFL%			AND
		TFL_LOCAL  = %exp:cCodLocal%		AND	
		TFL_CODPAI = %exp:cOrcamento%		AND  
		TFL.%NotDel%	
		
EndSql

(cQueryFUN)->(dbGoTop())

If (cQueryFUN)->(!Eof())

	aAdd(aRetorno,{	(cQueryFUN)->TFF_FUNCAO,;	//Codigo do Posto (Função)
					(cQueryFUN)->RJ_DESC } )	//Nome do Posto (Função)
Endif 

IF Select( cQueryFUN ) > 0
	(cQueryFUN)->(dbCloseArea())
EndIf

RestArea(aArea)

Return(aRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At990Local
Retorna array contendo código da entidade, loja da entidade, descrição do local e nome da entidade.
@param  cCodLocal, Caracter, Codigo do local de atendimento
@return aRetorno, Array, Array contendo código da entidade, loja da entidade, descricao do local e nome da entidade
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At990Local(cCodLocal)

Local aRetorno	:= {}

dbSelectARea("ABS")
dbSetOrder(1)
If	dbSeek(xFilial("ABS")+cCodLocal)
		
	If	ABS->ABS_ENTIDA == '1'
		cNomeEnt := Posicione("SA1",1,xFilial("SA1")+ABS->ABS_CODIGO+ABS->ABS_LOJA,"A1_NOME")	//Cliente
	Else 
		cNomeEnt := Posicione("SUS",1,xFilial("SUS")+ABS->ABS_CODIGO+ABS->ABS_LOJA,"US_NOME")	//Prospect
	Endif 
		
	aAdd(aRetorno,{ABS_CODIGO,ABS_LOJA,ABS_DESCRI,cNomeEnt})
		
Endif 

Return aRetorno

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At990TstGrv
Testa a criação dos diretorios usados na integração e realiza copia do DOT na estação local
@param  cPathServer, Caracter, Caminho do servidor que contem o DOT original
@param  cPathOri, Caracter, Caminho na estação onde será copiado o DOT original 
@param  cPathFinal, Caracter, Caminho na estação onde será criado o modelo final 
@param  cModWord, Caracter, Nome do Modelo
@return lRetorno, Lógico, Verdadeiro ou Falso
@author Eduardo Gomes Júnior
@since 04/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At990TstGrv(cPathServer,cPathOri,cPathFinal,cModWord)

Local lRetorno		:= .T.

If	!ExistDir(cPathOri)
	If	MakeDir(cPathOri) <> 0 
		lRetorno := .F.
	Endif 
Endif

If	!ExistDir(cPathFinal)
	If	MakeDir(cPathFinal) <> 0
		lRetorno := .F.
	Endif 
Endif

If	lRetorno

	If	!File(cPathOri+""+cModWord+""+".DOT")
	
		If	File(cPathServer+""+cModWord+""+".DOT")
			__CopyFile( cPathServer+cModWord+".DOT" , cPathOri+cModWord+".DOT")
		Else
			MsgAlert( STR0029 + cModWord+ STR0030 +cPathServer+ STR0031  ,STR0011 )	//"Modelo:"".DOT não localizado no servidor (pasta:"###") impressão cancelada."###"Atenção" 
			lRetorno := .F.
		Endif 	
	
	Endif
	
Else

	MsgAlert(STR0028+" "+STR0032 ,STR0011)	//"Impressão cancelada" ###"Usuário sem permissão para salvar arquivos na unidade!"###"Atenção" 	
	
Endif 	 

Return lRetorno
