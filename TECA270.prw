#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECA270.CH" 

Static cPerfil  := ""	// Controla o perfil do vistoriador.
Static cVistor  := ""	// Codigo do vistoriador.
Static nLine	:= 0	// Linha atual.  

/*                        
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณTECA270   บAutor  ณVendas CRM          บ Data ณ  27/02/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณVistoria Tecnica.             			           	      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro		                                      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                     			  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Function TECA270()

Local oBrowse	:= Nil 										// Objeto oBrowse.
Local bPerfil	:= {|a,b,c,d| At270EPerf(a,b,c,d)}			// Bloco de codigo perfil do vistoriador.

Private cCadastro := STR0001  								// Variavel utilizada no Banco de Conhecimento
Private aRotina   := MenuDef()                          // Array aRotina utilizada no banco de conhecimento

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Verifica se o usuario e um vistoriador e carrega o seu perfil. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"TECA270",/*aEstrut*/,/*oObject*/,"Perfil")

If At("ACESSA",cPerfil) > 0
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Cria o Browse ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("AAT")
	oBrowse:SetDescription(STR0001)       						// "Vistoria T้cnica"
	oBrowse:AddLegend("AAT_STATUS=='1'","GREEN" ,STR0002)	// "Aberto"
	oBrowse:AddLegend("AAT_STATUS=='2'","YELLOW",STR0003)	// "Agendado"
	oBrowse:AddLegend("AAT_STATUS=='3'","RED"   ,STR0004)	// "Concluido"
	oBrowse:AddLegend("AAT_STATUS=='4'","BLACK" ,STR0005)	// "Cancelado"
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Verifica Permissao de Filtro ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Eval(bPerfil,"TECA270",/*aEstrut*/,oBrowse,"SetFilterDefault")
	
	oBrowse:Activate()
	
EndIf

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Limpa o Perfil do Vistoriador ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
cPerfil  := ""
cVistor  := ""

Return( .T. )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณModelDef  บAutor  ณVendas CRM          บ Data ณ  27/02/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณModelo de Dados Vistoria Tecnica.                   		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpO - Modelo de Dados                                      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                      			  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Tratamento para FWExecView chamada pela proposta comercial. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
If IsInCallStack("FATA300")
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Habilita a visualizacao dos valores para os vendedores. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Eval(bPerfil,"FATA300",/*aEstrut*/,/*oObject*/,"Vendedor")
EndIf

If lAgendAbb	        
	oStruAAT:SetProperty("AAT_DTINI",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_HRINI",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_DTFIM",MODEL_FIELD_OBRIGAT,.F.)
	oStruAAT:SetProperty("AAT_HRFIM",MODEL_FIELD_OBRIGAT,.F.) 
	oStruAAT:SetProperty("AAT_STATUS",MODEL_FIELD_WHEN,{||IIF(oModel:GetOperation()==3,.F.,.T.)})
EndIf

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona as Estruturas no Array aEstrut. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
aAdd(aEstrut,oStruAAT)
aAdd(aEstrut,oStruPrd)
aAdd(aEstrut,oStruAce)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Instancia o modelo de dados Vistoria Tecnica. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oModel := MPFormModel():New("TECA270",/*bPreValidacao*/,bPosValid,bCommit,bCancel)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Criacao da Trigger. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
aAux := FwStruTrigger("AAU_QTDVEN","AAU_VLRTOT","At270CTot('PRDDETAIL','AAU_QTDVEN')",.F.,Nil,Nil,Nil)
oStruPrd:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("AAU_PRCVEN","AAU_VLRTOT","At270CTot('PRDDETAIL','AAU_PRCVEN')",.F.,Nil,Nil,Nil)
oStruPrd:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("AAU_QTDVEN","AAU_VLRTOT","At270CTot('ACEDETAIL','AAU_QTDVEN')",.F.,Nil,Nil,Nil)
oStruAce:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("AAU_PRCVEN","AAU_VLRTOT","At270CTot('ACEDETAIL','AAU_PRCVEN')",.F.,Nil,Nil,Nil)
oStruAce:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Verifica se o vistoriador podera alterar o campo AAT_VISTOR. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"MODELDEF",aEstrut,oModel,"SetProperty")  

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Permite alteracao nos campos Oportunidade e Proposta somente na inclusao. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oStruAAT:SetProperty("AAT_OPORTU",MODEL_FIELD_WHEN,{|| IIF(oModel:GetOperation()==3,.T.,.F.) })
oStruAAT:SetProperty("AAT_PROPOS",MODEL_FIELD_WHEN,{|| IIF(oModel:GetOperation()==3,.T.,.F.) })

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Mudanca da propriedade do campo AAU_FOLDER. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oStruPrd:SetProperty("AAU_FOLDER",MODEL_FIELD_INIT,{||"1"})		// Produto(s)
oStruAce:SetProperty("AAU_FOLDER",MODEL_FIELD_INIT,{||"2"}) 	// Acessorio(s)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Atualiza o total dos grids Produto e Acessorio. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oStruPrd:SetProperty("AAU_PRODUT",MODEL_FIELD_VALID,FwBuildFeature( STRUCT_FEATURE_VALID,"At270VdPrd('PRDDETAIL')"))
oStruAce:SetProperty("AAU_PRODUT",MODEL_FIELD_VALID,FwBuildFeature( STRUCT_FEATURE_VALID,"At270VdPrd('ACEDETAIL')"))

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona os campos no modelo de dados. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oModel:AddFields("AATMASTER",/*cOwner*/,oStruAAT,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/ )
oModel:AddGrid("PRDDETAIL","AATMASTER",oStruPrd,bLinePre,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/)
oModel:AddGrid("ACEDETAIL","AATMASTER",oStruAce,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/,/*bPosVal*/)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona campos calculados. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"MODELDEF",/*aEstrut*/,oModel,"AddCalc")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Permite de grid sem dados. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oModel:GetModel("ACEDETAIL"):SetOptional(.T.)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Gatilho para mudanca do campo AAU_LOCAL caso esteja vazio.ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
aAux := FwStruTrigger( "AAU_PRODUT", "AAU_LOCAL", "At270LoIt('PRDDETAIL')",.F.,Nil,Nil,Nil)    
oStruPrd:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger( "AAU_PRODUT", "AAU_LOCAL", "At270LoIt('ACEDETAIL')",.F.,Nil,Nil,Nil)    
oStruAce:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Montagem do relacionamento. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oModel:SetRelation("PRDDETAIL",{{"AAU_FILIAL","xFilial('AAU')"},{"AAU_CODVIS","AAT_CODVIS"},{"AAU_FOLDER","'1'"}},AAU->( IndexKey(2)))
oModel:SetRelation("ACEDETAIL",{{"AAU_FILIAL","xFilial('AAU')"},{"AAU_CODVIS","AAT_CODVIS"},{"AAU_FOLDER","'2'"}},AAU->( IndexKey(2)))

