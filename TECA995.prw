#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA995.CH"

Static cItem := ""	

//-------------------------------------------------------------------
/*/{Protheus.doc} TECA995
	Definição do modelo de Dados
/*/
//-------------------------------------------------------------------	
Function TECA995()
Local oBrowse
Local cFiltro := "!Empty(TFJ->TFJ_CONTRT) .And. At995FltVig()" 
	
oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TFJ')
oBrowse:SetDescription(STR0009) //"Custos - Orçamento ativos"
oBrowse:SetFilterDefault( cFiltro )

oBrowse:Activate()

Return NIL	

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
	Definição do modelo de Dados

/*/
//-------------------------------------------------------------------
Static Function ModelDef()

Local oModel   := Nil
Local oStrTFJ  := FWFormStruct(1,'TFJ')
Local oStrTWZ  := FWFormStruct(1,'TWZ')


oModel := MPFormModel():New('TECA995')

oStrTFJ:SetProperty( "*", MODEL_FIELD_OBRIGAT, .F. )
oStrTWZ:SetProperty("TWZ_DESCRI", MODEL_FIELD_INIT, {|oMdlGrd, cCampo, cAtualContent| At995PrdDesc( oMdlGrd, cCampo, cAtualContent ) } )

oModel:AddFields('TFJMASTER',,oStrTFJ,/*bPreValid*/,{|oModel| At995TdOk(oModel)})

oModel:AddGrid( 'TWZDETAIL', 'TFJMASTER', oStrTWZ, {|oModelGrid, nLine,cAction,cField,xValue,xOldValue|A995PreV(oModelGrid,cAction,cField,xValue,xOldValue)})
oModel:SetRelation('TWZDETAIL', {{ 'TWZ_FILIAL', 'xFilial("TWZ")' }, { 'TWZ_CODORC', 'TFJ_CODIGO' } }, TWZ->(IndexKey(1)) )

oModel:GetModel('TFJMASTER'):SetOnlyQuery()
oModel:GetModel('TFJMASTER'):SetDescription(STR0010) //"Orçamento de serviços"
oModel:GetModel('TWZDETAIL'):SetDescription(STR0011) //"Custos"
oModel:GetModel('TWZDETAIL'):SetOptional(.T.)

oModel:SetActivate({|oModel| At995Init( oModel ) })

Return oModel

//--------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
Definicao da View
@author Matheus Lando Raimundo
@return oView
/*/
//--------------------------------------------------------------------
Static Function ViewDef()
Local oModel   := ModelDef() 
Local oStrTFJ  := FWFormStruct(2,'TFJ', {|cCampo| AllTrim(cCampo) $ "TFJ_CODIGO|TFJ_PROPOS|TFJ_CODENT|TFJ_LOJA|TFJ_CONDPG|TFJ_LUCRO|TFJ_ADM"})
Local oStrTWZ  := FWFormStruct(2,'TWZ', {|cCampo| !AllTrim(cCampo) $ "TWZ_CODORC"})
Local oView    := FWFormView():New()

oView:SetModel(oModel)

//Inclui a consulta para os registros na tabela ABB.
oView:AddUserButton(STR0001, "" ,{|oModel| At995Aloc(oModel)},,VK_F4) //"Alocações(F4)"

oView:AddField('VIEW_TFJ' ,oStrTFJ, 'TFJMASTER')	
oView:AddGrid('VIEW_TWZ' ,oStrTWZ, 'TWZDETAIL')
oView:CreateHorizontalBox('CIMA',25)
oView:CreateHorizontalBox('MEIO',75)

oView:SetOwnerView('VIEW_TFJ','CIMA' )
oView:SetOwnerView('VIEW_TWZ','MEIO')
oView:EnableTitleView('VIEW_TWZ')
oView:EnableTitleView('VIEW_TFJ')

oStrTFJ:SetProperty("*",MVC_VIEW_CANCHANGE,.F.)

//--------------------------------
// Evento de duplo click no Grid
//--------------------------------
oView:SetViewProperty("VIEW_TWZ","GRIDDOUBLECLICK",{{|oFormulario,cFieldName,nLineGrid,nLineModel| At995DbClk(oFormulario,cFieldName,nLineGrid,nLineModel,oView)}})

oStrTWZ:RemoveField('TWZ_CODIGO')

oView:SetCloseOnOk({||.T.})

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE STR0012	ACTION "VIEWDEF.TECA995"	OPERATION 2	ACCESS 0  	//'Visualizar'
ADD OPTION aRotina TITLE STR0013	ACTION "VIEWDEF.TECA995"	OPERATION 4 ACCESS 0  	//'Lançamentos'
ADD OPTION aRotina TITLE STR0014	ACTION "VIEWDEF.TECA995" 	OPERATION 8 ACCESS 0 	//'Imprimir'

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} At995Locais()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At995Locais()

Local oModel         := FWModelActive()
Local lRet           := .F.
Local oBrowse        := Nil
Local cAls              := GetNextAlias()
Local nSuperior      := 0
Local nEsquerda      := 0
Local nInferior      := 0
Local nDireita       := 0
Local oDlgTela := Nil
Local cQry   := ""
//Definição do índice da Consulta Padrão
Local aIndex := {"ABS_LOCAL"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek := {{ STR0015, {{STR0016,"C",TamSx3('TFL_CODIGO')[1],0,"",,}} }} //"Local de atendimento" # "Local"
Local cCodOrc := oModel:GetValue('TFJMASTER','TFJ_CODIGO')
Local cRet := ""
Local cCodTFL := ""


cQry := " SELECT " 
cQry += " ABS_FILIAL, "
cQry += " TFL_CODIGO,"
cQry += " ABS_LOCAL, "  	
cQry += " ABS_DESCRI, "
cQry += " TFL_DTINI,"  
cQry += " TFL_DTFIM,"  
cQry += " TFL_TOTRH,"
cQry += " TFL_TOTMI,"
cQry += " TFL_TOTMC,"
cQry += " TFL_TOTLE"    
cQry += " FROM " + RetSqlName("ABS") + " ABS "  
cQry += " INNER JOIN " + RetSqlName("TFL") + " TFL "
cQry += " ON TFL.TFL_FILIAL = '" +   xFilial('TFL') + "'"
cQry += " AND TFL.TFL_LOCAL = ABS.ABS_LOCAL "  
cQry += " AND TFL.D_E_L_E_T_ <> '*'"  
cQry += " AND TFL_CODPAI =  '" + cCodOrc  + "'"
cQry += " WHERE ABS_FILIAL = '" +  xFilial('ABS') + "'"
cQry += " AND ABS.D_E_L_E_T_ <> '*'"
  
nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE STR0017 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //"Locais de Atendimento"
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0017) //"Locais de Atendimento"
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cRet := (oBrowse:Alias())->TFL_CODIGO,  , lRet := .T., oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0018), {|| cRet := (oBrowse:Alias())->TFL_CODIGO,  lRet := .T., oDlgTela:End()},, 2 ) //Confirmar
oBrowse:AddButton( OemTOAnsi(STR0019),  {|| cRet := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

ADD COLUMN oColumn DATA { ||  ABS_FILIAL } 	TITLE STR0020 		SIZE TamSx3('ABS_FILIAL')[1] 	OF oBrowse //"Filial"
ADD COLUMN oColumn DATA { ||  TFL_CODIGO } 	TITLE STR0021 		SIZE TamSx3('TFL_CODIGO')[1] 	OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  ABS_LOCAL} 	TITLE STR0022		SIZE TamSx3('ABS_LOCAL')[1]  	OF oBrowse //"Local"
ADD COLUMN oColumn DATA { ||  ABS_DESCRI } 	TITLE STR0023 		SIZE TamSx3('ABS_DESCRI')[1]  	OF oBrowse //"Descrição"
ADD COLUMN oColumn DATA { ||  TFL_DTINI } 	TITLE STR0024 		SIZE TamSx3('TFL_DTINI')[1]  	OF oBrowse //"Dt Ini"
ADD COLUMN oColumn DATA { ||  TFL_DTFIM } 	TITLE STR0025 		SIZE TamSx3('TFL_DTFIM')[1]  	OF oBrowse //"Dt Fim"
ADD COLUMN oColumn DATA { ||  TFL_TOTRH } 	TITLE STR0026 		SIZE TamSx3('TFL_TOTRH')[1]  	OF oBrowse //"Total RH"
ADD COLUMN oColumn DATA { ||  TFL_TOTMI } 	TITLE STR0027		SIZE TamSx3('TFL_TOTMI')[1]  	OF oBrowse //"Total MI"
ADD COLUMN oColumn DATA { ||  TFL_TOTMC } 	TITLE STR0028	 	SIZE TamSx3('TFL_TOTMC')[1]  	OF oBrowse //"Total MC"
ADD COLUMN oColumn DATA { ||  TFL_TOTLE } 	TITLE STR0029	 	SIZE TamSx3('TFL_TOTLE')[1]  	OF oBrowse //"Total LE"
            
oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED
 
If lRet
	cItem := cRet 
EndIf
     
     
Return lRet



//-------------------------------------------------------------------
/*/{Protheus.doc} At995PrdMI()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At995PrdMI()

