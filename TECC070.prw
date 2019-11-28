#INCLUDE "Protheus.ch"
#INCLUDE "TECC070.ch"
#INCLUDE "Tecc070_Def.ch"

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECC070
Central do Cliente do Gestão de Serviços
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function TECC070()
	Local oTree		:= Nil
	Local dDataDe	:= Nil
	Local dDataAte	:= Nil

	Private cCodCli := ""
	Private cLojCli	:= ""
	Private cNomCli	:= ""
	
	Private aObjGetD:= {}
	Private oDlg	:= Nil
	Private oBox1	:= Nil
	Private oPanel	:= Nil

	//Pergunta qual cliente deseja consultar
	If Pergunte("TECC070",.T.)

		//Carrega os dados do cliente
		cCodCli := Padr(MV_PAR01,TamSX3("A1_COD")[1])
		cLojCli := Padr(MV_PAR02,TamSX3("A1_LOJA")[1])
		cNomCli := Alltrim(Posicione("SA1",1,xFilial('SA1')+cCodCli+cLojCli,"A1_NOME"))
		dDataDe := Stod("  /  /    ")
		dDataAte:= Stod("  /  /    ")
	
		//Pinta a Dialog Principal
		TC070Paint(cCodCli,cLojCli,dDataDe,dDataAte,@oTree)
		
		//Exibe a interface ao usuario
		Tc070Show()
		
		//Destroi os objetos graficos da memoria
		Tc070DestroyAll()
	EndIf 
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} TC070Paint
"Pinta" a dialog principal da rotina de Central do Cliente
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070Paint(cCodCli,cLojCli,dDataDe,dDataAte,oTree)
	Local cUrl := Tc071CliUrl(cCodCli,cLojCli) 
	
	//Monta a janela principal³
	oDlg:= MSDIALOG():Create()
	oDlg:cName     		:= "oDlg"
	oDlg:cCaption  		:= STR0001
	oDlg:nLeft     		:= 0
	oDlg:nTop      		:= 0
	oDlg:nWidth    		:= Tc070Res(98,.T.) 
	oDlg:nHeight   		:= Tc070Res(85,.F.)
	oDlg:lShowHint 		:= .F.
	oDlg:bInit			:= {|| EnchoiceBar(oDlg, {||( oDlg:End() )} , {||( oDlg:End() )} ,, Tc070UsrBut(cCodCli) ) }
	oDlg:lCentered 		:= .T.

	//Pinta o box da esquerda "Opções de Consulta"
	oBox1:= TGROUP():Create(oDlg)
	oBox1:cName 	   := "oBox1"
	oBox1:cCaption     := STR0002 	//Opções de Consulta
	oBox1:nLeft 	   := 20
	oBox1:nTop  	   := 70
	oBox1:nWidth 	   := oDlg:nWidth - (oDlg:nWidth * 80 / 100) 
	oBox1:nHeight 	   := oDlg:nHeight - (oDlg:nHeight * 15 / 100)
	oBox1:lShowHint    := .F.
	oBox1:lReadOnly    := .F.
	oBox1:Align        := 0
	oBox1:lVisibleControl := .T.
	
	//Monta o Tree dentro da Box 1
	oTree:= TTree():New(,,,,oDlg)
	oTree:nTop 		:= oBox1:nTop + 20
	oTree:nLeft 	:= oBox1:nLeft + 10
	oTree:nWidth 	:= oBox1:nWidth - 20
	oTree:nHeight 	:= oBox1:nHeight - 40
	oTree:bLClicked := {|| Tc070LoadData(oTree:CurrentNodeID,cCodCli,cLojCli,dDataDe,dDataAte,oTree) }
	oTree:nClrPane 	:= CLR_WHITE	
	oTree:PTSendTree(Tc070GetOpc())
			
	//Monta o TPanel		
	oPanel := tPanel():New()
	oPanel:oWnd		:= oDlg
	oPanel:nTop 	:= oTree:nTop 
	oPanel:nLeft	:= oTree:nLeft + oTree:nWidth + 20
	oPanel:nWidth 	:= oDlg:nWidth - (oTree:nLeft + oTree:nWidth + 20 + 20)
	oPanel:nHeight 	:= oTree:nHeight
	//oPanel:nClrPane	:= CLR_YELLOW
	
	//Forceps Click on Main Node
	oTree:PTGotoToNode(M_CLIENTE)	
	Tc070NewBrw(M_CLIENTE,cURL)
	
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070GetOpc
Retorna um array opções de consulta disponiveis no layout de "arvore"
A montagem do array esta condicionada ao controle de alcadas do GS 
Para remocao de campos RECOMENDAR O USO DO CONTROLE DE X3_NIVEL no Usuario
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070GetOpc()
	Local aRet := {}
	Local cCliInfo := cCodCli + " - " + cNomCli
	Local cIcoGrpOff 	:= "FOLDER5"
	Local cIcoGrpOn 	:= "FOLDER6"
	Local cIcoItnOff 	:= "BRW_LUPA"
	Local cIcoItnOn 	:= "BRW_LUPA"
	
	//Cliente
	aadd(aRet, {M_RAIZ		,M_CLIENTE		,"", cCliInfo  	,cIcoGrpOff	,cIcoGrpOn	} ) //Codigo + Nome do Cliente
	
	//Oportunidades
	If Tc070ChkOpt(M_OPORT)
		aadd(aRet, {M_CLIENTE	,M_OPORT		,""	,STR0003	,cIcoGrpOff	,cIcoGrpOn	} )	//"Oportunidades"
		aadd(aRet, {M_OPORT		,I_OP_SEMPROP	,""	,STR0004	,cIcoItnOff ,cIcoItnOn} ) //"Sem Proposta"
		aadd(aRet, {M_OPORT		,I_OP_EMABERT	,""	,STR0005	,cIcoItnOff	,cIcoItnOn} ) //"Em Aberto"
		aadd(aRet, {M_OPORT		,I_OP_ENCERRA	,""	,STR0006	,cIcoItnOff	,cIcoItnOn} ) //"Encerradas"
		aadd(aRet, {M_OPORT		,I_OP_CANCELA	,""	,STR0007	,cIcoItnOff	,cIcoItnOn} ) //"Canceladas"
	EndIf
	
	//Propostas
	If Tc070ChkOpt(M_PROPOSTAS)
		aadd(aRet, {M_CLIENTE	,M_PROPOSTAS	,""	,STR0008	,cIcoGrpOff	,cIcoGrpOn	} ) //"Propostas"
		aadd(aRet, {M_PROPOSTAS	,I_PR_EMABER	,""	,STR0009	,cIcoItnOff	,cIcoItnOn} ) //"Em aberto"
		aadd(aRet, {M_PROPOSTAS	,I_PR_FINALI	,""	,STR0010	,cIcoItnOff	,cIcoItnOn} ) //"Finalizadas"
		aadd(aRet, {M_PROPOSTAS	,I_PR_VISTEC	,""	,STR0043	,cIcoItnOff	,cIcoItnOn} ) //"Vistorias Tecnica"
	EndIf
			
	//Contratos
	If Tc070ChkOpt(M_CONTRATOS)
		aadd(aRet, {M_CLIENTE 	,M_CONTRATOS	,""	,STR0011	,cIcoGrpOff	,cIcoGrpOn	} ) //"Contratos"
		aadd(aRet, {M_CONTRATOS	,I_CT_VIGENT	,""	,STR0012	,cIcoItnOff	,cIcoItnOn} ) //"Vigentes"
		aadd(aRet, {M_CONTRATOS	,I_CT_ENCERR	,""	,STR0013	,cIcoItnOff	,cIcoItnOn} ) //"Encerrados"	
		aadd(aRet, {M_CONTRATOS	,I_CT_MEDICA	,""	,STR0044	,cIcoItnOff	,cIcoItnOn} ) //"Medicoes"
	EndIf
			
	//Financeiro
	If Tc070ChkOpt(M_FINANCEIR)
		aadd(aRet, {M_CLIENTE	,M_FINANCEIR	,""	,STR0014	,cIcoGrpOff	,cIcoGrpOn	} ) //"Financeiro"		
		aadd(aRet, {M_FINANCEIR ,I_FI_PRVABE	,""	,STR0063	,cIcoItnOff	,cIcoItnOn} ) //"Provisórios em dia"
		aadd(aRet, {M_FINANCEIR	,I_FI_PRVVEN	,""	,STR0064	,cIcoItnOff	,cIcoItnOn} ) //"Provisórios Vencidos" 
		aadd(aRet, {M_FINANCEIR ,I_FI_TITABE	,""	,STR0015	,cIcoItnOff	,cIcoItnOn} ) //"Titulos em Aberto"
		aadd(aRet, {M_FINANCEIR	,I_FI_TITBXA	,""	,STR0016	,cIcoItnOff	,cIcoItnOn} ) //"Titulos Baixados" 
		aadd(aRet, {M_FINANCEIR	,I_FI_TITVEN	,""	,STR0017	,cIcoItnOff	,cIcoItnOn} ) //"Titulos Vencidos"
	Endif

	//Faturamento
	If Tc070ChkOpt(M_FATURAMEN)
		aadd(aRet, {M_CLIENTE 	,M_FATURAMEN	,""	,STR0018	,cIcoGrpOff	,cIcoGrpOn	} ) //"Faturamento"
		aadd(aRet, {M_FATURAMEN	,I_FT_PEDABE	,""	,STR0019	,cIcoItnOff	,cIcoItnOn} ) //"Pedidos em Aberto"
		aadd(aRet, {M_FATURAMEN	,I_FT_PEDFAT	,""	,STR0020	,cIcoItnOff	,cIcoItnOn} ) //"Pedidos Faturados"	
		aadd(aRet, {M_FATURAMEN	,I_FT_NOTSRV	,""	,STR0040	,cIcoItnOff	,cIcoItnOn} ) //"NF (Serviço)"
		aadd(aRet, {M_FATURAMEN	,I_FT_NOTREM	,""	,STR0041	,cIcoItnOff	,cIcoItnOn} ) //"NF (Remessa)"
		aadd(aRet, {M_FATURAMEN	,I_FT_NOTRET	,""	,STR0042	,cIcoItnOff	,cIcoItnOn} ) //"NF (Retorno)"
		aadd(aRet, {M_FATURAMEN	,I_FT_NOTOTR	,""	,STR0045	,cIcoItnOff	,cIcoItnOn} ) //"NF (Outros)"
	EndIf
	
	//Locais de Atendimento
	If Tc070ChkOpt(M_LOCAISATE)
		aadd(aRet, {M_CLIENTE	,M_LOCAISATE	,""	,STR0021	,cIcoGrpOff	,cIcoGrpOn	} ) //"Locais de Atendimento"
		aadd(aRet, {M_LOCAISATE	,I_LA_CONTRA	,""	,STR0022	,cIcoItnOff	,cIcoItnOn} ) //"Atendidos"
		aadd(aRet, {M_LOCAISATE	,I_LA_SEMCON	,""	,STR0023	,cIcoItnOff	,cIcoItnOn} ) //"Sem Contrato"
	EndIf
	
	//Equipamentos
	If Tc070ChkOpt(M_EQUIPAMEN)
		aadd(aRet, {M_CLIENTE	,M_EQUIPAMEN	,""	,STR0024	,cIcoGrpOff	,cIcoGrpOn	} ) //"Equipamentos"	
		aadd(aRet, {M_EQUIPAMEN	,I_EQ_RESERV	,""	,STR0025	,cIcoItnOff	,cIcoItnOn} ) //"Reservados"
		aadd(aRet, {M_EQUIPAMEN	,I_EQ_ASEPAR	,""	,STR0028	,cIcoItnOff	,cIcoItnOn} ) //"A Separar"
		aadd(aRet, {M_EQUIPAMEN	,I_EQ_SEPARA	,""	,STR0048	,cIcoItnOff	,cIcoItnOn} ) //"Separados"
		aadd(aRet, {M_EQUIPAMEN	,I_EQ_LOCADO	,""	,STR0026	,cIcoItnOff	,cIcoItnOn} ) //"Locados"
		aadd(aRet, {M_EQUIPAMEN	,I_EQ_DEVOLV	,""	,STR0027	,cIcoItnOff	,cIcoItnOn} ) //"Devolvidos"
	EndIf
	
	//Recursos Humanos
	If Tc070ChkOpt(M_RECHUMANO)
		aadd(aRet, {M_CLIENTE	,M_RECHUMANO	,""	,STR0029	,cIcoGrpOff	,cIcoGrpOn	} ) //"Recursos Humanos"	
		aadd(aRet, {M_RECHUMANO ,I_RH_POSTOS	,""	,STR0030	,cIcoItnOff	,cIcoItnOn} ) //"Postos RH"
		aadd(aRet, {M_RECHUMANO ,I_RH_ATEND		,""	,STR0031	,cIcoItnOff	,cIcoItnOn} ) //"Atendentes (Histórico)"
		aadd(aRet, {M_RECHUMANO ,I_RH_ATFUT		,""	,STR0046	,cIcoItnOff	,cIcoItnOn} ) //"Atendentes (Alocados)"
	EndIf
	
	//Ordens de Serviço
	If Tc070ChkOpt(M_ORDSERICO)
		aadd(aRet, {M_CLIENTE	,M_ORDSERICO	,""	,STR0032	,cIcoGrpOff	,cIcoGrpOn	} ) //"Ordens de Serviço"
		aadd(aRet, {M_ORDSERICO	,I_OS_SIGTEC	,""	,STR0033	,cIcoItnOff	,cIcoItnOn} ) //"OS SIGATEC"
		aadd(aRet, {M_ORDSERICO	,I_OS_SIGMNT	,""	,STR0034	,cIcoItnOff	,cIcoItnOn} ) //"OS SIGAMNT"
	EndIf	
	
	//Armamentos
	If Tc070ChkOpt(M_ARMAMENTO)
		aadd(aRet, {M_CLIENTE	,M_ARMAMENTO	,""	,STR0035	,cIcoGrpOff	,cIcoGrpOn	} ) //"Armamentos"
		aadd(aRet, {M_ARMAMENTO	,I_AR_ARMAS		,""	,STR0036	,cIcoItnOff	,cIcoItnOn} ) //"Armas"
		aadd(aRet, {M_ARMAMENTO	,I_AR_COLETE	,""	,STR0037	,cIcoItnOff	,cIcoItnOn} ) //"Coletes"
		aadd(aRet, {M_ARMAMENTO	,I_AR_MUNICO	,""	,STR0038	,cIcoItnOff	,cIcoItnOn} ) //"Munições"
	EndIf
		
Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070RgtClk	
Funcao responsavel por criar um menu de opções ao clique direito do mouse
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070RgtClk(cNodeId,aHeader,aCols,x,y,w,z,nType,oObj)
	Local cCliInfo := cCodCli + " - " + cNomCli
	Local oMenu
	Local aMenu			:= {}
	Local aUsrButons	:= {}
	Local nI			:= 0
	Local nMouseX		:= 0
	Local nMouseY		:= 0

	//Array com os itens a serem exibidos no menu
	If nType == GETDADOS
		Aadd( aMenu , { STR0047 , '{|| Tc072Print(aHeader,cNodeId,cCliInfo,aCols) }' , "BRW_PRINT" , STR0047, .T.	} ) //"Imprimir Consulta"
		nMouseX	:= x + 200
		nMouseY	:= y + 200
	ElseIf nType == FWGRAPH
		Aadd( aMenu , { STR0059 , '{|| Tc073SavePng(cNodeId,oObj) }' , "SALVAR" , STR0059, .T.	} ) //"Salvar Imagem"
		nMouseX	:= w
		nMouseY	:= x 
	EndIf
	
	
	/*Ponto de entrada utilizado para inclusao de itens de menu customizados
		Retorno    : Array contendo as rotinas a serem adicionados no menu
					[1] : Titulo
					[2] : Codeblock contendo a funcao do usuario
					[3] : Resource utilizado no bitmap
					[4] : Tooltip do bitmap*/
	If ExistBlock("Tc070RgtClk")	
		aUsrButons := ExecBlock("Tc070RgtClk", .F., .F.,{__cUserID,cNodeId,aHeader,aCols})
		For nI := 1 To Len(aUsrButons)
			aAdd(aMenu,{aUsrButons[nI,1],aUsrButons[nI,2],aUsrButons[nI,3],aUsrButons[nI,4],.T.})
		Next nI
	EndIf

	//Monta o menu com os itens de aMenu
	MENU oMenu POPUP
	For nI:= 1 To Len(aMenu)	
	        MenuAddItem( aMenu[nI,1] ,/*<cMsg>*/,/*<.checked.>*/,.T.,/*aMenu[nI,2]*/,/*<cBmpFile>*/,aMenu[nI,3],oMenu,;
					     &(aMenu[nI][2]),/*<nState>*/,/*<nVirtKey>*/,/*<.help.>*/,/*<nHelpId>*/,/*[<{uWhen}>]*/,/*<.break.>*/ )
	Next nI
	ENDMENU

	//Exibe o menu		
	ACTIVATE POPUP oMenu AT nMouseX, nMouseY