If AAT->AAT_STATUS == "2" 
	oModel:GetModel("PRDDETAIL"):SetOptional(.T.)
	oModel:GetModel("ACEDETAIL"):SetOptional(.T.)
Endif

//Ativa็ใo do Model
oModel:SetVldActivate( { |oModel| At270Activ( oModel ) } )

oModel:SetDescription(STR0001)	//"Vistoria T้cnica"

Return(oModel)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณViewDef   บAutor  ณVendas CRM          บ Data ณ  27/02/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณInterface Vistoria Tecnica.                       		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpO - Interface                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                      			  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona as Estruturas. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
aAdd(aEstrut,oStruAAT)
aAdd(aEstrut,oStruPrd)                     
aAdd(aEstrut,oStruAce)
aAdd(aEstrut,oStruCal)


//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Remove os campos de controle da View para nใo ser visualizado pelo usuario. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oStruPrd:RemoveField("AAU_ITPROP")
oStruPrd:RemoveField("AAU_CODVIS")
oStruPrd:RemoveField("AAU_FOLDER") 
oStruPrd:RemoveField("AAU_ITPAI") 

oStruAce:RemoveField("AAU_ITPROP")
oStruAce:RemoveField("AAU_CODVIS")
oStruAce:RemoveField("AAU_FOLDER") 
oStruAce:RemoveField("AAU_PMS")             

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Remove os campos da view conforme o perfil do usuario. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"RemoveField")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Instancia a interface Vistoria Tecnica. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oView := FWFormView():New()
oView:SetModel(oModel)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona rotinas conforme o perfil do usuario. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"AddUserButton")
	
oView:AddUserButton(STR0031,"",{|| MsDocument("AAT",AAT->(Recno()),oModel:GetOperation())},,,{MODEL_OPERATION_VIEW,MODEL_OPERATION_UPDATE})  // Conhecimento
oView:AddUserButton(STR0032,"",{|| TECR271(oView)},,,) // Imprime Vistoria   

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona os campos no cabecalho. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oView:AddField("VIEW_AAT",oStruAAT,"AATMASTER")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona os campos na view conforme o perfil do usuario. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"AddField")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Adiciona os campos no grid. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oView:AddGrid("VIEW_PRD",oStruPrd,"PRDDETAIL")
oView:AddGrid("VIEW_ACE",oStruAce,"ACEDETAIL")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Campos com incremento. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
oView:AddIncrementField("VIEW_PRD","AAU_ITEM")
oView:AddIncrementField("VIEW_ACE","AAU_ITEM")

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Habilita as views conforme o perfil do usuario. ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Eval(bPerfil,"VIEWDEF",aEstrut,oView,"EnableView")

