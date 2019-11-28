#INCLUDE "TECA750.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

Static cFrear		:= ""
Static cFrearCol	:= ""

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA750

Cadastro de Ocorrência de Armamentos - TE4

@author 	Serviços
@since 		20/08/13
@version 	P11 R9
@param		cFilterData, Caracter, código a ser utilizado para filtragem padrão da tabela/browse
/*/
//----------------------------------------------------------------------------------------------------------------------
Function TECA750(cFilterData)

Local oBrowse

Default cFilterData := ""

Private aRotina	:= MenuDef()
Private cCadastro	:= STR0001 //"Cadastro de Ocorrência"

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('TE4')
oBrowse:SetDescription(STR0001) //Cadastro de Ocorrência

If !Empty(cFilterData)
	oBrowse:SetFilterDefault(cFilterData)
EndIf

oBrowse:Activate()

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

Definição do MenuDef

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:aRotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE STR0002 ACTION 'PesqBrw' 			OPERATION 1 ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0003 ACTION 'VIEWDEF.TECA750' 	OPERATION 2 ACCESS 0 //"Visualizar"
ADD OPTION aRotina TITLE STR0004 ACTION 'VIEWDEF.TECA750' 	OPERATION 3 ACCESS 0 //"Incluir"
ADD OPTION aRotina TITLE STR0005 ACTION 'VIEWDEF.TECA750' 	OPERATION 4 ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0006 ACTION 'VIEWDEF.TECA750' 	OPERATION 5 ACCESS 0 //"Excluir"
ADD OPTION aRotina TITLE STR0007 ACTION 'MSDOCUMENT'			OPERATION 7 ACCESS 0 //"Bco. Conhecimento"

Return (aRotina)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Model 

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:oModel
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oModel
Local oStruTE4		:= FWFormStruct(1,'TE4')     //Tabela cadastral
Local oStruTE5  	:= FWFormStruct(1,'TE5')		//Tabela de Funcionarios da ocorrencia	
Local oStruTE6  	:= FWFormStruct(1,'TE6')		//Tabela de Arma
Local oStruTES  	:= FWFormStruct(1,'TES')		//Tabela de Arma
Local oStruTET  	:= FWFormStruct(1,'TET')		//Tabela de Arma
Local oStruTE7  	:= FWFormStruct(1,'TE7')		//Tabela de Pessoas
Local aAux			:= {}
Local aAux1		:= {}
Local aAux2		:= {}
Local aAux3		:= {}
Local aAux4		:= {}
Local aAux5		:= {}
Local aAux6		:= {}
Local aAux7		:= {}

Local bPosValidacao	:= {|oModel|At750PosValid(oModel)}
Local bCommit			:= {|oModel|At750Grava(oModel)}
Local bPosValTE6		:= {|oModel|At750PosT6(oModel) }
Local bPosValTES		:= {|oModel|At750PosTS(oModel) }
Local bPosValTET		:= {|oModel|At750PosTET(oModel)}	

//Criação de Gatilhos para preencher os campos de Municipio e Estado
aAux1 := FwStruTrigger("TE4_EST","TE4_ESTADO","At750DescEst()",.F.,Nil,Nil,Nil)
oStruTE4:AddTrigger(aAux1[1],aAux1[2],aAux1[3],aAux1[4]) 

aAux := FwStruTrigger("TE4_CODMUN","TE4_MUN","At750DescMun()",.F.,Nil,Nil,Nil)
oStruTE4:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux2 := FwStruTrigger("TE4_CONTAT","TE4_NOMCTN","At750DescCont(1)",.F.,Nil,Nil,Nil)
oStruTE4:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

aAux2 := FwStruTrigger("TE7_CONTAT","TE7_NOME","At750DescCont(2)",.F.,Nil,Nil,Nil)
oStruTE7:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

aAux2 := FwStruTrigger("TE5_ATEND","TE5_NOMATE","At750DescAten(2),At750DescAten(3),At750DescAten(4)",.F.,Nil,Nil,Nil)
oStruTE5:AddTrigger(aAux2[1],aAux2[2],aAux2[3],aAux2[4])

aAux3 := FwStruTrigger("TE4_LOCINT","TE4_DSCINT","At750DescLoc()",.F.,Nil,Nil,Nil)
oStruTE4:AddTrigger(aAux3[1],aAux3[2],aAux3[3],aAux3[4])

aAux4 := FwStruTrigger("TE4_LOCAL","TE4_DSCPOS","At750LocAtd()",.F.,Nil,Nil,Nil)
oStruTE4:AddTrigger(aAux4[1],aAux4[2],aAux4[3],aAux4[4])

aAux5 := FwStruTrigger("TE6_ARMA","TE6_DSCPRO","At750TE6(1),At750TE6(2)",.F.,Nil,Nil,Nil)
oStruTE6:AddTrigger(aAux5[1],aAux5[2],aAux5[3],aAux5[4])

aAux6 := FwStruTrigger("TES_CODCOL","TES_DSCPRO","At750TES(1),At750TES(2)",.F.,Nil,Nil,Nil)
oStruTES:AddTrigger(aAux6[1],aAux6[2],aAux6[3],aAux6[4])

//Instancia o cadastro de Ocorrencia
oModel := MPFormModel():New('TECA750',/*bPreValidacao*/,bPosValidacao,bCommit,/*bCancel*/)

//Instancia o cabeçalho da ocorrencia
oModel:AddFields('TE4MASTER',/*cOwner*/,oStruTE4,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/,/*bFieldAbp*/)

//Instancia o Grid para cadastro de ocorrencia
oModel:AddGrid("TE5FUNC","TE4MASTER",oStruTE5,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*bLoadPrd*/)
oModel:AddGrid("TE7PESSOA","TE4MASTER",oStruTE7,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/,/*bLoadAce*/)

oModel:AddGrid("TE6ARMA","TE5FUNC",oStruTE6,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, bPosValTE6,/*bLoadFunc*/)
oModel:AddGrid("TESCOL","TE5FUNC",oStruTES,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, bPosValTES,/*bLoadAce*/)
oModel:AddGrid("TETMUN","TE5FUNC",oStruTET,/*bLinePre*/,/*bLinePost*/, /*bPreValTET*/, bPosValTET,/*bLoadAce*/)


//Realiza o relacionamento entre o cabeçalho e os grids Funcionario/Pessoas
oModel:SetRelation("TE5FUNC",{{"TE5_FILIAL","xFilial('TE5')"},{"TE5_CDOCOR","TE4_COD"}},TE5->( IndexKey(1)))  
oModel:SetRelation("TE7PESSOA",{{"TE7_FILIAL","xFilial('TE7')"},{"TE7_CDOCOR","TE4_COD"}},TE7->( IndexKey(1)))

oModel:SetRelation("TE6ARMA",{{"TE6_FILIAL","xFilial('TE6')"},{"TE6_CDOCOR","TE4_COD"},{"TE6_ATEND","TE5_ATEND"},{"TE6_ITEM","TE5_ITEM"}},TE6->( IndexKey(1)))
oModel:SetRelation("TESCOL",{{"TES_FILIAL","xFilial('TES')"},{"TES_CDOCOR","TE4_COD"},{"TES_ATEND","TE5_ATEND"},{"TES_ITEM","TE5_ITEM"}},TES->( IndexKey(1)))
oModel:SetRelation("TETMUN",{{"TET_FILIAL","xFilial('TET')"},{"TET_CDOCOR","TE4_COD"},{"TET_ATEND","TE5_ATEND"},{"TET_ITEM","TE5_ITEM"}},TET->( IndexKey(1)))