Return  

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070LoadData
Funcao primaria que carrega os dados de uma determinada consulta de clientes recebida
por parametro. Executa a funcao Tc070Search responsavel por coletar os dados
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070LoadData(cNodeID,cCodCli,cLojCli,dDataDe,dDataAte,oTree)
	Local lRet := .F.	
	Processa({|| lRet := Tc070Search(cNodeID,cCodCli,cLojCli,dDataDe,dDataAte,oTree), STR0039 }) //"Aguarde, buscando dados"
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070Search
Funcao primaria que carrega os dados de uma determinada consulta de clientes recebida
por parametro. Para cada nó da arvore existe uma funcao especifica de pesquisa e de 
carregamento da Header e aCols - Quando for um item. Quando for uma pasta, carrega um FWCHartBar
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070Search(cNodeID,cCodCli,cLojCli,dDataDe,dDataAte,oTree)
	Local aGrid		:= {}
	Local aGraph	:= {}
	Local lGraph	:= .F.
	Local cURL		:= ""
	Local aCols		:= {}
	Local aHeader	:= {}
	
	Default cNodeID := ""
	
	If !(Empty(cNodeID))
		Do Case
			
			//"Nó "mae" da arvore"
			Case cNodeID == M_RAIZ
				cURL := Tc071CliUrl(cCodCli,cLojCli)
				
			//"Nome do Cliente"		
			Case cNodeID == M_CLIENTE
				cURL := Tc071CliUrl(cCodCli,cLojCli)				
				
			//Oportunidade
			Case cNodeID == M_OPORT
				aGrid := Tc073LoadGph(M_OPORT,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.

			//Sem Proposta
			Case cNodeID == I_OP_SEMPROP
				aGrid := Tc071OpNoProp(cCodCli,cLojCli,dDataDe,dDataAte) 
				
			//Em Aberto
			Case cNodeID == I_OP_EMABERT
				aGrid := Tc071OpAberta(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Encerradas
			Case cNodeID == I_OP_ENCERRA
				aGrid := Tc071OpEncerr(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Canceladas
			Case cNodeID == I_OP_CANCELA	
				aGrid := Tc071OpCancel(cCodCli,cLojCli,dDataDe,dDataAte)

			//Propostas
			Case cNodeID == M_PROPOSTAS	
				aGrid := Tc073LoadGph(M_PROPOSTAS,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//Em Aberto
			Case cNodeID == I_PR_EMABER
				aGrid := Tc071PropAb(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Finalizadas			
			Case cNodeID == I_PR_FINALI		
				aGrid := Tc071PropEn(cCodCli,cLojCli,dDataDe,dDataAte)
				
			//Vistorias Técnicas
			Case cNodeID == I_PR_VISTEC		
				aGrid := Tc071PropVT(cCodCli,cLojCli,dDataDe,dDataAte)
								
			//Contratos
			Case cNodeID == M_CONTRATOS
				aGrid := Tc073LoadGph(M_CONTRATOS,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//Vigentes
			Case cNodeID == I_CT_VIGENT
				aGrid := Tc071CtrVig(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Encerrados
			Case cNodeID == I_CT_ENCERR
				aGrid := Tc071CtrEnc(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Medicoes
			Case cNodeID == I_CT_MEDICA
				aGrid := Tc071CtrMed(cCodCli,cLojCli,dDataDe,dDataAte)	

			//Financeiro			
			Case cNodeID == M_FINANCEIR
				aGrid := Tc073LoadGph(M_FINANCEIR,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//Provisorios em dia
			Case cNodeID == I_FI_PRVABE
				aGrid := Tc071TitPAb(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Provisorios Vencidos
			Case cNodeID == I_FI_PRVVEN
				aGrid := Tc071TitPVc(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Titulos em Aberto
			Case cNodeID == I_FI_TITABE
				aGrid := Tc071TitAbr(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Titulos Baixados
			Case cNodeID == I_FI_TITBXA
				aGrid := Tc071TitBxa(cCodCli,cLojCli,dDataDe,dDataAte)
				
			//Titulos Vencidos
			Case cNodeID == I_FI_TITVEN
				aGrid := Tc071TitVnc(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Faturamento
			Case cNodeID == M_FATURAMEN
				aGrid := Tc073LoadGph(M_FATURAMEN,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//Pedidos em Aberto
			Case cNodeID == I_FT_PEDABE
				aGrid := Tc071PedAbr(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Pedidos Faturados
			Case cNodeID == I_FT_PEDFAT
				aGrid := Tc071PedFat(cCodCli,cLojCli,dDataDe,dDataAte)

			//NF (Servico)
			Case cNodeID == I_FT_NOTSRV
				aGrid := Tc071NFSrv(cCodCli,cLojCli,dDataDe,dDataAte)

			//NF (Remessa)
			Case cNodeID == I_FT_NOTREM
				aGrid := Tc071NFRms(cCodCli,cLojCli,dDataDe,dDataAte)

			//NF (Retorno)
			Case cNodeID == I_FT_NOTRET
				aGrid := Tc071NFRet(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//NF (Outros)
			Case cNodeID == I_FT_NOTOTR
				aGrid := Tc071NFOut(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Locais de Atendimento
			Case cNodeID == M_LOCAISATE
				aGrid := Tc073LoadGph(M_LOCAISATE,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//Locais Atendidos
			Case cNodeID == I_LA_CONTRA
				aGrid := Tc071LACtr(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Sem Contrato
			Case cNodeID == I_LA_SEMCON
				aGrid := Tc071LAVzo(cCodCli,cLojCli,dDataDe,dDataAte)

			//Equipamentos
			Case cNodeID == M_EQUIPAMEN	
				aGrid := Tc073LoadGph(M_EQUIPAMEN,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//Reservados
			Case cNodeID == I_EQ_RESERV
				aGrid := Tc071EqRes(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Locados
			Case cNodeID == I_EQ_LOCADO
				aGrid := Tc071EqLoc(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Devolvidos
			Case cNodeID == I_EQ_DEVOLV
				aGrid := Tc071EqDev(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//A Separar
			Case cNodeID == I_EQ_ASEPAR
				aGrid := Tc071EqASp(cCodCli,cLojCli,dDataDe,dDataAte)
	
			//Separados
			Case cNodeID == I_EQ_SEPARA
				aGrid := Tc071EqSep(cCodCli,cLojCli,dDataDe,dDataAte)
	
			//Recursos Humanos
			Case cNodeID == M_RECHUMANO
				aGrid := Tc073LoadGph(M_RECHUMANO,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
				
			//Postos
			Case cNodeID == I_RH_POSTOS
				aGrid := Tc071RHPos(cCodCli,cLojCli,dDataDe,dDataAte)
				
			//"Atendentes (Histórico)"
			Case cNodeID == I_RH_ATEND
				aGrid := Tc071RHAHs(cCodCli,cLojCli,dDataDe,dDataAte)

			//"Atendentes (Alocados)"
			Case cNodeID == I_RH_ATFUT
				aGrid := Tc071RHAFt(cCodCli,cLojCli,dDataDe,dDataAte)
 	
			//Ordens de Servico
			Case cNodeID == M_ORDSERICO	
				aGrid := Tc073LoadGph(M_ORDSERICO,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
			
			//OS SIGATEC
			Case cNodeID == I_OS_SIGTEC
				aGrid := Tc071OSTec(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//OS SIGAMNT
			Case cNodeID == I_OS_SIGMNT
				aGrid := Tc071OSMnt(cCodCli,cLojCli,dDataDe,dDataAte)

			//Armamento
			Case cNodeID == M_ARMAMENTO
				aGrid := Tc073LoadGph(M_ARMAMENTO,cCodCli,cLojCli,dDataDe,dDataAte)
				lGraph := .T.
				
			//Armas
			Case cNodeID == I_AR_ARMAS
				aGrid := Tc071GAArm(cCodCli,cLojCli,dDataDe,dDataAte)
						
			//Coletes
			Case cNodeID == I_AR_COLETE
				aGrid := Tc071GACol(cCodCli,cLojCli,dDataDe,dDataAte)
			
			//Municoes
			Case cNodeID == I_AR_MUNICO
				aGrid := Tc071GAMun(cCodCli,cLojCli,dDataDe,dDataAte)
		
		EndCase
				
		//Atualiza a GetDados com o resultado da Pesquisa
		If !lGraph .and. Empty(cURL)
			If len(aGrid) > 0
				aHeader := aClone(aGrid[1])
				If len(aGrid[2]) > 0
					aCols := aClone(aGrid[2])
				Else
					//Monta aCols em Branco pois nao ha resultados validos
					aCols := aClone(EmptyLine(aGrid[1]))
				EndIf
			EndIf
		ElseIf lGraph .and. Empty(cURL)
			If len(aGrid) > 0
				aGraph := aClone(aGrid)
			EndIf
		EndIf
		
		//Exibe a MsNewGetDados do Node em Questão
		Tc070HideAllGD()
		If !lGraph .and. Len(aCols) > 0
			Tc070NewGet(cNodeID,aCols,aHeader)
		ElseIf lGraph .and. empty(cURL) 
			Tc070NewGph(cNodeID,aGraph,oTree,cCodCli,cLojCli,dDataDe,dDataAte)
		ElseIf !(empty(cURL)) 
			Tc070NewBrw(cNodeID,cURL)
		EndIf
		
	EndIf

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070Show
"Pinta" a dialog principal da rotina de Central do Cliente
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070Show()
	If ValType(oDlg) == "O"
		oDlg:Activate()
	EndIf
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070UsrBut
Função que executa um ponto de entrada para adicionar botoes de usuario na Enchoice Buttons
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070UsrBut(cCodCli)
	Local aRet := {}

	if ExistBlock("Tc070UsrBut")
		aRet := ExecBlock("Tc070UsrBut", .F., .F.,{cCodCli,cLojCli}) 
	EndIf
	
Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} TC070Paint
"Pinta" a dialog principal da rotina de Central do Cliente
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070Res(nPerc,lWidth)
	Local nRet 
	Local nResHor := GetScreenRes()[1] 					
	Local nResVer := GetScreenRes()[2]
	
	if lWidth
		nRet := nPerc * nResHor / 100
	else
		nRet := nPerc * nResVer / 100
	endif

Return nRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070NewGet
Cria um objeto MsNewGetDados dentro do Array de GetDados.
Se o objeto ja foi criado em momento anterior, entao apenas atualiza sua aCols e
executa o Refresh + Show
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070NewGet(cNodeID,aCols,aHeader)
	Local nGetDTop  := 0 		
	Local nGetDLeft := 0 	
	Local nGetDDown := 0  	
	Local nGetDRight:= 0
	Local nPos		:= 0 
	Local oGetD		:= Nil
	Local nTam		:= 0
	Local aGrid		:= {}

	//Busco se a GetDados deste item ja foi criada antes
	nPos := aScan(aObjGetD,{ |x| x[1] == cNodeID})

	//Oculta da aCols os Campos que tem X3_NIVEL maior que o do Usuario do Sistema
	aGrid := ChkFldAcc(aHeader,aCols)
	aHeader := aClone(aGrid[1]) 
	aCols 	:= aClone(aGrid[2])


	If nPos <= 0
		//Adiciona no Array de Objetos
		aAdd(aObjGetD,Array(3))
			
		//Monta a GetDados que apresenta os resultados da pesquisa, inicialmente com aHeader e aCols "Fake"
		//Cada clique em um node do oTree determina uma aHeader e uma aCols validos
		nGetDTop  := (oBox1:nTop / 2)
		nGetDLeft := (oBox1:nLeft + oBox1:nWidth + 20) / 2 	
		nGetDDown := (oBox1:nHeight) / 1.8
		nGetDRight:= (oDlg:nWidth - (oBox1:nLeft + oBox1:nWidth + 20)) / 1.55  
		nTam 	 := len(aObjGetD)
		
		aObjGetD[nTam,1] := cNodeID			//Identificador do Objeto
		aObjGetD[nTam,3] := GETDADOS		//Tipo: MsGetDados
		aObjGetD[nTam,2] := MsNewGetDados():New(nGetDTop,nGetDLeft, nGetDDown,nGetDRight ,/*GD_UPDATE*/, /*cLinhaOk*/, /*cTudoOk*/,/*incremento*/,/*aCamposAlt*/,/*lVazio*/,999,/*cCampoOk*/,/*Superdel*/,/*cApagaOk*/,oDlg,aHeader,aCols)
		aObjGetD[nTam,2]:oBrowse:bRClicked := {|w,x,y,z| Tc070RgtClk(cNodeID,aObjGetD[nTam,2]:aHeader,aObjGetD[nTam,2]:aCols,x,y,w,z,GETDADOS)} 					
		aObjGetD[nTam,2]:ForceRefresh()
		aObjGetD[nTam,2]:Refresh()
		aObjGetD[nTam,2]:Show()				
	Else
		aObjGetD[nPos,2]:aCols := aCols
		aObjGetD[nPos,2]:ForceRefresh()
		aObjGetD[nPos,2]:Refresh()
		aObjGetD[nPos,2]:Show()
	EndIf
	
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070NewGph
Cria um objeto do Tipo Grafico dentro do Array de GetDados.
Se o objeto ja foi criado em momento anterior entao apenas executa o Refresh + Show
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070NewGph(cNodeID,aGraph,oTree,cCodCli,cLojCli,dDataDe,dDataAte)
	Local nWebTop  := 0 		
	Local nWebLeft := 0 	
	Local nWebDown := 0  	
	Local nWebRight:= 0
	Local nPos		:= 0 
	Local nI		:= 1
	Local oChart	:= Nil
	Local nTam		:= 0

	//Busco se a FWChartBar deste item ja foi criada antes
	nPos := aScan(aObjGetD,{ |x| x[1] == cNodeID})

	If nPos <= 0
		//Adiciona no Array de Objetos
		aAdd(aObjGetD,Array(3))
		nTam := len(aObjGetD)
	Else
		nTam := nPos
	EndIf

	//Monta a FWChartBar que apresenta os resultados da pesquisa
	nWebTop  := (oBox1:nTop / 2)
	nWebLeft := (oBox1:nLeft + oBox1:nWidth + 20) / 2
	nWebDown := (oBox1:nHeight) / 2
	nWebRight:= (oDlg:nWidth - (oBox1:nLeft + oBox1:nWidth + 20)) / 2  
	nTam 	 := len(aObjGetD)
	
	aObjGetD[nTam,1] := cNodeID		//Identificador do Objeto
	aObjGetD[nTam,3] := FWGRAPH		//Tipo: FwChart		
	aObjGetD[nTam,2] := FWChartBar():New()
	aObjGetD[nTam,2]:init( oPanel, .t., .t. ) 
	For nI := 1 to len(aGraph)
		aObjGetD[nTam,2]:addSerie(aGraph[nI,1],aGraph[nI,2])
	Next nI
	aObjGetD[nTam,2]:setLegend(CONTROL_ALIGN_RIGHT)
	aObjGetD[nTam,2]:oOwner:bRclicked := {|w,x,y,z| Tc070RgtClk(cNodeID,{},{},x,y,w,z,FWGRAPH,aObjGetD[nTam,2])}
	aObjGetD[nTam,2]:oOwner:bLclicked := aObjGetD[nTam,2]:oOwner:bLDBLclick  
	aObjGetD[nTam,2]:oOwner:bLDBLclick := {|| Tc070ClkGph(cNodeId,aObjGetD[nTam,2],oTree,cCodCli,cLojCli,dDataDe,dDataAte)  }		
	aObjGetD[nTam,2]:Build()
	
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070NewBrw
Cria um objeto do Tipo TIBrowser
Se o objeto ja foi criado em momento anterior entao apenas executa o Refresh + Show
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070NewBrw(cNodeID,cURL)
	Local nWebTop  := 0
	Local nWebLeft := 0
	Local nWebDown := 0
	Local nWebRight:= 0
	Local nPos		:= 0 
	Local nI		:= 1
	Local oChart	:= Nil
	Local nTam		:= 0

	//Busco se a TIBrowser deste item ja foi criada antes
	nPos := aScan(aObjGetD,{ |x| x[1] == cNodeID})

	If nPos <= 0
		//Adiciona no Array de Objetos
		aAdd(aObjGetD,Array(3))
		nTam := len(aObjGetD)
	
		//Monta a TIBrowser que apresenta os resultados da pesquisa
		aObjGetD[nTam,1] := cNodeID			//Identificador do Objeto
		aObjGetD[nTam,3] := TIBROWSER		//Tipo: TiBrowser		
		aObjGetD[nTam,2] := TiBrowser():New(,,,,cURL,oPanel)
		aObjGetD[nTam,2]:nLeft := 0.1
		aObjGetD[nTam,2]:nTop := 0.1
		aObjGetD[nTam,2]:nHeight := oPanel:nHeight
		aObjGetD[nTam,2]:nWidth := oPanel:nWidth
		aObjGetD[nTam,2]:Navigate(cURL)
	Else
		aObjGetD[nPos,2]:Show()
		aObjGetD[nPos,2]:Navigate(cURL)
	EndIf
	
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070HideAllGD
Ocula todas as GetDados que existirem
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070HideAllGD()
	Local nI := 0
	Local nJ := 0
	Local n5Perc := 0
	
	For nI := 1 to len(aObjGetD)		
		If aObjGetD[nI,3] == GETDADOS
			aObjGetD[nI,2]:Hide()
		ElseIf aObjGetD[nI,3] == FWGRAPH			
			aObjGetD[nI,2]:oOwner:lVisible := .F.
			aObjGetD[nI,2]:Refresh()
		ElseIf aObjGetD[nI,3] == TIBROWSER
			aObjGetD[nI,2]:Hide()
			aObjGetD[nI,2]:Refresh()
		EndIf
	Next nI
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070DestroyAll
Destroi todos os objetos de GetDados criados durante a execucao
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070DestroyAll()
	Local nI := 0
	
	For nI := 1 to len(aObjGetD)
		TecDestroy(aObjGetD[nI,2])
		aObjGetD[nI,1] := Nil
		aObjGetD[nI,2] := Nil
	Next nI
	ASize(aObjGetD,0)
	
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070ChkOpt(cNodeId)
 Define regras de restrição de acesso de acordo com o Acesso Grupo Perfil do GS
 Para remocao de campos RECOMENDAR O USO DO CONTROLE DE X3_NIVEL no Usuario
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070ChkOpt(cNodeID)
	Local lRet 	:= .F.
	Local cCode := ""
	Default cNodeID := ""
		
	If !Empty(cNodeId)
		Do Case
			Case cNodeID == M_OPORT
				cCode := "022"
			Case cNodeID == M_PROPOSTAS
				cCode := "023"
			Case cNodeID == M_CONTRATOS
				cCode := "024"
			Case cNodeID == M_FINANCEIR
				cCode := "025"
			Case cNodeID == M_FATURAMEN
				cCode := "026"
			Case cNodeID == M_LOCAISATE
				cCode := "027"
			Case cNodeID == M_EQUIPAMEN
				cCode := "028"
			Case cNodeID == M_RECHUMANO
				cCode := "029"
			Case cNodeID == M_ORDSERICO
				cCode := "030"
			Case cNodeID == M_ARMAMENTO
				cCode := "031"
		EndCase	
		
		//Chama a rotina padrão de validação
		lRet := At680Perm(Nil,__cUserId,cCode)
	EndIf
	
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} EmptyLine
Cria uma linha da aCols vazia quando nao sao encotrados resultados em uma query
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function EmptyLine(aHdr)
	Local aRet   := {}
	Local nI	 := 0
	            
	aAdd(aRet, Array( Len(aHdr)+1 ) )
	
	For nI := 1 To Len(aHdr)
		aRet[Len(aRet),nI] := CriaVar(Alltrim(aHdr[nI,2]),.F.)
	Next nI
		
	aRet[Len(aRet)][Len(aHdr)+1] := .F.
Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc070ClkGph
Funcao executada no clique dpuplo sobre o grafico.
Direciona para algum nó da arvore de acordo com o codigo do node pai + opçcao
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function Tc070ClkGph(cNodeId,oObj,oTree,cCodCli,cLojCli,dDataDe,dDataAte)
	Local cToNode := ""
	
	//Identifica qual o No de Destino a partir do no Pai + nro da barra selecionada
	cToNode := Tc073MapNode(cNodeId,oObj)	
	If !Empty(cToNode)
		oTree:PTGotoToNode(cToNode)
		Tc070LoadData(cToNode,cCodCli,cLojCli,dDataDe,dDataAte,oTree)
	EndIf
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} ChkFldAcc
Remove da aCols e da aHeader todos os campos que o usuario nao tem acesso
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function ChkFldAcc(aHeader,aCols)
	Local aRet 		:= Array(2)
	Local nI		:= 1
	Local nJ		:= 1
	Local nPosFldNm	:= 2
	Local aArea		:= GetArea()
	
	dbSelectArea('SX3')
	SX3->(dbSetOrder(2))
	While .T.
		If SX3->(dbSeek(aHeader[nI,nPosFldNm])) .and. cNivel < SX3->X3_NIVEL
			
			//Deleta o campo da Header
			aDel(aHeader,nI)
			aSize(aHeader,Len(aHeader)-1)
			
			//Deleta a coluna da aCols
			For nJ := 1 to len(aCols)
				aDel(aCols[nJ],nI)
				aSize(aCols[nJ],Len(aCols[nJ])-1)
			Next nJ 
		Else
			//Incrementa apenas se o campo nao foi deletado
			//Se foi deletado na etapa anterior, a analise continua do mesmo ponto vide aSize
			nI++
		EndIf
		
		//Controle do final do laço
		If nI >= len(aHeader)
			exit
		EndIf	
	EndDo
	
	//Formata o retorno
	aRet[1] := aClone(aHeader)
	aRet[2] := aClone(aCols)
	
	RestArea(aArea)

Return aRet