#INCLUDE "Protheus.ch"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "TECA570.CH"

#DEFINE MODEL 1
#DEFINE VIEW 2

#DEFINE MANUT_TIPO_CANCEL	'05'	//Tipo Cancelamento

#DEFINE PERMISSAO_CLIENTE 		1
#DEFINE PERMISSAO_CONTRATO 		2
#DEFINE PERMISSAO_BASEATEND 		3
#DEFINE PERMISSAO_CONTRATOSERV 	4
#DEFINE PERMISSAO_EQUIPE 		5

Static cAliasTmp := ""//Alias Temporario dos dados de conflito
Static aPerm		:= NIL //Controle de permissões. Esta variavel deverá ser recuperada através do método at570getPe()
/*
{Protheus.doc} TECA570

Apresenta conflitos de alocação relacionados a demissão, férias ou afastamentos no RH. 

@param aParam 	Array 		Array com informações para realização do filtro, caso não seja passado será apresentado pergunte para realização do filtro
								[1]Data Inicial de Alocação
								[2]Data Final de alocação
								[3]Atendente De
								[4]Atendente Ate
@param lPrevisao	Boolean 	Caso Verdadeiro será apresentada a previsão dos conflitos conforme datas do parametro, caso falso será apresentado conflitos existentes na alocação.
	
@owner  rogerio.souza
@author  rogerio.souza
@version P11.8
@since   04/06/2013 
@return Nil
@menu    
*/
Function TECA570(aParam, lPrevisao)

Local oDialog	:= Nil

Local aSize	:= FWGetDialogSize( oMainWnd )
Local cPerg := "TEC570"
Local lExibe := .T.
Local dAlocDe := STOD("")
Local dAlocAte := STOD("")
Local cAtendDe := ""
Local cAtendAte := ""
Local cPermissao := ""
Local lContRefr := .T.//Controle para execução de refresh

Default lPrevisao := .F.
Private cCadastro := "" 
Private oBrowse := Nil

If at570CPerm()//controla permissoes?
	cPermissao := AT570Perm()
	If Empty(cPermissao)
		Help( ' ', 1, 'TECA570', , STR0017, 1, 0 )	//"Usuário sem permissão de acesso para as informações de alocação!"
		lExibe := .F.
	EndIf
EndIf

If lExibe
	If (ValType(aParam)=="A" .AND. Len(aParam) > 0)
		dAlocDe 	:= aParam[1]
		dAlocAte 	:= aParam[2]
		cAtendDe 	:= aParam[3]
		cAtendAte 	:= aParam[4]
	Else
		lExibe 		:= Pergunte(cPerg, .T.)
		dAlocDe 	:= MV_PAR01
		dAlocAte 	:= MV_PAR02
		cAtendDe 	:= MV_PAR03
		cAtendAte 	:= MV_PAR04
	EndIf
EndIf

If lExibe
	cAliasTmp 	:= GetNextAlias()
	
	oBrowse := FWFormBrowse():New()
	
	oBrowse:SetDataQuery(.T.)
	If lPrevisao
		oBrowse:SetQuery( AT570QryPrev(dAlocDe, dAlocAte, cAtendDe, cAtendAte) )
	Else
		oBrowse:SetQuery( AT570Query(dAlocDe, dAlocAte, cAtendDe, cAtendAte) )			
	EndIf
	oBrowse:SetAlias( cAliasTmp )
	oBrowse:AddStatusColumns( { || AT570Status( cAliasTmp ) }, { || AT570Legen() } )						
	oBrowse:SetColumns( AT570Colum() )
	oBrowse:SetUseFilter( .T. )
	//filtros
	oBrowse:SetFilterDefault( "At570Filter()") 	
 	
	oBrowse:AddButton( STR0007, { || AT570Legen()},,2,, .F., 2 )	//'Legenda'		
	oBrowse:AddButton( STR0002, { || If((oBrowse:Alias())->(!EOF()), FWExecView(STR0003,'TECA570', MODEL_OPERATION_VIEW,, { || .T. } ),NIL) },,2,, .F., 2 )	//'Visualizar' - Conflito de Alocação
	If !IsInCallStack('AT570Detal')
		oBrowse:AddButton( STR0008, { || MsgRun ( STR0009, STR0008, {|| AT570Subst(oBrowse:Alias())} ), MsgRun ( STR0011, STR0010, {|| AT570Refresh(oBrowse)} ) },,4,, .F., 2 )	//'Substituir' - Realizando Substituição
		oBrowse:AddButton( STR0013, { || If(Pergunte("TEC570"), MsgRun ( STR0011, STR0010, {|| AT570Refresh(oBrowse)} ),NIL) },,4,, .F., 2 )	//Opções - 'Atualizar' - Atualizando
	EndIf
	oBrowse:AddButton( STR0001, { ||oDialog:End() },,,, .F., 2 )	//'Sair'
					
	If (cAliasTmp)->(RecCount()) == 0
		Help( ' ', 1, 'TECA570', , STR0014, 1, 0 )	//"Não há registros para serem exibidos!"			
	Else
		oDialog := MsDialog():New( aSize[1], aSize[2], aSize[3], aSize[4], "", , , , , , , , /*oMainWnd*/, .T. )	
		oBrowse:SetOwner( oDialog )
		oBrowse:Activate()
		oDialog:Activate()					
	EndIf
		
EndIf

Return

//
/*
{Protheus.doc} AT570Colum

Recupera informações das colunas que serão exibidas no browse
	
@owner  rogerio.souza
@author  rogerio.souza
@version P11.8
@since   04/06/2013 
@return aColumns Array
*/
Static Function AT570Colum()
Local aCampos := AT570Field()
Local aColumns:= {}
Local nI 		:= 1
Local nJ 		:= 1
Local aArea	:= GetArea()
Local aAreaSX3:= SX3->(GetArea())	
	
DbSelectArea('SX3')		//Campos da tabela
SX3->( DbSetOrder(2) )	//X3_CAMPO

For	nI:=1 To Len(aCampos)
	If ( SX3->( MsSeek( aCampos[nI] ) ) )
	
		AAdd( aColumns, FWBrwColumn():New() )
		
		If ( SX3->X3_TIPO == "D"  )
			aColumns[nJ]:SetData( &("{||SToD(" + aCampos[nI] + ")}") )
		Else
			aColumns[nJ]:SetData( &("{||" + aCampos[nI] + "}") )
		EndIf	
	
		aColumns[nJ]:SetTitle( X3Titulo() )
		aColumns[nJ]:SetSize( SX3->X3_TAMANHO )
		aColumns[nJ]:SetDecimal( SX3->X3_DECIMAL )
		aColumns[nJ]:SetPicture( SX3->X3_PICTURE )
		
		If aCampos[nI] == "RH_DATAINI"
			aColumns[nJ]:SetData( {|| At570IniF()} )
		ElseIf aCampos[nI] == "RH_DATAFIM"
			aColumns[nJ]:SetData( {|| At570FimF()} )			
		EndIf		
		
		nJ++
	EndIf	
Next nI

RestArea(aAreaSX3)
RestArea(aArea)
	
Return aColumns

//
/*
{Protheus.doc} ModelDef

Definição do Model da rotina TECA570
	
@owner  rogerio.souza
@author  rogerio.souza
@version P11.8
@since   04/06/2013 
@return oModel MPFormModel Modelo da rotina 
*/
Static Function ModelDef()
Local oModel:= MPFormModel():New('TECA570', /*bPreValidacao*/, /**/, {||.T.}, /*bCancel*/ )
Local oStru := AT570Struc(MODEL)

oModel:AddFields( 'MASTER', /*cOwner*/, oStru, /*bPreValidacao*/, /*bPosValidacao*/, {||} )

oModel:SetDescription( STR0003 )
oModel:GetModel( 'MASTER'):SetDescription( STR0003 )

oModel:SetActivate( {|oModel| AT570LoadM( oModel ) } )
oModel:setPrimaryKey({})

Return oModel

/*
{Protheus.doc} ViewDef

Definição da View

@param  
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return oView FWFormView
*/
Static Function ViewDef() 
Local oView := Nil
Local oStruct := AT570Struc(VIEW)
Local oModel   := FWLoadModel( 'TECA570' )
Local aCpos := AT570Field()
Local nI := 1

//Atribui propriedade somente visualização
For nI:=1 To Len(aCpos)
	oStruct:SetProperty( aCpos[nI] , MVC_VIEW_CANCHANGE, .F.)