//Configura o Grid para não duplicar a linha do Grid
oModel:GetModel("TE5FUNC"):SetUniqueLine({"TE5_ATEND"})
oModel:GetModel("TE7PESSOA"):SetUniqueLine({"TE7_CONTAT"})

oModel:GetModel("TE6ARMA"):SetUniqueLine({"TE6_ARMA"})
oModel:GetModel("TESCOL"):SetUniqueLine({"TES_CODCOL"})
oModel:GetModel("TETMUN"):SetUniqueLine({"TET_PRODUT"})

//Permite o Grid sem dados
oModel:GetModel("TE5FUNC"):SetOptional(.T.)
oModel:GetModel("TE7PESSOA"):SetOptional(.T.)

oModel:GetModel("TE6ARMA"):SetOptional(.T.)
oModel:GetModel("TESCOL"):SetOptional(.T.)
oModel:GetModel("TETMUN"):SetOptional(.T.)

//Desabilita o Grid de Armas para Edição
oModel:GetModel( 'TE6ARMA' ):SetNoInsertLine( .T. )
oModel:GetModel( 'TE6ARMA' ):SetNoDeleteLine( .T. )
oModel:GetModel( 'TE6ARMA' ):SetNoUpdateLine( .T. )
	
oModel:GetModel( 'TESCOL' ):SetNoInsertLine( .T. )
oModel:GetModel( 'TESCOL' ):SetNoDeleteLine( .T. )
oModel:GetModel( 'TESCOL' ):SetNoUpdateLine( .T. )
	
oModel:GetModel( 'TETMUN' ):SetNoInsertLine( .T. )
oModel:GetModel( 'TETMUN' ):SetNoDeleteLine( .T. )
oModel:GetModel( 'TETMUN' ):SetNoUpdateLine( .T. )

Return(oModel)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef

Definição da View 

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpO:oView
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView		:= Nil
Local oModel   	:= FWLoadModel('TECA750')
Local oStruTE4 	:= FWFormStruct(2,'TE4')   		//Ocorrencia
Local oStruTE5	:= FWFormStruct(2,"TE5")		//Funcionarios
Local oStruTE6  := FWFormStruct(2,'TE6')		//Arma
Local oStruTES  := FWFormStruct(2,'TES')		//Colete
Local oStruTET 	:= FWFormStruct(2,'TET',{|cCampo| !(AllTrim(cCampo)+"|" $ "TET_LOTE|TET_DTVAL|TET_SINARM|")})		//Munição
Local oStruTE7	:= FWFormStruct(2,"TE7") 		//Pessoas		


oView:= FWFormView():New()
oView:SetModel(oModel)

oView:AddUserButton(STR0007, 'CLIPS',{|oView|MsDocument('TE4',TE4->(RECNO()),oModel:GetOperation() )}) //"Bco. Conhecimento"

oStruTE4:RemoveField("TE4_CDUSER")

oStruTE5:RemoveField("TE5_CDOCOR")

oStruTE6:RemoveField("TE6_ATEND")  
oStruTE6:RemoveField("TE6_CDOCOR")
oStruTE6:RemoveField("TE6_ITEM") 
 
oStruTE7:RemoveField("TE7_CDOCOR")

oStruTES:RemoveField("TES_ATEND")  
oStruTES:RemoveField("TES_CDOCOR")

oStruTET:RemoveField("TET_ATEND")  
oStruTET:RemoveField("TET_CDOCOR")

oView:AddField('VIEW_CAB',oStruTE4,'TE4MASTER')

oView:AddGrid("VIEW_GRID_TE5",oStruTE5,"TE5FUNC")

oView:AddGrid("VIEW_GRID_TE6",oStruTE6,"TE6ARMA")
oView:AddGrid("VIEW_GRID_TES",oStruTES,"TESCOL")
oView:AddGrid("VIEW_GRID_TET",oStruTET,"TETMUN")

oView:AddGrid("VIEW_GRID_TE7",oStruTE7,"TE7PESSOA")

oView:AddIncrementField( 'VIEW_GRID_TE5', 'TE5_ITEM' )		// Item Incremental do Grid Funcionarios
oView:AddIncrementField( 'VIEW_GRID_TE6', 'TE6_SBITEM' )		// Item Incremental do Grid Arma
oView:AddIncrementField( 'VIEW_GRID_TES', 'TES_ITEM' )		// Item Incremental do Grid Colete
oView:AddIncrementField( 'VIEW_GRID_TET', 'TET_ITEM' )		// Item Incremental do Grid Munição

oView:AddIncrementField( 'VIEW_GRID_TE7', 'TE7_ITEM' )		// Item Incremental do Grid Pessoas

oView:CreateHorizontalBox('SUPERIOR',30)
oView:CreateHorizontalBox('INFERIOR',50)
oView:CreateHorizontalBox('INFERIOR2',20)

//Cria pastas
oView:CreateFolder('PASTAS','INFERIOR')
oView:CreateFolder('PASTAS2','INFERIOR2')

oView:AddSheet( 'PASTAS', 'ABA01', STR0008,{|| At750VdFolder(oView:GetFolderActive("PASTAS",2))}) //"Atendentes"

oView:AddSheet( 'PASTAS2', 'ABA01', STR0009) //"Arma"
oView:AddSheet( 'PASTAS2', 'ABA02', STR0010) //"Colete"
oView:AddSheet( 'PASTAS2', 'ABA03', STR0011) //"Munição"

oView:AddSheet( 'PASTAS', 'ABA02', STR0012,{|| At750VdFolder(oView:GetFolderActive("PASTAS",2))}) //"Pessoas"

// Cria um "box" horizontal para receber cada elemento da view			
oView:CreateHorizontalBox( 'ABAS1'  , 100,,, 'PASTAS', 'ABA01' )	//"Funcionarios"
oView:CreateHorizontalBox( 'ABAS2' ,  100,,, 'PASTAS', 'ABA02' )	//"Pessoas"

oView:CreateHorizontalBox( 'ABA10'  , 100,,, 'PASTAS2', 'ABA01' )	//"Arma"
oView:CreateHorizontalBox( 'ABA20' ,  100,,, 'PASTAS2', 'ABA02' )	//"Colete"
oView:CreateHorizontalBox( 'ABA30' ,  100,,, 'PASTAS2', 'ABA03' )	//"Munição"

// Relaciona o identificador (ID) da View com o "box" para exibição
oView:SetOwnerView( 'VIEW_CAB', 'SUPERIOR' )		
oView:SetOwnerView( 'VIEW_GRID_TE5', 'ABAS1' )  	//Atendentes
oView:SetOwnerView( 'VIEW_GRID_TE6', 'ABA10' )	//"Arma"
oView:SetOwnerView( 'VIEW_GRID_TES', 'ABA20' )	//"Colete"
oView:SetOwnerView( 'VIEW_GRID_TET', 'ABA30' )	//"Munição"

oView:SetOwnerView( 'VIEW_GRID_TE7', 'ABAS2' )	//Pessoas

oView:SetCloseOnOk({|| .T.} )

Return(oView)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750VdFolder

Habilita ou Desabilita a Edição do Grid de Armas, conforme o Folder selecionado,
sendo habilitado quando o Folder de Funcionarios estiver selecionado

@author Serviços
@since 20/08/13
@version P11 R9

@param aFolsel,Array com os Dados do Folder

@return ExpL: Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750VdFolder(aFolSel)
Local lRet := .T.

