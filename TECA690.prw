#Include 'Totvs.ch'
#Include 'FWMVCDef.ch'
#Include 'TECA690.ch'


//------------------------------------------------------------------------------
/* {Protheus.doc} TECA690()
       Fun��o da rotina TECA690
@sample      TECA690() 
@since       06/09/2013  
@version     P11.90
/*/
//------------------------------------------------------------------------------
Function TECA690()

Local oBrw := FwMBrowse():New()

At690Unit()  												// Chamada da Static Function At690Unit()
oBrw:SetAlias( 'TCU' )
oBrw:SetMenudef( 'TECA690' )
oBrw:SetDescription ( OEmToAnsi( STR0001 ) )				//Cadastro de Tipos
oBrw:Activate()

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
       Rotina para constru��o do menu
@sample      Menudef() 
@since       06/09/2013  
@version     P11.90
/*/
//------------------------------------------------------------------------------
Static Function Menudef()

Local aMenu := FWMVCMenu('TECA690')							// Cria o menu na chamada do TECA690

Return aMenu

//------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Defini��o do modelo de Dados

@author alessandro.silva

@since 24/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel
Local oStr1	  := FWFormStruct(1,'TCU')

oModel := MPFormModel():New('TECA690') 
oModel:addFields('TCU',,oStr1)
oModel:SetPrimaryKey({ 'TCU_FILIAL', 'TCU_COD' })
oModel:getModel('TCU'):SetDescription(STR0002)				//'Tipos de Aloca��o'
oModel:SetDescription(STR0002)								//'Tipos de Aloca��o'
oModel:SetVldActivate({|oModel|(At690Vld(oModel))})


Return oModel

//------------------------------------------------------------------------------
/* {Protheus.doc} ViewDef
	Defini��o do interface

@author alessandro.silva

@since 24/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Static Function ViewDef()
Local oView
Local oModel := ModelDef()
Local oStr1  := FWFormStruct(2, 'TCU')

oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField('FORM1' , oStr1,'TCU' ) 
oView:CreateHorizontalBox( 'TECA690', 100)
oView:SetOwnerView('FORM1','TECA690')
oView:EnableTitleView('FORM1' , STR0003 )					//'Cadastro de Tipos de Aloca��o'

Return oView

//------------------------------------------------------------------------------
/* {Protheus.doc} At690Unit
Defini��o da Function At690Unit

@author alessandro.silva

@since 24/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At690Unit()					

Local nVar		 := .T.
Local aCodigos   := {{'001',STR0004,'1','2','2','1'},;				//"Efetivo"
					 {'002',STR0005,'2','1','2','1'},;				//"Cobertura Cobrada"
					 {'003',STR0006,'1','1','2','1'},;				//"Apoio"
					 {'004',STR0007,'1','1','2','2'},;				//"Excedente"
					 {'005',STR0008,'1','2','2','2'},;				//"Treinamento"
					 {'006',STR0009,'1','1','2','2'},;				//"Curso"
					 {'007',STR0010,'1','2','2','2'},;				//"Cortesia"
					 {'008',STR0014,'2','1','2','2'},;				//"Cobertura N�o Cobrada"
					 {'009',STR0015,'1','1','2','1'},;				//"Rota Cobertura"
					 {'010',STR0016,'1','1','2','2'},;				//"Reciclagem"
					 {'011',STR0017,'2','1','2','1'},;				//"Folga Trab."
					 {'012',STR0018,'2','1','2','1'},;				//"Folga Trab. CN"
					 {'013',STR0019,'2','1','2','2'},;				//"Ft. CN Comp."
					 {'RES',STR0013,'2','2','1','2'}}				//"Reserva T�cnica"
					 

DbselectArea('TCU')
TCU->(Dbsetorder(1))

For nVar:=1 to Len(aCodigos)

	If TCU->(!Dbseek(Xfilial('TCU')+aCodigos[nVar,1]))		// Gravando array na tabela TCU
		RecLock('TCU',.T.)
		TCU->TCU_FILIAL	:= xFilial('TCU')
    	TCU->TCU_COD	:= aCodigos[nVar][1]				//EX. Posi��o 1 [001]
    	TCU->TCU_DESC	:= aCodigos[nVar][2]				//EX. Posi��o 2 [Efetivo]   
    	TCU->TCU_EXALOC	:= aCodigos[nVar][3]				//EX. Posi��o 3 [1]          
       	TCU->TCU_EXMANU	:= aCodigos[nVar][4]				//EX. Posi��o 4 [2]  
       	TCU->TCU_RESTEC	:= aCodigos[nVar][5]				//EX. Posi��o 5 [2]
       	TCU->TCU_COBALO	:= aCodigos[nVar][6]				//EX. Posi��o 6 [1]
    	TCU->(MsUnlock())
	Else
		If TCU->TCU_COBALO==" "
			RecLock('TCU',.F.)
			TCU->TCU_COBALO		:= aCodigos[nVar][6]				//EX. Posi��o 6 [1]
			If nVar==2
				TCU->TCU_DESC	:= aCodigos[nVar][2]				//Altera��o na descri��o do registro 002
			EndIf
    		TCU->(MsUnlock()) 
    	EndIf	
	EndIf										     		 
	
Next nVar

Return

//------------------------------------------------------------------------------
/* {Protheus.doc} ViewDef
	Defini��o da Function At690Vld()

@author alessandro.silva

@since 24/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Function At690Vld(oModel)

Local lRet := .T.

If ( oModel:GetOperation() == MODEL_OPERATION_UPDATE .Or.;
     oModel:GetOperation() == MODEL_OPERATION_DELETE) .And. ;
	 (TCU->TCU_COD <= '008' .Or. TCU->TCU_COD == 'RES')    							// Valida��o do campo TCU_COD onde nele n�o poder� ser digitado valor de codigo no intervalo de 001 / 008 nem o c�digo RES
		Help(' ',1,'At690NoAltera',,I18N(STR0011 ,{AllTrim(RetTitle('At690NoAltera'))}),1,0)	// "O c�digo digitado � de uso exclusivo do sistema, n�o pode ser alterado ou exclu�do. Use um c�digo maior que 008 e diferente de RES."  -  N�o Permitido
		lRet:= .F.
Endif                                                                                                                                                                                

Return lRet