Local oModel         := FWModelActive()
Local lRet           := .F.
Local oBrowse        := Nil
Local cAls              := GetNextAlias()
Local nSuperior      := 0	
Local nEsquerda      := 0
Local nInferior      := 0
Local nDireita       := 0
Local oDlgTela := Nil
Local cQry   := ""
//Definição do índice da Consulta Padrão
Local aIndex := {"TFG_PRODUT"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek := {{ STR0030, {{STR0031,"C",TamSx3("TFG_PRODUT")[1],0,"",,}} }} //"Produtos" # "Produto"
Local cCodOrc := oModel:GetValue('TFJMASTER','TFJ_CODIGO')
Local cLocal := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')
Local cProd := ""
Local cAls := GetNextAlias()

Local cRet := ""

If !Empty(oModel:GetValue('TFJMASTER','TFJ_CODTAB'))
	  		
	cQry := " SELECT TFG_FILIAL, TFG_COD, TFG_PRODUT, B1_DESC ,TFG_QTDVEN ,TFG_PERINI ,TFG_PERFIM FROM " + RetSqlName("TFG") +  " TFG "
	cQry += " INNER JOIN "  + RetSqlName("TFL") + " TFL "  
	cQry += " ON TFL.TFL_FILIAL = '" +  xFilial('TFL') + "'"
	cQry += " AND TFL.TFL_CODPAI = '" + cCodOrc + "'"
	cQry += " AND TFL.TFL_CODIGO = '" + cLocal + "'"
	cQry += " AND TFL.D_E_L_E_T_ <> '*'"
	cQry += " AND TFG.TFG_CODPAI = TFL.TFL_CODIGO " 
	cQry += "  INNER JOIN " +   RetSqlName("SB1") + " SB1 "
	cQry += " ON SB1.B1_FILIAL = '" +  xFilial('SB1') + "'"
	cQry += " AND SB1.B1_COD = TFG.TFG_PRODUT "
	cQry += " AND SB1.D_E_L_E_T_ <> '*'"
	cQry += " WHERE TFG.TFG_FILIAL = '"  + xFilial('TFG') + "'"
	cQry += " AND TFG.D_E_L_E_T_ <> '*'"
Else	
	cQry := " SELECT TFG_FILIAL, TFG_COD, TFG_PRODUT, B1_DESC ,TFG_QTDVEN ,TFG_PERINI ,TFG_PERFIM FROM " + RetSqlName("TFG") +  " TFG " 
	cQry += " INNER JOIN "  + RetSqlName("TFL") + " TFL "  
	cQry += " ON TFL.TFL_FILIAL = '" +  xFilial('TFL') + "'"
	cQry += " AND TFL.TFL_CODPAI = '" + cCodOrc + "'"
	cQry += " AND TFL.TFL_CODIGO = '" + cLocal + "'"	
	cQry += " AND TFL.D_E_L_E_T_ <> '*'"
	cQry += "  INNER JOIN " + RetSqlName("TFF") + " TFF ON TFF.TFF_FILIAL = '" + xFilial('TFF') + "'" + " AND TFF.TFF_CODPAI = TFL.TFL_CODIGO" 
	cQry += "  AND TFG.TFG_CODPAI = TFF.TFF_COD" 
	cQry += "  INNER JOIN " +   RetSqlName("SB1") + " SB1 "
	cQry += "  ON SB1.B1_FILIAL = '" +  xFilial('SB1') + "'"
	cQry += "  AND SB1.B1_COD = TFG.TFG_PRODUT "
	cQry += "  AND SB1.D_E_L_E_T_ <> '*'"
	cQry += "    WHERE TFG.TFG_FILIAL = '"  + xFilial('TFG') + "'"
	cQry += "    AND TFG.D_E_L_E_T_ <> '*'"
	cQry += "    AND TFF.D_E_L_E_T_ <> '*'" 			
EndIf

  
nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE STR0030 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //"Produto"
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0038) //"Produtos MI" 
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cRet := (oBrowse:Alias())->TFG_COD,  , lRet := .T., oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0018), {|| cRet := (oBrowse:Alias())->TFG_COD, lRet := .T., oDlgTela:End()},, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0019), {|| cRet := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

ADD COLUMN oColumn DATA { ||  TFG_FILIAL } 	TITLE STR0020 		SIZE TamSx3('TFG_FILIAL')[1] 	OF oBrowse //"Filial"
ADD COLUMN oColumn DATA { ||  TFG_COD} 		TITLE STR0021 		SIZE TamSx3('TFG_COD')[1]  		OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  TFG_PRODUT } 	TITLE STR0031	 	SIZE TamSx3('TFG_PRODUT')[1] 	OF oBrowse //"Produto" 
ADD COLUMN oColumn DATA { ||  B1_DESC } 	TITLE STR0023	 	SIZE TamSx3('B1_DESC')[1]  		OF oBrowse //"Descrição"
ADD COLUMN oColumn DATA { ||  TFG_QTDVEN } 	TITLE STR0032	 	SIZE TamSx3('TFG_QTDVEN')[1] 	OF oBrowse //"Quantidade"
ADD COLUMN oColumn DATA { ||  TFG_PERINI } 	TITLE STR0033	 	SIZE TamSx3('TFG_PERINI')[1]  	OF oBrowse //"Per ini"
ADD COLUMN oColumn DATA { ||  TFG_PERFIM } 	TITLE STR0034	 	SIZE TamSx3('TFG_PERFIM')[1]  	OF oBrowse //"Per fim"
            
oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED
 
If lRet
	cItem := cRet 
EndIf

     
Return lRet



//-------------------------------------------------------------------
/*/{Protheus.doc} At995PrdMC()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At995PrdMC()

Local oModel         := FWModelActive()
Local lRet           := .F.
Local oBrowse        := Nil
Local cAls              := GetNextAlias()
Local nSuperior      := 0	
Local nEsquerda      := 0
Local nInferior      := 0
Local nDireita       := 0
Local oDlgTela := Nil
Local cQry   := ""
//Definição do índice da Consulta Padrão
Local aIndex := {"TFH_PRODUT"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek := {{ STR0030, {{STR0031,"C",TamSx3("TFH_PRODUT")[1],0,"",,}} }} //"Produtos" # "Produto"
Local cCodOrc := oModel:GetValue('TFJMASTER','TFJ_CODIGO')
Local cContr := oModel:GetValue('TFJMASTER','TFJ_CONTRT')
Local cRevi := oModel:GetValue('TFJMASTER','TFJ_CONREV')
Local cLocal := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')

Local cRet := ""

If !Empty(oModel:GetValue('TFJMASTER','TFJ_CODTAB'))
	  		
	cQry := " SELECT TFH_FILIAL, TFH_COD, TFH_PRODUT, B1_DESC ,TFH_QTDVEN ,TFH_PERINI ,TFH_PERFIM FROM " + RetSqlName("TFH") +  " TFH " 
	
	cQry += " INNER JOIN "  + RetSqlName("TFL") + " TFL "  
	cQry += " ON TFL.TFL_FILIAL = '" +  xFilial('TFL') + "'"
	cQry += " AND TFL.TFL_CODPAI = '" + cCodOrc + "'"
	cQry += " AND TFL.TFL_CODIGO = '" + cLocal + "'"
	cQry += " AND TFL.D_E_L_E_T_ <> '*'"
	cQry += " AND TFH.TFH_CODPAI = TFL.TFL_CODIGO "
	cQry += " INNER JOIN " +   RetSqlName("SB1") + " SB1 "
	cQry += " ON SB1.B1_FILIAL = '" +  xFilial('SB1') + "'"
	cQry += " AND SB1.B1_COD = TFH.TFH_PRODUT "
	cQry += " AND SB1.D_E_L_E_T_ <> '*'"
	cQry += " WHERE TFH.TFH_FILIAL = '"  + xFilial('TFH') + "'"
	cQry += " AND TFH.D_E_L_E_T_ <> '*'"	

Else	
	cQry := " SELECT TFH_FILIAL, TFH_COD, TFH_PRODUT, B1_DESC ,TFH_QTDVEN ,TFH_PERINI ,TFH_PERFIM FROM " + RetSqlName("TFH") +  " TFH "
	cQry += " INNER JOIN "  + RetSqlName("TFL") + " TFL "
	cQry += " ON TFL.TFL_FILIAL = '" +  xFilial('TFL') + "'"
	cQry += " AND TFL.TFL_CODPAI = '" + cCodOrc + "'"
	cQry += " AND TFL.TFL_CODIGO = '" + cLocal + "'"
	cQry += " AND TFL.D_E_L_E_T_ <> '*'" 	
	cQry += "  INNER JOIN " + RetSqlName("TFF") + " TFF ON TFF.TFF_FILIAL = '" + xFilial('TFF') + "'" + " AND TFF.TFF_CODPAI = TFL.TFL_CODIGO" 
	cQry += "  AND TFH.TFH_CODPAI = TFF.TFF_COD" 
	cQry += "  INNER JOIN " +   RetSqlName("SB1") + " SB1 "
	cQry += "  ON SB1.B1_FILIAL = '" +  xFilial('SB1') + "'"
	cQry += "  AND SB1.B1_COD = TFH.TFH_PRODUT "
	cQry += "  AND SB1.D_E_L_E_T_ <> '*'"
	cQry += "    WHERE TFH.TFH_FILIAL = '"  + xFilial('TFH') + "'"
	cQry += "    AND TFH.D_E_L_E_T_ <> '*'"
	cQry += "    AND TFF.D_E_L_E_T_ <> '*'" 				
	  		
EndIf
  
nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE STR0031 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //"Produto"
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0037) //"Produtos MC"
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cRet := (oBrowse:Alias())->TFH_COD,  lRet := .T., oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0018), {|| cRet := (oBrowse:Alias())->TFH_COD, lRet := .T.,oDlgTela:End()},, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0019),  {|| cRet := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

ADD COLUMN oColumn DATA { ||  TFH_FILIAL } 	TITLE STR0020 		SIZE TamSx3('TFH_FILIAL')[1]	OF oBrowse //"Filial"
ADD COLUMN oColumn DATA { ||  TFH_COD}	 	TITLE STR0021		SIZE TamSx3('TFH_COD')[1]  		OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  TFH_PRODUT } 	TITLE STR0031		SIZE TamSx3('TFH_PRODUT')[1] 	OF oBrowse //"Produto" 
ADD COLUMN oColumn DATA { ||  B1_DESC } 	TITLE STR0023	 	SIZE TamSx3('B1_DESC')[1]  		OF oBrowse //"Descrição"
ADD COLUMN oColumn DATA { ||  TFH_QTDVEN } 	TITLE STR0032	 	SIZE TamSx3('TFH_QTDVEN')[1]  	OF oBrowse //"Quantidade"
ADD COLUMN oColumn DATA { ||  TFH_PERINI } 	TITLE STR0033	 	SIZE TamSx3('TFH_PERINI')[1]  	OF oBrowse //"Per ini"
ADD COLUMN oColumn DATA { ||  TFH_PERFIM } 	TITLE STR0034	 	SIZE TamSx3('TFH_PERFIM')[1]  	OF oBrowse //"Per fim"
            
oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED


If lRet
	cItem := cRet 
EndIf
     
Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At995PrdRH()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At995PrdRH()

Local oModel         := FWModelActive()
Local lRet           := .F.
Local oBrowse        := Nil
Local cAls              := GetNextAlias()
Local nSuperior      := 0	
Local nEsquerda      := 0
Local nInferior      := 0
Local nDireita       := 0
Local oDlgTela := Nil
Local cQry   := ""
//Definição do índice da Consulta Padrão
Local aIndex := {"TFF_PRODUT"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek := {{ STR0030, {{STR0031,"C",TamSx3("TFF_PRODUT")[1],0,"",,}} }} //"Produtos" # "Produto"
Local cCodOrc := oModel:GetValue('TFJMASTER','TFJ_CODIGO')
Local cContr := oModel:GetValue('TFJMASTER','TFJ_CONTRT')
Local cRevi := oModel:GetValue('TFJMASTER','TFJ_CONREV')
Local cLocal := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')

Local cRet := ""

cQry := " SELECT " 
cQry += " TFF_FILIAL,"
cQry += " TFF_COD, "
cQry += " TFF_PRODUT, "
cQry += " B1_DESC, "
cQry += " TFF_QTDVEN, "
cQry += " TFF_PRCVEN, "
cQry += " TFF_PERINI, "
cQry += " TFF_PERFIM "  
cQry += " FROM " + RetSqlName("TFF") + " TFF "
cQry += " INNER JOIN " + RetSqlName("SB1") + " SB1 "
cQry += " ON SB1.B1_FILIAL = '" +  xFilial('SB1') + "'"
cQry += " AND SB1.B1_COD = TFF.TFF_PRODUT"  
cQry += " AND SB1.D_E_L_E_T_ <> '*'"

cQry += " INNER JOIN " + RetSqlName("TFL") + " TFL "
cQry += " ON TFL.TFL_FILIAL = '" +  xFilial('TFL') + "'"
cQry += " AND TFL.TFL_CODPAI = '"  + cCodOrc + "'"
cQry += " AND TFL.TFL_CODIGO = '"  + cLocal + "'"
cQry += " AND TFL.TFL_CODIGO = TFF.TFF_CODPAI"
cQry += " AND TFL.D_E_L_E_T_ <> '*'"
  
cQry += " WHERE TFF_FILIAL = '" + xFilial('TFF') + "'"
cQry += " AND TFF.D_E_L_E_T_ <> '*'"
  
nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE STR0031 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //"Produto"
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0035) //"Produtos RH"
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cRet := (oBrowse:Alias())->TFF_COD,  lRet := .T., oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0018), {|| cRet := (oBrowse:Alias())->TFF_COD, lRet := .T.,  oDlgTela:End()},, 2 ) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0019),  {|| cRet := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

ADD COLUMN oColumn DATA { ||  TFF_FILIAL } 	TITLE STR0020 		SIZE TamSx3('TFF_FILIAL')[1] 	OF oBrowse //"Filial" 
ADD COLUMN oColumn DATA { ||  TFF_COD} 		TITLE STR0021		SIZE TamSx3('TFF_COD')[1]  		OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  TFF_PRODUT } 	TITLE STR0031		SIZE TamSx3('TFF_PRODUT')[1] 	OF oBrowse //"Produto"
ADD COLUMN oColumn DATA { ||  B1_DESC } 	TITLE STR0023	 	SIZE TamSx3('B1_DESC')[1]  		OF oBrowse //"Descrição"
ADD COLUMN oColumn DATA { ||  TFF_QTDVEN } 	TITLE STR0032	 	SIZE TamSx3('TFF_QTDVEN')[1]  	OF oBrowse //"Quantidade"
ADD COLUMN oColumn DATA { ||  TFF_PERINI } 	TITLE STR0033	 	SIZE TamSx3('TFF_PERINI')[1]  	OF oBrowse //"Per ini"
ADD COLUMN oColumn DATA { ||  TFF_PERFIM } 	TITLE STR0034 		SIZE TamSx3('TFF_PERFIM')[1]  	OF oBrowse //"Per fim"
            
oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED

If lRet
	cItem := cRet 
EndIf

     
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995PrdLE()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At995PrdLE()

Local oModel         := FWModelActive()
Local lRet           := .F.
Local oBrowse        := Nil
Local cAls              := GetNextAlias()
Local nSuperior      := 0	
Local nEsquerda      := 0
Local nInferior      := 0
Local nDireita       := 0
Local oDlgTela := Nil
Local cQry   := ""
//Definição do índice da Consulta Padrão
Local aIndex := {"TFI_PRODUT"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek := {{ STR0030, {{STR0031,"C",TamSx3("TFI_PRODUT")[1],0,"",,}} }} //Produtos # Produto
Local cCodOrc := oModel:GetValue('TFJMASTER','TFJ_CODIGO')
Local cContr := oModel:GetValue('TFJMASTER','TFJ_CONTRT')
Local cRevi := oModel:GetValue('TFJMASTER','TFJ_CONREV')
Local cLocal := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')

Local cRet := ""

cQry := " SELECT " 
cQry += " TFI_FILIAL,"
cQry += " TFI_COD, "
cQry += " TFI_PRODUT, "
cQry += " B1_DESC, "
cQry += " TFI_QTDVEN, ""
cQry += " TFI_PERINI, "
cQry += " TFI_PERFIM "  
cQry += " FROM " + RetSqlName("TFI") + " TFI "
cQry += " INNER JOIN " + RetSqlName("SB1") + " SB1 "
cQry += " ON SB1.B1_FILIAL = '" +  xFilial('SB1') + "'"
cQry += " AND SB1.B1_COD = TFI.TFI_PRODUT"  
cQry += " AND SB1.D_E_L_E_T_ <> '*'"

cQry += " INNER JOIN " + RetSqlName("TFL") + " TFL "
cQry += " ON TFL.TFL_FILIAL = '" +  xFilial('TFL') + "'"
cQry += " AND TFL.TFL_CODPAI = '"  + cCodOrc + "'"
cQry += " AND TFL.TFL_CODIGO = '"  + cLocal + "'"
cQry += " AND TFL.TFL_CODIGO = TFI.TFI_CODPAI"
cQry += " AND TFL.D_E_L_E_T_ <> '*'"
  
cQry += " WHERE TFI_FILIAL = '" + xFilial('TFI') + "'"
cQry += " AND TFI.D_E_L_E_T_ <> '*'"
  
nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE STR0031 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //Produto
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0036) //"Produtos LE" 
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cRet := (oBrowse:Alias())->TFI_COD,  lRet := .T., oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi(STR0018), {|| cRet := (oBrowse:Alias())->TFI_COD,  lRet := .T., oDlgTela:End()},, 2 )
oBrowse:AddButton( OemTOAnsi(STR0019),  {|| cRet := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

ADD COLUMN oColumn DATA { ||  TFI_FILIAL } 	TITLE STR0020 		SIZE TamSx3('TFI_FILIAL')[1] 	OF oBrowse //"Filial"
ADD COLUMN oColumn DATA { ||  TFI_COD} 		TITLE STR0021		SIZE TamSx3('TFI_COD')[1]  		OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  TFI_PRODUT } 	TITLE STR0031		SIZE TamSx3('TFI_PRODUT')[1] 	OF oBrowse //"Produto"
ADD COLUMN oColumn DATA { ||  B1_DESC } 	TITLE STR0023		SIZE TamSx3('B1_DESC')[1]  		OF oBrowse //"Descrição"
ADD COLUMN oColumn DATA { ||  TFI_QTDVEN } 	TITLE STR0032	 	SIZE TamSx3('TFI_QTDVEN')[1]  	OF oBrowse //"Quantidade"
ADD COLUMN oColumn DATA { ||  TFI_PERINI } 	TITLE STR0033	 	SIZE TamSx3('TFI_PERINI')[1]  	OF oBrowse //"Per ini" 
ADD COLUMN oColumn DATA { ||  TFI_PERFIM } 	TITLE STR0034	 	SIZE TamSx3('TFI_PERFIM')[1]  	OF oBrowse //"Per fim" 
            
oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED

If lRet
	cItem := cRet 
EndIf
     
Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} At995RetIt()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At995RetIt()

Return cItem  

//-------------------------------------------------------------------
/*/{Protheus.doc} At995Pesq()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995Pesq()
Local lRet := .F.
Local oModel := FwModelActive()
Local cTpServ := oModel:GetValue('TWZDETAIL','TWZ_TPSERV') 
cItem := ""



