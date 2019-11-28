#Include 'PROTHEUS.CH'
#Include 'TECM330.CH'
#Include "FWMVCDEF.CH"
#Include "TBICONN.CH"

Static	nFileLog	:= 0
Static	aLog		:= {}

#DEFINE RESTRICAO_AGENDA_RH 		'1'	// Não geração de agendas por restrição no RH (casos de férias, afastamentos e demissão)
#DEFINE RESTRICAO_AGENDA_SUSPENSAO	'2'	// Não geração de agendas por suspensão
#DEFINE RESTRICAO_AGENDA_GS 		'3'	// Não geração de agendas por curso, reciclagem ou folga no dia
#DEFINE RESTRICAO_AGENDA_FALTA		'4'	// Geração de agenda e manutenção automática por falta em função do atendente ainda estar "em falta" (não ter acontecido a movimentação com a situação "Retorno de Falta")
#DEFINE RESTRICAO_AGENDA_RESERVA	'5'	// Inclusão de atendente no posto de reserva padrão.


//------------------------------------------------------------------------------
/*/{Protheus.doc} TECM330()
Rotina responsável por gerar a agenda do dia dos atendentes. O fonte irá 
gerar as informações para todos os atendentes ativos de todas as filiais.

@sample     TECM330(aParam)

@param 		aParam, Array, Lista de parâmetros cadastradas no schedule 
                           (não há a necessidade de informá-los no cadastro da schedule, será criado automaticamente)
							aParam[1] - Empresa associada ao agendamento da rotina
							aParam[2] - Filial associada ao agendamento da rotina
							aParam[3] - Usuário associado ao agendamento da rotina
							aParam[4] - Id do agendamento  

@return 	Nil 

@author		Ana Maria Utsumi       
@since      22/08/2016  
@version    P12
/*/
//------------------------------------------------------------------------------
Function TECM330(aParam)
Local   aArea		:= GetArea()
Local 	cFilAtu		:= ""
Local 	cEmpresa	:= "0"
Local 	aMsgProc	:= {}
Local 	aButtons	:= {}
Local   nContinua	:= 0
Local	lExecJob	:= RemoteType() //Iif(GetRemoteType() == -1, .T., .F.)
Local	cPath     	:= ""
Local	cFileLog  	:= "" 
Local 	n			:= 0
Local	aSelFil		:= {}
Local  	cSeq		:= '01'
Local 	lMvVlDt		:= .T. 
Default aParam 		:= {}

//Se executado pelo menu, solicitar confirmação de processamento
If !lExecJob
	AAdd(aMsgProc, OemToAnsi(STR0034))	//"O objetivo desta rotina é gerar a agenda do dia dos atendentes."
	AAdd(aMsgProc, OemToAnsi(STR0035))	//"Além disso, será gerado um arquivo TXT com os possíveis problemas e incidências "
	AAdd(aMsgProc, OemToAnsi(STR0036))	//"encontradas, como atendentes sem alocação, em falta, em férias ou afastamentos."
	
	AAdd(aButtons,{1, .T., {|o| nContinua:=1,o:oWnd:End()}})
	AAdd(aButtons,{2, .T., {|o| o:oWnd:End()}})	
	
	FormBatch( OemToAnsi(STR0001), aMsgProc, aButtons )	//"Geração Diária de Agenda"
	lMvVlDt := Iif(SuperGetMV("MV_MVVLDT",,.F.), Date() == dDataBase ,.T.)
Else
	ConOut(STR0006 +" "+ Time())						//"Início"
	nContinua := 1
EndIf

If nContinua==1
	
	If lExecJob
		PREPARE ENVIRONMENT EMPRESA aParam[1] FILIAL aParam[2] MODULO "TEC" 
		//__cUserID := aParam[3]
	EndIf
	
	DbSelectArea("SM0")
	SM0->(DbSetOrder(1))	
	SM0->(DbGoTop())
		
	//Se execução não é via Job, posicionar na empresa logada
	If !lExecJob
		SM0->(DbSeek(cEmpAnt))
	EndIf
	
	//Cria pastas de log se necessário
	cPath := "\GestaoDeServicos\AlocacaoDiaria\"
	If !ExistDir(Substr(cPath, 1, Len(cPath)-15))
		If MakeDir(Substr(cPath, 1, Len(cPath)-15),,.F.)<>0	//Cria pasta GestaoDeServicos
			ConOut(STR0019)									//"Erro ao gerar arquivo de log".	
			Return
		Else
			If !ExistDir(cPath)
				If MakeDir(cPath,,.F.)<>0					//Cria pasta AlocacaoDiaria
					ConOut(STR0019)							//"Erro ao gerar arquivo de log".	
					Return
				EndIf	
			EndIf
		EndIf	
	EndIf

	If lExecJob
		Do While !SM0->(Eof())
			Aadd(aSelFil,SM0->M0_CODFIL)
			SM0->(DbSkip())
		EndDo
	Else
		aSelFil := AdmGetFil(.F.,.T.,"ABB")
	EndIf	
	
	If Len(aSelFil) > 0
		If lMvVlDt
			For n := 1 to Len(aSelFil)
			
				SM0->(DbSeek(cEmpAnt + aSelFil[n]))
							
				//Verifica se é necessário criar o arquivo de log. É criado um por empresa.
				If cEmpresa <> SM0->M0_CODIGO
					FClose(nFileLog)
					cEmpresa :=	SM0->M0_CODIGO			
						
					cFileIni := cPath+(Iif(lExecJob, AllTrim(DToS(Date())) + "-" + cEmpresa + "-", AllTrim(DToS(dDataBase)) + "-" + cEmpresa ))				
					cFileLog := cFileIni + '-seq-' + cSeq + '.LOG'
					//Realiza tratamento para sequencia de arquivos
					While File(cFileLog)
						cSeq := Soma1(cSeq)
						cFileLog := cFileIni + '-seq-' + cSeq + '.LOG'
					EndDo
					
					nFileLog := FCreate(cFileLog)
						
					If nFileLog == -1
						If !lExecJob
							Help( ,, 'TECM330',, STR0019, 1, 0 )	//"Erro ao gerar arquivo de log".
						Else
							ConOut(STR0019)			//"Erro ao gerar arquivo de log".
						EndIf	
						Return
					EndIf
				EndIf
					
				FWrite(nFileLog, STR0008 + SM0->M0_CODIGO + "/" + SM0->M0_CODFIL + CRLF)				//"Empresa/Filial: "
				FWrite(nFileLog, Time() + " " + Replicate("=",40) + " " +STR0006+ " " + Replicate("=",40) + CRLF)	//"======= Início ======="	
				
					
				If At330VdPr(Alltrim(SM0->M0_CODFIL))		//Faz a verificação das premissas para executar a rotina 
		
					If lExecJob	
//						RpcSetType( 3 )
//						PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL SM0->M0_CODFIL MODULO "TEC"
						TECM330Atd(.T., AllTrim(aParam[2]))
					Else	//Execução por Menu
						aArea	:= GetArea()
						cFilAtu	:= cFilAnt
						cFilAnt := SM0->M0_CODFIL
						Processa( {|| TECM330Atd(.F., AllTrim(SM0->M0_CODFIL))})
						
						cFilAnt := cFilAtu
						RestArea(aArea)
					EndIf
					
					//Cria registro de log dos atendentes
					At330Log()
				EndIf
					
				FWrite(nFileLog, Time() + " " + Replicate("=",40) + " " +STR0007+ " " + Replicate("=",40) + CRLF + CRLF)	//"======= Término ======="	
		
			Next
			FClose(nFileLog)
			
			SendMailJob(cFileLog)
		
			//Se executado pelo menu, informar final de processamento
			If !lExecJob	
				MsgInfo(STR0002, STR0001)		// "Fim do processamento", "Geração Diária de Agenda"
			Else
				RESET ENVIRONMENT
				aParam:=aSize(aParam,0)
				aParam:=nil
				ConOut(STR0007 +" "+ time())	//"Término"
			EndIf
		Else
			MsgInfo(STR0042, STR0041)	// "Processo Cancelado", "Não é possível executar o job com a data base diferente da data do sistema operacional."
		Endif
	Else
		MsgInfo(STR0041, STR0001)		// "Processo Cancelado", "Geração Diária de Agenda"
	EndIf
