#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "TECA330.CH"             
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "MOVIMENTACAO.CH"

Static lSigaMdtGS	:= SuperGetMv("MV_NG2GS",.F.,.F.)	//Parâmetro de integração entre o SIGAMDT x SIGATEC

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA330
Alocacao de Atendentes

@sample 	TECA330() 

@param		ExpC1	Numero do Contrato.
@param		ExpC2	Codigo orçamento de serviços.
	
@return		ExpL	Verdadeiro / Falso

@author		Anderson Silva
@since		05/10/2012       
@version	P12   
/*/         
//------------------------------------------------------------------------------
Function TECA330(cNrContrat, cNrOrcSrv, lSrvExt)
  
Local lRetorno 		:= .T.                                                                                             	// Retorno da rotina.
Local oDlg 			:= Nil   												   		   									// Janela Principal.
Local aSize	 		:= FWGetDialogSize( oMainWnd ) 																		// Array com tamanho da janela.
Local oFWLayer		:= Nil															   									// Objeto FwLayer.
Local oDlgCfgAlo	:= Nil											   													// Janela Configuracao para Alocacao.
Local oLbxCfgAlo	:= Nil															   									// Listbox Configuracao para Alocacao.
Local oDlgDetFil	:= Nil																								// Janela Detalhes do Atendente | Filtro.
Local oMnuDtFil		:= Nil															  	   								// Objeto menu popup.
Local oMnuItDFil	:= {}															   									// Itens do menu popup.
Local oTreeDtFil	:= Nil															   									// Tree Detalhes do Atendente | Filtro.
Local oDlgAllAtd 	:= Nil   														   									// Janela dos atendentes Gestao de Servicos.
Local oDlgAtdAlo	:= Nil																								// Janela dos atendentes alocado no contrato.
Local oTreeOS	    := Nil 															   									// Tree Ordem de Servicos.
Local aHeaderAbq	:= {}  															   									// Header Configuracao para Alocacao.
Local aConfAloc		:= {}																								// Array com as configuracoes da alocacao.
Local oMnuOS		:= Nil																								// Objeto menu popup.
Local oMnuItOS 		:= {}																								// Itens do menu popup.
Local oMrkAllAtd	:= Nil															   									// Objeto FwFormBrowse atendentes Gestao de Servicos.
Local oMrkAtdAlo	:= Nil																								// Objeto FwFormBrowse atendentes alocado no contrato.
Local aMrkAllAtd 	:= {}															  									// Array atendentes alocado.
Local aMrkAtdAlo 	:= {} 															   									// Array atendentes alocado no contrato.
Local oPnlParams 	:= Nil	                                                            								// Panel com os parametros de alocacao.
Local oPnlBrwA1 	:= Nil              																				// Panel com o browse atendentes Gestao de Servicos.
Local oPnlTree 		:= Nil                                                             									// Panel com Tree de O/S.
Local oPnlBrwA2 	:= Nil																								// Panel com o browse atendentes alocacados no contrato.
Local oMGAlocDe  	:= Nil																								// Objeto MSGet alocacao de:
Local dAlocDe		:= dDataBase                                                                          			   	// Alocacao de:
Local oMGAlocAte 	:= Nil																								// Objeto MSGet alocacao ate:
Local dAlocAte		:= dDataBase                                                                                       	// Alocacao de:
Local oCbxFilt 		:= Nil  														   									// Combo para filtrar "1=Banco de Apoio","2=Reserva Técnica","3=Todos Atendentes".
Local cItCbxSel 	:= "3"  															   								// Item selecionado no combo de filtro.
Local aFiltCbx		:= {STR0001,STR0002,STR0186}  			 															// Tipos de Filtros {"1=Banco de Apoio","2=Reserva Técnica","3=Todos Atendentes"}.
Local lTecXRh 		:= SuperGetMv("MV_TECXRH",,.F.)	 																// Integracao Gestao de Servicos com RH?.
Local oTBParmsOk 	:= Nil   																							// Botao OK utilizado para buscar os atendente de acordo com os parametros.
Local lRfzConsul   	:= .F.																								// Refaz a consulta?
Local dBkpDe 		:= dDataBase																						// DataBase.
Local dBkpAte 		:= dDataBase                                                                                       	// DataBase.
Local nPosPerFim    := 0 																								// Periodo Final.
Local lGoTop 		:= .T.																								// Posiciona no primeiro registro.
Local lPermFiltr	:= SuperGetMv("MV_TECPRMF",,.T.)
Local cAliasADY := ""
Local lPosAAH := .T.
Local cLocal := ""					//Retorna Local de Atendimento

Local bOkFiltro := {|| }

Default cNrContrat 	:= ""			// Numero do Contrato.
Default cNrOrcSrv	  	:= "" 			// Codigo orçamento de serviços
Default lSrvExt  := .F.          // Informa se a alocação é para um orçamento de serviço extra

Static nPosCargo   := 0 																								// Posicao da coluna Cargo no ListBox.
Static	nPosFuncao  := 0																								// Posicao da coluna Funcao no ListBox.
Static	nPosTurno	:= 0																								// Posicao da coluna Turno no ListBox.
Static nPosSeqTrn := 0
Static	nPosHrsCtr	:= 0																								// Posicao da coluna Horas Contradas no ListBox.
Static	nPosHrsAlo	:= 0																								// Posicao da coluna Horas Alocadas no ListBox.
Static	nPosSaldo	:= 0   																								// Posicao da coluna Saldo de Horas no ListBox.
Static	nPosIdCfg  := 0																								// Posicao da coluna Id da Configuracao da Alocacao no ListBox.
Static nPosLocal  := 0 																								// Posicao da coluna Local de atendimento.
Static nPosCC		:= 0
Static nPosPerIni := 0																								// Periodo Inicial.
Static nPosCarac := 0
Static nPosCurso := 0
Static nPosHabil := 0
Static nPosEscala := 0
Static nPosItEsc := 0
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Salva status das variaveis private e public.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SaveInter()     

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿f
//³Limpa a variavel aRotina para nao carregar nos browses.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aRotina	:= {}

If lTecXRh
	nPosLocal		:= 2
	nPosCargo     := 5
	nPosFuncao    := 7
	nPosPerIni    := 9
	nPosPerFim    := 10
	nPosTurno	 	:= 11
	nPosSeqTrn	  	:= 13
	nPosHrsCtr	  	:= 14
	nPosHrsAlo	  	:= 15
	nPosSaldo	  	:= 16
	nPosCC			:= 18
	nPosIdCfg		:= 19
	nPosCarac		:= 20	
	nPosCurso		:= 21
	nPosHabil		:= 22
	nPosEscala		:= 23
	nPosItEsc		:= 24
		
Else
	nPosLocal		:= 2
	nPosFuncao    := 5
	nPosPerIni    := 7
	nPosPerFim    := 8
	nPosTurno	  := 9
	nPosSeqTrn	  := 11
	nPosHrsCtr	  := 12
	nPosHrsAlo	  := 13
	nPosSaldo	  := 14
	nPosCC			:= 16		
	nPosIdCfg     := 17
	nPosCarac		:= 18
	nPosCurso		:= 19
	nPosHabil		:= 20
	nPosEscala		:= 21
	nPosItEsc		:= 22
	
EndIf

If !Empty(cNrOrcSrv) //reposiciona todos campos para suprir a necessidade
	nPosLocal := 2
	If lTecXRh
		nPosCargo 	+= 2
	EndIf
	nPosFuncao	+= 2
	nPosPerIni	+= 2
	nPosPerFim	+= 2
	nPosTurno	+= 2
	nPosSeqTrn	+= 2
	nPosHrsCtr	+= 2
	nPosHrsAlo	+= 2
	nPosSaldo	+= 2
	nPosCC += 2
	nPosIdCfg 	+= 2
	nPosCarac	+= 2
	nPosCurso	+= 2
	nPosHabil	+= 2
	nPosEscala	+= 2
	nPosItEsc	+= 2
	
EndIf


If !Empty(cNrContrat)
	
	If ! Empty(cNrOrcSrv)		
		cAliasADY := GetNextAlias()

		BeginSQL Alias cAliasADY       
			SELECT  ADY_TPCONT 
				FROM %Table:ADY% ADY		
			INNER JOIN %Table:TFJ% TFJ ON
				TFJ.TFJ_FILIAL = ADY.ADY_FILIAL AND
				TFJ.TFJ_PROPOS = ADY.ADY_PROPOS AND
				TFJ.TFJ_PREVIS = ADY.ADY_PREVIS AND
				TFJ.TFJ_CODIGO = %Exp:cNrOrcSrv% AND
				TFJ.%notDel%
			WHERE 
				ADY.ADY_FILIAL = %xFilial:ADY% AND
				ADY.%notDel%	
		EndSql 

		If ((cAliasADY)->(!EOF()) .AND. (cAliasADY)->(ADY_TPCONT) == '4' ) .OR. lSrvExt
			lPosAAH:= .F.
		EndIf
		(cAliasADY)->(DbCloseArea())		
	EndIf
	
	If lPosAAH
		DbSelectArea("AAH")
		DbSetOrder(1)	
		If !DbSeek(xFilial("AAH")+cNrContrat)
			lRetorno := .F.
			MsgStop(STR0156,STR0031) // "Contrato não localizado para alocação.","Atenção"	
		EndIf
	EndIf	
EndIf

If lRetorno

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Busca os produtos de alocacao configurados para o contrato. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	At330GtABQ(@aHeaderAbq,@aConfAloc,lTecXRh,cNrOrcSrv,lSrvExt)
	
	If Len(aConfAloc) > 0
		
		DEFINE DIALOG oDlg TITLE STR0005 FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL	// "Alocação de Atendentes"
		
		oFWLayer := FWLayer():New()
		oFWLayer:Init(oDlg,.F.)
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Janela configuracao para alocacao. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oFWLayer:AddLine("LINETOP",30,.F.)
		oFWLayer:AddCollumn("CONFALOC",50,.F.,"LINETOP")
		oFWLayer:AddWindow("CONFALOC","oDlgCfgAlo",STR0006,100,.F.,.F.,,"LINETOP",{||})	// "Configuração para Alocação"
				
		oDlgCfgAlo := oFWLayer:GetWinPanel("CONFALOC","oDlgCfgAlo","LINETOP")
		
		bOkFiltro := {|| IIf( At330VMCfg(aConfAloc),;
		                      MsgRun(STR0007, STR0008, {|| ( At330ClrDt(oTreeDtFil),;
		                                                     ApagarTemp(oMrkAllAtd:Alias()),;
		                                                     aMrkAllAtd := ListarApoio(dAlocDe /*dIniAloc*/,;
		                                                                               dAlocAte /*dFimAloc*/,;
		                                                                               IIf(lTecXRh, At330GTree(oTreeDtFil,"FILCAR"), Nil) /*aCargos*/,;
		                                                                               At330GTree(oTreeDtFil,"FILFUN") /*aFuncoes*/,;
		                                                                               At330GTree(oTreeDtFil,"FILHAB") /*aHabil*/,;
		                                                                               /*cDisponib*/,;
		                                                                               /*cContIni*/,;
		                                                                               /*cContFim*/,;
		                                                                               At330GTree(oTreeDtFil,"FILCC")[1] /*cCCusto*/,;
		                                                                               cItCbxSel /*cLista*/,;
		                                                                               /*nLegenda*/,;
		                                                                               /*cItemOS*/,;
		                                                                               At330GTree(oTreeDtFil,"FILTUR") /*aTurnos*/,;
		                                                                               At330GTree(oTreeDtFil,"FILREG") /*aRegiao*/,;
		                                                                               /*lEstrut*/,;
		                                                                               /*aPeriodos*/,;
		                                                                               /*cIdCfAbq*/,;
		                                                                               /*cLocOrc*/,;
		                                                                               At330GTree(oTreeDtFil,"FILSEQ") /*aSeqTrn*/,;
		                                                                               /*aPeriodRes*/,;
		                                                                               aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocalAloc*/,;
		                                                                               At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
		                                                                               At330GTree(oTreeDtFil,"FILCUR") /*aCursos*/),;
		                                                     At330AtBrw(oMrkAllAtd,aMrkAllAtd[1]),;
		                                                     lRfzConsul := .F.,;
		                                                     dBkpDe := dAlocDe,;
		                                                     dBkpAte := dAlocAte )}),;
		                      .F.)}
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ ListBox Configuracoes para Alocacao. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Empty(cNrOrcSrv)

			@ 000,000 LISTBOX oLbxCfgAlo FIELDS HEADER {} SIZE oDlgCfgAlo:nWidth/2,oDlgCfgAlo:nHeight/2 OF oDlgCfgAlo PIXEL;
			   ON dblClick( aEval(aConfAloc,{|x|x[1] := .F.}),;
			                (IIf(at330VldOk(aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg]),;
			                     ((aConfAloc[oLbxCfgAlo:nAt][1] := .T.,;
			                       oLbxCfgAlo:Refresh(),;
			                       /*Limpa os filtros*/ At330ClrFl(oTreeDtFil,lTecXRh),;
			                       /*Carrega os Cargos*/ IIf(lTecXRh, At330VAddC(oTreeDtFil,aConfAloc[oLbxCfgAlo:nAt][nPosCargo]), Nil),; 
			                       /*Carrega as Funções*/ At330VAddF(oTreeDtFil,;
			                                                         aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]),;
			                                                         /*Carrega o Turno Trab*/ At330VAddT(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosTurno]),;
			                                                         /*Carrega o C.Custo*/ At330VAdCc(oTreeDtFil, AAH->AAH_CCUSTO),;
			                                                         /*Caracteristica*/ At330VAdCR(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosCarac]),;
			                                                         /*Curso*/ At330VAdCU(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosCurso]),;
			                                                         /*Habilidade*/ At330VAddH(oTreeDtFil,;
			                                                                                   aConfAloc[oLbxCfgAlo:nAt][nPosHabil],;
			                                                                                   aConfAloc[oLbxCfgAlo:nAt][nPosEscala],;
			                                                                                   aConfAloc[oLbxCfgAlo:nAt][nPosItEsc],;
			                                                                                   /*nNivel*/,;
			                                                                                   lTecXRH)),;
			                       MsgRun(STR0007, STR0008, {|| At330ClrDt(oTreeDtFil),;	// "Localizando os atendentes..."##"Aguarde"
			                                                    ApagarTemp(oMrkAllAtd:Alias()),;
			                                                    /*Busca o periodo inicial da alocação*/ (dAlocDe  := aConfAloc[oLbxCfgAlo:nAt][nPosPerIni], oMGAlocDe:CtrlRefresh()),;
			                                                    /*Busca o periodo final da alocação*/   (dAlocAte := aConfAloc[oLbxCfgAlo:nAt][nPosPerFim], oMGAlocAte:CtrlRefresh()),;
			                                                    aMrkAllAtd := ListarApoio(dAlocDe /*dIniAloc*/,;
			                                                                              dAlocAte /*dFimAloc*/,;
			                                                                              IIF(lTecXRh, {aConfAloc[oLbxCfgAlo:nAt][nPosCargo]}, Nil) /*aCargos*/,;
			                                                                              {aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]} /*aFuncoes*/,;
			                                                                              At330GTree(oTreeDtFil,"FILHAB") /*aHabil*/,;
			                                                                              /*cDisponib*/,;
			                                                                              /*cContIni*/,;
			                                                                              /*cContFim*/,;
			                                                                              At330GTree(oTreeDtFil, "FILCC")[1] /*cCCusto*/,;
			                                                                              cItCbxSel /*cLista*/,;
			                                                                              /*nLegenda*/,;
			                                                                              /*cItemOS*/,;
			                                                                              {aConfAloc[oLbxCfgAlo:nAt][nPosTurno]} /*aTurnos*/,;
			                                                                              At330GTree(oTreeDtFil,"FILREG")/*aRegiao*/,;
			                                                                              /*lEstrut*/,;
			                                                                              /*aPeriodos*/,;
			                                                                              /*cIdCfAbq*/,;
			                                                                              /*cLocOrc*/,;
			                                                                              /*aSeqTrn*/,;
			                                                                              /*aPeriodRes*/,;
			                                                                              /*cLocalAloc*/,;
			                                                                              /*aCarac*/,;
			                                                                              /*aCursos*/),;
			                                                    At330AtBrw(oMrkAllAtd, aMrkAllAtd[1]) /*Atualiza o browse da alocacao de atendentes*/,;
			                                                    lRfzConsul := .F.,;
			                                                    dBkpDe := dAlocDe,;
			                                                    dBkpAte := dAlocAte})),;
			                     nil)))			
		Else	
			
			@ 000,000 LISTBOX oLbxCfgAlo FIELDS HEADER {} SIZE oDlgCfgAlo:nWidth/2,oDlgCfgAlo:nHeight/2 OF oDlgCfgAlo PIXEL;
				ON dblClick( aEval(aConfAloc,{|x|x[1] := .F.}),;
				                   (IIf(at330VldOk(aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg]),;
				                        (( aConfAloc[oLbxCfgAlo:nAt][1] := .T.,;
				                           oLbxCfgAlo:Refresh(),;
				                           /*Limpa os filtros*/ At330ClrFl(oTreeDtFil,lTecXRh),;
				                           /*Carrega os Cargos*/ IIF(lTecXRh, At330VAddC(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosCargo]), Nil),; 
				                           /*Carrega as Funções*/ At330VAddF(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]),;
				                           /*Carrega o Turno Trab*/ At330VAddT(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosTurno]),;
				                           /*Carrega a Sequencia do turno*/ At330VAddS(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosSeqTrn]),;
				                           /*Carrega o C.Custo*/ At330VAdCc(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosCC]) ),;
				                         /*Carrega as Regiões*/ At330VAdRg(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosLocal]),;
				                         /*Caracteristica*/ At330VAdCR(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosCarac]),;
				                         /*Curso*/ At330VAdCU(oTreeDtFil, aConfAloc[oLbxCfgAlo:nAt][nPosCurso]),;
				                         /*Habilidade*/ At330VAddH(oTreeDtFil,;
				                                                   aConfAloc[oLbxCfgAlo:nAt][nPosHabil],;
				                                                   aConfAloc[oLbxCfgAlo:nAt][nPosEscala],;
				                                                   aConfAloc[oLbxCfgAlo:nAt][nPosItEsc],;
				                                                   /*nNivel*/,;
				                                                   lTecXRH),;
				                         MsgRun(STR0007, STR0008, {|| At330ClrDt(oTreeDtFil),; // "Localizando os atendentes..."##"Aguarde"
				                                                      ApagarTemp(oMrkAllAtd:Alias()),;
				                                                      ApagarTemp(oMrkAtdAlo:Alias()),;
				                                                      /*Busca o periodo inicial da alocação*/ (dAlocDe := aConfAloc[oLbxCfgAlo:nAt][nPosPerIni], oMGAlocDe:CtrlRefresh()),;
				                                                      /*Busca o periodo final da alocação*/ (dAlocAte := aConfAloc[oLbxCfgAlo:nAt][nPosPerFim], oMGAlocAte:CtrlRefresh()),;
				                                                      /*Busca Atendentes*/ aMrkAllAtd := ListarApoio(dAlocDe /*dIniAloc*/,;
				                                                                                                     dAlocAte /*dFimAloc*/,;
				                                                                                                     IIF(lTecXRh, {aConfAloc[oLbxCfgAlo:nAt][nPosCargo]}, Nil) /*aCargos*/,;
				                                                                                                     {aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]} /*aFuncoes*/,;
				                                                                                                     At330GTree(oTreeDtFil,"FILHAB") /*aHabil*/,;
				                                                                                                     /*cDisponib*/,;
				                                                                                                     /*cContIni*/,;
				                                                                                                     /*cContFim*/,;
				                                                                                                     At330GTree(oTreeDtFil,"FILCC")[1] /*cCCusto*/,;
				                                                                                                     cItCbxSel /*cLista*/,;
				                                                                                                     /*nLegenda*/,;
				                                                                                                     /*cItemOS*/,;
				                                                                                                     {aConfAloc[oLbxCfgAlo:nAt][nPosTurno]} /*aTurnos*/,;
				                                                                                                     At330GTree(oTreeDtFil,"FILREG") /*aRegiao*/,;
				                                                                                                     /*lEstrut*/,;
				                                                                                                     /*aPeriodos*/,;
				                                                                                                     /*cIdCfAbq*/,;
				                                                                                                     /*cLocOrc*/,;
				                                                                                                     At330GTree(oTreeDtFil,"FILSEQ") /*aSeqTrn*/,;
				                                                                                                     /*aPeriodRes*/,;
				                                                                                                     aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocalAloc*/,;
				                                                                                                     At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
				                                                                                                     At330GTree(oTreeDtFil,"FILCUR") /*aCursos*/),;
                                                                    /*Atualiza o browse da alocacao de atendentes*/ At330AtBrw(oMrkAllAtd,aMrkAllAtd[1]),;
                                                                    /*Busca Atendentes Alocados*/ aMrkAtdAlo := ListarApoio(dAlocDe /*dIniAloc*/,;
                                                                                                                            dAlocAte /*dFimAloc*/,;
                                                                                                                            /*IIF(lTecXRh,{aConfAloc[oLbxCfgAlo:nAt][nPosCargo]},Nil)*/ /*aCargos*/,;
                                                                                                                            /*{aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]}*/ /*aFuncoes*/,;
                                                                                                                            /*At330GTree(oTreeDtFil,"FILHAB")*/ /*aHabil*/,;
                                                                                                                            "A" /*cDisponib*/,;
                                                                                                                            /*cContIni*/,;
                                                                                                                            /*cContFim*/,;
                                                                                                                            /*cCCusto*/,;
                                                                                                                            "3" /*cLista*/,;
                                                                                                                            2 /*nLegenda*/,;
                                                                                                                            /*cItemOS*/,;
                                                                                                                            /*{aConfAloc[oLbxCfgAlo:nAt][nPosTurno]}*/ /*aTurnos*/,;
                                                                                                                            /*At330GTree(oTreeDtFil,"FILREG")*/ /*aRegiao*/,;
                                                                                                                            /*lEstrut*/,;
                                                                                                                            /*aPeriodos*/,;
                                                                                                                            aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg] /*cIdCfAbq*/,;
                                                                                                                            aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocOrc*/,;
                                                                                                                            /*aSeqTrn*/,;
                                                                                                                            /*aPeriodRes*/,;
                                                                                                                            aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocalAloc*/,;
                                                                                                                            At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
                                                                                                                            /*aCursos*/),;
                                                                    /*Atualiza o browse de atendentes alocados*/ At330AtBrw(oMrkAtdAlo, aMrkAtdAlo[1]),;
                                                                    lRfzConsul := .F.,;
                                                                    dBkpDe := dAlocDe,;
                                                                    dBkpAte := dAlocAte})),;							
				                        NIL)))
			
		EndIf
		
		
		oLbxCfgAlo:Align := CONTROL_ALIGN_ALLCLIENT
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Popula o Listbox Configuracao para Alocacao. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oLbxCfgAlo:aHeaders := aHeaderAbq
		oLbxCfgAlo:SetArray(aConfAloc)
		oLbxCfgAlo:bLine := {|| At330bLine(aConfAloc[oLbxCfgAlo:nAt]) }
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Janela Detalhes do Atendente | Filtro. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oFWLayer:AddCollumn("DETFIL",50,.F.,"LINETOP")
		oFWLayer:AddWindow("DETFIL","oDlgDetFil",STR0009,100,.F.,.F.,,"LINETOP",{||})  // "Detalhes do Atendente | Filtro"
		oDlgDetFil	:= oFWLayer:GetWinPanel("DETFIL","oDlgDetFil","LINETOP")
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa Tree Detalhes do Atendente | Filtro. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oTreeDtFil := At330MTree(oDlgDetFil,lTecXRh) 

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Cria o Menu POP-UP  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		MENU oMnuDtFil POPUP OF oTreeDtFil
			aAdd(oMnuItDFil,MenuAddItem(STR0014,,,.T.,,,,oMnuDtFil,{|| At330AddIt(oTreeDtFil,lTecXRh) },,,,,{ || .T. } ))	// Adicionar
			aAdd(oMnuItDFil,MenuAddItem(STR0015,,,.T.,,,,oMnuDtFil,{|| At330RemIt(oTreeDtFil,lTecXRh) },,,,,{ || .T. } ))	// Remover
			aAdd(oMnuItDFil,MenuAddItem(STR0163,,,.T.,,,,oMnuDtFil,{|| At330ClrPt(oTreeDtFil) },,,,,{ || .T. }))       		// Limpar Pasta
			aAdd(oMnuItDFil,MenuAddItem(STR0016,,,.T.,,,,oMnuDtFil,{|| IIF(lPermFiltr,At330ClrFl(oTreeDtFil,lTecXRh),MsgAlert(STR0187)) },,,,,{ || .T. }))		// "Limpar Filtro"#"Usuário não tem permissão para limpar o filtro"	
			aAdd(oMnuItDFil,MenuAddItem(STR0017,,,.T.,,,,oMnuDtFil,bOkFiltro,,,,,{ || .T. }))  // "Executar Filtro"#"Localizando os atendentes..."#"Aguarde"			
		ENDMENU
		                                
		oTreeDtFil:bRClicked := {|oTreeDtFil,x,y| oMnuDtFil:Activate(x-650,y-160,oTreeDtFil) } // Posição x,y em relação a Dialog
		
		oFWLayer:SetColSplit("DETFIL", CONTROL_ALIGN_RIGHT,"LINETOP")
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Janela Atendentes do Gestao de Servicos. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oFWLayer:AddLine("LINEBOTTOM",70,.F.)
		oFWLayer:AddCollumn("ALLATEND",49,.T.,"LINEBOTTOM")
		
		oFWLayer:AddWindow("ALLATEND","oDlgAllAtd",STR0018,100,.F.,.F.,,"LINEBOTTOM",{||})  // "Atendentes"
		oDlgAllAtd := oFWLayer:GetWinPanel("ALLATEND","oDlgAllAtd","LINEBOTTOM")
		
		oPnlParams := TPanel():New(000,000,"",oDlgAllAtd,,,,,,(oDlgAllAtd:nWidth/2),(oDlgAllAtd:nHeight/2)*0.10)
		oPnlParams:Align := CONTROL_ALIGN_TOP
		
		@000,002 TO (oPnlParams:nHeight/2),(oPnlParams:nWidth/2)-2 LABEL STR0019 PIXEL OF oPnlParams     // "Parametros"
		
		@008,008 SAY STR0020 SIZE 35,10 OF oPnlParams PIXEL  // "Alocação de:"
		@006,042 MSGET oMGAlocDe VAR dAlocDe PICTURE ""  SIZE 40,10 OF oPnlParams WHEN At740Recor(cNrContrat) VALID At330VldDt(cNrContrat,dAlocDe) ON CHANGE ( IIF(dBkpDe<>dAlocDe,lRfzConsul := .T.,lRfzConsul := .F.)) PIXEL
		
		@008,086 SAY STR0151 SIZE 35,10 OF oPnlParams PIXEL  // "Alocação até:"
		@006,123 MSGET oMGAlocAte VAR dAlocAte PICTURE ""  SIZE 40,10 OF oPnlParams WHEN At740Recor(cNrContrat) VALID At330VldDt(cNrContrat,dAlocDe,dAlocAte) ON CHANGE ( IIF(dBkpAte<>dAlocAte,lRfzConsul := .T.,lRfzConsul := .F.)) PIXEL
					
		@008,168 SAY STR0021 SIZE 35,10 OF oPnlParams PIXEL  // "Filtrar por:"
		@007,196 COMBOBOX oCbxFilt VAR cItCbxSel ITEMS aFiltCbx SIZE 66, 10 OF oPnlParams PIXEL
		
		oTBParmsOk	:= TButton():New(007,266,STR0022,oPnlParams,bOkFiltro,15,10,,,.F.,.T.,.F.,STR0022,.F.,,,.F. ) // "Ok"#"Localizando os atendentes..."#"Aguarde"
		
		oPnlBrwA1 := TPanel():New(000,000,"",oDlgAllAtd,,,,,,(oDlgAllAtd:nWidth/2),(oDlgAllAtd:nHeight/2)*0.90)
		oPnlBrwA1:Align := CONTROL_ALIGN_BOTTOM
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Browse Atendentes do Gestao de Servicos. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aMrkAllAtd := ListarApoio(/*dIniAloc*/,;
		                          /*dFimAloc*/,;
		                          /*aCargos*/,;
		                          /*aFuncoes*/,;
		                          /*aHabil*/,;
		                          /*cDisponib*/,;
		                          /*cContIni*/,;
		                          /*cContFim*/,;
		                          /*cCCusto*/,;
		                          /*cLista*/,;
		                          /*nLegenda*/,;
		                          /*cItemOS*/,;
		                          /*aTurnos*/,;
		                          /*aRegiao*/,;
		                          /*lEstrut*/,;
		                          /*aPeriodos*/,;
		                          /*cIdCfAbq*/,;
		                          /*cLocOrc*/,;
		                          /*aSeqTrn*/,;
		                          /*aPeriodRes*/,;
		                          /*cLocalAloc*/,;
		                          /*aCarac*/,;
		                          /*aCursos*/)
		
		At330BrwA1(oPnlBrwA1,@oMrkAllAtd,aMrkAllAtd,lTecXRh, @dAlocDe, @dAlocAte, oTreeDtFil, oLbxCfgAlo, cItCbxSel, @aConfAloc,nPosPerFim,@oMrkAtdAlo )		
				
		oMrkAllAtd:SetChange({|| At330TStDt(oTreeDtFil,(oMrkAllAtd:Alias())->TMP_CODTEC,aMrkAllAtd[4],aMrkAllAtd[5],lTecXRh,aMrkAllAtd[6],aMrkAllAtd[7])})
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Acoes para Alocar e Desalocar Atendentes. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		oFWLayer:AddCollumn("ACOES",2,.F.,"LINEBOTTOM")
		oDlgAcoes 	:= oFWLayer:GetColPanel("ACOES","LINEBOTTOM")	
						
		oTbAlocar 	:= TButton():New((oDlgAcoes:nHeight/2*((1/11)*4))-5,(oDlgAcoes:nWidth/2)*0.09,">>",oDlgAcoes,{|| IIF(At330VdAlo(oMrkAllAtd,oTreeOS,lRfzConsul,cNrOrcSrv,cNrContrat,aConfAloc[oLbxCfgAlo:nAt],nPosPerFim),;
		MsgRun(STR0023,STR0008,{|| At330Aloca(dAlocDe,dAlocAte,oMrkAllAtd,oMrkAtdAlo,oTreeOS,oTreeDtFil,oLbxCfgAlo,cItCbxSel,lTecXRh,@aConfAloc,@aMrkAllAtd,@aMrkAtdAlo,Iif(Empty(cNrOrcSrv),/*cNrOrcSrv*/,cNrOrcSrv))}),.F.)};
		,10,10,,,.F.,.T.,.F.,STR0024,.F.,,,.F. ) // "Montando alocação dos atendentes..."#"Aguarde"#"Alocar"
		
		oTbDesaloc	:= TButton():New((oDlgAcoes:nHeight/2*((1/11)*5))-5,(oDlgAcoes:nWidth/2)*0.09,"<<",oDlgAcoes,{|| IIF(At330VdDes(oMrkAtdAlo),;
		MsgRun(STR0025,STR0008,{|| At330Deslo(dAlocDe,dAlocAte,oMrkAllAtd,@aMrkAllAtd,cItCbxSel,oMrkAtdAlo,@aMrkAtdAlo,oTreeOS,@aConfAloc,oLbxCfgAlo,oTreeDtFil,lTecXRh,Iif(Empty(cNrOrcSrv),/*cNrOrcSrv*/,cNrOrcSrv))}),.F.)},10,10,,,.F.,.T.,.F.,STR0159,.F.,,,.F. ) // "Buscando os agendamentos dos atendentes..."#"Aguarde"#"Deslocar"	
			
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Janela Atendentes Alocado no Contrato. ³                                                      
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ                                                                   
		oFWLayer:AddCollumn("ATDALOCADO",49,.F.,"LINEBOTTOM")
		oFWLayer:AddWindow("ATDALOCADO","oDlgAtdAlo",STR0026,100,.F.,.F.,,"LINEBOTTOM",{||}) // "Atendentes Alocados"
		oDlgAtdAlo := oFWLayer:GetWinPanel("ATDALOCADO","oDlgAtdAlo","LINEBOTTOM")
					
		// Verifica o preenchimento do codigo do orçamento de serviços
		If Empty(cNrOrcSrv)				
			
			oPnlTree := TPanel():New(000,000,"",oDlgAtdAlo,,,,,,(oDlgAtdAlo:nWidth/2),(oDlgAtdAlo:nHeight/2)*0.30)
			oPnlTree:Align := CONTROL_ALIGN_TOP
			
			oPnlBrwA2 := TPanel():New(000,000,"",oDlgAtdAlo,,,,,,(oDlgAtdAlo:nWidth/2),(oDlgAtdAlo:nHeight/2)*0.70)
			oPnlBrwA2:Align := CONTROL_ALIGN_BOTTOM	                                                                                             
					
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Tree Ordens de Servicos do Contrato. ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oTreeOS := DBTree():New(000,000,(oPnlTree:nHeight/2),(oPnlTree:nWidth/2),oPnlTree,{|| At330GAtIt(oTreeOS,oMrkAtdAlo)},{|| At330GAtIt(oTreeOS,oMrkAtdAlo)},.T.)
			At330TOS(@oTreeOS)
			oPnlTree:Align := CONTROL_ALIGN_TOP			
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Cria o Menu POP-UP  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MENU oMnuOS POPUP Of oTreeOS
			aAdd(oMnuItOS,MenuAddItem(STR0027,,,.T.,,,,oMnuOS,{|| At330VisOS(oTreeOS) },,,,,{|| .T. } ) )  // "Ordem de  Serviço"
			aAdd(oMnuItOS,MenuAddItem(STR0028,,,.T.,,,,oMnuOS,{|| At330VBase(oTreeOS) },,,,,{|| .T. } ) )  // "Base de Atendimento"
			aAdd(oMnuItOS,MenuAddItem(STR0029,,,.T.,,,,oMnuOS,{|| At330LtOs(oTreeOS) },,,,,{|| .T. } ) )   // "Legenda"
			ENDMENU
			
			oTreeOS:bRClicked := {|oTreeOS,x,y| oMnuOS:Activate(x-650,y-405,oTreeOS) } // Posição x,y em relação a Dialog			
											
		Else			
		
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Exibe somente a janela dos atendentes alocados. ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oPnlBrwA2 := TPanel():New(000,000,"",oDlgAtdAlo,,,,,,(oDlgAtdAlo:nWidth/2),(oDlgAtdAlo:nHeight/2)*1)
			oPnlBrwA2:Align := CONTROL_ALIGN_BOTTOM
										
		Endif	
			
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Browse Atendentes Alocado no Contrato. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aMrkAtdAlo := ListarApoio(/*dIniAloc*/,;
		                          /*dFimAloc*/,;
		                          /*aCargos*/,;
		                          /*aFuncoes*/,;
		                          /*aHabil*/,;
		                          /*cDisponib*/,;
		                          /*cContIni*/,;
		                          /*cContFim*/,;
		                          /*cCCusto*/,;
		                          /*cLista*/,;
		                          /*nLegenda*/,;
		                          /*cItemOS*/,;
		                          /*aTurnos*/,;
		                          /*aRegiao*/,;
		                          .T. /*lEstrut*/,;
		                          /*aPeriodos*/,;
		                          /*cIdCfAbq*/,;
		                          /*cLocOrc*/,;
		                          /*aSeqTrn*/,;
		                          /*aPeriodRes*/,;
		                          /*cLocalAloc*/,;
		                          /*aCarac*/,;
		                          /*aCursos*/)
		
		At330BrwA2(oPnlBrwA2,@oMrkAtdAlo,aMrkAtdAlo,lTecXRh,aConfAloc,oLbxCfgAlo,oTreeDtFil,nPosPerFim)
		
		ACTIVATE DIALOG oDlg CENTERED
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Apaga a tabela temporaria. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		ApagarTemp(aMrkAllAtd[1])
		ApagarTemp(aMrkAtdAlo[1])
	Else
		MsgStop(STR0030,STR0031)  // "Não há recursos configurado para este contrato."#"Atenção"
	EndIf
	
EndIf      

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Restaura o status das variaveis private e public.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RestInter()

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330MTree
Cria o componente DbTree Detalhes do Atendente | Filtro.

@sample 	At330MTree(oDlgDetFil,lTecXRh,lSubst) 

@param		ExpO1 	Dialog para criacao do componente. 
			ExpL2	Integracao Gestao de Servicos com RH? 
			ExpL3	Rotina de Substituicao de Atendentes?
	
@return		ExpO	Objeto DbTree  Detalhes do Atendente | Filtro.

@author		Anderson Silva
@since		30/01/2012       
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330MTree(oDlgDetFil,lTecXRh,lSubst) 

Local oTreeDtFil := Nil																							// Tree Detalhes do Atendente | Filtro.
Local nTamTree	 := IIf(lTecXRh,TAMSX3("RBG_DESC")[1]+TAMSX3("RBK_DESCRI")[1]+TAMSX3("RBL_DESCRI")[1],100)	// Tamanho horizontal do Tree.

