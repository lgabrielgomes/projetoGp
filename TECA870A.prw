#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA870A.CH'

/*/{Protheus.doc} TECA870A
Interface para a rotina de gestão de orçamentos de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@sample 	TECA870A() 
@since		20/07/2016       
@version	P12   
/*/
Function TECA870A()
Local oBrw    	:= FwMBrowse():New()
Local aRotPE	:= {}
Local nI		:= 0

oBrw:SetAlias( 'TFJ' )
oBrw:SetMenudef( 'TECA870A' )
oBrw:SetDescription( OEmToAnsi( STR0001 ) ) //'Gestão de Orçamentos de Serviço Extra' 
oBrw:SetFilterDefault("TFJ->TFJ_SRVEXT == '1' .AND. TFJ->TFJ_STATUS $ '1|5'")

oBrw:AddButton(STR0002 ,{|| At870AAloc()                     },,,,.F.,1) //"Alocação de Atendentes"
oBrw:AddButton(STR0003 ,{|| At870AEncP(TFJ->TFJ_CODIGO,oBrw) },,,,.F.,1) //"Encerramento de Posto"

//Ponto de Entrada para inclusão de botoes na interface
If (ExistBlock( "AT870AMNU" ))
	aRotPE := ExecBlock( "AT870AMNU", .F., .F. )
	If ValType(aRotPE) == "A"
		For nI:=1 To Len(aRotPE)
			If ValType(aRotPE[nI]) == "A"
				oBrw:AddButton(aRotPE[nI][1], aRotPE[nI][2],,,, .F., 2 )
			EndIf
		Next nI
	EndIf
EndIf

	
oBrw:Activate()

Return

/*/{Protheus.doc} At870AAloc
Responsável por fazer a alocação de atendentes dos orçamentos de serviço extra.

@author 	Leandro Dourado - Totvs Ibirapuera
@sample 	TECA870A() 
@since		20/07/2016       
@version	P12   
/*/
Function At870AAloc()
Local aAreaTFJ   := TFJ->(GetArea())
Local cNrContrat := ""
Local cNumOrcSrv := TFJ->TFJ_CODIGO
Local nRecnoTFJ  := TFJ->(Recno())

TECA330(cNumOrcSrv, cNumOrcSrv, .T.)

RestArea( aAreaTFJ )

Return



//-------------------------------------------------------------------------------------
/*/{Protheus.doc} At870EncPo(cNumOrc, oBrowse)

Interface para encerramento do posto	 

@sample     At870EncPo(cContrato, cRevisao) 

@return      

@author     serviços
@since      25/08/2015
@version    P12
/*/
//-----------------------------------------------------------------------------------------
Function At870AEncP(cNumOrc,oBrowse)

Local aArea  := {}
Local oModel := Nil
Local aArea  := GetArea()
Local lRet   := .F.

//Foi necessario abrir o SX3
DbSelectArea("SX3")
SX3->(DbSetOrder(1))

If TFJ->TFJ_STATUS <> '5'
	FWExecView( STR0003, "VIEWDEF.TECA871", MODEL_OPERATION_UPDATE, /*oDlg*/, {||.T.} /*bCloseOk*/,	{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ )	 //"Encerramento do Posto"		
Else
	Help( ' ', 1, 'TECA870A', , STR0004, 1, 0 )	//"Posto já encerrado!" 
Endif

RestArea( aArea )

Return lRet

