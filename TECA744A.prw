#INCLUDE 'PROTHEUS.CH' 
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA744A.CH'

//Itens do browse de base de atendimento
#DEFINE B_MARCA  			1
#DEFINE B_CODPRO			2
#DEFINE B_DESCRI			3
#DEFINE B_NUMSER			4
#DEFINE B_SITE  			5
#DEFINE B_CODFAB 			6
#DEFINE B_LOJFAB 			7

Static	cNumSerAA3	:= ' '

/*/{Protheus.doc} TECA744A
Rotina de efetivação de orçamentos de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@sample 	TECA744A() 
@since		15/07/2016       
@version	P12   
/*/
Function TECA744A()
Local aArea    := GetArea()                                             // Salva área corrente atual.
Local aAreaTFL := TFL->(GetArea())                                      // Salva área corrente da TFL.
Local aAreaTFF := TFF->(GetArea())                                      // Salva área corrente da TFH.
Local aAreaTFI := TFI->(GetArea())                                      // Salva área corrente da TFI.
Local cNrContr := ""                                                    // Numero do contrato.
Local cIdBase  := ""                                                    // Id da base de atendimento.
Local cRevisao := ""                                                    // Número de revisão do contrato.
Local lEfetiva := .T.                                                   // Indica se o orçamento será efetivado de fato.
Local cCodTFJ  := TFJ->TFJ_CODIGO                                       // Codigo da TFJ (Orçamento de Serviços).
Local cCodTFL  := ""                                                    // Codigo da TFL (Locais de Atendimento).
Local cOrcPai  := ""                                                    // Orçamento que originou o contrato no qual o orçamento de serviço de reforço será vinculado.
Local aButtons := {{.F.,Nil} ,{.F.,Nil},{.F.,Nil}     ,{.F.,Nil}     ,;
				   {.F.,Nil} ,{.F.,Nil},{.T.,STR0001} ,{.T.,STR0002} ,; //"Efetivar"###"Cancelar"
				   {.F.,Nil },{.F.,Nil},{.F.,Nil}     ,{.F.,Nil}     ,;
				   {.F.,Nil} ,{.F.,Nil}}                                // Botões da FwExecView				   

If AllTrim(TFJ->TFJ_STATUS) == "1" // Valido se o orçamento de serviços já foi efetivado.
	lEfetiva := .F.
	Help("",1,"TECA744AVLD",,STR0003,2,0) //"Esse orçamento já está efetivado!"
EndIf

If AllTrim(TFJ->TFJ_STATUS) == "5" // Valido se o orçamento de serviços foi encerrado.
	lEfetiva := .F.
	Help("",1,"TECA744AVLD",,STR0021,2,0) //"Esse orçamento já está efetivado!"
EndIf

Begin Transaction

If SX1->(DbSeek("TEC744A   02"))
	RecLock('SX1',.F.)
	X1_CNT01 := ' '
	MsUnlock()
EndIf

If lEfetiva .AND. Pergunte("TEC744A",.T.)

	cNrContr := AllTrim(MV_PAR01)
	cIdBase  := AllTrim(MV_PAR02)
	If Empty(cNrContr) // Se o número de contrato estiver vazio, exibe aviso de confirmação
		If !MsgYesNo(STR0005,STR0006) //"O número do contrato com o cliente não foi preenchido! Deseja confirmar a efetivação?"###"Contrato não preenchido!"
			lEfetiva := .F.		
			DisarmTransaction()
		EndIf
		If lEfetiva
			If Empty(cIdBase) 
				Help("",1,"TECA744A",,STR0011,2,0) // 'É necessário informar uma base de atendimento!'
				lEfetiva := .F.	
			Else
				AA3->(DbSetOrder(6))
				If AA3->(DbSeek(xFilial('AA3') + cIdBase ) )
					If AA3->AA3_CONTRT <> ' ' .And. AA3->AA3_ORIGEM <> ' '
						Help("",1,"TECA744A",,STR0013,2,0) //'Esta base de atendimento já esta sendo utilizada, selecione outro registro!'
						lEfetiva := .F.
					EndIf
				Else
					Help("",1,"TECA744A",,STR0012,2,0) // 'Base de Atendimento Inexistente!'
					lEfetiva := .F.								
				EndIF
			EndIf
		EndIf
	Else 
		/*/ 
			Se o número de contrato for preenchido, valida se ele está ativo e se o cliente do orçamento de serviços posicionado faz parte desse contrato.
			Também retorna o código do orçamento de serviços vinculado ao contrato selecionado.
		/*/ 
		lEfetiva:= At744VldContr( cNrContr, TFJ->TFJ_CODENT, TFJ->TFJ_LOJA, @cOrcPai )
	EndIf
	
	If lEfetiva // Monta a tela para o usuário visualizar o orçamento de serviços antes de fazer a efetivação.
		lEfetiva := FWExecView(STR0007, 'TECA744A', MODEL_OPERATION_UPDATE,, {||.T.}, {||At744AEfetiva(cCodTFJ, cNrContr, cOrcPai,cIdBase)},,aButtons ,{||At744ACancela()} ) == 0 //"Efetivar Orçamento de Serviços Extra"
	EndIf
