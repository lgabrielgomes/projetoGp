#include "protheus.ch"
#include "fwmvcdef.ch"
#include "fwbrowse.ch"
#include "teca934.ch"


Static cItem   := ""

/*/{Protheus.doc} TECA934
@description      Rotina de faturamento antecipado.
@author           josimar.assuncao
@since                  12.04.2017
/*/   
Function TECA934()
Local oMBrowse := FWmBrowse():New()

oMBrowse:= FWmBrowse():New() 
oMBrowse:SetAlias("TFV")
oMBrowse:SetDescription(STR0001)   //  "Faturamento Antecipado"

oMBrowse:SetFilterDefault("TFV_ANTECI = '1'") 
	
oMBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
@description      Menu para a rotina de faturamento antecipado.
@author           josimar.assuncao
@since                  12.04.2017
@return           array com as rotinas para execução a partir do browse.
/*/
Static Function MenuDef()
Local aRotina := {}
Local aLote := {}

ADD OPTION aLote TITLE STR0002 ACTION "At934ILote" OPERATION 3 ACCESS 0   // "Incluir"
ADD OPTION aLote TITLE STR0003 ACTION "At934ELote" OPERATION 5 ACCESS 0   // "Estornar"

ADD OPTION aRotina TITLE STR0004 ACTION "PesqBrw" OPERATION 1 ACCESS 0   // "Pesquisar"
ADD OPTION aRotina TITLE STR0071 ACTION "At930GerMed" OPERATION 3 ACCESS 0 	// "Medir/Apurar Contrato"
ADD OPTION aRotina TITLE STR0003 ACTION "At930GerMed" OPERATION 5 ACCESS 0 	// "Estornar"
ADD OPTION aRotina TITLE STR0005 ACTION "VIEWDEF.TECA930" OPERATION 2 ACCESS 0 	// "Visualizar"

ADD OPTION aRotina TITLE STR0006 ACTION aLote OPERATION 3 ACCESS 0   // "Op. Em Lotes"

Return aRotina


/*/{Protheus.doc} At934ILote
@description      Abre interface de processamento em Lote - Inclusão
@author           matheus.raimundo
@since                  19.04.2017
/*/
Function At934ILote()
Local aButtons    := {  {.F.,Nil},;             //- Copiar
                                         {.F.,Nil},;             //- Recortar
                                         {.F.,Nil},;             //- Colar
                                         {.F.,Nil},;             //- Calculadora
                                         {.F.,Nil},;             //- Spool
                                         {.F.,Nil},;             //- Imprimir
                                         {.T.,STR0048},;              //- "Confirmar"
                                         {.T.,STR0049},;   //- "Cancelar"
                                         {.F.,Nil},;             //- WalkThrough
                                         {.F.,Nil},;             //- Ambiente
                                         {.F.,Nil},;             //- Mashup
                                         {.F.,Nil},;             //- Help
                                         {.F.,Nil},;             //- Formulário HTML
                                         {.F.,Nil};                   //- ECM
                                   }

FWExecView(STR0034,"VIEWDEF.TECA934A",MODEL_OPERATION_INSERT,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,30,aButtons)

Return

/*/{Protheus.doc} At934ELote
@description      Abre interface de processamento em Lote - Inclusão
@author           matheus.raimundo
@since                  19.04.2017
/*/
Function At934ELote()
Local aButtons    := {  {.F.,Nil},;             //- Copiar
                                         {.F.,Nil},;             //- Recortar
                                         {.F.,Nil},;             //- Colar
                                         {.F.,Nil},;             //- Calculadora
                                         {.F.,Nil},;             //- Spool
                                         {.F.,Nil},;             //- Imprimir
                                         {.T.,STR0048},;              //- "Confirmar"
                                         {.T.,STR0049},;   //- "Cancelar"
                                         {.F.,Nil},;             //- WalkThrough
                                         {.F.,Nil},;             //- Ambiente
                                         {.F.,Nil},;             //- Mashup
                                         {.F.,Nil},;             //- Help
                                         {.F.,Nil},;             //- Formulário HTML
                                         {.F.,Nil};                   //- ECM
                                   }

FWExecView(STR0035,"VIEWDEF.TECA934A",MODEL_OPERATION_INSERT,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,30,aButtons)

Return

/*/{Protheus.doc} At934ClGrd
@description      Limpa os grids 
@author           matheus.raimundo
@since                  02.05.2017
@param                  oMdlGrid
@return           Nil
/*/
Function At934ClGrd(oMdlGrid)
Local nNewLine := 0
Local nX       := 0 
Local aProp := GetPropMdl(oMdlGrid)
Local aSaveRows := FwSaveRows()

If !oMdlGrid:IsEmpty()
      oMdlGrid:SetNoInsertLine(.F.)
      oMdlGrid:SetNoDeleteLine(.F.)
      nNewLine := oMdlGrid:AddLine()
      oMdlGrid:LineShift(1,nNewLine)
      
      For nX := oMdlGrid:Length() To 1 Step -1
            oMdlGrid:GoLine(nX)
            If nX > 1
                  oMdlGrid:DeleteLine(.T.,.T.)
            EndIf 
            
      Next nX
	  oMdlGrid:SetNoDeleteLine(.T.)
EndIf 

RstPropMdl(oMdlGrid,aProp)
FwRestRows( aSaveRows )
      
Return 


//-------------------------------------------------------------------
/*/{Protheus.doc} At934Contr()
Consulta especifica de contratos