Next nI


oView := FWFormView():New()
oView:SetModel( oModel )
 
oView:AddField( 'VIEW_TECA570', oStruct, 'MASTER' )//Add Controle

oView:CreateHorizontalBox( 'TELA' , 100 )// Criar um "box" horizontal para receber algum elemento da view

oView:SetOwnerView( 'VIEW_TECA570', 'TELA' )// Relaciona o ID da View com o "box" para exibicao

Return oView


/*Static Function MenuDef()
Local aRotina := {}
ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.TECA570' OPERATION 3 ACCESS 0
Return aRotina*/



/*
{Protheus.doc} AT570Field

Retorna campos que serão utilizados

@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return aCampos Array array com campos utilizados 
*/
Static Function AT570Field()
Local aCampos := {}

aAdd(aCampos, "AA1_CODTEC")//Codigo do Atendente
aAdd(aCampos, "AA1_NOMTEC")//Nome do Atendnete
aAdd(aCampos, "ABB_DTINI")//Data Alocação Inicial
aAdd(aCampos, "ABB_HRINI")//Hora Alocação Inicial
aAdd(aCampos, "ABB_DTFIM")//Data Alocação Inicial
aAdd(aCampos, "ABB_HRFIM")//Hora Alocação Final
aAdd(aCampos, "RA_SITFOLH")//Situação no GPE
aAdd(aCampos, "RH_DATAINI")//Data Inicial Programação Férias
aAdd(aCampos, "RH_DATAFIM")//Data Final Programação Férias
aAdd(aCampos, "R8_DATAINI")//Data Inicial Afastamento
aAdd(aCampos, "R8_DATAFIM")//Data Final Afastamento
aAdd(aCampos, "RA_DEMISSA")//Data de Demissão

Return aCampos


//Retorna Estrutura para o Model
/*
{Protheus.doc} AT570Struc

Recupera estrutura de Model ou de View da rotina TECA570

@param  nType Integer - 1(MODEL), 2(VIEW)
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return oStruct - FWFormModelStruct ||  FWFormViewStruct
*/
Static Function AT570Struc(nType)
Local oStruct := Nil
Local aCampos := AT570Field()
Local nI := 1
Local aArea	:= GetArea()
Local aAreaSX3:= SX3->(GetArea())	
Local bBlockIni := Nil

If nType == MODEL
	oStruct := FWFormModelStruct():New()
Else
	oStruct := FWFormViewStruct():New()
EndIf
		
DbSelectArea('SX3')		//Campos da tabela
SX3->( DbSetOrder(2) )	//X3_CAMPO
	
For	nI:=1 To Len(aCampos)		
	
	If ( SX3->( MsSeek( aCampos[nI] ) ) )
			
		If nType == MODEL//Estrutura para Model
						
			If aCampos[nI] == "RH_DATAINI"
				bBlockIni := {|| At570IniF()}
			ElseIf aCampos[nI] == "RH_DATAFIM"
				bBlockIni := {|| At570FimF()}
			Else
				bBlockIni := Nil			
			EndIf	
			
			oStruct:AddField( ;
				X3Titulo()  		, ;             // [01] Titulo do campo
				X3Descric()	, ;             // [02] ToolTip do campo
				AllTrim(aCampos[nI])     	, ;             // [03] Id do Field
				SX3->X3_TIPO		, ;            	// [04] Tipo do campo
				SX3->X3_TAMANHO	, ;             // [05] Tamanho do campo
				SX3->X3_DECIMAL 	, ;               // [06] Decimal do campo
				/*NIL*/            , ;               // [07] Code-block de validação do campo
				/*{||.F.}*/   		, ;               // [08] Code-block de validação When do campo
				/*NIL*/ 			, ;         	  // [09] Lista de valores permitido do campo
				/*.F.*/     		, ;               // [10] Indica se o campo tem preenchimento obrigatório
				bBlockIni          , ;               // [11] Code-block de inicializacao do campo
				/*.F.*/            , ;               // [12] Indica se trata-se de um campo chave
				.T.					, ;               // [13] Indica se o campo pode receber valor em uma operação de update.
				.T.     )              				  // [14] Indica se o campo é virtual
		Else// Estrutura para View			
		    oStruct:AddField( ;
			    aCampos[nI]   			, ;             // [01] Campo
			    cValToChar(nI)        , ;             	// [02] Ordem
			    X3Titulo()	        	, ;             	// [03] Titulo
			    X3Descric()           , ;             	// [04] Descricao
			    /*{}*/                 , ;             	// [05] Help
			    'GET'					, ;             	// [06] Tipo do campo   COMBO, Get ou CHECK
			    SX3->X3_PICTURE		, ;             	// [07] Picture
			    /*''*/                 	, ;             	// [08] PictVar
			    /*NIL*/            	, ;            		// [09] F3
			    .T.						, ;             	// [10] Editavel
			    '01'                 	, ;        			// [11] Folder
			    /*''*/           		, ;            		// [12] Group
			    /*{}*/                 	, ;            		// [13] Lista Combo
			    /*10*/                 	, ;            		// [14] Tam Max CombO
			    /*''*/               	, ;            		// [15] Inic. Browse
			    .T.  )               						// [16] Virtual		  
		EndIf	
	EndIf		
Next nI	

RestArea(aAreaSX3)
RestArea(aArea)

Return oStruct


/*
{Protheus.doc} AT570Query

Recupera query para listagem dos cnflitos

@param dAlocDe 	Data Data inicial de alocação
@param	dAlocAte 	Data Data Final de Alocação
@param	cAtendDe 	String Atendente De
@param cAtendAte	String Atendente Ate
@param cPermissao String COndição para filtro devido a permissoes
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return cQuery String Query para recuperação de conflitos com o RH 
*/
Static Function AT570Query(dAlocDe, dAlocAte, cAtendDe,  cAtendAte)

Local cQuery := ""
Local cPermissao := ""
Local lUsaEAIGS := ( !Empty(SuperGetMv( "MV_RHMUBCO",,"")) ) // verifica se está com integração via EAI habilitada
		
cQuery += " SELECT DISTINCT " 
cQuery += 		"ABB.ABB_FILIAL,"
cQuery += 		"AA1.AA1_CODTEC,"
cQuery += 		"AA1.AA1_NOMTEC,"
cQuery += 		"ABB.ABB_DTINI,"
cQuery += 		"ABB.ABB_HRINI,"
cQuery += 		"ABB.ABB_DTFIM,"
cQuery += 		"ABB.ABB_HRFIM,"
cQuery += 		"COALESCE(SRA.RA_SITFOLH,' ') RA_SITFOLH,"
cQuery += 		"COALESCE(SRA.RA_DEMISSA,' ') RA_DEMISSA,"
cQuery += 		"COALESCE(SRF.RF_DATAINI,' ') RF_DATAINI,"
cQuery += 		"COALESCE(SRF.RF_DFEPRO1, 0 ) RF_DFEPRO1,"
cQuery += 		"COALESCE(SRF.RF_DATINI2,' ') RF_DATINI2,"
cQuery += 		"COALESCE(SRF.RF_DFEPRO2, 0 ) RF_DFEPRO2,"
cQuery += 		"COALESCE(SRF.RF_DATINI3,' ') RF_DATINI3,"
cQuery += 		"COALESCE(SRF.RF_DFEPRO3, 0 ) RF_DFEPRO3,"	
cQuery += 		"COALESCE(SRH.RH_DATABAS,' ') RH_DATABAS,"
cQuery += 		"COALESCE(SRH.RH_DBASEAT,' ') RH_DBASEAT,"
cQuery += 		"COALESCE(SR8.R8_DATAINI,' ') R8_DATAINI,"
cQuery += 		"COALESCE(SR8.R8_DATAFIM,' ') R8_DATAFIM "

cQuery += "FROM "+RetSqlName("ABB")+" ABB"	

cQuery += " LEFT JOIN "+RetSqlName("AA1")+" AA1"
cQuery += 		" ON AA1.AA1_FILIAL = ABB.ABB_FILIAL" 
cQuery += 		" AND AA1.AA1_CODTEC = ABB.ABB_CODTEC"
cQuery += 		" AND AA1.D_E_L_E_T_ = ' '"