Else
	DisarmTransaction()
EndIf

End Transaction
RestArea(aArea)
RestArea(aAreaTFL)
RestArea(aAreaTFF)
RestArea(aAreaTFI)

Return

/*/{Protheus.doc} ModelDef
Definicao do Modelo

@author Leandro Dourado - Totvs Ibirapuera
@since 06/08/2012
@version 11.7
/*/
Static Function ModelDef()
Local oModel     := FwLoadModel("TECA744")
Local oSubMdl    := Nil
Local cIdMdl     := ""
Local aSubMdls   := oModel:GetAllSubModels()
Local oStructNx  := Nil
Local nX         := 0

For nX := 1 to Len(aSubMdls)
	cIdMdl    := aSubMdls[nX]:cID
	oSubMdl   := oModel:GetModel(cIdMdl)
	If oSubMdl:ClassName() == "FWFORMGRID"
		oSubMdl:SetNoDeleteLine(.T.)
		oSubMdl:SetNoInsertLine(.T.)
	EndIf
	
	oStructNx := oSubMdl:GetStruct()
	oStructNx:SetProperty("*",MODEL_FIELD_OBRIGAT,.F.)
Next nX

Return oModel

/*/{Protheus.doc} ViewDef
Definicao de Interface.

@author Leandro Dourado - Totvs Ibirapuera
@since 06/08/2012
@version 11.7
/*/
Static Function ViewDef()
Local oView    := FwLoadView("TECA744")
Local oModel   := ModelDef()
Local aSubMdls := oView:GetModelsIds()
Local nX       := 0

oView:SetModel(oModel)

For nX := 1 To Len(aSubMdls)
	If !(aSubMdls[nX] $ "TOTAIS|MES_TOT")
		oView:SetViewProperty(aSubMdls[nX], "ONLYVIEW")   
	EndIf
Next nX
oView:SetAfterViewActivate({|oView| InitDados(oView) })

Return oView

/*/{Protheus.doc} InitDados
Definicao de Interface.

@author Leandro Dourado - Totvs Ibirapuera
@since 06/08/2012
@version 11.7
/*/
Static Function InitDados(oView)
Local oModel  := FwModelActive()
Local cStatus := oModel:GetValue("TFJ_REFER","TFJ_STATUS")

oModel:LoadValue("TFJ_REFER","TFJ_STATUS",cStatus)

Return

/*/{Protheus.doc} At744VldContr
Valida se o contrato informado é valido e se o cliente do orçamento posicionado está relacionado ao contrato informado.

@author 	Leandro Dourado - Totvs Ibirapuera
@since		18/07/2016       
@version	P12   
@param      cNrContr, String, Número do contrato a ser validado.
@param      cCliente, String, Cliente do orçamento de serviços posicionado.
@param      cLoja   , String, Loja do cliente do orçamento de serviços posicionado.
@param      cOrcPai , String, Orçamento que originou o contrato que está sendo validado.
/*/
Function At744VldContr(cNrContr, cCliente, cLoja, cOrcPai)
Local aArea      := GetArea()
Local aAreaTFJ   := TFJ->(GetArea())
Local lRet       := .F.

Default cNrContr := ""
Default cOrcPai  := ""

