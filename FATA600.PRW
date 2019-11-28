#INCLUDE "PROTHEUS.CH"
#INCLUDE "FATA600.CH"
#INCLUDE "DBTREE.CH"
#INCLUDE "FWMVCDEF.CH"

Static aTipo09		:= {}
Static aCronoFin	:= {}
Static aConfigAlo 	:= {}	// Configuracao da alocacao de recurso.
Static _aTFFCOD_   	:= {} 	// Armazena os codigos gerados para os itens do RH
Static _lVistoria_	:= .F.	// Armazena se a chamada do Orcamento e via Vistoria
Static _oMdlOpor	:= Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} FATA600
Proposta Comercial (Convertida em MVC)

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//------------------------------------------------------------------
Function FATA600(oMdlFt300, nOperation, aADYMaster, aADZProduto, aADZAcessor)

Local aArea		:= GetArea()
Local oBrowse	:= Nil															//Objeto do Browse
Local nX		:= 0															//Contador
Local aSincProp	:= {}															//Campo virtual para ilutrar a proposta sincronizada
Local nOpcADJ	:= SuperGetMv("MV_FATMNTP",, 1)								//Tratamento do dado na ADJ
Local cFilter	:= ""															//Filtro do Browse
Local aCores	:= {}															//Cores da legenda
Local oTableAtt	:= Nil
Local lFT600FIL	:= ExistBlock("FT600FIL")
Local aCoresNew	:= {}
Local lRet		:= .T.
Local aAutoRot	:= {}
Local nSeekOpt	:= 0
Local aFT600CL	:= {}

Default nOperation	:= MODEL_OPERATION_INSERT
Default aADYMaster	:= {}
Default aADZProduto	:= {}
Default aADZAcessor	:= {}

Private cCadastro		:= STR0001 	//"Proposta Comercial"
Private aRotina		:= MenuDef()
Private INCLUI		:= .F. 		// Vari�vel declarada devido a rotina autom�tica e chamada no Model.
//comentario teste
If Len( aADYMaster ) == 0
	// Tratamento efetuado para quando chamado a proposta, da visualiza��o de uma oportunidade.
	If ValType(oMdlFt300) == "O"
		nOperation	:= oMdlFt300:GetOperation()
		If nOperation == MODEL_OPERATION_VIEW .And. nOpcADJ <> 4
			// Se tiver proposta
			DbSelectArea( "ADJ" )
			DbSetOrder( 1 ) //ADJ_FILIAL+ADJ_NROPOR+ADJ_REVISA
			If Empty(FwFldGet("ADJ_PROPOS")) .AND. ADJ->(DbSeek(xFilial("ADJ")+FwFldGet("AD1_NROPOR")))
				//Liberado a op��o visualizar da proposta, n�o possivel realizar as outras op��es de menu.
				aRotina := {}
				ADD OPTION aRotina TITLE STR0023 ACTION "VIEWDEF.FATA600"	OPERATION 2 ACCESS 0 	// "Visualizar"
				AAdd( aRotina, { STR0026, 'A600Impr' 	, 0, 6, 0, NIL } ) 	//"Impress�o"
			Else
				HELP(" ",1,"REGNOIS")
				lRet	:= .F.
			EndIf
		EndIf
	EndIf

	If lRet
		If ValType(oMdlFt300) == "O"
			_oMdlOpor := oMdlFt300
		EndIf

		aCores 	:= FT600Legenda()

		cFilter := "ADY_FILIAL == '" + xFilial("ADY") + "' .AND. ADY_OPORTU == '" + AD1->AD1_NROPOR + "'"
		If lFT600FIL
			cFilter += " .AND. "+ExecBlock("FT600FIL",.F.,.F.,{cFilter})
		EndIf
		oBrowse := FWMBrowse():New()
		oBrowse:SetAlias('ADY')

		//Adiciona as Legendas no Browse
		For nX := 1 To Len(aCores)
			oBrowse:AddLegend( aCores[nX][1], aCores[nX][2], aCores[nX][3] )
		Next nX

		//------------------------------------------
		// Ponto de entrada que adiciona coluna ao Browse
		//------------------------------------------
		If ExistBlock("FT600CL")
			aFT600CL := ExecBlock("FT600CL",.F.,.F.)
			If ValType(aFT600CL) == "A"
				For nX := 1 to len(aFT600CL)
					oBrowse:AddColumn(aFT600CL[nX])
				Next nX
			EndIf
			aFT600CL	:= {}
		Endif

		oBrowse:SetFilterDefault(cFilter)

		//Adiciona no browse o campo Sincronizar para o parametro MV_FATMNTP igual a 1
		If cValToChar( nOpcADJ ) $ "1|4"
			aSincProp:= { STR0192, {|| IIF(ADY->ADY_SINCPR,"LBOK","LBNO")}, "C", "@BMP", 0, 1, 0, .F., {||}, .T.,,,,, .F. } //Sincronizar
			oBrowse:AddColumn(aSincProp)
		EndIf

		oBrowse:SetCacheView( .F. )
		//Habilita as vis�es na proposta comercial
		oBrowse:SetAttach(.T.)
		oTableAtt := TableAttDef()
		If oTableAtt <> Nil
			oBrowse:SetViewsDefault(oTableAtt:aViews)
			oBrowse:SetChartsDefault(oTableAtt:aCharts)

			oBrowse:SetIDChartDefault( "PorDtEmis" )
		EndIf

		//Se n�o for SIGACRM inibe a exibi��o do gr�fico
		If nModulo <> 73
			oBrowse:SetOpenChart( .F. )
		EndIf

		oBrowse:SetCanSaveArea(.T.)
		oBrowse:SetTotalDefault('ADY_PROPOS','COUNT',STR0281) // "Total de Registros"
		oBrowse:SetChgAll(.F.)
		oBrowse:SetSeeAll(.F.)
		oBrowse:DisableDetails(.F.)
		oBrowse:SetDescription(cCadastro)
		oBrowse:SetMenuDef("FATA600")
		oBrowse:SetMainProc("FATA600")
		oBrowse:Activate()
	EndIf
Else
	//------------------------------------------
	// Cabe�alho - Proposta
	//------------------------------------------
	aAdd( aAutoRot, { "ADYMASTER", aADYMaster } )

	//------------------------------------------
	// Itens - Proposta (Folder Produtos)
	//------------------------------------------
	aAdd( aAutoRot, { "ADZPRODUTO", aADZProduto } )

	//------------------------------------------
	// Itens - Proposta (Folder Acess�rios)
	//------------------------------------------
	aAdd( aAutoRot, { "ADZACESSOR", aADZAcessor } )

	//-------------------------------------------------------------
	// Posiciona na oportunidade caso  o modelo n�o esteja ativo.
	//-------------------------------------------------------------
	nSeekOpt := aScan( aADYMaster, { |x| Alltrim( x[1] ) == "ADY_OPORTU" } )

	If nSeekOpt > 0
		DbSelectArea( "AD1" )
		DbSetOrder( 1 ) //AD1_FILIAL+AD1_NROPOR+AD1_REVISA
		If DbSeek( xFilial("AD1") + aADYMaster[nSeekOpt][2] )
			_oMdlOpor := FwLoadModel( 'FATA300' )
			_oMdlOpor:SetOperation( MODEL_OPERATION_UPDATE )
			_oMdlOpor:Activate()
			//------------------------------------------
			// Rotina Automatica atrav�s do MVC
			//------------------------------------------
			If nOperation == MODEL_OPERATION_INSERT
				INCLUI := .T.
			EndIf
			FwMvcRotAuto( ModelDef(), "ADY", nOperation, aAutoRot, /*lSeek*/, .T. )
		Else
			Help( ,, 'A600EXECAUTO1',, STR0323, 1, 0 )//"O n�mero da oportunidade informado n�o foi encontrado, sendo assim, a execu��o da rotina autom�tica n�o ser� efetuada."
		EndIf
	Else
		Help( ,, 'A600EXECAUTO2',, STR0324, 1, 0 )//"N�o foi informado o n�mero da Oportunidade de Vendas, sendo assim, a execu��o da rotina autom�tica n�o ser� efetuada."
	EndIf

EndIf

_oMdlOpor := Nil

RestArea( aArea )
Return Nil

//------------------------------------------------------------------------------
/*/	{Protheus.doc} TableAttDef

Cria as vis�es e gr�ficos padr�o.

@sample	TableAttDef()

@param		Nenhum

@return	ExpA - Array de Objetos com as Visoes e Gr�ficos.

@author	Aline Kokumai
@since		02/05/2014
@version	12
/*/
//------------------------------------------------------------------------------
Static Function TableAttDef()

Local oTableAtt		:= FWTableAtt():New()
Local oPorStatus	:= Nil // Pizza: Proposta Comercial por Status
Local oPorDtEmis	:= Nil // Colunas: Proposta Por Data de Emiss�o
Local oPropSinc		:= Nil // Vis�o: Oportunidades Sincronizadas

oTableAtt:SetAlias("ADY")

// Proposta Sincronizada
oPropSinc := FWDSView():New()
oPropSinc:SetName(STR0260)	//"Proposta Sincronizada"
oPropSinc:SetID("PropSinc")
oPropSinc:SetOrder(1) // ADY_FILIAL+ADY_PROPOS+ADY_PREVIS
oPropSinc:SetCollumns({	"ADY_PROPOS", "ADY_PREVIS", "ADY_OPORTU", "ADY_REVISA", "ADY_ENTIDA", "ADY_CODIGO",;
					 	"ADY_LOJA", "ADY_DESENT","ADY_TABELA", "ADY_STATUS", "ADY_VEND", "ADY_MSBLQL"})
oPropSinc:SetPublic( .T. )
oPropSinc:AddFilter(STR0260, "ADY_SINCPR == .T.")
oTableAtt:AddView(oPropSinc)

// GRAFICOS
// Pizza: Proposta Comercial por Status
oPorStatus := FWDSChart():New()
oPorStatus:SetName(STR0261)	//"Proposta Comercial por Status"
oPorStatus:SetTitle(STR0261)
oPorStatus:SetID("PorStatus")
oPorStatus:SetType("PIECHART")
oPorStatus:SetSeries({ {"ADY", "ADY_PROPOS", "COUNT"} })
oPorStatus:SetCategory( { {"ADY", "ADY_STATUS"} } )
oPorStatus:SetPublic( .T. )
oPorStatus:SetLegend( CONTROL_ALIGN_BOTTOM ) //Inferior
oPorStatus:SetTitleAlign( CONTROL_ALIGN_CENTER )
oTableAtt:AddChart(oPorStatus)

// Colunas: Proposta Por Data de Emiss�o
oPorDtEmis := FWDSChart():New()
oPorDtEmis:SetName(STR0264)	//"Proposta Por Data de Emiss�o"
oPorDtEmis:SetTitle(STR0264)
oPorDtEmis:SetID("PorDtEmis")
oPorDtEmis:SetType("BARCOMPCHART")
oPorDtEmis:SetSeries({ {"ADY", "ADY_PROPOS", "COUNT"} })
oPorDtEmis:SetCategory( { {"ADY", "ADY_DATA"} } )
oPorDtEmis:SetPublic( .T. )
oPorDtEmis:SetLegend( CONTROL_ALIGN_BOTTOM ) //Inferior
oPorDtEmis:SetTitleAlign( CONTROL_ALIGN_CENTER )
oTableAtt:AddChart(oPorDtEmis)

Return (oTableAtt)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Defini��o do MenuDef

@return ExpO, Array, aRotina

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina 	:= {}
Local nPos			:= 0
Local aAtiv		:= {}
Local aAnotac		:= {}
Local aEntRelac	:= {}

ADD OPTION aRotina TITLE  STR0023  ACTION  "VIEWDEF.FATA600" OPERATION 2 ACCESS 0 // "Visualizar"
ADD OPTION aRotina TITLE  STR0024  ACTION  "VIEWDEF.FATA600" OPERATION 3 ACCESS 0 // "Incluir"
ADD OPTION aRotina TITLE  STR0025  ACTION  "VIEWDEF.FATA600" OPERATION 4 ACCESS 0 // "Alterar"
ADD OPTION aRotina TITLE  STR0335  ACTION  "VIEWDEF.FATA600" OPERATION 5 ACCESS 0 // "Excluir"
ADD OPTION aRotina TITLE  STR0191  ACTION  "VIEWDEF.FATA600" OPERATION 9 ACCESS 0 // "Copiar"

AAdd( aRotina, { STR0026, 'A600Impr' 	, 0, 6, 0, NIL } ) //"Impress�o"
aAdd( aRotina, { STR0190, 'A600CompPr' , 0, 7, 0, NIL } ) //"Comparar Propostas"

If nModulo == 28
	AAdd( aRotina, { STR0219, "A600SerRes", 0, 4,, .T. }  ) // "Reservar Equip."
EndIf

If nModulo == 73

	aEntRelac := CRMXINCROT( "ADY", aEntRelac )

	ADD OPTION aEntRelac TITLE STR0235   ACTION "CRMA200()"	 OPERATION  8 ACCESS 0  //"Privil�gios"

	nPos := ASCAN(aEntRelac, { |x|  x[2] == "CRMA190Con()" })
	If nPos > 0
		ADD OPTION aRotina TITLE aEntRelac[nPos][1] ACTION aEntRelac[nPos][2] OPERATION 8  ACCESS 0//"Conectar"
		Adel(aEntRelac,nPos)
		Asize(aEntRelac,Len(aEntRelac)-1)
	EndIf

	nPos := ASCAN(aEntRelac, { |x|  IIF(ValType(x[2]) == "C", x[2] == "CRMA180()", Nil) })
	If nPos > 0
		ADD OPTION aAtiv   TITLE STR0231 ACTION "CRMA180(,,,3,,)" OPERATION 3  ACCESS 0 //"Nova Atividade"
		ADD OPTION aAtiv   TITLE STR0232 ACTION "CRMA180()" OPERATION 8  ACCESS 0 //"Todas as ATividades"
		aEntRelac[nPos][2] := aAtiv
	EndIf

	nPos := ASCAN(aEntRelac, { |x|  IIF(ValType(x[2]) == "C", x[2] == "CRMA090()", Nil) })
	If nPos > 0
		ADD OPTION aAnotac   TITLE STR0233 ACTION "CRMA090(3)" OPERATION 3  ACCESS 0 //"Nova Anota��o"
		ADD OPTION aAnotac   TITLE STR0234 ACTION "CRMA090()" OPERATION 8  ACCESS 0 //"Todas as Anota��es"
		aEntRelac[nPos][2] := aAnotac
	EndIf
EndIf

//copia � desativada enquanto o novo fata600 da totvs12 nao descer para o padr�o
If nModulo == 28
	nPos := ASCAN(aRotina, { |x|  x[1] == "Copiar" })
	If nPos > 0
		Adel(aRotina,nPos)
		Asize(aRotina,Len(aRotina)-1)
	EndIf
EndIf

Asort(aEntRelac,,,{ | x,y | y[1] > x[1] } )

ADD OPTION aRotina TITLE  STR0266 ACTION aEntRelac 	    OPERATION 8  ACCESS 0	//"Relacionadas"

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Defini��o do modelo de Dados

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

Local oModel
Local nTamTot		:= GetSX3Cache("ADZ_TOTAL","X3_TAMANHO")		// Tamanho do campo ADZ_TOTAL.
Local nDecTot		:= GetSX3Cache("ADZ_TOTAL","X3_DECIMAL")		// Numero de decimais do campo ADZ_TOTAL.
Local aAux1		:= {}
Local lFta600MDL	:= ExistBlock("FATA600MDL")

Local oStructFke	:= FWFormModelStruct():New()

Local oStrADY		:= FWFormStruct(1,'ADY')			//Cabe�alho da Proposta Comercial
Local oStrADZPro	:= FWFormStruct(1,'ADZ')			//Itens da Proposta Comercial
Local oStrADZAce	:= FWFormStruct(1,'ADZ')			//Itens da Proposta Comercial

Local oStrGINVE	:= FWFormStruct(1,'GIN')			//Pasta Percurso
Local oStrGIOVE	:= FWFormStruct(1,'GIO')			//Pasta Custos
Local oStrGIPVE	:= FWFormStruct(1,'GIP')			//Pasta Veiculos