cQuery += " LEFT JOIN "+RetSqlName("SRA")+" SRA"
cQuery += 		" ON SRA.RA_FILIAL = AA1.AA1_FUNFIL"
cQuery += 		" AND SRA.RA_MAT = AA1.AA1_CDFUNC"
cQuery += 		" AND SRA.D_E_L_E_T_ = ' '"

cQuery += " LEFT JOIN "+RetSqlName("SR8")+" SR8"
cQuery += 		" ON SR8.R8_FILIAL = SRA.RA_FILIAL"
cQuery += 		" AND SR8.R8_MAT = SRA.RA_MAT"
cQuery += 		" AND ( "
cQuery += 		"       ( SR8.R8_DATAFIM = '' AND ABB.ABB_DTINI <= SR8.R8_DATAINI ) OR   
cQuery += 		"       ( SR8.R8_DATAFIM <>'' AND NOT (SR8.R8_DATAFIM < ABB.ABB_DTINI OR SR8.R8_DATAINI > ABB.ABB_DTFIM )"
cQuery += 			" ))"
cQuery += 		" AND SR8.D_E_L_E_T_ = ' '"

cQuery += " LEFT JOIN "+RetSqlName("SRH")+" SRH"
cQuery += 		" ON SRH.RH_FILIAL = SRA.RA_FILIAL"
cQuery += 		" AND SRH.RH_MAT = SRA.RA_MAT"
cQuery += 		" AND NOT (SRH.RH_DBASEAT < ABB.ABB_DTINI OR SRH.RH_DATABAS > ABB.ABB_DTFIM)"
cQuery += 		" AND SRH.D_E_L_E_T_ = ' '"

cQuery += " LEFT JOIN "+RetSqlName("SRF")+" SRF"	
cQuery += 		" ON SRF.RF_FILIAL = SRA.RA_FILIAL"
cQuery += 		" AND SRF.RF_MAT = SRA.RA_MAT	"
cQuery += 		" AND SRF.D_E_L_E_T_ = ' '"
cQuery += 		" AND "

cQuery += "("
cQuery += 		"("			
cQuery += 			" ABB.ABB_DTINI >= SRF.RF_DATAINI OR"
cQuery += 			" ABB.ABB_DTFIM <= SRF.RF_DATAINI"		
cQuery += 		") OR ("
cQuery += 			" ABB.ABB_DTINI >= SRF.RF_DATINI2 OR"
cQuery += 			" ABB.ABB_DTFIM <= SRF.RF_DATINI2 "		
cQuery += 		") OR ("
cQuery += 			" ABB.ABB_DTINI >= SRF.RF_DATINI3 OR"
cQuery += 			" ABB.ABB_DTFIM <= SRF.RF_DATINI3 "		
cQuery += 		")"
cQuery += ")"
	
cQuery += " WHERE "
cQuery += 		" ABB.ABB_FILIAL = '"+xFilial("ABB")+"'"		
cQuery += 		" AND ABB.ABB_CODTEC BETWEEN '"+cAtendDe+"' AND '"+cAtendAte+"'"
cQuery += 		" AND ("
cQuery += 		" ABB.ABB_DTINI BETWEEN '"+DTOS(dAlocDe)+"' AND '"+DTOS(dAlocAte)+"' OR"
cQuery += 		" ABB.ABB_DTFIM BETWEEN '"+DTOS(dAlocDe)+"' AND '"+DTOS(dAlocAte)+"'"
cQuery += 		")"
cQuery += 		" AND ABB.ABB_ATIVO ='1'"
cQuery += 		" AND ABB.ABB_ATENDE ='2'"
	
cQuery += 		" AND ABB.D_E_L_E_T_ = ' '"
cQuery += 		" AND ("
cQuery += 			" (SRA.RA_DEMISSA <> '' AND SRA.RA_DEMISSA <= ABB.ABB_DTINI) OR"
cQuery += 			" (SRA.RA_DEMISSA <> '' AND SRA.RA_DEMISSA <= ABB.ABB_DTFIM)"

If lUsaEAIGS
	cQuery += 		" OR SRA.RA_SITFOLH = 'A'"
Else
	cQuery += 		" OR SR8.R8_DATAINI <> '"+Space(8)+"'"
EndIf

cQuery += 			" OR SRH.RH_DATABAS <> '"+Space(8)+"'"
cQuery += 			" OR SRF.RF_DATAINI <> '"+Space(8)+"'"
cQuery += 			" OR SRF.RF_DATINI2 <> '"+Space(8)+"'"
cQuery += 			" OR SRF.RF_DATINI3 <> '"+Space(8)+"'"
cQuery += 		")"	

If At570CPerm()//controla permissoes?
	cPermissao := AT570Perm()
	If !Empty(cPermissao)		
		cQuery += cPermissao
	EndIf
EndIf

cQuery += " ORDER BY AA1_CODTEC, AA1_NOMTEC, ABB_DTINI, ABB_HRINI, ABB_DTFIM"

Return ChangeQuery(cQuery)

/*
{Protheus.doc} AT570QryPC
Encapsula a função AT570QryPrev que retorna uma string em forma de query de previsão de conflitos

@param dAlocDe 	Data Data inicial de alocação
@param	dAlocAte 	Data Data Final de Alocação
@param	cAtendDe 	String Atendente De
@param cAtendAte	String Atendente Ate
@param aLstAte	Array Contendo uma Lista simples com os códigos dos atendentes que se deseja consultar.

@version V12
@since   21/05/2015 
@return cQuery String Query para recuperação de conflitos com o RH em uma determinada data
*/
Function AT570QryPC(dAlocDe, dAlocAte, cAtendDe, cAtendAte, aLstAte)
Local cRet := ""
cRet := AT570QryPrev(dAlocDe, dAlocAte, cAtendDe, cAtendAte, aLstAte)
Return cRet


/*
{Protheus.doc} AT570QryPrev

Recupera query para previsão de conflitos

@param dAlocDe 	Data Data inicial de alocação
@param	dAlocAte 	Data Data Final de Alocação
@param	cAtendDe 	String Atendente De
@param cAtendAte	String Atendente Ate
@param aLstAte	Array Contendo uma Lista simples com os códigos dos atendentes que se deseja consultar.
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return cQuery String Query para recuperação de conflitos com o RH em uma determinada data
*/
Static Function AT570QryPrev(dAlocDe, dAlocAte, cAtendDe, cAtendAte, aLstAte)

Local cQuery := ""
Local lUsaEAIGS := ( !Empty(SuperGetMv( "MV_RHMUBCO",,"")) ) // verifica se está com integração via EAI habilitada
Local nI := 0
Local cLstAte := ""
	
Default aLstAte := {}	//{cCdAte1,cCdAte2,..,cCdAten} - Entre cada par de aspas simples deve constar um código de atendente
	
cQuery := "SELECT DISTINCT"
cQuery += " AA1.AA1_FILIAL, "
cQuery += " AA1.AA1_CODTEC, "
cQuery += " AA1.AA1_NOMTEC,  "
cQuery += " '"+DTOS(dAlocDe)+"' AS ABB_DTINI, "
cQuery += " '  :  ' AS ABB_HRINI, "
cQuery += " '"+DTOS(dAlocAte)+"' AS ABB_DTFIM, "
cQuery += " '  :  ' AS ABB_HRFIM,  "
cQuery += " COALESCE(SRA.RA_SITFOLH,' ') RA_SITFOLH, " 
cQuery += " COALESCE(SRA.RA_DEMISSA,' ') RA_DEMISSA,  "
cQuery += " COALESCE(SRF.RF_DATAINI,' ') RF_DATAINI,"
cQuery += " COALESCE(SRF.RF_DFEPRO1, 0 ) RF_DFEPRO1,"
cQuery += " COALESCE(SRF.RF_DATINI2,' ') RF_DATINI2,"
cQuery += " COALESCE(SRF.RF_DFEPRO2, 0 ) RF_DFEPRO2,"
cQuery += " COALESCE(SRF.RF_DATINI3,' ') RF_DATINI3,"
cQuery += " COALESCE(SRF.RF_DFEPRO3, 0 ) RF_DFEPRO3,"	
cQuery += " COALESCE(SRH.RH_DATABAS,' ') RH_DATABAS,"
cQuery += " COALESCE(SRH.RH_DBASEAT,' ') RH_DBASEAT,"
cQuery += " COALESCE(SR8.R8_DATAINI,' ') R8_DATAINI,"
cQuery += " COALESCE(SR8.R8_DATAFIM,' ') R8_DATAFIM "

