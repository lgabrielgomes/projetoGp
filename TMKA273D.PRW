#INCLUDE "PROTHEUS.CH" 
#INCLUDE "TMKA273D.CH" 
#INCLUDE "TMKDEF.CH"  

#DEFINE TEF_CLISITEF				"6"		//Utiliza a DLL CLISITEF
#DEFINE _FORMATEF					"CC" 	//Formas de pagamento que utilizam operação TEF para validação

#DEFINE YMF                          2      //Indica que a analise de credito esta sendo feita pelo YMF


STATIC cOpFat 		:= Alltrim(SuperGetMv("MV_OPFAT"))	// Indica como sera o processo de FATURAMENTO 
STATIC aCrdCliente	:= {"",""} 				   			// Informacoes do cliente para private label [1]-CNPJ/CPF [2]-Num. Cartao PRIVATE LABEL
STATIC aContrTmp	:= {}								// Numeros de contratos que foram utilizados e nao foram gravados no atendimento
STATIC cContrato	:= ""								// Numero do contrato da analise de credito realizada
STATIC aInfMA7  	:= {}	                    		// Array com dados do MA7 para controle de "backup" caso o usuario nao confirme a operacao
STATIC aInfMAH  	:= {}                       		// Array com dados do MAH para controle de "backup" caso o usuario nao confirme a operacao
STATIC aInfMAL  	:= {}                       		// Array com dados do MAL para controle de "backup" caso o usuario nao confirme a operacao

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³																						 ³
³	ACOLS DA ROTINA DE TELEVENDAS														 ³
³																						 ³
³	01 - Produto																		 ³
³	02 - Descricao																		 ³
³	03 - Situacao do Produto															 ³
³	04 - Quantidade																		 ³	
³	05 - Pre‡o Unitario																     ³	
³	06 - Valor do Item (Quantidade * Pre‡o Unitario)									 ³
³	07 - Local Padrao																	 ³
³	08 - Unidade																		 ³
³	09 - Desconto (%)																 	 ³
³	10 - Valor do Desconto																 ³
³	11 - Tipo E/S																		 ³
³	12 - Codigo Fiscal																	 ³
³	13 - Acrescimo (%)																	 ³	
³	14 - Valor do Acrescimo																 ³
³	15 - Preco de Tabela																 ³
³	16 - Data de entrega																 ³
³	17 - Lote																			 ³
³	18 - Sub-Lote																		 ³
³	19 - Data de validade do Lote														 ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³Tk273GrvTel³ Autor ³ Vendas Clientes      ³ Data ³28/10/03                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Executa a gravacao do atendimento-TELEVENDAS com Integridade                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Tk273GrvTel( ExpN1,	ExpO2, 	ExpC3, 	Exp4C,   			                         ³±±
±±³          ³              ExpC5,	ExpC6,	ExpC7,	ExpC8,                                       ³±±
±±³          ³              ExpC9,	ExpC10, ExpC11,	ExpC12,				                         ³±±
±±³          ³              ExpC13,	ExpC14,	ExpC15, ExpC16,				                         ³±±
±±³          ³              ExpN17,	ExpN18,	ExpN19,	ExpN20,			                         	 ³±±
±±³          ³              ExpA21,	ExpN22,	ExpN23,	ExpN24,                                      ³±±
±±³          ³              ExpN25,	ExpL26,	ExpA27,	ExpL28,                                      ³±±
±±³          ³              ExpA29,	ExpN30,	ExpC31,	ExpL32)                                      ³±±
±±³          ³                                                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1   - opções escolhida pelo usuário (Alteração/ Visualização)   				 ³±±		
±±³          ³ExpO2   - objeto palheta de atendimento (Telemarketing, Televendas, Telecobrança)  ³±±	
±±³          ³ExpC3   - condição de pagto.    													 ³±±		
±±³          ³ExpC4  - desconto concedido	   											 	     ³±±					 	
±±³          ³ExpC5  - codigo da transportadora	   											     ³±±
±±³          ³ExpC6  - 	codigo da transportadora  												 ³±±
±±³          ³ExpC7  - endereço de cobrança			    										 ³±±
±±³          ³ExpC8  - endereço para entrega			    									 ³±±			
±±³          ³ExpC9  - cidade para cobrança    													 ³±±
±±³          ³ExpC10  - CEP para cobrança		    											 ³±±
±±³          ³ExpC11  - estado para cobrança			    									 ³±±
±±³          ³ExpC12  - bairro para entrega						    							 ³±±
±±³          ³ExpC13  - bairro para cobrança	                                                 ³±±
±±³          ³ExpC14  - cidade para entrega    													 ³±±
±±³          ³ExpC15  - CEP para entrega			    										 ³±±
±±³          ³ExpC16  - estado para entrega				     									 ³±±		
±±³          ³ExpN17  - Valor Liquido    														 ³±±
±±³          ³ExpN18  - Taxa de Juros    														 ³±±
±±³          ³ExpN19  - Taxa de Desconto concedido		    									 ³±±
±±³          ³ExpN20  - Valor do Juros						    								 ³±±
±±³          ³ExpA21  - Array de parcelas	    												 ³±±
±±³          ³ExpN22  - Valor de entrada	    												 ³±±
±±³          ³ExpN23  - Valor Financiado	     												 ³±±
±±³          ³ExpN24  - Número de parcelas			    										 ³±±				
±±³          ³ExpN25  -     																	 ³±±
±±³          ³ExpL26  - Controle para tela para Visual.    										 ³±±
±±³          ³ExpA27  - aCols dos ítens do pedido	    										 ³±±
±±³          ³ExpL28  - indica se está usando agenda	    									 ³±±					
±±³          ³ExpA29  - array com campos do SUA no dic.	    									 ³±±
±±³          ³ExpN30  - Valor Não Faturado    													 ³±±
±±³          ³ExpC31  - codigo do cliente anterior    											 ³±±	
±±³          ³ExpL32  - indica o uso do SigaCRD    											     ³±±
±±³          ³ExpL33  - controle de regra de negocios										     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ TeleVendas                                                 						 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
                       
Function Tk273GrvTel(	nOpc		,oFolderTlv	,cCodPagto		,cDescPagto		,;
					 	cCodTransp	,cTransp	,cCob			,cEnt			,;
						cCidadeC	,cCepC		,cUfC			,cBairroE		,;
						cBairroC	,cCidadeE	,cCepE			,cUfE			,;
						nLiquido	,nTxJuros	,nTxDescon		,nVlJur			,;
						aParcelas	,nEntrada	,nFinanciado	,nNumParcelas	,;
						nValorCC	,lHabilita	,aColsTlv		,l380			,;
						aSx3Sua		,nValNFat	,cCliAnt		,lSigaCRD       ,;
						lTLVReg)
							
Local lRet		:= .F.                                  						// Retorno da funcao

//Variveis para gravacao do ATENDIMENTO
Local nPProd    := aPosicoes[1][2]												// Produto
Local nPDescPro := aPosicoes[2][2]												// Descricao do Produto
Local nPQtd     := aPosicoes[4][2]                      						// Quantidade
Local nPVrUnit  := aPosicoes[5][2]                      						// Valor unitario
Local nPvlrItem	:= aPosicoes[6][2]                      						// Valor do item
Local nPLocal   := aPosicoes[7][2]                      						// Local
Local nPUm	    := aPosicoes[8][2]                      						// Unidade
Local nPDesc	:= aPosicoes[9][2]                      						// Desconto %
Local nPValdesc := aPosicoes[10][2]                     						// Valor do Desconto
Local nPTes	    := aPosicoes[11][2]                     						// TES
Local nPCf		:= aPosicoes[12][2]                     						// CFO
Local nPPrcTab	:= aPosicoes[15][2]                     						// Preco de tabela
Local nPDtEntre := aPosicoes[16][2]                     						// Data entrega
Local nLote		:= aPosicoes[17][2]												// Lote
Local nSubLote	:= aPosicoes[18][2]												// Sub-Lote
Local nDtValid	:= aPosicoes[19][2]												// Validade do lote
Local lTKGRPEDT	:= FindFunction("T_TKGRPED") 									// P.E. antes da grava‡ao do atendimento com espera de retorno - Para uso exclusivo de Templates
Local lTKGRPED	:= FindFunction("U_TKGRPED") 									// P.E. antes da grava‡ao do atendimento com espera de retorno 
Local lTMKVOK 	:= FindFunction("U_TMKVOK") 									// P.E. depois da grava‡ao do atendimento
Local lTMKVPED 	:= FindFunction("U_TMKVPED") 									// P.E. para substituir a gravacao do SC5 e SC6
Local lTMKVFIMT	:= FindFunction("T_TMKVFIM") 									// P.E. no fim da grava‡ao do pedido do SC5/SC6 - Para uso exclusivo de Templates
Local lTMKVFIM 	:= FindFunction("U_TMKVFIM") 									// P.E. no fim da grava‡ao do pedido do SC5/SC6
Local lTMKVPV 	:= FindFunction("U_TMKVPV") 									// P.E. no fim da grava‡ao do pedido do SC5/SC6 e antes da geracao da nota fiscal(SF2/SD2)
Local lTMKR03T	:= FindFunction("T_TMKR03") 									// P.E. do Relatorio de PEDIDO - Para uso exclusivo de Templates
Local lTMKR03	:= FindFunction("U_TMKR03") 									// P.E. do Relatorio de PEDIDO
Local lTMKR3AT  := FindFunction("T_TMKR3A") 									// P.E  do Relatorio de ORCAMENTO - Para uso exclusivo de Templates
Local lTMKR3A	:= FindFunction("U_TMKR3A") 									// P.E  do Relatorio de ORCAMENTO
Local lTMKVA1 	:= FindFunction("U_TMKVA1") 									// P.E. para a grava‡ao de PROSPECT para CLIENTE
Local lTMKVSL4 	:= FindFunction("U_TMKVSL4") 									// P.E. no fim da gravacao do SL4
Local lTKTipCli	:= FindFunction("U_TKTIPCLI")				    				//P.E. que permita customizar gravação do tipo decliente no pedido de vendas.

Local cNumSL1	:= CRIAVAR("UA_NUMSL1",.F.)             						// Codigo do orcamento no SIGALOJA -SL1	
Local cTmkLoj	:= SuperGetMv("MV_TMKLOJ")     									// Inclui os ORCAMENTOS NO SIGALOJA gerados pelo Televendas
Local cTmkaLoj	:= SuperGetMv("MV_TMKALOJ")        								// Altera os ORCAMENTOS NO SIGALOJA gerados pelo Televendas
Local lCheque   := (SuperGetMV("MV_TEFGRT") == "S")							// Indica se havera pergunta para garantia do CHEQUE.
Local nValidade := TkPosto(M->UA_OPERADO,"U0_VALIDAD")  						// Validade do orcamento
Local lMV_TMKFIS:= IIf(lTk271Auto, .T., GetNewPar("MV_TMKFIS",.T.))									// (Não divulgar) Parametro que indica que a atualização da MATXFIS é feita de maneira on-line, no off-line a MATXFIS só é atualizada quando se entra na condição de pagamento.
Local nNumPar := SuperGetMv("MV_NUMPARC")									//Numero de parcelas utilizada no sistema

Local cNovoItem 	:= "00"														// Valor do NOVO ITEM que sera incluido no SUB/SC6
Local nCont			:= 0														// Contador
Local nTotal 		:= 0                                    					// Valor total das parcelas 
Local cCampo    	:= ""                                   					// Campo
Local bCampo    	:= ""                                   					// Macro do campo
Local cNumAux		:= M->UA_NUM                            					// Numero auxiliar
Local cMay      	:= ""														// Variavel auxiliar
Local nCartao   	:= 0                                    					// Total das parcelas com CARTAO
Local cHisTlv   	:= ""                                   					// Historico do TLV - SA1
Local nI			:= 0														// Contador de Colunas (AHEADER)
Local nX 			:= 0														// Contador de Linhas (ACOLS)
Local cI			:= "00"														// Soma ITEM - UB_ITEM e C6_ITEM	
Local lNovo			:= .F.														// Flag para inclusao ou alteracao na gravacao

//Controle de Administradora Financeira para TEF
Local cAdm      	:= ""                                                                      
Local aCupomTEF 	:= {}
Local lTefOk    	:= .F.                            							// Tef OK
Local lGrava 		:= .T.														// Flag para a continuar a gravacao  

// Variaveis para Gravacao do SEF
Local aReceb    	:= {}      													// Array do aParcelas para TEF
Local nCheques      := 0														// Contador de Cheques (Total)
Local nContSEF 		:= 0 														// Contador de Cheques 
Local j             := 0														// Contador de Parcelas
Local cBanco		:= ""                               						// Banco do Cheque
Local cNumCheque	:= ""														// Numero do Cheque
Local cAgencia 		:= ""														// Agencia do Cheque
Local cConta		:= ""														// Contao do Cheque
Local cRG			:= ""														// RG do emissor do cheque
Local cTelefone		:= ""														// Telefone do emissor do cheque	
Local nValorCheque 	:= ""														// Valor do cheque
Local dDataVencto  	:= ""														// Vencimento do cheque

// Localizacoes
Local cOpRem   		:= SuperGetMV("MV_OPREM")									// Geracao do remito/remision/guia de despacho - Localizacoes
Local lOpRem   		:= .F.          											// Flag para gravacao do remito	
Local cTextMsg 		:= ""

// Variveis para gravacao do PEDIDO
Local lTipo9		:= .F.														// Indica se a venda foi tipo 9
Local cNumSc5		:= CRIAVAR("C5_NUM",.F.)									// Numero do Pedido	- Inclusao
Local nPos 			:= 0														// Posicao dentro do array
Local aPedido		:= {}														// Array com o numero do pedido para emissao da NF - MV_OPFAT = S
Local lOpFat    	:= .F.   													// Flag para gravacao da NF - MV_OPFAT = "S"
Local nOpAnt 		:= 0														// Valor do status da OPERACAO anterior em caso de ALTERACAO  
Local nValComi		:= 0 														// Valor da Comissao para o SC5

Local cTipoCli  	:= ""														// Tipo do Cliente / Prospect
Local cPrcFiscal	:= TkPosto(M->UA_OPERADO,"U0_PRECOF")						// Preco Fiscal Bruto = S ou N - Posto de Venda
Local lAvalCre  	:= IF(TkPosto(M->UA_OPERADO,"U0_AVALCRE") == "1",.T.,.F.)	// Avalia Credito 1 - Sim / 2 - Nao
Local lBloqCre		:= lAvalCre													// Indica como vai ficar o bloqueio de credito .T.- Liberado .F.-Bloqueado		
Local lAvalEst  	:= IF(TkPosto(M->UA_OPERADO,"U0_AVALEST") == "1",.T.,.F.)	// Avalia Estoque 1 - Sim / 2 - Nao
Local cParcela  	:= "123456789ABCDEFGHIJKLMNOPQ"								// Sequencia da Parcela - para Tipo 9
Local nTamDec		:= TamSx3("C6_PRCVEN")[2]									// Pega o tamanho das casas decimais no SC6

Local lBlqRegra		:= .F.														// Se houve bloqueio por regra (Ou seja, não gerou SC9)
Local lBlqVerba		:= .F.														// Se houve bloqueio por verba (Ou seja, não gerou SC9)
Local lLiber 		:= .F.														// Compatibilizacao com o SIGAFAT
Local lTransf		:= .F.                                                     	// Compatibilizacao com o SIGAFAT	
Local lLiberOk 		:= .T.														// Compatibilizacao com o SIGAFAT
Local lResidOk 		:= .T.														// Compatibilizacao com o SIGAFAT		
Local lFaturOk 		:= .F.														// Compatibilizacao com o SIGAFAT	
Local lGravaDoc     := .F.                                                      // Controla se deve inicializar os arquivos do SIGACRD
Local cEstacao		:= TkPosto(M->UA_OPERADO,"U0_ESTACAO")						// Codigo da estacao do posto de venda do Operador
Local cForma		:= ""	                                                    // Pega forma de pagamento
Local nPOpc			:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_OPC"})        	// Verifica se o campo esta no SX3 
Local nPItem		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})        	// Pega a posição do campo ITEM no aHeader 
Local npNumPCom		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_NUMPCOM"})        	// Verifica se o campo esta no SX3 
Local npItemPC		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEMPC"})	
Local npPICMRET		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_PICMRET"})
Local npCodFCI		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_FCICOD"})	
Local npVlrFCI		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_VLIMPOR"})	
//Variaveis para integracao com SIGACRD
Local lForcada		:= .F.														// Indica que foi feita uma analise de credito off-line (forcada)
Local lConfCRD		:= .F.														// Indica se a Transacao1 de analise retornou Ok para executar a Transacao2
Local cMV_CRDAVAL	:= SuperGetMV("MV_CRDAVAL",,"13|22|43")		  				// Parametro que define os modulos e processos que tem analise de credito
Local cMV_FormCRD   := SuperGetMV("MV_FORMCRD",,"CH/FI")                       	// Formas de pagamento para as quais deve avaliar credito - SIGACRD
Local aRetCrd		:= {}														// Retorno da funcao que avalia o credito
Local nTotalFat		:= 0														// Valor total a faturar que sera considerado para efetuar a analise de credito

Local lApagaSU4		:= .F.														// Flag para controlar a exclusao do SU6 e do SU4 - Nas listas de contato pendentes.

Local nTamUA_OBS 	:= TamSx3("UA_OBS")[1]										// Tamanho do campo UA_OBS
Local nTamUS_HISTMK := TamSx3("US_HISTMK")[1]									// Tamanho do campo US_HISTMK
Local nTamA1_HISTMK	:= TamSx3("A1_HISTMK")[1]									// Tamanho do campo A1_HISTMK
Local aTravaSB2 	:= {}															// Array com os recnos dos registros que foram travados pelo Simplelock()
Local lFirst		:= .T.													
Local lTCPG			:= SuperGetMV("MV_TMKTCPG",.F.,.F.)	// Parametro do SX6 que controla ou não a abertura da tela de condição de pagamento ao confirmar o atendimento.													

//Variavel private que sera necessaria dentro da transacao TEF (LOJXTEF)
Private nDecimais	:= MsDecimais(SL4->L4_MOEDA)

Default lTLVReg  := .F.

// Bloqueio de regr de negócio quando parâmetro MV_TMKTCPG estiver habilitado, 
// pois quando esta desabilitado será controlado pela lTLVReg 
If lTCPG
	If !Type("lCondBlq") == "U" 
		lTLVReg := lCondBlq
	EndIf	
EndIf

//Carrega perguntas do MATA440 e MATA410 - Compatibilizacao das variaveis lLiber e lTransf
Pergunte("MTA440",.F.)
lLiber := MV_PAR02 == 1
lTransf:= MV_PAR01 == 1     

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Se nao estiver utilizando a rotina de entrada automatica³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If  !( Type("lTk271Auto") <> "U" .AND. lTk271Auto )
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Força a execução da validação do campo em foco.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Tk273ExecCampo({||.T.})
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Força a atualização da parte fiscal quando o parâmetro³
//³MV_TMKFIS está para .F. (Televendas off-line).        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !lMV_TMKFIS
	Tk273AtuNFs()	

	aValores[MERCADORIA]	:= MaFisRet(, "NF_VALMERC")
	aValores[SUFRAMA]		:= MaFisRet(, "NF_DESCZF")
	aValores[TOTAL]			:= MaFisRet(, "NF_TOTAL")
	aValores[BASEDUP]		:= MaFisRet(, "NF_BASEDUP")
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Executa todas as validacoes necessarias antes de executar a gravacao                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

// Se for uma alteracao do atendimento 		
If (nOpc == 4)
	DbSelectArea("SUA")
	DbSetOrder(1)
	If DbSeek(xFilial("SUA") + M->UA_NUM)
	
		//Verifica se o Operador tem acesso (Senhas) para alterar o pedido
		If (VAL(SUA->UA_OPER) == FATURAMENTO)
			If !ChkPsw(20)
				Return(lRet)
			Endif
		Endif
	
		If SUA->UA_STATUS == "CAN"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se nao estiver usando a entrada automatica³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto
				Help(" ",1,"PED.CAN")	   // Se o atendimento foi CANCELADO
			Endif
			Return(lRet)
		Endif

		cNumSL1 := SUA->UA_NUMSL1
		cNumSc5 := SUA->UA_NUMSC5

		// Pega o conteudo da Operacao anterior
		nOpAnt := IF(!Empty(SUA->UA_OPER),VAL(SUA->UA_OPER),0)

	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se nao estiver usando a entrada automatica³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !lTk271Auto
			// Nao encontrou o atendimento nao grava a alteracao
			Help(" ",1,"TK270NSEEK")
		Endif	
		Return(lRet)
	Endif	

Endif
                                          
//Verifica se o parametro MV_TMKINCP esta ativo
If !TK273ValPed(@nOpc,l380)
    Return(lRet)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de Entrada para uso exclusivo de Templates³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lTkGrPEdT
	If !T_TKGRPED(	nLiquido		,aParcelas		,M->UA_OPER	,M->UA_NUM,;
					M->UA_CODLIG	,cCodPagto		,@cOpFat	,cCodTransp)
		Return(lRet)
	Else
		If (ValType(cOpFat) <> "C") .OR. !(cOpFat $ "SNP") 
			cOpFat := Alltrim(SuperGetMv("MV_OPFAT"))
		Endif	
	Endif 
Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de Entrada³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lTkGrPEd
	If !U_TKGRPED(	nLiquido		,aParcelas		,M->UA_OPER	,M->UA_NUM,;
					M->UA_CODLIG	,cCodPagto		,@cOpFat	,cCodTransp)
		Return(lRet)
	Else
		If (ValType(cOpFat) <> "C") .OR. !(cOpFat $ "SNP") 
			cOpFat := Alltrim(SuperGetMv("MV_OPFAT"))
		Endif	
	Endif 
Endif
         
