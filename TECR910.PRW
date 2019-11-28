#INCLUDE "PROTHEUS.CH"
#INCLUDE "REPORT.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TECR910.CH"

//Status do orçamento de serviços
#DEFINE DEF_TFJ_ATIVO     "1"			//TFJ_STATUS Ativo
#DEFINE DEF_TFJ_EMREVISAO "2"			//TFJ_STATUS Em Revisão
#DEFINE DEF_TFJ_REVISADO  "3"			//TFJ_STATUS Revisado
#DEFINE DEF_TFJ_AGDAPROVA "4"			//TFJ_STATUS Aguardando Aprovação
#DEFINE DEF_TFJ_ENCERRADO "5"			//TFJ_STATUS Encerrado
#DEFINE DEF_TFJ_CANCELADO "6"			//TFJ_STATUS Cancelado


Static _CampoMod := ""
Static aCTT := {}

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} TECR910
Relatorio de Compação de Contratos - GESP
@author Serviços
@since 27/03/2019
@version P1217
@return oReport - Objeto report
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Function TECR910()
	Local oReport		:= NIL //Objeto report
	Local cPerg  		:= "TECR910"
	Local aAreaTFJ		:= {} //WorkArea TFQ
	Local cAlias 		:= ""
	Local oTempTable 	:= NIL
	Local aCpos 		:= {} //Campos do relatório

	If TRepInUse()  .AND. 	Pergunte(cPerg, .T.) 

		cAlias	:= GetNextAlias()	

		oTempTable := CreateStruct(cAlias, @aCpos)
		aCTT := {}

		aAreaTFJ := TFJ->(GetArea())
		oReport := ReportDef(cAlias, aCpos) 
		oReport:PrintDialog()	
		RestArea(aAreaTFJ)

		If Valtype(oTempTable) <> NIL
			oTempTable:Delete() 
			FreeObj(oTempTable)
		EndIf
	EndIf

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ReportDef

