#INCLUDE 'TECA190B.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'FWBROWSE.CH'

#DEFINE FIL_ATENDE 1
#DEFINE FIL_LOCAL  2
#DEFINE FIL_REGIAO 3
#DEFINE FIL_EQUIPE 4
#DEFINE FIL_HABILI 5
#DEFINE FIL_SUPERV 6 

Static dDtAgIni := dDatabase-15
Static dDtAgFim := dDatabase+15

Static MsgRun1 := Capital(STR0001)  // 'Filtrando dados...'
Static MsgRun2 := STR0002  // 'Aguarde'

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA190B
	Rotina para mesa operacional - chama a rotina que constrói com mensagem para o usuário
aguardar 

@sample 	TECA190B

@since		29/04/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function TECA190B()

MsgRun(MsgRun1,MsgRun2, {|| TECA190BT()})

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA190BT
	Constrói a interface da mesa operacional para a visão de atendentes 

@sample 	TECA190BT

@since		29/04/2014
@version	P12

/*/
//------------------------------------------------------------------------------
Function TECA190BT()

Local aCoors     := FwGetDialogSize(oMainWnd)

Local oDlgMesAtd := Nil
Local oDlgEsq    := Nil
Local oDlgDir    := Nil
Local oFWLayer   := Nil
Local oFWLayEsq  := Nil
Local oFWLayDir  := Nil
Local oPanButts  := Nil
Local oPanNames  := Nil
Local oPanDates  := Nil
Local oPanBrowse := Nil
Local oFolder    := Nil
Local oDlgAgend  := Nil
Local oDlgManut  := Nil

Local xAux       := {}

Local oBrwAtd    := Nil
Local oBrwAge    := Nil
Local oBrwMnt    := Nil

Local oDlgFil    := Nil
Local oGroup     := Nil

Local oSayAgIni  := Nil
Local oDtAgIni   := Nil
Local oSayAgFim  := Nil
Local oDtAgFim   := Nil

Local bRefBrw    := Nil 

DEFINE MSDIALOG oDlgMesAtd TITLE STR0003 FROM aCoors[1],aCoors[2] TO aCoors[3]-10,aCoors[4]-10 PIXEL  // "Mesa Operacional - Atendentes"

//------------------------------------------
// Divide a tela e organiza os layers a serem apresentados
oFWLayer := FWLayer():New()
oFWLayer:Init(oDlgMesAtd,.F.,.T.)

oFWLayer:AddLine("TUDO",100,.F.)

oFWLayer:AddCollumn("ESQ",30,.T.,"TUDO")
oFWLayer:AddCollumn("DIR",70,.T.,"TUDO")

oFWLayer:AddWindow("ESQ","oDlgEsq","",100,.F.,.T.,,"TUDO",{|| })
oDlgEsq := oFWLayer:GetWinPanel("ESQ","oDlgEsq","TUDO")

oFWLayer:AddWindow("DIR","oDlgDir","",100,.F.,.T.,,"TUDO",{|| })
oDlgDir := oFWLayer:GetWinPanel("DIR","oDlgDir","TUDO")

oFWLayEsq := FWLayer():New()
oFWLayEsq:Init(oDlgEsq,.F.,.T.)

oFWLayEsq:AddLine("CIM_ESQ",30,.T.,"ESQ")
oFWLayEsq:AddColumn("FILTROS",100,.T.,"CIM_ESQ")

oFWLayEsq:AddLine("BAI_ESQ",70,.T.,"ESQ")
oFWLayEsq:AddColumn("ATENDEN",100,.T.,"BAI_ESQ")

oFWLayDir := FWLayer():New()
oFWLayDir:Init(oDlgDir,.F.,.T.)

oFWLayDir:AddLine("BAI_DIR",100,.T.,"DIR")
oFWLayDir:AddColumn("BROWSE",100,.T.,"BAI_DIR")

//-----------------------------------------------
//  Adiciona os painéis que conterão os objetos

oFWLayEsq:AddWindow("FILTROS","oPanButts","",100,.F.,.T.,,"CIM_ESQ",{|| })
oPanButts := oFWLayEsq:GetWinPanel("FILTROS","oPanButts","CIM_ESQ")

oFWLayEsq:AddWindow("ATENDEN","oPanNames","",100,.F.,.T.,,"BAI_ESQ",{|| })
oPanNames := oFWLayEsq:GetWinPanel("ATENDEN","oPanNames","BAI_ESQ")

oFWLayDir:AddWindow("BROWSE","oPanBrowse","",100,.F.,.T.,,"BAI_DIR",{|| })
oPanBrowse := oFWLayDir:GetWinPanel("BROWSE","oPanBrowse","BAI_DIR")

//-----------------------------------
// Cria folder para conter as informações de agenda e manutenções separadas
oFolder := TFolder():New(001,001,{STR0004,STR0005},{"HEADER1","HEADER2"},oPanBrowse,,,, .T., .F.,;  // "Agenda" ### "Manutenções" 
	(oPanBrowse:nClientWidth*0.5),(oPanBrowse:nClientHeight*0.5))

oDlgAgend := oFolder:aDialogs[1]
oDlgManut := oFolder:aDialogs[2]

oFWLayer:Show()

//_______ Panel dos filtro __________

oDlgFil := TScrollBox():New(oPanButts,00,00,(oPanButts:nClientHeight*0.52),(oPanButts:nClientWidth*0.5),.T.,.F.,.F.)

@ 005,005 BUTTON STR0006 SIZE 35,10 OF oDlgFil PIXEL Action( At190BCrgDt(oBrwAtd) )  // "Filtrar"

@ 020,005 BUTTON STR0007 SIZE 35,10 OF oDlgFil PIXEL Action(At190BFil( FIL_REGIAO ))  // "Região"
@ 020,045 BUTTON STR0008 SIZE 35,10 OF oDlgFil PIXEL Action(At190BFil( FIL_EQUIPE ))  // "Equipe"

@ 035,005 BUTTON STR0009 SIZE 35,10 OF oDlgFil PIXEL Action(At190BFil( FIL_LOCAL ))  // "Local"
@ 035,045 BUTTON STR0010 SIZE 35,10 OF oDlgFil PIXEL Action(At190BFil( FIL_ATENDE ))  // "Atendente"

@ 050,005 BUTTON STR0011 SIZE 35,10 OF oDlgFil PIXEL Action(At190BFil( FIL_HABILI ))  // "Habilidades"
@ 050,045 BUTTON STR0039 SIZE 35,10 OF oDlgFil PIXEL Action(At190BFil( FIL_SUPERV ))  // "Área de Supervisor"

oGroup := TGroup():New( 015,085,060,160,STR0012,oDlgFil,,,.T.)  // 'Período das Agendas'

oSayAgIni := TSay():New( 027, 090, { || STR0013 }, oGroup,,,,,,.T.,,, 050, 10 )  // 'De:'
oDtAgIni  := TGet():New( 025, 101,{|u| If( PCount() > 0, dDtAgIni := u, dDtAgIni )},oGroup,050,010,"",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'dDtAgIni',,,, )
oSayAgFim := TSay():New( 047, 090, { || STR0014 }, oGroup,,,,,,.T.,,, 050, 10 )  // 'Até:'
oDtAgFim  := TGet():New( 045, 101,{|u| If( PCount() > 0, dDtAgFim := u, dDtAgFim )},oGroup,050,010,"",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'dDtAgFim',,,, )

//___________________________________

//----------Cria os browses---------
oBrwAtd := At190BBrwNew( "190BAA1", At190BSqlBrw('AA1'), '', oPanNames, At190BGFields('AA1'), .F., xAux)

xAux := {}
aAdd( xAux, { {|| At190BSAg1( oBrwAge:cAlias ) }, {|| AT190BLegen('AGENDA1') }, STR0004 } )  // 'Agenda'
aAdd( xAux, { {|| At190BSAg2( oBrwAge:cAlias ) }, {|| AT190BLegen('AGENDA2') }, STR0015 } )  // 'Alocação'
oBrwAge := At190BBrwNew( "190BABB", At190BSqlBrw('ABB',(oBrwAtd:cAlias)->AA1_CODTEC) , '', oDlgAgend, At190BGFields('ABB'), .F., xAux)

xAux := {}
aAdd( xAux, { {|| At190BSMn1( oBrwMnt:cAlias ) }, {|| AT190BLegen('MANUT1') }, STR0016 } )  // 'Tipo'
aAdd( xAux, { {|| At190BSMn2( oBrwMnt:cAlias ) }, {|| AT190BLegen('MANUT2') }, STR0017 } )  // 'Substituição'
oBrwMnt := At190BBrwNew( "190BABR", At190BSqlBrw('ABR',(oBrwAtd:cAlias)->AA1_CODTEC) , '', oDlgManut, At190BGFields('ABR'), .F., xAux)

aSize( xAux, 0 )

bRefBrw := {||MsgRun( MsgRun1 + " " +(oBrwAtd:cAlias)->AA1_CODTEC+"/"+RTrim((oBrwAtd:cAlias)->AA1_NOMTEC),MsgRun2,{||At190BRefBrw((oBrwAtd:cAlias)->AA1_CODTEC,{{oBrwAge,'ABB'},{oBrwMnt,'ABR'}})})}
oBrwAtd:bChange := bRefBrw


//----------Adiciona as opções aos browses---------
oBrwAtd:AddButton( STR0018, {|| At190BAtend( (oBrwAtd:cAlias)->AA1_CODTEC ) } )  // 'Visualizar Atendente'
oBrwAtd:AddButton( STR0019, {|| TECA750("Posicione('TE5',1,xFilial('TE5')+TE4->TE4_COD+'"+(oBrwAtd:cAlias)->AA1_CODTEC+"','TE5_ITEM')<>'  '") } )  // 'Ocorrência'
oBrwAtd:AddButton( STR0020, {|| At190BDisVi((oBrwAtd:cAlias)->AA1_CODTEC) } )  // 'Disciplina'

oBrwAge:AddButton( STR0021, {|| At190BMnExec( (oBrwAge:cAlias)->ABB_CODIGO ), Eval(bRefBrw) } )  // 'Manutenção da Agenda'
oBrwAge:AddButton( STR0022, {|| TECA550( (oBrwAge:cAlias)->ABB_CODIGO, oBrwAge:cAlias ), Eval(bRefBrw) } )  // 'Manutenções Relacionadas'

oBrwMnt:AddButton( STR0023, {|| At190BMnVi( (oBrwMnt:cAlias)->ABR_AGENDA, (oBrwMnt:cAlias)->ABR_MOTIVO ) } )  // 'Visualizar Manutenção'

oBrwMnt:Activate()
oBrwAge:Activate()
oBrwAtd:Activate()

//----------------------------------

ACTIVATE MSDIALOG oDlgMesAtd

//--------------------------------------
//  Desativa os browses e elimina o conteúdo das variáveis de interface
// Isso é feito para que a função DelClassIntF consiga eliminar
// a reserva das variáveis de memória
oBrwMnt:DeActivate()
oBrwAge:DeActivate()
oBrwAtd:DeActivate()

oDlgMesAtd := Nil
oDlgEsq    := Nil
oDlgDir    := Nil
oFWLayer   := Nil
oFWLayEsq  := Nil
oFWLayDir  := Nil
oPanButts  := Nil
oPanNames  := Nil
oPanDates  := Nil
oPanBrowse := Nil
oFolder    := Nil
oDlgAgend  := Nil
oDlgManut  := Nil
xAux       := Nil
oBrwAtd    := Nil
oBrwAge    := Nil
oBrwMnt    := Nil
oDlgFil    := Nil
oGroup     := Nil
oSayAgIni  := Nil
oDtAgIni   := Nil
oSayAgFim  := Nil
oDtAgFim   := Nil
bRefBrw    := Nil

// chama a rotina que faz a limpeza dos componentes como Nil
DelClassIntf() 

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190BFil
	Cria o array no formato correto para execução do filtro da mesa

@sample		At190BFil( 1 )

@since		24/04/2014 
@version 	P12
     
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BFil( nParam )

Local aParam := { { 'AA1'   , '001', STR0010 , 1,'AA1_FILIAL+AA1_CODTEC', 'AA1', { {'AA1', 1, 'AA1_NOMTEC'} }, {}, {||.F.}, '', /*VldExtra*/ },; // 'Atendente'
				  { 'ABS'   , '001', STR0024, 1,'ABS_FILIAL+ABS_LOCAL', 'ABS', { {'ABS', 1, 'ABS_DESCRI+ABS_REGIAO'} }, {}, {||.F.}, '', /*VldExtra*/ }, ;  // 'Local de Atendimento'
				  { 'SX5'   , 'A2_', STR0007, 1,'X5_FILIAL+X5_TABELA+X5_CHAVE', 'A2', { {'SX5', 1, 'X5_DESCRI'} }, {}, {||.F.}, 'A2', /*VldExtra*/ }, ;  // 'Região'
				  { 'AAX'   , '001', STR0008, 1,'AAX_FILIAL+AAX_CODEQU', 'AAX', { {'AAX', 1, 'AAX_NOME+AAX_TPGRUP'} }, {}, {||.F.}, '', /*VldExtra*/ }, ;  // 'Equipe'
				  { 'SX5'   , 'A4_', STR0011, 1,'X5_FILIAL+X5_TABELA+X5_CHAVE', 'A4', { {'SX5', 1, 'X5_DESCRI'} }, {}, {||.F.}, 'A4', /*VldExtra*/ }, ;  // 'Habilidades'
				  { 'TGS' 	, '001', STR0039, 2,'TGS_FILIAL+TGS_SUPERV', 'TGSSUP', { {'TGS', 2, 'TGS_SUPERV+TGS_REGIAO'} }, {}, {||.F.}, '', /*VldExtra*/ } ;  // 'Área de Supervisor'
				}