@author Matheus Lando Raimundo      

/*/
//------------------------------------------------------------------
Function At934Contr()

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
Local aIndex := {"CN9_NUMERO"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek := {{ STR0052, {{STR0052,"C",TamSx3('CN9_NUMERO')[1],0,"",,}} }} //"Contrato" ## "Contrato"
Local cRet := ""
Local cRecorre := ""


cQry := " SELECT CN9_NUMERO, CN9_REVISA, CN9_DTINIC, CN9_DTFIM, TFJ_CNTREC" 
cQry += " FROM " + RetSqlName("CN9") + " CN9 "
cQry += " INNER JOIN " + RetSqlName("TFJ") + " TFJ "
cQry += " ON TFJ.TFJ_FILIAL = '" +   xFilial('TFJ') + "'"
cQry += " AND TFJ_CONTRT = CN9_NUMERO AND TFJ_CONREV = CN9_REVISA AND TFJ.D_E_L_E_T_ <> '*'"                                                                   

cQry += "  WHERE CN9_FILIAL = '" +   xFilial('CN9') + "'" 
cQry += "  AND CN9.CN9_SITUAC = '05' "
cQry += "   AND CN9.D_E_L_E_T_ <> '*'"
cQry += "   AND TFJ_ANTECI = '1' "       
cQry += "   AND TFJ_STATUS = '1' "       
cQry += "   AND TFJ.D_E_L_E_T_ <> '*'"

cQry += "  Order by CN9_NUMERO "

nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE STR0064 FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL //Contratos
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(STR0065) //"Contratos vigentes"
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cRecorr := (oBrowse:Alias())->TFJ_CNTREC, cRet := (oBrowse:Alias())->CN9_NUMERO,  , lRet := .T., oDlgTela:End()}) //"Confirmar"
oBrowse:AddButton( OemTOAnsi(STR0048), {|| cRecorre := (oBrowse:Alias())->TFJ_CNTREC, cRet := (oBrowse:Alias())->CN9_NUMERO,  lRet := .T., oDlgTela:End()},, 2 ) //"Cancelar"
oBrowse:AddButton( OemTOAnsi(STR0049),  {|| cRecorre := "", cRet := "", oDlgTela:End()} ,, 2 ) //"Cancelar" 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

ADD COLUMN oColumn DATA { ||  CN9_NUMERO } TITLE STR0052 SIZE TamSx3('CN9_NUMERO')[1] OF oBrowse //"Contrato"
ADD COLUMN oColumn DATA { ||  CN9_REVISA } TITLE STR0053 SIZE TamSx3('CN9_REVISA')[1] OF oBrowse  //"Revisão"
ADD COLUMN oColumn DATA { ||  STOD(CN9_DTINIC)} TITLE STR0054 SIZE TamSx3('CN9_DTINIC')[1]  OF oBrowse //"Data inicial"
ADD COLUMN oColumn DATA { ||  STOD(CN9_DTFIM) } TITLE STR0055 SIZE TamSx3('CN9_DTFIM')[1]  OF oBrowse //"Data final"


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
Function At934RetCN()

Return cItem  


