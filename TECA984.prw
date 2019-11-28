#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA984.CH"

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA984
@description	Facilitador
@sample	 	TECA984()
@param		Nenhum
@return		NIL
@author		Filipe Gonçalves (filipe.goncalves)
@since		31/05/2016
@version	P12   
/*/
//------------------------------------------------------------------------------
Function TECA984()
Local	oMBrowse	:= FWmBrowse():New()

oMBrowse:SetAlias("TWM")				
oMBrowse:SetDescription(STR0001)	// "Facilitador"

//Legendas
oMBrowse:AddLegend( "TWM_DTVALI >= dDataBase", "GREEN"	, STR0011 	)//"Aberto"
oMBrowse:AddLegend( "TWM_DTVALI <= dDataBase", "RED"		, STR0012 	)//"Encerrado"
// filtra a filial corrente no browse para não ter problema na carga do modelo de dados e leitura do parâmetro de precificação
// quando distribuído por filial
oMBrowse:SetFIlterDefault("TWM->TWM_FILIAL == xFilial('TWM')")

oMBrowse:Activate()

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
@description	Define o menu funcional.
@sample	 		MenuDef()
@param			Nenhum
@return			ExpA: Opções da Rotina.
@author			Filipe Goncalves
@since			31/05/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function MenuDef()    
Local	aRotina	:= {}

ADD OPTION aRotina TITLE STR0002  ACTION "PesqBrw"         OPERATION 1                      ACCESS 0 // "Pesquisar"
ADD OPTION aRotina TITLE STR0003  ACTION "VIEWDEF.TECA984" OPERATION MODEL_OPERATION_VIEW   ACCESS 0 // "Visualizar"
ADD OPTION aRotina TITLE STR0004  ACTION "VIEWDEF.TECA984" OPERATION MODEL_OPERATION_INSERT ACCESS 0 // "Incluir"
ADD OPTION aRotina TITLE STR0005  ACTION "VIEWDEF.TECA984" OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // "Alterar"
ADD OPTION aRotina TITLE STR0006  ACTION "VIEWDEF.TECA984" OPERATION MODEL_OPERATION_DELETE ACCESS 0 // "Excluir"
ADD OPTION aRotina TITLE STR0013  ACTION "VIEWDEF.TECA984" OPERATION 9						ACCESS 0 // "Copiar"

Return(aRotina)

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
@description	Definição do Model
@sample	 		ModelDef()
@param			Nenhum
@return			ExpO: Objeto FwFormModel
@author			Filipe Gonçalves
@since			31/05/2016
@version		P12
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()
Local oModel	:= Nil
Local oStrTWM	:= FWFormStruct(1, "TWM")	// Cabeçalho Facilitador
Local oStruRH 	:= FWFormStruct(1, "TWN")
Local oStruMC 	:= FWFormStruct(1, "TWN")
Local oStruMI 	:= FWFormStruct(1, "TWN")
Local oStruLE 	:= FWFormStruct(1, "TWN")
Local lOrcPrc 	:= GetMv("MV_ORCPRC",,.F.)
Local bCommit 	:= {|oModel| At894Grv( oModel ) }
Local aOnlyRh 	:= { "TWN_FUNCAO", "TWN_DESFUN", "TWN_TURNO", "TWN_DTURNO", "TWN_CARGO", "TWN_DCARGO" }
Local nZ 		:= 1

For nZ := 1 To Len( aOnlyRh )
	oStruMC:RemoveField( aOnlyRh[nZ] )
	oStruMI:RemoveField( aOnlyRh[nZ] )
	oStruLE:RemoveField( aOnlyRh[nZ] )
Next

oStruRH:SetProperty('TWN_DESCRI',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA984","RHDETAIL","B1_DESC","SB1",1, "XFILIAL('SB1')+TWN->TWN_CODPRO") } )
oStruMC:SetProperty('TWN_DESCRI',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA984","MCDETAIL","B1_DESC","SB1",1, "XFILIAL('SB1')+TWN->TWN_CODPRO") } )
oStruMI:SetProperty('TWN_DESCRI',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA984","MIDETAIL","B1_DESC","SB1",1, "XFILIAL('SB1')+TWN->TWN_CODPRO") } )
oStruLE:SetProperty('TWN_DESCRI',MODEL_FIELD_INIT,{|| ATINIPADMVC("TECA984","LEDETAIL","B1_DESC","SB1",1, "XFILIAL('SB1')+TWN->TWN_CODPRO") } )

// Cria o objeto do modelo de dados principal
oModel := MPFormModel():New("TECA984", /*bPreValid*/, /*bPósValid*/, bCommit, /*bCancel*/) 

