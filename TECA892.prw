#INCLUDE "Protheus.ch"
#INCLUDE "TECA892.CH"
#INCLUDE "FWMVCDEF.CH" 
 
//-------------------------------------------------------------------------------------------------------------------- 
/*/{Protheus.doc} TECA892
Cadastro de Kits

@author leandro.dourado
@since 08/09/2016
@version 12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA892()

Private aRotina	:= MenuDef()

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TWX')
oBrowse:SetDescription(STR0001) //"Cadastro de Kit de Materiais"
oBrowse:Activate()

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Menu Funcional

@author leandro.dourado
@since 08/09/2016
@version 11.7
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()     
Local aRotina        := {}

ADD OPTION aRotina TITLE STR0002 ACTION "PesqBrw"             OPERATION 0                         ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0003 ACTION "VIEWDEF.TECA892"     OPERATION MODEL_OPERATION_VIEW      ACCESS 0 //"Visualizar"
ADD OPTION aRotina TITLE STR0004 ACTION "VIEWDEF.TECA892"     OPERATION MODEL_OPERATION_INSERT    ACCESS 0 //"Incluir"
ADD OPTION aRotina TITLE STR0005 ACTION "VIEWDEF.TECA892"     OPERATION MODEL_OPERATION_UPDATE    ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0006 ACTION "VIEWDEF.TECA892"     OPERATION MODEL_OPERATION_DELETE    ACCESS 0 //"Excluir"

Return aRotina

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definicao do Modelo

@author leandro.dourado
@since 06/08/2012
@version 11.7
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruCab 	  := FWFormStruct(1,"TWX",{|cCampo|   cCampo $ "TWX_KITPRO|TWX_DESKIT"})
Local oStruItens  := FWFormStruct(1,"TWX",{|cCampo| !(cCampo $ "TWX_KITPRO|TWX_DESKIT")})
Local oModel      := Nil
Local bCommit     := {|oModel| At892Commit(oModel) }

Local nTamLocal   := TamSx3("TFS_LOCAL")[1]

//-----------------------------------------
//Monta o modelo do formulário 
//-----------------------------------------
oModel:= MPFormModel():New("TECA892",/*Pre-Validacao*/,/*Pos-Validacao*/,bCommit,/*Cancel*/)

