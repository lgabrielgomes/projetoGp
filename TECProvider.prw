
#INCLUDE 'TOTVS.CH'
#INCLUDE "PARMTYPE.CH"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "FWEVENTVIEWCONSTS.CH"

//-----------------------------------------------------------------
/*/{Protheus.doc} New()
Classe provedora dos dados da Base de Atendimento

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/
//--------------------------------------------------------------------
CLASS TECProvider

Data cNumSer		AS CHARACTER
Data cFil			AS CHARACTER
Data cProd			AS CHARACTER
Data lIdUnico		AS LOGICAL
Data lAtivoFixo	AS LOGICAL
Data lValido		AS LOGICAL
Data lEquipLoc	AS LOGICAL
Data lBaseBloq	AS LOGICAL
Data cDesc			AS CHARACTER
Data cProdGrp		AS CHARACTER
Data cProdTipo	AS CHARACTER
Data cProdUm		AS CHARACTER
Data cFilOri		AS CHARACTER
Data nPrcVen		AS NUMBER
Data nPeso			AS NUMBER
Data cProdConta	AS CHARACTER
Data cProdCC		AS CHARACTER
Data cProdItem	AS CHARACTER
Data aAtivos		AS ARRAY
Data aError		AS ARRAY
Data nQtdATF		AS NUMBER
Data nRecNoAA3	AS NUMBER
Data nRecNoTWH	AS NUMBER

METHOD NEW()
//-- Metodos de Inicialização 
METHOD Initialize()
METHOD Load()
METHOD LoadSB1()
METHOD LoadAA3()
METHOD LoadSB5()
METHOD LoadTWH()

//-- Metodos de CRUD 
METHOD InsertTWH()

METHOD InsertTWI()
METHOD UpdateTWI()
METHOD DeleteTWI()

METHOD InsertTWP()
METHOD DeleteTWP()

METHOD InsertTWU()
METHOD UpdateTWU()
METHOD DeleteTWU()

METHOD ShowErro()

//-- Metodos de alteração da base
METHOD BloqueiaBase()
METHOD DesbloqueiaBase()
METHOD AlteraFilOriBase()
METHOD AtStatusBase()

//-- Metodos de Saldo
METHOD SaldoDisponivel()
METHOD SaldoTotal()
METHOD SaldoAdquirido()
METHOD SelectNotId()
METHOD SaldoLocado()
METHOD SaldoReservado()
METHOD SaldoManutencao()
METHOD SaldoTravado()
METHOD SaldoBloqueado()

ENDCLASS

//-----------------------------------------------------------------
/*/{Protheus.doc} New()
Método construtor da classe

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/
//--------------------------------------------------------------------
METHOD New(cNumSer,cFil,lLoadAll) CLASS TECProvider
Default lLoadAll := .F.

Self:Initialize()

If SuperGetMv('MV_TECATF', .F.,'N') == 'S'
	If Empty(cFil)
		Self:cFil := cFilAnt
	Else
		Self:cFil := cFil
	EndIf
      
	If !Empty(cNumSer)
		Self:cNumSer := Padr(cNumSer,TamSx3('AA3_NUMSER')[1])
		Self:Load(lLoadAll)
	EndIf
Else
	Self:lValido := .F.
	Aadd(Self:aError,'Objeto inválido, parâmetro de integração MV_TECATF desativado')
	Aadd(Self:aError,'Ative o parâmetro')
EndIf

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} New()
Método construtor da classe

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/
//--------------------------------------------------------------------
METHOD Initialize() CLASS TECProvider

Self:cNumSer               := ""     
Self:cFil                  := cFilAnt         
Self:cFilOri        := ""
Self:cProd                 := ""
Self:lIdUnico              := .F. 
Self:lAtivoFixo      := .F.
Self:lEquipLoc             := .F.
Self:aAtivos         := {}
Self:aError          := {}
Self:nRecNoAA3       := 0
Self:nRecNoTWH       := 0
Self:nQtdATF               := 0
Self:lBaseBloq       := .F.
Self:cDesc			:= ""
Self:cProdGrp		:= ""
Self:cProdTipo	:= ""
Self:cProdUm		:= ""
Self:nPrcVen		:= 0 
Self:nPeso			:= 0
Self:cProdConta	:= ""
Self:cProdCC		:= ""
Self:cProdItem	:= ""
Self:lValido := .T.  

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} Load()
Metodo de carga dos dados

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/
//--------------------------------------------------------------------
METHOD Load(lLoadAll) CLASS TECProvider
If Self:LoadAA3()    
	If !Self:lEquipLoc
   		Aadd(Self:aError,'Objeto inválido, Base de atendimento não é de locação') 
       Self:lValido := .F.  
      EndIf 
Else
	Aadd(Self:aError,'Objeto inválido, Base de atendimento não encontrada') 
  	Self:lValido := .F.
EndIf

If Self:lValido  .And. !Self:LoadSB1()
	Aadd(Self:aError,'Objeto inválido, Produto não encontrado no cadastro de Produtos')
  	Self:lValido := .F.
EndIf
      
If Self:lValido  .And. !Self:LoadSB5()
	Aadd(Self:aError,'Objeto inválido, Complemento de produto não encontrado')
  	Self:lValido := .F.
EndIf

If Self:lValido
	Self:LoadTWH(lLoadAll)
EndIf             

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} LoadAA3
Posiciona Registro na AA3

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD LoadAA3() CLASS TECProvider
Local lRet := .F.
Local aArea       := GetArea()

AA3->(DbSetOrder(6))  // AA3_FILIAL+AA3_NUMSER+AA3_FILORI
      
lRet := AA3->(DbSeek(xFilial("AA3",Self:cFil)+Self:cNumSer+Self:cFilOri))
If lRet
	Self:nRecNoAA3       :=    AA3->(RecNo())  
	
   	Self:cProd           :=    AA3->AA3_CODPRO
   	Self:lEquipLoc 		:=    AA3->AA3_EQALOC == '1'
   	Self:lBaseBloq       :=    AA3->AA3_MSBLQL == '1'
   	Self:cFilOri         :=    AA3->AA3_FILORI
EndIf
                             
RestArea(aArea)
Return lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} LoadSB1
Posiciona Registro na SB1 e alimenta propriedades da classe

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD LoadSB1() CLASS TECProvider
Local lRet := .F.
Local aArea       := GetArea()

dbSelectArea('SB1')
SB1->(DbSetOrder(1))
      
lRet := SB1->(DbSeek(xFilial("SB1",Self:cFil)+Self:cProd))
If lRet
	
	Self:cDesc	 := SB1->B1_DESC	
	Self:cProdGrp	:= SB1->B1_GRUPO	
	Self:cProdTipo := SB1->B1_TIPO	
	Self:cProdUm	:= SB1->B1_UM	
	Self:nPrcVen	:= SB1->B1_PRV1	
	Self:nPeso		:= SB1->B1_PESO	
	Self:cProdConta	:= SB1->B1_CONTA
	Self:cProdCC	:= SB1->B1_CC	
	Self:cProdItem := SB1->B1_ITEMCC		  
EndIf
                             
RestArea(aArea)
Return lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} LoadSB5
Posiciona Registro na SB5

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD LoadSB5() CLASS TECProvider
Local lRet := .F.
Local aArea       := GetArea()

SB5->(DbSetOrder(1))
      
lRet := SB5->(DbSeek(xFilial("SB5",Self:cFil)+Self:cProd))
If lRet
	Self:lIdUnico := SB5->B5_ISIDUNI <> '2'  
EndIf
                             
RestArea(aArea)
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} LoadTHW
Posiciona Registro na AA3

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD LoadTWH(lLoad) CLASS TECProvider
Local aArea             := GetArea()
Local oModel980         := Nil
Local oTWHDetail        := Nil
Local nI                     := 0


TWH->(DbSetOrder(1))
    
Self:lAtivoFixo := TWH->(DbSeek(xFilial("TWH",Self:cFil)+Self:cNumSer+Self:cFil))

If Self:lAtivoFixo
	Self:nRecNoTWH := TWH->(RecNo())
    If lLoad 
      oModel980   := FwLoadModel('TECA980')
      oTWHDetail  := oModel980:GetModel('TWH_GRID')

      oModel980:SetOperation(MODEL_OPERATION_VIEW)
      oModel980:Activate()
      
     
      For nI := 1 To oTWHDetail:Length()
            oTWHDetail:GoLine(nI)
     		Aadd(Self:aAtivos,{TWH->TWH_FILORI,oTWHDetail:GetValue('TWH_ATVCBA'),oTWHDetail:GetValue('TWH_ATVITE'),;
                                                                 oTWHDetail:GetValue('TWH_QUANTD')})
     		Self:nQtdATF += oTWHDetail:GetValue('TWH_QUANTD')                                                                                                     
      Next nI 
	EndIf                             