// Valida se existe contato selecionado para geracao de Lista Pendente
If !Empty(M->UA_PROXLIG) .AND. !Empty(M->UA_CODCONT)
	DbSelectArea("SU5")
	DbSetOrder(1)
	If DbSeek(xFilial("SU5") + M->UA_CODCONT)
		If 	Empty(SU5->U5_FONE) 	.AND.;
			Empty(SU5->U5_CELULAR) 	.AND.;
			Empty(SU5->U5_FAX) 		.AND.;
			Empty(SU5->U5_FCOM1) 	.AND.;
			Empty(SU5->U5_FCOM2)
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se nao estiver usando a entrada automatica³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto
				Help(" ",1,"TMKSEMTEL")
			Endif
			Return(lRet)
		Endif
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se nao estiver usando a entrada automatica³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !lTk271Auto
			Help(" ",1,"SEM CONTAT")
		Endif
		Return(lRet)
	Endif
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Em caso de pendencia avalia se o contato foi informado ³
	//³para gravacao do SU4/SU6                               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !Empty(M->UA_PROXLIG) .AND. Empty(M->UA_CODCONT)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se nao estiver usando a entrada automatica³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !lTk271Auto
			Aviso(STR0013,STR0014,{"OK"}) //"Pendência" ### "Por favor, informe o contato para geração da pendencia." 
		Endif
		Return(lRet)
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Se o usuario estiver fazendo um atendimento nao valida todos os campos ele podera gravar o minimo de informacoes ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If VAL(M->UA_OPER) <> ATENDIMENTO .AND. !Empty(M->UA_OPER)

	 
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida se existem produtos lancados³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aValores[TOTAL] <= 0      

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se o flag para nao gerar titulo, poder lancar quantidade e valor total = 0,00 estiver TRUE: NAO FECHA O ATENDIMENTO³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lTesTit 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se nao estiver usando a entrada automatica³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto
				Help(" ",1,"SEMDADOS")
			Endif	
			Return(lRet)
		Endif	

	Endif	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida a troca do codigo do cliente.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ( cCliAnt <> M->UA_CLIENTE + M->UA_LOJA ) .AND. ( !Empty(cCliAnt) )
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se nao estiver usando a entrada automatica³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !lTk271Auto
			Help(" ",1,"FALTA_PGTO") 
		Endif	
		Return(lRet)
	Endif	

	//Se o atendimento for uma alteracao e o parametro MV_TMKALOJ for "S"
	If nOpc == 4
		If cTmkaLoj == "S"
			// Se encontrou o orcamento e ele ja foi recebido nao procede a alteracao
			DbSelectArea("SL1")
			DbSetOrder(1)
			If DbSeek(xFilial("SL1") + SUA->UA_NUMSL1)
				If !Empty(SL1->L1_DOC)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se nao estiver usando a entrada automatica³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If !lTk271Auto
						Help(" ",1,"VENDA_LOJA")
					Endif
					Return(lRet)
				Else
					TkLibLoja("D")
				EndIf
			Endif
		Endif
	Endif
	
	//Se for pedido  tem que haver pelo menos 1 parcela
	If (Val(M->UA_OPER) == FATURAMENTO) .OR. (Val(M->UA_OPER) == ORCAMENTO .AND. (!Empty(aParcelas) .OR. (!Empty(cCodPagto) .AND. Empty(aParcelas))))
		
		If ((Len(aParcelas) == 0) .OR. (aParcelas[1][2] == 0)) .OR. Empty(cCodPagto)

			// Se uma das TES utilizadas gera TITULO a condicao de pagamento e obrigatoria
			If lTesTit
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se nao estiver usando a entrada automatica³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If !lTk271Auto
					Help(" ",1,"FALTA_PGTO")
				Endif	
				Return(lRet)
			Endif	

		Else
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Verifica se o valor das parcelas ‚ o mesmo do VALOR LIQUIDO - rodape     ³
			//³Vale a seguinte Regra:                                                   ³
			//³Se for OR€AMENTO e ja foi especificado uma forma de pagamento            ³
			//³Se for FATURAMENTO sempre valida o valor das parcelas + o Frete Informado³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Len(aParcelas) > 0 .AND. !Empty(aParcelas[1][1])

				For nI := 1 To Len(aParcelas)
					nTotal += Round(NoRound(aParcelas[nI][2],4),2)
					
					If ("$" $ aParcelas[nI][3]) .AND. (nI > 1) .AND. (aParcelas[nI][1] > dDataBase)
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se nao estiver usando a entrada automatica³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !lTk271Auto
							Help( " ", 1, "NOPRAZO" )
						Endif	
						Return(lRet)
					Endif
					
					If nI > 1
						If aParcelas[nI][1] < aParcelas[nI-1][1]
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Se nao estiver usando a entrada automatica³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If !lTk271Auto
								Help(" ",1,"TK273WRDAT")
							Endif	
							Return(lRet)
						Endif
					Endif
				Next nI
				
				If NoRound(nTotal,2) <> NoRound(aValores[BASEDUP],2)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se nao estiver usando a entrada automatica³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If !lTk271Auto
						Help( " ", 1, "TK010VALOK" )
					Endif	
					Return(lRet)
				Endif
			Endif
		Endif
	Endif

	// Se for uma alteracao do atendimento 		
	If (nOpc == 4)		
		Do Case
		
			//Se for Alteracao e o registro ja estiver sido gerado como Faturamento checa a integridade do SC5 e do SC6
			Case VAL(SUA->UA_OPER) == FATURAMENTO 
			
				//Posiciona no pedido correto - O pedido so pode ser cancelado pelo SIGATMK 
				DbSelectArea("SC5")
				DbSetOrder(1)
				If DbSeek(xFilial("SC5")+cNumSc5)


					// Verifica se teve algum item com NF emitida parcial
					DbSelectArea("SC6")
					DbSetOrder(1)
					If DbSeek(xFilial("SC6")+cNumSc5)
						While (!Eof()) .AND. (SC6->C6_FILIAL == xFilial("SC6")) .AND. (SC6->C6_NUM == cNumSc5)					
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Impede a alteracao de Pedido com Servico de WMS jah executado 		  ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ								
							If	IntDL(SC6->C6_PRODUTO) 									
								SC9->(dbSetOrder(2)) //-- C9_FILIAL+C9_CLIENTE+C9_LOJA+C9_PEDIDO+C9_ITEM
								If	SC9->(DbSeek(xFilial("SC9")+SC5->C5_CLIENTE+SC5->C5_LOJACLI+SC5->C5_NUM+SC6->C6_ITEM, .F.))
									If	Empty(SC9->C9_NFISCAL) .And. SC9->C9_BLWMS == '05' .And. !(SC6->C6_QTDLIB==SC9->C9_QTDLIB) //-- Liberado para WMS (Servico jah executado)
										Aviso('SigaWMS',STR0073+AllTrim(SC6->C6_ITEM)+STR0074+" ( "+AllTrim(Transform(SC9->C9_QTDLIB, PesqPict('SC9', 'C9_QTDLIB')))+" "+STR0075, {'Ok'}) //'O Item '###" nao pode ser alterado porque possui servicos de WMS pendentes. Estorne estes servicos para proceder com a alteracao."###"na 1a UM ) nao pode ser alterada."											
										Return(lRet)
									EndIf
								EndIf								
							EndIf 						
							DbSkip()
						End
						
					Endif
					
				Endif
						
		
			// Validacoes da ALTERACAO de ORCAMENTO
			Case VAL(SUA->UA_OPER) == ORCAMENTO		
				
				// Se encontrou o orcamento e ele ja foi recebido nao procede a alteracao
				If (cTmkaLoj == "S")
					DbSelectArea("SL1")
					DbSetOrder(1)
					If DbSeek(xFilial("SL1") + SUA->UA_NUMSL1) .AND. !Empty(SL1->L1_DOC)
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se nao estiver usando a entrada automatica³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !lTk271Auto
							Help(" ",1,"VENDA_LOJA")
						Endif	
						Return(lRet)
					Endif
				Endif
			
				Do Case
					Case SUA->UA_STATUS == "NF."
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se nao estiver usando a entrada automatica³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !lTk271Auto
							Help(" ",1,"NF.EMITIDA") // Se a NF foi emitida nao tem gravacao
						Endif	
						Return(lRet)
							
					Case SUA->UA_STATUS == "RM."
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se nao estiver usando a entrada automatica³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !lTk271Auto
				  			Help(" ",1,"RM.ENVIADA") // Se a NF foi emitida nao tem gravacao
						Endif	
						Return(lRet)
		
					Case SUA->UA_STATUS == "CAN"
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se nao estiver usando a entrada automatica³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !lTk271Auto
							Help(" ",1,"PED.CAN")	 // Se o atendimento foi CANCELADO
						Endif	
						Return(lRet)
		    	Endcase
		EndCase		
				
    Endif

	If Val(M->UA_OPER) == ORCAMENTO

		If lProspect .And. cTmkLoj == "S"
			Aviso(STR0015,STR0080,{"OK"})	//"Atenção"##"Foi verificado que a integração com o SIGALOJA (MV_TMKLOJ) está habilitada, portanto não poderá ser utilizado nenhum prospect na geração do orçamento."			
			M->UA_CLIENTE := Space(Len(M->UA_CLIENTE))
			M->UA_LOJA	  := Space(Len(M->UA_LOJA))
			M->UA_DESCCLI := Space(Len(M->UA_DESCCLI))
			lProspect := .F. 								
			Return(lRet)
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Executa a analise de credito para os ORCAMENTOS apenas se o parametro permitir.³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 		If "21" $ cMV_CRDAVAL
			If lSigaCRD .AND. lTesTit .AND. !lProspect
				nTotalFat:= NoRound(aValores[BASEDUP],2)

				Conout("1.TMKA273D - Tk273GrvTel - " +;
					 STR0029 + If( Empty( M->UA_NUM), "", M->UA_NUM ) +;       //	" Orcamento: "
						STR0030 )      //" Chama a funcao Tk273AvalCred "
				
				aRetCrd:= Tk273AvalCred("1",.T.,aParcelas,aValores[BASEDUP],nVlJur,cMV_CRDAVAL,.F.)
	
				If !Tk273RetCred(@lForcada,aRetCrd,nTotalFat)                                   
					Conout("2.TMKA273D - Tk273GrvTel - " +;
						STR0029 + If( Empty( M->UA_NUM), "", M->UA_NUM ) +;	//" Orcamento: "
						STR0031) 	//" Credito nao aprovado "
					Return(lRet)
				Else                                          
					Conout("3.TMKA273D - Tk273GrvTel - "  +;
					STR0029 + If( Empty( M->UA_NUM), "", M->UA_NUM ) +;     //" Orcamento: " 
					STR0032 )        //" Credito aprovado"
				Endif
			Else
				Conout("4.TMKA273D - Tk273GrvTel - " +;
						STR0029	+ If( Empty( M->UA_NUM), "", M->UA_NUM ) +;         //" Orcamento: "
						" lSigaCRD = " 	+ If( Empty(lSigaCRD), "", If(lSigaCRD, ".T.",".F.")) +; 
						" lTesTit = "  	+ If( Empty(lTesTit), "", If(lTesTit, ".T.",".F.")) +;
						" lProspect = " + If( Empty(lProspect), "", If(lProspect, ".T.",".F.")) )
						
			Endif	           
	    else
    		Conout(STR0033 +;       //"5.TMKA273D - Tk273GrvTel - nao avaliou "
    				STR0029 + If( Empty( M->UA_NUM), "", M->UA_NUM )  )    //"Orcamento: "
	    Endif

	//Se a operacao Atual for FATURAMENTO o sistema vai pedir a confirmacao para gerar o pedido
    ElseIf Val(M->UA_OPER) == FATURAMENTO

		//Somente quando a operacao for Inclusao o sistema vai pedir a confirmacao de gerar o pedido
		If nOpc == 3
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se nao estiver usando a entrada automatica³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto
				If ! TmkOk(STR0001)  //"Confirma o Pedido ?"
					Return(lRet)
				Endif
			Endif
		Elseif nOpc == 4 .AND. (VAL(SUA->UA_OPER) == ORCAMENTO)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se nao estiver usando a entrada automatica³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto                     
				If lProspect    
					DbSelectArea("SUS")
					DbSetOrder(1)
					If DbSeek(xFilial("SUS")+SUA->UA_CLIENTE+SUA->UA_LOJA)
					    If !Empty(SUS->US_CODCLI) .AND. !Empty(SUS->US_LOJACLI)      
					   		Aviso(STR0015,STR0079,{"OK"}) //"Atencao","Esse prospect ja foi convertido em Cliente, portanto o atendimento dever ser feito pelo código de CLIENTE"
		                 	Return(.F.)      
		        		EndIf   
		        	EndIf
           		EndIf 
	             			
				If ! TmkOk(STR0001)  //"Confirma o Pedido ?"
					Return(lRet)
				Else 
				    Tk273DelLoj(nOpc,cNumSL1) 
				Endif                              		
			Endif
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Executa a analise de credito do SIGACRD ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 		If "22" $ cMV_CRDAVAL

			If lSigaCRD .AND. lTesTit .AND. !lProspect
	            
				nTotalFat	:= NoRound(aValores[BASEDUP],2)
								
				Conout(STR0034 + M->UA_NUM )	//"6.TMKA273D - Tk273GrvTel - Chama a funcao TK273AvalCred Orcamento: " 
				aRetCrd		:= Tk273AvalCred("1",.T.,aParcelas,aValores[BASEDUP],nVlJur,cMV_CRDAVAL,.F.)
	
				If !Tk273RetCred(@lForcada,aRetCrd,nTotalFat)
					Conout("7.TMKA273D - Tk273GrvTel - " +;
							STR0029 + M->UA_NUM +;		//" Orcamento: "
							STR0031 )		//" Credito nao aprovado "
							
					Return(lRet) 
				else
					Conout("8.TMKA273D - Tk273GrvTel - " +;
							STR0029 + M->UA_NUM +;     //" Orcamento: "
							STR0032  )					//" Credito aprovado "
				Endif
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Seta variavel de controle para nao analisar o credito pelo SIGAFAT³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lAvalCre:= .F.  	
	            lBloqCre:= .T.		
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Seta variavel para controlar a execucao da transacao 2.  A transacao 2 devera ser executada apenas para a operacao de ³
				//³Faturamento, pois ate o orcamento se existir Contrato o mesmo devera se manter pendente ate a sua conversao.          ³
				//³Se a venda nao foi rejeitada e foi preenchido contrato, ou seja, se houve analise de fato, deve confirmar a transacao ³				
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		        If !aRetCrd[5] .AND. !Empty(aRetCrd[4])				
	 				Conout("9.TMKA273D - Tk273GrvTel - " +;
	 						STR0029 + M->UA_NUM +;          //" Orcamento: "
	 						" Validacao !aRetCrd[5] .AND. !Empty(aRetCrd[4] " )
	 			   	lConfCRD  := .T.			
	 			EndIf   	            
			Else
				Conout("10.TMKA273D - Tk273GrvTel - " +;
						STR0029 + M->UA_NUM +;  //" Orcamento: "
						" lSigaCRD = " + If( Empty(lSigaCRD), "", If(lSigaCRD, ".T.",".F.")) +; 
						" lTesTit = "  + If( Empty(lTesTit), "", If(lTesTit, ".T.",".F.")) +;
						" lProspec = " + If( Empty(lProspect), "", If(lProspect, ".T.",".F.")) )
			Endif	
	    Else
	    	Conout(STR0035)			//"11.TMKA273D - Tk273GrvTel - 22 Nao esta contido em cMV_CRDAVAL "
	    Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se os produtos não estão sendo utilizados pela rotina de ³
		//³ Saldos em Estoque (SB2).										  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        For nX := 1 To Len(aCols)
			SB1->(dbSeek(xFilial("SB1")+aCols[nX][nPProd]))
			SF4->(DbSeek(xFilial("SF4")+aCols[nX][nPTes]))			
			//Verifica somente os produtos que movimentam estoque.
			If SF4->F4_ESTOQUE == "S" .And. SB2->(dbSeek(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD))
				If !SB2->(SimpleLock())		//Se o registro estiver sendo utilizado por outro usuário.
					Aviso(STR0015,;
						  STR0076+AllTrim(SB1->B1_COD)+;	//"O Produto: "
						  STR0077+;							//" está sendo utilizado por outro usuário na rotina de Saldos em Estoque."
						  STR0078,;							//" O pedido não será gravado, até que o produto seja liberado."
						  {"OK"})
					//Destrava os registros.
					For nI := 1 To Len(aTravaSB2)
						SB2->(MsRUnlock(aTravaSB2[nI]))
					Next nI					
					Return (.F.)
				EndIf
				//Guarda o recno dos registros que foram travados.
				AADD(aTravaSB2, SB2->(Recno()))			
			EndIf			
		Next nX
		
		//Se forem gerados titulos financeiros e a condicao de pagamento foi escolhida
		If lTesTit
			//Somente permite a venda com TEF se a nota for gerada pelo Call Center
			If lUsaTef 
				//Verifica se os dados complementares foram preenchidos nas parcelas de cartao de credito
				For nI:=1 TO Len(aParcelas)
					
					If cTipTef $ TEF_CLISITEF
						If AllTrim(aParcelas[nI][3]) $ _FORMATEF 
							nCartao += aParcelas[nI][2]
						EndIf
					Else
						If (ALLTRIM(aParcelas[nI][3]) $ "CC")
							If (ALLTRIM(aParcelas[nI][3]) $ if(lCheque,"CC;CH","CC"))
	                            // Soma o numerario para CARTAO DE CREDITO 
								nCartao += aParcelas[nI][2]
							Endif
						Endif
					Endif
					
				Next nI
				
				If (nCartao > 0) .AND. (cTipTef == "2" .OR. cTipTef == "3" .OR. cTipTef == TEF_CLISITEF)
                    // A venda com TEF e CC obriga que o Televenda faca a geracao da NF e do TITULO.
					If (cOpFat <> "S")
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se nao estiver usando a entrada automatica³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !lTk271auto
							Help(" ",1,"ERRO_OPFAT")
						Endif	
						lTefOk := .F.
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Destrava os registros da tabela SB2 ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						Tk273Unlock(aTravaSB2)
						Return(lRet)
					Endif
				Endif
			Endif

			//Verifica se alguma das parcelas ‚ Cartao de Cr‚dito ou Cheque (TEF DEDICADO) 
			If ((nCartao > 0) .AND. (cTipTef == "2" .OR. cTipTef == "3" .OR. cTipTef == TEF_CLISITEF))

				//Somente permite a venda com TEF se a nota for gerada pelo Call Center
				If (cOpFat == "S")
					
					If cTipTef == TEF_CLISITEF	//Operacao com a nova DLL CliSiTEF
				
						//Pegando os dados totalizados de cartões a serem enviados para a transacao TEF
						For nI := 1 To Len(aPgtosSint)
							If AllTrim(aPgtosSint[nI][1]) $ _FORMATEF
							
								//Verifica o valor da primeira parcela a ser enviada para a transação TEF
								nPos := Ascan(aParcelas,{|x| AllTrim(x[3])+AllTrim(x[6]) == AllTrim(aPgtosSint[nI][1])+AllTrim(aPgtosSint[nI][4]) } )
								nVlrEntrada := If(nPos>0,aParcelas[nPos][2],0)
							
						        Aadd(aReceb,{ aPgtosSint[nI][5],;											//Data
							        	    Val(StrTran(StrTran(aPgtosSint[nI][3],",",""),".",""))/100,;	//Valor
							        	    aPgtosSint[nI][1],;												//Forma
							        	    aPgtosSint[nI][4],;												//ID para identificação da forma de pagamento na operação TEF
							        	    aPgtosSint[nI][2],;												//Qtde de Parcelas
											nVlrEntrada,;													//Valor Entrada
							        	    {Space(03),;
							        	    Space(3),;
							        	    Space(04),;
							        	    Space(10),;
							        	    Space(07),;
							        	    Space(15),;
							        	    Space(15)}}) //Dados do Cheque
							EndIf
						Next nI
								
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ A CliSiTef nao efetua consulta a cheque ³
						//³ na operacao TeleMarketing (funcao=100)  ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ						
						/*
						If At("S",LjGetStation("TEFCONS")) <> 0 //lCheque
							For nI := 1 To Len(aParcelas)
								If Alltrim(aParcelas[nI][3]) == "CH"
									Aadd(aReceb,{ aParcelas[nI][1],;						//Data
												aParcelas[nI][2],;							//Valor
												aParcelas[nI][3],;							//Forma
												aParcelas[nI][6],;							//ID para identificação da forma de pagamento na operação TEF
												1,;											//Quantidade de Parcelas
												0,;											//Valor de Entrada, para cheques podemos considerar o mesmo
												{"01",;										//Compensacao
												Substr(aParcelas[nI][4],1,3),; 			//Banco
												Substr(aParcelas[nI][4],4,5),;				//Agencia
												Substr(aParcelas[nI][4],9,10),;			//Conta
												Substr(aParcelas[nI][4],28,06),;			//Cheque (a ClisiTef aceita somente 6 posicoes)
												Substr(aParcelas[nI][4],34,14),;			//RG
												Substr(aParcelas[nI][4],48,15)}})			//Fone
								EndIf
							Next nI
					    EndIf*/
					
					Else //Se nao for CLISITEF					
				
						For nI := 1 TO Len(aParcelas)
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Se a "Consulta de Cheques" esta sendo utilizada as parcelas   ³
							//³de CH  serao enviadas para a transacao com o SITEF            ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If lCheque
								AAdd(aReceb,{	aParcelas[nI][1],;
												aParcelas[nI][2],;
												aParcelas[nI][3],;
												"",;
												"",;
												"",;
												"",;
												"",;
												""})
							ElseIf !(ALLTRIM(aParcelas[nI][3]) $ "CH")
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Se a "Consulta de Cheques" nao esta sendo utilizada as parcelas ³
								//³com CH nao serao enviadas para a transacao com o SITEF          ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								AAdd(aReceb,{	aParcelas[nI][1],;
												aParcelas[nI][2],;
												aParcelas[nI][3],;
												"",;
												"",;
												"",;
												"",;
												"",;
												""})
							Endif
						Next nI	
		
						//Parcelas da condicao de pagamento que serao enviadas para o TEF
						aParcTef := aClone(aReceb)
		
					Endif
		
				Endif
										
				//O Array aParcelas foi substituido pelo aReceb na passagem do parametro
				If cTipTef == TEF_CLISITEF
					//Verifica se usa a condicao de captura de pre-autorizacao
					If Upper(Alltrim(cDescPagto)) <> "CAPTURA"
						oTEF:Operacoes("T",aReceb,.F.)
					Else
						oTEF:Operacoes("CAPTURA_PRE_AUTORIZ",aReceb)
					EndIf
					lTefOk := oTef:lTefOk				
				Else
					lTefOk := LOJA010T( "V" , ,aReceb)
				Endif
					
				// Se o retorno nao for LOGICO - ocorreu um erro
				If !ValType(lTefOK) == "L"
					lTefOK := .F.
				Endif
				
				// Se o retorno for negativo para a transacao
				If !lTefOK
					If cTipTef <> TEF_CLISITEF
						//Envia desfazimento da transacao
						LOJA010T("F","N")
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Destrava os registros da tabela SB2 ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						Tk273Unlock(aTravaSB2)
						Return(lRet)
					Endif
				Endif
					
				If !lTefOk
					If !lTk271Auto
						lGrava	:= TmkOk(STR0002) 	 //"Continua Manualmente?"
					Endif
					
					If !lGrava
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Destrava os registros da tabela SB2 ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						Tk273Unlock(aTravaSB2)
						Return(lRet)
					Endif
				Else
				
					If cTipTef <> TEF_CLISITEF
						// Finaliza operacao TEF
						If !LOJA010T( "I", "V" )
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Destrava os registros da tabela SB2 ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							Tk273Unlock(aTravaSB2)
							Return(lRet)
						Endif           
						aCupomTEF := Cupom_TEF() 	// Funcao de impressao do sigaloja onde capturo a Adm. de cartao de credito.
						cAdm      := IF(ValType(aCupomTEF) == "A",Alltrim(aCupomTEF[7]),"")
						cAdm      := Tk273GetSAE(cAdm)											
					Else 
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ CLISITEF: finaliza operacao TEF (no TMK nao e obrigat. imprimir cupom)  ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ						
						If oTef:lTefOk 				//Se nao ocorreu problema na transacao Tef
				   		   oTEF:FinalTrn(1) 		//Finaliza a TRN com parametro confirma = 1
				   		   oTef:lTefOk	:= .T.
						EndIf
					EndIf								
					
				Endif           

			Endif
		Endif
		
		If	cPaisLoc == "BRA" .OR.;
			(cPaisLoc <> "BRA" .AND. (Type(M->UA_DOCGER) <> "U" .AND. M->UA_DOCGER $ "13"))
			//Gera o faturamento a partir do SC5 de acordo com o MV_OPFAT
			Do Case
				Case cOpFat == "S"
					lOpFat := .T.
							
				Case cOpFat == "P"
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se nao estiver usando a entrada automatica³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If !lTk271Auto
						If TmkOk(STR0003) //"Confirma Faturamento ?"
							lOpFat := .T.
						Endif
					Else
					    lOpFat := .F.  // Como a entrada automatica esta ATIVA a opcao "P" so vai gerar Pedido.
					Endif	
			EndCase
		Endif
		
		//ÚÄLocalizacoesÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gera remito/remision/guia de despacho conforme parametro  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If cPaisLoc <> "BRA" .AND. (Type(M->UA_DOCGER) <> "U" .AND. M->UA_DOCGER == "2")
			Do Case
				Case ALLTRIM(cOpRem) == "N"
					lOpRem := .F.
					
				Case ALLTRIM(cOpRem) == "S"
					lOpRem := .T.
					
				Case ALLTRIM(cOpRem) == "P"
					If cPaisLoc == "ARG"
						cTextMsg := STR0004 //"¨Genera Remito?"
						
					ElseIf cPaisLoc $ "COL|MEX|PAR"
						cTextMsg := STR0005 //"¨Genera Remision?"
						
					ElseIf cPaisLoc == "CHI"
						cTextMsg := STR0006 //"¨Genera Guia de Despacho?"
						
					ElseIf cPaisLoc == "VEN"
						cTextMsg := STR0007 //"¨Genera Factura de Entrega?"
						
					Endif
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se nao estiver usando a entrada automatica³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If !lTk271auto
						If TmkOk(cTextMsg)
							lOpRem := .T.
						Else
							lOpRem := .F.
						Endif
					Else
						lOpRem := .T. // Como a entrada automatica esta ATIVA a opcao "P" sempre gera o REMITO
					Endif	
			EndCase
		Endif
	Endif
	
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicia o processo de gravacao rapido - revisado com o Eduardo a partir da versao 6.09                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !lGrava
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Destrava os registros da tabela SB2 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Tk273Unlock(aTravaSB2)
	Return(lRet)
Endif
lGrava := .F.

DbSelectArea("SB1")
DbSetOrder(1)

DbSelectArea("SF4")
DbSetOrder(1)
           
// Verifica se a condicao de pagamento e do tipo 9
DbSelectArea("SE4")
DbSetOrder(1)
If DbSeek(xFilial("SE4")+cCodPagto)
	If SE4->E4_TIPO == "9"
		lTipo9 := .T.
	Endif
Endif

