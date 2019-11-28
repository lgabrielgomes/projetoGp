#INCLUDE "PROTHEUS.CH"
#INCLUDE "TECA900.CH"
#INCLUDE "FILEIO.CH"   
#INCLUDE "TOPCONN.CH"

//Define Atraso, Saida Antecipada, Hora Extra Conforme Tabela I5 - SX5
#DEFINE I5_ATRASO		'02'
#DEFINE I5_SAIANT		'03'
#DEFINE I5_HREXTR		'04'

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA900()

Realiza a Geração Automatica de Atendimentos da O.S quando utilizar o Controle Alocação

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA900()

Local aArea		:= GetArea()
Local cIdcfal		:= Space(TamSX3("ABB_IDCFAL")[1])
Local cCondicao	:= "%"
Local nTamOs		:= TAMSX3("AB6_NUMOS")[1]
Local nTamCtr		:= TAMSX3("AB6_CONTRT")[1]
Local cNumOs		:= ""
Local nTotal		:= 0
Local oDlg
Local oMeter
Local nMeter
Local nX
Local oPanTop
Local oPanBot
Local oSayMsg
Local oSay
Local oFont
Local cTitulo		:= ''
Local cFuncao		:= ''
//----------------------------------------------------------------------------
// Parametros Utilizados no Pergunte                                                             
// 
// MV_PAR01: Atendente De ?
// MV_PAR02: Atendente Ate ?                                               	  
// MV_PAR03: Data Inicio De ?                                                     
// MV_PAR04: Data Inicio Ate ?                                                                                                    
// MV_PAR05: Cliente De ? 
// MV_PAR06: Cliente Ate ?
// MV_PAR07: Contrato De ?
// MV_PAR08: Contrato Ate ?
// MV_PAR09: O.S. De ?
// MV_PAR10: O.S. Ate ?
// MV_PAR11: Serviço Padrao ?         
// MV_PAR12: Local De ?
// MV_PAR13: Local Ate ?      
// MV_PAR20: Diretorio do Log ?                     			  
//------------------------------------------------------------------------------

lContinua := Pergunte("TEC900",.T.)

If lContinua .AND. (Empty(MV_PAR11)  .OR. !ExistCpo("AA5", MV_PAR11, 1))
	Aviso(STR0001,STR0003,{STR0002},2) //"Atenção"##"Um código de Serviço Padrão para geração do atendimento deve ser obrigatoriamente preenchido."##OK!
ElseIf lContinua	
	//Ativo, Chegou como Nao e Atendeu tambem Nao.
	cCondicao += "ABB.ABB_IDCFAL != '"+cIdcfal+"' AND " 
	cCondicao += "ABB.ABB_ATIVO = '1' AND "
	
	If MV_PAR19 == 1 //inclusão
		cCondicao += "ABB.ABB_CHEGOU = 'N' AND "
		cCondicao += "ABB.ABB_ATENDE = '2' AND " 
	Else // exclusão
		cCondicao += "ABB.ABB_CHEGOU = 'S' AND "
		cCondicao += "ABB.ABB_ATENDE = '1' AND " 
	EndIf	
	
	//Filtro Tecnico De e Ate		
	If !Empty(MV_PAR01)
		cCondicao += "ABB.ABB_CODTEC >='" + MV_PAR01 + "' AND "
	EndIf						
	If !Empty(MV_PAR02)
		cCondicao += "ABB.ABB_CODTEC <='" + MV_PAR02 + "' AND "
	EndIf
	
	//Filtra De/Ate
	If !Empty(MV_PAR03)
		cCondicao += "TDV.TDV_DTREF >='" + DToS( MV_PAR03 ) + "' AND " 	
	EndIf		
	If !Empty(MV_PAR04)		
		cCondicao += "TDV.TDV_DTREF <='" + DToS( MV_PAR04 ) + "' AND "
	EndIf
	
	// Adiciona consistencia para os agendamentos sem O.S.
	If	!Empty(MV_PAR05) .Or. !Empty(MV_PAR06) .Or. ;
		!Empty(MV_PAR07) .Or. !Empty(MV_PAR08) .Or. ;
		!Empty(MV_PAR09) .Or. !Empty(MV_PAR10)		
		cCondicao += "(ABB.ABB_NUMOS = '      '  OR ("
	EndIf
	
	//Cliente De/Ate
	If !Empty(MV_PAR05)		
		cCondicao += "AB6.AB6_CODCLI >='" + MV_PAR05 + "' AND " 	
	EndIf		
	If !Empty(MV_PAR06)		
		cCondicao += "AB6.AB6_CODCLI <='" + MV_PAR06 + "' AND "
	EndIf						
	
	
	//Tratamento de Contrato/Serv. Extra/Ambos
	If MV_PAR16 == 1 //Contrato
		If !Empty(MV_PAR07)
			cCondicao += "ABQ.ABQ_CONTRT >='" + MV_PAR07 + "' AND ABQ.ABQ_ORIGEM = 'CN9' AND "
		EndIf
		If !Empty(MV_PAR08)
			cCondicao += "ABQ.ABQ_CONTRT <='" + MV_PAR08 + "' AND ABQ.ABQ_ORIGEM = 'CN9' AND "
		EndIf		
	ElseIf MV_PAR16 == 2 //Serviço Extra
		If !Empty(MV_PAR17)
			cCondicao += "ABQ.ABQ_CONTRT >='" + MV_PAR17 + "' AND ABQ.ABQ_ORIGEM = 'TFJ' AND "
		EndIf
		If !Empty(MV_PAR18)
			cCondicao += "ABQ.ABQ_CONTRT <='" + MV_PAR18 + "' AND ABQ.ABQ_ORIGEM = 'TFJ' AND "
		EndIf	
	Else //Ambos
		cCondicao += " (ABQ.ABQ_CONTRT >='" + MV_PAR07 + "' AND ABQ.ABQ_ORIGEM = 'CN9'  OR  "
		cCondicao += "  ABQ.ABQ_CONTRT >='" + MV_PAR17 + "' AND ABQ.ABQ_ORIGEM = 'TFJ') AND "
		cCondicao += " (ABQ.ABQ_CONTRT <='" + MV_PAR08 + "' AND ABQ.ABQ_ORIGEM = 'CN9'  OR  "
		cCondicao += "  ABQ.ABQ_CONTRT <='" + MV_PAR18 + "' AND ABQ.ABQ_ORIGEM = 'TFJ') AND " 	
	EndIf		
		
	//O.S. De e Ate
	If !Empty(MV_PAR09)
		cCondicao += "AB6.AB6_NUMOS >='" + MV_PAR09 + "' AND "	
	EndIf		
	If !Empty(MV_PAR10)
		cCondicao += "AB6.AB6_NUMOS <='" + MV_PAR10 + "' AND "			
	EndIf
	
	// Adiciona consistencia para os agendamentos sem O.S.
	If	!Empty(MV_PAR05) .Or. !Empty(MV_PAR06) .Or. ;
		!Empty(MV_PAR07) .Or. !Empty(MV_PAR08) .Or. ;
		!Empty(MV_PAR09) .Or. !Empty(MV_PAR10)
		If AllTrim(Right(cCondicao, 4)) == "AND"
			cCondicao := Substr(cCondicao, 1, Len(Alltrim(cCondicao)) - 4) + ")) AND "
		Else 
			cCondicao += ")) AND "
		EndIf	
	EndIf	
		
	//Local De e Ate
	If !Empty(MV_PAR12)
		cCondicao += "ABB.ABB_LOCAL >='" + MV_PAR12 + "' AND "
	EndIf
	If !Empty(MV_PAR13)
		cCondicao += "ABB.ABB_LOCAL <='" + MV_PAR13 + "' AND "
	EndIf		
	
	cCondicao += "%"	
	
	cAliasUI := At900Qry(cCondicao)
	
	DbSelectArea(cAliasUI)
	While !(cAliasUI)->(EOF())	
		nTotal++
		(cAliasUI)->(DbSkip())
	End
	
	(cAliasUI)->(DbGoTop())	
	If nTotal > 0 
		If MV_PAR19 == 1 //inclusão
			cTitulo := STR0004
			cFuncao	:= 'At900GerAt(cAliasUI,oDlg,oMeter,oSayMsg)'
		Else
			cTitulo := STR0025 //  'Excluindo Atendimento da O.S.'
			cFuncao	:= 'At900DelAt(cAliasUI,oDlg,oMeter,oSayMsg)'
		EndIf
			DEFINE MSDIALOG oDlg TITLE cTitulo FROM 0,0 TO 100,422 PIXEL STYLE DS_MODALFRAME //"Geração do Atendimento da O.S."
			oPanTop := TPanel():New( 0, 0, , oDlg, , , , , , 0, 0, ,  )
			oPanTop:Align := CONTROL_ALIGN_ALLCLIENT     
			
			oPanBot := TPanel():New( 0, 0, , oDlg, , , , ,/*CLR_YELLOW*/, 0, 25 , )
			oPanBot:Align := CONTROL_ALIGN_BOTTOM
			
			DEFINE FONT oFont NAME "Arial" SIZE 0,16
			@ 05,08 SAY oSay Var "<center>" + STR0005 + cValToChar(nTotal)+STR0006 + "</center>" PIXEL SIZE 210,65 HTML FONT oFont PIXEL OF oPanTop //"Serão processados "##" atendimentos."
				
			nMeter := 0
			oMeter := TMeter():New(02,7,{|u|if(Pcount()>0,nMeter:=u,nMeter)},nTotal,oPanBot,200,100,,.T.,,,.F.)			
			
			@ 10,02 SAY oSayMsg Var "<center>"+STR0007+"</center>" PIXEL SIZE 210,65 HTML FONT oFont PIXEL OF oPanBot //"Processando..."
			
		ACTIVATE DIALOG oDlg CENTERED ON INIT &cFuncao
	Else
		Aviso(STR0001,STR0008,{STR0002},2) //"Atenção"##"Não há registros para gerar atendimento conforme parametros informados."##{"OK"}			
	EndIf
	
	(cAliasUI)->(DbCloseArea())
	