EndIf	
Return (.T.)


//------------------------------------------------------------------------------
/*/{Protheus.doc} TECM330Atd()
Gera as informações para todos os atendentes ativos da filial indicada.

@sample     TECM330Atd(.T., cFil) 
@param 		lJob, 	Boolean, 	.T. indica que rotina executada via job
@param 		cFil, 	String, 	Filial 

@return 	Nil 

@author		Ana Maria Utsumi       
@since      22/08/2016  
@version    P12
/*/
//------------------------------------------------------------------------------
Function TECM330Atd(lJob, cFil)
Local dData    	:= If(lJob,date(),dDataBase)//Data Atual
Local cOrcRes	:= SuperGetMV("MV_GSORCRE")
Local cMotFalta := SuperGetMV("MV_ATMTFAL",,,)
Local cMotCanc	:= SuperGetMV("MV_ATMTCAN",,,) 
Local cMotFerias:= SuperGetMV("MV_ATMTFER",,,) 
Local cMotCurso := SuperGetMV("MV_ATMTCUR",,,) 
Local cMotRecicl:= SuperGetMV("MV_ATMTREC",,,)
Local nFaltFix	:= SuperGetMv("MV_FALTFIX",.F.,15)
Local cMotAusen	:= "" 
Local cEscala	:= ""
Local cCodTec	:= ""
Local cMatric	:= ""
Local cTmpAA1	:= ""
Local cAliasQry := ""
Local dDtIniAfa := ""
Local dDtFimAfa := ""
Local cMotAfa	:= ""
Local aErro 	:= {}
Local aManut	:= {}
Local aAusencia := {}
Local aAgenda	:= {}
Local nCont		:= 0
Local lRet		:= .T.
Local lDemitido	:= .F.
Local lAfastado	:= .F.
Local lFerias	:= .F.
Local lSuspenso	:= .F.
Local aAreaTFF	:= TFF->(GetArea())
Local aAreaABB 	:= ABB->(GetArea())
Local aArea		:= GetArea()
Local aAtdReserv:= {}
Local lLibSit	:= .F.
Local aChkFe	:= {.F.,.F.,.F.,.F.}
Local cTurno	:= ""
Local cSeq		:= ""
Local aFerias	:= {}
Local aCobFer	:= {}
Local cWhere	:= ""
Local aFaltFix  := {}
Local lFaltFix  := .F.

If lJob
	ConOut(STR0005 + ": " + cFil)							//"Verificando atendentes ativos da Filial"
EndIf

DbSelectArea("TW1")
TW1->(DbSetOrder(1)) //TW1_FILIAL+TW1_CODTW0+TW1_COD 
	
//Consulta de atendentes ativos
cTmpAA1:=GetNextAlias()
BeginSql Alias cTmpAA1
	SELECT AA1.AA1_CODTEC, AA1.AA1_NOMTEC, AA1.AA1_TURNO, AA1.AA1_CDFUNC, AA1.AA1_ESCALA, AA1.AA1_TURNO, AA1.AA1_SEQTUR, AA1_FALTFX
	FROM %table:AA1% AA1
	LEFT JOIN %table:SRA% SRA
	  ON SRA.RA_FILIAL=%Exp:cFil%
	 AND SRA.RA_MAT=AA1.AA1_CDFUNC
	 AND SRA.%NotDel%
	WHERE AA1.AA1_FILIAL =%Exp:cFil%
	  AND AA1.%NotDel%
	  AND (AA1.AA1_ALOCA='1' OR AA1_FALTFX ='1')
	ORDER BY %Order:AA1%
EndSql
DbSelectArea(cTmpAA1)

ProcRegua(RecCount())