//Blocos de valida��o
Local bLinePost		:= {|oModel, nLine| At600LOk(oModel, nLine)}  	//Pr�-Valida��o da linha
Local bPosVldLin		:= {|oModel| At600VPsLn(oModel)} 	//P�s-Valida��o da linha
Local bTudoOk			:= {|oModel| At600TOk(oModel)}	 	//P�s-Valida��o do Model
Local bCommit			:= {|oModel| At600Commit(oModel)} 	//Commit do Model
Local bCancel			:= {|oModel| At600Cancel(oModel)} 	//Cancelamento da Proposta
Local bLoadCro		:= {|| {}}
Local bActive			:= {|oModel| Ft600MdlAct(oModel)}	//Load do Grid
Local cValidUser		:= ""
Local bVldActive		:= {|oModel| FT600VldActivate(oModel)}

oStructFke:AddTable("ZYY",{},STR0267) //"Cronograma"

//----------------Estrutura para cria��o do campo-----------------------------
// [01] C Titulo do campo
// [02] C ToolTip do campo
// [03] C identificador (ID) do Field
// [04] C Tipo do campo
// [05] N Tamanho do campo
// [06] N Decimal do campo
// [07] B Code-block de valida��o do campo
// [08] B Code-block de valida��o When do campo
// [09] A Lista de valores permitido do campo
// [10] L Indica se o campo tem preenchimento obrigat�rio
// [11] B Code-block de inicializacao do campo
// [12] L Indica se trata de um campo chave
// [13] L Indica se o campo pode receber valor em uma opera��o de update.
// [14] L Indica se o campo � virtual

oStructFke:AddField(STR0268, STR0269, "ZYY_FILIAL", "C", FwSizeFilial(), 0)								//"Filial"//"Filial do Sistema"
oStructFke:AddField(STR0270, STR0270, "ZYY_PARCE",  "C", GetSX3Cache("E1_PARCELA","X3_TAMANHO"), 0)	//Parcela
oStructFke:AddField(STR0271, STR0271, "ZYY_VENC",   "D", 8,              0)								//"Vencimento"
oStructFke:AddField(STR0271, STR0271, "ZYY_TOTAL",  "N", nTamTot,        nDecTot)						//"Vencimento"

Ft600TAddADZ( oStrADZPro, "ADZPRODUTO" )
Ft600TAddADZ( oStrADZAce, "ADZACESSOR" )

aAux1 := FwStruTrigger("GIO_CUSTO","GIO_VALTOT","A600GIOCUSTO()",.F.,Nil,Nil,Nil)
oStrGIOVE:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

//Inicializa a revis�o quando � inclus�o
If INCLUI
	oStrADY:SetProperty("ADY_PREVIS",MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,"StrZero(1,GetSX3Cache('ADY_PREVIS','X3_TAMANHO'),0)"))	// Revis�o
	oStrADY:SetProperty("ADY_TABELA",MODEL_FIELD_INIT,FwBuildFeature(STRUCT_FEATURE_INIPAD,"AD1->AD1_TABELA"))											// tabela de pre�os da oportunidade
EndIf

//Para modulo Gest�o de Servi�o campo n�o � Necessario Ser Obrigatorio
If nModulo == 28
	oStrADY:SetProperty('ADY_TABELA' ,MODEL_FIELD_OBRIGAT,.F.)
	oStrADY:SetProperty('ADY_TABELA' ,MODEL_FIELD_WHEN   , {|| oModel:GetValue( "ADYMASTER", "ADY_TPCONT" ) <> "4"} )

	oStrADY:SetProperty('ADY_CONDPG' ,MODEL_FIELD_OBRIGAT,.F.)
	oStrADY:SetProperty('ADY_CONDPG' ,MODEL_FIELD_WHEN   , {|| oModel:GetValue( "ADYMASTER", "ADY_TPCONT" ) <> "4"} )

	oStrADY:SetProperty('ADY_TES' ,MODEL_FIELD_OBRIGAT,.F.)
	oStrADY:SetProperty('ADY_TES' ,MODEL_FIELD_WHEN   , {|| oModel:GetValue( "ADYMASTER", "ADY_TPCONT" ) <> "4"} )
EndIf

oStrADZPro:SetProperty("ADZ_FOLDER",MODEL_FIELD_INIT	,FwBuildFeature(STRUCT_FEATURE_INIPAD,"'1'")) // Produto(s)
oStrADZAce:SetProperty("ADZ_FOLDER",MODEL_FIELD_INIT	,FwBuildFeature(STRUCT_FEATURE_INIPAD,"'2'")) // Acessorio(s)

cValidUser := FT600VldUser( "ADZ_PRODUT" )
oStrADZPro:SetProperty("ADZ_PRODUT",MODEL_FIELD_VALID,FwBuildFeature( STRUCT_FEATURE_VALID,"Ft600VProd('ADZPRODUTO') .And. " + cValidUser ) )
oStrADZAce:SetProperty("ADZ_PRODUT",MODEL_FIELD_VALID,FwBuildFeature( STRUCT_FEATURE_VALID,"Ft600VProd('ADZACESSOR') .And. " + cValidUser ) )

cValidUser := FT600VldUser( "ADZ_PRDALO" )
oStrADZPro:SetProperty("ADZ_PRDALO",MODEL_FIELD_VALID,FwBuildFeature(STRUCT_FEATURE_VALID,"At600VdAlo(1) .And. " + cValidUser ) )
oStrADZAce:SetProperty("ADZ_PRDALO",MODEL_FIELD_VALID,FwBuildFeature(STRUCT_FEATURE_VALID,"At600VdAlo(2) .And. " + cValidUser ) )

cValidUser := FT600VldUser( "ADZ_CONDPG" )
oStrADZPro:SetProperty("ADZ_CONDPG",MODEL_FIELD_VALID,FwBuildFeature(STRUCT_FEATURE_VALID," ExistCpo('SE4') .AND. A600VldCPg('ADZPRODUTO') .And. " + cValidUser + ".And. A600VTP09 ('ADZPRODUTO')") )
oStrADZAce:SetProperty("ADZ_CONDPG",MODEL_FIELD_VALID,FwBuildFeature(STRUCT_FEATURE_VALID," ExistCpo('SE4') .AND. A600VldCPg('ADZACESSOR') .And. " + cValidUser + ".And. A600VTP09 ('ADZACESSOR')") )

oStrADZPro:SetProperty("ADZ_PRCVEN",MODEL_FIELD_OBRIGAT,.F.)
oStrADZPro:SetProperty('ADZ_TOTAL'	,MODEL_FIELD_OBRIGAT,.F.)
oStrADZAce:SetProperty("ADZ_PRCVEN",MODEL_FIELD_OBRIGAT,.F.)
oStrADZAce:SetProperty('ADZ_TOTAL'	,MODEL_FIELD_OBRIGAT,.F.)

//----------------------------------------------------------------------------------------------------------------------
// Retira a obrigatoriedade da tabela quando � utilizado agrupador, pois neste caso, ser� utilizado a tabela de pre�os
// das regras de comercializa��o por item
//----------------------------------------------------------------------------------------------------------------------
If SuperGetMv( "MV_FATMNTP",, 1 ) == 4
	oStrADY:SetProperty( "ADY_TABELA", MODEL_FIELD_OBRIGAT, .F. )
EndIf

oModel	:= MPFormModel():New('FATA600' /*<cID>*/,;
      	                     /*<bPre>*/,;
      	                     bTudoOk /*<bPost>*/,;
      	                     bCommit /*<bCommit>*/,;
      	                     bCancel /*<bCancel>*/)

oModel:addFields('ADYMASTER',,oStrADY,)

oModel:addGrid('ADZPRODUTO' /*<cId>*/,;
               'ADYMASTER' /*<cOwner>*/,;
               oStrADZPro /*<oModelStruct>*/,;
               {|oModel,nLine,cAction,cField| Ft600LinePre(oModel,nLine,cAction,cField,1)} /*<bLinePre>*/,;
               bLinePost /*<bLinePost>*/,;
               /*<bPreVal>*/,;
               bPosVldLin /*<bPost>*/,;
               /*<bLoadGrid>*/)
oModel:addGrid('ADZACESSOR' /*<cId>*/,;
               'ADYMASTER' /*<cOwner>*/,;
               oStrADZAce /*<oModelStruct>*/,;
               {|oModel,nLine,cAction,cField| Ft600LinePre(oModel,nLine,cAction,cField,2)} /*<bLinePre>*/,;
               bLinePost /*<bLinePost>*/,;
               /*<bPreVal>*/,;
               bPosVldLin /*<bPost>*/,;
               /*<bLoadGrid>*/)
oModel:addGrid('CRONOFIN' /*<cId>*/,;
               'ADYMASTER' /*<cOwner>*/,;
               oStructFke /*<oModelStruct>*/,;
               /*<bLinePre>*/,;
               /*<bLinePost>*/,;
               /*<bPreVal>*/,;
               /*<bPost>*/,;
               bLoadCro /*<bLoadGrid>*/)

If nModulo == 88 //Gest�o de Transporte de Passageiros

	//-------------------------------------------------------------------------------------------------+
	// Campos Quantidade e Custo unitario n�o podem ser alterados, quando o custo for do tipo ped�gio. |
	// ------------------------------------------------------------------------------------------------+
	oStrGIOVE:SetProperty('GIO_QUANT'	, MODEL_FIELD_WHEN, {|| oModel:GetValue( "GIOCUSTOS", "GIO_UM" ) <> "PD"})
	oStrGIOVE:SetProperty('GIO_CUSUNI', MODEL_FIELD_WHEN, {|| oModel:GetValue( "GIOCUSTOS", "GIO_UM" ) <> "PD"})

	oModel:AddGrid("GINVIAESP", "ADYMASTER", oStrGINVE , , { |oModelGrid| PrVLinGIN(oModelGrid , @oModel)})
	oModel:AddGrid('GIOCUSTOS', 'ADYMASTER', oStrGIOVE,/*{||Ft600LinePre()}*/,/*bLinePost*/, /*bPreVal*/,/*bPosVldLin*/)
	oModel:AddGrid('GIPVEICULO','ADYMASTER', oStrGIPVE,/*{||Ft600LinePre()}*/,/*bLinePost*/, /*bPreVal*/,/*bPosVldLin*/)

	oModel:SetRelation('GINVIAESP',{{'GIN_FILIAL','xFilial("GIN")'},{"GIN_PROPOS","ADY_PROPOS"}},GIN->(IndexKey(1)))
	oModel:SetRelation('GIOCUSTOS',{{'GIO_FILIAL','xFilial("GIO")'},{"GIO_PROPOS","ADY_PROPOS"}},GIO->(IndexKey(1)))
	oModel:SetRelation('GIPVEICULO',{{'GIP_FILIAL','xFilial("GIP")'},{"GIP_PROPOS","ADY_PROPOS"}},GIP->(IndexKey(1)))

	oModel:GetModel("GIOCUSTOS"):SetUniqueLine({"GIO_CUSTO"})

	// ----------------------------------+
	// Nao permite inseir uma nova linha |
	// ----------------------------------+
	oModel:GetModel( 'GINVIAESP' ):SetNoInsertLine()

EndIf

oModel:GetModel('ADYMASTER'):SetDescription(STR0252)	//"Cabe�alho da Proposta"
oModel:GetModel('ADZPRODUTO'):SetDescription(STR0236)	//"Produto"
oModel:GetModel('ADZACESSOR'):SetDescription(STR0237)	//'Acessorio'

If nModulo == 88 //Gest�o de Transporte de Passageiros
	oModel:GetModel('GINVIAESP'):SetDescription(STR0306)   //"Percurso"
	oModel:GetModel('GIOCUSTOS'):SetDescription(STR0294)   //"Custos""
	oModel:GetModel('GIPVEICULO'):SetDescription(STR0295)  //"Ve�culos"
EndIf

//Realiza o relacionamento
oModel:SetRelation('ADZPRODUTO',{{'ADZ_FILIAL','xFilial("ADZ")'},{"ADZ_PROPOS","ADY_PROPOS"},{"ADZ_REVISA","ADY_PREVIS"},{"ADZ_FOLDER","'1'"}},ADZ->(IndexKey(3)))
oModel:SetRelation('ADZACESSOR',{{'ADZ_FILIAL','xFilial("ADZ")'},{"ADZ_PROPOS","ADY_PROPOS"},{"ADZ_REVISA","ADY_PREVIS"},{"ADZ_FOLDER","'2'"}},ADZ->(IndexKey(3)))

// --------------+
// TOTALIZADORES |
// --------------+
//-- Total Geral de Produto
oModel:AddCalc('CALC' /*cId*/,;
               'ADYMASTER' /*cOwner*/,;
               'ADZPRODUTO' /*cIdForm*/,;
               'ADZ_TOTAL' /*cIdField*/,;
               'ADZ__TOTPRD' /*cIdCalc*/,;
               'FORMULA' /*cOperation*/,;
               {||.T.} /*bCondition*/,;
                /*bInitValue*/,;
               STR0283 /*cTitle*/,; // 'Total Geral de Produto'
               {|oMdlCalc,nTotal,xValor,lSum| A600RdpTot(oMdlCalc,nTotal,xValor,lSum,'ADZPRODUTO','ADZ__TOTPRD') },;
               /*nTamanho*/,;
               /*nDecimal*/)
//-- Total Geral de Acessorio
oModel:AddCalc('CALC' /*cId*/,;
               'ADYMASTER' /*cOwner*/,;
               'ADZACESSOR' /*cIdForm*/,;
               'ADZ_TOTAL' /*cIdField*/,;
               'ADZ__TOTACE' /*cIdCalc*/,;
               'FORMULA' /*cOperation*/,;
               {||.T.} /*bCondition*/,;
               /*bInitValue*/,;
               STR0285 /*cTitle*/,; // 'Total Geral de Acessorio'
               {|oMdlCalc,nTotal,xValor,lSum| A600RdpTot(oMdlCalc,nTotal,xValor,lSum,'ADZACESSOR','ADZ__TOTACE') },;
               /*nTamanho*/,;
               /*nDecimal*/)
//-- Total Geral da Proposta
oModel:AddCalc('CALC' /*cId*/,;
               'ADYMASTER' /*cOwner*/,;
               "ADZPRODUTO" /*cIdForm*/,;
               "ADZ_TOTAL" /*cIdField*/,;
               "ADZ__TOTPRO" /*cIdCalc*/,;
               "FORMULA" /*cOperation*/,;
               {||.T.} /*bCondition*/,;
               /*bInitValue*/,;
               STR0286 /*cTitle*/,; // "( A+B )"#"Total Geral da Proposta"
               {|oModel| oModel:GetValue("CALC",'ADZ__TOTPRD')+oModel:GetValue("CALC",'ADZ__TOTACE')} /*bFormula*/,;
               nTamTot /*nTamanho*/,;
               nDecTot /*nDecimal*/)

If nModulo == 88 //Gest�o de Transporte de Passageiros
	oModel:AddCalc('CALC', 'ADYMASTER', 'GIOCUSTOS', 'GIO_VALTOT', 'GIO__CUSTOS', 'SUM', /*bCondition*/, /*bInitValue*/, STR0405 /*cTitle*/, /*bFormula*/) //"Total Geral de Custo Final"
Endif

oModel:GetModel('CALC'):AddEvents('CALC',"ADZ__TOTPRO","ADZ__TOTACE",{|| .T. })	//"Total" 'Acessorio'

//Utiliza��o da grid antiga (GetDados())
oModel:GetModel("ADZPRODUTO"):SetUseOldGrid( .T. )

//Para o modulo Gestao de Servicos desabilita edicao da grid de produtos na proposta comercial
If nModulo == 28
	oModel:GetModel('ADZPRODUTO'):SetNoInsertLine( .T. )
	oModel:GetModel('ADZPRODUTO'):SetNoDeleteLine( .T. )
	oModel:GetModel('ADZPRODUTO'):SetNoUpdateLine( .T. )
Endif

//Permite o Grid sem dados
oModel:GetModel("ADZACESSOR"):SetOptional(.T.)
oModel:GetModel("CRONOFIN"):SetOptional(.T.)

//Utiliza��o da grid antiga (GetDados())
oModel:GetModel("ADZACESSOR"):SetUseOldGrid( .T. )

//Desabilita o Cronograma financeiro para edi��o e no commit
oModel:GetModel('CRONOFIN'):SetNoInsertLine( .T. )
oModel:GetModel('CRONOFIN'):SetNoDeleteLine( .T. )
oModel:GetModel('CRONOFIN'):SetNoUpdateLine( .T. )

//Desabilita o model para o commit
oModel:GetModel('CRONOFIN'):SetOnlyQuery(.T.)

oModel:SetVldActivate( bVldActive )

//Inicializa cronograma financeiro
oModel:SetActivate(bActive)

// ---------------------------------------------------------+
// Ponto de entada para adi��o de totalizadores customizados|
// ---------------------------------------------------------+
If lFta600MDL
	ExecBlock("FATA600MDL" ,.F. ,.F. ,{oModel})
