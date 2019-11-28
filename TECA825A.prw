#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'FWBROWSE.CH'
#INCLUDE 'TECA825A.CH'

STATIC nLinMark    := 0
STATIC cKeyTFI     := ''
STATIC cPropFiltro := ''
STATIC cPRevFiltro := ''

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
	Definição do modelo de dados para a seleção do item da tfi que terá a reserva
@sample 	ModelDef()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel
Local oStr1:= FWFormStruct(1,'TFI',{|cCpo|Alltrim(cCpo)$'TFI_FILIAL+TFI_COD'})
Local oStr2:= FWFormStruct(1,'TFI')

//------------------------------------------------------
//
nLinMark  := 0
cKeyTFI   := ''
//
//------------------------------------------------------

// Adiciona o marcador de seleção dos equipamentos
oStr2:AddField( STR0001, ; // cTitle // 'Mark'
				STR0001, ; // cToolTip // 'Mark'
				'TFI_FLAG', ; // cIdField
				'L', ; // cTipo
				1, ; // nTamanho
				0, ; // nDecimal
				{|oMdl, cCampo, xValueNew, nLine, xValueOld| vldMark(oMdl, cCampo, xValueNew, nLine, xValueOld) }, ; // bValid
				{|| .T.}, ; // bWhen
				Nil, ; // aValues
				Nil, ; // lObrigat
				Nil, ; // bInit
				Nil, ; // lKey
				.F., ; // lNoUpd
				.T. ) // lVirtual

oStr2:RemoveField("TFI_CALCMD")

oModel := MPFormModel():New('TECA825A',,{|oMdl| At825ATdOk(oMdl) },{|oMdl| At825ASave(oMdl)})
oModel:SetDescription(STR0002)  // 'Item de Locação'

oModel:addFields('CAB',,oStr1)

oStr1:SetProperty('*', MODEL_FIELD_OBRIGAT, Nil )
oStr2:SetProperty('*', MODEL_FIELD_OBRIGAT, Nil )

oStr1:SetProperty('TFI_COD', MODEL_FIELD_INIT, Nil )
oStr2:SetProperty('TFI_COD', MODEL_FIELD_INIT, Nil )

oStr2:AddField(STR0001,STR0001, 'TFI_MARK', 'C', 1, 0, , , {}, .F.,FWBuildFeature( STRUCT_FEATURE_INIPAD, "{||.F.}") , .F., .F., .T., , )  // 'Mark' ### 'Mark' 
oModel:addGrid('ITENS','CAB',oStr2,,,,,{|oMdlgrid| SelecTFI(oMdlgrid) })

oModel:getModel('CAB'):SetOnlyQuery(.T.)
oModel:getModel('CAB'):SetDescription('Item')

oModel:getModel('ITENS'):SetOnlyQuery(.T.)
oModel:getModel('ITENS'):SetDescription(STR0002)  // 'Itens de Locação'

oModel:getModel('ITENS'):SetNoInsertLine(.T.)
oModel:getModel('ITENS'):SetNoDeleteLine(.T.)

Return oModel

//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
	Definição da interface para a seleção do item da tfi que terá a reserva
@sample 	ViewDef()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oView  := Nil
Local oModel := ModelDef()
Local oStr1  := FWFormStruct(2, 'TFI')

oView := FWFormView():New()

oView:SetModel(oModel)

oStr1:SetProperty('*', MVC_VIEW_CANCHANGE, .F. )

oStr1:AddField('TFI_FLAG',;				// cIdField
               '01',;					// cOrdem
               STR0001,;					// cTitulo // 'Mark'
               STR0001,;					// cDescric // 'Mark'
               {STR0004, STR0005},;	// aHelp : 'Marque os itens que deseja realizar  ' ### 'a reserva dos equipamentos '    
               'CHECK',;					// cType
               '@!',;					// cPicture
               Nil,;						// nPictVar
               Nil,;						// Consulta F3
               .T.,;						// lCanChange
               '01',;					// cFolder
               Nil,;						// cGroup
               Nil,;						// aComboValues
               Nil,;						// nMaxLenCombo
               Nil,;						// cIniBrow
               .T.,;						// lVirtual
               Nil )						// cPictVar

oStr1:RemoveField("TFI_CALCMD")

oView:AddGrid('FORM1' , oStr1,'ITENS')
oView:CreateHorizontalBox( 'BOXFORM1', 100)
oView:SetOwnerView('FORM1','BOXFORM1')

oView:SetCloseOnOK({||.T.})

oView:SetFieldAction( 'TFI_FLAG', { |oView, cIDView, cField, xValue| oView:Refresh() } )

oView:showUpdateMsg(.F.)
Return oView


