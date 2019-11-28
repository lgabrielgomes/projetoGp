#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA270.CH" 

Static cPerfil  := ""	// Controla o perfil do vistoriador.
Static cVistor  := ""	// Codigo do vistoriador.
Static nLine	:= 0	// Linha atual.  

/*                        
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �TECA270   �Autor  �Vendas CRM          � Data �  27/02/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Vistoria Tecnica.             			           	      ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro		                                      ���
�������������������������������������������������������������������������͹��
���Parametros�Nenhum					                     			  ���
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Function TECA270()

Local oBrowse	:= Nil 										// Objeto oBrowse.
Local bPerfil	:= {|a,b,c,d| At270EPerf(a,b,c,d)}			// Bloco de codigo perfil do vistoriador.

Private cCadastro := STR0001  								// Variavel utilizada no Banco de Conhecimento
Private aRotina   := MenuDef()                          // Array aRotina utilizada no banco de conhecimento

//����������������������������������������������������������������Ŀ
//� Verifica se o usuario e um vistoriador e carrega o seu perfil. �
//������������������������������������������������������������������
Eval(bPerfil,"TECA270",/*aEstrut*/,/*oObject*/,"Perfil")

If At("ACESSA",cPerfil) > 0
	//���������������Ŀ
	//� Cria o Browse �
	//�����������������
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("AAT")
	oBrowse:SetDescription(STR0001)       						// "Vistoria T�cnica"
	oBrowse:AddLegend("AAT_STATUS=='1'","GREEN" ,STR0002)	// "Aberto"
	oBrowse:AddLegend("AAT_STATUS=='2'","YELLOW",STR0003)	// "Agendado"
	oBrowse:AddLegend("AAT_STATUS=='3'","RED"   ,STR0004)	// "Concluido"
	oBrowse:AddLegend("AAT_STATUS=='4'","BLACK" ,STR0005)	// "Cancelado"
	
	//������������������������������Ŀ
	//� Verifica Permissao de Filtro �
	//��������������������������������
	Eval(bPerfil,"TECA270",/*aEstrut*/,oBrowse,"SetFilterDefault")
	
	oBrowse:Activate()
	
EndIf

//�������������������������������Ŀ
//� Limpa o Perfil do Vistoriador �
//���������������������������������
cPerfil  := ""
cVistor  := ""

Return( .T. )

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ModelDef  �Autor  �Vendas CRM          � Data �  27/02/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Modelo de Dados Vistoria Tecnica.                   		  ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpO - Modelo de Dados                                      ���
�������������������������������������������������������������������������͹��
���Parametros�Nenhum					                      			  ���
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function ModelDef()

Local oModel		:= Nil														   				// Objeto que contem o modelo de dados.
Local oStruAAT 	:= FWFormStruct(1,"AAT",/*bAvalCampo*/,/*lViewUsado*/)				// Objeto que contem a estrutura do cabecalho de vistoria.
Local oStruPrd 	:= FWFormStruct(1,"AAU",/*bAvalCampo*/,/*lViewUsado*/)				// Objeto que contem a estrutura de produtos.
Local oStruAce	:= FWFormStruct(1,"AAU",/*bAvalCampo*/,/*lViewUsado*/)				// Objeto que contem a estrutura de acessorios.
Local aAux			:= {} 																		// Array auxilar para montar a trigger.
Local aEstrut		:= {} 												   						// Array que contem as estruturas.
Local bPosValid	:= {|oModel| At270VdAge(oModel)}										// Pos validacao do formulario.
Local bCommit		:= {|oModel| At270Cmt(oModel)}    										// Bloco de commit.
Local bCancel		:= {|oModel| At270Canc(oModel)}    									// Bloco de cancelamento do formulario.
Local bLinePre	:= {|oMdlPrd,nLinha,cAction| At270DLin(oMdlPrd,nLinha,cAction)}	// Pre validacao da linha.
Local bPerfil		:= {|a,b,c,d| At270EPerf(a,b,c,d)}										// Bloco de codigo perfil do vistoriador
Local lAgendAbb	:= SuperGetMv("MV_ATVTABB",,.F.)										// Controla agenda pela ABB

//�������������������������������������������������������������Ŀ
//� Tratamento para FWExecView chamada pela proposta comercial. �
//���������������������������������������������������������������
If IsInCallStack("FATA300")
	//���������������������������������������������������������Ŀ
	//� Habilita a visualizacao dos valores para os vendedores. �
	//�����������������������������������������������������������
	Eval(bPerfil,"FATA300",/*aEstrut*/,/*oObject*/,"Vendedor")
EndIf

If lAgendAbb	        
	oStruAAT:SetProperty("AAT_DTINI",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_HRINI",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_DTFIM",MODEL_FIELD_OBRIGAT,.F.)
	oStruAAT:SetProperty("AAT_HRFIM",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_STATUS",MODEL_FIELD_WHEN,{||IIF(oModel:GetOperation()==3,.F.,.T.)})
EndIf

//������������������������������������������Ŀ
//� Adiciona as Estruturas no Array aEstrut. �
//��������������������������������������������
aAdd(aEstrut,oStruAAT)
aAdd(aEstrut,oStruPrd)
aAdd(aEstrut,oStruAce)

//�����������������������������������������������Ŀ
//� Instancia o modelo de dados Vistoria Tecnica. �
//�������������������������������������������������
oModel := MPFormModel():New("TECA270",/*bPreValidacao*/,bPosValid,bCommit,bCancel)

//���������������������Ŀ
//� Criacao da Trigger. �
//�����������������������
aAux := FwStruTrigger("AAU_QTDVEN","AAU_VLRTOT","At270CTot('PRDDETAIL','AAU_QTDVEN')",.F.,Nil,Nil,Nil)
oStruPrd:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("AAU_PRCVEN","AAU_VLRTOT","At270CTot('PRDDETAIL','AAU_PRCVEN')",.F.,Nil,Nil,Nil)
oStruPrd:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("AAU_QTDVEN","AAU_VLRTOT","At270CTot('ACEDETAIL','AAU_QTDVEN')",.F.,Nil,Nil,Nil)
oStruAce:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("AAU_PRCVEN","AAU_VLRTOT","At270CTot('ACEDETAIL','AAU_PRCVEN')",.F.,Nil,Nil,Nil)
oStruAce:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//��������������������������������������������������������������Ŀ
//� Verifica se o vistoriador podera alterar o campo AAT_VISTOR. �
//����������������������������������������������������������������
Eval(bPerfil,"MODELDEF",aEstrut,oModel,"SetProperty")  

//���������������������������������������������������������������������������Ŀ
//� Permite alteracao nos campos Oportunidade e Proposta somente na inclusao. �
//�����������������������������������������������������������������������������
oStruAAT:SetProperty("AAT_OPORTU",MODEL_FIELD_WHEN,{|| IIF(oModel:GetOperation()==3,.T.,.F.) })
oStruAAT:SetProperty("AAT_PROPOS",MODEL_FIELD_WHEN,{|| IIF(oModel:GetOperation()==3,.T.,.F.) })

//���������������������������������������������Ŀ
//� Mudanca da propriedade do campo AAU_FOLDER. �
//�����������������������������������������������
oStruPrd:SetProperty("AAU_FOLDER",MODEL_FIELD_INIT,{||"1"})		// Produto(s)
oStruAce:SetProperty("AAU_FOLDER",MODEL_FIELD_INIT,{||"2"}) 	// Acessorio(s)

//�������������������������������������������������Ŀ
//� Atualiza o total dos grids Produto e Acessorio. �
//���������������������������������������������������
oStruPrd:SetProperty("AAU_PRODUT",MODEL_FIELD_VALID,FwBuildFeature( STRUCT_FEATURE_VALID,"At270VdPrd('PRDDETAIL')"))
oStruAce:SetProperty("AAU_PRODUT",MODEL_FIELD_VALID,FwBuildFeature( STRUCT_FEATURE_VALID,"At270VdPrd('ACEDETAIL')"))

//����������������������������������������Ŀ
//� Adiciona os campos no modelo de dados. �
//������������������������������������������
oModel:AddFields("AATMASTER",/*cOwner*/,oStruAAT,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/ )
oModel:AddGrid("PRDDETAIL","AATMASTER",oStruPrd,bLinePre,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/)
oModel:AddGrid("ACEDETAIL","AATMASTER",oStruAce,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/,/*bPosVal*/)

//�����������������������������Ŀ
//� Adiciona campos calculados. �
//�������������������������������
Eval(bPerfil,"MODELDEF",/*aEstrut*/,oModel,"AddCalc")

//����������������������������Ŀ
//� Permite de grid sem dados. �
//������������������������������
oModel:GetModel("ACEDETAIL"):SetOptional(.T.)

//�����������������������������������������������������������Ŀ
//� Gatilho para mudanca do campo AAU_LOCAL caso esteja vazio.�
//�������������������������������������������������������������
aAux := FwStruTrigger( "AAU_PRODUT", "AAU_LOCAL", "At270LoIt('PRDDETAIL')",.F.,Nil,Nil,Nil)    
oStruPrd:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger( "AAU_PRODUT", "AAU_LOCAL", "At270LoIt('ACEDETAIL')",.F.,Nil,Nil,Nil)    
oStruAce:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//�����������������������������Ŀ
//� Montagem do relacionamento. �
//�������������������������������
oModel:SetRelation("PRDDETAIL",{{"AAU_FILIAL","xFilial('AAU')"},{"AAU_CODVIS","AAT_CODVIS"},{"AAU_FOLDER","'1'"}},AAU->( IndexKey(2)))
oModel:SetRelation("ACEDETAIL",{{"AAU_FILIAL","xFilial('AAU')"},{"AAU_CODVIS","AAT_CODVIS"},{"AAU_FOLDER","'2'"}},AAU->( IndexKey(2)))

If AAT->AAT_STATUS == "2" 
	oModel:GetModel("PRDDETAIL"):SetOptional(.T.)
	oModel:GetModel("ACEDETAIL"):SetOptional(.T.)
Endif

//Ativa��o do Model
oModel:SetVldActivate( { |oModel| At270Activ( oModel ) } )

oModel:SetDescription(STR0001)	//"Vistoria T�cnica"

Return(oModel)

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ViewDef   �Autor  �Vendas CRM          � Data �  27/02/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Interface Vistoria Tecnica.                       		  ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpO - Interface                                            ���
�������������������������������������������������������������������������͹��
���Parametros�Nenhum					                      			  ���
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function ViewDef()

Local oView		:= Nil									// Objeto que contem interface vistoria tecnica.
Local oModel		:= FWLoadModel("TECA270")			// Objeto que contem o modelo de dados.
Local nOperation	:= oModel:nOperation				   	// Numero da operacao.
Local oStruAAT	:= FWFormStruct(2,"AAT")				// Objeto que contem a estrutura do cabecalho de vistoria.
Local oStruPrd	:= FWFormStruct(2,"AAU")				// Objeto que contem a estrutura de produtos.
Local oStruAce	:= FWFormStruct(2,"AAU")				// Objeto que contem a estrutura de acessorios.
Local oStruCal	:= FWFormViewStruct():New()			// Objeto que contem a estrutura dos campos calculados.
Local aEstrut		:= {}     								// Array que contem as estruturas.
Local bPerfil		:= {|a,b,c,d| At270EPerf(a,b,c,d)}	// Bloco de codigo perfil do vistoriador.
Local lAgendAbb	:= SuperGetMv("MV_ATVTABB",,.F.)   // Controla agenda pela ABB

If lAgendAbb	        
	oStruAAT:SetProperty("AAT_DTINI",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_HRINI",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_DTFIM",MODEL_FIELD_OBRIGAT,.F.)
	oStruAAT:SetProperty("AAT_HRFIM",MODEL_FIELD_OBRIGAT,.F.)
EndIf
//�������������������������Ŀ
//� Adiciona as Estruturas. �
//���������������������������
aAdd(aEstrut,oStruAAT)
aAdd(aEstrut,oStruPrd)                     
aAdd(aEstrut,oStruAce)
aAdd(aEstrut,oStruCal)


//�����������������������������������������������������������������������������Ŀ
//� Remove os campos de controle da View para n�o ser visualizado pelo usuario. �
//�������������������������������������������������������������������������������
oStruPrd:RemoveField("AAU_ITPROP")
oStruPrd:RemoveField("AAU_CODVIS")
oStruPrd:RemoveField("AAU_FOLDER") 
oStruPrd:RemoveField("AAU_ITPAI") 

oStruAce:RemoveField("AAU_ITPROP")
oStruAce:RemoveField("AAU_CODVIS")
oStruAce:RemoveField("AAU_FOLDER") 
oStruAce:RemoveField("AAU_PMS")             

//��������������������������������������������������������Ŀ
//� Remove os campos da view conforme o perfil do usuario. �
//����������������������������������������������������������
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"RemoveField")