// Pega o tipo do Cliente / Prospect
If lProspect
	DbSelectArea("SUS")
	DbSetOrder(1)
	If DbSeek(xFilial("SUS") + M->UA_CLIENTE + M->UA_LOJA)
		cTipoCli:= SUS->US_TIPO
	Endif
Else
	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1") + M->UA_CLIENTE + M->UA_LOJA)
		cTipoCli:= SA1->A1_TIPO
		nValComi:= SA1->A1_COMIS
	Endif
Endif

If lTKTipCli 
	cTipoCli := U_TKTIPCLI(cTipoCli)
Else
	cTipoCli := M->UA_TIPOCLI
EndIf	

If nValComi == 0	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pega o valor da comissao no cadastro de vendedores, caso nao tenha o % preenchido no cadastro de clientes ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Empty(M->UA_COMIS) .AND. !Empty(M->UA_VEND)
		DbSelectArea("SA3")
		DbSetOrder(1)
		If DbSeek(xFilial("SA3")+M->UA_VEND)
			nValComi := A3_COMIS
		Endif
	Endif
Endif

If !Empty(M->UA_OPER)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se a liga‡„o for de um PROSPECT e for um FATURAMENTO passo o PROSPECT para  ³
	//³o Cadastro de clientes e ATUALIZO o Cadastro de Prospect tudo no P.E TMKVA1 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Val(M->UA_OPER) == FATURAMENTO

		If lTMKVA1 .AND. lProspect
			lRet := U_TMKVA1()
			If ValType(lRet) <> "L"
				lRet := .F.
			Endif
			
			If !lRet
				lProspect := .T.
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Destrava os registros da tabela SB2 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				Tk273Unlock(aTravaSB2)
				Return(lRet)
			Else
			    lRet := Tk273GrvPTC(M->UA_CLIENTE,M->UA_LOJA)
			    If lRet
			    	lProspect := .F.
			    Else	
				    lProspect := .T.
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Destrava os registros da tabela SB2 ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					Tk273Unlock(aTravaSB2)
				    Return(lRet)
				Endif    
			Endif	
		Endif
	Endif

	//Inclui os bonus
	Tk273Bonus(1)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Atualiza o status dos semaforos para evitar o empilhamento do ultimo folder ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nOpc == 3  // Inclusao
		
		If TkGetTipoAte() == "4"
			//O usuario esta no segundo  folder
			
			If nFolder == 2  //TLV
				// Volta a sequencia do ultimo folder
				DbSelectArea("ACF")
				RollBackSX8()
				
				DbSelectArea("SUA")
			Endif
			
		Endif
		
		DbSelectArea("SUA")
		DbSetOrder(1)
		
		cMay := "SUA" + ALLTRIM(xFilial("SUA")) + cNumAux
		While (DbSeek(xFilial("SUA") + cNumAux) .OR. !MayIUseCode(cMay))
			cNumAux := Soma1(cNumAux,Len(cNumAux))
			cMay 	:= "SUA" + ALLTRIM(xFilial("SUA")) + cNumAux
		End
		
		If (cNumAux <> M->UA_NUM)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se nao estiver usando a entrada automatica³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271auto
				Help(" ",1,"NUMSEQ",,cNumAux,4,15)
			Endif	
			M->UA_NUM := cNumAux
		Endif
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Confirma o codigo do atendimento³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If __lSX8
			ConfirmSX8()
		Endif
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Libera numeros reservados                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		FreeUsedCode(.T.)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Atualiza o flag para inclusao de registro³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		lNovo := .T.
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Atualiza o status dos semaforos para evitar o empilhamento do ultimo folder ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If TkGetTipoAte() == "4"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³O usuario esta no segundo  folder     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If nFolder == 2  //TLV
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Volta a sequencia do primeiro  folder ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				DbSelectArea("SUC")
				RollBackSX8()
				
				DbSelectArea("SUA")
			Endif
		Endif
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a gravacao dos lancamentos do SIGAPCO          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PcoIniLan("000100")

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicia a gravacao do SUA/SC5/SUB/SC6 - Atendimento e Pedido                                                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nX := 1 TO Len(aCols)

		BEGIN TRANSACTION
			
			//Grava o cabecalho do TELEVENDAS
			If lFirst
	
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Antes de gravar o cabecalho de Televendas - Grava/Apaga as listas de Contatos pendentes     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If !Empty(M->UA_PROXLIG)
					If ( !IsInCallStack("TK380EXECLISTA") .Or. ( M->UA_PROXLIG <> SUA->UA_PROXLIG .Or.  M->UA_HRPEND <> SUA->UA_HRPEND ) )
						TKGrvSU4(M->UA_CODCONT	,IF(lProspect,"SUS","SA1"),(M->UA_CLIENTE+M->UA_LOJA)	,M->UA_OPERADO,;
								"2"				,M->UA_NUM					,M->UA_PROXLIG			,M->UA_HRPEND,;
								l380)
					EndIf
				Else
				
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se for alteracao de atendimento verifica se ja existe uma lista de contato gerada anteriormente³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		            If nOpc == 4 
		
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se o campo "Proxima Ligacao" no banco estiver preenchido significa que ja foi gerada uma lista de contato pendente anteriormente³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If !Empty(SUA->UA_PROXLIG)
					
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Procura a lista de contato pendente³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							DbSelectArea("SU4")
							DbSetOrder(4)			//U4_FILIAL+U4_CODLIG
							If DbSeek(xFilial("SU4")+M->UA_NUM)
								// Flag para garantir que o item da lista (SU6) sera apagado e consequentemente o pai pode ser apagado tambem (SU4)
					            lApagaSU4 := .F.
					            
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Apaga os itens da lista de contatos.³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								DbSelectArea("SU6")
								DbSetOrder(1)
								If DbSeek(xFilial("SU6") + SU4->U4_LISTA)
									While (!Eof()) .AND. (SU6->U6_FILIAL == xFilial("SU6")) .AND. (SU6->U6_LISTA == SU4->U4_LISTA)
										If Alltrim(SU6->U6_STATUS) == "1"   // Nao enviado
											Reclock( "SU6" ,.F.,.T.)
											DbDelete()
											MsUnlock()
											lApagaSU4 := .T.
										Endif	
										SU6->(DbSkip())
									End
								Endif
							
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Apaga o cabecalho da lista de contatos ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								If lApagaSU4
									DbSelectArea("SU4")
									Reclock( "SU4" ,.F.,.T.)
									DbDelete()
									MsUnlock()
								Endif	
								
							Endif
						Endif	
					Endif
				Endif
			     
			
		
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Pega forma de pagamento³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

				DbSelectArea("SE4")
				DbSetOrder(1)
				If DbSeek(xFilial("SE4")+cCodPagto)
   					cForma:=SE4->E4_FORMA
				EndIf 
			

				//Grava o cabecalho do TELEVENDAS
				DbSelectArea("SUA")
				RecLock("SUA",lNovo)
				
				For nCont := 1 To Len(aSx3SUA)				// Array com os campos do SUA no dicionario
					cCampo := ALLTRIM(aSx3SUA[nCont][1])	//X3_CAMPO
					
					Do Case
						Case (cCampo == "UA_FILIAL")
							SUA->&(cCampo) := xFilial("SUA")
							
						Case (cCampo == "UA_VALMERC")
							SUA->&(cCampo) := aValores[MERCADORIA]
							
						Case (cCampo == "UA_ACRESCI")
							SUA->&(cCampo) := aValores[ACRESCIMO]
							
						Case (cCampo == "UA_DESPESA")
							SUA->&(cCampo) := aValores[DESPESA]
							
						Case (cCampo == "UA_DESCONT")
							SUA->&(cCampo) := aValores[DESCONTO]
							
						Case (cCampo == "UA_VALBRUT")
							SUA->&(cCampo) := aValores[MERCADORIA]
							
						Case (cCampo == "UA_VLRLIQ")
							SUA->&(cCampo) := aValores[TOTAL]
							
						Case (cCampo == "UA_DTLIM")
							SUA->&(cCampo) := dDataBase+nValidade
							
						Case (cCampo == "UA_FRETE")
							SUA->&(cCampo) := aValores[FRETE]
							
						Case (cCampo == "UA_INICIO")
							SUA->&(cCampo) := cTimeIni
							
						Case (cCampo == "UA_FIM")
							SUA->&(cCampo) := Time()
							
						Case (cCampo == "UA_ENDENT")
							SUA->&(cCampo) := cEnt
							
						Case (cCampo == "UA_ENDCOB")
							SUA->&(cCampo) := cCob
							
						Case (cCampo == "UA_CEPE")
							SUA->&(cCampo) := cCepE
							
						Case (cCampo == "UA_CEPC")
							SUA->&(cCampo) := cCepC
							
						Case (cCampo == "UA_MUNE")
							SUA->&(cCampo) := cCidadeE
							
						Case (cCampo == "UA_MUNC")
							SUA->&(cCampo) := cCidadeC
							
						Case (cCampo == "UA_ESTE")
							SUA->&(cCampo) := cUFE
							
						Case (cCampo == "UA_ESTC")
							SUA->&(cCampo) := cUFC
							
						Case (cCampo == "UA_TRANSP")
							SUA->&(cCampo) := cCodTransp
							
						Case (cCampo == "UA_BAIRROC")
							SUA->&(cCampo) := cBairroC
							
						Case (cCampo == "UA_BAIRROE")
							SUA->&(cCampo) := cBairroE
							
						Case (cCampo == "UA_ACRECND")
							SUA->&(cCampo) := nVlJur
							
						Case (cCampo == "UA_PROSPEC")
							SUA->&(cCampo) := lProspect
							
						Case (cCampo == "UA_STATUS")
							SUA->&(cCampo) := IF(SUA->UA_CANC== "S","CAN","SUP")
							
						Case (cCampo == "UA_ENTRADA")
							SUA->&(cCampo) := nEntrada
							
						Case (cCampo == "UA_FINANC")
							SUA->&(cCampo) := nFinanciado
							
						Case (cCampo == "UA_JUROS")
							SUA->&(cCampo) := nTxJuros
							
						Case (cCampo == "UA_TXDESC")
							SUA->&(cCampo) := nTxDescon
							
						Case (cCampo == "UA_PARCELA")
							SUA->&(cCampo) := nNumParcelas
							
						Case (cCampo == "UA_CONDPG")
							SUA->&(cCampo) := cCodPagto 
							
						Case(cCampo == "UA_FORMPG")	
							SUA->&(cCampo):= cForma 
							
						Case (cCampo == "UA_CARTAO")
							SUA->&(cCampo) := nCartao
							
						Case (cCampo == "UA_DIASDAT")
							SUA->&(cCampo) := (CTOD("01/01/45") - dDataBase)
							
						Case (cCampo == "UA_HORADAT")
							SUA->&(cCampo) := 86400 - ( (VAL(Substr(cTimeIni,1,2))*3600) + ( VAL(Substr(cTimeIni,4,2))*60) + VAL(Substr(cTimeIni,7,2)) )

						OtherWise
                            If (aSx3SUA[nCont][2] <> "V") .AND. (aSx3SUA[nCont][3])		// X3_CONTEXT e .T.
								If (SUA->(FieldPos(cCampo))  > 0)
									SUA->&(cCampo) := M->&(cCampo)
								Endif
							Endif
							
					EndCase
		
				Next nCont
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualizacao das informacoes da Analise de Credito feita pelo SIGACRD³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lSigaCRD .AND. lTesTit .AND. !lProspect	                           
					Conout("12.TMKA273D - Tk273GrvTel - " +;
							STR0029 + M->UA_NUM +;		//" Orcamento: "
							STR0036 )		//"Chama a funcao Tk273GrvCred "
					Tk273GrvCred(lForcada)				                               
				Endif
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Caso utilizou o TEF para as vendas com cartao de credito, atualiza as informacoes da venda com TEF.³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lUsaTef
					If lTefOk .AND. (cTipTef == "2" .OR. cTipTef == "3" .OR. cTipTef == TEF_CLISITEF)
						
						If cTipTef <> TEF_CLISITEF						
							SUA->UA_VENDTEF := "S"
							SUA->UA_DATATEF := aTefDados[1][2]
							SUA->UA_HORATEF := aTefDados[1][3]
							SUA->UA_DOCTEF  := aTefDados[1][4]
							SUA->UA_AUTORIZ := aTefDados[1][5]
							SUA->UA_INSTITU := aTefDados[1][8]
							SUA->UA_DOCCANC := aTefDados[1][6]
							SUA->UA_DATCANC := aTefDados[1][12]
							SUA->UA_HORCANC := aTefDados[1][7]
							SUA->UA_NSUTEF  := aTefDados[1][9]
							SUA->UA_TIPCART := aTefDados[1][10]
							
							If ! Empty(aTefDados[1][15])
								SUA->UA_FORMPG  := aTefDados[1][15]
							Else
								SUA->UA_FORMPG  := "CC"
							Endif												
						Else	//CliSiTEF 							
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Efetua a alteracao das datas e conferencia de ADM informadas durante o processamento do TEF		       ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ							
							Tk273TEFAceParc(aParcelas)
							
							SUA->UA_VENDTEF := "S"
							SUA->UA_DATATEF := oTef:cData
							SUA->UA_HORATEF := oTef:aRetCartao[1]:cHoraTrans
							SUA->UA_DOCTEF  := oTef:aRetCartao[1]:cNsuAutor
							SUA->UA_AUTORIZ := oTef:aRetCartao[1]:cAutoriza
							SUA->UA_INSTITU := oTef:aRetCartao[1]:cDescAdm
							SUA->UA_NSUTEF  := oTef:aRetCartao[1]:cNsuSitef
							SUA->UA_TIPCART := oTef:aRetCartao[1]:cTipCart 							
							If !Empty(oTef:aRetCartao[1]:cDocCanRei)
								SUA->UA_DOCCANC := oTef:aRetCartao[1]:cDocCanRei
								SUA->UA_DATCANC := StrTran(DToC(oTef:aRetCartao[1]:dDataCanRei),"/","")
								SUA->UA_HORCANC := oTef:aRetCartao[1]:cHoraTrans
							Endif
							If !Empty(oTef:aRetCartao[1]:cForma)
								SUA->UA_FORMPG  := oTef:aRetCartao[1]:cForma
							Else
								SUA->UA_FORMPG  := "CC"
							Endif
							cAdm := oTef:aRetCartao[1]:cCodAdm
						Endif						
						
					Else
						SUA->UA_VENDTEF := "N"
					Endif
				Endif
				MsUnlock()
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Grava a OBSERVACAO do atendimento³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If nOpc == 3
					If !Empty(M->UA_OBS)		//Inclusao
						MSMM(,nTamUA_OBS,,M->UA_OBS,1,,,"SUA","UA_CODOBS")
					Endif
				Else
					If Empty(SUA->UA_CODOBS)	// Inclusao
						MSMM(,nTamUA_OBS,,M->UA_OBS,1,,,"SUA","UA_CODOBS")
					Else						// Alteracao
						MSMM(SUA->UA_CODOBS,nTamUA_OBS,,M->UA_OBS,1,,,"SUA","UA_CODOBS")
					Endif
				Endif

				FkCommit() // Commit para Integridade Referencial do SUA.
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Apaga os items da forma de pagamento do SL4         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				DbSelectArea("SL4")
				DbSetOrder(1)
				If DbSeek(xFilial("SL4") + M->UA_NUM +"SIGATMK ")  //O espaco em branco e necessario para a Chave
					While !Eof() 						   .AND. ;
						(SL4->L4_FILIAL == xFilial("SL4")) .AND. ;
						(SL4->L4_NUM == M->UA_NUM) 		   .AND. ;
						(ALLTRIM(SL4->L4_ORIGEM) == "SIGATMK")

						RecLock("SL4",.F.,.T.)
						DbDelete()
						MsUnlock()
						DbSkip()
					End
				Endif
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Grava informacoes do arquivo de forma de pagamento  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If (Len(aParcelas) > 0)
					For nI := 1 TO Len(aParcelas)
						Reclock("SL4",.T.)
						Replace L4_NUM	   With M->UA_NUM
						Replace L4_FILIAL  With xFilial("SL4")
						Replace L4_DATA    With aParcelas[nI][1]
						Replace L4_VALOR   With aParcelas[nI][2]
						Replace L4_FORMA   With aParcelas[nI][3]
						Replace L4_OBS     With aParcelas[nI][4]
						Replace L4_ORIGEM  With "SIGATMK"						
						Replace L4_NUMCART With SUBSTR(aParcelas[nI][4], AT("*", aParcelas[nI][4]), 16)
						
						If lUsaTef .AND. lTefOk .AND. cTipTef == TEF_CLISITEF
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Grava no SL4 os campos gerados na trans. TEF (Clisitef) ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                        	Tk273GeraTef(aParcelas[nI][1],;				//Data
                        				 aParcelas[nI][3],;				//Forma
                        				 aParcelas[nI][6],;				//ID Cartao
                        				 Substr(aParcelas[nI][4],1,3),;//Bco
                        				 NIL,;							//Agencia
                        				 NIL,;							//Cheque
                        				 NIL,;							//Adm
                        				 nI)							//Indice array
						Else
							
							Replace L4_AUTORIZ With SUBSTR(aParcelas[nI][4], (AT("*", aParcelas[nI][4]) + 24))
							Replace L4_ADMINIS With IF(!Empty(cAdm), cAdm, SUBSTR(aParcelas[nI][4], 0, (AT("*", aParcelas[nI][4]) - 1)))
							
						Endif
						If Len(aParcelas[nI]) >= 5
							If aParcelas[nI][5] > 0
								Replace L4_COMP With STR(aParcelas[nI][5],3,0)
							Endif
						EndIf
						SL4->(MsUnlock())
					Next nI
                Endif
                
				// Ponto de Entrada apos a gravacao do arquivo SL4
				If lTMKVSL4
					U_TMKVSL4(M->UA_NUM,aParcelas)				
				EndIf				
                
				//Se nao existir o Ponto TMKVPED o sistema grava o SC5 - Esse ponto Substitui a gravacao do SC5/SC6
				If !lTMKVPED
					
					//Se o atendimento ja foi gravado como FATURAMENTO executa o Estorno do SC5
					If (nOpAnt == FATURAMENTO) .AND. (nOpc == 4)
						DbSelectArea("SC5")
						DbSetOrder(1)
						If DbSeek(xFilial("SC5") + cNumSC5)
							MaAvalSC5("SC5",2)	//Estorna
						Endif
					Endif	
					
					If Val(M->UA_OPER) == FATURAMENTO
							
						//Se ‚ um NOVO PEDIDO gero os registros no SC5
						If Empty(cNumSc5)
							DbSelectArea("SC5")
							DbSetOrder(1)
							cNumSC5 := GetSxeNum("SC5","C5_NUM")
						
							cMay := "SC5"+ALLTRIM(xFilial("SC5"))+cNumSC5
							While (DbSeek(xFilial("SC5")+cNumSC5) .OR. !MayIUseCode(cMay))
								cNumSC5 := Soma1(cNumSC5,Len(cNumSC5))
								cMay 	:= "SC5"+ALLTRIM(xFilial("SC5"))+cNumSC5
							End
							If __lSX8
								ConfirmSX8()
							Endif

							lNovo := .T.
						Endif	
                    
						DbSelectArea("SC5")
						RecLock("SC5",lNovo)
						Replace C5_FILIAL  With xFilial("SC5")
						Replace C5_NUM     With cNumSC5
						Replace C5_TIPO    With "N"
						Replace C5_CLIENTE With M->UA_CLIENTE
						Replace C5_LOJACLI With M->UA_LOJA
						Replace C5_CLIENT  With M->UA_CLIENTE
						Replace C5_LOJAENT With M->UA_LOJA
						Replace C5_TRANSP  With cCodTransp
						Replace C5_TIPOCLI With cTipoCli
						Replace C5_CONDPAG With cCodPagto
						Replace C5_TABELA  With M->UA_TABELA
						Replace C5_VEND1   With M->UA_VEND
						Replace C5_COMIS1  With IIF( Empty( nValComi ), M->UA_COMIS, nValComi)
						Replace C5_ACRSFIN With nTxJuros

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³A data de emissao do pedido e atualizada somente na primeira gravacao³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If lNovo
							Replace C5_EMISSAO With dDataBase
							//Natureza quando o MV_1DUPNAT é no pedido de venda
							cNaturez := MaFisRet(, "NF_NATUREZA")
							If "C5_NATUREZ"  $ SuperGetMv("MV_1DUPNAT",.F.,"") .And. !Empty(cNaturez)
								Replace C5_NATUREZ With cNaturez 
							EndIf

							
						Endif	
						Replace C5_MOEDA   With M->UA_MOEDA
						Replace C5_TXMOEDA With RecMoeda(M->UA_EMISSAO,M->UA_MOEDA)
						Replace C5_LIBEROK With IF(lOpFat .OR. lOpRem,"S","")
						Replace C5_FRETE   With aValores[FRETE]
						Replace C5_DESPESA With aValores[DESPESA]
						Replace C5_DESCONT With IF(Empty(M->UA_PDESCAB),aValores[DESCONTO],0) // O desconto no rodape e valido somente se o Operador nao usa a INDENIZACAO (Cabecalho)
						Replace C5_TIPLIB  With M->UA_TIPLIB
						Replace C5_COMIS1  With IIF( Empty( nValComi ), M->UA_COMIS, nValComi)						
						Replace C5_PDESCAB With M->UA_PDESCAB
						Replace C5_TPFRETE With M->UA_TPFRETE 
						Replace C5_TPCARGA With M->UA_TPCARGA 
						Replace C5_DESC1   With M->UA_DESC1
						Replace C5_DESC2   With M->UA_DESC2
						Replace C5_DESC3   With M->UA_DESC3
						Replace C5_DESC4   With M->UA_DESC4
						Replace C5_INCISS  With SA1->A1_INCISS
						If cPaisLoc <> "BRA" .AND. Type(SUA->UA_DOCGER) <> "U"
							Replace C5_DOCGER  With SUA->UA_DOCGER
							Replace C5_TIPOREM With "0"
						Endif

						// Grava as parcelas quando a venda for do tipo 9
						If lTipo9
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Acerta as informações das parcelas que foram desconsideradas³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If Len(aParcelas) < nNumPar
								For nI := 1 To nNumPar - Len(aParcelas)
									AADD(aParcelas ,{	CtoD("  /  /  "),;
															0  ,;
															"" ,;
															Space(80),;
															0,;
															Space(01)})
								Next
							EndIf
							For nI := 1 TO Len(aParcelas)
								Replace &("SC5->C5_DATA"+Substr(cParcela,nI,1)) With aParcelas[nI][1]
								If aParcelas[nI][5] > 0
									Replace &("SC5->C5_PARC"+Substr(cParcela,nI,1)) With aParcelas[nI][5] //Valor em %
								Else
									Replace &("SC5->C5_PARC"+Substr(cParcela,nI,1)) With aParcelas[nI][2] //Valor em R$
								Endif
							Next nI
						Endif
				        
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Gravacao dos campos SIGACRD para integracao com o SIGAFAT.  ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

					   	Replace C5_CONTRA with SUA->UA_CONTRA
			        	
   						FkCommit() // Commit para integridade referencial do SC5
				    
						//Atualizo o numero do pedido e do atendimento para gerar a NF  - MV_OPFAT = "S"
						AADD(aPedido,{M->UA_NUM,cNumSc5})
					
						//Atualizo o numero do pedido no SUA 
						DbSelectArea("SUA")
						RecLock("SUA",.F.)
						Replace UA_NUMSC5 With cNumSC5
						MsUnlock()
                    Endif                              
			    Endif
			Endif
			lFirst := .F.	
			// Verifica os itens que foram excluidos do Acols e que foram incluidos - Atendimento (SUB)
			cI := SomaIt(cI)

			//Se a linha foi apagada - apaga da Base de dados
			If aCols[nX][Len(aHeader)+1]	
				DbSelectArea("SUB")
				DbSetOrder(1)
				If DbSeek(xFilial("SUB") + M->UA_NUM + aCols[nX][nPItem])
					Reclock("SUB",.F.,.T.)
					DbDelete()
					MsUnlock()
				Endif
			
			ElseIf !Empty(aCols[nX][nPProd])
					
				//Se o item e valido grava no SUB - verifica se e novo ou nao
				cNovoItem := SomaIt(cNovoItem)
				
				DbSelectArea("SUB")
				DbSetOrder(1)
				If DbSeek(xFilial("SUB") + M->UA_NUM + aCols[nX][nPItem])
					lNovo := .F.
				Else
					lNovo := .T.
				Endif
					
				Reclock("SUB",lNovo)
				bCampo := {|nCPO| Field(nCPO) }
					
				Replace SUB->UB_FILIAL  With xFilial("SUB")
				Replace SUB->UB_NUM     With M->UA_NUM
				Replace SUB->UB_ITEM    With aCols[nX][nPItem]
					
				For nI := 1 To SUB->(FCount())
				
					If !(EVAL(bCampo,nI) == "UB_FILIAL") .AND. !(EVAL(bCampo,nI) == "UB_NUM") .AND. !(EVAL(bCampo,nI) == "UB_ITEM")
						nPos:= Ascan(aHeader,{|x| ALLTRIM(EVAL(bCampo,nI)) == ALLTRIM(x[2])})
						If (nPos > 0)
							If (aHeader[nPos][10] <> "V" .AND. aHeader[nPos][08] <> "M")
								Replace SUB->&(EVAL(bCampo,nI)) With aCols[nX][nPos]
							Endif 
							If aHeader[nPos][08] == "M"
								cMemo:= M->aCols[nX][nPos]
								If !Empty (cMemo) .Or. Altera
									If aHeader[nPos][10] <> "V"
										SUB->(FieldPut(FieldPos(Trim(aHeader[npos][2])),cMemo))
									EndIf	
						   		EndIf	
							Endif
				   		Endif
				   	Endif	
				Next nI
				
			Endif 
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Ponto de Entrada depois da gravacao do SUA/SUB - Documentado para nao usar interface ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lTMKVOK
				If nX == Len(aCols)
					U_TMKVOK(M->UA_NUM)
				Endif
			Endif	

			If (Val(M->UA_OPER) == FATURAMENTO) 

				//Se nao existir o Ponto TMKVPED o sistema grava o SC5 - Esse ponto Substitui a gravacao do SC5/SC6
				If !lTMKVPED
	
					//Se a linha atual foi deletada apaga do SC6 
					If aCols[nX][Len(aHeader)+1]
						SB1->(DbSeek(xFilial("SB1")+aCols[nX][nPProd]))
						SF4->(DbSeek(xFilial("SF4")+aCols[nX][nPTes]))
						//Destrava o resgitro da tabela SB2 - Saldos em Estoque.
						If SF4->F4_ESTOQUE == "S" .And. SB2->(dbSeek(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD))
							SB2->(MsUnlock())
						EndIf
						DbSelectArea( "SC6" )
						DbSetOrder(1)
						If DbSeek(xFilial("SC6") + cNumSc5 + aCols[nX][nPItem])
							Reclock("SC6" ,.F.,.T.)
							DbDelete()
							MaAvalSC6("SC6",2,"SC5")
						Endif
	
					ElseIf !Empty(aCols[nX][nPProd])
		
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Se houver Desconto  no Total do Pedido               ³
						//³fa‡o um rateio entre os itens para gravar no SC6     ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					   	//O suframa ja estara somado no item (na funcao TK273Refresh) como ocorre no pedido de vendas
					   	nValorSC6 := aCols[nX][nPvlrItem] //+ MaFisRet(nX,'IT_DESCZF')
						
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Gravacao do valor bruto no SC6 para ajuste de geracao³
						//³de pedidos pelo faturamento sem recalculo de SUFRAMA ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  		
				
						SB1->(DbSeek(xFilial("SB1")+aCols[nX][nPProd]))
						SF4->(DbSeek(xFilial("SF4")+aCols[nX][nPTes]))
						//Destrava o resgitro da tabela SB2 - Saldos em Estoque.
						If SF4->F4_ESTOQUE == "S" .And. SB2->(dbSeek(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD))
							SB2->(MsUnlock())
						EndIf
				
						DbSelectArea("SC6")
						DbSetOrder(1)
						If DbSeek(xFilial("SC6") + cNumSc5 + aCols[nX][nPItem])
							lNovo := .F.
							RecLock("SC6")
							MaAvalSC6("SC6",2,"SC5")
						Else
							lNovo := .T.
						Endif
								
						Reclock("SC6",lNovo)
						Replace C6_FILIAL  With xFilial("SC6")
						Replace C6_NUM     With cNumSC5
						Replace C6_ITEM    With aCols[nX][nPItem]
						Replace C6_CLI     With SC5->C5_CLIENTE
						Replace C6_LOJA    With SC5->C5_LOJACLI
						Replace C6_PRODUTO With aCols[nX][nPProd]
						Replace C6_COMIS1  With SB1->B1_COMIS
							Replace C6_DESCRI  With aCols[nX][nPDescPro]
						Replace C6_UM	   With aCols[nX][nPUm]
						Replace C6_QTDVEN  With aCols[nX][nPQtd]
						Replace C6_SEGUM   With SB1->B1_SEGUM
						Replace C6_UNSVEN  With ConvUm(aCols[nX][nPProd],aCols[nX][nPQtd],0,2)
						Replace C6_PRUNIT  With aCols[nX][nPPrcTab]
						If cPrcFiscal == "1"  								// Se o PRECO FISCAL BRUTO = Sim
							Replace C6_PRCVEN With NoRound(nValorSC6 / aCols[nX][nPQtd],nTamDec)
						Else
							Replace C6_PRCVEN  	With aCols[nX][nPVrunit] 	// O valor do item ja esta com desconto
							Replace C6_VALDESC	With aCols[nX][nPValdesc]
							Replace C6_DESCONT 	With aCols[nX][nPDesc]
						Endif
						Replace C6_VALOR   With nValorSC6
						Replace C6_TES     With aCols[nX][nPTes]
						Replace C6_CF      With aCols[nX][nPCf]
						Replace C6_LOCAL   With aCols[nX][nPLocal]
						Replace C6_ENTREG  With aCols[nX][nPDtEntre]
						Replace C6_TPOP    With "F"
						
						/*
							ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							³Nao atualizo este campo, pois a funcao MaAvalSC6 o atualizara.³
							ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							Replace C6_QTDEMP  With IF(lOpFat .OR. lOpRem,aCols[nX][nPQtd],0)
					    */
						Replace C6_QTDLIB  With IF(lOpFat .OR. lOpRem,aCols[nX][nPQtd],0)
						Replace C6_CLASFIS With Subs(SB1->B1_ORIGEM,1,1)+SF4->F4_SITTRIB
						Replace C6_PEDCLI  With "TMK"+M->UA_NUM
							Replace C6_OPC  With aCols[nX][nPOpc]
						Replace C6_CODISS  With SB1->B1_CODISS
						If nLote > 0
							Replace C6_LOTECTL With aCols[nX][nLote]
						EndIf
						If nSubLote > 0
							Replace C6_NUMLOTE With aCols[nX][nSubLote]
						EndIf
						If nDtValid > 0
							Replace C6_DTVALID With aCols[nX][nDtValid]
						EndIf
						If npItemPC > 0 .And. npNumPCom >0
							Replace C6_ITEMPC  With aCols[nX][npItemPC]
							Replace C6_NUMPCOM With aCols[nX][npNumPCom]
						EndIf
						If npPICMRET > 0
							Replace C6_PICMRET  With aCols[nX][npPICMRET]							
						EndIf
						If cPaisLoc == "BRA" .And. npCodFCI >0 .And. npVlrFCI >0 
							Replace C6_FCICOD  With aCols[nX][npCodFCI]
							Replace C6_VLIMPOR With aCols[nX][npVlrFCI]
						EndIf
						FkCommit() // Commit para integridade referencial do SC6

						/*			

						ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						³Parametros³ExpC1: Alias da tabela dos itens do Pedido de Venda         ³
						³          ³ExpN2: Codigo do Evento                                     ³
						³          ³       [1] Implantacao do Pedido de Venda                   ³
						³          ³       [2] Estorno  do Pedido de Venda                      ³
						³          ³       [3] Liberacao do Pedido de Venda                     ³
						³          ³       [4] Estorno da Liberacao do Pedido de Venda          ³
						³          ³       [5] Preparacao da Nota Fiscal de Saida               ³
						³          ³       [6] Estorno da Nota Fiscal de Saida                  ³
						³          ³ExpC3: Alias do SC5                                         ³
						³          ³ExpL4: Liberacao Parcial                                    ³
						³          ³ExpL5: Transfere Locais                                     ³
						³          ³ExpL6: Verifica se todos os itens foram liberados           ³
						³          ³ExpL7: Verifica os residuos do pedido de venda              ³
						³          ³ExpL8: Verifica se todos os itens foram faturados           ³
						³          ³ExpL9: Atualiza somente os acumulados                       ³
						³          ³ExpNA: Valor a ser adicionado ao limite de credito          ³
						³          ³ExpCB: Alias do SD2 ( Uso Interno para otimizacao )         ³
						³          ³ExpLC: Indica se esta o SC6 esta sendo baixado por un REMITO³
						ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						*/
						MaAvalSC6("SC6",1,"SC5",lLiber,lTransf,@lLiberOk,@lResidOk,@lFaturOk,,,,,,lTLVReg)
						
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Verifica se houve bloqueio por regra ou verba.³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If SC6->C6_BLOQUEI == "01"
							lBlqRegra := .T.
						ElseIf SC6->C6_BLOQUEI == "02"
							lBlqVerba := .T.
						EndIf
			
						If (lOpFat .OR. lOpRem) .And. (!lBlqRegra .And. !lBlqVerba)
							/*
							ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							³Parametros³ExpN1: Registro do SC6                                      ³  
							³          ³ExpN2: Quantidade a Liberar                                 ³  
							³          ³ExpL3: Bloqueio de Credito                                  ³   
							³          ³ExpL4: Bloqueio de Estoque                                  ³  
							³          ³ExpL5: Avaliacao de Credito                                 ³  
							³          ³ExpL6: Avaliacao de Estoque                                 ³  
							³          ³ExpL7: Permite Liberacao Parcial                            ³  
							³          ³ExpL8: Tranfere Locais automaticamente                      ³  
							³          ³ExpA9: Empenhos ( Caso seja informado nao efetua a gravacao ³  
							³          ³       apenas avalia ).                                     ³  
							³          ³ExpbA: CodBlock a ser avaliado na gravacao do SC9           ³  
							³          ³ExpAB: Array com Empenhos previamente escolhidos            ³  
							³          ³       (impede selecao dos empenhos pelas rotinas)          ³  
							³          ³ExpLC: Indica se apenas esta trocando lotes do SC9          ³  
							³          ³ExpND: Valor a ser adicionado ao limite de credito          ³  
							³          ³ExpNE: Quantidade a Liberar - segunda UM                    ³  
							ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							*/
							/*
							  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						 	  ³Para geracao do SC9 informa-se o total de itens a ser LIBERADO.³
							  ³Exemplo:                                                       ³
							  ³                                                               ³
							  ³Vendido        Liberado             - Liberacao Parcial        ³
							  ³100                 50                                         ³
							  ³                                                               ³
							  ³Vendido        Liberado             - Liberacao Total          ³
							  ³100                 100                                        ³
							  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							*/
							
							MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDLIB,lBloqCre,lAvalEst,lAvalCre,lAvalEst,.T.,.T.,NIL,NIL,NIL,NIL,NIL,0)
							If lSigaCrd	 .AND. lConfCRD
								a450Grava(1,.T.,.F.) //Forcar a liberacao do SC9
							ElseIf lUsaTef .AND. lTefOk
								a450Grava(1,.T.,.T.) //Forcar a liberacao do SC9														
							Endif	
						Endif
					Endif
				
				Else

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Executa o ponto de Entrada TMKVPED e substitui a gravacao do SC5/SC6 ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If lTMKVPED
						If nX == Len(aCols)
							U_TMKVPED(M->UA_NUM)
							lRet := .T.
						Endif	
					Endif
									
				Endif
            Endif

			//Se a linha atual nao estiver deletada grava no SUB e a gravacao foi feita pelo padrao
			If !aCols[nX][Len(aHeader)+1] .AND. (!lTMKVPED)		
				DbSelectArea("SUB")
				DbSetOrder(1)
				If DbSeek(xFilial("SUB")+M->UA_NUM+aCols[nX][nPItem])
					RecLock("SUB",.F.)
					Replace SUB->UB_NUMPV  With cNumSC5
					Replace SUB->UB_ITEMPV With aCols[nX][nPItem]
				Endif
			Endif
		
		END TRANSACTION
	
	Next nX	

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Aviso de bloqueio por regra ou verba.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lBlqRegra
		Help("  ",1,"TMKBLQREG")
	ElseIf lBlqVerba
		Help("  ",1,"TMKBLQVER")
	EndIf    
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a gravacao dos lancamentos do SIGAPCO            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PcoFinLan("000100")
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Executa a transacao 2 - de confirmacao dos dados e impressao do comprovante apenas na operacao FATURAMENTO.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lConfCRD
	    Conout(STR0037 +;                 //"13.TMKA273D Entrou na confirmacao da transacao "
	    		STR0038 + If( Empty(cContrato),"", cContrato) )		//"Contrato: "
	    		
		aRetCrd:= Tk273AvalCred( "2",		.T.      	, aParcelas,	aValores[BASEDUP]  ,;
		                         nVlJur,	cMV_CRDAVAL , .F. )        
		                         
		If aRetCrd[1] <> 0 //Confirmacao nao esta ok.
	        Conout(STR0039 +;			//"14.TMKA273D Nao Confirmacao "
	        		If(Empty(cContrato),"", cContrato) )		
	        		
    		aRetCrd    := aClone(CrdxVenda( "3", {"",""}, cContrato, .F., Nil))     		   
	 	Endif

		//Limpa as variaveis staticas de controle
		Tk273SetCred()	            

	Endif
	
	If lSigaCRD .AND. lTesTit .AND. !lProspect	
	   //Se confirmou a transacao de avaliacao, deve inicializar os arquivos do SIGACRD	     
	   If lConfCRD
	      lGravaDoc  := .F.
	   ElseIf Val(M->UA_OPER) == ORCAMENTO
	      //Se for gravacao de orcamento e tiver alguma parcela para analise de credito, nao inicializa os arquivos do SIGACRD
	      For nX := 1 to Len(aParcelas)
             If AllTrim(aParcelas[nX][3]) $ cMV_FormCRD
                lGravaDoc  := .T.
             Endif
          Next nX   
       EndIf  
	   Conout("15.TMKA273D - Tk273GrvTel - " +;
	   			STR0029 + M->UA_NUM +;		//" Orcamento: "
	   			STR0040 )      //" Chama a funcao Tk273AtuPen para cancelar o contrato "
	   	         
	   //Cancela contrato que nao gerou orcamento nem venda.        
	   //Nao precisa perguntar se deseja cancelar o contrato na gravacao. Se nao estiver associado ao SUA, cancela
	   Tk273AtuPen( lSigaCRD   ,.F.    ,lGravaDoc  ,.F.   )
    Else
    	Conout("16.TMKA273D - Tk273GrvTel - " +;
    			STR0029 + M->UA_NUM +;			//" Orcamento: "
    			STR0041 )		//"Nao fez a Chamada da funcao Tk273AtuPen "
    Endif    

	If (!lTMKVPED) .OR. (Val(M->UA_OPER) <> FATURAMENTO)
		// Atualiza os acumulados do SC5
		If !Empty(cNumSc5)
			MaAvalSC5("SC5",1,lLiber,lTransf,@lLiberOk,@lResidOk,@lFaturOk)		
			SC5->(MsUnLock())
		Endif
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se for gerar NF   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (lOpfat .OR. lOpRem) .And. (!lBlqRegra .And. !lBlqVerba)
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Realizar um backup da situacao atual da funcao fiscal antes de realizar        ³
			//³a geracao da nota. Depois a mesma sera restaurada exatamente na situacao       ³
			//³a qual ela se encontrava. Isto evita problemas na exibicao de valores no rodape³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MafisSave()	    
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Ponto de Entrada apos a gravacao do SC5/SC6 e antes da Geracao da Nota ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lTMKVPV
				U_TMKVPV(M->UA_NUM,cNumSC5)
			Endif
			
			TkGeraNF(3,aPedido,cAdm,aParcelas)

			MaFisRestore()		

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualizacao de Cheques ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			For nContSEF := 1 To Len (aParcelas)
				If "CH" $ Trim(aParcelas[nContSEF][3])
					nCheques ++
				Endif
			Next nContSEF
	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se Gera Duplicata grava SEF. Nao existe SEF sem SE1.³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
			If SF4->F4_DUPLIC = "S" // Posicionado na funcao TkGeraNF
				If nCheques > 0
					For nContSEF := 1 TO Len(aParcelas)
						
						If "CH" $ Trim(aParcelas[nContSEF][3])
							j:=j+1
								
							cBanco			  := Substr(aParcelas[nContSEF][4],1,3  )
							cNumCheque		  := Substr(aParcelas[nContSEF][4],19,15)
							cAgencia 		  := Substr(aParcelas[nContSEF][4],4,5  )
							cConta			  := Substr(aParcelas[nContSEF][4],9,10 )
							cRG				  := Substr(aParcelas[nContSEF][4],34,14)
							cTelefone		  := Substr(aParcelas[nContSEF][4],48,15)
							nValorCheque 	  := aParcelas[nContSEF][2]
							dDataVencto  	  := aParcelas[nContSEF][1]
							
							Reclock( "SEF" , .T. )
							REPLACE SEF->EF_FILIAL  	 WITH xFilial("SEF")
							REPLACE SEF->EF_NUM			 WITH cNumCheque
							REPLACE SEF->EF_BANCO	     WITH cBanco
							REPLACE SEF->EF_AGENCIA 	 WITH cAgencia
							REPLACE SEF->EF_CONTA	     WITH cConta
							REPLACE SEF->EF_VALOR	     WITH nValorCheque
							REPLACE SEF->EF_DATA	     WITH dDataBase
							REPLACE SEF->EF_VENCTO		 WITH dDataVencto
							REPLACE SEF->EF_BENEF	  	 WITH SM0->M0_NOMECOM
							REPLACE SEF->EF_CART		 WITH "R"
							REPLACE SEF->EF_TEL			 WITH cTelefone
							REPLACE SEF->EF_RG		     WITH cRG
							REPLACE SEF->EF_NUMNOTA 	 WITH SUA->UA_DOC   //SUA esta sendo posicionado no TmkxFat Funcao TkGeraNf
							REPLACE SEF->EF_SERIE	     WITH SUA->UA_SERIE  // Serie é remontado abaixo 
							REPLACE SEF->EF_TITULO   	 WITH SE1->E1_NUM
							REPLACE SEF->EF_PREFIXO	     WITH SE1->E1_PREFIXO  
							REPLACE SEF->EF_TIPO	     WITH SE1->E1_TIPO
							REPLACE SEF->EF_TERCEIR 	 WITH .F.
							REPLACE SEF->EF_HIST	     WITH ""   		  // PARA RDMAKE
							REPLACE SEF->EF_PARCELA  	 WITH SE1->E1_PARCELA
							REPLACE SEF->EF_CLIENTE	     WITH SUA->UA_CLIENTE
							REPLACE SEF->EF_LOJACLI	     WITH SUA->UA_LOJA	
							If cPaisLoc == "BRA"
								REPLACE SEF->EF_GARANT		WITH cGaranCh  //para uso de TEF
							Endif
						    SerieNfId ("SEF",1,"EF_SERIE",,,,SUA->UA_SERIE)
						    SEF->( dbCommit())
							MsUnlock()
						Endif
					Next nContSEF
				Endif
		    Endif

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualiza o campo E1_NUMCRD e exclui os registros de ³
			//³ parcelas de financiamento(MAL). (SIGACRD)           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 			If lSigaCRD	.And. lTesTit .And. !lProspect .And. lConfCRD
				If !Empty(SUA->UA_CONTRA)
	 				dbSelectArea("SE1")
	 				dbSetOrder(1)
	 				SE1->(dbSeek(xFilial("SE1")+SUA->UA_SERIE+SUA->UA_DOC))
					While !Eof() .And. xFilial("SE1")+SUA->UA_SERIE+SUA->UA_DOC == SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM
				  		RecLock("SE1",.F.)
					 	REPLACE SE1->E1_NUMCRD WITH SUA->UA_CONTRA
					  	SE1->(MsUnlock())	
					  	SE1->(dbSkip())
					EndDo

					dbSelectArea("MAL")
					dbSetOrder(1)
					MAL->(dbSeek(xFilial("MAL")+SUA->UA_CONTRA))
					While !Eof() .And. xFilial("MAL")+SUA->UA_CONTRA == MAL->MAL_FILIAL+MAL->MAL_CONTRA
						Reclock("MAL",.F.)
						MAL->(dbDelete())
						MAL->(MsUnlock())
						MAL->(dbSkip())
					EndDo	
				EndIf
            EndIf		

		// Verifico se o cliente usa o SIGALOJA junto com o SIGATMK
		ElseIf (Val(M->UA_OPER) == ORCAMENTO)
			// Se o atendimento for uma inclusao e o parametro MV_TMKLOJ for "S"
			If (nOpc == 3) 
				If (cTmkLoj == "S")
					Tk273GrvLoja(nOpc			,aParcelas	,@cNumSL1		,cAdm		,;
								 cTipoCli		,cCodPagto	,nFinanciado	,nTxJuros	,;
								 nNumParcelas	,nValidade	,nEntrada)	
									 
				Endif
			Endif
				
			// Se o atendimento for uma alteracao e o parametro MV_TMKALOJ for "S"
			If nOpc == 4
				If Empty(cNumSL1)
					If (cTmkLoj == "S") 
						Tk273GrvLoja(3				,aParcelas	,@cNumSL1		,cAdm		,;
									 cTipoCli		,cCodPagto	,nFinanciado	,nTxJuros	,;
									 nNumParcelas	,nValidade	,nEntrada)	
					Endif				 
				Else
					If (cTmkaLoj == "S")
						//Se encontrou o orcamento e ele ja NAO foi recebido procede a alteracao
						DbSelectArea("SL1")
						DbSetOrder(1)
						If DbSeek(xFilial("SL1") + cNumSL1) .AND. Empty(SL1->L1_DOC)
							Tk273GrvLoja(4				,aParcelas	,cNumSL1		,cAdm		,;
										 cTipoCli		,cCodPagto	,nFinanciado	,nTxJuros	,;
										 nNumParcelas	,nValidade	,nEntrada)	
	
						Endif
					Endif	
				Endif
			Endif
		ElseIf (Val(M->UA_OPER) == ATENDIMENTO) .And. nOpc == 4 .And. (nOpAnt == ORCAMENTO) .And. cTmkLoj == "S"
				Tk273DelLoj(nOpc,cNumSL1) 
		Endif
				
			
		// Atualiza o historico do televendas
		If lProspect
				
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Gravo no hist¢rio do prospect o contato, a data, a observa‡„o e a origem(TMK)³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("SUS")
			DbSetOrder(1)
			If DbSeek(xFilial("SUS") + M->UA_CLIENTE + M->UA_LOJA)
				Reclock("SUS",.F.)
				If Empty(SUS->US_CODHIST)
					// Se ainda n„o existe historico gravado para esse prospect fa‡o uma inclusao
					cHistlv := DTOC(M->UA_EMISSAO)+STR0008 + CRLF //"-TeleMarketing-"
					cHistlv += IF(Empty(M->UA_OBS),"",M->UA_OBS + CRLF) 
					MSMM(,nTamUS_HISTMK,,cHistlv,1,,,"SUS","US_CODHIST")
				Else
					// Se ja existe historico atualizo com o SUS+SUA atual
	   	    	    cHisTlv	+= MSMM(SUS->US_CODHIST,35)//Carrego o historico acumulado da entidade antes de inserir o novo
					cHistlv += DTOC(M->UA_EMISSAO)+STR0008 + CRLF //"-TeleMarketing-"
					cHistlv += IF(Empty(M->UA_OBS),"",M->UA_OBS + CRLF)
					MSMM(SUS->US_CODHIST,nTamUS_HISTMK,,cHistlv,1,,,"SUS","US_CODHIST")
				Endif
				MsUnlock()
				Dbcommit()
			Endif
				
		Else
				
	 		// Gravo no hist¢rio do cliente o contato, a data, a observa‡ao e a origem(TELEVENDAS)
	 		DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1") + M->UA_CLIENTE + M->UA_LOJA)
				Reclock("SA1",.F.)
				If Empty(SA1->A1_CODHIST)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se ainda n„o existe historico gravado para esse cliente fa‡o uma inclus„o ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					cHistlv := DTOC(M->UA_EMISSAO)+STR0009 + CRLF  //"-TeleVendas-"
					cHistlv += IF(Empty(M->UA_OBS),"",M->UA_OBS + CRLF)
					MSMM(,nTamA1_HISTMK,,cHistlv,1,,,"SA1","A1_CODHIST")
				Else
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Se ja existe historico atualizo com o SA1+SUA atual  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					cHistlv += DTOC(M->UA_EMISSAO)+STR0009 + CRLF //"-TeleVendas-"
					cHistlv += IF(Empty(M->UA_OBS),"",M->UA_OBS + CRLF)
					MSMM(SA1->A1_CODHIST,nTamA1_HISTMK,,cHistlv,1,,,"SA1","A1_CODHIST",,.T.)
				Endif
				MsUnlock()
			Endif
		Endif
	    
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Atualiza a data do ultimo contato.  SU5.                       ³
		//³Para que possam ser geradas listas por ultimo contato todas as ³
		//³interacoes devem atualizar a data do ultimo contato no cadastro³
		//³de Contatos.                                                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	    If !Empty(M->UA_CODCONT)
	    	DbSelectArea("SU5")
			DbSetOrder(1)
			If DbSeek(xFilial("SU5") + M->UA_CODCONT)
				Reclock("SU5",.F.)
				Replace SU5->U5_ULTCONT With M->UA_EMISSAO
				MsUnlock()			
			Endif
		Endif    
	    
	    // Gravacao efetuada com sucesso
		lRet := .T.
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Ponto de Entrada para uso exclusivo de Templates³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lTMKVFIMT
			T_TMKVFIM(M->UA_NUM,cNumSC5)
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Executa o ponto de Entrada TMKVFIM apos a gravacao do SC5/SC6 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lTMKVFIM
			U_TMKVFIM(M->UA_NUM,cNumSC5)
		Endif
	
		If Val(M->UA_OPER) == FATURAMENTO
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³O relatorio de Pedido nao podera ser executado na entrada automatica  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Ponto de Entrada para uso em Templates									³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lTMKR03T
					uPorPrograma := .T.
					T_TMKR03(M->UA_NUM)
				Endif
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³O Relat¢rio de Pedido ‚ executado a partir de um RDMAKE ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lTMKR03
					uPorPrograma := .T.
					U_TMKR03(M->UA_NUM)
				Endif
			Endif
				
		ElseIf Val(M->UA_OPER) == ORCAMENTO
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³O relatorio de Orcamento nao podera ser executado na entrada automatica ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lTk271Auto
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Ponto de Entrada para uso exclusivo de Templates³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lTMKR3AT
					uPorPrograma := .T.
					T_TMKR3A(M->UA_NUM)
				Endif
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³O Relat¢rio de Orcam. ‚ executado a partir de um RDMAKE ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lTMKR3A
					uPorPrograma := .T.
					U_TMKR3A(M->UA_NUM)
				Endif
			Endif 
		Endif 
	Endif 
