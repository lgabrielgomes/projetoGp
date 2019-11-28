#INCLUDE 'PROTHEUS.CH'
#Include 'FWMVCDEF.CH'
#Include 'TECA960.CH' 

Static nEnv := 0
Static nNEnv	:= 0

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA960
	Programação de Rateio

@sample 	TECA960() 

@since		24/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function TECA960()

Local cPerg 	:= "TECA960"
Local cCliDe	:= ""
Local cCliAt	:= ""
Local cCompt	:= ""
Local lOk		:= .F.
Local lCont	:= .F.
Local dDtIni	
Local dDtFim
Local nSobrR	:= 0
Local nProc	:= 0
Local nGerLg	:= 0
Local oProcess := Nil	
Local cDir	 := ""

While Pergunte(cPerg,.T.)

	cCliDe := MV_PAR01
	cCliAt	:= MV_PAR02
	dDtIni	:= MV_PAR03
	dDtFim	:= MV_PAR04
	cCompt	:= MV_PAR05
	nSobrR	:= MV_PAR06
	nProc	:= MV_PAR07
	nGerLg	:= MV_PAR08
	cDir	:= MV_PAR09 //Diretorio onde será copiado o log
	
	If At960VlPrg(dDtIni,dDtFim,cCompt)	//Valida os campos do pergunte
		lCont := .T.
		cCompt	:= At960Cfol(MV_PAR05)
		Exit
	EndIf
	
End	

If nProc == 2 //Estorno
	If MsgNoYes(STR0001+;								//"A realização do estorno excluirá as programações de rateio existentes no módulo de Gestão de Pessoal"
				 STR0002+CHR(13)+CHR(10)+STR0003)		//" para os atendentes na competência informada."+##+##+"Deseja continuar com a operação?"
		lCont := .T.
	Else
		lCont := .F.	
	EndIf
EndIf

If lCont		
	BEGIN TRANSACTION
		oProcess := MSNewProcess():New( { | lEnd | lOk := A960ProgRt( @lEnd,cCliDe,cCliAt,dDtIni,dDtFim,cCompt,nSobrR,nProc,nGerLg,oProcess) }, STR0036, IIf(nProc==1,STR0037,STR0038), .F. )	//"Aguarde, gerando programação de rateio...",("Enviando","Excluindo") 
		oProcess:Activate()
	END TRANSACTION()
EndIf

If lOk
	If nProc == 1  //Processamento Envio
		At960GrLg(,,,,,,,.T.)
		If nEnv == 0 .And. nNEnv == 0
			Aviso(STR0004,STR0005,{STR0006},2)		//"Atenção","Não há registros para envio da programação de rateio.",{"OK"}
		Else		
			Aviso(STR0007,STR0008+cValToChar(nEnv)+CRLF;		//"Envio da Programação de Rateio","Programações enviadas: " 
					+STR0009+cValToChar(nNEnv)+CRLF;									//"Programações não enviadas: "
					+STR0010+Alltrim(cDir)+"\ProgRateio-" + AllTrim(DToS(Date())) + ".LOG",{STR0006},2)						//"Foi gerado o log no arquivo "{"OK"}
		EndIf
	Else	////Processamento Estorno
		If nNEnv > 0
			Aviso(STR0004,STR0011+CRLF;										//"Atenção","Programações excluídas com sucesso"
					+STR0010+TxLogPath("ProgRateio"),{STR0006},2)						//"Foi gerado o log no arquivo "{"OK"}
			nNEnv := 0
		EndIf	
	EndIf
EndIf

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A960ProgRt
	Consulta as alocações

@sample 	A960ProgRt() 

@since		24/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function A960ProgRt(lEnd,cCliDe,cCliAt,dDtIni,dDtFim,cCompt,nSobrR,nProc,nGerLg,oProcess)

Local cFilAA1	:= xFilial("AA1")
Local cFilSRA	:= xFilial("SRA")
Local cFilABS	:= xFilial("ABS")
Local cFilAB9	:= xFilial("AB9")
Local cFilABA	:= xFilial("ABA")
Local cAtend	:= ""
Local aAtend	:= {}
Local aTot		:= {}
Local cAtendOld := ""
Local nQtdProc	:= 0
Local nQtdAtend	:= 0
Local nTot			:=0