EndIf                             
RestArea(aArea)
Return 

//-----------------------------------------------------------------
/*/{Protheus.doc} ShowErro

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD ShowErro() CLASS TECProvider
Local cErro := ""
Local cSolucao := ""
Local nLen := Len(Self:aError) 


If nLen > 0
	cErro := Self:aError[1]
   	If    nLen > 1
  		cSolucao := Self:aError[2]
    EndIf
Else
	cErro := "Objeto inválido"
EndIf
Help("",1,"TECERROR",,cErro,4,10,,,,,,{cSolucao})


Return 

//-----------------------------------------------------------------
/*/{Protheus.doc} InsertTWH
Insere Registro na TWH

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD InsertTWH(cFilAtivo,cAtivo,cItem,nQtd) CLASS TECProvider
Local oModel980   := FwLoadModel('TECA980')
Local oTWHMaster  := oModel980:GetModel("TWH_CABEC")
Local oTWHDetail  := oModel980:GetModel("TWH_GRID")
Local lRet              := .F.

If Self:lAtivoFixo
    TWH->(DbGoto(Self:nRecNoTWH))   
    oModel980:SetOperation(MODEL_OPERATION_UPDATE)
    oModel980:Activate()
      
    oTWHDetail:Addline()
    oTWHDetail:LoadValue('TWH_ATVCBA',cAtivo)
    oTWHDetail:LoadValue('TWH_ATVITE',cItem)
    oTWHDetail:LoadValue('TWH_DTINVI',dDatabase)
    oTWHDetail:LoadValue('TWH_QUANTD',nQtd)
Else
      oModel980:SetOperation(MODEL_OPERATION_INSERT)
      oModel980:Activate()
      
      oTWHMaster:LoadValue('TWH_BASE',Self:cNumSer)
      oTWHMaster:LoadValue('TWH_FILORI',cFilAtivo)
      oTWHDetail:LoadValue('TWH_ATVCBA',cAtivo)
      oTWHDetail:LoadValue('TWH_ATVITE',cItem)
      oTWHDetail:LoadValue('TWH_DTINVI',dDatabase)
      oTWHDetail:LoadValue('TWH_QUANTD',nQtd)
  	  Self:lAtivoFixo := .T.
EndIf

If oModel980:VldData()
      lRet := oModel980:CommitData()
EndIf

If !lRet
	Aadd(Self:aError,oModel980:aErrorMessage[6])
  	Aadd(Self:aError,oModel980:aErrorMessage[7])
EndIf
      
Return lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} InsertTWI
Insere Registro na TWI

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD InsertTWI(cIdReg,cBase,nQuant,cCodCli,cLoja,cExigeNF) CLASS TECProvider
Local aArea			:= GetArea()
Local cCodigo		:= ''
Default cIdReg 		:= ''
Default cExigeNF 	:= '1'
Default cFilNF 		:= xFilial("SD2")

If !Empty(cIdReg)
	
	DbSelectArea('TWI')
	TWI->(DbSetOrder(1)) //TWI_FILIAL+TWI_IDREG
	      
	If TWI->(!DbSeek(xFilial("TWI")+cIdReg))
		RecLock( 'TWI',.T.)
			TWI->TWI_FILIAL = 	xFilial('TWI')
			TWI->TWI_IDREG 	= 	cIdReg
			TWI->TWI_BASE 	=	cBase
			TWI->TWI_QTDSAI = 	nQuant
			TWI->TWI_CODCLI = 	cCodCli
			TWI->TWI_LOJA 	= 	cLoja
			TWI->TWI_LIBERA	= 	'2'		
			TWI->TWI_EXIGNF = 	cExigeNF
		TWI->(MsUnlock())
	Endif
Endif

RestArea(aArea)

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} DeleteTWI
Insere Registro na TWI

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD DeleteTWI(cIdReg,cFilMov) CLASS TECProvider
Local aArea       := GetArea()

Default cFilMov := xFilial('TWI',Self:cFil)

If TWI->(DbSeek(cFilMov+cIdReg))
      RecLock('TWI', .F.)
      TWI->(dbDelete())
      TWI->(MsUnlock())
EndIf    

RestArea(aArea)

Return 
 

//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoDisponivel
Retorna o saldo disponivel para utilização na locacao de equipamentos

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD SaldoDisponivel() CLASS TECProvider
Local nSldDsp	:= 0

nSldDsp := Self:SaldoTotal() - Self:SaldoLocado() - Self:SaldoBloqueado()

Return nSldDsp

//-----------------------------------------------------------------
/*/{Protheus.doc} BloqueiaBase

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD BloqueiaBase() CLASS TECProvider
Local aArea       := GetArea()
Local lRet			:= .T.
      
AA3->(DbGoto(Self:nRecNoAA3))

RecLock( 'AA3',.F.)
AA3->AA3_MSBLQL := '1'
AA3->(MsUnlock())

RestArea(aArea)
Return lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} DesbloqueiaBase

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD DesbloqueiaBase() CLASS TECProvider
Local aArea       := GetArea()
      
AA3->(DbGoto(Self:nRecNoAA3))

RecLock( 'AA3',.F.)
AA3->AA3_MSBLQL := '2'
AA3->(MsUnlock())   

RestArea(aArea)
Return

//-----------------------------------------------------------------
/*/{Protheus.doc} UpdateTWI
Update TWI

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD UpdateTWI(cIdReg,cNota,cSerie,cItem,lLiberado,cFilNF,cFilMov) CLASS TECProvider
Local aArea       := GetArea()
Default cNota     := ""
Default cSerie    := ""
Default cItem     := ""
Default cFilNF    := xFilial("SD2")  // filial para associar a NF de saída
Default cFilMov   := xFilial('TWI',Self:cFil)  // filial para pesquisar o registro da TWI

TWI->(DbSetOrder(1))
If TWI->(DbSeek(cFilMov+cIdReg)) 
      RecLock( 'TWI',.F.)
            
      TWI->TWI_NUMNF = cNota
      TWI->TWI_SERNF = cSerie
      //TWI->TWI_SDOCNF = cSerie
      TWI->TWI_ITEMNF = cItem
      
      If lLiberado 
      		TWI->TWI_LIBERA = '1'
      		TWI->TWI_DTSAI  = dDataBase
      Else
      		TWI->TWI_LIBERA = '2'
      EndIf
      
      TWI->TWI_FILNF := cFilNF
      
      TWI->(MsUnlock())
EndIf    

RestArea(aArea)

Return




///////////////////////------------------------
//-- Funções não pertecentes a classe
///////////////////////------------------------