// Adiciona a validação extra para os valores digitados/selecionados pelo usuário
aParam[FIL_EQUIPE,11] := "At201BHas(Posicione('AAX',1,xValueNew,'AAX_CODEQU'),,'"+__cUserId+"')"

TECA670( aParam[nParam], .F. /*lUsaCombobox*/ )

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190BGFields
	Cria a estrutura dos campos a serem adicionados ao browse 

@sample		At190BGFields( cTabela )
	
@since		24/04/2014 
@version 	P12

@param		cTabela, Caracter, tabela que definirá quais campos serão carregados

@return		aEstrut, Array, lista com as informações a serem utilizadas para cada campo
     
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At190BGFields( cTabela )

Local aEstrut    := {}
Local aCampos    := {}
Local nX         := 1

Local aSave      := GetArea()
Local aSaveSX3   := SX3->( GetArea() )

Local cbCharge   := Nil

Default cTabela  := ''

If !Empty(cTabela)
	
	If cTabela == 'AA1'
		aCampos := {'AA1_FILIAL','AA1_CODTEC','AA1_NOMTEC'}
	ElseIf cTabela == 'ABB'
		aCampos := {'ABB_FILIAL','ABB_CODIGO','ABB_LOCAL','ABB_DTINI','ABB_HRINI','ABB_DTFIM','ABB_HRFIM','ABB_HRTOT','ABB_ATIVO','ABB_MANUT','ABB_CODTEC','ABB_NOMTEC'}
	ElseIf cTabela == 'ABR'
		aCampos := {'ABR_FILIAL','ABR_AGENDA','ABR_DTMAN','ABR_MOTIVO','ABR_DMOT','ABR_DTINI','ABR_HRINI','ABR_DTFIM','ABR_HRFIM','ABR_TEMPO','ABR_CODSUB','ABR_USASER'}
	EndIf
	
	DbSelectArea('SX3')
	
	For nX := 1 To Len(aCampos)
		
		DbSetOrder(2) // X3_CAMPO
		
		If SX3->( DbSeek( PadR(aCampos[nX],10) ) )
			cbCharge := If( SX3->X3_TIPO=='D','{||STOD('+aCampos[nX]+')}','{||'+aCampos[nX]+'}')
			aAdd( aEstrut, { X3Titulo(), ;
							 &(cbCharge),;
							 SX3->X3_TIPO,;
							 X3Picture(aCampos[nX]),;
							 1 ,;
							 TamSX3(aCampos[nX])[1],;
							 TamSX3(aCampos[nX])[2],;
							 .F. ,;
							 {|| .F.},;
							 .F. } )
		EndIf
	Next nX