Local cFunc	:= ""
Local nTotLc	:= 0
Local cLoc		:= ""
Local cCC		:= ""

Local cAliasA		:= GetNextAlias()

Default oProcess := Nil

BeginSQL alias cAliasA

SELECT
	ABB.ABB_CODTEC,
	ABS.ABS_CCUSTO,
	AA1.AA1_CDFUNC,
	AA1.AA1_FUNFIL,
	ABB.ABB_LOCAL,
	SUM(ABA_QUANT) AS TOTAL	
		
From %table:ABB% ABB

INNER JOIN
%table:AA1% AA1 ON (AA1.AA1_FILIAL = %exp:cFilAA1% AND AA1.AA1_CODTEC = ABB.ABB_CODTEC AND AA1.%notDel%)

INNER JOIN
%table:SRA% SRA ON (SRA.RA_FILIAL = AA1.AA1_FUNFIL AND SRA.RA_MAT = AA1.AA1_CDFUNC AND SRA.%notDel%)

INNER JOIN
%table:ABS% ABS ON (ABS.ABS_FILIAL = %exp:cFilABS% AND ABS.ABS_LOCAL = ABB.ABB_LOCAL AND ABS.%notDel%)

INNER JOIN
%table:AB9% AB9 ON (AB9.AB9_FILIAL = %exp:cFilAB9% AND AB9.AB9_NUMOS = ABB.ABB_CHAVE AND AB9.AB9_CODTEC = ABB.ABB_CODTEC AND;
 AB9.AB9_ATAUT = ABB.ABB_CODIGO AND AB9.%notDel%)

INNER JOIN
%table:ABA% ABA ON (ABA.ABA_FILIAL = %exp:cFilABA% AND ABA.ABA_NUMOS = AB9.AB9_NUMOS AND ABA.ABA_CODTEC = AB9.AB9_CODTEC AND;
 ABA.ABA_SEQ = AB9.AB9_SEQ AND ABA.%notDel%)

Where ABB.ABB_CODTEC BETWEEN %exp:AllTrim(cCliDe)% AND %exp:AllTrim(cCliAt)% AND
	   ABB.ABB_DTINI >= %exp:dDtIni% AND ABB.ABB_DTFIM <= %exp:dDtFim% AND
	   ABB.ABB_ATENDE = "1" AND
	   ABB.ABB_ATIVO = "1" AND
	   ABB.ABB_LOCAL <> " " AND
	   ABB.%notDel%

Group by ABB.ABB_CODTEC,ABS.ABS_CCUSTO,AA1.AA1_CDFUNC,ABB.ABB_LOCAL, AA1.AA1_FUNFIL

Order by AA1.AA1_CDFUNC,ABB.ABB_LOCAL
	   
EndSql

If (cAliasA)->(!EOF())
	(cAliasA)->(dbEval({||nQtdProc++}))
	If oProcess <> Nil
		oProcess:SetRegua1(nQtdProc)
	EndIf

	(cAliasA)->(dbGoTop())
	
	cAtendOld := (cAliasA)->(ABB_CODTEC)
	
	While !(cAliasA)->(EOF())
		cAtend := (cAliasA)->(ABB_CODTEC)
		nTotLc	:= (cAliasA)->(TOTAL)
		cLoc 	:= (cAliasA)->(ABB_LOCAL)
		cCC		:= (cAliasA)->(ABS_CCUSTO)
		cFunc	:= (cAliasA)->(AA1_CDFUNC)
		
		If cAtendOld != (cAliasA)->(ABB_CODTEC) .AND. cAtendOld != ""
			A960VldPrR(aAtend,aTot,cCompt,nSobrR,nProc,nGerLg,oProcess)
			aAtend := {}
		EndIF
		
		cAtendOld := (cAliasA)->(ABB_CODTEC)		
		
		If oProcess <> Nil
			oProcess:IncRegua2(STR0012 + (cAliasA)->ABB_CODTEC + STR0013 )			//"Aguarde... Processando o rateio do "#'...'
		EndIf
		
		nPos := aScan(aAtend,{|x| x[1] == (cAliasA)->(ABB_CODTEC) .AND. x[4] == (cAliasA)->(ABS_CCUSTO) })
		If nPos > 0 //Se encontrar o mesmo atendente com o mesmo centro de custo, soma os valores
			aAtend[nPos][2] += nTotLc			
		Else		
			aAdd(aAtend,{cAtend,nTotLc,cLoc,cCC,cFunc,(cAliasA)->AA1_FUNFIL})
		EndIf
		
		nPos := aScan(aTot,{|x| x[1] == (cAliasA)->(ABB_CODTEC) })
		If nPos > 0
			aTot[nPos][2] += nTotLc
		Else
			aAdd(aTot,{cAtend,nTotLc})//controle do total do atendente
		EndIf
								
		(cAliasA)->(DBSkip())
	End
	
	//Processa o ultimo atendente
	A960VldPrR(aAtend,aTot,cCompt,nSobrR,nProc,nGerLg,oProcess)
	aAtend := {}
	
		
