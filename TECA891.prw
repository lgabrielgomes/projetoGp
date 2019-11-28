#INCLUDE "PROTHEUS.CH" 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA891.CH"

//Variaveis para verificar periodo de apontamento para contrato recorrente
Static cPriDia		:= "01"									//Primeiro dia do Mes
Static cUltDia		:= StrZero( F_UltDia(dDataBase), 2 )    //Ultimo dia do mes corrrente
Static cMesCor		:= StrZero( Month(dDataBase)   , 2 )	//Mes do dia corrente
Static cAnoCor	 	:= Alltrim(Str ( Year(dDataBase)))      //Ano do Mes corrente
Static lLegend		:= .T.
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Realiza apontamento dos materiais 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruTFL 	:= 	FWFormStruct( 1, 'TFL' )
Local oStruTGU 	:= 	FWFormStruct( 1, 'TGU' )
Local bCommit	:= {|oModel|At891Commit(oModel)}
Local oModel 	:= MPFormModel():New( 'TECA891',/*bPreValidacao*/,/*bPosVld*/,bCommit,/*bCancel*/)
Local cIsGsMt	:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_ISGSMT")
Local cDtIni	:=  cAnoCor + cMesCor + cPriDia
Local cDtFin	:= cAnoCor + cMesCor + cUltDia

oStruTFL:AddField( STR0001 ,STR0001 ,'TFL_DESLOC', 'C', 60, 0,/*bValid*/,/*bWhen*/, /*aValues*/, .F., ,/*lKey*/, /*lNoUpd*/, .F./*lVirtual*/,/*cValid*/) //Descrição

oStruTFL:AddField( STR0002 ,STR0002 ,'TFL_SALDO' , 'N', 16, 2,,/*bWhen*/, /*aValues*/, .F., ,/*lKey*/, /*lNoUpd*/, .F./*lVirtual*/,/*cValid*/)			  //Status
oStruTFL:AddField( 'Saldo MI' ,'Saldo MI' ,'TFL_SLDMI' , 'N', 16, 2,,/*bWhen*/, /*aValues*/, .F., ,/*lKey*/, /*lNoUpd*/, .F./*lVirtual*/,/*cValid*/)			  //'Saldo MI'
oStruTFL:AddField( 'Saldo MC' ,'Saldo MC' ,'TFL_SLDMC' , 'N', 16, 2,,/*bWhen*/, /*aValues*/, .F., ,/*lKey*/, /*lNoUpd*/, .F./*lVirtual*/,/*cValid*/)			  //'Saldo MC'
oStruTGU:AddField( 'Legenda'  ,'Legenda'  ,'TGU_SIT'   ,'BT',1,0, {|| At891GetLg()}/*bValid*/,/*bWhen*/, /*aValues*/, .F., {|| At891LgTGU()},/*lKey*/, /*lNoUpd*/, .T./*lVirtual*/,/*cValid*/)//"Status"
oStruTGU:AddField( 'Tp. Gs. Mt. Ant' ,'Tipo de Gestão de Material Anterior' ,'TGU_TPGSMTANT' , 'C', 1,,,/*bWhen*/, /*aValues*/, .F., ,/*lKey*/, /*lNoUpd*/, .F./*lVirtual*/,/*cValid*/)			  //'Tp. Gs. Mt. Ant' ,'Tipo de Gestão de Material Anterior'

oStruTGU:SetProperty("TGU_TPGSMT",MODEL_FIELD_OBRIGAT,(cIsGsMt == "1"))
oStruTGU:SetProperty("*"         ,MODEL_FIELD_WHEN,{|| At891BlqAp(FwFldGet("TGU_APURAC"))})
oStruTGU:SetProperty("TGU_APURAC",MODEL_FIELD_WHEN,{|| .T. })
oStruTGU:SetProperty("TGU_SIT"	 ,MODEL_FIELD_WHEN,{|| .T. })

oModel:AddFields( 'MODEL_TFL' , /*cOwner*/ , oStruTFL )

oModel:AddGrid ( 'MODEL_TGU' , 'MODEL_TFL' , oStruTGU, {|oModel,nLine,cAction| FDelReg(oModel,nLine,cAction)} )
oModel:GetModel( 'MODEL_TGU' ):SetUniqueLine( { 'TGU_COD'} )

oModel:SetRelation( 'MODEL_TGU', { { 'TGU_FILIAL', 'xFilial( "TGU" )' }, { 'TGU_CODTFL', 'TFL_CODIGO' } }, TGU->( IndexKey( 1 ) ) )

