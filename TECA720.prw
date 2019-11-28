#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA720.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA720

Cadastro de Coletes - TE1
@author Serviços
@since 28/08/13

/*/
//----------------------------------------------------------------------------------------------------------------------
Function TECA720()

Local oBrowse

Private aRotina	:= MenuDef() 
Private cCadastro	:=STR0001// Cadastro de Coletes

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TE1')
oBrowse:SetDescription(STR0001) // Cadastro de Coletes
oBrowse:Activate()

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

Definição do MenuDef
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:aRotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static function MenuDef()
Local aRotina :={}

ADD OPTION aRotina TITLE STR0002 	ACTION 'PesqBrw' 				OPERATION 1 ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0003 	ACTION 'VIEWDEF.TECA720' 	OPERATION 2 ACCESS 0 //"Visualizar"
ADD OPTION aRotina TITLE STR0004 	ACTION 'VIEWDEF.TECA720' 	OPERATION 3 ACCESS 0 //"Incluir"
ADD OPTION aRotina TITLE STR0005	ACTION 'VIEWDEF.TECA720' 	OPERATION 4 ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0006 	ACTION 'VIEWDEF.TECA720' 	OPERATION 5 ACCESS 0 //"Excluir"
ADD OPTION aRotina TITLE STR0007	ACTION 'MSDOCUMENT'			OPERATION 7 ACCESS 0 //"Bco. Conhecimento"

Return(aRotina)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Model 
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:oModel
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel
Local oStruTE1		:= FWFormStruct(1,'TE1')
Local bPosValidacao	:= {|oModel|At720Vld(oModel)}
Local aAux				:= {}
Local aAux1			:= {}
Local aAux2			:= {}
Local bCommit			:= {|oModel|At720Commit(oModel)}

aAux := FwStruTrigger("TE1_LOJA","TE1_NOME","At720DescFor(1),At720DescFor(2)",.F.,Nil,Nil,Nil)
oStruTE1:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux1 := FwStruTrigger("TE1_CODPRO","TE1_DESPRO","At720DescPro()",.F.,Nil,Nil,Nil)
oStruTE1:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

aAux2 := FwStruTrigger("TE1_LOCAL","TE1_CLIDES","At720DscLoc()",.F.,Nil,Nil,Nil)
oStruTE1:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

oModel := MPFormModel():New('TECA720',/*bPreValidacao*/,bPosValidacao,bCommit,/*bCancel*/)
oModel:AddFields('TE1MASTER',/*cOwner*/,oStruTE1,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/,/*bFieldAbp*/)

oModel:SetPrimaryKey({"TE1_FILIAL","TE1_COD"})

Return(oModel)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View 
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:oView
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView
Local oModel   	:= FWLoadModel('TECA720')
Local oStruTE1 	:= FWFormStruct(2,'TE1',{|cCampo| !AllTrim(cCampo) $ "TE1_SINARM|TE1_DTSINA"})

oView:= FWFormView():New()
oView:SetModel(oModel)

oView:AddUserButton(STR0007, 'CLIPS',{|oView|MsDocument('TE1',TE1->(RECNO()),oModel:GetOperation() )}) //"Bco. Conhecimento"

//Adiciona o Link para Consulta do C.A
oView:AddUserButton(STR0008,"",{|oView|coTIBrowse(oModel)},,,) //Consulta C.A

oView:AddUserButton(STR0019, 'CLIPS',{|oView| At720Ocorr(FwFldGet("TE1_CODCOL"))}) //"Ocorrencias"

oView:AddUserButton(STR0020, 'CLIPS',{|oView| At720Manut(FwFldGet("TE1_CODCOL"))}) //"Manutenções"

oView:AddUserButton(STR0021, 'CLIPS',{|oView| At720Movim(FwFldGet("TE1_CODCOL"))}) //"Movimentações"

oStruTE1:RemoveField("TE1_ORIGEM")
oStruTE1:RemoveField("TE1_ENTIDA")
oStruTE1:RemoveField("TE1_PRVRET")
oStruTE1:RemoveField("TE1_CODMOV")