//------------------------------------------------------------------------------
/*/{Protheus.doc} VldMark
	valida a marcação do registro e elimina uma marcação anterior
@sample 	VldMark()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function VldMark( oMdlBase, cCampo, xValueNew, nLine, xValueOld )

Local nLinAtual   := 0
Local lRet        := !Empty(oMdlBase:GetValue('TFI_COD'))

If lRet .And. xValueNew
	nLinAtual   := oMdlBase:GetLine()
	
	If nLinAtual <> nLinMark
	
		If nLinMark <> 0
			oMdlBase:GoLine( nLinMark )
			oMdlBase:SetValue('TFI_FLAG', .F. ) // desmarca o item anterior
		EndIf
		
		oMdlBase:GoLine( nLinAtual )  // retorna ao item posicionado antes
		
	EndIf
	
	nLinMark := nLinAtual
Else
	nLinMark := 0
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825ASave
	Salva a chave do registro da tfi que foi selecionada
@sample 	At825ASave()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At825ASave(oMdl)

Local oMdlItens := oMdl:GetModel('ITENS')

cKeyTFI := oMdlItens:GetValue('TFI_FILIAL')+oMdlItens:GetValue('TFI_COD')

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825AGetKey
	Devolve a chave do registro da tfi que foi selecionada
@sample 	At825AGetKey()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825AGetKey()

Return cKeyTFI

//------------------------------------------------------------------------------
/*/{Protheus.doc} SelecTFI
	Função que realiza a carga dos dados no grid dos itens de locação
@sample 	SelecTFI()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function SelecTFI(oMdlGrid)

Local aRet    	  := {}
Local cTmpQry     := GetNextAlias()
Local cExpCliPros := "%%"
Local cExpExtProp := "%%"
Local cExpProd    := "%%"
Local cEspContrat := ""
Local cEspReserva := Space(TamSX3('TFI_RESERV')[1])
Local cEspPropost := Space(TamSX3('AD1_PROPOS')[1])
Local lSrvExt     := If(ValType(MV_PAR06) <> "U",MV_PAR06 == 1,.F.)

//-----------------------------------------
//   Verifica se está sendo chamado direto da janela de proposta comercial
cExpExtProp := If( !Empty(cPropFiltro) .And. !Empty(cPRevFiltro), ;
						 "% AND ADY.ADY_PROPOS='"+cPropFiltro+"' AND ADY.ADY_PREVIS='"+cPRevFiltro+"' %" , ;
						 "%%" )
//-----------------------------------------
//  Avalia se passou pela janela do pergunte
If At825Perg()

	cExpProd    := If( !Empty(mv_par01) , ;
							"% AND TFI.TFI_PRODUT='"+mv_par01+"' %" ,;
							"%%" )

	If !Empty(mv_par02) .And. !Empty(mv_par03)
		If lSrvExt
			cExpCliPros := "% AND TFJ.TFJ_CODENT='"+mv_par02+"' AND TFJ.TFJ_LOJA='"+mv_par03+"' %"
		Else
			cExpCliPros := "% AND AD1.AD1_CODCLI='"+mv_par02+"' AND AD1.AD1_LOJCLI='"+mv_par03+"' %"
		EndIf
	ElseIf !Empty(mv_par04) .And. !Empty(mv_par05)
		cExpCliPros := "% AND AD1.AD1_PROSPE='"+mv_par02+"' AND AD1.AD1_LOJPRO='"+mv_par03+"' %"
	Else
		cExpCliPros := "%%"
	EndIf

EndIf

//-----------------------------------------
//  Avalia se considera oportunidades com contrato ja gerado.
If SuperGetMV("MV_TECRESC",,.F.)
	cEspContrat := "% AND TFI.TFI_SEPARA <> '1' %"												//Orçamentos com contrato e nao separados.
Else
	cEspContrat := "% AND TFI.TFI_CONTRT = '" + Space(TamSX3('TFI_CONTRT')[1]) + "' %"		//Somente orçamentos sem contrato
EndIf



//---------------------------------------------------
//   Executa o tratamento para ordenar pelo Recno()
// os registros a serem exibidos no grid da TFI
If lSrvExt
	// Caso seja um orçamento de serviços extra, não haverá uma oportunidade (AD1) vinculada ao orçamento de serviços.
BeginSql Alias cTmpQry
	
		COLUMN TFI_PERINI AS DATE
		COLUMN TFI_PERFIM AS DATE
	
		SELECT  TFI.* ,
		        SB1.B1_DESC TFI_DESCRI ,
		        SB1.B1_UM TFI_UM
		FROM %Table:TFJ% TFJ
			INNER JOIN %Table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%   AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO AND TFL.%NotDel%
			INNER JOIN %Table:TFI% TFI ON TFI.TFI_FILIAL = %xFilial:TFI%   AND TFI.%NotDel% AND TFI.TFI_CODPAI = TFL.TFL_CODIGO
					%Exp:cExpProd% AND TFI.TFI_PERINI   >= %Exp:dDataBase% AND TFI.TFI_RESERV = %Exp:cEspReserva%
			INNER JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL  = %xFilial:SB1%   AND SB1.B1_COD     = TFI.TFI_PRODUT AND SB1.%NotDel%
		WHERE
			TFJ.TFJ_FILIAL = %xFilial:TFJ% AND TFJ.%NotDel%
			AND TFJ.TFJ_SRVEXT = '1'
				%Exp:cExpCliPros%
		