//-----------------------------------------------------------------
/*/{Protheus.doc} TcBxAtf
Rotina de baixa entre filiais do Ativo Fixo 

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function TcBxAtf(cFilAtivo,cAtivo,cItem,nQtd,lBaixa)
Local aArea					 := GetArea()
Local aAreaSN1				 := SN1->(GetArea())
Local oTecProvider           := Nil
Local nRecNo                 := 0
Local cNumSer                := ""
Local cNumSerNew             := ""
Local lRet                   := .T.

//1* Coleto o numero da base de atendimento a partir do codigo do ativo
cNumSer := GetNumSer(cFilAtivo,cAtivo,cItem)

If !(Empty(cNumSer))
	
	//2* Instancia a classe de integracao e valida se a Base de Atendimento é valida e relacionada a algum ativo
	oTecProvider := TECProvider():New(cNumSer,cFilAtivo,.T.)
	
	If oTecProvider:lValido
		//Begin Transaction				  
		
		If oTecProvider:lAtivoFixo
		
			//3* Antes de prosseguir com a baixa, valida se a quantidade disponivel 
			//para locação é maior ou igual a quantidade baixada. Caso nao seja, significa que esta tudo locado/bloqueado/reservado 
			If oTecProvider:SaldoDisponivel() >= nQtd
			
				//4* Tratamento caso seja IdUnico. 
				If oTecProvider:lIdUnico 
					If lBaixa 
						oTecProvider:BloqueiaBase()
					Else
						oTecProvider:DesbloqueiaBase()                             
					EndIf                                                                        
				
				//4 * Tratamento caso seja Granel
				Else
					If lBaixa 
						If ((oTecProvider:SaldoAdquirido() - nQtd) <= 0)                               
							oTecProvider:BloqueiaBase()        
						EndIf
					Else
						If oTecProvider:lBaseBloq .And. oTecProvider:nQtdATF > 0                                   
							oTecProvider:DesbloqueiaBase()           
						EndIf
					EndIf                                                                                                                
				EndIf
			Else
				//Sem saldo disponivel.
				Aadd(oTecProvider:aError,'Saldo de Transferencia não disponivel para movimentação. Consulte as reservas, locações e bloqueios deste ativo no GS')
				lRet := .F.
			EndIf
		EndIf                                    
       
       //Por fim, exibe eventuais mensagens de alerta e valida a transacao no banco de dados     
		If !(lRet)
			//DisarmTransaction()
			If Len(oTecProvider:aError) > 0
				oTecProvider:ShowErro()
			EndIf	            
       Else
       	//End Transaction
       EndIf		
	EndIf
EndIf

//Destroi objetos e limpa a memoria
TecDestroy(oTecProvider)
	
RestArea(aAreaSN1)
RestArea(aArea)
Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} TcTransAtf
Rotina de transferencia entre filiais do Ativo Fixo 

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function TcTransAtf(cFilOrig,cAtivo,cItem,cFilDest,nQtd,lGeraNF,cNewItem,cCodBem)
Local oTecProvider   := Nil
Local nRecNo         := 0
Local cNumSer        := ""
Local cNumSerNew     := ""
Local lRet           := .T.
Local oTecDest       := Nil
Local nAcao			:= 0
Local aAcoes			:= {}
Local cFilBkp			:= ""
Local aArea			:= GetArea()
Local aAreaSN1		:= SN1->(getArea())
Local aAreaSN3		:= SN3->(getArea())
Local nRetAviso		:= 0

//1* Busco o numero da Base de Atendimento a partir do Codigo de Ativo informado (cAtivo)
cNumSer := GetNumSer(cFilOrig,cAtivo,cItem)
If !Empty(cNumSer)
	
	//Instancia a Classe de Integração
	oTecProvider := TECProvider():New(cNumSer,cFilOrig,.T.)
    
	//1* Valido se a base de atendimento possui vinculo com o ativo.
	If oTecProvider:lAtivoFixo
		//Begin Transaction
		lRet := oTecProvider:lValido   
		 
		 //2* Valido se existe a quantidade a ser transferida como disponivel no GS. Se nao houver, breca o processo
		 /*Não precisa mais ser feito. Foi implementado direto no ATFA060 via TcAtfVldMov() 
		 If lRet .and. oTecProvider:SaldoDisponivel() < nQtd
		 	lRet := .F.
			Aadd(oTecProvider:aError,'Saldo de Transferencia não disponivel para movimentação. Consulte as reservas, locações e bloqueios deste ativo no GS') 
		 EndIf*/
		 
		 //3* Valido se o item é Valido para Transferencia          	
	    If lRet 
	    	Aadd(aAcoes,"Não realizar ação neste momento")
			Aadd(aAcoes,"Transferir o saldo para outra base de atendimento")
			
			//Proteger para permitir esta opção apenas quando AA3, SB1, SA1 e SA2 forem compartilhadas
			Aadd(aAcoes,"Busca Automatica a partir do Número de Serie + Produto")
	
			If (oTecProvider:lIdUnico .Or. oTecProvider:nQtdAtf == nQtd) .And. xFilial('SB1',cFilOrig) == xFilial('SB1',cFilDest) .And. (xFilial('ST9',cFilOrig) == xFilial('ST9',cFilDest)) 
				Aadd(aAcoes,"Manter o saldo na Base (alterando a filial origem)")
			EndIf 
	 	
			nAcao := GSEscolha("Destino do(s) Equipamento(s) de Locação","Qual ação deseja tomar em relação ao saldo transferido da base de atendimento no GS",aAcoes)     		     				          	
	      	
			Do Case			
				Case nAcao == 1
					//Nao Faz Nada
					lRet := .T.
					
				Case nAcao == 2
					//Transferir o saldo para outra base de atendimento
					cFilBkp := cFilAnt
					cFilAnt := cFilDest
					While .T.
						cNumSerNew := TcPesqBsMan(cFilDest)
						If !(Empty(cNumSerNew))
							exit
						Else
							MsgAlert("Nenhuma base foi selecionada. Por favor, escolha uma base para transferencia do saldo")
						EndIf
					EndDo					
					lRet := TcTrocaBase(cNumSerNew,@oTecProvider,cFilDest,cAtivo,cNewItem,nQtd)	
					cFilAnt := cFilBkp
						
				Case nAcao == 3
					//Transferir o saldo para outra base de atendimento
					cFilBkp := cFilAnt
					cFilAnt := cFilDest
					
					While .T.
						cNumSerNew := TcPesqBsAut(cFilDest,cFilOrig,cNumSer,oTecProvider:cProd,oTecProvider:lIdUnico)						
						If Empty(cNumSerNew)							
							nRetAviso := GSEscolha("Base não encontrada","Nenhuma base valida foi encontrada na filial de destino. Deseja Selecionar uma base ou cadastrar uma nova automaticamente?",{"Seleção Manual","Cadastro Automático."})
							If nRetAviso == 2
								If oTecProvider:BloqueiaBase()
									cNumSerNew := TcNewBase(cFilOrig,cFilDest,cNumSer,oTecProvider:cProd,oTecProvider:nRecNoAA3,cNewItem,cCodBem)								
									If !(Empty(cNumSerNew))
										MsgInfo("O Equipamento: " + alltrim(cNumSerNew) + " foi cadastrado com sucesso na filial: " + cFilDest + ". É necessário complementar as suas informações de cadastro posteriormente para correta utilização.")
									EndIf
								EndIf
							ElseIf nRetAviso == 1
								cNumSerNew := TcPesqBsMan(cFilDest)
							EndIf
						Else
							MsgInfo("O Equipamento: " + alltrim(cNumSerNew) + " foi localizado com sucesso na filial: " + cFilDest)
						EndIf
						
						If !(Empty(cNumSerNew)) .Or. (nRetAviso == 0)  
							exit
						EndIf
					EndDo
					If nRetAviso > 0 
						lRet := TcTrocaBase(cNumSerNew,@oTecProvider,cFilDest,cAtivo,cNewItem,nQtd)	
						cFilAnt := cFilBkp
					EndIf
					
				Case nAcao == 4
					oTecProvider:AlteraFilOriBase(cFilDest,.T.)
					lRet := .T.		
										
			EndCase
		Else
			MsgInfo("O Equipamento: " + alltrim(cNumSerNew) + " não é um equipamento valido para movimentação no GS")		
		EndIf		
	Else
		MsgInfo("O Equipamento: " + alltrim(cNumSerNew) + " não possui vinculo criado com o Ativo Fixo movimentado")
	EndIf

	//Por fim, exibe eventuais mensagens de alerta e valida a transacao no banco de dados        
	If !lRet
	    If Len(oTecProvider:aError) > 0
	    	oTecProvider:ShowErro()		      			
	    Else
	    	If ValType(oTecDest) == 'O' .And. Len(oTecDest:aError) > 0
	        	oTecDest:ShowErro()
			EndIf                                    
		EndIf
	EndIf

	//Destroi objetos e limpa a memoria
	TecDestroy(oTecProvider)	
	TecDestroy(oTecDest)
EndIf

RestArea(aAreaSN3)
RestArea(aAreaSN1)
RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TcNewBase()
Cadastra uma nova base de atendimento em uma filial a partir de uma existente em outra.

@author Cesar A. Bianchi      
@since 15/10/2015
@version P12
@return cBase
/*/
//------------------------------------------------------------------
Static Function TcNewBase(cFilOrig,cFilDest,cNumSer,cProd,nRecAA3,cNewItem,cCodBem)
	Local cBase := ""
	Local aCabec := {} 
	Local aItens := {}
	Local aArea 	:= GetArea()
	Local cAlias := GetNextAlias()
	Local cFilBkp := ""
	Local cBaseAux	:= ""
	
	Private lMsErroAuto	:= .F.
	
	dbSelectArea('AA3')
	AA3->(dbGoTo(nRecAA3))
	cBaseAux := cNumSer
	
	//Grava os dados no cabeçalho
		
	Aadd(aCabec,{"AA3_CODPRO"	,AA3->AA3_CODPRO	,Nil})
	Aadd(aCabec,{"AA3_NUMSER"	,cNumSer			,Nil})	
	Aadd(aCabec,{"AA3_DTVEND"	,Date()			,Nil})
	Aadd(aCabec,{"AA3_EQALOC"	,AA3->AA3_EQALOC	,NIl})	
	Aadd(aCabec,{"AA3_MODELO"	,AA3->AA3_MODELO	,Nil})
	Aadd(aCabec,{"AA3_MANPRE"	,AA3->AA3_MANPRE	,Nil})
	Aadd(aCabec,{"AA3_EQ3"		,AA3->AA3_EQ3		,Nil})
	Aadd(aCabec,{"AA3_FILORI"	,cFilDest			,Nil})	
	Aadd(aCabec,{"AA3_HMEATV"	,AA3->AA3_HMEATV	,Nil})
	Aadd(aCabec,{"AA3_HMESEP"	,AA3->AA3_HMESEP	,Nil})
	Aadd(aCabec,{"AA3_HMERET"	,AA3->AA3_HMERET	,Nil})
	Aadd(aCabec,{"AA3_HMELIM"	,AA3->AA3_HMELIM	,Nil})
	If !(Empty(AA3->AA3_CODBEM))
		Aadd(aCabec,{"AA3_CODBEM"	,AA3->AA3_CODBEM	,Nil})
		Aadd(aCabec,{"AA3_CDBMFL"	,cFilDest			,Nil})
	EndIf
		
	cFilBkp := cFilAnt 
	cFilAnt := cFilDest	
	Aadd(aCabec,{"AA3_FILIAL"	,xFilial('AA3',cFilDest)	,Nil})
	
	MsExecAuto( {|w,x,y,z| TECA040(w,x,y,z)},Nil,aCabec,aItens, 3)

	If lMsErroAuto
		cBase := ""
		MostraErro()
	Else
		cBase := cBaseAux
	EndIf
	
	cFilAnt := cFilBkp
	RestArea(aArea)
Return cBase

//-------------------------------------------------------------------
/*/{Protheus.doc} TcTrocaBase()
Transfere o saldo da base de atendimento do GS de uma filial para outra na TWH