//Aplica o filtro no model
oModel:GetModel( 'MODEL_TGU' ):SetLoadFilter( { { 'TGU_APURAC', "' '" } } )
oModel:GetModel( 'MODEL_TGU' ):SetOptional( .T. )

//Se for recorrente só carrega apontamentos do mes corrente
If TFJ->TFJ_CNTREC = '1'
	oModel:GetModel( 'MODEL_TGU' ):SetLoadFilter( , "(TGU_DATA BETWEEN '" + cDtIni + "' AND '" + cDtFin + "' )" )
EndIf

oModel:SetVldActivate( {|oModel| At891Vld(oModel)} ) 

oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return ( oModel )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Realiza apontamento dos materiais 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oModel 	:= 	FWLoadModel ( 'TECA891' )
Local oView 	:= 	FWFormView():New()

Local oStruTFL  :=  Nil
Local oStruTGU 	:= 	Nil
Local cIsGsMt	:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_ISGSMT")

cCmpsFil   :=  '|TFL_LOCAL|'
oStruTFL 	:= 	FWFormStruct( 2, 'TFL', {|cCampo| ( AllTrim( cCampo )+"|" $ cCmpsFil ) } )

cCmpsFil  :=  '|TGU_DATA|TGU_COD|TGU_PROD|TGU_DESCPR|TGU_QUANT|TGU_VALOR|TGU_TOTAL|'

If cIsGsMt == "1"
	cCmpsFil  += 'TGU_TPGSMT|
Endif

oStruTGU 	:= 	FWFormStruct( 2, 'TGU', {|cCampo| ( AllTrim( cCampo )+"|" $ cCmpsFil ) } )

If cIsGsMt == "1"
	oStruTGU:SetProperty('TGU_TPGSMT', MVC_VIEW_ORDEM , "04" )
Endif

oStruTFL:SetProperty('TFL_LOCAL', MVC_VIEW_CANCHANGE, .F.)

oView:SetModel( oModel )            
                                        
oStruTFL:AddField( 'TFL_DESLOC', ; // cIdField
       			 '04', ; // cOrdem
                   STR0001, ; // cTitulo - Descrição
                   STR0001, ; // cDescric  - Descrição
                   {}, ; // aHelp
                   'C', ; // cType
                   '', ; // cPicture
       			   Nil, ; // nPictVar
                   Nil, ; // Consulta F3
                   .F., ; // lCanChange
                   '', ; // cFolder
                   Nil, ; // cGroup
                   Nil, ; // aComboValues
                   Nil, ; // nMaxLenCombo
                   '', ; // cIniBrow
                   .T., ; // lVirtual
                   '' ) // cPictVar
                    
oStruTFL:AddField( 'TFL_CONTRT', ; // cIdField
       				'05',; // cOrdem
                    STR0003,; // cTitulo - Contrato
                    STR0003 , ; // cDescric - Contrato
                    {}, ; // aHelp
                   	'C', ; // cType
                   	'', ; // cPicture
       				Nil, ; // nPictVar
                    Nil, ; // Consulta F3
                    .F., ; // lCanChange
                    '', ; // cFolder
                    Nil, ; // cGroup
                    Nil, ; // aComboValues
                    Nil, ; // nMaxLenCombo
                    Nil, ; // cIniBrow
                    .T., ; // lVirtual
                    Nil ) // cPictVar     
                    
oStruTFL:AddField( 'TFL_CONREV', ; // cIdField
       				'06', ; // cOrdem
                    STR0004 , ; // cTitulo - Revisão
                    STR0004 , ; // cDescric - Revisão
                    {}, ; // aHelp
                   	'C', ; // cType
                   	'', ; // cPicture
       				Nil, ; // nPictVar
                    Nil, ; // Consulta F3
                    .F., ; // lCanChange
                    '', ; // cFolder
                    Nil, ; // cGroup
                    Nil, ; // aComboValues
                    Nil, ; // nMaxLenCombo
                    Nil, ; // cIniBrow
                    .T., ; // lVirtual
                    Nil ) // cPictVar    
                    
