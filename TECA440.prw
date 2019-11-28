#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TECA440.CH'

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECA440
	Constrói o browse para as operações relacionadas com a gestão da disciplina

@sample		TECA440(Nil)
	
@since		12/02/2014 
@version 	P12

@param		cFilDef, Caracter, filtro padrão a ser inserido na exibição do browse

/*/
//--------------------------------------------------------------------------------------------------------------------
Function TECA440(cFilDef)

Local oBrw := FwMBrowse():New()

DEFAULT cFilDef := ''

oBrw:SetAlias( 'TIT' )
oBrw:SetMenudef( "TECA440" )
oBrw:SetDescription( OEmToAnsi( STR0001 ) ) //"Gestão de Disciplina"

If !Empty(cFilDef)
	oBrw:SetFilterDefault(cFilDef)
EndIf

oBrw:Activate()

Return

//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
	Rotina para construção do menu
@sample 	Menudef() 
@since		06/09/2013  
@version 	P11.90
/*/
//------------------------------------------------------------------------------
Static Function Menudef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar"  ACTION "VIEWDEF.TECA440" OPERATION 2   ACCESS 0 // "Visualizar"
ADD OPTION aRotina TITLE "Incluir"  ACTION "At440GsDc(3)" OPERATION MODEL_OPERATION_INSERT ACCESS 0 // "Incluir"
ADD OPTION aRotina TITLE "Alterar"  ACTION "At440GsDc(4)" OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // "Alterar"
ADD OPTION aRotina TITLE "Excluir"  ACTION "VIEWDEF.TECA440" OPERATION MODEL_OPERATION_DELETE ACCESS 0 // "Excluir"
ADD OPTION aRotina TITLE "Imprimir"  ACTION "VIEWDEF.TECA440"  OPERATION 8 ACCESS 0//"Imprimir browse"
ADD OPTION aRotina TITLE "Copiar"  ACTION "VIEWDEF.TECA440" OPERATION 9						ACCESS 0 // "Copiar"

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados

@author arthur.colado

@since 12/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ModelDef()
Local oModel
 
Local oStr1:= FWFormStruct(1,'TIT') 
Local oStr2:= FWFormStruct(1,'TIU') 


oModel := MPFormModel():New('TECA440',,{|oModel|A440VLDPOS(oModel)},{|oModel|AT440GRV(oModel)})
oModel:SetDescription('TECA440')

oStr1:RemoveField( 'TIT_USUARI' )
oStr1:RemoveField( 'TIT_FILIAL' )

oModel:addFields('TIT',,oStr1)
oModel:SetPrimaryKey({ 'TIT_CODIGO' })


oStr2:RemoveField( 'TIU_CODTIT' )
oStr2:RemoveField( 'TIU_FILIAL' )

oModel:addGrid('TIU','TIT',oStr2)
oModel:SetRelation('TIU', { { 'TIU_FILIAL', 'xFilial("TIT")' }, { 'TIU_CODTIT', 'TIT_CODIGO' } }, TIU->(IndexKey(1)) )

oModel:getModel('TIT'):SetDescription(STR0001)	//Gestão de Disciplina
oModel:getModel('TIU'):SetDescription(STR0002)	//Processos Relacionados
oModel:GetModel( 'TIU' ):SetOptional( .T. )


oStr1:SetProperty( "TIT_CODRES", MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "At440VlRes()" ))

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição do interface

@author arthur.colado

@since 12/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ViewDef()
Local oView
Local oModel := ModelDef() 
Local oStr1:= FWFormStruct(2, 'TIT')
Local oStr2:= FWFormStruct(2, 'TIU')

oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField(STR0001 , oStr1,'TIT' )	//'Gestão de Disciplina
oView:AddGrid(STR0002 , oStr2,'TIU')	//Processos Relacionados

oStr1:RemoveField( 'TIT_OCORR' )
oStr1:RemoveField( 'TIT_USUARI' )
oView:CreateHorizontalBox( 'BOXFORM1', 66)

oStr2:RemoveField( 'TIU_CODTIT' )
oStr2:RemoveField( 'TIU_CODTIT' )