EndIf

RestArea( aArea ) 

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900GerAt()

Realiza o Processamento do Pergunte na geração do Atendimento da O.S

@param ExpC:Alias da Tabela de processamento
@param ExpO:Dialog do Processamento
@param ExpO:Tmeter para atualizar o processamento
@param ExpO:Texto do processamento

@return ExpL: Retorna .T. quando houve sucesso na operação
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900GerAt(cAliasUI,oDlg,oMeter,oSayMsg)
Local cServico	:= MV_PAR11							// Codigo Serviço Padrao
Local cServExt	:= MV_PAR11							// Serviço para Hora Extra
Local nReg			:= 0									// Contador Gauge/Tmeter
Local aSeqTec		:= {}									// Sequencia dos Tecnicos
Local aAtende		:= {}
Local aItAten		:= {}
Local aChaveAA3	:= {}
Local aNumOS		:= {}
Local aOsContrt	:= {}
Local nPosTec		:= 0
Local dDataIni
Local cHoraIni
Local dDataFim
Local cHoraFim
Local aAreaABB
Local nI
Local cSequencia	:= "01"
Local cTotFat		:= 0
Local nTamItem	:= TamSX3("ABA_ITEM")[1]
Local nHrTotal	:= 0									//Total de Horas 
Local nHrExtra	:= 0									//Total de Horas Extras
Local nHrNormal	:= 0									//Total de Horas Normais
Local aCritica	:= {}
Local lGrpCob		:= .F.
Local nTamChave 	:= TamSX3("AB7_NUMOS")[1]+TamSX3("AB7_ITEM")[1]	
Local lContinua	:= .T.	
Local cCodGrup	:= ""
Local cErro		:= ""
Local cCondPV		:= ""
Local cTpCont		:= ""
Local cChave     	:= ""
Local cOsLocal	:= ""
Local cItemOS		:= ""
Local lItemOs		:= .F.
Local lSeek		:= .F.
Local lGerOS		:= .F.
Local cOcoGct		:= SuperGetMV("MV_OCOGCT",.F.,"")

Local aArea, aAreaAB6, aAreaADY, aAreaAA3 

(cAliasUI)->(dbGoTop())

