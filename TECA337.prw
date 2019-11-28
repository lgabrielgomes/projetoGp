#INCLUDE 'TECA337.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE "FWMVCDEF.CH"

Static aPerfil  := {}	//Array que armazenará os campos do perfil de alocação
Static aRet337  := {}

//-------------------------------------------------------------------
/*/{Protheus.doc} TECA337
Configuração de perfil de alocação usando como referência o atendente 
selecionado para filtros de seleção de postos normais ou rotas de almocistas

@sample 	TECA337()  

@param		cFil		, string, Filial do atendente
@param		cCodAtend	, string, Código do atendente
@param		cUsaFunc	, string, 1 - indica que usa função; 2 - não usa função
@param		cUsaTurno	, string, 1 - indica que usa turno ; 2 - não usa turno 
@param 		cUsaSeq		, string, 1 - indica que usa seq   ; 2 - não usa sequência
@param		cUsaCargo	, string, 1 - indica que usa cargo ; 2 - não usa cargo
 
@return		Nil
	
@author		Ana Maria Utsumi       
@since		30/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Function TECA337( cFil, cCodAtend, lShowView, cUsaFunc, cUsaCargo, cUsaTurno, cUsaSeq  )
Local 	aRetorno  := {}	//Array que retorna as respostas do perfil de alocação
Local 	nCont	  := 0
Local   oModel    := Nil

Default lShowView := .T.
//Default cUsaFunc  := "1"
//Default cUsaTurno := "2"
//Default cUsaSeq   := "2"
//Default cusaCargo := "2"

If Empty(cUsaFunc)
	cUsaFunc  := "1"
EndIf

If Empty(cUsaTurno)
	cUsaTurno := "2"
EndIf

If Empty(cUsaSeq)
	cUsaSeq   := "2"
EndIf

If Empty(cusaCargo)
	cusaCargo := "2"
EndIf

aRet337 := {}

//Cria array com parâmetros
aPerfil := DefCampos(cFilAnt, cCodAtend, cUsaFunc, cUsaTurno, cUsaSeq, cUsaCargo)

oModel := FwLoadModel("TECA337")
oModel:SetOperation(MODEL_OPERATION_INSERT)
oModel:Activate()

If lShowView
	FWExecView(STR0001, 'TECA337', 3, , {|| .T. },,,,,,,oModel )	//"Configuração de Perfil de Alocação"
Else
	At337FilRet(oModel)
EndIf

aRetorno := aRet337
aRet337  := {}

oModel:Deactivate()
oModel:Destroy
FreeObj(oModel)
oModel := Nil
DelClassIntF()

Return aRetorno


//-------------------------------------------------------------------
Static Function ModelDef()
Local oModel	:= Nil
Local oStr1		:= Nil
Local aRetorno	:= {}
Local cAliasTMP	:= ""
Local oTempTable:= Nil

//Cria arquivo temporário
oTempTable := fCriaTMP(aPerfil)
cAliasTMP  := oTempTable:GetAlias()

oStr1:= mdloStr1Str(cAliasTMP, aPerfil)
	
oModel := MPFormModel():New('TECA337', /*bPreValidacao*/, /*bPosValidacao*/, { | oModel | PerfilFormCommit( oModel ) } /*bCommit*/,{ | oModel | At337FilRet( oModel ),.T. }  /*bCancel*/ )
	
oModel:SetDescription('Model')
oModel:addFields('PERFILMASTER',,oStr1, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/,  /*bLoad*/)
oModel:getModel('PERFILMASTER'):SetDescription('Field')

//Apaga arquivo temporário
oTempTable:Delete()

Return oModel

//-------------------------------------------------------------------
Static Function ViewDef()
Local oModel	:= ModelDef()
Local oStr2 	:= viewoStr1Str()
Local oView		:= FWFormView():New()
Local n			:= 0
	