If IsInCallStack("TECA890")
	oStruCab:AddField(	STR0007             ,;  	// [01] C Titulo do campo 	##### "Qtd. Apontamento"
						STR0007 	        ,;   	// [02] C ToolTip do campo	##### "Qtd. Apontamento"
     					"TWX_QTDKIT"		,;    	// [03] C identificador (ID) do Field
         				"N" 				,;    	// [04] C Tipo do campo
            			5 					,;    	// [05] N Tamanho do campo
              			0 					,;    	// [06] N Decimal do campo
                		FwBuildFeature( STRUCT_FEATURE_VALID,"Positivo() .And. FwFldGet('TWX_QTDKIT') <= FwFldGet('TWX_SLDKIT')") 				,;    	// [07] B Code-block de validação do campo
                 		Nil					,;      // [08] B Code-block de validação When do campo
                  		Nil 				,;    	// [09] A Lista de valores permitido do campo
                   		Nil 				,;  	// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil					,;   	// [11] B Code-block de inicializacao do campo
                    	Nil 				,;  	// [12] L Indica se trata de um campo chave
                    	Nil 				,;      // [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.F. )            		    // [14] L Indica se o campo é virtual         
	
	oStruCab:AddField(	STR0009             ,;  	// [01] C Titulo do campo 	##### "Saldo do Kit"
						STR0009          	,;   	// [02] C ToolTip do campo	##### "Saldo do Kit"
     					"TWX_SLDKIT"		,;    	// [03] C identificador (ID) do Field
         				"N" 				,;    	// [04] C Tipo do campo
            			5 					,;    	// [05] N Tamanho do campo
              			0 					,;    	// [06] N Decimal do campo
                		Nil 				,;    	// [07] B Code-block de validação do campo
                 		Nil					,;      // [08] B Code-block de validação When do campo
                  		Nil 				,;    	// [09] A Lista de valores permitido do campo
                   		Nil 				,;  	// [10] L Indica se o campo tem preenchimento obrigatório
                    	FwBuildFeature( STRUCT_FEATURE_INIPAD,"At890SldKit()")		,;   	// [11] B Code-block de inicializacao do campo
                    	Nil 				,;  	// [12] L Indica se trata de um campo chave
                    	Nil 				,;      // [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )            		    // [14] L Indica se o campo é virtual                     	         	
EndIf

oModel:AddFields("TWXMASTER", Nil/*cOwner*/, oStruCab ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
oModel:GetModel("TWXMASTER"):SetDescription(STR0001)  //"Cadastro de Kit de Materiais"

oModel:SetPrimaryKey({"TWX_FILIAL+TWX_KITPRO+TWX_CODPRO"})

oModel:AddGrid("TWXDETAIL", "TWXMASTER"/*cOwner*/, oStruItens,/*bLinePre*/,/*bLinePost*/,/*bPre*/,/*bPost*/,/*Carga*/) 
oModel:SetRelation("TWXDETAIL",{{"TWX_FILIAL",'xFilial("TWX")'},{"TWX_KITPRO","TWX_KITPRO"}},TWX->(IndexKey(1))) //TWX_FILIAL+TWX_KITPRO+TWX_CODPRO 

oModel:GetModel('TWXDETAIL'):SetUniqueLine({'TWX_CODPRO'})

If IsInCallStack("TECA890")
	oModel:GetModel('TWXMASTER'):SetOnlyQuery(.T.)
	oModel:GetModel('TWXDETAIL'):SetOnlyQuery(.T.)
	oModel:GetModel('TWXDETAIL'):SetNoInsertLine()
	oModel:GetModel('TWXDETAIL'):SetNoUpdateLine()
	oModel:GetModel('TWXDETAIL'):SetNoDeleteLine()
EndIf

Return oModel

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definicao da Visao

@author leandro.dourado
@since 08/09/2016
@version 11.7
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView  		:= Nil
Local oModel  		:= FWLoadModel("TECA892")
Local oStruCab 	    := FWFormStruct(2,"TWX",{|cCampo| cCampo $ "TWX_KITPRO|TWX_DESKIT"})
Local oStruItens 	:= FWFormStruct(2,"TWX",{|cCampo| !(cCampo $ "TWX_KITPRO|TWX_DESKIT")})

//-----------------------------------------
//Monta o modelo da interface do formulário
//-----------------------------------------
oView := FWFormView():New()
oView:SetModel(oModel)   

If IsInCallStack("TECA890")

	oStruCab:AddField( 	"TWX_QTDKIT"	     ,; // cIdField
                   	    "04"		         ,; // cOrdem
                   	    STR0007	             ,; // cTitulo		##### "Qtd. Apontamento"
                   	    STR0007              ,; // cDescric		##### "Qtd. Apontamento"
                   	    {}			         ,; // aHelp
                   	    "N"		             ,; // cType
					    "@E 99999"		     ,; // cPicture
                         Nil			     ,; // nPictVar
                         Nil			     ,; // Consulta F3
                         .T.			     ,; // lCanChange
                         Nil  	             ,; // cFolder
                         Nil			     ,; // cGroup
                         Nil			     ,; // aComboValues
                         Nil			     ,; // nMaxLenCombo
                         Nil			     ,; // cIniBrow
                         .T.		     	 ,; // lVirtual
                         Nil ) 	     		    // cPictVar
                         
   oStruCab:AddField( 	"TWX_SLDKIT"	     ,; // cIdField
                   	    "06"		         ,; // cOrdem
                   	    STR0009  	         ,; // cTitulo		##### "Saldo do Kit"
                   	    STR0009              ,; // cDescric		##### "Saldo do Kit"
                   	    {}			         ,; // aHelp
                   	    "N"		             ,; // cType
					    "@E 99999"		     ,; // cPicture
                         Nil			     ,; // nPictVar
                         Nil			     ,; // Consulta F3
                         .F.			     ,; // lCanChange
                         Nil  	             ,; // cFolder
                         Nil			     ,; // cGroup
                         Nil			     ,; // aComboValues
                         Nil			     ,; // nMaxLenCombo
                         Nil			     ,; // cIniBrow
                         .T.		     	 ,; // lVirtual
                         Nil ) 	     		    // cPictVar                      

	oStruItens:SetProperty('TWX_QUANT' , MVC_VIEW_TITULO,'Qtd. Por Kit')
EndIf

oView:AddField( "VIEW_CABTWX" , oStruCab, "TWXMASTER" )
oView:CreateHorizontalBox( "HEADER" , 30 )
oView:SetOwnerView( "VIEW_CABTWX" , "HEADER" )

oView:AddGrid("VIEW_ITENS" , oStruItens,"TWXDETAIL")
oView:CreateHorizontalBox( "ITENS" , 70 )
oView:SetOwnerView( "VIEW_ITENS" , "ITENS" )

oView:AddIncrementField("VIEW_ITENS","TWX_ITEM")
                
Return oView

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At892Commit
Bloco de gravação do kit de materiais.

@author leandro.dourado
@since 08/09/2016
@version 12.1.14
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At892Commit(oModel)
Local lRet := .T.

If !IsInCallStack("TECA890")
	lRet := FwFormCommit(oModel)
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At892VldProd
Realiza o valid do campo TWX_CODPRO

@author leandro.dourado
@since 08/09/2016
@param - cCampo: Indica qual é o campo que está chamando a função
@version 11.7
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At892Prod(cCampo)
Local aArea     := GetArea()
Local aAreaSB1  := SB1->(GetArea())
Local aAreaSB5  := SB5->(GetArea())
Local oModel	:= FwModelActive()
Local lRet  	:= .T.
Local cProdKIT	:= oModel:GetValue("TWXMASTER","TWX_KITPRO")
Local cProdTWX	:= oModel:GetValue("TWXDETAIL","TWX_CODPRO")

If cCampo == "TWX_KITPRO"
	lRet := ExistChav("TWX",cProdKIT) 
	
	If !lRet
		Help('',1,STR0013,,STR0010,1,0)        //"Produto Inválido"	#####	"O produto selecionado já foi utilizado no cadastro de Kit de Produtos."
	EndIf
	
	If lRet
		lRet := ExistCpo("SB1",cProdKIT)
	EndIf
	
	If lRet
		lRet := Posicione('SB1',1,xFilial('SB1')+cProdKIT,'B1_TIPO') == "KT"
		If !lRet
			Help('',1,STR0013,,STR0011,1,0)		//"Produto Inválido"	#####	"Somente produtos do tipo 'KT' podem ser selecionados."
		EndIf
	EndIf
			
ElseIf cCampo == "TWX_CODPRO"
	lRet := ExistCpo("SB1",cProdTWX)
	
	If lRet
		lRet := Posicione('SB1',1,xFilial('SB1')+cProdTWX,'B1_TIPO') != "KT"
		If !lRet
			Help('',1,STR0013,,STR0012,1,0)	    //"Produto Inválido"	#####	"Os produtos que compõe um Kit de Produtos não podem ser do tipo KT."
		EndIf
	EndIf
	
	If lRet
		DbSelectArea("SB5")
		SB5->(DbSetOrder(1)) // B5_FILIAL+B5_COD
		If SB5->(DbSeek(FwxFilial("SB5")+cProdTWX))
			lRet := SB5->B5_TPISERV $ "1235" .AND. (SB5->B5_GSMI=="1" .OR.  SB5->B5_GSMC=="1")
		Else
			lRet := .F.
EndIf
		If !lRet
			Help('',1,STR0013,,STR0014+CRLF+STR0015,1,0) //"Produto Inválido" ##### "São permitidos apenas produtos configurados como material de consumo ou material de implantação!" ### "Acesse o cadastro de complemento de produtos caso queira configurá-lo."
		EndIf
	Endif
	
EndIf

RestArea( aArea )
RestArea( aAreaSB1 )
RestArea( aAreaSB5 )

Return lRet