If cIsGsMt == "1"
	oStruTFL:AddField( 'TFL_SLDMI', ; // cIdField
	       				'08', ; // cOrdem
	                    STR0021 , ; // cTitulo - 'Saldo MI'
	                    STR0021 , ; // cDescric - 'Saldo MI'
	                    {}, ; // aHelp
	                   	'N', ; // cType
	                   	'@E 999,999,999.99', ; // cPicture
	       				Nil, ; // nPictVar
	                    Nil, ; // Consulta F3
	                    .F., ; // lCanChange
	                    '', ; // cFolder
	                    Nil, ; // cGroup
	                    Nil, ; // aComboValues
	                    Nil, ; // nMaxLenCombo
	                    Nil, ; // cIniBrow
	                    .T., ; // lVirtual
	                    Nil ) // cPictVar     
	
	oStruTFL:AddField( 'TFL_SLDMC', ; // cIdField
	       				'09', ; // cOrdem
	                    STR0022 , ; // cTitulo - 'Saldo MC'
	                    STR0022 , ; // cDescric - 'Saldo MC'
	                    {}, ; // aHelp
	                   	'N', ; // cType
	                   	'@E 999,999,999.99', ; // cPicture
	       				Nil, ; // nPictVar
	                    Nil, ; // Consulta F3
	                    .F., ; // lCanChange
	                    '', ; // cFolder
	                    Nil, ; // cGroup
	                    Nil, ; // aComboValues
	                    Nil, ; // nMaxLenCombo
	                    Nil, ; // cIniBrow
	                    .T., ; // lVirtual
	                    Nil ) // cPictVar     
Else
	oStruTFL:AddField( 'TFL_SALDO', ; // cIdField
	       				'07', ; // cOrdem
	                    STR0002 , ; // cTitulo - Saldo
	                    STR0002 , ; // cDescric - Saldo
	                    {}, ; // aHelp
	                   	'N', ; // cType
	                   	'@E 999,999,999.99', ; // cPicture
	       				Nil, ; // nPictVar
	                    Nil, ; // Consulta F3
	                    .F., ; // lCanChange
	                    '', ; // cFolder
	                    Nil, ; // cGroup
	                    Nil, ; // aComboValues
	                    Nil, ; // nMaxLenCombo
	                    Nil, ; // cIniBrow
	                    .T., ; // lVirtual
	                    Nil ) // cPictVar     
Endif

oStruTGU:AddField( 'TGU_SIT', ; // cIdField
       				'01', ; // cOrdem
                    STR0023, ; // cTitulo 'Legenda'
                    STR0023, ; // cDescric 'Legenda'
                    {}, ; // aHelp
                   	'BT', ; // cType
                   	'', ; // cPicture
       				Nil, ; // nPictVar
                    Nil, ; // Consulta F3
                    .T., ; // lCanChange
                    '', ; // cFolder
                    Nil, ; // cGroup
                    Nil, ; // aComboValues
                    Nil, ; // nMaxLenCombo
                    Nil, ; // cIniBrow
                    .T., ; // lVirtual
                    Nil ) // cPictVar

//Exibindo os titulos da tela
oView:AddField( 'VIEW_TFL', oStruTFL, 'MODEL_TFL' )
oView:EnableTitleView( 'VIEW_TFL', STR0005 ) //Local de Atendimento"

oView:AddGrid ( 'VIEW_TGU', oStruTGU, 'MODEL_TGU' )
oView:EnableTitleView( 'VIEW_TGU', STR0006 ) //Apontamento por Valor

oView:AddOtherObject( 'PANEL_BUTTONS',{ |oPanel| FChBtkMon( oPanel ) } )		//Botoes de Manipulacao das informacoes

//Definindo os espaços de tela
oView:CreateHorizontalBox( 'FIELDSTFL', 20 )
oView:CreateHorizontalBox( 'GRIDTGU', 70 )
oView:CreateHorizontalBox( 'HISTORIC', 10 )

oView:SetOwnerView( 'VIEW_TFL', 'FIELDSTFL' )
oView:SetOwnerView( 'VIEW_TGU', 'GRIDTGU' )
oView:SetOwnerView( 'PANEL_BUTTONS', 'HISTORIC' )

//Campo Auto-Incremental
oView:AddIncrementField( 'VIEW_TGU', 'TGU_COD' )

oView:AddUserButton(STR0009 ,"",{|oView| At891Hist(oView) })//'Materiais por valor'

Return ( oView ) 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
Realiza a inicialização dos valores na carga da tela

@Param oModel - Model Corrente 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------	
Static Function InitDados( oModel )

Local cDesLoc   := ''
Local cQuery    := ''
Local cSelect   := ''
Local cFrom     := '' 
Local cWhere    := '' 
Local cAliasQry := ''
Local cDesPrd   := ''
Local cFilTGU 	:= xFilial("TGU")
Local nSaldo    := 0
Local nSaldoMi	:= 0
Local nSaldoMc	:= 0
Local nX        := 0
Local oMdlTFL 	:= oModel:GetModel("MODEL_TFL")
Local oMdlTGU 	:= oModel:GetModel("MODEL_TGU")
Local cIsGsMt	:= ""