@author Cesar A. Bianchi      
@since 15/10/2015
@version P12
@return lRet
/*/
//------------------------------------------------------------------
Function TcTrocaBase(cNumSerNew,oTecProvider,cFilDest,cAtivo,cNewItem,nQtd)
	Local lRet := .T.
	Local oTecDest := Nil
	Default cNumSerNew := ""

	If !Empty(cNumSerNew)
		oTecDest := TECProvider():New(cNumSerNew,cFilDest,.T.)
		If oTecDest:lValido
			If oTecProvider:lIdUnico 
				If !oTecDest:lIdUnico
					lRet := .F.
					Aadd(oTecDest:aError,'Base de Atendimento inválida para integração')
					Aadd(oTecDest:aError,'ID único deve ser igual a SIM')
				EndIf
								
				If lRet .And. oTecDest:nQtdATF >  0
			      	lRet := .F.
     				Aadd(oTecDest:aError,'Base de Atendimento inválida para integração')
           		Aadd(oTecDest:aError,'Esta base de atendimento já possui vinculo com outro Ativo Fixo')
              EndIf
								       	               		
      		ElseIf !oTecProvider:lIdUnico .And. oTecDest:lIdUnico
            	lRet := .F.
     			Aadd(oTecDest:aError,'Base de Atendimento inválida para integração')
	          	Aadd(oTecDest:aError,'ID único deve ser igual a NÃO')
	       EndIf                                                                    
			         		
			If lRet
				lRet := oTecDest:InsertTWH(cFilDest,cAtivo,cNewItem,nQtd)
				If lRet 
					oTecDest:DesbloqueiaBase()
				Else
					Aadd(oTecDest:aError,'Não foi possivel incluir valores na relacao base x ativo - Tabela TWH.')
				Endif
			EndIf
		Else
			lRet := .F.                                                                                   
		EndIf
	//Else
		//lRet := MsgYesNo('Deseja mesmo assim efetivar a transferência?')                          
	EndIf

	//Mostra as mensagens de Erro que aconteceram
	If !lRet
		oTecDest:ShowErro()
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} TcPesqBsMan()
Consulta especifica de base de atendimento

@author Matheus Lando Raimundo      
@since 15/10/2015
@version P12
@param oModel Modelo ativo
@return Nil
/*/
//------------------------------------------------------------------
Function TcPesqBsMan(cFilDest)

Local oModel         := FWModelActive()
Local lRet           := .T.
Local oBrowse        := Nil
Local cAls              := GetNextAlias()
Local nSuperior      := 0
Local nEsquerda      := 0
Local nInferior      := 0
Local nDireita       := 0
Local oDlgTela       := Nil
Local cQry              := ""
//Definição do índice da Consulta Padrão
Local aIndex         := {"AA3_CODPRO"}
//Definição da Descrição da Chave de Pesquisa da Consulta Padrão
Local aSeek               := {{ "Base de Atendimento", {{"Base de Atendimento","C",TamSx3('AA3_NUMSER')[1],0,"",,}} }}
Local cBase := ""

cQry := " SELECT " 
cQry += " AA3_FILIAL, "  
cQry += " AA3_FILORI, "  
cQry += " AA3_CODPRO, "  
cQry += " AA3_NUMSER, "  
cQry += " B1_DESC "  
cQry += " FROM " + RetSqlName("AA3") + " AA3 "  
cQry += " INNER JOIN " + RetSqlName("SB1") + " SB1"
cQry += " ON SB1.B1_FILIAL = '" +   xFilial('SB1',cFilDest) + "'"
cQry += " AND AA3.AA3_CODPRO = SB1.B1_COD"  
cQry += " AND SB1.D_E_L_E_T_ = ' '"  
cQry += " WHERE AA3_FILIAL = '" +  xFilial('AA3',cFilDest) + "'"
cQry += " AND AA3_FILORI =   '" +  cFilDest + "'"  
cQry += " AND AA3.AA3_EQALOC = '1' "
cQry += " AND AA3.D_E_L_E_T_ = ' '" 


nSuperior := 0
nEsquerda := 0
nInferior := 460
nDireita  := 800

DEFINE MSDIALOG oDlgTela TITLE "Base Atendimento" FROM nSuperior,nEsquerda TO nInferior,nDireita PIXEL 
 
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription("Base Atendimento") 
oBrowse:SetAlias(cAls)
oBrowse:SetDataQuery()
oBrowse:SetQuery(cQry)
oBrowse:SetOwner(oDlgTela)
oBrowse:SetDoubleClick({ || cBase := (oBrowse:Alias())->AA3_NUMSER,  lRet := .T., oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi("Confirmar"), {|| cBase := (oBrowse:Alias())->AA3_NUMSER,  oDlgTela:End()})
oBrowse:AddButton( OemTOAnsi("Cancelar"),  {|| cBase := "", oDlgTela:End()} ,, 2 ) //"Cancelar"
oBrowse:AddButton( OemTOAnsi("Incluir"),   {|| IncBaseAtend(@cBase), Iif(!Empty(cBase),oDlgTela:End(),Nil) } ,, 2 ) 
oBrowse:DisableDetails()
oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek({||.T.},aSeek)

ADD COLUMN oColumn DATA { ||  AA3_FILIAL } TITLE "Filial" SIZE TamSx3('AA3_FILIAL')[1] OF oBrowse //"Filial"
ADD COLUMN oColumn DATA { ||  AA3_CODPRO  } TITLE "Produto" SIZE TamSx3('AA3_CODPRO')[1]  OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  B1_DESC } TITLE "Descrição" SIZE TamSx3('B1_DESC')[1]  OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  AA3_FILORI} TITLE "Fil Ori" SIZE TamSx3('AA3_FILORI')[1]  OF oBrowse //"Código"
ADD COLUMN oColumn DATA { ||  AA3_NUMSER } TITLE "Num Ser" SIZE TamSx3('AA3_NUMSER')[1] OF oBrowse //"Código"
            
oBrowse:Activate()

ACTIVATE MSDIALOG oDlgTela CENTERED

     
Return( cBase )

//-------------------------------------------------------------------
/*/{Protheus.doc} TcPesqBsAut()
Consulta uma base de atendimento valida em outra filial

@author Cesar A. Bianchi      
@since 15/10/2015
@version P12
@return Nil
/*/
//------------------------------------------------------------------
Function TcPesqBsAut(cFilDest,cFilOrig,cNumSer,cProd,lUnico)
	Local aArea := GetArea()
	Local cQry := ""
	Local cAlias := GetNextAlias()
	Local cBase	:= ""
	
	cQry := " SELECT " 
	cQry += " AA3_FILIAL, "  
	cQry += " AA3_FILORI, "  
	cQry += " AA3_CODPRO, "  
	cQry += " AA3_NUMSER, "  
	cQry += " B1_DESC "  
	cQry += " FROM " + RetSqlName("AA3") + " AA3 "  
	cQry += " INNER JOIN " + RetSqlName("SB1") + " SB1"
	cQry += " ON SB1.B1_FILIAL = '" +   xFilial('SB1',cFilDest) + "'"
	cQry += " 		AND AA3.AA3_CODPRO = SB1.B1_COD"
	cQry += " 		AND AA3.AA3_CODPRO = '" + cProd + "' "   
	cQry += " 		AND SB1.D_E_L_E_T_ = ' '"  
	cQry += " WHERE AA3_FILIAL = '" +  xFilial('AA3',cFilDest) + "'"
	cQry += " 		AND AA3.AA3_FILORI =   '" +  cFilDest + "'"
	cQry += " 		AND AA3.AA3_NUMSER =   '" +  cNumSer + "' "
	cQry += " 		AND AA3.AA3_EQALOC = '1' "
	If lUnico
		//Se for IDUnico, é obrigatorio que a base de origem esteja bloqueada
		//Significa que ela pertenceu a um movimento anterior
		//Neste caso, necessita ser vinculado ao mesmo item
		cQry += " AND AA3.AA3_MSBLQL = '1' "
	EndIf
	cQry += " 		AND AA3.D_E_L_E_T_ = ' '" 
	iif(Select(cAlias)>0,(cAlias)->(dbCloseArea()),Nil)
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQry), cAlias, .F., .T.)	

	If (cAlias)->(!(Eof()))
		If !(Empty((cAlias)->AA3_NUMSER))
			cBase := (cAlias)->AA3_NUMSER
		EndIf
	EndIf
	
	(cAlias)->(dbCloseArea())
	RestArea(aArea)     