EndIF
Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} FT600VldActivate
Valida o activate do model.
@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//-------------------------------------------------------------------
Static Function FT600VldActivate( oModel )

Local lRet 			:= .T.
Local nOperation	:= oModel:GetOperation()

If ( !Empty( _oMdlOpor ) .And. _oMdlOpor:IsActive() .And. _oMdlOpor:GetOperation() == MODEL_OPERATION_VIEW )
	If nOperation == MODEL_OPERATION_INSERT
		Help(,,"FT600VLDACT",, STR0336 + STR0024 + STR0337, 1, 0 ) //"N�o � poss�vel #Incluir# proposta devido a opera��o da oportunidade ser visualiza��o."
		lRet := .F.
	ElseIf nOperation == MODEL_OPERATION_UPDATE
		Help(,,"FT600VLDACT",, STR0336 + STR0025 + STR0337, 1, 0 ) //"N�o � poss�vel #Alterar# proposta devido a opera��o da oportunidade ser visualiza��o."
		lRet := .F.
	ElseIf nOperation == MODEL_OPERATION_DELETE
		Help(,,"FT600VLDACT",, STR0336 + STR0335 + STR0337, 1, 0 ) //"N�o � poss�vel #Excluir# proposta devido a opera��o da oportunidade ser visualiza��o."
		lRet := .F.
	EndIf
EndIf

If	lRet .AND. nOperation <> MODEL_OPERATION_VIEW .AND. nOperation <> MODEL_OPERATION_INSERT .AND. ADY->ADY_STATUS == "F"
	Help( ,, "FT600VLDACT",, STR0213, 1, 0 )	//Proposta Bloqueada!
	lRet := .F.
EndIf

If lRet .AND. nOperation == MODEL_OPERATION_UPDATE
	oModel:GetModel('ADZPRODUTO'):SetOnlyQuery(.T.)
	oModel:GetModel('ADZACESSOR'):SetOnlyQuery(.T.)
EndIf
Return( lRet )

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Defini��o do interface

@author luiz.jesus
@since 18/03/2014
@version 12
/*/
//-------------------------------------------------------------------
Static Function ViewDef()

Local oView
Local oModel		:= FwLoadModel("FATA600")
Local oStrADY		:= FWFormStruct(2, 'ADY')
Local oStrADZPro	:= FWFormStruct(2, 'ADZ')
Local oStrADZAce	:= FWFormStruct(2, 'ADZ')
Local oStructFke	:= FWFormViewStruct():New()
Local oStrGINVE		:= FWFormStruct(2, 'GIN')
Local oStrGIOVE		:= FWFormStruct(2, 'GIO')
Local oStrGIPVE		:= FWFormStruct(2, 'GIP')
Local oStr4			:= FWCalcStruct(oModel:GetModel('CALC'))
Local lMultVist	 	:= SuperGetMv("MV_MULVIST",,.F.)   				// Multipla Vistorias
Local nOpcADJ 		:= SuperGetMv("MV_FATMNTP",,1) 					//Tratamento do dado na ADJ
Local lFT600BUT		:= ExistBlock("FT600BUT") 						//Ponto de entrada para adicionar botoes na EnchoiceBar
Local lFT600APRV	:= ExistBlock("FT600APRV")						//Ponto de entrada para indicar se serao exibidos as funcoes de aprovacao da proposta
Local lPyme			:= IIF(Type("__lPyme") <> "U",__lPyme,.F.)					// Serie 3 do Protheus
Local lAprova		:= .F.                                                                                //Indica se as op��es de aprova��o devem ser exibidas no A��es Relacionadas
Local aButtons		:= {}
Local oMdlPROD		:= oModel:GetModel('ADZPRODUTO')
Local oMdlACES		:= oModel:GetModel('ADZACESSOR')
Local lGeraOrc		:= SuperGetMv("MV_CRMGORC",,.T.) // O pedido de vendas n�o ser� mais gerado de forma autom�tica ao desabilitar o par�metro. (Inicialmente criado para atender � TDI para n�o gravar mais CJ e CK, ao desabilit�-lo).
Local lOrcSimp	 	:= SuperGetMV('MV_ORCSIMP',, '2') == '1' .AND. HasOrcSimp()

//----------------Estrutura para cria��o do campo-----------------------------
// [01] C Nome do Campo
// [02] C Ordem
// [03] C Titulo do campo
// [04] C Descri��o do campo
// [05] A Array com Help
// [06] C Tipo do campo
// [07] C Picture
// [08] B Bloco de Picture Var
// [09] C Consulta F3
// [10] L Indica se o campo � evit�vel
// [11] C Pasta do campo
// [12] C Agrupamento do campo
// [13] A Lista de valores permitido do campo (Combo)
// [14] N Tamanho Maximo da maior op��o do combo
// [15] C Inicializador de Browse
// [16] L Indica se o campo � virtual
// [17] C Picture Vari�vel

oStructFke:AddField("ZYY_PARCE","01",STR0270,STR0270,{STR0270},"C","@!",Nil,Nil,.F.,Nil)	//"Parcela"
oStructFke:AddField("ZYY_VENC","02",STR0271,STR0271,{STR0271},"D",,Nil,Nil,.F.,Nil)	//"Vencimento"
oStructFke:AddField("ZYY_TOTAL","03",STR0272,STR0272,{STR0272},"N",PesqPict("ADZ","ADZ_TOTAL"),Nil,Nil,.F.,Nil)	//"Total"

oView := FWFormView():New()
oView:SetModel(oModel)

//Adiciona os bot�es em a��es relacionadas
oView:AddUserButton(STR0010,"",{|| A600Servicos(oModel) },,,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE}) //"Servi�os (PMS)"
oView:AddUserButton(STR0058,"",{|| Ft600Impos() },,,{MODEL_OPERATION_VIEW,MODEL_OPERATION_UPDATE} )			//"Impostos"
oView:AddUserButton(STR0017,"",{|| A600TimeV() },,,{MODEL_OPERATION_VIEW,MODEL_OPERATION_UPDATE} )			//"Time de vendas"
If nOpcADJ <> 4
	oView:AddUserButton(STR0291,"",{|| FT600Cat(oModel)},,VK_F4,{MODEL_OPERATION_INSERT,MODEL_OPERATION_VIEW,MODEL_OPERATION_UPDATE})		//'Categoria'
Else
	oView:AddUserButton(STR0319,"",{|| FT600AGrup(oModel),oView:Refresh() },,VK_F4,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE})		//'Agrupadores' ### "Informe a tabela de pre�os"
EndIf

If nModulo == 88
	oView:AddUserButton(STR0307,"",{|oView|If( oModel:getModel('GIOCUSTOS'):Length() < 1 .Or. Empty(FwFldGet("GIO_CUSTO")), Aviso(STR0308, STR0309, {"Ok"} ), GTPA140A(oView)) },,,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE,MODEL_OPERATION_VIEW} ) // "Calcular Custo" # "Planilha de Custos" # "� necess�rio existir pelo menos uma linha na aba 'Custos', para acionar essa op��o"
	// Adiciona o bot�o para impress�o do contrato, apenas na visualiza��o e quando a oportunidade estiver encerrada
	If oModel:GetOperation() == MODEL_OPERATION_VIEW .And. AD1->AD1_STATUS == "9"
		oView:AddUserButton(STR0310,"",{|oView| Ft600ImpCo(oView) },,,{MODEL_OPERATION_VIEW} )	// "Imp. Contrato"
	Endif

	//---------------------------------------------------------------+
	// Soma Valor pedagio ida/volta e atualiza valor total do custo. |
	// --------------------------------------------------------------+
	oView:SetFieldAction('GIN_PEDIDA', {|| FtV600Pedag(oModel), oView:Refresh()})
	oView:SetFieldAction('GIN_PEDVOL', {|| FtV600Pedag(oModel), oView:Refresh()})
EndIf

If nModulo == 28

	oView:AddUserButton(STR0208,"",{|oView|At600OrcView()},,,{MODEL_OPERATION_VIEW} ) 							//'Vis. Orc�am. Serv.'
	oView:AddUserButton(STR0194,"",{|oView|AT600COrc()},,,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE} ) //'Atualiza Orc. Servi�os'
	oView:AddUserButton(STR0195,"",{|oView|At600SeExc()},,,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE} ) //'Remover Orc. Servi�os'
	//oView:AddUserButton(STR0176,"",{||TECA350(A600LdPROD( oModel ))},,, { MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE } ) //"Beneficios"
	//oView:AddUserButton(STR0280,"",{|oView|TECA340(oView,oMdlPROD,oMdlACES,aConfigAlo)},,,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE} ) //'Conf. de Aloca��o'

	If !lPyme
		If	!( IsInCallStack("At270VProp") )
			// Se a execu��o da VIEW n�o for a partir da rotina de Visualiza��o da Vistoria T�cnica, exibe os bot�es da Vistoria T�cnica
			If !lMultVist .And. !lOrcSimp
				oView:AddUserButton(STR0145,"",{|| A600VsVist(/*cCodVis*/,oModel)})	//"Visualizar Vistoria"
				oView:AddUserButton(STR0144,"",{|| TECA280(/*cCodVis*/,oModel)},,,{ MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE }) 		//"Vis.Tec x Proposta"
				oView:AddUserButton(STR0146,"",{|| A600ImpVis(/*cCodVis*/,oModel)},,,{ MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE }) 					//"Importar Vistoria Tecnica"
			ElseIf !lOrcSimp
				oView:AddUserButton(STR0147,"",{|| A600ConVis(oModel)}) 					//"Vistoria(s) T�cnica"
			EndIf
		EndIf
	EndIf

EndIf

If lFT600APRV
	lAprova := ExecBlock("FT600APRV", .F., .F., {oModel})
	If ( ValType(lAprova) <> 'L' )
		lAprova := .F.
	Endif
EndIf

If ( SCJ->CJ_STATUS == 'F' .Or. lAprova ).And. lGeraOrc
   	oView:AddUserButton( STR0015, '', { |oView| Ft600Aprv( .T., oView ) },,,{ MODEL_OPERATION_VIEW } ) //"Aprovar"
    oView:AddUserButton( STR0046, '', { |oView| Ft600Aprv( .F., oView ) },,,{ MODEL_OPERATION_VIEW } ) //"Reprovar"
Endif

oView := CRMXAddAct("ADY",oView) //Adcionar Rotinas no 'A��es relacionadas' do Formul�rio

If ( lFT600BUT )
	aButtons := ExecBlock( "FT600BUT", .F.,.F., {oView} )
	If ( ValType( aButtons ) == 'A' .And. Len( aButtons ) > 0 )
		AEval( aButtons, { |x| oView:AddUserButton( x[1], x[2], x[3], x[4], x[5], x[6] ) } )
	EndIf
EndIf

aSort(oView:aUserButtons,,,{ | x,y | y[1] > x[1] } )

oView:AddField('FORM1' , oStrADY,'ADYMASTER' )
oView:AddGrid('Produt' , oStrADZPro,'ADZPRODUTO' )
oView:AddGrid('Acess' , oStrADZAce,'ADZACESSOR' )
oView:AddGrid('CROFIN' , oStructFke,'CRONOFIN' )
If nModulo == 88 //Gest�o de Transporte de Passageiros
	// Campo Valor Total apenas Visivel
	oStrGIOVE:SetProperty ( 'GIO_VALTOT', MVC_VIEW_CANCHANGE, .F. )
	// Adiciona o componente para estrutura
	oView:AddGrid('ViagEs' , oStrGINVE,'GINVIAESP' )
	oView:AddGrid('Custos' , oStrGIOVE,'GIOCUSTOS' )
	oView:AddGrid('Veicul' , oStrGIPVE,'GIPVEICULO')
EndIf

oView:AddField('FORM9', oStr4,'CALC')

If ( nModulo <> 28 .OR. lPyme .OR. lMultVist )
	oStrADY:RemoveField( 'ADY_CODVIS' )
	oStrADY:RemoveField( 'ADY_SITVIS' )
	oStrADY:RemoveField( 'ADY_VISTEC' )
EndIf

If !( cValToChar( nOpcADJ ) $ "1|4" )
	oStrADY:RemoveField( 'ADY_SINCPR' )
EndIf

oStrADY:RemoveField( 'ADY_HREMIS' )
oStrADY:RemoveField( 'ADY_USREMI' )
oStrADY:RemoveField( 'ADY_DTUPL'  )
oStrADY:RemoveField( 'ADY_HRUPLO' )
oStrADY:RemoveField( 'ADY_USRUPL' )
oStrADY:RemoveField( 'ADY_DTAPRP' )
oStrADY:RemoveField( 'ADY_HRAPRP' )
oStrADY:RemoveField( 'ADY_USRPRP' )
oStrADY:RemoveField( 'ADY_DTPDV'  )
oStrADY:RemoveField( 'ADY_HRPDV'  )
oStrADY:RemoveField( 'ADY_USRPDV' )
oStrADY:RemoveField( 'ADY_DTFAT'  )
oStrADY:RemoveField( 'ADY_HRFAT'  )
oStrADY:RemoveField( 'ADY_USRFAT' )
oStrADY:RemoveField( 'ADY_DTREPR' )
oStrADY:RemoveField( 'ADY_HRREPR' )
oStrADY:RemoveField( 'ADY_USREPR' )
oStrADY:RemoveField( 'ADY_MTREPR' )
oStrADY:RemoveField( 'ADY_OBSREP' )
oStrADY:RemoveField( 'ADY_DTAPRO' )
oStrADY:RemoveField( 'ADY_HRAPRO' )
oStrADY:RemoveField( 'ADY_USAPRO' )
oStrADY:RemoveField( 'ADY_OBSAPR' )
oStrADY:RemoveField( 'ADY_USAPRP' )
oStrADY:RemoveField( 'ADY_USRAPR' )

oStrADZPro:RemoveField("R_E_C_N_O_")
oView:CreateHorizontalBox( 'BOXFORM1', 50)
oView:CreateHorizontalBox( 'MIDDLE', 34)

oView:CreateFolder('ABAS','MIDDLE')  // Pasta que conter� cada uma das guias
oView:AddSheet( 'ABAS', 'ABA01', STR0236 )	//'Produto'
oView:AddSheet( 'ABAS', 'ABA02', STR0237 )	//'Acessorio'
oView:AddSheet( 'ABAS', 'ABA03', STR0238 )	//'Cronograma Financeiro'
If nModulo == 88 //Gest�o de Transporte de Passageiros
	oView:AddSheet( 'ABAS', 'ABA04', STR0306 ) //  "Percurso"
	oView:AddSheet( 'ABAS', 'ABA05', STR0294 ) // "Custos"
	oView:AddSheet( 'ABAS', 'ABA06', STR0295 ) // "Ve�culos"
EndIf
oView:CreateHorizontalBox( 'BOXFORM11', 100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA03')
oView:SetOwnerView('CROFIN','BOXFORM11')

oView:CreateHorizontalBox( 'ID_ABA01' , 100,,, 'ABAS', 'ABA01' )

oView:CreateHorizontalBox( 'ID_ABA02' , 100,,, 'ABAS', 'ABA02' )
If nModulo == 88 //Gest�o de Transporte de Passageiros
	oView:CreateHorizontalBox( 'ID_ABA04' , 100,,, 'ABAS', 'ABA04' )
	oView:CreateHorizontalBox( 'ID_ABA05' , 100,,, 'ABAS', 'ABA05' )
	oView:CreateHorizontalBox( 'ID_ABA06' , 100,,, 'ABAS', 'ABA06' )
EndIf
oView:CreateHorizontalBox( 'BOXFORM9', 16)
oView:SetOwnerView('FORM9','BOXFORM9')

oView:SetOwnerView('FORM1','BOXFORM1')

oView:SetOwnerView( 'Produt' , 'ID_ABA01')

oView:SetOwnerView( 'Acess' , 'ID_ABA02')
If nModulo == 88 //Gest�o de Transporte de Passageiros
	oView:SetOwnerView( 'ViagEs' , 'ID_ABA04')
	oView:SetOwnerView( 'Custos' , 'ID_ABA05')
	oView:SetOwnerView( 'Veicul' , 'ID_ABA06')
EndIf

oView:AddIncrementField('Acess' , 'ADZ_ITEM' )

oView:AddIncrementField('Produt' , 'ADZ_ITEM' )
If nModulo == 88 //Gest�o de Transporte de Passageiros
	oView:AddIncrementField('ViagEs' , 'GIN_ITEM' )
	oView:AddIncrementField('Custos' , 'GIO_ITEM' )
	oView:AddIncrementField('Veicul' , 'GIP_ITEM' )
EndIf

//Refaz cronograma financeiro ao trocar de Aba
oView:SetVldFolder({|| Ft600Folcg()})

oView:ShowInsertMessage(.F.)
oView:ShowUpdateMessage(.F.)
oView:SetCloseOnOk({|| .T.})	//Realizar o fechamento da Proposta ap�s as confirma��o
Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} At600Tipo9
Cria a Tela para preenchimento das parcelas