// Cria a antiga Enchoice do grupo de comunicação
oModel:AddFields("TWMMASTER", /*cOwner*/, oStrTWM) 

// Cria a grid das etapas do grupo de comunicação
oModel:AddGrid("RHDETAIL","TWMMASTER", oStruRH,/*bPreValidacao*/,/*bPosValidacao*/,,, /*bCarga*/) 
If lOrcPrc
	oModel:AddGrid("MCDETAIL","TWMMASTER",oStruMC,/*bPreValidacao*/,/*bPosValidacao*/,,, /*bCarga*/) 
	oModel:AddGrid("MIDETAIL","TWMMASTER",oStruMI,/*bPreValidacao*/,/*bPosValidacao*/,,, /*bCarga*/)
Else
	oModel:AddGrid("MCDETAIL","RHDETAIL", oStruMC,/*bPreValidacao*/,/*bPosValidacao*/,,, /*bCarga*/) 
	oModel:AddGrid("MIDETAIL","RHDETAIL", oStruMI,/*bPreValidacao*/,/*bPosValidacao*/,,, /*bCarga*/)
EndIf 
oModel:AddGrid("LEDETAIL","TWMMASTER",oStruLE,/*bPreValidacao*/,/*bPosValidacao*/,,, /*bCarga*/) 	

//Criação dos relacionamentos
oModel:SetRelation("RHDETAIL", {{"TWN_FILIAL","xFilial('TWN')"}, {"TWN_CODTWM","TWM_CODIGO"}, {"TWN_TPITEM","'1'"} }, TWN->(IndexKey(1)))
If lOrcPrc
	oModel:SetRelation("MCDETAIL", {{"TWN_FILIAL","xFilial('TWN')"}, {"TWN_CODTWM","TWM_CODIGO"}, {"TWN_TPITEM","'2'"} }, TWN->(IndexKey(1)))
	oModel:SetRelation("MIDETAIL", {{"TWN_FILIAL","xFilial('TWN')"}, {"TWN_CODTWM","TWM_CODIGO"}, {"TWN_TPITEM","'3'"} }, TWN->(IndexKey(1)))
Else
	oModel:SetRelation("MCDETAIL", {{"TWN_FILIAL","xFilial('TWN')"}, {"TWN_CODTWM","TWM_CODIGO"},{"TWN_TPITEM","'2'"},{"TWN_ITEMRH","TWN_ITEM"} }, TWN->(IndexKey(1)))
	oModel:SetRelation("MIDETAIL", {{"TWN_FILIAL","xFilial('TWN')"}, {"TWN_CODTWM","TWM_CODIGO"},{"TWN_TPITEM","'3'"},{"TWN_ITEMRH","TWN_ITEM"} }, TWN->(IndexKey(1)))
EndIf
oModel:SetRelation("LEDETAIL", {{"TWN_FILIAL","xFilial('TWN')"}, {"TWN_CODTWM","TWM_CODIGO"}, {"TWN_TPITEM","'4'"}}, TWN->(IndexKey(1)))

//Definição das descrições
oModel:GetModel("RHDETAIL"):SetDescription(STR0007)	// "Recursos Humanos"
oModel:GetModel("MCDETAIL"):SetDescription(STR0008)	// "Material de Consumo"
oModel:GetModel("MIDETAIL"):SetDescription(STR0009)	// "Material de Implantação"
oModel:GetModel("LEDETAIL"):SetDescription(STR0010)	// "Locação de Equipamento"