//�����������������������������������������Ŀ
//� Instancia a interface Vistoria Tecnica. �
//�������������������������������������������
oView := FWFormView():New()
oView:SetModel(oModel)

//������������������������������������������������Ŀ
//� Adiciona rotinas conforme o perfil do usuario. �
//��������������������������������������������������
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"AddUserButton")
	
oView:AddUserButton(STR0031,"",{|| MsDocument("AAT",AAT->(Recno()),oModel:GetOperation())},,,{MODEL_OPERATION_VIEW,MODEL_OPERATION_UPDATE})  // Conhecimento
oView:AddUserButton(STR0032,"",{|| TECR271(oView)},,,) // Imprime Vistoria   

//����������������������������������Ŀ
//� Adiciona os campos no cabecalho. �
//������������������������������������
oView:AddField("VIEW_AAT",oStruAAT,"AATMASTER")

//����������������������������������������������������������Ŀ
//� Adiciona os campos na view conforme o perfil do usuario. �
//������������������������������������������������������������
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"AddField")

//�����������������������������Ŀ
//� Adiciona os campos no grid. �
//�������������������������������
oView:AddGrid("VIEW_PRD",oStruPrd,"PRDDETAIL")
oView:AddGrid("VIEW_ACE",oStruAce,"ACEDETAIL")

//������������������������Ŀ
//� Campos com incremento. �
//��������������������������
oView:AddIncrementField("VIEW_PRD","AAU_ITEM")
oView:AddIncrementField("VIEW_ACE","AAU_ITEM")

//�������������������������������������������������Ŀ
//� Habilita as views conforme o perfil do usuario. �
//���������������������������������������������������
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"EnableView")

Return(oView)

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �MenuDef   �Autor  �Vendas CRM          � Data �  27/02/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Criacao do MenuDef.	  	                        		  ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpA - Opcoes de menu                                       ���
�������������������������������������������������������������������������͹��
���Parametros�Nenhum					                      			  ���
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

Static Function MenuDef()

Local aRotina := {} 				// Variavel a rotina.                      
Local lAgendAbb	:= SuperGetMv("MV_ATVTABB",,.F.)   					// Controla agenda pela ABB

ADD OPTION aRotina TITLE STR0006 ACTION "PesqBrw" 		  OPERATION 1 ACCESS 0  // "Pesquisar"
ADD OPTION aRotina TITLE STR0007 ACTION "VIEWDEF.TECA270" OPERATION 2 ACCESS 0  // "Visualizar"
ADD OPTION aRotina TITLE STR0008 ACTION "VIEWDEF.TECA270" OPERATION 3 ACCESS 0 	// "Incluir"
ADD OPTION aRotina TITLE STR0009 ACTION "VIEWDEF.TECA270" OPERATION 4 ACCESS 0	// "Alterar"
ADD OPTION aRotina TITLE STR0010 ACTION "VIEWDEF.TECA270" OPERATION 5 ACCESS 0 	// "Excluir" 
ADD OPTION aRotina TITLE STR0028 ACTION "A600RelVis(AAT->AAT_CODVIS)"   OPERATION 6 ACCESS 0  // "Imprimir Modelo"
If lAgendAbb
	ADD OPTION aRotina TITLE STR0027 ACTION "At270Agend" OPERATION 1 ACCESS 0 	// "Agendar / Reagendar"
EndIf

ADD OPTION aRotina TITLE STR0031 ACTION 'MSDOCUMENT'  OPERATION 7 ACCESS 0 //"Bco. Conhecimento"

Return(aRotina)


/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270EPerf �Autor  �Vendas CRM          � Data �  21/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Executa o perfil do vistoriador por rotina.	   	           ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro                                            ���
��������������������������������������������������������������������������͹��
���Parametros�ExpC1 - Rotina que sera verificada o perfil do usuario.	   ���
���			 �ExpA2 - Estruturas de Dados.                    	           ���
���			 �ExpO3 - Objeto MVC.                                          ���
���			 �ExpC4 - Acao do objeto MVC.                                  ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270                                                      ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Static Function At270EPerf(cRotina,aEstrut,oObject,cAction)

Default cRotina	:= ""  		// Funcao que solicitou a verificacao do perfil.
Default aEstrut	:= {}		// Estrutura de dados.
Default oObject := Nil		// Objeto a ser utilizado na verificacao do perfil.
Default cAction := ""		// Acao que sera executada no objeto.

Do Case
	Case cRotina $ "TECA270|FATA300"
		At270PMain(oObject,cAction)
	Case cRotina == "MODELDEF"
		At270PMdl(aEstrut,oObject,cAction)
	Case cRotina == "VIEWDEF"
		At270PView(aEstrut,oObject,cAction)
EndCase
Return( .T. )

/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa  �At270PMain �Autor  �Vendas CRM          � Data �  21/03/12     ���
����������������������������������������������������������������������������͹��
���Desc.     �Verifica se o usuario e um vistoriador; e carrega o seu perfil ���
���		     �durante a execucao da rotina principal(TECA270).	             ���
����������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                      ���
����������������������������������������������������������������������������͹��
���Parametros�ExpO1 - Objeto MVC.      	  								     ���
���			 �ExpC2 - Acao do objeto MVC.                      	             ���
����������������������������������������������������������������������������͹��
���Uso       �TECA270                                                        ���
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/

Static Function At270PMain(oObject,cAction)

Local aAreaAA1	:= AA1->(GetArea())	// Guarda a area atual da tabela AA1.
Local cCodUser	:= __cUserId			// Codigo do usuario.
Local lRetorno	:= .F.					// Retorno da validacao.
Local cFiltro		:= ""

DbSelectArea("AA1")
DbSetOrder(4)

Do Case
	Case cAction == "Vendedor"
		//��������������������Ŀ
		//� Visualiza Valores? �
		//����������������������
		cPerfil := "VISVLR|"
	
	Case cAction == "Perfil"
		If DbSeek(xFilial("AA1")+cCodUser)
		
			If AA1->AA1_VISTOR == "1"
							
				lRetorno := .T.
				cVistor	 := AA1->AA1_CODTEC
				cPerfil  := "ACESSA|"
	   			//��������������������Ŀ
				//� Visualiza Valores? �
				//����������������������
				If AA1->AA1_VISVLR == "1"
					cPerfil += "VISVLR|"
				EndIf
				//�������������������������������Ŀ
				//� Visualiza Proposta Comercial? �
				//���������������������������������
				If AA1->AA1_VISPRO == "1"
					cPerfil += "VISPRO|"
				EndIf
				//�����������������������������Ŀ
				//� Importa Proposta Comercial? �
				//�������������������������������
				If AA1->AA1_IMPPRO == "1"
					cPerfil += "IMPPRO|"
				EndIf 
				//�������������������������������������������Ŀ
				//� Acessa a rotina de categoria de produtos? �
				//���������������������������������������������
				If AA1->AA1_CATEGO == "1"
					cPerfil += "CATEGO|"
				EndIf
				//����������������������������������������������Ŀ
				//� Permite se altera o responsavel da vistoria? �
				//������������������������������������������������
				If AA1->AA1_ALTVIS == "1"
					cPerfil += "ALTVIS|"
				EndIf
				//�������������������������������������������������������Ŀ
				//� Permite o vistoriador acessar somente suas vistorias  �
				//���������������������������������������������������������
				If AA1->AA1_FTVIST == "1"
					cPerFil += "FILVIS"
				ElseIf AA1->AA1_FTVIST == "3" // Permite que o vistoriador acesse somente as vistorias do grupo
					cPerFil += "GRPVIS"
				EndIf
				
				//��������������������������������Ŀ
				//� Acessa a rotina CRM Simulador? �
				//����������������������������������
				If AA1->AA1_CRMSIM == "1"
					cPerFil += "CRMSIM"
				EndIf
			Else
				//��������������������������������������������������������������������������Ŀ
				//�	 Problema: Este atendente n�o tem perfil para realizar vistoria t�cnica. �
				//�	 Solucao: Defina este atendente como vistoriador no cadastro de          �
				//�	 atendentes para acessar esta rotina.					        		 �
				//����������������������������������������������������������������������������
				Help( " ", 1, "PERFILVIST" )
				lRetorno := .F.
			EndIf
		Else
			//���������������������������������������������������������������������������������������Ŀ
			//�	 Problema: Este usu�rio n�o tem permiss�o para acessar a rotina de vistoria t�cnica.  �
			//�	 Solucao: Cadastre ou altera um atendente e associe o mesmo a este usu�rio.           �
			//�����������������������������������������������������������������������������������������
			Help( " ", 1, "USRATEND" )
			lRetorno := .F.
		EndIf		
	
	Case cAction == "SetFilterDefault"
		cFiltro := ""
		If At("FILVIS",cPerfil) > 0
			cFiltro := "AAT_VISTOR=='"+cVistor+"'"
		ElseIf At("GRPVIS",cPerfil) > 0 
			cFiltro := At270FilVist( cVistor )			
		EndIf
		If !Empty(cFiltro)
			oObject:SetFilterDefault( cFiltro )
		EndIf		
EndCase                           
RestArea(aAreaAA1)
Return ( lRetorno )


/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270PMdl  �Autor  �Vendas CRM          � Data �  21/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Verifica o perfil do vistoriador durante a criacao do Modelo ���
���  	     �de dados.    												   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro                                            ���
��������������������������������������������������������������������������͹��
���Parametros�ExpA1 - Estruturas de Dados.                                 ���
���			 �ExpO2 - Objeto MVC.                                          ���
���			 �ExpC3 - Acao do objeto MVC.                                  ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270                                                      ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Static Function At270PMdl(aEstrut,oObject,cAction)

Local bCond		:= {||.T.}						// Condicao para soma.
Local nTamTot	:= TamSX3("AAU_VLRTOT")[1]		// Tamanho do campo AAU_VRLTOT.
Local nDecTot	:= TamSX3("AAU_VLRTOT")[2]		// Numero de decimais do campo AAU_VLRTOT.
Local oMdlCalc	:= Nil      					// Model calculado.

Do Case
	Case cAction == "SetProperty"
		//���������������������������������������������������Ŀ
		//� Permite o vistoriador alterar o campo AAT_VISTOR? �
		//�����������������������������������������������������
		aEstrut[1]:SetProperty("AAT_VISTOR",MODEL_FIELD_WHEN,{|| IIF(At("ALTVIS",cPerfil) > 0,.T.,.F.) })		
   
	Case cAction == "AddCalc"  
		//�����������������������������������������������������Ŀ
		//� Permite o vistoriador acessar os campos calculados. �
		//�������������������������������������������������������	
		If At("VISVLR",cPerfil) > 0		
			oObject:AddCalc("CALCDETAIL","AATMASTER","PRDDETAIL","AAU_VLRTOT","AAU__TOTPRD","SUM",bCond,/*bInitValue*/,;
			                STR0023,/*bFormula*/,nTamTot,nDecTot)   // "( A ) - Produto(s)" 
								
			oObject:AddCalc("CALCDETAIL","AATMASTER","ACEDETAIL","AAU_VLRTOT","AAU__TOTACE","SUM",bCond,/*bInitValue*/,;
			                STR0024,/*bFormula*/,nTamTot,nDecTot) // "( B ) - Acessorio(s)"
			
		  	oObject:AddCalc("CALCDETAIL","AATMASTER","PRDDETAIL","AAU_VLRTOT","AAU__TOT","FORMULA",bCond,/*bInitValue*/,;
		   	                STR0025,{|oModel| oModel:GetValue("CALCDETAIL","AAU__TOTPRD")+oModel:GetValue("CALCDETAIL","AAU__TOTACE") },nTamTot,nDecTot) // "( A+B )"
			
			oMdlCalc := oObject:GetModel("CALCDETAIL")		
			oMdlCalc:AddEvents("CALCDETAIL","AAU__TOT","AAU__TOTACE",bCond)						
		EndIf 
EndCase
Return ( .T. )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270PView �Autor  �Vendas CRM          � Data �  21/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Verifica o perfil do vistoriador durante a criacao da        ���
���  	     �interface. 												   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro                                            ���
��������������������������������������������������������������������������͹��
���Parametros�ExpA1 - Estruturas de Dados.                                 ���
���			 �ExpO2 - Objeto MVC.                                          ���
���			 �ExpC3 - Acao do objeto MVC.                                  ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270                                                      ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270PView(aEstrut,oObject,cAction)