@author luiz.jesus

@since 18/03/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function At600Tipo9(cCodTp9,oModel,cFolder,cE4_COND)

Local aArea		:= GetArea()				//Salva a area anterior
Local nOpcA		:= 0						//Opcao de escolha  OK - CANCELA
Local aTipo9		:= {}						//Array com as parcelas
Local nP			:= 0
Local nNAnt		:= N						//Salva o N
Local nOpAux		:= oModel:GetOperation()
Local nOpetarion	:= Iif((nOpAux==3).OR.(nOpAux==4),3,1)
Local cUsado		:= str2bin("x       x     x x       x       x       x       x       x       x       x       x       x       x       x       x  x    ")
Local lAlterCron	:= SuperGetMv("MV_ALTERCR",,.F.)	// Parametro que define se a condi��o de pagamento parte do ADZ_DT1VEN

//Objetos da Tela
Local oDlgModal	:= Nil
Local oGetTotal	:= Nil
Local oPanelMain	:= Nil
Local oLayMain	:= Nil
Local oDlgLayParc	:= Nil
Local oDlgLayCalc	:= Nil
Local oDlgLayCab	:= NIL
Local oGetProd	:= NIL
Local oGetDProd	:= NIL

//variaveis da tela
Local cProd		:= oModel:GetModel(cFolder):GetValue("ADZ_PRODUT")
Local cDProd		:= oModel:GetModel(cFolder):GetValue("ADZ_DESCRI")

//variaveis compartilhadas
Private nTotal	:= oModel:GetModel(cFolder):GetValue("ADZ_TOTAL") //Valor total do Item
Private nSaldo	:= nTotal
Private nSalPer	:= (nSaldo / nTotal) * 100
Private oGetSaldo
Private oGetParc
Private oGetSalPer

//Variaveis usada na getDados
Private lRefresh
Private aHeader	:= {}
Private aCols		:= {}

//�����������������������������������Ŀ
//� Monta cabecalho                   �
//�������������������������������������
AADD(aHeader,{STR0270,;								//01 - X3TITULO()            //"Parcela"
              "TEMP_ITEM",;							//02 - X3_CAMPO
              "@E 999",;								//03 - X3_PICTURE
              3,;										//04 - X3_TAMANHO
              0,;										//05 - X3_DECIMAL
              "NaoVazio()",;						//06 - X3_VALID
              cUsado,;								//07 - X3_USADO
              "C",;									//08 - X3_TIPO
              "",;									//09 - X3_ARQUIVO
              ""})									//10 - X3_CONTEXT

AADD(aHeader,{STR0007,;								//01 - X3TITULO()            //"Valor"
              "L4_VALOR",;							//02 - X3_CAMPO
              "@E 999,999.99",;						//03 - X3_PICTURE
              10,;									//04 - X3_TAMANHO
              2,;										//05 - X3_DECIMAL
              "Positivo()",;						//06 - X3_VALID
              cUsado,;								//07 - X3_USADO
              "N",;									//08 - X3_TIPO
              "",;									//09 - X3_ARQUIVO
              ""})									//10 - X3_CONTEXT

AADD(aHeader,{STR0274,;								//01 - X3TITULO()		//"Percentual"
              "L4_COMP",;							//02 - X3_CAMPO
              "@E 999.9999",;						//03 - X3_PICTURE
              8,;										//04 - X3_TAMANHO
              2,;										//05 - X3_DECIMAL
              "Positivo()",;						//06 - X3_VALID
              cUsado,;								//07 - X3_USADO
              "N",;									//08 - X3_TIPO
              "",;									//09 - X3_ARQUIVO
              ""})									//10 - X3_CONTEXT

AADD(aHeader,{STR0275,;								//01 - X3TITULO()		//"Data"
              "L4_DATA",;							//02 - X3_CAMPO
              "",;									//03 - X3_PICTURE
              8,;										//04 - X3_TAMANHO
              0,;										//05 - X3_DECIMAL
              "NaoVazio()",;						//06 - X3_VALID
              cUsado,;								//07 - X3_USADO
              "D",;									//08 - X3_TIPO
              "",;									//09 - X3_ARQUIVO
              ""})									//10 - X3_CONTEXT

aTipo9 := Ft600GetTipo09()

//���������������������������������������Ŀ
//�Se as parcelas devem ser recalculadas  �
//�����������������������������������������
If	Len(aTipo9) > 0
	For nP := 1 To Len(aTipo9)
		If	Alltrim(aTipo9[nP,5]) == Alltrim( oModel:GetModel(cFolder):GetValue('ADZ_ITEM') ) .And.;
			Alltrim(aTipo9[nP,6]) == Alltrim( oModel:GetModel(cFolder):GetValue('ADZ_FOLDER') )
			aadd(aCols, {StrZero(len(aCols)+1,3),;							//Item
			             aTipo9[nP,3],;										//Valor
			             NoRound( (aTipo9[nP,3] / nTotal) * 100 , 4 ),;	//Percentual
			             aTipo9[nP,2],;										//Data
			             .F.})												//Deletado
		Endif
	Next nP
Endif

If	Len(aCols) == 0
	//�����������������������������������Ŀ
	//� Monta o Array com 1 elemento vazio�
	//�������������������������������������
	aCols			:= Array(1, Len(aHeader) + 1)
	aCols[1][1]	:= StrZero(1,3)
	aCols[1][2]	:= 0
	aCols[1][3]	:= 0
	aCols[1][4]	:= If(lAlterCron .AND. ! Empty(oModel:GetModel(cFolder):GetValue("ADZ_DT1VEN")), oModel:GetModel(cFolder):GetValue("ADZ_DT1VEN"), dDatabase) ///CTOD("")
	aCols[1][5]	:= .F.		//Linha de controle de DELECAO
EndIf

n	:= Len(aCols)

//Se executado via �rea de trabalho
If Empty(aRotina)
	aRotina := Menudef()
EndIf

oDlgModal	:= FWDialogModal():New()
oDlgModal:SetTitle(STR0054) //"Valor da Parcela e Vencimento"
oDlgModal:SetBackground(.F.)
oDlgModal:SetEscClose(.F.)
oDlgModal:SetSize(270,248)
oDlgModal:EnableFormBar(.T.)
oDlgModal:SetCloseButton(.F.)
oDlgModal:CreateDialog()
oDlgModal:CreateFormBar()

oDlgModal:AddButton(STR0395,{|| (nOpcA := 1,IIF(At600Tp9Tot(aCols,cCodTp9,oModel,cFolder),oDlgModal:DeActivate(),nOpcA:=0)) },STR0395,,.T.,.F.,.T.)	//"Salvar" ## "Salvar"
oDlgModal:AddButton(STR0396,{|| At600Tp9GP()},STR0396,,.T.,.F.,.T.)																								//"Parcelar" ## "Parcelar"
oDlgModal:AddButton(STR0397,{|| At600Tp9LP()},STR0397,,.T.,.F.,.T.)																								//"Limpar" ## "Limpar"
oDlgModal:AddButton(STR0066,{|| oDlgModal:DeActivate()},STR0066,,.T.,.F.,.T.)																					//"Cancelar" ## "Cancelar"

oPanelMain	:= oDlgModal:GetPanelMain()

oLayMain	:= FWLayer():New()
oLayMain:Init(oPanelMain, .F.)

oLayMain:AddLine("LINE_CABEC",  25, .T.)
oLayMain:AddLine("LINE_PARCEL", 55, .T.)
oLayMain:AddLine("LINE_CALC",   20, .T.)

oLayMain:AddCollumn("COL_CABEC", 100, .T., "LINE_CABEC")
oLayMain:AddCollumn("COL_PARCEL", 100, .T., "LINE_PARCEL")
oLayMain:AddCollumn("COL_CALC",   100, .T., "LINE_CALC")

oLayMain:AddWindow("COL_CABEC",  "WIN_CABEC",  STR0407, 100, .F., .F.,, "LINE_CABEC")	//"Produto"
oLayMain:AddWindow("COL_PARCEL", "WIN_PARCEL", STR0398, 100, .F., .F.,, "LINE_PARCEL")	//Parcelas
oLayMain:AddWindow("COL_CALC",   "WIN_CALC",   STR0272, 100, .F., .F.,, "LINE_CALC")	//Total

oDlgLayCab		:= oLayMain:GetWinPanel("COL_CABEC", "WIN_CABEC", "LINE_CABEC")
@ 04,02 SAY STR0407 SIZE 25,10 PIXEL OF oDlgLayCab  //"Produto"
@ 02,35 MSGET oGetProd  VAR cProd  SIZE 105,10 WHEN .F. PICTURE "@!" PIXEL OF oDlgLayCab
@ 18,02 SAY STR0408 SIZE 25,10 PIXEL OF oDlgLayCab  //"Descri��o"
@ 16,35 MSGET oGetDProd VAR cDProd SIZE 200,10 WHEN .F. PICTURE "@!" PIXEL OF oDlgLayCab

oDlgLayParc				:= oLayMain:GetWinPanel("COL_PARCEL", "WIN_PARCEL", "LINE_PARCEL")
oGetParc					:= MSGetDados():New(1,1,105,237,nOpetarion,Nil,"AlwaysTrue","+TEMP_ITEM",.T.,,,.F.,999,"At600Tp9FOk",,,,oDlgLayParc)
oGetParc:oBrowse:bDelete	:= {|| aCols[n,Len(aCols[n])]	:= !aCols[n,Len(aCols[n])], At600Tp9Rf(), oGetParc:oBrowse:Refresh(.F.)}
oGetParc:Refresh(.T.)

oDlgLayCalc	:= oLayMain:GetWinPanel( "COL_CALC", "WIN_CALC", "LINE_CALC" )
@ 05,05 SAY STR0392 SIZE 20,10 PIXEL OF oDlgLayCalc  //Saldo:
@ 03,25 MSGET oGetSaldo VAR nSaldo SIZE 54,10 WHEN .F. PICTURE "@E 999,999,999.99" PIXEL  OF oDlgLayCalc

@ 05,85 SAY STR0393 SIZE 23,10 PIXEL OF oDlgLayCalc //Saldo %:
@ 03,110 MSGET oGetSalPer VAR nSalPer SIZE 50,10 WHEN .F. PICTURE "@E 999.9999" PIXEL  OF oDlgLayCalc

@ 05,165 SAY STR0394 SIZE 20,10 PIXEL OF oDlgLayCalc //Total:
@ 03,180 MSGET oGetTotal VAR nTotal SIZE 54,10 WHEN .F. PICTURE "@E 999,999,999.99" PIXEL  OF oDlgLayCalc

At600Tp9Rf()
oDlgModal:Activate()

N := nNAnt

RestArea(aArea)
Return(nOpcA == 1)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At600Tp9GP
@description	Funcao Gera Parcelas da tela em At600Tipo9.
@sample		At600Tp9GP()
@author		CRM e Servi�os
@since		11/07/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At600Tp9GP()

Local oDialog 		:= Nil
Local oPanel			:= Nil
Local cQtdParc		:= StrZero(1,3)
Local dVenc			:= dDatabase
Local nI				:= 0
Local nX				:= 0
Local nVlrParcela		:= 0
Local nDiaVenc		:= 0
Local nMesVenc		:= 0
Local nAnoVenc		:= 0
Local nTtParcelado	:= 0
Local nQtdParc		:= 0
Local nParcMan		:= 0
Local lContinua		:= .F.
Local aDelet			:= {}
Local nLimiteParc		:= SuperGetMv("MV_NUMPARC",,999)
Local bConfirmar		:= {|| Iif(val(cQtdParc)>nLimiteParc .Or. val(cQtdParc)==0,;
                                Help( ,, 'A600TP9GP',, STR0399 + Str(nLimiteParc), 1, 0 )  ,; //"O numero de parcelas deve ser maior que 0 e menor que "
                                (lContinua := .T., oDialog:DeActivate()) )  }
Local nColItm			:= aScan(aHeader,{|x|Alltrim(x[2])=="TEMP_ITEM" }) //coluna de valores
Local nColVlr			:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_VALOR" }) //coluna de valores
Local nColPer			:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_COMP" }) //coluna de valores
Local nColData		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_DATA" }) //coluna de valores
Local nColDel			:= Len(aHeader) +1 //coluna de delecao

//-------------------------------------------------------------------
// valida Saldo
//-------------------------------------------------------------------
If nSaldo <= 0
	Help(,1,"A600TP9GP",,STR0400,1) //"N�o h� saldo para parcelar"
	Return
EndIf

//-------------------------------------------------------------------
// Monta o janela pesquisa.
//-------------------------------------------------------------------
oDialog := FWDialogModal():New()
oDialog:SetTitle( STR0401 )    //"Gerar Parcelas"
oDialog:SetBackGround( .F. )
oDialog:SetEscClose( .T. )
oDialog:SetSize( 100, 150 )
oDialog:EnableFormBar( .T. )
oDialog:SetCloseButton(.F.)
oDialog:CreateDialog()
oDialog:CreateFormBar()
oDialog:AddButton( STR0065, bConfirmar, STR0065 , , .T., .F., .T., )			//"OK"
oDialog:AddButton( STR0066,{|| oDialog:DeActivate()  },STR0066,,.T.,.F.,.T.)	//"Cancelar"

//-------------------------------------------------------------------
// Recupera o container.
//-------------------------------------------------------------------
oPanel := oDialog:GetPanelMain()

//-------------------------------------------------------------------
// Insere as op��es de tela.
//-------------------------------------------------------------------
@ 15,05 SAY STR0402  SIZE 70,10 PIXEL	OF oPanel  //"Quantidade de Parcelas:"
@ 25,05 MSGET cQtdParc  SIZE 60,10 PICTURE "@999999" PIXEL HASBUTTON OF oPanel
@ 15,85 SAY STR0403  SIZE 70,10 PIXEL OF oPanel  //"Primeiro Vencimento:"
@ 25,85 MSGET dVenc  SIZE 60,10 PIXEL HASBUTTON OF oPanel

//-------------------------------------------------------------------
// Exibe a janela.
//-------------------------------------------------------------------
oDialog:Activate()

If lContinua

	nQtdParc		:= Val(cQtdParc)
	nVlrParcela	:= NoRound( nSaldo / nQtdParc , 2)

	nDiaVenc		:= Day(dVenc)
	nMesVenc		:= Month(dVenc)
	nAnoVenc		:= Year(dVenc)

	//-------------------------------------------------------------------
	// Retira parcelas invalidas inseridas manualmente
	//-------------------------------------------------------------------
	For nI := 1 to len(aCols)
		If aCols[nI][nColDel] .Or. aCols[nI][nColVlr] <= 0
			aAdd( aDelet , aCols[nI][nColItm] )
		EndIf
	Next nI

	For nI := 1 to len(aDelet)
		Adel(aCols, aScan(aCols,{|x|Alltrim(x[nColItm])==aDelet[nI] }) )
		ASize(aCols,Len(aCols)-1)
	Next nI

	//-------------------------------------------------------------------
	// Geracao das parcelas
	//-------------------------------------------------------------------
	nQtdParc += nParcMan := Len(aCols)
	For nI := 1 to nQtdParc

		//-------------------------------------------------------------------
		// Nao altera parcelas inseridas manualmente
		//-------------------------------------------------------------------
		If nParcMan >= nI
			aCols[nI][nColItm] := StrZero(nI,3)
			Loop
		EndIf

		//-------------------------------------------------------------------
		// Nao incrementa data na primeira parcela automatica
		//-------------------------------------------------------------------
		If nI > (1 + nParcMan)
			If nMesVenc == 12
				nMesVenc := 1
				nAnoVenc++
			Else
				nMesVenc++
			EndIf
		EndIf

		//-------------------------------------------------------------------
		// Calcula diferenca para a ultima parcela
		//-------------------------------------------------------------------
		If nI == nQtdParc
			nTtParcelado := 0
			For nX := 1 to len(aCols)
				If !aCols[nX][nColDel]
					nTtParcelado += aCols[nX][nColVlr]
				EndIf
			Next nX

			nVlrParcela := nTotal - nTtParcelado
		EndIf

		//-------------------------------------------------------------------
		// Grava parcela
		//-------------------------------------------------------------------
		ASize(aCols,nI)
		aCols[nI] := Array(5)
		aCols[nI][nColItm] := StrZero(nI,3)
		aCols[nI][nColVlr] := nVlrParcela
		aCols[nI][nColPer] := NoRound( (nVlrParcela / nTotal) * 100 , 4 )
		aCols[nI][nColData] := STOD(StrZero(nAnoVenc,4) + StrZero(nMesVenc,2) + StrZero(nDiaVenc,2))
		aCols[nI][nColDel] := .F.			//Linha de controle de DELECAO

	Next nI

	//-------------------------------------------------------------------
	// Atualiza Saldo na tela
	//-------------------------------------------------------------------
	nTtParcelado := 0
	For nX := 1 to len(aCols)
		If !aCols[nX][nColDel]
			nTtParcelado += aCols[nX][nColVlr]
		EndIf
	Next nX

	nSaldo := nTotal - nTtParcelado
	oGetSaldo:Refresh()

	nSalPer := ( nSaldo / nTotal) * 100
	oGetSalPer:Refresh()

EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At600Tp9LP
Funcao Limpa Parcelas da tela em At600Tipo9.
@sample		At600Tp9LP()
@author		CRM e Servi�os
@since		11/07/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At600Tp9LP()

Local nColItm		:= aScan(aHeader,{|x|Alltrim(x[2])=="TEMP_ITEM" }) //coluna de valores
Local nColVlr		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_VALOR" }) //coluna de valores
Local nColPer		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_COMP" }) //coluna de valores
Local nColData	:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_DATA" }) //coluna de valores
Local nColDel		:= Len(aHeader) +1 //coluna de delecao

//-------------------------------------------------------------------
// Limpa objeto da GetDados
//-------------------------------------------------------------------
aCols					:= {}
aCols					:= Array(1, Len(aHeader) + 1)
aCols[1][nColItm]		:= StrZero(1,3)
aCols[1][nColVlr]		:= 0
aCols[1][nColPer]		:= 0
aCols[1][nColData]	:= dDatabase
aCols[1][nColDel]		:= .F.			//Linha de controle de DELECAO

//-------------------------------------------------------------------
// Atualiza Saldo na tela
//-------------------------------------------------------------------
nSaldo := nTotal
oGetSaldo:Refresh()

nSalPer := ( nSaldo / nTotal) * 100
oGetSalPer:Refresh()
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At600Tp9Rf
Funcao Refresh dos objetos de tela em At600Tipo9.
@sample		At600Tp9Rf()
@author		CRM e Servi�os
@since		11/07/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At600Tp9Rf()

Local aColsParc	:= aClone(aCols)
Local nSomaItens	:= 0
Local nI			:= 0
Local nColItm		:= aScan(aHeader,{|x|Alltrim(x[2])=="TEMP_ITEM"}) //coluna de valores
Local nColVlr		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_VALOR"}) //coluna de valores
Local nColPer		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_COMP"}) //coluna de valores
Local nColData	:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_DATA"}) //coluna de valores
Local nColDel		:= Len(aHeader) +1 //coluna de delecao

//-------------------------------------------------------------------
// Soma dos itens, ignora itens deletados
//-------------------------------------------------------------------
For nI := 1 to len(aColsParc)
	If !aColsParc[nI][nColDel]
		nSomaItens += aColsParc[nI][nColVlr]
	EndIf
Next nI

//-------------------------------------------------------------------
// Atualiza Saldo na tela
//-------------------------------------------------------------------
nSaldo := nTotal - nSomaItens
oGetSaldo:Refresh()

nSalPer := ( nSaldo / nTotal) * 100
oGetSalPer:Refresh()
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At600Tp9FOk
Funcao field ok do getDados em At600Tipo9.
@sample		At600Tp9FOk()
@author		CRM e Servi�os
@since		11/07/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At600Tp9FOk()

Local nLinPosNow	:= oGetParc:oBrowse:nAt //linha alterada
Local nColPosNow	:= oGetParc:oBrowse:nColPos  //coluna alterada
Local nSomaItens	:= 0
Local nI			:= 0
Local nVlrNew		:= &(ReadVar()) //novo valor do campo alterado

Local nColItm		:= aScan(aHeader,{|x|Alltrim(x[2])=="TEMP_ITEM" }) //coluna de valores
Local nColVlr		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_VALOR" }) //coluna de valores
Local nColPer		:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_COMP" }) //coluna de valores
Local nColData	:= aScan(aHeader,{|x|Alltrim(x[2])=="L4_DATA" }) //coluna de valores
Local nColDel		:= Len(aHeader) +1 //coluna de delecao

//-------------------------------------------------------------------
// Atualiza valores na aCols
//-------------------------------------------------------------------
If nColPosNow == nColVlr
	aCols[nLinPosNow][nColVlr] := nVlrNew
	aCols[nLinPosNow][nColPer] := NoRound( (nVlrNew / nTotal) * 100 , 4 )
ElseIf nColPosNow == nColPer
	aCols[nLinPosNow][nColVlr] :=  NoRound( ( nVlrNew / 100 ) * nTotal , 2)
EndIf

//-------------------------------------------------------------------
// Soma dos itens, ignora itens deletados
//-------------------------------------------------------------------
For nI:=1 to len(aCols)
	If !aCols[nI][nColDel]
		nSomaItens += aCols[nI][nColVlr]
	EndIf
Next nI

//-------------------------------------------------------------------
// Atualiza Saldo na tela
//-------------------------------------------------------------------
nSaldo := nTotal - nSomaItens
oGetSaldo:Refresh()

nSalPer := ( nSaldo / nTotal) * 100
oGetSalPer:Refresh()
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} A600CompPr

Fun��o que faz a compara��o das propostas.

@sample		A600CompPr()

@author		CRM e Servi�os
@since		29/04/2013
@version	P12
/*/
//------------------------------------------------------------------------------
Function A600CompPr()

Local aArea		:= GetArea()
Local aAreaADY	:= ADY->(GetArea())
Local oDlgProp	:= Nil
Local aListBox	:= {}
Local aRet     	:= {}
Local oChkMar  	:= Nil
Local oLbx     	:= Nil
Local oDlg			:= Nil
Local oOk      	:= LoadBitmap(GetResources(), 'LBOK')
Local oNo      	:= LoadBitmap(GetResources(), 'LBNO')
Local lChk     	:= .F.
Local lTeveMarc	:= .F.
Local cVar     	:= ""
Local oMdlOpor	:= FT600MdlOport()
Local oMdlAD1		:= oMdlOpor:GetModel("AD1MASTER")
Local lRetorno 	:= .T.
Local cFilADY		:= xFilial("ADY")

DbSelectArea("ADY")
ADY->(DbSetOrder(2))	//ADY_FILIAL+ADY_OPORTU+ADY_REVISA+ADY_PROPOS
If ADY->(DbSeek(cFilADY+oMdlAD1:GetValue("AD1_NROPOR")))
	While ( ADY->(!Eof()) .AND. ADY->ADY_FILIAL == cFilADY .AND. ADY->ADY_OPORTU == oMdlAD1:GetValue("AD1_NROPOR") )
		aAdd(aListBox,{IIF(ADY->ADY_SINCPR,.T.,.F.),ADY->ADY_PROPOS,dToc(ADY->ADY_DATA)})
		ADY->(DbSkip())
	EndDo
EndIf

If Len(aListBox) > 0

	aSort(aListBox,,,{ |x,y| x[2] < y[2] } )

	DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD
	DEFINE MSDIALOG  oDlgProp Title STR0128 From 0, 0 To 255, 450 Pixel
	oDlgProp:cToolTip := STR0244 //"Tela para Sele��o de Propostas"
	oDlgProp:cTitle := STR0245	//"Selecione as Propostas Comerciais para compara��o"
	@ 10, 10 Listbox oLbx Var cVar Fields Header ' ', STR0246, STR0247 Size 210, 095 Of oDlg Pixel //"Proposta"	"Data de Emiss�o"
	oLbx:SetArray(aListBox)
	oLbx:bLine := {|| {IIf( aListBox[oLbx:nAt, 1], oOk, oNo ),;
	                   aListBox[oLbx:nAt, 2], ;
	                   aListBox[oLbx:nAt, 3]}}
	oLbx:BlDblClick := {|| aListBox[oLbx:nAt, 1] := !aListBox[oLbx:nAt, 1], Ft600VerTodos( aListBox, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
	oLbx:cToolTip   := oDlgProp:cTitle
	oLbx:lHScroll   := .F. // NoScroll
	@ 112, 10 CheckBox oChkMar Var  lChk Prompt STR0248 Message STR0249 Size 40, 007 Pixel Of oDlgProp; //'Todos'###'Marca / Desmarca Todos'
	                                     on Click Ft600Marca(lChk, @aListBox, oLbx)
	DEFINE SButton From 111, 155 Type 1 Action ( IIf(FT600RetProp(@aRet, aListBox),(Ft600CR("ADY",aListBox[oLbx:nAt,2],aRet),oDlgProp:End()), MsgStop(STR0253)) ) OnStop STR0250 Enable Of oDlgProp //'Confirma a Sele��o' "N�o h� Propostas Marcadas."
	DEFINE SButton From 111, 188 Type 2 Action ( IIf(lTeveMarc, aRet := aMarcadas, .T.), oDlgProp:End() )                                                         OnStop STR0251 Enable Of oDlgProp //'Abandona a Sele��o'
	ACTIVATE MSDIALOG oDlgProp CENTERED

Else
	lRetorno := .F.
	Aviso(STR0241,STR0242,{STR0243})	//"Aten�ao"##"N�o h� Propostas a serem comparadas!"##"Ok"
EndIf

RestArea(aAreaADY)
RestArea(aArea)
Return(lRetorno)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600CR

Programa de comparacao das revisoes da Proposta Comercial.

@sample  Ft600CR(cCodVSup)

@Param   cCodVSup - Codigo do supervisor

@return  lAchou -  Variavel l�gica com flag informando se achou ou n�o

@author  Servi�os/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------

Function Ft600CR(cAlias,cPropos,aPropos)

Local aLstHeader	:= {}
Local aLstCols	:= {}
Local cLine		:= "{||}"
Local aCmp			:= {}
Local cVar     	:= ""
Local nOpca		:= 0
Local oDlg
Local oBold
Local oFont1
Local oBmp
Local oList
Local oOk			:= LoadBitmap( GetResources(), "LBOK" )
Local oNo			:= LoadBitmap( GetResources(), "LBNO" )
Local lRet			:= .T.

Default cAlias 	:= "ADY"
Default cPropos	:= ""
Default aPropos	:= {}

DbSelectArea(cAlias)
DbSetOrder(1)

If !Empty(cPropos)
	Dbseek(xFilial(cAlias) + cPropos)
EndIf

lRet := Ft600Rev((cAlias)->ADY_PROPOS, @aLstHeader, @aLstCols, @cLine,(cAlias)->ADY_OPORTU,aPropos)

If Len(aLstCols) > 1

	DEFINE DIALOG oDlg TITLE STR0063 FROM 0,-300 TO 470,600 OF oMainWnd PIXEL //"Comparador das revis�es"

	DEFINE FONT oBold 	NAME "Arial"   		SIZE 0, -13 BOLD
	DEFINE FONT oFont1	NAME "Courier New" 	SIZE 7,15
	@  0, 0  BITMAP oBmp RESNAME "PROJETOAP" oF oDlg SIZE 30, 1000 NOBORDER WHEN .F. PIXEL ADJUST
	@ 03, 40 SAY STR0064 FONT oBold PIXEL //"Selecione as revis�es que deseja comparar"
	@ 14, 30 TO 16 ,450 LABEL '' OF oDlg   PIXEL
	@ 40, 30 LISTBOX oList VAR cVar Fields SIZE 420, 170 ON DBLCLICK (Ft600Click(@aLstCols,oList:nAt)) OF oDlg PIXEL FONT oFont1
	oList:aHeaders := aLstHeader
	oList:SetArray(aLstCols)
	oList:bLine := &(cLine)
	oList:nFreeze := 1
	@ 22 , 412 BUTTON STR0023  SIZE 039, 013 OF oDlg PIXEL Action(Ft600Vis(aLstCols,oList:nAt))//"Visualizar"
	@ 218, 369 BUTTON STR0065  SIZE 039, 013 OF oDlg PIXEL Action(iIf(Ft600ROk(aLstCols,@aCmp),(nOpca := 1,oDlg:End()),)) //"OK"
	@ 218, 412 BUTTON STR0066  SIZE 039, 013 OF oDlg PIXEL Action( nOpca := 0, oDlg:End()) //"Cancelar"

	ACTIVATE MSDIALOG oDlg CENTERED

	If nOpca == 1
		Processa({||Ft600Cmp(aCmp)}, STR0067, STR0068,.F.)	//"Processando"###"Comparando as revis�es da Proposta comercial..."
	EndIf
Else
	Aviso(STR0069,STR0070,{STR0065})	//Proposta selecionada n�o possui revis�es!
	lRet := .F.
EndIf

Return lRet

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Cmp

Programa de comparacao das revisoes da Proposta Comercial.

@sample  Ft600Cmp

@author  Servi�os/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------

Static Function Ft600Cmp(aCmp)

Local oDlg
Local oTree
Local oTree2
Local oMenu
Local oMenu2
Local aOpVComp := {}
Local aOrigem  := {}
Local aDestino := {}
Local aButtons := {}
Local aObjects := {}
Local aPosObj  := {}
Local aInfo    := {}
Local aSize    := MsAdvSize(.T.)

/*
ESTRUTURA DO RETORNO DA Ft600Tree
[1] - Alias
[2] - Chave
[3] - Descricao
[4] - Cargo
[5] - Cargo Pai
[6] - Tipo Diferenca (N - Normal, C - Change, E - Deleted, I - Inserted)
[7] - E Recurso ? (Truee,False)
[8] - Indica tipo do produto(1-Produto, 2-Acessorio)
*/

//Monta um array com a estrutura do tree de oportunidade de venda
//que sera utilizado como base na comparacao.
aOrigem := Ft600Tree(aCmp[1])

//Monta um array com a estrutura do tree de oportunidade de venda
//que sera utilizado como base na comparacao.
aDestino:= Ft600Tree(aCmp[2])


//Monta um array com a estrutura do tree de oportunidade de venda
//da comparacao entre as versoes.
aOpVComp:= Ft600Compara(aOrigem,aDestino)

//Monta a  tela com o tree da versao base e com o tree da versao
//resultado da comparacao.
aAdd( aObjects, { 100, 100, .T., .T., .F. } )
aAdd( aObjects, { 100, 100, .T., .T., .F. } )
aInfo  := { aSize[1],aSize[2],aSize[3],aSize[4],3,3 }
aPosObj:= MsObjSize( aInfo, aObjects, .T.,.T. )

DEFINE MSDIALOG oDlg TITLE STR0254 FROM aSize[7],0 TO aSize[6],aSize[5] OF oMainWnd PIXEL	//"Compara��o das Revis�es"

	MENU oMenu POPUP
		MENUITEM STR0023 ACTION Ft600VisDet(@oTree,aOrigem)	//"Visualizar"
	ENDMENU

	MENU oMenu2 POPUP
		MENUITEM STR0023 ACTION Ft600VisDet(@oTree2,aOpVComp)	//"Visualizar"
		MENUITEM STR0255 ACTION Ft600Item(oTree,oTree2,aOrigem,aOpVComp,aCmp[1],aCmp[2])	//"Comparar"
	ENDMENU

	oTree:= dbTree():New(aPosObj[1,1], aPosObj[1,2],aPosObj[1,3],aPosObj[1,4], oDlg,,,.T.)
	oTree:bRClicked := {|o,x,y|  oMenu:Activate(x-100,y-200,oTree) } // Posi��o x,y em rela��o a Dialog
	oTree:bChange   := {|| Ft600CtrMenu(1,oMenu,oTree)}
	oTree:lShowHint := .F.
	Ft600MontaTree(@oTree,aOrigem)

	oTree2:= dbTree():New(aPosObj[2,1], aPosObj[2,2],aPosObj[2,3],aPosObj[2,4], oDlg,,,.T.)
	oTree2:bRClicked := {|o,x,y|  oMenu2:Activate(x-800,y-200,oTree2) } // Posi��o x,y em rela��o a Dialog
	oTree2:bChange   := {|| Ft600CtrMenu(2,oMenu2,oTree2)}
	oTree2:lShowHint := .F.
	Ft600MontaTree(@oTree2,aOpVComp)

	AAdd(aButtons, {"DBG09",       {|| Ft600Inf()}, STR0256})	//"Legenda"
   	AAdd(aButtons, {"PMSSETADOWN", {|| Ft300Nav(1,aOpVComp,@oTree,@oTree2)}, STR0257, STR0257})	//"Proxima Diferenca"
   	AAdd(aButtons, {"PMSSETAUP",   {|| Ft300Nav(2,aOpVComp,@oTree,@oTree2)}, STR0258, STR0258})	//"Diferenca Anterior"

ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg, {||oDlg:End()} ,{||oDlg:End()},,aButtons)