Default lSubst	 := .F.  																						// Rotina de Substituicao de Atendentes.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Tree Detalhes do Atendente | Filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oTreeDtFil 	:= DBTree():New(000,000,oDlgDetFil:nHeight/2,(oDlgDetFil:nWidth/2),oDlgDetFil,,,.T.)
oTreeDtFil:Cargo := {}
oTreeDtFil:Align := CONTROL_ALIGN_ALLCLIENT
oTreeDtFil:AddItem(PadR(STR0010,nTamTree),"DETATD","FOLDER5","FOLDER6",,,1)	// "Detalhes do Atendente"
oTreeDtFil:AddItem(STR0011,"HABATEND","FOLDER5","FOLDER6",,,2)   	   		// "Habilidades"
oTreeDtFil:AddItem(STR0221,"CARATEND","FOLDER5","FOLDER6",,,2)  		 	// "Característica"
oTreeDtFil:AddItem(STR0012,"REGATEND","FOLDER5","FOLDER6",,,2)				// "Região de Atendimento"
oTreeDtFil:AddItem(STR0222,"CURATEND","FOLDER5","FOLDER6",,,2)   	   		// "Cursos"
oTreeDtFil:AddItem(STR0013,"FILTRAR","FOLDER5","FOLDER6",,,1)          		// "Filtrar por:"
oTreeDtFil:TreeSeek("FILTRAR")
oTreeDtFil:AddItem(STR0011,"FILHAB","FOLDER5","FOLDER6",,,2)          		// "Habilidades"
aAdd(oTreeDtFil:Cargo,{"FILHAB"})
oTreeDtFil:AddItem(STR0221,"FILCRC","FOLDER5","FOLDER6",,,2)       // "Característica"
aAdd(oTreeDtFil:Cargo,{"FILCRC"})
oTreeDtFil:AddItem(STR0012,"FILREG","FOLDER5","FOLDER6",,,2)   				// "Região de Atendimento"
aAdd(oTreeDtFil:Cargo,{"FILREG"})  
oTreeDtFil:AddItem(STR0222,"FILCUR","FOLDER5","FOLDER6",,,2)          		// "Cursos"
aAdd(oTreeDtFil:Cargo,{"FILCUR"})

If lTecxRh
	oTreeDtFil:AddItem(STR0164,"FILCAR","FOLDER5","FOLDER6",,,2)         	// "Cargo"   
	aAdd(oTreeDtFil:Cargo,{"FILCAR"})
EndIf
oTreeDtFil:AddItem(STR0165,"FILFUN","FOLDER5","FOLDER6",,,2)   			// "Função"	  
aAdd(oTreeDtFil:Cargo,{"FILFUN"})
oTreeDtFil:AddItem(STR0166,"FILTUR","FOLDER5","FOLDER6",,,2)   			// "Turno de Trabalho"	
aAdd(oTreeDtFil:Cargo,{"FILTUR"})
oTreeDtFil:AddItem(STR0112,"FILSEQ","FOLDER5","FOLDER6",,,2)   			// "Sequência do Turno"	
aAdd(oTreeDtFil:Cargo,{"FILSEQ"})  	
oTreeDtFil:AddItem(STR0189,"FILCC","FOLDER5","FOLDER6",,,2)  				// "Centro de Custo"	
aAdd(oTreeDtFil:Cargo,{"FILCC"})  

Return( oTreeDtFil )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GtABQ
Busca os produtos de alocacao configurados para o contrato.

@sample 	At330GtABQ(aHeaderAbq,aConfAloc,lTecXRh)   

@param		ExpA1	Cabecalho do browse conf. para alocacao.	
			ExpA2	Itens do browse conf. para alocacao.
			ExpL3	Integracao Gestao de Servicos com RH?
			ExpC4	Codigo orçamento de serviços
			
@return		ExpL	Verdadeiro

@author		Anderson Silva
@since		05/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330GtABQ(aHeaderAbq,aConfAloc,lTecXRh,cNrOrcSrv,lSrvExt)

Local lRetorno		:= .T.						// Retorno da rotina.
Local aArea    		:= GetArea()				// Guarda a area atual.
Local aAreaABQ 		:= ABQ->(GetArea())		// Guarda a area ABQ.
Local aLinCfgAll		:= {}						// Linha do array que contem a configuracao da alocacao.
Local cSeek			:= ""
Local cWhere			:= ""
Local cAliasABQ		:= GetNextAlias()
Local cRetorno		:= ""
Local lFilTFF        := FindFunction("ExistFilTFF") .And. ExistFilTFF()
Local aCarac		:= {}
Local aCursos		:= {}
Local aHabil		:= {}
Local aEscala		:= {}
Local aItEsc		:= {}

Default cNrOrcSrv 	:= ""
Default lSrvExt 	:= .F.

Aadd(aHeaderAbq,"")

If !Empty(cNrOrcSrv)
	Aadd(aHeaderAbq,STR0199)	// "Código"
	Aadd(aHeaderAbq,STR0033)		// "Descrição"
EndIf
Aadd(aHeaderAbq,STR0032)		// "Produto"
Aadd(aHeaderAbq,STR0033)		// "Descrição"
Aadd(aHeaderAbq,STR0034)		// "Tipo de Produto"
If lTecXRh
	Aadd(aHeaderAbq,STR0035)	// "Cargo"
	Aadd(aHeaderAbq,STR0036)	// "Descrição"
EndIf
Aadd(aHeaderAbq,STR0037)        // "Função"
Aadd(aHeaderAbq,STR0038)     	// "Descrição"
Aadd(aHeaderAbq,STR0039)   		// "Periodo Inicial"
Aadd(aHeaderAbq,STR0040)    	// "Periodo Final"
Aadd(aHeaderAbq,STR0041)       	// "Turno"
Aadd(aHeaderAbq,STR0038)      	// "Descrição"
Aadd(aHeaderAbq,STR0204)       	// "Seq.  turno"
Aadd(aHeaderAbq,STR0042)   		// "Horas Contratadas"
Aadd(aHeaderAbq,STR0043)      	// "Horas Alocadas"
Aadd(aHeaderAbq,STR0044)		// "Saldo de Horas"
Aadd(aHeaderAbq,STR0188)		// "Recursos"
Aadd(aHeaderAbq,STR0189)		//"Centro de Custo"

If Empty(cNrOrcSrv)

	cSeek := AAH->AAH_CONTRT

	cWhere := "%ABQ.ABQ_ORIGEM = '   ' AND %"

	BeginSql Alias cAliasABQ

		SELECT DISTINCT
			ABQ.ABQ_FILIAL, ABQ.ABQ_CONTRT, ABQ.ABQ_CODTFF, ABQ.ABQ_LOCAL,
			ABS.ABS_DESCRI, ABQ.ABQ_PRODUT, SB1.B1_DESC,    ABQ.ABQ_TPPROD,
			ABQ.ABQ_CARGO, 	ABQ.ABQ_FUNCAO, SRJ.RJ_DESC,
			ABQ.ABQ_PERINI, ABQ.ABQ_PERFIM, ABQ.ABQ_TURNO,  SR6.R6_DESC,
			ABQ.ABQ_TOTAL,  ABQ.ABQ_SALDO,  ABQ.ABQ_FATOR,  AAH.AAH_CCUSTO,
			ABQ.ABQ_ITEM,   ABQ.ABQ_ORIGEM
		FROM 
			%table:ABQ% ABQ 
			LEFT JOIN %table:ABS% ABS 
				   ON ABS.ABS_FILIAL = %xFilial:ABS%
			      AND ABS.ABS_LOCAL  = ABQ.ABQ_LOCAL	      
			      AND ABS.%NotDel%
			LEFT JOIN %table:SB1% SB1 
				   ON SB1.B1_FILIAL = %xFilial:SB1%
			      AND SB1.B1_COD    = ABQ.ABQ_PRODUT
			      AND SB1.%NotDel%
			LEFT JOIN %table:SQ3% SQ3 
				   ON SQ3.Q3_FILIAL = %xFilial:SQ3%
			      AND SQ3.Q3_CARGO  = ABQ.ABQ_CARGO
			      AND SQ3.%NotDel%
			LEFT JOIN %table:SRJ% SRJ 
				   ON SRJ.RJ_FILIAL = %xFilial:SRJ%
			      AND SRJ.RJ_FUNCAO = ABQ.ABQ_FUNCAO
			      AND SRJ.%NotDel%
			LEFT JOIN %table:SR6% SR6 
				   ON SR6.R6_FILIAL = %xFilial:SR6%
			      AND SR6.R6_TURNO  = ABQ.ABQ_TURNO
			      AND SR6.%NotDel%	
			LEFT JOIN %table:AAH% AAH
				   ON AAH.AAH_FILIAL = %xFilial:AAH%
			      AND AAH.AAH_CONTRT = ABQ.ABQ_CONTRT	      
			      AND AAH.%NotDel%
		WHERE
			ABQ.ABQ_FILIAL = %xFilial:AAH% 	AND 
			ABQ.ABQ_CONTRT = %Exp:cSeek%	AND
			%Exp:cWhere%			
			ABQ.%NotDel%

		GROUP BY ABQ.ABQ_FILIAL, ABQ.ABQ_CONTRT, ABQ.ABQ_CODTFF, ABQ.ABQ_LOCAL,
			ABS.ABS_DESCRI, ABQ.ABQ_PRODUT, SB1.B1_DESC,    ABQ.ABQ_TPPROD,
			ABQ.ABQ_CARGO, 	ABQ.ABQ_FUNCAO, SRJ.RJ_DESC,
			ABQ.ABQ_PERINI, ABQ.ABQ_PERFIM, ABQ.ABQ_TURNO,  SR6.R6_DESC,
			ABQ.ABQ_TOTAL,  ABQ.ABQ_SALDO,  ABQ.ABQ_FATOR,  AAH.AAH_CCUSTO,
			ABQ.ABQ_ITEM,   ABQ.ABQ_ORIGEM
	EndSql
		
ElseIf lSrvExt

	BeginSql Alias cAliasABQ

		SELECT DISTINCT
			ABQ.ABQ_FILIAL, ABQ.ABQ_CONTRT, ABQ.ABQ_CODTFF, ABQ.ABQ_LOCAL,
			ABS.ABS_DESCRI, ABQ.ABQ_PRODUT, SB1.B1_DESC,    ABQ.ABQ_TPPROD,
			ABQ.ABQ_CARGO,  ABQ.ABQ_FUNCAO, SRJ.RJ_DESC,
			ABQ.ABQ_PERINI, ABQ.ABQ_PERFIM, ABQ.ABQ_TURNO,  SR6.R6_DESC,
			ABQ.ABQ_TOTAL,  ABQ.ABQ_SALDO,  ABQ.ABQ_FATOR,  ABS.ABS_CCUSTO,
			ABQ.ABQ_ITEM,   ABQ.ABQ_ORIGEM, ABQ.ABQ_FILTFF		
		FROM 
			%table:ABQ% ABQ 
			
			INNER JOIN %table:TFF% TFF ON 
				TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_FILIAL = ABQ.ABQ_FILTFF
				AND TFF.TFF_COD = ABQ.ABQ_CODTFF			
				AND TFF.%NotDel%
						
			INNER JOIN %table:TFL% TFL ON
				TFL.TFL_FILIAL = %xFilial:TFL%
				AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
				AND TFL.TFL_CODPAI = %Exp:cNrOrcSrv% 
				AND TFL.%NotDel%
			
			LEFT JOIN %table:ABS% ABS 
					ON ABS.ABS_FILIAL = %xFilial:ABS%
					AND ABS.ABS_LOCAL  = ABQ.ABQ_LOCAL	      
					AND ABS.%NotDel%
			LEFT JOIN %table:SB1% SB1 
					ON SB1.B1_FILIAL = %xFilial:SB1%
					AND SB1.B1_COD    = ABQ.ABQ_PRODUT
					AND SB1.%NotDel%
			LEFT JOIN %table:SQ3% SQ3 
					ON SQ3.Q3_FILIAL = %xFilial:SQ3%
					AND SQ3.Q3_CARGO  = ABQ.ABQ_CARGO
					AND SQ3.%NotDel%
			LEFT JOIN %table:SRJ% SRJ 
					ON SRJ.RJ_FILIAL = %xFilial:SRJ%
					AND SRJ.RJ_FUNCAO = ABQ.ABQ_FUNCAO
					AND SRJ.%NotDel%
			LEFT JOIN %table:SR6% SR6 
					ON SR6.R6_FILIAL = %xFilial:SR6%
					AND SR6.R6_TURNO  = ABQ.ABQ_TURNO
					AND SR6.%NotDel%,
											
			%table:TFJ% TFJ
		WHERE
			ABQ.ABQ_FILIAL = %xFilial:ABQ% 		AND 
			TFJ.TFJ_FILIAL = %xFilial:TFJ% 		AND
			TFL.TFL_FILIAL = %xFilial:TFL% 		AND			
			TFJ.TFJ_CODIGO = %Exp:cNrOrcSrv% 	AND
			TFJ.TFJ_CODIGO = TFL.TFL_CODPAI		AND
			ABQ.%NotDel% 						AND 
			TFJ.%NotDel% 						AND
			TFL.%NotDel% 						

			GROUP BY ABQ.ABQ_FILIAL, ABQ.ABQ_CONTRT, ABQ.ABQ_CODTFF, ABQ.ABQ_LOCAL,
			ABS.ABS_DESCRI, ABQ.ABQ_PRODUT, SB1.B1_DESC,    ABQ.ABQ_TPPROD,
			ABQ.ABQ_CARGO,  ABQ.ABQ_FUNCAO, SRJ.RJ_DESC,
			ABQ.ABQ_PERINI, ABQ.ABQ_PERFIM, ABQ.ABQ_TURNO,  SR6.R6_DESC,
			ABQ.ABQ_TOTAL,  ABQ.ABQ_SALDO,  ABQ.ABQ_FATOR,  ABS.ABS_CCUSTO,
			ABQ.ABQ_ITEM,   ABQ.ABQ_ORIGEM, ABQ.ABQ_FILTFF	

	EndSql
Else
	BeginSql Alias cAliasABQ

		SELECT DISTINCT
			ABQ.ABQ_FILIAL, ABQ.ABQ_CONTRT, ABQ.ABQ_CODTFF, ABQ.ABQ_LOCAL,
			ABS.ABS_DESCRI, ABQ.ABQ_PRODUT, SB1.B1_DESC,    ABQ.ABQ_TPPROD,
			ABQ.ABQ_CARGO,  ABQ.ABQ_FUNCAO, SRJ.RJ_DESC,
			ABQ.ABQ_PERINI, ABQ.ABQ_PERFIM, ABQ.ABQ_TURNO,  SR6.R6_DESC,
			ABQ.ABQ_TOTAL,  ABQ.ABQ_SALDO,  ABQ.ABQ_FATOR,  ABS.ABS_CCUSTO,
			ABQ.ABQ_ITEM,   ABQ.ABQ_ORIGEM, ADY.ADY_TPCONT, ABQ.ABQ_FILTFF		
		FROM 
			%table:ABQ% ABQ 
			
			INNER JOIN %table:TFF% TFF ON 
				TFF.TFF_FILIAL = %xFilial:TFF%
				AND TFF.TFF_FILIAL = ABQ.ABQ_FILTFF
				AND TFF.TFF_COD = ABQ.ABQ_CODTFF			
				AND TFF.%NotDel%
						
			INNER JOIN %table:TFL% TFL ON
				TFL.TFL_FILIAL = %xFilial:TFL%
				AND TFL.TFL_CODIGO = TFF.TFF_CODPAI
				AND TFL.TFL_CODPAI = %Exp:cNrOrcSrv% 
				AND TFL.%NotDel%
			
			LEFT JOIN %table:ABS% ABS 
					ON ABS.ABS_FILIAL = %xFilial:ABS%
					AND ABS.ABS_LOCAL  = ABQ.ABQ_LOCAL	      
					AND ABS.%NotDel%
			LEFT JOIN %table:SB1% SB1 
					ON SB1.B1_FILIAL = %xFilial:SB1%
					AND SB1.B1_COD    = ABQ.ABQ_PRODUT
					AND SB1.%NotDel%
			LEFT JOIN %table:SQ3% SQ3 
					ON SQ3.Q3_FILIAL = %xFilial:SQ3%
					AND SQ3.Q3_CARGO  = ABQ.ABQ_CARGO
					AND SQ3.%NotDel%
			LEFT JOIN %table:SRJ% SRJ 
					ON SRJ.RJ_FILIAL = %xFilial:SRJ%
					AND SRJ.RJ_FUNCAO = ABQ.ABQ_FUNCAO
					AND SRJ.%NotDel%
			LEFT JOIN %table:SR6% SR6 
					ON SR6.R6_FILIAL = %xFilial:SR6%
					AND SR6.R6_TURNO  = ABQ.ABQ_TURNO
					AND SR6.%NotDel%,
											
			%table:TFJ% TFJ, %table:ADY% ADY 
		WHERE
			ABQ.ABQ_FILIAL = %xFilial:AAH% 		AND 
			TFJ.TFJ_FILIAL = %xFilial:TFJ% 		AND
			TFL.TFL_FILIAL = %xFilial:TFL% 		AND			
			ADY.ADY_FILIAL = %xFilial:ADY% 		AND
			TFJ.TFJ_CODIGO = %Exp:cNrOrcSrv% 	AND
			TFJ.TFJ_CODIGO = TFL.TFL_CODPAI		AND
			ABQ.ABQ_CONTRT = TFL.TFL_CONTRT		AND			
			TFJ.TFJ_PROPOS = ADY.ADY_PROPOS 	AND 
			TFJ.TFJ_PREVIS = ADY.ADY_PREVIS		AND
			((ADY.ADY_TPCONT = "4" 				AND 
			ABQ.ABQ_ORIGEM = "CN9") 				OR 
			ABQ.ABQ_ORIGEM = "   ")				AND
			ABQ.%NotDel% 							AND 
			TFJ.%NotDel% 							AND
			TFL.%NotDel% 							AND			
			ADY.%NotDel% 
			
			GROUP BY ABQ.ABQ_FILIAL, ABQ.ABQ_CONTRT, ABQ.ABQ_CODTFF, ABQ.ABQ_LOCAL,
			ABS.ABS_DESCRI, ABQ.ABQ_PRODUT, SB1.B1_DESC,    ABQ.ABQ_TPPROD,
			ABQ.ABQ_CARGO,  ABQ.ABQ_FUNCAO, SRJ.RJ_DESC,
			ABQ.ABQ_PERINI, ABQ.ABQ_PERFIM, ABQ.ABQ_TURNO,  SR6.R6_DESC,
			ABQ.ABQ_TOTAL,  ABQ.ABQ_SALDO,  ABQ.ABQ_FATOR,  ABS.ABS_CCUSTO,
			ABQ.ABQ_ITEM,   ABQ.ABQ_ORIGEM, ADY.ADY_TPCONT, ABQ.ABQ_FILTFF

	EndSql

EndIf

While (cAliasABQ)->(!Eof())

	aLinCfgAll := {}
	
	Aadd(aLinCfgAll,.F.)
	
	If !Empty(cNrOrcSrv)
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABQ_LOCAL))
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABS_DESCRI))
	Endif
		
	Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABQ_PRODUT))
	Aadd(aLinCfgAll,Alltrim((cAliasABQ)->B1_DESC))
	Aadd(aLinCfgAll,X3Combo("ABQ_TPPROD",(cAliasABQ)->ABQ_TPPROD))
	If lTecXRh
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABQ_CARGO))
		Aadd(aLinCfgAll,Alltrim( Posicione( "SQ3", 1, xFilial("SQ3")+ (cAliasABQ)->ABQ_CARGO, "Q3_DESCSUM") ) )
	EndIf
	Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABQ_FUNCAO))
	Aadd(aLinCfgAll,Alltrim((cAliasABQ)->RJ_DESC))
	Aadd(aLinCfgAll,sTod((cAliasABQ)->ABQ_PERINI))
	Aadd(aLinCfgAll,sTod((cAliasABQ)->ABQ_PERFIM))
	Aadd(aLinCfgAll,(cAliasABQ)->ABQ_TURNO)
	Aadd(aLinCfgAll,Alltrim((cAliasABQ)->R6_DESC))
	Aadd(aLinCfgAll,If(Empty(cNrOrcSrv),"",Posicione("TFF",1,xFilial("TFF")+(cAliasABQ)->ABQ_CODTFF,"TFF_SEQTRN")))
	Aadd(aLinCfgAll,Transform((cAliasABQ)->ABQ_TOTAL,PesqPict("ABQ","ABQ_TOTAL")))
	Aadd(aLinCfgAll,Transform(((cAliasABQ)->ABQ_TOTAL-(cAliasABQ)->ABQ_SALDO),PesqPict("ABQ","ABQ_TOTAL")))
	Aadd(aLinCfgAll,Transform((cAliasABQ)->ABQ_SALDO,PesqPict("ABQ","ABQ_SALDO")))
	Aadd(aLinCfgAll,(cAliasABQ)->ABQ_FATOR)
	If Empty(cNrOrcSrv)	
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->AAH_CCUSTO))
	Else
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABS_CCUSTO))
	EndIf
	If !Empty(cNrOrcSrv) 
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABQ_CONTRT+(cAliasABQ)->ABQ_ITEM+(cAliasABQ)->ABQ_ORIGEM))
	Else
		Aadd(aLinCfgAll,Alltrim((cAliasABQ)->ABQ_CONTRT+(cAliasABQ)->ABQ_ITEM))
	EndIf
	
	// Carrega as caracteristicas
	aCarac := {}
	DbSelectArea("TDS")
	TDS->(DbSetOrder(2)) //TDS_FILIAL, TDS_CODTFF
	TDS->(DbSeek(xFilial("TDS")+(cAliasABQ)->ABQ_CODTFF))
	DO WHILE TDS->(!EOF()) .AND. TDS->TDS_FILIAL == xFilial("TDS") .AND. TDS->TDS_CODTFF == (cAliasABQ)->ABQ_CODTFF
		Aadd(aCarac,TDS->TDS_CODTCZ)
		TDS->(DbSkip())
	END
	
	Aadd(aLinCfgAll,aCarac)

	// Carrega os cursos
	aCursos := {}
	DbSelectArea("TGV")
	TGV->(DbSetOrder(2)) //TGV_FILIAL, TGV_CODTFF
	TGV->(DbSeek(xFilial("TGV")+(cAliasABQ)->ABQ_CODTFF))
	DO WHILE TGV->(!EOF()) .AND. TGV->TGV_FILIAL == xFilial("TGV") .AND. TGV->TGV_CODTFF == (cAliasABQ)->ABQ_CODTFF
		Aadd(aCursos,TGV->TGV_CURSO)
		TGV->(DbSkip())
	END
	Aadd(aLinCfgAll,aCursos)

	// Carrega as Habilidades
	aHabil  := {}
	aEscala := {}
	aItEsc  := {}

	DbSelectArea("TDT")
	TDT->(DbSetOrder(2)) //TDT_FILIAL, TDT_CODTFF
	TDT->(DbSeek(xFilial("TDT")+(cAliasABQ)->ABQ_CODTFF))
	DO WHILE TDT->(!EOF()) .AND. TDT->TDT_FILIAL == xFilial("TDT") .AND. TDT->TDT_CODTFF == (cAliasABQ)->ABQ_CODTFF
	
		IF lTecXRh 
			Aadd(aHabil,TDT->TDT_CODHAB)
			Aadd(aEscala,TDT->TDT_ESCALA)
			Aadd(aItEsc,TDT->TDT_ITESCA)
		ELSE
			Aadd(aHabil,TDT->TDT_HABX5)
		ENDIF
		TDT->(DbSkip())
	END
	Aadd(aLinCfgAll,aHabil)
	Aadd(aLinCfgAll,aEscala)
	Aadd(aLinCfgAll,aItEsc)
	
	aAdd(aConfAloc,aLinCfgAll)
	
	(cAliasABQ)->(dbSkip())

EndDo

RestArea(aArea)
RestArea(aAreaABQ)

(cAliasABQ)->(dbCloseArea())

//Ordena Configuração de alocação por Local, Função, Turno, Sequencia
aSort(aConfAloc, , ,{|x, y| x[nPosLocal]+x[nPosFuncao]+x[nPosTurno]+x[nPosSeqTrn] < y[nPosLocal]+y[nPosFuncao]+y[nPosTurno]+y[nPosSeqTrn] })

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330BLine
Avalia a linha configuracao da alocacao.

@sample 	At330BLine(aLinha)   

@param		ExpA1	Array com a configuracao da alocacao.	
			
@return		ExpA	Linha da configuracao da alocacao avaliada.	

@author		Anderson Silva
@since		05/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330BLine(aLinha)

Local aBkpLinha := aLinha  						   	   			// Backup da configuracao da alocacao.
Local oOk 		:= LoadBitMap(GetResources(), "LBOK")			// Imagem checkbox marcado.
Local oNo 		:= LoadBitMap(GetResources(), "LBNO")			// Imagem checkbox desmarcado.

If ValType(aBkpLinha[1]) == "L"
	aBkpLinha[1] := Iif(aBkpLinha[1],oOk,oNo)
EndIf

Return( aBkpLinha )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330TStDt
Seta os detalhes do atendente no Tree. 

@sample 	At330TStDt(oTreeDtFil,cCodAtend,aHabAtend,aRegAtend,lTecXRh,aCarAtend,aCurAtend)  

@param		ExpO1	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2 	Codigo do Atendente.
 			ExpA3 	Habilidades do Atendente.
			ExpA4 	Região de Atendimento do Atendente.
			ExpL5	Integracao Gestao de Servicos com RH?
			ExpL6	Caracteristica do atendente
			ExpL7	Curso do Funcionário
			 						
@return		ExpL 	Verdadeiro	

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330TStDt(oTreeDtFil,cCodAtend,aHabAtend,aRegAtend,lTecXRh,aCarAtend,aCurAtend)

Local lRetorno 		:= .T.									// Retorno da rotina.
Local aArea 		:= GetArea()							// Guarda a area atual.
Local aAreaAA2 		:= AA2->(GetArea())					// Guarda a area AA2.
Local cIdTree		:= StrZero(0,6)							// Id utilizado para identificar o item do tree.
Local nPosAtd		:= 0									// Posicao do codigo do atendente no array aHabAtend.
Local nX			:= 0 									// Incremento utilizado no laco for.

Default cCodAtend 	:= ""									// Codigo do atendente.
Default aHabAtend 	:= {}									// Habilidades do atendente.
Default aRegAtend	:= {}									// Regiao de atendimento do atendente.
Default aCarAtend 	:= {}
Default aCurAtend 	:= {}