Do Case
	Case cAction == "AddField"
		//�����������������������������������������������������Ŀ
		//� Permite o vistoriador acessar os campos calculados. �
		//�������������������������������������������������������
		If At("VISVLR",cPerfil) > 0
			aEstrut[4] := FWCalcStruct( oObject:GetModel("CALCDETAIL") )
			oObject:AddField("VIEW_CALC",aEstrut[4],"CALCDETAIL")
		EndIf	
   
	Case cAction == "RemoveField"
		//������������������������������Ŀ
		//� Remove os campos de valores? �
		//��������������������������������
		If At("VISVLR",cPerfil) == 0		
			//������������Ŀ
	   		//� Cabecalho. �
	   		//��������������
			aEstrut[1]:RemoveField("AAT_TABELA")
			
			//������������������Ŀ
	   		//� Folder Produtos. �
	   		//��������������������
			aEstrut[2]:RemoveField("AAU_MOEDA")
			aEstrut[2]:RemoveField("AAU_PRCVEN")
			aEstrut[2]:RemoveField("AAU_PRCTAB")
			aEstrut[2]:RemoveField("AAU_VLRTOT")
			
			//��������������������Ŀ
	   		//� Folder Acessorios. �
	   		//���������������������� 
			aEstrut[3]:RemoveField("AAU_MOEDA")
			aEstrut[3]:RemoveField("AAU_PRCVEN")
			aEstrut[3]:RemoveField("AAU_PRCTAB")
			aEstrut[3]:RemoveField("AAU_VLRTOT")
		EndIf
		
	Case cAction == "AddUserButton"
		//�������������������������������Ŀ
		//� Visualiza Proposta Comercial? �
		//���������������������������������
		If At("VISPRO",cPerfil) > 0
			oObject:AddUserButton(STR0015,"",{|| At270VProp()})  // Visualizar Prospota
		EndIf
		//�����������������������������Ŀ
		//� Importa Proposta Comercial? �
		//�������������������������������
		If At("IMPPRO",cPerfil) > 0
			oObject:AddUserButton(STR0014,"",{|oView| At270IProp(oView:GetModel())}, Nil, Nil, {MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE})  // Importar Prospota
		EndIf
		//�������������������������������������������Ŀ
		//� Acessa a rotina de categoria de produtos? �
		//���������������������������������������������
		If At("CATEGO",cPerfil) > 0
			oObject:AddUserButton(STR0013,"",{|| At270CTPrd()})  // Categoria
		EndIf		
		//��������������������������������Ŀ
		//� Acessa a rotina CRM Simulador? �
		//����������������������������������
		If At("CRMSIM",cPerfil) > 0
			oObject:AddUserButton(STR0016,"",{|| At270Simul()})  // CRM Simulador
		EndIf		
					
		If nModulo == 28 // Modulo Gestao de Servi�os
			oObject:AddUserButton( STR0035, "", { || At600OrcView( Nil, .T. ) }, Nil, Nil, { MODEL_OPERATION_VIEW, MODEL_OPERATION_DELETE } )  // 'Vis. Or�am. Serv.'
			oObject:AddUserButton( STR0036, "", { |oView| At270GerOrc( MODEL_OPERATION_INSERT, oView:GetModel() ) }, Nil, Nil, { MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE } ) // Atualiza Orc. Servi�os
			oObject:AddUserButton( STR0037, "", { |oView| At600SeExc( MODEL_OPERATION_DELETE, .T., oView:GetModel() ) }, Nil, Nil, { MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE } ) // Remover Orc. Servi�os
		EndIf							
				
	Case cAction == "EnableView"
		//����������������������������������������������Ŀ
		//� Acessa a interface com os campos calculados? �
		//������������������������������������������������
		If At("VISVLR",cPerfil) > 0
			
			oObject:CreateHorizontalBox("TOP",40)
			oObject:CreateHorizontalBox("CENTER",48)
			oObject:CreateFolder("FOLDER","CENTER")
			
			oObject:AddSheet("FOLDER","TAB1",STR0017)	// "Produto(s)"
			oObject:AddSheet("FOLDER","TAB2",STR0018)	// "Acessorio(s)"
			
			oObject:CreateHorizontalBox("HBX_TAB1",100,,,"FOLDER","TAB1") // "Produto(s)"
			oObject:CreateHorizontalBox("HBX_TAB2",100,,,"FOLDER","TAB2") // "Acessorio(s)"
			
			oObject:CreateHorizontalBox("BUTTON",12)
			oObject:CreateVerticalBox("TOTAIS",100,"BUTTON")
			oObject:EnableTitleView("VIEW_CALC",STR0019) // "Valor Total dos Itens Vistoriados"
			
			oObject:SetOwnerView("VIEW_AAT","TOP")
			oObject:SetOwnerView("VIEW_PRD","HBX_TAB1")
			oObject:SetOwnerView("VIEW_ACE","HBX_TAB2")
			oObject:SetOwnerView("VIEW_CALC","TOTAIS")
		Else
			oObject:CreateHorizontalBox("TOP",50)
			oObject:CreateHorizontalBox("BUTTOM",50)
			oObject:CreateFolder("FOLDER","BUTTOM")
			
			oObject:AddSheet("FOLDER","TAB1",STR0017)	// "Produto(s)"
			oObject:AddSheet("FOLDER","TAB2",STR0018)	// "Acessorio(s)"
			
			oObject:CreateHorizontalBox("HBX_TAB1",100,,,"FOLDER","TAB1") // "Produto(s)"
			oObject:CreateHorizontalBox("HBX_TAB2",100,,,"FOLDER","TAB2") // "Acessorio(s)"
			
			oObject:SetOwnerView("VIEW_AAT","TOP")
			oObject:SetOwnerView("VIEW_PRD","HBX_TAB1")
			oObject:SetOwnerView("VIEW_ACE","HBX_TAB2")
		EndIf		
EndCase
Return( .T. )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270RVist �Autor  �Vendas CRM          � Data �  21/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Retorna o codigo do vistoriador.							   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpC - Codigo do vistoriador.                                ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Dicionario de dados(SX3)                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Function At270RVist()

Local cCodUser  := __cUserId 	// Codigo do usuario.
Local cCodVist  := ""	   		// Codigo do vistoriador.

DbSelectArea("AA1")
DbSetOrder(4)

If DbSeek(xFilial("AA1")+cCodUser)	
	If AA1->AA1_VISTOR == "1"
		cCodVist := AA1->AA1_CODTEC
	EndIf  
EndIf

Return( cCodVist )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270VdAge �Autor  �Vendas CRM          � Data �  19/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Valida agendamento do vistoriador.						   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                    ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270                                                      ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Function At270VdAge(oMdl)

Local aAreaAAT	:= AAT->(GetArea())			   		   			// Guarda a area atual da tabela AA1.
Local nOperation	:= oMdl:GetOperation()					   		// Numero da operacao( 1=Visualizar; 3=Incluir; 4=Alterar; 5=Excluir ).
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")			   		// Obtem o modelo de dados AATMASTER.
Local cCodVis		:= oMdlAAT:GetValue("AAT_CODVIS")				// Codigo da vistoria.
Local cVistor		:= oMdlAAT:GetValue("AAT_VISTOR")				// Codigo do vistoriador.
Local dDtIni		:= oMdlAAT:GetValue("AAT_DTINI")				// Data inicial.
Local cHrIni		:= oMdlAAT:GetValue("AAT_HRINI")   			// Hora inicial.
Local dDtFim		:= oMdlAAT:GetValue("AAT_DTFIM")				// Data final. 
Local cHrFim		:= oMdlAAT:GetValue("AAT_HRFIM")   			// Hora final.
Local cAgendado	:= "2"												// Status agendado.
Local lRetorno	:= .T.							  					// Retorno da validacao.
Local nChvIni		:= Val(DtoS(dDtIni)+StrTran(cHrIni,":",""))	// Chave inicial digitada.
Local nChvIniP	:= 0                                         	// Chave inicial posicionada.
Local nChvFim		:= Val(DtoS(dDtFim)+StrTran(cHrFim,":",""))  	// Chave final digitada.
Local nChvFimP	:= 0 												// Chave final posicionada.
Local lAgendAbb	:= SuperGetMv("MV_ATVTABB",,.F.)   			// Controla agenda pela ABB

If !lAgendAbb
	DbSelectArea("AAT")
	DbSetOrder(3)

	If DbSeek(xFilial("AAT")+cVistor+cAgendado)
		While AAT->(!Eof()) .AND. AAT->AAT_FILIAL == xFilial("AAT") .AND.;
		      AAT->AAT_VISTOR == cVistor .AND. AAT->AAT_STATUS == "2"		

			nChvIniP	:= Val(DtoS(AAT->AAT_DTINI)+StrTran(AAT->AAT_HRINI,":",""))
			nChvFimP	:= Val(DtoS(AAT->AAT_DTFIM)+StrTran(AAT->AAT_HRFIM,":",""))
		   
			If ( ( nChvIniP >= nChvIni .AND. nChvIniP <= nChvFim ) .OR.;
			     ( nChvFimP >= nChvIni .AND. nChvFimP <= nChvFim ) .OR.;
			     ( nChvIni >= nChvIniP .AND. nChvIni <= nChvFimP ) .OR.;
			     ( nChvFim >= nChvIniP .AND. nChvFim <= nChvFimP ) )
				   			
				If ( ( nOperation == 3 .OR. nOperation == 4 ) .AND. !( AAT->AAT_CODVIS == cCodVis ) )
					//�������������������������������������������������������������������������������Ŀ
					//�	 Problema: O per�odo informado se encontra agendado em outra vistoria t�cnica.�
					//�	 Solucao: Alterar o per�odo informado.									      �
					//���������������������������������������������������������������������������������
					Help(" ",1,"AT270PERAG")
					lRetorno := .F.
				EndIf
			EndIf
			AAT->(DbSkip())
		EndDo
	EndIf
EndIf

RestArea(aAreaAAT)

Return( lRetorno )


/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa  �At270VdPro �Autor  �Vendas CRM          � Data �  28/03/12     ���
����������������������������������������������������������������������������͹��
���Desc.     �Valida se ja existe uma vistoria tecnica aberta ou atendida    ���
���          �cadastrada somente para oportunidade selecionada pelo usuario. ���
����������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                      ���
����������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                     ���
����������������������������������������������������������������������������͹��
���Uso       �TECA270                                                        ���
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/

Function At270VdOpo()

Local aAreaAD1	:= AD1->(GetArea())      			// Guarda a area atual.
Local oMdl 	 	:= FWModelActive() 	 				// Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cCodOpo	:= oMdlAAT:GetValue("AAT_OPORTU") 	// Codigo da oportunidade.
Local lMultVist := SuperGetMv("MV_MULVIST",,.F.)   // Multiplas Vistorias.
Local lRetorno 	:= .T. 								// Retorno da validacao.

DbSelectArea("AD1")
DbSetOrder(1)

If DbSeek(xFilial("AD1")+cCodOpo)
	
	If AD1->AD1_STATUS == "1"
		
		If !lMultVist
			
			If !Empty(AD1->AD1_CODVIS)
				If AD1->AD1_VISTEC == "1" .AND. AD1->AD1_SITVIS == "1"
					//��������������������������������������������������������������������������������������������������Ŀ
					//�	 Problema: J� existe uma vistoria t�cnica em aberto para esta oportunidade de venda.             �
					//�	 Solucao: Selecione uma outra oportunidade ou cancele a vistoria aberta para esta oportunidade.  �
					//����������������������������������������������������������������������������������������������������
					Help(" ",1,"AT270OPOAB")
					lRetorno := .F.
				ElseIf AD1->AD1_VISTEC == "1" .AND. AD1->AD1_SITVIS == "2"
					//���������������������������������������������������������������������������������������������������Ŀ
					//�	 Problema: J� existe uma vistoria t�cnica agendada para esta oportunidade de venda.               �
					//�	 Solucao: Selecione uma outra oportunidade ou cancele a vistoria agendada para esta oportunidade. �
					//�����������������������������������������������������������������������������������������������������
					Help(" ",1,"AT270OPOAG")
					lRetorno := .F.
				EndIf
			EndIf
			
		EndIf
	Else
		//������������������������������������������������������������������������������������������Ŀ
		//�	 Problema: Solicita��o de vistoria t�cnica somente para oportunidade de venda em aberto. �
		//�	 Solucao: Selecione uma oportunidade em aberto ou inclua uma nova oportunidade.			 �
		//��������������������������������������������������������������������������������������������
		lRetorno := .F.
		Help("",1,"AT270OPABR")
	EndIf
	
EndIf

RestArea(aAreaAD1)
Return( lRetorno )


/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270VdPro �Autor  �Vendas CRM          � Data �  28/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Valida se ja existe uma vistoria tecnica aberta ou atendida  ���
���          �cadastrada para proposta / revisao selecionada pelo usuario. ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                    ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270                                                      ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Function At270VdPro()