Return Nil

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600DesbP

Interface de desbloqueio de proposta

@sample     A600DesbP(  )

@param		 ExpC - Codigo do Vendedor superior

@return     ExpL: Verdadeiro

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function A600DesbP(cCodVSup)

Local oGrpProp      		//Objeto Grupo Box
Local oGrpPesq	   			//Objeto Grupo Box
Local oBtn1         		//Objeto Button Pesquisar
Local oBtn2    				//Objeto Button Proximo
Local oBtn3    				//Objeto Button Visualizar
Local oBtn4   				//Objeto Button Aprovar
Local oBtn5    				//Objeto Button Sair
Local oBtn6                 //Objeto Button Reprovar
Local oBtn7   				//Objeto Button Sair
Local oGet1    				//Objeto Get
Local oPanel1  				//Objeto Panel
Local oPanel2 				//Objeto Panel
Local oBrwPBlq 			    //Objeto Browse Proposta bloqueadas
Local cGet1 := Space(60)    //Espaco na caixa de texto
Local aPropBlq := A600BProp(cCodVSup)
Static oDlg 				//Objeto MSDialog Proposta(s) bloqueada(s)

If Len(aPropBlq) > 0

	DEFINE MSDIALOG oDlg TITLE STR0088 FROM 000, 000  TO 340,900 PIXEL  //Proposta(s) Bloqueada(s)

	oPanel1 := TPanel():New(00,00,/*cText*/,oDlg,/*oFont*/,/*lCentered*/,;
	                        /*uParam7*/,/*nClrText*/,/*nClrBack*/,;
	                        350,497,/*lLowered*/,/*lRaised*/)

	oPanel2 := TPanel():New(00,00,/*cText*/,oDlg,/*oFont*/,/*lCentered*/,;
	                        /*uParam7*/,/*nClrText*/,/*nClrBack*/,;
	                        350,026,/*lLowered*/,/*lRaised*/)

	@ 001, 001 GROUP oGrpProp TO 143, 400 PROMPT STR0089 OF oPanel1 PIXEL  //"Proposta bloqueadas criadas pelos vendedores em sua c�lula de vendas"
	@ 000, 001 GROUP oGrpPesq TO 024, 200 PROMPT STR0090 OF oPanel2 PIXEL //"Pesquisa"
	@ 008, 004 MSGET oGet1 VAR cGet1 SIZE 093, 010 OF oPanel2 PIXEL
	@ 008, 108 BUTTON oBtn1 PROMPT STR0091 SIZE 037, 012 OF oPanel2 PIXEL ACTION IIF(A600Pesq(oBrwPBlq,cGet1, .T. ),oGet1:SetColor(CLR_BLACK,CLR_WHITE),oGet1:SetColor(CLR_WHITE,CLR_HRED))//"&Pesquisar"
	@ 008, 156 BUTTON oBtn2 PROMPT STR0092 SIZE 037, 012 OF oPanel2 PIXEL ACTION IIF(A600Pesq(oBrwPBlq,cGet1, .F. ),oGet1:SetColor(CLR_BLACK,CLR_WHITE),oGet1:SetColor(CLR_WHITE,CLR_HRED))//"Proximo"
	@ 008, 214 BUTTON oBtn3 PROMPT STR0093 SIZE 037, 012 OF oPanel2 PIXEL ACTION VisualProp(oBrwPBlq:aArray[oBrwPBlq:nAt,5])//"&Visualizar"
	@ 008, 262 BUTTON oBtn4 PROMPT STR0125 SIZE 037, 012 OF oPanel2 PIXEL ACTION IIF(A600RProp(oBrwPBlq,cCodVSup),oDlg:End(),Nil) //"Atualizar"
	@ 008, 310 BUTTON oBtn5 PROMPT STR0094 SIZE 037, 012 OF oPanel2 PIXEL ACTION IIF(A600AProp(oBrwPBlq),oDlg:End(),Nil)//"Aprovar"
	@ 008, 358 BUTTON oBtn6 PROMPT STR0046 SIZE 037, 012 OF oPanel2 PIXEL ACTION IIF(A600Reprov(oBrwPBlq),IIF(A600RProp(oBrwPBlq,cCodVSup),oDlg:End(),Nil) ,Nil)//"Reprovar"
	@ 008, 406 BUTTON oBtn7 PROMPT STR0097 SIZE 037, 012 OF oPanel2 PIXEL ACTION oDlg:End()//"Sair"
	oBrwPBlq := FWBrwProp(oPanel1,aPropBlq)

	// Don't change the Align Order
	oPanel1:Align := CONTROL_ALIGN_ALLCLIENT
	oPanel2:Align := CONTROL_ALIGN_BOTTOM

	ACTIVATE MSDIALOG oDlg CENTERED

Else
	AVISO(STR0096,STR0098,{STR0099},1)  //"N�o h� proposta(s) bloqueada(s) para aprova��o"//"Fechar"
EndIf

Return(.T.)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} FwBrwProp

Browse para marcacao da(s) proposta(s) bloqueada(s)

@sample     FwBrwProp(  )

@param		 ExpO1 - Objeto oPanel1
@param		 ExpA2 - Proposta(s) bloqueada(s)

@return     ExpL: Verdadeiro/Falso

@author     Victor Bitencourt
@since      08/09/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Static Function FwBrwProp(oPanel1,aPropBlq)

Local oBrowse   						   					//Objeto Browse
Local aBrowse  	:= aPropBlq        					  	//Array com a(s) proposta(s) bloqueada(s)
Local nRow 		:= 09  		   						  	//coordenada vertical.
Local nCol      	:= 03 	   		   						//coordenada horizontal.
Local nWidth    	:= 392			   						//largura em pixels do objeto.
Local nHeight   	:= 130		  	    	 				//altura em pixels do objeto.
Local aHeaders  	:={STR0100,STR0101,STR0102,STR0103}    //t�tulo dos campos no cabe�alho. ##"Proposta"#"Data"#"Entidade"#"Nome"##
Local aColSizes 	:={30,30,35,142}           				// largura das colunas.
Local bLDblClick 	:= {|| }								//bloco de codigo que ser� executado quando clicar duas vezes no objeto.
Local uParam20 	:= .F.    								//Compatibilidade.
Local lPixel    	:=.T.    							    //Considera as coordenadas passadas em pixels.
Local uParam24  	:=.F.    							    //Compatibilidade.


oBrowse := TCBrowse():New(nRow,nCol,nWidth,nHeight,/*bLine*/,aHeaders,aColSizes,;
                          oPanel1,/*cField*/,/*uValue1*/,/*uValue2*/,/*bChange*/,bLDblClick,;
                          /*bRClick*/,/*oFont*/,/*oCursor*/,/*nClrFore*/,/*nClrBack*/,/*cMsg*/,;
                          uParam20,/*cAlias*/,lPixel,/*bWhen*/,uParam24,/*bValid*/,/*lHScroll*/,/*lVScroll*/)

oBrowse:SetArray(aBrowse)
oBrowse:bLine := {|| {;
aBrowse[oBrowse:nAt,1],;
aBrowse[oBrowse:nAt,2],;
aBrowse[oBrowse:nAt,3],;
aBrowse[oBrowse:nAt,4];
}}

//����������������������������������������Ŀ
//� Troca a imagem no duplo click do mouse.�
//������������������������������������������
oBrowse:bLDblClick := {||VisualProp(aBrowse[oBrowse:nAt,5]),oBrowse:DrawSelect()}

// Scroll type
oBrowse:nScrollType := 0

Return(oBrowse)

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} A600TimeV

Exibicao do time de vendas associado a oportunidade da proposta atual.

@sample  A600TimeV

@author  Servi�os/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------

Static Function A600TimeV()

Local aArea		:= GetArea()							// Armazena a area atual
Local aAreaSA3		:= SA3->(GetArea())					// Armazena o posicionamento do SA3
Local aAreaAD2		:= AD2->(GetArea())					// Armazena o posicionamento do AD2
Local aAreaSUM		:= SUM->(GetArea())					// Armazena o posicionamento do SUM
Local aVend		:= {}									// Lista de vendedores
Local oMdlOpor	:= FT600MdlOport()
Local oMdlAD1 		:= oMdlOpor:GetModel("AD1MASTER")
Local cOportun		:= oMdlAD1:GetValue("AD1_NROPOR")
Local cRevisa	 	:= oMdlAD1:GetValue("AD1_REVISA")
Local cFilAD2		:= xFilial("AD2")						// Filial da tabela AD2
Local cFilSA3		:= xFilial("SA3")						// Filial da tabela SA3
Local cFilSUM		:= xFilial("SUM")						// Filial da tabela SUM
Local oDlg			:= Nil  								// Objeto da tela
Local oLBox		:= Nil									// Objeto da Listbox

Default cRevisa := ""

//Seleciona o indice utilizado para cada tabela
DbSelectArea("SA3")
DbSetOrder(1)	//A3_FILIAL+A3_COD

DbSelectArea("SUM")
DbSetOrder(1)	//A3_FILIAL+A3_COD

DbSelectArea("AD2")
DbSetOrder(1)	//AD2_FILIAL+AD2_NROPOR+AD2_REVISA+AD2_VEND
DbSeek(cFilAD2+cOportun+cRevisa)

	//Percorre o time de vendas da oportunidade associada
	While !AD2->(Eof()) 			.AND.;
		AD2->AD2_FILIAL	== cFilAD2	.AND.;
		AD2->AD2_NROPOR	== cOportun	.AND.;
		AD2->AD2_REVISA	== cRevisa

		SA3->(DbSeek(cFilSA3+AD2->AD2_VEND))	//Posiciona Vendedor
		SUM->(DbSeek(cFilSUM+SA3->A3_CARGO))	//Localiza o cargo do vendedor


		//Armazena os dados
		AAdd(aVend,{AD2->AD2_VEND,AllTrim(Capital(SA3->A3_NOME)),AllTrim(Capital(SUM->UM_DESC))})

		AD2->(DbSkip())

	End

	//Se encontrou vendedores para a oportunidade, monta a tela
	//com a listbox para exibicao do time
	If Len(aVend) > 0

		DEFINE MSDIALOG oDlg TITLE STR0017 + " - " + STR0042 + cOportun FROM 0,0 TO 300,665 PIXEL  //"Time de vendas"###"Oportunidade:"

		//Label
		@ 03,03 TO 145,295 LABEL STR0017 PIXEL OF oDlg

		//Listbox
		@ 12,08 ListBox oLBox Fields HEADER STR0043,STR0044,STR0045;  //"Codigo"###"Nome"###"Cargo"
		Size 280,126 Of oDlg Pixel

		//Atribuicao do conteudo da listbox
		oLBox:SetArray(aVend)
		oLBox:bLine := {||{	aVend[oLBox:nAt,01],;
					 		aVend[oLBox:nAT,02],;
							aVend[oLBox:nAT,03]}}

		//Botoes
		DEFINE SBUTTON FROM 005,300 TYPE 1 ENABLE OF oDlg Action (oDlg:End())

		ACTIVATE MSDIALOG oDlg CENTERED

	Else
		Help("",1,"FT600TIMVEN",,STR0041,1) //"Time de vendas n�o encontrado para a oportunidade desta proposta"
	EndIf

RestArea(aAreaSA3)
RestArea(aAreaAD2)
RestArea(aAreaSUM)
RestArea(aArea)

Return Nil

//-----------------------------------------------------------------------------------------
/*/	{Protheus.doc} Ft600Impos

Esta funcao efetua os calculos de impostos (ICMS,IPI,ISS,etc) com base nas funcoes fiscais,
a fim de possibilitar ao usuario o valor de desembolso financeiro.

@sample  Ft600Impos

@author  Servi�os/CRM
@since   29/04/2014
@version P12
/*/
//-----------------------------------------------------------------------------------------
Static Function Ft600Impos()

Local aArea		 := GetArea()
Local aAreaSA1	 := SA1->(GetArea())
Local aAreaADZ   := ADZ->(GetArea())
Local aTitles    := {STR0058}	//"Impostos"
Local nX         := 0
Local nPrcLista  := 0
Local nValMerc   := 0
Local nDesconto  := 0
Local nAcresFin  := 0
Local nQtdPeso   := 0
Local nItem      := 0
Local oDlg			:= NIL
Local oFolder		:= NIL
Local nZ         := 0
Local aCols		 := {}
Local oModel	 := FWModelActive()
Local nOperation := oModel:GetOperation()
Local oMdlADZ1    := oModel:GetModel("ADZPRODUTO")
Local oStructADZ1 := oMdlADZ1:GetStruct()
Local aCamposADZ := oStructADZ1:GetFields()
Local oMdlADZ2    := oModel:GetModel("ADZACESSOR")
Local cF600Cla	  := ""
Local nBkp		  := IIf (Type("N")<>"U", N, Nil)

Local nCodPro    := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_PRODUT"})	//Posicao do campo ADZ_PRODUT
Local nQtdVen    := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_QTDVEN"})	//Posicao do campo ADZ_QTDVEN
Local nTes       := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_TES"})	//Posicao do campo ADZ_TES
Local nValor     := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_TOTAL"})  //Posicao do campo ADZ_VALOR
Local nPrUnit    := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_PRCTAB"}) //Posicao do campo ADZ_PRCTAB
Local nPrcVen    := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_PRCVEN"}) //Posicao do campo ADZ_PRCVEN
Local nValDes    := aScan(aCamposADZ,{|x| AllTrim(x[3])=="ADZ_VALDES"}) //Posicao do campo ADZ_VALDES
Local cFilSB1		:= xFilial("SB1")
Local cFilSB2		:= xFilial("SB2")
Local cFilSF4		:= xFilial("SF4")
Local lDescSai	:= Iif(GetNewPar('MV_DESCSAI','1') == "2",.T.,.F.)

//Posiciona Registros
DbSelectArea("SA1")
DbSetOrder(1)

MsSeek(xFilial("SA1")+If(!Empty(M->ADY_CLIENT),M->ADY_CLIENT,M->ADY_CLIENT)+M->ADY_LOJENT)
//Inicializa a funcao fiscal
MaFisSave()
MaFisEnd()

