#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA780.CH"

Static cDesc		:= ""
Static cTab		:= ""
Static cCampo		:= ""
Static aCmpBco	:= {}

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA780

Cadastro de Manutenção de Armamentos - TEU
@author Serviços
@since 28/08/13
@version P11 R9

@return Nil,Não Retorna Nada
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Function TECA780(uAutoItens,nOpcAuto)
Local nX			:= 0
Local oBrowse
Local aCores 		:= {	{ 'TEU->TEU_STATUS=="1"' , 'BR_VERDE', STR0002 },; 	//"Aguardando Interação"
							{ 'TEU->TEU_STATUS=="2"' , 'BR_AMARELO', STR0003},;	//"Manutenção Iniciada"
							{ 'TEU->TEU_STATUS=="3"' , 'BR_VERMELHO', STR0004}}	//"Manutenção Finalizada"

Default uAutoItens	:= {}
Default nOpcAuto		:= MODEL_OPERATION_VIEW

Private aRotina	:= MenuDef()					
Private cCadastro	:= STR0001 //"Cadastro de Manutenção"

If uAutoItens <> Nil .AND. !Empty(uAutoItens)
	FWMVCRotAuto(ModelDef(),"TEU",nOpcAuto,{{"TEUMASTER",uAutoItens}},,.T.)
Else 
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('TEU')
	
	// Adiciona as legendas.
	For nX := 1 To Len(aCores)
		oBrowse:AddLegend(aCores[nX][1],aCores[nX][2],aCores[nX][3]) 
	Next nX   
	
	oBrowse:SetDescription(STR0001) // "Cadastro de Manutenção"
	oBrowse:Activate()
EndIf

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
Local aRotina:= FWMVCMenu( "TECA780" )

aAdd( aRotina, { STR0005, 'MSDOCUMENT', 0, 7, 0, NIL } ) //"Bco. Conhecimento"


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
Local oStruTEU		:= FWFormStruct(1,'TEU')
Local aAux				:= {}
Local aAux1			:= {}
Local aAux2			:= {}
Local bPosValidacao	:= {|oModel|At780PosVld(oModel)}
Local bCommit			:= {|oModel|At780Grava(oModel)}
Local bActivate		:= {|oModel|At780PreValid(oModel)}

aAux := FwStruTrigger("TEU_CDARM","TEU_DSCARM","At780DescPro()",.F.,Nil,Nil,Nil)
oStruTEU:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux1 := FwStruTrigger("TEU_CDRESP","TEU_RESPON","At780DescRes()",.F.,Nil,Nil,Nil)
oStruTEU:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

aAux2 := FwStruTrigger("TEU_CODLOC","TEU_DSCLOC","At780DescLoc()",.F.,Nil,Nil,Nil)
oStruTEU:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

oModel := MPFormModel():New('TECA780',/*bPreValidacao*/,bPosValidacao,bCommit,/*bCancel*/)

oModel:AddFields('TEUMASTER',/*cOwner*/,oStruTEU,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/,/*bFieldAbp*/)

oModel:SetPrimaryKey({"TEU_FILIAL","TEU_CODIGO"})

//Valida o Model para Ativa-lo
oModel:SetVldActivate(bActivate)

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
Local oModel   	:= FWLoadModel('TECA780')
Local oStruTEU 	:= FWFormStruct(2,'TEU')

oView:= FWFormView():New()
oView:SetModel(oModel)

oView:AddUserButton(STR0005, 'CLIPS',{|oView|MsDocument('TEU',TEU->(RECNO()),oModel:GetOperation() )}) //"Bco. Conhecimento"

oStruTEU:RemoveField("TEU_ORIGEM")
oStruTEU:RemoveField("TEU_ENTIDA")
oStruTEU:RemoveField("TEU_ULTSTA")

oView:AddField('VIEW_CAB',oStruTEU,'TEUMASTER')
oView:CreateHorizontalBox('SUPERIOR',100)
oView:SetOwnerView( 'VIEW_CAB','SUPERIOR' )

oView:SetCloseOnOk({|| .T.} )

Return oView

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780PosVld

Pos-Validação do cadastro de Manutenção
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780PosVld(oModel)
Local lRet			:= .T.
Local nOperation	:= oModel:GetOperation()
Local aAreaTE0	:= {}
Local aAreaTE1	:= {}
Local aAreaTE2	:= {}	
		
If nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_INSERT
	Do Case
		Case FwFldGet("TEU_TPARMA") == "1"
			
			aAreaTE0	:= TE0->(GetArea())
			DbSelectArea("TE0")
			TE0->(DbSetOrder(1))
			If TE0->(DbSeek(xFilial("TE0") + FwFldGet("TEU_CDARM")))
				//Verificar se o item foi alocado
				If Empty(TE0->TE0_LOCAL)
					Help( ,, "At780PosVld",, STR0007, 1, 0 )//"Alocação","O Armamento selecionado não foi alocado"
					lRet := .F.
				EndIf
				//Verifica o Status e verifica se o Status é impeditivo
				//1=Ativa;2=Implantada;3=Em Manutencao;4=Furtada;5=Roubada;6=Extraviada;7=Apreendida;8=Recuperada;9=Desativada;10=Descartada
				// Os Status entre o 4 e o 10 são impeditivos exceto o Status 8
				If TE0->TE0_SITUA >= "4" 
					If TE0->TE0_SITUA <> "8"
						Help( ,, "At780PosVld",, STR0009, 1, 0 ) //Status,
						lRet	:= .F.
					EndIf	
				ElseIf TE0->TE0_SITUA == "3" .And. nOperation == MODEL_OPERATION_INSERT
					Help( ,, "At780PosVld",, STR0009, 1, 0 ) //Alocação,"A Arma selecionada já está em Manutenção"
					lRet	:= .F.
				EndIf
			EndIf 	
			RestArea(aAreaTE0)
			
		Case FwFldGet("TEU_TPARMA") == "2"
			
			aAreaTE1	:= TE1->(GetArea())
			DbSelectArea("TE1")
			TE1->(DbSetOrder(1))
			If TE1->(DbSeek(xFilial("TE1") + FwFldGet("TEU_CDARM")))
				//Verificar se o item foi alocado
				If Empty(TE1->TE1_LOCAL)
					Help( ,, "At780PosVld",, STR0007, 1, 0 )//"Alocação","O Armamento selecionado não foi alocado"
					lRet := .F.
				EndIf
				//Verifica o Status e verifica se o Status é impeditivo
				//1=Ativa;2=Implantada;3=Em Manutencao;4=Furtada;5=Roubada;6=Extraviada;7=Apreendida;8=Recuperada;9=Desativada;10=Descartada
				// Os Status entre o 4 e o 10 são impeditivos exceto o Status 8
				If TE1->TE1_SITUA >= "4" 
					If TE1->TE1_SITUA <> "8"
						Help( ,, "At780PosVld",, STR0009, 1, 0 ) //Status,"A Arma selecionada possui um status impeditivo, não será possivel realizar a inclusão"
						lRet	:= .F.
					EndIf	
				ElseIf TE1->TE1_SITUA == "3" .And. nOperation == MODEL_OPERATION_INSERT
					Help( ,, "At780PosVld",, STR0009, 1, 0 ) //Alocação,"A Arma selecionada já está em Manutenção"
					lRet	:= .F.
				EndIf
			EndIf 	
			RestArea(aAreaTE1)
			
		Case FwFldGet("TEU_TPARMA") == "3"
			
			If FwFldGet("TEU_QTDMUN") == 0
				Help( ,, "At780PosVld",, STR0011, 1, 0 ) //"Quantidade","É Necessario informar a quantidade de munições para a manutenção"
				lRet := .F.
			ElseIf Empty(FWFldGet("TEU_CODLOC"))
				Help( ,, "At780PosVld",, STR0012, 1, 0 ) //Alocação,"É Necessario informar o local de Alocação da munição para a manutenção"
				lRet := .F.
			Else
				aAreaTE2	:= TE2->(GetArea())
				DbSelectArea("TE2")
				TE2->(DbSetOrder(1))
				If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TEU_CDARM")))
					//Verificar se o item foi alocado
					If Empty(TE2->TE2_LOCAL)
						Help( ,, "At780PosVld",, STR0007, 1, 0 )//"Alocação","O Armamento selecionado não foi alocado"
						lRet := .F.
					EndIf
				EndIf
				//Verifica a quantidade, ela tem que ser menor que o saldo
				If lRet .And. FwFldGet("TEU_STATUS") == "2"
					lRet := At780VerSaldo()
				EndIf 	
				RestArea(aAreaTE2)		
			EndIf
			
	EndCase
	
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780Grava

