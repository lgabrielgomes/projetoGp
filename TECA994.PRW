#INCLUDE "TECA994.CH"
#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDEF.CH"

#DEFINE _TPIP_CABEC    	"0"
#DEFINE _TPIP_FUNCAO    "1"
#DEFINE _TPIP_TURNO    	"2"
#DEFINE _TPIP_ESCALA    "3"
#DEFINE _TPIP_MATIMPL   "4"
#DEFINE _TPIP_MATCONS   "5"


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA994	

Cadastro de Vínculos

@author 	Serviços
@since 		19/03/2019
@version P12117
/*/
//----------------------------------------------------------------------------------------------------------------------
Function TECA994()
Local cFilDefault := "TXA->TXA_TPIT = '" + _TPIP_CABEC  + "'"
Local oBrowse := NIL

If SuperGetMv("MV_GSVINC",,.F.)

	oBrowse := FwMBrowse():New()
	oBrowse:SetAlias( 'TXA' )
	oBrowse:SetMenudef( 'TECA994' )
	oBrowse:SetDescription(STR0001) //Configuração de Vínculos
	oBrowse:SetFilterDefault(cFilDefault)
	oBrowse:Activate()
Else
	MsgStop(STR0002) //"Para habilitar a funcionalidade de configuração de vínculos, favor habilitar o parâmetro MV_GSVINC"
EndIf

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef

Definição do MenuDef

@author Serviços
@since 19/03/2019
@version P12117

@return ExpO:aRotina
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function MenuDef()

LOCAL aRotina := {}


ADD OPTION aRotina TITLE STR0003	ACTION 'PesqBrw' 			OPERATION 1 ACCESS 0 //"Pesquisar"
ADD OPTION aRotina TITLE STR0004	ACTION 'VIEWDEF.TECA994' 	OPERATION 2 ACCESS 0 //"Visualizar"
ADD OPTION aRotina TITLE STR0005		ACTION 'VIEWDEF.TECA994' 	OPERATION 3 ACCESS 0 //"Incluir"
ADD OPTION aRotina TITLE STR0006		ACTION 'VIEWDEF.TECA994' 	OPERATION 4 ACCESS 0 //"Alterar"
ADD OPTION aRotina TITLE STR0007		ACTION 'VIEWDEF.TECA994' 	OPERATION 5 ACCESS 0 //"Excluir"

Return aRotina

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef

Definição do Model 

@author Serviços
@since 19/03/2019
@version P12117

@return ExpO:oModel
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruTXAC 	:= FWFormModelStruct():New()
Local oStruTXAF		:= FWFormStruct(1,'TXA', {|cCampo| !( RTrim(cCampo) $ "TXA_PRODUT;TXA_TPIT;TXA_DESCR") })		//Item de Função
Local oStruTXAT		:= FWFormStruct(1,'TXA', {|cCampo|  !( RTrim(cCampo) $ "TXA_PRODUT;TXA_TPIT;TXA_DESCR") })		//Item de Turno
Local oStruTXAE		:= FWFormStruct(1,'TXA', {|cCampo|  !( RTrim(cCampo) $ "TXA_PRODUT;TXA_TPIT;TXA_DESCR") })		//Item de Escala
Local oStruTXAMI	:= FWFormStruct(1,'TXA', {|cCampo|  !( RTrim(cCampo) $ "TXA_PRODUT;TXA_TPIT;TXA_DESCR")})		//Item de MI
Local oStruTXAMC	:= FWFormStruct(1,'TXA', {|cCampo|  !( RTrim(cCampo) $ "TXA_PRODUT;TXA_TPIT;TXA_DESCR") })		//Item de MC
Local xAux			:= {}

oStruTXAC:AddTable("ZXA",{},oStruTXAF:GetTable()[3])	//"Configuração de Vínculos"
oStruTXAC:AddField( ;
						RetTitle("TXA_PRODUT"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_PRODUT"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_PRODUT",;					// [03] Id do Field
						GetSx3Cache("TXA_PRODUT","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_PRODUT","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_PRODUT","X3_DECIMAL"),;								// [06] Decimal do campo
						/**/,;						// [07] Code-block de validação do campo
						/*nil*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						.T.;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)

oStruTXAC:AddField( ;
						RetTitle("TXA_DESCR"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_DESCR"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_DESCR",;					// [03] Id do Field
						GetSx3Cache("TXA_DESCR","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_DESCR","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_DESCR","X3_DECIMAL"),;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)

oStruTXAC:AddField( ;
						RetTitle("TXA_EXFUNC"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_EXFUNC"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_EXFUNC",;					// [03] Id do Field
						GetSx3Cache("TXA_EXFUNC","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_EXFUNC","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_EXFUNC","X3_DECIMAL"),;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)						

oStruTXAC:AddField( ;
						RetTitle("TXA_EXTUR"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_EXTUR"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_EXTUR",;					// [03] Id do Field
						GetSx3Cache("TXA_EXTUR","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_EXTUR","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_EXTUR","X3_DECIMAL"),;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						{||.F.},;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)							

oStruTXAC:AddField( ;
						RetTitle("TXA_EXESC"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_EXESC"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_EXESC",;					// [03] Id do Field
						GetSx3Cache("TXA_EXESC","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_EXESC","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_EXESC","X3_DECIMAL"),;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)							

oStruTXAC:AddField( ;
						RetTitle("TXA_EXMC"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_EXMC"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_EXMC",;					// [03] Id do Field
						GetSx3Cache("TXA_EXMC","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_EXMC","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_EXMC","X3_DECIMAL"),;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)

oStruTXAC:AddField( ;
						RetTitle("TXA_EXMI"),;						// [01] Titulo do campo # "Apuração"
						RetTitle("TXA_EXMI"),;						// [02] ToolTip do campo # "Apuração"
						"ZXA_EXMI",;					// [03] Id do Field
						GetSx3Cache("TXA_EXMI","X3_TIPO"),;							// [04] Tipo do campo
						GetSx3Cache("TXA_EXMI","X3_TAMANHO"),;							// [05] Tamanho do campo
						GetSx3Cache("TXA_EXMI","X3_DECIMAL"),;								// [06] Decimal do campo
						/*NIL*/,;						// [07] Code-block de validação do campo
						/*NIL*/,;						// [08] Code-block de validação When do campo
						/*NIL*/,;						// [09] Lista de valores permitido do campo
						/*.F.*/,;						// [10] Indica se o campo tem preenchimento obrigatório
						/*NIL*/,;						// [11] Code-block de inicializacao do campo
						/*.F.*/,;						// [12] Indica se trata-se de um campo chave
						.F.,;							// [13] Indica se o campo pode receber valor em uma operação de update.
						.F.)