If !Empty(cNrContr)
	cRevisao := Posicione("CN9",7,xFilial("CN9")+cNrContr+"05","CN9_REVISA")
	lRet     := At930VldCont(cNrContr,cRevisao) 
EndIf

If lRet
	DbSelectArea("CNC")
	CNC->(DbSetOrder(3)) // CNC_FILIAL+CNC_NUMERO+CNC_REVISA+CNC_CLIENT+CNC_LOJACL
	lRet := CNC->(DbSeek(FWxFilial("CNC")+cNrContr+cRevisao+cCliente+cLoja))
	
	If !lRet
		Help("",1,"TECA744AVLD",,STR0008,2,0) //"O cliente desse orçamento não está vinculado ao contrato informado!"
	EndIf
EndIf

If lRet
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(5)) //TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
	
	If TFJ->(DbSeek(FWxFilial('TFJ')+cNrContr+cRevisao))
		cOrcPai := TFJ->TFJ_CODIGO
	EndIf
EndIf

RestArea( aArea )
RestArea( aAreaTFJ )

Return lRet


/*/{Protheus.doc} At744AEfetiva
Realiza as tratativas necessárias para a efetivação de um orçamento de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@since		18/07/2016       
@version	P12   
/*/
Function At744AEfetiva( cCodTFJ, cNrContr, cOrcPai ,cIdBase)
Local oModel     := FwModelActive()                                 // Model Ativo
Local cMsgErro   := ""
Local lEfetiva   := .T.
Local lSeqTrn    := (TFF->(FieldPos("TFF_SEQTRN"))>0)               // Indica se o campo TFF_SEQTRN existe no dicionário (SX3).
Local lFilTFF    := FindFunction("ExistFilTFF") .And. ExistFilTFF() // Indica se o campo ABQ_FILTFF existe no banco
Local aItemRH    := {}
Local cCodTFL    := ""
Local oModelTFF  := oModel:GetModel("TFF_RH")
Local oModelTFG  := oModel:GetModel("TFG_MI")
Local oModelTFH  := oModel:GetModel("TFH_MC")
Local oModelTFI  := oModel:GetModel("TFI_LE")
Local oModelTFJ  := oModel:GetModel("TFJ_REFER")
Local oModelTFL  := oModel:GetModel("TFL_LOC")
Local nTFF       := 0
Local nTFG       := 0
Local nTFH       := 0
Local nTFI       := 0
Local nTFL       := 0
Local lOrcPrc    := SuperGetMv("MV_ORCPRC",,.F.)
Local cReserva	 := ""

Default cCodTFJ  := TFJ->TFJ_CODIGO
Default cNrContr := AllTrim(MV_PAR01)
Default cOrcPai  := ""