EndIf

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} A960VldPrR
	Valida a Programação de Rateio

@sample 	A960VldPrR() 

@since		25/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function A960VldPrR(aAtend,aTot,cCompt,nSobrR,nProc,nGerLg,oProcess)

Local aRat		:= {}
Local nX		:= 0
Local nZ		:= 0
Local cPerc	:= "99."

For nZ := 1 to (TamSx3("RHQ_PERC")[2])
 cPerc += '9'
Next

If nProc == 1 //Envio

	For nX := 1 to Len(aAtend)
		
		If oProcess <> Nil
			oProcess:SetRegua1(nX)
		EndIf
		
		nPos := aScan(aTot,{|x| x[1] == aAtend[nX][1]})
		If nPos > 0
			nTotal := ((aAtend[nX][2]*100)/aTot[nPos][2])
			If nTotal <> 100
				nPos := aScan(aRat,{|x| x[1] == aAtend[nX][5] .AND. x[2] == aAtend[nX][6] })
				If nPos > 0
					aAdd(aRat[nPos][3],{cCompt,aAtend[nX][4],nTotal})
				Else
					aAdd(aRat,{aAtend[nX][5], aAtend[nX][6],{{cCompt,aAtend[nX][4],nTotal}}})
				EndIf
			Else
				DbSelectArea("SRA")
				DbSetOrder(1)//RA_FILIAL + RA_MAT
				If SRA->(DbSeek(aAtend[nX][6]+aAtend[nX][5]))
					If aAtend[nX][4] <> SRA->RA_CC
						aAdd(aRat,{aAtend[nX][5], aAtend[nX][6],{{cCompt,aAtend[nX][4],Val(cPerc)}}})
					EndIf
				EndIf
			EndIf
		EndIf
	
	Next nX

	A960ProRat(aRat,nSobrR,cCompt,nGerLg,nProc,oProcess)
			
	
ElseIf nProc == 2 //Estorno

	At960EstRt(aAtend,cCompt,nProc,nGerLg,oProcess)

EndIf

aAtend := {}

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} A960ProRat
	Envio da Programação de Rateio

@sample 	A960ProRat() 

@since		26/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function A960ProRat(aRat,nSobrR,cCompt,nGerLg,nProc,oProcess)

Local oModel	:= FwLoadModel("GPEA056")
Local lRet		:= .T.
Local lSobrEs	:= .F.
Local lExist	:= .F.
Local cProgRt	:= ""
Local aErro	:= {}
Local nW		:= 0
Local nY		:= 0
Local cFilBkp := cFilAnt