oView:AddField('VIEW_CAB',oStruTE1,'TE1MASTER')
oView:CreateHorizontalBox('SUPERIOR',100)
oView:SetOwnerView( 'VIEW_CAB','SUPERIOR' )

Return(oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Imp

Inclusão do Colete quando é adicionado uma nota Fiscal de Entrada
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Imp()
Local lRet := .T.

Processa( { || lRet := At720Inc() },STR0025,STR0026,.F.)//'Aguarde';'Realizando Inclusão de Coletes'

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Inc

Inclusão do Colete quando é adicionado uma nota Fiscal de Entrada
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Inc()
Local oModel		:= Nil
Local oAux			:= Nil
Local lRet 		:=.T.
Local aAreaSD1 	:= SD1->(GetArea())
Local aAreaSA2 	:= SA2->(GetArea())
Local nQuant		:= 0

DbSelectArea('SD1')
SD1->(DbSetOrder(2)) // A1_FILIAL+A1_COD+A1_LOJA
If SD1->(DbSeek(xFilial('SD1')+ SD1->D1_COD + SD1->D1_DOC + SD1->D1_SERIE + SD1->D1_FORNECE + SD1->D1_LOJA)) // Filial: 01, Código: 000001, Loja: 02

	DbSelectArea('SA2')
	SA2->(DbSetOrder(1))
	SA2->(DbSeek(xFilial("SA2") + SD1->D1_FORNECE + SD1->D1_LOJA))
	
	oModel :=FwloadModel('TECA720')
	
	For nQuant:= 1 To SD1->D1_QUANT

		oModel:SetOperation(3)
		oModel:Activate()
			
		oAux:= oModel:GetModel('TE1MASTER')
		lAux:= oModel:LoadValue('TE1MASTER','TE1_DOC',SD1->D1_DOC)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_SERIE',SD1->D1_SERIE)
		
		//Atualiza campo _SDOC dos documentos fiscais, caso habilitado
		If SerieNFId("TE1", 3, "TE1_SERIE") != "TE1_SERIE"					
			lAux:= oModel:LoadValue('TE1MASTER',SerieNFId("TE1", 3, "TE1_SERIE"), SerieNFId("SD1", 2, "D1_SERIE"))
		EndIf
		
		lAux:= oModel:LoadValue('TE1MASTER','TE1_DTNOTA',SD1->D1_EMISSAO)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_COMPRA',SD1->D1_EMISSAO)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_CODFOR',SD1->D1_FORNECE)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_LOJA',SD1->D1_LOJA)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_CODPRO',SD1->D1_COD)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_ITEM',SD1->D1_ITEM)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_SEQ',cValtoChar(nQuant))	
		lAux:= oModel:LoadValue('TE1MASTER','TE1_ORIGEM',"MATA103")
		lAux:= oModel:LoadValue('TE1MASTER','TE1_NOME',SA2->A2_NOME)
		lAux:= oModel:LoadValue('TE1MASTER','TE1_CNPJ',SA2->A2_CGC)
						
		If ( lRet := oModel:VldData() )
			// Se o dados foram validados faz-se a gravação efetiva dos dados (commit)
			lRet := oModel:CommitData()
		EndIf
		
	
		If !lRet
			// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou 
			//mensagem de aviso
			aErro := oModel:GetErrorMessage()
					 
			AutoGrLog( STR0009 + ' [' + AllToChar( aErro[1] ) + ']' ) //"Id do formulário de origem:"
			AutoGrLog( STR0010 + ' [' + AllToChar( aErro[2] ) + ']' ) //"Id do campo de origem: "
			AutoGrLog( STR0011 + ' [' + AllToChar( aErro[3] ) + ']' ) // "Id do formulário de erro: "
			AutoGrLog( STR0012 + ' [' + AllToChar( aErro[4] ) + ']' ) //"Id do campo de erro: "
			AutoGrLog( STR0013 + ' [' + AllToChar( aErro[5] ) + ']' ) //"Id do erro: "
			AutoGrLog( STR0014 + ' [' + AllToChar( aErro[6] ) + ']' ) // "Mensagem do erro: "
			AutoGrLog( STR0015 + ' [' + AllToChar( aErro[7] ) + ']' ) //"Mensagem da solução: "
			AutoGrLog( STR0016 + ' [' + AllToChar( aErro[8] ) + ']' ) //"Valor atribuído: "
			AutoGrLog( STR0017 + ' [' + AllToChar( aErro[9] ) + ']' )//"Valor anterior: "
		
			MostraErro()
					
			// Desativamos o Model 
			oModel:DeActivate()
			oModel:Destroy()
			
		EndIf
		
		oModel:DeActivate()
	
	Next nQuant

