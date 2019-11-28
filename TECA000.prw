#INCLUDE "TECA000.CH"
#INCLUDE "PROTHEUS.CH" 
#INCLUDE "FWMVCDEF.CH"

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA000
Configuração de parâmetros do módulo de Gestão de Serviços

@sample 	TECA000()   

@param		Nenhum
	
@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function TECA000()
Private aParams	:= {} //Array que armazenará os dados dos parâmetros.
 					  //Para inclusão de novo parâmetro nesta tela, basta acrescentar o parâmetro e seus dados nesta array.

If !VerSenha(171)
	Help(,,"TECA000",,STR0002,1,0)	// Usuário sem acesso ao Configurador.
	Return
EndIf

FWExecView(STR0001, 'TECA000', 3, , {|| .T. } )	//"Configuração de Parâmetros da Alocação e Movimentação Ágil"

Return NIL

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Definição do modelo de Dados

@sample ModelDef()

@return oModel  Object	Retorna o Modelo de dados	

@author		Ana Maria Utsumi        
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Local oModel	:= Nil
Local oStr1		:= Nil
Local aRetorno	:= {}
Local cAliasTMP	:= ""
Local oTempTable:= Nil

//Cria array com parâmetros
aParams := DefineSX6()

//Cria arquivo temporário
oTempTable := fCriaTMP(aParams)
cAliasTMP  := oTempTable:GetAlias()

oStr1:= mdloStr1Str(cAliasTMP, aParams)
	
oModel := MPFormModel():New('ModelWFParam', /*bPreValidacao*/, /*bPosValidacao*/, { | oModel | ParamFormCommit( oModel ) } /*bCommit*/, /*bCancel*/ )
	
oModel:SetDescription('Model')
oModel:addFields('FieldParam',,oStr1, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/,  /*bLoad*/)
oModel:getModel('FieldParam'):SetDescription('Field')

//Apaga arquivo temporário
oTempTable:Delete()

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
Definição da interface

@sample ViewDef()

@return oView  Object	Retorna o objeto da View

@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
Local oModel	:= ModelDef()
Local oStr2 	:= viewoStr1Str()
Local oView		:= FWFormView():New()
Local n			:= 0
	
oView:SetModel( oModel )
oView:AddField('FormParam' , oStr2,'FieldParam' ) 
oView:CreateHorizontalBox( 'BOXFORMParam', 100)
oView:SetOwnerView('FormParam','BOXFORMParam')
oView:SetCloseOnOk({|| .T. }) 
	
// Cria os grupos para agrupamentos de campos
oStr2:AddGroup( STR0006, STR0006, 'TELA', 2 )	//Integrações
oStr2:AddGroup( STR0007, STR0007, 'TELA', 2 )	//Motivos
oStr2:AddGroup( STR0008, STR0008, 'TELA', 2 )	//Ocorrências
oStr2:AddGroup( STR0009, STR0009, 'TELA', 2 )	//Geral
	
For n := 1 To Len(aParams)
	oStr2:SetProperty(aParams[n, 1], MVC_VIEW_GROUP_NUMBER, aParams[n, 7] )
Next
	
Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} mdloStr1Str()
Retorna estrutura do tipo FWformModelStruct.

@sample 	mdloStr1Str(cAlias, aParams)  

@param 		cAlias	String	Nome do alias 
@param		aParams	Array 	Array com os parâmetros e propriedades que serão utilizados na tela 	

@return 	oStruct	Object	Retorna o objeto com a estrutura da Model

@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function mdloStr1Str(cAlias, aParams)
Local oStruct 	:= FWFormModelStruct():New()
Local aFields 	:= {}
Local n			:= 0
Local bInit		:= Nil
Local cInit		:= Nil
			
oStruct:AddTable(cAlias,{'MV_RHMUBCO'}, STR0005)//Parâmetros
	