Begin Transaction 	
	
	Do While !(cTmpAA1)->(Eof())
		cCodTec := (cTmpAA1)->AA1_CODTEC
		cMatric	:= (cTmpAA1)->AA1_CDFUNC
		cTurno	:= (cTmpAA1)->AA1_TURNO
		cSeq 	:= (cTmpAA1)->AA1_SEQTUR
		cEscala := (cTmpAA1)->AA1_ESCALA
		lFaltFix:= (cTmpAA1)->AA1_FALTFX == "1"

		lLibSit	  := IIF(ExistBlock("M330LST") , ExecBlock("M330LST",.F.,.F.,{cCodTec,dData}), .F. )
		
		IncProc(STR0005 + " " + cFil + " - " + STR0037 + " " + cCodTec)	//"Verificando atendentes ativos da Filial"###"Atendente"
		
		//Se atendente não alocado, alocá-lo no posto de reserva
		If (!(At330VdAl(cFil, cCodTec, dData )) .And. !lFaltFix) .And. (!Empty(cEscala) .And. !Empty(cTurno) .And. !Empty(cSeq))
			
			aAdd(aAtdReserv,{cCodTec,cEscala,cTurno,cSeq})
			
		EndIf
			
		//Verifica se atendente demitido
		lDemitido := At570ChkDm(cFil, cMatric, dData, dData)
			
		//Verifica se atendente afastado
		lAfastado	:= At570ChkAf(cFil, cMatric, dData, dData)
			
		//Verifica se atendente esta de ferias
		aChkFe 		:= At570ChkFe(cFil, cMatric, dData, dData)
		
		lFerias		:= aChkFe[1] .Or. aChkFe[2] .Or. aChkFe[3] .Or. aChkFe[4]
			
		//Atendente com ferias efetivas e pertence a rota de cobertura com ferista envolvido, não gera agenda por tanto não precisa de manuntenção.
		If aChkFe[4]
			aCobFer := At581Feris(cCodTec,dData,dData)
			If Empty(aCobFer)
				aAdd(aFerias,cCodTec)
			Endif
		Endif

		//Verifica se atendente suspenso 
		lSuspenso	:= At335ChkSu(cFil, cCodTec, dData, dData)
			
		//Verifica se atendente ausente e retorna o motivo (por curso, reciclagem, folga ou falta, com a data inicial e final do evento) 
		aAusencia	:= At335ChkAu(cFil, cCodTec, dData)
					
		//Registrar atendente em array para geração de arquivo de log
		If lDemitido .Or. ((lAfastado	.Or. lFerias .Or. lSuspenso .Or. Len(aAusencia)>0) .And. !lLibSit)
			//Query que retorna o período de afastamento/licença do atendente
			cAliasQry 	:= GetNextAlias()
			BeginSql Alias cAliasQry
				SELECT  AA1.AA1_FILIAL,
	           		    AA1.AA1_CODTEC,
						COALESCE(SRA.RA_DEMISSA,' ') RA_DEMISSA,
						COALESCE(SRF.RF_DATAINI,' ') RF_DATAINI,
						COALESCE(SRF.RF_DFEPRO1, 0 ) RF_DFEPRO1,
						COALESCE(SRF.RF_DATINI2,' ') RF_DATINI2,
						COALESCE(SRF.RF_DFEPRO2, 0 ) RF_DFEPRO2,
						COALESCE(SRF.RF_DATINI3,' ') RF_DATINI3,
						COALESCE(SRF.RF_DFEPRO3, 0 ) RF_DFEPRO3,
						COALESCE(SRH.RH_DATABAS,' ') RH_DATABAS,
						COALESCE(SRH.RH_DBASEAT,' ') RH_DBASEAT,
						COALESCE(SR8.R8_TIPO   ,' ') R8_TIPO   ,
						COALESCE(SR8.R8_DATAINI,' ') R8_DATAINI,
						COALESCE(SR8.R8_DATAFIM,' ') R8_DATAFIM,
						COALESCE(RCM.RCM_DESCRI,' ') RCM_DESCRI,
						COALESCE(TIT.TIT_CODTIQ,' ') TIT_CODTIQ,
						COALESCE(TIQ.TIQ_DESCR ,' ') TIQ_DESCRI,
						COALESCE(TIT.TIT_DATA  ,' ') TIT_DATA  ,
						COALESCE(TIT.TIT_QTDDIA,' ') TIT_QTDDIA 			
				FROM %table:AA1% AA1
				LEFT JOIN %table:SRA% SRA
				  ON SRA.RA_FILIAL = %xFilial:SRA%
				 AND SRA.RA_MAT = AA1.AA1_CDFUNC
				 AND SRA.%NotDel%
				LEFT JOIN %table:SR8% SR8
				  ON SR8.R8_FILIAL = %xFilial:SR8%
				 AND SR8.R8_MAT = SRA.RA_MAT
				 AND SR8.%NotDel%
				 AND ((NOT (%exp:dData% > SR8.R8_DATAFIM OR %exp:dData% < SR8.R8_DATAINI)) OR
       			           (%exp:dData%>=SR8.R8_DATAINI AND SR8.R8_DATAFIM = '')
	                 )	 
				LEFT JOIN %table:TIT% TIT
	 			  ON TIT.TIT_FILIAL = %xFilial:TIT%
	 			 AND TIT.TIT_CODTEC = AA1.AA1_CODTEC
	 			 AND TIT.%NotDel%
	 			 AND ((%Exp:dData% BETWEEN TIT.TIT_DATA AND DATEADD(DAY,TIT.TIT_QTDDIA-1,TIT.TIT_DATA))
					 OR
	    			  (%Exp:dData% BETWEEN TIT.TIT_DATA AND DATEADD(DAY,TIT.TIT_QTDDIA-1,TIT.TIT_DATA))
				     OR
	    			  (TIT.TIT_DATA ='')
					 )
	 			 AND TIT.TIT_AFASTA = '1'
				LEFT JOIN %table:RCM% RCM
	  			  ON RCM.RCM_FILIAL = %xFilial:RCM%
	 			 AND RCM.RCM_TIPO  = SR8.R8_TIPOAFA
	 			 AND RCM.%NotDel%
				LEFT JOIN %table:TIQ% TIQ
	  			  ON TIQ.TIQ_FILIAL = %xFilial:TIQ%
	 			 AND TIQ.TIQ_CODIGO = TIT.TIT_CODTIQ
	 			 AND TIQ.%NotDel%
				LEFT JOIN %table:SRF% SRF
	  			  ON SRF.RF_FILIAL =  %xFilial:SRF%
	 			 AND SRF.RF_MAT = SRA.RA_MAT	
	 			 AND SRF.%NotDel%
	 			 AND (( %Exp:dData% BETWEEN SRF.RF_DATAINI AND DATEADD(DAY,SRF.RF_DFEPRO1-1,SRF.RF_DATAINI) ) 
			         OR 
			 		  ( %Exp:dData% BETWEEN SRF.RF_DATINI2 AND DATEADD(DAY,SRF.RF_DFEPRO2-1,SRF.RF_DATINI2) )
			         OR 
				      ( %Exp:dData% BETWEEN SRF.RF_DATINI3 AND DATEADD(DAY,SRF.RF_DFEPRO3-1,SRF.RF_DATINI3) )
				     )
				LEFT JOIN %table:SRH% SRH
				  ON SRH.RH_FILIAL = %xFilial:SRH%
				 AND SRH.RH_MAT = SRA.RA_MAT
				 AND NOT (SRH.RH_DBASEAT < %Exp:dData% OR SRH.RH_DATABAS > %Exp:dData%)
				 AND SRH.%NotDel%
				 
			   WHERE AA1.AA1_FILIAL = %xFilial:TFF%
				 AND AA1.AA1_CODTEC = %Exp:cCodTec%
	  			 AND AA1.%NotDel%
				 AND (SR8.R8_DATAINI <> '        '
				   OR SRF.RF_DATAINI <> '        '
				   OR SRF.RF_DATINI2 <> '        '
				   OR SRF.RF_DATINI3 <> '        '
				   OR SRH.RH_DATABAS <> '        '
				   OR TIT.TIT_DATA   <> '        '
				   OR SRA.RA_DEMISSA <> '        '
					 )
	 			ORDER BY AA1_FILIAL, AA1_CODTEC
			EndSql
			DbSelectArea(cAliasQry)
			
			//Registra array de log e de faltas
			Do Case
				Case lFerias
					If DToS(dData)>=(cAliasQry)->RF_DATAINI .Or. DToS(dData)<=(cAliasQry)->RF_DATAINI
						dDtIniAfa 	:= (cAliasQry)->RF_DATAINI
						dDtFimAfa	:= DToS((SToD((cAliasQry)->RF_DATAINI) + ((cAliasQry)->RF_DFEPRO1-1)))
					ElseIf DToS(dData)>=(cAliasQry)->RF_DATINI2 .Or. DToS(dData)<=(cAliasQry)->RF_DATINI2 
						dDtIniAfa 	:= (cAliasQry)->RF_DATINI2
						dDtFimAfa	:= DToS((SToD((cAliasQry)->RF_DATINI2) + ((cAliasQry)->RF_DFEPRO2-1)))
					ElseIf DToS(dData)>=(cAliasQry)->RF_DATINI3 .Or. DToS(dData)<=(cAliasQry)->RF_DATINI3	
						dDtIniAfa 	:= (cAliasQry)->RF_DATINI3
						dDtFimAfa	:= DToS((SToD((cAliasQry)->RF_DATINI3) + ((cAliasQry)->RF_DFEPRO3-1)))
					EndIf
					cMotAfa	:= STR0017
					AAdd(aLog,{RESTRICAO_AGENDA_RH, cCodTec, (cTmpAA1)->AA1_NOMTEC, cMotAfa + " ", DToC(SToD(dDtIniAfa)) + " - " + DToC(SToD(dDtFimAfa)), "" , SToD(dDtIniAfa)})
		
				Case lAfastado
				  	dDtIniAfa 	:= (cAliasQry)->R8_DATAINI
					dDtFimAfa	:= (cAliasQry)->R8_DATAFIM
					cMotAfa		:= AllTrim((cAliasQry)->R8_TIPO)+ " - " +AllTrim((cAliasQry)->RCM_DESCRI)
					AAdd(aLog,{RESTRICAO_AGENDA_RH, cCodTec, (cTmpAA1)->AA1_NOMTEC, cMotAfa + " ", DToC(SToD(dDtIniAfa)) + " - " + DToC(SToD(dDtFimAfa)), "",SToD(dDtIniAfa)})
	
					//Para atendente afastado, gravar em array para posterior alteração em agenda
					AAdd(aManut, {"A", cCodTec})

				Case lDemitido
					AAdd(aLog,{RESTRICAO_AGENDA_RH, cCodTec, (cTmpAA1)->AA1_NOMTEC, STR0040 + ": ", DToC(SToD((cAliasQry)->RA_DEMISSA)), "",SToD((cAliasQry)->RA_DEMISSA)})
				Case lSuspenso
					dDtIniAfa 	:= (cAliasQry)->TIT_DATA
					dDtFimAfa	:= DToS((SToD((cAliasQry)->TIT_DATA) + ((cAliasQry)->TIT_QTDDIA-1)))	
					cMotAfa		:= AllTrim((cAliasQry)->TIT_CODTIQ)+ " - " + AllTrim((cAliasQry)->TIQ_DESCRI)
					AAdd(aLog,{RESTRICAO_AGENDA_SUSPENSAO, cCodTec, (cTmpAA1)->AA1_NOMTEC, cMotAfa +" ", DToC(SToD(dDtIniAfa)) + " - " + DToC(SToD(dDtFimAfa)), "",SToD(dDtIniAfa)})
					//Para atendente suspenso, gravar em array para posterior alteração em agenda
					AAdd(aManut, {"S", cCodTec})
					
				Case (Len(aAusencia)>0 .And. aAusencia[1][1]<>"0")

					AAdd(aLog,{RESTRICAO_AGENDA_GS, cCodTec, (cTmpAA1)->AA1_NOMTEC, aAusencia[1][1]+" - "+ aAusencia[1][2] +" ", DToC(SToD(aAusencia[1][3])) + " - " + DToC(SToD(aAusencia[1][4])), "",SToD(aAusencia[1][3])})
					
					//Gravar em array para posterior alteração em agenda					
					If !lFaltFix .And. aAusencia[1][1]=="1" .And. (Empty(aAusencia[1][4]) .And. ((dData-sTod(aAusencia[1][3])) >= nFaltFix)) .Or. (!Empty(aAusencia[1][4]) .And. ((dData-sTod(aAusencia[1][4])) >= nFaltFix))
						AAdd(aFaltFix,{cCodTec,aAusencia[1][5]})
					//Se o atendente faltou
					Elseif aAusencia[1][1]=="1"
						AAdd(aManut, {aAusencia[1][1], cCodTec})					
					//Se o atendente esta em reciclagem
					Elseif aAusencia[1][1]=="2"
						AAdd(aManut, {aAusencia[1][1], cCodTec})
					//Se o atendente esta em curso
					Elseif aAusencia[1][1]=="3"
						AAdd(aManut, {aAusencia[1][1], cCodTec})

					EndIf
			EndCase	
			(cAliasQry)->(DbCloseArea()) 
		EndIf
		(cTmpAA1)->(DbSkip())
	EndDo
	(cTmpAA1)->(DbCloseArea())

	//Desalocar os atendentes do posto de reserva ou efetivo e colocar em falta fixa.
	If Len(aFaltFix) > 0
		At330FtFix( cFil, dData, aFaltFix)
	Endif

	//Aloca atendentes sem posto no posto de reserva técnica
	If Len(aAtdReserv) > 0
		AlocaAtd(cFil, dData, aAtdReserv)
	EndIf
	
	IncProc(STR0038 + " " + cFil)	//"Criação de agendas da filial"

	//Efetuar o registro de agenda dos atendentes
	lRet := At330AloAut( "", "z", "", "z", "", "z", dData, dData, "", "", "z", "z", "", "z",.F., "1", "0",,,,.F.,lLibSit )
    
	If !lRet
		DisarmTransaction()
		Break
	EndIf	
	
	IncProc(STR0039 + " " + cFil)	//"Verificação de manutenção de agendas da filial"
		
	//Efetuar alteração em registro de atendentes em falta, curso, reciclagem, suspensão ou afastamento.
	For nCont := 1 to Len(aManut)
		If aManut[nCont,1] =="1"
			cMotAusen := cMotFalta
			cWhere 	  := "%%"
		Elseif aManut[nCont,1] =="2"
			cMotAusen := cMotRecicl
			cWhere    := "%AND ABB.ABB_TIPOMV <> '010'%"
		Elseif aManut[nCont,1] =="3"
			cMotAusen := cMotCurso
			cWhere    := "%AND ABB.ABB_TIPOMV <> '006'%"
		Else
			cMotAusen := cMotCanc
			cWhere 	  := "%%"
		EndIf
		
		//Informar dados da agenda
		cAliasQry := GetNextAlias()
		BeginSql Alias cAliasQry
			SELECT  ABB.*
			FROM %table:ABB% ABB
			JOIN %table:TDV% TDV
		  	  ON TDV.TDV_FILIAL = %xFilial:TDV% AND TDV.TDV_CODABB=ABB.ABB_CODIGO AND TDV.TDV_DTREF=%Exp:dData% AND TDV.%NotDel%
			WHERE ABB.ABB_FILIAL = %xFilial:ABB%   AND 
			  ABB.ABB_CODTEC=%Exp:aManut[nCont,2]% AND
		 	  ABB.%NotDel%						   
			  %Exp:cWhere%
		 	  
		EndSql
		
		aAgenda := {}
		Do While !(cAliasQry)->(Eof()) .And. lRet
			aAdd(aAgenda,{(cAliasQry)->ABB_CODIGO,;
						  (cAliasQry)->ABB_DTINI,;
				  		  (cAliasQry)->ABB_HRINI,;
					      (cAliasQry)->ABB_DTFIM,;
					      (cAliasQry)->ABB_HRFIM} )
		
			(cAliasQry)->(DbSkip()) 
		EndDo

		// Chamada da função responsável pela gravação da tabela ABR através da utilização do modelo de dados do TECA550
		lRet := At336GrABR(aAgenda,cMotAusen,dData,,,,,,cAliasQry)
	
		(cAliasQry)->(DbCloseArea()) 

		If !lRet
			DisarmTransaction()
			Break
		EndIf	
	Next nCont

	cMotAusen := cMotFerias
		
	//Efetuar alteração em registro de atendentes em Ferias
	For nCont := 1 to Len(aFerias)

		//Informar dados da agenda
		cAliasQry := GetNextAlias()

		BeginSql Alias cAliasQry
			SELECT  ABB.*
			FROM %table:ABB% ABB
			JOIN %table:TDV% TDV
		  	  ON TDV.TDV_FILIAL = %xFilial:TDV% AND TDV.TDV_CODABB=ABB.ABB_CODIGO AND TDV.TDV_DTREF=%Exp:dData% AND TDV.%NotDel%
			WHERE ABB.ABB_FILIAL = %xFilial:ABB%
			  AND ABB.ABB_CODTEC=%Exp:aFerias[nCont]%
		 	  AND ABB.%NotDel%
		EndSql
		
		aAgenda := {}
		Do While !(cAliasQry)->(Eof()) .And. lRet
			aAdd(aAgenda,{(cAliasQry)->ABB_CODIGO,;
						  (cAliasQry)->ABB_DTINI,;
				  		  (cAliasQry)->ABB_HRINI,;
					      (cAliasQry)->ABB_DTFIM,;
					      (cAliasQry)->ABB_HRFIM} )
		
			(cAliasQry)->(DbSkip()) 
		EndDo

		// Chamada da função responsável pela gravação da tabela ABR através da utilização do modelo de dados do TECA550
		lRet := At336GrABR(aAgenda,cMotAusen,dData,,,,,,cAliasQry)
	
		(cAliasQry)->(DbCloseArea()) 

		If !lRet
			DisarmTransaction()
			Break
		EndIf	
	Next nCont