//Define se modelos são obrigatórios
oModel:GetModel("RHDETAIL"):SetOptional(.T.)
oModel:GetModel("MCDETAIL"):SetOptional(.T.)
oModel:GetModel("MIDETAIL"):SetOptional(.T.)
oModel:GetModel("LEDETAIL"):SetOptional(.T.)
//PE T740MCPO para manipular campos no Modelo
If ExistBlock("T984MCPO")
	ExecBlock("T984MCPO",.F.,.F.,@oModel)
EndIf
oModel:SetActivate( {|oModel| At984Activ( oModel ) } )

Return(oModel)

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
@description	Definição da View
@sample	 		ViewDef()
@param			Nenhum
@return			ExpO	Objeto FwFormView 
@author			Filipe Gonçalves 
@since			31/05/2016       
@version		P12   
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()
Local oView		:= Nil						// Interface de visualização construída	
Local oModel	:= ModelDef()				// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
Local oStrTWM   := FWFormStruct(2, "TWM")   // Cria a estrutura a ser usada na View 
Local oStrRH 	:= FWFormStruct(2, "TWN", {|cCampo| !AllTrim(cCampo)$ "TWN_CODTWM|TWN_TPITEM|TWN_TES"})	
Local oStrMC 	:= FWFormStruct(2, "TWN", {|cCampo| !AllTrim(cCampo)$ "TWN_CODTWM|TWN_TPITEM|TWN_FUNCAO|TWN_DESFUN|TWN_TURNO|TWN_DTURNO|TWN_CARGO|TWN_DCARGO"})
Local oStrMI 	:= FWFormStruct(2, "TWN", {|cCampo| !AllTrim(cCampo)$ "TWN_CODTWM|TWN_TPITEM|TWN_FUNCAO|TWN_DESFUN|TWN_TURNO|TWN_DTURNO|TWN_CARGO|TWN_DCARGO"})
Local oStrLE 	:= FWFormStruct(2, "TWN", {|cCampo| !AllTrim(cCampo)$ "TWN_CODTWM|TWN_TPITEM|TWN_FUNCAO|TWN_DESFUN|TWN_TURNO|TWN_DTURNO|TWN_CARGO|TWN_DCARGO"})

oStrRh:RemoveField("TWN_ITEMRH")
oStrMC:RemoveField("TWN_ITEMRH")
oStrMI:RemoveField("TWN_ITEMRH")
oStrLE:RemoveField("TWN_ITEMRH")

If GetMv('MV_ORCPRC',,.F.)
	oStrRH:RemoveField('TWN_VLUNIT')		
EndIf
oStrLE:RemoveField('TWN_VLUNIT')

// Cria o objeto de View
oView	:= FWFormView():New()

// Define qual modelo de dados será utilizado
oView:SetModel(oModel)

// Adiciona as visões na tela
oView:CreateHorizontalBox("TOP",  30)
oView:CreateHorizontalBox("DOWN", 70)

oView:AddField("VIEW_TWM", oStrTWM, "TWMMASTER")		// Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)
oView:SetOwnerView("VIEW_TWM", "TOP")					// Relaciona o identificador (ID) da View com o "box" para sua exibição

oView:CreateFolder("ABAS", "DOWN")						// Cria Folders na view

// Cria as grids para o modelo
oView:AddGrid("VIEW_RH", oStrRH, "RHDETAIL") 											
oView:AddGrid("VIEW_MC", oStrMC, "MCDETAIL") 											
oView:AddGrid("VIEW_MI", oStrMI, "MIDETAIL") 											
oView:AddGrid("VIEW_LE", oStrLE, "LEDETAIL")

// Cria Folders na View
oView:AddSheet("ABAS", "DOWN_RHDETAIL", STR0007)
oView:AddSheet("ABAS", "DOWN_MCDETAIL", STR0008)
oView:AddSheet("ABAS", "DOWN_MIDETAIL", STR0009)
oView:AddSheet("ABAS", "DOWN_LEDETAIL", STR0010)