//Grava a descrição do Local de Atendimento para exibição no cabeçalho
cDesLoc	:= Alltrim( Posicione( "ABS", 1, xFilial("ABS") + oMdlTFL:GetValue("TFL_LOCAL"), "ABS_DESCRI") )
oMdlTFL:LoadValue("TFL_DESLOC", cDesLoc)

cIsGsMt := Posicione( "TFJ", 1, xFilial("TFJ") + oMdlTFL:GetValue("TFL_CODPAI") , "TFJ_ISGSMT")

lLegend := .F.

For nX := 1 To oMdlTGU:Length() 
	
	oMdlTGU:GoLine(nX)
	
	oMdlTGU:SetValue("TGU_SIT",At891LgTGU(oMdlTGU:GetValue("TGU_APURAC")))	

	If cIsGsMt == "1"
		If oMdlTGU:GetValue("TGU_TPGSMT") == "1"
			nSaldoMi += ( oMdlTGU:GetValue("TGU_QUANT") * oMdlTGU:GetValue("TGU_VALOR") )
		Elseif oMdlTGU:GetValue("TGU_TPGSMT") == "2"
			nSaldoMc += ( oMdlTGU:GetValue("TGU_QUANT") * oMdlTGU:GetValue("TGU_VALOR") )
		Endif		
	Else
		nSaldo 	 += ( oMdlTGU:GetValue("TGU_QUANT") * oMdlTGU:GetValue("TGU_VALOR") )
	Endif
	
	If  !( oMdlTGU:IsDeleted() ) .And. !Empty( oMdlTGU:GetValue( 'TGU_PROD' ) )
		cDesPrd := Posicione( "SB1", 1, xFilial("SB1") + oMdlTGU:GetValue('TGU_PROD' ), "B1_DESC")
		oMdlTGU:LoadValue("TGU_DESCPR", cDesPrd )
		oMdlTGU:SetValue("TGU_TPGSMTANT", oMdlTGU:GetValue("TGU_TPGSMT"))
	EndIf
Next nX

lLegend := .T.

//Busca o valor de materiais de todos os itens de recursos humanos utilizados no local de trabalho
cSelect := "%SUM( TFF_VLRMAT ) TFF_VLRMAT, SUM( TFF_VLMTMI ) TFF_VLMTMI, SUM( TFF_VLMTMC ) TFF_VLMTMC %"
cFrom   := "%"+RetSqlName("TFF")+" TFF%" 
cWhere  := "%TFF_LOCAL = '" + TFL->TFL_LOCAL + "' AND TFF_CODPAI = '" +  TFL->TFL_CODIGO + "' "
cWhere  += " AND TFF.D_E_L_E_T_ = ' '%"

cAliasQry := GetNextAlias() 
BeginSql Alias cAliasQry     
    SELECT							
	    %Exp:cSelect%
    FROM              	
        %Exp:cFrom%
	WHERE
		%EXP:cWhere% 
EndSql

nSaldo   := (cAliasQry)->TFF_VLRMAT - nSaldo
nSaldoMi := (cAliasQry)->TFF_VLMTMI - nSaldoMi
nSaldoMc := (cAliasQry)->TFF_VLMTMC - nSaldoMc

(cAliasQry)->( dbCloseArea() )

//Atualiza o campo de Saldo do cabeçalho
If cIsGsMt == "1"
	oMdlTFL:LoadValue("TFL_SLDMI", nSaldoMi )
	oMdlTFL:LoadValue("TFL_SLDMC", nSaldoMc )
Else
	oMdlTFL:LoadValue("TFL_SALDO", nSaldo )
Endif

Return ( Nil )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} F891VldGrid
Atualiza o valor do Saldo 

@Param
cCmp - Campo que será validado

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function F891VldGrid( cCmp )
Local nX      := 0
Local cCmp    := cCmp
Local lRet    := .T.
 
Local nTotAtu    := 0
Local nSaldo     := 0
Local nSaldoAnt  := 0

Local cCmpSld 	 := ""
Local cCmpSldAnt := ""
Local cIsGsMt 	 := ""
Local lMtVlrMi	 := .F.
Local lMtVlrMc   := .F.
Local cTpGsMt 	 := ""
Local cTpGsMtAnt := ""

oView 		:= 	FWViewActive()	//Recuperando a view ativa da interface
oModel 		:= 	FWModelActive()	//Recuperando a view ativa da interface

nSaldo  := oModel:GetValue( 'MODEL_TGU' , 'TGU_TOTAL' ) //Valor Anterior