oView:CreateHorizontalBox( 'BOXFORM3', 34)
oView:SetOwnerView(STR0002,'BOXFORM3')	//Processos Relacionados
oView:SetOwnerView(STR0001,'BOXFORM1')	//'Gestão de Disciplina
oView:SetFieldAction( 'TIT_CODTEC', { |oView, cIDView, cField, xValue| At440ValDis()} )
oView:SetFieldAction( 'TIT_QTDDIA', { |oView, cIDView, cField, xValue| At440Falta()} )
oView:AddUserButton(STR0003, 'CLIPS',{|oView| AT440VisForm()}) //Imprimir Disciplina

Return oView

//------------------------------------------------------------------------------
/*/{Protheus.doc} At440ValDis()
Rotina valida o histórico de punições que funcionário ja recebeu


@author arthur.colado
@since 12/02/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At440ValDis()

Local cAlias	:= GetNextAlias()
Local cFunc 	:= FwFldGet("TIT_CODTEC")
Local cCodDis 	:= FwFldGet("TIT_CODTIQ")
Local dData 	:= FwFldGet("TIT_DATA")
Local cMensagem := ""
Local cDescri	:= ""

If Empty(cCodDis) .OR. Empty(dData)
	cMensagem := STR0004		// "Os campos Disciplina e Data Disc. devem ser Preenchidos"
	Help(" ",1,"TECA440",,I18N(cMensagem,{AllTrim(RetTitle(STR0001))}),1,0)	//"Disciplina" 
	At440VldMov()	
Else
	BeginSql alias cAlias  		     
	    SELECT COUNT(TIT.TIT_CODTIQ) QTD, TIT.TIT_CODTIQ, TIT.TIT_CODTEC, TIQ.TIQ_DESCR
		FROM %table:TIT% TIT 
		INNER JOIN %table:TIQ% TIQ
		ON (TIQ.TIQ_FILIAL = %xfilial:TIT% AND TIT.TIT_CODTIQ = TIQ.TIQ_CODIGO)
		WHERE TIT.TIT_CODTEC = %exp:cFunc% 
		AND TIT.TIT_TIPO = '1'
		AND TIT.%notDel% 
		AND TIQ.%notDel% 
		GROUP BY TIT.TIT_CODTIQ, TIT.TIT_CODTEC, TIQ.TIQ_DESCR		
	EndSql
		
	DbSelectArea(cAlias)
			
	While (cAlias)->( !Eof() )					
		cDescri += AllTrim(( cAlias )-> TIQ_DESCR) + STR0005 + cValtoChar(( cAlias )-> QTD) + CRLF	// total de 
											
		( cAlias )->(DbSkip())		
	End
			
	(cAlias)->( DbCloseArea() )	
	
	If !Empty(cDescri)
		cMensagem := STR0006+ CRLF + cDescri //"O funcionário possui histórico de:"
	Else
		cMensagem := STR0007 + CRLF //"Não existe Histórico Disciplinar para este Atendente"
	EndIf		

	At440AplDis(cMensagem, cFunc, cCodDis, dData)	
		
	at440SetLoc()

EndIf

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At440AplDis()
Rotina verifica qual a disciplina que deve ser aplicada baseada na parametrização realizada no cadastro de Disciplina


@author arthur.colado
@since 12/02/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At440AplDis(cMensagem, cFunc, cCodDis, dData)

Local cAlias	:= GetNextAlias()
Local cDescri	:= ""

BeginSql alias cAlias  							
	SELECT TIR.TIR_QTD, TIQ2.TIQ_DESCR DSC, TIQ.TIQ_DESCR
	FROM %table:TIR% TIR  
	INNER JOIN %table:TIQ% TIQ
	ON (TIQ.TIQ_FILIAL = %xfilial:TIQ% AND TIQ.TIQ_CODIGO = TIR.TIR_SUGEST)
	INNER JOIN %table:TIQ% TIQ2
	ON (TIR.TIR_FILIAL = %xfilial:TIR% AND TIR.TIR_CODTIQ = TIQ2.TIQ_CODIGO)
	WHERE TIR.TIR_CODTIQ = %exp:cCodDis% 
	AND TIR.TIR_SUGERI = "1"
	AND TIR.%notDel% 
	AND TIQ.%notDel%			
EndSql
	
DbSelectArea(cAlias)
		
While (cAlias)->( !Eof() )	
	cDescri += AllTrim(STR0008 + cValtoChar(( cAlias )-> TIR_QTD) + STR0009 + ( cAlias )-> DSC + STR0010 + ( cAlias )-> TIQ_DESCR) + CRLF		//"Para "  " disciplinas do tipo "   " sugere-se aplicar " 
		
	( cAlias )->(DbSkip())		
End

(cAlias)->( DbCloseArea() )	

If !Empty(cDescri)
	cMensagem += + CRLF + cDescri + CRLF		
	
EndIf

At440SugDis(cMensagem, cFunc, cCodDis, dData) 

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At440SugDis()
Rotina verifica qual seria a proxima disciplina a aplicar ao funcionário baseado no histórico e disciplina selecionada

@author arthur.colado
@since 12/02/2014
@version 1.0/*/
//------------------------------------------------------------------------------