Commit do cadastro de Manutenção
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780Grava(oModel)
Local nOperation 	:= oModel:GetOperation()
Local lRet			:= .T.

If nOperation == MODEL_OPERATION_INSERT .Or. nOperation == MODEL_OPERATION_UPDATE
	Do Case
		Case FwFldGet("TEU_STATUS") == "2"
				//Muda o Status da Arma para Em Manutenção
				At780SitArma(.T.,Nil)	
		Case FwFldGet("TEU_STATUS") == "3" .Or. FwFldGet("TEU_STATUS") == "1"
				If !IsInCallStack("TECA880")
					//Volta o Status da Arma
					At780SitArma(Nil,.T.)
				EndIf	
	EndCase
EndIf

FWModelActive( oModel )
FWFormCommit( oModel )

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780PreValid

Pre-Validação do Cadastro de Manutenção, não permite alteração com a manutenção finalizada
@author Serviços
@since 28/08/13
@version P11 R9

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780PreValid(oModel)
Local nOperation 	:= oModel:GetOperation()
Local lRet			:= .T.

If nOperation == MODEL_OPERATION_UPDATE .And. TEU->TEU_STATUS == "3"
	Help( ,, "At780PreValid",, STR0014, 1, 0 )//"Manutenção,'Não é permitido alterar a manutenção finalizada.'
	lRet := .F.
EndIf

If lRet .And. (nOperation == MODEL_OPERATION_DELETE .And. TEU->TEU_STATUS <> "1")
	Help( ,, "At780PreValid",, STR0015, 1, 0 ) //Manutenção,'Não é permitido excluir uma manutenção Iniciada ou Finalizada.'
	lRet := .F.
EndIf

If lRet .And. (nOperation == MODEL_OPERATION_DELETE .And. Alltrim(TEU->TEU_ORIGEM) == "TECA880")
	Help( ,, "At780PreValid",, "Não é possivel excluir uma manutenção originada da movimentação", 1, 0 ) //Manutenção,'Não é permitido excluir uma manutenção Iniciada ou Finalizada.'
	lRet := .F.
EndIf

Return(lRet)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FA780F3

Chama a Consulta Padrão conforme o que foi selecionado no campo TpArma
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function FA780F3()

Local oModel		:= FwModelActive()
Local oModelTEU 	:= oModel:GetModel('TEUMASTER')

Local lRet			:= .T.
Local aArea		:= GetArea()
Local cTpArma		:= oModelTEU:GetValue("TEU_TPARMA") 

SaveInter()

Do Case
	Case cTpArma == "1"
		lRet := Conpad1( NIL,NIL,NIL,"TE0")
		
	Case cTpArma == "2"
		lRet := ConPad1(Nil,Nil,Nil,"TE1")
		
	Case cTpArma == "3"
		lRet := ConPad1(Nil,Nil,Nil,"TE2")
									
EndCase

RestInter()

RestArea(aArea)

