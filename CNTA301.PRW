#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "CNTA301.CH"
#INCLUDE "GCTXDEF.CH"

// -- Declaração de Variáveis Estáticas
Static cTipRevisa	:= ''
Static cAprTipRev	:= ''

//-------------------------------------------------------------------
/*{Protheus.doc} CNTA301
Programa de manutenção de Contratos - Venda

@author Leandro.Moura
@since 23/09/2013
@version P11.90
*/
//-------------------------------------------------------------------
Function CNTA301()
Return
//-------------------------------------------------------------------
/*{Protheus.doc} ViewDef
Rotina para montagem da view da manutenção de contratos - Tipo Venda

@author Leandro.Moura
@since 23/09/2013
@version P11.90
*/
//-------------------------------------------------------------------
Static Function ViewDef()
Local oModel	:= FWLoadModel("CNTA301")
Local oView		:= FWFormView():New()

//- Listagem de campos para cada modelo (Finalizar string com '|')
Local cCampoCN8	:= "CN8_CONTRA|CN8_REVISA|CN8_FORNEC|CN8_LOJA|CN8_NOME|"
Local cCampoCN9	:= "CN9_VLREAJ|CN9_NUMTIT|CN9_VLMEAC|CN9_TXADM|CN9_FORMA|CN9_DTENTR|CN9_LOCENT|CN9_CODENT|CN9_DESLOC|CN9_DESFIN|CN9_CONTFI|CN9_DTINPR|CN9_PERPRO|CN9_UNIPRO|CN9_VLRPRO|CN9_DTINCP|CN9_FILCTR|CN9_MODORJ|CN9_CODCLA|CN9_CODJUS|CN9_CODOBJ|CN9_UTMSCF|"
Local cCampoCNA	:= "CNA_CONTRA|CNA_REVISA|CNA_CRONCT|CNA_FORNEC|CNA_LJFORN|CNA_CRONOG|CNA_ESPEL|CNA_DTMXMD|CNA_CRONCT|CNA_VLCOMS|"
Local cCampoCNB	:= "CNB_CONTRA|CNB_NUMERO|CNB_REVISA|CNB_REALI|CNB_DTREAL|CNB_DTANIV|CNB_CONORC|CNB_DTCAD|CNB_DTPREV|CNB_RATEIO|CNB_TIPO|CNB_ITSOMA|CNB_PERC|CNB_FILHO|CNB_PRCORI|CNB_SLDREC|CNB_QTDORI|CNB_QTRDAC|CNB_QTRDRZ|CNB_QTREAD|CNB_VLREAD|CNB_VLRDGL|CNB_PERCAL|CNB_FLGCMS|CNB_TE|CNB_NUMSC|CNB_NUMSC|CNB_ITEMSC|CNB_IDENT|CNB_MODORJ|CNB_VLTOTR|CNB_PROXRJ|CNB_UNPERI|CNB_PERI|"
Local cCampoCNC	:= "CNC_NUMERO|CNC_CODIGO|CNC_CODED|CNC_NUMPR|CNC_REVISA|CNC_NOME|CNC_LOJA|"
Local cCampoCND	:= "CND_CONTRA|CND_REVISA|CND_PARCEL|CND_CLIENT|CND_FORNEC|CND_LJFORN|CND_LOJACL|CND_CONDPG|CND_DESCCP|CND_VLCONT|CND_VLGER|CND_NUMERO|CND_TIPPLA|CND_DESCTP|CND_PARC1|CND_DATA1|CND_PARC2|CND_DATA2|CND_PARC3|CND_DATA3|CND_PARC4|CND_DATA4|CND_AUTFRN|CND_PEDIDO|CND_RESID|CND_SERVIC|CND_REVGER|CND_ULTMED|CND_FILCTR|CND_ULTMED|CND_RECMED|CND_MEDRET|CND_RETIFI|"
Local cCampoCNF	:= "CNF_CONTRA|CNF_REVISA|CNF_MAXPAR|CNF_PERANT|CNF_PERIOD|CNF_DIAPAR|CNF_CONDPG|CNF_NUMPLA|"
Local cCampoCNH	:= "CNH_REVISA|"
Local cCampoCNK	:= "CNK_CONTRA|CNK_OBS|"
Local cCampoCNS	:= "CNS_CONTRA|CNS_REVISA|CNS_CRONOG|CNS_PLANI|CNS_PARCEL|CNS_ITOR|"
Local cCampoCNT	:= "CNT_CONTRA|CNT_CLIENT|CNT_LOJACL|"
Local cCampoCNU := "CNU_CONTRA|"
Local cCampoCNV	:= "CNV_CONTRA|CNV_REVISA|CNV_PLANIL|"
Local cCampoCNW	:= "CNW_CONTRA|CNW_REVISA|CNW_NUMERO|CNW_DTLANC|"
Local cCampoCNX	:= "CNX_NUMMED|CNX_NUMTIT|CNX_PREFIX|CNX_FORNEC|CNX_CONTRA|CNX_LJFORN|CNX_CHEQUE|"
Local cCampoCNZ	:= "CNZ_CONTRA|CNZ_CODPLA|CNZ_REVISA|CNZ_NUMMED|CNZ_FORNEC|CNZ_LJFORN|CNZ_CLIENT|CNZ_LOJACL|CNZ_ITCONT|CNZ_VALOR1|CNZ_VALOR2|CNZ_VALOR3|CNZ_VALOR4|CNZ_VALOR5|"
Local cCampoCXN	:= "CXN_NUMMED|CXN_PARCEL|CXN_CRONOG|CXN_CRONCT|CXN_PARCEL|CXN_DTINI|CXN_DTFIM|CXN_VLPREV|CXN_VLMULT|CXN_VLLIQD|CXN_VLBONI|CXN_VLDESC|CXN_VLTOT|CXN_VLCOMS|CXN_VLREAJ|CXN_VLRADT|CXN_DTVENC|"
Local cCampoCXM	:= "CXM_CONTRA|CXM_NUMERO|CXM_REVISA|CXM_FILIAL|CXM_VLMED|"
Local cCampoCXO	:= "CXO_FILIAL|CXO_NUMMED|CXO_CONTRA|CXO_REVISA|CXO_NUMPLA|"
Local cCampoCXP	:= "CXP_FILIAL|CXP_CONTRA|CXP_NUMMED|CXP_REVISA|CXP_NUMPLA|CXP_ITMNAT|"

