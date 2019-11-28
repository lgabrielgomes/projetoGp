#include "TECA934A.CH"
#include "protheus.ch"
#include "fwmvcdef.ch"
#include "fwbrowse.ch"

Static nTotMark := 0


//--------------------------------------------------------------------
/*/{Protheus.doc} ModelDef	()

@author Matheus Lando Raimundo
@return oModel
/*/
//--------------------------------------------------------------------
Static Function ModelDef()
Local oModel 		:= Nil
Local oStrZZZ  		:= FWFormModelStruct():New()
Local oStrCN9		:= FWFormStruct( 1, "CN9",{|cCampo| AllTrim(cCampo) $ "CN9_NUMERO|CN9_REVISA|CN9_DTINIC|CN9_DTFIM|CN9_VLATU|CN9_SALDO"})
Local aCampo    	:= {}
Local bNoInit 		:= FwBuildFeature( STRUCT_FEATURE_INIPAD, '' )
Local lTpDsc 		:= SuperGetMv("MV_GSFAMEN",,"0") == "1"

oModel := MPFormModel():New('TECA934A',,{|oModel|At934aVld(oModel)},{|oModel|At934aCmt(oModel)})

oStrZZZ:AddTable("ZZZ",{" "}," ")
oStrCN9:SetProperty("*", MODEL_FIELD_INIT, bNoInit )  // remove todos os inicializadores padrão dos campos
oStrCN9:SetProperty("*", MODEL_FIELD_OBRIGAT, .F.)

aCampo := {}
aCampo := {STR0024, STR0024,'_CRTDE','C', TamSX3('CN9_NUMERO')[1], 0,Nil,Nil, Nil, Nil , Nil, Nil, Nil, .F.}//"Contrato de"
AddFieldMD(@oStrZZZ,aCampo)
aCampo := {}
aCampo := {STR0025, STR0025 ,'_CRTATE','C', TamSX3('CN9_NUMERO')[1], 0,{||A934aVldt(oModel, 'ZZZ_CRTATE', 3)},Nil, Nil, Nil , Nil, Nil, Nil, .F.}//"Contrato até"
AddFieldMD(@oStrZZZ,aCampo)

