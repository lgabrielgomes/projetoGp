#INCLUDE 'TECA335A.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'MOVIMENTACAO.CH'
//-------------------------------------------------------------------
/*/{Protheus.doc} TECA335A
Consulta de Agendas por período

@sample 	TECA335A(cFil, cCodAtend)  

@param		cFil		String	Filial do Atendente
@param 		cCodAtend	String	Código do Atendente
	
@author		Ana Maria Utsumi       
@since		17/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Function TECA335A(cFil, cCodAtend)

Local aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,STR0025},;	//"Fechar"
		           {.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}}

Local cPerg			:= "TECA335A" 
Local lPergunte		:= .F.
Local lContinua		:= .F.
Local aArea			:= GetArea()

// Atribui os valores da data da movimentação ao primeiro parametro do relatório
aKeySX1 := {{cPerg, '03', cFil},{cPerg, '04', cCodAtend}}
HS_PosSX1(aKeySX1)
MV_PAR03 := cFil
MV_PAR04 := cCodAtend

lPergunte := Pergunte("TECA335A",.T.)

If lPergunte 
	If Empty(MV_PAR01) .Or. Empty(MV_PAR02) .Or. Empty(MV_PAR03) .Or. Empty(MV_PAR04)
		MsgAlert(STR0002)//"Informe todos os parâmetros para gerar a consulta da agenda"
	ElseIf MV_PAR02 < MV_PAR01
		MsgAlert(STR0003)//"A data final deve ser maior que a data inicial"
	Else
		lContinua := .T.
	EndIf
EndIf	

If lContinua
	FWExecView(STR0001,"VIEWDEF.TECA335A", MODEL_OPERATION_INSERT,,,,,aButtons)  // "Consulta de Agendas por Período"
EndIf

RestArea(aArea)
	
Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados

@sample 	ModelDef()

@author		Ana Maria Utsumi       
@since		17/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Local cCpoView	:= ""
Local oModel	:= MPFormModel():New('TECA335A')
Local oStruAtd	:= FWFormModelStruct():New()
Local oStruABB  := FWFormStruct(1,'ABB', {|cCampo|  AtCamposABB(cCampo,.T.,@cCpoView)})

oStruAtd:AddTable("AA1",{}, STR0001)	// "Consulta de Agendas por Período"

//------------------------------------------
// Adição de campos oStruAtd
//------------------------------------------
oStruAtd:AddField( 	STR0004					,;	//[01] C Titulo do campo "Filial"                                     
					STR0004					,;  //[02] C ToolTip do campo "Filial"                                    
					"AA1_FILIAL"			,;  //[03] C identificador (ID) do Field                                     
					"C"						,;  //[04] C Tipo do campo                                                   
					TamSX3("AA1_FILIAL")[1]	,;  //[05] N Tamanho do campo                                                
					0						,;  //[06] N Decimal do campo                                                
					Nil						,;  //[07] B Code-block de validação do campo                                
					Nil						,;  //[08] B Code-block de validação When do campo                           
					Nil						,;  //[09] A Lista de valores permitido do campo                             
					.T.						,;  //[10] L Indica se o campo tem preenchimento obrigatório                 
					{|| MV_PAR03 }			,;  //[11] B Code-block de inicializacao do campo                            
					.F.						,;  //[12] L Indica se trata de um campo chave                               
					.T.						,;  //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,;  //[14] L Indica se o campo é virtual                                     
											)	//[15] Valid do usuario                                                  

oStruAtd:AddField( 	STR0005					,; //[01] C Titulo do campo "Código do Atendente"                                               
					STR0005					,; //[02] C ToolTip do campo "Código do Atendente"                                               
					"AA1_CODTEC"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("AA1_CODTEC")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					.T.						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					{|| MV_PAR04 }			,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          
	       			
oStruAtd:AddField(	STR0006					,; //[01] C Titulo do campo "Nome do Atendente"                                                
					STR0006					,; //[02] C ToolTip do campo "Nome do Atendente"                                               
					"AA1_NOMTEC"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("AA1_NOMTEC")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil 					)  //[15] Valid do usuario                                                          

oStruAtd:AddField( 	STR0007					,;	//[01] C Titulo do campo "Data Inicial"
					STR0007					,;	//[02] C ToolTip do campo "Data Inicial"
					"AA1_DTINI"				,;	//[03] C identificador (ID) do Field
					"D"						,;	//[04] C Tipo do campo 
					8						,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.T.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					{|| MV_PAR01 }			,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.F.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario

oStruAtd:AddField( 	STR0008					,;	//[01] C Titulo do campo "Data Final"
					STR0008					,;	//[02] C ToolTip do campo "Data Final"
					"AA1_DTFIM"				,;	//[03] C identificador (ID) do Field
					"D"						,;	//[04] C Tipo do campo 
					8						,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.T.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					{|| MV_PAR02 }			,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.F.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario

//------------------------------------------
// Adição de campos oStruABB
//------------------------------------------
oStruABB:AddField( 	""						,;	//[01] C Titulo do campo "Data Ref."
					""						,;	//[02] C ToolTip do campo "Data Ref."
					"ABB_LEG"				,;	//[03] C identificador (ID) do Field
					"BT"					,;	//[04] C Tipo do campo 
					1						,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.F.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					Nil						,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.T.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario

oStruABB:AddField( 	""						,;	//[01] C Titulo do campo "Data Ref."
					""						,;	//[02] C ToolTip do campo "Data Ref."
					"B1_DESC"				,;	//[03] C identificador (ID) do Field
					"C"						,;	//[04] C Tipo do campo 
					TamSX3("B1_DESC")[1]	,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.F.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					Nil						,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.T.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario

oStruABB:AddField( 	""						,;	//[01] C Titulo do campo "Data Ref."
					""						,;	//[02] C ToolTip do campo "Data Ref."
					"ABS_DESCRI"			,;	//[03] C identificador (ID) do Field
					"C"						,;	//[04] C Tipo do campo 
					TamSX3("ABS_DESCRI")[1]	,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.F.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					Nil						,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.T.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario

oStruABB:AddField( 	STR0030					,;	//[01] C Titulo do campo "Filial da Agenda"
					STR0030					,;	//[02] C ToolTip do campo "Filial da Agenda"
					"ABB_NOMEFIL"			,;	//[03] C identificador (ID) do Field
					"C"						,;	//[04] C Tipo do campo 
					40						,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.T.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					Nil						,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.T.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario

oStruABB:AddField( 	STR0027					,; //[01] C Titulo do campo "Cliente"                                                
					STR0027					,; //[02] C ToolTip do campo "Cliente"                                               
					"TFJ_CODENT"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("TFJ_CODENT")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					.F.						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					.F.						,; //[12] L Indica se trata de um campo chave                                       
					.T.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

oStruABB:AddField( 	STR0028					,; //[01] C Titulo do campo "Loja"                                                
					STR0028					,; //[02] C ToolTip do campo "Loja"                                               
					"TFJ_LOJA"				,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("TFJ_LOJA")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					.F.						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					.F.						,; //[12] L Indica se trata de um campo chave                                       
					.T.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

oStruABB:AddField( 	STR0029					,; //[01] C Titulo do campo "Nome do Cliente"                                                
					STR0029					,; //[02] C ToolTip do campo "Nome do Cliente"                                               
					"A1_NOME"				,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("A1_NOME")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					.F.						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					.F.						,; //[12] L Indica se trata de um campo chave                                       
					.T.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

//Para evitar erros de estruturas que não foram desenvolvidas para MVC
oStruABB:SetProperty("*", MODEL_FIELD_INIT   , FwBuildFeature( STRUCT_FEATURE_INIPAD, "" ) )
oStruABB:SetProperty("*", MODEL_FIELD_VALID  , FwBuildFeature( STRUCT_FEATURE_VALID , "" ) )
oStruABB:SetProperty("*", MODEL_FIELD_WHEN   , FwBuildFeature( STRUCT_FEATURE_WHEN  , "" ) )

//Retirar obrigatoriedade para permitir exibição de dias sem registro na ABB (Ex.: dias de folga)
oStruABB:SetProperty("*", MODEL_FIELD_OBRIGAT, .F. )

oModel:AddFields('CABEC_ATEND' , /*cOwner*/   , oStruAtd)
oModel:AddGrid('ITENS_ABB'     ,'CABEC_ATEND' , oStruABB,/*bLinePre*/,/*bLinePost*/,/*bPre*/,/*bPost*/,/*bLoad*/)