cQuery += " FROM "+RetSqlName("AA1")+" AA1 "

cQuery += "	LEFT JOIN "+RetSqlName("SRA")+"  SRA " 	
cQuery += 		" ON SRA.RA_FILIAL = AA1.AA1_FUNFIL AND SRA.RA_MAT = AA1.AA1_CDFUNC AND SRA.D_E_L_E_T_ = ' ' " 
	
cQuery += "	LEFT JOIN  "+RetSqlName("SR8")+" SR8 " 	
cQuery += 		"ON SR8.R8_FILIAL = SRA.RA_FILIAL 	AND SR8.R8_MAT = SRA.RA_MAT " 	
cQuery += 			" AND ( " 				
cQuery += 		    "       ( SR8.R8_DATAFIM = '' AND '"+DTOS(dAlocDe)+"' <= SR8.R8_DATAINI ) OR   
cQuery += 		    "       ( SR8.R8_DATAFIM <>'' AND NOT (SR8.R8_DATAFIM < '"+DTOS(dAlocDe)+"' OR SR8.R8_DATAINI > '"+DTOS(dAlocAte)+"') )"
cQuery += 			"     ) "
cQuery += "	AND SR8.D_E_L_E_T_ = ' ' " 

cQuery += " LEFT JOIN "+RetSqlName("SRH")+" SRH"
cQuery += 		" ON SRH.RH_FILIAL = SRA.RA_FILIAL"
cQuery += 		" AND SRH.RH_MAT = SRA.RA_MAT"
cQuery += 		" AND NOT (SRH.RH_DBASEAT < '"+DTOS(dAlocDe)+"' OR SRH.RH_DATABAS > '"+DTOS(dAlocAte)+"')"
cQuery += 		" AND SRH.D_E_L_E_T_ = ' '"

cQuery += "	LEFT JOIN "+RetSqlName("SRF")+" SRF "
cQuery += 		" ON SRF.RF_FILIAL = SRA.RA_FILIAL "
cQuery += 		" AND SRF.RF_MAT = SRA.RA_MAT "
cQuery += 		" AND SRF.D_E_L_E_T_ = ' ' "
cQuery += 		" AND " 
cQuery += "("
cQuery += 		"("			
cQuery += 		" '"+DTOS(dAlocDe)+"' >= SRF.RF_DATAINI OR"
cQuery += 		" '"+DTOS(dAlocAte)+"' <= SRF.RF_DATAINI"		
cQuery += 		")OR("
cQuery += 		" '"+DTOS(dAlocDe)+"' >= SRF.RF_DATINI2 OR"
cQuery += 		" '"+DTOS(dAlocAte)+"' <= SRF.RF_DATINI2 "		
cQuery += 		")OR("
cQuery += 		" '"+DTOS(dAlocDe)+"' >= SRF.RF_DATINI3 OR"
cQuery += 		" '"+DTOS(dAlocAte)+"' <= SRF.RF_DATINI3 "		
cQuery += 		")"
cQuery += ")"

cQuery += "	WHERE  "
 
cQuery += "	AA1.AA1_FILIAL = '"+xFilial('AA1')+"' "

If Empty(aLstAte)
	cQuery += "	AND AA1.AA1_CODTEC >= '"+cAtendDe+"' "
	cQuery += "	AND AA1.AA1_CODTEC <= '"+cAtendAte+"' " 
Else
	cLstAte := "("
	For nI := 1 to Len(aLstAte)
	 	cLstAte += "'" + aLstAte[nI] 
	 	cLstAte += If(Len(aLstAte) == nI, "'","';")
	Next nI
	cLstAte += ") "
	
	cQuery += "	AND AA1.AA1_CODTEC IN " + cLstAte
EndIf

cQuery += "	AND AA1.D_E_L_E_T_ = ' ' " 	
cQuery += "	AND ("
cQuery += "	(SRA.RA_DEMISSA <> '' AND SRA.RA_DEMISSA <= '"+DTOS(dAlocDe)+"') OR "
cQuery += "	(SRA.RA_DEMISSA <> '' AND SRA.RA_DEMISSA <= '"+DTOS(dAlocAte)+"') OR "

If lUsaEAIGS
	cQuery += "	SRA.RA_SITFOLH = 'A' "
Else
	cQuery += "	SR8.R8_DATAINI <> '' "
EndIf

cQuery += " OR SRH.RH_DATABAS <> '"+Space(8)+"'"

cQuery += " OR SRF.RF_DATAINI <> '' OR SRF.RF_DATINI2 <> '' OR SRF.RF_DATINI3 <> '' OR SR8.R8_DATAINI <> '' "
cQuery += ")"
cQuery += "	ORDER BY AA1_CODTEC,"
cQuery += "	AA1_NOMTEC,"
cQuery += "	ABB_DTINI,"
cQuery += "	ABB_HRINI,"
cQuery += "	ABB_DTFIM"

Return ChangeQuery(cQuery)


/*
{Protheus.doc} AT570LoadM

Realiza o Carregamento no Model

@param	oModel MPFormModel
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return 
*/
Static Function AT570LoadM(oModel)
	Local aCpos := AT570Field()
	Local nI := 1	
	Local oStruct := oModel:GetModel("MASTER"):GetStruct()		
	
	For nI:=1 To Len(aCpos)
		If !aCpos[nI] $ "RH_DATAINI|RH_DATAFIM"
			If oStruct:GetProperty(aCpos[nI], MODEL_FIELD_TIPO) == "D"		
				oModel:LoadValue("MASTER",aCpos[nI], STOD((cAliasTmp)->&(aCpos[nI])))
			Else
				oModel:LoadValue("MASTER",aCpos[nI], (cAliasTmp)->&(aCpos[nI]))
			EndIf
		EndIf		
	Next nI
	
Return

/*
{Protheus.doc} AT570Status

Recupera Status de conflito para apresentação no Browse

@param  cAlias	String	Alias aberto para verificação do status
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return cStatus	String Status do registro do cAlias
*/
Static Function AT570Status(cAlias)

Local cStatus := ''	
Local cFeriasIni := DTOS(At570IniF())
Local cFeriasFim := DTOS(At570FimF())
Local lUsaEAIGS := ( !Empty(SuperGetMv( "MV_RHMUBCO",,"")) ) // verifica se está com integração via EAI habilitada

//Demissão
If !Empty((cAlias)->RA_DEMISSA) .AND. ((cAlias)->RA_DEMISSA <= (cAlias)->ABB_DTINI .OR. (cAlias)->RA_DEMISSA <= (cAlias)->ABB_DTFIM)
	cStatus := 'BR_VERMELHO'
	
//Férias
ElseIf ((cAlias)->ABB_DTINI >= cFeriasIni .AND. (cAlias)->ABB_DTINI <= cFeriasFim) .OR.;
		((cAlias)->ABB_DTFIM >= cFeriasIni .AND. (cAlias)->ABB_DTFIM <= cFeriasFim) .OR.;
		((cAlias)->ABB_DTINI <= cFeriasIni .AND. (cAlias)->ABB_DTFIM >= cFeriasFim)
	cStatus := "BR_AZUL"
	
//Afastamento
ElseIf	( ( lUsaEAIGS .And. (cAlias)->RA_SITFOLH = 'A' ) ;
		.OR. ( !lUsaEAIGS .And. ;
		((cAlias)->ABB_DTINI >= (cAlias)->R8_DATAINI .AND. (cAlias)->ABB_DTINI <= (cAlias)->R8_DATAFIM) .OR.;
		((cAlias)->ABB_DTFIM >= (cAlias)->R8_DATAINI .AND. (cAlias)->ABB_DTFIM <= (cAlias)->R8_DATAFIM) .OR.;
		((cAlias)->ABB_DTINI >= (cAlias)->R8_DATAINI .AND. Empty((cAlias)->R8_DATAFIM) ) .OR.;
		((cAlias)->ABB_DTFIM >= (cAlias)->R8_DATAINI .AND. Empty((cAlias)->R8_DATAFIM) ) ;
		))
	cStatus := "BR_AMARELO"	
									
EndIf

Return cStatus