If  cTpServ == '1'
	lRet := At995PrdRH()
ElseIf cTpServ == '2'
	lRet := At995PrdMI()
ElseIf cTpServ == '3'
	lRet := At995PrdMC()
ElseIf cTpServ == '4'
	lRet := At995PrdLE()	
EndIf	

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At995VldIt()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995VldIt()
Local oModel  := FwModelActive()
Local cTpServ := oModel:GetValue('TWZDETAIL','TWZ_TPSERV')
Local cItem   := oModel:GetValue('TWZDETAIL','TWZ_ITEM')
Local cLocal := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')
Local lRet    := .T.

If  cTpServ == '1'		
	lRet := ExistCpo('TFF',cItem,1) 	
ElseIf cTpServ == '2'
	lRet := ExistCpo('TFG',cItem,1)
ElseIf cTpServ == '3'
	lRet := ExistCpo('TFH',cItem,1)
ElseIf cTpServ == '4'
	lRet := ExistCpo('TFI',cItem,1)	
EndIf	
      

Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} At995Gtl()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995Gtl()
Local oModel  := FwModelActive()
Local cTpServ := oModel:GetValue('TWZDETAIL','TWZ_TPSERV')
Local cLocal := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')
Local cItem   := oModel:GetValue('TWZDETAIL','TWZ_ITEM')
Local cRet    := ""