Return(oView)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณMenuDef   บAutor  ณVendas CRM          บ Data ณ  27/02/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณCriacao do MenuDef.	  	                        		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpA - Opcoes de menu                                       บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                      			  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270EPerf บAutor  ณVendas CRM          บ Data ณ  21/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณExecuta o perfil do vistoriador por rotina.	   	           บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro                                            บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpC1 - Rotina que sera verificada o perfil do usuario.	   บฑฑ
ฑฑบ			 ณExpA2 - Estruturas de Dados.                    	           บฑฑ
ฑฑบ			 ณExpO3 - Objeto MVC.                                          บฑฑ
ฑฑบ			 ณExpC4 - Acao do objeto MVC.                                  บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                      บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออออปฑฑ
ฑฑบPrograma  ณAt270PMain บAutor  ณVendas CRM          บ Data ณ  21/03/12     บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออออนฑฑ
ฑฑบDesc.     ณVerifica se o usuario e um vistoriador; e carrega o seu perfil บฑฑ
ฑฑบ		     ณdurante a execucao da rotina principal(TECA270).	             บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                      บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpO1 - Objeto MVC.      	  								     บฑฑ
ฑฑบ			 ณExpC2 - Acao do objeto MVC.                      	             บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                        บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Visualiza Valores? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		cPerfil := "VISVLR|"
	
	Case cAction == "Perfil"
		If DbSeek(xFilial("AA1")+cCodUser)
		
			If AA1->AA1_VISTOR == "1"
							
				lRetorno := .T.
				cVistor	 := AA1->AA1_CODTEC
				cPerfil  := "ACESSA|"
	   			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Visualiza Valores? ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_VISVLR == "1"
					cPerfil += "VISVLR|"
				EndIf
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Visualiza Proposta Comercial? ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_VISPRO == "1"
					cPerfil += "VISPRO|"
				EndIf
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Importa Proposta Comercial? ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_IMPPRO == "1"
					cPerfil += "IMPPRO|"
				EndIf 
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Acessa a rotina de categoria de produtos? ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_CATEGO == "1"
					cPerfil += "CATEGO|"
				EndIf
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Permite se altera o responsavel da vistoria? ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_ALTVIS == "1"
					cPerfil += "ALTVIS|"
				EndIf
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Permite o vistoriador acessar somente suas vistorias  ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_FTVIST == "1"
					cPerFil += "FILVIS"
				ElseIf AA1->AA1_FTVIST == "3" // Permite que o vistoriador acesse somente as vistorias do grupo
					cPerFil += "GRPVIS"
				EndIf
				
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ Acessa a rotina CRM Simulador? ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				If AA1->AA1_CRMSIM == "1"
					cPerFil += "CRMSIM"
				EndIf
			Else
				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณ	 Problema: Este atendente nใo tem perfil para realizar vistoria t้cnica. ณ
				//ณ	 Solucao: Defina este atendente como vistoriador no cadastro de          ณ
				//ณ	 atendentes para acessar esta rotina.					        		 ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				Help( " ", 1, "PERFILVIST" )
				lRetorno := .F.
			EndIf
		Else
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ	 Problema: Este usuแrio nใo tem permissใo para acessar a rotina de vistoria t้cnica.  ณ
			//ณ	 Solucao: Cadastre ou altera um atendente e associe o mesmo a este usuแrio.           ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270PMdl  บAutor  ณVendas CRM          บ Data ณ  21/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณVerifica o perfil do vistoriador durante a criacao do Modelo บฑฑ
ฑฑบ  	     ณde dados.    												   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro                                            บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpA1 - Estruturas de Dados.                                 บฑฑ
ฑฑบ			 ณExpO2 - Objeto MVC.                                          บฑฑ
ฑฑบ			 ณExpC3 - Acao do objeto MVC.                                  บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                      บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function At270PMdl(aEstrut,oObject,cAction)

Local bCond		:= {||.T.}						// Condicao para soma.
Local nTamTot	:= TamSX3("AAU_VLRTOT")[1]		// Tamanho do campo AAU_VRLTOT.
Local nDecTot	:= TamSX3("AAU_VLRTOT")[2]		// Numero de decimais do campo AAU_VLRTOT.
Local oMdlCalc	:= Nil      					// Model calculado.

Do Case
	Case cAction == "SetProperty"
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Permite o vistoriador alterar o campo AAT_VISTOR? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		aEstrut[1]:SetProperty("AAT_VISTOR",MODEL_FIELD_WHEN,{|| IIF(At("ALTVIS",cPerfil) > 0,.T.,.F.) })		
   
	Case cAction == "AddCalc"  
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Permite o vistoriador acessar os campos calculados. ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู	
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270PView บAutor  ณVendas CRM          บ Data ณ  21/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณVerifica o perfil do vistoriador durante a criacao da        บฑฑ
ฑฑบ  	     ณinterface. 												   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro                                            บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpA1 - Estruturas de Dados.                                 บฑฑ
ฑฑบ			 ณExpO2 - Objeto MVC.                                          บฑฑ
ฑฑบ			 ณExpC3 - Acao do objeto MVC.                                  บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                      บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function At270PView(aEstrut,oObject,cAction)