Function At440SugDis(cMensagem, cFunc, cCodDis, dData)

Local cAlias	:= GetNextAlias()
Local cAlias2	:= GetNextAlias()
Local cCodigo	:= ""
Local cTotal	:= ""
Local nConvert	:= 0
Local cDescri	:= ""
Local oModel	:= FWModelActive()

BeginSql alias cAlias 
	SELECT COUNT(TIT.TIT_CODTIQ) QTD, TIT.TIT_CODTIQ
	FROM %table:TIT% TIT 
	INNER JOIN %table:TIQ% TIQ
	ON (TIQ.TIQ_FILIAL = %xfilial:TIT% AND TIT.TIT_CODTIQ = TIQ.TIQ_CODIGO)
	WHERE TIT.TIT_CODTEC = %exp:cFunc% 
	AND TIT.TIT_CODTIQ = %exp:cCodDis% 
	AND TIT.TIT_TIPO = '1'
	AND TIT.%notDel% 
	AND TIQ.%notDel% 
	GROUP BY TIT.TIT_CODTIQ, TIT.TIT_CODTEC, TIQ.TIQ_DESCR			
EndSql
	
DbSelectArea(cAlias)
		
While (cAlias)->( !Eof() )					
	cTotal := cValToChar(( cAlias )-> QTD)
	cCodigo:= ( cAlias )-> TIT_CODTIQ
								
	( cAlias )->(DbSkip())		
End
	(cAlias)->( DbCloseArea() )	
		
If Empty(cTotal)
	cTotal := "1"
	cCodigo := cCodDis
EndIf
		
nConvert := Val(cTotal) + 1
		
BeginSql alias cAlias2 //valida baseado no histórico consultado acima qual a disciplina deve aplicada  							
	SELECT TIQ.TIQ_DESCR,TIR.TIR_PONTO, TIR.TIR_PPERDA  
	FROM %table:TIR% TIR  
	INNER JOIN %table:TIQ% TIQ
	ON (TIQ.TIQ_FILIAL = %xfilial:TIQ% AND TIQ.TIQ_CODIGO = TIR.TIR_SUGEST)
	WHERE TIR.TIR_CODTIQ = %Exp:cCodigo%
	AND TIR.TIR_QTD =  %Exp:nConvert%
	AND TIR.%notDel% 
	AND TIQ.%notDel%
EndSql
		
DbSelectArea(cAlias2)
	
While (cAlias2)->( !Eof() )	
	cDescri := ( cAlias2 )-> TIQ_DESCR
	
	oModel:SetValue("TIT","TIT_PONTOS", ( cAlias2 )-> TIR_PONTO)
	oModel:SetValue("TIT","TIT_PLR", ( cAlias2 )-> TIR_PPERDA)
			
	( cAlias2 )->(DbSkip())				
End


(cAlias2)->( DbCloseArea() )	
		
If !Empty(cDescri)
	cMensagem += STR0011 + cDescri + CRLF //"Para a Disciplina Selecionada está parametrizado a aplicação de"
Else
	cMensagem += STR0012 + CRLF//"Não existe critério parametrizado para a disciplia selecionada"
EndIf
	
At440RhPrazos(cFunc, cMensagem, cCodDis, dData )			

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At440RhPrazos()
Rotina valida os prazos do funcionários como os períodos de experiencia, demitido e em dia de trabalho

@author arthur.colado
@since 12/02/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At440RhPrazos(cFunc, cMensagem, cCodDis, dData, lTrava)