If  cTpServ == '1'		
	cRet := Posicione( "TFF", 1, xFilial("TFF")+cItem, "TFF_PRODUT" ) 	
ElseIf cTpServ == '2'
	cRet := Posicione( "TFG", 1, xFilial("TFG")+cItem, "TFG_PRODUT" )
ElseIf cTpServ == '3'
	cRet := Posicione( "TFH", 1, xFilial("TFH")+cItem, "TFH_PRODUT" )
ElseIf cTpServ == '4'
	cRet := Posicione( "TFI", 1, xFilial("TFI")+cItem, "TFI_PRODUT" )
EndIf	

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995GPrd()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995GPrd()
Local oModel  := FwModelActive()
Local cProd := oModel:GetValue('TWZDETAIL','TWZ_PRODUT')
Local cRet  := ""

If !Empty(cProd)
	cRet := Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
EndIf

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A995PreV()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function A995PreV(oModelGrid,cAction,cField,xValue,xOldValue)
Local lRet := .T.

If cAction == 'SETVALUE'
	If cField == 'TWZ_LOCAL'
		If Empty(xValue) .Or. xValue <> xOldValue
			oModelGrid:ClearField('TWZ_ITEM')
			oModelGrid:ClearField('TWZ_PRODUT')
			oModelGrid:ClearField('TWZ_DESCRI')
			oModelGrid:ClearField('TWZ_TPSERV')
		EndIf
	ElseIf cField == 'TWZ_TPSERV'
		If xValue <> xOldValue 
			oModelGrid:ClearField('TWZ_ITEM')
			oModelGrid:ClearField('TWZ_PRODUT')
			oModelGrid:ClearField('TWZ_DESCRI')
		EndIf
	ElseIf cField == 'TWZ_ITEM'
		If Empty(xValue) 			
			oModelGrid:ClearField('TWZ_PRODUT')
			oModelGrid:ClearField('TWZ_DESCRI')
		EndIf		
	EndIf	
ElseIf cAction == 'DELETE' 
	If oModelGrid:IsInserted()
		RollBackSXE()
	EndIf	
	
	If !Empty(oModelGrid:GetValue('TWZ_ROTINA')) .And. (!IsInCallStack('At995ExcC') .And. !IsInCallStack('At995IncC')) 
		lRet := .F.
		Help(,, "AT995NODEL",,STR0007,1,0,,,,,,;  // "O lançamento não aconteceu manualmente e só pode ser excluído pela rotina originadora."
							{STR0008})   // "Acesse a rotina originadora e desfaça o movimento que realizou o lançamento."
	EndIf	
ElseIf cAction == 'CANSETVALUE' .And. !Empty(oModelGrid:GetValue('TWZ_ROTINA')) .And. (!IsInCallStack('At995IncC')) 
	lRet := .F.	
EndIf

Return lRet                                               