/*
{Protheus.doc} AT570Legen

Aprensentação das Legendas disponiveis

@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
*/
Static Function AT570Legen()
	Local oLegenda  :=  FWLegend():New()

	oLegenda:Add( '', 'BR_VERMELHO'	, STR0004 )	//'Alocação com Demissão'
	oLegenda:Add( '', 'BR_AMARELO'	, STR0005 )	//'Alocação com Afastamento'
	oLegenda:Add( '', 'BR_AZUL'		, STR0006 )	//'Alocação com Férias'

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()

Return Nil

//Substituição da alocação
/*
{Protheus.doc} AT570Subst

Apresenta tela para escolha de substituto e gera registro na manunteção da alocação. 

@param  cAlias	String
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013  
*/
Function AT570Subst(cAlias)
	
	Local aCarga := {}
	Local aArea:=GetArea()
	Local aAreaABB := ABB->(GetArea())	
	Local aAreaABR := ABR->(GetArea())	
	Local cCodAtdSub := ""
	Local aErro := {}
	Local cAliasBkp := ""
	Local cAliasABB:=""	
	Local aQry540 := {}
	Local cQryABB := ""
	Local lRet := .T.
	
	Local cMotivo :=  SuperGetMV("MV_ATMTCAN", , "") //Parametro para motivo de cancelamentol
	
	//Valida Motivo de cancelamento
	If ValType(cMotivo) != "C" .OR. !AT570VldMt(AllTrim(cMotivo))
		Help( ' ', 1, 'AT570Subst', , STR0012, 1, 0 )	//"Parametro MV_ATMTCAN deve ser um motivo do tipo de Cancelamento."
		Return .F.
	EndIf                                                     

	cMotivo := AllTrim(cMotivo) 		
	
	//Encontra informações para a carga
	ABB->(DbSetOrder(1))//ABB_FILIAL+ABB_CODTEC+DTOS(ABB_DTINI)+ABB_HRINI+DTOS(ABB_DTFIM)+ABB_HRFIM	
	If ABB->(MsSeek( (cAlias)->ABB_FILIAL+(cAlias)->AA1_CODTEC+(cAlias)->ABB_DTINI+(cAlias)->ABB_HRINI+(cAlias)->ABB_DTFIM+(cAlias)->ABB_HRFIM))
		
		//Recupera contrato e Origem
		ABQ->(DbSetOrder(1))//ABQ_CONTRT+ABQ_ITEM+ABQ_ORIGEM
		If ABQ->(DbSeek(xFilial("ABQ")+ABB->ABB_IDCFAL))
			AAdd( aCarga, { ABB->ABB_CODTEC 										 	,;
							SubStr( ABB->ABB_IDCFAL, 1, TAMSX3( 'AAH_CONTRT' )[1] )	,;
				            ABB->ABB_CODIGO  					   							,;
				            DTOS(ABB->ABB_DTINI)												,;
				            ABB->ABB_HRINI	   											,;
				            DTOS(ABB->ABB_DTFIM)	   											,;
				            ABB->ABB_HRFIM} )//Origem		
			
					
			//Verifica Manutenções
			If	AT570CkMan(ABB->ABB_FILIAL, ABB->ABB_CODIGO) 
				Help( ' ', 1, 'AT570Subst', , STR0015, 1, 0 )	//"A agenda já possui manutenção por motivo de cancelamento."
				
			Else//Não existe manutenção do tipo Cancelamento '05'
				If TECA560( aCarga, @cCodAtdSub, ABQ->ABQ_ORIGEM )//Apresenta tela para atendente substituto		
			
					cAliasABB := GetNextAlias()
					cAliasBkp := At550GtAls()		
				
					aQry540 := AT540ABBQry( ABB->ABB_CODTEC, ABB->ABB_CHAVE, ABB->ABB_DTINI, ABB->ABB_DTFIM, Nil , Nil, ABB->ABB_CODIGO, .T., ABB->ABB_ENTIDA )//Recupera cQuery para o model da TECA550
					
					If Len(aQry540) > 0 
						
						cQryABB := aQry540[1]
						//Habilita registros no Alias temporario para ser considerada a agenda no Model TECA550
						dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryABB),cAliasABB)
														
						AT550StAls(cAliasABB)//Add Alias para o model
						
						oModel		:= FWLoadModel( "TECA550" )	//Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
						
						oModel:SetOperation(MODEL_OPERATION_INSERT)
						oModel:Activate()
						
						If !Empty(cCodAtdSub)		
						
							oModel:SetValue( 'ABRMASTER', 'ABR_MOTIVO', cMotivo)
							oModel:SetValue( 'ABRMASTER', 'ABR_CODSUB', cCodAtdSub)
							
							lRet := oModel:VldData()
							If ( lRet )											
								lRet := oModel:CommitData()//Grava Model
							Else
								aErro   := oModel:GetErrorMessage()						
								Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )					
							EndIf
						EndIf
					EndIf
	
					At550StAls(cAliasBkp)//Volta alias original para rotina
				EndIf	
			EndIf
		EndIf
	EndIf
	
	RestArea(aAreaABB)
	RestArea(aAreaABR)
	RestArea(aArea)
Return lRet

//Atualiza Browse
/*
{Protheus.doc} AT570Refresh

Atualiza o Browse

@param  oBrw FWFormBrowse
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013  
*/
Function AT570Refresh(oBrw)		

	oBrw:SetQuery( AT570Query(MV_PAR01, MV_PAR02, MV_PAR03, MV_PAR04) )		

	oBrw:Refresh( .T. )
Return


/*
{Protheus.doc} AT570VldMt

Realiza validação do motivo de manut
@param  cMotivo String Motivo que será validado
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return lRet Boolean 
*/
Static Function AT570VldMt(cMotivo)
Local aArea 	:= GetArea()
Local aAreaABN := ABN->(GetArea())
Local cTipo	:= ''
Local lRet := .F.

If ValType(cMotivo) != "C"
	Return .F.
EndIf

DbSelectArea('ABN')
ABN->(DbSetOrder(1))//ABN_FILIAL+ABN_MOTIVO

If ( ABN->( DbSeek( xFilial('ABN') + cMotivo ) ) )
	cTipo := ABN->ABN_TIPO
EndIf

If cTipo == MANUT_TIPO_CANCEL
	lRet := .T.
EndIf

RestArea(aAreaABN)
RestArea( aArea )

Return lRet


/*
{Protheus.doc} At570VldRh

Valida Inconsistencias no RH para alocação em determinada data.
Retorn Verdadeiro caso não exista inconsistencias para o tecnico, Falso caso exista inconsistencias

@param	cCodTec	String Codigo do tecnico a ser validado
@param dDataIni	Data Data inicial de alocação a ser validada
@param dDataFim	Data Data Final de alocação a ser validada
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return lRet	Boolean 
*/
Function At570VldRh(cCodTec, dDataIni, dDataFim )
Local lRet := .T.
Local aArea := GetArea()
Local aAreaAA1:= AA1->(GetArea())
Local cFilFun := "" 
Local cMat := ""
Local lUsaEAIGS := ( !Empty(SuperGetMv( "MV_RHMUBCO",,"")) ) // verifica se está com integração via EAI habilitada
Local aChekFeri	:= {}

AA1->(DbSetOrder(1))//AA1_FILIAL+AA1_CODTEC
 
If AA1->(MsSeek(xFilial("AA1")+cCodTec))
	cFilFun := AA1->AA1_FUNFIL
	cMat := AA1->AA1_CDFUNC	
EndIf

If !Empty(cMat)
	//Verifica se o atendente esta com as ferias programadas ou se esta de ferias.
	aChekFeri := CheckFeria(cFilFun, cMat, dDataIni, dDataFim)
	
	//Verifica inconsistencias em determinada data
	If CheckDemis(cFilFun, cMat, dDataIni, dDataFim) .OR. CheckAfast(cFilFun, cMat, dDataIni, dDataFim) .OR. (aChekFeri[1] .Or. aChekFeri[2] .Or. aChekFeri[3] .Or. aChekFeri[4])
		lRet := .F.
	ElseIf lUsaEAIGS .And. Posicione("SRA",1,xFilial("SRA")+cMat,"RA_SITFOLH") $ "A/D"
		lRet := .F.
	EndIf
	
EndIf 
		 
RestArea(aAreaAA1)
RestArea(aArea)
Return lRet 


/*
{Protheus.doc} CheckDemis

Verifica se há inconsistencia de Demissao 
Retorna Verdadeiro caso exista inconsitencia de alocação na data informada

@param  cFilFun	String	Filial do funcionário
@param  cMat		String	Matricula do Funcionario
@param  dDataIni	Data	Data inicial de alocação
@param  dDataFim	Data	Data Final de alocação
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return lRet Boolean	 
 */