Endif

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³Tk271GrvLoja ³ Autor ³ Vendas Clientes     ³ Data ³05/04/01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Grava os dados do Or‡amento no SL1/SL2 do SIGALOJA          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ TeleVendas                                                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Tk273GrvLoja(nOpc			,aParcelas		,cNumSL1		,cAdm		,;
							 cTipoCli		,cCodPagto		,nFinanciado	,nTxJuros	,;
							 nNumParcelas	,nValidade		,nEntrada)



Local aArea		:= GetArea()		// Salva a area atual
Local nX 		:= 0 				// Contador
Local nDin		:= 0                // Montante em dinheiro
Local nCar		:= 0				// Montante em cartao
Local nChe		:= 0                // Montante em cheque
Local nFin		:= 0				// Montante em financiamento
Local nVal		:= 0				// Montante em vales
Local nOut		:= 0                // Montante em outros
Local nCon		:= 0                // Montante em cobranca
Local cMay      := ""               // Variavel auxiliar
Local lNovo 	:= .F.				// Flag para novo registro (Inclusao/Alteracao)
Local cI 		:= "00"				// Contador de Linhas percorridas
Local cNovoItem := "00"				// Linhas incluidas
Local cDesc 	:= ""				// Descricao do produto

Local nPProd    := aPosicoes[1][2]	// Produto
Local nPQtd     := aPosicoes[4][2]  // Quantidade
Local nPVrUnit  := aPosicoes[5][2]  // Valor unitario
Local nPVlrItem	:= aPosicoes[6][2]  // Valor do item
Local nPLocal   := aPosicoes[7][2]  // Local
Local nPUm	    := aPosicoes[8][2]  // Unidade
Local nPDesc	:= aPosicoes[9][2]  // Desconto %
Local nPValDesc := aPosicoes[10][2] // Valor do Desconto
Local nPAcre 	:= aPosicoes[13][2] // Valor do Desconto
Local nPValAcre := aPosicoes[14][2] // Valor do Desconto
Local nPTes	    := aPosicoes[11][2] // TES
Local nPCf		:= aPosicoes[12][2] // CFO
Local nPPrcTab	:= aPosicoes[15][2] // Preco de tabela
Local nLoteCTL  := aPosicoes[17][2]	// Lote 
Local nSubLote  := aPosicoes[18][2]	// Sub Lote
Local nQtd		:= 0				// Quantidade no item na linha
Local nDesc		:= 0				// Porcentagem do desconto no item
Local nValDesc	:= 0				// Valor do desconto no item
Local nAcre		:= 0				// Porcentagem do acréscimo no item
Local nValAcre	:= 0				// Valor do acréscimo no item
Local nPrcTab	:= 0				// Valor de tabela no item
Local nVrUnit	:= 0				// Valor unitário no item
Local nVlrItem	:= 0				// Valor no item
Local cLote		:= ""   			// Numero de Lote 
Local cSubLote	:= ""   			// Numero de Sub Lote 
Local lGravOrc	:= .T.			// Permite Gravar orcamento.
Local lGravPE	:= .T.			// Retorno do PE com a permição para gravação do orcamento.
Local lTK273GORC := ExistBlock("TK273GORC") // Valida existencia de ponto de entrada
Local lTamCsDec  := If ( SuperGetMV("MV_TMKLOJ",,.F. )== "S" .AND. SuperGetMv( "MV_LJTPDES", , 0 ) == 2 ,.T.,.F. )  // Verifica se tem Integracao com o loja e se o vai usar uma regra de desconto diferente do TMK
Local cMvArreFat := SuperGetMV( "MV_ARREFAT",,"N" )
Local aSequencia := {}  
Local nTamOrc 	 := 0
Local lFisNota	 := SuperGetMV("MV_FISNOTA",,.F.)	//Utiliza emissao de NF
Local lUsaNF 	 := .F.
Local nTotIPI	 := IIf(MaFisFound("NF"),MaFisRet(,"NF_VALIPI"),0)
Local nValSoma	 := 0 
Local nSomaVlMer := 0