Return( cBase )

//-------------------------------------------------------------------
/*/{Protheus.doc} GetNumSer()
Retorno o código da base de atendimento de acordo com Filial e ativo

@author Matheus Lando Raimundo      
@since 15/10/2015
@version P12
@param oModel Modelo ativo
@return Nil
/*/
//------------------------------------------------------------------
Function GetNumSer(cFilAtivo,cAtivo,cItem)
Local cNumSer 		:= ""
Local aArea			:= GetArea()
Default cFilAtivo		:= ""
Default cAtivo		:= ""
Default cItem			:= ""

If !(Empty(cFilAtivo)) .and. !(Empty(cAtivo)) .and. !(Empty(cItem))
	TWH->(DbSetOrder(2))
	If TWH->(DbSeek(xFilial("TWH") + Padr(cFilAtivo,TamSx3("TWH_FILORI")[1]) + Padr(cAtivo,TamSx3("TWH_ATVCBA")[1]) + Padr(cItem,TamSx3("TWH_ATVITE")[1]) ))
		cNumSer := TWH->TWH_BASE                       
	EndIf
EndIf

RestArea(aArea)
Return cNumSer

//-------------------------------------------------------------------
/*/{Protheus.doc} IncBaseAtend()
Rotina de inclusão da base de atendimento

@author Matheus Lando Raimundo      
@since 15/10/2015
@version P12
@param oModel Modelo ativo
@return Nil
/*/
//------------------------------------------------------------------
Function IncBaseAtend(cBaseRet)
Local lAlteraAux  := ALTERA
Local lIncluiAux  := INCLUI
Local nOpcA		  := 0	
Local aArea       := GetArea()

Private aRotina := {    { "Pesquisar"     ,"AxPesqui"       ,0    ,1    ,0      ,.F.},;//"Pesquisar"
                                   { "Visualizar"    ,"At040Visua"     ,0    ,2    ,0      ,.T.},;     //"Visualizar"
                                   { "Incluir" ,"At040Inclu"     ,0    ,3    ,0    ,.T.}}       //"Incluir"

Private cCadastro := "INCLUSÃO - Base de Atendimento"// "INCLUSÃO - Base de Atendimento"    

ALTERA      := .F.
INCLUI      := .T.

nOpcA := At040Inclu("AA3",0,3)

If nOpcA == 1
      cBaseRet := AA3->AA3_NUMSER 
EndIf

ALTERA      := lAlteraAux
INCLUI      := lIncluiAux
RestArea(aArea)

Return nOpcA


//-----------------------------------------------------------------
/*/{Protheus.doc} SelectNotId
Seleciona os equipamentos que não são controlados por ID único.

@param                    cCodLocEq, caracter, código da locação TFI.
@since 08/08/2016
/*/   
//--------------------------------------------------------------------
METHOD SelectNotId( cCodLocEq ) CLASS TECProvider
Local cQry              := GetNextAlias()
Local aArea             := GetArea()
Local cItemProd         := ""
Local cCodigosTWS := ""
Local cProdFilter   := ""
Local xAux              := ""
Local cLastTWS          := ""
Local lFoundTWS   := .F.
Local lUseInTWS   := .F.
Local lUseIn        := .F.
Local dDtBs             := dDataBase
Local xListProd         := Nil
Local cJoin             := ""
Local cWhere            := ""
Local nTamFilSB1 := AtTamFilTab('SB1')
Local nTamFilTEW := AtTamFilTab('TEW')
Local nTamFilAA3 := AtTamFilTab('AA3')
Local nTamFilSA1 := AtTamFilTab('SA1')
Local nTamFilTWH := AtTamFilTab('TWH')
Local nZ                := 0
Local cExpOrder := ""
Local cFilSB5 := xFilial("SB5")
Local nTamFilSN1 := AtTamFilTab('SN1')
Local nTamFilTWI := AtTamFilTab('TWI')
Local nTamFilTWU := AtTamFilTab('TWU')

Default cCodLocEq := ""

DbSelectArea("TFI")
TFI->( DbSetOrder( 1 ) )

