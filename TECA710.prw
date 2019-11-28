#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA710.CH"

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA710

Cadastro de Armas - TE0
@author Serviços
@since 28/08/13
@version P11 R9

@return Nil,Não Retorna Nada
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Function TECA710()

Local oBrowse

Private aRotina	:= MenuDef()
Private cCadastro	:= STR0001 //"Cadastro de Armas"
 
oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TE0')
oBrowse:SetDescription(STR0001) // Cadastro de Armas
oBrowse:Activate()

Return
	
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Definição do MenuDef
@author Serviços
@since 28/08/13
@version P11 R9

@return ExpO:aRotina,aRotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina:= {}
ADD OPTION aRotina TITLE STR0002		ACTION 'PESQBrw' 				OPERATION 1 ACCESS 0	//Pesquisa
ADD OPTION aRotina TITLE STR0003		ACTION 'VIEWDEF.TECA710' 	OPERATION 2 ACCESS 0	//Visualizar
ADD OPTION aRotina TITLE STR0004   	ACTION 'VIEWDEF.TECA710' 	OPERATION 3 ACCESS 0	//Incluir
ADD OPTION aRotina TITLE STR0005   	ACTION 'VIEWDEF.TECA710' 	OPERATION 4 ACCESS 0	//Alterar
ADD OPTION aRotina TITLE STR0006 		ACTION 'VIEWDEF.TECA710' 	OPERATION 5 ACCESS 0 //"Excluir"
ADD OPTION aRotina TITLE STR0007		ACTION 'MSDOCUMENT'			OPERATION 7 ACCESS 0 //"Bco. Conhecimento"

Return aRotina

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Model 
@author Serviços
@since 28/08/13
@version P11 R9

@return ExpO:oModel
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel
Local oStruTE0		:= FWFormStruct(1,'TE0')
Local aAux			:= {}
Local aAux1		:= {}
Local aAux2		:= {}
Local aAux3		:= {}
Local bCommit		:= {|oModel|At710Commit(oModel)}

aAux := FwStruTrigger("TE0_LOJA","TE0_NOME","At710DescFor(1),At710DescFor(2)",.F.,Nil,Nil,Nil)
oStruTE0:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux1 := FwStruTrigger("TE0_CODPRO","TE0_DESPRO","At710DescPro()",.F.,Nil,Nil,Nil)
oStruTE0:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

aAux2 := FwStruTrigger("TE0_CDPAIS","TE0_DCPAIS","At710DscPais()",.F.,Nil,Nil,Nil)
oStruTE0:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

aAux3 := FwStruTrigger("TE0_LOCAL","TE0_CLIDES","At710DscLoc()",.F.,Nil,Nil,Nil)
oStruTE0:AddTrigger(aAux3[1],aAux3[2],aAux3[3],aAux3[4])

oModel := MPFormModel():New('TECA710',/*bPreValidacao*/,{|oModel|AT710VLD(oModel)},bCommit,/*bCancel*/)

oModel:AddFields('TE0MASTER',/*cOwner*/,oStruTE0,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/,/*bFieldAbp*/)

oModel:SetPrimaryKey({"TE0_FILIAL","TE0_CODCOL"})

Return oModel

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View 
@author Serviços
@since 28/08/13
@version P11 R9

@return ExpO:oView
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView
Local oModel   	:= FWLoadModel('TECA710')
Local oStruTE0 	:= FWFormStruct(2,'TE0')

oView:= FWFormView():New()
oView:SetModel(oModel)

oView:AddUserButton(STR0007, 'CLIPS',{|oView|MsDocument('TE0',TE0->(RECNO()),oModel:GetOperation() )}) //"Bco. Conhecimento"

oView:AddUserButton(STR0018, 'CLIPS',{|oView| At710Ocorr(FwFldGet("TE0_COD"))}) //"Ocorrencias"

oView:AddUserButton(STR0019, 'CLIPS',{|oView| At710Manut(FwFldGet("TE0_COD"))}) //"Manutenções"

oView:AddUserButton(STR0020, 'CLIPS',{|oView| At710Movim(FwFldGet("TE0_COD"))}) //"Movimentações"

oStruTE0:RemoveField("TE0_ORIGEM")
oStruTE0:RemoveField("TE0_ENTIDA")
oStruTE0:RemoveField("TE0_AGEND")
oStruTE0:RemoveField("TE0_PRVRET")
oStruTE0:RemoveField("TE0_CODMOV")