//- Preparação de estruturas da View
Local oStruCN8	:= FWFormStruct(2,'CN8', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCN8})
Local oStruCN9	:= FWFormStruct(2,'CN9', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCN9})
Local oStruCNA	:= FWFormStruct(2,'CNA', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNA})
Local oStruCNB	:= FWFormStruct(2,'CNB', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNB})
Local oStruCNC	:= FWFormStruct(2,'CNC', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNC})
Local oStruCND	:= FWFormStruct(2,'CND', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCND})
Local oStruCNF	:= FWFormStruct(2,'CNF', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNF})
Local oStruCNH	:= FWFormStruct(2,'CNH', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNH})
Local oStruCNI	:= FWFormStruct(2,'CNI')
Local oStruCNK	:= FWFormStruct(2,'CNK', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNK})
Local oStruCNS	:= FWFormStruct(2,'CNS', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNS})
Local oStruCNT	:= FWFormStruct(2,'CNT', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNT})
Local oStruCNU	:= FWFormStruct(2,'CNU', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNU})
Local oStruCNV	:= FWFormStruct(2,'CNV', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNV})
Local oStruCNW	:= FWFormStruct(2,'CNW', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNW})
Local oStruCNX	:= FWFormStruct(2,'CNX', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNX})
Local oStruCNZ	:= FWFormStruct(2,'CNZ', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCNZ})
Local oStruCXI	:= FWFormStruct(2,'CXI')
Local oStruCXL	:= FWFormStruct(2,'CXL')
Local oStruCXN	:= FWFormStruct(2,'CXN', {|cCampo|  AllTrim(cCampo)+'|' $ cCampoCXN})
Local oStruCXM	:= FWFormStruct(2,'CXM', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXM})
//Local oStruCXO	:= FWFormStruct(2,'CXO', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXO})
//Local oStruCXP	:= FWFormStruct(2,'CXP', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXP})
Local oStruCXO	:= Nil
Local oStruCXP	:= Nil
Local oStruSC7	:= FWFormStruct(2,'SC7')
Local oStruSC5	:= FWFormStruct(2,'SC5')

Local oStruTCNS	:= FWFormViewStruct():New()
Local oCalcCNF 	:= FWCalcStruct(oModel:GetModel('CALC_CNF'))

Local cVisuMed	:= SuperGetMV("MV_CTRMED",.F.,"0") //Define a Visualização das Medições e Pedidos
Local lMultNat	:= SuperGetMv('MV_MULNATR',.F.,.F.)
Local lFldReaj	:= SuperGetMV('MV_CNRJMNT',.F.,.F.)

Local lFisico 	:= Cn300RetSt("FISICO",2)
Local lContab	:= Cn300RetSt("CONTABIL",2)
Local lMedeve	:= Cn300RetSt("MEDEVE",2)
Local lFixo		:= Cn300RetSt("FIXO",2)
Local lRemovCrg	:= .F.
Local lRemovCtb	:= .F.
Local lVisuCau	:= .T.
Local lVisuPla	:= .T.
Local lVisuCro	:= .T.
Local lVisuDoc	:= .T.
Local lVisuAll	:= .F.
Local lA300STRU := ExistBlock("A300STRU")

ALTERA:= IF(Type("ALTERA") == "U", .T., ALTERA)

If AliasInDic('CXO')
	oStruCXO		:= FWFormStruct(2,'CXO', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXO})
	oStruCXP		:= FWFormStruct(2,'CXP', {|cCampo| !AllTrim(cCampo)+'|' $ cCampoCXP})
EndIF

cTipRevisa	:= A300GTpRev()
cAprTipRev	:= A300GATpRv()

//-- Adiciona campos header do cronograma fisico
oStruTCNS:AddField("TCNS_PARC"							,;	// [01]  C   Nome do Campo
				"01"										,;	// [02]  C   Ordem
				STR0016 									,;	// [03]  C   Titulo do campo
				STR0017									,;	// [04]  C   Descricao do campo
				NIL											,;	// [05]  A   Array com Help
				"C"											,;	// [06]  C   Tipo do campo
				""											,;	// [07]  C   Picture
				NIL											,;	// [08]  B   Bloco de Picture Var
				NIL											,;	// [09]  C   Consulta F3
				.F.											,;	// [10]  L   Indica se o campo é alteravel
				NIL											,;	// [11]  C   Pasta do campo
				NIL											,;	// [12]  C   Agrupamento do campo
				NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL											,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL											,;	// [15]  C   Inicializador de Browse
				.T.											,;	// [16]  L   Indica se o campo é virtual
				NIL											,;	// [17]  C   Picture Variavel
				NIL											)	// [18]  L   Indica pulo de linha após o campo