Static Function CheckDemis(cFilFun, cMat, dDataIni, dDataFim)
	Local lRet := .F.
	Local aAreaSRA := SRA->(GetArea())
	
	SRA->(DbSetOrder(1))//RA_FILIAL+RA_MAT
	If SRA->(MsSeek(cFilFun+cMat))
		If !Empty(SRA->RA_DEMISSA) 
			If SRA->RA_DEMISSA <= dDataIni .OR. SRA->RA_DEMISSA <= dDataFim
				lRet := .T.
			EndIf
		EndIf 
	EndIf
	
	RestArea(aAreaSRA)
			
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CheckAfast

Verifica se há inconsistencia de Afastamento

Retorna Verdadeiro caso exista inconsitencia de alocação na data informada

@param  cFilFun	String	Filial do funcionário
@param  cMat		String	Matricula do Funcionario
@param  dDataIni	Data	Data inicial de alocação
@param  dDataFim	Data	Data Final de alocação
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return lRet Boolean	 
/*/
//-------------------------------------------------------------------
  
Static Function CheckAfast(cFilFun, cMat, dDataIni, dDataFim)
	Local lRet := .F.
	Local aArea := GetArea()
	Local cAlias := GetNextAlias() 
	
	BeginSQL alias cAlias		
		SELECT 	COUNT(*) NUM
 		FROM %table:SR8% SR8  
 		WHERE 
			SR8.%notDel%
 			AND SR8.R8_FILIAL = %exp:cFilFun% 				
 			AND SR8.R8_MAT = %exp:cMat%
 			AND ((NOT (%exp:dDataIni% > SR8.R8_DATAFIM OR %exp:dDataFim% < SR8.R8_DATAINI)) OR
       			 (%exp:dDataFim%>=SR8.R8_DATAINI AND SR8.R8_DATAFIM = '')
	            )
	EndSQL	

	If (cAlias)->(!Eof()) .AND. (cAlias)->NUM > 0
		lRet := .T.
	EndIf
	
	(cAlias)->(DbCloseArea())
	
	RestArea(aArea)
					
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CheckFeria

Verifica se há inconsistencia de Férias

Retorna Verdadeiro caso exista inconsitencia de alocação na data informada

@param  cFilFun	String	Filial do funcionário
@param  cMat		String	Matricula do Funcionario
@param  dDataIni	Data	Data inicial de alocação
@param  dDataFim	Data	Data Final de alocação
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
@return aRet Array, aRet[1] - Ferias programadas.
					aRet[2]	- Ferias programadas 2.
					aRet[3] - Ferias programadas 3.
					aRet[4] - Ferias processada.
					aRet[5] - Data inicio das ferias.
					aRet[6] - Data final das ferias.
/*/
//-------------------------------------------------------------------
  
Static Function CheckFeria(cFilFun, cMat, dDataIni, dDataFim)
	Local aRet 	:= {.F.,.F.,.F.,.F.,sTod(""),sTod("")} 
	Local aArea := GetArea()
	Local cAliasSRF := GetNextAlias()
	Local cAliasSR8 := GetNextAlias()  
	Local cFilRCM	:= xFilial('RCM',cFilFun)
	
	//Verifica se funcionário possui férias programadas	
	BeginSQL alias cAliasSRF			
		SELECT 	
			SRF.RF_DATAINI, 
			SRF.RF_DFEPRO1,
			SRF.RF_DATINI2,
			SRF.RF_DFEPRO2,
			SRF.RF_DATINI3,
			SRF.RF_DFEPRO3
			
 		FROM %table:SRF% SRF 
 		WHERE 
			SRF.%notDel%
 			AND SRF.RF_FILIAL = %exp:cFilFun% 				
 			AND SRF.RF_MAT = %exp:cMat%
 			AND ( 	
 					(
 						%exp:dDataIni% >= SRF.RF_DATAINI OR
						%exp:dDataFim% <= SRF.RF_DATAINI 				
					) OR (					
						%exp:dDataIni% >= SRF.RF_DATINI2 OR	
						%exp:dDataFim% <= SRF.RF_DATINI2  					
					) OR ( 	
						%exp:dDataIni% >= SRF.RF_DATINI3 OR
						%exp:dDataFim% <= SRF.RF_DATINI3 
 					)
 				) 	 			
	EndSQL	

	While (cAliasSRF)->(!Eof())
	
		If !Empty((cAliasSRF)->RF_DATAINI) .AND.;
			DTOS(dDataIni) >= (cAliasSRF)->RF_DATAINI .AND. DTOS(dDataIni) <= DTOS((STOD((cAliasSRF)->RF_DATAINI) + ((cAliasSRF)->RF_DFEPRO1-1))) .OR.;
			DTOS(dDataFim) >= (cAliasSRF)->RF_DATAINI .AND. DTOS(dDataFim) <= DTOS((STOD((cAliasSRF)->RF_DATAINI) + ((cAliasSRF)->RF_DFEPRO1-1))) .OR.;
			DTOS(dDataIni) <= (cAliasSRF)->RF_DATAINI .AND. DTOS(dDataFim) >= DTOS((STOD((cAliasSRF)->RF_DATAINI) + ((cAliasSRF)->RF_DFEPRO1-1)))
				
			aRet[1] := .T.
			aRet[5] := STOD((cAliasSRF)->RF_DATAINI)
			aRet[6] := STOD((cAliasSRF)->RF_DATAINI) + ((cAliasSRF)->RF_DFEPRO1-1)
			Exit
								
		ElseIf  !Empty((cAliasSRF)->RF_DATINI2) .AND.;
			DTOS(dDataIni) >= (cAliasSRF)->RF_DATINI2 .AND. DTOS(dDataIni) <= DTOS((STOD((cAliasSRF)->RF_DATINI2) + ((cAliasSRF)->RF_DFEPRO2-1))) .OR.;
			DTOS(dDataFim) >= (cAliasSRF)->RF_DATINI2 .AND. DTOS(dDataFim) <= DTOS((STOD((cAliasSRF)->RF_DATINI2) + ((cAliasSRF)->RF_DFEPRO2-1))) .OR.;
			DTOS(dDataIni) <= (cAliasSRF)->RF_DATINI2 .AND. DTOS(dDataFim) >= DTOS((STOD((cAliasSRF)->RF_DATINI2) + ((cAliasSRF)->RF_DFEPRO2-1)))
			
			aRet[2] := .T.
			aRet[5] := STOD((cAliasSRF)->RF_DATAINI2)
			aRet[6] := STOD((cAliasSRF)->RF_DATAINI2) + ((cAliasSRF)->RF_DFEPRO2-1)
			Exit
						
		ElseIf  !Empty((cAliasSRF)->RF_DATINI3) .AND.;
			DTOS(dDataIni) >= (cAliasSRF)->RF_DATINI3 .AND. DTOS(dDataIni) <= DTOS((STOD((cAliasSRF)->RF_DATINI3) + ((cAliasSRF)->RF_DFEPRO3-1))) .OR.;
			DTOS(dDataFim) >= (cAliasSRF)->RF_DATINI3 .AND. DTOS(dDataFim) <= DTOS((STOD((cAliasSRF)->RF_DATINI3) + ((cAliasSRF)->RF_DFEPRO3-1))) .OR.;
			DTOS(dDataIni) <= (cAliasSRF)->RF_DATINI3 .AND. DTOS(dDataFim) >= DTOS((STOD((cAliasSRF)->RF_DATINI3) + ((cAliasSRF)->RF_DFEPRO3-1)))
			
			aRet[3] := .T.
			aRet[5] := STOD((cAliasSRF)->RF_DATAINI3)
			aRet[6] := STOD((cAliasSRF)->RF_DATAINI3) + ((cAliasSRF)->RF_DFEPRO3-1)

			Exit
						
		EndIf

		(cAliasSRF)->(DbSkip())
	EndDo

	(cAliasSRF)->(DbCloseArea())
	
	//Verifica se funcionário possui férias processadas, caso não exista férias programadas no período
	BeginSQL alias cAliasSR8		
		SELECT SR8.R8_DATAINI, SR8.R8_DATAFIM, COUNT(*) NUM
 		FROM %table:SR8% SR8
 		INNER JOIN %table:RCM% RCM 
 		ON  RCM.RCM_FILIAL 	= %exp:cFilRCM% 
 		AND RCM.RCM_TIPO	= SR8.R8_TIPOAFA
 		AND RCM.RCM_TIPOAF	= 4
 		WHERE 
			SR8.%notDel%
			AND RCM.%notDel%
 			AND SR8.R8_FILIAL = %exp:cFilFun% 				
 			AND SR8.R8_MAT = %exp:cMat%
 			AND ((NOT (%exp:dDataIni% > SR8.R8_DATAFIM OR %exp:dDataFim% < SR8.R8_DATAINI)) OR
       			 (%exp:dDataFim%>=SR8.R8_DATAINI AND SR8.R8_DATAFIM = '')
	            )
		GROUP BY SR8.R8_DATAINI, SR8.R8_DATAFIM
	EndSQL	

	If (cAliasSR8)->(!Eof()) .And. (cAliasSR8)->NUM > 0
		aRet[4] := .T.
		aRet[5] := STOD((cAliasSR8)->R8_DATAINI)
		aRet[6] := STOD((cAliasSR8)->R8_DATAFIM)
	EndIf
		
	(cAliasSR8)->(DbCloseArea())
			
	RestArea(aArea)		
	