Relatorio de Compação de Contratos - GESP
@author Serviços
@since 27/03/2019
@version P1217
@return oReport - Objeto report
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function ReportDef(cAlias, aFields)
	Local cPerg  	:= "TECR910"

	Local oReport		:= Nil							//Objeto para armazenar a seção pai
	Local oSection1		:= Nil							//Objeto para armazenar a seção 1 do objeto pai
	Local oSection2		:= Nil							//Objeto para armazenar a seção 2 do objeto pai
	Local oSection3		:= Nil							//Objeto para armazenar a seção 3 do objeto pai
	Local oSection3		:= Nil							//Objeto para armazenar a seção 3 do objeto pai
	Local oSection4		:= Nil							//Objeto para armazenar a seção 4 do objeto pai
	Local oSection5		:= Nil							//Objeto para armazenar a seção 5 do objeto pai
	Local oSection6		:= Nil							//Objeto para armazenar a seção 6 do objeto pai
	Local oSection7		:= Nil							//Objeto para armazenar a seção 7 do objeto pai
	Local oSection8		:= Nil							//Objeto para armazenar a seção 8 do objeto pai
	Local oSection9		:= Nil							//Objeto para armazenar a seção 9 do objeto pai
	Local oSection10	:= Nil							//Objeto para armazenar a seção 10 do objeto pai
	Local oSection11	:= Nil							//Objeto para armazenar a seção 11 do objeto pai
	Local oSection12	:= Nil							//Objeto para armazenar a seção 12 do objeto pai
	Local oSection13	:= Nil							//Objeto para armazenar a seção 13 do objeto pai
	Local oSectionD 	:= NIL								//Objeto para armazenar a seção 14 do objeto pai
	Local oSectionT 	:= NIL								//Objeto para armazenar a seção 15 do objeto pai
	Local nC := 0
	Local cOrcMod		:= IIF( SuperGetMv("MV_ORCPRC",,.F.), "TECA740F", "TECA740")
	Local nSpaceMt		:=  IIF(cOrcMod = "TECA740", 9, 6)
	Local aOperac   := { "", "", STR0020, STR0021, STR0022} //"Adicionado"##"Alterado"##"Excluído"
	Local nTamOper := 10
	/*Local nC := 0
	Local bBlock := {}
	Local cTitle := ""*/
	Local aSections 	:= Array(14, "")
	*/
	//Array de Secoes do relatorio
	aSections[01] := "TFJ"
	aSections[02] := "TFL"
	aSections[03] := "TFF"
	aSections[04] := "TFI"
	aSections[05] := "TWO"
	aSections[06] := "ABP"  
	aSections[07] := "TFG"
	aSections[08] := "TFH" 
	aSections[09] := "TFU"
	aSections[10] := "TGV"
	aSections[11] := "TDS"
	aSections[12] := "TDT"
	aSections[13] := "TEV"  
	aSections[14] := cAlias 

	//Relatório
	DEFINE REPORT oReport NAME cPerg TITLE STR0001 ACTION {|oReport| PrintReport(oReport, cAlias, aSections, aFields, cOrcMod)} //"Comparação de Contratos"

	//Secao 1 - Orçamento
	DEFINE SECTION oSection1 OF oReport TITLE STR0002 TABLES "TFJ" BREAK HEADER //"Orçamento"

	DEFINE CELL NAME "TFJ_CONTRT"		OF oSection1 ALIAS "TFJ" 
	DEFINE CELL NAME "TFJ_CONREV"		OF oSection1 ALIAS "TFJ" 
	DEFINE CELL NAME "TFJ_CONREV"	    OF oSection1 Title "Rev Destino" ALIAS "TFJ"  BLOCK  {|| MV_PAR03  } 
	DEFINE CELL NAME "TFJ_CODIGO"		OF oSection1 ALIAS "TFJ" 
	DEFINE CELL NAME "TFJ_PROPOS"		OF oSection1 ALIAS "TFJ" 
	DEFINE CELL NAME "TFJ_PREVIS"		OF oSection1 ALIAS "TFJ" 
	oSection1:SetNoFilter( "TFJ" ) 

	//Seção 2 - Local
	DEFINE SECTION oSection2 OF oReport TITLE STR0003 TABLES "TFL", "ABS" LEFT MARGIN  3//"Local"

	DEFINE CELL NAME "TFL_LOCAL"		OF oSection2 ALIAS "TFL" 
	DEFINE CELL NAME "TFL_DESLOC"		OF oSection2 ALIAS "TFL" BLOCK {|| ABS->ABS_DESCRI  } 
	DEFINE CELL NAME "TFL_ESTADO"		OF oSection2 ALIAS "TFL" BLOCK {|| ABS->ABS_ESTADO  } 
	DEFINE CELL NAME "TFL_MUNIC"		OF oSection2 ALIAS "TFL" BLOCK {|| ABS->ABS_MUNIC  }  
	DEFINE CELL NAME "TFL_DTINI"		OF oSection2 ALIAS "TFL" 
	DEFINE CELL NAME "TFL_DTFIM"		OF oSection2 ALIAS "TFL"      
	DEFINE CELL NAME "TFL_TOTAL"		OF oSection2 ALIAS "TFL" BLOCK {|| TFL->(TFL_TOTRH+TFL_TOTMI+TFL_TOTMC+TFL_TOTLE)}      
	DEFINE CELL NAME "TFL_ENCE"			OF oSection2 ALIAS "TFL" BLOCK {|| IIF(TFL->TFL_ENCE == "1", "Sim", "Não") }
	oSection2:SetNoFilter( "TFL" ) 
	TRPosition():New(oSection2,"ABS",1,{|| xFilial("ABS")+TFL->TFL_LOCAL })   

	//Secao 3 - RH
	DEFINE SECTION oSection3 OF oReport TITLE STR0004 TABLES "TFF", "SB1", "SRJ", "SQ3","TDW" LEFT MARGIN  6//"Recursos Humanos"

	DEFINE CELL NAME "TFF_ITEM"		OF oSection3 ALIAS "TFF" 
	DEFINE CELL NAME "TFF_PRODUT"	OF oSection3  Title STR0023 ALIAS "TFF" //"Produto RH"
	DEFINE CELL NAME "TFF_DESCRI"   OF oSection3 ALIAS "TFF" BLOCK {|| SB1->B1_DESC  } 
	DEFINE CELL NAME "TFF_PERINI"	OF oSection3 ALIAS "TFF"   
	DEFINE CELL NAME "TFF_PERFIM"	OF oSection3 ALIAS "TFF"
	DEFINE CELL NAME "TFF_FUNCAO"	OF oSection3 ALIAS "TFF"
	DEFINE CELL NAME "TFF_DFUNC"	OF oSection3 ALIAS "TFF" BLOCK {|| SRJ->RJ_DESC  } 
	//DEFINE CELL NAME "TFF_TURNO"	OF oSection3 ALIAS "TFF"
	DEFINE CELL NAME "TFF_CARGO"	OF oSection3 ALIAS "TFF"
	DEFINE CELL NAME "TFF_DCARGO"	OF oSection3 ALIAS "TFF" BLOCK {|| SQ3->Q3_DESCSUM  } 
	DEFINE CELL NAME "TFF_ESCALA"	OF oSection3 ALIAS "TFF"
	DEFINE CELL NAME "TFF_NOMESC"	OF oSection3 ALIAS "TFF" BLOCK {|| TDW->TDW_DESC  } 
	oSection3:SetNoFilter( "TFF" )
	TRPosition():New(oSection3,"SB1", 1,{|| xFilial("SB1")+TFF->TFF_PRODUT})  
	TRPosition():New(oSection3,"SRJ", 1,{|| XFILIAL('SRJ')+TFF->TFF_FUNCAO}) 
	TRPosition():New(oSection3,'SQ3',1, {|| XFILIAL('SQ3')+TFF->TFF_CARGO}) 
	TRPosition():New(oSection3,'TDW',1, {|| XFILIAL('TDW')+TFF->TFF_ESCALA}) 

	//Seção 4 - 
	DEFINE SECTION oSection4 OF oReport TITLE STR0005 TABLES "TFI", "SB1" LEFT MARGIN  6 //"Locação de Equipamentos"

	DEFINE CELL NAME "TFI_ITEM"		OF oSection4 ALIAS "TFI" 
	DEFINE CELL NAME "TFI_PRODUT"	OF oSection4 Title STR0024 ALIAS "TFI"  //"Prod Loc Equip"
	DEFINE CELL NAME "TFI_DESCRI"   OF oSection4 ALIAS "TFL" BLOCK {|| SB1->B1_DESC  } 
	DEFINE CELL NAME "TFI_PERINI"	OF oSection4 ALIAS "TFI"   
	DEFINE CELL NAME "TFI_PERFIM"	OF oSection4 ALIAS "TFI   
	DEFINE CELL NAME "TFI_TOTAL"	OF oSection4 ALIAS "TFI"  
	oSection4:SetNoFilter( "TFI" )
	TRPosition():New(oSection4,"SB1", 1,{|| xFilial("SB1")+TFI->TFI_PRODUT})  
	//Seção 5 - 

	DEFINE SECTION oSection5 OF oReport TITLE STR0006 TABLES "TWO" LEFT MARGIN  6 //"Facilitador"

	DEFINE CELL NAME "TWO_CODFAC"	OF oSection5 ALIAS "TWO" 
	DEFINE CELL NAME "TWO_DESCRI"	OF oSection5 ALIAS "TWO" 
	DEFINE CELL NAME "TWO_QUANT"	OF oSection5 ALIAS "TWO" 
	DEFINE CELL NAME "TWO_CODORC"	OF oSection5 ALIAS "TWO" 
	oSection5:SetNoFilter( "TWO" )

	//FILHOS TFF - TECA740
	//Seção 6 - 
	DEFINE SECTION oSection6 OF oReport TITLE STR0007 TABLES "ABP", "SX5", "SRV" LEFT MARGIN  6 //"Benefícios do Contrato"

	DEFINE CELL NAME "ABP_ITEM"		OF oSection6 ALIAS "ABP" 
	DEFINE CELL NAME "ABP_BENEFI"	OF oSection6 ALIAS "ABP" 
	DEFINE CELL NAME "ABP_DESCRI"	OF oSection6 ALIAS "ABP" BLOCK {|| X5DESCRI() } 
	DEFINE CELL NAME "ABP_VERBA"	OF oSection6 ALIAS "ABP" 		
	DEFINE CELL NAME "ABP_DSVERB"	OF oSection6 ALIAS "ABP" BLOCK {|| SRV->RV_DESC } 	
	DEFINE CELL NAME "ABP_VALOR"	OF oSection6 ALIAS "ABP" 	 
	oSection6:SetNoFilter( "ABP" )
	TRPosition():New(oSection6,"SX5", 1,{|| XFILIAL('SX5')+'AZ'+ABP->ABP_BENEFI}) 	
	TRPosition():New(oSection6,"SRV", 1,{|| XFILIAL("SRV")+ABP->ABP_VERBA}) 

	//Seção7  - 
	DEFINE SECTION oSection7 OF oReport TITLE STR0008 TABLES "TFG", "SB1" LEFT MARGIN  nSpaceMt //"Materiais de Implantação"

	DEFINE CELL NAME "TFG_ITEM"		OF oSection7 ALIAS "TFG" 
	DEFINE CELL NAME "TFG_PRODUT"	OF oSection7 Title STR0025 ALIAS "TFG"  //"Prod Mat Impl"
	DEFINE CELL NAME "TFG_DESCRI"   OF oSection7 ALIAS "TFG" BLOCK {|| SB1->B1_DESC  } 
	DEFINE CELL NAME "TFG_PERINI"	OF oSection7 ALIAS "TFG"   
	DEFINE CELL NAME "TFG_PERFIM"	OF oSection7 ALIAS "TFG"  
	DEFINE CELL NAME "TFG_TOTGER"	OF oSection7 ALIAS "TFG"  BLOCK { || TFG->( TFG_QTDVEN * TFG_PRCVEN ) }
	oSection7:SetNoFilter( "TFG" )
	TRPosition():New(oSection7,"SB1", 1,{|| xFilial("SB1")+TFG->TFG_PRODUT})  		

	//Seção8  - 
	DEFINE SECTION oSection8 OF oReport TITLE STR0009 TABLES "TFH", "SB1" LEFT MARGIN  nSpaceMt  //"Materiais de Consumo"

	DEFINE CELL NAME "TFH_ITEM"		OF oSection8 ALIAS "TFH" 
	DEFINE CELL NAME "TFH_PRODUT"	OF oSection8 Title STR0025  ALIAS "TFH"  //"Prod Mat Cons"
	DEFINE CELL NAME "TFH_DESCRI"   OF oSection8 ALIAS "TFH" BLOCK {|| SB1->B1_DESC  } 
	DEFINE CELL NAME "TFH_PERINI"	OF oSection8 ALIAS "TFH"   
	DEFINE CELL NAME "TFH_PERFIM"	OF oSection8 ALIAS "TFH"  
	DEFINE CELL NAME "TFH_TOTGER"	OF oSection8 ALIAS "TFH" BLOCK { || TFH->( TFH_QTDVEN * TFH_PRCVEN ) }
	oSection8:SetNoFilter( "TFH" )
	TRPosition():New(oSection8,"SB1", 1,{|| xFilial("SB1")+TFH->TFH_PRODUT}) 

	//Seção 9 - 
	DEFINE SECTION oSection9 OF oReport TITLE STR0010 TABLES "TFU", "ABN"  LEFT MARGIN  9 //"Hora-Extra"

	DEFINE CELL NAME "TFU_CODABN"		OF oSection9 ALIAS "TFU" 
	DEFINE CELL NAME "TFU_ABNDES"		OF oSection9 ALIAS "TFU" BLOCK {|| ABN->ABN_DESC } 
	DEFINE CELL NAME "TFU_VALOR"	OF oSection9 ALIAS "TFU" 
	oSection9:SetNoFilter("TFU"  )
	TRPosition():New(oSection9,"ABN", 1,{|| XFILIAL('ABN')+TFU->TFU_CODABN}) 

	//Seção 10  - 
	DEFINE SECTION oSection10 OF oReport TITLE STR0011 TABLES "TGV", "RA1" LEFT MARGIN  9 //"Curso"

	DEFINE CELL NAME "TGV_CURSO"		OF oSection10 ALIAS "TGV" 		
	DEFINE CELL NAME "TGV_DCURSO"		OF oSection10 ALIAS "TGV" BLOCK { || RA1->RA1_DESC}	 
	oSection10:SetNoFilter( "TGV" )
	TRPosition():New(oSection10,"RA1", 1,{|| XFILIAL('RA1')+TGV->TGV_CURSO}) 

	//Seção  - 
	DEFINE SECTION oSection11 OF oReport TITLE STR0012 TABLES "TDS", "TCZ" LEFT MARGIN  9 //"Característica do Local"

	DEFINE CELL NAME "TDS_CODTCZ"		OF oSection11 ALIAS "TDS" 	
	DEFINE CELL NAME "TDS_DSCTCZ"		OF oSection11 ALIAS "TDS" 	BLOCK { || TCZ->TCZ_DESC }				
	oSection11:SetNoFilter( "TDS" )
	TRPosition():New(oSection11,"TCZ", 1,{|| XFILIAL('TCZ')+TDS->TDS_CODTCZ}) 

	//Seção 12  - 
	DEFINE SECTION oSection12 OF oReport TITLE STR0013 TABLES "TDT", "RBG", "RBK", "SX5" LEFT MARGIN  9 //"Habilidades do Posto"

	DEFINE CELL NAME "TDT_CODHAB"		OF oSection12 ALIAS "TDT"
	DEFINE CELL NAME "TDT_DSCHAB"		OF oSection12 ALIAS "TDT"  BLOCK { || RBG->RBG_DESC } 	
	DEFINE CELL NAME "TDT_ESCALA"		OF oSection12 ALIAS "TDT" 	
	DEFINE CELL NAME "TDT_DSCESC"		OF oSection12 ALIAS "TDT"  BLOCK {|| RBK->RBK_DESCRI  }
	DEFINE CELL NAME "TDT_ITESCA"		OF oSection12 ALIAS "TDT"
	DEFINE CELL NAME "TDT_HABX5"		OF oSection12 ALIAS "TDT" 
	DEFINE CELL NAME "TDT_DHABX5"		OF oSection12 ALIAS "TDT" BLOCK {|| X5DESCRI() }									
	oSection12:SetNoFilter(  "TDT")
	TRPosition():New(oSection12,"RBG", 1,{|| XFILIAL('RBG')+TDT->TDT_CODHAB}) 
	TRPosition():New(oSection12,'RBK',1, {|| XFILIAL('RBK')+TDT->TDT_ESCALA}) 
	TRPosition():New(oSection12,'SX5',1, {|| XFILIAL('SX5')+'A4'+TDT->TDT_HABX5})                     

	//Seção 13 - 
	DEFINE SECTION oSection13 OF oReport TITLE STR0014 TABLES "TEV" LEFT MARGIN  9 //"Cobrança Locação"

	DEFINE CELL NAME "TEV_ITEM"		OF oSection13 ALIAS "TEV" 
	DEFINE CELL NAME "TEV_MODCOB"	OF oSection13 ALIAS "TEV" SIZE 20 BLOCK { || RetMobCob(TEV->TEV_MODCOB) } 	
	DEFINE CELL NAME "TEV_UM"		OF oSection13 ALIAS "TEV" 
	DEFINE CELL NAME "TEV_QTDE"		OF oSection13 ALIAS "TEV" 	
	DEFINE CELL NAME "TEV_VLRUNI"	OF oSection13 ALIAS "TEV" 
	DEFINE CELL NAME "TEV_VLTOT"	OF oSection13 ALIAS "TEV" 						
	oSection13:SetNoFilter("TEV"  )



	//Seção 1 - Detalhe
	DEFINE SECTION oSectionD OF oReport TITLE STR0015 TABLES cAlias LEFT MARGIN  12//"Detalhes"
	DEFINE CELL NAME "CAMPO"	  		OF oSectionD ALIAS cAlias TITLE STR0016			SIZE aFields[aScan(aFields, { |c| c[1] == "CAMPO"})][03] //"Campo"
	DEFINE CELL NAME "DESCR_CAMP"	  		OF oSectionD ALIAS cAlias TITLE STR0017		SIZE aFields[aScan(aFields, { |c| c[1] == "DESCR_CAMP"})][03] //"Descrição"	
	DEFINE CELL NAME "VLR_ORIG"	  		OF oSectionD ALIAS cAlias TITLE "Valor Revisão Original"		SIZE aFields[aScan(aFields, { |c| c[1] == "VLR_ORIG"})][03] //"Valor Original"
	DEFINE CELL NAME "VLR_DEST"	  		OF oSectionD ALIAS cAlias TITLE "Valor Revisão Destino"		SIZE aFields[aScan(aFields, { |c| c[1] == "VLR_DEST"})][03] //"Valor Destino"	
	DEFINE CELL NAME "SITUACAO"		OF oSectionD  Title "Situação" ALIAS  cAlias  SIZE nTamOper BLOCK {|| aOperac[Max(Val((cAlias)->ORIGEM),1)]  } 

	//Seção 1 - Detalhe
	/*	DEFINE SECTION oSectionT OF oReport TITLE "Detalhes" TABLES cAlias //"Prestadora do serviço"

	For nC := 1 to Len(aFields)
	//Células Seção 0
	bBlock := &("{|| (cAlias)-> "+ aFields[nC, 01] + "}")
	cTitle := aFields[nC, 01]
	cTitle := IIF(Left(cTitle, 2)="CH", PadR( aFields[nC, 01], Max(aFields[nC, 03], Len(aFields[nC, 01])), "."), aFields[nC, 01])
	DEFINE CELL NAME aFields[nC, 01]	  	OF oSectionT TITLE cTitle 	 SIZE aFields[nC, 03]				BLOCK bBlock

	Next nC 
	DEFINE CELL NAME "SITUACAO"		OF oSectionT ALIAS Title "Situação" ALIAS  cAlias BLOCK {||  aOperac[Max(Val((cAlias)->ORIGEM),1)]  }	*/