End Transaction
		
RestArea(aAreaTFF)
RestArea(aAreaABB)
RestArea(aArea)
	
Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330VdPr(cFil)
Verifica se as premissas para executar a rotina estão configuradas corretamente

@sample	At330VdPr(cFil)
@param	cFil, 	String, 	Filial

@return lRet, 	Retorna, 	.T. se todas as premissas são atendidas 

@author 	Ana Maria Utsumi
@since		30/08/2016
@version 	P12
     
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At330VdPr(cFil)
Local dData    	:= If(Iif(GetRemoteType() == -1, .T., .F.),date(),dDataBase)//Data Atual
Local cOrcRes	:= SuperGetMV("MV_GSORCRE",,,cFil)
Local cMotFalta := SuperGetMV("MV_ATMTFAL",,,)
Local lRh 		:= FindFunction("U_PNMSESC") .And. FindFunction("U_PNMSCAL") 
Local lRet 		:= .F.
Local aArea 	:= GetArea()
Local cFilTFJ	:= xFilial("TFJ",cFil)
Local cFilTFL	:= xFilial("TFL",cFil)
Local cFilTFF	:= xFilial("TFF",cFil)

DbSelectArea("TFJ")
TFJ->(DbSetOrder(1)) //TFJ_FILIAL + TFJ_CODIGO
If TFJ->(DbSeek(cFilTFJ+cOrcRes))

	DbSelectArea("TFL")
	TFL->(DbSetOrder(2)) //TFL_FILIAL + TFL_CODPAI
	If TFL->(DbSeek(cFilTFL+TFJ->TFJ_CODIGO))	

		DbSelectArea("TFF")
		TFF->(DbSetOrder(3)) //TFF_FILIAL + TFF_CODPAI
		
		While TFL->(!Eof()) .And. cFilTFL == TFL->TFL_FILIAL .And. TFJ->TFJ_CODIGO == TFL->TFL_CODPAI

			If TFF->(DbSeek(cFilTFF+TFL->TFL_CODIGO))
			
				While TFF->(!Eof()) .And. cFilTFF == TFF->TFF_FILIAL .And. TFL->TFL_CODIGO == TFF->TFF_CODPAI

					If AllTrim(TFF->TFF_CODSUB)<>"" .Or. TFF->TFF_PERFIM<dData
						FWrite(nFileLog, STR0065+TFF->TFF_COD+STR0066 + CRLF)	//"Posto padrão inativo."
					ElseIf !lRh
						FWrite(nFileLog, STR0033 + CRLF)	//"Para que seja possivel executar essa rotina, aplique o patch para as configurações do RH!"
					Else
						lRet	:= .T.
					EndIf	

					TFF->(DbSkip())
				EndDo
			Else
				FWrite(nFileLog, STR0062 + CRLF) //"Rh do local de atendimento do orçamento de reserva não configurado."
			Endif
			TFL->(DbSkip())
		EndDo
	Else
		FWrite(nFileLog, STR0063 + CRLF) //"Local de atendimento do orçamento de reserva não configurado."
	Endif