If TFI->(DbSeek(xFilial("TFI")+cCodLocEq))
      cItemProd := TFI->TFI_PRODUT

      DbSelectArea("TEZ")
      TEZ->( DbSetOrder( 1 ) ) // TEZ_FILIAL+TEZ_PRODUT
      
      //--------------------------------------------------------------
      //  Verifica se existe configuração de kit para o produto utilizado
      If TEZ->( DbSeek( xFilial("TEZ")+cItemProd ) )
            // identifica os produtos que compoem o kit
            xListProd := {}
            While TEZ->( !EOF() ) .And. TEZ->TEZ_FILIAL = xFilial("TEZ") .And. TEZ->TEZ_PRODUT == cItemProd
            	
            	If Posicione("SB5",1,cFilSB5+TEZ->TEZ_ITPROD,"B5_ISIDUNI") == "2"
                  xAux += TEZ->TEZ_ITPROD + "#"
                  aAdd( xListProd, TEZ->TEZ_ITPROD )
                EndIf
                TEZ->( DbSkip() )
            EndDo
            
            xAux := StrTran( SubStr( xAux, 1, Len(xAux)-1 ), "#", "','" )
            
            If Empty( xAux )
                  xAux := Space( TamSX3('AA3_CODPRO')[1] )
                  xListProd := xAux
            EndIf
            cItemProd := "% AND AA3.AA3_CODPRO IN ( '"+xAux+"' ) %"
      Else
            xListProd := cItemProd
            cItemProd := "% AND AA3.AA3_CODPRO = '"+cItemProd+"' %"
      EndIf
      
      dDatIni := If(!Empty(TFI->TFI_PERINI),TFI->TFI_PERINI,TFI->TFI_ENTEQP)
      dDatFim := If(!Empty(TFI->TFI_PERFIM),TFI->TFI_PERFIM,TFI->TFI_COLEQP)
      
      DbSelectArea('TWS')
      TWS->( DbSetOrder( 2 ) ) // TWS_FILIAL+TWS_FILPRD+TWS_PRDCOD
      
      If ValType(xListProd) == 'A' .And. Len(xListProd) >= 1
            
            // procura os códigos de produtos associados com a 
            For nZ := 1 To Len( xListProd )
                  If TWS->(DbSeek( xFilial("TWS")+xFilial("SB1")+xListProd[nZ] ))
                        
                        lFoundTWS := .T.
                        cCodigosTWS += TWS->TWS_CODIGO+'#'
                        cLastTWS := TWS->TWS_CODIGO
                        
                        While TWS->( !EOF() ) .And. TWS->TWS_CODIGO == cLastTWS
                             cProdFilter += ( TWS->(TWS_FILPRD+TWS_PRDCOD) + '#')
                             TWS->(DbSkip())
                        End
                  EndIf
            Next nZ
            
            If !lFoundTWS
                  AEval( xListProd, {|x| cProdFilter += (  x + '#') } )
            EndIf
            
            lUseIn := .T.
            lUseInTWS := .T.
            
      ElseIf ValType(xListProd) == 'C'
            
            If TWS->(DbSeek( xFilial('TWS')+xFilial('SB1')+xListProd ))
                  
                  lFoundTWS := .T.
                  cCodigosTWS := TWS->TWS_CODIGO
                  cLastTWS := TWS->TWS_CODIGO
                  
                  While TWS->( !EOF() ) .And. TWS->TWS_CODIGO == cLastTWS
                        cProdFilter += ( TWS->(TWS_FILPRD+TWS_PRDCOD) + '#')
                        TWS->(DbSkip())
                  End
                  
                  lUseIn := .T.
            Else
                  cProdFilter := xListProd
            EndIf
            
      EndIf 
      
      If !Empty(cProdFilter)
            
            If lUseIn
                  cProdFilter := "IN ('" + StrTran( SubStr( cProdFilter, 1, Len(cProdFilter)-1), "#", "','" ) + "' ) "
            Else
                  cProdFilter := "= '" + cProdFilter+ "' "
            EndIf
            
            If lUseInTWS
                  cCodigosTWS := "IN ('" + StrTran( SubStr( cCodigosTWS, 1, Len(cCodigosTWS)-1), "#", "','" ) + "' ) "
            Else
                  cCodigosTWS := "= '"+cCodigosTWS+"' "
            EndIf
      Endif
      
      If lFoundTWS
            cJoin +=    "LEFT JOIN "+RetSqlName('TWS')+ " TWS ON "
            cJoin +=                                             "TWS.D_E_L_E_T_=' '"
            cJoin +=                                             "AND TWS_FILIAL = ' ' " // -- filial da TWS
            cJoin +=                                             "AND TWS_CODIGO " + cCodigosTWS
      EndIf
      
      cJoin := '%' + cJoin + '%'
      
      If lFoundTWS
            cWhere +=         "AND ( ( SB1.B1_FILIAL = TWS.TWS_FILPRD AND SB1.B1_COD = TWS.TWS_PRDCOD ) )"
      Else
            cWhere +=         "AND ( ( SB1.B1_FILIAL ="+xFilial("SB1")+" AND SB1.B1_COD "+cProdFilter+" ) )" //-- filial da SB1 combinada com o código do produto
      EndIf
      
      cWhere := '%' +cWhere + '%'
      
      BeginSql Alias cQry
      
          SELECT DISTINCT AA3.*
                          ,SB1.B1_DESC AA3_DESPRO
                          ,SA1.A1_NOME AA3_NOMCLI
                          ,0 AA3_GNITRES 
                          ,TWH_FILORI
                          ,CASE	WHEN AA3.AA3_FILORI = %Exp:cFilAnt% 
                          		THEN 0 
								ELSE 1
							END AA3_ORDEM
                  FROM %Table:SB1% SB1 
                  INNER JOIN %Table:AA3% AA3 
                        ON AA3.AA3_EQALOC = '1' 
                        AND AA3.AA3_CODPRO = SB1.B1_COD 
                        AND AA3.AA3_FILIAL = SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilAA3% )
						AND AA3.%NotDel%
                  INNER JOIN  %Table:TWH% TWH
                        ON TWH_FILIAL = SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilTWH% )
                        AND TWH_BASE  = AA3_NUMSER
                        AND TWH_FILORI = AA3_FILORI
                        AND TWH.%NotDel%             
                  INNER JOIN %Table:SB5% SB5 
                        ON SB5.B5_FILIAL = SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilSB1% )
                        AND SB5.B5_COD = AA3.AA3_CODPRO 
                        AND SB5.%NotDel%
                  LEFT JOIN %Table:SA1% SA1 
                        ON SA1.%NotDel%
                        AND SA1.A1_COD = AA3.AA3_CODCLI 
                        AND SA1.A1_LOJA = AA3.AA3_LOJA 
                        AND SA1.A1_FILIAL = SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilSA1% )
                  %Exp:cJoin%
            WHERE  SB1.%NotDel%
                  AND SB5.B5_ISIDUNI = '2'
                  %Exp:cWhere%
              AND ( 
                  		     (  SELECT COALESCE(SUM(N1_QUANTD),0) 
							     	FROM %Table:SN1% SN1
										INNER JOIN %Table:TWH%
											ON TWH_FILIAL = SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilTWH% ) 
											AND SN1.N1_CBASE = TWH.TWH_ATVCBA
											AND SN1.N1_ITEM = TWH.TWH_ATVITE
											AND TWH.%NotDel%
									
									WHERE SN1.N1_FILIAL = SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilSN1% )
										AND TWH.TWH_FILORI = AA3.AA3_FILORI
										AND TWH_BASE = AA3.AA3_NUMSER
										AND SN1.%NotDel%
									  
                                     ) - 
	
								 	(  SELECT COALESCE(SUM(TWI.TWI_QTDSAI),0) - COALESCE(SUM(TWI.TWI_QTDRET),0) SLDLOC 
								 		FROM %Table:TEW% TEW
											INNER JOIN %Table:TWI% TWI
												ON  TWI_FILIAL 	= TEW_FILIAL
												AND TWI_IDREG 	= TEW_CODMV
												AND TWI.%NotDel%
										WHERE TEW.TEW_FILBAT 	= AA3.AA3_FILORI
											AND TEW.TEW_BAATD 	= AA3.AA3_NUMSER
											AND TEW.TEW_TIPO 	<> '2'
											AND TEW.%NotDel%
														
			 						) -
									
									(
										SELECT COALESCE(SUM(TWU.TWU_QTDBLQ),0) - COALESCE(SUM(TWU.TWU_QTDLIB),0) SLDRES 
										FROM %Table:TWU% TWU															
										WHERE TWU_FILIAL 	= SUBSTRING(AA3.AA3_FILORI, 1, %Exp:nTamFilTWU% )
											AND TWU.TWU_BASE = AA3.AA3_NUMSER
											AND TWU.%NotDel%
										)
					) > 0
      EndSql
Endif

//RestArea(aArea)

Return cQry
//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoAdquirido
       Realiza o calculo da quantidade total de itens associado a uma determinada base de atendimento 
considerando o código Base do Ativo e todos os itens vinculados a ele.

@since 09/08/2016
/*/   
//--------------------------------------------------------------------
METHOD SaldoAdquirido() CLASS TECProvider
Local aArea       := GetArea()
Local aAreaSN1	  := SN1->(GetArea())
Local aAreaTWH	  := TWH->(GetArea())
Local cIdUnic     := ""
Local cBaseAtv    := ""
Local nSldAdq     := 0
Local cFilTWH     := xFilial("TWH",Self:cFil)

If Self:nRecNoTWH > 0
      TWH->(DbGoto(Self:nRecNoTWH))
      DbSelectArea("SN1")
      SN1->(DbSetOrder(1))

      While TWH->( !EOF() ) .And. TWH->TWH_FILIAL = cFilTWH .And. TWH->TWH_BASE == Self:cNumSer

            If TWH->TWH_ATVCBA <> cBaseAtv .And. SN1->(DbSeek(TWH->TWH_FILORI+TWH->TWH_ATVCBA))
            
                  While SN1->( !EOF() ) .And. TWH->TWH_FILORI == SN1->N1_FILIAL .And. TWH->TWH_ATVCBA == SN1->N1_CBASE
                        
                        nSldAdq := N1_QUANTD+nSldAdq
                        
                        SN1->( DbSkip() )
                  EndDo
            Endif
            cBaseAtv := TWH->TWH_ATVCBA

            TWH->( DbSkip() )

      EndDo
EndIf

RestArea(aAreaSN1)
RestArea(aAreaTWH)
RestArea(aArea)
Return nSldAdq

//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoTotal
       Realiza o calculo da quantidade total dos Ativos associados a Base de Atendimento 
considerando as informações registradas na tabela TWH e o período inicial e final indicado como parâmetro

@since 09/08/2016
/*/   
//--------------------------------------------------------------------
METHOD SaldoTotal() CLASS TECProvider
Local aArea       := GetArea()
Local nTotal      := 0
Local cIdUnic     := ""
Local cBaseAtv    := ""
LOcal cFilTWH     := xFilial("TWH",Self:cFil)

If Self:nRecNoTWH > 0
      TWH->(DbGoto(Self:nRecNoTWH))   
      DbSelectArea("SN1")
      SN1->(DbSetOrder(1))

      While TWH->( !EOF() ) .And. TWH->TWH_FILIAL = cFilTWH .And. TWH->TWH_BASE == Self:cNumSer

			If SN1->(DbSeek(TWH->TWH_FILORI+TWH->TWH_ATVCBA+TWH->TWH_ATVITE))
                  nTotal := N1_QUANTD+nTotal
            Endif
                  
            TWH->( DbSkip() )

      EndDo 
EndIf

RestArea(aArea)
Return nTotal