Return oReport

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} PrintReport

Função responsavél pela impressão do relatório
@author Serviços
@since 27/03/2019
@version P1217
@return 
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function PrintReport(oReport, cAlias, aSections, aStuct, cOrcMod)
	Local aChaves 		:= {}
	Local aAlias		:= Array(4, "")
	Local oSectionD 	:= oReport:Section(Len(aSections))
	Local cOrigem	    := ""
	Local nNivel :=  0
	Local nPosSeA  := 0
	Local lIniSec := .F.

	LoadTab(cAlias, aSections, aStuct, cOrcMod)

	aChaves := Array(04, "")
	aAlias := Array(4, space(3))
	ApagaFilh(0, @aChaves, @aAlias, aStuct)



	While !(cAlias)->(EOF())
		If aChaves[01]+aAlias[01]+aChaves[02]+aAlias[02]+aChaves[03]+aAlias[03]+aChaves[04]+aAlias[04] <> (cAlias)->(CHV01+ALI01+CHV02+ALI02+CHV03+ALI03+CHV04+ALI04)
			If lIniSec
				oSectionD:Finish()
			EndIf
			ImprimeQuebra(@aChaves, @aAlias, Val((cAlias)->NIVEL), oReport, cAlias, aSections, aStuct)
			oSectionD:Init()
			lIniSec := .T.
		EndIf

		oSectionD:PrintLine() 

		(cAlias)->(DbSkip())
	End

	If lIniSec
		oSectionD:Finish()
	EndIf

Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} LoadTab