Else
	FWrite(nFileLog, STR0064 + CRLF) //"Orçamento de reserva não configurado. Efetue a alteração do parâmetro MV_GSORCRE." 
Endif

RestArea(aArea)

Return lRet


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330VdAl()
Verifica se atendente está alocado

@param 		cFil, 		String,		Filial
@param 		cCodTec,	String,		Código do Atendente 
@param 		dData,		Date,		Data de referência

@return		lRet, 		Boolean,	Retorna .T. se o atendente estiver alocado 

@author 	Ana Maria Utsumi
@since		30/08/2016
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At330VdAl(cFil, cCodTec, dData)
Local cTmpEfe	:= ""
Local cTmpRes  	:= ""
Local cTmpAlm	:= ""
Local cTmpCob	:= ""
Local lEfeVazio := .F.
Local lResVazio := .F.
Local lAlmVazio := .F.
Local lCobVazio := .F.
Local lFerVazio	:= .F.
Local lFolVazio	:= .F.
Local lRet 		:= .T.
Local aArea 	:= GetArea()
Local aCobFer	:= {}
Local cTpRt		:= ""
	
//Verificar se atendente efetivo em posto
cTmpEfe:=GetNextAlias()
BeginSql Alias cTmpEfe
	SELECT TGY.TGY_ATEND
	FROM %table:TGY% TGY
	INNER JOIN %table:TFF% TFF
	   ON TFF.TFF_FILIAL= %xFilial:TFF%
	  AND TFF.TFF_COD=TGY.TGY_CODTFF
	  AND TFF.%NotDel%
	INNER JOIN %table:ABS% ABS
	   ON ABS.ABS_FILIAL= %xFilial:ABS%
	  AND ABS.ABS_LOCAL=TFF.TFF_LOCAL
	  AND ABS.%NotDel%
	WHERE TGY.TGY_FILIAL =%Exp:cFil%
	  AND TGY.%NotDel%
  	  AND TGY.TGY_ATEND=%Exp:cCodTec%
	  AND ((%Exp:dData% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM) OR TGY.TGY_DTFIM='')
	  AND ABS.ABS_RESTEC<>1
EndSql
	
If (cTmpEfe)->(Eof())
	lEfeVazio := .T.
EndIf
(cTmpEfe)->(DbCloseArea())
	
//Verificar se atendente em posto de reserva
cTmpRes:=GetNextAlias()
BeginSql Alias cTmpRes
	SELECT TGY.TGY_ATEND
	FROM %table:TGY% TGY
	INNER JOIN %table:TFF% TFF
	   ON TFF.TFF_FILIAL=%xFilial:TFF%
	  AND TFF.TFF_COD=TGY.TGY_CODTFF
	  AND TFF.%NotDel%
	INNER JOIN %table:ABS% ABS
	   ON ABS.ABS_FILIAL=%xFilial:ABS%
	  AND ABS.ABS_LOCAL=TFF.TFF_LOCAL
	  AND ABS.%NotDel%
	WHERE TGY.TGY_FILIAL =%Exp:cFil%
	  AND TGY.%NotDel%
	  AND TGY.TGY_ATEND=%Exp:cCodTec%
	  AND ((%Exp:dData% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM) OR TGY.TGY_DTFIM='')
	  AND ABS.ABS_RESTEC=1
EndSql
		
If (cTmpRes)->(Eof())
	lResVazio := .T.
EndIf
(cTmpRes)->(DbCloseArea())
		
//Verificar se atendente em rota de cobertura (almocista/jantista)
cTmpAlm := GetNextAlias()
BeginSql Alias cTmpAlm
	SELECT TW0.TW0_ATEND,
		   TW0.TW0_COD,
		   TW0.R_E_C_N_O_ TW0RECNO,
		   TW0.TW0_COBRT,
		   TGX.TGX_TIPO
	FROM %table:TW0% TW0
	INNER JOIN %table:TGZ% TGZ
	   ON  TGZ.TGZ_FILIAL =%xFilial:TGZ%
	  AND TGZ.TGZ_CODTW0=TW0.TW0_COD
	INNER JOIN %table:TGX% TGX
	   ON TGX.TGX_FILIAL = %xFilial:TGX%
	  AND TGX.TGX_COD    = TGZ.TGZ_CODTDX	  
	WHERE TW0.TW0_FILIAL =%xFilial:TW0%
	  AND TW0.%NotDel%
	  AND TGZ.%NotDel%
	  AND TGX.%NotDel%
	  AND TW0.TW0_ATEND=%Exp:cCodTec%
	  AND (TGX.TGX_TIPO	=	'2' OR TGX.TGX_TIPO	=	'3')
	  AND %Exp:dData% BETWEEN TGZ.TGZ_DTINI AND TGZ.TGZ_DTFIM
EndSql
		
If (cTmpAlm)->(Eof())
	lAlmVazio := .T.
Else
	If (cTmpAlm)->TW0_COBRT == "1"
		lAlmVazio := At581Efet("RE", (cTmpAlm)->TW0_COD, dData, (cTmpAlm)->TW0_ATEND, .T. )
	Endif
EndIf
(cTmpAlm)->(DbCloseArea())
		
//Verificar se atendente em cobertura (não pertence a rota de cobertura)
cTmpCob:=GetNextAlias()
BeginSql Alias cTmpCob
	SELECT TGZ.TGZ_ATEND
	FROM %table:TGZ% TGZ
	WHERE TGZ.TGZ_FILIAL =%xFilial:TGZ%
	  AND TGZ.%NotDel%
	  AND TGZ.TGZ_ATEND=%Exp:cCodTec%
	  AND %Exp:dData% BETWEEN TGZ.TGZ_DTINI AND TGZ.TGZ_DTFIM
	  AND TGZ.TGZ_CODTW0=""
EndSql
	
If (cTmpCob)->(Eof())
	lCobVazio := .T.
EndIf	
(cTmpCob)->(DbCloseArea())
	
//Verificar se atendente em rota de cobertura (Ferista/Folguista)
cTpRt := At581TpRot(cCodTec)

If cTpRt <> "4"
	lFerVazio := .T.
Else  //Se estiver verifica se existe algum atendente que saira de ferias.
	aCobFer := At581Feris(cCodTec,dData,dData,.T.)
	If Empty(aCobFer)
		lFerVazio := .T.
	Else
		//Se estiver no posto de reserva faz o seu recolhimento.
		If !lResVazio
			At336ChkAlc( cFil, cCodTec, dData, .T. )
		Endif
	Endif
Endif

If cTpRt <> "1"
	lFolVazio := .T.
Else  //Se estiver verifica se existe algum atendente da rota saira de folga conforme a escala.
	If !At581Folg(cCodTec,dData)
		lFolVazio := .T.
	Else
		//Se estiver no posto de reserva faz o seu recolhimento.
		If !lResVazio
			At336ChkAlc( cFil, cCodTec, dData, .T. )
		Endif
	Endif
Endif