Local cAlias	:= GetNextAlias()
Local dDiscipl	:= dData
Local lFlag		:= .T.
Local dDemissao	
Local dExper1
Local dExper2
Local cSeq		:= ""
Local lDiaTra	:= .T.
Local cTurno    := ''

BeginSql alias cAlias 
	COLUMN RA_DEMISSA AS DATE
	COLUMN RA_VCTOEXP AS DATE
	COLUMN RA_VCTEXP2 AS DATE
			 							
	SELECT SRA.RA_DEMISSA,SRA.RA_VCTOEXP, SRA.RA_VCTEXP2, SRA.RA_TNOTRAB, RA_SEQTURN  
	FROM %table:AA1% AA1
	INNER JOIN %table:SRA% SRA
	ON (AA1.AA1_FILIAL = %xfilial:AA1% AND AA1.AA1_CDFUNC = SRA.RA_MAT)
	WHERE AA1.AA1_CODTEC = %exp:cFunc%
	AND AA1.%notDel% 
	AND SRA.%notDel% 		
	EndSql
	
DbSelectArea(cAlias)
		
While (cAlias)->( !Eof() )					
	dDemissao := ( cAlias )-> RA_DEMISSA
	dExper1	:= ( cAlias )-> RA_VCTOEXP
	dExper2	:= ( cAlias )-> RA_VCTEXP2
	cTurno := ( cAlias )-> RA_TNOTRAB
	cSeq := ( CAlias )-> RA_SEQTURN
	( cAlias )->(DbSkip())		
End
		
(cAlias)->( DbCloseArea() )			
	
If !Empty(dDemissao)
	cMensagem := STR0013 + DToC(dDemissao) + CRLF + CRLF + cMensagem	//"O funcionário foi demitido em"
	lFlag := .F.
							
ElseIf !Empty(dExper1) .OR. !Empty(dExper2)
			
	If dDiscipl <= dExper1
		cMensagem := STR0014 +  DToC(dExper1) + CRLF + CRLF + cMensagem	//"O funcionário está em Período da Primeira Experiencia "
							
	ElseIf dDiscipl <= dExper2
		cMensagem := STR0015 + DToC(dExper2)+ CRLF + CRLF + cMensagem	//"O funcionário está em Período da Segunda Experiencia"	
	
	EndIf	
				
Else
	cMensagem := STR0016 + CRLF + CRLF + cMensagem 	// "Funcionário está ativo e não consta período de Experiência"
				
EndIf
			
lDiaTra := TxDiaTrab(dDiscipl, cTurno, cSeq, cFunc)	
		
If lDiaTra

	If lFlag
		cMensagem := STR0017 + CRLF + CRLF + cMensagem	 //"Funcionário está em dia de Trabalho para a Data informada "
	
	EndIf
Else
	cMensagem := STR0018 + CRLF + CRLF + cMensagem 	//"Funcionário não está em dia de Trabalho para a Data informada "
	
EndIf
		
At440Processo(cFunc, cMensagem, cCodDis, dData)

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At440Processo()
Rotina verifica se funcionários possui investigação com processo jurídico vinculado

@author arthur.colado
@since 12/02/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At440Processo(cFunc, cMensagem, cCodDis, dData)

Local cAlias	:= GetNextAlias()
Local cDescri	:= ""

BeginSql alias cAlias 			
	SELECT TIU.TIU_DESCRI
	FROM %table:TIT% TIT
	INNER JOIN %table:TIU% TIU
	ON (TIU.TIU_FILIAL = %xfilial:TIT% AND TIT.TIT_CODIGO = TIU.TIU_CODTIT)
	Where TIT.TIT_CODTEC =  %exp:cFunc%
	AND TIU.TIU_RELACI = '4'
	AND TIT.%notDel% 
	AND TIU.%notDel% 
EndSql
	
DbSelectArea(cAlias)
		
While (cAlias)->( !Eof() )					
	cDescri := ( cAlias )-> TIU_DESCRI
									
	( cAlias )->(DbSkip())		
End
		
(cAlias)->( DbCloseArea() )			
	
If !Empty(cDescri)
	cMensagem := CRLF + STR0019 + cDescri + CRLF + CRLF + cMensagem  	// "O funcionário possui Processo Jurídico Aberto: "
								
Else
	cMensagem := CRLF + STR0020 + CRLF + CRLF + cMensagem    //"Não Consta processo Jurídico Aberto "	
			