oStruTXAC:SetProperty("ZXA_PRODUT", MODEL_FIELD_VALID, {|oModel| IIF( Inclui, ExistChav("TXA", oModel:GetValue("ZXA_PRODUT"), 1), .F. )} )

oStruTXAF:SetProperty('TXA_FUNCAO',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAT:SetProperty('TXA_TURNO',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAE:SetProperty('TXA_ESCALA',MODEL_FIELD_OBRIGAT,.T.)

oStruTXAMI:SetProperty('TXA_PRDMAT',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAMI:SetProperty('TXA_QTDE',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAMI:SetProperty('TXA_TPQTDE',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAMI:SetProperty("TXA_OBRIGA", MODEL_FIELD_VALID, {|oModel| At994VlObr(oModel:GetValue("TXA_PRDMAT"), M->TXA_OBRIGA) } )

oStruTXAMC:SetProperty('TXA_PRDMAT',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAMC:SetProperty('TXA_QTDE',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAMC:SetProperty('TXA_TPQTDE',MODEL_FIELD_OBRIGAT,.T.)
oStruTXAMC:SetProperty("TXA_OBRIGA", MODEL_FIELD_VALID, {|oModel| At994VlObr(oModel:GetValue("TXA_PRDMAT"), M->TXA_OBRIGA, oModel) } )

xAux := FwStruTrigger('ZXA_PRODUT', "ZXA_DESCR", 'GetAdvFVal("SB1", "B1_DESC", xFilial("SB1")+M->ZXA_PRODUT, 1, "")', .F., ,, ,, "001")
oStruTXAC:AddTrigger( xAux[1], xAux[2], xAux[3] , xAux[4])


//Instancia o cadastro de Ocorrencia
oModel := MPFormModel():New('TECA994',/*bPreValidacao*/,{|oModel|At994PosVld(oModel)},{|oModel|At994Commit(oModel)},/*bCancel*/)

//Instancia o cabeçalho da ocorrencia
oModel:AddFields('TXAMASTER',/*cOwner*/,oStruTXAC,/*bPreValidacao*/,,{|oModel| At994InitD(oModel)}, ,/*bFieldAbp*/)
oModel:GetModel( 'TXAMASTER' ):SetOnlyQuery(.T.)

//Instancia os Grids para cadastro de ocorrencia

oModel:AddGrid("TXAFUNC","TXAMASTER",oStruTXAF,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,/*bPosValidacao*/,/*bLoadPrd*/)
oModel:AddGrid("TXATURN","TXAMASTER",oStruTXAT,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,/*bPosValidacao*/,/*bLoadPrd*/)
oModel:AddGrid("TXAESC","TXAMASTER",oStruTXAE,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,/*bPosValidacao*/,/*bLoadPrd*/)
oModel:AddGrid("TXAMI","TXAMASTER",oStruTXAMI,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,/*bPosValidacao*/,/*bLoadPrd*/)
oModel:AddGrid("TXAMC","TXAMASTER",oStruTXAMC,/*bLinePre*/,/*bLinePost*/,/*bPreValidacao*/,/*bPosValidacao*/,/*bLoadPrd*/)

//Realiza o relacionamento entre o cabeçalho e os grids Funcionario/Pessoas - Armas - Munições - Coletes
oModel:SetRelation("TXAFUNC",{{"TXA_FILIAL","xFilial('TXA')"},{"TXA_PRODUT","ZXA_PRODUT"},{ "TXA_TPIT", "'"+_TPIP_FUNCAO+"'"}},TXA->(IndexKey(1)))  
oModel:SetRelation("TXATURN",{{"TXA_FILIAL","xFilial('TXA')"},{"TXA_PRODUT","ZXA_PRODUT"},{ "TXA_TPIT", "'"+_TPIP_TURNO+"'"}},TXA->(IndexKey(1)))    
oModel:SetRelation("TXAESC",{{"TXA_FILIAL","xFilial('TXA')"},{"TXA_PRODUT","ZXA_PRODUT"},{ "TXA_TPIT", "'"+_TPIP_ESCALA+"'"}},TXA->(IndexKey(1)))   
oModel:SetRelation("TXAMI",{{"TXA_FILIAL","xFilial('TXA')"},{"TXA_PRODUT","ZXA_PRODUT"},{ "TXA_TPIT", "'"+_TPIP_MATIMPL+"'"}},TXA->(IndexKey(1)))  
oModel:SetRelation("TXAMC",{{"TXA_FILIAL","xFilial('TXA')"},{"TXA_PRODUT","ZXA_PRODUT"},{ "TXA_TPIT", "'"+_TPIP_MATCONS+"'"}},TXA->(IndexKey(1))) 

//Determina a obrigatoriedade de preenchiento dos Grid's
oModel:GetModel('TXAFUNC'):SetOptional(.T.)
oModel:GetModel('TXATURN'):SetOptional(.T.)
oModel:GetModel('TXAESC'):SetOptional(.T.)
oModel:GetModel('TXAMC'):SetOptional(.T.)
oModel:GetModel('TXAMI'):SetOptional(.T.)

//Configura o Grid para não duplicar a linha
oModel:GetModel("TXAFUNC"):SetUniqueLine({ "TXA_FUNCAO" })
oModel:GetModel("TXATURN"):SetUniqueLine({"TXA_TURNO" })
oModel:GetModel("TXAESC"):SetUniqueLine({"TXA_ESCALA" })
oModel:GetModel("TXAMC"):SetUniqueLine({"TXA_PRDMAT" })
oModel:GetModel("TXAMI"):SetUniqueLine({"TXA_PRDMAT" })

//Bloqueia o grid de turno
oModel:GetModel("TXATURN"):SetNoInsertLine(.T.)
oModel:GetModel("TXATURN"):SetNoDeleteLine(.T.)
oModel:GetModel("TXATURN"):SetNoUpdateLine(.T.)

oModel:SetPrimaryKey({})

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
Local oView			:= Nil										// Interface de visualização construída	
Local oModel		:= FWLoadModel("TECA994")				// Cria um objeto de Modelo de dados baseado no ModelDef do fonte informado
Local oStruTXAF		:= FWFormStruct(2,'TXA', {|cCampo|  ( RTrim(cCampo) $ "TXA_FUNCAO;TXA_DFUNC") })		//Item de Função
Local oStruTXAT		:= FWFormStruct(2,'TXA', {|cCampo|  ( RTrim(cCampo) $ "TXA_TURNO;TXA_DTURNO") })		//Item de Turno
Local oStruTXAE		:= FWFormStruct(2,'TXA', {|cCampo|  ( RTrim(cCampo) $ "TXA_ESCALA;TXA_NOMESC") })		//Item de Escala
Local oStruTXAMI 	:= FWFormStruct(2,'TXA', {|cCampo|  ( RTrim(cCampo) $ "TXA_PRDMAT;TXA_DESMAT;TXA_OBRIGA;TXA_QTDE;TXA_TPQTDE")})		//Item de MI
Local oStruTXAMC	:= FWFormStruct(2,'TXA', {|cCampo|  ( RTrim(cCampo) $ "TXA_PRDMAT;TXA_DESMAT;TXA_OBRIGA;TXA_QTDE;TXA_TPQTDE") })		//Item de MC
Local oStruTXAC 	:= FWFormViewStruct():New()
//Local oStruTXAC2 	:= FWFormViewStruct():New()

oView:= FWFormView():New()
oView:SetModel(oModel)

oStruTXAC:AddField( ;
					"ZXA_PRODUT",;				// [01] Campo
					"01",;							// [02] Ordem
					RetTitle("TXA_PRODUT"),;						// [03] Titulo # "Grupo de faturamento"
					RetTitle("TXA_PRODUT"),;						// [04] Descricao # "Grupo de faturamento"
					StrTokArr2(Ap5GetHelp("TXA_PRODUT"),CRLF),;						// [05] Help
					"C",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					GetSx3Cache("TXA_PRODUT","X3_F3"),;						// [09] F3
					.T.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)

oStruTXAC:AddField( ;
					"ZXA_DESCR",;				// [01] Campo
					"02",;							// [02] Ordem
					RetTitle("TXA_DESCR"),;						// [03] Titulo # "Grupo de faturamento"
					RetTitle("TXA_DESCR"),;						// [04] Descricao # "Grupo de faturamento"
					StrTokArr2(Ap5GetHelp("TXA_DESCR"),CRLF),;						// [05] Help
					"G",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					GetSx3Cache("TXA_DESCR","X3_F3"),;						// [09] F3
					.F.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)


oStruTXAC:AddField( ;
					"ZXA_EXFUNC",;				// [01] Campo
					"03",;							// [02] Ordem
					STR0008,;						// [03] Titulo # // "Função"
					STR0008,;						// [04] Descricao # // "Função"
					StrTokArr2(Ap5GetHelp("TXA_EXFUNC"),CRLF),;						// [05] Help
					"C",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					GetSx3Cache("TXA_EXFUNC","X3_F3"),;						// [09] F3
					.T.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)

oStruTXAC:AddField( ;
					"ZXA_EXTUR",;				// [01] Campo
					"04",;							// [02] Ordem
					STR0009,;						// [03] Titulo # "Turno"
					STR0009,;						// [04] Descricao # "Turno"
					StrTokArr2(Ap5GetHelp("TXA_EXTUR"),CRLF),;						// [05] Help
					"C",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					,;						// [09] F3
					.T.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)

oStruTXAC:AddField( ;
					"ZXA_EXESC",;				// [01] Campo
					"05",;							// [02] Ordem
					STR0010,;						// [03] Titulo # "Escala"
					STR0010,;						// [04] Descricao # "Escala"
					StrTokArr2(Ap5GetHelp("TXA_EXESC"),CRLF),;						// [05] Help
					"C",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					,;						// [09] F3
					.T.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)

oStruTXAC:AddField( ;
					"ZXA_EXMC",;				// [01] Campo
					"06",;							// [02] Ordem
					STR0011,;						// [03] Titulo # "Material de Consumo"
					STR0011,;						// [04] Descricao # "Material de Consumo"
					StrTokArr2(Ap5GetHelp("TXA_EXMC"),CRLF),;						// [05] Help
					"C",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					,;						// [09] F3
					.T.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)
					
oStruTXAC:AddField( ;
					"ZXA_EXMI",;				// [01] Campo
					"07",;							// [02] Ordem
					STR0012,;						// [03] Titulo # "Material de Implantacao" 
					STR0012,;						// [04] Descricao # "Material de Implantacao" 
					StrTokArr2(Ap5GetHelp("TXA_EXMI"),CRLF),;						// [05] Help
					"C",;							// [06] Tipo do campo   COMBO, Get ou CHECK
					,;							// [07] Picture
					/*''*/,;						// [08] PictVar
					,;						// [09] F3
					.T.,;							// [10] Editavel
					'',;							// [11] Folder
					/*''*/,;						// [12] Group
					/*{}*/,;						// [13] Lista Combo
					/*10*/,;						// [14] Tam Max CombO
					/*''*/,;						// [15] Inic. Browse
					.F.)

oView:AddField('VIEW_CAB',oStruTXAC,'TXAMASTER')
oView:AddGrid("VIEW_GRID_TXAFUNC",oStruTXAF,"TXAFUNC")
oView:AddGrid("VIEW_GRID_TXATURN",oStruTXAT,"TXATURN")
oView:AddGrid("VIEW_GRID_TXAESC",oStruTXAE,"TXAESC")
oView:AddGrid("VIEW_GRID_TXAMI",oStruTXAMI,"TXAMI")
oView:AddGrid("VIEW_GRID_TXAMC",oStruTXAMC,"TXAMC")

oView:CreateHorizontalBox('SUPERIOR',40)
oView:CreateHorizontalBox('INFERIOR',60)

// Criação da pasta para conter as abas da parte inferior
oView:CreateFolder( "ABAS", "INFERIOR" )
// Criação das Abas
oView:AddSheet( "ABAS", "ABA01", STR0008 )	// "Função"
oView:AddSheet( "ABAS", "ABA02", STR0009 )			// "Turno"
oView:AddSheet( "ABAS", "ABA03", STR0010 )			// "Escala"
oView:AddSheet( "ABAS", "ABA04", STR0011 )			// "Material de Consumo"
oView:AddSheet( "ABAS", "ABA05", STR0012)			// "Material de Implantacao" 

// Criação das áreas de exibição dos dados nas abas
oView:CreateHorizontalBox( "ID_ABA01", 100,,, "ABAS", "ABA01" )
oView:CreateHorizontalBox( "ID_ABA02", 100,,, "ABAS", "ABA02" )
oView:CreateHorizontalBox( "ID_ABA03", 100,,, "ABAS", "ABA03" )
oView:CreateHorizontalBox( "ID_ABA04", 100,,, "ABAS", "ABA04" )
oView:CreateHorizontalBox( "ID_ABA05", 100,,, "ABAS", "ABA05" )

// Relacionando o componente da interface com o componente de dados.
oView:SetOwnerView( 'VIEW_CAB', 'SUPERIOR' )			// Cabeçalho da Movimentação	
oStruTXAC:AddGroup( 'GRP_TECA994_00', "", '', 1 )	
oStruTXAC:AddGroup( 'GRP_TECA994_01', STR0016, '', 2 ) //'Permite Excedente de'
oStruTXAC:SetProperty( "*", MVC_VIEW_GROUP_NUMBER, 'GRP_TECA994_01' )
oStruTXAC:SetProperty( 'ZXA_PRODUT' , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA994_00' )
oStruTXAC:SetProperty( 'ZXA_DESCR' , MVC_VIEW_GROUP_NUMBER, 'GRP_TECA994_00' )
oView:SetOwnerView( 'VIEW_GRID_TXAFUNC', 'ID_ABA01' )	// Grid Destinatários 
oView:SetOwnerView( 'VIEW_GRID_TXATURN', 'ID_ABA02' )	// Grid Armas
oView:SetOwnerView( 'VIEW_GRID_TXAESC', 'ID_ABA03' )	// Grid Munição
oView:SetOwnerView( 'VIEW_GRID_TXAMC', 'ID_ABA04' )	// Grid Coletes
oView:SetOwnerView( 'VIEW_GRID_TXAMI', 'ID_ABA05' )	// Grid Coletes

Return(oView)



//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994Commit

Realiza a gravação do registro de cabelhaçalho dos itens
@author Serviços
@since 15/03/2019
@version P121117

@return lRet, Retorna .T. se houve sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------

Static Function At994Commit(oMldCmm)
Local lRet 			:= .T. //Retorno do Commit
Local nOperation 	:= oMldCmm:GetOperation() //Operacao
Local aAreaTXA 		:= TXA->(GetArea()) //WorkArea
Local oMdl 			:= NIL //Modelo
     
oMdl := oMldCmm:GetModel('TXAMASTER')

cChave := xFilial("TXA")+ oMdl:GetValue("ZXA_PRODUT") + _TPIP_CABEC

TXA->(DbSetOrder(1))

If TXA->(DbSeek(cChave))
	RecLock("TXA", .F.)
Else
	RecLock("TXA", .t.)
	TXA->TXA_FILIAL := xFilial("TXA")
	TXA->TXA_PRODUT := oMdl:GetValue("ZXA_PRODUT")
	TXA->TXA_TPIT := _TPIP_CABEC
EndIf

If   nOperation != MODEL_OPERATION_DELETE
	TXA->TXA_EXFUNC := oMdl:GetValue("ZXA_EXFUNC")
	TXA->TXA_EXTUR := oMdl:GetValue("ZXA_EXTUR")
	TXA->TXA_EXESC := oMdl:GetValue("ZXA_EXESC")
	TXA->TXA_EXMC := oMdl:GetValue("ZXA_EXMC")
	TXA->TXA_EXMI := oMdl:GetValue("ZXA_EXMI")
	
Else
	TXA->(DbDelete())
EndIf

TXA->(MsUnLock())
RestArea(aAreaTXA)

FWFormCommit( oMldCmm )
Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994InitD

Inicialização do Model
@author Serviços
@since 15/03/2019
@version P12117

@return aAux - Dados carregados
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At994InitD ( oMdlGer )

Local aAux := Array(7, .f.) //Array com os campos de retorno
			
aAux[01] := ""
aAux[02] := ""


If oMdlGer:GetOperation() != MODEL_OPERATION_INSERT 
		aAux[01] :=  TXA->TXA_PRODUT
		aAux[02] := GetAdvFVal("SB1","B1_DESC", xFilial("SB1")+TXA->TXA_PRODUT, 1, "")	
		aAux[03] := TXA->TXA_EXFUNC
		aAux[04] := TXA->TXA_EXTUR
		aAux[05] := TXA->TXA_EXESC
		aAux[06] := TXA->TXA_EXMC
		aAux[07] := TXA->TXA_EXMI

EndIf

Return aAux

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994RetVc

Retorna os tipo de vinculo do produto
@author Serviços
@since 15/03/2019
@version P12117

@return cRet - Tipo de Retorno
	"0" - Todos os registros (não localizou a chave)
	"1" - Permite excedente
	"2" - Apenas os vinculos cadastrados
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994RtPrd(cProdRH, cReg, uRet)
Local aAreaTXA 		:= TXA->(GetArea()) 
Local cRet 			:= "0"
Local aCampos 		:= 	{"TXA_EXFUNC", "TXA_EXTUR","TXA_EXESC", "TXA_EXMI", "TXA_EXMC"} 
Local aCamposRet 		:= {"TXA_FUNCAO", "TXA_TURNO","TXA_ESCALA","TXA_PRDMAT", "TXA_PRDMAT"} 
Local cFiltro 		:= ""
Local cQtdReg			:= "0"		

Default cReg := "0"
Default uRet := ""
Default cProdRH := ""

TXA->(DbSetOrder(1)) //TXA_FILIAL + TXA_PRODUT + TXA_TPIT + TXA_FUNCAO + TXA_TURNO + TXA_ESCALA + TXA_PRDMAT

If cReg <> "0" .And. TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_CABEC)) 

	If TXA->(FieldGet(FieldPos(aCampos[Val(cReg)])))
		cRet := "1"
	Else
		cRet := "2"
		//verifica a quantidade de produto configurado
		cQtdReg := At994QtdReg(cProdRH,cReg)
		If cQtdReg  == "1"
			uRet := TXA->(FieldGet(FieldPos(aCamposRet[Val(cReg)])))
		ElseIf cQtdReg == "0" //Não tem produto cadastrado traz tudo
			cRet := "0"
		EndIf		
	EndIf
EndIf

RestArea(aAreaTXA)
Return cRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994RtQtde

Retorna a quantidade do Material
@author Serviços
@since 15/03/2019
@version P12117

@return nRet - Quantidade do Material
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994RtQtde(cProdRH, nQtdRH, nQtdIt,cCampo,;
					cPrdMat, cEscala )
Local aAreaTXA 		:= {}
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local cTpIt 		:= ""
Local nRet 			:= 0
Local cTabela 		:= ""

Default nQtdIt := 0
Default nQtdRH := 0
Default cProdRH := FwFldGet("TFF_PRODUT")
Default cCampo := Substr(ReadVar(), 4)
Default cPrdMat := FwFldGet(cCampo) 
Default cEscala := FwFldGet("TFF_ESCALA")

cTabela := SubStr(cCampo,1,AT("_",cCampo)-1)
nRet := nQtdIt 

If cTabela $ "TFH|TFG"
	aAreaTXA := TXA->(GetArea()) 
	
	If cTabela == "TFH"
		cTpIt := _TPIP_MATCONS
	Else
		cTpIt := _TPIP_MATIMPL
	EndIf
	
	nQtdRH :=  Max(nQtdRH, 1)	
	
	TXA->(DbSetOrder(2)) //TXA_FILIAL + TXA_PRODUT + TXA_TPIT + TXA_PRDMAT
	
	If TXA->(DbSeek(xFilial("TXA")+ cProdRH +cTpIt +  cPrdMat))
	     IF TXA->TXA_TPQTDE  == "1" //Fixa
	     	nRet := TXA->TXA_QTDE
	     ElseIf TXA->TXA_TPQTDE  == "2"
	     	nRet := TXA->TXA_QTDE * nQtdRH
	     ElseIf TXA->TXA_TPQTDE  == "3"
	     	If !Empty(cEscala)
	     		nRet := (GetAdvFVal("TDW", "TDW_QTDPES", xFilial("TDW")+cEscala, 1, 1) * nQtdRH) * TXA->TXA_QTDE
	     	Else
	     		nRet := nQtdRH
	     	EndIf
	     EndIf
	EndIf
	//Testar o caso do campo não ser localizado e ter sido editado pelo usuário
	RestArea(aAreaTXA)  
EndIf      

FWRestRows( aSaveLines )
RestArea(aArea)

Return nRet            

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994RtVic

Retorna o vinculo do produto, caso seja um único
@author Serviços
@since 15/03/2019
@version P12117

@return cRet - Vinculo retornado
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994RtVic(cProdRH, cFieldRet)
Local cRet := ""
Local cTpIt := "0"

Do Case 
Case cFieldRet == "TFF_FUNCAO"
	cTpIt := _TPIP_FUNCAO
Case cFieldRet == "TFF_TURNO"
	cTpIt := _TPIP_TURNO
Case cFieldRet == "TFF_ESCALA"
	cTpIt := _TPIP_ESCALA
Case cFieldRet == "TFH_PRODUT"
	cTpIt := _TPIP_MATCONS
Case cFieldRet == "TFG_PRODUT"
	cTpIt := _TPIP_MATIMPL
EndCase

At994RetVc(cProdRH, cTpIt, @cRet)       

Return cRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994InsMat

Adiciona no Grid os Materiais cadastrados como obrigatórios
@author Serviços
@since 15/03/2019
@version P12117

@return cProdRH - Codigo do Produto RH
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994InsMat(cProdRH,lInsEscala)
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local oModel 		:= NIL
Local oMdlAux		:= Nil
Local oView 		:= Nil
Local aAreaTXA 	:= {}
Local cChave 		:= ""
Local aGrids 		:= {{_TPIP_MATCONS, "TFH_MC", "TFH_PRODUT","TFH_PERINI", "TFH_PERFIM","VIEW_MC"}, ;
				 		{_TPIP_MATIMPL, "TFG_MI", "TFG_PRODUT","TFG_PERINI", "TFG_PERFIM","VIEW_MI"}}
Local dDtIni		:= Ctod("")
Local dDtFim		:= Ctod("")
Local nC 			:= 0
Local lRet			:= .T.
Local nLine		:= 0

Default cProdRH 		:= ""
Default lInsEscala 	:= .F.

If !Empty(cProdRH)
	oModel := FWModelActive() //Modelo Ativo
	oView 		:= FwViewActive()
	If RTrim(oModel:GetId()) ==  "TECA740"
		aAreaTXA := TXA->(GetArea())
	 //Adiciona os itens de MI/MC do Modelo
	 	TXA->(DbSetOrder(1)) //TXA_FILIAL + TXA_PRODUT + TXA_TPIT + TXA_FUNCAO + TXA_TURNO + TXA_ESCALA + TXA_PRDMAT
	 	For nC := 1 to  Len(aGrids)
		 	cChave := xFilial("TXA") + cProdRH + aGrids[nC, 01]
		 	TXA->(DbSeek(cChave))
		 	Do While TXA->(!Eof() .AND.  TXA_FILIAL + TXA_PRODUT + TXA_TPIT  == cChave)
		 		If TXA->TXA_OBRIGA .AND. ;
		 			( (lInsEscala .AND. RTrim(TXA->TXA_TPQTDE)  == "3" ) .OR. TXA->TXA_TPQTDE  != "3")
		 		 	//Adiciona o item no model
		 		 	//Atualiza o campo data inicial/final
		 		 	If Empty(oModel:GetValue("TFF_RH", "TFF_PERINI"))
		 		 		lRet := oModel:SetValue("TFF_RH", "TFF_PERINI", oModel:GetValue("TFL_LOC","TFL_DTINI")  )
		 		 	EndIf
		 		 	
		 		 	dDtIni := oModel:GetValue("TFF_RH", "TFF_PERINI")
		 		 	
		 		 	If lRet .And. Empty(oModel:GetValue("TFF_RH", "TFF_PERFIM"))
		 		 		lRet := oModel:SetValue("TFF_RH", "TFF_PERFIM", oModel:GetValue("TFL_LOC","TFL_DTFIM")  )
		 		 	EndIf
		 		 	
		 		 	dDtFim := oModel:GetValue("TFF_RH", "TFF_PERFIM")
		 		 	
		 		 	
		 		 	If !oModel:GetModel(aGrids[nC, 02]):IsEmpty() .AND. ;
		 		 		!Empty(oModel:GetValue(aGrids[nC, 02], aGrids[nC, 03])) .AND.;
		 		 		!oModel:GetModel(aGrids[nC, 02]):SeekLine({{aGrids[nC, 03], TXA->TXA_PRDMAT}}) 
		 		 		
		 		 		nLine := oModel:GetModel(aGrids[nC, 02]):AddLine()		 		 		
		 		 		oModel:GetModel(aGrids[nC, 02]):GoLine(nLine)
		 		 	EndIf		 		 	

		 		 	lRet := oModel:GetModel(aGrids[nC, 02]):SetValue(aGrids[nC, 03], TXA->TXA_PRDMAT)
		 		 	
		 		 	If lRet .And. Empty(oModel:GetValue(aGrids[nC, 02], aGrids[nC, 04]))
		 		 		lRet := oModel:GetModel(aGrids[nC, 02]):SetValue(aGrids[nC, 04], dDtIni)
		 		 	EndIf
		 		 	
		 		 	If lRet .And. Empty(oModel:GetValue(aGrids[nC, 02],aGrids[nC, 05]))
		 		 		oModel:GetModel(aGrids[nC, 02]):SetValue(aGrids[nC, 05], dDtFim)
		 		 	EndIf
		 		 	
		 		 	If oView:IsActive()
						oView:Refresh(aGrids[nC, 06])//Atualiza grid para que seja apresentado os valores alterados	
					Endif
		 		 	
		 		EndIf
		 		TXA->(DbSkip(1))
		 	EndDo
	 	Next nC
	 	RestArea(aAreaTXA)
	EndIf
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)

Return cProdRH

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994RcQtd

Recalcula a quantidade do Material após a alteração da quantidade do produto
@author Serviços
@since 15/03/2019
@version P12117
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At994RcQtd(oMdlFull, nQtdRH, cEscala)
Local cProdRH := ""
Local aGrids := {{_TPIP_MATCONS, "TFH_MC", "TFH_PRODUT", "TFH_QTDVEN"}, ;
				 {_TPIP_MATIMPL, "TFG_MI", "TFG_PRODUT", "TFG_QTDVEN"}}

Local aAreaTXA := {}
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local nC := 0
Local nY := 0
Local nQtd := 0
Local nQtdIt := 0
Local cPrdMat := ""

cProdRH := oMdlFull:GetValue("TFF_RH", "TFF_PRODUT")

If !Empty(cProdRH) .and. nQtdRH > 0
 	For nC := 1 to  Len(aGrids)
 	
 		If !oMdlFull:GetModel(aGrids[nC, 02]):IsEmpty()
		 	For nY := 1 to oMdlFull:GetModel(aGrids[nC, 02]):Length()
		 		oMdlFull:GetModel(aGrids[nC, 02]):GoLine(nY)
		 		If !oMdlFull:GetModel(aGrids[nC, 02]):IsDeleted()
		 		
				 	nQtdIt := oMdlFull:GetValue(aGrids[nC, 02], aGrids[nC, 04])
				 	cPrdMat := oMdlFull:GetValue(aGrids[nC, 02], aGrids[nC, 03])
				 	
				 	nQtd :=  At994RtQtde(cProdRH, nQtdRH, nQtdIt,aGrids[nC, 03], ;
				 						cPrdMat, cEscala  )
				 	
				 	If nQtdIt <> nQtd
				 		oMdlFull:SetValue(aGrids[nC, 02], aGrids[nC, 04], nQtd)
				 	EndIf
	
			 	EndIf
		 	Next NY
	 	EndIf
 	Next nC	
EndIf

FWRestRows( aSaveLines )
RestArea(aArea)

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994RcQtd

Apaga os materias que estão vinculados ao produto
@author Serviços
@since 15/03/2019
@version P12117
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At994DlIt(oMdlFull, cProdRH)
Local aGrids := {{_TPIP_MATCONS, "TFH_MC", "TFH_PRODUT"}, ;
				 {_TPIP_MATIMPL, "TFG_MI", "TFG_PRODUT"}}

Local aAreaTXA 	:= {}
Local nC 		:= 0
Local nY 		:= 0
Local nQtd 		:= 0
Local nQtdIt 	:= 0
Local cPrdMat 	:= ""
Local cTpRet 	:= ""
Local cTpRetNw  := "" //Novo tipo de Retorno

If !Empty(cProdRH)
 	For nC := 1 to  Len(aGrids)
	 	cTpRet := At994RetVc(cProdRH, aGrids[nC, 01])
	 	cTpRetNw := At994RetVc(oMdlFull:GetValue("TFF_RH", "TFF_PRODUT"),  aGrids[nC, 01])
	 	If cTpRetNw == "2" //Novo vínculo permite apenas os produtos cadastrados
	 		If !oMdlFull:GetModel(aGrids[nC, 02]):IsEmpty()
	 		 	For nY := 1 to oMdlFull:GetModel(aGrids[nC, 02]):Length()
			 		oMdlFull:GetModel(aGrids[nC, 02]):GoLine(nY)
			 		If !oMdlFull:GetModel(aGrids[nC, 02]):IsDeleted() .and. !Empty(oMdlFull:GetValue(aGrids[nC, 02], aGrids[nC, 03]))
			 			oMdlFull:GetModel(aGrids[nC, 02]):DeleteLine()	
				 	EndIf
			 	Next NY
		 	EndIf
		 EndIf
 	Next nC	
EndIf

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994VlObr

Valida os campos TES e Preço de Venda do Material cadastrado como Obrigatório
@author Serviços
@since 15/03/2019
@version P12117
@retunr lRet - Campos cadastrados
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994VlObr(cProdMat, lObrig, oModel)
Local lRet 			:= .T.
Local aRet 			:= {}

//Ponto de Entrada para inclusão de botoes na interface
If (ExistBlock( "AT994VLOBR" ))
	lRet := ExecBlock( "AT994VLOBR", .F., .F., {cProdMat,lObrig, oModel} )
	If ValType(lRet) != "L"
		lRet := .T.
	EndIf

Else
	If !Empty(cProdMat) .AND. lObrig
		
		aRet := GetAdvFVal("SB1", {"B1_TS", "B1_PRV1"}, xFilial("SB1")+cProdMat, 1, {"", ""} )
		If Empty(aRet[01]) .OR. Empty(aRet[02])
			lRet := .F.
			Help("",1, STR0013, , STR0014, 1, )//"Atenção"###"Para cadastrar material como obrigatório é necessário que os campos TES de Saída e Preço de Venda estejam cadastrados no produto"
		EndIf
	EndIf	
EndIf

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994VlObr

Valida se ao menos uma configuração de vínculo for informada
@author Serviços
@since 15/03/2019
@version P12117
@retunr lRet - Campos cadastrados
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994PosVld(oModel)
Local lRet := .F.

If oModel:GetValue("TXAMASTER", "ZXA_EXFUNC") .OR. !oModel:GetModel("TXAFUNC"):IsEmpty()
	lRet := .T.
ElseIf oModel:GetValue("TXAMASTER", "ZXA_EXTUR") .OR. !oModel:GetModel("TXATURN"):IsEmpty()
	lRet := .T.
ElseIf oModel:GetValue("TXAMASTER", "ZXA_EXESC") .OR. !oModel:GetModel("TXAESC"):IsEmpty()
	lRet := .T.
ElseIf oModel:GetValue("TXAMASTER", "ZXA_EXMI") .OR. !oModel:GetModel("TXAMI"):IsEmpty()
	lRet := .T.
ElseIf oModel:GetValue("TXAMASTER", "ZXA_EXMC") .OR. !oModel:GetModel("TXAMC"):IsEmpty()
	lRet := .T.
EndIf

If !lRet
	Help("",1, STR0013, , STR0015, 1, )//"Atenção"##"Defina ao menos uma configuração de vínculo para o Produto"
EndIf

Return lRet


/*nCampo := 1 = Função
  nCampo := 2 = Escala
  nCampo := 3 = Turno
*/
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994InsRH

Verifica se o produto tem execendete ou não
@author Serviços
@since 15/03/2019
@version P12117
@return .t.
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994InsRH(cProdRH,cCod,nCampo)
Local lRet 		:= .T.
Local aAreaTXA 	:= TXA->(GetArea())
Local cFuncVazio 	:= Space(TamSX3("TXA_FUNCAO")[1]) 	//Código da Função
Local cTurnVazio 	:= Space(TamSX3("TXA_TURNO")[1]) 	//Turno Vazio
Local cEscVazio 	:= Space(TamSX3("TXA_ESCALA")[1]) 	//Turno Vazio

TXA->(DbSetOrder(1)) //TXA_FILIAL + TXA_PRODUT + TXA_TPIT + TXA_FUNCAO + TXA_TURNO + TXA_ESCALA + TXA_PRDMAT

If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_CABEC)) 
	
	Do Case
		Case nCampo == 1 //Função	
		
			If TXA->TXA_EXFUNC
				lRet := .T.
			Else
				If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_FUNCAO + cCod))
					lRet := .T.
				Else
					lRet := .F.
				EndIf 	
			EndIf
		Case nCampo == 2 //Escala
		
			If TXA->TXA_EXESC
				lRet := .T.
			Else
				If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_ESCALA + cFuncVazio + cTurnVazio + cCod))
					lRet := .T.
				Else
					lRet := .F.
				EndIf 	
			EndIf
		Case nCampo == 3 //Turno
		
			If TXA->TXA_EXTUR
				lRet := .T.
			Else
				If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_TURNO + cFuncVazio + cCod))
					lRet := .T.
				Else
					lRet := .F.
				EndIf 
			EndIf
		Case nCampo == 4 //Mat Implantacao
		
			If TXA->TXA_EXMI
				lRet := .T.
			Else
				If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_MATIMPL + cFuncVazio + cTurnVazio + cEscVazio + cCod))
					lRet := .T.
				Else
					lRet := .F.
				EndIf 
			EndIf
		Case nCampo == 5 //Mat Consumo
		
			If TXA->TXA_EXMC
				lRet := .T.
			Else
				If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_MATCONS + cFuncVazio + cTurnVazio + cEscVazio + cCod))
					lRet := .T.
				Else
					lRet := .F.
				EndIf 
			EndIf	
	End Case