If !oTreeDtFil:IsEmpty()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Deleta a pasta habilidades do ultimo atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		IF oTreeDtFil:TreeSeek("HABATEND")
			oTreeDtFil:DelItem()
		ENDIF
	ENDIF
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Deleta a pasta regiao de atendimento do ultimo atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		IF oTreeDtFil:TreeSeek("REGATEND")
			oTreeDtFil:DelItem()
		ENDIF
	ENDIF
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Deleta a pasta Caracteristica do ultimo atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		IF oTreeDtFil:TreeSeek("CARATEND")
			oTreeDtFil:DelItem()
		ENDIF
	ENDIF
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Deleta a pasta Curso do ultimo atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		IF oTreeDtFil:TreeSeek("CURATEND")
			oTreeDtFil:DelItem()
		ENDIF
	ENDIF
			
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Adiciona uma nova pasta habilidade para atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		oTreeDtFil:AddItem(STR0011,"HABATEND","FOLDER5","FOLDER6",,,2) // "Habilidades"
		IF oTreeDtFil:TreeSeek("HABATEND")

			If lTecXRh
				
				nPosAtd := aScan(aHabAtend,{|x| x[1] == cCodAtend })
				
				If nPosAtd > 0
					For nX := 2 To Len(aHabAtend[nPosAtd])
						cIdTree	 := "HabAtd"  
						oTreeDtFil:AddItem(STR0045+aHabAtend[nPosAtd][nX][2]+STR0046+aHabAtend[nPosAtd][nX][5]+;
						STR0047+aHabAtend[nPosAtd][nX][7],cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#" | Escala: "#" | Item da Escala: "
					Next nX
				EndIf
			Else
				
				nPosAtd := aScan(aHabAtend,{|x| x[1] == cCodAtend })
				
				If nPosAtd > 0
					For nX := 2 To Len(aHabAtend[nPosAtd])
						cIdTree	 := "HabAtd"
						oTreeDtFil:AddItem(STR0045+aHabAtend[nPosAtd][nX][2]+STR0048+;
						cValToChar(aHabAtend[nPosAtd][nX][3]),cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#" | Nivel: "
					Next nX
				EndIf
				
			EndIf
		ENDIF
	ENDIF
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Adiciona uma nova pasta Caracteristica do atendimento para atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		oTreeDtFil:AddItem(STR0221,"CARATEND","FOLDER5","FOLDER6",,,2) // "Característica"
		IF oTreeDtFil:TreeSeek("CARATEND")
	
			nPosAtd := aScan(aCarAtend,{|x| x[1] == cCodAtend })
			
			If nPosAtd > 0
				For nX := 2 To Len(aCarAtend[nPosAtd])
					cIdTree	 := "CarAtd"
					oTreeDtFil:AddItem(STR0223+aCarAtend[nPosAtd][nX][2],cIdTree,"PMSTASK4",,,,2) // "Característica: "
				Next nX
			EndIf
		ENDIF
	ENDIF
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Adiciona uma nova pasta regiao de atendimento para atendente selecionado no grid. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF oTreeDtFil:TreeSeek("DETATD")
		oTreeDtFil:AddItem(STR0012,"REGATEND","FOLDER5","FOLDER6",,,2) // "Região de Atendimento"
		IF oTreeDtFil:TreeSeek("REGATEND")
	
			nPosAtd := aScan(aRegAtend,{|x| x[1] == cCodAtend })
			
			If nPosAtd > 0
				For nX := 2 To Len(aRegAtend[nPosAtd])
					cIdTree	 := "RegAtd"
					oTreeDtFil:AddItem(STR0049+aRegAtend[nPosAtd][nX][2],cIdTree,"PMSTASK4",,,,2) // "Região: "
				Next nX
			EndIf
		
			//Curso
			oTreeDtFil:TreeSeek("DETATD")
			oTreeDtFil:AddItem(STR0222,"CURATEND","FOLDER5","FOLDER6",,,2) // "Cursos"
			oTreeDtFil:TreeSeek("CURATEND")
					
			nPosAtd := aScan(aCurAtend,{|x| x[1] == cCodAtend })
			
			If nPosAtd > 0
				For nX := 2 To Len(aCurAtend[nPosAtd])
					cIdTree	 := "CurAtd" 
					oTreeDtFil:AddItem(STR0224+aCurAtend[nPosAtd][nX][2],cIdTree,"PMSTASK4",,,,2) // "Curso: "
				Next nX
			EndIf	

		ENDIF
	ENDIF
		
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Indica o termino da contrução da Tree. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTreeDtFil:EndTree()
	
EndIf

RestArea(aArea)
RestArea(aAreaAA2)

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AddIt
Chamada da interface para adicionar informacoes nas pastas de filtro.

@sample 	At330AddIt(oTreeDtFil,lTecXRh)  

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 
			ExpL2	Integracao Gestao de Servicos com RH?

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330AddIt(oTreeDtFil,lTecXRh)

Local lRetorno  	:= .T.								// Retorno da rotina.
Local lPermFiltr	:= SuperGetMv("MV_TECPRMF",,.T.)    // Usuario tem permissão para manipular filtro

If At330FilAce(AllTrim(oTreeDtFil:GetCargo()))
	If lPermFiltr
		If AllTrim(oTreeDtFil:GetCargo()) == "FILHAB"
			lRetorno := At330IntHb(oTreeDtFil,lTecXRh)
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILREG"
			lRetorno := At330IntRg(oTreeDtFil)
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILCAR"   
			lRetorno := At330IntCg(oTreeDtFil)  
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILFUN"   
			lRetorno := At330IntFu(oTreeDtFil)
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILTUR"   
			lRetorno := At330IntTu(oTreeDtFil)
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILSEQ"   
			lRetorno := At330IntSe(oTreeDtFil)	
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILCC"   
			lRetorno := At330IntCc(oTreeDtFil)	
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILCRC"   
			lRetorno := At330IntCa(oTreeDtFil)	
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILCUR"   
			lRetorno := At330IntCu(oTreeDtFil)	
		Else
			lRetorno := .F.
			MsgAlert(STR0050,STR0051) // "Selecione uma pasta de filtro para adicionar."#"Atenção"
		EndIf
	Else
		If AllTrim(oTreeDtFil:GetCargo()) == "FILHAB"
			lRetorno := At330IntHb(oTreeDtFil,lTecXRh)
		ElseIf AllTrim(oTreeDtFil:GetCargo()) == "FILREG"
				lRetorno := At330IntRg(oTreeDtFil)
			ElseIf AllTrim(oTreeDtFil:GetCargo()) $ ("FILCAR|FILFUN|FILTUR|FILCC|FILSEQ|FILCRC|FILCUR")
	        	MsgAlert(STR0190,STR0051)	//"Usuário não tem permissao para adicionar"
	   		Else
				lRetorno := .F.
				MsgAlert(STR0050,STR0051) // "Selecione uma pasta de filtro para adicionar."#"Atenção"  
	    EndIf	
	EndIf
EndIf
	
Return( lRetorno ) 

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntHb
Interface para adicionar habilidades.

@sample 	At330IntHb(oTreeDtFil,lTecXRh)  

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 
			ExpL2	Integracao Gestao de Servicos com RH?

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntHb(oTreeDtFil,lTecXRh)

Local lRetorno  := .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0014											// Titulo da janela principal.
Local oGCodHabi	:= Nil												// Objeto MsGet habilidades.
Local cCodHabi	:= Space(6)                                       	// Codigo da habilidade.
Local oGEscala  := Nil 												// Objeto MsGet escala.
Local bEscala 	:= {||}												// Bloco de codigo para buscar a Escala.
Local oGItEsc	:= Nil 												// Objeto MsGet item da escala.
Local cItEscala := ""                                              	// Item da escala.
Local oGNivHabi	:= Nil												// Objeto MsGet.
Local nNivHabi	:= 0   												// Nivel da habilidade.
Local oBtnOk	:= Nil												// Botao OK.

Private cEscala	:= ""												// Codigo da escala.

If lTecXRh
	
	cCodHabi  := Padr("",TAMSX3("RBG_HABIL")[1])
	bEscala   := {|| cEscala := Posicione("RBG",1,xFilial("RBG")+cCodHabi,"RBG_ESCALA") }
	cItEscala := Padr("",TAMSX3("RBL_ITEM")[1])
	
	DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.35 OF oMainWnd PIXEL
	
		@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0052 SIZE 35,10 OF oDlg PIXEL  // "Habilidade:"
		@ aPosObj[1,1]+1,aPosObj[1,2]+30 MSGET oGCodHabi VAR cCodHabi PICTURE PesqPict("RBG","RBG_HABIL") F3 "RBG" SIZE TAMSX3("RBG_HABIL")[1],5 OF oDlg VALID ExistCpo("RBG",cCodHabi,1) PIXEL
		
		@ aPosObj[1,1]+2,aPosObj[1,2]+68 SAY STR0053 SIZE 35,10 OF oDlg PIXEL  // "Escala:"
		@ aPosObj[1,1]+1,aPosObj[1,2]+90 MSGET oGEscala VAR Eval(bEscala) PICTURE PesqPict("RBK","RBK_ESCALA") SIZE TAMSX3("RBK_ESCALA")[1],5 OF oDlg WHEN .F. PIXEL
		
		@ aPosObj[1,1]+2,aPosObj[1,2]+110 SAY STR0054 SIZE 45,10 OF oDlg PIXEL  // "Item da Escala:"
		@ aPosObj[1,1]+1,aPosObj[1,2]+150 MSGET oGItEsc VAR cItEscala PICTURE PesqPict("RBL","RBL_ITEM") F3 "RBL02" SIZE TAMSX3("RBL_ITEM")[1],5 OF oDlg VALID ExistCpo("RBL",cEscala+cItEscala,1) PIXEL
		
   		DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+179 TYPE 1  ACTION (IIF(At330VAddH(oTreeDtFil,cCodHabi,cEscala,cItEscala,nNivHabi,lTecXRh),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
	ACTIVATE DIALOG oDlg CENTERED
	
Else                            
	
	DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.30 OF oMainWnd PIXEL
	
		@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0052 SIZE 35,10 OF oDlg PIXEL  //"Habilidade:" 
		@ aPosObj[1,1]+1,aPosObj[1,2]+30 MSGET oGCodHabi VAR cCodHabi PICTURE "@!" F3 "A4" SIZE 15,5 OF oDlg VALID ExistCpo("SX5","A4"+cCodHabi) PIXEL
		
		DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+150 TYPE 1  ACTION (IIF(At330VAddH(oTreeDtFil,cCodHabi,cEscala,cItEscala,0,lTecXRh),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
	ACTIVATE DIALOG oDlg CENTERED
	
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntRg
Interface para adicionar regioes de atendimento.

@sample 	At330IntRg(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntRg(oTreeDtFil)

Local lRetorno	:= .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodReg	:= Nil												// Objeto MsGet habilidades.
Local cCodReg	:= Space(3)                                       	// Codigo da habilidade.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.15 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0049 SIZE 35,10 OF oDlg PIXEL  // "Região:"
	@ aPosObj[1,1]+1,aPosObj[1,2]+22 MSGET oGCodReg VAR cCodReg PICTURE "@!" F3 "A2" SIZE 3,5 OF oDlg VALID ExistCpo("SX5","A2"+cCodReg) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+58 TYPE 1  ACTION (IIF(At330VAddR(oTreeDtFil,cCodReg),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )   


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntCg
Interface para adicionar cargos do RH.

@sample 	At330IntCg(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntCg(oTreeDtFil)

Local lRetorno 	:= .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodCar	:= Nil												// Objeto MsGet habilidades.
Local cCodCar	:= Space(5)                                       	// Codigo da habilidade.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.16 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0167 SIZE 35,10 OF oDlg PIXEL  // "Cargo:"
	@ aPosObj[1,1]+1,aPosObj[1,2]+23 MSGET oGCodCar VAR cCodCar PICTURE "@!" F3 "SQ3ABO" SIZE 3,5 OF oDlg VALID ExistCpo("SQ3",cCodCar) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+66 TYPE 1  ACTION (IIF(At330VAddC(oTreeDtFil,cCodCar),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )            

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntFu
Interface para adicionar funcoes do RH.

@sample 	At330IntFu(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntFu(oTreeDtFil)

Local lRetorno 	:= .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodFun	:= Nil												// Objeto MsGet funcao.
Local cCodFun	:= Space(5)                                       	// Codigo da funcao.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.16 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0168 SIZE 35,10 OF oDlg PIXEL  // "Função:"
	@ aPosObj[1,1]+1,aPosObj[1,2]+24 MSGET oGCodFun VAR cCodFun PICTURE "@!" F3 "SRJ" SIZE 3,5 OF oDlg VALID ExistCpo("SRJ",cCodFun) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+66 TYPE 1  ACTION (IIF(At330VAddF(oTreeDtFil,cCodFun),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )     


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntTu
Interface para adicionar turnos de trabalho do RH.

@sample 	At330IntTu(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntTu(oTreeDtFil)

Local lRetorno  := .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodTur	:= Nil												// Objeto MsGet funcao.
Local cCodTur	:= Space(3)                                       	// Codigo da funcao.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.15 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0169 SIZE 35,10 OF oDlg PIXEL  // "Turno:"
	@ aPosObj[1,1]+1,aPosObj[1,2]+21 MSGET oGCodTur VAR cCodTur PICTURE "@!" F3 "SR6" SIZE 3,5 OF oDlg VALID ExistCpo("SR6",cCodTur) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+57 TYPE 1  ACTION (IIF(At330VAddT(oTreeDtFil,cCodTur),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntSe
Interface para adicionar Sequencia do turno de trabalho

@sample 	At330IntSe(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntSe(oTreeDtFil)

Local lRetorno  := .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodSeq	:= Nil												// Objeto MsGet funcao.
Local cCodSeq	:= Space(2)                                       	// Codigo da funcao.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.15 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0205 SIZE 35,10 OF oDlg PIXEL  // "Sequencia:"
	@ aPosObj[1,1]+1,aPosObj[1,2]+30 MSGET oGCodSeq VAR cCodSeq PICTURE "@!" F3 "SPJTEC" SIZE 3,5 OF oDlg PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+57 TYPE 1  ACTION (IIF(At330VAddS(oTreeDtFil,cCodSeq ),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntCc
Interface para adicionar centro de custo do RH.

@sample 	At330IntCc(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		
@since		09/05/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntCc(oTreeDtFil)
                 
Local lRetorno  := .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodCc	:= Nil												// Objeto MsGet centro de custo.
Local cCodCc	:= Space(9)                                       	// Codigo do centro de custo.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.16 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0196 SIZE 35,10 OF oDlg PIXEL  // "C.Custo:"
	@ aPosObj[1,1]+1,aPosObj[1,2]+22 MSGET oGCodCc VAR cCodCc PICTURE "@!" F3 "CTT" SIZE 3,5 OF oDlg VALID ExistCpo("CTT",cCodCc) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1]+1,aPosObj[1,2]+67 TYPE 1  ACTION (IIF(At330VAdCC(oTreeDtFil,cCodCc),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAddH
Valida e adiciona a habilidade na pasta Filtrar Atendentes por Habilidades.	

@sample 	At330VAddH(oTreeDtFil,aCodHabi,aEscala,aItEscala,aNivHabi,lTecXRh)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Habilidade.
			ExpC3	Escala.
			ExpC4	Item da Escala
			ExpN5	Nivel minino da Habilidade
			ExpL6	Integracao Gestao de Servicos com RH?
			 

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAddH(oTreeDtFil,aCodHabi,aEscala,aItEscala,aNivHabi,lTecXRh)

Local lRetorno	  := .T.			   					// Retorno da rotina.
Local cIdTree	  := ""					   				// Id utilizado para identificar o item do tree.
Local cDescHab	  := ""   								// Descricao da habilidade.
Local nPosPasta   := 0									// Posicao da pasta de habilidades na carga do Tree.
Local nPosItem    := 0									// Posicao de uma determinada habilidade.
Local cCodHabi  := "" 								// Codigo da habilidade.
Local cEscala   := ""									// Codigo da escala.
Local cItEscala := ""									// Item da escala.
Local nNivHabi  := 0
Local nX		:= 0 
Local cDescHabil := ""
Local cDescEscal := ""
Local cDescItEsc := ""
Default aCodHabi  := "" 								// Codigo da habilidade.
Default aEscala   := ""									// Codigo da escala.
Default aItEscala := ""									// Item da escala.
Default aNivHabi  := 0 									// Nivel da habilidade.

IF Valtype(aCodHabi) == "A"
	FOR nX := 1 TO Len(aCodHabi)
		If lTecXRh                
		
			If !Empty(aCodHabi[nX])
				If ExistCpo("RBG",aCodHabi[nX],1) .AND. ExistCpo("RBL",aEscala[nX]+aItEscala[nX],1)
					nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILHAB"  })
					If nPosPasta > 0
						nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == aCodHabi[nX] .AND. x[4] == aItEscala[nX]  })
						If nPosItem == 0
							If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILHAB")
								cIdTree := Soma1(StrZero(oTreeDtFil:Total(),6))
								cDescHabil := Capital(AllTrim(FDesc("RBG",aCodHabi[nX],"RBG_DESC")))
								cDescEscal := Capital(AllTrim(FDesc("RBK",aEscala[nX],"RBK_DESCRI")))
								cDescItEsc := Capital(AllTrim(FDesc("RBL",aEscala[nX]+aItEscala[nX] ,"RBL_DESCRI")))
								oTreeDtFil:AddItem(STR0045+cDescHabil+STR0046+cDescEscal+STR0047+cDescItEsc,cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#" | Escala: "#" | Item da Escala: "
								aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,aCodHabi[nX],0,aItEscala[nX]}) 
								oTreeDtFil:EndTree()
							EndIf
						Else     
							lRetorno := .F.
							MsgStop(STR0057+chr(10)+STR0058,STR0059) // "Habilidade duplicada!"#"Remova esta habilidade do filtro e adicione novamente."#"Atenção"
						EndIf
					EndIf
				Else 
					lRetorno := .F.
				EndIf
			Else 
				lRetorno := .F.                                                                               
				MsgAlert(STR0060,STR0059)	// "Habilidade não informada!"#"Atenção"
			EndIf
		Else
			If !Empty(aCodHabi[nX])
				If ExistCpo("SX5","A4"+aCodHabi[nX])
					nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILHAB"  })
					If nPosPasta > 0
						nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == aCodHabi[nX] })
						If nPosItem == 0
							If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILHAB")
								cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
								cDescHab := Posicione("SX5",1,xFilial("SX5")+"A4"+aCodHabi[nX],"X5_DESCRI")
								cDescHab := Capital(Alltrim(cDescHab))
								//oTreeDtFil:AddItem(STR0052+cDescHab+STR0162+cValToChar(0),cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#" | Nivel Mínimo: "
								oTreeDtFil:AddItem(STR0052+cDescHab,cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#"
								aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,aCodHabi[nX],0,''})
								oTreeDtFil:EndTree()
							EndIf
						Else 
							lRetorno := .F.
							MsgStop(STR0057+chr(10)+STR0058,STR0059) // "Habilidade duplicada!"#"Remova esta habilidade do filtro e adicione novamente."#"Atenção"
						EndIf
					EndIf
				Else
					lRetorno := .F.
				EndIf
			Else 
				lRetorno := .F.
				MsgAlert(STR0060,STR0059)	// "Habilidade não informada!"#"Atenção"
			EndIf
		EndIf
	Next Nx
ELSE
	cCodHabi	:= aCodHabi
	cEscala 	:= aEscala
	cItEscala	:= aItEscala
	nNivHabi	:= aNivHabi
	
	If lTecXRh                
	
		If !Empty(cCodHabi)
			If ExistCpo("RBG",cCodHabi,1) .AND. ExistCpo("RBL",cEscala+cItEscala,1)
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILHAB"  })
				If nPosPasta > 0
					nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodHabi .AND. x[4] == cItEscala  })
					If nPosItem == 0
						If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILHAB")
							cIdTree := Soma1(StrZero(oTreeDtFil:Total(),6))
							cDescHabil := Capital(AllTrim(FDesc("RBG",cCodHabi,"RBG_DESC")))
							cDescEscal := Capital(AllTrim(FDesc("RBK",cEscala,"RBK_DESCRI")))
							cDescItEsc := Capital(AllTrim(FDesc("RBL",cEscala+cItEscala ,"RBL_DESCRI")))
							oTreeDtFil:AddItem(STR0045+cDescHabil+STR0046+cDescEscal+STR0047+cDescItEsc,cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#" | Escala: "#" | Item da Escala: "
							aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodHabi,nNivHabi,cItEscala}) 
							oTreeDtFil:EndTree()
						EndIf
					Else     
						lRetorno := .F.
						MsgStop(STR0057+chr(10)+STR0058,STR0059) // "Habilidade duplicada!"#"Remova esta habilidade do filtro e adicione novamente."#"Atenção"
					EndIf
				EndIf
			Else 
				lRetorno := .F.
			EndIf
		Else 
			lRetorno := .F.                                                                               
			MsgAlert(STR0060,STR0059)	// "Habilidade não informada!"#"Atenção"
		EndIf
	Else
		If !Empty(cCodHabi)
			If ExistCpo("SX5","A4"+cCodHabi)
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILHAB"  })
				If nPosPasta > 0
					nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodHabi })
					If nPosItem == 0
						If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILHAB")
							cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
							cDescHab := Posicione("SX5",1,xFilial("SX5")+"A4"+cCodHabi,"X5_DESCRI")
							cDescHab := Capital(Alltrim(cDescHab))
							oTreeDtFil:AddItem(STR0052+cDescHab+STR0162+cValToChar(nNivHabi),cIdTree,"PMSTASK4",,,,2) // "Habilidade: "#" | Nivel Mínimo: "
							aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodHabi,nNivHabi,''})
							oTreeDtFil:EndTree()
						EndIf
					Else 
						lRetorno := .F.
						MsgStop(STR0057+chr(10)+STR0058,STR0059) // "Habilidade duplicada!"#"Remova esta habilidade do filtro e adicione novamente."#"Atenção"
					EndIf
				EndIf
			Else
				lRetorno := .F.
			EndIf
		Else 
			lRetorno := .F.
			MsgAlert(STR0060,STR0059)	// "Habilidade não informada!"#"Atenção"
		EndIf
	EndIf
ENDIF
Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAddR
Valida e adiciona a regiao na pasta Filtrar Atendentes por Regiao de Atendimento.

@sample 	At330VAddR(oTreeDtFil,cCodReg)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Regiao de Atendimento.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAddR(oTreeDtFil,cCodReg)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescReg	  := ""     		// Descricao da regiao.
Local nPosPasta   := 0				// Posicao da pasta de regioes de atendimento na carga do Tree.
Local nPosItem    := 0				// Posicao de uma determinada regiao de atendimento.

Default cCodReg  := "" 				// Codigo da regiao.


If !Empty(cCodReg)
	If ExistCpo("SX5","A2"+cCodReg)
		nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILREG"  })
		If nPosPasta > 0
			nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodReg })
			If nPosItem == 0
				If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILREG")
					cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
					cDescReg := Posicione("SX5",1,xFilial("SX5")+"A2"+cCodReg,"X5_DESCRI")
					cDescReg := Capital(Alltrim(cDescReg))
					oTreeDtFil:AddItem(STR0049+cDescReg,cIdTree,"PMSTASK4",,,,2) // "Região: "
					aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodReg})
					oTreeDtFil:EndTree()
				EndIf
			Else
				lRetorno := .F.
				MsgStop(STR0062+chr(10)+STR0063,STR0061)  // "Região duplicada!"#"Remova esta região do filtro e adicione novamente."#"Atenção"
			EndIf
		EndIf
	Else
		lRetorno := .F.
	EndIf

EndIf


Return( lRetorno )  

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAddC
Valida e adiciona o cargo na pasta Filtrar Atendentes por Cargo.

@sample 	At330VAddR(oTreeDtFil,cCodCar)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Cargo.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAddC(oTreeDtFil,cCodCar)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescCar	  := ""     		// Descricao da regiao.
Local nPosPasta   := 0				// Posicao da pasta de cargos na carga do Tree.
Local nPosItem    := 0				// Posicao de um determinado cargo.

Default cCodCar  := "" 				// Codigo da regiao.


If !Empty(cCodCar)
	If ExistCpo("SQ3",cCodCar)
		nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCAR"  })
		If nPosPasta > 0
			nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodCar })
			If nPosItem == 0
				If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILCAR")
					cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
					cDescCar := FDESC("SQ3",cCodCar,"Q3_DESCSUM",,xFilial("SQ3"))                               
					cDescCar := Capital(Alltrim(cDescCar))
					oTreeDtFil:AddItem(STR0173+cDescCar,cIdTree,"PMSTASK4",,,,2) // "Cargo: "
					aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodCar})
					oTreeDtFil:EndTree()
				EndIf
			Else
				lRetorno := .F.
				MsgStop(STR0170+chr(10)+STR0171,STR0172)  // "Cargo duplicado!"#"Remova este cargo do filtro e adicione novamente."#"Atenção"
			EndIf
		EndIf
	Else
		lRetorno := .F.
	EndIf
Else
	lRetorno := .F.
EndIf


Return( lRetorno )   

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAddS
Valida e adiciona o sequencia do turno de trabalho na pasta Filtrar Atendentes por Sequencia do Turno de Trabalho.

@sample 	At330VAddS(oTreeDtFil,cCodSeq)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Sequencia do Turno de Trabalho.

@return		ExpL 	Verdadeiro / Falso

@since		22/08/2014
@version	P11.9
/*/
//------------------------------------------------------------------------------
Function At330VAddS(oTreeDtFil,cCodSeq)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescTur	  := ""     		// Descricao do turno de trabalho.
Local nPosPasta   := 0				// Posicao da pasta de funcoes na carga do Tree.
Local nPosItem    := 0				// Posicao de uma determinada funcao.

Default cCodSeq  := "" 				// Codigo do turno de trabalho.

If !Empty(cCodSeq)
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILSEQ"  })
	If nPosPasta > 0
		nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodSeq })
		If nPosItem == 0
			If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILSEQ")
				cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))                             
				cDescTur := Capital(Alltrim(cCodSeq))
				oTreeDtFil:AddItem(STR0205+cDescTur,cIdTree,"PMSTASK4",,,,2) // "Sequencia: "
				aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodSeq})
				oTreeDtFil:EndTree()
			EndIf
		Else
			lRetorno := .F.
			MsgStop(STR0206+chr(10)+STR0207,STR0172)  // "Sequência duplicada!"#"Remova esta sequência do filtro e adicione novamente."#"Atenção"
		EndIf
	EndIf
EndIf

Return( lRetorno )
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAddF
Valida e adiciona a funcao na pasta Filtrar Atendentes por Funcao.

@sample 	At330VAddF(oTreeDtFil,cCodFun)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Funcao.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAddF(oTreeDtFil,cCodFun)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescFun	  := ""     		// Descricao da funcao.
Local nPosPasta   := 0				// Posicao da pasta de funcoes na carga do Tree.
Local nPosItem    := 0				// Posicao de uma determinada funcao.

Default cCodFun  := "" 				// Codigo da funcao.


If !Empty(cCodFun)
	If ExistCpo("SRJ",cCodFun)
		nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILFUN"  })
		If nPosPasta > 0
			nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodFun })
			If nPosItem == 0
				If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILFUN")
					cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
					cDescFun := FDESC("SRJ",cCodFun,"RJ_DESC",,xFilial("SRJ"))                                
					cDescFun := Capital(Alltrim(cDescFun))
					oTreeDtFil:AddItem(STR0175+cDescFun,cIdTree,"PMSTASK4",,,,2) // "Função: "
					aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodFun})
					oTreeDtFil:EndTree()
				EndIf
			Else  
				lRetorno := .F.
				MsgStop(STR0176+chr(10)+STR0177,STR0172)  // "Função duplicada!"#"Remova esta função do filtro e adicione novamente."#"Atenção"
			EndIf
		EndIf
	Else
		lRetorno := .F.
	EndIf
Else
	lRetorno := .F.
	MsgAlert(STR0178,STR0172)  // "Função não informada!"#"Atenção"
EndIf

Return( lRetorno )     

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAddT
Valida e adiciona o turno de trabalho na pasta Filtrar Atendentes por Turno de Trabalho.

@sample 	At330VAddT(oTreeDtFil,cCodTur)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Turno de Trabalho.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAddT(oTreeDtFil,cCodTur)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescTur	  := ""     		// Descricao do turno de trabalho.
Local nPosPasta   := 0				// Posicao da pasta de funcoes na carga do Tree.
Local nPosItem    := 0				// Posicao de uma determinada funcao.

Default cCodTur  := "" 				// Codigo do turno de trabalho.


If !Empty(cCodTur)
	If ExistCpo("SR6",cCodTur)
		nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILTUR"  })
		If nPosPasta > 0
			nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodTur })
			If nPosItem == 0
				If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILTUR")
					cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
					cDescTur := FDESC("SR6",cCodTur,"R6_DESC",,xFilial("SR6"))                               
					cDescTur := Capital(Alltrim(cDescTur))
					oTreeDtFil:AddItem(STR0179+cDescTur,cIdTree,"PMSTASK4",,,,2) // "Turno: "
					aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodTur})
					oTreeDtFil:EndTree()
				EndIf
			Else
				lRetorno := .F.
				MsgStop(STR0180+chr(10)+STR0181,STR0172)  // "Turno duplicado!"#"Remova este turno do filtro e adicione novamente."#"Atenção"
			EndIf
		EndIf
	Else
		lRetorno := .F.
	EndIf
Else 
	lRetorno := .F.
	MsgAlert(STR0182,STR0172)  // "Turno não informado!"#"Atenção"
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAdCC
Valida e adiciona o centro de custo na pasta Filtrar Atendentes por Centro de custo.

@sample 	At330VAdCC(oTreeDtFil,cCodCc)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Cargo.

@return		ExpL 	Verdadeiro / Falso

@author		
@since		09/05/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAdCC(oTreeDtFil,cCodCc)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescCc	  := ""     		// Descricao do centro de custo.
Local nPosPasta   := 0				// Posicao da pasta de cargos na carga do Tree.
Local nPosItem    := 0				// Posicao de um determinado cargo.

Default cCodCc  := "" 				// Codigo da regiao.

If !Empty(cCodCc)
	If ExistCpo("CTT",cCodCc)
		nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCC"  })
		If nPosPasta > 0
			nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodCc })
			If nPosItem == 0
				If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILCC")
					cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
					cDescCc := FDESC("CTT",cCodCc,"CTT_CUSTO",,xFilial("CTT"))                               
					cDescCc := Capital(Alltrim(cDescCc))
					oTreeDtFil:AddItem(STR0196+cDescCc,cIdTree,"PMSTASK4",,,,2) // "C.Custo:"
					aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodCc})
					oTreeDtFil:EndTree()
				EndIf
			Else
				lRetorno := .F.
				MsgStop(STR0191+chr(10)+STR0192,STR0172)  // "Centro de Custo duplicado"#"Remova este centro de custo do filtro e adicione novamente."#"Atenção"
			EndIf
		EndIf
	Else
		lRetorno := .F.
		MsgAlert(STR0193,STR0172)  // "Centro de Custo não informado!"#"Atenção"
	EndIf

EndIf

Return( lRetorno )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAdRg
Valida e adiciona o centro de custo na pasta Filtrar Atendentes por Centro de custo.

@sample 	At330VAdCC(oTreeDtFil,cCodCc)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Cargo.

@return		ExpL 	Verdadeiro / Falso

@author		
@since		09/05/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAdRg(oTreeDtFil,cCodLoc)

Local lRetorno  := .T.			// Retorno da rotina.
Local cCodReg	  := ""     		// Codigo da regiao do local de atendimento.

Default cCodLoc  := "" 				// Codigo da regiao.

If !Empty(cCodLoc)
	If ExistCpo("ABS",cCodLoc)
		cCodReg := Posicione("ABS",1,xFilial("ABS")+cCodLoc,"ABS->ABS_REGIAO")
		At330VAddR(oTreeDtFil,cCodReg)
	Else
		lRetorno := .F.
	EndIf
EndIf

Return( lRetorno )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330RemIt
Remove item do filtro.

@sample 	At330RemIt(oTreeDtFil,lTecXRh)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 
			ExpL2	Integracao Gestao de Servicos com RH?

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330RemIt(oTreeDtFil,lTecXRh)

Local lRetorno		:= .T.								// Retorno da rotina.
Local nPos		:= 0        						// Posicao do elemento.
Local nTam		:= 0      							// Tamanho do array.
Local nPosItem  	:= 0								// Posicao de uma determinada habilidade.
Local nX		:= 0								// Incremento utilizado no laco for.
Local lPermFiltr	:= SuperGetMv("MV_TECPRMF",,.T.)    // Usuario tem permissão para manipular filtro

Do Case
	Case oTreeDtFil:Nivel() == 1 .OR. oTreeDtFil:Nivel() == 2
		lRetorno := .F.
		MsgStop(STR0065,STR0061) // "Não é possivel remover esta pasta."#"Atenção"
	Case ( oTreeDtFil:Nivel() == 3 .AND. AllTrim(oTreeDtFil:GetCargo()) $ "HabAtd|RegAtd" )
		lRetorno := .F.
		MsgStop(STR0066,STR0061)  // "Não é possivel remover este item."#"Atenção"
	OtherWise
		If lPermFiltr
			For nX := 1 To Len(oTreeDtFil:Cargo)
				nPosItem := aScanX(oTreeDtFil:Cargo[nX],{|x,y| y > 1 .AND. x[1] == AllTrim(oTreeDtFil:GetCargo()) })
				If nPosItem > 0
					If At330FilAce(oTreeDtFil:Cargo[nX][1])
						ADel(oTreeDtFil:Cargo[nX],nPosItem) 
						nTam := Len(oTreeDtFil:Cargo[nX])-1
						ASize(oTreeDtFil:Cargo[nX],nTam)
						oTreeDtFil:DelItem()
					EndIf					
					Exit
				EndIf
			Next nX
		Else	
			MsgAlert(STR0194,STR0051) 	//"Usuário não tem permissao para remover item"
		EndIf
EndCase


Return( lRetorno )
  
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ClrPt 
Limpa a pasta selecionada do filtro.

@sample 	At330ClrPt(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330ClrPt(oTreeDtFil)

Local lRetorno 		:= .T.		// Retorno da rotina.
Local nPosPasta 	:= 0		// Posicao dos itens habilidades na carga do Tree.  
Local lPermFiltr	:= SuperGetMv("MV_TECPRMF",,.T.)	// Usuario tem permissão para manipular filtro

If At330FilAce(Alltrim(oTreeDtFil:GetCargo()))

	Do Case
		
		Case oTreeDtFil:Nivel() == 2 .AND. Alltrim(oTreeDtFil:GetCargo()) $ "FILHAB"
			oTreeDtFil:DelItem()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array Habilidades ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILHAB"  })
			oTreeDtFil:Cargo[nPosPasta] := {"FILHAB"}
			
			oTreeDtFil:TreeSeek("FILTRAR")
			oTreeDtFil:AddItem(STR0067,"FILHAB","FOLDER5","FOLDER6",,,2) // "Habilidades"
			oTreeDtFil:EndTree()
		Case oTreeDtFil:Nivel() == 2 .AND. Alltrim(oTreeDtFil:GetCargo()) $ "FILREG"
			oTreeDtFil:DelItem()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array Regiao de Atendimento ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILREG"  })
			oTreeDtFil:Cargo[nPosPasta] := {"FILREG"}
			
			oTreeDtFil:TreeSeek("FILTRAR")
			oTreeDtFil:AddItem(STR0068,"FILREG","FOLDER5","FOLDER6",,,2) // "Região de Atendimento"
			oTreeDtFil:EndTree()
		Case oTreeDtFil:Nivel() == 2 .AND. Alltrim(oTreeDtFil:GetCargo()) $ "FILCAR"
			If lPermFiltr
				oTreeDtFil:DelItem()
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Limpa o array Cargo ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCAR"  })
				oTreeDtFil:Cargo[nPosPasta] := {"FILCAR"}
				
				oTreeDtFil:TreeSeek("FILTRAR")
				oTreeDtFil:AddItem(STR0164,"FILCAR","FOLDER5","FOLDER6",,,2) // "Cargo"
				oTreeDtFil:EndTree()
			Else
				MsgAlert(STR0195,STR0051) //"Usuário não tem permissao para limpar pasta"#"Atenção"
			EndIf	
		Case oTreeDtFil:Nivel() == 2 .AND. Alltrim(oTreeDtFil:GetCargo()) $ "FILFUN"
			If lPermFiltr
				oTreeDtFil:DelItem()
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Limpa o array Funcao ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILFUN"  })
				oTreeDtFil:Cargo[nPosPasta] := {"FILFUN"}
				
				oTreeDtFil:TreeSeek("FILTRAR")
				oTreeDtFil:AddItem(STR0165,"FILFUN","FOLDER5","FOLDER6",,,2) // "Função"
				oTreeDtFil:EndTree()
			Else
				MsgAlert(STR0195,STR0051) //"Usuário não tem permissao para limpar pasta"#"Atenção"
			EndIf	
		Case oTreeDtFil:Nivel() == 2 .AND. Alltrim(oTreeDtFil:GetCargo()) $ "FILTUR"
			If lPermFiltr
				oTreeDtFil:DelItem()
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Limpa o array Turno de Trabalho ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILTUR"  })
				oTreeDtFil:Cargo[nPosPasta] := {"FILTUR"}
				
				oTreeDtFil:TreeSeek("FILTRAR")
				oTreeDtFil:AddItem(STR0166,"FILTUR","FOLDER5","FOLDER6",,,2) // "Turno de Trabalho"
				oTreeDtFil:EndTree()
			Else
				MsgAlert(STR0195,STR0051) //"Usuário não tem permissao para limpar pasta"#"Atenção" 
			EndIf		
		Case oTreeDtFil:Nivel() == 2 .AND. Alltrim(oTreeDtFil:GetCargo()) $ "FILCC"
			If lPermFiltr
				oTreeDtFil:DelItem()
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Limpa o array centro de custo ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
			    nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCC" })
			    oTreeDtFil:Cargo[nPosPasta] := {"FILCC"}
			    
			    oTreeDtFil:TreeSeek("FILTRAR")
				oTreeDtFil:AddItem(STR0189,"FILCC","FOLDER5","FOLDER6",,,2)  // "Centro de Custo"	
				oTreeDtFil:EndTree()
			Else
				MsgAlert(STR0195,STR0051) //"Usuário não tem permissao para limpar pasta"#"Atenção"
			EndIf		
		OtherWise
			lRetorno := .F.
			MsgAlert(STR0069,STR0061)  // "Selecione uma pasta de filtro para limpar."#"Atenção"
	EndCase

EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ClrFl
Limpa todas as pastas do filtro.

@sample 	At330ClrFl(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 
			ExpL2	Integracao Gestao de Servicos com RH? 
			ExpL3	Rotina de Substituicao de Atendentes?

@return		ExpL	Verdadeiro.

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330ClrFl(oTreeDtFil,lTecXRh,lSubst)

Local lRetorno := .T.	// Retorno da rotina.
Local nPosPasta := 0	// Posicao dos itens habilidades na carga do Tree.

Default lSubst := .F.	// Rotina de Substituicao de Atendentes?

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta habilidades da pasta de filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILHAB",.F.)
		If oTreeDtFil:TreeSeek("FILHAB") 
			oTreeDtFil:DelItem()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array habilidades ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILHAB"  })
			oTreeDtFil:Cargo[nPosPasta] := {"FILHAB"}
		EndIf
	EndIf		
EndIf
 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta regiao de atendimento da pasta de filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILREG",.F.)
		If oTreeDtFil:TreeSeek("FILREG")
	   		oTreeDtFil:DelItem()
	   		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array regiao de atendimento ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILREG"  })
			oTreeDtFil:Cargo[nPosPasta] := {"FILREG"}
	 	EndIf
	 EndIf
EndIf
                                                 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta cargo da pasta de filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR") .AND. lTecXRh
	If At330FilAce("FILCAR",.F.)		
		If oTreeDtFil:TreeSeek("FILCAR")
	   		oTreeDtFil:DelItem()
	   		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array cargo ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCAR"  })
			oTreeDtFil:Cargo[nPosPasta] := {"FILCAR"}
	 	EndIf
	EndIf	 	
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta funcao da pasta de filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILFUN",.F.)
		If At330FilAce("FILFUN",.F.)
			If oTreeDtFil:TreeSeek("FILFUN")
		   		oTreeDtFil:DelItem()
		   		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Limpa o array funcao ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILFUN"  })
				oTreeDtFil:Cargo[nPosPasta] := {"FILFUN"}
		 	EndIf
	 	EndIf
	EndIf	 	
EndIf  

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta turno de trabalho da pasta de filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILTUR",.F.)
		If oTreeDtFil:TreeSeek("FILTUR")
	   		oTreeDtFil:DelItem()
	   		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array turno de trabalho ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILTUR"  })
			oTreeDtFil:Cargo[nPosPasta] := {"FILTUR"}
	 	EndIf
	EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta sequencia do turno da pasta de filtro. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR")
	If oTreeDtFil:TreeSeek("FILSEQ")
   		oTreeDtFil:DelItem()
   		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Limpa o array sequencia do turno ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILSEQ"  })
		oTreeDtFil:Cargo[nPosPasta] := {"FILSEQ"}
 	EndIf
EndIf

If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILCC",.F.)
		If oTreeDtFil:TreeSeek("FILCC")
			oTreeDtFil:DelItem()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array centro de custo ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCC" })
			oTreeDtFil:Cargo[nPosPasta] := {"FILCC"}
		EndIf
	EndIf		
EndIf

If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILCRC",.F.)
		If oTreeDtFil:TreeSeek("FILCRC")
			oTreeDtFil:DelItem()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array caracteristica  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCRC" })
			oTreeDtFil:Cargo[nPosPasta] := {"FILCRC"}
		EndIf
	EndIf		
EndIf

If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILCUR",.F.)
		If oTreeDtFil:TreeSeek("FILCUR")
			oTreeDtFil:DelItem()
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Limpa o array curso           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCUR" })
			oTreeDtFil:Cargo[nPosPasta] := {"FILCUR"}
		EndIf
	EndIf		
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Adiciona as pastas no Tree ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If oTreeDtFil:TreeSeek("FILTRAR")
	If At330FilAce("FILHAB",.F.)
		oTreeDtFil:AddItem(STR0011,"FILHAB","FOLDER5","FOLDER6",,,2)          			// "Habilidades" 
		aAdd(oTreeDtFil:Cargo,{"FILHAB"})
	EndIf
	If At330FilAce("FILCRC",.F.)
		oTreeDtFil:AddItem(STR0221,"FILCRC","FOLDER5","FOLDER6",,,2)          			// "Caractersística" 
		aAdd(oTreeDtFil:Cargo,{"FILCRC"})
	EndIf
	If At330FilAce("FILREG",.F.)	  
		oTreeDtFil:AddItem(STR0012,"FILREG","FOLDER5","FOLDER6",,,2)   				// "Região de Atendimento"
		aAdd(oTreeDtFil:Cargo,{"FILREG"})
	EndIf		
	If At330FilAce("FILCUR",.F.)	  
		oTreeDtFil:AddItem(STR0222,"FILCUR","FOLDER5","FOLDER6",,,2)   				// "Cursos"
		aAdd(oTreeDtFil:Cargo,{"FILCUR"})
	EndIf		
	If lTecxRh .And. At330FilAce("FILCAR",.F.)
		oTreeDtFil:AddItem(STR0164,"FILCAR","FOLDER5","FOLDER6",,,2)      		// "Cargo"   
		aAdd(oTreeDtFil:Cargo,{"FILCAR"})
	EndIf
	If At330FilAce("FILFUN",.F.)	 
		oTreeDtFil:AddItem(STR0165,"FILFUN","FOLDER5","FOLDER6",,,2)   			// "Função"	  
		aAdd(oTreeDtFil:Cargo,{"FILFUN"})
	EndIf
	If At330FilAce("FILTUR",.F.)
		oTreeDtFil:AddItem(STR0166,"FILTUR","FOLDER5","FOLDER6",,,2)   	   		// "Turno de Trabalho"	
		aAdd(oTreeDtFil:Cargo,{"FILTUR"})
	EndIf	
	aAdd(oTreeDtFil:Cargo,{"FILSEQ"})
		oTreeDtFil:AddItem(STR0112,"FILSEQ","FOLDER5","FOLDER6",,,2)   	   		// "Sequencia Turno de Trabalho"	
		aAdd(oTreeDtFil:Cargo,{"FILSEQ"}) 
	EndIf	  
	If At330FilAce("FILCC",.F.)	  	
		oTreeDtFil:AddItem(STR0189,"FILCC","FOLDER5","FOLDER6",,,2)  			// "Centro de Custo"	
		aAdd(oTreeDtFil:Cargo,{"FILCC"})
	EndIf	  
EndIf

Return( lRetorno )   


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330TOS 
Tree com as Ordem de Servicos para alocacao.

@sample 	At330TOS(oTreeOS)

@param		ExpO1	Objeto DBTree Ordem de Servico.

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330TOS(oTreeOS)

Local lRetorno	 := .T.						// Retorno da rotina.
Local aArea 	 := GetArea()     			// Guarda area atual.
Local aAreaAB6	 := AB6->(GetArea())		// Guarda area AB6. 
Local aAreaAB7	 := AB7->(GetArea())		// Guarda area AB7.
Local aAreaAA3	 := AA3->(GetArea())		// Guarda area AA3.  
Local cIdTree	 := StrZero(0,6)			// Id utilizado para identificar o item do tree.
Local aCargo	 := {}   					// Array utilizado para carga das O/S no objeto DBTree.
Local cItemAB7	 := ""						// Item da O/S que sera utilizado para alocar o atendente no contrato.
Local cCodPro	 := ""						// Base de atendimento.
Local cIdUnico	 := ""						// Id unico da base de atendimento.
Local cTpContrt	 := "1"      				// Contrato de Manutencao.
Local cOS		 := ""                     	// Codigo da Ordem de Servico.
Local cUltIdTree := StrZero(0,6)			// Id do tree da ultima O/S adicionada no tree.
Local cBaseAtd	 := ""						// Base de atendimento

DbSelectArea("AB6")
DbSetOrder(6)

DbSelectArea("AB7")      
DbSetOrder(1)

DbSelectArea("AA3")
DbSetOrder(2)

If AB6->(DbSeek(xFilial("AB6")+cTpContrt+AAH->AAH_CONTRT))
	
	While ( AB6->(!Eof()) .AND. AB6->AB6_FILIAL == xFilial("AB6") .AND. AB6->AB6_TPCONT == cTpContrt .AND. AB6->AB6_CONTRT == AAH->AAH_CONTRT )
		
		If AB6->AB6_STATUS == "A"
			
			If AB7->(DbSeek(xFilial("AB7")+AB6->AB6_NUMOS))
				
				lCriaNivel := .T.
				
				While ( AB7->(!Eof()) .AND. AB7->AB7_FILIAL == xFilial("AB7") .AND. AB7->AB7_NUMOS == AB6->AB6_NUMOS )
					
					If AB7->AB7_TIPO $ "1|3"
						
						If AA3->( DbSeek(xFilial("AA3")+AAH->AAH_CONTRT+AB6->AB6_CODCLI+AB6->AB6_LOJA+AB7->AB7_CODPRO+AB7->AB7_NUMSER))
							
							If lCriaNivel
								cOS 	 	:= AB6->AB6_NUMOS
								cIdTree 	:= Soma1(cIdTree)
								cUltIdTree 	:= cIdTree
								lCriaNivel	:= .F.
								oTreeOS:AddItem(At330Title("AB6_NUMOS")+" - "+AB6->AB6_NUMOS+Space(100),cIdTree,"BR_VERDE",,,,1)
								aAdd(aCargo,{cIdTree,"OS",cOS,"",""})
							EndIf
							
							If oTreeOS:TreeSeek(cUltIdTree)
								cIdTree  := Soma1(cIdTree)
								cItemAB7 := AllTrim(AB7->AB7_ITEM)
								cCodPro	 := AllTrim(AA3->AA3_CODPRO)
								cIdUnico := AllTrim(AA3->AA3_NUMSER)
								cDesOcor := Capital(AllTrim(Posicione("AAG",1,xFilial("AAG")+AB7->AB7_CODPRB,"AAG_DESCRI")))
								cString	 := At330Title("AB7_ITEM")+": "+cItemAB7+" | "+At330Title("AB7_CODPRO")+": "+cCodPro+" | "+At330Title("AB7_NUMSER")+": "+cIdUnico+" | "+At330Title("AB7_CODPRB")+": "+cDesOcor
								cBaseAtd := AA3->AA3_CONTRT+AA3->AA3_CODCLI+AA3->AA3_LOJA+AA3->AA3_CODPRO+AA3->AA3_NUMSER
								cItemAB7 := AB7->AB7_NUMOS+AB7->AB7_ITEM
								oTreeOS:AddItem(cString,cIdTree,IIF(AB7->AB7_TIPO == "1","PMSTASK4","PMSTASK2"),,,,2)
								aAdd(aCargo,{cIdTree,"ITEM",cOS,cBaseAtd,cItemAB7})
							Endif
							
						EndIf
					EndIf
					AB7->(DbSkip())
				End
				
			EndIf
		EndIf
		
		AB6->(DbSkip())
	End
	
EndIf
 
If Len(aCargo) > 0
	oTreeOS:Cargo := aCargo
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Indica o termino da contrução da Tree. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTreeOS:EndTree()
Else
	oTreeOS:Cargo := {}	
EndIf	

RestArea(aArea)   
RestArea(aAreaAB6)
RestArea(aAreaAB7)
RestArea(aAreaAA3)

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VisOS 
Visualizacao da ordem de servico pelo Tree de O/S.

@sample 	At330VisOS(oTreeOS)

@param		ExpO1	Objeto DBTree Ordem de Servico.

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VisOS(oTreeOS)

Local lRetorno  := .T. 							// Retorno da rotina.
Local nReg	 	:= 0  		   					// Numero do registro.
Local cAlias	:= "AB6"	   					// Tabela AB6.
Local nPos 		:= 0                            // Posicao da Ordem de Servico no Tree.

Private cCadastro	:= STR0070 					// "Ordem de Serviço"
Private aRotina		:= {}		  				// Variavel com a opcao visualizar.
Private Inclui		:= .F.						// Caso for inclusao.
Private Altera		:= .F.						// Caso for alteracao.

nPos := aScan(oTreeOS:Cargo,{|x| x[1] == AllTrim(oTreeOS:GetCargo())})

If nPos > 0
	
	DbSelectArea("AB6")
	DbSetOrder(1)       
	
	If DbSeek(xFilial("AB6")+oTreeOS:Cargo[nPos][3])
		nReg := AB6->(Recno())
		aRotina := {{STR0071,"AT450Visua",0,2}} 	// "Visualizar"
		AT450Visua(cAlias,nReg,1)
	EndIf
	
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VBase 
Visualizacao da base de atendimento pelo Tree de O/S.

@sample 	At330VBase(oTreeOS)

@param		ExpO1	Objeto DBTree Ordem de Servico.

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VBase(oTreeOS)

Local lRetorno 		 := .T. 						// Retorno da rotina.
Local nReg			 := 0  							// Numero do registro.
Local cAlias		 := "AA3"	   					// Tabela AA3.
Local nPos 	 		 := 0                           // Posicao da Ordem de Servico no Tree.

Private cCadastro	:= STR0072 						// "Ordem de Serviço"
Private aRotina		:= {}							// Variavel com a opcao visualizar.
Private Inclui		:= .F.		   					// Caso for inclusao.
Private Altera		:= .F.							// Caso for alteracao.

nPos := aScan(oTreeOS:Cargo,{|x| x[1] == AllTrim(oTreeOS:GetCargo())})

If nPos > 0 .AND. !Empty(oTreeOS:Cargo[nPos][4])
	
	DbSelectArea("AA3")
	DbSetOrder(2)                            
	
	If DbSeek(xFilial("AA3")+oTreeOS:Cargo[nPos][4])
		nReg := AA3->(Recno())
		aRotina := {{STR0071,"At040Visua",0,2}} 	// "Visualizar"
		At040Visua(cAlias,nReg,1)
	EndIf
Else
	MsgAlert(STR0073,STR0059) // Selecione um item da O/S para visualizar a base de atendimento."#"Atenção"
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330LtOs 
Legenda do Tree de O/S.

@sample 	At330LtOs()

@param		Nenhum

@return		Nenhum

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330LtOs()

Local oLegenda  :=  FWLegend():New() 		// Objeto FwLegend.
                                                  	
oLegenda:Add("","BR_VERDE",STR0074)       	// "O/S - Aberta" 					
oLegenda:Add("","PMSTASK4",STR0075)  		// "Situação do Item - O/S"
oLegenda:Add("","PMSTASK2",STR0076)  		// "Situação do Item - Em Atendimento"

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330BrwA1 
Browse atendentes do Gestao de Servicos.

@sample 	At330BrwA1(oDlgAllAtd,oMrkAllAtd,aMrkAllAtd,lTecXRh)

@param		ExpO1	Objeto Panel atendentes.
			ExpO2 	Objeto FwMarkBrowse atendentes.
			ExpA3 	Array com as informacoes para popular o browse.
			ExpL4	Integracao Gestao de Servicos com RH?
			ExpA5	Data Inicial de alocação
			ExpA6	Data Final de alocação
@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330BrwA1(oDlgAllAtd,oMrkAllAtd,aMrkAllAtd,lTecXRh, dAlocDe, dAlocAte, oTreeDtFil, oLbxCfgAlo, cItCbxSel, aConfAloc,nPosPerFim,oMrkAtdAlo )

Local lRetorno  := .T. 					// Retorno da rotina.
Local aSeek		:= {}					// Array com a chaves para busca.
Local aIndex	:= {}					// Array com indice.
Local cAliasTmp	:= aMrkAllAtd[1]		// Alias temporario.
Local cAliasIdx	:= aMrkAllAtd[2] 		// Index temporario.
Local aColumns	:= aMrkAllAtd[3]		// Colunas que serao exibidas no browse.


If !lTecXRh
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Remove os campos TMP_CARGO / TMP_SITFOL / TMP_DESC . ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	ADel(aColumns,8)
	ADel(aColumns,11)
	ADel(aColumns,12)
	ASize(aColumns,Len(aColumns)-3)
EndIf

DbSelectArea(cAliasTmp)
(cAliasTmp)->( DbGoTop() )

aAdd(aSeek,{TxDadosCpo("AA1_CODTEC")[1],{{"","C",TamSX3("AA1_CODTEC")[1],TamSX3("AA1_CODTEC")[2],;
			TxDadosCpo("AA1_CODTEC")[1],PesqPict("AA1","AA1_CODTEC")}} } )

oMrkAllAtd := FWMarkBrowse():New()
oMrkAllAtd:SetFieldMark("TMP_OK")
oMrkAllAtd:SetOwner(oDlgAllAtd)
oMrkAllAtd:oBrowse:SetDataQuery(.F.)
oMrkAllAtd:oBrowse:SetDataTable(.T.)
oMrkAllAtd:SetAlias(cAliasTmp)
oMrkAllAtd:oBrowse:SetSeek(,aSeek)
oMrkAllAtd:SetCustomMarkRec({|| At330CMkB1(oMrkAllAtd,aConfAloc) })
oMrkAllAtd:SetAllMark({|| At330AMkB1(oMrkAllAtd,aConfAloc) })
oMrkAllAtd:SetTemporary()
oMrkAllAtd:SetDescription("")
oMrkAllAtd:SetMenuDef("")
oMrkAllAtd:AddButton(STR0077,{|| At330VsAtd((oMrkAllAtd:Alias())->TMP_CODTEC)},,,,.F.,1) 	// "Visualizar Atendente"
oMrkAllAtd:AddButton(STR0078,{|| At330CAloc((oMrkAllAtd:Alias())->TMP_CODTEC,oMrkAtdAlo,aConfAloc,oLbxCfgAlo,oTreeDtFil,nPosPerFim)},,,,.F.,1) 	// "Controle de Alocação"
oMrkAllAtd:AddButton(STR0079,{|| At330LMkA1() },,,,.F.,2)                      			// "Legenda"
oMrkAllAtd:AddButton(STR0200,{||At330DefEq(dAlocDe,dAlocAte,oMrkAllAtd,oTreeDtFil,;
														    oLbxCfgAlo,cItCbxSel,lTecXRh,aConfAloc,aMrkAllAtd) },,,,.F.,1) 	// "Definir Equipe"

If lTecXRh
	oMrkAllAtd:AddButton(STR0198,{|| At570Detal((oMrkAllAtd:Alias())->TMP_CODTEC, {{dAlocDe, "", dAlocAte, ""}} )},,,,.F.,1) 	// "Detalhes no RH"
EndIf

oMrkAllAtd:AddButton(STR0233,{|| At330VsRest((oMrkAllAtd:Alias())->TMP_CODTEC)},,,,.F.,1)   // "Restrições do atendente"

oMrkAllAtd:SetColumns(aColumns)
oMrkAllAtd:Activate()

Return( lRetorno )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330BrwA2 
Browse atendentes alocados do Gestao de Servicos

@sample 	At330BrwA2(oDlgAtdAlo,oMrkAtdAlo,aMrkAtdAlo,lTecXRh)

@param		ExpO1	Objeto Panel atendentes alocados.
			ExpO2 	Objeto FwMarkBrowse atendentes alocados.
			ExpA3 	Array com as informacoes para popular o browse.
			ExpL4	Integracao Gestao de Servicos com RH?   
			
@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330BrwA2(oDlgAtdAlo,oMrkAtdAlo,aMrkAtdAlo,lTecXRh,aConfAloc,oLbxCfgAlo,oTreeDtFil,nPosPerFim)

Local lRetorno  := .T. 					// Retorno da rotina.
Local aSeek		:= {}					// Array com a chaves para busca.
Local cAliasTmp	:= aMrkAtdAlo[1]		// Alias temporario.
Local cAliasIdx	:= aMrkAtdAlo[2] 		// Index temporario.
Local aColumns	:= aMrkAtdAlo[3]		// Colunas que serao exibidas no browse.

If lTecXRh
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Remove os campos TMP_DISP / TMP_SITFOL / TMP_DESC.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	ADel(aColumns,9)
	ADel(aColumns,11)
	ADel(aColumns,12)
	ASize(aColumns,Len(aColumns)-3)
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Remove os campos TMP_CARGO / TMP_DISP / TMP_SITFOL / TMP_DESC.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	ADel(aColumns,8)
	ADel(aColumns,9)
	ADel(aColumns,11)
	ADel(aColumns,12)
	ASize(aColumns,Len(aColumns)-4)
EndIf

DbSelectArea(cAliasTmp)
(cAliasTmp)->( DbGoTop() )

aAdd(aSeek,{TxDadosCpo("AA1_CODTEC")[1],{{"","C",TamSX3("AA1_CODTEC")[1],TamSX3("AA1_CODTEC")[2],TxDadosCpo("AA1_CODTEC")[1],PesqPict("AA1","AA1_CODTEC")}} } )

oMrkAtdAlo:= FWMarkBrowse():New()
oMrkAtdAlo:SetFieldMark("TMP_OK")
oMrkAtdAlo:SetOwner(oDlgAtdAlo)
oMrkAtdAlo:oBrowse:SetDataQuery(.F.)
oMrkAtdAlo:oBrowse:SetDataTable(.T.)
oMrkAtdAlo:SetAlias(cAliasTmp)
oMrkAtdAlo:oBrowse:SetSeek(,aSeek) 
oMrkAtdAlo:SetAllMark({|| At330AMkB2(oMrkAtdAlo) })  
oMrkAtdAlo:SetTemporary()
oMrkAtdAlo:SetDescription("")
oMrkAtdAlo:SetMenuDef("")
oMrkAtdAlo:AddButton(STR0077,{|| At330VsAtd((oMrkAtdAlo:Alias())->TMP_CODTEC)},,,,.F.,1) 		// "Visualizar Atendente"
oMrkAtdAlo:AddButton(STR0078,{|| At330CAloc((oMrkAtdAlo:Alias())->TMP_CODTEC,oMrkAtdAlo,aConfAloc,oLbxCfgAlo,oTreeDtFil,nPosPerFim)},,,,.F.,1)  	// "Controle de Alocação"
oMrkAtdAlo:AddButton(STR0079,{|| At330LMkA2()},,,,.F.,2)                               		// "Legenda"
                                           
oMrkAtdAlo:SetColumns(aColumns)
oMrkAtdAlo:Activate()

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330Title 
Retorna o titulo do campo.

@sample 	At330Title(cCampoX3)

@param		ExpC1	Titulo do Campo.

@return		ExpC	Nome do campo 

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330Title(cCampoX3)

Local cTitulo := ""			// Titulo do campo

Default cCampoX3 := ""		// Nome do Campo no SX3.

DbSelectArea("SX3")
DbSetOrder(2)

If DbSeek(cCampoX3)
	cTitulo := Alltrim(X3Titulo())
EndIf

Return( cTitulo )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330FEsc 
Filtro da Escala.

@sample 	At330FEsc()

@param		Nenhum

@return		ExpL - Condicao do Filtro.

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330FEsc()

Local lCondicao := (RBL->RBL_ESCALA == cEscala)    // Codicao do Filtro.

Return( lCondicao )
     
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AtBrw 
Atualiza o browse da alocacao de atendentes. 

@sample 	At330AtBrw(oBrowse,cAlias)

@param		ExpO1 	Objeto Browse a ser atualizado.
			ExpC2 	Novo Alias.

@return		ExpL	Verdadeiro.

@author		Anderson Silva
@since		27/11/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330AtBrw(oBrowse,cAlias)

Local lRetorno  := .T. 		// Retorno da rotina.
Local lGoTop 	:= .T.		// Posiciona no primeiro registro.

oBrowse:SetAlias(cAlias)
oBrowse:Refresh(lGoTop)     
oBrowse:OnChange() 

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VsAtd 
Visualiza o Atendente.

@sample 	At330VsAtd(cCodAtend)

@param		ExpC1	Codigo do Atendente.

@return		ExpL	Verdadeiro.

@author		Anderson Silva
@since		27/11/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VsAtd(cCodAtend)

Local lRetorno := .T. 		// Retorno na rotina.

If !Empty(cCodAtend)
	
	DbSelectArea("AA1")
	DbSetOrder(1)
	
	If DbSeek(xFilial("AA1")+cCodAtend)
		FWExecView(Upper(STR0071),"VIEWDEF.TECA020",1,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)    // Visualizar
	EndIf
	
Else
	MsgAlert(STR0157,STR0158) // "Selecione um atendente para visualizar."###"Atenção"
EndIf

Return( lRetorno )
  
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330LMkA1
Legenda do browse atendentes.

@sample 	At330LMkA1()

@param		Nenhum

@return		Nenhum

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330LMkA1()

Local oLegenda  :=  FWLegend():New() 				// Objeto FwLegend.

oLegenda:Add("","BR_BRANCO",STR0080)     		  	// "Disponível / Não Alocado."
oLegenda:Add("","BR_AMARELO",STR0081)				// "Não Disponível / Alocado."
oLegenda:Add("","BR_VERMELHO",STR0082)      		// "Não Disponível / Restrito no RH."
oLegenda:Add("","BR_PRETO",STR0231)      		// "Restrição de bloqueio no local de atendimento/cliente"
oLegenda:Add("","BR_LARANJA",STR0232)      		// "Restrição de aviso no local de atendimento/cliente"

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil
 
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330LMkA2
Legenda do Browse Atendentes Alocado no Contrato.

@sample 	At330LMkA2()

@param		Nenhum

@return		Nenhum

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330LMkA2()

Local oLegenda  :=  FWLegend():New() 		// Objeto FwLegend.

oLegenda:Add("","BR_PRETO",STR0083)     	// "Alocado."

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil
   
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ClrDt
Limpa as pastas do detalhes do atendente.

@sample 	At330ClrDt(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.

@return		ExpL	Verdadeiro.

@author		Anderson Silva
@since		30/10/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330ClrDt(oTreeDtFil)

Local lRetorno := .T.   // Retorno da rotina.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta habilidades do ultimo atendente selecionado no grid. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oTreeDtFil:TreeSeek("DETATD")
oTreeDtFil:TreeSeek("HABATEND")
oTreeDtFil:DelItem()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Deleta a pasta regiao de atendimento do ultimo atendente selecionado no grid. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oTreeDtFil:TreeSeek("DETATD")
oTreeDtFil:TreeSeek("REGATEND")
oTreeDtFil:DelItem()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Adiciona uma nova pasta habilidade para atendente selecionado no grid. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oTreeDtFil:TreeSeek("DETATD")
oTreeDtFil:AddItem(STR0067,"HABATEND","FOLDER5","FOLDER6",,,2) 	// "Habilidades" 
oTreeDtFil:AddItem(STR0012,"REGATEND","FOLDER5","FOLDER6",,,2)		// "Região de Atendimento"

Return( lRetorno )   


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GAtIt
Retorna os atendentes no item da O.S. 

@sample 	At330GAtIt(oTreeOS,oMrkAtdAlo)

@param		ExpO1	Objeto DBTree Ordem de Servico.
			ExpO2 	Objeto FwMarkBrowse atendentes alocados.
			
@return		ExpL	Verdadeiro.

@author		Anderson Silva
@since		27/11/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330GAtIt(oTreeOS,oMrkAtdAlo)

Local lRetorno	:= .T.	   	// Retorno da rotina
Local nPosItOS 	:= 0		// Posicao do elemento no array.

nPosItOS := aScan(oTreeOS:Cargo,{|x| x[1] == AllTrim(oTreeOS:GetCargo()) .AND. x[2] == "ITEM" })

If nPosItOS > 0
	MsgRun(STR0084, STR0085, {|| ApagarTemp(oMrkAtdAlo:Alias()),;	// "Localizando os atendentes alocados..."#"Aguarde"
	                             aMrkAtdAlo := ListarApoio(/*dIniAloc*/,;
	                                                       /*dFimAloc*/,;
	                                                       /*aCargos*/,;
	                                                       /*aFuncoes*/,;
	                                                       /*aHabil*/,;
	                                                       "A" /*cDisponib*/,;
	                                                       /*cContIni*/,;
	                                                       /*cContFim*/,;
	                                                       /*cCCusto*/,;
	                                                       "3" /*cLista*/,;
	                                                       2 /*nLegenda*/,;
	                                                       oTreeOS:Cargo[nPosItOS][5] /*cItemOS*/,;
	                                                       /*aTurnos*/,;
	                                                       /*aRegiao*/,;
	                                                       /*lEstrut*/,;
	                                                       /*aPeriodos*/,;
	                                                       /*cIdCfAbq*/,;
	                                                       /*cLocOrc*/,;
	                                                       /*aSeqTrn*/,;
	                                                       /*aPeriodRes*/,;
	                                                       /*cLocalAloc*/,;
	                                                       /*aCarac*/,;
	                                                       /*aCursos*/),;
	                             At330AtBrw(oMrkAtdAlo,aMrkAtdAlo[1])})