Do Case
	Case cAction == "AddField"
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Permite o vistoriador acessar os campos calculados. ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If At("VISVLR",cPerfil) > 0
			aEstrut[4] := FWCalcStruct( oObject:GetModel("CALCDETAIL") )
			oObject:AddField("VIEW_CALC",aEstrut[4],"CALCDETAIL")
		EndIf	
   
	Case cAction == "RemoveField"
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Remove os campos de valores? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If At("VISVLR",cPerfil) == 0		
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฟ
	   		//ณ Cabecalho. ณ
	   		//ภฤฤฤฤฤฤฤฤฤฤฤฤู
			aEstrut[1]:RemoveField("AAT_TABELA")
			
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	   		//ณ Folder Produtos. ณ
	   		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			aEstrut[2]:RemoveField("AAU_MOEDA")
			aEstrut[2]:RemoveField("AAU_PRCVEN")
			aEstrut[2]:RemoveField("AAU_PRCTAB")
			aEstrut[2]:RemoveField("AAU_VLRTOT")
			
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	   		//ณ Folder Acessorios. ณ
	   		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู 
			aEstrut[3]:RemoveField("AAU_MOEDA")
			aEstrut[3]:RemoveField("AAU_PRCVEN")
			aEstrut[3]:RemoveField("AAU_PRCTAB")
			aEstrut[3]:RemoveField("AAU_VLRTOT")
		EndIf
		
	Case cAction == "AddUserButton"
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Visualiza Proposta Comercial? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If At("VISPRO",cPerfil) > 0
			oObject:AddUserButton(STR0015,"",{|| At270VProp()})  // Visualizar Prospota
		EndIf
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Importa Proposta Comercial? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If At("IMPPRO",cPerfil) > 0
			oObject:AddUserButton(STR0014,"",{|oView| At270IProp(oView:GetModel())}, Nil, Nil, {MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE})  // Importar Prospota
		EndIf
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Acessa a rotina de categoria de produtos? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If At("CATEGO",cPerfil) > 0
			oObject:AddUserButton(STR0013,"",{|| At270CTPrd()})  // Categoria
		EndIf		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Acessa a rotina CRM Simulador? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If At("CRMSIM",cPerfil) > 0
			oObject:AddUserButton(STR0016,"",{|| At270Simul()})  // CRM Simulador
		EndIf		
					
		If nModulo == 28 // Modulo Gestao de Servi็os
			oObject:AddUserButton( STR0035, "", { || At600OrcView( Nil, .T. ) }, Nil, Nil, { MODEL_OPERATION_VIEW, MODEL_OPERATION_DELETE } )  // 'Vis. Or็am. Serv.'
			oObject:AddUserButton( STR0036, "", { |oView| At270GerOrc( MODEL_OPERATION_INSERT, oView:GetModel() ) }, Nil, Nil, { MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE } ) // Atualiza Orc. Servi็os
			oObject:AddUserButton( STR0037, "", { |oView| At600SeExc( MODEL_OPERATION_DELETE, .T., oView:GetModel() ) }, Nil, Nil, { MODEL_OPERATION_INSERT, MODEL_OPERATION_UPDATE } ) // Remover Orc. Servi็os
		EndIf							
				
	Case cAction == "EnableView"
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Acessa a interface com os campos calculados? ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270RVist บAutor  ณVendas CRM          บ Data ณ  21/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณRetorna o codigo do vistoriador.							   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpC - Codigo do vistoriador.                                บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Dicionario de dados(SX3)                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdAge บAutor  ณVendas CRM          บ Data ณ  19/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValida agendamento do vistoriador.						   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                      บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
					//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					//ณ	 Problema: O perํodo informado se encontra agendado em outra vistoria t้cnica.ณ
					//ณ	 Solucao: Alterar o perํodo informado.									      ณ
					//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdPro บAutor  ณVendas CRM          บ Data ณ  28/03/12     บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออออนฑฑ
ฑฑบDesc.     ณValida se ja existe uma vistoria tecnica aberta ou atendida    บฑฑ
ฑฑบ          ณcadastrada somente para oportunidade selecionada pelo usuario. บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                      บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                     บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                        บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
					//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					//ณ	 Problema: Jแ existe uma vistoria t้cnica em aberto para esta oportunidade de venda.             ณ
					//ณ	 Solucao: Selecione uma outra oportunidade ou cancele a vistoria aberta para esta oportunidade.  ณ
					//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
					Help(" ",1,"AT270OPOAB")
					lRetorno := .F.
				ElseIf AD1->AD1_VISTEC == "1" .AND. AD1->AD1_SITVIS == "2"
					//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					//ณ	 Problema: Jแ existe uma vistoria t้cnica agendada para esta oportunidade de venda.               ณ
					//ณ	 Solucao: Selecione uma outra oportunidade ou cancele a vistoria agendada para esta oportunidade. ณ
					//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
					Help(" ",1,"AT270OPOAG")
					lRetorno := .F.
				EndIf
			EndIf
			
		EndIf
	Else
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ	 Problema: Solicita็ใo de vistoria t้cnica somente para oportunidade de venda em aberto. ณ
		//ณ	 Solucao: Selecione uma oportunidade em aberto ou inclua uma nova oportunidade.			 ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		lRetorno := .F.
		Help("",1,"AT270OPABR")
	EndIf
	
EndIf

RestArea(aAreaAD1)
Return( lRetorno )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdPro บAutor  ณVendas CRM          บ Data ณ  28/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValida se ja existe uma vistoria tecnica aberta ou atendida  บฑฑ
ฑฑบ          ณcadastrada para proposta / revisao selecionada pelo usuario. บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                      บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ	 Problema: Jแ existe uma vistoria t้cnica em aberto para esta proposta comercial.                ณ
			//ณ	 Solucao: Selecione uma outra proposta ou cancele a vistoria t้cnica associado a esta proposta.  ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			Help(" ",1,"AT270PRPAB")
					lRetorno := .F.
		ElseIf ADY->ADY_VISTEC ==  "1" .AND. ADY->ADY_SITVIS == "2"
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ	 Problema: Jแ existe uma vistoria t้cnica agendada para esta proposta comercial.                 ณ
			//ณ	 Solucao: Selecione uma outra proposta ou cancele a vistoria t้cnica associado a esta proposta.  ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			Help(" ",1,"AT270PRPAG")
			lRetorno := .F.
		EndIf
	EndIf
EndIf 