oModel:GetModel("CABEC_ATEND" ):SetDescription( STR0001 )	// "Consulta de Agendas por Período"
oModel:GetModel("ITENS_ABB"   ):SetDescription( STR0001 )	// "Consulta de Agendas por Período"

oModel:SetPrimaryKey( {} )
oModel:SetActivate({ |oModel| At335aAgCg( oModel ) })

Return oModel
//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição do interface

@sample 	ViewDef()

@author		Ana Maria Utsumi       
@since		17/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
Local oModel	:= ModelDef()
Local oStruAtd	:= FWFormViewStruct():New()
Local oStruABB  := FWFormStruct(2,'ABB', {|cCampo| AtCamposABB(cCampo,.F.)})
Local oView		:= FWFormView():New()

oStruAtd:AddField( 	"AA1_FILIAL",;	//[01] C Nome do Campo                              
					"01"		,;  //[02] C Ordem                                      
					STR0004		,;  //[03] C Título do campo "Filial"                           
					STR0004		,;  //[04] C Descrição do campo "Filial"                        
					Nil			,;  //[05] A Array com Help                             
					"C"			,;  //[06] C Tipo do campo                              
					"@!"		,;  //[07] C Picture                                    
					Nil			,;  //[08] B Bloco de Picture Var                       
					Nil			,;  //[09] C Consulta F3                                
					.F.			,;  //[10] L Indica se o campo é editável               
					Nil			,;  //[11] C Pasta do campo                             
					Nil			,;  //[12] C Agrupamento do campo                       
					Nil			,;  //[13] A Lista de valores permitido do campo (Combo)
					Nil			,;  //[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;  //[15] C Inicializador de Browse                    
					.T.			,;  //[16] L Indica se o campo é virtual                
					Nil 		) 	//[17] C Picture Variável                           		