If 	aFolSel[1] == 2 .Or. Empty(FwFldGet("TE4_TPOCOR"))
	//Desabilita o Grid para edição
	oModel := FWModelActive()
	oModel:GetModel( 'TE6ARMA' ):SetNoInsertLine( .T. )
	oModel:GetModel( 'TE6ARMA' ):SetNoDeleteLine( .T. )
	oModel:GetModel( 'TE6ARMA' ):SetNoUpdateLine( .T. )
	
	oModel:GetModel( 'TESCOL' ):SetNoInsertLine( .T. )
	oModel:GetModel( 'TESCOL' ):SetNoDeleteLine( .T. )
	oModel:GetModel( 'TESCOL' ):SetNoUpdateLine( .T. )
	
	oModel:GetModel( 'TETMUN' ):SetNoInsertLine( .T. )
	oModel:GetModel( 'TETMUN' ):SetNoDeleteLine( .T. )
	oModel:GetModel( 'TETMUN' ):SetNoUpdateLine( .T. )
ElseIf aFolSel[1] == 1
	//Habilita o grid para edição
	oModel := FWModelActive()
	oModel:GetModel( 'TE6ARMA' ):SetNoInsertLine( .F. )
	oModel:GetModel( 'TE6ARMA' ):SetNoDeleteLine( .F. )
	oModel:GetModel( 'TE6ARMA' ):SetNoUpdateLine( .F. )
	
	oModel:GetModel( 'TESCOL' ):SetNoInsertLine( .F. )
	oModel:GetModel( 'TESCOL' ):SetNoDeleteLine( .F. )
	oModel:GetModel( 'TESCOL' ):SetNoUpdateLine( .F. )
	
	oModel:GetModel( 'TETMUN' ):SetNoInsertLine( .F. )
	oModel:GetModel( 'TETMUN' ):SetNoDeleteLine( .F. )
	oModel:GetModel( 'TETMUN' ):SetNoUpdateLine( .F. )
EndIf

Return( lRet )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750DescMun

Realiza o gatilho para o campo de descrição do Municipio

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Municipio
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750DescMun()
Local cDescMun		:= ""
Local aArea		:= GetArea()

cDescMun := Alltrim(Posicione("CC2",1,xFilial("CC2")+FwFldGet("TE4_EST")+FwFldGet("TE4_CODMUN"),"CC2_MUN"))

RestArea(aArea)

Return(cDescMun)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750DescEst

Realiza o gatilho para o campo de descrição do Estado

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Estado
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750DescEst()
Local cDescEst		:= ""
Local aArea		:= GetArea()

cDescEst := Alltrim(Posicione("SX5",1,xFilial("SX5")+"12"+FwFldGet("TE4_EST"),"X5_DESCRI"))

RestArea(aArea)

Return(cDescEst)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AT750DescCont

Realiza o gatilho para o campo de Nome do Contato

@author Serviços
@since 20/08/13
@version P11 R9

@param nNumFolder,Numero indicando de qual foi o campo que realizou a chamado da função