Função responsavél pela Carga de Dados do relatório
@author Serviços
@since 27/03/2019
@version P1217
@return
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function LoadTab(cAlias, aSections, aStuct, cOrcMod)
	Local nTamCtt 		:= TFJ->(TamSx3("TFJ_CONTRT")[1])
	Local nTamRev 		:= TFJ->(TamSx3("TFJ_CONREV")[1])
	Local lAtvMdl		:= .F. //Model Ativo
	Local cChave 		:= ""
	Local cDescrP 		:= ""
	Local oModelOri 	:= NIL
	Local oModelDes 	:= NIL 
	Local aRet 			:= {}
	Local aGrids 		:= {}
	Local aDep 			:= {}
	Local aModelos 		:= {} //Arrays dos Modelos
	Local aChaves 		:= {}
	Local nI  			:= 0
	Local nY 			:= 0
	Local nZ 			:= 0
	Local nPosP 		:= 0
	Local nReg			:= 0

	TFJ->(DbSetOrder(5)) //TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV

	If TFJ->(DbSeek(xFilial("TFJ")+PadR(MV_PAR01, nTamCtt)+PadR(MV_PAR02, nTamRev) ))

		cChave := TFJ->(TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV)

		/*Do While TFJ->(!Eof()) .AND. TFJ->TFJ_STATUS == '2' .AND. cChave == TFJ->(TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV) //TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV TFJ_STATUS <> '2')
		TFJ->(DbSkip(1))
		EndDo*/

		aAdd( aCTT, {TFJ->TFJ_CODIGO, TFJ->TFJ_STATUS})

		nReg := TFJ->(Recno())

		If TFJ->(DbSeek(xFilial("TFJ")+PadR(MV_PAR01, nTamCtt)+PadR(MV_PAR03, nTamRev) )) 

			cChave := TFJ->(TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV)

			/*Do While TFJ->(!Eof()) .AND. TFJ->TFJ_STATUS == '2' .AND. cChave == TFJ->(TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV) //TFJ_FILIAL+TFJ_CONTRT+TFJ_CONREV TFJ_STATUS <> '2')
			TFJ->(DbSkip(1))
			EndDo*/ 		

			aAdd( aCTT, {TFJ->TFJ_CODIGO, TFJ->TFJ_STATUS})
			oModelDes 		:= FwLoadModel(cOrcMod)
			oModelDes:SetOperation( MODEL_OPERATION_VIEW)
			lAtvMdl :=  oModelDes:Activate()

			If lAtvMdl
				TFJ->(DbGoTo(nReg))
				oModelOri 	:= FwLoadModel(cOrcMod)
				oModelOri:SetOperation( MODEL_OPERATION_VIEW )
				oModelOri:Activate()
				aRet := oModelOri:Compare(oModelDes, .t. )
			EndIf

			If Len(aRet) > 0 

				//Caputura a Estrutura do Modelos-Filhos
				aDep := oModelOri:Getdependency()

				//Retorna o Modelo em Array
				RetModel(aDep, oModelOri, 0, "", "", @aModelos)


				If Len(aModelos) > 0

					For nI := 1 to Len(aRet)
						cDescrP := "" 
						nY := aScan(aModelos, { |m| aRet[nI, 01] == m[3] })
						If nY > 0

							If !Empty(aModelos[nY, 06])
								nPosP := aScan(aModelos, { |m|  RTrim(aModelos[nY, 06]) == m[3] })

								If nPosP > 0
									cDescrP := aModelos[nPosP, 07][3] 
								EndIf
							EndIf

							aChaves := {}
							//Grava o Registro na tabela temporaria
							For nZ :=  1 to Len(aRet[nI][03])							
								GravaReg(aModelos[nY], aRet[nI][03][nZ], cAlias, aRet[nI][02], aRet[nI] , cDescrP, aModelos, nZ, @aChaves)
							Next nZ

						EndIf
					Next	
				EndIf
			EndIf
		EndIf
	EndIf

	(cAlias)->(DbSetOrder(1))
	(cAlias)->(DbGoTop())

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ImprimeQuebra