EndIf	
		
Aviso(STR0021 , cMensagem,{STR0022},3)		//"Atenção"  "OK"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         

Return .T.

//-----------------------------------------------------------------------------
/*/{Protheus.doc} AT440Falta
Atribuição de falta baseado nos parametros código do atendente, data, quantidade de dias

@param   	AT440Falta	
@owner   	arthur.colado
@author 	arthur.colado
@version 	V119
@since   	09/10/2013 
/*/
//-----------------------------------------------------------------------------

Function AT440Falta()

Local cAlias	:= GetNextAlias()
Local aArea		:= GetArea()
Local cFunc		:= FwFldGet("TIT_CODTEC")
Local dDtIni	:= FwFldGet("TIT_DATA")
Local nDias		:= FwFldGet("TIT_QTDDIA")
Local nConta	:= 1
Local dDtFim	:= CToD("")
Local cQryABB   := ""
Local aQry540   := {}
Local cAliasABB := ""	
Local lConfirm  := .F.
Local cAlerta	:= ""
Local aAgendas	:= {}

If !Empty(cFunc) .AND. !Empty(dDtIni) .AND. !Empty(nDias)

	BeginSql alias cAlias 					
		SELECT ABB.ABB_CODTEC, ABB.ABB_DTINI, ABB.ABB_DTFIM
		FROM %table:ABB% ABB
		Where ABB.ABB_CODTEC =  %exp:cFunc%
		AND ABB.ABB_DTINI >= %exp:dDtIni%
		AND ABB.%notDel% 
		GROUP BY ABB.ABB_DTINI, ABB.ABB_DTFIM, ABB.ABB_CODTEC 
	EndSql
	
	DbSelectArea(cAlias)
	
	While ( cAlias )->( !Eof() )				
		
		If nConta <= nDias	
			dDtFim := ( cAlias )-> ABB_DTFIM
			
			nConta := nConta + 1
		EndIf
					
		( cAlias )->(DbSkip())		
	End
	
	(cAlias)->( DbCloseArea() )
	
	If Empty(dDtFim)
		cAlerta := STR0023 	//"Funcionário não tem Agenda para atender a Punição de Afastamento no período desejado"
	Else
		dDtFim := SToD(dDtFim)
		aQry540 := AT540ABBQry( cFunc, "", dDtIni, dDtFim, Nil , Nil, "", .T., ""  )
						
		If Len(aQry540) > 0
			cQryABB := aQry540[1]
			cQryABB += " AND ABB.ABB_ATIVO = '1'"
			cQryABB += " ORDER BY ABB_DTINI, ABB_HRINI"

			cAliasABB := GetNextAlias()

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryABB),cAliasABB)
							
			AT550StAls(cAliasABB)//Add Alias para o model
			While (cAliasABB)->(!Eof())

				AAdd( aAgendas, {(cAliasABB)->ABB_CODTEC										,;
			   					SubStr( (cAliasABB)->ABB_IDCFAL , 1, TAMSX3( 'AAH_CONTRT' )[1]) ,;
			   					(cAliasABB)->ABB_CODIGO  				  						,;
			   					sTod((cAliasABB)->ABB_DTINI)									,;
			   					(cAliasABB)->ABB_HRINI											,;
			   					sTod((cAliasABB)->ABB_DTFIM)									,;
			   					(cAliasABB)->ABB_HRFIM											})

				(cAliasABB)->(DbSkip())
			EndDo
			If !Empty(aAgendas)
				(cAliasABB)->(DbGoTop())
				lConfirm := ( AT550ExecView( cAliasABB, MODEL_OPERATION_INSERT, aAgendas ) == 0 )
			Endif

			If lConfirm
				cAlerta := STR0024 + DToC(dDtIni)+ STR0025 + DToC(dDtFim)	//"Afastamento Aplicado no Período Desejado de: "  " Até: "
			Else
				cAlerta := STR0026 	//"Não Foi Aplicado o Afastamento"
			EndIf						
		EndIf
	EndIf
	RestArea(aArea)		
Else
	cAlerta := STR0027 	//"Preencher os campos Obrigatórios"