EndIf
        
Return( lRetorno )


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GTree
Retorna os itens de uma determinada pasta de filtro do Tree.

@sample 	At330GTree(oTreeDtFil,cIdFolder)

@param		ExpO1	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Id da pasta de filtro.	
			
@return		ExpA - Itens da pasta de filtro. 

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330GTree(oTreeDtFil,cIdFolder)

Local aRet		:= {}			// Array com os itens do Tree.
Local nX		:= 0 			// Incremento utilizado no laco For.
Local nPosPasta := 0   			// Posicao dos itens habilidades na carga do Tree.

Default cIdFolder := ""

Do Case

Case ( cIdFolder == "FILHAB" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })		
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,{	oTreeDtFil:Cargo[nPosPasta][nX][2] ,;
						oTreeDtFil:Cargo[nPosPasta][nX][3]	,;
						oTreeDtFil:Cargo[nPosPasta][nX][4]	})
		Next nX
	EndIf  
Case ( cIdFolder == "FILREG" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf
Case ( cIdFolder == "FILCAR" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf   
Case ( cIdFolder == "FILFUN" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf
Case ( cIdFolder == "FILTUR" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf
Case ( cIdFolder == "FILSEQ" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf
Case ( cIdFolder == "FILCC" )
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })
	If nPosPasta > 0 .And. Len(oTreeDtFil:Cargo[nPosPasta]) >= 2
		nX := 2
		aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
	Else
		aAdd(aRet," ")
	EndIf
Case ( cIdFolder == "FILCRC" ) // Caracteristica
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf
Case ( cIdFolder == "FILCUR" ) // Cursos
	nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == cIdFolder })	
	If nPosPasta > 0
		For nX := 2 To Len(oTreeDtFil:Cargo[nPosPasta])
			aAdd(aRet,oTreeDtFil:Cargo[nPosPasta][nX][2])
		Next nX
	EndIf	
EndCase

Return( aRet )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330CAloc
Retorna as regioes adicionada no filtro do Tree.

@sample 	At330CAloc(cCodAtend)

@param		ExpC1	Codigo Atendente.
			
@return		ExpL	Verdadeiro / Falso

@author		Anderson Silva
@since		27/11/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330CAloc(cCodAtend,oBrowse,aConfAloc,oLbxCfgAlo,oTreeDtFil,nPosPerFim)
	
Local lRetorno := .T.    // Retorno da rotina	

If !Empty(cCodAtend)

	TECA510(,cCodAtend)
	
	If	! IsInCallStack("TECA560")
	dAlocDe := aConfAloc[oLbxCfgAlo:nAt][nPosPerIni]
	dAlocAte := aConfAloc[oLbxCfgAlo:nAt][nPosPerFim]
	
	aMrkAtdAlo := ListarApoio(dAlocDe /*dIniAloc*/,;
		dAlocAte /*dFimAloc*/,;
		/*IIF(lTecXRh,{aConfAloc[oLbxCfgAlo:nAt][nPosCargo]},Nil)*/ /*aCargos*/,;
		/*{aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]}*/ /*aFuncoes*/,;
		/*At330GTree(oTreeDtFil,"FILHAB")*/ /*aHabil*/,;
		"A" /*cDisponib*/,;
		/*cContIni*/,;
		/*cContFim*/,;
		/*cCCusto*/,;
		"3" /*cLista*/,;
		2 /*nLegenda*/,;
		/*cItemOS*/,;
		/*{aConfAloc[oLbxCfgAlo:nAt][nPosTurno]}*/ /*aTurnos*/,;
		/*At330GTree(oTreeDtFil,"FILREG")*/ /*aRegiao*/,;
		/*lEstrut*/,;
		/*aPeriodos*/,;
		aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg] /*cIdCfAbq*/,;
		aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocOrc*/,;
		/*aSeqTrn*/,;
		/*aPeriodRes*/,;
		aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocalAloc*/,;
		At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
		/*aCursos*/)
	
	At330AtBrw(oBrowse,aMrkAtdAlo[1])
	EndIf
Else
	lRetorno := .F.
	MsgAlert(STR0152,STR0147) // "Selecione um atendente para visualizar a sua alocação."#"Atenção"
EndIf
	
Return( lRetorno )
 

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VdAlo 
Valida as informacoes do browse atendentes antes de alocar.

@sample 	At330VdAlo(oMrkAllAtd,oTreeOS,lRfzConsul)

@param		ExpO1 	Objeto FwMarkBrowse atendentes alocados.
			ExpO2 	Objeto DBTree Ordem de Servico.
			ExpL3 	Refaz a consulta de atendentes?
			ExpC4 	Codigo orçamento de serviços 

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		18/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VdAlo(oMrkAllAtd,oTreeOS,lRfzConsul,cNrOrcSrv,cContrato,aConf,nPosPerFim)

Local lRetorno  := .F. 									// Retorno da rotina.
Local aAreaTmp	:= (oMrkAllAtd:Alias())->(GetArea())	// Guarda area do browse.	
Local nPosItOS	:= 0									// Posicao do item da O/S.
Local lOrcSrv		:= .F.
Local cAliasTFF   := GetNextAlias()
Local cAliasABQ   := GetNextAlias()
Local nQtdAtend	:= 0
Local cContrIte   := SUBSTRING(aConf[nPosIdCfg],TAMSX3("TFF_CONTRT")[1]+1,TAMSX3("TFF_ITEM")[1])
Local aAtendente  :={}	
Local cFilAtu 		:= xFilial("AA1")
Local lFilDiff 		:= .F.
Default cNrOrcSrv := ""
Default cContrato := SUBSTRING(aConf[nPosIdCfg],1,TAMSX3("TFF_CONTRT")[1])
Default nPosPerFim:= 0

lOrcSrv := (!Empty(cNrOrcSrv))

If !lRfzConsul
	(oMrkAllAtd:Alias())->(DbGoTop())
	
	While (oMrkAllAtd:Alias())->(!Eof())
		If !Empty((oMrkAllAtd:Alias())->TMP_OK)
			lRetorno := .T.
			nQtdAtend++
			
			If Ascan(aAtendente,(oMrkAllAtd:Alias())->TMP_CODTEC)==0
				aAdd(aAtendente,(oMrkAllAtd:Alias())->TMP_CODTEC)
			EndIf	
			
			If cFilAtu <> (oMrkAllAtd:Alias())->TMP_FILIAL
				lRetorno := .F.
				lFilDiff := .T.
				Help("",1,"At330FilDif",, STR0256,2,0)   // "Atendentes de filiais diferentes do contrato não podem ser alocados."
				Exit
			EndIf
		EndIf
		(oMrkAllAtd:Alias())->(DbSkip())
	End
	
	If !lRetorno .And. !lFilDiff
		MsgStop(STR0086,STR0059) // "Não há atendentes marcados para alocação."#"Atenção"
	EndIf	
	
	If nPosPerFim > 0 .And. Empty(aConf[nPosPerFim])
		Help("",1,"At330VdAlo",,STR0222,2,0) //"Informe a data final de alocacao"
		lRetorno := .F.
	EndIf
	
	If !lOrcSrv .And. lRetorno 
		If Len(oTreeOS:Cargo) > 0
			nPosItOS := aScan(oTreeOS:Cargo,{|x| x[1] == AllTrim(oTreeOS:GetCargo()) .AND. x[2] == "ITEM" })
			If nPosItOS == 0
				lRetorno := .F.
				MsgAlert(STR0087,STR0059) // "Selecione um item da O/S para alocar este atendente"#"Atenção"
			EndIf
		Else
			lRetorno := .F.
			MsgAlert(STR0197,STR0059) //"Para realizar a alocação de atendentes inclua uma ordem de serviço para este contrato!"
		EndIf
	EndIf	
	
	If lRetorno .And. Len(aAtendente)>0
		lRetorno:=At020VlDtC(aAtendente)//Alerta para vencimento do curso do atendente	
	EndIf		
	
Else
	Aviso(STR0059,STR0088+Chr(10)+STR0089,{STR0161},2) // "Atenção"#"O período de alocação foi alterado."#"Em parâmetros clique no botão Ok para localizar os atendentes no período desejado." 
EndIf

RestArea(aAreaTmp)

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330Aloca
Monta a alocacao dos atendentes selecionados no browse(Atendentes).

@sample 	At330Aloca(dAlocDe,dAlocAte,oMrkAllAtd,oMrkAtdAlo,oTreeOS,oTreeDtFil,
			oLbxCfgAlo,cItCbxSel,lTecXRh,aConfAloc,aMrkAllAtd,aMrkAtdAlo,cNrOrcSrv)


@param		ExpD1 	Alocacao De.
			ExpD2	Alocacao Ate.
			ExpO3 	Objeto FwMarkBrowse atendentes.
			ExpO4 	Objeto FwMarkBrowse atendentes alocados.
			ExpO5 	Objeto DBTree Ordem de Servico. 
			ExpO6	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpO7 	Objeto ListBox Configuracao da Alocacao.
			ExpC8	Item selecionado no objeto ComboBox.
			ExpL9	Integracao Gestao de Servicos com RH?  
			ExpA10	Array com as configuracoes da alocacao.
			ExpA11	Array com atendentes do Gestao de Servicos.
			ExpA12	Array com os atendentes alocados no contrato.
			ExpC13 Codigo orçamento de serviços

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330Aloca( dAlocDe,dAlocAte,oMrkAllAtd,oMrkAtdAlo,oTreeOS,oTreeDtFil,;
							oLbxCfgAlo,cItCbxSel,lTecXRh,aConfAloc,aMrkAllAtd,aMrkAtdAlo,cNrOrcSrv ) 

Local lRetorno 		:= .F.  											// Retorno da validacao.
Local aAreaTmp 		:= (oMrkAllAtd:Alias())->(GetArea())   			// Guarda a area do browse.
Local cAlocDe	 	:= dToc(dAlocDe) 									// Alocacao De.
Local cAlocAte 		:= dToc(dAlocAte) 									// Alocacao Ate.
Local cCodAtend		:= "" 												// Codigo do Atendente.
Local cSim			:= STR0090   		  								// Indica o sim de acordo com o idioma corrente.
Local nPosAtd		:= 0 				   								// Posicao do atendente no array.
Local nPosCfgAlo	:= 0                                              	// Posicao da configuracao da alocacao (selecionada).
Local nPosItOS      := 0												// Posicao do item da O/S selecionada no Tree de OS.
Local aCalendAtd	:= {}												// Array com o calendario do RH do atendente.
Local aCalendInf	:= {}								                // Array com as informacoes do calendario do RH do atendente.
Local aAtdXCalen 	:= {} 												// Array com os atendentes X calendario do RH.		
Local cHrsCtrt		:= "" 												// Horas contratada (Caracter).
Local nHrsCtrt		:= 0 												// Horas contratada (Numerico).
Local cHrsAloc		:= "" 												// Horas alocadas (Caracter).
Local nHrsAloc		:= 0												// Horas alocadas (Numerico).
Local cSldHrs		:= ""												// Saldo de horas (Caracter).
Local nSldHrs		:= 0                                               	// Saldo de horas (Numerico).
Local nTotHrsAlo	:= 0  												// Total de horas para alocar.
Local nOpcA			:= 0 												// Opcao escolhida pelo usuario (1-Confirmar ou 2-Fechar).
Local lCanAlocEx 	:= At680Perm( Nil, __cUserID, "005" ) 				// avalia se o usuário tem permissão de alocação excedente
Local lCanAlocAll 	:= .T. 												// variável para controlar se a alocação poderá ser realizada
Local aItensBlock 	:= {}
Local cAgsBlocks 	:= ""
Local nQtAlocar 	:= 0
Local cMsgErro 		:= ""

Default cNrOrcSrv := ""
 
nPosCfgAlo	:= aScan(aConfAloc,{|x| Valtype(x[1]) == "O" .And. x[1]:cName == "LBOK" })

If Empty(cNrOrcSrv)
	nPosItOS 	:= aScan(oTreeOS:Cargo,{|x| x[1] == AllTrim(oTreeOS:GetCargo()) .AND. x[2] == "ITEM" })
EndIf

cHrsCtrt 	:= StrTran(aConfAloc[nPosCfgAlo][nPosHrsCtr],".","")
nHrsCtrt  	:= Val(StrTran(cHrsCtrt,",","."))

cHrsAloc 	:= StrTran(aConfAloc[nPosCfgAlo][nPosHrsAlo],".","")
nHrsAloc  	:= Val(StrTran(cHrsAloc,",","."))

cSldHrs 	:= StrTran(aConfAloc[nPosCfgAlo][nPosSaldo],".","")
nSldHrs		:= Val(StrTran(cSldHrs,",","."))

(oMrkAllAtd:Alias())->(DbGoTop())

While (oMrkAllAtd:Alias())->(!Eof())
	
	lCanAlocAll := .T.
	
	If !Empty((oMrkAllAtd:Alias())->TMP_OK) 
		nPosAtd := aScan(aAtdXCalen,{|x| x[1] == (oMrkAllAtd:Alias())->TMP_CODTEC })
		If nPosAtd == 0
			lRetorno := TxCalenAtd( dAlocDe, dAlocAte, (oMrkAllAtd:Alias())->TMP_CODTEC, @aCalendAtd, @aCalendInf,;
									aConfAloc[nPosCfgAlo][nPosTurno], If(!Empty(aConfAloc[nPosCfgAlo][nPosSeqTrn]),aConfAloc[nPosCfgAlo][nPosSeqTrn], '01' ),;
									/*lTransf*/,/*lExibeHelp*/, aConfAloc[nPosCfgAlo][nPosPerIni],;
									aConfAloc[nPosCfgAlo][nPosLocal], (oMrkAllAtd:Alias())->TMP_FILIAL, @cMsgErro )
			
			If ( lRetorno .AND. Len(aCalendAtd) > 0 )
				
				If !lCanAlocEx
					nQtAlocar += 1
					lCanAlocAll := At330CanAloc( @cAgsBlocks ,;
											@aCalendAtd, ;
											@aCalendInf, ; 
											aConfAloc[nPosCfgAlo,nPosIdCfg],;
											(oMrkAllAtd:Alias())->TMP_CODTEC,;
											(oMrkAllAtd:Alias())->TMP_NOMTEC,;
											nQtAlocar )
				EndIf
				
				If Len(aCalendAtd) > 0
					aAdd(aAtdXCalen,{	(oMrkAllAtd:Alias())->TMP_CODTEC  				,;
						(oMrkAllAtd:Alias())->TMP_NOMTEC								,;
						(oMrkAllAtd:Alias())->TMP_CDFUNC								,;
						aConfAloc[nPosCfgAlo][nPosTurno]	  							,;
						(oMrkAllAtd:Alias())->TMP_FUNCAO 								,;
						(oMrkAllAtd:Alias())->TMP_CARGO	   								,;
						aConfAloc[nPosCfgAlo][nPosIdCfg]   							,;
						Iif(Empty(cNrOrcSrv),oTreeOS:Cargo[nPosItOS][3], "")			,;
						Iif(Empty(cNrOrcSrv),oTreeOS:Cargo[nPosItOS][5], "")			,;
						aCalendAtd						   									,;
						aCalendInf 				   										,;
						Iif(Empty(cNrOrcSrv),"",aConfAloc[nPosCfgAlo][nPosLocal]) 	,;
						aConfAloc[nPosCfgAlo][nPosSeqTrn]})
									
					nTotHrsAlo += aCalendInf[1]
				EndIf
				
				If !lCanAlocAll
					aAdd( aItensBlock, cAgsBlocks )
				EndIf
				
			EndIf
			
		EndIf
		
	EndIf
	(oMrkAllAtd:Alias())->(DbSkip())
End

If Len(aItensBlock) > 0 

	cAgsBlocks := ""
	aEval( aItensBlock, {|x| cAgsBlocks += x + CRLF } )

	If Len(aAtdXCalen) > 0
		
		lRetorno := ( Aviso( STR0005,; //"Alocação de Atendente"
						STR0208 + CRLF +;  // "Deseja continuar com a geração das agendas que não possuem impedimento?"
						STR0209 + CRLF + ; // "Algumas agendas não serão geradas por limitação na quantidade restrita no contrato."
						STR0210 + CRLF + cAgsBlocks, ;  // "Agendas que não serão geradas são:" 
						{STR0211,STR0212},3) ) == 1  // "Sim" ### "Não" 
	Else
		lRetorno := .F.
		Aviso( STR0005,; // "Alocação de Atendente"
			STR0213 + CRLF + cAgsBlocks, ;  // "Agendas não serão geradas em função de restrição na quantidade em contrato." 
			{STR0022},3)  // "OK"
	EndIf
	
EndIf