//Carrega os campos do formulário com os dados da SX6
For n := 1 To Len(aParams)
	If  aParams[n, 5] == Nil
		bInit := Nil
		cInit := Nil
	Else
		If ValType(aParams[n, 5]) == 'L'				
			cInit := Iif(aParams[n, 5], "{ || .T. }" , "{ || .F. }")
		ElseIf ValType(aParams[n, 5]) == 'N'
			cInit := "{ || '" + AllTrim(Str(aParams[n, 5])) + "'}"
		Else				
			cInit := "{ || '" + AllTrim(aParams[n, 5]) + "'}"
		EndIf
		bInit := &(cInit)
	EndIf
		
	oStruct:AddField(	aParams[n, 1],; 	// [01] Titulo do campo 
						aParams[n, 1],;		// [02] ToolTip do campo 
						aParams[n, 1],; 	// [03] Id do Field
						aParams[n, 2],; 	// [04] Tipo do campo
						aParams[n, 3],; 	// [05] Tamanho do campo
						aParams[n, 4],; 	// [06] Decimal do campo
						aParams[n, 8],; 	// [07] Code-block de validação do campo
						aParams[n, 9],; 	// [08] Code-block de validação When do campo
						aParams[n,10],; 	// [09] Lista de valores permitido do campo
						aParams[n,11],; 	// [10] Indica se o campo tem preenchimento obrigatório
						bInit        ,; 	// [11] Folder
						aParams[n,12],; 	// [12] Indica se trata-se de um campo chave
						aParams[n,13],; 	// [13] Indica se o campo pode receber valor em uma operação de update.
						aParams[n,14],; 	// [14] Indica se o campo é virtual
						aParams[n,15],; 	// [15] Valid do usuario
					)
Next
	
Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} viewoStr1Str
Retorna estrutura do tipo FWFormViewStruct.

@return 	oStruct	Object	Retorna o objeto com a estrutura da View

@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function viewoStr1Str()
Local n			:= 0
Local nX		:= 0
Local cDescri 	:= ''
Local nSizeFil	:= FwSizeFilial()
Local oStruct 	:= FWFormViewStruct():New()
	
For n := 1 to Len(aParams)
		
	//Localizar descrição do parâmetro
	DbSelectArea("SX6")
	SX6->(DbSetOrder(1))
	If SX6->(DbSeek( cFilAnt+ aParams[n,1]))
		cDescri := X6Descric()+X6Desc1()+X6Desc2()
	ElseIf SX6->(DbSeek( Space(nSizeFil)+ aParams[n,1]))
		cDescri := X6Descric()+X6Desc1()+X6Desc2()
	EndIf	
		
	//Elimina espaços em branco a mais na string
	nX := 0
	While (nX := At("  ",cDescri)) > 0
   		cDescri := StrTran(cDescri,"  "," ")
	Enddo
		
	oStruct:AddField( 	aParams[n, 1],;				// [01] Campo
						Str(n),;					// [02] Ordem
						aParams[n, 1],;				// [03] Titulo
						cDescri,;					// [04] Descricao
						{cDescri}, ;				// [05] Help
						aParams[n, 6],;				// [06] Tipo do campo Combo, Get ou Check
						aParams[n,17],;				// [07] Picture
						,;							// [08] PictVar
						aParams[n,16],;				// [09] F3
						,;							// [10] Editavel
						,;							// [11] Folder
						,;							// [12] Group
						aParams[n,10],;				// [13] Lista Combo
						,;							// [14] Tam Max Combo
						,;							// [15] Inic. Browse
						aParams[n,13],;				// [16] Virtual
						,;							// [17] Picture variável			
					)
Next

Return oStruct