Local aAreaADY	:= AAT->(GetArea())
Local oMdl 	 	:= FWModelActive() 	 				// Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cCodPro	:= oMdlAAT:GetValue("AAT_PROPOS")	// Codigo da proposta.
Local lMultVist := SuperGetMv("MV_MULVIST",,.F.)   // Multiplas Vistorias.
Local lRetorno 	:= .T.								// Retorno da validacao.

DbSelectArea("ADY")
DbSetOrder(1)

If !lMultVist
	If DbSeek(xFilial("ADY")+cCodPro) .AND. !Empty(ADY->ADY_CODVIS)
		If ADY->ADY_VISTEC ==  "1" .AND. ADY->ADY_SITVIS == "1"
			//��������������������������������������������������������������������������������������������������Ŀ
			//�	 Problema: J� existe uma vistoria t�cnica em aberto para esta proposta comercial.                �
			//�	 Solucao: Selecione uma outra proposta ou cancele a vistoria t�cnica associado a esta proposta.  �
			//����������������������������������������������������������������������������������������������������
			Help(" ",1,"AT270PRPAB")
					lRetorno := .F.
		ElseIf ADY->ADY_VISTEC ==  "1" .AND. ADY->ADY_SITVIS == "2"
			//��������������������������������������������������������������������������������������������������Ŀ
			//�	 Problema: J� existe uma vistoria t�cnica agendada para esta proposta comercial.                 �
			//�	 Solucao: Selecione uma outra proposta ou cancele a vistoria t�cnica associado a esta proposta.  �
			//����������������������������������������������������������������������������������������������������
			Help(" ",1,"AT270PRPAG")
			lRetorno := .F.
		EndIf
	EndIf
EndIf 

RestArea(aAreaADY)
Return( lRetorno )


/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270Oport �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Preenche os campos da tabela AAT(Vist. Tecnica Cabe�alho)	   ���
���          �relacionado a oport. de venda a partir do campo AAT_ENTIDA   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpC - Numero da Entidade                                    ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Gatilho(SX7)                                       ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Function At270Oport()

Local oMdl 	 	:= FWModelActive() 	 							// Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")					// Obtem o modelo de dados AATMASTER.
Local cOport	:= Alltrim(oMdlAAT:GetValue("AAT_OPORTU"))		// Codigo da oportunidade.
Local cRevisao	:= Alltrim(oMdlAAT:GetValue("AAT_OREVIS")) 		// Revisao da oportunidade.
Local cEntidade	:= ""											// Entidade cliente.
Local cNomEnt	:= "" 											// Nome da entidade.
Local cNoVend	:= ""											// Nome do vendedor.
Local aAreaAD1	:= AD1->(GetArea())  							// Guarda area da tabela AD1.

DbSelectArea("AD1")
DbSetOrder(1)

If DbSeek(xFilial("AD1")+cOport+cRevisao)	
	//����������������������Ŀ
	//� Cliente ou Prospect. �
	//������������������������
	If !( Empty(AD1->AD1_CODCLI) .AND. Empty(AD1->AD1_LOJCLI) )
		cEntidade := "1"
		oMdlAAT:SetValue("AAT_CODENT",AD1->AD1_CODCLI)
		oMdlAAT:SetValue("AAT_LOJENT",AD1->AD1_LOJCLI)
		cNomEnt := Alltrim( Posicione("SA1",1,xFilial("SA1")+AD1->AD1_CODCLI+AD1->AD1_LOJCLI,"A1_NOME") )
	Else
		cEntidade := "2"
		oMdlAAT:SetValue("AAT_CODENT",AD1->AD1_PROSPE)
		oMdlAAT:SetValue("AAT_LOJENT",AD1->AD1_LOJPRO)
		cNomEnt := Alltrim( Posicione("SUS",1,xFilial("SUS")+AD1->AD1_PROSPE+AD1->AD1_LOJPRO,"US_NOME") )
	EndIf
	//�������������������Ŀ
	//� Nome da entidade. �
	//���������������������
	oMdlAAT:SetValue("AAT_NOMENT",cNomEnt)
	//�����������������������������������������Ŀ
	//� Vendedor responsavel pela oportunidade. �
	//�������������������������������������������
	oMdlAAT:SetValue("AAT_VEND",AD1->AD1_VEND)
	cNoVend := Alltrim( Posicione("SA3",1,xFilial("SA3")+AD1->AD1_VEND,"A3_NOME") )
	oMdlAAT:SetValue("AAT_NOMVEN",cNoVend)
	
EndIf

RestArea(aAreaAD1)
Return( cEntidade )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270RNEnt �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Retorna o nome da entidade (Cliente ou Prospect) no campo    ���
���          �AAT_NOMENT                                                   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpC - Nome da Entidade                                      ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Dicionario de dados(SX3)                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Function At270RNEnt()

Local oMdl 	 	:= FWModelActive() 	 			// Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")	// Obtem o modelo de dados.
Local cNomEnt	:= "" 							// Nome da entidade.

If !( oMdl:nOperation == 3 ) .And. IsInCallStack("TECA270")
	If ( oMdlAAT:GetValue("AAT_ENTIDA") == "1" )
		cNomEnt := Alltrim( Posicione("SA1",1,xFilial("SA1")+oMdlAAT:GetValue("AAT_CODENT")+oMdlAAT:GetValue("AAT_LOJENT"),"A1_NOME") )
	Else
		cNomEnt := Alltrim( Posicione("SUS",1,xFilial("SUS")+oMdlAAT:GetValue("AAT_CODENT")+oMdlAAT:GetValue("AAT_LOJENT"),"US_NOME") )
	EndIf
ElseIf IsInCallStack("TECA500")
	If AAT->AAT_ENTIDA == "1"
		cNomEnt := Alltrim( Posicione("SA1",1,xFilial("SA1")+AAT->AAT_CODENT+AAT->AAT_LOJENT,"A1_NOME") )
	Else
		cNomEnt := Alltrim( Posicione("SUS",1,xFilial("SUS")+AAT->AAT_CODENT+AAT->AAT_LOJENT,"US_NOME") )
	EndIf	
EndIf

Return( cNomEnt )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270RNBrw �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Retorna o nome da Entidade / Vistoriador no Browse.          ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpC - Nome da Entidade / Vistoriador                        ���
��������������������������������������������������������������������������͹��
���Parametros�ExpC1 - Campo					                               ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Browse                                             ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Function At270RNBrw(cCampo)

Local cNome := ""	 	// Nome da entidade.

Do Case
	
	Case ( cCampo == "AAT_NOMENT" .AND. AAT->AAT_ENTIDA == "1" )
		cNome := Alltrim( Posicione("SA1",1,xFilial("SA1")+AAT->AAT_CODENT+AAT->AAT_LOJENT,"A1_NOME") )
	Case ( cCampo == "AAT_NOMENT" .AND. AAT->AAT_ENTIDA == "2" )
		cNome := Alltrim( Posicione("SUS",1,xFilial("SUS")+AAT->AAT_CODENT+AAT->AAT_LOJENT,"US_NOME") )
	Case ( cCampo == "AAT_NOMVIS" )
		cNome := Alltrim( Posicione("AA1",1,xFilial("AA1")+AAT->AAT_VISTOR,"AA1_NOMTEC") )
		
EndCase

Return( cNome )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270VdDHr �Autor  �Vendas CRM          � Data �  06/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Verifica se a data / hora fim e maior ou igual que a data /  ���
���			 �hora inicio.												   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                    ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Dicionario de dados(SX3)                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

Function At270VdDHr()

Local oMdl 	:= FWModelActive() 	 				// Retorna o model ativo.
Local oMdlAAT	:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local dDtIni	:= oMdlAAT:GetValue("AAT_DTINI")	// Data inicial.
Local cHrIni	:= oMdlAAT:GetValue("AAT_HRINI")	// Hora inicial.
Local dDtFim	:= oMdlAAT:GetValue("AAT_DTFIM")	// Data final.
Local cHrFim	:= oMdlAAT:GetValue("AAT_HRFIM")	// Hora final.
Local lRetorno	:= .T.								// Retorno da validacao.
Local lAgendAbb		:= SuperGetMv("MV_ATVTABB",,.F.)   					// Controla agenda pela ABB

If !lAgendAbb
	lRetorno := AtVldDiaHr( dDtIni, dDtFim, cHrIni, cHrFim )
	
	If lRetorno .AND. !Empty(dDtIni) .AND. !Empty(dDtFim) .AND. dDtFim < dDtIni
		lRetorno := .F.
	EndIf
EndIf

If !lRetorno
	//���������������������������������������������������Ŀ
	//�	 Problema: Per�odo de agendamento inv�lido.       �
	//�	 Solucao: Informe outro per�odo.   				  �
	//�����������������������������������������������������
	Help("",1,"AT270VLDATAHR")                  
	lRetorno := .F.
EndIf

Return( lRetorno )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270VdPrd �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Valida o produto.								   	           ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                    ���
��������������������������������������������������������������������������͹��
���Parametros�ExpC1 - Modelo de Dados.                                     ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270                                                      ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Function At270VdPrd(cMdDetail)

Local aAreaDA1	:= DA1->(GetArea())									// Guarda a area atual da tabela DA1.
Local aAreaSB1	:= SB1->(GetArea())									// Guarda a area atual da tabela SB1.
Local oMdl 	 	:= FWModelActive() 	 									// Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")							// Obtem o modelo de dados AATMASTER.
Local oMdlAtu 	:= oMdl:GetModel(cMdDetail)			   					// Obtem o modelo de dados corrente( PRDDETAIL / ACEDETAIL ).
Local cCodOpo	:= oMdlAAT:GetValue("AAT_OPORTU")						// Codigo da oportunidade.
Local cRevOpo	:= oMdlAAT:GetValue("AAT_OREVIS")						// Revisao da oportunidade.
Local cTabPrc	:= oMdlAAT:GetValue("AAT_TABELA")						// Codigo da tabela de precos.
Local cCodProd	:= oMdlAtu:GetValue("AAU_PRODUT")						// Codigo do produto.
Local aPrdSel	:= {}													// Array que contem Produto / Acessorios.
Local lRetorno 	:= .T.	 												// Retorno da Validacao.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Oportunidade de venda n�o informado.                               �
	//�	 Solucao: Informe a oportunidade de venda no cabe�alho da vistoria t�cnica.   �
	//���������������������������������������������������������������������������������
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
EndIf

If ( lRetorno .AND. !Empty(cCodProd) ) 

	lRetorno := ExistCpo("SB1",cCodProd,1) 
	
	If lRetorno		
	
		DbSelectArea("DA1")
		DbSetOrder(1)

		DbSelectArea("SB1")
		DbSetOrder(1)
		
		If DbSeek(xFilial("SB1")+cCodProd)
			//��������������������������������������Ŀ
			//� Existe acesssorio para este produto? �
			//���������������������������������������� 
			If cMdDetail == "PRDDETAIL"
				aPrdSel := At600Prd(cCodProd) 
			EndIf
			//����������������������Ŀ 
			//� Produto x acessorio? �
			//������������������������  
			If Len(aPrdSel) > 1
				If cMdDetail == "PRDDETAIL" .AND. nLine <> oMdlAtu:GetLine()
					nLine := oMdlAtu:GetLine()
					At270VdPxA(aPrdSel,/*lCategoria*/,/*lImpProp*/,/*lSimulador*/)
				EndIf
				nLine := 0
			Else
				oMdlAtu:SetValue("AAU_DESCRI",SB1->B1_DESC)
				oMdlAtu:SetValue("AAU_UM",SB1->B1_UM)
				
				If DA1->(DbSeek(xFilial("DA1") + cTabPrc + cCodProd )) .AND. (DA1->DA1_MOEDA <> 0)
					oMdlAtu:SetValue("AAU_MOEDA",Str(DA1->DA1_MOEDA,1))
				Else
					oMdlAtu:SetValue("AAU_MOEDA","1")
				EndIf		
				oMdlAtu:SetValue("AAU_QTDVEN",1)
			EndIf	
		EndIf
	EndIf   

EndIf

RestArea(aAreaDA1)
RestArea(aAreaSB1)

Return ( lRetorno )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270CTot  �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Calcula o valor total do produto.							   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpN - Valor Total do Produto                                ���
��������������������������������������������������������������������������͹��
���Parametros�ExpC1 - Modelo de Dados.                                     ���
���			 �ExpC2 - Nome do Campo 									   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Gatilho(SX7)                                       ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Function At270CTot(cMdDetail,cCampo)

