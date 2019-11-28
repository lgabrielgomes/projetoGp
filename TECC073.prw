#INCLUDE "Protheus.ch" 
#INCLUDE "TECC070.ch" 
#INCLUDE "Tecc070_Def.ch"

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc073LoadGph
Retorna um array com dados de Graficos a serem exibidos. Chama a funcao especifica
para cada no clicado
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc073LoadGph(cNodeID,cCodCli,cLojCli,dDataDe,dDataAte)
	Local aRet := {}
	
	Do Case
		Case cNodeID == M_OPORT 														 		//"Oportunidades"
			aAdd(aRet,{STR0004,Len(Tc071OpNoProp(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 		//"Sem Proposta"
			aAdd(aRet,{STR0005,Len(Tc071OpAberta(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 		//"Em Aberto"
			aAdd(aRet,{STR0006,Len(Tc071OpEncerr(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 		//"Encerradas"
			aAdd(aRet,{STR0007,Len(Tc071OpCancel(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 		//"Canceladas"
						
		Case cNodeID == M_PROPOSTAS 															//"Propostas"
			aAdd(aRet,{STR0009,Len(Tc071PropAb(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Em aberto"
			aAdd(aRet,{STR0010,Len(Tc071PropEn(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Finalizadas"
			aAdd(aRet,{STR0043,Len(Tc071PropVT(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Vistorias Tecnica"
			
		Case cNodeID == M_CONTRATOS														 		//"Contratos"		
			aAdd(aRet,{STR0012,Len(Tc071CtrVig(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Vigentes"
			aAdd(aRet,{STR0013,Len(Tc071CtrEnc(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 		 	//"Encerrados"
			aAdd(aRet,{STR0044,Len(Tc071CtrMed(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 		 	//"Medicoes"
			
		Case cNodeID == M_FINANCEIR														 		//"Financeiro"			
			aAdd(aRet,{STR0063,Len(Tc071TitPAb(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Provisorios em Dia"
			aAdd(aRet,{STR0064,Len(Tc071TitPVc(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Provisorios Vencidos"
			aAdd(aRet,{STR0015,Len(Tc071TitAbr(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Titulos em Aberto"
			aAdd(aRet,{STR0016,Len(Tc071TitBxa(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Titulos Baixados"
			aAdd(aRet,{STR0017,Len(Tc071TitVnc(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Titulos Vencidos"
						
		Case cNodeID == M_FATURAMEN														 		//"Faturamento"
			aAdd(aRet,{STR0019,Len(Tc071PedAbr(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Pedidos em Aberto"
			aAdd(aRet,{STR0020,Len(Tc071PedFat(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Pedidos Faturados"			
			aAdd(aRet,{STR0040,Len(Tc071NFSrv(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"NF (Serviço)"
			aAdd(aRet,{STR0041,Len(Tc071NFRms(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"NF (Remessa)"
			aAdd(aRet,{STR0042,Len(Tc071NFRet(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"NF (Retorno)"
			aAdd(aRet,{STR0045,Len(Tc071NFOut(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"NF (Outros)"
			
		Case cNodeID == M_LOCAISATE																//"Locais de Atendimento"
			aAdd(aRet,{STR0022,Len(Tc071LACtr(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Atendidos"
			aAdd(aRet,{STR0023,Len(Tc071LAVzo(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Sem Contrato"
			
		Case cNodeID == M_EQUIPAMEN														 		//"Equipamentos"
			aAdd(aRet,{STR0025,Len(Tc071EqRes(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Reservados"
			aAdd(aRet,{STR0028,Len(Tc071EqASp(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"A Separar"
			aAdd(aRet,{STR0048,Len(Tc071EqSep(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Separados"
			aAdd(aRet,{STR0026,Len(Tc071EqLoc(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Locados"
			aAdd(aRet,{STR0027,Len(Tc071EqDev(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Devolvidos"
			
		Case cNodeID == M_RECHUMANO														 		//"Recursos Humanos"
			aAdd(aRet,{STR0030,Len(Tc071RHPos(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Postos RH"
			aAdd(aRet,{STR0031,Len(Tc071RHAHs(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Atendentes (Histórico)"
			aAdd(aRet,{STR0046,Len(Tc071RHAFt(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Atendentes (Alocados)"
			
		Case cNodeID == M_ORDSERICO														 		//"Ordens de Serviço"
			aAdd(aRet,{STR0033,Len(Tc071OSTec(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"OS SIGATEC"
			aAdd(aRet,{STR0034,Len(Tc071OSMnt(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"OS SIGAMNT"
			
		Case cNodeID == M_ARMAMENTO														 		//"Armamentos"
			aAdd(aRet,{STR0036,Len(Tc071GAArm(cCodCli,cLojCli,dDataDe,dDataAte)[2])})			//"Armas"
			aAdd(aRet,{STR0037,Len(Tc071GACol(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 			//"Coletes"
			aAdd(aRet,{STR0038,Len(Tc071GAMun(cCodCli,cLojCli,dDataDe,dDataAte)[2])}) 			//"Munições"
		EndCase	
	
Return aRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc073SavePng
Chama a interface para salvar uma imagem do grafico em questao
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc073SavePng(cNodeID,oObjGrp)
	Local cPath := ""
	Local cRet	:= ""
		
	If ValType(oObjGrp) == "O"
		cPath := cGetFile("Arquivos Tipo PNG" + "(*.PNG)|*.PNG|","Salvar Imagem",1,"c:\",.F.,GETF_LOCALFLOPPY + GETF_LOCALHARD +  GETF_NETWORKDRIVE ,.T.,.T.)
		
		If !Empty(cPath)
			If !(".PNG" $ (cPath))
				cPath := cPath + ".png"
			EndIf			
		 	cRet := oObjGrp:SavetoPng(0.1,0.1,oObjGrp:nCWidth * 1.20 ,oObjGrp:nCHeight  * 1.20 ,cPath)
		 	
		 	If !Empty(cPath)
		 		MsgInfo("Arquivo salvo com sucesso no caminho " + cPath)
		 	EndIf
		 EndIf
	EndIf
	
Return 


//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc073MapNode
Contem o mapa das barras de grafico x sua respectiva posicao no oTree
Devolve qual node da arvore deve ser selecionado a partir do clique duplo 
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc073MapNode(cNodeId,oObj)
	Local nBarSel	:= oObj:oOwner:ShapeAtu
	Local cToNode	:= ""
	
	//MsgInfo('Oi Matheus, voce clicou em: ' + cNodeID + " - Barra numero: " + alltrim(str(nBarSel)))
	
	Do Case
		//"Oportunidades"
		Case cNodeID == M_OPORT 														 		
			If nBarSel == 1			//"Sem Proposta"
				cToNode	:= I_OP_SEMPROP
			ElseIf  nBarSel == 2	//"Em Aberto"
				cToNode	:= I_OP_EMABERT
			ElseIf nBarSel == 3		//"Encerradas"
				cToNode	:= I_OP_ENCERRA
			ElseIf nBarSel == 4		//"Canceladas"
				cToNode	:= I_OP_CANCELA
			EndIf

		//"Propostas"
		Case cNodeID == M_PROPOSTAS 
			If nBarSel == 1			//"Em aberto"
				cToNode	:= I_PR_EMABER
			ElseIf  nBarSel == 2	//"Finalizadas"
				cToNode	:= I_PR_FINALI
			ElseIf nBarSel == 3		//"Vistorias Tecnica"
				cToNode	:= I_PR_VISTEC
			EndIf
		
		//"Contratos"	
		Case cNodeID == M_CONTRATOS
			If nBarSel == 1			//"Vigentes"
				cToNode	:= I_CT_VIGENT
			ElseIf  nBarSel == 2	//"Encerrados"
				cToNode	:= I_CT_ENCERR
			ElseIf nBarSel == 3		//"Medicoes"
				cToNode	:= I_CT_MEDICA
			EndIf
			
		//"Financeiro"
		Case cNodeID == M_FINANCEIR														 		
			If nBarSel == 1			//"Provisorios em Dia"
				cToNode	:= I_FI_PRVABE
			ElseIf nBarSel == 2		//"Provisorios Vencidos""
				cToNode	:= I_FI_PRVVEN
			ElseIf nBarSel == 3		//"Titulos em Aberto"
				cToNode	:= I_FI_TITABE
			ElseIf  nBarSel == 4	//"Titulos Baixados"
				cToNode	:= I_FI_TITBXA
			ElseIf nBarSel == 5		//"Titulos Vencidos"
				cToNode	:= I_FI_TITVEN
			EndIf
			
		//"Faturamento"				
		Case cNodeID == M_FATURAMEN														 		
			If nBarSel == 1			//"Pedidos em Aberto"
				cToNode	:= I_FT_PEDABE
			ElseIf  nBarSel == 2	//"Pedidos Faturados"
				cToNode	:= I_FT_PEDFAT
			ElseIf nBarSel == 3		//"NF (Serviço)"
				cToNode	:= I_FT_NOTSRV
			ElseIf  nBarSel == 4	//"NF (Remessa)"
				cToNode	:= I_FT_NOTREM
			ElseIf nBarSel == 5		//"NF (Retorno)"
				cToNode	:= I_FT_NOTRET
			ElseIf nBarSel == 6		//"NF (Outros)"
				cToNode	:= I_FT_NOTOTR
			EndIf
		
		//"Locais de Atendimento"	
		Case cNodeID == M_LOCAISATE
			If nBarSel == 1			//"Atendidos"
				cToNode	:= I_LA_CONTRA
			ElseIf  nBarSel == 2	//"Sem Contrato"
				cToNode	:= I_LA_SEMCON
			EndIf

		//"Equipamentos"
		Case cNodeID == M_EQUIPAMEN														 		
			If nBarSel == 1			//"Reservados"
				cToNode	:= I_EQ_RESERV			
			ElseIf  nBarSel == 2	//"A Separar"
				cToNode	:= I_EQ_ASEPAR
			ElseIf  nBarSel == 3	//"Separados"
				cToNode	:= I_EQ_SEPARA
			ElseIf  nBarSel == 4	//"Locados"
				cToNode	:= I_EQ_LOCADO				
			ElseIf nBarSel == 5	//"Devolvidos"
				cToNode	:= I_EQ_DEVOLV			
			EndIf
		
		//"Recursos Humanos"	
		Case cNodeID == M_RECHUMANO
			If nBarSel == 1			//"Postos RH"
				cToNode	:=	I_RH_POSTOS
			ElseIf  nBarSel == 2	//"Atendentes (Histórico)"
				cToNode	:= I_RH_ATEND
			ElseIf nBarSel == 3		//"Atendentes (Alocados)"
				cToNode	:= I_RH_ATFUT
			EndIf		
			
		//"Ordens de Serviço"
		Case cNodeID == M_ORDSERICO														 		
			If nBarSel == 1			//"OS SIGATEC"
				cToNode	:= I_OS_SIGTEC
			ElseIf  nBarSel == 2	//"OS SIGAMNT"
				cToNode	:= I_OS_SIGMNT
			EndIf		
			
		//"Armamentos"	
		Case cNodeID == M_ARMAMENTO														 		
			If nBarSel == 1			//"Armas"
				cToNode	:= I_AR_ARMAS
			ElseIf  nBarSel == 2	//"Coletes"
				cToNode	:= I_AR_COLETE
			ElseIf  nBarSel == 3	//"Munições"
				cToNode	:= I_AR_MUNICO
			EndIf
		EndCase	

	
Return cToNode