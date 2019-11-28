#INCLUDE "PROTHEUS.CH" 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA930.CH"

#DEFINE _TFLFILIAL	1
#DEFINE _TFLCODIGO 	2
#DEFINE _TFLLOCAL 	3
#DEFINE _TFLDESC 	4
#DEFINE _TFLUSO 	5
#DEFINE _TFLDISP	6
#DEFINE _TFLMOB 	7
#DEFINE _TFLTOTAL	8
#DEFINE _TFLDTINI	9
#DEFINE _TFLDTFIM	10
#DEFINE _TFLCODPAI	11
#DEFINE _TFLPREV 	11
#DEFINE _TFLPLAN	12

#DEFINE _TFIFILIAL 	1
#DEFINE _TFICODIGO 	2
#DEFINE _TFIPRODUT 	3
#DEFINE _TFICODPAI 	4
#DEFINE _TFIUSO 	5
#DEFINE _TFIDISP 	6
#DEFINE _TFIMOB 	7
#DEFINE _TFITOTAL 	8
#DEFINE _TFIPERINI 	9
#DEFINE _TFIPERFIM	10
#DEFINE _TFIDESCON	11
#DEFINE _TFIITCNB	12
#DEFINE _TFIQTDVEN	13
#DEFINE _TFIPREV 	14
#DEFINE _TFITES		14

#DEFINE _TEVFILIAL 	1
#DEFINE _TEVCODLOC 	2
#DEFINE _TEVITEM 	3
#DEFINE _TEVMODCOB 	4
#DEFINE _TEVTOTAL 	5
#DEFINE _TEVCODTFL 	6
#DEFINE _TEVCODTFI 	7
#DEFINE _TEVQTDE 	8
#DEFINE _TEVQTDEAPU	9
#DEFINE _TEVVLRUNI 	10
#DEFINE _TEVQTDORI 	11
#DEFINE _TEVPREV	11

#DEFINE _TW7FILIAL 	1
#DEFINE _TW7TFICOD 	2
#DEFINE _TW7TEVITE 	3
#DEFINE _TW7TPPAI 	4
#DEFINE _TW7TIPOMV 	5
#DEFINE _TW7DESCRI 	6
#DEFINE _TW7VALOR 	7
#DEFINE _TW7MODO 	8
#DEFINE _TW7FLGPED 	9
#DEFINE _TW7_MAX 	9

STATIC lMedExt
STATIC lSrvExt := .F.
STATIC nLenSX8 := 0
STATIC nOpcDA := 1
STATIC nOpcHE := 1   
STATIC _aComptc := {}   //Competencia para utilização no cronograma financeiro
STATIC lTeca934 := IsInCallStack("TECA934") .or. IsInCallStack("TECA934A")


//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA930
Apuração / Medição de atendimentos do contrato
@sample 	TECA930() 
@param		Nenhum
@return	ExpL	Verdadeiro / Falso
@since		01/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function TECA930()

Local oMBrowse

oMBrowse:= FWmBrowse():New() 
oMBrowse:SetAlias("TFV")
oMBrowse:SetDescription(STR0001)   // "Apuração / Medição de Atendimentos"
	
oMBrowse:Activate()
	
Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Define o menu funcional. 
@sample 	MenuDef() 
@param		Nenhum
@return	ExpA Opções da Rotina.
@since		01/11/2013
@author	Serviços         
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function MenuDef()    

Local aRotina := {}

ADD OPTION aRotina TITLE STR0076 ACTION "At930GerMed" OPERATION 3 ACCESS 0 	// "Medir/Apurar Contrato"
ADD OPTION aRotina TITLE STR0148  ACTION "TECR930A"    OPERATION 1 ACCESS 0 	// "Anexo de Fatura"
ADD OPTION aRotina TITLE STR0003 ACTION "At930GerMed" OPERATION 5 ACCESS 0 	// "Estornar"
ADD OPTION aRotina TITLE STR0087 ACTION "VIEWDEF.TECA930" OPERATION 2 ACCESS 0 	// "Visualizar"
	
Return(aRotina)


//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do Model
@sample 	ModelDef() 
@param		Nenhum
@return	ExpO Objeto FwFormModel 
@since		01/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel
Local oStruTFV		:= FWFormStruct( 1, "TFV" )
Local oStruTFW		:= FWFormStruct( 1, "TFW" )							// TFW - Recursos Humanos
Local oStruTFX		:= FWFormStruct( 1, "TFX" )							// TFX - Material de Implantação
Local oStruTFY		:= FWFormStruct( 1, "TFY" )							// TFY - Material de Consumo
Local oStruTFL		:= FWFormStruct( 1, "TFL" )							// TFL - Locação de Equipamentos
Local oStruTFI		:= FWFormStruct( 1, "TFI", {|cCampo| AllTrim(cCampo)$ "TFI_FILIAL#TFI_PRODUT#TFI_COD#TFI_CODPAI#TFI_DESCON#TFI_ITCNB#TFI_QTDVEN#TFI_PERINI#TFI_PERFIM#TFI_TES"} )	// TFI - Locação de Equipamentos (PRODUTOS)
Local oStruTFZ		:= FWFormStruct( 1, "TFZ" )							// TFZ - Locação de Equipamentos (DETALHES APURAÇÃO)
Local oStruZZP		:= FWFormModelStruct():New()
Local oStruTIP		:= FWFormStruct( 1, "TIP" )							// TIP - Detalhe da Apuração/Medição
Local oStruTCV		:= FWFormStruct( 1, "TCV" )							// TCV - Pedidos fora do contrato
Local oStrTFWTW6	:= FWFormStruct( 1, "TW6" )							// TFWTW6 - Recursos Humanos - DESCONTOS
Local oStrTFWTW7 	:= FWFormStruct( 1, "TW7" )																			// TFWTW7 - Recursos Humanos - MULTAS/BONIFICAÇÕES (acréscimos/decréscimos)
Local oStrTFXTW6	:= FWFormStruct( 1, "TW6" )							// TFXTW6 - Material de Implantação - DESCONTOS
Local oStrTFXTW7  	:= FWFormStruct( 1, "TW7" )																			// TFXTW7 - Material de Implantação - MULTAS/BONIFICAÇÕES (acréscimos/decréscimos)
Local oStrTFYTW6	:= FWFormStruct( 1, "TW6" )							// TFYTW6 - Material de Consumo - DESCONTOS
Local oStrTFYTW7  	:= FWFormStruct( 1, "TW7" )																			// TFYTW7 - Material de Consumo - MULTAS/BONIFICAÇÕES (acréscimos/decréscimos)
Local oStrTFITW6	:= FWFormStruct( 1, "TW6" )							// TFITW6 - Locação de Equipamentos - DESCONTOS
Local oStrTFITW7  	:= FWFormStruct( 1, "TW7" )																			// TFITW7 - Locação de Equipamentos - MULTAS/BONIFICAÇÕES (acréscimos/decréscimos)
Local oStruTW8		:= FWFormStruct( 1, "TW8" )
Local aAux			:=	{}
Local bCommit		:= {|oModel| At930Commit(oModel) }
Local bPosValid		:= {|oModel| A930PosVld(oModel) }
Local lOrcPrc		:= SuperGetMv("MV_ORCPRC",,.F.) 
Local bPVlMulDes	:= {|oModelGrid, nLine, cAction, cField, xValue, xOldValue| AT930AtuTot(oModelGrid, nLine, cAction, cField, xValue, xOldValue) }
Local bVLnTFITW6	:= {|| A930VLnTFITW6()}
Local oStrTWB		:= FWFormStruct(1,"TWB")
Local bPreLinTFZ	:= {|oModelGrid, nLine, cAction, cField| PreLinTFZ(oModelGrid, nLine, cAction, cField) }
Local cRevCtr		:= ""
Local cIsGsMt		:= ""
//Faturamento antecipado
Local oStruABX		:= FWFormStruct( 1, "ABX" )							// ABX - Apuração fat antecipado
Local lPermExce		:= ( GetMv("MV_CNBTEXC",.F.,"N")=="S" )

If !lTeca934
	Pergunte("TEC930",.F.)
Else
	Pergunte("TEC934",.F.)
EndIf

cRevCtr			:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
cIsGsMt			:= Posicione( "TFJ", 5, xFilial("TFJ") + MV_PAR01 + cRevCtr, "TFJ_ISGSMT")

nLenSX8 := GetSX8Len()

oStruZZP:AddTable("ZZP",{},STR0006)	//"Grupo de faturamento"

If !INCLUI
	lSrvExt	:= IIF(Empty(TFV->TFV_ORCSRV), .F. , .T. )
EndIf

aAux := FwStruTrigger( "TFW_VLRMED", "TFW_VLRMED", "At930TrgRH( 'TFWDETAIL', 'TFW_VLRMED', 'ZZPDETAIL', 'ZZP_VLRTOT', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFW_VLREXT", "TFW_VLREXT", "At930TrgRH( 'TFWDETAIL', 'TFW_VLREXT', 'ZZPDETAIL', 'ZZP_VLREXT', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFW_TOTMUL", "TFW_TOTMUL", "At930TrgRH( 'TFWDETAIL', 'TFW_TOTMUL', 'ZZPDETAIL', 'ZZP_TOTMUL', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFW_TOTBON", "TFW_TOTBON", "At930TrgRH( 'TFWDETAIL', 'TFW_TOTBON', 'ZZPDETAIL', 'ZZP_TOTBON', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFW_TOTDES", "TFW_TOTDES", "At930TrgRH( 'TFWDETAIL', 'TFW_TOTDES', 'ZZPDETAIL', 'ZZP_TOTDES', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFW_VLMTMI", "TFW_VLMTMI", "At930TrgRH( 'TFWDETAIL', 'TFW_VLMTMI', 'ZZPDETAIL', 'ZZP_VLRTOT', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFW_VLMTMC", "TFW_VLMTMC", "At930TrgRH( 'TFWDETAIL', 'TFW_VLMTMC', 'ZZPDETAIL', 'ZZP_VLRTOT', 1 )", .F. )
oStruTFW:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFX_VLRMED", "TFX_VLRMED", "At930TrgGer( 'TFXDETAIL', 'TFX_VLRMED', 'ZZPDETAIL', 'ZZP_VLRTOT', 2 )", .F. )
oStruTFX:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFX_TOTMUL", "TFX_TOTMUL", "At930TrgGer( 'TFXDETAIL', 'TFX_TOTMUL', 'ZZPDETAIL', 'ZZP_TOTMUL', 2 )", .F. )
oStruTFX:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFX_TOTBON", "TFX_TOTBON", "At930TrgGer( 'TFXDETAIL', 'TFX_TOTBON', 'ZZPDETAIL', 'ZZP_TOTBON', 2 )", .F. )
oStruTFX:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFX_TOTDES", "TFX_TOTDES", "At930TrgGer( 'TFXDETAIL', 'TFX_TOTDES', 'ZZPDETAIL', 'ZZP_TOTDES', 2 )", .F. )
oStruTFX:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFY_VLRMED", "TFY_VLRMED", "At930TrgGer( 'TFYDETAIL', 'TFY_VLRMED', 'ZZPDETAIL', 'ZZP_VLRTOT', 3 )", .F. )
oStruTFY:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFY_TOTMUL", "TFY_TOTMUL", "At930TrgGer( 'TFYDETAIL', 'TFY_TOTMUL', 'ZZPDETAIL', 'ZZP_TOTMUL', 3 )", .F. )
oStruTFY:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFY_TOTBON", "TFY_TOTBON", "At930TrgGer( 'TFYDETAIL', 'TFY_TOTBON', 'ZZPDETAIL', 'ZZP_TOTBON', 3 )", .F. )
oStruTFY:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFY_TOTDES", "TFY_TOTDES", "At930TrgGer( 'TFYDETAIL', 'TFY_TOTDES', 'ZZPDETAIL', 'ZZP_TOTDES', 3 )", .F. )
oStruTFY:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFI_TOTMUL", "TFI_TOTMUL", "At930TrgGer( 'TFIPRODUT', 'TFI_TOTMUL', 'ZZPDETAIL', 'ZZP_TOTMUL', 4 )", .F. )
oStruTFI:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFI_TOTBON", "TFI_TOTBON", "At930TrgGer( 'TFIPRODUT', 'TFI_TOTBON', 'ZZPDETAIL', 'ZZP_TOTBON', 4 )", .F. )
oStruTFI:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger( "TFI_TOTDES", "TFI_TOTDES", "At930TrgGer( 'TFIPRODUT', 'TFI_TOTDES', 'ZZPDETAIL', 'ZZP_TOTDES', 4 )", .F. )
oStruTFI:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])

aAux := FwStruTrigger("TFZ_QTDAPU","TFZ_QTDAPU","At930GatQdt()",.F.,Nil,Nil,Nil) //Gatilho do material de consumo, preenche produto, descrição do produto e saldo
oStruTFZ:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_CODABS","TWB_DESABS","Posicione('ABS',1,xFilial('ABS')+FwFldGet('TWB_CODABS'),'ABS_DESCRI')",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

// TWB_TOTMED - gatilhos para preencher o campo com o totalizador da linha
aAux := FwStruTrigger("TWB_IMPMED","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRRH","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRMI","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRMC","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRLE","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRMUL","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRBON","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TWB_VLRDES","TWB_TOTMED","At930TotRL()",.F.,Nil,Nil,Nil)
oStrTWB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

// At930TrgLoc( cMdlCalc, cCpoTot, cMdlCDom, cCpoCDOM, cCpoCodTFL )
// adiciona os gatilhos para montar o resumo dos valores por local 
aAux := FwStruTrigger("TFW_VLRTOT","TFW_VLRTOT","At930TrgLoc( 'TFWDETAIL', 'TFW_VLRMED', 'TWBDETAIL', 'TWB_VLRRH', 'TFW_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFW:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFX_VLRMED","TFX_VLRMED","At930TrgLoc( 'TFXDETAIL', 'TFX_VLRMED', 'TWBDETAIL', 'TWB_VLRMI', 'TFX_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFY_VLRMED","TFY_VLRMED","At930TrgLoc( 'TFYDETAIL', 'TFY_VLRMED', 'TWBDETAIL', 'TWB_VLRMC', 'TFY_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFL_VALTOT","TFL_VALTOT","At930TrgLoc( 'TFLDETAIL', 'TFL_VLRMED', 'TWBDETAIL', 'TWB_VLRLE', 'TFL_CODIGO' )",.F.,Nil,Nil,Nil)
oStruTFL:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//At930TrgMBD( cIdMdlOrig, nTipo, cCpoCodTFL )
// adiciona os gatilhos para somar os conteúdos de multas, bonificações e descontos
aAux := FwStruTrigger("TFW_TOTMUL","TFW_TOTMUL","At930TrgMBD( 'TFWDETAIL', 1, 'TFW_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFW:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFW_TOTBON","TFW_TOTBON","At930TrgMBD( 'TFWDETAIL', 2, 'TFW_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFW:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFW_TOTDES","TFW_TOTDES","At930TrgMBD( 'TFWDETAIL', 3, 'TFW_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFW:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFX_TOTMUL","TFX_TOTMUL","At930TrgMBD( 'TFXDETAIL', 1, 'TFX_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFX_TOTBON","TFX_TOTBON","At930TrgMBD( 'TFXDETAIL', 2, 'TFX_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFX_TOTDES","TFX_TOTDES","At930TrgMBD( 'TFXDETAIL', 3, 'TFX_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFX:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFY_TOTMUL","TFY_TOTMUL","At930TrgMBD( 'TFYDETAIL', 1, 'TFY_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFY_TOTBON","TFY_TOTBON","At930TrgMBD( 'TFYDETAIL', 2, 'TFY_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFY_TOTDES","TFY_TOTDES","At930TrgMBD( 'TFYDETAIL', 3, 'TFY_CODTFL' )",.F.,Nil,Nil,Nil)
oStruTFY:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("TFI_TOTMUL","TFI_TOTMUL","At930TrgMBD( 'TFIPRODUT', 1, 'TFI_CODPAI' )",.F.,Nil,Nil,Nil)
oStruTFI:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFI_TOTBON","TFI_TOTBON","At930TrgMBD( 'TFIPRODUT', 2, 'TFI_CODPAI' )",.F.,Nil,Nil,Nil)
oStruTFI:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
aAux := FwStruTrigger("TFI_TOTDES","TFI_TOTDES","At930TrgMBD( 'TFIPRODUT', 3, 'TFI_CODPAI' )",.F.,Nil,Nil,Nil)
oStruTFI:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

oStrTWB:SetProperty("TWB_CODTFV", MODEL_FIELD_OBRIGAT, .F.)

//========================================
// TFW - Recursos Humanos
//========================================
oStruTFW:AddField(	STR0004,;								// [01] C Titulo do campo # Local
					  	STR0004,;								// [02] C ToolTip do campo # Local
     					"TFW_LOCAL",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("ABS_LOCAL")[1],;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(1,"TFW_LOCAL")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFW:AddField(	STR0005,;								// [01] C Titulo do campo # Descrição
					  	STR0005,;								// [02] C ToolTip do campo # Descrição
     					"TFW_DESCRI",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			50,;									// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(1,"TFW_DESCRI")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFW:AddField(	STR0063,;								// [01] C Titulo do campo # Total apurado
					  	STR0063,;								// [02] C ToolTip do campo # Total apurado
     					"TFW_TOTHOR",;						// [03] C identificador (ID) do Field
         				"N",;									// [04] C Tipo do campo
            			16,;									// [05] N Tamanho do campo
              			2,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(1,"TFW_TOTHOR")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFW:AddField(	STR0055,;								// [01] C Titulo do campo # Total
					  	STR0055,;								// [02] C ToolTip do campo # Total
     					"TFW_VLRTOT",;						// [03] C identificador (ID) do Field
         				"N",;									// [04] C Tipo do campo
            			16,;									// [05] N Tamanho do campo
              			2,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(1,"TFW_VLRTOT")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual                    	

oStruTFW:AddField(	STR0038,;								// [01] C Titulo do campo # Produto
					  	STR0038,;								// [02] C ToolTip do campo # Produto
     					"TFW_PRODUT",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("B1_COD")[1],;				// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(1,"TFW_PRODUT")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFW:AddField(	STR0064,;								// [01] C Titulo do campo # Desc. Produto
					  	STR0064,;								// [02] C ToolTip do campo # Desc. Produto
     					"TFW_DSCPRO",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("B1_DESC")[1],;				// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(1,"TFW_DSCPRO")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual                    	
                   	
oStruTFW:AddField(	STR0105,;								// [01] C Titulo do campo # "Planilha" 
					  	STR0105,;								// [02] C ToolTip do campo # "Planilha"
     					"TFW_PLAN",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("CNA_NUMERO")[1],;			// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil,;									// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual

oStruTFW:SetProperty("TFW_VLRAPU", MODEL_FIELD_OBRIGAT, .F.)
oStruTFW:SetProperty("TFW_APURAC", MODEL_FIELD_OBRIGAT, .F.)
oStruTFW:SetProperty("TFW_NUMMED", MODEL_FIELD_OBRIGAT, .F.)
oStruTFW:SetProperty("TFW_ITMED",  MODEL_FIELD_OBRIGAT, .F.)
oStruTFW:SetProperty("TFW_PLAN",   MODEL_FIELD_OBRIGAT, .F.)
oStruTFW:SetProperty("TFW_VLRCON", MODEL_FIELD_OBRIGAT, .F.)

//========================================
// TFX - Material de Implantação
//========================================
oStruTFX:AddField(	STR0004,;								// [01] C Titulo do campo # Local
					  	STR0004,;								// [02] C ToolTip do campo # Local
     					"TFX_LOCAL",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			8,;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(2,"TFX_LOCAL")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFX:AddField(	STR0005,;								// [01] C Titulo do campo # Descrição
					  	STR0005,;								// [02] C ToolTip do campo # Descrição
     					"TFX_DESCRI",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			50,;									// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
	                  	Nil,;									// [09] A Lista de valores permitido do campo
	                   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(2,"TFX_DESCRI")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFX:AddField(	STR0038,;								// [01] C Titulo do campo # Produto
					  	STR0038,;								// [02] C ToolTip do campo # Produto
     					"TFX_PRODUT",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("B1_COD")[1],;				// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                	  	Nil,;									// [09] A Lista de valores permitido do campo
                	   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(2,"TFW_PRODUT")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFX:AddField(	STR0064,;								// [01] C Titulo do campo # Desc. Produto
					  	STR0064,;								// [02] C ToolTip do campo # Desc. Produto
     					"TFX_DSCPRO",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("B1_DESC")[1],;				// [05] N Tamanho do campo
              			0 ,;									// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                	  	Nil,;									// [09] A Lista de valores permitido do campo
                 	  	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(2,"TFX_DSCPRO")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
                    	
oStruTFX:AddField(	STR0105,;								// [01] C Titulo do campo # "Planilha"
					  	STR0105,;								// [02] C ToolTip do campo # "Planilha"
     					"TFX_PLAN",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("CNA_NUMERO")[1],;			// [05] N Tamanho do campo
              			0 ,;									// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                 	 	Nil,;									// [09] A Lista de valores permitido do campo
                  	 	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                 	   	Nil,;									// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual

oStruTFX:SetProperty("TFX_VLRAPU",MODEL_FIELD_OBRIGAT, .F.)
oStruTFX:SetProperty("TFX_VLRMED",MODEL_FIELD_OBRIGAT, .F.)
oStruTFX:SetProperty("TFX_APURAC",MODEL_FIELD_OBRIGAT, .F.)
oStruTFX:SetProperty("TFX_NUMMED",MODEL_FIELD_OBRIGAT, .F.)
oStruTFX:SetProperty("TFX_ITMED", MODEL_FIELD_OBRIGAT, .F.)
oStruTFX:SetProperty("TFX_PLAN", MODEL_FIELD_OBRIGAT, .F.)
If lOrcPrc
	oStruTFX:SetProperty("TFX_CODTFF", MODEL_FIELD_OBRIGAT, .F.)
EndIf

//========================================
// TFY - Material de Consumo
//========================================
oStruTFY:AddField(	STR0004,;								// [01] C Titulo do campo # Local
					  	STR0004,;								// [02] C ToolTip do campo # Local
     					"TFY_LOCAL",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			8,;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                  	 	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(3,"TFY_LOCAL")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFY:AddField(	STR0005,;								// [01] C Titulo do campo # Descrição
					  	STR0005,;								// [02] C ToolTip do campo # Descrição
     					"TFY_DESCRI",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			50,;									// [05] N Tamanho do campo
              			0 ,;									// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(3,"TFY_DESCRI")},; // [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFY:AddField(	STR0038,;								// [01] C Titulo do campo # Produto
					  	STR0038,;								// [02] C ToolTip do campo # Produto
     					"TFY_PRODUT",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("B1_COD")[1],;				// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(3,"TFY_PRODUT")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStruTFY:AddField(	STR0064,;								// [01] C Titulo do campo # Desc. Produto
					  	STR0064,;								// [02] C ToolTip do campo # Desc. Produto
     					"TFY_DSCPRO",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("B1_DESC")[1],;				// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(3,"TFY_DSCPRO")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual                    	

oStruTFY:AddField(	STR0105,;								// [01] C Titulo do campo # "Planilha"
					  	STR0105,;								// [02] C ToolTip do campo # "Planilha"
     					"TFY_PLAN",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			TamSX3("CNA_NUMERO")[1],;			// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil,;									// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual	                    	                    	

oStruTFY:SetProperty("TFY_VLRAPU", MODEL_FIELD_OBRIGAT, .F.)
oStruTFY:SetProperty("TFY_APURAC", MODEL_FIELD_OBRIGAT, .F.)
oStruTFY:SetProperty("TFY_NUMMED", MODEL_FIELD_OBRIGAT, .F.)
oStruTFY:SetProperty("TFY_ITMED",  MODEL_FIELD_OBRIGAT, .F.)
oStruTFY:SetProperty("TFY_PLAN",   MODEL_FIELD_OBRIGAT, .F.)
If lOrcPrc
	oStruTFY:SetProperty("TFY_CODTFF", MODEL_FIELD_OBRIGAT, .F.)
EndIf

//========================================
// TFL - Locais de Prestação do Serviço
//========================================
oStruTFL:SetProperty("*", MODEL_FIELD_VALID, {||.T.})
oStruTFL:SetProperty("*", MODEL_FIELD_OBRIGAT, .F. )

oStruTFL:AddField(	STR0055,;								// [01] C Titulo do campo # "Total"
						STR0055,;								// [02] C ToolTip do campo # "Total"
						'TFL_VALTOT',;						// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						/* */,;								// [07] B Code-block de validação do campo
						/*bValid*/,;							// [08] B Code-block de validação When do campo
						/*bWhen*/,;							// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFL_VALTOT")},;	// [11] B Code-block de inicializacao do campo
						/*lKey*/,;								// [12] L Indica se trata de um campo chave
						/*lNoUpd*/,;							// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T./*lVirtual*/,;						// [14] L Indica se o campo é virtual
						/*cValid*/ )

oStruTFL:AddField(	STR0056,;								// [01] C Titulo do campo # "Tot.Disp"
						STR0057,;								// [02] C ToolTip do campo # "Tot.Disp"
						'TFL_DISP',;							// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						/* */,;								// [07] B Code-block de validação do campo
						/*bValid*/,;							// [08] B Code-block de validação When do campo
						/*bWhen*/,;							// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFL_DISP")},;	// [11] B Code-block de inicializacao do campo
						/*lKey*/,;								// [12] L Indica se trata de um campo chave
						/*lNoUpd*/,;							// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T./*lVirtual*/,;						// [14] L Indica se o campo é virtual
						/*cValid*/ )

oStruTFL:AddField(	STR0058,;								// [01] C Titulo do campo # "Tot.Uso"
						STR0058,;								// [02] C ToolTip do campo # "Tot.Uso"
						'TFL_USO',;							// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						/* */,;								// [07] B Code-block de validação do campo
						/*bValid*/,;							// [08] B Code-block de validação When do campo
						/*bWhen*/,;							// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFL_USO")},;		// [11] B Code-block de inicializacao do campo
						/*lKey*/,;								// [12] L Indica se trata de um campo chave
						/*lNoUpd*/,;							// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T./*lVirtual*/,;						// [14] L Indica se o campo é virtual
						/*cValid*/ )

oStruTFL:AddField(	STR0059,;								// [01] C Titulo do campo # "Tot.Mobi."
						STR0060,;								// [02] C ToolTip do campo # "Tot.Mobilização"
						'TFL_MOBILI',;						// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						/* */,;								// [07] B Code-block de validação do campo
						/*bValid*/,;							// [08] B Code-block de validação When do campo
						/*bWhen*/,;							// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFL_MOBILI")},;	// [11] B Code-block de inicializacao do campo
						/*lKey*/,;								// [12] L Indica se trata de um campo chave
						/*lNoUpd*/,;							// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T./*lVirtual*/,;						// [14] L Indica se o campo é virtual
						/*cValid*/ )

oStruTFL:SetProperty("TFL_DESLOC", MODEL_FIELD_INIT, {|| If( !Inclui, Posicione("ABS",1,xFilial("ABS")+TFL->TFL_LOCAL,"ABS_DESCRI"), "")})

//========================================
// TFI - Locação de Equipamentos 
//========================================
oStruTFI:SetProperty("*", MODEL_FIELD_VALID, {||.T.})
oStruTFI:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)
oStruTFI:AddField(	STR0056,;								// [01] C Titulo do campo # "Tot.Disp"
						STR0057,;								// [02] C ToolTip do campo # "Tot.Disp"
						'TFI_DISP',;							// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFI_DISP")},;	// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

oStruTFI:AddField(	STR0058,;								// [01] C Titulo do campo # "Tot.Uso"
						STR0058,;								// [02] C ToolTip do campo # "Tot.Uso"
						'TFI_USO',;							// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFI_USO")},;		// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

oStruTFI:AddField(	STR0059,;								// [01] C Titulo do campo # "Tot.Mobi."
						STR0060,;								// [02] C ToolTip do campo # "Tot.Mobilização"
						'TFI_MOBILI',;						// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFI_MOBILI")},;	// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

oStruTFI:AddField(	STR0093,;								// [01] C Titulo do campo # "Multas"
						STR0093,;								// [02] C ToolTip do campo # "Multas"
						'TFI_TOTMUL',;						// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						16,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						Nil,;									// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

oStruTFI:AddField(	STR0094,;								// [01] C Titulo do campo # "Bonificações"
						STR0094,;								// [02] C ToolTip do campo # "Bonificações"
						'TFI_TOTBON',;						// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						16,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						Nil,;									// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

oStruTFI:AddField(	STR0092,;								// [01] C Titulo do campo # "Descontos
						STR0092,;								// [02] C ToolTip do campo # "Descontos"
						'TFI_TOTDES',;						// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						16,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						Nil,;									// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

//========================================
// TFZ - Locação de Equipamentos (DETALHES APURAÇÃO)
//========================================
oStruTFZ:AddField(	STR0004,;								// [01] C Titulo do campo # Local
					  	STR0004,;								// [02] C ToolTip do campo # Local
     					"TFZ_LOCAL",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			8,;										// [05] N Tamanho do campo
              		0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  	Nil,;									// [09] A Lista de valores permitido do campo
                   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(4,"TFZ_LOCAL")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual

oStruTFZ:AddField(	STR0005,;								// [01] C Titulo do campo # Descrição
					  	STR0005,;								// [02] C ToolTip do campo # Descrição
     					"TFZ_DESCRI",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			50,;									// [05] N Tamanho do campo
              		0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  	Nil,;									// [09] A Lista de valores permitido do campo
                   	Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| At930IniEst(4,"TFZ_DESCRI")},;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual

oStruTFZ:AddField(	STR0061,;								// [01] C Titulo do campo # Quant.Previs
						STR0061,;								// [02] C ToolTip do campo # Quant.Previs
						'TFZ_QTDE',;							// [03] C identificador (ID) do Field
						'N',;									// [04] C Tipo do campo
						11,;									// [05] N Tamanho do campo
						2,;										// [06] N Decimal do campo
						Nil,;									// [07] B Code-block de validação do campo
						Nil,;									// [08] B Code-block de validação When do campo
						Nil,;									// [09] A Lista de valores permitido do campo
						.F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
						{|| At930IniEst(4,"TFZ_QTDE")},;	// [11] B Code-block de inicializacao do campo
						Nil,;									// [12] L Indica se trata de um campo chave
						Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T.,;									// [14] L Indica se o campo é virtual
						/*cValid*/)

oStruTFZ:SetProperty("TFZ_QTDAPU", MODEL_FIELD_OBRIGAT, .F.)
oStruTFZ:SetProperty("TFZ_TOTAL",  MODEL_FIELD_OBRIGAT, .F.)
oStruTFZ:SetProperty("TFZ_APURAC", MODEL_FIELD_OBRIGAT, .F.)
oStruTFZ:SetProperty("TFZ_NUMMED", MODEL_FIELD_OBRIGAT, .F.)
oStruTFZ:SetProperty("TFZ_ITMED",  MODEL_FIELD_OBRIGAT, .F.)

//========================================
// TW6 - Descontos na apuração
//========================================
oStrTFWTW6:SetProperty("TW6_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFWTW6:SetProperty("TW6_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFWTW6:SetProperty("TW6_CODPAI", MODEL_FIELD_OBRIGAT, .F.)

oStrTFXTW6:SetProperty("TW6_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFXTW6:SetProperty("TW6_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFXTW6:SetProperty("TW6_CODPAI", MODEL_FIELD_OBRIGAT, .F.)

oStrTFYTW6:SetProperty("TW6_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFYTW6:SetProperty("TW6_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFYTW6:SetProperty("TW6_CODPAI", MODEL_FIELD_OBRIGAT, .F.)

oStrTFITW6:SetProperty("TW6_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFITW6:SetProperty("TW6_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFITW6:SetProperty("TW6_CODPAI", MODEL_FIELD_OBRIGAT, .F.)

//==================================================================
// TW7 - Acréscimo / Decréscimo na apuração ( Multas / Bonificações)
//==================================================================
oStrTFWTW7:SetProperty("TW7_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFWTW7:SetProperty("TW7_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFWTW7:SetProperty("TW7_CODPAI", MODEL_FIELD_OBRIGAT, .F.)
oStrTFWTW7:SetProperty("TW7_CODMOV", MODEL_FIELD_OBRIGAT, .F.)
oStrTFWTW7:SetProperty("TW7_MODO" 	,MODEL_FIELD_WHEN, {||.F.} )

oStrTFXTW7:SetProperty("TW7_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFXTW7:SetProperty("TW7_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFXTW7:SetProperty("TW7_CODPAI", MODEL_FIELD_OBRIGAT, .F.)
oStrTFXTW7:SetProperty("TW7_CODMOV", MODEL_FIELD_OBRIGAT, .F.)
oStrTFXTW7:SetProperty("TW7_MODO" 	,MODEL_FIELD_WHEN, {||.F.} )

oStrTFYTW7:SetProperty("TW7_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFYTW7:SetProperty("TW7_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFYTW7:SetProperty("TW7_CODPAI", MODEL_FIELD_OBRIGAT, .F.)
oStrTFYTW7:SetProperty("TW7_CODMOV", MODEL_FIELD_OBRIGAT, .F.)
oStrTFYTW7:SetProperty("TW7_MODO" 	,MODEL_FIELD_WHEN, {||.F.} )


oStrTFITW7:SetProperty("TW7_CODIGO", MODEL_FIELD_OBRIGAT, .F.)
oStrTFITW7:SetProperty("TW7_TPPAI",  MODEL_FIELD_OBRIGAT, .F.)
oStrTFITW7:SetProperty("TW7_CODPAI", MODEL_FIELD_OBRIGAT, .F.)
oStrTFITW7:SetProperty("TW7_CODMOV", MODEL_FIELD_OBRIGAT, .F.)
oStrTFITW7:SetProperty("TW7_MODO" 	,MODEL_FIELD_WHEN, {||.F.} )


//========================================
// Outras configurações
//========================================
oStruTIP:SetProperty("TIP_ITAPUR", MODEL_FIELD_OBRIGAT, .F.)

oStruTCV:SetProperty("TCV_NUMAPU", MODEL_FIELD_OBRIGAT, .F.)

If lMedExt .OR. lSrvExt
	oStruTFV:SetProperty("TFV_HREXTR",MODEL_FIELD_OBRIGAT, .F.)
Else
	If lPermExce
		oStruTFV:SetProperty("TFV_HREXTR", MODEL_FIELD_INIT, {|| "2"})
	Else
		oStruTFV:SetProperty("TFV_HREXTR", MODEL_FIELD_INIT, {|| "1"})
	EndIf
EndIf

If lSrvExt
	oStruTFV:SetProperty("TFV_CONTRT",MODEL_FIELD_OBRIGAT, .F.)
EndIf

oStruTW8:SetProperty("TW8_OK", MODEL_FIELD_VALID, {||At930VldOs()})

oStruTW8:AddField(STR0100,;								// [01] C Titulo do campo # "Código"
                  STR0101,;								// [02] C ToolTip do campo # "Código de desconto"
                  'TW8_CODIGO',;						// [03] C identificador (ID) do Field
                  'C',;									// [04] C Tipo do campo
                  20,;									// [05] N Tamanho do campo
                  Nil,;									// [06] N Decimal do campo
                  Nil,;									// [07] B Code-block de validação do campo
                  Nil,;									// [08] B Code-block de validação When do campo
                  Nil,;									// [09] A Lista de valores permitido do campo
                  .F.,;									// [10] L Indica se o campo tem preenchimento obrigatório
                  Nil,;									// [11] B Code-block de inicializacao do campo
                  Nil,;									// [12] L Indica se trata de um campo chave
                  Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                  .T.,;									// [14] L Indica se o campo é virtual
                  Nil)

// Realiza a criação da estrutura com os campos que receberão as informações dos grupos
LoadStruZZP( oStruZZP )

If lTeca934
	
oStruABX:AddField(	STR0005,;								// [01] C Titulo do campo # Descrição
					  	STR0005,;								// [02] C ToolTip do campo # Descrição
     					"ABX_DESCRI",;						// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			50,;									// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	{|| Posicione("ABS",1,xFilial("ABS")+ABX->ABX_LOCAL,"ABS_DESCRI")},;		// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
	oStruABX:SetProperty("ABX_MESANO", MODEL_FIELD_OBRIGAT, .F.)
EndIf
// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TECA930",/*bPreValid*/,bPosValid, bCommit )
oModel:AddFields("TFVMASTER",/*cOwner*/,oStruTFV)

// Cria a lista de grupos de faturamento
oModel:AddGrid( "ZZPDETAIL", "TFVMASTER", oStruZZP,,,,,{|| At930LoadZZP()} )

// Janela Locacao de equipamentos
oModel:AddGrid("TFWDETAIL","TFVMASTER",oStruTFW)
oModel:SetRelation("TFWDETAIL",{{"TFW_FILIAL","xFilial('TFW')"},{"TFW_APURAC" ,"TFV_CODIGO" }},TFW->(IndexKey(1)))

// Detalhes da apuracao/medicao para a gravação
oModel:AddGrid("TIPDETAIL","TFVMASTER",oStruTIP)
oModel:SetRelation("TIPDETAIL",{{"TIP_FILIAL","xFilial('TIP')"},{"TIP_ITAPUR" ,"TFV_CODIGO" }},TIP->(IndexKey(5)))

// Pedidos fora do contrato
oModel:AddGrid("TCVDETAIL","TFVMASTER",oStruTCV)
oModel:SetRelation("TCVDETAIL",{{"TCV_FILIAL","xFilial('TCV')"},{"TCV_NUMAPU" ,"TFV_CODIGO" }},TCV->(IndexKey(1)))

oModel:AddGrid("TFXDETAIL","TFVMASTER",oStruTFX)
oModel:SetRelation("TFXDETAIL",{{"TFX_FILIAL","xFilial('TFX')"},{"TFX_APURAC" ,"TFV_CODIGO" }},TFX->(IndexKey(1)))

oModel:AddGrid("TFYDETAIL","TFVMASTER",oStruTFY)
oModel:SetRelation("TFYDETAIL",{{"TFY_FILIAL","xFilial('TFY')"},{"TFY_APURAC" ,"TFV_CODIGO" }},TFY->(IndexKey(1)))

// Apuração faturamento antecipado
If lTeca934
	oModel:AddGrid("ABXDETAIL","TFVMASTER",oStruABX)
	oModel:SetRelation("ABXDETAIL",{{"ABX_FILIAL","xFilial('ABX')"},{"ABX_CODTFV" ,"TFV_CODIGO" }},ABX->(IndexKey(4)))
EndIf	
oModel:AddGrid("TFLDETAIL","TFVMASTER",oStruTFL)

If lSrvExt
	If oModel:GetOperation() == MODEL_OPERATION_VIEW
		oModel:SetRelation("TFLDETAIL",{{"TFL_FILIAL","xFilial('TFL')"},{"TFL_CODPAI" ,"TFV_ORCSRV" }},TFL->(IndexKey(4)))
	Else
		oModel:SetRelation("TFLDETAIL",{{"TFL_FILIAL","xFilial('TFL')"},{"TFL_CODPAI" ,"MV_PAR05" }},TFL->(IndexKey(4)))
	EndIf
Else
oModel:SetRelation("TFLDETAIL",{{"TFL_FILIAL","xFilial('TFL')"},{"TFL_CONTRT" ,"TFV_CONTRT" },{"TFL_CONREV" ,"TFV_REVISA" }},TFL->(IndexKey(4)))
Endif

oModel:AddGrid("TFIPRODUT","TFLDETAIL",oStruTFI)
oModel:SetRelation("TFIPRODUT",{{"TFI_FILIAL","xFilial('TFI')"},{"TFI_CODPAI" ,"TFL_CODIGO" }},TFI->(IndexKey(3)))

oModel:AddGrid("TFZDETAIL","TFIPRODUT",oStruTFZ, bPreLinTFZ)
oModel:SetRelation("TFZDETAIL",{{"TFZ_FILIAL","xFilial('TFZ')"},{"TFZ_APURAC" ,"TFV_CODIGO" }, {"TFZ_CODTFI" ,"TFI_COD" }},TFZ->(IndexKey(1)))

oModel:AddGrid("TFWTW6DETAIL","TFWDETAIL",oStrTFWTW6,bPVlMulDes)
oModel:SetRelation("TFWTW6DETAIL",{{"TW6_FILIAL","xFilial('TW6')"},{"TW6_TPPAI","'RH'"},{"TW6_CODPAI","TFW_CODIGO"}},TW6->(IndexKey(1)))

oModel:AddGrid("TFWTW7DETAIL","TFWDETAIL",oStrTFWTW7,bPVlMulDes)
oModel:SetRelation("TFWTW7DETAIL",{{"TW7_FILIAL","xFilial('TW7')"},{"TW7_TPPAI","'RH'"},{"TW7_CODPAI","TFW_CODIGO"}},TW7->(IndexKey(1)))

oModel:AddGrid("TFXTW6DETAIL","TFXDETAIL",oStrTFWTW6,bPVlMulDes)
oModel:SetRelation("TFXTW6DETAIL",{{"TW6_FILIAL","xFilial('TW6')"},{"TW6_TPPAI","'MI'"},{"TW6_CODPAI","TFX_CODIGO"}},TW6->(IndexKey(1)))

oModel:AddGrid("TFXTW7DETAIL","TFXDETAIL",oStrTFWTW7,bPVlMulDes)
oModel:SetRelation("TFXTW7DETAIL",{{"TW7_FILIAL","xFilial('TW7')"},{"TW7_TPPAI","'MI'"},{"TW7_CODPAI","TFX_CODIGO"}},TW7->(IndexKey(1)))

oModel:AddGrid("TFYTW6DETAIL","TFYDETAIL",oStrTFWTW6,bPVlMulDes)
oModel:SetRelation("TFYTW6DETAIL",{{"TW6_FILIAL","xFilial('TW6')"},{"TW6_TPPAI","'MC'"},{"TW6_CODPAI","TFX_CODIGO"}},TW6->(IndexKey(1)))

oModel:AddGrid("TFYTW7DETAIL","TFYDETAIL",oStrTFWTW7,bPVlMulDes)
oModel:SetRelation("TFYTW7DETAIL",{{"TW7_FILIAL","xFilial('TW7')"},{"TW7_TPPAI","'MC'"},{"TW7_CODPAI","TFY_CODIGO"}},TW7->(IndexKey(1)))

oModel:AddGrid("TFITW6DETAIL","TFIPRODUT",oStrTFWTW6,bPVlMulDes,bVLnTFITW6)
oModel:SetRelation("TFITW6DETAIL",{{"TW6_FILIAL","xFilial('TW6')"},{"TW6_TPPAI","'LE'"},{"TW6_CODPAI","TFI_COD"}},TW6->(IndexKey(1)))

oModel:AddGrid("TFITW7DETAIL","TFIPRODUT",oStrTFWTW7,bPVlMulDes)
oModel:SetRelation("TFITW7DETAIL",{{"TW7_FILIAL","xFilial('TW7')"},{"TW7_TPPAI","'LE'"},{"TW7_CODPAI","TFI_COD"}},TW7->(IndexKey(1)))

oModel:AddGrid("TW8DETAIL","TFIPRODUT",oStruTW8)
oModel:SetRelation("TW8DETAIL",{{"TW8_FILIAL","xFilial('TW8')"},{"TW8_CODTFI","TFI_COD"}},TW8->(IndexKey(1)))
oModel:GetModel("TW8DETAIL"):SetOptional(.T.)		// TW8 - Desconto por OS
oModel:GetModel('TW8DETAIL'):SetNoInsertLine(.T.)
oModel:GetModel('TW8DETAIL'):SetNoDeleteLine(.T.)

oModel:AddGrid("TWBDETAIL","TFVMASTER", oStrTWB ) // TWB - Resumo por local
oModel:SetRelation("TWBDETAIL",{{"TWB_FILIAL","xFilial('TWB')"},{"TWB_CODTFV","TFV_CODIGO"}},TWB->(IndexKey(1)))
oModel:GetModel("TWBDETAIL"):SetOptional(.T.)
oModel:GetModel('TWBDETAIL'):SetNoInsertLine(.T.)
oModel:GetModel('TWBDETAIL'):SetNoDeleteLine(.T.)

oModel:GetModel( "ZZPDETAIL" ):SetDescription( STR0006 ) // "Grupo de faturamento"

oModel:GetModel("TCVDETAIL"):SetOptional(.T.)
oModel:GetModel("TIPDETAIL"):SetOptional(.T.)
oModel:GetModel("TFWDETAIL"):SetOptional(.T.)		// TFW - Recursos Humanos
oModel:GetModel("TFXDETAIL"):SetOptional(.T.)		// TFX - Material de Implantação
oModel:GetModel("TFYDETAIL"):SetOptional(.T.)		// TFY - Material de Consumo
oModel:GetModel("TFLDETAIL"):SetOptional(.T.)		// TFL - Locação de Equipamentos
oModel:GetModel("TFIPRODUT"):SetOptional(.T.)		// TFI - Locação de Equipamentos (PRODUTOS)
oModel:GetModel("TFZDETAIL"):SetOptional(.T.)		// TFZ - Locação de Equipamentos (DETALHES APURAÇÃO)
oModel:GetModel("TFWTW6DETAIL"):SetOptional(.T.)	// TFWTW6 - Recursos Humanos - DESCONTOS
oModel:GetModel("TFWTW7DETAIL"):SetOptional(.T.)	// TFWTW7 - Recursos Humanos - MULTAS/BONIFICAÇÕES (Acréscimos/Decréscimos)
oModel:GetModel("TFXTW6DETAIL"):SetOptional(.T.)	// TFXTW6 - Material de Implantação - DESCONTOS
oModel:GetModel("TFXTW7DETAIL"):SetOptional(.T.)	// TFXTW7 - Material de Implantação - MULTAS/BONIFICAÇÕES (Acréscimos/Decréscimos)
oModel:GetModel("TFYTW6DETAIL"):SetOptional(.T.)	// TFYTW6 - Material de Consumo - DESCONTOS
oModel:GetModel("TFYTW7DETAIL"):SetOptional(.T.)	// TFYTW7 - Material de Consumo - MULTAS/BONIFICAÇÕES (Acréscimos/Decréscimos)
oModel:GetModel("TFITW6DETAIL"):SetOptional(.T.)	// TFITW6 - Locação de Equipamentos (PRODUTOS) - DESCONTOS
oModel:GetModel("TFITW7DETAIL"):SetOptional(.T.)	// TFITW7 - Locação de Equipamentos (PRODUTOS) - MULTAS/BONIFICAÇÕES (Acréscimos/Decréscimos)

oModel:GetModel("ZZPDETAIL"):SetOnlyQuery(.T.)
oModel:GetModel("ZZPDETAIL"):SetNoDeleteLine(.T.)

oModel:GetModel('TFLDETAIL'):SetOnlyQuery()
oModel:GetModel('TFIPRODUT'):SetOnlyQuery()

oModel:SetVldActivate( {|oModel| AT930VldCt(oModel)} )
oModel:SetActivate( {|oModel| InitDados( oModel ) } )

Return(oModel)


//------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View

@sample 	ViewDef()

@param		Nenhum
	
@return	ExpO Objeto FwFormView 
@author	Serviços
@since		01/11/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()

Local oView			:= Nil										// Interface de visualização construída	
Local oModel			:= FWLoadModel("TECA930")				// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado

Local oStruTFV		:= FWFormStruct( 2, "TFV", {|cCpo|   !(Alltrim(cCpo)$"TFV_NUMPED")})				// Cria as estruturas a serem usadas na View
Local oStruTFW		:= FWFormStruct( 2, "TFW", {|cCpo|   !(Alltrim(cCpo)$"TFW_APURAC#TFW_NUMMED#TFW_ITMED#TFW_CODTFL#TFW_CODIGO#TFW_MEDAD#TFW_ITMAD#TFW_MEDHE#TFW_ITMHE#TFW_MEDMI#TFW_ITMMI#TFW_MEDMC#TFW_ITMMC")})	// TFW - Recursos Humanos
Local oStruTFX		:= FWFormStruct( 2, "TFX", {|cCpo|   !(Alltrim(cCpo)$"TFX_APURAC#TFX_NUMMED#TFX_ITMED#TFX_CODTFL#TFX_CODIGO")})	// TFX - Material de Implantação
Local oStruTFY		:= FWFormStruct( 2, "TFY", {|cCpo|   !(Alltrim(cCpo)$"TFY_APURAC#TFY_NUMMED#TFY_ITMED#TFY_CODTFL#TFY_CODIGO")})	// TFY - Material de Consumo

Local oStruTFL		:= FWFormStruct( 2, "TFL", {|cCpo|   (Alltrim(cCpo)$"TFL_LOCAL#TFL_DESLOC")})											// TFL - Locação de Equipamentos
Local oStruTFI		:= FWFormStruct( 2, "TFI", {|cCampo| AllTrim(cCampo)$"TFI_FILIAL#TFI_PRODUT#TFI_COD#TFI_CODPAI#TFI_TOTMUL#TFI_TOTBON#TFI_TOTDES#TFI_DESCON#TFI_TES"})					// TFI - Locação de Equipamentos (PRODUTOS)
Local oStruTFZ		:= FWFormStruct( 2, "TFZ", {|cCpo|   !(Alltrim(cCpo)$"TFZ_CODIGO#TFZ_APURAC#TFZ_NUMMED#TFZ_ITMED#TFZ_CODTFL#TFX_CODIGO#TFZ_CODTEV#TFZ_CODLOC#TFZ_CODTFI")})	// TFZ - Locação de Equipamentos (DETALHES APURAÇÃO)

Local oStrTFWTW6		:= FWFormStruct( 2, "TW6", {|cCampo| !(AllTrim(cCampo)$ "TW6_FILIAL#TW6_CODIGO#TW6_TPPAI#TW6_CODPAI#TW6_OS")})				// TFWTW6 - Recursos Humanos (DESCONTOS)
Local oStrTFWTW7 := FWFormStruct( 2, "TW7", {|cCampo| !( AllTrim(cCampo)$ "TW7_FILIAL#TW7_CODIGO#TW7_TPPAI#TW7_CODPAI#TW7_CODMOV" )} )	// TFWTW7 - Recursos Humanos (MULTAS/BONIFICAÇÃO) (Acréscimos/Decréscimos)

Local oStrTFXTW6		:= FWFormStruct( 2, "TW6", {|cCampo| !(AllTrim(cCampo)$ "TW6_FILIAL#TW6_CODIGO#TW6_TPPAI#TW6_CODPAI#TW6_OS")})				// TFXTW6 - Material de Implantação (DESCONTOS)
Local oStrTFXTW7 := FWFormStruct( 2, "TW7", {|cCampo| !( AllTrim(cCampo)$ "TW7_FILIAL#TW7_CODIGO#TW7_TPPAI#TW7_CODPAI#TW7_CODMOV" )} )	// TFXTW7 - Material de Implantação (MULTAS/BONIFICAÇÃO)  (Acréscimos/Decréscimos)

Local oStrTFYTW6		:= FWFormStruct( 2, "TW6", {|cCampo| !(AllTrim(cCampo)$ "TW6_FILIAL#TW6_CODIGO#TW6_TPPAI#TW6_CODPAI#TW6_OS")})				// TFYTW6 - Material de Consumo (DESCONTOS)
Local oStrTFYTW7 := FWFormStruct( 2, "TW7", {|cCampo| !( AllTrim(cCampo)$ "TW7_FILIAL#TW7_CODIGO#TW7_TPPAI#TW7_CODPAI#TW7_CODMOV" )} )	// TFYTW7 - Material de Consumo (MULTAS/BONIFICAÇÃO)  (Acréscimos/Decréscimos)

Local oStrTFITW6		:= FWFormStruct( 2, "TW6", {|cCampo| !(AllTrim(cCampo)$ "TW6_FILIAL#TW6_CODIGO#TW6_TPPAI#TW6_CODPAI#TW6_OS")})				// TFITW6 - Locação de Equipamentos (DESCONTOS)
Local oStrTFITW7 := FWFormStruct( 2, "TW7", {|cCampo| !( AllTrim(cCampo)$ "TW7_FILIAL#TW7_CODIGO#TW7_TPPAI#TW7_CODPAI#TW7_CODMOV" )} )	// TFITW7 - Locação de Equipamentos (MULTAS/BONIFICAÇÃO)  (Acréscimos/Decréscimos)
 
Local oStruZZP		:= FWFormViewStruct():New()

Local oStruTW8		:= FWFormStruct( 2, "TW8", {|cCampo| !( AllTrim(cCampo)$ "TW8_CODTFI" )} )	// TW8 - Desconto por OS
Local oStrTWB			:= FWFormStruct(2,"TWB")
Local cRevCtr		:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
Local cIsGsMt		:= ""


//Faturamento antecipado
Local oStrABX		:= FWFormStruct( 2, "ABX")

If !lSrvExt
	cIsGsMt		:= Posicione( "TFJ", 5, xFilial("TFJ") + MV_PAR01 + cRevCtr, "TFJ_ISGSMT")

Else
	cIsGsMt		:= Posicione( "TFJ", 1, xFilial("TFJ") + MV_PAR05, "TFJ_ISGSMT")
	
EndIf
// TFV - Cabeçalho da Apuração

//========================================
// TFW - Recursos Humanos
//========================================
oStruTFW:AddField( ;									// Ord. Tipo Desc.
						"TFW_LOCAL",;					// [01] C Nome do Campo
						"01",;							// [02] C Ordem
						STR0004,;						// [03] C Titulo do campo # "Local" 
						STR0004,;						// [04] C Descrição do campo # "Local" 
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"",;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável
						
oStruTFW:AddField( ;									// Ord. Tipo Desc.
						"TFW_DESCRI",;				// [01] C Nome do Campo
						"02",;							// [02] C Ordem
						STR0005,;						// [03] C Titulo do campo # "Descrição"
						STR0005,;						// [04] C Descrição do campo # "Descrição"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável		
						
oStruTFW:AddField( ;									// Ord. Tipo Desc.
						"TFW_PRODUT",;				// [01] C Nome do Campo
						"04",;							// [02] C Ordem
						STR0038,;						// [03] C Titulo do campo # "Produto"
						STR0038,;						// [04] C Descrição do campo # "Produto"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"",;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável
						
oStruTFW:AddField( ;									// Ord. Tipo Desc.
						"TFW_DSCPRO",;				// [01] C Nome do Campo
						"05",;							// [02] C Ordem
						STR0064,;						// [03] C Titulo do campo # "Desc. Produto"
						STR0064,;						// [04] C Descrição do campo # "Desc. Produto"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável		

oStruTFW:AddField( ; 								// Ord. Tipo Desc.
						"TFW_TOTHOR",;				// [01] C Nome do Campo
						"10",;							// [02] C Ordem
						STR0063,;						// [03] C Titulo do campo # "Total apurado"
						STR0063,;						// [04] C Descrição do campo # "Total apurado"
						Nil,;							// [05] A Array com Help
						"N",;							// [06] C Tipo do campo
						"@E 9,999,999,999,999.99",;	// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"",;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável
						
oStruTFW:AddField( ; // Ord. Tipo Desc.
						"TFW_VLRTOT",;				// [01] C Nome do Campo
						"15",;							// [02] C Ordem
						STR0055,;						// [03] C Titulo do campo # "Total"
						STR0055,;						// [04] C Descrição do campo # "Total"
						Nil,;							// [05] A Array com Help
						"N",;							// [06] C Tipo do campo
						"@E 9,999,999,999,999.99",;	// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável		
If cIsGsMt == "1"
Endif
						
oStruTFW:SetProperty("TFW_CODTFF", MVC_VIEW_ORDEM, "03")
oStruTFW:SetProperty("TFW_HORAN" , MVC_VIEW_ORDEM, "06")
oStruTFW:SetProperty("TFW_VLHORN", MVC_VIEW_ORDEM, "07")
oStruTFW:SetProperty("TFW_HORAE" , MVC_VIEW_ORDEM, "08")
oStruTFW:SetProperty("TFW_VLHORE", MVC_VIEW_ORDEM, "09")
oStruTFW:SetProperty("TFW_MESANT", MVC_VIEW_ORDEM, "10")
oStruTFW:SetProperty("TFW_VLRAPU", MVC_VIEW_ORDEM, "11")
oStruTFW:SetProperty("TFW_VLRCON", MVC_VIEW_ORDEM, "13")
oStruTFW:SetProperty("TFW_VLRMED", MVC_VIEW_ORDEM, "14")
oStruTFW:SetProperty("TFW_VLREXT", MVC_VIEW_ORDEM, "15")
oStruTFW:SetProperty("TFW_TOTDES", MVC_VIEW_ORDEM, "16")
oStruTFW:SetProperty("TFW_TOTBON", MVC_VIEW_ORDEM, "17")
oStruTFW:SetProperty("TFW_VLRTOT", MVC_VIEW_ORDEM, "18")
oStruTFW:SetProperty("TFW_PDMTMI", MVC_VIEW_ORDEM, "19")
oStruTFW:SetProperty("TFW_VLMTMI", MVC_VIEW_ORDEM, "22")
oStruTFW:SetProperty("TFW_PDMTMC", MVC_VIEW_ORDEM, "23")
oStruTFW:SetProperty("TFW_VLMTMC", MVC_VIEW_ORDEM, "26")


oStruTFW:RemoveField("TFW_ITEMMI")
oStruTFW:RemoveField("TFW_ITEMMC")
oStruTFW:RemoveField("TFW_ABTINS")
oStruTFX:RemoveField("TFX_DIFMED")
oStruTFX:RemoveField("TFX_CODTFG")
oStruTFW:RemoveField("TFW_DIFMED")
oStruTFY:RemoveField("TFY_DIFMED")
oStruTFY:RemoveField("TFY_CODTFH")
//========================================
// TFX - Material de Implantação
//========================================
oStruTFX:AddField( ;									// Ord. Tipo Desc.
						"TFX_LOCAL",;					// [01] C Nome do Campo
						"01",;							// [02] C Ordem
						STR0004,;						// [03] C Titulo do campo # "Local"
						STR0004,;						// [04] C Descrição do campo # "Local"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável

oStruTFX:AddField( ;									// Ord. Tipo Desc.
						"TFX_DESCRI",;				// [01] C Nome do Campo
						"02",;							// [02] C Ordem
						STR0005,;						// [03] C Titulo do campo # "Descrição"
						STR0005,;						// [04] C Descrição do campo # "Descrição"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável		
						
oStruTFX:AddField( ; 								// Ord. Tipo Desc.
						"TFX_PRODUT",;				// [01] C Nome do Campo
						"04",;							// [02] C Ordem
						STR0038,;						// [03] C Titulo do campo # "Produto"
						STR0038,;						// [04] C Descrição do campo # "Produto"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável

oStruTFX:AddField( ; 								// Ord. Tipo Desc.
						"TFX_DSCPRO",;				// [01] C Nome do Campo
						"05",;							// [02] C Ordem
						STR0064,;						// [03] C Titulo do campo # "Desc. Produto"
						STR0064,;						// [04] C Descrição do campo # "Desc. Produto"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável						

oStruTFX:SetProperty("TFX_CODTFF", MVC_VIEW_ORDEM, "03")
oStruTFX:SetProperty("TFX_VLRAPU", MVC_VIEW_ORDEM, "06")
oStruTFX:SetProperty("TFX_MESANT", MVC_VIEW_ORDEM, "07")
oStruTFX:SetProperty("TFX_VLRCON", MVC_VIEW_ORDEM, "09")
oStruTFX:SetProperty("TFX_TOTMUL", MVC_VIEW_ORDEM, "10")
oStruTFX:SetProperty("TFX_TOTBON", MVC_VIEW_ORDEM, "11")
oStruTFX:SetProperty("TFX_TOTDES", MVC_VIEW_ORDEM, "12")
oStruTFX:SetProperty("TFX_VLRMED", MVC_VIEW_ORDEM, "13")

//========================================
// TFY - Material de Consumo
//========================================
oStruTFY:AddField( ;									// Ord. Tipo Desc.
						"TFY_LOCAL",;					// [01] C Nome do Campo
						"01",;							// [02] C Ordem
						STR0004,;						// [03] C Titulo do campo # "Local"
						STR0004,;						// [04] C Descrição do campo # "Local"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável

oStruTFY:AddField( ; 								// Ord. Tipo Desc.
						"TFY_DESCRI",;				// [01] C Nome do Campo
						"02",;							// [02] C Ordem
						STR0005,;						// [03] C Titulo do campo # "Descrição"
						STR0005,;						// [04] C Descrição do campo # "Descrição"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável

oStruTFY:AddField( ;									// Ord. Tipo Desc.
						"TFY_PRODUT",;				// [01] C Nome do Campo
						"04",;							// [02] C Ordem
						STR0038,;						// [03] C Titulo do campo # "Produto"
						STR0038,;						// [04] C Descrição do campo # "Produto"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável						

oStruTFY:AddField( ;									// Ord. Tipo Desc.
						"TFY_DSCPRO",;				// [01] C Nome do Campo
						"05",;							// [02] C Ordem
						STR0064,;						// [03] C Titulo do campo # "Desc. Produto"
						STR0064,;						// [04] C Descrição do campo # "Desc. Produto"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável

oStruTFY:SetProperty("TFY_CODTFF", MVC_VIEW_ORDEM, "03")
oStruTFY:SetProperty("TFY_VLRAPU", MVC_VIEW_ORDEM, "06")
oStruTFY:SetProperty("TFY_MESANT", MVC_VIEW_ORDEM, "07")
oStruTFY:SetProperty("TFY_VLRCON", MVC_VIEW_ORDEM, "09")
oStruTFY:SetProperty("TFY_TOTMUL", MVC_VIEW_ORDEM, "10")
oStruTFY:SetProperty("TFY_TOTBON", MVC_VIEW_ORDEM, "11")
oStruTFY:SetProperty("TFY_TOTDES", MVC_VIEW_ORDEM, "12")
oStruTFY:SetProperty("TFY_VLRMED", MVC_VIEW_ORDEM, "13")

//========================================
// TFL - Locação de Equipamentos
//========================================
oStruTFL:AddField( ;									// Ord. Tipo Desc.
						'TFL_VALTOT',;				// [01] C Nome do Campo (cIdField)
       				'05',;							// [02] C Ordem (cOrdem)
                     STR0065,;						// [03] C Titulo do campo (cTitulo) #"Valor Total"
                     STR0065,;						// [04] C Descrição do campo (cDescric) #"Valor Total"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFL:AddField(	'TFL_DISP',;					// [01] C Nome do Campo (cIdField)
       				'06',;							// [02] C Ordem (cOrdem)
                     STR0066,;						// [03] C Titulo do campo (cTitulo) #"Disponibilização"
                     STR0066,;						// [04] C Descrição do campo (cDescric) #"Disponibilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFL:AddField(	'TFL_USO',;					// [01] C Nome do Campo (cIdField)
       				'07',;							// [02] C Ordem (cOrdem)
                     STR0067,;						// [03] C Titulo do campo (cTitulo) #"Uso"
                     STR0067,;						// [04] C Descrição do campo (cDescric) #"Uso"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFL:AddField(	'TFL_MOBILI',;				// [01] C Nome do Campo (cIdField)
       				'08',;							// [02] C Ordem (cOrdem)
                     STR0068,;						// [03] C Titulo do campo (cTitulo) #"Mobilização"
                     STR0068,;						// [04] C Descrição do campo (cDescric) #"Mobilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFL:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)

//========================================
// TFI - Locação de Equipamentos (PRODUTOS)
//========================================
oStruTFI:AddField(	'TFI_DISP',;					// [01] C Nome do Campo (cIdField)
       				'06',;							// [02] C Ordem (cOrdem)
                     STR0066,;						// [03] C Titulo do campo (cTitulo) #"Disponibilização"
                     STR0066,;						// [04] C Descrição do campo (cDescric) #"Disponibilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFI:AddField(	'TFI_USO',;					// [01] C Nome do Campo (cIdField)
       				'07',;							// [02] C Ordem (cOrdem)
                     STR0067,;						// [03] C Titulo do campo (cTitulo) #"Uso"
                     STR0067,;						// [04] C Descrição do campo (cDescric) #"Uso"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFI:AddField(	'TFI_MOBILI',;				// [01] C Nome do Campo (cIdField)
       				'08',;							// [02] C Ordem (cOrdem)
                     STR0068,;						// [03] C Titulo do campo (cTitulo) #"Mobilização"
                     STR0068,;						// [04] C Descrição do campo (cDescric) #"Mobilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFI:AddField(	'TFI_TOTMUL',;				// [01] C Nome do Campo (cIdField)
       				'09',;							// [02] C Ordem (cOrdem)
                     STR0093,;						// [03] C Titulo do campo (cTitulo) #"Mobilização"
                     STR0093,;						// [04] C Descrição do campo (cDescric) #"Mobilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFI:AddField(	'TFI_TOTBON',;				// [01] C Nome do Campo (cIdField)
       				'10',;							// [02] C Ordem (cOrdem)
                     STR0094,;						// [03] C Titulo do campo (cTitulo) #"Mobilização"
                     STR0094,;						// [04] C Descrição do campo (cDescric) #"Mobilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFI:AddField(	'TFI_TOTDES',;				// [01] C Nome do Campo (cIdField)
       				'11',;							// [02] C Ordem (cOrdem)
                     STR0092,;						// [03] C Titulo do campo (cTitulo) #"Mobilização"
                     STR0092,;						// [04] C Descrição do campo (cDescric) #"Mobilização"
                     {},;							// [05] A Array com Help (aHelp)
                   	'N',;							// [06] C Tipo do campo (cType)
                   	'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
       				Nil,;							// [08] B Bloco de Picture Var (bPictVar)
                     Nil,;							// [09] C Consulta F3
                     .T.,;							// [10] L Indica se o campo é editável (lCanChange)
                     '',;							// [11] C Pasta do campo (cFolder)
                     Nil,;							// [12] C Agrupamento do campo (cGroup)
                     Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
                     Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
                     Nil,;							// [15] C Inicializador de Browse (cIniBrow)
                     .T.,;							// [16] L Indica se o campo é virtual (lVirtual)
                     Nil )							// [17] C Picture Variável (cPictVar)

oStruTFI:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)
												
//========================================
// TFZ - Locação de Equipamentos (DETALHES APURAÇÃO)
//========================================
//Campo virtual para atribuir a quantidade a ser apurada.    
oStruTFZ:AddField(	'TFZ_QTDE',;					// [01] C Nome do Campo (cIdField)
						'10',;							// [02] C Ordem (cOrdem)
						STR0061,;						// [03] C Titulo do campo (cTitulo) #"Quant.Previs"
						STR0061,;						// [04] C Descrição do campo (cDescric) #"Quant.Previs"
						{},;							// [05] A Array com Help (aHelp)
						'N',;							// [06] C Tipo do campo (cType)
						'@E 9,999,999,999.99',;		// [07] C Picture (cPicture)
						Nil,;							// [08] B Bloco de Picture Var (bPictVar)
						Nil,;							// [09] C Consulta F3
						.T.,;							// [10] L Indica se o campo é editável (lCanChange)
						'',;							// [11] C Pasta do campo (cFolder)
						Nil,;							// [12] C Agrupamento do campo (cGroup)
						Nil,;							// [13] A Lista de valores permitido do campo (Combo) (aComboValues)
						Nil,;							// [14] N Tamanho Maximo da maior opção do combo (nMaxLenCombo)
						Nil,;							// [15] C Inicializador de Browse (cIniBrow)
						.T.,;							// [16] L Indica se o campo é virtual (lVirtual)
						Nil )							// [17] C Picture Variável (cPictVar)

oStruTFZ:SetProperty("*",MVC_VIEW_CANCHANGE, .F.)

oStruTFZ:SetProperty("TFZ_QTDAPU",MVC_VIEW_CANCHANGE, .T.)
oStruTFZ:SetProperty("TFZ_MODCOB" , MVC_VIEW_ORDEM, "01")

oStrTWB:RemoveField("TWB_COD")
oStrTWB:RemoveField("TWB_CODTFV")

LoadStruZZP(oStruZZP, .T.)

If lSrvExt
	oStruTFV:RemoveField("TFV_HREXTR")
EndIf
If lTeca934	


oStrABX:AddField( ;									// Ord. Tipo Desc.
						"ABX_DESCRI",;				// [01] C Nome do Campo
						"02",;							// [02] C Ordem
						STR0005,;						// [03] C Titulo do campo # "Descrição"
						STR0005,;						// [04] C Descrição do campo # "Descrição"
						Nil,;							// [05] A Array com Help
						"C",;							// [06] C Tipo do campo
						"@!",;							// [07] C Picture
						NIL,;							// [08] B Bloco de Picture Var
						"" ,;							// [09] C Consulta F3
						.F.,;							// [10] L Indica se o campo é editável
						NIL,;							// [11] C Pasta do campo
						NIL,;							// [12] C Agrupamento do campo
						NIL,;							// [13] A Lista de valores permitido do campo (Combo)
						NIL,;							// [14] N Tamanho Maximo da maior opção do combo
						NIL,;							// [15] C Inicializador de Browse
						.T.,;							// [16] L Indica se o campo é virtual
						NIL )							// [17] C Picture Variável	
							
	oStrABX:RemoveField("ABX_CODIGO")
	oStrABX:RemoveField("ABX_OPERAC")
	oStrABX:RemoveField("ABX_CONTRT")
	oStrABX:RemoveField("ABX_CONREV")
	oStrABX:RemoveField("ABX_NUMMED")
	oStrABX:RemoveField("ABX_CODTFV")
	oStrABX:RemoveField("ABX_PEDIDO")
	oStrABX:RemoveField("ABX_PEDITE")
	oStrABX:RemoveField("ABX_VLCOMP")
	oStrABX:RemoveField("ABX_RECORR")
	oStrABX:RemoveField("ABX_PRIMED")
	oStrABX:RemoveField("ABX_TPDESC")
	oStrABX:RemoveField("ABX_MESANO")
	oStrABX:RemoveField("ABX_VLORMD")
	oStrABX:RemoveField("ABX_DESCON")
	
	oStrABX:SetProperty("ABX_DTINAP" , MVC_VIEW_ORDEM, "01")
	oStrABX:SetProperty("ABX_DTFMAP" , MVC_VIEW_ORDEM, "02")
	oStrABX:SetProperty("ABX_LOCAL"  , MVC_VIEW_ORDEM, "03")
	oStrABX:SetProperty("ABX_DESCRI" , MVC_VIEW_ORDEM, "04")
	oStrABX:SetProperty("ABX_CODPLA" , MVC_VIEW_ORDEM, "05")
	
Else
	oStruTFW:RemoveField("TFW_MESANT")
	oStruTFX:RemoveField("TFX_MESANT")
	oStruTFY:RemoveField("TFY_MESANT")

EndIf

oView := FWFormView():New()											// Cria o objeto de View
oView:SetModel(oModel)												// Define qual Modelo de dados será utilizado
oView:AddField("VIEW_TFV",       oStruTFV,   "TFVMASTER")		// Adiciona no nosso View um controle do tipo formulário (antiga Enchoice)
oView:AddGrid("VIEW_ZZP",        oStruZZP,   "ZZPDETAIL")
oView:AddGrid("TECA930_IRH",     oStruTFW,   "TFWDETAIL")		// TFW - Recursos Humanos
oView:AddGrid("TECA930_IRH_TW6", oStrTFWTW6, "TFWTW6DETAIL")	// TFWTW6 - Recursos Humanos - DESCONTOS
oView:AddGrid("TECA930_IRH_TW7", oStrTFWTW7, "TFWTW7DETAIL" )	// TFWTW7 - Recursos Humanos - MULTAS/BONIFICAÇÃO  (Acréscimos/Decréscimos)
oView:AddGrid("TECA930_IMI",     oStruTFX,   "TFXDETAIL")		// TFX - Material de Implantação
oView:AddGrid("TECA930_IMI_TW6", oStrTFXTW6, "TFXTW6DETAIL")	// TFXTW6 - Material de Implantação - DESCONTOS
oView:AddGrid( "TECA930_IMI_TW7", oStrTFXTW7, "TFXTW7DETAIL" )	// TFXTW7 - Material de Implantação - MULTAS/BONIFICAÇÃO  (Acréscimos/Decréscimos)
oView:AddGrid("TECA930_IMC",     oStruTFY,   "TFYDETAIL")		// TFY - Material de Consumo
oView:AddGrid("TECA930_IMC_TW6", oStrTFYTW6, "TFYTW6DETAIL")	// TFYTW6 - Material de Consumo - DESCONTOS
oView:AddGrid( "TECA930_IMC_TW7", oStrTFYTW7, "TFYTW7DETAIL" )	// TFYTW7 - Material de Consumo - MULTAS/BONIFICAÇÃO  (Acréscimos/Decréscimos)
oView:AddGrid("TECA930_LOC",     oStruTFL,   "TFLDETAIL")		// TFL - Locação de Equipamentos
oView:AddGrid("TECA930_IPR",     oStruTFI,   "TFIPRODUT")		// TFI - Locação de Equipamentos (PRODUTOS)
oView:AddGrid("TECA930_IPR_TW6", oStrTFITW6, "TFITW6DETAIL")	// TFITW6 - Locação de Equipamentos (PRODUTOS) - DESCONTOS
oView:AddGrid( "TECA930_IPR_TW7", oStrTFITW7, "TFITW7DETAIL" )	// TFITW7 - Locação de Equipamentos (PRODUTOS) - MULTAS/BONIFICAÇÃO  (Acréscimos/Decréscimos)
oView:AddGrid("TECA930_ILE",     oStruTFZ,   "TFZDETAIL")		// TFZ - Locação de Equipamentos (DETALHES APURAÇÃO)

oView:AddGrid("TECA930_TW8_OS", oStruTW8, "TW8DETAIL")		// TW8 - Desconto por ordem de Serviço

oView:AddGrid("TECA930_RESLOC", oStrTWB,  "TWBDETAIL")		// TWB - Resumo Local

If lTeca934
	oView:AddGrid("TECA930_APUR", oStrABX,  "ABXDETAIL")		// ABX - APURAÇÃO MÊS ANTERIOR
EndIf

oView:AddUserButton(STR0084 ,"",{|oView| FMedApu930(oView)})	//'Materiais por valor'
oView:AddUserButton("Visualizar contrato" ,"",{|oView| A930ViewCTR()})	//'Materiais por valor'

oView:AddUserButton("Opções de Faturamento","",{|oView| AtTec930FS(oView) })	

// Adiciona as visões na tela
oView:CreateHorizontalBox( "TOP",  20 )
oView:CreateHorizontalBox( "DOWN", 80 )

// Cria Folder na view
oView:CreateFolder( "ABAS", "DOWN" )
oView:AddSheet("ABAS", "ABA01", STR0007)	//"Recursos Humanos"
oView:AddSheet("ABAS", "ABA02", STR0008)	//'Materiais de Implantação'
oView:AddSheet("ABAS", "ABA03", STR0009)	//'Materiais de Consumo'
oView:AddSheet("ABAS", "ABA04", STR0010)	//"Locação de Equipamentos"
oView:AddSheet("ABAS", "ABA06", STR0095)	//"Resumo dos Locais"
oView:AddSheet("ABAS", "ABA05", STR0090)	//"Resumo da Medição"
If lTeca934
	oView:AddSheet("ABAS", "ABA07", "Apuração Mês Anterior")	//"Apuração Mês Anterior"
EndIf
oView:CreateHorizontalBox("ID_ABA01_TOP",               065,,, "ABAS", "ABA01")									// Define a área de item de RH (Área superior)
oView:CreateHorizontalBox("ID_ABA01_DOWN",              030,,, "ABAS", "ABA01")									// Define a área de item de RH (Área inferior)
oView:CreateHorizontalBox("ID_ABA01_FOOTER",            005,,, "ABAS", "ABA01")									// Define a área do botão detalhes do item de RH
oView:CreateFolder("ABA01_DOWN_ABAS", "ID_ABA01_DOWN")																// Define a área para a criação das Abas do item de RH
oView:AddSheet("ABA01_DOWN_ABAS", "ABA01_DOWN_ABAS_01", STR0091)													// Define a Aba das Multas(Acréscimo) e Bonificações(Decréscimo) do item de RH
oView:AddSheet("ABA01_DOWN_ABAS", "ABA01_DOWN_ABAS_02", STR0092)													// Define a Aba dos Descontos do item de RH
oView:CreateHorizontalBox("ID_ABA01_DOWN_ABAS_01_H1",   100,,, "ABA01_DOWN_ABAS", "ABA01_DOWN_ABAS_01")		// Define a área das Multas(Acréscimo) e Bonificações(Decréscimo) do item de RH
oView:CreateHorizontalBox("ID_ABA01_DOWN_ABAS_02_H1",   100,,, "ABA01_DOWN_ABAS", "ABA01_DOWN_ABAS_02")		// Define a área dos Descontos do item de RH

oView:CreateHorizontalBox("ID_ABA02_TOP",               065,,, "ABAS", "ABA02")									// Define a área de Materiais de Implantação (Área superior)
oView:CreateHorizontalBox("ID_ABA02_DOWN",              030,,, "ABAS", "ABA02")									// Define a área de item de Materiais de Implantação (Área inferior)
oView:CreateHorizontalBox("ID_ABA02_FOOTER",            005,,, "ABAS", "ABA02")									// Define a área do botão detalhes de Materiais de Implantação
oView:CreateFolder("ABA02_DOWN_ABAS", "ID_ABA02_DOWN")																// Define a área para a criação das Abas do item de Materiais de Implantação
oView:AddSheet("ABA02_DOWN_ABAS", "ABA02_DOWN_ABAS_01", STR0091)													// Define a Aba das Multas(Acréscimo) e Bonificações(Decréscimo) do item de Materiais de Implantação
oView:AddSheet("ABA02_DOWN_ABAS", "ABA02_DOWN_ABAS_02", STR0092)													// Define a Aba dos Descontos do item de Materiais de Implantação
oView:CreateHorizontalBox("ID_ABA02_DOWN_ABAS_01_H1",   100,,, "ABA02_DOWN_ABAS", "ABA02_DOWN_ABAS_01")		// Define a área das Multas(Acréscimo) e Bonificações(Decréscimo) do item de Materiais de Implantação
oView:CreateHorizontalBox("ID_ABA02_DOWN_ABAS_02_H1",   100,,, "ABA02_DOWN_ABAS", "ABA02_DOWN_ABAS_02")		// Define a área dos Descontos do item de Materiais de Implantação

oView:CreateHorizontalBox("ID_ABA03_TOP",               065,,, "ABAS", "ABA03")									// Define a área de Materiais de Consumo (Área superior)
oView:CreateHorizontalBox("ID_ABA03_DOWN",              030,,, "ABAS", "ABA03")									// Define a área de item de Materiais de Consumo (Área inferior)
oView:CreateHorizontalBox("ID_ABA03_FOOTER",            005,,, "ABAS", "ABA03")									// Define a área do botão detalhes Materiais de Consumo
oView:CreateFolder("ABA03_DOWN_ABAS", "ID_ABA03_DOWN")																// Define a área para a criação das Abas do item de Materiais de Consumo
oView:AddSheet("ABA03_DOWN_ABAS", "ABA03_DOWN_ABAS_01", STR0091)													// Define a Aba das Multas(Acréscimo) e Bonificações(Decréscimo) do item de Materiais de Consumo
oView:AddSheet("ABA03_DOWN_ABAS", "ABA03_DOWN_ABAS_02", STR0092)													// Define a Aba dos Descontos do item de Materiais de Consumo
oView:CreateHorizontalBox("ID_ABA03_DOWN_ABAS_01_H1",   100,,, "ABA03_DOWN_ABAS", "ABA03_DOWN_ABAS_01")		// Define a área das Multas(Acréscimo) e Bonificações(Decréscimo) do item de Materiais de Consumo
oView:CreateHorizontalBox("ID_ABA03_DOWN_ABAS_02_H1",   100,,, "ABA03_DOWN_ABAS", "ABA03_DOWN_ABAS_02")		// Define a área dos Descontos do item de Materiais de Consumo

oView:CreateHorizontalBox("ID_ABA04_TOP",               030,,, "ABAS", "ABA04")									// Define a área de Locação de Equipamentos (Área superior)
oView:CreateHorizontalBox("ID_ABA04_MIDDLE",            035,,, "ABAS", "ABA04")									// Define a área de item de Locação de Equipamentos (Área intermediária)
oView:CreateHorizontalBox("ID_ABA04_DOWN",              030,,, "ABAS", "ABA04")									// Define a área de item de Locação de Equipamentos (Área inferior)
oView:CreateHorizontalBox("ID_ABA04_FOOTER",            005,,, "ABAS", "ABA04")									// Define a área do botão detalhes de Locação de Equipamentos

oView:CreateFolder("ABA04_MIDDLE_ABAS", "ID_ABA04_MIDDLE")														 	// Define a área para a criação das Abas dos produtos do item da Locação de Equipamentos
oView:AddSheet("ABA04_MIDDLE_ABAS", "ABA04_MIDDLE_ABAS_01", STR0102)	//"Produtos"								// Define a Aba dos produtos do item da Locação de Equipamentos
oView:CreateHorizontalBox("ID_ABA04_MIDDLE_ABAS_01_H1", 100,,, "ABA04_MIDDLE_ABAS", "ABA04_MIDDLE_ABAS_01")	// Define a área dos produtos do item da Locação de Equipamentos

oView:AddSheet("ABA04_MIDDLE_ABAS", "ABA04_MIDDLE_ABAS_02", STR0103)	//"Ordem Serviço"						// Define a Aba desconto OS
oView:CreateHorizontalBox("ID_ABA04_MIDDLE_ABAS_02_H1", 100,,, "ABA04_MIDDLE_ABAS", "ABA04_MIDDLE_ABAS_02")	// Define a área dos produtos do item da Locação de Equipamentos

oView:CreateFolder("ABA04_DOWN_ABAS", "ID_ABA04_DOWN")																// Define a área para a criação das Abas do item da Locação de Equipamentos
oView:AddSheet("ABA04_DOWN_ABAS", "ABA04_DOWN_ABAS_01", STR0104)	//"Medição"									// Define a Aba das Medições do item da Locação de Equipamentos
oView:AddSheet("ABA04_DOWN_ABAS", "ABA04_DOWN_ABAS_02", STR0091)													// Define a Aba das Multas(Acréscimo) e Bonificações(Decréscimo) do item da Locação de Equipamentos
oView:AddSheet("ABA04_DOWN_ABAS", "ABA04_DOWN_ABAS_03", STR0092)													// Define a Aba dos Descontos do item da Locação de Equipamentos
oView:CreateHorizontalBox("ID_ABA04_DOWN_ABAS_01_H1",   100,,, "ABA04_DOWN_ABAS", "ABA04_DOWN_ABAS_01")		// Define a área das Medições do item da Locação de Equipamentos
oView:CreateHorizontalBox("ID_ABA04_DOWN_ABAS_02_H1",   100,,, "ABA04_DOWN_ABAS", "ABA04_DOWN_ABAS_02")		// Define a área das Multas(Acréscimo) e Bonificações(Decréscimo) do item da Locação de Equipamentos
oView:CreateHorizontalBox("ID_ABA04_DOWN_ABAS_03_H1",   100,,, "ABA04_DOWN_ABAS", "ABA04_DOWN_ABAS_03")		// Define a área dos Descontos do item da Locação de Equipamentos

oView:CreateHorizontalBox("ID_ABA05", 100,,, "ABAS", "ABA05")	// Define a área do Resumo da Medição

oView:CreateHorizontalBox("ID_ABA06", 100,,, "ABAS", "ABA06")	// Define a área do Resumo dos Locais
If lTeca934
	oView:CreateHorizontalBox("ID_ABA07", 100,,, "ABAS", "ABA07")	// Define a área do Apuração Mês anterior
EndIf
// Adiciona os botoes de detalhes do local nas abas
oView:AddOtherObject("DETALHE_IRH", {|oPanel| At930Buttons(oPanel,2)})
oView:AddOtherObject("DETALHE_IMI", {|oPanel| At930Buttons(oPanel,3)})
oView:AddOtherObject("DETALHE_IMC", {|oPanel| At930Buttons(oPanel,4)})
oView:AddOtherObject("DETALHE_ILE", {|oPanel| At930Buttons(oPanel,5)})

// Relaciona o identificador (ID) da View com o "box" para exibição
oView:SetOwnerView("VIEW_TFV",        "TOP")
oView:SetOwnerView("TECA930_IRH",     "ID_ABA01_TOP")
oView:SetOwnerView("TECA930_IRH_TW7", "ID_ABA01_DOWN_ABAS_01_H1")
oView:SetOwnerView("TECA930_IRH_TW6", "ID_ABA01_DOWN_ABAS_02_H1")
oView:SetOwnerView("DETALHE_IRH",     "ID_ABA01_FOOTER")
oView:SetOwnerView("TECA930_IMI",     "ID_ABA02_TOP")
oView:SetOwnerView("TECA930_IMI_TW7", "ID_ABA02_DOWN_ABAS_01_H1")
oView:SetOwnerView("TECA930_IMI_TW6", "ID_ABA02_DOWN_ABAS_02_H1")
oView:SetOwnerView("DETALHE_IMI",     "ID_ABA02_FOOTER")
oView:SetOwnerView("TECA930_IMC",     "ID_ABA03_TOP")
oView:SetOwnerView("TECA930_IMC_TW7", "ID_ABA03_DOWN_ABAS_01_H1")
oView:SetOwnerView("TECA930_IMC_TW6", "ID_ABA03_DOWN_ABAS_02_H1")
oView:SetOwnerView("DETALHE_IMC",     "ID_ABA03_FOOTER")
oView:SetOwnerView("TECA930_LOC",     "ID_ABA04_TOP")
oView:SetOwnerView("TECA930_IPR",     "ID_ABA04_MIDDLE_ABAS_01_H1")
oView:SetOwnerView("TECA930_ILE",     "ID_ABA04_DOWN_ABAS_01_H1")
oView:SetOwnerView("TECA930_IPR_TW7", "ID_ABA04_DOWN_ABAS_02_H1")
oView:SetOwnerView("TECA930_IPR_TW6", "ID_ABA04_DOWN_ABAS_03_H1")
oView:SetOwnerView("DETALHE_ILE",     "ID_ABA04_FOOTER")
oView:SetOwnerView("VIEW_ZZP",        "ID_ABA05")

oView:SetOwnerView("TECA930_TW8_OS",  "ID_ABA04_MIDDLE_ABAS_02_H1")
oStruTW8:SetProperty('*',	MVC_VIEW_CANCHANGE,.F.)	//Desabilita todos os campos para edição
oStruTW8:SetProperty('TW8_OK',	MVC_VIEW_CANCHANGE,.T.)	//Habilita somente o campo OK para edição

oView:SetOwnerView("TECA930_RESLOC",  "ID_ABA06")
If lTeca934
	oView:SetOwnerView("TECA930_APUR",  "ID_ABA07")
Endif

oView:SetDescription( STR0001 ) // "Apuração / Medição de Atendimentos"
oView:SetCloseOnOk({|| .T.} )

Return(oView)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930Buttons
Criação dos botões para detalhes do local nas abas da apuração do contrato
@sample 	At930Buttons(oPanel,nAba)
@param		oPanel - Painel onde deverá ser criado e exibido o botão
@param		nAba   - Numero da aba onde devera ser criado o botão
@return	Nil 
@author	Serviços
@since		04/11/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function At930Buttons( oPanel, nAba )

Local oButton

// Ancoramos os objetos no oPanel passado
@ 000, 000 Button oButton Prompt STR0011 Of oPanel Size 055, 012 Pixel //"Detalhes do Local"
oButton:Align := CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel

// Define a ação ao clicar no botão atraves da aba selecionada
Do Case
	Case nAba == 2	// Aba de Recursos Humanos
		oButton:bAction := { || At930DetRH() }
	Case nAba == 3	// Aba de Materiais de Implantação
		oButton:bAction := { || At930DetMat(1) }
	Case nAba == 4	// Aba de Materiais de Consumo
		oButton:bAction := { || At930DetMat(2) }
	Case nAba == 5	// Aba de Locação de Equipamentos
		oButton:bAction := { ||  At930DetLoc() }	
EndCase	

Return(Nil)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GridZZP
Atualização da aba Resumo da Medição
@sample 	At930GridZZP(oPanel)
@param		Nil
@return	Nil 
@author	Serviços
@since		04/11/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function At930GridZZP(oMdlGer)

Local aSaveRows := {}
Local nVlrTotal := 0
Local nVlrExced := 0
Local nX
Local aRet		  := {}
Local cRevCtr	:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
Local cOrcSrvExt:= ""
Local cChvSeek  := ""
Local cIsGsMt		:= "" 
Local nVlrMtMi		:= 0
Local nVlrMtMc		:= 0
Local nVlrAcres		:= 0
Local aAreaTFJ		:= TFJ->(GetArea())

aSaveRows := FwSaveRows()
If !Empty(MV_PAR01) .OR. (lSrvExt .AND. !Empty(MV_PAR05))
	
	dbSelectArea( "TFJ" )
	If lSrvExt
		cOrcSrvExt := AllTrim(MV_PAR05)
		cChvSeek   := "FWxFilial('TFJ') + '"+cOrcSrvExt+"' == TFJ->(TFJ_FILIAL+TFJ_CODIGO)"
		TFJ->( dbSetOrder( 1 ) ) // TFJ_FILIAL + TFJ_CODIGO
		TFJ->( DbSeek( FWxFilial("TFJ") + cOrcSrvExt ) )
	Else
		cChvSeek   := "xFilial('TFJ')+TFJ->TFJ_CONTRT+TFJ->TFJ_CONREV == xFilial('TFJ') + '"+ MV_PAR01 + cRevCtr + "'"
		TFJ->( dbSetOrder( 5 ) )
		TFJ->( DbSeek( xFilial("TFJ") + MV_PAR01 + cRevCtr ) )
	EndIf
	
	While TFJ->( !Eof() ) .AND. &(cChvSeek)				
		If TFJ->TFJ_STATUS <> "1"
			TFJ->(dbSkip())
			Loop
		EndIf
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_APU", STR0007  ) // "Recursos Humanos"
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_GRPFAT",	 TFJ->TFJ_GRPRH )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_DESC", Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPRH,"B1_DESC") )
			
		nVlrTotal := 0
		nVlrExced := 0

		For nX := 1 To oMdlGer:GetModel( "TFWDETAIL" ):Length()        	
        	oMdlGer:GetModel( "TFWDETAIL" ):GoLine(nX)        	
        	nVlrTotal += FwFldGet("TFW_VLRMED")
        	nVlrTotal += FwFldGet("TFW_VLMTMI")
        	nVlrTotal += FwFldGet("TFW_VLMTMC")
        	nVlrAcres += FwFldGet("TFW_TOTMUL")
			nVlrExced += FwFldGet("TFW_VLREXT")
			nVlrMtMi  += FwFldGet("TFW_VLMTMI")
			nVlrMtMc  += FwFldGet("TFW_VLMTMC")
       	Next nX
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLRTOT", nVlrTotal+nVlrMtMi+nVlrMtMc)
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLREXT", nVlrExced )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_TOTMUL", nVlrAcres )
		
		oMdlGer:GetModel( "ZZPDETAIL" ):AddLine()
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_APU", STR0008  ) // "Materiais de Implantação"
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_GRPFAT",	 TFJ->TFJ_GRPMI )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_DESC", Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPMI,"B1_DESC") )
		
		nVlrTotal := 0
				
		For nX := 1 To oMdlGer:GetModel( "TFXDETAIL" ):Length()        	
        	oMdlGer:GetModel( "TFXDETAIL" ):GoLine(nX)        	
        	nVlrTotal += FwFldGet("TFX_VLRMED")			
       	Next nX
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLRTOT", nVlrTotal )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLREXT", 0  )
		
		oMdlGer:GetModel( "ZZPDETAIL" ):AddLine()
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_APU", STR0009  ) // "Materiais de Consumo"
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_GRPFAT",	 TFJ->TFJ_GRPMC )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_DESC", Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPMC,"B1_DESC") )
		
		nVlrTotal := 0
				
		For nX := 1 To oMdlGer:GetModel( "TFYDETAIL" ):Length()        	
        	oMdlGer:GetModel( "TFYDETAIL" ):GoLine(nX)        	
        	nVlrTotal += FwFldGet("TFY_VLRMED")			
       	Next nX		
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLRTOT", nVlrTotal )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLREXT", 0  )
		
		oMdlGer:GetModel( "ZZPDETAIL" ):AddLine()
		
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_APU", STR0010 ) // "Locação de Equipamentos" 
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_GRPFAT",	 TFJ->TFJ_GRPLE )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_DESC", Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPLE,"B1_DESC") )
			
		nVlrTotal := 0
				
		For nX := 1 To oMdlGer:GetModel( "TFZDETAIL" ):Length()        	
        	oMdlGer:GetModel( "TFZDETAIL" ):GoLine(nX)        	
        	nVlrTotal += FwFldGet("TFZ_TOTAL")			
       Next nX	
					
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLRTOT", nVlrTotal )
		oMdlGer:SetValue( "ZZPDETAIL", "ZZP_VLREXT", 0  )
	
						  
		TFJ->( DbSkip() )	
	End
	
	
EndIf

RestArea(aAreaTFJ)

Return(aRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At930LoadZZP
Atualização da lista de grupos de faturamentos
@sample 	At930LoadZZP(oMdlGrid)
@param		Nil
@return	Nil 
@author	Serviços
@since		21/11/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function At930LoadZZP(oMdlGrid)

Local aSaveRows := {}
Local nVlrTotal := 0
Local nVlrExced := 0
Local nVlrDesc  := 0
Local nVlrMulta  := 0
Local nVlrBoni  := 0
Local aRet		  := {}
Local cCodRev   := ""
Local cCodApu	  := TFV->TFV_CODIGO
Local lFirst	  := .T. 	
Local cCodPai	  := ""	
Local nOrderTFJ	  := 0

Local cAliasTFW := GetNextAlias()
Local cAliasTFX := GetNextAlias()
Local cAliasTFY := GetNextAlias()
Local cAliasTFZ := GetNextAlias()

lSrvExt		:= IIF(Empty(TFV->TFV_ORCSRV), .F. , .T. )
nOrderTFJ	:= IIF(lSrvExt,1,5)

aSaveRows := FwSaveRows()

cCodRev := Posicione("CN9",7,xFilial("CN9")+TFV->TFV_CONTRT+"05","CN9_REVISA")
	
dbSelectArea( "TFJ" )
TFJ->( dbSetOrder( nOrderTFJ ) )

If lSrvExt
	TFJ->( DbSeek( xFilial("TFJ") + TFV->TFV_ORCSRV ) )
Else
	TFJ->( DbSeek( xFilial("TFJ") + TFV->TFV_CONTRT + cCodRev ) )
EndIf

While TFJ->( !Eof() ) .AND. IIF(lSrvExt, xFilial("TFJ")+TFJ->TFJ_CODIGO == xFilial("TFV")+TFV->TFV_ORCSRV  ,xFilial("TFJ")+TFJ->TFJ_CONTRT+TFJ->TFJ_CONREV == xFilial("TFV")+TFV->TFV_CONTRT+cCodRev)	
				
	If TFJ->TFJ_STATUS <> "1"
		TFJ->(dbSkip())
		Loop
	EndIf

	//=============================================================//
	// Recursos Humanos
	//=============================================================//
	nVlrTotal := 0
	nVlrExced := 0		
	nVlrDesc  := 0	

	// Verificar a apuração dos itens do RH
	BeginSql Alias cAliasTFW

		SELECT TFW.TFW_VLRMED, TFW.TFW_VLREXT, TFW_CODIGO
		  FROM %table:TFW% TFW
		 WHERE TFW.TFW_FILIAL = %xFilial:TFW%
		   AND TFW.TFW_APURAC = %Exp:cCodApu%
		   AND TFW.%NotDel%

	EndSql
	
	While (cAliasTFW)->(!Eof())		
		nVlrTotal += (cAliasTFW)->TFW_VLRMED
		nVlrExced += (cAliasTFW)->TFW_VLREXT			
		
		If lFirst
			cCodPai := "%('" +  (cAliasTFW)->(TFW_CODIGO) + "'"
			lFirst := .F.
		Else
			cCodPai +=  ", '" + (cAliasTFW)->(TFW_CODIGO) + "'"		
		EndIf				 								
		(cAliasTFW)->(dbSkip())			
	EndDo	
	If !Empty(cCodPai)
		cCodPai +=  ")%"
	EndIf			

	nVlrDesc := A930GetDsc(cCodPai,'RH')		
	A930GetMB(cCodPai,'RH',@nVlrMulta,@nVlrBoni)
			
	aAdd(aRet,{ 1, { STR0007,TFJ->TFJ_GRPRH,Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPRH,"B1_DESC"),nVlrTotal,nVlrExced,nVlrMulta,nVlrBoni,nVlrDesc}} )


	//=============================================================//
	// "Materiais de Implantação"
	//=============================================================//
	nVlrTotal := 0
	nVlrMulta	:= 0
	nVlrBoni := 0
	nVlrDesc := 0	
	cCodPai := ""
	lFirst := .T.

	// Verificar a apuração dos materiais de implantação
	BeginSql Alias cAliasTFX

		SELECT TFX.TFX_VLRMED, TFX.TFX_CODIGO
		  FROM %table:TFX% TFX
		 WHERE TFX.TFX_FILIAL = %xFilial:TFX%
		   AND	TFX.TFX_APURAC = %Exp:cCodApu%
		   AND TFX.%NotDel%

	EndSql
	
	While (cAliasTFX)->(!Eof())		
		nVlrTotal += (cAliasTFX)->TFX_VLRMED			
		
		If lFirst
			cCodPai := "%('" +  (cAliasTFX)->(TFX_CODIGO) + "'"
			lFirst := .F.
		Else
			cCodPai +=  ", '" + (cAliasTFX)->(TFX_CODIGO) + "'"		
		EndIf
						
		(cAliasTFX)->(dbSkip())			
	EndDo		
	If !Empty(cCodPai) 			
		cCodPai +=  ")%"
	EndIf
	
	nVlrDesc := A930GetDsc(cCodPai,'MI')		
	A930GetMB(cCodPai,'MI',@nVlrMulta,@nVlrBoni)	

	aAdd(aRet,{2,{STR0008,TFJ->TFJ_GRPMI,Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPMI,"B1_DESC"),nVlrTotal,0,nVlrMulta,nVlrBoni,nVlrDesc}} )


	//=============================================================//
	// "Materiais de Consumo"
	//=============================================================//
	nVlrTotal := 0
	nVlrMulta	:= 0
	nVlrBoni := 0
	nVlrDesc := 0
	cCodPai := ""
	lFirst := .T.
	
	// Verificar a apuração dos materiais de consumo
	BeginSql Alias cAliasTFY

		SELECT TFY.TFY_VLRMED, TFY.TFY_CODIGO
		  FROM %table:TFY% TFY
		 WHERE TFY.TFY_FILIAL = %xFilial:TFY%
		   AND TFY.TFY_APURAC = %Exp:cCodApu%
		   AND TFY.%NotDel%  

	EndSql
	
	While (cAliasTFY)->(!Eof())		
		nVlrTotal += (cAliasTFY)->TFY_VLRMED
		If lFirst
			cCodPai := "%('" +  (cAliasTFY)->(TFY_CODIGO) + "'"
			lFirst := .F.
		Else
			cCodPai +=  ", '" + (cAliasTFY)->(TFY_CODIGO) + "'"		
		EndIf
		
		(cAliasTFY)->(dbSkip())			
	EndDo
	If !Empty(cCodPai) 			
		cCodPai += ")%"
	EndIf
	
	nVlrDesc := A930GetDsc(cCodPai,'MC')		
	A930GetMB(cCodPai,'MC',@nVlrMulta,@nVlrBoni)

	aAdd(aRet,{3,{STR0009,TFJ->TFJ_GRPMC,Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPMC,"B1_DESC"),nVlrTotal,0,nVlrMulta,nVlrBoni,nVlrDesc}} )


	//=============================================================//
	// "Locação de Equipamentos"
	//=============================================================//
	nVlrTotal := 0
	nVlrMulta	:= 0
	nVlrBoni := 0
	nVlrDesc := 0
	cCodPai := ""
	lFirst := .T.
			
	// Verificar a apuração das alocações de equipamentos
	BeginSql Alias cAliasTFZ

		SELECT TFZ.TFZ_TOTAL, TFZ_CODIGO
		  FROM %table:TFZ% TFZ
		 WHERE TFZ.TFZ_FILIAL = %xFilial:TFZ%
		   AND TFZ.TFZ_APURAC = %Exp:cCodApu%
		   AND TFZ.%NotDel%

	EndSql
	
	While (cAliasTFZ)->(!Eof())
		nVlrTotal += (cAliasTFZ)->TFZ_TOTAL	
		If lFirst
			cCodPai := "%('" +  (cAliasTFZ)->(TFZ_CODIGO) + "'"
			lFirst := .F.
		Else
			cCodPai +=  ", '" + (cAliasTFZ)->(TFZ_CODIGO) + "'"		
		EndIf
			
		(cAliasTFZ)->(dbSkip())
	EndDo
	
	If !Empty(cCodPai)
		cCodPai +=  ")%"
	EndIf
	
	nVlrDesc := A930GetDsc(cCodPai,'LE')		
	A930GetMB(cCodPai,'LE',@nVlrMulta,@nVlrBoni)
			
	aAdd(aRet,{4,{STR0010,TFJ->TFJ_GRPLE,Posicione("SB1",1,xFilial("SB1")+TFJ->TFJ_GRPLE,"B1_DESC"),nVlrTotal,0,nVlrMulta,nVlrBoni,nVlrDesc}} )
	
	If Select(cAliasTFW) > 0
		(cAliasTFW)->(dbCloseArea())
	EndIf

	If Select(cAliasTFX) > 0
		(cAliasTFX)->(dbCloseArea())
	EndIf

	If Select(cAliasTFY) > 0
		(cAliasTFY)->(dbCloseArea())
	EndIf

	If Select(cAliasTFZ) > 0
		(cAliasTFZ)->(dbCloseArea())
	EndIf				
			  
	TFJ->( DbSkip() )
		
EndDo



lSrvExt:= .F.

Return(aRet)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GerMed
Função para geração das medições do contrato
@sample 	At930GerMed()
@param		nenhum
@return	Nil 
@author	Serviços
@since		04/11/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function At930GerMed(cAlias, nReg, nOpc)
Local lPergunte := .F. //(nOpc == 3 .Or. Pergunte("TEC930",.T.))
Local nOperacao  := If(nOpc <> 3, MODEL_OPERATION_INSERT, MODEL_OPERATION_DELETE )  

Local cCodContrt := ' ' 
Local cContRevis := ' ' 
Local nOpcMed	 := 0
Local lIncAlt	 := INCLUI .OR. ALTERA  


If !lTeca934
	If lIncAlt 
		nOpcMed:= 	GSEscolha( 	STR0149					,; 	//"Tipo de Apuração/Medição"
					STR0150	,;  //"Selecione o tipo de Apuração/Medição que deseja processar"	
					{ STR0151, STR0152, STR0153 }	,;  //"Contrato Normal"//"Fora do Contrato"//"Orçamento Serv. Extra" 
					1 ) 
	Endif
	
	Do Case
		Case nOpcMed == 1
			lMedExt	:= .F.
			lSrvExt	:= .F.
		Case nOpcMed == 2
			lMedExt	:= .T.
		Case nOpcMed == 3
			lSrvExt	:= .T.	
	EndCase 
ELse
	nOpcMed := 1	
	lMedExt	:= .F.
	lSrvExt	:= .F.
Endif

If !(lIncAlt .And. nOpcMed == 0) .Or. !lIncAlt  

	If !lTeca934
		lPergunte := (nOpc == 3 .Or. Pergunte("TEC930",.T.)) 
	Else
		lPergunte := (nOpc == 3 .Or. Pergunte("TEC934",.T.))
	EndIf

	If lSrvExt 
		If Empty(MV_PAR05)
			lGeraMed := .F.
			MsgStop(STR0154,STR0155) //"Para essa opção o número do orçamento de serviços extra deve ser preenchido!"//"Atenção"
		Else
			lGeraMed := At930SrvExtVld(AllTrim(MV_PAR05)) // Valida se é orçamento de serviço extra e se foi efetivado.
		EndIf
		
		MV_PAR01 := Space(TamSX3("CN9_NUMERO")[1])
		
	EndIf

	If lPergunte
		cCodContrt := IIf( nOpc == 3, TFV->TFV_CONTRT, MV_PAR01 )
		cContRevis := Posicione("CN9",7,xFilial("CN9")+cCodContrt+"05","CN9_REVISA")
		// ---------------
		// Devolve a ordem 1 para a tabela CN9
		CN9->( DbSetOrder( 1 ) ) // CN9_FILIAL+CN9_NUMERO+CN9)REVISA
	
		If (lSrvExt .AND. Empty(cCodContrt)) .OR. At930VldCont( cCodContrt, cContRevis )
			MsgRun( STR0074, STR0073, {|| FWExecView(STR0002,"VIEWDEF.TECA930",nOperacao,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/) } ) // 'Processando Apuração  ' #### 'Aguarde...' #### "Geração"
		EndIf
	Endif
EndIf

// Reinicializa a variável static ao final do processo

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930VldCont
Função para geração das medições do contrato
@sample 	At930VldCont(cContrato)
@param		cContrato - Numero do contrato qual deseja validar
@return	Nil 
@author	Serviços
@since		04/11/2013       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Function At930VldCont( cContrato, cRevisao )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet := .T.
Local cAliasTFJ 	:= ""

If (Posicione("CN9",1,xFilial("CN9")+cContrato+cRevisao,"CN9_SITUAC") == "05")
	
	cAliasTFJ := GetNextAlias()
	//Verifica se o orçamento/contrato esta em processo de revisão
	
	BeginSQL Alias cAliasTFJ
		
		SELECT	TFJ.TFJ_CODIGO
		FROM 	%table:TFJ% TFJ
		WHERE 	TFJ.TFJ_FILIAL = %xFilial:TFJ% AND
				TFJ.TFJ_CONTRT = %exp:cContrato% AND
				TFJ.%NotDel% AND
				TFJ.TFJ_STATUS IN ('2','4') // DEF_TFJ_EMREVISAO, DEF_TFJ_AGDAPROVA
	EndSQL
				
	If (cAliasTFJ)->(!EOF())
	lRet := .F.
		Help( "", 1, "AT930VLDCONT1", , STR0112, 1, 0,,,,,,;  //"O contrato possui revisão em andamento para efetivação ou aprovação."
					{STR0113}) // "Termine o processo de revisão para realizar a apuração."
	EndIf
	
	(cAliasTFJ)->(dbCloseArea())
Else
	If !Empty(cContrato+cRevisao) // Se não for orçamento de Serv. Extra
	lRet := .F.
	Help(" ", 1, "AT930VLDCONT")
EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)
Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} InitDados
Inicializa as informações de status dos contratos
@sample 	InitDados()
@param  	oMdlGer, Objeto, objeto geral do model que será alterado
@return	Nil 
@author 	Serviços
@since		28/10/2013
@version	P11.90
/*/
//------------------------------------------------------------------------------
Static Function InitDados(oMdlGer)

Local oMdlTFV		:= oMdlGer:GetModel("TFVMASTER")
Local oStrTFITW6	:= oMdlGer:GetModel('TFITW6DETAIL'):GetStruct()
Local oStruTFW 		:= oMdlGer:GetModel('TFWDETAIL'):GetStruct()
Local aSaveRows 	:= {}
Local cRevCtr 		:= ""
Local aConfFat		:= {1,1}	
Local lA930Load		:=  ExistBlock("A930Load")				 

If oMdlGer:GetOperation() == MODEL_OPERATION_VIEW 
	If Empty(TFV->TFV_CONTRT)
		aConfFat	:= A930FatSep(TFV->TFV_ORCSRV, 1)
	Else
		aConfFat	:= A930FatSep(TFV->TFV_CONTRT, 2)
	EndIf
Else
	If lSrvExt
		aConfFat	:= A930FatSep(MV_PAR05, 1)
	Else
		aConfFat	:= A930FatSep(MV_PAR01, 2)
	EndIf
EndIf

nOpcDA	:= aConfFat[1]
nOpcHE	:= aConfFat[2]
	
aSaveRows := FwSaveRows()
				
If oMdlGer:GetOperation() == 3

	cRevCtr := Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")

	oMdlTFV:SetValue( "TFV_CONTRT", MV_PAR01  )
	oMdlTFV:SetValue( "TFV_REVISA", cRevCtr  )
	oMdlTFV:SetValue( "TFV_DTINI" , MV_PAR02  )
	oMdlTFV:SetValue( "TFV_DTFIM" , MV_PAR03  )
	oMdlTFV:SetValue( "TFV_DTAPUR", dDataBase )
	oMdlTFV:SetValue( "TFV_ORIGEM", IIF(lSrvExt, "TFJ", "CN9" ))
	If lSrvExt
		oMdlTFV:SetValue( "TFV_ORCSRV", MV_PAR05 )
	EndIf

	DbSelectArea("TFJ")
	TFJ->( DbSetOrder( 5 ) )  // TFJ_FILIAL + TFJ_CONTRT + TFJ_CONREV
	TFJ->( DbSeek( xFilial("TFJ") + MV_PAR01 + cRevCtr ) )
	oMdlTFV:SetValue( "TFV_ANTECI", If( TFJ->TFJ_ANTECI=="1", "1", "2" ) )

	// carrega primeiro os locais	
	At930ResLoc( oMdlGer, MV_PAR01, cRevCtr, MV_PAR05 )
	At930LoadMat()
	At930CaRH(MV_PAR01)
	At930LoEq(MV_PAR01,oMdlGer)
	At930GridZZP(oMdlGer)
	At930TrgGer( 'TFLDETAIL', 'TFL_VALTOT', 'ZZPDETAIL', 'ZZP_VLRTOT', 4 )	
	If lTeca934
		A930CarAnt(oMdlGer)//Carga dos valores de ultima medição
		At930LoAp(oMdlGer) //carrega a apuração ABX
	EndIf
	
	If lA930Load
		ExecBlock("A930Load",.F.,.F.,{oMdlGer})
	EndIf
	
Else
		
	At970SetHm()	// Inicializa os valores de medição/apuração de horimetro

	cRevCtr  := Posicione("CN9",7,xFilial("CN9")+oMdlTFV:GetValue("TFV_CONTRT")+"05","CN9_REVISA")	
	MV_PAR01 := oMdlTFV:GetValue("TFV_CONTRT")	
	MV_PAR02 := oMdlTFV:GetValue("TFV_DTINI")
	MV_PAR03 := oMdlTFV:GetValue("TFV_DTFIM")	
					
EndIf

// Carrega os dados para a aba de resumo dos locais
If	oMdlGer:GetOperation() == MODEL_OPERATION_VIEW   .OR.;
	oMdlGer:GetOperation() == MODEL_OPERATION_INSERT .OR.;
	oMdlGer:GetOperation() == MODEL_OPERATION_UPDATE
	At930ResView( oMdlGer )
EndIf

FwRestRows( aSaveRows )

oMdlGer:GetModel("ZZPDETAIL"):SetNoInsertLine(.T.)

oMdlGer:GetModel("TFWDETAIL"):SetNoInsertLine(.T.)
oMdlGer:GetModel("TFWDETAIL"):SetNoDeleteLine(.T.)

oMdlGer:GetModel("TFXDETAIL"):SetNoInsertLine(.T.)
oMdlGer:GetModel("TFXDETAIL"):SetNoDeleteLine(.T.)

oMdlGer:GetModel("TFYDETAIL"):SetNoInsertLine(.T.)
oMdlGer:GetModel("TFYDETAIL"):SetNoDeleteLine(.T.)

oMdlGer:GetModel("TFIPRODUT"):SetNoInsertLine(.T.)
oMdlGer:GetModel("TFIPRODUT"):SetNoDeleteLine(.T.)

oMdlGer:GetModel("TFLDETAIL"):SetNoInsertLine(.T.)
oMdlGer:GetModel("TFLDETAIL"):SetNoDeleteLine(.T.)

oMdlGer:GetModel("TFZDETAIL"):SetNoInsertLine(.T.)
oMdlGer:GetModel("TFZDETAIL"):SetNoDeleteLine(.T.) 

oStrTFITW6:SetProperty("TW6_VALOR", MODEL_FIELD_OBRIGAT, .F.)

If oMdlGer:GetOperation() == MODEL_OPERATION_VIEW
	oMdlGer:lModify := .F.
EndIf

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930DetRH
Tela de detalhes das informações adicionais dos Recursos Humanos utilizados no contrato
@sample 	At930DetRH()
@return	Nil 
@author 	Serviços
@since		06/11/2013
@version	P11.90
/*/
//------------------------------------------------------------------------------
Static Function At930DetRH()

Local cTitulo	  := STR0012 // "Detalhe "

Local oOk					//Objeto Confirma
Local oTop 				//Objeto Panel
Local oSup1
Local oInf1
Local oSup2
Local oInf2
Local oBottom
Local oPanel
Local oDlgCmp
Local oFolder
Local aFolder	:= {STR0013,STR0014}  // "Horas" # "Horas Extras"
Local oListBox			//Grid campos Horas
Local oListBox2			//Grid campos Horas Extras
Local oListBox3			//Grid campos Horas Extras totalizador
Local aCmpDet	  := {}
Local aCmpHrE	  := {}
Local aCmpOsE   := {}
Local aRetDet   := {}
Local oModel	  := FWModelActive()
Local oModelTFW := oModel:GetModel("TFWDETAIL")
Local cIdApur   := ""

If oModelTFW:GetOperation() == 5 // Estorno da apuracao
	cIdApur := FwFldGet("TFV_CODIGO")
EndIf

cTitulo += STR0007 // "Recursos Humanos"

// Processamento de todos os dados do detalhe do recurso humano
aRetDet := At930QDetRH( MV_PAR01, MV_PAR02, MV_PAR03,; 
						  FwFldGet("TFW_CODTFF"), FwFldGet("TFW_CODTFL"), cIdApur )

aCmpDet := aRetDet[1][1] // O.S. Horas normais
aCmpOsE := aRetDet[1][2] // O.S. Horas extras
aCmpHrE := aRetDet[1][3] // Total hora extra por motivo

If Len(aCmpHrE) = 0
	aAdd(aCmpHrE, {"","","","",""})
EndIf

If Len(aCmpOsE) = 0
	aAdd(aCmpOsE, {"","","","","","","","","","","","","","","",""})
EndIf 

If !Empty(aCmpDet)

	//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
	Define MsDialog oDlgCmp TITLE cTitulo FROM 000, 000 To 600, 1100 Pixel		
	
	// Cria o panel as informaçoes do local e total
	@ 000, 000 MsPanel oTop Of oDlgCmp Size 000, 040 // Coordenada para o panel
	oTop:Align := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
		
	@ 005,005 SAY STR0015 OF oTop PIXEL SIZE 120,9  // "Contrato"
	@ 015,005 MsGet aCmpDet[1][09] OF oTop SIZE 60,10 PIXEL WHEN .F.
	@ 005,075 SAY STR0016 OF oTop PIXEL SIZE 120,9 // "Revisão"
	@ 015,075 MsGet aCmpDet[1][10] OF oTop SIZE 20,10 PIXEL WHEN .F.
	@ 005,105 SAY STR0004 OF oTop PIXEL SIZE 120,9 // "Local"
	@ 015,105 MsGet aCmpDet[1][11] OF oTop SIZE 40,10 PIXEL WHEN .F.
	@ 005,155 SAY STR0005 OF oTop PIXEL SIZE 120,9 // "Descrição"
	@ 015,155 MsGet aCmpDet[1][12] OF oTop SIZE 190,10 PIXEL WHEN .F.
	
	oFolder	:=	TFolder():New(0,0,aFolder,aFolder,oDlgCmp,,,,.T., , 354, 200) 
	oFolder:Align := CONTROL_ALIGN_ALLCLIENT
	
	@ 000, 000 MsPanel oSub1 Of oFolder:aDialogs[1] Size 000,040
	oSub1:Align := CONTROL_ALIGN_TOP
	
	@ 005,005 SAY STR0017 OF oSub1 PIXEL SIZE 60,9 // "Horas Normais:"
	@ 015,005 MsGet FWFLDGET("TFW_HORAN") OF oSub1 SIZE 60,10 PIXEL WHEN .F.
	
	@ 005,075 SAY STR0018 OF oSub1 PIXEL SIZE 60,9 // "Valor Hr Normal:"
	@ 015,075 MsGet FWFLDGET("TFW_VLHORN") OF oSub1 SIZE 60,10 PICTURE "@E 9,999,999,999.99" PIXEL WHEN .F.
	
	@ 005,145 SAY STR0019 OF oSub1 PIXEL SIZE 60,9 // "Horas Extras:"
	@ 015,145 MsGet FWFLDGET("TFW_HORAE") OF oSub1 SIZE 60,10 PIXEL WHEN .F.
	
	@ 005,215 SAY STR0020 OF oSub1 PIXEL SIZE 60,9 // "Valor Hr Extra"
	@ 015,215 MsGet FWFLDGET("TFW_VLHORE") OF oSub1 SIZE 60,10 PICTURE "@E 9,999,999,999.99" PIXEL WHEN .F. //FWFLDGET REALMENTE ATENDE?
	
	@ 050, 000 MsPanel oInf1 Of oFolder:aDialogs[1] Size 000,030
	oInf1:Align := CONTROL_ALIGN_ALLCLIENT
	
	// Criação do grid para o panel	
	oListBox := TWBrowse():New(000,000,000,000,,{STR0021,STR0022,STR0023,STR0024,STR0025,STR0026,STR0027,STR0028,; 
												      STR0029,STR0030},,oInf1,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
 													// "OS"#"Seq"#"Horas"#"Data Emissão"#"Data Chegada"#"Hora Chegada"#
 													//"Data Saída"#"Hora Saída"#"Cód. Atendente"#"Atendente"												      
												       	  
	oListBox:SetArray(aCmpDet) // Atrela os dados do grid com a matriz	
	oListBox:bLine := { ||{aCmpDet[oListBox:nAT][1],;
							  aCmpDet[oListBox:nAT][2],;
							  aCmpDet[oListBox:nAT][3],;
							  aCmpDet[oListBox:nAT][4],;
							  aCmpDet[oListBox:nAT][5],;
							  aCmpDet[oListBox:nAT][6],;
							  aCmpDet[oListBox:nAT][7],;
							  aCmpDet[oListBox:nAT][8],;
							  aCmpDet[oListBox:nAT][13],;
							  aCmpDet[oListBox:nAT][14]}} // Indica as linhas do grid	
	oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
	
	@ 000, 000 MsPanel oSub2 Of oFolder:aDialogs[2] Size 000,100
	oSub2:Align := CONTROL_ALIGN_TOP
	
	// Criação do grid do totalizador de horas extas	
	oListBox3 := TWBrowse():New(000,000,000,000,,{STR0031,STR0032,STR0023,STR0054,STR0034},,oSub2,,,,,,,,,,,,.F.,,.T.,,.F.,,,) 	  
												      // "Motivo"#"Descrição"#"Horas"#"Valor Hora"#"Valor"
 													
	oListBox3:SetArray(aCmpHrE) // Atrela os dados do grid com a matriz
	oListBox3:bLine := { ||{aCmpHrE[oListBox3:nAT][1],;
							  aCmpHrE[oListBox3:nAT][2],;
							  aCmpHrE[oListBox3:nAT][3],;
							  aCmpHrE[oListBox3:nAT][4],;
							  aCmpHrE[oListBox3:nAT][5]}} // Indica as linhas do grid	
	oListBox3:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse

	@ 050, 000 MsPanel oInf2 Of oFolder:aDialogs[2] Size 000,030
	oInf2:Align := CONTROL_ALIGN_ALLCLIENT	
	
	// Criação do grid para o panel	
	oListBox2 := TWBrowse():New(000,000,000,000,,{ STR0021,STR0022,STR0031,STR0032,STR0023,STR0024,STR0025,STR0026,STR0027,STR0028,; 
												      STR0029,STR0030},,oInf2,,,,,,,,,,,,.F.,,.T.,,.F.,,,) 	  
												      // "OS"#"Seq"#"Horas"#"Data Emissão"#"Data Chegada"#"Hora Chegada"#
 													//"Data Saída"#"Hora Saída"#"Cód. Atendente"#"Atendente"
 													
	oListBox2:SetArray(aCmpOsE) // Atrela os dados do grid com a matriz
	oListBox2:bLine := { ||{aCmpOsE[oListBox2:nAT][1],;
							  aCmpOsE[oListBox2:nAT][2],;
							  aCmpOsE[oListBox2:nAT][3],;
							  aCmpOsE[oListBox2:nAT][4],;
							  aCmpOsE[oListBox2:nAT][5],;
							  aCmpOsE[oListBox2:nAT][6],;
							  aCmpOsE[oListBox2:nAT][7],;
							  aCmpOsE[oListBox2:nAT][8],;
							  aCmpOsE[oListBox2:nAT][9],;
							  aCmpOsE[oListBox2:nAT][10],;
							  aCmpOsE[oListBox2:nAT][15],;
							  aCmpOsE[oListBox2:nAT][16]}} // Indica as linhas do grid	
	oListBox2:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
	
	// Cria o panel para o botao OK	
	@ 000, 000 MsPanel oBottom Of oDlgCmp Size 000, 012 // Corrdenada para o panel dos botoes (size)
	oBottom:Align := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)

	// Botao de acao OK	
	@ 000, 000 Button oOk Prompt STR0035  Of oBottom Size 030, 000 Pixel //"Ok"
	oOk:bAction := { || oDlgCmp:End() }
	oOk:Align   := CONTROL_ALIGN_RIGHT	
		
	// Ativa a tela exibindo conforme a coordenada
	Activate MsDialog oDlgCmp Centered
	
Else

	Help(" ", 1, "AT930DETRH")
	
EndIf
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930DetMat
Tela de detalhes das informações adicionais dos materiais utilizados no contrato
@sample 	At930DetMat(nTipo,cCodRel)
@param  	nTipo   - 1 = Materiais de Implantacao / 2 = Materiais de Consumo
@param  	cCodRel - Codigo do relacionamento para levantamentos dos dados adicionais
			dos produtos.
@return	Nil 
@author 	Serviços
@since		06/11/2013
@version	P11.90
/*/
//------------------------------------------------------------------------------
Static Function At930DetMat(nTipo,cCodRel)

Local aOldArea	:= GetArea()
Local cAliasMat	:= GetNextAlias()
Local aCmpDet		:= {}
Local oModel		:= FwModelActive()
Local cTitulo		:= STR0012 // "Detalhe "
Local cLocal		:= ""
Local cIdApur		:= ""
Local cCodTFF		:= ""
Local cWhereCob	:= ""
Local cChvTFL   := ""
Local nTotalApu
Local oListBox			//Grid campos
Local oOk					//Objeto Confirma
Local oTop 				//Objeto Panel
Local oMiddle
Local oBottom
Local oDlgCmp
Local cRevCtr		:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
Default cCodRel := ""

If oModel:GetOperation() == 5 // Estorno da apuracao
	cIdApur := FwFldGet("TFV_CODIGO")
EndIf

If nTipo == 1 // Materiais de implantacao

	cLocal    := FwFldGet("TFX_LOCAL")	
	nTotalApu := FwFldGet("TFX_VLRAPU")
	cCodTFF   := FwFldGet("TFX_CODTFF")	
	cTitulo 	+= STR0008 // "Materiais de implantacao"
	
	If lSrvExt
		//cWhereCob := "%TFG.TFG_COBCTR = '2' AND TFG.TFG_PRCVEN > 0%" 
		cWhereCob += "%TFG.TFG_TIPMAT = '3' %"
		cChvTFL   := "%TFL.TFL_CODPAI = '" + MV_PAR05 + "'%"
	Else
		If lMedExt
			cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
			cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND " 
			cWhereCob += "TFG.TFG_TIPMAT = '2' %"
			//cWhereCob += "TFG.TFG_COBCTR = '2' AND TFG.TFG_PRCVEN > 0%" 
		Else
			cWhereCob := "%TFF.TFF_CONTRT = '" + MV_PAR01 + "' AND "
			cWhereCob += "TFF.TFF_CONREV = '" + cRevCtr + "' AND " 
			cWhereCob += "TFG.TFG_TIPMAT = '3' %"
			//cWhereCob += "TFG.TFG_COBCTR <> '2' %"
		EndIf
		cChvTFL := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
		cChvTFL += " TFL.TFL_CONREV = '" + cRevCtr  + "'%"
	EndIf
	
	BeginSql Alias cAliasMat
	
		SELECT TFF.TFF_CONTRT CONTRT, TFF.TFF_CONREV CONREV, TFF.TFF_LOCAL LOCCONT, ABS.ABS_DESCRI DESCLOC,
		       TFS.TFS_DTAPON DTAPON, TFG.TFG_PRODUT PRODUT, SB1.B1_DESC DESCP,     TFS.TFS_QUANT QUANT,
		       TFG.TFG_PRCVEN PRCVEN,
		       ( TFS.TFS_QUANT *
		         ( TFG.TFG_PRCVEN -
		             (((TFG.TFG_PRCVEN * TFG.TFG_DESCON)/100)) +
		             ((TFG.TFG_PRCVEN * TFG.TFG_LUCRO)/100) +
		             ((TFG.TFG_PRCVEN * TFG.TFG_ADM)/100) ) ) VLR_TOTAL
		  FROM %table:TFS% TFS
		       JOIN %table:TFG% TFG ON TFG.TFG_FILIAL = %xFilial:TFG%
		                           AND TFS.TFS_CODTFG = TFG.TFG_COD
		                           AND TFG.%NotDel%
		       LEFT JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1%
		                                AND SB1.B1_COD = TFG.TFG_PRODUT
		                                AND SB1.%NotDel%
		       LEFT JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                                AND TFF.TFF_COD = TFG.TFG_CODPAI
		                                AND TFF.TFF_COD = %Exp:cCodTFF%
		                                AND TFF.%NotDel%
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                AND ABS.ABS_LOCAL = TFF.TFF_LOCAL
		                                AND ABS.%NotDel%		
		       LEFT JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                                AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
		                                AND TFL.TFL_CONTRT = %Exp:MV_PAR01%         
										AND %Exp:cChvTFL%
										AND TFL.%NotDel% 
		 WHERE TFS.TFS_FILIAL = %xFilial:TFS%
		   AND RTrim(LTrim(TFS.TFS_ITAPUR)) = %Exp:cIdApur%
		   AND TFS.TFS_DTAPON >= %Exp:MV_PAR02%
		   AND TFS.TFS_DTAPON <= %Exp:MV_PAR03%
		   AND TFF.TFF_LOCAL = %Exp:cLocal%
		   AND TFS.%NotDel%
		   AND %Exp:cWhereCob%

	EndSql
	
ElseIf nTipo == 2 // Materiais de consumo
		
	cLocal    := FwFldGet("TFY_LOCAL")
	nTotalApu := FwFldGet("TFY_VLRAPU")
	cCodTFF   := FwFldGet("TFY_CODTFF")	
	cTitulo 	+= STR0009 // "Materiais de consumo"
	
	If lSrvExt
		cWhereCob += "%TFH.TFH_TIPMAT = '3' %"
		//cWhereCob := "%TFH.TFH_COBCTR = '2' AND TFH.TFH_PRCVEN > 0%" 
		cChvTFL   := "%TFL.TFL_CODPAI = '" + MV_PAR05 + "'%"
	Else
		If lMedExt
			cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
			cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND "
			cWhereCob += "TFH.TFH_TIPMAT = '2' %"
			//cWhereCob += "TFH.TFH_COBCTR = '2' AND TFH.TFH_PRCVEN > 0%" 
		Else
			cWhereCob := "%TFF.TFF_CONTRT = '" + MV_PAR01 + "' AND "
			cWhereCob += "TFF.TFF_CONREV = '" + cRevCtr + "' AND " 
	 		cWhereCob += "TFH.TFH_TIPMAT = '3' %"
	 		//cWhereCob += "TFH.TFH_COBCTR <> '2' %"
		EndIf
		cChvTFL := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
		cChvTFL += " TFL.TFL_CONREV = '" + cRevCtr  + "' AND "
	EndIf
	
	BeginSql Alias cAliasMat
	
		SELECT TFF.TFF_CONTRT CONTRT, TFF.TFF_CONREV CONREV, TFF.TFF_LOCAL LOCCONT, ABS.ABS_DESCRI DESCLOC, 
		       TFT.TFT_DTAPON DTAPON, TFH.TFH_PRODUT PRODUT, SB1.B1_DESC DESCP,     TFT.TFT_QUANT QUANT,
		       TFH.TFH_PRCVEN PRCVEN,
		       ( TFT.TFT_QUANT *
		         ( TFH.TFH_PRCVEN -
		             (((TFH.TFH_PRCVEN * TFH.TFH_DESCON)/100)) + 
		             ((TFH.TFH_PRCVEN * TFH.TFH_LUCRO)/100) +
		             ((TFH.TFH_PRCVEN * TFH.TFH_ADM)/100) ) ) VLR_TOTAL

		  FROM %table:TFT% TFT
		       JOIN %table:TFH% TFH ON TFH.TFH_FILIAL = %xFilial:TFH%
		                           AND TFT.TFT_CODTFH = TFH.TFH_COD
		                           AND TFH.%NotDel%
		       LEFT JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1%
		                                AND SB1.B1_COD = TFH.TFH_PRODUT
		                                AND SB1.%NotDel%
		       LEFT JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                                AND TFF.TFF_COD = TFH.TFH_CODPAI
		                                AND TFF.TFF_COD = %Exp:cCodTFF%
		                                AND TFF.%NotDel%
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                AND ABS.ABS_LOCAL = TFF.TFF_LOCAL
		                                AND ABS.%NotDel%
		       LEFT JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                                AND TFL.TFL_CODIGO = TFF.TFF_CODPAI		                                      
										AND %Exp:cChvTFL%
										AND TFL.%NotDel% 
		 WHERE TFT.TFT_FILIAL = %xFilial:TFT%
		   AND RTrim(LTrim(TFT.TFT_ITAPUR)) = %Exp:cIdApur%
		   AND TFT.TFT_DTAPON >= %Exp:MV_PAR02%
		   AND TFT.TFT_DTAPON <= %Exp:MV_PAR03%
		   AND TFF.TFF_LOCAL = %Exp:cLocal%
		   AND TFT.%NotDel%
		   AND %Exp:cWhereCob%

	EndSql

EndIf 

While (cAliasMat)->(!Eof())		

	aAdd( aCmpDet, { StoD((cAliasMat)->DTAPON), (cAliasMat)->PRODUT,;
					   (cAliasMat)->DESCP,   (cAliasMat)->QUANT,;
					   (cAliasMat)->PRCVEN,  (cAliasMat)->VLR_TOTAL,;
					   (cAliasMat)->CONTRT,  (cAliasMat)->CONREV,;
					   (cAliasMat)->LOCCONT, (cAliasMat)->DESCLOC  } )
	
	(cAliasMat)->(dbSkip())
	
EndDo

If Len(aCmpDet) > 0

	//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
	Define MsDialog oDlgCmp TITLE cTitulo FROM 000, 000 To 450, 700 Pixel		
	
	// Cria o panel as informaçoes do local e total
	@ 000, 000 MsPanel oTop Of oDlgCmp Size 000, 070 // Coordenada para o panel
	oTop:Align := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
	@ 005,005 SAY STR0015 OF oTop PIXEL SIZE 120,9 // "Contrato"
	@ 015,005 MsGet aCmpDet[1][07] OF oTop SIZE 60,10 PIXEL WHEN .F.
	@ 005,075 SAY STR0016 OF oTop PIXEL SIZE 120,9 // "Revisão"
	@ 015,075 MsGet aCmpDet[1][08] OF oTop SIZE 20,10 PIXEL WHEN .F.
	@ 005,105 SAY STR0004 OF oTop PIXEL SIZE 120,9 // "Local"
	@ 015,105 MsGet aCmpDet[1][09] OF oTop SIZE 40,10 PIXEL WHEN .F.
	@ 005,155 SAY STR0005 OF oTop PIXEL SIZE 120,9 // "Descrição"
	@ 015,155 MsGet aCmpDet[1][10] OF oTop SIZE 190,10 PIXEL WHEN .F.
	
	@ 035,005 SAY STR0036 OF oTop PIXEL SIZE 120,9 // "Total apurado"
	@ 045,005 MsGet nTotalApu OF oTop SIZE 60,10 PICTURE "@E 9,999,999,999.99" PIXEL WHEN .F. 
			
	// Cria o panel o browse dos itens dos materiais
	@ 000, 000 MsPanel oMiddle Of oDlgCmp Size 000, 150 // Coordenada para o panel
	oMiddle:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)	
		
	// Criação do grid para o panel	
	oListBox := TWBrowse():New(000,000,000,000,,{STR0037,STR0038,STR0005,STR0038,STR0040,;
													   STR0041},,oMiddle,,,,,,,,,,,,.F.,,.T.,,.F.,,,)
												      //"Data"#"Produto"#"Descrição"#"Quant."#"Vlr.Unitario"#"Vlr.Total"	
												       	  
	oListBox:SetArray(aCmpDet) // Atrela os dados do grid com a matriz
	oListBox:bLine := { ||{aCmpDet[oListBox:nAT][1],;
							  aCmpDet[oListBox:nAT][2],;
							  aCmpDet[oListBox:nAT][3],;
							  aCmpDet[oListBox:nAT][4],;
							  aCmpDet[oListBox:nAT][5],;
							  aCmpDet[oListBox:nAT][6]}} // Indica as linhas do grid	
	oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
	
	// Cria o panel para o botao OK	
	@ 000, 000 MsPanel oBottom Of oDlgCmp Size 000, 012 // Corrdenada para o panel dos botoes (size)
	oBottom:Align := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
	// Botao de acao OK	
	@ 000, 000 Button oOk Prompt STR0035  Of oBottom Size 030, 000 Pixel //Ok
	oOk:bAction := { || oDlgCmp:End() }
	oOk:Align   := CONTROL_ALIGN_RIGHT	
		
	// Ativa a tela exibindo conforme a coordenada
	Activate MsDialog oDlgCmp Centered
	
Else

	Help(" ", 1, "AT930DETMAT")

EndIf

(cAliasMat)->(DbCloseArea())
RestArea(aOldArea)		
Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930DetLoc
Load das informações da tela de detalhes Locação de Equipamento
@sample 	At930DetLoc() 
@param		Nenhum
@return	ExpL	Nil
@since		22/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------
Static Function At930DetLoc()

Local aOldArea	:= GetArea()
Local aCmpDet		:= {}
Local cTitulo		:= STR0012 // "Detalhe "
Local cAliasTEW	:= ""
Local cLocalABS	:= ""
Local oListBox			//Grid campos
Local oOk					//Objeto Confirma
Local oTop 				//Objeto Panel
Local oMiddle
Local oBottom
Local oDlgCmp
Local cMotivo		:= ""
Local cQuery		:= ""

cTitulo			+= STR0010 // "Locação de Equipamentos"
DbSelectArea("TEW")
DbsetOrder(1)	
cAliasTEW			:= GetNextAlias()

cQuery		:= "SELECT TEW.TEW_MOTIVO, TEW.TEW_CODMV, TEW.TEW_PRODUT, TEW.TEW_DTRINI, TEW.TEW_DTRFIM, TEW.TEW_SUBSTI, TEW.TEW_BAATD,  TEW.TEW_QTDVEN"
cQuery		+= " FROM " + RetSQLName("TEW") + " TEW "
cQuery		+= " WHERE TEW_CODEQU = '"+FWFLDGET("TFI_COD")+"' AND "
cQuery		+= " TEW_FILIAL = '" + xFilial("TEW")+"' AND "		
cQuery		+= " TEW.TEW_DTRINI <= '"+DTOS(FWFLDGET("TFV_DTFIM"))+"' AND "
cQuery		+= " ( "
cQuery		+= " (LTRIM(RTRIM(TEW.TEW_DTRFIM)) = ' ' OR TEW.TEW_DTRFIM >= '"+DTOS(FWFLDGET("TFV_DTINI"))+"') AND "
cQuery		+= " (LTRIM(RTRIM(TEW.TEW_DTAMNT)) = ' ' OR TEW.TEW_DTAMNT >= '"+DTOS(FWFLDGET("TFV_DTINI"))+"') "
cQuery		+= " ) AND "	
cQuery		+= " TEW.D_E_L_E_T_ = ' ' "
	
cQuery		:= ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN",TcGenQry(,,cQuery), cAliasTEW, .T., .T.)
	
TcSetField( cAliasTEW, 'TEW_DTRFIM', 'D', 8, 0 )
TcSetField( cAliasTEW, 'TEW_DTRINI', 'D', 8, 0 )
	
While (cAliasTEW)->(!Eof())		
	If (cAliasTEW)->TEW_MOTIVO == "1"
		cMotivo:= STR0088 //"Substituição"
	ElseIf (cAliasTEW)->TEW_MOTIVO == "2"
		cMotivo:= STR0089 //"Cancelamento"
	Else
		cMotivo:=""
	EndIf
	aAdd( aCmpDet, { (cAliasTEW)->TEW_CODMV,;
	                 (cAliasTEW)->TEW_PRODUT,;
	                 Posicione("SB1",1,xFilial("SB1")+(cAliasTEW)->TEW_PRODUT,"B1_DESC"),;
	                 (cAliasTEW)->TEW_BAATD,;
	                 (cAliasTEW)->TEW_DTRINI,;
	                 (cAliasTEW)->TEW_DTRFIM,;
	                 (cAliasTEW)->TEW_SUBSTI,;
	                 cMotivo,;
	                 (cAliasTEW)->TEW_QTDVEN})
					   
	(cAliasTEW)->(DbSkip())				
EndDo

If !Empty(aCmpDet)

	//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
	Define MsDialog oDlgCmp TITLE cTitulo FROM 000, 000 To 450, 700 Pixel		
	
	// Cria o panel as informaçoes do local e total
	@ 000, 000 MsPanel oTop Of oDlgCmp Size 000, 070 // Coordenada para o panel
	oTop:Align := CONTROL_ALIGN_TOP //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
	@ 005,005 SAY STR0015 OF oTop PIXEL SIZE 120,9 // "Contrato"
	@ 015,005 MsGet FWFLDGET("TFV_CONTRT") OF oTop SIZE 60,10 PIXEL WHEN .F.
	cLocalABS:= Posicione("TFL",1,xFilial("TFL")+FWFLDGET("TFZ_CODTFL"),"TFL_LOCAL")
	@ 005,105 SAY STR0004 OF oTop PIXEL SIZE 120,9 // "Local"
	@ 015,105 MsGet cLocalABS OF oTop SIZE 40,10 PIXEL WHEN .F.
	@ 005,155 SAY STR0005 OF oTop PIXEL SIZE 120,9 // "Descrição"
	@ 015,155 MsGet Posicione("ABS",1,xFilial("ABS")+cLocalABS,"ABS_DESCRI") OF oTop SIZE 190,10 PIXEL WHEN .F.
			
	// Cria o panel o browse dos itens dos materiais
	@ 000, 000 MsPanel oMiddle Of oDlgCmp Size 000, 150 // Coordenada para o panel
	oMiddle:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)	
		
	// Criação do grid para o panel	
	oListBox := TWBrowse():New(000,000,000,000,,{	STR0042,;												//"Movimentações"
														STR0038,;												//"Produto"
														STR0005,;												//"Descrição"
														STR0099,;												//"Base Atend."
														STR0043,;												//"Data Inicial"
														STR0044,;												//"Data Final"
														STR0045,;												//"Substituto"
														STR0046,;
														'Quantidade'},,oMiddle,,,,,,,,,,,,.F.,,.T.,,.F.,,,)	//"Motivo da Substituição"

	oListBox:SetArray(aCmpDet) // Atrela os dados do grid com a matriz
	oListBox:bLine := { ||{aCmpDet[oListBox:nAT][1],;
							  aCmpDet[oListBox:nAT][2],;
							  aCmpDet[oListBox:nAT][3],;
							  aCmpDet[oListBox:nAT][4],;
							  aCmpDet[oListBox:nAT][5],;
							  aCmpDet[oListBox:nAT][6],;
							  aCmpDet[oListBox:nAT][7],;
							  aCmpDet[oListBox:nAT][8],; // Indica as linhas do grid
							  aCmpDet[oListBox:nAT][9]}} // Indica as linhas do grid
	oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
	
	// Cria o panel para o botao OK	
	@ 000, 000 MsPanel oBottom Of oDlgCmp Size 000, 012 // Corrdenada para o panel dos botoes (size)
	oBottom:Align := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	
	// Botao de acao OK	
	@ 000, 000 Button oOk Prompt STR0035  Of oBottom Size 030, 000 Pixel //Ok
	oOk:bAction := { || oDlgCmp:End() }
	oOk:Align   := CONTROL_ALIGN_RIGHT	
		
	// Ativa a tela exibindo conforme a coordenada
	Activate MsDialog oDlgCmp Centered
Else
	Help(" ", 1, "AT930DETMAT")
EndIf

(cAliasTEW)->(DbCloseArea())				
RestArea(aOldArea)
Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930LoadMat
Carga de dados para os grid de materiais de implantação e consumo
@sample 	At930LoadMat()
@param  	Nenhum
@return	Nil 
@author 	Serviços
@since		07/11/2013
@version	P11.90
/*/
//------------------------------------------------------------------------------
Static Function At930LoadMat() 

Local aOldArea	:= GetArea()
Local cAliasIMI	:= GetNextAlias()
Local cAliasIMC	:= GetNextAlias()
Local oMdlAtivo	:= FwModelActive()
Local oMdlIMI		:= oMdlAtivo:GetModel("TFXDETAIL")
Local oMdlIMC		:= oMdlAtivo:GetModel("TFYDETAIL")
Local nDifDias	:= 0
Local nDifCalc	:= 0
Local nPerCalc	:= 0
Local cWhereCob	:= ""
Local cRevCtr		:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
Local lOrcPrc		:= SuperGetMv("MV_ORCPRC",,.F.)
Local cTipoOrc	:= If( lOrcPrc, '0', '1' ) // identifica o tipo de orçamento sendo utilizado para condicionar o relacionamento com TFF e TFL
Local dDtIni 	:= MV_PAR02
Local dDtFim 	:= MV_PAR03
Local lApuApt	:= SuperGetMv("MV_APUAPT",,.F.)
//grupo de Faturamento
Local lGrpFatOrc:= TFJ->TFJ_GRPFAT== "1"
Local cPlanMC	:= ""
Local cPlanMI	:= ""
Local dDtIniApu	:= MV_PAR02 
Local dDtFimApu	:= MV_PAR03

If lTeca934 //ajustar data da apuração para mês anterior
		dDtIniApu	:= MV_PAR05 
		dDtFimApu	:= MV_PAR06
EndIf

If lSrvExt
	cWhereCob := "%TFL.TFL_CODPAI = '" + MV_PAR05 + "' AND "
	cWhereCob += "TFG.TFG_TIPMAT = '3' %"
	//cWhereCob += " TFG.TFG_COBCTR = '2' AND TFG.TFG_PRCVEN > 0%" 
ElseIf lMedExt
	cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
	cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND "
	cWhereCob += "TFG.TFG_TIPMAT = '2' %"
	//cWhereCob += "TFG.TFG_TIPMAT = '2' %" 
	//cWhereCob += "TFG.TFG_COBCTR = '2' AND TFG.TFG_PRCVEN > 0%" 
Else
	cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
	cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND " 
	cWhereCob += "TFG.TFG_TIPMAT = '3' %"
 	//cWhereCob += "TFG.TFG_COBCTR <> '2' %"
EndIf

// Materiais de Implantação
BeginSql Alias cAliasIMI
	
	SELECT TFL.TFL_CODIGO, TFL.TFL_LOCAL, ABS.ABS_DESCRI, TFG.TFG_PERINI, TFG.TFG_PERFIM,
	       SUM(TFG.TFG_VALDES) VAL_DSC, SUM(TFS.TFS_QUANT) QUANTIDADE, TFG.TFG_COD,
	       ( SELECT SUM( (TFG2.TFG_QTDVEN * 
	                      (TFG2.TFG_PRCVEN - ((TFG2.TFG_PRCVEN * TFG2.TFG_DESCON)/100) 
	                                       + ((TFG2.TFG_PRCVEN * TFG2.TFG_LUCRO)/100)
	                                       + ((TFG2.TFG_PRCVEN * TFG2.TFG_ADM)/100)) ))
	            FROM %table:TFG% TFG2
	           WHERE TFG2.TFG_FILIAL = %xFilial:TFG%
	             AND TFG2.%NotDel%
	             AND TFG2.TFG_COD = TFG.TFG_COD 	             
	           GROUP BY TFG2.TFG_FILIAL,TFG2.TFG_LOCAL, TFG2.TFG_CODPAI
	       ) VLR_CONT,			

 		   ( SELECT SUM( (TFS2.TFS_QTDKIT * 
 		   				  (TFG3.TFG_PRCVEN - ((TFG3.TFG_PRCVEN * TFG3.TFG_DESCON)/100)
 		   				  				   + ((TFG3.TFG_PRCVEN * TFG3.TFG_LUCRO)/100) 
 		   				  				   + ((TFG3.TFG_PRCVEN * TFG3.TFG_ADM)/100) )))
   			   FROM %table:TFG% TFG3
  					LEFT JOIN  ( SELECT TFS.TFS_FILIAL, TFS.TFS_CODTFG,TFS.TFS_QTDKIT
  									FROM %table:TFG% TFG
  										LEFT JOIN %table:TFS% TFS ON TFS.TFS_FILIAL = %xFilial:TFS%
											AND TFS.TFS_CODTFG = TFG.TFG_COD
 										    AND RTrim(LTrim(TFS.TFS_ITAPUR)) = ' '
				                            AND TFS.TFS_DTAPON >= %Exp:dDtIniApu%
				                            AND TFS.TFS_DTAPON <= %Exp:dDtFimApu%
				                            AND TFS.%NotDel% 
	     						 GROUP BY TFS.TFS_FILIAL, TFS.TFS_CODTFG,TFS.TFS_QTDKIT
	     						 ) TFS2 ON TFS2.TFS_FILIAL = %xFilial:TFS%
 									    AND TFS2.TFS_CODTFG = TFG.TFG_COD
  			   WHERE TFG3.TFG_FILIAL = %xFilial:TFG%
			     AND TFG3.%NotDel% 
     			 AND TFG3.TFG_COD = TFG.TFG_COD
   			   GROUP BY TFG3.TFG_FILIAL,TFG3.TFG_LOCAL,TFG3.TFG_CODPAI
   		   ) VLR_APUKIT,

 	       SUM( TFS.TFS_QUANT * 
 	            (TFG.TFG_PRCVEN - ((TFG.TFG_PRCVEN * TFG.TFG_DESCON)/100)
	                            + ((TFG.TFG_PRCVEN * TFG.TFG_LUCRO)/100)
	                            + ((TFG.TFG_PRCVEN * TFG.TFG_ADM)/100) )) VLR_APU,
	       TFF.TFF_COD, TFG.TFG_PRODUT, SB1.B1_DESC
	FROM %table:TFG% TFG		
	     LEFT JOIN %table:TFS% TFS ON TFS.TFS_FILIAL = %xFilial:TFS%
	                              AND TFS.TFS_CODTFG = TFG.TFG_COD
	                              AND TFS.TFS_PEND = 'N'
	                              AND RTrim(LTrim(TFS.TFS_ITAPUR)) = ' '
	                              AND TFS.TFS_DTAPON >= %Exp:dDtIniApu%
	                              AND TFS.TFS_DTAPON <= %Exp:dDtFimApu%
	                              AND TFS.%NotDel%
	     LEFT JOIN %table:TFF% TFF ON '1' = %exp:cTipoOrc%
	                              AND TFF.TFF_FILIAL = %xFilial:TFF%
	                              AND TFF.TFF_COD = TFG.TFG_CODPAI
	                              AND TFF.%NotDel%
	     LEFT JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
	                              AND TFL.%NotDel%
	                              AND ( ( '1' = %exp:cTipoOrc% AND TFL.TFL_CODIGO = TFF.TFF_CODPAI ) OR
	                                    ( '0' = %exp:cTipoOrc% AND TFL.TFL_CODIGO = TFG.TFG_CODPAI ) ) 
	     LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
	                              AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
	                              AND ABS.%NotDel%
	     LEFT JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1%
	                              AND SB1.B1_COD = TFG.TFG_PRODUT
	                              AND SB1.%NotDel%		
	 WHERE TFG.TFG_FILIAL = %xFilial:TFG%
	   AND TFG.%NotDel%
	   AND %Exp:cWhereCob%
	   AND NOT( TFG_PERINI > %Exp:dDtFim% OR TFG_PERFIM < %Exp:dDtIni% )
	 GROUP BY TFL.TFL_CODIGO, TFL.TFL_LOCAL,  ABS.ABS_DESCRI, TFL.TFL_CODIGO, TFG.TFG_COD,  
 	          TFG.TFG_PERINI, TFG.TFG_PERFIM, TFF.TFF_COD,    TFF.TFF_PRODUT, TFG_PRODUT, SB1.B1_DESC		

EndSql

While (cAliasIMI)->(!Eof())		
	
	oMdlIMI:SetValue( "TFX_LOCAL" , (cAliasIMI)->TFL_LOCAL  )
	oMdlIMI:SetValue( "TFX_DESCRI", (cAliasIMI)->ABS_DESCRI )
	oMdlIMI:SetValue( "TFX_CODTFL", (cAliasIMI)->TFL_CODIGO )		

	If lApuApt
		lKit := AllTrim(Posicione("SB1",1,FwxFilial("SB1")+(cAliasIMI)->TFG_PRODUT,"B1_TIPO")) == "KT"

		If lKit
			oMdlIMI:SetValue( "TFX_VLRAPU", (cAliasIMI)->VLR_APUKIT )
			oMdlIMI:SetValue( "TFX_VLRMED", (cAliasIMI)->VLR_APUKIT	)	
		Else
			oMdlIMI:SetValue( "TFX_VLRAPU", (cAliasIMI)->VLR_APU    )
			oMdlIMI:SetValue( "TFX_VLRMED", (cAliasIMI)->VLR_APU 	)	
		Endif
	Endif	

	oMdlIMI:SetValue( "TFX_CODTFF", (cAliasIMI)->TFF_COD	)	
	oMdlIMI:SetValue( "TFX_PRODUT", (cAliasIMI)->TFG_PRODUT )							
	oMdlIMI:SetValue( "TFX_DSCPRO", (cAliasIMI)->B1_DESC    )
	oMdlIMI:SetValue( "TFX_CODTFG", (cAliasIMI)->TFG_COD    )
	
	If !lGrpFatOrc
		oMdlIMI:SetValue( "TFX_PLAN", Posicione("TFL",1,xFilial("TFL")+oMdlIMI:GetValue("TFX_CODTFL"),"TFL_PLAN")  )
	Else
		At870GrPlan( TFJ->TFJ_CODGRP,(cAliasIMI)->TFL_LOCAL , , @cPlanMI )
		oMdlIMI:SetValue( "TFX_PLAN", cPlanMI)
	EndIf
	
	nDifCalc := (StoD((cAliasIMI)->TFG_PERFIM) - StoD((cAliasIMI)->TFG_PERINI)) + 1
	 	
 	If MV_PAR02 < StoD((cAliasIMI)->TFG_PERINI)
 		dDtIni := StoD((cAliasIMI)->TFG_PERINI)
 	EndIf
 	
 	If MV_PAR03 > StoD((cAliasIMI)->TFG_PERFIM)
 		dDtFim := StoD((cAliasIMI)->TFG_PERFIM)
 	EndIf

	nDifDias := (dDtFim - dDtIni) + 1

	nPerCalc := (nDifDias / nDifCalc) * 100
		
	If nDifCalc > nDifDias .And. At740Recor(MV_PAR01)	
		If nDifDias > 0
			oMdlIMI:SetValue( "TFX_VLRCON", (((cAliasIMI)->VLR_CONT * nPerCalc) / 100) )	
			If !lApuApt
				oMdlIMI:SetValue( "TFX_VLRAPU", (((cAliasIMI)->VLR_CONT * nPerCalc) / 100) )
				oMdlIMI:SetValue( "TFX_VLRMED", (((cAliasIMI)->VLR_CONT * nPerCalc) / 100) )	
			Endif
		Else
			oMdlIMI:SetValue( "TFX_VLRCON", 0 )
			If !lApuApt
				oMdlIMI:SetValue( "TFX_VLRAPU", 0 )
				oMdlIMI:SetValue( "TFX_VLRMED", 0 )
			Endif
		Endif
	Else
		If nDifDias > 0
			oMdlIMI:SetValue( "TFX_VLRCON", (cAliasIMI)->VLR_CONT )	
			If !lApuApt
				oMdlIMI:SetValue( "TFX_VLRAPU", (cAliasIMI)->VLR_CONT )	
				oMdlIMI:SetValue( "TFX_VLRMED", (cAliasIMI)->VLR_CONT )	
			Endif
		Else
			oMdlIMI:SetValue( "TFX_VLRCON", 0 )
			If !lApuApt
				oMdlIMI:SetValue( "TFX_VLRAPU", 0 )
				oMdlIMI:SetValue( "TFX_VLRMED", 0 )
			Endif
		Endif
	EndIf
	
	(cAliasIMI)->(dbSkip())
	
	If (cAliasIMI)->(!Eof())
		oMdlIMI:AddLine()
	Endif 
	
EndDo

If lSrvExt
	cWhereCob := "%TFL.TFL_CODPAI = '" + MV_PAR05 + "' AND "
	cWhereCob += " TFH.TFH_TIPMAT = '3' %"
	//cWhereCob += " TFH.TFH_COBCTR = '2' AND TFH.TFH_PRCVEN > 0%" 
ElseIf lMedExt
	cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
	cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND "
	cWhereCob += " TFH.TFH_TIPMAT = '2' %"
	//cWhereCob += "TFH.TFH_COBCTR = '2' AND TFH.TFH_PRCVEN > 0%" 
Else
	cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
	cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND " 
 	cWhereCob += " TFH.TFH_TIPMAT = '3' %"
 	//cWhereCob += "TFH.TFH_COBCTR <> '2' %"
EndIf

// Materiais de Consumo
BeginSql Alias cAliasIMC

	SELECT TFL.TFL_CODIGO, TFL.TFL_LOCAL, ABS.ABS_DESCRI, TFH.TFH_PERINI, TFH.TFH_PERFIM,
	       SUM(TFH.TFH_VALDES) VAL_DSC, SUM(TFT.TFT_QUANT) QUANTIDADE, TFH.TFH_COD,
	       ( SELECT SUM( (TFH2.TFH_QTDVEN * 
	                      (TFH2.TFH_PRCVEN - ((TFH2.TFH_PRCVEN * TFH2.TFH_DESCON)/100)
	                                       + ((TFH2.TFH_PRCVEN * TFH2.TFH_LUCRO)/100)
	                                       + ((TFH2.TFH_PRCVEN * TFH2.TFH_ADM)/100) )))
	           FROM %table:TFH% TFH2
	          WHERE TFH2.TFH_FILIAL = %xFilial:TFH%
	            AND TFH2.%NotDel%
	            AND TFH2.TFH_COD = TFH.TFH_COD
	          GROUP BY TFH2.TFH_FILIAL, TFH2.TFH_LOCAL, TFH2.TFH_CODPAI
	       ) VLR_CONT,						

 		   ( SELECT SUM( (TFT2.TFT_QTDKIT * 
 		   				  (TFH3.TFH_PRCVEN - ((TFH3.TFH_PRCVEN * TFH3.TFH_DESCON)/100)
 		   				  				   + ((TFH3.TFH_PRCVEN * TFH3.TFH_LUCRO)/100) 
 		   				  				   + ((TFH3.TFH_PRCVEN * TFH3.TFH_ADM)/100) )))
   			   FROM %table:TFH% TFH3
  					LEFT JOIN  ( SELECT TFT.TFT_FILIAL, TFT.TFT_CODTFH,TFT.TFT_QTDKIT
  									FROM %table:TFH% TFH
  										LEFT JOIN %table:TFT% TFT ON TFT.TFT_FILIAL = %xFilial:TFT%
											AND TFT.TFT_CODTFH = TFH.TFH_COD
 										    AND RTrim(LTrim(TFT.TFT_ITAPUR)) = ' '
				                            AND TFT.TFT_DTAPON >= %Exp:dDtIniApu%
				                            AND TFT.TFT_DTAPON <= %Exp:dDtFimApu%
				                            AND TFT.%NotDel% 
	     						 GROUP BY TFT.TFT_FILIAL, TFT.TFT_CODTFH,TFT_QTDKIT
	     						 ) TFT2 ON TFT2.TFT_FILIAL = %xFilial:TFT%
 									    AND TFT2.TFT_CODTFH = TFH.TFH_COD
  			   WHERE TFH3.TFH_FILIAL = %xFilial:TFH%
			     AND TFH3.%NotDel% 
     			 AND TFH3.TFH_COD = TFH.TFH_COD
   			   GROUP BY TFH3.TFH_FILIAL,TFH3.TFH_LOCAL,TFH3.TFH_CODPAI
   		   ) VLR_APUKIT,
    
	       SUM(TFT.TFT_QUANT * (TFH.TFH_PRCVEN - ((TFH.TFH_PRCVEN * TFH.TFH_DESCON)/100)
	                                           + ((TFH.TFH_PRCVEN * TFH.TFH_LUCRO)/100)
	                                           + ((TFH.TFH_PRCVEN * TFH.TFH_ADM)/100) )) VLR_APU,
    	       
	       TFF.TFF_COD, TFH.TFH_PRODUT, SB1.B1_DESC
	  FROM %table:TFH% TFH
	       LEFT JOIN %table:TFT% TFT ON TFT.TFT_FILIAL = %xFilial:TFT%
	                                AND TFT.TFT_CODTFH = TFH.TFH_COD
	                                AND TFT.TFT_PEND = 'N'
	                                AND RTrim(LTrim(TFT.TFT_ITAPUR)) = ' '
	                                AND TFT.TFT_DTAPON >= %Exp:dDtIniApu%
	                                AND TFT.TFT_DTAPON <= %Exp:dDtFimApu%
	                                AND TFT.%NotDel%
	       LEFT JOIN %table:TFF% TFF ON '1' = %exp:cTipoOrc%
	                                AND TFF.TFF_FILIAL = %xFilial:TFF%
	                                AND TFF.TFF_COD = TFH.TFH_CODPAI
	                                AND TFF.%NotDel%
	       LEFT JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
	                                AND TFL.%NotDel%
	                                AND ( ( '1' = %exp:cTipoOrc% AND TFL.TFL_CODIGO = TFF.TFF_CODPAI ) OR
	                                      ( '0' = %exp:cTipoOrc% AND TFL.TFL_CODIGO = TFH.TFH_CODPAI ) ) 
	       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
	                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
	                                AND ABS.%NotDel%
	       LEFT JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1%
	                                AND SB1.B1_COD = TFH.TFH_PRODUT
	                                AND SB1.%NotDel%
	 WHERE TFH.TFH_FILIAL = %xFilial:TFH%
	   AND TFH.%NotDel%
	   AND %Exp:cWhereCob%  
	   AND NOT( TFH_PERINI > %Exp:dDtFim% OR TFH_PERFIM < %Exp:dDtIni% )
	 GROUP BY TFL.TFL_CODIGO, TFL.TFL_LOCAL,  ABS.ABS_DESCRI, TFL.TFL_CODIGO, TFH.TFH_COD, 
	          TFH.TFH_PERINI, TFH.TFH_PERFIM, TFF.TFF_COD,    TFF.TFF_PRODUT, TFH.TFH_PRODUT, SB1.B1_DESC

EndSql

While (cAliasIMC)->(!Eof())		
	
	oMdlIMC:SetValue( "TFY_LOCAL" , (cAliasIMC)->TFL_LOCAL  )
	oMdlIMC:SetValue( "TFY_DESCRI", (cAliasIMC)->ABS_DESCRI )
	oMdlIMC:SetValue( "TFY_CODTFL", (cAliasIMC)->TFL_CODIGO	)

	If lApuApt
		lKit := AllTrim(Posicione("SB1",1,FwxFilial("SB1")+(cAliasIMC)->TFH_PRODUT,"B1_TIPO")) == "KT"

		If lKit
			oMdlIMC:SetValue( "TFY_VLRAPU", (cAliasIMC)->VLR_APUKIT	)
			oMdlIMC:SetValue( "TFY_VLRMED", (cAliasIMC)->VLR_APUKIT )
		Else
			oMdlIMC:SetValue( "TFY_VLRAPU", (cAliasIMC)->VLR_APU	)
			oMdlIMC:SetValue( "TFY_VLRMED", (cAliasIMC)->VLR_APU 	)
		Endif
	Endif

	oMdlIMC:SetValue( "TFY_CODTFF", (cAliasIMC)->TFF_COD	)	
	oMdlIMC:SetValue( "TFY_PRODUT", (cAliasIMC)->TFH_PRODUT )						
	oMdlIMC:SetValue( "TFY_DSCPRO", (cAliasIMC)->B1_DESC    )
	oMdlIMC:SetValue( "TFY_CODTFH", (cAliasIMC)->TFH_COD    )
	
	If !lGrpFatOrc
		oMdlIMC:SetValue( "TFY_PLAN", Posicione("TFL",1,xFilial("TFL")+oMdlIMC:GetValue("TFY_CODTFL"),"TFL_PLAN")  )
	Else
		At870GrPlan( TFJ->TFJ_CODGRP,(cAliasIMC)->TFL_LOCAL , , , @cPlanMC)
		oMdlIMC:SetValue( "TFY_PLAN", cPlanMC)
	EndIf
		
	

	nDifCalc := StoD((cAliasIMC)->TFH_PERFIM) - StoD((cAliasIMC)->TFH_PERINI) + 1
	 	
 	If MV_PAR02 < StoD((cAliasIMC)->TFH_PERINI)
 		dDtIni := StoD((cAliasIMC)->TFH_PERINI)
 	EndIf
 	
 	If MV_PAR03 > StoD((cAliasIMC)->TFH_PERFIM)
 		dDtFim := StoD((cAliasIMC)->TFH_PERFIM)
 	EndIf

	nDifDias := (dDtFim - dDtIni) + 1

	nPerCalc := (nDifDias / nDifCalc) * 100
		
	If nDifCalc > nDifDias .And. At740Recor(MV_PAR01)
		If nDifDias > 0
			oMdlIMC:SetValue( "TFY_VLRCON", (((cAliasIMC)->VLR_CONT * nPerCalc) / 100) )	
			If !lApuApt
				oMdlIMC:SetValue( "TFY_VLRAPU", (((cAliasIMC)->VLR_CONT * nPerCalc) / 100) )	
				oMdlIMC:SetValue( "TFY_VLRMED", (((cAliasIMC)->VLR_CONT * nPerCalc) / 100) )	
			Endif
		Else
			oMdlIMC:SetValue( "TFY_VLRCON", 0 )
			If !lApuApt			
				oMdlIMC:SetValue( "TFY_VLRAPU", 0 )
				oMdlIMC:SetValue( "TFY_VLRMED", 0 )
			Endif
		Endif
	Else
		If nDifDias > 0
			oMdlIMC:SetValue( "TFY_VLRCON", (cAliasIMC)->VLR_CONT )
			If !lApuApt
				oMdlIMC:SetValue( "TFY_VLRAPU", (cAliasIMC)->VLR_CONT )
				oMdlIMC:SetValue( "TFY_VLRMED", (cAliasIMC)->VLR_CONT )
			Endif
		Else
			oMdlIMC:SetValue( "TFY_VLRCON", 0 )
			If !lApuApt
				oMdlIMC:SetValue( "TFY_VLRAPU", 0 )
				oMdlIMC:SetValue( "TFY_VLRMED", 0 )
			Endif
		Endif
	EndIf

	(cAliasIMC)->(dbSkip())
	
	If (cAliasIMC)->(!Eof())
		oMdlIMC:AddLine()
	Endif 
	
EndDo

(cAliasIMI)->(DbCloseArea())
(cAliasIMC)->(DbCloseArea())
RestArea(aOldArea)

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930CaRH
Load das informações da tela de Recursos Humanos
@sample 	At930CaRH() 
@param		cContrato - Contrato que será apurado
@return	ExpL	Nil
@since		22/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------//
Static Function At930CaRH(cContrato)

Local aArea		:= GetArea()
Local cAliasAB9	:= GetNextAlias()
Local cAliasTW7	:= GetNextAlias()
Local cOperConc	:= if(Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX","||","+")
Local cIdcABQ		:= ""
Local oModel		:= FWModelActive()
Local oModelTFW	:= oModel:GetModel("TFWDETAIL")
Local oModelTW7	:= oModel:GetModel("TFWTW7DETAIL")
Local oStruTFW 		:= oModelTFW:GetStruct()
Local aBusca		:= {}
Local lExiste		:= .F.
Local nVlrHor		:= 0
Local nHorTot		:= 0
Local nDifDias	:= 0
Local nDifCalc	:= 0
Local nPerCalc	:= 0
Local nTotal		:= 0
Local nTotHora	:= 0
Local nVlrTot		:= 0
Local cHora		:= ""
Local cMinutos	:= ""
Local cRevCtr		:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
Local cChvTFL       := ""
Local nTotHrE		:= 0
Local nHorExt		:= 0
Local nHorTotE	:= 0
Local nValHorE	:= 0
Local nLinha		:= 0
Local nValTHe		:= 0
Local nValTHn		:= 0
Local nTotHrN		:= 0
Local cMod			:= ""
Local cWhereCob	:= ""
Local nVlrCont	:= 0
Local nX		:= 0
Local nI 		:= 0
Local dDtIni	:= MV_PAR02 
Local dDtFim	:= MV_PAR03
Local cIsGsMt	:= TFJ->TFJ_ISGSMT
Local lGsMtMi	:= TFJ->TFJ_GSMTMI $ "2|3"
Local lGsMtMc	:= TFJ->TFJ_GSMTMC $ "2|3"
Local dDtIniApu	:= MV_PAR02 
Local dDtFimApu	:= MV_PAR03


//grupo de Faturamento
Local lGrpFatOrc:= TFJ->TFJ_GRPFAT== "1"
Local cPlanRH	:= ""

If lTeca934 //ajustar data da apuração para mês anterior
	dDtIniApu	:= MV_PAR05 
	dDtFimApu	:= MV_PAR06
EndIf


If lSrvExt

	DbSelectArea("TFJ")
	DbSetOrder(1)
	If TFJ->( DbSeek( xFilial("TFJ") + MV_PAR05 ) )
		cIsGsMt	:= TFJ->TFJ_ISGSMT
		lGsMtMi	:= TFJ->TFJ_GSMTMI $ "2|3"
		lGsMtMc	:= TFJ->TFJ_GSMTMC $ "2|3"
	EndIf

EndIf

If Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX"	
	
	//Calculo para horas
	cHora    := "(SUM(CAST(SUBSTR(ABR.ABR_TEMPO,1,2) AS INTEGER)) * 60)"
	
	//Calculo para minutos
	cMinutos := "SUM(CAST(SUBSTR(ABR.ABR_TEMPO,4,2) AS INTEGER))" 
	
	If Trim(Upper(TcGetDb())) $ "POSTGRES"	
		cMod := "%SUBSTR( Concat( '00', Cast((" + cHora + "+" + cMinutos + ") / 60 as VarChar(2))),4,2)"
		cMod += " || ':' || "
		cMod += "SUBSTR( Concat( '00', Cast(mod(CAST((" + cHora + "+" + cMinutos + ") AS NUMERIC) , 60) as VarChar(2))),4,2)%"
 	Else
 		cMod := "%SUBSTR( Concat( '00', Cast((" + cHora + "+" + cMinutos + ") / 60 as VarChar(2))),4,2)"
		cMod += " || ':' || "
		cMod += "SUBSTR( Concat( '00', Cast(Mod((" + cHora + "+" + cMinutos + "), 60) as VarChar(2))),4,2)%" 
 	EndIf

Else

	//Calculo para horas
	cHora := "( Sum(datepart(hh,convert(varchar,ABR.ABR_TEMPO,108))) * 60 + " 
	cHora += "Sum(datepart(mi,convert(varchar,ABR.ABR_TEMPO,108))) ) / 60"
	
	//Calculos para os minutos
	cMinutos := "( Sum(datepart(hh,convert(varchar,ABR.ABR_TEMPO,108))) * 60 + " 
	cMinutos += "Sum(datepart(mi,convert(varchar,ABR.ABR_TEMPO,108))) ) % 60"

	//Horas formatadas
	cMod := "%Replicate('0', 2 - DataLength(LTrim(RTrim(Convert(Varchar, " + cHora + " ))))) + "
	cMod += "Convert(Varchar," + cHora + ") + ':' + "
 	cMod += "Replicate('0', 2 - DataLength(Ltrim(Rtrim(Convert(Varchar, " + cMinutos + "))))) + " 
	cMod += "Convert(Varchar," + cMinutos + ")%"	
	   
EndIF 

If lSrvExt
	cWhereCob := "%TFL.TFL_CODPAI = '" + MV_PAR05 + "' AND "
	cWhereCob += "TFF.TFF_COBCTR = '2' AND TFF.TFF_PRCVEN > 0 %" 
	cChvTFL   := "%TFL.TFL_CODPAI = '" + MV_PAR05 + "'  %"
Else
	If lMedExt
		cWhereCob := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
		cWhereCob += "TFL.TFL_CONREV = '" + cRevCtr + "' AND "
		cWhereCob += "TFF.TFF_COBCTR = '2' AND TFF.TFF_PRCVEN > 0%" 
	Else
		cWhereCob := "%TFF.TFF_CONTRT = '" + MV_PAR01 + "' AND "
		cWhereCob += "TFF.TFF_CONREV = '" + cRevCtr + "' AND " 
	 	cWhereCob += "TFF.TFF_COBCTR <> '2' AND TFF.TFF_PRCVEN > 0%"
	EndIf
	cChvTFL := "%TFL.TFL_CONTRT = '" + MV_PAR01 + "' AND "
	cChvTFL += " TFL.TFL_CONREV = '" + cRevCtr  + "'%"
EndIf

nDifDias := (MV_PAR03 - MV_PAR02) + 1	  

cIdcABQ := "%ABQ.ABQ_CONTRT" + cOperConc + "ABQ.ABQ_ITEM" + cOperConc + "ABQ.ABQ_ORIGEM%"

	//Levanatamento de apontamentos dos apontamentos efetuados
	BeginSql Alias cAliasAB9
		
		SELECT TFL.TFL_CODIGO, TFL.TFL_LOCAL, ABS.ABS_DESCRI, TFF.TFF_COD, TFF.TFF_PRODUT, 
		       SB1.B1_DESC, SUM(ABA.ABA_QUANT) TOT_HOR, ABQ.ABQ_TOTAL, TFF.TFF_QTDVEN, 
		       TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_PERINI, TFF.TFF_PERFIM,
		       %Exp:cMod% TOT_HOREXT, TFU.TFU_VALOR, ABN.ABN_TIPO,
		       TFF.TFF_TXLUCR, TFF.TFF_TXADM, TFF.TFF_ORIREF, TFF.TFF_TOTBEN, TFF.TFF_TOTVRB
		  FROM %table:TFF% TFF
		       LEFT JOIN %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
		                                AND ABQ.ABQ_FILTFF = TFF.TFF_FILIAL
		                                AND ABQ.ABQ_CODTFF = TFF.TFF_COD
		                                AND ABQ.%NotDel%
		       LEFT JOIN %table:ABB% ABB ON ABB.ABB_FILIAL = %xFilial:ABB% 
		                                AND ABB.ABB_IDCFAL = ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM 
		                                AND ABB.ABB_CHEGOU = 'S' AND ABB.ABB_ATENDE = '1' 
		                                AND ABB.ABB_DTINI >= %Exp:dDtIniApu% 
		                                AND ABB.ABB_DTINI <= %Exp:dDtFimApu% 
		                                AND ABB.ABB_DTFIM >= %Exp:dDtIniApu% 
		                                AND ABB.ABB_DTFIM <= %Exp:dDtFimApu% 
		                                AND ABB.%NotDel%
		       LEFT JOIN %table:AB9% AB9 ON AB9.AB9_FILIAL = %xFilial:AB9% 
		                                AND AB9.AB9_ATAUT = ABB.ABB_CODIGO 
		                                AND AB9.AB9_NUMOS = ABB.ABB_CHAVE
		                                AND RTrim(LTrim(AB9.AB9_ITAPUR))=' '		 
		                                AND AB9.%NotDel%
		       LEFT JOIN %table:ABA% ABA ON ABA.ABA_FILIAL = %xFilial:ABA%
		                                AND ABA.ABA_NUMOS = AB9.AB9_NUMOS
		                                AND ABA.ABA_SEQ  =  AB9.AB9_SEQ
		                                AND ABA.ABA_CODTEC  =  ABB.ABB_CODTEC  
		                                AND ABA.%NotDel%
		       LEFT JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL% 
		                                AND TFL.TFL_CODIGO = TFF.TFF_CODPAI 
									AND TFL.TFL_CONTRT = %Exp:MV_PAR01% 
									AND TFL.TFL_CONREV = %Exp:cRevCtr% 
		                                AND TFL.%NotDel%      
										AND TFL.TFL_TOTRH > 0              
										AND %Exp:cChvTFL% 
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS% 
		                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL 
		                                AND ABS.%NotDel%
		       LEFT JOIN %table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1% 
	  	                                AND SB1.B1_COD = TFF.TFF_PRODUT 
	  	                                AND SB1.%NotDel%
		       LEFT JOIN %table:ABR% ABR ON ABR.ABR_FILIAL = %xFilial:ABR% 
		                                AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
		                                AND ABR.ABR_DTINI >= %Exp:dDtIniApu% 
		                                AND ABR.ABR_DTFIM <= %Exp:dDtFimApu%
		                                AND ABR.%NotDel%
		       LEFT JOIN %table:ABN% ABN ON ABN.ABN_FILIAL = %xFilial:ABN% 
		                                AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO	
		                                AND ABN.ABN_TIPO = '04' 	 
		                                AND ABN.%NotDel%
		       LEFT JOIN %table:TFU% TFU ON TFU.TFU_FILIAL = %xFilial:TFU%
		                                AND TFU.TFU_CODTFF = TFF.TFF_COD		 
		                                AND TFU.TFU_CODABN = ABR.ABR_MOTIVO		 
		                                AND TFU.%NotDel%
		 WHERE TFF.TFF_FILIAL = %xFilial:TFF%
		   AND TFF.%NotDel%
		   AND %Exp:cWhereCob% 		
		   AND NOT( TFF_PERINI > %Exp:dDtFim% OR TFF_PERFIM < %Exp:dDtIni% )
		 GROUP BY TFL.TFL_CODIGO, TFL.TFL_LOCAL, ABS.ABS_DESCRI, TFF.TFF_COD, TFF.TFF_PRODUT, 
		          SB1.B1_DESC, ABQ.ABQ_TOTAL, TFF.TFF_QTDVEN, TFF.TFF_PRCVEN, TFF.TFF_VALDES, 
		          TFF.TFF_PERINI, TFF.TFF_PERFIM, TFU.TFU_VALOR, ABN.ABN_TIPO,
		          TFF.TFF_TXLUCR, TFF.TFF_TXADM, TFF.TFF_ORIREF, TFF.TFF_TOTBEN, TFF.TFF_TOTVRB
	ORDER BY TFF_COD

EndSql

nTotHrE  := 0
nHorExt  := 0
nHorTotE := 0
nValHorE := 0
nTotal   := 0
nTotHora := 0
nVlrTot  := 0
nLinha   := 0
nValTHe  := 0
nValTHn  := 0
nTotHre  := 0



While (cAliasAB9)->(!Eof())
 	   	
 	nTotHrE  := 0
 	nValHorE := 0
 	nHorTotE := 0
	nValTHe := 0
	nValHorE := 0
	nHorTot := 0
	nTotHrN := 0
		
	aBusca := {}
	AAdd( aBusca, { "TFW_CODTFL", (cAliasAB9)->TFL_CODIGO } )
	AAdd( aBusca, { "TFW_CODTFF", (cAliasAB9)->TFF_COD    } )
	
	lExiste := oModelTFW:SeekLine( aBusca )
		
	If (cAliasAB9)->TOT_HOR > 0
		If (cAliasAB9)->ABN_TIPO == "04"
			nTotHrN  := (cAliasAB9)->TOT_HOR - HoraToInt((cAliasAB9)->TOT_HOREXT)
		Else
			nTotHrN  := (cAliasAB9)->TOT_HOR
		EndIf
	EndIf
	
	nVlrCont := ((cAliasAB9)->TFF_PRCVEN * (cAliasAB9)->TFF_QTDVEN ) - (cAliasAB9)->TFF_VALDES + (cAliasAB9)->TFF_TXLUCR + (cAliasAB9)->TFF_TXADM

	If !Empty((cAliasAB9)->TFF_ORIREF)    
		nVlrHor	:= POSICIONE("TFF",1,xFilial("TFF")+(cAliasAB9)->TFF_ORIREF,"TFF_REFVLR")
	Else
		nVlrHor	:= nVlrCont / (cAliasAB9)->ABQ_TOTAL   
	EndIf
	If (cAliasAB9)->TOT_HOR > 0
		If 	ExistBlock('AT930VLREF') .AND. !Empty((cAliasAB9)->TFF_ORIREF)     
			nHorTot := ExecBlock("AT930VLREF",.F.,.F.,{(cAliasAB9)->TFF_COD,dDtIniApu, dDtFimApu, nVlrHor})
		Else
			nHorTot  := nTotHrN * nVlrHor
		EndIf 		
	EndIf
	
	If (cAliasAB9)->ABN_TIPO == "04" .and. (cAliasAB9)->TOT_HOR > 0  
		If !Empty((cAliasAB9)->TFU_VALOR) // Campos de hora extra		
			nHorTotE  := HoraToInt((cAliasAB9)->TOT_HOREXT) * (cAliasAB9)->TFU_VALOR
		Else
			nHorTotE  := HoraToInt((cAliasAB9)->TOT_HOREXT) * nVlrHor		
		EndIf	
	EndIf
			
	If ! lExiste	
						
		 If nLinha > 0
 			oModelTFW:AddLine()
 		Else 
 			nLinha ++	
 		EndIf 
		
		nTotHora := (cAliasAB9)->TOT_HOR
		
		nHorExt  := HoraToInt((cAliasAB9)->TOT_HOREXT) 
		 
		nValHorE := nHorTotE  
		nVlrTot  := nHorTotE + nHorTot
		nValTHn  := nHorTot
		nValTHe  := nHorTotE  		
		nTotHre  := nTotHrN   			
				
	Else	
		
		nTotHora := oModelTFW:GetValue( "TFW_TOTHOR" ) + (cAliasAB9)->TOT_HOR
				
		nHorExt  := oModelTFW:GetValue( "TFW_HORAE"  ) + HoraToInt((cAliasAB9)->TOT_HOREXT)  
		
		nValHorE := oModelTFW:GetValue( "TFW_VLREXT" ) + nHorTotE 		
		nVlrTot  := oModelTFW:GetValue( "TFW_VLRAPU" ) + nHorTotE + nHorTot		
		nValTHn  := oModelTFW:GetValue( "TFW_VLHORN" ) + nHorTot
		nValTHe  := oModelTFW:GetValue( "TFW_VLHORE" ) + nHorTotE  
		nTotHre  := oModelTFW:GetValue( "TFW_HORAN" ) + nTotHrN  			
						
	Endif
		
	oModelTFW:SetValue( "TFW_CODTFL", (cAliasAB9)->TFL_CODIGO )
	oModelTFW:SetValue( "TFW_LOCAL" , (cAliasAB9)->TFL_LOCAL  )
	oModelTFW:SetValue( "TFW_DESCRI", (cAliasAB9)->ABS_DESCRI )	
	oModelTFW:SetValue( "TFW_HORAN" , nTotHre 	  			  )
	oModelTFW:SetValue( "TFW_VLHORN", nValTHn  	  			  )
	oModelTFW:SetValue( "TFW_HORAE" , nHorExt 				  )
	oModelTFW:SetValue( "TFW_VLHORE", nValTHe 				  ) 
	// valores da apuração e sugerido para a medição
	oModelTFW:SetValue( "TFW_VLRAPU", nVlrTot				  )
	oModelTFW:SetValue( "TFW_VLREXT", nValHorE  		      ) 
	oModelTFW:SetValue( "TFW_VLRMED", nVlrTot 			 )
	oModelTFW:SetValue( "TFW_VLRTOT", nVlrTot + nValHorE )
	oModelTFW:SetValue( "TFW_TOTHOR", nTotHora				  ) 
	oModelTFW:SetValue( "TFW_CODTFF", (cAliasAB9)->TFF_COD	  )	
	oModelTFW:SetValue( "TFW_PRODUT", (cAliasAB9)->TFF_PRODUT )						
	oModelTFW:SetValue( "TFW_DSCPRO", (cAliasAB9)->B1_DESC    )	
	
	
	If !lGrpFatOrc
		oModelTFW:SetValue( "TFW_PLAN",   Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")   )
	Else
		At870GrPlan( TFJ->TFJ_CODGRP,(cAliasAB9)->TFL_LOCAL , @cPlanRH)
		oModelTFW:SetValue( "TFW_PLAN",  cPlanRH  )
	EndIf			
	 	
 	nDifCalc := StoD((cAliasAB9)->TFF_PERFIM) - StoD((cAliasAB9)->TFF_PERINI) + 1
 	
 	dDtIni := MV_PAR02//Data Inicial da apuração
 	dDtFim := MV_PAR03//data Final da apuração
 	
 	//Ajusta quantidade de dias para apuração conforme periodo definido no local de atendimento
 	If MV_PAR02 < StoD((cAliasAB9)->TFF_PERINI)
 		dDtIni := StoD((cAliasAB9)->TFF_PERINI)
 	EndIf
 	If MV_PAR03 > StoD((cAliasAB9)->TFF_PERFIM)
 		dDtFim := StoD((cAliasAB9)->TFF_PERFIM)
 	EndIf
 	
 	nDifDias := (dDtFim - dDtIni) + 1	 //Total de dias a ser apurado 
 	
	If nDifCalc > nDifDias .And. At740Recor(MV_PAR01)
		if nDifDias > 0
			nPerCalc := (nDifDias / nDifCalc) * 100
			oModelTFW:SetValue( "TFW_VLRCON", ((nVlrCont * nPerCalc) / 100) )
			oModelTFW:SetValue( "TFW_ABTINS", (((cAliasAB9)->TFF_TOTBEN+(cAliasAB9)->TFF_TOTVRB)* nPerCalc/ 100))
			If cIsGsMt == "1"
				DbSelectArea("TFF")
				TFF->(DbSetOrder(1))
				If TFF->(DbSeek(xFilial("TFF")+(cAliasAB9)->TFF_COD))
					If lGsMtMi 
						oStruTFW:SetProperty("TFW_PDMTMI" 	,MODEL_FIELD_WHEN, {||.T.} )
						oStruTFW:SetProperty("TFW_VLMTMI" 	,MODEL_FIELD_WHEN, {||.T.} )
						oModelTFW:SetValue( "TFW_PDMTMI", TFF->TFF_PDMTMI )
						oModelTFW:SetValue( "TFW_VLMTMI", ( ( TFF->TFF_VLMTMI * nPerCalc) / 100) )
					Else
						oModelTFW:SetValue( "TFW_PDMTMI", "" )
						oModelTFW:SetValue( "TFW_VLMTMI", 0 )
						oStruTFW:SetProperty("TFW_PDMTMI" 	,MODEL_FIELD_WHEN, {||.F.} )
						oStruTFW:SetProperty("TFW_VLMTMI" 	,MODEL_FIELD_WHEN, {||.F.} )
					Endif
	
					If lGsMtMc
						oStruTFW:SetProperty("TFW_PDMTMC" 	,MODEL_FIELD_WHEN, {||.T.} )
						oStruTFW:SetProperty("TFW_VLMTMC" 	,MODEL_FIELD_WHEN, {||.T.} )
						oModelTFW:SetValue( "TFW_PDMTMC", TFF->TFF_PDMTMC )
						oModelTFW:SetValue( "TFW_VLMTMC", ( ( TFF->TFF_VLMTMC * nPerCalc) / 100) )
					Else
						oModelTFW:SetValue( "TFW_PDMTMC", "" )
						oModelTFW:SetValue( "TFW_VLMTMC", 0  )
						oStruTFW:SetProperty("TFW_PDMTMC" 	,MODEL_FIELD_WHEN, {||.F.} )
						oStruTFW:SetProperty("TFW_VLMTMC" 	,MODEL_FIELD_WHEN, {||.F.} )										
					Endif
				Endif
			Endif
 		Else
			oModelTFW:SetValue( "TFW_VLRCON", 0 )
		Endif
 	Else
		If nDifDias > 0
			oModelTFW:SetValue( "TFW_VLRCON", nVlrCont )
			oModelTFW:SetValue( "TFW_ABTINS", (cAliasAB9)->TFF_TOTBEN+(cAliasAB9)->TFF_TOTVRB)
			If cIsGsMt == "1"
				DbSelectArea("TFF")
				TFF->(DbSetOrder(1))
				If TFF->(DbSeek(xFilial("TFF")+(cAliasAB9)->TFF_COD))
	
					If lGsMtMi
						oModelTFW:SetValue( "TFW_PDMTMI", TFF->TFF_PDMTMI )
						oModelTFW:SetValue( "TFW_VLMTMI", TFF->TFF_VLMTMI )
					Else
						oModelTFW:SetValue( "TFW_PDMTMI", "" )
						oModelTFW:SetValue( "TFW_VLMTMI", 0  )
					Endif
	
					If lGsMtMc
						oModelTFW:SetValue( "TFW_PDMTMC", TFF->TFF_PDMTMC )
						oModelTFW:SetValue( "TFW_VLMTMC", TFF->TFF_VLMTMC )
					Else
						oModelTFW:SetValue( "TFW_PDMTMC", "" )
						oModelTFW:SetValue( "TFW_VLMTMC", 0  )
					Endif
				Endif
			Endif
		Else
			oModelTFW:SetValue( "TFW_VLRCON", 0 )
		Endif
 	EndIf	
 	
 	(cAliasAB9)->(dbSkip()) 	
 	 
EndDo

(cAliasAB9)->(DbCloseArea())
RestArea(aArea)

If lSrvExt
	BeginSql Alias cAliasTW7
		SELECT	SUM(TWQ.TWQ_VALOR) TWQ_VALOR, TWQ_FILIAL, TFF_CODPAI, TFF_COD		
		FROM %table:TWQ% TWQ
				
		INNER JOIN  %table:TFF% TFF 
			ON	TFF.TFF_FILIAL =  %xFilial:TFF%   AND 
				TFF.TFF_COD = TWQ.TWQ_POSTRH AND 
				TFF.%NotDel%	
		INNER JOIN %table:TFL% TFL ON
				TFL.TFL_FILIAL = %xFilial:TFL%  AND 
				TFL.TFL_CODIGO = TFF.TFF_CODPAI AND  
				TFL.%NotDel%                    AND
				%Exp:cChvTFL%
		WHERE		
			TWQ.TWQ_FILIAL  = %xFilial:TWQ% AND 
			TWQ.TWQ_POSTRH <> '' AND 
			TWQ.TWQ_PEDIDO = '' AND 
			TWQ.TWQ_ORCEXT = %Exp:MV_PAR05% AND 
			TWQ.TWQ_DATA BETWEEN %Exp:dDtIniApu% AND %Exp:dDtFimApu% AND
			TWQ.%NotDel% AND
			TFF.TFF_PERINI <= %Exp:dDtFimApu% AND
			TFF.TFF_PERFIM >= %Exp:dDtIniApu% 
		GROUP BY TWQ.TWQ_FILIAL, TFF.TFF_CODPAI, TFF_COD			
	EndSql 
Else	
	BeginSql Alias cAliasTW7
		SELECT	SUM(TWQ.TWQ_VALOR) TWQ_VALOR, TWQ_FILIAL, TFF_CODPAI, TFF_COD		
		FROM %table:TWQ% TWQ
				
		INNER JOIN %table:CN9% CN9 ON
			CN9.CN9_FILIAL  = %xFilial:CN9%  AND 
			CN9.CN9_NUMERO  = TWQ.TWQ_CONTRT AND 
			CN9.CN9_REVISA	= TWQ.TWQ_CONREV AND 	
			CN9.%NotDel% 	
		INNER JOIN  %table:TFF% TFF 
			ON	TFF.TFF_FILIAL =  %xFilial:TFF%   AND 
				TFF.TFF_COD = TWQ.TWQ_POSTRH AND 
				TFF.%NotDel%	
		INNER JOIN %table:TFL% TFL ON
				TFL.TFL_FILIAL = %xFilial:TFL%  AND 
				TFL.TFL_CODIGO = TFF.TFF_CODPAI AND  
				TFL.%NotDel%                    AND
				%Exp:cChvTFL%
		WHERE		
			TWQ.TWQ_FILIAL  = %xFilial:TWQ% AND 
			TWQ.TWQ_POSTRH <> '' AND 
			TWQ.TWQ_PEDIDO = '' AND 
			TWQ.TWQ_DATA BETWEEN %Exp:dDtIniApu% AND %Exp:dDtFimApu% AND
			TWQ.%NotDel% AND
			TFF.TFF_PERINI <= %Exp:dDtFimApu% AND
			TFF.TFF_PERFIM >= %Exp:dDtIniApu% 
		GROUP BY TWQ.TWQ_FILIAL, TFF.TFF_CODPAI, TFF_COD					
	EndSql 
EndIf

oModelTW7:GetStruct():SetProperty('TW7_MODO',MODEL_FIELD_WHEN,{||.T.})

While (cAliasTW7)->(!Eof())	 
	For nX := 1 To oModelTFW:Length()
		oModelTFW:GoLine(nX) 								
		If !oModelTFW:IsDeleted()
			If !oModelTFW:IsDeleted() .And. (oModelTFW:GetValue('TFW_CODTFL') == (cAliasTW7)->TFF_CODPAI) .And. (oModelTFW:GetValue('TFW_CODTFF') == (cAliasTW7)->TFF_COD) 
												
				If oModelTW7:Length() > 1 
					oModelTW7:AddLine()
				EndIf
				
				oModel:SetValue( "TFWTW7DETAIL", "TW7_FILIAL",	(cAliasTW7)->TWQ_FILIAL	)
				oModel:SetValue( "TFWTW7DETAIL", "TW7_TPPAI",	"RH"					)
				oModel:SetValue( "TFWTW7DETAIL", "TW7_CODPAI",	(cAliasTW7)->TFF_CODPAI	)
				oModel:SetValue( "TFWTW7DETAIL", "TW7_TPMOV",	"1"						) 
				oModel:SetValue( "TFWTW7DETAIL", "TW7_DESCRI",	STR0144					) //"Desp. Adicionais" 		
				oModel:SetValue( "TFWTW7DETAIL", "TW7_VALOR",	(cAliasTW7)->TWQ_VALOR	)
				oModel:SetValue( "TFWTW7DETAIL", "TW7_MODO",	"1"						) 
				oModel:SetValue( "TFWTW7DETAIL", "TW7_DESPAD",	"1" 					)	
				
				nI ++
			EndIf
		EndIf
	Next nX

	(cAliasTW7)->(DbSkip())
		
EndDo

(cAliasTW7)->(DbCloseArea())
oModelTW7:GetStruct():SetProperty('TW7_MODO',MODEL_FIELD_WHEN,{||.F.})

Return(Nil)

//------------------------------------------------------------------------------
/*/{Protheus.doc} GetVlrProp
Retorna o valor proporcional dentro de um periodo
@sample 	getVlrProp() 
@param		dIni - Data inicial para a primeira consistencia
@param		dFim - Data final para a primeira consistencia
@param		nVlr - Valor para a consistencia
@param		dParIni - Data inicial para a segunda consistencia
@param		dParFim - Data final para a segunda consistencia
@return	ExpL	Nil
@since		03/01/2014
@author		Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------//
Static Function GetVlrProp(dIni, dFim, nVlr, dParIni, dParFim, cApuMed, dEntre, dCole, cCodTFI, nQtdVen, cNumCtr)

Local nDifDias	:= (dParFim - dParIni) + 1
Local nDifCalc	:= 0//(dFim - dIni) + 1
Local nRet			:= 0
Local dDtRemes	:= sTod("")
Local nPerCalc	:= 0

Default cApuMed := "1"
Default cNumCtr := ""
	
If cApuMed == "1" .or. Empty(cApuMed)
	//Tipo da Apuração -> Inicio Periodo - Fim Periodo
	If valType(dIni) == "C"
		dIni := STOD(dINI)
	EndIf
	
	If ValType(dFim) == "C"
		dFim := STOD(dFim)
	EndIf
	
	nDifCalc := (dFim - dIni) + 1
		
	nDifDias := At930CQtdC(dParIni,dIni,dParFim,dFim)
		
	If nDifCalc > nDifDias
		nPerCalc := (nDifDias / nDifCalc) * 100
		nRet := (nVlr * nPerCalc)/100
	Else
		nRet := nVlr
	EndIf
		
ElseIf cApuMed == "2"
	//Tipo da Apuração -> Entrega - Coleta
	If valType(dEntre) == "C"
		dEntre := STOD(dEntre)
	EndIf
	
	If ValType(dCole) == "C"
		dCole := STOD(dCole)
	EndIf
	
	nDifCalc := (dCole - dEntre) + 1
		
	nDifDias := At930CQtdC(dParIni,dEntre,dParFim,dCole)
		
	If nDifCalc > nDifDias
		nPerCalc := (nDifDias / nDifCalc) * 100
		nRet := (nVlr * nPerCalc)/100
	Else
		nRet := nVlr
	EndIf
		
ElseIF cApuMed == "3"
	//Tipo da Apuração -> Inicio Periodo - Coleta
	If valType(dIni) == "C"
		dIni := STOD(dINI)
	EndIf
	
	If ValType(dCole) == "C"
		dCole := STOD(dCole)
	EndIf
	
	nDifCalc := (dCole - dIni) + 1
		
	nDifDias := At930CQtdC(dParIni,dIni,dParFim,dCole)
		
	If nDifCalc > nDifDias
		nPerCalc := (nDifDias / nDifCalc) * 100
		nRet := (nVlr * nPerCalc)/100
	Else
		nRet := nVlr
	EndIf
		
ElseIF cApuMed == "4"
	//Tipo da Apuração -> Entrega - Fim Periodo
	If valType(dEntre) == "C"
		dEntre := STOD(dEntre)
	EndIf
	
	If ValType(dFim) == "C"
		dFim := STOD(dFim)
	EndIf
	
	nDifCalc := (dFim - dEntre) + 1
		
	nDifDias := At930CQtdC(dParIni,dEntre,dParFim,dFim)
	
	If nDifCalc > nDifDias
		nPerCalc := (nDifDias / nDifCalc) * 100
		nRet := (nVlr * nPerCalc)/100
	Else
		nRet := nVlr
	EndIf

ElseIF cApuMed == "5"
	//Tipo da Apuração -> Data Nota de Remessa do Item. - Fim Periodo
	dDtRemes := At930MinDt(cCodTFI)
	
	If ValType(dDtRemes) == "C"
		dDtRemes := STOD(dDtRemes)
	EndIf
	
	If ValType(dFim) == "C"
		dFim := STOD(dFim)
	EndIf

	If dDtRemes <> sTod("")
	
		nDifCalc := (dFim - dDtRemes) + 1
			
		nDifDias := At930CQtdC(dParIni,dDtRemes,dParFim,dFim)
			
		If nDifCalc > nDifDias
			nPerCalc := (nDifDias / nDifCalc) * 100
			nRet := (nVlr * nPerCalc)/100
		Else
			nRet := nVlr
		EndIf
	Else
		nRet := nVlr
	Endif
EndIf

//Quando for contrato recorrente 
If !At740Recor(cNumCtr)
	If nDifDias > 0
		nRet := (nQtdVen*30)
	Else
		nRet := 0
	Endif
Endif

Return Round(nRet, 2)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At930LoEq
Load das informações da tela de locação de Equipamentos
@sample 	At930LoEq() 
@param		cContrato - Contrato que será apurado
@return	ExpL	Nil
@since		22/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------//
Static Function At930LoEq(cContrato,oModel)
Local aArea		:= GetArea()
Local cAliasTFL	:= GetNextAlias()
Local cAliasTFI	:= GetNextAlias()
Local cAliasQry	:= GetNextAlias()
Local cAliasTW7	:= GetNextAlias()
Local cAliasTEW	:= "TEW"
Local cCodTfi		:= ""
Local cQuery		:= ""
Local nCont			:= 0
Local nTotal		:= 0
Local nX			:= 0
Local oModelTFL	:= oModel:GetModel("TFLDETAIL")
Local oModelTFI	:= oModel:GetModel("TFIPRODUT")
Local oModelTFZ	:= oModel:GetModel("TFZDETAIL")
Local oModelTW7	:= oModel:GetModel("TFITW7DETAIL")  //Grid de Acrescimos/Decréscimos (Bonificação/Desconto)
Local aTEV			:= {}
Local aTFI			:= {}
Local aTFL			:= {}
Local nPos			:= 0
Local nI			:= 0
Local nY			:= 0
Local nZ			:= 0
Local nCalcDisp	:= 0
Local nCalcUso	:= 0
Local nCalcMob	:= 0

Local aQtdTFL		:= {}
Local aQtdTFI		:= {}
Local aEquip		:= {}
Local cRevCtr		:= Posicione("CN9",7,xFilial("CN9")+MV_PAR01+"05","CN9_REVISA")
Local nDiasApurados	:= 0
Local nValAddAcres	:= 0
Local nValApuHoras	:= 0
Local aTW7Aresc		:= {}
Local oMdlAcresc		:= Nil
Local lAddLine		:= .F.
Local lNotId			:= 0
Local nTotEqupD		:= 0
Local nTotEqupO		:= 0
Local dDataSai		:= Ctod('  /  /    ')
Local dDataRet		:= Ctod('  /  /    ')
Local aDataSai		:= {}
Local aDataRet		:= {}
Local nTotEqupM   	:= 0
Local nQtdApu 		:= 0
Local nVlrApu		:= 0
Local nCont			:= 0
Local cWhereLoEq    := ""
Local cChvTFL       := ""
Local nX		:= 0
Local nI 		:= 0
Local dDtIniApu	:= MV_PAR02 
Local dDtFimApu	:= MV_PAR03

//grupo de Faturamento
Local lGrpFatOrc:= TFJ->TFJ_GRPFAT== "1"
Local cPlanLE	:= ""


If lTeca934 //ajustar data da apuração para mês anterior
	dDtIniApu	:= MV_PAR05 
	dDtFimApu	:= MV_PAR06
EndIf


If lSrvExt
	cWhereLoEq := "%TFI.TFI_SRVEXT = '1'%"
	
	cChvTFL    := "%TFL.TFL_CODIGO = TFI.TFI_CODPAI AND "
	cChvTFL    += " TFL.TFL_CODPAI = '"+MV_PAR05+"'%"
Else
	cWhereLoEq := "%TFI.TFI_CONTRT = '"+MV_PAR01+"' AND "
	cWhereLoEq += "	TFI.TFI_CONREV = '"+cRevCtr +"'%"
	
	cChvTFL    := "%TFL.TFL_CODIGO = TFI.TFI_CODPAI%"

EndIf

BeginSql Alias cAliasQry
	
	SELECT ABS.ABS_DESCRI, TFL.TFL_FILIAL, TFL.TFL_CODIGO, TFL.TFL_LOCAL,  TFL.TFL_DTINI,  TFL.TFL_DTFIM,
	       TFL.TFL_CODPAI, TFI.TFI_FILIAL, TFI.TFI_COD,    TFI.TFI_PRODUT, TFI.TFI_TES, TFI.TFI_APUMED, TFI.TFI_ENTEQP,
	       TFI.TFI_PERINI, TFI.TFI_PERFIM, TFI.TFI_TPCOBR, TFL.TFL_PLAN,   TEV.TEV_MODCOB, TEV.TEV_QTDE,
	       TFI.TFI_COLEQP, TEV.TEV_FILIAL, TEV.TEV_CODLOC, TEV.TEV_ITEM,   TFI.TFI_QTDVEN, TFI.TFI_DESCON, TFI.TFI_ITCNB,
	       TEV.TEV_VLRUNI, ((TEV.TEV_VLRUNI * TEV.TEV_QTDE) + TEV.TEV_TXLUCR + TEV.TEV_TXADM - TFI.TFI_VALDES ) TEV_TOTAL
	  FROM %table:TEV% TEV
	       INNER JOIN %table:TFI% TFI ON TFI.TFI_FILIAL  = %xFilial:TFI%
	                                 AND TFI.%NotDel%
	                                 AND TFI.TFI_COD = TEV.TEV_CODLOC
	       INNER JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL% 
									 AND TFL.%NotDel% 	               
									 AND %Exp:cChvTFL%
	       LEFT JOIN %table:ABS% ABS  ON ABS.ABS_FILIAL = %xFilial:ABS%
	                                 AND ABS.%NotDel%
	                                 AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
	 WHERE TEV.TEV_FILIAL = %xFilial:TEV%
	   AND TEV.%NotDel%
	   AND %Exp:cWhereLoEq%
	   AND (     ( TFI.TFI_APUMED IN (" ","1","5") AND TFI.TFI_PERINI <= %Exp:dDtFimApu% AND TFI.TFI_PERFIM >= %Exp:dDtIniApu%)	// 1=Inicio(Locação)/Fim(Locação) ou 5=Dt. Nota de Remessa do Item./Fim(Locação)
	          OR ( TFI.TFI_APUMED = "2"            AND TFI.TFI_ENTEQP <= %Exp:dDtFimApu% AND TFI.TFI_COLEQP >= %Exp:dDtIniApu%)	// 2=Agenda.(Entrega)/Coleta(Equip)
	          OR ( TFI.TFI_APUMED = "3"            AND TFI.TFI_PERINI <= %Exp:dDtFimApu% AND TFI.TFI_COLEQP >= %Exp:dDtIniApu%)	// 3=Inicio(Locação)/Coleta(Equip)
	          OR ( TFI.TFI_APUMED = "4"            AND TFI.TFI_ENTEQP <= %Exp:dDtFimApu% AND TFI.TFI_PERFIM >= %Exp:dDtIniApu%)	// 4=Agenda.(Entrega)/Fim(Locação)
	       )
EndSql 

nCalcDisp := 0
nCalcUso  := 0
nCalcMob  := 0

At970SetHm()	// Inicializa os valores de medição/apuração de horimetro

aEquip := GetPerDisp(MV_PAR01, cRevCtr, dDtIniApu, dDtFimApu)

While (cAliasQry)->( ! Eof() )	 
		
	nPos := aScan(aTFL, {|x| x[_TFLCODIGO] == (cAliasQry)->TFL_CODIGO}) 
	If nPos == 0
		aAdd(aTFL, Array(_TFLPLAN)) 
		nPos := Len(aTFL) 
		aTfl[nPos][_TFLFILIAL] := (cAliasQry)->TFL_FILIAL
		aTfl[nPos][_TFLCODIGO] := (cAliasQry)->TFL_CODIGO
		aTfl[nPos][_TFLLOCAL]  := (cAliasQry)->TFL_LOCAL
		aTfl[nPos][_TFLDTINI]  := STOD((cAliasQry)->TFL_DTINI)
		aTfl[nPos][_TFLDTFIM]  := STOD((cAliasQry)->TFL_DTFIM)
		aTfl[nPos][_TFLCODPAI] := (cAliasQry)->TFL_CODPAI
		aTfl[nPos][_TFLDESC]   := (cAliasQry)->ABS_DESCRI
		aTfl[nPos][_TFLUSO]    := 0
		aTfl[nPos][_TFLDISP]   := 0
		aTfl[nPos][_TFLMOB]    := 0
		aTfl[nPos][_TFLTOTAL]  := 0		
		aTfl[nPos][_TFLTOTAL]  := 0
		If !lGrpFatOrc
			aTfl[nPos][_TFLPLAN]   := (cAliasQry)->TFL_PLAN		
		Else
			At870GrPlan( TFJ->TFJ_CODGRP,(cAliasQry)->TFL_LOCAL ,,,, @cPlanLE )
			aTfl[nPos][_TFLPLAN]   := cPlanLE
		EndIf		
	EndIf
				
	nPos := aScan(aTFI, {|x| x[_TFICODIGO] == (cAliasQry)->TFI_COD})
	If nPos == 0
		aAdd(aTFI, Array(_TFIPREV))
		nPos := Len(aTFI)
		aTFI[nPos][_TFIFILIAL] := (cAliasQry)->TFI_FILIAL 
		aTFI[nPos][_TFICODIGO] := (cAliasQry)->TFI_COD
		aTFI[nPos][_TFICODPAI] := (cAliasQry)->TFL_CODIGO
		aTFI[nPos][_TFIPRODUT] := (cAliasQry)->TFI_PRODUT
		aTFI[nPos][_TFIDESCON] := (cAliasQry)->TFI_DESCON
		aTFI[nPos][_TFIUSO]    := 0
		aTFI[nPos][_TFIDISP]   := 0
		aTFI[nPos][_TFIMOB]    := 0
		aTFI[nPos][_TFITOTAL]  := 0		
		aTFI[nPos][_TFIITCNB]  := (cAliasQry)->TFI_ITCNB
		aTFI[nPos][_TFIQTDVEN]  := (cAliasQry)->TFI_QTDVEN
		aTFI[nPos][_TFIPERINI]  := (cAliasQry)->TFI_PERINI
		aTFI[nPos][_TFIPERFIM]  := (cAliasQry)->TFI_PERFIM
		aTFI[nPos][_TFITES]  := (cAliasQry)->TFI_TES
	EndIf	
		
	aAdd(aTEV, Array(_TEVPREV))
	nPos := Len(aTEV)
	aTEV[nPos][_TEVFILIAL]  := (cAliasQry)->TEV_FILIAL
	aTEV[nPos][_TEVCODLOC]  := (cAliasQry)->TEV_CODLOC
	aTEV[nPos][_TEVITEM]    := (cAliasQry)->TEV_ITEM
	aTEV[nPos][_TEVTOTAL]   := (cAliasQry)->TEV_TOTAL
	aTEV[nPos][_TEVMODCOB]  := (cAliasQry)->TEV_MODCOB
	aTEV[nPos][_TEVCODTFI]  := (cAliasQry)->TFI_COD
	aTEV[nPos][_TEVCODTFL]  := (cAliasQry)->TFL_CODIGO
	aTEV[nPos][_TEVQTDORI]  := (cAliasQry)->TEV_QTDE


	// cálculo da quantidade prevista de locação para o período de locação
	//1=Uso;2=Disponibilidade;3=Mobilizacao;4=Horas;5=Franquia/Excedente
	If aTEV[nPos][_TEVMODCOB] == "4" .Or. aTEV[nPos][_TEVMODCOB] == "5"
		//  Quando for horas ou franquia calcula a quantidade prevista considerando
		// da última atualização do medidor (data mais recente) até a data da última medição ou início de alocação (data mais antiga)
		// Caso não exista lançamento não haverá valor sugerido, nem apurado
		aTEV[nPos][_TEVQTDE]	:= GetVlrHoras( (cAliasQry)->TFI_COD,;
		                                     STOD((cAliasQry)->TFI_PERINI),;
		                                     STOD((cAliasQry)->TFI_PERFIM),;
		                                     (cAliasQry)->TFI_QTDVEN,;
		                                     (cAliasQry)->TEV_QTDE )
	Else
		aTEV[nPos][_TEVQTDE]	:= GetVlrProp((cAliasQry)->TFI_PERINI,;
		                                   (cAliasQry)->TFI_PERFIM,;
		                                   (cAliasQry)->TEV_QTDE,;
		                                   dDtIniApu,;
		                                   dDtFimApu,;
		                                   (cAliasQry)->TFI_APUMED,;
		                                   (cAliasQry)->TFI_ENTEQP,;
		                                   (cAliasQry)->TFI_COLEQP,;
	                                  	   (cAliasQry)->TFI_COD,;
	                                  	   (cAliasQry)->TFI_QTDVEN,;
	                                  	   MV_PAR01)
	EndIf
	aTEV[nPos][_TEVVLRUNI] := (cAliasQry)->TEV_VLRUNI	//TFZ_VLRUNI
	aTEV[nPos][_TEVQTDEAPU] := 0
	// cálculo da quantidade apurada de locação para o período		
	If (cAliasQry)->TEV_MODCOB == "2"	//2=Disponibilidade
		//soma o total de dias alocados de disponibilidade
		nDiasApurados := 0
		aEval( aEquip, {|x| If( x[1] == (cAliasQry)->TFI_COD, nDiasApurados+= x[2], nil) } )
		aTEV[nPos][_TEVQTDEAPU] :=  nDiasApurados

	ElseIf aTEV[nPos][_TEVQTDE] > 0 .And. ;  // só
		((cAliasQry)->TEV_MODCOB == "4" .Or. (cAliasQry)->TEV_MODCOB == "5")  //4=Horas ou 5=Franquia/Excedente

		//soma as horas lançadas dos equipamentos alocados no item
		nValApuHoras := 0
		aEval( aEquip, {|x| If( x[1] == (cAliasQry)->TFI_COD, nValApuHoras+= x[6], nil) } )

		// quantidade a ser acrescida igual a diferença entre apurada e prevista
		nValAddAcres := nValApuHoras - aTEV[nPos][_TEVQTDE]

		// corrige o valor para ser acrescido quando não há necessidade de acrescentar valor
		nValAddAcres := IIf( nValAddAcres < 0, 0, nValAddAcres )

		// qtde apurada igual a quantidade prevista quando existe valor a ser acrescido
		nValApuHoras := IIf( nValAddAcres > 0, aTEV[nPos][_TEVQTDE], nValApuHoras)

		If nValApuHoras > 0 .And. (cAliasQry)->TEV_MODCOB == "4"
			aTEV[nPos][_TEVQTDEAPU] += nValApuHoras
		EndIf

		If nValAddAcres > 0
			aAdd( aTW7Aresc, Array(_TW7_MAX) )  // cria array para todas as posições
			nI := Len(aTW7Aresc)
			aTW7Aresc[nI,_TW7FILIAL] := (cAliasQry)->TFI_FILIAL
			aTW7Aresc[nI,_TW7TFICOD] := (cAliasQry)->TFI_COD
			aTW7Aresc[nI,_TW7TEVITE] := (cAliasQry)->TEV_ITEM
			aTW7Aresc[nI,_TW7TPPAI]  := "LE"
			aTW7Aresc[nI,_TW7TIPOMV] := "1" // 1=Multa;2=Bonificação
			aTW7Aresc[nI,_TW7DESCRI] := STR0156 //"HORAS EXCEDENTES LOCAÇÃO "
			aTW7Aresc[nI,_TW7VALOR]  := nValAddAcres * (cAliasQry)->TEV_VLRUNI
			aTW7Aresc[nI,_TW7MODO]   := "2" // 1=Automático;2=Manual
			aTW7Aresc[nI,_TW7FLGPED] := "1" // 1=Sim;2=Não
		EndIf
	Else
		aTEV[nPos][_TEVQTDEAPU] += aTEV[nPos][_TEVQTDE]
	EndIf
		
	(cAliasQry)->(dbSkip())

EndDo

For nI:= 1 To Len(aTFL)		
	If nI != 1
		oModelTFL:AddLine()
	EndIf

	oModel:LoadValue("TFLDETAIL", "TFL_FILIAL", aTFL[nI][_TFLFILIAL])
	oModel:LoadValue("TFLDETAIL", "TFL_CODIGO", aTFL[nI][_TFLCODIGO])
	oModel:SetValue("TFLDETAIL",  "TFL_LOCAL",  aTFL[nI][_TFLLOCAL])
	oModel:SetValue("TFLDETAIL",  "TFL_DESLOC", aTFL[nI][_TFLDESC])
	oModel:SetValue("TFLDETAIL",  "TFL_DTINI",  aTFL[nI][_TFLDTINI])
	oModel:LoadValue("TFLDETAIL", "TFL_DTFIM",  aTFL[nI][_TFLDTFIM])
	oModel:LoadValue("TFLDETAIL", "TFL_CODPAI", aTFL[nI][_TFLCODPAI])
	oModel:SetValue("TFLDETAIL",  "TFL_DISP",   aTFL[nI][_TFLDISP])
	oModel:SetValue("TFLDETAIL",  "TFL_USO",    aTFL[nI][_TFLUSO])
	oModel:SetValue("TFLDETAIL",  "TFL_MOBILI", aTFL[nI][_TFLMOB])
	oModel:SetValue("TFLDETAIL",  "TFL_VALTOT", aTFL[nI][_TFLTOTAL])
	oModel:SetValue("TFLDETAIL",  "TFL_PLAN",   aTFL[nI][_TFLPLAN])
	
	aAdd(aQtdTFL, {aTFL[nI][_TFLCODIGO], .F.})
	
Next nI	

// Ordena pelo código da TFI e fará a adição das linhas em conjunto com a TFI
ASORT(aTW7Aresc, , , { | x,y | x[_TW7TFICOD] > y[_TW7TFICOD] } )
oMdlAcresc := oModel:GetModel("TFITW7DETAIL")

oMdlAcresc:GetStruct():SetProperty('TW7_MODO',MODEL_FIELD_WHEN,{||.T.})
For nY:=1 To Len(aTFI)			
		
	oModelTFL:SeekLine({ {"TFL_CODIGO",aTFI[nY][_TFICODPAI]} })	
	
	nPos := aScan(aQtdTFL, {|x| x[1]==aTFI[nY][_TFICODPAI]})	
	If nPos > 0
		If aQtdTFL[nPos][2]
			oModelTFI:AddLine()
		Else
			aQtdTFL[nPos][2] := .T.			
		EndIf
	EndIf	
							
	oModel:LoadValue("TFIPRODUT", "TFI_FILIAL", aTFI[nY][_TFIFILIAL])
	oModel:SetValue("TFIPRODUT",  "TFI_PRODUT", aTFI[nY][_TFIPRODUT])
	oModel:LoadValue("TFIPRODUT", "TFI_CODPAI", aTFI[nY][_TFICODPAI])
	oModel:LoadValue("TFIPRODUT", "TFI_COD",    aTFI[nY][_TFICODIGO])
	oModel:SetValue("TFIPRODUT",  "TFI_DISP",   aTFI[nY][_TFIDISP])
	oModel:SetValue("TFIPRODUT",  "TFI_USO",    aTFI[nY][_TFIUSO])
	oModel:SetValue("TFIPRODUT",  "TFI_MOBILI", aTFI[nY][_TFIMOB])
	oModel:SetValue("TFIPRODUT",  "TFI_DESCON", aTFI[nY][_TFIDESCON])
	oModel:SetValue("TFIPRODUT",  "TFI_ITCNB", aTFI[nY][_TFIITCNB])
	oModel:SetValue("TFIPRODUT",  "TFI_QTDVEN", aTFI[nY][_TFIQTDVEN])
	oModel:LoadValue("TFIPRODUT",  "TFI_PERINI", Stod(aTFI[nY][_TFIPERINI]))
	oModel:LoadValue("TFIPRODUT",  "TFI_PERFIM", Stod(aTFI[nY][_TFIPERFIM]))
	oModel:LoadValue("TFIPRODUT",  "TFI_TES", aTFI[nY][_TFITES])
	
	aAdd(aQtdTFI, {aTFI[nY][_TFICODIGO], .F.})	
	
	//Realizar a carga da aba de Desconto por OS
	At930LoOs(oModel, aEquip)
	
	//  avalia se há acréscimos a serem adicionados por causa de uso dos equipamentos com medidores
	// adiciona neste momento para ficar com o vínculo do primeiro item de TFZ depois e não ter problemas na visualização, estorno
	nPos := aScan(aTW7Aresc, {|x| x[_TW7FILIAL]==aTFI[nY,_TFIFILIAL] .And. ;
									x[_TW7TFICOD]==aTFI[nY,_TFICODIGO] })

	If nPos > 0

		nI := Len(aTW7Aresc)
		cCodTfi := aTW7Aresc[nPos,_TW7TFICOD]
		

		While nPos <= nI .And. aTW7Aresc[nPos,_TW7TFICOD] == cCodTfi

			nI := oMdlAcresc:Length()
			lAddLine := ( nI > 1 .Or. ( nI == 1 .And. !Empty(oMdlAcresc:GetValue("TW7_DESCRI") ) ) )

			If lAddLine
				oMdlAcresc:GoLine(nI)
				oMdlAcresc:AddLine()
				nI := oMdlAcresc:GetLine()
			EndIf

			oMdlAcresc:SetValue("TW7_FILIAL",aTW7Aresc[nPos,_TW7FILIAL])
			oMdlAcresc:SetValue("TW7_TPPAI" ,aTW7Aresc[nPos,_TW7TPPAI])
			oMdlAcresc:SetValue("TW7_TPMOV" ,aTW7Aresc[nPos,_TW7TIPOMV])
			oMdlAcresc:SetValue("TW7_DESCRI",aTW7Aresc[nPos,_TW7DESCRI])
			oMdlAcresc:SetValue("TW7_VALOR" ,aTW7Aresc[nPos,_TW7VALOR])
			oMdlAcresc:SetValue("TW7_MODO"  ,aTW7Aresc[nPos,_TW7MODO])
			oMdlAcresc:SetValue("TW7_FLGPED",aTW7Aresc[nPos,_TW7FLGPED])

			oMdlAcresc:SetValue("TW7_CODPAI",oModel:GetValue("TFZDETAIL", "TFZ_CODIGO"))

			nPos++
		End
	EndIf

Next nY
oMdlAcresc:GetStruct():SetProperty('TW7_MODO',MODEL_FIELD_WHEN,{||.F.})

For nZ:=1 To Len(aTEV)		
	If oModelTFL:SeekLine({ {"TFL_CODIGO",aTEV[nZ][_TEVCODTFL]} })
		If oModelTFI:SeekLine({ {"TFI_COD",aTEV[nZ][_TEVCODTFI]},{"TFI_CODPAI",aTEV[nZ][_TEVCODTFL]} })	
			
			nPos := aScan(aQtdTFI, {|x| x[1]==aTEV[nZ][_TEVCODTFI]})	
			If nPos > 0
				If aQtdTFI[nPos][2]
					oModelTFZ:AddLine()
				Else
					aQtdTFI[nPos][2] := .T.			
				EndIf
			EndIf
				
	 		  lNotId := SuperGetMv('MV_TECATF', .F.,'N') == 'S' .And. Posicione("SB5",1,xFilial("SB5")+oModelTFI:GetValue('TFI_PRODUT'),'B5_ISIDUNI') == '2'
            If aTEV[nZ][_TEVMODCOB] == '2' .And. lNotId

				//-- Dias da item de locação
				aQtd := At930GetQt(oModelTFI:GetValue('TFI_COD'),oModel:GetModel("TFVMASTER"):GetValue("TFV_DTINI"))

				aDataSai := {}
				aDataRet 	:= {}
				nDias 	 	 := 0
				nTotEqupO 	 := 0
				nTotEqupD 	 := 0
				nTotEqupM 	 := 0
				nQtdApu 	 := 0
				nTotal 	 := 0


				For nCont := 1 To Len(aQtd)
					aDataSai := {}
					aDataRet := {}

					If !Empty(aQtd[nCont,2])
						Aadd(aDataSai, StoD(aQtd[nCont,2]))
					EndIf

					Aadd(aDataSai, oModel:GetModel("TFVMASTER"):GetValue("TFV_DTINI"))
					Aadd(aDataSai, oModelTFI:GetValue("TFI_PERINI"))

					If !Empty(aQtd[nCont,3])
						Aadd(aDataRet, StoD(aQtd[nCont,3]))
					EndIf

					Aadd(aDataRet, oModel:GetModel("TFVMASTER"):GetValue("TFV_DTFIM"))
					Aadd(aDataRet, oModelTFI:GetValue("TFI_PERFIM"))
                 	dDataSai := GetMax(aDataSai)
                 	dDataRet := GetMin(aDataRet)

					//-- Total do item da locação
					nDias := dDataRet - dDataSai + 1
					nTotEqupO   := oModelTFI:GetValue('TFI_QTDVEN') * aTEV[nZ][_TEVQTDORI]
					nTotEqupD   := nDias * aQtd[nCont,1]

					//-- Total da medição
					nTotEqupM   := nTotEqupD / nTotEqupO

					//-- Valor da apuração
					nQtdApu += nTotEqupM * aTEV[nZ][_TEVQTDORI]
				Next nCont
				nTotal := nQtdApu * aTEV[nZ][_TEVVLRUNI] * ( 1 - ( oModelTFI:GetValue('TFI_DESCON') / 100 ) )
			Else
          		nTotal := aTEV[nZ][_TEVQTDEAPU] * aTEV[nZ][_TEVVLRUNI] * ( 1 - ( oModelTFI:GetValue('TFI_DESCON')  / 100 ) )
			EndIf

			oModel:LoadValue("TFZDETAIL", "TFZ_LOCAL",  oModel:GetModel("TFLDETAIL"):GetValue("TFL_LOCAL"))
			oModel:LoadValue("TFZDETAIL", "TFZ_DESCRI", oModel:GetModel("TFLDETAIL"):GetValue("TFL_DESLOC"))
			oModel:LoadValue("TFZDETAIL", "TFZ_CODTFL", oModel:GetModel("TFLDETAIL"):GetValue("TFL_CODIGO"))			
			oModel:LoadValue("TFZDETAIL", "TFZ_CODTFI", aTEV[nZ][_TEVCODTFI])
			oModel:LoadValue("TFZDETAIL", "TFZ_CODTEV", aTEV[nZ][_TEVITEM])


            If aTEV[nZ][_TEVMODCOB] == '2' .And. lNotId
            	oModel:LoadValue("TFZDETAIL", "TFZ_QTDAPU", nQtdApu)
			Else
			oModel:LoadValue("TFZDETAIL", "TFZ_QTDAPU", aTEV[nZ][_TEVQTDEAPU])
			EndIf

			oModel:LoadValue("TFZDETAIL", "TFZ_QTDE",   aTEV[nZ][_TEVQTDE])

			oModel:LoadValue("TFZDETAIL", "TFZ_VLRUNI", aTEV[nZ][_TEVVLRUNI])			
			oModel:LoadValue("TFZDETAIL", "TFZ_TOTAL",  nTotal)
			oModel:LoadValue("TFZDETAIL", "TFZ_MODCOB", aTEV[nZ][_TEVMODCOB])
			oModel:LoadValue("TFZDETAIL", "TFZ_APURAC", oModel:GetModel("TFVMASTER"):GetValue("TFV_CODIGO"))
			
			Do Case//Totaliza valores de acordo com o modo de cobrança
				Case aTEV[nZ][_TEVMODCOB] == "1" .OR. aTEV[nZ][_TEVMODCOB] == "4" //Uso ou Horas
					oModel:LoadValue("TFLDETAIL", "TFL_USO", oModel:GetModel("TFLDETAIL"):GetValue("TFL_USO") + nTotal)
					oModel:LoadValue("TFIPRODUT", "TFI_USO", oModel:GetModel("TFIPRODUT"):GetValue("TFI_USO") + nTotal)			
				Case aTEV[nZ][_TEVMODCOB] == "2"//Disponibilidade
					oModel:LoadValue("TFLDETAIL", "TFL_DISP", oModel:GetModel( "TFLDETAIL" ):GetValue("TFL_DISP") + nTotal)
					oModel:LoadValue("TFIPRODUT", "TFI_DISP", oModel:GetModel( "TFIPRODUT" ):GetValue("TFI_DISP") + nTotal)					
				Case aTEV[nZ][_TEVMODCOB] == "3"//Mobilização
					oModel:LoadValue("TFLDETAIL", "TFL_MOBILI", oModel:GetModel( "TFLDETAIL" ):GetValue("TFL_MOBILI") + nTotal)
					oModel:LoadValue("TFIPRODUT", "TFI_MOBILI", oModel:GetModel( "TFIPRODUT" ):GetValue("TFI_MOBILI") + nTotal)					
			EndCase
			
			oModel:LoadValue("TFLDETAIL", "TFL_VALTOT", oModel:GetModel( "TFLDETAIL" ):GetValue("TFL_VALTOT")+ nTotal )
		EndIf
	EndIf	
Next nZ

If lSrvExt
	BeginSql Alias cAliasTW7
		
		SELECT	TWQ_VALOR, TWQ_FILIAL, TWQ_POSTLE, TFI_CODPAI, TFI_COD		
		FROM %table:TWQ% TWQ
					
		INNER JOIN %table:TFI% TFI ON 
			TFI.TFI_FILIAL  = %xFilial:TFI%  AND	
			TFI.TFI_COD 	= TWQ.TWQ_POSTLE AND 
			TFI.%NotDel%	
		INNER JOIN %table:TFL% TFL ON
			TFL.TFL_FILIAL = %xFilial:TFL% AND
			TFL.TFL_CODIGO = TFI.TFI_CODPAI AND 		 
			TFL.%NotDel% 	               AND
			%Exp:cChvTFL%		
		WHERE		
			TWQ.TWQ_FILIAL  = %xFilial:TWQ% AND 
			TWQ.TWQ_POSTLE <> '' AND 
			TWQ.TWQ_PEDIDO = '' AND
			TWQ.TWQ_DATA BETWEEN %Exp:dDtIniApu% AND %Exp:dDtFimApu% AND 		
			TWQ.%NotDel% AND
			TFI.TFI_PERINI <= %Exp:dDtFimApu% AND
			TFI.TFI_PERFIM >= %Exp:dDtIniApu% AND
			%Exp:cWhereLoEq%	
						
	EndSql 
Else
	BeginSql Alias cAliasTW7
		
		//SELECT	TWQ.TWQ_FILIAL,	TWQ.TWQ_DATA, 	TWQ.TWQ_POSTRH, TWQ.TWQ_POSTLE, TWQ.TWQ_VALOR,
				//CN9.CN9_FILIAL, CN9.CN9_NUMERO, CN9.CN9_REVISA, CN9.CN9_DTINIC, CN9.CN9_DTFIM, 	
				//CN9.CN9_VLATU, 	CN9.CN9_SALDO, 	CN9.CN9_FILORI,
				//TFI.TFI_COD, 	TFI.TFI_CODPAI
		SELECT	TWQ_VALOR, TWQ_FILIAL, TWQ_POSTLE, TFI_CODPAI, TFI_COD		
		FROM %table:TWQ% TWQ
				
		INNER JOIN %table:CN9% CN9 ON
			CN9.CN9_FILIAL  = %xFilial:CN9%  AND 
			CN9.CN9_NUMERO  = TWQ.TWQ_CONTRT AND 
			CN9.CN9_REVISA	= TWQ.TWQ_CONREV AND 	
			CN9.%NotDel% 		
		INNER JOIN %table:TFI% TFI ON 
			TFI.TFI_FILIAL  = %xFilial:TFI%  AND	
			TFI.TFI_COD 	= TWQ.TWQ_POSTLE AND 
			TFI.%NotDel%	
		INNER JOIN %table:TFL% TFL ON
			TFL.TFL_FILIAL = %xFilial:TFL% AND
			TFL.TFL_CODIGO = TFI.TFI_CODPAI AND 		 
			TFL.%NotDel% 	               AND
			%Exp:cChvTFL%		
		WHERE		
			TWQ.TWQ_FILIAL  = %xFilial:TWQ% AND 
			TWQ.TWQ_POSTLE <> '' AND 
			TWQ.TWQ_PEDIDO = '' AND
			TWQ.TWQ_DATA BETWEEN %Exp:dDtIniApu% AND %Exp:dDtFimApu% AND 		
			TWQ.%NotDel% AND
			TFI.TFI_PERINI <= %Exp:dDtFimApu% AND
			TFI.TFI_PERFIM >= %Exp:dDtIniApu% AND
			%Exp:cWhereLoEq%	
					
	EndSql 
EndIf

oModelTW7:GetStruct():SetProperty('TW7_MODO',MODEL_FIELD_WHEN,{||.T.})

While (cAliasTW7)->(!Eof())	 

	For nI := 1 To oModelTFL:Length()

		oModelTFL:GoLine(nI)
		
		For nX := 1 To oModelTFI:Length()
			oModelTFI:GoLine(nX) 								
			If !oModelTFI:IsDeleted() .And. oModelTFI:GetValue('TFI_CODPAI') == (cAliasTW7)->TFI_CODPAI .AND. oModelTFI:GetValue('TFI_COD') == (cAliasTW7)->TWQ_POSTLE
	
				If oModelTW7:Length() > 1 
					oModelTW7:AddLine()
				EndIf
			
				oModel:SetValue("TFITW7DETAIL", "TW7_FILIAL",	(cAliasTW7)->TWQ_FILIAL	)
				oModel:SetValue( "TFITW7DETAIL", "TW7_TPPAI",	"LE"					)
				oModel:SetValue( "TFITW7DETAIL", "TW7_CODPAI",	(cAliasTW7)->TFI_COD	)
				oModel:SetValue( "TFITW7DETAIL", "TW7_TPMOV",	"1"						) 
				oModel:SetValue( "TFITW7DETAIL", "TW7_DESCRI",	"Despesas"				) 		
				oModel:SetValue( "TFITW7DETAIL", "TW7_VALOR",	(cAliasTW7)->TWQ_VALOR	)
				oModel:SetValue( "TFITW7DETAIL", "TW7_MODO",	"1"						) 
				oModel:SetValue( "TFITW7DETAIL", "TW7_DESPAD",	"1" 					)	
			
				
			EndIf
		Next nX
	Next nI

	(cAliasTW7)->(DbSkip())
		
EndDo

oModelTW7:GetStruct():SetProperty('TW7_MODO',MODEL_FIELD_WHEN,{||.F.})

(cAliasTW7)->(DbCloseArea())

oModelTFL:GoLine(1)
oModelTFI:GoLine(1)
oModelTFZ:GoLine(1)
oModelTW7:GoLine(1)

(cAliasQry)->(DbCloseArea())
RestArea(aArea)

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} GetPerDisp
@since 06/01/2014
@version 11.9
@param        cContrt, character
@param        cRevisa, character
@param        dDtIni, Date
@param        dDtFim, Date
@return       aEquip, Array com equipamento e quantidade de dias utilizados para disponibilidade
@description Recupera estrutura de dados com quantidade de dias dos equipamentos locados 
/*/
//------------------------------------------------------------------------------//
Static Function GetPerDisp(cContrt, cRevisa, dDtIni, dDtFim)

Local cAliasTEW	:= GetNextAlias()
Local aArea		:= GetArea()
Local aEquip		:= {}
Local nPos			:= 0
Local dIni			:= STOD("")
Local dFim			:= STOD("")
Local lKit			:= .F.
Local cCodKit		:= ""
Local cKitSeq		:= ""
Local nHorasApont 	:= 0

BeginSql Alias cAliasTEW

	SELECT TFI.TFI_COD,   TEW.TEW_DTRINI, TEW.TEW_DTRFIM, TEW.TEW_DTAMNT, TEW.TEW_CODMV,
	       TEW.TEW_BAATD, TEW.TEW_CODKIT, TEW.TEW_KITSEQ, AA3.AA3_HMEATV
	  FROM %table:TEW% TEW
	       INNER JOIN %table:TFI% TFI ON TFI.TFI_FILIAL = %xFilial:TFI%
	                                 AND TFI.TFI_COD = TEW.TEW_CODEQU
	                                 AND TFI.%NotDel%
			INNER JOIN %table:AA3% AA3 ON AA3.AA3_NUMSER = TEW.TEW_BAATD
									AND AA3.AA3_FILORI = TEW.TEW_FILBAT
									AND AA3.%NotDel%
	 WHERE TEW.TEW_FILIAL = %xFilial:TEW%
	   AND TEW.%NotDel%
	   AND TFI.TFI_CONTRT = %Exp:cContrt%
	   AND TFI.TFI_CONREV = %Exp:cRevisa%
	   AND TEW.TEW_DTRINI <> ' '
	   AND ( 
	          ( TEW.TEW_DTRINI BETWEEN %Exp:dDtIni% AND %Exp:dDtFim% )
	          OR
	          (     TEW.TEW_MOTIVO <> ' '
	            AND LTRIM(RTRIM(TEW.TEW_DTAMNT)) <> ' ' 
	            AND TEW.TEW_DTAMNT BETWEEN %Exp:dDtIni% AND %Exp:dDtFim%
	          )
	          OR
	          (     TEW.TEW_MOTIVO = ' '
	            AND LTRIM(RTRIM(TEW.TEW_DTRFIM)) <> ' ' 
	            AND LTRIM(RTRIM(TEW.TEW_DTAMNT)) = ' ' 
	            AND TEW.TEW_DTRFIM BETWEEN %Exp:dDtIni% AND %Exp:dDtFim%
	          )
	          OR
	          (     TEW.TEW_DTRINI < %Exp:dDtIni%
	            AND (
	                  ( TEW.TEW_MOTIVO <> ' ' AND ( LTRIM(RTRIM(TEW.TEW_DTAMNT))=' ' OR TEW.TEW_DTAMNT > %Exp:dDtFim% ) )
	                  OR
	                  ( TEW.TEW_MOTIVO = ' ' AND ( LTRIM(RTRIM(TEW.TEW_DTRFIM))=' ' OR TEW.TEW_DTRFIM > %Exp:dDtFim% ) )
	                )
	          )
	       )
	 ORDER BY TFI.TFI_COD

EndSql

While (cAliasTEW)->(! Eof())
	If (cAliasTEW)->TEW_DTRINI >= DtoS(dDtIni)
		dIni	:= StoD((cAliasTEW)->TEW_DTRINI)
	Else
		dIni	:= dDtIni
	EndIf
	
	If ! Empty((cAliasTEW)->TEW_DTRFIM)
		If (cAliasTEW)->TEW_DTRFIM < DToS(dDtFim)
			dFim	:= StoD((cAliasTEW)->TEW_DTRFIM)			
		Else
			dFim	:= dDtFim
		EndIf 			
	ElseIf ! Empty((cAliasTEW)->TEW_DTAMNT)
		If (cAliasTEW)->TEW_DTAMNT < DToS(dDtFim)
			dFim	:= StoD((cAliasTEW)->TEW_DTAMNT)			
		Else
			dFim	:= dDtFim
		EndIf 	
	Else
		dFim	:= dDtFim 
	EndIf
	
	nPos := aScan(aEquip, {|x| x[1] ==(cAliasTEW)->TFI_COD .And. (cAliasTEW)->TEW_BAATD })
	nHorasApont := 0
	If nPos == 0		
		// avalia se tem horímetro ativo no equipamento
		If (cAliasTEW)->AA3_HMEATV == '1'
			// calcula a quantidade de horas lançadas no medidor do equipamento
			At970BldHm((cAliasTEW)->TEW_BAATD, (cAliasTEW)->TEW_CODMV, MV_PAR03)
			nHorasApont := At970TotHm((cAliasTEW)->TEW_BAATD)
		EndIf

		aAdd(aEquip, {(cAliasTEW)->TFI_COD, (dFim-dIni)+1, (cAliasTEW)->TEW_BAATD, dIni, dFim, nHorasApont})
		//Verifica se o produto é de kit, assim soma somente uma vez
		If !Empty((cAliasTEW)->TEW_CODKIT) .And. !Empty((cAliasTEW)->TEW_KITSEQ)
			lKit		:= .T.
			cCodKit	:= (cAliasTEW)->TEW_CODKIT
			cKitSeq	:= (cAliasTEW)->TEW_KITSEQ
		Else
			lKit		:= .F.
			cCodKit	:= (cAliasTEW)->TEW_CODKIT
			cKitSeq	:= (cAliasTEW)->TEW_KITSEQ
		EndIf	

	Else

		If lKit .And. cCodKit == (cAliasTEW)->TEW_CODKIT .And. cKitSeq <> (cAliasTEW)->TEW_KITSEQ
			aEquip[nPos][2]	+= (dFim-dIni) + 1
			cCodKit			:= (cAliasTEW)->TEW_CODKIT
			cKitSeq			:= (cAliasTEW)->TEW_KITSEQ
		ElseIf !lKit
			aEquip[nPos][2]	+= (dFim-dIni) + 1
		EndIf	

	EndIf

	(cAliasTEW)->(DbSkip())
EndDo

(cAliasTEW)->(dBCloseArea())
RestArea(aArea)
Return aEquip

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GatQdt
Quatilho para quantidade total da TFZ
@sample 	At930GatQdt() 
@param		Nenhum
@return	ExpL	nQntAtu - Quantidade Atual
@since		22/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------//
Function At930GatQdt()
Local oModel		:= FWModelActive()
Local oModelTFL	:= oModel:GetModel("TFLDETAIL")
Local nVlrAtu	:= 	0
Local nVlrAnt	:=	oModel:GetModel( "TFZDETAIL" ):GetValue( "TFZ_TOTAL" )
Local nVlTot	:=0
Local nVlTotAnt:=0
Local nVlrTFI := 0
Local nVlrTFL := 0

nVlrAtu := oModel:GetValue("TFZDETAIL", "TFZ_QTDAPU") * oModel:GetValue("TFZDETAIL", "TFZ_VLRUNI") * (1 - ( oModel:GetValue("TFIPRODUT", "TFI_DESCON") / 100 ) )
oModel:SetValue("TFZDETAIL", "TFZ_TOTAL", nVlrAtu)

nVlTotAnt := oModel:GetValue("TFLDETAIL", "TFL_USO") + oModel:GetValue("TFLDETAIL", "TFL_DISP") + oModel:GetValue("TFLDETAIL", "TFL_MOBILI")

//Atualiza grid TEV TFI TFL
Do Case//Totaliza valores de acordo com o modo de cobrança
	Case ( oModel:GetValue("TFZDETAIL", "TFZ_MODCOB") == "1" .OR. oModel:GetValue("TFZDETAIL", "TFZ_MODCOB") == "4" )	//Uso ou Horimetro

		nVlrTFI := oModel:GetValue("TFIPRODUT", "TFI_USO") - nVlrAnt + nVlrAtu
		oModel:LoadValue("TFIPRODUT", "TFI_USO", nVlrTFI)
	
		nVlrTFL := oModel:GetValue("TFLDETAIL", "TFL_USO") - nVlrAnt + nVlrAtu
		oModel:LoadValue("TFLDETAIL", "TFL_USO", nVlrTFL)
								
	Case oModel:GetValue("TFZDETAIL", "TFZ_MODCOB") == "2"//Disponibilidade

		nVlrTFI := oModel:GetValue("TFIPRODUT", "TFI_DISP") - nVlrAnt + nVlrAtu
		oModel:LoadValue("TFIPRODUT", "TFI_DISP", nVlrTFI)
	
		nVlrTFL := oModel:GetValue("TFLDETAIL", "TFL_DISP") - nVlrAnt + nVlrAtu	
		oModel:LoadValue("TFLDETAIL", "TFL_DISP", nVlrTFL)
	
	Case oModel:GetValue("TFZDETAIL", "TFZ_MODCOB") == "3"//Mobilização

		nVlrTFI := oModel:GetValue("TFIPRODUT", "TFI_MOBILI") - nVlrAnt + nVlrAtu
		oModel:LoadValue("TFIPRODUT", "TFI_MOBILI", nVlrTFI)
	
		nVlrTFL := oModel:GetValue("TFLDETAIL", "TFL_MOBILI") - nVlrAnt + nVlrAtu
		oModel:LoadValue("TFLDETAIL", "TFL_MOBILI", nVlrTFL)
	
EndCase

//Atualiza Total TFL
nVlTot := oModel:GetValue("TFLDETAIL", "TFL_USO") + oModel:GetValue("TFLDETAIL", "TFL_DISP") + oModel:GetValue("TFLDETAIL", "TFL_MOBILI")
oModelTFL:SetValue("TFL_VALTOT", oModel:GetValue("TFLDETAIL", "TFL_VALTOT")-nVlTotAnt + nVlTot)
At930TrgGer( 'TFLDETAIL', 'TFL_VALTOT', 'ZZPDETAIL', 'ZZP_VLRTOT', 4 )
Return (0)


//-------------------------------------------------------------------
/*/{Protheus.doc} LoadStruZZP
Realiza a criação de campos para um model específico para totalizar
Será responsável pelos campos de atualização dos Totalizadores
@author Serviços
@since 19/11/2013
@version P11.9
@params
	oPar1  --> Objeto com a estrutura dos dados para alteração
		a passagem deve ocorrer por parametro
	lPar1  --> indica qual tipo de estrutura carregar
		-----> .T. = Model (Default)
		-----> .F. = View
/*/
//-------------------------------------------------------------------
Static Function LoadStruZZP( oStruct, lView )

Default lView := .F.

If ! lView
	oStruct:AddField( ;
						STR0047,;						// [01] Titulo do campo # "Apuração"
						STR0047,;						// [02] ToolTip do campo # "Apuração"
						"ZZP_APU",;					// [03] Id do Field
						"C",;							// [04] Tipo do campo
						25,;							// [05] Tamanho do campo
						0,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual
		
	oStruct:AddField( ;
						STR0006,;						// [01] Titulo do campo # "Grupo de faturamento"
						STR0006,;						// [02] ToolTip do campo # "Grupo de faturamento"
						"ZZP_GRPFAT",;				// [03] Id do Field
						"C",;							// [04] Tipo do campo
						TamSX3("B1_COD")[1],;		// [05] Tamanho do campo
						0,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual
	
	oStruct:AddField( ;
						STR0005,;						// [01] Titulo do campo # "Descrição"
						STR0005,;						// [02] ToolTip do campo # "Descrição"
						"ZZP_DESC",;					// [03] Id do Field
						"C",;							// [04] Tipo do campo
						TamSX3("B1_DESC")[1],;		// [05] Tamanho do campo
						0,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual
						
	oStruct:AddField( ;
						STR0034,;						// [01] Titulo do campo # "Valor"
						STR0034,;						// [02] ToolTip do campo  # "Valor"
						"ZZP_VLRTOT",;				// [03] Id do Field
						"N",;							// [04] Tipo do campo
						14,;							// [05] Tamanho do campo
						2,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual
						
	oStruct:AddField( ;
						STR0048,;						// [01] Titulo do campo # "Excedente"
						STR0048,;						// [02] ToolTip do campo # "Excedente"
						"ZZP_VLREXT",;				// [03] Id do Field
						"N",;							// [04] Tipo do campo
						14,;							// [05] Tamanho do campo
						2,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual
						
	oStruct:AddField( ;
						STR0093,;						// [01] Titulo do campo # "Acréscimos"
						STR0093,;						// [02] ToolTip do campo # "Acréscimos"
						"ZZP_TOTMUL",;				// [03] Id do Field
						"N",;							// [04] Tipo do campo
						16,;							// [05] Tamanho do campo
						2,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual

	oStruct:AddField( ;
						STR0094,;						// [01] Titulo do campo # "Bonificações"
						STR0094,;						// [02] ToolTip do campo # "Bonificações"
						"ZZP_TOTBON",;				// [03] Id do Field
						"N",;							// [04] Tipo do campo
						16,;							// [05] Tamanho do campo
						2,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual

	oStruct:AddField( ;
						STR0092,;						// [01] Titulo do campo # "Descontos"
						STR0092,;						// [02] ToolTip do campo # "Descontos"
						"ZZP_TOTDES",;				// [03] Id do Field
						"N",;							// [04] Tipo do campo
						16,;							// [05] Tamanho do campo
						2,;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.T.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						/*.F.*/)						// [14] Indica se o campo é virtual

Else

	oStruct:AddField( ;
						"ZZP_APU",;					// [01] Campo
						"1",;							// [02] Ordem
						STR0047,;						// [03] Titulo # "Apuração"
						STR0047,;						// [04] Descricao # "Apuração"
						/*{}*/,;						// [05] Help
						'C',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						Nil,;							// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual
						
	oStruct:AddField( ;
						"ZZP_GRPFAT",;				// [01] Campo
						"2",;							// [02] Ordem
						STR0006,;						// [03] Titulo # "Grupo de faturamento"
						STR0006,;						// [04] Descricao # "Grupo de faturamento"
						/*{}*/,;						// [05] Help
						'C',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						Nil,;							// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual
						
	oStruct:AddField( ;
						"ZZP_DESC",;					// [01] Campo
						"3",;							// [02] Ordem
						STR0005,;						// [03] Titulo  # "Descrição"
						STR0005,;						// [04] Descricao  # "Descrição"
						/*{}*/,;						// [05] Help
						'C',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						Nil,;							// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual						
	
	oStruct:AddField( ;
						"ZZP_VLRTOT",;				// [01] Campo
						"4",;							// [02] Ordem
						STR0034,;						// [03] Titulo # "Valor"
						STR0034,;						// [04] Descricao  # "Valor"
						/*{}*/,;						// [05] Help
						'N',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						"@E 999,999,999,999.99",;	// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual	

	oStruct:AddField( ;
						"ZZP_VLREXT",;				// [01] Campo
						"5",;							// [02] Ordem
						STR0048,;						// [03] Titulo # "Excedente"
						STR0048,;						// [04] Descricao # "Excedente"
						/*{}*/,;						// [05] Help
						'N',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						"@E 999,999,999,999.99",;	// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual

	oStruct:AddField( ;
						"ZZP_TOTMUL",;				// [01] Campo
						"6",;							// [02] Ordem
						STR0093,;						// [03] Titulo # "Multas"
						STR0093,;						// [04] Descricao  # "Multas"
						/*{}*/,;						// [05] Help
						'N',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						"@E 999,999,999,999.99",;	// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual

	oStruct:AddField( ;
						"ZZP_TOTBON",;				// [01] Campo
						"7",;							// [02] Ordem
						STR0094,;						// [03] Titulo # "Bonificações"
						STR0094,;						// [04] Descricao  # "Bonificações"
						/*{}*/,;						// [05] Help
						'N',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						"@E 999,999,999,999.99",;	// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual
		
	oStruct:AddField( ;
						"ZZP_TOTDES",;				// [01] Campo
						"8",;							// [02] Ordem
						STR0092,;						// [03] Titulo # "Descontos"
						STR0092,;						// [04] Descricao  # "Descontos"
						/*{}*/,;						// [05] Help
						'N',;							// [06] Tipo do campo   COMBO, Get ou CHECK
						"@E 999,999,999,999.99",;	// [07] Picture
						/*''*/,;						// [08] PictVar
						/*NIL*/,;						// [09] F3
						.F.,;							// [10] Editavel
						'',;							// [11] Folder
						/*''*/,;						// [12] Group
						/*{}*/,;						// [13] Lista Combo
						/*10*/,;						// [14] Tam Max CombO
						/*''*/,;						// [15] Inic. Browse
						.F.)							// [16] Virtual
EndIf						
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930TrgGer
@sample 	At930TrgGer( "CALC_TFH", "TOT_MC", "TFF_RH", "TFF_TOTMC" )
@since		19/11/2013
@version	P11.90
/*/
//------------------------------------------------------------------------------
Function At930TrgGer( cMdlCalc, cCpoTot, cMdlCDom, cCpoCDOM, nLine )
Local aSaveLines	:= FWSaveRows()
Local oMdl			:= FwModelActive()
Local oView		:= FwViewActive()
Local nLineAnt	:= oMdl:GetModel( cMdlCalc ):GetLine()
Local nValor		:= 0
Local nX
Local aAreaTFJ		:= TFJ->(GetArea())

If	oMdl:GetModel( cMdlCDom ):Length() >= 4
	For	nX := 1 To oMdl:GetModel( cMdlCalc ):Length()
		oMdl:GetModel( cMdlCalc ):GoLine(nX)
		nValor += oMdl:GetModel( cMdlCalc ):GetValue( cCpoTot )
			If cCpoTot = "TFW_VLRMED"
				nValor += oMdl:GetModel( cMdlCalc ):GetValue( "TFW_VLMTMI" )
				nValor += oMdl:GetModel( cMdlCalc ):GetValue( "TFW_VLMTMC" )
			EndIf
	Next nX

	oMdl:GetModel( cMdlCDom ):GoLine(nLine)
	oMdl:GetModel( cMdlCDom ):SetValue( cCpoCDOM, nValor )
EndIf

oMdl:GetModel( cMdlCalc ):GoLine(nLineAnt)

If	oView <> NIL .and. oView:IsActive()
	oView:Refresh()
EndIf

FWRestRows( aSaveLines )
RestArea(aAreaTFJ)

Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At930TrgRh
@sample 	At930TrgRh( "CALC_TFH", "TOT_MC", "TFF_RH", "TFF_TOTMC" )
@since		12/12/2013       
@version	P11.90
/*/
//------------------------------------------------------------------------------
Function At930TrgRH( cMdlCalc, cCpoTot, cMdlCDom, cCpoCDOM, nLine )
Local aSaveLines	:= FWSaveRows()
Local oMdl			:= FwModelActive()
Local oView		:= FwViewActive()
Local nLinha		:= oMdl:GetModel(cMdlCalc):GetLine()
Local nVlrTotal	:= 0

At930TrgGer( cMdlCalc, cCpoTot, cMdlCDom, cCpoCDOM, nLine )

oMdl:GetModel(cMdlCalc):GoLine(nLinha)

nVlrTotal :=	oMdl:GetModel(cMdlCalc):GetValue("TFW_VLRMED") + ;
				oMdl:GetModel(cMdlCalc):GetValue("TFW_VLREXT") + ;
				oMdl:GetModel(cMdlCalc):GetValue("TFW_VLMTMI") + ;
				oMdl:GetModel(cMdlCalc):GetValue("TFW_TOTMUL") + ;
				oMdl:GetModel(cMdlCalc):GetValue("TFW_VLMTMC") - ;
				oMdl:GetModel(cMdlCalc):GetValue("TFW_TOTBON") - ;
				oMdl:GetModel(cMdlCalc):GetValue("TFW_TOTDES")

oMdl:GetModel(cMdlCalc):SetValue("TFW_VLRTOT", nVlrTotal )

If	oMdl:GetId() == "TECA930" .And. oView:IsActive()
	oView:Refresh()
EndIf

FWRestRows( aSaveLines )

Return(0)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At930Grv
	Interface para gravação e geração da apuração/medição
	
@sample 	At930Grv(oMdlGeral)
@author 	Serviços 
@since		19/11/2013       
@version	P11.90
@param  	oExp, Objeto, objeto do modelo de dados a ser gravado
@return  	lRet, Logico, status da gravação
/*/
//------------------------------------------------------------------------------
Function At930Grv( oModel )

Local lRet			:= .T.
Local cAliasTFL		:= GetNextAlias()
Local oTFVMaster 	:= oModel:GetModel('TFVMASTER')
Local cMV_PAR01		:= oTFVMaster:GetValue("TFV_CONTRT")  // Contrato
Local dDtIniApu		:= oTFVMaster:GetValue("TFV_DTINI")   // Data Inicial
Local dDtFimApu		:= oTFVMaster:GetValue("TFV_DTFIM")  // Data Final
Local aCabApu		:= {} // Dados para o cabecalho da apuração
Local aIteApu		:= {} // Dados para os dados da medicao normal
Local aCmboCmp		:= {}
Local aCabe			:= {}
Local aItem			:= {}
Local aItemExc		:= {} 
Local nPosPlan		:= 0
Local nPosMed		:= 0
Local nPosCab		:= 0
Local nPosMI		:= 0
Local nPosMC		:= 0
Local nTotExt		:= 0
Local cOpcApu		:= oTFVMaster:GetValue("TFV_HREXTR") 
Local cAliasAB9		:= GetNextAlias()
Local cAliasIMI		:= GetNextAlias()
Local cAliasIMC		:= GetNextAlias()
Local cAliasTEW		:= GetNextAlias()
Local cOperConc		:= if(Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX","||","+")
Local nVlrTot		:= 0 
Local cRevCtr		:= ''  // inicializa vazio para conseguir carregar o pergunte correto
Local aRateio		:= {}
Local i				:= 0
Local nI			:= 0
Local nJ			:= 0
Local nX			:= 0
Local nY			:= 0
Local nZ        	:= 0
Local nW        	:= 0
Local nU        	:= 0
Local cIdcABQ		:= ''
Local cLocal		:= ''
Local xAux			:= Nil
Local xAuxPed		:= Nil
Local nPosIAP		:= 0
Local nPosAux		:= 0
Local aMedGCT		:= {}
Local cNumMed		:= ""
Local cWhereCob		:= ""
Local nPos			:= 0
Local aPedCabec		:= {}
Local aPedItens		:= {}
Local aLocPed		:= {}
Local aLocPedX		:= {}
Local aItePed		:= {}
Local aAreaSX3		:= {}
//Local nItePed		:= 0
Local nPosLocal		:= 0
Local nPosFat		:= 0
Local aTEVUpdate	:= {}
Local nDecTFW		:= 2
Local nDecTFX		:= 2
Local nDecTFY		:= 2
Local nDecTFI		:= 2
Local nVlrMedMI		:= 0
Local nVlrMedMC		:= 0
Local nVlrMedLE		:= 0
Local nVlrMedRH		:= 0
Local nPosItItens	:= 0
Local nVlrMulta		:= 0
Local nVlrBoni		:= 0
Local nVlrDesc		:= 0
Local lOrcPrc		:= SuperGetMv("MV_ORCPRC",,.F.)
Local lSomaImp		:= SuperGetMv("MV_ATOPIMP",,.T.) // verifica o parâmetro de incorporação do valor do imposto
Local nVlrHora		:= 0					
Local nPercHre		:= 0
Local aMultas		:= {} 
Local cTipoFrete	:= ""
Local cGrpCom		:= ""
Local cNumProp		:= ""
Local cNumCtr		:= ""
Local cChave		:= ""  
Local lDsgCN 		:= .F.
Local lGrpFat	 := .F.
Local oTFWDetail := oModel:GetModel("TFWDETAIL")
Local oTFXDetail := oModel:GetModel("TFXDETAIL")
Local oTFYDetail := oModel:GetModel("TFYDETAIL")
Local oTFIDetail := oModel:GetModel("TFIPRODUT")
Local oTFZDetail := oModel:GetModel("TFZDETAIL")
Local oTW7Detail := oModel:GetModel("TFWTW7DETAIL")
Local oTW7TFIDetail := oModel:GetModel("TFITW7DETAIL")
Local aItnsRef	:= {}
Local cItem		:= "001"
Local cItemMI	:= "001"
Local cItemMC	:= "001"
Local nVlrTotHE	:= 0
Local cPict 		:= PesqPict("CNB","CNB_VLTOT")
Local nRetCNF		:= 0
Local cCodLoc		:= ""
Local aComplSC5	:= {}
Local lFatAntecip 	:= ( oTFVMaster:GetValue("TFV_ANTECI") == "1" )
Local cChvABQ   	:= ""
Local cChvTFL   	:= ""
Local cCodTFJ   	:= ""
Local cRevCtrQry 	:= ""
Local nVlrDASep		:= 0
Local aCabecF		:= {}
Local aItensF  		:= {} 
Local aItemF		:= {}
Local aFatSep		:= {}
Local aFatSepCab	:= {}
Local lFatDASep 	:= IIF(nOpcDA <> 1 , .T. , .F.)
Local j				:= 0
Local aCompPed := {}
Local cChaveGF	:= ""
Local aDescs	:= {}
Local lGsMtMi	:= .F.
Local lGsMtMc	:= .F.
Local aArea		:= GetArea()
Local nVlrHE	:= 0
Local cCodTes	:= ""
Local cCodProd	:= ""
Local cCodProdMI:= ""
Local cCodProdMC:= ""
Local cCodLocal	:= ""
Local cChaveQbr	:= ""
Local cCodTFL	:= ""
Local cChvQbrMI	:= ""
Local cChvQbrMC	:= ""
Local aPlan		:= {}
Local aAux		:= {}
Local aPlanItem	:= {}
Local aPlanHE	:= {}//adiciona dados para hora extra de excedente
Local cCodCli	:= ""
Local cLoja		:= ""
Local cCodCliMI	:= ""
Local cLojaMI	:= ""
Local cCodCliMC	:= ""
Local cLojaMC	:= ""
Local cIDFatSep	:= ""
Local lGerHeEx	:= nOpcHE == 1 .and. cOpcApu == "2"
Local cB1_CODISS		:= "" //Codigo do Serviço
Local cFilSB1			:= xFilial("SB1")
Local aAreaSB1			:= {}
Local cChaveLoc 		:= ""
Local cB1_CISSMI		:= ""
Local cB1_CISSMC 		:= ""


//grupo de Faturamento
Local lGrpFatOrc:= .F.
Local cPlanRH	:= ""
Local cPlanMC	:= ""
Local cPlanMI	:= ""
Local cPlanLE	:= ""
Local lRecorr	:= .F.

//ABATIMENTO DE INSS
Local nAbtINSS	:= 0


If !lTeca934
	Pergunte("TEC930",.F.)// garante que o pergunte da apuração seja o ativo
Else
	If !IsInCallStack("At934aProc")
		Pergunte("TEC934",.F.)
	EndIf
	dDtIniApu	:= MV_PAR05 
	dDtFimApu	:= MV_PAR06
EndIf


cRevCtr := Posicione("CN9",7,xFilial("CN9")+oTFVMaster:GetValue("TFV_CONTRT")+"05","CN9_REVISA")

Private lMsErroAuto    := .F.
Private lMsHelpAuto    := .T.
Private lAutoErrNoFile := .F.
Private lMedHE		   := .F.

cIdcABQ := "%ABQ.ABQ_CONTRT" + cOperConc + "ABQ.ABQ_ITEM" + cOperConc + "ABQ.ABQ_ORIGEM%"

If lSrvExt
	cCodTFJ := AllTrim(MV_PAR05)
	cRevCtrQry := "%TFJ.TFJ_CODIGO = '" + cCodTFJ +"'%"
Else
	cRevCtrQry := "%TFL.TFL_CONTRT = '" + cMV_PAR01 + "' "
	cRevCtrQry += "AND TFL.TFL_CONREV = '" + cRevCtr + "'%"
EndIf

// Sql para buscar todos os locais e planilha disponiveis no contrato
BeginSql Alias cAliasTFL

	SELECT TFL.TFL_CODIGO, TFL.TFL_LOCAL,  TFL.TFL_CONTRT, TFL.TFL_CONREV, TFL.TFL_PLAN,
  	       TFL.TFL_ITPLRH, TFL.TFL_ITPLMI, TFL.TFL_ITPLMC, TFL.TFL_ITPLLE, ABS.ABS_CCUSTO, 
  	       TFJ.TFJ_CODENT, TFJ.TFJ_LOJA,   TFJ.TFJ_CONDPG, TFJ.TFJ_TPFRET, TFJ.TFJ_GRPCOM, 
  	       TFJ.TFJ_PROPOS, TFJ.TFJ_CONTRT, TFJ.TFJ_CONREV, TFJ.TFJ_DSGCN, TFJ_GRPFAT,
  	       ABS.ABS_CLIFAT, ABS.ABS_LJFAT, TFJ.TFJ_CODIGO, TFJ.TFJ_ISGSMT, TFJ.TFJ_GSMTMI, TFJ.TFJ_GSMTMC, 
  	       TFJ.TFJ_CODGRP, TFJ.TFJ_CNTREC
  	
  	  FROM %table:TFL% TFL
	       JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
	                           AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
	                           AND ABS.%NotDel%  		
	       JOIN %table:TFJ% TFJ ON TFJ.TFJ_FILIAL = %xFilial:TFJ%
	                           AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI
	                           AND TFJ.%NotDel%  		
	 WHERE TFL.TFL_FILIAL = %xFilial:TFL%
    	AND %Exp:cRevCtrQry%
	   	AND TFL.%NotDel%

EndSql

If (cAliasTFL)->(!Eof())
	lDsgCN := (cAliasTFL)->(TFJ_DSGCN) == '1'
	lGrpFat := (cAliasTFL)->(TFJ_GRPFAT) == '1'
	lRecorr := (cAliasTFL)->(TFJ_CNTREC) == '1'
	If (cAliasTFL)->(TFJ_ISGSMT) == "1"
		lGsMtMi := (cAliasTFL)->(TFJ_GSMTMI) $ '2|3' .AND. lGrpFat
		lGsMtMc := (cAliasTFL)->(TFJ_GSMTMC) $ '2|3'.AND. lGrpFat
	Endif
EndIf

cLocal := "%("



While (cAliasTFL)->(!Eof())	
	lGrpFatOrc := (cAliasTFL)->TFJ_GRPFAT=="1" 
	
	If lMedExt .OR. lSrvExt
	
		aAdd( aLocPed, { 	(cAliasTFL)->TFL_CODIGO	,; 
							(cAliasTFL)->ABS_CCUSTO	,; 
							(cAliasTFL)->ABS_CLIFAT	,;	
							(cAliasTFL)->ABS_LJFAT	,;
							(cAliasTFL)->TFJ_CONDPG	,;
							(cAliasTFL)->TFJ_TPFRET	,; 
							(cAliasTFL)->TFL_LOCAL	,;
							(cAliasTFL)->TFJ_CODIGO	})

		aAdd( aLocPedX, { 	(cAliasTFL)->ABS_CLIFAT	,;	
							(cAliasTFL)->ABS_LJFAT	,;
							(cAliasTFL)->TFJ_CONDPG	,;
							(cAliasTFL)->TFL_CONTRT ,; 
							(cAliasTFL)->TFJ_CODIGO	,; 
							(cAliasTFL)->TFL_LOCAL	,; 
							(cAliasTFL)->TFJ_CODGRP	})					
	
	Else 
		aAdd( aLocPedX, { 	(cAliasTFL)->ABS_CLIFAT	,;	
							(cAliasTFL)->ABS_LJFAT	,;
							(cAliasTFL)->TFJ_CONDPG	,;
							(cAliasTFL)->TFL_CONTRT ,; 
							(cAliasTFL)->TFJ_CODIGO	,; 
							(cAliasTFL)->TFL_LOCAL	,; 
							(cAliasTFL)->TFJ_CODGRP	})	
							
		If !lGrpFatOrc
			cPlanRH := (cAliasTFL)->TFL_PLAN
			cPlanMI := (cAliasTFL)->TFL_PLAN
			cPlanMC := (cAliasTFL)->TFL_PLAN
			cPlanLE := (cAliasTFL)->TFL_PLAN
		
		Else
			At870GrPlan( (cAliasTFL)->TFJ_CODGRP,(cAliasTFL)->TFL_LOCAL , @cPlanRH, @cPlanMI, @cPlanMC, @cPlanLE )
		EndIf	
	
		// Itens para o cabecalho da apuração
		//RH
		aAdd(aCabApu, { 	(cAliasTFL)->TFL_CODIGO, (cAliasTFL)->TFL_CONTRT,; 
							(cAliasTFL)->TFL_CONREV, cPlanRH,;
									0, (cAliasTFL)->TFL_LOCAL, 'RH', (cAliasTFL)->ABS_CLIFAT, (cAliasTFL)->ABS_LJFAT,(cAliasTFL)->TFJ_CODGRP } )//Total da medição
			 
		//MI
		aAdd(aCabApu, { 	(cAliasTFL)->TFL_CODIGO, (cAliasTFL)->TFL_CONTRT,;
									(cAliasTFL)->TFL_CONREV, cPlanMI,;
									0, (cAliasTFL)->TFL_LOCAL, 'MI', (cAliasTFL)->ABS_CLIFAT, (cAliasTFL)->ABS_LJFAT, (cAliasTFL)->TFJ_CODGRP } )//Total da medição

		//MC
		aAdd(aCabApu, { 	(cAliasTFL)->TFL_CODIGO, (cAliasTFL)->TFL_CONTRT,;
									(cAliasTFL)->TFL_CONREV, cPlanMC,;
									0, (cAliasTFL)->TFL_LOCAL, 'MC', (cAliasTFL)->ABS_CLIFAT, (cAliasTFL)->ABS_LJFAT, (cAliasTFL)->TFJ_CODGRP } )//Total da medição

		//LE
		aAdd(aCabApu, { 	(cAliasTFL)->TFL_CODIGO, (cAliasTFL)->TFL_CONTRT,;
									(cAliasTFL)->TFL_CONREV, cPlanLE,;
									0, (cAliasTFL)->TFL_LOCAL, 'LE', (cAliasTFL)->ABS_CLIFAT, (cAliasTFL)->ABS_LJFAT, (cAliasTFL)->TFJ_CODGRP } )//Total da medição

		//HE
		aAdd(aCabApu, { 	(cAliasTFL)->TFL_CODIGO, (cAliasTFL)->TFL_CONTRT,;
							(cAliasTFL)->TFL_CONREV, cPlanRH,;
							 0, (cAliasTFL)->TFL_LOCAL, 'HE', (cAliasTFL)->ABS_CLIFAT, (cAliasTFL)->ABS_LJFAT, (cAliasTFL)->TFJ_CODGRP } )//Total da medição

		//AD
		aAdd(aCabApu, { 	(cAliasTFL)->TFL_CODIGO, (cAliasTFL)->TFL_CONTRT,;
									(cAliasTFL)->TFL_CONREV, cPlanRH,;
									0, (cAliasTFL)->TFL_LOCAL, 'AD', (cAliasTFL)->ABS_CLIFAT, (cAliasTFL)->ABS_LJFAT, (cAliasTFL)->TFJ_CODGRP } )//Total da medição


		If !Empty((cAliasTFL)->TFL_ITPLRH) // itens para a planilha do RH 
			aAdd(aIteApu, { 1, (cAliasTFL)->TFL_CODIGO, cPlanRH,; 
								  (cAliasTFL)->TFL_ITPLRH, 0 } )
		EndIf	 
	  	
	  	If !Empty((cAliasTFL)->TFL_ITPLMI) // itens para a planila do Material de Implantacao
	  		aAdd(aIteApu, { 2, (cAliasTFL)->TFL_CODIGO, cPlanMI,; 
	  							  (cAliasTFL)->TFL_ITPLMI, 0 } )
	  	EndIf 
	  	
	  	If !Empty((cAliasTFL)->TFL_ITPLMC) // itens para a planilha do Material de Consumo
	  		aAdd(aIteApu, { 3, (cAliasTFL)->TFL_CODIGO, cPlanMC,; 
	  							  (cAliasTFL)->TFL_ITPLMC, 0 } ) 
	  	EndIf 
	  	
	  	If !Empty((cAliasTFL)->TFL_ITPLLE) // itens para a planilha da Locacao de Equipamento
	  		aAdd(aIteApu, { 4, (cAliasTFL)->TFL_CODIGO, cPlanLE,;
	  						    (cAliasTFL)->TFL_ITPLLE, 0 } ) 
	  	EndIf	
	
	EndIf
	
	cLocal += "'" + (cAliasTFL)->TFL_LOCAL + "'"
	
	If !Empty((cAliasTFL)->TFJ_GRPCOM) .AND. Empty(cGrpCom)
		cGrpCom  := (cAliasTFL)->TFJ_GRPCOM
		cNumProp := (cAliasTFL)->TFJ_PROPOS
		cNumCtr  := (cAliasTFL)->TFJ_CONTRT
	Endif
	(cAliasTFL)->(dbSkip())
	
	If (cAliasTFL)->(!Eof())
		cLocal += ","
	EndIf
 
EndDo

cLocal += ")%"

// Verificar a quantidade de casas decimais dos campos
aAreaSX3  := SX3->(GetArea())	
DbSelectArea("SX3")
SX3->(dbSetOrder(2))
If SX3->(DbSeek("TFW_VLRTOT"))	
	nDecTFW := SX3->X3_DECIMAL 
Endif	
If SX3->(DbSeek("TFX_VLRMED"))	
	nDecTFX := SX3->X3_DECIMAL  
Endif	
If SX3->(DbSeek("TFY_VLRMED"))	
	nDecTFY := SX3->X3_DECIMAL  
Endif

If SX3->(DbSeek("TFI_TOTAL"))	
	nDecTFI := SX3->X3_DECIMAL  
Endif	
SX3->(RestArea(aAreaSX3))

dbSelectArea( 'TGU' )
TGU->( dbSetOrder( 1 ) )

dbSelectArea( 'TFL' )
TFL->( dbSetOrder( 4 ) )

If lMedExt .OR. lSrvExt	                                                            
	for nI:=1 to len( aLocPed )	
		cChave := xFilial("TGU")+ aLocPed[nI,1]  
		If TGU->(dbSeek(cChave) )
			While TGU->( !Eof() ) .And. TGU->(TGU_FILIAL+TGU_CODTFL)==cChave
				Reclock("TGU",.F.)
				TGU->TGU_APURAC := oTFVMaster:GetValue("TFV_CODIGO")
				TGU->(MsUnlock())
				TGU->( dbSkip() )		
			enddo						
		endif
	next
else	
	for nI:=1 to len( aCabApu )//APONTAMENTOS
		cChave := xFilial("TGU")+ aCabApu[nI,1]                          				
		If TGU->(dbSeek(cChave ) )
			While TGU->( !Eof() ) .And. TGU->(TGU_FILIAL+TGU_CODTFL)==cChave
				Reclock("TGU",.F.)
				TGU->TGU_APURAC := oTFVMaster:GetValue("TFV_CODIGO")
				TGU->(MsUnlock())
				TGU->( dbSkip() )	
			enddo
		endif
	next
endif

// ----------------------------------------
// Verifico se há Faturamento Separado
// ----------------------------------------
//lFatDASep	:= IIF(nOpcDA <> 1 , .T. , .F.)
If nOpcDA == 2
	cIDFatSep := "AD"
ElseIf nOpcDA == 3
	cIDFatSep := "AG"
EndIf
// ----- MEDIÇAO RH


aAreaSB1		:=  SB1->(GetArea())
SB1->(DbSetOrder(1))

//Totalizando itens da apuração do RH, Percorre os itens de RH para adicionar o valor no array aCabApu, que será usado para criação dos pedidos de venda
For nI := 1 To oModel:GetModel("TFWDETAIL"):Length()	

	oModel:GetModel("TFWDETAIL"):GoLine(nI)
								
	aFatSep:= {}
	aPlanItem:= {}
	aPlanHE:= {}
	aItnsRef := {}
	nVlrMedRH := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLRMED")
	nVlrMedMI := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLMTMI")
	nVlrMedMC := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLMTMC")
	cB1_CODISS		:= "" //Codigo do Serviço
	cB1_CISSMI		:= ""  // //Codigo do Serviço MI
	cB1_CISSMC 		:= "" // //Codigo do Serviço MC
	If nVlrMedRH+nVlrMedMI+nVlrMedMC > 0	
		cCodLocal := oModel:GetModel("TFWDETAIL"):GetValue("TFW_LOCAL")	

	 	If lMedExt .OR. lSrvExt

			If lSrvExt .And. lGrpFat //Trecho que define a quebra do pedido
				cChaveGF := At930GFIT(cCodLocal, cCodTFJ, "RH", @cCodCli, @cLoja)
				cChvQbrMC := At930GFIT(cCodLocal, cCodTFJ, "MC", @cCodCliMC, @cLojaMC)
				cChvQbrMI := At930GFIT(cCodLocal, cCodTFJ, "MI", @cCodCliMI, @cLojaMI)
				
			Else
				cChaveGF := oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL")
				cCodTFL	 := oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL")	
				
				If (nPos:= aScan( aLocPedX, { |x| x[06] == cCodLocal }))>0
					cCodCli:= aLocPedX[nPos][1]
					cLoja := aLocPedX[nPos][2]

				EndIf
		
			EndIf //lSrvExt .And. lGrpFat

			If !lOrcPrc
				nVlrDesc:= oModel:GetModel("TFWDETAIL"):GetValue("TFW_TOTDES")
			EndIf
			
			If lSrvExt .And. lGrpFat	
				nVlrMedRH := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLRTOT")+nVlrDesc  - (nVlrMedMI+nVlrMedMC)
			Else
				nVlrMedRH := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLRTOT")+nVlrDesc
				nAbtINSS := (nVlrMedMI+nVlrMedMC) + oTFWDetail:GetValue('TFW_ABTINS')
			EndIf
			
			nVlrHE	  := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLREXT")
			If lDsgCN
				cCodProd  := oModel:GetModel("TFWDETAIL"):GetValue("TFW_PRODUT")
				cCodTes	  := AT930Tes( "TFF", oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFF"))
			Else
				cCodProd  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_GRPRH")
				cCodTes  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_TES")
				cCodProdMI  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_GRPMI")
				cCodProdMC  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_GRPMC")
			Endif

			aFatSep:= {}

			If SB1->(DbSeek(cFilSB1 + cCodProd))
				cB1_CODISS		:= SB1->B1_CODISS
				cChaveGF		:= cChaveGF+cB1_CODISS
				If lGrpFat
					cChvQbrMC	:= cChvQbrMC+cB1_CODISS
					cChvQbrMI	:= cChvQbrMI+cB1_CODISS				
				EndIf
			EndIf
		
			nPosLocal := aScan(aItePed, { |x| x[1] == cChaveGF} )		
			If nOpcHE <> 1 //Subtrai horas extras, pois o valor vai em pedido separado
				nVlrMedRH := nVlrMedRH - nVlrHE
				If nOpcHE == 2 .and. nVlrHE > 0
					If lGrpFat
						cChaveQbr := At930GFIT(cCodLocal, cCodTFJ, "HE", @cCodCli, @cLoja)
					Else
						cChaveQbr := cCodLocal+cB1_CODISS
					EndIf
	
						
					nPosFat:=  aScan( aFatSepCab, { |x| x[01]+x[04] == "HE"+cChaveQbr })
					
					If nPosFat == 0
						aAdd(aFatSep, {nVlrHE, cCodProd, cCodTes} )
						aAdd(aFatSepCab	, {"HE" , cCodCli , cLoja,cChaveQbr , cCodLocal, aFatSep, "" , cCodLocal})
					Else
						If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd .AND. x[04] == cB1_CODISS }))>0
							aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrHE
						Else
							aAdd(aFatSepCab[nPosFat][6],{nVlrHE, cCodProd,  cCodTes, cB1_CODISS})
						EndIf
					 
					Endif
				EndIf
			Endif
			aFatSep:= {}
			If nOpcDA <> 1 //Subtrai despesas adicionais, pois o valor vai em pedido separado
			
				If lGrpFat
					cChaveQbr := At930GFIT(cCodLocal, cCodTFJ, "AD", @cCodCli, @cLoja)
				Else
					cChaveQbr := cCodLocal+cB1_CODISS
				EndIf
				
		
				nVlrDASep:= 0
				For nY := 1 To oTW7Detail:Length()
					oTW7Detail:GoLine(nY)
					If !oTW7Detail:IsDeleted() .And. oTW7Detail:GetValue('TW7_VALOR') > 0 
						If oTW7Detail:GetValue("TW7_DESPAD")== '1' 	
							nVlrDASep += oTW7Detail:GetValue("TW7_VALOR")
						EndIf 
					EndIf
				Next nY
				
				
				If (nOpcDA + nOpcHE) == 6 .and. (nVlrDASep + nVlrHE)>0
				
					nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[04] == "AG"+cChaveQbr+cB1_CODISS })
					If nPosFat == 0
						aAdd(aFatSep, {nVlrDASep+nVlrHE, cCodProd, cCodTes} )
						aAdd(aFatSepCab	, {"AG" ,  cCodCli , cLoja,cChaveQbr, cCodLocal, aFatSep, "" , cCodLocal})
					Else
					
						If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd .AND. x[04] == cB1_CODISS }))>0
							aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrDASep+nVlrHE
						Else
							aAdd(aFatSepCab[nPosFat][6],{nVlrDASep+nVlrHE,cCodProd,  cCodTes, cB1_CODISS}) 
						EndIf 
						
					Endif

				Else
					If nOpcDA == 2 .and. nVlrDASep > 0 
						nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[04] == "AD"+cChaveQbr})
						If nPosFat == 0
							aAdd(aFatSep, {nVlrDASep, cCodProd, cCodTes, cB1_CODISS} )
							aAdd(aFatSepCab	, {"AD" ,  cCodCli , cLoja,cChaveQbr , cCodLocal, aFatSep, "", cCodLocal })
						Else
							If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd .AND. x[04] == cB1_CODISS }))>0
								aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrDASep
							Else
								aAdd(aFatSepCab[nPosFat][6],{nVlrDASep, cCodProd,  cCodTes, cB1_CODISS})
							EndIf 
						Endif

					EndIf
				Endif

				nVlrMedRH := nVlrMedRH - nVlrDASep
			EndIf

			If nVlrMedRH > 0
				At930GerIts(aItePed, nPosLocal, cChaveGF,cCodProd,nVlrMedRH, nVlrDesc, cCodTes, nDecTFW, lDsgCN, cB1_CODISS, cCodTFL, nAbtINSS)
			Endif
			
			If lGsMtMi .AND. nVlrMedMI > 0 .AND. !Empty(cCodProdMI) //AQUI PAM
				nPosLocal := aScan(aItePed, { |x| x[1] == cChvQbrMI} )	
				At930GerIts(aItePed, nPosLocal, cChvQbrMI,cCodProdMI,nVlrMedMI, 0, cCodTes, nDecTFW, lDsgCN, cB1_CISSMI, cCodTFL, nVlrMedMI)
			Endif
			
			If lGsMtMc .AND. nVlrMedMC > 0 .AND. !Empty(cCodProdMC)
				nPosLocal := aScan(aItePed, { |x| x[1] == cChvQbrMC } )	
				At930GerIts(aItePed, nPosLocal, cChvQbrMC,cCodProdMC,nVlrMedMC, 0, cCodTes, nDecTFW, lDsgCN, cB1_CISSMC, cCodTFL, nVlrMedMC)
			Endif
			
			If nOpcDA == 1  	
		    	nVlrDASep:= 0  
		    EndIf

		Else 

			If lGrpFat       
				nPosCab := At930PCab(@aCabApu, oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"), 'RH', cCodLocal)
				If lGsMtMi
					nPosMI := At930PCab(@aCabApu, oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"), 'MI', cCodLocal)
				EndIf
				If lGsMtMc
					nPosMC := At930PCab(@aCabApu, oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"), 'MC', cCodLocal)
				EndIf
			Else
				nPosCab := aScan( aCabApu, { |x| x[1] == oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL") } )
			EndIf
					
			If lDsgCN
				cCodProd  := oModel:GetModel("TFWDETAIL"):GetValue("TFW_PRODUT")
				cCodTes	  := AT930Tes( "TFF", oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFF"))
			Else
				cCodProd  :=Posicione("TFJ",5,xFilial("TFJ")+oTFVMaster:GetValue("TFV_CONTRT")+oTFVMaster:GetValue("TFV_REVISA"),"TFJ_GRPRH")
				cCodTes  := Posicione("TFJ",5,xFilial("TFJ")+oTFVMaster:GetValue("TFV_CONTRT")+oTFVMaster:GetValue("TFV_REVISA"),"TFJ_TES")
			Endif

			If SB1->(DbSeek(cFilSB1 + cCodProd))
				cB1_CODISS		:= SB1->B1_CODISS
			EndIf	
			
			nTotExt := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLREXT")
			If !lDsgCN .and. (nPosIAP := aScan( aIteApu, { |x| x[1] == 1 .And. x[2] == aCabApu[nPosCab][1] } ))>0
				cItem := aIteApu[nPosIAP][4]
				nPosAux := aScan( aIteApu, { |x| x[1] == 2 .And. x[2] == aCabApu[nPosCab][1] } )
				cItemMI:= aIteApu[nPosAux][4]
				nPosAux := aScan( aIteApu, { |x| x[1] == 3 .And. x[2] == aCabApu[nPosCab][1] } )
				cItemMC:= aIteApu[nPosAux][4]
			Else
				cItem := Posicione("TFF",1,xFilial("TFF")+oTFWDetail:GetValue("TFW_CODTFF"),"TFF_ITCNB")
				cItemMI := Posicione("TFF",1,xFilial("TFF")+oTFWDetail:GetValue("TFW_CODTFF"),"TFF_ITICNB")
				cItemMC := Posicione("TFF",1,xFilial("TFF")+oTFWDetail:GetValue("TFW_CODTFF"),"TFF_ITCCNB")
			EndIf

			oTFWDetail:SetValue('TFW_ITMED',cItem)
	
			
			IF nOpcHE == 1
			 	nVlrMedRH += nTotExt
			EndIf
			
			If nOpcDA <> 1
				nVlrDASep:= 0
				For nY := 1 To oTW7Detail:Length()
					oTW7Detail:GoLine(nY)
					If !oTW7Detail:IsDeleted() .And. oTW7Detail:GetValue('TW7_VALOR') > 0 
						If oTW7Detail:GetValue("TW7_DESPAD")== '1' 	
							nVlrDASep += oTW7Detail:GetValue("TW7_VALOR")
						EndIf 
					EndIf
				Next nY	
			EndIf
			
			If nPosCab > 0
			
				cCodCli	:= aCabApu[nPosCab][8]
				cLoja	:= aCabApu[nPosCab][9]
			
				If lGrpFat
					If nPosMI > 0
						cCodCliMI:= aCabApu[nPosMI][8]
						cLojaMI	:= aCabApu[nPosMI][9] 
						cChvQbrMI := aCabApu[nPosMI][4]+cCodCliMI+cLojaMI  
					EndIf
					If nPosMC > 0
						cCodCliMC:= aCabApu[nPosMC][8]
						cLojaMC	:= aCabApu[nPosMC][9] 
						cChvQbrMC := aCabApu[nPosMC][4]+cCodCliMC+cLojaMC
					EndIf
					cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja     
				Else
					cChaveQbr := aCabApu[nPosCab][4]
				EndIf
				
				nPos := aScan( aPlan, { |x| x[10] == cChaveQbr} ) 
				If nPos == 0 
				
					cNumMed := CriaVar("CND_NUMMED")
					If !lDsgCN
						If (nPosMed := aScan( aMedGCT, { |x| x[1] == aCabApu[nPosCab][1] } ))==0
							aAdd( aMedGCT, { aCabApu[nPosCab][1], cNumMed, cItem, "", "", "" } )
						Else 
							aMedGCT[nPosMed][3] := cItem
						EndIf
					EndIf
					
					Aadd( aItnsRef,{cItem,'Recursos Humanos'})
					
					oTFWDetail:SetValue('TFW_NUMMED',cNumMed)
					If nVlrMedRH>0
						If lGerHeEx
							aAdd(aPlanHE	, {cItem,nTotExt, cCodTes} )
						Endif
						A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMedRH, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItem, aPlanHE, aItnsRef, oTFWDetail:GetValue('TFW_ABTINS'))
					Endif
					aPlanHE:= {}
					If !lGrpFat
						If lGsMtMi .and. nVlrMedMI >0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMI"))
							If Len(aPlan) >= 1
								A930AltPlan(aPlan,cItemMI, nVlrMedMI, Len(aPlan),nVlrMedMI)					
							Else 
								A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMedMI, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItemMI, aPlanHE, aItnsRef,nVlrMedMI)
							EndIf
						EndIf
						
						If lGsMtMc .and. nVlrMedMC>0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMC")) 
							If Len(aPlan) >= 1
								A930AltPlan(aPlan,cItemMC, nVlrMedMC, Len(aPlan),nVlrMedMC)						
							Else 
								A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMedMC, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItemMC, aPlanHE, aItnsRef,nVlrMedMC)
							EndIf
						EndIf
					Else
						If lGsMtMi .and. nVlrMedMI >0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMI"))
							nPos := aScan( aPlan, { |x| x[10] == cChvQbrMI} )
							If nPos == 0
								cNumMed := CriaVar("CND_NUMMED")
								oTFWDetail:SetValue('TFW_MEDMI',cNumMed)
								A930GerPlan(aPlan, aCabApu,nPosMI,nVlrMedMI, cCodCliMI, cLojaMI, cNumMed, cChvQbrMI, cCodLocal, cItemMI, aPlanHE, aItnsRef, nVlrMedMI)
							Else
								A930AltPlan(aPlan,cItemMI, nVlrMedMI, nPos, nVlrMedMI)
								oTFWDetail:SetValue('TFW_MEDMI',aPlan[nPos][8])
							EndIf
							oTFWDetail:SetValue('TFW_ITEMMI',cItemMI)
						EndIf
						
						If lGsMtMc .and. nVlrMedMC >0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMC"))
							nPos := aScan( aPlan, { |x| x[10] == cChvQbrMC} )
							If nPos == 0
								cNumMed := CriaVar("CND_NUMMED")
								oTFWDetail:SetValue('TFW_MEDMC',cNumMed)
								A930GerPlan(aPlan, aCabApu,nPosMC,nVlrMedMC, cCodCliMC, cLojaMC, cNumMed, cChvQbrMC, cCodLocal, cItemMC, aPlanHE, aItnsRef, nVlrMedMC)
							Else
								A930AltPlan(aPlan,cItemMC, nVlrMedMC, nPos,nVlrMedMC)
								oTFWDetail:SetValue('TFW_MEDMC',aPlan[nPos][8])
							EndIf
							oTFWDetail:SetValue('TFW_ITEMMC',cItemMC)
						EndIf
					
					EndIf
				Else //nPos == 0
					If !lDsgCN .and. (nPosItItens:= aScan( aPlan[nPos][9], { |x| x[1] == cItem} ))>0
						aPlan[nPos][9][nPosItItens][2]+= nVlrMedRH
						aPlan[nPos][9][nPosItItens][3]+= oTFWDetail:GetValue('TFW_ABTINS')
						If lGerHeEx
							aPlan[nPos][12][nPosItItens][2]+= nTotExt
						EndIf
						aPlan[nPos][5]+= nVlrMedRH+nVlrMedMI+nVlrMedMC
					Else
						
						If nVlrMedRH > 0
							aAdd(aPlan[nPos][9]	, {cItem, nVlrMedRH,oTFWDetail:GetValue('TFW_ABTINS')} )
						EndIf
						If lGerHeEx
							aAdd(aPlan[nPos][12],{cItem,nTotExt, cCodTes}) 
						EndIf
						aAdd(aPlan[nPos][13],{cItem,'Recursos Humanos'}) 
						oTFWDetail:SetValue('TFW_NUMMED',aPlan[nPos][8])
						aPlan[nPos][5]+= nVlrMedRH+nVlrMedMI+nVlrMedMC
						
						If !lGrpFat
							If lGsMtMi .And. nVlrMedMI > 0.And. !Empty(oTFWDetail:GetValue("TFW_PDMTMI"))
								aAdd(aPlan[nPos][9]	, {cItemMI, nVlrMedMI,nVlrMedMI} )						
							EndIf
							
							If lGsMtMc .And. nVlrMedMC > 0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMC"))
								aAdd(aPlan[nPos][9]	, {cItemMC, nVlrMedMC, nVlrMedMC} )						
							EndIf
						
						Else
						
							If lGsMtMi .and. nVlrMedMI >0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMI"))
								nPos := aScan( aPlan, { |x| x[10] == cChvQbrMI} )
								If nPos == 0
									cNumMed := CriaVar("CND_NUMMED")
									oTFWDetail:SetValue('TFW_MEDMI',aPlan[nPos][8])
									A930GerPlan(aPlan, aCabApu,nPosMI,nVlrMedMI, cCodCliMI, cLojaMI, cNumMed, cChvQbrMI, cCodLocal, cItemMI, aPlanHE, aItnsRef,nVlrMedMI)
								Else
									A930AltPlan(aPlan,cItemMI, nVlrMedMI, nPos, nVlrMedMI)
									oTFWDetail:SetValue('TFW_MEDMI',aPlan[nPos][8])
								EndIf
								oTFWDetail:SetValue('TFW_ITEMMI',cItemMI)
							EndIf
							
							If lGsMtMc .and. nVlrMedMC >0 .And. !Empty(oTFWDetail:GetValue("TFW_PDMTMC"))
								nPos := aScan( aPlan, { |x| x[10] == cChvQbrMC} )
								If nPos == 0
									cNumMed := CriaVar("CND_NUMMED")
									oTFWDetail:SetValue('TFW_MEDMC',aPlan[nPos][8])
									A930GerPlan(aPlan, aCabApu,nPosMC,nVlrMedMC, cCodCliMC, cLojaMC, cNumMed, cChvQbrMC, cCodLocal, cItemMC, aPlanHE, aItnsRef,nVlrMedMC)
								Else
									A930AltPlan(aPlan,cItemMC, nVlrMedMC, nPos,nVlrMedMC)
									oTFWDetail:SetValue('TFW_MEDMC',aPlan[nPos][8])
								EndIf
								oTFWDetail:SetValue('TFW_ITEMMC',cItemMC)
							EndIf
						EndIf
						
					EndIf //!lDsgCN .and. (nPosItItens:= aScan( aPlan[nPos][9], { |x| x[1] == cItem} ))>0
					
				EndIf //nPos == 0

				If nOpcDA <> 1 
				
					If lGrpFat       
						nPos := At930PCab(@aCabApu, oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"), 'AD', cCodLocal)
						cCodCli	:= aCabApu[nPos][8]
						cLoja	:= aCabApu[nPos][9]
						cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja   
					EndIf
				EndIf //nOpcDA <> 1 
				
			
				If lRecorr .and. (nOpcDA + nOpcHE) == 6 .and. (nVlrDASep + nTotExt)>0
					aFatSep:= {}
					nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[04] == "AG"+cChaveQbr+cB1_CODISS }) //estrutura o pedido por planilha
					If nPosFat == 0
						aAdd(aFatSep, {nVlrDASep + nTotExt, cCodProd, cCodTes} )
						aAdd(aFatSepCab	, {"AG" , cCodCli , cLoja,cChaveQbr+cB1_CODISS , aCabApu[nPosCab][4], aFatSep, cNumMed, aCabApu[nPosCab][6] }) //fabiana
					Else
					
						If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd  .AND. x[04] == cB1_CODISS}))>0
							aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrDASep + nTotExt
						Else
							aAdd(aFatSepCab[nPosFat][6],{nVlrDASep + nTotExt, cCodProd,  cCodTes, cB1_CODISS})
						EndIf 

					Endif
				
				Else
					If nOpcDA == 2 .and. nVlrDASep > 0 .and. nVlrMedRH > 0
						aFatSep:= {}
						nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[04] == "AD"+cChaveQbr+cB1_CODISS }) //estrutura o pedido por planilha
						If nPosFat == 0
							aAdd(aFatSep, {nVlrDASep, cCodProd, cCodTes} )
							aAdd(aFatSepCab	, {"AD" , cCodCli , cLoja,cChaveQbr+cB1_CODISS , aCabApu[nPosCab][4], aFatSep, cNumMed, aCabApu[nPosCab][6] }) //fabiana
						Else
							If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd .AND. x[04] == cB1_CODISS}))>0
								aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrDASep
							Else
								aAdd(aFatSepCab[nPosFat][6],{nVlrDASep, cCodProd,  cCodTes, cB1_CODISS})
							EndIf 

						Endif
					EndIf
					
					If nOpcHE >= 2 .and. nTotExt > 0 .AND. !lGerHeEx
						If lGrpFat       
							nPos := At930PCab(@aCabApu, oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"), 'HE', cCodLocal)
							cCodCli	:= aCabApu[nPos][8]
							cLoja	:= aCabApu[nPos][9]
							cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja+"HE"
							
						Else
							cChaveQbr := aCabApu[nPosCab][4]+"HE"
						   
						EndIf
						
						
						If !lRecorr
						
							nPos := aScan( aPlan, { |x| x[10] == cChaveQbr+cB1_CODISS} ) 
							
							If nPos == 0
								cNumMed := CriaVar("CND_NUMMED")
								oTFWDetail:SetValue('TFW_MEDHE',cNumMed)
								A930GerPlan(aPlan, aCabApu,nPosCab,nTotExt, cCodCli, cLoja, cNumMed, cChaveQbr+cB1_CODISS, cCodLocal, cItem, aPlanHE, aItnsRef)
							Else
								A930AltPlan(aPlan,cItem, nTotExt, nPos)
								oTFWDetail:SetValue('TFW_MEDHE',aPlan[nPos][8])
							EndIf
							
							oTFWDetail:SetValue('TFW_ITMHE',cItem)
						Else
						
							aFatSep:= {}
							nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[04] == "HE"+cChaveQbr+cB1_CODISS}) //estrutura o pedido por planilha
							If nPosFat == 0
								aAdd(aFatSep, {nTotExt, cCodProd, cCodTes} )
								aAdd(aFatSepCab	, {"HE" , cCodCli , cLoja,cChaveQbr+cB1_CODISS , aCabApu[nPosCab][4], aFatSep, cNumMed, aCabApu[nPosCab][6] }) //fabiana
							Else
							
								If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd .and. x[04] == cB1_CODISS }))>0
									aFatSepCab[nPosFat][6][nPosItItens][1] += nTotExt
								Else
									aAdd(aFatSepCab[nPosFat][6],{nTotExt, cCodProd,  cCodTes, cB1_CODISS}) 
								EndIf 
	 
							Endif
						EndIf
					EndIf	// nOpcHE == 2 .and. nTotExt > 0 
				Endif //nOpcDA + nOpcHE == 6 .and. (nVlrDASep + nTotExt)>0
			Endif //nPosCab > 0
		EndIf //If lMedExt .OR. lSrvExt

	Endif//If oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLRMED") > 0

Next nI


RestArea(aAreaSB1)

// ----- MEDIÇAO MATERIAL DE IMPLANTACAO
//Totalizando itens do Material de Implantaçao

aPlanHe:= {}

For nI := 1 To oModel:GetModel("TFXDETAIL"):Length()
	
	oModel:GetModel("TFXDETAIL"):GoLine(nI)
	aPlanItem:= {}
	aItnsRef := {}
	cCodLocal := POSICIONE("TFL",1,xFilial("TFL") + oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFL") ,"TFL_LOCAL")
	If oModel:GetModel("TFXDETAIL"):GetValue("TFX_VLRMED")>0
	
		If lDsgCN
			cCodProd  := Posicione("TFF",1,xFilial("TFF")+oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFF"),"TFF_PRODUT")
			cCodTes  := AT930Tes( "TFF", oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFF"), oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFL") )
		Else
			cCodProd  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_GRPMI")
			cCodTes  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_TESMI")
		Endif
		
		If lMedExt .OR. lSrvExt
	 
			If lSrvExt .And. lGrpFat
				cChaveGF := At930GFIT(cCodLocal, cCodTFJ, "MI", @cCodCli, @cLoja)
			Else
			
				If SB1->(DbSeek(cFilSB1 + cCodProd))
					cB1_CODISS		:= SB1->B1_CODISS
				Else
					cB1_CODISS := ""
				EndIf
				
				cChaveGF := oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFL")+cB1_CODISS
				cCodTFL	 := oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFL")
				nPos:= aScan( aLocPedX, { |x| x[06] == cCodLocal })
				cCodCli:= aLocPedX[nPos][1]
				cLoja := aLocPedX[nPos][2]
			EndIf
			
			If !lOrcPrc
				nVlrDesc:= oModel:GetModel("TFXDETAIL"):GetValue("TFX_TOTDES")
				nVlrMedMI := oModel:GetModel("TFXDETAIL"):GetValue("TFX_VLRMED")+oModel:GetModel("TFXDETAIL"):GetValue("TFX_TOTMUL")- oModel:GetModel("TFXDETAIL"):GetValue("TFX_TOTBON")
			Else
				nVlrMedMI := oModel:GetModel("TFXDETAIL"):GetValue("TFX_VLRMED")+oModel:GetModel("TFXDETAIL"):GetValue("TFX_TOTMUL")- oModel:GetModel("TFXDETAIL"):GetValue("TFX_TOTBON")- nVlrDesc
			EndIf  
	
			nPosLocal := aScan(aItePed, { |x| x[1] == cChaveGF } )
			
			At930GerIts(aItePed, nPosLocal, cChaveGF,cCodProd,nVlrMedMI, nVlrDesc, cCodTes, nDecTFX, lDsgCN,cB1_CODISS,cCodTFL,nVlrMedMI)
	
		Else
									      
			If lGrpFat
				nPosCab := At930PCab(@aCabApu, oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFL"), 'MI', cCodLocal)
			Else
				nPosCab := aScan( aCabApu, { |x| x[1] == oModel:GetModel("TFXDETAIL"):GetValue("TFX_CODTFL") } )
			EndIf
			
			nVlrMedMI := oModel:GetModel("TFXDETAIL"):GetValue("TFX_VLRMED")
			
			If nPosCab > 0
			
				cCodCli	:= aCabApu[nPosCab][8]
				cLoja	:= aCabApu[nPosCab][9]
				If !lDsgCN .and. (nPosIAP := aScan( aIteApu, { |x| x[1] == 2 .And. x[2] == aCabApu[nPosCab][1] } ))>0
					cItem := aIteApu[nPosIAP][4]
				Else		
					cItem := Posicione("TFG",1,xFilial("TFG")+oTFXDetail:GetValue("TFX_CODTFG"),"TFG_ITCNB")
				EndIf
				
				If lGrpFat 
					cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja     
				Else
					cChaveQbr := aCabApu[nPosCab][4]
				EndIf
				nPos := aScan( aPlan, { |x| x[10] == cChaveQbr} )
				
	
				If nPos == 0
				
					cNumMed := CriaVar("CND_NUMMED")
					
					If !lDsgCN
						If (nPosMed := aScan( aMedGCT, { |x| x[1] == aCabApu[nPosCab][1] } ))==0
							aAdd( aMedGCT, { aCabApu[nPosCab][1], cNumMed, "", cItem, "", "" } )
						Else 
							aMedGCT[nPosMed][4] := cItem
						EndIf
					EndIf
					
					Aadd( aItnsRef,{cItem,'Materiais de implantação'})	
									
					A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMedMI, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItem, aPlanHE, aItnsRef,nVlrMedMI)
									
					oTFXDetail:SetValue('TFX_NUMMED',cNumMed)
				
				Else
				
					If !lDsgCN .and. (nPosItItens:= aScan( aPlan[nPos][9], { |x| x[1] == cItem} ))>0
						aPlan[nPos][9][nPosItItens][2]+= nVlrMedMI
						aPlan[nPos][9][nPosItItens][3]+= nVlrMedMI //abatimento de INSS
					Else
						oTFXDetail:SetValue('TFX_NUMMED',aPlan[nPos][8])
						aAdd(aPlan[nPos][9],{cItem, nVlrMedMI,nVlrMedMI}) 
						aAdd(aPlan[nPos][13],{cItem,'Materiais de implantação'})
					EndIf
					aPlan[nPos][5]+= nVlrMedMI
				Endif
				
				oTFXDetail:SetValue('TFX_ITMED',cItem)
		
			EndIf	//nPosCab > 0
		EndIf //lMedExt .OR. lSrvExt
	EndIf //oModel:GetModel("TFXDETAIL"):GetValue("TFX_VLRMED")	

Next nI

// ----- MEDIÇAO MATERIAL DE CONSUMO
//Totalizando itens do Material de Consumo

For nI := 1 To oModel:GetModel("TFYDETAIL"):Length()
	
	oModel:GetModel("TFYDETAIL"):GoLine(nI)
	aPlanItem:= {}
	aItnsRef := {}
	cCodLocal := POSICIONE("TFL",1,xFilial("TFL") + oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFL") ,"TFL_LOCAL")
	If oModel:GetModel("TFYDETAIL"):GetValue("TFY_VLRMED") > 0

		If lDsgCN
			cCodProd  := Posicione("TFF",1,xFilial("TFF")+oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFF"),"TFF_PRODUT")//oModel:GetModel("TFYDETAIL"):GetValue("TFY_PRODUT")
			cCodTes := AT930Tes( "TFF", oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFF"), oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFL") )
		Else
			cCodProd  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_GRPMC")
			cCodTes := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_TESMC")
		Endif
		
		If lMedExt .OR. lSrvExt
	
			If lSrvExt .And. lGrpFat
				cChaveGF := At930GFIT(cCodLocal, cCodTFJ, "MC", @cCodCli, @cLoja) 
			Else
				If SB1->(DbSeek(cFilSB1 + cCodProd))
					cB1_CODISS		:= SB1->B1_CODISS
				Else
					cB1_CODISS := ""
				EndIf
				cChaveGF := oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFL") + cB1_CODISS
				cCodTFL	 := oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFL")
				
			EndIf  
			If !lOrcPrc
				nVlrDesc:= oModel:GetModel("TFYDETAIL"):GetValue("TFY_TOTDES")
				nVlrMedMC := oModel:GetModel("TFYDETAIL"):GetValue("TFY_VLRMED")+oModel:GetModel("TFYDETAIL"):GetValue("TFY_TOTMUL")- oModel:GetModel("TFYDETAIL"):GetValue("TFY_TOTBON")
			Else
				nVlrMedMC := oModel:GetModel("TFYDETAIL"):GetValue("TFY_VLRMED")+oModel:GetModel("TFYDETAIL"):GetValue("TFY_TOTMUL")- oModel:GetModel("TFYDETAIL"):GetValue("TFY_TOTBON")- nVlrDesc
			EndIf
	
			nPosLocal := aScan(aItePed, { |x| x[1] == cChaveGF } )
			
			At930GerIts(aItePed, nPosLocal, cChaveGF,cCodProd,nVlrMedMC, nVlrDesc, cCodTes, nDecTFY, lDsgCN,cB1_CODISS,cCodTFL,nVlrMedMC)

		Else	
				
			If lGrpFat
				nPosCab := At930PCab(@aCabApu, oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFL"), 'MC', cCodLocal)
	        Else
	        	nPosCab := aScan( aCabApu, { |x| x[1] == oModel:GetModel("TFYDETAIL"):GetValue("TFY_CODTFL") } )
	        EndIf
	   	
			nVlrMedMC := oModel:GetModel("TFYDETAIL"):GetValue("TFY_VLRMED")
			
			If nPosCab > 0
			
				cCodCli	:= aCabApu[nPosCab][8]
				cLoja	:= aCabApu[nPosCab][9]	
				If !lDsgCN .and. (nPosIAP := aScan( aIteApu, { |x| x[1] == 3 .And. x[2] == aCabApu[nPosCab][1] } ))>0
					cItem := aIteApu[nPosIAP][4]
				Else	
					cItem := Posicione("TFH",1,xFilial("TFH")+oTFYDetail:GetValue("TFY_CODTFH"),"TFH_ITCNB")
				EndIf
				
				If lGrpFat 
					cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja     
				Else
					cChaveQbr := aCabApu[nPosCab][4]
				EndIf
				nPos := aScan( aPlan, { |x| x[10] == cChaveQbr} )
				
	
				If nPos == 0
				
					cNumMed := CriaVar("CND_NUMMED")
					
					If !lDsgCN
						If (nPosMed := aScan( aMedGCT, { |x| x[1] == aCabApu[nPosCab][1] } ))==0
							aAdd( aMedGCT, { aCabApu[nPosCab][1], cNumMed, "", "", cItem, "" } )
						Else 
							aMedGCT[nPosMed][5] := cItem
						EndIf
					EndIf
					Aadd( aItnsRef,{cItem,'Materiais de consumo'})			
					

					A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMedMC, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItem, aPlanHE, aItnsRef,nVlrMedMC)
									
					oTFYDetail:SetValue('TFY_NUMMED',cNumMed)
				
				Else
				
					If !lDsgCN .and. (nPosItItens:= aScan( aPlan[nPos][9], { |x| x[1] == cItem} ))>0
						aPlan[nPos][9][nPosItItens][2]+= nVlrMedMC
						aPlan[nPos][9][nPosItItens][3]+= nVlrMedMC
					Else
						oTFYDetail:SetValue('TFY_NUMMED',aPlan[nPos][8])
						aAdd(aPlan[nPos][9],{cItem, nVlrMedMC,nVlrMedMC}) 
						aAdd(aPlan[nPos][13],{cItem,'Materiais de consumo'})
					EndIf
					aPlan[nPos][5]+= nVlrMedMC
				Endif
				
				oTFYDetail:SetValue('TFY_ITMED',cItem)
			EndIf	
		EndIf //lMedExt .OR. lSrvExt
	EndIf //oModel:GetModel("TFYDETAIL"):GetValue("TFY_VLRMED")

Next nI

// ----- MEDIÇAO LOCACAO DE EQUIPAMENTO
//Totalizando itens de Locacao de Equipamento

For nI := 1 To oModel:GetModel("TFLDETAIL"):Length()

	oModel:GetModel("TFLDETAIL"):GoLine(nI)

	If oModel:GetModel("TFLDETAIL"):GetValue("TFL_VALTOT") > 0
	
		cCodLocal := oModel:GetModel("TFLDETAIL"):GetValue("TFL_LOCAL")
	       
		If lMedExt .OR. lSrvExt
	
			If lSrvExt .And. lGrpFat
				cChaveGF := At930GFIT(cCodLocal, cCodTFJ, "LE", @cCodCli, @cLoja) 
			Else
				cChaveGF := oModel:GetModel("TFLDETAIL"):GetValue("TFL_CODIGO")
				nPos:= aScan( aLocPedX, { |x| x[06] == cCodLocal })
				cCodCli:= aLocPedX[nPos][1]
				cLoja := aLocPedX[nPos][2]
			EndIf  
					
			For nW := 1 To oTFIDetail:Length() //leitura por item do local
			
				oTFIDetail:GoLine(nW)
				
				If nOpcDA <> 1
					nVlrDASep:= 0
					For nY := 1 To oTW7TFIDetail:Length()
						oTW7TFIDetail:GoLine(nY)
						If !oTW7TFIDetail:IsDeleted() .And. oTW7TFIDetail:GetValue('TW7_VALOR') > 0 
							If oTW7TFIDetail:GetValue("TW7_DESPAD")== '1' 	
								nVlrDASep += oTW7TFIDetail:GetValue("TW7_VALOR")
							EndIf 
						EndIf
					Next nY	

				EndIf
				
				
				If !lOrcPrc
			 		nVlrDesc:= oTFIDetail:GetValue("TFI_TOTDES")
					nVlrMedLE := oTFIDetail:GetValue("TFI_DISP")+oTFIDetail:GetValue("TFI_TOTMUL")-oTFIDetail:GetValue("TFI_TOTBON")-nVlrDASep
				Else
					nVlrMedLE := oTFIDetail:GetValue("TFI_DISP")+oTFIDetail:GetValue("TFI_TOTMUL")-oTFIDetail:GetValue("TFI_TOTBON")-oTFIDetail:GetValue("TFI_TOTDES") -nVlrDASep
				EndIF
				
				If lDsgCN
					cCodProd  := oTFIDetail:GetValue("TFI_PRODUT")
					cCodTes	  := oTFIDetail:GetValue("TFI_TES")
				Else
					cCodProd  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_GRPLE")
					cCodTes	  := Posicione("TFJ",1,xFilial("TFJ")+oTFVMaster:GetValue("TFV_ORCSRV"),"TFJ_TESLE")
				Endif

				nPos:= aScan( aLocPedX, { |x| x[06] == cCodLocal })
				
				If nOpcDA <> 1 .and. nVlrDASep > 0
				
					If lGrpFat
						cChaveQbr := At930GFIT(cCodLocal, cCodTFJ, "AD", @cCodCli, @cLoja)
					Else
						cChaveQbr := cCodLocal
					EndIf 
					aFatSep:= {}
					nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[05] == cIDFatSep+aLocPedX[nPos][6] }) //estrutura o pedido por local 
					If nPosFat == 0
						aAdd(aFatSep, {nVlrDASep, cCodProd, cCodTes} )
						aAdd(aFatSepCab	, {cIDFatSep , cCodCli , cLoja,cChaveQbr, cCodLocal, aFatSep, cNumMed, cCodLocal })
					Else
						If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd }))>0
							aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrDASep
						Else
							aAdd(aFatSepCab[nPosFat][6],{nVlrDASep, cCodProd,  cCodTes, ""})
						EndIf  
					Endif
				EndIf
		
				nPosLocal := aScan(aItePed, { |x| x[1] == cChaveGF } )
				
				At930GerIts(aItePed, nPosLocal, cChaveGF,cCodProd,nVlrMedLE, nVlrDesc, cCodTes, nDecTFI, lDsgCN)
				
			Next nW

		Else	
		
			If lGrpFat
				nPosCab := At930PCab(@aCabApu, oModel:GetModel("TFLDETAIL"):GetValue("TFL_CODIGO"), 'LE', cCodLocal)
		    Else
		    	nPosCab := aScan( aCabApu, { |x| x[1] == oModel:GetModel("TFLDETAIL"):GetValue("TFL_CODIGO") } )
		    EndIf

			If nPosCab > 0

				
				For nW := 1 To oTFIDetail:Length() //leitura por item da planilha
					oTFIDetail:GoLine(nW)
					aPlanItem:= {}
					aItnsRef := {}
					If nOpcDA <> 1
						nVlrDASep:= 0
						For nY := 1 To oTW7TFIDetail:Length()
							oTW7TFIDetail:GoLine(nY)
							If !oTW7TFIDetail:IsDeleted() .And. oTW7TFIDetail:GetValue('TW7_VALOR') > 0 
								If oTW7TFIDetail:GetValue("TW7_DESPAD")== '1' 	
									nVlrDASep += oTW7TFIDetail:GetValue("TW7_VALOR")
								EndIf 
							EndIf
						Next nY	

					EndIf

					
					nVlrMedLE := oTFIDetail:GetValue("TFI_DISP") 
					If !lDsgCN .and. (nPosIAP := aScan( aIteApu, { |x| x[1] == 4 .And. x[2] == aCabApu[nPosCab][1] } ))>0
						cItem := aIteApu[nPosIAP][4]
					Else
						cItem := oTFIDetail:GetValue('TFI_ITCNB')
					EndIf
					cCodCli	:= aCabApu[nPosCab][8]
					cLoja	:= aCabApu[nPosCab][9]
					If lGrpFat 
						cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja     
					Else
						cChaveQbr := aCabApu[nPosCab][4]
					EndIf
					nPos := aScan( aPlan, { |x| x[10] == cChaveQbr} )

					If nPos == 0 //indica uma nova planilha para medição
			
						cNumMed := CriaVar("CND_NUMMED")
						
						If !lDsgCN
							If (nPosMed := aScan( aMedGCT, { |x| x[1] == aCabApu[nPosCab][1] } ))==0
								aAdd( aMedGCT, { aCabApu[nPosCab][1], cNumMed, "", "", "", cItem } )
							Else 
								aMedGCT[nPosMed][6] := cItem
							EndIf
						EndIf

						Aadd( aItnsRef,{cItem,'Locação de equipamentos'})
						A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMedLE, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItem, aPlanHE, aItnsRef)
						
					Else
						If !lDsgCN .and. (nPosItItens:= aScan( aPlan[nPos][9], { |x| x[1] == cItem} ))>0
							aPlan[nPos][9][nPosItItens][2]+= nVlrMedLE
						Else
							cNumMed := aPlan[nPos][8]
							aAdd(aPlan[nPos][9],{cItem, nVlrMedLE,0})
							Aadd( aItnsRef,{cItem,'Locação de equipamentos'})
						EndIf
						
						aPlan[nPos][5]+= nVlrMedLE 
					Endif //nPos == 0 
					
					For nU := 1 To oTFZDetail:Length()
						oTFZDetail:GoLine(nU)
						If oTFZDetail:GetValue('TFZ_TOTAL') > 0
							oTFZDetail:SetValue('TFZ_NUMMED',cNumMed)
							oTFZDetail:SetValue('TFZ_ITMED',cItem)
						EndIf
		
					Next nU
				
					If lDsgCN
						cCodProd  := oTFIDetail:GetValue("TFI_PRODUT")
						cCodTes	  := oTFIDetail:GetValue("TFI_TES")
					Else
						cCodProd  :=Posicione("TFJ",5,xFilial("TFJ")+oTFVMaster:GetValue("TFV_CONTRT")+oTFVMaster:GetValue("TFV_REVISA"),"TFJ_GRPLE")
						cCodTes  := Posicione("TFJ",5,xFilial("TFJ")+oTFVMaster:GetValue("TFV_CONTRT")+oTFVMaster:GetValue("TFV_REVISA"),"TFJ_TESLE")
					Endif
				
					If nOpcDA > 1 .and. nVlrDASep > 0 
						If lGrpFat       
							nPos := At930PCab(@aCabApu, oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"), 'AD', cCodLocal)
							cCodCli	:= aCabApu[nPos][8]
							cLoja	:= aCabApu[nPos][9]
							cChaveQbr := aCabApu[nPosCab][4]+cCodCli+cLoja   
						EndIf
						aFatSep:= {}
						nPosFat:=   aScan( aFatSepCab, { |x| x[01]+x[04] == cIDFatSep+cChaveQbr }) //estrutura o pedido por planilha
						If nPosFat == 0
							aAdd(aFatSep, {nVlrDASep,cCodProd, cCodTes} )
							aAdd(aFatSepCab	, {cIDFatSep , cCodCli , cLoja,cChaveQbr , aCabApu[nPosCab][4], aFatSep, cNumMed, aCabApu[nPosCab][6] }) //fabiana
						Else
							If !lDsgCN .and. (nPosItItens:= aScan( aFatSepCab[nPosFat][6], { |x| x[02] == cCodProd }))>0
								aFatSepCab[nPosFat][6][nPosItItens][1] += nVlrDASep
							Else
								aAdd(aFatSepCab[nPosFat][6],{nVlrDASep, cCodProd,  cCodTes, ""})
							EndIf  
						Endif
					EndIf
				Next nW
			EndIf //If nPosCab > 0
		Endif //lMedExt .OR. lSrvExt
	Endif //oModel:GetModel("TFLDETAIL"):GetValue("TFL_VALTOT") > 0

Next nI

// ----- VALOR MEDIÇÃO POR PLANILHA
// Adiciona o valor do imposto ao total 
If lOrcPrc .And. lSomaImp .and. !lDsgCN
	For nI := 1 To oModel:GetModel("TWBDETAIL"):Length()
	
		oModel:GetModel("TWBDETAIL"):GoLine(nI)
		
		nPosCab := aScan( aPlan, { |x| x[1] == oModel:GetModel("TWBDETAIL"):GetValue("TWB_CODTFL") } )
		
		If nPosCab > 0
		
			aPlan[nPosCab][5] += Round(oModel:GetModel("TWBDETAIL"):GetValue("TWB_IMPMED"),2)
			For nZ := 1 To Len(aPlan[nI][9])
				
				aPlan[nPosCab][9][nZ][2] += Round(oModel:GetModel("TWBDETAIL"):GetValue("TWB_IMPMED"),2)
					
			Next nZ
		
		EndIf

	Next nI
EndIf


If lMedExt .OR. lSrvExt
	
	If lSrvExt .And. lGrpFat 
		aLocPed:= at930GFCAB(aLocPed)
	EndIf
	
	//Ordena pelo local + quebra do Pedido
	
	aSort(aItePed , , , {|a, b| a[4]+ a[1] < b[4] + b[1]})

	
	// GERACAO DO PEDIDO PARA A MEDICAO FORA DO CONTRATO
	For nI:=1 To Len(aLocPed)	
	
		cChaveQbr := ""
		
		If lSrvExt .And. lGrpFat 
			cChaveLoc := aLocPed[nI][7] + aLocPed[nI][3] + aLocPed[nI][4] 

		Else
			cChaveLoc := aLocPed[nI][1]
		EndIf
		
		nPosLocal := aScan( aItePed, { |x| x[4] == cChaveLoc  } ) //Chave sem o código do ISSQN
		
	
		cChaveQbr := ""
		aPedCabec := {}
		aPedItens := {}
		xAuxPed   := {}
		aRateio   := {}		
	 
		If nPosLocal > 0
			//Chave de Quebra do pedido de venda
			cChaveQbr := aItePed[nPosLocal][1]
			//Insere uma nova quebra : codigo do serviço Iss
			
			Do While nPosLocal <= Len(aItePed) .AND. aItePed[nPosLocal][4] == cChaveLoc
				//Quebra do Pedido
				If !(cChaveQbr == aItePed[nPosLocal][1])
				
					//Gera o Pedido de venda com os itens anteriores
					lRet := at930GPed(aPedItens, aLocPed[nI], oTFVMaster, lFatDASep, aLocPedX, dDtIniApu, dDtFimApu, lGrpFat, oModel, oTFVMaster, lSrvExt, xAuxPed)
					
					If !lRet
						Exit
					EndIf
					aPedCabec := {}
					aPedItens := {}
					xAuxPed   := {}
					aRateio   := {}	
					cChaveQbr := aItePed[nPosLocal][1]			
					
				EndIf	
					
				//Insere os itens do pedido
				For nX:=1 To Len(aItePed[nPosLocal][2])	
					aAdd( xAuxPed, {} )		
					For nY:=1 To Len(aItePed[nPosLocal][2][nX])				
						aAdd( xAuxPed[Len(xAuxPed)], aItePed[nPosLocal][2][nX][nY] )
					Next nY			
				Next nX	
				
				aPedItens := aClone( xAuxPed )		
			
						

			 	nPosLocal++
			EndDo
			
			lRet := at930GPed(aPedItens, aLocPed[nI], oTFVMaster, lFatDASep, aLocPedX, dDtIniApu, dDtFimApu, lGrpFat, oModel, oTFVMaster, lSrvExt, xAuxPed)
			If !lRet
				Exit
			EndIf			
		EndIf
	Next nI
Else //lMedExt .OR. lSrvExt
	// REALIZACAO DA MEDICAO NO GCT, ATRAVES DOS DADOS COLETADOS E TOTALIZADOS
	aAux := {}
	For nI:=1 To Len(aPlan)
	
		
		// Tela para seleção da competencia e parcela
		If (aScan( aAux, { |x| x == aPlan[nI][4]+aPlan[nI][1] }))==0
			xAux := At930Compt( cMV_PAR01, cRevCtr, aPlan[nI][4], aPlan[nI][1] , aPlan[nI][5])
			aAdd( aAux, aPlan[nI][4]+aPlan[nI][1])
		EndIf
		
		// Quando usuário fechar sem preessionar o Ok, aborta o processo de geração/gravação
		If xAux == Nil
			lRet := .F.
			_aComptc := {} //Reinicia a variavel apra não ter problemas em medições novas
			Exit
		Else
			// identifica a competência para geração da medição
			aCmboCmp := aClone( xAux )
			aCabe	:=	{}
			aItem	:=	{}
			aItemExc := {}

			// Cabecalho para envio da medição para o GCT
			aAdd( aCabe, { "CND_FILIAL", xFilial("CND"), NIL } )
			aAdd( aCabe, { "CND_CONTRA", aPlan[nI][2], NIL } )	
			aAdd( aCabe, { "CND_REVISA", aPlan[nI][3], NIL } )
			aAdd( aCabe, { "CND_NUMERO", aPlan[nI][4], NIL } )

			//-------------------------------------
			//  Verifica se
			If Len( aCmboCmp ) > 0
				aAdd( aCabe, { "CND_COMPET", aCmboCmp[1][1], NIL } )
				aAdd( aCabe, { "CND_PARCEL", aCmboCmp[1][2], NIL } )
			Else
				aAdd( aCabe, { "CND_COMPET", Space(TamSX3('CND_COMPET')[1]), NIL } )
				aAdd( aCabe, { "CND_PARCEL", Space(TamSX3('CND_PARCEL')[1]), NIL } )
			EndIf

			aAdd( aCabe, { "CND_NUMMED", aPlan[nI][8], NIL } )
			aAdd( aCabe, { "CND_VLTOT", aPlan[nI][5], NIL } )
			
			//Cliente e Loja
			If lGrpFat
				aAdd( aCabe, { "CND_CLIENT", aPlan[nI][6], NIL } )
				aAdd( aCabe, { "CND_LOJACL", aPlan[nI][7], NIL } )
			EndIf
			
			For nZ := 1 To Len(aPlan[nI][9])
			
				aAdd( aItem, {} )
				aAdd( aItem[Len(aItem)], { "CNE_ITEM"  	, aPlan[nI][9][nZ][1], NIL } )
				aAdd( aItem[Len(aItem)], { "CNE_VLTOT"	, aPlan[nI][9][nZ][2], NIL } )
				aAdd( aItem[Len(aItem)], { "CNE_ABTINS"	, aPlan[nI][9][nZ][3], NIL } )
			
			Next nZ
			
			
			If lGerHeEx .and. Len(aPlan[nI][12])>0
				For nZ := 1 To Len(aPlan[nI][12])
				
					aAdd( aItemExc, {} )
					aAdd( aItemExc[Len(aItemExc)], { "CNE_ITEM", aPlan[nI][12][nZ][1], NIL } )
					aAdd( aItemExc[Len(aItemExc)], { "CNE_VLUNIT", aPlan[nI][12][nZ][2], NIL } )
					aAdd( aItemExc[Len(aItemExc)], { "CNE_QUANT"  	, 1, NIL } )
					aAdd( aItemExc[Len(aItemExc)], { "CNE_TES" 		, aPlan[nI][12][nZ][3], NIL } )
				
				Next nZ
			EndIf
			
			lFatDASep:= IIF(nOpcDA <> 1 , .T. , .F.)
			
			If lFatDASep .and. nOpcHE == 3 //tratamento de quando for hora extra e fatura aglutinado, gerar as despesas adicionais como multa da hora extra
				lFatDASep := !("HE"$ aPlan[nI][10])
			EndIf
			If nOpcHE > 1
				lMedHE	:= ("HE"$ aPlan[nI][10])
			EndIf
			
			nVlrMulta	:= 0
			nVlrBoni	:= 0
			nVlrTotHE	:= 0
			aMultas 	:= A930Multas(oModel,aPlan[nI][4],@nVlrMulta,@nVlrBoni,@nVlrDASep,  lFatDASep, @nVlrTotHE, lMedHE)
			If !lMedHE
				nVlrDesc 	:= A930Desc(oModel,aPlan[nI][4],aPlan[nI][2],aPlan[nI][3],lGrpFat,aPlan[nI][1],,,aDescs)
			EndIf
			
			If Len(aCmboCmp) > 0 .And. lRet .And. lDsgCN .And. !At930VldCNB(@aItem,aPlan[nI][13],aPlan[nI][13],aPlan[nI][1],aPlan[nI][2],aPlan[nI][3],aPlan[nI][4])
				lRet := .F.
				Exit
			EndIf
			
			
			// função At930VldSld = [valor da parcela na CNF maior que o valor da medição?]
			nRetCNF := 0
			If lRet .And. !lMedHE .and. Len(aCmboCmp) > 0 .And. At740Recor(aCabe[2][2]) .And. ;
				!At930VldSld(	aCabe[2][2],;//cContrato
								aCabe[3][2],;	//cRevisao
								aCmboCmp[1][3],;//cCronog
								aCmboCmp[1][1],;//cComp
								aCabe[8][2],;	//nValMed
								cOpcApu,;	//cOpcHE
								nVlrTotHE,;	//nVlrTotHE
								nVlrDesc,; //nVlrDesc
								nVlrMulta,;	//nVlrMulta
								nVlrBoni,;	//nVlrBoni
								aCmboCmp[1][2],;
								@nRetCNF)	//cParcela

				MsgInfo(STR0070 + CRLF + CRLF + STR0071+ CRLF  + CRLF +  ;
							"Valor de medição: " + Alltrim(Transform(aCabe[8][2] - nVlrDesc +  nVlrMulta - nVlrBoni,cPict))+ CRLF+;
							"Saldo da competência: " + Alltrim(Transform(nRetCNF,cPict)) + CRLF +;
							"Diferença: " + Alltrim(Transform((aCabe[8][2] - nVlrDesc +  nVlrMulta - nVlrBoni) - nRetCNF,cPict)))
							//"Valor total de medição não previsto no cronograma."+CRLF+"O mesmo deve ser reestruturado."
				lRet:= .F.
				Exit
			EndIf
			//chamada da execauto do contrato
			If Len(aCabe) > 0 .And. Len(aItem) > 0 .And. lRet
				lMsErroAuto:= .F.

				//ExecAuto para inclusão da medição/apuração.
				MsExecAuto({|a,b,c,d|, CNTA120(a,b,c,Nil,Nil,Nil,d,aMultas,aDescs,@lRet) },aCabe,aItem,3)
			
				aMultas  	:= {}
				aDescs   	:= {}
				
				If !lMsErroAuto
					lMsErroAuto := .F.

					//Coleta o codigo do local de atendimento
					aComplSC5 := GetComplSc5(aPlan[nI][11])

					//ExecAuto para a finalização da medição/apuração.
					MsExecAuto({|a,b,c,d|, CNTA120(a,b,c,Nil,Nil,Nil,d,Nil,aComplSC5,@lRet)},aCabe,aItem,6)

					If !lMsErroAuto
						If !Empty(aItemExc) .And. lRet
							lMsErroAuto := .F.

							//ExecAuto para inclusaão do valor extra na medição/apuração.
							MsExecAuto({|a,b,c,d|, CNTA120(a,b,c,Nil,Nil,Nil,d,Nil,Nil,@lRet)},aCabe,aItem,8,aItemExc)

							If lMsErroAuto
								If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
									Help(,,'AT930ERRMD3',,STR0124,1,0)
								Else
									MostraErro()
								EndIf
								lRet := .F.		
								Exit
							Endif
						Endif
						
						If lRet .and. !lFatDASep
							A930GrvTWQ(lSrvExt,aLocPedx,aPlan[nI][4], aPlan[nI][8], SC5->C5_NUM, dDtIniApu, dDtFimApu, lGrpFat)
						EndIf
					Else
						If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
							Help(,,'AT930ERRMD2',,STR0078,1,0)
						Else
							MostraErro()
						EndIf
						lRet:= .F.
						Exit
					EndIf //2° !lMsErroAuto
				Else
					If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
						Help(,,'AT930ERRMD1',,STR0079,1,0)
					Else
						MostraErro()
					EndIf
					lRet:= .F.
					Exit
				EndIf // 1° If !lMsErroAuto
			EndIf //Len(aCabe) > 0 .And. Len(aItem) > 0 .And. lRet
		EndIf //xAux == Nil						
	Next nI

EndIf //lMedExt .OR. lSrvExt


// -------------------------------
// RESET DE VARIÁVEIS DE CONTROLE
// -------------------------------

nVlrMulta	:= 0
nVlrBoni	:= 0
nVlrDASep	:= 0

// ----------------------------------------------------
// GERAÇÃO DOS PEDIDOS PROVENIENTES DO FATURA SEPARADO
// ----------------------------------------------------
If Len(aFatSepCab) > 0 .and. lRet
	
	For j := 1 to Len(aFatSepCab)
		
		aCabecF:= {}
		
		aAdd( aCabecF, { "C5_FILIAL"  	, xFilial("SC5") 					, Nil } )
		aAdd( aCabecF, { "C5_TIPO"    	, 'N'		   						, Nil } )
		aAdd( aCabecF, { "C5_CLIENTE" 	, aFatSepCab[j][2]					, Nil } )
		aAdd( aCabecF, { "C5_LOJACLI" 	, aFatSepCab[j][3]					, Nil } )
		aAdd( aCabecF, { "C5_CONDPAG" 	, aLocPedX[1][3]					, Nil } )
	 	aAdd( aCabecF, { "C5_ORIGEM"	, 'TECA930'							, Nil } )
	 	aAdd( aCabecF, { "C5_MDCONTR"	, aLocPedX[1][4]					, Nil } )
	 	
 		If lSrvExt
			aAdd( aCabecF, { 'C5_ORCSERV', oTFVMaster:GetValue("TFV_ORCSRV"), Nil } )
		EndIf
	 
		//Insere os dados complementares do Pedido
		

		aCompPed:= GetComplSc5(aFatSepCab[j][8])
		
		If Len(aCompPed) > 0 
			For i := 1 to Len(aCompPed)
				aAdd( aCabecF, {aCompPed[i][1] , aCompPed[i][2]	, Nil } )
			Next i			
		Endif


		aItemF  := {}
		
		
		For i := 1 to Len(aFatSepCab[j][6]) 
			aItensF := {}
				
			AAdd( aItensF, { "C6_FILIAL"	, xFilial("SC6") 						, NIL})
			AAdd( aItensF, { "C6_ITEM"		, StrZero( i, TamSx3("C6_ITEM")[1] )	, NIL})
			AAdd( aItensF, { "C6_PRODUTO"	, aFatSepCab[j][6][i][2]   				, NIL})
			AAdd( aItensF, { "C6_QTDVEN"	, 1                                 	, NIL})
			AAdd( aItensF, { "C6_PRCVEN"	, aFatSepCab[j][6][i][1]            	, NIL})
			AAdd( aItensF, { "C6_PRUNIT"	, aFatSepCab[j][6][i][1]            	, NIL})
			AAdd( aItensF, { "C6_VALOR"		, aFatSepCab[j][6][i][1]            	, NIL})
			AAdd( aItensF, { "C6_TES"		, aFatSepCab[j][6][i][3] 				, NIL})
			AAdd( aItensF, { "C6_CC"		, CNB->CNB_CC	               			, NIL})
		    
			AAdd(aItemF, aItensF)
		Next i
			lMsErroAuto := .F.
			MsExecAuto({|x,y,z| MATA410(x,y,z)},aCabecF,aItemF,3 )
								     
			If lMsErroAuto
				lRet := .F.
				xAuxPed := GetAutoGrLog()
				MostraErro()
			Else 
				lRet := .T.
				
				If !Empty(oModel:GetModel("TCVDETAIL"):GetValue("TCV_NUMAPU")) 				
					oModel:GetModel("TCVDETAIL"):AddLine()
				EndIf
					 
				oModel:GetModel("TCVDETAIL"):SetValue("TCV_FILIAL" , xFilial("TCV") )
				oModel:GetModel("TCVDETAIL"):SetValue("TCV_NUMAPU" , oModel:GetModel("TFVMASTER"):GetValue("TFV_CODIGO") )
				oModel:GetModel("TCVDETAIL"):SetValue("TCV_NUMPED" , SC5->C5_NUM )			
				oModel:GetModel("TCVDETAIL"):SetValue("TCV_FATSEP" , '1' )	
				If lFatDASep
					A930GrvTWQ(lSrvExt,aLocPedX,aFatSepCab[j][5], aFatSepCab[j][7], SC5->C5_NUM, dDtIniApu, dDtFimApu, lGrpFat)
				Endif
				
			EndIf //If lMsErroAuto
	Next j
EndIf

// Atualiza as tabelas com dados gerados da medições do GCT
If lRet
	
	FwModelActive(oModel) // restabelece o model da apuração como o ativo
	
	If lSrvExt
		cWhereCob := "%TFF.TFF_COBCTR = '2' AND TFF.TFF_PRCVEN > 0%"
		cChvABQ   := "%ABQ.ABQ_CODTFJ = '"+cCodTFJ+"'%"
		cChvTFL   := "%TFL.TFL_CODPAI = '"+cCodTFJ+"'%"
	Else
		If lMedExt	
			cWhereCob := "%TFF.TFF_COBCTR = '2' AND TFF.TFF_PRCVEN > 0%" 
		Else	 
			cWhereCob := "%TFF.TFF_COBCTR <> '2' %"
		EndIf
		cChvABQ   := "%ABQ.ABQ_CONTRT = '"+cMV_PAR01+"'%"
		cChvTFL   := "%TFL.TFL_CONTRT = '"+cMV_PAR01+"' AND "
		cChvTFL   += "TFL.TFL_CONREV = '"+cRevCtr  +"'%"
	EndIf

	//Populando campos para a apuração do RH
		BeginSql Alias cAliasAB9
			SELECT AB9.AB9_FILIAL, AB9.AB9_NUMOS, AB9.AB9_CODTEC, AB9.AB9_SEQ                                                                                                                         
			  FROM %table:ABB% ABB
			       JOIN %table:AB9% AB9 ON AB9.AB9_FILIAL = %xFilial:AB9%
			                           AND AB9.AB9_ATAUT = ABB.ABB_CODIGO
			                           AND AB9.AB9_NUMOS = ABB.ABB_CHAVE
			                           AND RTrim(LTrim(AB9.AB9_ITAPUR)) = ' '
			                           AND AB9.%NotDel%
			       JOIN %table:ABA% ABA ON ABA.ABA_FILIAL = %xFilial:ABA%
			                           AND ABA.ABA_NUMOS = AB9.AB9_NUMOS
			                           AND ABA.ABA_SEQ  =  AB9.AB9_SEQ
			                           AND ABA.%NotDel%
			       JOIN %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
			                           AND ABB.ABB_IDCFAL = %Exp:cIdcABQ%
			                           AND ABQ.%NotDel%
			       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
			                           AND TFF.TFF_FILIAL = ABQ.ABQ_FILTFF
			                           AND TFF.TFF_COD = ABQ.ABQ_CODTFF
			                           AND %Exp:cWhereCob%
			                           AND TFF.%NotDel%
			       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
			                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
			                           AND TFL.%NotDel%                    
				                       AND %Exp:cChvTFL%
			 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
			   AND ABB.ABB_CHEGOU = 'S'
			   AND ABB.ABB_ATENDE = '1'
			   AND ABB.ABB_DTINI >= %Exp:dDtIniApu%
			   AND ABB.ABB_DTINI <= %Exp:dDtFimApu%
			   AND ABB.ABB_DTFIM >= %Exp:dDtIniApu%
			   AND ABB.ABB_DTFIM <= %Exp:dDtFimApu%
			   AND ABQ.ABQ_CONTRT = %Exp:cMV_PAR01%
			   AND ABB.%NotDel%
			 GROUP BY AB9.AB9_FILIAL, AB9.AB9_NUMOS, AB9.AB9_CODTEC, AB9.AB9_SEQ

		EndSql

	dbSelectArea("AB9")
	AB9->(dbSetOrder(1))
	
	While (cAliasAB9)->(!Eof())		
	
		If AB9->(dbSeek(xFilial("AB9")+(cAliasAB9)->AB9_NUMOS + ;
						 (cAliasAB9)->AB9_CODTEC + (cAliasAB9)->AB9_SEQ))  
			Reclock("AB9",.F.)
			AB9->AB9_ITAPUR := oTFVMaster:GetValue("TFV_CODIGO")
			MsUnlock()				
		EndIf
		(cAliasAB9)->(dbSkip())
		
	EndDo
	
	If lSrvExt
		cWhereCob := "%TFG.TFG_COBCTR = '2' AND TFG.TFG_PRCVEN > 0%" 
		cChvTFL   := "%TFL.TFL_CODPAI = '"+cCodTFJ+"'%"
	Else
		If lMedExt
			cWhereCob := "%TFG.TFG_COBCTR = '2' AND TFG.TFG_PRCVEN > 0%" 
		Else
			cWhereCob := "%TFG.TFG_COBCTR <> '2' %"
		EndIf
		cChvTFL := "%TFL.TFL_CONTRT = '"+cMV_PAR01+"'  	AND "
		cChvTFL += " TFL.TFL_CONREV = '"+cRevCtr  +"'%"
	EndIf	
	
	// Populando campos para a apuração dos Materiais de implantação
	BeginSql Alias cAliasIMI
	
		SELECT TFS.TFS_CODIGO
		  FROM %table:TFS% TFS
		       JOIN %table:TFG% TFG ON TFG.TFG_FILIAL = %xFilial:TFG%
		                           AND TFS.TFS_CODTFG = TFG.TFG_COD
		                           AND %Exp:cWhereCob%
		                           AND TFG.%NotDel%
		       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                           AND TFF.TFF_COD = TFG.TFG_CODPAI
		                           AND TFF.%NotDel%	
	 	       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
	 	                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
	 	                           AND TFL.%NotDel%			
		 WHERE TFS.TFS_FILIAL = %xFilial:TFS%
		   AND RTrim(LTrim(TFS.TFS_ITAPUR)) = ' '
		   AND TFS.TFS_DTAPON >= %Exp:dDtIniApu%
		   AND TFS.TFS_DTAPON <= %Exp:dDtFimApu%
		   AND TFF.TFF_LOCAL IN %Exp:cLocal%
		   AND TFS.%NotDel%
		   AND %Exp:cChvTFL%						
	EndSql
	
	dbSelectArea("TFS")
	TFS->(dbSetOrder(1))
	
	While (cAliasIMI)->(!Eof())		
	
		If TFS->(dbSeek(xFilial("TFS")+(cAliasIMI)->TFS_CODIGO))
			Reclock("TFS",.F.)
			TFS->TFS_ITAPUR := oTFVMaster:GetValue("TFV_CODIGO")
			MsUnlock()				
		EndIf	
			
		(cAliasIMI)->(dbSkip())
		
	EndDo
	
	If lSrvExt
		cWhereCob := "%TFH.TFH_COBCTR = '2' AND TFH.TFH_PRCVEN > 0%" 
		cChvTFL   := "%TFL.TFL_CODPAI = '"+cCodTFJ+"'%"
	Else
		If lMedExt
			cWhereCob := "%TFH.TFH_COBCTR = '2' AND TFH.TFH_PRCVEN > 0%" 
		Else
			cWhereCob := "%TFH.TFH_COBCTR <> '2' %"
		EndIf
		cChvTFL := "%TFL.TFL_CONTRT = '"+cMV_PAR01+"'  	AND "
		cChvTFL += " TFL.TFL_CONREV = '"+cRevCtr  +"'%"
	EndIf	

	// Populando campos para a apuração dos Materiais de consumo
	BeginSql Alias cAliasIMC
		
		SELECT TFT.TFT_CODIGO
		  FROM %table:TFT% TFT
		       JOIN %table:TFH% TFH ON TFH.TFH_FILIAL = %xFilial:TFH% 
		                           AND TFT.TFT_CODTFH = TFH.TFH_COD
		                           AND %Exp:cWhereCob%				
		                           AND TFH.%NotDel%
		       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF% 
		                           AND TFF.TFF_COD = TFH.TFH_CODPAI 
		                           AND TFF.%NotDel%
	 	       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL% 
		                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI 
		                           AND TFL.%NotDel%						
		 WHERE TFT.TFT_FILIAL = %xFilial:TFT%
		   AND RTrim(LTrim(TFT.TFT_ITAPUR)) = ' '
		   AND TFT.TFT_DTAPON >= %Exp:dDtIniApu%
		   AND TFT.TFT_DTAPON <= %Exp:dDtFimApu%
		   AND %Exp:cChvTFL%
		   AND TFF.TFF_LOCAL IN %Exp:cLocal%
		   AND TFT.%NotDel%		
	
	EndSql
		
	DbSelectArea("TFT")
	TFT->( DbSetOrder( 1 ) )
	
	While (cAliasIMC)->(!Eof())		
	
		If TFT->(dbSeek(xFilial("TFT")+(cAliasIMC)->TFT_CODIGO))
			Reclock("TFT",.F.)
			TFT->TFT_ITAPUR := oTFVMaster:GetValue("TFV_CODIGO")
			MsUnlock()				
		EndIf	
		
		(cAliasIMC)->(dbSkip())
			
	EndDo

	// Populando campos para a apuração dos Equipamentos de Locação
	BeginSql Alias cAliasTEW
	
		SELECT TEW.TEW_FILIAL, TEW.TEW_CODMV, TEW.TEW_BAATD 
		  FROM %table:TEW% TEW
		       JOIN %table:TFI% TFI ON TFI.TFI_FILIAL = %xFilial:TFI%
		                           AND TFI.TFI_COD = TEW.TEW_CODEQU
		                           AND TFI.%NotDel%
		       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                           AND TFL.TFL_CODIGO = TFI.TFI_CODPAI
		                           AND %Exp:cChvTFL%
		                           AND TFL.%NotDel%	
		 WHERE TEW.TEW_FILIAL = %xFilial:TFT%
		   AND TEW.TEW_DTRINI <= %Exp:dDtFimApu%
		   AND ( (LTRIM(RTRIM(TEW.TEW_DTRFIM)) = ' ' OR TEW.TEW_DTRFIM >= %Exp:dDtIniApu%) AND
		         (LTRIM(RTRIM(TEW.TEW_DTAMNT)) = ' ' OR TEW.TEW_DTAMNT >= %Exp:dDtIniApu%) )
		   AND TEW.%NotDel%
	EndSql
	
	DbSelectArea("TEW")
	TEW->( DbSetOrder( 1 ) )
	
	While (cAliasTEW)->(!Eof())		
	
		If TEW->(dbSeek(xFilial("TEW")+(cAliasTEW)->TEW_CODMV))
			TEW->(Reclock("TEW",.F.))
			TEW->TEW_ITAPUR := oTFVMaster:GetValue("TFV_CODIGO")
			TEW->(MsUnlock())
		EndIf	
		
		//Atualiza o código da apuração/medição nas marcações do horimetro da base de atendimento (equipamento),
		//caso este tenha sido utilizado em sua apuração/medição.
		At970GvTFV((cAliasTEW)->TEW_BAATD, oTFVMaster:GetValue("TFV_CODIGO"))

		(cAliasTEW)->(dbSkip())	
			
	EndDo
	
	// Atualizando os grids com os dados de medição gerada pelo GCT
	//Atualizando itens da apuração do RH
	nVlrHora := 0					
	nVlrTot  := 0
	nPercHre := 0
	
	For nI := 1 To oModel:GetModel("TFWDETAIL"):Length() 
			
		oModel:GetModel("TFWDETAIL"):GoLine(nI)		
		//Atualizando a tabela de detalhes da apuração		
		aRetDet := At930QDetRH( oTFVMaster:GetValue("TFV_CONTRT"),;
								   oTFVMaster:GetValue("TFV_DTINI"),;
								   oTFVMaster:GetValue("TFV_DTFIM"),;
						          oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFF"),;
						          oModel:GetModel("TFWDETAIL"):GetValue("TFW_CODTFL"),; 
						          oTFVMaster:GetValue("TFV_CODIGO"),;
						          .F. )
						  
		For nX:=1 To Len(aRetDet[1])		
			For nY:=1 To Len(aRetDet[1][nX])					
				
				If !Empty(oModel:GetModel("TIPDETAIL"):GetValue("TIP_CODEQU")) .And. ;
					!Empty(oModel:GetModel("TIPDETAIL"):GetValue("TIP_CODTEC"))
					
					oModel:GetModel("TIPDETAIL"):AddLine()
				EndIf 				
				
				oModel:GetModel("TIPDETAIL"):SetValue("TIP_FILIAL", xFilial("TIP")		   )
				oModel:GetModel("TIPDETAIL"):SetValue("TIP_CODTEC", aRetDet[1][nX][nY][1])
				oModel:GetModel("TIPDETAIL"):SetValue("TIP_QTDE"  , aRetDet[1][nX][nY][3])
				oModel:GetModel("TIPDETAIL"):SetValue("TIP_VLRAPR", aRetDet[1][nX][nY][4])
				oModel:GetModel("TIPDETAIL"):SetValue("TIP_DTINI" , oTFVMaster:GetValue("TFV_DTINI"))
				oModel:GetModel("TIPDETAIL"):SetValue("TIP_DTFIM" , oTFVMaster:GetValue("TFV_DTFIM"))
				
				If nX == 2 
					
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_HEMOT", aRetDet[1][nX][nY][5])					
										
					nPercHre := aRetDet[1][nX][nY][4] / oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLHORE")					
					nVlrTot := oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLREXT") * nPercHre
					 
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_VLRMED", nVlrTot)
					
				Else 
					
					nVlrHora :=	oModel:GetModel("TFWDETAIL"):GetValue("TFW_VLRMED") / ;
								   	oModel:GetModel("TFWDETAIL"):GetValue("TFW_HORAN")
					
					nVlrTot := aRetDet[1][nX][nY][3] * nVlrHora	   	
								   	 						
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_VLRMED", nVlrTot) 
				EndIf 					
			
			Next		
		Next 
		
	Next nI
		
		
	//Atualizando itens de Locacao de Equipamento
	For xAux := 1 To oModel:GetModel("TFLDETAIL"):Length()
		oModel:GetModel("TFLDETAIL"):GoLine(xAux)

		nPosPlan := aScan( aMedGCT, { |x| x[1] == oModel:GetModel("TFLDETAIL"):GetValue("TFL_CODIGO") } )
		
		If nPosPlan > 0 
		
			For nJ := 1 To oModel:GetModel("TFIPRODUT"):Length()
				oModel:GetModel("TFIPRODUT"):GoLine(nJ)
				
				aRetDet  := At930QDetLE(oModel:GetModel("TFIPRODUT"):GetValue("TFI_COD"))
				nQtdBase := Len(aRetDet)				
									
				For nI := 1 To oModel:GetModel("TFZDETAIL"):Length()
					oModel:GetModel("TFZDETAIL"):GoLine(nI)		
			
					aAdd( aTEVUpdate, { oModel:GetModel("TFZDETAIL"):GetValue('TFZ_CODTFI'), ;
										oModel:GetModel("TFZDETAIL"):GetValue('TFZ_CODTEV'), ;
										oModel:GetModel("TFZDETAIL"):GetValue('TFZ_QTDAPU') } )
															
					If oModel:GetModel("TFZDETAIL"):GetValue("TFZ_MODCOB") == "2"
					
						For nX := 1 To nQtdBase							
							aRetDet[nX][4] := oModel:GetModel("TFZDETAIL"):GetValue("TFZ_VLRUNI") * aRetDet[nX][2]							
							aRetDet[nX][5] := oModel:GetModel("TFZDETAIL"):GetValue("TFZ_QTDAPU") * aRetDet[nX][7] 																					 
							aRetDet[nX][6] := oModel:GetModel("TFZDETAIL"):GetValue("TFZ_VLRUNI") * aRetDet[nX][5]														
						Next
					 
					Else
					
						For nX := 1 To nQtdBase
							
							aAdd( aRetDet, { aRetDet[nX][1],; 						    						// Base de atendimento  
								oModel:GetModel("TFZDETAIL"):GetValue("TFZ_QTDE")  ,; 						// Qtde prevista na apuracao								
								oModel:GetModel("TFZDETAIL"):GetValue("TFZ_MODCOB"),; 			  			// Modo de cobrança
								oModel:GetModel("TFZDETAIL"):GetValue("TFZ_VLRUNI") * ;
								oModel:GetModel("TFZDETAIL"):GetValue("TFZ_QTDE"),;   			  			// Valor apurado 
								oModel:GetModel("TFZDETAIL"):GetValue("TFZ_QTDAPU") * aRetDet[nX][7],; 	// Qtde medida								
								oModel:GetModel("TFZDETAIL"):GetValue("TFZ_VLRUNI") * ;
								(oModel:GetModel("TFZDETAIL"):GetValue("TFZ_QTDAPU") * aRetDet[nX][7]),; 	// Valor medido
								aRetDet[nX][7] } )																// Percentual do item equivalente a locação 
							
						Next 
					
					EndIf
					
				Next nI
				
				For nX:=1 To Len(aRetDet)		
					
					If !Empty(oModel:GetModel("TIPDETAIL"):GetValue("TIP_CODEQU")) .Or. ;
						!Empty(oModel:GetModel("TIPDETAIL"):GetValue("TIP_CODTEC"))
						
						oModel:GetModel("TIPDETAIL"):AddLine()
					EndIf
					 
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_FILIAL", xFilial("TIP")		  			 	)
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_DTINI" , oTFVMaster:GetValue("TFV_DTINI") 	)
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_DTFIM" , oTFVMaster:GetValue("TFV_DTFIM") 	)
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_CODEQU", aRetDet[nX][1]						)
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_QTDE"  , aRetDet[nX][2]						) 
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_HEMOT" , aRetDet[nX][3]						)	
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_VLRAPR", aRetDet[nX][4]						)
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_QTDMED", aRetDet[nX][5]						)			
					oModel:GetModel("TIPDETAIL"):SetValue("TIP_VLRMED", aRetDet[nX][6]						) 
				
				Next
			
			Next nJ
		
		EndIf	
				
	Next xAux
	
	//Atualiza o saldo dos registros da TEV
	DbSelectArea('TEV')
	TEV->(DbSetOrder(1))  // TEV_FILIAL+TEV_CODLOC+TEV_ITEM
	For nI := 1 To Len(aTEVUpdate)
	
		If TEV->(DbSeek(xFilial('TEV')+aTEVUpdate[nI,1]+aTEVUpdate[nI,2]))
			
			nJ := TEV->TEV_SLD - aTEVUpdate[nI,3]
			Reclock('TEV', .F.)
			TEV->TEV_SLD := nJ
			TEV->(MsUnlock())
			
		EndIf
	
	Next nI
	
EndIf

If lRet .AND. !Empty(cGrpCom)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³SIGATEC WorkFlow # ME - Inclusão da Medição de Contrato 	³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	At774Mail("TFJ",cGrpCom,"ME","<b>"+STR0096+"</b> "+cNumProp+"<b> "+STR0097+"</b>"+cNumCtr) //"Num. Proposta: " # "Nr. Contrato: "
Endif

_aComptc := {} //Reinicia a variavel apra não ter problemas em medições novas

If lRet
	nOpcDA  := 1
	nOpcHE	:= 1 
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930Est
	Estorno da medicao/apuracao dos itens gravados
@sample 	At930Est(oModel)
@author 	Serviços 
@since		19/11/2013       
@version	P11.90
@param  	oExp, Objeto, objeto do modelo de dados a ser gravado
@return  	lRet, Logico, status da gravação
/*/
//------------------------------------------------------------------------------
Function At930Est(oModel)

Local aOldArea	:= GetArea()
Local lRet			:= .T.
Local lExtMed		:= .F.
Local nCont
Local cCodRev		:= ""
Local cCodPln		:= ""
Local cCodTFJ		:= ""
Local cGrpCom		:= ""
Local nI
Local nJ
Local nK
Local nPos
Local cCodContrt 	:= ""
Local aCabMed		:= {}
Local aCabTot		:= {}
Local aIteMed		:= {}
Local aItem		:= {}
Local aPedApu		:= {}
Local aPedApuFS		:= {}
Local cAliasAB9	:= GetNextAlias()
Local cAliasIMI	:= GetNextAlias()
Local cAliasIMC	:= GetNextAlias()
Local cAliasTEW	:= GetNextAlias()
Local cAliasTGU	:= GetNextAlias()
Local cAliasTWQ	:= GetNextAlias()
Local oModelTFV := oModel:GetModel("TFVMASTER")
Local oModelTFW	:= oModel:GetModel("TFWDETAIL")
Local oModelTFX	:= oModel:GetModel("TFXDETAIL")
Local oModelTFY	:= oModel:GetModel("TFYDETAIL")
Local oModelTFZ	:= oModel:GetModel("TFZDETAIL")
Local oModelABX	
Local aTEVUpdate	:= {}
Local cCodApu		:= oModelTFV:GetValue("TFV_CODIGO")
//grupo de Faturamento
Local lGrpFatOrc:= .F.
Local cLocal := ""
Local bCond	 := {|| .T.}

Local dDtIniApu	:= oModelTFV:GetValue("TFV_DTINI")
Local dDtFimApu	:= oModelTFV:GetValue("TFV_DTFIM")

Private lMsErroAuto		:= .F.
Private lMsHelpAuto		:= .T.
Private lAutoErrNoFile	:= .F.

If !Empty(oModelTFV:GetValue("TFV_CONTRT"))
	TFJ->(dbSetOrder(5))
	bCond	 := {||  TFJ->(dbSeek(xFilial("TFJ")+oModelTFV:GetValue("TFV_CONTRT")+oModelTFV:GetValue("TFV_REVISA"))) }
Else
	TFJ->(dbSetOrder(1))
	bCond	 := {||  TFJ->(dbSeek(xFilial("TFJ")+oModelTFV:GetValue("TFV_ORCSRV"))) }
Endif

If lTeca934 
	oModelABX	:= oModel:GetModel("ABXDETAIL")
	dDtIniApu	:= oModelABX:GetValue("ABX_DTINAP")
	dDtFimApu	:= oModelABX:GetValue("ABX_DTFMAP")
EndIf

If Eval(bCond)

	dbSelectArea("TCV")
	TCV->(dbSetOrder(1))
	TCV->(dbSeek(xFilial("TCV")+cCodApu))
	
	While TCV->(!Eof()) .And. TCV->TCV_FILIAL == xFilial("TCV") .AND. TCV->TCV_NUMAPU == cCodApu
	
		If TCV->TCV_FATSEP = '1'
			aAdd(aPedApuFS	, TCV->TCV_NUMPED )
		Else
			aAdd(aPedApu , TCV->TCV_NUMPED )
		EndIf
		
		TCV->(dbSkip())
	EndDo
	
	lExtMed := (Len(aPedApu) > 0)
	
	// Estorno para a tabela de recursos humanos
	BeginSql Alias cAliasAB9
	
		SELECT AB9.AB9_FILIAL, AB9.AB9_NUMOS, AB9.AB9_CODTEC, AB9.AB9_SEQ
		  FROM %table:AB9% AB9
		  WHERE AB9.AB9_FILIAL = %xFilial:AB9%
		    AND AB9.AB9_ITAPUR = %Exp:cCodApu%
		    AND AB9.%NotDel%
	
	EndSql
	
	DbSelectArea("AB9")
	AB9->( DbSetOrder( 1 ) )
	
	While (cAliasAB9)->(!Eof())
		If AB9->(dbSeek(xFilial("AB9")+(cAliasAB9)->AB9_NUMOS+(cAliasAB9)->AB9_CODTEC+(cAliasAB9)->AB9_SEQ))
			Reclock("AB9",.F.)
			AB9->AB9_ITAPUR := ""
			MsUnlock()
		EndIf
		(cAliasAB9)->(dbSkip())
	EndDo
	
	// Estorno para a tabela de materiais de implantação
	BeginSql Alias cAliasIMI
	
		SELECT TFS.TFS_FILIAL, TFS.TFS_CODIGO
		  FROM %table:TFS% TFS
		 WHERE TFS.TFS_FILIAL = %xFilial:TFS%
		   AND TFS.TFS_ITAPUR = %Exp:cCodApu%
		   AND TFS.%NotDel%
	
	EndSql
	
	DbSelectArea("TFS")
	TFS->( DbSetOrder( 1 ) )
	
	While (cAliasIMI)->(!Eof())		
		If TFS->(dbSeek(xFilial("TFS")+(cAliasIMI)->TFS_CODIGO))
			Reclock("TFS",.F.)
			TFS->TFS_ITAPUR := ""
			MsUnlock()
		EndIf
		(cAliasIMI)->(dbSkip())
	EndDo
	
	// Estorno para a tabela de materiais de consumo	
	BeginSql Alias cAliasIMC
	
		SELECT TFT.TFT_FILIAL, TFT.TFT_CODIGO
		  FROM %table:TFT% TFT
		 WHERE TFT.TFT_FILIAL = %xFilial:TFT%
		   AND TFT.TFT_ITAPUR = %Exp:cCodApu%
		   AND TFT.%NotDel%
	
	EndSql
	
	DbSelectArea("TFT")
	TFT->( DbSetOrder( 1 ) )
	
	While (cAliasIMC)->(!Eof())
		If TFT->(dbSeek(xFilial("TFT")+(cAliasIMC)->TFT_CODIGO))
			Reclock("TFT",.F.)
			TFT->TFT_ITAPUR := ""
			MsUnlock()
		EndIf
		(cAliasIMC)->(dbSkip())
	EndDo
	
	// Estorno para a tabela de alocação de recursos
	BeginSql Alias cAliasTEW
	
		SELECT TEW.TEW_FILIAL, TEW.TEW_CODMV, TEW.TEW_BAATD
		  FROM %table:TEW% TEW
		 WHERE TEW.TEW_FILIAL = %xFilial:TEW%
		   AND TEW.TEW_ITAPUR = %Exp:cCodApu%
		   AND TEW.%NotDel%
	
	EndSql
	
	DbSelectArea("TEW")
	TEW->( DbSetOrder( 1 ) )
	
	While (cAliasTEW)->(! Eof())
		If TEW->(dbSeek(xFilial("TEW")+(cAliasTEW)->TEW_CODMV))
			Reclock("TEW",.F.)
			TEW->TEW_ITAPUR := ""
			MsUnlock()
		EndIf
		At970DlTFV((cAliasTEW)->TEW_BAATD, cCodApu)	// Estorna a efetivação da apuração das marcações do horimetro da base de atendimento, caso esta exista.
		(cAliasTEW)->(dbSkip())
	EndDo
	
	// Estorno para o apontamento de materiais 
	BeginSql Alias cAliasTGU
	
		SELECT TGU.TGU_COD, TGU.TGU_APURAC
		  FROM %table:TGU% TGU
		 WHERE TGU.TGU_FILIAL = %xFilial:TGU%
		   AND TGU.TGU_APURAC = %Exp:cCodApu%
		   AND TGU.%NotDel%
	
	EndSql
	
	DbSelectArea("TGU")
	TGU->( DbSetOrder( 2 ) )
	While (cAliasTGU)->(!Eof())
		If TGU->(dbSeek(xFilial("TGU")+(cAliasTGU)->TGU_COD))
			Reclock("TGU",.F.)
			TGU->TGU_APURAC := ""
			MsUnlock()
		EndIf
		(cAliasTGU)->(dbSkip())
	EndDo
	
	
	If lExtMed // Verifica se a medição fora do contrato
	
		For nI:=1 To Len(aPedApu)
		
			lMsErroAuto := .F.
			MSExecAuto({|x,y,z| Mata410(x,y,z)},{{"C5_NUM",aPedApu[nI],NIL}},{},5)
	
			If lMsErroAuto
				lRet := .F.
				If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
					Help(,,'AT930ERRMD3',,STR0080,1,0)   //"Ocorreu erro na exclusão do pedido de cobrança"
				Else
					MostraErro()
				EndIf
				Exit
			Else
	
				A930EstTWQ(lExtMed,oModelTFV:GetValue("TFV_ORCSRV"),"", aPedApu[nI], dDtIniApu, dDtFimApu)
			Endif
		
		Next nI
		
	Else
		lGrpFatOrc:= TFJ->TFJ_GRPFAT =="1"
		// Verificar a apuração dos itens do RH
		For nI := 1 To oModelTFW:Length()
	
			oModelTFW:GoLine(nI)
	
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFW:GetValue("TFW_MEDAD") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_CODPAI")
			cLocal	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_LOCAL")
			
			If nPos == 0 .And. !Empty(oModelTFW:GetValue("TFW_MEDAD"))
	
				If !lGrpFatOrc
					cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				Else
					At870GrPlan( TFJ->TFJ_CODGRP,cLocal , @cCodPln )
				EndIf
				
				aAdd( aCabMed, { "CND_NUMMED", oModelTFW:GetValue("TFW_MEDAD"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFW:GetValue("TFW_MEDAD") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFW:GetValue("TFW_MEDAD"), oModelTFW:GetValue("TFW_ITMAD") } )
				EndIf
	
			EndIf
			
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFW:GetValue("TFW_MEDHE") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_CODPAI")
			If nPos == 0 .And. !Empty(oModelTFW:GetValue("TFW_MEDHE"))
				
				A930EstTWQ(lExtMed,oModelTFV:GetValue("TFV_CONTRT"),oModelTFW:GetValue("TFW_MEDHE"), "", dDtIniApu, dDtFimApu)
	
				If !lGrpFatOrc
					cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				Else
					At870GrPlan( TFJ->TFJ_CODGRP,cLocal , @cCodPln )
				EndIf
				
				aAdd( aCabMed, { "CND_NUMMED", oModelTFW:GetValue("TFW_MEDHE"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFW:GetValue("TFW_MEDHE") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFW:GetValue("TFW_MEDHE"), oModelTFW:GetValue("TFW_ITMHE") } )
				EndIf
	
			EndIf
			
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFW:GetValue("TFW_MEDMC") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_CODPAI")
			If nPos == 0 .And. !Empty(oModelTFW:GetValue("TFW_MEDMC"))
	
				cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				aAdd( aCabMed, { "CND_NUMMED", oModelTFW:GetValue("TFW_MEDMC"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFW:GetValue("TFW_MEDMC") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFW:GetValue("TFW_MEDMC"), oModelTFW:GetValue("TFW_ITEMMC") } )
				EndIf
	
			EndIf
			
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFW:GetValue("TFW_MEDMI") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_CODPAI")
			If nPos == 0 .And. !Empty(oModelTFW:GetValue("TFW_MEDMI"))
	
				If !lGrpFatOrc
					cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				Else
					At870GrPlan( TFJ->TFJ_CODGRP,cLocal , @cCodPln )
				EndIf
				
				aAdd( aCabMed, { "CND_NUMMED", oModelTFW:GetValue("TFW_MEDMI"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFW:GetValue("TFW_MEDMI") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFW:GetValue("TFW_MEDMI"), oModelTFW:GetValue("TFW_ITEMMI") } )
				EndIf
	
			EndIf
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFW:GetValue("TFW_NUMMED") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_CODPAI")
			If nPos == 0 .And. !Empty(oModelTFW:GetValue("TFW_NUMMED"))
					
				A930EstTWQ(lExtMed,oModelTFV:GetValue("TFV_CONTRT"),oModelTFW:GetValue("TFW_NUMMED"), "", dDtIniApu, dDtFimApu)
	
				If !lGrpFatOrc
					cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				Else
					At870GrPlan( TFJ->TFJ_CODGRP,cLocal , @cCodPln )
				EndIf
				
				aAdd( aCabMed, { "CND_NUMMED", oModelTFW:GetValue("TFW_NUMMED"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFW:GetValue("TFW_NUMMED") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFW:GetValue("TFW_NUMMED"), oModelTFW:GetValue("TFW_ITMED") } )
				EndIf
	
			EndIf
	
		Next nI
	
		// Verificar a apuração dos materiais de implantação
		For nI := 1 To oModelTFX:Length()
	
			oModelTFX:GoLine(nI)
	
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFX:GetValue("TFX_NUMMED") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFX:GetValue("TFX_CODTFL"),"TFL_CODPAI")
			cLocal	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_LOCAL")
			If nPos == 0 .And. !Empty(oModelTFX:GetValue("TFX_NUMMED"))
	
				If !lGrpFatOrc
					cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				Else
					At870GrPlan( TFJ->TFJ_CODGRP,cLocal ,, @cCodPln )
				EndIf
				
				aAdd( aCabMed, { "CND_NUMMED", oModelTFX:GetValue("TFX_NUMMED"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFX:GetValue("TFX_NUMMED") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFX:GetValue("TFX_NUMMED"), oModelTFX:GetValue("TFX_ITMED") } )
				EndIf
	
			EndIf
	
		Next nI
		
		// Verificar a apuração dos materiais de consumo
		For nI := 1 To oModelTFY:Length()
	
			oModelTFY:GoLine(nI)
	
			nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFY:GetValue("TFY_NUMMED") })
			cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFY:GetValue("TFY_CODTFL"),"TFL_CODPAI")
			cLocal	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_LOCAL")
			
			If nPos == 0 .And. !Empty(oModelTFY:GetValue("TFY_NUMMED"))
	
				If !lGrpFatOrc
					cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
				Else
					At870GrPlan( TFJ->TFJ_CODGRP,cLocal ,,, @cCodPln )
				EndIf
				
				aAdd( aCabMed, { "CND_NUMMED", oModelTFY:GetValue("TFY_NUMMED"), cCodPln } )
	
				nPos := aScan(aIteMed,{ |x| x[1] == oModelTFY:GetValue("TFY_NUMMED") } )
				If nPos == 0
					aAdd( aIteMed, { oModelTFY:GetValue("TFY_NUMMED"), oModelTFY:GetValue("TFY_ITMED") } )
				EndIf
	
			EndIf
		Next nI
	
		// Verificar a apuração das alocações de equipamentos
		For nK := 1 To oModel:GetModel('TFLDETAIL'):Length()
			oModel:GetModel('TFLDETAIL'):GoLine(nK)
	
			For nJ := 1 To oModel:GetModel('TFIPRODUT'):Length()
				oModel:GetModel('TFIPRODUT'):GoLine(nJ)
	
				For nI := 1 To oModelTFZ:Length()
					oModelTFZ:GoLine(nI)
	
					aAdd( aTEVUpdate, { oModelTFZ:GetValue('TFZ_CODTFI'),oModelTFZ:GetValue('TFZ_CODTEV'), oModelTFZ:GetValue('TFZ_QTDAPU') } )
					nPos		:= aScan(aCabMed, {|x| x[2] == oModelTFZ:GetValue("TFZ_NUMMED") })
					cCodTFJ	:= Posicione("TFL",1,xFilial("TFL")+oModelTFZ:GetValue("TFZ_CODTFL"),"TFL_CODPAI")
					cLocal	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_LOCAL")
					If nPos == 0 .And. !Empty(oModelTFZ:GetValue("TFZ_NUMMED"))
					
						A930EstTWQ(lExtMed,oModelTFV:GetValue("TFV_CONTRT"),oModelTFZ:GetValue("TFZ_NUMMED"), "", dDtIniApu, dDtFimApu)
	
					If !lGrpFatOrc
						cCodPln	:= Posicione("TFL",1,xFilial("TFL")+oModelTFW:GetValue("TFW_CODTFL"),"TFL_PLAN")
					Else
						At870GrPlan( TFJ->TFJ_CODGRP,cLocal ,,,, @cCodPln )
					EndIf
						aAdd( aCabMed, { "CND_NUMMED", oModelTFZ:GetValue("TFZ_NUMMED"), cCodPln } )
	
						nPos := aScan(aIteMed,{ |x| x[1] == oModelTFZ:GetValue("TFZ_NUMMED") } )
						If nPos == 0
							aAdd( aIteMed, { oModelTFZ:GetValue("TFZ_NUMMED"), oModelTFZ:GetValue("TFZ_ITMED") } )
						EndIf
	
					EndIf
	
				Next nI
				
			Next nJ
			
		Next nK
		
		//Atualiza o saldo da tabela TEV (cobrança da locação de equipamentos)
		DbSelectArea('TEV')
		TEV->(DbSetOrder(1))  // TEV_FILIAL+TEV_CODLOC+TEV_ITEM
		For nI := 1 To Len(aTEVUpdate)
			If TEV->(DbSeek(xFilial('TEV')+aTEVUpdate[nI,1]+aTEVUpdate[nI,2]))
				nJ := TEV->TEV_SLD + aTEVUpdate[nI,3]
				Reclock('TEV', .F.)
				TEV->TEV_SLD := nJ
				TEV->(MsUnlock())
			EndIf
		Next nI
		
		// Estorno para o GCT
		If Len(aCabMed) > 0
				
			cCodContrt := oModelTFV:GetValue("TFV_CONTRT")
	
			For nI:=1 To Len(aCabMed)
				
				aCabTot := {}
				aItem   := {}
				
				aAdd( aCabTot, { aCabMed[nI][1], aCabMed[nI][2], NIL } )
				
				cCodRev := Posicione("CN9",7,xFilial("CN9")+cCodContrt+"05","CN9_REVISA")
	
				aAdd( aCabTot, { "CND_CONTRA", cCodContrt 		, NIL } )
				aAdd( aCabTot, { "CND_REVISA", cCodRev					 , NIL } )
				aAdd( aCabTot, { "CND_NUMERO", aCabMed[nI][3]			 , NIL } )
				
				nPos := aScan(aIteMed,{ |x| x[1] == aCabMed[nI][2] } )
				If nPos > 0
					aAdd( aItem, {} )
					aAdd( aItem[Len(aItem)], { "CNE_ITEM", Alltrim(aIteMed[nPos][2]), Nil } )
				EndIf
				// posiciona no cabeçalho da medição para garantir a execução da execauto para o registro certo
				CND->(DbSetOrder(1))	//CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED
				CND->(DbSeek(xFilial("CND")+cCodContrt+cCodRev+aCabMed[nI][3]+aCabMed[nI][2]))
	
				// Estorno da medição/apuração
				MsExecAuto({|a,b,c|, CNTA120(a,b,c)},aCabTot,aItem,7)
				If !LMsErroAuto
					lMsErroAuto:= .F.
					// Exclusão da medição/apuração
					MsExecAuto({|a,b,c|, CNTA120(a,b,c)},aCabTot,aItem,5)
					If lMsErroAuto
						lRet := .F.
						If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
							Help(,,'AT930ERRMD5',, STR0081,1,0) //'Ocorreu erro na exclusão da medição.'
						Else
							MostraErro()
						EndIf
					EndIf
				Else
					lRet:= .F.
					If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
						Help(,,'AT930ERRMD4',, STR0082,1,0) //'Ocorreu erro no estorno da medição.'
					Else
						MostraErro()
					EndIf
				EndIf
					
			Next nI
		EndIf
		
	EndIf
	
	// -------------------------------------------------
	// ESTORNO PARA PEDIDOS GERADOS PELO FATURA SEPARADO
	// -------------------------------------------------
	If lRet .And. Len(aPedApuFS) > 0
	
		For nI:=1 To Len(aPedApuFS)
		
			lMsErroAuto := .F.
			MSExecAuto({|x,y,z| Mata410(x,y,z)},{{"C5_NUM",aPedApuFS[nI],NIL}},{},5)
	
			If lMsErroAuto
				lRet := .F.
				If Empty(NomeAutoLog()) .OR. Empty(MemoRead(NomeAutoLog()))
					Help(,,'AT930ERRMD3',,STR0080,1,0)   //"Ocorreu erro na exclusão do 	 de cobrança"
				Else
					MostraErro()
				EndIf
				Exit
			Else
				If lExtMed
					A930EstTWQ(lExtMed,oModelTFV:GetValue("TFV_ORCSRV"),"", aPedApuFS[nI], dDtIniApu, dDtFimApu)
				Endif
			Endif
		Next nI	
	
	EndIf
		
	If lRet .AND. !Empty(cCodTFJ)
		cGrpCom := Posicione("TFJ",1,xFilial("TFJ")+cCodTFJ,"TFJ_GRPCOM")
		If !Empty(cGrpCom)
	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³SIGATEC WorkFlow # ME - Estorno da Medição de Contrato 	³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			At774Mail("TFJ",cGrpCom,"ME","<b>"+STR0096+"</b> "+TFJ->TFJ_PROPOS+"<b> "+STR0097+"</b>"+TFJ->TFJ_CONTRT,"RED",STR0098) //"Num. Proposta: " # "Nr. Contrato: " # "Estorno"
		Endif
	Endif
	
	(cAliasAB9)->(DbCloseArea())
	(cAliasIMI)->(DbCloseArea())
	(cAliasIMC)->(DbCloseArea())
	(cAliasTEW)->(DbCloseArea())
	(cAliasTGU)->(DbCloseArea())
Else
 //add help
 	Help(,,'AT930ERRMD7',,STR0157,1,0)   //"Contrato Ou Orçamento não encontrado"
 	lRet:= .F.
EndIf
RestArea(aOldArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930Compt
Tela de seleção da competência.
@sample 	At930Compt() 
@param		cContrato - Contrato
@param		cRevis - Revisão
@param		cNumPlan - Número da Planilha
@param		cLocal - Local x Orçamento que será selecionado a Competência
@return	ExpL	aRet - array com valores da competência e parcela
@since		22/11/2013
@author	Serviços       
@version	P11.9   
/*/
//------------------------------------------------------------------------------//

Static Function At930Compt(cContrato,cRevis,cNumPlan,cLocal)
Local oDlg			:= Nil
Local oOk			:= Nil
Local oBottom		:= Nil
Local oCombo		:= Nil
Local aAreaCNF		:= GetArea()
Local aCmboCmp		:= {}
Local cCmboCmp		:= ""
Local lVarCmpt  	:= IIf(Len(_aComptc)>0,.T.,.F.)
Local aRet			:= {}
Local cTitulo		:= STR0050 // "Seleção de Competência"
Local cAliasCNF		:= "CNF"
Local lRet			:= .F.
Local cQuery		:= ""
Local lOk			:= .F.
Local cCronog		:= ''
Local nTamCom		:= TamSX3("CNF_COMPET")[1]
Local nTamPar		:= TamSX3("CNF_PARCEL")[1]
Local cProxMed		:= ""
Local nPosProMed	:= 0
Local oView 		:= FwViewActive()
Local lTelas 		:= oView:IsActive() .And. oView:GetModel():GetId()=="TECA930"

If !lTeca934
	Pergunte("TEC930",.F.)
Else
	Pergunte("TEC934",.F.)
EndIf

If !HasMedEven( cContrato, cRevis )
	If At740Recor(cContrato)
		DbSelectArea(cAliasCNF)
		DbSetOrder(1)
		cAliasCNF	:= GetNextAlias()
		cQuery		:= "SELECT CNA_NUMERO, CNA_CONTRA, CNA_CRONOG, CNF_COMPET, CNF_PARCEL, CNF_SALDO " 
		cQuery		+=       " FROM " + RetSQLName("CNA") + " CNA "
		cQuery		+= " INNER JOIN " + RetSQLName("CNF") + " CNF "
		cQuery		+= " ON CNA.CNA_CRONOG = CNF.CNF_NUMERO "
		cQuery		+=      " AND CNA.CNA_FILIAL = CNF.CNF_FILIAL"
		cQuery		+= " WHERE CNA.CNA_FILIAL ='"+xFilial("CNA")+"'"
		cQuery		+=   " AND CNA.CNA_NUMERO ='"+cNumPlan+"'" 
		cQuery		+=   " AND CNA.CNA_CONTRA ='"+cContrato+"'"
		cQuery		+=   " AND CNA.CNA_REVISA ='"+cRevis+"'"
		cQuery		+=   " AND CNF.CNF_FILIAL ='"+xFilial("CNF")+"'"
		cQuery		+=   " AND CNF.CNF_CONTRA ='"+cContrato+"'"
		cQuery		+=   " AND CNF.CNF_REVISA ='"+cRevis+"'"
		cQuery      +=   " AND CNF_SALDO > 0 "
		cQuery      +=   " AND CNF_DTVENC >= '"+DTOS(MV_PAR02)+"'"
		cQuery		+=   " AND CNA.D_E_L_E_T_ = ' ' "
		cQuery		+=   " AND CNF.D_E_L_E_T_ = ' ' " 
		cQuery      +=   " ORDER BY CNF_PARCEL ,CNF_COMPET" 
		
		cQuery		:= ChangeQuery(cQuery)	
		DbUseArea(.T., "TOPCONN",TcGenQry(,,cQuery), cAliasCNF, .T., .T.)
		
		cCronog	:=	(cAliasCNF)->CNA_CRONOG
		
		While!(cAliasCNF)->(Eof()) 
			Aadd(aCmboCmp,(cAliasCNF)->CNF_COMPET+" "+(cAliasCNF)->CNF_PARCEL+"          R$ "+ALLTRIM(STR((cAliasCNF)->CNF_SALDO)))
			(cAliasCNF)->(DbSkip())
		EndDo
	Else
	
		BeginSQL Alias "CNATMP"
			SELECT CNA.CNA_PROMED
			FROM  %Table:CNA% CNA
			WHERE CNA.CNA_FILIAL = %xFilial:CNA% AND CNA.CNA_CONTRA = %Exp:cContrato% AND
													 CNA.CNA_REVISA = %Exp:cRevis% AND
													 CNA.CNA_NUMERO = %Exp:cNumPlan% AND
													 CNA.CNA_PERIOD <> ' ' AND CNA.%NotDel%
		EndSQL
	
		While !CNATMP->(EOF())
			cProxMed := Dtoc(Stod(CNATMP->CNA_PROMED))
			cProxMed := Substr(cProxMed,4)
			nPosProMed := aScan(aCmboCmp,{ |x| x == cProxMed })
			If nPosProMed == 0
				aAdd(aCmboCmp,cProxMed)
			Endif
			CNATMP->(dbSkip())
		EndDo
	     CNATMP->(dbCloseArea())
	Endif

	If (lVarCmpt)
		//For nCntCmpt := 1 To Len(aCmboCmp)
			If ( aScan(aCmboCmp, Substr(_aComptc[1][2],1,nTamCom)+" "+SubStr(_aComptc[1][2],nTamCom+2,nTamPar)) )
				lVarCmpt := .T.
			Else 
				lVarCmpt := .F.
			EndIf
		//Next nCntCmpt
	EndIf
	
	cLocInf := Posicione("TFL",1,xFilial("TFL")+cLocal,"TFL_LOCAL")
	
	If !(lVarCmpt) .and. lTelas
	
	//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
		Define MsDialog oDlg TITLE cTitulo FROM 000, 000 To 170, 250 Pixel	
			
		oOk:= LoadBitMap(GetResources(), "LBOK")
		@ 001,010 SAY STR0051 /*+ cLocal*/ OF oDlg PIXEL SIZE 120,9 // "Local x Orçamento:"
		@ 011,010 SAY cLocInf + " - " + Posicione("ABS",1,xFilial("ABS")+cLocInf,"ABS_DESCRI") OF oDlg PIXEL SIZE 120,9 // "Local x Orçamento:"
		@ 024,010 SAY STR0158 + " - " + cNumPlan OF oDlg PIXEL SIZE 120,9 // "Planilha"
		@ 035,010 SAY STR0052 OF oDlg PIXEL SIZE 80,9 // "Selecione a Competência:"
		@ 045,010 COMBOBOX oCombo   VAR cCmboCmp ITEMS aCmboCmp OF oDlg SIZE 100,10 PIXEL
		If (At930VldCr(cContrato, cRevis))
			@ 060,010 CheckBox oChkCmpt VAR lVarCmpt PROMPT STR0126 OF oDlg SIZE 120,10 PIXEL //STR0126 - "Utiliza mesma competência para todas?"
		EndIf
		@ 072,010 Button oOk Prompt STR0035  Of oDlg Size 60, 010 Pixel //"Ok"
		oOk:bAction := { || lOk := .T., oDlg:End() }
		
		Activate MsDialog oDlg Centered
	EndIf
	
	If !lTelas
		lOk := .T.
		cCmboCmp := aCmboCmp[1]
	EndIf
	
	If lOk 
		Aadd(aRet,{Substr(cCmboCmp,1,nTamCom),SubStr(cCmboCmp,nTamCom+2,nTamPar),cCronog})
		//verificar se utiliza a mesma competencia para os demais locais
		If (lVarCmpt)
			_aComptc := {}
			aAdd(_aComptc, {aRet, cCmboCmp})
		EndIf
		
	Else
		If (lVarCmpt)
			aRet := _aComptc[1][1]
		Else
			aRet := Nil
		EndIf
	EndIf
EndIf
RestArea(aAreaCNF)

Return aRet



//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930Commit()
Realiza a Gravação dos Dados utilizando o Model
@param ExpO:Modelo de Dados da Tela de cadastro
@return ExpL: Retorna .T. quando houve sucesso na Gravação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At930Commit(oModel)

Local lRetorno	:= .T.
Local lConfirm
Local nOperation	:= oModel:GetOperation()
Local lAt930Grv	:= .F.
Local oModTW6		:= oModel:GetModel('TFITW6DETAIL')
Local nX			:= 0
Local oView 		:= FwViewActive()
Local lTelas 		:= oView:IsActive() .And. oView:GetModel():GetId()=="TECA930"

If nOperation == 5					// Quando a operação for de estorno, questionará se realmente deseja realizar o estorno da apuração.

	If !IsBlind() .And. lTelas
		lConfirm:= MsgYesNo(STR0053) // "Deseja realmente estornar a Apuração?"
	Else
		lConfirm	:= .T.
	EndIf
		
	If lConfirm == .T.
	
		Begin Transaction

			If !(lRetorno := At930Est(oModel))
				DisarmTransacation()
			Else			
				FWModelActive(oModel)
				FWFormCommit(oModel)
			EndIf

		End Transaction
		
	EndIf
	
Else				//Senão for exclusão, não haverá questionamento.
	
	//Verifica ponto de entrada para continuar a gravação
	If ExistBlock("AT930GRV")
		lAt930Grv := ExecBlock("AT930GRV",.F.,.F.,{oModel})
	EndIf
	
	If !lAt930Grv
		Begin Transaction

			If lRetorno
				For nX := 1 To oModTW6:Length()
					oModTW6:GoLine(nX)
					If oModTW6:GetValue('TW6_VALOR') == 0
						oModTW6:DeleteLine()
					EndIf
				Next
			Endif

			If lRetorno .And. ( IsBlind() .Or. !lTelas )
				lRetorno := At930Grv(oModel)
			Else
				MsgRun( STR0074, STR0073, {|| lRetorno := At930Grv(oModel) } ) // 'Processando Apuração  ' #### 'Aguarde...'
			EndIf

			If (!lRetorno)
				DisarmTransacation()
			Else			
				FWModelActive( oModel )
				If !IsBlind() .And. lTelas
					MsgRun( STR0075, STR0073, {|| lRetorno := FWFormCommit( oModel ) } ) // 'Gerando Medição' #### 'Aguarde...'
					MsgInfo(STR0049) // "Apuração/Medição efetuada com sucesso."
				Else
					lRetorno := FWFormCommit( oModel )	
				EndIf
			EndIf

			If lRetorno
				While GetSX8Len() > nLenSX8
					RollBackSX8()
				End
			Else
				While GetSX8Len() > nLenSX8
					ConfirmSX8()
				End
			EndIf

		End Transaction
	EndIf
EndIf

Return( lRetorno )


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930IniEst()
Atualiza as informações das listas, quando for executado o estorno.
@param 		ExpN:Numero da aba qual deseja carregar os dados
@param 		ExpC:Campo qual deseja atribuir o valor
@author 	Serviços 
@since  	16/12/2013
@version	P11.9 
@return 	Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At930IniEst(nAba, cCampo)

Local uRet		  := ""
Local cCodTFF   := ""
Local cCodTFG	:= ""
Local cCodTFH	:= ""
Local cCodTFL   := ""
Local cCodTFI   := ""
Local cAliasTFZ := GetNextAlias()
Local cCodApu   := ""
Local nVlrTot   := 0

Do Case
	Case nAba == 1 ; cCodTFF := TFW->TFW_CODTFF ; cCodTFL := TFW->TFW_CODTFL
	Case nAba == 2 ; cCodTFG := TFX->TFX_CODTFG ; cCodTFL := TFX->TFX_CODTFL
	Case nAba == 3 ; cCodTFH := TFY->TFY_CODTFH ; cCodTFL := TFY->TFY_CODTFL
EndCase

If !INCLUI
	
	If Right(cCampo,6) == "PRODUT" .Or. Right(cCampo,6) == "DSCPRO"
		If nAba == 1
			dbSelectArea("TFF")
			TFF->(dbSetOrder(1)) // TFF_FILIAL + TFF_COD
			
			If TFF->(dbSeek(xFilial("TFF")+cCodTFF))
				If Right(cCampo,6) == "PRODUT"
					uRet := TFF->TFF_PRODUT
				Else
					uRet := Posicione("SB1",1,xFilial("SB1")+TFF->TFF_PRODUT,"B1_DESC")
				EndIf
			EndIf
		Elseif nAba == 2
			dbSelectArea("TFG")
			TFG->(dbSetOrder(1)) // TFG_FILIAL + TFG_COD
		
			If TFG->(dbSeek(xFilial("TFG")+cCodTFG))
				If Right(cCampo,6) == "PRODUT"
					uRet := TFG->TFG_PRODUT
				Else
					uRet := Posicione("SB1",1,xFilial("SB1")+TFG->TFG_PRODUT,"B1_DESC")
				EndIf
			EndIf
		Elseif nAba == 3
			dbSelectArea("TFH")
			TFH->(dbSetOrder(1)) // TFH_FILIAL + TFH_COD
	
			If TFH->(dbSeek(xFilial("TFH")+cCodTFH))
				If Right(cCampo,6) == "PRODUT"
					uRet := TFH->TFH_PRODUT
				Else
					uRet := Posicione("SB1",1,xFilial("SB1")+TFH->TFH_PRODUT,"B1_DESC")
				EndIf
			EndIf
		Endif
	ElseIf Right(cCampo,5) == "LOCAL" .Or. Right(cCampo,6) == "DESCRI"
		
		dbSelectArea("TFL")
		TFL->(dbSetOrder(1))
		
		If TFL->(dbSeek(xFilial("TFL")+cCodTFL))
			If Right(cCampo,5) == "LOCAL"
				uRet := TFL->TFL_LOCAL
			Else
				uRet := Posicione("ABS",1,xFilial("ABS")+TFL->TFL_LOCAL,"ABS_DESCRI")
			EndIf
		EndIf
		
	ElseIf cCampo == "TFZ_QTDE"
		
		dbSelectArea("TFI")
		TFI->(dbSetOrder(1))
		
		If TFI->(dbSeek(xFilial("TFI")+TFZ->TFZ_CODTFI))
			dbSelectArea("TEV")
			TEV->(dbSetOrder(1))
			If TEV->(dbSeek(xFilial("TEV")+TFZ->TFZ_CODTFI+TFZ->TFZ_CODTEV))
				If	TEV->TEV_MODCOB == "4"	//1=Uso;2=Disponibilidade;3=Mobilizacao;4=Horas;5=Franquia/Excedente
					uRet := 0
				Else
					uRet := getVlrProp(	TFI->TFI_PERINI, TFI->TFI_PERFIM,;
									   	TEV->TEV_QTDE, TFV->TFV_DTINI, TFV->TFV_DTFIM , , , , , TFI->TFI_QTDVEN, TFV->TFV_CONTRT )
				EndIf
			EndIf
		EndIf
			
		ElseIf 	cCampo == "TFL_DISP" .Or. cCampo == "TFL_USO" .Or. ;
				cCampo == "TFL_MOBILI" .Or. cCampo == "TFL_VALTOT" .OR. ;
				cCampo == "TFI_DISP" .Or. cCampo == "TFI_USO" .Or. cCampo == "TFI_MOBILI"
			
			cCodApu := TFV->TFV_CODIGO
			
			If Left(cCampo,3) == "TFI"
				cCodTFL := TFI->TFI_CODPAI
				If !Empty(TFI->TFI_CODPAI)
					cCodTFI := "%TFZ.TFZ_CODTFI = " + TFI->TFI_COD + " AND %"
				Else
					cCodTFI := "% %"
				EndIf
			Else
				cCodTFL := TFL->TFL_CODIGO
				cCodTFI := "% %"
			EndIf
			
			BeginSql Alias cAliasTFZ
				
				SELECT TFZ.TFZ_APURAC, TFZ.TFZ_CODTFL, TFZ.TFZ_MODCOB, SUM(TFZ.TFZ_TOTAL) AS TOTAL
				FROM %table:TFZ% TFZ
				WHERE TFZ.TFZ_FILIAL = %xFilial:TFZ%
				AND TFZ.TFZ_APURAC = %Exp:cCodApu%
				AND TFZ.TFZ_CODTFL = %Exp:cCodTFL%
				AND %Exp:cCodTFI%
				TFZ.%NotDel%
				GROUP BY TFZ.TFZ_APURAC, TFZ.TFZ_CODTFL, TFZ.TFZ_MODCOB
				
			EndSql
			
			While (cAliasTFZ)->(!Eof())
				
				If cCampo <> "TFL_VALTOT"
					If ( (cAliasTFZ)->TFZ_MODCOB == "1" .OR. (cAliasTFZ)->TFZ_MODCOB == "4" ) .And. Right(cCampo,3) == "USO"		//1=Uso;2=Disponibilidade;3=Mobilizacao;4=Horimetro
						uRet := (cAliasTFZ)->TOTAL
					ElseIf (cAliasTFZ)->TFZ_MODCOB == "2" .And. Right(cCampo,4) == "DISP"		//1=Uso;2=Disponibilidade;3=Mobilizacao;4=Horimetro
						uRet := (cAliasTFZ)->TOTAL
					ElseIf (cAliasTFZ)->TFZ_MODCOB == "3" .And. Right(cCampo,6) == "MOBILI"		//1=Uso;2=Disponibilidade;3=Mobilizacao;4=Horimetro
						uRet := (cAliasTFZ)->TOTAL
					EndIf
					
					If ! Empty(uRet)
						Exit
					EndIf
				Else
					nVlrTot += (cAliasTFZ)->TOTAL
				EndIf
				
				(cAliasTFZ)->(dbSkip())
				
		End
			
		(cAliasTFZ)->(DbCloseArea())
			
			If cCampo == "TFL_VALTOT"
				uRet := nVlrTot
			EndIf
			
		ElseIf cCampo == "TFW_TOTHOR" // Total apurado RH
			uRet := TFW->TFW_HORAN + TFW->TFW_HORAE
		ElseIf cCampo == "TFW_VLRTOT" // Total RH
			uRet := TFW->TFW_VLRMED + TFW->TFW_VLREXT + TFW->TFW_TOTMUL + TFW->TFW_VLMTMI + TFW->TFW_VLMTMC - TFW->TFW_TOTBON - TFW->TFW_TOTDES 
		EndIf		

Endif

Return(uRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  HasMedEven()
	Pesquisa se um determinado contrato possui configuração para receber medição eventual

@param 		ExpC:Código do contrato
@param 		ExpC:Sequência da Revisão

@author 	Serviços 
@since  	07/01/2014
@version	P11.9 
@return 	ExpL:possui(.T.) ou não (.F.) medição eventual configurada
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function HasMedEven( cCtr, cRev )

Local lRet			:= .F.
Local aSave		:= GetArea()
Local aSaveCN9	:= CN9->(GetArea())
Local aSaveCN1	:= CN1->(GetArea())

DbSelectArea('CN9')
CN9->( DbSetOrder( 1 ) ) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA

DbSelectArea('CN1')
CN1->( DbSetOrder( 1 ) ) // CN1_FILIAL+CN1_CODIGO+CN1_ESPCTR

If CN9->( DbSeek( xFilial('CN9')+cCtr+cRev ) ) .And. ;  // procura contrato
	CN1->( DbSeek( xFilial('CN1')+CN9->CN9_TPCTO + '2' ) ) .And. ;  // procura o tipo do contrato
	CN1->CN1_MEDEVE == '1' // possui medição eventual configurada

	lRet := .T.

EndIf

RestArea(aSaveCN1)
RestArea(aSaveCN9)
RestArea(aSave)

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930VldSld()

Verifica se o saldo da medição do contrato, esta dentro do limite do cronograma financeiro.

@param 		ExpC:Contrato a ser utilzado na medicao
@param 		ExpC:Revisão do contrato a ser utilzado na medicao
@param 		ExpC:Cronograma financeiro do contrato a ser utilzado na medicao
@param 		ExpC:Competencia do contrato a ser utilzado na medicao
@param 		ExpN:Valor total da medição a ser consistido
@param 		ExpC:Indica o tipo de geração de excedentes selecionado pelo usuário na medição
@param 		ExpN:Valor total das horas extras

@author 	Serviços 
@since  	07/01/2014
@version	P11.9 
@return 	Nil
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At930VldSld(cContrato, cRevisao, cCronog, cComp, nValMed, cOpcHE, nVlrTotHE,  nVlrDesc,  nVlrMulta,  nVlrBoni, cParcela, nRet)

Local lRet    := .F.
Local nLimMed := 0
Local cSeek   := ''
Local aArea   := GetArea()

Default cOpcHE 	:= "1" // por padrão considera normal+hora extra dentro do limite do contrato
Default nVlrTotHE 	:= 0
Default cParcela   := ''
Default nRet		:= 0

CN9->(dbSetOrder(1))

If CN9->(dbSeek(xFilial("CN9")+cContrato+cRevisao))
	
	dbSelectArea("CN1")
	CN1->(dbSetOrder(1))
	
	If CN1->(dbSeek(xFilial("CN1")+CN9->CN9_TPCTO))
	
		nLimMed := CN1->CN1_LMTMED
		
		dbSelectArea("CNF")
		CNF->(dbSetOrder(2))
		CNF->(dbSeek(cSeek := xFilial("CNF") + cContrato + cRevisao + cCronog + cComp))
		Do While CNF->(! Eof()) .And. cSeek == CNF->(CNF_FILIAL + CNF_CONTRA + CNF_REVISA + CNF_NUMERO + CNF_COMPET)
			If AllTrim(CNF_PARCEL) == AllTrim(cParcela) //Pesquisa a parcela Selecionada para Medicao
				If cOpcHE == "2" // caso HE seja cobrada como excedente da medição
					nValMed -= nVlrTotHE
				EndIf
				lRet := ((CNF->CNF_SALDO+((CNF->CNF_VLPREV*nLimMed)/100)) >= nValMed - nVlrDesc +  nVlrMulta - nVlrBoni)
				If !lRet
					nRet := (CNF->CNF_SALDO+((CNF->CNF_VLPREV*nLimMed)/100))
				EndIf
				Exit
			EndIf
			CNF->(dbSkip())
		EndDo
			 
	EndIf
	
EndIf
	
RestArea(aArea)
	
Return(lRet)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930QDetRH()
Gera as informações do detalhes de horas apuradas do RH.
@param 		ExpC:Contrato a ser utilzado no detalhe
@param 		ExpC:Data Inicial da apuração/medição
@param 		ExpC:Data Final da apuração/medição
@param 		ExpC:Codigo do recurso humano a ser utilizado no detalhe
@param 		ExpC:Codigo do local a ser utilizado no detalhe
@param 		ExpC:Codigo da apuração para a pesquisa no estorno
@param 		ExpL:Para identificar se vai ser retornado dados para a tela ou processamento
@author 	Serviços 
@since  	13/02/2014
@version	P12 
@return 	ExpA: Array com os dados do detalhe do RH
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At930QDetRH(cContrato, cDataIni, cDataFim, cCodTFF, cCodTFL, cIdApur, lTela)

Local aRet			:= {}
Local aHrNormal	:= {}
Local aTecHrN		:= {}
Local aHrExtra	:= {}
Local aTecHrE		:= {}
Local aHrOsE		:= {}
Local cHora		:= ""
Local cMinutos	:= "" 
Local cMod			:= ""
Local cIdcABQ		:= ""
Local cWhereCob	:= ""
Local nPos			:= 0
Local nVlrTot		:= 0
Local nHreTot		:= 0
Local nTecHor		:= 0
Local nValTot		:= 0 
Local cAliasAB9	:= GetNextAlias()
Local cAliasABR	:= GetNextAlias()
Local cRevCtr		:= Posicione("CN9",7,xFilial("CN9")+cContrato+"05","CN9_REVISA")
Local cOperConc	:= if(Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX","||","+")
Local cOperador	:= "%" + cOperConc + "%"
Local lFilTFF		:= FindFunction("ExistFilTFF") .And. ExistFilTFF()
Local nVlrCont	:= 0
Local nVlrHor		:= 0
Local nHorTot		:= 0
Local cChvTFL   := ""
Local cCodTFJ   := AllTrim(MV_PAR05)

Default cIdApur := ""
Default lTela   := .T.

If Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX"	
			
	//Calculo para horas
	cHora    := "(SUM(CAST(SUBSTR(ABR.ABR_TEMPO,1,2) AS INTEGER)) * 60)"
	
	//Calculo para minutos
	cMinutos := "SUM(CAST(SUBSTR(ABR.ABR_TEMPO,4,2) AS INTEGER))" 
	
	If Trim(Upper(TcGetDb())) $ "POSTGRES"	
		cMod := "%SUBSTR( Concat( '00', Cast((" + cHora + "+" + cMinutos + ") / 60 as VarChar(2))),4,2)"
		cMod += " || ':' || "
		cMod += "SUBSTR( Concat( '00', Cast(mod(CAST((" + cHora + "+" + cMinutos + ") AS NUMERIC) , 60) as VarChar(2))),4,2)%"
 	Else
		cMod := "%SUBSTR( Concat( '00', Cast((" + cHora + "+" + cMinutos + ") / 60 as VarChar(2))),4,2)"
		cMod += " || ':' || "
		cMod += "SUBSTR( Concat( '00', Cast(Mod((" + cHora + "+" + cMinutos + "), 60) as VarChar(2))),4,2)%" 
	EndIf

Else

	//Calculo para horas
	cHora := "( Sum(datepart(hh,convert(varchar,ABR.ABR_TEMPO,108))) * 60 + " 
	cHora += "Sum(datepart(mi,convert(varchar,ABR.ABR_TEMPO,108))) ) / 60"
	
	//Calculos para os minutos
	cMinutos := "( Sum(datepart(hh,convert(varchar,ABR.ABR_TEMPO,108))) * 60 + " 
	cMinutos += "Sum(datepart(mi,convert(varchar,ABR.ABR_TEMPO,108))) ) % 60"

	//Horas formatadas
	cMod := "%Replicate('0', 2 - DataLength(LTrim(RTrim(Convert(Varchar, " + cHora + " ))))) + "
	cMod += "Convert(Varchar," + cHora + ") + ':' + "
 	cMod += "Replicate('0', 2 - DataLength(Ltrim(Rtrim(Convert(Varchar, " + cMinutos + "))))) + " 
	cMod += "Convert(Varchar," + cMinutos + ")%"
	   
EndIF	

cIdcABQ := "%ABQ.ABQ_CONTRT" + cOperConc + "ABQ.ABQ_ITEM" + cOperConc + "ABQ.ABQ_ORIGEM%"

If lSrvExt
	cWhereCob := "%TFF.TFF_COBCTR = '2' AND TFF.TFF_PRCVEN > 0%" 
	cChvTFL   := "%TFL.TFL_CODPAI = '" + cCodTFJ + "'%"
Else
	If lMedExt
		cWhereCob := "%TFF.TFF_COBCTR = '2' AND TFF.TFF_PRCVEN > 0%" 
	Else	 
	 	cWhereCob := "%TFF.TFF_COBCTR <> '2' %"
	EndIf
	cChvTFL := "%TFL.TFL_CONTRT = '"+cContrato+"' AND "
	cChvTFL += " TFL.TFL_CONREV = '"+cRevCtr+"'%"
EndIf

// Aba detalhes Recursos Humanos - Horas Normais
IF !lFilTFF
	BeginSql Alias cAliasAB9
		
		SELECT AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG,
		       AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		       TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		       TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN
	  	  FROM %table:ABB% ABB
		       JOIN %table:AB9% AB9 ON AB9.AB9_FILIAL = %xFilial:AB9%
		                           AND AB9.AB9_ATAUT = ABB.ABB_CODIGO
		                           AND AB9.AB9_NUMOS = ABB.ABB_CHAVE
		                           AND RTrim(LTrim(AB9.AB9_ITAPUR))=%Exp:cIdApur%
		                           AND AB9.%NotDel%	
		       JOIN %table:AB7% AB7 ON AB7.AB7_FILIAL = %xFilial:AB7%
		                           AND AB7.AB7_NUMOS %Exp:cOperador% AB7.AB7_ITEM = AB9.AB9_NUMOS
		                           AND AB7.%NotDel% 
		       JOIN %table:AB6% AB6 ON AB6.AB6_FILIAL = %xFilial:AB6%
		                           AND AB6.AB6_NUMOS = AB7.AB7_NUMOS
		                           AND AB6.%NotDel% 
		       JOIN %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
		                           AND ABB.ABB_IDCFAL = %Exp:cIdcABQ%
		                           AND ABQ.%NotDel%
		       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                           AND TFF.TFF_COD = ABQ.ABQ_CODTFF
		                           AND TFF.TFF_COD = %Exp:cCodTFF%
		                           AND %Exp:cWhereCob%
		                           AND TFF.%NotDel%
		       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
		                           AND TFL.TFL_CODIGO = %Exp:cCodTFL%
		                           AND %Exp:cChvTFL%
		                           AND TFL.%NotDel% 
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
		                                AND ABS.%NotDel%
		       LEFT JOIN %table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
		                                AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
		                                AND AA1.%NotDel%
		 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
		   AND ABB.ABB_CHEGOU = 'S'
		   AND ABB.ABB_ATENDE = '1'
		   AND ABB.ABB_DTINI >= %Exp:cDataIni%
		   AND ABB.ABB_DTINI <= %Exp:cDataFim%
		   AND ABB.ABB_DTFIM >= %Exp:cDataIni%
		   AND ABB.ABB_DTFIM <= %Exp:cDataFim%
		   AND ABQ.ABQ_CONTRT = %Exp:cContrato%
		   AND ABB.%NotDel%  	 
		 GROUP BY AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG,
		          AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		          TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		          TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN
		ORDER BY ABB.ABB_CODTEC, AB9.AB9_DTCHEG,AB9.AB9_HRCHEG,AB9.AB9_DTSAID, AB9.AB9_HRSAID

	EndSql  
ELSE
	BeginSql Alias cAliasAB9
		
		SELECT AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG,
		       AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		       TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		       TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN
		  FROM %table:ABB% ABB
		       JOIN %table:AB9% AB9 ON AB9.AB9_FILIAL = %xFilial:AB9%
		                           AND AB9.AB9_ATAUT = ABB.ABB_CODIGO
		                           AND AB9.AB9_NUMOS = ABB.ABB_CHAVE
		                           AND RTrim(LTrim(AB9.AB9_ITAPUR))=%Exp:cIdApur%
		                           AND AB9.%NotDel%	
		       JOIN %table:AB7% AB7 ON AB7.AB7_FILIAL = %xFilial:AB7%
		                           AND AB7.AB7_NUMOS %Exp:cOperador% AB7.AB7_ITEM = AB9.AB9_NUMOS
		                           AND AB7.%NotDel% 
		       JOIN %table:AB6% AB6 ON AB6.AB6_FILIAL = %xFilial:AB6%
		                           AND AB6.AB6_NUMOS = AB7.AB7_NUMOS
		                           AND AB6.%NotDel% 
	  	       JOIN %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
	  	                           AND ABB.ABB_IDCFAL = %Exp:cIdcABQ%
	  	                           AND ABQ.%NotDel%
		       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                           AND TFF.TFF_FILIAL = ABQ.ABQ_FILTFF
		                           AND TFF.TFF_COD = ABQ.ABQ_CODTFF
		                           AND TFF.TFF_COD = %Exp:cCodTFF%
		                           AND %Exp:cWhereCob%
		                           AND TFF.%NotDel%
		       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
		                           AND TFL.TFL_CODIGO = %Exp:cCodTFL%
		                           AND %Exp:cChvTFL%
		                           AND TFL.%NotDel% 
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
		                                AND ABS.%NotDel%
		       LEFT JOIN %table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
		                                AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
		                                AND AA1.%NotDel%
		 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
		   AND ABB.ABB_CHEGOU = 'S'
		   AND ABB.ABB_ATENDE = '1'
		   AND ABB.ABB_DTINI >= %Exp:cDataIni%
		   AND ABB.ABB_DTINI <= %Exp:cDataFim%
		   AND ABB.ABB_DTFIM >= %Exp:cDataIni%
		   AND ABB.ABB_DTFIM <= %Exp:cDataFim%
		   AND ABQ.ABQ_CONTRT = %Exp:cContrato%
		   AND ABB.%NotDel%  	 
		 GROUP BY AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG,
		          AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		          TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		          TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN
		 ORDER BY ABB.ABB_CODTEC, AB9.AB9_DTCHEG,AB9.AB9_HRCHEG,AB9.AB9_DTSAID, AB9.AB9_HRSAID

	EndSql
ENDIF

While (cAliasAB9)->(!Eof())		

	IF lTela 
	
		aAdd( aHrNormal, { (cAliasAB9)->AB9_NUMOS		,	(cAliasAB9)->AB9_SEQ,;
						   (cAliasAB9)->AB9_TOTFAT		,	StoD((cAliasAB9)->AB6_EMISSA),;
						   StoD((cAliasAB9)->AB9_DTCHEG),	(cAliasAB9)->AB9_HRCHEG,  ;
						   StoD((cAliasAB9)->AB9_DTSAID),	(cAliasAB9)->AB9_HRSAID,;
						   (cAliasAB9)->TFF_CONTRT		,	(cAliasAB9)->TFF_CONREV,; 
						   (cAliasAB9)->TFF_LOCAL		,	(cAliasAB9)->ABS_DESCRI,;
						   (cAliasAB9)->ABB_CODTEC		,	(cAliasAB9)->AA1_NOMTEC })
						    
	Else						   
			
		nVlrCont := ((cAliasAB9)->TFF_PRCVEN - (cAliasAB9)->TFF_VALDES) * (cAliasAB9)->TFF_QTDVEN  
		nVlrHor  := nVlrCont / (cAliasAB9)->ABQ_TOTAL   
		nHorTot  := HoraToInt((cAliasAB9)->AB9_TOTFAT) * nVlrHor
		
		nPos := aScan( aTecHrN, {|x| x[1] == (cAliasAB9)->ABB_CODTEC } )
	
		If nPos == 0		
			aAdd( aTecHrN, { (cAliasAB9)->ABB_CODTEC, nVlrHor, HoraToInt((cAliasAB9)->AB9_TOTFAT), nHorTot } )		
		Else
		
			nTecHor := aTecHrN[nPos][3] + HoraToInt((cAliasAB9)->AB9_TOTFAT)
			nValTot := aTecHrN[nPos][4] + nHorTot
			
			aTecHrN[nPos][3] := nTecHor
			aTecHrN[nPos][4] := nValTot		
			 	
		EndIf
		
	EndIf	
							   	
	(cAliasAB9)->(dbSkip())
	
EndDo

// Aba detalhes Recursos Humanos - Horas Extras
IF !lFilTFF

	BeginSql Alias cAliasABR
		
		SELECT AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG, 
		       AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		       TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		       TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN, ABR.ABR_MOTIVO, ABN.ABN_DESC, 
		       TFU.TFU_CODIGO, TFU.TFU_VALOR, %Exp:cMod% TOT_HOR							 					 
		  FROM %table:ABB% ABB
		       JOIN %table:AB9% AB9 ON AB9.AB9_FILIAL = %xFilial:AB9%
		                           AND AB9.AB9_ATAUT = ABB.ABB_CODIGO
		                           AND AB9.AB9_NUMOS = ABB.ABB_CHAVE
		                           AND RTrim(LTrim(AB9.AB9_ITAPUR))=%Exp:cIdApur%
		                           AND AB9.%NotDel%		
		       JOIN %table:AB7% AB7 ON AB7.AB7_FILIAL = %xFilial:AB7%
		                           AND AB7.AB7_NUMOS %Exp:cOperador% AB7.AB7_ITEM = AB9.AB9_NUMOS
		                           AND AB7.%NotDel% 
		       JOIN %table:AB6% AB6 ON AB6.AB6_FILIAL = %xFilial:AB6%
		                           AND AB6.AB6_NUMOS = AB7.AB7_NUMOS
		                           AND AB6.%NotDel% 
	  	       JOIN %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
	  	                           AND ABB.ABB_IDCFAL = %Exp:cIdcABQ%
	  	                           AND ABQ.%NotDel%		
		       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                           AND TFF.TFF_COD = ABQ.ABQ_CODTFF
		                           AND TFF.TFF_COD = %Exp:cCodTFF%
		                           AND %Exp:cWhereCob%
		                           AND TFF.%NotDel%
		       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
		                           AND TFL.TFL_CODIGO = %Exp:cCodTFL%
		                           AND %Exp:cChvTFL%
		                           AND TFL.%NotDel%
		       JOIN %table:ABR% ABR ON ABR.ABR_FILIAL = %xFilial:ABR%
		                           AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
		                           AND ABR.ABR_DTINI >= %Exp:cDataIni%
		                           AND ABR.ABR_DTFIM <= %Exp:cDataFim%
		                           AND ABR.%NotDel% 
		       JOIN %table:ABN% ABN ON ABN.ABN_FILIAL = %xFilial:ABN%
		                           AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO
		                           AND ABN.ABN_TIPO = '04'
		                           AND ABN.%NotDel%
		       LEFT JOIN %table:TFU% TFU ON TFU.TFU_FILIAL = %xFilial:TFU%
		                                AND TFU.TFU_CODTFF = TFF.TFF_COD
		                                AND TFU.TFU_CODABN = ABR.ABR_MOTIVO
		                                AND TFU.%NotDel% 
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
		                                AND ABS.%NotDel%
		       LEFT JOIN %table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
		                                AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
		                                AND AA1.%NotDel%
		 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
		   AND ABB.ABB_CHEGOU = 'S'
		   AND ABB.ABB_ATENDE = '1'
		   AND ABB.ABB_DTINI >= %Exp:cDataIni%
		   AND ABB.ABB_DTINI <= %Exp:cDataFim%
		   AND ABB.ABB_DTFIM >= %Exp:cDataIni%
		   AND ABB.ABB_DTFIM <= %Exp:cDataFim%
		   AND ABQ.ABQ_CONTRT = %Exp:cContrato%
		   AND ABB.%NotDel%	
		 GROUP BY AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG, 
		          AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		          TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		          TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN, ABR.ABR_MOTIVO, ABN.ABN_DESC, 
		          TFU.TFU_CODIGO, TFU.TFU_VALOR
		 ORDER BY ABB.ABB_CODTEC, AB9.AB9_DTCHEG,AB9.AB9_HRCHEG,AB9.AB9_DTSAID, AB9.AB9_HRSAID

	EndSql
ELSE
	BeginSql Alias cAliasABR
		
		SELECT AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG, 
		       AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		       TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		       TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN, ABR.ABR_MOTIVO, ABN.ABN_DESC, 
		       TFU.TFU_CODIGO, TFU.TFU_VALOR, %Exp:cMod% TOT_HOR							 					 
		  FROM %table:ABB% ABB
		       JOIN %table:AB9% AB9 ON AB9.AB9_FILIAL = %xFilial:AB9%
		                           AND AB9.AB9_ATAUT = ABB.ABB_CODIGO
		                           AND AB9.AB9_NUMOS = ABB.ABB_CHAVE
		                           AND RTrim(LTrim(AB9.AB9_ITAPUR))=%Exp:cIdApur%
		                           AND AB9.%NotDel%		
		       JOIN %table:AB7% AB7 ON AB7.AB7_FILIAL = %xFilial:AB7%
		                           AND AB7.AB7_NUMOS %Exp:cOperador% AB7.AB7_ITEM = AB9.AB9_NUMOS
		                           AND AB7.%NotDel% 
		       JOIN %table:AB6% AB6 ON AB6.AB6_FILIAL = %xFilial:AB6%
		                           AND AB6.AB6_NUMOS = AB7.AB7_NUMOS
		                           AND AB6.%NotDel% 
	  	       JOIN %table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
	  	                           AND ABB.ABB_IDCFAL = %Exp:cIdcABQ%
	  	                           AND ABQ.%NotDel%		
		       JOIN %table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFF%
		                           AND TFF.TFF_FILIAL = ABQ.ABQ_FILTFF
		                           AND TFF.TFF_COD = ABQ.ABQ_CODTFF
		                           AND TFF.TFF_COD = %Exp:cCodTFF%
		                           AND %Exp:cWhereCob%
		                           AND TFF.%NotDel%
		       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
		                           AND TFL.TFL_CODIGO = %Exp:cCodTFL%
		                           AND %Exp:cChvTFL%
		                           AND TFL.%NotDel%
		       JOIN %table:ABR% ABR ON ABR.ABR_FILIAL = %xFilial:ABR%
		                           AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
		                           AND ABR.ABR_DTINI >= %Exp:cDataIni%
		                           AND ABR.ABR_DTFIM <= %Exp:cDataFim%
		                           AND ABR.%NotDel% 
		       JOIN %table:ABN% ABN ON ABN.ABN_FILIAL = %xFilial:ABN%
		                           AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO
		                           AND ABN.ABN_TIPO = '04'
		                           AND ABN.%NotDel%
		       LEFT JOIN %table:TFU% TFU ON TFU.TFU_FILIAL = %xFilial:TFU%
		                                AND TFU.TFU_CODTFF = TFF.TFF_COD
		                                AND TFU.TFU_CODABN = ABR.ABR_MOTIVO
		                                AND TFU.%NotDel% 
		       LEFT JOIN %table:ABS% ABS ON ABS.ABS_FILIAL = %xFilial:ABS%
		                                AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
		                                AND ABS.%NotDel%
		       LEFT JOIN %table:AA1% AA1 ON AA1.AA1_FILIAL = %xFilial:AA1%
		                                AND AA1.AA1_CODTEC = ABB.ABB_CODTEC
		                                AND AA1.%NotDel%
		 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
		   AND ABB.ABB_CHEGOU = 'S'
		   AND ABB.ABB_ATENDE = '1'
		   AND ABB.ABB_DTINI >= %Exp:cDataIni%
		   AND ABB.ABB_DTINI <= %Exp:cDataFim%
		   AND ABB.ABB_DTFIM >= %Exp:cDataIni%
		   AND ABB.ABB_DTFIM <= %Exp:cDataFim%
		   AND ABQ.ABQ_CONTRT = %Exp:cContrato%
		   AND ABB.%NotDel%	
		 GROUP BY AB9.AB9_NUMOS, AB9.AB9_SEQ, AB9.AB9_TOTFAT, AB6.AB6_EMISSA, AB9.AB9_DTCHEG, 
		          AB9.AB9_HRCHEG, AB9.AB9_DTSAID, AB9.AB9_HRSAID, TFF.TFF_CONTRT, TFF.TFF_CONREV, 
		          TFF.TFF_LOCAL, ABS.ABS_DESCRI, ABB.ABB_CODTEC, AA1.AA1_NOMTEC, ABQ.ABQ_TOTAL, 
		          TFF.TFF_PRCVEN, TFF.TFF_VALDES, TFF.TFF_QTDVEN, ABR.ABR_MOTIVO, ABN.ABN_DESC, 
		          TFU.TFU_CODIGO, TFU.TFU_VALOR
		 ORDER BY ABB.ABB_CODTEC, AB9.AB9_DTCHEG,AB9.AB9_HRCHEG,AB9.AB9_DTSAID, AB9.AB9_HRSAID

	EndSql
ENDIF

While (cAliasABR)->(!Eof())
		
	If Len(Alltrim((cAliasABR)->TFU_CODIGO)) > 0 // Campos de hora extra
		nVlrHor  := (cAliasABR)->TFU_VALOR
		nHorTot  := HoraToInt((cAliasABR)->TOT_HOR) * nVlrHor
	Else
		nVlrCont := ((cAliasABR)->TFF_PRCVEN - (cAliasABR)->TFF_VALDES) * (cAliasABR)->TFF_QTDVEN  
		nVlrHor  := nVlrCont / (cAliasABR)->ABQ_TOTAL   
		nHorTot  := HoraToInt((cAliasABR)->TOT_HOR) * nVlrHor
	EndIf

	IF lTela
	
		aAdd( aHrOsE, { (cAliasABR)->AB9_NUMOS		,	(cAliasABR)->AB9_SEQ,;
						   (cAliasABR)->ABR_MOTIVO	    ,  (cAliasABR)->ABN_DESC,;
						   AllTrim((cAliasABR)->TOT_HOR),	StoD((cAliasABR)->AB6_EMISSA),;
						   StoD((cAliasABR)->AB9_DTCHEG),	(cAliasABR)->AB9_HRCHEG,  ;
						   StoD((cAliasABR)->AB9_DTSAID),	(cAliasABR)->AB9_HRSAID,;
						   (cAliasABR)->TFF_CONTRT		,	(cAliasABR)->TFF_CONREV,; 
						   (cAliasABR)->TFF_LOCAL		,	(cAliasABR)->ABS_DESCRI,;
						   (cAliasABR)->ABB_CODTEC		,	(cAliasABR)->AA1_NOMTEC })
		
		nPos := aScan( aHrExtra, {|x| x[1]== (cAliasABR)->ABR_MOTIVO } )
		
		If nPos > 0	
		
			nHreTot := HoraToInt(aHrExtra[nPos][3]) + HoraToInt((cAliasABR)->TOT_HOR)
			nVlrTot := aHrExtra[nPos][5] + nHorTot
			
			aHrExtra[nPos][3] := AllTrim(IntToHora(nHreTot))
			aHrExtra[nPos][5] := Round(nVlrTot,2)
			
		Else
			aAdd(aHrExtra, {(cAliasABR)->ABR_MOTIVO, (cAliasABR)->ABN_DESC,;
				 			 AllTrim((cAliasABR)->TOT_HOR), Round(nVlrHor,2), Round(nHorTot,2) })		 
		EndIf
		
	Else 						
				
		nPos := aScan( aTecHrE, {|x| x[1] == (cAliasABR)->ABB_CODTEC .And. x[5] == (cAliasABR)->ABR_MOTIVO } )
	
		If nPos == 0		
			
			aAdd( aTecHrE, { (cAliasABR)->ABB_CODTEC,; 
								nVlrHor,;
								HoraToInt((cAliasABR)->TOT_HOR),;
								nHorTot,; 
								(cAliasABR)->ABR_MOTIVO } )
							    		
		Else
		
			nTecHor := aTecHrE[nPos][3] + HoraToInt((cAliasABR)->TOT_HOR)
			nValTot := aTecHrE[nPos][4] + nHorTot
			
			aTecHrE[nPos][3] := nTecHor
			aTecHrE[nPos][4] := nValTot		
			 	
		EndIf
		
		nPos := aScan( aTecHrN, {|x| x[1] == (cAliasABR)->ABB_CODTEC } )
		
		If nPos > 0
		
			nTecHor := aTecHrN[nPos][3] - HoraToInt((cAliasABR)->TOT_HOR)
			nValTot := aTecHrN[nPos][2] * nTecHor
			
			aTecHrN[nPos][3] := nTecHor
			aTecHrN[nPos][4] := nValTot	
		
		EndIf
		 
	Endif 		
	
	(cAliasABR)->(dbSkip())	
	
EndDo

IF lTela 
	aAdd( aRet, { aHrNormal, aHrOsE, aHrExtra } )
Else 
	aAdd( aRet, { aTecHrN, aTecHrE } )
Endif 	

Return(aRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930QDetLE()
Gera as informações do detalhes da Locação de Equipamentos para os equipamentos.
@param 		ExpC:Contrato a ser utilzado no detalhe
@param 		ExpC:Data Inicial da apuração/medição
@param 		ExpC:Data Final da apuração/medição
@param 		ExpC:Codigo do recurso humano a ser utilizado no detalhe
@param 		ExpC:Codigo do local a ser utilizado no detalhe
@param 		ExpC:Codigo da apuração para a pesquisa no estorno
@param 		ExpL:Para identificar se vai ser retornado dados para a tela ou processamento
@author 	Serviços 
@since  	13/02/2014
@version	P12 
@return 	ExpA: Array com os dados do detalhe do RH
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At930QDetLE(cCodTFI)

Local cAliasTEW := GetNextAlias()
Local cDtInTFV  := FwFldGet("TFV_DTINI")
Local cDtFiTFV  := FwFldGet("TFV_DTFIM")
Local dDataFim   
Local dDataIni   
Local aRet		  := {}
Local nDifDias  := 0 
Local nPosEq	  := 0
Local nTotDias  := 0
Local nLE		  := 0

BeginSql Alias cAliasTEW

	SELECT TEW_MOTIVO, TEW_CODMV, TEW_BAATD, TEW_PRODUT, TEW_DTRINI, TEW_DTRFIM, TEW_DTAMNT, TEW_SUBSTI
	  FROM %table:TEW% TEW
	 WHERE TEW_FILIAL = %xFilial:TEW%
	   AND TEW_CODEQU = %Exp:cCodTFI%
	   AND ( 
	         ( TEW.TEW_DTRINI BETWEEN %Exp:cDtInTFV% AND %Exp:cDtFiTFV% )
	         OR 
	         (     TEW.TEW_MOTIVO <> ' '
	           AND LTRIM(RTRIM(TEW.TEW_DTAMNT)) <> ' ' 
	           AND TEW.TEW_DTAMNT BETWEEN %Exp:cDtInTFV% AND %Exp:cDtFiTFV% )
	         OR
	         (     TEW.TEW_MOTIVO = ' '
	           AND LTRIM(RTRIM(TEW.TEW_DTRFIM)) <> ' ' 
	           AND LTRIM(RTRIM(TEW.TEW_DTAMNT)) = ' ' 
	           AND TEW.TEW_DTRFIM BETWEEN %Exp:cDtInTFV% AND %Exp:cDtFiTFV% )
	         OR
	         (     TEW.TEW_DTRINI < %Exp:cDtInTFV%
	           AND
	               (
	                 ( TEW.TEW_MOTIVO <> ' ' AND ( LTRIM(RTRIM(TEW.TEW_DTAMNT))=' ' OR TEW.TEW_DTAMNT > %Exp:cDtFiTFV% ) )
	                 OR
	                 ( TEW.TEW_MOTIVO = ' ' AND ( LTRIM(RTRIM(TEW.TEW_DTRFIM))=' ' OR TEW.TEW_DTRFIM > %Exp:cDtFiTFV% ) )
	               )
	         )
	       )
	   AND TEW.%NotDel%

EndSql

While (cAliasTEW)->(!EoF())

	If Len(AllTrim((cAliasTEW)->TEW_DTAMNT)) > 0
		dDataFim := (cAliasTEW)->TEW_DTAMNT
	ElseIf Len(AllTrim((cAliasTEW)->TEW_DTRFIM)) > 0
		dDataFim := (cAliasTEW)->TEW_DTRFIM
	Else 
		dDataFim := cDtFiTFV
	EndIf
	
	If valType(dDataFim) == "C"
		dDataFim := StoD(dDataFim)
	EndIf
	
	If Len(AllTrim((cAliasTEW)->TEW_DTRINI)) > 0
		dDataIni := (cAliasTEW)->TEW_DTRINI
	Else
		dDataIni := cDtInTFV
	EndIf
	
	If valType(dDataIni) == "C"
		dDataIni := StoD(dDataIni)
	EndIf 

	nDifDias := (dDataFim - dDataIni) + 1
	
	nPosEq := aScan( aRet, { |x| x[1] == (cAliasTEW)->TEW_BAATD } )
	
	If nPosEq == 0	
		aAdd( aRet, { (cAliasTEW)->TEW_BAATD, nDifDias, "2", 0, 0, 0, 0 } )
	Else 		
		aRet[nPosEq][2] += nDifDias 				
	EndIf
	
	nTotDias += nDifDias						
	
	(cAliasTEW)->(dbSkip())

EndDo

For nLE:=1 To Len(aRet)
	aRet[nLE][7] := aRet[nLE][2] / nTotDias  // Percentual do item equivalente a locação
Next
		
Return(aRet)	


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  AT930VldCt()
Valida se o contrato está com medição automatica
@param ExpO:Modelo de Dados da Tela de cadastro
@return ExpL: Retorna .T. quando não estiver com medição automatica
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AT930VldCt(oModel)

Local aArea			:= GetArea()
Local lRet				:= .T.
Local cTpCont			:= ""
Local cContrato		:= MV_PAR01
Local lFatAntecip 	:= (TFV->TFV_ANTECI == "1")
Local lRotFatAnteci 	:= ( IsInCallStack( "TECA934" ) )

If oModel:GetOperation() != MODEL_OPERATION_DELETE
	DbSelectArea("CN9")
	DbSetOrder(1) // CN9_FILIAL + CN9_NUMERO

	DbSelectArea("CN1")
	DbSetOrder(1)  // CN1_FILIAL + CN1_CODIGO

	If oModel:GetOperation() == MODEL_OPERATION_VIEW
		MV_PAR01 := TFV->TFV_CONTRT
	EndIf

	If CN9->(DbSeek(xFilial("CN9") + MV_PAR01 ) )
		cTpCont := CN9->CN9_TPCTO
		If CN1->(DbSeek(xFilial("CN1")+cTpCont))
			If CN1->CN1_MEDAUT == "1"
				Help(,,'AT930MEDAUTO',,STR0072,1,0)		//"Não é possível a medição ou apuração para um contrato com medição automática"
				lRet := .F.
			EndIf
		EndIf
	Endif
EndIf

If !lMedExt .AND. !lSrvExt .and. oModel:GetOperation() = MODEL_OPERATION_INSERT
	lRet := A930VldPer()
EndIf

// Valida quando é orçamento de faturamento antecipado
If lRet .And. !lRotFatAnteci
	If oModel:GetOperation() == MODEL_OPERATION_DELETE
		If lFatAntecip
			Help(,,'AT930ANTECIEST',, STR0127,1,0,,,,,,; // "Apuração de faturamento antecipado não pode ser estornada por esta rotina."
						{ STR0128 } ) // "Estorne pela rotina de faturamento antecipado."
			lRet := .F.
		EndIf
	ElseIf oModel:GetOperation() == MODEL_OPERATION_INSERT .and. !lMedExt
		lFatAntecip := At934IsFAnt( cContrato )
		If lFatAntecip
			Help(,,'AT930ANTECIINC',, STR0146,1,0,,,,,,; // "Apuração de faturamento antecipado não pode ser incluída por esta rotina."
						{ STR0147 } ) // "Inclua pela rotina de faturamento antecipado."
			lRet := .F.
		EndIf
	EndIf
EndIf


If oModel:GetOperation() == MODEL_OPERATION_VIEW
	MV_PAR01 := cContrato
EndIf

RestArea(aArea)

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  AT930Tes()
Retorna a TES do orçamento de serviços para a geração do pedido
@param ExpC:Tipo da TES a ser retornada
@param ExpC:Codigo do recurso a ser pesquisado
@author 	Serviços 
@since  	25/04/2014
@version	P12 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AT930Tes( cTipo, cCodTFF, cCodTFL )

Local cRet      := ""
Local aArea	  := GetArea()
Local cAliasTES := GetNextAlias()

Default cCodTFF := ""
Default cCodTFL := ""

If !Empty(cCodTFF)
	BeginSql Alias cAliasTES

		SELECT TFJ.TFJ_TES, TFJ.TFJ_TESMI, TFJ.TFJ_TESMC 
		  FROM %table:TFF% TFF
		       JOIN %table:TFL% TFL ON TFL.TFL_FILIAL = %xFilial:TFL%
		                           AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
		                           AND TFL.%NotDel%
		       JOIN %table:TFJ% TFJ ON TFJ.TFJ_FILIAL = %xFilial:TFJ%
		                           AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI
		                           AND TFJ.%NotDel%
		 WHERE TFF.TFF_FILIAL = %xFilial:TFF%
		   AND TFF.TFF_COD = %Exp:cCodTFF%
		   AND TFF.%NotDel%

	EndSql
Else
	BeginSql Alias cAliasTES

		SELECT TFJ.TFJ_TES, TFJ.TFJ_TESMI, TFJ.TFJ_TESMC 
		  FROM %Table:TFL% TFL
		       JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ% 
		                           AND TFJ.%NotDel%
		                           AND TFJ_CODIGO = TFL_CODPAI
		 WHERE TFL.%NotDel%
		   AND TFL_CODIGO = %Exp:cCodTFL%

	EndSql
EndIf

If cTipo = "TFF"
	cRet := (cAliasTES)->TFJ_TES
ElseIf cTipo = "TFG"
	cRet := (cAliasTES)->TFJ_TESMI 
ElseIf cTipo = "TFH"
	cRet := (cAliasTES)->TFJ_TESMC
EndIf		

(cAliasTES)->( DbCloseArea() )

RestArea(aArea)

Return(cRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930HePar()
	Valida a seleção do tipo de geração das horas extras
	Verifica se o parâmetro MV_CNBTEXC está configurado para permitir a geração de excedentes pelo GCT
@author 	Serviços 
@since  	04/09/2014
@version	P12 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At930HePar()

Local lRet			:= .T.
Local lPermExce	:= ( GetMv("MV_CNBTEXC",.F.,"N")=="S" ) // verifica se o parãmetro está habilitado 

If M->TFV_HREXTR=="2" .And. !lPermExce
	lRet := .F.
	Help(,,"At930HePar",,STR0083,1,0)
EndIf

Return lRet

//==============================================================================================================
/*/{Protheus.doc}  AT930AtuTot(oModelGrid, nLine, cAction, cField, xValue, xOldValue)
Atualiza totalizadores de multas(acréscimos), bonificações(decréscimos) e descontos, baseado no campo que está sendo modificado.

@return 	lRet
@author 	israel.escorizza
@since  	04/02/2015
@version	V12.1.6
/*/
//==============================================================================================================

Function AT930AtuTot(oModelGrid, nLine, cAction, cField, xValue, xOldValue)
Local oModel	:= oModelGrid:GetModel()		//- Modelo ativo
Local oModelG	:= NIL							//- Modelo que será utilizano no totalizador

Local cModelG	:= oModelGrid:GetId()		//- Id da Grid-pai utilizada.
Local cVlrFld := ""							//- Campo que contem o valor que será atualizado (TW6_VALOR | TW7_VALOR)

Local nVlrFld	:= 0							//- Valor numérico do campo (TW6_VALOR | TW7_VALOR)
Local nVlrTot := 0							//- Valor total do somatório que será aplicado no aCampos
Local nModo	:= 1							//- Define se é uma multa ou bonificação (TW7_TPMUL) (acréscimo ou decréscimo)

Local aCampos 	:= {}							//- Array para armazenamento dos campos que serão utilizados
Local aSaveLines	:= FWSaveRows()

Local lOS			:= .F.
Local lRet 		:= .T.

Default cField := ""
Default cAction := ""

If cAction $ "CANSETVALUE|SETVALUE|DELETE|UNDELETE"
		
	DO	CASE
		CASE cModelG == "TFWTW6DETAIL"
			oModelG := oModel:GetModel("TFWDETAIL")
			aAdd(aCampos,"TFW_TOTDES")
			aAdd(aCampos,"")
			aAdd(aCampos,"TFW_LOCAL")

		CASE cModelG == "TFXTW6DETAIL"
			oModelG := oModel:GetModel("TFXDETAIL")
			aAdd(aCampos,"TFX_TOTDES")
			aAdd(aCampos,"")
			aAdd(aCampos,"TFX_LOCAL")

		CASE cModelG == "TFYTW6DETAIL"
			oModelG := oModel:GetModel("TFYDETAIL")
			aAdd(aCampos,"TFY_TOTDES")
			aAdd(aCampos,"")
			aAdd(aCampos,"TFY_LOCAL")

		CASE cModelG == "TFITW6DETAIL"
			oModelG := oModel:GetModel("TFIPRODUT")
			aAdd(aCampos,"TFI_TOTDES")
			aAdd(aCampos,"")
			aAdd(aCampos,"TFI_CODPAI")
			
			If (TW6->( ColumnPos('TW6_OS')) > 0 )
				lOS	:= oModelGrid:GetValue("TW6_OS")
			Else
				lOS := .F.
			EndIf										

		CASE cModelG == "TFWTW7DETAIL"
			oModelG := oModel:GetModel("TFWDETAIL")
			aAdd(aCampos,"TFW_TOTMUL")
			aAdd(aCampos,"TFW_TOTBON")
			aAdd(aCampos,"TFW_LOCAL")

		CASE cModelG == "TFXTW7DETAIL"
			oModelG := oModel:GetModel("TFXDETAIL")
			aAdd(aCampos,"TFX_TOTMUL")
			aAdd(aCampos,"TFX_TOTBON")
			aAdd(aCampos,"TFX_LOCAL")

		CASE cModelG == "TFYTW7DETAIL"
			oModelG := oModel:GetModel("TFYDETAIL")
			aAdd(aCampos,"TFY_TOTMUL")
			aAdd(aCampos,"TFY_TOTBON")
			aAdd(aCampos,"TFY_LOCAL")

		CASE cModelG == "TFITW7DETAIL"
			oModelG := oModel:GetModel("TFIPRODUT")
			aAdd(aCampos,"TFI_TOTMUL")
			aAdd(aCampos,"TFI_TOTBON")
			aAdd(aCampos,"TFI_CODPAI")

	ENDCASE

	cVlrFld := IIf (SUBSTR(cModelG,4,3)== "TW6", "TW6_VALOR","TW7_VALOR")
	nVlrFld := oModelGrid:GetValue(cVlrFld)
	nVlrTot := oModelG:GetValue(aCampos[1])

	DO CASE
		CASE cAction == 'CANSETVALUE'
			If lOS
				Help(" ",1,"A930ALTOS") //- "Não é possivel alterar valor de desconto vinculado a uma OS."
				lRet := .F.
			EndIf

		CASE cAction == 'SETVALUE' .And. cField $ "TW6_VALOR|TW7_VALOR|TW7_TPMOV" .And. xOldValue != xValue
			If cField == "TW7_TPMOV"
				oModelG:SetValue(aCampos[1],nVlrTot + (nVlrFld * IIf(xValue=="1",1,-1)))
				nVlrTot := oModelG:GetValue(aCampos[2])
				oModelG:SetValue(aCampos[2],nVlrTot - (nVlrFld * IIf(xValue=="1",1,-1)))
			Else
				If cField == "TW7_VALOR"
					nModo := Iif(oModelGrid:GetValue("TW7_TPMOV") == "1",1,2)
				EndIf
				nVlrTot := oModelG:GetValue(aCampos[nModo])
				oModelG:SetValue(aCampos[nModo],nVlrTot + (xValue - xOldValue))
			EndIf

		CASE cAction == 'DELETE'
			If cVlrFld == "TW6_VALOR" //- Desconto
				If lOS
					Help(" ",1,"A930DELOS") //- "Não é possivel excluir um desconto vinculado a uma OS. O desconto será desconsiderado caso a OS não esteja selecionada!"
					lRet := .F.
				Else
					oModelG:SetValue(aCampos[1], nVlrTot - nVlrFld)
				EndIf
			Else
				nModo := Iif(oModelGrid:GetValue("TW7_TPMOV") == "1",1,2)
				nVlrTot := oModelG:GetValue(aCampos[nModo])
				oModelG:SetValue(aCampos[nModo], nVlrTot - nVlrFld)
			EndIf
		CASE cAction == 'UNDELETE'
			If cVlrFld == "TW6_VALOR" //- Desconto
				oModelG:SetValue(aCampos[1], nVlrTot + nVlrFld)
			Else
				nModo := Iif(oModelGrid:GetValue("TW7_TPMOV") == "1",1,2)
				nVlrTot := oModelG:GetValue(aCampos[nModo])
				oModelG:SetValue(aCampos[nModo], nVlrTot + nVlrFld)
			EndIf
	ENDCASE
	
	
	
	If cModelG $ "TFWTW7DETAIL|TFITW7DETAIL"
		
		oStruTFWTW7	 := oModel:GetModel(cModelG):GetStruct()
		
		oStruTFWTW7:SetProperty("TW7_TPMOV" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruTFWTW7:SetProperty("TW7_DESCRI" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruTFWTW7:SetProperty("TW7_VALOR" 	,MODEL_FIELD_WHEN, {||.T.} )
		oStruTFWTW7:SetProperty("TW7_FLGPED" 	,MODEL_FIELD_WHEN, {||.T.} )
		
		If oModelGrid:GetValue("TW7_DESPAD")== '1' 			
			oStruTFWTW7:SetProperty("TW7_TPMOV" 	,MODEL_FIELD_WHEN, {||.F.} )
			oStruTFWTW7:SetProperty("TW7_DESCRI" 	,MODEL_FIELD_WHEN, {||.F.} )
			oStruTFWTW7:SetProperty("TW7_VALOR" 	,MODEL_FIELD_WHEN, {||.F.} )
			oStruTFWTW7:SetProperty("TW7_FLGPED" 	,MODEL_FIELD_WHEN, {||.F.} )
			
			If cAction == 'DELETE' 
				Help( ,, 'Help',, STR0160, 1, 0 ) //"Não é possível excluir esta linha. "
				oModel:GetModel(cModelG):UnDeleteLine()
				lRet := .F.
			EndIf				
		EndIf
	Endif

	If Empty(oModelG:GetValue(aCampos[3])) .And. cAction == 'CANSETVALUE'
		Help( "", 1, "AT930AtuTot", , STR0159, 1, 0)//"Não é possível inserir Acréscimos e Decrécimos ou Descontos."
		lRet := .F.
	Endif
EndIf

FWRestRows(aSaveLines)

Return lRet

//==============================================================================================================
/*/{Protheus.doc}  AT930TfiMul()
Carga de visualização do campo virtual de Multas (acréscimos) e Bonificações (decréscimos) da tabela TFI

@Return
@author 	israel.escorizza
@since  	04/02/2015
@version	V12.1.6
/*/
//==============================================================================================================
Function AT930TfiMul()
Local oModel 	  := FwModelActive()
Local oModelTFI := oModel:GetModel("TFIDETAIL")
Local oModelTW7 := oModel:GetModel("TFITW7DETAIL")

Local nTotMul 	:= 0
Local nTotBon		:= 0
Local nX			:= 1
Local nY			:= 1
Local aSaveLines	:= FWSaveRows()

For nX := 1 To oModelTFI:Length()
	nTotMul := 0
	nTotBon := 0
	oModelTFI:GoLine(nX)
	For nY := 1 To oModelTW7:Length()
		oModelTW7:GoLine(nY)
		If(oModelTW7:GetValue("TW7_TPMOV") == "1")
			nTotMul += oModelTW7:GetValue("TW7_VALOR")
		Else
			nTotBon += oModelTW7:GetValue("TW7_VALOR")
		EndIf
	Next nY
	oModelTFI:SetValue("TFI_TOTMUL",nTotMul)
	oModelTFI:SetValue("TFI_TOTBON",nTotBon)
Next nX

FWRestRows(aSaveLines)

Return
//==============================================================================================================
/*/{Protheus.doc}  AT930TfiDes()
Carga de visualização do campo virtual de Descontos da tabela TFI
@Return
@author 	israel.escorizza
@since  	04/02/2015
@version	V12.1.6
/*/
//==============================================================================================================
Function AT930TfiDes()
Local oModel 	  := FwModelActive()
Local oModelTFI := oModel:GetModel("TFIDETAIL")
Local oModelTW6 := oModel:GetModel("TFITW6DETAIL")

Local nTot 	:= 0
Local nX		:= 0
Local nY		:= 0
Local aSaveLines	:= FWSaveRows()

For nX := 1 To oModelTFI:Length()
	nTot := 0
	oModelTFI:GoLine(nX)
	For nY := 1 To oModelTW6:Length()
		oModelTW6:GoLine(nY)
		nTot += oModelTW6:GetValue("TW6_VALOR")
	Next nY
	oModelTFI:SetValue("TFI_TOTDES",nTot)
Next nX

FWRestRows(aSaveLines)

Return

//==============================================================================================================
/*/{Protheus.doc}  At930LoOs(oModel)
Load das informações das ordens de Serviço 
@Return
@author 	filipe.goncalves
@since  	17/02/2016
@version	V12.1.12
/*/
//==============================================================================================================
Static Function At930LoOs(oModel, aEquip)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModelOs	:= oModel:GetModel("TW8DETAIL")
Local cAliasSTJ	:= GetNextAlias()
Local cProd		:= oModel:GetValue("TFIPRODUT", "TFI_COD")
Local cCodbem		:= ""
Local dDtIni	
Local dDtFim	
Local lRet			:= .T.
Local nX			:= 0

For nX := 1 to Len(aEquip)
	
	If cProd == aEquip[nx][1]
		
		dDtIni := aEquip[nx][4]
		dDtFim := If(Empty(aEquip[nx][5]), MV_PAR03, aEquip[nx][5])
		
		BeginSql Alias cAliasSTJ
			SELECT STJ.TJ_ORDEM, AA3.AA3_CODBEM, STJ.TJ_PLANO, STJ.TJ_DTMRINI, STJ.TJ_HOMRINI, STJ.TJ_DTMRFIM, STJ.TJ_HOMRFIM,
			       SUM(STJ.TJ_CUSTMDO + STJ.TJ_CUSTMAT + STJ.TJ_CUSTMAA + STJ.TJ_CUSTMAS + STJ.TJ_CUSTTER) TJ_CUSTO
			  FROM %table:TFI% TFI
			       INNER JOIN %table:TEW% TEW ON TEW.TEW_FILIAL = %xFilial:TEW% 
			                                 AND TEW.%NotDel%
			                                 AND TEW.TEW_CODEQU = TFI.TFI_COD
			       INNER JOIN %table:AA3% AA3 ON AA3.AA3_FILIAL = %xFilial:AA3% 
			                                 AND AA3.%NotDel%
			                                 AND AA3.AA3_NUMSER = TEW.TEW_BAATD 
			       INNER JOIN %table:STJ% STJ ON STJ.TJ_FILIAL = AA3.AA3_CDBMFL
			                                 AND STJ.%NotDel% 
			                                 AND STJ.TJ_CODBEM = AA3.AA3_CODBEM
			 WHERE TFI.TFI_FILIAL = %xFilial:TFI%
			   AND TFI.%NotDel%
			   AND TFI.TFI_COD = %Exp:aEquip[nx][1]%
 			   AND (STJ.TJ_DTMRINI >= %Exp:dDtIni% AND STJ.TJ_DTMRFIM <= %Exp:dDtFim%)
 			 GROUP BY STJ.TJ_ORDEM, AA3.AA3_CODBEM, STJ.TJ_PLANO, STJ.TJ_DTMRINI, STJ.TJ_HOMRINI, STJ.TJ_DTMRFIM, STJ.TJ_HOMRFIM 
		EndSql
		
		While (cAliasSTJ)->(! Eof())
			If !(Empty(oModelOs:GetValue('TW8_ORDEM')))
				oModelOs:SetNoInsertLine(.F.)
				oModelOs:AddLine()
				oModelOs:SetNoInsertLine(.T.)
			EndIf
			
			oModelOs:SetValue('TW8_ORDEM',  (cAliasSTJ)->TJ_ORDEM)
			oModelOs:SetValue('TW8_CODBEM', (cAliasSTJ)->AA3_CODBEM)
			oModelOs:SetValue('TW8_PLANO',  (cAliasSTJ)->TJ_PLANO)
			oModelOs:SetValue('TW8_DTMRIN', StoD((cAliasSTJ)->TJ_DTMRINI))
			oModelOs:SetValue('TW8_HOMINI', (cAliasSTJ)->TJ_HOMRINI)
			oModelOs:SetValue('TW8_DTMFIM', StoD((cAliasSTJ)->TJ_DTMRFIM))
			oModelOs:SetValue('TW8_HOMFIM', (cAliasSTJ)->TJ_HOMRFIM)
			oModelOs:SetValue('TW8_CODTFI', cProd)
			oModelOs:SetValue('TW8_NUMSER', aEquip[nx][3])
			oModelOs:SetValue('TW8_CUSTOT', (cAliasSTJ)->TJ_CUSTO)
			
			(cAliasSTJ)->(dbSkip())
		EndDo
		
		(cAliasSTJ)->( DbCloseArea() )
	EndIf
	
Next nX

RestArea(aArea)
FWRestRows( aSaveLines )
Return lRet

//==============================================================================================================
/*/{Protheus.doc}  At930VldOs()
Valid do campo TW8_OK
@Return 	lRet
@author 	filipe.goncalves
@since  	18/02/2016
@version	V12.1.12
/*/
//==============================================================================================================
Static Function At930VldOs()

Local aSave	:= FWSaveRows()
Local oModel	:= FwModelActive()
Local oView	:= FwViewActive()
Local oModTW6	:= oModel:GetModel('TFITW6DETAIL')
Local nCusto	:= oModel:GetValue('TW8DETAIL','TW8_CUSTOT')
Local cTpDesc	:= CN130DesPV()
Local lRet 	:= .T.

If Empty(oModel:GetValue('TW8DETAIL','TW8_ORDEM'))
	lRet := .F.
ElseIf	Empty(cTpDesc) 
	Help(,,"AT930NOREG",,STR0106,1,0)	//"Faça a inclusão de um tipo de desconto para que possa marcar uma OS!"
	lRet := .F.
EndIf

If	lRet
	If	oModel:GetValue("TW8DETAIL", "TW8_OK")

		// Marcando a O.S.
		If	!( oModTW6:SeekLine({{"TW6_TPDESC", cTpDesc}}) )
			// Se não encontrar a linha totalizadora dos descontos conforme o tipo de desconto, adiciona a linha da grid de totalizadores dos descontos
			oModTW6:AddLine()	
			oModTW6:SetValue("TW6_TPDESC", cTpDesc)
		EndIf
		oModTW6:SetValue("TW6_OS", .T.)
		oModTW6:SetValue("TW6_VALOR", (oModTW6:GetValue("TW6_VALOR") + nCusto))	
		If	Empty(oModel:GetValue("TW8DETAIL", "TW8_CODIGO"))
			oModel:SetValue("TW8DETAIL","TW8_CODIGO", oModTW6:GetValue("TW6_CODIGO"))	//Campo Gravado para controle
		EndIf

	Else

		// Desmarcando a O.S. 
		If	( oModTW6:SeekLine({{"TW6_TPDESC", cTpDesc},{"TW6_CODIGO",AllTrim(oModel:GetValue("TW8DETAIL","TW8_CODIGO"))}}) )
			oModTW6:SetValue('TW6_VALOR', (oModTW6:GetValue('TW6_VALOR') - nCusto))
		Else 
			Help(,,"AT930MARK",,STR0107,1,0)	//"Não localizado o tipo de desconto associado a esta Ordem de Serviço!"
			lRet := .F.
		EndIf

	EndIf
EndIf

FWRestRows(aSave)
Return lRet

//==============================================================================================================
/*/{Protheus.doc}  A930Multas()
Função que retonar o total de descontos
@author 	matheus.raimundo
@since  	12/02/2015
/*/
//==============================================================================================================
Function A930Multas(oModel,cPlan,nVlrMulta,nVlrBoni,nVlrDASep,lFatDASep, nVlrTotHE, lMedHE)
Local oModelTFW := oModel:GetModel("TFWDETAIL")
Local oModelTFX := oModel:GetModel("TFXDETAIL")
Local oModelTFY := oModel:GetModel("TFYDETAIL")
Local oModelTFL := oModel:GetModel("TFLDETAIL")
Local oModelTFI := oModel:GetModel("TFIPRODUT")
Local oModelTFWMUL := oModel:GetModel("TFWTW7DETAIL")
Local oModelTFXMUL := oModel:GetModel("TFXTW7DETAIL")
Local oModelTFYMUL := oModel:GetModel("TFYTW7DETAIL")
Local oModelTFLMUL := oModel:GetModel("TFITW7DETAIL")
Local nTot 		:= 0
Local lAddMult	:= .T.
Local nX		:= 0
Local nY		:= 0
Local nJ		:= 0
Local aMultas	:= {}
Local aSaveLines	:= FWSaveRows()

Default nVlrMulta := 0
Default nVlrBoni  := 0
Default lMedHE    := .F.

For nX := 1 To oModelTFW:Length()
	oModelTFW:GoLine(nX)
	
	If !oModelTFW:IsDeleted() .And. oModelTFW:GetValue('TFW_PLAN') == cPlan .and. oModelTFW:GetValue('TFW_VLRMED') > 0
		nVlrTotHE += oModelTFW:GetValue('TFW_VLREXT')
		For nY := 1 To oModelTFWMUL:Length()
			oModelTFWMUL:GoLine(nY)
			lAddMult := !lMedHE
			If !oModelTFWMUL:IsDeleted() .And. !Empty(oModelTFWMUL:GetValue('TW7_VALOR')) 
								
				If oModelTFWMUL:GetValue("TW7_DESPAD")=='1'
					If lFatDASep
						lAddMult := .F.
					Else
						lAddMult := .T.
					EndIf
					
				EndIf
							
				If lAddMult
					aAdd(aMultas,Array(6))	
																
					aTail(aMultas)[1] := oModelTFWMUL:GetValue("TW7_TPMOV")
					aTail(aMultas)[2] := oModelTFWMUL:GetValue("TW7_DESCRI")  
					aTail(aMultas)[3] := oModelTFWMUL:GetValue("TW7_VALOR")
					aTail(aMultas)[4] := oModelTFWMUL:GetValue("TW7_MODO") 
					aTail(aMultas)[5] := oModelTFWMUL:GetValue("TW7_FLGPED")
					
					If oModelTFWMUL:GetValue("TW7_TPMOV") == '1'
						nVlrMulta += oModelTFWMUL:GetValue("TW7_VALOR")									
					ElseIf oModelTFWMUL:GetValue("TW7_TPMOV") == '2'
						nVlrBoni += oModelTFWMUL:GetValue("TW7_VALOR")									
					EndIf					
				Else
					If lFatDASep .And. oModelTFWMUL:GetValue("TW7_DESPAD")=='1' 	
						nVlrDASep += oModelTFWMUL:GetValue("TW7_VALOR")
					EndIf 
				EndIf
				
			EndIf
		Next nY
	EndIf		
Next nX

For nX := 1 To oModelTFX:Length()
	oModelTFX:GoLine(nX)
	If !oModelTFX:IsDeleted() .And. oModelTFX:GetValue('TFX_PLAN') == cPlan .and. oModelTFX:GetValue('TFX_VLRMED') >0
		For nY := 1 To oModelTFXMUL:Length()
			oModelTFXMUL:GoLine(nY)
			If !oModelTFXMUL:IsDeleted() .And. !Empty(oModelTFXMUL:GetValue('TW7_VALOR')) 	
				aAdd(aMultas,Array(6))	
															
				aTail(aMultas)[1] := oModelTFXMUL:GetValue("TW7_TPMOV")
				aTail(aMultas)[2] := oModelTFXMUL:GetValue("TW7_DESCRI")  
				aTail(aMultas)[3] := oModelTFXMUL:GetValue("TW7_VALOR")
				aTail(aMultas)[4] := oModelTFXMUL:GetValue("TW7_MODO") 
				aTail(aMultas)[5] := oModelTFXMUL:GetValue("TW7_FLGPED")
				
				If oModelTFXMUL:GetValue("TW7_TPMOV") == '1'
					nVlrMulta += oModelTFXMUL:GetValue("TW7_VALOR")									
				ElseIf oModelTFXMUL:GetValue("TW7_TPMOV") == '2'
					nVlrBoni += oModelTFXMUL:GetValue("TW7_VALOR")									
				EndIf				
				 
			EndIf
		Next nY
	EndIf		
Next nX

For nX := 1 To oModelTFY:Length()
	oModelTFY:GoLine(nX)
	If !oModelTFY:IsDeleted() .And. oModelTFY:GetValue('TFY_PLAN') == cPlan .and. oModelTFY:GetValue('TFY_VLRMED') > 0
		For nY := 1 To oModelTFYMUL:Length()
			oModelTFYMUL:GoLine(nY)
			If !oModelTFYMUL:IsDeleted() .And. !Empty(oModelTFYMUL:GetValue('TW7_VALOR'))	
				aAdd(aMultas,Array(6))	
															
				aTail(aMultas)[1] := oModelTFYMUL:GetValue("TW7_TPMOV")
				aTail(aMultas)[2] := oModelTFYMUL:GetValue("TW7_DESCRI")  
				aTail(aMultas)[3] := oModelTFYMUL:GetValue("TW7_VALOR")
				aTail(aMultas)[4] := oModelTFYMUL:GetValue("TW7_MODO") 
				aTail(aMultas)[5] := oModelTFYMUL:GetValue("TW7_FLGPED")
				
				If oModelTFYMUL:GetValue("TW7_TPMOV") == '1'
					nVlrMulta += oModelTFYMUL:GetValue("TW7_VALOR")									
				ElseIf oModelTFYMUL:GetValue("TW7_TPMOV") == '2'
					nVlrBoni += oModelTFYMUL:GetValue("TW7_VALOR")									
				EndIf	 
			EndIf
		Next nY
	EndIf		
Next nX

For nX := 1 To oModelTFL:Length()	
	oModelTFL:GoLine(nX)
	If !oModelTFL:IsDeleted() .And. oModelTFL:GetValue('TFL_PLAN') == cPlan .and. oModelTFL:GetValue('TFL_VLRMED') > 0
		For nY := 1 To oModelTFI:Length()
			oModelTFI:GoLine(nY)
			If !oModelTFI:IsDeleted()
				For nJ := 1 To oModelTFLMUL:Length()
					lAddMult := .T.
					oModelTFLMUL:GoLine(nJ)
					If !oModelTFLMUL:IsDeleted() .And. !Empty(oModelTFLMUL:GetValue('TW7_VALOR'))
						If oModelTFLMUL:GetValue("TW7_DESPAD")=='1'
							If lFatDASep
								lAddMult := .F.
							Else
								lAddMult := .T.
							EndIf
						EndIf
									
						If lAddMult
							aAdd(aMultas,Array(6))	
																		
							aTail(aMultas)[1] := oModelTFLMUL:GetValue("TW7_TPMOV")
							aTail(aMultas)[2] := oModelTFLMUL:GetValue("TW7_DESCRI")  
							aTail(aMultas)[3] := oModelTFLMUL:GetValue("TW7_VALOR")
							aTail(aMultas)[4] := oModelTFLMUL:GetValue("TW7_MODO") 
							aTail(aMultas)[5] := oModelTFLMUL:GetValue("TW7_FLGPED")
							
							If oModelTFLMUL:GetValue("TW7_TPMOV") == '1'
								nVlrMulta += oModelTFLMUL:GetValue("TW7_VALOR")									
							ElseIf oModelTFLMUL:GetValue("TW7_TPMOV") == '2'
								nVlrBoni += oModelTFLMUL:GetValue("TW7_VALOR")									
							EndIf					
						Else
							If lFatDASep .And. oModelTFLMUL:GetValue("TW7_DESPAD")=='1' 	
								nVlrDASep += oModelTFLMUL:GetValue("TW7_VALOR")
							EndIf 
						EndIf						  
					EndIf
				Next nJ											 				
			EndIf
		Next nY
	EndIf		
Next nX

FWRestRows(aSaveLines)
Return aMultas                                       

//==============================================================================================================
/*/{Protheus.doc}  A930Desc()
	Função que retorna o array com os descontos ou o total do desconto.
@author 	Kaique Schiller Olivero
@since  	12/02/2015
/*/
//==============================================================================================================
Static Function A930Desc(oModel,cPlan,cContra,cRevisa,lGrpFat,cCodTFL,cCliDesc,cLojDesc,aDescs)
Local nX			:= 0
Local nY			:= 0
Local nJ			:= 0
Local nZ			:= 0
Local aSaveLines	:= FWSaveRows()
Local cTpDesc 		:= ""
Local nVlrTpDsc		:= 0
Local aTpDescAux	:= {}
Local aTipoDsc		:= {}
Local aGrpFat		:= {}
Local lGetDesc		:= .T.
Local aParamGrid	:= {{"RH","TFW_PLAN","TFW_LOCAL",oModel:GetModel("TFWDETAIL"),oModel:GetModel("TFWTW6DETAIL"),Nil},;
						{"MI","TFX_PLAN","TFX_LOCAL",oModel:GetModel("TFXDETAIL"),oModel:GetModel("TFXTW6DETAIL"),Nil},;
						{"MC","TFY_PLAN","TFY_LOCAL",oModel:GetModel("TFYDETAIL"),oModel:GetModel("TFYTW6DETAIL"),Nil},;
						{"LE","TFL_PLAN","TFL_LOCAL",oModel:GetModel("TFLDETAIL"),oModel:GetModel("TFITW6DETAIL"), oModel:GetModel("TFIPRODUT")}}

Local nVlrTotDes	:= 0

Default cCliDesc    := ""
Default cLojDesc	:= ""

For nX := 1 To Len(aParamGrid)
	If lGrpFat
		//Pega o cliente e a loja do grupo de faturamento.
		aGrpFat := At932CliGF(aParamGrid[nX,1],cContra,cRevisa,cCodTFL)
		If !Empty(aGrpFat)
			//Se for o mesmo cliente e loja que a medição pega os descontos.
			lGetDesc := cCliDesc == aGrpFat[1] .And. cLojDesc == aGrpFat[2]
		Endif
	Endif

	If lGetDesc
		//Pega todos os tipos de descontos nas abas.
		At930GtDc(cPlan,cContra,cRevisa,aParamGrid[nX,2],aParamGrid[nX,3],aParamGrid[nX,4],aParamGrid[nX,5],aParamGrid[nX,6],@aTipoDsc)
	Endif
Next nX

//Ordena os descontos
aSort( aTipoDsc,,,{ |x,y| x[1] < y[1] } )

//Pega quantos tipos de desconto tem para totalizar
For nX := 1 To Len(aTipoDsc)
	If cTpDesc <> aTipoDsc[nX,1]		
		aAdd(aTpDescAux,aTipoDsc[nX,1])
		cTpDesc := aTipoDsc[nX,1]
	EndIf
Next nX

cTpDesc := ""

//Totaliza todos os tipos de desconto
For nX := 1 To Len(aTpDescAux)
	For nY := 1 To Len(aTipoDsc)
		If aTpDescAux[nX] == aTipoDsc[nY,1]
			cTpDesc 	:= aTipoDsc[nY,1]
			nVlrTpDsc	+= aTipoDsc[nY,2]
			nVlrTotDes  += aTipoDsc[nY,2]
		Endif
	Next nY

	If nVlrTpDsc > 0
		aAdd(aDescs,{cTpDesc,nVlrTpDsc})
		cTpDesc 	:= ""
		nVlrTpDsc	:= 0
	Endif

Next nX

FWRestRows(aSaveLines)

Return nVlrTotDes

//==============================================================================================================
/*/{Protheus.doc}  A930GetDsc()
Função que retorna o total de descontos.
@author 	matheus.raimundo
@since  	19/02/2015
/*/
//==============================================================================================================
Function A930GetDsc(cCod,cTipo)
Local cAliasTW6 := GetNextAlias()
Local nRet 	  := 0	

If !Empty(cCod) 
	BeginSql Alias cAliasTW6

		SELECT SUM(TW6.TW6_VALOR) TW6_VALOR
		  FROM %table:TW6% TW6
		 WHERE TW6.TW6_FILIAL = %xFilial:TW6%
		   AND TW6.TW6_CODPAI IN %Exp:cCod%
		   AND TW6.TW6_TPPAI = %Exp:cTipo%
		   AND TW6.%NotDel%

	EndSql
	
	nRet :=  (cAliasTW6)->(TW6_VALOR)
	(cAliasTW6)->(dbCloseArea())
Else
	nRet := 0
EndIf		

Return nRet


//==============================================================================================================
/*/{Protheus.doc}  A930GetMB()
Função que retorna o total de Multas e Bonificações
@author 	matheus.raimundo
@since  	19/02/2015
/*/
//==============================================================================================================
Function A930GetMB(cCod,cTipo,nVlrMulta,nVlrBoni)
Local cAliasTW7 := GetNextAlias()

If !Empty(cCod)
	BeginSql Alias cAliasTW7

		SELECT SUM(TW7.TW7_VALOR) TW7_VALOR, TW7_TPMOV
		  FROM %table:TW7% TW7
		 WHERE TW7.TW7_FILIAL = %xFilial:TW7%
		   AND TW7.TW7_CODPAI IN %Exp:cCod%
		   AND TW7.TW7_TPPAI = %Exp:cTipo%
		   AND TW7.%NotDel%
		 GROUP BY TW7_TPMOV	

	EndSql

	While (cAliasTW7)->(!Eof())
	
		If (cAliasTW7)->(TW7_TPMOV) == '1'
			nVlrMulta := (cAliasTW7)->(TW7_VALOR)
		ElseIf (cAliasTW7)->(TW7_TPMOV) == '2'					
			nVlrBoni += (cAliasTW7)->TW7_VALOR	
		EndIf
	
		(cAliasTW7)->(dbSkip())	
	EndDo
	(cAliasTW7)->(dbCloseArea())
Else
	nVlrMulta := 0
	nVlrBoni := 0
EndIf	

Return 

//==============================================================================================================
/*/{Protheus.doc}  A930VLnTFITW6()
Função de validação da linha do modelo TFITW6DETAIL
@return	lRet
@author 	israel.escorizza
@since  	22/02/2015
/*/
//==============================================================================================================
Function A930VLnTFITW6()
Local oModel		:= FwModelActive()
Local oModTFITW6	:= oModel:GetModel('TFITW6DETAIL')
Local lRet 		:= .T.

If Empty(oModTFITW6:GetValue("TW6_TPDESC"))
	Help(" ",1,"A930NOTPO") //- "Campo Tipo Desc não preenchido"
	lRet := .F.
ElseIf oModTFITW6:GetValue("TW6_VALOR") <= 0 .And. !oModTFITW6:GetValue("TW6_OS")
	Help(" ",1,"A930NOVLR") //- "Campo Valor não preenchido"
	lRet := .F.
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  FMedApu930()
	Monta a tela de detalhamento de apontamento por valor
@author 	Serviços 
@since  	02/07/2015
@version	P12 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function FMedApu930(oModel)
Local cAliasPro	:= "AT930QRY"
Local cRotina  	:= 'TECA930'
Local cTitulo  	:= STR0086 //'Detalhes Apontamento por Valor'
Local cQuery   	:= ''
Local aSize	 		:= FWGetDialogSize( oMainWnd ) 	// Array com tamanho da janela.
Local aFields  	:= {}
Local cApuracao	:=oModel:GetModel("TFVMASTER"):GetValue("TFV_CODIGO") 


Local oPanel   := Nil
Local oFWLayer := Nil
Local oBrowse  := Nil

oBrowse := FWFormBrowse():New()

aColumns := At930Cols(cAliasPro)

If oModel:GetOperation() == MODEL_OPERATION_DELETE//Estorno
	cQuery   := At930Query(cApuracao)
Else
	cQuery   := At930Query("")
EndIf


DEFINE DIALOG oDlg TITLE cTitulo FROM aSize[1] + 100,aSize[2] + 100 TO aSize[3] - 100, aSize[4] - 100 PIXEL
	
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

oBrowse:AddButton( STR0085, { || oDlg:End() },,,, .F., 2 )	//'Sair'

oBrowse:SetDescription(cTitulo)

oBrowse:Activate()

ACTIVATE DIALOG oDlg CENTERED

Return ( .T. )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930Cols()
	Tratamento dos campos que serão exibidos na tela de detalhamento de materiais
@author 	Serviços 
@since  	02/07/2015
@version	P12 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At930Cols( cAliasPro )

Local nI		:= 0 
Local aArea		:= GetArea()
Local aColumns	:= {}

Local aCampos 	:= { "TGU_DATA", "TFL_LOCAL", "ABS_DESCRI", "TGU_PROD", "B1_DESC", "TGU_QUANT", "TGU_VALOR", "TGU_TOTAL" }
							
DbSelectArea("SX3")
SX3->(DbSetOrder(2))

For nI:=1 To Len(aCampos)

	if aCampos[nI] == 'TGU_TOTAL'

		cCampo := aCampos[nI]
		
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
	   	aColumns[nLinha]:SetType("N")
	   	aColumns[nLinha]:SetTitle("Total")
		aColumns[nLinha]:SetSize(14)
		aColumns[nLinha]:SetDecimal(2)
		aColumns[nLinha]:SetPicture(" @E 999,999,999.99" )
		aColumns[nLinha]:SetData(&("{||" + cCampo + "}"))		
				
	else
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
	endif
	
Next nI

SX3->(dbCloseArea())

RestArea(aArea)

Return(aColumns)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930Query()
	Query para filtro dos registros de detalhamento por valor
@author 	Serviços 
@since  	02/07/2015
@version	P12 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At930Query(cApuracao)
Local cRevCtr := Posicione("CN9",1,xFilial("CN9")+MV_PAR01,"CN9_REVATU")

cQuery := " SELECT TGU_DATA, TFL_LOCAL, ABS_DESCRI, TGU_PROD, B1_DESC, TGU_QUANT, TGU_VALOR, ( TGU_QUANT * TGU_VALOR ) TGU_TOTAL "
 
cQuery += " FROM " + RetSqlName("TGU")

cQuery += " INNER JOIN " + RetSqlName("TFL")
cQuery += " ON TFL_FILIAL = '" + xFilial("TFL") + "' AND"
cQuery += " TFL_CONTRT = '" + MV_PAR01 + "' AND TFL_CONREV = '" + cRevCtr + "'  AND TGU_CODTFL = TFL_CODIGO "

If lSrvExt 
	cQuery +=  " AND TFL_CODPAI = '" + MV_PAR05 + "' "
EndIf

cQuery += " INNER JOIN " + RetSqlName("SB1")
cQuery += " ON B1_FILIAL = '" + xFilial("SB1") + "' AND"
cQuery += " B1_COD = TGU_PROD "

cQuery += " INNER JOIN " + RetSqlName("ABS")
cQuery += " ON ABS_FILIAL = '"+ xFilial("ABS") + "' AND"
cQuery += " ABS_LOCAL = TFL_LOCAL "

cQuery += " WHERE TGU_APURAC = '"+cApuracao+"'"
cQuery += " AND ( TGU_DATA >= '" + dToS(MV_PAR02) + "' AND TGU_DATA <= '" +  dToS(MV_PAR03) + "' ) "
cQuery += " AND "+RetSqlName("TFL")+".D_E_L_E_T_ = ''"
cQuery += " AND "+RetSqlName("TGU")+".D_E_L_E_T_ = ''"
cQuery += " AND "+RetSqlName("SB1")+".D_E_L_E_T_ = ''"
cQuery += " AND "+RetSqlName("ABS")+".D_E_L_E_T_ = ''"

cQuery += " ORDER BY TGU_DATA"

Return ( cQuery )

/*/{Protheus.doc}  At930ResLoc()
	Carrega os dados dos locais do Orçamento na apuração (aba de resumo dos locais)
@since  	01/04/2016
/*/
Function At930ResLoc( oMdl, cNumCtr, cRevCtr,cNumOrc )
Local oMdlResumo := oMdl:GetModel("TWBDETAIL")
Local aArea := GetArea()
Local aAreaTFL := TFL->( GetArea() )
Local lOk := .T.
Local oPlanPrec := Nil 
Local aXmlItens := Nil
Local nValImp := 0
Local lValImp := .F.
Local cChvTFL    := ""
Local cChvWhile  := ""
Local cNumero	 := ""
Local cQuery := ""
Local cAliasQry := GetNextAlias()


cQuery := "SELECT * FROM " + RetSqlName( "TFL" )
If lSrvExt
	cQuery += "WHERE TFL_CODPAI = '" + cNumOrc + "' 
Else
	cQuery += "WHERE TFL_CONTRT = '" + cNumCtr + "'
	cQuery += "AND TFL_CONREV = '" + cRevCtr + "'
EndIf
cQuery += "AND TFL_FILIAL = '" + xFilial("TFL") + "'
cQuery += "AND D_E_L_E_T_ = '' "
cQuery += "ORDER BY R_E_C_N_O_ ASC "

cQuery := ChangeQuery(cQuery)
dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ) , cAliasQry, .F., .T. )

oMdlResumo:SetNoInsertLine(.F.)

DbSelectArea("TFJ")
TFJ->( DbSetOrder(1) ) // TFJ_FILIAL+TFJ_CODIGO

		
If ( lValImp := TFJ->(DbSeek(xFilial("TFJ")+(cAliasQry)->TFL_CODPAI)) .And. ; // posiciona no cabeçalho do orçamento de serviços
				!Empty(TFJ->TFJ_TABXML) )  // verifica se é orçamento com precificação
	
	oPlanPrec := FWUIWorkSheet():New(,.F.)
EndIf
	
	While (cAliasQry)->(!EOF()) .And. (cAliasQry)->TFL_CONTRT == cNumCtr .And. (cAliasQry)->TFL_CONREV == cRevCtr 
		If !Empty( oMdlResumo:GetValue("TWB_CODTFL") ) 
			// verifica se foi possível adicionar nova linha, caso não consiga
			// aborta o preenchimento do grid
			If oMdlResumo:Length()+1 <> oMdlResumo:AddLine()
				AtErroMvc(oMdl)
				MostraErro()
				lOk := .F.
				Exit
			EndIf
		EndIf
		// não sei pq mas no ambiente não estava inicializando corretamente com getsxenum na primeira linha
		If Empty( oMdlResumo:GetValue("TWB_COD") )
			lOk := lOk .And. oMdlResumo:SetValue("TWB_COD", CriaVar("TWB_COD"))
		EndIf
		
		lOk := lOk .And. oMdlResumo:SetValue("TWB_CODTFL", (cAliasQry)->TFL_CODIGO)
		lOk := lOk .And. oMdlResumo:SetValue("TWB_CODABS", (cAliasQry)->TFL_LOCAL)
		
		//-------------------------------------------------------
		//  recarregar o objeto da planilha para capturar o valor de imposto
		If lValImp
			// lê o valor do imposto a partir do campo na TFL
			nValImp := (cAliasQry)->TFL_TOTIMP

			If nValImp > 0
				lOk := lOk .And. oMdlResumo:SetValue("TWB_VLORIG", nValImp)
				lOk := lOk .And. oMdlResumo:SetValue("TWB_IMPMED", ( nValImp/ At740FDDiff( (cAliasQry)->TFL_DTINI, (cAliasQry)->TFL_DTFIM ) ) )
			EndIf
		EndIf

		// aborta o preenchimento na identificação de qlq erro
		If !lOk
			AtErroMvc(oMdl)
			MostraErro()
			Exit
		EndIf

		(cAliasQry)->(DbSkip())
	EndDo
	oMdlResumo:SetNoInsertLine(.T.)
//EndIf
(cAliasQry)->(DbCloseArea())
RestArea(aAreaTFL)
RestArea(aArea)

Return

/*/{Protheus.doc}  At930TrgLoc()
	Função para execução dos gatilho de preenchimento dos campos conforme o conceito de produto RH, MI, MC e LE
@since  	05/04/2016
@sample 	At930TrgLoc( 'TFXDETAIL', 'TFX_VLRMED', 'TWBDETAIL', 'TWB_VLRMI', 'TFX_CODTFL' )
@param  	cMdlCalc, Caracter, modelo de origem das informações
@param  	cCpoTot, Caracter, identificador do campo que deve ter o conteúdo somado
@param  	cMdlCDom, Caracter, modelo de destino do valor somado
@param  	cCpoCDom, Caracter, identificador do campo de destino do valor somado
@param  	cCpoCodTFL, Caracter, identificador do campo que possui o conteúdo com o código da TFL para condicionar a soma
/*/
Function At930TrgLoc( cMdlCalc, cCpoTot, cMdlCDom, cCpoCDOM, cCpoCodTFL )

Local nValor := 0
Local nX := 1
Local oMdl   := FwModelActive()
Local nLineAnt := oMdl:GetModel( cMdlCalc ):GetLine()
Local cCodTFL := oMdl:GetModel( cMdlCalc ):GetValue(cCpoCodTFL)

For nX := 1 To oMdl:GetModel( cMdlCalc ):Length()
    oMdl:GetModel( cMdlCalc ):GoLine(nX)        	
    
	If oMdl:GetModel( cMdlCalc ):GetValue(cCpoCodTFL) == cCodTFL
    	nValor += oMdl:GetModel( cMdlCalc ):GetValue( cCpoTot )
    	If cCpoTot = "TFW_VLRMED"
			nValor += oMdl:GetModel( cMdlCalc ):GetValue( "TFW_VLMTMI" )
			nValor += oMdl:GetModel( cMdlCalc ):GetValue( "TFW_VLMTMC" )
		EndIf
	EndIf
Next nX	

// posiciona no item do local que deve sofrer a atualização do valor
If oMdl:GetModel( cMdlCDom ):SeekLine( {{ "TWB_CODTFL", cCodTFL }} )
	oMdl:GetModel( cMdlCDom ):SetValue( cCpoCDOM, nValor )
EndIf

oMdl:GetModel( cMdlCalc ):GoLine(nLineAnt)

Return 0

/*/{Protheus.doc}  At930TrgMBD()
	Função para somar os valores de Multa, Bonificações e Descontos conforme o código do local do orçamento vinculado
@since  	05/04/2016
@sample 	At930TrgMBD( 'TFIPRODUT', 1, 'TFI_CODPAI' )
@param  	cIdMdlOrig, Caracter, modelo de origem das informações
@param  	nTipo, Numerico, codigo que indica qual o tipo deve ter o conteúdo somado (1=Multa;2=Bonificação;3=Desconto)
@param  	cCpoCodTFL, Caracter, identificador do campo que possui o conteúdo com o código da TFL para condicionar a soma
/*/
Function At930TrgMBD( cIdMdlOrig, nTipo, cCpoCodTFL )

Local nValor := 0
Local nX := 1
Local nY := 1
Local oMdl   := FwModelActive()
Local nLineAnt := oMdl:GetModel( cIdMdlOrig ):GetLine()
Local cCodTFL := oMdl:GetModel( cIdMdlOrig ):GetValue(cCpoCodTFL)
Local aInfCpos := {{"TFWDETAIL","TFW_CODTFL",{"TFW_TOTMUL","TFW_TOTBON","TFW_TOTDES"}},;
					{"TFXDETAIL","TFX_CODTFL",{"TFX_TOTMUL","TFX_TOTBON","TFX_TOTDES"}},;
					{"TFYDETAIL","TFY_CODTFL",{"TFY_TOTMUL","TFY_TOTBON","TFY_TOTDES"}},;
					{"TFIPRODUT","TFI_CODPAI",{"TFI_TOTMUL","TFI_TOTBON","TFI_TOTDES"}}}
Local aCpoDest := { "TWB_VLRMUL", "TWB_VLRBON", "TWB_VLRDES" }
Local oMdlTmp := Nil
Default nTipo := 0

If nTipo > 0 .And. nTipo <= 3
	For nX := 1 To Len(aInfCpos)
	    
	    oMdlTmp := oMdl:GetModel( aInfCpos[nX,1] )
	    
	    For nY := 1 To oMdlTmp:Length()
	    	
	    	oMdlTmp:GoLine(nY)
	    
			If oMdlTmp:GetValue(aInfCpos[nX,2]) == cCodTFL
		    	nValor += oMdlTmp:GetValue( aInfCpos[nX,3,nTipo] )
			EndIf
		
		Next nY
	Next nX	
	
	// posiciona no item do local que deve sofrer a atualização do valor
	If oMdl:GetModel( "TWBDETAIL" ):SeekLine( {{ "TWB_CODTFL", cCodTFL }} )
		oMdl:GetModel( "TWBDETAIL" ):SetValue( aCpoDest[nTipo], nValor )
	EndIf
	
	oMdl:GetModel( cIdMdlOrig ):GoLine(nLineAnt)

EndIf

Return 0

/*/{Protheus.doc}  At930ResView()
	Função para somar os valores de Multa, Bonificações e Descontos conforme o código do local do orçamento vinculado
@since  	05/04/2016
@sample 	At930ResView( oMdlGer )
@param  	cIdMdlOrig, Caracter, modelo de origem das informações
@param  	nTipo, Numerico, codigo que indica qual o tipo deve ter o conteúdo somado (1=Multa;2=Bonificação;3=Desconto)
@param  	cCpoCodTFL, Caracter, identificador do campo que possui o conteúdo com o código da TFL para condicionar a soma
/*/
Function At930ResView( oMdlGer )

Local nPosCodLoc 		:= 1
Local nPosRh 			:= 2
Local nPosMi 			:= 3
Local nPosMc 			:= 4
Local nPosLe 			:= 5
Local nPosMul 		:= 6
Local nPosBon 		:= 7
Local nPosDes 		:= 8
Local nPosCodABS 		:= 9
Local nPosDesABS 		:= 10
Local nQtTotal 		:= 10
Local aDadosLocais 	:= Array(oMdlGer:GetModel("TWBDETAIL"):Length())
Local nI 				:= 1
Local nJ 				:= 1
Local nK 				:= 1
Local nItLocal 		:= 0
Local cFilABS			:= xFilial("ABS")
Local cFilTFL			:= xFilial("TFL")
Local oMdlTemp 		:= Nil

// Cria a estrutura para copiar os dados dos modelos
For nI := 1 To Len(aDadosLocais)
	aDadosLocais[nI]				:= Array(nQtTotal)
	// inicializa o conteúdo conforme o tipo
	aDadosLocais[nI,nPosCodLoc] := ""
	aDadosLocais[nI,nPosRh]		:= 0
	aDadosLocais[nI,nPosMi]		:= 0
	aDadosLocais[nI,nPosMc]		:= 0
	aDadosLocais[nI,nPosLe]		:= 0
	aDadosLocais[nI,nPosMul]		:= 0
	aDadosLocais[nI,nPosBon]		:= 0
	aDadosLocais[nI,nPosDes]		:= 0
	aDadosLocais[nI,nPosCodABS]	:= 0
	aDadosLocais[nI,nPosDesABS]	:= 0
Next nI

// Soma os valores conforme os conceitos de produtos: RH, Mat. Imp., Mat. Cons. e Locação
// Recursos Humanos
oMdlTemp := oMdlGer:GetModel("TFWDETAIL")
For nI := 1 To oMdlTemp:Length()
	oMdlTemp:GoLine(nI)
	
	If ( nItLocal := aScan( aDadosLocais, {|x| x[nPosCodLoc] == oMdlTemp:GetValue("TFW_CODTFL") } ) ) == 0
		nItLocal := aScan( aDadosLocais, {|x| AllTrim(x[nPosCodLoc])== "" } )
	EndIf

	If	nItLocal > 0
		aDadosLocais[nItLocal,nPosCodLoc]	:= oMdlTemp:GetValue("TFW_CODTFL")
		aDadosLocais[nItLocal,nPosRh]		+= oMdlTemp:GetValue("TFW_VLRMED")+oMdlTemp:GetValue("TFW_VLREXT")+oMdlTemp:GetValue("TFW_VLMTMI")+oMdlTemp:GetValue("TFW_VLMTMC")
		aDadosLocais[nItLocal,nPosMul]		+= oMdlTemp:GetValue("TFW_TOTMUL")
		aDadosLocais[nItLocal,nPosBon]		+= oMdlTemp:GetValue("TFW_TOTBON")
		aDadosLocais[nItLocal,nPosDes]		+= oMdlTemp:GetValue("TFW_TOTDES")
	EndIf
Next nI
oMdlTemp:GoLine(1)

// Material de Implantação
oMdlTemp := oMdlGer:GetModel("TFXDETAIL")
For nI := 1 To oMdlTemp:Length()
	oMdlTemp:GoLine(nI)
	
	If ( nItLocal := aScan( aDadosLocais, {|x| x[nPosCodLoc]== oMdlTemp:GetValue("TFX_CODTFL") } ) ) == 0
		nItLocal := aScan( aDadosLocais, {|x| AllTrim(x[nPosCodLoc])== "" } )
	EndIf

	If	nItLocal > 0
		aDadosLocais[nItLocal,nPosCodLoc]	:= oMdlTemp:GetValue("TFX_CODTFL")
		aDadosLocais[nItLocal,nPosMi]		+= oMdlTemp:GetValue("TFX_VLRMED")
		aDadosLocais[nItLocal,nPosMul]		+= oMdlTemp:GetValue("TFX_TOTMUL")
		aDadosLocais[nItLocal,nPosBon]		+= oMdlTemp:GetValue("TFX_TOTBON")
		aDadosLocais[nItLocal,nPosDes]		+= oMdlTemp:GetValue("TFX_TOTDES")
	EndIf
Next nI
oMdlTemp:GoLine(1)

// Material de Consumo
oMdlTemp := oMdlGer:GetModel("TFYDETAIL")
For nI := 1 To oMdlTemp:Length()
	oMdlTemp:GoLine(nI)
	
	If ( nItLocal := aScan( aDadosLocais, {|x| x[nPosCodLoc]== oMdlTemp:GetValue("TFY_CODTFL") } ) ) == 0
		nItLocal := aScan( aDadosLocais, {|x| AllTrim(x[nPosCodLoc])== "" } )
	EndIf

	If	nItLocal > 0
		aDadosLocais[nItLocal,nPosCodLoc]	:= oMdlTemp:GetValue("TFY_CODTFL")
		aDadosLocais[nItLocal,nPosMc]		+= oMdlTemp:GetValue("TFY_VLRMED")
		aDadosLocais[nItLocal,nPosMul]		+= oMdlTemp:GetValue("TFY_TOTMUL")
		aDadosLocais[nItLocal,nPosBon]		+= oMdlTemp:GetValue("TFY_TOTBON")
		aDadosLocais[nItLocal,nPosDes]		+= oMdlTemp:GetValue("TFY_TOTDES")
	EndIf
Next nI
oMdlTemp:GoLine(1)

// Locação de Equipamentos - TFL - TFI - TFZ
oMdlTemp := oMdlGer:GetModel("TFLDETAIL")
For nI := 1 To oMdlTemp:Length()
	oMdlTemp:GoLine(nI)
	
	If ( nItLocal := aScan( aDadosLocais, {|x| x[nPosCodLoc]== oMdlTemp:GetValue("TFL_CODIGO") } ) ) == 0
		nItLocal := aScan( aDadosLocais, {|x| AllTrim(x[nPosCodLoc])== "" } )
	EndIf

	If	nItLocal > 0
		aDadosLocais[nItLocal,nPosCodLoc]	:= oMdlTemp:GetValue("TFL_CODIGO")
		aDadosLocais[nItLocal,nPosLe]		+= oMdlTemp:GetValue("TFL_VALTOT")

		For nJ := 1 To oMdlGer:GetModel("TFIPRODUT"):Length()
			oMdlGer:GetModel("TFIPRODUT"):GoLine(nJ)

			aDadosLocais[nItLocal,nPosMul]	+= oMdlGer:GetModel("TFIPRODUT"):GetValue("TFI_TOTMUL")
			aDadosLocais[nItLocal,nPosBon]	+= oMdlGer:GetModel("TFIPRODUT"):GetValue("TFI_TOTBON")
			aDadosLocais[nItLocal,nPosDes]	+= oMdlGer:GetModel("TFIPRODUT"):GetValue("TFI_TOTDES")
		Next nJ
	EndIf
Next nI
oMdlTemp:GoLine(1)

DbSelectArea("TFL")
TFL->(DbSetOrder( 1 )) // TFL_FILIAL+TFL_CODIGO

DbSelectArea("ABS")
ABS->(DbSetOrder( 1 )) // ABS_FILIAL+ABS_LOCAL

For nItLocal := 1 To Len(aDadosLocais)

	TFL->(DbSeek(cFilTFL+aDadosLocais[nItLocal,nPosCodLoc]))
	aDadosLocais[nItLocal,nPosCodABS] := TFL->TFL_LOCAL

	ABS->(DbSeek(cFilABS+aDadosLocais[nItLocal,nPosCodABS]))
	aDadosLocais[nItLocal,nPosDesABS] := ABS->ABS_DESCRI

Next nItLocal

// atribui os valores ao modelo do resumo
oMdlTemp := oMdlGer:GetModel("TWBDETAIL")
For nI := 1 To oMdlTemp:Length()
	oMdlTemp:GoLine(nI)
	
	nItLocal := aScan( aDadosLocais, {|x| x[nPosCodLoc]== oMdlTemp:GetValue("TWB_CODTFL") } )
	If nItLocal > 0
		oMdlTemp:LoadValue("TWB_VLRRH",aDadosLocais[nItLocal,nPosRh])
		oMdlTemp:LoadValue("TWB_VLRMI",aDadosLocais[nItLocal,nPosMi])
		oMdlTemp:LoadValue("TWB_VLRMC",aDadosLocais[nItLocal,nPosMc])
		oMdlTemp:LoadValue("TWB_VLRLE",aDadosLocais[nItLocal,nPosLe])
		oMdlTemp:LoadValue("TWB_VLRMUL",aDadosLocais[nItLocal,nPosMul])
		oMdlTemp:LoadValue("TWB_VLRBON",aDadosLocais[nItLocal,nPosBon])
		oMdlTemp:LoadValue("TWB_VLRDES",aDadosLocais[nItLocal,nPosDes])
	
		oMdlTemp:LoadValue("TWB_TOTMED",At930TotRL(oMdlGer))
	Endif
Next nI
oMdlTemp:GoLine(1)

Return


Function At930TotRL(oModInfo)
Local nValorTot := 0
Local oModResLoc := Nil
Local nValMed := 0
Local nVlrMulta := 0
Local nVlrBoni := 0
Local nVlrDesc := 0

Default oModInfo := FwModelActive()
oModResLoc := oModInfo:GetModel("TWBDETAIL")

If oModInfo:GetId() == "TECA930"
	
	nValMed := oModResLoc:GetValue("TWB_VLRRH") + oModResLoc:GetValue("TWB_VLRMI") + oModResLoc:GetValue("TWB_VLRMC") + oModResLoc:GetValue("TWB_VLRLE") + oModResLoc:GetValue("TWB_IMPMED")
	nVlrMulta := oModResLoc:GetValue("TWB_VLRMUL")
	nVlrBoni := oModResLoc:GetValue("TWB_VLRBON")
	nVlrDesc := oModResLoc:GetValue("TWB_VLRDES")
	
	nValorTot := (nValMed - nVlrDesc + nVlrMulta - nVlrBoni)
EndIf

Return nValorTot

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930MinDt()

@author 	Serviços 
@since  	12/05/2016
@version	P12 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At930MinDt(cCodigo)
Local cNewAlias	 := GetNextAlias()
Local dDtRemes	 := sTod("")
Default cCodigo := ""

If !Empty(cCodigo)

	BeginSql Alias cNewAlias

		SELECT MIN(F2_EMISSAO) EMISSAO
		  FROM %Table:TEW% TEW
		       INNER JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL = %xFilial:SC5%
		                                 AND SC5.C5_NUM = TEW.TEW_NUMPED
		                                 AND SC5.%NotDel%
		       INNER JOIN %Table:SF2% SF2 ON SF2.F2_FILIAL = %xFilial:SF2%
		                                 AND SF2.F2_DOC = SC5.C5_NOTA
		                                 AND SF2.F2_SERIE = SC5.C5_SERIE 
		                                 AND SF2.F2_CLIENTE = SC5.C5_CLIENTE
		                                 AND SF2.F2_LOJA = SC5.C5_LOJACLI
		                                 AND SF2.%NotDel%
		 WHERE TEW.TEW_FILIAL = %xFilial:TEW%
		   AND TEW.TEW_CODEQU = %Exp:cCodigo%
		   AND TEW.%NotDel%

	EndSql

	If (cNewAlias)->(!Eof())
		dDtRemes := (cNewAlias)->EMISSAO
	Endif
	
(cNewAlias)->(dbCloseArea())

Endif

Return dDtRemes

/*/{Protheus.doc}  PreLinTFZ()
	Valida se pode realizar a edição da linha de apuração do modo de cobrança de locação de equipamentos
@author 	Inovação Gestão de Serviços
@since  	16/09/2016
@version	P12
@param 		oModelGrid, Objeto FwFormGridModel, objeto da grid completo em edição
@param 		nLine, Numérico, número da linha sendo editada ou tentando ser editada
@param 		cAction, Caracter, código da ação sendo executada CANSETVALUE, SETVALUE, DELETELINE, UNDELETELINE
@return 	Lógico, determina se pode ou não editar a linha
/*/
Static Function PreLinTFZ(oModelGrid, nLine, cAction, cField)

Local lRet := .T.

If cAction == "CANSETVALUE" .And. oModelGrid:GetValue("TFZ_MODCOB") == "5"
	lRet := .F.
	Help(,,"PRELINTFZ",, STR0114,1,0,,,,,,;  // "Não é permitida a alteração quando o modo de cobrança é 5-Franquia/Excedente."
					{STR0115})  // "Altere o valor inserido como acréscimo/decréscimo na respectiva aba."
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930CQtdC
Retorna o valor proporcional dentro de um periodo
@sample 	At930CQtdC(dDtParI,dDtContI,dDtParF,dDtContF) 
@param		dDtParI  - Data inicial Informada no parametro
@param		dDtContI - Data Inicial do Orçamento
@param		dDtParF  - Data Final Informada no parametro
@param		dDtContF - Data Final do Orçamento
@return		nRet - Numerico
@since		09/09/2016
@author		Serviços       
@version	P12   
/*/
//------------------------------------------------------------------------------//
Static Function At930CQtdC(dDtParI,dDtContI,dDtParF,dDtContF)

Local nRet := 0
Local dDtIni	:= sTod("")
Local dDtFim	:= sTod("")
	
If dDtParI < dDtContI
	dDtIni := dDtContI
Else
	dDtIni := dDtParI
EndIf
	
If dDtParF > dDtContF
	dDtFim := dDtContF
Else
	dDtFim := dDtParF
EndIf
	
nRet := (dDtFim - dDtIni) + 1

Return nRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetVlrHoras
	Calcula a quantidade prevista para o período considera do último lançamento não apurado até a data final da apuração
@since		23/09/2016
@author	Inovação Gestão de Serviços
@version	P12
@return	nRet - Numerico quantidade prevista para uso pelo equipamento
@param 		cCodTFI, Caracter, código do item de locação sendo calculada a apuração
@param 		dDtIniTFI, Data, dia inicial do item de locação
@param 		dDtFimTFI, Data, dia final do item de locação
@param 		nQtdTFI, Numérico, quantidade de equipamentos para serem alocados no item
@param 		nQtdTEV, Numérico, quantidade de horas para "consumo" pelo itens de locação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function GetVlrHoras( cCodTFI, dDtIniTFI, dDtFimTFI, nQtdTFI, nQtdTEV )
Local nQtPrevis := 0
Local nDifDiasLanc := 0
Local cAliasQry := GetNextAlias()
Local nTamFilTWT := AtTamFilTab( "TWT" )
Local cUltFilBas := ""
Local cUltBase := ""
Local dIniCalc := CTOD("")
Local dFimCalc := CTOD("")
Local lUltNaoApurado := .F.

BeginSQL Alias cAliasQry

	COLUMN TWT_DTMARC AS DATE

	SELECT TEW_FILIAL
		, TEW_CODEQU
		, TEW_FILBAT
		, TWT_CODAA3
		, TWT_DTMARC
		, TWT_HRMARC
		, TWT_CODMV
		, TWT_CODTFV
	FROM %Table:TEW% TEW
		LEFT JOIN %Table:TWT% TWT ON TWT_FILIAL = SUBSTRING( TEW_FILBAT, 1, %Exp:nTamFilTWT% )
								AND TWT_CODAA3 = TEW_BAATD
								AND TWT_CODMV = TEW_CODMV
								AND TWT.%NotDel%
	WHERE
		TEW_FILIAL = %xFilial:TEW%
		AND TEW_CODEQU = %Exp:cCodTFI%
		AND TEW.%NotDel%
	ORDER BY 2, 3, 4, 5, 6
EndSQL

While (cAliasQry)->(!EOF())

	If cUltFilBas == (cAliasQry)->TEW_FILBAT .And. cUltBase == (cAliasQry)->TWT_CODAA3
		//   caso seja a mesma base e o registro esteja apurado, troca a data inicial para
		// identificação do período não apurado
		If !Empty( (cAliasQry)->TWT_CODTFV )
			dIniCalc := (cAliasQry)->TWT_DTMARC
		EndIf
	Else
		//   calcula a quantidade de dias não apurados da base
		// quando percebe a troca da base ao percorrer o resultado da consulta
		// não soma dias quando só existe um registro para o equipamento (ou seja só existe a marcação da separação)
		If !Empty(cUltBase) .And. lUltNaoApurado .And. dFimCalc <> dIniCalc
			nDifDiasLanc += (dFimCalc - dIniCalc + 1 )
		EndIf
		// troca a base e a data de início
		cUltFilBas := (cAliasQry)->TEW_FILBAT
		cUltBase := (cAliasQry)->TWT_CODAA3
		dIniCalc := (cAliasQry)->TWT_DTMARC
	EndIf
	// sempre pega a data do registro pois pode ser o último
	dFimCalc := (cAliasQry)->TWT_DTMARC
	lUltNaoApurado := Empty((cAliasQry)->TWT_CODTFV)
	(cAliasQry)->(DbSkip())
End

//Calcula o último item que saiu pelo EOF
// não soma dias quando só existe um registro para o equipamento (ou seja só existe a marcação da separação)
If lUltNaoApurado .And. dFimCalc <> dIniCalc
	nDifDiasLanc += (dFimCalc - dIniCalc + 1)
EndIf

(cAliasQry)->(DbCloseArea())

// calcula o percentual que representa a quantidade de dias lançada e sem apuração
//  considerando os valores informados no contrato
nQtPrevis := ( nDifDiasLanc / ( ( dDtFimTFI - dDtIniTFI + 1 ) * nQtdTFI ) ) * nQtdTEV

Return nQtPrevis

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930SldCNB
Retorna o saldo disponivel a ser medido de um item da CNB
autor: Matheus Lando Raimundo
/*/
//------------------------------------------------------------------------------//
Function A930SldCNB(cContra,cRevisa,cPlan,cItem,lRetDados,cProd,cDesc)
Local nRet 	:= 0
Local aArea	:= GetArea()

CNB->(DbSetOrder(1))

If CNB->(DbSeek(xFilial('CN9')+ cContra + cRevisa + cPlan + cItem))
	nRet := CNB->CNB_SLDMED * CNB->CNB_VLUNIT
	If lRetDados
		cProd := CNB->CNB_PRODUT
		cDesc := CNB->CNB_DESCRI
	EndIf
EndIf

RestArea(aArea)
Return nRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} A930ViewCTR
View do Contrato

autor: Matheus Lando Raimundo

/*/
//------------------------------------------------------------------------------//
Function A930ViewCTR()
Local aArea	:= GetArea()
Local oModel	:= FwModelActive()
Local oTFVMaster := oModel:GetModel('TFVMASTER')

CN9->(DbSetOrder(1))
If CN9->(DbSeek(xFilial('CN9')+ oTFVMaster:GetValue('TFV_CONTRT') + oTFVMaster:GetValue('TFV_REVISA')))
	FwExecView(STR0087,'VIEWDEF.CNTA301',MODEL_OPERATION_VIEW)  // 'Visualizar'
EndIf
RestArea(aArea)
Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At930VldCNB
Valida o valor da CNB para medição e elimina os itens com saldo zerado para medição

autor: Matheus Lando Raimundo

/*/
//------------------------------------------------------------------------------//
Function At930VldCNB(aItem,aItemExc,aItnsRef,cCodTFL,cContra,cRevisa,cPlan)
Local lRet 	:= .T.
Local nI		:= 0
Local cProd	:= ""
Local cDesc	:= ""
Local nSldCNB	:= 0
Local cPict 	:= PesqPict("CNB","CNB_VLTOT")
Local nDecimal := X3Decimal("CNB_VLTOT")
Local cLocal	:= ""
Local aArea	:= GetArea()
Local cAviso	:= ""
Local nPos		:= 0
Local nVlrExc := 0
Local aLinDel	:= {}
Local nLmtMed	:= 0

For nI := 1 To Len(aItem)
	nSldCNB := A930SldCNB(cContra,cRevisa,cPlan,aItem[nI,1,2],.T.,@cProd,@cDesc)
	nLmtMed := Cn121LtMed(nSldCNB,cContra,cRevisa,cPlan)

	If nLmtMed > 0
		nSldCNB := nLmtMed
	Endif

	If Round(aItem[nI,2,2],nDecimal) > Round(nSldCNB,nDecimal) .and. At740Recor(cContra)
		lRet := .F.
		TFL->(DbSetOrder(1))
		TFL->(DbSeek(xFilial('TFL')+cCodTFL))
		cLocal := TFL->TFL_LOCAL
		nValor := 	aItem[nI,2,2]
		If nPos := Ascan(aItemExc,aItem[nI,1,2]) > 0
			nVlrExc := aItemExc[nPos,2,2]
		EndIf

		cAba := aItnsRef[Ascan(aItnsRef, {|x| x[1] == aItem[nI,1,2]}),2]
		cAviso 	+=  STR0116 + Alltrim(cAba) +  CRLF  ;  // 'Aba: '
				+ STR0117 + Alltrim(cLocal) +  CRLF;  // 'Local: '
		    	+ STR0118 + Alltrim(cPlan) + CRLF ;  // 'Planilha: '
		    	+ STR0119 + Alltrim(cProd) + ' - ' + Alltrim(cDesc) +  CRLF;  // 'Produto: '
		    	+ STR0120 + Alltrim(Transform(aItem[nI,2,2],cPict)) + CRLF ;  // 'Valor item medição: '
		    	+ STR0121 + Alltrim(Transform(nSldCNB,cPict)) + CRLF;  // 'Saldo item contrato: '
		    	+ STR0122 + Alltrim(Transform(aItem[nI,2,2] - nSldCNB,cPict)) + CRLF + CRLF  // 'Diferença: '
	ElseIf lRet .And. nSldCNB == 0
		Aadd(aLinDel,nI)
	EndIf

Next nI

If lRet
	aSort( aLinDel, , , {|x,y| x > y })
	For nI := 1 To Len(aLinDel)
		Adel(aItem,aLinDel[nI])
		Asize(aItem,Len(aItem)-1)
	Next nI
EndIf


If !lRet
	AtShowLog(Alltrim(cAviso), STR0123, .T., .T., .T.,.F.)  // 'Valor de medição superior ao saldo do(s) item(ns) do contrato'
EndIf


RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GetQt
Retorna a quantidade das movimentações

autor: Matheus Lando Raimundo

/*/
//------------------------------------------------------------------------------//
Function At930GetQt(cCodTFI,dDataFim)
Local cQuery		:= ""
Local cAliasTEW	:= GetNextAlias()
Local aRet			:= {}


cQuery		:= "SELECT TEW_QTDVEN, TWI.TWI_DTSAI, TWP.TWP_DTRET "
cQuery		+= " FROM " + RetSQLName("TEW") + " TEW "
cQuery		+= " INNER JOIN " + RetSQLName("TWI") + " TWI ON "
cQuery		+= " TWI_FILIAL = '" + xFilial("TWI") + "' AND "
cQuery		+= " TWI.D_E_L_E_T_ <> '*' AND "
cQuery		+= " TWI.TWI_IDREG = TEW.TEW_CODMV AND "
cQuery		+= " TWI.TWI_LIBERA = '1' "
cQuery		+= " LEFT JOIN " + RetSQLName("TWP") + " TWP ON "
cQuery		+= " TWP_FILIAL = '" + xFilial("TWP") + "' AND "
cQuery		+= " TWP.D_E_L_E_T_ <> '*' AND "
cQuery		+= " TWP.TWP_IDREG = TEW.TEW_CODMV "
cQuery		+= " WHERE TEW_CODEQU = '" + cCodTFI + "' AND "
cQuery		+= " TEW_FILIAL = '" + xFilial("TEW")+"' AND "
cQuery		+= " TEW_QTDVEN > 0 AND "
cQuery		+= " TEW.TEW_DTRINI <= '"+DTOS(dDataFim)+"' AND "
cQuery		+= " TEW.D_E_L_E_T_ = ' ' "

cQuery		:= ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN",TcGenQry(,,cQuery), cAliasTEW, .T., .T.)

While (cAliasTEW)->(!Eof())
	Aadd(aRet,{(cAliasTEW)->(TEW_QTDVEN),(cAliasTEW)->(TWI_DTSAI),(cAliasTEW)->(TWP_DTRET)})
	(cAliasTEW)->(DbSkip())
EndDo


(cAliasTEW)->(DbCloseArea())

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GetQt
Retorna a quantidade das movimentações

autor:

/*/
//------------------------------------------------------------------------------//
Static Function GetComplSc5(cCodLoc)
	Local aDataSC5 := {}
	Local aArea	:= GetArea()

	Default cCodLoc := ""

	//1* A partir do cod do local de atendimento, obtem a informação do C5_RECISS,  C5_ESTPRES E C5_MUNPRES
	If !(Empty(cCodLoc))
		dbSelectArea('ABS')

		ABS->(dbSetOrder(1))
		If ABS->(dbSeek(xFilial('ABS') + Padr(cCodLoc,TamSx3('ABS_LOCAL')[1]) ))
			aAdd(aDataSC5,{"C5_RECISS",ABS->ABS_RECISS})
			aAdd(aDataSC5,{"C5_ESTPRES",ABS->ABS_ESTADO})
			aAdd(aDataSC5,{"C5_MUNPRES",ABS->ABS_CODMUN})
		EndIf
	EndIf


	//3* Ponto de entrada para que campos de usuario ABS do cliente sejam direcionados para campos de usuario da SC5


	RestArea(aArea)
Return aDataSC5

//------------------------------------------------------------------------------
/*/{Protheus.doc}  GetMin(aDados)
Retorna a quantidade das movimentações

autor: Matheus Lando Raimundo

/*/
//------------------------------------------------------------------------------//
Function GetMin(aDados)

Asort(aDados)

Return aDados[1]

//------------------------------------------------------------------------------
/*/{Protheus.doc}  GetMax(aDados)

autor: Matheus Lando Raimundo

/*/
//------------------------------------------------------------------------------//
Function GetMax(aDados)

Asort(aDados)

Return aDados[Len(aDados)]



//------------------------------------------------------------------------------
/*/{Protheus.doc} At930SrvExtVld
Função para validar se é um orçamento de serviços extra e se ele está efetivado.

@param		cNumOrc, Caractere, Número do orçamento de serviços extra que será validado.

@return	Nil
@author	Serviços
@since		04/11/2013
@version	P11.9
/*/
//------------------------------------------------------------------------------
Function At930SrvExtVld(cNumOrc)

Local lRet := .F.
Local aArea    := GetArea()

DbSelectArea("TFJ")
TFJ->(DbSetOrder(1)) //TFJ_FILIAL+TFJ_CODIGO
If TFJ->(DbSeek(FwxFilial("TFJ")+cNumOrc)) .AND. TFJ->TFJ_SRVEXT == '1'
	lRet := .T.
EndIf

RestArea( aArea )

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At930VldCt()
Valida se Permite selecionar mesma competência para as medicoes
@sample 	At930VldCt(cNumCtr, cRevCtr)
@param		cNumCtr - Numero do Contrato, cRevCtr - Numero da Revisao do contrato
@return		lVldCtr - Lógico
@since		
@author	Heimdall Castro
@version	P12   
/*/
//--------------------------------------------------------------------------------------------------------------------


Static Function At930VldCr(cNumCtr, cRevCtr)

Local aArea   := GetArea()
Local lVldCtr := .F.
Local cCrFin  := POSICIONE("CN9",1,xFilial("CN9")+cNumCtr+cRevCtr,"CN9_UTMSCF")

If (cCrFin == "1")
	lVldCtr := .T.
EndIf

RestArea(aArea)

Return (lVldCtr)

/*/{Protheus.doc} At930PCab
Retorna a Posição do Cliente na estrutura de Apuração,
de acordo com o Tipo de Serviço recebido por parâmetro
@type function
@author Alison
@since 13/10/2016
@version 1.0
@param cContra, character, Número do Contrato
@param cRev, character, Revisão do Contrato
@param aCabApu, array, Array de Cabeçalho de Apuração
@param cCodTFL, character, Código da Tabela TFL
@param cOpcApu, character, Opção de Apuração
@return nPos, Posição no Array aCabApu
/*/
Static Function At930PCab(aCabApu, cCodTFL, cOpcApu, cLocal)
	Local nPos      := 0 //Posição no Cabeçalho

	DbSelectArea("TWW")
	TWW->(DbSetOrder(2))//TWW_FILIAL + TWW_CHAVE+TWW_LOCAL
	
	nPos := aScan( aCabApu, { |x| x[01] + x[07] == cCodTFL + cOpcApu } )
	
	//Caso não encontre Cliente para o Serviço, Buscar o Padrão de Faturamento
	If (nPos == 0)
		nPos := aScan( aCabApu, { |x| x[1] == cCodTFL } )	
	Else
		If TWW->(dbSeek(xFilial("TWW")+aCabApu[nPos, 10]+cLocal))
			aCabApu[nPos, 08] := TWW->&('TWW_CLIE' + cOpcApu)
			aCabApu[nPos, 09] := TWW->&('TWW_LOJA' + cOpcApu)
		EndIf
	EndIf

Return nPos

//------------------------------------------------------------------------------
/*/	{Protheus.doc} AtTec930FS
Interface de seleção de opções de Faturamento | Fatura Separado  
@sample	 	AtTec930FS()
@since		09/09/2016
@author		Fernando Alves Silva
@version	P12   
/*/
//------------------------------------------------------------------------------//
Static Function AtTec930FS(oView)  

Local aButtons 	:= {}
Local lOk 		:= .F.	
Local oRadDA	:= Nil
Local oRadHE	:= Nil
Local oGrpPar1	:= Nil
Local oGrpPar2	:= Nil 
Local oGrpPar3	:= Nil
Local oSay1		:= Nil  
Local oSay2		:= Nil	
Local oSay3		:= Nil
Local oSay4		:= Nil
Local oSay5		:= Nil
Local nX		:= 1
Local oModel	:= FwModelActive()
Local nOpcao	:= oModel:GetOperation()
Local aItes1	:= {}
Local aItems2	:= {}
Local nRad1Bak 	:= nOpcDA
Local nRad2Bak 	:= nOpcHE

 
Private cCadastro := STR0137 //"Opções de Faturamento"

DEFINE DIALOG oDlg TITLE STR0140 FROM 180,180 TO 365,635 PIXEL    //"FATURA SEPARADO"
          
aItems1 := {' ',' ',' '}
aItems2 := {' ',' ',' '}    

@ 033, 050  GROUP oGrpPar1 TO 090, 100 	PROMPT "" 		OF oDlg PIXEL
@ 033, 050  GROUP oGrpPar1 TO 050, 100 	PROMPT "" 		OF oDlg PIXEL

@ 033, 110 	GROUP oGrpPar2 TO 090, 160 	PROMPT "" 		OF oDlg PIXEL
@ 033, 110 	GROUP oGrpPar2 TO 050, 160 	PROMPT "" 		OF oDlg PIXEL

@ 033, 170  GROUP oGrpPar3 TO 090, 220 	PROMPT "" 		OF oDlg PIXEL
@ 033, 170  GROUP oGrpPar3 TO 050, 220 	PROMPT "" 		OF oDlg PIXEL

@ 038, 055 SAY	oSay1 PROMPT STR0141  	SIZE 245, 011 OF oDlg PIXEL //"Mesma Fatura"  
@ 038, 115 SAY	oSay2 PROMPT STR0142  	SIZE 245, 011 OF oDlg PIXEL //"Fatura Indvidual"
@ 038, 175 SAY	oSay3 PROMPT STR0143  	SIZE 245, 011 OF oDlg PIXEL //"Aglutina Fatura" 

@ 055, 005 SAY	oSay4 PROMPT STR0144  	SIZE 245, 011 OF oDlg PIXEL //"Desp. Adicionais"
@ 075, 005 SAY	oSay5 PROMPT STR0145	SIZE 245, 011 OF oDlg PIXEL //"Horas Extras"

oRadDA := TRadMenu():New (55,55,aItems1,,oDlg,, {|| IIF(nOpcDA == 3, oRadHE:SetOption(3), IIF(nOpcHE == 3,oRadHE:SetOption(1),oRadHE:SetOption(nOpcHE)) )} ,,,,,,180,12,,,,.T.,.T.)
oRadHE := TRadMenu():New (75,55,aItems2,,oDlg,, {|| IIF(nOpcHE == 3, oRadDA:SetOption(3), IIF(nOpcDA == 3,oRadDA:SetOption(1),oRadDA:SetOption(nOpcDA)) )} ,,,,,,180,12,,,,.T.,.T.)     

If nOpcao = 1 //Visualizar - Desabilita opções
	For nX := 1 to 3
		oRadDA:Disable(nX)
		oRadHE:Disable(nX)
	Next nX
EndIf

oRadDA:bSetGet := {|u|Iif (PCount()==0,nOpcDA,nOpcDA:=u)}	  
oRadHE:bSetGet := {|u|Iif (PCount()==0,nOpcHE,nOpcHE:=u)}

ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg,{||lOk:=.T.,oDlg:End()},{||oDlg:End()},,@aButtons,,,,,.F.))

If !lOk
	nOpcDA 	:= nRad1Bak
	nOpcHE	:= nRad2Bak 
EndIf

Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} A930FatSep
Função Responsável por localizar a configuração de Faturamento do Contrato
@sample	 	A930FatSep()
@param		cContrato - Número do Contrato Atual
@return		aRet - Array
@since		03/01/2017
@author		Fernando Alves Silva
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930FatSep(cContrato, nOrder)

Local aRet	 := {1,1}

DbSelectArea("T42")
DbSetOrder(nOrder)

If ValType(cContrato) == "C"
	If T42->(DbSeek(xFilial("T42")+cContrato))
		aRet:= {}
		aAdd(aRet, Val(T42->T42_FATDAD) )
		aAdd(aRet, Val(T42->T42_FATHEX) )	
	EndIf
EndIf

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930MultFS
Verifica a existência de Despesas Adicionais.
@sample	 	A930MultFS()
@return		aMultas - Array com Despesas Adicionais encontradas 
@since		03/03/2017
@author		Fernando Alves Silva
@version	P12   
/*/
//------------------------------------------------------------------------------

Function A930MultFS(oModel,nVlrMulta,nVlrBoni,nVlrDASep,lFatDASep)
Local oModelTFW := oModel:GetModel("TFWDETAIL")
Local oModelTFX := oModel:GetModel("TFXDETAIL")
Local oModelTFY := oModel:GetModel("TFYDETAIL")
Local oModelTFL := oModel:GetModel("TFLDETAIL")
Local oModelTFI := oModel:GetModel("TFIPRODUT")
Local oModelTFWMUL := oModel:GetModel("TFWTW7DETAIL")
Local oModelTFXMUL := oModel:GetModel("TFXTW7DETAIL")
Local oModelTFYMUL := oModel:GetModel("TFYTW7DETAIL")
Local oModelTFLMUL := oModel:GetModel("TFITW7DETAIL")
Local nTot 		:= 0
Local lAddMult	:= .T.
Local nX		:= 0
Local nY		:= 0
Local nJ		:= 0
Local aMultas	:= {}
Local aSaveLines	:= FWSaveRows()

Default nVlrMulta := 0

For nX := 1 To oModelTFW:Length()
	oModelTFW:GoLine(nX)
	If !oModelTFW:IsDeleted() .and. oModelTFW:GetValue("TFW_VLRMED") > 0
		For nY := 1 To oModelTFWMUL:Length()
			oModelTFWMUL:GoLine(nY)
			If !oModelTFWMUL:IsDeleted() .And. !Empty(oModelTFWMUL:GetValue('TW7_VALOR')) 
								
				If oModelTFWMUL:GetValue("TW7_DESPAD")=='1'
					If lFatDASep
						lAddMult := .F.
					Else
						lAddMult := .T.
					EndIf
				Else
					lAddMult := .F.
				EndIf
							
				If lAddMult
					aAdd(aMultas,Array(6))	
																
					aTail(aMultas)[1] := oModelTFWMUL:GetValue("TW7_TPMOV")
					aTail(aMultas)[2] := oModelTFWMUL:GetValue("TW7_DESCRI")  
					aTail(aMultas)[3] := oModelTFWMUL:GetValue("TW7_VALOR")
					aTail(aMultas)[4] := oModelTFWMUL:GetValue("TW7_MODO") 
					aTail(aMultas)[5] := oModelTFWMUL:GetValue("TW7_FLGPED")
					
					If oModelTFWMUL:GetValue("TW7_TPMOV") == '1'
						nVlrMulta += oModelTFWMUL:GetValue("TW7_VALOR")									
					ElseIf oModelTFWMUL:GetValue("TW7_TPMOV") == '2'
						nVlrBoni += oModelTFWMUL:GetValue("TW7_VALOR")									
					EndIf					
				Else
					If lFatDASep .And. oModelTFWMUL:GetValue("TW7_DESPAD")=='1' 	
						nVlrDASep += oModelTFWMUL:GetValue("TW7_VALOR")
					EndIf 
				EndIf
				
			EndIf
		Next nY
	EndIf		
Next nX

For nX := 1 To oModelTFL:Length()	
	oModelTFL:GoLine(nX)
	If !oModelTFL:IsDeleted()
		For nY := 1 To oModelTFI:Length()
			oModelTFI:GoLine(nY)
			If !oModelTFI:IsDeleted()
				For nJ := 1 To oModelTFLMUL:Length()
					oModelTFLMUL:GoLine(nJ)
					If !oModelTFLMUL:IsDeleted() .And. !Empty(oModelTFLMUL:GetValue('TW7_VALOR'))
						If oModelTFLMUL:GetValue("TW7_DESPAD")=='1'
							If lFatDASep
								lAddMult := .F.
							Else
								lAddMult := .T.
							EndIf
						Else
							lAddMult := .F.
						EndIf
									
						If lAddMult
							aAdd(aMultas,Array(6))	
																		
							aTail(aMultas)[1] := oModelTFLMUL:GetValue("TW7_TPMOV")
							aTail(aMultas)[2] := oModelTFLMUL:GetValue("TW7_DESCRI")  
							aTail(aMultas)[3] := oModelTFLMUL:GetValue("TW7_VALOR")
							aTail(aMultas)[4] := oModelTFLMUL:GetValue("TW7_MODO") 
							aTail(aMultas)[5] := oModelTFLMUL:GetValue("TW7_FLGPED")
							
							If oModelTFLMUL:GetValue("TW7_TPMOV") == '1'
								nVlrMulta += oModelTFLMUL:GetValue("TW7_VALOR")									
							ElseIf oModelTFLMUL:GetValue("TW7_TPMOV") == '2'
								nVlrBoni += oModelTFLMUL:GetValue("TW7_VALOR")									
							EndIf					
						Else
							If lFatDASep .And. oModelTFLMUL:GetValue("TW7_DESPAD")=='1' 	
								nVlrDASep += oModelTFLMUL:GetValue("TW7_VALOR")
							EndIf 
						EndIf						  
					EndIf
				Next nJ											 				
			EndIf
		Next nY
	EndIf		
Next nX

FWRestRows(aSaveLines)
Return aMultas                                       

//------------------------------------------------------------------------------
/*/{Protheus.doc}  At930DscTp()
	Inicializador padrão da descrição do tipo de desconto.
Autor: Kaique Schiller Olivero

/*/
//------------------------------------------------------------------------------//
Function At930DscTp()
Local cTpDesc	:= TW6->TW6_TPDESC
Local cDescri 	:= ""

If !Empty(cTpDesc)
	DbSelectArea("CNP")
	CNP->(DbSetOrder(1))
	If !INCLUI .And. CNP->(DbSeek(xFilial("CNP")+cTpDesc))
		cDescri := CNP->CNP_DESCRI
	Endif
	CNP->(DbCloseArea())
Endif

Return cDescri


//------------------------------------------------------------------------------
/*/{Protheus.doc}  At930CntRec()
	Rotina para tratamentos de contrato recorrente ao selecionar o contrato no pergunte TEC930.
Autor: Kaique Schiller Olivero

/*/
//------------------------------------------------------------------------------//
Function At930CntRec(cAcao)
Local aArea			:= GetArea()
Local lRet 			:= .T.
Local cContr		:= MV_PAR01
Local cRevis 		:= ""
Local nMonth      	:= Month(dDataBase) 
Local nYear       	:= Year(dDataBase)

If cAcao == '1'
	
	If !lSrvExt  
		If Empty(MV_PAR01)
			lRet := .F.
			Help( "", 1, "At930CntRec", ,STR0139, 1, 0,,,,,,; //"Para Apuração/Medição de Contratos Normais é Necessário informar o número do Contrato"  
			{STR0161}) //"Informe o número do Contrato"
			If !lTeca934
				MV_PAR05 := Space(TamSX3("TFJ_CODIGO")[1])
			EndIf
		EndIf
	Else
		MV_PAR01 := Space(TamSX3("CN9_NUMERO")[1]) 
	Endif 
	
ElseIf cAcao == '4'

	If !lSrvExt 
		Help( "", 1, "At930CntRec", , STR0162, 1, 0,,,,,,;  //"Para Apuração/Medição de Contratos Normais não é necessário preencher este campo"
		{STR0163}) //"Atenção"
		If lTeca934
			MV_PAR05 := Space(TamSX3("TFJ_CODIGO")[1])
		EndIf
	Else
		If Empty(MV_PAR05) 
			lRet := .F.
			Help( "", 1, "At930CntRec", , STR0164, 1, 0,,,,,,; //"Para Apuração/Medição de Orçamento de Serv. Extra é Necessário informar o número do Orçamento"  
			{STR0165}) //"Informe o número do Orçamento"		
		EndIf
		MV_PAR01 := Space(TamSX3("CN9_NUMERO")[1]) 
	Endif 

Else
	lRet := .T.
EndIF

If lRet 
	If !Empty(cContr)
		cRevis := Posicione("CN9",7,xFilial("CN9")+cContr+"05","CN9_REVISA")
		DbSelectArea("TFJ")
		TFJ->(DbSetOrder(5)) //TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
		If TFJ->(DbSeek(xFilial("TFJ")+cContr+cRevis))
			If TFJ->TFJ_CNTREC == "1"
				If cAcao == "1"
					MV_PAR02 := FirstDate(dDataBase)
					MV_PAR03 := LastDate(dDataBase)
					MV_PAR04 := SubStr(cValTochar(dDataBase),4,2)+"/"+SubStr(cValTochar(dDataBase),7,4)
					If lTeca934
						If nMonth == 1
							nYear := nYear-1
							nMonth := 12
						Else
							nMonth := nMonth-1
						EndIf
						MV_PAR05 := CTOD("01/"+StrZero(nMonth,2)+"/" + Str(nYear) )
						MV_PAR06 :=  LastDate(CTOD("01/"+StrZero(nMonth,2)+"/" + Str(nYear) ))
						MV_PAR07 := SubStr(cValTochar(MV_PAR05),4,2)+"/"+SubStr(cValTochar(MV_PAR06),7,4)					
					EndIf
				Elseif cAcao == "2"
					If !Empty(MV_PAR04)
						MV_PAR02 := FirstDate(Ctod("01/"+MV_PAR04))
						MV_PAR03 := LastDate(Ctod("01/"+MV_PAR04))
					Endif
					If lTeca934
						If !Empty(MV_PAR07)
							MV_PAR05 := FirstDate(Ctod("01/"+MV_PAR07))
							MV_PAR06 := LastDate(Ctod("01/"+MV_PAR07))
						Endif
					EndIf	
				Elseif cAcao == "3"
					If !Empty(MV_PAR04)
						If Len(SubStr(cValTochar(MV_PAR04),1,2)) == 2 .And. Len(SubStr(cValTochar(MV_PAR04),4,4)) == 4;
																	  .And. Val(SubStr(cValTochar(MV_PAR04),1,2)) >= 1;
																	  .And. Val(SubStr(cValTochar(MV_PAR04),1,2)) <= 12																  
							MV_PAR02 := FirstDate(Ctod("01/"+MV_PAR04))
							MV_PAR03 := LastDate(Ctod("01/"+MV_PAR04))
						Else
							lRet := .F.
							Help( "", 1, "At930CntRec", , STR0131, 1, 0,,,,,,;  //"Vigência inválida."
							{STR0132}) // "Informe a vigência corretamente."
						Endif
					Else
						lRet := .F.
						Help( "", 1, "At930CntRec", , STR0133, 1, 0,,,,,,;  //"É necessário informar uma data de vigência para contrato recorrente."
						{STR0132}) // "Informe a vigência corretamente."
					Endif
					
					If lTeca934
					
						If !Empty(MV_PAR07)
							If Len(SubStr(cValTochar(MV_PAR07),1,2)) == 2 .And. Len(SubStr(cValTochar(MV_PAR07),4,4)) == 4;
																		  .And. Val(SubStr(cValTochar(MV_PAR07),1,2)) >= 1;
																		  .And. Val(SubStr(cValTochar(MV_PAR07),1,2)) <= 12																  
								MV_PAR05 := FirstDate(Ctod("01/"+MV_PAR07))
								MV_PAR06 := LastDate(Ctod("01/"+MV_PAR07))
							Else
								lRet := .F.
								Help( "", 1, "At930CntRec", , STR0131, 1, 0,,,,,,;  //"Vigência inválida."
								{STR0132}) // "Informe a vigência corretamente."
							Endif
						Else
							lRet := .F.
							Help( "", 1, "At930CntRec", , STR0133, 1, 0,,,,,,;  //"É necessário informar uma data de vigência para contrato recorrente."
							{STR0132}) // "Informe a vigência corretamente."
						Endif
					
					EndIf
				Endif
			Else
				MV_PAR04 := ""
				If lTeca934
					MV_PAR07 := ""
				EndIf
			Endif
		Endif
	Endif
Endif

RestArea(aArea)

Return lRet

/*/{Protheus.doc} At934IsFAnt
@description 	Verifica se um contrato está indicado como faturamento antecipado.
@author 		josimar.assuncao
@since 			20.04.2017
@param 			cContrato, caracter, número do contrato.
@return 		Lógico, indica se o contrato está indicado como faturamento antecipado.
/*/
Static Function At934IsFAnt( cContrato )
Local lRet 			:= .F.
Local cRevisao 		:= Posicione("CN9",7,xFilial("CN9")+cContrato+"05","CN9_REVISA")

// TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
lRet := (Posicione( "TFJ", 5, xFilial("TFJ")+cContrato+cRevisao, "TFJ_ANTECI" ) == "1" )

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} at930GFCAB
Função responsável por atualizar o cabeçalho de geração de PV para Grupo de Fat.
@sample	 	at930GFCAB()
@return		aGrpFat - Array contendo o Cabec dos Pedidos de Venda
@since		14/08/2017
@author		Fernando Alves Silva
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function at930GFCAB(aLocPed)

Local cQry1			:= ""
Local aGrpFat		:= {}
Local nI			:= 0 
Local cAliasTWW	 	:= GetNextAlias()


For nI := 1 to Len(aLocPed)

	cQry1	:= "SELECT * FROM" +  RetSqlName("TWW") + " WHERE TWW_NUMERO = '"+aLocPed[nI][8]+"' AND TWW_LOCAL = '"+aLocPed[nI][7]+"' AND D_E_L_E_T_ = ''
	cQry1	:= ChangeQuery(cQry1)	
	DbUseArea(.T., "TOPCONN",TcGenQry(,,cQry1), cAliasTWW, .T., .T.)	
	
	While (cAliasTWW)->(!Eof())
		
		nPosRH := aScan(aGrpFat, {|x| x[7] + x[3] + x[4] == aLocPed[nI][7] + (cAliasTWW)->TWW_CLIERH + (cAliasTWW)->TWW_LOJARH  })	
		If nPosRH == 0		
			aAdd(aGrpFat,{	aLocPed[nI][1]			,; 
							aLocPed[nI][2]			,; 
							(cAliasTWW)->TWW_CLIERH	,; 
							(cAliasTWW)->TWW_LOJARH	,; 
							aLocPed[nI][5]			,; 
							aLocPed[nI][6]			,; 
							aLocPed[nI][7]			,; 
							aLocPed[nI][8] 			})
		EndIf
		
		nPosMI := aScan(aGrpFat, {|x| x[7] + x[3] + x[4] == aLocPed[nI][7] + (cAliasTWW)->TWW_CLIEMI + (cAliasTWW)->TWW_LOJAMI  })
		If nPosMI == 0	
			aAdd(aGrpFat,{	aLocPed[nI][1]			,; 
							aLocPed[nI][2]			,; 
							(cAliasTWW)->TWW_CLIEMI	,; 
							(cAliasTWW)->TWW_LOJAMI	,; 
							aLocPed[nI][5]			,; 
							aLocPed[nI][6]			,; 
							aLocPed[nI][7]			,; 
							aLocPed[nI][8] 			})
		EndIf

		nPosMC := aScan(aGrpFat, {|x| x[7] + x[3] + x[4] == aLocPed[nI][7] + (cAliasTWW)->TWW_CLIEMC + (cAliasTWW)->TWW_LOJAMC  })
		If nPosMC == 0			
			aAdd(aGrpFat,{	aLocPed[nI][1]			,; 
							aLocPed[nI][2]			,; 
							(cAliasTWW)->TWW_CLIEMC	,; 
							(cAliasTWW)->TWW_LOJAMC	,; 
							aLocPed[nI][5]			,; 
							aLocPed[nI][6]			,; 
							aLocPed[nI][7]			,; 
							aLocPed[nI][8] 			})
		EndIf
		
		nPosLE := aScan(aGrpFat, {|x| x[7] + x[3] + x[4] == aLocPed[nI][7] + (cAliasTWW)->TWW_CLIELE + (cAliasTWW)->TWW_LOJALE  })
		If nPosLE == 0			
			aAdd(aGrpFat,{	aLocPed[nI][1]			,; 
							aLocPed[nI][2]			,; 
							(cAliasTWW)->TWW_CLIELE	,; 
							(cAliasTWW)->TWW_LOJALE	,; 
							aLocPed[nI][5]			,; 
							aLocPed[nI][6]			,; 
							aLocPed[nI][7]			,; 
							aLocPed[nI][8] 			})
		EndIf
		
		nPosHE := aScan(aGrpFat, {|x| x[7] + x[3] + x[4] == aLocPed[nI][7] + (cAliasTWW)->TWW_CLIEHE + (cAliasTWW)->TWW_LOJAHE  })
		If nPosHE == 0		
			aAdd(aGrpFat,{	aLocPed[nI][1]			,; 
							aLocPed[nI][2]			,; 
							(cAliasTWW)->TWW_CLIEHE	,; 
							(cAliasTWW)->TWW_LOJAHE	,; 
							aLocPed[nI][5]			,; 
							aLocPed[nI][6]			,; 
							aLocPed[nI][7]			,; 
							aLocPed[nI][8] 			})
		EndIf

		nPosAD := aScan(aGrpFat, {|x| x[7] + x[3] + x[4] == aLocPed[nI][7] + (cAliasTWW)->TWW_CLIEAD + (cAliasTWW)->TWW_LOJAAD  })
		If nPosAD == 0			
			aAdd(aGrpFat,{	aLocPed[nI][1]			,; 
							aLocPed[nI][2]			,; 
							(cAliasTWW)->TWW_CLIEAD	,; 
							(cAliasTWW)->TWW_LOJAAD	,; 
							aLocPed[nI][5]			,; 
							aLocPed[nI][6]			,; 
							aLocPed[nI][7]			,; 
							aLocPed[nI][8] 			})
		EndIf
		
		(cAliasTWW)->(DbSkip())
	EndDo
	(cAliasTWW)->(DbCloseArea())
Next nI

Return aGrpFat

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GFIT
Função Responsável por Verificar o cliente configurado no Grupo de Faturamento
de acordo com cada Tipo de Serviço (RH, MI, MC, LE , AD e HE) e em seguida 
montar a chave responsável pelo agrupamento do Pedido de Vendas.
@sample	 	At930GFIT()
@return		cChaveRet - Chave Responsável pelo Agrupamento
@since		14/08/2017
@author		Fernando Alves Silva
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At930GFIT(cLocal, cOrcSer, cOpcApu, cCliente, cLoja)

Local cQry1   := ""
Local cChaveRet  := ""

 DbSelectArea("TWW")
 TWW->(DbSetOrder(1))//TWW_FILIAL + TWW_NUMERO+TWW_LOCAL
 
  If TWW->(dbSeek(xFilial("TWW")+cOrcSer+cLocal))
	   cCliente := TWW->&('TWW_CLIE' + cOpcApu)
	   cLoja := TWW->&('TWW_LOJA' + cOpcApu)
	   cChaveRet := cLocal + cCliente+ cLoja
	   
  EndIf

Return cChaveRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GtDc
Pega todos os tipos de descontos nas abas
@sample	 	At930GtDc()
@return		aTipoDsc - Todos os tipos de descontos em todas as abas.
@since		01/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At930GtDc(cPlan,cContra,cRevisa,cCmpPlan,cCmpLoc,oGrid,oGridDes,oGridLoc,aTipoDsc)
Local nTot 			:= 0
Local nX			:= 0
Local nY			:= 0
Local nJ			:= 0
Local nZ			:= 0
Local aSaveLines	:= FWSaveRows()
Default cCmpPlan	:= ""
Default oGrid		:= Nil
Default oGridDes	:= Nil
Default oGridLoc	:= Nil

For nX := 1 To oGrid:Length()
	oGrid:GoLine(nX)
	If !oGrid:IsDeleted() .And. oGrid:GetValue(cCmpPlan) == cPlan
		If oGridLoc <> Nil
			For nX := 1 To oGridLoc:Length()
				oGridLoc:GoLine(nX)
				For nY := 1 To oGridDes:Length()
					oGridDes:GoLine(nY)
					If !oGridDes:IsDeleted() .And. !Empty(oGridDes:GetValue("TW6_TPDESC"))
						aAdd(aTipoDsc,{oGridDes:GetValue("TW6_TPDESC"),; //Tipo de desconto 
									   oGridDes:GetValue("TW6_VALOR")})  //Valor
					EndIf
				Next nY
			Next nX
		Else
			For nY := 1 To oGridDes:Length()
				oGridDes:GoLine(nY)
				If !oGridDes:IsDeleted() .And. !Empty(oGridDes:GetValue("TW6_TPDESC"))				
					aAdd(aTipoDsc,{oGridDes:GetValue("TW6_TPDESC"),; //Tipo de desconto 
								   oGridDes:GetValue("TW6_VALOR")})  //Valor
				EndIf
			Next nY
		Endif
	EndIf
Next nX

FWRestRows(aSaveLines)

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930VldMt
Validação dos materiais por valor
@sample	 	At930VldMt()
@return		lRet 
@since		01/11/2017
@author		Kaique Schiller
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At930VldMt(cCodTFF,nVlr,cGsMt)
Local lRet 		:= .T.
Local aAreaTFF	:= TFF->(GetArea())
Default cCodTFF := ""
Default nVlr 	:= 0
Default cGsMt	:= ""

If !Empty(cCodTFF) .And. nVlr < 0
	lRet := .F.
	Help( "", 1, "At930VldMt", , STR0166, 1, 0,,,,,,;  //"Não é possível inserir um valor menor que zero."
	{STR0167}) //"Informe um valor maior que zero."
Endif

If lRet .And. !Empty(cCodTFF)
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))
	If TFF->(dbSeek(xFilial("TFF")+cCodTFF))
		If cGsMt == "1"
			If nVlr > TFF->TFF_VLMTMI
				lRet := .F.
			Endif
		Elseif cGsMt == "2"
			If nVlr > TFF->TFF_VLMTMC
				lRet := .F.
			Endif
		Endif
		If !lRet
			Help( "", 1, "At930VldMt", , STR0168, 1, 0,,,,,,;  //"Não é possível inserir um valor maior que o orçamento de serviços."
			{STR0169}) //"Informe um valor menor que o orçamento de serviços."
		Endif
	Endif
Endif

RestArea(aAreaTFF)

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930GrvTWQ
Função para gravação da tabela TWQ - Despesas adicionais
@sample	 	A930GrvTWQ()
@return		lRet 
@since		18/12/2017
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930GrvTWQ(lSrvExt,aLocPedX,cLocPlan, cNumMed, cNumPed, dDataIni, dDataFim, lGrpFat)
	Local lRet := .T.
	Local aArea := GetArea()
	Local nPos := 0
	//Grupo de Faturamento
	Local cPlanRH	:= ""
	Local cPlanLE	:= ""
	
	Default cLocPlan := ""
	Default lGrpFat := .F.
	
	DbSelectArea("TWQ") 
	
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))//TFF_FILIAL + TFF_COD
	
	DbSelectArea("TFI")
	TFI->(DbSetOrder(1))//TFI_FILIAL + TFI_COD
	
	DbSelectArea("TFL")
	TFL->(DbSetOrder(1))//TFL_FILIAL + TFL_CODIGO	
	
	If lSrvExt .and. (nPos := aScan( aLocPedX, { |x| x[06] == cLocPlan })) > 0

		// --------------------------------------------------
		// Gravação do Flag na Tabela de Despesas Adicionais
		// --------------------------------------------------
		
		TWQ->(DbGoTop())
		TWQ->(DbSetOrder(4))
			
		If TWQ->(DbSeek(xFilial("TWQ")+aLocPedX[nPos][5]))
			While TWQ->(!Eof()) .And. TWQ->TWQ_ORCEXT == aLocPedX[nPos][5]
				If !Empty(TWQ->TWQ_POSTRH) 
					If TFF->(DbSeek(xFilial("TFF")+TWQ->TWQ_POSTRH)) .and. TFF->TFF_LOCAL == aLocPedX[nPos][6]
						If (TWQ->TWQ_DATA >= dDataIni .And. TWQ->TWQ_DATA <= dDataFim)
							Reclock("TWQ", .F. )
								TWQ->TWQ_PEDIDO := cNumPed			
							TWQ->(MsUnlock())
						EndIf
					EndIF
				EndIf
				If !Empty(TWQ->TWQ_POSTLE) .AND. TFI->(DbSeek(xFilial("TFI")+TWQ->TWQ_POSTLE))
					If TFL->(DbSeek(xFilial("TFL")+TFI->TFI_CODPAI)) .AND. TFL->TFL_LOCAL == aLocPedX[nPos][6]
						If (TWQ->TWQ_DATA >= dDataIni .And. TWQ->TWQ_DATA <= dDataFim)
							Reclock("TWQ", .F. )
								TWQ->TWQ_PEDIDO := cNumPed				
							TWQ->(MsUnlock())
						EndIf
					EndIf
				EndIf
				
				TWQ->(DbSkip())
			EndDo     
		EndIf //If TWQ->(DbSeek(xFilial("TWQ")+aLocPedX[nPos][5])) 		
	Else	
	

		TWQ->(DbGoTop())
		TWQ->(DbSetOrder(2))
		
		If TWQ->(DbSeek(xFilial("TWQ")+aLocPedX[1][4]))
			While TWQ->(!Eof()) .And. TWQ->TWQ_CONTRT == aLocPedX[1][4]
				If (TWQ->TWQ_DATA >= dDataIni .And. TWQ->TWQ_DATA <= dDataFim)
					If !EMPTY(TWQ->TWQ_POSTRH) //Despesa Adicional de RH
						If TFF->(DbSeek(xFilial("TFF")+TWQ->TWQ_POSTRH))
							If TFL->(DbSeek(xFilial("TFL")+TFF->TFF_CODPAI)) 
								If lGrpFat
									At870GrPlan( aLocPedX[1][7], TFF->TFF_LOCAL, @cPlanRH)
								Else
									cPlanRH	:= TFL->TFL_PLAN
								EndIf
								If cPlanRH == cLocPlan
									Reclock("TWQ", .F. )
										TWQ->TWQ_PEDIDO := cNumPed
										TWQ->TWQ_NUMMED	:= cNumMed  				
									TWQ->(MsUnlock())
								Endif //cPlanRH == cLocPlan
							Endif //TFL->(DbSeek(xFilial("TFL")+TFF->TFF_CODPAI))
						Endif //TFF->(DbSeek(xFilial("TFF")+TWQ->TWQ_POSTRH))
					EndIf //!EMPTY(TWQ->TWQ_POSTRH)
					
					If !EMPTY(TWQ->TWQ_POSTLE) //Despesa Adicional Locação de equipamento
						If TFI->(DbSeek(xFilial("TFI")+TWQ->TWQ_POSTLE))
							If TFL->(DbSeek(xFilial("TFL")+TFI->TFI_CODPAI)) 
							
								If lGrpFat
									At870GrPlan( aLocPedX[1][7],TFI->TFI_LOCAL,,,, @cPlanLE )
								Else
									cPlanLE	:= TFL->TFL_PLAN
								EndIf
				
								If cPlanLE == cLocPlan
									Reclock("TWQ", .F. )
										TWQ->TWQ_PEDIDO := cNumPed
										TWQ->TWQ_NUMMED	:= cNumMed  				
									TWQ->(MsUnlock())
								Endif
							Endif //TFL->(DbSeek(xFilial("TFL")+TFI->TFI_CODPAI)) 
						Endif //TFI->(DbSeek(xFilial("TFI")+TWQ->TWQ_POSTLE))
					EndIf //!EMPTY(TWQ->TWQ_POSTLE)
				Endif //(TWQ->TWQ_DATA >= dDataIni .And. TWQ->TWQ_DATA <= dDataFim)
				TWQ->(DbSkip())
			EndDo   
		EndIf // TWQ->(DbSeek(xFilial("TWQ")+aLocPedX[1][4])) 
	Endif //lSrvExt .and. (nPos := aScan( aLocPedX, { |x| x[06] == cLocPlan })) > 0								
	
	RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930EstTWQ
Função para limpar da tabela TWQ - Despesas adicionais
@sample	 	A930EstTWQ()
@return		lRet 
@since		18/12/2017
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930EstTWQ(lSrvExt,cCodRef,cNumMed, cNumPed, dDataIni, dDataFim)
	Local lRet := .T.
	Local aArea := GetArea()

		
	DbSelectArea("TWQ") 
	
	If lSrvExt 

		// --------------------------------------------------
		// Gravação do Flag na Tabela de Despesas Adicionais
		// --------------------------------------------------
		
		TWQ->(DbGoTop())
		TWQ->(DbSetOrder(4))
		If TWQ->(dbSeek(xFilial("TWQ")+cCodRef))
			While TWQ->(!Eof()) .And. TWQ->TWQ_ORCEXT == cCodRef
				If !Empty(TWQ->TWQ_PEDIDO) .AND. TWQ->TWQ_PEDIDO == cNumPed
					If (TWQ->TWQ_DATA >= dDataIni .And. TWQ->TWQ_DATA <= dDataFim)
						Reclock("TWQ",.F.)
							TWQ->TWQ_PEDIDO := ""
						TWQ->(MsUnlock())
					EndIf
				EndIf
				TWQ->(dbSkip())
			EndDo	
		EndIf 		
	Else	
		TWQ->(DbGoTop())
		TWQ->(DbSetOrder(2))
		
		If TWQ->(dbSeek(xFilial("TWQ")+cCodRef))
			While TWQ->(!Eof()) .And. TWQ->TWQ_CONTRT == cCodRef
				If !Empty(TWQ->TWQ_NUMMED) .AND. TWQ->TWQ_NUMMED == cNumMed
					If (TWQ->TWQ_DATA >= dDataIni .And. TWQ->TWQ_DATA <= dDataFim)
						Reclock("TWQ",.F.)
							TWQ->TWQ_PEDIDO := ""
							TWQ->TWQ_NUMMED := ""
						TWQ->(MsUnlock())
					EndIf
				EndIf
				TWQ->(dbSkip())
			EndDo	
		EndIf
	Endif								
	
	RestArea(aArea)
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930GerPlan
Função montar os dados da medição no array aPlan
@sample	 	A930GerPlan
@return		aPlan
@since		24/01/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930GerPlan(aPlan, aCabApu,nPosCab,nVlrMed, cCodCli, cLoja, cNumMed, cChaveQbr, cCodLocal, cItem, aPlanHE, aItnsRef, nVlrINSS)
	Local aPlanItem := {}
	
	Default nVlrINSS := 0
	
	aAdd(aPlanItem	, {cItem, nVlrMed, nVlrINSS} )
	
	

	aAdd(aPlan	, {	aCabApu[nPosCab][1], ;//1 - Local de atendimento (TFL_CODIGO)
					aCabApu[nPosCab][2] ,; //2 - Numero do contrato
					aCabApu[nPosCab][3] ,; //3 - Revisão do contrato
					aCabApu[nPosCab][4], ; //4 - Numero da planilha
					nVlrMed, ; //5 - total da medição
					cCodCli, ; //6 - cliente da medição
					cLoja, ; //7 - Loja da medição
					cNumMed, ; // 8 - Numero da medição
					aPlanItem,;//9 - Array com os itens da planilha para medição
					cChaveQbr, ;//10 - Chave de quebra de Medição
					cCodLocal, ;//11 - Codigo do local (ABS)
					aPlanHE, ; //12 - itens para hora extra excedente
					aItnsRef }) //13 - Item de referencia para a função At930VldCNB

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930AltPlan
Função montar os dados da medição no array aPlan
@sample	 	A930AltPlan
@return		aPlan
@since		24/01/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930AltPlan(aPlan,cItem, nVlrMed, nPos,nVlrINSS )
	
	Default nVlrINSS := 0
	
	aAdd(aPlan[nPos][9]	, {cItem, nVlrMed,nVlrINSS} )	
	aPlan[nPos][5]	+= nVlrMed

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930GerIts
Função montar os dados do pedido no array aPlan
@sample	 	At930GerIts
@return		aItePed
@since		31/01/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At930GerIts(aItePed, nPos, cChaveGF,cCodProd,nVlrMed, nVlrDesc, cCodTes, nDec, lDsgCN, cCodIss, cChvNoIss,nAbatINSS)
	Local nItePed 	:= 0
	Local lAddItem	:= .F.
	
	Default cCodIss 	:= ""
	Default cChvNoIss 	:= cChaveGF
	Default nAbatINSS	:= 0
	
	If nPos == 0
	
		aAdd( aItePed, { cChaveGF ,; 
								 { { { "C6_ITEM"	, StrZero( 1, TamSx3('C6_ITEM')[1] ), Nil },; 
								  	{ "C6_PRODUTO"	, cCodProd				, Nil },;
								  	{ "C6_QTDVEN"	, 1						, Nil },;
								  	{ "C6_PRCVEN"	, Round(nVlrMed,nDec) 	, Nil },;
								  	{ "C6_PRUNIT"	, Round(nVlrMed,nDec) 	, Nil },;
								  	{ "C6_VALOR"	, Round(nVlrMed,nDec) 	, Nil },;
								  	{ "C6_VALDESC"	, Round(nVlrDesc,nDec)	, Nil },;
								  	{ "C6_TES"		, cCodTes 				, Nil } ,;
								  	{ "C6_ABATINS"	,  Round(nAbatINSS,nDec), Nil } } },;
								  	cCodIss,;
								  	cChvNoIss} )
	
	Else
	
	//	If !lDsgCN
		//nItePed 	:= Len(aItePed[nPos][2])
		
		For nItePed := 1 to Len(aItePed[nPos][2])
		
			If aItePed[nPos][2][nItePed][2][2] == cCodProd
				lAddItem := .F.
				Exit
			Else
				lAddItem := .T.
			Endif
		
		Next nItePed
		//lAddItem	:= aItePed[nPos][2][nItePed][2][2] <> cCodProd
	//	EndIf 

				
		If lAddItem 
	
	
			nItePed := Len(aItePed[nPos][2])+1
			aAdd( aItePed[nPos][2], 	{ { "C6_ITEM"	, StrZero( nItePed, TamSx3('C6_ITEM')[1] ), Nil },; 
									  					{ "C6_PRODUTO"	, cCodProd		, Nil },;
									  					{ "C6_QTDVEN"	,	 1			, Nil },;
									  					{ "C6_PRCVEN"	, Round(nVlrMed,nDec) 	, Nil },;
									  					{ "C6_PRUNIT"	, Round(nVlrMed,nDec) 	, Nil },;
									  					{ "C6_VALOR"	, Round(nVlrMed,nDec) 	, Nil },;
									  					{ "C6_VALDESC"	, Round(nVlrDesc,nDec)	, Nil },;
									  					{ "C6_TES"		, cCodTes 				, Nil },;
									  					{ "C6_ABATINS"	, Round(nAbatINSS,nDec)	, Nil } } )
		Else
			
			aItePed[nPos][2][nItePed][4][2] +=  Round(nVlrMed,nDec)
			aItePed[nPos][2][nItePed][5][2] +=  Round(nVlrMed,nDec)
			aItePed[nPos][2][nItePed][6][2] +=  Round(nVlrMed,nDec)
			aItePed[nPos][2][nItePed][7][2] +=  Round(nVlrDesc,nDec)
			aItePed[nPos][2][nItePed][9][2] +=  Round(nAbatINSS,nDec)
		 
		Endif
	
	EndIf
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930VldExt
Valida serviço extra digitado nos parametros.
@sample	 	At930VldExt
@return		lRet
@since		28/02/2018
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At930VldExt(cSrvExt)

Local lRet 		:= .F.
Local cStatus	:= Posicione("TFJ",1,xFilial("TFJ") + cSrvExt,"TFJ_STATUS")
Local cSrvExt	:= Posicione("TFJ",1,xFilial("TFJ") + cSrvExt,"TFJ_SRVEXT")

If lSrvExt
	If cStatus == "1" .AND. cSrvExt == "1" //Se for srv extra e estiver ativo.
		lRet := .T.
	Else
		Help(,,'At930VldExt',,STR0170,1,0) //"Selecione um serviço extra ativo."
	EndIf
Else
	lRet := .T.
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930PosVld
Pós validação do modelo.
@sample	 	A930PosVld
@return		lRet
@since		28/02/2018
@author		Leandro Fini
@version	P12   
/*/
//------------------------------------------------------------------------------
Function A930PosVld(oModel)

Local oTFWDETAIL	:= oModel:GetModel("TFWDETAIL")
Local lRet			:= .T.
Local nX			:= 1
Local cPostos		:= ""

For	nX := 1 To oTFWDETAIL:Length()
		oTFWDETAIL:GoLine(nX)
		If oTFWDETAIL:GetValue("TFW_VLRTOT") < 0 
			lRet := .F.
			cPostos += "|[ " + oTFWDETAIL:GetValue("TFW_CODTFF") + " ]|"
		EndIf
Next nX

If !lRet
		Help(,,'A930PosVld',,STR0171 + cPostos ,1,0)	//"O valor total da medição deve ser maior ou igual a zero, revise os Postos: "
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At930LoAp
Carga da ABX quando for faturamento antecipado
@sample	 	At930LoAp
@return		lRet
@since		02/04/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At930LoAp(oModel)

	Local nX 			:= 1
	Local nRefMod		:= 0
	Local nRefABX		:= 0
	Local oTFVMaster 	:= oModel:GetModel('TFVMASTER') 
	Local oTFWDetail 	:= oModel:GetModel("TFWDETAIL")
	Local oTFXDetail 	:= oModel:GetModel("TFXDETAIL")
	Local oTFYDetail 	:= oModel:GetModel("TFYDETAIL")
	Local oTFLDetail 	:= oModel:GetModel("TFLDETAIL")
	Local oABXDetail 	:= oModel:GetModel("ABXDETAIL")
	Local cContrato 	:= oTFVMaster:GetValue("TFV_CONTRT")
	Local cCodApur 		:= oTFVMaster:GetValue("TFV_CODIGO")
	Local cRevisao 		:= oTFVMaster:GetValue("TFV_REVISA")
	Local lNovo		 	:= .T.
	Local lGsMtMi		:= .F.//TFJ->TFJ_GSMTMI $ "2|3"
	Local lGsMtMc		:= .F.//TFJ->TFJ_GSMTMC $ "2|3"
	Local cPlanMC		:= ""
	Local cPlanMI		:= ""
	Local cChaveOrc		:= ""//TFJ->TFJ_CODGRP
	
	TFJ->(DbSetOrder(5))//TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV
	If TFJ->(DbSeek(xFilial("TFJ")+cContrato+cRevisao))
		lGsMtMi		:= TFJ->TFJ_GSMTMI $ "2|3"
		lGsMtMc		:= TFJ->TFJ_GSMTMC $ "2|3"
		cChaveOrc	:= TFJ->TFJ_CODGRP
	EndIf

	
	//Leitura dos movimentos de RH
	nRefMod	:= oTFWDetail:Length()
	For nX := 1 to nRefMod
		oTFWDetail:GoLine(nX)
		If  oTFWDetail:GetValue("TFW_VLRCON") 
			If nX > 1
				If !(oABXDetail:SeekLine( {{"ABX_CODPLA", oTFWDetail:GetValue("TFW_PLAN") }} )) //planilha de RH
					oABXDetail:AddLine()
					lNovo := .T.
				Else
					lNovo := .F.
				EndIf
			EndIf
			
			 If lNovo
		         oABXDetail:SetValue("ABX_CODIGO", cCodApur)
		         oABXDetail:SetValue("ABX_CONTRT", cContrato)
		         oABXDetail:SetValue("ABX_CONREV", cRevisao )
		         oABXDetail:SetValue("ABX_CODPLA", oTFWDetail:GetValue("TFW_PLAN") )
		         oABXDetail:SetValue("ABX_LOCAL", oTFWDetail:GetValue("TFW_LOCAL") )
		         oABXDetail:SetValue("ABX_DESCRI", oTFWDetail:GetValue("TFW_DESCRI") )        
		         oABXDetail:SetValue("ABX_MESANO", MV_PAR07)
		         oABXDetail:SetValue("ABX_DTINAP", MV_PAR05)
		         oABXDetail:SetValue("ABX_DTFMAP", MV_PAR06)
		         oABXDetail:SetValue("ABX_VLMEDI", oTFWDetail:GetValue("TFW_MESANT") )
		         oABXDetail:SetValue("ABX_VLAPUR", oTFWDetail:GetValue("TFW_VLRAPU") )
		     Else
		      	oABXDetail:SetValue("ABX_VLMEDI", oABXDetail:GetValue("ABX_VLMEDI") + oTFWDetail:GetValue("TFW_MESANT"))
		        oABXDetail:SetValue("ABX_VLAPUR", oABXDetail:GetValue("ABX_VLAPUR") + oTFWDetail:GetValue("TFW_VLRAPU") )
		     EndIf
		     If oTFWDetail:GetValue("TFW_VLRMED") == 0
		      	oTFWDetail:SetValue("TFW_VLRMED", oTFWDetail:GetValue("TFW_VLRCON"))
		      Endif
		      
		      If lGsMtMi //Planilha Material de Implantação
	      		 At870GrPlan( cChaveOrc, oTFWDetail:GetValue("TFW_LOCAL"), , @cPlanMI)
		      	 If !(oABXDetail:SeekLine( {{"ABX_CODPLA", cPlanMI }} ))
					oABXDetail:AddLine()
					lNovo := .T.
				 Else
					lNovo := .F.
				 EndIf
					
				 If lNovo
			         oABXDetail:SetValue("ABX_CODIGO", cCodApur)
			         oABXDetail:SetValue("ABX_CONTRT", cContrato)
			         oABXDetail:SetValue("ABX_CONREV", cRevisao )
			         oABXDetail:SetValue("ABX_CODPLA", cPlanMI )
			         oABXDetail:SetValue("ABX_LOCAL", oTFWDetail:GetValue("TFW_LOCAL") )
			         oABXDetail:SetValue("ABX_DESCRI", oTFWDetail:GetValue("TFW_DESCRI") )   
			         oABXDetail:SetValue("ABX_MESANO", MV_PAR07)
			         oABXDetail:SetValue("ABX_DTINAP", MV_PAR05)
			         oABXDetail:SetValue("ABX_DTFMAP", MV_PAR06)
			         oABXDetail:SetValue("ABX_VLMEDI", oTFWDetail:GetValue("TFW_VLMTMI") )
			        
			     Else
			      	oABXDetail:SetValue("ABX_VLMEDI", oABXDetail:GetValue("ABX_VLMEDI") + oTFWDetail:GetValue("TFW_VLMTMI"))
			        
			     EndIf
		      
		      EndIf
		      
		      If lGsMtMc //Planilha Material de Consumo
		      	At870GrPlan( cChaveOrc, oTFWDetail:GetValue("TFW_LOCAL"), , ,@cPlanMC)
		      	 If !(oABXDetail:SeekLine( {{"ABX_CODPLA", cPlanMC }} ))
					oABXDetail:AddLine()
					lNovo := .T.
				 Else
					lNovo := .F.
				 EndIf
					
				 If lNovo
			         oABXDetail:SetValue("ABX_CODIGO", cCodApur)
			         oABXDetail:SetValue("ABX_CONTRT", cContrato)
			         oABXDetail:SetValue("ABX_CONREV", cRevisao )
			         oABXDetail:SetValue("ABX_CODPLA", cPlanMC )
			         oABXDetail:SetValue("ABX_LOCAL", oTFWDetail:GetValue("TFW_LOCAL") )
			         oABXDetail:SetValue("ABX_DESCRI", oTFWDetail:GetValue("TFW_DESCRI") )   
			         oABXDetail:SetValue("ABX_MESANO", MV_PAR07)
			         oABXDetail:SetValue("ABX_DTINAP", MV_PAR05)
			         oABXDetail:SetValue("ABX_DTFMAP", MV_PAR06)
			         oABXDetail:SetValue("ABX_VLMEDI", oTFWDetail:GetValue("TFW_VLMTMC") )
			         
			     Else
			      	oABXDetail:SetValue("ABX_VLMEDI", oABXDetail:GetValue("ABX_VLMEDI") + oTFWDetail:GetValue("TFW_VLMTMC"))
			        
			     EndIf
		      
		      
		      EndIf
		     
		EndIf
			
	Next nX 	
	
	//Leitura dos movimentos de MI
	nRefABX := oABXDetail:Length()
	nRefMod	:= oTFXDetail:Length()
	lNovo 	:= .T.
	For nX := 1 to nRefMod
	
		oTFXDetail:GoLine(nX)
		
		If oTFXDetail:GetValue("TFX_VLRCON")
			If !(oABXDetail:SeekLine( {{"ABX_CODPLA", oTFXDetail:GetValue("TFX_PLAN") }} ))
				oABXDetail:AddLine()
				lNovo := .T.
			Else
				lNovo := .F.
			EndIf
			 If lNovo
				
		         oABXDetail:SetValue("ABX_CODIGO", cCodApur)
		         oABXDetail:SetValue("ABX_CONTRT", cContrato)
		         oABXDetail:SetValue("ABX_CONREV", cRevisao )
		         oABXDetail:SetValue("ABX_CODPLA", oTFXDetail:GetValue("TFX_PLAN") )
		         oABXDetail:SetValue("ABX_LOCAL", oTFXDetail:GetValue("TFX_LOCAL") )
		         oABXDetail:SetValue("ABX_DESCRI", oTFXDetail:GetValue("TFX_DESCRI") )   
		         oABXDetail:SetValue("ABX_MESANO", MV_PAR07)
		         oABXDetail:SetValue("ABX_DTINAP", MV_PAR05)
		         oABXDetail:SetValue("ABX_DTFMAP", MV_PAR06)
		         oABXDetail:SetValue("ABX_VLMEDI", oTFXDetail:GetValue("TFX_MESANT") )
		         oABXDetail:SetValue("ABX_VLAPUR", oTFXDetail:GetValue("TFX_VLRAPU") )
		     Else
		      	oABXDetail:SetValue("ABX_VLMEDI", oABXDetail:GetValue("ABX_VLMEDI") + oTFXDetail:GetValue("TFX_MESANT") )
		        oABXDetail:SetValue("ABX_VLAPUR", oABXDetail:GetValue("ABX_VLAPUR") + oTFXDetail:GetValue("TFX_VLRAPU") )
		     EndIf
		    If oTFXDetail:GetValue("TFX_VLRMED")== 0 
		   		oTFXDetail:SetValue("TFX_VLRMED", oTFXDetail:GetValue("TFX_VLRCON"))
		   	EndIf
		 EndIf
	Next nX  
		
	//Leitura dos movimentos de MC
	nRefMod	:= oTFYDetail:Length()
	nRefABX := oABXDetail:Length()
	lNovo 	:= .T.
	For nX := 1 to nRefMod
	
		
		oTFYDetail:GoLine(nX)
		If oTFYDetail:GetValue("TFY_VLRCON")> 0
			
			If !(oABXDetail:SeekLine( {{"ABX_CODPLA", oTFYDetail:GetValue("TFY_PLAN") }} ))
				oABXDetail:AddLine()
				lNovo := .T.
			Else
				lNovo := .F.
			EndIf

			 If lNovo
			
		         oABXDetail:SetValue("ABX_CODIGO", cCodApur)
		         oABXDetail:SetValue("ABX_CONTRT", cContrato)
		         oABXDetail:SetValue("ABX_CONREV", cRevisao )
		         oABXDetail:SetValue("ABX_CODPLA", oTFYDetail:GetValue("TFY_PLAN") )
		         oABXDetail:SetValue("ABX_LOCAL", oTFYDetail:GetValue("TFY_LOCAL") )
		         oABXDetail:SetValue("ABX_DESCRI", oTFYDetail:GetValue("TFY_DESCRI") )   
		         oABXDetail:SetValue("ABX_MESANO", MV_PAR07)
		         oABXDetail:SetValue("ABX_DTINAP", MV_PAR05)
		         oABXDetail:SetValue("ABX_DTFMAP", MV_PAR06)
		         oABXDetail:SetValue("ABX_VLMEDI", oTFYDetail:GetValue("TFY_MESANT") )
		         oABXDetail:SetValue("ABX_VLAPUR", oTFYDetail:GetValue("TFY_VLRAPU") )
		     Else
		      	oABXDetail:SetValue("ABX_VLMEDI", oABXDetail:GetValue("ABX_VLMEDI") + oTFYDetail:GetValue("TFY_MESANT") )
		        oABXDetail:SetValue("ABX_VLAPUR", oABXDetail:GetValue("ABX_VLAPUR") + oTFYDetail:GetValue("TFY_VLRAPU") )
		     EndIf
		     If oTFYDetail:GetValue("TFY_VLRMED") == 0
		    	oTFYDetail:SetValue("TFY_VLRMED", oTFYDetail:GetValue("TFY_VLRCON"))
		    EndIf
	     EndIf
	
	Next nX 
	
	//Leitura dos movimentos de LE
	nRefMod	:= oTFLDetail:Length()
	nRefABX := oABXDetail:Length()
	lNovo 	:= .T.
	For nX := 1 to nRefMod
	
		oTFLDetail:GoLine(nX)
		If oTFLDetail:GetValue("TFL_VALTOT")>0
			
			If !(oABXDetail:SeekLine( {{"ABX_CODPLA", oTFLDetail:GetValue("TFL_PLAN") }} ))
				oABXDetail:AddLine()
				lNovo := .T.
			Else
				lNovo := .F.
			EndIf
			 If lNovo
				
		         oABXDetail:SetValue("ABX_CODIGO", cCodApur)
		         oABXDetail:SetValue("ABX_CONTRT", cContrato)
		         oABXDetail:SetValue("ABX_CONREV", cRevisao )
		         oABXDetail:SetValue("ABX_CODPLA", oTFLDetail:GetValue("TFL_PLAN") )
		         oABXDetail:SetValue("ABX_LOCAL", oTFLDetail:GetValue("TFL_LOCAL") )
		         oABXDetail:SetValue("ABX_DESCRI", oTFLDetail:GetValue("TFL_DESCRI") )   
		         oABXDetail:SetValue("ABX_MESANO", MV_PAR07)
		         oABXDetail:SetValue("ABX_DTINAP", MV_PAR05)
		         oABXDetail:SetValue("ABX_DTFMAP", MV_PAR07)
		         oABXDetail:SetValue("ABX_VLMEDI", oTFLDetail:GetValue("TFL_VALTOT") )
		         oABXDetail:SetValue("ABX_VLAPUR", oTFLDetail:GetValue("TFL_DISP") )
		     Else
		      	oABXDetail:SetValue("ABX_VLMEDI", oABXDetail:GetValue("ABX_VLMEDI") + oTFLDetail:GetValue("TFL_VALTOT") )
		        oABXDetail:SetValue("ABX_VLAPUR", oABXDetail:GetValue("ABX_VLAPUR") + oTFLDetail:GetValue("TFL_DISP") )
		     EndIf
		     
		EndIf
	Next nX  
	
	oABXDetail:SetNoInsertLine(.T.)
	oABXDetail:SetNoDeleteLine(.T.)

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930CarAnt
Carregar os dados de medição do mês Anterior
@sample	 	A930CarAnt
@since		09/04/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930CarAnt(oModel)

	Local oMdlAnt
	Local oTFWAnt
	Local oTFXAnt
	Local oTFYAnt
	Local oTFWDetail 	:= oModel:GetModel("TFWDETAIL")
	Local oTFXDetail 	:= oModel:GetModel("TFXDETAIL")
	Local oTFYDetail 	:= oModel:GetModel("TFYDETAIL")
	Local nX 			:= 1
	Local nRefMod		:= 0
	Local cTfvCod		:= A930UltMed(MV_PAR01)
	Local aAreaTFJ		:= TFJ->(GetArea())
	Local aBkpPERG		:= {}
	
		aAdd(aBkpPERG, 	MV_PAR01)
		aAdd(aBkpPERG, 	MV_PAR02)
		aAdd(aBkpPERG, 	MV_PAR03)
		aAdd(aBkpPERG, 	MV_PAR04)
		aAdd(aBkpPERG, 	MV_PAR05)
		aAdd(aBkpPERG, 	MV_PAR06)
		aAdd(aBkpPERG, 	MV_PAR07) 
	
    If !Empty(cTfvCod) .and. TFV->(DbSeek(xFilial("TFV") + cTfvCod)) 
	    oMdlAnt := FwLoadModel("TECA930")
	    oMdlAnt:SetOperation( MODEL_OPERATION_VIEW )
	    oMdlAnt:Activate()
		
		oTFWAnt := oMdlAnt:GetModel("TFWDETAIL")
		oTFXAnt := oMdlAnt:GetModel("TFXDETAIL")
		oTFYAnt := oMdlAnt:GetModel("TFYDETAIL")
		
		nRefMod	:= oTFWAnt:Length()
		For nX := 1 to nRefMod
			oTFWAnt:GoLine(nX)
			
			If oTFWDetail:SeekLine( {{"TFW_CODTFF", oTFWAnt:GetValue("TFW_CODTFF") }} )
				oTFWDetail:SetValue("TFW_MESANT", oTFWAnt:GetValue("TFW_VLRMED"))
				oTFWDetail:SetValue("TFW_VLRMED", oTFWDetail:GetValue("TFW_VLRAPU")+ oTFWDetail:GetValue("TFW_VLRCON")-oTFWAnt:GetValue("TFW_VLRMED"))
				oTFWDetail:SetValue("TFW_DIFMED", oTFWDetail:GetValue("TFW_VLRCON")-oTFWAnt:GetValue("TFW_VLRMED"))
			EndIf
		Next nX
		
		nRefMod	:= oTFXAnt:Length()
		For nX := 1 to nRefMod
			oTFXAnt:GoLine(nX)
			
			If oTFXDetail:SeekLine( {{"TFX_CODTFG", oTFXAnt:GetValue("TFX_CODTFG") }} )
				oTFXDetail:SetValue("TFX_MESANT", oTFXAnt:GetValue("TFX_VLRMED") )
				oTFXDetail:SetValue("TFX_VLRMED", oTFXDetail:GetValue("TFX_VLRAPU")+ oTFXDetail:GetValue("TFX_VLRCON")-oTFXAnt:GetValue("TFX_VLRMED"))
				oTFXDetail:SetValue("TFX_DIFMED", oTFXDetail:GetValue("TFX_VLRCON")-oTFXAnt:GetValue("TFX_VLRMED"))
			EndIf
		Next nX
		
		nRefMod	:= oTFYAnt:Length()
		For nX := 1 to nRefMod
			oTFYAnt:GoLine(nX)
			
			If oTFYDetail:SeekLine( {{"TFY_CODTFH", oTFYAnt:GetValue("TFY_CODTFH") }} )
				oTFYDetail:SetValue("TFY_MESANT", oTFYAnt:GetValue("TFY_VLRMED") )
				oTFYDetail:SetValue("TFY_VLRMED", oTFYDetail:GetValue("TFY_VLRAPU")+ oTFYDetail:GetValue("TFY_VLRCON")-oTFYAnt:GetValue("TFY_VLRMED"))
				oTFYDetail:SetValue("TFY_DIFMED", oTFYDetail:GetValue("TFY_VLRCON")-oTFYAnt:GetValue("TFY_VLRMED"))
			EndIf
		Next nX
		
		oMdlAnt:DeActivate()
	    oMdlAnt:Destroy()
		oMdlAnt:= Nil
	
	EndIf
	
	MV_PAR01 :=  aBkpPERG[1]
	MV_PAR02 :=  aBkpPERG[2]
	MV_PAR03 :=  aBkpPERG[3]
	MV_PAR04 :=  aBkpPERG[4]
	MV_PAR05 :=  aBkpPERG[5]
	MV_PAR06 :=  aBkpPERG[6]
	MV_PAR07 :=  aBkpPERG[7]
	
	RestArea(aAreaTFJ)
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930UltMed
Carregar os dados de medição do mês Anterior
@sample	 	A930UltMed
@since		09/04/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Function A930UltMed(cContrt)

Local cRet := ""
Local cQuery := ""
Local cAliasTFV := GetNextAlias()

	cQuery := "Select Max(TFV_CODIGO) TFV_CODIGO FROM "
	cQuery += RetSqlName("TFV") 
	cQuery += " WHERE "                                    
	cQuery += "TFV_FILIAL = '"+xFilial("TFV")+"' AND "
	cQuery += "TFV_CONTRT= '" + cContrt + "' AND "
	cQuery += "D_E_L_E_T_ = ' ' "
	cQuery := ChangeQuery(cQuery)

	dBUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAliasTFV,.F.,.T.)

	If !Empty((cAliasTFV)->TFV_CODIGO)
		cRet := (cAliasTFV)->TFV_CODIGO
	Endif
	(cAliasTFV)->(dbCloseArea())							


Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A930VldPer
Valida Periodo da medição
@sample	 	A930VldPer
@since		11/04/2018
@author		Pâmela Bernardo
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function A930VldPer()

Local lRet := .T.
Local cQuery := ""
Local cAliasTFV := GetNextAlias()

	cQuery := "Select Max(TFV_CODIGO) TFV_CODIGO FROM "
	cQuery += RetSqlName("TFV") 
	cQuery += " WHERE "                                    
	cQuery += "TFV_FILIAL = '"+xFilial("TFV")+"' AND "
	cQuery += "TFV_CONTRT= '" + MV_PAR01 + "' AND "
	cQuery += "TFV_DTFIM >= '" + DTOS(MV_PAR02) + "' AND "
	cQuery += "D_E_L_E_T_ = ' ' "
	cQuery := ChangeQuery(cQuery)

	dBUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAliasTFV,.F.,.T.)

	If !Empty((cAliasTFV)->TFV_CODIGO)
		lRet := .F.
		Help(,,'AT930PERIODO',, STR0172,1,0,,,,,,; // "Periodo informado já medido"
						{ STR0173} ) // "Alterar periodo de medição" 
	Endif
	(cAliasTFV)->(dbCloseArea())							


Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} at930GPed
Gera o pedido de Venda 
@sample	 	at930GPed
@since		11/04/2018
@author		fabiana.silva
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function at930GPed(aPedItens, aLocPed, oTFVMaster, lFatDASep, ;
						  aLocPedX, dDtIniApu, dDtFimApu, lGrpFat, ;
						  oModel, oTFVMaster, lSrvExt, xAuxPed)
Local i := 0
Local cTipoFrete := 0
Local aPedCabec := {}
Local aRateio := {}

Local lRet := .T.
Private lMsErroAuto := .F.
					

If Len(aPedItens) > 0

	aAdd( aPedCabec, { 'C5_TIPO'   , 'N'							 , Nil } )
	aAdd( aPedCabec, { 'C5_CLIENTE', aLocPed[3] 				 , Nil } )
	aAdd( aPedCabec, { 'C5_LOJACLI', aLocPed[4] 				 , Nil } )
	aAdd( aPedCabec, { 'C5_CONDPAG', aLocPed[5] 				 , Nil } )
	aAdd( aPedCabec, { 'C5_ORIGEM', 'TECA930'						 , Nil } )
	If lSrvExt
		aAdd( aPedCabec, { 'C5_ORCSERV', oTFVMaster:GetValue("TFV_ORCSRV"), Nil } )
	EndIf
	
	//Insere os dados complementares do Pedido
	aCompPed:= GetComplSc5(aLocPed[7])
	
	If Len(aCompPed) > 0 
		For i := 1 to Len(aCompPed)
			aAdd( aPedCabec, { aCompPed[i][1], aCompPed[i][2]		, Nil } )	
		Next i			
	Endif
	
	If !Empty(aLocPed[6])
		cTipoFrete := Iif(aLocPed[6]=="1","C","F")
		aAdd( aPedCabec, { 'C5_TPFRETE', cTipoFrete, Nil } )
	Endif	
	
	aAdd( aRateio, { "01", { { { "AGG_ITEM"  , "01", Nil },;
								 { "AGG_PERC"  , 100, Nil },;
								 { "AGG_CC"    , aLocPed[2], Nil },;
								 { "AGG_CONTA" , "", Nil },;
								 { "AGG_ITEMCT", "", Nil },;
								 { "AGG_CLVL"  , "", Nil } } } } )									
							
	lMsErroAuto := .F.
	MsExecAuto( { |w,x,y,z| MATA410( w, x, y, Nil, Nil, Nil, Nil, z ) }, aPedCabec, aPedItens, 3, aRateio )
						     
	If lMsErroAuto
		lRet := .F.
		xAuxPed := GetAutoGrLog()
		MostraErro()
	Else
		If !lFatDASep
			A930GrvTWQ(lSrvExt,aLocPedX,aLocPed[7], "", SC5->C5_NUM, dDtIniApu, dDtFimApu, lGrpFat)
		EndIf
		lRet := .T.
		
		If !Empty(oModel:GetModel("TCVDETAIL"):GetValue("TCV_NUMAPU"))						
			oModel:GetModel("TCVDETAIL"):AddLine()
		EndIf
			 
		oModel:GetModel("TCVDETAIL"):SetValue("TCV_FILIAL" , xFilial("TCV") )
		oModel:GetModel("TCVDETAIL"):SetValue("TCV_NUMAPU" , oTFVMaster:GetValue("TFV_CODIGO") )
		oModel:GetModel("TCVDETAIL"):SetValue("TCV_NUMPED" , SC5->C5_NUM )			
		oModel:GetModel("TCVDETAIL"):SetValue("TCV_FATSEP" , '2' )													
	EndIf	
				
EndIf
					
					
Return lRet