EndIf
	
	Help(" ",1,"TECA440",,I18N(cAlerta,{AllTrim(RetTitle(STR0028))}),1,0)	//"Disciplina"

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} At440VldMov()
Rotina apaga todos os dados da consulta padrão caso for alterado o critério de pesquisa do campo TIT_TIPO


@author arthur.colado
@since 12/02/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function At440VldMov()
Local oModel	:= FWModelActive()

If 	FwFldGet("TIT_TIPO") == "1" .Or. FwFldGet("TIT_TIPO") == "2"
	
	//Limpa o codigo quando for alterado
	If !Empty(FwFldGet("TIT_CODTIQ"))
		oModel:LoadValue("TIT","TIT_CODTIQ", "")
		oModel:LoadValue("TIT","TIT_DISCIP", "")
	EndIf
	
	If !Empty(FwFldGet("TIT_CODTIS"))	
		oModel:LoadValue("TIT","TIT_CODTIS", "")
		oModel:LoadValue("TIT","TIT_MOTIVO", "")
	EndIf
	
EndIf

If Empty(FwFldGet("TIT_CODTIS")) .OR. Empty(FwFldGet("TIT_DATA"))
	oModel:LoadValue("TIT","TIT_CODTEC", "")
	
EndIf

Return .T.

//------------------------------------------------------------------------------
/*/{Protheus.doc} AT440Form()
Rotina cria o formulário da Disciplina aplicada que será impresso para o Atendente assinar

@author Luiz.Jesus
@since 12/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------

Function AT440Form()

Local oWF                                                    //Objeto TWFProcess
Local nVTotIt   := 0                                         //Valor total dos itens do produto
Local nX 		:= 0                                         //Incremento utilizado no laco For
Local cArqHtm   := ""                                        //Arquivo Html
Local cPathWF   := "\samples\documents\disciplina\"  
Local cPath 	:= "\samples\documents\disciplina\disciplinas\" 
Local cFileHTML := FwFldGet("TIT_CODIGO") + ".htm"
Local cAfasta	:= FwFldGet("TIT_AFASTA")
Local lRet		:= .T.
Local lVis		:= .F.
Local nStatus	:= 0
Local cArq		:= ""
Local nTamArq	:= 1

MakeDir(cPath)

#IFDEF SPANISH
      cArqHtm := "WFLPrdSpa.htm"
#ELSE
      #IFDEF ENGLISH
            cArqHtm := "WFLPrdEng.htm"
      #ELSE
            cArqHtm := STR0030	//"modelo.html"
      #ENDIF
#ENDIF

//Valida a existência do modelo do fromulário da disciplina.
If !File( cPathWF + cArqHtm )
	
	While nTamArq < Len(cPathWF+cArqHtm)
		cArq += SubStr( cPathWF+cArqHtm , nTamArq , 49 ) + " "
 		nTamArq += 49
	End
	
	Help( " " , 1 , "TECA440ARQ" , , Alltrim(cArq) + " " + STR0039 + STR0040 , 1 , 0 ) //cPathWF + cArqHtm + não encontrado no servidor. O arquivo é necessário para geração do formulário da disciplina.
	lRet := .F.
EndIf

If lRet
	For nX := 1 To 1
		        
		//Zera o total dos itens
		nVTotIt := 0
		// Inicializa a classe TWFProcess 
		oWF := TWFHTML():New( cPathWF+cArqHtm )  		
		
		// Preenche as variaveis no HTML do corpo do formulário
		
		oWF:ValByName("dData", FwFldGet("TIT_DATA"))                                                                                           
		oWF:ValByName("cNome", FwFldGet("TIT_NOMTEC"))  
		oWF:ValByName("cMat", FwFldGet("TIT_CODTEC"))                                                                               
		oWF:ValByName("cPosto", FwFldGet("TIT_CODABS") + " - " + FwFldGet("TIT_LOCAL"))                                                                                        
		oWF:ValByName("cArea", FwFldGet("TIT_REGIAO"))               
		oWF:ValByName("cTurno", FwFldGet("TIT_TURNO")) 
		 
		If  cAfasta == "1" 
		   
		            	oWF:ValByName("cRef", FwFldGet("TIT_DISCIP") + ": " + cValToChar(FwFldGet("TIT_QTDDIA")) + STR0032)      //"PUNIÇÃO DISCIPLINAR FORMAL: "     	" Dia(s)"
			            
		Else
			oWF:ValByName("cRef", FwFldGet("TIT_DISCIP"))  	//"PUNIÇÃO DISCIPLINAR FORMAL: "
			 
		EndIf                            
		
		oWF:ValByName("cTiqText1", FwFldGet("TIT_TEXTO1"))                                           
		oWF:ValByName("cTitDsc", FwFldGet("TIT_MOTIVO") + ": " + FwFldGet("TIT_DESCRI"))                      
		oWF:ValByName("cTiqText2", FwFldGet("TIT_TEXTO2"))                                                 
		
		//salva em diretório local temporário
		oWF:SaveFile( cPath + cFileHTML	 )	
					
	Next nX
	
	lVis := MsgNoYes(STR0034," MsgNoYes ")		//"Deseja Imprimir a Disciplina Agora?"
  
	If lVis
		AT440VisForm()	      
	EndIf
EndIf

Return(lRet)
//------------------------------------------------------------------------------
/*/{Protheus.doc} AT440VisForm()
Rotina visualiza o formulário criado da Disciplina aplicada que será impresso para o Atendente assinar