DbSelectArea("TFJ")
TFJ->(DbSetOrder(1))
If TFJ->(DbSeek(xFilial("TFJ") + oModel:GetValue( "MODEL_TFL" , "TFL_CODPAI" )))
	cIsGsMt  := TFJ->TFJ_ISGSMT
	lMtVlrMi := TFJ->TFJ_GSMTMI == "1"
	lMtVlrMc := TFJ->TFJ_GSMTMC == "1"
Endif

If 'TGU_QUANT' $ cCmp
	nTotAtu := M->TGU_QUANT * ( oModel:GetValue( 'MODEL_TGU' , 'TGU_VALOR' ) )
Elseif 'TGU_VALOR' $ cCmp
	nTotAtu := ( oModel:GetValue( 'MODEL_TGU' , 'TGU_QUANT' ) ) * M->TGU_VALOR
Elseif 'TGU_TPGSMT' $ cCmp
	nTotAtu := oModel:GetValue( 'MODEL_TGU' , 'TGU_QUANT' ) * oModel:GetValue( 'MODEL_TGU' , 'TGU_VALOR' )	
	If oModel:GetValue( 'MODEL_TGU' , 'TGU_TPGSMT' ) == "1" .And. lMtVlrMi
		Help( " ", 1, 'F891VldGrid', , STR0017 , 1, 0 ) //"Não é póssivel inserir um apontamento de material de implantação, a configuração da gestão de materiais no orçamento de serviços está com a opção 1-Material."
		lRet := .F.
	Elseif oModel:GetValue( 'MODEL_TGU' , 'TGU_TPGSMT' ) == "2" .And. lMtVlrMc
		Help( " ", 1, 'F891VldGrid', , STR0018 , 1, 0 ) //"Não é póssivel inserir um apontamento de material de consumo, a configuração da gestão de materiais no orçamento de serviços está com a opção 1-Material."  
		lRet := .F.
	Endif
Else
	Return ( .T. )
Endif

If lRet
	If cIsGsMt == "1"
		cTpGsMt 	:= oModel:GetValue( 'MODEL_TGU' , 'TGU_TPGSMT' )
		cTpGsMtAnt  := oModel:GetValue( 'MODEL_TGU' , 'TGU_TPGSMTANT' )
				
		If cTpGsMt == "1"
			cCmpSld := 'TFL_SLDMI'
		Elseif cTpGsMt == "2"
			cCmpSld := 'TFL_SLDMC'
		Endif
	
		If cTpGsMtAnt == "1"
			cCmpSldAnt := 'TFL_SLDMI'
		Elseif cTpGsMtAnt == "2"
			cCmpSldAnt := 'TFL_SLDMC'
		Endif
	
	Else
		cCmpSld := 'TFL_SALDO'
	Endif
	
	If nTotAtu <> nSaldo
		nSaldo :=  nTotAtu - nSaldo	
	Endif
	
	If !Empty(cCmpSldAnt) .And. cTpGsMt <> cTpGsMtAnt
		nSaldoAnt := oModel:GetValue( 'MODEL_TFL', cCmpSldAnt ) + nSaldo 
	
		If nSaldoAnt >= 0
			//Atualiza o campo de Saldo do cabeçalho
			oModel:LoadValue("MODEL_TFL", cCmpSldAnt, nSaldoAnt)
		Endif
	Endif
	
	If !Empty(cCmpSld)
		nSaldo := oModel:GetValue( 'MODEL_TFL', cCmpSld ) - nSaldo 
	
		If nSaldo >= 0
			//Atualiza o campo de Saldo do cabeçalho
			oModel:LoadValue("MODEL_TFL", cCmpSld, nSaldo)
		Else
			Help( ' ', 1, 'TECA891', , STR0007 , 1, 0 ) //Limite de saldo excedido
			lRet := .F.
			
		Endif
	Endif
	
	If lRet
		oModel:SetValue( 'MODEL_TGU' , 'TGU_TPGSMTANT', oModel:GetValue( 'MODEL_TGU' , 'TGU_TPGSMT' ) )
	Endif 
Endif


Return ( lRet )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FVld891Dt
Verifica se a data informada esta no período de vigência 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function FVld891Dt(cCampo)

Local lRet 	 	:= .T.
Local cRecorre	:= Posicione( "TFJ", 1, xFilial("TFJ") + TFL->TFL_CODPAI, "TFJ_CNTREC") //Verifica se é recorrente
Local dDtIni	:= sToD(cAnoCor + cMesCor + cPriDia)	//Pega o primeiro dia do mes corrente
Local dDtFin	:= sToD(cAnoCor + cMesCor + cUltDia)  //Pega o ultimo dia do mes corrente

Default cCampo	:= ""

