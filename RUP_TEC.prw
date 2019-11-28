#Include 'Protheus.ch'

//------------------------------------------------------------------------------
/*/{Protheus.doc} RUP_TEC()
Funções de compatibilização e/ou conversão de dados para as tabelas do sistema.
Sempre executar primeiro o ajuste de dicionario, entao o ajuste de dados ("update tabelas")
@sample		RUP_TEC("12", "2", "003", "005", "BRA")
@param		cVersion	- Versão do Protheus 
@param		cMode		- Modo de execução	- "1" = Por grupo de empresas / "2" =Por grupo de empresas + filial (filial completa)
@param		cRelStart	- Release de partida	- (Este seria o Release no qual o cliente está)
@param		cRelFinish	- Release de chegada	- (Este seria o Release ao final da atualização)
@param		cLocaliz	- Localização (país)	- Ex. "BRA"
@return		Nil
@author		Cesar Bianchi
@since		24/08/2017
@version	12
/*/
//------------------------------------------------------------------------------
Function RUP_TEC(cVersion, cMode, cRelStart, cRelFinish, cLocaliz)

	Local aArea	   := GetArea()
	Local aAreaSIX := SIX->(GetArea())
	Local aAreaSX1 := SX1->(GetArea())
	Local aAreaSX2 := SX2->(GetArea())
	Local aAreaSX3 := SX3->(GetArea())
	Local aAreaSX5 := SX5->(GetArea())
	Local aAreaSX9 := SX9->(GetArea())
	Local aDelSX9 	 := {}
	Local cTmpContent 	:= ""
	Local nInd1		:= 0

	//1* Chama os ajustes de dicionario
	RupTecDic(cVersion, cMode, cRelStart, cRelFinish, cLocaliz)
	
	//2* Chama os ajustes de dados (alimenta campos novos, fix)
	//Só executa caso seja DBACCESS para nao capotar o Loja (Front) - POR ISSO O IFDEF TOP EM FONTE 12
	#IFDEF TOP
		RupTecTbl(cVersion, cMode, cRelStart, cRelFinish, cLocaliz)
	#ENDIF

	//***********************************************************************************//
	//Ajuste da SX9. Neste trecho são excluidas amarraçoes SX9 criadas de forma errada.  //
	//Entretanto, nao existe a opção de "exclusao" dentro da EngSX9()                    //
	//Como a maioria dos clientes vigentes ja executaram essa exclusão, a opção foi      //
	// comentada uma vez que nao é mais necessaria (Sonarqube)                           //
	//***********************************************************************************//
	/*If cRelStart >= "014" .And. cRelFinish <= "016"	
		aAdd( aDelSX9, "TFJ"+"ADY" )
		aAdd( aDelSX9, "TWT"+"TFV" )	
	EndIf
	SX3->(DbSetOrder(2))
	DbSelectArea("SX9")
	SX9->(DbSetOrder(2))
	For nInd1 := 1 To Len(aDelSX9)
		If SX9->(DbSeek(aDelSX9[nInd1]))
			Reclock("SX9",.F.)
			SX9->( DbDelete() )
			SX9->(MsUnlock())
		EndIf
	Next nInd1*/
	
	RestArea(aAreaSIX)
	RestArea(aAreaSX1)
	RestArea(aAreaSX2)
	RestArea(aAreaSX3)
	RestArea(aAreaSX5)
	RestArea(aAreaSX9)
	RestArea(aArea)
		
Return Nil

