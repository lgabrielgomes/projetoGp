#INCLUDE "TECA336.CH"
#INCLUDE "PROTHEUS.CH" 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "MOVIMENTACAO.CH"

#DEFINE POS_IDCFAL     15

Static lChkWhen     	:= .T.      // Essa variável é setada como falso quando é feita o model é instanciado e alimentado sem uma interface.
Static lResetSitAt  	:= .T.      // Indica se a variável que guarda a situação do atendente será resetada. Isso é util quando é feito um execauto do TECA336 dentro do próprio TECA336.
Static lTrocaEfet   	:= .F.      // Indica quando o método de gravação do model oMdlTrocaEfet é chamado, impedindo um loop infinito.
Static cAliasABB    	:= ""       // Alias temporário usado para carregar as agendas.
Static cSitAtend    	:= ""       // Situação atual do atendente. Essa situação é obtida no TECA335 e repassada para o TECA336.
Static cMovAtend		:= ""		// Movimentação atual do atendente.
Static cFilAtd      	:= ""       // Filial do atendente
Static dDataRef     	:= Ctod("") // Data passada pelo TECA335 
Static aPerfAloc    	:= {}       // Array com as opções de perfil de alocação
Static cHrIniCob    	:= ""       // Horário inicial de cobertura. Essa variável é chamada no TECA550, através do At336IniCob().
Static cTpMovCob    	:= ""       // Tipo de motivo de cobertura. Essa variável é chamada no TECA550, através do At336TpCob().
Static cListDia	 		:= ''       // Ponto de entrada para Dobra de Reforço Diario
Static cListFT	 		:= ''       // Ponto de entrada para FT (Folga trabalhada)
Static cListCob	 		:= ''       // Ponto de entrada para Cobertura 
Static cListCanFT 		:= ''       // Ponto de entrada para Cancelamento de Folga Trabalhada 
Static cListCanCB 		:= ''       // Ponto de entrada para Cancelamento de Cobertura 
Static cListCanHE		:= ''		// Ponto de entrada para Cancelamento de Hora Extra
Static cListHE	 		:= ''       // Ponto de entrada para HE (Hora extra)
Static aInfoRes			:= {}		// Informações da reserva.
Static lTrocaOk			:= .F.		// Verifica se a troca de efetivos foi realizada com sucesso.
Static lLibSit			:= .T.
Static lRecolheOk		:= .F.		//Permite o recolhimento.
Static lWhenHora		:= .F.	   	//Habilita os campos de manipulação de horas
Static aAgendRes		:= {}		//Caso precise alterar a hora final da agenda de reserva sem cancelar a agenda.
// Modelos de Dados
Static oMdlTrocaEfet	:= Nil    // Modelo de dados utilizado somente para a troca de efetivos.

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA336()
Função principal do Movimentar.

@param		Nenhum
@author		Leandro Dourado
@since		28/09/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function TECA336( oMdl335 )

Local aRows       := FwSaveRows()
Local cFil        := oMdl335:GetValue("CAB_ATEND","AA1_FILIAL")
Local cCodAtend   := oMdl335:GetValue("CAB_ATEND","AA1_CODTEC")
Local dDataMov    := oMdl335:GetValue("CAB_ATEND","TDV_DTREF")
Local cSitTec     := AllTrim(oMdl335:GetValue("CAB_ATEND","AA1_SITTEC"))
Local cTipoMv     := ""
Local oMdlABB     := oMdl335:GetModel("ITE_ABB")
Local lMovimenta  := .T.
Local lEscFil     := .F. // Indica se será exibida a tela para selecionar a filial da movimentação.
Local cFilName    := AllTrim(FWFilialName(cEmpAnt,cFilAnt))
Local cFilAgenda  := ""
Local aSM0        := {}
Local aAllSM0     := FwLoadSM0()
Local nX          := 0
Local nSelecao    := 0
Local nPosSM0     := 0
Local aButtons    := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,STR0012},{.T.,STR0013},; //"Confirmar"###"Fechar"
		           {.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}}
Local cFilBkp		:= cFilAnt

oMdlABB:Goline(1)
cTipoMv := AllTrim(oMdlABB:GetValue("ABB_TIPOMV"))

// Limpa as funções dos botões F5 e F6, para evitar erros que seriam causados caso essas teclas fossem apertadas.		           
SetKey( VK_F6, Nil )	           

If !Empty(cFil) .AND. !Empty(cCodAtend) .AND. !Empty(dDataMov) .AND. !Empty(cSitTec)

	cSitAtend := AllTrim(cSitTec)
	cMovAtend := AllTrim(cTipoMv)
	//Comentamos o PE AT336LST, pq esta gerando erro no recolhimento de atendente.
	lLibSit	  	:= .F. //IIF(ExistBlock("AT336LST") , ExecBlock("AT336LST",.F.,.F.,{cFilAnt,cCodAtend,dDataMov,cSitAtend}), .F. )
	cListFT	  	:= IIF(ExistBlock("AT336FT")  , ExecBlock("AT336FT"	,.F.,.F.,{}), '' )
	cListCanFT	:= IIF(ExistBlock("AT336CFT") , ExecBlock("AT336CFT",.F.,.F.,{}), '' )
	cListHE	  	:= IIF(ExistBlock("AT336HE")  , ExecBlock("AT336HE"	,.F.,.F.,{}), '' )	
	cListCanHE	:= IIF(ExistBlock("AT336CHE") , ExecBlock("AT336CHE",.F.,.F.,{}), '' )	
	cListCob  	:= IIF(ExistBlock("AT336COB") , ExecBlock("AT336COB",.F.,.F.,{}), '' )	
	cListCanCB	:= IIF(ExistBlock("AT336CCB") , ExecBlock("AT336CCB",.F.,.F.,{}), '' )
	cListDia  	:= IIF(ExistBlock("AT336DIA") , ExecBlock("AT336DIA",.F.,.F.,{}), '' )		
	
	// Este case faz algumas validações antes de exibir a tela do Movimentar.
	Do Case
	
	Case ((Upper(cSitAtend) $ Upper(SIT_ATEND_DEMISSAO) + '|' + Upper(SIT_ATEND_AFASTA) + '|' + Upper(SIT_ATEND_SUSPENSAO) + '|' + Upper(SIT_ATEND_FERIAS)) .Or. Upper(cSitAtend) == Upper(SIT_ATEND_FALTAFIXA) ) .And. !lLibSit
		Help("",1,"TECA336",,STR0014+Lower(AllTrim(cSitTec))+STR0015,2,0) //"Esse atendente está em situação de "###" e não poderá ser movimentado!"
		lMovimenta := .F.
	
	Case (AllTrim(Upper(cSitTec)) == Upper(SIT_ATEND_SEMAGENDA))
		Help("",1,"TECA336",,STR0081,2,0) //"Esse atendente está alocado porém sua agenda desse dia não foi gerada. Execute o programa de alocações diárias para poder movimentar esse atendente!"
		lMovimenta := .F.
	
	Case oMdlABB:SeekLine({{"ABB_ATENDE","1"}, {"ABB_CHEGOU","S"}})
        Help("",1,"TECA336",,STR0130,2,0) //"A agenda deste dia já foi atendida e não pode sofrer manutenção."
        lMovimenta := .F.
    
	
	Case oMdlABB:SeekLine({{"ABB_ATIVO","1"}})
		
		For nX := 1 To oMdlABB:Length()
			oMdlABB:GoLine(nX)
			
			If oMdlABB:GetValue("ABB_ATIVO") == "1" .AND. aScan(aSM0,{|x| AllTrim(x[1]) == AllTrim(oMdlABB:GetValue("ABB_CODFIL"))}) == 0
				Aadd(aSM0,{AllTrim(oMdlABB:GetValue("ABB_CODFIL")),AllTrim(oMdlABB:GetValue("ABB_NOMEFIL"))})
				
				If AllTrim(oMdlABB:GetValue("ABB_CODFIL")) <> xFilial("ABB",cFilAnt)
					lEscFil := .T.
				EndIf
			EndIf
			
		Next nX
		
		oMdlABB:GoLine(1)
		
		If lEscFil
			If Len(aSM0) == 1
				If MsgYesNo(STR0082 + AllTrim(aSM0[1,1]) + ':' + AllTrim(aSM0[1,2]) + "." + CRLF + STR0083,STR0037) //"Esse atendente possui agenda(s) apenas na filial " ### "Deseja trocar a filial da movimentação?" ###"Atenção!"
					lMovimenta := .T.
					cFilAnt := aSM0[1,1]
				Else
					lMovimenta := .F.
					Help("",1,"TECA336",,STR0084,2,0) //"Atendente não encontrado na filial informada!"
				EndIf
			Else
				nSelecao := TmsF3Array({STR0085,STR0086}, aSM0, STR0087 ) //"Codigo Filial" ### "Nome Filial" ### "Filiais de Agenda"
				
				If nSelecao > 0
					If aSM0[nSelecao,1] <> cFilAnt
						cFilAnt := aSM0[nSelecao,1]
					EndIf
					lMovimenta := .T.
				Else
					lMovimenta := .F.
				EndIf
			EndIf
		ElseIf Len(aSM0) > 0
			lMovimenta := .T.
		Else
			lMovimenta := .F.
		EndIf
		
	OtherWise
		lMovimenta := .T.
		
	EndCase
	
	If lLibSit
		lMovimenta := lLibSit
	EndIf	
	
	If lMovimenta
		cFilAtd   := cFil
		dDataRef  := dDataMov
		
		DbSelectArea("AA1")
		AA1->(DbSetOrder(1)) //AA1_FILIAL+AA1_CODTEC
		If AA1->(DbSeek(FwxFilial("AA1",cFilAtd)+cCodAtend))
			If !IsInCallStack('TEC335CSV')
				FWExecView(STR0016,"VIEWDEF.TECA336",MODEL_OPERATION_INSERT,,,,,aButtons) // "Movimentar"
				cFilAnt := cFilBkp
			EndIf
		Else
			Help("",1,"TECA336",,STR0017,2,0)      //"Atendente não encontrado na filial informada!"
		EndIf
	EndIf
Else
	Help("",1,"TECA336",,STR0018,2,0) //"Confirme o preenchimento da data de referência, da filial e do código do atendente antes de utilizar essa opção!"
EndIf

// Preenche novamente a função F6 para ser utilizada no TECA335.
SetKey(VK_F6, {|| TECA336(FwModelActive()), At335AgCar() })

FwRestRows( aRows )

Return Nil

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de dados.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Static Function ModelDef()

Local cCpoView := ""
Local oStruTW3 := FWFormStruct( 1, 'TW3' )
Local oStruABB := FWFormStruct( 1, 'ABB',{|cCampo|  AtCamposABB(cCampo,.T.,@cCpoView)})
Local bPosVld  := {|oModel|At336PosVld(oModel)}
Local bCommit  := {|oModel|At336Grava(oModel)}
Local bCancel  := {|oModel|At336Cancel(oModel)}
Local oModel   := MpFormModel():New( 'TECA336',/*Pre-Validacao*/,bPosVld,bCommit,bCancel )
Local aCpoABB  := StrTokArr(cCpoView, "|" )
Local nX       := 0
Local aAux     := {}
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.) 

oStruTW3:AddField(	STR0019      ,; 	// [01] Titulo do campo   "Usa Função?"
					STR0019      ,;		// [02] ToolTip do campo  "Usa Função?"
					"TW3_USAFUN" ,; 	// [03] Id do Field
					"C"          ,;  	// [04] Tipo do campo
					1            ,; 	// [05] Tamanho do campo
					0            ,; 	// [06] Decimal do campo
					Nil          ,; 	// [07] Code-block de validação do campo
					Nil          ,; 	// [08] Code-block de validação When do campo
					Nil          ,; 	// [09] Lista de valores permitido do campo
					.F.          ,; 	// [10] Indica se o campo tem preenchimento obrigatório
					nIL          ,; 	// [11] Folder
					.F.          ,; 	// [12] Indica se trata-se de um campo chave
					.T.          ,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          ,; 	// [14] Indica se o campo é virtual
					Nil           )  	// [15] Valid do usuario

oStruTW3:AddField(	STR0020      ,; 	// [01] Titulo do campo      "Usa Cargo?"
					STR0020      ,;		// [02] ToolTip do campo     "Usa Cargo?"
					"TW3_USACGO" ,; 	// [03] Id do Field
					"C"          ,;  	// [04] Tipo do campo
					1            ,; 	// [05] Tamanho do campo
					0            ,; 	// [06] Decimal do campo
					Nil          ,; 	// [07] Code-block de validação do campo
					Nil          ,; 	// [08] Code-block de validação When do campo
					Nil          ,; 	// [09] Lista de valores permitido do campo
					.F.          ,; 	// [10] Indica se o campo tem preenchimento obrigatório
					nIL          ,; 	// [11] Folder
					.F.          ,; 	// [12] Indica se trata-se de um campo chave
					.T.          ,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          ,; 	// [14] Indica se o campo é virtual
					Nil           )  	// [15] Valid do usuario					

oStruTW3:AddField(	STR0021      ,; 	// [01] Titulo do campo     "Usa Turno?"
					STR0021      ,;		// [02] ToolTip do campo    "Usa Turno?"
					"TW3_USATUR" ,; 	// [03] Id do Field
					"C"          ,;  	// [04] Tipo do campo
					1            ,; 	// [05] Tamanho do campo
					0            ,; 	// [06] Decimal do campo
					Nil          ,; 	// [07] Code-block de validação do campo
					Nil          ,; 	// [08] Code-block de validação When do campo
					Nil          ,; 	// [09] Lista de valores permitido do campo
					.F.          ,; 	// [10] Indica se o campo tem preenchimento obrigatório
					nIL          ,; 	// [11] Folder
					.F.          ,; 	// [12] Indica se trata-se de um campo chave
					.T.          ,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          ,; 	// [14] Indica se o campo é virtual
					Nil           )  	// [15] Valid do usuario

oStruTW3:AddField(	STR0022      ,; 	// [01] Titulo do campo     "Usa Sequencia?"
					STR0022      ,;	    // [02] ToolTip do campo    "Usa Sequencia?"
					"TW3_USASEQ" ,; 	// [03] Id do Field
					"C"          ,;  	// [04] Tipo do campo
					1            ,; 	// [05] Tamanho do campo
					0            ,; 	// [06] Decimal do campo
					Nil          ,; 	// [07] Code-block de validação do campo
					Nil          ,; 	// [08] Code-block de validação When do campo
					Nil          ,; 	// [09] Lista de valores permitido do campo
					.F.          ,; 	// [10] Indica se o campo tem preenchimento obrigatório
					nIL          ,; 	// [11] Folder
					.F.          ,; 	// [12] Indica se trata-se de um campo chave
					.T.          ,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          ,; 	// [14] Indica se o campo é virtual
					Nil           )  	// [15] Valid do usuario

oStruTW3:AddField(	"TW3_IDCFAL" ,; 	// [01] Titulo do campo     
					"TW3_IDCFAL" ,;	    // [02] ToolTip do campo    
					"TW3_IDCFAL" ,; 	// [03] Id do Field
					"C"          ,;  	// [04] Tipo do campo
					TamSX3("ABB_IDCFAL")[1]            ,; 	// [05] Tamanho do campo
					0            ,; 	// [06] Decimal do campo
					Nil          ,; 	// [07] Code-block de validação do campo
					Nil          ,; 	// [08] Code-block de validação When do campo
					Nil          ,; 	// [09] Lista de valores permitido do campo
					.F.          ,; 	// [10] Indica se o campo tem preenchimento obrigatório
					nIL          ,; 	// [11] Folder
					.F.          ,; 	// [12] Indica se trata-se de um campo chave
					.T.          ,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          ,; 	// [14] Indica se o campo é virtual
					Nil           )  	// [15] Valid do usuario

oStruTW3:AddField(	"TW3_RESERV" ,; 	// [01] Titulo do campo     
					"TW3_RESERV" ,;	    // [02] ToolTip do campo    
					"TW3_RESERV" ,; 	// [03] Id do Field
					"C"          ,;  	// [04] Tipo do campo
					1            ,; 	// [05] Tamanho do campo
					0            ,; 	// [06] Decimal do campo
					Nil          ,; 	// [07] Code-block de validação do campo
					Nil          ,; 	// [08] Code-block de validação When do campo
					Nil          ,; 	// [09] Lista de valores permitido do campo
					.F.          ,; 	// [10] Indica se o campo tem preenchimento obrigatório
					Nil          ,; 	// [11] Folder
					.F.          ,; 	// [12] Indica se trata-se de um campo chave
					.T.          ,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          ,; 	// [14] Indica se o campo é virtual
					Nil           )  	// [15] Valid do usuario

oStruTW3:AddField(	"Efetivo?" 	 						,; 		// [01] Titulo do campo     
					"Efetivo?" 	 						,;    	// [02] ToolTip do campo    
					"TW3_EFETIV" 						,; 		// [03] Id do Field
					"C"          						,;  	// [04] Tipo do campo
					1            						,; 		// [05] Tamanho do campo
					0            						,; 		// [06] Decimal do campo
					{|| .T. }								,; 		// [07] Code-block de validação do campo
					{|| At335when("TW3_EFETIV")}		,; 		// [08] Code-block de validação When do campo
					Nil									,; 		// [09] Lista de valores permitido do campo
					.F.          						,; 		// [10] Indica se o campo tem preenchimento obrigatório
					{|| "1" }							,;		// [11] Code-block de inicializacao do campo
					.F.          						,; 		// [12] Indica se trata-se de um campo chave
					.T.          						,; 		// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          						,; 		// [14] Indica se o campo é virtual
					Nil           						)  		// [15] Valid do usuario
			
					
oStruABB:AddField(	STR0165 				,; 	// [01] Titulo do campo  //"Tot. Hr. Extra"
					STR0165					,;  // [02] ToolTip do campo //"Tot. Hr. Extra"
					"ABB_HEXTOT" 			,; 	// [03] Id do Field
					"C"          			,;	// [04] Tipo do campo
					TamSX3("ABR_TEMPO")[1]  ,; 	// [05] Tamanho do campo
					0   					,; 	// [06] Decimal do campo
					Nil          			,; 	// [07] Code-block de validação do campo
					Nil          			,; 	// [08] Code-block de validação When do campo
					Nil          			,; 	// [09] Lista de valores permitido do campo
					.F.          			,; 	// [10] Indica se o campo tem preenchimento obrigatório
					Nil          			,; 	// [11] Folder
					.F.          			,; 	// [12] Indica se trata-se de um campo chave
					.T.          			,; 	// [13] Indica se o campo pode receber valor em uma operação de update.
					.T.          			,; 	// [14] Indica se o campo é virtual
					Nil           			)  	// [15] Valid do usuario

aAux := FwStruTrigger("TW3_SITCOD","TW3_EFETIV","At336GtEft()",.F.,Nil,Nil,Nil)
oStruTW3:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

If lMV_GSGEHOR

	oStruTW3:AddField(STR0166,STR0166,"TW3_ENTRA1","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_ENTRA1") .And. At580eWhen("1")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Entrada 1" # "Entrada 1"
	oStruTW3:AddField(STR0167,STR0167,"TW3_SAIDA1","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_SAIDA1") .And. At580eWhen("1")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Saida 1" #"Saida 1"
	
	oStruTW3:AddField(STR0168,STR0168,"TW3_ENTRA2","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_ENTRA2") .And. At580eWhen("2")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Entrada 2" # "Entrada 2"
	oStruTW3:AddField(STR0169,STR0169,"TW3_SAIDA2","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_SAIDA2") .And. At580eWhen("2")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Saida 2" #"Saida 2"
	
	oStruTW3:AddField(STR0170,STR0170,"TW3_ENTRA3","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_ENTRA3") .And. At580eWhen("3")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Entrada 3" # "Entrada 3"
	oStruTW3:AddField(STR0171,STR0172,"TW3_SAIDA3","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_SAIDA3") .And. At580eWhen("3")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Saida 3" #"Saida 3"
	
	oStruTW3:AddField(STR0173,STR0173,"TW3_ENTRA4","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_ENTRA4") .And. At580eWhen("4")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Entrada 4" # "Entrada 4"
	oStruTW3:AddField(STR0174,STR0174,"TW3_SAIDA4","C",5,0,{|a,b,c,d|At336VldHr(a,b,c,d)},{|| At335when("TW3_SAIDA4") .And. At580eWhen("4")}, /*aValues*/,.F.,/*bInit*/,/*lKey*/,/*lNoUpd*/,.T./*lVirtual*/,/*cValid*/) //"Saida 4" #"Saida 4"

	aAux := FwStruTrigger("TW3_TRSQES","TW3_TRSQES","At336GatHr()",.F.,Nil,Nil,Nil)
	oStruTW3:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

EndIf

aAux := FwStruTrigger("ABB_DTINI","ABB_MANUT","'1'",.F.,Nil,Nil,Nil)
oStruABB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABB_HRINI","ABB_MANUT","'1'",.F.,Nil,Nil,Nil)
oStruABB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABB_DTFIM","ABB_MANUT","'1'",.F.,Nil,Nil,Nil)
oStruABB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABB_HRFIM","ABB_MANUT","'1'",.F.,Nil,Nil,Nil)
oStruABB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

//Gatiha o total de horas extras inseridas na tela.
aAux := FwStruTrigger("ABB_HRINI","ABB_HEXTOT",'At336TtExt(FwFldGet("ABB_CODTEC"), FwFldGet("ABB_CODTFF"), FwFldGet("ABB_LOCAL"), FwFldGet("TW3_DTMOV"),FwFldGet("TW3_SITCOD"))',.F.,Nil,Nil,Nil)
oStruABB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

aAux := FwStruTrigger("ABB_HRFIM","ABB_HEXTOT",'At336TtExt(FwFldGet("ABB_CODTEC"), FwFldGet("ABB_CODTFF"), FwFldGet("ABB_LOCAL"), FwFldGet("TW3_DTMOV"),FwFldGet("TW3_SITCOD"))',.F.,Nil,Nil,Nil)
oStruABB:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

oModel:AddFields( "TW3MASTER", /*cOwner*/ , oStruTW3, /*bPreValidacao*/, {|oMdlTW3| At336ePosV(oMdlTW3,"TW3")} /*bPosValidacao*/, /*bCarga*/ )

oModel:AddGrid(   "ABBDETAIL", "TW3MASTER", oStruABB,/*bLinePre*/,/*bLinePost*/,/*bPre*/,/*bPost*/,/*bLoad*/)

oModel:GetModel("TW3MASTER"):SetDescription( STR0016 ) //"Movimentar"
oModel:GetModel("ABBDETAIL"):SetDescription( STR0023 ) //"Informações da Agenda"

oModel:GetModel("ABBDETAIL"):SetOptional(.T.)
oModel:GetModel("ABBDETAIL"):SetOnlyQuery(.T.)

oStruABB:SetProperty( "*"        , MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, ""                        ))
oStruABB:SetProperty( "ABB_HRINI", MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "At336HrVld('ABB_HRINI')" ))
oStruABB:SetProperty( "ABB_HRFIM", MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "At336HrVld('ABB_HRFIM')" ))

For nX := 1 To Len(aCpoABB)
	oStruABB:SetProperty(aCpoABB[nX], MODEL_FIELD_WHEN, {|oMdl,cCpoABB| At335When(cCpoABB,.T.)})
	oStruABB:SetProperty(aCpoABB[nX], MODEL_FIELD_INIT, {|| "" })
Next nX

oModel:SetPrimaryKey( {"TW3_FILIAL+TW3_COD"} )
oModel:SetActivate({|oModel| At336ABBLoad( oModel ) })

Return oModel

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição da interface.

@type function
@author Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since 28/09/2016
@return oView
/*/
//--------------------------------------------------------------------------------------------------------
Static Function ViewDef()

Local oModel   := FWLoadModel( 'TECA336' )
Local oStruTW3 := FWFormStruct( 2, 'TW3', {|cCampo| !(AllTrim(cCampo) $ "TW3_COD|TW3_DTEXEC|TW3_USEXEC")} )
Local oStruABB := FWFormStruct( 2, 'ABB', {|cCampo| AtCamposABB(cCampo,.F.)})
Local oView    := FWFormView():New()
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.)

oStruTW3:AddField( 	"TW3_EFETIV"								,;	// [01] Campo
					"99"										,;	// [02] Ordem
					"Efetivo?"									,;	// [03] Titulo 	  	//"Efetivo?"
					"Efetivo?"									,;	// [04] Descricao 	//"Efetivo?"
					{"Efetivo?"}								,;	// [05] Help 		//"Efetivo?"
					"C" 										,;  // [06] Tipo do campo                              
					"@!"										,;  // [07] Picture                                    
					Nil											,;  // [08] Bloco de Picture Var                       
					""  										,;  // [09] Consulta F3                                
					.T.											,;  // [10] Indica se o campo é editável               
					Nil											,;  // [11] Pasta do campo                             
					"004"										,;  // [12] Agrupamento do campo                       
					{"1=Sim","2=Nao"}							,;  // [13] Lista de valores permitido do campo (Combo)
					Nil											,;  // [14] Tamanho Maximo da maior opção do combo     
					Nil											,;  // [15] Inicializador de Browse                    
					.T.											,;  // [16] Indica se o campo é virtual                
					Nil 										)	// [17] Picture Variável                             


oStruABB:AddField( 	"ABB_HEXTOT"								,;	// [01] Campo
					"99"										,;	// [02] Ordem
					STR0165										,;	// [03] Titulo 	  	//"Tot. Hr. Extra"
					STR0175										,;	// [04] Descricao 	//"Total de Hora Extra"
					{STR0176}									,;	// [05] Help 		//"Total de Hora(s) Extra(s) aplicada(s)"
					"C" 										,;  // [06] Tipo do campo                              
					PesqPict("ABR","ABR_TEMPO")					,;  // [07] Picture                                    
					Nil											,;  // [08] Bloco de Picture Var                       
					""  										,;  // [09] Consulta F3                                
					.F.											,;  // [10] Indica se o campo é editável               
					Nil											,;  // [11] Pasta do campo                             
					Nil											,;  // [12] Agrupamento do campo                       
					Nil											,;  // [13] Lista de valores permitido do campo (Combo)
					Nil											,;  // [14] Tamanho Maximo da maior opção do combo     
					Nil											,;  // [15] Inicializador de Browse                    
					.T.											,;  // [16] Indica se o campo é virtual                
					Nil 										)	// [17] Picture Variável                             

If lMV_GSGEHOR
	oStruTW3:AddField("TW3_ENTRA1",Soma1(oStruTW3:GetProperty('TW3_MOTCOB', MVC_VIEW_ORDEM)),STR0166,STR0166,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Entrada 1" # "Entrada 1"
	oStruTW3:AddField("TW3_SAIDA1",Soma1(oStruTW3:GetProperty('TW3_ENTRA1', MVC_VIEW_ORDEM)),STR0167,STR0167,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Saida 1" # "Saida 1"
	
	oStruTW3:AddField("TW3_ENTRA2",Soma1(oStruTW3:GetProperty('TW3_SAIDA1', MVC_VIEW_ORDEM)),STR0168,STR0168,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Entrada 2" # "Entrada 2"
	oStruTW3:AddField("TW3_SAIDA2",Soma1(oStruTW3:GetProperty('TW3_ENTRA2', MVC_VIEW_ORDEM)),STR0169,STR0169,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Saida 2" # "Saida 2"
	
	oStruTW3:AddField("TW3_ENTRA3",Soma1(oStruTW3:GetProperty('TW3_SAIDA2', MVC_VIEW_ORDEM)),STR0170,STR0170,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Entrada 3" # "Entrada 3"
	oStruTW3:AddField("TW3_SAIDA3",Soma1(oStruTW3:GetProperty('TW3_ENTRA3', MVC_VIEW_ORDEM)),STR0171,STR0171,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Saida 3" # "Saida 3"
	
	oStruTW3:AddField("TW3_ENTRA4",Soma1(oStruTW3:GetProperty('TW3_SAIDA3', MVC_VIEW_ORDEM)),STR0173,STR0173,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Entrada 4" # "Entrada 4"
	oStruTW3:AddField("TW3_SAIDA4",Soma1(oStruTW3:GetProperty('TW3_ENTRA4', MVC_VIEW_ORDEM)),STR0174,STR0174,{},"C","@9 99:99",Nil,Nil,.T.,"","004",Nil,Nil,Nil,.T.,Nil) //"Saida 4" # "Saida 4"

EndIf

oView:SetModel( oModel )

oView:AddField( 'VIEW_CABTW3', oStruTW3, 'TW3MASTER' )
oView:CreateHorizontalBox( 'CABECALHO' , 75 )
oView:SetOwnerView( 'VIEW_CABTW3', 'CABECALHO' )

oStruABB:SetProperty("ABB_MANUT", MVC_VIEW_CANCHANGE, .F.)

oView:AddGrid("VIEW_ITABB" , oStruABB,"ABBDETAIL")
oView:CreateHorizontalBox( "ITENS" , 25 )
oView:SetOwnerView( "VIEW_ITABB" , "ITENS" )

oView:EnableTitleView( "VIEW_ITABB", STR0177 ) //"Dados da Agenda"

oView:SetFieldAction("ABB_HRINI",{|oView,cIDView,cField| At336JDGat(oView)})
oView:SetViewAction("ASKONCANCELSHOW",{||.F.})

oView:AddUserButton( STR0024, 'CLIPS', {|oView| AtPerfilAloc(oView)} ) //"Perfil de Alocação"
oView:AddUserButton( STR0178, 'CLIPS', {|oView| At336VisEs(oView)} )   //"Visualizar Escala"

oView:SetContinuousForm()  //seta formulario continuo

Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtCamposABB
Função utilizada para filtrar os campos da ABB no model e na view do movimentar.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
@obs 
@sample
/*/
//------------------------------------------------------------------------------
Static Function AtCamposABB(cCampo,lModel,cCpoView)
Local aArea      := GetArea()
Local lRet       := .T.
Local cContexto  := ""

Default cCpoView := ""

cCpoView  := "ABB_FILIAL|ABB_DTINI|ABB_DTFIM|ABB_HRINI|ABB_HRFIM|ABB_IDCFAL|ABB_MANUT|ABB_ATIVO"

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

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336HrVld
Valida a hora inicial ou final informada, quando utilizada as situações de saída antecipada, atraso ou jornada diferenciada.

@author Leandro Dourado 
@version 12.1.14
@since 27/12/2016
@return oModel
/*/
//------------------------------------------------------------------------------
Function At336HrVld(cCampo)
Local aAreaABB  	:= ABB->(GetArea())
Local oModel    	:= FwModelActive()
Local oMdlTW3   	:= oModel:GetModel("TW3MASTER")
Local oMdlABB   	:= oModel:GetModel("ABBDETAIL")
Local cSituacao 	:= oMdlTW3:GetValue("TW3_SITCOD")
Local lRet      	:= .T.
Local nLin      	:= oMdlABB:GetLine()
Local cFilMov   	:= oMdlTW3:GetValue("TW3_FILIAL")
Local dDtIni    	:= oMdlABB:GetValue("ABB_DTINI")
Local dDtFim    	:= oMdlABB:GetValue("ABB_DTFIM")
Local cHrIni    	:= oMdlABB:GetValue("ABB_HRINI")
Local cHrFim    	:= oMdlABB:GetValue("ABB_HRFIM")
Local cHrIniSub 	:= oMdlTW3:GetValue("TW3_SUBINI")
Local lMV_GSGEHOR   := SuperGetMV("MV_GSGEHOR",,.F.)
Local aCmpHrs		:= {"TW3_ENTRA1","TW3_SAIDA1"}
Local cHrEmpty		:= "  :  "
Local cEntrAux		:= ""
Local cHrEntr		:= ""
Local nX			:= 0
Local aRows      	:= FwSaveRows()

If cSituacao == SIT_MOV_SAIDANT .AND. cCampo == "ABB_HRFIM"
	If nLin <> oMdlABB:Length()
		lRet := .F.
		Help("",1,"AT336SIT17",,STR0025,2,0) // "Apenas o horário de saída da última agenda do dia poderá ser editado!"
	Elseif !Empty(cHrIniSub) .And. cHrIniSub <> cHrEmpty .And. cHrIniSub < oMdlABB:GetValue("ABB_HRFIM")
		lRet := .F.
		Help("",1,"AT336SIT17",,STR0135,2,0) // "Não é possível alterar o horário de saída, o campo de hora início do substituto é menor que o horário de saída."
	EndIf
	
	If lRet 
		DbSelectArea("ABB")
		ABB->(DbSetOrder(8))
		If ABB->(DbSeek(FwxFilial("ABB",cFilMov)+oMdlABB:GetValue("ABB_CODIGO")))
			If cHrFim >= ABB->ABB_HRFIM
				lRet := .F.
				Help("",1,"AT336SIT17",,STR0026,2,0) //"Para a situação de Saída Antecipada, informe uma hora final anterior ao previsto na agenda!"
			EndIf

			DbSelectArea("ABR")
			ABR->(DbSetOrder(1))			
			If ABR->(DbSeek(FwxFilial("ABR",cFilMov)+oMdlABB:GetValue("ABB_CODIGO")+"000004")) .And. ABR->ABR_HRFIM <> ABR->ABR_HRFIMA
				lRet := .F.
				Help("",1,"AT336SIT19",,STR0136,2,0) //"Não é possível informar a hora do atraso, já existe manutenção de hora extra pra essa agenda!"
			Endif

		EndIf
	EndIf
EndIf

If ((cSituacao $ SIT_MOV_EFETIVO + "|" + SIT_MOV_EXCEDEN + "|" + 			;
				 SIT_MOV_CORTESI + "|" + SIT_MOV_TREINAM + "|" + 			;
				 SIT_MOV_SERVEXT .And. lMV_GSGEHOR .And. At580EGHor()) .Or.	;
				 ((cSituacao $ SIT_MOV_REFORCO + "|" + SIT_MOV_FTREFORCO + "|" + cListDia) .And. lMV_GSGEHOR	)  .Or.;
				 ( cSituacao $ SIT_MOV_COBERTU + "|" + SIT_MOV_FOLGAFT 	 + "|" + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP )) .And.;
				 cCampo == "ABB_HRFIM" .And. lRet																					

	If nLin <> oMdlABB:Length()
		lRet := .F.
		Help("",1,"AT336SIT17",,"Apenas o horário de saída da última agenda de reserva do dia poderá ser editado!",2,0) // "Apenas o horário de saída da última agenda de reserva do dia poderá ser editado!"
	Endif

	If lRet .And. oMdlABB:GetValue("ABB_HRFIM") <= oMdlABB:GetValue("ABB_HRINI")
		lRet := .F.
		Help("",1,"AT336SIT17",,"Horário de saída da reserva está menor ou igual o horário de entrada.",2,0) // "Apenas o horário de saída da última agenda de reserva do dia poderá ser editado!"
	Endif
	
	If !Empty(oMdlTW3:GetValue("TW3_ENTRA1")) .And. oMdlTW3:GetValue("TW3_ENTRA1") <> cHrEmpty .And. lMV_GSGEHOR
		cHrEntr := oMdlTW3:GetValue("TW3_ENTRA1")
	Elseif !Empty(cHrIniSub) .And. cHrIniSub <> cHrEmpty
		cHrEntr := cHrIniSub
	Endif

	If lRet .And. cHrEntr <=  oMdlABB:GetValue("ABB_HRFIM")
		lRet := .F.
		Help("",1,"AT336SIT17",,"Horário de saída da reserva está maior ou igual o horário de entrada do posto.",2,0) // "Apenas o horário de saída da última agenda de reserva do dia poderá ser editado!"
	Endif


Endif

If cSituacao == SIT_MOV_ATRASO .AND. cCampo == "ABB_HRINI"
	
	If lRet
		If !Empty(cHrIniSub) .And. cHrIniSub <> cHrEmpty .And. cHrIniSub >= oMdlABB:GetValue("ABB_HRINI")		
			lRet := .F.
			Help("",1,"AT336SIT19",,STR0137,2,0) //"Não é possível alterar o horário de entrada, o campo de hora início do substituto é maior ou igual o horário de entrada."
		Else
			DbSelectArea("ABB")
			ABB->(DbSetOrder(8))
			If ABB->(DbSeek(FwxFilial("ABB",cFilMov)+oMdlABB:GetValue("ABB_CODIGO")))
				If cHrIni <= ABB->ABB_HRINI
					lRet := .F.
					Help("",1,"AT336SIT19",,STR0028,2,0) //"Para a situação de Atraso, informe uma hora inicial posterior ao previsto na agenda!"
				EndIf
				
				DbSelectArea("ABR")
				ABR->(DbSetOrder(1))			
				If ABR->(DbSeek(FwxFilial("ABR",cFilMov)+oMdlABB:GetValue("ABB_CODIGO")+"000004")) .And. ABR->ABR_HRINI <> ABR->ABR_HRINIA
					lRet := .F.
					Help("",1,"AT336SIT19",,STR0138,2,0) //"Não é possível informar a hora do atraso, já existe manutenção de hora extra pra essa agenda."
				Endif
			EndIf
		Endif
	EndIf
EndIf

If cSituacao == SIT_MOV_JORNDIF .AND. cCampo == "ABB_HRINI"
	If nLin <> 1
		lRet := .F.
		Help("",1,"AT336SIT17",,STR0027,2,0) //"Para esta situação, apenas a hora inicial da primeira agenda poderá ser alterada!"
	EndIf
EndIf

If cSituacao == SIT_MOV_HORAEXT
	If cCampo == "ABB_HRINI"
		If nLin > 1 .And. nLin == oMdlABB:Length()
			lRet := .F.
			Help( , , "AT336SIT17", , "Não é possível realizar a alteração da hora inicial.", 1, 0,,,,,,{"Apenas a hora inicial da primeira agenda e hora final da ultima agenda poderá ser alterada."})
		Endif

	Elseif cCampo == "ABB_HRFIM"
		If nLin == 1 .And. nLin <> oMdlABB:Length()
			lRet := .F.
			Help( , , "AT336SIT17", , "Não é possível realizar a alteração da hora final.", 1, 0,,,,,,{"Apenas a hora inicial da primeira agenda e hora final da ultima agenda poderá ser alterada."})
		EndIf
		
	Endif

	For nX := 1 To oMdlABB:Length()
		
		oMdlABB:Goline(nX)
		
		If lRet .And. At336AgExt(oMdlABB:GetValue("ABB_CODIGO")) <> "00:00"
			lRet := .F.
			Help( , , "AT336SIT17", , "Não é possível realizar a alteração, ja foi aplicado hora extra.", 1, 0,,,,,,{"Caso queira alterar o horário ínicio e fim das agendas, cancele a hora extra e aplique novamente."})
			Exit
		Endif

	Next nX

	FwRestRows( aRows )

Endif

If lRet
	lRet := AtVldHora(cHrFim)
	
	If lRet
		If !AtVldDiaHr( dDtIni, dDtFim, cHrIni, cHrFim )
			lRet := .F.
			If cCampo == "ABB_HRFIM"
				Help("",1,"AT336HRFIM",,STR0029,2,0)  //"Hora final inválida."
			ElseIf cCampo == "ABB_HRINI"
				Help("",1,"AT336HRINI",,STR0030,2,0) //"Hora inicial inválida."
			EndIf
		EndIf
	EndIf
EndIf

RestArea( aAreaABB )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336ABBLoad
Carrega as agendas do atendente selecionado na grid do movimentar.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Function At336ABBLoad( oModel )
Local aArea     := GetArea()
Local oMdlTW3   := oModel:GetModel("TW3MASTER")
Local oMdlABB   := oModel:GetModel("ABBDETAIL")
Local oStrABB   := oMdlABB:GetStruct()
Local aCpoABB   := oStrABB:GetFields()
Local cCodAtend := oMdlTW3:GetValue("TW3_ATDCOD")
Local cFilMov   := oMdlTW3:GetValue("TW3_FILIAL")
Local cFilABB   := xFilial("ABB",cFilMov)
Local cFilTDV   := xFilial("TDV",cFilMov)
Local dDtMov	:= oMdlTW3:GetValue("TW3_DTMOV")
Local nX        := 0
Local xValor    := Nil
Local nLinha    := 1
Local aRetDetRh := {}

cAliasABB := GetNextAlias()

BeginSql Alias cAliasABB
	SELECT *
	FROM   %table:ABB% ABB
	
	INNER JOIN %Table:TDV% TDV ON
	TDV.TDV_FILIAL        = %Exp:cFilTDV%  
	AND TDV.TDV_CODABB    = ABB.ABB_CODIGO 
	AND TDV.TDV_DTREF     = %Exp:dDtMov%   
	AND TDV.%NotDel%	
	
	WHERE   ABB.ABB_FILIAL = %Exp:cFilABB%
	AND     ABB.ABB_CODTEC = %Exp:cCodAtend% 
	AND     ABB.ABB_ATIVO  = '1'    
	AND     ABB.%NotDel%
	ORDER   BY %Order:ABB%
EndSql

(cAliasABB)->(DbGoTop())

While (cAliasABB)->(!Eof())
	If !oMdlABB:IsEmpty()
		nLinha := oMdlABB:AddLine(.T.)
	EndIf
	oMdlABB:GoLine( nLinha )
	For nX := 1 To Len(aCpoABB)
		If !(aCpoABB[nX,3] $ "ABB_SAIU|ABB_OBSIN|ABB_OBSOUT|ABB_LATIN|ABB_LONIN|ABB_LATOUT|ABB_LONOUT|ABB_HRCHIN|ABB_HRCOUT|ABB_OBSMIN|ABB_MANIN|ABB_MANOUT|ABB_OBSMOU")			
			
			If aCpoABB[nX,3] == "ABB_HEXTOT"	
				xValor := At336AgExt((cAliasABB)->ABB_CODIGO)
			Else
				xValor := &("('"+cAliasABB+"')->"+aCpoABB[nX,3])
				If TamSx3(AllTrim(aCpoABB[nX,3]))[3] == "D"
					xValor := Stod(xValor)
				EndIf
			Endif

			oMdlABB:LoadValue(aCpoABB[nX,3],xValor)
		Endif		
	Next nX
	(cAliasABB)->(DbSkip())
EndDo

oMdlABB:GoLine(1)
oMdlABB:SetNoInsertLine(.T.)
oMdlABB:SetNoDeleteLine(.T.)

RestArea( aArea )

Return .T.

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtGetAgendas
Obtem todas as agendas que deverão ser canceladas, de acordo com a situação informada.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtGetAgendas(oMdlAbb,oMdlTW3,cIdcFal,cSituacao)
Local aArea     := GetArea()
Local cAliasQry := ""
Local aRet      := {}
Local cCodTFF   := ""
Local oStrABB   := oMdlABB:GetStruct()
Local aCpoABB   := oStrABB:GetFields()
Local cFil      := oMdlTW3:GetValue("TW3MASTER","TW3_FILIAL")
Local cCodAtend := oMdlTW3:GetValue("TW3MASTER","TW3_ATDCOD")
Local cSituacao := oMdlTW3:GetValue("TW3MASTER","TW3_SITCOD")
Local dDtMov    := oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV")
Local nX        := 0
Local xValor    := Nil
Local nLinha    := 1
Local nQtRg     := 0
Local cDtFim    := ""
Local cChvABB   := ""
Local nPos		:= 0
Local cHrFim	:= ""
Local cIDcFalIn	:= ""

For nX := 1 To oMdlAbb:Length()
	oMdlAbb:Goline(nX)

	//Quando for reforço realiza o recolhimento somente do local de reforço, para as outras situações realiza o recolhimento total.
	If ((cSituacao $ SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" + SIT_MOV_CANCFT.And. !Empty(Posicione("TFF",1,FwxFilial("TFF")+oMdlAbb:GetValue("ABB_CODTFF")  ,"TFF_ORIREF" ))) .Or.;
																							!(cSituacao $ SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF )) .And. (!Empty(oMdlAbb:GetValue("ABB_IDCFAL")) .And. cIdcFal <> oMdlAbb:GetValue("ABB_IDCFAL"))

		If Empty(cIDcFalIn)
			cIDcFalIn += "'" + oMdlAbb:GetValue("ABB_IDCFAL") + "'"
		Else
			cIDcFalIn += "," + "'" + oMdlAbb:GetValue("ABB_IDCFAL") + "'"
		EndIf
	Endif
Next nX

If !Empty(cIDcFalIn)
	cIDcFalIn := "%"+cIDcFalIn+"%"
Endif

If Empty(cIDcFalIn) .Or. Empty(cIdcFal)

	If cSituacao $ SIT_MOV_RECOLHE + "|" + SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" + SIT_MOV_CANCFT
		cAliasQry := GetNextAlias()
		If At336TGYChk( cAliasQry, cFil, cCodAtend, dDtMov, .T., "3" )
			cCodTFF := (cAliasQry)->TGY_CODTFF
		EndIf
		(cAliasQry)->(DbCloseArea())
	Elseif cSituacao == SIT_MOV_RETCURS
		cCodTFF := SuperGetMv("MV_GSRHCUR",,"")
	Elseif cSituacao == SIT_MOV_RETRECI
		cCodTFF := SuperGetMv("MV_GSRHREC",,"")
	Elseif cSituacao == SIT_MOV_CANCADISPEMP
		cCodTFF := SuperGetMv("MV_GSRHDSP",,"")
	Else
		cCodTFF := oMdlTW3:GetValue("TW3MASTER","TW3_ITRHCT")
	EndIf
	
	If !Empty(cCodTFF)
		DbSelectArea("ABQ")
		ABQ->(DbSetOrder(3)) // ABQ_FILIAL+ABQ_CODTFF+ABQ_FILTFF 
		If ABQ->(DbSeek(FwxFilial("ABQ")+cCodTFF))
			cIdcFal := ABQ->ABQ_CONTRT+ABQ->ABQ_ITEM+ABQ->ABQ_ORIGEM
		EndIf
	EndIf
	
EndIf

If !Empty(cIdcFal) .Or. !Empty(cIDcFalIn)

	cAliasABB := GetNextAlias()
	
	If cSituacao $ SIT_MOV_CANCADISPEMP + "|" + SIT_MOV_RETRECI + "|" + SIT_MOV_RETCURS + "|" + SIT_MOV_RECOLHE + "|" + SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" + SIT_MOV_CANCFT
		cChvABB := "%%"
	Else
		cDtFim  := Dtos(M->TW3_ADTFIM)
		cChvABB := "%AND ABB.ABB_DTFIM <= '"+cDtFim+"'%"
	EndIf
	
	BeginSql Alias cAliasABB
		SELECT *
		FROM   %table:ABB% ABB
		
		INNER JOIN %Table:TDV% TDV ON
		TDV.TDV_FILIAL        = %xFilial:TDV%  
		AND TDV.TDV_CODABB    = ABB.ABB_CODIGO 
		AND TDV.TDV_DTREF     >= %Exp:dDtMov%   
		AND TDV.%NotDel%	
		
		WHERE  ABB.ABB_FILIAL =  %xFilial:ABB%
		AND    ABB.ABB_CODTEC =  %Exp:cCodAtend%
		AND    ABB.ABB_IDCFAL IN (%Exp:cIDcFalIn%)
		AND    ABB.ABB_ATIVO  =  '1'
		AND    ABB.%NotDel%
		       %Exp:cChvABB%
		ORDER  BY %Order:ABB%
	EndSql
	
	(cAliasABB)->(DbGoTop())
	
	While (cAliasABB)->(!Eof())

		nPos := aScan(aAgendRes,{|x| x[1] == (cAliasABB)->ABB_CODIGO })

		If nPos > 0 .And. aAgendRes[nPos,5] <> (cAliasABB)->ABB_HRFIM
			cHrFim := aAgendRes[nPos,5]
			aAgendRes[nPos,6] := .T.
		Else
			cHrFim	:= (cAliasABB)->ABB_HRFIM
		Endif

		Aadd(aRet,{(cAliasABB)->ABB_CODIGO,(cAliasABB)->ABB_DTINI,(cAliasABB)->ABB_HRINI,(cAliasABB)->ABB_DTFIM, cHrFim })

		(cAliasABB)->(DbSkip())
	EndDo
EndIf

RestArea( aArea )

Return aRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336PosVld
Realiza as pós-validações do modelo de dados da tela Movimentar.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336PosVld(oModel)
Local aArea      := GetArea()
Local aAreaABR   := ABR->(GetArea())
Local aRows      := FwSaveRows()
Local lRet       := .T.
Local nRecnoTW5  := 0
Local cFilMov    := oModel:GetValue("TW3MASTER","TW3_FILIAL")
Local cSituacao  := oModel:GetValue("TW3MASTER","TW3_SITCOD")
Local cCodAtend  := oModel:GetValue("TW3MASTER","TW3_ATDCOD")
Local cCodSub    := oModel:GetValue("TW3MASTER","TW3_TECSUB")
Local dDtMov     := oModel:GetValue("TW3MASTER","TW3_DTMOV" )
Local cCodTFF    := oModel:GetValue("TW3MASTER","TW3_ITRHCT" )
Local cFilTGZ    := xFilial("TGZ",cFilMov)
Local oMdlABB    := oModel:GetModel("ABBDETAIL")
Local cMotivoABN := SuperGetMv("MV_ATMTFAL",,"")
Local aAgenda    := {}
Local nX         := 0
Local aErro      := {}
Local oMdlTW5    := Nil
Local cAliasQry  := ""
Local cHrIni	 := ""
Local cHrFim	 := ""

lRet := AtVldObrig( oModel )

If lRet
	If cSituacao == SIT_MOV_FALTA
		
		If oMdlABB:Length() > 0 .AND. !oMdlABB:IsEmpty()
			For nX := 1 To oMdlABB:Length()
				oMdlABB:GoLine(nX)
				
				If oMdlABB:GetValue("ABB_ATIVO") == "2"
					lRet := .F.
					Help("",1,"AT336SIT09",,STR0031,2,0) // "A agenda desse dia já está inativa!"
					Exit
				EndIf
			Next nX
		Else
			lRet := .F.
			Help("",1,"AT336SIT09",,STR0032,2,0) // "Não há agenda gerada para esse atendente nessa data!"
		EndIf
		
		If lRet
			nRecnoTW5 := AtChkFalta(cCodAtend,dDtMov)
			If nRecnoTW5 > 0
				lRet := .F.
				Help("",1,"AT336SIT09",,STR0033,2,0) // "Esse atendente já possui um registro de falta em aberto!"
			EndIf
		EndIf
	
	ElseIf cSituacao == SIT_MOV_RETFALT
	
		nRecnoTW5 := AtChkFalta(cCodAtend,dDtMov)
		If nRecnoTW5 == 0
			Help("",1,"AT336SIT10",,STR0034,2,0) //"Esse atendente não possui registro de faltas em aberto!"
		Else
			DbSelectArea("TW5")
			TW5->(DbGoTo(nRecnoTW5))
			If TW5->TW5_DTINI == dDtMov
				lRet := MsgYesNo(STR0035+DtoC(dDtMov)+STR0036,STR0037) //"Houve o lançamento de uma falta para esse atendente na data atual de movimentação ("###"). Deseja desfazer o lançamento da falta?"###"Atenção!"
				If !lRet
					Help("",1,"AT336SIT10",,STR0038,2,0) //"O retorno de falta não pôde ser lançado por já haver um lançamento de falta nesse dia."
				EndIf
			EndIf
		EndIf
		
	ElseIf cSituacao $ SIT_MOV_HORAEXT + "|" + cListHE 
	
		If oMdlABB:Length() > 0 .AND. !oMdlABB:IsEmpty()
			For nX := 1 To oMdlABB:Length()
				oMdlABB:GoLine(nX)
				
				If oMdlABB:GetValue("ABB_ATIVO") == "2"
					lRet := .F.
					Help("",1,"AT336SIT18",,STR0031,2,0) // "A agenda desse dia está inativa!"
					Exit
				EndIf
			Next nX
		Else
			lRet := .F.
			Help("",1,"AT336SIT18",,STR0039,2,0) // "Para utilizar essa situação é necessário haver agendas geradas para esse dia!"
		EndIf
	
	ElseIf cSituacao == SIT_MOV_FOLGUIS
		
		lRet := !(At336TGZChk( Nil, cFilTGZ, cCodAtend, dDtMov, cCodTFF, .F. ))
		
		If !lRet
			Help("",1,"AT336SIT",,STR0088,2,0) //"O atendente da movimentação já está vinculado à esse posto de folguista!"
		Endif
	
	ElseIf cSituacao == SIT_MOV_TROCFUN
		
		If oMdlABB:Length() > 0 .AND. !oMdlABB:IsEmpty()
			lRet := !(oMdlABB:SeekLine({{"ABB_MANUT","1"}}))
			
			If !lRet
				Help("",1,"AT336SIT08",,STR0089 + AllTrim(cCodAtend) + STR0090,2,0) //"A agenda do atendente "###" possui manutenções. Nesse caso a troca não pode ser realizada!"
			Endif
		Else
			lRet := lRet .And. !(At336TW5Chk( cCodAtend, dDtMov ))
			
			If !lRet
				Help("",1,"AT336SIT08",,STR0091 + AllTrim(cCodAtend) + STR0092,2,0) //"A troca envolvendo o atendente "###"não pode ser realizada pois ele possui um registro de ausência para a data da movimentação."
			Endif
		EndIf
		
		If lRet
			cAliasQry := GetNextAlias()
			
			BeginSql Alias cAliasQry
				SELECT *
				FROM   %table:ABB% ABB
				
				INNER JOIN %Table:TDV% TDV ON
				TDV.TDV_FILIAL        = %xFilial:TDV%  
				AND TDV.TDV_CODABB    = ABB.ABB_CODIGO 
				AND TDV.TDV_DTREF     = %Exp:dDtMov%   
				AND TDV.%NotDel%	
				
				WHERE   ABB.ABB_FILIAL = %xFilial:ABB%
				AND     ABB.ABB_CODTEC = %Exp:cCodSub% 
				AND     ABB.ABB_ATIVO  = '1'    
				AND     ABB.%NotDel%
				ORDER   BY %Order:ABB%
			EndSql
			
			(cAliasQry)->(DbGoTop())
			
			If (cAliasQry)->(!Eof())
				While (cAliasQry)->(!Eof())
					
					If (cAliasQry)->ABB_MANUT == "1"
						lRet := .F.
					EndIf
					
					(cAliasQry)->(DbSkip())
				EndDo
				
				If !lRet
					Help("",1,"AT336SIT08",,STR0093 + AllTrim(cCodSub) + STR0094,2,0) //"A agenda do atendente "###" possui manutenções. Nesse caso a troca não pode ser realizada!"
				EndIf
			Else
				lRet := lRet .And. !(At336TW5Chk( cCodSub, dDtMov ))
				
				If !lRet
					Help("",1,"AT336SIT08",,STR0095 + AllTrim(cCodSub) + STR0096,2,0) //"A troca envolvendo o atendente "###"não pode ser realizada pois ele possui um registro de ausência para a data da movimentação."
				EndIf
			EndIf
		EndIf

	Elseif cSituacao == SIT_MOV_FTREFORCO

		//Query com os dias da semana e horários de trabalho do reforço
		cAliasQry := GetNextAlias()

		BeginSql Alias cAliasQry
			SELECT T44.T44_SEQUEN, T44.T44_HORAIN, T44.T44_HORAFI 
			FROM %table:TW4% TW4
			INNER JOIN %table:T44% T44
		  	ON (T44.T44_FILIAL=%xFilial:T44% AND T44.T44_CODTW4=TW4.TW4_COD AND T44.%NotDel%)
			WHERE TW4.TW4_FILIAL=%xFilial:TW4%
		  	  AND TW4.%NotDel%
		  	  AND TW4.TW4_CODTFF=%Exp:cCodTFF%
			ORDER BY T44.T44_SEQUEN
		EndSql
		
		(cAliasQry)->(DbGoTop())
		
		While (cAliasQry)->(!Eof())

			If Empty(cHrIni)
				cHrIni := (cAliasQry)->T44_HORAIN
			Endif

			cHrFim := (cAliasQry)->T44_HORAFI
			
			(cAliasQry)->(DbSkip())

		EndDo
				
		If !Empty(cHrIni) .And. !Empty(cHrFim) .And. TxExistAloc(cCodAtend,dDtMov,cHrIni,dDtMov,cHrFim) 
			Help( , , "At336PosVld", ,"Conflito de alocação, não é possível realizar FT de Reforço, o horário do posto que o atendente está alocado é igual ao horário do posto de reforço." , 1, 0,,,,,,{"Realize o recolhimento do atendente ou altere o horário de entrada e saída do posto de reforço."}) //"Conflito de alocação, não é possível realizar FT de Reforço, o horário do posto que o atendente está alocado é igual ao horário do posto de reforço."##"Realize o recolhimento do atendente ou altere o horário de entrada e saída do posto de reforço."
			lRet := .F.
		Endif	

		(cAliasQry)->(DbCloseArea())

	EndIf
EndIf

If lRet .And. ExistBlock("AT336POSVL")
	lRet := ExecBlock("AT336POSVL",.F.,.F.,{oModel})
EndIf

RestArea( aArea )
RestArea( aAreaABR )
FwRestRows( aRows )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336Grava
Alimenta e grava todos os modelos de dados que serão utilizados pelo Movimentar, conforme a situação informada.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336Grava(oModel)
Local cFil       := oModel:GetValue("TW3MASTER","TW3_FILIAL")
Local cSituacao  := oModel:GetValue("TW3MASTER","TW3_SITCOD")
Local cCodAtend  := oModel:GetValue("TW3MASTER","TW3_ATDCOD") 
Local dDtMov     := oModel:GetValue("TW3MASTER","TW3_DTMOV") 
Local nGrupo     := oModel:GetValue("TW3MASTER","TW3_GRPESC")
Local cCodRtCob  := oModel:GetValue("TW3MASTER","TW3_RTACOD")
Local cCodTFF    := oModel:GetValue("TW3MASTER","TW3_ITRHCT")
Local cCodTDX    := oModel:GetValue("TW3MASTER","TW3_TRSQES")
Local cCodTW3	 := oModel:GetValue("TW3MASTER","TW3_COD")
Local lEfetiv	 := oModel:GetValue("TW3MASTER","TW3_EFETIV") <> "2"
Local cCodCob    := oModel:GetValue("TW3MASTER","TW3_ITCOBE")
Local cTFFRecol  := "" // Codigo de TFF no qual será feito o recolhimento.
Local nRecnoTW5  := 0
Local lRet       := .T.
Local nX         := 0
Local nY         := 0
Local aRetRes    := {}
Local aCodTFF    := {}
Local aCodAtend  := {}
Local lAloAut    := .F. // Indica se será chamada a função At330AloAut.
Local cLocalTFF  := ""
Local cCodTFL    := ""
Local cEscala    := ""
Local cContrt    := ""
Local cOrcSrv    := ""
Local cCliente   := ""
Local cLojaCli   := ""
Local cMotivo    := ""
Local cTpLanc    := ""
Local lSrvExt    := .F.
Local lAteCob    := .F.
Local cAliasQry  := ""
Local cResPad	 := ""
Local cMemorando := Nil
Local xRet		 := Nil
Local aFerias	 := {.F.,""}
Local lMovJob	 := IsIncallStack("TECM330")
Local aAloc		 := {}		
Local cRtTipo 	 := ""
Local cOrcRes	 := SuperGetMV("MV_GSORCRE",,,cFil)
Local oMdlABB    := oModel:GetModel("ABBDETAIL")

Begin Transaction
	
	If lRet .and. ValType(oMdlTrocaEfet) == "O" .AND. !lTrocaEfet
		lTrocaEfet    := .T. // Essa variavel é setada como verdadeira para impedir que o sistema caia num loop infinito
		lResetSitAt   := .F.
		lRet          := oMdlTrocaEfet:CommitData()
		lResetSitAt   := .T.
		lTrocaEfet    := .F.

		If lRet
			lTrocaOk := .T.
		Endif

		oMdlTrocaEfet:DeActivate()
		oMdlTrocaEfet:Destroy()
		FreeObj(oMdlTrocaEfet)
		oMdlTrocaEfet := Nil
		DelClassIntF()

	EndIf
	
	If lRet
		Do Case
			Case (cSituacao $ SIT_MOV_COBERTU + "|" + SIT_MOV_FOLGAFT + "|" + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + "|" + cListFT + "|" + cListCob) .And. !Empty(cCodCob)

				//Se houver alteração no horário final da ultima agenda de reserva, aplica saida antecipada.
				If oMdlABB:Length() > 0 .And. oMdlABB:GoLine(oMdlABB:Length()) .And. Posicione("ABB",8,FwxFilial("ABB")+oMdlAbb:GetValue("ABB_CODIGO"),"ABB_HRFIM") <> oMdlABB:GetValue("ABB_HRFIM")

					aAdd(aAgendRes,{oMdlABB:GetValue("ABB_CODIGO"),;
								 	oMdlABB:GetValue("ABB_DTINI") ,;
									oMdlABB:GetValue("ABB_HRINI") ,;
									oMdlABB:GetValue("ABB_DTFIM") ,;
									oMdlABB:GetValue("ABB_HRFIM") ,;
									.F.} )

					cMotivo := SuperGetMv("MV_ATMTSAN",,"")

					// Chamada da função responsável pela gravação das manutenções 
					lRet := At336GrABR( aAgendRes , cMotivo , dDtMov 	 , ""	  ,;
					                    ""		  , .T.	    , ""		 , .F.    ,;
					                    Nil    	  , cFil 	, cCodTW3              )

				Else
					// Funcao que verifica se o atendente está em posto de reserva e se estiver, faz o cancelamento da agenda.
					lRet := At336ChkAlc( cFil, cCodAtend, dDtMov, .F. )
				
				Endif	
			
				lRet := lRet .And. AtCobAloc(oModel)
			
		
			Case (cSituacao $ SIT_MOV_EFETIVO +"|"+ SIT_MOV_TREINAM +"|"+ SIT_MOV_EXCEDEN 	 +"|"+ SIT_MOV_CORTESI +"|"+ ; 
			                  SIT_MOV_SERVEXT +"|"+ SIT_MOV_REFORCO +"|"+ SIT_MOV_FTREFORCO	 +"|"+ SIT_MOV_FOLGAFT +"|"+ cListFT +"|"+ cListDia)
				
				For nX := 1 To oMdlABB:Length()
					oMdlABB:GoLine(nX)
					aAdd(aAgendRes,{oMdlABB:GetValue("ABB_CODIGO"),;
								 	oMdlABB:GetValue("ABB_DTINI") ,;
									oMdlABB:GetValue("ABB_HRINI") ,;
									oMdlABB:GetValue("ABB_DTFIM") ,;
									oMdlABB:GetValue("ABB_HRFIM") ,;
									.F.} )
				Next nX

				If cSituacao $ SIT_MOV_REFORCO + '|' + SIT_MOV_FTREFORCO + '|' + cListDia
					lRet := At336ABQRef( cCodTFF )
				EndIf

				//Quando não for ft de reforço ou ft normal
				If !(cSituacao $ SIT_MOV_FTREFORCO + '|' + SIT_MOV_FOLGAFT)
					// Funcao que verifica se o atendente está em posto de reserva e se estiver, faz seu recolhimento.
					lRet := lRet .And. At336ChkAlc( cFil, cCodAtend, dDtMov, .T. )
				Endif

			  	// Chama rotina de gravação
				lRet := lRet .And. AtTW3Grv(oModel,"TGY",cSituacao)

				If cSituacao == SIT_MOV_EFETIVO
					//Alteração na rota de cobertura.
					lRet := lRet .And. At581Alt(cCodTFF,cCodTDX,cCodAtend,nGrupo)
				Endif

				If lRet
					lAloAut := .T.
					Aadd( aCodTFF, cCodTFF )
				Endif
		
			// Troca de Funcionario: por conta de suas particularidades foi dado um tratamento à parte para essa situação.
			Case cSituacao == SIT_MOV_TROCFUN 
			
				At580VdFolder({1})
				lRet := AtTrocaFunc(oModel,@aCodTFF,@aCodAtend)
				
			Case cSituacao $ SIT_MOV_RETCURS + "|" + SIT_MOV_RETRECI + "|" + SIT_MOV_CANCADISPEMP
				
				//Realiza alteração na TW5
				lRet := AtDelCurso( cFil, cCodAtend, dDtMov )

				//Realiza o cancelamento da agenda e alocação de curso e reciclagem.			
				lRet := lRet .And. AtTW5Grv(oModel, cSituacao)

				//Quando o atendente estiver alocado no posto de efetivo desfaz a manuntenção.
				If At336TGYChk( , cFil, cCodAtend, dDtMov, .T., "1" )

					If cSituacao == SIT_MOV_RETRECI
						cMotivo := SuperGetMv("MV_ATMTREC",,"")
					Elseif cSituacao == SIT_MOV_RETCURS
						cMotivo := SuperGetMv("MV_ATMTCUR",,"")
					Elseif cSituacao == SIT_MOV_CANCADISPEMP
						cMotivo := SuperGetMv("MV_ATMTDSP",,"")
					Endif

					lRet := lRet .And. AtDesfazManut( cCodAtend, dDtMov, cMotivo)

				Else //Quando não estiver alocado no posto de efetivo, aloca o atendente na reserva.

					aRetRes := At336Rsrv(cFil, cCodAtend, dDtMov, , , @cCodTFF, cCodTW3 )

					If Len(aRetRes) > 0
						lRet := .F.
					Else
						cMemorando := "0"
					Endif

				EndIf
				
				// Caso seja aplicado um retorno de curso no meio do período do curso, o sistema gerará a agenda do atendente.
				If lRet .AND. !Empty(cCodTFF)
					lAloAut := .T.
					Aadd( aCodTFF, cCodTFF )
				EndIf
			
			// Faz a movimentação de rota de cobertura (almocista ou jantista) através do TECA581
			Case cSituacao $ SIT_MOV_ALMOCIS + "|" + SIT_MOV_FOLGUIS + "|" + SIT_MOV_FERISTA .AND. !Empty(cCodRtCob) // Indica se utiliza rota de cobertura (almocista/jantista)
				
				If cSituacao == SIT_MOV_FERISTA
					
					aFerias := At581FerRt(cCodRtCob)

					if aFerias[1]
						lRecolheOk := .T.

						// Funcao que verifica se o atendente está em posto de reserva e se estiver, faz seu recolhimento se existir ferias.
						lRet := At336ChkAlc( cFil, cCodAtend, dDtMov, .T. )					

						lRecolheOk := .F.
					Endif
				Else
					// Funcao que verifica se o atendente está em posto de reserva e se estiver, faz seu recolhimento
					lRet := At336ChkAlc( cFil, cCodAtend, dDtMov, .T. )
					lAteCob := .T.				
				Endif

				If lEfetiv
					lRet := lRet .AND. At336RtCob(cCodAtend,cCodRtCob,@aCodTFF,"MV",@cRtTipo)
				Else
					lRet := lRet .AND. At336RtCob(cCodAtend,cCodRtCob,@aCodTFF,"MV",@cRtTipo,"1")
				Endif
				
				If lRet .And. !Empty(aFerias[2])
					cCodAtend := aFerias[2]
					aAloc 	  := TxEscCalen(cCodAtend,dDtMov,dDtMov)
					
					If !Empty(aAloc)
						cCodTFF := aAloc[1][11]
					Endif

					If !Empty(cCodTFF)
						Aadd( aCodTFF,cCodTFF  )
					Endif
				Endif

				If lRet .AND. Len(aCodTFF) > 0
					cMemorando := "0"
					lAloAut := .T.
				EndIf
				
			Case cSituacao == SIT_MOV_RETFALT 
				lRet := AtRetFalta(oModel,"1")

			Case cSituacao == SIT_MOV_CANCFOL
				lRet := AtRetFalta(oModel,"2")
				
			Case cSituacao $ SIT_MOV_CANCCOB + '|' + SIT_MOV_CANCFT + '|' + SIT_MOV_CANCFTCN + "|" + SIT_MOV_CANCCNCOMP + "|" + cListCanCB + "|" + cListCanFT
			
				//Quando for agenda de reserva verifica se houve alguma manutenção.
				If oMdlABB:SeekLine({{"ABB_TIPOMV" , "RES"}})

					cMotivo := SuperGetMv("MV_ATMTSAN",,"")
	
					//Funcao que cancela a manutenção de saída antecipada da reserva
					lRet := AtDesfazManut( cCodAtend, dDtMov, cMotivo, , , , "1" )
	
					//Cancela a cobertura
					lRet := AtCancCob(oModel)
					
				Else
					//Cancela a cobertura
					lRet := AtCancCob(oModel)
				
				Endif
				
				
			Case cSituacao == SIT_MOV_CANCADN
				cMotivo := SuperGetMv("MV_ATMTSAN",,"")
				lRet 	:= AtDesfazManut( cCodAtend, dDtMov, cMotivo, , , , "1" )

			Case cSituacao == SIT_MOV_CANCATR
				cMotivo := SuperGetMv("MV_ATMTATR",,"")
				lRet 	:= AtDesfazManut( cCodAtend, dDtMov, cMotivo, , , , "1" )

			Case cSituacao $ SIT_MOV_CANCEXT + '|' + cListCanHE
				lRet 	:= AtCancHrExt(oModel)
			
			Case cSituacao == SIT_MOV_CANCJORNDIF
				cMotivo := SuperGetMv("MV_ATMTJDF",,"")
				lRet 	:= AtDesfazManut( cCodAtend, dDtMov, cMotivo, , , , "1" )

			Case (cSituacao $ SIT_MOV_FALTA   + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_JORNDIF 	+ '|' + SIT_MOV_CANCFTREF 		+ '|' + ;
							 	 					  SIT_MOV_FOLGA   + '|' + SIT_MOV_RECOLHE 	+ '|' + SIT_MOV_SAIDANT 		+ '|' + ;
							 	 					  SIT_MOV_HORAEXT + '|' + SIT_MOV_ATRASO  	+ '|' + SIT_MOV_CURSO   		+ '|' + ;
							 	 					  SIT_MOV_RECICLA + '|' + SIT_MOV_ADISPEMP 	+ '|' + SIT_MOV_RECREFORCO 		+ '|' + cListHE)
			
				lRet := AtTW5Grv(oModel,cSituacao)
				
				If lRet
					If cSituacao == SIT_MOV_RECOLHE .Or. (cSituacao == SIT_MOV_RECREFORCO .And. !At336TGYChk( , cFil, cCodAtend, dDtMov, .T., "1" ))
						If oModel:GetValue("TW3MASTER","TW3_RESERV") <> "1"
							aRetRes := At336Rsrv(cFil, cCodAtend, dDtMov, , , @cCodTFF, cCodTW3 )
		
							If Len(aRetRes) > 0
								lRet := .F.
							Endif
						Else
							cCodTFF := ""
						Endif
					Endif
				Endif

				If cSituacao $ SIT_MOV_CURSO + '|' + SIT_MOV_RECICLA + '|' + SIT_MOV_ADISPEMP
					
					// Funcao que verifica se o atendente está em posto de reserva e se estiver, faz seu recolhimento					
					lRet := lRet .And. At336ChkAlc( cFil, cCodAtend, dDtMov, .T. )
					
					// Chama rotina de gravação
					lRet := lRet .And. AtTW3Grv(oModel,"TGY",cSituacao)
	
					If lRet
						If cSituacao == SIT_MOV_RECICLA
							cCodTFF := SuperGetMv("MV_GSRHREC",,"")
						Elseif cSituacao == SIT_MOV_CURSO
							cCodTFF := SuperGetMv("MV_GSRHCUR",,"")
						Elseif cSituacao == SIT_MOV_ADISPEMP
							cCodTFF := SuperGetMv("MV_GSRHDSP",,"")
						Endif
					Endif
				Endif

				If lRet .And. !Empty(cCodTFF)
					lAloAut    := .T.
					cMemorando := "0"
					Aadd( aCodTFF, cCodTFF )
				Endif			

			Case cSituacao $ SIT_MOV_RECALMO + '|' + SIT_MOV_RECFOLG + '|' + SIT_MOV_RECFERI

				lRet := At336RtCob(cCodAtend,cCodRtCob,@aCodTFF,"RE")							

				If lRet .And. !At336TGYChk( , cFil, cCodAtend, dDtMov, .T., "2" )
					aRetRes := At336Rsrv(cFil, cCodAtend, dDtMov, , , @cResPad, cCodTW3)
				Endif
				
				If Len(aRetRes) > 0
					lRet := .F.
				Else
					If !Empty(cResPad)
						lAloAut    := .T.
						cMemorando := "0"
						Aadd( aCodTFF, cResPad )
					Endif
				Endif
		
		EndCase
	EndIf

	If lRet
		If lAloAut
			For nX := 1 To Len(aCodTFF)
				
				cCodTFF := aCodTFF[nX]
				If !Empty(cCodTFF) 
					cLocalTFF := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF  ,"TFF_LOCAL" )
					cCodTFL   := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF  ,"TFF_CODPAI")
					cEscala   := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF  ,"TFF_ESCALA")
					cContrt   := Posicione("TFL",1,FwxFilial("TFL")+cCodTFL  ,"TFL_CONTRT")
					cOrcSrv   := Posicione("TFL",1,FwxFilial("TFL")+cCodTFL  ,"TFL_CODPAI")
					cCliente  := Posicione("TFJ",1,FwxFilial("TFJ")+cOrcSrv  ,"TFJ_CODENT")
					cLojaCli  := Posicione("TFJ",1,FwxFilial("TFJ")+cOrcSrv  ,"TFJ_LOJA"  )
					lSrvExt   := Posicione("TFJ",1,FwxFilial("TFJ")+cOrcSrv  ,"TFJ_SRVEXT") == "1"
				EndIf
				
				lRet := At330AloAut(                                     ;
							 cEscala                                    ,; // Escala Inicial
					 		 cEscala                                    ,; // Escala Final
					 		 cContrt                                    ,; // Contrato Inicial
					 		 cContrt                                    ,; // Contrato Final
					 		 cLocalTFF                                  ,; // Local Inicial
					 		 cLocalTFF                                  ,; // Local Final
					 		 oModel:GetValue("TW3MASTER","TW3_DTMOV")   ,; // Data inicial
					 		 oModel:GetValue("TW3MASTER","TW3_DTMOV")   ,; // Data final
					 		 cCliente                                   ,; // Cliente Inicial
					 		 cLojaCli                                   ,; // Loja Inicial
					 		 cCliente                                   ,; // Cliente Final
					 		 cLojaCli                                   ,; // Loja Final
					 		 Space(TamSX3("TGS_SUPERV")[1])             ,; // Supervisor de
					 		 Replicate('Z',TamSx3("TGS_SUPERV")[1])     ,; // Supervisor ate
					 		 .F.                                        ,; // Exibir mensagens?
					 		 iif(lMovJob,"1",Nil)                       ,; // cConfirma : "0" - Não Confirma, "1" - Confirma, " " - Efetua pergunta de confirmação
					 		 cMemorando                                 ,; // cMemorando: "0" - Não gera memorandos, "1" - Gera memorandos, " " - Efetua pergunta de confirmação
					 		 lSrvExt                                    ,; // Serviço Extra?
					 		 cCodAtend									,; // Código do Atendente
					 		 cCodTFF                                    ,; // Código da TFF 
					 		 lAteCob                                    ,; // Indica se trata-se de uma movimentação de posto de cobertura (Almocista, jantista, ou folguista)
					 		 lLibSit									,;
					 		 cSituacao									,; // Situações para movimentar agenda 
							 Iif(cSituacao == SIT_MOV_ALMOCIS, oModel:GetValue("TW3MASTER","TW3_COD") , ''),;
							 cRtTipo									) //Tipo da implantação da rota de cobertura
			Next nX
		EndIf
		
		// Caso o atendente tenha sido recolhido porém lhe foi dada uma ausência (falta, curso, reciclagem ou folga), será reaplicada essa ausencia na reserva.
		If lRet .And. cSituacao == SIT_MOV_RECOLHE .And. At336TW5Chk( cCodAtend, dDtMov, @cTpLanc )
			If cTpLanc == "1"
				cMotivo := SuperGetMv("MV_ATMTFAL",,"")
			Else
				// Para as manutenções de Curso, reciclagem e folga, é feito o cancelamento da agenda.
				cMotivo := SuperGetMv("MV_ATMTCAN",,"")
			EndIf
			
			lRet := At336CanAgenda( cFil, cCodAtend, dDtMov, "2", cMotivo )		
		EndIf
		
		If lRet .And. ExistBlock("AT336CMT")
			lRet :=  ExecBlock("AT336CMT",.F.,.F.,{oModel})
		Endif
		
		If lRet
			lRet := FwFormCommit(oModel)
		EndIf
	EndIf

	If !lRet
		FwModelActive(oModel)
		DisarmTransaction()
		Break
	EndIf	
	
	If cSituacao <> SIT_MOV_RECOLHE
		// Reseta todas as variáveis staticas do TECA336.
		AtResetStatics() 
	Endif

End Transaction

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtResetStatics
Reseta as variáveis static do TECA336.

@author Leandro Dourado 
@version 12.1.14
@since 09/02/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtResetStatics()

lChkWhen     := .T.
cFilAtd      := ""
If !Empty(cAliasABB) .AND. Select(cAliasABB) > 0
	(cAliasABB)->(DbCloseArea())
EndIf
cAliasABB    := ""
dDataRef     := Ctod("")
If lResetSitAt
	cSitAtend     := ""
	cMovAtend	  := ""
	oMdlTrocaEfet := Nil
EndIf
lResetSitAt  := .T.
aPerfAloc    := {}
cHrIniCob    := ""
cTpMovCob	 := ""
aAgendRes	 := {}

Return .T.

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336Cancel
Função executada pelo botão cancelar do formulário. Reseta as variáveis static e fecha a tela de movimentação.

@author Leandro Dourado 
@version 12.1.14
@since 09/02/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336Cancel(oModel)

AtResetStatics()

Return .T.

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtTW3Grv
Faz a gravação dos dados da tabela TW3, além de utilizar o modelo de dados do TECA580E para alocar o atendente informado.

@author Leandro Dourado 
@version 12.1.14
@since 28/09/2016
@return oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Function AtTW3Grv(oMdlTW3,cTabela,cSituacao)
Local oMdlAloc  := Nil
Local oMdlTDX   := Nil
Local oMdlTGX   := Nil
Local cCodAtend := ""
Local cCodTFF   := ""
Local nGrupo    := 0
Local dDtMov    := cTod("") 
Local cCodTDX   := ""
Local cCodTW3   := ""
Local cLocalTFF := ""
Local cCodTFL   := ""
Local dDtFim    := cTod("")
Local cContrt   := ""
Local cOrcSrv   := ""
Local cCliente  := ""
Local cLojaCli  := ""
Local lSrvExt   := .F. 
Local nLinhas   := 0
Local nLinNova  := 1
Local lAddLinha := .T.
Local lRet      := .T.
Local aErro     := {}
Local aAlocEsc  := {}
Local nX        := 0
Local cFil      := ""
Local cEscala   := ""
Local cTipAloc  := ""
Local cItem     := ""
Local oMdl580E  := Nil
Local cEntra1		:= ""
Local cSaida1		:= ""
Local cEntra2		:= ""
Local cSaida2		:= ""
Local cEntra3		:= ""
Local cSaida3		:= ""
Local cEntra4		:= ""
Local cSaida4		:= ""
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.)
Local lEfetiv		:= .T.

cCodAtend := oMdlTW3:GetValue("TW3MASTER","TW3_ATDCOD" ) 
dDtMov    := oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV"  )
cCodTW3   := oMdlTW3:GetValue("TW3MASTER","TW3_COD"    )
lEfetiv   := oMdlTW3:GetValue("TW3MASTER","TW3_EFETIV" ) <> "2"

If cSituacao $ SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO + "|" + SIT_MOV_ADISPEMP

	If cSituacao == SIT_MOV_RECICLA
		cCodTFF := SuperGetMv("MV_GSRHREC",,"")
	Elseif cSituacao == SIT_MOV_CURSO
		cCodTFF := SuperGetMv("MV_GSRHCUR",,"")
	Elseif cSituacao == SIT_MOV_ADISPEMP
		cCodTFF := SuperGetMv("MV_GSRHDSP",,"")
	Endif

	If TFF->(DbSeek(xFilial("TFF") + cCodTFF ))
	
		cEscala := TFF->TFF_ESCALA		
		
		//Buscar registro de escala efetivo
		DbSelectArea("TDX")
		TDX->(DbSetOrder(2))	//TDX_FILIAL + TDX_CODTDW + TDX_TURNO
		TDX->(DbSeek(xFilial("TDX") + cEscala ))
		
		cCodTDX	:= TDX->TDX_COD
		
		//Buscar o grupo conforme a configuração do efetivo.	
		nGrupo := At336GrpDp(xFilial("TGY")	,;
		 							cCodTFF	,;
		 							dDtMov	,;
		 							dDtMov	,;
		 							cCodTDX	,;
		 							cCodAtend)
	Endif
Else
	cCodTFF   := oMdlTW3:GetValue("TW3MASTER","TW3_ITRHCT" )
	nGrupo    := oMdlTW3:GetValue("TW3MASTER","TW3_GRPESC" )
	cCodTDX   := oMdlTW3:GetValue("TW3MASTER","TW3_TRSQES" )
	
	If lMV_GSGEHOR
		cEntra1	:= oMdlTW3:GetValue("TW3MASTER","TW3_ENTRA1" )
		cSaida1	:= oMdlTW3:GetValue("TW3MASTER","TW3_SAIDA1" )
		cEntra2	:= oMdlTW3:GetValue("TW3MASTER","TW3_ENTRA2" )
		cSaida2	:= oMdlTW3:GetValue("TW3MASTER","TW3_SAIDA2" )
		cEntra3	:= oMdlTW3:GetValue("TW3MASTER","TW3_ENTRA3" )
		cSaida3	:= oMdlTW3:GetValue("TW3MASTER","TW3_SAIDA3" )
		cEntra4	:= oMdlTW3:GetValue("TW3MASTER","TW3_ENTRA4" )
		cSaida4	:= oMdlTW3:GetValue("TW3MASTER","TW3_SAIDA4" )
	Endif
Endif

cLocalTFF := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF  ,"TFF_LOCAL" )
cCodTFL   := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF  ,"TFF_CODPAI")

If lEfetiv
	dDtFim := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF  ,"TFF_PERFIM")
Else
	dDtFim := dDtMov
Endif

cContrt   := Posicione("TFL",1,FwxFilial("TFL")+cCodTFL  ,"TFL_CONTRT")
cOrcSrv   := Posicione("TFL",1,FwxFilial("TFL")+cCodTFL  ,"TFL_CODPAI")
cCliente  := Posicione("TFJ",1,FwxFilial("TFJ")+cOrcSrv  ,"TFJ_CODENT")
cLojaCli  := Posicione("TFJ",1,FwxFilial("TFJ")+cOrcSrv  ,"TFJ_LOJA"  )
lSrvExt   := Posicione("TFJ",1,FwxFilial("TFJ")+cOrcSrv  ,"TFJ_SRVEXT") == "1"

At580bKill()

If cSituacao $ SIT_MOV_REFORCO + '|' + SIT_MOV_FTREFORCO + '|' + cListDia
	At580EGHor(.F.)
	lMV_GSGEHOR := .F.
Else
	At580EGHor((VldEscala(TFF->(RECNO()),.F.)))
Endif

oMdl580E := FwLoadModel("TECA580E")
oMdl580E:SetOperation(MODEL_OPERATION_UPDATE)
oMdl580E:Activate()

oMdlTDX  := oMdl580E:GetModel("TDXDETAIL")
oMdlTGX  := oMdl580E:GetModel("TGXDETAIL")

// Posiciona o Modelo de dados da TDX/TGX no registro correto.
If cTabela == "TGY"
	At580VdFolder({1}) //Função do TECA580E, para o sistema identificar que se trata da alocação de um KK.
	For nX := 1 To oMdlTDX:Length()
		oMdlTDX:GoLine(nX)
		If oMdlTDX:GetValue("TDX_COD") == cCodTDX
			Exit
		EndIf
	Next nX
Else
	At580VdFolder({2}) //Função do TECA580E, para o sistema identificar que se trata da alocação de uma cobertura.
	For nX := 1 To oMdlTGX:Length()
		oMdlTGX:GoLine(nX)
		If oMdlTGX:GetValue("TGX_COD") == cCodTDX
			Exit
		EndIf
	Next nX
EndIf

If cTabela == "TGY"
	oMdlAloc := oMdl580E:GetModel("TGYDETAIL")
Else
	oMdlAloc := oMdl580E:GetModel("TGZDETAIL")
EndIf

If !oMdlAloc:IsEmpty() // Caso o grid já esteja preenchido, adiciona nova linha.
	For nX := 1 To oMdlAloc:Length()
		oMdlAloc:GoLine(nX)
		If !oMdlAloc:IsDeleted()
			If oMdlAloc:GetValue(cTabela+"_GRUPO") == nGrupo .AND.;
			  (oMdlAloc:GetValue(cTabela+"_DTINI") <= dDtMov .AND. oMdlAloc:GetValue(cTabela+"_DTFIM") >= dDtMov) .And. !(cSituacao $ SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO + "|" + SIT_MOV_ADISPEMP )
				lAddLinha := .F.
			EndIf
		EndIf
	Next nX
	
	If lAddLinha
		nLinhas  := oMdlAloc:Length()
		nLinNova := oMdlAloc:AddLine()
		If nLinNova <= nLinhas 
			lRet := .F.
		EndIf
	EndIf
EndIf

If lRet
	
	aAlocEsc := {}
	If cTabela == "TGY"
		cFil     := FwxFilial("TGY")
		cEscala  := oMdlTDX:GetValue("TDX_CODTDW")
		cTipAloc := At336TipAlo( cSituacao, lEfetiv )
		cItem    := At336TGYIt(xFilial("TGY"), cCodTFF)
	ElseIf cTabela == "TGZ"
		cFil     := FwxFilial("TGZ")
		cEscala  := oMdlTGX:GetValue("TGX_CODTDW")
		cTipAloc := ""
		cItem    := At336TGZIt(xFilial("TGZ"), cCodTFF)
	EndIf
	
	If cSituacao $ SIT_MOV_ADISPEMP +"|"+ SIT_MOV_FOLGAFT +"|"+ SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + '|' + cListFT
		dDtFim   := dDtMov
	ElseIf cSituacao $ SIT_MOV_TREINAM + "|" + SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO
		dDtFim   := oMdlTW3:GetValue("TW3MASTER","TW3_ADTFIM" )
	EndIf
	
	Aadd(aAlocEsc, cFil                           ) //"TGY_FILIAL"
	Aadd(aAlocEsc, cEscala                        ) //"TGY_ESCALA"
	Aadd(aAlocEsc, cCodTDX						  ) //"TGY_CODTDX"
	Aadd(aAlocEsc, cItem						  ) //"TGY_ITEM"
	Aadd(aAlocEsc, cCodAtend                      ) //"TGY_ATEND"
	Aadd(aAlocEsc, oMdlTDX:GetValue("TDX_TURNO" ) ) //"TGY_TURNO"
	Aadd(aAlocEsc, oMdlTDX:GetValue("TDX_SEQTUR") ) //"TGY_SEQ"
	Aadd(aAlocEsc, dDtMov                         ) //"TGY_DTINI"
	Aadd(aAlocEsc, dDtFim                         ) //"TGY_DTFIM"
	Aadd(aAlocEsc, cCodTFF                        ) //"TGY_CODTFF"
	Aadd(aAlocEsc, nGrupo                         ) //"TGY_GRUPO"
	Aadd(aAlocEsc, cTipAloc                       ) //"TGY_TIPALO" 
	Aadd(aAlocEsc, cCodTW3                        ) //"TGY_CODTW3"

	If lMV_GSGEHOR
		Aadd(aAlocEsc, cEntra1	)	//"TW3_ENTRA1"		
		Aadd(aAlocEsc, cSaida1	)	//"TW3_SAIDA1"
		Aadd(aAlocEsc, cEntra2	)	//"TW3_ENTRA2"
		Aadd(aAlocEsc, cSaida2	)	//"TW3_SAIDA2"
		Aadd(aAlocEsc, cEntra3	)	//"TW3_ENTRA3"
		Aadd(aAlocEsc, cSaida3	)	//"TW3_SAIDA3"
		Aadd(aAlocEsc, cEntra4	)	//"TW3_ENTRA4"
		Aadd(aAlocEsc, cSaida4	)	//"TW3_SAIDA4"
	Endif

	lRet := At336GrTGY(oMdl580E, oMdlAloc, cTabela, aAlocEsc, ,lMV_GSGEHOR)
	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtTrocaFunc
Realiza o processamento de troca de funcionários.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtTrocaFunc( oMdlTW3, aCodTFF, aCodAtend )
Local aArea       := GetArea()
Local aAreaABB    := ABB->(GetArea())
Local aAreaTFF    := TFF->(GetArea())
Local oMdlAloc    := Nil
Local cFilMov     := oMdlTW3:GetValue("TW3MASTER","TW3_FILIAL")
Local cCodAtend   := oMdlTW3:GetValue("TW3MASTER","TW3_ATDCOD")
Local cFilSub     := oMdlTW3:GetValue("TW3MASTER","TW3_TECFIL")
Local cCodSub     := oMdlTW3:GetValue("TW3MASTER","TW3_TECSUB") 
Local dDtMov      := oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV" ) 
Local cCodTW3     := oMdlTW3:GetValue("TW3MASTER","TW3_COD"   ) 
Local cFilTGYAtd  := xFilial("TGY",cFilMov)
Local cFilTGYSub  := xFilial("TGY",cFilSub)
Local cAliasAtend := GetNextAlias()
Local cAliasSub   := GetNextAlias()
Local nLinhas     := 0
Local nLinNova    := 1
Local lRet        := .T.
Local dDtFimAtend := Ctod("")
Local dDtFimSub   := Ctod("")
Local cTFFAtend   := ""
Local cTFFSub     := ""
Local oMdlTroca1  := Nil
Local oMdlTroca2  := Nil
Local cTDXAtend   := ""
Local cTDXSub     := ""
Local aManut1     := {}
Local aManut2     := {}
Local aManut3     := {}
Local aManut4     := {}

Default aCodTFF   := {}

DbSelectArea("TFF")
TFF->(DbSetOrder(1)) //TFF_FILIAL+TFF_COD

/*/
	Etapa 1 - Inverter TGY entre os funcionários envolvidos
/*/
BeginSql Alias cAliasAtend
	SELECT TGY.TGY_CODTFF, TGY.TGY_CODTDX, TGY.R_E_C_N_O_ RECNOTGY
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL = %Exp:cFilTGYAtd%
	AND TGY.TGY_ATEND    = %Exp:cCodAtend%
	AND %Exp:dDtMov% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM
	AND TGY.%NotDel%
	ORDER BY %Order:TGY%
EndSql

(cAliasAtend)->(DbGoTop())

BeginSql Alias cAliasSub
	SELECT TGY.TGY_CODTFF, TGY.TGY_CODTDX, TGY.R_E_C_N_O_ RECNOTGY
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL = %Exp:cFilTGYSub%
	AND TGY.TGY_ATEND    = %Exp:cCodSub%
	AND %Exp:dDtMov% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM
	AND TGY.%NotDel%
	ORDER BY %Order:TGY%
EndSql

(cAliasSub)->(DbGoTop())

If (cAliasAtend)->(!Eof()) .AND. (cAliasSub)->(!Eof())

	oMdlTroca1  := FwLoadModel("TECA580E")
	cTFFAtend   := (cAliasAtend)->TGY_CODTFF
	cTDXAtend   := (cAliasAtend)->TGY_CODTDX
		
	lRet        := lRet .And. AtTrocaTGY(oMdlTroca1, cFilMov, cTFFAtend,cCodAtend, cTDXAtend, cCodSub, dDtMov, @dDtFimAtend, cCodTW3)

	If lRet
		oMdlTroca2 := FwLoadModel("TECA580E")
		cTFFSub    := (cAliasSub)->TGY_CODTFF
		cTDXSub    := (cAliasSub)->TGY_CODTDX
				
		lRet       := lRet .And. AtTrocaTGY(oMdlTroca2, cFilSub, cTFFSub ,cCodSub, cTDXSub, cCodAtend, dDtMov, @dDtFimSub, cCodTW3)
	EndIf
	
	If lRet
		
		// Troca as agendas do atendente posicionado pelo substituto
		AtTrocaABB(cFilMov, cTFFAtend, dDtMov, dDtFimAtend, cCodSub)
		
		// Troca as agendas do atendente substituto pelo posicionado
		AtTrocaABB(cFilSub, cTFFSub  , dDtMov, dDtFimSub, cCodAtend)

	EndIf
	
	(cAliasAtend)->(DbCloseArea())
	(cAliasSub)->(DbCloseArea())
Else
	lRet := .F.	
EndIf

RestArea( aArea )
RestArea( aAreaABB )
RestArea( aAreaTFF )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtTrocaTGY
Função que executa um subprocesso da AtTrocaFunc, que é responsável por fazer a troca dos postos (TGY) entre os funcionários selecionados. 

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtTrocaTGY( oModel, cFilMov, cCodTFF, cCodAtend, cCodTDX, cCodSub, dDtMov, dDtFim, cCodTW3 )
Local dDtFimNew := Ctod("") // Armazena a nova data final para a TGY, que será aplicado ao posto anterior à troca.
Local oMdlAloc  := Nil
Local cEscala   := ""
Local cTurno    := ""
Local cSeq      := ""
Local nGrupo    := 0
Local cNewTDX   := ""
Local cTipAlo   := ""
Local cCodTW3	:= ""
Local aAlocEsc  := {}
Local nX        := 0
Local nLinhas   := 0
Local nLinNova  := 0
Local lRet      := .T.
Local cFil      := FwxFilial("TGY",cFilMov)
Local dUltAlo   := Ctod("")

If TFF->(DbSeek(FwxFilial("TFF",cFilMov) + cCodTFF))
	
	oModel:SetOperation(MODEL_OPERATION_UPDATE)
	oModel:Activate()
	oMdlAloc := oModel:GetModel("TGYDETAIL")
	For nX := 1 To oMdlAloc:Length()
		oMdlAloc:GoLine(nX)
		If lRet .AND. !oMdlAloc:IsDeleted() .AND. cCodAtend == oMdlAloc:GetValue("TGY_ATEND") .AND.;
		   (dDtMov  >= oMdlAloc:GetValue("TGY_DTINI") .AND. dDtMov <= oMdlAloc:GetValue("TGY_DTFIM")) .AND.;
		    cCodTDX == oMdlAloc:GetValue("TGY_CODTDX")
		   
			cEscala := oMdlAloc:GetValue("TGY_ESCALA")
			cNewTDX := oMdlAloc:GetValue("TGY_CODTDX")
			cTurno  := oMdlAloc:GetValue("TGY_TURNO" )
			cSeq    := oMdlAloc:GetValue("TGY_SEQ"   )
			dDtFim  := oMdlAloc:GetValue("TGY_DTFIM" )
			nGrupo  := oMdlAloc:GetValue("TGY_GRUPO" )
			cTipAlo := oMdlAloc:GetValue("TGY_TIPALO")
			
			nLinhas  := oMdlAloc:Length()
			If nLinhas > 1
				/*/ 
					A data final do alocação anterior à troca deverá ser de um dia antes da movimentação. 
					Porém, caso a data da movimentação seja anterior à data de início do posto, será assumida a data inicial do posto.
				/*/
				dDtFimNew    := dDtMov-1
				
				// Caso a data final seja menor do que a data inicial, significa que o atendente foi efetivado no mesmo dia da movimentação.
				If !(dDtFimNew < oMdlAloc:GetValue("TGY_DTINI"))
					oMdlAloc:SetValue("TGY_ULTALO",dDtFimNew)
					oMdlAloc:SetValue("TGY_DTFIM" ,dDtFimNew)
					nLinNova := oMdlAloc:AddLine()
					If nLinNova <= nLinhas 
						lRet := .F.
					EndIf
				EndIf
			Else
				nLinNova := nLinhas
			EndIf
			
			If lRet
				aAlocEsc := {}
				Aadd(aAlocEsc, cFil                      ) //"TGY_FILIAL"
				Aadd(aAlocEsc, cEscala                   ) //"TGY_ESCALA"
				Aadd(aAlocEsc, cNewTDX                   ) //"TGY_CODTDX"
				Aadd(aAlocEsc, At336TGYIt(cFil, cCodTFF) ) //"TGY_ITEM"
				Aadd(aAlocEsc, cCodSub                   ) //"TGY_ATEND"
				Aadd(aAlocEsc, cTurno                    ) //"TGY_TURNO"
				Aadd(aAlocEsc, cSeq                      ) //"TGY_SEQ"
				Aadd(aAlocEsc, dDtMov                    ) //"TGY_DTINI"
				Aadd(aAlocEsc, dDtFim                    ) //"TGY_DTFIM"
				Aadd(aAlocEsc, cCodTFF                   ) //"TGY_CODTFF"
				Aadd(aAlocEsc, nGrupo                    ) //"TGY_GRUPO"
				Aadd(aAlocEsc, cTipAlo                   ) //"TGY_TIPALO"
				Aadd(aAlocEsc, cCodTW3                   ) //"TGY_CODTW3"				
				
				dUltAlo := Ctod("")//dDtMov // Como as agendas já estão criadas, crio o novo registro de TGY com o campo ULTALO já preenchido.
				
				lRet := At336GrTGY(oModel,oMdlAloc, "TGY", aAlocEsc, dUltAlo)
				If lRet
					Exit
				EndIf
			EndIf
		EndIf
	Next nX
	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtTrocaABB
Função que executa o subprocesso da AtTrocaFunc responsável por fazer a troca das agendas entre os funcionários selecionados.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtTrocaABB(cFilMov, cCodTFF, dDtIni, dDtFim, cCodSub)
Local aArea     := GetArea()
Local cAliasQry := GetNextAlias()
Local cFilABQ   := xFilial("ABQ",cFilMov)
Local cFilTDV   := xFilial("TDV",cFilMov)
Local cFilABB   := xFilial("ABB",cFilMov)

DbSelectArea("ABB")
	
BeginSql Alias cAliasQry
	SELECT ABB.R_E_C_N_O_ AS RECNOABB
	FROM %table:ABB% ABB
	INNER JOIN  %table:ABQ% ABQ ON 
		  ABQ.ABQ_FILIAL     = %Exp:cFilABQ%
		  AND ABQ.ABQ_CODTFF = %Exp:cCodTFF%
		  AND ABQ.%notDel%
  	INNER JOIN %Table:TDV% TDV ON
		  TDV.TDV_FILIAL     = %Exp:cFilTDV%
		  AND TDV.TDV_CODABB = ABB.ABB_CODIGO 
		  AND TDV.TDV_DTREF  BETWEEN %Exp:Dtos(dDtIni)% AND %Exp:Dtos(dDtFim)%
		  AND TDV.%NotDel%
	WHERE ABB.ABB_FILIAL     = %Exp:cFilABB%
		  AND ABB.ABB_IDCFAL = ABQ_CONTRT || ABQ_ITEM || ABQ_ORIGEM
		  AND ABB.%NotDel%
	ORDER BY %Order:ABB%
EndSql
	
(cAliasQry)->(DbGoTop())

While (cAliasQry)->(!EOF())
	ABB->(DbGoTo((cAliasQry)->RECNOABB))
	Reclock("ABB",.F.)
	ABB->ABB_CODTEC := cCodSub
	ABB->(MsUnlock())
	(cAliasQry)->(DbSkip())
EndDo

(cAliasQry)->(DbCloseArea())

RestArea( aArea )

Return

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336GrTGY
Utiliza o modelo de dados do TECA580E para fazer a gravação das tabelas TGY e TGZ, 
sendo que deve ser passado um model do TECA580E ativo para o correto funcionamento da rotina.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336GrTGY(oModel, oMdlAloc, cTabela, aAlocEsc, dUltAlo, lMV_GSGEHOR)
Local lRet       := .T.
Local aErro      := {}
Local cFilAtend  := aAlocEsc[1]
Local cEscala    := aAlocEsc[2]
Local cCodTDX    := aAlocEsc[3]
Local nItem      := aAlocEsc[4]
Local cCodAtend  := aAlocEsc[5]
Local cTurno     := aAlocEsc[6]
Local cSeq       := aAlocEsc[7]
Local dDtMov     := aAlocEsc[8]
Local dDtFim     := aAlocEsc[9]
Local cCodTFF    := aAlocEsc[10]
Local nGrupo     := aAlocEsc[11]
Local cTipAlo    := aAlocEsc[12]
Local cCodTW3    := Iif(cTabela == "TGY" , aAlocEsc[13] , "")
Local cEntra1	 	:= ""
Local cSaida1    	:= ""
Local cEntra2	 	:= ""
Local cSaida2    	:= ""
Local cEntra3	 	:= ""
Local cSaida3    	:= ""
Local cEntra4	 	:= ""
Local cSaida4    	:= ""
Local cHrEmpty		:= "  :  "

Default oModel   := Nil
Default cTabela  := ""
Default dUltAlo  := Ctod("")
Default lMV_GSGEHOR := .F.

If ValType(oModel) == "O" 
	
	If cTabela == "TGY"
		If lMV_GSGEHOR
			cEntra1	 := aAlocEsc[14]
			cSaida1  := aAlocEsc[15]
			cEntra2	 := aAlocEsc[16]
			cSaida2  := aAlocEsc[17]
			cEntra3	 := aAlocEsc[18]
			cSaida3  := aAlocEsc[19]
			cEntra4	 := aAlocEsc[20]
			cSaida4  := aAlocEsc[21]
		Endif

	EndIf

	oMdlAloc:SetValue(  cTabela+"_FILIAL", cFilAtend )
	oMdlAloc:SetValue(  cTabela+"_ESCALA", cEscala   )
	oMdlAloc:SetValue(  cTabela+"_CODTDX", cCodTDX   )
	oMdlAloc:SetValue(  cTabela+"_ITEM"  , nItem     )
	oMdlAloc:SetValue(  cTabela+"_ATEND" , cCodAtend )
	oMdlAloc:SetValue(  cTabela+"_TURNO" , cTurno    )
	oMdlAloc:SetValue(  cTabela+"_SEQ"   , cSeq      )
	oMdlAloc:SetValue(  cTabela+"_DTINI" , dDtMov    )
	oMdlAloc:SetValue(  cTabela+"_DTFIM" , dDtFim    )
	oMdlAloc:SetValue(  cTabela+"_CODTFF", cCodTFF   )
	oMdlAloc:SetValue(  cTabela+"_GRUPO" , nGrupo    )
	If cTabela == "TGY"
		oMdlAloc:SetValue("TGY_TIPALO", cTipAlo )
		oMdlAloc:SetValue("TGY_CODTW3", cCodTW3 )
		oMdlAloc:SetValue("TGY_ULTALO", dUltAlo )

		If lMV_GSGEHOR .And. lWhenHora
			If !Empty(cEntra1) .And. cEntra1 <> cHrEmpty
				oMdlAloc:SetValue("TGY_ENTRA1", cEntra1 )
			Endif

			If !Empty(cSaida1) .And. cSaida1 <> cHrEmpty
				oMdlAloc:SetValue("TGY_SAIDA1", cSaida1 )
			Endif

			If !Empty(cEntra2) .And. cEntra2 <> cHrEmpty
				oMdlAloc:SetValue("TGY_ENTRA2", cEntra2 )
			Endif

			If !Empty(cSaida2) .And. cSaida2 <> cHrEmpty
				oMdlAloc:SetValue("TGY_SAIDA2", cSaida2 )
			Endif

			If !Empty(cEntra3) .And. cEntra3 <> cHrEmpty
				oMdlAloc:SetValue("TGY_ENTRA3", cEntra3 )
			Endif

			If !Empty(cSaida3) .And. cSaida3 <> cHrEmpty
				oMdlAloc:SetValue("TGY_SAIDA3", cSaida3 )
			Endif	

			If !Empty(cEntra4) .And. cEntra4 <> cHrEmpty
				oMdlAloc:SetValue("TGY_ENTRA4", cEntra4 )
			Endif

			If !Empty(cSaida4) .And. cSaida4 <> cHrEmpty
				oMdlAloc:SetValue("TGY_SAIDA4", cSaida4 )	
			Endif
		Endif

	EndIf
	
	lRet := oModel:VldData()
	If ( lRet )											
		lRet := oModel:CommitData()//Grava Model
	Else
		aErro   := oModel:GetErrorMessage()						
		Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
	EndIf

EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtTW5Grv
Função responsável pela gravação das situações que realizam manutenções ou cancelamento de agendas. 
A gravação da TW5 é feita apenas quando essa manutenção indicar uma ausência, que o caso das faltas, reciclagem, curso e folga.

@author Leandro Dourado 
@version 12.1.14
@since 02/12/2016
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Function AtTW5Grv(oMdlTW3,cSituacao)
Local aRows     := FwSaveRows()
Local aArea     := GetArea()
Local oMdlABB   := oMdlTW3:GetModel("ABBDETAIL")
Local nOper550  := 0
Local lCancFut  := cSituacao $ SIT_MOV_CANCADISPEMP + "|" + SIT_MOV_RETRECI + "|" + SIT_MOV_RETCURS + "|" + SIT_MOV_RECOLHE + "|" + SIT_MOV_FALTAAB + "|" + SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" +  SIT_MOV_CANCFT // Indica se haverá cancelamento de agendas futuras.
Local lRet      := .T.

Local cAliasQry := ""
Local cCodAtend := oMdlTW3:GetValue( "TW3MASTER","TW3_ATDCOD" )
Local dDataMov  := oMdlTW3:GetValue( "TW3MASTER","TW3_DTMOV"  )
Local cFilSub   := oMdlTW3:GetValue( "TW3MASTER","TW3_TECFIL" )
Local cCodSub   := oMdlTW3:GetValue( "TW3MASTER","TW3_TECSUB" )
Local cHrIniSub := oMdlTW3:GetValue( "TW3MASTER","TW3_SUBINI" )
Local cFilMov   := oMdlTW3:GetValue( "TW3MASTER","TW3_FILIAL" )
Local cCodTW3		:= oMdlTW3:GetValue( "TW3MASTER","TW3_COD"    )
Local cIdcFal   := ""
Local cTpLanc   := ""
Local cMotivo   := ""
Local nX        := 0
Local aRecnos   := {}
Local nRecTW5   := 0
Local cCodABB   := ""
Local aAgenda   := {}
Local lAltHora  := .F. // Indica se o sistema deverá exigir a alteração da hora de entrada e/ou saída.
Local lGravaTW5 := .T.
Local aErro     := {}
Local oMdlTW5   := Nil
Local cNovoEfet := ""  // Quando é feito o recolhimento e o usuário deseja que o substituto se torne efetivo, essa variavel será preenchida     
Local cCodTFF   := ""
Local cCodTDX   := ""

If cSituacao $ SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB
	cTpLanc := "1" // Falta
ElseIf cSituacao == SIT_MOV_RECICLA 
	cTpLanc := "2" // Reciclagem
ElseIf cSituacao == SIT_MOV_CURSO 
	cTpLanc := "3" // Curso
ElseIf cSituacao == SIT_MOV_FOLGA 
	cTpLanc := "4" // Lançamento de Folga
ElseIf cSituacao == SIT_MOV_ADISPEMP
	cTpLanc := "8" // A disposição da empresa
EndIf

If Empty(cTpLanc)
	lGravaTW5 := .F.
EndIf

If lGravaTW5
	DbSelectArea("TW5")
	oMdlTW5 := FwLoadModel("TECA336A")
	oMdlTW5:SetOperation(MODEL_OPERATION_INSERT)
	oMdlTW5:Activate()
	
	oMdlTW5:SetValue("TW5MASTER","TW5_FILIAL", FwxFilial("TW5")           )
	oMdlTW5:SetValue("TW5MASTER","TW5_COD"   , GetSxeNum("TW5","TW5_COD") )
	oMdlTW5:SetValue("TW5MASTER","TW5_ATDCOD", cCodAtend                  )
	oMdlTW5:SetValue("TW5MASTER","TW5_TPLANC", cTpLanc                    )
	oMdlTW5:SetValue("TW5MASTER","TW5_DTINI" , dDataMov                   )
	oMdlTW5:SetValue("TW5MASTER","TW5_CODTW3", cCodTW3                    )
	
	If cSituacao $ SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO  + '|' + SIT_MOV_FALTAAB // Reciclagem/Curso/Falta abonada
		oMdlTW5:SetValue("TW5MASTER","TW5_DTFIM" , oMdlTW3:GetValue("TW3MASTER","TW3_ADTFIM"))
	ElseIf cSituacao <> SIT_MOV_FALTA
		oMdlTW5:SetValue("TW5MASTER","TW5_DTFIM" , dDataMov )
	EndIf
	
	lRet := oMdlTW5:VldData()
	
	If lRet
		oMdlTW5:CommitData()
		TW5->(ConfirmSX8())
	Else
		aErro   := oMdlTW5:GetErrorMessage()	
		Help( ,, 'TW5GRV',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
		TW5->(RollBackSX8())
	EndIf
EndIf

If lRet
	
	If lCancFut
		// Obtem todas as agendas que deverão ser canceladas, para as situações Curso, Reciclagem e Recolhimento.
		aAgenda := AtGetAgendas( oMdlAbb,oMdlTW3,@cIdcFal,cSituacao ) 
	Else
		For nX := 1 To oMdlABB:Length()
			oMdlABB:GoLine(nX)
			aAdd(aAgenda,{oMdlABB:GetValue("ABB_CODIGO"),;
					 	  oMdlABB:GetValue("ABB_DTINI") ,;
						  oMdlABB:GetValue("ABB_HRINI") ,;
						  oMdlABB:GetValue("ABB_DTFIM") ,;
						  oMdlABB:GetValue("ABB_HRFIM")} )
		Next nX
	EndIf
	
	/*
		Gravação da tabela de Manutenções de Agenda (ABR).
	*/
	If Len(aAgenda) > 0
	
		If (cSituacao $ SIT_MOV_CANCADISPEMP + "|" + SIT_MOV_RETRECI + "|" + SIT_MOV_RETCURS) .Or. (cSituacao $ SIT_MOV_RECOLHE + "|" + SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" + SIT_MOV_CANCFT .And. !At336AltAg()) //Recolhimento
			cMotivo := SuperGetMv("MV_ATMTCAN",,"")
		Elseif cSituacao == SIT_MOV_FOLGA
			cMotivo := SuperGetMv("MV_ATMTFOL",,"")
		ElseIf cSituacao $ SIT_MOV_SAIDANT + "|" + SIT_MOV_RECOLHE// Saida antecipada
			cMotivo := SuperGetMv("MV_ATMTSAN",,"")
		ElseIf cSituacao $ SIT_MOV_HORAEXT + '|' + cListHE // Hora Extra
			Pergunte("AT336HREXT")
			cMotivo := MV_PAR01
			If Empty(cMotivo)
				lRet := .F.
				Help( ,, 'AT336HREXT',, STR0097, 1, 0 ) //"Informe um motivo de manutenção do tipo hora extra!"
			EndIf
		ElseIf cSituacao == SIT_MOV_ATRASO // Atraso
			cMotivo := SuperGetMv("MV_ATMTATR",,"")
		ElseIf cSituacao == SIT_MOV_JORNDIF
			cMotivo := SuperGetMv("MV_ATMTJDF",,"")
		Elseif cSituacao == SIT_MOV_RECICLA
			cMotivo := SuperGetMv("MV_ATMTREC",,"")
		Elseif cSituacao == SIT_MOV_CURSO
			cMotivo := SuperGetMv("MV_ATMTCUR",,"")		
		Elseif cSituacao == SIT_MOV_ADISPEMP
			cMotivo := SuperGetMv("MV_ATMTDSP",,"")		
		Else
			cMotivo := SuperGetMv("MV_ATMTFAL",,"")
		EndIf
		
		If (cSituacao $ SIT_MOV_SAIDANT +"|"+ SIT_MOV_HORAEXT +"|"+ SIT_MOV_ATRASO +"|"+ SIT_MOV_JORNDIF + '|' + cListHE) .Or. (cSituacao $ SIT_MOV_RECOLHE + "|" + SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" + SIT_MOV_CANCFT.And. At336AltAg())
			lAltHora := .T.
		EndIf
		
		If !Empty(cFilSub) .AND. !Empty(cCodSub)
		
			lRet := lRet .AND. At336CanAgenda(cFilSub, cCodSub, dDataMov, "2")
			
			If lRet .And. cSituacao == SIT_MOV_RECOLHE .And. AllTrim(cFilMov) == AllTrim(cFilSub) .And. !IsBlind()
				If MsgYesNo(STR0098,STR0037) //"Deseja tornar o substituto efetivo deste posto? Caso contrário, ele fará a cobertura apenas para a data da movimentação!"###"Atenção!"
					cNovoEfet := cCodSub
					cCodSub   := ""
				EndIf
			Endif
			
		EndIf
		
		// Chamada da função responsável pela gravação da tabela ABR através da utilização do modelo de dados do TECA550
		lRet := lRet .And. At336GrABR( aAgenda, cMotivo , dDataMov , cFilSub,;
		                               cCodSub, lAltHora, cHrIniSub, .F.    ,;
		                               Nil    , cFilMov , cCodTW3            )
		
	EndIf
	
	If lRet .AND. cSituacao $ SIT_MOV_CANCADISPEMP + "|" + SIT_MOV_RETRECI + "|" + SIT_MOV_RETCURS + "|" + SIT_MOV_RECOLHE + "|" + SIT_MOV_RECREFORCO + "|" + SIT_MOV_CANCFTREF + "|" + SIT_MOV_CANCFT
		
		If !Empty(cIDcFal)
			
			lRet := At336RecTGY(cIDcFal, cCodAtend , dDataMov, @cCodTFF, @cCodTDX)
			
			lRet := lRet .And. At581Alt(cCodTFF,cCodTDX,cCodAtend)

			If lRet .And. !Empty(cNovoEfet)
				lRet := At336Efetiva( cNovoEfet, dDataMov, cCodTFF, cCodTDX, "06" )
			EndIf
		Else
			lRet := .F.
			Help( ,, 'AT336RECOLHE',, STR0099, 1, 0 ) //"Esse atendente deve estar vinculado a um posto como efetivo!"
		Endif
	EndIf
	
EndIf

RestArea( aArea )
FwRestRows( aRows )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtRetFalta
Faz a gravação do retorno de falta e cancelamento de folga. Caso o atendente posicionado esteja com falta ou folga no dia da movimentação, essa falta ou folga será estornada.

@author Leandro Dourado 
@version 12.1.14
@since 02/12/2016
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtRetFalta(oMdlTW3,cSit)
Local oMdlTW5   := FwLoadModel("TECA336A")
Local lRet      := .F.
Local nRecTW5   := 0
Local aErro     := {}
Local aManut    := {}
Local cMotivo   := SuperGetMv("MV_ATMTFAL",,"")
Local cFilMov   := oMdlTW3:GetValue("TW3MASTER","TW3_FILIAL")
Local cCodAtend := oMdlTW3:GetValue("TW3MASTER","TW3_ATDCOD")
Local dDtMov    := oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV")
Local cFilSub   := "" 
Local cCodSub   := ""
Local cMotSub   := ""
Local cTpLanc	:= ""
Default cSit	:= "1"

If cSit == "1"
	cTpLanc := "1"
Elseif cSit == "2"
	cMotivo := SuperGetMv("MV_ATMTFOL",,"")
	cTpLanc := "4"
Endif

If !Empty(cTpLanc)
	DbSelectArea("TW5")
	
	nRecTW5 := AtChkFalta(cCodAtend,oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV"),cTpLanc)
	If !Empty(nRecTW5)
		TW5->(DbGoTo(nRecTW5))
		
		If TW5->TW5_DTINI == dDtMov
			oMdlTW5:SetOperation(MODEL_OPERATION_DELETE)
		Else
			oMdlTW5:SetOperation(MODEL_OPERATION_UPDATE)
		EndIf
		oMdlTW5:Activate()
		
		If oMdlTW5:GetOperation() <> MODEL_OPERATION_DELETE
			oMdlTW5:SetValue("TW5MASTER","TW5_DTFIM", oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV")-1)
		EndIf
		
		lRet := oMdlTW5:VldData()
	
		If lRet
			lRet := oMdlTW5:CommitData()
			TW5->(ConfirmSX8())
			
			lRet := AtDesfazManut( cCodAtend, dDtMov, cMotivo )
			
		Else
			aErro   := oMdlTW5:GetErrorMessage()						
			Help( ,, 'TW5GRV',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
			TW5->(RollBackSX8())
		EndIf
	EndIf
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336GrABR
Faz a geração das manutenções de agenda (ABR), através do modelo de dados do TECA550.
É necessário setar uma query já pronta das agendas (ABB), através do At550StAls(), para que o TECA550 consiga fazer as manutenções.

@author Leandro Dourado 
@version 12.1.14
@since 05/12/2016
@return oModel
@obs 
@sample
/*/
//------------------------------------------------------------------------------
Function At336GrABR( aAgenda  , cMotivo , dDtMov   , cFilSub   ,;
                     cCodSub  , lAltHora, cHrIniSub, lCobertura,;
                     cAliasQry, cFilMov , cCodTW3  , lCancCob)
                     
Local aAreaABB     := ABB->(GetArea())
Local nX           := 0
Local oMdl550      := Nil
Local nOper550     := 0
Local cCodAbb      := ""
Local lRet         := .T.
Local cFiltro      := ""
Local nRecABB      := 0
Local aErro        := {}
Local aAtend       := {}
Local cHoraIni     := ""
Local cHoraFim     := ""
Local lGeraABR     := .T.
Local nRecnoABR    := 0
Local cAliasAux    := ""
Local cFilABB      := ""
Local cFilABR      := ""
Local cFilOld      := ""

Default cCodSub    := ""
Default lAltHora   := .F.
Default cHrIniSub  := ""
Default lCobertura := .F.
Default cAliasQry  := ""
Default cFilMov    := ""
Default cCodTW3    := ""	
Default lCancCob   := .F.

If !Empty(cFilMov)
	cFilABB := FwxFilial("ABB",cFilMov)
	cFilABR := FwxFilial("ABR",cFilMov)
	cFilOld := cFilAnt
	cFilAnt := cFilMov
Else
	cFilABB := FwxFilial("ABB")
	cFilABR := FwxFilial("ABR")
EndIf

If !Empty(cAliasQry)
	cAliasAux := cAliasABB
	cAliasABB := cAliasQry
EndIf

If !Empty(cHrIniSub) .And. cHrIniSub <> "  :  " 
	cHrIniCob := cHrIniSub 
Else
	cHrIniCob := ""
EndIf

DbSelectArea("ABB")
ABB->(DbSetOrder(8)) //ABB_FILIAL+ABB_CODIGO

DbSelectArea("ABR")
ABR->(DbSetOrder(1)) //ABR_FILIAL+ABR_AGENDA+ABR_MOTIVO

For nX := 1 To Len(aAgenda)
	If lRet
		cCodABB  := aAgenda[nX,1]
		lGeraABR := .T.
		
		If lRet .AND. ABB->(DbSeek(cFilABB+cCodABB))
			
			If lAltHora .And. Len(aAgenda[nX]) > 1
				cHoraIni := aAgenda[nX,3]
				cHoraFim := aAgenda[nX,5]
				
				lGeraABR := cHoraIni <> ABB->ABB_HRINI .OR. cHoraFim <> ABB->ABB_HRFIM
			EndIf
			
			If lGeraABR
				nRecABB   := ABB->(Recno())
				If lCobertura
					nRecnoABR := aAgenda[nX,6]
					ABR->( DbGoTo(nRecnoABR) )
					
					nOper550 := MODEL_OPERATION_UPDATE
				Else
					If ABR->(DbSeek(cFilABR+cCodABB+cMotivo))
						nOper550 := MODEL_OPERATION_UPDATE
					Else
						nOper550 := MODEL_OPERATION_INSERT
					EndIf
				EndIf
				
				cFiltro := "R_E_C_N_O_ == "+cValToChar(nRecABB)
				
				DbSelectArea(cAliasABB)
				(cAliasABB)->(DbSetFilter({||&cFiltro},cFiltro))
				(cAliasABB)->(DbGoTop())
				
				If (cAliasABB)->(!EOF())
					At550StAls(cAliasABB) // Seta alias temporário da ABB para ser utilizado no TECA550
					oMdl550 := FwLoadModel("TECA550")
					oMdl550:SetOperation(nOper550)
					oMdl550:Activate()
					
					If !lCancCob

						oMdl550:SetValue("ABRMASTER","ABR_CODTW3", cCodTW3 )
						
						If AT550When( oMdl550, "ABR_MOTIVO" )
							oMdl550:SetValue("ABRMASTER","ABR_MOTIVO", cMotivo )
						EndIf
						
						If AT550When( oMdl550, "ABR_USASER" )
							oMdl550:SetValue("ABRMASTER","ABR_USASER", "2" )
						EndIf
					Endif 					
					
					If (!Empty(cFilSub) .Or. lCancCob) .AND. AT550When( oMdl550, "ABR_FILSUB" )
						oMdl550:SetValue("ABRMASTER","ABR_FILSUB", cFilSub )
					EndIf
					
					If (!Empty(cCodSub) .Or. lCancCob) .AND. AT550When( oMdl550, "ABR_CODSUB" )
						oMdl550:SetValue("ABRMASTER","ABR_CODSUB", cCodSub )
					EndIf
					
					If Len(aAgenda[nX]) > 1 .And. !lCancCob
						If AT550When( oMdl550, "ABR_DTINI" )
							oMdl550:SetValue("ABRMASTER", "ABR_DTINI", aAgenda[nX,2])
						EndIf
						
						If AT550When( oMdl550, "ABR_HRINI" )
							oMdl550:SetValue("ABRMASTER", "ABR_HRINI", aAgenda[nX,3])
						EndIf	
							
						If AT550When( oMdl550, "ABR_DTFIM" )		
							oMdl550:SetValue("ABRMASTER", "ABR_DTFIM", aAgenda[nX,4])
						EndIf
						
						If AT550When( oMdl550, "ABR_HRFIM" )
							oMdl550:SetValue("ABRMASTER", "ABR_HRFIM", aAgenda[nX,5])
						EndIf
					EndIf
					
					lRet := oMdl550:VldData()
					If ( lRet )	
						lRet := oMdl550:CommitData() //Grava Model
						If lRet .AND. !Empty(cHrIniCob)
							cHrIniCob := "" 
						EndIf
					Else
						aErro   := oMdl550:GetErrorMessage()						
						Help( "",1, 'AT336GRABR',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )
					EndIf
					oMdl550:Deactivate()
					
				EndIf
			EndIf
		EndIf
	EndIf
Next nX

If !Empty(cAliasQry)
	cAliasABB := cAliasAux
EndIf

If lRet
	aAtend := At550Atend()

	If Len( aAtend ) > 0
		At550FilCt(aAtend)
	EndIf
Endif

If !Empty(cFilOld)
	cFilAnt := cFilOld
EndIf

RestArea( aAreaABB )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtDesfazManut
Desfaz manutenções que tenham cancelado agendas do atendente informado.
Caso exista um atendente realizando a cobertura da agenda, suas manutenções de cancelamento serão desfeitas também, assim ele retornará para a reserva.

@author Leandro Dourado
@since 27/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtDesfazManut( cCodAtend, dDtMov, xMotivo, aManut, aManutSub, lChkReserv, cTip )
Local lRet         := .T.
Local cCodSub      := ""
Local cMotSub      := ""

Default xMotivo    := Nil //Caso o Motivo seja passado como nulo, ele deverá ser passado para a função GetABBInativas como nulo também.
Default aManut     := {}
Default aManutSub  := {}
Default lChkReserv := .T.
Default cTip	   := "2"

// Busca 
If Empty(aManut)
	aManut := GetABBInativas( cCodAtend, dDtMov, dDtMov, Nil, xMotivo, lChkReserv, cTip )
Endif
		
If Len(aManut) > 0
	lRet := At336DelABR( aManut, @cCodSub )
	
	// Caso haja um substituto e o usuário tenha decidido dar o retorno da falta, reativa as agendas do substituto em seu posto de reserva.
	If lRet .And. !Empty(cCodSub)
		cMotSub   := SuperGetMv("MV_ATMTCAN",,"")
		aManutSub := GetABBInativas( cCodSub, dDtMov, dDtMov, Nil, cMotSub )
		
		If Len(aManutSub) > 0
			lRet := At336DelABR( aManutSub, cCodSub )
		EndIf
	EndIf
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336DelABR
Subprocesso da função AtDesfazManut, utilizada para exclusão de registros da ABR, através do modelo de dados do TECA550.

@author Leandro Dourado 
@version 12.1.14
@since 05/12/2016
@return oModel
@obs 
@sample
/*/
//------------------------------------------------------------------------------
Function At336DelABR( aManut, cCodSub )
Local aAreaABR   := ABR->(GetArea())
Local nX         := 0
Local nOper550   := 0
Local cCodAbb    := ""
Local cNomeSub   := ""
Local cMotivo    := ""
Local lRet       := .T.
Local aErro      := {}
Local oMdl550    := Nil

Default cCodSub  := ""

DbSelectArea("ABR")
ABR->(DbSetOrder(1)) //ABR_FILIAL+ABR_AGENDA+ABR_MOTIVO

For nX := 1 To Len(aManut)
	cCodABB := aManut[nX,1]
	cMotivo := aManut[nX,2]
	
	If ABR->(DbSeek( FwxFilial("ABR")+cCodABB+cMotivo ))
		
		If !Empty(ABR->ABR_CODSUB) .AND. AllTrim(cCodSub) <> AllTrim(ABR->ABR_CODSUB)
			cCodSub := ABR->ABR_CODSUB
			If !Empty(cCodSub)
				
				cNomeSub := Posicione("AA1",1,xFilial("AA1")+cCodSub,"AA1_NOMTEC")
				lRet := MsgYesNo(STR0100 + AllTrim(cCodSub) + " - " + AllTrim(cNomeSub) + ; //"O atendente "
				                 STR0101                                                 ,; //" já foi alocado para realizar a cobertura desse posto! Deseja confirmar a operação?"
				                 STR0037 )                                                  //"Atenção!"
			EndIf
		EndIf
		
		If lRet
			oMdl550 := FwLoadModel("TECA550")
			At550StAls(cAliasABB) // Seta alias temporário da ABB para ser utilizado no TECA550
			oMdl550:SetOperation(MODEL_OPERATION_DELETE)
			oMdl550:Activate()
					
			lRet := oMdl550:VldData()
			
			If ( lRet )	
				lRet := oMdl550:CommitData()//Grava Model
			Else
				aErro   := oMdl550:GetErrorMessage()						
				Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )				
			EndIf
			
			oMdl550:Deactivate()
		Else
			Help( ,, 'Help',, STR0102, 1, 0 ) //"Operação cancelada pelo usuário!"
		EndIf
	EndIf
Next nX

RestArea( aAreaABR )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtChkFalta
Função utilizada na situação de retorno de falta, que executa query para avaliar se o atendente possui um registro de falta em aberto.

@author Leandro Dourado 
@version 12.1.14
@since 05/12/2016
@return oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtChkFalta(cCodAtend,dDtMov,cTpLanc)
Local aArea       := GetArea()
Local nRecTW5     := 0
Local cAliasQry   := GetNextAlias()
Local cChvTW5     := ""
Default cTpLanc	  := "1"

BeginSql Alias cAliasQry
	SELECT TW5.R_E_C_N_O_ RECNOTW5
	FROM %table:TW5% TW5
	WHERE TW5.TW5_FILIAL = %xFilial:TW5%
	AND ( %Exp:dDtMov% BETWEEN TW5.TW5_DTINI AND TW5_DTFIM
	OR  TW5.TW5_DTFIM    = '' ) 
	AND TW5.TW5_ATDCOD   = %Exp:cCodAtend%
	AND TW5.TW5_TPLANC   = %Exp:cTpLanc%
	AND TW5.%NotDel%
	ORDER BY %Order:TW5%
EndSql

DbSelectArea(cAliasQry)
(cAliasQry)->(DbGoTop())
If (cAliasQry)->(!Eof())
	nRecTW5 := (cAliasQry)->RECNOTW5
EndIf
(cAliasQry)->(DbCloseArea())

RestArea(aArea)

Return nRecTW5

//------------------------------------------------------------------------------
/*/{Protheus.doc} At335When
Avalia quais campos deverão ser habilitados, de acordo com a situação de movimentação informada.

@author Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since 07/10/2016
@return lRet , Logico, Retorna se permite a edição do campo.
/*/
//------------------------------------------------------------------------------
Function At335When( cCampo, lAgenda)  
Local oModel    := FwModelActive()
Local lRet      := .F.
Local cSituacao := AllTrim(oModel:GetValue("TW3MASTER","TW3_SITCOD"))
Local cAgrup    := ""
Local lItCob    := .F. // Indica se o campo de posto de cobertura será habilitado.

Default cCampo  := ""
Default lAgenda := .F.

If !Empty(cCampo) .And. !lAgenda
	If cCampo $ "TW3_ENTRA1|TW3_SAIDA1|TW3_ENTRA2|TW3_SAIDA2|TW3_ENTRA3|TW3_SAIDA3|TW3_ENTRA4|TW3_SAIDA4" .And. lWhenHora
		cAgrup := "004"
	Elseif cCampo == "TW3_EFETIV"
		cAgrup := "004"
	Else
		cAgrup := Posicione("SX3", 2, cCampo, "X3_AGRUP" )
	Endif
EndIf

/*
	Agrupamentos: 
	001 - Identificacao da Movimentacao 
	002 - Acao
	003 - Cobertura
	004 - Item Alocação
	005 - Rota Almocista
	006 - Motivo
	
	Situações:
	01  - Implantacao de efetivo                                 
	02  - Implantacao de treinamento                             
	03  - Implantacao de folguista                               
	04  - Implantacao de almocista                               
	05  - Implantacao de cortesia                                
	06  - Implantacao de reforco                                 
	07  - Implantacao de servico extra                           
	08  - Troca de funcionario                                   
	09  - Falta                                                  
	10  - Retorno de falta                                       
	11  - Reciclagem                                             
	12  - Curso                                                  
	13  - Folga                                                  
	14  - Recolhimento                                           
	15  - Folga Trabalhada - FT                                  
	16  - Folga Convocacao - CN                                  
	17  - Saida antecipada                                       
	18  - Hora Extra                                             
	19  - Atraso                                                 
*/

If !lChkWhen

	lRet := .T.

ElseIf cCampo == "TW3_SITCOD"
	lRet := .T.

Elseif cCampo == "TW3_MOTCOD" .And. cSituacao <> SIT_MOV_COBERTU
	lRet := .T.

ElseIf cSituacao $ SIT_MOV_EFETIVO + "|" + SIT_MOV_EXCEDEN + "|" + SIT_MOV_CORTESI 	 + "|" +;
                   SIT_MOV_REFORCO + "|" + SIT_MOV_SERVEXT + "|" + SIT_MOV_FTREFORCO + "|" + cListDia
	
	If cAgrup $ "004" 
		lRet := .T.
	EndIf
	
	If lAgenda
		If cCampo $ "ABB_HRFIM|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf

	If cCampo == "TW3_EFETIV" .And. cSituacao == SIT_MOV_FTREFORCO
		lRet := .F.
	Endif

ElseIf cSituacao == SIT_MOV_TREINAM

	If (cAgrup $ "004" .AND. cCampo <> "TW3_EFETIV") .OR. cCampo $ "TW3_QTDIAS"
		lRet := .T.
	EndIf

	If lAgenda
		If cCampo $ "ABB_HRFIM|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf

ElseIf cSituacao $ SIT_MOV_FOLGAFT + '|' + SIT_MOV_FOLGACN  + '|' + SIT_MOV_COBERTU + "|" + SIT_MOV_CNCOMP + "|" + cListFT + "|" + cListCob

	If (cAgrup == "002" .AND. cCampo <> "TW3_TECSUB")
		lRet := .T.
	EndIf
	
	If cAgrup == "004" .And. cSituacao $ SIT_MOV_FOLGAFT .And. cCampo <> "TW3_EFETIV" 
		lRet := .T.
	Endif
	
	lItCob := .T.

	If lAgenda
		If cCampo $ "ABB_HRFIM|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf
	
ElseIf cSituacao $ SIT_MOV_ALMOCIS + '|' + SIT_MOV_RECALMO + '|' + SIT_MOV_FOLGUIS + '|' + SIT_MOV_RECFOLG + "|" + SIT_MOV_FERISTA + "|" + SIT_MOV_RECFERI //Implantacao de almocista, Folguista e Ferista

	If cAgrup $ "005" 
		lRet := .T.
	EndIf

	If !lRet .And. cSituacao == SIT_MOV_ALMOCIS .And. cAgrup == "004" .And. cCampo == "TW3_EFETIV"
		lRet := .T.
	Endif

ElseIf cSituacao $ SIT_MOV_TROCFUN
	
	If cAgrup $ "002" 
		lRet := .T.
	EndIf
	
	If cCampo $ "TW3_SUBINI|TW3_MOTCOB"
		lRet := .F.
	Endif
	
ElseIf cSituacao $ SIT_MOV_RECOLHE

	If cAgrup $ "002" .And. cMovAtend <> TIPALO_TREINAMENTO 
		lRet := .T.
	EndIf

ElseIf cSituacao $ SIT_MOV_FALTA + "|" + SIT_MOV_FOLGA 
	
	If cAgrup $ "002" .And. Alltrim(Upper(cSitAtend)) <> Upper(SIT_ATEND_RESERVA) .And. !(cMovAtend $ TIPALO_EXCEDENTE + "|" + TIPALO_RECLICAGEM  + "|" + TIPALO_TREINAMENTO  + "|" + TIPALO_CURSO)
		lRet := .T.
	EndIf
	
ElseIf cSituacao == SIT_MOV_FALTAAB

	If (cAgrup $ "002" .And. Alltrim(Upper(cSitAtend)) <> Upper(SIT_ATEND_RESERVA) .And. !(cMovAtend $ TIPALO_EXCEDENTE + "|" + TIPALO_RECLICAGEM  + "|" + TIPALO_TREINAMENTO  + "|" + TIPALO_CURSO )).OR. cCampo $ "TW3_QTDIAS"
		lRet := .T.
	EndIf
	
ElseIf cSituacao == SIT_MOV_RETFALT // Retorno de falta  
	
	lRet := .F.
	
ElseIf cSituacao $ SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO // Reciclagem ### Curso
	If cCampo = "TW3_QTDIAS"
		lRet := .T.
	Else
		If !(cMovAtend $ TIPALO_RESERVA + "|" + TIPALO_RECLICAGEM + "|" + TIPALO_CURSO) .And. cCampo $ "TW3_QTDIAS|TW3_TECFIL|TW3_TECSUB|TW3_MOTCOB"
			lRet := .T.
		EndIf
	Endif
ElseIf cSituacao == SIT_MOV_SAIDANT // Saida antecipada   
	
	If (cAgrup $ "002" ) .And. !(Alltrim(Upper(cSitAtend)) $ Upper(SIT_ATEND_RESERVA) + "|" + Upper(SIT_ATEND_RECICLA) + "|" + Upper(SIT_ATEND_CURSO)) .And. cMovAtend <> TIPALO_TREINAMENTO
		lRet := .T.
	EndIf	
	
	If lAgenda
		If cCampo $ "ABB_HRFIM|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf
	
ElseIf cSituacao $ SIT_MOV_HORAEXT + '|' + cListHE // Hora Extra   
	
	If cCampo == "TW3_MOTCOB" .And. !(Alltrim(Upper(cSitAtend)) $ Upper(SIT_ATEND_RESERVA) + "|" + Upper(SIT_ATEND_EFETIVO) + '|' + Upper(SIT_ATEND_DIARIO) + "|" + Upper(SIT_ATEND_COBERTURA))
		lRet := .T.
	EndIf

	
	If lAgenda
		If cCampo $ "ABB_HRFIM|ABB_HRINI|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf
	
ElseIf cSituacao == SIT_MOV_ATRASO // Atraso
	
	If cAgrup $ "002" .And. Alltrim(Upper(cSitAtend)) <> Upper(SIT_ATEND_RESERVA) .And. !(cMovAtend $ TIPALO_RECLICAGEM  + "|" + TIPALO_TREINAMENTO  + "|" + TIPALO_CURSO)
		lRet := .T.
	EndIf
		
	If lAgenda
		If cCampo $ "ABB_HRINI|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf
ElseIf cSituacao == SIT_MOV_JORNDIF // Jornada Diferenciada
	
	If lAgenda
		If cCampo $ "ABB_HRINI|ABB_MANUT"
			lRet := .T.
		EndIf
	EndIf
EndIf

If lRet
	
	// O campo item de escala só estará habilitado quando o item de RH. 
	If lRet .And. cCampo == "TW3_TRSQES" .AND. Empty(FwFldGet("TW3_ITRHCT"))
		lRet := .F.
	EndIf
	
	// O campo Motivo de cobertura só estará habilitado quando o item de cobertura ou o atendente substituto for preenchido.
	If lRet .And. cCampo == "TW3_MOTCOB" .AND. (Empty(FwFldGet("TW3_ITCOBE")) .AND. Empty(FwFldGet("TW3_TECSUB"))) .AND. !(cSituacao $ SIT_MOV_HORAEXT + '|' + cListHE)
		lRet := .F.
	EndIf
	
	If lRet .And. cCampo == "TW3_ITCOBE" .AND. !lItCob
		lRet := .F.
	EndIf
	
	If lRet .And. cCampo $ "TW3_ENTRA1|TW3_SAIDA1|TW3_ENTRA2|TW3_SAIDA2|TW3_ENTRA3|TW3_SAIDA3|TW3_ENTRA4|TW3_SAIDA4" .And. Empty(FwFldGet("TW3_TRSQES"))
		lRet := .F.
	Endif
	
EndIf

If ExistBlock("AT336WHEN")
	lRet := ExecBlock("AT336WHEN",.F.,.F.,{cSituacao,cCampo,cAgrup,lAgenda,lRet})
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336JDGat
Gatilha o horário final, quando a situação informada for a Jornada Diferenciada

@author  Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since   13/02/2017
@return  lRet , Logico, Retorna se permite a edição do campo.
/*/
//------------------------------------------------------------------------------
Function At336JDGat( oView )
Local aArea       := GetArea()
Local aAreaABB    := ABB->(GetArea())
Local oModel      := FwModelActive()
Local oMdlTW3     := oModel:GetModel("TW3MASTER")
Local oMdlABB     := oModel:GetModel("ABBDETAIL")
Local cSituacao   := oMdlTW3:GetValue("TW3_SITCOD")
Local cHoraIni    := ""
Local cHoraFim    := ""
Local cHoraIniOld := ""
Local cHoraFimOld := ""
Local cHorasDif   := ""
Local lSubtrai    := .F.

If cSituacao == SIT_MOV_JORNDIF
	If oMdlABB:GetLine() == 1
		DbSelectArea("ABB")
		ABB->(DbSetOrder(8)) // ABB_FILIAL+ABB_CODIGO
		If ABB->(DbSeek(FwxFilial("ABB")+oMdlABB:GetValue("ABB_CODIGO")))
			
			cHoraIni    := oMdlABB:GetValue("ABB_HRINI")
			cHoraIniOld := ABB->ABB_HRINI 
			
			cHoraIni    += ":00"
			cHoraIniOld += ":00"
			
			If HoraToInt(cHoraIniOld) > HoraToInt(cHoraIni)
				cHorasDif := ElapTime ( cHoraIni, cHoraIniOld )
				lSubtrai  := .T.
			Else
				cHorasDif := ElapTime ( cHoraIniOld, cHoraIni )
			EndIf
			
			// Atribuo o novo horário ao campo hora final da última linha da agenda do dia.
			oMdlABB:GoLine(oMdlABB:Length())
			ABB->(DbSeek(FwxFilial("ABB")+oMdlABB:GetValue("ABB_CODIGO")))
			
			If lSubtrai
				cHoraFim := IntToHora(HoraToInt(ABB->ABB_HRFIM) - HoraToInt(cHorasDif))
			Else
				cHoraFim := IntToHora(HoraToInt(ABB->ABB_HRFIM) + HoraToInt(cHorasDif))
			EndIf
			oMdlABB:LoadValue("ABB_HRFIM",cHoraFim)
			
			oMdlABB:GoLine(1)
			If ValType(oView) == "O"
				oView:Refresh()
			EndIf
			
		EndIf
	EndIf
EndIf

RestArea( aArea )
RestArea( aAreaABB )

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336VldSituacao
Valida a situação da movimentação (TW3_SITCOD) informada, considerando a situação do atendente na data da movimentação. 

@author  Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since   07/10/2016
@return  lRet , Logico, Retorna se permite a edição do campo.
/*/
//------------------------------------------------------------------------------
Function At336VldSituacao()
Local oModel    := FwModelActive()
Local oMdlABB   := oModel:GetModel("ABBDETAIL")
Local cFil      := FwFldGet("TW3_FILIAL")
Local cFilTGZ   := xFilial("TGZ",cFil)
Local cSituacao := AllTrim(FwFldGet("TW3_SITCOD"))
Local cCodAtend := AllTrim(FwFldGet("TW3_ATDCOD"))
Local dDtMov    := FwFldGet("TW3_DTMOV")
Local lRet      := ExistCpo("SX5","I6" + FwFldGet("TW3_SITCOD"))  
Local cErro     := "" 
Local cAliasQry := ""
Local cIDcFal   := ""
Local cCodTFF   := ""
Local cMvAtPres := ""
Local aRows 	:= {}
Local nX		:= 0
Local aManut	:= {}
Local cCodAgend	:= ""
Local cMotivo   := SuperGetMv("MV_ATMTFAL",,"")

If lRet .And. !(AllTrim(cSituacao) $ At336FI6())
	lRet := .F.
	oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
	STR0139, "") //"Não é possível informar a situação que não está relacionada na consulta."
Endif

If lRet .And. Empty(cSitAtend)
	lRet := .F.
	oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
	STR0040, "") //"Não foi possível determinar a situação do atendente nesta data."						
Endif

If lRet
	
	Do Case

	// Para a situação do atendente de falta, apenas o retorno de falta poderá ser lançado.
	Case Upper(cSitAtend) == Upper(SIT_ATEND_FALTA)
		If !(cSituacao $ SIT_MOV_RETFALT + '|' + SIT_MOV_RECOLHE + '|' + SIT_MOV_TROCFUN)
			lRet := .F.
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0041, "") //"Esse atendente está em situação de falta e apenas o retorno da falta poderá ser lançado."
		Elseif cSituacao == SIT_MOV_RETFALT

			DbSelectArea("ABB")
			ABB->(DbSetOrder(1))
			ABB->(DbSeek(FwxFilial("ABB")+cCodAtend))

			While ABB->(!EOF()) .And. ABB->ABB_CODTEC == cCodAtend .And. ABB->ABB_DTINI <= dDtMov
				cCodAgend := ABB->ABB_CODIGO
				ABB->(DbSkip())
			EndDo

			If !Empty(cCodAgend)
				DbSelectArea("ABR")
				ABR->(DbSetOrder(1))
				If ABR->(DbSeek(FwxFilial("ABR")+cCodAgend+cMotivo)) .And. !Empty(ABR->ABR_CODSUB)
					lRet := .F.
					oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
					STR0140, "") //"Não é possível processeguir com o Retorno de Falta, pois já existe cobertura."					
				Endif
			Endif
		Endif
	// O retorno de falta poderá ser lançado apenas quando o atendente estiver em falta.
	Case cSituacao == SIT_MOV_RETFALT
	
		If Upper(cSitAtend) <> Upper(SIT_ATEND_FALTA)
			lRet := .F.
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0042, "")//"O retorno de falta só pode ser utilizado para atendentes em situação de falta!"					
		EndIf
		
	Case Upper(cSitAtend) == Upper(SIT_ATEND_CURSO) 
		If !(cSituacao $ SIT_MOV_RETCURS + '|' + SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_ATRASO + '|' + SIT_MOV_SAIDANT)
			lRet := .F. 
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0043+Lower(cSitAtend)+STR0141, "")//"Esse atendente está em situação de "###". Nesse caso, apenas o cancelamento de curso/reciclagem poderá ser utilizado!"			
		EndIf

	Case Upper(cSitAtend) == Upper(SIT_ATEND_RECICLA)
		If !(cSituacao <> SIT_MOV_RETRECI + '|' + SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_ATRASO + '|' + SIT_MOV_SAIDANT)
			lRet := .F. 
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0043+Lower(cSitAtend)+STR0142, "")//"Esse atendente está em situação de "###". Nesse caso, apenas o cancelamento de curso/reciclagem poderá ser utilizado!"			
		EndIf
		
	// Permite a utilização apenas em dia de trabalho ou dia de folga
	Case !(Upper(cSitAtend) $ Upper(SIT_ATEND_COBERTURA) + '|' + Upper(SIT_ATEND_DIARIO) + '|' + Upper(SIT_ATEND_EFETIVO) + '|' + Upper(SIT_ATEND_RESERVA) + '|' + Upper(SIT_ATEND_FOLGA) + '|' + Upper(SIT_ATEND_NAOALOCADO) + '|' + Upper(SIT_ATEND_FERISTA) + '|' + Upper(SIT_ATEND_ADISPEMP) ) .And. (!cSituacao $ cListCanCB ) .And. (!cSituacao $ cListCanFT ) .And. (!cSituacao $ cListDia )  
		lRet := .F. 
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
		STR0045+Lower(cSitAtend)+STR0046, "")	//"Esse atendente está em situação de "###". Portanto, essa situação não poderá ser utilizada!"	
	
	// Verifica se o atendente está cadastrado na TGY (em posto de efetivo) para datas futuras à data da movimentação. Se estiver, retorna falso.
	Case cSituacao $ SIT_MOV_EFETIVO + '|' + SIT_MOV_TREINAM + '|' + SIT_MOV_CORTESI + '|' +;
	                 SIT_MOV_REFORCO + '|' + SIT_MOV_SERVEXT + '|' + SIT_MOV_EXCEDEN + '|' + cListdia

		lRet := Upper(cSitAtend) <> Upper(SIT_ATEND_EFETIVO)
		
		If !lRet
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0103+Lower(cCodAtend)+STR0104, "")//"O atendente "###" está alocado em um posto de efetivo!"			
		Endif
	
	// Verifica se o atendente está cadastrado na TGZ para a data da movimentação. Se estiver, retorna falso.
	Case cSituacao $ SIT_MOV_FOLGUIS + '|' + SIT_MOV_ALMOCIS + '|' + SIT_MOV_FERISTA
		lRet := !(At336TGZChk( Nil, cFilTGZ, cCodAtend, dDtMov, cCodTFF ))
		
		If !lRet
			Help("",1,"AT336SIT",,STR0143+Lower(cCodAtend)+STR0144,2,0) //"O atendente "#" já está vinculado à esse posto de folguista!"
		Endif
	
	Case cSituacao == SIT_MOV_RECFOLG
		lRet := At581TpRot(cCodAtend) == "1" //Folguista
		
		If !lRet
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0105, "")//"Esse atendente não está vinculado a um posto de folguista/feirista! Essa situação não poderá ser utilizada!"				
		Endif
	
	Case cSituacao == SIT_MOV_RECALMO
		lRet := At581TpRot(cCodAtend) $ "2|3" //Almocista/Jantista
		
		If !lRet
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0106, "")//"Esse atendente não está vinculado a um posto de almocista/jantista! Essa situação não poderá ser utilizada!"			
		Endif
	
	// Verifica se o atendente está em situação de folga. Se não estiver, retorna falso.
	Case cSituacao $ SIT_MOV_FOLGAFT + '|' + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + "|" + cListFT
	
		If Upper(cSitAtend) <> Upper(SIT_ATEND_FOLGA)
			lRet := .F.
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0107, "")//"Para utilizar essa situação o atendente deverá estar em dia de folga!"			
		EndIf
		
		If lRet 
			
			lRet := !(At336TW5Chk( cCodAtend, dDtMov )) .Or. cSituacao $ SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP
			If !lRet 
				oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
				STR0108, "")//"Esse atendente possui um registro de ausência para a data da movimentação. Essa situação não poderá ser utilizada!"				
			EndIf
			
		EndIf
	
	// Verifica se o atendente está cadastrado na TGY para a data da movimentação. Se não estiver, retorna falso.
	Case cSituacao == SIT_MOV_TROCFUN
		
		lRet := (Upper(cSitAtend) $ Upper(SIT_ATEND_EFETIVO) + '|' + Upper(SIT_ATEND_DIARIO)) .OR. At336TGYChk( Nil, cFil, cCodAtend, dDtMov, .T., "1" )
		
		If !lRet
			oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
			STR0047, "")//"Esse atendente deve estar vinculado como efetivo em um posto para utilizar essa situação!"			
		Else
			oModel:SetValue("TW3MASTER","TW3_TECFIL",FwFldGet("TW3_FILIAL"))
		EndIf
	
	Case cSituacao == SIT_MOV_RECOLHE
	
		If !(Upper(cSitAtend) $ Upper(SIT_ATEND_EFETIVO) + '|' + Upper(SIT_ATEND_DIARIO) + '|' + Upper(SIT_ATEND_RESERVA))
			lRet := At336TGYChk( Nil, cFil, cCodAtend, dDtMov, .T., "1" )
			
			If !lRet
				oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
				STR0109, "")//"O atendente precisa estar num posto como efetivo para ser recolhido!"				
			EndIf
		EndIf
		
		If lRet
			
			// Caso o atendente esteja alocado em um posto de reserva que não está contido no MV_ATPRES, o sistema deverá permitir o recolhimento.
			If Upper(cSitAtend) == Upper(SIT_ATEND_RESERVA)
				cIDcFal   := oMdlABB:GetValue("ABB_IDCFAL")
				cCodTFF   := AllTrim(Posicione("ABQ",1,FwxFilial("ABQ")+cIdcFal,"ABQ_CODTFF"))
				
				cMvAtPres := SuperGetMV("MV_ATPRES",,,cFil)
				
				If (cCodTFF $ cMvAtPres)
					lRet := .F.
					oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
					STR0110, "") //"Esse atendente já está alocado em um posto de reserva padrão!"					
				EndIf
			EndIf
			
		EndIf
		
		If !lRet
				oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
				STR0047, "")//"Esse atendente deve estar vinculado como efetivo em um posto para utilizar essa situação!"			
		EndIf
		
	// Permite o lançamento de falta, saída antecipada, hora extra e atraso apenas para os dias que o atendente possuir agenda.
	Case (cSituacao $ SIT_MOV_SAIDANT + '|' + SIT_MOV_HORAEXT + '|' + ;
		              SIT_MOV_ATRASO  + '|' + SIT_MOV_FALTA   + '|' + ;
		              SIT_MOV_FOLGA   + '|' + SIT_MOV_FALTAAB + '|' + cListHE) .And. oMdlABB:IsEmpty()
		lRet := .F.              
		oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
		STR0048, "") // "Não há agenda gerada para esse atendente nessa data! Essa situação não poderá ser utilizada!"		
	Case (cSituacao $ SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB)

		aRows 	:= FwSaveRows()

		DbSelectArea("ABR")
		ABR->(DbSetOrder(1))	
		For nX := 1 To oMdlABB:Length()
			oMdlABB:GoLine(nX)
			If ABR->(DbSeek(FwxFilial("ABR",cFil)+oMdlABB:GetValue("ABB_CODIGO")+"000003"))
				lRet := .F.              
				oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
				STR0145, "") //"Esse atendente já sofreu manutenção na agenda com a saída antecipada, não é possível prosseguir com a situação de falta!"				
				Exit
			Elseif ABR->(DbSeek(FwxFilial("ABR",cFil)+oMdlABB:GetValue("ABB_CODIGO")+"000004"))
				lRet := .F.              
				oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
				STR0146, "") //"Esse atendente já sofreu manutenção da agenda com a hora extra, não é possível prosseguir com a situação de falta!"					
			Endif

		Next nX
		
		FwRestRows( aRows )

	EndCase
	
	If ExistBlock("AT336SIT")
		lRet := ExecBlock("AT336SIT",.F.,.F.,{cSituacao,cSitAtend,lRet})
	EndIf
Else
	oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SITCOD",oModel:GetModel():GetId(),	"TW3_SITCOD",'TW3_SITCOD',; 
	STR0049, "")//"Código de situação inválido!"					
	
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336VldMotivo
Valida se o motivo de movimentação pode ser informado para a situação de movimentação que foi informada.

@author  Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since   07/10/2016
@return  lRet , Logico, Retorna se permite a edição do campo.
/*/
//------------------------------------------------------------------------------
Function At336VldMotivo()
Local cCodMotivo := AllTrim(FwFldGet("TW3_MOTCOD"))
Local lRet       := .T.
Local aMotivos   := {}

If !Empty(cCodMotivo)
	aMotivos := StrTokArr(At336FI7(),"|")
	If aScan(aMotivos,cCodMotivo) == 0
		lRet := .F.
		Help("",1,"AT336MOT",,STR0050,2,0) //"O código de motivo informado não é permitido para a situação informada"
	EndIf
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336MotCob
Valida se o motivo de cobertura pode ser informado para a situação de movimentação que foi informada.

@author  Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since   07/10/2016
@return  lRet , Logico, Retorna se permite a edição do campo.
/*/
//------------------------------------------------------------------------------
Function At336MotCob()
Local cCodMotivo := AllTrim(FwFldGet("TW3_MOTCOB"))
Local aMotivos   := {}
Local lRet		 := .T.

aMotivos := StrTokArr(At336FI7Cob(),"|")
If aScan(aMotivos,cCodMotivo) == 0
	lRet := .F.
	Help("",1,"AT336MOT",,STR0050,2,0) //"O código de motivo informado não é permitido para a situação informada"
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336GrOk
Faz validações após o sistema gatilhar o campo grupo (TW3_GRPESC), pois a partir do grupo o sistema consegue verificar se o posto informado está vago. 
Se não estiver, o sistema pode bloquear a alocação ou exibir uma tela para seleção de um atendente que será substituído, de acordo com a situação da movimentação.
No caso específico da situação de implantação de excedente, o posto deve estar completo, caso contrário o sistema retornará falso.

@author Leandro Dourado - Totvs Ibirapuera
@version 12.1.14
@since 07/10/2016
@return lRet , Logico, Retorna se permite a edição do campo.
/*/
//------------------------------------------------------------------------------
Function At336GrOk( )
Local lRet        := .T.
Local oModel      := FwModelActive()
Local oMdlTW3     := oModel:GetModel("TW3MASTER")
Local cFil        := oMdlTW3:GetValue("TW3_FILIAL")
Local cCodAtend   := oMdlTW3:GetValue("TW3_ATDCOD")
Local dDtMov      := oMdlTW3:GetValue("TW3_DTMOV")
Local cSituacao   := oMdlTW3:GetValue("TW3_SITCOD")
Local nGrupo      := oMdlTW3:GetValue("TW3_GRPESC")
Local cEscala     := oMdlTW3:GetValue("TW3_TRSQES")
Local cCodTFF     := oMdlTW3:GetValue("TW3_ITRHCT")
Local nQtdVen     := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_QTDVEN")
Local dDtFim      := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_PERFIM")
Local cAliasQry   := GetNextAlias()
Local aAtendentes := {}
Local aCodTFF     := {}
Local lVago       := .T. // Para a situação de implantação de efetivo

If nGrupo > nQtdVen .AND. !(cSituacao $ SIT_MOV_EXCEDEN + ' | ' + SIT_MOV_TREINAM)
	If cSituacao $ SIT_MOV_EFETIVO + ' | ' + SIT_MOV_SERVEXT + ' | ' + SIT_MOV_TREINAM + ' | ' + SIT_MOV_CORTESI + ' | ' + SIT_MOV_REFORCO + '|' + cListDia
		lVago := .F.
	Else
		lRet := .F.
		Help("",1,"AT336GRUPO",,STR0052+Dtoc(dDtMov)+STR0053,2,0) //"Esse posto está completo para o item de escala selecionado na data "###"! Selecione um item de escala diferente."
	EndIf
EndIf

If cSituacao == SIT_MOV_TREINAM .And. nGrupo > nQtdVen
	lRet := MsgYesNo(STR0111,STR0037) //"Não há postos vagos para esse item de recursos humanos. Deseja implantar esse atendente como um excedente?"###"Atenção!"
	
	If !lRet
		Help("",1,"AT336GRUPO",,STR0112,2,0) //"Implantação cancelada pelo usuário!"
	EndIf
EndIf

If cSituacao == SIT_MOV_EXCEDEN .AND. nGrupo <= nQtdVen
	lRet := .F.
	Help("",1,"AT336GRUPO",,STR0054,2,0) //"Para utilizar essa situação o posto deve estar completo! Utilize a situação de implantação de efetivo."
EndIf

If nGrupo < 1
	lRet := .F.
EndIf

If lRet .AND. !lVago
	BeginSql Alias cAliasQry
		SELECT TGY.TGY_ATEND, AA1.AA1_NOMTEC, TGY.TGY_GRUPO, TGY.TGY_CODTFF, TGY.TGY_DTINI, TGY_DTFIM
		FROM %table:TGY% TGY
		LEFT JOIN %table:AA1% AA1 ON 
			AA1.AA1_FILIAL     = %xFilial:AA1% 
			AND AA1.AA1_CODTEC = TGY.TGY_ATEND
			AND AA1.%NotDel%
		WHERE TGY.TGY_FILIAL = %xFilial:TGY%
			AND TGY.TGY_CODTFF = %Exp:cCodTFF%
			AND TGY.TGY_CODTDX = %Exp:cEscala%
			AND %Exp:dDtMov% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM
			AND TGY.%NotDel%
		ORDER BY TGY.TGY_GRUPO
	EndSql
	
	(cAliasQry)->(DbGoTop())
	
	While (cAliasQry)->(!EOF())
		aAdd(aAtendentes, {(cAliasQry)->TGY_ATEND, (cAliasQry)->AA1_NOMTEC,;
			               (cAliasQry)->TGY_GRUPO, Stod((cAliasQry)->TGY_DTINI), Stod((cAliasQry)->TGY_DTFIM)})
		(cAliasQry)->(DbSkip())
	EndDo
	
	If MsgYesNo(STR0055+; //"Todas as vagas efetivas desse posto estão cobertas, sendo necessário recolher um atendente de uma dessas vagas para tornar "
		        STR0056+CRLF+STR0057,STR0037) //"o atendente posicionado como efetivo."###"Deseja selecionar um atendente para recolhimento?"###"Atenção!"
		lRet   := AtMostraEfetivos( aAtendentes, dDtMov, dDtFim, cCodTFF )
	Else
		lRet := .F.
		Help( ,, 'Help',, STR0058, 1, 0 ) //"Não há vagas disponíveis nesse posto. Faça o recolhimento de um atendente para poder efetivar novos atendentes nesse posto."
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtMostraEfetivos
Demonstra todos os atendentes efetivos no posto selecionado na tela do movimentar.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtMostraEfetivos(aAtendentes, dDtMov, dDtFim, cCodTFF)
Local lRet        := .T.
Local aHeader     := {STR0059,STR0060,STR0061,STR0062,STR0063} //"Cod. Atendente"###"Nome"###"Grupo"###"Dt. Inicial"###"Dt. Final"
Local nSelecao    := 0
Local cCodRecolhe := ""
Local aErro       := {}
Local oModel      := FwModelActive()
Local oMdlTW3     := oModel:GetModel("TW3MASTER")
Local cTpLanc     := ""
Local cMotivo     := ""
Local nGrupo      := 0
	
//Verificar se existe informação para o filtro
If Len(aAtendentes) > 0
	nSelecao := TmsF3Array(aHeader, aAtendentes, STR0064 ) //"Efetivos do posto"

	If nSelecao > 0
		cCodRecolhe := aAtendentes[ nSelecao, 1 ]
		nGrupo      := aAtendentes[ nSelecao, 3 ]
		
		lRet := At336Recolhe( cCodRecolhe, cCodTFF, dDtMov, .T. )
		If lRet
			oMdlTW3:LoadValue("TW3_GRPESC",nGrupo)
		EndIf
	Else 
		lRet := .F.
		Help("",1,"AT336GRUPO",,STR0065+Dtoc(dDtMov)+STR0066+Dtoc(dDtFim)+STR0067,2,0) //"Não há disponibilidade para alocação nesse posto para o período de "###" a "###" escala selecionados. É necessário escolher um funcionário para recolhimento primeiro!"S
	EndIf	
Endif
	
Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336ItOk()
Valida o campo Item RH de Alocação (TW3_ITRHCT), informado pelo usuário.

@sample 	At336ItOk()  
@return		lRet	Retorna .T. se o Item RH de Alocação está de acordo com os critérios	
	
@author		Leandro Dourado      
@since		18/11/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336ItOk()
Local lRet       	:= .F. 
Local cAliasQry  	:= GetNextAlias()
Local cCodTFF    	:= FwFldGet("TW3_ITRHCT")
Local cSituacao  	:= FwFldGet("TW3_SITCOD")
Local dDtMov     	:= FwFldGet("TW3_DTMOV")
Local cCodAtend  	:= FwFldGet("TW3_ATDCOD")
Local aCmpTFF    	:= {}
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.)
Local aArea
Local cEscala	 	:= ""
Local cCodTDX	 	:= ""

lRet := AtTFFQry(cAliasQry,cCodTFF,cSituacao)

If lRet
	lRet := At336TW2("TW3_CLICOD",Posicione("ABS",1,FwxFilial("ABS")+(cAliasQry)->TFF_LOCAL,"ABS_CODIGO"))
	If lRet
		lRet := At336TW2("TW3_LOCCOD",(cAliasQry)->TFF_LOCAL)
	EndIf			
EndIf

If lRet .And. lMV_GSGEHOR .And. !Empty(cCodTFF) .And. !(cSituacao $ SIT_MOV_REFORCO + '|' + SIT_MOV_FTREFORCO + '|' + cListDia)

	aArea := GetArea()

	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))
	If TFF->(DbSeek( FwxFilial("TFF")+cCodTFF))
		lWhenHora := At580EGHor((VldEscala(TFF->(RECNO()))))
	Endif

	RestArea(aArea)
Else
	lWhenHora := .F.
EndIf

If lRet .And. !Empty(cCodTFF) .And. cSituacao $ SIT_MOV_EFETIVO +"|"+ SIT_MOV_TREINAM +"|"+ SIT_MOV_CORTESI   +"|"+ ; 
          	   									SIT_MOV_SERVEXT +"|"+ SIT_MOV_REFORCO +"|"+ SIT_MOV_FTREFORCO +"|"+ cListDia
	
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1)) //TFF_FILIAL + TFF_COD
	TFF->(DbSeek(xFilial("TFF") + cCodTFF ))

	cEscala := TFF->TFF_ESCALA
	lRet	:= .F.
	
	DbSelectArea("TDX")
	TDX->(DbSetOrder(2))	//TDX_FILIAL + TDX_CODTDW + TDX_TURNO
	TDX->(DbSeek(xFilial("TDX") + cEscala ))

	While TDX->TDX_FILIAL == xFilial("TDX") .And. TDX->TDX_CODTDW == cEscala .And. !lRet
		
		cCodTDX	:= TDX->TDX_COD
		
		//Buscar o grupo conforme a configuração do efetivo.
		nGrupo := At336GrpDp(xFilial("TGY")	,;
		 							cCodTFF	,;
		 							dDtMov	,;
		 							dDtMov	,;
		 							cCodTDX	,;
		 							cCodAtend)

		lRet := (cAliasQry)->TFF_QTDVEN >= nGrupo

		TDX->(DbSkip())
	EndDo

Endif

(cAliasQry)->(DbCloseArea())

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336ItCob()
Validar se o item de cobertura (TW3_ITCOBE) está de fato disponível para seleção.

@sample 	At336ItCob()  
@return		lRet	Retorna .T. se o item de cobertura está de acordo com os critérios.
	
@author		Leandro Dourado      
@since		22/05/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336ItCob()
Local lRet       := .F. 
Local cAliasQry  := GetNextAlias()
Local cSituacao  := FwFldGet("TW3_SITCOD")
Local cFilSub    := FwFldGet("TW3_TECFIL")
Local dDtMov     := FwFldGet("TW3_DTMOV")
Local cCodTFFCob := FwFldGet("TW3_ITCOBE")
Local cCodTec	 := FwFldGet("TW3_ATDCOD")

aCmpTFF := AtTFFManut( cFilSub, dDtMov, cCodTec )

If aScan(aCmpTFF,{|x| x[1] == cCodTFFCob}) > 0
	lRet := .T.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtTFFMovF3()
Cria a consulta específica para demonstrar os Items RH de alocação. Chamada a partir do F3 do campo TW3_ITRHCT.

@sample 	AtTFFMovF3()  
@param		Nenhum
@author		Leandro Dourado       
@since		09/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtTFFMovF3()
Local oView     := FwViewActive()
Local oMdlTW3   := oView:GetModel("TW3MASTER")  
Local dDtMov    := oMdlTW3:GetValue("TW3_DTMOV")
Local cSituacao := oMdlTW3:GetValue("TW3_SITCOD")
Local cCodAtend	:= oMdlTW3:GetValue("TW3_ATDCOD")
Local aCmpTFF   := {}
Local aIDcFal   := {}
Local cCampo1   := ""
Local cAliasQry := ""
Local aHeader   := {STR0001,STR0002,STR0003,"Client. Local","Desc. Cli. Local",STR0004,; //"Item RH"#"Local"#"Desc. Local"#"Client. Local"#"Desc. Cli. Local"#"Produto"
                    STR0005,STR0008,STR0009,STR0006,; //"Desc. Produto"#"Período Inicial"#"Período Final"#"Escala"
                    STR0007,STR0010,STR0011}  //#"Desc. Escala"#"Funcao"#"Desc. Funcao"#
Local lIncF3	:= .T.
Local cCodTDX	:= ""
Local cEscala	:= ""
Local nGrupo	:= 0

//montar query
cAliasQry := GetNextAlias()

If AtTFFQry(cAliasQry,,cSituacao)

	DbSelectArea(cAliasQry)	
	(cAliasQry)->(DbGoTop())
	
	While (cAliasQry)->(!EOF())

		If cSituacao $ SIT_MOV_EFETIVO +"|"+ SIT_MOV_TREINAM +"|"+ SIT_MOV_CORTESI 	 +"|"+ ; 
                  	   SIT_MOV_SERVEXT +"|"+ SIT_MOV_REFORCO +"|"+ SIT_MOV_FTREFORCO +"|"+ cListDia

			cEscala := (cAliasQry)->TFF_ESCALA
			cCodTFF	:= (cAliasQry)->TFF_COD
			lIncF3  := .F.
			
			//Buscar registro de escala efetivo
			DbSelectArea("TDX")
			TDX->(DbSetOrder(2))	//TDX_FILIAL + TDX_CODTDW + TDX_TURNO
			TDX->(DbSeek(xFilial("TDX") + cEscala ))
	
			While TDX->TDX_FILIAL == xFilial("TDX") .And. TDX->TDX_CODTDW == cEscala .And. !lIncF3
				
				cCodTDX	:= TDX->TDX_COD
				
				//Buscar o grupo conforme a configuração do efetivo.
				nGrupo := At336GrpDp(xFilial("TGY")	,;
				 							cCodTFF	,;
				 							dDtMov	,;
				 							dDtMov	,;
				 							cCodTDX	,;
				 							cCodAtend)
	
				lIncF3 := (cAliasQry)->TFF_QTDVEN >= nGrupo

				TDX->(DbSkip())
			EndDo
		Endif

		If lIncF3
			AAdd(aCmpTFF,  {(cAliasQry)->TFF_COD                                                    ,; //itemRh
				 			(cAliasQry)->TFF_LOCAL                                                  ,; //local
				 			Posicione("ABS",1,FwxFilial("ABS")+(cAliasQry)->TFF_LOCAL,"ABS_DESCRI") ,; //descricao local
				 			Posicione("ABS",1,FwxFilial("ABS")+(cAliasQry)->TFF_LOCAL,"ABS_CODIGO") ,; //Cliente do local
				 			Posicione("SA1",1,FwxFilial("SA1")+ABS->ABS_CODIGO,"A1_NOME") 			,; //Descrição do Cliente do local			
				 			(cAliasQry)->TFF_PRODUT                                                 ,; //produto
				 			Posicione("SB1",1,FwxFilial("SB1")+(cAliasQry)->TFF_PRODUT,"B1_DESC")   ,; //desc. prodtuto
				 			Stod((cAliasQry)->TFF_PERINI)                                           ,; //período inicial
				 			Stod((cAliasQry)->TFF_PERFIM)                                           ,; //período final
				 			(cAliasQry)->TFF_ESCALA                                                 ,; //escala
				 			Posicione("TDW",1,FwxFilial("TDW")+(cAliasQry)->TFF_ESCALA,"TDW_DESC")  ,; //desc. escala
				 			(cAliasQry)->TFF_FUNCAO                                                 ,; //função
				 			Posicione("SRJ",1,FwxFilial("SRJ")+(cAliasQry)->TFF_FUNCAO,"RJ_DESC" )  }) //desc. função	

		Endif
		(cAliasQry)->(DbSkip())
	Enddo
	(cAliasQry)->(DbCloseArea())
	
EndIf

//Verificar se existe informação para o filtro
If Len(aCmpTFF) > 0
	nSelecao := TmsF3Array(aHeader, aCmpTFF, "Itens de Escala",,,aHeader ) //"Itens de Escala"

	If	nSelecao > 0
		VAR_IXB := aCmpTFF[ nSelecao, 1 ]
		lRet := At336TW2("TW3_CLICOD",aCmpTFF[ nSelecao, 4 ],oMdlTW3)
		If lRet
			lRet := At336TW2("TW3_LOCCOD",aCmpTFF[ nSelecao, 2 ],oMdlTW3)
			If !lRet
				VAR_IXB := ""
			EndIf	
		EndIf
	Else 
		VAR_IXB := ""
	EndIf	
Else
	Help("",1,"TFFMOVF3",,STR0080,2,0) //"Não foram encontrados postos no período atual com os filtros informados. Verifique o filtro por cliente, o filtro por local e o perfil de alocação!"
	VAR_IXB := ""
Endif
	
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtCobMovF3()
Função que retorna a consulta específica de postos de cobertura. Chamada a partir do campo TW3_ITCOBE.

@sample 	AtTFFMovF3()  
@param		Nenhum
@author		Leandro Dourado       
@since		09/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtCobMovF3()
Local oModel    := FwModelActive()
Local oMdlTW3   := oModel:GetModel("TW3MASTER")  
Local cFilSub   := oMdlTW3:GetValue("TW3_TECFIL")
Local dDtMov    := oMdlTW3:GetValue("TW3_DTMOV")
Local cSituacao := oMdlTW3:GetValue("TW3_SITCOD")
Local cCodTec 	:= oMdlTW3:GetValue("TW3_ATDCOD")
Local aCmpTFF   := {}
Local aIDcFal   := {}
Local cCampo1   := ""
Local cAliasQry := ""
Local aHeader   := {STR0001,STR0002,STR0003,STR0162,STR0163,STR0164,STR0004,; //"Item RH"#"Local"#"Desc. Local"#"Cod. Cliente"#"Loja"#"Desc. Cliente"#"Produto"
                    STR0005,STR0008,STR0009,STR0006,; //"Desc. Produto"#"Período Inicial"#"Período Final"#"Escala"
                    STR0007,STR0010,STR0011}          //#"Desc. Escala"#"Funcao"#"Desc. Funcao"#"Cobertura?"
                    
If !Empty(cFilSub)
	aCmpTFF := AtTFFManut( cFilSub, dDtMov, cCodTec )

	//Verificar se existe informação para o filtro
	If Len(aCmpTFF) > 0
		nSelecao := TmsF3Array(aHeader, aCmpTFF, STR0147 ) //"Itens de Escala"
	
		If	nSelecao > 0
			VAR_IXB := aCmpTFF[ nSelecao, 1 ]
			oMdlTW3:SetValue( "TW3_IDCFAL", aCmpTFF[ nSelecao, POS_IDCFAL ] )
		Else 
			VAR_IXB := ""
		EndIf	
	Else
		Help("",1,"COBMOVF3",,STR0113,2,0) //"Não foram encontrados postos de cobertura para a filial informada."
		VAR_IXB := ""
	Endif
Else
	VAR_IXB := ""
	Help("",1,"COBMOVF3",,STR0114,2,0) //"Informe a filial de cobertura antes de selecionar o posto para cobertura!"
EndIf
	
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtTDXMovF3()
Função que demonstra a consulta padrão para o campo item de escala do Movimentar.

@sample 	AtTDXMovF3()  
@param		Nenhum
@author		Leandro Dourado       
@since		02/02/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtTDXMovF3()
Local cSituacao := FwFldGet("TW3_SITCOD")
Local lRet      := .T.

VAR_IXB := ""

If ConPad1(,,,"TDXMOV")
	VAR_IXB := TDX->TDX_COD
EndIf

Return .T.


//------------------------------------------------------------------------------
/*/{Protheus.doc} AtTFFQry()
Utilizada tanto na consulta padrão quanto na validação do preenchimento do campo de Item RH de Alocação (TW3_ITRHCT).
Essa função deverá receber a string do alias da query, pois ela não ficará encarregada de fechar a área.

@sample 	AtTFFQry(cAliasQry,cCodTFF)  
@param		cAliasQry, Caractere, String passada através de um GetNextAlias, utilizada para a query.
@param		cCodTFF  , Caractere, Código da TFF digitado pelo usuário no campo. Utilizado para validar se o item da TFF é válido.
@return     lRet     , Logico   , Indica se a query retornou algum resultado.
@author		Leandro Dourado       
@since		09/11/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function AtTFFQry(cAliasQry,cCodTFF,cSituacao)
Local lRet      := .F.
Local cWhere    := ""
Local cChvTFJ   := ""
Local cChvTDX   := ""
Local cFuncao   := ""
Local cFilMov   := FwFldGet("TW3_FILIAL")
Local dDtMov    := FwFldGet("TW3_DTMOV")
Local cCliCod   := FwFldGet("TW3_CLICOD")
Local cLocal    := FwFldGet("TW3_LOCCOD")
Local cCodAtend := FwFldGet("TW3_ATDCOD")
Local cOrcRes	:= Alltrim(SuperGetMV("MV_GSORCRE"))
Local cChvABQ   := ""
Local cWhereTW4 := ""
Local nDia		:= 0

Default cCodTFF := ""

If Empty(aPerfAloc)
	aPerfAloc := TECA337(cFilAnt, FwFldGet("TW3_ATDCOD"),.F.)
EndIf

If aPerfAloc[1,1] == "1" // Verifica se deverá ser considerada a função do atendente
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere += "AND TFF.TFF_FUNCAO = '"+aPerfAloc[1,2]+"' "
EndIf

If aPerfAloc[2,1] == "1" // Verifica se deverá ser considerada o cargo do atendente
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere += "AND TFF.TFF_CARGO  = '"+aPerfAloc[2,2]+"' "      
EndIf

If !Empty(cLocal)
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere += "AND TFF.TFF_LOCAL = '"+cLocal+"' "
EndIf

If !Empty(cCodTFF)
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere += "AND TFF.TFF_COD = '"+cCodTFF+"' "
EndIf

If cSituacao == SIT_MOV_EFETIVO .Or. lLibSit
	If Empty(cWhere)
		cWhere += "%"
	EndIf

	cWhere += "AND ( TFF.TFF_PRCVEN > 0 OR TFF_TIPORH = '2' )"
EndIf

If cSituacao == SIT_MOV_EXCEDEN
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere += "AND TFF.TFF_PRCVEN > 0   "
Endif

If cSituacao $ SIT_MOV_CORTESI
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere += "AND TFF.TFF_COBCTR = '2' "
	cWhere += "AND TFF.TFF_PRCVEN = 0   "
EndIf

If cSituacao $ SIT_MOV_REFORCO + '|' + SIT_MOV_FTREFORCO + '|' + cListDia
	If Empty(cWhere)
		cWhere += "%" 
	EndIf
	cWhere += "AND TFF.TFF_ORIREF <> '' "
	cChvABQ := "%%"

	//Quando for FT de reforço verifica se o posto não é dia de folga
	If cSituacao == SIT_MOV_FTREFORCO
	
		nDia := Dow(dDtMov)

		If nDia == 1
			cWhereTW4 := "TW4.TW4_DOM = '" + 'T' + "'"
		Elseif nDia == 2
			cWhereTW4 := "TW4.TW4_SEG = '" + 'T' + "'"
		Elseif nDia == 3
			cWhereTW4 := "TW4.TW4_TER = '" + 'T' + "'"
		Elseif nDia == 4
			cWhereTW4 := "TW4.TW4_QUA = '" + 'T' + "'"
		Elseif nDia == 5
			cWhereTW4 := "TW4.TW4_QUI = '" + 'T' + "'"
		Elseif nDia == 6
			cWhereTW4 := "TW4.TW4_SEX = '" + 'T' + "'"
		Elseif nDia == 7
			cWhereTW4 := "TW4.TW4_SAB = '" + 'T' + "'"
		Endif

		cWhere	+= "AND EXISTS( SELECT 1 FROM " + RetSqlName("TW4") + " TW4 "
		cWhere	+= " WHERE TW4.TW4_FILIAL = '"+xFilial("TW4")+"' AND TW4.TW4_CODTFF = TFF.TFF_COD  AND "+cWhereTW4+" AND TW4.D_E_L_E_T_ = ' ' )"

	Endif

Else
	cChvABQ := "%INNER JOIN " + RetSqlName("ABQ") + " ABQ ON "
	cChvABQ += "	'" + xFilial("ABQ") + "'  = ABQ.ABQ_FILIAL AND "
	cChvABQ += "	ABQ.ABQ_CODTFF = TFF.TFF_COD    AND "
	cChvABQ += "	ABQ.D_E_L_E_T_  = ' '%"
EndIf

If cSituacao == SIT_MOV_SERVEXT
	If Empty(cWhere)
		cWhere += "%"
	EndIf
	cWhere  += "AND TFF.TFF_COBCTR = '2' "
	cWhere  += "AND TFF.TFF_ORIREF = '"+Space(TamSx3("TFF_ORIREF")[1])+"'"
	cChvTFJ := "%AND TFJ.TFJ_SRVEXT = '1' "
EndIf

If !Empty(cCliCod)
	If Empty(cChvTFJ)
		cChvTFJ += "%"
	EndIf
	cChvTFJ += "AND TFJ.TFJ_CODENT = '" + cCliCod + "'"
EndIf

If Empty(cChvTFJ)
	cChvTFJ := "%%"
Else
	cChvTFJ += "%"
EndIf

If Empty(cWhere)
	cWhere := "%%"
Else
	cWhere += "%"
EndIf

If aPerfAloc[3,1] == "1" // Verifica se deverá ser considerada a função do atendente
	If Empty(cChvTDX)
		cChvTDX += "%"
	EndIf
	cChvTDX += "AND TDX.TDX_TURNO = '"+aPerfAloc[3,2]+"' "
EndIf

If aPerfAloc[4,1] == "1" // Verifica se deverá ser considerada a função do atendente
	If Empty(cChvTDX)
		cChvTDX += "%"
	EndIf
	cChvTDX += "AND TDX.TDX_SEQTUR = '"+aPerfAloc[4,2]+"' "
EndIf

If Empty(cChvTDX)
	cChvTDX := "%%"
Else
	cChvTDX += "%"
EndIf

BeginSql Alias cAliasQry
	SELECT TFF.TFF_COD,
       TFF.TFF_LOCAL,
       TFF.TFF_PRODUT,
       TFF.TFF_PERINI,
       TFF.TFF_PERFIM,
       TFF_ESCALA,
       TFF_FUNCAO,
       TFF_QTDVEN
	FROM %table:TFF% TFF
	%Exp:cChvABQ%
	INNER JOIN %table:TFL% TFL ON
		%xFilial:TFL%  = TFL.TFL_FILIAL  AND 
		TFL.TFL_CODIGO = TFF.TFF_CODPAI  AND
		TFL.%NotDel%
	INNER JOIN %table:TFJ% TFJ ON
		%xFilial:TFJ%  = TFJ.TFJ_FILIAL  AND 
		TFJ.TFJ_CODIGO = TFL.TFL_CODPAI  AND
		TFJ.%NotDel%
		%Exp:cChvTFJ%
	LEFT JOIN %table:TDX% TDX ON 
		%xFilial:TDX%  = TDX.TDX_FILIAL  AND 
		TDX.TDX_CODTDW = TFF.TFF_ESCALA  AND
		TDX.%NotDel%
		%Exp:cChvTDX%	
	  
	WHERE TFF.TFF_FILIAL = %xFilial:TFF%
		AND TFF.TFF_CODSUB  = ''
		AND %Exp:dDtMov% BETWEEN TFF.TFF_PERINI AND TFF_PERFIM
		AND TFF.TFF_ENCE   <> '1'
		AND TFF.TFF_ESCALA <> ''
		AND TFJ.TFJ_CODIGO <> %Exp:cOrcRes%
		AND TFF.%NotDel%
		%Exp:cWhere%
	GROUP BY TFF.TFF_FILIAL, TFF.TFF_COD, TFF.TFF_LOCAL, TFF.TFF_PRODUT, TFF.TFF_PERINI, TFF.TFF_PERFIM, TFF_ESCALA, TFF_FUNCAO, TFF_QTDVEN
	ORDER BY %Order:TFF%
EndSql

(cAliasQry)->(DbGoTop())

If (cAliasQry)->(!Eof())
	lRet := .T.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtAA1MovF3()
Função que retorna a consulta específica para demonstrar os atendentes disponíveis para a cobertura do posto informado.




@sample 	AtAA1MovF3()  

@param		Nenhum

author		Ana Maria Utsumi       
@since		12/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtAA1MovF3()
Local aArea      := GetArea()
Local aAreaABQ   := ABQ->(GetArea())
Local oModel     := FwModelActive()
Local oMdlABB    := oModel:GetModel("ABBDETAIL")
Local cCodAtdSub := ""
Local cIdCfal    := oMdlABB:GetValue("ABB_IDCFAL")
Local cOrigem    := ""
Local cCodTFF    := ""
Local cSituacao  := oModel:GetValue("TW3MASTER","TW3_SITCOD")
Local cCodAtend  := oModel:GetValue("TW3MASTER","TW3_ATDCOD")
Local dDtMov     := oModel:GetValue("TW3MASTER","TW3_DTMOV")
Local cFilMov    := oModel:GetValue("TW3MASTER","TW3_FILIAL")
Local cFilSub    := oModel:GetValue("TW3MASTER","TW3_TECFIL")
Local cCodSub    := oModel:GetValue("TW3MASTER","TW3_TECSUB")
Local aCarga     := {}
Local aCmpAA1	 := {}
Local cAliasQry	 := ""
Local cFiltro 	 := ""
Local nSelecao   := 0
Local aHeader    := {STR0068,STR0069,STR0003,STR0004,; //"Código"##"Nome do Atendente"##"Local"#"Desc. Local"
 					 STR0008,STR0009,STR0006,STR0007,; //"Período Inicial"#"Período Final"#"Escala"#"Desc. Escala"
 					 STR0010,STR0011}                  //"Funcao"#"Desc. Funcao"#

cCodTFF := AtGetTFFAtd(cFilMov, cCodAtend, dDtMov, cIdCfal, @cOrigem)

Do Case

Case cSituacao == SIT_MOV_TROCFUN
	
	cAliasQry := GetNextAlias()
	
	//Executa a query para buscar os atendentes substitutos
	AtQryFunTroca(cAliasQry,cSituacao,dDtMov,cFilSub,cCodAtend,.F.,cCodTFF)
	
	DbSelectArea(cAliasQry)
	(cAliasQry)->(DbGoTop())
	While (cAliasQry)->(!EOF())
		AAdd(aCmpAA1,                                                                      ;
		   {(cAliasQry)->TGY_ATEND                                                        ,;  //Código do Atendente
			(cAliasQry)->AA1_NOMTEC                                                       ,;  //Nome do Atendente
			(cAliasQry)->TFF_LOCAL                                                        ,;  //Local
			Posicione("ABS",1,xFilial("ABS",cFilMov)+(cAliasQry)->TFF_LOCAL,"ABS_DESCRI") ,;  //Desc. Local
			(cAliasQry)->TFF_PERINI                                                       ,;  //Período Inicial
			(cAliasQry)->TFF_PERFIM                                                       ,;  //Período Final
			(cAliasQry)->TFF_ESCALA                                                       ,;  //Escala
			Posicione("TDW",1,xFilial("TDW",cFilMov)+(cAliasQry)->TFF_ESCALA,"TDW_DESC")  ,;  //Desc. Escala
			(cAliasQry)->TFF_FUNCAO                                                       ,;  //Funcao
			Posicione("SRJ",1,xFilial("SRJ",cFilMov)+(cAliasQry)->TFF_FUNCAO,"RJ_DESC" )  ,;  //Desc. Funcao
			})
		(cAliasQry)->(DbSkip())
	Enddo
	(cAliasQry)->(DbCloseArea())
	
	If Len(aCmpAA1) > 0
		nSelecao := TmsF3Array( aHeader, aCmpAA1, STR0070,,,aHeader ) //"Atendentes de Cobertura"
		
		If	nSelecao > 0
			cCodAtdSub := aCmpAA1[ nSelecao, 1 ]
		Else 
			cCodAtdSub := ""
		EndIf
	Else
		Help("",1,"ATAA1MOVF3",,STR0115,2,0) //"Não há atendentes alocados como efetivo em outros postos dessa filial!"
	EndIf

OtherWise

	If !Empty(cOrigem) .AND. !Empty(cCodTFF)

		If Conpad1( NIL,NIL,NIL,"AA1335")
			cCodAtdSub := VAR_IXB
		Endif
	EndIf
EndCase

VAR_IXB := cCodAtdSub

RestArea( aArea )
RestArea( aAreaABQ )

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtTGYGruF3()

Função que retorna a consulta específica do campo TW3_GRPESC.
Essa função está descontinuada, pois o campo é bloqueado para edição.

@sample 	AtTGYGruF3()  

@param		Nenhum

author		Ana Maria Utsumi       
@since		12/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtTGYGruF3() 
Local aCmpTGY	:= {}
Local nSelecao  := 0
Local tmpTGY  	:= GetNextAlias()
Local cFiltro 	:= ""
Local aHeader	:= {}
Local cCodTFF   := FwFldGet("TW3_ITRHCT")
Local cEscala   := FwFldGet("TW3_TRSQES")

//Montar Query
BeginSql Alias tmpTGY
	SELECT TGY_GRUPO
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL=%xFilial:TGY%
	  AND TGY.TGY_CODTFF=%Exp:cCodTFF%
	  AND TGY.TGY_ESCALA=%Exp:cEscala%
	ORDER BY TGY.TGY_GRUPO
EndSql

DbSelectArea(tmpTGY)
(tmpTGY)->(DbGoTop())
While !EOF()
	If aScan(aCmpTGY, (tmpTGY)->TGY_GRUPO) == 0
		AAdd(aCmpTGY, {(tmpTGY)->TGY_GRUPO}) 	//Numero do grupo
	EndIf
	(tmpTGY)->(DbSkip())
Enddo
(tmpTGY)->(DbCloseArea())

//Verificar se existe informação para o filtro
If Len(aCmpTGY) > 0
	
	nSelecao := TmsF3Array( {STR0061}, aCmpTGY, STR0071 ) //"Grupo"###"Grupos de Escala"
	
	If	nSelecao > 0
		//-- VAR_IXB eh utilizada como retorno da consulta F3 TGYGRU.
		VAR_IXB := aCmpTGY[ nSelecao, 1 ]
	Else 
		VAR_IXB := 0
	EndIf
	
Else
	Help("",1,"TGYGRUF3",,STR0018,2,0) //"Não existe informação para este contrato"
	lOK := .F.
Endif
	
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtABSCliLj()
Utilizado na consulta padrão do campo TW3_LOCCOD, filtrando os locais de atendimento com base no cliente informado.

@sample 	AtABSCliLj()  
@return		lRet, Logical   - Retorna verdadeiro quando o local de atendimento analisado pertencer ao cliente preenchido.
@author		Leandro Dourado - Totvs Ibirapuera    
@since		09/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function AtABSCliLj()
Local lRet     := .F.
Local cRet     := ""
Local oModel   := FwModelActive()
Local cCliente := ""

oModel := oModel:GetModel("TW3MASTER")

If !Empty(oModel:GetValue("TW3_CLICOD"))
	
	cCliente := oModel:GetValue("TW3_CLICOD")

	If ABS->ABS_ENTIDA == "1" .AND. ABS->(ABS_CODIGO) == cCliente
		lRet := .T.
	EndIf
Else
	lRet := .T.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336ItEsc()
Valida se o item da escala informado (TW3_TRSQES) está disponível para vínculo com o atendente da movimentação.

@sample 	At336ItEsc()  

@param		Nenhum

@return		lRet	Retorna .T. se o Item da escala está de acordo com os critérios	
	
@author		Leandro Dourado     
@since		18/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336ItEsc()
Local aArea     := GetArea()
Local lRet      := .T. 
Local cAliasTmp := GetNextAlias()
Local cSituacao := FwFldGet("TW3_SITCOD")
Local cCodTFF   := FwFldGet("TW3_ITRHCT")
Local dDtMov    := FwFldGet("TW3_DTMOV")
Local citemEsc  := FwFldGet("TW3_TRSQES")
Local cEscala   := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_ESCALA")

If cSituacao == SIT_MOV_FOLGUIS // Implantação de Folguista
	//montar query
	BeginSql Alias cAliasTmp
		SELECT * 
		FROM %table:TGX% TGX
		WHERE TGX.TGX_FILIAL   = %xFilial:TGX%
			AND TGX.TGX_COD    = %Exp:citemEsc%
			AND TGX.TGX_CODTDW = %Exp:cEscala%
			AND TGX.%NotDel%
	EndSql
Else
	//montar query
	BeginSql Alias cAliasTmp
		SELECT * 
		FROM %table:TDX% TDX
		WHERE TDX.TDX_FILIAL   = %xFilial:TDX%
			AND TDX.TDX_COD    = %Exp:citemEsc%
			AND TDX.TDX_CODTDW = %Exp:cEscala%
			AND TDX.%NotDel%
	EndSql
EndIf

DbSelectArea(cAliasTmp)
(cAliasTmp)->(DbGoTop())
lRet := (cAliasTmp)->(!Eof())	//Se encontrou registro, indica que Item escala está de acordo com os critérios

If lRet
	If cSituacao == SIT_MOV_FOLGUIS
		If !((cAliasTmp)->TGX_TIPO $ "1|4")
			lRet := .F.
			Help("",1,"336ITESC",,STR0072,2,0) //"Item de escala inválido! Selecione um item de escala de cobertura do tipo folguista!"
		EndIf
		
		If !AtChkEfetivos( cCodTFF, dDtMov )
			lRet := .F.
			Help("",1,"336ITESC",,STR0116,1,0,,,,,,{STR0117}) //"Não há efetivos alocados nesse posto!"###"Faça a alocação dos postos efetivos antes de iniciar a alocação dos postos de cobertura!"
		EndIf
	EndIf
Else
	Help("",1,"336ITESC",,STR0073,2,0) //"Item de escala informado incompatível com o posto de trabalho!"
EndIf

(cAliasTmp)->(DbCloseArea())

RestArea( aArea )

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336RtOk()
Valida a rota de cobertura informada pelo usuário através do campo TW3_RTACOD.

@sample 	At336RtOk()  

@param		Nenhum

@return		lRet	Retorna .T. se a rota de cobertura está de acordo com os critérios	
	
@author		Ana Maria Utsumi       
@since		19/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336RtOk()
Local tmpRt     := ""
Local cAliasTmp	:= ""
Local lRet      := .F. 
Local cSituacao := FwFldGet("TW3_SITCOD")
Local cCodTW0   := FwFldGet("TW3_RTACOD")
Local cCodAtend := FwFldGet("TW3_ATDCOD")
Local dDtMov    := FwFldGet("TW3_DTMOV")
Local cCodTFF   := ""
Local cPostos   := ""
Local cChvTW0   := ""
Local cAtVazio  := Space(TamSx3("TW0_ATEND")[1])
Local cEscala	:= ""
Local cItemEsc  := ""
Local cSeqTur	:= ""
Local cDiaSem	:= AllTrim(STR(Dow(dDtMov)))
Local cWhere	:= ""

If cSituacao $ SIT_MOV_ALMOCIS + "|" + SIT_MOV_FOLGUIS + "|" + SIT_MOV_FERISTA
	cChvTW0 := "%TW0.TW0_ATEND  = '" + cAtVazio + "'%"
ElseIf cSituacao $ SIT_MOV_RECALMO + "|" + SIT_MOV_RECFOLG + "|" + SIT_MOV_RECFERI
	cChvTW0 := "%TW0.TW0_ATEND  = '" + cCodAtend + "'%"
EndIf
	
//montar query
tmpRt := GetNextAlias()
BeginSql Alias tmpRt
	SELECT TW1_COD, TW1_CODTFF ,TW1_CODTGX 
	  FROM %table:TW1% TW1
	  INNER JOIN %table:TW0% TW0 
	  	ON TW0.TW0_COD     = TW1.TW1_CODTW0
	    AND TW0.TW0_FILIAL = %xFilial:TW0% 
	    AND %Exp:cChvTW0%
	  	AND TW0.%NotDel% 
	  WHERE TW1.TW1_FILIAL = %xFilial:TW1%
	  	AND TW1.TW1_CODTW0 = %Exp:cCodTW0%
	    AND TW1.%NotDel%
	ORDER BY %Order:TW1%
EndSql

DbSelectArea(tmpRt)
(tmpRt)->(DbGoTop())
lRet := !(tmpRt)->(Eof())	//Se encontrou registro, indica que a rota está de acordo com os critérios

If lRet .And. cSituacao $ SIT_MOV_ALMOCIS + "|" + SIT_MOV_FOLGUIS
	cItemEsc := (tmpRt)->TW1_CODTGX
	cSeqTur	 := Posicione('TGX',1, xFilial('TGX') + cItemEsc , 'TGX_ITEM')
	cEscala	 := Posicione('TGX',1, xFilial('TGX') + cItemEsc , 'TGX_CODTDW')
	While (tmpRt)->(!Eof())
		cCodTFF := (tmpRt)->TW1_CODTFF
		If !AtChkEfetivos( cCodTFF, dDtMov )
			If !Empty(cPostos)
				cPostos += ", "
			EndIf
			cPostos += cCodTFF
		EndIf
		(tmpRt)->(DbSkip())
	EndDo
	
	If !Empty(cPostos)
		cPostos += "."
		
		lRet := .F.
		Help("",1,"336ITESC",,STR0118+CRLF+cPostos,1,0,,,,,,; //"Os seguintes itens de recursos humanos não possuem efetivos associados:"
		                     {STR0119})           //Faça a alocação dos postos efetivos antes de iniciar a alocação dos postos de cobertura!"
	EndIf
EndIf

(tmpRt)->(DbCloseArea())

If lRet 
	If cSituacao == SIT_MOV_ALMOCIS
		cWhere := "%TGW.TGW_DIASEM = '" + cDiaSem + "' AND"
		cWhere += " TGW.TGW_STATUS = '" + '3' 	  + "'%"
	Elseif cSituacao == SIT_MOV_FOLGUIS
		cWhere := "%TGW.TGW_STATUS = '" + '2' 	  + "'%"
	Endif

	If !Empty(cWhere)

	cAliasTmp := GetNextAlias()
	
	//montar query
	BeginSql Alias cAliasTmp
		SELECT * 
		FROM %table:TDX% TDX INNER JOIN
		%table:TGW% TGW ON
		TGW.TGW_FILIAL   = %xFilial:TGW% AND
		TGW.TGW_EFETDX	 = TDX.TDX_COD 
		WHERE TDX.TDX_FILIAL   = %xFilial:TDX%
			AND TDX.TDX_CODTDW = %Exp:cEscala%
				AND %Exp:cWhere%
			AND TDX.%NotDel%
			AND TGW.%NotDel%
	EndSql
	
	DbSelectArea(cAliasTmp)
	(cAliasTmp)->(DbGoTop())
	lRet := (cAliasTmp)->(!Eof())	//Se encontrou registro, indica que Item escala está de acordo com os critérios
	
	If lRet
		If cSituacao == SIT_MOV_ALMOCIS
				If !((cAliasTmp)->TGW_COBTIP $ "2|3")
				lRet := .F.
				Help("",1,"336ITEROTA",,STR0131,2,0) //"Item de escala inválido! Verifique se a cobertura da escala é do tipo Almocista"                                                                                                                                                                                                                                                                                                                                                                                                                                   
			EndIf
			Elseif cSituacao == SIT_MOV_FOLGUIS
				If (cAliasTmp)->TGW_COBTIP <> "1"
					lRet := .F.
					Help("",1,"336ITEROTA",,STR0148,2,0) //"Item de escala inválido! Verifique se a cobertura da escala é do tipo Folguista"                                                                                                                                                                                                                                                                                                                                                                                                                                   
				EndIf
		EndIf
	Else
		Help("",1,"336ITEROTA",,STR0073,2,0) //"Item de escala informado incompatível com o posto de trabalho!"
	EndIf
	
	(cAliasTmp)->(DbCloseArea())
	Endif
EndIf

Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At336CanAt()
Valida o atendente selecionado para cobertura conforme a situação utilizada.

@sample 	At336CanAt()  

@param		Nenhum

@return		lRet	Retorna .T. se o atendente substituto não possui restrições
	
@author		Ana Maria Utsumi       
@since		18/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336CanAt()
Local aArea     := GetArea()
Local aAreaAA1  := AA1->(GetArea())
Local tmpAA1	:= ""
Local lRet 		:= .T.
Local oModel    := FwModelActive()
Local oMdlABB   := oModel:GetModel("ABBDETAIL")
Local cFil      := oModel:GetValue("TW3MASTER","TW3_FILIAL")
Local cSituacao := oModel:GetValue("TW3MASTER","TW3_SITCOD")
Local cFilSub   := oModel:GetValue("TW3MASTER","TW3_TECFIL")
Local cCodSub   := oModel:GetValue("TW3MASTER","TW3_TECSUB")
Local dDtMov    := oModel:GetValue("TW3MASTER","TW3_DTMOV" )
Local cCodAtend := oModel:GetValue("TW3MASTER","TW3_ATDCOD")
Local dDtFim    := dDtMov
Local cCodLoc   := ""
Local cAliasQry := ""

If !Empty(cFilSub)

	DbSelectArea("AA1")
	AA1->(DbSetOrder(1)) // AA1_FILIAL+AA1_CODTEC
	lRet := AA1->(DbSeek(xFilial("AA1",cFilSub)+cCodSub))
	
	cFilAnt := cFilSub
	
Else
	lRet := .F.
	Help("",1,"AT336CANAT",,STR0120,2,0) //"Filial do substituto não informada!"
EndIf

If lRet .And. cFil+cCodAtend == cFilSub+cCodSub // Caso haja a tentativa de trocar um efetivo por ele mesmo, retorna falso.
	lRet := .F.
	Help("",1,"AT336CANAT",,STR0121,2,0) //"O atendente substituto deve ser diferente do atendente da movimentação!"
EndIf

If lRet

	If !oMdlABB:IsEmpty()
		cCodLoc := oMdlAbb:GetValue("ABB_LOCAL")
	Else
		cAliasQry := GetNextAlias()
		If At336TGYChk( cAliasQry, cFil, cCodAtend, dDtMov, .T., "1" )
			cCodLoc := Posicione("TFF",1,FwxFilial("TFF")+(cAliasQry)->TGY_CODTFF,"TFF_LOCAL")
		Else
			lRet := .F.
		EndIf
		(cAliasQry)->(DbCloseArea())
	EndIf
	
	lRet := lRet .And. At012Blq( cCodSub, dDtMov, dDtFim, cCodLoc ) //Valida se atendente está livre de restrições operacionais  

Endif

If lRet
	
	Do Case
	
	Case cSituacao == SIT_MOV_TROCFUN
	
		cCodTFF := AtGetTFFAtd(cFil, cCodAtend, dDtMov)
		
		cAliasQry := GetNextAlias()
		AtQryFunTroca(cAliasQry,cSituacao,dDtMov,cFilSub, cCodSub,.T.,cCodTFF)
		DbSelectArea(cAliasQry)
		(cAliasQry)->(DbGoTop())
		//Recebe filtro SQL por situação
		lRet := !(cAliasQry)->(Eof())	//Se encontrou registro, indica que atendente dentro dos critérios
		(cAliasQry)->(DbCloseArea())
	
	Case Upper(At335StAtd( cFilSub, cCodSub, dDtMov )) == Upper(SIT_ATEND_FOLGA) .AND. cSituacao <> SIT_MOV_RECOLHE
	
		lRet := .T.
		
	Otherwise
	
		//Montar Query
		cAliasQry := GetNextAlias()
		BeginSql Alias cAliasQry
			SELECT AA1_CODTEC
			FROM %table:AA1% AA1
			WHERE AA1.AA1_FILIAL = %Exp:cFilSub%
			  AND AA1.AA1_CODTEC = %Exp:cCodSub%
			  AND AA1.%NotDel%
			  AND NOT EXISTS (SELECT TGY.TGY_CODTFF 
							  FROM %table:TGY% TGY 
							  INNER JOIN %table:TFF% TFF 
							  	ON  TFF.TFF_FILIAL = TGY.TGY_FILIAL
							  	AND TFF.TFF_COD    = TGY.TGY_CODTFF
							  	AND TFF.%NotDel% 
							  INNER JOIN %table:ABS% ABS 
								ON  ABS.ABS_FILIAL = TFF.TFF_FILIAL
							 	AND ABS.ABS_LOCAL  = TFF.TFF_LOCAL
							  	AND ABS.%NotDel% 
							  WHERE TGY.TGY_FILIAL = AA1.AA1_FILIAL 
							  	AND TGY.TGY_ATEND  = AA1.AA1_CODTEC
							  	AND ABS.ABS_RESTEC <> '1'
							    AND TGY.%NotDel%)
			ORDER BY %Order:AA1%
		EndSql
	
		DbSelectArea(cAliasQry)
		(cAliasQry)->(DbGoTop())
		lRet := !(cAliasQry)->(Eof())	//Se encontrou registro, indica que atendente dentro dos critérios
		(cAliasQry)->(DbCloseArea())
	EndCase
	
EndIf

cFilAnt := cFil

RestArea(aAreaAA1)
RestArea(aArea)

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} AtQryFunTroca()
Executa uma query que será utilizada na situação de troca de funcionários. 
Essa função é chamada tanto da consulta padrão que busca o substituto que será utilizado na cobertura, quanto da rotina de validação do substituto que foi informado.
O alias já deve ter sido setado e ele deve ser fechado posteriormente à essa função, pois ela apenas executa a query para ser utilizada em outros pontos do sistema.

@sample 	AtQryFunTroca()  

@param		cAliasQry
@param		cSituacao
@param		dDtMov
@param		cFilAA1
@param		cCodAtend
@param		lValid
@param		cCodTFF

@return		cFiltro	Retorna filtro SQL
	
@author		Ana Maria Utsumi       
@since		18/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function AtQryFunTroca(cAliasQry,cSituacao,dDtMov,cFilAA1,cCodAtend,lValid,cCodTFF)
Local cWhereTGY   := ""
Local cFilTGY     := xFilial("TGY",cFilAA1)

Default cCodAtend := ""
	
If lValid 
	cWhereTGY := "%TGY.TGY_ATEND =  '" + cCodAtend + "'%"
Else
	cWhereTGY := "%TGY.TGY_ATEND <> '" + cCodAtend + "'%"
EndIf

BeginSql Alias cAliasQry
	SELECT TGY.TGY_ATEND, AA1.AA1_NOMTEC, AA1.AA1_FUNCAO, TFF.TFF_LOCAL, TFF.TFF_PERINI, TFF.TFF_PERFIM, TFF.TFF_ESCALA, TFF.TFF_FUNCAO
	
	FROM %table:TGY% TGY
	
	INNER JOIN %table:TFF% TFF 
		ON  TFF.TFF_FILIAL = %xFilial:TFF%
		AND TFF.TFF_COD    = TGY.TGY_CODTFF
		AND TFF.%NotDel%
	
	INNER JOIN %table:AA1% AA1 
		ON  AA1.AA1_FILIAL = %xFilial:AA1% 
		AND AA1.AA1_CODTEC = TGY.TGY_ATEND	
		AND AA1.%NotDel%
		
	INNER JOIN %table:TCU% TCU
		ON  TCU.TCU_FILIAL = %xFilial:TCU%
		AND TCU.TCU_COD    = TGY.TGY_TIPALO
		AND TCU.TCU_RESTEC <> '1'
		AND TCU.%NotDel%
	
	WHERE   TGY.TGY_FILIAL  = %Exp:cFilTGY%
	    AND TGY.TGY_DTFIM  >= %Exp:dDtMov% 
	    AND TGY.TGY_CODTFF <> %Exp:cCodTFF%
		AND %Exp:cWhereTGY%	
		AND TGY.%NotDel%
	
	GROUP BY TGY.TGY_ATEND, AA1.AA1_NOMTEC, AA1_FUNCAO, TFF.TFF_LOCAL, TFF.TFF_PERINI, TFF.TFF_PERFIM, TFF.TFF_ESCALA, TFF.TFF_FUNCAO
EndSql	
	
Return 


//------------------------------------------------------------------------------
/*/{Protheus.doc} At336FI6()
Filtro da consulta padrão na SX5 para restringir as situações de movimentação conforme o status do dia do atendente.

Situações Cadastradas:
Cód	Descrição
01	Implantação de efetivo
02	Implantação de treinamento
03	Implantação de folguista
04	Implantação de almocista
05	Implantação de cortesia
06	Implantação de reforço
07	Implantação de serviço extra
08	Troca de funcionário
09	Falta
10	Retorno de Falta
11	Reciclagem
12	Curso
13	Folga
14	Recolhimento
15	Folga Trabalhada - FT
16	Folga Convocação - CN
17	Saída Antecipada
18	Hora Extra
19	Atraso

Status do atendente:
a)	Atendente Restrito no RH por férias: Visualizar a rotina de Controle de Dias de Direito (acionando a visualização da
    função GPEA050 do módulo de Recursos Humanos, vide Protótipo 04);
b)	Atendente Restrito no RH por afastamento: Visualizar a rotina de Ausências (acionando a visualização da função GPEA240 
    do módulo de Recursos Humanos, vide Protótipo 05);
c)	Atendente Suspenso: Sem ação ao menos que a disciplina encerre ou seja desfeita;
d)	Atendente em Folga ou Falta: Atendente disponível para sofrer alguma movimentação;
e)	Atendente em dia de Trabalho – alocado em posto: Atendente disponível para sofrer alguma manutenção ou movimentação;
f)	Atendente em dia de Trabalho – reserva: Atendente disponível para sofrer alguma movimentação ou manutenção;
g)	Atendente em Reciclagem ou Curso: Atendente será bloqueado para a movimentação. A movimentação só poderá ser feita 
    depois que for realizada a exclusão ou alteração do período do Curso ou Reciclagem.

@sample 	At336FI6()  

@param		Nenhum

@return cRet - Retorna a string do filtro SXB
	
@author		Ana Maria Utsumi       
@since		19/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336FI6()
Local cRet      := ""
Local oModel    := FwModelActive()
Local oMdlABB   := oModel:GetModel("ABBDETAIL")
Local cFil      := oModel:GetValue("TW3MASTER","TW3_FILIAL")
Local dDtMov    := oModel:GetValue("TW3MASTER","TW3_DTMOV")
Local cCodAtend := oModel:GetValue("TW3MASTER","TW3_ATDCOD")
Local cTpRt		:= ""
Local cSitAnt	:= ""

Do Case
	Case Upper(cSitAtend) $  Upper(SIT_ATEND_DEMISSAO)  + '|' + Upper(SIT_ATEND_AFASTA) + '|' + Upper(SIT_ATEND_SUSPENSAO)
		cRet := ""
	
	Case Upper(cSitAtend) == Upper(SIT_ATEND_COBERTURA)

		cTpRt := At581TpRot(cCodAtend)

		If cTpRt $ "2|3"    //Almocista/Jantista.
			cRet := SIT_MOV_RECALMO

		Elseif cTpRt == "1" //Folguista.
			cRet := SIT_MOV_RECFOLG

		Elseif cTpRt == "4" //Ferista.
			cRet := SIT_MOV_RECFERI

		Else
			cSitAnt := Posicione('TW3',1, xFilial('TW3') + oMdlABB:GetValue('ABB_CODTW3') , 'TW3_SITCOD')
	
			If cSitAnt == SIT_MOV_FOLGAFT
				cRet := SIT_MOV_CANCFT
			
			Elseif cSitAnt == SIT_MOV_FOLGACN
				cRet := SIT_MOV_CANCFTCN

			Elseif cSitAnt == SIT_MOV_CNCOMP
				cRet := SIT_MOV_CANCCNCOMP

			Elseif cSitAnt == SIT_MOV_FTREFORCO
				cRet := SIT_MOV_CANCFTREF

			Else
				cRet := SIT_MOV_CANCCOB

			Endif
		Endif

		cRet += SIT_MOV_FALTA   + '|' + SIT_MOV_FOLGA   + '|' + SIT_MOV_HORAEXT + '|' + SIT_MOV_ATRASO + '|' +;
		        SIT_MOV_JORNDIF + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_SAIDANT 
				
		cRet += At336GtCan(oMdlABB)
		
	Case Upper(cSitAtend) == Upper(SIT_ATEND_FALTA)

		If cMovAtend == TIPALO_RESERVA .Or. cMovAtend == TIPALO_COBERTURA
			cRet := SIT_MOV_RETFALT
		Else
			cRet := SIT_MOV_RETFALT + '|' + SIT_MOV_RECOLHE + '|' + SIT_MOV_TROCFUN
		Endif

	Case Upper(cSitAtend) == Upper(SIT_ATEND_NAOALOCADO)
		cRet := SIT_MOV_EFETIVO  + '|' + SIT_MOV_TREINAM  + '|' + SIT_MOV_FOLGUIS 	 + '|' + SIT_MOV_ALMOCIS + '|' + ;
		        SIT_MOV_CORTESI  + '|' + SIT_MOV_REFORCO  + '|' + SIT_MOV_SERVEXT 	 + '|' + SIT_MOV_EXCEDEN + '|' + ;
		        SIT_MOV_RECICLA  + '|' + SIT_MOV_CURSO    + '|' + SIT_MOV_COBERTU 	 + '|' + SIT_MOV_FERISTA + '|' + ;
		        SIT_MOV_ADISPEMP + '|' + cListCob 		  + '|' + cListDia
		
	Case Upper(cSitAtend) == Upper(SIT_ATEND_CURSO)
		cRet := SIT_MOV_RETCURS 

		If !oMdlABB:IsEmpty()
			cRet += '|' + SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_ATRASO + '|' + SIT_MOV_SAIDANT

			cRet += At336GtCan(oMdlABB)

		Endif
	Case Upper(cSitAtend) ==  Upper(SIT_ATEND_RECICLA)
		cRet := SIT_MOV_RETRECI 

		If !oMdlABB:IsEmpty()
			cRet += '|' + SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_ATRASO + '|' + SIT_MOV_SAIDANT

			cRet += At336GtCan(oMdlABB)

		Endif

	Case Upper(cSitAtend) ==  Upper(SIT_ATEND_ADISPEMP)

		cRet := SIT_MOV_CANCADISPEMP 

		If !oMdlABB:IsEmpty()
			cRet += '|' + SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_ATRASO + '|' + SIT_MOV_SAIDANT

			cRet += At336GtCan(oMdlABB)

		Endif

	Case Upper(cSitAtend) == Upper(SIT_ATEND_FOLGA)

		//Se o atendente estiver envolvido na rota de cobertura.
		cTpRt := At581TpRot(cCodAtend)

		If cTpRt $ "2|3"  	//Almocista/Jantista.
			cRet := '|' + SIT_MOV_RECALMO
		Elseif cTpRt == "1" //Folguista.
			cRet := '|' + SIT_MOV_RECFOLG
		Elseif cTpRt == "4" //Ferista.
			cRet := '|' + SIT_MOV_RECFERI
		Endif
		
		//Se for folga aplicada
		If (AtChkFalta(cCodAtend,dDtMov,"4") > 0)
			
			cRet += SIT_MOV_CANCFOL

			//Quando for reserva ou efetivo.
			If At336TGYChk( , cFil, cCodAtend, dDtMov, .T., "3" )
				cRet += SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP
			Endif

		Else //Se for folga de escala.
		
			//Quando for reserva.
			If At336TGYChk( , cFil, cCodAtend, dDtMov, .T., "2" )

				cRet := SIT_MOV_EFETIVO 	+ '|' + SIT_MOV_TREINAM  	+ '|' + SIT_MOV_FOLGUIS + '|' + SIT_MOV_ALMOCIS + '|' + ;
						SIT_MOV_CORTESI 	+ '|' + SIT_MOV_REFORCO  	+ '|' + SIT_MOV_SERVEXT + '|' + SIT_MOV_EXCEDEN + '|' + ;
						SIT_MOV_RECICLA 	+ '|' + SIT_MOV_CURSO    	+ '|' + SIT_MOV_FOLGA   + '|' + SIT_MOV_COBERTU + '|' + ;
						SIT_MOV_FERISTA 	+ '|' + SIT_MOV_FOLGAFT 	+ '|' + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP  + '|' + ;
						SIT_MOV_FTREFORCO  	+ '|' + SIT_MOV_ADISPEMP 	+ '|' + cListDia

			//Quando for efetivo.
			Elseif At336TGYChk( , cFil, cCodAtend, dDtMov, .T., "1" )

				cRet := SIT_MOV_FOLGAFT + "|" + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + "|" + SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO + "|" + SIT_MOV_FTREFORCO + "|"

				If At336TGYRf( cFil, cCodAtend, dDtMov )
					cRet += SIT_MOV_RECREFORCO
				Else
					cRet += SIT_MOV_RECOLHE
				Endif
			Endif
		Endif

	Case Upper(cSitAtend) == Upper(SIT_ATEND_RESERVA)

		If At581TpRot(cCodAtend) $ "1|4"
			cRet := SIT_MOV_FOLGA   + '|' + SIT_MOV_COBERTU + '|' + SIT_MOV_RECFERI + '|' + cListCob 
		Else
			cRet := SIT_MOV_EFETIVO + '|' + SIT_MOV_TREINAM  + '|' + SIT_MOV_FOLGUIS  + '|' + SIT_MOV_ALMOCIS 	 + '|' + ;
			        SIT_MOV_CORTESI + '|' + SIT_MOV_REFORCO  + '|' + SIT_MOV_SERVEXT  + '|' + SIT_MOV_EXCEDEN 	 + '|' + ;
			        SIT_MOV_RECICLA + '|' + SIT_MOV_CURSO    + '|' + SIT_MOV_FOLGA    + '|' + SIT_MOV_COBERTU 	 + '|' + ;
			        SIT_MOV_FERISTA + '|' + SIT_MOV_ADISPEMP + '|' + cListCob 		  + '|' + cListDia
		Endif
		        
		If !oMdlABB:IsEmpty()
			cRet += SIT_MOV_FOLGA   + '|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_FALTA + '|' + SIT_MOV_SAIDANT + '|' + ;
			        SIT_MOV_ATRASO  + '|' + SIT_MOV_JORNDIF + '|' + SIT_MOV_HORAEXT

			cRet += At336GtCan(oMdlABB)

		EndIf
	
	Case Upper(cSitAtend) $ Upper(SIT_ATEND_EFETIVO) + '|' + Upper(SIT_ATEND_DIARIO) .Or. lLibSit
		
		If At336TGYRf( cFil, cCodAtend, dDtMov )
			cRet := SIT_MOV_RECREFORCO
		Else
			cRet := SIT_MOV_RECOLHE
		Endif    
		
		If cMovAtend <> TIPALO_TREINAMENTO
			cRet += '|' + SIT_MOV_RECICLA   + '|' + SIT_MOV_CURSO + '|' + SIT_MOV_FOLGA + '|' + SIT_MOV_TROCFUN + '|' + SIT_MOV_ADISPEMP
		Endif
		        
		If !oMdlABB:IsEmpty()

			If cMovAtend <> TIPALO_TREINAMENTO
				cRet += '|' +  SIT_MOV_JORNDIF + '|' + SIT_MOV_HORAEXT
			Endif

			cRet +=	'|' + SIT_MOV_FALTAAB + '|' + SIT_MOV_FALTA + '|' + SIT_MOV_SAIDANT + '|' + SIT_MOV_ATRASO

			cRet += At336GtCan(oMdlABB)

		EndIf

	Case Upper(cSitAtend) == Upper(SIT_ATEND_FERISTA)

		cRet += '|' + SIT_MOV_RECFERI

	Case Upper(cSitAtend) == Upper(SIT_ATEND_FOLGUISTA)

		cRet += '|' + SIT_MOV_RECFOLG

	Case Upper(cSitAtend) $ Upper(SIT_ATEND_ALMOCISTA) + '|' + Upper(SIT_ATEND_JANTISTA)

		cRet += '|' + SIT_MOV_RECALMO

EndCase

If 	ExistBlock('AT336FIL')
	cRet := ExecBlock("AT336FIL",.F.,.F.,{cSitAtend,cRet,!oMdlABB:IsEmpty()})
EndIf  

Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336FI7()
Filtro da consulta padrão na SX5 para restringir os motivos da movimentação conforme a situação informada.

Motivos Cadastrados:
Cód	Descrição
01	Posto Vago
02	Treinamento
03	Cortesia
04	Reforço
05	Serviço Extra
06	Troca de funcionário
07	Cobertura de Falta
08	Cobertura de Férias
09	Cobertura de Reciclagem
10	Cobertura de Folga
11	Cobertura de Suspensão
12	Cobertura de Saída Antecipada
13	Cobertura de Atraso
14	Cob. de Licença não Remunerada
15	Autorização Coordenação
16	Autorização Gerência
17	Extra Faturado
18	SDF
19	Dobra

@sample 	At336FI7()  

@param		Nenhum

@return cRet - Retorna a string do filtro SXB
	
@author		Ana Maria Utsumi       
@since		19/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336FI7()
Local cRet      := ""
Local cSituacao := AllTrim(FwFldGet("TW3_SITCOD"))

Do Case
	Case cSituacao $ SIT_MOV_EFETIVO + "|" + SIT_MOV_FOLGUIS .Or. lLibSit	            
		cRet := "01|06"										    //Posto Vago e Cobertura de Férias
	Case cSituacao $ SIT_MOV_ALMOCIS
		cRet := "01"
	Case cSituacao == SIT_MOV_TREINAM							
		cRet := "02"											//Treinamento
	Case cSituacao == SIT_MOV_CORTESI							
		cRet := "03"											//Cortesia
	Case cSituacao $ SIT_MOV_REFORCO + '|' + cListDia					
		cRet := "04"											//Reforço
	Case cSituacao == SIT_MOV_SERVEXT							
		cRet := "05"											//Serviço Extra
	Case cSituacao == SIT_MOV_TROCFUN							
		cRet := "06"											//Troca de funcionário
	Case cSituacao $  SIT_MOV_RECOLHE + '|' + SIT_MOV_RECFOLG + '|' + SIT_MOV_RECALMO + '|' + SIT_MOV_RECREFORCO
		cRet := "19|20|21"										/*Autorização Coordenação e Autorização Gerência*/

	Case cSituacao $ SIT_MOV_SAIDANT + '|' + SIT_MOV_JORNDIF	//Saída Antecipada
		cRet := "19|22"											/*Cobertura de Saída Antecipada*/
	Case cSituacao == SIT_MOV_EXCEDEN
		cRet := "15|16"                                         //
	Case cSituacao $ SIT_MOV_HORAEXT + '|' + cListHE
		cRet := "07|13|17"       				
	Case cSituacao $ SIT_MOV_ATRASO
		cRet := "25" 
	Case cSituacao $ SIT_MOV_FALTA + '|' + SIT_MOV_FALTAAB           
		cRet := "27"	
	Case cSituacao $ SIT_MOV_RECICLA          
		cRet := "28"		
	Case cSituacao $ SIT_MOV_CURSO          
		cRet := "29"		
	Case cSituacao $ SIT_MOV_FOLGAFT + '|' + SIT_MOV_FTREFORCO          
		cRet := "30"			
	Case cSituacao $ SIT_MOV_RETFALT         
		cRet := "31"			
	Case cSituacao $ SIT_MOV_FOLGA + '|' + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP          
		cRet := "26"	
	Case cSituacao $ SIT_MOV_CANCFOL	
		cRet := "32"		   					
	Case cSituacao $ SIT_MOV_CANCATR	
		cRet := "33"		   					
	Case cSituacao $ SIT_MOV_CANCADN	
		cRet := "34"		   					
	Case cSituacao $ SIT_MOV_RETCURS	
		cRet := "35"		   					
	Case cSituacao $ SIT_MOV_CANCCOB + '|' + SIT_MOV_CANCFT + '|' + SIT_MOV_CANCFTCN + '|' + SIT_MOV_CANCCNCOMP + '|' + SIT_MOV_CANCFTREF
		cRet := "36"		   					
	Case cSituacao $ SIT_MOV_CANCEXT
		cRet := "37"		   					
	Case cSituacao $ SIT_MOV_RETRECI
		cRet := "38"		   					
	Case cSituacao $ SIT_MOV_FERISTA	
		cRet := "39"		   					
	Case cSituacao $ SIT_MOV_RECFERI	
		cRet := "40"		   					
	Case cSituacao $ SIT_MOV_CANCJORNDIF
		cRet := "43"
	Case cSituacao $ SIT_MOV_ADISPEMP
		cRet := "44"
	Case cSituacao $ SIT_MOV_CANCADISPEMP
		cRet := "45"

EndCase

If ExistBlock("AT336MOT")
	cRet := ExecBlock("AT336MOT",.F.,.F.,{cSituacao,cRet})
EndIf

Return cRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At336FI7Cob()
Filtro da consulta padrão na SX5 para restringir os motivos de cobertura conforme a situação informada.

Motivos Cadastrados:
Cód	Descrição
01	Posto Vago
02	Treinamento
03	Cortesia
04	Reforço
05	Serviço Extra
06	Troca de funcionário
07	Cobertura de Falta
08	Cobertura de Férias
09	Cobertura de Reciclagem
10	Cobertura de Folga
11	Cobertura de Suspensão
12	Cobertura de Saída Antecipada
13	Cobertura de Atraso
14	Cob. de Licença não Remunerada
15	Autorização Coordenação
16	Autorização Gerência
17	Extra Faturado
18	SDF
19	Dobra

@sample 	At336FI7Cob()  

@param		Nenhum

@return cRet - Retorna a string do filtro SXB
	
@author		Leandro Dourado       
@since		19/06/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336FI7Cob()
Local cRet      := ""
Local cSituacao := AllTrim(FwFldGet("TW3_SITCOD"))

Do Case
	Case cSituacao $  SIT_MOV_FALTA   + '|' + SIT_MOV_FALTAAB	//Falta/Falta Abonada
		cRet := "07"											/*Cobertura de Falta*/	
	Case cSituacao $  SIT_MOV_RETFALT + '|' + SIT_MOV_RETCURS   //Retorno de Falta e Retorno de Curso
		cRet := ""												/*Não solicitam motivo*/
	Case cSituacao $  SIT_MOV_RECICLA 
		cRet := "09"
	Case cSituacao == SIT_MOV_CURSO	
		cRet := "23"
	Case cSituacao == SIT_MOV_FOLGA								//Folga
		cRet := "10"											/*Cobertura de Folga*/
	Case cSituacao $  SIT_MOV_RECOLHE 
		cRet := "06|07"										    
	Case cSituacao == SIT_MOV_ATRASO	
		cRet := "13"
	Case cSituacao $  SIT_MOV_FOLGAFT + '|' + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + "|" + cListFT    //Folga Trabalhada - FT  ou Folga Convocação
		cRet := "01|02||03|04|05|07|08|09|10|11|12|13|14|15|16|17|18|24"  		    /*Cobertura de Falta, Cobertura de Férias, Cobertura de Reciclagem, Cobertura de Folga, Cobertura de Suspensão, Cobertura de Atraso, Cobertura de Saída Antecipada, Cob. de Licença não Remunerada, Folga Convocação e Dobra*/
	Case cSituacao $ SIT_MOV_HORAEXT + "|" + cListHE                //Hora Extra
		cRet := "07|13|17"											/*Extra Faturado*/
	Case cSituacao $ SIT_MOV_COBERTU + "|" + cListCob
		cRet := "01|02|03|04|05|07|08|09|10|11|12|13|14|18|24"
EndCase

Return cRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At336StxMt()
Gatilho do código do motivo conforme a situação inserida para o atendente. No detalhamento da regra de negócio algumas situações 
possuem somente um motivo podendo ser associado nestes casos, este único motivo associado precisa ser gatilhado para o campo com 
o código do motivo.

@sample 	At336StxMt()  

@param		Nenhum

@return cRet - Retorna a string com motivo padrão
	
@author		Ana Maria Utsumi       
@since		19/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336StxMt( )
	Local cRet :=""	
	
	cRet := At336FI7()
	
	// Caso haja mais de um motivo para a situação informada, o sistema não gatilha o código, 'ndo o usuário a preencher o motivo manualmente. 
	If Len( StrTokArr(cRet, "|") ) > 1
		cRet := ""
	EndIf
	
Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336GrGat()
Gatilha o valor do campo grupo com base no Item de RH + Escala. 
Além disso, é verificado se o atendente posicionado está livre de restrições operacionais.

@sample 	At336GrGat()  
@return 	nGrupo,		Number, Retorna o número do grupo disponível
@author		Leandro Dourado     
@since		26/01/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336GrGat()
Local aArea     := GetArea()
Local nRet      := 0
Local cFil      := FwxFilial("TGY")
Local cSituacao := FwFldGet("TW3_SITCOD")
Local cCodTFF   := FwFldGet("TW3_ITRHCT")
Local cEscala   := FwFldGet("TW3_TRSQES")
Local dDtMov    := FwFldGet("TW3_DTMOV") 
Local cCodAtend := FwFldGet("TW3_ATDCOD") 
Local nQtdVen   := 0
Local dDtFim    := Ctod("")
Local cCodLoc   := ""
Local cAliasQry := ""

If !Empty(cCodTFF) .AND. !Empty(cEscala)
	Do Case
		Case cSituacao == SIT_MOV_FOLGUIS
			
			cFil    := FwxFilial("TGZ")
			nQtdVen := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_QTDVEN")
			dDtFim  := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_PERFIM")
			cCodLoc := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_LOCAL")
			
			If At012Blq(cCodAtend, dDtMov, dDtFim, cCodLoc) //Valida se atendente está livre de restrições operacionais  
				nRet := At336TGZGr(cFil, cCodTFF, dDtMov, dDtFim, cEscala, cCodAtend)
			EndIf
		
		Otherwise
		
			cFil    := FwxFilial("TGY")
			nQtdVen := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_QTDVEN")
			cCodLoc := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_LOCAL")
	
			If cSituacao $ SIT_MOV_FOLGAFT +"|"+ SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + "|" + cListFT
				dDtFim := dDtMov
			Else
				dDtFim := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_PERFIM")
			EndIf
			
			If At012Blq(cCodAtend, dDtMov, dDtFim, cCodLoc) //Valida se atendente está livre de restrições operacionais  
				nRet := At336GrpDp(cFil, cCodTFF, dDtMov, dDtFim, cEscala, cCodAtend)
			EndIf
	EndCase
	
EndIf

RestArea( aArea )

Return nRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336GrpDp()
Verifica qual o número do próximo grupo disponível para alocação. Será verificado
se existe "quebra" na sequência de grupos, e se existir, este será o próximo número
de grupo a ser utilizado, caso contrário, retorna próximo grupo após o último utilizado.

@sample 	At336GrpDp(cFil, cCodTFF, dDtIni)  

@param		cFil,		String, Código da filial do Recurso Humano do contrato
@param		cCodTFF,	String,	Código do Recurso Humano do contrato
@param		dDtIni,		Date,	Data da movimentação

@return 	nGrupo,		Number, Retorna o número do grupo disponível
	
@author		Ana Maria Utsumi       
@since		22/12/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336GrpDp(cFil, cCodTFF, dDtIni, dDtFim, cCodTDX,cCodAtend)
Local cAliasQry  := GetNextAlias()
Local cTabQry    := ""
Local tmpQry 	 := ""	
Local tmpQryProx := ""
Local nGrupo 	 := 0	
Local nCount     := 0
Local lVincula   := .T.

Default dDtFim   := Ctod("")
Default cCodTDX  := ""

If Empty(dDtFim) .OR. dDtIni == dDtFim
	cCondPer := "%('"+Dtos(dDtIni)+"' BETWEEN ORD.TGY_DTINI AND ORD.TGY_DTFIM)%"
Else
	cCondPer := "%((NOT (('"+Dtos(dDtIni)+"' > ORD.TGY_DTFIM OR '"+Dtos(dDtFim)+"' < ORD.TGY_DTINI))))%"
EndIf

cAliasQry := GetNextAlias()
BeginSql Alias cAliasQry
	SELECT ORD.TGY_CODTFF, ORD.TGY_GRUPO, ORD.TGY_ATEND,
	       DENSE_RANK() OVER (ORDER BY ORD.TGY_GRUPO ASC) AS ORDEM  
	FROM %table:TGY% ORD
	WHERE ORD.TGY_FILIAL = %Exp:cFil%
      AND ORD.TGY_CODTFF = %Exp:cCodTFF%
      AND ORD.TGY_CODTDX = %Exp:cCodTDX%
      AND ORD.%NotDel%
      AND %Exp:cCondPer%
	GROUP BY ORD.TGY_CODTFF, ORD.TGY_GRUPO, ORD.TGY_ATEND
	ORDER BY ORDEM
EndSql

(cAliasQry)->(DbGoTop())

// Caso o atendente seja encontrado, significa que ele já está vinculado ao posto no turno, horário e período selecionados. Caso contrário, ele poderá ser vinculado ao posto.
While (cAliasQry)->(!EOF()) .AND. lVincula
	If (cAliasQry)->TGY_ATEND == cCodAtend
		lVincula := .F.
		nGrupo   := 0
	EndIf
	If lVincula .AND. nGrupo == 0 .AND. (cAliasQry)->TGY_GRUPO <> (cAliasQry)->ORDEM
		nGrupo := (cAliasQry)->ORDEM
	EndIf
	nCount++
	(cAliasQry)->(DbSkip())
EndDo

If lVincula .AND. nGrupo == 0
	nGrupo := nCount+1
EndIf

(cAliasQry)->(DbCloseArea())

Return nGrupo

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336TGZGr()
Verifica qual o número do próximo grupo disponível para alocação, quando se tratar da implantação de um folguista. 
Será verificado se existe "quebra" na sequência de grupos, e se existir, este será o próximo número
de grupo a ser utilizado, caso contrário, retorna próximo grupo após o último utilizado.

@sample 	At336TGZGr(cFil, cCodTFF, dDtIni)  

@param		cFil,		String, Código da filial do Recurso Humano do contrato
@param		cCodTFF,	String,	Código do Recurso Humano do contrato
@param		dDtIni,		Date,	Data da movimentação

@return 	nGrupo,		Number, Retorna o número do grupo disponível
	
@author		Leandro F. Dourado       
@since		15/02/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336TGZGr(cFil, cCodTFF, dDtIni, dDtFim, cCodTGX,cCodAtend)
Local cAliasQry  := GetNextAlias()
Local cTabQry    := ""
Local tmpQry 	 := ""	
Local tmpQryProx := ""
Local nGrupo 	 := 0	
Local nCount     := 0
Local lVincula   := .T.

Default dDtFim   := Ctod("")
Default cCodTGX  := ""

If Empty(dDtFim) .OR. dDtIni == dDtFim
	cCondPer := "%('"+Dtos(dDtIni)+"' BETWEEN ORD.TGZ_DTINI AND ORD.TGZ_DTFIM)%"
Else
	cCondPer := "%((NOT (('"+Dtos(dDtIni)+"' > ORD.TGZ_DTFIM OR '"+Dtos(dDtFim)+"' < ORD.TGZ_DTINI))))%"
EndIf

cAliasQry := GetNextAlias()
BeginSql Alias cAliasQry
	SELECT ORD.TGZ_CODTFF, ORD.TGZ_GRUPO, ORD.TGZ_ATEND,
	       DENSE_RANK() OVER (ORDER BY ORD.TGZ_GRUPO ASC) AS ORDEM  
	FROM %table:TGZ% ORD
	WHERE ORD.TGZ_FILIAL = %Exp:cFil%
      AND ORD.TGZ_CODTFF = %Exp:cCodTFF%
      AND ORD.TGZ_CODTDX = %Exp:cCodTGX%
      AND ORD.%NotDel%
      AND %Exp:cCondPer%
	GROUP BY ORD.TGZ_CODTFF, ORD.TGZ_GRUPO, ORD.TGZ_ATEND
	ORDER BY ORDEM
EndSql

(cAliasQry)->(DbGoTop())

// Caso o atendente seja encontrado, significa que ele já está vinculado ao posto no turno, horário e período selecionados. Caso contrário, ele poderá ser vinculado ao posto.
While (cAliasQry)->(!EOF()) .AND. lVincula
	If (cAliasQry)->TGZ_ATEND == cCodAtend
		lVincula := .F.
		nGrupo   := 0
	EndIf
	If lVincula .AND. nGrupo == 0 .AND. (cAliasQry)->TGZ_GRUPO <> (cAliasQry)->ORDEM
		nGrupo := (cAliasQry)->TGZ_GRUPO
	EndIf
	nCount++
	(cAliasQry)->(DbSkip())
EndDo

If lVincula .AND. nGrupo == 0
	nGrupo := nCount+1
EndIf

(cAliasQry)->(DbCloseArea())

Return nGrupo

//------------------------------------------------------------------------------
/*/{Protheus.doc} At336Rsrv()
Aloca o atendente no posto de reserva técnica configurado para o ambiente.

@sample 	At336Rsrv(cFil, cCodTec, dDtRef)  

@param		cFil,		String, Código da filial do atendente
@param		cCodTec,	String,	Código do atendente
@param		dDtRef,		Date,	Data da movimentação

@return 	aErro,	Array, Retorna array preenchida caso haja erro de gravação
	
@author		Ana Maria Utsumi       
@since		28/12/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At336Rsrv(cFil, cCodTec, dDtRef, cTipAlo, dDtFim, cResPad, cCodTW3 )
Local cOrcRes	:= SuperGetMV("MV_GSORCRE",,,cFil)
Local cEscala	:= ""
Local aAreaTFF	:= TFF->(GetArea())
Local aAreaTDX	:= TDX->(GetArea())
Local aAreaTGY	:= TGY->(GetArea())
Local aAreaTCU	:= TCU->(GetArea())
Local aArea 	:= GetArea()
Local lRet		:= .T.
Local aErro		:= {}
Local aFolder	:= {}
Local nTotLinhas:= 0
Local nGrupo	:= 1
Local oModelTGY	:= Nil
Local oAuxTDX	:= Nil
Local oAux		:= Nil
Local oStruct	:= Nil
Local cEfetiv	:= ""
Local cTurno	:= ""
Local cSeq		:= ""
Default cTipAlo	:= ""
Default dDtFim  := Ctod("")
Default cCodTW3 := ""

If MsgYesNo(STR0155,STR0037) //"Gostaria de retornar o atendente ao posto de reserva configurado no cadastro do atendente?","Atenção."
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1)) // AA1_FILIAL+AA1_CODTEC
	If AA1->(DbSeek(xFilial("AA1",cFil)+cCodTec))

		cEscala := AA1->AA1_ESCALA
		cTurno 	:= AA1->AA1_TURNO
		cSeq	:= AA1->AA1_SEQTUR
		cResPad := At020RsTff(cFil,cOrcRes,cEscala)
		
		If Empty(cResPad)
			Help( , , "At336Rsrv", , STR0156, 1, 0,,,,,,{STR0157+Alltrim(cOrcRes)+; //"Não foi possível encontrar o posto de reserva."##"Verifique as datas de alocação no orçamento: "			
														 STR0158+Alltrim(cEscala)+"."}) //" ou se existe o posto com a escala: "
			lRet := .F.
		Endif
	Endif
Else
	While .T.
		lRet := ConPad1(,,,"TDXRES")
		If !lRet
			Help( , , "At336Rsrv", , STR0159 , 1, 0,,,,,,{STR0160}) //"Não é possível sair sem escolher um posto de reserva."##"Selecione um posto de reserva."
		Else
			Exit
		Endif		
	EndDo

	If Empty(aInfoRes)
		lRet := .F.
	Endif

	If lRet
		cResPad := aInfoRes[1]
		cEscala := aInfoRes[3]
		cTurno 	:= aInfoRes[4]
		cSeq	:= aInfoRes[5]

		DbSelectArea("AA1")
		AA1->(DbSetOrder(1)) // AA1_FILIAL+AA1_CODTEC
		If AA1->(DbSeek(xFilial("AA1",cFil)+cCodTec))
			Reclock("AA1",.F.)
				AA1->AA1_TURNO 	:= cTurno
				AA1->AA1_SEQTUR := cSeq
				AA1->AA1_ESCALA := cEscala
			AA1->(MsUnlock())
		Endif
	Endif
Endif

If lRet
	//Buscar Posto 
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))	//TFF_FILIAL + TFF_COD
	If TFF->(DbSeek(xFilial("TFF") + cResPad))
		cEscala := TFF->TFF_ESCALA
		
		If Empty(cTipAlo)
			//Buscar por tipo de alocação da reserva se não for passado por parãmetro.
			DbSelectArea("TCU")
			TCU->(DbSetOrder(1))	//TCU_FILIAL + TCU_COD
			If TCU->(DbSeek(xFilial("TCU") + "RES"))
				cTipAlo := "RES"
			EndIf	
		Endif	
		
		//Buscar registro de escala efetivo
		DbSelectArea("TDX")
		TDX->(DbSetOrder(2))	//TDX_FILIAL + TDX_CODTDW + TDX_TURNO + TDX_SEQTUR
		TDX->(DbSeek(xFilial("TDX") + cEscala+cTurno+cSeq ))
		
		cEfetiv	:= TDX->TDX_COD
				
		//Buscar o grupo conforme a configuração do efetivo.	
		nGrupo := At336GrpDp(cFil, cResPad, dDtRef, dDtRef, cEfetiv, cCodTec)
		
		///Grava registro de atendente em posto de reserva técnica
		DbSelectArea("TGY")
		TGY->(DbSetOrder(1))	//TGY_FILIAL+TGY_ESCALA+TGY_CODTDX+TGY_CODTFF+TGY_ITEM                                                                                                            
								
		oModelTGY := FWLoadModel('TECA580E')
					
		oModelTGY:SetOperation( MODEL_OPERATION_UPDATE )
		oModelTGY:GetModel( 'TGYDETAIL' ):SetLoadFilter( , " ( TGY_ATEND = '"+cCodTec+"' )" )
	    lRet 	:= oModelTGY:Activate()
					
		If lRet
			oAuxTDX	:= oModelTGY:GetModel( 'TDXDETAIL' )
			oAux	:= oModelTGY:GetModel( 'TGYDETAIL' )
			oStruct	:= oAux:GetStruct()
								
		    AAdd(aFolder,1)
					
			At580VdFolder(aFolder)	//Definir nome da pasta que indica a alocação de efetivos
			
			If oAuxTDX:SeekLine({{"TDX_COD",cEfetiv}})		
	
				If !Empty( oAux:GetValue('TGY_ATEND') )
					nTotLinhas := oAux:Length()
					If nTotLinhas >= 1
						lRet := (oAux:AddLine() == (nTotLinhas +1))
					EndIf
				EndIf
						
				//Retorna o número do próximo item da alocação
				cItem := At336TGYIt(cFil, cResPad)
				lRet := oAux:SetValue('TGY_FILIAL', cFil)
				lRet := oAux:SetValue('TGY_ATEND' , cCodTec)
				lRet := oAux:SetValue('TGY_ESCALA', cEscala)
				lRet := oAux:SetValue('TGY_DTINI' , dDtRef)
		
				//Quando for curso ou reciclagem altera a data fim.
				If !Empty(dDtFim)
					lRet := oAux:SetValue('TGY_DTFIM', dDtFim )
				Endif
		
				lRet := oAux:SetValue('TGY_GRUPO' , nGrupo)
				lRet := oAux:SetValue('TGY_ITEM'  , cItem) 
				lRet := oAux:SetValue('TGY_TIPALO', cTipAlo)

				If !Empty(cCodTW3)
					lRet := oAux:SetValue('TGY_CODTW3', cCodTW3)					
				Endif

				If (lRet := oModelTGY:VldData())
					lRet := oModelTGY:CommitData()
					If lRet
						cFilAtd   := cFil			
					Endif
				EndIf
			Endif
		EndIf
					
		If !lRet
			aErro   := oModelTGY:GetErrorMessage()
		EndIf
			
		oModelTGY:DeActivate()
		oModelTGY:Destroy()
	
		FreeObj(oModelTGY)
		oModelTGY := Nil
		DelClassIntF()
		
	Endif 	
Endif


RestArea(aAreaTFF)
RestArea(aAreaTDX)
RestArea(aAreaTGY)
RestArea(aAreaTCU)
RestArea(aArea)

Return aErro


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TGYIt()
Retorna o próximo número do item da TGY

@sample		At336TGYIt(cFil, cCodTFF)

@param		cFil, 		String,	Código da filial do Recurso Humano do contrato
@param		cCodTFF, 	String,	Código do Recurso Humano do contrato

@return		cItem,		String,	Retorna o próximo item da TGY a utilizar

@author 	Ana Maria Utsumi
@since		28/12/2016
@version 	P12
     
@return Nil 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At336TGYIt(cFil, cCodTFF)
Local cTmpQry 	:= GetNextAlias()
Local aArea 	:= GetArea()
Local cItem	  	:= ""

//Localiza último item da TGY
BeginSql Alias cTmpQry
	SELECT ISNULL(MAX(TGY_ITEM),'00') AS ULTIMO
 	FROM %table:TGY% TGY
 	WHERE TGY.TGY_FILIAL=%Exp:cFil%
 	  AND TGY.TGY_CODTFF=%Exp:cCodTFF%
      AND TGY.%NotDel%
EndSql

cItem := StrZero(Val(Soma1((cTmpQry)->ULTIMO)), TamSX3("TGY_ITEM")[1],0)

(cTmpQry)->(DbCloseArea())

RestArea(aArea)

Return cItem

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TGZIt()
Retorna o próximo número do item da TGZ.

@sample		At336TGZIt(cFil, cCodTFF)

@param		cFil, 		String,	Código da filial do Recurso Humano do contrato
@param		cCodTFF, 	String,	Código do Recurso Humano do contrato

@return		cItem,		String,	Retorna o próximo item da TGZ a utilizar

@author 	Ana Maria Utsumi
@since		28/12/2016
@version 	P12
     
@return Nil 
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At336TGZIt(cFil, cCodTFF)
Local cTmpQry 	:= GetNextAlias()
Local aArea 	:= GetArea()
Local cItem	  	:= ""

//Localiza último item da TGZ
BeginSql Alias cTmpQry
	SELECT ISNULL(MAX(TGZ_ITEM),'00') AS ULTIMO
 	FROM %table:TGZ% TGZ
 	WHERE TGZ.TGZ_FILIAL = %Exp:cFil%
 	  AND TGZ.TGZ_CODTFF = %Exp:cCodTFF%
      AND TGZ.%NotDel%
EndSql

cItem := StrZero(Val(Soma1((cTmpQry)->ULTIMO)), TamSX3("TGY_ITEM")[1],0)

(cTmpQry)->(DbCloseArea())

RestArea(aArea)

Return cItem


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336RtCob()
Realiza a alocação do atendente posicionado em uma rota de cobertura. A alocação é feita pelo At581MvRmv, do TECA581.
Após finalizar a alocação, os postos da rota serão informados no array aCodTFF para que sejam geradas as agendas para todos os postos dessa rota.

@sample		At336RtCob(cCodAtend,cCodRtCob)

@param		cFil, 		String,	Código da filial do Recurso Humano do contrato
@param		cCodAtend, 	String,	Código do atendente que será vinculado à rota de cobertura
@param		cCodRtCob, 	String,	Código da rota de cobertura na qual o atendente será associado.

@return		lRet,		Lógico,	Retorna se houve a correta associação do atendente à rota de cobertura.

@author 	Leandro F. Dourado
@since		17/02/17
@version 	P12
     
@return Nil 
/*/
//--------------------------------------------------------------------------------------------------------------------
Function At336RtCob(cCodAtend,cCodRtCob,aCodTFF,cTpOper,cRtTipo,cCobert)
Local aArea := GetArea()
Local lRet  := .F.
Default cCobert	:= ""

DbSelectArea("TW0")
TW0->(DbSetOrder(1)) // TW0_FILIAL+TW0_COD

DbSelectArea("TW1")
TW1->(DbSetOrder(1)) //TW1_FILIAL+TW1_CODTW0+TW1_COD 

If TW0->(DbSeek(FwxFilial("TW0")+cCodRtCob))
	
	cRtTipo := TW0->TW0_TIPO

	lRet := At581MvRmv( cTpOper,,, .T., cCodAtend, cCobert )
		
	If cTpOper == "MV" .And. TW0->TW0_TIPO $ "1|2|3"
		If lRet
			If TW1->(DbSeek(FwxFilial("TW1")+cCodRtCob))
				While TW1->(TW1_FILIAL+TW1_CODTW0) == FwxFilial("TW1")+cCodRtCob .AND. TW1->(!EOF())
					Aadd(aCodTFF,TW1->TW1_CODTFF)
					TW1->(DbSkip())
				EndDo
			EndIf
		Else
			If !lRet
				Help( , , "At336RtCob", , STR0122, 1, 0,,,,,,{STR0123}) //"O processo de associação do atendente à rota de cobertura encontrou problemas!"###"Verifique se todos os postos associados à rota de cobertura estão dentro do período de vigência!"
			Endif
		EndIf
	EndIf
	
EndIf

RestArea( aArea )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336RecTGY
Ao utilizar a opção de recolhimento, essa função será chamada para que haja manutenção da TGY, 
onde a data final de alocação será alterado para a data anterior à data da movimentação. 
Caso o atendente seja recolhido no mesmo dia em que foi alocado, o registro na TGY será deletado.
A chamada dessa função é feita a partir do AtTW5Grv().

@author  Leandro Dourado 
@param   cIDcFal  , Caracter, Utilizado para localizar o código da TFF, para buscar o registro da TGY onde a manutenção será feita.
@param   cCodAtend, Caracter, Código do atendente que será recolhido.
@param   dDtMov   , Data    , Data da movimentação. A data final na TGY onde a manutenção será feita será alterada para a data anterior à esta data.
@param   cCodTFF  , Caracter, Código do posto do qual o atendente será recolhido.  Essa variável é passada por referência e será retornada para a AtTW5Grv().
@param   cCodTDX  , Caracter, Código da escala na qual o atendente será recolhido. Essa variável é passada por referência e será retornada para a AtTW5Grv().
@version 12.1.14
@since   19/01/2017
@return  Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336RecTGY( cIDcFal, cCodAtend, dDtMov, cCodTFF, cCodTDX )
Local aArea      	:= GetArea()
Local cAliasTGY  	:= ""
Local cAliasTGZ  	:= ""
Local oModel     	:= Nil
Local oMdlTDX    	:= Nil
Local oMdlTGY    	:= Nil
Local nOperation 	:= 0
Local lDelete    	:= .F.
Local lRet       	:= .T.

Default cCodTFF  := ""
Default cCodTDX  := ""

DbSelectArea("ABQ")
ABQ->(DbSetOrder(1)) //ABQ_FILIAL+ABQ_CONTRT+ABQ_ITEM+ABQ_ORIGEM

If ABQ->(DbSeek(FwxFilial("ABQ")+cIDcFal))
	
	cCodTFF := ABQ->ABQ_CODTFF
	
	cAliasTGY := GetNextAlias()
	BeginSql Alias cAliasTGY
		SELECT *, TGY.R_E_C_N_O_ AS RECNOTGY
		FROM %table:TGY% TGY
		WHERE TGY.TGY_FILIAL = %xFilial:TGY%
	      AND TGY.TGY_CODTFF = %Exp:cCodTFF%
	      AND TGY.TGY_ATEND  = %Exp:cCodAtend%
	      AND TGY.%NotDel%
	      AND (%Exp:dDtMov% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM)
	EndSql
	
	(cAliasTGY)->(DbGoTop())
	
	If (cAliasTGY)->(!EOF())
	
		If (cAliasTGY)->TGY_DTINI == Dtos(dDtMov)
			lDelete    := .T.
		EndIf
		
		cCodTDX := (cAliasTGY)->TGY_CODTDX
		
		DbSelectArea("TFF")
		TFF->(DbSetOrder(1)) //TFF_FILIAL+TFF_COD
		
		If TFF->(DbSeek(FwxFilial("TFF")+cCodTFF))

			At580bKill()

			At580EGHor(.F.)
			
			oModel := FwLoadModel("TECA580E")
			oModel:SetOperation(MODEL_OPERATION_UPDATE)
			oModel:GetModel( 'TGYDETAIL' ):SetLoadFilter( , " ( TGY_ATEND = '"+cCodAtend+"' )" )
			oModel:Activate()
			
			oMdlTDX := oModel:GetModel("TDXDETAIL")
			If oMdlTDX:SeekLine({{"TDX_COD" , (cAliasTGY)->TGY_CODTDX}},.F.)
				At580VdFolder({1})
				oMdlTGY := oModel:GetModel("TGYDETAIL")
				
				If oMdlTGY:SeekLine({{"TGY_ITEM" , (cAliasTGY)->TGY_ITEM}},.F.)
					If lDelete
						oMdlTGY:DeleteLine()
					Else
						//Grava novamente o atendete para disparar gatilho das horas flexiveis.
						//oMdlTGY:SetValue("TGY_ATEND" ,	cCodAtend	)
						oMdlTGY:SetValue("TGY_ULTALO",	dDtMov-1	)
						oMdlTGY:SetValue("TGY_DTFIM" ,	dDtMov-1	)
					EndIf
					lRet := oModel:VldData()
					If ( lRet )											
						lRet  := oModel:CommitData() //Grava Model
					Else
						aErro := oModel:GetErrorMessage()
						Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )	
					EndIf
					
					oModel:DeActivate()
					oModel:Destroy()
				
					FreeObj(oModel)
					oModel := Nil
					DelClassIntF()

				Endif
			EndIf
		EndIf
		
	EndIf
	
	(cAliasTGY)->(DbCloseArea())
	
EndIf

RestArea( aArea )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtVldObrig
Função que valida os campos obrigatórios de acordo com a situação informada.

@author  Leandro Dourado 
@param   oModel, Objeto, Modelo de dados que será avaliado.
@version 12.1.14
@since   19/01/2017
@return  Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtVldObrig( oModel )
Local lRet      := .T.
Local nX        := 0
Local nY        := 0
Local nZ        := 0
Local aCpoTW3   := {}
Local aCpoABB   := {}
Local cCpoABB   := ""
Local cMsgErro  := ""
Local nLinObg   := 0
Local oMdlTW3   := oModel:GetModel("TW3MASTER")
Local oMdlABB   := oModel:GetModel("ABBDETAIL")
Local cSituacao := oMdlTW3:GetValue("TW3_SITCOD")
Local aAreaSX3  := SX3->(GetArea())
Local xValor    := Nil

If Empty(cSituacao)
	lRet := .F.
	Help("",1,"OBRIGAT",,STR0074,2,0) //"O campo obrigatório 'Situação' deve ser preenchido!"
EndIf

If lRet .AND. lChkWhen
	Do Case
		Case cSituacao $ SIT_MOV_EFETIVO + "|" + SIT_MOV_CORTESI 	+ "|" + ;
			             SIT_MOV_REFORCO + "|" + SIT_MOV_SERVEXT 	+ "|" + ;
			             SIT_MOV_EXCEDEN + "|" + SIT_MOV_FTREFORCO 	+ "|" + cListDia 

			Aadd(aCpoTW3,"TW3_ITRHCT")
			Aadd(aCpoTW3,"TW3_GRPESC")
			
		Case cSituacao == SIT_MOV_TREINAM
			Aadd(aCpoTW3,"TW3_ITRHCT")
			Aadd(aCpoTW3,"TW3_GRPESC")
			Aadd(aCpoTW3,"TW3_QTDIAS")

		Case cSituacao $ SIT_MOV_ALMOCIS  + "|" + SIT_MOV_FOLGUIS + "|" + SIT_MOV_FERISTA + "|" + ;
						 SIT_MOV_RECALMO  + "|" + SIT_MOV_RECFOLG + "|" + SIT_MOV_RECFERI 

			Aadd(aCpoTW3,"TW3_RTACOD")

		Case cSituacao $ SIT_MOV_TROCFUN
			Aadd(aCpoTW3,"TW3_TECSUB")  

		Case cSituacao $ SIT_MOV_FOLGA
			If !Empty(oMdlTW3:GetValue("TW3_TECSUB"))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf

		Case cSituacao == SIT_MOV_FALTA
			If !Empty(oMdlTW3:GetValue("TW3_TECSUB"))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf

		Case cSituacao $ SIT_MOV_COBERTU + "|" + SIT_MOV_FOLGAFT + "|" + SIT_MOV_FOLGACN + "|" + SIT_MOV_CNCOMP + '|' + cListFT + "|" + cListCob

			If Empty(oMdlTW3:GetValue("TW3_ITRHCT")) .And. oMdlTW3:GetValue("TW3_GRPESC") == 0
				Aadd(aCpoTW3,"TW3_ITCOBE")
				Aadd(aCpoTW3,"TW3_MOTCOB")
			Endif

		Case cSituacao == SIT_MOV_RECOLHE
			If !Empty(oMdlTW3:GetValue("TW3_TECSUB"))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf

		Case cSituacao == SIT_MOV_FALTAAB
			Aadd(aCpoTW3,"TW3_QTDIAS")
			If !Empty(oMdlTW3:GetValue("TW3_ITCOBE")) .Or. !Empty(oMdlTW3:GetValue("TW3_TECSUB"))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf			

		Case cSituacao $ SIT_MOV_RECICLA + "|" + SIT_MOV_CURSO
			Aadd(aCpoTW3,"TW3_QTDIAS")
			If !Empty(oMdlTW3:GetValue("TW3_TECSUB"))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf

		Case cSituacao == SIT_MOV_SAIDANT .And. oMdlAbb:Length() > 0
			// Apenas o horário final da segunda agenda deverá ser obrigatório.
			Aadd(aCpoABB,{{"ABB_HRFIM"},oMdlAbb:Length()})
				
		Case cSituacao == SIT_MOV_JORNDIF
			// Apenas o horário final da segunda agenda deverá ser obrigatório, afinal ao alterar a hora inicial o horário final será alterado.
			Aadd(aCpoABB,{{"ABB_HRFIM"},2})
			
		Case cSituacao $ SIT_MOV_HORAEXT + "|" + cListHE 
			/* 
				No caso da hora extra, será validado se algum horário (entrada ou saída) de alguma das agendas disponíveis foi alterada. 
				Ou seja, é obrigatório que apenas um dos horários seja alterado.
			*/
			Aadd(aCpoABB,{{"ABB_HRINI","ABB_HRFIM"}})

			If !(Alltrim(Upper(cSitAtend)) $ Upper(SIT_ATEND_RESERVA) + "|" + Upper(SIT_ATEND_EFETIVO) + '|' + Upper(SIT_ATEND_DIARIO) + "|" + Upper(SIT_ATEND_COBERTURA))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf

			
		Case cSituacao == SIT_MOV_ATRASO
			Aadd(aCpoABB,{{"ABB_HRINI"}})
			If !Empty(oMdlTW3:GetValue("TW3_TECSUB"))
				Aadd(aCpoTW3,"TW3_MOTCOB")
			EndIf
						
	EndCase
	
	If cSituacao <> SIT_MOV_COBERTU
		Aadd(aCpoTW3,"TW3_MOTCOD")
	Endif

	If ExistBlock("AT336OBTW3")
		aCpoTW3 := ExecBlock("AT336OBTW3",.F.,.F.,{cSituacao,aCpoTW3})
	EndIf	
	
	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	
	For nX := 1 To Len(aCpoTW3)
		If Empty(oMdlTW3:GetValue(aCpoTW3[nX]))
			SX3->(DbSeek(aCpoTW3[nX]))
			Help("",1,"OBRIGAT",,STR0075+AllTrim(X3Titulo())+STR0076,2,0) //"Para a situação informada, o campo '"###"' deve ser preenchido!"
			lRet := .F.
			Exit
		EndIf
	Next nX
	
	If lRet
		For nX := 1 To Len(aCpoABB)
		
			nLinObg := 0
			
			For nY := 1 To oMdlAbb:Length()
			
				If Len(aCpoABB[nX]) > 1
					nLinObg := aCpoABB[nX,2]
					oMdlAbb:GoLine(nLinObg)
				Else
					oMdlAbb:GoLine(nY)
				EndIf
				
				For nZ := 1 to Len(aCpoABB[nX,1])
				
					cCpoABB := aCpoABB[nX,1,nZ]
					xValor  := Posicione("ABB",8,FwxFilial("ABB")+oMdlAbb:GetValue("ABB_CODIGO"),cCpoABB)
					
					
					If Empty(oMdlAbb:GetValue(cCpoABB)) .OR. xValor == oMdlAbb:GetValue(cCpoABB)
					
						lRet := .F.
						
						// Caso a obrigatoriedade seja para alguma linha específica, sai do laço.
						If nLinObg > 0
							Exit
						EndIf
						
					Else
					
						// Caso alguma linha tenha sido alterada, retorna true e sai do laço.
						lRet := .T.
						Exit
						
					EndIf
					
				Next nZ
				
				// Caso haja alguma alteração, não será necessário avaliar mais campos.
				If lRet
					Exit
				EndIf
					
			Next nY
			
			If !lRet
				SX3->(DbSeek(cCpoABB))
				
				cMsgErro := STR0077+AllTrim(X3Titulo()) //"Para a situação informada, o campo '"
				If nLinObg > 0
					cMsgErro += STR0078+cValToChar(nLinObg) // "' da linha "
				Else
					cMsgErro += "'"
				EndIf
				cMsgErro += STR0079 //" deve ser alterado!"
				
				oModel:GetModel():SetErrorMessage(oModel:GetId(),cCpoABB,oModel:GetModel():GetId(),	cCpoABB,cCpoABB,; 
				cMsgErro, "")		
			EndIf
		Next nX
	EndIf
EndIf

RestArea( aAreaSX3 )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetABBInativas
Pesquisa e retorna as agendas que foram desabilitadas ou habilitadas (ABB_ATIVO = 1/2) ao lançar uma falta, curso ou reciclagem.

@author  Leandro Dourado 
@param   cCodAtend   , Caracter, Atendente no qual serão pesquisadas as agendas.
@param   dDtIni      , Data    , Data inicial do período a ser pesquisado.
@param   dDtFim      , Data    , Data final do período a ser pesquisado.
@param   cCodTW3     , Caracter, Código da TW3 (movimentação feita através do movimentar). Quando passado, é utilizado na pesquisa da ABR.
@param   cMotivo     , Caracter, Código do Motivo de manutenção da agenda. Quando informado, é utilizado na pesquisa da ABR.
@param   lCheckReserv, Lógico  , Indica se serão considerados postos de reserva técnica na pesquisa.
@param   cAtivo		 , Caracter, Indica se localiza as agendas desabilitadas ou habilitadas 1 = ativo / 2 = inativo.
@version 12.1.14
@since   19/01/2017
@return  Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function GetABBInativas( cCodAtend, dDtIni, dDtFim, cCodTW3, cMotivo, lChkReserv, cAtivo )
Local aArea        := GetArea()
Local aManut       := {}
Local cAliasQry    := GetNextAlias()
Local cChvABR      := "%"
Local cChvTCU      := "%"

Default cCodTW3    := ""
Default cMotivo    := ""
Default lChkReserv := .T.
Default cAtivo	   := "2"

If !Empty(cCodTW3)
	cChvABR += " AND ABR.ABR_CODTW3 = '"+cCodTW3+"'"
EndIf

If !Empty(cMotivo)
	cChvABR += " AND ABR.ABR_MOTIVO = '"+cMotivo+"'"
EndIf

cChvABR += "%"

If !lChkReserv
	cChvTCU += " AND TCU.TCU_RESTEC <> '1'"
Endif

cChvTCU += "%"

If Empty(dDtFim)
	dDtFim  := dDtIni
EndIf

BeginSql Alias cAliasQry
	SELECT *
	FROM %table:ABB% ABB
	INNER JOIN %Table:ABR% ABR ON
		  ABR.ABR_FILIAL = %xFilial:ABR%
		  %Exp:cChvABR%
      AND ABR.%NotDel%
  	INNER JOIN %Table:TDV% TDV ON
		  TDV.TDV_FILIAL = %xFilial:TDV%
	  AND TDV.TDV_CODABB = ABB.ABB_CODIGO 
	  AND TDV.TDV_DTREF  BETWEEN %Exp:Dtos(dDtIni)% AND %Exp:Dtos(dDtFim)% 
	  AND TDV.%NotDel%
	INNER JOIN %Table:TCU% TCU ON
		  TCU.TCU_FILIAL = %xFilial:TCU%
	  AND TCU.TCU_COD    = ABB.ABB_TIPOMV
	  AND TCU.%NotDel%
	      %Exp:cChvTCU%
	WHERE ABB.ABB_FILIAL = %xFilial:ABB%
	  AND ABB.ABB_CODTEC = %Exp:cCodAtend%
	  AND ABB.ABB_CODIGO = ABR.ABR_AGENDA
	  AND ABB.ABB_ATIVO  = %Exp:cAtivo%
	  AND ABB.%NotDel%
	ORDER BY %Order:ABB%
EndSql

(cAliasQry)->(DbGoTop())

While (cAliasQry)->(!EOF())
	aAdd(aManut,{(cAliasQry)->ABB_CODIGO,;
				 (cAliasQry)->ABR_MOTIVO,;
				 (cAliasQry)->ABB_FILTEC,;
				 (cAliasQry)->ABB_CODTEC})
	(cAliasQry)->(DbSkip())
EndDo

(cAliasQry)->(DbCloseArea())

RestArea( aArea )

Return aManut


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336DtRef
Retorna a data de referência, para inicializar o campo TW3_DTMOV.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Function At336DtRef()
Local dRet := Ctod("")

If !Empty(dDataRef)
	dRet := dDataRef
Else
	dRet := dDataBase
EndIf

Return dRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TGYChk
Verifica se o atendente posicionado está vinculado na TGY em data igual ou posterior à data de movimentação.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017

@param  cAliasQry , Caracter, Informa o alias temporário que sera utilizado para fazer a query.
@Param  cCodAtend , Caracter, Codigo do atendente que será utilizado na pesquisa
@param  dDtMov    , Data    , Data da movimentação
@param  lDataAtual, Logico  , Indica se faz a busca com base na data atual. Se for passado falso, a pesquisa será feita nas datas futuras à data da movimentação.
@param  cChkReserv, Caracter, 1 - Checa apenas postos efetivos; 2 - Checa apenas postos de reserva; 3 - Checa todos os postos.

@return lRet      , Logico  , Se o atendente estiver vinculado na TGY de qualquer posto, em data igual ou posterior a data atual, retorna verdadeiro.
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TGYChk( cAliasQry, cFil, cCodAtend, dDtMov, lDataAtual, cChkReserv )
Local aArea        := GetArea()
Local lRet         := .T.
Local cChvTGY      := ""
Local cChvTCU      := ""
Local lCloseArea   := .F.
Local cFilTGY      := xFilial("TGY",cFil)
Local cFilTCU      := xFilial("TCU",cFil)

Default cAliasQry  := ""
Default lDataAtual := .F.
Default cChkReserv := "3"

If Empty(cAliasQry)
	cAliasQry  := GetNextAlias()
	lCloseArea := .T.
EndIf

If lDataAtual
	cChvTGY := "%'"+Dtos(dDtMov)+"' BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM "
Else
	cChvTGY := "%TGY.TGY_DTINI >= '"+Dtos(dDtMov)+"' "
EndIf

cChvTGY += "%"

Do Case
	Case cChkReserv == "1"
		cChvTCU := "%AND TCU.TCU_RESTEC <> '1'%"
	Case cChkReserv == "2"
		cChvTCU := "%AND TCU.TCU_RESTEC = '1'%"
	Case cChkReserv == "3"
		cChvTCU := "%%"
EndCase

BeginSql Alias cAliasQry
	SELECT *
	FROM %table:TGY% TGY
	
	INNER JOIN %Table:TCU% TCU ON
	  TCU.TCU_FILIAL       =  %Exp:cFilTCU%
	  AND TCU.TCU_COD      =  TGY.TGY_TIPALO
	  AND TCU.%NotDel%
	  %Exp:cChvTCU%
	WHERE TGY.TGY_FILIAL =  %Exp:cFilTGY%
      AND TGY.TGY_ATEND  =  %Exp:cCodAtend%
      AND TGY.%NotDel%
      AND %Exp:cChvTGY%
      ORDER BY TGY.R_E_C_N_O_ DESC
EndSql

(cAliasQry)->(DbGoTop())

lRet := (cAliasQry)->(!Eof()) // Se a query retornar vazia, retorna falso

If lCloseArea
	(cAliasQry)->(DbCloseArea())
EndIf

RestArea( aArea )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TGZChk
Verifica se o atendente posicionado está vinculado na TGZ em data igual ou posterior à data de movimentação.

@author  Leandro Dourado 
@param   cAliasQry, Caracter, Alias temporário que será utilizado na Query. Se for passado em branco, será assumido o valor do GetNextAlias() e o Alias será fechado dentro da própria função.
@param   cFil     , Caracter, Filial da movimentação
@param   cCodAtend, Caracter, Código do atendente que será recolhido da TGZ.
@param   dDtMov   , Data    , Data do movimentação de recolhimento.
@param   cCodTFF  , Caracter, Código da TFF. Se informado, o sistema fará a busca em um posto específico. Se  não, será feita pesquisa em todos os postos.
@param   lChkAlmoc, Logico
@version 12.1.14
@since   19/01/2017
@return  lRet, Logico, Se o atendente estiver vinculado na TGY de qualquer posto, em data igual ou posterior a data atual, retorna verdadeiro.
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TGZChk( cAliasQry, cFil, cCodAtend, dDtMov, cCodTFF, lChkAlmoc )
Local aArea        := GetArea()
Local lRet         := .T.
Local lCloseArea   := .F.
Local cFilTGZ      := xFilial("TGZ",cFil)
Local cChvTGZ      := "%"

Default cAliasQry  := ""
Default cCodTFF    := ""
Default lChkAlmoc  := .T.

If !Empty(cCodTFF)
	cChvTGZ += "AND TGZ.TGZ_CODTFF  = '" + cCodTFF + "' "
EndIf

If lChkAlmoc
	cChvTGZ += "AND TGZ.TGZ_CODTW0  <> '' "
Else
	cChvTGZ += "AND TGZ.TGZ_CODTW0  =  '' "
EndIf

cChvTGZ += "%"

If Empty(cAliasQry)
	cAliasQry  := GetNextAlias()
	lCloseArea := .T.
EndIf

BeginSql Alias cAliasQry
	SELECT *
	FROM %table:TGZ% TGZ
	WHERE TGZ.TGZ_FILIAL  = %Exp:cFilTGZ%
      AND TGZ.TGZ_ATEND   = %Exp:cCodAtend%
      AND %Exp:dDtMov% BETWEEN TGZ.TGZ_DTINI AND TGZ.TGZ_DTFIM
      AND TGZ.%NotDel%
      %Exp:cChvTGZ%
EndSql

(cAliasQry)->(DbGoTop())

lRet := (cAliasQry)->(!Eof()) // Se a query retornar vazia, retorna falso.

If lCloseArea
	(cAliasQry)->(DbCloseArea())
EndIf

RestArea( aArea )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtDelCurso
Função responsável por desfazer o lançamento de curso/reciclagem. É chamada a partir da situação de cancelamento de curso/reciclagem.
Caso o atendente tenha sido movimentado para um curso ou reciclagem na mesma data do cancelamento, 
a movimentação de curso/reciclagem será estornada. Caso contrário, o atendente estará em curso ou reciclagem até a data anterior da movimentação.

@author  Leandro Dourado
@param   cFilMov  , Caracter, Filial da movimentação
@param   cCodAtend, Caracter, Codigo do atendente que será movimentado
@param   dDtMov   , Data    , Data da movimentação
@param   cCodTFF  , Caracter, Código da TFF na qual o atendente está alocado. Esse parâmetro é passado em branco devolvido por referência.
@version 12.1.14
@since   05/12/2016
@return  oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtDelCurso(cFilMov, cCodAtend, dDtMov)
Local aArea     := GetArea()
Local aManut   := {}
Local aErro     := {}
Local nRecTW5   := 0
Local cAliasQry := GetNextAlias()
Local lRet      := .T.
Local cFilTW5   := xFilial("TW5",cFilMov)
Local oMdlTW5   := Nil
Local cFilSub   := "" 
Local cCodSub   := ""

If lRet
	BeginSql Alias cAliasQry
		SELECT TW5.R_E_C_N_O_ RECNOTW5
		FROM %table:TW5% TW5
		WHERE TW5.TW5_FILIAL = %Exp:cFilTW5%
		AND %Exp:dDtMov% BETWEEN TW5.TW5_DTINI AND TW5_DTFIM
		AND TW5.TW5_ATDCOD   = %Exp:cCodAtend%
		AND TW5.TW5_TPLANC   IN ('2','3','8')
		AND TW5.%NotDel%
		ORDER BY %Order:TW5%
	EndSql
	
	DbSelectArea(cAliasQry)
	(cAliasQry)->(DbGoTop())
	If (cAliasQry)->(!Eof())
		nRecTW5 := (cAliasQry)->RECNOTW5
	EndIf
	(cAliasQry)->(DbCloseArea())
	
	If !Empty(nRecTW5)
		DbSelectArea("TW5")
		TW5->(DbGoTo(nRecTW5))
		
		If dDtMov == TW5->TW5_DTINI
			
			If lRet
				oMdlTW5 := FwLoadModel("TECA336A")
				oMdlTW5:SetOperation(MODEL_OPERATION_DELETE)
				oMdlTW5:Activate()
				lRet := oMdlTW5:VldData()
				If ( lRet )											
					lRet  := oMdlTW5:CommitData()//Grava Model
				Else
					aErro := oMdlTW5:GetErrorMessage()						
					Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )	
				EndIf
			EndIf
		Else
			oMdlTW5 := FwLoadModel("TECA336A")
			oMdlTW5:SetOperation(MODEL_OPERATION_UPDATE)
			oMdlTW5:Activate()
			oMdlTW5:SetValue("TW5MASTER","TW5_DTFIM",dDtMov-1)
			lRet := oMdlTW5:VldData()
			If ( lRet )											
				lRet  := oMdlTW5:CommitData()//Grava Model
			Else
				aErro := oMdlTW5:GetErrorMessage()						
				Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )	
			EndIf
		EndIf
	EndIf
EndIf

RestArea(aArea)

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtPerfilAloc
Função responsável por carregar as informações do perfil de alocação (TECA337) para o movimentar.

@author  Leandro Dourado 
@param   oView, Objeto, Objeto da view do TECA336.
@version 12.1.14
@since   05/12/2016
@return  oModel
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Function AtPerfilAloc(oView,oModel)
Local oMdlTW3 := Nil

Default oModel  := oView:GetModel()

oMdlTW3 := oModel:GetModel("TW3MASTER")

//Caso venha da importação automatica remove todos os perfis de alocação
If !IsInCallStack("TEC335CSV")
	aPerfAloc := TECA337(cFilAnt, oMdlTW3:GetValue("TW3_ATDCOD"),.T.,oMdlTW3:GetValue("TW3_USAFUN"),;
    	                 oMdlTW3:GetValue("TW3_USACGO"),oMdlTW3:GetValue("TW3_USATUR"),oMdlTW3:GetValue("TW3_USASEQ"))
Else
	aPerfAloc := TECA337(cFilAnt, oMdlTW3:GetValue("TW3_ATDCOD"),.F.,"2","2","2","2")
EndIf

oMdlTW3:SetValue("TW3_USAFUN",aPerfAloc[1,1])
oMdlTW3:SetValue("TW3_USACGO",aPerfAloc[2,1])
oMdlTW3:SetValue("TW3_USATUR",aPerfAloc[3,1])
oMdlTW3:SetValue("TW3_USASEQ",aPerfAloc[4,1])

Return


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TipAlo
Função responsável retornar o tipo de alocação de acordo com a situação informada.

@author  Leandro Dourado 
@param   cSituacao, Caracter, Situação de movimentação.
@version 12.1.14
@since   31/03/2017
@return  cTipAlo, Caracter, Tipo de alocação correspondente à situação informada.
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336TipAlo(cSituacao, lEfetiv )
Local cTipAlo := ""

If !lEfetiv
	cTipAlo := TIPALO_DIARIO
Else
	Do Case

		Case cSituacao == SIT_MOV_RECOLHE
				cTipAlo := TIPALO_RESERVA
		Case cSituacao == SIT_MOV_EFETIVO .Or. lLibSit
			cTipAlo := TIPALO_EFETIVOS
		Case cSituacao == SIT_MOV_TREINAM
			cTipAlo := TIPALO_TREINAMENTO
		Case cSituacao == SIT_MOV_CORTESI
			cTipAlo := TIPALO_CORTESIA
		Case cSituacao $ SIT_MOV_REFORCO + '|' + cListDia
			cTipAlo := TIPALO_REFORCO   
		Case cSituacao == SIT_MOV_SERVEXT
			cTipAlo := TIPALO_EFETIVOS   
		Case cSituacao $ SIT_MOV_COBERTU + "|" + cListFT + "|" + cListCob
			cTipAlo := TIPALO_COBERTURA
		Case cSituacao == SIT_MOV_EXCEDEN
			cTipAlo := TIPALO_EXCEDENTE
		Case cSituacao $ SIT_MOV_RECICLA + '|' + SIT_MOV_RETRECI
			cTipAlo := TIPALO_RECLICAGEM
		Case cSituacao $ SIT_MOV_CURSO + '|' + SIT_MOV_RETCURS
			cTipAlo := TIPALO_CURSO 
		Case cSituacao $ SIT_MOV_ADISPEMP + '|' + SIT_MOV_CANCADISPEMP
			cTipAlo := TIPALO_ADISPEMP
		Case cSituacao $ SIT_MOV_FTREFORCO + '|' + SIT_MOV_FOLGAFT
			cTipAlo := TIPALO_FOLGATRAB
	EndCase
Endif

Return cTipAlo

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtTFFManut
Retorna os postos (TFF) que sofreram manutenção (ABR) sem que tenha sido informado um atendente para a cobertura.

@author  Leandro Dourado 
@param   cFilSub, Caracter, Filial do atendente
@param   dDtMov , Data    , Data da movimentação
@version 12.1.14
@since   03/04/2017
@return  aCmpTFF, Array, Array com os postos da TFF que tiveram manutenção sem que tenha sido alocado um atendente para cobertura.
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Function AtTFFManut( cFilSub, dDtMov, cCodAtd )
Local cAliasQry := GetNextAlias()
Local cFilABR   := xFilial("ABR",cFilSub)
Local cFilABB   := xFilial("ABB",cFilSub)
Local cFilTDV   := xFilial("TDV",cFilSub)
Local cFilABQ   := xFilial("ABQ",cFilSub)
Local cFilTFF   := xFilial("TFF",cFilSub)
Local cFilABS   := xFilial("ABS",cFilSub)
Local cFilABN 	:= xFilial("ABN",cFilSub)
Local cOrcRes	:= SuperGetMV("MV_GSORCRE",,,cFilSub)
Local cGsRhCur 	:= SuperGetMv("MV_GSRHCUR",,,cFilSub)
Local cGsRhRec 	:= SuperGetMv("MV_GSRHREC",,,cFilSub)
Local cGsRhDsp 	:= SuperGetMv("MV_GSRHDSP",,,cFilSub)
Local nPosTFF   := 0
Local aCmpTFF   := {}

BeginSql Alias cAliasQry
	SELECT TFF.TFF_COD, TFF.TFF_LOCAL, TFF.TFF_PRODUT, TFF.TFF_PERINI, TFF.TFF_PERFIM, TFF.TFF_ESCALA, TFF.TFF_FUNCAO, ABB.ABB_IDCFAL, ABS_DESCRI, ABS_CODIGO, ABS_LOJA
	FROM   %table:TFF% TFF
	
	INNER JOIN %Table:ABS% ABS ON
	ABS.ABS_FILIAL        = %Exp:cFilABS%
	AND ABS.ABS_LOCAL     = TFF.TFF_LOCAL
	AND ABS.%NotDel%
	
	INNER JOIN %Table:ABR% ABR ON
	ABR.ABR_FILIAL        = %Exp:cFilABR%
	AND ABR.ABR_CODSUB    = ''
	AND ABR.%NotDel%
	
	INNER JOIN %Table:ABN% ABN ON
	ABN.ABN_FILIAL        = %Exp:cFilABN%  
	AND ABN.ABN_CODIGO    = ABR.ABR_MOTIVO 
	AND ABN.%NotDel%
	
	INNER JOIN %Table:ABB% ABB ON
	ABB.ABB_FILIAL        = %Exp:cFilABB%  
	AND ABB.ABB_CODIGO    = ABR.ABR_AGENDA 
	AND ABB.ABB_MANUT     = '1' 
	AND ABB.%NotDel%
		
	INNER JOIN %Table:TDV% TDV ON
	TDV.TDV_FILIAL        = %Exp:cFilTDV%  
	AND TDV.TDV_CODABB    = ABB.ABB_CODIGO 
	AND TDV.TDV_DTREF     = %Exp:dDtMov%   
	AND TDV.%NotDel%	
	
	INNER JOIN %Table:ABQ% ABQ ON
	ABQ.ABQ_FILIAL        = %Exp:cFilABQ%
	AND ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM = ABB.ABB_IDCFAL
	AND ABQ.ABQ_CODTFJ <> %Exp:cOrcRes%
	AND ABQ.%NotDel%
	
	WHERE  TFF.TFF_FILIAL 	= %Exp:cFilTFF%   
	AND    TFF.TFF_COD    	= ABQ.ABQ_CODTFF
	AND    TFF.TFF_ENCE 	<> '1'
	AND    TFF.%NotDel%
	AND    ABB.ABB_CODTEC	<> %Exp:cCodAtd%
	AND    ABB.ABB_CODTFF NOT IN ( %Exp:cGsRhDsp% ,%Exp:cGsRhCur% , %Exp:cGsRhRec%)
	AND	   ABN.ABN_TIPO   NOT IN ('04','07')
	GROUP  BY TFF.TFF_FILIAL, TFF.TFF_COD, TFF.TFF_LOCAL, TFF.TFF_PRODUT, TFF.TFF_PERINI, TFF.TFF_PERFIM, TFF.TFF_ESCALA, TFF.TFF_FUNCAO, ABB.ABB_IDCFAL, ABS_DESCRI, ABS_CODIGO, ABS_LOJA
	ORDER  BY %Order:TFF%
EndSql
	
(cAliasQry)->(DbGoTop())

While (cAliasQry)->(!EOF())
	 
	AAdd(aCmpTFF,  {(cAliasQry)->TFF_COD                                                    ,; //itemRh
		 			(cAliasQry)->TFF_LOCAL                                                  ,; //local
		 			(cAliasQry)->ABS_DESCRI 												,; //descricao local
		 			(cAliasQry)->ABS_CODIGO                                                 ,; //cliente do local
		 			(cAliasQry)->ABS_LOJA                                                   ,; //loja do cliente do local
		 			Posicione("SA1",1,FwxFilial("SA1")+(cAliasQry)->(ABS_CODIGO+ABS_LOJA),"A1_NOME")  ,; //desc. cliente.
		 			(cAliasQry)->TFF_PRODUT                                                 ,; //produto
		 			Posicione("SB1",1,FwxFilial("SB1")+(cAliasQry)->TFF_PRODUT,"B1_DESC")   ,; //desc. prodtuto
		 			Stod((cAliasQry)->TFF_PERINI)                                           ,; //período inicial
		 			Stod((cAliasQry)->TFF_PERFIM)                                           ,; //período final
		 			(cAliasQry)->TFF_ESCALA                                                 ,; //escala
		 			Posicione("TDW",1,FwxFilial("TDW")+(cAliasQry)->TFF_ESCALA,"TDW_DESC")  ,; //desc. escala
		 			(cAliasQry)->TFF_FUNCAO                                                 ,; //função
		 			Posicione("SRJ",1,FwxFilial("SRJ")+(cAliasQry)->TFF_FUNCAO,"RJ_DESC")   ,; //desc. função
		 			(cAliasQry)->ABB_IDCFAL                                                 }) //Chave para buscar informações do posto de cobertura

	(cAliasQry)->(DbSkip())
Enddo
(cAliasQry)->(DbCloseArea())
	
Return aCmpTFF

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336IniCob
Retorna o horário de início da cobertura. Essa função é utilizada no TECA550.

@author Leandro Dourado 
@version 12.1.14
@since 03/04/2017
@return cHrIniCob, Caracter, Hora de cobertura inicial, informado na tela do movimentar.
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Function At336IniCob()
Return cHrIniCob

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TpCob
Retorna o tipo de movimentação de cobertura. Essa função é utilizada no TECA550.

@author Kaique Schiller
@since 21/01/2019
@return cTpMovCob, Caracter, Tipo de movimentação de cobertura.
@obs 
@sample
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TpCob()
Return cTpMovCob

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtCobAloc
Função responsável por fazer a alocação de um substituto em um posto que sofreu manutenção e está com uma vaga de cobertura em aberto.

@author  Leandro Dourado 
@param   oModel, Objeto, Modelo de dados do movimentar
@version 12.1.14
@since   11/04/2017
@return  lRet, Lógico, Indica se a alocação foi feita corretamente.
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtCobAloc( oModel )
Local cIDcFal   := oModel:GetValue("TW3MASTER","TW3_IDCFAL")
Local dDtMov    := oModel:GetValue("TW3MASTER","TW3_DTMOV" )
Local cFilMov   := oModel:GetValue("TW3MASTER","TW3_TECFIL")
Local cFilSub   := oModel:GetValue("TW3MASTER","TW3_FILIAL")
Local cCodAtend := oModel:GetValue("TW3MASTER","TW3_ATDCOD")
Local cCodTW3 	:= oModel:GetValue("TW3MASTER","TW3_COD")
Local cSituacao	:= oModel:GetValue("TW3MASTER","TW3_SITCOD")
Local cFilTDV	:= xFilial("TDV",cFilMov)
Local cFilABR	:= xFilial("ABR",cFilMov)
Local cFilABB	:= xFilial("ABB",cFilMov) 
Local cFilABN	:= xFilial("ABN",cFilMov) 
Local cMotivo   := ""
Local aAgenda   := {}
Local aManut    := {}

cHrIniCob := oModel:GetValue("TW3MASTER","TW3_SUBINI")

If cSituacao $ SIT_MOV_FOLGAFT + "|" + SIT_MOV_FTREFORCO
	cTpMovCob := TIPALO_FOLGATRAB 	//Folga trabalhada.

Elseif cSituacao == SIT_MOV_FOLGACN
	cTpMovCob := TIPALO_FOLGATRABCN //Folga Trabalhada Covocação Normal.

Elseif cSituacao == SIT_MOV_CNCOMP
	cTpMovCob := TIPALO_FTCNCOMP 	//Folga Trabalhada Covocação Normal Compensado.

Endif

cAliasABB := GetNextAlias()

BeginSql Alias cAliasABB
	SELECT *, ABR.R_E_C_N_O_ AS RECNOABR
	FROM %table:ABB% ABB
  	INNER JOIN %Table:TDV% TDV ON
		  TDV.TDV_FILIAL     = %Exp:cFilTDV%
		  AND TDV.TDV_CODABB = ABB.ABB_CODIGO 
		  AND TDV.TDV_DTREF  = %Exp:Dtos(dDtMov)%
		  AND TDV.%NotDel%

	INNER JOIN %Table:ABR% ABR ON
	      ABR.ABR_FILIAL     = %Exp:cFilABR%
	      AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
	      AND ABR.ABR_CODSUB = ''
	      AND ABR.%NotDel%

	INNER JOIN %Table:ABN% ABN ON
	      ABN.ABN_FILIAL     = %Exp:cFilABN%
	      AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO
	      AND ABN.%NotDel%

	WHERE ABB.ABB_FILIAL     = %Exp:cFilABB%
		  AND ABB.ABB_IDCFAL = %Exp:cIDcFal%
		  AND ABB.ABB_MANUT  = '1'
		  AND ABB.%NotDel%
		  AND ABN.ABN_TIPO NOT IN ('04','05','07')
	ORDER BY %Order:ABB%
EndSql

(cAliasABB)->(DbGoTop())

While (cAliasABB)->(!EOF())
	aAdd(aAgenda,{(cAliasABB)->ABB_CODIGO,;
				  (cAliasABB)->ABB_DTINI ,;
				  (cAliasABB)->ABB_HRINI ,;
				  (cAliasABB)->ABB_DTFIM ,;
				  (cAliasABB)->ABB_HRFIM ,;
		          (cAliasABB)->RECNOABR  })
	(cAliasABB)->(DbSkip())
EndDo

lRet := At336GrABR( aAgenda  , cMotivo , dDtMov   , cFilSub,;
		            cCodAtend, .F.     , cHrIniCob, .T.    ,;
		            Nil      , cFilMov ,cCodTW3             )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336ChkAlc
Verifica se o atendente está alocado como efetivo em um posto (posto de reserva ou efetivo) e realiza seu recolhimento ou cancelamento de agenda.

@author  Leandro Dourado 
@param   cFil     , Caracter, Filial da movimentação
@param   cCodAtend, Caracter, Código do atendente que será movimentado
@param   dDtMov   , Data    , Data da movimentação
@param   lRecolhe , Logico  , Indica se o atendente será recolhido (lRecolhe = .T.) ou se sua agenda será apenas cancelada (lRecolhe = .F.)
@param   cChkRes  , Caracter, 1 - Checa apenas postos efetivos; 2 - Checa apenas postos de reserva; 3 - Checa todos os postos.
@version 12.1.14
@since   25/04/2017
@return  oModel
/*/
//--------------------------------------------------------------------------------------------------------
Function At336ChkAlc( cFil, cCodAtend, dDtMov, lRecolhe, cChkRes )
Local lRet       := .T.
Local cAliasQry  := GetNextAlias()
Local cTFFRecol  := ""
Local cCodTDX  	 := ""
Local nGrupo	 := 0
Default lRecolhe := .T.
Default cChkRes  := "2"

If At336TGYChk( cAliasQry, cFil, cCodAtend, dDtMov, .T., cChkRes )
	
	If lRecolhe
	
		cTFFRecol := (cAliasQry)->TGY_CODTFF
		cCodTDX	  := (cAliasQry)->TGY_CODTDX
		nGrupo	  := (cAliasQry)->TGY_GRUPO
		(cAliasQry)->(DbCloseArea())
		
		lRet :=  At336Recolhe( cCodAtend, cTFFRecol, dDtMov, .F., cCodTDX, nGrupo )
		
	Else
	
		lRet :=  At336CanAgenda( cFil, cCodAtend, dDtMov, cChkRes )
		
	EndIf
	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336Recolhe
Faz o recolhimento de um posto para posteriormente realizar uma implantação.

@author Leandro Dourado
@param   cCodAtend , Caracter, Código do Atendente que será recolhido.
@param   cCodTFF   , Caracter, Posto do qual o atendente será recolhido.
@param   dDtMov    , Data    , Data da movimentação.
@param   lTrocaEfet, Logico  , Indica se trata-se da situação de troca de efetivos.
@version 12.1.14
@since 25/04/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Function At336Recolhe( cCodAtend, cCodTFF, dDtMov, lTrocaEfet, cCodTDX, nGrupo )
Local lRet         := .T.
Local oMdlRecolhe  := Nil
Local oMdlABB      := Nil
Local cCodABS      := ""
Local lResTec      := .F.
Local lMovJob	   := IsInCallStack("TECM330")
Default cCodAtend  := ""
Default cCodTFF    := ""
Default dDtMov     := dDataBase
Default lTrocaEfet := .F.
Default nGrupo	   := 0

lChkWhen    := .F. // É necessário setar essa variavel como falso para que o sistema ignore o when dos campos
lResetSitAt := .F. // É necessario setar essa variavel como falso para o sistema não resetar a situação do atendente, o que acarretaria em problemas.
oMdlRecolhe := FwLoadModel("TECA336")
oMdlRecolhe:SetOperation(MODEL_OPERATION_INSERT)
oMdlRecolhe:Activate()

oMdlRecolhe:SetValue( "TW3MASTER", "TW3_FILIAL", FwxFilial("TW3") )
oMdlRecolhe:SetValue( "TW3MASTER", "TW3_COD"   , GetSxeNum("TW3", "TW3_COD") )
oMdlRecolhe:SetValue( "TW3MASTER", "TW3_ATDCOD", cCodAtend        )
oMdlRecolhe:LoadValue("TW3MASTER", "TW3_SITCOD", SIT_MOV_RECOLHE  )
oMdlRecolhe:SetValue( "TW3MASTER", "TW3_DTMOV" , dDtMov           )
oMdlRecolhe:SetValue( "TW3MASTER", "TW3_TECSUB", ""               )
oMdlRecolhe:LoadValue("TW3MASTER", "TW3_ITRHCT", cCodTFF          )

cCodABS := Posicione("TFF",1,FwxFilial("TFF")+cCodTFF,"TFF_LOCAL")

// Caso o atendente esteja sendo recolhido de um posto de reserva, o campo TW3_RESERV é manipulado para impedir uma nova geração de agenda nesse posto.
If Posicione("ABS", 1, FwxFilial("ABS") + cCodABS, "ABS_RESTEC") == "1"
	oMdlRecolhe:SetValue( "TW3MASTER", "TW3_RESERV", "1" )
	lResTec := .T.
	If lMovJob
		oMdlRecolhe:SetValue( "TW3MASTER", "TW3_TRSQES", cCodTDX )
		oMdlRecolhe:SetValue( "TW3MASTER", "TW3_GRPESC", nGrupo )
	Endif
EndIf

If lTrocaEfet .Or. lTrocaOk .Or. lRecolheOk
	oMdlABB := oMdlRecolhe:GetModel("ABBDETAIL")
	oMdlABB:ClearData()
	oMdlABB:InitLine()
	
	At336ABBLoad(oMdlRecolhe)
EndIf

If lTrocaOk
	lTrocaOk := .F.
Endif

lRet := oMdlRecolhe:VldData()
If ( lRet )
	If lTrocaEfet
		oMdlTrocaEfet := oMdlRecolhe
	Else											
		lRet  := oMdlRecolhe:CommitData() //Grava Model
		oMdlRecolhe:DeActivate()
		oMdlRecolhe:Destroy()
		FreeObj(oMdlRecolhe)
		oMdlRecolhe := Nil
		DelClassIntF()
	EndIf
	TW3->(ConfirmSX8())
Else
	aErro := oMdlRecolhe:GetErrorMessage()
	Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )	
	TW3->(RollBackSX8())
EndIf
lChkWhen    := .T.
lResetSitAt := .T.

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336AtdFil
Retorna a filial do atendente que foi selecionado na tela do TECA335. Essa função é chamada do inicializador padrão do campo TW3_FILATD.

@author Leandro Dourado 
@version 12.1.14
@since 25/04/2017
@return cFilAtd, Caracter, Filial do atendente posicionado.
/*/
//--------------------------------------------------------------------------------------------------------
Function At336AtdFil()

Return cFilAtd

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336FilSub
Valida a filial do atendente de cobertura informada.

@author Leandro Dourado 
@version 12.1.14
@since 12/05/2017
@return lRet, Logico, Retorna se a filial informada é valida
/*/
//--------------------------------------------------------------------------------------------------------
Function At336FilSub()
Local lRet    := .T.
Local oModel  := FwModelActive()
Local oMdlTW3 := oModel:GetModel("TW3MASTER")
Local cFilSub := oMdlTW3:GetValue("TW3_TECFIL")
Local cCodEmp := FwCodEmp()
Local nTamEmp := Len(cCodEmp)

lRet := ExistCpo("SM0",cEmpAnt+cFilSub)

If lRet .And. oMdlTW3:GetValue("TW3_SITCOD") == SIT_MOV_TROCFUN
	lRet := cFilSub == oMdlTW3:GetValue("TW3_FILIAL")
	
	If !lRet
		Help("",1,"FILSUB336",,STR0124,2,0) //"A troca entre efetivos deve ser realizada apenas entre funcionários de uma mesma filial!"
	EndIf
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336CanAgenda
Verifica se o atendente informado possui agenda em posto de reserva. Se tiver, cancela as agendas do posto de reserva para o dia da movimentação.

@author Leandro Dourado 
@version 12.1.14
@since 25/04/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Function At336CanAgenda( cFilMov, cCodAtd, dDtMov, cChkReserv, cMotivo, cTipAlo )
Local cAliasQry    := GetNextAlias()
Local cFilABB      := xFilial("ABB",cFilMov)
Local cFilTDV      := xFilial("TDV",cFilMov)
Local cFilTCU      := xFilial("TCU",cFilMov)
Local aAgenda      := {}
Local lRet         := .T.
Local cChvTCU      := ""
Local cChvABB      := ""

Default cChkReserv := "3"
Default cMotivo    := ""
Default cTipAlo    := ""

If Empty(cMotivo)
	cMotivo := SuperGetMv("MV_ATMTCAN",,"")
EndIf

Do Case
	Case cChkReserv == "1"
		cChvTCU := "%AND TCU.TCU_RESTEC <> '1'%"
	Case cChkReserv == "2"
		cChvTCU := "%AND TCU.TCU_RESTEC =  '1'%"
	Case cChkReserv == "3"
		cChvTCU := "%%"
EndCase

If !Empty(cTipAlo)
	cChvABB := "%AND ABB.ABB_TIPOMV = '" + cTipAlo + "'%"
Else
	cChvABB := "%%"
EndIf

BeginSql Alias cAliasQry
	SELECT *
	FROM %table:ABB% ABB
  	INNER JOIN %Table:TDV% TDV 
		  ON  TDV.TDV_FILIAL = %Exp:cFilTDV%
		  AND TDV.TDV_CODABB = ABB.ABB_CODIGO 
		  AND TDV.TDV_DTREF  = %Exp:dDtMov%
		  AND TDV.%NotDel%
	INNER JOIN %table:TCU% TCU
		  ON  TCU.TCU_FILIAL = %Exp:cFilTCU%
		  AND TCU.TCU_COD    = ABB.ABB_TIPOMV
		  AND TCU.%NotDel%
		  %Exp:cChvTCU%
	WHERE     ABB.ABB_FILIAL = %Exp:cFilABB%
		  AND ABB.ABB_CODTEC = %Exp:cCodAtd%
		  AND ABB.ABB_ATIVO  = "1"
		  AND ABB.%NotDel%
		  %Exp:cChvABB%
	ORDER BY %Order:ABB%
EndSql

(cAliasQry)->(DbGoTop())

	While (cAliasQry)->(!Eof())
		aAdd(aAgenda,{(cAliasQry)->ABB_CODIGO})
		(cAliasQry)->(DbSkip())
	EndDo
	
If Len(aAgenda) > 0
	lRet := At336GrABR( aAgenda  , cMotivo , dDtMov   , ""     ,;
                        ""       , .F.     ,  ""      , .F.    ,;
                        cAliasQry, cFilMov                      )
Endif

(cAliasQry)->(DbCloseArea())

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336VlHrExt()
Verifica se motivo de manutenção de agenda informada é referente à hora extra.

@author Leandro Dourado 
@version 12.1.14
@since 25/04/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Function At336VlHrExt()
Local lRet := .T.

lRet := ExistCpo("ABN") .AND. Posicione("ABN",1,xFilial("ABN")+AllTrim(MV_PAR01),"ABN_TIPO") == "04"

If !lRet
	Help( ,, 'AT336VLHREXT',, STR0125, 1, 0 ) //"O motivo de manutenção informado não é valido! Informe um motivo do tipo 'Hora extra'!"
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtGetTFFAtd()
Verifica se motivo de manutenção de agenda informada é referente à hora extra.

@author Leandro Dourado 
@version 12.1.14
@since 25/04/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtGetTFFAtd(cFilMov, cCodAtend, dDtMov, cIdCfal, cOrigem)
Local aArea     := GetArea()
Local cCodTFF   := ""
Local cAliasQry := ""

Default cIdCfal := ""
Default cOrigem := ""

If !Empty(cIdCfal)
	cOrigem    := Posicione("ABQ",1,FwxFilial("ABQ")+cIdcFal,"ABQ_ORIGEM")
	cCodTFF    := Posicione("ABQ",1,FwxFilial("ABQ")+cIdcFal,"ABQ_CODTFF")
Else
	cAliasQry := GetNextAlias()
	At336TGYChk( cAliasQry, cFilMov, cCodAtend, dDtMov, .T., "1" )
						
	cCodTFF := (cAliasQry)->TGY_CODTFF
	cOrigem := Posicione("ABQ",3,FwxFilial("ABQ")+cCodTFF,"ABQ_ORIGEM")
	
	(cAliasQry)->(DbCloseArea())
EndIf

RestArea( aArea )

Return cCodTFF

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336QtDias()
Verifica se motivo de manutenção de agenda informada é referente à hora extra.

@author Leandro Dourado 
@version 12.1.14
@since 25/04/2017
@return oModel
/*/
//--------------------------------------------------------------------------------------------------------
Function At336QtDias()
Local lRet    := .T.
Local nQtDias := FwFldGet("TW3_QTDIAS")
Local cSituacao := FwFldGet("TW3_SITCOD")

If nQtDias == 0
	lRet := .F.
EndIf

If cSituacao $ (SIT_MOV_RECICLA + '|' + SIT_MOV_CURSO) .AND. nQtDias > 5
	lRet := MsgYesNo(STR0126,STR0037) //"A duração informada é superior a 5 dias! Deseja confirmar?"###"Atenção!"
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TW3Clear
Limpa o conteudo dos campos na alteração da situação da movimentação.
@author Rodolfo Novaes
@since 26/05/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TW3Clear()
Local oModel	:= FwModelActive()
Local oMdlTW3   := oModel:GetModel("TW3MASTER")
Local oStrTW3   := oMdlTW3:GetStruct()
Local aCpoTW3   := oStrTW3:GetFields()
Local nX		:= 1
Local cReturn	:= oMdlTW3:GetValue("TW3_SITCOD")
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.)
Local cCmpsHrs		:= ""

For nX := 1 To Len(aCpoTW3)

	If lMV_GSGEHOR
		cCmpsHrs := '|TW3_ENTRA1|TW3_SAIDA1|TW3_ENTRA2|TW3_SAIDA2|TW3_ENTRA3|TW3_SAIDA3|TW3_ENTRA4|TW3_SAIDA4'
	Endif
	
	If aCpoTW3[nX,3] $ ('TW3_SITDES|TW3_QTDIAS|TW3_ADTFIM|TW3_TECFIL|TW3_TECSUB|TW3_TECSNM|TW3_SUBINI|TW3_MOTCOD|TW3_MOTDES|TW3_CLICOD|TW3_LOCCOD|TW3_ITRHCT|TW3_TRSQES|TW3_GRPESC'+cCmpsHrs)

		oMdlTW3:ClearField(aCpoTW3[nX,3])
	EndIf
Next nX

Return cReturn

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336IteClear
Limpa o conteudo dos campos na alteração do item de alocação
@author Rodolfo
@since 26/05/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function At336IteClear()
Local oModel	:= FwModelActive()
Local oView		:= FWViewActive()
Local oMdlTW3   := oModel:GetModel("TW3MASTER")
Local cReturn	:= oMdlTW3:GetValue("TW3_ITRHCT")
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.)
Local nK			:= 0

oMdlTW3:ClearField('TW3_TRSQES')
oMdlTW3:ClearField('TW3_GRPESC')

If lMV_GSGEHOR

	For nK := 1 To 4
		oMdlTW3:ClearField(("TW3_ENTRA"+ cValToChar(nK)))
		oMdlTW3:ClearField(("TW3_SAIDA"+ cValToChar(nK)))		
	Next nK

Endif

oView:Refresh()

Return cReturn

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336SubIni
Valida o campo hora inicial de cobertura.

@author Leandro Dourado
@since 13/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function At336SubIni()
Local cFilSub   := FwFldGet("TW3_TECFIL")
Local cCodSub   := FwFldGet("TW3_TECSUB")
Local cHrIni    := FwFldGet("TW3_SUBINI")
Local cSituacao := FwFldGet("TW3_SITCOD")
Local lRet      := .T.
Local cAliasQry := ""
Local cIdcFal   := FwFldGet("TW3_IDCFAL")
Local dDtMov    := FwFldGet("TW3_DTMOV")
Local oModel    := FwModelActive()
Local oMdlABB   := Nil
Local aRows     := {}
Local cHrEmpty  := "  :  "

If !Empty(cHrIni) .And. cHrIni <> cHrEmpty

	If lRet := AtVldHora(cHrIni)
	
		If !Empty(cIdcFal)
		
			cAliasQry := GetNextAlias()
		
			BeginSql Alias cAliasQry
				SELECT *, ABR.R_E_C_N_O_ AS RECNOABR
				FROM %table:ABB% ABB
			  	INNER JOIN %Table:TDV% TDV ON
					  TDV.TDV_FILIAL     = %xFilial:TDV%
					  AND TDV.TDV_CODABB = ABB.ABB_CODIGO 
					  AND TDV.TDV_DTREF  = %Exp:dDtMov%
					  AND TDV.%NotDel%
				INNER JOIN %Table:ABR% ABR ON
				      ABR.ABR_FILIAL     = %xFilial:ABB%
				      AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
				      AND ABR.%NotDel%
				WHERE ABB.ABB_FILIAL     = %xFilial:ABB%
					  AND ABB.ABB_IDCFAL = %Exp:cIDcFal%
					  AND ABB.ABB_MANUT  = '1'
					  AND ABB.%NotDel%
				ORDER BY %Order:ABB%
			EndSql
			
			(cAliasQry)->(DbGoTop())
			
			If (cAliasQry)->(!EOF()) .And. cHrIni > (cAliasQry)->ABB_HRFIM .And. !(cSituacao $ cListFT + '|' + cListCob)
				oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SUBINI",oModel:GetModel():GetId(),	"TW3_SUBINI",'TW3_SUBINI',; 
				STR0127, "")				
				lRet := .F.
			Endif			
	
			(cAliasQry)->(DbCloseArea())
		EndIf
	
		If lRet
			oMdlABB := oModel:GetModel("ABBDETAIL")
			
			aRows := FwSaveRows()
			
			If cSituacao == SIT_MOV_SAIDANT
				If oMdlABB:Length() >= 1
		
					oMdlABB:GoLine(2)
					
					If cHrIni < oMdlABB:GetValue("ABB_HRFIM")
						oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SUBINI",oModel:GetModel():GetId(),	"TW3_SUBINI",'TW3_SUBINI',; 
						"A hora de início da cobertura não pode ser menor que o horário final da agenda.", "")						
						lRet := .F.
					Endif			
				Endif
			
			Elseif cSituacao == SIT_MOV_ATRASO
				If oMdlABB:Length() > 0
		
					oMdlABB:GoLine(1)
					
					If cHrIni >= oMdlABB:GetValue("ABB_HRINI")
						oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SUBINI",oModel:GetModel():GetId(),	"TW3_SUBINI",'TW3_SUBINI',; 
						"",1,"AT336SUBINI",,STR0161, "") //"A hora de início da cobertura não pode ser maior ou igual o horário ínicio da agenda."
						lRet := .F.
					Endif			
				Endif
			Else			
				If oMdlABB:Length() > 1
		
					oMdlABB:GoLine(1)
					
					If cHrIni > oMdlABB:GetValue("ABB_HRFIM") .And. !cSituacao $ SIT_MOV_FOLGAFT + '|' + SIT_MOV_FOLGACN + '|' + SIT_MOV_CNCOMP + '|' + cListFT + '|' + cListCob
						oModel:GetModel():SetErrorMessage(oModel:GetId(),"TW3_SUBINI",oModel:GetModel():GetId(),	"TW3_SUBINI",'TW3_SUBINI',; 
						STR0127, "")
						lRet := .F.
					Endif			
				Endif
			Endif
		
			FwRestRows( aRows )		
		Endif
	EndIf

	lRet := IIF(ExistBlock("AT336SUB") , ExecBlock("AT336SUB",.F.,.F.,{lRet,cSituacao,cHrIni}), lRet )

Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336ABQRef

Gera registro da ABQ, quando se tratar de uma implantação de reforço. 
Isso porque o item de reforço pode ser alterado até que seja feita uma alocação.

@author Leandro Dourado
@since 22/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function At336ABQRef( cCodTFF )
Local lRet     := .T.
Local aArea    := GetArea()
Local aAreaTFF := TFF->(GetArea())
Local aItemRH  := {}
Local lSeqTrn  := (TFF->(FieldPos("TFF_SEQTRN")) > 0)

DbSelectArea("TFF")
TFF->(DbSetOrder(1)) //TFF_FILIAL + TFF_COD

If TFF->(DbSeek(xFilial("TFF")+cCodTFF))

	Aadd(aItemRH,{;
	              TFF->TFF_PRODUT,;                  
	              TFF->TFF_CARGO ,;                  
	              TFF->TFF_FUNCAO,;                
	              TFF->TFF_PERINI,;                
	              TFF->TFF_PERFIM,;                  
	              TFF->TFF_TURNO ,;                 
	              TFF->TFF_QTDVEN,;                
	              TFF->TFF_COD   ,;                 
	              If( lSeqTrn, TFF->TFF_SEQTRN, ""),;
	              .T.            ,;
	              TFF->TFF_FILIAL,;
	              TFF->TFF_ESCALA,;
	              TFF->TFF_CALEND ;
	              })                              
	
	lRet := At850CnfAlc( TFF->TFF_CONTRT, TFF->TFF_LOCAL, aItemRH )
Else
	lRet := .F.
EndIf

RestArea( aArea )
RestArea( aAreaTFF )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TW5Chk
Verifica se o atendente possui algum registro de ausência (TW5) para a data da movimentação.

@author Leandro Dourado
@since 22/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TW5Chk( cCodAtend, dDtMov, cTpLanc )
Local cAliasQry := GetNextAlias()

Default cTpLanc := ""
			
BeginSql Alias cAliasQry
	SELECT TW5.R_E_C_N_O_ RECNOTW5
	FROM %table:TW5% TW5
	WHERE TW5.TW5_FILIAL = %xFilial:TW5%
	AND ( %Exp:dDtMov% BETWEEN TW5.TW5_DTINI AND TW5_DTFIM
	OR  TW5.TW5_DTFIM    = '' ) 
	AND TW5.TW5_ATDCOD   = %Exp:cCodAtend%
	AND TW5.%NotDel%
	ORDER BY %Order:TW5%
EndSql

(cAliasQry)->(DbGoTop())

lRet := (cAliasQry)->(!Eof())

If lRet
	cTpLanc := TW5->TW5_TPLANC
EndIf

(cAliasQry)->(DbCloseArea())

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtChkEfetivos
Verifica se o posto informado possui algum efetivo alocado.

@author Leandro Dourado
@since 27/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function AtChkEfetivos( cCodTFF, dDtMov )
Local cAliasQry := GetNextAlias()
Local lRet      := .T.

BeginSql Alias cAliasQry
	SELECT *
	FROM %table:TGY% TGY
	WHERE TGY.TGY_FILIAL  = %xFilial:TGY%
	AND   TGY.TGY_DTINI  <= %Exp:dDtMov%
	AND   TGY.TGY_DTFIM  >= %Exp:dDtMov%
	AND   TGY.TGY_CODTFF  = %Exp:cCodTFF% 
	AND   TGY.%NotDel%
	ORDER BY %Order:TGY%
EndSql

(cAliasQry)->(DbGoTop())

lRet := (cAliasQry)->(!Eof())

(cAliasQry)->(DbCloseArea())

Return lRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtRefazManut
Refaz as manutenções realizadas pela troca de efetivos.

@author Leandro Dourado
@since 27/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtRefazManut( aManut, aManutSub, dDtMov )
Local lRet := .T.

If Len(aManut) > 0
	lRet := lRet .And. At336CanAgenda( aManut[1,3], aManut[1,4], dDtMov, "3", aManut[1,2] )
EndIf

If Len(aManutSub) > 0
	lRet := lRet .And. At336CanAgenda( aManutSub[1,3], aManutSub[1,4], dDtMov, "3", aManutSub[1,2] )
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336Efetiva
Efetiva atendente em posto efetivo. As informações passadas já devem ter sido validadas previamente.

@author Leandro Dourado
@since 27/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function At336Efetiva( cCodAtend, dDtMov, cCodTFF, cCodTDX, cCodI7 )
Local lRet        := .T.
Local oModel      := Nil
Local nGrupo	  := 0

Default cCodAtend := ""
Default cCodTFF   := ""
Default dDtMov    := dDataBase

lChkWhen    := .F. // É necessário setar essa variavel como falso para que o sistema ignore o when dos campos
lResetSitAt := .F. // É necessario setar essa variavel como falso para o sistema não resetar a situação do atendente, o que acarretaria em problemas.
oModel := FwLoadModel("TECA336")
oModel:SetOperation(MODEL_OPERATION_INSERT)
oModel:Activate()

oModel:SetValue( "TW3MASTER", "TW3_FILIAL", FwxFilial("TW3") )
oModel:SetValue( "TW3MASTER", "TW3_COD"   , GetSxeNum("TW3", "TW3_COD") )
oModel:SetValue( "TW3MASTER", "TW3_ATDCOD", cCodAtend        )
oModel:LoadValue("TW3MASTER", "TW3_SITCOD", SIT_MOV_EFETIVO  )
oModel:SetValue( "TW3MASTER", "TW3_DTMOV" , dDtMov           )
oModel:SetValue( "TW3MASTER", "TW3_TECSUB", ""               )
oModel:LoadValue("TW3MASTER", "TW3_ITRHCT", cCodTFF          )
oModel:SetValue( "TW3MASTER", "TW3_TRSQES", cCodTDX          )
oModel:LoadValue("TW3MASTER", "TW3_MOTCOD", cCodI7           )

nGrupo := oModel:GetValue("TW3MASTER","TW3_GRPESC")

lRet := oModel:VldData()
lRet := lRet .And. oModel:CommitData() //Grava Model

If lRet
	lRet := At581Alt(cCodTFF,cCodTDX,cCodAtend,nGrupo)
Endif

If ( lRet )										
	TW3->(ConfirmSX8())
Else
	aErro := oModel:GetErrorMessage()
	Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )	
	TW3->(RollBackSX8())
EndIf

lChkWhen    := .T.
lResetSitAt := .T.

oModel:DeActivate()
oModel:Destroy()
FreeObj(oModel)
oModel := Nil
DelClassIntF()

Return lRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtRecFolguista
Realiza o recolhimento de um atendente em posto de folguista.

@author Leandro Dourado
@since 27/06/2017
@version 1.0
/*/
//--------------------------------------------------------------------------------------------------------
Function AtRecFolguista( oModel, lAloAut )
Local aArea     := GetArea()
Local lRet      := .T.
Local cAliasQry := GetNextAlias()
Local oMdlTW3   := oModel:GetModel("TW3MASTER")
Local oMdlABB   := oModel:GetModel("ABBDETAIL")
Local cFilMov   := oMdlTW3:GetValue("TW3_FILIAL")
Local cCodAtend := oMdlTW3:GetValue("TW3_ATDCOD")
Local dDtMov    := oMdlTW3:GetValue("TW3_DTMOV")

Local nSelecao  := 0
Local nRecnoTGZ := 0
Local cLocal    := ""
Local cDescLoc  := ""
Local cCodRec   := ""
Local aRecnoTGZ := {}
Local aPostos   := {}
Local aHeader   := {STR0001,STR0002,STR0003,; //"Item RH"#"Local"#"Desc. Local"#
                    STR0008,STR0009,STR0006,; //"Período Inicial"#"Período Final"#"Escala"
                    STR0007}  //#"Desc. Escala"
                 
Default lAloAut := .F.               

lRet := At336TGZChk( cAliasQry, cFilMov, cCodAtend, dDtMov )

If lRet
	While (cAliasQry)->(!Eof())
	
		cLocal     := Posicione("TFF",1,xFilial("TFF")+(cAliasQry)->TGZ_CODTFF,"TFF_LOCAL")
		cDescLocal := Posicione("ABS",1,FwxFilial("ABS")+cLocal,"ABS_DESCRI")
		
		aAdd(aPostos,{(cAliasQry)->TGZ_CODTFF ,;
			          cLocal                  ,;
			          cDescLocal              ,;
			          (cAliasQry)->TGZ_DTINI  ,;
			          (cAliasQry)->TGZ_DTFIM  ,;
			          (cAliasQry)->TGZ_ESCALA ,;
			          Posicione("TDW",1,FwxFilial("TDW")+(cAliasQry)->TGZ_ESCALA,"TDW_DESC")})
			          
		Aadd(aRecnoTGZ,{(cAliasQry)->TGZ_CODTFF, (cAliasQry)->R_E_C_N_O_})       
		(cAliasQry)->(DbSkip())
	EndDo
	
	nSelecao := TmsF3Array(aHeader, aPostos, STR0128 ) //"Postos de Folguista"
	
	If nSelecao > 0
		cCodRec := aPostos[nSelecao, 1]
		cLocal  := aPostos[nSelecao, 2]
		
		nRecnoTGZ := aRecnoTGZ[aScan(aRecnoTGZ, {|x| x[1] == cCodRec }),2]
		
		DbSelectArea("TGZ")
		TGZ->(DbGoTo(nRecnoTGZ))
		
		lRet := AtRecTGZ( cCodAtend, dDtMov, cCodRec )
		
		If lRet .And. oMdlABB:SeekLine({{"ABB_LOCAL" , cLocal}})
		
			lRet := At336CanAgenda( cFilMov, cCodAtend, dDtMov, "3", Nil, TIPALO_COBERTURA )
			
			If lRet
				lAloAut := .T.
			EndIf
		
		EndIf
		
	Else
		lRet := .F.
		Help( ,, 'Help',, STR0129, 1, 0 ) //"Não foi selecionado um posto para o recolhimento!"
	EndIf
EndIf

(cAliasQry)->(DbCloseArea())

RestArea( aArea )

Return lRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtRecTGZ
Ao utilizar a opção de recolhimento, essa função será chamada para que haja manutenção da TGZ.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtRecTGZ( cCodAtend, dDtMov, cCodTFF )
Local aArea      := GetArea()
Local cAliasTGY  := ""
Local cAliasTGZ  := ""
Local cCodTDX    := ""
Local cItem      := ""
Local oModel     := Nil
Local oMdlTGX    := Nil
Local oMdlTGZ    := Nil
Local nOperation := 0
Local lDelete    := .F.
Local lRet       := .T.

Default cCodTFF  := ""
	
If TGZ->TGZ_CODTFF == cCodTFF

	If TGZ->TGZ_DTINI == dDtMov
		lDelete    := .T.
	EndIf
	
	cCodTDX := TGZ->TGZ_CODTDX
	cItem   := TGZ->TGZ_ITEM
	
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1)) //TFF_FILIAL+TFF_COD
	
	If TFF->(DbSeek(FwxFilial("TFF")+cCodTFF))

		At580bKill()
		
		At580EGHor((VldEscala(TFF->(RECNO()),.F.)))

		oModel := FwLoadModel("TECA580E")
		oModel:SetOperation(MODEL_OPERATION_UPDATE)
		oModel:Activate()
		
		oMdlTGX := oModel:GetModel("TGXDETAIL")
		If oMdlTGX:SeekLine({{"TGX_COD" , cCodTDX}},.F.)
			At580VdFolder({2})
			oMdlTGZ := oModel:GetModel("TGZDETAIL")
			
			If oMdlTGZ:SeekLine({{"TGZ_ITEM" , cItem}},.F.)
				If lDelete
					oMdlTGZ:DeleteLine()
				Else
					oMdlTGZ:SetValue("TGZ_DTFIM" ,dDtMov-1)
				EndIf
				lRet := oModel:VldData()
				If ( lRet )											
					lRet  := oModel:CommitData() //Grava Model
				Else
					aErro := oModel:GetErrorMessage()
					Help( ,, 'Help',, aErro[MODEL_MSGERR_MESSAGE], 1, 0 )	
				EndIf
			Endif
		EndIf
	EndIf
	
EndIf
	
RestArea( aArea )

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336RtFil
Retorna o filtro para a consulta padrão TW0MOV.

@author Leandro Dourado 
@version 12.1.14
@since 19/01/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Function At336RtFil()
Local lRet      := .F.
Local cSituacao := FwFldGet("TW3_SITCOD")
Local cCodAtend := FwFldGet("TW3_ATDCOD")

If Empty(TW0->TW0_ATEND)
	If cSituacao == SIT_MOV_FOLGUIS .And. TW0->TW0_TIPO == "1"
		lRet := .T.
	Elseif cSituacao $ SIT_MOV_ALMOCIS  .And. TW0->TW0_TIPO $ "2|3"
		lRet := .T.
	Elseif cSituacao == SIT_MOV_FERISTA .And. TW0->TW0_TIPO == "4"
		lRet := .T.
	Endif
Else
	lRet := AllTrim(TW0->TW0_ATEND) == AllTrim(cCodAtend) .And. (cSituacao $ SIT_MOV_RECALMO + "|" + SIT_MOV_RECFOLG + "|" + SIT_MOV_RECFERI )
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336VlLoc
Validação do local vinculado com o cliente da ABS.

@author Kaique Schiller
@since 23/11/2017
@return Nil
/*/
//--------------------------------------------------------------------------------------------------------
Function At336VlLoc()
Local lRet 		:= .T.
Local cCodCli	:= FwFldGet("TW3_CLICOD")
Local cCodLoc 	:= FwFldGet("TW3_LOCCOD")

If !Empty(cCodCli)
	DbSelectArea("ABS")
	ABS->(DbSetOrder(1))
	If ABS->(DbSeek(FwxFilial("ABS")+cCodLoc))
		lRet := ABS->ABS_CODIGO == cCodCli
	Endif
	
	If !lRet
		Help("",1,"TECA336",,STR0149,2,0) //"Não possível inserir um local que não está vinculado ao cliente."
	Endif
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336GtCob
Seleciona a manutenção e a agenda do técnico que está sendo coberto.

@author Kaique Schiller
@since 11/12/2017
@return aManut
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336GtCob(cFilMov ,cCodAtend, dDtMov)
Local cAliasQry := GetNextAlias()
Local aManut	:= {}
Local cMtvFalta := SuperGetMv("MV_ATMTFAL",,"")
Local cMtvFolga := SuperGetMv("MV_ATMTFOL",,"")
Local cMtvCanc	:= SuperGetMv("MV_ATMTCAN",,"")
Local cMtvCurso	:= SuperGetMv("MV_ATMTCUR",,"") 
Local cMtvRecicl:= SuperGetMv("MV_ATMTREC",,"") 
Local cMtvADisp	:= SuperGetMv("MV_ATMTDSP",,"") 
Local cMtvFer	:= SuperGetMv("MV_ATMTFER",,"")

BeginSql Alias cAliasQry
	SELECT  ABB.*,
            ABB.R_E_C_N_O_,
            ABR.R_E_C_N_O_ ABR_RECNO
	FROM %table:ABR% ABR
		INNER JOIN %table:ABB% ABB 
			ON  ABB.ABB_FILIAL = %Exp:cFilMov% 
			AND ABB.ABB_CODIGO = ABR.ABR_AGENDA
	WHERE ABR.ABR_FILIAL  = %Exp:cFilMov%
	AND   ABR.ABR_CODSUB  = %Exp:cCodAtend%
	AND   ABR.ABR_DTINI  >= %Exp:dDtMov%
	AND   ( ABR.ABR_MOTIVO  = %Exp:cMtvFalta% 	OR 
			ABR.ABR_MOTIVO  = %Exp:cMtvFolga% 	OR 
			ABR.ABR_MOTIVO  = %Exp:cMtvCanc%  	OR 
			ABR.ABR_MOTIVO  = %Exp:cMtvCurso%  	OR 
			ABR.ABR_MOTIVO  = %Exp:cMtvRecicl%  OR 
			ABR.ABR_MOTIVO  = %Exp:cMtvADisp%   OR
			ABR.ABR_MOTIVO  = %Exp:cMtvFer% )			
	AND   ABR.%NotDel%
EndSql

(cAliasQry)->(DbGoTop())

While (cAliasQry)->(!EOF())
	aAdd(aManut,{(cAliasQry)->ABB_CODIGO,;
				 (cAliasQry)->ABB_DTINI,;
				 (cAliasQry)->ABB_HRINI,;
				 (cAliasQry)->ABB_DTFIM,;
				 (cAliasQry)->ABB_HRFIM,;
				 (cAliasQry)->ABR_RECNO,;
				 cAliasQry})
	(cAliasQry)->(DbSkip())
EndDo

Return aManut

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtCancCob
Realiza o cancelamento da cobertura.

@author Kaique Schiller
@since 19/12/2017
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtCancCob(oMdlTW3)
Local aManut	:= {}
Local cFilMov   := oMdlTW3:GetValue("TW3MASTER","TW3_FILIAL")
Local cCodAtend := oMdlTW3:GetValue("TW3MASTER","TW3_ATDCOD")
Local dDtMov    := oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV")
Local cSituacao := oMdlTW3:GetValue("TW3MASTER","TW3_SITCOD")
Local lRet		:= .F.
Local cMotivo	:= ""

aManut := At336GtCob(cFilMov ,cCodAtend, dDtMov)

If Len(aManut) > 0
	
	lRet := At336GrABR( aManut  , cMotivo , dDtMov   , "" 	  ,	   ;
		            	"" 		, .F.     , "" 		 , .T.    ,	   ;
		            	aManut[1][7]      , cFilMov	 , 		  ,.T. )

	If !(cSituacao $ SIT_MOV_CANCFT + '|' + SIT_MOV_CANCFTCN + '|' + SIT_MOV_CANCCNCOMP + '|' + cListCanCB + '|' + cListCanFT )

		cMotivo := SuperGetMv("MV_ATMTCAN",,"")
		
		lRet := lRet .And. AtDesfazManut( cCodAtend, dDtMov, cMotivo )
	Endif

	(aManut[1][7])->(DbCloseArea())
Else
	//Cancelamento para FT quando não for por manutenção.
	If cSituacao $ SIT_MOV_CANCFT
		lRet := AtTW5Grv(oMdlTW3,cSituacao)
	Endif
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} AtCancCob
Realiza o cancelamento da hora extra.

@author Kaique Schiller
@since 19/12/2017
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function AtCancHrExt(oMdlTW3)
Local aManut	:= {}
Local cCodAtend := oMdlTW3:GetValue("TW3MASTER","TW3_ATDCOD")
Local dDtMov    := oMdlTW3:GetValue("TW3MASTER","TW3_DTMOV")
Local oMdlABB   := oMdlTW3:GetModel("ABBDETAIL")
Local lRet		:= .F.

aManut := At336HrExt(cCodAtend, oMdlABB)

If Len(aManut) > 0
	lRet := AtDesfazManut( cCodAtend, dDtMov, , aManut )
Endif

Return lRet
//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336GtCan
Retorna as situações de cancelamento de algumas manutenções.

@author Kaique Schiller
@since 19/12/2017
@return cRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336GtCan(oMdlABB)
Local nX		:= 0
Local nZ		:= 0
Local cRet		:= ""
Local aRows  	:= {}
Local aManut	:= {}
Local nExtra 	:= 0
Default oMdlABB := Nil

If Valtype(oMdlABB) == "O" .And. !oMdlABB:IsEmpty()
	aRows := FwSaveRows()

	DbSelectArea("ABR")
	ABR->(DbSetOrder(1))

	DbSelectArea("ABN")
	ABN->(DbSetOrder(1))

	For nX := 1 To oMdlABB:Length()
		oMdlABB:GoLine(nX)
		If !(cRet $ SIT_MOV_CANCADN) .And. ABR->(DbSeek( FwxFilial("ABR")+oMdlABB:GetValue("ABB_CODIGO")+SuperGetMv("MV_ATMTSAN",,"")))
			cRet += '|' + SIT_MOV_CANCADN
		Endif

		If !(cRet $ SIT_MOV_CANCATR) .And. ABR->(DbSeek( FwxFilial("ABR")+oMdlABB:GetValue("ABB_CODIGO")+SuperGetMv("MV_ATMTATR",,""))) 
			cRet += '|' + SIT_MOV_CANCATR
		Endif
		
		If !(cRet $ SIT_MOV_CANCEXT)
			
			aManut := AT550QryMan(oMdlABB:GetValue("ABB_CODIGO"))

			For nZ := 1 To Len(aManut)
			
				nExtra := AScan( aManut, { |x| x[2] == "04" } )

				If nExtra > 0 .And. ABR->(DbSeek( FwxFilial("ABR")+oMdlABB:GetValue("ABB_CODIGO")+aManut[nExtra,1])) 
					cRet += '|' + SIT_MOV_CANCEXT
				Endif

			Next nZ
		Endif
		
		If !(cRet $ SIT_MOV_CANCJORNDIF) .And. ABR->(DbSeek( FwxFilial("ABR")+oMdlABB:GetValue("ABB_CODIGO")+SuperGetMv("MV_ATMTJDF",,"")))
			cRet += '|' + SIT_MOV_CANCJORNDIF
		Endif

	Next nX
	FwRestRows( aRows )
Endif

Return cRet


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336HrExt
Seleciona as agendas que tem hora extra.

@author Kaique Schiller
@since 20/12/2017
@return aManut
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336HrExt(cCodAtend, oMdlABB)
Local cAliasQry := GetNextAlias()
Local aManut	:= {}
Local cCodABB	:= ""
Local nX		:= 0

For nX := 1 To oMdlABB:Length()
	oMdlABB:Goline(nX)
	If !Empty(oMdlABB:GetValue("ABB_CODIGO")) .And. cCodABB <> oMdlABB:GetValue("ABB_CODIGO")
		If Empty(cCodABB)
			cCodABB += "'" + oMdlABB:GetValue("ABB_CODIGO") + "'"
		Else
			cCodABB += "," + "'" + oMdlABB:GetValue("ABB_CODIGO") + "'"
		EndIf
	Endif
Next nX

If !Empty(cCodABB)
	cCodABB := "%"+cCodABB+"%"
Endif

BeginSql Alias cAliasQry

	SELECT ABB_CODIGO,
		   ABR_MOTIVO,
		   ABB_FILTEC,
		   ABB_CODTEC
	FROM %table:ABB% ABB
	INNER JOIN %table:ABR% ABR 
		ON ABR.ABR_FILIAL 	  = %xFilial:ABR%
		   AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
		   AND ABR.%NotDel%
	INNER JOIN %table:ABN% ABN 
		ON ABN.ABN_FILIAL 	  = %xFilial:ABN%
		   AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO
		   AND ABN.%NotDel%
	WHERE ABB.ABB_FILIAL = %xFilial:ABB%
	  AND ABB.ABB_CODTEC = %Exp:cCodAtend%
	  AND ABB.ABB_ATIVO  = '1'
	  AND ABB.%NotDel%
	  AND ABN.ABN_TIPO = '04'
	  AND ABB.ABB_CODIGO IN (%Exp:cCodABB%)

	ORDER BY ABB_FILIAL,
	         ABB_CODTEC,
	         ABB_DTINI,
	         ABB_HRINI,
	         ABB_DTFIM,
	         ABB_HRFIM

EndSql

(cAliasQry)->(DbGoTop())

While (cAliasQry)->(!EOF())
	aAdd(aManut,{(cAliasQry)->ABB_CODIGO,;
				 (cAliasQry)->ABR_MOTIVO,;
				 (cAliasQry)->ABB_FILTEC,;
				 (cAliasQry)->ABB_CODTEC})
	(cAliasQry)->(DbSkip())
EndDo

(cAliasQry)->(DbCloseArea())

Return aManut

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336CliCod
Função para validar os campos de cliente e local de alocação, e verifica a restrição

@author Luiz Gabriel
@since 10/04/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At336CliCod(nCampo)
Local lRet		:= .T.
Local oModel	:= FWModelActive()
Local oMdlTW3   := oModel:GetModel("TW3MASTER")	
Local cCampo	:= ""

If nCampo == 1
	lRet := Vazio() .Or. ExistCpo("SA1")
	If lRet
		cCampo := oMdlTW3:GetValue("TW3_CLICOD")
		lRet := At336TW2("TW3_CLICOD",cCampo,oMdlTW3)
	EndIf	
ElseIf nCampo == 2
	lRet := Vazio() .Or. (ExistCpo("ABS") .And. At336VlLoc())
	If lRet
		cCampo := oMdlTW3:GetValue("TW3_LOCCOD")
		lRet := At336TW2("TW3_LOCCOD",cCampo,oMdlTW3)
	EndIf	
EndIf

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TW2
Função para verificar a restrição do atendente em locais e clientes

@author Luiz Gabriel
@since 10/04/2018
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336TW2(cCampo,cConteudo,oMdlTW3)
Local aCmpTW2	:= {}
Local cTempTW2 	:= GetNextAlias()
Local cData		:= ""
Local cCodTec	:= ""
Local cCodCli	:= ""
Local cCodLoc	:= ""
Local cWhere	:= ""
Local lRet		:= .T.
Local oModel	:= Nil

Default oMdlTW3	:= Nil

If Valtype(oMdlTW3) == "O" .And. oMdlTW3:IsActive()
	cData		:= Dtos(oMdlTW3:GetValue("TW3_DTMOV"))
	cCodTec		:= oMdlTW3:GetValue("TW3_ATDCOD")
ElseIf Valtype(oMdlTW3) == "U" 
	oModel     	:= FwViewActive()
	If oModel <> Nil
		oMdlTW3   	:= oModel:GetModel("TW3MASTER")  
		cData		:= Dtos(oMdlTW3:GetValue("TW3_DTMOV"))
		cCodTec		:= oMdlTW3:GetValue("TW3_ATDCOD")	
	Endif
EndIf

//cria as condições para a query
cWhere := "%TW2.TW2_CODTEC = '" + cCodTec + "' AND "

//Altera o tipo confirme o campo a ser pesquisado
If "TW3_CLICOD" $ cCampo
	cWhere += "TW2.TW2_TIPO = '1' AND "
	cWhere += "TW2.TW2_CLIENT = '" + cConteudo + "' AND "
ElseIf "TW3_LOCCOD" $ cCampo
	cWhere += "TW2.TW2_TIPO = '2' AND "
	cWhere += "TW2.TW2_LOCAL = '" + cConteudo + "' AND "
EndIf

cWhere += "((TW2.TW2_TEMPO = '2' AND "
cWhere += "TW2.TW2_DTINI <= '" + cData + "' AND "
cWhere += "TW2.TW2_DTFIM >= '" + cData + "' ) OR "
cWhere += "(TW2.TW2_TEMPO = '1' AND "
cWhere += "TW2.TW2_DTINI <= '" + cData + "' ))AND "
cWhere += "%"

//montar query para a consulta padrão
BeginSql Alias cTempTW2
	SELECT * FROM %table:TW2% TW2
		WHERE TW2.TW2_FILIAL = %xFilial:TW2% AND
			%Exp:cWhere%
			TW2.%NotDel%		
EndSql
	
DbSelectArea(cTempTW2)
DbGoTop(cTempTW2)
While !EOF()
	AADD(aCmpTW2,{(cTempTW2)->TW2_COD,;  	//Codigo do local
	(cTempTW2)->TW2_TIPO,;       		//Tipo
	(cTempTW2)->TW2_CODTEC ,; 		 	//Codigo do Atendente
	(cTempTW2)->TW2_CLIENT ,;		  	//Codigo do Cliente
	(cTempTW2)->TW2_LOJA ,;			//Loja do Cliente
	(cTempTW2)->TW2_RESTRI ,;			//Tipo da Restrição
	})
	dBSkip()
Enddo
(cTempTW2)->(DbCloseArea())
	
If Len(aCmpTW2) > 0
		//Verifica se a restrição é um bloqueio ou aviso
	If aCmpTW2[1][6] == "1" //Aviso
		If MsgYesNo(STR0132) //"O atendente selecionado possui restrições de alocação no cliente/Local escolhido. Deseja continuar? "
			lRet := .T.
		Else
			lRet := .F.
			Help("",1,"TECA336",,STR0133,2,0) //"Selecione outro cliente/Local para continuar a alocação"
		EndIf
	ElseIf aCmpTW2[1][6] == "2" //Bloqueio
		Help("",1,"TECA336",,STR0134,2,0) //"O Atendente selecionado possui restrições e não pode ser alocado no cliente/Local"
		lRet := .F.
	EndIf
EndIf
	
Return lRet 

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336VisEs

Visualizar o cadastro de escalas.

@author Kaique Schiller
@since 22/06/2018
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------
Function At336VisEs(oModel)
Local oMdlTW3 	:= Nil
Local aArea   	:= GetArea()
Local lConfirm	:= .T.
Default oModel  := oView:GetModel()

oMdlTW3 := oModel:GetModel("TW3MASTER")

If !Empty(oMdlTW3:GetValue("TW3_ITRHCT"))
	dbSelectArea("TFF")
	TFF->(dbSetOrder(1)) //TFF_FILIAL+TFF_COD
	If TFF->(dbSeek(xFilial("TFF")+oMdlTW3:GetValue("TW3_ITRHCT")))	

		dbSelectArea("TDW")
		TDW->(dbSetOrder(1)) //TDW_FILIAL+TDW_COD
		If TDW->(dbSeek(xFilial("TDW")+TFF->TFF_ESCALA))	
	
			lConfirm := ( FWExecView( STR0152,"VIEWDEF.TECA580", MODEL_OPERATION_VIEW, /*oDlg*/, {||.T.} /*bCloseOk*/, ;  // "Visualização da Escala" 
										{||.T.}/*bOk*/,/*nReducao*/, /*aButtons*/, {||.T.}/*bCancel*/ ) == 0 )
		Endif
	Else
		Help("",1,"At336VisEs",,STR0150+TFF->TFF_ESCALA+STR0151,2,0) //"Não existe o código: "##" no cadastro de escalas."
	Endif
Else
	Help("",1,"At336VisEs",,STR0153,2,0) //"Informe um item de alocação pra visualização da escala."
Endif

RestArea( aArea )

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} At336F3Res()
@description	Montagem da consulta específica pra reserva técnica.

@author Kaique Schiller
@since 25/08/2018
@return lRet
/*/
//------------------------------------------------------------------
Function At336F3Res()
Local lRet              := .T.
Local cTit				:= ""
Local cQry				:= ""
Local aHeader			:= {}
Local aSeek				:= {}
Local aIndex			:= {}
Local cCmpRet			:= ""
Local cFuncao			:= "At336GvRes"
Local cOrcRes			:= SuperGetMV("MV_GSORCRE")

cTit := STR0154 //"Reservas Técnica."

cQry := "SELECT TFF_COD,"
cQry += "		TDX_COD," 
cQry += "		TDX_CODTDW,"
cQry += "		TDW_DESC,"
cQry += "		TDX_TURNO,"
cQry += "		TDX_SEQTUR"
cQry += " FROM " + RetSqlName("TFJ") + " TFJ "
cQry += " 	INNER JOIN " + RetSqlName("TFL") + " TFL "
cQry += " 		ON TFL.TFL_FILIAL = '" +  xFilial("TFL") + "'"
cQry += " 		AND TFL.D_E_L_E_T_ = '' "
cQry += " 		AND TFL.TFL_CODPAI = TFJ.TFJ_CODIGO"
cQry += " 	INNER JOIN " + RetSqlName("TFF") + " TFF "
cQry += " 		ON TFF.TFF_FILIAL = '" +  xFilial("TFF") + "'"
cQry += " 		AND TFF.D_E_L_E_T_ = '' "
cQry += " 		AND TFF_CODPAI = TFL_CODIGO"
cQry += " 	INNER JOIN " + RetSqlName("TDX") + " TDX "
cQry += " 		ON TDX.TDX_FILIAL = '" +  xFilial("TDX") + "'"
cQry += " 		AND TDX.D_E_L_E_T_ = '' "
cQry += " 		AND TDX_CODTDW = TFF_ESCALA"
cQry += " 	INNER JOIN " + RetSqlName("TDW") + " TDW "
cQry += " 		ON TDW.TDW_FILIAL = '" +  xFilial("TDW") + "'"
cQry += " 		AND TDW.D_E_L_E_T_ = '' "
cQry += " 		AND TDW_COD = TFF_ESCALA"
cQry += " WHERE TFJ_CODIGO = '" +  cOrcRes + "'"
cQry += " 		AND TDX.TDX_STATUS = '1' "
cQry += " 		AND TFJ.D_E_L_E_T_ = '' "
cQry += " 		AND ('"+DToS(dDataBase)+"' BETWEEN TFF.TFF_PERINI AND TFF.TFF_PERFIM )"

cQry := ChangeQuery( cQry )

Aadd( aHeader, 	{"TFF_COD"		,"Cod. RH"		})
Aadd( aHeader, 	{"TDX_COD"		,"Cod. Efetivo"	})
Aadd( aHeader, 	{"TDX_CODTDW"					})
Aadd( aHeader, 	{"TDW_DESC"		,"Desc. Escala"	})
Aadd( aHeader, 	{"TDX_TURNO"					})
Aadd( aHeader, 	{"TDX_SEQTUR"					})

Aadd( aSeek, 	"TDX_CODTDW")
				
Aadd( aIndex, "TDX_COD")

cCmpRet := "TDX_COD"

lRet := TxF3Gen(cTit, cQry, aHeader, aSeek, aIndex, cCmpRet, cFuncao, .F.)

Return(lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} At336GvRes()
@description	Realiza a passagem das informações da consulta específica de reserva.

@author Kaique Schiller
@since  25/08/2018
@return lRet
/*/
//------------------------------------------------------------------
Function At336GvRes(oBrw)
Local lRet		:= .F.

aInfoRes := { 	(oBrw:Alias())->&("TFF_COD"		),;
				(oBrw:Alias())->&("TDX_COD"		),;
				(oBrw:Alias())->&("TDX_CODTDW"	),;
				(oBrw:Alias())->&("TDX_TURNO"	),;
				(oBrw:Alias())->&("TDX_SEQTUR"	) }

If !Empty(aInfoRes)
	lRet := .T.
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At336RtRes()
@description	Retorna o código de efetivação da consulta específica de reserva.

@author Kaique Schiller
@since  25/08/2018
@return TxRetF3: Retornará o 'Codigo de efetivação' selecionado na consulta padrão.
/*/
//------------------------------------------------------------------
Function At336RtRes()

Return TxRetF3()

//-------------------------------------------------------------------
/*/{Protheus.doc} At336FlTDX()
@description	Filtra os registros do codigo de efetivo.

@author Kaique Schiller
@since  22/09/2018
@return cSQL: Retornará a query filtrando o consulta padrão TDXMOV.
/*/
//------------------------------------------------------------------
Function At336FlTDX()
Local cSQL 		:= ""
Local cEscala	:= Posicione( "TFF", 1, xFilial("TFF")+FwFldGet("TW3_ITRHCT"), "TFF_ESCALA" )

cSQL := "@TDX_FILIAL 	= '" + xFilial("TDX") 	+ "'"
cSQL += "AND TDX_CODTDW = '" + cEscala 			+ "'"

Return cSQL

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TtExt
Calcula o total de horas extras.

@author Kaique Schiller
@since 09/01/2019
@return cRetTotExt
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TtExt(cCodAtend, cCodTFF, cLocal, dDtMov, cSituacao )
Local cAliasQry  := GetNextAlias()
Local cRetTotExt := "00:00"
Local cHrIni	 := "00:00"
Local cHrFim	 := "00:00"
Local nHrInt	 := 0

BeginSql Alias cAliasQry

	SELECT ABR_TEMPO, ABR_HRINIA, ABR_HRFIMA
	FROM %table:ABB% ABB
	INNER JOIN %table:ABR% ABR 
		ON ABR.ABR_FILIAL 	  = %xFilial:ABR%
		   AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
		   AND ABR.%NotDel%
	INNER JOIN %table:ABN% ABN 
		ON ABN.ABN_FILIAL 	  = %xFilial:ABN%
		   AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO
		   AND ABN.ABN_TIPO = '04'
		   AND ABN.%NotDel%
	WHERE ABB.ABB_FILIAL = %xFilial:ABB%
	  AND ABB.ABB_CODTEC = %Exp:cCodAtend%
	  AND ABB.ABB_LOCAL  = %Exp:cLocal%
	  AND ABB.ABB_CODTFF = %Exp:cCodTFF%
	  AND ABB.ABB_DTINI >= %Exp:Dtos(dDtMov)%
	  AND ABB.ABB_DTFIM <= %Exp:Dtos(dDtMov)%
	  AND ABB.ABB_ATIVO  = '1'
	  AND ABB.%NotDel%
EndSql

(cAliasQry)->(DbGoTop())

While (cAliasQry)->(!EOF())
	
	nHrInt := HoraToInt((cAliasQry)->ABR_TEMPO)
	
	cRetTotExt := AtSomaHora(cRetTotExt,nHrInt)
	
	(cAliasQry)->(DbSkip())
EndDo

If (cAliasQry)->(!EOF()) //Se houver manunteção
	cHrIni := (cAliasQry)->ABR_HRINIA
	cHrFim := (cAliasQry)->ABR_HRFIMA
Else
	If cSituacao == SIT_MOV_HORAEXT
		cHrIni := FwFldGet("ABB_HRINI")
		cHrFim := FwFldGet("ABB_HRFIM")
	Endif
Endif

DbSelectArea("ABB")
ABB->(DbSetOrder(8))
If ABB->(dbSeek(xFilial("ABB")+FwFldGet("ABB_CODIGO")))
	
	If cHrIni <> "00:00" .And. cHrIni < ABB->ABB_HRINI

		nHrInt := HoraToInt(ABB->ABB_HRINI)-HoraToInt(FwFldGet("ABB_HRINI"))
		
		cRetTotExt := AtSomaHora(cRetTotExt,nHrInt)
	Endif		

	If cHrFim <> "00:00" .And. cHrFim > ABB->ABB_HRFIM

		nHrInt := HoraToInt(FwFldGet("ABB_HRFIM"))-HoraToInt(ABB->ABB_HRFIM)
		
		cRetTotExt := AtSomaHora(cRetTotExt,nHrInt)

	Endif
Endif

(cAliasQry)->(DbCloseArea())

Return cRetTotExt

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336GatHr
Gatilho de horas.

@author Kaique Schiller
@since 14/01/2019
/*/
//--------------------------------------------------------------------------------------------------------
Function At336GatHr()
Local oModel		:= FwModelActive()
Local oMdlTW3		:= oModel:GetModel("TW3MASTER")
Local cSituacao 	:= oMdlTW3:GetValue("TW3_SITCOD")
Local dDtMov    	:= oMdlTW3:GetValue("TW3_DTMOV")
Local nK			:= 0
Local lMV_GSGEHOR   := SuperGetMV("MV_GSGEHOR",,.F.)
Local nDia			:= 0
Local cAliasQry		:= ""
Local cWhere		:= ""

If lMV_GSGEHOR
	If cSituacao $ SIT_MOV_REFORCO + '|' + SIT_MOV_FTREFORCO + '|' + cListDia 
		If !Empty(oMdlTW3:GetValue("TW3_TRSQES"))

			nDia := Dow(dDtMov)

			If nDia == 1
				cWhere := "%TW4.TW4_DOM = '" + 'T' + "'%"
			Elseif nDia == 2
				cWhere := "%TW4.TW4_SEG = '" + 'T' + "'%"
			Elseif nDia == 3
				cWhere := "%TW4.TW4_TER = '" + 'T' + "'%"
			Elseif nDia == 4
				cWhere := "%TW4.TW4_QUA = '" + 'T' + "'%"
			Elseif nDia == 5
				cWhere := "%TW4.TW4_QUI = '" + 'T' + "'%"
			Elseif nDia == 6
				cWhere := "%TW4.TW4_SEX = '" + 'T' + "'%"
			Elseif nDia == 7
				cWhere := "%TW4.TW4_SAB = '" + 'T' + "'%"
			Endif

			//Query com os dias da semana e horários de trabalho do reforço
			cAliasQry := GetNextAlias()
			BeginSql Alias cAliasQry
				SELECT T44.T44_SEQUEN, T44.T44_HORAIN, T44.T44_HORAFI 
				FROM %table:TW4% TW4
				JOIN %table:T44% T44
			  	ON (T44.T44_FILIAL=%xFilial:T44% AND T44.T44_CODTW4=TW4.TW4_COD AND T44.%NotDel%)
				WHERE TW4.TW4_FILIAL=%xFilial:TW4%
			  	  AND TW4.%NotDel%
			  	  AND TW4.TW4_CODTFF=%Exp:oMdlTW3:GetValue("TW3_ITRHCT")%
				  AND %Exp:cWhere%
				ORDER BY T44.T44_SEQUEN
			EndSql

			While (cAliasQry)->(!EOF())

				nK++

				oMdlTW3:LoadValue(("TW3_ENTRA"+ cValToChar(nK) ) , (cAliasQry)->T44_HORAIN )	
				oMdlTW3:LoadValue(("TW3_SAIDA"+ cValToChar(nK) ) , (cAliasQry)->T44_HORAFI )	
				
				(cAliasQry)->(DbSkip())

			EndDo
			
			(cAliasQry)->(DbCloseArea())

		Endif
	Elseif At580EGHor()

		For nK := 1 To 4
			
			If !Empty(oMdlTW3:GetValue("TW3_TRSQES"))
	
				If ( At580bHGet(( "PJ_ENTRA" + cValToChar(nK) )) != 0 .OR. At580bHGet(("PJ_SAIDA" + cValToChar(nK))) != 0 ) .OR.;
						At580bHGet(("PJ_JND" + cValToChar(nK) + "CON")) == 'S'
						
					oMdlTW3:LoadValue(("TW3_ENTRA"+ cValToChar(nK) ) ,TxValToHor(At580bHGet(("PJ_ENTRA"+ cValToChar(nK)))))	
					oMdlTW3:LoadValue(("TW3_SAIDA"+ cValToChar(nK) ) ,TxValToHor(At580bHGet(("PJ_SAIDA"+ cValToChar(nK)))))
				EndIf
			Else
				oMdlTW3:LoadValue(("TW3_ENTRA"+ cValToChar(nK) ) , "" )	
				oMdlTW3:LoadValue(("TW3_SAIDA"+ cValToChar(nK) ) , "" )
			Endif
		Next nK

	Endif
Endif

Return ""

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336VldHr
Validação de horas.

@author Kaique Schiller
@since 14/01/2019
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336VldHr(oMdl,cCmp,xVlr,xVlrOld)
Local lRet := .T. 

If !Empty(xVlr) .And. xVlr <> "  :  "
	lRet := AtVldHora(xVlr)
Endif

Return lRet
//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336ePosV
Pós validação do modelo com relação a manipulação de horas da escala.

@author Kaique Schiller
@since 14/01/2019
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336ePosV(oMdl,cTbl)
Local lRet 			:= .T.
Local cSituacao 	:= oMdl:GetValue("TW3_SITCOD")
Local cCodTFF		:= oMdl:GetValue("TW3_ITRHCT")
Local lMV_GSGEHOR 	:= SuperGetMV("MV_GSGEHOR",,.F.) .AND. At580EGHor()
Local aArea

If !Empty(cCodTFF) .And. lMV_GSGEHOR .And. cSituacao $ SIT_MOV_EFETIVO + "|" + SIT_MOV_EXCEDEN + "|" + SIT_MOV_CORTESI + "|" + SIT_MOV_SERVEXT + "|" + SIT_MOV_TREINAM

	aArea := GetArea()
		
	At580bKill()
	
	DbSelectArea("TFF")
	TFF->(DbSetOrder(1))
	If TFF->(DbSeek( FwxFilial("TFF")+cCodTFF)) .And. At580EGHor((VldEscala(TFF->(RECNO()),.F.)))
		lRet := AT580ePosV(oMdl,,cTbl)
	Endif

	RestArea(aArea)

Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336Inapt
@description Verifica se o atendente está inapto a ser efetivado.

@author Kaique Schiller
@since 21/01/2019
@return .T.
/*/
//--------------------------------------------------------------------------------------------------------
Function At336Inapt()
Local lRet			:= .T.
Local oModel  		:= FwModelActive()
Local oMdlTW3		:= oModel:GetModel("TW3MASTER")
Local cFilAtd		:= oMdlTW3:GetValue("TW3_FILIAL")
Local cCodAtd		:= oMdlTW3:GetValue("TW3_ATDCOD")
Local dDtMov		:= oMdlTW3:GetValue("TW3_DTMOV")
Local cSituacao		:= oMdlTW3:GetValue("TW3_SITCOD")

If !Empty(cFilAtd) .And. !Empty(cCodAtd) .And. (dDtMov <> cTod("") .And. !Empty(dDtMov)) .And. ;
														   (cSituacao $ SIT_MOV_ALMOCIS + "|" +;  	//Implantacao de Almocista/Jantista
																		SIT_MOV_FERISTA + "|" +;	//Implantacao de Ferista                          
																		SIT_MOV_EXCEDEN + "|" +;	//Implantacao de Excedente                        
																		SIT_MOV_SERVEXT + "|" +;	//Implantacao de Servico Extra                    
																		SIT_MOV_REFORCO + "|" +;	//Implantacao de Reforco                          
																		SIT_MOV_CORTESI + "|" +;	//Implantacao de Cortesia                                    
																		SIT_MOV_FOLGUIS + "|" +;	//Implantacao de Folguista                        
																		SIT_MOV_TREINAM + "|" +;	//Implantacao de Treinamento                      
																		SIT_MOV_EFETIVO + "|" +;    //Implantacao de Efetivo				
																		SIT_MOV_COBERTU + "|" +;	//Cobertura
																		SIT_MOV_RECICLA + "|" +;	//Reciclagem
																		cListDia	    + "|" +;    //Reforço Diario (custom)
																		SIT_MOV_CURSO )				//Curso

	lRet := lRet .And. At020Inapt(cFilAtd,cCodAtd,dDtMov)
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336AgRes
@description Permite acessar a variável estatica das agendas de reserva.

@author Kaique Schiller
@since 30/01/2019
@return aAgendRes
/*/
//--------------------------------------------------------------------------------------------------------
Function At336AgRes()

Return aAgendRes

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336AltAg
@description Verifica se houve alteração no horário da reserva.

@author Kaique Schiller
@since 30/01/2019
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At336AltAg()
Local lRet := .F.

If !Empty(aAgendRes) .And. (aScan(aAgendRes,{|x| x[6] == .T. }) > 0 )
	lRet := .T.
Endif

Return lRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336AtSeq
@description Verifica quais são os dias de folga da escala, turno e sequencia.

@author Kaique Schiller
@since 05/02/2019
@return cRetFolga
/*/
//--------------------------------------------------------------------------------------------------------
Function At336AtSeq()
Local cRetFolga := ""
Local aArea		:= GetArea()
Local aFolgas	:= {}

DbSelectArea("TGW")
TGW->(DbSetOrder(2)) //TGW_FILIAL + TGW_EFETDX
If TGW->(DbSeek(xFilial("TGW")+TDX->TDX_COD))
	While !TGW->(Eof()) .AND. TGW->TGW_FILIAL == xFilial("TGW") .AND. TGW->TGW_EFETDX == TDX->TDX_COD
		If TGW->TGW_STATUS == "2" .And. aScan(aFolgas, TGW->TGW_DIASEM) == 0
			If Empty(cRetFolga)
				cRetFolga += TECCdow(Val(TGW->TGW_DIASEM))
			Else
				cRetFolga += "/"+TECCdow(Val(TGW->TGW_DIASEM))
			Endif

			Aadd(aFolgas,TGW->TGW_DIASEM)

		EndIF
		TGW->(DbSkip())	
	EndDo
Endif

RestArea(aArea)

Return cRetFolga


//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336AtSeq
@description Seleciona a hora extra aplicada na agenda.

@author Kaique Schiller
@since 15/03/2019
@return cRetFolga
/*/
//--------------------------------------------------------------------------------------------------------
Static Function At336AgExt(cCodABB)
Local cAliasQry  := GetNextAlias()
Local cRetHrExt  := "00:00"
Local nHrInt	 := 0

BeginSql Alias cAliasQry

	SELECT ABR.ABR_TEMPO
	FROM %table:ABB% ABB
	INNER JOIN %table:ABR% ABR 
		ON ABR.ABR_FILIAL 	  = %xFilial:ABR%
		   AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
		   AND ABR.%NotDel%
	INNER JOIN %table:ABN% ABN 
		ON ABN.ABN_FILIAL 	  = %xFilial:ABN%
		   AND ABN.ABN_CODIGO = ABR.ABR_MOTIVO
		   AND ABN.ABN_TIPO = '04'
		   AND ABN.%NotDel%
	WHERE ABB.ABB_FILIAL = %xFilial:ABB%
	  AND ABB.ABB_CODIGO = %Exp:cCodABB%
	  AND ABB.ABB_ATIVO  = '1'
	  AND ABB.%NotDel%
EndSql

While (cAliasQry)->(!EOF())
	
	nHrInt := HoraToInt((cAliasQry)->ABR_TEMPO)
	
	cRetHrExt := AtSomaHora(cRetHrExt,nHrInt)
	
	(cAliasQry)->(DbSkip())
EndDo

(cAliasQry)->(DbCloseArea())

Return cRetHrExt

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336GtEft
@description Limpa o campo de efetivo.

@author Kaique Schiller
@since 26/03/2019
@return cRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At336GtEft()
Local oModel			:= FwModelActive()
Local oMdlTW3			:= oModel:GetModel("TW3MASTER")
Local cSituacao 		:= oMdlTW3:GetValue("TW3_SITCOD")
Local cRet				:= "1"

//Quando não for implantações limpa o campo de efetivo.
If !(cSituacao $ 	SIT_MOV_EFETIVO + "|" + SIT_MOV_EXCEDEN + "|" + SIT_MOV_CORTESI + "|" +;
		  	   	 	SIT_MOV_REFORCO + "|" + SIT_MOV_SERVEXT + "|" + SIT_MOV_ALMOCIS + "|" + cListDia)

	cRet := ""

Endif

Return cRet

//--------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At336TGYRf
@description Verifica se o atendente esta vinculado no posto de reforco.

@author Kaique Schiller
@since 02/04/2019
@return lRet
/*/
//--------------------------------------------------------------------------------------------------------
Function At336TGYRf(cFil, cCodAtend, dDtMov)
Local cTmpQry 	:= GetNextAlias()
Local lRet			:= .F.

BeginSql Alias cTmpQry

	SELECT TGY.TGY_ATEND
 	FROM %table:TGY% TGY
 	WHERE TGY.TGY_FILIAL	=	%Exp:cFil%
 	  AND TGY.TGY_ATEND		=	%Exp:cCodAtend%
		AND TGY.TGY_TIPALO 	= '015'
		AND %Exp:dDtMov% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM
    AND TGY.%NotDel%

EndSql

If (cTmpQry)->(!EOF())
	lRet := .T.
Endif

(cTmpQry)->(DbCloseArea())

Return lRet