oStruAtd:AddField( 	"AA1_CODTEC",;	//[01] C Nome do Campo                              
					"02"		,;	//[02] C Ordem                                      
					STR0005		,;	//[03] C Título do campo "Código"                    
					STR0005		,;	//[04] C Descrição do campo "Código"                
					Nil			,;	//[05] A Array com Help                             
					"C"			,;	//[06] C Tipo do campo                              
					"@!"		,;	//[07] C Picture                                    
					Nil			,;	//[08] B Bloco de Picture Var                       
					Nil			,;	//[09] C Consulta F3                                
					.F.			,;	//[10] L Indica se o campo é editável               
					Nil			,;	//[11] C Pasta do campo                             
					Nil			,;	//[12] C Agrupamento do campo                       
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;	//[15] C Inicializador de Browse                    
					.T.			,;	//[16] L Indica se o campo é virtual                
					Nil			) 	//[17] C Picture Variável                            
					 
oStruAtd:AddField( 	"AA1_NOMTEC",;	//[01] C Nome do Campo                              
					"03"		,;	//[02] C Ordem                                      
					STR0006		,;	//[03] C Título do campo "Nome do Atendente"                    
					STR0006		,;	//[04] C Descrição do campo "Nome do Atendente"                 
					Nil			,;	//[05] A Array com Help                             
					"C"			,;	//[06] C Tipo do campo                              
					"@!"		,;	//[07] C Picture                                    
					Nil			,;	//[08] B Bloco de Picture Var                       
					""			,;	//[09] C Consulta F3                                
					.F.			,;	//[10] L Indica se o campo é editável               
					Nil			,;	//[11] C Pasta do campo                             
					Nil			,;	//[12] C Agrupamento do campo                       
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;	//[15] C Inicializador de Browse                    
					.T.			,;	//[16] L Indica se o campo é virtual                
					Nil			) 	//[17] C Picture Variável                           
					
oStruAtd:AddField( 	"AA1_DTINI" ,;	//[01] C Nome do Campo                              
					"04"		,;	//[02] C Ordem                                      
					STR0007		,;	//[03] C Título do campo "Data Inicial"        
					STR0007		,;	//[04] C Descrição do campo "Data Inicial"     
					Nil			,;	//[05] A Array com Help                             
					"D"			,;	//[06] C Tipo do campo                              	
					"@!"		,;	//[07] C Picture                                    
					Nil			,;	//[08] B Bloco de Picture Var                       
					""			,;	//[09] C Consulta F3                                
					.F.			,;	//[10] L Indica se o campo é editável               
					Nil			,;	//[11] C Pasta do campo                             
					Nil			,;	//[12] C Agrupamento do campo                       
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;	//[15] C Inicializador de Browse                    
					.T.			,;	//[16] L Indica se o campo é virtual               
					Nil			) 	//[17] C Picture Variável                          
					 
oStruAtd:AddField( 	"AA1_DTFIM"	,;	//[01] C Nome do Campo                              
					"05"		,;	//[02] C Ordem                                      
					STR0008		,;	//[03] C Título do campo "Data Final"             
					STR0008		,;	//[04] C Descrição do campo "Data Final"          
					Nil			,;	//[05] A Array com Help                             
					"D"			,;	//[06] C Tipo do campo                              
					"@!"		,;	//[07] C Picture                                    
					Nil			,;	//[08] B Bloco de Picture Var                       
					""			,;	//[09] C Consulta F3                                
					.F.			,;	//[10] L Indica se o campo é editável               
					Nil			,;	//[11] C Pasta do campo                             
					Nil			,;	//[12] C Agrupamento do campo                       
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;	//[15] C Inicializador de Browse                  
					.T.			,;	//[16] L Indica se o campo é virtual              
					Nil			) 	//[17] C Picture Variável                         