RestArea(aAreaADY)
Return( lRetorno )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270Oport บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณPreenche os campos da tabela AAT(Vist. Tecnica Cabe็alho)	   บฑฑ
ฑฑบ          ณrelacionado a oport. de venda a partir do campo AAT_ENTIDA   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpC - Numero da Entidade                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Gatilho(SX7)                                       บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Cliente ou Prospect. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Nome da entidade. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	oMdlAAT:SetValue("AAT_NOMENT",cNomEnt)
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Vendedor responsavel pela oportunidade. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	oMdlAAT:SetValue("AAT_VEND",AD1->AD1_VEND)
	cNoVend := Alltrim( Posicione("SA3",1,xFilial("SA3")+AD1->AD1_VEND,"A3_NOME") )
	oMdlAAT:SetValue("AAT_NOMVEN",cNoVend)
	
EndIf

RestArea(aAreaAD1)
Return( cEntidade )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270RNEnt บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณRetorna o nome da entidade (Cliente ou Prospect) no campo    บฑฑ
ฑฑบ          ณAAT_NOMENT                                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpC - Nome da Entidade                                      บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Dicionario de dados(SX3)                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270RNBrw บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณRetorna o nome da Entidade / Vistoriador no Browse.          บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpC - Nome da Entidade / Vistoriador                        บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpC1 - Campo					                               บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Browse                                             บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdDHr บAutor  ณVendas CRM          บ Data ณ  06/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณVerifica se a data / hora fim e maior ou igual que a data /  บฑฑ
ฑฑบ			 ณhora inicio.												   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Dicionario de dados(SX3)                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Perํodo de agendamento invแlido.       ณ
	//ณ	 Solucao: Informe outro perํodo.   				  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"AT270VLDATAHR")                  
	lRetorno := .F.
EndIf

Return( lRetorno )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdPrd บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValida o produto.								   	           บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpC1 - Modelo de Dados.                                     บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                      บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Oportunidade de venda nใo informado.                               ณ
	//ณ	 Solucao: Informe a oportunidade de venda no cabe็alho da vistoria t้cnica.   ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ Existe acesssorio para este produto? ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู 
			If cMdDetail == "PRDDETAIL"
				aPrdSel := At600Prd(cCodProd) 
			EndIf
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ 
			//ณ Produto x acessorio? ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู  
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270CTot  บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณCalcula o valor total do produto.							   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpN - Valor Total do Produto                                บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpC1 - Modelo de Dados.                                     บฑฑ
ฑฑบ			 ณExpC2 - Nome do Campo 									   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Gatilho(SX7)                                       บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Calcula o valor total.ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270CTPrd บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณCategoria de produtos. 									   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                    บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270							                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Oportunidade de venda nใo informado.                               ณ
	//ณ	 Solucao: Informe a oportunidade de venda no cabe็alho da vistoria t้cnica.   ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Rotina de selecao de categoria e produtos.ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	aPrdSel := FATA610()
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Adiciona e Valida os produtos / acessorios no grid. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	If Len(aPrdSel) > 0
		At270VdPxA(aPrdSel,lCategoria,/*lImpProp*/,/*lSimulador*/) 
	EndIf	
EndIf

Return( lRetorno )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270Simul บAutor  ณVendas CRM          บ Data ณ  22/03/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณCRM Simulador												   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso		                               บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270							                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Oportunidade de venda nใo informado.                               ณ
	//ณ	 Solucao: Informe a oportunidade de venda no cabe็alho da vistoria t้cnica.   ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ Apaga itens deletados no CRM Simulador na Vistoria. ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
									
					//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					//ณ Valida a existencia de acessorios (KIT) para o produto selecionado.ณ
					//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
						//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	   					//ณ Recupera o item deletado na vistoria presente no CRM Simulador. ณ
	  					//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
						oMdlPrd:UnDeleteLine()
						oMdlPrd:SetValue("AAU_QTDVEN",aColsSrv[nX][4])
					Else
						oMdlPrd:SetValue("AAU_QTDVEN",aColsSrv[nX][4])
					EndIf
					
				EndIf
				
			Next nX
		    
		    //ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ Posiciona na primeira linha. ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		    oMdlPrd:GoLine(1)
		   
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ Adiciona e Valida os produtos / acessorios no grid.ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			If Len(aPrdSel) > 0
				At270VdPxA(aPrdSel,/*lCategoria*/,/*lImpProp*/,lSimulador)
			EndIf 
			
		EndIf
		
	EndIf
	
EndIf

RestArea(aAreaAF1)