Local oMdl 	 	:= FWModelActive()										// Retorna o model ativo.
Local oMdlAAT		:= oMdl:GetModel("AATMASTER")							// Obtem o modelo de dados AATMASTER.
Local oMdlAtu		:= oMdl:GetModel(cMdDetail)			   	   				// Obtem o modelo de dados corrente( PRDDETAIL / ACEDETAIL ).
Local cCodEnt		:= oMdlAAT:GetValue("AAT_CODENT")						// Codigo da entidade.
Local cLojEnt		:= oMdlAAT:GetValue("AAT_LOJENT") 						// Codigo de loja da entidade.
Local cTabPrc		:= oMdlAAT:GetValue("AAT_TABELA") 						// Codigo da tabela de precos.
Local cCodProd	:= oMdlAtu:GetValue("AAU_PRODUT") 						// Codigo do produto.
Local nQtdVen		:= oMdlAtu:GetValue("AAU_QTDVEN") 						// Quantidade do produto.
Local cMoeda		:= oMdlAtu:GetValue("AAU_MOEDA")  						// Moeda utilizada.
Local nPrcVen		:= oMdlAtu:GetValue("AAU_PRCVEN")  					// Preco de Venda.
Local lProspect	:= IIF(oMdlAAT:GetValue("AAT_ENTIDA")== "2",.T.,.F.)	// Verifica se entidade e prospect.
Local nDecTot		:= TamSX3("AAU_VLRTOT")[2]     							// Numero de decimais do campo AAU_VLRTOT.
Local nVlrTot		:= 0   													// Valor total do produto.
Local bTotal		:= {|nQtd,nUnit, nDecs| Round(nQtd * nUnit,nDecs)}	// Calculo do valor total Quantidade x Preco Unitario.

If ( cCampo == "AAU_QTDVEN" )	 
	//�����������������������Ŀ
	//� Calcula o valor total.�
	//�������������������������
	nPrcVen := MaTabPrVen( cTabPrc,cCodProd,nQtdVen,cCodEnt,cLojEnt,Val(cMoeda),/*dDataVld*/,/*nTipo*/,/*lExec*/,/*lAtuEstado*/,lProspect )
	If nPrcVen == 0
		nPrcVen := oMdlAtu:GetValue("AAU_PRCVEN")
	EndIf	
	oMdlAtu:SetValue("AAU_PRCVEN",nPrcVen)
	oMdlAtu:SetValue("AAU_PRCTAB",nPrcVen)
	nVlrTot := Eval(bTotal,nQtdVen,nPrcVen,nDecTot)
ElseIf ( cCampo == "AAU_PRCVEN" )	
	nVlrTot := Eval(bTotal,nQtdVen,nPrcVen,nDecTot)
EndIf

Return( nVlrTot )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270CTPrd �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Categoria de produtos. 									   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                    ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270							                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270CTPrd()

Local oMdl			:= FWModelActive()					// Retorna o model ativo.
Local oMdlAAT		:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cCodOpo		:= oMdlAAT:GetValue("AAT_OPORTU")	// Codigo da oportunidade.
Local cRevOpo		:= oMdlAAT:GetValue("AAT_OREVIS")	// Revisao da oportunidade.
Local aPrdSel		:= {}									// Array que contem Produto / Acessorios.
Local lCategoria	:= .T.                            	// Categoria de Produto.
Local lRetorno	:= .T.									// Retorno da validacao.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Oportunidade de venda n�o informado.                               �
	//�	 Solucao: Informe a oportunidade de venda no cabe�alho da vistoria t�cnica.   �
	//���������������������������������������������������������������������������������
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	//�������������������������������������������Ŀ
	//� Rotina de selecao de categoria e produtos.�
	//���������������������������������������������
	aPrdSel := FATA610()
	//�����������������������������������������������������Ŀ
	//� Adiciona e Valida os produtos / acessorios no grid. �
	//�������������������������������������������������������
	If Len(aPrdSel) > 0
		At270VdPxA(aPrdSel,lCategoria,/*lImpProp*/,/*lSimulador*/) 
	EndIf	
EndIf

Return( lRetorno )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270Simul �Autor  �Vendas CRM          � Data �  22/03/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �CRM Simulador												   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso		                               ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270							                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270Simul()

Local aAreaAF1	:= AF1->(GetArea())					// Area da tabela AF1.
Local oMdl			:= FWModelActive()					// Retorna o model ativo.
Local oMdlAAT		:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local oMdlPrd		:= oMdl:GetModel("PRDDETAIL")		// Obtem o modelo de dados PRDDETAIL.
Local cCodVis		:= oMdlAAT:GetValue("AAT_CODVIS")  // Codigo da vistoria.
Local cCodOpo		:= oMdlAAT:GetValue("AAT_OPORTU") 	// Codigo da oportunidade.
Local cRevOpo		:= oMdlAAT:GetValue("AAT_OREVIS") 	// Revisao da oportunidade.
Local cCateg		:= ""									// Codigo da categoria.
Local cTipo		:= "3" 								// Vistoria tecnica.
Local aPrdSel		:= {}									// Array que contem Produto / Acessorios.
Local aHeadSrv	:= {}									// Array com o Cabecalho da tabela AF3.
Local aColsSrv	:= {}									// Array com os Produtos da tabela AF3.
Local aAcessorio	:= {}									// Array com os acessorios.
Local nX			:= 0  									// Incremento utilizado no laco For.
Local nY			:= 0									// Incremento utilizado no laco For.
Local lSimulador	:= .T.									// Define se a validacao do produto x acessorio e especifico para o CRM Simulador.
Local lRetorno	:= .T.									// Retorno da validacao.
Local lDelLine	:= .F.									// Deleta linha.
Local lSeekLine	:= 0                          		// Procura linha especifica.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Oportunidade de venda n�o informado.                               �
	//�	 Solucao: Informe a oportunidade de venda no cabe�alho da vistoria t�cnica.   �
	//���������������������������������������������������������������������������������
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	
	lRetorno := FATA530C(3,cCodVis)
	
	If 	lRetorno
		
		DbSelectArea("AF1")
		DbSetOrder(4)
		If DbSeek(xFilial("AF1")+cCodVis+cTipo)
			Ft530Prod(@aHeadSrv,@aColsSrv,AF1->AF1_ORCAME)
		Endif
		
		//�����������������������������������������������������Ŀ
		//� Apaga itens deletados no CRM Simulador na Vistoria. �
		//�������������������������������������������������������
		For nX := 1 To oMdlPrd:Length()
			lDelLine := .F.
			oMdlPrd:GoLine(nX)
			If Alltrim(oMdlPrd:GetValue("AAU_PMS")) == Alltrim(AF1->AF1_ORCAME)
				lDelLine := (aScan(aColsSrv,{|x| AllTrim(x[1]) == AllTrim(oMdlPrd:GetValue("AAU_PRODUT"))}) == 0)
				If lDelLine .AND. !oMdlPrd:IsDeleted()
					oMdlPrd:DeleteLine()
				EndIf
			EndIf
		Next nX
		
		If Len(aColsSrv) > 0
			
			For nX := 1 To Len(aColsSrv)
				
				lSeekLine := oMdlPrd:SeekLine({{"AAU_PRODUT",Alltrim(aColsSrv[nX][1])},{"AAU_PMS",Alltrim(AF1->AF1_ORCAME)}})
				
				If !lSeekLine
					
					aAdd(aPrdSel,{	aColsSrv[nX][1] 	,;
									aColsSrv[nX][2] 	,;
				  					cCateg				,;
				   					"000000"			,;
				   					"P"					,;
									aColsSrv[nX][4]		,;
									AF1->AF1_ORCAME})        
									
					//��������������������������������������������������������������������Ŀ
					//� Valida a existencia de acessorios (KIT) para o produto selecionado.�
					//����������������������������������������������������������������������
					A610Acessorio(aColsSrv[nX][1],cCateg,@aAcessorio)
					
					For nY := 1 To Len(aAcessorio)
						aAdd(aPrdSel,{	aAcessorio[nY][1] ,;
										aAcessorio[nY][2] ,;
					   					aAcessorio[nY][3] ,;
										aAcessorio[nY][4] ,;
					   					aAcessorio[nY][5] ,;
										aAcessorio[ny][6] ,;
					   					""}	)
					Next nY
					
					aAcessorio := {}
					
				Else
					
					If oMdlPrd:IsDeleted() 
						//�����������������������������������������������������������������Ŀ
	   					//� Recupera o item deletado na vistoria presente no CRM Simulador. �
	  					//�������������������������������������������������������������������
						oMdlPrd:UnDeleteLine()
						oMdlPrd:SetValue("AAU_QTDVEN",aColsSrv[nX][4])
					Else
						oMdlPrd:SetValue("AAU_QTDVEN",aColsSrv[nX][4])
					EndIf
					
				EndIf
				
			Next nX
		    
		    //������������������������������Ŀ
			//� Posiciona na primeira linha. �
			//��������������������������������
		    oMdlPrd:GoLine(1)
		   
			//����������������������������������������������������Ŀ
			//� Adiciona e Valida os produtos / acessorios no grid.�
			//������������������������������������������������������
			If Len(aPrdSel) > 0
				At270VdPxA(aPrdSel,/*lCategoria*/,/*lImpProp*/,lSimulador)
			EndIf 
			
		EndIf
		
	EndIf
	
EndIf

RestArea(aAreaAF1)

Return( lRetorno )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270VdPxA �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Valida Produtos e Acessorios para adicionar no grid.	       ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro				                               ���
��������������������������������������������������������������������������͹��
���Parametros�ExpA1 - Array que contem Produto / Acessorios.               ���
���			 �ExpL2 - Validacao especifica para importacao de proposta.	   ���
���			 �ExpL3 - Validacao especifica para o CRM Simulador.		   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270				                                       ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270VdPxA(aPrdSel,lCategoria,lImpProp,lSimulador, oMdl, aPrpXOrc)

Local oMdlAAT 	:= Nil								// Obtem o modelo de dados AATMASTER.
Local oMdlAtu		:= Nil														// Modelo de dados corrente( PRDDETAIL / ACEDETAIL ).
Local cCodEnt  	:= Nil							// Codigo da entidade.
Local cLojEnt		:= Nil							// Codigo de loja da entidade.
Local cTabPrc		:= Nil							// Codigo da tabela de precos.
Local nLinha		:= 0														// Linha atual.
Local cItemPrd	:= 0														// Item atual do produto.
Local cItemPai	:= 0														// Item pai(produto) para ser relacionado ao acessorio.
Local nX			:= 0														// Incremento utilizado no laco For.
Local lProspect 	:= Nil 		// Verifica se entidade e prospect.
Local lAddLine	:= .F. 														// Adiciona linha.
Local nPPrpXOrc	:= 0

Default lCategoria	:= .F.  													// Categoria de Produto.
Default lImpProp    := .F.														// Validacao especifica para importacao de proposta.
Default lSimulador	:= .F.     													// Validacao especifica para o CRM Simulador.
Default oMdl 		    := FWModelActive() 	 										// Retorna o model ativo.

oMdlAAT 	:= oMdl:GetModel("AATMASTER")
cCodEnt 	:= oMdlAAT:GetValue("AAT_CODENT")
cLojEnt 	:= oMdlAAT:GetValue("AAT_LOJENT")
cTabPrc   	:= oMdlAAT:GetValue("AAT_TABELA")
lProspect	:= IIF(oMdlAAT:GetValue("AAT_ENTIDA")== "2",.T.,.F.)

DbSelectArea("DA1")
DbSetOrder(1)

DbSelectArea("SB1")
DbSetOrder(1)

//������������������������������������������������������������Ŀ
//� Forca adicionar uma nova linha para Categoria de Produtos, �
//� Importacao de Proposta,Simulador.                          �
//��������������������������������������������������������������
lAddLine := ( lCategoria .OR. lImpProp .OR. lSimulador )