aCampo := {}
aCampo := {STR0026, STR0026,'_DTMEDIN','D', 8, 0,{||.T.}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//"Data de Medição Inicial"
AddFieldMD(@oStrZZZ,aCampo)

aCampo := {}
aCampo := {STR0027,STR0027,'_DTMEDFI','D', 8, 0,{||A934aVldt(oModel, 'ZZZ_DTMEDFI', 1)}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//"Data de Medição Final"
AddFieldMD(@oStrZZZ,aCampo)

aCampo := {}
aCampo := {STR0003, STR0003,'_COMPET','C', 7, 0,{||.T.}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//'competência'
AddFieldMD(@oStrZZZ,aCampo)

aCampo := {}
aCampo := {STR0028, STR0028,'_DTAPINI','D', 8, 0,{||.T.}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//"Data de Apuração Inicial"
AddFieldMD(@oStrZZZ,aCampo)

aCampo := {}
aCampo := {STR0029,STR0029,'_DTAPFIM','D', 8, 0,{||A934aVldt(oModel, 'ZZZ_DTAPFIM', 2)}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//"Data de Apuração Final"
AddFieldMD(@oStrZZZ,aCampo)

aCampo := {}
aCampo := {STR0014, STR0014,'_COMPANT','C', 7, 0,{||.T.}, Nil, Nil, Nil, Nil, Nil, Nil, .F.}//'Compet Apur'
AddFieldMD(@oStrZZZ,aCampo)


aCampo := {}
aCampo := {STR0015, STR0015,'_MARK','L', 1, 0,{||.T.}, Nil, Nil, .F.,Nil, Nil, Nil, .F.} //'Mark'
AddFieldMD(@oStrCN9,aCampo)

aCampo := {}
aCampo := {STR0016, STR0016,'_RECORR','C', 3, 0,{||.T.}, Nil, Nil, .F.,Nil, Nil, Nil, .F.} //'Recorrente'
AddFieldMD(@oStrCN9,aCampo)

oStrCN9:AddField(		STR0030,;								// [01] C Titulo do campo # "Ult Med Ini."
					  	STR0030,;								// [02] C ToolTip do campo # "Ult Med Ini."
     					"CN9_ULDTMDI",;							// [03] C identificador (ID) do Field
         				"D",;									// [04] C Tipo do campo
            			8,;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil,;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
oStrCN9:AddField(		STR0031,;								// [01] C Titulo do campo #"Ult Med Fim."
					  	STR0031,;								// [02] C ToolTip do campo # "Ult Med Fim."
     					"CN9_ULDTMDF",;							// [03] C identificador (ID) do Field
         				"D",;									// [04] C Tipo do campo
            			8,;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil,;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual

oStrCN9:AddField(	STR0032,;								// [01] C Titulo do campo #"Cliente"
					  	STR0032,;								// [02] C ToolTip do campo # "Cliente"
     					"CN9_CLIENT",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			50,;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil,;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual
                    	
oStrCN9:AddField(		STR0033,;								// [01] C Titulo do campo # "Cod Med"
					  	STR0033,;								// [02] C ToolTip do campo # "Cod Med"
     					"CN9_CODTFV",;							// [03] C identificador (ID) do Field
         				"C",;									// [04] C Tipo do campo
            			6,;										// [05] N Tamanho do campo
              			0,;										// [06] N Decimal do campo
                		Nil,;									// [07] B Code-block de validação do campo
                 		Nil,;									// [08] B Code-block de validação When do campo
                  		Nil,;									// [09] A Lista de valores permitido do campo
                   		Nil,;									// [10] L Indica se o campo tem preenchimento obrigatório
                    	Nil,;	// [11] B Code-block de inicializacao do campo
                    	Nil,;									// [12] L Indica se trata de um campo chave
                    	Nil,;									// [13] L Indica se o campo pode receber valor em uma operação de update.
                    	.T. )									// [14] L Indica se o campo é virtual


oModel:addFields( 'ZZZMASTER', ,oStrZZZ)
oModel:AddGrid( 'CN9DETAIL', 'ZZZMASTER',oStrCN9 ,,,,,)

oModel:GetModel('ZZZMASTER'):SetOnlyQuery(.T.)
oModel:GetModel('CN9DETAIL'):SetNoInsertLine(.T.)
oModel:GetModel('CN9DETAIL'):SetNoDeleteLine(.T.)
oModel:GetModel('CN9DETAIL'):SetOnlyQuery(.T.)

oModel:GetModel('ZZZMASTER'):SetDescription(STR0004) //'Parâmetros'
oModel:GetModel('CN9DETAIL'):SetDescription(STR0005)//'Contratos'

oModel:SetPrimaryKey({})
oModel:SetDescription(STR0006)//'Processamento em Lote'

Return oModel

//--------------------------------------------------------------------
/*/{Protheus.doc} 	ViewDef()

@author Matheus Lando Raimundo
@return oView
/*/
//--------------------------------------------------------------------
Static Function ViewDef()
Local oModel   	:= ModelDef()
Local oView    	:= FWFormView():New()		
Local oStrZZZ  	:= FWFormStruct(2,'ZZZ')
Local oStrCN9  	:= FWFormStruct(2,'CN9',{|cCampo| AllTrim(cCampo) $ "CN9_NUMERO|CN9_REVISA|CN9_DTINIC|CN9_DTFIM"})
Local aCampo    := {}
Local aCombo	:= {}
Local lInsert := IsInCallStack('At934ILote')
Local lEstorna := IsInCallStack('At934ELote')
Local lTpDsc 	:= SuperGetMv("MV_GSFAMEN",,"0") == "1"

If lInsert
	SX3->(dbSetOrder(2)) 
	If SX3->(dbSeek('ABX_OPERAC'))   
		aCombo  := StrTokArr(X3Cbox(),';')
	EndIf
ElseIf lEstorna	
	Aadd(aCombo,STR0017) //'1=Estornar medição/apuração'
EndIf

oStrCN9:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)	

aCampo 	:= {}
aCampo 	:= {'_CRTDE', '01', STR0024,STR0024, Nil, 'C', '@!', Nil, 'TFJANT', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Contrato De"
AddFieldVW('ZZZ',@oStrZZZ,aCampo)

aCampo 	:= {}
aCampo 	:= {'_CRTATE', '02', STR0025,STR0025, Nil, 'C', '@!', Nil, 'TFJANT', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Contrato Até"
AddFieldVW('ZZZ',@oStrZZZ,aCampo)

aCampo 	:= {}
aCampo 	:= {'_DTMEDIN', '03', STR0026,STR0026, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Data de Medição Inicial"
AddFieldVW('ZZZ',@oStrZZZ,aCampo)

aCampo 	:= {}
aCampo 	:= {'_DTMEDFI', '04', STR0027,STR0027, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Data de Medição Final"
AddFieldVW('ZZZ',@oStrZZZ,aCampo)

aCampo 	:= {}
aCampo 	:= {'_COMPET', '05', STR0007,STR0007, Nil, 'C', '@9 99/9999', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//'Competência'
AddFieldVW('ZZZ',@oStrZZZ,aCampo)

If !lEstorna
	aCampo 	:= {}
	aCampo 	:= {'_DTAPINI', '06', STR0028,STR0028, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Data de Apuração Inicial"
	AddFieldVW('ZZZ',@oStrZZZ,aCampo)
	
	aCampo 	:= {}
	aCampo 	:= {'_DTAPFIM', '07', STR0029,STR0029, Nil, 'D', '', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Data de Apuração Final"
	AddFieldVW('ZZZ',@oStrZZZ,aCampo)
	
	aCampo 	:= {}
	aCampo 	:= {'_COMPANT', '08', STR0014,STR0014, Nil, 'C', '@9 99/9999', Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}//"Compet Apur"
	AddFieldVW('ZZZ',@oStrZZZ,aCampo)
EndIf
aCampo 	:= {}
aCampo 	:= {'_MARK', '00', ' ',' ', Nil, 'L', Nil, Nil, '', .T., Nil, Nil, Nil, Nil, Nil, .T.,Nil}
AddFieldVW('CN9',@oStrCN9,aCampo)

aCampo 	:= {}
aCampo 	:= {'_RECORR', '05', STR0016,STR0018, Nil, 'C', Nil, Nil, '', .F., Nil, Nil, Nil, Nil, Nil, .T.,Nil} //'Recorrente'
AddFieldVW('CN9',@oStrCN9,aCampo)

oStrCN9:AddField( ;									// Ord. Tipo Desc.
						"CN9_ULDTMDI",;					// [01] C Nome do Campo
						"07",;							// [02] C Ordem
						STR0030,;						// [03] C Titulo do campo # "Ult Med Ini." 
						STR0030,;						// [04] C Descrição do campo #"Ult Med Ini."
						Nil,;							// [05] A Array com Help
						"D",;							// [06] C Tipo do campo
						"",;							// [07] C Picture
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
						
oStrCN9:AddField( ;									// Ord. Tipo Desc.
						"CN9_ULDTMDF",;					// [01] C Nome do Campo
						"08",;							// [02] C Ordem
						STR0031,;						// [03] C Titulo do campo # "Ult Med Fim."
						STR0031,;						// [04] C Descrição do campo # "Ult Med Fim."
						Nil,;							// [05] A Array com Help
						"D",;							// [06] C Tipo do campo
						"",;							// [07] C Picture
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
						
oStrCN9:AddField( ;									// Ord. Tipo Desc.
						"CN9_CLIENT",;					// [01] C Nome do Campo
						"08",;							// [02] C Ordem
						STR0032,;						// [03] C Titulo do campo #"Cliente"
						STR0032,;						// [04] C Descrição do campo #"Cliente"
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

oStrCN9:SetProperty( 'CN9_NUMERO' 	, MVC_VIEW_ORDEM, '01')
oStrCN9:SetProperty( 'CN9_REVISA' 	, MVC_VIEW_ORDEM, '02')
oStrCN9:SetProperty( 'CN9_CLIENT' 	, MVC_VIEW_ORDEM, '03')
oStrCN9:SetProperty( 'CN9_DTINIC' 	, MVC_VIEW_ORDEM, '04')
oStrCN9:SetProperty( 'CN9_DTFIM' 	, MVC_VIEW_ORDEM, '05')
oStrCN9:SetProperty( 'CN9_ULDTMDI' 	, MVC_VIEW_ORDEM, '08')
oStrCN9:SetProperty( 'CN9_ULDTMDF'	, MVC_VIEW_ORDEM, '09')
oStrCN9:SetProperty( 'CN9_RECORR' 	, MVC_VIEW_ORDEM, '10')

oView:SetModel(oModel)  //-- Define qual o modelo de dados será utilizado
oView:SetDescription(STR0006)

oView:AddField('VIEW_ZZZ' ,oStrZZZ, 'ZZZMASTER')
oView:AddGrid('VIEW_CN9'  ,oStrCN9, 'CN9DETAIL')

oView:CreateHorizontalBox('CIMA',40)
oView:CreateHorizontalBox('MEIO',60)

oView:SetOwnerView('VIEW_ZZZ','CIMA' )
oView:SetOwnerView('VIEW_CN9','MEIO')

oView:EnableTitleView('VIEW_ZZZ' , STR0004 ) 
oView:EnableTitleView('VIEW_CN9' , STR0005 ) 

oView:SetCloseOnOk({||.T.})
oView:SetViewProperty("VIEW_CN9", "ENABLENEWGRID")
oView:SetViewProperty("VIEW_CN9", "GRIDFILTER", {.T.})

oView:SetFieldAction( 'CN9_MARK', { |oView, cIDView, cField, xValue| At934aMark(xValue) } )
oView:SetFieldAction( 'ZZZ_CRTDE', { |oView, cIDView, cField, xValue|  At934aLdCN(oView) } )
oView:SetFieldAction( 'ZZZ_CRTATE', { |oView, cIDView, cField, xValue|  At934aLdCN(oView) } )
oView:SetFieldAction( 'ZZZ_DTMEDINI', { |oView, cIDView, cField, xValue|  At934aLdCN(oView) } )
oView:SetFieldAction( 'ZZZ_DTMEDFI', { |oView, cIDView, cField, xValue|  At934aLdCN(oView) } )
If !lEstorna
	oView:SetFieldAction( 'ZZZ_DTAPINI', { |oView, cIDView, cField, xValue|  At934aLdCN(oView) } )
EndIf


oView:setInsertMessage(STR0006,STR0018) //'Processamento em Lote' ## 'Processamento efetuado com sucesso'

oView:AddUserButton(STR0008 ,"",{|oView| A934ViewCTR()}) //"Visualizar contrato"
oView:AddUserButton(STR0019 ,"",{|oView| A934aAll()})    //"Replicar marcação"

Return oView

//--------------------------------------------------------------------
/*/{Protheus.doc} 	At934aInit()

@author Matheus Lando Raimundo
@return lRet
/*/
//--------------------------------------------------------------------
Function At934ALoad(oView)
Local oModel := FwModelActive()
Local cAliasTemp := GetNextAlias()
Local oCN9Detail := oModel:GetModel('CN9DETAIL') 
Local aRet  	 := {}
Local oStrCN9	 := oCN9Detail:GetStruct()
Local cContrde   := oModel:GetValue('ZZZMASTER','ZZZ_CRTDE')
Local cContrate  := oModel:GetValue('ZZZMASTER','ZZZ_CRTATE')
Local dMedicao    :=  oModel:GetValue('ZZZMASTER','ZZZ_DTMEDIN')
Local dFimMed   :=  oModel:GetValue('ZZZMASTER','ZZZ_DTMEDFI')
Local cCodTFV    :=  ""
Local lEstorna	 := IsInCallStack('At934ELote')

CNTA300BlMd(oCN9Detail,.F.) 

nTotMark := 0
At934ClGrd(oCN9Detail)

oStrCN9:SetProperty('*', MVC_VIEW_CANCHANGE, .T.)
oStrCN9:SetProperty('*', MODEL_FIELD_OBRIGAT , .F.)	

If lEstorna
	BeginSQL Alias cAliasTemp
			
			SELECT CN9_NUMERO, CN9_REVISA, CN9_DTINIC, CN9_DTFIM, CN9_VLINI, CN9_VLATU, CN9_SALDO,TFJ_CODENT, TFJ_LOJA, TFV_CODIGO,
			CASE 
				WHEN TFJ_CNTREC = '1'  THEN 'Sim'
				ELSE 'Não'
			END	TFJ_CNTREC
			FROM %Table:CN9% CN9			 
			INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
														AND TFJ_CONTRT = CN9_NUMERO
														AND TFJ_CONREV = CN9_REVISA
														AND TFJ_ANTECI = '1' 
														AND TFJ_STATUS = '1'
														AND TFJ.%NotDel%
			INNER JOIN %Table:TFV% TFV ON TFV_FILIAL = %xFilial:TFV%
									AND TFV_CONTRT = CN9.CN9_NUMERO
									AND TFV_REVISA = CN9.CN9_REVISA
									AND TFV_ANTECI = '1' 
									AND TFV_DTINI >= %Exp:dMedicao%
									AND TFV_DTFIM <= %Exp:dFimMed%		
									AND TFV.%NotDel%	
																																												
			WHERE CN9.CN9_FILIAL = %xFilial:CN9%	
				AND CN9.CN9_SITUAC = '05'
				AND CN9.CN9_NUMERO>= %Exp:cContrde%
				AND CN9.CN9_NUMERO<= %Exp:cContrate%
				AND CN9.%NotDel%
				AND NOT EXISTS (
								SELECT TFV_CONTRT
								FROM %Table:TFV% TFV2
									WHERE TFV2.TFV_FILIAL = %xFilial:TFV%														
									AND TFV2.TFV_CONTRT = CN9.CN9_NUMERO
									AND TFV2.TFV_REVISA = CN9.CN9_REVISA
									AND  TFV2.TFV_DTINI >  %Exp:dMedicao%										
									AND TFV2.%NotDel%
							)
		ORDER BY %Order:CN9%
    EndSQL
Else 

	BeginSQL Alias cAliasTemp	
			
			SELECT CN9_NUMERO, CN9_REVISA, CN9_DTINIC, CN9_DTFIM, CN9_VLINI, CN9_VLATU, CN9_SALDO,TFJ_CODENT, TFJ_LOJA, 
			CASE 
				WHEN TFJ_CNTREC = '1'  THEN 'Sim'
				ELSE 'Não'
			END	TFJ_CNTREC
			FROM %Table:CN9% CN9			 
			INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
														AND TFJ_CONTRT = CN9_NUMERO
														AND TFJ_CONREV = CN9_REVISA
														AND TFJ_ANTECI = '1' 
														AND TFJ_STATUS = '1' 
														AND TFJ.%NotDel%
			WHERE CN9.CN9_FILIAL = %xFilial:CN9%	
				AND CN9.CN9_SITUAC = '05'
				AND CN9.CN9_NUMERO>= %Exp:cContrde%
				AND CN9.CN9_NUMERO<= %Exp:cContrate%
				AND CN9.CN9_DTFIM > %Exp:dMedicao%
				AND CN9.%NotDel%
				AND NOT EXISTS (
								SELECT TFV_CONTRT
								FROM %Table:TFV% TFV
									WHERE TFV.TFV_FILIAL = %xFilial:TFV%														
									AND TFV.TFV_CONTRT = CN9.CN9_NUMERO
									AND TFV.TFV_REVISA = CN9.CN9_REVISA
									AND TFV.TFV_DTINI >=  %Exp:dMedicao%										
									AND TFV.%NotDel%
								)
		ORDER BY %Order:CN9%
		EndSQL 

EndIf

While (cAliasTemp)->(!EOF())
	
		oCN9Detail:SetNoInsertLine(.F.)
		If !oCN9Detail:IsEmpty()
			oCN9Detail:AddLine()
		EndIf
		cCodTFV    :=  A930UltMed((cAliasTemp)->(CN9_NUMERO))

		oCN9Detail:LoadValue('CN9_NUMERO',(cAliasTemp)->(CN9_NUMERO))
		oCN9Detail:LoadValue('CN9_REVISA',(cAliasTemp)->(CN9_REVISA))
		oCN9Detail:LoadValue('CN9_DTINIC',SToD((cAliasTemp)->(CN9_DTINIC)))
		oCN9Detail:LoadValue('CN9_DTFIM',SToD((cAliasTemp)->(CN9_DTFIM)))
		oCN9Detail:LoadValue('CN9_VLATU',(cAliasTemp)->(CN9_VLATU))
		oCN9Detail:LoadValue('CN9_SALDO',(cAliasTemp)->(CN9_SALDO))
		oCN9Detail:LoadValue('CN9_RECORR',(cAliasTemp)->(TFJ_CNTREC))
		If !Empty(cCodTFV)
			oCN9Detail:LoadValue('CN9_ULDTMDI',POSICIONE("TFV",1,xFilial("TFV") + cCodTFV, "TFV_DTINI" ))
			oCN9Detail:LoadValue('CN9_ULDTMDF',POSICIONE("TFV",1,xFilial("TFV") + cCodTFV, "TFV_DTFIM" ))
		EndIf
		oCN9Detail:LoadValue('CN9_CLIENT',POSICIONE("SA1",1,xFilial("SA1") + (cAliasTemp)->(TFJ_CODENT) + (cAliasTemp)->(TFJ_LOJA), "A1_NREDUZ" ))
		If lEstorna
			oCN9Detail:LoadValue('CN9_CODTFV',(cAliasTemp)->(TFV_CODIGO))
		EndIf

	(cAliasTemp)->(DbSkip())
EndDo
oCN9Detail:SetNoInsertLine(.T.)

(cAliasTemp)->(DbCloseArea())
oStrCN9:SetProperty('*', MVC_VIEW_CANCHANGE, .F.)

If !oCN9Detail:IsEmpty()
	CNTA300BlMd(oCN9Detail,,.T.)
Else
	CNTA300BlMd(oCN9Detail,.T.)
EndIf	
oCN9Detail:GoLine(1) 	
	
oStrCN9:SetProperty('CN9_MARK', MVC_VIEW_CANCHANGE, .T.)
oStrCN9:SetProperty('*', MODEL_FIELD_OBRIGAT , .F.)	
	
oView:Refresh()
	
Return .T.


//--------------------------------------------------------------------
/*/{Protheus.doc} 	A934ViewCTR()

@author Matheus Lando Raimundo
@return 
/*/
//--------------------------------------------------------------------
Function A934ViewCTR()
Local aArea	:= GetArea()
Local oModel	:= FwModelActive()
Local oCN9Detail := oModel:GetModel('CN9DETAIL')

CN9->(DbSetOrder(1))
If CN9->(DbSeek(xFilial('CN9')+ oCN9Detail:GetValue('CN9_NUMERO') + oCN9Detail:GetValue('CN9_REVISA')))
	FwExecView(STR0009,'VIEWDEF.CNTA301',MODEL_OPERATION_VIEW)  // 'Visualizar'//"Visualizar"
EndIf

RestArea(aArea)
Return

//--------------------------------------------------------------------
/*/{Protheus.doc} 	At934aVld()

@author Matheus Lando Raimundo
@return lRet
/*/
//--------------------------------------------------------------------
Function At934aVld(oModel)
Local lRet := .T.
Local lEstorna := IsInCallStack('At934ELote')

If Empty(oModel:GetValue("ZZZMASTER","ZZZ_COMPET"))
  lRet := .F.
  Help(" ",1,"A934ACOMPET",,STR0010,4,1)//'Necessário informar a competência para realizar o processamento'
EndIf


If lRet .and. !lEstorna .and. Empty(oModel:GetValue("ZZZMASTER","ZZZ_COMPANT"))
  lRet := .F.
  Help(" ",1,"A934ACOMPANT",,STR0034,4,1)//"Necessário informar periodo de apuração para realizar o processamento"
EndIf


If lRet .and. !lEstorna .and. oModel:GetValue("ZZZMASTER","ZZZ_DTMEDIN") < oModel:GetValue("ZZZMASTER","ZZZ_DTAPINI")
  lRet := .F.
  Help(" ",1,"A934ADATA",,STR0035,4,1)//"O Periodo de apuração não pode ser maior que o periodo de medição"
EndIf

If lRet .And. nTotMark == 0 
	lRet := .F.
	Help(" ",1,"A934CONTR",,STR0020,4,1)//"Necessário informar ao menos um contrato para processamento"
EndIf
 
Return lRet

//--------------------------------------------------------------------
/*/{Protheus.doc} 	At934aCmt()

@author Matheus Lando Raimundo
@return lRet
/*/
//--------------------------------------------------------------------
Function At934aCmt(oModel)
Local lRet := .T.
Local nI   := 1
Local oZZZMaster := oModel:GetModel('ZZZMASTER')
Local oCN9Detail := oModel:GetModel('CN9DETAIL')
Local nProc		 := 0
Local aError	 :=  {}
Local nRefCNA	 :=  oCN9Detail:Length()

Begin Transaction


	For nI := 1 To nRefCNA
		oCN9Detail:GoLine(nI)
	
		If oCN9Detail:GetValue('CN9_MARK')		
			nProc += 1
			MsgRun(STR0012 + Alltrim(Str(nProc)) + ' '+ STR0013 + Alltrim(Str(nTotMark)), STR0011,{|| lRet := At934aProc(oModel,oCN9Detail:GetValue('CN9_CODTFV'),oCN9Detail:GetValue('CN9_RECORR'),oCN9Detail:GetValue('CN9_NUMERO'), @aError)})//"Processando Apurações/Mediçoes..."//"Processando contrato "//"de "
			If !lRet
				Exit
				DisarmTransacation()
			Else
				oCN9Detail:LoadValue('CN9_MARK',.F.)
			EndIf
		EndIf	
	Next nI
	
	If !lRet
		AtShowLog(Alltrim(aError[MODEL_MSGERR_MESSAGE] + CRLF + CRLF + aError[MODEL_MSGERR_SOLUCTION] ), STR0021, .T., .T., .T.,.F.)  // 'Valor de medição superior ao saldo do(s) item(ns) do contrato' ## "Processamento não concluído"
	EndIf

End Transaction

FwModelActive(oModel)

Return lRet 

//--------------------------------------------------------------------
/*/{Protheus.doc} 	At934aProc()

@author Matheus Lando Raimundo
@return lRet
/*/
//--------------------------------------------------------------------
Function At934aProc(oModel,cCodTFV,cRecorr,cContrato,aError)
Local lRet 			:= .T.
Local oMdl930   	:= Nil
Local lInsert 		:= IsInCallStack('At934ILote')
Local lEstorna 		:= IsInCallStack('At934ELote') 
Local lEncontrou	:= .T.
Local nX			:= 0
Local oZZZMaster := oModel:GetModel('ZZZMASTER')



If lInsert
	Pergunte("TEC934",.F.) 
		
	oMdl930 := FwLoadModel('TECA930')
	oMdl930:SetOperation(MODEL_OPERATION_INSERT)
	MV_PAR01 := cContrato
	MV_PAR02 := oZZZMaster:GetValue("ZZZ_DTMEDIN")
	MV_PAR03 := oZZZMaster:GetValue("ZZZ_DTMEDFI")
	If cRecorr == 'Sim'
		MV_PAR04 := oZZZMaster:GetValue("ZZZ_COMPET")
		MV_PAR07 := oZZZMaster:GetValue("ZZZ_COMPANT")
	Else
		MV_PAR04 := ""
		MV_PAR07 := ""
	Endif
	MV_PAR05 := oZZZMaster:GetValue("ZZZ_DTAPINI")
	MV_PAR06 := oZZZMaster:GetValue("ZZZ_DTAPFIM")
	
ElseIf lEstorna
	TFV->(dbSetOrder(1)) 
	If TFV->(dbSeek(xFilial('TFV')+cCodTFV))
		oMdl930 := FwLoadModel('TECA930')
		oMdl930:SetOperation(MODEL_OPERATION_DELETE)
	Else
		lEncontrou := .F.
	EndIf		
EndIf

If lEncontrou
	If oMdl930:Activate()			
		If lRet .And. oMdl930:VldData() .And. oMdl930:CommitData()
			lRet := .T.
		Else
			lRet := .F.
			aError := oMdl930:GetErrorMessage()
		EndIf

		oMdl930:DeActivate()
	    oMdl930:Destroy()
		oMdl930:= Nil
	Else
		aError := oMdl930:GetErrorMessage()
		lRet := .F.
	EndIf	
EndIf	

Return lRet

//--------------------------------------------------------------------
/*/{Protheus.doc} 	At934aMark()

@author Matheus Lando Raimundo
@return 
/*/
//--------------------------------------------------------------------
Function At934aMark(xValue)

If xValue
	nTotMark := nTotMark + 1 
Else
	nTotMark := nTotMark - 1
EndIf 
Return .T. 


//--------------------------------------------------------------------
/*/{Protheus.doc}At934aLdCN()

@author Matheus Lando Raimundo
@return 
/*/
//--------------------------------------------------------------------
Function At934aLdCN(oView)
Local oModel := FwModelActive()
Local nMes	  := 0
Local nAno	  := 0
Local dMedicao    :=  oModel:GetValue('ZZZMASTER','ZZZ_DTMEDIN')
Local dApura	  :=  oModel:GetValue('ZZZMASTER','ZZZ_DTAPINI')
Local cCompetencia := ""
Local lEstorna := IsInCallStack('At934ELote')



If !Empty(dMedicao) 

		
	nAno := Year(dMedicao)
	nMes := Month(dMedicao)

	cCompetencia :=  StrZero(nMes,2) + '/' + Alltrim(Str(nAno)) 		
	oModel:GetModel('ZZZMASTER'):LoadValue('ZZZ_COMPET',cCompetencia)
	If !lEstorna
		nAno := Year(dApura)
		nMes := Month(dApura)
	
		cCompetencia :=  StrZero(nMes,2) + '/' + Alltrim(Str(nAno))
		
		oModel:GetModel('ZZZMASTER'):LoadValue('ZZZ_COMPANT',cCompetencia)
	Endif

	Processa({|| At934ALoad( oView), STR0022}) //"Pesquisando contratos..."
EndIf	

Return .T.

//--------------------------------------------------------------------
/*/{Protheus.doc}A934aAll()
	Replicar a flag para todas as linhas.
@author Kaique Schiller
@return .T.
/*/
//--------------------------------------------------------------------
Function A934aAll()
Local oModel		:= FwModelActive()
Local oCN9Detail 	:= oModel:GetModel("CN9DETAIL")
Local aSaveLines	:= FwSaveRows()
Local nX			:= 0
Local lMark			:= oCN9Detail:GetValue("CN9_MARK")

nTotMark := 0

For nX := 1 To oCN9Detail:Length()
	oCN9Detail:Goline(nX)
	If oCN9Detail:SetValue("CN9_MARK",lMark)
		At934aMark(lMark)
	Endif
Next nX

FWRestRows(aSaveLines)

Return .T.

//--------------------------------------------------------------------
/*/{Protheus.doc}A934aVldt()
	Valida data de medição/apuração
@author Kaique Schiller
/*/
//--------------------------------------------------------------------
Static Function A934aVldt(oModel, cCampo, nTipo)
	Local lRet := .T.
	Local oModelZZZ 	:= oModel:GetModel("ZZZMASTER")
	If nTipo == 1
		If oModelZZZ:GetValue(cCampo)< oModelZZZ:GetValue("ZZZ_DTMEDIN")
			lRet := .F.
			Help(" ",1,"A934DTMED",,STR0036,4,1)//"Data de medição final menor que a inicial"
		EndIf
	Elseif nTipo == 2
		If oModelZZZ:GetValue(cCampo)< oModelZZZ:GetValue("ZZZ_DTAPINI")
			lRet := .F.
			Help(" ",1,"A934DTAPU",,STR0037,4,1)//"Data de apuração final menor que a inicial"
		EndIf
	Else
	
		If oModelZZZ:GetValue(cCampo) < oModelZZZ:GetValue("ZZZ_CRTDE")
		  lRet := .F.
		  Help(" ",1,"A934ACTR",,STR0038,4,1)//"O contrato Inicial não pode ser maior que o contrato final"
		EndIf
	Endif

Return lRet