If Len(aAtdXCalen) > 0 .And. lRetorno
	
	nOpcA := At330MntAl(aAtdXCalen,nSldHrs,nTotHrsAlo,lTecXRh,cNrOrcSrv)
	
	If nOpcA == 1
	
		MsgRun(STR0091, STR0092, {||( At330ClrDt(oTreeDtFil),; // "Atualizado o browse atendentes"#"Aguarde"
		                              ApagarTemp(oMrkAllAtd:Alias()),;
		                              aMrkAllAtd := ListarApoio(dAlocDe /*dIniAloc*/,;
		                                                        dAlocAte /*dFimAloc*/,;
		                                                        IIf(lTecXRh, At330GTree(oTreeDtFil,"FILCAR"), Nil) /*aCargos*/,;
		                                                        At330GTree(oTreeDtFil,"FILFUN") /*aFuncoes*/,;
		                                                        At330GTree(oTreeDtFil,"FILHAB") /*aHabil*/,;
		                                                        /*cDisponib*/,;
		                                                        /*cContIni*/,;
		                                                        /*cContFim*/,;
		                                                        At330GTree(oTreeDtFil,"FILCC")[1] /*cCCusto*/,;
		                                                        cItCbxSel /*cLista*/,;
		                                                        /*nLegenda*/,;
		                                                        /*cItemOS*/,;
		                                                        At330GTree(oTreeDtFil,"FILTUR") /*aTurnos*/,;
		                                                        At330GTree(oTreeDtFil,"FILREG") /*aRegiao*/,;
		                                                        /*lEstrut*/,;
		                                                        /*aPeriodos*/,;
		                                                        /*cIdCfAbq*/,;
		                                                        /*cLocOrc*/,;
		                                                        At330GTree(oTreeDtFil,"FILSEQ") /*aSeqTrn*/,;
		                                                        /*aPeriodRes*/,;
		                                                        aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocalAloc*/,;
		                                                        At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
		                                                        At330GTree(oTreeDtFil,"FILCUR") /*aCursos*/),;
		                              At330AtBrw(oMrkAllAtd,aMrkAllAtd[1]))})
		If Empty(cNrOrcSrv)
			MsgRun(STR0093, STR0092, {|| ApagarTemp(oMrkAtdAlo:Alias()),; // "Atualizado o browse atendentes alocados..."#"Aguarde"
			                             aMrkAtdAlo := ListarApoio(/*dIniAloc*/,;
			                                                       /*dFimAloc*/,;
			                                                       /*aCargos*/,;
			                                                       /*aFuncoes*/,;
			                                                       /*aHabil*/,;
			                                                       "A" /*cDisponib*/,;
			                                                       /*cContIni*/,;
			                                                       /*cContFim*/,;
			                                                       /*cCCusto*/,;
			                                                       "3" /*cLista*/,;
			                                                       2 /*nLegenda*/,;
			                                                       oTreeOS:Cargo[nPosItOS][5] /*cItemOS*/,;
			                                                       /*aTurnos*/,;
			                                                       /*aRegiao*/,;
			                                                       /*lEstrut*/,;
			                                                       /*aPeriodos*/,;
			                                                       /*cIdCfAbq*/,;
			                                                       /*cLocOrc*/,;
			                                                       /*aSeqTrn*/,;
			                                                       /*aPeriodRes*/,;
			                                                       /*cLocalAloc*/,;
			                                                       /*aCarac*/,;
			                                                       /*aCursos*/),;
			                             At330AtBrw(oMrkAtdAlo, aMrkAtdAlo[1])})
		Else
			MsgRun(STR0093, STR0092, {|| ApagarTemp(oMrkAtdAlo:Alias()),; // "Atualizado o browse atendentes alocados..."#"Aguarde"
			                             aMrkAtdAlo := ListarApoio(/*dIniAloc*/,;
			                                                       /*dFimAloc*/,;
			                                                       /*aCargos*/,;
			                                                       /*aFuncoes*/,;
			                                                       /*aHabil*/,;
			                                                       "A" /*cDisponib*/,;
			                                                       /*cContIni*/,;
			                                                       /*cContFim*/,;
			                                                       /*cCCusto*/,;
			                                                       "3" /*cLista*/,;
			                                                       2 /*nLegenda*/,;
			                                                       /*cItemOS*/,;
			                                                       /*aTurnos*/,;
			                                                       /*aRegiao*/,;
			                                                       /*lEstrut*/,;
			                                                       /*aPeriodos*/,;
			                                                       aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg] /*cIdCfAbq*/,;
			                                                       aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocOrc*/,;
			                                                       /*aSeqTrn*/,;
			                                                       /*aPeriodRes*/,;
			                                                       /*cLocalAloc*/,;
			                                                       /*aCarac*/,;
			                                                       /*aCursos*/),;
			                             At330AtBrw(oMrkAtdAlo, aMrkAtdAlo[1])})
		EndIf		
		
		aConfAloc[nPosCfgAlo][nPosSaldo]	:= Transform(( nSldHrs - nTotHrsAlo ),PesqPict("ABQ","ABQ_SALDO"))
		aConfAloc[nPosCfgAlo][nPosHrsAlo]	:= Transform(( nHrsCtrt - ( nSldHrs - nTotHrsAlo ) ),PesqPict("ABQ","ABQ_TOTAL"))
		oLbxCfgAlo:Refresh()    
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Abate o saldo de horas do configurador de alocacao. ³
   		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TxSaldoCfg(aConfAloc[nPosCfgAlo][nPosIdCfg],nTotHrsAlo,.F.)
		
	EndIf
	
Else
	
	If !lCanAlocEx .And. Len(aItensBlock) > 0 .And. !lRetorno
		MsgStop(STR0254,STR0061) //"Geração das agendas foi cancelada"#"Atenção"
	ElseIf !Empty(cMsgErro)
		MsgStop(cMsgErro,STR0061) // "Atenção"
	ElseIf lTecXRh
		MsgStop(STR0094,STR0061) // "O período selecionado não está disponivel no calendário do RH."#"Atenção"
	Else
		MsgStop(STR0095,STR0061) // "O período selecionado não está disponivel."#"Atenção"
	EndIf
EndIf

RestArea(aAreaTmp)

Return( lRetorno )                                                   

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330MntAl
Monta a interface da previsao de alocacao.

@sample 	At330MntAl(aAtdXCalen,nSldHrs,nTotHrsAlo,lTecXRh)

@param		ExpA1 	Array com os atendentes X calendario do RH.
			ExpN2	Saldo de horas.
			ExpN3 	Total de Horas para alocar.
			ExpL4	Integracao Gestao de Servicos com RH?
			ExpC5 	Codigo orçamento de serviços

@return		ExpN 	Opcao escolhida pelo usuario (Confirmar ou Fechar).

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330MntAl(aAtdXCalen,nSldHrs,nTotHrsAlo,lTecXRh, cNrOrcSrv)

Local oDlg 	   		:= Nil     											// Janela principal.
Local aSize    		:= MsAdvSize()										// Dimensao da janela criada pelo Protheus.
Local aObjects  	:= {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     	:= {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   	:= MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local oFWLayer		:= Nil 												// Objeto FwLayer.
Local oDlgAtend		:= Nil 												// Janela atendentes.								
Local oDlgCalend	:= Nil 												// Janela calendario do atendente.
Local oBrwAtend		:= Nil												// Browse atendentes.
Local oBrwCalend	:= Nil												// Browse calendario do atendente.
Local oColAtend 	:= Nil												// Colunas do Browse atendentes.
Local oColCalend	:= Nil												// Colunas do Browse calendario do atendente.
Local oDlgInfAlo	:= Nil												// Janela informacoes da alocacao.
Local oDlgTotais	:= Nil												// Janela totais.
Local oMGHrsAlo		:= Nil												// Objeto MsGet horas alocadas.												
Local nHrsAlo		:= aAtdXCalen[1][11][1] 							// Horas alocadas.
Local oMGDiasTrb	:= Nil   											// Objeto MsGet dias trabalhados.	 													
Local nDiasTrb 		:= aAtdXCalen[1][11][2]							// Dias trabalhados.	
Local oMGSldHrs		:= Nil    											// Objeto MsGet saldo de horas.
Local nSdHrs		:= nSldHrs 											// Saldo de horas.
Local oMGTotAlo		:= Nil 												// Objeto MsGet total de horas para alocar.
Local nTHrsAlo		:= nTotHrsAlo 										// Total de horas para alocar.
Local oMGSHrsPrv	:= Nil    											// Objeto MsGet saldo de horas previsto.
Local nSHrsPrv		:= (nSldHrs-nTotHrsAlo) 						    // Saldo de horas previsto.
Local nOpcA			:= 0												// Opcao escolhida pelo usuario (1-Confirmar ou 2-Fechar).
Local lGoTop 		:= .T.												// Posiciona no primeiro registro.
Local cTipo		:= ""

Default cNrOrcSrv := ""

DEFINE MSDIALOG oDlg TITLE STR0096 From aSize[7],aSize[2] TO aSize[6],aSize[5] OF oMainWnd PIXEL  // "Previsão da Alocação dos Atendentes"

	oFWLayer := FWLayer():New()
	oFWLayer:Init(oDlg,.F.)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Janela configuracao para alocacao. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oFWLayer:AddLine("LINEATD",40,.F.)
	oFWLayer:AddCollumn("ATEND",100,.F.,"LINEATD")
	oFWLayer:AddWindow("ATEND","oDlgAtend",STR0097,100,.F.,.F.,,"LINEATD",{||})  // "Atendentes"
	
	oDlgAtend := oFWLayer:GetWinPanel("ATEND","oDlgAtend","LINEATD")


	DEFINE FWBROWSE oBrwAtend DATA ARRAY ARRAY aAtdXCalen LINE BEGIN 1 OF oDlgAtend

		ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][1] }") TITLE STR0098 SIZE TamSX3("AA1_CODTEC")[1] OF oBrwAtend   	   											   				// "Atendente"
		ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][2] }") TITLE STR0099 SIZE TamSX3("AA1_NOMTEC")[1] OF oBrwAtend   																// "Nome do Atend."
		ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][3] }") TITLE STR0100 SIZE TamSX3("AA1_CDFUNC")[1]  OF oBrwAtend	   															// "Cód.Func."
		ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][4] }") TITLE STR0101 SIZE TamSX3("AA1_TURNO")[1]  OF oBrwAtend   		   														// "Turno"
		ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][13] }") TITLE STR0204 SIZE TamSX3("RA_SEQTURN")[1]  OF oBrwAtend   		   														// "Seq. Turno"
		ADD COLUMN oColAtend DATA &("{ || Alltrim(FDESC('SR6',aAtdXCalen[oBrwAtend:At()][4],'R6_DESC'))}") TITLE STR0102 SIZE TamSX3("R6_DESC")[1]  OF oBrwAtend  					   				// "Descrição"
		ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][5] }") TITLE STR0103 SIZE TamSX3("AA1_FUNCAO")[1] OF oBrwAtend   																// "Função"
		ADD COLUMN oColAtend DATA &("{ || Alltrim(FDESC('SRJ',aAtdXCalen[oBrwAtend:At()][5],'RJ_DESC',,ABQ->ABQ_FILIAL)) }") TITLE STR0102 SIZE TamSX3("RJ_DESC")[1]  OF oBrwAtend    				// "Descrição"
		
		If lTecXRh
			ADD COLUMN oColAtend DATA &("{ || aAtdXCalen[oBrwAtend:At()][6] }") TITLE STR0104 SIZE TamSX3('RA_CARGO')[1]  OF oBrwAtend                                                				// "Cargo" 
			ADD COLUMN oColAtend DATA &("{ || Alltrim(FDESC('SQ3',aAtdXCalen[oBrwAtend:At()][6],'Q3_DESCSUM',,ABQ->ABQ_FILIAL)) }") TITLE STR0105 SIZE TamSX3("Q3_DESCSUM")[1]  OF oBrwAtend   		// "Descrição"
		EndIf

	ACTIVATE FWBROWSE oBrwAtend

	oFWLayer:AddLine("LINEPRV",40,.F.)
	oFWLayer:AddCollumn("CALEND",100,.F.,"LINEPRV")
	oFWLayer:AddWindow("CALEND","oDlgCalend",STR0106,100,.F.,.F.,,"LINEPRV",{||})		// "Calendário do Atendente"
	
	oDlgCalend := oFWLayer:GetWinPanel("CALEND","oDlgCalend","LINEPRV")


	DEFINE FWBROWSE oBrwCalend DATA ARRAY ARRAY aAtdXCalen[1][10] LINE BEGIN 1 OF oDlgCalend
	
		ADD COLUMN oColCalend DATA &("{ || aAtdXCalen[oBrwAtend:At()][10][oBrwCalend:At()][1] }") TITLE STR0107 SIZE 8 ALIGN 1 OF oBrwCalend		// "Data"
		ADD COLUMN oColCalend DATA &("{ || aAtdXCalen[oBrwAtend:At()][10][oBrwCalend:At()][2] }") TITLE STR0108 SIZE 5 ALIGN 1 OF oBrwCalend 	// "Dia da Semana"
		ADD COLUMN oColCalend DATA &("{ || aAtdXCalen[oBrwAtend:At()][10][oBrwCalend:At()][3] }") TITLE STR0109 SIZE 5 ALIGN 1 OF oBrwCalend  	// "Entrada"
		ADD COLUMN oColCalend DATA &("{ || aAtdXCalen[oBrwAtend:At()][10][oBrwCalend:At()][4] }") TITLE STR0110 SIZE 5 ALIGN 1 OF oBrwCalend    	// "Saída"
		ADD COLUMN oColCalend DATA &("{ || aAtdXCalen[oBrwAtend:At()][10][oBrwCalend:At()][5] }") TITLE STR0111 SIZE 5 ALIGN 1 OF oBrwCalend   	// "Horas Trab."
		ADD COLUMN oColCalend DATA &("{ || aAtdXCalen[oBrwAtend:At()][10][oBrwCalend:At()][6] }") TITLE STR0112 SIZE 2 ALIGN 1 OF oBrwCalend   	// "Sequência do Turno"
		
	ACTIVATE FWBROWSE oBrwCalend

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Janela configuracao para alocacao. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oFWLayer:AddLine("LINEINFTOT",20,.F.)   
	oFWLayer:AddCollumn("INFOALO",38,.F.,"LINEINFTOT")
	oFWLayer:AddCollumn("TOTAIS",62,.F.,"LINEINFTOT")
	oFWLayer:AddWindow("INFOALO","oDlgInfAlo",STR0113,100,.F.,.F.,,"LINEINFTOT",{|| })									// "Informações da Alocação"
	oFWLayer:AddWindow("TOTAIS","oDlgTotais",STR0114,100,.F.,.F.,,"LINEINFTOT",{|| })	   									// "Saldos / Total"
	
	oDlgInfAlo := oFWLayer:GetWinPanel("INFOALO","oDlgInfAlo","LINEINFTOT")
	oDlgTotais := oFWLayer:GetWinPanel("TOTAIS","oDlgTotais","LINEINFTOT")

	@002,001 SAY STR0115 SIZE 40,10 OF oDlgInfAlo PIXEL       													   			// "Horas Alocar:"
	@001,038 MSGET oMGHrsAlo VAR nHrsAlo PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgInfAlo PIXEL
	@002,104 SAY STR0116 SIZE 40,10 OF oDlgInfAlo PIXEL     														   		// "Dias Trab.:"
	@001,134 MSGET oMGDiasTrb VAR nDiasTrb PICTURE "@!"  WHEN .F.  SIZE 60,5 OF oDlgInfAlo PIXEL
	                                                            	
	@002,001 SAY STR0117 SIZE 50,10 OF oDlgTotais PIXEL         												   			// "Saldo de Hrs:"
	@001,038 MSGET oMGSldHrs VAR nSdHrs PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgTotais PIXEL
	@002,103 SAY STR0118 SIZE 50,10 OF oDlgTotais PIXEL          										   					// "Total de Hrs. Alocar:"
	@001,158 MSGET oMGTotAlo VAR nTHrsAlo PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgTotais PIXEL
	@002,223 SAY STR0119 SIZE 62,10 OF oDlgTotais PIXEL                           					   						// "Saldo de Hrs. (Estimado):"
	@001,289 MSGET oMGSHrsPrv VAR nSHrsPrv PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgTotais PIXEL

	EnchoiceBar(oDlg, {|| cTipo:=At330TipAlo(.T.), Iif(At330ResTec(aAtdXCalen,cTipo),(MsgRun(STR0120,STR0121,{|| nOpcA := 1,At330GvAlo(aAtdXCalen,cNrOrcSrv,cTipo) }),oDlg:End()),Nil) },{|| nOpcA := 2,oDlg:End() })  // "Alocando os atendentes..."#"Aguarde"

	oBrwAtend:SetChange({||	oBrwCalend:SetArray(aAtdXCalen[oBrwAtend:At()][10]) , oBrwCalend:Refresh(lGoTop),;
	( nHrsAlo := aAtdXCalen[oBrwAtend:At()][11][1],oMGHrsAlo:CtrlRefresh()),;
	( nDiasTrb := aAtdXCalen[oBrwAtend:At()][11][2],oMGDiasTrb:CtrlRefresh())})

ACTIVATE DIALOG oDlg CENTERED

Return( nOpcA )
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330CMkB1
Marca / Desmarca o atendente no browse.

@sample 	At330CMkB1(oMrkAllAtd)

@param		ExpO1 	Objeto FwMarkBrowse atendentes.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330CMkB1(oMrkAllAtd,aDConfAloc)

Local lRetorno	:= .T.			// Retorno da rotina.
Local cSim		:= STR0090   	// Indica o sim de acordo com o idioma corrente.
Local lTecXRh 		:= SuperGetMv("MV_TECXRH",,.F.)	// Integracao Gestao de Servicos com RH?.

Local lCont		:= .F.
Local ni		:= 0

For ni := 1 to Len(aDConfAloc)
	
	lCont := ValType(aDConfAloc[ni,1]) == "O" .And. aDConfAloc[ni,1]:cName == 'LBOK'
	
	If lCont
		exit
	EndIf
	
Next ni

If lCont
	If ( !oMrkAllAtd:IsMark() )
		If AllTrim((oMrkAllAtd:Alias())->TMP_DISP) == AllTrim(cSim) .Or. ((((oMrkAllAtd:Alias())->TMP_DISP) <> Alltrim(cSim) ) .And. ((oMrkAllAtd:Alias())->TMP_ALOC == AllTrim(cSim)))
			If( ((oMrkAllAtd:Alias())->TMP_LEGEN <> ("BR_LARANJA     ")) .And. ((oMrkAllAtd:Alias())->TMP_LEGEN <> AllTrim("BR_PRETO       ")) )
				RecLock(oMrkAllAtd:Alias(),.F.)
				(oMrkAllAtd:Alias())->TMP_OK  := oMrkAllAtd:Mark()
				(oMrkAllAtd:Alias())->(MsUnLock())
			Elseif  ((oMrkAllAtd:Alias())->TMP_LEGEN == ("BR_LARANJA     "))
				If msgYesNo(STR0234,STR0235) //"Atendente com restrição operacional de aviso."##"Deseja Continuar?" 
					lRetorno := .T.
					RecLock(oMrkAllAtd:Alias(),.F.)
				(oMrkAllAtd:Alias())->TMP_OK  := oMrkAllAtd:Mark()
				(oMrkAllAtd:Alias())->(MsUnLock())
				Else
					lRetorno := .F.
				Endif
			Elseif ((oMrkAllAtd:Alias())->TMP_LEGEN == ("BR_PRETO       "))
				Help("",1,"At330CMkB1",,STR0236,2,0) //"Atendente com restrição operacional para o local/cliente"
			Endif	
		ElseIf lTecXRh .AND. !AllTrim((oMrkAllAtd:Alias())->TMP_DISPRH) == AllTrim(cSim)
				lRetorno := .F.
				Help("",1,"At330CMkB1",,STR0197,2,0) //"Atendente possui bloqueio no RH."	
		Else	
			RecLock(oMrkAllAtd:Alias(),.F.)
			(oMrkAllAtd:Alias())->TMP_OK  := oMrkAllAtd:Mark()
			(oMrkAllAtd:Alias())->(MsUnLock())
		EndIf
	Else
		RecLock(oMrkAllAtd:Alias(),.F.)
		(oMrkAllAtd:Alias())->TMP_OK  := ""
		(oMrkAllAtd:Alias())->(MsUnLock())
	EndIf     
Else
	Help("",1,"At330CMkB1",,STR0253,2,0)//#"Favor selecionar um local"	
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AMkB1
Marca / Desmarca todos os atendentes no browse.

@sample 	At330AMkB1(oMrkAllAtd)

@param		ExpA1 	Objeto FwMarkBrowse atendentes.

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330AMkB1(oMrkAllAtd,aDConfAloc)

Local lRetorno	:= .T.		   								// Retorno da rotina.                           
Local aAreaTmp	:= (oMrkAllAtd:Alias())->(GetArea())		// Guarda a area do browse.
Local cSim		:= STR0090     								// Indica o sim de acordo com o idioma corrente.
Local lGoTop 	:= .T.										// Posiciona no primeiro registro.

Local lCont		:= .F.
Local ni		:= 0

For ni := 1 to len(aDConfAloc)
	
	lCont := aDConfAloc[ni,1]:cName == 'LBOK' 
	
	If lCont
		exit
	EndIf
	
Next ni

If lCont

	(oMrkAllAtd:Alias())->(DbGoTop())
	
	While (oMrkAllAtd:Alias())->(!Eof())
		If ( !oMrkAllAtd:IsMark() )
			If AllTrim((oMrkAllAtd:Alias())->TMP_DISP) == AllTrim(cSim)
				RecLock(oMrkAllAtd:Alias(),.F.)
				(oMrkAllAtd:Alias())->TMP_OK  := oMrkAllAtd:Mark()
				(oMrkAllAtd:Alias())->(MsUnLock())
			EndIf
		Else
			RecLock(oMrkAllAtd:Alias(),.F.)
			(oMrkAllAtd:Alias())->TMP_OK  := ""
			(oMrkAllAtd:Alias())->(MsUnLock())
		EndIf
		(oMrkAllAtd:Alias())->(DbSkip())
	End
Else
	Help("",1,"At330CMkB1",,STR0253,2,0)//#"Favor selecionar um local"
EndIf

RestArea(aAreaTmp)  
oMrkAllAtd:Refresh(lGoTop)

Return( lRetorno )    

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330AMkB2
Marca / Desmarca todos os atendentes alocados no browse.

@sample 	At330AMkB2(oMrkAtdAlo)

@param		ExpO1 	Objeto FwMarkBrowse atendentes alocados.

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330AMkB2(oMrkAtdAlo)

Local lRetorno	:= .T.									// Retorno da rotina.  
Local aAreaTmp	:= (oMrkAtdAlo:Alias())->(GetArea()) 	// Guarda area do browse. 
Local lGoTop 	:= .T.									// Posiciona no primeiro registro.


(oMrkAtdAlo:Alias())->(DbGoTop())

While (oMrkAtdAlo:Alias())->(!Eof())
	If ( !oMrkAtdAlo:IsMark() )
		RecLock(oMrkAtdAlo:Alias(),.F.)
		(oMrkAtdAlo:Alias())->TMP_OK  := oMrkAtdAlo:Mark()
		(oMrkAtdAlo:Alias())->(MsUnLock())
	Else
		RecLock(oMrkAtdAlo:Alias(),.F.)
		(oMrkAtdAlo:Alias())->TMP_OK  := ""
		(oMrkAtdAlo:Alias())->(MsUnLock())
	EndIf
	(oMrkAtdAlo:Alias())->(DbSkip())
End

RestArea(aAreaTmp) 
oMrkAtdAlo:Refresh(lGoTop)

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GvAlo
Grava a alocacao dos atendentes na tabela ABB.

@sample 	At330GvAlo(aAtdXCalen)

@param		ExpA1 	Array com os atendentes X calendario do RH.
			ExpC2 	Codigo orçamento de serviços
@param 		cMemorando - "0" - Não gera memorandos; "1" - Gera memorandos; " " - Efetua pergunta de confirmação	

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		19/12/2012
@version	P12   
@history 	16/09/2016, Ana Utsumi, Inclusão do parâmetro cMemorando que indica se mensagem de confirmação deve ser exibida ou se resposta recebida por este parâmetro
/*/
//------------------------------------------------------------------------------
Function At330GvAlo(aAtdXCalen,cNrOrcSrv,cTipo, cMemorando,cSituacao)

Local lRetorno 	:= .T.		 			// Retorno da rotina.
Local aAreaABB	:= ABB->(GetArea())  // Area da tabela ABB.
Local nX 		:= 0          			// Incremento utilizado no laco for.
Local nI 		:= 0					// Incremento utilizado no laco for.

// Guarda o Indice da Alocacao do atendente
Local _aAtenABB := {}
Local _cCtrato  := Space(TAMSX3("TFF_CONTRT")[1])
Local cMotCanc  := ""
Local cAliasABB := ""
Local cAliasMNT := ""
Local cAliasBKP := ""
Local aQuery    := {}
Local oMdlManut := Nil
Local lRet      := .F.
Local aErro550  := {}
Local cQryABB 	:= ""
Local lContinua := .T.

Local lCustoTWZ	:= ExistBlock("TecXNcusto")
Local nCusto	:= 0
Local nCustAux	:= 0
Local cCodTWZ 	:= ""
Local aDtIniFIm	:= {}								//Recebe data inicio/fim da agenda do atendente para atualização das tarefas por funcionarios (TN6)
Local lGravaTN6	:= .F.
Local cFuncaoTFF:= ""	
Local lMovimentar	:= FindFunction("TECA336") .AND. (IsInCallStack("TECA336") .Or. IsInCallStack('TEC335CSV'))
Local cFil			:= ""
Local lGrvCustom	:= ExistBlock("AT330GRV")
Local aAgeRes		:= {}
Local lCancAge	 	:= .T.
Default cNrOrcSrv 	:= ""
Default cTipo 	 	:= ""
Default cMemorando 	:= " "

//Verificação para pegar a filial do atendente para gravação
If lMovimentar
	cFil := At336AtdFil()
	aAgeRes := At336AgRes()

	//Verifica se cancela a agenda de reserva ou não.	
	If !Empty(aAgeRes) .And. (aScan(aAgeRes,{|x| x[6] == .T. }) > 0 )
		lCancAge := .F.
	Endif
Else
	cFil := xFilial("AA1")
EndIf

If lCancAge
	cMotCanc  := GetMv("MV_ATMTCAN",,"")
Endif

If Empty(cMotCanc) .And. lCancAge
	If !MsgNoYes(STR0241,STR0242) // "Parâmetro 'MV_ATMTCAN' não está preenchido com um motivo de manutenção para cancelar agendas de reserva. Deseja continuar?" ### "Cancelar Reservas" 
		lContinua := .F.
		lRetorno := .F.
	Else
		Help(,, "AT330CANCRES",,STR0243,1,0,,,,,,{STR0244})  // 'Caso existam agendas de reserva no período não serão canceladas.' ### "Agendas de reserva precisarão ser canceladas manualmente pela rotina de Manutenção de Agendas"
	EndIf
EndIf

If lContinua
	Begin Transaction
	
	DbSelectArea("ABB")
	ABB->(DbSetOrder(1))
	
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))
	
	For nX := 1 To Len(aAtdXCalen)
		
		AA1->(MsSeek(xFilial("AA1")+ aAtdXCalen[nX][1]))
	
		// posicina ABQ
		DbSelectArea("ABQ")
		ABQ->( DbSetOrder( 1 ) ) // ABQ_FILIAL + ABQ_CONTRT + ABQ_ITEM + ABQ_ORIGEM
		ABQ->( DbSeek( xFilial("ABQ")+ aAtdXCalen[nX][7] ) )
			
		// posicina TFF
		DbSelectArea("TFF")
		TFF->( DbSetOrder( 1 ) ) // TFF_FILIAL + TFF_COD
		TFF->( DbSeek( ABQ->( ABQ_FILTFF + ABQ_CODTFF ) ) )

		//Busca o custo do atendente pelo PE ou pelo campo do atendente
		If lCustoTWZ
		
			nCusto := ExecBlock("TecXNcusto",.F.,.F.,;
								{ 1, aAtdXCalen[nX][1], AA1->AA1_FUNFIL, AA1->AA1_CDFUNC,;
								TFF->TFF_CONTRT, TFF->TFF_LOCAL, TFF->TFF_CODPAI, TFF->TFF_COD, aAtdXCalen[nX][7] } )
		Else
		
			nCusto 		:= AA1->AA1_CUSTO
			
		EndIf
		
		If	lSigaMdtGS	//Integração entre o SIGAMDT x SIGATEC	
			cFuncaoTFF 	:= At330Funcao(aAtdXCalen[nX][7])
		Endif 			
		
		For nI := 1 To Len(aAtdXCalen[nX][10])
			RecLock("ABB",.T.)
			Replace ABB->ABB_FILIAL	With xFilial("ABB")
			Replace ABB->ABB_CODIGO	With Iif(FindFunction("AtABBNumCd"),AtABBNumCd(),GetSXENum("ABB","ABB_CODIGO"))
			Replace ABB->ABB_FILTEC WITH cFil
			Replace ABB->ABB_CODTEC	With aAtdXCalen[nX][1]		
					
			If Empty(cNrOrcSrv)
				Replace ABB->ABB_ENTIDA	With "AB7"			
				Replace ABB->ABB_CHAVE	With aAtdXCalen[nX][9]		
				Replace ABB->ABB_NUMOS	With aAtdXCalen[nX][8]
			Else
				Replace ABB->ABB_LOCAL	With aAtdXCalen[nX][12]
			EndIf
			
			Replace ABB->ABB_DTINI	With aAtdXCalen[nX][10][nI][1]
			Replace ABB->ABB_HRINI	With aAtdXCalen[nX][10][nI][3]
			Replace ABB->ABB_DTFIM	With IIF(aAtdXCalen[nX][10][nI][4] < aAtdXCalen[nX][10][nI][3],1,0)+aAtdXCalen[nX][10][nI][1]
			Replace ABB->ABB_HRFIM	With aAtdXCalen[nX][10][nI][4]
			Replace ABB->ABB_HRTOT	With AtTotHora(aAtdXCalen[nX][10][nI][1],aAtdXCalen[nX][10][nI][3],aAtdXCalen[nX][10][nI][1],aAtdXCalen[nX][10][nI][4])
			Replace ABB->ABB_SACRA 	With "S"
			Replace ABB->ABB_CHEGOU	With "N"
			Replace ABB->ABB_ATENDE	With "2"
			Replace ABB->ABB_MANUT	With "2"
			Replace ABB->ABB_ATIVO	With "1"
			Replace ABB->ABB_IDCFAL	With aAtdXCalen[nX][7]
			Replace ABB->ABB_CODTW3	With aAtdXCalen[nX][13]
			Replace ABB->ABB_CODTFF	With TFF->TFF_COD
						
			If !Empty(cTipo)
				Replace ABB->ABB_TIPOMV	With cTipo
			EndIf		

			MsUnLock()
			ConfirmSX8()
				
			If lGrvCustom
				ExecBlock("AT330GRV",.F.,.F.)
			Endif
				
			If	lSigaMdtGS	//Integração entre o SIGAMDT x SIGATEC	
				aAdd(aDtIniFIm,{aAtdXCalen[nX][10][nI][1],IIF(aAtdXCalen[nX][10][nI][4] < aAtdXCalen[nX][10][nI][3],1,0)+aAtdXCalen[nX][10][nI][1]})
			Endif 				
	
			_cCtrato := Substr(aAtdXCalen[nX][7],1,TAMSX3("TFF_CONTRT")[1])
			//Armazena os atendentes
			IF aScan(_aAtenABB,{|X| X[1] = _cCtrato }) = 0
				Aadd(_aAtenABB, {_cCtrato,;
					             ABB->ABB_CODIGO,;
					             DTOS(ABB->ABB_DTINI),;
					             ABB->ABB_HRINI,;
					             DTOS(ABB->ABB_DTFIM),;
					             ABB->ABB_HRFIM})
			ENDIF
		Next nI
		
		If nCusto > 0
			//Realiza a gravação do custo
			At330HasTWZ( aAtdXCalen[nX][7], @cCodTWZ  )
			lRetorno := At330GrvCus( aAtdXCalen[nX][7], cCodTWZ )
			If !lRetorno
				Exit
			EndIf
		EndIf	

		If	lSigaMdtGS	//Integração entre o SIGAMDT x SIGATEC
			At330TarNov( aAtdXCalen[nX,1], aAtdXCalen[nX,12], cFuncaoTFF , aDtIniFIm[1,1], aDtIniFIm[Len(aDtIniFIm),2],,,cSituacao)
		Endif
		 			
	Next nX
	
//Avalia se ja existia agenda previa do tipo RESERVA para manutencao de CANCELAMENTO
	If lRetorno .And. !Empty(cTipo) .And. !Empty(cMotCanc)
	
		dbSelectArea("TCU")
		TCU->(dbSetOrder(1))
		If TCU->(dbSeek(xFilial("TCU")+cTipo )) .And. TCU->TCU_RESTEC <> "1"
	
			For nX := 1 To Len(aAtdXCalen)
			
				For nI := 1 To Len(aAtdXCalen[nX][10])
				
					//Busca as AGENDAS de RESERVA TECNICA para o mesmo periodo, pois serao canceladas automaticamente
					dbSelectArea("ABB")
					ABB->(dbSetOrder(1))
					ABB->(dbSeek(xFilial("ABB")+aAtdXCalen[nX][1]+DToS(aAtdXCalen[nX][10][nI][1]) ))
					While ABB->(!Eof()) .And. ABB->(ABB_FILIAL+ABB_CODTEC+DTOS(ABB_DTINI)) == xFilial("ABB")+aAtdXCalen[nX][1]+DToS(aAtdXCalen[nX][10][nI][1])
						dbSelectArea("TCU")
						TCU->(dbSetOrder(1))
						TCU->(dbSeek(xFilial("TCU")+ABB->ABB_TIPOMV ))
						If TCU->TCU_RESTEC <> '1' .OR. ABB->ABB_ATIVO == "2"
							ABB->(dbSkip())
							Loop
						EndIf
						
						aQuery := AT540ABBQry( ABB->ABB_CODTEC, ABB->ABB_CHAVE, ABB->ABB_DTINI, ABB->ABB_DTFIM, ABB->ABB_HRINI, ABB->ABB_HRFIM, ABB->ABB_CODIGO, .T., ABB->ABB_ENTIDA )
						
						If Len(aQuery) > 0
							cAliasABB := GetNextAlias() 
							cAliasBkp := At550GtAls()
							cQryABB   := aQuery[1]
							dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryABB),cAliasABB)
							AT550StAls(cAliasABB)
						
							oMdlManut := FWLoadModel( "TECA550" )	
						
							oMdlManut:SetOperation(3)
							lRet := oMdlManut:Activate()
						
							If lRet		
								oMdlManut:SetValue( 'ABRMASTER', 'ABR_MOTIVO'	, cMotCanc)
								oMdlManut:SetValue( 'ABRMASTER', 'ABR_DTINI'	, ABB->ABB_DTINI)
								oMdlManut:SetValue( 'ABRMASTER', 'ABR_HRINI'	, ABB->ABB_HRINI)
								oMdlManut:SetValue( 'ABRMASTER', 'ABR_DTFIM'	, ABB->ABB_DTFIM)
								oMdlManut:SetValue( 'ABRMASTER', 'ABR_HRFIM'	, ABB->ABB_HRFIM)
								oMdlManut:SetValue( 'ABRMASTER', 'ABR_OBSERV'	, STR0221) //"Manutencao pela alocacao de reserva tecnica via contrato"
							
								lRet := oMdlManut:VldData() .And. oMdlManut:CommitData()
								If ( !lRet )
									aErro550   := oMdlManut:GetErrorMessage()
									Help( ,, 'At330GvAlo_CancAutom',, aErro550[MODEL_MSGERR_MESSAGE], 1, 0 )
								EndIf
							EndIf
							
							oMdlManut:DeActivate()
							oMdlManut:Destroy()
							At550StAls(cAliasBKP)	
							
						EndIf
						
						ABB->(dbSkip())
					EndDo
						
				Next nI
			
			Next nX
		
		EndIf
	EndIf
	
	IF Len(_aAtenABB) > 0
		If (cMemorando=="1") .Or. (cMemorando=" " .And. MSGYESNO( STR0218,STR0217 )) //"Deseja realmente gerar os memorandos?" # "Memorando"
			// Filtra os contratos/revisao dos atendentes.
			At330FilCt(_aAtenABB)
		EndIf
	EndIf

	If !lRetorno
		DisarmTransaction()
		Break
	EndIf

	End Transaction
	RestArea(aAreaABB) 
EndIf

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VdDes
Valida o browse atendentes alocados.

@sample 	At330VdDes(oMrkAtdAlo)  

@param		ExpO1 	Objeto FwMarkBrowse atendentes alocados.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VdDes(oMrkAtdAlo)

Local lRetorno := .F.     								// Retorno da validacao.     
Local aAreaTmp := (oMrkAtdAlo:Alias())->(GetArea()) 	// Guarda a area do browse.

(oMrkAtdAlo:Alias())->(DbGoTop())

While (oMrkAtdAlo:Alias())->(!Eof())
	If !Empty((oMrkAtdAlo:Alias())->TMP_OK)
		lRetorno := .T.
		Exit
	EndIf
	(oMrkAtdAlo:Alias())->(DbSkip())
End

If !lRetorno
	MsgStop(STR0124,STR0125)   // "Não há atendentes marcados para desalocar."#"Atenção"
EndIf

RestArea(aAreaTmp) 

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330Deslo
Desaloca os atendentes selecionados no browse(Atendentes Alocados).

@sample 	At330Deslo(dAlocDe,dAlocAte,oMrkAllAtd,aMrkAllAtd,cItCbxSel,oMrkAtdAlo,aMrkAtdAlo,oTreeOS,aConfAloc,oLbxCfgAlo,oTreeDtFil,lTecXRh)

@param		ExpD1 	Alocacao De.
			ExpD2	Alocacao Ate.	
			ExpO1 	Objeto FwMarkBrowse atendentes.
			ExpA2	Array com atendentes do Gestao de Servicos.
			ExpC3	Item selecionado no objeto ComboBox.
			ExpO4 	Objeto FwMarkBrowse atendentes alocados.
			ExpA5 	Array com os atendentes alocados.
			ExpO6 	Objeto DBTree Ordem de Servico. 
			ExpA7 	Array com a Configuracao da Alocacao.
			ExpO8 	Objeto ListBox Configuracao da Alocacao.
			ExpO9	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpL10	Integracao Gestao de Servicos com RH?  
			ExpC11 	Codigo orçamento de serviços
			
@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------       
Static Function At330Deslo(dAlocDe,dAlocAte,oMrkAllAtd,aMrkAllAtd,cItCbxSel,oMrkAtdAlo,aMrkAtdAlo,oTreeOS,aConfAloc,oLbxCfgAlo,oTreeDtFil,lTecXRh,cNrOrcSrv)

Local lRetorno 		:= .T.										// Retorno da rotina.
Local aAreaTmp 		:= (oMrkAtdAlo:Alias())->(GetArea())  		// Guarda a area do browse.
Local nPosAtd		:= 0  										// Posicao do atendente no array aAtdXAgend. 
Local aAgenda		:= {}										// Array com a agenda do atendente.
Local aAtdXAgend	:= {}										// Atendente X Agenda.
Local nPosCfgAlo 	:= 0										// Posicao da configuracao da alocacao no array aConfAloc.
Local nPosItOS 		:= 0 										// Posicao do item da O/S selecionado no Tree de OS.
Local nTotAlo 		:= 0										// Total de horas alocadas.
Local cHrsCtrt		:= ""										// Total de horas contratadas no configurador (Caracter).
Local nHrsCtrt		:= 0  										// Total de horas contratadas no configurador (Numerico).										
Local cHrsAloc		:= "" 										// Total de horas alocadas no configurador (Caracter).										
Local nHrsAloc		:= 0 										// Total de horas alocadas no configurador (Numerico).
Local cSldHrs		:= ""										// Saldo de horas no configurador (Caracter).
Local nSldHrs		:= 0										// Saldo de horas no configurador (Numerico).
Local aSaldoCfg 	:= {} 										// Saldo de horas apos desalocar os atendentes.
Local nX 			:= 0 										// Incremento utilizado no laco for.
Local nOpcA			:= 0										// Opcao escolhida pelo usuario (1-Confirmar ou 2-Fechar).

Default cNrOrcSrv := ""
    
If Empty(cNrOrcSrv)
	nPosItOS 	:= aScan(oTreeOS:Cargo,{|x| x[1] == AllTrim(oTreeOS:GetCargo()) .AND. x[2] == "ITEM" })
EndIf

(oMrkAtdAlo:Alias())->(DbGoTop())

While (oMrkAtdAlo:Alias())->(!Eof())
	If !Empty((oMrkAtdAlo:Alias())->TMP_OK )
		
		nPosAtd := aScan(aAtdXAgend,{|x| x[1] == (oMrkAtdAlo:Alias())->TMP_CODTEC })
		
		If nPosAtd == 0			
				
			aAgenda := At330GtABB((	oMrkAtdAlo:Alias())->TMP_CODTEC,;
										Iif(Empty(cNrOrcSrv), oTreeOS:Cargo[nPosItOS][5] , Nil),;
										Iif(Empty(cNrOrcSrv), Nil, aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg]))
										
			If ( Len(aAgenda) > 0 )
				aAdd(aAtdXAgend,{	(oMrkAtdAlo:Alias())->TMP_CODTEC 	,;
									(oMrkAtdAlo:Alias())->TMP_NOMTEC	,;
									(oMrkAtdAlo:Alias())->TMP_CDFUNC	,;
									(oMrkAtdAlo:Alias())->TMP_TURNO	  	,;
									(oMrkAtdAlo:Alias())->TMP_FUNCAO 	,;
									(oMrkAtdAlo:Alias())->TMP_CARGO		,;
									aAgenda[1]                          ,;
									aAgenda[2]                          ,;
									aAgenda[3]	 							})
									nTotAlo += aAgenda[2]
			EndIf
		EndIf
	EndIf
	
	(oMrkAtdAlo:Alias())->(DbSkip())
End

If Len(aAtdXAgend) > 0
	
	nOpcA := At330MntDS(aAtdXAgend,nTotAlo,lTecXRh,@aSaldoCfg)
	
	If 	nOpcA == 1
		For nX := 1 To Len(aSaldoCfg)
			nPosCfgAlo	:= aScan(aConfAloc,{|x| AllTrim(x[nPosIdCfg]) == AllTrim(aSaldoCfg[nX][1]) })
			If nPosCfgAlo > 0
				cHrsCtrt := StrTran(aConfAloc[nPosCfgAlo][nPosHrsCtr],".","")
				nHrsCtrt  := Val(StrTran(cHrsCtrt,",","."))
				
				cHrsAloc := StrTran(aConfAloc[nPosCfgAlo][nPosHrsAlo],".","")
				nHrsAloc  := Val(StrTran(cHrsAloc,",","."))
				
				cSldHrs := StrTran(aConfAloc[nPosCfgAlo][nPosSaldo],".","")
				nSldHrs	:= Val(StrTran(cSldHrs,",","."))
								
				aConfAloc[nPosCfgAlo][nPosSaldo]  := Transform(( nSldHrs + aSaldoCfg[nX][2] ),PesqPict("ABQ","ABQ_SALDO"))
				aConfAloc[nPosCfgAlo][nPosHrsAlo] := Transform(( nHrsCtrt - ( nSldHrs + aSaldoCfg[nX][2] ) ),PesqPict("ABQ","ABQ_TOTAL"))
				oLbxCfgAlo:Refresh()
			EndIf
		Next nX

		MsgRun(STR0091, STR0092, {||( At330ClrDt(oTreeDtFil),; // "Atualizado o browse atendentes"#"Aguarde"
		                              ApagarTemp(oMrkAllAtd:Alias()),;
		                              aMrkAllAtd := ListarApoio(dAlocDe /*dIniAloc*/,;
		                                                        dAlocAte /*dFimAloc*/,;
		                                                        IIF(lTecXRh, At330GTree(oTreeDtFil,"FILCAR"), Nil) /*aCargos*/,;
		                                                        At330GTree(oTreeDtFil,"FILFUN") /*aFuncoes*/,;
		                                                        At330GTree(oTreeDtFil,"FILHAB") /*aHabil*/,;
		                                                        /*cDisponib*/,;
		                                                        /*cContIni*/,;
		                                                        /*cContFim*/,;
		                                                        At330GTree(oTreeDtFil,"FILCC")[1] /*cCCusto*/,;
		                                                        cItCbxSel /*cLista*/,;
		                                                        /*nLegenda*/,;
		                                                        /*cItemOS*/,;
		                                                        At330GTree(oTreeDtFil,"FILTUR") /*aTurnos*/,;
		                                                        At330GTree(oTreeDtFil,"FILREG") /*aRegiao*/,;
		                                                        /*lEstrut*/,;
		                                                        /*aPeriodos*/,;
		                                                        /*cIdCfAbq*/,;
		                                                        /*cLocOrc*/,;
		                                                        At330GTree(oTreeDtFil,"FILSEQ") /*aSeqTrn*/,;
		                                                        /*aPeriodRes*/,;
		                                                        /*cLocalAloc*/,;
		                                                        At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
		                                                        At330GTree(oTreeDtFil,"FILCUR") /*aCursos*/),;		
		                              At330AtBrw(oMrkAllAtd, aMrkAllAtd[1]))})
		If Empty(cNrOrcSrv)
			MsgRun(STR0126, STR0121, {|| ApagarTemp(oMrkAtdAlo:Alias()),; // "Atualizado o browse atendentes alocados..."#"Aguarde"
			                             aMrkAtdAlo := ListarApoio(/*dIniAloc*/,;
			                                                       /*dFimAloc*/,;
			                                                       /*aCargos*/,;
			                                                       /*aFuncoes*/,;
			                                                       /*aHabil*/,;
			                                                       "A" /*cDisponib*/,;
			                                                       /*cContIni*/,;
			                                                       /*cContFim*/,;
			                                                       /*cCCusto*/,;
			                                                       "3" /*cLista*/,;
			                                                       2 /*nLegenda*/,;
			                                                       oTreeOS:Cargo[nPosItOS][5] /*cItemOS*/,;
			                                                       /*aTurnos*/,;
			                                                       /*aRegiao*/,;
			                                                       /*lEstrut*/,;
			                                                       /*aPeriodos*/,;
			                                                       /*cIdCfAbq*/,;
			                                                       /*cLocOrc*/,;
			                                                       /*aSeqTrn*/,;
			                                                       /*aPeriodRes*/,;
			                                                       /*cLocalAloc*/,;
			                                                       /*aCarac*/,;
			                                                       /*aCursos*/),;
			                             At330AtBrw(oMrkAtdAlo, aMrkAtdAlo[1])})
		Else
			MsgRun(STR0126, STR0121, {|| ApagarTemp(oMrkAtdAlo:Alias()),; // "Atualizado o browse atendentes alocados..."#"Aguarde"
			                             aMrkAtdAlo := ListarApoio(/*dIniAloc*/,;
			                                                       /*dFimAloc*/,;
			                                                       /*aCargos*/,;
			                                                       /*aFuncoes*/,;
			                                                       /*aHabil*/,;
			                                                       "A" /*cDisponib*/,;
			                                                       /*cContIni*/,;
			                                                       /*cContFim*/,;
			                                                       /*cCCusto*/,;
			                                                       "3" /*cLista*/,;
			                                                       2 /*nLegenda*/,;
			                                                       /*cItemOs*/,;
			                                                       /*aTurnos*/,;
			                                                       /*aRegiao*/,;
			                                                       /*lEstrut*/,;
			                                                       /*aPeriodos*/,;
			                                                       aConfAloc[oLbxCfgAlo:nAt][nPosIdCfg] /*cIdCfAbq*/,;
			                                                       aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocOrc*/,;
			                                                       /*aSeqTrn*/,;
			                                                       /*aPeriodRes*/,;
			                                                       /*cLocalAloc*/,;
			                                                       /*aCarac*/,;
			                                                       /*aCursos*/),;
			                             At330AtBrw(oMrkAtdAlo, aMrkAtdAlo[1])})
		Endif			
		
		
	EndIf