oStruABB:AddField( 	"ABB_LEG"	,;	//[01] C Nome do Campo                             
					"01"		,;	//[02] C Ordem                                     
					""			,;	//[03] C Título do campo - Legenda de situação do dia              
					""			,;	//[04] C Descrição do campo           
					{}			,;	//[05] A Array com Help                            
					"BT"		,;	//[06] C Tipo do campo                             
					""			,;	//[07] C Picture                                   
					Nil			,;	//[08] B Bloco de Picture Var                      
					""			,;	//[09] C Consulta F3                               
					.T.			,;	//[10] L Indica se o campo é editável              
					Nil			,;	//[11] C Pasta do campo                            
					Nil			,;	//[12] C Agrupamento do campo                      
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo    
					Nil			,;	//[15] C Inicializador de Browse                   
					.T.			,;	//[16] L Indica se o campo é virtual              
					Nil			) 	//[17] C Picture Variável   
					                      
oStruABB:AddField( 	"B1_DESC"	,;	//[01] C Nome do Campo                               
					"20"		,;	//[02] C Ordem                                       
					STR0023		,;	//[03] C Título do campo "Desc. Produto"
					STR0023		,;	//[04] C Descrição do campo "Desc. Produto"                         
					Nil			,;	//[05] A Array com Help                              
					"C"			,;	//[06] C Tipo do campo                               
					"@!"		,;	//[07] C Picture                                     
					Nil			,;	//[08] B Bloco de Picture Var                        
					""			,;	//[09] C Consulta F3                                 
					.F.			,;	//[10] L Indica se o campo é editável                
					Nil			,;	//[11] C Pasta do campo                              
					Nil			,;	//[12] C Agrupamento do campo                        
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)  
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo      
					Nil			,;	//[15] C Inicializador de Browse                     
					.T.			,;	//[16] L Indica se o campo é virtual                 
					Nil			) 	//[17] C Picture Variável 
					                           
oStruABB:AddField( 	"ABS_DESCRI",;	//[01] C Nome do Campo                              
					"21"		,;	//[02] C Ordem                                      
					STR0024		,;	//[03] C Título do campo "Desc. Local"            
					STR0024		,;	//[04] C Descrição do campo "Desc. Local"         
					Nil			,;	//[05] A Array com Help                             
					"C"			,;	//[06] C Tipo do campo                              
					"@!"		,;	//[07] C Picture                                    
					Nil			,;	//[08] B Bloco de Picture Var                       
					""			,;	//[09] C Consulta F3                                
					.F.			,;	//[10] L Indica se o campo é editável               
					Nil			,;	//[11] C Pasta do campo                             
					Nil			,;	//[12] C Agrupamento do campo                       
					Nil			,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			,;	//[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;	//[15] C Inicializador de Browse                    
					.T.			,;	//[16] L Indica se o campo é virtual             
					Nil			) 	//[17] C Picture Variável                        

oStruABB:AddField( 	"ABB_NOMEFIL",;	//[01] C Nome do Campo                             
					"22"		 ,;	//[02] C Ordem                                     
					STR0030		 ,;	//[03] C Título do campo "Filial da Agenda"              
					STR0030		 ,;	//[04] C Descrição do campo "Filial da Agenda"          
					{}			 ,;	//[05] A Array com Help                            
					"C"		 	 ,;	//[06] C Tipo do campo                             
					""			 ,;	//[07] C Picture                                   
					Nil			 ,;	//[08] B Bloco de Picture Var                      
					""			 ,;	//[09] C Consulta F3                               
					.T.			 ,;	//[10] L Indica se o campo é editável              
					Nil			 ,;	//[11] C Pasta do campo                            
					Nil			 ,;	//[12] C Agrupamento do campo                      
					Nil			 ,;	//[13] A Lista de valores permitido do campo (Combo)
					Nil			 ,;	//[14] N Tamanho Maximo da maior opção do combo    
					Nil			 ,;	//[15] C Inicializador de Browse                   
					.T.			 ,;	//[16] L Indica se o campo é virtual              
					Nil			 ) 	//[17] C Picture Variável   
					                      
oStruABB:AddField(	"TFJ_CODENT",;	//[01] C Nome do Campo                              
					"23"		,;  //[02] C Ordem                                      
					STR0027		,;  //[03] C Título do campo "Cliente"              
					STR0027		,;  //[04] C Descrição do campo "Cliente"           
					Nil			,;  //[05] A Array com Help                             
					"C" 		,;  //[06] C Tipo do campo                              
					"@!"		,;  //[07] C Picture                                    
					Nil			,;  //[08] B Bloco de Picture Var                       
					""   		,;  //[09] C Consulta F3                                
					.F.			,;  //[10] L Indica se o campo é editável               
					Nil			,;  //[11] C Pasta do campo                             
					Nil			,;  //[12] C Agrupamento do campo                       
					Nil			,;  //[13] A Lista de valores permitido do campo (Combo)
					Nil			,;  //[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;  //[15] C Inicializador de Browse                    
					.T.			,;  //[16] L Indica se o campo é virtual                
					Nil			 ) 	//[17] C Picture Variável     
					                      