EndIf

RestArea( aSaveSX3 )
RestArea( aSave )


Return aEstrut

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190BBrwNew
	Cria os browses baseado na FwFormBrowse e query

@sample		At190BBrwNew( "190ATFH", At190ASqlBrw('TFH',(oBrwLocais:cAlias)->TFL_CODIGO), '',     oPanMc, At190AGFields('TFH'), .F., xAux)
	
@since		24/04/2014 
@version 	P12

@param		cNameTab, Caracter, nome da tabela a ser utilizada para o retorno dos dados da query e como referência ao browse
@param		cQry, Caracter, instrução sql para consulta dos registro que irão preencher o browse
@param		cDescrição, Caracter, título a ser exibido no browse
@param		oPanel, Objeto, objeto que irá conter o browse
@param		lActivate, Logico, define se o objeto deverá ser criado e já ativado
@param		aAddStCols, Array, lista com as colunas de status/legenda que deverão ser adicionadas, sendo no formato:
			{ {	posicao 1 - bloco de código de captura do status
				posicao 2 - bloco de código para exibição da legenda ao realizar duplo clique no campo
				posicao 3 - título a ser atribuído a coluna de status
			  }, ....}    

@return		oBrwTmp, Objeto, instância da classe FwFormBrowse

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At190BBrwNew( cNameTab, cQry, cDescricao, oPanel, aFields, lActivate, aAddStCols)