For nX := 1 To Len(aParcelas)
	Do Case
		Case AllTrim(aParcelas[nX][3]) == "R$" .Or. AllTrim(aParcelas[nX][3]) == "$" 
			nDin += aParcelas[nX][2]
			
		Case AllTrim(aParcelas[nX][3]) == "CC"
			nCar += aParcelas[nX][2]
			
		Case AllTrim(aParcelas[nX][3]) == "CH"
			nChe += aParcelas[nX][2]
			
		Case AllTrim(aParcelas[nX][3]) == "FI"
			nFin += aParcelas[nX][2]
			
		Case AllTrim(aParcelas[nX][3]) == "VA"
			nVal += aParcelas[nX][2]
			
		Case AllTrim(aParcelas[nX][3]) == "CO"
			nCon += aParcelas[nX][2]
			
		OtherWise
			nOut += aParcelas[nX][2]
	EndCase
Next nX

If lTK273GORC
	lGravPE  := ExecBlock("TK273GORC",.F.,.F.,{nOpc,aParcelas})
	lGravOrc	:= IIf(ValType(lGravPE) <> "L",lGravOrc,lGravPE)
EndIf

If lGravOrc              

	DbSelectArea("SB1")
	DbSetOrder(1)
	
	Do Case
		Case nOpc == 3  // INCLUSAO
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se ‚ um novo pedido gero os registros no SC5,SC6 e SC9       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("SL1")
			DbSetOrder(1)
			cNumSL1 := GetSxeNum("SL1","L1_NUM")
					
			aSequencia := {}
			If LjNfPafEcf(SM0->M0_CGC) 				
				nTamOrc		:= TamSX3("LQ_NUMORC")[1] 
				If SuperGetMv("MV_LJPRVEN",,.T.)
					LjxDNota(	SuperGetMv("MV_LJSERPRE",,"PRE")	, 1				, .T.	, 1		,;
								@aSequencia							, Space(nTamOrc), nil	, 1		,;
								999									, .F.			, ""	, Nil	,;
								nTamOrc								, .T. )           
				Else                                                                  
					LjxDNota(	SuperGetMv("MV_LJSERDAV",,"DAV")	, 1				, .T.	, 1		,;
								@aSequencia							, Space(nTamOrc), nil	, 1		,;
								999									, .F.			, ""	, Nil	,;
								nTamOrc								, .T. )
				EndIf
			EndIf
	    
			cMay := "SL1" + ALLTRIM(xFilial("SL1")) + cNumSL1
			While (DbSeek(xFilial("SL1") + cNumSL1) .OR. !MayIUseCode(cMay))
				cNumSL1 := Soma1(cNumSL1,Len(cNumSL1))
				cMay 	:= "SL1" + ALLTRIM(xFilial("SL1"))+cNumSL1
			End
			
			If __lSX8
				ConfirmSX8()
			Endif
			lNovo := .T.
	
		Case nOpc == 4 //ALTERACAO
	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Apaga os items da forma de pagamento do SL4         ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("SL4")
			DbSetOrder(1)
			If DbSeek(xFilial("SL4") + cNumSL1 +"")  //Nao preenche a ORIGEM porque e um ORCAMENTO DO SIGALOJA
				While !Eof() 						   .AND. ;
					(SL4->L4_FILIAL == xFilial("SL4")) .AND. ;
					(SL4->L4_NUM == cNumSL1) 		   .AND. ;
					(ALLTRIM(SL4->L4_ORIGEM) == "")
					
					RecLock("SL4",.F.,.T.)
					DbDelete()
					MsUnlock()
					SL4->(DbSkip())
				End
			Endif
	
			//Posiciona no orcamento correto
			DbSelectArea( "SL1" )
			DbSetOrder(1)
			DbSeek(xFilial("SL1") + cNumSL1)
	EndCase
	
	BEGIN TRANSACTION
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Inicia a gravacao do SUA/SC5/SUB/SC6 - Atendimento e Pedido                                                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nX := 1 TO Len(aCols)
		
			//Grava o cabecalho do TELEVENDAS
			If nX == 1
		
				Reclock( "SL1",lNovo)
				REPLACE L1_FILIAL  WITH  xFilial("SL1")
				REPLACE L1_NUM	   WITH  cNumSL1
				REPLACE L1_CLIENTE WITH  M->UA_CLIENTE
				REPLACE L1_EMISSAO WITH  M->UA_EMISSAO             
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Informações detalhadas dos campos que tratam valores no³
				//³SL1, SL2, SD1, SD2, podem ser encontradas no portal    ³
				//³Athenas com o tópico "Gravação da venda".              ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		  		REPLACE L1_VLRLIQ  WITH  A410Arred (aValores[BASEDUP], "L1_VLRLIQ" ) 
				REPLACE L1_VALBRUT WITH  A410Arred (aValores[BASEDUP], "L1_VALBRUT" ) 
				REPLACE L1_VLRTOT  WITH  A410Arred (aValores[TOTAL], "L1_VLRTOT" )
				REPLACE L1_VALMERC WITH  A410Arred (aValores[MERCADORIA], "L1_VALMERC" ) 			
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se houver desconto precisa gravar o valor "1" no campo³
				//³L1_TIPODES para que o desconto seja calculado         ³
				//³corretamente.                                         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If aValores[DESCONTO] > 0
					REPLACE L1_DESCONT WITH  A410Arred (aValores[DESCONTO], "L1_DESCONT" ) 
					REPLACE L1_TIPODES WITH "1"
				EndIf
				
				REPLACE L1_DTLIM   WITH  dDataBase+nValidade
				REPLACE L1_LOJA    WITH  M->UA_LOJA
				REPLACE L1_VEND    WITH  M->UA_VEND
				REPLACE L1_COMIS   WITH  SUA->UA_COMIS
				REPLACE L1_TIPOCLI WITH  cTipoCli
				REPLACE L1_DINHEIR WITH  nDin
				REPLACE L1_CHEQUES WITH  nChe
				REPLACE L1_CARTAO  WITH  nCar
				REPLACE L1_CONVENI WITH  nCon
				REPLACE L1_VALES   WITH  nVal
				REPLACE L1_FINANC  WITH  nFin
				REPLACE L1_OUTROS  WITH  nOut
				REPLACE L1_COND    WITH  0
				REPLACE L1_CONDPG  WITH  cCodPagto
				REPLACE L1_FORMPG  WITH  If(Len(aParcelas)>0,aParcelas[Len(aParcelas),3],"")
				REPLACE L1_FORMA   WITH  Len(aParcelas)
				REPLACE L1_ENTRADA WITH  nEntrada
				REPLACE L1_PARCELA WITH  Len(aParcelas)
				REPLACE L1_FINANC  WITH  nFinanciado
				REPLACE L1_JUROS   WITH  nTxJuros
				REPLACE L1_PARCELA WITH  nNumParcelas
				REPLACE L1_IMPRIME WITH  "1N"
				REPLACE L1_FRETE   WITH  aValores[FRETE]
				REPLACE L1_TPFRET  WITH  M->UA_TPFRETE
				REPLACE L1_TRANSP  WITH  M->UA_TRANSP
				REPLACE L1_MOEDA   WITH  M->UA_MOEDA
				REPLACE L1_DESPESA WITH	 aValores[DESPESA]				
				REPLACE L1_NUMATEN WITH SUA->UA_NUM
	
				If Empty(SL1->L1_VEND)
					REPLACE L1_VEND WITH SuperGetMv("MV_VENDPAD")			
				EndIf
				If Len(aSequencia) > 0
					REPLACE L1_NUMORC WITH aSequencia[1][2]
					REPLACE L1_TPORC  WITH aSequencia[1][1]
				EndIf
				
				SA1->(DbSetOrder(1))
				If ( SA1->(DbSeek(xfilial("SA1")+ M->UA_CLIENTE + M->UA_LOJA)))					
					lUsaNF := LjNFFimVd(.T. , NIL, NIL , SA1->A1_EST , SA1->A1_PESSOA)	  
				EndIf
				
				//Força a gravação do IMPNF para .T. quando o produto possuir IPI, para que seja finalizado no Venda Assistida como nota.
				If (lUsaNF .And. lFisNota) .Or. nTotIPI > 0
					REPLACE L1_IMPNF WITH .T.
					If nTotIPI > 0	
						REPLACE L1_VALIPI WITH nTotIPI
					EndIf
				EndIf
						
				FkCommit()
		
				DbSelectArea("SUA")
				Reclock("SUA",.F.)
				Replace UA_NUMSL1 With cNumSL1
				MsUnlock()
				Dbcommit()
			Endif
				                             
			// Verifica os itens que foram excluidos do Acols e que foram incluidos - Atendimento (SUB)
			cI := SomaIt(cI)
	
			//Se a linha foi apagada - apaga da Base de dados
			If aCols[nx][Len(aHeader)+1]	
				DbSelectArea("SL2")
				DbSetOrder(1)
				If DbSeek(xFilial("SL2") + cNumSL1 + cI)
					Reclock("SL2",.F.,.T.)
					DbDelete()
					MsUnlock()
				Endif    
				
			ElseIf !Empty(aCols[nX][nPProd])
				//Se o item e valido grava no SUB - verifica se e novo ou nao
				cNovoItem := SomaIt(cNovoItem)                               
		
				DbSelectArea("SL2")
				DbSetOrder(1)
				If DbSeek(xFilial("SL2") + cNumSL1 + cI)
					lNovo := .F.
				Else
					lNovo := .T.
				Endif
	
				cDesc := ""
				If SB1->( DbSeek(xFilial("SB1") + aCols[nX][nPProd] ))	
					cDesc := SB1->B1_DESC
				Endif	
			
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Verifica a utilização dos descontos, acréscimos e se foi³
				//³digitado manualmente o preço unitário do produto.       ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nQtd	:= aCols[nX][nPQtd]
				nDesc	:= aCols[nX][nPDesc]			
				nValDesc:= A410Arred(aCols[nX][nPPrcTab]*aCols[nX][nPDesc]/100,"L2_VALDESC")
				nAcre	:= aCols[nX][nPAcre]
				nValAcre:= aCols[nX][nPValAcre]
				nPrcTab	:= aCols[nX][nPPrcTab]
				If (M->UA_DESC1+M->UA_DESC2+M->UA_DESC3+M->UA_DESC4) > 0
					nVrUnit	 := A410Arred(nPrcTab - nValDesc, "L2_VRUNIT" )
					nVlrItem := A410Arred (nQtd * nVrUnit, "L2_VLRITEM" )
				Else
		   			nVrUnit	 := A410Arred (aCols[nX][nPVrunit], "L2_VRUNIT" )
					nVlrItem := A410Arred (aCols[nX][nPVlrItem], "L2_VLRITEM" )
				EndIf								
				cLote   	:= aCols[nX][nLoteCTL]  
				cSubLote	:= aCols[nX][nSubLote]  
				nValSoma 	+= nVlrItem
				nSomaVlMer 	+= (nQtd * nPrcTab)
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se houver acréscimo:                                        ³
				//³- Adiciona o acréscimo no preço unitário, e na tabela.      ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If nAcre > 0
					nPrcTab	:= nVrUnit
					nDesc	:= 0
					nValDesc:= 0
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se não houver nem desconto, nem acréscimo:                    ³
				//³- Utiliza o preço unitário como o preço da tabela, pois caso o³
				//³usuário altere o preço unitário manualmente, sem dar desconto,³
				//³o SIGALOJA calcula corretamente.                              ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				ElseIf nDesc == 0 .AND. nAcre == 0
					nPrcTab	:= nVrUnit				
				EndIf
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se o preço unitário estiver diferente do preço do item recalcula    ³
				//³o preço do item. (Caso o usuário digite manualmente o preço unitário³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ( nVrUnit * nQtd ) <> nVlrItem
					nVlrItem := ( nVrUnit * nQtd )
				EndIf
			    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Acerto o valor unitario para 2 casas decimis pois ao finalizar no   ³
				//³Ecf no  Sigaloja ocorre diferenca³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			    If lTamCsDec
			    	If cMvArreFat == "S"
						nVlrItem  := Round (nVlrItem, nDecimais)	  
						nValDesc  := Round (nValDesc, nDecimais)	      	
			    	Else
			    		nVlrItem  := NoRound (nVlrItem, nDecimais)         
			    		nValDesc  := NoRound (nValDesc, nDecimais)	      	  
			    	EndIf
			    End 
				DbSelectArea("SL2")
				Reclock( "SL2",lNovo)  // Grava SUB
				Replace L2_NUM	   With cNumSL1
				Replace L2_FILIAL  With xFilial("SL2")
				Replace L2_PRODUTO With aCols[nX][nPProd]
				Replace L2_DESCRI  With cDesc
				Replace L2_ITEM	   With cNovoItem
				Replace L2_QUANT   With aCols[nX][nPQtd]
				Replace L2_VRUNIT  With nVrUnit
				Replace L2_VLRITEM With nVlrItem
				Replace L2_LOCAL   With aCols[nX][nPLocal]
				Replace L2_UM	   With aCols[nX][nPUm]
				Replace L2_DESC	   With nDesc
				Replace L2_VALDESC With aCols[nX][nPValDesc]
				Replace L2_TES	   With aCols[nX][nPTes]
				Replace L2_CF	   With aCols[nX][nPCf]
				Replace L2_TABELA  With M->UA_TABELA
				Replace L2_EMISSAO With M->UA_EMISSAO
				Replace L2_PRCTAB  With nPrcTab
				Replace L2_LOTECTL With cLote
				Replace L2_NLOTE   With	cSubLote
				If (lUsaNF .And. lFisNota) .Or. nTotIPI > 0
					If nTotIPI > 0
						Replace L2_VALIPI With MaFisRet(nX,'IT_VALIPI')
					EndIf
				EndIf
				
			Endif
	
		Next nX

		Reclock( "SL1",.F.)
		REPLACE L1_VALMERC WITH A410Arred (nSomaVlMer, "L1_VALMERC" )
		REPLACE L1_DESCNF WITH  A410Arred ((aValores[DESCONTO] * 100)/nValSoma, "L1_DESCONT" ) + A410Arred (M->UA_DESC1+M->UA_DESC2+M->UA_DESC3+M->UA_DESC4, "L1_DESCONT" )
		REPLACE L1_DESCONT WITH  A410Arred ((nValSoma * L1_DESCNF)/100, "L1_DESCNF" ) 
		If !Empty(L1_DESCONT) .And. Empty(L1_TIPODES)
			REPLACE L1_TIPODES WITH "1"
		EndIf
		SL1->(MsUnlock())
				
		// Grava informacoes do arquivo de forma de pagamento
		For nX := 1 TO Len(aParcelas)
			Reclock("SL4",.T.)
			Replace L4_NUM	  With cNumSL1
			Replace L4_FILIAL With xFilial("SL4")
			Replace L4_DATA   With aParcelas[nX][1]
			Replace L4_VALOR  With aParcelas[nX][2]
			Replace L4_FORMA  With aParcelas[nX][3]
			Replace L4_OBS    With aParcelas[nX][4]
			Replace L4_ORIGEM With ""
			Replace L4_ADMINIS With IF(!Empty(cAdm),cAdm," ")
			If aParcelas[nX][5] > 0
				Replace L4_COMP With STR(aParcelas[nX][5],3,0)
			Endif
			MsUnlock()
			Dbcommit()
		Next nX
	
	END TRANSACTION
EndIf

RestArea(aArea)
			
Return(.T.)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³Tk273Bonus³ Autor ³ Vendas Clientes       ³ Data ³25/03/2002³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Rotina de tratamento da regra de bonificacao para interface ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1: Tipo de operacao                                     ³±±
±±³          ³       [1] Inclusao de bonus                                ³±±
±±³          ³       [2] Leitura de bonus                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina tem como objetivo avaliar a regra de bonificacao³±±
±±³          ³e adicionar na respectiva interface                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Televendas            			                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Tk273Bonus(nTipo)

Local aArea     := GetArea()				// Salva a area atual
Local aBonus    := {}						// Array contendo os itens que serao bonificados - adicionados ao pedido
Local nAux      := 0						// Contador auxiliar	
Local nTotal    := 0						// Contador do total de itens de bonus 
Local nCol		:= 0 						// Contador das colunas
Local nLinha    := Len(aCols)				// Contador do total de linhas adicionadas
Local nCont	    := 0          				// Contador de Linhas do Acols
Local nUsado    := Len(aHeader)				// Total de campos (colunas)	
Local nPProd    := aPosicoes[1][2]			// Posicao do Produto
Local nPDescri  := aPosicoes[2][2]			// Posicao da descricao
Local nPSitProd := aPosicoes[3][2]			// Posicao da Situacao do Produto
Local nPQtd     := aPosicoes[4][2]  		// Posicao da Quantidade	
Local nPVrUnit  := aPosicoes[5][2]			// Posicao do Valor unitario
Local nPLocal   := aPosicoes[7][2]			// Posicao do Local (Estoque)
Local nPUm	    := aPosicoes[8][2]			// Posicao da Unidade de Medida
Local nPTES	    := aPosicoes[11][2]			// Posicao do TES	
Local nPCf		:= aPosicoes[12][2]			// Posicao do CFO
Local nPItem	:= aPosicoes[20][2]			// Posicao do número do item
Local cItem		:= "01"						// Número do item a ser adicionado					
Local cEstado   := SuperGetMv("MV_ESTADO")	// Estado da empresa atual
Local cFormPg		:= Space(Len(ACO->ACO_FORMPG))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica os bonus                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nTipo == 1
	If !Empty(M->UA_CONDPG)
		cFormPg := Posicione("SE4",1,xFilial("SE4") + M->UA_CONDPG ,"E4_FORMA")
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica os bonus por item de venda                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aBonus   := FtRgrBonus(aCols,{nPProd,nPQtd,nPTES},M->UA_CLIENTE,M->UA_LOJA,M->UA_TABELA,M->UA_CONDPG,cFormPg)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Recupera os bonus ja existentes                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
	aBonus   := FtRecBonus(aCols,{nPProd,nPQtd,nPTES,nUsado+1},aBonus)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Grava os novos bonus                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
	nTotal := Len(aBonus)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pega o número do último item.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    cItem  := aCols[Len(aCols),nPItem]

	If nTotal > 0
		For nAux := 1 To nTotal
		
			AAdd(aCols,Array(nUsado+1))
			nLinha ++
			n := nLinha

			For nCol := 1 To nUsado   
				If IsHeadRec(aHeader[nCol,2])
					aCols[nLinha,nCol] :=	 0 
				ElseIf IsHeadAlias(aHeader[nCol,2])
					aCols[nLinha,nCol] := "SUB"
				Else		
					aCols[nLinha,nCol] := CriaVar(aHeader[nCol,2],.T.)	
				EndIf			
			Next nCol	
			aCols[nLinha,nUsado+1] := .F.
			
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1") + aBonus[nAux][1])

				cItem					:= Soma1( cItem )
				aCols[nLinha,nPItem]	:= cItem			

				aCols[nLinha,nPProd] 	:= aBonus[nAux][1]
				aCols[nLinha,nPQtd]  	:= aBonus[nAux][2]
			
				aCols[nLinha,nPDescri] 	:= SB1->B1_DESC
				aCols[nLinha][nPUm]    	:= SB1->B1_UM
				aCols[nLinha][nPLocal] 	:= RetFldProd(SB1->B1_COD,"B1_LOCPAD")
				aCols[nLinha][nPSitProd]:= SB1->B1_SITPROD
				aCols[nLinha][nPVrUnit] := 0

 				If ExistTrigger("UB_PRODUTO")
   					RunTrigger(2,Len(aCols))
				Endif	

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Lanca o TES usado para Bonificacao³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				aCols[nLinha,nPTES]  	:= aBonus[nAux][3]
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Verifico o ESTADO do cliente³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				DbSelectArea("SF4")
				DbSetOrder(1)
				If DbSeek(xFilial("SF4") + aCols[nLinha][nPTes])
					If cPaisLoc=="BRA"
						aCols[nLinha][nPCf] := 	IF(SA1->A1_TIPO<>"X",;
												IF(SA1->A1_EST == cEstado,F4_CF,"6"+Subs(F4_CF,2,2)),"7"+Subs(F4_CF,2,2))
					Else
						aCols[nLinha][nPCf] := ALLTRIM(SF4->F4_CF)
					Endif
				Endif
			
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Executa a rotina que ira selecionar o preco de tabela do produto ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				Tk273Calcula("UA_TABELA",nLinha,.F.)
				
			Endif
			
		Next nAux
	Endif