MaFisIni(Iif(Empty(M->ADY_CLIENT),M->ADY_CODIGO,M->ADY_CLIENT),; 							// 1-Codigo Cliente/Fornecedor
         Iif(!Empty(M->ADY_LOJENT),M->ADY_LOJENT,M->ADY_LOJA),; 							// 2-Loja do Cliente/Fornecedor
         "C",; 							// 3-C:Cliente , F:Fornecedor
         "N",; 							// 4-Tipo da NF
         Nil,;
         Nil,;
         Nil,;
         Nil,;
         Nil,;
         "MATA461",; 							// 10-Nome da rotina que esta utilizando a funcao
         Nil,;
         Nil,;
         If(SubsTr(M->ADY_ENTIDA,1,1)<> "1" .AND. Empty(M->ADY_CLIENT),M->ADY_CODIGO + M->ADY_LOJA,"")) // 13- Codigo e Loja do Prospect

	//Na argentina o calculo de impostos depende da serie.
	If cPaisLoc == 'ARG'
		MaFisAlt('NF_SERIENF',LocXTipSer('SA1',MVNOTAFIS))
	Endif

	//Agrega os itens para a funcao fiscal
	DbSelectArea("ADZ")
	DbGotop()

	For nZ := 1 TO 2
		If nZ == 1
			aCols := oMdlADZ1:ACOLS
		Else
			aCols := oMdlADZ2:ACOLS
		EndIf

		For nX := 1 to Len(aCols)
			//Verifica se a linha foi deletada
			If ( !oMdlADZ1:IsDeleted() .And. !Empty(aCols[nX][nCodPro]))
				//Posiciona Registros
				SB1->(dbSetOrder(1))
				If SB1->(MsSeek(cFilSB1+aCols[nX][nCodPro]))
					nQtdPeso := aCols[nX][nQtdVen]*SB1->B1_PESO
				EndIf
				SB2->(dbSetOrder(1))
				SB2->(MsSeek(cFilSB2+aCols[nX][nCodPro]+SB1->B1_LOCPAD))
				SF4->(dbSetOrder(1))
				SF4->(MsSeek(cFilSF4+aCols[nX][nTes]))

				//Calcula o preco de lista
				nValMerc  := aCols[nX][nValor]
				nPrcLista := aCols[nX][nPrUnit]
				nQtdPeso  := 0
				nItem++
				If ( nPrcLista == 0 )
					nPrcLista := A410Arred(nValMerc/aCols[nX][nQtdVen],"ADZ_PRCVEN")
				EndIf
				nAcresFin := A410Arred(aCols[nX][nPrcVen]*SE4->E4_ACRSFIN/100,"D2_PRCVEN")
				nValMerc  += A410Arred(nAcresFin*aCols[nX][nQtdVen],"D2_TOTAL")
				nDesconto := A410Arred(nPrcLista*aCols[nX][nQtdVen],"D2_DESCON")-nValMerc
				nDesconto := IIf(nDesconto==0,aCols[nX][nValDes],nDesconto)
				nDesconto := Max(0,nDesconto)
				nPrcLista += nAcresFin

				//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
				If cPaisLoc=="BRA" .or. lDescSai
					nValMerc  += nDesconto
				Endif

				//Agrega os itens para a funcao fiscal
				MaFisAdd((aCols[nX][nCodPro]),;   	// 1-Codigo do Produto ( Obrigatorio )
				         (aCols[nX][nTes]),;	   			// 2-Codigo do TES ( Opcional )
				         (aCols[nX][nQtdVen]),;    			// 3-Quantidade ( Obrigatorio )
				         nPrcLista,;		   					// 4-Preco Unitario ( Obrigatorio )
				         nDesconto,;    						// 5-Valor do Desconto ( Opcional )
				         "",;	   		   					// 6-Numero da NF Original ( Devolucao/Benef )
				         "",;								// 7-Serie da NF Original ( Devolucao/Benef )
				         0,;				   					// 8-RecNo da NF Original no arq SD1/SD2
				         0,;				   					// 9-Valor do Frete do Item ( Opcional )
				         0,;									// 10-Valor da Despesa do item ( Opcional )
				         0,;				   					// 11-Valor do Seguro do item ( Opcional )
				         0,;				   					// 12-Valor do Frete Autonomo ( Opcional )
				         nValMerc,;							// 13-Valor da Mercadoria ( Obrigatorio )
				         0)				   					// 14-Valor da Embalagem ( Opiconal )

				SB1->(dbSetOrder(1))
				If SB1->(MsSeek(cFilSB1+aCols[nX][nCodPro]))
					nQtdPeso := aCols[nX][nQtdVen]*SB1->B1_PESO
				Endif

				//Altera peso para calcular frete
				MaFisAlt("IT_PESO",nQtdPeso,nItem)
				MaFisAlt("IT_PRCUNI",nPrcLista,nItem)
				MaFisAlt("IT_VALMERC",nValMerc,nItem)
				//���������������������������������������������Ŀ
				//�Tratamento efetuado para atender ao calculo  �
				//�do FCI.									    �
				//�����������������������������������������������
				N := nX		//Incializa��o manual da vari�vel N para verificar o aCols
				cF600Cla := CodSitTri()
				MaFisAlt("IT_CLASFIS", cF600Cla,nX)
			EndIf
			dbSelectArea("ADZ")
			dbSkip()
		Next nX

	Next nY

//Monta a tela de exibicao dos valores fiscais
DEFINE MSDIALOG oDlg TITLE OemToAnsi(STR0062) FROM 09,00 TO 28,80 //"Planilha Financeira"
oFolder := TFolder():New(001,001,aTitles,{"HEADER"},oDlg,,,, .T., .F.,315,140)

//Folder 1
MaFisRodape(1,oFolder:aDialogs[1],,{005,001,310,60},Nil,.T.)

@ 070,005 SAY RetTitle("F2_FRETE")		SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
@ 070,105 SAY RetTitle("F2_SEGURO")		SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
@ 070,205 SAY RetTitle("F2_DESCONT")	SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
@ 085,005 SAY RetTitle("F2_FRETAUT")	SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
@ 085,105 SAY RetTitle("F2_DESPESA")	SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
@ 085,205 SAY RetTitle("F2_VALFAT")		SIZE 40,10 PIXEL OF oFolder:aDialogs[1]
@ 070,050 MSGET MaFisRet(,"NF_FRETE")		PICTURE PesqPict("SF2","F2_FRETE",16,2)		SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 070,150 MSGET MaFisRet(,"NF_SEGURO")  	PICTURE PesqPict("SF2","F2_SEGURO",16,2)	SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 070,250 MSGET MaFisRet(,"NF_DESCONTO")	PICTURE PesqPict("SF2","F2_DESCONTO",16,2)	SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 085,050 MSGET MaFisRet(,"NF_AUTONOMO")	PICTURE PesqPict("SF2","F2_FRETAUT",16,2)	SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 085,150 MSGET MaFisRet(,"NF_DESPESA")		PICTURE PesqPict("SF2","F2_DESPESA",16,2)	SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 085,250 MSGET MaFisRet(,"NF_BASEDUP")		PICTURE PesqPict("SF2","F2_VALFAT",16,2)	SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 105,005 TO 106,310 PIXEL OF oFolder:aDialogs[1]
@ 110,005 SAY OemToAnsi(STR0060)   SIZE 40,10 PIXEL OF oFolder:aDialogs[1] //"Total da Nota"
@ 110,050 MSGET MaFisRet(,"NF_TOTAL")      PICTURE PesqPict("SF2","F2_VALBRUT",16,2) 	SIZE 50,07 PIXEL WHEN .F. OF oFolder:aDialogs[1]
@ 110,270 BUTTON OemToAnsi(STR0061)			SIZE 040,11 FONT oFolder:aDialogs[1]:oFont ACTION oDlg:End() OF oFolder:aDialogs[1] PIXEL	//"Sair"

ACTIVATE MSDIALOG oDlg CENTERED

MaFisEnd()
MaFisRestore()

N := nBkp

RestArea(aAreaADZ)
RestArea(aAreaSA1)
RestArea(aArea)

Return

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600GetCrono
@description	Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
             	Cronograma Financeiro para passar para os outros fontes que comp�em o FATA600,
             	evitando assim, a declara��o de vari�veis Private.
@sample		Ft600Crono( )
@return		aCronoFin: Array do Cronograma (Retorna a vari�vel statica do cronograma financeiro.)
@author		Thamara Villa Jacomo
@since			09/01/2014
@version		P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600GetCrono()

Return( aCronoFin )

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600GetAloc

Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
Cronograma Financeiro para passar para os outros fontes que comp�em o FATA600,
evitando assim, a declara��o de vari�veis Private.

@sample     Ft600GetAloc( )

@return     aConfigAlo: Configuracao da aloca��o

@author     Thamara Villa Jacomo
@since      09/01/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600GetAloc()

Return( aConfigAlo )

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600SetAloc
Seta a configura��o da aloca��o.
@sample     Ft600SetAloc( aCfgAlo )
@return     Nenhum
@author     Thamara Villa Jacomo
@since      09/01/2014
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function Ft600SetAloc( aXX )

Default	aXX	:= {}

aConfigAlo := aXX
Return

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600GetBen()

Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
Beneficio para passar para os outros fontes que comp�em o FATA600,
evitando assim, a declara��o de vari�veis Private.

@sample     FT600GetBen( )

@return     _aTFFCOD_: Array dos codigos do item do RH

@author     totvs
@since      01/06/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function FT600GetBen()

Return( _aTFFCOD_ )

Function FT600SetBen( aBenef )
	_aTFFCOD_ := aBenef
Return

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600GetVis()

Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
Beneficio para passar para os outros fontes que comp�em o FATA600,
evitando assim, a declara��o de vari�veis Private.

@sample     FT600GetVis( )

@return     _lVistoria_: Logico

@author     totvs
@since      08/06/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function FT600GetVis()

Return( _lVistoria_ )

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} FT600SetVis()

Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
Beneficio para passar para os outros fontes que comp�em o FATA600,
evitando assim, a declara��o de vari�veis Private.

@sample     FT600SetVis( )

@return

@author     totvs
@since      08/06/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function FT600SetVis( lVistoria )

	_lVistoria_ := lVistoria
Return

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600GetTipo09
Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
array aTipo09 para passar para os outros fontes que comp�em o FATA600,
evitando assim, a declara��o de vari�veis Private.
@sample     Ft600GetTipo09( )
@return	ExpA = Array com o conte�do da vari�vel aTipo09
@author     Thamara Villa
@since      13/01/2014
@version    P12.1.7
/*/
//-----------------------------------------------------------------------------------------
Function Ft600GetTipo09()

Return( aTipo09 )

//-----------------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600SetTipo09
Devido ao fracionamento dos fontes, � necess�rio guardar o conte�do da vari�vel est�tica do
array aTipo09 para passar para os outros fontes que comp�em o FATA600,
evitando assim, a declara��o de vari�veis Private.
@sample     Ft600SetTipo09( )
@param 		ExpA = Array com o conte�do da vari�vel aTipo09
@return	 Nil
@author     Thamara Villa
@since      13/01/2014
@version    P12.1.7
/*/
//-----------------------------------------------------------------------------------------
Function Ft600SetTipo09(aRef)

aTipo09	:= aClone(aRef)
Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600TAddADZ
Centraliza a inclus�o dos gatilhos no model.
@sample 	Ft600TAddADZ( oStruct, cMdlDetail )
@param		oStruct		, Objeto	, Estrutura dos campos
			cMdlDetail		, Caracter	, Nome do ModelGrid que o gatilho foi disparado.
@Return   	Nenhum
@author	Anderson Silva
@since		10/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Static Function Ft600TAddADZ( oStruct, cMdlDetail )

Local aAux1 	:= {}
Local aAux2 	:= {}
Local aAux3 	:= {}
Local aAux4 	:= {}
Local aAux5 	:= {}
Local aAux6	:= {}
Local aAux7 	:= {}
Local aAux8 	:= {}
Local aAux9	:= {}
Local aAux10	:= {}
Local aAux11	:= {}
Local aAux12	:= {}
Local aAux13	:= {}
Local aAux14	:= {}
Local aAux15	:= {}
Local aAux16	:= {}
Local aAux17	:= {}
Local aAux18	:= {}
Local aAux19	:= {}
Local aAux20	:= {}

//Cria��o de Gatilhos para preencher os campos de Produto
aAux1 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_DESCRI" /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_DESCRI','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)

oStruct:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4])

aAux2 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_UM"     /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_UM','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

aAux3 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_MOEDA"  /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_MOEDA','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux3[1],aAux3[2],aAux3[3],aAux3[4])

aAux4 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_TES"    /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_TES','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux4[1],aAux4[2],aAux4[3],aAux4[4])

aAux5 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_QTDVEN" /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_QTDVEN','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux5[1],aAux5[2],aAux5[3],aAux5[4])

aAux6 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_PRCTAB" /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_PRCTAB','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux6[1],aAux6[2],aAux6[3],aAux6[4])

aAux7 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_PRCVEN" /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_PRCVEN','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux7[1],aAux7[2],aAux7[3],aAux7[4])

aAux8 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_CONDPG" /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_CONDPG','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       "FT600CdTrg('ADZ_PRODUT','ADZ_CONDPG','" + cMdlDetail + "')" /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux8[1],aAux8[2],aAux8[3],aAux8[4])

aAux9 := FwStruTrigger("ADZ_PRODUT" /*cDom*/,;
                       "ADZ_TPPROD" /*cCDom*/,;
                       "FT600Trigger('ADZ_PRODUT','ADZ_TPPROD','" + cMdlDetail + "')" /*cRegra*/,;
                       .F. /*lSeek*/,;
                       Nil /*cAlias*/,;
                       0   /*nOrdem*/,;
                       Nil /*cChave*/,;
                       Nil /*cCondic*/,;
                       Nil /*cSequen*/)
oStruct:AddTrigger(aAux9[1],aAux9[2],aAux9[3],aAux9[4])

aAux10 := FwStruTrigger("ADZ_QTDVEN" /*cDom*/,;
                        "ADZ_TOTAL"  /*cCDom*/,;
                        "FT600Trigger('ADZ_QTDVEN','ADZ_TOTAL','" + cMdlDetail + "')" /*cRegra*/,;
                        .F. /*lSeek*/,;
                        Nil /*cAlias*/,;
                        0   /*nOrdem*/,;
                        Nil /*cChave*/,;
                        Nil /*cCondic*/,;
                        Nil /*cSequen*/)
oStruct:AddTrigger(aAux10[1],aAux10[2],aAux10[3],aAux10[4])

aAux11 := FwStruTrigger("ADZ_MOEDA"  /*cDom*/,;
                        "ADZ_PRCTAB" /*cCDom*/,;
                        "FT600Trigger('ADZ_MOEDA','ADZ_PRCTAB','" + cMdlDetail + "')" /*cRegra*/,;
                        .F. /*lSeek*/,;
                        Nil /*cAlias*/,;
                        0   /*nOrdem*/,;
                        Nil /*cChave*/,;
                        Nil /*cCondic*/,;
                        Nil /*cSequen*/)
oStruct:AddTrigger(aAux11[1],aAux11[2],aAux11[3],aAux11[4])

aAux12 := FwStruTrigger("ADZ_MOEDA"  /*cDom*/,;
                        "ADZ_PRCVEN" /*cCDom*/,;
                        "FT600Trigger('ADZ_MOEDA','ADZ_PRCVEN','" + cMdlDetail + "')" /*cRegra*/,;
                        .F. /*lSeek*/,;
                        Nil /*cAlias*/,;
                        0   /*nOrdem*/,;
                        Nil /*cChave*/,;
                        Nil /*cCondic*/,;
                        Nil /*cSequen*/)
oStruct:AddTrigger(aAux12[1],aAux12[2],aAux12[3],aAux12[4])

If	ADZ->(ColumnPos("ADZ_TABAGR")) > 0
	// Quanto o campo ADZ_TABAGR existir no dicion�rio de dados, leva em considera��o a regra de sua aplica��o
	aAux13 := FwStruTrigger("ADZ_TABAGR" /*cDom*/,;
	                        "ADZ_PRCTAB" /*cCDom*/,;
	                        "FT600Trigger('ADZ_TABAGR','ADZ_PRCTAB','" + cMdlDetail + "')" /*cRegra*/,;
	                        .F. /*lSeek*/,;
	                        Nil /*cAlias*/,;
	                        0   /*nOrdem*/,;
	                        Nil /*cChave*/,;
	                        Nil /*cCondic*/,;
	                        Nil /*cSequen*/)
	oStruct:AddTrigger(aAux13[1],aAux13[2],aAux13[3],aAux13[4])

	aAux14 := FwStruTrigger("ADZ_TABAGR" /*cDom*/,;
	                        "ADZ_PRCVEN" /*cCDom*/,;
	                        "FT600Trigger('ADZ_TABAGR','ADZ_PRCVEN','" + cMdlDetail + "')" /*cRegra*/,;
	                        .F. /*lSeek*/,;
	                        Nil /*cAlias*/,;
	                        0   /*nOrdem*/,;
	                        Nil /*cChave*/,;
	                        Nil /*cCondic*/,;
	                        Nil /*cSequen*/)
	oStruct:AddTrigger(aAux14[1],aAux14[2],aAux14[3],aAux14[4])

	aAux15 := FwStruTrigger("ADZ_TABAGR" /*cDom*/,;
	                        "ADZ_TOTAL"  /*cCDom*/,;
	                        "FT600Trigger('ADZ_TABAGR','ADZ_TOTAL','" + cMdlDetail + "')" /*cRegra*/,;
	                        .F. /*lSeek*/,;
	                        Nil /*cAlias*/,;
	                        0   /*nOrdem*/,;
	                        Nil /*cChave*/,;
	                        Nil /*cCondic*/,;
	                        Nil /*cSequen*/)
	oStruct:AddTrigger(aAux15[1],aAux15[2],aAux15[3],aAux15[4])
EndIf

aAux16 := FwStruTrigger("ADZ_PRCVEN" /*cDom*/,;
                        "ADZ_TOTAL"  /*cCDom*/,;
                        "FT600Trigger('ADZ_PRCVEN','ADZ_TOTAL','" + cMdlDetail + "')" /*cRegra*/,;
                        .F. /*lSeek*/,;
                        Nil /*cAlias*/,;
                        0   /*nOrdem*/,;
                        Nil /*cChave*/,;
                        Nil /*cCondic*/,;
                        Nil /*cSequen*/)
oStruct:AddTrigger(aAux16[1],aAux16[2],aAux16[3],aAux16[4])