@author Luiz.Jesus
@since 12/03/2014
@version 1.0
/*/
//------------------------------------------------------------------------------
Function AT440VisForm()

Local oDlg
Local aSize 	:=    {}
Local cPathLoc 	:= GetTempPath(.F.)
Local cFile		:=  FwFldGet("TIT_CODIGO")+".htm" 
Local cPathWf 	:= "\samples\documents\disciplina\disciplinas\"+ cFile 
Local cLogo		:= "\samples\documents\disciplina\disciplinas\logo.jpg"
Local oTIBrowser := Nil

CPYS2T(cPathWf, cPathLoc)
CPYS2T(cLogo, cPathLoc)

aSize := FWGetDialogSize( oMainWnd )

DEFINE MSDIALOG oDlg TITLE STR0036 FROM aSize[1], aSize[2] TO aSize[3], aSize[4] PIXEL 	//"Punição"

oTIBrowser := TIBrowser():New(00,00,00, 00,cPathLoc+cFile,oDlg )
oTIBrowser:Align    := CONTROL_ALIGN_ALLCLIENT
oTIBrowser:GoHome()


ACTIVATE DIALOG oDlg CENTERED 
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} AT440GRV
Grava e Cria o Formulário Disciplinar

@author arthur.colado
@since 04/02/2014
@version 1.0
/*/
//-------------------------------------------------------------------
Function AT440GRV(oModel)
Local lRet 	:= .T.

MsgRun(STR0037 ,STR0038  ,{ || lRet := AT440Form() })		//"Criando Formulário...." ,"Aguarde"

If lRet
	FwFormCommit(oModel)
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At440GsDc
Gestão de escalas.

@author Kaique Schiller
@since 28/07/2017
/*/
//-------------------------------------------------------------------
Function At440GsDc(nOpcx)
Local cTitulo 	:=  ""
Local nOper 	:= 0
Local nConfirm	:= 0

Begin Transaction

	If nOpcx == 3
		cTitulo 	:= "Incluir"
		nOper		:= MODEL_OPERATION_INSERT
	Elseif nOpcx == 4
		cTitulo 	:= "Alterar"
		nOper		:= MODEL_OPERATION_UPDATE
	Endif

	nConfirm := FWExecView(cTitulo,"VIEWDEF.TECA440",nOper,,{|| .T.})
	
	If nConfirm <> 0
		DisarmTransaction()
	Endif

End Transaction

Return .T.


/*/{Protheus.doc} At440VlRes
Validação do campo TIT_CODRES
@author Rodolfo Novaes
@since 06/02/2018
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Function At440VlRes()
Local oModel	:= FWModelActive()
Local lRet		:= .F.

If Posicione('AA1',1,xFilial('AA1') + oModel:GetValue('TIT','TIT_CODRES'),'AA1_SUPERV') == '1'
	lRet	:= .T.
Else
	oModel:SetErrorMessage( oModel:GetId() ,"TIT_CODRES" ,"TIT", "TIT_CODRES" ,'',; 
			STR0041, STR0042 ) //'O atendente informado não é supervisor!' - 'Informe um atendente supervisor!'	
EndIf
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} at440SetLoc()
Função para setar o valor do local de atendimento de acordo com o funcionário e data


