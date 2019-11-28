#INCLUDE 'TECA335.CH'
#INCLUDE 'MOVIMENTACAO.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

Static cFilBkp 	  	:= ""
Static lTecxRh	  	:= .F.
Static oMdlBKP		:= Nil
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA335
Tela de movimentação do atendente

@sample 	TECA335()  

@param		Nenhum

@return		Nil	
	
@author		Ana Maria Utsumi       
@since		22/03/2017
@version	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA335()
Local aAreaSM0 := SM0->(GetArea())
Local aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,STR0030},;	//"Fechar"
		           {.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}}

cFilBkp := cFilAnt
lTecXRh := SuperGetMv("MV_TECXRH",,.F.)	 				// Integracao Gestao de Servicos com RH?.

FWExecView(STR0031,"VIEWDEF.TECA335",MODEL_OPERATION_INSERT,,,,,aButtons)  // "Consulta"

cFilAnt := cFilBkp
cFilBkp := ""

SetKey( VK_F6, Nil )	
SetKey( VK_F7, Nil )
SetKey( VK_F8, Nil )

RestArea(aAreaSM0)

Return NIL


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef()
Definição do Modelo de Dados 

@sample 	ModelDef

@author 	Ana Maria Utsumi
@since		22/03/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()
Local cCpoView := ""
Local oModel	:= MPFormModel():New('TECA335')
Local oStruAtd	:= FWFormModelStruct():New()
Local oStruABB  := FWFormStruct(1,'ABB', {|cCampo|  AtCamposABB(cCampo,.T.,@cCpoView)})
Local oStruEsc	:= FWFormModelStruct():New()

oStruAtd:AddTable("TDV",{}, STR0001)	// "Movimentação de Atendentes"


//------------------------------------------
// Adição de campos oStruAtd
//------------------------------------------
oStruAtd:AddField( 	STR0002					,;	//[01] C Titulo do campo "Data Ref."
					STR0002					,;	//[02] C ToolTip do campo "Data Ref."
					"TDV_DTREF"				,;	//[03] C identificador (ID) do Field
					"D"						,;	//[04] C Tipo do campo 
					8						,;	//[05] N Tamanho do campo
					0						,;	//[06] N Decimal do campo 
					Nil						,;	//[07] B Code-block de validação do campo
					Nil						,;	//[08] B Code-block de validação When do campo
					Nil						,;	//[09] A Lista de valores permitido do campo
					.T.						,;	//[10] L Indica se o campo tem preenchimento obrigatório
					{|| dDataBase}			,;	//[11] B Code-block de inicializacao do campo
					Nil						,;	//[12] L Indica se trata de um campo chave
					.T.						,;	//[13] L Indica se o campo pode receber valor em uma operação de update.
					.T.						,;	//[14] L Indica se o campo é virtual
					Nil 					) 	//[15] Valid do usuario        					
					
					
oStruAtd:AddField( 	STR0003					,;	//[01] C Titulo do campo "Filial"                                     
					STR0003					,;  //[02] C ToolTip do campo "Filial"                                    
					"AA1_FILIAL"			,;  //[03] C identificador (ID) do Field                                     
					"C"						,;  //[04] C Tipo do campo                                                   
					TamSX3("AA1_FILIAL")[1]	,;  //[05] N Tamanho do campo                                                
					0						,;  //[06] N Decimal do campo                                                
					Nil						,;  //[07] B Code-block de validação do campo                                
					Nil						,;  //[08] B Code-block de validação When do campo                           
					Nil						,;  //[09] A Lista de valores permitido do campo                             
					.T.						,;  //[10] L Indica se o campo tem preenchimento obrigatório                 
					{|| cFilAnt  }			,;  //[11] B Code-block de inicializacao do campo                            
					Nil						,;  //[12] L Indica se trata de um campo chave                               
					.T.						,;  //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,;  //[14] L Indica se o campo é virtual                                     
					Nil						)   //[15] Valid do usuario                                                  
           