// Define a área da Aba								
oView:CreateHorizontalBox("ID_DOWN_RHDETAIL", 100,,, "ABAS", "DOWN_RHDETAIL")
oView:CreateHorizontalBox("ID_DOWN_MCDETAIL", 100,,, "ABAS", "DOWN_MCDETAIL")
oView:CreateHorizontalBox("ID_DOWN_MIDETAIL", 100,,, "ABAS", "DOWN_MIDETAIL")
oView:CreateHorizontalBox("ID_DOWN_LEDETAIL", 100,,, "ABAS", "DOWN_LEDETAIL")

// Relaciona o identificador (ID) da View com o "box" para sua exibição
oView:SetOwnerView("VIEW_RH", "ID_DOWN_RHDETAIL") 										
oView:SetOwnerView("VIEW_MC", "ID_DOWN_MCDETAIL")
oView:SetOwnerView("VIEW_MI", "ID_DOWN_MIDETAIL")
oView:SetOwnerView("VIEW_LE", "ID_DOWN_LEDETAIL")

// Campos incrementais
oView:AddIncrementField('VIEW_RH' , 'TWN_ITEM' )
oView:AddIncrementField('VIEW_MC' , 'TWN_ITEM' )
oView:AddIncrementField('VIEW_MI' , 'TWN_ITEM' )
oView:AddIncrementField('VIEW_LE' , 'TWN_ITEM' )

// Identificação (Nomeação) da VIEW
oView:SetDescription(STR0001) // "Facilitador"
//PE T740VCPO para manipular campos na View
If ExistBlock("T984VCPO")
	ExecBlock("T984VCPO",.F.,.F.,{@oStrRH, @oStrMC, @oStrMI, @oStrLE})
EndIf


Return(oView)

//------------------------------------------------------------------------------
/*/{Protheus.doc} AT984ValTp
@description	Validação do Tipo de Produto conforme a aba atual
@sample	 		AT984ValTp()
@param			Nenhum
@return			lRet	Logico 
@author			Joni Lima do Carmo 
@since			03/08/2016       
@version		P12   
/*/
//------------------------------------------------------------------------------
Function AT984ValTp()

Local aArea	 	:= GetArea()
Local aAreaSB1	:= SB1->(GetArea())
Local aAreaSB5	:= SB5->(GetArea())
Local lRet			:= .T.
Local oView		:= FWViewActive()
Local oModel		:= FwModelActive()
Local cNMdl		:= ''
Local oMdDet		:= nil

If ValType(oView) == 'O' .and. FunName() == 'TECA984'

		//Case para Pegar o Modelo 
	DO CASE
		CASE oView:GetFolderActive("ABAS", 2)[1] == 1 // Aba RH
			cNMdl := 'RHDETAIL'
		CASE oView:GetFolderActive("ABAS", 2)[1] == 2 // Aba MC
			cNMdl := 'MCDETAIL'
		CASE oView:GetFolderActive("ABAS", 2)[1] == 3 // Aba MI
			cNMdl := 'MIDETAIL'
		CASE oView:GetFolderActive("ABAS", 2)[1] == 4 // Aba LE
			cNMdl := 'LEDETAIL'
	ENDCASE

	oMdDet := oModel:GetModel(cNMdl)

	dbSelectArea('SB5')
	SB5->(dbSetOrder(1))//B5_FILIAL+B5_COD

	If SB5->(dbSeek(xFilial('SB5') + oMdDet:GetValue('TWN_CODPRO')))

		//Case para fazer a validação Baseado na SB5
		DO CASE
			CASE oView:GetFolderActive("ABAS", 2)[1] == 1 // Aba RH
				lRet := SB5->B5_TPISERV = '4'
				If !lRet
					Help( ' ', 1, 'TECA984', , STR0014, 1, 0 )
				EndIf
			CASE oView:GetFolderActive("ABAS", 2)[1] == 2 // Aba MC
				lRet := SB5->B5_TPISERV = '5' .and. SB5->B5_GSMC= '1'
				If !lRet
					Help( ' ', 1, 'TECA984', , STR0015, 1, 0 )
				EndIf
			CASE oView:GetFolderActive("ABAS", 2)[1] == 3 // Aba MI
				lRet := SB5->B5_TPISERV = '5' .and. SB5->B5_GSMI= '1'
				If !lRet
					Help( ' ', 1, 'TECA984', , STR0016, 1, 0 )
				EndIf
			CASE oView:GetFolderActive("ABAS", 2)[1] == 4 // Aba LE
				lRet := SB5->B5_TPISERV = '5' .and. SB5->B5_GSLE= '1'
				If !lRet
					Help( ' ', 1, 'TECA984', , STR0017, 1, 0 )
				EndIf
			OTHERWISE
				lRet:= .F.
		ENDCASE

	Else
		lRet := .F.
		Help( ' ', 1, 'TECA984', ,STR0018, 1, 0 )
	EndIf