For nY := 1 To Len(aRat)

	lRet	:= .T.
	
	If oProcess <> Nil
		oProcess:IncRegua2(STR0012 + aRat[nY][1] + STR0013 )			////"Aguarde... Processando o rateio do "#'...'
	EndIf
		
	DbSelectArea("RHQ")
	DbSetOrder(1) //RHQ_FILIAL+RHQ_MAT+RHQ_DEMES
	If RHQ->(DbSeek(aRat[nY][2]+aRat[nY][1]+cCompt))
		cProgRt := aRat[nY][2]+aRat[nY][1]+cCompt
		lExist := .T.
		If nSobrR == 1 //Sim
			lSobrEs := .T.
		ElseIf nSobrR == 2 //Não
			lSobrEs := .F.	
		EndIf
	EndIf

	If lSobrEs //Se Sobreescreve sim
		While RHQ->(!EOF()) .AND. cProgRt == RHQ_FILIAL+RHQ_MAT+RHQ_DEMES
			RecLock("RHQ",.F.)
			RHQ->(DbDelete())			//deleta item
			RHQ->(MsUnLock())
			RHQ->(DbSkip())
		End
	Else
		If lExist //Se Existe
			lRet := .F.
			lExist := .F.
		EndIf		
	EndIf
	
	If lRet
	
		DbSelectArea("SRA")
		SRA->(DbSetOrder(1)) //RA_FILIAL + RA_MAT
		SRA->(DbSeek(aRat[nY][2]+aRat[nY][1]))
		
		Inclui := .F.
		Altera := .T.
		cFilBkp := cFilAnt
		cFilAnt := aRat[nY][2]
		oModel:SetOperation(MODEL_OPERATION_UPDATE)
		oModel:Activate()
	
		If oModel:GetModel( "RHQDETAIL" ):Length() > 1 .OR. !Empty(oModel:GetValue("RHQDETAIL", "RHQ_DEMES"))
			oModel:GetModel("RHQDETAIL"):AddLine()
		EndIf
	
		For nW := 1 To Len(aRat[nY][3])			
			oModel:SetValue("RHQDETAIL", "RHQ_DEMES",aRat[nY][3][nW][1])//cCompt)
			oModel:SetValue("RHQDETAIL", "RHQ_AMES" ,aRat[nY][3][nW][1])//cCompt)
			oModel:SetValue("RHQDETAIL", "RHQ_CC"   ,aRat[nY][3][nW][2])//cCentCust)
			oModel:SetValue("RHQDETAIL", "RHQ_PERC" ,aRat[nY][3][nW][3])//nTotal)
			If Len(aRat[nY][3]) > 1 .AND. nW <> Len(aRat[nY][3])
				oModel:GetModel("RHQDETAIL"):AddLine()
			EndIf	
		Next nW
		
		If ( lRetVl := oModel:VldData() ) //Validação dos dados
			
			// Se o dados foram validados faz-se a gravação efetiva dos
			// dados (commit)
			oModel:CommitData()
			
			aErro := {}
			
			At960GrLg(aErro,aRat[nY][2], aRat[nY][1],STR0014,nGerLg,cCompt,nProc,.F.)		//"Programação de Rateio Enviada com sucesso"
			
		EndIf
	
		If !lRetVl
	
			aErro := oModel:GetErrorMessage()
	
			At960GrLg(aErro,aRat[nY][2], aRat[nY][1],STR0015,nGerLg,cCompt,nProc,.F.)			//"Erro no envio da programação de Rateio"
		
		EndIf
	
		oModel:DeActivate()

		cFilAnt := cFilBkp

	EndIf

Next nY


Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At960EstRt
	Estorno da Programação de Rateio

@sample 	At960EstRt() 

@since		26/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At960EstRt(aAtend,cCompt,nProc,nGerLg,oProcess)

Local nX := 0
Local aErro := {}
Local oModel	:= FwLoadModel("GPEA056")
Local lOk 	:= .T.

DbSelectArea("RHQ")
DbSelectArea("SRA")

For nX := 1 To Len(aAtend)

	If oProcess <> Nil
		oProcess:IncRegua2(STR0016 + aAtend[nX][5] + STR0013 )		//"Aguarde... Excluindo a programação de rateio do "#'...'
	EndIf

	RHQ->( DbSetOrder(1) ) //RHQ_FILIAL+RHQ_MAT+RHQ_DEMES
	SRA->( DbSetOrder(1) ) // RA_FILIAL + RA_MAT
	
	Inclui := .F.
	Altera := .F.
	If SRA->(DbSeek(aAtend[nX][6]+aAtend[nX][5]))  .And. ;
		RHQ->(DbSeek(aAtend[nX][6]+aAtend[nX][5]+cCompt))
		
		cAtend := aAtend[nX][6]+aAtend[nX][5]+cCompt
		nNEnv++
		aErro := {}
		
		oModel:SetOperation(MODEL_OPERATION_DELETE)
		lOk := oModel:Activate()
		
		If lOk 
			lOk := oModel:VldData() .And. oModel:CommitData()
			
			If !lOk 
				aErro := oModel:GetErrorMessage()
			EndIf
			
			At960GrLg(aErro,aAtend[nX][6],aAtend[nX][5],STR0017,nGerLg,cCompt,nProc,.F.)		//"Programação de Rateio Excluída com sucesso"
			
			oModel:DeActivate()	
		EndIf
		
	EndIf