//-------------------------------------------------------------------
/*/{Protheus.doc} fCriaTMP
Cria arquivo temporário

@sample	fCriaTMP(aParams)

@param 		aParams		Array	Array com os parâmetros e propriedades que serão utilizados na tela

@return 	oTabelaTmp 	Object	Retorna o objeto da classe de criação de arquivo temporário AU

@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function fCriaTMP(aParams)
Local aArea     	:= GetArea()
Local aCampos   	:= {}
Local oTabelaTmp	:= Nil
Local cAliasTmp 	:= GetNextAlias()
Local cIndTemp		:= Alltrim(cAliasTmp)
Local cTrab			:= ""
Local n 			:= 0

For n := 1 to Len(aParams)
	AAdd( aCampos, { aParams[n, 1], aParams[n, 2],  aParams[n, 3], aParams[n, 4]} )
Next

//Criação do objeto
oTabelaTmp := FWTemporaryTable():New( cAliasTmp )

//Monta os campos da tabela a partir da array
oTabelaTmp:SetFields(aCampos)

oTabelaTmp:AddIndex(cIndTemp, {"MV_RHMUBCO"})
oTabelaTmp:Create()
	
RestArea( aArea )

Return oTabelaTmp

//-------------------------------------------------------------------
/*/{Protheus.doc} ParamFormCommit
Gravação dos dados na SX6

@sample		ParamFormCommit(oModel)

@param		oModel	Object	Objeto da Model

@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function ParamFormCommit(oModel)
Local oModelParams := oModel:getModel('FieldParam'):GetStruct()
Local aRetorno
Local nEntity := 1
				
aRetorno := oModelParams:GetFields()
		
For nEntity := 1 To Len(aRetorno)
	PUTMV(aRetorno[nEntity][3], oModel:GetValue('FieldParam' , aRetorno[nEntity][3]))
Next

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} DefineSX6
Define array com os parâmetros que serão utilizados na tela

@sample		DefineSX6()

@return 	aParams	Array	Retorna array com os parâmetros e propriedades que serão utilizados na tela

@author		Ana Maria Utsumi       
@since		01/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Static Function DefineSX6()
Local aParams := {}

//{Nome_Param, Tipo, Tam, Dec, Conteúdo, Tipo campo, Agrupamento de campos,Code-block de validação do campo, Code-block de validação When do campo, Lista Combo, 
// Preenchimento obrigatório?, Campo chave?, Campo pode receber valor em uma operação de update?, Campo é virtual?, Valid do usuario, F3, Picture}
//             1             2      3    4  5                                       6        7        8 9  10                 11   12   13   14 15   16      17
AAdd(aParams, {'MV_TECXRH'  ,'L',   1,   0, SuperGetMv("MV_TECXRH"  ,.F.,  ,cFilAnt), 'Check' ,STR0006 , , , {}               , .F., .F., .F., .T., ,        ,     })
AAdd(aParams, {'MV_RHMUBCO' ,'C',   3,   0, SuperGetMv("MV_RHMUBCO" ,.F.,'',cFilAnt), 'Get'   ,STR0006 , , , {}               , .F., .F., .F., .T., , 'SA6'  ,     })
AAdd(aParams, {'MV_ATMTFAL' ,'C',   6,   0, SuperGetMv("MV_ATMTFAL" ,.F.,'',cFilAnt), 'Get'   ,STR0007 , , , {}               , .F., .F., .F., .T., , 'ABN'  ,     })
AAdd(aParams, {'MV_ATMTSAN' ,'C',   6,   0, SuperGetMv("MV_ATMTSAN" ,.F.,'',cFilAnt), 'Get'   ,STR0007 , , , {}               , .F., .F., .F., .T., , 'ABN'  ,     })
AAdd(aParams, {'MV_ATMTATR' ,'C',   6,   0, SuperGetMv("MV_ATMTATR" ,.F.,'',cFilAnt), 'Get'   ,STR0007 , , , {}               , .F., .F., .F., .T., , 'ABN'  ,     })
AAdd(aParams, {'MV_ATMTCAN' ,'C',   6,   0, SuperGetMv("MV_ATMTCAN" ,.F.,'',cFilAnt), 'Get'   ,STR0007 , , , {}               , .F., .F., .F., .T., , 'ABN'  ,     })
AAdd(aParams, {'MV_ATMTJDF' ,'C',   6,   0, SuperGetMv("MV_ATMTJDF" ,.F.,'',cFilAnt), 'Get'   ,STR0007 , , , {}               , .F., .F., .F., .T., , 'ABN'  ,     })
AAdd(aParams, {'MV_OCOGCT'  ,'C',   6,   0, SuperGetMv("MV_OCOGCT"  ,.F.,'',cFilAnt), 'Get'   ,STR0008 , , , {}               , .F., .F., .F., .T., , 'AAG'  ,     })
AAdd(aParams, {'MV_TECPRMF' ,'L',   1,   0, SuperGetMv("MV_TECPRMF" ,.F.,'',cFilAnt), 'Check' ,STR0009 , , , {}               , .F., .F., .F., .T., ,        ,     })
AAdd(aParams, {'MV_TECINTR' ,'C',  20,   0, SuperGetMv("MV_TECINTR" ,.F.,'',cFilAnt), 'Get'   ,STR0009 , , , {}               , .F., .F., .F., .T., ,        , '99'})
AAdd(aParams, {'MV_ATPRES'  ,'C',   6,   0, SuperGetMv("MV_ATPRES"  ,.F.,'',cFilAnt), 'Get'   ,STR0009 , , , {}               , .F., .F., .F., .T., , 'TFFRT',     })