EndIf

RestArea(aAreaSB5)
RestArea(aAreaSB1)
RestArea(aArea)

Return lRet

/*/{Protheus.doc} At894Grv
@description	Grava os dados manualmente para conseguir registrar um modelo 2 entre grids
@param			oModel, Objeto FwFormModel/MpFormModel, modelo de dados completo da rotina
@return			Logico, determina se conseguiu realizar a gravação dos dados ou não
@author			Inovação Gestão de Serviços 
@since			28/10/2016
@version		P12
/*/
Static Function At894Grv( oModel )
Local lRet := .T.
Local nI := 1
Local aCampos := {}
Local nPos := 0
Local nTotCampos := 0
Local lOrcPrc := GetMv("MV_ORCPRC",,.F.)
Local oMdlCab := oModel:GetModel("TWMMASTER")
Local oMdlRH := oModel:GetModel("RHDETAIL")
Local oMdlMC := oModel:GetModel("MCDETAIL")
Local oMdlMI := oModel:GetModel("MIDETAIL")
Local oMdlLE := oModel:GetModel("LEDETAIL")
Local lNew   := .F.
Local cItemRH := ""
Local nSaveSx8Len := GetSx8Len()
Local cQryDel := ""

If oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. ;
	oModel:GetOperation() == MODEL_OPERATION_UPDATE
	
	// grava o cabeçalho
	aCampos := oMdlCab:GetStruct():GetFields()
	nTotCampos := Len(aCampos)
	If oModel:GetOperation() == MODEL_OPERATION_INSERT
		lNew := .T.
	Else
		lNew := .F.
		TWM->( DbSeek( xFilial("TWM")+oMdlCab:GetValue("TWM_CODIGO") ) )	
	EndIf
	
	Begin Transaction
	
	Reclock("TWM", lNew )
		For nPos := 1 To nTotCampos
			TWM->( FieldPut( FieldPos( aCampos[nPos,MODEL_FIELD_IDFIELD] ), oMdlCab:GetValue(aCampos[nPos,MODEL_FIELD_IDFIELD]) ) )
		Next nPos
		TWM->TWM_FILIAL := xFilial("TWM")
	TWM->(MsUnlock())
	
	// grava os produtos de recursos humanos
	aCampos := oMdlRH:GetStruct():GetFields()
	nTotCampos := Len(aCampos)
	For nI := 1 To oMdlRH:Length()
		oMdlRH:GoLine(nI)
		If !Empty( oMdlRH:GetValue("TWN_CODPRO") )
			If oMdlRH:IsDeleted()
				If !oMdlRH:IsInserted()
					
					TWN->( DbGoTo( oMdlRH:GetDataId(nI) ) )
					Reclock("TWN",.F.)
					TWN->(DbDelete())
					TWN->(MsUnlock())
					
					oMdlMC:GoLine(1)
					oMdlMI:GoLine(1)
					
					//  grava os materiais de consumo vinculados ao recurso humano			
					If !lOrcPrc .And. !Empty( oMdlMC:GetValue("TWN_CODPRO") )
						lRet := At894GrvMt(oMdlMC, "2", .T.)
					EndIf
					
					//  grava os materiais de implantação vinculados ao recurso humano
					If !lOrcPrc .And. !Empty( oMdlMI:GetValue("TWN_CODPRO") )
						lRet := At894GrvMt(oMdlMI, "3", .T.)
					EndIf
					
				EndIf
			Else
				oMdlMC:GoLine(1)
				oMdlMI:GoLine(1)
				If oMdlRH:IsInserted() .Or. oMdlRH:GetDataId(nI) == 0
					lNew := .T.
				Else
					lNew := .F.
					TWN->( DbGoTo( oMdlRH:GetDataId(nI) ) )
				EndIf
				
				Reclock("TWN", lNew )
					For nPos := 1 To nTotCampos
						TWN->( FieldPut( FieldPos( aCampos[nPos,MODEL_FIELD_IDFIELD] ), oMdlRH:GetValue(aCampos[nPos,MODEL_FIELD_IDFIELD]) ) )
					Next nPos
					TWN->TWN_FILIAL := xFilial("TWN")
					TWN->TWN_TPITEM := "1"
					TWN->TWN_CODTWM := TWM->TWM_CODIGO
				TWN->(MsUnlock())
				cItemRH := TWN->TWN_ITEM
				//  grava os materiais de consumo vinculados ao recurso humano			
				If !lOrcPrc .And. !Empty( oMdlMC:GetValue("TWN_CODPRO") )
					lRet := At894GrvMt(oMdlMC, "2", .F., .T., cItemRH)
				EndIf
				
				//  grava os materiais de implantação vinculados ao recurso humano
				If !lOrcPrc .And. !Empty( oMdlMI:GetValue("TWN_CODPRO") )
					lRet := At894GrvMt(oMdlMI, "3", .F., .T., cItemRH)
				EndIf
				
			EndIf
		EndIf
	Next nI
	
	If lOrcPrc
		// chama a gravação dos materiais quando é orçamento com precificação 
		// e não fica vinculado aos itens de Rh
		lRet := At894GrvMt( oMdlMC, "2" )
		lRet := At894GrvMt( oMdlMI, "3" )
	EndIf
	
	// grava os produtos de locação de equipamentos
	aCampos := oMdlLE:GetStruct():GetFields()
	nTotCampos := Len(aCampos)
	For nI := 1 To oMdlLE:Length()
		oMdlLE:GoLine(nI)
		If !Empty( oMdlLE:GetValue("TWN_CODPRO") )
			If oMdlLE:IsDeleted()
				If !oMdlLE:IsInserted()
					
					TWN->( DbGoTo( oMdlLE:GetDataId(nI) ) )
					Reclock("TWN",.F.)
					TWN->(DbDelete())
					TWN->(MsUnlock())
				EndIf
			Else
				oMdlMC:GoLine(1)
				oMdlMI:GoLine(1)
				If oMdlLE:IsInserted() .Or.  oMdlLE:GetDataId(nI) == 0 
					lNew := .T.
				Else
					lNew := .F.
					TWN->( DbGoTo( oMdlLE:GetDataId(nI) ) )
				EndIf
				
				Reclock("TWN", lNew )
					For nPos := 1 To nTotCampos
						TWN->( FieldPut( FieldPos( aCampos[nPos,MODEL_FIELD_IDFIELD] ), oMdlLE:GetValue(aCampos[nPos,MODEL_FIELD_IDFIELD]) ) )
					Next nPos
					TWN->TWN_FILIAL := xFilial("TWN")
					TWN->TWN_TPITEM := "4"
					TWN->TWN_CODTWM := TWM->TWM_CODIGO
				TWN->(MsUnlock())
			EndIf
		EndIf
	Next nI

	If lRet
		ConfirmSX8()
	Else
		RollBackSX8()
	EndIf

	If !lRet
		DisarmTransaction()
	EndIf
	
	End Transaction