Local oBrwTmp    := Nil 
Local nX         := 1
Local nCpo       := 1

Default cNameTab   := ''
Default cQry       := ''
Default cDescricao := ''
Default lActivate  := .T.

If !Empty(cNameTab) .And. !Empty(cQry)

	oBrwTmp := FWFormBrowse():New()
	oBrwTmp:SetDataQuery(.T.)
	oBrwTmp:SetAlias( cNameTab )
	oBrwTmp:SetQuery( cQry )
	oBrwTmp:SetDescription( cDescricao )
	oBrwTmp:SetOwner(oPanel)
	oBrwTmp:SetUseFilter( .T. )	
	
	If ValType(aAddStCols)=='A'
		For nX := 1 To Len(aAddStCols)
			oBrwTmp:AddStatusColumn( aAddStCols[nX,1], aAddStCols[nX,2] )
			nCpo := Len(oBrwTmp:aColumns)
			oBrwTmp:aColumns[nCpo]:SetTitle(aAddStCols[nX,3])
		Next nX
	EndIf
	
	For nX := 1 To Len(aFields)
		oBrwTmp:AddColumn( aFields[nX] )
	Next nX

	oBrwTmp:DisableDetails()

	If lActivate
		oBrwTmp:Activate()
	EndIf

EndIf