Return aRet

/*
{Protheus.doc} AT570Detal

Apresenta tela com detalhes de conflitos de alocação

@param	cAtend		String	Codigo do atendente
@param	aPeriodos	Array	Informações de periodos a serem considerados
@param	aConfAloc	Array	Configuração de alocação a ser considerada
@param	aPosPeriod	Array	Posição de data inicial e data Final dentro do aConfAloc [1]Data Inicial [2]Data Final
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   04/06/2013 
*/
Function AT570Detal(cAtend, aPeriodos)
Local nI := 1
Local dAlocDe := STOD("")
Local dAlocAte := STOD("") 
Local cAliasBkp := cAliasTmp //realiza backup do alias atual da variavel estatica, para o caso de chamar a rotina dentro da TECA570


Default aPeriodos := {}

If ValType(aPeriodos) == "A" .AND. Len(aPeriodos) > 0
	dAlocDe 	:= aPeriodos[1][1]
	dAlocAte 	:= aPeriodos[1][3]
	
	//Encontra menor e mairo data de alocacao do periodo
	For nI:=1 To Len(aPeriodos)
		If aPeriodos[nI][1] < dAlocDe
			dAlocDe := aPeriodos[nI][1]
		EndIf
		If aPeriodos[nI][3] > dAlocAte
			dAlocAte := aPeriodos[nI][3]
		EndIf
	Next nI 
	
	TECA570({dAlocDe, dAlocAte, cAtend, cAtend}, .T.)
	
	cAliasTmp := cAliasBkp //Volta Alias

EndIf    

	
Return

/*
{Protheus.doc} AT570CkMan

Verifica se agenda possui manutenções do tipo de cancelamento

@param	cFil	String	Filial da agenda
@param	cAgenda	String	Codigo da Agenda

@return lRet	Boolean	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   05/06/2013 
*/
Static Function AT570CkMan(cFil, cAgenda)  
	Local lRet := .F.  
	Local aArea := ABR->(GetArea())
	
	ABR->(DbSelectArea(1))//ABR_FILIAL+ABR_AGENDA+ABR_MOTIVO
	ABR->( MsSeek(cFil+cAgenda ) )
	While ABR->(!EOF()) .AND. ABR->ABR_FILIAL == cFil .AND. ABR->ABR_AGENDA == cAgenda
		If AT570VldMt(ABR->ABR_MOTIVO) 
			lRet := .T.
			Exit
		EndIF
		ABR->(DbSkip())
	End
	
	RestArea(aArea)

Return lRet

/*
{Protheus.doc} AT570Perm

Recupera permissão de contratos e equipes no formato SQL para realização de filtros em query

@param  
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   13/06/2013 
@return cPermissao String Permissoes no formato SQL
 
*/
Static Function AT570Perm()
Local aPermissao	:= at570GetPe()//Recupera array de permissoes
Local aOs := {}
Local aAtend := {}
Local cOs:=""
Local cAtend := ""

Local nI := 1
Local cRet := ""

//Verifica permissoes de equipes
aAtend := at570PerAt()
If Len(aAtend) > 0
	For nI:=1 To Len(aAtend)
		cAtend += "'"+aAtend[nI]+"',"
	Next nI
	
	If !Empty(cAtend)
		cAtend:=SubStr(cAtend, 1, Len(cAtend)-1)
	EndIf
EndIf

If !Empty(cAtend)
 	cRet += " AND ABB.ABB_CODTEC IN ("+cAtend+")"
EndIf
 
Return cRet

/*
{Protheus.doc} at570PerAt

retorna codigo dos atendentes da equipe do usuario logado.

@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   13/06/2013 
@return aRet Array Codigos de atendentes das equipes do usuario
*/
Static Function at570PerAt()
Local aPerEquipe := at570Equip(__cUserId)
Local aRet:={}
Local nI:=1

//Recupera codigo dos atendentes
For nI:=1 To Len(aPerEquipe)
	AAY->(DbSetOrder(1))//AAY_FILIAL+AAY_CODEQU+AAY_CODTEC
	If AAY->(MsSeek(xFilial("AAY")+aPerEquipe[nI]))
		
		While( AAY->(!EOF()) .AND. xFilial("AAY")==AAY->AAY_FILIAL .AND. aPerEquipe[nI]==AAY->AAY_CODEQU)
			If aScan(aRet, {|x| x == AAY->AAY_CODTEC}) == 0
				aAdd(aRet,AAY->AAY_CODTEC)
			EndIf				
			AAY->(DbSkip())			
		End	
		
	EndIf
Next nI


Return aRet

/*
{Protheus.doc} at570Equip

Retorna codigos das equipes do usuario definido pelo parametro cId

@param  cID String Id do usuario
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   13/06/2013 
@return aEquipe Array Codigos da equipe do usuario 
*/
Static Function at570Equip(cId)
Local aEquipe := {} 
Local cAlias := GetNextAlias()
Local cQuery := "" 

AA1->(DbSetorder(4)) //AA1_FILIAL+AA1_CODUSR

If !Empty(cId) .AND. AA1->(DbSeek(xFilial("AA1")+cId))
	cQuery := 	" SELECT AAY.*,R_E_C_N_O_ AAYRECNO FROM " + RetSqlName("AAY") + " AAY "
	cQuery += 	"WHERE"
	cQuery += 	" AAY_FILIAL='" + xFilial( "AAY" ) + "' AND "
	cQuery +=	"AAY_CODTEC = '"+AA1->AA1_CODTEC+"' AND "
	cQuery += 	"D_E_L_E_T_=' '"
	
	cQuery := ChangeQuery( cQuery ) 

	dbUseArea( .T., "TOPCONN", TcGenQry( , , cQuery ), cAlias, .T., .T. ) 

	While (cAlias)->( !Eof() )					
		AAdd(aEquipe, ( cAlias )->AAY_CODEQU)
		( cAlias )->(DbSkip())
	End		
EndIf
	
Return aEquipe


/*
{Protheus.doc} at570CPerm

Verifica se controla permissoes de acordo com parametro MV_TECPCON  e cadastro de permissoes
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   13/06/2013 
@return lCOntrola Boolean - Verdadeiro indica que controla permissoes, Falso indica que não controla permissoes 
*/
Static Function at570CPerm()
Local lPercTec		:= SuperGetMv('MV_TECPCON',,.F.)
Local aPermissao	:= at570GetPe()//Recupera permissoes
Local aAtend 		:= at570PerAt()//Permissoes de equipe
Local lControla := .F.

If lPercTec .OR. !Empty(aPermissao) .OR. !Empty(aAtend) 
	lControla := .T.
Else
	lControla := .F.
EndIf	
Return lControla

/*
{Protheus.doc} at570GetPe

Aplicação de padrão singleton para aPErm
 
Controle da variavel estática aPerm, caso não tenha sido realizada atribuição com seu conteudo, realiza a chamada da função At120Perm 
para carregar variavel aPerm somente uma vez no fonte.
	
@owner  rogerio.souza
@author  rogerio.souza
@version V11
@since   13/06/2013 
@return aPerm Array
*/
Static Function at570GetPe()
If ValType(aPerm) == "U"
	aPerm := At201Perm()