oStruTCNS:AddField("TCNS_VTOT"							,;	// [01]  C   Nome do Campo
				"02"										,;	// [02]  C   Ordem
				STR0018 									,;	// [03]  C   Titulo do campo
				STR0019									,;	// [04]  C   Descricao do campo
				NIL											,;	// [05]  A   Array com Help
				"N"											,;	// [06]  C   Tipo do campo
				PesqPict("CNF","CNF_VLPREV")			,;	// [07]  C   Picture
				NIL											,;	// [08]  B   Bloco de Picture Var
				NIL											,;	// [09]  C   Consulta F3
				.F.											,;	// [10]  L   Indica se o campo é alteravel
				NIL											,;	// [11]  C   Pasta do campo
				NIL											,;	// [12]  C   Agrupamento do campo
				NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL											,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL											,;	// [15]  C   Inicializador de Browse
				.T.											,;	// [16]  L   Indica se o campo é virtual
				NIL											,;	// [17]  C   Picture Variavel
				NIL											)	// [18]  L   Indica pulo de linha após o campo

//-- Adiciona campos de arrasto e redistribuição de saldos para o cronograma contábil
oStruCN9:AddField("CN9_ARRASC"							,;	// [01]  C   Nome do Campo
				"01"										,;	// [02]  C   Ordem
				"Arrasto" 									,;	// [03]  C   Titulo do campo
				"Arrasto"									,;	// [04]  C   Descricao do campo
				{STR0030}									,;	// [05]  A   Array com Help
				"C"											,;	// [06]  C   Tipo do campo
				"@!"										,;	// [07]  C   Picture
				NIL											,;	// [08]  B   Bloco de Picture Var
				NIL											,;	// [09]  C   Consulta F3
				.T.											,;	// [10]  L   Indica se o campo é alteravel
				"4"											,;	// [11]  C   Pasta do campo
				"GRP4"										,;	// [12]  C   Agrupamento do campo
				{'1=Sim','2=Não'}							,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL											,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL											,;	// [15]  C   Inicializador de Browse
				.T.											,;	// [16]  L   Indica se o campo é virtual
				NIL											,;	// [17]  C   Picture Variavel
				NIL											)	// [18]  L   Indica pulo de linha após o campo

oStruCN9:AddField("CN9_REDVAC"							,;	// [01]  C   Nome do Campo
				"02"										,;	// [02]  C   Ordem
				"Redist. Val." 							,;	// [03]  C   Titulo do campo
				"Redistribuição de Valores"				,;	// [04]  C   Descricao do campo
				{STR0031} 									,;	// [05]  A   Array com Help
				"C"											,;	// [06]  C   Tipo do campo
				"@!"										,;	// [07]  C   Picture
				NIL											,;	// [08]  B   Bloco de Picture Var
				NIL											,;	// [09]  C   Consulta F3
				.T.											,;	// [10]  L   Indica se o campo é alteravel
				"4"											,;	// [11]  C   Pasta do campo
				"GRP4"										,;	// [12]  C   Agrupamento do campo
				{'1=Sim','2=Não'}							,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL											,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL											,;	// [15]  C   Inicializador de Browse
				.T.											,;	// [16]  L   Indica se o campo é virtual
				NIL											,;	// [17]  C   Picture Variavel
				NIL											)	// [18]  L   Indica pulo de linha após o campo

oStruCND:AddField("CND_FILDES"						,;	// [01]  C   Nome do Campo
				"01"								,;	// [02]  C   Ordem
				(STR0050)		 					,;	// [03]  C   Titulo do campo
				(STR0050)		 					,;	// [03]  C   Descricao do campo
				NIL									,;	// [05]  A   Array com Help
				"C"									,;	// [06]  C   Tipo do campo
				"@!"								,;	// [07]  C   Picture
				NIL									,;	// [08]  B   Bloco de Picture Var
				NIL									,;	// [09]  C   Consulta F3
				.F.									,;	// [10]  L   Indica se o campo é alteravel
				NIL									,;	// [11]  C   Pasta do campo
				NIL									,;	// [12]  C   Agrupamento do campo
				NIL									,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL									,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL									,;	// [15]  C   Inicializador de Browse
				.T.									,;	// [16]  L   Indica se o campo é virtual
				NIL									,;	// [17]  C   Picture Variavel
				NIL									)	// [18]  L   Indica pulo de linha após o campo


oStruCXN:AddField("CXN_FILDES"						,;	// [01]  C   Nome do Campo
				"01"								,;	// [02]  C   Ordem
				'Fil. Medição'	 						,;	// [03]  C   Titulo do campo
				'Fil. Medição'							,;	// [04]  C   Descricao do campo
				NIL									,;	// [05]  A   Array com Help
				"C"									,;	// [06]  C   Tipo do campo
				"@!"								,;	// [07]  C   Picture
				NIL									,;	// [08]  B   Bloco de Picture Var
				NIL									,;	// [09]  C   Consulta F3
				.F.									,;	// [10]  L   Indica se o campo é alteravel
				NIL									,;	// [11]  C   Pasta do campo
				NIL									,;	// [12]  C   Agrupamento do campo
				NIL									,;	// [13]  A   Lista de valores permitido do campo (Combo)
				NIL									,;	// [14]  N   Tamanho maximo da maior opção do combo
				NIL									,;	// [15]  C   Inicializador de Browse
				.T.									,;	// [16]  L   Indica se o campo é virtual
				NIL									,;	// [17]  C   Picture Variavel
				NIL									)	// [18]  L   Indica pulo de linha após o campo

//-- Monta o modelo da interface do formulario
oView:SetModel(oModel)

cOper := oModel:GetOperation()

//Seta a operação para validadar o Folder Caucao
Do Case
	Case cOper == MODEL_OPERATION_VIEW
		cCau	:= DEF_CAU_VIS
	Case cOper == MODEL_OPERATION_INSERT
		cCau 	:= DEF_CAU_INC
	Case cOper == MODEL_OPERATION_UPDATE
		cCau	:= DEF_CAU_EDT
	Case cOper == MODEL_OPERATION_DELETE
		cCau 	:= DEF_CAU_EXC
EndCase