For nX := 1 To Len(aPrdSel)
	
	If aPrdSel[nX][5] == "P"
		oMdlAtu  := oMdl:GetModel("PRDDETAIL")
	Else
		oMdlAtu  := oMdl:GetModel("ACEDETAIL")
	EndIf
	
	If (nX == 1 .AND. !Empty(oMdlAtu:GetValue("AAU_PRODUT")) .AND.lAddLine ) .OR. ( nX > 1 .AND. !Empty(oMdlAtu:GetValue("AAU_PRODUT")))
		nLinha := oMdlAtu:AddLine()
		If nLinha > 0
			oMdlAtu:GoLine(nLinha)
		EndIf
	EndIf
	
	cItemPrd := StrZero(oMdlAtu:Length(),TamSX3("AAU_ITEM")[1])
	
	If aPrdSel[nX][5] == "P"
		cItemPai := cItemPrd
	EndIf
	
	SB1->(dbSeek(xFilial("SB1")+aPrdSel[nX][1]))
	
	oMdlAtu:SetValue("AAU_ITEM",    cItemPrd)
	oMdlAtu:LoadValue("AAU_PRODUT", aPrdSel[nX][1])
	oMdlAtu:SetValue("AAU_DESCRI",  SB1->B1_DESC)
	oMdlAtu:SetValue("AAU_UM",      SB1->B1_UM)      
	
	If DA1->(DbSeek(xFilial("DA1") + cTabPrc + aPrdSel[nX][1] )) .AND. (DA1->DA1_MOEDA <> 0)
		If lImpProp
			//��������������������������������������Ŀ
   			//� Mantem a moeda definida na prospota. �
   			//����������������������������������������
			oMdlAtu:SetValue("AAU_MOEDA",aPrdSel[nX][7])
		Else
			oMdlAtu:SetValue("AAU_MOEDA",Str(DA1->DA1_MOEDA,1))
		EndIf
	Else
		oMdlAtu:SetValue("AAU_MOEDA","1")
	EndIf
	
	oMdlAtu:SetValue("AAU_QTDVEN",aPrdSel[nX][6])
	
	If lImpProp .AND. Empty(cTabPrc)
		//��������������������������������������������������������������������������������������Ŀ
  		//� Mantem o valor unitario da proposta se o vistoriador nao optar pela tabela de preco. �
   		//����������������������������������������������������������������������������������������
		nPrcVen := aPrdSel[nX][8]
	Else
		nPrcVen := MaTabPrVen( cTabPrc,aPrdSel[nX][1],aPrdSel[nX][6],cCodEnt,cLojEnt,Val(oMdlAtu:GetValue("AAU_MOEDA")),/*dDataVld*/,/*nTipo*/,/*lExec*/,/*lAtuEstado*/,lProspect  )
	EndIf
	
	oMdlAtu:SetValue("AAU_PRCVEN",nPrcVen)	
	
	//������������������������������������������������������������Ŀ
 	//� Importa o tipo de produto e define o item pai da proposta. �
  	//��������������������������������������������������������������
	If lImpProp
   		oMdlAtu:SetValue("AAU_TPPROD",aPrdSel[nX][9])
   		oMdlAtu:SetValue("AAU_ITPROP",aPrdSel[nX][11])
	EndIf                                                     
	
	//����������������������������Ŀ
 	//� Define o pai do acessorio. �
  	//������������������������������
	If oMdlAtu:GetId() == "ACEDETAIL"  .AND. aPrdSel[nX][5] <> "P"
		If ( lImpProp )
			If ( aPrdSel[nX][12] == "PxA" ) 
				oMdlAtu:SetValue("AAU_ITPAI",cItemPai)
			EndIf
		Else
			oMdlAtu:SetValue("AAU_ITPAI",cItemPai)
		EndIf
	EndIf
	
	If lSimulador
		//�������������������������������������������������������������������Ŀ
  		//� Relaciona o codigo do orcamento do simulador ao produto do grid   �
  		//� caso o usuario utilizar o CRM Simulador para elaborar a vistoria. �  		
  		//���������������������������������������������������������������������
		oMdlAtu:SetValue("AAU_PMS",aPrdSel[nX][7])
	EndIf

	If	( nPPrpXOrc := aScan(aPrpXOrc,{|x| x[01] == aPrdSel[nX][1]}) ) > 0
		aPrpXOrc[nPPrpXOrc,04]	:= cItemPrd
	EndIf

Next nX 

//���������������������������������������������Ŀ
//� Posiciona na primeira linha da aba produto. �	
//�����������������������������������������������
If ( lCategoria .OR. lImpProp .OR. lSimulador )
	oMdl:GetModel("PRDDETAIL"):GoLine(1)
EndIf

//�������������������������������������������������������������Ŀ
//� Posiciona na primeira linha caso o acessorio do produto ser �
//� carregado automaticamente. 									�  		
//���������������������������������������������������������������
If ValType(oMdlAtu) == "O" .AND. oMdlAtu:GetId() == "ACEDETAIL"
	oMdlAtu:GoLine(1)
EndIf

Return ( .T. )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270DLin  �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Validacao do delete da linha.                       	       ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro 		                                   ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270							                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270DLin(oMdlPrd,nLinha,cAction)

Local oMdl 	 	:= FWModelActive() 	 						// Retorna o model ativo.
Local oView		:= FwViewActive() 							// Retorna a view ativa.
Local oMdlAce		:= oMdl:GetModel("ACEDETAIL")				// Obtem o modelo de dados ACEDETAIL.
Local cItemPai	:= oMdlPrd:GetValue("AAU_ITEM")				// Item pai(produto).
Local nX		:= 0										// Incremento utilizado no laco For.

If oMdl:GetId() == "TECA270"

	For nX := 1 To oMdlAce:Length()
		oMdlAce:GoLine(nX)
		If oMdlAce:GetValue("AAU_ITPAI") == cItemPai
			If cAction == "DELETE" .AND. !oMdlAce:IsDeleted()
				oMdlAce:DeleteLine()
			ElseIf cAction == "UNDELETE" .AND. oMdlAce:IsDeleted()
				oMdlAce:UnDeleteLine()
			EndIf
		EndIf
	Next nX
	
	If ValType(oView) == "O" .And. oView:GetModel():GetId() == "TECA270"
		oMdlAce:GoLine(1)             
	  	oView:Refresh("VIEW_ACE")      
	EndIf

EndIf

Return( .T. )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270VProp �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Visualizacao da proposta comercial.                      	   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso 		                           ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270							                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270VProp()