oStruAtd:AddField( 	STR0004					,; //[01] C Titulo do campo "Código do Atendente"                                               
					STR0004					,; //[02] C ToolTip do campo "Código do Atendente"                                               
					"AA1_CODTEC"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("AA1_CODTEC")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					{||at335VldDm()}  		,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					.T.						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.T.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          
If !lTecXRh
	       			
	oStruAtd:AddField(	STR0005					,; //[01] C Titulo do campo "Nome do Atendente"                                                
						STR0005					,; //[02] C ToolTip do campo "Nome do Atendente"                                               
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
	       			
	oStruAtd:AddField(  STR0049 				,; //[01] C Titulo do campo ""Telefone""                                                
						STR0049					,; //[02] C ToolTip do campo ""Telefone""                                               
						"AA1_FONE"				,; //[03] C identificador (ID) do Field                                             
						"C"						,; //[04] C Tipo do campo                                                           
						TamSX3("AA1_FONE")[1]	,; //[05] N Tamanho do campo                                                        
						0						,; //[06] N Decimal do campo                                                        
						Nil						,; //[07] B Code-block de validação do campo                                        
						Nil						,; //[08] B Code-block de validação When do campo                                   
						Nil						,; //[09] A Lista de valores permitido do campo                                     
						Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
						Nil						,; //[11] B Code-block de inicializacao do campo                                    
						Nil						,; //[12] L Indica se trata de um campo chave                                       
						.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
						.T.						,; //[14] L Indica se o campo é virtual                                             
						Nil						)  //[15] Valid do usuario                                                          
	       			
	oStruAtd:AddField( 	STR0006					,; //[01] C Titulo do campo "Cód Função"                                                
						STR0006					,; //[02] C ToolTip do campo "Cód Função"                                               
						"AA1_FUNCAO"			,; //[03] C identificador (ID) do Field                                             
						"C"						,; //[04] C Tipo do campo                                                           
						TamSX3("AA1_FUNCAO")[1]	,; //[05] N Tamanho do campo                                                        
						0						,; //[06] N Decimal do campo                                                        
						Nil						,; //[07] B Code-block de validação do campo                                        
						Nil						,; //[08] B Code-block de validação When do campo                                   
						Nil						,; //[09] A Lista de valores permitido do campo                                     
						Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
						Nil						,; //[11] B Code-block de inicializacao do campo                                    
						Nil						,; //[12] L Indica se trata de um campo chave                                       
						.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
						.T.						,; //[14] L Indica se o campo é virtual                                             
						Nil						)  //[15] Valid do usuario                                                          
Else

	oStruAtd:AddField(	STR0005					,; //[01] C Titulo do campo "Nome do Atendente"                                                
						STR0005					,; //[02] C ToolTip do campo "Nome do Atendente"                                               
						"RA_NOME"			,; //[03] C identificador (ID) do Field                                             
						"C"						,; //[04] C Tipo do campo                                                           
						TamSX3("RA_NOME")[1]	,; //[05] N Tamanho do campo                                                        
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
	       			
	oStruAtd:AddField(  STR0049					,; //[01] C Titulo do campo "Telefone"                                                
						STR0049					,; //[02] C ToolTip do campo "Telefone"                                               
						"RA_TELEFON"			,; //[03] C identificador (ID) do Field                                             
						"C"						,; //[04] C Tipo do campo                                                           
						TamSX3("RA_TELEFON")[1]	,; //[05] N Tamanho do campo                                                        
						0						,; //[06] N Decimal do campo                                                        
						Nil						,; //[07] B Code-block de validação do campo                                        
						Nil						,; //[08] B Code-block de validação When do campo                                   
						Nil						,; //[09] A Lista de valores permitido do campo                                     
						Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
						Nil						,; //[11] B Code-block de inicializacao do campo                                    
						Nil						,; //[12] L Indica se trata de um campo chave                                       
						.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
						.T.						,; //[14] L Indica se o campo é virtual                                             
						Nil						)  //[15] Valid do usuario                                                          
	       			
	oStruAtd:AddField( 	STR0006					,; //[01] C Titulo do campo "Cód Função"                                                
						STR0006					,; //[02] C ToolTip do campo "Cód Função"                                               
						"RA_CODFUNC"			,; //[03] C identificador (ID) do Field                                             
						"C"						,; //[04] C Tipo do campo                                                           
						TamSX3("RA_CODFUNC")[1]	,; //[05] N Tamanho do campo                                                        
						0						,; //[06] N Decimal do campo                                                        
						Nil						,; //[07] B Code-block de validação do campo                                        
						Nil						,; //[08] B Code-block de validação When do campo                                   
						Nil						,; //[09] A Lista de valores permitido do campo                                     
						Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
						Nil						,; //[11] B Code-block de inicializacao do campo                                    
						Nil						,; //[12] L Indica se trata de um campo chave                                       
						.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
						.T.						,; //[14] L Indica se o campo é virtual                                             
						Nil						)  //[15] Valid do usuario     

EndIf

oStruAtd:AddField( 	STR0007					,; //[01] C Titulo do campo "Descrição da Função"                                                
					STR0007					,; //[02] C ToolTip do campo "Descrição da Função"                                               
					"RJ_DESC"				,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("RJ_DESC")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

oStruAtd:AddField( 	STR0043					,; //[01] C Titulo do campo "Filial - Matrícula"                                               
					STR0043					,; //[02] C ToolTip do campo "Filial - Matrícula"                                               
					"AA1_MATRIC"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("AA1_CDFUNC")[1]+TamSX3("AA1_FUNFIL")[1]+3	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					.T.						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.T.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

oStruAtd:AddField( 	STR0008					,; //[01] C Titulo do campo "Cód Cargo"                                                
					STR0008					,; //[02] C ToolTip do campo "Cód Cargo"                                             
					"RA_CARGO"				,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("RA_CARGO")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

oStruAtd:AddField( 	STR0009					,; //[01] C Titulo do campo "Descrição do Cargo"                                                
					STR0009					,; //[02] C ToolTip do campo "Descrição do Cargo"                                               
					"Q3_DESCSUM"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("Q3_DESCSUM")[1]	,; //[05] N Tamanho do campo                                                        
					0						,; //[06] N Decimal do campo                                                        
					Nil						,; //[07] B Code-block de validação do campo                                        
					Nil						,; //[08] B Code-block de validação When do campo                                   
					Nil						,; //[09] A Lista de valores permitido do campo                                     
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                         
					Nil						,; //[11] B Code-block de inicializacao do campo                                    
					Nil						,; //[12] L Indica se trata de um campo chave                                       
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update.         
					.T.						,; //[14] L Indica se o campo é virtual                                             
					Nil						)  //[15] Valid do usuario                                                          

oStruAtd:AddField(	STR0010					,; //[01] C Titulo do campo "Situação do Atendente"                                                
					STR0010					,; //[02] C ToolTip do campo "Situação do Atendente"                                              
					"AA1_SITTEC"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					40                     	,; //[05] N Tamanho do campo                                                        
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


//------------------------------------------
// Adição de campos oStruABB
//------------------------------------------
oStruABB:AddField( 	""						,;	//[01] C Titulo do campo 
					""						,;	//[02] C ToolTip do campo 
					"ABB_LEG"				,;	//[03] C identificador (ID) do Field
					"BT"					,;	//[04] C Tipo do campo 
					1						,;	//[05] N Tamanho do campo
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

oStruABB:AddField( 	STR0011					,; //[01] C Titulo do campo "Desc. Local"                                                
					STR0011					,; //[02] C ToolTip do campo "Desc. Local"                                               
					"ABS_DESCRI"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("ABS_DESCRI")[1]	,; //[05] N Tamanho do campo                                                        
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

oStruABB:AddField( 	STR0012					,; //[01] C Titulo do campo "Desc. Tipo de Alocação"                                                
					STR0012					,; //[02] C ToolTip do campo "Desc. Tipo de Alocação"                                               
					"TCU_DESC"				,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("TCU_DESC")[1]	,; //[05] N Tamanho do campo                                                        
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

oStruABB:AddField( 	STR0044					,;	//[01] C Titulo do campo  "Cod.Fil.Agenda"
					STR0044					,;	//[02] C ToolTip do campo "Cod.Fil.Agenda"
					"ABB_CODFIL"			,;	//[03] C identificador (ID) do Field
					"C"						,;	//[04] C Tipo do campo 
					TamSX3("ABB_FILIAL")[1]	,;	//[05] N Tamanho do campo
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

oStruABB:AddField( 	STR0040					,;	//[01] C Titulo do campo "Nome da Filial da Agenda"
					STR0040					,;	//[02] C ToolTip do campo "Nome da Filial da Agenda"
					"ABB_NOMEFIL"			,;	//[03] C identificador (ID) do Field
					"C"						,;	//[04] C Tipo do campo 
					Length(SM0->M0_FILIAL)	,;	//[05] N Tamanho do campo
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

oStruABB:AddField( 	STR0050					,;	//[01] C Titulo do campo  "Cod. Prod."
					STR0050					,;	//[02] C ToolTip do campo "Cod. Prod."
					"ABB_CODSB1"			,;	//[03] C identificador (ID) do Field
					"C"						,;	//[04] C Tipo do campo 
					TamSX3("B1_COD")[1]	,;	//[05] N Tamanho do campo
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

oStruABB:AddField( 	STR0051					,;	//[01] C Titulo do campo  "Desc. Prod."
					STR0051					,;	//[02] C ToolTip do campo "Desc. Prod."
					"ABB_DSCSB1"			,;	//[03] C identificador (ID) do Field
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

oStruABB:AddField( 	STR0013					,; //[01] C Titulo do campo "Cliente"                                                
					STR0013					,; //[02] C ToolTip do campo "Cliente"                                               
					"ABS_CODIGO"			,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("ABS_CODIGO")[1]	,; //[05] N Tamanho do campo                                                        
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

oStruABB:AddField( 	STR0014					,; //[01] C Titulo do campo "Loja"                                                
					STR0014					,; //[02] C ToolTip do campo "Loja"                                               
					"ABS_LOJA"				,; //[03] C identificador (ID) do Field                                             
					"C"						,; //[04] C Tipo do campo                                                           
					TamSX3("ABS_LOJA")[1]	,; //[05] N Tamanho do campo                                                        
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

oStruABB:AddField( 	STR0015					,; //[01] C Titulo do campo "Nome do Cliente"                                                
					STR0015					,; //[02] C ToolTip do campo "Nome do Cliente"                                               
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

//------------------------------------------
// Adição de campos oStruEsc
//------------------------------------------
oStruEsc:AddField(	STR0016					,; //[01] C Titulo do campo "Cód Escala"                             
					STR0016					,; //[02] C ToolTip do campo "Cód Escala"                             
					"TFF_ESCALA"			,; //[03] C identificador (ID) do Field                                     
					"C"						,; //[04] C Tipo do campo                                                   
					TamSX3("TFF_ESCALA")[1]	,; //[05] N Tamanho do campo                                                
					0						,; //[06] N Decimal do campo                                                
					Nil						,; //[07] B Code-block de validação do campo                                
					Nil						,; //[08] B Code-block de validação When do campo                           
					Nil						,; //[09] A Lista de valores permitido do campo                             
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                 
					Nil						,; //[11] B Code-block de inicializacao do campo                            
					Nil						,; //[12] L Indica se trata de um campo chave                               
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,; //[14] L Indica se o campo é virtual                                    
					Nil						)  //[15] Valid do usuario                                                 
					
oStruEsc:AddField(	STR0017					,; //[01] C Titulo do campo "Descrição da Escala"                                    
					STR0017					,; //[02] C ToolTip do campo "Descrição da Escala"                                  
					"TDW_DESC"  			,; //[03] C identificador (ID) do Field                                     
					"C"						,; //[04] C Tipo do campo                                                   
					TamSX3("TDW_DESC")[1]	,; //[05] N Tamanho do campo                                                
					0						,; //[06] N Decimal do campo                                                
					Nil						,; //[07] B Code-block de validação do campo                                
					Nil						,; //[08] B Code-block de validação When do campo                           
					Nil						,; //[09] A Lista de valores permitido do campo                             
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                 
					Nil						,; //[11] B Code-block de inicializacao do campo                            
					Nil						,; //[12] L Indica se trata de um campo chave                               
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,; //[14] L Indica se o campo é virtual                                    
					Nil						)  //[15] Valid do usuario                                                

oStruEsc:AddField( STR0018					,; //[01] C Titulo do campo "Cód Turno"                                   
					STR0018					,; //[02] C ToolTip do campo "Cód Turno"                                  
					"TDV_TURNO" 			,; //[03] C identificador (ID) do Field                                     
					"C"						,; //[04] C Tipo do campo                                                   
					TamSX3("TDV_TURNO")[1]	,; //[05] N Tamanho do campo                                                
					0						,; //[06] N Decimal do campo                                                
					Nil						,; //[07] B Code-block de validação do campo                                
					Nil						,; //[08] B Code-block de validação When do campo                           
					Nil						,; //[09] A Lista de valores permitido do campo                             
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                 
					Nil						,; //[11] B Code-block de inicializacao do campo                            
					Nil						,; //[12] L Indica se trata de um campo chave                               
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,; //[14] L Indica se o campo é virtual                                     
					Nil						)  //[15] Valid do usuario                                                   

oStruEsc:AddField( 	STR0019					,; //[01] C Titulo do campo "Decrição do Turno"                                     
					STR0019					,; //[02] C ToolTip do campo "Decrição do Turno"                                    
					"R6_DESC" 				,; //[03] C identificador (ID) do Field                                     
					"C"						,; //[04] C Tipo do campo                                                   
					TamSX3("R6_DESC")[1] 	,; //[05] N Tamanho do campo                                                
					0						,; //[06] N Decimal do campo                                                
					Nil						,; //[07] B Code-block de validação do campo                                
					Nil						,; //[08] B Code-block de validação When do campo                           
					Nil						,; //[09] A Lista de valores permitido do campo                             
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                 
					Nil						,; //[11] B Code-block de inicializacao do campo                            
					Nil						,; //[12] L Indica se trata de um campo chave                               
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,; //[14] L Indica se o campo é virtual                                    
					Nil						)  //[15] Valid do usuario                                                

oStruEsc:AddField( 	STR0020					,; //[01] C Titulo do campo "Seq do Turno"                                    
					STR0020					,; //[02] C ToolTip do campo "Seq do Turno"                                   
					"TDV_SEQTRN"			,; //[03] C identificador (ID) do Field                                     
					"C"						,; //[04] C Tipo do campo                                                   
					TamSX3("TDV_SEQTRN")[1]	,; //[05] N Tamanho do campo                                                
					0						,; //[06] N Decimal do campo                                                
					Nil						,; //[07] B Code-block de validação do campo                                
					Nil						,; //[08] B Code-block de validação When do campo                           
					Nil						,; //[09] A Lista de valores permitido do campo                             
					Nil						,; //[10] L Indica se o campo tem preenchimento obrigatório                 
					Nil						,; //[11] B Code-block de inicializacao do campo                            
					Nil						,; //[12] L Indica se trata de um campo chave                               
					.F.						,; //[13] L Indica se o campo pode receber valor em uma operação de update. 
					.T.						,; //[14] L Indica se o campo é virtual                                    
					Nil						)  //[15] Valid do usuario                                                

oStruABB:SetProperty("*", MODEL_FIELD_INIT , FwBuildFeature( STRUCT_FEATURE_INIPAD, "" ) )
oStruABB:SetProperty("*", MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID , "" ) )
oStruABB:SetProperty("*", MODEL_FIELD_WHEN , FwBuildFeature( STRUCT_FEATURE_WHEN  , "" ) )

oStruAtd:SetProperty("AA1_FILIAL", MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID, 'ExistCpo("SM0", cEmpAnt+M->AA1_FILIAL)'))

oModel:AddFields('CAB_ATEND' , /*cOwner*/ , oStruAtd)
oModel:AddGrid('ITE_ABB'     ,'CAB_ATEND' , oStruABB,/*bLinePre*/,/*bLinePost*/,/*bPre*/,/*bPost*/,/*bLoad*/)
oModel:AddFields('ITE_ESCALA', 'ITE_ABB'  , oStruEsc)

oModel:GetModel("CAB_ATEND" ):SetDescription( STR0001 )	// "Movimentação de Atendentes"
oModel:GetModel("ITE_ABB"   ):SetDescription( STR0001 )	// "Movimentação de Atendentes"
oModel:GetModel("ITE_ESCALA"):SetDescription( STR0001 )	// "Movimentação de Atendentes"

oModel:SetPrimaryKey( {} )
oModel:SetActivate()

Return oModel


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
Definição da Interface Visual do Modelo

@sample 	ViewDef

@author 	Ana Maria Utsumi
@since		22/03/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView		:= FWFormView():New()
Local oModel	:= ModelDef()
Local oStruAtd	:= FWFormViewStruct():New()
Local oStruABB  := FWFormStruct(2,'ABB', {|cCampo| AtCamposABB(cCampo,.F.)})
Local oStruEsc	:= FWFormViewStruct():New()
Local bAgenda	:= {|| At335AgCar()}
Local bMovimenta:= {|| TECA336(FwModelActive()), At335AgCar() }
Local bConsuAgen:= {|| TECA335A(oModel:GetValue("CAB_ATEND","AA1_FILIAL"),oModel:GetValue("CAB_ATEND","AA1_CODTEC"))} 
Local bConsuPost:= {|| TECR331(oModel:GetValue("CAB_ATEND","TDV_DTREF"))} 

oStruAtd:AddField( "TDV_DTREF" , "01", STR0002, STR0002, Nil, "D", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Data Ref." 
oStruAtd:AddField( "AA1_FILIAL", "03", STR0003, STR0003, Nil, "C", "@!", Nil, "SM0",; 
													.T., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Filial do Atendente" 
oStruAtd:AddField( "AA1_CODTEC", "04", STR0004, STR0004, Nil, "C", "@!", Nil, "AA1335",; 
													.T., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Código" 
oStruAtd:AddField( "AA1_MATRIC", "05", STR0043, STR0043, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cód Matrícula"

If !lTecXRh													 
	oStruAtd:AddField( "AA1_NOMTEC", "06", STR0005, STR0005, Nil, "C", "@!", Nil, ""   ,;
														.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Nome do Atendente" 
	oStruAtd:AddField( "AA1_FONE"  , "07", "Telefone", "Telefone", Nil, "C", "@!", Nil, ""   ,;
														.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Telefone" 
	oStruAtd:AddField( "AA1_FUNCAO", "08", STR0006, STR0006, Nil, "C", "@!", Nil, ""   ,;
														.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cód Função"
Else
	oStruAtd:AddField( "RA_NOME", "06", STR0005, STR0005, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Nome do Atendente" 
	oStruAtd:AddField( "RA_TELEFON"  , "07", "Telefone", "Telefone", Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Telefone" 
	oStruAtd:AddField( "RA_CODFUNC", "08", STR0006, STR0006, Nil, "C", "@!", Nil, ""   ,;
														.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cód Função"
EndIf
 
oStruAtd:AddField( "RJ_DESC"   , "09", STR0007, STR0007, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Descrição da Função" 
oStruAtd:AddField( "RA_CARGO"  , "10", STR0008, STR0008, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cód Cargo" 
oStruAtd:AddField( "Q3_DESCSUM", "11", STR0009, STR0009, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Descrição do Cargo" 
oStruAtd:AddField( "AA1_SITTEC", "12", STR0010, STR0010, Nil, "C", "@!", Nil, ""   ,; 
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Situação do Atendente" 

oStruABB:AddField( "ABB_LEG"    , "01", ""     , ""     , Nil, "BT", "", Nil, ""   ,;
													.T., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // Legenda Ativo ou Não 
oStruABB:AddField( "ABS_DESCRI" , "21", STR0011, STR0011, Nil, "C" , "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Desc. Local"
oStruABB:AddField( "TCU_DESC"  , "22", STR0012, STR0012, Nil, "C" , "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Desc. Tipo de Alocação"

oStruABB:AddField( "ABB_CODSB1", "24", "Cod. Prod.", "Cod. Prod.", Nil, "C" , "", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cod. Prod."
oStruABB:AddField( "ABB_DSCSB1", "25", "Desc. Prod.", "Desc. Prod.", Nil, "C" , "", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Desc. Prod."

oStruABB:AddField( "ABB_CODFIL" , "26", STR0044, STR0044, Nil, "C" , "", Nil, ""   ,;
													.T., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cod.Fil.Agenda" 													
oStruABB:AddField( "ABB_NOMEFIL", "27", STR0040, STR0040, Nil, "C" , "", Nil, ""   ,;
													.T., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Nome da Filial da Agenda" 													.T., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Nome da Filial da Agenda" 

//Travamos na ordem 27 pra que os campos inseridos pelo o usuário seja mostrado por ultimo.
oStruABB:AddField( "ABS_CODIGO" , "27", STR0013, STR0013, Nil, "C" , "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cliente"
oStruABB:AddField( "ABS_LOJA"   , "27", STR0014, STR0014, Nil, "C" , "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Loja"
oStruABB:AddField( "A1_NOME"    , "27", STR0015, STR0015, Nil, "C" , "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Nome do Cliente" 


oStruEsc:AddField( "TFF_ESCALA", "01", STR0016, STR0016, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cód Escala" 
oStruEsc:AddField( "TDW_DESC"  , "02", STR0017, STR0017, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Descrição da Escala" 
oStruEsc:AddField( "TDV_TURNO" , "03", STR0018, STR0018, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Cód Turno" 
oStruEsc:AddField( "R6_DESC"   , "04", STR0019, STR0019, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Decrição do Turno" 
oStruEsc:AddField( "TDV_SEQTRN", "05", STR0020, STR0020, Nil, "C", "@!", Nil, ""   ,;
													.F., Nil, Nil, Nil, Nil, Nil, .T., Nil ) // "Seq do Turno" 
// Ordena a visualização correta do cabecalho da alocacao
oStruAtd:SetProperty( "TDV_DTREF"	, MVC_VIEW_ORDEM, "01" )

// Cria os grupos para agrupamentos de campos
oStruAtd:AddGroup( STR0037, STR0037, '', 2 )				//"Dados do atendente"
oStruAtd:SetProperty("*", MVC_VIEW_GROUP_NUMBER, STR0037)	//"Dados do atendente"	

oStruEsc:AddGroup( STR0038, STR0038, '', 2 )				//"Dados da escala"
oStruEsc:SetProperty("*", MVC_VIEW_GROUP_NUMBER, STR0038)	//"Dados da escala"	

oStruABB:SetProperty( "ABB_CODTFF"	, MVC_VIEW_ORDEM, "23" ) //Ordem do campo.

oView:SetModel(oModel)
oView:AddField('VIEW_ATEND' , oStruAtd, 'CAB_ATEND')
oView:CreateHorizontalBox('ATEND' , 20)
oView:SetOwnerView('VIEW_ATEND' , 'ATEND' )

oView:AddField('VIEW_ESCALA', oStruEsc, 'ITE_ESCALA')
oView:CreateHorizontalBox('ESCALA', 20)
oView:SetOwnerView('VIEW_ESCALA', 'ESCALA')

oView:AddGrid( 'VIEW_AGENDA', oStruABB, 'ITE_ABB'  ) 
oView:CreateHorizontalBox('AGENDA', 60)
oView:SetOwnerView('VIEW_AGENDA', 'AGENDA')

oView:AddUserButton( STR0024+" <F6>", '', bMovimenta)		//"Movimentar"

oView:AddUserButton( STR0025+" <F7>", '', bConsuAgen)		//"Consulta de Agendas"

oView:AddUserButton( STR0026+" <F8>", '', bConsuPost)		//"Consulta Posto Vago"
					

oView:AddUserButton( STR0027        , '', ;						//"Visualizar Cadastro do Atendente"
					{|| DbSelectArea("AA1"),;
						AA1->(DbSetOrder(1)),;	//AA1_FILIAL+AA1_CODTEC
						Iif (AA1->(DbSeek(oModel:GetValue("CAB_ATEND","AA1_FILIAL")+oModel:GetValue("CAB_ATEND","AA1_CODTEC"))),;
                             FWExecView(STR0027, "VIEWDEF.TECA020", MODEL_OPERATION_VIEW,, {||.T.} /*bCloseOk*/, {||.T.}/*bOk*/,,, {||.T.}/*bCancel*/ ),;
			                 Help( ,, 'TECA335',, STR0033, 1, 0 )) }) //"Código do atendente não encontrado nesta filial"

oView:AddUserButton( STR0028        , '', ;						//"Visualizar Controle de Dias de Direito"
					{|| Posicione("AA1",1,oModel:GetValue("CAB_ATEND","AA1_FILIAL")+oModel:GetValue("CAB_ATEND","AA1_CODTEC"),"AA1_CDFUNC"),;
						DbSelectArea("SRA"),;
						SRA->(DbSetOrder(1)),;	//RA_FILIAL+RA_MAT
                    	Iif (SRA->(DbSeek(AA1->AA1_FUNFIL+AA1->AA1_CDFUNC)),;
                             FWExecView(STR0028, "VIEWDEF.GPEA050", MODEL_OPERATION_VIEW,, {||.T.} /*bCloseOk*/, {||.T.}/*bOk*/,,, {||.T.}/*bCancel*/ ),;
                             Help( ,, 'TECA335',, STR0032, 1, 0 )) }) //"Registro do funcionário no RH não encontrado"

oView:AddUserButton( STR0029        , '', ;						// "Visualizar Ausências"
					{|| Posicione("AA1",1,oModel:GetValue("CAB_ATEND","AA1_FILIAL")+oModel:GetValue("CAB_ATEND","AA1_CODTEC"),"AA1_CDFUNC"),;
						DbSelectArea("SRA"), SRA->(DbSetOrder(1)),;	//RA_FILIAL+RA_MAT
                        Iif (SRA->(DbSeek(AA1->AA1_FUNFIL+AA1->AA1_CDFUNC)),;
                             FWExecView(STR0029, "VIEWDEF.GPEA240", MODEL_OPERATION_VIEW,, {||.T.} /*bCloseOk*/, {||.T.}/*bOk*/,,, {||.T.}/*bCancel*/ ),;
                             Help( ,, 'TECA335',, STR0032, 1, 0 )) }) //"Registro do funcionário no RH não encontrado"

oView:AddUserButton( STR0042, '', ;				//"Consulta de Ficha de Registro"
					{|| Posicione("AA1",1,oModel:GetValue("CAB_ATEND","AA1_FILIAL")+oModel:GetValue("CAB_ATEND","AA1_CODTEC"),"AA1_CDFUNC"),;
						DbSelectArea("SRA"), SRA->(DbSetOrder(1)),;	//RA_FILIAL+RA_MAT
                        Iif (SRA->(DbSeek(AA1->AA1_FUNFIL+AA1->AA1_CDFUNC)),;
                             GPEA260(),;
                             Help( ,, 'TECA335',, STR0032, 1, 0 )) }) //"Registro do funcionário no RH não encontrado"

oView:AddUserButton( STR0059, '', {|| TEC335CSV()} )	//"Importar manutenções CSV"

oView:AddUserButton( STR0036, '', {||At335GetLe()} )				//"Legenda"

oView:AddUserButton( STR0060, '', {|| PONR050() } )		//"Relatório Abono"

oView:AddUserButton( STR0061, '', {|oView| At335Manut(oView) } ) //"Vis. Manut. de Agenda"

oView:SetFieldAction("TDV_DTREF"  , bAgenda)
oView:SetFieldAction("AA1_CODTEC" , bAgenda)
oView:SetFieldAction("AA1_FILIAL" , {|oView| At335ClrData(oView) })
oView:SetFieldAction("ABB_LEG"    , {||At335GetLe()})

oView:EnableTitleView( "VIEW_AGENDA", STR0062 ) //"Dados da Agenda"

// Para evitar o problema da tela do movimentar ser chamada diversas vezes,
// a função do F6 é limpa e depois resetada no TECA336.
SetKey(VK_F6, bMovimenta)	// Movimentar
SetKey(VK_F7, bConsuAgen)	// Consulta Agenda
SetKey(VK_F8, bConsuPost)	// Consulta Posto Vago

oView:SetCloseOnOk({|| .T.} )
oView:SetViewAction("ASKONCANCELSHOW",{||.F.})

oView:SetContinuousForm()  //seta formulario continuo

Return oView

//--------------------------------------------------------------------------------------------------------------------
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
//--------------------------------------------------------------------------------------------------------------------
Static Function AtCamposABB(cCampo,lModel,cCpoView)
Local aArea      := GetArea()
Local lRet       := .T.
Local cContexto  := ""

Default cCpoView := ""

cCpoView  := "|ABB_FILIAL|ABB_CODTEC|ABB_NOMTEC|ABB_ENTIDA|ABB_CHAVE|ABB_NUMOS|ABB_HRTOT|ABB_OBSERV|ABB_SACRA|ABB_DATA|ABB_IDCFAL|ABB_CODIGO|ABB_ATIVO|ABB_CUSTO|ABB_CODTWZ|ABB_CODTW3|ABB_FILTEC|ABB_SAIU|ABB_OBSIN|ABB_OBSOUT|ABB_LATIN|ABB_LONIN|ABB_LATOUT|ABB_LONOUT|ABB_HRCHIN|ABB_HRCOUT|ABB_OBSMIN|ABB_MANIN|ABB_MANOUT|ABB_OBSMOU"

If lModel
	cContexto := Posicione("SX3",2,cCampo,"X3_CONTEXT")
	If cContexto == "V" .And. !(cCpoView $ "ABB_CODTFF")
		lRet  := .F.
	EndIf
Else
	lRet      := !(AllTrim(cCampo) $ cCpoView)
EndIf

RestArea( aArea )

Return lRet



//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335AgCar()
Carrega dados da agenda do atendente

@sample 	At335AgCar()

@return 	Nil

@author 	Ana Maria Utsumi
@since		22/03/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At335AgCar()
Local oModel    := FwModelActive()
Local oView		:= FwViewActive()
Local oMdlAA1	:= oModel:GetModel("CAB_ATEND")
Local oMdlABB   := oModel:GetModel("ITE_ABB")
Local dDtRef    := oMdlAA1:GetValue("TDV_DTREF")
Local cFil	    := oMdlAA1:GetValue("AA1_FILIAL")
Local cCodAtend := oMdlAA1:GetValue("AA1_CODTEC")
Local cNomAtend := ""
Local cFunFil	:= ""
Local cFunciona	:= ""
Local cCodFuncao:= ""
Local cCCusto	:= ""
Local cTel		:= ""
Local aAreaAA1  := AA1->(GetArea())
Local aAreaSRJ  := SRJ->(GetArea())
Local aAreaSRA  := SRA->(GetArea())
Local aAreaSQ3  := SQ3->(GetArea())
Local lOk		:= .T.

If !Empty(dDtRef) .AND. !Empty(cFil) .AND. Empty(cCodAtend)
	
	If !lTecXRh		
		oModel:GetModel("CAB_ATEND"):ClearField("AA1_NOMTEC")		
		oModel:GetModel("CAB_ATEND"):ClearField("AA1_FUNCAO")
		oModel:GetModel("CAB_ATEND"):ClearField("AA1_FONE")	
	Else
		oModel:GetModel("CAB_ATEND"):ClearField("RA_NOME")		
		oModel:GetModel("CAB_ATEND"):ClearField("RA_CODFUNC")
		oModel:GetModel("CAB_ATEND"):ClearField("RA_TELEFON")	
	EndIf		
	oModel:GetModel("CAB_ATEND"):ClearField("AA1_MATRIC")
	oModel:GetModel("CAB_ATEND"):ClearField("AA1_CODTEC")
	oModel:GetModel("CAB_ATEND"):ClearField("AA1_SITTEC")
	oModel:GetModel("CAB_ATEND"):ClearField("RJ_DESC")
	oModel:GetModel("CAB_ATEND"):ClearField("Q3_DESCSUM")
		
	oMdlABB:ClearData()
	oMdlABB:InitLine()
	
	oView:Refresh() 	
	
ElseIf !Empty(dDtRef) .AND. !Empty(cFil) .AND. !Empty(cCodAtend)		
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))	//AA1_FILIAL+AA1_CODTEC

	If AA1->(DbSeek(cFil+cCodAtend))
		cNomAtend	:= AA1->AA1_NOMTEC
		cFunFil		:= AA1->AA1_FUNFIL
		cFunciona	:= AA1->AA1_CDFUNC
		cCodFuncao	:= AA1->AA1_FUNCAO
		cCCusto		:= AA1->AA1_CC
		cTel		:= AA1->AA1_FONE
		If !lTecXRh
			oModel:SetValue("CAB_ATEND", "AA1_NOMTEC", cNomAtend)
			oModel:SetValue("CAB_ATEND", "AA1_FUNCAO", cCodFuncao)
			oModel:SetValue("CAB_ATEND", "AA1_FONE"  , cTel)
		Else
			DbSelectArea("SRA")
			SRA->(DbSetOrder(1))
			If SRA->(DbSeek(cFunFil+cFunciona))
					oModel:SetValue("CAB_ATEND", "RA_NOME"		, 	SRA->RA_NOME	)
					oModel:SetValue("CAB_ATEND", "RA_CODFUNC"	, 	SRA->RA_CODFUNC	)
					oModel:SetValue("CAB_ATEND", "RA_TELEFON"  	, 	SRA->RA_TELEFON	)
					oModel:SetValue("CAB_ATEND", "RA_CARGO"  	, 	SRA->RA_CARGO  	)
					oModel:SetValue("CAB_ATEND", "Q3_DESCSUM"	, 	DesCarCC()		)												    															    			                                                    
			Endif
		EndIf

		If lOk
			oModel:SetValue("CAB_ATEND", "AA1_MATRIC", Alltrim(cFunFil)+" - "+cFunciona)
			oModel:SetValue("CAB_ATEND", "RJ_DESC"   , Posicione("SRJ",1,xFilial("SRJ")+cCodFuncao,"RJ_DESC"   ))	//RJ_FILIAL+RJ_FUNCAO
        			                                         		
			//Atualiza agendas
			MsgRun(STR0021,STR0022,{||At335QryAg()}) //"Montando a Agenda do Atendente...""Aguarde"
			oModel:SetValue("CAB_ATEND", "AA1_SITTEC", At335StAtd(cFil, cCodAtend, dDtRef,oMdlABB))
			oView:Refresh() 
		EndIf	 
	Else
		Help( ,, 'AT335AGCAR',, STR0033, 1, 0 ) // "Código do atendente não encontrado nesta filial"
	EndIf	

EndIf		

If ValType(oMdlBKP) == "U" .And. ValType(oModel) == "O"
	oMdlBKP := oModel
EndIf

RestArea(aAreaAA1)
RestArea(aAreaSRJ)
RestArea(aAreaSRA)
RestArea(aAreaSQ3)

Return Nil


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335QryAg()
Carrega as agendas do atendente informado no grid

@sample 	At335QryAg()

@return 	.T.

@author 	Ana Maria Utsumi
@since		31/03/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At335QryAg()

Local oModel    := FwModelActive()
Local oMdlAA1   := oModel:GetModel("CAB_ATEND")
Local oMdlABB   := oModel:GetModel("ITE_ABB")
Local oStrABB   := oMdlABB:GetStruct()
Local aCpoABB   := oStrABB:GetFields()
Local dDtRef	:= oMdlAA1:GetValue("TDV_DTREF")
Local cFil		:= oMdlAA1:GetValue("AA1_FILIAL")
Local cCodAtend	:= oMdlAA1:GetValue("AA1_CODTEC")
Local cAliasQry	:= GetNextAlias()
Local nX        := 0
Local nY        := 0
Local xValor    := Nil
Local nLinha    := 1
Local aSM0 		:= AtRetSM0(cEmpAnt)
Local aTabelas  := {{"ABB",{}},{"ABQ",{}},{"TFF",{}},{"TFL",{}},{"TFJ",{}},{"TDV",{}},{"ABS",{}},{"SA1",{}},{"TCU",{}},{"TGY",{}}}
Local nPos      := 0
Local cFilABB   := ""
Local cFilABQ   := ""
Local cFilTFF   := ""
Local cFilTFL   := ""
Local cFilTFJ   := ""
Local cFilTDV   := ""
Local cFilABS   := ""
Local cFilSA1   := ""
Local cFilTCU   := ""
Local cFilTGY	:= ""
Local cGroupBy  := ""
Local cCodPrd	:= ""
Local lAloc		:= .F.
Local lCobe		:= .F.
Local aCobFer	:= {}
Local aAloc		:= {}

// Busco os códigos de todas as filiais das tabelas envolvidas.
For nX := 1 To Len(aTabelas)
	For nY := 1 To Len(aSM0)
		If aScan(aTabelas[nX,2],xFilial(aTabelas[nX,1],aSM0[nY])) == 0
			aAdd(aTabelas[nX,2],xFilial(aTabelas[nX,1],aSM0[nY]))
		EndIf
	Next nY
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "ABB" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilABB)
		cFilABB += "','"
	EndIf
	cFilABB += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "ABQ" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilABQ)
		cFilABQ += "','"
	EndIf
	cFilABQ += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "TFF" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilTFF)
		cFilTFF += "','"
	EndIf
	cFilTFF += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "TFL" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilTFL)
		cFilTFL += "','"
	EndIf
	cFilTFL += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "TFJ" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilTFJ)
		cFilTFJ += "','"
	EndIf
	cFilTFJ += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "TDV" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilTDV)
		cFilTDV += "','"
	EndIf
	cFilTDV += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "ABS" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilABS)
		cFilABS += "','"
	EndIf
	cFilABS += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "SA1" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilSA1)
		cFilSA1 += "','"
	EndIf
	cFilSA1 += aTabelas[nPos,2,nX]
Next nX

nPos := aScan(aTabelas, {|x| x[1] == "TCU" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilTCU)
		cFilTCU += "','"
	EndIf
	cFilTCU += aTabelas[nPos,2,nX]
Next nX


nPos := aScan(aTabelas, {|x| x[1] == "TGY" })

For nX := 1 To Len(aTabelas[nPos,2])
	If nX <= Len(aTabelas[nPos,2]) .And. !Empty(cFilTGY)
		cFilTGY += "','"
	EndIf
	cFilTGY += aTabelas[nPos,2,nX]
Next nX

For nX := 1 To Len(aCpoABB)
	If !(aCpoABB[nX,3] $ "ABB_LEG|ABB_CODFIL|ABB_NOMEFIL|ABB_CODSB1|ABB_DSCSB1")
		If !Empty(cGroupBy)
			cGroupBy += ","
		Else
			cGroupBy += "%"
		EndIf
		cGroupBy += aCpoABB[nX,3]
	EndIf
Next nX

cGroupBy += ", TDV.TDV_CODIGO, ABB.D_E_L_E_T_, ABB.R_E_C_N_O_, ABB.R_E_C_D_E_L_%"

BeginSql Alias cAliasQry
	COLUMN ABB_DTINI AS DATE
	COLUMN ABB_DTFIM AS DATE
	COLUMN ABB_DATA  AS DATE

	SELECT ABB.*, TDV_CODIGO, ABS.ABS_DESCRI, TCU.TCU_DESC, ABS.ABS_CODIGO, ABS.ABS_LOJA, SA1.A1_NOME
	FROM %table:ABB% ABB
	JOIN %table:ABQ% ABQ ON (ABQ.ABQ_FILIAL IN (%Exp:cFilABQ%) AND ABQ.ABQ_CONTRT||ABQ.ABQ_ITEM||ABQ.ABQ_ORIGEM=ABB.ABB_IDCFAL AND ABQ.ABQ_LOCAL=ABB.ABB_LOCAL AND ABQ.%NotDel%)
	JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL IN (%Exp:cFilTFF%) AND TFF.TFF_COD=ABQ.ABQ_CODTFF    AND TFF.%NotDel%)
	JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL IN (%Exp:cFilTFL%) AND TFL.TFL_CODIGO=TFF_CODPAI     AND TFL.%NotDel%)
	JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL IN (%Exp:cFilTFJ%) AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	JOIN (SELECT TDV.TDV_FILIAL, ABB.ABB_CODIGO AS TDV_CODIGO
    	        FROM %table:ABB% ABB 
	        	JOIN %table:TDV% TDV ON (TDV.TDV_FILIAL IN (%Exp:cFilTDV%) AND TDV.TDV_CODABB=ABB.ABB_CODIGO AND TDV.TDV_DTREF = %Exp:dDtRef% AND TDV.%NotDel%)
	            WHERE      ABB.ABB_FILTEC =  %Exp:cFil%
	  				  AND  ABB.ABB_CODTEC =  %Exp:cCodAtend%
	  				  AND  ABB.%NotDel%) TDV ON (ABB.ABB_FILIAL = TDV.TDV_FILIAL AND ABB.ABB_CODIGO = TDV_CODIGO)
    JOIN %table:ABS% ABS ON (ABS.ABS_FILIAL IN (%Exp:cFilABS%) AND ABS.ABS_LOCAL=ABB.ABB_LOCAL   AND ABS.%NotDel%)
    JOIN %table:SA1% SA1 ON (SA1.A1_FILIAL  IN (%Exp:cFilSA1%) AND SA1.A1_COD = ABS.ABS_CODIGO   AND SA1.A1_LOJA = ABS.ABS_LOJA AND SA1.%NotDel%)
    LEFT JOIN %table:TCU% TCU ON (TCU.TCU_FILIAL IN (%Exp:cFilTCU%) AND TCU_COD=ABB.ABB_TIPOMV   AND TCU.%NotDel%)
	WHERE ABB.%NotDel%
	  AND ABB.ABB_FILIAL IN (%Exp:cFilABB%)
	  AND ABB.ABB_CODIGO = TDV_CODIGO
	  AND ABB.ABB_CODTEC = %Exp:cCodAtend%
    GROUP BY %Exp:cGroupBy%
    
	ORDER BY ABB_ATIVO, ABB_CODIGO DESC
	
EndSql

oMdlABB:SetNoInsertLine(.F.)
oMdlABB:SetNoDeleteLine(.F.)
oMdlABB:SetNoUpdateLine(.F.)

oMdlABB:GoLine(1)
oMdlABB:ClearData()
oMdlABB:InitLine()

If (cAliasQry)->(Eof())
	(cAliasQry)->(DbCloseArea())
	cAliasQry	:= GetNextAlias()
	
	BeginSql Alias cAliasQry
		SELECT *
		FROM %table:TGY% TGY
		WHERE TGY.TGY_FILIAL IN (%Exp:cFilTGY%)
	      AND TGY.TGY_ATEND  =  %Exp:cCodAtend%
	      AND TGY.%NotDel%
	      AND %Exp:dDtRef% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM
	EndSql
	
	If (cAliasQry)->(!Eof())
		oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", (cAliasQry)->TGY_ESCALA )
		oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , Posicione('TDW',1,xFilial('TDW') + (cAliasQry)->TGY_ESCALA , 'TDW_DESC'))
		oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , (cAliasQry)->TGY_TURNO  )
		oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , Posicione('SR6',1,xFilial('SR6') + (cAliasQry)->TGY_TURNO , 'R6_DESC'))
		oModel:SetValue( "ITE_ESCALA", "TDV_SEQTRN", (cAliasQry)->TGY_SEQ )	
		lAloc := .T.
	EndIf

	(cAliasQry)->(DbCloseArea())
	cAliasQry	:= GetNextAlias()

	BeginSql Alias cAliasQry
		SELECT *
		FROM %table:TGZ% TGZ
		WHERE TGZ.TGZ_FILIAL IN (%Exp:cFilTGY%)
	      AND TGZ.TGZ_ATEND  =  %Exp:cCodAtend%
	      AND TGZ.%NotDel%
	      AND %Exp:dDtRef% BETWEEN TGZ.TGZ_DTINI AND TGZ.TGZ_DTFIM
	EndSql

	If (cAliasQry)->(!Eof())
		oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", (cAliasQry)->TGZ_ESCALA )
		oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , Posicione('TDW',1,xFilial('TDW') + (cAliasQry)->TGZ_ESCALA , 'TDW_DESC'))
		oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , (cAliasQry)->TGZ_TURNO  )
		oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , Posicione('SR6',1,xFilial('SR6') + (cAliasQry)->TGZ_TURNO , 'R6_DESC'))
		lCobe := .T.
	EndIf

	If !lAloc .And. !lCobe
		
		aCobFer := At581Feris(cCodAtend,dDtRef,dDtRef,.T.,.T.)
		
		If !Empty(aCobFer)
			aAloc := TxEscCalen(aCobFer[1],dDtRef,dDtRef)
	
			If !Empty(aAloc)
				oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", aAloc[1][1])
				oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , Posicione('TDW',1,xFilial('TDW') + aAloc[1][1] , 'TDW_DESC'))
				oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , aAloc[1][2])
				oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , Posicione('SR6',1,xFilial('SR6') + aAloc[1][2] , 'R6_DESC'))
				oModel:SetValue( "ITE_ESCALA", "TDV_SEQTRN", aAloc[1][3])		
			Endif
		Endif
	Endif
Else
	While (cAliasQry)->(!Eof())
		If !oMdlABB:IsEmpty()
			nLinha := oMdlABB:AddLine()
		EndIf
		oMdlABB:GoLine(nLinha)
		For nX := 1 To Len(aCpoABB)
			If aCpoABB[nX,3]=="ABB_LEG"	//Inserir legenda de agenda ativa ou não
				oMdlABB:LoadValue(aCpoABB[nX,3], At335AgLeg((cAliasQry)->ABB_ATIVO))
			ElseIf aCpoABB[nX,3]=="ABB_NOMEFIL"
				xValor := FWFilialName(,(cAliasQry)->ABB_FILIAL)
				oMdlABB:LoadValue(aCpoABB[nX,3], xValor)
			ElseIf aCpoABB[nX,3]=="ABB_CODFIL"
				xValor := (cAliasQry)->ABB_FILIAL
				oMdlABB:LoadValue(aCpoABB[nX,3], xValor)
			Elseif aCpoABB[nX,3]=="ABB_CODSB1"
				xValor := Posicione("TFF",1,xFilial("TFF")+(cAliasQry)->ABB_CODTFF,"TFF_PRODUT")
				oMdlABB:LoadValue(aCpoABB[nX,3], xValor)
				cCodPrd := xValor
			Elseif aCpoABB[nX,3]=="ABB_DSCSB1"
				xValor := Posicione("SB1",1,xFilial("SB1")+cCodPrd,"B1_DESC")
				oMdlABB:LoadValue(aCpoABB[nX,3], xValor)
				cCodPrd := ""
			Else
				If !(aCpoABB[nX,3] $ "ABB_SAIU|ABB_OBSIN|ABB_OBSOUT|ABB_LATIN|ABB_LONIN|ABB_LATOUT|ABB_LONOUT|ABB_HRCHIN|ABB_HRCOUT|ABB_OBSMIN|ABB_MANIN|ABB_MANOUT|ABB_OBSMOU")
					xValor := &("('"+cAliasQry+"')->"+aCpoABB[nX,3])
					oMdlABB:LoadValue(aCpoABB[nX,3],xValor)
				Endif
			EndIf	
		Next nX
		
		At335QryEs()
		
		(cAliasQry)->(DbSkip())
	EndDo
EndIf

oMdlABB:GoLine(1)
oMdlABB:SetNoInsertLine(.T.)
oMdlABB:SetNoDeleteLine(.T.)

//Habilitar para edição somente o campo de legenda para exibir descrições da legenda no enter do campo ou duplo clique
oStrABB:SetProperty("*"      , MODEL_FIELD_WHEN, {||.F.})
oStrABB:SetProperty("ABB_LEG", MODEL_FIELD_WHEN, {||.T.})

(cAliasQry)->(DbCloseArea())

Return .T.


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335AgLeg()
Cria legenda das agendas, indicando se agenda ativa ou não

@sample At335AgLeg(cAtivo)

@param  	cAtivo,	String,		Indica se agenda ativa ou não
     
@return 	cRet,	String,		String da cor da legenda

@author 	Ana Maria Utsumi
@since		03/04/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At335AgLeg(cAtivo)
Local cRet

If cAtivo == "1"
	cRet := "BR_VERDE"
Else
	cRet := "BR_VERMELHO"
EndIf
Return cRet


//----------------------------------------------------------------
/*/{Protheus.doc}  At335GetLe			   
Cria as informações referentes a legenda do Grid de agendas (ABB).

@sample At335GetLe()

@author 	Ana Maria Utsumi
@since		18/04/2017
@version 	P12

@return 	lRet: Retorna .T. quando a criação foi bem sucedida.
/*/
//----------------------------------------------------------------
Static Function At335GetLe()

Local oLegenda := FwLegend():New()
     
oLegenda:Add( "", "BR_VERDE"  	, STR0035) 	// "Agenda Ativa"	
oLegenda:Add( "", "BR_VERMELHO" , STR0034) 	// "Agenda Inativa"	
oLegenda:View()
DelClassIntf()

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335QryEs()
Carrega a escala da agenda da linha do grid

@sample 	At335QryEs()

@return 	.T.

@author 	Ana Maria Utsumi
@since		31/03/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At335QryEs()

Local oModel    := FwModelActive()
Local oMdlAA1   := oModel:GetModel("CAB_ATEND")
Local oMdlABB   := oModel:GetModel("ITE_ABB")
Local dDtRef	:= oMdlAA1:GetValue("TDV_DTREF")
Local cFil		:= oMdlAA1:GetValue("AA1_FILIAL")
Local cCodTec	:= oMdlAA1:GetValue("AA1_CODTEC")
Local cCodigo	:= oMdlABB:GetValue("ABB_CODIGO")

Local cAliasQry	:= GetNextAlias()
Local aAloc		:= {}

BeginSql Alias cAliasQry
	SELECT TFF_ESCALA, TFF_ORIREF, TDW_DESC, TDV_TURNO, R6_DESC, TDV_SEQTRN, TGZ_ATEND, TGZ_ESCALA, TGZ_TURNO, ABB_ATIVO
	FROM %table:ABB% ABB
	JOIN %table:ABQ% ABQ ON (ABQ.ABQ_FILIAL=%xFilial:ABQ% AND ABQ.ABQ_CONTRT||ABQ.ABQ_ITEM||ABQ.ABQ_ORIGEM=ABB.ABB_IDCFAL AND ABQ.ABQ_LOCAL=ABB.ABB_LOCAL AND ABQ.%NotDel%) 
	JOIN %table:TFF% TFF ON (TFF.TFF_FILIAL=%xFilial:TFF% AND TFF.TFF_COD=ABQ.ABQ_CODTFF AND TFF.%NotDel%)
	JOIN %table:TFL% TFL ON (TFL.TFL_FILIAL=%xFilial:TFL% AND TFL.TFL_CODIGO=TFF_CODPAI AND TFL.%NotDel%)
	JOIN %table:TFJ% TFJ ON (TFJ.TFJ_FILIAL=%xFilial:TFJ% AND TFJ.TFJ_CODIGO=TFL.TFL_CODPAI AND TFJ.%NotDel%)
	JOIN %table:TDV% TDV ON (TDV.TDV_FILIAL=%xFilial:TDV% AND TDV.TDV_CODABB=ABB.ABB_CODIGO AND TDV.%NotDel%)
	LEFT JOIN %table:TDW% TDW ON (TDW.TDW_FILIAL=%xFilial:TDW% AND TDW.TDW_COD=TFF.TFF_ESCALA AND TDW.%NotDel%)
    LEFT JOIN %table:SR6% SR6 ON (SR6.R6_FILIAL=%xFilial:SR6% AND SR6.R6_TURNO=TDV.TDV_TURNO AND SR6.%NotDel%)
	LEFT JOIN %table:TGZ% TGZ ON (TGZ.TGZ_FILIAL = %Exp:cFil% AND TGZ.TGZ_ATEND = %Exp:cCodTec% AND TGZ.%NotDel% AND %Exp:dDtRef% BETWEEN TGZ.TGZ_DTINI AND TGZ.TGZ_DTFIM)
    WHERE ABB.%NotDel%
	  AND ABB.ABB_FILIAL= %Exp:cFil%
      AND ABB.ABB_CODIGO= %Exp:cCodigo%
	  AND TDV.TDV_DTREF = %Exp:dDtRef%
EndSql

If Alltrim((cAliasQry)->TFF_ORIREF) == ""
	If Empty(Alltrim((cAliasQry)->TGZ_ATEND))
		If (cAliasQry)->ABB_ATIVO = '1'
		oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", (cAliasQry)->TFF_ESCALA )
		oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , (cAliasQry)->TDW_DESC   )
		oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , (cAliasQry)->TDV_TURNO  )
		oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , (cAliasQry)->R6_DESC    )
		oModel:SetValue( "ITE_ESCALA", "TDV_SEQTRN", (cAliasQry)->TDV_SEQTRN )
	Else

			aAloc := TxEscCalen(cCodTec,dDtRef,dDtRef)

			If !Empty(aAloc)
				oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", aAloc[1][1])
				oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , Posicione('TDW',1,xFilial('TDW') + aAloc[1][1] , 'TDW_DESC'))
				oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , aAloc[1][2])
				oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , Posicione('SR6',1,xFilial('SR6') + aAloc[1][2] , 'R6_DESC'))
				oModel:SetValue( "ITE_ESCALA", "TDV_SEQTRN", aAloc[1][3])		
			Endif
		Endif
	Else
		oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", (cAliasQry)->TGZ_ESCALA )
		oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , Posicione('TDW',1,xFilial('TDW') + (cAliasQry)->TGZ_ESCALA , 'TDW_DESC'))
		oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , (cAliasQry)->TGZ_TURNO  )
		oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , Posicione('SR6',1,xFilial('SR6') + (cAliasQry)->TGZ_TURNO , 'R6_DESC'))
		oModel:SetValue( "ITE_ESCALA", "TDV_SEQTRN", "" )
	Endif
Else
	oModel:SetValue( "ITE_ESCALA", "TFF_ESCALA", " "     )
	oModel:SetValue( "ITE_ESCALA", "TDW_DESC"  , STR0041 )	//"Escala de Reforço"
	oModel:SetValue( "ITE_ESCALA", "TDV_TURNO" , " "     )
	oModel:SetValue( "ITE_ESCALA", "R6_DESC"   , " "     )
	oModel:SetValue( "ITE_ESCALA", "TDV_SEQTRN", " "     )
EndIf

(cAliasQry)->(DbCloseArea())

Return .T.


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335ChkSu()
Verifica se há inconsistencia de Suspensão

@sample At335ChkSu(cFilTec, cCodTec, dDataIni, dDataFim)

@param  	cFilTec		String	Filial do atendente
@param  	cCodTec		String	Código do atendente
@param  	dDataIni	Date	Data inicial de verificação 
@param  	dDataFim	Date	Data Final de verificação
     
@return 	lRet		Boolean	Retorna .T. se o atendente suspenso

@author 	Ana Maria Utsumi
@since		31/08/2016
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At335ChkSu(cFilTec, cCodTec, dDataIni, dDataFim)

Local lRet		:= .F.
Local tmpSus 	:= ""
Local aAreaTIT	:= TIT->(GetArea())
Local aArea		:= GetArea()
	
//Verificar se atendente suspenso
tmpSus:=GetNextAlias()
BeginSql Alias tmpSus
	SELECT TIT_CODIGO
	FROM %table:TIT% TIT
	WHERE TIT.TIT_FILIAL =%Exp:cFilTec%
	AND TIT.TIT_CODTEC =%Exp:cCodTec%
	AND ((%Exp:dDataIni% BETWEEN TIT.TIT_DATA AND DATEADD(DAY,TIT.TIT_QTDDIA-1,TIT.TIT_DATA))
	     OR
	     (%Exp:dDataFim% BETWEEN TIT.TIT_DATA AND DATEADD(DAY,TIT.TIT_QTDDIA-1,TIT.TIT_DATA))
	    )
	AND TIT.TIT_AFASTA="1"
	AND TIT.%NotDel%
EndSql
DbSelectArea(tmpSus)
	
If !(tmpSUS)->(Eof())
	lRet := .T.
EndIf

(tmpSus)->(DbCloseArea())
	
RestArea(aAreaTIT)
RestArea(aArea)

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335ChkAu()
Verifica se atendente ausente e qual o motivo da ausência

@sample At335ChkAu(cFilTec, cCodTec, dData)

@param  cFilTec	, String	, Filial do atendente
@param  cCodTec	, String	, Código do atendente
@param  dData	, Date		, Data de verificação 
@param	oModelAg, Object	, Objeto da Model
     
@return aRet	Array 	Retorna o motivo da ausência do atendente e o período inicial e final do evento
		Estrutura do array:
		[1]-Motivo da ausência (1 - Falta / 2 - Reciclagem / 3 - Curso / 4 - Folga / 0 - Dia de Folga)
		[2]-Descrição do motivo 
		[3]-Data inicial
		[4]-Data final

@author 	Ana Maria Utsumi
@since		01/09/2016
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At335ChkAu(cFilTec, cCodTec, dData, oModelAg)

Local aRet	 	:= {}
Local tmpAus 	:= ""
Local cAliasTGY	:= ""
Local cAliasTGZ	:= ""
Local aAreaAA1	:= AA1->(GetArea())
Local aAreaTFF	:= TFF->(GetArea())
Local aArea		:= GetArea()
Local lRetAgenda:= .F.
Local lRet		:= .F.
Local aTabPadrao:= {}
Local aTabCalend:= {}	 
Local cSituacao	:= ""
Local cEscala	:= ""
Local cTurno	:= ""
Local cSeq		:= ""
Local cCodTFF	:= ""
Local cReserva	:= ""
Local oModelBkp := FWModelActive()
Local cQry		:= ""
Local lOkABB	:= .F.
Default oModelAg	:= Nil
	
//Verifica se atendente ausente através de manutenção na tela de movimentação
tmpAus:=GetNextAlias()
BeginSql Alias tmpAus
	SELECT TW5.TW5_TPLANC, TW5.TW5_DTINI, TW5.TW5_DTFIM, TW5.R_E_C_N_O_ REC
	FROM %table:TW5% TW5
	WHERE TW5.TW5_FILIAL =%Exp:cFilTec%
	  AND TW5.TW5_ATDCOD =%Exp:cCodTec%
  	  AND %Exp:dData% >= TW5.TW5_DTINI AND (%Exp:dData%<=TW5.TW5_DTFIM OR TW5.TW5_DTFIM=%Exp:''%)
	  AND TW5.%NotDel%
EndSql
DbSelectArea(tmpAus)
	
If !(tmpAus)->(Eof())	
	Do Case
		Case (tmpAus)->TW5_TPLANC=="1"
			cSituacao := SIT_ATEND_FALTA
		Case (tmpAus)->TW5_TPLANC=="2"
			cSituacao := SIT_ATEND_RECICLA
		Case (tmpAus)->TW5_TPLANC=="3"
			cSituacao := SIT_ATEND_CURSO
		Case (tmpAus)->TW5_TPLANC=="4"	
			cSituacao := SIT_ATEND_FOLGA		
		Case (tmpAus)->TW5_TPLANC=="7"	
			cSituacao := SIT_ATEND_FALTAFIXA		
		Case (tmpAus)->TW5_TPLANC=="8"	
			cSituacao := SIT_ATEND_ADISPEMP		
	Endcase

	AAdd(aRet,{(tmpAus)->TW5_TPLANC	,;
		        cSituacao			,;
  	    	   	(tmpAus)->TW5_DTINI ,;
				(tmpAus)->TW5_DTFIM ,;
				(tmpAus)->REC 		})
			  
Else
	//Quando é projeção de agenda.
	//Localiza atendente
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))	//AA1_FILIAL+AA1_CODTEC                                                                                                                                           
	AA1->(DbSeek(cFilTec+cCodTec))

	If oModelAg<>Nil .And. !Empty(oModelAg:GetValue("ABB_CODIGO"))
		lOkABB := !(oModelAg:SeekLine({{"ABB_ATIVO","1"}}))
	Else
		cQry := At335Agend(cFilTec, cCodTec, dData)
		lOkABB := (cQry)->(!EOF())
		(cQry)->(DbCloseArea())
	Endif
	//Executa o CriaCalend() caso o atendente sem agenda para identificar se é dia de folga
	If Alltrim(AA1->AA1_CDFUNC)<>"" .And. lOkABB
		//Verifica se atendente alocado
		cAliasTGY	:= GetNextAlias()
		lRet		:= At336TGYChk( cAliasTGY, cFilTec, cCodTec, dData, .T., "3" )
		
		DbSelectArea("TDX")
		TDX->(DbSetOrder(1))	//TDX_FILIAL+TDX_COD                                                                                                                                           

		If lRet .And. TDX->(DbSeek(xFilial("TDX")+(cAliasTGY)->TGY_CODTDX))
   			cEscala	:= TDX->TDX_CODTDW
   			cTurno	:= TDX->TDX_TURNO
   			cSeq	:= TDX->TDX_SEQTUR
   			cCodTFF	:= (cAliasTGY)->TGY_CODTFF
   		Else
   			cAliasTGZ	:= GetNextAlias()
 			lRet		:= At336TGZChk( cAliasTGZ, cFilTec, cCodTec, dData)
			If lRet
				cEscala	:= (cAliasTGZ)->TGZ_ESCALA
   				cTurno	:= (cAliasTGZ)->TGZ_TURNO
   				cSeq	:= (cAliasTGZ)->TGZ_SEQ
   				cCodTFF	:= (cAliasTGZ)->TGZ_CODTFF
   			EndIf
			(cAliasTGZ)->(DbCloseArea())
		EndIf
		(cAliasTGY)->(DbCloseArea())
	
		//Localiza recurso humano
		DbSelectArea("TFF")
		TFF->(DbSetOrder(1))	//TFF_FILIAL+TFF_COD                                                                                                                                           
		TFF->(DbSeek(xFilial("TFF")+cCodTFF))
		cCalend := TFF->TFF_CALEND
	
		If cEscala<>""
			U_PNMSEsc(cEscala)	//Atribui variável estática _cEscala para usar em função CriaCalend()
			U_PNMSCal(cCalend)	//Informar calendario     
		
			lRetAgenda := CriaCalend(dData	   		,;	//01 -> Data Inicial do Periodo
									 dData			,;	//02 -> Data Final do Periodo
									 cTurno			,;	//03 -> Turno Para a Montagem do Calendario
								 	 cSeq			,;	//04 -> Sequencia Inicial para a Montagem Calendario
								 	 @aTabPadrao	,;	//05 -> Array Tabela de Horario Padrao
								 	 @aTabCalend	,;	//06 -> Array com o Calendario de Marcacoes  
									 AA1->AA1_FUNFIL,;	//07 -> Filial para a Montagem da Tabela de Horario
									 AA1->AA1_CDFUNC,;	//08 -> Código da matrícula do atendente
									 )

			// Limpar as variáveis estáticas
			U_PNMSEsc(Nil)
			U_PNMSCal(Nil)
				
			If len(aTabCalend)>0 .And. aTabCalend[01][06] $ "N"
					AAdd(aRet,{	"0" 				,;
						       	SIT_ATEND_FOLGA     ,;
			  	    		   	dData				,;
								dData   			,;
								0 					})
							  
			EndIf
		EndIf
	EndIf
EndIf		

(tmpAus)->(DbCloseArea())
FWModelActive( oModelBkp )
RestArea(aAreaAA1)
RestArea(aAreaTFF)
RestArea(aArea)
	
Return aRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335StAtd()
Verifica situação do dia do atendente

@sample At335StAtd(cFilTec, cCodTec, dData)

@param  cFilTec		, String	, Filial do atendente
@param  cCodTec		, String	, Código do atendente
@param  dData		, Date		, Data de verificação 
@param	oModelAg	, Object	, Objeto da model

@return cRet	String 	Retorna situação do atendente no dia

@author 	Ana Maria Utsumi
@since		01/09/2016
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At335StAtd(cFilTec, cCodTec, dData, oModelAg)

Local cRet 		:= ""
Local cMatric 	:= ""
Local aAreaAA1 	:= AA1->(GetArea())
Local cAliasTGY	:= ""
Local cAliasTGZ	:= ""
Local cReserva  := "0"
Local cEscala	:= ""
Local cTurno	:= ""
Local cSeq		:= ""
Local dUltAlo	:= CtoD("  /  /    ")
Local aChkFe	:= {.F.,.F.,.F.,.F.}
Local lFerias	:= .F.
Local cTipRt	:= ""
Local lAfastado	:= .F.
Local lSuspenso := .F.
Local aAusencia	:= {} 
Local lEfetiv	:= .T.
Default oModelAg	:= Nil

//Posiciona registro de atendente para buscar o código da matrícula
DbSelectArea("AA1")	
AA1->(DbSetOrder(1))//AA1_FILIAL + AA1_CODTEC
If AA1->(DbSeek(cFilTec+cCodTec))
	cMatric := AA1->AA1_CDFUNC
EndIf
	
//Verifica se atendente esta de férias 
aChkFe 	:= At570ChkFe(cFilTec, cMatric, dData, dData)

lFerias	:= aChkFe[4]
		
//Verifica se atendente afastado
lAfastado	:= At570ChkAf(cFilTec, cMatric, dData, dData)
		
//Verifica se atendente suspenso 
lSuspenso	:= At335ChkSu(cFilTec, cCodTec, dData, dData)
		
//Verifica se atendente ausente e retorna o motivo (por curso, reciclagem, folga ou falta) 
aAusencia	:= At335ChkAu(cFilTec, cCodTec, dData, oModelAg)

//Define a descrição da situação atual do atendente
Do Case 
	Case lFerias
		cRet := SIT_ATEND_FERIAS	//"Férias"
	Case lSuspenso
		cRet := SIT_ATEND_SUSPENSAO	//"Suspensão" 
	Case Len(aAusencia) > 0 .And. aAusencia[1,1] $'|1|2|3|7|8' 
		Do Case
			Case aAusencia[1,1]=='1'
				cRet := SIT_ATEND_FALTA		//"Falta"
			Case aAusencia[1,1]=='2'
				cRet := SIT_ATEND_RECICLA	//"Reciclagem"
			Case aAusencia[1,1]=='3'
				cRet := SIT_ATEND_CURSO		//"Curso"
			Case aAusencia[1,1]=='7'
				cRet := SIT_ATEND_FALTAFIXA	//"Falta Fixa"
			Case aAusencia[1,1]=='8'
				cRet := SIT_ATEND_ADISPEMP	//"A Disposição da Empresa"
		EndCase
	Case lAfastado
		cRet := SIT_ATEND_AFASTA	//"Afastamento"
	Otherwise
		
		//Verifica se atendente alocado
		cAliasTGY	:= GetNextAlias()
		lRet		:= At336TGYChk( cAliasTGY, cFilTec, cCodTec, dData, .T., "3" )
		DbSelectArea("TDX")
		TDX->(DbSetOrder(1))	//TDX_FILIAL+TDX_COD                                                                                                                                           

		If lRet .And. TDX->(DbSeek(xFilial("TDX")+(cAliasTGY)->TGY_CODTDX))
   			cEscala	:= TDX->TDX_CODTDW
   			cTurno	:= TDX->TDX_TURNO
   			cSeq	:= TDX->TDX_SEQTUR
   			dUltAlo := (cAliasTGY)->TGY_ULTALO
   			cReserva:= (cAliasTGY)->TCU_RESTEC

			lEfetiv := !(dData == sTod((cAliasTGY)->TGY_DTINI) 	.And.; 
					   	 dData == sTod((cAliasTGY)->TGY_DTFIM) 	.And.;
					     dData == sTod((cAliasTGY)->TGY_ULTALO)) 

   		Else
   			cAliasTGZ	:= GetNextAlias()
 			lRet		:= At336TGZChk( cAliasTGZ, cFilTec, cCodTec, dData)
			If lRet
				cEscala	:= (cAliasTGZ)->TGZ_ESCALA
   				cTurno	:= (cAliasTGZ)->TGZ_TURNO
   				cSeq	:= (cAliasTGZ)->TGZ_SEQ
   				dUltAlo := (cAliasTGY)->TGY_ULTALO
   				cReserva:= "0"
   			EndIf
			(cAliasTGZ)->(DbCloseArea())
		EndIf
		(cAliasTGY)->(DbCloseArea())
		
		//Verifica se encontrou registro na ABB
		If oModelAg<>Nil .And. !oModelAg:isempty()
		
			If oModelAg:SeekLine({{"ABB_ATIVO","1"}})
		
				If (oModelAg:GetValue("ABB_TIPOMV") $ TIPALO_COBERTURA + '|' + TIPALO_FOLGATRAB + '|' + TIPALO_FOLGATRABCN + '|' + TIPALO_FTCNCOMP) .Or. cReserva == "0" // 002 = Tipo de alocação de cobertura
					cRet := SIT_ATEND_COBERTURA		//"Dia de Trabalho em Cobertura" 
				ElseIf cReserva == "1" 
					cRet := SIT_ATEND_RESERVA	    //"Dia de Trabalho em Posto de Reserva"
				ElseIf (cReserva == "2" .Or. Empty(cReserva)) .And. lEfetiv
					cRet := SIT_ATEND_EFETIVO	    //"Dia de Trabalho em Posto Efetivo"
				ElseIf cReserva == "2" .Or. Empty(cReserva)
					cRet := SIT_ATEND_DIARIO		//"Dia de Trabalho em Posto Diario"
				EndIf			
			Else
				//Se não encontrou registro na ABB, identificar se é um dia de folga, ou se está sem agenda ou não está alocado
				If lRet
					If Len(aAusencia) > 0 .And. aAusencia[1,1]$'|4|0' .And. dUltAlo<DToS(dData) .And. cReserva <> "0"
						cRet := SIT_ATEND_SEMAGENDA	    //"Sem Agenda"
					Else
						cRet := SIT_ATEND_FOLGA			//"Folga"
					EndIf	
				Else
					//Quando pertencer a rota do ferista.
					If At581TpRot(cCodTec) == "4" 
						cRet := SIT_ATEND_FOLGA         //"Folga"
					Else
						cRet := SIT_ATEND_NAOALOCADO    //"Não Alocado"
					Endif
				EndIf			
			Endif

		Else
			cQry := At335Agend(cFilTec, cCodTec, dData)
			If (cQry)->(!EOF())
				
				If ((cQry)->ABB_TIPOMV $ TIPALO_COBERTURA + '|' + TIPALO_FOLGATRAB + '|' + TIPALO_FOLGATRABCN + '|' + TIPALO_FTCNCOMP) .Or. cReserva == "0" // 002 = Tipo de alocação de cobertura
					cRet := SIT_ATEND_COBERTURA		//"Dia de Trabalho em Cobertura" 
				ElseIf cReserva == "1" 
					cRet := SIT_ATEND_RESERVA	    //"Dia de Trabalho em Posto de Reserva"
				ElseIf (cReserva == "2" .Or. Empty(cReserva)) .And. lEfetiv
					cRet := SIT_ATEND_EFETIVO	    //"Dia de Trabalho em Posto Efetivo"
				ElseIf cReserva == "2" .Or. Empty(cReserva)
					cRet := SIT_ATEND_DIARIO	 	//"Dia de Trabalho em Posto Diario"
				EndIf
			Else
				//Se não encontrou registro na ABB, identificar se é um dia de folga, ou se está sem agenda ou não está alocado
				If lRet
					If Len(aAusencia) > 0 .And. aAusencia[1,1]$'|4|0' .And. dUltAlo<DToS(dData) .And. cReserva <> "0"
						cRet := SIT_ATEND_SEMAGENDA	    //"Sem Agenda"
					Else
						cRet := SIT_ATEND_FOLGA			//"Folga"
					EndIf
				Else
					//Quando pertencer a rota do ferista.
					If At581TpRot(cCodTec) == "4" 
						cRet := SIT_ATEND_FOLGA         //"Folga"
					Else
						cRet := SIT_ATEND_NAOALOCADO    //"Não Alocado"
					Endif
				EndIf
			Endif
			(cQry)->(DbCloseArea())
		EndIf
EndCase

If ExistBlock("AT335SIT")
	cRet := ExecBlock("AT335SIT",.F.,.F.,{cFilTec, cCodTec, dData, cRet})
EndIf

RestArea(aAreaAA1)

Return Upper(cRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335ClrData()
Limpa os dados da view do TECA335.

@sample At335ClrData(oView)
@param  oView	Objeto	View do TECA335
@return Nil
@author 	Leandro Dourado
@since		01/04/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At335ClrData(oView)
Local oModel  := oView:GetModel()
Local oMdlABB := oModel:GetModel("ITE_ABB")

If !Empty(oModel:GetValue("CAB_ATEND","AA1_CODTEC"))
	If !lTecXRh		
		oModel:GetModel("CAB_ATEND"):ClearField("AA1_NOMTEC")		
		oModel:GetModel("CAB_ATEND"):ClearField("AA1_FUNCAO")	
	Else
		oModel:GetModel("CAB_ATEND"):ClearField("RA_NOME")		
		oModel:GetModel("CAB_ATEND"):ClearField("RA_CODFUNC")
	EndIf
	
	oModel:GetModel("CAB_ATEND"):ClearField("AA1_CODTEC")
	oModel:GetModel("CAB_ATEND"):ClearField("AA1_SITTEC")
	oModel:GetModel("CAB_ATEND"):ClearField("RJ_DESC")
	oModel:GetModel("CAB_ATEND"):ClearField("Q3_DESCSUM")
		
	oMdlABB:ClearData()
	oMdlABB:InitLine()
	
	oView:Refresh() 
EndIf

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335AtdFil()
Consulta específica de atendentes, podendo enxergar outras filiais. 
Consulta - AA1335.

@sample At335AtdFil()
@return Nil
@author 	Leandro Dourado
@since		01/04/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At335AtdFil()
Local aArea      := GetArea()
Local oModel     := FwModelActive()
Local cFilAA1    := ""
Local cFilQry    := ""
Local cCodAtend  := ""
Local aCmpAA1	 := {}
Local aHeaderAA1 := {STR0004, STR0005}  //"Filial"###"Código do Atendente"###"Nome do Atendente"
Local cAliasQry	 := ""
Local nSelecao   := 0
Local lMovAgil 	 := IsInCallStack("TECA335")
Local lMovimentar:= IsInCallStack("TECA336")
Local dDtRef     := Ctod('')



If lMovAgil .And. !lMovimentar
	cFilAA1 := FwFldGet("AA1_FILIAL")
	dDtRef     := oModel:GetModel("CAB_ATEND"):GetValue("TDV_DTREF")
Elseif lMovimentar
	cFilAA1 := FwFldGet("TW3_TECFIL")
	dDtRef     := oModel:GetModel("TW3MASTER"):GetValue("TW3_DTMOV")
Else
	DbSelectArea("AA1")
	cFilAA1 := xFilial("AA1")
Endif

cFilQry    := FwxFilial("AA1",cFilAA1)

cAliasQry := GetNextAlias()

BeginSql Alias cAliasQry
	SELECT AA1.AA1_FILIAL, AA1.AA1_CODTEC, AA1.AA1_NOMTEC, SRA.RA_NOME, SRA.RA_MAT
	
	FROM %table:AA1% AA1
	INNER JOIN %table:SRA% SRA ON SRA.RA_FILIAL = %Exp:cFilAA1% AND 
		SRA.RA_MAT=AA1.AA1_CDFUNC AND SRA.%NotDel%
	WHERE   AA1.AA1_FILIAL = %Exp:cFilAA1%
		AND AA1.%NotDel%
	
	ORDER BY AA1.AA1_FILIAL,AA1.AA1_CODTEC, AA1.AA1_NOMTEC, SRA.RA_NOME
EndSql	

DbSelectArea(cAliasQry)
(cAliasQry)->(DbGoTop())
While (cAliasQry)->(!EOF())
	If !lTecXRh	
		AAdd(aCmpAA1,                 ;
		   {(cAliasQry)->AA1_CODTEC  ,;     //Código do Atendente
			(cAliasQry)->AA1_NOMTEC  })   	//Nome do Atendente
	ElseIf !At570ChkDm((cAliasQry)->AA1_FILIAL,(cAliasQry)->RA_MAT,dDtRef,dDtRef  )
	
		AAdd(aCmpAA1,                 ;
		   {(cAliasQry)->AA1_CODTEC  ,;     //Código do Atendente
			(cAliasQry)->RA_NOME  })   	//Nome do Atendente
	EndIf
			
	(cAliasQry)->(DbSkip())
Enddo
(cAliasQry)->(DbCloseArea())

If Len(aCmpAA1) > 0
	nSelecao := At335F3Atd( aHeaderAA1, aCmpAA1, STR0047+AllTrim(cFilAA1),,,aHeaderAA1,cFilAA1 ) //"Atendentes da filial "
	
	If	nSelecao > 0
		cCodAtend := aCmpAA1[ nSelecao, 1 ]
	Else 
		cCodAtend := ""
	EndIf
Else
	Help("",1,"AA1335",,STR0046,2,0) //"Não foram encontrados atendentes para a filial informada!"
EndIf

VAR_IXB := cCodAtend

RestArea( aArea )

Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335ChkAtd()
Consulta específica de atendentes, podendo enxergar outras filiais.

@sample At335ChkAtd()
@return Nil
@author 	Leandro Dourado
@since		01/04/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At335ChkAtd( cFilAA1, cCodAtend )
Local cAliasQry := GetNextAlias()
Local lRet      := .T.

BeginSql Alias cAliasQry
	SELECT AA1.AA1_FILIAL, AA1.AA1_CODTEC, AA1.AA1_NOMTEC
	
	FROM %table:AA1% AA1
	
	WHERE   AA1.AA1_FILIAL = %Exp:cFilAA1%
		AND AA1.AA1_CODTEC = %Exp:cCodAtend%
		AND AA1.%NotDel%
	
	ORDER BY AA1.AA1_FILIAL,AA1.AA1_CODTEC, AA1.AA1_NOMTEC
EndSql	

(cAliasQry)->(DbGoTop())

lRet := (cAliasQry)->( !Eof() )

(cAliasQry)->(DbCloseArea())

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtRetSM0()
Retorna todas as filiais de um mesmo grupo de empresas.

@sample     AtRetSM0()
@return     Nil
@author 	Leandro Dourado
@since		11/07/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function AtRetSM0( cCodEmp )
Local aRet  := {}
Local aArea := SM0->(GetArea())

DbSelectArea("SM0")
SM0->(DbSetOrder(1))
SM0->(DbGoTop())

While SM0->(!Eof())
	If Alltrim(SM0->M0_CODIGO) == Alltrim(cCodEmp)
		aAdd(aRet, SM0->M0_CODFIL)
		SM0->(dbSkip())	
	EndIf
Enddo

RestArea( aArea )

Return aRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335F3Atd
Consulta de atendente - AA1_CODTEC e TW3_TECSUB.

@author Kaique Schiller
@since 04/12/2017
@return Lógico.
/*/
//--------------------------------------------------------------------------------------------------------
Function At335F3Atd( aHeadTms, aItemTms, cTitulo, lCancel, aNewButton, aCabec, cFilAA1)
Local nTmsItem	 := 0
Local nTmsOpcA	 := 0
Local oTmsBtn1
Local oTmsBtn2
Local oTmsDlg
Local oTmsBrw
Local oNewBtn
Local bActionBtn

//-- Tratamento da Janela
Local aCoordWnd  := {}
Local aCoordObj  := {}
Local aCoordPE   := {}
Local nHRes      := oMainWnd:nClientWidth //--Resolucao horizontal do monitor     
Local nAjuste    := 0
Local bActionPsq := {}
Local aAtend	 := {}
Local cGetSit	 := ""
Local oSaySit	 := Nil
Local oGetSit	 := Nil

DEFAULT lCancel    := .T.
DEFAULT aNewButton := {}
DEFAULT aCabec     := {}
If ValType(aCabec) == "A"
	If Len(aCabec) > 0
		bActionPsq := {||TMSPesqBrw(aItemTms,aCabec,oTmsBrw,.F.),aAtend := aItemTms[ oTmsBrw:nAT ],At335Sit(cFilAA1,@cGetSit,aAtend),oGetSit:Refresh()}
	EndIf	
EndIf	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Trata as Coordenadas da tela/objetos de acordo com a resolucao de tela ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ                                                                                
If ( Upper(Alltrim(GetTheme())) == "FLAT") .Or. SetMdiChild()
	nAjuste := 0.90
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³TEMA: OCEAN e CLASSIC³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
		nAjuste := 0.8
	ElseIf (nHRes == 798) .Or. (nHRes == 800) // Resolucao 800x600
		nAjuste := 1
	Else // Resolucao 1024x768 e acima
		nAjuste := 1.1
	EndIf
EndIf

//-- Coordenadas da Janela
aCoordWnd := {	0 ,; 
				0,; 
				Int(350 * nAjuste),; 
				Int(850 * nAjuste) }

If ValType(aCabec) == "A"
	If Len(aCabec) > 0
		//-- Coordenadas dos objetos da tela
		aCoordObj := {		{Int(5   * nAjuste),; 	//
							 Int(5   * nAjuste),;	//--  Coordenadas do TWBrowse
							 Int(370 * nAjuste),;	//
							 Int(145 * nAjuste)},;	//
							{Int(5  * nAjuste), Int(380 * nAjuste) },;	   //-- Coordenadas do Botao "OK"
							{Int(20 * nAjuste), Int(380 * nAjuste)},;	   //-- Coordenadas do Botao "CANCELAR"
							{Int(35 * nAjuste), Int(380 * nAjuste)},;      //-- Coordenadas do Botao adicional, passado pelo parametro aNewButton
							{Int(50 * nAjuste), Int(380 * nAjuste)},;	   //-- Coordenadas do Botao Pesquisar
							{Int(156* nAjuste), Int(10  * nAjuste)},;	   //-- Coordenadas da descrição da situação
							{Int(156* nAjuste), Int(45  * nAjuste)}}	   //-- Coordenadas do campo da situação
							
	Else					
		//-- Coordenadas dos objetos da tela
		aCoordObj := {	{Int(5   * nAjuste),; 	//
						 Int(5   * nAjuste),;	//--  Coordenadas do TWBrowse
						 Int(370 * nAjuste),;	//
						 Int(145 * nAjuste)},;	//
						{Int(5  * nAjuste), Int(380 * nAjuste)},;	//-- Coordenadas do Botao "OK"
						{Int(20 * nAjuste), Int(380 * nAjuste)},;	//-- Coordenadas do Botao "CANCELAR"
						{Int(35 * nAjuste), Int(380 * nAjuste)},;	//-- Coordenadas do Botao adicional, passado pelo parametro aNewButton
						{Int(156* nAjuste), Int(10  * nAjuste)},;	   //-- Coordenadas da descrição da situação
						{Int(156* nAjuste), Int(45  * nAjuste)}}	   //-- Coordenadas do campo da situação
	EndIf
EndIf

DEFINE MSDIALOG oTmsDlg TITLE STR0067 +" "+ cTitulo From aCoordWnd[1],aCoordWnd[2] To aCoordWnd[3],aCoordWnd[4] OF oMainWnd PIXEL //"Consulta padrão"   

oTmsBrw := TWBrowse():New( aCoordObj[1,1], aCoordObj[1,2], aCoordObj[1,3], aCoordObj[1,4],, aHeadTms,,oTmsDlg,,,,{|| At335Sit(cFilAA1,@cGetSit,aItemTms[ oTmsBrw:nAT ]),oGetSit:Refresh()},,,,,,,,.T.,,.T. )

oSaySit := TSay():New( Iif( ValType(aCabec) == "A" ,aCoordObj[6,1],aCoordObj[5,1]) , Iif( ValType(aCabec) == "A" ,aCoordObj[6,2],aCoordObj[5,2]), { || STR0068 }, oTmsDlg,,,,,,.T.,,, 060, 10 ) //"Situação"
oGetSit := TGet():New( Iif( ValType(aCabec) == "A" ,aCoordObj[7,1],aCoordObj[6,1]) , Iif( ValType(aCabec) == "A" ,aCoordObj[7,2],aCoordObj[6,2]), { | u | If( PCount() == 0, cGetSit, cGetSit := u ) },oTmsDlg,150, 010, "!@",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cGetSit",,,,  )

oTmsBrw:SetArray( aItemTms )
oTmsBrw:bLine := { || aAtend := aItemTms[ oTmsBrw:nAT ] }
oTmsBrw:bLDblClick := { || ( nTmsOpcA := 1, nTmsItem := oTmsBrw:nAt, oTmsDlg:End() ) }

DEFINE SBUTTON oTmsBtn1 FROM  aCoordObj[2,1], aCoordObj[2,2] PIXEL TYPE  1 ACTION (nTmsOpcA := 1,nTmsItem := oTmsBrw:nAt,oTmsDlg:End()) ENABLE OF oTmsDlg

If	lCancel	
	DEFINE SBUTTON oTmsBtn2 FROM aCoordObj[3,1], aCoordObj[3,2] PIXEL TYPE  2 ACTION (nTmsOpcA := 0,oTmsDlg:End()) ENABLE OF oTmsDlg
EndIf

If Len(aNewButton) > 0
	bActionBtn:= aNewButton[1,2]
	
	DEFINE SBUTTON oNewBtn; 
	FROM aCoordObj[4,1], aCoordObj[4,2] PIXEL; 
	TYPE aNewButton[1,1];
	ACTION Eval(bActionBtn, oTmsBrw:nAt);
	ENABLE OF oTmsDlg
	
EndIf

If ValType(aCabec) == "A"
	If Len(aCabec) > 0
		oNewBtn := SButton():New(aCoordObj[5,1], aCoordObj[5,2], 17, bActionPsq, oTmsDlg, .T., STR0069 ) //'Pesquisar'
	EndIf
EndIf
ACTIVATE MSDIALOG oTmsDlg Centered

Return( Iif( nTmsOpcA == 1, nTmsItem, 0 ) )

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335Sit
Alteração da variavel da  situação do atendente dentro da consulta padrão.

@author Kaique Schiller
@since 04/12/2017
@return Lógico.
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At335Sit(cFil, cSit,aAtend)
Local dDtRef	 := dDataBase

If !Empty(aAtend)
	cSit := At335StAtd(cFil, aAtend[1], dDtRef)
Else
	cSit := ""
Endif

Return .T.

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335Agend
Verifica agenda na ABB.

@author Kaique Schiller
@since 04/12/2017
@return Query.
/*/
//--------------------------------------------------------------------------------------------------------
Function At335Agend(cFilTec, cCodTec, dData)
Local cAliasABB	:= ""
Default cFilTec	:= ""
Default cCodTec	:= ""
Default dData	:= STOD("")

If !Empty(cFilTec) .And. !Empty(cCodTec) .And. !Empty(dData)

	cAliasABB := GetNextAlias()

	BeginSQL Alias cAliasABB
		SELECT ABB_TIPOMV
	    FROM %Table:ABB% ABB
	    	INNER JOIN %table:TDV% TDV ON TDV.TDV_FILIAL = %xFilial:TDV% 
	    		AND TDV.TDV_CODABB = ABB.ABB_CODIGO
	    		AND TDV.TDV_DTREF  = %Exp:dData%
	    		AND TDV.%NotDel%
	    WHERE ABB.ABB_FILIAL = %Exp:cFilTec%
	      AND ABB.ABB_CODTEC = %Exp:cCodTec%
	      AND ABB_ATIVO 	 = '1'
	      AND ABB.%NotDel%
	EndSQL
Endif

Return cAliasABB


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335Agend
@description 	Importação automática de manutenções através de preenchimento de CSV de importação

@author guilherme.pimentel
@since 11/04/2018
@param 		cArq, Caracter, caminho do CSV a ser importado
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function TEC335CSV(cArq)
Local aSaveLines	:= FWSaveRows()
Local cLinha		:= ""
Local lFirst		:= .T.
Local lRet			:= .T.
Local aCampos 		:= {}
Local aDados  		:= {}
Local nX 			:= 0
Local nY 			:= 0

Local oTECA335 		:= Nil
Local oTECA335C		:= Nil

Local oTECA336 		:= Nil
Local oTECA336C		:= Nil
 
Local dDAtual		:= dDatabase
Local cCodEsc		:= ""
 
Default cArq    := "c:\teca335.csv"

Private aErro := {}
 
If !File(cArq)
	MsgStop(STR0052+cArq+STR0053,"TEC335CSV") //"O arquivo "#" não foi encontrado. A importação será cancelada!"
	lRet := .F.
EndIf
 
If lRet
	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()
	 
		IncProc(STR0054) //"Lendo arquivo"
	 
		cLinha := FT_FREADLN()
	 
		If lFirst
			aCampos := Separa(cLinha,";",.T.)
			lFirst := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf
	 
		FT_FSKIP()
	EndDo
	 
	Begin Transaction
		ProcRegua(Len(aDados))
		For nX:=1 to Len(aDados)
	 
			IncProc(STR0055) //"Importando Manutenções"
	 		
	 		//Realiza ajuste para buscar o codigo da TDX
	 		cCodEsc := TEC335TDX(aDados[nX,2],aDados[nX,7],aDados[nX,8],aDados[nX,9])
	 		If !Empty(cCodEsc)
	 			aDados[nX,8] := cCodEsc
	 		EndIf
	 		
			dDataBase := CtoD(aDados[nX,1])
			
			//Carga e instancia do TECA335
			oTECA335 := FWModelActive()
			oTECA335C := oTECA335:GetModel('CAB_ATEND')
					
			//Preenche data, filial e atendente
			lRet := lRet .And. oTECA335C:SetValue("TDV_DTREF",dDataBase)
			lRet := lRet .And. oTECA335C:SetValue('AA1_FILIAL',aDados[nX,2])
			lRet := lRet .And. oTECA335C:SetValue('AA1_CODTEC',aDados[nX,3])
			
			//Funções declaradas no SetFieldAction
			If lRet
				At335AgCar()
			EndIf
			
			If lRet
				//Chama função do TECA336 para preparação dos dados
				TECA336(oTECA335)
				
				//Instancia modelo da Movimentação
				oTECA336 := FWLoadModel("TECA336")
				oTECA336C := oTECA336:GetModel('TW3MASTER')
						
				oTECA336:SetOperation(MODEL_OPERATION_INSERT)
				oTECA336:Activate()
				
				AtPerfilAloc(,oTECA336)
				
				//Preenchimento dinâmicos dos campos
				For nY := 4 to Len(aCampos)
					If !Empty(aDados[nX,nY]) .And. aCampos[nY] <> "SEQ" .And. lRet
						lRet := lRet .And. oTECA336C:SetValue(aCampos[nY],aDados[nX,nY])
					EndIf
				Next nY
			EndIf
			
			//Commit do 336
			If lRet := lRet .And. oTECA336:VldData()
				lRet := oTECA336:CommitData()
			EndIf
			If !lRet
				Ft600ErroMvc(oTECA336) 
			EndIf
			
			//Desativação do modelo
			oTECA336:DeActivate()
			
			oTECA336 := Nil
			
			//Informa arquivos inseridos e aborta 
			If !lRet
				ApMsgInfo(STR0056+Alltrim(str(nX))+STR0057,"TEC335CSV") //"Erro encontrado na linha "#". As anteriores foram não tiveram problemas, entretanto foram restauradas"			
				DisarmTransaction()
				Exit
			EndIf
			
			FwModelActive(oMdlBKP)
			
		Next nX
	End Transaction
	 
	FT_FUSE()
	 
	If lRet
		ApMsgInfo(STR0058,"TEC335CSV") //"Importação das manutenções concluída com sucesso!"
	EndIf
EndIf

//Restaura data
dDatabase := dDAtual

//Recupera o Model original
oModel := oMdlBKP

FWRestRows(aSaveLines)

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TEC335TDX
@description Busca do codigo da escala com o turno e a sequencia

@author luiz.jesus	
@since 11/06/2018
@param 	cCodFilial, Caracter, codigo da filial
@param 	cCodTFF, Caracter, codigo da TFF
@param 	cCodTurno, Caracter, codigo do turno
@param 	cCodSeq, Caracter, codigo da sequencia do turno

@return cCodTDX, Caracter, codigo da escala
/*/
//--------------------------------------------------------------------------------------------------------
Static Function TEC335TDX(cCodFilial,cCodTFF,cCodTurno,cCodSeq)
Local aRet			:= {}
Local cAliasTDX		:= GetNextAlias()
Local cCodTDX		:= ""

BeginSql Alias cAliasTDX
	
	SELECT
		TFF.TFF_FILIAL,
		TFF.TFF_COD,
		TDX.TDX_COD,
		TDX.TDX_TURNO,
		TDX.TDX_SEQTUR					
	FROM %table:TFF% TFF
		INNER JOIN %table:TDW% TDW
			ON TDW.TDW_FILIAL = %xFilial:TDW% AND   
			TDW.TDW_STATUS = '1' AND
			TDW.%NotDel% 
		INNER JOIN %table:TDX% TDX
			ON TDX.TDX_FILIAL = %xFilial:TDX% AND   
			TDX.TDX_CODTDW = TDW.TDW_COD AND
			TDX.TDX_TURNO = %Exp:cCodTurno% AND  
			TDX.TDX_SEQTUR = %Exp:cCodSeq% AND
			TDX.%NotDel% 		
	WHERE
		TFF.TFF_FILIAL = %Exp:cCodFilial% AND
		TFF.TFF_COD = %Exp:cCodTFF% AND  
		TFF.%NotDel% 
				
EndSql
	
If !(cAliasTDX)->(Eof())					 	
	cCodTDX = (cAliasTDX)->TDX_COD
EndIf
	
(cAliasTDX)->(DbCloseArea())

Return cCodTDX

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} at335VldDm
@description Valida se o funcionario não esta demitido

@author Matheus Lando Raimundo	
@since 27/06/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function at335VldDm()
Local lRet := .T.
Local oModel    := FwModelActive()
Local oMdlAA1	:= oModel:GetModel("CAB_ATEND")
Local dDtRef    := oMdlAA1:GetValue("TDV_DTREF")
Local cFil	    := oMdlAA1:GetValue("AA1_FILIAL")
Local cCodAtend := oMdlAA1:GetValue("AA1_CODTEC")
Local cFunFil	:= ""
Local cFunciona	:= ""
Local aArea 	:= GetArea()

DbSelectArea("AA1")
AA1->(DbSetOrder(1))
If AA1->(DbSeek(cFil+cCodAtend))
	cFunciona	:= AA1->AA1_CDFUNC		
	cFunFil		:= AA1->AA1_FUNFIL
	If lTecXRh		
		DbSelectArea("SRA")
		SRA->(DbSetOrder(1))
		If SRA->(DbSeek(cFunFil+cFunciona))
			If At570ChkDm(cFil,cFunciona,dDtRef,dDtRef) 																    															    			                                                    				
				Help( ,, 'AT335FUNDEM',, STR0048, 1, 0 ) // "Código do atendente não encontrado nesta filial"
				lRet := .F.
			EndIf	
		Endif
	EndIf
EndIf	
RestArea(aArea)
Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At335Manut
@description Visualização da manutenção das agendas.

@author Kaique Schiller
@since 21/01/2019
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At335Manut(oView)
Local oModel	:= oView:GetModel()
Local oMdlABB	:= oModel:GetModel("ITE_ABB")
Local cAgenda	:= oMdlABB:GetValue("ABB_CODIGO")

If !Empty(cAgenda)
	DbSelectArea('ABR')
	ABR->(DbSetOrder(1))
	If ABR->(DbSeek(xFilial('ABR')+cAgenda))
		TECA550(cAgenda,"ABR")
	Else
		Help( , , "At335Manut", , STR0063, 1, 0,,,,,,{STR0064}) // "Não existe manutenção para essa agenda." # "Posicione na agenda que existe manutenção."
	Endif
Else
	Help( , , "At335Manut", , STR0065, 1, 0,,,,,,{STR0066}) //"Não existe agenda para esse atendente." # "Posicione no atendente que existe agenda."
Endif

Return .T.