oStruABB:AddField(	"TFJ_LOJA"  ,;	//[01] C Nome do Campo                               
					"24"		,;  //[02] C Ordem                                      
					STR0028		,;  //[03] C Título do campo "Loja"                  
					STR0028		,;  //[04] C Descrição do campo "Loja"               
					Nil			,;  //[05] A Array com Help                             
					"C" 		,;  //[06] C Tipo do campo                              
					"@!"		,;  //[07] C Picture                                    
					Nil			,;  //[08] B Bloco de Picture Var                       
					""   		,;  //[09] C Consulta F3                                
					.F.			,;  //[10] L Indica se o campo é editável               
					Nil			,;  //[11] C Pasta do campo                             
					Nil			,;  //[12] C Agrupamento do campo                       
					Nil			,;  //[13] A Lista de valores permitido do campo (Combo)
					Nil			,;  //[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;  //[15] C Inicializador de Browse                    
					.T.			,;  //[16] L Indica se o campo é virtual                
					Nil 		) 	//[17] C Picture Variável
					                            
oStruABB:AddField(	"A1_NOME"   ,;	//[01] C Nome do Campo                               
					"25"		,;  //[02] C Ordem                                      
					STR0029		,;  //[03] C Título do campo "Nome do Cliente"                    
					STR0029		,;  //[04] C Descrição do campo "Nome do Cliente"                  
					Nil			,;  //[05] A Array com Help                             
					"C" 		,;  //[06] C Tipo do campo                              
					"@!"		,;  //[07] C Picture                                    
					Nil			,;  //[08] B Bloco de Picture Var                       
					""  		,;  //[09] C Consulta F3                                
					.F.			,;  //[10] L Indica se o campo é editável               
					Nil			,;  //[11] C Pasta do campo                             
					Nil			,;  //[12] C Agrupamento do campo                       
					Nil			,;  //[13] A Lista de valores permitido do campo (Combo)
					Nil			,;  //[14] N Tamanho Maximo da maior opção do combo     
					Nil			,;  //[15] C Inicializador de Browse                    
					.T.			,;  //[16] L Indica se o campo é virtual                
					Nil 		) 	//[17] C Picture Variável                             

	
// Ordena a visualização correta do cabecalho da alocacao
oStruAtd:SetProperty( "AA1_FILIAL"	, MVC_VIEW_ORDEM  , "01" )

oView:SetModel(oModel)

oView:AddField('VIEW_ATEND' , oStruAtd, 'CABEC_ATEND')
oView:CreateHorizontalBox('ATEND' , 30)
oView:SetOwnerView('VIEW_ATEND' , 'ATEND' )

oView:AddGrid( 'VIEW_AGENDA', oStruABB, 'ITENS_ABB'  ) 
oView:CreateHorizontalBox('AGENDA', 70)
oView:SetOwnerView('VIEW_AGENDA', 'AGENDA')

oView:AddUserButton( STR0026, '', {||At335AGLeg()})				//"Legenda"

oView:SetFieldAction("ABB_LEG"  , {||At335AGLeg()})

oView:SetCloseOnOk({|| .T.} )
oView:SetViewAction("ASKONCANCELSHOW",{||.F.})

Return oView


//-------------------------------------------------------------------
/*/{Protheus.doc} AtCamposABB()
Efetua a seleção de campos da Model

@sample 	AtCamposABB(cCampo,.T.,@cCpoView)

@param	cCampo, 	String, 
@param	lModel, 	Boolean,	Indica se chamada da função pela Model ou não
@param	cCpoView	String,		Lista de campos que serão exibidos	

@return 	cCpoView

@author 	Ana Maria Utsumi
@since		22/03/2017
@version 	P12
/*/
//-------------------------------------------------------------------
Static Function AtCamposABB(cCampo,lModel,cCpoView)
Local aArea      := GetArea()
Local lRet       := .T.
Local cContexto  := ""

Default cCpoView := ""

cCpoView  := "ABB_FILIAL|ABB_DTINI|ABB_HRINI|ABB_HRFIM|ABB_LOCAL"

If lModel
	cContexto := Posicione("SX3",2,cCampo,"X3_CONTEXT")
	If cContexto == "V"
		lRet  := .F.
	EndIf
Else
	lRet      := AllTrim(cCampo) $ cCpoView
EndIf

RestArea( aArea )

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At335aAgCg()
Carrega dados da agenda do atendente

@sample 	At335aAgCg()

@return 	Nil