oView:AddField('VIEW_CAB',oStruTE0,'TE0MASTER')
oView:CreateHorizontalBox('SUPERIOR',100)
oView:SetOwnerView( 'VIEW_CAB','SUPERIOR' )

return oView

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Imp

Inclusão da Arma quando é adicionado uma nota Fiscal de Entrada
@author Serviços
@since 28/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function aT710Imp()
Local lRet := .T.

Processa( { || lRet := At710Inc() },STR0024,STR0025,.F.)//'Aguarde';'Realizando Inclusão de Armas'

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Inc

Inclusão da Arma quando é adicionado uma nota Fiscal de Entrada
@author Serviços
@since 28/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Inc()
Local oModel
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
	
	oModel:=FwloadModel('TECA710')
	
	For nQuant:= 1 To SD1->D1_QUANT
     
		oModel:SetOperation(3)
		oModel:Activate()
			
		lAux:= oModel:LoadValue('TE0MASTER','TE0_DOC',SD1->D1_DOC)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_SERIE',SD1->D1_SERIE)
		
		//Atualiza campo _SDOC dos documentos fiscais, caso habilitado
		If SerieNFId("TE0", 3, "TE0_SERIE") != "TE0_SERIE"					
			lAux:= oModel:LoadValue('TE0MASTER',SerieNFId("TE0", 3, "TE0_SERIE"), SerieNFId("SD1", 2, "D1_SERIE"))
		EndIf
		
		lAux:= oModel:LoadValue('TE0MASTER','TE0_DTNOTA',SD1->D1_EMISSAO)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_COMPRA',SD1->D1_EMISSAO)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_CODFOR',SD1->D1_FORNECE)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_LOJA',SD1->D1_LOJA)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_CODPRO',SD1->D1_COD)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_ITEM',SD1->D1_ITEM)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_SEQ',cValtoChar(nQuant))
		lAux:= oModel:LoadValue('TE0MASTER','TE0_ATIVO',SD1->D1_CBASEAF)	
		lAux:= oModel:LoadValue('TE0MASTER','TE0_ORIGEM',"MATA103")
		lAux:= oModel:LoadValue('TE0MASTER','TE0_NOME',SA2->A2_NOME)
		lAux:= oModel:LoadValue('TE0MASTER','TE0_CNPJ',SA2->A2_CGC)			
					
		If lRet := oModel:VldData()
			// Se o dados foram validados faz-se a gravação efetiva dos dados (commit)
			oModel:CommitData()
		EndIf
		
		If !lRet
			// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou 
			//mensagem de aviso
			aErro := oModel:GetErrorMessage()
					 
			AutoGrLog( STR0008 + ' [' + AllToChar( aErro[1] ) + ']' ) //"Id do formulário de origem:"
			AutoGrLog( STR0009 + ' [' + AllToChar( aErro[2] ) + ']' ) //"Id do campo de origem: "
			AutoGrLog( STR0010 + ' [' + AllToChar( aErro[3] ) + ']' ) //"Id do formulário de erro: "
			AutoGrLog( STR0011 + ' [' + AllToChar( aErro[4] ) + ']' ) //"Id do campo de erro: "
			AutoGrLog( STR0012 + ' [' + AllToChar( aErro[5] ) + ']' ) //"Id do erro: "
			AutoGrLog( STR0013 + ' [' + AllToChar( aErro[6] ) + ']' ) //"Mensagem do erro: "
			AutoGrLog( STR0014 + ' [' + AllToChar( aErro[7] ) + ']' ) //"Mensagem da solução: "
			AutoGrLog( STR0015 + ' [' + AllToChar( aErro[8] ) + ']' ) //"Valor atribuído: "
			AutoGrLog( STR0016 + ' [' + AllToChar( aErro[9] ) + ']' ) //"Valor anterior: "
			
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
/*/{Protheus.doc} AT710Vld

Validação do Cadastro de Armas
@author Serviços
@since 28/08/13
@version P11 R9

@param oModel, Modelo de dados do cadastro de Armas
@return ExpL,Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AT710Vld(oModel)
Local lRet       := .T.
Local nOperation := oModel:GetOperation()

//Não permite a exclusão quando a Arma já foi movimentada ou foi alocado
If nOperation == 5
	If FwFldGet("TE0_SITUA") <> "1" .Or. !Empty(FwFldGet("TE0_LOCAL"))
		Help( "", 1, "At710Situa" )
		lRet := .F.
	EndIf
EndIf

If (nOperation == 3 .Or. nOperation == 4) .And. (!Empty(FwFldGet("TE0_LOCAL")))
	If !At710Status()
		Help( "", 1, "At710Status" )
		lRet := .F.	
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710DescFor

Realiza o preenchimento da descrição do Fornecedor e do CNPJ do Fornecedor
@author Serviços
@since 20/08/13
@version P11 R9

@Param nPos,Indica qual o campo que será preenchido
@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710DescFor(nPos)
Local cDesc		:= ""
Local oModel
Local aAreaSA2 	:= SA2->(GetArea())

Default nPos := 0

If nPos > 0
	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))
	
	If SA2->(DbSeek(xFilial("SA2") + FwFldGet("TE0_CODFOR") + FwFldGet("TE0_LOJA")))
		If nPos == 1
			oModel := FWModelActive()
			oModel:setValue("TE0MASTER",'TE0_CNPJ',SA2->A2_CGC)
		ElseIf nPos == 2
			cDesc := SA2->A2_NOME
		EndIf	
	EndIf
EndIf

RestArea(aAreaSA2)
					
Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710DescPro

Realiza o preenchimento da descrição do Produto
@author Serviços
@since 28/08/13
@version P11 R9


@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710DescPro()
Local cDesc		:= ""
Local aAreaSB1		:= SB1->(GetArea())

cDesc := Posicione("SB1",1,xFilial("SB1") + FwFldGet("TE0_CODPRO"),"SB1->B1_DESC")

RestArea(aAreaSB1)

Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710DscPais

Realiza o preenchimento da descrição do Pais de Origem da Arma
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna a descrição do Pais de Origem da Arma
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710DscPais()
Local cDesc		:= ""
Local aAreaCCH	:= CCH->(GetArea())

cDesc := Posicione("CCH",1,xFilial("CCH") + FwFldGet("TE0_CDPAIS"),"CCH->CCH_PAIS")

RestArea(aAreaCCH)

Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710DscLoc

Realiza o preenchimento da descrição do Local Interno
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Retorna a Descrição do Local Interno
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710DscLoc()
Local cLocal		:= ""
Local aAreaTER	:= TER->(GetArea())

cLocal	:= Posicione("TER",1,xFilial("TER") + FwFldGet("TE0_LOCAL"),"TER->TER_DESCRI")

RestArea(aAreaTER)

Return(cLocal)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710When

Habilita os campos Forncedor e Produto quando a Origem não for MATA103
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710When()
Local lRet 		:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Não deixa alterar o fornecedor e o produto quando o mesmo tiver vinculo com Nota Fiscal
If nOperation == 4 .AND. Alltrim(TE0->TE0_ORIGEM) == "MATA103"
	lRet := .F.
EndIf

Return(lRet)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710WLocal

Desabilita o campo de Local quando ele já está preenchido
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710WLocal()
Local lRet 		:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Não deixa alterar o fornecedor e o produto quando o mesmo tiver vinculo com Nota Fiscal
If nOperation == 4 .AND. !Empty(TE0->TE0_LOCAL)
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Exc

Exclui o registro da Arma, através da exclusão da NFE
Informa ao usuario e pergunta se ele deseja continuar com a Exclusão
@author Serviços
@since 20/08/13
@version P11 R9

@Param cDoc,Numero do Documento de Entrada
@Param cSerie,Numero da Serie do Documento de Entrada
@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Exc(cDoc,cSerie,lExc)
Local lRet			:= .F.
Local aAreaTE0	:= TE0->(GetArea())

Default cDoc		:= ""
Default cSerie	:= ""
Default lExc		:= .F.

DbSelectArea("TE0")
TE0->(DbSetOrder(2))

If AliasInDic("TE0") .And. TE0->(DbSeek(xFilial("TE0") + cDoc + cSerie))
	If Alltrim(TE0->TE0_ORIGEM) == "MATA103" .AND. Empty(TE0->TE0_ENTIDA)
		If !lExc
			lRet :=MsgYesNo(STR0017) //"Essa Nota possui um cadastro de Arma Ativo, Deseja Continuar?"
		EndIf
		If lExc
			While !TE0->(Eof()) .And. TE0->TE0_DOC == cDoc .And. TE0->TE0_SERIE == cSerie
				RecLock("TE0",.F.)
					TE0->( dbDelete() )
					TE0->( MsUnlock() )
			TE0->(dbSkip())
			End
		EndIf	
	ElseIf Alltrim(TE0->TE0_ORIGEM) == "MATA103" .AND. !Empty(TE0->TE0_ENTIDA)
		Help( "", 1, "At710Mov" )
	EndIf
EndIf

RestArea(aAreaTE0)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Mov

Verifica se a Arma está movimentada ou com o Status Frear alterado
@author Serviços
@since 20/08/13
@version P11 R9

@Param cDoc,Numero do Documento de Entrada
@Param cSerie,Numero da Serie do Documento de Entrada
@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Mov(cDoc,cSerie)
Local lRet			:= .T.
Local aAreaTE0	:= TE0->(GetArea())
Default cDoc		:= ""
Default cSerie	:= ""

DbSelectArea("TE0")
DbSetOrder(2)

If AliasInDic("TE0") .And. TE0->(DbSeek(xFilial("TE0") + cDoc + cSerie))
	If  Alltrim(TE0->TE0_ORIGEM) == "MATA103" .AND. TE0->TE0_SITUA <> "1"
		lRet := .F.
	EndIf
EndIf

RestArea(aAreaTE0)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Status

Verifica campos Obrigatorios para a troca de Status da Arma
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Status()
Local lRet			:= .T.
Local oModel		:= FWModelActive() 
Local nOperation	:= oModel:GetOperation()

//Verifica se os campos estão preenchidos para alterar o Status para Implantado
If nOperation == 4 .Or. nOperation == 3
	If (Empty(FwfldGet("TE0_ESPEC")) .OR. Empty(FwFldGet("TE0_MARCA")) .OR. Empty(FwFldGet("TE0_CALIBR")).OR. ;
	   Empty(FwfldGet("TE0_MODELO")) .OR. Empty(FwFldGet("TE0_CORON")) .OR. Empty(FwFldGet("TE0_ACABA")).OR. ;
	   Empty(FwfldGet("TE0_CAPMUN")) .OR. Empty(FwFldGet("TE0_VALIDA")) .OR. Empty(FwFldGet("TE0_NUMREG")).OR. ;
	   Empty(FwfldGet("TE0_DTREG")) .OR. Empty(FwFldGet("TE0_ORGAO")) .OR. Empty(FwFldGet("TE0_SINARM")).OR. ;
	   Empty(FwfldGet("TE0_CDPAIS")) .OR. Empty(FwFldGet("TE0_DELEG")))
			
		lRet := .F.
	EndIf	
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710VldProd

Valida o Tipo de Produto no cadastro, para não permitir a inclusão de produtos que não
são do tipo Arma
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710VldProd()
Local lRet		:= .T.
Local aAreaSB5:= SB5->(GetArea())

DbSelectArea('SB5')
SB5->(DbSetOrder(1)) // acordo com o arquivo SIX -> A1_FILIAL+A1_COD+A1_LOJA

If  SB5->(FieldPos("B5_TPISERV")) > 0	
	If SB5->(DbSeek(xFilial('SB5')+FwFldGet("TE0_CODPRO")))
				
		If SB5->B5_TPISERV<>'1' 
			Help("  ",1,"AT710Tipo")
			lRet := .F.		
		EndIf
	Else
		Help("  ",1,"AT710Tipo")
		lRet := .F.	
	EndIf
EndIf		

RestArea(aAreaSB5)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Ocorr

Monta a Tela com todas as ocorrencias relacionadas a Arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cArma,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Ocorr(cArma)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina := {}


DEFINE MSDIALOG oPanel TITLE STR0018 FROM 050,050 TO 500,800 PIXEL//"Ocorrencias"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0021 ) //"Lista de Ocorrencias"
oBrowse:SetAlias( "TE6" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("12")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TE6_ARMA = '" + cArma + "'" ) 
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At710VisOcor()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710VisOcor

Ação do Duplo-click na Ocorrencias, abrindo o cadastro de ocorrencia no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710VisOcor()
Local aArea		:= GetArea()
                 
DbSelectArea("TE4")
TE4->(DbSetOrder(1))
	
If TE4->(DbSeek(xFilial("TE4")+TE6->TE6_CDOCOR))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA750",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Commit

Commit do cadastro de armas, onde será gravado a data de alocação no cofre
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At710Commit(oModel)
Local lRet	:= .T.
Local nOperation	:= oModel:GetOperation()

// só atualiza a referência de alocação enquanto a arma ainda não estiver recebido alocação em cofre
If (nOperation == 3 .Or. nOperation == 4) .And. ( !Empty(oModel:GetValue("TE0MASTER","TE0_LOCAL")) ) .And. ( Empty(oModel:GetValue("TE0MASTER","TE0_DTALOC")) )
	lRet := lRet .And. oModel:setValue("TE0MASTER",'TE0_DTALOC',dDataBase)
	lRet := lRet .And. oModel:setValue("TE0MASTER",'TE0_ENTIDA',"TER")	
EndIf

lRet := lRet .And. FWFormCommit( oModel )	

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Manut

Monta a Tela com todas as ocorrencias relacionadas a Arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cArma,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Manut(cArma)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina	:= {}

DEFINE MSDIALOG oPanel TITLE STR0019 FROM 050,050 TO 500,800 PIXEL//"Manutenções"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0022 ) //"Lista de Manutenções"
oBrowse:SetAlias( "TEU" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("13")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TEU_TPARMA = '1' .AND. TEU_CDARM = '" + cArma + "' " ) 
oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At710VisManut()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710VisManut

Ação do Duplo-click na Ocorrencias, abrindo o cadastro de ocorrencia no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710VisManut()
Local aArea		:= GetArea()
                 
DbSelectArea("TEU")
TEU->(DbSetOrder(1))
	
If TEU->(DbSeek(xFilial("TEU")+TEU->TEU_CODIGO))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA780",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Movim

Monta a Tela com todas as movimentações relacionadas a arma
@author Serviços
@since 20/08/13
@version P11 R9

@Param cArma,Codigo da Arma 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Movim(cArma)
Local oPanel		:= Nil
Local oBrowse		:= Nil
Local aBckp		:= aClone(aRotina)

aRotina	:= {}

DEFINE MSDIALOG oPanel TITLE STR0020 FROM 050,050 TO 500,800 PIXEL//"Movimentações"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0023 ) //"Lista de Movimentações" 
oBrowse:SetAlias( "TFO" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("14")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "TFO_ITMOV = '1' .AND. TFO_ITCOD = '" + cArma + "' " ) 

oBrowse:Activate() 

//bloco de codigo para duplo click - deve ficar após o activate, senao o FWMBrowse ira sobreescrever com o bloco padrao
oBrowse:BlDblClick := {||At710VisMovim()} 
oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED

aRotina := aBckp
aBckp := {}

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710VisMovim

Ação do Duplo-click na Movimentação, abrindo o cadastro de movimentaadminções no modo 
Visualização
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710VisMovim()
Local aArea		:= GetArea()
                 
DbSelectArea("TFQ")
TFQ->(DbSetOrder(1))
	
If TFQ->(DbSeek(xFilial("TFQ")+TFO->TFO_CDMOV))
	FWExecView(Upper(STR0003),"VIEWDEF.TECA880",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)	
EndIf

RestArea(aArea)

Return (.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At710Ativo

Verifica a situação da arma para realizar a baixa do ativo
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At710Ativo(cProduto,cDoc,cSerie,cItem)
Local lRet 	:= .T.
Local aArea	:= GetArea()

Default cProduto	:= ""
Default cDoc	 	:= ""
Default cSerie 	:= ""
Default cItem	 	:= ""	

//Verifica se o produto é do tipo arma
DbSelectArea("SB5")
SB5->(DbSetOrder(1)) // acordo com o arquivo SIX -> A1_FILIAL+A1_COD+A1_LOJA

If  SB5->(FieldPos("B5_TPISERV")) > 0	
	If SB5->(DbSeek(xFilial("SB5")+cProduto))
				
		If SB5->B5_TPISERV=='1' 

			DbSelectArea("TE0")
			TE0->(DbSetOrder(2))
				
			//Verifica se a situação da arma está como Descartada	
			If TE0->(DbSeek(xFilial("TE0") + cDoc + cSerie + cItem))
				If TE0->TE0_SITUA <> "A"
					lRet := .F.
					Help("  ",1,"AT710ATIVO")
				EndIf		
			EndIf
			
		EndIf
	
	EndIf
	
EndIf		
	
RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TecFilArma

Retorna a consulta especifica para armas.

@author Rebeca Facchinato Asunção
@since 25/08/2017
@version P12.1.17
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TecFilArm(nOpc)

Local lRet := .F.

	lRet:= TxProdArm(1)

Return lRet