Else
	lRetorno := .F.
	MsgStop(STR0127+chr(10)+STR0183,STR0125)   // "Não será possível desalocar."+"Verifique os agendamentos dos atendentes marcado no browse."#""Atenção" 
EndIf

RestArea(aAreaTmp)

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GtABB
Busca a agenda do atendente na ABB.

@sample 	At330GtABB(cCodAtend,cItemOS,cNrOrcSrv)

@param		ExpC1 	Atendente
			ExpC2 	Item da O/S.
			ExpC3	Codigo do relacionamento da ABQ

@return		ExpA 	Agenda do Atendente / Totais

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330GtABB(cCodAtend,cItemOS,cIdCFal)

Local aAreaABB 	 := ABB->(GetArea())   // Guarda area atual da tabela ABB.
Local aAgenda 	 := {}  				// Array com  a agenda do atendente.
Local nHrsTrb := 0					    // Horas trabalhadas.
Local nTotalHrs	 := 0					// Total de horas alocada.					 
Local nTotAgend	 := 0					// Total de agendamentos.					
Local aRet 		 := {}					// Array com agenda,total de horas e total de agendamentos.
Local cAliasABB	 := GetNextAlias()	
Local cWhere		 := ""

Default cIdCFal := ""

If Empty(cIdCFal)
	cWhere := "%ABB.ABB_ENTIDA = 'AB7' AND LTrim(RTrim(ABB.ABB_CHAVE)) = '" + cItemOS + "'%"
Else
	cWhere := "%ABB.ABB_IDCFAL ='" + cIdCFal + "'%"
EndIf

BeginSql Alias cAliasABB
      
   SELECT ABB.ABB_DTINI, ABB.ABB_HRINI, ABB.ABB_DTFIM, ABB.ABB_HRFIM
   FROM %table:ABB% ABB 
   WHERE	ABB.ABB_FILIAL	= %xFilial:ABB% 		AND
   			ABB.ABB_CODTEC	= %Exp:cCodAtend% 	AND	
   			ABB.ABB_ATENDE 	= "2" 					AND 
   			ABB.ABB_ATIVO 	= "1" 					AND
   			ABB.%NotDel% 								AND  
   			%Exp:cWhere%
   			   			          
EndSql

While (cAliasABB)->(!Eof())
	
	nHrsTrb := SubtHoras(sTod(	(cAliasABB)->ABB_DTINI),;
						   		 	(cAliasABB)->ABB_HRINI,;
						   	sTod(	(cAliasABB)->ABB_DTFIM),;
						   			(cAliasABB)->ABB_HRFIM)						   	
						   	
	aAdd(aAgenda,{.F.,	sTod(	(cAliasABB)->ABB_DTINI),;
					 				(cAliasABB)->ABB_HRINI,;
					 		sTod(	(cAliasABB)->ABB_DTFIM),;
					 				(cAliasABB)->ABB_HRFIM,;
					 		IntToHora(nHrsTrb)})
					 		
	nTotalHrs += nHrsTrb
	nTotAgend += 1	
	
	(cAliasABB)->(dbSkip())
		
End

(cAliasABB)->(dbCloseArea())

If Len(aAgenda) > 0
	aRet := {aAgenda,nTotalHrs,nTotAgend}
EndIf

RestArea(aAreaABB)

Return( aRet )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330MntDS
Monta a interface para desalocar os atendentes.

@sample 	At330MntDS(aAtdXAgend,nTotAloc,lTecXRh,aSaldoCfg)

@param		ExpA1 	Atendente X Agenda
			ExpN2	Total de horas alocadas.
			ExpL3	Integracao Gestao de Servicos com RH?  
			ExpA4	Array com saldo de horas por configuracao de alocacao.

@return		ExpN 	Opcao escolhida pelo usuario (Confirmar ou Fechar).

@author		Anderson Silva
@since		19/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330MntDS(aAtdXAgend,nTotAloc,lTecXRh,aSaldoCfg)

Local oDlg 			:= Nil     											// Janela principal.
Local aSize     	:= MsAdvSize()										// Dimensao da janela criada pelo Protheus.
Local aObjects  	:= {{100,100,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     	:= {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   	:= MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local oFWLayer		:= Nil												// Objeto FwLayer.
Local oDlgAtend		:= Nil												// Janela atendente.
Local oDlgAgend		:= Nil 												// Janela agenda do atendente.
Local oBrwAtend		:= Nil 												// Browse do atendente. 
Local oBrwAgend		:= Nil 												// Browse agenda do atendente.
Local oColAtend 	:= Nil												// Coluna do browse atendente.
Local oColAgend		:= Nil 												// Coluna do browse agenda atendente. 
Local oDlgInfAge	:= Nil												// Janela informacoes da agenda.
Local oDlgTotais	:= Nil 												// Janela totais.
Local oMGHrsAlo  	:= Nil  											// Objeto MsGet horas alocadas.
Local nHrsAlo 	 	:= aAtdXAgend[1][8]   								// Horas alocadas.
Local oMGHrsDes  	:= Nil  											// Objeto MsGet horas a desalocar.
Local nHrsDes    	:= 0												// Horas a desalocar.
Local oMGTotAgen 	:= Nil												// Objeto MsGet total de agendamentos.
Local nTotAgend  	:= aAtdXAgend[1][9]  								// Total de agendamentos.
Local oMGTotAlo  	:= Nil  											// Objeto MsGet total de horas alocadas
Local nTotAlo	 	:= nTotAloc                                        	// Total de horas alocadas.
Local oMGTotDes  	:= Nil 												// Objeto MsGet total de horas a desalocar.
Local nTotDes    	:= 0												// Total de horas a desalocar.
Local nOpcA			:= 0												// Opcao escolhida pelo usuario (1-Confirmar ou 2-Fechar).
Local aButtons      := {}                                              	// Botoes da EnchoiceBar.
Local lGoTop 		:= .T.												// Posiciona no primeiro registro.


DEFINE MSDIALOG oDlg TITLE STR0128 From aSize[7],aSize[2] TO aSize[6],aSize[5] OF oMainWnd PIXEL  // "Agenda dos Atendentes"

	oFWLayer := FWLayer():New()
	oFWLayer:Init(oDlg,.F.)
	         
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Janela configuracao para alocacao. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oFWLayer:AddLine("LINEATD",40,.F.)
	oFWLayer:AddCollumn("ATEND",100,.F.,"LINEATD")
	oFWLayer:AddWindow("ATEND","oDlgAtend",STR0129,100,.F.,.F.,,"LINEATD",{||})   // "Atendentes"

	oDlgAtend := oFWLayer:GetWinPanel("ATEND","oDlgAtend","LINEATD")


	DEFINE FWBROWSE oBrwAtend DATA ARRAY ARRAY aAtdXAgend LINE BEGIN 1 OF oDlgAtend

		ADD COLUMN oColAtend DATA &("{ || aAtdXAgend[oBrwAtend:At()][1] }") TITLE STR0098 SIZE TamSX3("AA1_CODTEC")[1] OF oBrwAtend          														// "Atendente"
		ADD COLUMN oColAtend DATA &("{ || aAtdXAgend[oBrwAtend:At()][2] }") TITLE STR0099 SIZE TamSX3("AA1_NOMTEC")[1] OF oBrwAtend   	 															// "Nome do Atend."
		ADD COLUMN oColAtend DATA &("{ || aAtdXAgend[oBrwAtend:At()][3] }") TITLE STR0100 SIZE TamSX3("AA1_CDFUNC")[1]  OF oBrwAtend     															// "Cód.Func."
		ADD COLUMN oColAtend DATA &("{ || aAtdXAgend[oBrwAtend:At()][4] }") TITLE STR0101 SIZE TamSX3("AA1_TURNO")[1]  OF oBrwAtend          														// "Turno"
		ADD COLUMN oColAtend DATA &("{ || Alltrim(FDESC('SR6',aAtdXAgend[oBrwAtend:At()][4],'R6_DESC'))}") TITLE STR0102 SIZE TamSX3("R6_DESC")[1]  OF oBrwAtend 									// "Descrição"
		ADD COLUMN oColAtend DATA &("{ || aAtdXAgend[oBrwAtend:At()][5] }") TITLE STR0103 SIZE TamSX3("AA1_FUNCAO")[1] OF oBrwAtend           														// "Função" 
		ADD COLUMN oColAtend DATA &("{ || Alltrim(FDESC('SRJ',aAtdXAgend[oBrwAtend:At()][5],'RJ_DESC',,ABQ->ABQ_FILIAL)) }") TITLE STR0102 SIZE TamSX3("RJ_DESC")[1]  OF oBrwAtend      			// "Descrição"
		
		If lTecXRh
			ADD COLUMN oColAtend DATA &("{ || aAtdXAgend[oBrwAtend:At()][6] }") TITLE STR0104 SIZE TamSX3("RA_CARGO")[1]  OF oBrwAtend      													 	// "Cargo"
			ADD COLUMN oColAtend DATA &("{ || Alltrim(FDESC('SQ3',aAtdXAgend[oBrwAtend:At()][6],'Q3_DESCSUM',,ABQ->ABQ_FILIAL)) }") TITLE STR0105 SIZE TamSX3("Q3_DESCSUM")[1]  OF oBrwAtend   		// "Descrição"
		EndIf

	ACTIVATE FWBROWSE oBrwAtend

	oFWLayer:AddLine("LINEAGEN",40,.F.)
	oFWLayer:AddCollumn("PAGENDA",100,.F.,"LINEAGEN")
	oFWLayer:AddWindow("PAGENDA","oDlgAgend",STR0130,100,.F.,.F.,,"LINEAGEN",{||}) // "Agendamentos do Atendente"
	
	oDlgAgend := oFWLayer:GetWinPanel("PAGENDA","oDlgAgend","LINEAGEN")
	

	DEFINE FWBROWSE oBrwAgend DATA ARRAY ARRAY aAtdXAgend[1][7] LINE BEGIN 1 OF oDlgAgend

		ADD MARKCOLUMN oColPAgend DATA &('{ || IIf(aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][1],"BR_BRANCO","BR_PRETO") }') ;
		DOUBLECLICK { |oBrwAgend| aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][1] := !aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][1],;
		At330AtInf(oBrwAtend,oBrwAgend,aAtdXAgend,oMGHrsDes,@nHrsDes,oMGTotDes,@nTotDes,.F.) } HEADERCLICK { |oBrwAgend| ,;
		AEval(aAtdXAgend[oBrwAtend:At()][7],{|x| x[1] := !x[1]}),;
		At330AtInf(oBrwAtend,oBrwAgend,aAtdXAgend,oMGHrsDes,@nHrsDes,oMGTotDes,@nTotDes,.T.),oBrwAgend:Refresh(lGoTop) } OF oBrwAgend
		
		ADD COLUMN oColPAgend DATA &("{ || aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][2] }") TITLE STR0131 SIZE 5 ALIGN 1 OF oBrwAgend
		ADD COLUMN oColPAgend DATA &("{ || aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][3] }") TITLE STR0132 SIZE 5 ALIGN 1 OF oBrwAgend
		ADD COLUMN oColPAgend DATA &("{ || aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][4] }") TITLE STR0133 SIZE 5 ALIGN 1 OF oBrwAgend
		ADD COLUMN oColPAgend DATA &("{ || aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][5] }") TITLE STR0134 SIZE 5 ALIGN 1 OF oBrwAgend
		ADD COLUMN oColPAgend DATA &("{ || aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][6] }") TITLE STR0135 SIZE 5 ALIGN 1 OF oBrwAgend
		
	ACTIVATE FWBROWSE oBrwAgend

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Janela configuracao para alocacao. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oFWLayer:AddLine("LINEINFTOT",20,.F.)
	oFWLayer:AddCollumn("INFOAGEN",60,.F.,"LINEINFTOT")
	oFWLayer:AddCollumn("TOTAIS",40,.F.,"LINEINFTOT")
	oFWLayer:AddWindow("INFOAGEN","oDlgInfAge",STR0136,100,.F.,.F.,,"LINEINFTOT",{|| })  	// "Informações do Agendamento"
	oFWLayer:AddWindow("TOTAIS","oDlgTotais",STR0137,100,.F.,.F.,,"LINEINFTOT",{|| })    	// "Totais"

	oDlgInfAge  := oFWLayer:GetWinPanel("INFOAGEN","oDlgInfAge","LINEINFTOT")
	oDlgTotais := oFWLayer:GetWinPanel("TOTAIS","oDlgTotais","LINEINFTOT")


	@002,001 SAY STR0138 SIZE 50,10 OF oDlgInfAge PIXEL        																// "Horas Alocadas:" 
	@001,047 MSGET oMGHrsAlo VAR nHrsAlo PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgInfAge PIXEL
	
	@002,115 SAY STR0139 SIZE 50,10 OF oDlgInfAge PIXEL              										   				// "Horas à Desalocar:"
	@001,167 MSGET oMGHrsDes VAR nHrsDes PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgInfAge PIXEL
	
	@002,235 SAY STR0140 SIZE 50,10 OF oDlgInfAge PIXEL               														// "Agendamentos:"
	@001,278 MSGET oMGTotAgen VAR nTotAgend PICTURE "@!"  WHEN .F.  SIZE 60,5 OF oDlgInfAge PIXEL
	
	@002,001 SAY STR0141 SIZE 50,10 OF oDlgTotais PIXEL      																// "Horas Alocadas:"
	@001,044 MSGET oMGTotAlo VAR nTotAlo PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgTotais PIXEL
	
	@002,108 SAY STR0142  SIZE 50,10 OF oDlgTotais PIXEL         											  				// "Horas à Desalocar:"
	@001,162 MSGET oMGTotDes VAR nTotDes PICTURE PesqPict("ABQ","ABQ_SALDO")  WHEN .F.  SIZE 60,5 OF oDlgTotais PIXEL

	oBrwAtend:SetChange({||	oBrwAgend:SetArray(aAtdXAgend[oBrwAtend:At()][7]), oBrwAgend:Refresh(lGoTop),;
	At330AtInf(oBrwAtend,oBrwAgend,aAtdXAgend,oMGHrsDes,@nHrsDes,oMGTotDes,@nTotDes,.T.),;
	(nTotAgend := aAtdXAgend[oBrwAtend:At()][9],oMGTotAgen:CtrlRefresh()),;
	(nHrsAlo := aAtdXAgend[oBrwAtend:At()][8],oMGHrsAlo:CtrlRefresh())})
	
	aAdd(aButtons, {"", {|| IIF(At330IDesP(oBrwAtend,oBrwAgend,aAtdXAgend),;
	At330AtInf(oBrwAtend,oBrwAgend,aAtdXAgend,oMGHrsDes,@nHrsDes,oMGTotDes,@nTotDes,.T.),Nil) },;
	STR0143,STR0143}) //"Deslocar por Período"     
	
	aAdd(aButtons, {"", {|| At330LDspe() },STR0155,STR0155})	// "Legenda"     

	EnchoiceBar(oDlg, {|| IIF(At330VdIDs(aAtdXAgend),(MsgRun(STR0144,STR0145,{|| nOpcA := 1,aSaldoCfg := At330GvDes(aAtdXAgend) }),oDlg:End()),Nil)},{|| nOpcA := 2,oDlg:End() },,aButtons)  // "Desalocando os atendentes..."#"Aguarde" 
	                     
ACTIVATE DIALOG oDlg CENTERED

Return( nOpcA )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330MntDS
Atualiza as informacoes os da interface agenda dos atendentes.

@sample 	At330AtInf( oBrwAtend,oBrwAgend,aAtdXAgend,oMGHrsDes,nHrsDes,;
						oMGTotDes,nTotDes,lAllLine )  

@param		ExpO1 	Browse do atendente.
			ExpO2 	Browse agendamentos do atendente.
			ExpA3	Array Atendente X Agendamentos.
			ExpO4	MsGet horas a desalocar.
			ExpC5	Horas a desalocar. 
			ExpO6	MsGet total de horas a desalocar.
			ExpC7	Horas total a desalocar.
			ExpL8	Avalia todas as linhas do Browse?

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		20/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330AtInf( oBrwAtend,oBrwAgend,aAtdXAgend,oMGHrsDes,nHrsDes,oMGTotDes,nTotDes,lAllLine )    

Local lRetorno	:= .T. 			// Retorno da rotina.
Local nX 		:= 0 			// Incremento utilizado no for.
Local nI		:= 0			// Incremento utilizado no for

Default lAllLine := .F. 		// Avalia todas as linhas do Browse?

If lAllLine
	(nHrsDes := 0,oMGHrsDes:CtrlRefresh())
	(nTotDes := 0,oMGTotDes:CtrlRefresh())
	
	For nI := 1 To Len(aAtdXAgend[oBrwAtend:At()][7])
		If aAtdXAgend[oBrwAtend:At()][7][nI][1]
			nHrsDes += HoraToInt(aAtdXAgend[oBrwAtend:At()][7][nI][6])
		EndIf
	Next nI
	
	For nX := 1 To Len(aAtdXAgend)
		For nI := 1 To Len(aAtdXAgend[nX][7])
			If aAtdXAgend[nX][7][nI][1]
				nTotDes += HoraToInt(aAtdXAgend[nX][7][nI][6])
			EndIf
		Next nI
	Next nX
Else
	If aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][1]
		nHrsDes += HoraToInt(aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][6])
		nTotDes += HoraToInt(aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][6])
	Else
		nHrsDes -= HoraToInt(aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][6])
		nTotDes -= HoraToInt(aAtdXAgend[oBrwAtend:At()][7][oBrwAgend:At()][6])
	EndIf
EndIf

oMGHrsDes:CtrlRefresh()
oMGTotDes:CtrlRefresh()

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GvDes
Desaloca os atendentes na tabela ABB.

@sample 	At330GvDes(aAtdXAgend)

@param		ExpA1 	Array Atendente X Agendamentos.

@return		ExpA 	Saldo de horas por configuracao de alocacao

@author		Anderson Silva
@since		20/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330GvDes(aAtdXAgend)

Local aAreaABB	:= ABB->(GetArea()) 	// Guarda area atual da tabela ABB. 
Local aAreaABR	:= ABR->(GetArea()) 	// Guarda area atual da tabela ABR. 
Local nX 		:= 0					// Incremento utilizado no laco for.
Local nI		:= 0					// Incremento utilizado no laco for
Local nTotDes   := 0					// Total de horas a desalocar.
Local aSaldoCfg	:= {}					// Array com saldo de horas por configuracao de alocacao.
Local nPos		:= 0					// Posicao da configuracao da alocacao no array aSaldoCfg.
Local lRetorno 	:= .T.
Local aDelTarCom:= {}								//Array contendo agenda -> Exclusão (descolamento completo)
Local aDelTarPar:= {}								//Array contendo agenda -> Exclusão (descolamento parcial)
Local dDtIni 	:= Ctod("//") 
Local dDtFim	:= Ctod("//")
Local lEscala 	:= .F.
Local cTpExclui	:= ""
					 
DbSelectArea("ABB")
DbSetOrder(1)

DbSelectArea("ABR") 
DbSetOrder(1)

Begin Transaction

For nX := 1 To Len(aAtdXAgend)
	For nI := 1 To Len(aAtdXAgend[nX][7])
		If aAtdXAgend[nX][7][nI][1]   
			//ABB_FILIAL+ABB_CODTEC+DTOS(ABB_DTINI)+ABB_HRINI+DTOS(ABB_DTFIM)+ABB_HRFIM
			If ABB->( DbSeek(xFilial("ABB")+aAtdXAgend[nX][1]+dTos(aAtdXAgend[nX][7][nI][2])+;
					  aAtdXAgend[nX][7][nI][3]+dTos(aAtdXAgend[nX][7][nI][4])+aAtdXAgend[nX][7][nI][5]) )
				ABB->(RecLock("ABB",.F.))
				ABB->(DbDelete())
				ABB->(MsUnlock())
				If	lSigaMdtGS	//Integração entre o SIGAMDT x SIGATEC
					aAdd(aDelTarCom,{ABB->ABB_DTINI, ABB->ABB_DTFIM })	//Compoem agenda para exclusao exclusao (deslocamento) completa
				Endif 					
				If ABR->(DbSeek(xFilial("ABR")+ABB->ABB_CODIGO))
					While ABR->(!Eof()) .AND. ABR->ABR_FILIAL == xFilial("ABR") .AND.  ABR->ABR_AGENDA == ABB->ABB_CODIGO
						ABR->(RecLock("ABR",.F.))
						ABR->(DbDelete())
						ABR->(MsUnlock())
						ABR->(DbSkip())
					End
				EndIf
				nPos := aScan(aSaldoCfg,{|x| x[1] == ABB->ABB_IDCFAL})
				If nPos == 0
					aAdd(aSaldoCfg,{ABB->ABB_IDCFAL,HoraToInt(aAtdXAgend[nX][7][nI][6])})
				Else
					aSaldoCfg[nPos][2] += HoraToInt(aAtdXAgend[nX][7][nI][6])
				EndIf
			EndIf
		Else

			If	lSigaMdtGS	//Integração entre o SIGAMDT x SIGATEC
				If ABB->( DbSeek(xFilial("ABB")+aAtdXAgend[nX][1]+dTos(aAtdXAgend[nX][7][nI][2])+;
					  aAtdXAgend[nX][7][nI][3]+dTos(aAtdXAgend[nX][7][nI][4])+aAtdXAgend[nX][7][nI][5]) )
					aAdd(aDelTarPar,{ABB->ABB_DTINI, ABB->ABB_DTFIM })	//Compoem agenda exclusao (deslocamento) parcial
				Endif 					
			Endif 				
		
		EndIf
	Next nI
	
	If	lSigaMdtGS	//Integração entre o SIGAMDT x SIGATEC
	
		If	IsInCallStack("TECA580B")
			lEscala := .T.
		Endif 
		
		If	Len(aDelTarPar) > 0 
			dDtIni 		:= aDelTarPar[1,1] 
			dDtFim		:= aDelTarPar[Len(aDelTarPar),2]
			cTpExclui	:= "P"
		Else 			
			dDtIni 		:= aDelTarCom[1,1] 
			dDtFim		:= aDelTarCom[Len(aDelTarCom),2]
			cTpExclui	:= "C"
		Endif

//		Regras abaixo desabilitadas devido ao uso do JOB de alocação da GP, caso necessário habilitar** - Eduardo Gomes Júnior 		
//		If	lEscala .AND. nX = Len(aAtdXAgend)
//			At330TarNov(aAtdXAgend[nX,1], ABB->ABB_LOCAL , aAtdXAgend[nX,5], dDtIni, dDtFim, .T. , "C" )
//		Endif
//		
//		If	!lEscala
//			At330TarNov(aAtdXAgend[nX,1], ABB->ABB_LOCAL , aAtdXAgend[nX,5], dDtIni, dDtFim, .T. , cTpExclui)
//		Endif 			 		
		
	Endif 			
	
	//Atualiza o Saldo do custo
	lRetorno := At330GrvCus( ABB->ABB_IDCFAL, ABB->ABB_CODTWZ, .T. )
	If !lRetorno
		Exit
	EndIf
Next nX

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Devolve o saldo de horas para configuracao da alocacao. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lRetorno
	For nX := 1 To Len(aSaldoCfg)	
		TxSaldoCfg(aSaldoCfg[nX][1],aSaldoCfg[nX][2],.T.)
	Next nX
Else
	DisarmTransaction()
	Break
EndIf

End Transaction

RestArea(aAreaABB)
RestArea(aAreaABR)

Return( aSaldoCfg )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VMCfg
Verifica se ha pelo menos uma configuracao de alocacao marcada.

@sample 	At330VMCfg(aConfAloc)

@param		ExpA1 	Array com a configuracao da alocacao.

@return		ExpL Verdadeiro / Falso

@author		Anderson Silva
@since		20/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VMCfg(aConfAloc)

Local lRetorno	:= .F.		// Retorno da rotina.
Local nX 		:= 0	    // Incremento utilizado no For.

For nX := 1 To Len(aConfAloc)
	If  Valtype(aConfAloc[nX][1]) == "O" .And. aConfAloc[nX][1]:cName == "LBOK"
		lRetorno := .T.
		Exit
	EndIf
Next nX

If !lRetorno
	MsgAlert(STR0146,STR0147)  // "Selecione uma configuração de alocação."#"Atenção"
EndIf

Return( lRetorno )  

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VdIDs()
Verifica se ha pelo menos um agendamento desalocado.

@sample 	At330VdIDs(aAtdXAgend)

@param		ExpA1 	Array com os agendamentos.

@return		ExpL Verdadeiro / Falso

@author		Anderson Silva
@since		01/02/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VdIDs(aAtdXAgend)

Local lRetorno	:= .F.					// Retorno da rotina.
Local nX 		:= 0 					// Incremento utilizado no For.
Local nI		:= 0					// Incremento utilizado no For. 
            
For nX := 1 To Len(aAtdXAgend)
	For nI := 1 To Len(aAtdXAgend[nX][7])
		If aAtdXAgend[nX][7][nI][1] 
			lRetorno := .T.
			Exit  
		EndIf
	Next nI   
	If lRetorno  
		Exit
	EndIf
Next nX

If !lRetorno
	MsgAlert(STR0184+chr(10)+STR0185,STR0147)  // "Não há agendamentos para desalocar."##"Desaloque com um duplo clique do mouse na legenda do agendamento."#"Atenção"
EndIf
            
Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IDesP
Interface para desalocar o atendente por periodo.

@sample 	At330IDesP(oBrwAtend,oBrwAgend,aAtdXAgend)
 
@param		ExpO1 	Browse do atendente.
			ExpO2 	Browse agendamentos do atendente.
			ExpA3	Array Atendente X Agendamentos.
		
@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		20/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IDesP(oBrwAtend,oBrwAgend,aAtdXAgend)

Local lRetorno  := .F.												// Retorno da validacao.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize()										// Dimensao da janela criada pelo Protheus.
Local cTitulo	:= STR0148						   					// Titulo da janela principal.
Local oGDtIni	:= Nil   											// Objeto MsGet data inicial.
Local dDtIni		:= CtoD(Space(08))								// Data inicial.
Local oGDtFim	:= Nil    											// Objeto MsGet data final.
Local dDtFim		:= CtoD(Space(08))								// Data inicial.
Local oBtnOk	:= Nil												// Botao OK.
Local nOpc			:= 0

While	.T.
	DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.15,aSize[5]*0.30 OF oMainWnd PIXEL
		@ 005,005 SAY   STR0149            SIZE 35,10 OF oDlg                        PIXEL  // "Data Inicial:"
		@ 005,035 MSGET oGDtIni VAR dDtIni SIZE 45,08 OF oDlg VALID NaoVazio(dDtIni) PIXEL
		@ 020,005 SAY   STR0150            SIZE 35,10 OF oDlg                        PIXEL  // "Data Final:"
		@ 020,035 MSGET oGDtFim VAR dDtFim SIZE 45,08 OF oDlg VALID dDtFim >= dDtIni PIXEL
		DEFINE SBUTTON oBtnOk FROM 048,130 TYPE 1;
		                      ACTION ( nOpc := 1, oDlg:End() );
		                      ENABLE OF oDlg
		DEFINE SBUTTON oBtnOk FROM 048,160 TYPE 2;
		                      ACTION ( nOpc := 0, oDlg:End() );
		                      ENABLE OF oDlg
ACTIVATE DIALOG oDlg CENTERED

	If	nOpc == 0
		EXIT
	ElseIf	nOpc == 1
		If	NaoVazio(dDtIni) .AND. NaoVazio(dDtFim)
			At330ADesP(dDtIni, dDtFim, oBrwAtend, oBrwAgend, aAtdXAgend)
			lRetorno := .T.
			EXIT
		EndIf
	EndIf
EndDo
Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330ADesP
Desaloca o atendente no browse (Agendamentos do Atendente)

@sample 	At330ADesP(dDtIni,dDtFim,oBrwAtend,oBrwAgend,aAtdXAgend)
 
@param		ExpD1 	Data inicial.
			ExpD2	Data final.
			ExpO3	Browse atendentes.
			ExpO4	Browse agendamentos do atendentes.
			ExpA5	Array Atendentes X Agendamentos.
		
@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		20/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330ADesP(dDtIni,dDtFim,oBrwAtend,oBrwAgend,aAtdXAgend)

Local lRetorno	:= .T.   		// Retorno da rotina
Local nPosDia	:= 0  			// Posicao da data no array.
Local nGoLine	:= 0			// Posiciona no grid a primeira data que foi desalocada.

While ( dDtIni <= dDtFim )
	nPosDia := aScan(aAtdXAgend[oBrwAtend:At()][7],{|x| x[2] == dDtIni })
	If ( nPosDia > 0 )
		aAtdXAgend[oBrwAtend:At()][7][nPosDia][1] := .T. 	
	   	If nGoLine == 0
	   		nGoLine := nPosDia
	   	EndIf	
	EndIf
	dDtIni += 1
End

If nGoLine > 0
	oBrwAgend:GoTo(nGoLine)
EndIf
	
oBrwAgend:Refresh()

Return( lRetorno )         
                        
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330LDspe 
Legenda da interface desalocacao de atendentes.

@sample 	At330LDspe()

@param		Nenhum
                             
@return		Nenhum

@author		Anderson Silva
@since		28/12/2012
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330LDspe()

Local oLegenda  :=  FWLegend():New() 		// Objeto FwLegend.
                                                  	
oLegenda:Add("","BR_PRETO",STR0153)    		// "Alocado" 
oLegenda:Add("","BR_BRANCO",STR0154)   		// "Desalocado"					

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VldOrc 