If ( M->TGU_DATA > TFL->TFL_DTFIM ) .Or. ( M->TGU_DATA < TFL->TFL_DTINI )
	lRet := .F.
	Help( ' ', 1, 'TECA891', , STR0008, 1, 0 ) //Data fora do período de vigência do local
ElseIf cRecorre = "1"
	If !(dDtIni <= M->TGU_DATA .And. dDtFin >= M->TGU_DATA )
		Help( "", 1, "FVld891Dt", , STR0014, 1, 0,,,,,,{STR0015 + dToc(dDtIni) + STR0016 + dToc(dDtFin)})  // "O periodo de apontamento do contrato recorrente está fora de vigencia" ## "Selecione uma data entre os dias "
     	lRet := .F.
     EndIf 
Endif

Return ( lRet )                                                                                                                     

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At891Hist
Monta tela de Histórico de apontamento de materiais 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At891Hist()

Local cAliasPro	:= "AT891QRY"
Local cQuery   := ''
Local aSize	 	:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local oBrowse  := Nil

oBrowse := FWFormBrowse():New()

aColumns := At891Cols()
cQuery   := At891Query()

DEFINE DIALOG oDlg TITLE STR0009 FROM aSize[1] + 100,aSize[2] + 100 TO aSize[3] - 100, aSize[4] - 100 PIXEL //Histórico
	
// Cria um Form Browse
oBrowse := FWFormBrowse():New()

// Atrela o browse ao Dialog form nao abre sozinho
oBrowse:SetOwner(oDlg)

// Indica que vai utilizar query
oBrowse:SetAlias(cAliasPro)
oBrowse:SetDataQuery(.T.)
oBrowse:SetQuery(cQuery)


oBrowse:SetColumns(aColumns)						 
oBrowse:DisableDetails()

oBrowse:AddButton( STR0010 , { || oDlg:End() },,,, .F., 2 ) //Sair	

oBrowse:SetDescription(STR0009)	//Histórico

oBrowse:Activate()

ACTIVATE DIALOG oDlg CENTERED

Return ( .T. )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At891Cols
Monta as colunas de exibição da GRID 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At891Cols()

Local nI		:= 0 
Local aArea		:= GetArea()
Local aColumns	:= {}

Local aCampos 	:= { "TGU_DATA", "TGU_PROD", "B1_DESC", "TGU_QUANT", "TGU_VALOR", "TGU_TOTAL", "TGU_APURAC" }
							
DbSelectArea("SX3")
SX3->(DbSetOrder(2))

For nI:=1 To Len(aCampos)

	If aCampos[nI] == 'TGU_TOTAL'

		cCampo := aCampos[nI]
		
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
	   	aColumns[nLinha]:SetType("N")
	   	aColumns[nLinha]:SetTitle(STR0011) //Total
		aColumns[nLinha]:SetSize(14)
		aColumns[nLinha]:SetDecimal(2)
		aColumns[nLinha]:SetPicture("@E 999,999,999.99" )
		aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))		
				
	Else
		If SX3->(dbSeek(aCampos[nI]))
		
			cCampo := AllTrim(SX3->X3_CAMPO)
			
			AAdd(aColumns,FWBrwColumn():New())
			nLinha := Len(aColumns)
		   	aColumns[nLinha]:SetType(SX3->X3_TIPO)
		   	aColumns[nLinha]:SetTitle(X3Titulo())
			aColumns[nLinha]:SetSize(SX3->X3_TAMANHO)
			aColumns[nLinha]:SetDecimal(SX3->X3_DECIMAL)
			aColumns[nLinha]:SetPicture(SX3->X3_PICTURE)
			
			If SX3->X3_TIPO == "D"
				aColumns[nLinha]:SetData(&("{|| sTod(" + cCampo + ")}"))		
			Else
				aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))	
			EndIf		
			
		EndIf
	Endif
	
Next nI

SX3->(dbCloseArea())

RestArea(aArea)

Return(aColumns)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At891Query
Monta a Query de Exibição na GRID 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At891Query()

cQuery := " SELECT TGU_DATA, TGU_PROD, B1_DESC, TGU_QUANT, TGU_VALOR, ( TGU_QUANT * TGU_VALOR ) TGU_TOTAL, TGU_APURAC "
 
cQuery += " FROM " + RetSqlName("TGU")

cQuery += " INNER JOIN " + RetSqlName("SB1")
cQuery += " ON B1_FILIAL = '" + xFilial("SB1") + "' AND"
cQuery += " TGU_PROD = B1_COD "
  
cQuery += " WHERE TGU_APURAC <> ''"
cQuery += " AND TGU_CODTFL = '" + TFL->TFL_CODIGO + "'"
cQuery += " AND "+RetSqlName("TGU")+".D_E_L_E_T_ = ''"
cQuery += " AND "+RetSqlName("SB1")+".D_E_L_E_T_ = ''"