//Se atendente não encontrado nas consultas, indica que ele não está alocado
If lEfeVazio .And. lResVazio .And. lAlmVazio .And. lCobVazio .And. lFerVazio .And. lFolVazio
	lRet :=.F.
EndIf	

RestArea(aArea)
	
Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330Log()
Criar log de atendentes

@param		Nenhum
     
@return 	Nil 

@author 	Ana Maria Utsumi
@since		30/08/2016
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At330Log()
Local 	nCont		:= 1
Local 	cSubTitulo	:= ""
Local 	nDif		:= 0
	
If !Empty(aLog)
	ASort(aLog,,, {|x,y| x[1]+x[4]+x[2] < y[1]+y[4]+y[2] }) 	//	Subtítulo + Motivo + Cód Atendente				
Endif

For nCont := 1 to Len(aLog)
	If cSubTitulo<>aLog[nCont,1]
		cSubTitulo:=aLog[nCont,1]
		Do Case
			Case cSubTitulo==RESTRICAO_AGENDA_RH
				FWrite(nFileLog, CRLF + Replicate("=",15) + " " +STR0009+ " " + Replicate("=",15) + CRLF)				//"======= Restristos no módulo Recursos Humanos ======="	
			Case cSubTitulo==RESTRICAO_AGENDA_SUSPENSAO
				FWrite(nFileLog, CRLF + Replicate("=",15) + " " +STR0010+ " " + Replicate("=",15) + CRLF)				//"======= Suspensos ======="	
			Case cSubTitulo==RESTRICAO_AGENDA_GS
				FWrite(nFileLog, CRLF + Replicate("=",15) + " " +STR0011+ " " + Replicate("=",15) + CRLF)				//"======= Restritos no módulo Gestão de Serviços ======="	
			Case cSubTitulo==RESTRICAO_AGENDA_FALTA
				FWrite(nFileLog, CRLF + Replicate("=",15) + " " +STR0012+ " " + Replicate("=",15) + CRLF)				//"======= Em Falta ======="	
			Case cSubTitulo==RESTRICAO_AGENDA_RESERVA
				FWrite(nFileLog, CRLF + Replicate("=",15) + " " +STR0013+ " " + aLog[nCont,6]+Replicate("=",15) + CRLF) //"======= Movidos para Reserva=999999 Contrato=999999 ======="	
		EndCase
	EndIf
	
	If ValType(aLog[nCont,7]) == 'D'
		nDif := DateDiffDay( aLog[nCont,7], dDataBase )
		If nDif > 0
			nDif++
		EndIf
	Else
		nDif := 0
	EndIf		
	
	FWrite(nFileLog, STR0014+": "+aLog[nCont,2]+ " - "+aLog[nCont,3]        + ;
	          		 Iif(aLog[nCont,4]>"", STR0015+": " +aLog[nCont,4], "") + ; 
	          		 Iif(aLog[nCont,5]>"", STR0016+": " +aLog[nCont,5], "") + ;
	          		 Iif(nDif > 0 , " " + Alltrim(Str(nDif)) + STR0043, "") + CRLF)		//STR0014 "Técnico"	   STR0015 "Motivo"	   STR0016 "Período" STR0043 "Dias"

Next nCont

aLog		:= {}

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} ${function_method_class_name}
(long_description)

@sample ${function_method_class_name} (${param}, ${param_type}, ${param_descr})

@param ${param}, ${param_type}, ${param_descr}

@return ${return}, ${return_description}