Return( lRetorno )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdPxA บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValida Produtos e Acessorios para adicionar no grid.	       บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro				                               บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpA1 - Array que contem Produto / Acessorios.               บฑฑ
ฑฑบ			 ณExpL2 - Validacao especifica para importacao de proposta.	   บฑฑ
ฑฑบ			 ณExpL3 - Validacao especifica para o CRM Simulador.		   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270				                                       บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Forca adicionar uma nova linha para Categoria de Produtos, ณ
//ณ Importacao de Proposta,Simulador.                          ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
   			//ณ Mantem a moeda definida na prospota. ณ
   			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			oMdlAtu:SetValue("AAU_MOEDA",aPrdSel[nX][7])
		Else
			oMdlAtu:SetValue("AAU_MOEDA",Str(DA1->DA1_MOEDA,1))
		EndIf
	Else
		oMdlAtu:SetValue("AAU_MOEDA","1")
	EndIf
	
	oMdlAtu:SetValue("AAU_QTDVEN",aPrdSel[nX][6])
	
	If lImpProp .AND. Empty(cTabPrc)
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
  		//ณ Mantem o valor unitario da proposta se o vistoriador nao optar pela tabela de preco. ณ
   		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		nPrcVen := aPrdSel[nX][8]
	Else
		nPrcVen := MaTabPrVen( cTabPrc,aPrdSel[nX][1],aPrdSel[nX][6],cCodEnt,cLojEnt,Val(oMdlAtu:GetValue("AAU_MOEDA")),/*dDataVld*/,/*nTipo*/,/*lExec*/,/*lAtuEstado*/,lProspect  )
	EndIf
	
	oMdlAtu:SetValue("AAU_PRCVEN",nPrcVen)	
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
 	//ณ Importa o tipo de produto e define o item pai da proposta. ณ
  	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	If lImpProp
   		oMdlAtu:SetValue("AAU_TPPROD",aPrdSel[nX][9])
   		oMdlAtu:SetValue("AAU_ITPROP",aPrdSel[nX][11])
	EndIf                                                     
	
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
 	//ณ Define o pai do acessorio. ณ
  	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
  		//ณ Relaciona o codigo do orcamento do simulador ao produto do grid   ณ
  		//ณ caso o usuario utilizar o CRM Simulador para elaborar a vistoria. ณ  		
  		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		oMdlAtu:SetValue("AAU_PMS",aPrdSel[nX][7])
	EndIf

	If	( nPPrpXOrc := aScan(aPrpXOrc,{|x| x[01] == aPrdSel[nX][1]}) ) > 0
		aPrpXOrc[nPPrpXOrc,04]	:= cItemPrd
	EndIf

Next nX 

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Posiciona na primeira linha da aba produto. ณ	
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
If ( lCategoria .OR. lImpProp .OR. lSimulador )
	oMdl:GetModel("PRDDETAIL"):GoLine(1)
EndIf

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Posiciona na primeira linha caso o acessorio do produto ser ณ
//ณ carregado automaticamente. 									ณ  		
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
If ValType(oMdlAtu) == "O" .AND. oMdlAtu:GetId() == "ACEDETAIL"
	oMdlAtu:GoLine(1)
EndIf

Return ( .T. )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270DLin  บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValidacao do delete da linha.                       	       บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro 		                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270							                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VProp บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณVisualizacao da proposta comercial.                      	   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso 		                           บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270							                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Oportunidade de venda nใo informado.                               ณ
	//ณ	 Solucao: Informe a oportunidade de venda no cabe็alho da vistoria t้cnica.   ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
ElseIf( Empty(cCodPro) .AND. Empty(cRevPro) )
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Proposta comercial nใo informado.                                  ณ
	//ณ	 Solucao: Informe a proposta comercial no cabe็alho da vistoria t้cnica.      ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"PROPREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	
	DbSelectArea("ADY")
	ADY->(dbSetOrder(1))
	
	If ADY->(dbSeek(xFilial("ADY")+cCodPro))				
		FWExecView(STR0038,"VIEWDEF.FATA600",MODEL_OPERATION_VIEW,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)  //"Visualizar proposta"                    
	Else
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ	 Problema: Proposta comercial nใo localizada para visualiza็ใo.        ณ
		//ณ	 Solucao: Cadastre uma proposta comercial para esta oportunidade.      ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		Help("",1,"PROPNAOLOC")
		lRetorno := .F.
	EndIf
	
EndIf

Return( lRetorno )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270IProp บAutor  ณVendas CRM          บ Data ณ  28/02/12   บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณImportacao da proposta comercial.                     	   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso 		                           บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270							                           บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
Local aPrpXOrc	:= {}														// Array que contem o relacionamento entre os itens da Proposta x itens do or็amento de servi็os para a montagem do novo or็amento de servi็os que estarแ associado เ Vistoria.
Local nX			:= 0														// Incremento utilizado no laco For.
Local nI			:= 0	 													// Incremento utilizado no laco For.
Local lImpProp	:= .T.														// Define se a validacao do produto x acessorio e especifico para o Importacao de Propostas.
Local lRetorno	:= .T.														// Retorno da validacao.

If ( Empty(cCodOpo) .AND. Empty(cRevOpo) )
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Oportunidade de venda nใo informado.                               ณ
	//ณ	 Solucao: Informe a oportunidade de venda no cabe็alho da vistoria t้cnica.   ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"OPORTREVIS")
	lRetorno := .F.
ElseIf( Empty(cCodPro) .AND. Empty(cRevPro) )
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Proposta comercial nใo informado.                                  ณ
	//ณ	 Solucao: Informe a proposta comercial no cabe็alho da vistoria t้cnica.      ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"PROPREVIS")
	lRetorno := .F.
EndIf