Função responsavél pela impressão da quebra do relatório
@author Serviços
@since 27/03/2019
@version P1217
@return
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function ImprimeQuebra(	aChaves, aAlias, 	nNivel, oReport, ;
	cAlias, aSections, 	aStuct)
	Local oSection 	:= NIL //Objeto da quebra
	Local cTabela 	:= "" //Alias da quebra
	Local nReg 		:= 0 //Recno do registro da tabela
	Local nPosSec 	:= 0 //Posicao da quebra
	Local cChave 	:= "" //Chave da tabela

	If nNivel > 1
		ImprimeQuebra(@aChaves, @aAlias, nNivel-1, oReport, cAlias, aSections, aStuct) //Imprime a quebra do pai
	EndIf

	cChave := (cAlias)->(FieldGet(nNivel))	
	cTabela := (cAlias)->(FieldGet(nNivel + 4))	
	nPosSec := aScan(aSections, { |cAli| cAli == cTabela})


	If nPosSec > 0 .AND. !Empty(cTabela) 

		If cChave <> aChaves[nNivel] .or. aAlias[nNivel] <> cTabela


			oSection := oReport:Section(nPosSec)
			nReg :=  (cAlias)->(FieldGet(nNivel + 8))	
			&(cTabela)->(DbGoTo(nReg))
			oSection:Init()
			oSection:PrintLine()
			oSection:Finish()

			ApagaFilh(nNivel, @aChaves, @aAlias, aStuct)

			aChaves[nNivel] := cChave
			aAlias[nNivel] := cTabela

		EndIf
	EndIf

Return Nil

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} ApagaFilh

Função responsavél pela apagar o array níveis abaixo
@author Serviços
@since 27/03/2019
@version P1217
@return
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function ApagaFilh(nNivel, aChaves, aAlias, aStuct)

	Do While  (nNivel := nNivel + 1) <= 4
		aChaves[nNivel] := space(aStuct[nNivel][03])
		aAlias[nNivel] :=  space(3) 
	EndDo

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} CreateStruct

Função responsavél por criar a estrutura da tabela
@author Serviços
@since 27/03/2019
@version P1217
@return oTempTable - Objeto Tabela
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function CreateStruct( cTblAlias, aFields)
	Local oTempTable 	:= NIL
	Local nTam 			:= 0
	Local nTamChave 	:= 0
	Local nTamRec		:= 20

	//--------------------------
	//Monta os campos da tabela
	//--------------------------
	//Campos CHV01...CHV04, ALI01...AL104, REC01...REC04 DEVEM ESTAR NA ORDEM 1 a 4 para não dar erro no fieldget
	nTam := GETSX3CACHE("TFJ_CODIGO", "X3_TAMANHO")
	nTamChave := Max(nTamChave, nTam)
	aadd(aFields,{"CHV01","C", nTam,0})

	nTam := GETSX3CACHE("TFL_CODIGO", "X3_TAMANHO")
	nTamChave := Max(nTamChave, nTam)
	aadd(aFields,{"CHV02","C", nTam,0})	

	nTam := GETSX3CACHE("TFF_COD", "X3_TAMANHO")
	nTamChave := Max(nTamChave, nTam)
	aadd(aFields,{"CHV03","C", nTam,0})

	nTam := GETSX3CACHE("TFI_COD", "X3_TAMANHO")
	nTamChave := Max(Max(nTamChave, nTam), nTamRec)	
	aadd(aFields,{"CHV04","C", nTam,0})

	aadd(aFields,{"ALI01","C",3,0}) //5
	aadd(aFields,{"ALI02","C",3,0})	//6
	aadd(aFields,{"ALI03","C",3,0}) //7
	aadd(aFields,{"ALI04","C",3,0}) //8

	aadd(aFields,{"REC01","N",nTamRec,0}) //9
	aadd(aFields,{"REC02","N",nTamRec,0}) //10	
	aadd(aFields,{"REC03","N",nTamRec,0}) //11
	aadd(aFields,{"REC04","N",nTamRec,0}) //12

	aadd(aFields,{"MODELO","C",10,0})
	aadd(aFields,{"NIVEL","C", 3,0})
	aadd(aFields,{"CHAVE","C", nTamChave,0})
	aadd(aFields,{"LINHA","C", 5,0})

	aadd(aFields,{"CAMPO","C",10,0})
	aadd(aFields,{"DESCR_CAMP","C",12,0})
	aadd(aFields,{"VLR_ORIG","C",50,1})
	aadd(aFields,{"VLR_DEST","C",50,0})
	aadd(aFields,{"ORIGEM","C",1, 0})	

	oTempTable := FWTemporaryTable():New( cTblAlias, aFields )	
	oTempTable:AddIndex("01", { "CHV01", "ALI01", "CHV02", "ALI02", "CHV03", "ALI03", "CHV04", "ALI04", "NIVEL", "MODELO", "CHAVE",  "LINHA", "CAMPO"} )
	oTempTable:Create()