//Recupera a variável aVldUsr
aVldUsr := CNGetVldUsr()

//Array com os modelos que o usuário pode ver
If Len(aVldUsr) > 0
	If aVldUsr[1] == .T.
		lVisuAll	:= .T.
	Else
		If !INCLUI
			lVisuCau := .F.
			lVisuPla := .F.
			lVisuCro := .F.
			lVisuDoc := .F.
		EndIf
		aVisuAC	:= CN300VisAc()
		lVisuCau	:= aVisuAC[1]
		lVisuPla	:= aVisuAC[2]
		lVisuCro	:= aVisuAC[3]
		lVisuDoc	:= aVisuAC[4]
	EndIf
EndIf
oView:AddField('VIEW_CN9',oStruCN9,'CN9MASTER');oView:AddGrid('VIEW_CNU',oStruCNU,'CNUDETAIL')
If lVisuAll .Or. lVisuCau
	oView:AddGrid('VIEW_CN8',oStruCN8,'CN8DETAIL');oView:AddGrid('VIEW_CNI',oStruCNI,'CNIDETAIL')
	oView:AddGrid('VIEW_CNT',oStruCNT,'CNTDETAIL')
EndIf
If lVisuAll .Or. lVisuPla
	oView:AddGrid('VIEW_CNA',oStruCNA,'CNADETAIL')
	oView:AddGrid('VIEW_CNB',oStruCNB,'CNBDETAIL')
	//oView:AddGrid('VIEW_CXI',oStruCXI,'CXIDETAIL')
	oView:AddGrid('VIEW_CXM',oStruCXM,'CXMDETAIL')
	If lVisuCro
		oView:AddGrid('VIEW_CNF',oStruCNF,'CNFDETAIL');oView:AddGrid('VIEW_CNS',oStruCNS,'CNSDETAIL')
		oView:AddGrid('VIEW_CNV',oStruCNV,'CNVDETAIL');oView:AddGrid('VIEW_CNW',oStruCNW,'CNWDETAIL')
	EndIf
	oView:AddGrid('VIEW_CNZ',oStruCNZ,'CNZDETAIL')

	If cVisuMed $ "12"

		oView:AddGrid('VIEW_CND',oStruCND,'CNDDETAIL')	
		oView:AddGrid('VIEW_SC5',oStruSC5,'SC5DETAIL')
	EndIf
EndIf
oView:AddGrid('VIEW_CNH',oStruCNH,'CNHDETAIL')
If lVisuAll .Or. lVisuDoc
	oView:AddGrid('VIEW_CNK',oStruCNK,'CNKDETAIL')
EndIf
oView:AddGrid('VIEW_CNX',oStruCNX,'CNXDETAIL');oView:AddGrid('VIEW_CNC',oStruCNC, 'CNCDETAIL')
If lVisuAll .Or. (lVisuPla .And. lVisuCro)
	oView:AddField('VIEW_CLC1',oCalcCNF,'CALC_CNF');oView:AddField('VIEW_CLC2',oStruTCNS,'CALC_CNS')
EndIf

//-- Cria as 2 divisoes da interface
oView:CreateHorizontalBox('SUPERIOR',40)
oView:CreateHorizontalBox('INFERIOR',60)

//-- Cria a pasta e planilhas da Manutencao de Contratos
oView:CreateFolder('FLDCNT','INFERIOR')

oView:AddSheet('FLDCNT','GRDCLI',STR0001)		//"Clientes"
oView:AddSheet('FLDCNT','GRDVEND',STR0002) 	//"Vendedores"
If lVisuAll .Or. lVisuCau
	oView:AddSheet('FLDCNT','GRDCAUC',STR0003)    //"Cauçao"
EndIf
If lVisuAll .Or. lVisuPla
	oView:AddSheet('FLDCNT','GRDPLAN',STR0004)    //"Planilhas"
	
	If AliasInDic('CXO') .And. lMultNat
		oView:AddGrid('VIEW_CXO',oStruCXO,'CXODETAIL')
		oView:AddGrid('VIEW_CXP',oStruCXP,'CXPDETAIL')
		
		oView:AddSheet('FLDCNT','ABANTM',STR0054) 		//'Mult. Naturezas da Planilha'
		oView:CreateHorizontalBox('GRDNTM',40,/*owner*/,/*lUsePixel*/,'FLDCNT','ABANTM')
		oView:CreateHorizontalBox('GRDCCM',60,/*owner*/,/*lUsePixel*/,'FLDCNT','ABANTM')
		oView:SetOwnerView('VIEW_CXO','GRDNTM')
		oView:SetOwnerView('VIEW_CXP','GRDCCM')
		
		oView:AddIncrementField('VIEW_CXO','CXO_ITEM')
		oView:AddIncrementField('VIEW_CXP','CXP_ITEM')
	EndIf
	
EndIf
If cVisuMed $ "12"
	oView:AddSheet('FLDCNT','GRDMED',STR0027) 	//"Medições"
EndIf
oView:AddSheet('FLDCNT','GRDMULT',STR0005)    //"Multas/Bonificações"
If lVisuAll .Or. lVisuDoc
	oView:AddSheet('FLDCNT','GRDDOC',STR0006)		//"Documentos"
EndIf
oView:AddSheet('FLDCNT','GRDADT',STR0007)		//"Adiantamentos"
If lVisuAll .Or. lVisuCau
	oView:AddSheet('FLDCNT','GRDCRT',STR0008)		//"Caucões Retidas"
EndIf

