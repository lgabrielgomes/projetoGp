#INCLUDE "Protheus.ch"
#INCLUDE "TECC070.ch"
#INCLUDE "Tecc070_Def.ch"

//------------------------------------------------------------------------------
/*/{Protheus.doc} Tc072Print
Funcao Principal de impressão de uma GetDados presente na rotina Central do Cliente
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Function Tc072Print(aHeader,cNodeId,cCliente,aCols)
	Local aCabec	:= LoadCabec(aHeader)
	Local aTables	:= LoadTables(aCabec)
	Local oReport	:= Nil
	Local cTitle	:= LoadTitle(cNodeId)
	
	If len(aCabec) > 0 .and. TRepInUse() 
		oReport := RepInit(aCabec,cTitle,aTables,cCliente,aCols) 
		oReport:SetLandScape()
		oReport:PrintDialog()	
	EndIf
Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} RepInit
Função responsavel por elaborar o layout do relatorio a ser impresso
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function RepInit(aCabec,cTitle,aTables,cCliente,aCols)
	Local oReport
	Local oSection1
	Local nI
	Local cRpTit := STR0001 + " / " + cTitle + " / " + cCliente
	
	//Define o relatorio e a(s) sua(s) seções
	oReport := TReport():New("REL001",cRpTit,,{|oReport| PrintReport(oReport,aCols,aCabec)},cRpTit)
	oSection1 := TRSection():New(oReport ,cCliente ,aTables)
	oSection1:SetReadOnly(.T.) 
	
	//Define a(s) coluna(s) do relatorio
	For nI := 1 to len(aCabec)
		TRCell():New(oSection1,aCabec[nI,1],aCabec[nI,2],aCabec[nI,3],aCabec[nI,4],aCabec[nI,5])
	Next nI
	
Return oReport

//------------------------------------------------------------------------------
/*/{Protheus.doc} PrintReport
Função responsavel por selecionar e pintar os dados (registros) no relatorio
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function PrintReport(oReport,aCols,aCabec)
	Local oSection1 := oReport:Section(1)
	Local cMeuAlias := GetNextAlias() 
	Local nI		:= 0
	Local nJ		:= 0

	oSection1:Init()
	For nI := 1 to len(aCols)				
		//Relaciona a coluna ao item da aCols
		For nJ := 1 to len(aCabec)
			oSection1:Cell(aCabec[nJ,1]):SetValue(aCols[nI,nJ])
		Next nJ
		oSection1:PrintLine()			
	Next nI
	oSection1:Finish()
		
Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} LoadCabec
Retorna um array criado a partir da aHeader da GetDados que servira como Cabeçalho
do Relatorio a ser construido.
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function LoadCabec(aHeader)
	Local aRet		:= {}
	Local nI		:= 1
	Local cField	:= ""
	Local cTbl		:= ""
	Local cTitle	:= ""
	Local cMask		:= ""
	Local nTam		:= 0
	Local nDec		:= 0
	
	If len(aHeader) > 0
		For nI := 1 to len(aHeader)
		
			cField	:= aHeader[nI,2]
			cTbl	:= StrTokArr(aHeader[nI,2],"_")[1] 
			cTitle	:= alltrim(aHeader[nI,1])
			cMask	:= aHeader[nI,3]
			nTam	:= aHeader[nI,4]
			nDec	:= aHeader[nI,5]
		
			aAdd(aRet,{cField,cTbl,cTitle,cMask,nTam,nDec})
		Next nI
	EndIf	

Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} LoadTables
Retorna um array com todas as tabelas contidas no relatorio
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function LoadTables(aCabec)
	Local aRet := {}
	Local nI	:= 0
	
	For nI := 1 to len(aCabec)
		If aScan(aRet,aCabec[nI,2]) <= 0		
			aAdd(aRet,aCabec[nI,2])
			
			//Adiciona o S a esquerda caso o campo seja por exemplo E1_PREFIXO
			If len(alltrim(aRet[len(aRet)])) == 2
				aRet[len(aRet)] := "S" + aRet[len(aRet)]
			EndIf 
			
		EndIf
	Next nI