While (cAliasUI)->(!Eof())	

	oMeter:Set(++nReg) // Atualiza Gauge/Tmeter
	oSayMsg:SetText("<center>"+STR0007+cValToChar(nReg)+"</center>")//"Processando..."
	//Inicializa Variaveis e Datas
	dDataIni	:= (cAliasUI)->ABB_DTINI
	cHoraIni	:= (cAliasUI)->ABB_HRINI
	dDataFim	:= (cAliasUI)->ABB_DTFIM
	cHoraFim	:= (cAliasUI)->ABB_HRFIM
	cServico	:= MV_PAR11
	cServExt	:= MV_PAR11
	nHrExtra	:= 0
	nHrNormal	:= 0
	lGrpCob	:= .F.	
	lContinua	:= .T.
	cCodGrup	:= ""	
	cChave		:= ""
	lGerOs		:= .F. 
				
	If Empty((cAliasUI)->ABB_NUMOS)			
		nPosOs := aScan(aOsContrt, {|x| x[1] == (cAliasUI)->ABB_IDCFAL } )		 	
		If nPosOs == 0	
			lGerOs := .T.
		Else	
			cChave := aOsContrt[nPosOs][2]
		Endif 		
	EndIf
	
	If lGerOs
	
		// Gerar O.S. para apontamento quando o agedamento for pela nova estrutura		
		aArea := GetArea()		
				
		aChaveAA3 := At900BaseCM(cAliasUI, (cAliasUI)->ABQ_CONTRT,(cAliasUI)->ABQ_ORIGEM)					
						
		If Len(aChaveAA3) > 0
			If (cAliasUI)->ABQ_ORIGEM == "CN9"
				
				cCodProp := At900GetPro((cAliasUI)->ABQ_CONTRT, (cAliasUI)->ABQ_CODTFF)  
				cCondPV  := Posicione("CN9", 1, xFilial("CN9")+(cAliasUI)->ABQ_CONTRT, "CN9_CONDPG")						
				cOcorren := cOcoGct
				cTpCont  := "3"
				
				AAG->(dbSetOrder(1))
				
				If Empty(cOcorren) .Or. ! AAG->(dbSeek(xFilial("AAG")+cOcorren)) 
					At900Crit(@aCritica,cAliasUI,STR0024) //"A ocorrência padrão para GCT (MV_OCOGCT), não foi encontrada."				
				EndIf

			ElseIf (cAliasUI)->ABQ_ORIGEM == "TFJ"
				
				cCodProp := (cAliasUI)->ABQ_CONTRT
				cCondPV  := Posicione("TFJ", 1, xFilial("TFJ")+(cAliasUI)->ABQ_CONTRT, "TFJ_CONDPG")						
				cOcorren := cOcoGct
				cTpCont  := "3"
				
				AAG->(dbSetOrder(1))
				
				If Empty(cOcorren) .Or. ! AAG->(dbSeek(xFilial("AAG")+cOcorren)) 
					At900Crit(@aCritica,cAliasUI,STR0024) //"A ocorrência padrão para GCT (MV_OCOGCT), não foi encontrada."				
				EndIf						
			Else
				
				DbSelectArea("AAH")
				AAH->(DbSetOrder(1))	
				AAH->(dbSeek(xFilial("AAH")+(cAliasUI)->ABQ_CONTRT))
			
				cCodProp := AAH->AAH_PROPOS
				cCondPV  := AAH->AAH_CONPAG
				cOcorren := AAH->AAH_OCOROS
				cTpCont  := "1"
							
			EndIf
				 
			If !Empty(cOcorren) 
				If (cAliasUI)->ABQ_ORIGEM == "TFJ"
					At900GerOs(cCodProp, aChaveAA3, cCondPV, cOcorren,; 
								Nil, @cOsLocal, Nil,Nil)				
				Else
					At240GerOs(cCodProp, aChaveAA3, cCondPV, cOcorren,; 
								(cAliasUI)->ABQ_CONTRT, @cOsLocal, Nil, cTpCont) 
				EndIf
			EndIf		
					
			cItemOs := ""
			
			For nI:=1 To Len(aChaveAA3)
				AB7->(dbSetOrder(5))			
				If AB7->(dbSeek(xFilial("AB7")+Substr(aChaveAA3[nI],9)))			
					While	AB7->AB7_FILIAL+AB7->AB7_CODFAB+AB7->AB7_LOJAFA+;
							AB7->AB7_CODPRO+AB7->AB7_NUMSER == xFilial("AB7")+Substr(aChaveAA3[nI],9)												
						If AB7->AB7_NUMOS == cOsLocal
							cItemOs := AB7->AB7_ITEM						
							Exit			
						EndIf					
						AB7->(dbSkip())					
					EndDo
				EndIf		
				If !Empty(cItemOs)
					Exit 
				EndIf
			Next nI		
			
			cChave := cOsLocal + cItemOs
				
			aAdd(aOsContrt, { (cAliasUI)->ABB_IDCFAL, cChave, cOsLocal, Nil, Nil } )		
							
		EndIf 
		
		RestArea( aArea )									
																			
	ElseIf Empty(cChave)
					 
		cChave := (cAliasUI)->ABB_CHAVE
								
	EndIf
		
	aArea := GetArea()
	
	DbSelectArea("AB7")
	AB7->(DbSetOrder(1))		
		
	DbSelectArea("ABQ")
	ABQ->(DbSetOrder(1))
		
	//Posiciona no Item da O.S.
	If !Empty(cChave) .And. (AB7->(MsSeek(xFilial("AB7")+Substr(cChave,1,nTamChave)))) //ABQ_CONTRT + ABQ_ITEM | AB7_NUMOS + AB7_ITEM	
		
		// Quando houver manutenção ajusta as datas
		If 	(cAliasUI)->ABB_MANUT == "1" 
			//Considera Horario Extra
			If !Empty((cAliasUI)->HRE_DTINI) .AND. !Empty((cAliasUI)->HRE_HRINI) .AND. !Empty((cAliasUI)->HRE_DTFIM) .AND. !Empty((cAliasUI)->HRE_HRFIM)																			
				dDataIni := (cAliasUI)->HRE_DTINI
				cHoraIni := (cAliasUI)->HRE_HRINI
				dDataFim := (cAliasUI)->HRE_DTFIM
				cHoraFim := (cAliasUI)->HRE_HRFIM												
				//Quando hora extra verifica se há codigo de serviço no Motivo (ABN)
				DbSelectArea("ABN")
				ABN->(DbSetOrder(1))
				//Se na manutencao usuario especificou servico diferente para hora extra. 
				If (cAliasUI)->ABR_USASER == "1" .AND. (ABN->(MsSeek(XFilial("ABN")+(cAliasUI)->ABR_MOTIVO)) .AND. !Empty(ABN->ABN_SERVIC))
					nHrExtra := HoraToInt((cAliasUI)->ABR_TEMPO) 				
					cServExt := ABN->ABN_SERVIC
				EndIf																		
			EndIf
			//Considera Atrasos (Horario Inicial)
			If !Empty((cAliasUI)->ATR_DTINI) .AND. !Empty((cAliasUI)->ATR_HRINI) 
				dDataIni := (cAliasUI)->ATR_DTINI
				cHoraIni := (cAliasUI)->ATR_HRINI
				//Recalcula Tempo da Hora Extra	
				If (nHrExtra > 0)
					nHrExtra := SubtHoras( dDataFim, cHoraFim, (cAliasUI)->ABB_DTFIM, (cAliasUI)->ABB_HRFIM)					
				EndIf		
			EndIf		
			//Considera Saida Antecipada (Horario Final)
			If !Empty((cAliasUI)->SAI_DTFIM) .AND. !Empty((cAliasUI)->SAI_HRFIM) 
				dDataFim := (cAliasUI)->SAI_DTFIM
				cHoraFim := (cAliasUI)->SAI_HRFIM
				//Recalcula Tempo da Hora Extra	
				If (nHrExtra > 0)
					nHrExtra := SubtHoras( dDataIni, cHoraIni, (cAliasUI)->ABB_DTINI, (cAliasUI)->ABB_HRINI)
				EndIf									
			EndIf	
																	
		EndIf
		
		//Calcula Total de Horas Realizadas
		nHrTotal	:= SubtHoras(dDataIni,cHoraIni,dDataFim,cHoraFim)
				
		//Calcula Horas Normais retirando o horario extra.
		If nHrExtra < 0 
			nHrExtra := 0
		EndIf
		nHrNormal	:= nHrTotal - nHrExtra		

		//Verifica se ha grupo de cobertura e o servico usado.
		//Quando chama AtBaseServ, se nao houver grupo de cobertura retorna vazio, entao preenche com o serviço do parametro.
		cServico := AtBaseServ(AB7->AB7_CODFAB,AB7->AB7_LOJAFA,AB7->AB7_CODPRO,AB7->AB7_NUMSER,(cAliasUI)->ABQ_PRODUT,@cCodGrup)

		// Quando Demanda procura o serviço conforme grupo de cobertura	
		If (cAliasUI)->ABQ_TPPROD == "3"
			//Se houver grupo cobertura ativa a flag.
			If !Empty(cServico)				
				lGrpCob	:= .T.				
			Else
				cServico	:= MV_PAR11
			EndIf		
		//Valida Impedindo a Geração do Atendimento caso seja usado um serviço relacionado a um grupo de cobertura
		//Para Mensal ou Material Operacional	
		ElseIf	!Empty(cCodGrup) .AND. !Empty(cServico) .AND. (cAliasUI)->ABQ_TPPROD != "3"
			//Caso seja Mensal e exista alguma alocação utilizando grupo de cobertura. Adota o serviço do parametro
			If cServico != MV_PAR11
				cServico := MV_PAR11
			EndIf
			
			SB1->( DbSetOrder( 1 ) ) 
			If SB1->( DbSeek( xFilial( "SB1" ) + (cAliasUI)->ABQ_PRODUT ) )							
				DbSelectArea("AAB")
				AAB->(DbSetOrder(1))
				//Se usar servico que consome G.C. em mensal/operacional no atendimento da o.s. sera consumido o G.C.
				If AAB->(DbSeek(XFilial("AAB")+cCodGrup+SB1->B1_TIPO+SB1->B1_GRUPO+(cAliasUI)->ABQ_PRODUT)) .AND. AAB->AAB_CODSER == MV_PAR11									 
					At900Crit(@aCritica,cAliasUI,STR0009) //"O Serviço Padrão para a alocação mensal não pode ser o mesmo serviço configurado para consumo do grupo de cobertura."
					lContinua	:= .F.
				EndIf
			EndIf
		Else
			cServico := MV_PAR11		
		EndIf	
		
		//Caso nao haja critica no uso do servico
		If lContinua
			//Determina a Sequencia do Atendimento da O.S.			
			cSequencia := ""			
			If (nPosTec := aScan(aSeqTec,{|x| x[1]==(cAliasUI)->ABB_CODTEC+Substr((cAliasUI)->ABB_CHAVE,1,nTamChave)})) > 0
				cSequencia += Soma1(aSeqTec[nPosTec][2])
				aSeqTec[nPosTec][2] := cSequencia 			
			Else			
				cSequencia := At900SeqT((cAliasUI)->ABB_CODTEC,Substr((cAliasUI)->ABB_CHAVE,1,nTamChave))
				AAdd(aSeqTec,{(cAliasUI)->ABB_CODTEC+Substr((cAliasUI)->ABB_CHAVE,1,nTamChave),cSequencia})
			EndIf
			
			cTotFat := IntToHora(nHrTotal)
			
			aAtende :=		{;
							AB7->AB7_NUMOS+AB7->AB7_ITEM,;		// Numero da O.S + Item
							cSequencia,;							// Sequencia de Atendimento
							(cAliasUI)->ABB_CODTEC,;				// Codigo do Técnico
							dDataIni,;								// Data de Chegada
							cHoraIni,;								// Hora de Chegada
							dDataFim,;								// Data de Saida
							cHoraFim,;								// Hora de Saida
							dDataIni,;								// Data de Inicio
							cHoraIni,;								// Hora de Inicio
							dDataFim,;								// Data de Fim
							cHoraFim,;								// Hora de Fim
							AB7->AB7_CODPRB,;						// Codigo da Ocorrencia
							"2",;									// Tipo(1= Encerrado,2=Aberta)
							cTotFat,;								// Horas Faturadas
							AB7->AB7_NUMOS;						// Numero da O.S 
							}					
			aItAten :=		{{;					
							StrZero(1,nTamItem),;				// Item (ABA)
							(cAliasUI)->ABQ_PRODUT,;				// Cod. Prod (ABA)
							nHrNormal,;							// Quantidade
							cServico,;								// Servico Padrao
							If(lGrpCob,"1","2");					// Força Grupo de Cobertura
							}}
							
			If nHrExtra > 0 // Quando houver codigo de serviço diferente na tabela ABN utiliza o serviço do total da hora extra.
				AAdd(aItAten,;
							{;					
							StrZero(2,nTamItem),;				// Item (ABA)
							(cAliasUI)->ABQ_PRODUT,;				// Cod. Prod (ABA)
							nHrExtra,;								// Quantidade
							cServExt,;								// Servico Padrao
							"2";									// Força Grupo de Cobertura
							})		
			EndIf
	
			Begin Transaction				 	
			
			If At900IncAt(aAtende,aItAten,3)
				If !At900AtABB((cAliasUI)->ABBRECNO,aAtende[1],aAtende[2],aAtende[3],(cAliasUI)->ABB_CODIGO,aAtende[15])
					DisarmTransaction()
					At900Crit(@aCritica,cAliasUI,STR0010) //"Erro ao Atualizar a Agenda referente ao Atendimento da O.S."
				Else 
					nPos := aScan(aOsContrt, { |x| x[2] == AB7->AB7_NUMOS+AB7->AB7_ITEM})
					If nPos > 0
						aOsContrt[nPos][4] := aAtende
						aOsContrt[nPos][5] := aItAten
					Endif						
				EndIf				
			Else
				DisarmTransaction()				
				cErro := ""
				AEval(GetAutoGRLog(),{|x| cErro += x+CRLF })
				At900Crit(@aCritica,cAliasUI,STR0011+CRLF+cErro) //"Erro ao Incluir Atendimento da O.S. para Alocação."
			EndIf
			
			End Transaction
											
		EndIf
				
	Else	
		At900Crit(@aCritica,cAliasUI,STR0012) //"Não Encontrado Item da O.S. para Alocação."
	EndIf
	
	RestArea( aArea )
	(cAliasUI)->(DbSkip())
		