Return oTempTable 

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GravaReg

Função responsavél para gravar os dados da comparação do modelo na tabela temporaria
@author Serviços
@since 27/03/2019
@version P1217
@return oReport - Objeto report
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function GravaReg(aModelo, aGrid, cTblAlias, cTpGrid, ;
	aRet, cDescrP, aModelos, nZ, ;
	aChaves)
	Local nC := 1
	Local aNoCpo := { "TFJ_TOTRH",;
	"TFL_CODSUB",;
	"TFF_CODSUB",;
	"TFG_CODSUB",;
	"TFH_CODSUB",;
	"TFL_CONREV",;
	"TFF_CONREV",;
	"TFG_CONREV",;
	"TFH_CONREV",;
	"TFI_CODSUB",;
	"TFI_CODPAI",;
	"TFI_CONREV",;
	'TFJ_CODIGO',;
	'TFJ_PREVIS',;
	'TFL_CODIGO', ;
	'TFL_CODPAI', ;
	'TFF_COD',; 
	'TFF_CODPAI',;
	'TFF_LOCAL',;
	'TFF_PROCES',;
	'TFG_COD',;
	'TFG_CODPAI',;
	'TFH_COD', ;
	'TFH_CODPAI', ;
	'TFH_LOCAL',;
	'TFI_COD', ;
	'TFI_CODPAI',;
	'TFI_LOCAL',;
	'ABP_ITRH', ;
	'TEV_CODLOC', ;
	'TFU_CODIGO',;
	'TFU_CODTFF',;
	'TFU_LOCAL',;
	'TGV_COD',;
	'TDT_COD',;
	'TDS_COD',;
	'TWO_CODORC',;
	'TWO_PROPOS',;
	'TWO_LOCAL',;
	"TFF_ORIREF"} 
	Local cCampo := ""
	Local cOpera := "4"
	Local nInc	:= 1
	Local nOrigem := 2
	Local nDestino := 3

	If cTpGrid == "F"
		cCampo := RTrim(aGrid[01])
		If (aRet[05][01] + aRet[05][02]) > 0 .AND. aScan(aNoCpo, {|c| c == cCampo }) = 0
			GravaCampos(aModelo, aGrid, cTblalias, nZ, nC, @aChaves, aRet[05], cDescrP, aModelos, cOpera, @nOrigem, @nDestino)
		EndIf
	Else
		If RTrim(aModelo[03]) <> "TFF_RH"
			cOpera := aGrid[02]
		Else
			If Empty(aGrid[04][01]) .or. Empty(aGrid[04][02])
				cOpera := "3"
			EndIf
		EndIf
		aChaves := {}
		For nC := 1 to Len(aGrid[03])
			cCampo := RTrim(aGrid[03][nC][01])	
			If (aGrid[04][01]  + aGrid[04][02] ) > 0 .AND. aScan(aNoCpo, {|c| c == cCampo}) = 0
				nInc++
				GravaCampos(aModelo, aGrid[03][nC], cTblalias, nInc, aGrid[01], @aChaves, aGrid[04], cDescrP, aModelos, @cOpera, @nOrigem, @nDestino )
			EndIf
		Next nC
	EndIf

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GravaCampos

Função responsavél para gravar os campos na tabela temporária
@author Serviços
@since 27/03/2019
@version P1217
@return oReport - Objeto report
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function GravaCampos(aModel, aCampo, cTblAlias, nLinha, nLinhaGrid, aChaves, aRegs, cDescrP, aModelos, cOp, nOrigem, nDestino)
	Local nPos := 0 //Posicao do campo na tabela temporaria

	Default cOp := "4"
	DeFault nOrigem := 2
	Default nDestino := 3

	If nLinha == 1 .OR.  Empty(aChaves)
		aChaves := GetChav(aModel, aCampo, aRegs, aModelos, @cOp)
		If (cOp == "3" .AND. aCampo[nDestino] == NIL) .OR. (cOp == "5" .AND. aCampo[nOrigem] == NIL)
			nOrigem := 3
			nDestino := 2
		EndIf
	EndIf



	RecLock(cTblAlias, .T.)
	(cTblAlias)->NIVEL := aModel[01]
	(cTblAlias)->MODELO := aModel[03]
	(cTblAlias)->CHV01 := aChaves[01]

	(cTblAlias)->CHV02 := aChaves[02]
	(cTblAlias)->CHV03 := aChaves[03]
	(cTblAlias)->REC04 := aChaves[14]	
	(cTblAlias)->CHAVE := aChaves[05]	
	(cTblAlias)->ORIGEM := cOp
	(cTblAlias)->ALI01 := aChaves[07]
	(cTblAlias)->REC01 := aChaves[08]
	(cTblAlias)->ALI02 := aChaves[09]
	(cTblAlias)->REC02 := aChaves[10]
	(cTblAlias)->ALI03 := aChaves[11]
	(cTblAlias)->REC03 := aChaves[12]
	(cTblAlias)->CHV04 := aChaves[04]
	(cTblAlias)->ALI04 := aChaves[13]

	(cTblAlias)->LINHA := StrZero(nLinhaGrid,5)	
	(cTblAlias)->CAMPO := aCampo[01]
	IF ( nPos := aScan(aModel[08],  { |l| l[3] == aCampo[01] } ) )  > 0
		(cTblAlias)->DESCR_CAMP := aModel[08][nPos][01]
	EndIf

	(cTblAlias)->VLR_ORIG := cValtoChar(aCampo[nOrigem])
	(cTblAlias)->VLR_DEST := cValtoChar(aCampo[nDestino])	
	(cTblAlias)->(MsUnLock())

Return


//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetChav

Função responsavél para capturar a chave do registro, conforme o modelo
@author Serviços
@since 27/03/2019
@version P1217
@return aArray - Array com as chaves