aAux17 := FwStruTrigger("ADZ_DESCON" /*cDom*/,;
                        "ADZ_DESCON" /*cCDom*/,;
                        "FT600Trigger('ADZ_DESCON','ADZ_DESCON','" + cMdlDetail + "')" /*cRegra*/,;
                        .F. /*lSeek*/,;
                        Nil /*cAlias*/,;
                        0   /*nOrdem*/,;
                        Nil /*cChave*/,;
                        Nil /*cCondic*/,;
                        Nil /*cSequen*/)
oStruct:AddTrigger(aAux17[1],aAux17[2],aAux17[3],aAux17[4])

aAux18 := FwStruTrigger("ADZ_VALDES" /*cDom*/,;
                        "ADZ_VALDES" /*cCDom*/,;
                        "FT600Trigger('ADZ_VALDES','ADZ_VALDES','" + cMdlDetail + "')" /*cRegra*/,;
                        .F. /*lSeek*/,;
                        Nil /*cAlias*/,;
                        0   /*nOrdem*/,;
                        Nil /*cChave*/,;
                        Nil /*cCondic*/,;
                        Nil /*cSequen*/)
oStruct:AddTrigger(aAux18[1],aAux18[2],aAux18[3],aAux18[4])

aAux19  := FwStruTrigger("ADZ_TOTAL" /*cDom*/,;
                         "ADZ_TOTAL" /*cCDom*/,;
                         "A600CroFinance()" /*cRegra*/,;
                         .F. /*lSeek*/,;
                         Nil /*cAlias*/,;
                         0   /*nOrdem*/,;
                         Nil /*cChave*/,;
                         Nil /*cCondic*/,;
                         Nil /*cSequen*/)
oStruct:AddTrigger(aAux19[1],aAux19[2],aAux19[3],aAux19[4])

aAux20  := FwStruTrigger("ADZ_DT1VEN" /*cDom*/,;
                         "ADZ_DT1VEN" /*cCDom*/,;
                         "A600CroFinance()" /*cRegra*/,;
                         .F. /*lSeek*/,;
                         Nil /*cAlias*/,;
                         0   /*nOrdem*/,;
                         Nil /*cChave*/,;
                         Nil /*cCondic*/,;
                         Nil /*cSequen*/)
oStruct:AddTrigger(aAux20[1],aAux20[2],aAux20[3],aAux20[4])

aAux21  := FwStruTrigger("ADZ_QTDVEN" /*cDom*/,;
                         "ADZ_VALDES" /*cCDom*/,;
                         "FT600Trigger('ADZ_QTDVEN','ADZ_VALDES','" + cMdlDetail + "')" /*cRegra*/,;
                         .F. /*lSeek*/,;
                         Nil /*cAlias*/,;
                         0   /*nOrdem*/,;
                         Nil /*cChave*/,;
                         Nil /*cCondic*/,;
                         Nil /*cSequen*/)
oStruct:AddTrigger(aAux21[1],aAux21[2],aAux21[3],aAux21[4])

Return Nil

//------------------------------------------------------------------------------
/*/	{Protheus.doc} FATA600AGR

Sobrescreve produtos do item da proposta com os produtos selecionados no
agrupador.

@sample	FATA600AGR()

@param	ExpO1 - ModelGrid dos Produtos da Oportunidade

@return	ExpA - Grid atualizada

@author	Cleyton F.Alves
@since		30/01/2014
@version	12.5.6
/*/
//------------------------------------------------------------------------------
Function FATA600AGR(oMdlADZ)

Local cFilADZ		:= xFilial("ADZ")
Local lDel			:= .F.

ADZ->(dbSetOrder(3))
ADZ->(dbSeek(cFilADZ+ADY->(ADY_PROPOS+ADY_PREVIS)))

WHile ADZ->(!Eof()) .AND. ADZ->ADZ_FILIAL == cFilADZ .AND. ADZ->ADZ_PROPOS == ADY->ADY_PROPOS .AND. ADZ->ADZ_REVISA == ADY->ADY_PREVIS

	If oMdlADZ:SeekLine({{"R_E_C_N_O_" , ADZ->(Recno())}},.F.)
		lDel := .F.
	Else
		lDel := .T.
	EndIf

	//Elimina os registros for�ados na dele��o da manipula��o da grid
	//antes do commit padr�o do form, que ajustar� a grava��o da tabela.
	If lDel
		RecLock("ADZ",.F.)
		dbDelete()
		MsUnLock()
	EndIf
	ADZ->(dbSkip())
EndDo

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} AT600COrc
Carga do Or�amento de Servi�os

@author guilherme.pimentel
@since 01/02/2017
@version 12
/*/
//------------------------------------------------------------------
Function AT600COrc()

MsgRun(STR0378,STR0379,{|| At600SeAtu() })	//"Realizando carga do Or�amento" ## "Aguarde"

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600MdlOport
Retorna o model da Oportunidade de Venda.
@sample 	FT600MdlOport( oMdlProp )
@param		oMdlProp , Objeto ,Model da Proposta Comercial
@Return   	oMdlOpor , Objeto ,Model da Oportunidade de Venda
@author	Anderson Silva
@since		10/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function FT600MdlOport(oMdlProp)

Local oMdlAD1		:= Nil
Local oMdlADY		:= Nil
Local lLoadModel	:= .T.

Default oMdlProp := FwModelActive()

If oMdlProp:GetId() == "FATA600"

	oMdlADY := oMdlProp:GetModel("ADYMASTER")

	If ( _oMdlOpor <> Nil .And. _oMdlOpor:GetId() == "FATA300" .And. _oMdlOpor:IsActive() .And. oMdlProp:IsActive() )
		oMdlAD1 := _oMdlOpor:GetModel("AD1MASTER")
		If ( oMdlAD1:GetValue("AD1_NROPOR") == oMdlADY:GetValue("ADY_OPORTU") .And.;
		     oMdlAD1:GetValue("AD1_REVISA") == oMdlADY:GetValue("ADY_REVISA") )
			lLoadModel := .F.
		EndIf
	EndIf

	If lLoadModel
		AD1->(DBSetOrder(1))
		If AD1->(DBSeek(xFilial("AD1") + oMdlADY:GetValue("ADY_OPORTU") + oMdlADY:GetValue("ADY_REVISA")))
			If _oMdlOpor == Nil
				_oMdlOpor := FwLoadModel("FATA300")
				If IsInCallStack("A416Desbl")
					_oMdlOpor:SetOperation(MODEL_OPERATION_VIEW)
				Else
					_oMdlOpor:SetOperation(MODEL_OPERATION_UPDATE)
				EndIf
			Else
				//Desativa o model e ativa novamente para carregar o model da proxima oportunidade de venda.
				_oMdlOpor:DeActivate()
			EndIf
			_oMdlOpor:Activate()
			FwModelActive(oMdlProp)
			//Valida se o model da oportunidade est� ativo.
			If !_oMdlOpor:IsActive()
				aError := _oMdlOpor:GetErrorMessage()
				If !Empty(aError)
					oMdlProp:SetErrorMessage(,,aError[3],,aError[5],aError[6],aError[7])
				EndIf
			EndIf
		EndIf
	EndIf

EndIf
Return(_oMdlOpor)

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600VldUser
Retorna a valida��o de usuario no SX3
@sample 	FT600VldUser( cField )
@param		cField	, caracter, Campo do SX3
@Return   	cRet	, caracter, Valid do campo
@author	Anderson Silva
@since		18/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Static Function FT600VldUser( cField )

Local cRet := ".T."

If !Empty( cField )
	cRet := GetSx3Cache( cField, "X3_VLDUSER" )
	If Empty( cRet )
		cRet := ".T."
	EndIf
EndIf
Return( cRet )

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600CbxStatus
Retorna os status da proposta comercial no X3_CBOX.
@sample 	FT600CbxStatus()
@param		Nenhum
@Return   	cRet	, caracter, Status da proposta comercial.
@author	Anderson Silva
@since		18/03/2016
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function FT600CbxStatus()

Local cCombo 			:= STR0353 //"A=Proposta em aberto;B=Proposta fechada;C=Proposta cancelada;D=Proposta n�o aprovada;E=Proposta Aprovada;F=Proposta bloqueada;G=Upload Pendente;H=Aguardando Analise;I=Contrato Gerado;J=Pedido de Venda Gerado;K=Nota Fiscal Gerada"
Local lFT600NSta		:= ExistBlock("FT600NSTA")
Local cRetStatus		:= ""

If lFT600NSta
	cRetStatus := ExecBlock("FT600NSTA")
	If ValType(cRetStatus) == "C" .AND. !(Empty(cRetStatus))
		cRetStatus	:= AllTrim(cRetStatus)
		cCombo		+= If(Left(cRetStatus,1) <> ";", ";", "") + cRetStatus
	EndIf
EndIf
Return( cCombo )

//------------------------------------------------------------------------------
/*/{Protheus.doc} Ft600Inf
Legenda do comparador da Proposta Comercial
@sample 	Ft600Inf()
@param		Nenhum
@Return   	lRet, l�gico, .T.
@author	CRM/Faturamento
@since		30/09/2003
@version
/*/
//------------------------------------------------------------------------------
Static Function Ft600Inf()

Local oDlg
Local oBmp1
Local oBmp2
Local oBmp3
Local oBmp4
Local oBmp5
Local oBmp6
Local oBmp7
Local oBmp8
Local oBmp9
Local oBmp10
Local oBut1

//�����������������������������������������������������������������������Ŀ
//�Cria tela com os bitmaps utilizados no tree para correta identificacao.�
//�������������������������������������������������������������������������

DEFINE MSDIALOG oDlg Title STR0075 Of oMainWnd Pixel From 0,0 To 175,550 //"Legenda"

@ 002,003 To 085,273 LABEL STR0075 Pixel //"Legenda"

@ 013,010 BITMAP oBmp1 RESNAME "BPMSEDT1"   SIZE 16,16 NOBORDER Pixel
@ 013,025 Say STR0001 + STR0084                         Of oDlg Pixel //"Proposta Comercial"###" - Modificada"

@ 013,150 BITMAP oBmp2 RESNAME "BPMSEDT4"   SIZE 16,16 NOBORDER Pixel
@ 013,165 Say STR0001 + STR0083                         Of oDlg Pixel //"Proposta Comercial"###" - N�o Alterada"

@ 025,010 BITMAP oBmp3 RESNAME "EXCLUIR"    SIZE 16,16 NOBORDER Pixel
@ 025,025 Say STR0085 + STR0081                         Of oDlg Pixel //"Produto"###" - Excluido"

@ 025,150 BITMAP oBmp7 RESNAME "SDUDRPTBL"  SIZE 16,16 NOBORDER Pixel
@ 025,165 Say STR0086 + STR0081                         Of oDlg Pixel //"Acessorio"###" - Excluido"

@ 040,010 BITMAP oBmp4 RESNAME "NOTE"       SIZE 16,16 NOBORDER Pixel
@ 040,025 Say STR0085 + STR0080                         Of oDlg Pixel //"Produto"###" - Modificado"

@ 040,150 BITMAP oBmp8 RESNAME "S4WB005N"   SIZE 16,16 NOBORDER Pixel
@ 040,165 Say STR0086 + STR0080                         Of oDlg Pixel //"Acessorio"###" - Modificado"

@ 055,010 BITMAP oBmp5 RESNAME "BMPINCLUIR" SIZE 16,16 NOBORDER Pixel
@ 055,025 Say STR0085 + STR0082                         Of oDlg Pixel //"Produto"###" - Incluido"

@ 055,150 BITMAP oBmp9 RESNAME "SDUSETDEL"  SIZE 16,16 NOBORDER Pixel
@ 055,165 Say STR0086 + STR0082                         Of oDlg Pixel //"Acessorio"###" - Incluido"

@ 073,010 BITMAP oBmp6 RESNAME "PMSTASK4"   SIZE 16,16 NOBORDER Pixel
@ 073,025 Say STR0085 + STR0083                         Of oDlg Pixel //"Produto"###" - N�o Alterado"

@ 073,150 BITMAP oBmp10 RESNAME "PMSTASK2"  SIZE 16,16 NOBORDER Pixel
@ 073,165 Say STR0086 + STR0083                         Of oDlg Pixel //"Acessorio"###" - N�o Alterado"

DEFINE SBUTTON oBut1 From 072,244 Type 1 ACTION (oDlg:End()) ENABLE Of oDlg
Activate MSDIALOG oDlg Centered
Return(.T.)

//------------------------------------------------------------------------------
/*/{Protheus.doc} FT600Legenda
Retorna array com cores e legendas da proposta comercial
@sample 	FT600Legenda()
@param		Nenhum
@Return   	aRet	, array, Dados da legenda
@author	Eder Oliveira
@since		04/04/2017
@version	12.1.7
/*/
//------------------------------------------------------------------------------
Function FT600Legenda()

Local lFT600COR	:= ExistBlock("FT600COR")
Local aRet			:= {}
Local aCoresNew	:= {}

aRet 	:= {{'ADY->ADY_STATUS=="A"', 'BR_VERDE',    STR0184},;		//"Proposta em aberto"
    	    {'ADY->ADY_STATUS=="B"', 'BR_VERMELHO', STR0185},;		//"Proposta fechada"
    	    {'ADY->ADY_STATUS=="C"', 'BR_PRETO',    STR0186},;		//"Proposta cancelada"
    	    {'ADY->ADY_STATUS=="D"', 'BR_AMARELO',  STR0187},;		//"Proposta n�o aprovada"
    	    {'ADY->ADY_STATUS=="E"', 'BLUE',        STR0032},;		//"Proposta Aprovada"
    	    {'ADY->ADY_STATUS=="F"', 'BR_CINZA',    STR0189},;		//"Proposta bloqueada"
    	    {'ADY->ADY_STATUS=="G"', 'BR_MARROM',   STR0348},;		//"Upload Pendente"
    	    {'ADY->ADY_STATUS=="H"', 'ORANGE',      STR0349},;		//"Aguardando Analise"
    	    {'ADY->ADY_STATUS=="I"', 'PINK',        STR0350},;		//"Contrato Gerado"
    	    {'ADY->ADY_STATUS=="J"', 'WHITE',       STR0351},;		//"Pedido de Venda Gerado"
    	    {'ADY->ADY_STATUS=="K"', 'BR_VIOLETA',  STR0352}}		//"Nota Fiscal Gerada"

//��������������������������������������������������������������Ŀ
//� Ponto de Entrada para alterar cores do Browse do Cadastro    �
//����������������������������������������������������������������
If lFT600COR
	aCoresNew := ExecBlock("FT600COR",.F.,.F.,{aRet})
	If ValType( aCoresNew ) == "A"
		aRet := aClone(aCoresNew)
	EndIf
Endif
Return(aRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} A600RdpTot
Retorna array com cores e legendas da proposta comercial
@sample 	A600RdpTot(oModel, 1401, 301, .F., 'ADZPRODUTO','ADZ__TOTPRD')
@param		oModel, Objeto, Modelo de dados da proposta
			nTotal, Numerico, Valor total da proposta
			xValor, Numerico, valor atual da linha posicionada
			lSum, L�gico, Se verdadeiro soma xValor ao nTotal, se n�o, subtrai
			cSubModel, Caracter, Id do submodelo (Produto/Acess�rio)
			cTotalType, Caracter, Id do campo virtual de total (Produto ou Acess�rio)
@Return   	nTotal, Numerico, Valor total da proposta
@author	Squad CRM/Faturamento
@since		30/05/2018
@version	12.1.17+
/*/
//------------------------------------------------------------------------------
Static Function A600RdpTot( oModel, nTotal, xValor, lSum, cSubModel,cTotalType )
	Local oModelADZ 	:= oModel:GetModel(cSubModel)
	Local oMdlCalPrd  	:= oModel:GetModel("CALC")
	Local nMoeda		:= Val( oModelADZ:GetValue('ADZ_MOEDA') )
	Local nTotAtu	 	:= 0

	Default nTotal	   	:= 0
	Default xValor		:= 0
	Default lSum		:= .T.
	Default cSubModel	:= 'ADZPRODUTO'
	Default cTotalType	:= 'ADZ__TOTPRD'

	If  nMoeda > 1
		nTotAtu := xMoeda( oModelADZ:GetValue('ADZ_TOTAL'),  nMoeda, 1 ,dDatabase , GetSX3Cache("ADZ_TOTAL","X3_DECIMAL") )
	Else
		nTotAtu := oModelADZ:GetValue('ADZ_TOTAL')
	EndIf

	If lSum
		nTotal := oMdlCalPrd:GetValue(cTotalType) + nTotAtu
	Else
		nTotal := oMdlCalPrd:GetValue(cTotalType) - nTotAtu
	EndIf

Return nTotal