//-------------------------------------------------------------------
/*/{Protheus.doc} At995VldLoc()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995VldLoc()
Local oModel  := FwModelActive()
Local cCodOrc := oModel:GetValue('TFJMASTER','TFJ_CODIGO')
Local cLocal  := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')
Local lRet    := .T.
Local cQry	  := ""
Local cAls	:= GetNextAlias()

cQry := " SELECT TFL_LOCAL" 
cQry += " FROM " + RetSqlName("TFL") + " TFL "  
cQry += " WHERE TFL_FILIAL = '" +  xFilial('TFL') + "'"
cQry += " AND TFL_CODPAI = '" +  cCodOrc + "'"
cQry += " AND TFL_CODIGO  = '" +  cLocal + "'"
cQry += " AND TFL.D_E_L_E_T_ = ' '"      

cQry := ChangeQuery(cQry)
DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAls,.T.,.T.)

lRet := !Empty((cAls)->TFL_LOCAL)

(cAls)->(DbCloseArea())

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At995DesLc()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995DesLc()
Local oModel  := FwModelActive()
Local cCodigo  := ""
Local cLocal	:= ""
Local cRet := ""

cCodigo	:= oModel:GetValue('TWZDETAIL','TWZ_LOCAL')
cLocal 	:= Posicione( "TFL", 1, xFilial("TFL")+cCodigo, "TFL_LOCAL")
cRet   	:= Posicione( "ABS", 1, xFilial("ABS")+cLocal, "ABS_DESCRI")

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995TdOk()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995TdOk()
Local oModel := FwModelActive()
Local lRet := .T.
Local nI := 1
Local nVlCust := 0
Local oTWZDetail  := oModel:GetModel('TWZDETAIL')
Local nVlrOrc := 0
Local cPict 		:= PesqPict("TFL","TFL_TOTRH")
Local cAviso		:= ""
Local cDescServ := ""
Local cTpServ	:= ""
Local aItens := {}
Local aArea := GetArea()

If SuperGetMV("MV_GSCUSMA",.F.,"2") == '2'
	
	For nI := 1 To oTWZDetail:Length()
		oTWZDetail:GoLine(nI)
		If !oTWZDetail:IsDeleted() .And. oTWZDetail:GetValue("TWZ_TPSERV") <> '5' 			
			If !Empty(oTWZDetail:GetValue("TWZ_ITEM"))
				nPos := Ascan(aItens,{|x| x[2] + x[3] == oTWZDetail:GetValue("TWZ_TPSERV") + oTWZDetail:GetValue("TWZ_ITEM")})
				If nPos == 0
					Aadd(aItens, {Alltrim(oTWZDetail:GetValue("TWZ_LOCAL")),oTWZDetail:GetValue("TWZ_TPSERV"),oTWZDetail:GetValue("TWZ_ITEM"),;
										 AllTrim(oTWZDetail:GetValue("TWZ_PRODUT")) + ' - ' +  AllTrim(oTWZDetail:GetValue("TWZ_DESCRI")),;
										 oTWZDetail:GetValue("TWZ_VLCUST")})
				Else
					aItens[nPos,5] += oTWZDetail:GetValue("TWZ_VLCUST")
				EndIf
			EndIf
		EndIf				
	Next nI	
	
	For nI := 1 To Len(aItens)
		nVlrOrc := 0
		cTpServ := aItens[nI,2]
		cItem := aItens[nI,3]
		nVlCust := aItens[nI,5]
		If  cTpServ == '1'		
			TFF->(DbSetOrder(1))
			If TFF->(DbSeek(xFilial('TFF')+cItem))
				nVlrOrc := TFF->TFF_PRCVEN * TFF->TFF_QTDVEN 
				cDescServ := "RH"
			EndIf	
		ElseIf cTpServ == '2'
			TFG->(DbSetOrder(1))
			If TFG->(DbSeek(xFilial('TFG')+cItem))
				nVlrOrc := TFG->TFG_PRCVEN * TFG->TFG_QTDVEN 
				cDescServ := "MI"
			EndIf	
			
		ElseIf cTpServ == '3'			
			TFH->(DbSetOrder(1))
			If TFH->(DbSeek(xFilial('TFH')+cItem))
				nVlrOrc := TFH->TFH_PRCVEN * TFH->TFH_QTDVEN 
				cDescServ := "MC"
			EndIf	
		ElseIf cTpServ == '4'
			TFI->(DbSetOrder(1))
			If TFI->(DbSeek(xFilial('TFI')+cItem))
				nVlrOrc := TFI->TFI_TOTAL 
				cDescServ := "LE"
			EndIf
		EndIf
		
		If nVlCust > nVlrOrc
			lRet := .F.
			cAviso 	+=  STR0039 + aItens[nI,1] +  CRLF  ; 				 //'Local: '
			+ STR0040 + cDescServ +  CRLF;  							 //"Serviço: "
		    + STR0041 + aItens[nI,3]+  CRLF ;  							 //"Item: "
		    + STR0042 + aItens[nI,4] + CRLF ;  							 //"Prodto: "
		    + STR0043 + Alltrim(Transform(nVlrOrc,cPict)) + CRLF ; 		 //"Valor Orçado: "
		    + STR0044 + Alltrim(Transform(nVlCust,cPict)) + CRLF + CRLF  //"Valor Custo: "	
		EndIf					
	Next nI 
EndIf	

If !lRet
	AtShowLog(Alltrim(cAviso), STR0045 , .T., .T., .T.,.F.) //'O valor de custo do(s) item(ns) não pode ultrapassar o valor orçado'
EndIf

RestArea(aArea)
Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At995VlOrc()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995VlOrc(cCodOrc)
Local nRet := 0
Local cAls	:= GetNextAlias()

cQry := " SELECT " 
cQry += " SUM(TFL_TOTRH) TFL_TOTRH, "
cQry += " SUM(TFL_TOTMI) TFL_TOTMI, "
cQry += " SUM(TFL_TOTMC) TFL_TOTMC, "
cQry += " SUM(TFL_TOTLE) TFL_TOTLE "

If TFL->(ColumnPos('TFL_TOTIMP'))
	cQry += " ,SUM(TFL_TOTIMP) TFL_TOTIMP "
EndIf

cQry += " FROM " + RetSqlName("TFL") + " TFL "  
cQry += " WHERE TFL.TFL_FILIAL = '" +   xFilial('TFL') + "'"	
cQry += " AND TFL_CODPAI =  '" + cCodOrc  + "'"
cQry += " AND TFL.D_E_L_E_T_ = ' '"  
 
cQry := ChangeQuery(cQry)
DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAls,.T.,.T.)  

nRet := (cAls)->TFL_TOTRH + (cAls)->TFL_TOTMI + (cAls)->TFL_TOTMC + (cAls)->TFL_TOTLE

If TFL->(ColumnPos('TFL_TOTIMP'))
	nRet +=  (cAls)->TFL_TOTIMP 
EndIf
    
(cAls)->(DbCloseArea())
Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995Init()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995Init( oModel )
Local nI := 1
Local nVlCust := 0
Local oTWZDetail  := oModel:GetModel('TWZDETAIL')
Local cCodigo  := oModel:GetValue('TWZDETAIL','TWZ_LOCAL')
Local cLocal	:= ""
Local cRet	:= ""

For nI := 1 To oTWZDetail:Length()
	oTWZDetail:GoLine(nI)
	If !oTWZDetail:IsDeleted()
		If !Empty(oTWZDetail:GetValue('TWZ_LOCAL'))
			cLocal := Posicione( "TFL", 1, xFilial("TFL")+oTWZDetail:GetValue('TWZ_LOCAL'), "TFL_LOCAL")
			cRet   := Posicione( "ABS", 1, xFilial("ABS")+cLocal, "ABS_DESCRI")
			oTWZDetail:LoadValue('TWZ_DESLOC',cRet)
		EndIf
	EndIf			
Next nI	
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} At995Custo()
Função para montagem de Array e Inclusão Do Custo

@sample		At995Custo(cOrcamento,cCodTFL,cLocal,cProd,cService,nVlrCusto,cOrigem)

@param		ExpC1 - Codigo do Orçamento
@param		ExpC2 - Codigo das tabelas dos itens
@param		ExpC3 - Codigo do Local de Atendimento
@param		ExpC4 - Codigo do Produto
@param		ExpC5 - Codigo do Tipo de Serviço("MI","MC", ETC.)
@param		ExpN6 - Valor do Custo
@param		ExpC7 - Origem do Custo
	
@return		ExpC - Codigo Gerado pela tabela TWZ

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Function At995Custo( cOrcamento, cCodIT, cLocal, cProd, cService, nVlrCusto, cOrigem, lHelp )
Local cCod		:= GetSxeNum('TWZ','TWZ_CODIGO')
Local aAreaTFJ	:= TFJ->(GetArea())
Local cItem		:= ""
Local nX		:= 0
Local aCampos	:= {}

Default lHelp := .F.

//O custo só será gravado quando o valor for maior que zero.
If nVlrCusto <= 0
	cCod := ""
	TWZ->(RollBackSX8())
	Return (cCod)
EndIf

DbSelectArea("TFJ")
TFJ->(DbSetOrder(1))
TFJ->(DbSeek(xFilial("TFJ")+cOrcamento))

Aadd(aCampos,{"TWZ_FILIAL", xFilial("TWZ") })
Aadd(aCampos,{"TWZ_CODIGO", cCod })
Aadd(aCampos,{"TWZ_CODORC", cOrcamento })
Aadd(aCampos,{"TWZ_LOCAL",cLocal })
Aadd(aCampos,{"TWZ_TPSERV",cService })

If cService <> "5"
	Aadd(aCampos,{"TWZ_ITEM",cCodIT})
EndIf	

Aadd(aCampos,{"TWZ_PRODUT",cProd })
Aadd(aCampos,{"TWZ_VLCUST",nVlrCusto })
Aadd(aCampos,{"TWZ_DTINC",dDataBase })
Aadd(aCampos,{"TWZ_ROTINA",cOrigem })

If !At995IncC(aCampos, lHelp)
	cCod := ""
EndIf

Restarea(aAreaTFJ)

Return (cCod)

//-------------------------------------------------------------------
/*/{Protheus.doc} At995IncC()
Função para Realizar a Inclusão do Custo