Begin Transaction

	// Gero o movimento inicial de locação de equipamentos logo no início do processo, pois caso algum erro ocorra a efetivação é abortada sem a necessidade de usar controles de transação.
	MsgRun(STR0009, STR0010, {|| lEfetiva := At800Start( @cMsgErro,cCodTFJ )}) // 'Gerando movimentos para locação de equipamentos' ### "Aguarde..."	
	If !lEfetiva
		Help(,,'AT850ERRO01',, cMsgErro,1,0)
	EndIf
	
	If lEfetiva
		
		For nTFL := 1 To oModelTFL:Length()
			oModelTFL:GoLine(nTFL)
			
			// Reinicializo a variável aItemRH, para que ele passe apenas os registros de recursos humanos do local de atendimento posicionado
			aItemRH := {}
			cReserva:= Posicione("ABS",1,xFilial("ABS") + oModelTFL:GetValue("TFL_LOCAL"),"ABS_RESTEC")	
			// Percorro todos os itens de recursos humanos relacionados ao local de atendimento posicionado.
			For nTFF := 1 To oModelTFF:Length()
				oModelTFF:GoLine(nTFF)
				
				If !Empty(oModelTFF:GetValue("TFF_PRODUT"))
					oModelTFF:LoadValue("TFF_COBCTR","2")
					/*/
						Preencho o array com as informações da TFF. 
						O preenchimento desse array é obrigatório para a geração de uma configuração de alocação (tabela ABQ) para os itens de recursos humanos.
					/*/
					Aadd(aItemRH,{;
						oModelTFF:GetValue("TFF_PRODUT"),;                  
						oModelTFF:GetValue("TFF_CARGO")	,;                  
						oModelTFF:GetValue("TFF_FUNCAO"),;                
						oModelTFF:GetValue("TFF_PERINI"),;                
						oModelTFF:GetValue("TFF_PERFIM"),;                  
						oModelTFF:GetValue("TFF_TURNO")	,;                 
						oModelTFF:GetValue("TFF_QTDVEN"),;                
						oModelTFF:GetValue("TFF_COD")   ,;                 
						If( lSeqTrn, oModelTFF:GetValue("TFF_SEQTRN"), ""),; 
						.T.	})                              
					If lFilTFF 
						// Caso lFIllTFF seja igual a true, adiciono a filial da TFF à ultima posição do array, que foi recém inclusa.
						aAdd(aItemRH[Len(aItemRH)],oModelTFF:GetValue("TFF_FILIAL"))
					EndIf
					aAdd(aItemRH[Len(aItemRH)],oModelTFF:GetValue("TFF_ESCALA"))
					aAdd(aItemRH[Len(aItemRH)],oModelTFF:GetValue("TFF_CALEND"))
				EndIf
			Next nTFF
				
			// Chamo a rotina responsável pela geração de configuração de alocação
			If Len(aItemRH) > 0  // Caso não haja nenhum item de recursos humanos, não será necessário gerar a configuração de alocação.
				lEfetiva := At850CnfAlc( cNrContr, oModelTFL:GetValue("TFL_LOCAL"), aItemRH, cCodTFJ )
			EndIf
			
			If lEfetiva
				If !lOrcPrc
					For nTFF := 1 To oModelTFF:Length()
						oModelTFF:GoLine(nTFF)
						For nTFG := 1 To oModelTFG:Length()
							oModelTFG:GoLine(nTFG)
							If !Empty(oModelTFG:GetValue("TFG_PRODUT"))
								oModelTFG:LoadValue("TFG_COBCTR","2")
							EndIf
							
							If !Empty(oModelTFG:GetValue("TFG_QTDVEN"))
								oModelTFG:LoadValue("TFG_SLD",oModelTFG:GetValue("TFG_QTDVEN"))
							EndIf
						Next nTFG
						
						For nTFH := 1 To oModelTFH:Length()
							oModelTFH:GoLine(nTFH)
							If !Empty(oModelTFH:GetValue("TFH_QTDVEN"))
								oModelTFH:LoadValue("TFH_SLD",oModelTFH:GetValue("TFH_QTDVEN"))
							EndIf
							If !Empty(oModelTFH:GetValue("TFH_PRODUT"))
								oModelTFH:LoadValue("TFH_COBCTR","2")
							EndIf
						Next nTFH
					Next nTFF
				EndIf
			Else
				Exit
			EndIf
			
			If lEfetiva
				If lOrcPrc
					For nTFG := 1 To oModelTFG:Length()
						oModelTFG:GoLine(nTFG)
						If !Empty(oModelTFG:GetValue("TFG_PRODUT"))
							oModelTFG:LoadValue("TFG_COBCTR","2")
						EndIf
						If !Empty(oModelTFG:GetValue("TFG_QTDVEN"))
							oModelTFG:LoadValue("TFG_SLD",oModelTFG:GetValue("TFG_QTDVEN"))
						EndIf
					Next nTFG
					
					For nTFH := 1 To oModelTFH:Length()
						oModelTFH:GoLine(nTFH)
						If !Empty(oModelTFH:GetValue("TFH_PRODUT"))
							oModelTFH:LoadValue("TFH_COBCTR","2")
						EndIf
						If !Empty(oModelTFH:GetValue("TFH_QTDVEN"))
							oModelTFH:LoadValue("TFH_SLD",oModelTFH:GetValue("TFH_QTDVEN"))
						EndIf
					Next nTFH
				EndIf
				
				// Percorro os itens de locação de equipamento relacionados ao local de atendimento posicionado para indicar que eles estão prontos para serem separados.
				For nTFI := 1 To oModelTFI:Length()
					oModelTFI:GoLine(nTFI)
					If !Empty(oModelTFI:GetValue("TFI_PRODUT"))
						oModelTFI:LoadValue("TFI_SRVEXT","1")
					EndIf
				Next nTFI
			Else
				Exit
			EndIf
		Next nTFL
		
		If lEfetiva
			// Altero o status do orçamento de serviços para 1=Ativo.
			oModelTFJ:LoadValue("TFJ_STATUS","1")
			If !Empty(cNrContr)
				oModelTFJ:LoadValue("TFJ_ORCPAI",cOrcPai)
			EndIf
			
			lEfetiva := FwFormCommit(oModel)
		EndIf
		
		If lEfetiva
			// Atualizo base de atendimento
			DbSelectArea("AA3")
			DbSetOrder(6)
			If AA3->(DbSeek(xFilial("AA3")+cIdBase))
				AA3->(RecLock("AA3"))
				AA3->AA3_CONTRT := cCodTFJ
				AA3->AA3_ORIGEM := "TFJ"
				AA3->(MsUnlock())
			EndIf		
		Else
			DisarmTransaction()
			Help( "", 1, "At744AEfetiva", , STR0022, 1, 0,,,,,,;  // "Ocorreu um erro na efetivação."
										{STR0023})  // "Comunique o administrador do sistema."
		EndIf
	
	EndIf