EndIf

// Desativamos o Model 
oModel:DeActivate()
oModel:Destroy()

RestArea(aAreaSD1)
RestArea(aAreaSA2)

Return lRet
		
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} coTIBrowse

Realiza a abertura do Link para verificação do C.A do Fornecedor
@author Serviços
@since 20/08/13
@version P11 R9

@Param oModel,Model do Cadastro
/*/
//--------------------------------------------------------------------------------------------------------------------
Function coTIBrowse(oModel)
Local oDlg
Local aSize	:=	{}
Local oMdl		:= oModel:GetModel("TE1MASTER") 
Local cUrl		:= SuperGetMV("MV_TECURL",,"") //"http://www3.mte.gov.br/sistemas/caepi/PesquisarCAInternetXSL.asp"	

aSize	:=	MsAdvSize()

oMainWnd:CoorsUpdate()  // Atualiza as corrdenadas da Janela MAIN
nMyWidth  := oMainWnd:nClientWidth - 10
nMyHeight := oMainWnd:nClientHeight - 30

DEFINE DIALOG oDlg TITLE STR0001 From aSize[7],00 To nMyHeight,nMyWidth PIXEL //"Cadastro de Coletes"

oTIBrowser := TIBrowser():New(05,05,nMyHeight-250, nMyWidth-820,cUrl,oDlg )
oTIBrowser:GoHome()

ACTIVATE DIALOG oDlg CENTERED 
Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Vld

Pos-Validação do cadastro de Coletes 
@author Serviços
@since 20/08/13
@version P11 R9

@Param oModel,Model do Cadastro
@Return ExpL: Retorna .T. quando houve sucesso na Inclusão
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At720Vld(oModel)
Local lRet       := .T.
Local nOperation := oModel:GetOperation()

//Não permite a exclusão quando a Situação for diferente de 1 ou foi alocado
If nOperation == 5
	If FwFldGet("TE1_SITUA") <> "1" .Or. !Empty(FwFldGet("TE1_LOCAL"))
		Help( "", 1, "At720Situa" )
		lRet := .F.
	EndIf
EndIf

If (nOperation == 3 .Or. nOperation == 4) .And. (!Empty(FwFldGet("TE1_LOCAL")))
	If !At720Status()
		Help( "", 1, "At720Status" )
		lRet := .F.	
	EndIf
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720DescFor

Realiza o preenchimento da descrição do Fornecedor e do CNPJ do Fornecedor
@author Serviços
@since 20/08/13
@version P11 R9

@Param nPos,Indica qual o campo que será preenchido
@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720DescFor(nPos)
Local cDesc		:= ""
Local oModel
Local aAreaSA2 	:= SA2->(GetArea())

Default nPos := 0

If nPos > 0
	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))
	
	If SA2->(DbSeek(xFilial("SA2") + FwFldGet("TE1_CODFOR") + FwFldGet("TE1_LOJA")))
		If nPos == 1
			oModel := FWModelActive()
			oModel:setValue("TE1MASTER",'TE1_CNPJ',SA2->A2_CGC)
		ElseIf nPos == 2
			cDesc := SA2->A2_NOME
		EndIf	
	EndIf
EndIf

RestArea(aAreaSA2)
					
Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720DescPro

Realiza o preenchimento da descrição do Produto
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720DescPro()
Local cDesc		:= ""
Local aAreaSB1		:= SB1->(GetArea())

cDesc := Posicione("SB1",1,xFilial("SB1") + FwFldGet("TE1_CODPRO"),"SB1->B1_DESC")

RestArea(aAreaSB1)

Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720DscLoc

Realiza o preenchimento da descrição do Local Interno
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Retorna a Descrição do Local Interno
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720DscLoc()
Local cLocal		:= ""
Local aAreaTER	:= TER->(GetArea())

cLocal	:= Posicione("TER",1,xFilial("TER") + FwFldGet("TE1_LOCAL"),"TER->TER_DESCRI")

RestArea(aAreaTER)

Return(cLocal)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720When

Habilita os campos Forncedor e Produto quando a Origem não for MATA103
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720When()
Local lRet 		:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Não deixa alterar o fornecedor e o produto quando o mesmo tiver vinculo com Nota Fiscal
If nOperation == 4 .AND. Alltrim(TE1->TE1_ORIGEM) == "MATA103"
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720WLocal

Desabilita o campo de Local quando ele já está preenchido
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720WLocal()
Local lRet 		:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Não deixa alterar o fornecedor e o produto quando o mesmo tiver vinculo com Nota Fiscal
If nOperation == 4 .AND. !Empty(TE1->TE1_LOCAL)
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Exc

Exclui o registro do Colete, através da exclusão da NFE
Informa ao usuario e pergunta se ele deseja continuar com a Exclusão
@author Serviços
@since 20/08/13
@version P11 R9

@Param cDoc,Numero do Documento de Entrada
@Param cSerie,Numero da Serie do Documento de Entrada

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Exc(cDoc,cSerie,lExc)
Local lRet			:= .F.
Local aAreaTE1		:= TE1->(GetArea())

Default cDoc		:= ""
Default cSerie		:= ""
Default lExc	:= .F.

DbSelectArea("TE1")
DbSetOrder(2)

If TE1->(DbSeek(xFilial("TE1") + cDoc + cSerie))
	If Alltrim(TE1->TE1_ORIGEM) == "MATA103" .AND. Empty(TE1->TE1_ENTIDA)
		If !lExc
			lRet :=MsgYesNo(STR0018) //"Essa Nota está vinculada a um Colete Ativo no Cadastro de Coletes, Deseja Continuar?"
		EndIf
		If lExc
			While !TE1->(Eof()) .And. TE1->TE1_DOC == cDoc .And. TE1->TE1_SERIE == cSerie
				RecLock("TE1",.F.)
					TE1->( dbDelete() )
					TE1->( MsUnlock() )
				TE1->(dbSkip())
			End
		EndIf	
	ElseIf Alltrim(TE1->TE1_ORIGEM) == "MATA103" .AND. !Empty(TE1->TE1_ENTIDA)
		Help( "", 1, "At720Mov" )	
	EndIf
EndIf

RestArea(aAreaTE1)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Mov

Verifica se o Colete está movimentado ou com o Status Frear alterado
@author Serviços
@since 20/08/13
@version P11 R9

@Param cDoc,Numero do Documento de Entrada
@Param cSerie,Numero da Serie do Documento de Entrada

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Mov(cDoc,cSerie)
Local lRet			:= .T.
Local aAreaTE1		:= TE1->(GetArea())

Default cDoc		:= ""
Default cSerie		:= ""

DbSelectArea("TE1")
TE1->(DbSetOrder(2))

If TE1->(DbSeek(xFilial("TE1") + cDoc + cSerie))
	If  Alltrim(TE1->TE1_ORIGEM) == "MATA103" .AND. TE1->TE1_SITUA <> "1"
		lRet := .F.
	EndIf
EndIf

RestArea(aAreaTE1)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Status

Verifica campos Obrigatorios para a troca de Status do Colete
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Status()
Local lRet	:= .T.
Local aAreaSM0  	:= SM0->(GetArea())
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Verifica se os campos estão preenchidos para alterar o Status para Implantado
If nOperation == 4 .Or. nOperation == 3
	If lRet .And. Empty(FwFldGet("TE1_NUMSER"))	
		lRet := .F.
	EndIf	
EndIf

RestArea(aAreaSM0)
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720VldProd

Valida o Tipo de Produto no cadastro, para não permitir a inclusão de produtos que não
são do tipo Colete
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720VldProd()
Local lRet			:= .T.
Local aAreaSB5 	:= SB5->(GetArea())

DbSelectArea('SB5')
SB5->(DbSetOrder(1)) // acordo com o arquivo SIX -> A1_FILIAL+A1_COD+A1_LOJA

If SB5->(DbSeek(xFilial('SB5')+FwFldGet("TE1_CODPRO"))) // Filial: 01, Código: 000001, Loja: 02
			
	If SB5->B5_TPISERV <>'2' 
		Help("  ",1,"AT720Tipo")
		lRet := .F.		
	EndIf
Else
	Help("  ",1,"AT720Tipo")
	lRet := .F.		
EndIf
		
RestArea(aAreaSB5)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Ocorr

Monta a Tela com todas as ocorrencias relacionadas ao Colete
@author Serviços
@since 20/08/13
@version P11 R9

@Param cColete,Codigo do Colete
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Ocorr(cColete)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0019 FROM 050,050 TO 500,800 PIXEL//"Ocorrencias"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0022 ) //"Lista de Ocorrencias"
oBrowse:SetAlias( "TES" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("12")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TES_CODCOL = '" + cColete + "'" ) 
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At720VisOcor()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720VisOcor

Ação do Duplo-click na Ocorrencias, abrindo o cadastro de ocorrencia no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720VisOcor()
Local aArea		:= GetArea()
                 
DbSelectArea("TE4")
TE4->(DbSetOrder(1))
	
If TE4->(DbSeek(xFilial("TE4")+TES->TES_CDOCOR))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA750",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Commit

Commit do cadastro de coletes, onde será gravado a data de alocação no cofre
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At720Commit(oModel)
Local lRet	:= .T.
Local nOperation	:= oModel:GetOperation()

If (nOperation == 3 .Or. nOperation == 4) .And. (!Empty(FwFldGet("TE1_LOCAL")))
	oModel:setValue("TE1MASTER",'TE1_DTALOC',dDataBase)
	oModel:setValue("TE1MASTER",'TE1_ENTIDA',"TER")		
EndIf

FWModelActive( oModel )
FWFormCommit( oModel )	

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Manut

Monta a Tela com todas as ocorrencias relacionadas a Arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cArma,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Manut(cColete)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0020 FROM 050,050 TO 500,800 PIXEL//"Manutenções"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0023 ) //"Lista de Manutenções"
oBrowse:SetAlias( "TEU" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("13")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TEU_TPARMA = '2' .AND. TEU_CDARM = '" + cColete + "' " ) 
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At720VisManut()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720VisManut

Ação do Duplo-click na Ocorrencias, abrindo o cadastro de ocorrencia no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720VisManut()
Local aArea		:= GetArea()
                 
DbSelectArea("TEU")
TEU->(DbSetOrder(1))
	
If TEU->(DbSeek(xFilial("TEU")+TEU->TEU_CODIGO))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA780",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720Movim

Monta a Tela com todas as movimentações relacionadas a arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cColete,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720Movim(cColete)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}

DEFINE MSDIALOG oPanel TITLE STR0021 FROM 050,050 TO 500,800 PIXEL//"Movimentações"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0024 ) 
oBrowse:SetAlias( "TFO" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("14")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TFO_ITMOV = '2' .AND. TFO_ITCOD = '" + cColete + "' " ) 

oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At720VisMovim()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At720VisMovim

Ação do Duplo-click na Movimentação, abrindo o cadastro de movimentaadminções no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At720VisMovim()
Local aArea		:= GetArea()
                 
DbSelectArea("TFQ")
TFQ->(DbSetOrder(1))
	
If TFQ->(DbSeek(xFilial("TFQ")+TFO->TFO_CDMOV))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA880",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TecFilCol

Retorna a consulta especifica para coletes.

@author Rebeca Facchinato Asunção
@since 25/08/2017
@version P12.1.17
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TecFilCol(nOpc)

Local lRet := .F.

	lRet:= TxProdArm(2)

Return lRet