Consistência para a configuração da alocação do atendente
@sample 	At330VldOrc
@param		ExpC1	Codigo do recursos humanos da proposta
@param		ExpC2	Codigo orçamento de serviços
                             
@return	ExpL	Verdadeiro

@author	Serviços
@since		02/10/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VldOrc(cCodTFF, cNrOrcSrv)

Local lRet 	  := .F. 
Local cAliasORC := GetNextAlias()

Default cNrOrcSrv := ""

lRet := (Empty(cNrOrcSrv))

If ! lRet   		
	  		   	
	BeginSql Alias cAliasORC    	
		SELECT	COUNT(*) QTD
		FROM 
			%Table:TFF% TFF, %Table:TFL% TFL  
		WHERE 
			TFF.TFF_FILIAL=%xFilial:TFF% 		AND 
			TFL.TFL_FILIAL=%xFilial:TFL% 		AND
			TFF.TFF_COD 	=%Exp:cCodTFF% 		AND 
			TFF.TFF_CODPAI=TFL.TFL_CODIGO 		AND
			TFL.TFL_CODPAI=%Exp:cNrOrcSrv%		AND			
			TFF.%NotDel%							AND
			TFL.%NotDel%									               			
	EndSql
	
	lRet := ((cAliasORC)->QTD > 0)

EndIf

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330FilAce 
Consistência para acesso ao filtro

@sample 	At330FilAce
@param		ExpA1	Lista do filtro a ser verificada
                             
@return	ExpL	Verdadeiro

@author	Serviços
@since		22/04/2014
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330FilAce(cFiltro,lMsg)

Local lRet	      	:= .F.
Local nPos		   	:= 0 
Local aPermissao 	:= {	{ "FILCC" , "008" },;  // Filtro de Centro de Custo 	
							{ "FILREG", "009" },; // Filtro de Região
							{ "FILFUN", "010" },; // Filtro de Função
							{ "FILCAR", "011" },; // Filtro de Cargo
							{ "FILHAB", "012" },; // Filtro de Habilidades
							{ "FILTUR", "013" },; // Filtro de Turno
							{ "FILSEQ", "016" }, ; // Filtro de Sequencia do Turno
							{ "FILCUR", "019" }, ; // Filtro de Cursos
							{ "FILCRC", "020" } ; // Filtro de Caracteristica
						}
						
Local nI		

Default lMsg := .T.				
												
nPos := aScan(aPermissao,{|x| x[1] == cFiltro })

If nPos > 0	
	lRet := At680Perm( Nil, __cUserID, aPermissao[nPos][2] )
EndIf

If ! lRet .And. lMsg
	Help(,,"AT330FILACE",,STR0202,1,0) // "Usuario não possui acesso para essa rotina!"
Endif

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VldDt 
Consistência para acesso ao filtro

@sample 	At330FilAce
@param		ExpC1	Numero do contrato a ser consistido
@param		ExpD1	Data inicial a ser consistida
@param		ExpD1	Data Final a ser consistida
                             
@return	ExpL	Verdadeiro

@author	Serviços
@since		22/04/2014
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330VldDt(cContrato, dDatIni, dDatFim)

Local lRet  := .F.
Local aArea := GetArea()

Default dDatFim := CtoD("")

If Empty(dDatFim)
	lRet := NaoVazio(dDatIni)
Else 
	lRet := (dDatFim >= dDatIni)
EndIf

If lRet .And. !At680Perm( Nil, __cUserID, "015" )

	dbSelectArea("CN9") 
	CN9->(dbSetOrder(7))
	
	lRet := CN9->(dbSeek(xFilial("CN9")+cContrato+"05"))

	If lRet
		lRet := dDatIni >= CN9->CN9_DTINIC
		If !Empty(dDatFim)
			lRet := lRet .And. dDatFim <= CN9->CN9_DTFIM
		EndIf			 
	EndIf
	
EndIf

RestArea(aArea)

Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330DefEq 
Define equipe para o filtro

@sample 	At330DefEq
                             
@return	ExpL	Verdadeiro

@author	Serviços
@since		23/04/2014
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330DefEq(dAlocDe,dAlocAte,oMrkAllAtd,oTreeDtFil,oLbxCfgAlo,cItCbxSel,lTecXRh,aConfAloc,aMrkAllAtd)

Local lRet    := .F.
Local aAcesso := {}
Local aParam  := { "AAX", "001", "Equipe", 1, "AAX_FILIAL+AAX_CODEQU",; 
					   "AAX", { { "AAX", 1, "AAX_NOME+AAX_REGIAO" } }, {}, {||.F.}, "", Nil }   
Local lConf670    := .F.                   

lConf670	:= TECA670( aParam, .F. )

If lConf670
	MsgRun(STR0091, STR0092, {||( At330ClrDt(oTreeDtFil),; // "Atualizado o browse atendentes"#"Aguarde"
	                              ApagarTemp(oMrkAllAtd:Alias()),;
	                              aMrkAllAtd := ListarApoio(dAlocDe /*dIniAloc*/,;
	                                                        dAlocAte /*dFimAloc*/,;
	                                                        IIF(lTecXRh, {aConfAloc[oLbxCfgAlo:nAt][nPosCargo]}, Nil) /*aCargos*/,;
	                                                        {aConfAloc[oLbxCfgAlo:nAt][nPosFuncao]} /*aFuncoes*/,;
	                                                        At330GTree(oTreeDtFil,"FILHAB") /*aHabil*/,;
	                                                        /*cDisponib*/,;
	                                                        /*cContIni*/,;
	                                                        /*cContFim*/,;
	                                                        AAH->AAH_CCUSTO /*cCCusto*/,;
	                                                        cItCbxSel /*cLista*/,;
	                                                        /*nLegenda*/,;
	                                                        /*cItemOS*/,;
	                                                        {aConfAloc[oLbxCfgAlo:nAt][nPosTurno]} /*aTurnos*/,;
	                                                        At330GTree(oTreeDtFil,"FILREG") /*aRegiao*/,;
	                                                        /*lEstrut*/,;
	                                                        /*aPeriodos*/,;
	                                                        /*cIdCfAbq*/,;
	                                                        /*cLocOrc*/,;
	                                                        /*aSeqTrn*/,;
	                                                        /*aPeriodRes*/,;
	                                                        aConfAloc[oLbxCfgAlo:nAt][nPosLocal] /*cLocalAloc*/,;
	                                                        At330GTree(oTreeDtFil,"FILCRC") /*aCarac*/,;
	                                                        At330GTree(oTreeDtFil,"FILCUR") /*aCursos*/),;
	                              At330AtBrw(oMrkAllAtd,aMrkAllAtd[1]))})
EndIf
Return(lRet)


//------------------------------------------------------------------------------
/*/{Protheus.doc} At330TipAlo

Tela de seleção do tipo de alocação.

@sample 	At330TipAlo() 

@param		lAlocacao - Verifica se a rotina que esta sendo chamada é de alocação
						  ou manutenção.
	
@return	ExpC	cRet - Codigo do tipo de alocação

@since		23/04/2014
@author	Serviços       
@version	P12   
/*/
//------------------------------------------------------------------------------//
Function At330TipAlo(lAlocacao)

Local oDlg     := Nil
Local oOk		 := Nil
Local oBottom	 := Nil
Local oCombo	 := Nil
Local aArea    := GetArea()
Local aCmboCmp := {}
Local aTipos 	 := {}
Local nPosTipo := 0
Local cCmboCmp := ""
Local cRet     := ""
Local cTitulo	 := STR0203 // "Seleção do tipo de alocação"
Local lOk      := .F.

Default lAlocacao := .F.

DbSelectArea('TCU')
TCU->(DbSetOrder(1)) //TCU_FILIAL+TCU_COD

If !TCU->(DbSeek(xFilial("TCU"))) // caso não encontre informações
	At690Unit()  // crias os tipos padrão para a filial
	TCU->(DbSeek(xFilial("TCU")))  // após criar... reposiciona no primeiro registro da filial
EndIf

While TCU->(!EOF()) .And. TCU->TCU_FILIAL==xFilial('TCU')

	// Valida se o tipo deve ser mostrado na alocacao/manuntencao da agenda
	If	(lAlocacao .And. TCU->TCU_EXALOC <> "1") .Or. ;
		(!lAlocacao .And. TCU->TCU_EXMANU <> "1")
		TCU->(DbSkip())
		Loop			
	EndIf 
	aAdd( aCmboCmp, TCU->TCU_COD + " - " + TCU->TCU_DESC )	
	aAdd( aTipos, { TCU->TCU_DESC, TCU->TCU_COD } )
	TCU->(DbSkip())
End	

//	Cria a tela para a pesquisa dos campos e define a area a ser utilizada na tela 
Define MsDialog oDlg TITLE cTitulo FROM 000, 000 To 200, 200 Pixel	
	
oOk:= LoadBitMap(GetResources(), "LBOK")
@ 020,020 SAY STR0203 OF oDlg PIXEL SIZE 80,9 // "Selecione o tipo da alocação:"
@ 035,020 COMBOBOX oCombo VAR cCmboCmp ITEMS aCmboCmp OF oDlg SIZE 60,10 PIXEL;

@ 060,020 Button oOk Prompt STR0022  Of oDlg Size 60, 010 Pixel //"Ok"
oOk:bAction := { || lOk := .T., oDlg:End() }

Activate MsDialog oDlg Centered

If lOk
	nPosTipo := aScan( aTipos, { |x| AllTrim(x[2]) == Alltrim(Substr(cCmboCmp,1,TAMSX3("TCU_COD")[1])) } )
	If nPosTipo > 0
		cRet := aTipos[nPosTipo][2]
	EndIf
Else
	cRet := ""
EndIf
	
RestArea(aArea)
		
Return(cRet)

//------------------------------------------------------------------------------//
/*/{Protheus.doc} At330CanAloc
	 Avalia período a período verificando se há alocação com número maior de recursos que o definido no contrato

@sample 	At330CanAloc() 
@param		cAgsBlocks, char, REFERÊNCIA, string com o detalhe dos período que não poderão ser alocados 
@param		aTxCalenAt, array, REFERÊNCIA, array com os períodos que serão avaliados ao final, terá somente as agendas permitidas
@param		aResumo, array, REFERÊNCIA, array com o resumo de horas e dias de alocação
@param		cIdCfg
@param		cAtdCod
@param		cAtdNom
@param		nQtAlocar

@return 	lCanAll, Logico, indica se todos os períodos podem ser alocados 
@since		23/04/2014
@version	P12   
/*/
//------------------------------------------------------------------------------//
Function At330CanAloc( cAgsBlocks, aTxCalenAt, aResumo, cIdCfg, cAtdCod, cAtdNom, nQtAlocar )

Local lCanAll 		:= .T.
Local cTmpAlias 	:= ""
Local nX 			:= 0

Local cDiaIni 		:= CTOD("")
Local cHoraIni 	:= CTOD("")
Local cDiaFim 		:= CTOD("")
Local cHoraFim 	:= CTOD("")

Local aLinesRem 	:= {}
Local lFirstMsg 	:= .T.
Local nQtIni 		:= 0
Local nQtRem 		:= 0
Local aAux 		:= {}

Default cAgsBlocks := ""
Default aTxCalenAt := {}
Default aResumo 	:= {}
Default cIdCfg 	:= ""
Default cAtdCod 	:= ""
Default cAtdNom 	:= ""

cAgsBlocks := ""
nQtIni := Len(aTxCalenAt)

If nQtIni > 0 .And. Len(aResumo) >= 2 .And. !Empty(cIdCfg)
	
	DbSelectArea("ABQ")
	ABQ->(DbSetOrder( 1 )) // ABQ_FILIAL+ABQ_CONTRT+ABQ_ITEM+ABQ_ORIGEM

	If ABQ->( DbSeek( xFilial("ABQ")+cIdCfg ) )
	
		cTmpAlias := GetNextAlias()
		lFirstMsg := .T.
		// avalia para cada período de alocação se já há o número limite de recursos alocados
		For nX := 1 To nQtIni
		
			cDiaIni := DTOS( aTxCalenAt[nX,1] )
			cHoraIni := aTxCalenAt[nX,3]
			cDiaFim := DTOS( aTxCalenAt[nX,7] )
			cHoraFim := aTxCalenAt[nX,4]
			
			BeginSql Alias cTmpAlias
			
				SELECT COUNT(ABB.R_E_C_N_O_) ABB_QT
				FROM %Table:ABB% ABB 
				       LEFT JOIN %Table:ABR% ABR ON ABR_FILIAL = %xFilial:ABR%
				                                AND ABR.%NotDel%
				                                AND ABB.ABB_MANUT = '1' 
				                                AND ABR.ABR_AGENDA = ABB.ABB_CODIGO
				 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
					AND ABB.%NotDel% 
				   AND ABB.ABB_IDCFAL = %Exp:cIdCfg%
					AND (
							( 
				                 ABB.ABB_DTINI = %Exp:cDiaIni%
				             AND ABB.ABB_HRINI = %Exp:cHoraIni%
				             AND ABB.ABB_DTFIM = %Exp:cDiaFim% 
				             AND ABB.ABB_HRFIM = %Exp:cHoraFim%
							)
							OR
							( 
				                 ABR.ABR_DTINIA = %Exp:cDiaIni%
				             AND ABR.ABR_HRINIA = %Exp:cHoraIni%
				             AND ABR.ABR_DTFIMA = %Exp:cDiaFim% 
				             AND ABR.ABR_HRFIMA = %Exp:cHoraFim%
							)
						)
			EndSql
			// verifica a quantidade de recursos já alocados e o definido para o contrato
			If (cTmpAlias)->(!EOF()) .And. ((cTmpAlias)->ABB_QT+nQtAlocar) > ABQ->ABQ_FATOR
				
				lCanAll := .F.
				aAdd( aLinesRem, nX )
				// cria a mensagem de retorno com os período identificados com a inconsistência
				If lFirstMsg
					lFirstMsg := .F.
					cAgsBlocks += I18N(STR0238,{ cAtdCod, cAtdNom }) + CRLF // "Atendente: #1[Código Técnico]# - #2[Nome Técnico]#"
					 
				EndIf
				
				cAgsBlocks += I18N(STR0239,; // "Dia Referência: #1[dtRef]# Início: #2[dtIni]# - #3[hrIni]# Fim: #4[dtFim]# - #5[hrFim]# "
										{ DTOC(aTxCalenAt[nX,8]), DTOC(aTxCalenAt[nX,1]), aTxCalenAt[nX,3], DTOC(aTxCalenAt[nX,7]), aTxCalenAt[nX,4] }) + CRLF
			
			Else
				// copia os períodos permitidos para um array temporário
				aAdd( aAux , aClone(aTxCalenAt[nX]) )
			EndIf 
			
			(cTmpAlias)->(DbCloseArea())
			
		Next nX
		
		nQtRem := Len(aLinesRem)
		// ajusta o array com os períodos para alocação
		// removendo os períodos que possuem bloqueio
		If nQtRem > 0
			
			// redefine o array de retorno com as informações permitidas
			aSize( aTxCalenAt, 0 )
			aTxCalenAt := aClone( aAux )
			
			// recalcula o total de horas nos itens
			aResumo[1] := 0
			aEval( aTxCalenAt, {|x|  aResumo[1] += HoraToInt( x[5] ) } )
			
			// verifica a qtde de dias de rederência diferentes que há no array 
			// para saber qtos dias diferentes há de trabalho
			aSize( aAux, 0 )
			aAux := {}
			aEval( aTxCalenAt, {|x| If( aScan(aAux,x[8])==0, aAdd(aAux,x[8]), Nil) } )
			aResumo[2] := Len(aAux)
			
		EndIf
		
	EndIf
	
EndIf

Return lCanAll

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GerMem

Filtra os atendentes do contrato

@sample 	At330GerMem(cNumContr, cRevContr, _aAtend_)

@param		cNumContr - Número do Contrato
@param		cRevContr - Revisão
@param		_aAtend_  - Vetor: cCodSub,cConfig,dDtIniSub,cHrIniSub,dDtFimSub,cHrFimSub,cLocal,cTipoAloc,cAgenda
	
@return	lRet

@since		05/02/2015
@author	Serviços       
@version	P12   
/*/
//------------------------------------------------------------------------------//
Function At330GerMem(cNumContr, cRevContr, _aAtend_)

Local lRet     := .F.
Local aAreaABB := GetArea()
Local cAliasAT := GetNextAlias()
Local _aMemo   := {} // Armazena as informacoes do memorando
Local cConfig  := ''
Local cLocal   := ''
Local cCodTec  := ''
Local cAgenda  := ''
Local cObserv 	:= ''

If Type("M->ABR_OBSERV") == "C"
	cObser := M->ABR_OBSERV
Else
	cObser := STR0255 // "Sem Observações"
EndIF

// Filtra os atendentes alocados no contrato

IF !Empty(_aAtend_)

	cCodTec := _aAtend_[1]
	cConfig := _aAtend_[2]
	cLocal  := _aAtend_[7]
	cAgenda := _aAtend_[9]

	BeginSql Alias cAliasAT
		SELECT DISTINCT ADY_CLIENT
		              , ADY_LOJA
						, A1_NOME
		              , TFF_CONTRT
		              , TFF_CONREV
		              , AA1_CDFUNC
		              , AA1_NOMTEC
		              , AA1_FUNCAO
		              , RJ_DESC
		              , TFF_CARGO
		              , COALESCE(Q3_DESCSUM, '') AS Q3_DESCSUM
		              , ABB_CODTEC
		              , ABS_LOCAL
		              , ABS_DESCRI
		              , ABS_END
		              , ABS_BAIRRO
		              , ABS_CONTAT
		              , COALESCE(U5_CONTAT, '') AS U5_CONTAT
		              , COALESCE(U5_DDD, '') AS U5_DDD
		              , COALESCE(U5_FONE, '') AS U5_FONE
		              , ABB_TIPOMV
		              , COALESCE(TCU_DESC, '') AS TCU_DESC
		              , TFF_TURNO
		              , COALESCE(R6_DESC, '') AS R6_DESC
		  FROM %table:ABB% ABB
		
		  JOIN %table:AA1% AA1 ON AA1_FILIAL = %xFilial:AA1%
		   AND AA1_CODTEC = ABB_CODTEC
		   AND AA1.%notDel%
		
		  JOIN %Table:ABQ% ABQ ON ABQ_FILIAL = %xFilial:ABQ%
		   AND ABQ_CONTRT || ABQ_ITEM || ABQ_ORIGEM = ABB_IDCFAL
		   AND ABQ.%notDel%

		  LEFT OUTER JOIN %table:TCU% TCU ON TCU_FILIAL = %xFilial:TCU%
		   AND TCU_COD = ABB_TIPOMV
		   AND TCU.%notDel%
		
		  JOIN %table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
		   AND TFJ_CONTRT = %Exp:cNumContr%
		   AND TFJ_CONREV = %Exp:cRevContr%
		   AND TFJ.%notDel%
		
		  JOIN %table:ADY% ADY ON ADY_FILIAL = %xFilial:ADY%
		   AND ADY_PROPOS = TFJ_PROPOS
		   AND ADY_PREVIS = TFJ_PREVIS
		   AND ADY.%notDel% 
	
		  JOIN %table:SA1% SA1 ON A1_FILIAL = %xFilial:SA1%
		   AND A1_COD = ADY_CLIENT
		   AND A1_LOJA = ADY_LOJA
		   AND SA1.%notDel% 
		   	
		  JOIN %table:TFF% TFF ON TFF_FILIAL = ABQ_FILTFF
		   AND TFF_CONTRT = TFJ_CONTRT
		   AND TFF_CONREV = TFJ_CONREV 
		   AND TFF_COD = ABQ_CODTFF
		   AND TFF.%notDel% 
		
		  LEFT OUTER JOIN %Table:SR6% SR6 ON R6_FILIAL = %xFilial:SR6%
		   AND R6_TURNO = TFF_TURNO
		   AND SR6.%notDel%
		
		  LEFT OUTER JOIN %Table:SQ3% SQ3 ON Q3_FILIAL = %xFilial:SQ3%
		   AND Q3_CARGO = TFF_CARGO
		   AND SQ3.%notDel% 
		 
		  JOIN %Table:SRJ% SRJ ON RJ_FILIAL = %xFilial:SRJ%
		   AND RJ_FUNCAO = TFF_FUNCAO
		   AND SRJ.%notDel%
		
		  JOIN %Table:TFL% TFL ON TFL_FILIAL = %xFilial:TFL%
		   AND TFL_CONTRT = TFJ_CONTRT 
		   AND TFL_CONREV = TFJ_CONREV
		   AND TFL_CODIGO = TFF_CODPAI
		   AND TFL.%notDel%
		
		  JOIN %Table:ABS% ABS ON ABS_FILIAL = %xFilial:ABS%
		   AND ABS_LOCAL = TFL_LOCAL 
		   AND ABS.%notDel%
	
		  LEFT OUTER JOIN %Table:SU5% SU5 ON U5_FILIAL = %xFilial:SU5%
		   AND U5_CODCONT = ABS_CONTAT 
		   AND SU5.%notDel%
	   	
		 WHERE ABB_FILIAL = %xFilial:ABB%
		   AND ABB_IDCFAL = %Exp:cConfig%
		   AND ABB_LOCAL = %Exp:cLocal%
		   AND ABB_CODTEC = %Exp:cCodTec%
		   AND ABB.%notDel%
	
	EndSql
ELSE
	BeginSql Alias cAliasAT
		SELECT DISTINCT ADY_CLIENT
		              , ADY_LOJA
						, A1_NOME
		              , TFF_CONTRT
		              , TFF_CONREV
		              , AA1_CDFUNC
		              , AA1_NOMTEC
		              , AA1_FUNCAO
		              , RJ_DESC
		              , TFF_CARGO
		              , COALESCE(Q3_DESCSUM, '') AS Q3_DESCSUM
		              , ABB_CODTEC
		              , ABS_LOCAL
		              , ABS_DESCRI
		              , ABS_END
		              , ABS_BAIRRO
		              , ABS_CONTAT
		              , COALESCE(U5_CONTAT, '') AS U5_CONTAT
		              , COALESCE(U5_DDD, '') AS U5_DDD
		              , COALESCE(U5_FONE, '') AS U5_FONE
		              , ABB_TIPOMV
		              , COALESCE(TCU_DESC, '') AS TCU_DESC
		              , TFF_TURNO
		              , COALESCE(R6_DESC, '') AS R6_DESC
		              , TFL_DTINI
		              , TFL_DTFIM
		              , TFF_HORAIN
		              , TFF_HORAFI
		  FROM %Table:ABB% ABB
		
		  JOIN %Table:AA1% AA1 ON AA1_FILIAL = %xFilial:AA1%
		   AND AA1_CODTEC = ABB_CODTEC
		   AND AA1.%notDel%
		
		  JOIN %Table:ABQ% ABQ ON ABQ_FILIAL = %xFilial:ABQ%
   		   AND ABB_IDCFAL = ABQ_CONTRT || ABQ_ITEM || ABQ_ORIGEM
		   AND ABQ.%notDel%
		   
		  LEFT OUTER JOIN %Table:TCU% TCU ON TCU_FILIAL = %xFilial:TCU%
		   AND TCU_COD = ABB_TIPOMV
		   AND TCU.%notDel%
		
		  JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = %xFilial:TFJ%
		   AND TFJ_CONTRT = %Exp:cNumContr%
		   AND TFJ_CONREV = %Exp:cRevContr%
		   AND TFJ.%notDel%
		
		  JOIN %Table:ADY% ADY ON ADY_FILIAL = %xFilial:ADY%
		   AND ADY_PROPOS = TFJ_PROPOS
		   AND ADY_PREVIS = TFJ_PREVIS
		   AND ADY.%notDel% 
	
		  JOIN %Table:SA1% SA1 ON A1_FILIAL = %xFilial:SA1%
		   AND A1_COD = ADY_CLIENT
		   AND A1_LOJA = ADY_LOJA
		   AND SA1.%notDel% 
		   	
		  JOIN %table:TFF% TFF ON TFF_FILIAL = ABQ_FILTFF
		   AND TFF_CONTRT = TFJ_CONTRT
		   AND TFF_CONREV = TFJ_CONREV 
		   AND TFF_COD = ABQ_CODTFF
		   AND TFF.%notDel% 
		
		  LEFT OUTER JOIN %Table:SR6% SR6 ON R6_FILIAL = %xFilial:SR6%
		   AND R6_TURNO = TFF_TURNO
		   AND SR6.%notDel%
		
		  LEFT OUTER JOIN %Table:SQ3% SQ3 ON Q3_FILIAL = %xFilial:SQ3%
		   AND Q3_CARGO = TFF_CARGO
		   AND SQ3.%notDel% 
		 
		  JOIN %Table:SRJ% SRJ ON RJ_FILIAL = %xFilial:SRJ%
		   AND RJ_FUNCAO = TFF_FUNCAO
		   AND SRJ.%notDel%
		
		  JOIN %Table:TFL% TFL ON TFL_FILIAL = %xFilial:TFL%
		   AND TFL_CONTRT = TFJ_CONTRT 
		   AND TFL_CONREV = TFJ_CONREV
		   AND TFL_CODIGO = TFF_CODPAI
		   AND TFL.%notDel%
		
		  JOIN %Table:ABS% ABS ON ABS_FILIAL = %xFilial:ABS%
		   AND ABS_LOCAL = TFL_LOCAL 
		   AND ABS.%notDel%
	
		  LEFT OUTER JOIN %Table:SU5% SU5 ON U5_FILIAL = %xFilial:SU5%
		   AND U5_CODCONT = ABS_CONTAT 
		   AND SU5.%notDel%
	   	
		 WHERE ABB_FILIAL = %xFilial:ABB%
		   AND ABB_ENTIDA = ' '
		   AND ABB.%notDel%
	
	EndSql
ENDIF

DbSelectArea(cAliasAT)

// Preenche os dados do memorando	              
DO WHILE (cAliasAT)->(!Eof())

	Aadd(_aMemo,{(cAliasAT)->A1_NOME,;		//NOME DO CLIENTE
	             (cAliasAT)->ABS_DESCRI,;	//POSTO
	             (cAliasAT)->ABS_END,;		//ENDERECO
	             (cAliasAT)->ABS_BAIRRO,;	//BAIRRO
	             (cAliasAT)->U5_DDD,;		//DDD
	             (cAliasAT)->U5_FONE,;		//TELEFONE
	             (cAliasAT)->U5_CONTAT,;	//CONTATO
	             (cAliasAT)->AA1_NOMTEC,;	//FUNCIONARIO
	             IIF(!Empty(cCodTec),_aAtend_[4],(cAliasAT)->TFF_HORAIN),;	//HORA INICIAL
	             IIF(!Empty(cCodTec),_aAtend_[6],(cAliasAT)->TFF_HORAFI),;	//HORA FINAL
	             (cAliasAT)->TFF_CONTRT,;	//CONTRATO
	             (cAliasAT)->TFF_CONREV,;	//REVISAO
	             (cAliasAT)->AA1_CDFUNC,;	//MATRICULA	
	             (cAliasAT)->RJ_DESC,;		//FUNCAO
	             (cAliasAT)->Q3_DESCSUM,;	//CARGO
	             (cAliasAT)->TCU_DESC,;	//TIPO DE MOVIMENTACAO
	             (cAliasAT)->R6_DESC,;		//TURNO
	             IIF(!Empty(cCodTec),DTOS(_aAtend_[3]),(cAliasAT)->TFL_DTINI),;	//DATA INICIAL
	             IIF(!Empty(cCodTec),DTOS(_aAtend_[5]),(cAliasAT)->TFL_DTFIM),;	//DATA FINAL
	             (cAliasAT)->ABB_CODTEC,;	//TECNICO
	             (cAliasAT)->ABS_LOCAL,;    //21LOCAL
				 Alltrim(cObser)})   //22OBSERVACOES

	(cAliasAT)->(DbSkip())
END

DbSelectArea(cAliasAT)
(cAliasAT)->(DbCloseArea())

IF Len(_aMemo) > 0
	// Chama rotina de geracao memorando em HTML
	lRet := At330Memo(_aMemo, cAgenda)
ELSE
	Help( ' ', 1, 'TECA330', , STR0214, 1, 0 )	//"Não existem atendentes alocados"
ENDIF

RestArea(aAreaABB)

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330Memo

Gera o memorando

@sample 	At330Memo(_aMemo,_cAgenda_)

@param		_aMemo    - vetor de dados
@param		_cAgenda_ - codigo da agenda
	
@return	lRet

@since		06/02/2015
@author	Serviços       
@version	P12   
/*/
//------------------------------------------------------------------------------//
Static Function At330Memo(_aMemo_, _cAgenda_)