@author 	Ana Maria Utsumi
@since		22/03/2017
@version 	P12
/*/
//-------------------------------------------------------------------
Static Function At335aAgCg(oModel)

//Atualiza agendas
MsgRun(STR0010,STR0009,{||At335AQry(oModel)}) //"Montando a Agenda do Atendente...""Aguarde"

Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} At335AQry
Define as colunas da grid

@sample 	At335AQry()  

@param		Nenhum
@return 	.T.
	 
@author		Ana Maria Utsumi       
@since		17/01/2017
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At335AQry(oModel)

Local oMdlAA1   := oModel:GetModel("CABEC_ATEND")
Local oMdlABB   := oModel:GetModel("ITENS_ABB")
Local oStrABB   := oMdlABB:GetStruct()
Local aCpoABB   := oStrABB:GetFields()
Local aAgenda	:= {}
Local dDataIni 	:= MV_PAR01
Local dDataFim 	:= MV_PAR02
Local cFilAtend	:= MV_PAR03
Local cCodAtend	:= MV_PAR04
Local lDemitido	:= .F.
Local lAfastado	:= .F.
Local lFerias	:= .F.
Local lSuspenso	:= .F.
Local aAusencia	:= {}
Local aTabPadrao:= {}
Local aTabCalend:= {}
Local aArea		:= GetArea()
Local aAreaSRA	:= SRA->(GetArea())
Local aAreaAA1	:= AA1->(GetArea())
Local cAliasABB	:= GetNextAlias()
Local aAreaSX3	:= SX3->(GetArea())
Local cCorLeg	:= ""
Local cRAMat	:= ""
Local dDtRef	:= dDataBase
Local lRetorno	:= .F.
Local nX		:= 1
Local nY		:= 1
Local nLinha	:= 1
Local xValor	:= Nil
Local cSituacao := ""

//SQL com as agendas criadas no período
BeginSQL Alias cAliasABB
	COLUMN ABB_DTINI AS DATE
	COLUMN ABB_DTFIM AS DATE
	COLUMN ABB_DATA  AS DATE
	
	SELECT ABB.*, SB1.B1_DESC, ABS.ABS_DESCRI,TDV.TDV_DTREF, TFJ.TFJ_CODENT, TFJ.TFJ_LOJA, SA1.A1_NOME
	FROM %table:ABB% ABB
	JOIN %table:TDV% TDV  ON (TDV.TDV_FILIAL=%xFilial:TDV% AND TDV.TDV_CODABB=ABB.ABB_CODIGO AND TDV.%NotDel%)
	JOIN %table:ABQ% ABQ  ON (ABQ.ABQ_FILIAL=%xFilial:ABQ% AND ABQ.ABQ_CONTRT||ABQ.ABQ_ITEM||ABQ.ABQ_ORIGEM=ABB.ABB_IDCFAL AND ABQ.ABQ_LOCAL=ABB.ABB_LOCAL AND ABQ.%NotDel%) 
	JOIN %table:TFF% TFF  ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_COD=ABQ.ABQ_CODTFF AND TFF.%NotDel%)
	JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)
	JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	JOIN %table:SA1% SA1 ON (SA1.A1_FILIAL=%xFilial:SA1% AND SA1.A1_COD=TFJ.TFJ_CODENT AND SA1.A1_LOJA=TFJ.TFJ_LOJA AND SA1.%NotDel%)
	JOIN %table:ABS% ABS  ON (ABS.ABS_FILIAL=%xFilial:ABS% AND ABS.ABS_LOCAL=ABB.ABB_LOCAL AND ABS.%NotDel%)
	JOIN %table:SB1% SB1  ON (SB1.B1_FILIAL =%xFilial:SB1% AND SB1.B1_COD=TFF.TFF_PRODUT AND SB1.%NotDel%)
	WHERE ABB.%NotDel%
	  AND TDV.TDV_DTREF BETWEEN %Exp:dDataIni% AND %Exp:dDataFim% 
	  AND ABB.ABB_FILIAL= %Exp:cFilAtend%
	  AND ABB.ABB_CODTEC= %Exp:cCodAtend%
	  AND ABB.ABB_ATIVO='1'
	ORDER BY ABB_DTINI, ABB_HRINI   
EndSQL

DbSelectArea("AA1")
AA1->(DbSetOrder(1))	//AA1_FILIAL+AA1_CODTEC
	
//Verifica se atendente possui matrícula no RH
If AA1->(DbSeek(xFilial("AA1")+cCodAtend))
	DbSelectArea("SRA")
	SRA->(DbSetOrder(1))	//RA_FILIAL+RA_MAT

	If SRA->(DbSeek(xFilial("SRA")+AA1->AA1_CDFUNC))
		cRAMat	:= SRA->RA_MAT 
	Else
		cRAMat	:= ""
	EndIf	 
	
	//Carrega o nome do atendente na tela
	oModel:SetValue("CABEC_ATEND", "AA1_NOMTEC", AA1->AA1_NOMTEC)
EndIf	

//Monta o Array das agendas com o intevalo de datas
For dDtRef := dDataIni To dDataFim 
	cSituacao 	:= ""
	cCorLeg		:= ""
	
	//Carregar model para permitir a verificação da situação do atendente no dia
	oModel := FWLoadModel('TECA335')
	oModel:SetOperation( MODEL_OPERATION_INSERT )
	lRet 	:= oModel:Activate()
	
	If lRet
		oAuxABB	:= oModel:GetModel( 'ITE_ABB' )
		oStruct	:= oAuxABB:GetStruct()
		oStruct:SetProperty( "*", MODEL_FIELD_OBRIGAT, .F. )
							
		If DToS(dDtRef)==(cAliasABB)->TDV_DTREF
		    If !Empty( oAuxABB:GetValue('ABB_FILIAL') )
				nTotLinhas := oAuxABB:Length()
				If nTotLinhas >= 1
					lRet := (oAuxABB:AddLine() == (nTotLinhas +1))
				EndIf
			EndIf
			lRet := oAuxABB:SetValue( 'ABB_FILIAL', (cAliasABB)->ABB_FILIAL )
			lRet := oAuxABB:SetValue( 'ABB_CODTEC', (cAliasABB)->ABB_CODTEC )
			lRet := oAuxABB:SetValue( 'ABB_ATIVO' , (cAliasABB)->ABB_ATIVO  )
			lRet := oAuxABB:SetValue( 'ABB_TIPOMV', (cAliasABB)->ABB_TIPOMV )
		EndIf		
	EndIf

	If lRet
		cSituacao := At335StAtd(cFilAtend, cCodAtend, dDtRef, oAuxABB)
	Else
		aErro   := oModel:GetErrorMessage()
	EndIf
	
	oModel:DeActivate()
	
	Do Case
		Case cSituacao == UPPER(SIT_ATEND_EFETIVO)    // "Dia de Trabalho em Posto Efetivo"
			cCorLeg := "BR_VERDE"
		Case cSituacao == UPPER(SIT_ATEND_RESERVA)    // "Dia de Trabalho em Posto de Reserva"
			cCorLeg := "BR_AMARELO"
		Case cSituacao == UPPER(SIT_ATEND_COBERTURA)  // "Dia de Trabalho em Cobertura"
			cCorLeg := "BR_PINK"
		Case cSituacao == UPPER(SIT_ATEND_NAOALOCADO) // "Nao alocado"
			cCorLeg := "BR_AZUL_CLARO"
		Case cSituacao == UPPER(SIT_ATEND_SEMAGENDA)  // "Sem agenda"
			cCorLeg := "BR_VERDE_ESCURO"
		Case cSituacao == UPPER(SIT_ATEND_FERIAS)     // "Férias"
			cCorLeg := "BR_BRANCO"
		Case cSituacao == UPPER(SIT_ATEND_AFASTA)     // "Afastamento"
			cCorLeg := "BR_LARANJA"
		Case cSituacao == UPPER(SIT_ATEND_FOLGA)      // "Folga"
			cCorLeg := "BR_AZUL"
		Case cSituacao == UPPER(SIT_ATEND_DEMISSAO)   // "Demissão"
			cCorLeg := "BR_VERMELHO"
		Case cSituacao == UPPER(SIT_ATEND_SUSPENSAO)  // "Suspensão"
			cCorLeg := "BR_MARRON_OCEAN"
		Case cSituacao == UPPER(SIT_ATEND_FALTA)      // "Falta"
			cCorLeg := "BR_PRETO"
		Case cSituacao == UPPER(SIT_ATEND_CURSO)      // "Curso"
			cCorLeg := "BR_MARRON"
		Case cSituacao == UPPER(SIT_ATEND_RECICLA)    // "Reciclagem"
			cCorLeg := "BR_VIOLETA"
	EndCase	
	
	//Se não existe registro na query, gerar registro sem agenda
	If (cAliasABB)->(Eof()) .Or. DToS(dDtRef)<>(cAliasABB)->TDV_DTREF
		AAdd(aAgenda, {	cCorLeg	,;	
					   	dDtRef	,;
					   	""		,;	
			   			""		,;
			   			""		,;
			   			""		,;
			   			""		,;
			  	 		""		,;
			   			""		,;
			   			""		,;
			  	 		""	 	,;
			  	 		""		 ;
			  	 	  } )
	Else
		While (cAliasABB)->(!Eof()) .And. DToS(dDtRef)==(cAliasABB)->TDV_DTREF
			//Grava registro da agenda 
			AAdd(aAgenda, {	cCorLeg									,;
						   	(cAliasABB)->ABB_DTINI					,;
						   	(cAliasABB)->ABB_HRINI					,;
						   	(cAliasABB)->ABB_HRFIM					,;
					   		(cAliasABB)->ABB_FILIAL					,;
				   			(cAliasABB)->B1_DESC					,;
				   			(cAliasABB)->ABB_LOCAL					,;
				  	 		(cAliasABB)->ABS_DESCRI					,;
				  	 		(cAliasABB)->TFJ_CODENT					,;
				  	 		(cAliasABB)->TFJ_LOJA					,;
				  	 		(cAliasABB)->A1_NOME					,;
				  	 		FWFilialName(,(cAliasABB)->ABB_FILIAL)	 ;
				  	 	  } )
	
			(cAliasABB)->(DbSkip())
		EndDo
	EndIf
	
Next dDtRef

oMdlABB:SetNoInsertLine(.F.)
oMdlABB:SetNoDeleteLine(.F.)
oMdlABB:SetNoUpdateLine(.F.)

For nX:=1 To Len(aAgenda)
	If !oMdlABB:IsEmpty()
		nLinha := oMdlABB:AddLine()
	EndIf
	oMdlABB:GoLine(nLinha)

	oMdlABB:LoadValue("ABB_LEG"    , aAgenda[nX, 1])
	oMdlABB:LoadValue("ABB_DTINI"  , aAgenda[nX, 2])
	oMdlABB:LoadValue("ABB_HRINI"  , aAgenda[nX, 3])
	oMdlABB:LoadValue("ABB_HRFIM"  , aAgenda[nX, 4])
	oMdlABB:LoadValue("ABB_FILIAL" , aAgenda[nX, 5])
	oMdlABB:LoadValue("B1_DESC"    , aAgenda[nX, 6])
	oMdlABB:LoadValue("ABB_LOCAL"  , aAgenda[nX, 7])
	oMdlABB:LoadValue("ABS_DESCRI" , aAgenda[nX, 8])
	oMdlABB:LoadValue("TFJ_CODENT" , aAgenda[nX, 9])
	oMdlABB:LoadValue("TFJ_LOJA"   , aAgenda[nX,10])
	oMdlABB:LoadValue("A1_NOME"    , aAgenda[nX,11])
	oMdlABB:LoadValue("ABB_NOMEFIL", aAgenda[nX,12])
Next nX

oMdlABB:GoLine(1)
oMdlABB:SetNoInsertLine(.T.)
oMdlABB:SetNoDeleteLine(.T.)

//Habilitar para edição somente o campo de legenda para exibir descrições da legenda no enter do campo ou duplo clique
oStrABB:SetProperty("*"      , MODEL_FIELD_WHEN, {||.F.})
oStrABB:SetProperty("ABB_LEG", MODEL_FIELD_WHEN, {||.T.})

(cAliasABB)->(DbCloseArea())

RestArea(aAreaSX3)
RestArea(aAreaSRA)
RestArea(aAreaAA1)
RestArea(aArea)

Return .T. 

//--------------------------------------------------------------------------------------------------------------------
Static Function At335AGLeg()
Local oLegenda  :=  FWLegend():New() 	// Objeto FwLegend.
                                                  	
oLegenda:Add("","BR_VERDE"		 , SIT_ATEND_EFETIVO   ) // "Dia de Trabalho em Posto Efetivo"
oLegenda:Add("","BR_AMARELO"	 , SIT_ATEND_RESERVA   ) // "Dia de Trabalho em Posto de Reserva"
oLegenda:Add("","BR_PINK"		 , SIT_ATEND_COBERTURA ) // "Dia de Trabalho em Cobertura"
oLegenda:Add("","BR_AZUL_CLARO"	 , SIT_ATEND_NAOALOCADO) // "Nao alocado"
oLegenda:Add("","BR_VERDE_ESCURO", SIT_ATEND_SEMAGENDA ) // "Sem agenda"
oLegenda:Add("","BR_BRANCO"		 , SIT_ATEND_FERIAS    ) // "Férias"
oLegenda:Add("","BR_LARANJA"	 , SIT_ATEND_AFASTA    ) // "Afastamento"
oLegenda:Add("","BR_AZUL"		 , SIT_ATEND_FOLGA     ) // "Folga"
oLegenda:Add("","BR_VERMELHO"	 , SIT_ATEND_DEMISSAO  ) // "Demissão"
oLegenda:Add("","BR_MARRON_OCEAN", SIT_ATEND_SUSPENSAO ) // "Suspensão"
oLegenda:Add("","BR_PRETO"	 	 , SIT_ATEND_FALTA     ) // "Falta"
oLegenda:Add("","BR_MARRON"	 	 , SIT_ATEND_CURSO     ) // "Curso"
oLegenda:Add("","BR_VIOLETA"	 , SIT_ATEND_RECICLA   ) // "Reciclagem"

oLegenda:Activate() 
oLegenda:View()
oLegenda:DeActivate()

Return Nil