EndIf


RestArea(aAreaTXA)

Return(lRet)

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994QtdReg

Verifica a quantidade de registros cadastrados no vinculo o produto possui
@author Serviços
@since 15/03/2019
@version P12117
@return .t.
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At994QtdReg(cProdRH, cReg)
Local tmpVinc	:= GetNextAlias()

BeginSql Alias tmpVinc
	SELECT count(*) as regTXA
	FROM %table:TXA% TXA
		WHERE	TXA.TXA_FILIAL = %xFilial:TXA%
			AND TXA.TXA_PRODUT  = %Exp:cProdRH%
			AND TXA.TXA_TPIT = %Exp:cReg%
			AND TXA.%NotDel%
EndSql

DbSelectArea(tmpVinc)
If (tmpVinc)->regTXA > 0 //existe vinculo
	If (tmpVinc)->regTXA == 1
		cReg := "1" //informa que só tem um registro
	Else
		cReg := "2" 
	EndIf
Else
	cReg := "0"	
Endif

Return cReg

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At994RetVc

Retorna os tipo de vinculo do produto
@author Serviços
@since 15/03/2019
@version P12117

@return cRet - Tipo de Retorno
	"0" - Todos os registros (não localizou a chave)
	"1" - Permite excedente
	"2" - Apenas os vinculos cadastrados
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At994RetVc(cProdRH, cReg, uRet)
Local aAreaTXA 		:= TXA->(GetArea()) 
Local cRet 			:= "0"
Local aCampos 		:= 	{"TXA_EXFUNC", "TXA_EXTUR","TXA_EXESC", "TXA_EXMI", "TXA_EXMC"} 
Local aCamposRet 	:= {"TXA_FUNCAO", "TXA_TURNO","TXA_ESCALA","TXA_PRDMAT", "TXA_PRDMAT"} 
Local cFiltro 		:= ""
Local nTotReg 		:= 0


Default cReg := "0"
Default uRet := ""
Default cProdRH := ""

cFiltro := "TXA_FILIAL = '" + xFilial("TXA") +  "' .AND. TXA_PRODUT = '" + cProdRH + "' .AND. TXA_TPIT = '" + cReg + "'" 
TXA->(DbSetOrder(1)) //TXA_FILIAL + TXA_PRODUT + TXA_TPIT + TXA_FUNCAO + TXA_TURNO + TXA_ESCALA + TXA_PRDMAT

If TXA->(DbSeek(xFilial("TXA")+ cProdRH + _TPIP_CABEC)) 
	TXA->(DbSetFilter({|| &cFiltro}, cFiltro))
	TXA->(DbGoTop())
	
	TXA->(DbEval({|| nTotReg := nTotReg + 1	 }))

	If TXA->(FieldGet(FieldPos(aCampos[Val(cReg)]))) 
		cRet := "1"
	ElseIf nTotReg > 0
		cRet := "2"
	EndIf
	
	If nTotReg  == 1
		TXA->(DbGoTop())
		uRet := TXA->(FieldGet(FieldPos(aCamposRet[Val(cReg)])))
	EndIf

	TXA->(DBClearFilter())
EndIf


RestArea(aAreaTXA)
Return cRet