ElseIf oModel:GetOperation() == MODEL_OPERATION_DELETE

	// exclusão dos registros 
	If TWM->( DbSeek( xFilial("TWM")+oMdlCab:GetValue("TWM_CODIGO") ) )
	
		cQryDel := GetNextAlias()
		
		BeginSQL Alias cQryDel
			
			SELECT TWN.R_E_C_N_O_ TWNRECNO 
			FROM %Table:TWN% TWN
			WHERE TWN_FILIAL = %xFilial:TWN% 
				AND TWN_CODTWM = %Exp:TWM->TWM_CODIGO%
				AND TWN.%NotDel%
		EndSQL
		
		Begin Transaction
		
		// percorre todos os registros da TWN que estão relacionados com o facilitador
		While (cQryDel)->(!EOF())
			
			TWN->( DbGoTo( (cQryDel)->TWNRECNO ) )
			
			Reclock("TWN", .F.)
				TWN->( DbDelete() )
			TWN->( MsUnlock() )
			
			(cQryDel)->(DbSkip())
		End
		
		(cQryDel)->( DbCloseArea() )
		
		Reclock("TWM",.F.)
			TWM->( DbDelete() )
		TWM->( MsUnlock() )
		
		End Transaction
	EndIf
EndIf

Return lRet
//------------------------------------------------------------------------------