//-----------------------------------------------------------------
/*/{Protheus.doc} InsertTWP
Exclui Registro na TWI

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD InsertTWP(cIdReg,cNota,cSerie,cItem,nQtd,lExigNF,cTipOs,cNumOs,cItemOs,cFilNF,cFilMov) CLASS TECProvider
Local aArea             := GetArea()
Default cNota    := ""
Default cSerie   := ""
Default cItem           := ""
Default cTipOs   := ""
Default cNumOs   := ""
Default cItemOs  := ""
Default cFilNF   := xFilial("SD1")
Default cFilMov  := xFilial('TWP',Self:cFil)

RecLock( 'TWP',.T.)
TWP->TWP_FILIAL = cFilMov
TWP->TWP_IDREG  = cIdReg
TWP->TWP_NUMNF  = cNota
TWP->TWP_SERNF  = cSerie
TWP->TWP_ITEMNF = cItem
TWP->TWP_QTDRET = nQtd
TWP->TWP_DTRET  = dDataBase
TWP->TWP_OSTIPO = cTipOs
TWP->TWP_OSNUM	= cNumOs
TWP->TWP_OSITEM	= cItemOs
TWP->TWP_FILNF  = cFilNF

If lExigNF
	TWP->TWP_EXIGNF = '1'	
Else
	TWP->TWP_EXIGNF = '2'
EndIf

TWP->(MsUnlock())

TWI->(DbSetOrder(1))
If TWI->(DbSeek(xFilial('TWI',cFilMov)+cIdReg))
	RecLock( 'TWI',.F.)
	TWI->TWI_QTDRET = TWI->TWI_QTDRET + nQtd    
	If TWI->TWI_QTDRET == TWI->TWI_QTDSAI
		TWI->TWI_DTRET = dDataBase
	Endif
	TWI->(MsUnlock())	
EndIf

RestArea(aArea)

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} DeleteTWP
Exclui Registro na TWP

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD DeleteTWP(cIdReg,cFilMov) CLASS TECProvider
Local aArea       := GetArea()
Local nNumNF	  := ""
Local cSerNF	  := ""
Local nQtd 		  := 0
Local lSeek		  := .T.
Default cIdReg	  := ""
Default cFilMov   := xFilial('TWP')

TWP->(DbSetOrder(1)) //TWP_FILIAL+TWP_IDREG+TWP_NUMNF+TWP_SERNF+TWP_ITEMNF

If !Empty(cIdReg)
	lSeek := TWP->(DbSeek(cFilMov+cIdReg))
Else
	cIdReg := TWP->TWP_IDREG
Endif

If lSeek .And. !Empty(cIdReg)
	nQtd := TWP->TWP_QTDRET
	RecLock('TWP', .F.)
	TWP->(dbDelete())
	TWP->(MsUnlock())
  
	TWI->(DbSetOrder(1))
	If TWI->(DbSeek(cFilMov+cIdReg))
		RecLock( 'TWI',.F.)
			TWI->TWI_QTDRET = TWI->TWI_QTDRET - nQtd
			TWI->TWI_DTRET  = CTOD("")
		TWI->(MsUnlock())	
	Endif
Endif 

RestArea(aArea)

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} InsertTWU
Insere Registro na TWU

@author Matheus Lando Raimundo
@since 01/06/2016,

@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD InsertTWU(cCodTEW,cBase,nQtdBlq,cTipo,cOSTipo,cOsNum,cOsItem,lDesBloq) CLASS TECProvider
Local aArea             := GetArea()
Default cCodTEW		:= ""
Default lDesBloq	:= .F.

RecLock( 'TWU',.T.)
TWU->TWU_FILIAL = xFilial('TWU',Self:cFil)
TWU->TWU_CODTEW = cCodTEW
TWU->TWU_BASE = cBase
TWU->TWU_SEQ = GetSeqTWU(cBase)
TWU->TWU_QTDBLQ = nQtdBlq
TWU->TWU_TIPO = cTipo
TWU->TWU_OSTIPO = cOSTipo
TWU->TWU_OSNUM = cOsNum
TWU->TWU_OSITEM = cOsItem

If lDesBloq
	TWU->TWU_QTDLIB = nQtdBlq
Else
	TWU->TWU_QTDLIB = 0
EndIf

TWU->(MsUnlock())

RestArea(aArea)

Return


//-----------------------------------------------------------------
/*/{Protheus.doc} GetQtdTWI

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function GetQtdTWI(cIdReg)
Local nRet := 0
TWI->(DbSetOrder(1))
If TWI->(DbSeek(xFilial('TWI')+cIdReg))
	nRet := TWI->TWI_QTDSAI
EndIf
Return nRet


//-----------------------------------------------------------------
/*/{Protheus.doc} GetSeqTWU

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function GetSeqTWU(cBase)
Local cSeq := '001'
Local cAliasTWU := GetNextAlias()

BeginSql Alias cAliasTWU 

	SELECT MAX(TWU.TWU_SEQ) TWU_SEQ FROM %table:TWU% TWU
	 
	WHERE TWU.TWU_FILIAL = %xfilial:TWU%
	  AND TWU.TWU_BASE   = %exp:cBase%
	  AND TWU.%NotDel%	
EndSql


cSeq := Soma1((cAliasTWU)->TWU_SEQ)

Return cSeq

//-----------------------------------------------------------------
/*/{Protheus.doc} DeleteTWU
DELETE Registro na TWU

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD DeleteTWU(cIdReg,cChaveOS) CLASS TECProvider
Local aArea       := GetArea()

If !Empty(cIdReg)
	TWU->(DbSetOrder(1))
	lRet := TWU->(DbSeek(xFilial('TWU',Self:cFil)+cIdReg))
ElseIf !Empty(cChaveOS)
	TWU->(DbSetOrder(4))
	lRet := TWU->(DbSeek(xFilial('TWU',Self:cFil)+cChaveOS))
EndIf	

If lRet
      RecLock('TWU', .F.)
      TWU->(dbDelete())
      TWU->(MsUnlock())
EndIf    

RestArea(aArea)

Return lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} UpdateTWU
Update TWU

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD UpdateTWU(cIdReg,nQtd,cChaveOS) CLASS TECProvider
Local aArea       := GetArea()
Local lRet			:= .F.


If !Empty(cIdReg)
	TWU->(DbSetOrder(1))
	lRet := TWU->(DbSeek(xFilial('TWU',Self:cFil)+cIdReg))
ElseIf !Empty(cChaveOS)
	TWU->(DbSetOrder(4))
	lRet := TWU->(DbSeek(xFilial('TWU',Self:cFil)+cChaveOS))
EndIf	

If lRet
	RecLock('TWU', .F.)
   	TWU->TWU_QTDLIB = TWU->TWU_QTDLIB + nQtd
   	TWU->(MsUnlock())
EndIf   	
    

RestArea(aArea)

Return lRet


//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoLocado
Calcula considerando o período recebido por parâmetro e considerar os 
	valores associados as movimentações ativas dentro deste período na tabela TEW

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD SaldoLocado() CLASS TECProvider
Local aArea		:= GetArea()
Local nSldLoc 	:= 0
Local cNewAlias := GetNextAlias()
Local cIdSer 	:= Self:cNumSer
Local cFilTWI 	:= xFilial("TWI",Self:cFil)
Local cFilTEW 	:= xFilial("TEW",Self:cFil)


If !Empty(cIdSer)

	BeginSql Alias cNewAlias 
			
		SELECT COALESCE(SUM(TWI.TWI_QTDSAI),0) - COALESCE(SUM(TWI.TWI_QTDRET),0) SLDLOC
		FROM %Table:TEW% TEW
		INNER JOIN %Table:TWI% TWI
			ON  TWI_FILIAL 	= %Exp:cFilTWI%
			AND TWI_IDREG 	= TEW_CODMV
			AND TWI.%NotDel%
		WHERE TEW_FILIAL 	= %Exp:cFilTEW%
			AND TEW_BAATD 	= %Exp:cIdSer%
			AND TEW_TIPO 	<> '2'
			AND TEW.%NotDel%
		EndSql

	If (cNewAlias)->(!EOF())
		nSldLoc := (cNewAlias)->SLDLOC
	Endif

	(cNewAlias)->(DbCloseArea())

Endif

RestArea(aArea)

Return nSldLoc


//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoLocado
Calcula considerando o período recebido por parâmetro e considerar os 
	valores associados as movimentações ativas dentro deste período na tabela TEW

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD AlteraFilOriBase(cFil,lAlteraTWH) CLASS TECProvider
Local aArea       := GetArea()
      
AA3->(DbGoto(Self:nRecNoAA3))

RecLock( 'AA3',.F.)
AA3->AA3_FILORI = cFil
AA3->(MsUnlock())   

If lAlteraTWH
	TWH->(DbGoto(Self:nRecNoTWH))
	RecLock( 'TWH',.F.)
	TWH->TWH_FILORI = cFil
	TWH->(MsUnlock())
	
	
EndIf

RestArea(aArea)

Return 