cQuery += " ORDER BY TGU_DATA"

Return ( cQuery )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FA891Atu
Atualiza a View depois dos valores alterados na tela 

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function FA891Atu()

oView 		:= 	FWViewActive()	
oview:Refresh( 'VIEW_TGU' )

Return ( Nil )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FChBtkMon
Cria o botão de histórico na tela 

@Param
oPanel - Painel onde serão criados os objetos

@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function FChBtkMon( oPanel  )

Local nLinIni := 17     //Define a Linha Inicial dentro do Panel oPanel   
Local nColIni := 710    //Define a Coluna Inicial dentro do Panel oPanel       
Local oView :=	FWViewActive()	//Recuperando o View ativo da interface  

TButton():New( nLinIni, nColIni, STR0009 , oPanel, { || At891Hist() },60,25,,,.F.,.T.,.F.,,.F.,,,.F. )   //Histórico
 
Return ( Nil )  

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FDelReg
Realiza o Delete / Undelete da GRID 


@author Serviços
@since 22/06/2015
@version P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function FDelReg(oMdlApt, nLine, cAction)
Local lRet			:= .T.
Local oModel 		:= 	FWModelActive()	//Recuperando a view ativa da interface
Local cCmpSld		:= ""
Local cIsGsMt 		:= ""

If cAction $ 'DELETE|UNDELETE'
	cIsGsMt := Posicione( "TFJ", 1, xFilial("TFJ") + oModel:GetValue( "MODEL_TFL" , "TFL_CODPAI" ) , "TFJ_ISGSMT")

	If cIsGsMt == "1"
		cTpGsMt := oModel:GetValue( 'MODEL_TGU' , 'TGU_TPGSMT' )
		If cTpGsMt == "1"
			cCmpSld := 'TFL_SLDMI'
		Elseif cTpGsMt == "2"
			cCmpSld := 'TFL_SLDMC'
		Endif
	Else
		cCmpSld := 'TFL_SALDO'
	Endif
Endif

if cAction == 'DELETE'	
	If lRet := At891BlqAp(oMdlApt:GetValue("TGU_APURAC"))
		If (Empty(oMdlApt:GetValue("TGU_DATA")) .AND. Empty(oMdlApt:GetValue("TGU_PROD")) .AND. Empty(oMdlApt:GetValue("TGU_QUANT")) .AND. Empty(oMdlApt:GetValue("TGU_VALOR")))
		
			TGU->(RoolBackSx8())
		
		Else
			nSaldo := oModel:GetValue( 'MODEL_TFL' , cCmpSld ) + oModel:GetValue( 'MODEL_TGU' , 'TGU_TOTAL' )
				
			oModel:LoadValue("MODEL_TFL", cCmpSld, nSaldo )
		EndIf
	Endif	
elseif cAction == 'UNDELETE'
	nSaldo := oModel:GetValue( 'MODEL_TFL' , cCmpSld ) - oModel:GetValue( 'MODEL_TGU' , 'TGU_TOTAL' )
	If nSaldo >= 0
		oModel:LoadValue("MODEL_TFL", cCmpSld, nSaldo )
	Else
		Help( ' ', 1, 'TECA891', , STR0007 , 1, 0 ) //Limite de saldo excedido
		lRet := .F.
	EndIf
	
	oModel:LoadValue("MODEL_TFL", cCmpSld, nSaldo )
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At891Commit()
Commit do Modelo de Dados

@sample		At891Commit(oModel)

@param		ExpO - Modelo de Dados
	
@return		ExpL - Retorna Verdadeiro, caso a Inclusão dos campos foram feitos com sucesso

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Static Function At891Commit(oModel)
Local lRet 		:= .T.
Local bAfter	:= {|oModel,cID,cAlias| At891After(oModel,cID,cAlias)}

lLegend := .F.
FWModelActive( oModel )
lRet := FWFormCommit( oModel,/*bBefore*/,bAfter,NIL)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At891After()
Função para Realizar a Inclusão do Custo

@sample		At891After(oModel,cID,cAlias)

@param		ExpO - Modelo de Dados
			ExpC - ID do Modelo
			ExpC - Alias da Tabela
	
@return		ExpL - Retorna Verdadeiro, caso a Inclusão dos campos foram feitos com sucesso

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Static Function At891After(oModel,cID,cAlias)
Local lRet 		:= .T.
Local cCodTWZ	:= ""
Local oMdlFull	:= Nil