@return ExpC:Descrição do Contato
/*/
//--------------------------------------------------------------------------------------------------------------------
Function AT750DescCont(nNumFolder)
Local cDescCont	:= ""
Local aArea		:= GetArea()

Default nNumFolder	:= 0

If nNumFolder == 1
	cDescCont :=AllTrim(Posicione("SU5",1,XFILIAL("SU5")+FwFldGet("TE4_CONTAT"),"U5_CONTAT"))
ElseIf nNumFolder == 2
	cDescCont :=AllTrim(Posicione("SU5",1,XFILIAL("SU5")+FwFldGet("TE7_CONTAT"),"U5_CONTAT"))
EndIf

RestArea(aArea)

Return(cDescCont)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750DescAten

Realiza o gatilho para os campos referentes ao Atendente
@author Serviços
@since 20/08/13
@version P11 R9

@param nNumOpt,Numero indicando qual campo será preenchido

@return ExpC:Descrição do Contato
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750DescAten(nNumOpt)
Local cDesc	:= ""
Local oModel

Default nNumOpt	:= 0

If nNumOpt > 0
	DbSelectArea("AA1")
	DbSetOrder(1)
	If DbSeek(xFilial("AA1")+FwFldGet("TE5_ATEND"))
		Do Case
			Case nNumOpt == 2
				oModel := FWModelActive()
				oModel:setValue("TE5FUNC","TE5_FUNCAO"	,AA1->AA1_FUNCAO)
			Case nNumOpt == 3
				oModel := FWModelActive()
				oModel:setValue("TE5FUNC","TE5_CDFUNC"	,AA1->AA1_CDFUNC)
			Case nNumOpt == 4
				oModel := FWModelActive()
				oModel:setValue("TE5FUNC","TE5_TURNO"	,AA1->AA1_TURNO)
				cDesc := AA1->AA1_NOMTEC
		EndCase
	EndIf 
EndIf

Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750DescLoc

Realiza o gatilho para o campo de descrição do Local Interno

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Local Interno
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750DescLoc()
Local cDescLoc	:= ""
Local aArea		:= GetArea()

cDescLoc := Alltrim(Posicione("TER",1,xFilial("TER")+FwFldGet("TE4_LOCINT"),"TER_DESCRI"))

RestArea(aArea)

Return(cDescLoc)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750LocAtd

Realiza o gatilho para o campo de descrição do Local de Atendimento

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Local de Atendimento
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750LocAtd()
Local cLocal	:= ""
Local aArea	:= GetArea()

cLocal := Alltrim(Posicione("ABS",1,xFilial("ABS")+FwFldGet("TE4_LOCAL"),"ABS_DESCRI"))

RestArea(aArea)

Return(cLocal)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750FArma

Realiza o gatilho para o campo de descrição do FREAR Arma

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Seleção do FREAR Arma
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750FArma(cItem)
Local cSitua		:= ""
Local aArea		:= GetArea()

Default cItem		:= ""

If !Empty(cItem)
	
	If cItem == "1"
		cSitua := Alltrim(Posicione("TE0",1,xFilial("TE0")+FwFldGet("TE6_ARMA"),"TE0_SITUA"))
	ElseIf cItem == "2"
		cSitua := Alltrim(Posicione("TE1",1,xFilial("TE1")+FwFldGet("TES_CODCOL"),"TE1_SITUA"))
	EndIf
	
	If cSitua == "1" .Or. cSitua == "2" .Or. cSitua == "3" .Or. cSitua == "9" .Or. cSitua == "A"	
		cFrear	:= ""
	Else
		Do Case
			Case cSitua == "4"
				cFrear	:= "1"	//Furtada
			Case cSitua == "5"
				cFrear	:= "2"	//Roubada
			Case cSitua == "6"
				cFrear	:= "3"	//Extraviada
			Case cSitua == "7"
				cFrear	:= "4"	//Apreendida
			Case cSitua == "8"
				cFrear	:= "5"	//Recuperada-
		EndCase
	EndIf

EndIf

RestArea(aArea)


Return(cFrear)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750FColete

Realiza o gatilho para o campo de descrição do FREAR Colete

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Seleção do FREAR Colete
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750FColete()
Local cSitua	:= ""
Local aArea	:= GetArea()

cSitua := Alltrim(Posicione("TE1",1,xFilial("TE1")+FwFldGet("TES_ARMA"),"TE1_SITUA"))

If cSitua == "1" .Or. cSitua == "2" .Or. cSitua == "3" .Or. cSitua == "9" .Or. cSitua == "10"	
	cFrearCol := ""
Else
	Do Case
		Case cSitua == "4"
			cFrearCol	:= "1"	//Furtada
		Case cSitua == "5"
			cFrearCol	:= "2"	//Roubada
		Case cSitua == "6"
			cFrearCol	:= "3"	//Extraviada
		Case cSitua == "7"
			cFrearCol	:= "4"	//Apreendida
		Case cSitua == "8"
			cFrearCol	:= "5"	//Recuperada
	EndCase
EndIf

RestArea(aArea)


Return(cFrear)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750AvisoTpOcor

Realiza um aviso quando o tipo de ocorrencia selecionado ser Armamento

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Verdadeiro
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750AvisoTpOcor()
Local lRet		:= .T.
Local oModel	:= Nil

If FwFldGet("TE4_TPOCOR") == "1"
	Aviso(STR0013,STR0014,{STR0015},2)
	
	//Habilita o grid de armas para edição
	oModel := FWModelActive()
	oModel:GetModel( 'TE6ARMA' ):SetNoInsertLine( .F. )
	oModel:GetModel( 'TE6ARMA' ):SetNoDeleteLine( .F. )
	oModel:GetModel( 'TE6ARMA' ):SetNoUpdateLine( .F. )
	
	oModel:GetModel( 'TESCOL' ):SetNoInsertLine( .F. )
	oModel:GetModel( 'TESCOL' ):SetNoDeleteLine( .F. )
	oModel:GetModel( 'TESCOL' ):SetNoUpdateLine( .F. )
	
	oModel:GetModel( 'TETMUN' ):SetNoInsertLine( .F. )
	oModel:GetModel( 'TETMUN' ):SetNoDeleteLine( .F. )
	oModel:GetModel( 'TETMUN' ):SetNoUpdateLine( .F. )
Else
	//Desabilita o Grid para edição
	oModel := FWModelActive()
	oModel:GetModel( 'TE6ARMA' ):SetNoInsertLine( .T. )
	oModel:GetModel( 'TE6ARMA' ):SetNoDeleteLine( .T. )
	oModel:GetModel( 'TE6ARMA' ):SetNoUpdateLine( .T. )
	
	oModel:GetModel( 'TESCOL' ):SetNoInsertLine( .T. )
	oModel:GetModel( 'TESCOL' ):SetNoDeleteLine( .T. )
	oModel:GetModel( 'TESCOL' ):SetNoUpdateLine( .T. )
	
	oModel:GetModel( 'TETMUN' ):SetNoInsertLine( .T. )
	oModel:GetModel( 'TETMUN' ):SetNoDeleteLine( .T. )
	oModel:GetModel( 'TETMUN' ):SetNoUpdateLine( .T. )

EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750PosValid

Realiza as validações da ocorrencia

@author Serviços
@since 20/08/13
@version P11 R9

@param oModel,Model do fonte para gravação

@return ExpL:Retorna .T. se ocorreu sucesso nas validações
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750PosValid(oModel)
Local nOperation 	:= oModel:GetOperation()
Local lRet := .T.

If (nOperation == 3 .OR. nOperation == 4)
	//Limpa os campos de Local ou Posto, conforme seleção do campo TE4_OCPOST.	
	If FwFldGet("TE4_OCPOST") == "S" .And. !Empty(FwFldGet("TE4_LOCINT"))
		oModel:LoadValue("TE4MASTER","TE4_LOCINT"	,"")
		oModel:LoadValue("TE4MASTER","TE4_DSCPOS" , "")	
	ElseIf FwFldGet("TE4_OCPOST") == "N" .And. !Empty(FwFldGet("TE4_LOCAL"))
		oModel:LoadValue("TE4MASTER","TE4_LOCAL"	,"")
		oModel:LoadValue("TE4MASTER","TE4_DSCPOS" , "")	
	EndIf
	
EndIf	

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750PosT6

Realiza as validações do Grid de Armas - TE6

@author Serviços
@since 20/08/13
@version P11 R9

@param oModel,Model do fonte para gravação

@return ExpL:Retorna .T. se ocorreu sucesso nas validações
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750PosT6(oModel)
Local nOperation	:= oModel:GetOperation()
Local lRet			:= .T.
Local nI			:= 0
Local aArea		:= GetArea()

For nI := 1 to oModel:Length()
	oModel:GoLine(nI)
	If (oModel:IsUpdated() .Or. oModel:IsInserted())
		
		If !Empty(FwFldGet("TE4_OCPOST"))
			DbSelectArea("TE0")
			TE0->(DbSetOrder(1))
			
			If TE0->(DbSeek(xFilial("TE0") + FwFldGet("TE6_ARMA")))
			
				If FwFldGet("TE4_OCPOST") == "S"
					
					If !TE0->TE0_LOCAL == FwFldGet("TE4_LOCAL")
						Help( ,, "At750PosT6",, STR0027 + cValToChar(nI) + STR0028, 1, 0 )//"A Arma Selecionada no Item: "##" não está alocada no local selecionado"
						lRet:= .F.
					EndIf
					
				ElseIf FwFldGet("TE4_OCPOST") == "N"
					
					If !TE0->TE0_LOCAL == FwFldGet("TE4_LOCINT")
						Help( ,, "At750PosT6",, STR0027 + cValToChar(nI) + STR0028, 1, 0 )//"A Arma Selecionada no Item: "##" não está alocada no local selecionado"
						lRet:= .F.
					EndIf
					
				EndIf
			
			EndIf
				
		EndIf
		
		If Empty(FWFldGet("TE6_MOTIVO")) .AND. !Empty(FWFldGet("TE6_FREAR")) .And. nOperation == MODEL_OPERATION_UPDATE
			Help( ,, "At750PosT6",, STR0017, 1, 0 )//"Motivo","O Campo Motivo deve ser informado quando o Status FREAR for selecionado!"
			lRet:= .F.
		EndIf
	EndIf
Next nI

RestArea(aArea)


Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750PosTS

Realiza as validações do Grid de Coletes - TES

@author Serviços
@since 20/08/13
@version P11 R9

@param oModel,Model do fonte para gravação

@return ExpL:Retorna .T. se ocorreu sucesso nas validações
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750PosTS(oModel)
Local nOperation	:= oModel:GetOperation()
Local lRet			:= .T.
Local nI			:= 0
Local aArea		:= GetArea()

For nI := 1 to oModel:Length()
	oModel:GoLine(nI)
	If (oModel:IsUpdated() .Or. oModel:IsInserted())
		
		If !Empty(FwFldGet("TE4_OCPOST"))
			DbSelectArea("TE1")
			TE1->(DbSetOrder(1))
			
			If TE1->(DbSeek(xFilial("TE1") + FwFldGet("TES_CODCOL")))
			
				If FwFldGet("TE4_OCPOST") == "S"
					
					If !TE1->TE1_LOCAL == FwFldGet("TE4_LOCAL")
						Help( ,, "At750PosTS",, "O Colete Selecionado no Item: " + cValToChar(nI) + " não está alocada no local selecionado", 1, 0 )
						lRet:= .F.
					EndIf
					
				ElseIf FwFldGet("TE4_OCPOST") == "N"
					
					If !TE1->TE1_LOCAL == FwFldGet("TE4_LOCINT")
						Help( ,, "At750PosTS",, "O Colete Selecionado no Item: " + cValToChar(nI) + " não está alocada no local selecionado", 1, 0 )
						lRet:= .F.
					EndIf
					
				EndIf
			
			EndIf
				
		EndIf
		
		If Empty(FWFldGet("TES_MOTIVO")) .AND. !Empty(FWFldGet("TES_FREAR")) .And. nOperation == MODEL_OPERATION_UPDATE
			Help( ,, "At750PosTS",, STR0017, 1, 0 )//"Motivo","O Campo Motivo deve ser informado quando o Status FREAR for selecionado!"
			lRet:= .F.
		EndIf
	EndIf

Next nI

RestArea(aArea)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc}  At750PosTET

Realiza as validações do Grid de Munições - TET

@author Serviços
@since 20/08/13
@version P11 R9

@param oModel,Model do fonte para gravação

@return ExpL:Retorna .T. se ocorreu sucesso nas validações
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750PosTET(oModel)
Local lRet			:= .T.
Local nOperation	:= oModel:GetOperation()
Local aAreaTFP		:= TFP->(GetArea())
Local aAreaTET		:= TET->(GetArea())
Local nI			:= 0
Local nMunicao		:= 0
Local nRecuperada	:= 0
Local aOcorr		:= {}
Local cCodMun		:= ""



//Limpa os campos de recuperação se o campo Utiliza configurado como Sim e algum FREAR
//Selecionado.
If (FwFldGet("TET_UTILIZ") == "1" .Or. !Empty(FwFldGet("TET_FREA"))) .And.;
	(FwFldGet("TET_RECUPE") == "1" .Or. !Empty(FwfldGet("TET_RECDE")))
		oModel:LoadValue("TET_RECUPE"	,"")
		oModel:LoadValue("TET_RECDE" , "")
EndIf

//Verifica se o campo Utilizado ou Frear estejam preenchidos
If (Empty(FwFldGet("TET_UTILIZ")) .And. Empty(FwFldGet("TET_FREA"))) 
	Help( ,, "At750PosTET",, STR0018, 1, 0 )//"Motivo","O campo FREA ou Utilizado devem estar preenchidos"
	lRet:= .F.
EndIf

If lRet
	For nI := 1 to oModel:Length()
		oModel:GoLine(nI)
		If !oModel:IsDeleted() .AND. (oModel:IsUpdated() .Or. oModel:IsInserted()) .And. (nOperation == MODEL_OPERATION_UPDATE .Or. nOperation == MODEL_OPERATION_INSERT)
			
			//Verifica se Houve movimentação para o posto através da tabela de Historico
			If FwFldGet("TE4_OCPOST") == "N"
				DbSelectArea("TFP")
				TFP->(DbSetOrder(7))
				If !TFP->(DbSeek(xFilial("TFP") + "1" + FwFldGet("TE4_LOCINT") + FwFldGet("TET_PRODUT")))
				
					Help( ,, "At750PosTET",, STR0020 + cValToChar(nI), 1, 0 )//"Essa munição não está alocada no Local Interno Linha: "
					lRet:= .F.		
					Return(lRet)
					
				ElseIf TFP->(DbSeek(xFilial("TFP") + "1" + FwFldGet("TE4_LOCINT") + FwFldGet("TET_PRODUT")))
					cCodMun := TFP->TFP_CODMUN 
					
					If TFP->TFP_SALDO < FwFldGet("TET_QTDMUN") .And. (!Empty(FwFldGet("TET_FREA")) .Or. FwFldGet("TET_UTILIZ") == "1")
						
						Help( ,, "At750PosTET",, STR0021, 1, 0 )//"A quantidade informada é maior do que está alocado!"
						lRet:= .F.
						Return(lRet)
						
					EndIf
					
					If !Empty(FwFldGet("TET_RECUPE"))
					
						If (FwFldGet("TET_RECUPE") == "1" .AND. FwFldGet("TET_UTILIZ") == "2")
						
							While !TFP->(Eof()) .And. TFP->TFP_FILIAL == xFilial("TFP") .And.;	
								TFP->TFP_CODMUN == cCodMun .And. TFP->TFP_CODINT == FwFldGet("TE4_LOCINT")
								
								If TFP->TFP_MOVIM == "3"  
									AAdd(aOcorr,TFP->TFP_CODOCO)			
								ElseIf TFP->TFP_MOVIM == "5" .And. TFP->TFP_RECDE == FwFldGet("TET_RECDE")	
									nRecuperada += TFP_SALDO	
								EndIf
								
								TFP->(DbSkip()) 
								
							End
						
						ElseIf (FwFldGet("TET_RECUPE") == "1" .AND. FwFldGet("TET_UTILIZ") == "1")		
							
							Help( ,, "At750PosTET",, STR0023, 1, 0 )//"Verifique se o campo Utilizado está como Não"
							lRet:= .F.
							Return(lRet)
						
						EndIf
						
					EndIf
				
				EndIf
			
			ElseIf FwFldGet("TE4_OCPOST") == "S"
				TFP->(DbSetOrder(8))
				
				If !TFP->(DbSeek(xFilial("TFP") + "2" + FwFldGet("TE4_LOCAL") + FwFldGet("TET_PRODUT")))	
					
					Help( ,, "At750PosTET",, STR0026 + cValToChar(nI), 1, 0 )//"Esse Lote não está alocado no Local de Atendimento Linha: "
					lRet:= .F.
					Return(lRet)
					
				ElseIf TFP->(DbSeek(xFilial("TFP") + "2" + FwFldGet("TE4_LOCAL") + FwFldGet("TET_PRODUT")))
					cCodMun := TFP->TFP_CODMUN 					
					If TFP->TFP_SALDO < FwFldGet("TET_QTDMUN") .And. (!Empty(FwFldGet("TET_FREA")) .Or. FwFldGet("TET_UTILIZ") == "1")
						
						Help( ,, "At750PosTET",, STR0021, 1, 0 )//"A quantidade informada é maior do que está alocado!"
						lRet:= .F.
						Return(lRet)
					
					EndIf
					
					If !Empty(FwFldGet("TET_RECUPE"))
						
						If (FwFldGet("TET_RECUPE") == "1" .AND. FwFldGet("TET_UTILIZ") == "2")
							
							While !TFP->(Eof()) .And. TFP->TFP_FILIAL == xFilial("TFP") .And.;	
								TFP->TFP_CODMUN == cCodMun .And. TFP->TFP_CODLOC == FwFldGet("TE4_LOCAL")
								
								If TFP->TFP_MOVIM == "3"  
									AAdd(aOcorr,TFP->TFP_CODOCO)			
								ElseIf TFP->TFP_MOVIM == "5" .And. TFP->TFP_RECDE == FwFldGet("TET_RECDE")	
									nRecuperada += TFP_SALDO	
								EndIf
								
								TFP->(DbSkip()) 
								
							End
							
						ElseIf (FwFldGet("TET_RECUPE") == "1" .AND. FwFldGet("TET_UTILIZ") == "1")					
							
							Help( ,, "At750PosTET",, STR0023, 1, 0 )//"Verifique se o campo Utilizado está como Não"
							lRet:= .F.
							Return(lRet)
						
						EndIf
					
					EndIf
								
				EndIf
				
			EndIf
			
		EndIf
		
	Next nI
	
	If lRet
		//Verifica se houve alguma ocorrencia que o FREA é igual ao que foi selecionada
		//no campo Recuperado de, realiza a soma e verifica se a soma é menor ou igual 
		//ao que foi informado.
		DbSelectArea("TET")
		TET->(DbSetOrder(1))
		
		For nI := 1 To Len(aOcorr)
			If TET->(DbSeek(xFilial("TET")+aOcorr[nI]))
				While !TET->(Eof()) .And. TET_FILIAL == xFilial("TET") .And. TET_FREA == FwFldGet("TET_RECDE")	
					nMunicao += TET_QTDMUN
				TET->(DbSkip())
				End
			EndIf	
		Next nI
		
		If nMunicao > 0
			nMunicao := (nMunicao - nRecuperada)
			If nMunicao < FwFldGet("TET_QTDMUN")
				Help( ,, "At750PosTET",, STR0024, 1, 0 )//"Operação","A Quantidade de Munição Informada é maior do que foi relatado em Ocorrencias anteriores"
				lRet := .F.
			EndIf
		ElseIf (FwFldGet("TET_RECUPE") == "1" .AND. FwFldGet("TET_UTILIZ") == "2")
			Help( ,, "At750PosTET",, STR0025, 1, 0 )//"Operação","Não foi encontrada nenhuma ocorrencia do tipo informado em Recuperado de?"
			lRet := .F.
		EndIf	
	EndIf
	
EndIf

RestArea(aAreaTFP)
RestArea(aAreaTET)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750Grava

Realiza as gravações da ocorrencia

@author Serviços
@since 20/08/13
@version P11 R9

@param oModel,Model do fonte para gravação

@return ExpL:Retorna .T. se ocorreu sucesso na Gravação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750Grava(oModel)
Local nOperation 	:= oModel:GetOperation()
Local lRet			:= .T.
Local aAreaTE0		:= {}
Local aAreaTE1		:= {}

Local oModelTE5	:= oModel:GetModel('TE5FUNC')	//Model do Grid Pai
Local oModelTE6	:= oModel:GetModel('TE6ARMA')	//Model do Grid Filho Arma
Local oModelTES	:= oModel:GetModel('TESCOL') 	//Model do Grid Filho Colete
Local oModelTET	:= oModel:GetModel('TETMUN') 	//Model do Grid Filho Colete

Local nX			:= 0 	//Contador do Grid Pai
Local nI			:= 0	//Contador do Grid Filho	Arma
Local nZ			:= 0	//Contador do Grid Filho Colete	
Local nY			:= 0	//Contador do Grid Filho Munição

If (nOperation == 3 .OR. nOperation == 4)
	
	If FwFldGet("TE4_TPOCOR") == "1" 
		
		aAreaTE0	:= TE0->(GetArea())
		aAreaTE1	:= TE1->(GetArea())
			
		For nX := 1 To oModelTE5:Length()
			
			oModelTE5:GoLine(nX)
			
			For nI := 1 To oModelTE6:Length()
				
				oModelTE6:GoLine(nI) 
				
				//Só Atualiza o Status da Arma quando o Grid foi alterado ou Incluido
				If !oModelTE6:IsDeleted() .And. (oModelTE6:IsUpdated() .Or. oModelTE6:IsInserted())		
					At750StArma()
				EndIf
				
			Next nI
			
			For nZ := 1 To oModelTES:Length()
				
				oModelTES:GoLine(nZ) 
				
				//Só Atualiza o Status do Colete quando o Grid foi alterado ou Incluido
				If !oModelTES:IsDeleted() .And. (oModelTES:IsUpdated() .Or. oModelTES:IsInserted())
					At750StColete()
				EndIf
				
			Next nZ
			
			For nY := 1 To oModelTET:Length()
				
				oModelTET:GoLine(nY) 
				
				//Só Atualiza o Status da Arma quando o Grid foi alterado ou Incluido
				If !oModelTET:IsDeleted() .And. (oModelTET:IsUpdated() .Or. oModelTET:IsInserted())
					At750StMunicao()
				EndIf
				
			Next nY
			
		Next nX	
		
		RestArea(aAreaTE0)
		RestArea(aAreaTE1)
				
	EndIf	
	
EndIf

FWModelActive( oModel )
FWFormCommit( oModel )


Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750StArma

Atualiza o Status da Arma conforme o FREAR selecionado

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750StArma()
Local lArma	:= .T.

If (cFrear != FwFldGet("TE6_FREAR")) .AND.(!Empty(FwfldGet("TE6_ARMA")) .And. !Empty(FwFldGet("TE6_FREAR")))
						
	DbSelectArea("TE0")
	TE0->(DbSetOrder(1))
						
	If TE0->(DbSeek(xFilial("TE0")+FwFldGet("TE6_ARMA")))
		Do Case
		Case FwFldGet("TE6_FREAR") == "1" //Furtada
									
			RecLock("TE0",.F.)
			REPLACE TE0_SITUA WITH "4"
			MsUnLock()
									
		Case FwFldGet("TE6_FREAR") == "2" //Roubada
									
			RecLock("TE0",.F.)
			REPLACE TE0_SITUA WITH "5"
			MsUnLock()
									
		Case FwFldGet("TE6_FREAR") == "3" //Extraviada
									
			RecLock("TE0",.F.)
			REPLACE TE0_SITUA WITH "6"
			MsUnLock()
									
		Case FwFldGet("TE6_FREAR") == "4" //Apreendida
									
			RecLock("TE0",.F.)
			REPLACE TE0_SITUA WITH "7"
			MsUnLock()
									
		Case FwFldGet("TE6_FREAR") == "5" //Recuperada
									
			RecLock("TE0",.F.)
			REPLACE TE0_SITUA WITH "8"
			MsUnLock()
									
		EndCase
	EndIf
	
	//Grava o registro de Alteração do FREAR
	At750HistFREAR(FwFldGet("TE6_ARMA"),,lArma,.F.)
						
EndIf

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750StColete

Atualiza o Status da Arma conforme o FREAR selecionado

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750StColete()
Local lColete	:= .T.

If !Empty(FwfldGet("TES_CODCOL")) .And. !Empty(FwFldGet("TES_FREAR"))
						
	DbSelectArea("TE1")
	TE1->(DbSetOrder(1))
						
	If TE1->(DbSeek(xFilial("TE1")+FwFldGet("TES_CODCOL")))
		Do Case
		Case FwFldGet("TES_FREAR") == "1" //Furtada
									
			RecLock("TE1",.F.)
			REPLACE TE1_SITUA WITH "4"
			MsUnLock()
									
		Case FwFldGet("TES_FREAR") == "2" //Roubada
									
			RecLock("TE1",.F.)
			REPLACE TE1_SITUA WITH "5"
			MsUnLock()
									
		Case FwFldGet("TES_FREAR") == "3" //Extraviada
									
			RecLock("TE1",.F.)
			REPLACE TE1_SITUA WITH "6"
			MsUnLock()
									
		Case FwFldGet("TES_FREAR") == "4" //Apreendida
									
			RecLock("TE1",.F.)
			REPLACE TE1_SITUA WITH "7"
			MsUnLock()
									
		Case FwFldGet("TES_FREAR") == "5" //Recuperada
									
			RecLock("TE1",.F.)
			REPLACE TE1_SITUA WITH "8"
			MsUnLock()
									
		EndCase
		
		//Grava o registro de Alteração do FREAR
		At750HistFREAR(,FwFldGet("TES_CODCOL"),.F.,lColete)
		
	EndIf
						
EndIf

Return(.T.)
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750HistFREAR

Atualiza a Tabela TIO para armazenar toda troca de Status dos Armamentos

@author Serviços
@since 20/08/13
@version P11 R9

@param cArma,Codigo da Arma
@Param cColete,Codigo do Colete
@Param lArma,Indica se deve Atualizar a Arma
@Param lColete,Indica se deve atualizar o Colete

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750HistFREAR(cArma,cColete,lArma,lColete)

Default cArma		:= ""
Default cColete	:= ""
Default lArma		:= .F.	
Default lColete	:= .F.

//Grava o TIO para controle do FREAR
Begin Transaction
	DbSelectArea("TIO")
	RecLock("TIO",.T.)
		REPLACE TIO_FILIAL 	With xFilial("TIO")
		REPLACE TIO_CODIGO 	With GetSXENum("TIO","TIO_CODIGO")
		REPLACE TIO_CDOCOR 	With FwFldGet("TE4_COD")
		REPLACE TIO_DTALT 	With dDataBase		
		If lArma
			REPLACE TIO_ARMA 	With cArma
			REPLACE TIO_MOTIVO 	With FwFldGet("TE6_MOTIVO")
			REPLACE TIO_FREAR		With FwFldGet("TE6_FREAR")
		ElseIf lColete
			REPLACE TIO_COLETE With cColete
			REPLACE TIO_MOTIVO 	With FwFldGet("TES_MOTIVO")
			REPLACE TIO_FREAR		With FwFldGet("TES_FREAR")
		EndIf
		REPLACE TIO_CODUSU 	With __cUserId
	MsUnlock()
	ConfirmSX8()
End Transaction	

	
Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750StMunicao

Atualiza a Tabela TFP de historico de movimentação de munições

@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At750StMunicao()
Local aAreaTFP	:= TFP->(GetArea())
Local cCodMun 	:= ""

If FwFldGet("TE4_OCPOST") == "N" .AND. (!Empty(FwFldGet("TET_FREA")) .Or. FwFldGet("TET_UTILIZ") == "1") 
	
	DbSelectArea("TFP")
	TFP->(DbSetOrder(7))
	
	If TFP->(DbSeek(xFilial("TFP") + "1" + FwFldGet("TE4_LOCINT") + FwFldGet("TET_PRODUT")))
		cCodMun := TFP->TFP_CODMUN
		Begin Transaction
			DbSelectArea("TFP")
			RecLock("TFP",.F.)
				REPLACE TFP_SALDO With (TFP->TFP_SALDO - FwFldGet("TET_QTDMUN"))
			MsUnlock()
		End Transaction	
	EndIf
	
	If Empty(cCodMun)	
		TE2->(DbSetOrder(4))
		
		If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TET_PRODUT")))
			cCodMun := TE2_CODMUN
		EndIf	
	EndIf
		
	Begin Transaction
		
		DbSelectArea("TFP")
		RecLock("TFP",.T.)
			REPLACE TFP_FILIAL 	With xFilial("TFP")
			REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
			REPLACE TFP_ENTIDA 	With "1"
			REPLACE TFP_CODINT 	With FwFldGet("TE4_LOCINT")
			REPLACE TFP_SALDO	With FwFldGet("TET_QTDMUN")
			
			If FwFldGet("TET_UTILIZ") == "1"
				REPLACE TFP_MOVIM 	With "4"
			ElseIf Empty(FwFldGet("TET_UTILIZ")) .Or. FwFldGet("TET_UTILIZ") == "2"
				REPLACE TFP_MOVIM 	With "3"
				REPLACE TFP_FREA		With FwFldGet("TET_FREA")
			EndIf
			
			REPLACE TFP_CODMUN	With cCodMun				
			REPLACE TFP_PRODUT	With FwFldGet("TET_PRODUT")
			REPLACE TFP_CODOCO	With FwFldGet("TE4_COD")
			REPLACE TFP_DTHIST	With dDataBase
		
		MsUnlock()
		ConfirmSX8()
	
	End Transaction
	
ElseIf FwFldGet("TE4_OCPOST") == "N" .AND. FwFldGet("TET_UTILIZ") == "2" .And. !Empty(FwFldGet("TET_RECDE"))
	DbSelectArea("TFP")
	TFP->(DbSetOrder(7))
	
	If TFP->(DbSeek(xFilial("TFP") + "1" + FwFldGet("TE4_LOCINT") + FwFldGet("TET_PRODUT")))
		cCodMun := TFP->TFP_CODMUN
		Begin Transaction
			DbSelectArea("TFP")
			RecLock("TFP",.F.)
				REPLACE TFP_SALDO		With (TFP->TFP_SALDO + FwFldGet("TET_QTDMUN"))
			MsUnlock()
		End Transaction	
	EndIf
	
	If Empty(cCodMun)	
		TE2->(DbSetOrder(4))
		
		If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TET_PRODUT")))
			cCodMun := TE2->TE2_CODMUN
		EndIf	
	EndIf	
		
	Begin Transaction
		
		DbSelectArea("TFP")
		RecLock("TFP",.T.)
			REPLACE TFP_FILIAL 	With xFilial("TFP")
			REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
			REPLACE TFP_ENTIDA 	With "1"
			REPLACE TFP_CODINT 	With FwFldGet("TE4_LOCINT")
			REPLACE TFP_SALDO		With FwFldGet("TET_QTDMUN")
			REPLACE TFP_MOVIM 	With "5"
			REPLACE TFP_RECDE		With FwFldGet("TET_RECDE")
			REPLACE TFP_CODMUN	With cCodMun				
			REPLACE TFP_PRODUT	With FwFldGet("TET_PRODUT")
			REPLACE TFP_CODOCO	With FwFldGet("TE4_COD")
			REPLACE TFP_DTHIST	With dDataBase
		
		MsUnlock()
		ConfirmSX8()
	
	End Transaction

ElseIf FwFldGet("TE4_OCPOST") == "S" .AND. (!Empty(FwFldGet("TET_FREA")) .Or. FwFldGet("TET_UTILIZ") == "1") 
	
	DbSelectArea("TFP")
	TFP->(DbSetOrder(8))
	
	If TFP->(DbSeek(xFilial("TFP") + "2" + FwFldGet("TE4_LOCAL") + FwFldGet("TET_PRODUT")))
		cCodMun := TFP->TFP_CODMUN
		Begin Transaction
			DbSelectArea("TFP")
			RecLock("TFP",.F.)
				REPLACE TFP_SALDO		With (TFP->TFP_SALDO - FwFldGet("TET_QTDMUN"))
			MsUnlock()
		End Transaction	
	EndIf
	
	If Empty(cCodMun)	
		TE2->(DbSetOrder(4))
		
		If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TET_PRODUT")))
			cCodMun := TE2->TE2_CODMUN
		EndIf	
	EndIf	
		
	Begin Transaction
		DbSelectArea("TFP")
		RecLock("TFP",.T.)
			REPLACE TFP_FILIAL 	With xFilial("TFP")
			REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
			REPLACE TFP_ENTIDA 	With "2"
			REPLACE TFP_CODLOC 	With FwFldGet("TE4_LOCAL")
			REPLACE TFP_SALDO		With FwFldGet("TET_QTDMUN")
			
			If FwFldGet("TET_UTILIZ") == "1"
				REPLACE TFP_MOVIM 	With "4"
			ElseIf Empty(FwFldGet("TET_UTILIZ")) .Or. FwFldGet("TET_UTILIZ") == "2"
				REPLACE TFP_MOVIM 	With "3"
				REPLACE TFP_FREA		With FwFldGet("TET_FREA")
			EndIf
			
			REPLACE TFP_CODMUN	With cCodMun				
			REPLACE TFP_PRODUT	With FwFldGet("TET_PRODUT")
			REPLACE TFP_CODOCO	With FwFldGet("TE4_COD")
			REPLACE TFP_DTHIST	With dDataBase
		
		MsUnlock()
		ConfirmSX8()
	
	End Transaction


ElseIf FwFldGet("TE4_OCPOST") == "S" .AND. FwFldGet("TET_UTILIZ") == "2" .And. !Empty(FwFldGet("TET_RECDE"))
		DbSelectArea("TFP")
		TFP->(DbSetOrder(8))
	
	If TFP->(DbSeek(xFilial("TFP") + "2" + FwFldGet("TE4_LOCAL") + FwFldGet("TET_PRODUT")))
		cCodMun := TFP->TFP_CODMUN
		Begin Transaction
			DbSelectArea("TFP")
			RecLock("TFP",.F.)
				REPLACE TFP_SALDO		With (TFP->TFP_SALDO + FwFldGet("TET_QTDMUN"))
			MsUnlock()
		End Transaction	
	EndIf
	
	If Empty(cCodMun)	
		TE2->(DbSetOrder(4))
		
		If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TET_PRODUT")))
			cCodMun := TE2->TE2_CODMUN
		EndIf	
	EndIf
		
	Begin Transaction
		
		DbSelectArea("TFP")
		RecLock("TFP",.T.)
			
			REPLACE TFP_FILIAL 	With xFilial("TFP")
			REPLACE TFP_CODIGO 	With GetSXENum("TFP","TFP_CODIGO")
			REPLACE TFP_ENTIDA 	With "2"
			REPLACE TFP_CODLOC 	With FwFldGet("TE4_LOCAL")
			REPLACE TFP_SALDO		With FwFldGet("TET_QTDMUN")
			REPLACE TFP_MOVIM 	With "5"
			REPLACE TFP_RECDE		With FwFldGet("TET_RECDE")
			REPLACE TFP_CODMUN	With cCodMun	
			//REPLACE TFP_LOTE		With FwFldGet("TET_LOTE")
			REPLACE TFP_PRODUT	With FwFldGet("TET_PRODUT")
			REPLACE TFP_CODOCO	With FwFldGet("TE4_COD")
			REPLACE TFP_DTHIST	With dDataBase
		
		MsUnlock()		
		ConfirmSX8()
	
	End Transaction	
EndIf

RestArea(aAreaTFP)

Return(.T.)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750When

Faz o controle de edição do campo TET_UTILIZ
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750When()
Local lRet	:= .F.

If Empty(FwFldGet("TET_UTILIZ")) .Or. FwFldGet("TET_UTILIZ") == "2"
	lRet := .T.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750WRecup

Faz o controle de edição do campo TET_UTILIZ
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpL:Retorna .T. 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750WRecup()
Local lRet	:= .T.

If FwFldGet("TET_UTILIZ") == "1" .Or. !Empty(FwFldGet("TET_FREA"))
	lRet := .F.
EndIf

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750IniArma

Realiza o preenchimento do inicializador dos armamentos
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Armamento 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750IniArma(cItem,cArma)
Local cProd := ""
Local cDesc := ""
	
Default cItem		:= ""
Default cArma		:= ""

If !INCLUI .And. !Empty(cItem) .And. !Empty(cArma)

	Do Case
		Case cItem == "1
			cProd := Posicione("TE0",1,xFilial("TE0") + cArma ,"TE0->TE0_CODPRO")	
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")

		Case cItem == "2"
			cProd := Posicione("TE1",1,xFilial("TE1") + cArma ,"TE1->TE1_CODPRO")
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
		
		Case cItem == "3"
			cProd := Posicione("TE2",1,xFilial("TE2") + cArma ,"TE2->TE2_CODPRO")
			cDesc := Posicione("SB1",1,xFilial("SB1") + cProd ,"SB1->B1_DESC")
	
	EndCase
	
EndIf
	
Return(cDesc)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750TE6

Realiza o preenchimento dos item da Arma no Grid
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Armamento 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750TE6(nPos)
Local cDesc		:= ""
Local oModel		:= Nil
Local aArea 		:= GetArea()
Local cFrear		:= ""

Default nPos := 0

If nPos > 0
	
	If nPos == 1
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
		
		If TE0->(DbSeek(xFilial("TE0") + FwFldGet("TE6_ARMA")))
			oModel := FWModelActive()
			oModel:setValue("TE6ARMA",'TE6_ATIVO',TE0->TE0_ATIVO)
			oModel:setValue("TE6ARMA",'TE6_MARCA',TE0->TE0_MARCA)
			oModel:setValue("TE6ARMA",'TE6_MODELO',TE0->TE0_MODELO)
			oModel:setValue("TE6ARMA",'TE6_ATIVO',TE0->TE0_ATIVO)
			oModel:setValue("TE6ARMA",'TE6_NUMREG',TE0->TE0_NUMREG)
			oModel:setValue("TE6ARMA",'TE6_NSINAR',TE0->TE0_SINARM)
			
			cFrear := At750FArma("1")
			oModel:setValue("TE6ARMA",'TE6_FREAR',cFrear)
		EndIf
		
	ElseIf nPos == 2
		DbSelectArea("TE0")
		TE0->(DbSetOrder(1))
		
		If TE0->(DbSeek(xFilial("TE0") + FwFldGet("TE6_ARMA")))
			cDesc := Posicione("SB1",1,xFilial("SB1") + TE0->TE0_CODPRO ,"SB1->B1_DESC")
		EndIf	
	EndIf
	
EndIf

RestArea(aArea)
					
Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750TES

Realiza o preenchimento dos itens do colete no grid
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Armamento 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750TES(nPos)
Local cDesc		:= ""
Local oModel		:= Nil
Local aArea 		:= GetArea()

Default nPos := 0

If nPos > 0
	
	If nPos == 1
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
		
		If TE1->(DbSeek(xFilial("TE1") + FwFldGet("TES_CODCOL")))
			oModel := FWModelActive()
			oModel:setValue("TESCOL",'TES_FABRIC',TE1->TE1_MARCA)
			oModel:setValue("TESCOL",'TES_VALIDA',TE1->TE1_VALIDA)
			oModel:setValue("TESCOL",'TES_COLETE',TE1->TE1_NUMCOL)
			oModel:setValue("TESCOL",'TES_NUMSER',TE1->TE1_NUMSER)
			oModel:setValue("TESCOL",'TES_SINARM',TE1->TE1_SINARM)
			oModel:setValue("TESCOL",'TES_PLCDIA',TE1->TE1_PLCDIA)
			oModel:setValue("TESCOL",'TES_PLCTRA',TE1->TE1_PLCTRA)
			
			cFrear := At750FArma("2")
			oModel:setValue("TESCOL",'TES_FREAR',cFrear)
		EndIf
		
	ElseIf nPos == 2
		DbSelectArea("TE1")
		TE1->(DbSetOrder(1))
		
		If TE1->(DbSeek(xFilial("TE1") + FwFldGet("TES_CODCOL")))
			cDesc := Posicione("SB1",1,xFilial("SB1") + TE1->TE1_CODPRO ,"SB1->B1_DESC")
		EndIf	
	EndIf
	
EndIf

RestArea(aArea)
					
Return(cDesc)	

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750TET

Realiza o preenchimento dos itens da munição no grid
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpC:Descrição do Armamento 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750TET()
Local cDesc		:= ""
Local oModel	:= Nil
Local aArea 	:= GetArea()

DbSelectArea("TE2")
TE2->(DbSetOrder(4))
		
If TE2->(DbSeek(xFilial("TE2") + FwFldGet("TET_PRODUT")))
	cDesc := Posicione("SB1",1,xFilial("SB1") + TE2->TE2_CODPRO ,"SB1->B1_DESC")
EndIf

oModel := FWModelActive()	
oModel:setValue("TETMUN",'TET_MARCA',TE2->TE2_MARCA)
oModel:setValue("TETMUN",'TET_CALIBR',TE2->TE2_CALIBR)


RestArea(aArea)
					
Return(cDesc)	
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At750IniData

Realiza a inicialização dos campos data do Grid de armas
@author Serviços
@since 20/08/13
@version P11 R9

@return ExpD:Data
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At750IniData(cItem,cArma)
Local dData
Local aArea	:= GetArea()

Default cItem	:= ""
Default cArma := ""

If !Empty(cItem) .And. !Empty(cArma)

	If cItem == "1"
		dData := Posicione("TE1",1,xFilial("TE1") + cArma ,"TE1->TE1_VALIDA")
	ElseIf cItem == "2"
	dData := Posicione("TE2",4,xFilial("TE2") + cArma ,"TE2->TE2_VALIDA")
	EndIf

EndIf

RestArea(aArea)

Return(dData)