Else
	FtDelBonus(aCols,{nPProd,nPQtd,nPTES,nUsado+1})	

	For nCont:= 1 To Len(aCols)	
		If (aCols[nCont][Len(aHeader)+1])

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Deleta o item da rotina fiscal.³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !MaFisFound("IT",nCont)
				MaFisAdd("","",0,0,0,"","",,0,0,0,0,0)
			Endif
			MaFisDel(nCont,aCols[nCont][Len(aCols[nCont])])
		Endif
	Next nCont
Endif                                

RestArea(aArea)

Return(.T.)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³TK271ValPed³Autor  ³ Vendas Clientes    ³ Data ³  07/03/02   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Gera novos atendimentos ao inves de alterar.                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Somente Televendas                                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Tk273ValPed(nOpc,l380)
Local lRet     	:= .T.							// Retorno Valido da funcao
Local aSArea  	:= GetArea()					// Salva a area atual
Local lTMKINCPED:= GetNewPar("MV_TMKINCP",.F.)  // Parametro Criado para realizar novas inclusoes quando a execucao for pela Lista de Contato Pendente   	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Se o parametro estiver criado (MV_TMKINCPED - Inclusao de Atendimentos executados pela Lista de Contatos Pendente)³
//³e a execucao esta sendo feita pela Agenda do Operador e nao e a 1¦ inclusao - Inclui um novo atendimento          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If (lTmkIncPed) .AND. (l380) .AND. (nOpc <> 3)
	
	DbSelectArea("SUA")
	DbSetOrder(1)
	If DbSeek(xFilial("SUA")+M->UA_NUM)
		Do case
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se a nota fiscal tiver sido emitida nao continua a gravacao³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Case AllTrim(SUA->UA_STATUS) == "NF." .AND. (Val(SUA->UA_OPER) == FATURAMENTO)
				MsgInfo(STR0010)	// "Este pedido ja foi faturado."
				lRet := .F.
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se o pedido estiver bloqueado realiza apenas a ALTERACAO   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Case AllTrim(SUA->UA_STATUS) == "SUP" .AND. (Val(SUA->UA_OPER) == FATURAMENTO)
				lRet := .T.
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se o atendimento foi cancelado nao continua a gravacao     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Case AllTrim(SUA->UA_STATUS) == "CAN"
				MsgInfo(STR0011)	// "Este pedido foi cancelado."
				lRet := .F.
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se o pedido ja foi liberado nao continua a gravacao        ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Case AllTrim(SUA->UA_STATUS) == "LIB"
				MsgInfo(STR0012)	// "Este pedido ja foi liberado."
				lRet := .F.
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Caso contrario prepara a alteracao para ser + 1 Inclusao   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			Otherwise
				M->UA_NUM := GetSXENum("SUA","UA_NUM")
				nOpc	:= 3 // transforma em inclusão para controle. A MayUse se encarrega do novo codigo.
				INCLUI	:= .T.
				lRet	:= .T.	//Orcamento
				
		Endcase
	Endif
Endif

RestArea(aSArea)
Return(lRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao	 ³Tk273GrvPTC³ Autor ³Marcelo Kotaki        ³ Data 05/11/03     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Objetivos:								              	    ³±±
±±³          ³Converte o Prospect em um novo Cliente					    ³±±
±±³          ³                                                              ³±±
±±³          ³Premissas:                                                    ³±±
±±³          ³1) Somente quando o atendimento for para um PROSPECT          ³±±
±±³          ³2) Somente quando a operacao do atendimento for FATURAMENTO   ³±±
±±³          ³                                                              ³±±
±±³          ³Regras:                                                       ³±±
±±³          ³- O historico do prospect sera mantido para o Prospect        ³±±
±±³          ³- No cadastro de prospect sera incluido o codigo do NOVO      ³±±
±±³          ³cliente                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpC1: Codigo do prospect                                     ³±±
±±³          ³ExpC2: Loja do prospect                                       ³±±
±±³          ³ExpL3: Flag para omitir as mensagens de aviso                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function Tk273GrvPTC(cProsp,cLoja,lAuto)

Local aArea			:= GetArea()					// Armazena o posicionamento atual
Local cCodSA1 		:= ""							// Novo codigo de cliente que sera informado para esse prospect
Local cCodAux 		:= ""							// Codigo auxiliar para evitar falhas no semaforo
Local lGrava  		:= .F.							// Flag para permitir ou nao a Gravacao 	
Local lRet	  		:= .F.							// Retorno da funcao	
Local lTMK273PTC	:= FindFunction("U_TMK273PTC") 	// P.E. depois da gravacao do prospect no cliente - NAO DIVULGAR pois deve ser usado o P.E. TMKVFIM.
Local lTK273PT2		:= FindFunction("U_TK273PT2") 	// P.E. depois da gravacao do SU5,AC8 e SA1 - NAO DIVULGAR pois deve ser usado o P.E. TMKVFIM.
Local lAtuADL		:= ChkFile("ADL")				// Indica se deve ser atualizada a tabela ADL

Local lTK273DCli 	:= ExistBlock("TK273DCli")
Local aTK273DCli		:= {}
Local nX    		:= 0

Local cChave 		:= ""
Local aAutoAO4		:= {}
Local aAmarra       := {} 

Local nCont    		:= 0

Default lAuto		:= .F.							// Flag que indica se a rotina esta sendo executada sem interface

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Posiciona o PROSPECT e GRAVA um novo CLIENTE                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("SUS")
DbSetOrder(1)
If DbSeek(xFilial("SUS")+cProsp+cLoja)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³O PROSPECT nao pode ter nenhum cliente relacionado       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Empty(SUS->US_CODCLI) .AND. Empty(SUS->US_LOJACLI)
	   lGrava := .T. 		
	Endif   

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida se existe o CGC desse prospect na base de clientes³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lGrava
	    If !Empty(SUS->US_CGC)
			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(xFilial("SA1")+SUS->US_CGC)

				If !lAuto .And. !IsInCallStack("FATA300")
					//"Atencao","O CNPJ desse Prospect ja está cadastrado na tabela de Clientes, o atendimento nao sera concluido"
					Aviso(STR0015,STR0016,{"OK"})
					Return(lRet)
				Endif
		
			Else   
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Valida se existe o mesmo NOME desse PROSPECT na base de clientes   ³
				//³Porem mantem a gravacao do registro porque os CNPJS sao diferentes ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				DbSelectArea("SA1")
				DbSetOrder(2)
				If DbSeek(xFilial("SA1")+SUS->US_NOME)

					If (ALLTRIM(SA1->A1_NOME) == ALLTRIM(SUS->US_NOME)) .AND. !lAuto
			   		   // "Atencao","Ja existe um Cliente cadastrado com o mesmo nome desse Prospect"
					   Aviso(STR0015,STR0017,{"OK"})
					Endif
					
				Endif
			Endif
			
		Endif	
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Pega um codigo valido para o novo  Cliente ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cCodSA1 := CriaVar("A1_COD",.F.)
		cCodAux := TkNumero("SA1","A1_COD")

		cCodSA1 		:= cCodAux 
		If Type("M->UA_CLIENTE") == "C"
			M->UA_CLIENTE 	:= cCodAux
		EndIf		
		
		Reclock("SA1",.T.)
		SA1->A1_FILIAL 	:= xFilial("SA1")
		SA1->A1_COD 	:= cCodSA1
		SA1->A1_LOJA	:= SUS->US_LOJA
		SA1->A1_NOME	:= SUS->US_NOME
		SA1->A1_NREDUZ	:= SUS->US_NREDUZ
		SA1->A1_TIPO	:= SUS->US_TIPO		
		SA1->A1_END		:= SUS->US_END		
		SA1->A1_MUN		:= SUS->US_MUN  
		SA1->A1_COD_MUN := SUS->US_COD_MUN
		SA1->A1_REGIAO  := SUS->US_REGIAO		
		SA1->A1_DSCREG  := SUS->US_DSCREG	
		SA1->A1_BAIRRO	:= SUS->US_BAIRRO
		SA1->A1_CEP		:= SUS->US_CEP
		SA1->A1_EST		:= SUS->US_EST
		SA1->A1_DDI		:= SUS->US_DDI
		SA1->A1_DDD		:= SUS->US_DDD
		SA1->A1_TEL		:= SUS->US_TEL
		SA1->A1_FAX		:= SUS->US_FAX
		SA1->A1_EMAIL	:= SUS->US_EMAIL
		SA1->A1_HPAGE	:= SUS->US_URL
		SA1->A1_ULTVIS	:= SUS->US_ULTVIS								
		SA1->A1_CODHIST	:= SUS->US_CODHIST
		SA1->A1_VEND	:= SUS->US_VEND
		SA1->A1_PESSOA 	:= SUS->US_PESSOA			
		SA1->A1_CGC		:= SUS->US_CGC			
			
		If cPaisloc == "BRA"
			SA1->A1_INSCR	:= SUS->US_INSCR
		EndIf

		SA1->A1_ALIQIR	:= SUS->US_ALIQIR		
		SA1->A1_GRPTRIB	:= SUS->US_GRPTRIB	
		SA1->A1_NATUREZ	:= SUS->US_NATUREZ		
		SA1->A1_RECCOFI	:= SUS->US_RECCOFI		
		SA1->A1_RECCSLL	:= SUS->US_RECCSLL		
		SA1->A1_RECISS	:= SUS->US_RECISS		
		SA1->A1_RECINSS	:= SUS->US_RECINSS		
		SA1->A1_RECPIS	:= SUS->US_RECPIS		
		SA1->A1_SUFRAMA	:= SUS->US_SUFRAMA			
		SA1->A1_DTCAD		:= Date()	
		SA1->A1_HRCAD		:= Time()
		SA1->A1_HRTRANS	:= SUS->US_TRASLA
		
		SA1->A1_LC		:= SUS->US_LC
		SA1->A1_VENCLC	:= SUS->US_VENCLC
		SA1->A1_MOEDALC	:= SUS->US_MOEDALC 	
		SA1->A1_CODSEG  	:= SUS->US_CODSEG
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
   		//³Gravacao dos campos para mapear a origem do Cliente³
   		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		
 	   	SA1->A1_ORIGCT 	:= SUS->US_ORIGEM		
	   	SA1->A1_ENTORI	:= SUS->US_ENTORI     
		
		//Grava a Campanha de origem ao fechar uma oportunidade gerada a partir de uma Resposta de Campanha.
		If IsInCallStack("FATA300") .And. !Empty(M->AD1_TPCAMP) .And. !Empty(M->AD1_CHVCAM) 
			SA1->A1_TPCAMP	:= M->AD1_TPCAMP
			SA1->A1_CHVCAM	:= M->AD1_CHVCAM
		EndIf
		
		SA1->A1_MSBLQL := "2" //Ativo.
		
		If lTK273DCli
			aTK273DCli:= ExecBlock("TK273DCli",.F.,.F.)
			For nX := 1 To Len(aTK273DCli)
				SA1->&(aTK273DCli[nX][1]):= aTK273DCli[nX][2] 	
			Next nX
		EndIf
		
		FkCommit()
		MsUnlock()         


		//Tabela de Complemento de Cliente
		DbSelectArea("AI0")
		Reclock("AI0",.T.)
		AI0->AI0_CODCLI := SA1->A1_COD
		AI0->AI0_LOJA   := SA1->A1_LOJA
		IF	!Empty(SUS->US_SETPUBL)
			AI0->AI0_SETPUB := SUS->US_SETPUBL
		Else
			AI0->AI0_SETPUB := "2"
		Endif	
			
		FkCommit()			
		MsUnlock() 
		
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Adiciona ou Remove o privilegios deste registro.  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cChave 	:= PadR(xFilial("SA1")+cCodSA1+SUS->US_LOJA,TAMSX3( "AO4_CHVREG")[1])
		aAutoAO4	:= CRMA200PAut(3,"SA1",cChave,/*cCodUsr*/,/*aPermissoes*/,/*aNvlEstrut*/,/*cCodUsrCom*/,/*dDataVld*/)
		
		DbSelectArea("AO3")
		AO3->(DbSetOrder(1))	// AO3_FILIAL+AO3_CODUSR
											
		If AO3->(DbSeek(xFilial("AO3")+RetCodUsr()))
		
			//------------------------------------------------------------------------------------------------					
			// Se o codigo do vendendor logado for diferente do cadastrado, insere na AO4 como compartilhado
			//------------------------------------------------------------------------------------------------
			If !Empty( SA1->A1_VEND ) .AND. AO3->AO3_VEND <> SA1->A1_VEND
									
				AO3->(DbSetOrder(2))	//AO3_FILIAL+AO3_VEND
									
				If AO3->(DbSeek(xFilial("AO3")+SA1->A1_VEND))
					aAutoAO4Aux := CRMA200PAut(,"SA1",cChave,AO3->AO3_CODUSR,/*aPermissoes*/,/*aNvlEstrut*/,RetCodUsr(),/*dDataVld*/)
					aAdd(aAutoAO4[2],aAutoAO4Aux[2][1])
				EndIf
									
			EndIf
		EndIf
								
										
		If Len(aAutoAO4) > 0
			lRet := CRMA200Auto(aAutoAO4[1],aAutoAO4[2])
		EndIf
		
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Ponto de entrada para gravacao dos dados do cliente³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lTMK273PTC
			U_TMK273PTC()
		Endif	
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Pegou um codigo novo confirma a gravacao do SXE³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If __lSX8
			ConfirmSX8()
		Endif
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Altera os relacionamentos de contatos para a nova entidade - CLIENTES ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("AC8")
		dbSetOrder(2) 		//AC8_FILIAL+AC8_ENTIDA+AC8_FILENT+AC8_CODENT+AC8_CODCON

 		While dbSeek(xFilial("AC8")+"SUS"+xFilial("SUS")+(SUS->US_COD+SUS->US_LOJA))	
			Reclock("AC8",.F.)
				Replace AC8_FILIAL With xFilial("AC8")
				Replace AC8_ENTIDA With "SA1"
				Replace AC8_FILENT With xFilial("SA1")
				Replace AC8_CODENT With cCodSA1+SUS->US_LOJA
			MsUnlock()
			DbCommit()               
		EndDo

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Altera os relacionamentos de Banco de Conhecimento para³
		//³a nova entidade - CLIENTES                             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		DbSelectArea("AC9")
		DbSetOrder(2) 		//AC9_FILIAL+AC9_ENTIDA+AC9_FILENT+AC9_CODENT+AC9_CODOBJ
		While dbSeek(xFilial("AC9")+"SUS"+xFilial("SUS")+(SUS->US_COD+SUS->US_LOJA))
			Reclock("AC9",.F.)
				Replace AC9_FILIAL With xFilial("AC9")
				Replace AC9_ENTIDA With "SA1"
				Replace AC9_FILENT With xFilial("SA1")
				Replace AC9_CODENT With cCodSA1+SUS->US_LOJA
			MsUnlock()
			DbCommit()               
		EndDo
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Atualiza o STATUS do prospect  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		DbSelectArea("SUS")
		Reclock( "SUS" ,.F.)
		Replace US_STATUS  With "6" 			// 6 - Cliente     
		Replace US_CODCLI  With cCodSA1
		Replace US_LOJACLI With cLoja
		Replace US_DTCONV  With Date()
		Replace US_HRCONV  With Time()
   		MsUnlock()
	
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Inclui os relacionamentos de segmento para a nova entidade - CLIENTES ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("AOW")
		dbSetOrder(1) //AOW_FILIAL+AOW_ENTIDA+AOW_FILENT+AOW_CODCNT+AOW_LOJCNT+AOW_CODSEG

 		IF	dbSeek(xFilial("AOW")+"SUS"+xFilial("SUS")+SUS->US_COD+SUS->US_LOJA+SUS->US_CODSEG)
  			While ((!AOW->( Eof())) .And. (xFilial("AOW") == AOW->AOW_FILIAL) .And.;
  			       (AOW->AOW_ENTIDA == 'SUS') .And. (xFilial("SUS")==AOW->AOW_FILENT) .And.;
  			       (AOW->AOW_CODCNT == SUS->US_COD) .And. (AOW->AOW_LOJCNT== SUS->US_LOJA) .And.;
  			       (AOW->AOW_CODSEG == SUS->US_CODSEG))


  			AAdd( aAmarra,{xFilial( "AOW" ),;
							 xFilial("SUS"),;
							 cCodSA1,;
							 "SA1",;
							 cLoja,;
							 AOW->AOW_CODSEG,;
							 AOW->AOW_SUBSEG} )
  
				AOW->( DbSkip() )            
			EndDo

			For nCont := 1 To Len( aAmarra )
				Reclock("AOW",.T.)
				AOW_FILIAL := aAmarra[nCont][1]
				AOW_FILENT := aAmarra[nCont][2]			
				AOW_CODCNT := aAmarra[nCont][3]			
				AOW_ENTIDA := aAmarra[nCont][4]
				AOW_LOJCNT := aAmarra[nCont][5]
				AOW_CODSEG := aAmarra[nCont][6]
				AOW_SUBSEG := aAmarra[nCont][7]
				MsUnlock()
				DbCommit()   
			Next
		Endif	
	
	
	
		
		If lAtuADL 
			Ft520UpdEn("SUS"		, "SA1"			, SUS->US_COD	, SA1->A1_COD	,;
						SUS->US_LOJA, SA1->A1_LOJA	)
		EndIf
		
		Ft300UpdEn(SUS->US_COD, SA1->A1_COD, SUS->US_LOJA, SA1->A1_LOJA)
		lRet := .T.
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Ponto de entrada para gravacao dos dados do cliente³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lTK273PT2
			U_TK273PT2()
		Endif			
		
		//Atualiza locais de atendimento mudando o prospect para o cliente gerado.
		DbSelectArea("ABS")
		DbSetOrder(1)
		If ABS->(DbSeek(xFilial("ABS")))
			While ABS->(!Eof())
				If ABS->ABS_ENTIDA == "2" .AND. ABS->ABS_CODIGO == cProsp .AND. ABS->ABS_LOJA == cLoja
					RecLock("ABS", .F.)
					ABS->ABS_ENTIDA	:=	"1"
					ABS->ABS_CODIGO	:= cCodSA1
					ABS->ABS_LOJA	:= SUS->US_LOJA
					ABS->ABS_CLIFAT	:= cCodSA1
					ABS->ABS_LJFAT	:= SUS->US_LOJA
					MsUnLock()
				EndIf
				ABS->(DbSkip())
			End
		EndIf		
	Endif
Endif

RestArea(aArea)

Return(lRet)
                                         

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273AvalCred ºAutor  ³ Vendas Clientesº Data ³  15/06/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Preparacao para enviar os dados do cliente para analise de  º±±
±±º          ³credito.                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³cExp1 := Transacao de analise de credito                    º±±
±±º          ³         "1" - Executar a transacao de credito              º±±
±±º          ³         "2" - Confirmar a transacao de credito             º±±
±±º          ³         "3" - Exclusao da transacao de credito             º±±
±±º          ³lExp2 := Envia para o crediario                             º±±
±±º          ³aExp3 := Array com as parcelas para pagamento               º±±
±±º          ³nExp4 := Valor total da venda (liquido)                     º±±
±±º          ³nExp5	:= Valor dos Juros                                    º±±
±±º          ³cExp6	:= Operacoes que serao feitas a analise de credito    º±±
±±º          ³         |21|- ORCAMENTO                                    º±±
±±º          ³         |22|- PEDIDO                                       º±±
±±º          ³lExp7 := Indica se eh uma consulta                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Retorno: Array aRetCred (Retorno da analise de credito)     º±±
±±º          ³                                                            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER - TELEVENDAS                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function Tk273AvalCred(	cTransacao 	,	lEnvCred	,	aParcelas	,	nLiquido,;
						nVlJur		,	cMV_CRDAVAL	, 	lModoCons)
            
Local aArea			:= GetARea()   					// Salva a area de trabalho atual
Local cCliente		:= M->UA_CLIENTE				// Codigo do Cliente
Local cLoja			:= M->UA_LOJA					// Codigo da Loja
Local cRespForcada	:= M->UA_OPERADO      			// Responsavel pela venda forcada
Local cDetalhe		:= Space(80)					// Detalhes da parcela - cartao, cheque, etc
Local cAdm			:= ""                          	// Codigo da Administradora
Local cBanco  		:= ""                     		// Codigo do Banco
Local cAgencia		:= ""                         	// Numero da Agencia
Local cConta		:= ""                          	// Numero da Conta
Local cCheque		:= ""                          	// Numero do Cheque
Local cRG			:= ""                         	// Numero do RG
Local cFone			:= ""                         	// Numero do Telefone

Local aDadosCRD		:= {}							// Array com os dados necessarios para efetuar a analise de credito
Local aProdCrd    	:= {}                  			// Produtos da venda 
Local aParcCRD		:= {}							// Array que contem as parcelas que serao analisadas
Local aParcVda    	:= {}                  			// Array com todas as Parcelas da venda
Local aRetCRD		:= {}							// Retorno da funcao de analise de credito
Local aRetFalse		:= {1,0,0,"",.F.}  			// Retorno para NAO continuar a operacao

Local nMoedaParc  	:= 1                   			// Moeda da parcela
Local nTpVenda    	:= 1                   			// 1-Venda Normal 2-Venda forcada
Local nI			:= 0							// Contador de loop
Local nPos			:= 0							// Posicao no array 
Local nTotalParc	:= 0							// Valor Total de parcelas a Faturar
Local nTotalNFat	:= 0							// Valor Total de produtos nao Faturados - TES que nao gera duplicata
Local nValIpi 		:= 0   							// Valor de IPI dos produtos que nao geram faturamento
Local nPercJur		:= 0							// Percentual de Juros
Local nPosItem  	:= aPosicoes[20][2]    			// Posicao do item no aHeader
Local nPProd    	:= aPosicoes[1][2]				// Produto
Local nPDescPro 	:= aPosicoes[2][2]				// Descricao do Produto
Local nPQtd     	:= aPosicoes[4][2]             // Quantidade
Local nPVrUnit  	:= aPosicoes[5][2]             // Valor unitario
Local nPVlrItem		:= aPosicoes[6][2]             // Valor do item
Local nPTes	    	:= aPosicoes[11][2]            // TES

Local lCheque     	:= .F.                 			// Indica se a parcela e cheque 
Local lTrocouCli    := .F. 
                      
DEFAULT	cMV_CRDAVAL := "XX"							// Nao vai validar a operacao para realizar a analise de credito