/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function GetChav(aModel, aCampo, aRegs, aModelos,cOp)
	Local aChaves 	:= Array(14, "") //Array de chaves do registro
	Local nReg 		:= 0 //Codigo do registro
	Local cOrigem 	:= "A" //Origem do registro
	Local cChave 	:= "" //Chave do registro
	Local nLAli 	:= 0 //Posicao do alias
	Local cCpoCont	:= ""
	Local cCpoRev	:= ""
	Local nPosCpo := 0
	Local nPosRev := 0
	Local nPosCodSub := 0
	Local cCpoCodSub := ""


	aChaveS[08] := 0
	aChaveS[10] := 0
	aChaveS[12] := 0
	aChaveS[14] := 0

	nReg := aRegs[01]
	If Empty(aRegs[01]) .OR. Empty(aRegs[02])
		cOrigem := "D"
		If  Empty(nReg) 
			nReg := aRegs[02]
		EndIf
	Else
		cOp := "4"
	EndIf

	//Posiciona no registro
	(aModel[07][01])->(DbGoTo(nReg))




	cChave := cValtoChar(nReg)
	If Val(aModel[01]) > 0 

		If Len(aModel[07][02]) = 1
			cChave := cValtoChar((aModel[07][01])->(Fieldget(FieldPos(aModel[07][02][01]))))
		EndIf
		aChaves[Val(aModel[01])] := cChave

		nLAli := 7 + (Val(aModel[01]) - 1 ) *2

		aChaves[nLAli] := aModel[07][01] //Alias 
		aChaves[++nLAli] := nReg //Recno
		aChaves[05] := cChave
		aChaves[06] := cOrigem
	EndIf

	If !Empty(aModel[06]) .AND. Val(aModel[01]) > 1 
		GetChaveSql(aModel, @aChaves, nReg, aModelos)
	EndIf

	//Verifica se o item de MI/MC foi excluído

	If Empty(aRegs[01]) .OR. Empty(aRegs[02])
		If Val(aModel[01]) >= 3 
			cOp := VerificaOp(aModel, @aChaves, nReg, cOp)
		ElseIf Val(aModel[01]) <= 2  //Segundo nível não pode excluir, então é inclusão
			cOp := "3"
		EndIf

	EndIf

Return aChaves

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} GetChaveSQL

Função responsavél por retornar a chave do SQL
@author Serviços
@since 27/03/2019
@version P1217
@return
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function GetChaveSQL(aModel, aChaves, nReg, aModelos)
	Local cAliasTmp 	:= GetNextAlias() //Alias temporario
	Local cSql 			:= "" //Expressão SQL
	Local aTabs 		:= {} //Tabelas do Modelo
	Local cTabela 		:= "" //Tabela da query
	Local cCampo 		:= "" //Campo da Query
	Local nPos 			:= 0 //Posicao da Query
	Local cWhere 		:= "" //Expressão Where
	locaL cTabelaM 		:= "" //Tabela Mandataria
	Local nC 			:= 0 //Contador
	Local cCpoGet 		:= "" //Campo da Query
	Local nRegAtu 		:= 0
	Local cCodPai 		:= aModel[06] //Codigo do Modelo Pai
	Local nAli 			:= 0 //Posicao do Alias
	Local cAli 			:= "" //Codigo do Alias

	cTabelaM := aModel[07][01]
	cCampo := cTabelaM + "." + cTabelaM + "_FILIAL = '" + xFilial(cTabelaM)+ "'"+;
	" AND "+ cTabelaM + ".D_E_L_E_T_ = ' ' "+;
	" AND "+ cTabelaM + ".R_E_C_N_O_ = "+ cValToChar(nReg)
	aAdd(aTabs, {aModel[07][01], cCampo} ) //Tabela Principal

	For nC := 1 to len(aModel[05]) //Relacionamentos

		If aModel[05][nC][01] <> cTabelaM+"_FILIAL"
			cCampo := aModel[05][nC][02]


			cCampo := aModel[05][nC][02]
			cTabela := SubStr(cCampo,1,AT("_",cCampo)-1)
			If !Empty(cTabela)
				cTabela := IIF(Len(cTabela) == 2, "S", "") + cTabela
			EndIf

			If ( nPos := aScan(aTabs, { |t| t[1] == cTabela}) ) == 0
				cCampo := " AND " + cTabela + "." + cTabela + "_FILIAL = '" + xFilial(cTabela)+ "'"+;
				" AND "+ cTabela + ".D_E_L_E_T_ = ' ' "
				aAdd(aTabs, {cTabela, cCampo} ) //Tabela Principal
				nPos := Len(aTabs)
			EndIf
			aTabs[nPos][02] := aTabs[nPos][02] + " AND " + cTabelaM + "." + aModel[05][nC][01]  + " = " + cTabela + "." + aModel[05][nC][02]
		EndIf
	Next nC 

	cCampo := ""
	cCodPai :=  aModel[06]

	If nPos :=  aScan(aModelos, { |m|  RTrim(cCodPai) == m[3] })
		If Len(aModelos[nPos][07][02]) == 1
			cCpoGet := aModelos[nPos][07][02][01]
			cTabela := SubStr(cCpoGet,1,AT("_",cCpoGet)-1)
			If !Empty(cTabela)
				cTabela := IIF(Len(cTabela) == 2, "S", "") + cTabela
			EndIf
			cAli := cTabela
			cCampo := cTabela + "." + cCpoGet + " AS CHAVE, "		

		EndIf

		cCampo += cTabela + ".R_E_C_N_O_ AS REGISTRO" 
	EndIf

	cTabela := ""
	cWhere := ""
	For nC := 1 to Len(aTabs)
		If !Empty(cTabela)
			cTabela += ", "
		EndIf
		cTabela += RetSqlName(aTabs[nC, 01]) + " " + aTabs[nC, 01]
		cWhere += aTabs[nC, 02] 
	Next nC

	If  aModelos[nPos][03] == "TFJ_REFER" //O pai é o orçamento
		cSql := "SELECT " + cCampo
		cSql += " FROM " + cTabela
		cSql += " WHERE " +  cWhere
		cSql := ChangeQuery( cSql )

		dbUseArea( .T., "TOPCONN", TcGenQry( , , cSql ),  cAliasTmp	, .T., .T. ) 	

		If (cAliasTmp)->(!Eof())	
			cCampo :=  cValToChar((cAliasTmp)->(CHAVE))
			nRegAtu := (cAliasTmp)->REGISTRO
		EndIf

		(cAliasTmp)->(DbCloseArea())	

		aChaves[ Val( aModelos[nPos][01] ) ] := cCampo

		nAli :=  7 + (Val( aModelos[nPos][01] )  - 1) * 2
		aChaves[ nAli ] :=  cAli
		aChaves[ ++nAli ] :=  nRegAtu
	Else

		cSql := "SELECT " + cCampo 
		cSql += " FROM " + cTabela
		cSql += " WHERE " +  cWhere
		cSql := ChangeQuery( cSql )

		dbUseArea( .T., "TOPCONN", TcGenQry( , , cSql ),  cAliasTmp	, .T., .T. ) 	

		If (cAliasTmp)->(!Eof())	
			cCampo := cValToChar((cAliasTmp)->(CHAVE))
			nRegAtu := (cAliasTmp)->REGISTRO
		EndIf

		(cAliasTmp)->(DbCloseArea())	

		aChaves[Val(aModelos[nPos][01])] := cCampo
		nAli := 7 + (Val( aModelos[nPos][01] )  - 1) * 2
		aChaves[ nAli ] := cAli
		aChaves[ ++nAli ] :=  nRegAtu

		GetChaveSQL(aModelos[nPos], @aChaves, nRegAtu, aModelos)
	EndIf