Return (lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780DescPro

Realiza o preenchimento da descrição do Produto
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780DescPro()
Local cDesc		:= ""
Local cArma		:= ""
Local aArea		:= GetArea()

Do Case
 	Case FwFldGet("TEU_TPARMA") == "1"
		
		cArma := Posicione("TE0",1,xFilial("TE0") + FwFldGet("TEU_CDARM"),"TE0->TE0_CODPRO")	
	 	cDesc := Posicione("SB1",1,xFilial("SB1") + cArma ,"SB1->B1_DESC")
	 	
	 Case FwFldGet("TEU_TPARMA") == "2"
		
		cArma := Posicione("TE1",1,xFilial("TE1") + FwFldGet("TEU_CDARM"),"TE1->TE1_CODPRO")
	 	cDesc := Posicione("SB1",1,xFilial("SB1") + cArma ,"SB1->B1_DESC")
	 	
	Case FwFldGet("TEU_TPARMA") == "3"		
		cArma := Posicione("TE2",1,xFilial("TE2") + FwFldGet("TEU_CDARM"),"TE2->TE2_CODPRO")
	 	cDesc := Posicione("SB1",1,xFilial("SB1") + cArma ,"SB1->B1_DESC")
EndCase

RestArea(aArea)

Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780DescRes

Realiza o preenchimento da descrição do Responsavél
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780DescRes(cResp)
Local cDescResp := ""

Default cResp := ""

If Empty(cResp)
	If Empty(aCmpBco)
		aCmpBco := At780Query()
		nY := aScan(aCmpBco,{|x| AllTrim(x[1]) == Alltrim(FwFldGet("TEU_CDRESP"))})
		cDesc := aCmpBco[nY][2]
	ElseIf Empty(cDesc)
		nY := aScan(aCmpBco,{|x| AllTrim(x[1]) == Alltrim(FwFldGet("TEU_CDRESP"))})
		cDesc := aCmpBco[nY][2]
	EndIf
Else
	If Empty(aCmpBco)
		aCmpBco := At780Query()
		nY := aScan(aCmpBco,{|x| AllTrim(x[1]) == Alltrim(cResp)})
		cDesc := aCmpBco[nY][2]
	ElseIf Empty(cDesc)
		nY := aScan(aCmpBco,{|x| AllTrim(x[1]) == Alltrim(cResp)})
		cDesc := aCmpBco[nY][2]
	EndIf
EndIf

cDescResp := cDesc

Return(cDescResp)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780DescLoc

Realiza o preenchimento da descrição do Local
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780DescLoc()
Local cDescLoc 	:= ""
Local aArea		:= GetArea()

If FwFldGet("TEU_ENTORI") == "1"

	cDescLoc	:= Posicione("TER",1,xFilial("TER") + FwFldGet("TEU_CODLOC"),"TER->TER_DESCRI")

ElseIf FwFldGet("TEU_ENTORI") == "2" 

	cDescLoc	:= Posicione("ABS",1,xFilial("ABS") + FwFldGet("TEU_CODLOC"),"ABS->ABS_DESCRI")

EndIf

RestArea(aArea)


Return(cDescLoc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780ConsPad

Realiza a Consulta especifica para os responsavéis
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780ConsPad()
Local lRet			:= .T.
Local cQuery		:= ""
Local cDscCmp		:= ""
Local cConteudo	:= ""
Local lOk			:= .F.
Local aArea		:= GetArea()

Local aSeek		:= {}
Local aIndex		:= {}
Local cABSQry		:= ""
Local cTit			:= "Responsável Manutenção"
Local cFuncao		:= "At780GvRes"
Local aHeader		:= {}

Local oBrowse		:= Nil	
Local oModel				//Modelo atual
Local oDlgCmp				//Dialog
Local oPanel 				//Objeto Panel
Local oFooter				//Rodapé
Local oListBox			//Grid campos
Local oOk					//Objeto Confirma 
Local oCancel				//Objeto Cancel
Local nOperation			//Modo de Edição: MODEL_OPERATION_INSERT ; MODEL_OPERATION_UPDATE ; MODEL_OPERATION_DELETE

lRet := At780TmpTbl()

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT780RetCons

Retorna a variavel da memoria do model, para a consulta especifica
@sample 	AT840RetCons() 
@since		11/09/2013
@version P11 R9
     
@return 	FwFldGet("TEU_CDRESP"), CHARACTER, conteudo da variavel de memoria.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780RetCons()

Return (cCampo)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780RetArma

Retorna a variavel da memoria do model, para a consulta especifica
@sample 	At780RetArma() 
@since		11/09/2013
@version P11 R9
     
@return 	cCodigo, CHARACTER, codigo do Armamento.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780RetArma()
Local cCodigo	:= ""		

Do Case
	Case FwFldGet("TEU_TPARMA") == "1
	
		cCodigo := TE0->TE0_COD

	Case FwFldGet("TEU_TPARMA") == "2"
	
		cCodigo := TE1->TE1_CODCOL
		
	Case FwFldGet("TEU_TPARMA") == "3"
	
		cCodigo := TE2->TE2_CODMUN
		
EndCase

Return(cCodigo)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780VldCons

Validação do campo de codigo das Armas conforme o que foi selecionado no campo TEU_TPARMA
@sample 	At780VldCons() 
@since		11/09/2013 
@version P11 R9
     
@return 	lRet, Retorno do ExistCPO de acordo com o que foi selecionado no campo TEU_TPARMA
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780VldCons()
Local lRet	:= .F.

Do Case
	Case FwFldGet("TEU_TPARMA") == "1
	
		lRet := ExistCpo("TE0")

	Case FwFldGet("TEU_TPARMA") == "2"
	
		lRet := ExistCpo("TE1")
		
	Case FwFldGet("TEU_TPARMA") == "3"
	
		lRet := ExistCpo("TE2")
	
EndCase

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780Query

Realiza a Query para a consulta especifica do Resposanvel
@sample 	At780Query() 
@since		11/09/2013 
@version P11 R9
     
@return 	aRet, Array com os Responsaveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780Query()
Local aRet		:= {}
Local cAlias	:= GetNextAlias()
Local cCond	:= "1"

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

BeginSQL alias cAlias		
	SELECT AA1.AA1_CODTEC,
			AA1.AA1_NOMTEC 
	FROM
		%Table:AA1% AA1
	WHERE
		AA1.AA1_FILIAL = %xfilial:AA1%
		AND
		AA1.AA1_RSPMNT = %Exp:cCond%
		AND
		AA1.%NotDel%
	Union
	SELECT SA2.A2_COD,
			SA2.A2_NOME 
	FROM
		%Table:SA2% SA2
	WHERE
		SA2.A2_FILIAL = %xfilial:SA2%
		AND
		SA2.%NotDel%	   	
EndSQL	

While (cAlias)->(!Eof())

	AAdd( aRet, { 	(cAlias)->AA1_CODTEC,;
						(cAlias)->AA1_NOMTEC } )
	
	(cAlias)->(DbSkip())
	
EndDo


(cAlias)->(DbCloseArea())

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780QryLoc

Realiza a Query para a consulta especifica do Local de Alocação da Munição
@sample 	At780Query() 
@since		11/09/2013 
@version P11 R9
     
@return 	aRet, Array com os Responsaveis
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780QryLoc()
Local aRet		:= {}
Local cAlias	:= GetNextAlias()
Local cCond	:= FwFldGet("TEU_CDARM")
Local cEntida	:= FwFldGet("TEU_ENTORI") 	//2=Local Interno, 1=Local de Atendimento
Local cMovim	:= ""
	
If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

If !Empty(cEntida)
	
	If cEntida == "1"
		cMovim := "1"
	ElseIf cEntida == "2"
		cMovim := "2"
	EndIf

	BeginSQL alias cAlias		
		SELECT TFP.*
		FROM
			%Table:TFP% TFP
		WHERE
			TFP.TFP_FILIAL = %xfilial:TFP%
			AND
			TFP_ENTIDA = %Exp:cEntida% 
			AND
			TFP_MOVIM = %Exp:cMovim% 
			AND
			TFP_SALDO > 0
			AND
			TFP_CODMUN = %Exp:cCond%
			AND 
			TFP.%NotDel%	
	EndSQL	
	
	While (cAlias)->(!Eof())
	
		AAdd( aRet, { 	(cAlias)->TFP_CODIGO,;
							(cAlias)->TFP_ENTIDA,;
							(cAlias)->TFP_CODINT,;
							(cAlias)->TFP_CODLOC,;
							(cAlias)->TFP_MOVIM,;
							(cAlias)->TFP_SALDO,;
							(cAlias)->TFP_LOTE } )
		
		(cAlias)->(DbSkip())
		
	EndDo
	
	(cAlias)->(DbCloseArea())
EndIf
	
Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780VldHrDt

Função para validar as data e horas de inicio e fim da manutenção
@sample 	At780VldHrDt() 
@since		11/09/2013 
@version P11 R9

@Param	cCpVld,campo para informar o campo que será validado
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780VldHrDt(cCpVld)
Local lRet	:= .T.

Default cCpVld	:= "" //Define o campo que será validadp	

Do Case

	Case cCpVld == "DTINI"
		lRet := (DToS(FwFldGet("TEU_DTINI")) >= DToS(FwFldGet("TEU_DTABER"))) .And. ;
					AtVldDiaHr(FwFldGet("TEU_DTINI"),FwFldGet("TEU_DTFIM"),;
								FwFldGet("TEU_HRINI"),FwFldGet("TEU_HRFIM"))				                                                                 					
	Case cCpVld == "HRINI"
		lRet:= AtVldHora(FwFldGet("TEU_HRINI")) .And. AtVldDiaHr(FwFldGet("TEU_DTINI"),FwFldGet("TEU_DTFIM"),;
					FwFldGet("TEU_HRINI"),FwFldGet("TEU_HRFIM"))                                 
	Case cCpVld == "DTFIM"
		lRet:= (DToS(FwFldGet("TEU_DTFIM")) >= DToS(FwFldGet("TEU_DTINI"))) .And. ;
				AtVldDiaHr(FwFldGet("TEU_DTINI"),FwFldGet("TEU_DTFIM"),;
							FwFldGet("TEU_HRINI"),FwFldGet("TEU_HRFIM"))                                                            
	Case cCpVld == "HRFIM"
		lRet:= AtVldHora(FwFldGet("TEU_HRFIM")) .And. AtVldDiaHr(FwFldGet("TEU_DTINI"),FwFldGet("TEU_DTFIM"),;
					FwFldGet("TEU_HRINI"),FwFldGet("TEU_HRFIM"))  			                                 
EndCase

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780VldStatus

Função para validar os status
@sample 	At780VldStatus() 
@since		11/09/2013 
@version P11 R9
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780VldStatus()
Local lRet	:= .T.

Do Case
	Case FwFldGet("TEU_STATUS") == "2"
		If Empty(FwFldGet("TEU_DTINI")) .And. Empty(FwFldGet("TEU_HRINI"))
			Help( ,, "At780VldStatus",, STR0021, 1, 0 ) //Status, 'Para mudar o Status para Iniciado o campo de Data e Hora de Inicio devem ser preenchidos'
			lRet := .F.
		EndIf
	Case FwFldGet("TEU_STATUS") == "3"
		If (Empty(FwFldGet("TEU_DTINI")) .And. Empty(FwFldGet("TEU_HRINI"))) .Or. ;
			 (Empty(FwFldGet("TEU_DTFIM")) .And. Empty(FwFldGet("TEU_HRFIM"))) .Or. ;
			 Empty(FwFldGet("TEU_LAUDO"))
			Help( ,, "At780VldStatus",, STR0022, 1, 0 ) //Status,'Para mudar o Status para Finalizado o campo de Data e Hora de Inicio e Fim e o Laudo devem ser preenchidos'
			lRet := .F.
		EndIf
EndCase

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780SitArma

Função para alterar o Status das Armas
@sample 	At780SitArma() 
@since		11/09/2013 
@version P11 R9

@Param lIniciada,lFinalizado,Indica se o Status voltará ao antigo ou par Em Manutenção
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780SitArma(lIniciado,lFinalizado)
Local aAreaTE0	:= {}
Local aAreaTE1	:= {}
Local oMdl			:= Nil
Local lAtuSaldo	:= .F.

Default lIniciado		:= .F.
Default lFinalizado	:= .F.

Do Case	
	Case FwFldGet("TEU_TPARMA") == "1"
	
		aAreaTE0 := TE0->(GetArea())
	
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
							
		If TE0->(DbSeek(xFilial("TE0")+FwFldGet("TEU_CDARM")))									
			If lIniciado
				//Antes de Alterar, armazena o Ultimo Status
				oMdl := FWModelActive()
				oMdl:setValue("TEUMASTER",'TEU_ULTSTA',TE0->TE0_SITUA)	
				
				RecLock("TE0",.F.)
				REPLACE TE0_SITUA WITH "3"
				MsUnLock()	
				
				//Grava o registro de Alteração do FREAR
				At780Hist(FwFldGet("TEU_CDARM"),Nil,.T.,.F.,"3")
			ElseIf lFinalizado	
				If !Empty(TEU->TEU_ULTSTA)
					//Retorna ao Status Anterior
					RecLock("TE0",.F.)
					REPLACE TE0_SITUA WITH TEU->TEU_ULTSTA
					MsUnLock()	
					
					//Grava o registro de Alteração do FREAR
					At780Hist(FwFldGet("TEU_CDARM"),Nil,.T.,.F.,TEU->TEU_ULTSTA)
				ElseIf FwFldGet("TEU_STATUS") <> "1"
					//Grava o registro de Alteração do FREAR
					At780Hist(FwFldGet("TEU_CDARM"),Nil,.T.,.F.,"3")	
				EndIf
			EndIf		
		EndIf
		RestArea(aAreaTE0)
	Case FwFldGet("TEU_TPARMA") == "2"
	
		aAreaTE1 := TE1->(GetArea())
	
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
							
		If TE1->(DbSeek(xFilial("TE1")+FwFldGet("TEU_CDARM")))									
			If lIniciado
				//Antes de Alterar, armazena o Ultimo Status
				oMdl := FWModelActive()
				oMdl:setValue("TEUMASTER",'TEU_ULTSTA',TE1->TE1_SITUA)	
				
				RecLock("TE1",.F.)
				REPLACE TE1_SITUA WITH "3"
				MsUnLock()	
				
				//Grava o registro de Alteração do FREAR
				At780Hist(Nil,FwFldGet("TEU_CDARM"),.F.,.T.,"3")
			ElseIf lFinalizado			
				If !Empty(TEU->TEU_ULTSTA)
					//Retorna ao Status Anterior
					RecLock("TE1",.F.)
						REPLACE TE1_SITUA WITH TEU->TEU_ULTSTA
					MsUnLock()	
				
					//Grava o registro de Alteração do FREAR
					At780Hist(Nil,FwFldGet("TEU_CDARM"),.F.,.T.,TEU->TEU_ULTSTA)
				ElseIf FwFldGet("TEU_STATUS") <> "1"
					//Grava o registro de Alteração do FREAR
					At780Hist(Nil,FwFldGet("TEU_CDARM"),.F.,.T.,"3")
				EndIf
			EndIf	
		EndIf
		RestArea(aAreaTE1)
	Case FwFldGet("TEU_TPARMA") == "3"
		If lIniciado
			At780IncTFP(lIniciado,Nil)
		ElseIf lFinalizado
			//Antes de Finalizar valida se há registro de manutenção na TFP
			lAtuSaldo := At780VerSaldo(.T.)
			At780IncTFP(Nil,lFinalizado,lAtuSaldo)
		EndIf			
EndCase
			
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780Hist

Atualiza a Tabela TIO para armazenar toda troca de Status dos Armamentos

@author Serviços
@since 20/08/13
@version P11 R9

@param cArma,Codigo da Arma
@Param cColete,Codigo do Colete
@Param lArma,Indica se deve Atualizar a Arma
@Param lColete,Indica se deve atualizar o Colete

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780Hist(cArma,cColete,lArma,lColete,cStatus)

Default cArma		:= ""
Default cColete	:= ""
Default lArma		:= .F.	
Default lColete	:= .F.
Default cStatus	:= ""

//Grava o TIO para controle do FREAR
Begin Transaction
	DbSelectArea("TIO")
	RecLock("TIO",.T.)
		REPLACE TIO_FILIAL 	With xFilial("TIO")
		REPLACE TIO_CODIGO 	With GetSXENum("TIO","TIO_CODIGO")
		REPLACE TIO_CODMNT 	With FwFldGet("TEU_CODIGO")
		REPLACE TIO_DTALT 	With dDataBase		
		If lArma
			REPLACE TIO_ARMA 	With cArma
			REPLACE TIO_MOTIVO 	With FwFldGet("TEU_MOTIVO")
			REPLACE TIO_FREAR		With cStatus 
		ElseIf lColete
			REPLACE TIO_COLETE With cColete
			REPLACE TIO_MOTIVO 	With FwFldGet("TEU_MOTIVO")
			REPLACE TIO_FREAR		With cStatus
		EndIf
		REPLACE TIO_CODUSU 	With __cUserId
	MsUnlock()
	ConfirmSX8()
End Transaction	

	
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780IncTFP

Atualiza a Tabela TFP e registra a manutenção

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780IncTFP(lIniciado,lFinalizado,lAtuSaldo)
Local lRet			:= .T.
Local lContinua	:= .F.
Local aAreaTFP	:= TFP->(GetArea())
Local aAreaTE2	:= TE2->(GetArea())
Local cLote		:= ""

Default lIniciado		:= .F.
Default lFinalizado	:= .F.
Default lAtuSaldo		:= .F.

If lIniciado .And. !Empty(FwFldGet("TEU_CODLOC")) 
	
	//Atualiza o Saldo do Local Selecionada para a Manutenção
	If FwFldGet("TEU_ENTORI") == "1"
		//Atualiza o Saldo do Local Interno Selecionada para a Manutenção
		TFP->(DbSetOrder(2))
	Else
		//Atualiza o Saldo do Local de Alocação Selecionada para a Manutenção
		TFP->(DbSetOrder(4))
	EndIf
	
	DbSelectArea("TE2")
	TE2->(DbSetOrder(1))
	
	If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TEU_CDARM")))
	
		If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TEU_ENTORI") + FwFldGet("TEU_CODLOC") + TE2->TE2_LOTE))
			cLote	:= TFP->TFP_LOTE
			Begin Transaction
				DbSelectArea("TFP")
				RecLock("TFP",.F.)
					REPLACE TFP_SALDO		With (TFP->TFP_SALDO - FwFldGet("TEU_QTDMUN"))
				MsUnlock()
			End Transaction
			lContinua	:= .T.	
		EndIf
	EndIf
	
	If lContinua
		Begin Transaction
			DbSelectArea("TFP")
			RecLock("TFP",.T.)
				REPLACE TFP_FILIAL 	With xFilial("TFP")
				REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
				REPLACE TFP_ENTIDA 	With FwFldGet("TEU_ENTORI")				
				
				If FwFldGet("TEU_ENTORI") == "1"
					//Informa o Local Interno
					REPLACE TFP_CODINT 	With FwFldGet("TEU_CODLOC")	
				Else
					//Informa o Local de Atendimento
					REPLACE TFP_CODLOC 	With FwFldGet("TEU_CODLOC")	
				EndIf
					
				REPLACE TFP_SALDO		With FwFldGet("TEU_QTDMUN")
				REPLACE TFP_MOVIM 	With "6"
				REPLACE TFP_CODMUN	With FwFldGet("TEU_CDARM")
				REPLACE TFP_LOTE		With cLote
				REPLACE TFP_DTHIST	With dDataBase
				REPLACE TFP_MANUT		With FwFldGet("TEU_CODIGO")	
			MsUnlock()
			ConfirmSX8()
		End Transaction
	EndIf
ElseIf lFinalizado .And. !Empty(FwFldGet("TEU_CODLOC")) 
	
	If FwFldGet("TEU_ENTORI") == "1"
		//Atualiza o Saldo do Local Interno Selecionada para a Manutenção
		TFP->(DbSetOrder(2))
	Else
		//Atualiza o Saldo do Local de Alocação Selecionada para a Manutenção
		TFP->(DbSetOrder(4))
	EndIf
	
	DbSelectArea("TE2")
	TE2->(DbSetOrder(1))
	
	If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TEU_CDARM")))
	
		If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TEU_ENTORI") + FwFldGet("TEU_CODLOC") + TE2->TE2_LOTE))
			cLote	:= TFP->TFP_LOTE
			Begin Transaction
				DbSelectArea("TFP")
					If lAtuSaldo
						RecLock("TFP",.F.)
							REPLACE TFP_SALDO		With (TFP->TFP_SALDO + FwFldGet("TEU_QTDMUN"))
						MsUnlock()
						
						//Atualiza a linha de manutenção encerrando a mesma
						If FwFldGet("TEU_ENTORI") == "1"
							//AtLocal Interno Selecionada para a Manutenção
							TFP->(DbSetOrder(3))
							If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TEU_ENTORI") + FwFldGet("TEU_CODLOC") + FwFldGet("TEU_CODIGO")))
								RecLock("TFP",.F.)
									REPLACE TFP_STATUS	With "1"								//Efetivada
								MsUnlock()	
							EndIf
						Else
							//Local de Alocação Selecionada para a Manutenção
							TFP->(DbSetOrder(5))
							If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TEU_ENTORI") + FwFldGet("TEU_CODLOC") + FwFldGet("TEU_CODIGO")))
								RecLock("TFP",.F.)
									REPLACE TFP_STATUS	With "1"								//Efetivada
								MsUnlock()	
							EndIf
						EndIf
					Else
						RecLock("TFP",.T.)
							REPLACE TFP_FILIAL 	With xFilial("TFP")
							REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
							REPLACE TFP_ENTIDA 	With FwFldGet("TEU_ENTORI")	
							
							If FwFldGet("TEU_ENTORI") == "1"
								//Informa o Local Interno
								REPLACE TFP_CODINT 	With FwFldGet("TEU_CODLOC")	
							Else
								//Informa o Local de Atendimento
								REPLACE TFP_CODLOC 	With FwFldGet("TEU_CODLOC")	
							EndIf	
							
							REPLACE TFP_SALDO		With FwFldGet("TEU_QTDMUN")
							REPLACE TFP_MOVIM 	With "6"
							REPLACE TFP_CODMUN	With FwFldGet("TEU_CDARM")
							REPLACE TFP_LOTE		With cLote
							REPLACE TFP_DTHIST	With dDataBase
							REPLACE TFP_MANUT		With FwFldGet("TEU_CODIGO")
							REPLACE TFP_STATUS	With "1"								//Efetivada	
						MsUnlock()
						ConfirmSX8()
					EndIf
			End Transaction
		EndIf
	EndIf
EndIf

RestArea(aAreaTFP)
RestArea(aAreaTE2)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780WLoc

Função para controlar o When dos campos de Munição
@sample 	At780WLoc() 
@since		11/09/2013 
@version P11 R9
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780WLoc()  
Local lRet := .F.

If !Empty(FwFldGet("TEU_ENTORI"))
	lRet := .T.
EndIF


Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780WArm

When para ativar o campo de codigo da arma
@sample 	At780WLoc() 
@since		11/09/2013 
@version P11 R9
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780WArm()  
Local lRet := .F.

If !Empty(FwFldGet("TEU_TPARMA"))
	lRet := .T.
EndIF

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780WEntOr

Função para controlar o When do campo de Entidade de Origem
@sample 	At780WEntOr() 
@since		11/09/2013 
@version P11 R9
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780WEntOr()  
Local lRet := .F.

If !Inclui .And. TEU->TEU_STATUS == "1" .And. FwFldGet("TEU_TPARMA") == "3"
	lRet := .T.
EndIf

If Inclui .And. FwFldGet("TEU_TPARMA") == "3" .And. !Empty(FwFldGet("TEU_CDARM"))
	lRet := .T.
EndIF

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780IncMaster

Função modelo de como será a execauto para o cadastro de manutenção
@sample 	U_At780IncMaster() 
@since		11/09/2013 
@version P11 R9
     
@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
User Function At780IncMaster()
Local aCampos	:= {}

Private lMsHelpAuto := .T.												// Variavel de controle interno do ExecAuto
Private lMsErroAuto := .F.	
/*
ConOut(Repl("-",80))
ConOut(PadC("Teste Prepare Env",80))
PREPARE ENVIRONMENT EMPRESA 'T1' FILIAL 'D MG 01' USER 'admin' PASSWORD '' TABLES "SX6" MODULO "TEC"
Conout(cEmpAnt+"-"+cFilAnt)
*/

aCampos:= {    	{"TEU_CODIGO"		,GetSXENum("TEU","TEU_CODIGO")         		,NIL},;
					{"TEU_TPARMA"     ,"1"     					,NIL},;
                	{"TEU_CDARM"      ,"ARMA00000000001"     	,NIL},;    
                	{"TEU_CDRESP"		,"FORN02"     			,NIL},;
                	{"TEU_DTABER"		,dDatabase             	,NIL},;
                	{"TEU_TPMNT"		,"2"          			,NIL},;       
                	{"TEU_MOTIVO"    ,"Teste de Inclusão"  	,NIL}}

Processa( { || TECA780(aCampos,3) },'Aguarde','Processando...',.F.)

If lMsErroAuto
	MostraErro()
	DisarmTransaction()
EndIf

ConfirmSX8()

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780ConsLoc

Realiza a Consulta especifica para os Locais de Alocação
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780ConsLoc()
Local lRet			:= .T.
Local aCmpBco		:= {}
Local cQuery		:= ""
Local cDscCmp		:= ""
Local cConteudo	:= ""
Local cCodigo		:= ""
Local cEntida		:= ""
Local cLocal		:= ""
Local lOk			:= .F.
Local aArea		:= GetArea()
Local oModel				//Modelo atual
Local oDlgCmp				//Dialog
Local oPanel 				//Objeto Panel
Local oFooter				//Rodapé
Local oListBox			//Grid campos
Local oOk					//Objeto Confirma 
Local oCancel				//Objeto Cancel

aCmpBco := At780QryLoc()

If Empty(aCmpBco)
	Help( ,, "At780ConsLoc",, STR0033, 1, 0 ) //"Não há alocação para a Origem selecionada"
	Return(.T.)
EndIf

//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
Define MsDialog oDlgCmp FROM 000, 000 To 350, 550 Pixel
		
// Cria o panel principal
@ 000, 000 MsPanel oPanel Of oDlgCmp Size 250, 340 // Coordenada para o panel
oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
// Criação do grid para o panel	
oListBox := TWBrowse():New( 40,05,204,100,,{STR0016,STR0023,STR0024,STR0025, STR0026, STR0027, STR0028},,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) // "Codigo","Entidade","Codigo Interno","Codigo do Local", "Movimentação", "Saldo", "Lote"
oListBox:SetArray(aCmpBco) // Atrela os dados do grid com a matriz
oListBox:bLine := { ||{aCmpBco[oListBox:nAT][1],aCmpBco[oListBox:nAT][2],aCmpBco[oListBox:nAT][3],aCmpBco[oListBox:nAT][4],aCmpBco[oListBox:nAT][5],aCmpBco[oListBox:nAT][6],aCmpBco[oListBox:nAT][7]}} // Indica as linhas do grid
oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgCmp:End()} // Duplo clique executa a ação do objeto indicado
oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
	
// Cria o panel para os botoes	
@ 000, 000 MsPanel oFooter Of oDlgCmp Size 000, 010 // Corrdenada para o panel dos botoes (size)
oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
// Botoes para o grid auxiliar	
@ 000, 000 Button oCancel Prompt STR0029  Of oFooter Size 030, 000 Pixel //Cancelar
oCancel:bAction := { || lOk := .F., oDlgCmp:End() }
oCancel:Align   := CONTROL_ALIGN_RIGHT
	
@ 000, 000 Button oOk     Prompt STR0030 Of oFooter Size 030, 000 Pixel //Confirmar
oOk:bAction     := { || lOk := .T.,cCodigo:=aCmpBco[oListBox:nAT][3],cEntida:=aCmpBco[oListBox:nAT][2],cLocal:=aCmpBco[oListBox:nAT][4],oDlgCmp:End() } // Acao ao clicar no botao
oOk:Align       := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
	
	// Ativa a tela exibindo conforme a coordenada
Activate MsDialog oDlgCmp Centered
		
//Utilizar o modelo ativo para substituir os valores das variaves de memoria		
oModel	:= FWModelActive()
	
If lOk
	If cEntida == "1"
		cTab	:= "TER"
		oModel:SetValue("TEUMASTER","TEU_CODLOC", cCodigo)
	ElseIf cEntida == "2"
		cTab := "ABS"
		oModel:SetValue("TEUMASTER","TEU_CODLOC", cLocal)
	EndIf
EndIf

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT780RetLoc

Retorna a variavel da memoria do model, para a consulta especifica
@sample 	AT840RetLoc() 
@since		11/09/2013
@version P11 R9
     
@return 	cCodigo, CHARACTER, conteudo da variavel de memoria.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780RetLoc()
Return (FwFldGet("TEU_CODLOC"))

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780VerSaldo

Verifica o saldo da munição, validando a quantidade
@sample 	At780VerSaldo(lRegistro) 
@since		11/09/2013
@version P11 R9
     
@return 	cCodigo, CHARACTER, conteudo da variavel de memoria.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At780VerSaldo(lRegistro)
Local lRet			:= .T.
Local aAreaTFP	:= TFP->(GetArea())
Local aAreaTE2	:= TE2->(GetArea())
Default lRegistro := .F.

DbSelectArea("TFP")

DbSelectArea("TE2")
TE2->(DbSetOrder(1))
	
If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TEU_CDARM")))
	
	If !lRegistro
		
		If FwFldGet("TEU_ENTORI") == "1"
			//Atualiza o Saldo do Local Interno Selecionada para a Manutenção
			TFP->(DbSetOrder(2))
		Else
			//Atualiza o Saldo do Local de Alocação Selecionada para a Manutenção
			TFP->(DbSetOrder(4))
		EndIf
		
		If TFP->(DbSeek(xFilial("TFP") + FwFldGet("TEU_ENTORI") + FwFldGet("TEU_CODLOC") + TE2->TE2_LOTE))
			If TFP->TFP_SALDO < FwFldGet("TEU_QTDMUN")
				Help( ,, "At780VerSaldo",, STR0031, 1, 0 )//Quantidade,"A quantidade informada é maior do que está alocado!"
				lRet := .F.
			EndIf
		EndIf
	Else
		If FwFldGet("TEU_ENTORI") == "1"
			//Atualiza o Saldo do Local Interno Selecionada para a Manutenção
			TFP->(DbSetOrder(3))
		Else
			//Atualiza o Saldo do Local de Alocação Selecionada para a Manutenção
			TFP->(DbSetOrder(5))
		EndIf
		//Verifica se há registro de Manutenção, senão não altera o Saldo
		If !TFP->(DbSeek(xFilial("TFP") + FwFldGet("TEU_ENTORI") + FwFldGet("TEU_CODLOC") + FwFldGet("TEU_CODIGO")))
			lRet := .F.
		EndIf
	EndIf	
EndIf

RestArea(aAreaTFP)
RestArea(aAreaTE2)					

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtVldResp

Valida o codigo do responsavel
@sample 	AtVldResp() 
@since		11/09/2013
@version P11 R9
@Param cCodigo, Codigo do Local informado no campo TEU_CDRESP
     
@return 	lRet, .T. se Houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AtVldResp(cCodigo)
Local lRet		:= .T.
Local nY		:= 0	
Local aResp	:= {}

aResp := At780Query()

nY := aScan(aResp,{|x| AllTrim(x[1]) == Alltrim(cCodigo)})

If nY == 0
	Help( ,, "AtVldResp",, STR0032, 1, 0 )//"Codigo","O codigo informado não está relacionado"
	lRet := .F.	
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780LocMun

Valida se o local informado realmente existe para a munição informada
@sample At780LocMun(cCodigo) 
@author Serviços
@since 28/08/13
@version P11 R9
@Param cCodigo, Codigo do Local informado no campo TEU_CODLOC

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780LocMun(cCodigo)
Local lRet		:= .T.
Local nY		:= 0	
Local oModel	:= Nil
Local aArea	:= GetArea()
Local aLoc		:= {}

aLoc := At780QryLoc()
	
If FwFldGet("TEU_ENTORI") == "1"
		//Faz a Busca para Locais Internos
	nY := aScan(aLoc,{|x| AllTrim(x[3]) == Alltrim(cCodigo)})
		
	If nY == 0
		Help(" ",1,"At780LocMun",, STR0032, 1, 0 )//"Codigo","O codigo informado não está relacionado"
		lRet := .F.
	EndIf
Else
		//Faz a Busca para Locais de Atendimento
	nY := aScan(aLoc,{|x| AllTrim(x[4]) == Alltrim(cCodigo)})
		
	If nY == 0
		Help(" ",1,"At780LocMun",, STR0032, 1, 0 )//"Codigo","O codigo informado não está relacionado"
		lRet := .F.
	EndIf
		
EndIf

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780CleArm

Limpa os campos de codigo e descrições dependendo do tipo de armamentos
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780CleArm()
Local lRet			:= .T.
Local oModel		:= FWModelActive()

If 	FwFldGet("TEU_TPARMA") == "1" .Or. FwFldGet("TEU_TPARMA") == "2"
	
	//Limpa o codigo da arma quando ela for alterada
	If !Empty(FwFldGet("TEU_CDARM"))
		oModel:LoadValue("TEUMASTER","TEU_CDARM", "")
		oModel:LoadValue("TEUMASTER","TEU_DSCARM", "")
	EndIf
	
	//Limpa o codigo da arma quando ela for alterada
	If !Empty(FwFldGet("TEU_CODLOC"))
		oModel:LoadValue("TEUMASTER","TEU_CODLOC", "")
		oModel:LoadValue("TEUMASTER","TEU_DSCLOC", "")
		oModel:LoadValue("TEUMASTER","TEU_QTDMUN", 0)
	EndIf
	
ElseIf	FwFldGet("TEU_TPARMA") == "3" 
	
	//Limpa o codigo da arma quando ela for alterada
	If !Empty(FwFldGet("TEU_CDARM"))
		oModel:LoadValue("TEUMASTER","TEU_CDARM", "")
		oModel:LoadValue("TEUMASTER","TEU_DSCARM", "")
	EndIf	
		
EndIf
	
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780ClnOri

Limpa os campos de descrição codigo dependendo da seleção do campo TEU_ENTORI
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780ClnOri()
Local lRet		:= .T.
Local oModel	:= FWModelActive()

If (FwFldGet("TEU_ENTORI") == "1" .Or. FwFldGet("TEU_ENTORI") == "2")
	
	//Limpa o codigo de Origem e sua descrição	
	If !Empty(FwFldGet("TEU_CODLOC"))
		oModel:LoadValue("TEUMASTER","TEU_CODLOC", "")
		oModel:LoadValue("TEUMASTER","TEU_DSCLOC", "")
	EndIf
			
EndIf
	
Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At780IniArma

Realiza o preenchimento do inicializador dos armamentos
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Armamento 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At780IniArma(cItem,cArma)
Local cProd := ""
Local cDesc := ""
	
Default cItem		:= ""
Default cArma		:= ""

If !INCLUI .And. !Empty(cItem) .And. !Empty(cArma)

	Do Case
		Case cItem == "1
			cProd := Posicione("TE0",1,xFilial("TE0") + cArma ,"TE0->TE0_CODPRO")	
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")

		Case cItem == "2"
			cProd := Posicione("TE1",1,xFilial("TE1") + cArma ,"TE1->TE1_CODPRO")
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
		
		Case cItem == "3"
			cProd := Posicione("TE2",1,xFilial("TE2") + cArma ,"TE2->TE2_CODPRO")
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
	
	EndCase
	
EndIf
	
Return(cDesc)

Function At780TmpTbl()
Local aRet				:= {}
Local cAlias			:= GetNextAlias()
Local cCond			:= "1"
Local cTempTab		:= ''	   								
Local oTempTab		:= Nil
Local lOk				:= .F.
Local aCampos			:= {}									//Campos retornados na consulta
Local aColumns		:= {}									//Estrutura dos campos retornada de acordo com os campos em aCampos
Local aStructure		:= {}									//Estrutura da tabela para criação do arquivo temporário
Local aSeek			:= {}
Local oBrwCons		:= Nil
Local oDlg				:= Nil
Local oModel			:= Nil

//-----------------------------------------------------------------------------------------
// Estrutura de campos da tabela temporária
//-----------------------------------------------------------------------------------------

//Campos retornados
AAdd( aCampos, { 'AA1_CODTEC'	, TxDadosCpo( 'AA1_CODTEC' )[1]	} )
AAdd( aCampos, { 'AA1_NOMTEC'	, TxDadosCpo( 'AA1_NOMTEC' )[1]	} )

//Estrutura para criação do arquivo temporário
AAdd( aStructure, { aCampos[1][1]	, 'C', TamSX3('AA1_CODTEC')[1], TamSX3('AA1_CODTEC')[2] } )
AAdd( aStructure, { aCampos[2][1]	, 'C', TamSX3('AA1_NOMTEC')[1], TamSX3('AA1_NOMTEC')[2] } )

Aadd( aSeek, {"Código", {{"","C",TamSX3("AA1_CODTEC")[1],0,"Código",,}} } )
Aadd( aSeek, {"Nome", {{"","C",TamSX3("AA1_NOMTEC")[1],0,"Descrição",,}}})

If Select("cAlias") > 0 
	(cAlias)->(DbCloseArea())
Endif

BeginSQL alias cAlias		
	SELECT AA1.AA1_CODTEC,
			AA1.AA1_NOMTEC 
	FROM
		%Table:AA1% AA1
	WHERE
		AA1.AA1_FILIAL = %xfilial:AA1%
		AND
		AA1.AA1_RSPMNT = %Exp:cCond%
		AND
		AA1.%NotDel%
	Union
	SELECT SA2.A2_COD,
			SA2.A2_NOME 
	FROM
		%Table:SA2% SA2
	WHERE
		SA2.A2_FILIAL = %xfilial:SA2%
		AND
		SA2.%NotDel%	   	
EndSQL	

//----------------------------------------------------------------------
// Cria arquivo de dados temporário
//----------------------------------------------------------------------
cTempTab:= GetNextAlias()
oTempTab:= FWTemporaryTable():New(cTempTab)
oTempTab:SetFields(aStructure)
oTempTab:AddIndex("I1",{"AA1_CODTEC"})
oTempTab:AddIndex("I2",{"AA1_NOMTEC"})
oTempTab:Create()

(cTempTab)->(dbGotop())

DBTblCopy(cAlias, cTempTab)

If ( Select( cAlias ) > 0 )
	DbSelectArea(cAlias)
	DbCloseArea()
EndIf

dbSelectArea(cTempTab)

	DEFINE DIALOG oDlg TITLE "Responsavél pela Manutenção" FROM 0,0 TO 460,800 PIXEL Style 128 // 'Consulta'

	oBrwCons := FWFormBrowse():New() 
	oBrwCons:SetDataQuery(.F.)
	oBrwCons:SetDataTable(.T.) 
	oBrwCons:SetAlias( cTempTab )
	oBrwCons:SetTemporary(.T.)
	oBrwCons:SetDescription( "Responsável" ) // 'Consulta de Equipamentos - Detalhe'
	oBrwCons:SetOwner(oDlg)
	oBrwCons:SetUseFilter()
	oBrwCons:DisableConfig()
	oBrwCons:SetSeek(,aSeek)
	
	oBrwCons:AddButton(STR0029,{ || lOk := .F., oDlg:End() },,,,.F.,1)  // "Cancelar"
	oBrwCons:AddButton(STR0030,{ || lOk := .T.,cCampo:=(oBrwCons:Alias())->AA1_CODTEC,cDesc:=(oBrwCons:Alias())->AA1_NOMTEC ,oDlg:End() },,,,.F.,1) //"Confirmar"
	
	ADD COLUMN oColumn DATA {|| AA1_CODTEC}  TITLE "Codigo" SIZE TamSX3("AA1_CODTEC")[1] OF oBrwCons //"Código"
	ADD COLUMN oColumn DATA {|| AA1_NOMTEC}  TITLE "Nome" SIZE TamSX3("AA1_NOMTEC")[1] OF oBrwCons //"Descrição"
	
	oBrwCons:DisableDetails()
	oBrwCons:Activate()
	
	ACTIVATE DIALOG oDlg CENTERED	
	
	TecDestroy(oTempTab)
	TecDestroy(oBrwCons)
	
	If IsInCallStack("TECA880")
		//Utilizar o modelo ativo para substituir os valores das variaves de memoria		
		oModel	:= FWModelActive()
		nOperation := oModel:GetOperation() 		
			
		If ((nOperation == MODEL_OPERATION_INSERT) .or. (nOperation == MODEL_OPERATION_UPDATE)) .and. lOk 
			oModel:SetValue("TFQMASTER","TFQ_CDRESP", cCampo)
		EndIf
	Else		
		//Utilizar o modelo ativo para substituir os valores das variaves de memoria		
		oModel	:= FWModelActive()
		nOperation := oModel:GetOperation() 		
			
		If ((nOperation == MODEL_OPERATION_INSERT) .or. (nOperation == MODEL_OPERATION_UPDATE)) .and. lOk
			oModel:SetValue("TEUMASTER","TEU_CDRESP", cCampo)
		EndIf
	EndIf
	
Return(lOk)