//-----------------------------------------------------------------
/*/{Protheus.doc} TcAtfVldMov
Valida movimentação de ativo

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function TcAtfVldMov(cFilOrig,cAtivo,nQtd,cItem)
Local oTecProvider  	:= Nil
Local cNumSer   		:= ""
Local lRet				:= .T.

cNumSer := GetNumSer(cFilOrig,cAtivo,cItem)

If !Empty(cNumSer)
	oTecProvider := TECProvider():New(cNumSer,cFilOrig)      
	If lRet := oTecProvider:lValido	
		If oTecProvider:lAtivoFixo
			If lRet .And. nQtd > oTecProvider:SaldoDisponivel()
	    		lRet := .F.
	    		Aadd(oTecProvider:aError,'Não será possível efetuar a movimentação do Ativo')
       		Aadd(oTecProvider:aError,'A base de atendimento não possui saldo disponível no Gestão de serviços')
       		Aadd(oTecProvider:aError,'Quantidade em transferencia: ' + alltrim(str(nQtd)))
       		Aadd(oTecProvider:aError,'Quantidade livre disponivel no Gestão de Serviços: ' + alltrim(str(oTecProvider:SaldoDisponivel())))
			EndIf       		
		EndIf
	EndIf
EndIf

If !lRet
	oTecProvider:ShowErro()
EndIf	

If ValType(oTecProvider) == 'O'
	FreeObj(oTecProvider)
EndIf

Return lRet

//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoReservado


@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD SaldoReservado(cCodRes) CLASS TECProvider
Local aArea		:= GetArea()
Local nSldLoc 	:= 0
Local cNewAlias := GetNextAlias()
Local cIdSer 	:= Self:cNumSer
Local cFiltrMov	:= ""
Local cFilTEW 	:= xFilial("TEW",Self:cFil)
Local cFilTWU 	:= xFilial("TWU",Self:cFil)

Default cCodRes	:= ""

If !Empty(cCodRes)
	cFiltrMov := "% AND TEW_RESCOD = '" + cCodRes + "'%" 
Else
	cFiltrMov := "%%"
EndIf 

If !Empty(cIdSer)

	BeginSql Alias cNewAlias 
			
		SELECT COALESCE(SUM(TWU.TWU_QTDBLQ),0) - COALESCE(SUM(TWU.TWU_QTDLIB),0) SLDRES
		FROM %Table:TWU% TWU
		
		INNER JOIN %Table:TEW% TEW
			ON  TEW_FILIAL 	= %Exp:cFilTEW%
			AND TEW_CODMV 	= TWU.TWU_CODTEW			
			AND TEW.%NotDel%
			
		WHERE TWU_FILIAL 	= %Exp:cFilTWU%
			AND TWU.%NotDel%
			AND TWU.TWU_BASE = TEW.TEW_BAATD
			AND TWU_TIPO  = '1'
			AND TEW_BAATD = %Exp:cIdSer%
			AND TEW_FILBAT = %Exp:Self:cFil%
			AND TEW_TIPO 	= '2'
			%Exp:cFiltrMov% 
					
		EndSql

	If (cNewAlias)->(!EOF())
		nSldLoc := (cNewAlias)->SLDRES
	Endif

	(cNewAlias)->(DbCloseArea())

Endif

RestArea(aArea)

Return nSldLoc

//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoTravado


@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD SaldoTravado() CLASS TECProvider
Local aArea		:= GetArea()
Local nSldMan 	:= 0
Local cNewAlias := GetNextAlias()
Local cIdSer 	:= Self:cNumSer
Local cFilTWU 	:= xFilial("TWU",Self:cFil)

If !Empty(cIdSer)

	BeginSql Alias cNewAlias 
			
		SELECT COALESCE(SUM(TWU.TWU_QTDBLQ),0) - COALESCE(SUM(TWU.TWU_QTDLIB),0) SLDRES
		FROM %Table:TWU% TWU
		WHERE TWU_FILIAL 	= %Exp:cFilTWU%
			AND TWU.%NotDel%
			AND TWU_TIPO  = '3'
			AND TWU_BASE = %Exp:cIdSer%
	EndSql

	If (cNewAlias)->(!EOF())
		nSldMan := (cNewAlias)->SLDRES
	Endif

	(cNewAlias)->(DbCloseArea())

Endif

RestArea(aArea)

Return nSldMan

//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoBloqueado


@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD SaldoBloqueado() CLASS TECProvider
Local nSldBlq := 0

nSldBlq := Self:SaldoReservado() + Self:SaldoManutencao() + Self:SaldoTravado()  

Return nSldBlq 

//-----------------------------------------------------------------
/*/{Protheus.doc} SaldoManutencao


@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD SaldoManutencao() CLASS TECProvider
Local aArea		:= GetArea()
Local nSldMan 	:= 0
Local cNewAlias := GetNextAlias()
Local cIdSer 	:= Self:cNumSer
Local cFilTWU 	:= xFilial("TWU",Self:cFil)

If !Empty(cIdSer)

	BeginSql Alias cNewAlias 
			
		SELECT COALESCE(SUM(TWU.TWU_QTDBLQ),0) - COALESCE(SUM(TWU.TWU_QTDLIB),0) SLDRES
		FROM %Table:TWU% TWU
				
			
		WHERE TWU_FILIAL 	= %Exp:cFilTWU%
			AND TWU.%NotDel%
			AND TWU_TIPO  = '2'
			AND TWU_BASE = %Exp:cIdSer%
	EndSql

	If (cNewAlias)->(!EOF())
		nSldMan := (cNewAlias)->SLDRES
	Endif

	(cNewAlias)->(DbCloseArea())

Endif

RestArea(aArea)

Return nSldMan

//-----------------------------------------------------------------
/*/{Protheus.doc} AtStatusBase

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
METHOD AtStatusBase() CLASS TECProvider
Local aArea := GetArea()

If TWH->(DbSeek(xFilial("TWH",Self:cFil)+Self:cNumSer)) .And. !Self:lIdUnico
	AA3->(DbGoto(Self:nRecNoAA3))
	RecLock( 'AA3',.F.)
	AA3->AA3_STATUS = '08'
	AA3->(MsUnlock())    		
EndIf 

RestArea(aArea)

Return


//-----------------------------------------------------------------
/*/{Protheus.doc} TecDestroy

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function TecDestroy(oObj)

If ValType(oObj) == 'O'
	FreeObj(oObj)
	oObj := Nil
	DelClassIntF()
EndIf

Return


//-----------------------------------------------------------------
/*/{Protheus.doc} GetMovCod
Retorna o código de uma movimentação

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function GetMovCod(cReserv,cNumSerie)
Local cCodMov := ""
Local cQry              := GetNextAlias()

BeginSql Alias cQry

SELECT TEW_CODMV
	FROM %Table:TEW% TEW		
		WHERE TEW_FILIAL 	= %xFilial:TEW%
			AND TEW_RESCOD 	= %Exp:cReserv%
			AND TEW_BAATD 	= %Exp:cNumSerie%
			AND TEW_TIPO	= '2'
			AND TEW.%NotDel%			
EndSql

If !Empty((cQry)->TEW_CODMV)
	cCodMov := (cQry)->TEW_CODMV	
EndIf

(cQry)->(DbCloseArea())

Return cCodMov




//-----------------------------------------------------------------
/*/{Protheus.doc} GetSldBase

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//-------------------------------------------------------------------
Function GetSldBase(cBase,nOpc,lReport)
Local oTec			:= Nil
Local nSld			:= 0
Default lReport := .F.

If lReport .or. !INCLUI
	oTec := TecProvider():New(cBase)
	Do Case
		Case nOpc == 1
			nSld := oTec:SaldoTotal() 			
		Case nOpc == 2	
			nSld := oTec:SaldoLocado()
		Case nOpc == 3	
			nSld := oTec:SaldoReservado()
		Case nOpc == 4	
			nSld := oTec:SaldoManutencao()			
		Case nOpc == 5	
			nSld := oTec:SaldoTravado()			
		Case nOpc == 6	
			nSld := oTec:SaldoDisponivel()
			//Tratamento para nao exibir negativos quando ID Unico esta em manutenção		
			If nSld < 0
				nSld := 0
			EndIf							
	EndCase	
EndIf
TecDestroy(oTec)
Return nSld

//-----------------------------------------------------------------
/*/{Protheus.doc} TecAtfSeek
Verifica se existe Base x Ativo,

@author Matheus Lando Raimundo
@since 01/06/2016
@version 1.0
/*/   
//--------------------------------------------------------------------
Function TecAtfSeek(cCodBase, cFilRef)
Local lRet 			:= .F.
Local aArea       	:= {}
Local aAreaAA3		:= {}
Local aAreaTWH		:= {}
Default cCodBase	:= ""
Default cFilRef 	:= cFilAnt

If !Empty(cCodBase)

	aArea		:= GetArea()
	aAreaAA3	:= AA3->(GetArea())
	aAreaTWH	:= TWH->(GetArea())

	DbSelectArea("TWH")
	TWH->(DbSetOrder(1)) //TWH_FILIAL+TWH_BASE+TWH_FILORI+TWH_ATVCBA+TWH_ATVITE
	
	If TWH->(DbSeek(xFilial('TWH',cFilRef)+cCodBase))
		DbSelectArea("AA3")
		AA3->(DbSetOrder(6)) //AA3_FILIAL+AA3_NUMSER+AA3_FILORI
		If AA3->(DbSeek(xFilial('AA3',cFilRef)+TWH->(TWH_BASE+TWH_FILORI)))
			lRet := .T.
		Endif
	Endif

	RestArea(aAreaTWH)
	RestArea(aAreaAA3)
	RestArea(aArea)

Endif


Return lRet