oView:SetModel( oModel )
oView:AddField('FormPerfil' , oStr2,'PERFILMASTER' ) 
oView:CreateHorizontalBox( 'BOXFORMPerfil', 100)
oView:SetOwnerView('FormPerfil','BOXFORMPerfil')
oView:SetCloseOnOk({|| .T. }) 
	
// Cria os grupos para agrupamentos de campos
oStr2:AddGroup( STR0003, STR0003, 'TELA', 2 )	// "Atendente selecionado"
oStr2:AddGroup( STR0004, STR0004, 'TELA', 2 )	// "Função"
oStr2:AddGroup( STR0005, STR0005, 'TELA', 2 )	// "Turno"
oStr2:AddGroup( STR0006, STR0006, 'TELA', 2 )	// "Sequência"
oStr2:AddGroup( STR0007, STR0007, 'TELA', 2 )	// "Cargo"
	
For n := 1 To Len(aPerfil)
	oStr2:SetProperty(aPerfil[n, 1], MVC_VIEW_GROUP_NUMBER, aPerfil[n, 19] )
Next
	
Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} mdloStr1Str()
Retorna estrutura do tipo FWformModelStruct.

@sample 	mdloStr1Str(cAlias, aPerfil)  

@param 		cAlias	String	Nome do alias 
@param		aPerfil	Array 	Array com os parâmetros e propriedades que serão utilizados na tela 	

@return 	oStruct	Object	Retorna o objeto com a estrutura da Model

@author		Ana Maria Utsumi       
@since		31/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function mdloStr1Str(cAlias, aPerfil)
Local oStruct 	:= FWFormModelStruct():New()
Local aFields 	:= {}
Local n			:= 0
Local bInit		:= Nil
Local cInit		:= Nil
			
oStruct:AddTable(cAlias,{'AA1_CODTEC'}, STR0002)	//"Perfil do Atendente"
	
//Carrega os campos do formulário com os dados da array
For n := 1 To Len(aPerfil)
	If  aPerfil[n, 6] == Nil
		bInit := Nil
		cInit := Nil
	Else
		If ValType(aPerfil[n, 6]) == 'L'				
			cInit := Iif(aPerfil[n, 6], "{ || .T. }" , "{ || .F. }")
		ElseIf ValType(aPerfil[n, 6]) == 'N'
			cInit := "{ || '" + AllTrim(Str(aPerfil[n, 6])) + "'}"
		Else				
			cInit := "{ || '" + AllTrim(aPerfil[n, 6]) + "'}"
		EndIf
		bInit := &(cInit)
	EndIf
		
	oStruct:AddField(	aPerfil[n, 1],; 	// [01] Titulo do campo 
						aPerfil[n, 1],;		// [02] ToolTip do campo 
						aPerfil[n, 1],; 	// [03] Id do Field
						aPerfil[n, 2],;  	// [04] Tipo do campo
						aPerfil[n, 3],; 	// [05] Tamanho do campo
						aPerfil[n, 4],; 	// [06] Decimal do campo
						aPerfil[n, 8],; 	// [07] Code-block de validação do campo
						aPerfil[n, 9],; 	// [08] Code-block de validação When do campo
						aPerfil[n,10],; 	// [09] Lista de valores permitido do campo
						aPerfil[n,11],; 	// [10] Indica se o campo tem preenchimento obrigatório
						bInit        ,; 	// [11] Folder
						aPerfil[n,12],; 	// [12] Indica se trata-se de um campo chave
						aPerfil[n,13],; 	// [13] Indica se o campo pode receber valor em uma operação de update.
						aPerfil[n,14],; 	// [14] Indica se o campo é virtual
						aPerfil[n,15],; 	// [15] Valid do usuario
					)
Next
	
Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} viewoStr1Str
Retorna estrutura do tipo FWFormViewStruct.

@return 	oStruct	Object	Retorna o objeto com a estrutura da View