//==================================================================================================================== 
/*/{Protheus.doc} RupTecDic(cFonte) 
Função para realização de ajustes no dicionario de dados.
NAO EXECUTAR NENHUM RECLOCK EM ARQUIVOS SX e XX
USAR SEMPRE AS FUNCOES DO FRAMEWORK/GCAD PARA MANIPULACAO DOS DICIONARIOS				
@param		cVersion	- Versão do Protheus 
@param		cMode		- Modo de execução	- "1" = Por grupo de empresas / "2" =Por grupo de empresas + filial (filial completa)
@param		cRelStart	- Release de partida	- (Este seria o Release no qual o cliente está)
@param		cRelFinish	- Release de chegada	- (Este seria o Release ao final da atualização)
@param		cLocaliz	- Localização (país)	- Ex. "BRA"
@return		Nil
@author		Cesar Bianchi
@since 	24/08/2017
@version P12 
/*/
//==================================================================================================================== 
Static Function RupTecDic(cVersion, cMode, cRelStart, cRelFinish, cLocaliz)
	Local aArea	 		:= GetArea()
	Local aAjSX1 		:= {}
	Local aAjSX2 		:= {}
	Local aAjSX3 		:= {}
	Local aAjSX5 		:= {}
	Local aAjSX9 		:= {}
	Local cTmpContent 	:= ""
	Local nInd1	 		:= 0
	Local aAtuTab 		:= {}
	Local cResLvr 		:= ""
	
	//******************************************************************//
	//Monta os ajustes necessarios na SX1 - Para uso na funcao do Frame //
	//******************************************************************//
	/*ATE O MOMENTO NENHUM AJUSTE NECESSARIO*/

	//******************************************************************//	
	//Monta os ajustes necessarios na SX2 - Para uso na funcao do Frame //
	//******************************************************************//
	/*ATE O MOMENTO NENHUM AJUSTE NECESSARIO*/
	
	//******************************************************************//
	//Monta os ajustes necessarios na SX3 - Para uso na funcao do Frame //
	//******************************************************************//
	//TW1
	aAdd(aAjSX3,{ {"TW1_CODTW0"	},{ {'X3_ORDEM'	,'03'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODTFF"	},{ {'X3_ORDEM'	,'04'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODTGX"	},{ {'X3_ORDEM'	,'05'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_GRUPO"	},{ {'X3_ORDEM'	,'06'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_HORINI"	},{ {'X3_ORDEM'	,'07'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_HORFIM"	},{ {'X3_ORDEM'	,'08'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODABS"	},{ {'X3_ORDEM'	,'09'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_LOCAL"	},{ {'X3_ORDEM'	,'10'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODTDW"	},{ {'X3_ORDEM'	,'11'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_ESCALA"	},{ {'X3_ORDEM'	,'12'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODSUP"	},{ {'X3_ORDEM'	,'13'	,Nil} } })
	aAdd(aAjSX3,{ {"TW1_SUPERV"	},{ {'X3_ORDEM'	,'14'	,Nil} } })
	//TFI	
	aAdd(aAjSX3,{ {"TFI_TPCOBR"	},{ {'X3_ORDEM'	,'08'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_QTDVEN"	},{ {'X3_ORDEM'	,'09'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_SEPSLD"	},{ {'X3_ORDEM'	,'10'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_PERINI"	},{ {'X3_ORDEM'	,'11'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_PERFIM"	},{ {'X3_ORDEM'	,'12'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_HORAIN"	},{ {'X3_ORDEM'	,'13'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_HORAFI"	},{ {'X3_ORDEM'	,'14'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_TOTAL"	},{ {'X3_ORDEM'	,'15'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_DESCON"	},{ {'X3_ORDEM'	,'16'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_VALDES"	},{ {'X3_ORDEM'	,'17'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_TES"	},{ {'X3_ORDEM'	,'18'	,Nil} } })	
	aAdd(aAjSX3,{ {"TFI_SEPARA"	},{ {'X3_ORDEM'	,'19'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CODPAI"	},{ {'X3_ORDEM'	,'20'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CONTRT"	},{ {'X3_ORDEM'	,'21'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CONREV"	},{ {'X3_ORDEM'	,'22'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_RESERV"	},{ {'X3_ORDEM'	,'23'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CODSUB"	},{ {'X3_ORDEM'	,'24'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_OK"		},{ {'X3_ORDEM'	,'25'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CODTGQ"	},{ {'X3_ORDEM'	,'26'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_ITTGR"	},{ {'X3_ORDEM'	,'27'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CODATD"	},{ {'X3_ORDEM'	,'28'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_NOMATD"	},{ {'X3_ORDEM'	,'29'	,Nil} } })	
	aAdd(aAjSX3,{ {"TFI_ENCE"	},{ {'X3_ORDEM'	,'30'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_ENTEQP"	},{ {'X3_ORDEM'	,'31'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_COLEQP"	},{ {'X3_ORDEM'	,'32'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_APUMED"	},{ {'X3_ORDEM'	,'33'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_OSMONT"	},{ {'X3_ORDEM'	,'34'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CONENT"	},{ {'X3_ORDEM'	,'35'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CONCOL"	},{ {'X3_ORDEM'	,'36'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_CHVTWO"	},{ {'X3_ORDEM'	,'37'	,Nil} } })
	aAdd(aAjSX3,{ {"TFI_DTPFIM"	},{ {'X3_ORDEM'	,'38'	,Nil} } })
	//AA3	
	aAdd(aAjSX3,{ {"AA3_HMEATV"	},{ {'X3_ORDEM'	,'76'	,Nil} } })
	aAdd(aAjSX3,{ {"AA3_HMESEP"	},{ {'X3_ORDEM'	,'77'	,Nil} } })
	aAdd(aAjSX3,{ {"AA3_CONSEP"	},{ {'X3_ORDEM'	,'78'	,Nil} } })
	aAdd(aAjSX3,{ {"AA3_HMERET"	},{ {'X3_ORDEM'	,'79'	,Nil} } })
	aAdd(aAjSX3,{ {"AA3_CONRET"	},{ {'X3_ORDEM'	,'80'	,Nil} } })
	aAdd(aAjSX3,{ {"AA3_HMELIM"	},{ {'X3_ORDEM'	,'81'	,Nil} } })
	//ABS
	aAdd(aAjSX3,{ {"ABS_CODMUN"	},{ {'X3_ORDEM'	,'17'	,Nil} } })
	aAdd(aAjSX3,{ {"ABS_RECISS"	},{ {'X3_ORDEM'	,'24'	,Nil} } })
	//TWT
	aAdd(aAjSX3,{ {"TWT_FILIAL"	},{ {'X3_ORDEM'	,'01'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_CODAA3"	},{ {'X3_ORDEM'	,'02'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_ITEM"	},{ {'X3_ORDEM'	,'03'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_DTMARC"	},{ {'X3_ORDEM'	,'04'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_HRMARC"	},{ {'X3_ORDEM'	,'05'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_NUMHOR"	},{ {'X3_ORDEM'	,'06'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_MOTIVO"	},{ {'X3_ORDEM'	,'07'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_VALHOR"	},{ {'X3_ORDEM'	,'08'	,Nil} } })	
	aAdd(aAjSX3,{ {"TWT_DSCMOT"	},{ {'X3_ORDEM'	,'09'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_HMELIM"	},{ {'X3_ORDEM'	,'10'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_VIRADA"	},{ {'X3_ORDEM'	,'11'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_TPLCTO"	},{ {'X3_ORDEM'	,'12'	,Nil} } })	
	aAdd(aAjSX3,{ {"TWT_CODTFV"	},{ {'X3_ORDEM'	,'13'	,Nil} } })
	aAdd(aAjSX3,{ {"TWT_CODMV"	},{ {'X3_ORDEM'	,'14'	,Nil} } })
	//TWR
	aAdd(aAjSX3,{ {"TWR_DESTIN"	},{ {'X3_ORDEM'	,'03'	,Nil} } })
	//TEW
	aAdd(aAjSX3,{ {"TEW_FILIAL"	},{ {'X3_ORDEM'	,'01'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODMV"	},{ {'X3_ORDEM'	,'02'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ORCSER"	},{ {'X3_ORDEM'	,'03'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODEQU"	},{ {'X3_ORDEM'	,'04'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_PRODUT"	},{ {'X3_ORDEM'	,'05'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_BAATD"	},{ {'X3_ORDEM'	,'06'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_FILBAT"	},{ {'X3_ORDEM'	,'07'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DTSEPA"	},{ {'X3_ORDEM'	,'08'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DTRINI"	},{ {'X3_ORDEM'	,'09'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DTRFIM"	},{ {'X3_ORDEM'	,'10'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_NUMPED"	},{ {'X3_ORDEM'	,'11'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ITEMPV"	},{ {'X3_ORDEM'	,'12'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_NFSAI"	},{ {'X3_ORDEM'	,'13'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_SERSAI"	},{ {'X3_ORDEM'	,'14'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ITSAI"	},{ {'X3_ORDEM'	,'15'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_NFENT"	},{ {'X3_ORDEM'	,'16'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_SERENT"	},{ {'X3_ORDEM'	,'17'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ITENT"	},{ {'X3_ORDEM'	,'18'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_SUBSTI"	},{ {'X3_ORDEM'	,'19'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_OBSMNT"	},{ {'X3_ORDEM'	,'20'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_MOTIVO"	},{ {'X3_ORDEM'	,'21'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DTAMNT"	},{ {'X3_ORDEM'	,'22'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODKIT"	},{ {'X3_ORDEM'	,'23'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_KITSEQ"	},{ {'X3_ORDEM'	,'24'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_NUMOS"	},{ {'X3_ORDEM'	,'25'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ITEMOS"	},{ {'X3_ORDEM'	,'26'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_FECHOS"	},{ {'X3_ORDEM'	,'27'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_TIPO"	},{ {'X3_ORDEM'	,'28'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_RESCOD"	},{ {'X3_ORDEM'	,'29'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ITAPUR"	},{ {'X3_ORDEM'	,'30'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DSPROD"	},{ {'X3_ORDEM'	,'31'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_EQ3"	},{ {'X3_ORDEM'	,'32'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODATD"	},{ {'X3_ORDEM'	,'33'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DSATD"	},{ {'X3_ORDEM'	,'34'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_LOCAL"	},{ {'X3_ORDEM'	,'35'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DSLOC"	},{ {'X3_ORDEM'	,'36'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODCLI"	},{ {'X3_ORDEM'	,'37'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_LOJCLI"	},{ {'X3_ORDEM'	,'38'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DESCLI"	},{ {'X3_ORDEM'	,'39'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CONTRT"	},{ {'X3_ORDEM'	,'40'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_LEGEND"	},{ {'X3_ORDEM'	,'41'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_SDOCE"	},{ {'X3_ORDEM'	,'42'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_SDOCS"	},{ {'X3_ORDEM'	,'43'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DTPFIM"	},{ {'X3_ORDEM'	,'44'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_QTDVEN"	},{ {'X3_ORDEM'	,'45'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_QTDRES"	},{ {'X3_ORDEM'	,'46'	,Nil} } })
	//Grupo de Campos	
	aAdd(aAjSX3,{ {"AA1_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"AA2_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"AAT_VISTOR"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"AAY_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"AAZ_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"AB9_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABB_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABC_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABF_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABG_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABJ_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABK_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABR_CODSUB"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"ABU_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })	
	aAdd(aAjSX3,{ {"ADE_TECNIC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TE5_ATEND"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TE6_ATEND"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TES_ATEND"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TET_ATEND"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TEU_CDRESP"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })	
	aAdd(aAjSX3,{ {"TFN_CODIGO"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TFQ_CDRESP"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TFQ_RESTRA"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TFR_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })	
	aAdd(aAjSX3,{ {"TGY_ATEND"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TGZ_ATEND"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TIM_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TIT_CODRES"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TIT_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TIW_CODRES"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	aAdd(aAjSX3,{ {"TIW_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })	
	aAdd(aAjSX3,{ {"TIP_CODTEC"	},{ {'X3_GRPSXG'	,'116'	,Nil} } })
	//Inicializador Padrao
	aAdd(aAjSX3,{ {"TEW_DSPROD"	},{ {'X3_RELACAO'	,'At800DsInf("SB1", "B1_DESC", xFilial("SB1")+TEW->TEW_PRODUT)'		,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODATD"	},{ {'X3_RELACAO'	,'AT800DSINF("TGQ", "TGQ_CODATE", xFilial("TFI")+TEW->TEW_CODEQU'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DSATD"	},{ {'X3_RELACAO'	,'At800DsInf("AA1", "AA1_NOMTEC", xFilial("TFI")+TEW->TEW_CODEQU)'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_LOCAL"	},{ {'X3_RELACAO'	,'At800DsInf("TFI", "TFI_LOCAL", xFilial("TFI")+TEW->TEW_CODEQU)'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DSLOC"	},{ {'X3_RELACAO'	,'At800DsInf("ABS", "ABS_DESCRI", xFilial("TFI")+TEW->TEW_CODEQU)'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CODCLI"	},{ {'X3_RELACAO'	,'At800DsInf("TFJ", "TFJ_CODENT", xFilial("TFJ")+TEW->TEW_ORCSER )'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_LOJCLI"	},{ {'X3_RELACAO'	,'At800DsInf("TFJ", "TFJ_LOJA", xFilial("TFJ")+TEW->TEW_ORCSER)'	,Nil} } })
	aAdd(aAjSX3,{ {"TEW_DESCLI"	},{ {'X3_RELACAO'	,'At800DsInf("SA1", "A1_NOME", xFilial("TFJ")+TEW->TEW_ORCSER)'		,Nil} } })
	aAdd(aAjSX3,{ {"TEW_CONTRT"	},{ {'X3_RELACAO'	,'At800DsInf("TFI", "TFI_CONTRT", xFilial("TFI")+TEW->TEW_CODEQU)'	,Nil} } })
	aAdd(aAjSX3,{ {"TDU_COD"	},{ {'X3_RELACAO'	,'GETSXENUM("TDU","TDU_COD")'										,Nil} } })
	aAdd(aAjSX3,{ {"AA3_DESSTA"	},{ {'X3_RELACAO'	,'Posicione("SX5",1,xFilial("SX5")+"A5"+AA3_STATUS,"X5_DESCRI")'	,Nil} } })
	aAdd(aAjSX3,{ {"ABB_CODIGO"	},{ {'X3_RELACAO'	,'AtABBNumCd()'														,Nil} } })
	aAdd(aAjSX3,{ {"B5_ISIDUNI"	},{ {'X3_RELACAO'	,"'1'"																,Nil} } })	
	aAdd(aAjSX3,{ {"ABS_FILCC"	},{ {'X3_RELACAO'	,''																	,Nil} } })	
	cTmpContent := "xFilial('SX5')+'AZ'+ABP->ABP_BENEFI"
	aAdd(aAjSX3,{ {"ABP_DESCRI"	},{ {'X3_RELACAO'	,'ATINIPADMVC("TECA740","ABP_BENEF","X5DESCRI()","SX5",1, "'+cTmpContent+'")'	,Nil} } })	
	cTmpContent := "xFilial('SRV')+ABP->ABP_VERBA"
	aAdd(aAjSX3,{ {"ABS_FILCC"	},{ {'X3_RELACAO'	,'ATINIPADMVC("TECA740","ABP_BENEF","RV_DESC","SRV",1, "'+cTmpContent+'")'			,Nil} } })
		
	aAdd(aAjSX3,{ {"TFO_LOTE"	},{ {'X3_RELACAO'	,'','AT880INILOTE(TFO->TFO_ITMOV,TFO->TFO_ITCOD)'} } })
	
	aAdd(aAjSX3,{ {"TET_DSCPRO"	},{ {'X3_RELACAO'	,'if(!INCLUI,Posicione("SB1",1,xFilial("SB1") + TET->TET_PRODUT ,"B1_DESC"),"")',Nil} } })
	aAdd(aAjSX3,{ {"TET_LOTE"	},{ {'X3_RELACAO'	,'','IIF(!INCLUI,ALLTRIM(POSICIONE("TE2",1,XFILIAL("TE2")+TET->TET_CODMUN,"TE2_LOTE")),"") '} } })
	aAdd(aAjSX3,{ {"TET_DTVAL"	},{ {'X3_RELACAO'	,'','AT750INIDATA("2",TET->TET_PRODUT)'} } })
	aAdd(aAjSX3,{ {"TET_MARCA"	},{ {'X3_RELACAO'	,'IIF(!INCLUI,ALLTRIM(POSICIONE("TE2",4,XFILIAL("TE2")+TET->TET_PRODUT,"TE2_MARCA")),"")','IIF(!INCLUI,ALLTRIM(POSICIONE("TE2",1,XFILIAL("TE2")+TET->TET_CODMUN,"TE2_MARCA")),"")'} } })
	aAdd(aAjSX3,{ {"TET_CALIBR"	},{ {'X3_RELACAO'	,'IIF(!INCLUI,ALLTRIM(POSICIONE("TE2",4,XFILIAL("TE2")+TET->TET_PRODUT,"TE2_CALIBR")),"")','IIF(!INCLUI,ALLTRIM(POSICIONE("TE2",1,XFILIAL("TE2")+TET->TET_CODMUN,"TE2_CALIBR")),"")'} } })
	aAdd(aAjSX3,{ {"TET_SINARM"	},{ {'X3_RELACAO'	,'','IIF(!INCLUI,ALLTRIM(POSICIONE("TE2",1,XFILIAL("TE2")+TET->TET_CODMUN,"TE2_SINARM")),"")'} } })
	
	//Valid de Campo
	aAdd(aAjSX3,{ {"AA1_CDFUNC"	},{ {'X3_VALID'	,'(Vazio() .OR. ExistCPO("SRA")) .AND. At020VTCA()'											,Nil} } })
	aAdd(aAjSX3,{ {"AA1_FUNFIL"	},{ {'X3_VALID'	,'At020VldFu(FwfldGet("AA1_CDFUNC"),FwfldGet("AA1_FUNFIL"))'								,Nil} } })
	aAdd(aAjSX3,{ {"TEW_BAATD"	},{ {'X3_VALID'	,'Vazio() .Or. AtChkHasKey("AA3", 6, xFilial("AA3",FwFldGet("TEW_FILBAT"))+M->TEW_BAATD)'	,Nil} } })				
	aAdd(aAjSX3,{ {"TEW_FILBAT"	},{ {'X3_VALID'	,'Vazio() .Or. ExistCpo("SM0",cEmpAnt+M->TEW_FILBAT)'										,Nil} } })
	aAdd(aAjSX3,{ {"AA3_FILORI"	},{ {'X3_VALID'	,'ExistCpo("SM0", cEmpAnt+M->AA3_FILORI) .And. At040FilOk()'								,Nil} } })	
	aAdd(aAjSX3,{ {"TEW_NUMOS"	},{ {'X3_VALID'	,'Vazio() .Or. At800VldOs( "TEW_NUMOS" )'													,Nil} } })
	aAdd(aAjSX3,{ {"TEW_ITEMOS"	},{ {'X3_VALID'	,'Vazio() .Or. At800VldOs( "TEW_ITEMOS" )'													,Nil} } })
	aAdd(aAjSX3,{ {"AB6_CDORCS"	},{ {'X3_VALID'	,'Vazio() .Or. At450Orcs()'																	,Nil} } })	
	aAdd(aAjSX3,{ {"AB6_ITORCS"	},{ {'X3_VALID'	,'Vazio() .Or. At450Orcs()'																	,Nil} } })
	aAdd(aAjSX3,{ {"AB6_FIORCS"	},{ {'X3_VALID'	,'ExistCpo("SM0", cEmpAnt+M->AB6_FIORCS)'													,Nil} } })
	aAdd(aAjSX3,{ {"ABS_CCUSTO"	},{ {'X3_VALID'	,'Vazio() .OR. At160HasCC( M->ABS_FILCC, M->ABS_CCUSTO )'									,Nil} } })	
	aAdd(aAjSX3,{ {"TWT_TPLCTO"	},{ {'X3_VALID'	,'Pertence("1234")'																			,Nil} } })
	aAdd(aAjSX3,{ {"ABR_MOTIVO"	},{ {'X3_VALID'	,'(Vazio() .Or. ExistCpo( "ABN", M->ABR_MOTIVO, 1 )) .And. At550VlMt()'						,Nil} } })
	aAdd(aAjSX3,{ {"TE2_CODPRO"	},{ {'X3_VALID'	,'ExistCpo("SB1") .AND. ExistChav("TE2") .AND. At730VldUn()'                                ,Nil} } })
	aAdd(aAjSX3,{ {"TEU_TPARMA"	},{ {'X3_VALID'	,'Pertence("12") .And. At780CleArm()                        '                                ,Nil} } })
	//Browse	
	aAdd(aAjSX3,{ {"TIN_ITEM"	},{ {'X3_BROWSE'	,'S'		,Nil} } })	
	aAdd(aAjSX3,{ {"TIN_CODUSR"	},{ {'X3_BROWSE'	,'S'		,Nil} } })	
	aAdd(aAjSX3,{ {"TIN_NOMUSR"	},{ {'X3_BROWSE'	,'S'		,Nil} } })
	aAdd(aAjSX3,{ {"TW1_LOCAL"	},{ {'X3_BROWSE'	,'S'		,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODTDW"	},{ {'X3_BROWSE'	,'S'		,Nil} } })	
	aAdd(aAjSX3,{ {"TW1_ESCALA"	},{ {'X3_BROWSE'	,'S'		,Nil} } })
	aAdd(aAjSX3,{ {"TW1_CODSUP"	},{ {'X3_BROWSE'	,'S'		,Nil} } })	
	aAdd(aAjSX3,{ {"TW1_SUPERV"	},{ {'X3_BROWSE'	,'S'		,Nil} } })		
	aAdd(aAjSX3,{ {"TW1_CODTW0"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_DOC"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_CODFOR"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_LOJA"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_NOME"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_CNPJ"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_SERIE"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_DTNOTA"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	aAdd(aAjSX3,{ {"TE2_COMPRA"	},{ {'X3_BROWSE'	,'N'		,Nil} } })
	//When
	aAdd(aAjSX3,{ {"AA3_CDBMFL"	},{ {'X3_WHEN'	,'Inclui .Or. At040NoSTP()'		,Nil} } })
	aAdd(aAjSX3,{ {"AA3_CODBEM"	},{ {'X3_WHEN'	,'Inclui .Or. At040NoSTP()'		,Nil} } })
	//Titulo
	aAdd(aAjSX3,{ {"AA3_CBASE"	},{ {'X3_TITULO'	,'Cod. Ativo'				,Nil} } })		
	aAdd(aAjSX3,{ {"AA3_ITEM"	},{ {'X3_TITULO'	,'Item Ativo'				,Nil} } })
	aAdd(aAjSX3,{ {"AA3_CDBMFL"	},{ {'X3_TITULO'	,'Fil. Bem MNT'				,Nil} } })
	aAdd(aAjSX3,{ {"AA3_CODBEM"	},{ {'X3_TITULO'	,'Cód. Bem MNT'				,Nil} } })	
	//Consulta Padrao F3
	aAdd(aAjSX3,{ {"TDU_CODTCZ"	},{ {'X3_F3'		,'TCZ'						,Nil} } })		
	aAdd(aAjSX3,{ {"TWS_FILPRD"	},{ {'X3_F3'		,'SM0SB1'					,Nil} } })
	aAdd(aAjSX3,{ {"ABS_CCUSTO"	},{ {'X3_F3'		,'ABSCTT'					,Nil} } })
	aAdd(aAjSX3,{ {"TE0_CODPRO"	},{ {'X3_F3'		,'SB1ARM'					,Nil} } })
	aAdd(aAjSX3,{ {"TE1_CODPRO"	},{ {'X3_F3'		,'SB1COL'					,Nil} } })
	aAdd(aAjSX3,{ {"TE2_CODPRO"	},{ {'X3_F3'		,'SB1MUN'					,Nil} } })
			
	//Contexto
	aAdd(aAjSX3,{ {"TW1_ESCALA"	},{ {'X3_CONTEXT'	,'V'						,Nil} } })		
	aAdd(aAjSX3,{ {"ABR_TIPDIA"	},{ {'X3_CONTEXT'	,'R'						,Nil} } })
	aAdd(aAjSX3,{ {"TFS_PRODUT"	},{ {'X3_CONTEXT'	,'R'						,Nil} } })
	aAdd(aAjSX3,{ {"TFT_PRODUT"	},{ {'X3_CONTEXT'	,'R'						,Nil} } })
	//Inicializador Padrao Browse	
	aAdd(aAjSX3,{ {"TIN_NOMUSR"	},{ {'X3_INIBRW'	,'UsrRetName(TIN->TIN_CODUSR)'											,Nil} } })		
	aAdd(aAjSX3,{ {"TWS_PRDDES"	},{ {'X3_INIBRW'	,'Posicione("SB1", 1, TWS->TWS_FILPRD+TWS->TWS_PRDCOD, "B1_DESC")'		,Nil} } })
	//Visual
	aAdd(aAjSX3,{ {"TW1_LOCAL"	},{ {'X3_VISUAL'	,'V'						,Nil} } })
	aAdd(aAjSX3,{ {"TW1_ESCALA"	},{ {'X3_VISUAL'	,'V'						,Nil} } })
	aAdd(aAjSX3,{ {"TFS_PRODUT"	},{ {'X3_VISUAL'	,'A'						,Nil} } })
	aAdd(aAjSX3,{ {"TFT_PRODUT"	},{ {'X3_VISUAL'	,'A'						,Nil} } })
	
	//CBOX
	aAdd(aAjSX3,{ {"TEU_TPARMA"	},{ {'X3_CBOX'	,'1=Arma;2=Colete'						,Nil} } })
	
	dbSelectArea("SX3")
	SX3->(dbSetOrder(2))
	SX3->(dbSeek("A1_NOME"))
	If len(SX3->X3_RESERV) <= 2
		cResLvr := SX3->X3_RESERV
	else
		cResLvr := X3Reserv(SX3->X3_RESERV)
	EndIf
	aAdd(aAjSX3,{ {"ABS_DESENT" },{ {'X3_RESERV'	,cResLvr					,Nil} } })
	
	SX3->(dbSeek("B1_DESC"))
	If len(SX3->X3_RESERV) <= 2
		cResLvr := SX3->X3_RESERV
	else
		cResLvr := X3Reserv(SX3->X3_RESERV)
	EndIf
	aAdd(aAjSX3,{ {"TET_DSCPRO" },{ {'X3_RESERV'	,cResLvr					,Nil} } })
	
	//******************************************************************//
	//Monta os ajustes necessarios na SX5 - Para uso na funcao do Frame //
	//******************************************************************//
	/*ATE O MOMENTO NENHUM AJUSTE NECESSARIO*/
	
	//******************************************************************//
	//Monta os ajustes necessarios na SX9 - Para uso na funcao do Frame //
	//******************************************************************//
	aAdd(aAjSX9,{{ 'TET' , 'SB1' }, {{ 'X9_EXPDOM', 'B1_COD','TE2_CODMUN' }, { 'X9_EXPCDOM', 'TET_PRODUT','TET_CODMUN' }}} )	
	
	//******************************************************************//
	//Monta os ajustes necessarios na SIX - Para uso na funcao do Frame //
	//******************************************************************//
	/*ATE O MOMENTO NENHUM AJUSTE NECESSARIO*/
	
	//******************************************************************//
	//Executa as funcoes do Framework para ajustar dicionarios.         //
	//Obs: A cada release é necessario ajustar da funcao                //		
	//******************************************************************//	
	//EngSX1117(aAjSX1) --Comentado pois atualmente nao existem ajustes de SX1 neste fonte
	//EngSX2117(aAjSX2) --Comentado pois atualmente nao existem ajustes de SX2 neste fonte
	EngSX3117(aAjSX3)
	//EngSX5117(aAjSX5) --Comentado pois atualmente nao existem ajustes de SX5 neste fonte
	EngSX9117(aAjSX9) 
	//EngSIX117(aAjSX5) --Comentado pois atualmente nao existem ajustes de SIX neste fonte
	
	//Zera Arrays
	aAjSX1 := Nil
	aAjSX2 := Nil
	aAjSX3 := Nil
	aAjSX5 := Nil
	aAjSX9 := Nil	
	RestArea(aArea)
	
Return Nil


//==================================================================================================================== 
/*/{Protheus.doc} RupTecTbl() 
Função para realização de ajustes de dados em tabelas do GS. 
NAO EXECUTAR MANUTENCAO DE SXS ATRAVES DESTA FUNCAO. CARATER EXCLUSIVO PARA AJUSTE DE DADOS APENAS				
@param		cVersion	- Versão do Protheus 
@param		cMode		- Modo de execução	- "1" = Por grupo de empresas / "2" =Por grupo de empresas + filial (filial completa)
@param		cRelStart	- Release de partida	- (Este seria o Release no qual o cliente está)
@param		cRelFinish	- Release de chegada	- (Este seria o Release ao final da atualização)
@param		cLocaliz	- Localização (país)	- Ex. "BRA"
@return		Nil
@author		Desconhecido
@since 	24/08/2017
@version P12 
/*/
//==================================================================================================================== 
Static Function RupTecTbl(cVersion, cMode, cRelStart, cRelFinish, cLocaliz)
	Local cTmpQry := ""
	Local nTamNvlEmp := Len( FWSM0Layout(cEmpAnt,1) )
	Local nTamNvlUni := Len( FWSM0Layout(cEmpAnt,2) )
	Local nTamNvlFil := Len( FWSM0Layout(cEmpAnt,3) )
	Local nTamFilTot := ( nTamNvlEmp + nTamNvlUni + nTamNvlFil )
	Local nTamFilSB1 := If( FWModeAccess("SB1",3) == "E", nTamFilTot, If( FWModeAccess("SB1",2) == "E", nTamNvlEmp + nTamNvlUni, If( FWModeAccess("SB1",1) == "E", nTamNvlEmp, 0 ) ) )
	Local nTamFilTEW := If( FWModeAccess("TEW",3) == "E", nTamFilTot, If( FWModeAccess("TEW",2) == "E", nTamNvlEmp + nTamNvlUni, If( FWModeAccess("TEW",1) == "E", nTamNvlEmp, 0 ) ) )
	Local nTamFilAA3 := If( FWModeAccess("AA3",3) == "E", nTamFilTot, If( FWModeAccess("AA3",2) == "E", nTamNvlEmp + nTamNvlUni, If( FWModeAccess("AA3",1) == "E", nTamNvlEmp, 0 ) ) )

	If cRelStart >= "007"
	 
		cTmpQry	:= GetNextAlias()
		DbSelectArea("TFI")
		
		If TFI->(FieldPos("TFI_CONENT")) > 0 .And. ;
			TFI->(FieldPos("TFI_CONCOL")) > 0
			
			BeginSql Alias cTmpQry
				SELECT  TFI_COD
					   ,TFI_CONENT
					   ,TFI_CONCOL
				FROM %Table:TFI% TFI
				WHERE TFI.TFI_FILIAL   = %xFilial:TFI%
					AND TFI.TFI_CONENT = %Exp:' '% 
					OR TFI.TFI_CONCOL  = %Exp:' '% 
					AND TFI.%NotDel%
			EndSql
	  		TFI->(DbSetOrder(1))
			While (cTmpQry)->(!Eof())
				If TFI->(DbSeek(xFilial("TFI")+(cTmpQry)->TFI_COD))		
					If TFI->TFI_CONENT == " "
						Reclock("TFI",.F.)
						TFI->TFI_CONENT := "2"
						TFI->(MsUnlock())
					Endif
				Endif
				If TFI->TFI_CONCOL == " "
					Reclock("TFI",.F.)
					TFI->TFI_CONCOL := "2"
					TFI->(MsUnlock())
				Endif
				TFI->(MsUnlock())
				(cTmpQry)->(DbSkip())
			EndDo
			(cTmpQry)->(DbCloseArea())
		EndIf
	
		// Selecionar os registros na TEW 
		// Identificar as bases de atendimento relacionadas através da FILIAL da TEW
		// Inserir nos campos AA3_FILORI e TEW_FILBAT o conteúdo da FILIAL da TEW
		//   as Bases não atendidas por este processo, precisão receber o conteúdo diretamente pelos usuários
		//   ou programa Rdmake do cliente		
		// verifica o compartilhamento das tabelas TEW, SB1 e AA3
		//  para depois inferir quais as filiais originais dos equipamentos com base nas alocações e produtos associados
		DbSelectArea("SB1")
		DbSelectArea("TEW")
		DbSelectArea("AA3")
		
		If ( nTamFilTot == nTamFilTEW ) .And. ; // TEW completamente exclusiva
			( nTamFilTEW > nTamFilAA3 ) .And. ; // AA3 com compartilhamento menor que a TEW
			( nTamFilSB1 > nTamFilAA3 ) .And. ; // SB1 com compartilhamento maior que a AA3
			( TEW->(FieldPos("TEW_FILBAT")) > 0 ) .And. ;
			( AA3->(FieldPos("AA3_FILORI")) > 0 )
		
			BeginSql Alias cTmpQry
				SELECT 
					TEW.R_E_C_N_O_ TEWRECNO
					, AA3.R_E_C_N_O_ AA3RECNO
					, TEW_FILIAL
					, TEW_CODMV
					, AA3_NUMSER
				FROM %Table:TEW% TEW
					INNER JOIN %Table:AA3% AA3 ON
									AA3.D_E_L_E_T_=' '
									AND AA3.AA3_NUMSER = TEW.TEW_BAATD
									AND AA3.AA3_EQALOC = '1'
									AND SUBSTRING( AA3.AA3_FILIAL, 1, %Exp:nTamFilAA3% ) = SUBSTRING( TEW.TEW_FILIAL, 1, %Exp:nTamFilAA3% )
				WHERE 
					TEW.D_E_L_E_T_=' '
					AND TEW.TEW_FILBAT = ' '
					AND TEW.TEW_BAATD <> ' ' 
			EndSql
			
			If (cTmpQry)->(!EOF())
				
				While (cTmpQry)->(!EOF())
					
					// atualiza a filial na TEW
					TEW->(DbGoTo( (cTmpQry)->TEWRECNO ))
					Reclock("TEW",.F.)
					TEW->TEW_FILBAT := (cTmpQry)->TEW_FILIAL
					TEW->(MsUnlock())
					
					// atualiza a filial na AA3
					AA3->(DbGoTo( (cTmpQry)->AA3RECNO ))
					Reclock("AA3",.F.)
					AA3->AA3_FILORI := (cTmpQry)->TEW_FILIAL
					AA3->(MsUnlock())
					
					(cTmpQry)->(DbSkip())
				End
			EndIf
			
			(cTmpQry)->(DbCloseArea())
			
			//  verifica as bases de atendimento que não tiveram o campo de filial dona preenchidos 
			// 
			BeginSql Alias cTmpQry
				SELECT 
					SB1.R_E_C_N_O_ SB1RECNO
					, AA3.R_E_C_N_O_ AA3RECNO
					, SB1.B1_FILIAL
					, AA3.AA3_NUMSER
				FROM %Table:SB1% SB1
					INNER JOIN %Table:SB5% SB5 ON 
									SB5.B5_FILIAL = SB1.B1_FILIAL
									AND SB5.B5_COD = SB1.B1_COD
									AND SB5.%NotDel%
									AND SB5.B5_TPISERV = '5'
									AND SB5.B5_GSLE = '1'
					INNER JOIN %Table:AA3% AA3 ON
									AA3.%NotDel%
									AND AA3.AA3_EQALOC = '1'
									AND AA3.AA3_FILORI = ' '
									AND AA3.AA3_CODPRO = SB1.B1_COD
									AND SUBSTRING( AA3.AA3_FILIAL, 1, %Exp:nTamFilAA3% ) = SUBSTRING( SB1.B1_FILIAL, 1, %Exp:nTamFilAA3% )
				WHERE 
					SB1.%NotDel%
			EndSql
			
			If (cTmpQry)->(!EOF())
				
				While (cTmpQry)->(!EOF())
					AA3->(DbGoTo((cTmpQry)->AA3RECNO))
					Reclock("AA3",.F.)
					AA3->AA3_FILORI := (cTmpQry)->B1_FILIAL
					AA3->(MsUnlock())
					
					(cTmpQry)->(DbSkip())
				End
			EndIf
			
			(cTmpQry)->(DbCloseArea())
			
		EndIf
		
		//------------------------------------------------------
		//  Realiza o preenchimento dos campos de cliente 
		DbSelectArea("SC5")
		DbSelectArea("TEW")
		
		If TEW->( FieldPos( "TEW_CODCLI" ) ) > 0 .And. TEW->( FieldPos( "TEW_LOJCLI" ) ) > 0
			
			//-------------------------------------
			//   identifica as movimentações que ainda não foram retornadas e os respectivos pedidos de venda associados
			BeginSql Alias cTmpQry
				SELECT TEW.R_E_C_N_O_ TEWRECNO
					, SC5.R_E_C_N_O_ SC5RECNO 
				FROM %Table:TEW% TEW
					INNER JOIN %Table:SC5% SC5 ON
										C5_FILIAL = TEW_FILIAL
										AND C5_NUM = TEW_NUMPED
										AND SC5.%NotDel%
				WHERE 
					TEW.%NotDel%
					AND TEW_DTRFIM = ' '
			EndSql
			
			While (cTmpQry)->(!EOF())
				SC5->( DbGoTo( (cTmpQry)->SC5RECNO ) )
				TEW->( DbGoTo( (cTmpQry)->TEWRECNO ) )
				
				Reclock("TEW", .F.)
					TEW->TEW_CODCLI := SC5->C5_CLIENTE
					TEW->TEW_LOJCLI := SC5->C5_LOJACLI
				TEW->( MsUnlock() )
				
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
			
		EndIf
		
		//  preenche o campo de filial do cabeçalho das Ordens de Serviço para montagem de equipamentos
		DbSelectArea("AB6")
		If AB6->( FieldPos( "AB6_FIORCS" ) ) > 0
			BeginSql Alias cTmpQry
				SELECT AB6.R_E_C_N_O_ AB6RECNO
				FROM %Table:AB6% AB6
				WHERE AB6_CDORCS <> ' '
					AND AB6.%NotDel%
			EndSql
			
			While (cTmpQry)->(!EOF())
				
				AB6->( DbGoTo( (cTmpQry)->AB6RECNO ) )
				
				Reclock("AB6",.F.)
					AB6->AB6_FIORCS := AB6->AB6_FILIAL
				AB6->(MsUnlock())
				
				(cTmpQry)->(DbSkip())
			End
			(cTmpQry)->(DbCloseArea())
	
		EndIf
		
		//  Preenche o campo de filial do documento de saída na tabela TWI
		DbSelectArea("TWI")
		If TWI->(FieldPos("TWI_FILNF")) > 0 
			
			BeginSql Alias cTmpQry
				SELECT TWI.R_E_C_N_O_ TWIRECNO
				FROM %Table:TWI% TWI
				WHERE TWI_NUMNF <> ' '
					AND TWI.%NotDel%
					AND TWI_FILNF = ' '
			EndSQL
			
			While (cTmpQry)->(!EOF())
				
				TWI->( DbGoTo( (cTmpQry)->TWIRECNO ) )
				
				Reclock("TWI",.F.)
					TWI->TWI_FILNF := TWI->TWI_FILIAL
				TWI->(MsUnlock())
				
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
		EndIf
		
		//  Preenche o campo de filial do documento de saída na tabela TWP
		DbSelectArea("TWP")
		If TWP->(FieldPos("TWP_FILNF")) > 0
			
			BeginSql Alias cTmpQry
				SELECT TWP.R_E_C_N_O_ TWPRECNO
				FROM %Table:TWP% TWP
				WHERE TWP_NUMNF <> ' '
					AND TWP.%NotDel%
					AND TWP_FILNF = ' '
			EndSQL
			
			While (cTmpQry)->(!EOF())
				
				TWP->(DbGoTo( (cTmpQry)->TWPRECNO ))
				
				Reclock("TWP",.F.)
					TWP->TWP_FILNF := TWP->TWP_FILIAL
				TWP->(MsUnlock())
				
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
		EndIf
		
		//  Preenche o campo de quantidade de saída e/ou retorno na tabela TWR
		DbSelectArea("TWR")
		If TWR->(FieldPos("TWR_QTDSAI")) > 0 .And. TWR->(FieldPos("TWR_QTDRET")) > 0
			
			BeginSql Alias cTmpQry
				SELECT TWR.R_E_C_N_O_ TWRRECNO
				FROM %Table:TWR% TWR
				WHERE TWR_SAIDOC <> ' '
					AND TWR.%NotDel%
					AND TWR_QTDSAI = 0
			EndSQL
			
			While (cTmpQry)->(!EOF())
				
				TWR->(DbGoTo((cTmpQry)->TWRRECNO))
				
				Reclock("TWR",.F.)
				TWR->TWR_QTDSAI := 1
				
				// caso tenha acontecido o retorno da NF tbm atualiza a qtde de retorno
				If TWR->TWR_ENTDOC <> ' '
					TWR->TWR_QTDRET := 1
				EndIf
				
				TWR->(MsUnlock())
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
		EndIf
	
		DbSelectArea("TFG")
		DbSelectArea("TFJ")
		If TFG->( FieldPos("TFG_CONTRT") ) > 0 .And. TFG->( FieldPos("TFG_CONREV") ) > 0 
	
			BeginSql Alias cTmpQry
				SELECT TFG.R_E_C_N_O_ TFGRECNO
					, TFJ.R_E_C_N_O_ TFJRECNO
				FROM %Table:TFG% TFG
					//-- JOIN PELOS RECURSOS HUMANOS
					LEFT JOIN %Table:TFF% TFF ON TFF_FILIAL = TFG_FILIAL
											AND TFF_COD = TFG_CODPAI
											AND TFF.%NotDel%
					LEFT JOIN %Table:TFL% TFL1 ON TFL1.TFL_FILIAL = TFF_FILIAL
											AND TFL1.TFL_CODIGO = TFF_CODPAI
											AND TFL1.%NotDel%
					//-- JOIN PELOS LOCAIS	
					LEFT JOIN %Table:TFL% TFL2 ON TFL2.TFL_FILIAL = TFG_FILIAL
											AND TFL2.TFL_CODIGO = TFG_CODPAI
											AND TFL2.%NotDel%
					//-- TFJ
					INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = TFG_FILIAL
											AND ( ( TFJ_CODTAB = ' ' AND TFJ_CODIGO = TFL1.TFL_CODPAI )
												OR ( TFJ_CODTAB <> ' ' AND TFJ_CODIGO = TFL2.TFL_CODPAI ) )
											AND TFJ_CONTRT <> ' '
											AND TFJ.%NotDel%
				WHERE TFG_CONTRT = ' '
					AND TFG_CONREV = ' '
					AND TFG.%NotDel%
			EndSQL
	
			While (cTmpQry)->(!EOF())
				TFJ->( DbGoTo( (cTmpQry)->TFJRECNO ) )
				TFG->( DbGoTo( (cTmpQry)->TFGRECNO ) )
	
				Reclock("TFG", .F.)
					TFG->TFG_CONTRT := TFJ->TFJ_CONTRT
					TFG->TFG_CONREV := TFJ->TFJ_CONREV
				TFG->( MsUnlock() )
	
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
		EndIf
		
		DbSelectArea("TFH")
		DbSelectArea("TFJ")
		If TFH->( FieldPos("TFH_CONTRT") ) > 0 .And. TFH->( FieldPos("TFH_CONREV") ) > 0 
	
			BeginSql Alias cTmpQry
				SELECT TFH.R_E_C_N_O_ TFHRECNO
					, TFJ.R_E_C_N_O_ TFJRECNO
				FROM %Table:TFH% TFH
					//-- JOIN PELOS RECURSOS HUMANOS
					LEFT JOIN %Table:TFF% TFF ON TFF_FILIAL = TFH_FILIAL
											AND TFF_COD = TFH_CODPAI
											AND TFF.%NotDel%
					LEFT JOIN %Table:TFL% TFL1 ON TFL1.TFL_FILIAL = TFF_FILIAL
											AND TFL1.TFL_CODIGO = TFF_CODPAI
											AND TFL1.%NotDel%
					//-- JOIN PELOS LOCAIS	
					LEFT JOIN %Table:TFL% TFL2 ON TFL2.TFL_FILIAL = TFH_FILIAL
											AND TFL2.TFL_CODIGO = TFH_CODPAI
											AND TFL2.%NotDel%
					//-- TFJ
					INNER JOIN %Table:TFJ% TFJ ON TFJ_FILIAL = TFH_FILIAL
											AND ( ( TFJ_CODTAB = ' ' AND TFJ_CODIGO = TFL1.TFL_CODPAI )
												OR ( TFJ_CODTAB <> ' ' AND TFJ_CODIGO = TFL2.TFL_CODPAI ) )
											AND TFJ_CONTRT <> ' '
											AND TFJ.%NotDel%
				WHERE TFH_CONTRT = ' '
					AND TFH_CONREV = ' '
					AND TFH.%NotDel%
			EndSQL
	
			While (cTmpQry)->(!EOF())
				TFJ->( DbGoTo( (cTmpQry)->TFJRECNO ) )
				TFH->( DbGoTo( (cTmpQry)->TFHRECNO ) )
	
				Reclock("TFH", .F.)
					TFH->TFH_CONTRT := TFJ->TFJ_CONTRT
					TFH->TFH_CONREV := TFJ->TFJ_CONREV
				TFH->( MsUnlock() )
	
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
		EndIf
	
	
	//Atualiza o campo Produto nas ocorrencias de munição
	DbSelectArea("TET")
	If TET->( FieldPos("TET_PRODUT") ) > 0
		
		BeginSql Alias cTmpQry
			SELECT 
				SB1.R_E_C_N_O_ SB1RECNO
				, SB1.B1_FILIAL
				, SB1.B1_COD
				, SB5.R_E_C_N_O_ SB5RECNO
				, SB5.B5_FILIAL
				, SB5.B5_COD
				, TET.TET_CODMUN
				, TET.TET_CDOCOR
				, TET.R_E_C_N_O_ TETRECNO
			FROM %Table:SB1% SB1
				INNER JOIN %Table:SB5% SB5 ON 
						SB5.B5_FILIAL = SB1.B1_FILIAL
						AND SB5.B5_COD = SB1.B1_COD
						AND SB5.B5_TPISERV = '3'
						AND SB5.%NotDel%
				INNER JOIN %Table:TE2% TE2 ON
						TE2.TE2_CODPRO = SB1.B1_COD
						AND TE2.%NotDel%
				INNER JOIN %Table:TET% TET ON
						TET.TET_CODMUN = TE2.TE2_CODMUN
						AND TET.%NotDel%
							
			WHERE 
			SB1.%NotDel%
		
		EndSQL
		
		While (cTmpQry)->(!EOF())
			TET->( DbGoTo( (cTmpQry)->TETRECNO ) )

			Reclock("TET", .F.)
				TET->TET_PRODUT := (cTmpQry)->B1_COD
			TET->( MsUnlock() )

			(cTmpQry)->(DbSkip())
		End
		
		(cTmpQry)->(DbCloseArea())
		
	EndIf
	
	//Atualiza o campo de produto na tabela TFO
	DbSelectArea("TFO")
	If TFO->( FieldPos("TFO_PRODUT") ) > 0
		
		BeginSql Alias cTmpQry
			SELECT  TFO.TFO_FILIAL,
				TFO.TFO_CDMOV,
				TFO.TFO_ITMOV,
				TFO.TFO_ITCOD,
				TFO.R_E_C_N_O_ TFORECNO,
				TE0.TE0_FILIAL,
				TE0.TE0_COD,
				TE0.TE0_CODPRO,
				TE0.R_E_C_N_O_ TE0RECNO,
				SB1.R_E_C_N_O_ SB1RECNO,
				SB1.B1_FILIAL,
				SB1.B1_COD,
				SB5.R_E_C_N_O_ SB5RECNO,
				SB5.B5_FILIAL,
				SB5.B5_COD
			FROM %Table:TFO% TFO
				INNER JOIN %Table:TE0% TE0 ON 
					TFO.TFO_ITMOV = '1' 
					AND TFO.TFO_ITCOD = TE0.TE0_COD 
					AND TE0.%NotDel%
				INNER JOIN %Table:SB1% SB1 ON
					SB1.B1_COD = TE0.TE0_CODPRO
					AND SB1.%NotDel%	
				INNER JOIN %Table:SB5% SB5 ON 
					SB5.B5_FILIAL = SB1.B1_FILIAL
					AND SB5.B5_COD = SB1.B1_COD
					AND SB5.B5_TPISERV = '1'
					AND SB5.%NotDel%
			WHERE 
				TFO.%NotDel%	
			UNION 
			SELECT  TFO.TFO_FILIAL,
					TFO.TFO_CDMOV,
					TFO.TFO_ITMOV,
					TFO.TFO_ITCOD,
					TFO.R_E_C_N_O_ TFORECNO,
					TE1.TE1_FILIAL,
					TE1.TE1_CODCOL,
					TE1.TE1_CODPRO,
					TE1.R_E_C_N_O_ TE1RECNO,
					SB1.R_E_C_N_O_ SB1RECNO,
					SB1.B1_FILIAL,
					SB1.B1_COD,
					SB5.R_E_C_N_O_ SB5RECNO,
					SB5.B5_FILIAL,
					SB5.B5_COD
			FROM %Table:TFO% TFO
				INNER JOIN %Table:TE1% TE1 ON 
					TFO.TFO_ITMOV = '2' 
					AND TFO.TFO_ITCOD = TE1.TE1_CODCOL 
					AND TE1.%NotDel%
				INNER JOIN %Table:SB1% SB1 ON
					SB1.B1_COD = TE1.TE1_CODPRO
					AND SB1.%NotDel%	
				INNER JOIN %Table:SB5% SB5 ON 
					SB5.B5_FILIAL = SB1.B1_FILIAL
					AND SB5.B5_COD = SB1.B1_COD
					AND SB5.B5_TPISERV = '2'
					AND SB5.%NotDel%	
			WHERE 
				TFO.%NotDel%					
			UNION
			SELECT  TFO.TFO_FILIAL,
					TFO.TFO_CDMOV,
					TFO.TFO_ITMOV,
					TFO.TFO_ITCOD,
					TFO.R_E_C_N_O_ TFORECNO,
					TE2.TE2_FILIAL,
					TE2.TE2_CODMUN,
					TE2.TE2_CODPRO,
					TE2.R_E_C_N_O_ TE2RECNO,
					SB1.R_E_C_N_O_ SB1RECNO,
					SB1.B1_FILIAL,
					SB1.B1_COD,
					SB5.R_E_C_N_O_ SB5RECNO,
					SB5.B5_FILIAL,
					SB5.B5_COD
			FROM %Table:TFO% TFO
				INNER JOIN %Table:TE2% TE2 ON 
					TFO.TFO_ITMOV = '3' 
					AND TFO.TFO_ITCOD = TE2.TE2_CODMUN 
					AND TE2.%NotDel%
				INNER JOIN %Table:SB1% SB1 ON
					SB1.B1_COD = TE2.TE2_CODPRO
					AND SB1.%NotDel%	
				INNER JOIN %Table:SB5% SB5 ON 
					SB5.B5_FILIAL = SB1.B1_FILIAL
					AND SB5.B5_COD = SB1.B1_COD
					AND SB5.B5_TPISERV = '3'
					AND SB5.%NotDel%	
			WHERE 
				TFO.%NotDel%	
		EndSql
		
		While (cTmpQry)->(!EOF())
			TFO->( DbGoTo( (cTmpQry)->TFORECNO ) )

			Reclock("TFO", .F.)
				TFO->TFO_PRODUT := (cTmpQry)->B1_COD
			TFO->( MsUnlock() )

			(cTmpQry)->(DbSkip())
		End
		
		(cTmpQry)->(DbCloseArea())
		
	EndIf 
	
		//Atualiza o campo Produto na tabela de historico da munição
		DbSelectArea("TFP")
		If TFP->( FieldPos("TFP_PRODUT") ) > 0
			
			BeginSql Alias cTmpQry
				SELECT 
					SB1.R_E_C_N_O_ SB1RECNO
					, SB1.B1_FILIAL
					, SB1.B1_COD
					, SB5.R_E_C_N_O_ SB5RECNO
					, SB5.B5_FILIAL
					, SB5.B5_COD
					, TFP.TFP_CODMUN
					, TFP.R_E_C_N_O_ TFPRECNO
				FROM %Table:SB1% SB1
					INNER JOIN %Table:SB5% SB5 ON 
							SB5.B5_FILIAL = SB1.B1_FILIAL
							AND SB5.B5_COD = SB1.B1_COD
							AND SB5.B5_TPISERV = '3'
							AND SB5.%NotDel%
					INNER JOIN %Table:TE2% TE2 ON
							TE2.TE2_CODPRO = SB1.B1_COD
							AND TE2.%NotDel%
					INNER JOIN %Table:TFP% TFP ON
							TFP.TFP_CODMUN = TE2.TE2_CODMUN
							AND TFP.%NotDel%
								
				WHERE 
				SB1.%NotDel%
			
			EndSQL
			
			While (cTmpQry)->(!EOF())
				TFP->( DbGoTo( (cTmpQry)->TFPRECNO ) )
	
				Reclock("TFP", .F.)
					TFP->TFP_PRODUT := (cTmpQry)->B1_COD
				TFP->( MsUnlock() )
	
				(cTmpQry)->(DbSkip())
			End
			
			(cTmpQry)->(DbCloseArea())
			
		EndIf
	
	Endif

Return Nil

//==================================================================================================================== 
/*/{Protheus.doc} AjustaTEC(cFonte) 
Função para realização do AjustaSX3 durante release. 
Os ajustes realizados nesta função devem obrigatóriamente estar contido na função de migração RUP_TEC. 
Os ajustes realizados nesta função serão removidos a cada release. 
@param  cFonte  - Fonte no qual o ajusta será realizado. 
@since 29/03/2016 
@version P12 
/*/
//==================================================================================================================== 
Function AjustaTEC(cFonte)
Local	lRet	:= .T.
Local 	cTmpQry	:= GetNextAlias()
Default	cFonte	:= ""

If cFonte == "TECA743"
	BeginSql Alias cTmpQry
		SELECT  TFI_COD
			   ,TFI_CONENT
			   ,TFI_CONCOL
		FROM %Table:TFI% TFI
		WHERE TFI.TFI_FILIAL   = %xFilial:TFI%
			AND TFI.TFI_CONENT = %Exp:' '% 
			OR TFI.TFI_CONCOL  = %Exp:' '% 
			AND TFI.%NotDel%
	EndSql

	DbSelectArea("TFI")
	TFI->(DbSetOrder(1))

	While (cTmpQry)->(!Eof())
		If TFI->(DbSeek(xFilial("TFI")+(cTmpQry)->TFI_COD))		

			If TFI->TFI_CONENT == " "
				Reclock("TFI",.F.)
					TFI->TFI_CONENT := "2"
				TFI->(MsUnlock())
			Endif

			If TFI->TFI_CONCOL == " "
				Reclock("TFI",.F.)
					TFI->TFI_CONCOL := "2"
				TFI->(MsUnlock())
			Endif
		Endif
		(cTmpQry)->(DbSkip())
	EndDo
	(cTmpQry)->(DbCloseArea())
Endif

Return lRet