@author Matheus Lando Raimundo
@since 21/06/2018
@version 1.0
/*/
//------------------------------------------------------------------------------
Function at440SetLoc()
Local cAliasTmp	:= GetNextAlias()
Local oModel 	:= FwModelActive()
Local oTITMaster := oModel:GetModel('TIT')
Local cFunc 	:= oTITMaster:GetValue("TIT_CODTEC")
Local dData 	:= oTITMaster:GetValue("TIT_DATA")
Local cLocais 	:= ""
Local nRecord	:= 0
Local oView := FwViewActive()
Local nI 	:= 1
Local aLocais := {}

BeginSql alias cAliasTmp 					
	SELECT DISTINCT ABB.ABB_LOCAL  	FROM %table:ABB% ABB				
		WHERE ABB_FILIAL = %xfilial:ABB%
		AND ABB.ABB_CODTEC =  %exp:cFunc%
		AND ABB.ABB_DTINI = %exp:dData%
		AND ABB.%notDel% 		
EndSql
	
oTITMaster:ClearField('TIT_CODABS')

( cAliasTmp )->( DBGoTop() )
While (cAliasTmp)->( !Eof() )		
	Aadd(aLocais, (cAliasTmp)->ABB_LOCAL)	
	(cAliasTmp)->(DbSkip())	
EndDo

If Len(aLocais) > 1
	For nI := 1 To Len(aLocais)
		cLocais := cLocais + aLocais[nI] + ' - ' + Posicione('ABS',1,xFilial('ABS') + aLocais[nI],'ABS_DESCRI') + CRLF  
	Next nI
	AtShowLog( STR0043 + CRLF + CRLF + cLocais + CRLF + STR0044	, STR0045)		
ElseIf Len(aLocais) == 1 		
	oTITMaster:SetValue('TIT_CODABS',aLocais[1])			
EndIf
(cAliasTmp)->( DbCloseArea() )		
oView:Refresh()

Return Nil	


/*/{Protheus.doc} A440VLDPOS
 Pós validação do modelo
@author TOTVS
@since 13/06/2019
@version 1.0
@return lRet
@param oModel, object, descricao
@type function
/*/
Function A440VLDPOS(oModel)

Local cAlias	:= GetNextAlias()
Local lFlag		:= .T.
Local dDemissao	
Local dExper1
Local dExper2
Local lRet		:= .T.
Local cSeq		:= ""
Local lDiaTra	:= .T.
Local cTurno    := ''
Local oModel 	:= FwModelActive()
Local oTITMaster := oModel:GetModel('TIT')
Local cFunc 	:= oTITMaster:GetValue("TIT_CODTEC")
Local dData 	:= oTITMaster:GetValue("TIT_DATA")

BeginSql alias cAlias 
	COLUMN RA_DEMISSA AS DATE
	COLUMN RA_VCTOEXP AS DATE
	COLUMN RA_VCTEXP2 AS DATE
			 							
	SELECT SRA.RA_DEMISSA,SRA.RA_VCTOEXP, SRA.RA_VCTEXP2, SRA.RA_TNOTRAB, RA_SEQTURN  
	FROM %table:AA1% AA1
	INNER JOIN %table:SRA% SRA
	ON (AA1.AA1_FILIAL = %xfilial:AA1% AND AA1.AA1_CDFUNC = SRA.RA_MAT)
	WHERE AA1.AA1_CODTEC = %exp:cFunc%
	AND AA1.%notDel% 
	AND SRA.%notDel% 		
	EndSql
	
DbSelectArea(cAlias)
		
While (cAlias)->( !Eof() )					
	dDemissao := ( cAlias )-> RA_DEMISSA
	dExper1	:= ( cAlias )-> RA_VCTOEXP
	dExper2	:= ( cAlias )-> RA_VCTEXP2
	cTurno := ( cAlias )-> RA_TNOTRAB
	cSeq := ( CAlias )-> RA_SEQTURN
	( cAlias )->(DbSkip())		
End
		
(cAlias)->( DbCloseArea() )			

			
lDiaTra := TxDiaTrab(dData, cTurno, cSeq, cFunc)	
		
If !lDiaTra

	Help(" ",1,"TECA440",,"Não é permitido aplicar disciplina para funcionário ausente.",1,0)
	lRet := .F.
	
EndIf

Return lRet