If lRetorno
	If At("VISPRO",cPerfil) > 0
		// "Deseja visualizar a proposta comercial antes da importa็ใo?"##"Aten็ใo"
		If MsgYesNo(STR0021,STR0020)
			//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
			//ณ	Visualiza a proposta comercial. ณ
			//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
			At270VProp()
		EndIf
	EndIf
	// "Deseja importar os produtos / acess๓rios da proposta comercial para a vistoria t้cnica?"##"Aten็ใo"
	If !( MsgYesNo(STR0022,STR0020))
		lRetorno := .F.
	EndIf

	If lRetorno
		DbSelectArea("TFJ")
		TFJ->( DbSetOrder( 6 ) ) // TFJ_FILIAL + TFJ_CODVIS
		If TFJ->( DbSeek( xFilial("TFJ")+oMdlAAT:GetValue("AAT_CODVIS") ) )
			lRetorno := .F.
			Help(,, "AT270HASORCSER",,STR0041,1,0,,,,,,{STR0042})	//"Jแ existe or็amento de servi็os para esta vistoria." ## "Exclua o existente ou fa็a uma nova vistoria."
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
		
		// Carrega o or็amento de servi็os com os dados da proposta comercial
		If	( lRetorno := ( lRetorno .AND. A600LOrc( Nil, cCodPro, cRevPro, "TECA270", oMdl, aPrpXOrc ) ) )
			MsgAlert(STR0026,STR0020)	//"Vistoria t้cnica importada com sucesso!"#Atencao
		Else
			Help(,,"At270IProp",,STR0043,1,0)	//"Os dados da proposta comercial nใo foram importados para esta vistoria."
		EndIf
	Else
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ	 Problema: Nใo hแ produtos / acess๓rios cadastrados para esta proposta comercial.                   ณ
		//ณ	 Solucao: Informe os produtos / acess๓rios para esta proposta comercial na oportunidade de venda.   ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		Help("",1,"NOPRDACE")
		lRetorno := .F.
	EndIf
	
EndIf

Return( lRetorno )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270Cmt  บAutor  ณVendas CRM          บ Data ณ  20/03/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณBloco de Commit.       	   						          บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro			                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpO1 - Modelo de dados.  		    					  บฑฑ  
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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

// Grava or็amento de servi็o
A600GrvOrc(oModel:GetValue('AATMASTER',"AAT_CODVIS"),oModel)		  

If cOperation == "3" .AND. lAgendAbb
	If MsgYesNo(STR0029,STR0020) //"Deseja agendar esta vistoria t้cnica agora?"#"Aten็ใo"
		Teca510(,cCodAtend)
	EndIf
EndIf

Return( .T. )
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270AfterบAutor  ณVendas CRM          บ Data ณ  20/03/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณAtualiza a oportunidade ou proposta.       		          บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro			                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpO1 - Modelo de dados.  		    					  บฑฑ  
ฑฑบ			 ณExpC2 - Id do Modelo.  		    	   					  บฑฑ 
ฑฑบ			 ณExpC3 - Alias.  		    		  						  บฑฑ 
ฑฑบ			 ณExpN4 - Operacao.  		    		  					  บฑฑ 
ฑฑบ			 ณExpC5 - Vistoria.  		    	  						  บฑฑ 
ฑฑบ			 ณExpC6 - Oportunidade.  		    				   		  บฑฑ 
ฑฑบ			 ณExpC7 - Proposta.  		    							  บฑฑ  
ฑฑบ			 ณExpC8 - Revisao.     				    					  บฑฑ  
ฑฑบ			 ณExpC9 - Status.  		    								  บฑฑ    
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออออปฑฑ
ฑฑบPrograma  ณAt270VdSts บAutor  ณVendas CRM          บ Data ณ  28/03/12     บฑฑ
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออออนฑฑ
ฑฑบDesc.     ณValida o status da vistoria tecnica.						     บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro / Falso                                      บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณNenhum					                                     บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                        บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Function At270VdSts()    

Local oMdl			:= FWModelActive() 	 				// Retorna o model ativo.         
Local nOperation	:= oMdl:GetOperation()   		   	// Numero da operacao.
Local oMdlAAT		:= oMdl:GetModel("AATMASTER")		// Obtem o modelo de dados AATMASTER.
Local cStatus		:= oMdlAAT:GetValue("AAT_STATUS") 	// Status da vistoria.
Local lRetorno	:= .T.									// Retorno da validacao


If nOperation == 4  

	If ( AAT->AAT_STATUS == "3" .AND. cStatus <> "3" ) 
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ	 Problema: Nใo serแ possivel alterar o status de uma vistoria t้cnica concluida.  ณ
		//ณ	 Solucao: Inclua uma nova vistoria. 											  ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		Help(" ",1,"AT270STSCON")
		lRetorno := .F. 
	ElseIf ( AAT->AAT_STATUS == "4" .AND. cStatus <> "4" )	  
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณ	 Problema: Nใo serแ possivel alterar o status de uma vistoria t้cnica cancelada.  ณ
		//ณ	 Solucao: Inclua uma nova vistoria. 											  ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		Help(" ",1,"AT270STSCAN")
		lRetorno := .F. 
	EndIf	
	
EndIf
	
Return( lRetorno )   

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270Canc บAutor  ณVendas CRM          บ Data ณ  14/07/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณBloco de Cancelamento do Formulario MVC.       	   		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณExpL - Verdadeiro			                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpO1 - Modelo de dados.  		    					  บฑฑ  
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Function At270Canc(oModel)

Local aAreaAF1		:= AF1->(GetArea())						// Area da tabela AF1.               
Local nOperation		:= oModel:GetOperation()  				// Numero da operacao.
Local oMdlAAT			:= oModel:GetModel("AATMASTER")	    	// Obtem o modelo de dados AATMASTER.
Local cCodVis			:= oMdlAAT:GetValue("AAT_CODVIS")  	// Codigo da vistoria tecnica.
Local cTipo		 	:= "3" 							  		// Vistoria tecnica.
Local lOrcPrc 		:= SuperGetMv("MV_ORCPRC",,.F.)			// Qual formato do or็amento de servi็o : com precifica็ใo (.t.) sem precifica็ใo (.f.)