End

// Encerra o atendimento gerado para a nova estrutura de alocação
If Len(aOsContrt) > 0	
	For nI := 1 to Len(aOsContrt)			
		If aOsContrt[nI][4] <> Nil
			aOsContrt[nI][4][13] := "1"			
			At900IncAt(aOsContrt[nI][4],aOsContrt[nI][5],4)
		EndIf			
	Next nI	
EndIf 

If nReg == 0
	Aviso(STR0001,STR0013,{STR0002},2) //"Atenção"##"Não há registros para gerar atendimento conforme parametros informados."##{"OK"}
ElseIf Len(aCritica) == 0
 	Aviso(STR0001,STR0014+ cValToChar(nReg) + STR0015,{STR0002},2) //"Atenção"##"Foram gerados:"##" atendimentos de ordens de serviço de alocação."##{"OK"}		
Else		
	Aviso(STR0001,STR0014+cValToChar((nReg-Len(aCritica)))+STR0015; //"Atenção"##"Foram gerados:"##" atendimentos de ordens de serviço de alocação."##
	+STR0016+CRLF+STR0017+TxLogPath("GerAtend"),{STR0002},2) //" Ocorreram erros na geração do atendimento da O.S."##"Foi gerado o log no arquivo "##"OK"	
EndIf

oDlg:End()

Return( Len(aCritica) == 0 )


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900IncAt()

Inclui o Atendimento da O.S via ExecAuto(Teca460)

@param ExpA:Array com os dados da ABB para a execAuto
@param ExpC:Sequencia que será utilizada na geração do atendimento
@param ExpN:Nopc para inclusão do atendimento da O.S (3 - Inclusão)