@author		Ana Maria Utsumi       
@since		31/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function viewoStr1Str()
Local n			:= 0
Local oStruct 	:= FWFormViewStruct():New()
	
For n := 1 to Len(aPerfil)
		
	oStruct:AddField( 	aPerfil[n, 1],;		// [01] Campo
						Str(n),;			// [02] Ordem
						aPerfil[n, 5],;		// [03] Titulo
						'',;				// [04] Descricao
						,;					// [05] Help
						aPerfil[n, 7],;		// [06] Tipo do campo Combo, Get ou Check
						aPerfil[n,17],;		// [07] Picture
						,;					// [08] PictVar
						aPerfil[n,16],;		// [09] F3
						aPerfil[n,18],;		// [10] Editavel
						,;					// [11] Folder
						,;					// [12] Group
						aPerfil[n,10],;		// [13] Lista Combo
						,;					// [14] Tam Max Combo
						,;					// [15] Inic. Browse
						aPerfil[n,13],;		// [16] Virtual
						,;					// [17] Picture variável			
					)
Next

Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} fCriaTMP
Cria arquivo temporário

@sample	fCriaTMP(aPerfil)

@param 		aPerfil		Array	Array com os parâmetros e propriedades que serão utilizados na tela

@return 	oTabelaTmp 	Object	Retorna o objeto da classe de criação de arquivo temporário AU

@author		Ana Maria Utsumi       
@since		31/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function fCriaTMP(aPerfil)
Local aArea     	:= GetArea()
Local aCampos   	:= {}
Local oTabelaTmp	:= Nil
Local cAliasTmp 	:= GetNextAlias()
Local cIndTemp		:= Alltrim(cAliasTmp)
Local cTrab			:= ""
Local n 			:= 0

For n := 1 to Len(aPerfil)
	AAdd( aCampos, { aPerfil[n, 1] ,;	// Nome do campo
					 aPerfil[n, 2] ,;	// Tipo
					 aPerfil[n, 3] ,;	// Tamanho
					 aPerfil[n, 4]  ;	// Decimal
				   } )
Next

//Criação do objeto
oTabelaTmp := FWTemporaryTable():New( cAliasTmp )

//Monta os campos da tabela a partir da array
oTabelaTmp:SetFields(aCampos)

oTabelaTmp:AddIndex(cIndTemp, {"AA1_CODTEC"})
oTabelaTmp:Create()
	
RestArea( aArea )

Return oTabelaTmp

//-------------------------------------------------------------------
/*/{Protheus.doc} PerfilFormCommit
Gravação dos dados na SX6

@sample		PerfilFormCommit(oModel)

@param		oModel	Object	Objeto da Model

@author		Ana Maria Utsumi       
@since		31/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function PerfilFormCommit(oModel)
//Local oModelPerfil	:= oModel:getModel('PERFILMASTER'):GetStruct()
//Local aRetorno		:= {}
//Local nEntity 		:= 1
//Local aRetPerfil	:= {}
				
/*aRetorno := oModelPerfil:GetFields()
aRetPerfil = aClone(aPerfil)

For nEntity := 1 To Len(aRetorno)
	If AllTrim(aPerfil[nEntity][6]) <> AllTrim(oModel:GetValue('PERFILMASTER' , aRetorno[nEntity][3]))
		ACopy(aPerfil[nEntity], aRetPerfil[nEntity], 1, 5)
		AFill(aRetPerfil[nEntity], oModel:GetValue('PERFILMASTER' , aRetorno[nEntity][3]), 6, 1)
	EndIf	
Next nEntity

aPerfil := aClone(aRetPerfil)*/

At337FilRet(oModel)

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} DefCampos
Define array com os campos que serão utilizados na tela

@sample		DefCampos()

@return 	aPerfil	Array	Retorna array com os campos e propriedades que serão utilizados na tela