EndIf
Return aPerm

/*/{Protheus.doc} At570IniF
	
@author rogerio.souza
@since 23/12/2013
@version V11.9
@return dData, Data de inicio das férias
@description
Calcula e retorna data de inicio das férias

/*/
Function At570IniF()

Local dData := STOD("")

If !Empty(RF_DATAINI) .AND.;
	ABB_DTINI >= RF_DATAINI .AND. ABB_DTINI <= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) .OR.;
	ABB_DTFIM >= RF_DATAINI .AND. ABB_DTFIM <= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) .OR.;
	ABB_DTINI <= RF_DATAINI .AND. ABB_DTFIM >= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1)))
	
	dData := STOD(RF_DATAINI)
								
ElseIf  !Empty(RF_DATINI2) .AND.;
	ABB_DTINI >= RF_DATINI2 .AND. ABB_DTINI <= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) .OR.;
	ABB_DTFIM >= RF_DATINI2 .AND. ABB_DTFIM <= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) .OR.;
	ABB_DTINI <= RF_DATINI2 .AND. ABB_DTFIM >= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1)))
	
	dData := STOD(RF_DATINI2)
						
ElseIf  !Empty(RF_DATINI3) .AND.;
	ABB_DTINI >= RF_DATINI3 .AND. ABB_DTINI <= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) .OR.;
	ABB_DTFIM >= RF_DATINI3 .AND. ABB_DTFIM <= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) .OR.;
	ABB_DTINI <= RF_DATINI3 .AND. ABB_DTFIM >= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1)))
		
	dData := STOD(RF_DATINI3)	
								
EndIf

Return dData

/*/{Protheus.doc} At570FimF
	
@author rogerio.souza
@since 23/12/2013
@version V11.9	
@return dData, Data final das férias

@description
Calcula e retorna data final das férias do funcionário.

/*/
Function At570FimF()

Local dData := STOD("")

If !Empty(RF_DATAINI) .AND.;
	ABB_DTINI >= RF_DATAINI .AND. ABB_DTINI <= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) .OR.;
	ABB_DTFIM >= RF_DATAINI .AND. ABB_DTFIM <= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) .OR.;
	ABB_DTINI <= RF_DATAINI .AND. ABB_DTFIM >= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1)))
	
	dData := STOD(RF_DATAINI) + (RF_DFEPRO1-1)
								
ElseIf  !Empty(RF_DATINI2) .AND.;
	ABB_DTINI >= RF_DATINI2 .AND. ABB_DTINI <= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) .OR.;
	ABB_DTFIM >= RF_DATINI2 .AND. ABB_DTFIM <= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) .OR.;
	ABB_DTINI <= RF_DATINI2 .AND. ABB_DTFIM >= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1)))
	
	dData := STOD(RF_DATINI2) + (RF_DFEPRO2-1)
						
ElseIf  !Empty(RF_DATINI3) .AND.;
	ABB_DTINI >= RF_DATINI3 .AND. ABB_DTINI <= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) .OR.;
	ABB_DTFIM >= RF_DATINI3 .AND. ABB_DTFIM <= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) .OR.;
	ABB_DTINI <= RF_DATINI3 .AND. ABB_DTFIM >= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1)))
		
	dData := STOD(RF_DATINI3) + (RF_DFEPRO3-1)	
								
EndIf


Return dData

/*/{Protheus.doc} At570Filter
	
@since 08/12/2014
@version V12
@return lREt, avaliação do filtro
@description filtro para avaliação de férias, demissão e afastamento durante período de alocação 
/*/
Function At570Filter()

Local lAfasta 		:= .F.
Local lDemiss 		:= .F.
Local lFerias 		:= .F.
Local lUsaEAIGS 	:= ( !Empty(SuperGetMv( "MV_RHMUBCO",,"")) ) // verifica se está com integração via EAI habilitada

// Conflito de Afastamento
lAfasta := (AllTrim(R8_DATAINI) <> '')

//Conflito de Demissão
lDemiss := !lAfasta .And. ( ;
				( lUsaEAIGS .And. RA_SITFOLH = 'A' ) ;
				.Or. ;
				( !lUsaEAIGS .And. (( AllTrim(RA_DEMISSA) != '' .AND. RA_DEMISSA <= ABB_DTINI ) .OR. ; 				
				 (AllTrim(RA_DEMISSA) != '' .AND. RA_DEMISSA <= ABB_DTFIM ))) ;
			)

//Conflito de Férias
lFerias := !lAfasta .And. !lDemiss .And. ( ;
				AllTrim(RF_DATAINI) != '' .AND. ;
				( ;
					ABB_DTINI >= RF_DATAINI .AND. ABB_DTINI <= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) .OR. ;
					ABB_DTFIM >= RF_DATAINI .AND. ABB_DTFIM <= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) .OR. ;
					ABB_DTINI <= RF_DATAINI .AND. ABB_DTFIM >= DTOS((STOD(RF_DATAINI) + (RF_DFEPRO1-1))) ;
				) ;
			) .OR. ( ;
				AllTrim(RF_DATAINI2) != '' .AND. ;
				( ;
					ABB_DTINI >= RF_DATINI2 .AND. ABB_DTINI <= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) .OR.;
					ABB_DTFIM >= RF_DATINI2 .AND. ABB_DTFIM <= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) .OR.;
					ABB_DTINI <= RF_DATINI2 .AND. ABB_DTFIM >= DTOS((STOD(RF_DATINI2) + (RF_DFEPRO2-1))) ;
				) ;
			) .OR. ( ;
				AllTrim(RF_DATAINI3) != '' .AND. ;
				( ;
					ABB_DTINI >= RF_DATINI3 .AND. ABB_DTINI <= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) .OR.;
					ABB_DTFIM >= RF_DATINI3 .AND. ABB_DTFIM <= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) .OR.;
					ABB_DTINI <= RF_DATINI3 .AND. ABB_DTFIM >= DTOS((STOD(RF_DATINI3) + (RF_DFEPRO3-1))) ;
				) ;
			)

Return ( lAfasta .Or. lDemiss .Or. lFerias )	

/*
{Protheus.doc} At570ChkDm

Encapsula a função CheckDemis 
Retorna Verdadeiro caso exista inconsitencia de alocação na data informada

@param  cFilFun	String	Filial do funcionário
@param  cMat		String	Matricula do Funcionario
@param  dDataIni	Data	Data inicial de alocação
@param  dDataFim	Data	Data Final de alocação

@simple At570ChkDm(cFilFun, cMat, dDataIni, dDataFim)
@since  18/05/2015 
@return lRet Boolean	 
 */
Function At570ChkDm(cFilFun, cMat, dDataIni, dDataFim)
Local lRet := CheckDemis(cFilFun, cMat, dDataIni, dDataFim)
Return lRet

/*
{Protheus.doc} At570ChkAf

Encapsula a função CheckAfast 
Retorna Verdadeiro caso exista inconsitencia de alocação na data informada

@param  cFilFun	String	Filial do funcionário
@param  cMat		String	Matricula do Funcionario
@param  dDataIni	Data	Data inicial de alocação
@param  dDataFim	Data	Data Final de alocação
	
@simple At570ChkAf(cFilFun, cMat, dDataIni, dDataFim)
@since  18/05/2015
@return lRet Boolean	 
 */ 
Function At570ChkAf(cFilFun, cMat, dDataIni, dDataFim)
Local lRet := CheckAfast(cFilFun, cMat, dDataIni, dDataFim)
Return lRet

/*
{Protheus.doc} At570ChkFe

Encapsula a função CheckFeria 
Retorna Verdadeiro caso exista inconsitencia de alocação na data informada

@param  cFilFun	String	Filial do funcionário
@param  cMat		String	Matricula do Funcionario
@param  dDataIni	Data	Data inicial de alocação
@param  dDataFim	Data	Data Final de alocação

@simple At570ChkFe(cFilFun, cMat, dDataIni, dDataFim)
@since  18/05/2015 
@return aRet Array, aRet[1] - Ferias programadas.
					aRet[2]	- Ferias programadas 2.
					aRet[3] - Ferias programadas 3.
					aRet[4] - Ferias processada.
 */ 
Function At570ChkFe(cFilFun, cMat, dDataIni, dDataFim)
Local aRet := CheckFeria(cFilFun, cMat, dDataIni, dDataFim)
Return aRet