@return ExpL: Retorna .T. quando houve sucesso na execução da execauto 
/*/
//--------------------------------------------------------------------------------------------------------------------

Function At900IncAt(aAtende,aItAten,nOpcx)

Local aCabec   		:= {}		//Array para o cabeçalho do atendimento		
Local aItem    		:= {}		//Array auxiliar para os itens da O.S
Local aItens   		:= {}		//Array para o item da O.S
Local lRet				:= .F.		//Retorno da função
Local nX				:= 0

Default nOpcx := 3

Private lMsHelpAuto 		:= .T.		// Controle interno do ExecAuto
Private lMsErroAuto 		:= .F.		// Informa a ocorrência de erros no ExecAuto
Private lAutoErrNoFile	:= .T.		// Loga Erros do Execauto na array
Private INCLUI 		:= .T.		// Variavel necessária para o ExecAuto identificar que se trata de uma inclusão
Private ALTERA 		:= .F.		// Variavel necessária para o ExecAuto identificar que se trata de uma inclusão

If nOpcx == 3 .Or. nOpcx == 4
	
	//Adiciona itens para o cabeçalho do Atendimento
	aAdd(aCabec,{"AB9_NUMOS"		, aAtende[1] , Nil })       	// Numero da O.S + Item
	aAdd(aCabec,{"AB9_SEQ"		, aAtende[2] , Nil })			// Sequencia de Atendimento
	aAdd(aCabec,{"AB9_CODTEC"  	, aAtende[3] , Nil })			// Codigo do Técnico
	aAdd(aCabec,{"AB9_DTCHEG"	, aAtende[4] , Nil })			// Data de Chegada
	aAdd(aCabec,{"AB9_HRCHEG" 	, aAtende[5] , Nil })			// Hora de Chegada
	aAdd(aCabec,{"AB9_DTSAID"	, aAtende[6] , Nil })			// Data de Saida	
	aAdd(aCabec,{"AB9_HRSAID"  	, aAtende[7] , Nil })			// Hora de Saida
	aAdd(aCabec,{"AB9_DTINI"  	, aAtende[8] , Nil })			// Data de Inicio
	aAdd(aCabec,{"AB9_HRINI"  	, aAtende[9] , Nil })			// Hora de Inicio
	aAdd(aCabec,{"AB9_DTFIM"  	, aAtende[10], Nil })			// Data de Fim
	aAdd(aCabec,{"AB9_HRFIM"  	, aAtende[11], Nil })			// Hora de Fim
	aAdd(aCabec,{"AB9_CODPRB"  	, aAtende[12], Nil })       	// Codigo da Ocorrencia
	aAdd(aCabec,{"AB9_TIPO"  	, aAtende[13], Nil })			// Tipo(1= Encerrado,2=Aberta)	
	aAdd(aCabec,{"AB9_TOTFAT"	, aAtende[14], Nil })			// Horas Faturadas
	
	For nX := 1 To Len(aItAten)
		aItem := {}
		//Itens do Atendimento da O.S
		aAdd(aItem, {"ABA_ITEM"			, aItAten[nX][1]	, Nil}) 		// Item 
		aAdd(aItem, {"ABA_CODPRO"		, aItAten[nX][2]	, Nil}) 		// Cod. do Produto				
		aAdd(aItem, {"ABA_QUANT"			, aItAten[nX][3]	, Nil}) 		// Quantidade usada
		aAdd(aItem, {"ABA_CODSER"		, aItAten[nX][4]	, Nil}) 		// Cod. do servico
		aAdd(aItens,aItem)		
	Next nX
	
	//Executa ExecAuto
	TECA460(aCabec,aItens,nOpcx)
	
	If !lMsErroAuto
		lRet := .T.	    
	EndIf
	
	aCabec := {}
	aItem  := {}
	aItens := {}

EndIf

Return ( lRet )

// 
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900SeqT()

Retorna a proxima sequencia a gerar para um tecnico no atendimento de uma O.S. 

@param ExpC:Codigo do Tecnico
@param ExpC:AB7_NUMOS

@return cSeq Sequencia em caractere
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900SeqT(cCodTec,cChave)
Local aArea	:= GetArea()
Local cSeq		:= "00"

DbSelectArea("AB9") //Filial+NUMOS+Tecnico
AB9->(DbSetOrder(1))
If AB9->(DbSeek(XFilial("AB9")+cChave+cCodTec))	
	While !AB9->(EOF()) .AND. AB9->AB9_FILIAL+AB9->AB9_NUMOS+AB9->AB9_CODTEC == XFilial("AB9")+cChave+cCodTec 
		cSeq := AB9->AB9_SEQ
		DbSkip()
	End	
EndIf

RestArea(aArea)

Return Soma1(cSeq) 


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900Qry()

Gera Tabela Temporaria utilizada para processamento

@param ExpC:Condicao para montar a query

@return cAlias Alias da tabela gerada

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900Qry(cCondicao)
Local cAliasUI	:= "TMPATDPRO"
Local cAtraso		:= "%''"								// 02 - Atraso (Tabela I5 - SX5)
Local cSaidaAnt	:= "%''"								// 03 - Saida Antecipada (Tabela I5 - SX5)
Local cHoraExtra	:= "%''"								// 04 - Hora Extra (Tabela I5 - SX5)
Local cSinalCon	:= If(Trim(Upper(TcGetDb())) $ "ORACLE,POSTGRES,DB2,INFORMIX","||","+") //Sinal de concatenação (Igual ao ADMXFUN)
Local cExpCon		:= "%ABQ.ABQ_CONTRT"+cSinalCon+"ABQ.ABQ_ITEM"
Local cIdcfal		:= Space(TamSX3("ABB_IDCFAL")[1])	// ID Configuracao Alocacao
Local cExpCmp		:= ""
Local lFilTFF		:= FindFunction("ExistFilTFF") .And. ExistFilTFF()
Local cFilABQ		:= ""

If Select(cAliasUI) > 0
	(cAliasUI)->(DbCloseArea())
EndIf

cExpCon += cSinalCon+"ABQ.ABQ_ORIGEM%"	

//Codigos Atraso/Saida Antecipada/Hr. Extra
DbSelectArea("ABN")
DbSetOrder(1)
DbGoTop()
While !ABN->(EOF())
	If ABN->ABN_TIPO == I5_ATRASO
		cAtraso	+=	",'"	+	ABN->ABN_CODIGO + "'"
	ElseIf ABN->ABN_TIPO == I5_SAIANT
		cSaidaAnt	+=	",'"	+	ABN->ABN_CODIGO + "'"
	ElseIf ABN->ABN_TIPO == I5_HREXTR
		cHoraExtra	+=	",'"	+	ABN->ABN_CODIGO + "'"	
	EndIf
	ABN->(DbSkip())
End

cAtraso	+= "%"
cSaidaAnt	+= "%"
cHoraExtra	+= "%"

IF !lFilTFF 
	cExpCmp := "%ABQ.ABQ_ORIGEM, ABQ.ABQ_CODTFF,%"
ELSE
	cExpCmp := "%ABQ.ABQ_ORIGEM, ABQ.ABQ_CODTFF, ABQ.ABQ_FILTFF,%"
ENDIF

//Verifica alocações ativas e não atendidas
BeginSQL alias cAliasUI
	column ABB_DTINI as Date
	column ABB_DTFIM as Date
	column ATR_DTINI as Date
	column ATR_DTFIM as Date
	column SAI_DTINI as Date
	column SAI_DTFIM as Date
	column HRE_DTINI as Date
	column HRE_DTFIM as Date	
	
SELECT
	ABB.ABB_FILIAL,
	ABB.ABB_CODTEC,
	ABB.ABB_NUMOS,
	ABB.ABB_ENTIDA,
	ABB.ABB_CHAVE,
	ABB.ABB_DTINI,
	ABB.ABB_HRINI,
	ABB.ABB_DTFIM,
	ABB.ABB_HRFIM,
	ABB.ABB_ATENDE,
	ABB.ABB_MANUT,	
	ABB.ABB_IDCFAL,
	ABB.ABB_CODIGO,
	ABQ.ABQ_PRODUT,	
	ABQ.ABQ_TPPROD,	
	ABQ.ABQ_CONTRT,
	%exp:cExpCmp%
	ATRASO.ABR_DTINI ATR_DTINI, 
	ATRASO.ABR_HRINI ATR_HRINI,
	ATRASO.ABR_DTFIM ATR_DTFIM, 
	ATRASO.ABR_HRFIM ATR_HRFIM,
	SAIANT.ABR_DTINI SAI_DTINI, 
	SAIANT.ABR_HRINI SAI_HRINI,
	SAIANT.ABR_DTFIM SAI_DTFIM, 
	SAIANT.ABR_HRFIM SAI_HRFIM,			
	HREXTR.ABR_DTINI HRE_DTINI, 
	HREXTR.ABR_HRINI HRE_HRINI,
	HREXTR.ABR_DTFIM HRE_DTFIM, 
	HREXTR.ABR_HRFIM HRE_HRFIM,
	HREXTR.ABR_MOTIVO,
	HREXTR.ABR_USASER,
	HREXTR.ABR_TEMPO,		
	ABB.R_E_C_N_O_ ABBRECNO	
	
FROM 
	%table:ABB% ABB
LEFT JOIN 
	%table:AB6% AB6 ON (AB6.AB6_FILIAL=%xfilial:AB6% AND AB6.AB6_NUMOS=ABB.ABB_NUMOS AND AB6.%notDel%)
INNER JOIN 
	%table:TDV% TDV ON (TDV.TDV_FILIAL=%xfilial:TDV% AND TDV.TDV_CODABB = ABB.ABB_CODIGO AND TDV.%notDel%)
JOIN
	%table:ABQ% ABQ ON (ABQ.ABQ_FILIAL=%xfilial:ABQ% AND %exp:cExpCon%=ABB.ABB_IDCFAL AND ABQ.ABQ_FILTFF = %xfilial:TFF% AND ABQ.%notDel%) 
LEFT JOIN	
	%table:ABR% ATRASO ON (ATRASO.ABR_FILIAL=%xfilial:ABR% AND ATRASO.ABR_AGENDA=ABB.ABB_CODIGO AND ATRASO.ABR_MOTIVO IN (%exp:cAtraso%) AND ATRASO.%notDel%)
LEFT JOIN	
	%table:ABR% SAIANT ON (SAIANT.ABR_FILIAL=%xfilial:ABR% AND SAIANT.ABR_AGENDA=ABB.ABB_CODIGO AND SAIANT.ABR_MOTIVO IN (%exp:cSaidaAnt%) AND SAIANT.%notDel%)
LEFT JOIN	
	%table:ABR% HREXTR ON (HREXTR.ABR_FILIAL=%xfilial:ABR% AND HREXTR.ABR_AGENDA=ABB.ABB_CODIGO AND HREXTR.ABR_MOTIVO IN (%exp:cHoraExtra%) AND HREXTR.%notDel%)
WHERE
		ABB.ABB_FILIAL = %xfilial:ABB%
	AND
		ABB.ABB_IDCFAL != %exp:cIdcfal%
	AND
		%exp:cCondicao%
		
		ABB.%notDel%
		
ORDER BY ABB_CODTEC,ABB_DTINI
EndSql

Return cAliasUI

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900AtABB()

Atualiza o agendamento da ABB para atendido apos a geração do atendimento da O.S

@param ExpN: Valor do Recno para atualização da ABB
@param ExpC: Código do AB9_NUMOS par atualização da AB9
@param ExpC: Código do AB9_SEQ para atualização da AB9
@param ExpC: Código do AB9_CODTEC para atualização da AB9
@param ExpC: Código da agenda da ABB para atualização da AB(

@return lRet Retorna .T. a atualização aconteceu com sucesso
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900AtABB(nRecno,cChave,cSeq,cCodTec,cCodABB,cNumOS)
Local lRet 		:= .F.		//Retorno da Função
Local lContinua	:= .F.		//Retorno da Atualização da AB9

Default cChave	:= ""
Default cSeq		:= ""
Default cCodTec	:= ""	
Default cCodABB	:= ""
Default cCodABB	:= ""
Default cNumOS	:= ""

DbSelectArea("ABB")
DbSetOrder(7) //ABB_FILIAL+ABB_CODTEC+ABB_ENTIDA+ABB_CHAVE

DbSelectArea("AB9")
DbSetOrder(1) //AB9_FILIAL+AB9_NUMOS+AB9_CODTEC+AB9_SEQ

//Atualiza o campo AB9_ATAUT, para indicar que o atendimento foi gerado automaticamente
If AB9->(DbSeek(xFilial("AB9")+cChave+cCodTec+cSeq))
	RecLock("AB9", .F.)
	
	REPLACE AB9_ATAUT WITH cCodABB
	
	AB9->( MsUnLock() )
	lContinua := .T.
EndIf

//Atualiza os campos na ABB para indicar que foi gerado o atendimento
If lContinua
	ABB->( MsGoto( nRecno ) )	
	RecLock("ABB", .F.)
	
	If !Empty(cNumOs)
		REPLACE ABB_NUMOS WITH	cNumOs
		REPLACE ABB_CHAVE WITH	cChave
	EndIf
	
	REPLACE ABB_CHEGOU WITH	"S"	//Compareceu "S" - Sim ; "N" - Não
	REPLACE ABB_ATENDE WITH	"1"	//Atendeu 	"1" - Sim ; "2" - Não		
	
	ABB->( MsUnLock() )	  		
	lRet := .T.
EndIf 
		
Return( lRet )

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900Crit()

Adiciona dados do registro em processamento quando houver crítica.

@param ExpA:Array com as criticas de todo o processamento.
@param Expc:Alias da tabela do processamento.
@param cMsg:Mensagem de critica do registro corrente.

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900Crit(aCritica,cAliasUI,cMsg)
	Local cText	
	Local cDirDest := MV_PAR20 //Dir. onde o arquivo log será copiado.
	Local cPath := ""
	
	AAdd(aCritica,{;
		(cAliasUI)->ABBRECNO,;
		(cAliasUI)->ABB_CODTEC,;
		(cAliasUI)->ABB_NUMOS,;
		(cAliasUI)->ABQ_CONTRT,;
		(cAliasUI)->ABB_DTINI,;
		(cAliasUI)->ABB_HRINI,;
		(cAliasUI)->ABB_DTFIM,;
		(cAliasUI)->ABB_HRFIM,;
		cMsg})
		
		
		cText := STR0023+cValToChar((cAliasUI)->ABBRECNO)+CRLF;
		+" "+RetTitle("ABB_CODTEC")+":"+(cAliasUI)->ABB_CODTEC+CRLF;
		+" "+RetTitle("ABB_NUMOS")+":"+(cAliasUI)->ABB_NUMOS+CRLF;
		+" "+RetTitle("ABQ_CONTRT")+":"+(cAliasUI)->ABQ_CONTRT+CRLF;
		+" "+RetTitle("ABB_DTINI")+":"+DtoC((cAliasUI)->ABB_DTINI)+CRLF;
		+" "+RetTitle("ABB_HRINI")+":"+(cAliasUI)->ABB_HRINI+CRLF;
		+" "+RetTitle("ABB_DTFIM")+":"+DToC((cAliasUI)->ABB_DTFIM)+CRLF;
		+" "+RetTitle("ABB_HRFIM")+":"+(cAliasUI)->ABB_HRFIM+CRLF;
		+" "+CRLF+cMsg+CRLF	
	
		//Cria arquivo de Log
		TxLogFile("GerAtend",cText)
		
		cPath := TxLogPath("GerAtend") //Resgata o nome do arquivo log gerado
		CpyS2T(cPath, cDirDest, .F. ) //Faz uma cópia do log para a maquina do usuario
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900BaseCM()

Retorna a lista de bases de atendimento associadas a um contrato de manutencao.

@author 	Serviços
@since		10/10/2013
@version	P11 R9

@param 		ExpC1:Alias utilizado para a busca
@param 		ExpC2:Codigo do contrato de manutencao.
@param 		ExpC3:Origem do contrato.

@return	aBase - Lista de bases de atendimento associadas ao contrato.

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900BaseCM(cAliasUI,cContrato,cOrigem)

Local aArea		:= GetArea()
Local aAreaAA3	:= AA3->(GetArea())
Local aAreaUI 	:= (cAliasUI)->(GetArea())
Local aBase		:= {}
Local cFilAA3		:= xFilial("AA3")

dbSelectArea("AA3")
AA3->(dbSetOrder(2)) //AA3_FILIAL+AA3_CONTRT+AA3_CODCLI+AA3_LOJA+AA3_CODPRO+AA3_NUMSER
AA3->(dbSeek(cFilAA3+cContrato))

While AA3->(!Eof()) .AND. AA3->AA3_FILIAL == cFilAA3 .AND. AA3->AA3_CONTRT == cContrato
	
	If AA3->AA3_ORIGEM <> cOrigem 
		AA3->(dbSkip())
		Loop
	EndIf	

	AAdd(aBase,AA3->(AA3_FILIAL+AA3_CODFAB+AA3_LOJAFA+AA3_CODPRO+AA3_NUMSER))	
	
	AA3->(dbSkip())
	
End

RestArea(aAreaAA3)
RestArea(aAreaUI)
RestArea(aArea)

Return(aBase)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900GetPro()

Retorna a proposta do contrato com a nova estrutura e integração com o GCT.

@author 	Serviços
@since		10/10/2013
@version	P11 R9

@param 		ExpC1:Codigo do contrato da integração GCT.
@param 		ExpC1:Codigo da revisão do contrato.
@param 		ExpC1:Codigo dos recursos do contrato.

@return	cProposta - Proposta relacionada ao contrato

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900GetPro(cCodContrt, cCodTFF)

Local cProposta := ""
Local cAliasTFF := GetNextAlias()

BeginSql Alias cAliasTFF
	
	SELECT 
		TFJ.TFJ_PROPOS, TFJ.TFJ_PREVIS	 
	FROM 	
		%Table:TFF% TFF
		JOIN 	%Table:TFL% TFL
	  	  ON 	TFL.TFL_FILIAL = %xFilial:TFL%
	 	 AND 	TFL.TFL_CODIGO = TFF.TFF_CODPAI
	 	 AND 	TFL.TFL_CONTRT = %Exp:cCodContrt%	 	 	 	 
	 	 AND 	TFL.%NotDel%
		JOIN 	%Table:TFJ% TFJ 
	  	  ON 	TFJ.TFJ_FILIAL = %xFilial:TFJ%
	 	 AND 	TFJ.TFJ_CODIGO = TFL.TFL_CODPAI  
	 	 AND 	TFJ.%NotDel%	 
	WHERE	
		TFF.TFF_FILIAL = %xFilial:TFF%	AND
		TFF.TFF_COD = %Exp:cCodTFF%		AND 
		TFF.%NotDel%
		
EndSql

cProposta := (cAliasTFF)->TFJ_PROPOS

Return(cProposta)


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At900GerOs()

Gravação de OS. para serviço extra.

@author 	Rodolfo Novaes
@since		21/03/2017
@version	P12

/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At900GerOs(	cCodOrc	, aChaveAA3	, cCondPV	, cOcorren	,;
						cContMnt	, cNumOS	, dDataInc, cTpCont ) 

Local lRet		:= .T.

Local aCab		:= {}
Local aItens	:= {}
Local aItem		:= {}

Local dDataBkp	:= dDataBase

Local nX		:= 0

Private lMsErroAuto	:= .F.

Default dDataInc := dDataBase
Default cTpCont  := "1"

AB6->(DbSetOrder(1))

TFJ->(DbSetOrder(1)) //TFJ_FILIAL + TFJ_CODIGO
TFJ->(DbSeek(xFilial("TFJ") + cCodOrc))

cNumOS := GetSXENum("AB6","AB6_NUMOS")
While AB6->(DbSeek(xFilial("AB6")+cNumOS))
	ConfirmSX8()
	cNumOS := GetSXENum("AB6","AB6_NUMOS")
End	
RollBackSx8() 

dDataBase := dDataInc

aAdd(aCab,{"AB6_NUMOS"	,cNumOS				,Nil})
aAdd(aCab,{"AB6_CODCLI"	,TFJ->TFJ_CODENT	,Nil})
aAdd(aCab,{"AB6_LOJA"	,TFJ->TFJ_LOJA		,Nil})
aAdd(aCab,{"AB6_EMISSA"	,dDataInc			,Nil})
aAdd(aCab,{"AB6_CONPAG"	,cCondPV			,Nil})
aAdd(aCab,{"AB6_HORA"	,Time()				,Nil}) 

//Chave da base utilizada(Indice 4): AA3_FILIAL+AA3_CODFAB+AA3_LOJAFA+AA3_CODPRO+AA3_NUMSER
AA3->(DbSetOrder(4))

For nX := 1 to Len(aChaveAA3)
	AA3->(DbSeek(aChaveAA3[nX]))
	aItem:= {}
	aAdd(aItem,{"AB7_ITEM"		,StrZero(nX,2)  	,Nil})
	aAdd(aItem,{"AB7_TIPO"		,"1"				,Nil})
	aAdd(aItem,{"AB7_CODPRO"	,AA3->AA3_CODPRO	,Nil})
	aAdd(aItem,{"AB7_NUMSER"	,AA3->AA3_NUMSER	,Nil})
	aAdd(aItem,{"AB7_CODPRB"	,cOcorren			,Nil})
	aAdd(aItens,aClone(aItem)) 	
Next nX

TECA450(,aCab,aItens,,3)

dDataBase := dDataBkp

If lMsErroAuto
	lRet := .F.
	ConOut("Erro na inclusao da Ordem de Serviço!") //
	MostraErro()
EndIf

Return lRet

/*/{Protheus.doc} At900DelAt
Realiza a exclusão das O.S. conforme pergunte
@author 	Rodolfo Novaes
@since 		27/11/2017
@version 	1.0
/*/
Static Function At900DelAt(cAliasUI,oDlg,oMeter,oSayMsg)
Local dDataIni
Local cHoraIni
Local dDataFim
Local cHoraFim
Local aAreaABB
Local cChave		:= ""	
Local cSequencia	:= ""
Local aCritica		:= {}
Local nReg			:= 0
Local nTamChave 	:= TamSX3("AB7_NUMOS")[1]+TamSX3("AB7_ITEM")[1]
Local nRecAB9		:= 0
Local aChaveAA3		:= {}
Local nI			:= 0
Local lContinua		:= .T.
Local cCritica		:= ""
Local aRet900Del	:= {}
Local cDiretorio	:= MV_PAR20 //Diretorio onde será copiado o log
Local nRecABB		:= 0

(cAliasUI)->(dbGoTop())

While (cAliasUI)->(!Eof())	

	oMeter:Set(++nReg) // Atualiza Gauge/Tmeter
	oSayMsg:SetText("<center>"+STR0007+cValToChar(nReg)+"</center>")//"Processando..."
	
	//Inicializa Variaveis e Datas
	dDataIni	:= (cAliasUI)->ABB_DTINI
	cHoraIni	:= (cAliasUI)->ABB_HRINI
	dDataFim	:= (cAliasUI)->ABB_DTFIM
	cHoraFim	:= (cAliasUI)->ABB_HRFIM
	cChave		:= ""	
	cChave := (cAliasUI)->ABB_CHAVE
	nRecABB		:= (cAliasUI)->ABBRECNO
		
	aArea := GetArea()
	
	If ExistBlock("AT900DEL")
		aRet900Del := ExecBlock("AT900DEL",.F.,.F.,{cAliasUI,@cCritica})
		lContinua	:= aRet900Del[1]
		cCritica	:= aRet900Del[2]
		If !lContinua .And. !Empty(cCritica)
			At900Crit(@aCritica,cAliasUI,cCritica)
		EndIf
	EndIf	
		
	DbSelectArea("AB9")
	AB9->(DbSetOrder(1))
		
	If AB9->(DbSeek(xFilial('AB9') + Substr(cChave,1,nTamChave))) .And. lContinua
		
		nRecAB9 := At900RetSq((cAliasUI)->ABB_CODTEC,Substr(cChave,1,nTamChave),dDataIni,cHoraIni)	
		
		If nRecAB9 == 0
			At900Crit(@aCritica,cAliasUI,STR0026) //'Não foi encontrado registro de O.S. apontada!'
		EndIf
				
		AB9->(DbGoTo(nRecAB9))
		If AB9->AB9_MPONTO
			At900Crit(@aCritica,cAliasUI,'Não é possível excluir/estornar a geração de atendimento, verificar se houve a exclusão/estorno das marcações na rotina de "Geração de Marcações".') //'Não é possível excluir/estornar a geração de atendimento, verificar se houve a exclusão/estorno das marcações na rotina de "Geração de Marcações".'
			lContinua := .F.
		EndIf
		
		If lContinua							
			Begin Transaction					 	
				Reclock('AB9',.F.)
				DbDelete()
				MsUnLock()
				
				aChaveAA3 := At900BaseCM(cAliasUI, (cAliasUI)->ABQ_CONTRT,(cAliasUI)->ABQ_ORIGEM)	
				
				For nI:=1 To Len(aChaveAA3)
					AB7->(dbSetOrder(5))			
					If AB7->(dbSeek(xFilial("AB7")+Substr(aChaveAA3[nI],9)))			
						While	AB7->AB7_FILIAL+AB7->AB7_CODFAB+AB7->AB7_LOJAFA+;
								AB7->AB7_CODPRO+AB7->AB7_NUMSER == xFilial("AB7")+Substr(aChaveAA3[nI],9)												
							Reclock('AB7',.F.)	
							DbDelete()
							MsUnLock()									
							AB7->(dbSkip())					
						EndDo
					EndIf		
				Next nI							
				
				ABB->(DbSetOrder(1))
				ABB->(DbGoTo(nRecABB))
				If ABB->ABB_CHEGOU == "S" .And. ABB->ABB_ATENDE == "1"
					Reclock('ABB',.F.)
					REPLACE ABB_CHEGOU WITH 'N'
					REPLACE ABB_ATENDE WITH '2'
					REPLACE ABB_CHAVE  WITH ''
					REPLACE ABB_NUMOS  WITH ''
					MsUnlock()
				Else
					At900Crit(@aCritica,cAliasUI,STR0027) //'Não foi encontrado registro de agenda de atendente!'
				EndIf			
			
			End Transaction		
		EndIf						
	EndIf	
	(cAliasUI)->(DbSkip())				
EndDo			
					 
If nReg == 0
	Aviso(STR0001,STR0028,{STR0002},2) //"Atenção"##"Não há registros para excluir atendimento conforme parametros informados."##{"OK"}
ElseIf Len(aCritica) == 0
 	Aviso(STR0001,STR0029 + cValToChar(nReg) + STR0015,{STR0002},2) //"Atenção"##"Foram excluidos:"##" atendimentos de ordens de serviço de alocação."##{"OK"}		
Else		
	Aviso(STR0001,STR0014+cValToChar((nReg-Len(aCritica)))+STR0015; //"Atenção"##"Foram gerados:"##" atendimentos de ordens de serviço de alocação."##
	+STR0016+CRLF+STR0017+Alltrim(cDiretorio)+"\GerAtend-" + AllTrim(DToS(Date())) + ".LOG",{STR0002},2) //" Ocorreram erros na geração do atendimento da O.S."##"Foi gerado o log no arquivo "##"OK"	
EndIf

oDlg:End()

Return( Len(aCritica) == 0 )



/*/{Protheus.doc} At900RetSq
Retorna a sequencia da AB9 a partir do codigo do tecnico + OS + data + hora
@author 	Rodolfo
@since 		27/11/2017
@version 	1.0
@param 		cCodTec, character, (Descrição do parâmetro)
@param 		cChave, character, (Descrição do parâmetro)
@param 		dData, data, (Descrição do parâmetro)
@param 		cHora, character, (Descrição do parâmetro)
/*/
Static Function At900RetSq(cCodTec,cChave,dData,cHora)
Local aArea	:= GetArea()
Local cSeq		:= "00"
Local nRet		:= 0
DbSelectArea("AB9") //Filial+NUMOS+Tecnico
AB9->(DbSetOrder(1))
If AB9->(DbSeek(XFilial("AB9")+cChave+cCodTec))	
	While !AB9->(EOF()) .AND. AB9->AB9_FILIAL+AB9->AB9_NUMOS+AB9->AB9_CODTEC == XFilial("AB9")+cChave+cCodTec 
		If DTOS(AB9->AB9_DTCHEG) + AB9->AB9_HRCHEG == DTOS(dData) + cHora
			nRet	:= Recno()
			Exit
		Else
			DbSkip()
		EndIf
	End	
EndIf

RestArea(aArea)

Return nRet 