/*/{Protheus.doc} At894GrvMt
@description	Grava os dados na tabela TWN dos itens que são materiais para o orçamento
@author			Inovação Gestão de Serviços 
@since			28/10/2016
@version		P12
@param			oModel, Objeto FwFormGridModel, modelo de dados com a lista de materiais a ser gravada
@param			cTipo, Caracter, Tipo "2" ou "3" indicando se é material de consumo ou implantação respectivamente
@param			lExclui, Lógico, Determina se todos os registros devem ser excluídos ou se deverá avaliar linha a linha do grid
@param 			lRh, Lógico, Determina se a lista de materiais está vinculada ao RH ou não
@param 			cItemRh, Caracter, Determina se a lista de materiais está vinculada ao RH ou não
@return			Logico, determina se conseguiu gravar os dados ou não
//------------------------------------------------------------------------------
/*/
Static Function At894GrvMt( oMdlGridMat, cTipo, lExclui, lRh, cItemRh )
Local lRet := .T.
Local nX := 1
Local aCampos := {}
Local nTotCampos := 0
Local lNew := .F.
Local nPos := 0

Default lExclui := .F.
Default lRh := .F.
Default cItemRh := ""
// verifica se recebeu o parâmetro com o item do RH
lRh := lRh .And. !Empty(cItemRh)

If lExclui
	For nX := 1 To oMdlGridMat:Length()
		If !oMdlGridMat:IsInserted()
			
			TWN->( DbGoTo( oMdlGridMat:GetDataId(nX) ) )
			Reclock("TWN",.F.)
			TWN->(DbDelete())
			TWN->(MsUnlock())
		EndIf
	Next nX
Else
	// grava os produtos de locação de equipamentos
	aCampos := oMdlGridMat:GetStruct():GetFields()
	nTotCampos := Len(aCampos)
	
	For nX := 1 To oMdlGridMat:Length()
		oMdlGridMat:GoLine(nX)
		If !Empty( oMdlGridMat:GetValue("TWN_CODPRO") )
			If oMdlGridMat:IsDeleted()
				If !oMdlGridMat:IsInserted()
					
					TWN->( DbGoTo( oMdlGridMat:GetDataId(nX) ) )
					Reclock("TWN",.F.)
					TWN->(DbDelete())
					TWN->(MsUnlock())
				EndIf
			Else
				If oMdlGridMat:IsInserted() .Or. oMdlGridMat:GetDataId(nX) == 0
					lNew := .T.
				Else
					lNew := .F.
					TWN->( DbGoTo( oMdlGridMat:GetDataId(nX) ) )
				EndIf
				
				Reclock("TWN", lNew )
					For nPos := 1 To nTotCampos
						TWN->( FieldPut( FieldPos( aCampos[nPos,MODEL_FIELD_IDFIELD] ), oMdlGridMat:GetValue(aCampos[nPos,MODEL_FIELD_IDFIELD]) ) )
					Next nPos
					TWN->TWN_FILIAL := xFilial("TWN")
					TWN->TWN_TPITEM := cTipo
					TWN->TWN_CODTWM := TWM->TWM_CODIGO
					
					TWN->TWN_ITEMRH := cItemRh
					
				TWN->(MsUnlock())
			EndIf
		EndIf
	Next nX