Return oBrwTmp

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190BSqlBrw
	Constrói a query para a consulta dos locais associados ao filtro fornecido pelo usuário

@sample		At190BSqlBrw('TFT',(oBrwMc:cAlias)->TFH_COD)
	
@since		24/04/2014 
@version 	P12

@param		cTabela, Caracter, tabela que definirá como a query será construída
@param		cparam, Caracter, informação adicional para filtro dos dados conforme a tabela

@return		cStrSql, Caracter, query para adição ao browse e filtro das informações

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At190BSqlBrw(cTabela, cParam)

Local cCondAtd := ''
Local cCondReg := ''
Local cCondEqp := ''
Local cCondLoc := ''
Local cCondHab := ''
Local cCondSit := ''
Local cSuperv  := ''

Local cStrSql  := ''

Default cTabela := ''
Default cParam  := ' '

If cTabela=='AA1'
	
	cCondAtd := At670FilSql( __cUserId, .F.,    'AA1', '001' )  // Atendente
	cCondReg := At670FilSql( __cUserId, .F.,    'SX5', 'A2_', , 'SXA2')  // Região
	cCondEqp := At670FilSql( __cUserId, .F.,    'AAX', '001' )  // Equipe
	cCondLoc := At670FilSql( __cUserId, .F.,    'ABS', '001' )  // Local
	cCondHab := At670FilSql( __cUserId, .F.,    'SX5', 'A4_', , 'SXA4')  // Habilidade
	cSuperv  := At670FilSql( __cUserId, .F.,    'TGS', '001' )  // Supervisor
	
	cStrSql += "SELECT "
	cStrSql += 		"DISTINCT "
	cStrSql += 		"AA1_FILIAL,AA1_CODTEC,AA1_NOMTEC "
	cStrSql += 		"FROM "+RetSqlName('AA1')+" AA1 "
	cStrSql += 		"LEFT JOIN "+RetSqlName('AAY')+" AAY ON AAY.AAY_FILIAL='"+xFilial('AAY')+"' AND AAY.AAY_CODTEC=AA1.AA1_CODTEC AND AAY.D_E_L_E_T_=' ' "
	cStrSql += 		"LEFT JOIN "+RetSqlName('AAX')+" AAX ON AAX.AAX_FILIAL='"+xFilial('AAX')+"' AND AAX.AAX_CODEQU=AAY.AAY_CODEQU AND AAX.D_E_L_E_T_=' ' "
	cStrSql += 		"LEFT JOIN "+RetSqlName('AA2')+" AA2 ON AA2.AA2_FILIAL='"+xFilial('AA2')+"' AND AA2.AA2_CODTEC=AA1.AA1_CODTEC AND AA2.D_E_L_E_T_=' ' "
	cStrSql += 		"LEFT JOIN "+RetSqlName('SX5')+" SXA4 ON SXA4.X5_FILIAL='"+xFilial('SX5')+"' AND SXA4.X5_TABELA='A4' AND SXA4.X5_CHAVE=AA2.AA2_HABIL " 
	cStrSql += 			"AND SXA4.D_E_L_E_T_=' ' " // --HABILIDADES
	cStrSql += 		"LEFT JOIN "+RetSqlName('SX5')+" SXA2 ON SXA2.X5_FILIAL='"+xFilial('SX5')+"' AND SXA2.X5_TABELA='A2' "
	cStrSql += 			"AND (SXA2.X5_CHAVE=AAX.AAX_REGIAO OR SXA2.X5_CHAVE=AA1.AA1_REGIAO )" // -- REGIÃO "
	cStrSql += 		"LEFT JOIN "+RetSqlName('ABB')+" ABB ON ABB.ABB_FILIAL='"+xFilial('ABB')+"' AND ABB.ABB_CODTEC=AA1.AA1_CODTEC " 
	cStrSql += 			"AND ABB.ABB_DTINI BETWEEN '"+DTOS(dDtAgIni)+"' AND '"+DTOS(dDtAgFim)+"' AND ABB.D_E_L_E_T_=' ' "
	cStrSql += 		"LEFT JOIN "+RetSqlName('ABS')+" ABS ON ABS.ABS_FILIAL='"+xFilial('ABS')+"' AND ABS.ABS_LOCAL=ABB.ABB_LOCAL AND ABS.D_E_L_E_T_=' ' "
	cStrSql += 		"LEFT JOIN "+RetSqlName('TGS')+" TGS ON TGS.TGS_FILIAL='"+xFilial('TGS')+"' AND TGS.TGS_REGIAO=ABS.ABS_REGIAO AND TGS.D_E_L_E_T_=' ' "
	cStrSql += 	"WHERE " 
	cStrSql += 		"AA1.AA1_FILIAL='"+xFilial('AA1')+"' AND AA1.D_E_L_E_T_=' ' "
	
	If Empty(cCondAtd) .And. Empty(cCondReg) .And. Empty(cCondEqp) .And. Empty(cCondLoc) ;
		.And. Empty(cCondHab) .And. Empty(cCondSit) .And. Empty(cSuperv)
		
		cStrSql += " AND AA1.AA1_CODTEC=' '"
	Else
		If !Empty(cCondAtd)
			cStrSql += cCondAtd
		EndIf
		
		If !Empty(cCondReg)
			cStrSql += cCondReg
		EndIf
		
		If !Empty(cCondEqp)
			cStrSql += cCondEqp
		EndIf
		
		If !Empty(cCondLoc)
			cStrSql += cCondLoc
		EndIf
		
		If !Empty(cCondHab)
			cStrSql += cCondHab
		EndIf
		
		If !Empty(cCondSit)
			cStrSql += cCondSit
		EndIf

		If !Empty(cSuperv)
			cStrSql += "AND (ABS.ABS_REGIAO = ' ' OR (" + Substring(cSuperv,At("(",cSuperv)-1,Len(cSuperv)) + " ))"
		EndIf
	EndIf
	