Return aParams

//-------------------------------------------------------------------
/*/{Protheus.doc} AtTFFRTF3
Função que retorna a consulta específica de registros de Reserva Técnica

@return		lOK	Boolean	Retorna .T. se a consulta específica retornou com registros

@author		Ana Maria Utsumi       
@since		08/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Function AtTFFRTF3()

Local aCmpTFF		:= {}
Local cCampo1		:= ""
Local lOk			:= .F.
Local oModel		:= Nil	//Modelo atual
Local oDlgTFF 		:= Nil	//Dialog
Local oPanel 		:= Nil	//Objeto Panel
Local oFooter		:= Nil	//Rodapé
Local oListBox		:= Nil	//Grid campos
Local oOk			:= Nil	//Objeto Confirma 
Local oCancel		:= Nil	//Objeto Cancel
Local oMdlTFF		:= FWModelActive()
Local oViewTFF		:= FWViewActive()
Local tmpTFF 		:= ""
Local aHeader		:={}
	
tmpTFF:=GetNextAlias()
BeginSql Alias tmpTFF
	SELECT TFF_COD, TFF_LOCAL, ABS_DESCRI, TFF_PRODUT, B1_DESC, TFF_ESCALA, TDW_DESC 
	FROM %table:TFF% TFF
	INNER JOIN %table:TDW% TDW ON 
		%xFilial:TDW% = TDW.TDW_FILIAL AND 
		TDW.TDW_COD = TFF.TFF_ESCALA AND
		TDW.%NotDel%
	INNER JOIN %table:SB1% SB1 ON  
		%xFilial:SB1% = SB1.B1_FILIAL AND
		SB1.B1_COD = TFF.TFF_PRODUT AND
		SB1.%NotDel%
	INNER JOIN %table:ABS% ABS ON  
    	%xFilial:ABS% = ABS.ABS_FILIAL AND
	    ABS.ABS_LOCAL = TFF_LOCAL AND
	    ABS.%NotDel%
	WHERE TFF.TFF_FILIAL = %xFilial:TFF%
		AND TFF.%NotDel%
		AND ABS.ABS_RESTEC=1	//Local de reserva ténica
		AND TFF.TFF_CODSUB=''	//Sem funcionário de cobertura
	ORDER BY %Order:TFF%
EndSql

DbSelectArea(tmpTFF)
(tmpTFF)->(DbGoTop())
While !EOF()
	AAdd(aCmpTFF,  {(tmpTFF)->TFF_COD     ,; 	//itemRh
		 			(tmpTFF)->TFF_LOCAL   ,;   	//local
		 			(tmpTFF)->ABS_DESCRI  ,;	//descricao local
		 			(tmpTFF)->TFF_PRODUT  ,;	//produto
		 			(tmpTFF)->B1_DESC     ,; 	//desc. prodtuto
		 			(tmpTFF)->TFF_ESCALA  ,;	//escala
		 			(tmpTFF)->TDW_DESC    ,;    //desc. escala
		 		   })
	DbSkip()
Enddo
(tmpTFF)->(DbCloseArea())

//Verificar se existe informação para o filtro
If Len(aCmpTFF) > 0
	lOK := .T.
	//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
	Define MsDialog oDlgTFF From 000, 000 To 200, 600 Pixel
		
	//Cria o panel principal
	@ 000, 000 MsPanel oPanel Of oDlgTFF Size 250, 350 // Coordenada para o panel
	oPanel:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
	aHeader:={STR0011,STR0012,STR0013,STR0014,STR0015,STR0016, STR0017} //"Item RH"#"Local"#"Desc. Local"#"Produto"#"Desc. Produto"#"Escala"#"Desc. Escala"
	// Criação do grid para o panel	
	oListBox := TWBrowse():New( 40,05,204,100, ,aHeader,,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,,) // Campo#Descricao	  
	oListBox:SetArray(aCmpTFF) // Relaciona os dados do grid com a matriz
	oListBox:bLine := { ||{aCmpTFF[oListBox:nAT][1],aCmpTFF[oListBox:nAT][2],aCmpTFF[oListBox:nAT][3],aCmpTFF[oListBox:nAT][4],aCmpTFF[oListBox:nAT][5],aCmpTFF[oListBox:nAT][6],aCmpTFF[oListBox:nAT][7]}} // Indica as linhas do grid
	oListBox:bLDblClick := { ||Eval(oOk:bAction), oDlgTFF:End()} // Duplo clique executa a ação do objeto indicado
	oListBox:Align := CONTROL_ALIGN_ALLCLIENT //Indica o preenchimento e alinhamento do browse
		
	// Cria o panel para os botoes	
	@ 000, 000 MsPanel oFooter Of oDlgTFF Size 000, 010 // Corrdenada para o panel dos botoes (size)
	oFooter:Align   := CONTROL_ALIGN_BOTTOM //Indica o preenchimento e alinhamento do panel (nao necessita das coordenadas)
			
	// Botoes para o grid auxiliar	
	@ 000, 000 Button oCancel Prompt STR0018  Of oFooter Size 030, 000 Pixel //Cancelar
	oCancel:bAction := { || lOk := .F., oDlgTFF:End() }
	oCancel:Align   := CONTROL_ALIGN_RIGHT
		
	@ 000, 000 Button oOk     Prompt STR0019 Of oFooter Size 030, 000 Pixel //Confirmar
	oOk:bAction     := { || lOk := .T.,(cCampo1:=aCmpTFF[oListBox:nAT][1]),oDlgTFF:End() } // Acao ao clicar no botao
	oOk:Align      	:= CONTROL_ALIGN_RIGHT // Alinhamento do botao referente ao panel
		
	// Ativa a tela exibindo conforme a coordenada
	Activate MsDialog oDlgTFF Centered	
		
	If lOK
		oMdlTFF:SetValue("FieldParam", "MV_ATPRES", cCampo1)
		oViewTFF:Refresh()
	EndIf		
Else
	Aviso( STR0020, STR0010, { "OK" }, 2 )			//"Atenção", "Não existe informação de postos"
	lOK := .F.
Endif
		
Return lOK

//-------------------------------------------------------------------
/*/{Protheus.doc} AtTFFRTrt
Retorno da consulta específica de registros de Reserva Técnica

@return Retorna o resultado da consulta específica no campo MV_ATPRES

@author		Ana Maria Utsumi       
@since		08/08/2016
@version	P12
/*/
//-------------------------------------------------------------------
Function AtTFFRTrt()

Local oMdlTFF := FWModelActive()

Return oMdlTFF:GetValue("FieldParam", "MV_ATPRES")