If nOperation == 3
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณVerifica se foi feita alguma simulacao de horas na vistoria tecnica.ณ
	//ณSe sim, essa simulacao deve ser excluida para evitar que o proximo  ณ
	//ณa usar a simulacao inicie com uma ja preenchida.    		  		   ณ 
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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

A600Clean() // Detroy o objeto do or็amento de servi็os
//---------------------------------------------
//  Elimina as informa็๕es de controle do or็amento com precifica็ใo
If lOrcPrc
	AT740FGXML(,,.T.)
	At600STabPrc( "", "" )
EndIf
FWFormCancel(oModel)

RestArea(aAreaAF1)

Return(.T.) 

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270GvAbbบAutor  ณ                    บ Data ณ  28/11/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณGrava็ใo no controle de aloca็ใo.			       	   		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณ							                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpO1 - Numero da operacao( 1=Visualizar; 3=Incluir; 		  บฑฑ
ฑฑบ	    	 ณ							  4=Alterar; 5=Excluir ).		  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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

DbSelectArea("ABB")		//Tabela de Aloca็ใo de Atendentes
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
	Help("",1,"AT270GVABB",,STR0030,2,0) //"O T้cnico jแ possui aloca็ใo no perํodo escolhido."
	lRetorno := .F.
EndIf

RestArea(aAreaAAT)
RestArea(aAreaABB)           

If !lRetorno .AND. InTransact()
	DisarmTransaction()
EndIf

Return(lRetorno)
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270Agend บAutor  ณTOTVS		          บ Data ณ  10/01/13   บฑฑ             
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณChamada da fun็ใo de controle de aloca็ใo.				   บฑฑ
ฑฑบ			 ณ 															   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270					                                   บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/                          
Function At270Agend()	
	TECA510(,AAT->AAT_VISTOR)
Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัอออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAt270LoIt  บAutor  ณVendas CRM          บ Data ณ  10/01/13   บฑฑ             
ฑฑฬออออออออออุอออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณGatilho para preencher o campo AAU_LOCAL(Item) com o conteudoบฑฑ
ฑฑบ			 ณ do AAT_LOCAL(Cabecalho).									   บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบRetorno   ณValor do campo AAU_LOCAL                                     บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณExpC1 - Modelo de Dados.                                     บฑฑ
ฑฑฬออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณTECA270 - Gatilho(SX7)                                       บฑฑ
ฑฑศออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
Rotina de ativa็ใo do Model.

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

	//Ativa็ใo em caso de exclusใo da Vistoria
	Case nOpc == MODEL_OPERATION_DELETE 
		//Verifica se a oportunidade estแ aberta, se sim permite a exclusใo.
		If ( StatOport( cOport ) != '1' )
			Help( " ", 1, "At270Activ", , STR0033, 1 )	//"Nใo ้ possํvel excluir Vistorias T้cnicas de oportunidades que nใo estejam abertas."
			lRet := .F.
		EndIf
		
		If lRet .And. cStatus == "3"
			Help( "", 1, "At270Activ", , STR0045, 1 ) //"Nใo ้ possํvel excluir Vistorias T้cnicas que estejam com o status igual a concluํdo."
			lRet := .F.
		Endif
	//Ativa็ใo em caso de altera็ใo da Vistoria	
	Case nOpc == MODEL_OPERATION_UPDATE
		//Verifica se a oportunidade estแ aberta, se sim permite a altera็ใo.
		If ( StatOport( cOport ) != '1' )
			Help( " ", 1, "At270Activ", , STR0034, 1 )	//"Nใo ้ possํvel alterar Vistorias T้cnicas de oportunidades que nใo estejam abertas."
			lRet := .F.
		EndIf
		
		If lRet .And. cStatus == "3"
			Help( " ", 1, "At270Activ", , STR0046, 1 ) //"Nใo ้ possํvel alterar Vistorias T้cnicas que estejam com o status igual a concluํdo."
			lRet := .F.
		Endif
EndCase

RestArea( aArea )

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} StatOport
Retorna o status de uma oportunidade.

@sample 	StatOport( cOport )
@param		cOport		N๚mero da oportunidade para busca.
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

@author	Servi็os
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
Consiste as informa็๕es dos campos para a cria็ใo do or็amento de vendas.

@sample 	At270GerOrc( nOperacao, lVistoria, oModel )

@param		nOperacao	Opera็ใo do model utilizada.
@param     oModel		Model utilizado para a vistoria tecnica

@result	lRet	  	Retorna se a opera็ใo teve sucesso na cria็ใo.

@author	Servi็os
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
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Oportunidade de venda nใo informado.                               ณ
	//ณ	 Solucao: Informe a oportunidade de venda no cabe็alho da vistoria t้cnica.   ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"OPORTREVIS")
	lRet := .F.
EndIf

If ( Empty(cDatIni) .AND. Empty(cHorIni) ) .OR. ( Empty(cDatFim) .AND. Empty(cHorFim) ) 
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ	 Problema: Perํodo de agendamento invแlido.       ณ
	//ณ	 Solucao: Informe outro perํodo.   				  ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	Help("",1,"AT270VLDATAHR")                  
	lRet := .F.
EndIf

If lRet
	
	At600SeAtu( nOperacao, .T., oModel ) 
EndIf

Return( lRet )