If INCLUI
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Validacao da troca do cliente apos jah ter sido feita uma analise de credito.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !Empty(aCrdCliente[1]+aCrdCliente[2])
   		DbSelectArea("SA1")
   		DbSetOrder(1)
   		If DbSeek(xFilial("SA1")+ cCliente+cLoja)
	   		If !Empty(aCrdCliente[1]) //CNPJ ou CPF
	   			
	   			If Alltrim(aCrdCliente[1])	<> Alltrim(SA1->A1_CGC)	
	   			
	   				Conout("17.TMKA273D - Tk273AvalCred - " +;
						" CNPJ/CPF = " + aCrdCliente[1]		+;
						" A1_CGC   = " + SA1->A1_CGC		+;						
						STR0045)			//" Zera array aCrdCliente"
	   			
	   				aCrdCliente  := {"",""}
	   			Else
	   				Conout("18.TMKA273D - Tk273AvalCred - "	+;
						" CNPJ/CPF = " + aCrdCliente[1]		+;
						" A1_CGC   = " + If(Empty(SA1->A1_CGC),"",SA1->A1_CGC)		+;												
						STR0046)			//" Nao Zera array aCrdCliente"
	   			Endif	
	   		ElseIf !Empty(aCrdCliente[2])
	   			DbSelectArea("MA6") //Cartoes
	   			DbSetOrder(2)
	   			If DbSeek(xFilial("MA6")+cCliente+cLoja)
	   				If Alltrim(aCrdCliente[2]) <> Alltrim(MA6->MA6_NUM)  //Num. Cartao Private Label
	   					
	   					Conout("19.TMKA273D - Tk273AvalCred - " 		+;
						STR0047 + aCrdCliente[2]  	+;           //" Nro Cartao Priv Label = "
						" MA6_NUM = " + Alltrim(MA6->MA6_NUM)  			+;
						STR0045) 		//" Zera array aCrdCliente "
						
		   				aCrdCliente  := {"",""}
					ELSE                       
						Conout("20.TMKA273D - Tk273AvalCred - " +;
						STR0047 + aCrdCliente[2]  +;             //" Nro Cartao Priv Label = "
						" MA6_NUM = " + Alltrim(MA6->MA6_NUM)  +;
						STR0046)			//" Nao Zera array aCrdCliente"
					
					Endif   				
				Else
					Conout("21.TMKA273D - Tk273AvalCred - "  +;
						STR0048	+ If( Empty(cCliente),"", cCliente) 	+;    //" Cliente = " 
						STR0049		+ If( Empty(cLoja), "", cLoja) 			+;	//" Loja = " 
						STR0050)			//" Nao encontrou o cliente no MA6"
				Endif
	   		Endif 
	   	Else
	   		Conout("22.TMKA273D - Tk273AvalCred - " +;
	   				STR0048 + If( Empty(cCliente),"", cCliente) +;	//"Cliente: "
	   				STR0049 	+ If( Empty(cLoja), "", cLoja) +;	//" Loja: "
	   				STR0051)			//" Nao encontrado no SA1"
	   	Endif		
	Else
		Conout("23.TMKA273D - Tk273AvalCred - "     	+;
		" Validacao: aCrdCliente[1] .AND. aCrdCliente[2] = VAZIO ")
	Endif	
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se trocou o cliente em um atendimento jah gravado, forca a identificacao do novo cliente³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (lTrocouCli := cCliente+cLoja <> SUA->UA_CLIENTE + SUA->UA_LOJA) .OR. Val(SUA->UA_OPER) == FATURAMENTO
		Conout("24.TMKA273D - Tk273AvalCred -"+ STR0045 +;		//Zera array aCrdCliente. 
				STR0048 + If(Empty(cCliente),"",cCliente) +;		//" Cliente: "
							   If(Empty(cLoja), "", cLoja) + ;
		       " SUA:" + SUA->UA_CLIENTE + SUA->UA_LOJA + ;
		       " UA_OPER " + SUA->UA_OPER )
   		aCrdCliente  := {"",""}
    Endif
        
	nPos:= Ascan(aContrTmp,{|x| x[1] == SUA->UA_CONTRA})
	If nPos == 0
		AADD(aContrTmp,{SUA->UA_CONTRA , SUA->UA_CLIENTE, SUA->UA_LOJA})
	Endif	
   	If !lTrocouCli .AND. cTransacao == "1" .AND. !Empty(SUA->UA_CONTRA)
   	   cContrato    := SUA->UA_CONTRA 
   	   Conout("25.TMKA273D - Tk273AvalCred -" + STR0054 +;		//Entrou em 
   	   			" !lTrocouCli .AND. cTransacao == '1' .AND. !Empty(SUA->UA_CONTRA) " +;
   	   			STR0038 + If(Empty(cContrato),"",cContrato))   	   //" Contrato: "
   	Endif   
   	                                                                   
   	Conout("26.TMKA273D - Tk273AvalCred - "     	+;
			STR0038 + cContrato +;		//" Contrato: "
			STR0048 + If( Empty(SUA->UA_CLIENTE), "", SUA->UA_CLIENTE) +;  //" Cliente : "
			STR0049 + If( Empty(SUA->UA_LOJA), "", SUA->UA_LOJA) +;         //" Loja: "
			STR0055 +"TK273RestCRD" )	//Chama a funcao
			
	Tk273RestCRD(cContrato, SUA->UA_CLIENTE, SUA->UA_LOJA)         
	
Endif	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inclui no array de produtos apenas os que possuem TES associada que gera duplicata³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
For nI:=1 TO Len(aCols)
	If !aCols[nI][Len(aHeader)+1] .AND. !Empty(aCols[nI][nPTes])
		DbSelectArea("SF4")
		DbSetOrder(1)
		If DbSeek(xFilial("SF4")+aCols[nI][nPTes])
			If SF4->F4_DUPLIC == "S" //Gera Duplicata
				AADD( aProdCrd, { 	aCols[nI][nPosItem]		,;	//01 Item do Produto
									aCols[nI][nPProd]		,;	//02 Codigo do Produto
								 	aCols[nI][nPDescPro]	,;	//03 Descricao do Produto
								  	aCols[nI][nPQtd]		,;	//04 Quantidade de pecas vendidas
								  	aCols[nI][nPVrUnit]		,;	//05 Valor unitario do produto
								  	aCols[nI][nPVlrItem]} )		//06 Valor total da venda do item
			Else          			 //Nao Gera Duplicata	
				nValIpi:=MaFisRet(nI,'IT_VALIPI')
				nTotalNFat += aCols[nI][nPVlrItem]+nValIpi
			Endif
		Endif
	Endif
Next nI

If Len(aProdCrd) <= 0
	Alert(STR0019) //"Nao existem produtos a serem avaliados para a análise de crédito. Avalie a TES utilizada."
	RestArea(aArea)
	Return(aRetFalse)
Endif	                                                                        

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o valor das parcelas e o mesmo do VALOR LIQUIDO ou se nao mudou nada³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Len(aParcelas) > 0 
	For nI := 1 To Len(aParcelas)
		nTotalParc += Round(NoRound(aParcelas[nI][2],4),2)
	Next nI
	
	If NoRound(nTotalParc,2) <> NoRound(nLiquido,2)
		Help( " ", 1, "TK010VALOK" )
		RestArea(aArea)
		Return(aRetFalse)
	Endif
Else
	Alert(STR0020) //"A condição de pagamento nao foi especificada. Por favor, selecione uma condição de pagamento para efetuar a análise de crédito."
	RestArea(aArea)
	Return(aRetFalse)
Endif

For nI := 1 to Len(aParcelas)
	cDetalhe		:= aParcelas[nI][4]				
	lCheque     	:= AllTrim(aParcelas[nI][3]) == "CH"
	nMoedaParc  	:= If(cPaisLoc == "BRA",M->UA_MOEDA ,1) 

	If AllTrim(aParcelas[nI][3]) == "CH"
		cBanco  	:= Substr(cDetalhe,1,3)
		cAgencia	:= Substr(cDetalhe,4,5)
		cConta  	:= Substr(cDetalhe,9,10)
		cCheque 	:= Substr(cDetalhe,19,15)
		cRg     	:= Substr(cDetalhe,34,14)
		cFone   	:= Substr(cDetalhe,48,15)

   	//Qualquer outra forma de pagamento
   	Else
		If AllTrim(aParcelas[nI][3]) <> "R$"
			cAdm   	:= Substr(cDetalhe,1,AT("-",cDetalhe)-1) //Adm de Cartao Private Label
        Endif
   	EndIf
	
	If nVlJur > 0
		nPercJur:= ( NoRound(nVlJur,2) * 100) / NoRound(nTotalParc,2)
	Endif
		
	Aadd(aParcVda,{	 aParcelas[nI][1]			,;	//01 Data de vencimento
				     aParcelas[nI][2]			,;	//02 Valor da parcela
				     aParcelas[nI][3]			,;	//03 Forma de pagamento
				     cAdm						,;	//04 Codigo da Administradora - SAE
				     If(lCheque,cCheque,"")	,;	//05 Numero do cheque/cartao 
				     If(lCheque,cAgencia,"")	,;  //06 Agencia do cheque
					 If(lCheque,cConta,"")		,;	//07 Conta do cheque
					 If(lCheque,cRg,"")		,; 	//08 RG do cheque
					 If(lCheque,cFone,"")		,; 	//09 Telefone do portador do cheque
					 .F.						,; 	//10 
					 nMoedaParc })	                //11 Moeda da parcela
    Conout("27. TMKA273D aParcVda: nI: " + ALLTRIM(STR(nI)) +;
    		 " " + If(Empty(aParcVda[nI][3]),"", aParcVda[nI][3]) +;
    		 " " + If(Empty(cAdm),"", cAdm) )	
Next nI

//Estrutura do array aDadosCRD
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³[1] - Numero do cartao Private Label                          ³
//³[2] - Numero do CPF                                           ³
//³[3] - Valor da venda (valor liquido)                          ³
//³[4] - Juros da venda (%)                                      ³
//³[5] - Numeros de parcelas                                     ³
//³[6] - Venda forcada (1-Venda Normal 2-Venda forçada)          ³
//³[7] - Responsável pela venda forçada                          ³
//³[8] - Array com as parcelas para o financiamento  - nao obrig.³
//³      [1] - Data de vencimento                                ³
//³      [2] - Valor da parcela                                  ³
//³      [3] - Forma de pagamento                                ³
//³      [4] - Administradora financeira                         ³
//³[9] - Loja que solicitou a transação SM0(EMP+FILIAL+NOMEFILI) ³
//³[10] - Numero do PDV que solicitou a transação                ³
//³[11] - Caixa que solicitou a transacao                        ³
//³[12] - Numero do Orcamento selecionado                        ³
//³[13] - Produtos contido na venda atual                        ³
//³      [1] - Item do produto                                   ³
//³      [2] - Codigo do produto                                 ³
//³      [3] - Descrição do produto                              ³
//³      [4] - Quantidade do produto                             ³
//³      [5] - Valor unitário do produto                         ³
//³      [6] - Valor total do item do produto                    ³
//³[14] - Parcelas de uma venda.                                 ³
//³      [1] - Data de vencimento                                ³
//³      [2] - Valor da parcela                                  ³
//³      [3] - Forma de pagamento                                ³
//³      [4] - Administradora                                    ³
//³      [5] - Número do cartão / cheque                         ³
//³      [6] - Agencia - Cheque                                  ³
//³      [7] - Conta - Cheque                                    ³
//³      [8] - Rg - Cheque                                       ³
//³      [9] - Telefone - Cheque                                 ³
//³      [10] - Valido para todas as parcelas                    ³
//³      [11] - Moeda da parcela                                 ³
//³[15] - Filial do Caixa que está sendo utilizado  SM0_FILIAL   ³
//³[16] - Codigo do cliente                                      ³
//³[17] - Loja do cliente                                        ³
//³[18] - Nome do usuario                                        ³
//³[19] - Condicao de Pagamento                                  ³
//³[20] - Modulo chamador										 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If Len(aParcVda) > 0
    SM0->(DbSetOrder(1))
    SM0->(DbSeek(Substr(cEmpAnt,1,2)+cFilAnt))
    
	aAdd( aDadosCrd, aCrdCliente[2] )  				// 01 Numero do cartao Private Label
	aAdd( aDadosCrd, aCrdCliente[1] )  				// 02 CNPJ/CPF
	aAdd( aDadosCrd, nLiquido 	)	   				// 03 Valor da venda  (Liquido)
	aAdd( aDadosCrd, nPercJur)	           			// 04 Juros da venda	(%)
	aAdd( aDadosCrd, Len(aParcelas))		       	// 05 Numero de parcelas
	aAdd( aDadosCrd, nTpVenda)			   			// 06 Venda forcada(1-Venda Normal 2-Venda forcada)
	aAdd( aDadosCrd, cRespForcada)			   		// 07 Responsavel pela venda forcada
	aAdd( aDadosCrd, AClone(aParcCrd))		       	// 08 Dados das parcelas
	aAdd( aDadosCrd, SM0->M0_CODIGO+"-"+FWGETCODFILIAL+"-"+Alltrim(SM0->M0_NOME)  ) // 09 Filial da venda
	aAdd( aDadosCrd, "")	  						// 10 PDV
	aAdd( aDadosCrd, "")			  				// 11 Caixa
	aAdd( aDadosCrd, M->UA_NUM)           			// 12 Num. do orcamento
	aAdd( aDadosCrd, aClone(aProdCrd))           	// 13 Produtos selecionados numa venda
	aAdd( aDadosCrd, aClone(aParcVda))           	// 14 Parcelas de uma venda
	aAdd( aDadosCrd, FWGETCODFILIAL)           		// 15 Filial do Caixa que esta sendo utilizado
	aAdd( aDadosCrd, cCliente)           			// 16 Cliente
	aAdd( aDadosCrd, cLoja)           				// 17 Loja
	aAdd( aDadosCrd, cUserName )					// 18 Nome do usuario

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se o campo UA_CONDPG existir, a condicao de pagamento desta "venda" eh armazenada³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aAdd( aDadosCrd, M->UA_CONDPG )				// 19 Condicao de pagamento
	aAdd( aDadosCrd, "TMK")           				// 20 Modulo chamador
	
	If !Empty(M->UA_VEND)
		aAdd( aDadosCrd, M->UA_VEND )     			// 21 Codigo do vendedor
	Else
		aAdd( aDadosCrd, "" )     					// 21 Codigo do vendedor
	Endif
	
    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Analise de credito  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		     			 	   	
	Do Case
		Case cTransacao == "1"
		
			Conout("28.TMKA273D - Tk273AvalCred -" +STR0055 +" CRDXVENDA "	+;   //Chama a funcao
			" cTransacao=1" + STR0048  + If( Empty(aDadosCrd[16]), "", aDadosCrd[16]) 	+;    //Cliente :
			STR0049     		+ If( Empty(aDadosCrd[17]), "", aDadosCrd[17]) 	+;       //" Loja: "
			STR0038     	+ If( Empty(cContrato), "", cContrato) 	+;    //" Contrato: "
			STR0056  	+ If( Empty(aDadosCrd[3]), "", Alltrim(STR(aDadosCrd[3]))) 	+;   //" Valor Venda: "
			STR0055 + " CrdXVenda " )             // Chama a funcao

		    aRetCrd   := aClone(CrdxVenda( "1", @aDadosCrd, cContrato, .F. ,lEnvCred, cMV_CRDAVAL,lModoCons))

  		    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		    //³Armazena CNPJ/CPF e/ou numero do cartao caso a identificacao ³
		    //³tenha sido feita na CrdxVenda                                ³	   
		    //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		     			 	   
		    If Empty(aCrdCliente[1]+aCrdCliente[2])
		    	Conout("29.TMKA273D - Tk273AvalCred -" + STR0055 +" CRDXVENDA "	+; 	//Chama a funcao
						" CNPJ/CPF : " 			+ If( Empty(aDadosCrd[2]), "", aDadosCrd[2]) 	+;
						STR0057   + If( Empty(aDadosCrd[1]), "", aDadosCrd[1]) 	+;    //" Numero do Cartao: "
						STR0058 )			//" Alimenta o array aCrdCliente "
		    
	           aCrdCliente    := {aDadosCrd[2],;       	//CNPJ/CPF
	                             aDadosCrd[1]}        	//Numero do cartao
	        EndIf   

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Atualiza o array de controle dos contratos que nao foram utilizados para serem cancelados.      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !Empty(aRetCrd[4])
				nPos:= Ascan(aContrTmp,{|x| x[1] == aRetCrd[4]})
				If nPos == 0
					AADD(aContrTmp,{aRetCrd[4] , M->UA_CLIENTE, M->UA_LOJA})
				Endif	
			Endif
					
	    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Confirmacao da transacao de credito  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		     			 	   	       
		Case cTransacao == "2"    
		
			Conout("30.TMKA273D - Tk273AvalCred -" + STR0055 + "CRDXVENDA "	+;   //Chama a funcao
			" cTransacao=2" + STR0048  + If( Empty(aDadosCrd[16]), "", aDadosCrd[16]) 	+;			//Cliente :
			STR0049     		+ If( Empty(aDadosCrd[17]), "", aDadosCrd[17]) 	+; 				//" Loja: "
			STR0038     	+ If( Empty(SUA->UA_CONTRA), If(!Empty(cContrato),cContrato, ""), SUA->UA_CONTRA) 	+;		//" Contrato: "
			STR0056  	+ If( Empty(aDadosCrd[3]), "", Alltrim(STR(aDadosCrd[3]))) 	+; 		//" Valor Venda: "
			STR0055 + "CrdXVenda " )		//" Chama a funcao
			
			aRetCrd := aClone(CrdxVenda( "2", aDadosCrd, cContrato, .F., lEnvCred, cMV_CRDAVAL ,lModoCons))
		   	If aRetCrd[1] == 0  //Confirmacao ok 
	           aCrdCliente := {"",""}
		   	EndIf
	
	    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Cancelamento da transacao de credito ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ		     			 	   	       	   
		Case cTransacao == "3"  
			Conout("31.TMKA273D - Tk273AvalCred -" + STR0055 + "CRDXVENDA "	+;		//Chama a funcao
			" cTransacao=2" + STR0048 + If( Empty(aDadosCrd[16]), "", aDadosCrd[16]) 	+;      //Cliente : 
			STR0049     		+ If( Empty(aDadosCrd[17]), "", aDadosCrd[17]) 	+; 		//" Loja: "
			STR0038     	+ If( Empty(cContrato), "", cContrato) 	+;			//" Contrato: "
			STR0056  	+ If( Empty(aDadosCrd[3]), "", Alltrim(STR(aDadosCrd[3]))) 	+; 	//" Valor Venda: "
			STR0055 + " CrdXVenda " )				//Chama a funcao
			aRetCRD		:= CrdxVenda( cTransacao,@aDadosCrd, If(Empty(SUA->UA_CONTRA),cContrato,SUA->UA_CONTRA), .F., lEnvCred, cMV_CRDAVAL ,lModoCons)
	       	aCrdCliente := {"",""}	   
	EndCase
EndIf
                              
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Retorno da funcao CrdXvenda()                   ³
//³0 - Aprovado                                    ³
//³1 - Nao aprovado                                ³
//³2 - Aprovado Off-line                           ³
//³3 - Rejeitado                                   ³
//³4 - Fila crediario                              ³
//³aRet[2] - Valor do limite de credito do cliente ³
//³aRet[3] - Valor dos titulos em aberto do cliente³
//³aRet[4] - Numero do contrato de credito         ³
//³aRet[5] - Indica se a venda foi rejeitada       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RestARea(aArea)

Return(aRetCRD)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273RetCrd ºAutor  ³ Vendas Clientes    º Data ³  06/21/05 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Tratamento do retorno da funcao da analise de credito quandoº±±
±±º          ³for chamada por diferentes operacoes.                       º±±
±±º          ³Essa funcao soh eh executada apos o retorno da Transacao1   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³lExp1 := Venda Forcada                                      º±±
±±º          ³aExp2	:= Array com o retorno da funcao de analise de creditoº±±
±±º          ³nExp3 := Valor total a faturar                              º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Retorno .T. ou .F.                                          º±±
±±º          ³                                                            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER - TELEVENDAS                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function Tk273RetCred(lForcada,aRetCrd,nTotalFat)
            
Local lRet	:= .T.			//Retorno da funcao
Local nPos	:= 0			//Posicao no array

If Len(aRetCrd) > 0 

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Tratamento do retorno falso da funcao³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aRetCrd[1] == 1 .AND. aRetCrd[2] == 0 .AND. aRetCrd[3] == 0 .AND. Empty(aRetCrd[4]) //Venda nao aprovada / Limite de Credito / Titulos em aberto / Contrato
		
		Conout("32.TMKA273D - Tk273RetCred - " +;
				STR0038 + If( Empty(cContrato), "", cContrato) +;			//" Contrato: "
				STR0059)             //" Venda nao aprovada "
		
		lRet:= .F.
		Return(lRet)
	Endif
		
	If !aRetCrd[5]	//Nao Rejeitada

		Do Case
		
			Case aRetCrd[1] == 0 	//Venda Aprovada
		        cContrato:= aRetCrd[4]	            
		        Conout("33.TMKA273D - Tk273RetCred -" + STR0060   +;				//Venda aprovada
		        		STR0038 + If( Empty(cContrato), "", cContrato) +;		//" Contrato: "
		        		STR0060)		//" Venda Aprovada. " 
			
			Case aRetCrd[1] == 2  	//Venda aprovada Off-Line 
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se nao conseguiu conexao com o WebService (OFF-LINE)                      	   ³
				//³Se for orcamento ou faturamento, vai gerar o contrato manual para gravar no SUA ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		        If Empty(cContrato)

       		        //Gera o Contrato Manual quando nao existir nenhum contrato
			        cContrato:= CrdGeraContr(nTotalFat,Nil,Nil)
        	
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Atualiza o array de controle dos contratos que nao foram utilizados para serem cancelados.      ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If !Empty(cContrato)
						
						Conout("34.TMKA273D - Tk273RetCred - "  +;
		        		STR0038 + If(Empty(cContrato),"",cContrato) +;		//" Contrato: "
		        		STR0061 )		//" Venda Aprovada Off-Line. "
						
						nPos:= Ascan(aContrTmp,{|x| x[1] == cContrato})
						If nPos == 0
							AADD(aContrTmp,{cContrato , M->UA_CLIENTE , M->UA_LOJA})
						Endif	    
					Else   
						Conout("35.TMKA273D - Tk273RetCred - "  +;
		        		STR0062 )		//" Contrato:   Venda Aprovada Off-Line. "
						
			        Endif

			    ElseIf cContrato <> aRetCrd[4]
			    	cContrato:= aRetCrd[4]
		        	Conout("36.TMKA273D - Tk273RetCred - "  +;
		        		STR0038 + If( Empty(cContrato), "", cContrato) +;		//" Contrato: "
		        		STR0061 )			    	//" Venda Aprovada Off-Line. "
			    Endif    
				lForcada  := .T.									
				
		EndCase
	
	Else //Rejeitada
    	Conout("37.TMKA273D - Tk273RetCred -" + STR0060  +;        //Venda aprovada "
		   		STR0038 + If( Empty(cContrato), "", cContrato) +;       //" Contrato: "
		   		STR0060 )		//Venda aprovada "
	
		lRet:= .F.
		Return (lRet)
    
    Endif

Endif
	
Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273GrvCredºAutor  ³ Vendas Clientes    º Data ³  21/06/05 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Gravacao das informacoes da analise de credito.             º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³lExp1 := Venda Forcada (off-line)                           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Retorno .T.                                                 º±±
±±º          ³                                                            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER - TELEVENDAS                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function Tk273GrvCred(lForcada)
            
Local lRet:= .T.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se foi venda forcada para gravar nos campos correspondentes. ³ 
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lForcada
	SUA->UA_CONTRA	:= cContrato
	SUA->UA_FORCADA	:= "1"

	If !Empty(aCrdCliente[1])
		SUA->UA_CGCCART	:= aCrdCliente[1]
	Else
		SUA->UA_CGCCART	:= aCrdCliente[2]
	Endif
Else
	SUA->UA_CONTRA	:= cContrato
	SUA->UA_FORCADA	:= "2"
	SUA->UA_CGCCART := ""
EndIf

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273ConsCred  ºAutor  ³ Vendas Clientesº Data ³  06/21/05  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Executa a consulta de credito disponibilizada atraves do   º±±
±±º          ³ botao existente na toolbar lateral do atendimento          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³lExp1 := Envia para o crediario                             º±±
±±º          ³aExp2 := Array com as parcelas para pagamento               º±±
±±º          ³nExp3 := Valor a Faturar do pedido                          º±±
±±º          ³nExp4 := Valor de Juros                                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Retorno -    .T. ou .F.                                     º±±
±±º          ³                                                            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER - TELEVENDAS                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function Tk273ConsCred(lEnvCred,aParcelas,nLiquido,nVlJur)