End Transaction

Return lEfetiva

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At744AIncBA

Inclusão de Base de Atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At744AIncBA()

Local aArea		:= GetArea()
Local nOpcA		:= 0  

SaveInter()

Private aRotina := {	{ STR0024	,"AxPesqui"  	,0	,1	,0	,.F.},;//"Pesquisar"
						{ STR0025	,"At040Visua"	,0	,2	,0	,.T.},;	//"Visualizar"
						{ STR0026	,"At040Inclu"	,0	,3	,0	,.T.}} 	//"Incluir"

Private cCadastro := STR0027   // "INCLUSÃO - Base de Atendimento"    

ALTERA	:= .F.
INCLUI	:= .T.

nOpcA := At040Inclu("AA3",0,3)

RestInter()
RestArea(aArea)
Return nOpcA


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At744AVdGvb

Validação Browse sugestão
@author Serviços
@since 31/10/13
@version P11 R9
@param aLocais:locais de atencimento
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At744AVdGvb(aLocais)

Local lRetorno := .T.	// Retorno da rotina.

aEval(aLocais,{|x| IIF(Empty(x[5]),lRetorno := .F., Nil)})

If !lRetorno
	MsgStop(STR0016,STR0004) // "Identificador não informado."##"Atenção"
EndIf

Return( lRetorno )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At744AGvBse

Grava Base de atendimento atraves dos locais de atendimento
@author Serviços
@since 31/10/13
@version P11 R9
@param aLocais:locais de atencimento
@return  .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At744AGvBse(aLocais)

Local lRetorno	:= .T.			// Retorno da rotina.
Local nX		:= 0			// Incremento utilizado no For.
Local aCabec	:= {}			// Array que contem o cabeçalho da tabela AA3.
Local aItens	:= {}			// Array itens da base de atendimento.

Private lMsErroAuto	:= .F.

if Len(aLocais) > 0
	DbSelectArea("AA3")
	AA3->(DbSetOrder(6))
	If !AA3->(DbSeek(xFilial('AA3') + aLocais[5])) 

		Aadd(aCabec,{"AA3_FILIAL"	,xFilial("AA3")	,Nil})
		Aadd(aCabec,{"AA3_CODCLI"	,aLocais[1]	,Nil})
		Aadd(aCabec,{"AA3_LOJA"  	,aLocais[2]	,Nil})
		Aadd(aCabec,{"AA3_CODPRO"	,aLocais[3]	,Nil})
		Aadd(aCabec,{"AA3_NUMSER"	,aLocais[5]	,Nil})
		Aadd(aCabec,{"AA3_DTVEN"	,Date()			,Nil})
		Aadd(aCabec,{"AA3_CODLOC"	,aLocais[6]	,Nil})
	
		MsExecAuto( {|w,x,y,z| TECA040(w,x,y,z)},Nil,aCabec,aItens, 3)
	
		If lMsErroAuto
			MostraErro()	
		EndIf
	EndIf

	aCabec	:= {}
	aItens	:= {}

endif

Return( lRetorno )