ElseIf cTabela=='ABB'
	cStrSql += "SELECT "
	cStrSql += "ABB_FILIAL,ABB_CODIGO,ABB_CODTEC,ABB_DTINI,ABB_HRINI,ABB_DTFIM,ABB_HRFIM,ABB_HRTOT,ABB_ATIVO,ABB_MANUT,ABB_LOCAL,ABB_ATENDE,ABB_CHEGOU,ABB_TIPOMV, 0 ABB_OK "
	cStrSql += ", AA1.AA1_NOMTEC ABB_NOMTEC "
	cStrSql += "FROM "+RetSqlName('ABB')+" ABB "
	cStrSql +=		"INNER JOIN "+RetSqlName('AA1')+" AA1 ON AA1.AA1_FILIAL='"+xFilial('AA1')+"' AND AA1.AA1_CODTEC=ABB.ABB_CODTEC AND AA1.D_E_L_E_T_=' ' "
	cStrSql +=	"WHERE ABB.ABB_FILIAL='"+xFilial('ABB')+"' AND ABB.ABB_CODTEC='"+cParam+"'"
	cStrSql +=		"AND ABB.ABB_DTINI BETWEEN '"+DTOS(dDtAgIni)+"' AND '"+DTOS(dDtAgFim)+"' AND ABB.D_E_L_E_T_=' '"

ElseIf cTabela=='ABR'
	cStrSql += "SELECT ABR_FILIAL,ABR_AGENDA,ABR_DTMAN,ABR_MOTIVO,ABR_DTINI,ABR_HRINI,ABR_DTFIM,ABR_HRFIM,ABR_TEMPO,ABR_CODSUB,ABR_USASER"
	cStrSql += ",ABN.ABN_DESC ABR_DMOT "
	cStrSql += "FROM "+RetSqlName('ABR')+" ABR "
	cStrSql += 		"INNER JOIN "+RetSqlName('ABN')+" ABN ON ABN.ABN_FILIAL='"+xFilial('ABN')+"' AND ABN.ABN_CODIGO=ABR.ABR_MOTIVO AND ABN.D_E_L_E_T_=' ' "
	cStrSql +=		"INNER JOIN "+RetSqlName('ABB')+" ABB ON ABB.ABB_FILIAL='"+xFilial('ABB')+"' AND ABB.ABB_CODIGO=ABR.ABR_AGENDA AND ABR.D_E_L_E_T_=' ' "
	cStrSql +=			"AND ABB.ABB_CODTEC='"+cParam+"' AND ABB.ABB_DTINI BETWEEN '"+DTOS(dDtAgIni)+"' AND '"+DTOS(dDtAgFim)+"'"
	cStrSql += "WHERE ABR.ABR_FILIAL='"+xFilial('ABR')+"' AND ABR.D_E_L_E_T_=' '"
	
EndIf

Return ChangeQuery(cStrSql)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BCRGDT
	Realiza o carregamento dos dados após pressionar o botão filtrar
para ação dos filtros no browse com os atendentes

@sample		At190BCrgDt(oBrwAtd)
	
@since		24/04/2014 
@version 	P12

@param		oBrwAtuacao, Objeto, Objeto FwFormBrowse construído a partir de query para sofrer a atualização

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BCrgDt( oBrwAtuacao )

oBrwAtuacao:SetQuery(At190BSqlBrw('AA1'))

//-------------------------------------------------
// Refresh do Browse para reexecução do filtro
oBrwAtuacao:GoTo( 1, .T.)
Eval( oBrwAtuacao:bChange, oBrwAtuacao )
oBrwAtuacao:Refresh()

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BREFBRW
	Atualiza as informações dos browses relacionados

@sample		At190BRefBrw((oBrwAtd:cAlias)->AA1_CODTEC,{{oBrwAge,'ABB'},{oBrwMnt,'ABR'}})
	