Return aRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} LoadTitle
Retorna uma string com o titulo do relatorio de acordo com o Nó selecionado
 
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
Static Function LoadTitle(cNodeID)
	Local cRet := ""
	
	Do Case
		//Sem Proposta
		Case cNodeID == I_OP_SEMPROP
			cRet := STR0003 + " - " + STR0004 
		//Em Aberto
		Case cNodeID == I_OP_EMABERT
			cRet := STR0003 + " - " + STR0005
		//Encerradas
		Case cNodeID == I_OP_ENCERRA
			cRet := STR0003 + " - " + STR0006
		//Canceladas
		Case cNodeID == I_OP_CANCELA	
			cRet := STR0003 + " - " + STR0007
		//Em Aberto
		Case cNodeID == I_PR_EMABER
			cRet := STR0008 + " - " + STR0009 		
		//Finalizadas			
		Case cNodeID == I_PR_FINALI		
			cRet := STR0008 + " - " + STR0010
		//Vistorias Técnicas
		Case cNodeID == I_PR_VISTEC		
			cRet := STR0008 + " - " + STR0043							
		//Vigentes
		Case cNodeID == I_CT_VIGENT
			cRet := STR0011 + " - " + STR0012		
		//Encerrados
		Case cNodeID == I_CT_ENCERR
			cRet := STR0011 + " - " + STR0013	
		//Medicoes
		Case cNodeID == I_CT_MEDICA
			cRet := STR0011 + " - " + STR0044	
		//Provisorios em Dia
		Case cNodeID == I_FI_PRVABE
			cRet := STR0014 + " - " + STR0063
		//Provisorios Vencidos
		Case cNodeID == I_FI_PRVVEN
			cRet := STR0014 + " - " + STR0064
		//Titulos em Aberto
		Case cNodeID == I_FI_TITABE
			cRet := STR0014 + " - " + STR0015
		//Titulos Baixados
		Case cNodeID == I_FI_TITBXA
			cRet := STR0014 + " - " + STR0016			
		//Titulos Vencidos
		Case cNodeID == I_FI_TITVEN
			cRet := STR0014 + " - " + STR0017		
		//Pedidos em Aberto
		Case cNodeID == I_FT_PEDABE
			cRet := STR0018 + " - " + STR0019		
		//Pedidos Faturados
		Case cNodeID == I_FT_PEDFAT
			cRet := STR0018 + " - " + STR0020
		//NF (Servico)
		Case cNodeID == I_FT_NOTSRV
			cRet := STR0018 + " - " + STR0040
		//NF (Remessa)
		Case cNodeID == I_FT_NOTREM
			cRet := STR0018 + " - " + STR0041 
		//NF (Retorno)
		Case cNodeID == I_FT_NOTRET
			cRet := STR0018 + " - " + STR0042		
		//NF (Outros)
		Case cNodeID == I_FT_NOTOTR
			cRet := STR0018 + " - " + STR0045		
		//Locais Atendidos
		Case cNodeID == I_LA_CONTRA
			cRet := STR0021 + " - " + STR0022		
		//Sem Contrato
		Case cNodeID == I_LA_SEMCON
			cRet := STR0021 + " - " + STR0023
		//Reservados
		Case cNodeID == I_EQ_RESERV
			cRet := STR0024 + " - " + STR0025		
		//Locados
		Case cNodeID == I_EQ_LOCADO
			cRet := STR0024 + " - " + STR0026		
		//Devolvidos
		Case cNodeID == I_EQ_DEVOLV
			cRet := STR0024 + " - " + STR0027		
		//A Separar
		Case cNodeID == I_EQ_ASEPAR
			cRet := STR0024 + " - " + STR0028	
		//Postos
		Case cNodeID == I_RH_POSTOS
			cRet := STR0029 + " - " + STR0030			
		//"Atendentes (Histórico)"
		Case cNodeID == I_RH_ATEND
			cRet := STR0029 + " - " + STR0031
		//"Atendentes (Alocados)"
		Case cNodeID == I_RH_ATFUT
			cRet := STR0029 + " - " + STR0046
		//OS SIGATEC
		Case cNodeID == I_OS_SIGTEC
			cRet := STR0032 + " - " + STR0033		
		//OS SIGAMNT
		Case cNodeID == I_OS_SIGMNT
			cRet := STR0032 + " - " + STR0034
		//Armas
		Case cNodeID == I_AR_ARMAS
			cRet := STR0035 + " - " + STR0036					
		//Coletes
		Case cNodeID == I_AR_COLETE
			cRet := STR0035 + " - " + STR0037		
		//Municoes
		Case cNodeID == I_AR_MUNICO
			cRet := STR0035 + " - " + STR0038
	EndCase

Return cRet