Next nX

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} At960Cfol
	Realiza a conversão da competencia na folha

@sample 	At960Cfol() 

@since		24/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At960Cfol(cCompFolh)

Local cAno		:= ""
Local cMes		:= ""
Local cRet		:= ""

cAno := SubStr(cCompFolh,4,7)
cMes := SubStr(cCompFolh,1,2)

cRet := cMes+cAno

Return cRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At960VlPrg
	Validação dos perguntes

@sample 	At960VlPrg() 

@since		24/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At960VlPrg(dDtIni,dDtFim,cCompt)

Local lRet := .T.

If Empty(dDtIni)
	MsgAlert(STR0019)		//"Preencha a data inicial"
	lRet := .F.
EndIf

If Empty(dDtFim)
	MsgAlert(STR0020)			//"Preencha a data final"
	lRet := .F.
EndIf

If Alltrim(cCompt) == "/" 
	MsgAlert(STR0021)		//"Preencha o campo competência"
	lRet := .F.
EndIf

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At960GrLg
	Geração dos Logs

@sample 	At960GrLg() 

@since		24/03/2014       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At960GrLg(aErro,cFilFun, cCodFunc,cMsg,nGerLg,cCompt,nProc,lFim)

Local cTexto	
Local cNome	:= ""
Local cDirDest := MV_PAR09 //Dir. onde o arquivo log será copiado.
Local cPath := ""

Default aErro 	:= {}
Default cCodFunc	:= ""

If !Empty(cCodFunc)
	cNome	:= Alltrim(Posicione("SRA",1,cFilFun+cCodFunc,"SRA->RA_NOME"))
EndIf

If !lFim
	
	cTexto := STR0022+cFilFun+"/"+cCodFunc+STR0023+cNome+" "+STR0035+cCompt+CRLF		//"Funcionário: "##" - "##"Competência: "##
	
	If nProc == 1		////Processamento Envio
	
		If Len(aErro) > 0
			nNEnv++
			cTexto +=	" "+CRLF+cMsg+CRLF;
						+" "+CRLF+STR0024+'['+ AllToChar( aErro[1] )+']'+CRLF;	//"Id do formulário de origem:"
						+" "+STR0025+'['+ AllToChar( aErro[2] ) +']'+CRLF;		//"Id do campo de origem: "
						+" "+STR0026+'['+ AllToChar( aErro[3] ) +']'+CRLF;		//"Id do formulário de erro: "
						+" "+STR0027+'['+ AllToChar( aErro[4] ) +']'+CRLF;		//"Id do campo de erro: "
						+" "+STR0028+'['+ AllToChar( aErro[5] ) +']'+CRLF;		//"Id do erro: "
						+" "+STR0029+'['+ AllToChar( aErro[6] ) +']'+CRLF;		//"Mensagem do erro: "
						+" "+STR0030+'['+ AllToChar( aErro[7] ) +']'+CRLF;		//"Mensagem da solução: "
						+" "+STR0031+'['+ AllToChar( aErro[8] ) +']'+CRLF;		//"Valor atribuído: "
						+" "+STR0032+'['+ AllToChar( aErro[9] ) +']'+CRLF;		//"Valor anterior: "
	    				+CRLF+"---------------------------------------------------"+CRLF+CRLF
	    				
		Else
		
			nEnv++
			If nGerLg == 1
				cTexto +=	" "+CRLF+cMsg+CRLF;
							+CRLF+"---------------------------------------------------"+CRLF+CRLF
			EndIf
			
		EndIf
		
	Else	//Processamento Estorno
		
		cTexto +=	" "+CRLF+cMsg+CRLF;
		+CRLF+"---------------------------------------------------"+CRLF+CRLF
	
	EndIf

Else
	cTexto :=	STR0033+cValToChar(nEnv)+CRLF;			//"Enviadas: "
				+STR0034+cValToChar(nNEnv)+CRLF;		//"Não Enviadas: "
				+CRLF+"---------------------------------------------------"+CRLF+CRLF	
EndIf	
	
	TxLogFile("ProgRateio",cTexto)
	
	cPath := TxLogPath("ProgRateio") //Resgata o nome do arquivo log gerado
	CpyS2T(cPath, cDirDest, .F. ) //Faz uma cópia do log para a maquina do usuario

Return