EndIf

Return lRet

/*/{Protheus.doc} At984IsFac
@description 	Avalia se determinado item pertence a um facilitador
@author 		josimar.assuncao
@return 		Lógico, determina se o item pertence ao facilitador posicionado
@since			23.03.2017
@version		P12
/*/
Function At984IsFac(cIdMdlGrd, cCodTWM, cCodRHPai)
Local lRet 			:= .F. 
Local lQry 			:= .F.
Local cQryTmp 		:= ""
Local cItemEval 	:= ""
Local cTpItem 		:= ""
Local aArea 		:= GetArea()
Local aAreaTWM 		:= TWM->(GetArea())
Local aAreaTWN 		:= TWN->(GetArea())

If cIdMdlGrd == "RHDETAIL" .And. TWN->TWN_TPITEM == "1" .Or. ;
	cIdMdlGrd == "MIDETAIL" .And. TWN->TWN_TPITEM == "3" .Or. ;
	cIdMdlGrd == "MCDETAIL" .And. TWN->TWN_TPITEM == "2" .Or. ;
	cIdMdlGrd == "LEDETAIL" .And. TWN->TWN_TPITEM == "4" 

	lQry := .T.

	If cIdMdlGrd $ "RHDETAIL/LEDETAIL"
		cCodRHPai := Space( Len( TWN->TWN_ITEMRH ) )
	EndIf
	cItemEval := TWN->TWN_ITEM
	cTpItem := TWN->TWN_TPITEM
EndIf

If lQry
	cQryTmp := GetNextAlias()
	BeginSql Alias cQryTmp
		SELECT TWN_ITEM
		FROM %Table:TWN% TWN
			INNER JOIN %Table:TWM% TWM ON TWM_FILIAL = %xFilial:TWM%
									AND TWM_CODIGO = TWN_CODTWM
									AND TWM.%NotDel%
		WHERE TWN_FILIAL = %xFilial:TWN%
			AND TWN_CODTWM = %Exp:cCodTWM%
			AND TWN_ITEM = %Exp:cItemEval%
			AND TWN_TPITEM = %Exp:cTpItem%
			AND TWN_ITEMRH = %Exp:cCodRHPai%
			AND TWN.%NotDel%
	EndSQL
	lRet := (cQryTmp)->(!EOF())
	(cQryTmp)->(DbCloseArea())
EndIf

RestArea(aAreaTWN)
RestArea(aAreaTWM)
RestArea(aArea)

Return lRet

/*/{Protheus.doc} At984Activ
@description 	Bloco para atualização do modelo de dados após a ativação dele
@author 		josimar.assuncao
@since			24.03.2017
@version		P12
/*/
Static Function At984Activ( oModel )
Local nI 			:= 1
Local nLinhas 		:= 1
Local oMdlGrd 		:= Nil
Local aGrds 		:= { "RHDETAIL", "MIDETAIL", "MCDETAIL", "RHDETAIL" }
Local cAux 			:= ""
Local cTempContent 	:= ""

If oModel:GetOperation() <> MODEL_OPERATION_DELETE
	// passa pelos grids para verificar se existe descrição de produto que não foi carregada
	For nI := 1 To Len( aGrds )
		oMdlGrd := oModel:GetModel( aGrds[nI] )
		For nLinhas := 1 To oMdlGrd:Length()
			oMdlGrd:GoLine( nLinhas )
			cAux := oMdlGrd:GetValue("TWN_CODPRO")
			If Empty(oMdlGrd:GetValue("TWN_DESCRI")) .And. !Empty(cAux)
				cTempContent := Posicione("SB1", 1, xFilial("SB1")+cAux, "B1_DESC")
				oMdlGrd:LoadValue( "TWN_DESCRI", cTempContent )
			EndIf
		Next nLinhas
		oMdlGrd:GoLine(1)
	Next nI
EndIf

Return 