If ( cId == "MODEL_TGU" .AND. cAlias == "TGU" )
	oMdlFull := FwModelActive()
	Do Case
		Case oModel:IsDeleted()
			If !Empty(oModel:GetValue("TGU_CODTWZ"))
				At995ExcC(oMdlFull:GetModel("MODEL_TFL"):GetValue("TFL_CODPAI"),oModel:GetValue("TGU_CODTWZ"))
			EndIf	
		Case oModel:IsInserted()
			cCodTWZ := At995Custo(oMdlFull:GetModel("MODEL_TFL"):GetValue("TFL_CODPAI"),;
						NIL,oMdlFull:GetModel("MODEL_TFL"):GetValue("TFL_CODIGO"),;
						oModel:GetValue("TGU_PROD"),"5",oModel:GetValue("TGU_TOTAL"),"TECA891")
			If !Empty(cCodTWZ)
				RecLock("TGU", .F.)
					TGU->TGU_CODTWZ := cCodTWZ
				TWZ->(MsUnlock())
			EndIf		
		Case oModel:IsUpdated()
			At995ExcC(oMdlFull:GetModel("MODEL_TFL"):GetValue("TFL_CODPAI"),oModel:GetValue("TGU_CODTWZ"))
			cCodTWZ := At995Custo(oMdlFull:GetModel("MODEL_TFL"):GetValue("TFL_CODPAI"),;
						NIL,oMdlFull:GetModel("MODEL_TFL"):GetValue("TFL_CODIGO"),;
						oModel:GetValue("TGU_PROD"),"5",oModel:GetValue("TGU_TOTAL"),"TECA891")
			If !Empty(cCodTWZ)
				RecLock("TGU", .F.)
					TGU->TGU_CODTWZ := cCodTWZ
				TWZ->(MsUnlock())
			EndIf				
	End Case
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At891Vld()
Função para validar a vigencia do contrato e não permitir o apontamento

@sample		At891Vld(oModel)

@param		ExpO - Modelo de Dados
	
@return		ExpL - Retorna Verdadeiro, caso a data de apontamento estiver dentro da vigencia

@author		Serviços
@since		02/10/2017
@version	12  
/*/
//------------------------------------------------------------------
Static Function At891Vld(oModel)
Local lRet := .T.

If !(TFL->TFL_DTINI <= dDataBase .And. TFL->TFL_DTFIM >= dDataBase )
	lRet := .F.
	oModel:GetModel():SetErrorMessage(oModel:GetId(),"TFL_LOCAL",oModel:GetModel():GetId(),	"TFL_LOCAL",'TFL_LOCAL',; 
		STR0012, STR0013 )//"O contrato está fora da vigencia de apontamento"##"Selecione outro contrato, ou realize uma nova revisão para o mesmo"

EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At891BlqAp()
Função para bloquear o itens que já foram apurados.

@sample		At891BlqAp(cApurac)

@param		cApurac - Codigo da apuração.
	
@return		lRet - Retorna Verdadeiro, caso o item não tenha sido apurado.

@author		Serviços
@since		02/10/2017
@version	12  
/*/
//------------------------------------------------------------------
Function At891BlqAp(cApurac)
Local lRet		:= .T.
Default cApurac := ""

If !Empty(cApurac) .And. !IsInCallStack("InitDados")
	Help("",1,"At891BlqAp",,STR0024,4,10,,,,,,; //Não é possível excluir ou alterar um item que já foi apurado.
						{STR0020+Alltrim(cApurac)+"." }) //"Realize o estorno da apuração: "
	lRet := .F.
Endif

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At890LgTGU
Atribui a cor verde nos apontamento do material de consumo que não foram apurados e vermelho no que já foram apurados.

@param		cApurac - Codigo da apuração.

@return 	cCor - br_verde para o apontamento que não foi apurado
@return 	cCor - br_vermelho par ao apontamento já apurado

@author  	Serviços
@since 	  	09/10/17
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At891LgTGU(cItapur)
Local cCor		:= ""
Default cItapur := ""

If Empty(cItapur)
	cCor	:= 'br_verde'
Else
	cCor	:=  'br_vermelho'
EndIf

Return cCor

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At891GetLg

Cria as informações referentes a legenda do grid de material de consumo.

@author  Serviços
@since 	  09/10/17

@return lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At891GetLg()
Local	oLegenda := FwLegend():New()
       If	lLegend         
               oLegenda:Add('','GREEN',STR0025)	//"Apontamento não apurado"
               oLegenda:Add('','RED'  ,STR0025)			//"Apontamento Apurado"
               oLegenda:View()
               DelClassIntf()
       EndIf                                                                                                                                   
Return .T.