A Tabela TFJ deve estar posicionada ao ser chamado a função

@sample		At995IncC(aCampos)

@param		ExpA1 - Array com os campos a serem Incluidos
	
@return		ExpL - Retorna Verdadeiro, caso a Inclusão dos campos foram feitos com sucesso

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Static Function At995IncC(aCampos, lHelp)
Local lRet		:= .T.
Local oMdlApont := FwModelActive()
Local nX		:= 0
Local oMdlTWZ	:= NIL
Local oModel	:= FWLoadModel("TECA995")

Default aCampos := {}
Default lHelp 	:= .F.

oModel:SetOperation( MODEL_OPERATION_UPDATE )
lRet := oModel:Activate()
oMdlTWZ := oModel:GetModel("TWZDETAIL")

If lRet .And. !oMdlTWZ:IsEmpty()
	oMdlTWZ:AddLine()
EndIf

If lRet .And. !Empty(aCampos)
	For nX := 1 To Len(aCampos)
		If !oMdlTWZ:SetValue(aCampos[nX][1],aCampos[nX][2] )
			lRet := .F.
			Exit
		EndIf	
	Next nX

	If lRet
		lRet := oModel:VldData() .And. oModel:CommitData()
		If lRet
			TWZ->(ConfirmSX8())
		Else
			TWZ->(RollBackSX8())
		EndIf
	Else
		TWZ->(RollBackSX8())		
	EndIf

	If !lRet .And. lHelp
		AtErroMvc( oModel )
		MostraErro()
	EndIf
EndIf

//Restaura o Model Anterior
If oMdlApont <> Nil
	FwModelActive( oMdlApont )
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995ExcC()
Função para Exclusão da linha do custo

@sample		At995ExcC(cOrcamento,cCod)

@param		ExpC1 - Codigo do Orçamento
@param		ExpC2 - Codigo da tabela TWZ que será excluido
	
@return		ExpL - Retorna Verdadeiro, caso a Exclusão foi feita com sucesso

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Function At995ExcC(cOrcamento,cCod, lHelp)
Local lRet		:= .F.
Local oMdlApont := FwModelActive()
Local oModel	:= FWLoadModel("TECA995")
Local oMdlTWZ	:= NIL
Local aAreaTFJ	:= TFJ->(GetArea())

Default cCod 		:= ""
Default cOrcamento	:= ""
Default lHelp 		:= .F.

If !Empty(cOrcamento)
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(1))
	TFJ->(DbSeek(xFilial("TFJ")+cOrcamento))

	oModel:SetOperation( MODEL_OPERATION_UPDATE )
	lRet := oModel:Activate()
	oMdlTWZ := oModel:GetModel("TWZDETAIL")
	
	If lRet .And. oMdlTWZ:SeekLine({{"TWZ_CODIGO",cCod}})
		lRet := lRet .And. oMdlTWZ:DeleteLine()
		lRet := lRet .And. oModel:VldData() .And. oModel:CommitData()
	EndIf

	If !lRet .And. lHelp
		AtErroMvc( oModel )
		MostraErro()
	EndIf
EndIf

//Restaura o Model Anterior
If oMdlApont <> Nil
	FwModelActive( oMdlApont )
EndIf

RestArea(aAreaTFJ)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995AtCus()
Função para Atualização do Custo

@sample		At995AtCus(cOrcamento,cCod)

@param		ExpC1 - Codigo do Orçamento
@param		ExpC2 - Codigo da tabela TWZ que será excluido
@param		ExpC3 - Array com os campos a serem atualizados
	