@since		24/04/2014 
@version 	P12

@param		cParam, Caracter, informação a ser utilizada para geração da query de atualização do browse
@param		aBrws, Array, lista com os browses a serem atualizados

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BRefBrw( cParam, aBrws )

Local nBrw := 1

For nBrw := 1 To Len(aBrws)
	
	aBrws[nBrw,1]:SetQuery(At190BSqlBrw(aBrws[nBrw,2],cParam))
	
	//-------------------------------------------------
	// Refresh do Browse para reexecução do filtro
	aBrws[nBrw,1]:GoTo( 1, .T.)
	
	If ValType(aBrws[nBrw,1]:bChange)=='B'
		Eval( aBrws[nBrw,1]:bChange, aBrws[nBrw,1] )
	EndIf
	
	aBrws[nBrw,1]:Refresh(.T.)
	
Next nBrw

Return Nil

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BLegen
	Monta janela de exibição das legendas conforme a referência informada

@sample		AT190BLegen(cConsulta)
	
@since		24/04/2014 
@version 	P12

@param		cConsulta, Caracter, identificação da legenda a ser apresentada
     
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AT190BLegen(cConsulta)

Local oLegenda  :=  FWLegend():New()

If cConsulta=='AGENDA1'
	oLegenda:Add( '', 'BR_VERDE'	, STR0025 )  // 'Agenda Ativa'
	oLegenda:Add( '', 'BR_AMARELO'	, STR0026 )  // 'Agenda com Manutenção'
	oLegenda:Add( '', 'BR_VERMELHO'	, STR0027 )  // 'Agenda Cancelada'
	oLegenda:Add( '', 'BR_PRETO'	, STR0028 )  // 'Agenda Atendida'

ElseIf cConsulta=='AGENDA2'
	AT190ALegen('AGENDA2')

ElseIf cConsulta=='MANUT1'
	oLegenda:Add( '', 'BR_VERMELHO'	, STR0029 )  // 'Falta'
	oLegenda:Add( '', 'BR_CINZA'	, STR0030 )  // 'Cancelamento'
	oLegenda:Add( '', 'BR_LARANJA'	, STR0031 )  // 'Saída Antecipada'
	oLegenda:Add( '', 'BR_AMARELO'	, STR0032 )  // 'Atraso'
	oLegenda:Add( '', 'BR_VERDE'	, STR0033 )  // 'Transferência'
	oLegenda:Add( '', 'BR_AZUL'		, STR0034 )  // 'Hora Extra'
	oLegenda:Add( '', 'BR_PINK'		, STR0035 )  // 'Outros Tipos'

ElseIf cConsulta=='MANUT2'
	oLegenda:Add( '', 'BR_BRANCO' 	, STR0036 )  // 'Com Substituição'
	oLegenda:Add( '', 'BR_PRETO'	, STR0037 )  // 'Sem Substituição'
	
EndIf

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190ASAg1
	Identifica os status para a ABB, considerando a situação da agenda

@sample		At190ASAg1( cTab )
	
@since		24/04/2014 
@version 	P12

@param		cTab, Caracter, tabela de dados a ter o conteúdo dos campos avaliados
@return		cStatus, Caracter, código da cor a ser atribuído no campo de status

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BSAg1( cTab )

Local cStatus := 'BR_VERDE'	//Agendamento não sofreu manutenção, está ativo e não foi atendido

If ( (cTab)->ABB_ATIVO == '1' )
	
	If ( (cTab)->ABB_MANUT == '1' )
		cStatus := 'BR_AMARELO'	//Agendamento alterado e ativo
	EndIf
	If ( (cTab)->ABB_ATENDE == '1' .And. (cTab)->ABB_CHEGOU = 'S' )
		cStatus := 'BR_PRETO'		//Atendimento encerrado
	EndIf
	
Else
	cStatus := 'BR_VERMELHO'	//Agendamento inativo
EndIf

Return cStatus

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190ASAg2
	Identifica os status para a ABB, considerando os tipos de alocação

@sample		At190ASAg2( cTab )
	
@since		24/04/2014 
@version 	P12

@param		cTab, Caracter, tabela de dados a ter o conteúdo dos campos avaliados
@return		cStatus, Caracter, código da cor a ser atribuído no campo de status

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BSAg2( cTab )

Local cStatus := At190ASAg2( cTab ) 

Return cStatus

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190BSMn1
	Identifica os status para a ABR, considera o tipo da manutenção

@sample		At190BSMn1( cTab )
	
@since		24/04/2014 
@version 	P12

@param		cTab, Caracter, tabela de dados a ter o conteúdo dos campos avaliados
@return		cStatus, Caracter, código da cor a ser atribuído no campo de status

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BSMn1( cTab )