@author		Ana Maria Utsumi       
@since		31/01/2011
@version	P12
/*/
//-------------------------------------------------------------------
Static Function DefCampos(cFil, cCodAtend, cUsaFunc, cUsaTurno, cUsaSeq, cUsaCargo)
Local aPerfil	:= {}
Local cSim		:= "1="+STR0012
Local cNao		:= "2="+STR0013
Local cAliasAA1	:= GetNextAlias()
Local bVldSeq   := FwBuildFeature( STRUCT_FEATURE_VALID,"At337SeqVld()" )

//Busca por dados do atendente
BeginSQL Alias cAliasAA1
	SELECT AA1.AA1_FILIAL, AA1.AA1_CODTEC, AA1.AA1_NOMTEC, AA1.AA1_CDFUNC, AA1.AA1_FUNCAO, RJ_DESC, AA1.AA1_TURNO, R6_DESC,
	       AA1.AA1_SEQTUR, SRA.RA_CARGO, SQ3.Q3_DESCSUM 
	FROM %table:AA1% AA1
	LEFT JOIN %table:SRJ% SRJ ON SRJ.RJ_FILIAL=%xFilial:SRJ% AND SRJ.RJ_FUNCAO=AA1.AA1_FUNCAO AND SRJ.%NotDel%
	LEFT JOIN %table:SR6% SR6 ON SR6.R6_FILIAL=%xFilial:SR6% AND SR6.R6_TURNO=AA1.AA1_TURNO AND SR6.%NotDel%
	LEFT JOIN %table:SRA% SRA ON SRA.RA_FILIAL=%xFilial:SRA% AND SRA.RA_MAT=AA1.AA1_CDFUNC AND SRA.%NotDel%
	LEFT JOIN %table:SQ3% SQ3 ON SQ3.Q3_FILIAL=%xFilial:SQ3% AND SQ3.Q3_CARGO=SRA.RA_CARGO AND SQ3.Q3_CC=AA1.AA1_CC AND SQ3.%NotDel%
	WHERE AA1.AA1_FILIAL=%Exp:cFil% 
	  AND AA1.AA1_CODTEC=%Exp:cCodAtend%
	  AND AA1.%NotDel%
EndSQL

//{1-Nome_Param, 2-Tipo, 3-Tam, 4-Dec, 5-Descrição do campo, 6-Conteúdo, 7-Tipo campo em tela, 8-Code-block de validação do campo, 9-Code-block de validação When do campo, 10-Lista Combo, 
// 11-Preenchimento obrigatório?, 12-Campo chave?, 13-Campo pode receber valor em uma operação de update?, 14-Campo é virtual?, 15-Valid do usuario, 16-F3, 17-Picture, 18-Editável, 19-Agrupamento de campos}
//             1             2    3                        4  5                            6                        7        8        9  10            11   12   13   14  15 16 17 18   19
AAdd(aPerfil, {'AA1_CODTEC', 'C', TamSX3("AA1_CODTEC")[1], 0, TxSX3Campo("AA1_CODTEC")[1], (cAliasAA1)->AA1_CODTEC, 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0003})
AAdd(aPerfil, {'AA1_NOMTEC', 'C', TamSX3("AA1_NOMTEC")[1], 0, TxSX3Campo("AA1_NOMTEC")[1], (cAliasAA1)->AA1_NOMTEC, 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0003})
AAdd(aPerfil, {'USA_FUNCAO', 'C', 1                      , 0, STR0008                    , cUsaFunc               , 'Combo' ,        , , {cSim, cNao}, .F., .F., .F., .T.,  ,  ,  , .T., STR0004})
AAdd(aPerfil, {'AA1_FUNCAO', 'C', TamSX3("AA1_FUNCAO")[1], 0, TxSX3Campo("AA1_FUNCAO")[1], (cAliasAA1)->AA1_FUNCAO, 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0004})
AAdd(aPerfil, {'RJ_DESC'   , 'C', TamSX3("RJ_DESC")[1]   , 0, TxSX3Campo("RJ_DESC")[1]   , (cAliasAA1)->RJ_DESC   , 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0004})
AAdd(aPerfil, {'USA_TURNO' , 'C', 1                      , 0, STR0009                    , cUsaTurno              , 'Combo' ,        , , {cSim, cNao}, .F., .F., .F., .T.,  ,  ,  , .T., STR0005})
AAdd(aPerfil, {'AA1_TURNO' , 'C', TamSX3("AA1_TURNO")[1] , 0, TxSX3Campo("AA1_TURNO")[1] , (cAliasAA1)->AA1_TURNO , 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0005})
AAdd(aPerfil, {'R6_DESC'   , 'C', TamSX3("R6_DESC")[1]   , 0, TxSX3Campo("R6_DESC")[1]   , (cAliasAA1)->R6_DESC   , 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0005})
AAdd(aPerfil, {'AA1_SEQTUR', 'C', TamSX3("AA1_SEQTUR")[1], 0, TxSX3Campo("AA1_SEQTUR")[1], (cAliasAA1)->AA1_SEQTUR, 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0006})
AAdd(aPerfil, {'USA_SEQ'   , 'C', 1                      , 0, STR0010                    , cUsaSeq                , 'Combo' , bVldSeq, , {cSim, cNao}, .F., .F., .F., .T.,  ,  ,  , .T., STR0006})
AAdd(aPerfil, {'USA_CARGO' , 'C', 1                      , 0, STR0011                    , cUsaCargo              , 'Combo' ,        , , {cSim, cNao}, .F., .F., .F., .T.,  ,  ,  , .T., STR0007})
AAdd(aPerfil, {'RA_CARGO'  , 'C', TamSX3("RA_CARGO")[1]  , 0, TxSX3Campo("RA_CARGO")[1]  , (cAliasAA1)->RA_CARGO  , 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0007})
AAdd(aPerfil, {'Q3_DESCSUM', 'C', TamSX3("Q3_DESCSUM")[1], 0, TxSX3Campo("Q3_DESCSUM")[1], (cAliasAA1)->Q3_DESCSUM, 'Get'   ,        , , {}          , .F., .F., .F., .T.,  ,  ,  , .F., STR0007})

Return aPerfil

//-------------------------------------------------------------------
/*/{Protheus.doc} At337FilRet
Preenche o array de retorno do TECA337