oView:CreateHorizontalBox('CLIENTE',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDCLI')
oView:CreateHorizontalBox('VEND',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDVEND')
If lVisuAll .Or. lVisuCau
	oView:CreateHorizontalBox('CAUCAO',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDCAUC')
EndIf
oView:CreateHorizontalBox('PLANCAB',30,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDPLAN')
oView:CreateHorizontalBox('PLANITS',70,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDPLAN')
oView:CreateHorizontalBox('MULTAS',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDMULT')
If cVisuMed == "1" .Or. cVisuMed == "2"
	oView:CreateHorizontalBox('MEDIT',30,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDMED')
	oView:CreateHorizontalBox('PEDIDO',70,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDMED')
EndIf
If lVisuAll .Or. lVisuDoc
	oView:CreateHorizontalBox('DOC',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDDOC')
EndIf
oView:CreateHorizontalBox('ADTO',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDADT')

If lVisuAll .Or. lVisuCau
	//-- Cria a pasta e planilhas do caucao
	oView:CreateFolder('FLDCAUC','CAUCAO')

	oView:AddSheet('FLDCAUC','GRDCAB',STR0009)		//"Caução"
	oView:AddSheet('FLDCAUC','GRDITS',STR0010)		//"Notas Fiscais"

	oView:CreateHorizontalBox('CAUCCB',100,/*owner*/,/*lUsePixel*/,'FLDCAUC','GRDCAB')
	oView:CreateHorizontalBox('CAUCIT',100,/*owner*/,/*lUsePixel*/,'FLDCAUC','GRDITS')
EndIf

If lVisuAll .Or. lVisuPla
	//-- Cria a pasta e planilhas das Planilhas
	oView:CreateFolder('FLDPLAN','PLANITS')

	oView:AddSheet('FLDPLAN','ABAITS',STR0011)		//"Itens"
	oView:AddSheet('FLDPLAN','ABAAGR',STR0049 ) 	//""Agrupadores de Estoque""
	//oView:AddSheet('FLDPLAN','ABAPAE',"Partes Envolvidas")		//"Partes Envolvidas"
	oView:AddSheet('FLDPLAN','ABARAT',STR0012)		//"Rateio It."
	If lVisuCro
		oView:AddSheet('FLDPLAN','ABACRG',STR0013)		//"Cronog. Financ."
		oView:AddSheet('FLDPLAN','ABACRF',STR0014)		//"Cronog. Fisico"
		oView:AddSheet('FLDPLAN','ABACCB',STR0015)		//"Cronog. Contab."
	EndIf

	oView:CreateHorizontalBox('GRDITS',100,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABAITS')
	oView:CreateHorizontalBox('GRDAGR',100,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABAAGR')
	//oView:CreateHorizontalBox('GRDPAE',100,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABAPAE')
	oView:CreateHorizontalBox('GRDRAT',100,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABARAT')
	If lVisuCro
		oView:CreateHorizontalBox('GRDCLC',40,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABACRG')
		oView:CreateHorizontalBox('GRDCRG',60,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABACRG')
		oView:CreateHorizontalBox('GRDCRC',40,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABACRF')
		oView:CreateHorizontalBox('GRDCRF',60,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABACRF')
		oView:CreateHorizontalBox('GRDCTB',40,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABACCB')
		oView:CreateHorizontalBox('GRDCBI',60,/*owner*/,/*lUsePixel*/,'FLDPLAN','ABACCB')
	EndIf
	If cVisuMed == "1" .Or. cVisuMed == "2"
	oView:CreateFolder('FLDMED','PEDIDO')
	oView:AddSheet('FLDMED','ABAPED',STR0028 ) 		//"Pedidos"
	oView:CreateHorizontalBox('GRDPED',100,/*owner*/,/*lUsePixel*/,'FLDMED','ABAPED')
	EndIf
EndIf

If lVisuAll .Or. lVisuCau
	oView:CreateHorizontalBox('CARET',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDCRT')
EndIf

//-- Relaciona o identificador (ID) da View com o "box" para exibição
oView:SetOwnerView('VIEW_CN9','SUPERIOR');oView:SetOwnerView('VIEW_CNC','CLIENTE')
oView:SetOwnerView('VIEW_CNU','VEND')
If lVisuCau
	oView:SetOwnerView('VIEW_CN8','CAUCCB')
	oView:SetOwnerView('VIEW_CNI','CAUCIT')
	oView:SetOwnerView('VIEW_CNT','CARET')
EndIf
If lVisuAll .Or. lVisuPla
	oView:SetOwnerView('VIEW_CNA','PLANCAB')
	oView:SetOwnerView('VIEW_CNB','GRDITS')
	//oView:SetOwnerView('VIEW_CXI','GRDPAE')
	oView:SetOwnerView('VIEW_CXM','GRDAGR')

If cVisuMed == "1" .Or. cVisuMed == "2"

		oView:SetOwnerView('VIEW_CND','MEDIT')
	If CNTGetFun() <> 'CNTA301'
		oView:SetOwnerView('VIEW_SC7','GRDPED')
	Else
		oView:SetOwnerView('VIEW_SC5','GRDPED')
	EndIf
EndIf

	If lVisuCro
		oView:SetOwnerView('CALC_CNF','GRDCLC');oView:SetOwnerView('VIEW_CNF','GRDCRG')
		oView:SetOwnerView('VIEW_CNS','GRDCRF');oView:SetOwnerView('CALC_CNS','GRDCRC')
		oView:SetOwnerView('VIEW_CNV','GRDCTB');oView:SetOwnerView('VIEW_CNW','GRDCBI')
	EndIf
	oView:SetOwnerView('VIEW_CNZ','GRDRAT');oView:SetOwnerView('VIEW_CNH','MULTAS')
EndIf

If lVisuAll .Or. lVisuDoc
	oView:SetOwnerView('VIEW_CNK','DOC')
EndIf
oView:SetOwnerView('VIEW_CNX','ADTO')

//-- Campos incrementais
If lVisuAll .Or. lVisuPla
	oView:AddIncrementField('VIEW_CNA','CNA_NUMERO')
	oView:AddIncrementField('VIEW_CNB','CNB_ITEM')
	oView:AddIncrementField('VIEW_CXM','CXM_ITEMID')
	oView:AddIncrementField('VIEW_CNZ','CNZ_ITEM')
	oView:AddIncrementField('VIEW_CNX','CNX_NUMERO')
EndIf

//-- Remove campos que nao devem ser exibidos em tela
If !Empty(cTipRevisa) .Or.  !Empty(cAprTipRev)
	oStruCN9:SetProperty('CN9_TIPREV',MVC_VIEW_ORDEM,'00')

	oStruCN9:AddGroup("GRP1", STR0032, "", 2)	//"Parâmetros"
	oStruCN9:AddGroup("GRP2", STR0033, "", 2)	//"Redistribuição de saldo"
	oStruCN9:AddGroup("GRP3", STR0034, "", 2)	//"Reajuste"
	oStruCN9:AddGroup("GRP4", STR0035, "", 2)	//"Parâmetros contábeis"
	oStruCN9:AddGroup("GRP5", STR0036, "", 2)	//"Paralisação"
	oStruCN9:AddGroup("GRP6", STR0037, "", 2)	//"Reinicio"

	oStruCN9:AddGroup("GRP7", STR0055, "", 2)	//"Datas Retroativas"
	oStruCN9:SetProperty( "CN9_DTRRDE" , MVC_VIEW_GROUP_NUMBER, "GRP7" )
	oStruCN9:SetProperty( "CN9_DTRRAT" , MVC_VIEW_GROUP_NUMBER, "GRP7" )
	
Else
	oStruCN9:RemoveField("CN9_TIPREV")
EndIf

//--Remove Campos exclusivos de cada revisao.
If (cTipRevisa <> DEF_REV_REAJU .And. cAprTipRev <> DEF_REV_REAJU) .And. ;
	!(cTipRevisa == DEF_REV_REALI )

	oStruCN9:RemoveField("CN9_DREFRJ")
	oStruCN9:RemoveField("CN9_DTREAJ")
Else

	If cTipRevisa == DEF_REV_REALI
		oStruCN9:SetProperty( "CN9_DREFRJ" , MVC_VIEW_GROUP_NUMBER, "GRP3" )
		oStruCN9:RemoveField("CN9_DTREAJ")
	EndIf

	If cTipRevisa == DEF_REV_REAJU
		oStruCN9:SetProperty( "CN9_DTREAJ" , MVC_VIEW_GROUP_NUMBER, "GRP3" )
		oStruCN9:SetProperty( "CN9_DREFRJ" , MVC_VIEW_GROUP_NUMBER, "GRP3" )
	EndIf
EndIf

If !(cTipRevisa $  DEF_REV_PARAL+'|'+DEF_REV_REINI+'|'+DEF_REV_ABERT) .And. !(cAprTipRev $  DEF_REV_PARAL+'|'+DEF_REV_REINI+'|'+DEF_REV_ABERT)
	oStruCN9:RemoveField("CN9_MOTPAR")
	oStruCN9:RemoveField("CN9_DESMTP")
	oStruCN9:RemoveField("CN9_DTFIMP")
	oStruCN9:RemoveField("CN9_DTREIN")
Else
	oStruCN9:SetProperty( "CN9_MOTPAR" , MVC_VIEW_GROUP_NUMBER, "GRP5" )
	oStruCN9:SetProperty( "CN9_DESMTP" , MVC_VIEW_GROUP_NUMBER, "GRP5" )
	oStruCN9:SetProperty( "CN9_DTFIMP" , MVC_VIEW_GROUP_NUMBER, "GRP5" )
	oStruCN9:SetProperty( "CN9_DTREIN" , MVC_VIEW_GROUP_NUMBER, "GRP6" )
EndIf

If Empty(cTipRevisa)
	oStruCN9:RemoveField("CN9_QTDPAR")
	oStruCN9:RemoveField("CN9_TPCRON")
	oStruCN9:RemoveField("CN9_ARRAST")
	oStruCN9:RemoveField("CN9_REDVAL")
	oStruCN9:RemoveField("CN9_UDMES")

	oStruCN9:RemoveField("CN9_CSLD")
	oStruCN9:RemoveField("CN9_CPARCA")
	oStruCN9:RemoveField("CN9_CPARCV")
	oStruCN9:RemoveField("CN9_MPLA")
	oStruCN9:RemoveField("CN9_DTRRDE")
	oStruCN9:RemoveField("CN9_DTRRAT")

	oStruCN9:RemoveField("CN9_ARRASC")
	oStruCN9:RemoveField("CN9_REDVAC")
	oStruCN9:RemoveField("CN9_TPCROC")
	oStruCN9:RemoveField("CN9_QTPARC")
	oStruCNA:RemoveField("CNA_SADISC")

	oStruCNA:RemoveField("CNA_SADIST")
Else
	oStruCN9:SetProperty( "CN9_TPCRON" , MVC_VIEW_GROUP_NUMBER, "GRP1" )
	oStruCN9:SetProperty( "CN9_ARRAST"  , MVC_VIEW_GROUP_NUMBER, "GRP1" )
	oStruCN9:SetProperty( "CN9_REDVAL" , MVC_VIEW_GROUP_NUMBER, "GRP1" )
	oStruCN9:SetProperty( "CN9_QTDPAR" , MVC_VIEW_GROUP_NUMBER, "GRP1" )
	oStruCN9:SetProperty( "CN9_UDMES" , MVC_VIEW_GROUP_NUMBER, "GRP1" )

	oStruCN9:SetProperty( "CN9_CSLD"  , MVC_VIEW_GROUP_NUMBER, "GRP2" )
	oStruCN9:SetProperty( "CN9_CPARCA" , MVC_VIEW_GROUP_NUMBER, "GRP2" )
	oStruCN9:SetProperty( "CN9_CPARCV" , MVC_VIEW_GROUP_NUMBER, "GRP2" )
	oStruCN9:SetProperty( "CN9_MPLA" , MVC_VIEW_GROUP_NUMBER, "GRP2" )

	oStruCN9:SetProperty( "CN9_TPCROC" , MVC_VIEW_GROUP_NUMBER, "GRP4" )
	oStruCN9:SetProperty( "CN9_QTPARC" , MVC_VIEW_GROUP_NUMBER, "GRP4" )
EndIf

//--Folder reajuste
If lFldReaj .And. IsInCallStack("CN300Visua")
	oView:AddGrid('VIEW_CXL',oStruCXL,'CXLDETAIL')
	oView:AddSheet('FLDCNT','GRDREAJ',"Reajustes")	//"Reajustes"
	oView:CreateHorizontalBox('REAJUSTE',100,/*owner*/,/*lUsePixel*/,'FLDCNT','GRDREAJ')
	oView:SetOwnerView('VIEW_CXL','REAJUSTE')
	oStruCXL:RemoveField("CXL_CONTRA");oStruCXL:RemoveField("CXL_REVISA")
Endif

If ExistFunc("CN300RatP") .And. (INCLUI .Or. (ALTERA .And. (!Empty(cTipRevisa) .And. (cTipRevisa == DEF_REV_ADITI .Or. cTipRevisa == DEF_REV_ABERT))))
	oView:AddUserButton(STR0052,'CLIPS',{|| CN300RatP(oModel)})	//-- Rateio Pré-Configurado
EndIf

If IsInCallStack("CN300Visua")
	oView:AddUserButton(STR0047,'BUDGET', {|| CN300VFoCl()}) //- Visualizar Forn./Cliente
EndIf

If !CNGetAdiant()
	If IsInCallStack("CN300Visua")
	 If cVisuMed <> "0"
		oView:AddUserButton(STR0029,'CLIPS',{|| CN301ViewVd()}) //Visualizar Pedido de Venda
	EndIf	
		oView:AddUserButton(STR0046,'CLIPS',{|| CN301posic("CN9",CN9->(Recno()),2,IIF(!Empty(CN9->CN9_REVISA),"IR","IC"),.F.)}) //"Aprovação por Itens"
		oView:AddUserButton(STR0022,'CLIPS',{|| StaticCall(CNTA100,CN100Conh)})	//-- Conhecimento
		oView:AddUserButton(STR0020,'CLIPS',{|| CN100Hist(M->CN9_NUMERO)})	//-- Historico
		oView:AddUserButton(STR0021,'CLIPS',{|| CN300Track()})	//-- Tracker
		oView:AddUserButton(STR0048,'CLIPS', {||CN300VDoc()}) //"Visualizar Documento"
		oView:addUserButton(STR0053,'CLIPS',{||CN300PrtExp(oModel)})
		
		If SuperGetMv("MV_CNINTFS",.F.,.F.)
			oView:AddUserButton(STR0051,'CLIPS',{|| TECLOCFIS()}) //Botão para localização física (Gestao de Servicos)
		EndIf

	ElseIf !IsInCallStack("CN300Delet") .And. Empty(cAprTipRev)
		If !Empty(cTipRevisa) // Somente na Revisao
			If !lRemovCrg
				oView:AddUserButton(STR0039,'CLIPS',{|| CN300RdSld(oModel)})	//"Redistribui saldos"
				oView:AddUserButton(STR0038,'CLIPS',{|| CN300AtCrs(oModel)})	//"Atualizar cronogramas Físico/Financeiro"
			EndIf

			If !lRemovCtb
				oView:AddUserButton(STR0040,'CLIPS',{|| CN300AtCont()})	//"Atualizar cronograma Contábil"
			EndIf

			If cTipRevisa == DEF_REV_REAJU
				oView:AddUserButton(STR0041,'CLIPS',{|| CN300REAJU(oModel)})	//"Executar reajuste"
			EndIf
		EndIf
		If (cTipRevisa == DEF_REV_ADITI .Or. cTipRevisa == DEF_REV_REALI .Or. cTipRevisa == DEF_REV_READE .Or. cTipRevisa == DEF_REV_REINI .Or. cTipRevisa == DEF_REV_RENOV .Or. cTipRevisa == DEF_REV_ORCGS .Or. cTipRevisa == DEF_REV_ABERT);
			.Or. Empty(cTipRevisa)

			//Se a revisão tiver cronograma ou não estiver fazendo uma revisão
			If !lRemovCrg .Or. Empty(cTipRevisa)
				If lVisuCro
					oView:AddUserButton(STR0023,'CLIPS',{|| CN300PrCF()}) 		//-- Incluir cronograma financeiro/físico
					oView:AddUserButton(STR0024,'CLIPS',{|| CN300DelCrg()}) 	//-- Excluir cronograma financeiro/físico
				EndIf
			EndIf

			//Se a revisão tiver cronograma ou não estiver fazendo uma revisão
			If !lRemovCtb .Or. Empty(cTipRevisa)
				If lVisuCro
					oView:AddUserButton(STR0025,'CLIPS',{|| CN300PrcCC()}) 		//-- Incluir cronograma contábil"
					oView:AddUserButton(STR0026,'CLIPS',{|| CN300DelCtb()}) 	//-- Excluir cronograma contábil"
				EndIf
			EndIf
		EndIf

		//Adiciona botão para localização física (Gestao de Servicos)
		If SuperGetMv("MV_CNINTFS",.F.,.F.) .And. CNTGetFun() == 'CNTA301'
			oView:AddUserButton(STR0051,'CLIPS',{|| TECLOCFIS()})
		EndIf

	EndIf
EndIf

If FunName() $ "GCPA200*GCPA300*TECA850*TECA870" .OR. IsInCallStack('MATA161')
	If lVisuAll .Or. lVisuPla
	oStruCNA:SetProperty('*',MVC_VIEW_CANCHANGE,.F.) 				//Desabilita os campos
	oStruCNA:SetProperty('CNA_FLREAJ', 	MVC_VIEW_CANCHANGE,.T.)	//Habilita o campo
		oStruCNB:SetProperty('*', MVC_VIEW_CANCHANGE, .F.) 				//Desabilita os campos
		// desabilita a edição dos campos do wizard do gestão de serviços
		If FunName() $ "TECA850*TECA870"
			oStruCNB:SetProperty('CNB_IDPED', MVC_VIEW_CANCHANGE, .T.)
			oStruCNB:SetProperty('CNB_CC', MVC_VIEW_CANCHANGE, .T.)
			oStruCNB:SetProperty('CNB_TS', MVC_VIEW_CANCHANGE, .T.)
			oStruCNC:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)
			oStruCN9:SetProperty("CN9_TPCTO",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_NUMERO",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_DTINIC",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_UNVIGE",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_VIGE",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_CONDPG",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_INDICE",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_FLGREJ",	MVC_VIEW_CANCHANGE,.F.)
			oStruCN9:SetProperty("CN9_FLGCAU",	MVC_VIEW_CANCHANGE,.F.)
			If oStruCN9:HasField("CN9_TIPREV")
				oStruCN9:SetProperty("CN9_TIPREV",	MVC_VIEW_CANCHANGE,.F.)
			EndIf
		EndIf
	EndIf
EndIf
If cTipRevisa == DEF_REV_REALI .And. !lFixo
	oStruCN9:SetProperty("CN9_VLATU",	MVC_VIEW_CANCHANGE,.T.)	//Habilita o campo
EndIf

If cTipRevisa == DEF_REV_ADITI .OR. cTipRevisa == DEF_REV_RENOV .OR. cTipRevisa == DEF_REV_ORCGS .OR. cTipRevisa == DEF_REV_ABERT
	oStruCNB:SetProperty('CNB_VLTOT',	MVC_VIEW_CANCHANGE,.F.)	//Desabilita para edição
EndIf

If lVisuAll .Or. lVisuPla
	oView:SetViewProperty( 'CNADETAIL', "CHANGELINE", {{ |oView, cViewID| a300ChgLine(oView, cViewID) }} )
EndIf
oStruCN9:SetProperty("CN9_VLADIT",MVC_VIEW_CANCHANGE, .F.)

If lA300STRU
	ExecBlock( "A300STRU", .F., .F., { "VIEWDEF", "V", @oView } )
EndIf

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} CNTGetFun()
Rotina para montagem do model da manutenção de contratos - venda

@author Antenor Silva
@since 03/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

Local lA300STRU := ExistBlock("A300STRU")

//-- Seta função chamadora
CNTSetFun("CNTA301")

oModel := FWLoadModel("CNTA300")

If lA300STRU
	ExecBlock( "A300STRU", .F., .F., { "MODELDEF", "V", @oModel } )
EndIf

Return oModel

//-------------------------------------------------------------------
/*{Protheus.doc} CN301ViewVd
Função que retorna a View do Pedido de Venda vinculado à Medição
@author miguel.santos
@since 20/07/2015
*/
//-------------------------------------------------------------------
Function CN301ViewVd(oModel)
Local oModelSC6 	:= Nil
Local oModelCND 	:= Nil
Local cPedido 		:= ""

// Foi necessario criar essas variaveis para que fosse possivel usar a funcao padrao do sistema A120Pedido()
Private aRotina   	:= {}
Private INCLUI    	:= .F.
Private ALTERA    	:= .F.
Private l120Auto	:= .F.
Private nTipoPed  	:= 1
Private cCadastro 	:= ""

DEFAULT oModel 		:= FWModelActive()
oModelSC5 	:= oModel:GetModel("SC5DETAIL")
oModelCND 	:= oModel:GetModel("CNDDETAIL")
cPedido 	:= oModelSC5:GetValue('C5_NUM')

//--Monta o aRotina para compatibilizacao
AAdd( aRotina, { '' , '' , 0, 1 } )
AAdd( aRotina, { '' , '' , 0, 2 } )
AAdd( aRotina, { '' , '' , 0, 3 } )
AAdd( aRotina, { '' , '' , 0, 4 } )
AAdd( aRotina, { '' , '' , 0, 5 } )

If SC5->(DbSeek(xFilial("SC5")+cPedido))
    cCadastro    := STR0042	//"Pedido de Venda"
    A410Visual("SC5",SC5->( Recno()),2)
Else
	Help('',1,'CNTA300SPD') //A Planilha selecionada não possui Pedidos!
EndIf

Return NIL

//-------------------------------------------------------------------
/*{Protheus.doc} CN301posic
Função para inicializar a variável aRotina antes da chamada da função a120Posic na ViewDef
@author Diego Bezerra
@since 17/08/2018
*/
//-------------------------------------------------------------------

Function CN301posic (cAlias, nReg, nNum, cChar, lBol)

Private aRotina   	:= {}

//--Monta o aRotina para compatibilizacao
AAdd( aRotina, { '' , '' , 0, 1 } )
AAdd( aRotina, { '' , '' , 0, 2 } )
AAdd( aRotina, { '' , '' , 0, 3 } )
AAdd( aRotina, { '' , '' , 0, 4 } )
AAdd( aRotina, { '' , '' , 0, 5 } )

a120Posic(cAlias ,nReg, nNum, cChar, lBol)

Return