@return		ExpL - Retorna Verdadeiro, caso a Atualização foi feita com sucesso

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Function At995AtCus(cOrcamento,cCod,aCampos, lHelp)
Local lRet	:= .F.
Local oMdlApont := FwModelActive()
Local oModel	:= FWLoadModel("TECA995")
Local oMdlTWZ	:= NIL
Local aAreaTFJ	:= TFJ->(GetArea())
Local nX		:= 0

Default cCod 		:= ""
Default cOrcamento	:= ""
Default aCampos		:= {}
Default lHelp 		:= .F.

If !Empty(cOrcamento)
	DbSelectArea("TFJ")
	TFJ->(DbSetOrder(1))
	TFJ->(DbSeek(xFilial("TFJ")+cOrcamento))

	oModel:SetOperation( MODEL_OPERATION_UPDATE )
	lRet := oModel:Activate()
	oMdlTWZ := oModel:GetModel("TWZDETAIL")
	
	If lRet .And. oMdlTWZ:SeekLine({{"TWZ_CODIGO",cCod}})
		If !Empty(aCampos)
			For nX := 1 To Len(aCampos)
				If !oMdlTWZ:SetValue(aCampos[nX][1],aCampos[nX][2] )
					lRet := .F.
					Exit
				EndIf	
			Next nX
			lRet := oModel:VldData() .And. oModel:CommitData()
		EndIf
	EndIf
	
	If !lRet .And. lHelp
		AtErroMvc( oModel )
		MostraErro()
	EndIf
EndIf

//Restaura o Model Anterior
If oMdlApont <> Nil
	FwModelActive( oMdlApont )
EndIf

RestArea(aAreaTFJ)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995FltVig()

@author Matheus Lando Raimundo      
/*/
//------------------------------------------------------------------
Function At995FltVig()
Local lRet := .F.

lRet := Posicione("CN9",1,xFilial("CN9")+TFJ->TFJ_CONTRT+TFJ->TFJ_CONREV,"CN9_SITUAC") == '05'

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At995DbClk()
Função de duplo-click para abertura dos agendamentos(ABB)

@sample		At995DbClk(oFormulario,cFieldName,nLineGrid,nLineModel,oView)

@param		ExpO1 - Objeto do Tipo FWFormGrid
@param		ExpC2 - Nome do campo do model
@param		ExpN3 - Linha do selecionada do Grid
@param		ExpN4 - Linha Correspondente no Model
@param		ExpO5 - Objeto da View
	
@return		ExpL - retornar .T. para executar a edicao do campo e .F. caso não queira editar

@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Static Function At995DbClk(oFormulario,cFieldName,nLineGrid,nLineModel,oView)
Local lRetorno	:= .T.
Local oMdlTWZ	:= NIL

Default oFormulario := Nil
Default oView       := Nil
Default cFieldName  := ""
Default nLineGrid   := 0
Default nLineModel  := 0

If oView <> Nil .And. ValType(oView) == "O" 
	oMdlTWZ := oView:GetModel("TWZDETAIL")
	If !oMdlTWZ:IsInserted()
			If cFieldName == "TWZ_TPSERV" .And. !Empty(oMdlTWZ:GetValue("TWZ_ROTINA"))
	
			// Executa função de exibição das alocações
	   		At995Aloc(oView)
				   			
			lRetorno := .F.	
		EndIf
	EndIf
				   	
EndIf

Return lRetorno

//-------------------------------------------------------------------
/*/{Protheus.doc} At995Aloc()
Função para listar os agendamentos do custo correspondente

@sample		At995Aloc(oModel)

@param		ExpO1 - Objeto do Modelo de dados
	
@author		Serviços
@since		02/02/2017
@version	12  
/*/
//------------------------------------------------------------------
Function At995Aloc(oModel)
Local oPanel	:= Nil
Local oBrowse	:= Nil
Local aSize		:= FWGetDialogSize(oMainWnd)
Local oMdlTWZ	:= oModel:GetModel('TWZDETAIL')
Local cTWZ		:= oMdlTWZ:GetValue("TWZ_CODIGO")
Local cTpServ	:= oMdlTWZ:GetValue("TWZ_TPSERV")
Local cRotina	:= oMdlTWZ:GetValue("TWZ_ROTINA")

If cTpServ <> "1" .OR. (cTpServ == "1" .And. Empty(cRotina))
	Aviso(STR0002, STR0003, {STR0004}, 2) //"A Rotina de visualização das alocações só será aberta para itens onde o campo Tipo de Serviço estiver como RH e foram incluidas de forma automatica"
	Return
EndIf

DEFINE MSDIALOG oPanel TITLE STR0005 FROM aSize[1] - 050,aSize[2]-050 TO aSize[3]-150,aSize[4]-300 PIXEL//"Alocações"

oBrowse:= FWmBrowse():New()
oBrowse:SetOwner( oPanel )   
oBrowse:SetDescription( STR0006 ) //"Lista de Alocações"
oBrowse:SetAlias( "ABB" ) 
oBrowse:DisableDetails() 
oBrowse:SetWalkThru(.F.)
oBrowse:SetAmbiente(.F.)
oBrowse:SetProfileID("12")
oBrowse:SetMenuDef( "  " )
oBrowse:SetFilterDefault( "ABB_CODTWZ = '" + cTWZ + "'" ) 
oBrowse:Activate() 

oBrowse:Refresh()

ACTIVATE MSDIALOG oPanel CENTERED


Return

/*/{Protheus.doc} At995PrdDesc()
@description 	Captura a descrição dos produtos associados com itens do orçamento de serviços
@author			josimar.assuncao
@since			28.03.2017
@version		12
@param 			oMdlGrd, objeto FWFormGridModel, modelo de dados que o campo pertence
@param 			cCampo, caracter, campo que deverá receber o conteúdo
@param 			cAtualContent, caracter, conteúdo atual do campo
@return 		Caracter, descrição do produto quando existir a necessidade de carregar conteúdo
/*/
Function At995PrdDesc( oMdlGrd, cCampo, cAtualContent )
Local cRetDesc 	:= ""
Local oMdlCab 	:= Nil
Local cCodTFJ 	:= ""

If oMdlGrd:GetLine() == 0
	oMdlCab := oMdlGrd:GetModel():GetModel("TFJMASTER")
	cCodTFJ := oMdlCab:GetValue("TFJ_CODIGO")
	If TWZ->(Recno()) > 0 .And. cCodTFJ == TWZ->TWZ_CODORC
		cRetDesc := Posicione("SB1", 1, xFilial("SB1")+TWZ->TWZ_PRODUT, "B1_DESC")
	EndIf
EndIf

Return cRetDesc