@sample		At337FilRet()

@return 	aRet337, Array, Retorna array com o resultado do que foi definido no perfil de alocação

@author		Leandro Dourado    
@since		31/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At337FilRet(oModel)

aAdd(aRet337,{oModel:GetValue('PERFILMASTER',"USA_FUNCAO"), oModel:GetValue('PERFILMASTER',"AA1_FUNCAO")})
aAdd(aRet337,{oModel:GetValue('PERFILMASTER',"USA_CARGO") , oModel:GetValue('PERFILMASTER',"RA_CARGO"  )})
aAdd(aRet337,{oModel:GetValue('PERFILMASTER',"USA_TURNO") , oModel:GetValue('PERFILMASTER',"AA1_TURNO" )})
aAdd(aRet337,{oModel:GetValue('PERFILMASTER',"USA_SEQ")   , oModel:GetValue('PERFILMASTER',"AA1_SEQTUR")})

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} At337FilRet
Preenche o array de retorno do TECA337

@sample		At337FilRet()

@return 	aRet337, Array, Retorna array com o resultado do que foi definido no perfil de alocação

@author		Leandro Dourado    
@since		31/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Function At337SeqVld()
Local lRet := FwFldGet('USA_TURNO') == '1'

If !lRet
	Help("",1,"AT337SEQ",,STR0014,2,0) //"Esse campo somente poderá alterado se o campo 'Usa turno?' for igua a sim!"
EndIf

Return lRet