Return
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} RetModel

Função responsavél por retornar o modelo em Array
@author Serviços
@since 27/03/2019
@version P1217
@return 
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function RetModel(aDeP, oModelOri, nLevel, cQbr, ;
	cIdPai,  aModelos)
	Local nC 		:= 0
	Local nY 		:= 0
	Local cQbrIt 	:= ""
	Local nZ 		:= 0
	Local aRelac 	:= {}
	Local oMdlStruc := NIL
	Local cModel	:= ""
	Local aTable	:= {}

	nLevel++

	//[1] - Nível do Model == Char(3)
	//[2] - Ordem do Modelo ==
	//[3] - Id do Modelo
	//[4] - Quebras do Modelo
	//[5] - Chave do Modelo
	//[6] - Modelo-pai
	//[7] - Tabela
	//[8] - Campos do Modelo

	For nC := 1 to Len(aDeP)
		If aDeP[nC][01] $ "FIELD|GRID|"
			oMdlStruc := oModelOri:GetModelStruct(aDeP[nC][02])[3]:Getstruct()

			aRelac := oModelOri:GetRelation(aDeP[nC][02])

			nZ :=  Len(aModelos)+1

			cQbrIt := cQbr + "|" + aDeP[nC][02]
			aTable := oMdlStruc:GetTable()

			/*If aDeP[nC][02] == "TFJ_REFER"
			aTable[02]:= {"TFJ_CONTRT"}
			EndIf
			*/

			aAdd(aModelos, {StrZero(nLevel,2), StrZero(nZ,2),aDeP[nC][02],  cQbr, ;
			aRelac[1], cIdPai, aTable, oMdlStruc:GetFields()  })

			RetFilhos(aDeP[nC][02], oModelOri, nLevel, cQbrIt, @aModelos)
		EndIf
	Next nC

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} RetFilhos

Função responsavél por retornar o SubModelo
@author Serviços
@since 27/03/2019
@version P1217
@return 
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function RetFilhos(cId, oModelOri, nLevel, cQbrIt, aModelos)
	Local aFilhos 	:= {}
	Local aRelation := {}

	aFilhos := oModelOri:Getdependency(cId)

	RetModel(aFilhos, oModelOri, nLevel, cQbrIt, cId, @aModelos)

Return

//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} RetMobCob

Função responsavél por retornar a Descrição da Modalida de Cobranca
@author Serviços
@since 27/03/2019
@version P1217
@return cDescr - Descrição da Modalida de Cobranca
/*/ 
//----------------------------------------------------------------------------------------------------------------------
Static Function RetMobCob(cTpMod)
	Local nY 		:= 0    
	Local aTpMod 	:= ""
	Local cDescr	:= ""

	If !Empty(cTpMod)
		If Empty(_CampoMod)
			DbSelectArea("SX3")
			dbSetOrder(2)
			If dbSeek( "TEV_MODCOB" )
				_CampoMod := X3Cbox()
			EndIf
		EndIf    

		aTpMod := StrTokArr(_CampoMod,";")         

		For nY:= 1 To Len(aTpMod)
			aTpMod[nY] = StrTokArr(aTpMod[nY],"=")
		Next

		cDescr := aTpMod[&cTpMod][2]
	EndIf

Return cDescr
//--------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} VerificaOp

Função responsavél por verificar se a operação da linha foi inclusão ou exclusão
@author Serviços
@since 27/03/2019
@version P1217
@return cOp - Operação: 3 - Inclusão - , 5 - Exclusão
/*/ 
//----------------------------------------------------------------------------------------------------------------------

Static Function VerificaOp(aModel, aChaves, nReg, cOp)
	Local nPosAContr := 0
	//Posiciona na primeira chave - Codigo do Orçamento
	Local cCpoCTT := aModel[07][01]+"_CONTRT"
	Local cCpoRev := aModel[07][01]+"_CONREV"
	Local cCodSub := aModel[07][01]+"_CODSUB"
	Local nPosCtt := 0
	Local nPosRev := 0
	Local nPosSub := 0

	If !Empty(aChaves[01]) 
		If (nPosAContr := aScan(aCTT, { |c| c[1] == aChaves[1]}) ) > 0
			nPosCtt := (aModel[07][01])->(FieldPos(cCpoCTT))
			nPosRev := (aModel[07][01])->(FieldPos(cCpoRev))
			nPosSub := (aModel[07][01])->(FieldPos(cCodSub))	
			If  nPosCtt > 0 .AND. nPosRev > 0 .and. nPosSub > 0
				If aCtt[nPosAContr, 02] == DEF_TFJ_AGDAPROVA
				//Item Novo  - Contrato Vazio
				//item Excluído  - Contrato Preenchido e Revisão = Revisao de Origem 
					If  Empty((aModel[07][01])->(FieldGet(nPosCtt)))
						cOp := "3"
					ElseIf   RTrim((aModel[07][01])->(FieldGet(nPosRev))) == MV_PAR02 
						cOp := "5"
					ElseIf RTrim((aModel[07][01])->(FieldGet(nPosRev))) == MV_PAR03 
						cOp := "3"
					EndIf
				Else
				//Item novo - Revisao = Revisão Destino
				//Item Excluído  = Revisão  = Revisao Origem e codsubvazio
					If RTrim((aModel[07][01])->(FieldGet(nPosRev))) == MV_PAR03 
						cOp := "3"
					ElseIf RTrim((aModel[07][01])->(FieldGet(nPosRev))) == MV_PAR02 .AND.  Empty((aModel[07][01])->(FieldGet(nPosSub)))
						cOp := "5"
					ElseIf  !Empty((aModel[07][01])->(FieldGet(nPosSub)))
						cOp := "3"
					EndIf
			
				EndIf
			EndIf
		EndIf
	EndIf

Return cOp