Local lRet		:= .T.						// Retorno da funcao
Local nSaldo	:= 0						// Saldo para compra
Local aRetCrd	:= {}                      	// Retorno da funcao de analise de credito
Local cCRLF    	:= Chr(13) + Chr(10)     	// Quebra de linha
Local nTotalParc:= 0						// Valor total a faturar 
Local nI		:= 0						// Contador do FOR
Local nMvTipACrd:= SuperGetMV("MV_TIPACRD", .F., 1)			//Define tipo de analise de credito  

//Objetos
Local oFont		  						
Local oDlg	
Local cMsgStatus

Conout("38. TMKA273D -  Tk273ConsCred - " + STR0063)		//Entrou na consulta "
aRetCrd:=  Tk273AvalCred("1",lEnvCred,aParcelas,nLiquido,nVlJur,Nil,.T.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Retorno da funcao CrdXvenda()                   ³
//³0 - Aprovado                                    ³
//³1 - Nao aprovado                                ³
//³2 - Aprovado Off-line                           ³
//³3 - Rejeitado                                   ³
//³4 - Fila crediario                              ³
//³aRet[2] - Valor do limite de credito do cliente ³
//³aRet[3] - Valor dos titulos em aberto do cliente³
//³aRet[4] - Numero do contrato de credito         ³
//³aRet[5] - Indica se a venda foi rejeitada       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If Len(aRetCrd) > 0
	Conout("39. TMKA273D - Tk273ConsCred - " +; 
			STR0038 + If( Empty(aRetCrd[4]), "", aRetCrd[4]) +;		//" Contrato: "
			" aRetCrd[5] " + If(aRetCrd[5],".T.",".F."))
	  
	If !aRetCrd[5] .AND. aRetCrd[1] == 2 //Off-Line
		Alert(STR0021)//"A consulta nao poderá ser realizada pois o serviço se encontra indisponível no momento."
		lRet:= .F.
		Return(lRet)
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Atualiza o codigo do contrato para posterior gravacao³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cContrato:= aRetCrd[4]       

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se o codigo do contrato for branco, nao precisa realizar a analise de credito³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !aRetCrd[5] .AND. aRetCrd[1] == 0 .AND. Empty(cContrato) .AND. nMvTipACrd <> YMF 
		Alert(STR0022)//"Não sera realizada a análise de crédito, a condição de pagamento selecionada nao requer sua realização."
		lRet:= .F.
		Return(lRet)
	Endif	

	If !aRetCrd[5] .AND. aRetCrd[1] == 0 .AND. aRetCrd[2] > 0      
	
		If Len(aParcelas) > 0 
			For nI := 1 To Len(aParcelas)
				nTotalParc += Round(NoRound(aParcelas[nI][2],4),2)
			Next nI
        Endif

		nSaldo     := 	aRetCrd[2] - (aRetCrd[3] + nTotalParc)
	  	cMsgStatus := 	STR0023 + Transform(aRetCrd[2]	,PesqPict("MAL","MAL_VALOR"))	+ Space(10)	//" Valor do Limite de crédito do cliente: "
		cMsgStatus += 	STR0024 + Transform(nSaldo		,PesqPict("MAL","MAL_VALOR")) 	+ cCRLF    	//" Saldo: "
		cMsgStatus += 	STR0025 + Transform(aRetCrd[3]	,PesqPict("MAL","MAL_VALOR")) 	+ ; 		//" Valor dos títulos em aberto: "
						STR0026 + Transform(nTotalParc	,PesqPict("MAL","MAL_VALOR"))  				//" + Compra Atual: "
	
		DEFINE FONT oFont NAME "Times New Roman" SIZE 9,14                                    
	      
		DEFINE MSDIALOG oDlg FROM 0,0 TO 130,600 TITLE STR0027 PIXEL 	//"Análise de Crédito"
		           
	 	   @ 03, 002 TO  45, 297 LABEL STR0028 OF oDlg PIXEL  			//"Status"
		   @ 12, 005 SAY oMsgStatus VAR cMsgStatus PIXEL FONT oFont
	 	   				   				
		   DEFINE SBUTTON FROM 50,268 TYPE 01 ACTION oDlg:End() ENABLE				         
		
		ACTIVATE MSDIALOG oDlg CENTERED
	
	Endif
Else		
   Conout("40. TMKA273D -  Tk273ConsCred - aRetCrd" + STR0064)		//na consulta zerado"
Endif

Return(lRet)		


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273SetCred ºAutor  ³ Vendas Clientes º Data ³  06/21/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Atualizacao das variaveis staticas de controle.             º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³lExp1 := Operador configurado para SIGACRD                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Retorno Nil                                                 º±±
±±º          ³                                                            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER - TELEVENDAS                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function Tk273SetCred()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ao finalizar a gravacao, atualiza as variaveis staticas.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Conout("41. TMKA273D " + STR0065 +;		//Inicializa variaveis  "
		STR0038 + If( Empty(cContrato), "", cContrato) )	//"Contrato: "
aCrdCliente := {"",""}
cContrato   := Space(TamSX3("MA7_CONTRA")[1])
aInfMA7     := {}
aInfMAH     := {}
aInfMAL     := {}

Return Nil


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273AtuPen ºAutor  ³ Vendas Clientes  º Data ³  06/22/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Preparacao para chamar a funcao que cancela contrato        º±±
±±º          ³que nao gerou orcamento nem pedido.                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³lExp1 := Operador configurado para SIGACRD                  º±±
±±º          ³lExp2 := Define se deve perguntar sobre cancelar o contrato º±±
±±º          ³ou nao 												      º±±
±±º          ³lExp3 := Define se eh chamado da gravacao do documento	  º±±
±±º          ³lExp4 := Define se eh chamado do cancelamento da operacao   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Retorno Nil                                                 º±±
±±º          ³                                                            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER - TELEVENDAS                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function Tk273AtuPen( lSigaCRD, lPergunta, lGravaDoc, lCancelaOp )

DEFAULT lSigaCRD 	:= .F.
DEFAULT lPergunta 	:= .F.    //Se sair da rotina(botao Cancelar) e o contrato nao estiver associado ao SUA deve perguntar ao usuario se cancela ou nao 
DEFAULT lGravaDoc 	:= .F.    //Define se a chamada eh feita de uma gravacao. 
DEFAULT lCancelaOp 	:= .F.    //Define se a chamada ef feita do cancelamento da operacao de atendimento

/*Contempla as seguintes situacoes:
1- Sair do atendimento sem gravar apos a consulta
2- Final da gravacao do atendimento
3- Troca de cliente apos ter gerado contrato
4- Trocar a condicao de pagamento por dinheiro
*/

If lSigaCRD 
	
	If Len(aContrTmp) > 0
		Conout("42. TMKA273D - Tk273AtuPen -" + STR0055 + "CrdAtuPend ")		//Chama a funcao
		
		CrdAtuPend( "SUA"     ,10      ,aContrTmp    ,lGravaDoc    ,;
		            lPergunta )
		            
		aContrTmp:= {}
	Endif		

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Os dados devem ser restaurados apenas se cancelar o atendimento     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ			 
   	If !Empty(cContrato) .AND. !INCLUI .AND. lCancelaOp
   		If	Len(aInfMAH) > 0 .AND. Len(aInfMAL)> 0 .AND. Len(aInfMA7) > 0
   		
 		   Conout("43.TMKA273D - Tk273AtuPen - " +;
 		   		 STR0038 + cContrato +;		//" Contrato: "
 		   		 STR0048 + If (Empty(M->UA_CLIENTE	), "", M->UA_CLIENTE) )		//" Cliente: " 
 		   		   		
		   CrdRestInfCRD( cContrato     ,aInfMAH    ,aInfMAL   ,aInfMA7   ,;
		                  M->UA_CLIENTE ,M->UA_LOJA )   
		   aInfMA7    := {}
		   aInfMAH    := {}
		   aInfMAL    := {}
		Else    
			Conout("44.TMKA273D - Tk273AtuPen - " +;
					"Len(aInfMAH) : " + Alltrim(STR(Len(aInfMAH))) +; 
					"Len(aInfMAL) : " + Alltrim(STR(Len(aInfMAL))) +;
					"Len(aInfMA7) : " + Alltrim(STR(Len(aInfMA7))) +;
					STR0066 + " CrdRestInfCRD ")       //" Nao chamou a funcao
			
		Endif
	Else
		Conout("45.TMKA273D - Tk273AtuPen " +;
				STR0038 + If( Empty(cContrato), "", cContrato) +; 	//" Contrato: "
				STR0067 + If(INCLUI, ".T.", ".F.") +;		//" INCLUI : "
				" lCancelaOp : " + If(lCancelaOp, ".T.", ".F.") )
				
	Endif			
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Atualizacao da variavel aCrdCliente de modo                         ³
	//³a limpa-la caso um contrato seja rejeitado e o usuario sair da venda³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aCrdCliente) > 0
		If !Empty(aCrdCliente[1]+aCrdCliente[2])
		    Conout(STR0068)		//"46. TMKA273D Zera aCrdCliente no AtuPen"
			aCrdCliente := {"",""}
		Endif
	Endif		
Endif
	
Return (Nil)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273RestCRDºAutor  ³ Vendas Clientes  º Data ³  27/06/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Armazena os dados dos arquivos MAH e MAL se o orcamento tem º±±
±±º			 ³um contrato de financiamento associado. Sera utilizado caso º±±
±±º			 ³o usuario nao confirme a operacao, pois deve voltar o backupº±±
±±º			 ³destes arquivos para atualizar a base de dados              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºSintaxe   ³ Tk273RestCtr(ExpC1, ExpC2, ExpC3)					      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ExpC1 - Numero do contrato 								  º±±
±±º          ³ExpC2 - Codigo do cliente 								  º±±
±±º          ³ExpC3 - Loja do cliente 								      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Nenhum			 									      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CALL CENTER - TELEVENDAS                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Tk273RestCRD(cNumContra, cCodClie, cLoja)

Local aArea    := GetArea()      // Area atual

Conout("47. TMKA273D" + STR0069 + "Tk273RestCRD " +;  //entrou no
		STR0038 + If(Empty(cNumContra),"",cNumContra) +;	//" Contrato: "
		STR0048  + If(Empty(cCodClie),"",cCodClie) +;      //" Cliente: "
		"/" 		  + If(Empty(cLoja),"",cLoja))

DbSelectArea("MA7")
DbSetOrder(1)
If DbSeek(xFilial("MA7")+cCodClie+cLoja)
   aInfMA7    := {}
   Aadd(aInfMA7, MA7->MA7_DATABL )   
   Aadd(aInfMA7, MA7->MA7_HORABL )
   Aadd(aInfMA7, MA7->MA7_USRBL  )   
   Aadd(aInfMA7, MA7->MA7_MOTBL  )
   Aadd(aInfMA7, MA7->MA7_VLRBL  )   
   Aadd(aInfMA7, MA7->MA7_BLOQUE )
   Aadd(aInfMA7, MA7->MA7_DTHRDS )   
   Aadd(aInfMA7, MA7->MA7_LC     )
   Aadd(aInfMA7, MA7->MA7_ARQPRO )   
   Aadd(aInfMA7, MA7->MA7_ARQPAR )   
Endif

DbSelectArea("MAH")
DbSetOrder(1)
If DbSeek(xFilial("MAH")+cNumContra)
   aInfMAH    := {}
   Aadd(aInfMAH, MAH->MAH_CONTRA )
   Aadd(aInfMAH, MAH->MAH_EMISSA )
   Aadd(aInfMAH, MAH->MAH_DTTRN  )
   Aadd(aInfMAH, MAH->MAH_HRTRN  ) 
   Aadd(aInfMAH, MAH->MAH_PDVTRN )                    
   Aadd(aInfMAH, MAH->MAH_CXTRN  ) 
   Aadd(aInfMAH, MAH->MAH_LJTRN  )                    
   Aadd(aInfMAH, MAH->MAH_VLRFIN )                                      
Endif

aInfMAL    := {}
DbSelectArea("MAL")
DbSetOrder(1)
If DbSeek(xFilial("MAL")+cNumContra)
	While !Eof() .AND. xFilial("MAL")+cNumContra == MAL->MAL_FILIAL+MAL->MAL_CONTRA
	   Aadd(aInfMAL, { MAL->MAL_CONTRA ,;
	                   MAL->MAL_PARCEL ,; 
	                   MAL->MAL_VENCTO ,;                    
	                   MAL->MAL_VALOR  ,; 
	                   MAL->MAL_SALDO  })
	   DbSkip()                   
	End
Endif

RestArea(aArea)

Return (NIL)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273SetCoºAutor  ³ Vendas Clientes    º Data ³  20/06/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Atualiza variaveis de contrato na Alteracao do atendimento  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºSintaxe   ³ Tk273SetContra()           								  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³Nenhum 													  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Nenhum 												  	  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ TeleVendas                                                 º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Tk273SetContra()

cContrato    := SUA->UA_CONTRA
If !Empty(cContrato)
   AAdd(aContrTmp,{cContrato,SUA->UA_CLIENTE,SUA->UA_LOJA})
   	  Conout("48.TMKA273D - Tk273SetContra -" + STR0070 + SUA->UA_CLIENTE + SUA->UA_LOJA +;   //CLIENTE+LOJA: "
	               STR0038 + cContrato +;		//" Contrato: "
	      		   STR0071 + " aContrTmp" )	   //" Preenche
Else
	Conout("49.TMKA273D - Tk273SetContra - " + STR0070 + SUA->UA_CLIENTE + SUA->UA_LOJA +;     //CLIENTE+LOJA: "
	      		   STR0072 )		//" Contrato vazio "
   
Endif   

Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³Tk273GeraTefºAutor  ³ Vendas Clientes  º Data ³  22/11/05   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Grava os dados da transacao TEF no arquivo SL4 quando se   º±±
±±º			 ³ esta utilizando a DLL CLISITEF.                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºSintaxe   ³ Tk273GeraTef(ExpD1, ExpC2, ExpC3, ExpC4, ExpC5, ExpC6,; 	  º±±
±±º          ³              ExpC7, ExpN8)                              	  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ExpD1 - Data               								  º±±
±±º          ³ExpC2 - Forma Pagto       								  º±±
±±º          ³ExpC3 - ID Cartao       								      º±±
±±º          ³ExpC4 - Banco           								      º±±
±±º          ³ExpC5 - Agencia         								      º±±
±±º          ³ExpC6 - Cheque          								      º±±
±±º          ³ExpC7 - Administradora  								      º±±
±±º          ³ExpN8 - Posicao no array								      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³Nenhum			 									      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ CALL CENTER - TELEVENDAS                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Tk273GeraTef(dData,	cForma,		cIDCart,	cBco, ;
					  cAge,		cChq,		cAdm,		nPosArray)
                                             
Local nPos			:= 0		//Posicao dentro do array
Local nPosAdm		:= 0		//Posicao da adm. financeira

Default dData 		:= CtoD("")
Default cForma		:= ""
Default cIDCart		:= ""
Default cBco		:= ""
Default cAge		:= ""
Default cChq		:= ""
Default cAdm		:= ""   
Default nPosArray	:= 1

If AllTrim(cForma) $ "CC"
	nPos := Ascan(oTEF:aRetCartao, {|x| AllTrim(x:cForma)+AllTrim(x:cIDCart) == AllTrim(cForma)+AllTrim(cIDCart) } )
ElseIf AllTrim(cForma) == "CH"
	nPos := Ascan(oTEF:aRetCartao, {|x| AllTrim(x:cForma)+AllTrim(x:cChqBco)+AllTrim(x:cChqAge)+AllTrim(x:cChqNum) == AllTrim(cForma)+AllTrim(cBco)+Alltrim(cAge)+Alltrim(cChq) } )
EndIf

If nPos > 0
	SL4->L4_VENDTEF	:= "S"
	SL4->L4_DATATEF	:= oTef:cData
	SL4->L4_HORATEF	:= oTef:aRetCartao[nPos]:cHoraTrans
	SL4->L4_DOCTEF	:= oTef:aRetCartao[nPos]:cNsuAutor
	SL4->L4_AUTORIZ	:= oTef:aRetCartao[nPos]:cAutoriza	
	SL4->L4_ADMINIS	:= oTef:aRetCartao[nPos]:cCodAdm	
	SL4->L4_INSTITU	:= oTef:aRetCartao[nPos]:cDescAdm	
	SL4->L4_NSUTEF	:= oTef:aRetCartao[nPos]:cNsuSitef
	SL4->L4_TIPCART	:= oTef:aRetCartao[nPos]:cTipCart
	SL4->L4_FORMAID := oTef:aRetCartao[nPos]:cIDCart
	//Tipo de Parcelamento ("0" - Estabelecimento / "1" - Administradora) + Quantidade de Parcelas
	SL4->L4_PARCTEF := If(oTef:aRetCartao[nPos]:lJurLoja,"0","1")+StrZero(oTef:aRetCartao[nPos]:nParcelas,2)
	
Endif	

Return nil

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³Tk273TEFAceParc³Autor ³ Vendas Clientes   ³ Data ³ 23/11/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Corrige as datas das parcelas no array originario da inter-³±±
±±³          ³ face                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ CALL CENTER - TeleVendas                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Tk273TEFAceParc(aParcelas)
Local nX 		:= 0                      				//Contador de laço
Local nY 		:= 0									//Contador de laço
Local nPos 		:= 0 									//Verifica qual posicao da array é correspondente a esta transacao TEF
Local lAltera	:= .F.									//Indica se havera alteracao da parcela

//Processar todas as transacçes efetuadas e atualizar a array da interface para processamento de gravacao do financeiro
For nX := 1 To Len(oTEF:aRetCartao)

	//Se for cartao a localizacao se da atraves da forma de pagamento e o seu respectivo ID indicado na interface de vendas
	If oTEF:aRetCartao[nX]:cForma $ "CC"
		nPos := Ascan(aParcelas, {|x| AllTrim(x[6]) == AllTrim(oTEF:aRetCartao[nX]:cIDCart) } )

		//Vou verificar se a ADM foi informada corretamente
		LjTEFConfADM(nX,aParcelas[nPos][4])
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se a venda for do Tipo CDC existe um tratamento especial                                     ³
		//³para recalculo de datas e valores, pois o operador podera alterar a data e o valor da entrada³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If oTef:nCodTrans == 19 
			If nPos > 0
				//O numero da parcela corresponde a array aDatas do retorno
				nParc 	:= 0 
				lAltera := .F.
				For nY 	:= nPos To Len(aParcelas)
					If AllTrim(aParcelas[nY][3])+AllTrim(aParcelas[nY][6]) == AllTrim(oTEF:aRetCartao[nX]:cForma)+AllTrim(oTEF:aRetCartao[nX]:cIDCart)
						nParc += 1
						aParcelas[nY][1] 	:= oTEF:aRetCartao[nX]:aDatas[nParc]
						aParcelas[nY][2]	:= oTEF:aRetCartao[nX]:aValores[nParc]
					EndIf
				Next nY
			EndIf				
	    EndIf					
		
	ElseIf oTEF:aRetCartao[nX]:cForma == "CH"
		//Os cheques serão localizados pelo Banco/Agencia/Numero
		nPos := Ascan(aParcelas, {|x| AllTrim(x[03])+Substr(AllTrim(x[04]),1,3)+Substr(AllTrim(x[04]),4,5)+Substr(AllTrim(x[04]),28,6) == AllTrim(oTEF:aRetCartao[nX]:cForma)+AllTrim(oTEF:aRetCartao[nX]:cChqBco)+AllTrim(oTEF:aRetCartao[nX]:cChqAge)+AllTrim(oTEF:aRetCartao[nX]:cChqNum)})
		If nPos > 0 .AND. aParcelas[nPos][1] <> oTEF:aRetCartao[nX]:aDatas[1]
			aParcelas[nPos][1] := oTEF:aRetCartao[nX]:aDatas[1]
		EndIf
	EndIf
	
Next nX

Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273DelLojºAutor  ³ Vendas CRM        º Data ³  30/04/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Controla o orcamento gravado no sigaloja (MV_TMKLOJ),       º±±
±±º          ³integração entre Call Center e Controle de Lojas, e que     º±±
±±º          ³foi utilizado pelo faturamento. Se houver geracao de pedido º±±
±±º          ³de vendas ou nota fiscal, o orçamento será apagado          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ExpN1 - operacao escolhida (Alteracao/ Visualizacao)        º±±
±±º          ³ExpC2 - numero do numero do atendimento,orcamentogravado    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER                                                 º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Tk273DelLoj(nOpc,cNumSL1)

Local cTMKLOJ		:= SuperGetMv("MV_TMKLOJ")
Local cNumAten      := "" 
Local cReserva		:= ""
Local aAreaSUA	 	:= SUA->(GetArea())

If nOpc == 4 .And. cTMKLOJ == "S" 
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Apaga os items da forma de pagamento do SL4         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SL4")
	DbSetOrder(1)
	If DbSeek(xFilial("SL4") + cNumSL1 +"")  //Nao preenche a ORIGEM porque e um ORCAMENTO DO SIGALOJA
		While !Eof() 						   .AND. ;
			(SL4->L4_FILIAL == xFilial("SL4")) .AND. ;
			(SL4->L4_NUM == cNumSL1) 		   .AND. ;
			(ALLTRIM(SL4->L4_ORIGEM) == "")
		
			RecLock("SL4",.F.,.T.)
			DbDelete()
			MsUnlock()
			SL4->(DbSkip())
		End
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Apaga os items do orcamento SL2                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SL2")
	DbSetOrder(1)
	If DbSeek(xFilial("SL2") + cNumSL1)  
		While !Eof() 						   .AND. ;
			(SL2->L2_FILIAL == xFilial("SL2")) .AND. ;
			(SL2->L2_NUM == cNumSL1) 		   
			 
			cReserva := ""
			If !Empty (SL2->L2_RESERVA)
		   		cReserva := SL2->L2_RESERVA		   		
			EndIf				
			RecLock("SL2",.F.,.T.)
			SL2->L2_RESERVA	:= ""
			SL2->L2_LOJARES	:= ""	
			DbDelete()
			MsUnlock()
			If !Empty (cReserva)
		   		Tk273DelRes(cReserva)	   		
			EndIf			
			SL2->(DbSkip())
		End
	Endif
			
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Apaga o cabecalho do orcamento SL1                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SL1")
	DbSetOrder(1)
	If DbSeek(xFilial("SL1") + cNumSL1 )  
	    cNumAten := SL1->L1_NUMATEN 
		While !Eof() 						   .AND. ;
			(SL1->L1_FILIAL == xFilial("SL1")) .AND. ;
			(SL1->L1_NUM == cNumSL1) 		
			
			RecLock("SL1",.F.,.T.)
			SL1->L1_RESERVA	:= ""
			DbDelete()
			MsUnlock()
			SL1->(DbSkip())
		End
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Limpa orcamento deletado do Atendimento.            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SUA")
	DbSetOrder(1)
	If DbSeek(xFilial("SUA") + cNumAten) 
	   RecLock("SUA",.F.) 
	   Replace SUA->UA_NUMSL1 WITH SPACE(TamSx3("UA_NUMSL1")[1])	   
	   MsUnlock()		
	EndIF
EndiF

RestArea(aAreaSUA)
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273DelResºAutor  ³ Vendas CRM        º Data ³  24/03/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Deleta a reserva                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ExpN1 - Codigo da reserva                                   º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER                                                 º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Tk273DelRes(cReserva)

DbSelectArea("SC0")
DbSetOrder(1)
If DbSeek(xFilial("SC0") + cReserva)  
	While !Eof() 						   .AND. ;
		(SC0->C0_FILIAL == xFilial("SC0")) .AND. ;
		(SC0->C0_NUM == cReserva) 	  	
		
		If SB2->( DbSeek( xFilial("SB2") + SC0->C0_PRODUTO + SC0->C0_LOCAL )  )
			GravaB2Emp("-", SC0->C0_QTDORIG, "X" , .T. , )
		EndIf
		Reclock( "SC0", .F. )
		SC0->( dbDelete() )
		SC0->( MsUnLock () )
		
		SC0->(DbSkip())
	End
Endif

Return() 

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Tk273UnlockºAutor  ³ Vendas CRM        º Data ³  12/02/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Destrava os registros da tabela SB2.                       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³							                                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³CALL CENTER                                                 º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Tk273Unlock(aTravaSB2)

Local nX := 0

If Len(aTravaSB2) > 0
	For nX := 1 To Len(aTravaSB2)
		SB2->(MsRUnlock(aTravaSB2[nX]))
	Next nX					
EndIf

Return