Local cStatus := 'BR_PINK'	// Outro tipo de manutenção
Local cTipo   := At190BTpMnt( (cTab)->ABR_MOTIVO )

If cTipo == '01'
	cStatus := 'BR_VERMELHO' // - falta

ElseIf cTipo == '02'
	cStatus := 'BR_AMARELO'  // - atraso

ElseIf cTipo == '03'
	cStatus := 'BR_LARANJA'  // - saída antecipada

ElseIf cTipo == '04'
	cStatus := 'BR_AZUL'     // - Hora Extra

ElseIf cTipo == '05'
	cStatus := 'BR_CINZA'    // - cancelamento

ElseIf cTipo == '06'
	cStatus := 'BR_VERDE'    // - transferência
EndIf

Return cStatus

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At190BSMn2
	Identifica os status para a ABR, considera a substituição

@sample		At190BSMn2( cTab )
	
@since		24/04/2014 
@version 	P12

@param		cTab, Caracter, tabela de dados a ter o conteúdo dos campos avaliados
@return		cStatus, Caracter, código da cor a ser atribuído no campo de status

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BSMn2( cTab )

Local cStatus := 'BR_PRETO'	// com substituição

If !Empty( (cTab)->ABR_CODSUB )
	cStatus := 'BR_BRANCO' // sem substituição
EndIf

Return cStatus

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BTPMNT
	Captura qual o tipo da manutenção

@sample		At190BTpMnt( cCodMnt )
	
@since		24/04/2014 
@version 	P12

@param		cCodMnt, Caracter, Código da manutenção
@return		cRet, Caracter, Tipo identificado da manutenção

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At190BTpMnt( cCodMnt )

Local cRet := ''

DbSelectArea('ABN')
ABN->( DbSetOrder(1))

If ABN->(DbSeek( xFilial('ABN')+cCodMnt ) )
	cRet := ABN->ABN_TIPO
EndIf

Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BATEND
	Exibe o cadastro do atendente para visualização

@sample		At190BAtend( (oBrwAtd:cAlias)->AA1_CODTEC )
	
@since		24/04/2014 
@version 	P12

@param		cTecnico, Caracter, código do atendente a ter o cadastro visualizado
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BAtend( cTecnico )

DbSelectArea('AA1')
AA1->(DbSetOrder(1)) //AA1_FILIAL+AA1_CODTEC

If AA1->( DbSeek( xFilial('AA1')+cTecnico) )
	FWExecView(STR0010,"VIEWDEF.TECA020",MODEL_OPERATION_VIEW)  // 'Atendente'
EndIf

Return
 
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BMNVI
	Exibe a manutenção para visualização, permitindo visualizar detalhes adicionais

@sample		At190BMnVi( (oBrwMnt:cAlias)->ABR_AGENDA, (oBrwMnt:cAlias)->ABR_MOTIVO )
	
@since		24/04/2014 
@version 	P12

@param		cAgen, Caracter, código da agenda que recebeu a manutenção
@param		cMot, Caracter, motivo da manutenção na agenda
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BMnVi( cAgen, cMot )

DbSelectArea('ABR')
ABR->(DbSetOrder(1)) //ABR_FILIAL+ABR_AGENDA+ABR_MOTIVO

If ABR->(DbSeek(xFilial('ABR')+cAgen+cMot))
	FWExecView(STR0021,"VIEWDEF.TECA550",MODEL_OPERATION_VIEW,,,,30)  // 'Manutenção da Agenda'
EndIf

Return 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BMNEXEC
	Chama a execução da manutenção da agenda para a agenda informada

@sample		At190BMnExec( (oBrwAge:cAlias)->ABB_CODIGO )

@since		24/04/2014 
@version 	P12

@param		cABBCodigo, Caracter, código da agenda para realizar a manutenção

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BMnExec( cABBCodigo )

DbSelectArea('ABB')
ABB->( DbSetOrder(8))  //ABB_FILIAL+ABB_CODIGO

If ABB->( DbSeek( xFilial('ABB')+cABBCodigo ) )
	TECA540( ABB->ABB_DTINI, ABB->ABB_DTFIM )
EndIf

Return 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT190BDISVI
	Executa a visualização das disciplinas para o atendente selecionado

@sample		At190BDisVi((oBrwAtd:cAlias)->AA1_CODTEC)
	
@since		24/04/2014 
@version 	P12

@param		cAtdCod, Caracter, atendente a ter a informação das disciplinas visualizadas.

/*/
//--------------------------------------------------------------------------------------------------------------------
Function At190BDisVi( cAtdCod )

DbSelectArea('AA1')
AA1->(DbSetOrder(1)) // AA1_FILIAL+AA1_CODTEC

If AA1->(DbSeek(xFilial('AA1')+cAtdCod ))
	FWExecView(STR0038,"VIEWDEF.TECA590",MODEL_OPERATION_VIEW,,,,)  // 'Consulta Disciplina'
EndIf

Return