@author Ana Utsumi
@since 03/08/2017
@version 12.1.17
/*/
//-------------------------------------------------------------------
Static Function AlocaAtd(cFil, dDtRef, aAtdReserv)
Local cOrcRes	:= SuperGetMV("MV_GSORCRE")
Local cTipAlo	:= "RES" //tipo de alocação da reserva
Local cEscala	:= ""
Local aAreaTFF	:= TFF->(GetArea())
Local aAreaTDX	:= TDX->(GetArea())
Local aAreaTGY	:= TGY->(GetArea())
Local aArea 	:= GetArea()
Local lRet		:= .F.
Local aErro		:= {}
Local nTotLinhas:= 0
Local cItem		:= StrZero(0,TamSX3("TGY_ITEM")[1],0)
Local nGrupo	:= 0
Local oModelTGY	:= Nil
Local oAuxTDX	:= Nil
Local oAux		:= Nil
Local nCont		:= 0
Local lCommit   := .F.
Local lMV_GSGEHOR := SuperGetMV("MV_GSGEHOR",,.F.)

DbSelectArea("TFJ")
TFJ->(DbSetOrder(1)) //TFJ_FILIAL + TFJ_CODIGO
If TFJ->(DbSeek(xFilial("TFJ") + cOrcRes))
	DbSelectArea("TFL")
	TFL->(DbSetOrder(2)) //TFL_FILIAL + TFL_CODPAI
	If TFL->(DbSeek(xFilial("TFL") + TFJ->TFJ_CODIGO))	

		DbSelectArea("TFF")
		DbSelectArea("TDX")
		DbSelectArea("TGY")

		TFF->(DbSetOrder(3)) //TFF_FILIAL + TFF_CODPAI	
		TDX->(DbSetOrder(2)) //TDX_FILIAL + TDX_CODTDW
		TGY->(DbSetOrder(1)) //TGY_FILIAL+TGY_ESCALA+TGY_CODTDX+TGY_CODTFF+TGY_ITEM                                                                                                            

		While TFL->(!Eof()) .And. xFilial("TFL") == TFL->TFL_FILIAL .And. TFJ->TFJ_CODIGO == TFL->TFL_CODPAI

			If TFF->(DbSeek(xFilial("TFF") + TFL->TFL_CODIGO))
			
				While TFF->(!Eof()) .And. xFilial("TFF") == TFF->TFF_FILIAL .And. TFL->TFL_CODIGO == TFF->TFF_CODPAI
					
					cEscala := TFF->TFF_ESCALA

					//Buscar registro de escala efetivo
					If TDX->(DbSeek(xFilial("TDX") + cEscala))
						
						If lMV_GSGEHOR
							At580bKill()
							At580EGHor((VldEscala(TFF->(RECNO()),.F.)))
						EndIf
						
						///Grava registro de atendente em posto de reserva técnica												
						oModelTGY := FWLoadModel('TECA580E')
										
						oModelTGY:SetOperation( MODEL_OPERATION_UPDATE )
						lRet 	:= oModelTGY:Activate()
						lCommit	:= .F.		
	
						If lRet
							oAuxTDX	:= oModelTGY:GetModel( 'TDXDETAIL' )
							oAux	:= oModelTGY:GetModel( 'TGYDETAIL' )

							At580VdFolder({1})	//Definir nome da pasta que indica a alocação de efetivos								

							//Se é a primeira alocação, verifica qual o próximo item
							cItem := At336TGYIt(cFil, TFF->TFF_COD)

							//Verifica os atendentes que precisam da reserva
							For nCont := 1 To Len(aAtdReserv)
								//Se for a escala que o atendente esta configurado e o codigo da configuração existir dentro do gestão de escalas realiza a inclusão do atendente.
								If cEscala == aAtdReserv[nCont,2] .And. oAuxTDX:SeekLine({{"TDX_CODTDW",aAtdReserv[nCont,2]},{"TDX_TURNO",aAtdReserv[nCont,3]},{"TDX_SEQTUR",aAtdReserv[nCont,4]}})

									If !Empty( oAux:GetValue('TGY_ATEND') )
										nTotLinhas := oAux:Length()
										If nTotLinhas >= 1
											lRet := (oAux:AddLine() == (nTotLinhas +1))
										EndIf
									EndIf
									
									cItem := Soma1(cItem)
									
									//Buscar o grupo que possui menos atendentes vinculados
									nGrupo := Val(cItem)
								
									IncProc(STR0037 + " " + aAtdReserv[nCont,1] +" Item "+ cItem)
																
									lRet := oAux:SetValue('TGY_FILIAL', cFil)
									lRet := oAux:SetValue('TGY_ATEND' , aAtdReserv[nCont,1])
									lRet := oAux:SetValue('TGY_ESCALA', cEscala)
									lRet := oAux:SetValue('TGY_DTINI' , dDtRef)
									lRet := oAux:SetValue('TGY_GRUPO' , nGrupo)
									lRet := oAux:SetValue('TGY_ITEM'  , cItem) 
									lRet := oAux:SetValue('TGY_TIPALO', cTipAlo)
									lCommit := .T.
								Endif
							Next nCont
							
							If lCommit .And. lRet
								lRet := oModelTGY:VldData()	
								lRet := oModelTGY:CommitData()
							Endif
	
							If !lRet
								aErro   := oModelTGY:GetErrorMessage()
					
								//Grava registro em log
								If Len(aErro)>0
									FWrite(nFileLog, STR0021 + " [" + AllToChar( aErro[1] ) + "]" + CRLF)	//"Id do formulário de origem:" 
									FWrite(nFileLog, STR0022 + " [" + AllToChar( aErro[2] ) + "]" + CRLF)	//"Id do campo de origem:     " 
									FWrite(nFileLog, STR0023 + " [" + AllToChar( aErro[3] ) + "]" + CRLF)	//"Id do formulário de erro:  "
									FWrite(nFileLog, STR0024 + " [" + AllToChar( aErro[4] ) + "]" + CRLF)	//"Id do campo de erro:       "
									FWrite(nFileLog, STR0025 + " [" + AllToChar( aErro[5] ) + "]" + CRLF)	//"Id do erro:                "
									FWrite(nFileLog, STR0026 + " [" + AllToChar( aErro[6] ) + "]" + CRLF)	//"Mensagem do erro:          "
									FWrite(nFileLog, STR0027 + " [" + AllToChar( aErro[7] ) + "]" + CRLF)	//"Mensagem da solução:       "
									FWrite(nFileLog, STR0028 + " [" + AllToChar( aErro[8] ) + "]" + CRLF)	//"Valor atribuido:           "
									FWrite(nFileLog, STR0029 + " [" + AllToChar( aErro[9] ) + "]" + CRLF)	//"Valor anterior:            "
					
									DisarmTransaction()
									Break
								EndIf
							EndIf
						
							oModelTGY:DeActivate()
							oModelTGY:Destroy()
						
						Endif
					Endif
					TFF->(DbSkip())
				EndDo
			Endif
			TFL->(DbSkip())
		EndDo
	Endif
Endif

RestArea(aAreaTFF)
RestArea(aAreaTDX)
RestArea(aAreaTGY)
RestArea(aArea)

Return aErro

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} RemoteType()
Função para Identificar o tipo e a versão do Smart Client em execução.
     
@return 	lRet. Caso retorne -1 a execução é feita via job 

@author 	Serviços
@since		20/12/2017
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function RemoteType()
Local lRet 			:= .F.
Local cLib			:= ""
Local nRemoteType	:= 0

nRemoteType := GetRemoteType(@cLib)

If nRemoteType == -1
	lRet := .T.
EndIf


Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} SendMailJob()
Função para envio do log do job por e-mail
     
@author 	Serviços
@since		22/02/2018
@version 	P12
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function SendMailJob(cFile,cToEmail,cMensagem,cAssunto)
Local oServer 		:= TMailManager():New()
Local nErr 			:= 0  
Local lRelauth 		:= SuperGetMv("MV_RELAUTH")			// Parametro que indica se existe autenticacao no e-mail
Local nSMTPTime 	:= SuperGetMv("MV_RELTIME",.F.,60)	// TIMEOUT PARA A CONEXAO
Local lSSL 			:= SuperGetMv("MV_RELSSL",.F.,.F.)	// VERIFICA O USO DE SSL
Local lTLS 			:= SuperGetMv("MV_RELTLS",.F.,.F.)	// VERIFICA O USO DE TLS
Local nSMTPPort 	:= SuperGetMv("MV_PORSMTP",.F.,25)	// PORTA SMTP
Local cCtaAut   	:= SuperGetMV('MV_RELAUSR') 		// usuario para Autenticacao Ex.: fuladetal
Local cConta    	:= SuperGetMV('MV_RELACNT') 		// Conta Autenticacao Ex.: fuladetal@fulano.com.br
Local cSenha      	:= SuperGetMV('MV_RELAPSW') 		// Senha de acesso Ex.: 123abc
Local cServer   	:= SuperGetMV('MV_RELSERV') 		// Ex.: smtp.gmail.com
Local cUser			:= SuperGetMV('MV_RELDEST') 		// Mensagem do e-mail 
Local cEmailBcc		:= ""								// E-mail de copia
Local aMailTo		:= {}
Local nX			:= 0
Local cTo		 	:= ""
Default cToEmail 	:= ""
Default cMensagem	:= SuperGetMV('MV_RELBODY') 		// Mensagem do e-mail
Default cAssunto	:= STR0061 + cValToChar( Date())    // Arquivo de Log do job do dia

If Empty(cToEmail)
	aMailTo := StrTokArr(cUser, ',')
	
	For nX := 1 To Len(aMailTo)
		cTo += UsrRetMail(aMailTo[nX]) + ";"
	Next nX
Else
	cTo := cToEmail
Endif

// Usa SSL, TLS ou nenhum na inicializacao
oServer:SetUseSSL(lSSL)
oServer:SetUseTLS(lTLS)

// Inicializacao do objeto de Email
nErr := oServer:init("",cServer,cConta,cSenha,,nSMTPPort)
If nErr <> 0
	CoNout(STR0044 + oServer:getErrorString(nErr)) // "[Init SMTP] Falha ao inicializar SMTP: "
	Return(.F.)
Else
	CoNout(STR0045 + oServer:getErrorString(nErr)) //"[Init SMTP] Sucesso ao inicializar SMTP "
Endif
	
// Define o Timeout SMTP
nErr := oServer:SetSMTPTimeout(nSMTPTime)
If nErr <> 0
	CoNout(STR0046 + oServer:getErrorString(nErr)) //"[SetSMTPTimeout] Falha ao definir timeout: "
	Return(.F.)
Else
	conout( STR0047 + oServer:getErrorString(nErr)) //"[SetSMTPTimeout] Sucesso ao definir Timeout SMTP: "
EndIf
	
// Conecta ao servidor
nErr := oServer:smtpConnect()
If nErr <> 0
	CoNout(STR0048 + oServer:getErrorString(nErr)) // "[Connect SMTP] Falha ao conectar: "
	oServer:SMTPDisconnect()
	Return(.F.)
Else
	CoNout(STR0049 + oServer:getErrorString(nErr)) // "[Connect SMTP] Sucesso ao conectar SMTP"
EndIf
	
// Realiza autenticacao no servidor
If lRelauth
	nErr := oServer:smtpAuth(cConta, cSenha)
	If nErr <> 0
		CoNout(STR0050 + oServer:getErrorString(nErr)) // "Falha ao autenticar:"
		oServer:SMTPDisconnect()
		Return(.F.)
	Else
		CoNout(STR0051 + oServer:getErrorString(nErr)) //"[AUTH] Sucesso ao autenticar: "
	EndIf
EndIf
	
// Cria uma nova mensagem (TMailMessage)
oMessage := TMailMessage():New()
oMessage:clear()
	
oMessage:cFrom		:= cConta
oMessage:cTo    	:= cTo
oMessage:cSubject	:= cAssunto
oMessage:cBody 		:= cMensagem
	
If !Empty(cFile)
	nErr := oMessage:AttachFile( cFile )
	If nErr < 0
		Conout(STR0052 +  oServer:getErrorString(nErr)) //"[Attach] Erro ao anexar arquivo"
		Return .F.
	Endif
EndIf
	
conout( STR0053 ) //"[SEND] Enviando ..."
nErr := oMessage:Send( oServer )
		  
If nErr != 0
	conout( STR0054 ) //"[SEND] Falha ao enviar"
	conout( STR0055 + str( nErr, 6 ), oServer:GetErrorString( nErr ) ) //"[SEND][ERROR] "
Else
	conout( STR0056 + oServer:getErrorString(nErr) ) //"[SEND] Sucesso no envio"
EndIf
	
conout( STR0057 ) //"[DISCONNECT] Desconectando SMTP "
nErr := oServer:SmtpDisconnect()
If nErr != 0
	conout( STR0058 ) //"[DISCONNECT] Falha ao Desconectar SMTP"
	conout( STR0059 + str( nErr, 6 ), oServer:GetErrorString( nErr ) ) //"[DISCONNECT][ERROR] "
Else
	conout( STR0060 + oServer:getErrorString(nErr) ) //"[DISCONNECT] Sucesso ao desconectar SMTP"
EndIf
	
Return .T.

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} At330FtFix()
Coloca o atendente que esta com mais de 15 dias de falta em falta fixa.
     
@author 	Kaique Schiller
@since		07/02/2019
/*/
//--------------------------------------------------------------------------------------------------------------------
Static Function At330FtFix(cFil, dData, aFaltFix)
Local aArea	  	:= GetArea()
Local oMdl580e	:= Nil
Local oMdlTDX	:= Nil
Local oMdlTGY	:= Nil
Local oMdlTW5 	:= Nil
Local oModelAfa := Nil 
Local oMdlSR8	:= Nil
Local nX 	  	:= 0
Local nRecTW5 	:= 0
Local lOk		:= .T.
Local cCodFunc	:= ""
Local cTipAfast := SuperGetMv("MV_TPAFAST",.F.,"014")
Local cToEmail	:= ""
Local cTitEmail := Alltrim(SM0->M0_CODFIL)+" - Ínicio de processo de desligamento por abandono de emprego."
Local cMsgEmail	:= cMsgEmail := "Os atendentes abaixo estão com mais de "+cValToChar(SuperGetMv("MV_FALTFIX",.F.,15))+" dias em falta é necessário que o RH realize o processo de desligamento por abandono de emprego."+CRLF+CRLF
Local cAliasTGY	:= ""