Local lRet			:= .F.
Local nX			:= 0
Local cPathWF		:= GetSrvProfString("ROOTPATH","/") + "\samples\documents\memorando\"  
Local cPath		:= "\memorando\"
Local cPathMArq	:= "memorando_arquivos\"
Local cArqHtm		:= "memorando.html"
Local oWF
Local _cRazao		:= ''
Local _cCnpj		:= ''
Local _cEnd		:= ''
Local _cTel		:= ''
Local _cFax		:= ''
Local cAliasM		:= ''
Local cPathLoc	:= 'file:///' + StrTran(GetSrvProfString("ROOTPATH","/"),'\','/') + StrTran(cPath,'\','/')
Local cPathAbs	 := StrTran(GetSrvProfString("ROOTPATH","/"),'\','/') + StrTran(cPath,'\','/')
Local nRecnoSM0	:= SM0->(RecNo())
Local cPathSrv	:= ''
Local cFileJpg	:= ''
Local cPathFile	:= ''
Local aArea		:= GetArea()
Local cAlias		:= "PROTHEUS_REPOSIT"
Local cBmpPict	:= ""
Local cPath2		:= GetSrvProfString("Startpath","")
Local lFile	
Local oDlg8
Local oBmp
Local cDest		:= "\memorando\fotos\"
Local cDirTemp	:= GetTempPath(.T.) + "fotos\"
Local cArqTmp		:= ""
Local lAchou		:= .F.
Local cShowLog	:= ""
Local cMemoHTM	:= ""
Local nFileHTM	:= 0

If	ExistDir( cPathWF )											.and.;
	ExistDir( cPathWF + cPathMArq )								.and.;
	File( cPathWF + cArqHtm )									.and.;
	File( cPathWF + cPathMArq + "colorschememapping.xml" )	.and.;
	File( cPathWF + cPathMArq + "filelist.xml" )				.and.;
	File( cPathWF + cPathMArq + "item0006.xml" )				.and.;
	File( cPathWF + cPathMArq + "props007.xml" )				.and.;
	File( cPathWF + cPathMArq + "themedata.thmx" )

	// cria o diretório que irá armazenar os memorandos
	FwMakeDir( cDest )

	// Dados da Empresa
	DbSelectArea("SM0")
	DBGoTop()
	Do While ! Eof()
		If SM0->M0_CODIGO == cEmpAnt
			_cRazao := SM0->M0_NOME
			_cCnpj  := Transform(SM0->M0_CGC,'@R 99.999.999/9999-99')
			_cEnd   := Alltrim(SM0->M0_ENDCOB) + ' ' + Alltrim(SM0->M0_CIDCOB) + ' ' + 'CEP: ' + Transform(SM0->M0_CEPCOB,"@R 99999-999") + ' ' + SM0->M0_ESTCOB
			_cTel   := SM0->M0_TEL
			_cFax   := SM0->M0_FAX

			EXIT		
		Endif
		DBSkip()
	EndDo

	DBGoTo(nRecnoSM0)  

	For nX := 1 to Len(_aMemo_)

		lAchou := .F.

		// Inicializa a classe TWFProcess 
		CpyS2T('\samples\documents\memorando\'+cArqHtm,GetTempPath(.T.))
		Sleep(1500)
		oWF := TWFHTML():New( GetTempPath(.T.)+cArqHtm )

		DbSelectArea("SRA")
		SRA->(DbSetOrder(1))//RA_FILIAL, RA_MAT
		SRA->(DbSeek(xFilial("SRA")+_aMemo_[nX][13]))

		// Preenche as variaveis no HTML do corpo do formulário
		cBmpPict := Upper( AllTrim( SRA->RA_BITMAP)) 
		If !Empty(cBmpPict)
		If File(cDest+cBmpPict+".BMP")
			lAchou := .T.
			cArqTmp := cBmpPict + ".BMP"
		ElseIf File(cDest+cBmpPict+".JPG")
			lAchou := .T.
			cArqTmp := cBmpPict + ".JPG"
		EndIf

		If !lAchou

			cPathPict 	:= ( cPath2 + cBmpPict)

			DEFINE MSDIALOG oDlg8   FROM -1000000,-4000000 TO -10000000,-8000000  PIXEL 
			@ -10000000, -1000000000000 REPOSITORY oBmp SIZE -6000000000, -7000000000 OF oDlg8  

			// Verifica se a imagem existe no repositorio
			If oBMP:ExistBMP(cBmpPict)

				If !Empty( cBmpPict := Upper( AllTrim( SRA->RA_BITMAP ) ) )
					lFile:=oBmp:Extract(cBmpPict, cPathPict)
					If lFile 
						If File(cPathPict+".BMP") 
							cPathFile := cPathPict + ".BMP"
							cArqTmp := cBmpPict + ".BMP"
						ElseIf File(cPathPict+".JPG")
							cPathFile := cPathPict + ".JPG"
							cArqTmp := cBmpPict + ".JPG"
						EndIf
					EndIf	
				EndIf	
			EndIf
			ACTIVATE MSDIALOG oDlg8 ON INIT (oBmp:lStretch := .T., oDlg8:End())
		
			// Copia para diretorio temporario
			CpyS2T( cPathFile, cDirTemp , .F. )
			// Deleta do diretorio do system
			FERASE( cPathFile )
			CpyT2S( cDirTemp + cArqTmp, cDest, .F.)
			ENDIF
			oWF:ValByName("cFoto"		, "<img src=" + '"fotos\' + cArqTmp + '"' + ' width="80" height="110"' + '/>')
		EndIf
		oWF:ValByName("cServidor"	, Alltrim(_cRazao))                                                                                           
		oWF:ValByName("cEndServ"		, Alltrim(_cEnd))  
		oWF:ValByName("cCnpjServ"	, _cCnpj)                                                                               
		oWF:ValByName("cTelServ"		, _cTel)                                                                                        
		oWF:ValByName("cFaxServ"		, _cFax)               
		oWF:ValByName("cData"		, Dtoc(dDataBase)) 
		oWF:ValByName("cHora"		, Substr(Time(),1,5))
		oWF:ValByName("cCliente"		, Alltrim(_aMemo_[nX][1]))
		oWF:ValByName("cPosto"		, Alltrim(_aMemo_[nX][2]))
		oWF:ValByName("cEndCli"		, Alltrim(_aMemo_[nX][3]))
		oWF:ValByName("cBaiCli"		, Alltrim(_aMemo_[nX][4]))
		oWF:ValByName("cTelCli"		, '('+_aMemo_[nX][5]+') ' + _aMemo_[nX][6])
		oWF:ValByName("cContato"		, Alltrim(_aMemo_[nX][7]))
		oWF:ValByName("cFunc"		, Alltrim(_aMemo_[nX][8]))
		oWF:ValByName("cHoraIni"		, _aMemo_[nX][9])
		oWF:ValByName("cHoraFim"		, _aMemo_[nX][10])
		oWF:ValByName("cContrato"	, _aMemo_[nX][11])
		oWF:ValByName("cRevisa"		, _aMemo_[nX][12])
		oWF:ValByName("cMatFunc"		, _aMemo_[nX][13])
		oWF:ValByName("cFuncao"		, Alltrim(_aMemo_[nX][14]))
		oWF:ValByName("cCargo"		, Alltrim(_aMemo_[nX][15]))
		oWF:ValByName("cTpMov"		, Alltrim(_aMemo_[nX][16]))
		oWF:ValByName("cTurno"		, Alltrim(_aMemo_[nX][17]))
		oWF:ValByName("cObs"		, Alltrim(_aMemo_[nX][22]))

		If ! Empty(_cAgenda_)
			cAliasM := GetNextAlias()

			BeginSql Alias cAliasM
				SELECT AA1_CDFUNC
	                , AA1_NOMTEC
				  FROM %table:ABB% ABB

				  JOIN %Table:AA1% AA1 ON AA1_FILIAL = %xFilial:AA1%
				   AND AA1_CODTEC = ABB_CODTEC
				   AND AA1.%notDel%

				 WHERE ABB_FILIAL = %xFilial:ABB%
				   AND ABB_CODIGO = %Exp:_cAgenda_%
				   AND ABB.%notDel%

			EndSql

			DbSelectArea(cAliasM)

			Do While (cAliasM)->(!Eof())	
				oWF:ValByName("cMatSub"	, Alltrim((cAliasM)->AA1_CDFUNC))
				oWF:ValByName("cSubst"	, Alltrim((cAliasM)->AA1_NOMTEC))
				(cAliasM)->(DbSkip())
			EndDo

			DbSelectArea(cAliasM)
			(cAliasM)->(DbCloseArea())

		EndIf

		oWF:ValByName("cDtIni"		, DTOC(STOD(_aMemo_[nX][18])))
		oWF:ValByName("cDtFim"		, DTOC(STOD(_aMemo_[nX][19])))

		//salva em diretório local temporário
		//oWF:SaveFile( cPath + dtos(dDataBase) + '_' + _aMemo_[nX][11] + '_' + _aMemo_[nX][20] + '_' + _aMemo_[nX][21] + '.htm' )
		oWF:SaveFile( cPath + dtos(dDataBase) + '_' + _aMemo_[nX][21] + '.htm' )
	Next nX

	If MsgYesNo(	STR0215 + GetSrvProfString("ROOTPATH","/") + cPath + chr(13) + chr(10) +;
					STR0216 ) //"Os arquivos foram gerados no diretório: " # "Deseja visualizar os arquivos gerados?"

		For nX := 1 TO Len(_aMemo_)

			cPathAbs := cPathAbs + dtos(dDataBase) + '_' + _aMemo_[nX][21] + '.htm'
			cPathAbs := Replace(cPathAbs,"/","\")
		
			cPathAbs := Tc330Copy(cPathAbs,dtos(dDataBase) + '_' + _aMemo_[nX][21] + '.htm')
		
			shellExecute("Open",cPathAbs , " /k dir", "C:\", 1 ) 
		Next nX
	EndIf
Else

	cShowLog	:= STR0245+CRLF+STR0246+CRLF+CRLF						//"Não foi encontrada na estrutura de pastas do servidor a configuração necessária para a geração dos memorandos.""Não foi encontrada na estrutura de pastas do servidor a configuração necessária para a geração dos memorandos." ## "Contacte o administrador do sistema."
	cShowLog	+= STR0247+CRLF											//"Solução:"
	cShowLog	+= "1) "+STR0248+CRLF+"   "+AllTrim(cPathWF)+CRLF	//"Verifique o seguinte caminho de diretório:"
	cShowLog	+= "2) "+STR0249+" "+AllTrim(cArqHtm)+CRLF			//"Verifique nesse diretório a existência do arquivo:"
	cShowLog	+= "3) "+STR0248+CRLF+"   "+cPathWF + cPathMArq+CRLF	//"Verifique o seguinte caminho de diretório:"
	cShowLog	+= "4) "+STR0250+CRLF									//"Verifique nesse diretório a existência dos arquivos:"
	cShowLog	+= "   - colorschememapping.xml"+CRLF
	cShowLog	+= "   - filelist.xml"+CRLF
	cShowLog	+= "   - item0006.xml"+CRLF
	cShowLog	+= "   - props007.xml"+CRLF
	cShowLog	+= "   - themedata.thmx"+CRLF+CRLF
	cShowLog	+= STR0251   //"Caso encontre, em seu ambiente, alguma inconsistência na configuração descrita, favor providenciar os ajustes necessários para que a geração dos memorandos possa ocorrer."
 
	AtShowLog( cShowLog, STR0217 )	//"Memorando"
	lRet	:=	.F.

EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330OPMEM

Gera o memorando

@sample 	At330OPMEM(_cPath_)

@param		_cPath_ - diretorio do html 
	
@return	

@since		09/02/2015
@author	Serviços       
@version	P12   
/*/
//------------------------------------------------------------------------------//
Static Function At330OPMEM(_cPath_)

Local oDlgE
Local aSize 	   := {}
Local oTIBrowser := Nil

aSize := FWGetDialogSize( oMainWnd )

DEFINE MSDIALOG oDlgE TITLE STR0217 FROM aSize[1], aSize[2] TO aSize[3], aSize[4] PIXEL 	//"Memorando"

oTIBrowser := TIBrowser():New(00,00,00, 00,_cPath_,oDlgE )
oTIBrowser:Align    := CONTROL_ALIGN_ALLCLIENT
oTIBrowser:GoHome()

ACTIVATE DIALOG oDlgE CENTERED

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330FilCt
Filtra os contratos/revisao.

@sample 	At330FilCt(_aAtenABB)

@param		_aAtenABB 	Array com dados dos atendentes

@return	
@author	Serviços
@since		09/02/2015
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330FilCt(_aAtenABB_)

Local aAreaABB  := GetArea()
Local cAliasABB := ''
Local nX        := 0

FOR nX := 1 TO Len(_aAtenABB_)

	//Busca a revisao do contrato

	cAliasABB := GetNextAlias()

	BeginSql Alias cAliasABB
	
		SELECT DISTINCT TFF.TFF_CONTRT, TFF.TFF_CONREV
		  FROM %table:ABB% ABB
	
		  JOIN %table:ABQ% ABQ ON ABQ_FILIAL = %xFilial:ABQ%
		   AND ABQ.%notDel%
		   AND ABQ_CONTRT || ABQ_ITEM || ABQ_ORIGEM = ABB_IDCFAL
		   	
		  JOIN %table:TFF% TFF ON TFF_FILIAL = %xFilial:TFF%
		   AND TFF_CONTRT = %Exp:_aAtenABB_[nX][1]%
		   AND TFF_COD = ABQ_CODTFF 
		   AND TFF.%notDel% 
		 
		 WHERE ABB_FILIAL = %xFilial:ABB%
		   AND ABB_CODIGO = %Exp:_aAtenABB_[nX][2]%
		   AND ABB_DTINI = %Exp:_aAtenABB_[nX][3]%
		   AND ABB_HRINI = %Exp:_aAtenABB_[nX][4]%
		   AND ABB_DTFIM = %Exp:_aAtenABB_[nX][5]%
		   AND ABB_HRFIM = %Exp:_aAtenABB_[nX][6]%
	EndSql
	
	DbSelectArea(cAliasABB)
		
	While (cAliasABB)->( !Eof() )	
		// Rotina de geracao do memorando
		At330GerMem((cAliasABB)->TFF_CONTRT, (cAliasABB)->TFF_CONREV,'')	
		(cAliasABB)->(DbSkip())				
	End
	
	DbSelectArea(cAliasABB)
	(cAliasABB)->(DbCloseArea())
NEXT nX

RestArea(aAreaABB)

Return
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VldOk(lOk)
Valida se o posto pode receber alocação
@sample 	At330VldOk(lOk)
@param		

@return	
@author	Serviços
@since		31/08/2015
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VldOk(nIdCfg )

Local lRetorno	:= .F.		// Retorno da rotina.
Local nX 		:= 0	    // Incremento utilizado no For.
Local tmpTFL:=""

			tmpTFL := GetNextAlias()
			BeginSQL Alias tmpTFL       
			SELECT  count(*)as Result
				FROM %Table:TFL% TFL		
	       INNER JOIN %Table:TFF% TFF ON TFF.TFF_FILIAL = %xFilial:TFL%
				AND TFF.%notDel%
	                                 AND TFF.TFF_CODPAI = TFL.TFL_CODIGO
	       INNER JOIN %Table:ABQ% ABQ ON ABQ.ABQ_FILIAL = %xFilial:ABQ%
				AND ABQ.%notDel%
	                                 AND ABQ.ABQ_FILTFF = %xFilial:TFF%
	                                 AND ABQ.ABQ_CODTFF = TFF.TFF_COD
	 WHERE TFL.TFL_FILIAL = %xFilial:TFL%
	   AND (TFF.TFF_ENCE = '1')
	   AND ABQ.ABQ_CONTRT || ABQ.ABQ_ITEM || ABQ.ABQ_ORIGEM = %Exp:nIdCfg%
				AND TFL.%notDel%	
		EndSql 
		
		DbSelectArea(tmpTFL)
		If (tmpTFL)->Result > 0 
			lRetorno := .F.
		Else
			lRetorno := .T.
		EndIf
		(tmpTFL)->(DbCloseArea())		

If !lRetorno
	MsgAlert(STR0219,STR0220)  // "Posto Encerrado, não poderá gerar novas agendas""#"Atenção" 
EndIf

Return( lRetorno )  

//------------------------------------------------------------------------------//
/*/{Protheus.doc} At330ResTec
	 Avalia se o local e tipo de movimento sao compativeis (RESERVA TECNICA)

@sample 	At330ResTec() 
@param		aAtdXCalen, array, REFERÊNCIA, array com a alocacao configurada 
@param		cTipoMov, char, REFERÊNCIA, string com o codigo do tipo de movimento (conforme tabela TCU)

@return 	lValid, Logico, .T. quando a combinacao local x tipo movimento for valida e .F. invalida 
@since		01/06/2015
@version	P12   
/*/
//------------------------------------------------------------------------------//
Static Function At330ResTec(aAtdXCalen,cTipoMov)
Local lValid   := .F.
Local aAreaBKP := GetArea()
Local nLinhas  := 0

dbSelectArea("TCU")
TCU->(dbSetOrder(1))
If TCU->(dbSeek(xFilial("TCU")+cTipoMov ))
	For nLinhas := 1 To Len(aAtdXCalen)
		dbSelectArea("ABS")
		ABS->(dbSetOrder(1))
		If ABS->(dbSeek(xFilial("ABS")+aAtdXCalen[nLinhas,12])) .And. ((ABS->ABS_RESTEC == "1" .And. TCU->TCU_RESTEC == "1") .Or. (ABS->ABS_RESTEC <> "1" .And. TCU->TCU_RESTEC <> "1")) 
			lValid := .T.
			Exit
		EndIf
	Next nLinhas
EndIf

If !lValid
	Help("",1,"At330ResTec",,STR0240,2,0) //"Verifique no local se o tipo é o mesmo do tipo escolhido."
EndIf

RestArea(aAreaBKP)

Return(lValid)

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntCa
Interface para adicionar caracteristica do atendente

@sample 	At330IntCa(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntCa(oTreeDtFil)

Local lRetorno  := .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{200,200,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodCar	:= Nil												// Objeto MsGet funcao.
Local cCodCar	:= Space(TAMSX3("TCZ_COD")[1])                                       	// Codigo da funcao.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.16 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0223 SIZE 50,10 OF oDlg PIXEL  // "Característica: "
	@ aPosObj[1,1]+1,aPosObj[1,2]+38 MSGET oGCodCar VAR cCodCar PICTURE "@!" F3 "TCZ" SIZE 3,5 OF oDlg VALID ExistCpo("TCZ",cCodCar) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1],aPosObj[1,2]+71 TYPE 1  ACTION (IIF(At330VAdCR(oTreeDtFil,cCodCar),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAdCR
Valida e adiciona a caracteristica na pasta Filtrar Atendentes por Caracteristica.

@sample 	At330VAdCR(oTreeDtFil,aCarac)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Caracteristica do Atendente.

@return		ExpL 	Verdadeiro / Falso

@author	services
@since		14/10/2015
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAdCR(oTreeDtFil,aCarac)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescCar	  := ""     		// Descricao da caracteristica.
Local nPosPasta   := 0				// Posicao da pasta de funcoes na carga do Tree.
Local nPosItem    := 0				// Posicao de uma determinada funcao.
Local nX          := 0
Local cCodCar	  := ""

Default aCarac  := "" 				// Codigo da Caracteristica.

IF ValType(aCarac)=='A'
	FOR nX := 1 TO Len(aCarac)
		If !Empty(aCarac[nX])
			If ExistCpo("TCZ",aCarac[nX])
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCRC"  })
				If nPosPasta > 0
					nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == aCarac[nX] })
					If nPosItem == 0
						If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILCRC")
							cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
							cDescCar := FDESC("TCZ",aCarac[nX],"TCZ_DESC",,xFilial("TCZ"))                               
							cDescCar := Capital(Alltrim(cDescCar))
							oTreeDtFil:AddItem(STR0223+cDescCar,cIdTree,"PMSTASK4",,,,2) // "Característica: "
							aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,aCarac[nX]})
							oTreeDtFil:EndTree()
						EndIf
					Else
						lRetorno := .F.
						MsgStop(STR0225+chr(10)+STR0226,STR0172)  // "Característica duplicado!"#"Remova esta característica do filtro e adicione novamente."#"Atenção"
					EndIf
				EndIf
			Else
				lRetorno := .F.
			EndIf
		Else 
			lRetorno := .F.
			MsgAlert(STR0227,STR0172)  // "Característica não informado!"#"Atenção"
		EndIf
	NEXT nX
ELSE
	cCodCar := aCarac

	If !Empty(cCodCar)
		If ExistCpo("TCZ",cCodCar)
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCRC"  })
			If nPosPasta > 0
				nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodCar })
				If nPosItem == 0
					If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILCRC")
						cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
						cDescCar := FDESC("TCZ",cCodCar,"TCZ_DESC",,xFilial("TCZ"))                               
						cDescCar := Capital(Alltrim(cDescCar))
						oTreeDtFil:AddItem(STR0223+cDescCar,cIdTree,"PMSTASK4",,,,2) // "Característica: "
						aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodCar})
						oTreeDtFil:EndTree()
					EndIf
				Else
					lRetorno := .F.
					MsgStop(STR0225+chr(10)+STR0226,STR0172)  // "Característica duplicado!"#"Remova esta característica do filtro e adicione novamente."#"Atenção"
				EndIf
			EndIf
		Else
			lRetorno := .F.
		EndIf
	Else 
		lRetorno := .F.
		MsgAlert(STR0227,STR0172)  // "Característica não informado!"#"Atenção"
	EndIf
ENDIF

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330IntCu
Interface para adicionar curso do funcionario

@sample 	At330IntCu(oTreeDtFil)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente | Filtro. 

@return		ExpL 	Verdadeiro

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Static Function At330IntCu(oTreeDtFil)

Local lRetorno  := .T.												// Retorno da rotina.
Local oDlg 		:= Nil     											// Janela principal.
Local aSize     := MsAdvSize(.F.)										// Dimensao da janela criada pelo Protheus.
Local aObjects  := {{200,200,.T.,.T.}} 							// Deficao do objeto.
Local aInfo     := {aSize[1],aSize[2],aSize[3],aSize[4],3,3}		// Area de trabalho dos objetos.
Local aPosObj   := MsObjSize( aInfo, aObjects )	   					// Dimensoes da janela principal.
Local cTitulo	:= STR0056											// Titulo da janela principal (Adicionar).
Local oGCodCur	:= Nil												// Objeto MsGet funcao.
Local cCodCur	:= Space(TAMSX3("RA1_CURSO")[1])                   	// Codigo da funcao.
Local oBtnOk	:= Nil												// Botao OK.

DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7]*0.05,0 to aSize[6]*0.05,aSize[5]*0.15 OF oMainWnd PIXEL

	@ aPosObj[1,1]+2,aPosObj[1,2] SAY STR0224 SIZE 50,10 OF oDlg PIXEL  // "Curso: "
	@ aPosObj[1,1]+1,aPosObj[1,2]+28 MSGET oGCodCur VAR cCodCur PICTURE "@!" F3 "RA1" SIZE 3,5 OF oDlg VALID ExistCpo("RA1",cCodCur) PIXEL
	
	DEFINE SBUTTON oBtnOk FROM aPosObj[1,1],aPosObj[1,2]+65 TYPE 1  ACTION (IIF(At330VAdCU(oTreeDtFil,cCodCur),oDlg:End(),lRetorno := .F.))  ENABLE OF oDlg
	
ACTIVATE DIALOG oDlg CENTERED

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VAdCU
Valida e adiciona o curso na pasta Filtrar Atendentes por Curso.

@sample 	At330VAdCU(oTreeDtFil,aCodCur)

@param		ExpO1 	Objeto DBTree Detalhes do Atendente / Filtro.
			ExpC2	Curso do Funcionário.

@return		ExpL 	Verdadeiro / Falso

@author		Anderson Silva
@since		24/01/2013
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VAdCU(oTreeDtFil,aCodCur)

Local lRetorno	  := .T.			// Retorno da rotina.
Local cIdTree	  := ""				// Id utilizado para identificar o item do tree.
Local cDescCur	  := ""     		// Descricao do curso.
Local nPosPasta   := 0				// Posicao da pasta de funcoes na carga do Tree.
Local nPosItem    := 0				// Posicao de uma determinada funcao.
Local nX          := 0
Local cCodCur	  := ""

Default aCodCur  := "" 				// Codigo do Curso

IF ValType(aCodCur)=='A'
	FOR nX := 1 TO Len(aCodCur)
		If !Empty(aCodCur[nX])
			If ExistCpo("RA1",aCodCur[nX])
				nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCUR"  })
				If nPosPasta > 0
					nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == aCodCur[nX] })
					If nPosItem == 0
						If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILCUR")
							cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
							cDescCur := FDESC("RA1",aCodCur[nX],"RA1_DESC",,xFilial("RA1"))                               
							cDescCur := Capital(Alltrim(cDescCur))
							oTreeDtFil:AddItem(STR0224+cDescCur,cIdTree,"PMSTASK4",,,,2) // "Curso:"
							aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,aCodCur[nX]})
							oTreeDtFil:EndTree()
						EndIf
					Else
						lRetorno := .F.
						MsgStop(STR0228+chr(10)+STR0229,STR0172)  // "Curso duplicado!"#"Remova esta curso do filtro e adicione novamente."#"Atenção"
					EndIf
				EndIf
			Else
				lRetorno := .F.
			EndIf
		Else 
			lRetorno := .F.
			MsgAlert(STR0230,STR0172)  // "Curso não informado!"#"Atenção"
		EndIf
	NEXT nX
ELSE
	cCodCur := aCodCur
	If !Empty(cCodCur)
		If ExistCpo("RA1",cCodCur)
			nPosPasta := aScan(oTreeDtFil:Cargo,{|x| x[1] == "FILCUR"  })
			If nPosPasta > 0
				nPosItem := aScanX(oTreeDtFil:Cargo[nPosPasta],{|x,y| y > 1 .AND. x[2] == cCodCur })
				If nPosItem == 0
					If oTreeDtFil:TreeSeek("FILTRAR") .AND. oTreeDtFil:TreeSeek("FILCUR")
						cIdTree  := Soma1(StrZero(oTreeDtFil:Total(),6))
						cDescCur := FDESC("RA1",cCodCur,"RA1_DESC",,xFilial("RA1"))                               
						cDescCur := Capital(Alltrim(cDescCur))
						oTreeDtFil:AddItem(STR0224+cDescCur,cIdTree,"PMSTASK4",,,,2) // "Curso:"
						aAdd(oTreeDtFil:Cargo[nPosPasta],{cIdTree,cCodCur})
						oTreeDtFil:EndTree()
					EndIf
				Else
					lRetorno := .F.
					MsgStop(STR0228+chr(10)+STR0229,STR0172)  // "Curso duplicado!"#"Remova esta curso do filtro e adicione novamente."#"Atenção"
				EndIf
			EndIf
		Else
			lRetorno := .F.
		EndIf
	Else 
		lRetorno := .F.
		MsgAlert(STR0230,STR0172)  // "Curso não informado!"#"Atenção"
	EndIf
ENDIF

Return( lRetorno )

//------------------------------------------------------------------------------
/*/{Protheus.doc} At330VsRest 
Visualiza o Atendente.

@sample 	At330VsRest(cCodAtend)

@param		ExpC1	Codigo do Atendente.

@return		ExpL	Verdadeiro.

@author	services
@since		14/10/2015
@version	P12   
/*/
//------------------------------------------------------------------------------
Function At330VsRest(cCodAtend)

Local lRetorno := .T. 		// Retorno na rotina.

If !Empty(cCodAtend)
	DbSelectArea("AA1")
	AA1->(DbSetOrder(1))//
	If AA1->(DbSeek(xFilial("AA1")+cCodAtend))
		lRetorno := .T.
		FWExecView(Upper(STR0221),"VIEWDEF.TECA012",1,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)    //"Restrições do atendente"
	Else
		MsgAlert(STR0157,STR0158) // "Selecione um atendente para visualizar."###"Atenção"
	EndIf
EndIf

Return( lRetorno )
  
//------------------------------------------------------------------------------
/*/{Protheus.doc} At330GrvCus
Realiza a gravação do custo da alocação conforme o codigo da ABB_IDCFAL

@sample 	At330GrvCus(cIdcFal)
@param		ExpC1	Codigo do campo ABB_IDCFAL(Contrato+Item+Origem)

@author		services
@since		22/02/2017
@version	P12
/*/
//------------------------------------------------------------------------------
Function At330GrvCus( cIdcFal, cCodTWZ, lRemAloc )
Local lRetorno 	:= .T.
Local cCtrato 	:= Substr(cIdcFal,1,TAMSX3("TFF_CONTRT")[1])
Local aAreaABB  := ABB->(GetArea())
Local aAreaTWZ	:= TWZ->(GetArea())
Local cAliasABB := GetNextAlias()
Local cCodTFL	:= ""
Local cItem		:= ""
Local cOrcamen	:= ""
Local cProdut	:= ""
Local nCusto	:= 0

Default cCodTWZ	:= "" // esta variável indica quando é alteração ou exclusão de um lançamento
Default lRemAloc := .F. // para idenficar quando é remoção de alocação

BeginSql Alias cAliasABB

	SELECT SUM(ABB_CUSTO) CUSTO, ABB.ABB_IDCFAL,ABB.ABB_LOCAL, TFF.TFF_COD, TFF.TFF_CODPAI, 
			TFL.TFL_CODPAI, ABQ.ABQ_PRODUT, ABQ.ABQ_CODTFF, ABB.ABB_CODTWZ
		FROM %table:ABB% ABB

		  INNER JOIN %table:ABQ% ABQ ON ABQ_FILIAL = %xFilial:ABQ%
		   AND ABQ.%notDel%
		   AND ABQ_CONTRT || ABQ_ITEM || ABQ_ORIGEM = %Exp:cIdcFal%

		  JOIN %table:TFF% TFF ON TFF_FILIAL = ABQ.ABQ_FILTFF
		   AND TFF_CONTRT = %Exp:cCtrato%
		   AND TFF_COD = ABQ_CODTFF
		   AND TFF.%notDel%
		  
		  JOIN %table:TFL% TFL ON TFL_FILIAL = ABQ.ABQ_FILTFF
		   AND TFL_CODIGO = TFF_CODPAI
		   AND TFF.%notDel% 

		 WHERE ABB_FILIAL = %xFilial:ABB%
		   AND ABB.ABB_IDCFAL = %Exp:cIdcFal%
		   AND ABB.ABB_ATIVO = '1'
		   AND ABB.%notDel%

		GROUP BY ABB.ABB_IDCFAL,ABB.ABB_LOCAL, TFF.TFF_COD, TFF.TFF_CODPAI, 
				TFL.TFL_CODPAI, ABQ.ABQ_PRODUT, ABQ.ABQ_CODTFF, ABB.ABB_CODTWZ

EndSql

If Empty(cCodTWZ)
	cCodTWZ 	:= (cAliasABB)->ABB_CODTWZ
EndIf
cOrcamen	:= (cAliasABB)->TFL_CODPAI
cCodTFL		:= (cAliasABB)->TFF_CODPAI
cItem		:= (cAliasABB)->TFF_COD
cProdut		:= (cAliasABB)->ABQ_PRODUT

While (cAliasABB)->( !Eof() )
	nCusto		+= (cAliasABB)->CUSTO
	(cAliasABB)->(DbSkip())
End

If !Empty(cCodTWZ)
	If nCusto > 0
		// Atualiza o valor do custo na TWZ
		lRetorno := At995AtCus( cOrcamen, cCodTWZ, {{"TWZ_VLCUST", nCusto }}, .T. )
	Else
		DbSelectArea("TWZ")
		TWZ->( DbSetOrder( 1 ) )  // TWZ_FILIAL + TWZ_CODIGO
		TWZ->( DbSeek( xFilial("TWZ") + cCodTWZ ) )
		cOrcamen := TWZ->TWZ_CODORC
		// Remove o registro
		lRetorno := At995ExcC( cOrcamen, cCodTWZ, .T.)
	EndIf
ElseIf !lRemAloc .And. nCusto > 0
	//Gera o custo na tabela TWZ somente quando for inclusão de agenda
	cCodTWZ := At995Custo( cOrcamen, cItem, cCodTFL, cProdut, "1", nCusto, "TECA330", .T.)
	If Empty(cCodTWZ)
		lRetorno := .F.
	EndIf
EndIf

//Atualiza os campos da ABB com a codigo do custo
At300CodTWZ(cCodTWZ,cIdcFal)

DbSelectArea(cAliasABB)
(cAliasABB)->(DbCloseArea())

RestArea(aAreaABB)
RestArea(aAreaTWZ)
Return lRetorno

//------------------------------------------------------------------------------
/*/{Protheus.doc} At300CodTWZ
Atualiza os campos da alocação(ABB) com o codigo do custo gerado

@sample 	At300CodTWZ(cCodTWZ,cIdcFal)
@param		ExpC1 - Codigo da tabela de custos(TWZ) que será atualizado
@param		ExpC2 - Codigo do campo ABB_IDCFAL(Contrato+Item+Origem)

@author		services
@since		22/02/2017
@version	P12
/*/
Static Function At300CodTWZ(cCodTWZ,cIdcFal)

Local cAliasABB := GetNextAlias()

BeginSql Alias cAliasABB
	SELECT ABB.R_E_C_N_O_ ABB_RECNO
	  FROM %table:ABB% ABB
	 WHERE ABB.ABB_FILIAL = %xFilial:ABB%
	   AND ABB.%NotDel% 
	   AND ABB.ABB_IDCFAL = %Exp:cIdcFal%
	   AND ABB.ABB_CODTWZ = ' ' 
	   AND ABB.ABB_CUSTO > 0
EndSql

While (cAliasABB)->( !Eof() )
	// Posiciona nos itens que sofrerão as atualizações
	ABB->( DbGoTo( (cAliasABB)->ABB_RECNO ) )
	ABB->(RecLock("ABB",.F.))
	ABB->ABB_CODTWZ := cCodTWZ
	ABB->(MsUnlock())
	(cAliasABB)->(DbSkip())
EndDo

DbSelectArea(cAliasABB)
(cAliasABB)->(DbCloseArea())

Return

/*/{Protheus.doc} At300CodTWZ
@descriptio 	Atualiza os campos da alocação(ABB) com o codigo do custo gerado
@sample 		At300CodTWZ(cCodTWZ,cIdcFal)
@version		P12
@author			josimar.assuncao
@since			06.03.2017
@param			cConfigAloc, caracter, configuração de alocação
@param			cCodTWZ, caracter, referência, variável para retorno da TWZ identificada
/*/
Static Function At330HasTWZ( cConfigAloc, cCodTWZ )
Local lFound := .F.
Local cQrySearch := ""

If !Empty( cConfigAloc )
	cQrySearch := GetNextAlias()
	cCodTWZ := ""

	BeginSQL Alias cQrySearch
		SELECT DISTINCT ABB_CODTWZ
		FROM %Table:ABB% ABB
		WHERE ABB_FILIAL = %xFilial:ABB%
			AND ABB_IDCFAL = %Exp:cConfigAloc%
			AND ABB_CODTWZ <> ' '
			AND ABB.%NotDel%
	EndSQL

	If (cQrySearch)->(!EOF())
		lFound := .T.
		cCodTWZ := (cQrySearch)->ABB_CODTWZ
	EndIf
	(cQrySearch)->(DbCloseArea())
EndIf

Return lFound

//------------------------------------------------------------------------------
Static Function Tc330Copy(cFileOri,cFileName)
	Local cFileDest := alltrim(GetTempPath(.T.)) 
	
	If substr(cFileDest,len(cFileDest),1) != "\"
		cFileDest += "\"
	EndIf
	cFileDest += cFileName
	
	CpyS2T("\memorando\" + cFileName,GetTempPath(.T.))
	Sleep(1500)
Return cFileDest
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} 
Realiza a manutenação do funcionario na TAREFA DO FUNCIONARIO 
@param  cAtendente, Caracter, Código do atendente
@param  cLocalAten, Caracter, Código do local 
@param  cPosto, Caracter, Código do posto (Função do atendente) 
@param  dDtIni, Data, Data inicio da agenda 
@param  dDtIni, Data, Data fim da agenda 
@param  lExclui, Lógico, Verdadeiro = exclusão total / Falso = Exclusão parcial (apenas atualização de datas)
@return Nenhum
@author Eduardo Gomes Júnior
@since 09/01/2018
/*/
//------------------------------------------------------------------------------------------
Function At330TarNov(cAtendente, cLocalAten, cPosto, dDtIni, dDtFim, lExclui, cTpExclui, cSituacao)

Local aArea 		:= GetArea()
local cCodFunc		:= ""
Local lNewTar		:= .F.
Local aNumRecTar	:= {}
Local lGravaTN6		:= .T.
Local lIncliTN6		:= .F.

Default cAtendente	:= ""
Default cLocalAten	:= ""
Default cPosto 		:= ""
Default dDtIni		:= Ctod("//")
Default dDtFim		:= Ctod("//")
Default lExclui		:= .F.
Default cTpExclui	:= ""
//Default cSituacao	:= "01"

If	!Empty(dDtIni) .AND. !Empty(dDtFim) 	

dbSelectArea("AA1")
dbSetOrder(1)
If	dbSeek(xFilial("AA1")+cAtendente)
	cCodFunc := AA1_CDFUNC
	If	Empty(cPosto)
		cPosto := AA1_FUNCAO
	Endif 
Endif 

aNumRecTar	:= At330MUltDt(cAtendente, cLocalAten, cPosto, cCodFunc )
lIncliTN6 	:= At330Situacao(cSituacao)

If	Len(aNumRecTar) > 0  

	If	aNumRecTar[1,1] > 0	 
		dbSelectArea("TN6")
		dbSetOrder(1)
		dbGoto(aNumRecTar[1,1])
	Endif 
	
Else 

	If	lIncliTN6 .And. Len(aNumRecTar) > 0

		dbSelectArea("TN6")
		dbSetOrder(1)	//TN6_FILIAL+TN6_CODTAR+TN6_MAT+DTOS(TN6_DTINIC)
		If	!dbSeek(xFilial("TN6")+aNumRecTar[1,2]+cCodFunc+Dtos(dDtIni))
			lGravaTN6 := .T.
			RecLock("TN6",.T.)
			TN6_FILIAL	:= xFilial("TN6")
			TN6_CODTAR	:= aNumRecTar[1,2]
			TN6_MAT		:= cCodFunc
			TN6_DTINIC	:= dDtIni
			TN6_DTTERM	:= dDtFim
			MsUnLock()
		Else
			lGravaTN6 := .F.
		Endif
		
	Endif 						

	//Adiciona novo funcionario na tarefa de risco
	
	lNewTar		:= .T.

Endif 	

If	!lNewTar

	If	lExclui

		If	cTpExclui == "C"	//Descolacamento (Exclusão) COMPLETA ou cancelamento total da agenda			
			RecLock("TN6",.F.)
			TN6->(DbDelete())
			MsUnLock()
//		Else
			//Descolacamento (Exclusão) PARCIAL ou cancelamento parcial da agenda 
//			RecLock("TN6",.F.)
//			TN6_DTINIC	:= dDtIni
//			TN6_DTTERM	:= dDtFim
//			MsUnLock()
		Endif 
					
	Else 
		
		If	( dDtIni - aNumRecTar[1,3] ) <= 3
			RecLock("TN6",.F.)
			TN6_DTTERM	:= dDtFim
			MsUnLock()
			
		Else
		
			If	lIncliTN6
				RecLock("TN6",.T.)
				TN6_FILIAL	:= xFilial("TN6")
				TN6_CODTAR	:= aNumRecTar[1,2]
				TN6_MAT		:= cCodFunc
				TN6_DTINIC	:= dDtIni
				TN6_DTTERM	:= dDtFim
				MsUnLock()
			Endif 	
							
//			Else  			
//				lGravaTN6 := .F.
//				RecLock("TN6",.F.)
//				TN6_DTTERM	:= dDtFim
//				MsUnLock()
//			Endif				

		Endif 
			
	Endif
	
Endif

Endif  	 

RestArea(aArea)

Return 

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330MUltDt
Retorna o RECNO e ultima TAREFA existente na TN6 para o atendente/local/posto/funcionario informados
@param  cAtendente, Caracter, Código do atendente
@param  cLocalAten, Caracter, Código do local 
@param  cPosto, Caracter, Código do posto (Função do atendente) 
@param  cCodFunc, Caracter, Código do funcionario
@return Nenhum
@author Eduardo Gomes Júnior
@since 27/11/2017
/*/
//------------------------------------------------------------------------------------------
Function At330MUltDt(cAtendente, cLocalAten, cPosto, cCodFunc)

Local cQueryMAX		:= GetNextAlias()
Local cQueryTN6		:= GetNextAlias()
Local dDUltData		:= Ctod("//")
Local aRetorno		:= {}

BeginSql Alias cQueryMAX

	COLUMN ULTDATA    AS DATE

	SELECT MAX(TN6_DTTERM) AS ULTDATA 	
	FROM %Table:TN5% TN5
	INNER JOIN %table:TN6% TN6 ON ( TN6_FILIAL = %exp:xFilial('TN6')% AND TN6_CODTAR = TN5_CODTAR AND TN6_MAT = %exp:cCodFunc% AND TN6.%notDel% )  
	WHERE 
	TN5.TN5_FILIAL			= %exp:xFilial('TN5')%
	AND TN5.TN5_LOCAL		= %exp:cLocalAten%
	// Analise de posto desabilitada. Será considerada o posto informado no contrato (At330Funcao)
	AND TN5.TN5_POSTO		= %exp:cPosto% 
	AND TN5.%NotDel%

EndSql


dDUltData := ULTDATA

If	!EMPTY(dDUltData)	

	BeginSql Alias cQueryTN6
	
		COLUMN TN6_DTINIC AS DATE
		COLUMN TN6_DTTERM AS DATE
		
		SELECT TN5_CODTAR, TN5_LOCAL, TN5_POSTO, TN6_MAT, TN6_DTINIC ,TN6_DTTERM, TN6.R_E_C_N_O_ AS TN6RECNO 	
		FROM %Table:TN5% TN5
		INNER JOIN %table:TN6% TN6 ON ( TN6_FILIAL = %exp:xFilial('TN6')% AND TN6_CODTAR = TN5_CODTAR AND TN6_MAT = %exp:cCodFunc% AND TN6.%notDel% )  
		WHERE 
		TN5.TN5_FILIAL			= %exp:xFilial('TN5')%
		AND TN5.TN5_LOCAL		= %exp:cLocalAten%
		//Analise de posto desabilitada. Será considerada o posto informado no contrato (At330Funcao)		
		AND TN5.TN5_POSTO		= %exp:cPosto%		  
		AND TN6.TN6_DTTERM		= %exp:dDUltData%
		AND TN5.%NotDel%
	
	EndSql
	
Else 

	BeginSql Alias cQueryTN6
	
		COLUMN TN6_DTINIC AS DATE
		COLUMN TN6_DTTERM AS DATE
		
		SELECT TN5_CODTAR, TN5_LOCAL, TN5_POSTO, TN6_MAT, TN6_DTINIC ,TN6_DTTERM, TN6.R_E_C_N_O_ AS TN6RECNO 	
		FROM %Table:TN5% TN5
		LEFT JOIN %table:TN6% TN6 ON ( TN6_FILIAL = %exp:xFilial('TN6')% AND TN6_CODTAR = TN5_CODTAR AND TN6_MAT = %exp:cCodFunc% AND TN6.%notDel% )  
		WHERE 
		TN5.TN5_FILIAL			= %exp:xFilial('TN5')%
		AND TN5.TN5_LOCAL		= %exp:cLocalAten%
		//Analise de posto desabilitada. Será considerada o posto informado no contrato (At330Funcao)
		AND TN5.TN5_POSTO		= %exp:cPosto%		  
		AND TN5.%NotDel%
	
	EndSql

Endif 	

If (cQueryTN6)->(!EOF())
	aAdd( aRetorno, { (cQueryTN6)->TN6RECNO, (cQueryTN6)->TN5_CODTAR, (cQueryTN6)->TN6_DTTERM } )
EndIf

(cQueryMAX)->(DbCloseArea())
(cQueryTN6)->(DbCloseArea())

Return(aRetorno)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330Funcao
Retona função (posto) informado no contrato
@param  cNrContrato, Caracter, Número do contrato
@return cRetorno, Caracter, Código da função
@author Eduardo Gomes Júnior
@since 06/02/2018
/*/
//------------------------------------------------------------------------------------------
Static Function At330Funcao(cNrContrato)

Local aArea		:= GetArea()
Local cRetorno	:= ""

DbSelectArea("ABQ")
DbSetOrder(1)// ABQ_FILIAL + ABQ_CONTRT + ABQ_ITEM + ABQ_ORIGEM
If	dbSeek(xFilial("ABQ")+cNrContrato)

	DbSelectArea("TFF")
	DbSetOrder(1)	// TFF_FILIAL + TFF_COD
	If	DbSeek( ABQ->( ABQ_FILTFF + ABQ_CODTFF ) )
		cRetorno := TFF_FUNCAO
	Endif 
	
Endif

RestArea(aArea)

Return cRetorno	 

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330Situacao
Avalia se situação informada cria agenda (tarefa para o funcionario) na tabela TN6
@param  cSituacao, Caracter, Código da Situação
@return lRetorno, Lógico, Verdadeiro/Falso
@author Eduardo Gomes Júnior
@since 06/02/2018
/*/
//------------------------------------------------------------------------------------------
Function At330Situacao(cSituacao)

Local lRetorno	:= .F.
Local cSitInc	:=  ( /*01 -*/ SIT_MOV_EFETIVO +"|"+ /*02 -*/ SIT_MOV_TREINAM +"|"+ /*03 - */SIT_MOV_FOLGUIS +"|"+ /*04 -*/ SIT_MOV_ALMOCIS +"|"+; 
 					  /*05 -*/ SIT_MOV_CORTESI +"|"+ /*06 -*/ SIT_MOV_REFORCO +"|"+ /*07 - */SIT_MOV_SERVEXT +"|"+ /*22 - */SIT_MOV_EXCEDEN +"|"+; 
 			          /*24 -*/ SIT_MOV_COBERTU )
 			          
Default cSituacao := "01"  			          

If	cSituacao $ cSitInc 	
	lRetorno := .T.
Endif 

Return(lRetorno)