Local oMdl 	 := FWModelActive() 	 				// Retorna o model ativo.
Local oMdlAAT  := oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cCodOpo	 := oMdlAAT:GetValue("AAT_OPORTU")	// Codigo da oportunidade.
Local cRevOpo	 := oMdlAAT:GetValue("AAT_OREVIS")	// Revisao da oportunidade.
Local cCodPro	 := oMdlAAT:GetValue("AAT_PROPOS") 	// Codigo da proposta comercial.
Local cRevPro	 := oMdlAAT:GetValue("AAT_PREVIS") 	// Revisao da proposta comercial.
Local lRetorno := .T.								// Retorno da validacao.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Oportunidade de venda n�o informado.                               �
	//�	 Solucao: Informe a oportunidade de venda no cabe�alho da vistoria t�cnica.   �
	//���������������������������������������������������������������������������������
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
ElseIf( Empty(cCodPro) .AND. Empty(cRevPro) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Proposta comercial n�o informado.                                  �
	//�	 Solucao: Informe a proposta comercial no cabe�alho da vistoria t�cnica.      �
	//���������������������������������������������������������������������������������
	Help("",1,"PROPREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	
	DbSelectArea("ADY")
	ADY->(dbSetOrder(1))
	
	If ADY->(dbSeek(xFilial("ADY")+cCodPro))				
		FWExecView(STR0038,"VIEWDEF.FATA600",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)  //"Visualizar proposta"                    
	Else
		//������������������������������������������������������������������������Ŀ
		//�	 Problema: Proposta comercial n�o localizada para visualiza��o.        �
		//�	 Solucao: Cadastre uma proposta comercial para esta oportunidade.      �
		//��������������������������������������������������������������������������
		Help("",1,"PROPNAOLOC")
		lRetorno := .F.
	EndIf
	
EndIf

Return( lRetorno )

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270IProp �Autor  �Vendas CRM          � Data �  28/02/12   ���
��������������������������������������������������������������������������͹��
���Desc.     �Importacao da proposta comercial.                     	   ���
��������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso 		                           ���
��������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270							                           ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Static Function At270IProp( oModelVis ) 

Local oMdl 	 	:= If( oModelVis == Nil, FWModelActive(), oModelVis) // Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")							// Obtem o modelo de dados AATMASTER.
Local cCodOpo		:= oMdlAAT:GetValue("AAT_OPORTU") 						// Codigo da oportunidade.
Local cRevOpo		:= oMdlAAT:GetValue("AAT_OREVIS") 						// Revisao da oportunidade.
Local cCodPro		:= oMdlAAT:GetValue("AAT_PROPOS")						// Codigo da proposta comercial.
Local cRevPro		:= oMdlAAT:GetValue("AAT_PREVIS") 						// Revisao da proposta comercial.
Local aProduto	:= {}														// Array que contem os produtos.
Local aAcessorio 	:= {}														// Array que contem os acessorios.
Local aPrdSel	  	:= {}														// Array que contem Produto / Acessorios.
Local aPrpXOrc	:= {}														// Array que contem o relacionamento entre os itens da Proposta x itens do or�amento de servi�os para a montagem do novo or�amento de servi�os que estar� associado � Vistoria.
Local nX			:= 0														// Incremento utilizado no laco For.
Local nI			:= 0	 													// Incremento utilizado no laco For.
Local lImpProp	:= .T.														// Define se a validacao do produto x acessorio e especifico para o Importacao de Propostas.
Local lRetorno	:= .T.														// Retorno da validacao.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Oportunidade de venda n�o informado.                               �
	//�	 Solucao: Informe a oportunidade de venda no cabe�alho da vistoria t�cnica.   �
	//���������������������������������������������������������������������������������
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
ElseIf( Empty(cCodPro) .AND. Empty(cRevPro) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Proposta comercial n�o informado.                                  �
	//�	 Solucao: Informe a proposta comercial no cabe�alho da vistoria t�cnica.      �
	//���������������������������������������������������������������������������������
	Help("",1,"PROPREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	If At("VISPRO",cPerfil) > 0
		// "Deseja visualizar a proposta comercial antes da importa��o?"##"Aten��o"
		If MsgYesNo(STR0021,STR0020)
			//���������������������������������Ŀ
			//�	Visualiza a proposta comercial. �
			//�����������������������������������
			At270VProp()
		EndIf
	EndIf
	// "Deseja importar os produtos / acess�rios da proposta comercial para a vistoria t�cnica?"##"Aten��o"
	If !( MsgYesNo(STR0022,STR0020))
		lRetorno := .F.
	EndIf

	If lRetorno
		DbSelectArea("TFJ")
		TFJ->( DbSetOrder( 6 ) ) // TFJ_FILIAL + TFJ_CODVIS
		If TFJ->( DbSeek( xFilial("TFJ")+oMdlAAT:GetValue("AAT_CODVIS") ) )
			lRetorno := .F.
			Help(,, "AT270HASORCSER",,STR0041,1,0,,,,,,{STR0042})	//"J� existe or�amento de servi�os para esta vistoria." ## "Exclua o existente ou fa�a uma nova vistoria."
		EndIf
	EndIf
EndIf

If lRetorno
	
	DbSelectArea("ADZ")
	DbSetOrder(3)	//ADZ_FILIAL+ADZ_PROPOS+ADZ_REVISA+ADZ_FOLDER+ADZ_ITEM
	
	If DbSeek(xFilial("ADZ")+cCodPro+cRevPro)
		
		While ( ADZ->(!Eof()) .AND.;
		        ADZ->ADZ_FILIAL == xFilial("ADZ") .AND.;
		        ADZ->ADZ_PROPOS == cCodPro .AND.;
		        ADZ->ADZ_REVISA == cRevPro )
			If ADZ->ADZ_FOLDER == "1"
				aAdd(aProduto,{ADZ->ADZ_ITEM,;
				               ADZ->ADZ_PRODUT,;
				               ADZ->ADZ_DESCRI,;
				               ADZ->ADZ_QTDVEN,;
				               ADZ->ADZ_MOEDA,;
				               ADZ->ADZ_PRCVEN,;
				               ADZ->ADZ_TPPROD,;
				               ADZ->ADZ_ITPAI})
				aAdd(aPrpXOrc,{ADZ->ADZ_PRODUT,;
				               ADZ->ADZ_ITEM,;
				               ADZ->ADZ_ITEMOR,;
				               ""})
			Else
				aAdd(aAcessorio,{ADZ->ADZ_ITEM,;
			 	                 ADZ->ADZ_PRODUT,;
			   	                 ADZ->ADZ_DESCRI,;
				                 ADZ->ADZ_QTDVEN,;
				                 ADZ->ADZ_MOEDA,;
				                 ADZ->ADZ_PRCVEN,;
				                 ADZ->ADZ_TPPROD,;
				                 ADZ->ADZ_ITPAI})
			EndIf

			ADZ->(DbSkip())
		EndDo
		
		If Len(aProduto) > 0
			For nX := 1 To Len(aProduto)
				aAdd(aPrdSel,{aProduto[nX][2],;
				              aProduto[nX][3],;
				              "",;
				              "000000",;
				              "P",;
				              aProduto[nX][4],;
				              aProduto[nX][5],;
				              aProduto[nX][6],;
				              aProduto[nX][7],;
				              aProduto[nX][8],;
				              aProduto[nX][1],;
				              ""})

				nPos := aScan(aAcessorio,{|x| x[8] == aProduto[nX][1]})

				If nPos > 0
					For nI := Len(aAcessorio) To 1 Step -1
						If ( aAcessorio[nI][8] == aProduto[nX][1] )
							aAdd(aPrdSel,{aAcessorio[nI][2],;
							              aAcessorio[nI][3],;
							              "",;
							              "000000",;
							              "A",;
							              aAcessorio[nI][4],;
							              aAcessorio[nI][5],;
							              aAcessorio[nI][6],;
							              aAcessorio[nI][7],;
							              aAcessorio[nI][8],;
							              aAcessorio[nI][1],;
							              "PxA"})
							aDel(aAcessorio,nI)
							aSize(aAcessorio,(Len(aAcessorio)-1))
						EndIf
					Next nI
				EndIf
			Next nX
		EndIf
		
		If Len(aAcessorio) > 0
			For nX := 1 To Len(aAcessorio)
				aAdd(aPrdSel,{aAcessorio[nX][2],;
				              aAcessorio[nX][3],;
				              "",;
				              "000000",;
				              "A",;
				              aAcessorio[nX][4],;
				              aAcessorio[nX][5],;
				              aAcessorio[nX][6],;
				              aAcessorio[nX][7],;
				              aAcessorio[nX][8],;
				              aAcessorio[nX][1],;
				              ""})
			Next nX
		EndIf
		
		If Len(aPrdSel) > 0
			lRetorno := At270VdPxA(aPrdSel,/*lCategoria*/,lImpProp,/*lSimulador*/, oMdl, aPrpXOrc)
		EndIf
		
		// Carrega o or�amento de servi�os com os dados da proposta comercial
		If	( lRetorno := ( lRetorno .AND. A600LOrc( Nil, cCodPro, cRevPro, "TECA270", oMdl, aPrpXOrc ) ) )
			MsgAlert(STR0026,STR0020)	//"Vistoria t�cnica importada com sucesso!"#Atencao
		Else
			Help(,,"At270IProp",,STR0043,1,0)	//"Os dados da proposta comercial n�o foram importados para esta vistoria."
		EndIf
	Else
		//�����������������������������������������������������������������������������������������������������Ŀ
		//�	 Problema: N�o h� produtos / acess�rios cadastrados para esta proposta comercial.                   �
		//�	 Solucao: Informe os produtos / acess�rios para esta proposta comercial na oportunidade de venda.   �
		//�������������������������������������������������������������������������������������������������������
		Help("",1,"NOPRDACE")
		lRetorno := .F.
	EndIf
	
EndIf

Return( lRetorno )


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �At270Cmt  �Autor  �Vendas CRM          � Data �  20/03/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Bloco de Commit.       	   						          ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro			                                  ���
�������������������������������������������������������������������������͹��
���Parametros�ExpO1 - Modelo de dados.  		    					  ���  
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Function At270Cmt(oModel) 

Local oMdlAAT		:= oModel:GetModel("AATMASTER")			// Obtem o modelo de dados AATMASTER.
Local cOperation	:= cValToChar(oMdlAAT:GetOperation())	// Numero da operacao.
Local cCodVis		:= oMdlAAT:GetValue("AAT_CODVIS")		// Codigo da vistoria tecnica.
Local cCodOpo		:= oMdlAAT:GetValue("AAT_OPORTU")		// Codigo da oportunidade.
Local cCodPro		:= oMdlAAT:GetValue("AAT_PROPOS")		// Codigo da proposta comercial.
Local cRevPro		:= oMdlAAT:GetValue("AAT_PREVIS")		// Revisao da proposta comercial.
Local cStatus		:= oMdlAAT:GetValue("AAT_STATUS")		// Revisao da proposta comercial.
Local cCodAtend	:= oMdlAAT:GetValue("AAT_VISTOR")		// Revisao da proposta comercial.
Local lMultVist	:= SuperGetMv("MV_MULVIST",,.F.)		// Multipla Vistorias
Local lAgendAbb	:= SuperGetMv("MV_ATVTABB",,.F.)		// Controla agenda pela ABB
Local bAfterTTS	:= {|| .T.}

If !lAgendAbb
	bAfterTTS := {|oModel| At270GvAbb(oModel:GetOperation())}	
	If oModel:GetOperation() == MODEL_OPERATION_INSERT .And. cStatus == "1"
		oModel:LoadValue("AATMASTER","AAT_STATUS","2")
	EndIf
ElseIf lAgendAbb .AND. oModel:GetOperation() == MODEL_OPERATION_DELETE
	bAfterTTS := {|oModel| At270GvAbb(oModel:GetOperation())}
EndIf

If !lMultVist
	// Faz Comit no MVC
	FWModelActive(oModel)
	FWFormCommit(oModel,Nil,{|oModel,cId,cAlias|At270After(oModel,cId,cAlias,cOperation,cCodVis,cCodOpo,cCodPro,cRevPro,cStatus)},bAfterTTS)
Else 
	// Faz Comit no MVC
	FWModelActive(oModel)
	FWFormCommit(oModel,NIL,NIL,bAfterTTS)
EndIf 

// Grava or�amento de servi�o
A600GrvOrc(oModel:GetValue('AATMASTER',"AAT_CODVIS"),oModel)		  

If cOperation == "3" .AND. lAgendAbb
	If MsgYesNo(STR0029,STR0020) //"Deseja agendar esta vistoria t�cnica agora?"#"Aten��o"
		Teca510(,cCodAtend)
	EndIf
EndIf

Return( .T. )
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �At270After�Autor  �Vendas CRM          � Data �  20/03/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Atualiza a oportunidade ou proposta.       		          ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro			                                  ���
�������������������������������������������������������������������������͹��
���Parametros�ExpO1 - Modelo de dados.  		    					  ���  
���			 �ExpC2 - Id do Modelo.  		    	   					  ��� 
���			 �ExpC3 - Alias.  		    		  						  ��� 
���			 �ExpN4 - Operacao.  		    		  					  ��� 
���			 �ExpC5 - Vistoria.  		    	  						  ��� 
���			 �ExpC6 - Oportunidade.  		    				   		  ��� 
���			 �ExpC7 - Proposta.  		    							  ���  
���			 �ExpC8 - Revisao.     				    					  ���  
���			 �ExpC9 - Status.  		    								  ���    
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Function At270After(oModel,cId,cAlias,cOperation,cCodVis,cCodOpo,cCodPro,cRevPro,cStatus)

Local aArea	    := GetArea()      	   		// Area atual.		
Local aAreaAAT	:= AAT->(GetArea())		// Area atual da tabela AAT.
Local aAreaAD1  := AD1->(GetArea())  		// Area atual da tabela AD1.
Local aAreaADY  := ADY->(GetArea())  		// Area atual da tabela ADY.

If ( cId == "AATMASTER" .AND. cAlias == "AAT" )
	
	If !Empty(cCodPro) .AND. !Empty(cRevPro)
		DbSelectArea("ADY")
		DbSetOrder(1)
		If DbSeek(xFilial("ADY")+cCodPro)
			If cOperation $ "3|4"
				RecLock("ADY",.F.)
				ADY->ADY_VISTEC := IIF(cStatus=="4","2","1")
				ADY->ADY_CODVIS := cCodVis
				ADY->ADY_SITVIS := cStatus
				MSUnlock()
			Else
				RecLock("ADY",.F.)
				ADY->ADY_VISTEC := "2"
				ADY->ADY_CODVIS := ""
				ADY->ADY_SITVIS := "4"
				MSUnlock()
			EndIf
		EndIf
	Else
		DbSelectArea("AD1")
		DbSetorder(1)
		If DbSeek(xFilial("AD1")+cCodOpo)
			If cOperation $ "3|4"
				RecLock("AD1",.F.)
				AD1->AD1_VISTEC := IIF(cStatus=="4","2","1")
				AD1->AD1_CODVIS := cCodVis
				AD1->AD1_SITVIS := cStatus
				MSUnlock()
			Else
				RecLock("AD1",.F.)
				AD1->AD1_VISTEC := "2"
				AD1->AD1_CODVIS := ""
				AD1->AD1_SITVIS := "4"
				MSUnlock()
			EndIf
		EndIf
	EndIf
EndIf

RestArea(aAreaAAT)
RestArea(aAreaAD1)
RestArea(aAreaADY)
RestArea(aArea)   

Return( .T. )

/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa  �At270VdSts �Autor  �Vendas CRM          � Data �  28/03/12     ���
����������������������������������������������������������������������������͹��
���Desc.     �Valida o status da vistoria tecnica.						     ���
����������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro / Falso                                      ���
����������������������������������������������������������������������������͹��
���Parametros�Nenhum					                                     ���
����������������������������������������������������������������������������͹��
���Uso       �TECA270                                                        ���
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/
Function At270VdSts()    

Local oMdl			:= FWModelActive() 	 				// Retorna o model ativo.         
Local nOperation	:= oMdl:GetOperation()   		   	// Numero da operacao.
Local oMdlAAT		:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cStatus		:= oMdlAAT:GetValue("AAT_STATUS") 	// Status da vistoria.
Local lRetorno	:= .T.									// Retorno da validacao


If nOperation == 4  

	If ( AAT->AAT_STATUS == "3" .AND. cStatus <> "3" ) 
		//�����������������������������������������������������������������������������������Ŀ
		//�	 Problema: N�o ser� possivel alterar o status de uma vistoria t�cnica concluida.  �
		//�	 Solucao: Inclua uma nova vistoria. 											  �
		//�������������������������������������������������������������������������������������
		Help(" ",1,"AT270STSCON")
		lRetorno := .F. 
	ElseIf ( AAT->AAT_STATUS == "4" .AND. cStatus <> "4" )	  
		//�����������������������������������������������������������������������������������Ŀ
		//�	 Problema: N�o ser� possivel alterar o status de uma vistoria t�cnica cancelada.  �
		//�	 Solucao: Inclua uma nova vistoria. 											  �
		//�������������������������������������������������������������������������������������
		Help(" ",1,"AT270STSCAN")
		lRetorno := .F. 
	EndIf	
	
EndIf
	
Return( lRetorno )   

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �At270Canc �Autor  �Vendas CRM          � Data �  14/07/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Bloco de Cancelamento do Formulario MVC.       	   		  ���
�������������������������������������������������������������������������͹��
���Retorno   �ExpL - Verdadeiro			                                  ���
�������������������������������������������������������������������������͹��
���Parametros�ExpO1 - Modelo de dados.  		    					  ���  
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Function At270Canc(oModel)

Local aAreaAF1		:= AF1->(GetArea())						// Area da tabela AF1.               
Local nOperation		:= oModel:GetOperation()  				// Numero da operacao.
Local oMdlAAT			:= oModel:GetModel("AATMASTER")	    	// Obtem o modelo de dados AATMASTER.
Local cCodVis			:= oMdlAAT:GetValue("AAT_CODVIS")  	// Codigo da vistoria tecnica.
Local cTipo		 	:= "3" 							  		// Vistoria tecnica.
Local lOrcPrc 		:= SuperGetMv("MV_ORCPRC",,.F.)			// Qual formato do or�amento de servi�o : com precifica��o (.t.) sem precifica��o (.f.)

If nOperation == 3
	//��������������������������������������������������������������������Ŀ
	//�Verifica se foi feita alguma simulacao de horas na vistoria tecnica.�
	//�Se sim, essa simulacao deve ser excluida para evitar que o proximo  �
	//�a usar a simulacao inicie com uma ja preenchida.    		  		   � 
	//����������������������������������������������������������������������
	DbSelectArea("AF1")
	DbSetOrder(4)
	If DbSeek(xFilial("AF1")+cCodVis+cTipo)
		FTAExcAF1(Nil,AF1->(Recno()))
	EndIf

	DbSelectArea( "TFJ" )
	TFJ->( DbSetOrder( 6 ) ) // TFJ_FILIAL + TFJ_CODVIS
	If TFJ->( DbSeek( xFilial("TFJ")+cCodVis ) )
		At740Del( TFJ->(Recno()) )
	EndIf
EndIf

A600Clean() // Detroy o objeto do or�amento de servi�os
//---------------------------------------------
//  Elimina as informa��es de controle do or�amento com precifica��o
If lOrcPrc
	AT740FGXML(,,.T.)
	At600STabPrc( "", "" )
EndIf
FWFormCancel(oModel)

RestArea(aAreaAF1)

Return(.T.) 

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �At270GvAbb�Autor  �                    � Data �  28/11/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Grava��o no controle de aloca��o.			       	   		  ���
�������������������������������������������������������������������������͹��
���Retorno   �							                                  ���
�������������������������������������������������������������������������͹��
���Parametros�ExpO1 - Numero da operacao( 1=Visualizar; 3=Incluir; 		  ���
���	    	 �							  4=Alterar; 5=Excluir ).		  ���
�������������������������������������������������������������������������͹��
���Uso       �TECA270                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

Function At270GvAbb(nOperation)

Local aAreaAAT 	:= AAT->(GetArea())
Local aAreaABB	:= ABB->(GetArea())
Local oMdl 	 	:= FWModelActive()
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")			   		// Obtem o modelo de dados AATMASTER.
Local cCodVis		:= oMdlAAT:GetValue("AAT_CODVIS")				// Codigo da vistoria.
Local cVistor		:= oMdlAAT:GetValue("AAT_VISTOR")				// Codigo do vistoriador.
Local dDtIni		:= oMdlAAT:GetValue("AAT_DTINI")				// Data inicial.
Local cHrIni		:= oMdlAAT:GetValue("AAT_HRINI")   			// Hora inicial.
Local dDtFim		:= oMdlAAT:GetValue("AAT_DTFIM")				// Data final.
Local cHrFim		:= oMdlAAT:GetValue("AAT_HRFIM")   			// Hora final.
Local cTotHr		:= AtTotHora(dDtIni,cHrIni,dDtFim,cHrFim)
Local lRetorno	:= .F.
Local lRet			:= .T.
Local nRecnoABB	:= 0

DbSelectArea("ABB")		//Tabela de Aloca��o de Atendentes
ABB->(DbSetOrder(7))		//ABB_FILIAL + ABB_CODTEC + ABB_ENTIDA + ABB_CHAVE

If ( ABB->( DbSeek( xFilial('ABB') + cVistor + 'AAT' + cCodVis ) ) )
	nRecnoABB := ABB->(Recno())
EndIf
	
If nOperation == MODEL_OPERATION_INSERT .Or. nOperation == MODEL_OPERATION_UPDATE
	lRet := !TxExistAloc( cVistor, dDtIni, cHrIni, dDtFim, cHrFim, nRecnoABB )
EndIf

If lRet
	
	If ABB->( !DbSeek( xFilial("ABB") + cVistor + "AAT" + cCodVis ) )
		RecLock( "ABB", .T. )
		ABB->ABB_FILIAL	:= xFilial("ABB")
		ABB->ABB_CODTEC	:= cVistor
		ABB->ABB_ENTIDA	:= "AAT"
		ABB->ABB_CHAVE	:= cCodVis
		ABB->ABB_DTINI	:= dDtIni
		ABB->ABB_HRINI	:= cHrIni
		ABB->ABB_DTFIM	:= dDtFim
		ABB->ABB_HRFIM	:= cHrFim
		ABB->ABB_HRTOT	:= cTotHr
		ABB->ABB_OBSERV	:= oMdlAAT:GetValue("AAT_OBSVIS")
		ABB->ABB_SACRA 	:= "S"
		ABB->ABB_CHEGOU	:= "N"
		ABB->ABB_ATENDE	:= "2"
		ABB->ABB_CODIGO	:=  Iif(FindFunction("AtABBNumCd"),AtABBNumCd(),GetSXENum("ABB","ABB_CODIGO"))
		ABB->ABB_MANUT	:= "2"
		ABB->ABB_ATIVO	:= "1"		
		MsUnlock()
		ConfirmSX8()
		lRetorno := .T.
	Else
		If nOperation == MODEL_OPERATION_UPDATE
			If M->AAT_STATUS == "3"
				RecLock("ABB",.F.)			
				ABB->ABB_ATENDE	:= "1"						
			Else
				RecLock("ABB",.F.)
				ABB->ABB_DTINI	:= dDtIni
				ABB->ABB_HRINI	:= cHrIni
				ABB->ABB_DTFIM	:= dDtFim
				ABB->ABB_HRFIM	:= cHrFim
				ABB->ABB_HRTOT	:= cTotHr
				ABB->ABB_OBSERV	:= oMdlAAT:GetValue("AAT_OBSVIS")
			EndIf                                                                          
			
			MsUnLock()
			lRetorno := .T.			
		ElseIf nOperation == MODEL_OPERATION_DELETE
			RecLock("ABB",.F.)
			DbDelete()
			MsUnLock()
			lRetorno := .T.
		EndIf
	EndIf
Else
	Help("",1,"AT270GVABB",,STR0030,2,0) //"O T�cnico j� possui aloca��o no per�odo escolhido."
	lRetorno := .F.
EndIf

RestArea(aAreaAAT)
RestArea(aAreaABB)           

If !lRetorno .AND. InTransact()
	DisarmTransaction()
EndIf

Return(lRetorno)
/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270Agend �Autor  �TOTVS		          � Data �  10/01/13   ���             
��������������������������������������������������������������������������͹��
���Desc.     �Chamada da fun��o de controle de aloca��o.				   ���
���			 � 															   ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270					                                   ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/                          
Function At270Agend()	
	TECA510(,AAT->AAT_VISTOR)
Return
/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �At270LoIt  �Autor  �Vendas CRM          � Data �  10/01/13   ���             
��������������������������������������������������������������������������͹��
���Desc.     �Gatilho para preencher o campo AAU_LOCAL(Item) com o conteudo���
���			 � do AAT_LOCAL(Cabecalho).									   ���
��������������������������������������������������������������������������͹��
���Retorno   �Valor do campo AAU_LOCAL                                     ���
��������������������������������������������������������������������������͹��
���Parametros�ExpC1 - Modelo de Dados.                                     ���
��������������������������������������������������������������������������͹��
���Uso       �TECA270 - Gatilho(SX7)                                       ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/
Function At270LoIt(cMdDetail)

Local oMdl 	 	:= FWModelActive()										// Retorna o model ativo.
Local oMdlAAT 	:= oMdl:GetModel("AATMASTER")							// Obtem o modelo de dados AATMASTER.
Local cLocCab	:= oMdlAAT:GetValue("AAT_LOCAL")						// Valor do campo AAT_LOCAL
Local oMdlAtu 	:= oMdl:GetModel(cMdDetail)			   	   				// Obtem o modelo de dados corrente( PRDDETAIL / ACEDETAIL ).
Local cLocItem	:= oMdlAtu:GetValue("AAU_LOCAL")						// Valor do campo AAU_LOCAL

If !Empty( cLocCab ) .AND. Empty(cLocItem)
	cLocItem := cLocCab
EndIf

Return( cLocItem )


//-------------------------------------------------------------------
/*/{Protheus.doc} At270Activ
Rotina de ativa��o do Model.

@sample 	At270Activ( oModel )
@param		oModel		Modelo de dados.

@author	Danilo Dias
@since		10/04/2013
@version	P11.80
/*/
//-------------------------------------------------------------------
Function At270Activ( oModel )

Local aArea		:= GetArea()
Local lRet 	:= .T.
Local cOport		:= AAT->AAT_OPORTU
Local nOpc			:= oModel:nOperation
Local cStatus 		:= AAT->AAT_STATUS

Do Case

	//Ativa��o em caso de exclus�o da Vistoria
	Case nOpc == MODEL_OPERATION_DELETE 
		//Verifica se a oportunidade est� aberta, se sim permite a exclus�o.
		If ( StatOport( cOport ) != '1' )
			Help( " ", 1, "At270Activ", , STR0033, 1 )	//"N�o � poss�vel excluir Vistorias T�cnicas de oportunidades que n�o estejam abertas."
			lRet := .F.
		EndIf
		
		If lRet .And. cStatus == "3"
			Help( "", 1, "At270Activ", , STR0045, 1 ) //"N�o � poss�vel excluir Vistorias T�cnicas que estejam com o status igual a conclu�do."
			lRet := .F.
		Endif
	//Ativa��o em caso de altera��o da Vistoria	
	Case nOpc == MODEL_OPERATION_UPDATE
		//Verifica se a oportunidade est� aberta, se sim permite a altera��o.
		If ( StatOport( cOport ) != '1' )
			Help( " ", 1, "At270Activ", , STR0034, 1 )	//"N�o � poss�vel alterar Vistorias T�cnicas de oportunidades que n�o estejam abertas."
			lRet := .F.
		EndIf
		
		If lRet .And. cStatus == "3"
			Help( " ", 1, "At270Activ", , STR0046, 1 ) //"N�o � poss�vel alterar Vistorias T�cnicas que estejam com o status igual a conclu�do."
			lRet := .F.
		Endif
EndCase

RestArea( aArea )

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} StatOport
Retorna o status de uma oportunidade.

@sample 	StatOport( cOport )
@param		cOport		N�mero da oportunidade para busca.
@result	cStatus	Status da oportunidade.

@author	Danilo Dias
@since		10/04/2013
@version	P11.80
/*/
//-------------------------------------------------------------------
Static Function StatOport( cOport )

Local aArea		:= GetArea()
Local aAreaAD1	:= AD1->(GetArea())
Local cStatus		:= ''					//Status da oportunidade

DbSelectArea('AD1')	//Oportunidade de Vendas
AD1->(DbSetOrder(1))	//AD1_FILIAL + AD1_NROPOR + AD1_REVISA

If ( AD1->( DbSeek( xFilial('AD1') + cOport ) ) )
	cStatus := AD1->AD1_STATUS
EndIf

RestArea( aAreaAD1 )
RestArea( aArea )

Return cStatus

//-------------------------------------------------------------------
/*/{Protheus.doc} At270FilVist
Retorna o status de uma oportunidade.

@sample 	At270FilVist( cCodVist )

@param		cCodVist	Codigo do vistoriador a ser analisado.
@result	cRet	  	String do filtro a ser utilizada no browse.

@author	Servi�os
@since		03/04/2014
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At270FilVist( cCodVist )

Local cRet 	   	:= ""
Local cAliasAAY 	:= GetNextAlias()

BeginSql Alias cAliasAAY
	SELECT AAY.AAY_CODTEC
	  FROM %table:AAY% AAY
	  JOIN ( SELECT AAY2.AAY_CODEQU 
	           FROM %table:AAY% AAY2		
	          WHERE AAY2.AAY_FILIAL = %xFilial:AAY%
	            AND AAY2.AAY_CODTEC = %Exp:cCodVist%
	            AND AAY2.%NotDel%
	          GROUP BY AAY2.AAY_CODEQU ) AAY_TEC ON AAY.AAY_CODEQU = AAY_TEC.AAY_CODEQU
	 WHERE AAY.AAY_FILIAL = %xFilial:AAY%
	   AND AAY.%NotDel%
	 GROUP BY AAY.AAY_CODTEC
EndSql	

While (cAliasAAY)->(!Eof())		

	cRet += "AAT_VISTOR == '" + (cAliasAAY)->AAY_CODTEC + "'"
					   	
	(cAliasAAY)->(dbSkip())
	
	If (cAliasAAY)->(!Eof())
		cRet += " .OR. "		
	EndIf 
	
EndDo

If !Empty(cRet)
	cRet += ""	
EndIf

Return(cRet)


//-------------------------------------------------------------------
/*/{Protheus.doc} At270GerOrc
Consiste as informa��es dos campos para a cria��o do or�amento de vendas.

@sample 	At270GerOrc( nOperacao, lVistoria, oModel )

@param		nOperacao	Opera��o do model utilizada.
@param     oModel		Model utilizado para a vistoria tecnica

@result	lRet	  	Retorna se a opera��o teve sucesso na cria��o.

@author	Servi�os
@since		04/04/2014
@version	P12
/*/
//-------------------------------------------------------------------
Static Function At270GerOrc( nOperacao, oModel )

Local lRet			:= .T.								// Retorno da validacao.

Local oMdlAAT	:= oModel:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cCodOpo	:= oMdlAAT:GetValue("AAT_OPORTU") 	// Codigo da oportunidade.
Local cRevOpo	:= oMdlAAT:GetValue("AAT_OREVIS") 	// Revisao da oportunidade.
Local cDatIni	:= oMdlAAT:GetValue("AAT_DTINI") 	// Revisao da oportunidade.
Local cHorIni	:= oMdlAAT:GetValue("AAT_HRINI") 	// Revisao da oportunidade.
Local cDatFim	:= oMdlAAT:GetValue("AAT_DTFIM") 	// Revisao da oportunidade.
Local cHorFim	:= oMdlAAT:GetValue("AAT_HRFIM") 	// Revisao da oportunidade.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//�������������������������������������������������������������������������������Ŀ
	//�	 Problema: Oportunidade de venda n�o informado.                               �
	//�	 Solucao: Informe a oportunidade de venda no cabe�alho da vistoria t�cnica.   �
	//���������������������������������������������������������������������������������
	Help("",1,"OPORTREVIS")
	lRet := .F.
EndIf

If ( Empty(cDatIni) .AND. Empty(cHorIni) ) .OR. ( Empty(cDatFim) .AND. Empty(cHorFim) ) 
	//���������������������������������������������������Ŀ
	//�	 Problema: Per�odo de agendamento inv�lido.       �
	//�	 Solucao: Informe outro per�odo.   				  �
	//�����������������������������������������������������
	Help("",1,"AT270VLDATAHR")                  
	lRet := .F.
EndIf

If lRet
	
	At600SeAtu( nOperacao, .T., oModel ) 
EndIf

Return( lRet )