DbSelectArea("TW5")
DbSelectArea("SR8")
DbSelectArea("AA1")
DbSelectArea("SRA")
DbSelectArea("TFF")

oMdl580e 	:= FwLoadModel("TECA580E")
oMdlTW5 	:= FwLoadModel("TECA336A")
oModelAfa	:= FWLoadModel('GPEA240')

//variavel usada no gpea240
Private aPerAtual 	:= {} 
Private aAutoCab	:= {}
Private aAutoItens	:= {}
Private cProcesso	:= ""
Private nColPro	 	:= 2
Private aSR8Respal  := {}

For nX := 1 To Len(aFaltFix)

	lOk := .T.

	//Recolhe o atendente da reserva ou do posto de efetivo.
	cAliasTGY := GetNextAlias()
	BeginSql Alias cAliasTGY
		SELECT *, TGY.R_E_C_N_O_ AS RECNOTGY
		FROM %table:TGY% TGY
		WHERE TGY.TGY_FILIAL = %xFilial:TGY%
	      AND TGY.TGY_ATEND  = %Exp:aFaltFix[nX,1]%
	      AND TGY.%NotDel%
	      AND (%Exp:dData% BETWEEN TGY.TGY_DTINI AND TGY.TGY_DTFIM)
	EndSql
	
	(cAliasTGY)->(DbGoTop())
	
	While (cAliasTGY)->(!EOF())
	
		TFF->(DbSetOrder(1)) //TFF_FILIAL+TFF_COD
		TFF->(DbSeek(FwxFilial("TFF")+(cAliasTGY)->TGY_CODTFF))

		oMdl580e:SetOperation(MODEL_OPERATION_UPDATE)
        oMdl580e:GetModel( 'TGYDETAIL' ):SetLoadFilter( , " ( TGY_ATEND = '"+aFaltFix[nX,1]+"' )" )

		lOk := lOk .And. oMdl580e:Activate()
		
		oMdlTDX := oMdl580e:GetModel("TDXDETAIL")

		lOk := lOk .And. oMdlTDX:SeekLine({{"TDX_COD" , (cAliasTGY)->TGY_CODTDX}},.F.)

		At580VdFolder({1})

		oMdlTGY := oMdl580e:GetModel("TGYDETAIL")
			
		lOk := lOk .And. oMdlTGY:SeekLine({{"TGY_ITEM" , (cAliasTGY)->TGY_ITEM}},.F.)

		lOk := lOk .And. oMdlTGY:SetValue("TGY_DTFIM" ,	dData-1		)

		lOk := lOk .And. oMdl580e:VldData() .And. oMdl580e:CommitData()

		oMdl580e:DeActivate()

		(cAliasTGY)->(DbSkip())

	EndDo

	//Altera a ausencia de falta para dar inicio a ausencia de falta fixa.
	nRecTW5 := aFaltFix[nX,2]
	TW5->(DbGoTo(nRecTW5))

	oMdlTW5:SetOperation(MODEL_OPERATION_UPDATE)
	lOk := lOk .And. oMdlTW5:Activate()
	
	lOk := lOk .And. oMdlTW5:SetValue("TW5MASTER","TW5_DTFIM", dData-1)
	
	lOk := lOk .And. oMdlTW5:VldData() .And. oMdlTW5:CommitData()

	oMdlTW5:DeActivate()
	
	//Inclusão de ausencia de falta de fixa.
	oMdlTW5:SetOperation(MODEL_OPERATION_INSERT)
	oMdlTW5:Activate()

	lOk := lOk .And. oMdlTW5:SetValue("TW5MASTER","TW5_ATDCOD", aFaltFix[nX,1]  )
	lOk := lOk .And. oMdlTW5:SetValue("TW5MASTER","TW5_TPLANC", "7"             )
	lOk := lOk .And. oMdlTW5:SetValue("TW5MASTER","TW5_DTINI" , dData           )

	lOk := lOk .And. oMdlTW5:VldData() .And. oMdlTW5:CommitData()
		
	If lOk
		AA1->(DbSetOrder(1)) // AA1_FILIAL+AA1_CODTEC
		AA1->(DbSeek(xFilial("AA1",cFil)+aFaltFix[nX,1]))
		
		cNomeFun := Alltrim(AA1->AA1_NOMTEC)
		cCodFunc := AA1->AA1_CDFUNC

		//Altera campo de falta fixa e alocação.			
		Reclock("AA1",.F.)
			AA1->AA1_FALTFX := "1"
			AA1->AA1_ALOCA	:= "2"
		AA1->(MsUnlock())
	Endif
	
	oMdlTW5:DeActivate()

	SRA->(DbSetOrder(1))
	SRA->(dbSeek(xFilial("SRA",cFil)+cCodFunc))

	//Inclusão de ausencia no RH.
	oModelAfa:SetOperation(MODEL_OPERATION_UPDATE)
	lOk := lOk .And. oModelAfa:Activate()
		
	oMdlSR8 := oModelAfa:GetModel("GPEA240_SR8")
		
	If oMdlSR8:Length() > 1 .Or. (oMdlSR8:Length() ==  1 .And. !Empty(oMdlSR8:GetValue("R8_TIPOAFA")) ) 
		lOk := lOk .And. oMdlSR8:AddLine()
	EndIf
		
	lOk := lOk .And. oMdlSR8:SetValue('R8_TIPOAFA',	cTipAfast)
	lOk := lOk .And. oMdlSR8:SetValue('R8_DATAINI',	dData)
	lOk := lOk .And. oMdlSR8:SetValue('R8_DURACAO',	999)
	
	lOk := lOk .And. oModelAfa:VldData() .And. oModelAfa:CommitData()

	oModelAfa:DeActivate()

	If lOk	
		cMsgEmail += Alltrim(aFaltFix[nX,1])+"/"+cNomeFun+CRLF+CRLF
		cToEmail  := SuperGetMv("MV_EMAILRH",.F.)
	Endif

Next nX

If !Empty(cToEmail)
	SendMailJob("",cToEmail,cMsgEmail,cTitEmail)
Endif

oMdl580e:Destroy()
oMdl580e:= Nil

oMdlTW5:Destroy()
oMdlTW5:= Nil

oModelAfa:Destroy()
oModelAfa:= Nil

Return .T.