/*/{Protheus.doc} At744Bases
Retorna sugestoes de base de atendimento para o usuario
@author 	Rodolfo Novaes
@since 		17/03/2017
@version 	1.0
/*/
Function At744Bases()
local aHeader	:= {'Cliente' , 'Loja' , 'Grupo RH' , 'Produto' , 'Id Novo' , 'Local ' , 'Descrição'}
local aLocais	:= {}
local nSelecao	:= 1
Local nTamNumSer	:= TAMSX3("AA3_NUMSER")[1] 
local cCodOrc		:= ' '
local lRetorno		:= .T.
Local lGsDesag 		:= ( SuperGetMv("MV_GSDSGCN", , "2") == "1" )
Local cProdBase 	:= ""

cCodOrc 	:= 	 TFJ->TFJ_CODIGO 
cIDNovo	:= SUBSTR(cCodOrc + 'TFJ',1,nTamNumSer)+REPLICATE("0",nTamNumSer-Len(SUBSTR(cCodOrc + 'TFJ',1,nTamNumSer))-1)+"1"

DbSelectArea("TFL")
TFL->(DbSetOrder(2)) // TFL_FILIAL+TFL_CODPAI

DbSelectArea("TFF")
TFF->(DbSetOrder(3)) // TFF_FILIAL+TFF_CODPAI

DbSelectArea("TFG")
TFG->(DbSetOrder(3)) // TFG_FILIAL+TFG_CODPAI

DbSelectArea("TFH")
TFH->(DbSetOrder(3)) // TFH_FILIAL+TFH_CODPAI

DbSelectArea("TFI")
TFI->(DbSetOrder(3)) // TFI_FILIAL+TFI_CODPAI

If TFL->(DbSeek(xFilial("TFL")+cCodOrc )) 		
	If !lGsDesag
		cProdBase := TFJ->TFJ_GRPRH
	Else
		If TFF->( DbSeek( xFilial("TFF")+TFL->TFL_CODIGO ) )
			cProdBase := TFF->TFF_PRODUT
		
		ElseIf TFG->( DbSeek( xFilial("TFG")+TFL->TFL_CODIGO ) )
			cProdBase := TFG->TFG_PRODUT
		
		ElseIf TFH->( DbSeek( xFilial("TFH")+TFL->TFL_CODIGO ) )
			cProdBase := TFH->TFH_PRODUT
		
		ElseIf TFI->( DbSeek( xFilial("TFI")+TFL->TFL_CODIGO ) )
			cProdBase := TFI->TFI_PRODUT
		EndIf
	EndIf

	aAdd(aLocais, { TFJ->TFJ_CODENT,;
					TFJ->TFJ_LOJA,;
					cProdBase,;
					Posicione("SB1", 1, xFilial("SB1")+cProdBase, "B1_DESC"),;
					cIDNovo,;
					TFL->TFL_LOCAL,;
					Posicione("ABS", 1, xFilial("ABS")+TFL->TFL_LOCAL, "ABS_DESCRI") } )
		               
	nSelecao := TmsF3Array(aHeader, aLocais, "Sugestão de Base" )
	If nSelecao > 0
		At744AGvBse(aLocais[nSelecao])
		cNumSerAA3 := AA3->AA3_NUMSER
	Else
		lRetorno   := .F.
		cNumSerAA3 := ' '	
		MsgAlert(STR0017, STR0004) //'Selecione uma sugestão de base de atendimento!' # 'Atencao'
	EndIf			               
Else
	if MsgYesNo(STR0018, STR0019) //'Deseja incluir uma nova base de atendimento?' # 'Sugestão não encontrada'
		At744AIncBA()
	EndIf
EndIf

Return ( lRetorno )

/*/{Protheus.doc} At744ARet
Retorna Numero da Base de Atendimento , usado na consulta especifica AA3_05
@author 	Rodolfo
@since 		24/03/2017
@version 1.0
/*/
Function At744ARet()   

Return ( cNumSerAA3 )   

/*/{Protheus.doc} At744ACancela
Realiza tratamento para cancelamento da efetivação.
@author 	Rodolfo
@since 		24/03/2017
@version 	1.0
/*/
Function At744ACancela()
lRetorno := .T.
//Disarm Transaction realizando rollback da base de atendimento.
DisarmTransaction()

Return ( lRetorno)