//		UNION ALL
	EndSql
Else
	BeginSql Alias cTmpQry

	COLUMN TFI_PERINI AS DATE
	COLUMN TFI_PERFIM AS DATE

	SELECT  TFI.* ,
	        SB1.B1_DESC TFI_DESCRI ,
	        SB1.B1_UM TFI_UM
	FROM %Table:AD1% AD1
		INNER JOIN %Table:ADY% ADY ON ADY.ADY_FILIAL = %xFilial:ADY% 
			AND ADY.ADY_OPORTU = AD1.AD1_NROPOR 
			AND ADY.ADY_REVISA = AD1.AD1_REVISA 
			AND ADY.%NotDel% 
			AND AD1.AD1_PROPOS = %Exp:cEspPropost%
		INNER JOIN %Table:TFJ% TFJ ON TFJ.TFJ_FILIAL = %xFilial:TFJ% 
			AND TFJ.TFJ_PROPOS = ADY.ADY_PROPOS 
			AND TFJ.TFJ_PREVIS = ADY.ADY_PREVIS
								AND TFJ.%NotDel%
		INNER JOIN %Table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%  
			AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO 
			AND TFL.%NotDel%
		INNER JOIN %Table:TFI% TFI ON TFI.TFI_FILIAL = %xFilial:TFI%   
			AND TFI.%NotDel%
			%Exp:cEspContrat% 
			AND TFI.TFI_CODPAI = TFL.TFL_CODIGO
			%Exp:cExpProd% 
			AND TFI.TFI_PERINI   >= %Exp:dDataBase% 
			AND TFI.TFI_RESERV = %Exp:cEspReserva%
		INNER JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL  = %xFilial:SB1%   
			AND SB1.B1_COD     = TFI.TFI_PRODUT 
			AND SB1.%NotDel%
	WHERE
		AD1.AD1_FILIAL = %xFilial:AD1% 
			AND AD1.%NotDel%
			%Exp:cExpExtProp% 
		AND AD1.AD1_STATUS = '1'
			%Exp:cExpCliPros%
	
	UNION ALL
	
	SELECT  TFI.* ,
	        SB1.B1_DESC TFI_DESCRI ,
	        SB1.B1_UM TFI_UM
	FROM %Table:AD1% AD1
		INNER JOIN %Table:ADY% ADY ON ADY.ADY_FILIAL = %xFilial:ADY% 
			AND ADY.ADY_PROPOS = AD1.AD1_PROPOS 
			AND ADY.%NotDel%
		INNER JOIN %Table:TFJ% TFJ ON TFJ.TFJ_FILIAL = %xFilial:TFJ% 
			AND TFJ.TFJ_PROPOS = ADY.ADY_PROPOS 
			AND TFJ.TFJ_PREVIS = ADY.ADY_PREVIS
								AND TFJ.%NotDel%
		INNER JOIN %Table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%   
			AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO 
			AND TFL.%NotDel%
		INNER JOIN %Table:TFI% TFI ON TFI.TFI_FILIAL = %xFilial:TFI%   			 
			AND TFI.%NotDel%
			%Exp:cEspContrat% 
			AND TFI.TFI_CODPAI = TFL.TFL_CODIGO
			%Exp:cExpProd% 
			AND TFI.TFI_PERINI >= %Exp:dDataBase% 
			AND TFI.TFI_RESERV = %Exp:cEspReserva%
		INNER JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL  = %xFilial:SB1%   
			AND SB1.B1_COD     = TFI.TFI_PRODUT 
			AND SB1.%NotDel%
	WHERE
		AD1.AD1_FILIAL = %xFilial:AD1% 
			AND AD1.%NotDel% 
			%Exp:cExpExtProp% 
		AND AD1.AD1_STATUS = '9'
			%Exp:cExpCliPros%
	
	EndSql
EndIf

aRet := FwLoadByAlias( oMdlGrid, cTmpQry )

(cTmpQry)->(DbCloseArea())

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825AProp
	Captura a proposta e revisão que precisam ser filtradas
@sample 	At825AProp()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825AProp( cProp, cPRev )

cPropFiltro := cProp
cPRevFiltro := cPRev

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At825ATdOk
	Valida a seleção de pelo menos 1 item para realizar a reserva
@sample 	At825ATdOk()
@since		11/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At825ATdOk(oMdl)

Local lRet := nLinMark <> 0

If !lRet
	Help(,,'AT825ASEL',,STR0006,1,0)  // 'Não foi selecionado item para a reserva'
EndIf

Return lRet