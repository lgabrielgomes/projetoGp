#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "TECA820.CH"
#INCLUDE "LOCACAO.CH"

//------------------ STATUS DO CAMPO AA3_DISP
#DEFINE DEF_STATUS_DISPONIVEL  '1'
#DEFINE DEF_STATUS_SELECIONADO '2'
#DEFINE DEF_STATUS_OUTRO       '3'
//------------------ FIM - STATUS DO CAMPO AA3_DISP

//------------------ POSICOES NO ARRAY PARA GERACAO DOS PEDIDOS DE REMESSA
// ---- posicionamento das listas principais
#DEFINE PED_POS_CAB				1
#DEFINE PED_POS_ITEM 			2
// ---- posicionamento dos campos no cabeçalho
#DEFINE PED_CAB_ORCAMENTO		1
#DEFINE PED_CAB_CLIENTE			2
#DEFINE PED_CAB_LOJA				3
#DEFINE PED_CAB_CONDPG			4
#DEFINE PED_CAB_TIPOFRETE		5
#DEFINE PED_CAB_CLIENTREGA	6
#DEFINE PED_CAB_LJENTREGA		7
#DEFINE PED_CAB_CONTR				8
#DEFINE PED_CAB_REVCTR 			9

#DEFINE PED_CAB_MAX_CAMPOS	9

// ---- posicionamento dos campos nos itens
#DEFINE PED_IT_ITEM					1
#DEFINE PED_IT_PRODUTO			2
#DEFINE PED_IT_QUANTIDADE		3
#DEFINE PED_IT_PR_VENDA			4
#DEFINE PED_IT_PR_UNIT			5
#DEFINE PED_IT_PR_VALOR			6
#DEFINE PED_IT_TES					7
#DEFINE PED_IT_COD_EQUIP		8
#DEFINE PED_IT_NUM_SERIE		9
#DEFINE PED_IT_RECNO_TEW		10
#DEFINE PED_IT_FILIAL				11

#DEFINE PED_IT_MAX_CAMPOS 		11
//------------------ FIM - POSICOES NO ARRAY PARA GERACAO DOS PEDIDOS DE REMESSA

STATIC cRecMarcados  := ""
STATIC nPosRecsIDU   := 1
STATIC nPosRecsGRN   := 1
STATIC aItensOk      := {}
STATIC lProcess      := .F.
STATIC lEntrou       := .F.
STATIC nQtdIni       := 0
STATIC lAutRob		 := .F.
STATIC cF3820F3      := ""
STATIC cF3820Ret     := ""

//------------------------------------------------------------------------------
/*/{Protheus.doc} TECA820
	Visualizar dos registros a serem separados para movimentação
@sample 	TECA820() 
@since		06/09/2013       
@version	P11.90
/*/
//------------------------------------------------------------------------------
Function TECA820( cAddFilter )

// filtra os equipamentos não separados e que estão com contrato no GCT
Local cFiltro := "TFI->TFI_FILIAL==xFilial('TFI') .And. TFI->TFI_SEPARA == '2' .And. TFI->TFI_ENCE <> '1' " +;
				".And. A820FltVig() .And. (!Empty(TFI->TFI_CONTRT) .Or. !Empty(TFI->TFI_CODTGQ)) .Or. (TFI->TFI_SRVEXT == '1' .AND. TFI->TFI_SEPARA == '2')" 

Default cAddFilter := ''

Static oBrw := Nil

If ! Empty( cAddFilter )
	cFiltro += cAddFilter
EndIf

lProcess := .F.
cRecMarcados := ""

oBrw := FwMarkBrowse():New()

oBrw:SetAlias("TFI")
oBrw:SetMenudef("TECA820")
oBrw:SetFieldMark("TFI_OK")
oBrw:SetCustomMarkRec( {|| At820Mk( oBrw ) } )
oBrw:SetAllMark( {|| At820AMk( oBrw ) } )
oBrw:SetDescription( OEmToAnsi( STR0001 ) ) // "Equipamentos não separados"
oBrw:SetFilterDefault( cFiltro )
oBrw:AddLegend( " Empty(TFI_CODTGQ)" , "BLUE"  , STR0044  ) //"Origem Contrato"
oBrw:AddLegend( " !Empty(TFI_CODTGQ)", "WHITE" , STR0045  ) //"Origem Requisições de Atendentes"

Pergunte("TECA820",.F.)
oBrw:AddFilter( STR0052, 'TFI->TFI_PERINI <= dDataBase + MV_PAR01' )  // 'Locações canceladas'

oBrw:SetParam({|| Pergunte("TECA820",.T.), oBrw:ExecuteFilter()})

oBrw:Activate()

oBrw:DeActivate()
oBrw := Nil
DelClassIntf()

RestArea(aArea)

Return lProcess


//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
	Definição do modelo de Dados
@since  	09/09/2013
@version 	P11.90
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

Local oModel := Nil
Local oStr1  := FWFormModelStruct():New()
Local oStr2  := FWFormStruct(1,'TFI')
Local oStr3  := FWFormStruct(1,'AA3', {|cCampo| FieldsAA3( cCampo , "1") })
Local oStr4  := FWFormStruct(1,'TWR')
Local oStr5	 := FWFormStruct(1,'AA3', {|cCampo| FieldsAA3( cCampo , "2") })

Local xAux   := Nil

oStr1:AddTable("TFI",{},"nulo")

oStr2:RemoveField("TFI_CALCMD")
oStr1:AddField( STR0058,STR0058,'TFI_NULO','C',1,0,NIL,NIL,NIL,.F.,NIL,.F.,Nil,.T.)

//Trata a obrigatoriedade dos campos da TFI devido a origem via Orcamento/Contrato e via Requisicoes para Atendentes
oStr2:SetProperty("TFI_LOCAL",  MODEL_FIELD_OBRIGAT, .F.)
oStr2:SetProperty("TFI_PERFIM", MODEL_FIELD_OBRIGAT, .F.)
oStr2:SetProperty("TFI_TES",    MODEL_FIELD_OBRIGAT, .F.)
oStr2:SetProperty("TFI_CODPAI", MODEL_FIELD_OBRIGAT, .F.)


// remove os campos obrigatórios pois serão preenchidos posteriormente na gravação da rotina
// parâmetros recebidos no valid >> oMdlVld,cCampo,xValueNew,nLine,xValueOld <<
oStr4:SetProperty( "*", MODEL_FIELD_OBRIGAT, .F. )
oStr4:SetProperty( "TWR_FILPED", MODEL_FIELD_OBRIGAT, .T. )
oStr4:SetProperty( "TWR_DESTIN", MODEL_FIELD_OBRIGAT, .T. )
oStr4:SetProperty( "TWR_CLIENT", MODEL_FIELD_VALID, ;
					{|a,b,c,d,e| Vazio() .Or. AtChkHasKey( "SA1", 1, xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLIENT") ) } )
oStr4:SetProperty( "TWR_LOJACL", MODEL_FIELD_VALID, ;
					{|a,b,c,d,e| Vazio() .Or. AtChkHasKey( "SA1", 1, xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLIENT")+FwFldGet("TWR_LOJACL") ) } )
oStr4:SetProperty( "TWR_CLENTR", MODEL_FIELD_VALID, ;
					{|a,b,c,d,e| Vazio() .Or. AtChkHasKey( "SA1", 1, xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLENTR") ) } )
oStr4:SetProperty( "TWR_LOJENT", MODEL_FIELD_VALID, ;
					{|a,b,c,d,e| Vazio() .Or. AtChkHasKey( "SA1", 1, xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLENTR")+FwFldGet("TWR_LOJENT") ) } )
oStr4:SetProperty( "TWR_CONDPG", MODEL_FIELD_VALID, ;
					{|a,b,xValueNew,d,e| Vazio() .Or. AtChkHasKey( "SE4", 1, xFilial("SE4",FwFldGet("TWR_FILPED"))+xValueNew ) } )
oStr4:SetProperty( "TWR_TES", MODEL_FIELD_VALID, ;
					{|a,b,xValueNew,d,e| Vazio() .Or. AtChkHasKey( "SF4", 1, xFilial("SF4",FwFldGet("TWR_FILPED"))+xValueNew ) .Or. FwFldGet("TWR_TES") > "500" } )
oStr4:SetProperty( "TWR_CNPJ", MODEL_FIELD_VALID, ;
					{|oMdlVld,b,xValueNew,d,e| Vazio() .Or. ;
					At820Cnpj( oMdlVld, iif(oMdlVld:GetValue("TWR_DESTIN")=="1","FIL","ENT"), xValueNew ) } )

// Bloqueia a edição dos campos da AA3, para permitir somente a edição da flag de marcação 
// e o campo de indicação de seleção em outro item
oStr3:SetProperty( "*", MODEL_FIELD_WHEN, {||.F.} )

//Adiciona o tipo de frete.
oStr2:AddField(	GetSx3Cache("TFJ_TPFRET","X3_TITULO"),;                                                         // cTitle // "Tipo Frete"
				GetSx3Cache("TFJ_TPFRET","X3_TITULO"),;                                                            // cToolTip // "Tipo Frete"
				"TFJ_TPFRET",;                                                                                     // cIdField
				GetSx3Cache("TFJ_TPFRET","X3_TIPO"),;                                                              // cTipo
				GetSx3Cache("TFJ_TPFRET","X3_TAMANHO"),;                                         					   // nTamanho
				GetSx3Cache("TFJ_TPFRET","X3_DECIMAL"),;                                                           // nDecimal
				Nil,;											     	              										   // bValid
				Nil,;                                                                                              // bWhen
				{"","1="+STR0063,"2="+STR0064},;                                                                   // aValues //CIF ## FOB
				.F.,;                                                           								   // lObrigat
				Nil,;                                                                                              // bInit
				.F.,;                                                                                              // lKey
				.T.,;                                                                                              // lNoUpd
				.T.)                                                                                               // lVirtual

//Adiciona a descrição do local de atendimento.
oStr2:AddField( GetSx3Cache("ABS_DESCRI","X3_TITULO"),;                                                		       // cTitle // "Desc. Local"
                GetSx3Cache("ABS_DESCRI","X3_TITULO"),;                                                			   // cToolTip // "Desc. Local"
                "ABS_DESCRI",;                                                                                     // cIdField
                GetSx3Cache("ABS_DESCRI","X3_TIPO"),;                                                              // cTipo
                GetSx3Cache("ABS_DESCRI","X3_TAMANHO"),;                                                           // nTamanho
                GetSx3Cache("ABS_DESCRI","X3_DECIMAL"),;                                                           // nDecimal
                Nil,; 																           							   // bValid
                Nil,;                                                                                         	   // bWhen
                {},;                                                                                               // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual

//Adiciona o municipio do local de atendimento.
oStr2:AddField( GetSx3Cache("ABS_MUNIC","X3_TITULO"),;                                                             // cTitle // Município
                GetSx3Cache("ABS_MUNIC","X3_TITULO"),;                                                             // cToolTip // "Município"
                "ABS_MUNIC",;                                                                                      // cIdField
                GetSx3Cache("ABS_MUNIC","X3_TIPO"),;                                                               // cTipo
                GetSx3Cache("ABS_MUNIC","X3_TAMANHO"),;                                                            // nTamanho
                GetSx3Cache("ABS_MUNIC","X3_DECIMAL"),;                                                            // nDecimal
                Nil,; 																			           				   // bValid
                Nil,;                                                                                         	   // bWhen
                Nil,;                                                                                              // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual

//Adiciona o codigo da entidade.
oStr2:AddField( GetSx3Cache("ABS_CODIGO","X3_TITULO"),;                                                		       // cTitle // "Cód. Entidade"
                GetSx3Cache("ABS_CODIGO","X3_TITULO"),;                                          			          // cToolTip //"Cód. Entidade"
                "ABS_CODIGO",;                                                                                     // cIdField
                GetSx3Cache("ABS_CODIGO","X3_TIPO"),;                                                              // cTipo
                GetSx3Cache("ABS_CODIGO","X3_TAMANHO"),;                                                           // nTamanho
                GetSx3Cache("ABS_CODIGO","X3_DECIMAL"),;                                                           // nDecimal
                Nil,; 																						           	   // bValid
                Nil,;                                                                                         	   // bWhen
                Nil,;                                                                                              // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual

//Adiciona a loja da entidade.
oStr2:AddField( GetSx3Cache("ABS_LOJA","X3_TITULO"),;                                   			                 // cTitle // "Loja Entidade"
                GetSx3Cache("ABS_LOJA","X3_TITULO"),;                                             		          // cToolTip // "Loja Entidade"
                "ABS_LOJA",;                                                                                       // cIdField
                GetSx3Cache("ABS_LOJA","X3_TIPO"),;                                                                // cTipo
                GetSx3Cache("ABS_LOJA","X3_TAMANHO"),;                                                             // nTamanho
                GetSx3Cache("ABS_LOJA","X3_DECIMAL"),;                                                             // nDecimal
                Nil,; 																							              // bValid
                Nil,;                                                                                         	   // bWhen
                Nil,;                                                                                              // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual
                
//Quantidade de equipamentos vendidos na TFI.
oStr2:AddField( GetSx3Cache("TFI_QTDVEN","X3_TITULO"),;                                   			               // cTitle // "Loja Entidade"
                GetSx3Cache("TFI_QTDVEN","X3_TITULO"),;                                             		       // cToolTip // "Loja Entidade"
                "TFI_QTDAVEN",;                                                                                    // cIdField
                GetSx3Cache("TFI_QTDVEN","X3_TIPO"),;                                                              // cTipo
                GetSx3Cache("TFI_QTDVEN","X3_TAMANHO"),;                                                           // nTamanho
                GetSx3Cache("TFI_QTDVEN","X3_DECIMAL"),;                                                           // nDecimal
                Nil,; 																							   // bValid
                Nil,;                                                                                         	   // bWhen
                Nil,;                                                                                              // aValues
                .F.,;                                                           								   // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual

// Adiciona o marcador de seleção dos equipamentos
oStr3:AddField( STR0005,;                                                                                          // cTitle // 'Mark'
                STR0005,;                                                                                          // cToolTip // 'Mark'
                'AA3_FLAG',;                                                                                       // cIdField
                'L',;                                                                                              // cTipo
                1,;                                                                                                // nTamanho
                0,;                                                                                                // nDecimal
                {|oMdl, cCampo, xValueNew, nLine, xValueOld| vldMark(oMdl, cCampo, xValueNew, nLine, xValueOld)},; // bValid
                {|| .T.},;                                                                                         // bWhen
                Nil,;                                                                                              // aValues
                Nil,;                                                                                              // lObrigat
                Nil,;                                                                                              // bInit
                Nil,;                                                                                              // lKey
                .F.,;                                                                                              // lNoUpd
                .T. )                                                                                              // lVirtual

//  Adiciona campo para indicar quando um equipamento já recebeu a marcação
// em outro item da TFI na mesma janela
oStr3:AddField( STR0006,;                          // cTitle // 'Disponivel'
                STR0006,;                          // cToolTip // 'Disponivel'
                'AA3_DISP',;                       // cIdField
                'C',;                              // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                {||'1'},;                          // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual
				
// Adiciona o marcador para validar se o flag faz parte de um kit completo
oStr3:AddField( STR0054,;                          // cTitle // 'KitCom'
                STR0054,;                          // cToolTip // 'KitCom'
                'AA3_KIT',;                        // cIdField
                'L',;                              // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;                              // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual
				
oStr3:AddField( STR0055,;                          // cTitle // 'Reserva'
                STR0055,;                          // cToolTip // 'Reserva'
                'AA3_ITRES',;                      // cIdField
                'N',;                              // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;                              // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual

// Adiciona o campo para receber a legenda 
oStr3:AddField( STR0007,;                          // cTitle // 'Status'
                STR0007,;                          // cTitle // 'Status'
                'AA3_SIT',;                        // cIdField
                'BT',;                             // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                {||At820GetLegend(1)},;            // bValid
                ,;                                 // bWhen
                ,;                                 // aValues
                .F.,;                              // lObrigat
                {|a,b|At820Status(a,b)},;          // bInit
                ,;                                 // lKey
                ,;                                 // lNoUpd
                .T.,;                              // lVirtual
                )                                  // cValid

// Adiciona o campo para receber a ordem de filial "logada" e depois demais
oStr3:AddField( STR0090,;                          // cTitle // "Ordem" 
                STR0090,;                          // cTitle // "Ordem"
                'AA3_ORDEM',;                        // cIdField
                'N',;                             // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                Nil,;            // bValid
                ,;                                 // bWhen
                ,;                                 // aValues
                .F.,;                              // lObrigat
                Nil,;          // bInit
                ,;                                 // lKey
                ,;                                 // lNoUpd
                .T.,;                              // lVirtual
                )                                  // cValid
// campo para a quantidade distribuída do item
oStr4:AddField( STR0091,;                          // cTitle // "Qt Sep" 
                STR0091,;                          // cTitle // "Qt Sep"
                "TWR_QTSEP","N",11,0,Nil,Nil,Nil,.F.,Nil,Nil,.F.,.T. ) // lVirtual

// campo para indicar se há necessidade de gerar o pedido de remessa ou não
oStr4:AddField( STR0092,;                          // cTitle // "Exige NF?" 
                STR0092,;                          // cTitle // "Exige NF?" 
                'TWR_EXIGNF','C',1,0,NIL,NIL,NIL,.F.,NIL,.F.,Nil,.T.)

// Adiciona o marcador para validar se o flag faz parte de um kit completo
oStr5:AddField( STR0054,;                          // cTitle // 'KitCom'
                STR0054,;                          // cToolTip // 'KitCom'
                'AA3_GNKIT',;                      // cIdField
                'L',;                              // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;                              // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual
				
oStr5:AddField( STR0055,;                          // cTitle // 'Reserva'
                STR0055,;                          // cToolTip // 'Reserva'
                'AA3_GNITRES',;                    // cIdField
                'N',;                              // cTipo
                1,;                                // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;                              // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual

// Adiciona o campo para receber a filial do ativo.
oStr5:AddField( STR0093,;                          // cTitle // 'Fil. Ativo'
                STR0094,;                          // cTitle // 'Filial Ativo'
                "TWH_FILORI",;                     // cIdField
                "C",;                              // cTipo
                TamSx3("TWH_FILORI")[1],;          // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;                              // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual

// Adiciona o campo para receber o valor da quantidaade disponivel para locação.
oStr5:AddField( STR0095,;                          // cTitle // "Qtd. Disp."
                STR0096,;                          // cTitle // "Quantidade disponível"
                "AA3_QTDDSP",;                     // cIdField
                "N",;                              // cTipo
                TamSx3("TFI_QTDVEN")[1],;           // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                { || At820Disp() },;	           // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual


oStr5:AddField( STR0097,;                          // cTitle // "Qtd. Res."
                STR0098,;                          // cTitle // "Quantidade reservada"
                "AA3_QTDRES",;                     // cIdField
                "N",;                              // cTipo
                TamSx3("TFI_QTDVEN")[1],;           // nTamanho
                0,;                                // nDecimal
                Nil,;                              // bValid
                Nil,;                              // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;	           				  // bInit
                Nil,;                              // lKey
                .T.,;                              // lNoUpd
                .T. )                              // lVirtual

// Adiciona o campo para receber o valor da quantidaade da reserva para locação.
oStr5:AddField( STR0099,;                          // cTitle // "Qtd. Separação"
                STR0100,;                          // cTitle // "Quantidade Separação"
                "AA3_QTDSEP",;                     // cIdField
                "N",;                              // cTipo
                TamSx3("TFI_QTDVEN")[1],;           // nTamanho
                0,;                                // nDecimal
                {|oMdlGRD, cCmp, xValueNew, nLi , xValueOld| At820VldSp(oMdlGRD, cCmp, xValueNew, nLi , xValueOld )},;// bValid
                Nil,;							   // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;					           // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual

// Adiciona o campo para receber o valor da quantidaade da reserva para locação.
oStr5:AddField( STR0101,;                          // cTitle // "Qtd. Separada"
                STR0102,;                          // cTitle // "Quantidade Separada"
                "AA3_SEPAR",;                      // cIdField
                "N",;                              // cTipo
                TamSx3("TFI_QTDVEN")[1],;           // nTamanho
                0,;                                // nDecimal
                Nil,;							   // bValid
                Nil,;				   			   // bWhen
                Nil,;                              // aValues
                Nil,;                              // lObrigat
                Nil,;	           				   // bInit
                Nil,;                              // lKey
                .F.,;                              // lNoUpd
                .T. )                              // lVirtual


// Adiciona o campo para receber a ordem de filial "logada" e depois demais
oStr5:AddField( STR0090,;                          // cTitle // "Ordem"
                STR0090,;                          // cTitle // "Ordem"
                'AA3_ORDEM','N',1,0,Nil,,,.F.,Nil,,,.T.,)

//-------------------------------------------------------------------------------------------------

xAux := FwStruTrigger( 'AA3_FLAG', 'AA3_DISP', 'At820GtDsp()', .F. )
		oStr3:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

xAux := FwStruTrigger( 'AA3_FLAG', 'AA3_FLAG', 'At820PvAdc()', .F. )
		oStr3:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

xAux := FwStruTrigger( 'AA3_DISP', 'AA3_SIT', 'At820GetLegend(2)', .F. )
		oStr3:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
// -------------------------------------------------------------------------------------------------
xAux := FwStruTrigger( 'TWR_CLIENT', 'TWR_NOME',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLIENT")+FwFldGet("TWR_LOJACL"),"A1_NOME")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TWR_LOJACL', 'TWR_NOME',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLIENT")+FwFldGet("TWR_LOJACL"),"A1_NOME")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TWR_CLENTR', 'TWR_NOMENT',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLENTR")+FwFldGet("TWR_LOJENT"),"A1_NOME")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TWR_LOJENT', 'TWR_NOMENT',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLENTR")+FwFldGet("TWR_LOJENT"),"A1_NOME")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

// gatilhos dos campos de CNPJ >>> essenciais na operação triangular
xAux := FwStruTrigger( 'TWR_CLIENT', 'TWR_CNPJ',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLIENT")+FwFldGet("TWR_LOJACL"),"A1_CGC")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TWR_LOJACL', 'TWR_CNPJ',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLIENT")+FwFldGet("TWR_LOJACL"),"A1_CGC")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TWR_CLENTR', 'TWR_CNPJEN',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLENTR")+FwFldGet("TWR_LOJENT"),"A1_CGC")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
xAux := FwStruTrigger( 'TWR_LOJENT', 'TWR_CNPJEN',;
				'Posicione("SA1",1,xFilial("SA1",FwFldGet("TWR_FILPED"))+FwFldGet("TWR_CLENTR")+FwFldGet("TWR_LOJENT"),"A1_CGC")', .F. )
		oStr4:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])
// -------------------------------------------------------------------------------------------------
//  Gatilho para atualizar as informações para a 
xAux := FwStruTrigger( 'AA3_QTDSEP', 'AA3_QTDSEP','At820TWRGrn()', .F. )
		oStr5:AddTrigger( xAux[1], xAux[2], xAux[3], xAux[4])

// -------------------------------------------------------------------------------------------------

oModel := MPFormModel():New('TECA820', /*bPreValid*/, {|oModel| At820TdOk(oModel)}, {|oModel| At820Grv2(oModel)})
oModel:SetDescription(STR0008) // 'Separação de Equipamentos'

oModel:addFields('CAB_VAZIO',,oStr1)

// Faz a carga dos dados do grid manualmente
oModel:addGrid( 'TFI_ITENS',;                      // cId
                'CAB_VAZIO',;                      // cOwner
                oStr2,;                            // oModelStruct
                ,;                                 // bLinePre
                ,;                                 // bLinePost
                ,;                                 // bPre
                ,;                                 // bLinePost
                {|oModel| SelecTFI(oModel)})       // bLoad

oModel:addGrid( 'AA3_BASES',;                      // cId
                'TFI_ITENS',;                      // cOwner
                oStr3,;                            // oModelStruct
                ,;                                 // bLinePre
                ,;                                 // bLinePost
                ,;                                 // bPre
                ,;                                 // bLinePost
                {|oModel| SelecAA3(oModel)})       // bLoad

oModel:addGrid( 'TWR_PEDIDOS',;                      // cId
                'CAB_VAZIO',;                      // cOwner
                oStr4,;                            // oModelStruct
                {|oMdlG,nLine,cAcao,cCampo,e| At820AvPedAd( oMdlG,nLine,cAcao,cCampo,e ) },;    // bLinePre
                ,;                                 // bLinePost
                ,;                                 // bPre
                ,;                                 // bLinePost
                {|oMdl| {} })       // bLoad

oModel:addGrid( 'AA3_GRANEL',;                     // cId
                'TFI_ITENS',;                      // cOwner
                oStr5,;                            // oModelStruct
                ,;                                 // bLinePre
                ,;                                 // bLinePost
                ,;                                 // bPre
                ,;                                 // bLinePost
                {|oModel| SelecGrn(oModel)})       // bLoad

oModel:SetPrimaryKey( {} )

oModel:getModel('TFI_ITENS'):SetOptional(.T.)
oModel:getModel('TFI_ITENS'):SetNoInsertLine()
oModel:getModel('TFI_ITENS'):SetNoDeleteLine()

oStr2:SetProperty("*", MODEL_FIELD_WHEN,{|| .F.})
oStr2:SetProperty("TFI_SEPSLD", MODEL_FIELD_WHEN,{|| .T.})
oStr2:SetProperty("TFI_QTDAVEN", MODEL_FIELD_WHEN,{|| .T.})

oStr5:SetProperty("AA3_MANPRE", MODEL_FIELD_WHEN,{|| .F.})
oStr5:SetProperty("AA3_OSMONT", MODEL_FIELD_WHEN,{|| .F.})

//oStr5:SetProperty("*", MODEL_FIELD_WHEN,{|| .F.})
//oStr5:SetProperty("AA3_SIT", MODEL_FIELD_WHEN,{|| .T.})
//oStr5:SetProperty("AA3_FLAG", MODEL_FIELD_WHEN,{|| .T.})
//oStr5:SetProperty("AA3_QTDDSP", MODEL_FIELD_WHEN,{|| .T.})
//oStr5:SetProperty("AA3_QTDSEP", MODEL_FIELD_WHEN,{|| .T.})

oModel:getModel('AA3_BASES'):SetOptional(.T.)
oModel:getModel('AA3_BASES'):SetNoInsertLine()
oModel:getModel('AA3_BASES'):SetNoDeleteLine()

oModel:getModel('TWR_PEDIDOS'):SetOptional(.T.)
oModel:getModel('TWR_PEDIDOS'):SetNoInsertLine()
oModel:getModel('TWR_PEDIDOS'):SetNoDeleteLine()

oModel:getModel('AA3_GRANEL'):SetOptional(.T.)
oModel:getModel('AA3_GRANEL'):SetNoInsertLine()
oModel:getModel('AA3_GRANEL'):SetNoDeleteLine()

oModel:getModel('CAB_VAZIO'):SetOnlyQuery()

oModel:getModel('CAB_VAZIO'):SetDescription(STR0009) // 'Dados'
oModel:getModel('TFI_ITENS'):SetDescription(STR0010) // 'Itens a Separar'
oModel:getModel('AA3_BASES'):SetDescription(STR0011) // 'Equip. Locação'
oModel:getModel('TWR_PEDIDOS'):SetDescription(STR0103) // 'Pedidos Adicionais'
oModel:getModel('AA3_GRANEL'):SetDescription(STR0104) // 'Equip. Granel'

oModel:SetActivate( {|oModel| At820MkRes( oModel ), At820SepAuto( oModel ),At820AtSld( oModel ) } )

Return oModel


//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
	Criação da janela para realização da separação dos equipamentos
@since  	09/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function ViewDef()

Local oView  := Nil
Local oModel := ModelDef()
Local oStr1  := FWFormViewStruct():New()
Local oStr2  := FWFormStruct(2,'TFI', {|cCpo| !( Alltrim(cCpo)$'TFI_ITEM' )} )
Local oStr3  := FWFormStruct(2,'AA3', {|cCampo| Alltrim(cCampo)<>'AA3_STATUS' .And. FieldsAA3(cCampo, "1") })
Local oStr4  := FWFormStruct(2,'TWR')
Local oStr5  := FWFormStruct(2,'AA3', {|cCampo| Alltrim(cCampo)<>'AA3_STATUS' .And. FieldsAA3(cCampo, "2") })

oStr1:AddField( 'TFI_NULO',;             // cIdField
                '01',;                   // cOrdem
                STR0058,;                // cTitulo //"Nulo"
                STR0058,;                // cDescric //"Nulo"
                Nil,;                    // aHelp
                'C',;                    // cType
                '@!',;                   // cPicture
                NIL,;                    // nPictVar
                '',;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar

oStr2:AddField(	"TFJ_TPFRET",;           // cIdField
				"35",;                   // cOrdem
				STR0062,;     		     // cTitulo //"Tipo Frete"
				STR0062,;          		 // cDescric //"Tipo Frete"
				NIL,;          			 // aHelp
				"C",;                    // cType
				PesqPict("TFJ","TFJ_TPFRET"),;// cPicture
				NIL,;                    // nPictVar
				"",;                     // Consulta F3
				.F.,;                    // lCanChange
				NIL,;                    // cFolder
				NIL,;                    // cGroup
				{"","1="+STR0063,"2="+STR0064},;// aComboValues //"CIF" # "FOB"
				NIL,;                    // nMaxLenCombo
				NIL,;                    // cIniBrow
				.T.)                     // lVirtual

oStr2:AddField( "ABS_DESCRI",;           // cIdField
                "36",;                   // cOrdem
                STR0065,;           	 // cTitulo //"Desc. Local"
                STR0065,;   			 // cDescric //"Desc. Local"
                Nil,;                    // aHelp
                "GET",;                  // cType
                PesqPict("ABS","ABS_DESCRI"),;// cPicture
                NIL,;                    // nPictVar
                "",;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar

oStr2:AddField( "ABS_MUNIC",;            // cIdField
                "37",;                   // cOrdem
                STR0066,;            	 // cTitulo //"Município"
                STR0066,;  				 // cDescric //"Município"
                Nil,;                    // aHelp
                "GET",;                  // cType
                PesqPict("ABS","ABS_MUNIC"),;// cPicture
                NIL,;                    // nPictVar
                "",;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar

oStr2:AddField( "ABS_CODIGO",;           // cIdField
                "38",;                   // cOrdem
                STR0067,;        		 // cTitulo //"Cód. Entidade"
                STR0067,;   			 // cDescric //"Cód. Entidade"
                Nil,;                    // aHelp
                "GET",;                  // cType
                PesqPict("ABS","ABS_CODIGO"),;// cPicture
                NIL,;                    // nPictVar
                "",;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar
                
oStr2:AddField( "ABS_LOJA",;             // cIdField
                "39",;                   // cOrdem
                STR0068,;      		     // cTitulo //"Loja Entidade"
                STR0068,;    			 // cDescric //"Loja Entidade"
                Nil,;                    // aHelp
                "GET",;                  // cType
                PesqPict("ABS","ABS_LOJA"),;// cPicture
                NIL,;                    // nPictVar
                "",;                     // Consulta F3
                .F.,;                    // lCanChange
                NIL,;                    // cFolder
                NIL,;                    // cGroup
                {},;                     // aComboValues
                Nil,;                    // nMaxLenCombo
                NIL,;                    // cIniBrow
                .T.,;                    // lVirtual
                NIL )                    // cPictVar

oView := FWFormView():New()
oView:SetModel(oModel)

oStr3:AddField( 'AA3_SIT',;              // cIdField
                '01',;                   // cOrdem
                '  ',;                   // cTitulo
                '  ',;                   // cDescric
                {},;                     // aHelp
                'BT',;                   // cType
                '',;                     // cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .T.,;                    // lCanChange
                '01',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr3:AddField( 'AA3_FLAG',;             // cIdField
                '02',;                   // cOrdem
                STR0005,;                // cTitulo // 'Mark'
                STR0005,;                // cDescric // 'Mark'
                {STR0012, STR0013},;     // aHelp  // 'Marque os itens para serem separados ' ### 'no atendimento da locação' 
                'CHECK',;                // cType
                '@!',;                   // cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .T.,;                    // lCanChange
                '01',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr5:AddField( "TWH_FILORI",;           // cIdField
                "05",;                   // cOrdem
                STR0093,;                // cTitulo //"Fil. Ativo"
                STR0094,;                // cDescric //"Filial Ativo"
                {""},;                   // aHelp
                'GET',;                  // cType
                '@!',;                   // cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .F.,;                    // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr5:AddField( "AA3_QTDRES",;           // cIdField
                "08",;                   // cOrdem
                STR0097,;                // cTitulo  //"Qtd. Res."
                STR0098,;                // cDescric //"Quantidade reservada"
                {""},;                   // aHelp
                'GET',;                  // cType
                PesqPict("TFI","TFI_QTDVEN"),;// cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .F.,;                    // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar                

oStr5:AddField( "AA3_QTDDSP",;           // cIdField
                "08",;                   // cOrdem
                STR0095,;                // cTitulo  //"Qtd. Disp."
                STR0096,;                // cDescric //"Quantidade disponível"
                {""},;                   // aHelp
                'GET',;                  // cType
                PesqPict("TFI","TFI_QTDVEN"),;// cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .F.,;                    // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr5:AddField( "AA3_SEPAR",;           // cIdField
                "09",;                  // cOrdem
                STR0101,;               // cTitulo  //"Qtd. Separada"
                STR0102,;               // cDescric //"Quantidade Separada"
                {""},;                   // aHelp
                'GET',;                  // cType
                PesqPict("TFI","TFI_QTDVEN"),;// cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .F.,;                    // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

oStr5:AddField( "AA3_QTDSEP",;           // cIdField
                "10",;                   // cOrdem
                STR0099,;                // cTitulo  //"Qtd. Separação"
                STR0100,;                // cDescric //"Quantidade Separação"
                {""},;                   // aHelp
                'GET',;                  // cType
                PesqPict("TFI","TFI_QTDVEN"),;// cPicture
                Nil,;                    // nPictVar
                Nil,;                    // Consulta F3
                .T.,;		 			 // lCanChange
                '02',;                   // cFolder
                Nil,;                    // cGroup
                Nil,;                    // aComboValues
                Nil,;                    // nMaxLenCombo
                Nil,;                    // cIniBrow
                .T.,;                    // lVirtual
                Nil )                    // cPictVar

//------------------------------------------------------------
//  Reordena os campos para deixar no final das colunas
oStr3:SetProperty('AA3_DESSTA', MVC_VIEW_ORDEM, 'zz')
oStr3:SetProperty('AA3_CODCLI', MVC_VIEW_ORDEM, '12')
oStr3:SetProperty('AA3_LOJA',   MVC_VIEW_ORDEM, '13')
oStr3:SetProperty('AA3_NOMCLI', MVC_VIEW_ORDEM, '14')
oStr3:SetProperty('AA3_FILORI', MVC_VIEW_ORDEM, '03')

oStr5:SetProperty('AA3_FILORI', MVC_VIEW_ORDEM, '03')

// Removo o campo MEMO.
oStr2:RemoveField("TFI_CALCMD")
// remove os campos que somente serão preenchidos na gravação da separação dos pedidos adicionais
oStr4:RemoveField("TWR_CODMOV")
oStr4:RemoveField("TWR_NUMPED")
oStr4:RemoveField("TWR_PEDIT")
oStr4:RemoveField("TWR_ATUFIL")
oStr4:RemoveField("TWR_CODTFI")
oStr4:RemoveField("TWR_SAIDOC")
oStr4:RemoveField("TWR_SAISER")
oStr4:RemoveField("TWR_SAIITE")
oStr4:RemoveField("TWR_SDOCS")
oStr4:RemoveField("TWR_ENTDOC")
oStr4:RemoveField("TWR_ENTSER")
oStr4:RemoveField("TWR_ENTITE")
oStr4:RemoveField("TWR_SDOCE")
oStr4:RemoveField("TWR_QTDSAI")
oStr4:RemoveField("TWR_QTDRET")

oView:CreateHorizontalBox('view_hide', 0)

oView:CreateHorizontalBox('LINHASUP', 50)
oView:CreateFolder( "ABASSUP", "LINHASUP" )
oView:AddSheet("ABASSUP", "ABASUP01", STR0105)	//"Itens Locação"
oView:AddSheet("ABASSUP", "ABASUP02", STR0106)	//"Pedidos adicionais"
oView:CreateHorizontalBox('GRID_TFI', 100,,, "ABASSUP", "ABASUP01")
oView:CreateHorizontalBox('GRID_TWR', 100,,, "ABASSUP", "ABASUP02")

oView:CreateHorizontalBox('LINHAINF', 50)
oView:CreateFolder( "ABASINF", "LINHAINF" )
oView:AddSheet("ABASINF", "ABAINF01", STR0107)	//"Equip. ID único"
oView:AddSheet("ABASINF", "ABAINF02", STR0108)	//"Equip. ID não único"
oView:CreateHorizontalBox('GRID_AA3', 100,,, "ABASINF", "ABAINF01")
oView:CreateHorizontalBox('GRID_GRANEL', 100,,, "ABASINF", "ABAINF02")

oView:AddField('FIELD_HIDE', oStr1, 'CAB_VAZIO' )
oView:AddGrid('TFI_ITENS', oStr2)
oView:AddGrid('AA3_BASES', oStr3)
oView:AddGrid('TWR_PEDIDOS', oStr4)
oView:AddGrid('AA3_GRANEL', oStr5)

oView:SetOwnerView('FIELD_HIDE','view_hide')
oView:SetOwnerView('TFI_ITENS','GRID_TFI')
oView:SetOwnerView('TWR_PEDIDOS','GRID_TWR')
oView:SetOwnerView('AA3_BASES','GRID_AA3')
oView:SetOwnerView('AA3_GRANEL','GRID_GRANEL')

oView:SetViewProperty('TFI_ITENS', 'ONLYVIEW')

oView:EnableTitleView('AA3_BASES', STR0014)	// "Equip. Id Único"
oView:EnableTitleView('TFI_ITENS', STR0015)	// 'Produtos Locados'
oView:EnableTitleView('TWR_PEDIDOS', STR0109) //"Pedidos adicionais"
oView:EnableTitleView('AA3_GRANEL', "Equip. Não Id Único") //"Equip. Granel"
oView:SetDescription(STR0008)					// 'Separação de Equipamentos'

oView:AddUserButton(STR0110,"",{|oModel| Teca040(Nil)},,,)	//"Cons.Base Atend."

oView:SetCloseOnOk({|| .T.} )

Return oView


//------------------------------------------------------------------------------
/*/{Protheus.doc} Menudef
	Rotina para construção do menu
@sample 	Menudef() 
@since		06/09/2013       
@version 	P11.90
@return 	aMenu, ARRAY, lista de opções disponíveis para usuário x rotina
/*/
//------------------------------------------------------------------------------
Static Function Menudef()

Local aMenu := {}

aAdd(aMenu,{ STR0002, 'PesqBrw',         0, 1, 0, .T. } ) // 'Pesquisar'
aAdd(aMenu,{ STR0003, 'VIEWDEF.TECA820', 0, 4, 0, .F. } ) // 'Sep. Equip. (Manual)'
aAdd(aMenu,{ STR0004, 'AT820Auto',       0, 4, 0, .F. } ) // 'Sep. Equip. (Auto)'
aAdd(aMenu,{ STR0073, 'TECR070',         0, 4, 0, .F. } ) // 'Relatório de Picking'
aAdd(aMenu,{ STR0111, 'TECA040(Nil)',    0, 6, 0, .F. } ) // "Consulta Base Atend."

Return aMenu 


//-------------------------------------------------------------------
/*/{Protheus.doc} AT820Auto
	Rotina para indicar a necessidade de pré seleção dos equipamentos para separação 
@since  	16/09/2013
@version 	P11.90
/*/
//-------------------------------------------------------------------
Function AT820Auto( cAlias, nReg, nOpcx )

FWExecView( STR0004,"VIEWDEF.TECA820", MODEL_OPERATION_UPDATE,/*oDlg*/,{||.T.}/*bCloseOnOk*/,/*bOk*/, /*nPercReducao*/) // "Sep. Equip. Auto"
Return 


//-------------------------------------------------------------------
/*/{Protheus.doc} FieldsAA3
	Filtra os campos a serem carregados na view e no model
@since  	17/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function FieldsAA3( cCampo , cFolder )

Local cCposPerm := ""
Local lRet      := .F.
Default cFolder	:= "1"

If cFolder == "1"
	cCposPerm += "AA3_CODPRO#AA3_DESPRO#AA3_NUMSER#AA3_CBASE#AA3_ITEM#AA3_CHAPA#AA3_MODELO#AA3_MANPRE#AA3_EXIGNF#AA3_STATUS#"
	cCposPerm += "AA3_CODCLI#AA3_LOJA#AA3_NOMCLI#AA3_DESSTA#AA3_EQ3#AA3_CODBEM#AA3_OSMONT#AA3_FILORI#AA3_FILIAL"
ElseIf cFolder == "2"
	cCposPerm += "AA3_CODPRO#AA3_DESPRO#AA3_NUMSER#AA3_MANPRE#AA3_EXIGNF#AA3_STATUS#"
	cCposPerm += "AA3_OSMONT#AA3_FILORI#AA3_FILIAL"
Endif

lRet := Alltrim(cCampo) $ cCposPerm

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} SelecTFI
	Função para carga dos itens selecionados na janela anterior
	Filtra os dados utilizando a cládula IN e o campo de Recno
@sample 	SelecTFI()
@since  	09/09/2013
@version 	P11.90
/*/
//-------------------------------------------------------------------
Static Function SelecTFI( oMdl )

Local aRet       := {}
Local cTmpQry    := GetNextAlias()
Local cInUse     := ''
Local xAux       := {}
Local nX         := 0
Local aSave      := GetArea()
Local aSaveTFI   := TFI->( GetArea() )

//---------------------------------------------------
//   Executa o tratamento para ordenar pelo Recno()
// os registros a serem exibidos no grid da TFI

lAutRob := IsBlind()

If lAutRob
	cRecMarcados := cValToChar(TFI->(RECNO()))
	cMarca 	:= GetMark(,"TFI","TFI_OK")
	RecLock("TFI",.F.)
	TFI->TFI_OK  := cMarca
	TFI->(MsUnLock())
EndIf

xAux := StrToKArr( cRecMarcados, "#" )

For nX := 1 To Len( xAux )
	xAux[nX] := Val( xAux[nX] )
Next nX

xAux := aSort( xAux )
cRecMarcados := ''
aEval( xAux, {|x| cRecMarcados += cValToChar( x ) + '#' } ) 

aSize( xAux, 0)
//-----------------------------------------------------
//  Ignora o último caracter '#' para não gerar RECNOs vazios no where
cInUse     := StrTran( SubStr( cRecMarcados, 1, Len(cRecMarcados) - 1), "#", "','" )

If Empty( cInUse )
	cInUse := '0'
EndIf

BeginSql Alias cTmpQry

	COLUMN TFI_PERINI AS DATE
	COLUMN TFI_PERFIM AS DATE
	COLUMN TFI_ENTEQP AS DATE
	COLUMN TFI_COLEQP AS DATE

	SELECT TFI.*
		,SB1.B1_DESC TFI_DESCRI
		,SB1.B1_UM TFI_UM
		,TFJ_TPFRET
	  	,ABS_DESCRI
	  	,ABS_MUNIC
	  	,ABS_CODIGO
	  	,ABS_LOJA
	FROM %Table:TFI% TFI
	INNER JOIN %Table:TFL% TFL
		ON TFL.TFL_FILIAL = %xFilial:TFL%
		AND TFL.TFL_CODIGO = TFI.TFI_CODPAI
		AND TFL.%NotDel%
	INNER JOIN %Table:TFJ% TFJ
		ON TFJ.TFJ_FILIAL = %xFilial:TFJ%
		AND TFJ.TFJ_CODIGO = TFL.TFL_CODPAI
		AND TFJ.%NotDel%
	INNER JOIN %Table:ABS% ABS 
		ON ABS.ABS_FILIAL = %xFilial:ABS%
		AND ABS.ABS_LOCAL = TFL.TFL_LOCAL
		AND ABS.%NotDel%
	INNER JOIN %Table:SB1% SB1
		ON SB1.B1_FILIAL = %xFilial:SB1% 
		AND SB1.B1_COD = TFI.TFI_PRODUT
		AND SB1.%NotDel%

	WHERE TFI.R_E_C_N_O_ IN ( %exp:cInUse% )
	ORDER BY TFI.R_E_C_N_O_

EndSql

aRet := FwLoadByAlias( oMdl, cTmpQry )

(cTmpQry)->(DbCloseArea())

nPosRecsIDU := 1
nPosRecsGRN := 1

RestArea(aSaveTFI)
RestArea(aSave)
Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} SelecAA3
	Função para carga dos equipamentos 
@sample 	SelecAA3()
@since  	13/09/2013
@version 	P11.90
/*/
//-------------------------------------------------------------------
Static Function SelecAA3( oMdl )

Local aRet			:= {}
Local cTmpQry		:= GetNextAlias()
Local cItemProd		:= ""
Local xAux			:= ""
Local cDtVazia		:= Space(8)
Local cExpOrder 	:= ''  // identifica a numeração dos campos AA3_CODPRO e AA3_NUMSER para ordem
Local cDiaIni 		:= ' '
Local cDiaFim 		:= ' '
Local cStrQryDisp	:= ''
Local xListProd 	:= Nil
Local cCposDisp 	:= ''
Local lAT820BATD	:= ExistBlock("AT820BATD")
Local lAT820DTIN	:= ExistBlock("AT820DTIN")
Local aRetPE		:= {}
Local cFilSB5 		:= xFilial("SB5")
Local oStruAA3  	:= oMdl:GetStruct()			
Local nPosOrd 		:= 0
Local nPosPrdt 		:= 0 
Local nPosNSer 		:= 0

If !Empty( StrTran( cRecMarcados, "#", "" ) )
	
	xAux := StrToKArr( cRecMarcados, "#" )
	
	//  se o numero de registros no array pode ser acessado pela variável 
	If Len( xAux ) >= nPosRecsIDU
		
		TFI->( DbGoTo( Val( xAux[nPosRecsIDU] ) ) )
		
		cItemProd := TFI->TFI_PRODUT
		
		aSize( xAux, 0)
		xAux := ""
		
		DbSelectArea("TEZ")
		TEZ->( DbSetOrder( 1 ) ) // TEZ_FILIAL+TEZ_PRODUT
		
		//--------------------------------------------------------------
		//  Verifica se existe configuração de kit para o produto utilizado
		If TEZ->( DbSeek( xFilial("TEZ")+cItemProd ) )
			// identifica os produtos que compoem o kit
			xListProd := {}
			While TEZ->( !EOF() ) .And. TEZ->TEZ_FILIAL = xFilial("TEZ") .And. TEZ->TEZ_PRODUT == cItemProd
				xAux += TEZ->TEZ_ITPROD + "#"
				aAdd( xListProd, TEZ->TEZ_ITPROD )
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
			
		cDiaIni := If(!Empty(TFI->TFI_PERINI),TFI->TFI_PERINI,TFI->TFI_ENTEQP)
		cDiaIni := If( dDataBase > cDiaIni , dDataBase , cDiaIni )
		cDiaFim := If(!Empty(TFI->TFI_PERFIM),TFI->TFI_PERFIM,TFI->TFI_COLEQP)
		
		cCposDisp := "AA3.*, SB1.B1_DESC AA3_DESPRO, SA1.A1_NOME AA3_NOMCLI, 0 AA3_ITRES, " +;      
					  "CASE WHEN AA3.AA3_FILORI = '"  + cFilAnt + "' THEN 0 ELSE 1 END AA3_ORDEM " 
	      				
		cStrQryDisp := "% "+At180xDisp( xListProd, cDiaIni, cDiaFim, dDataBase, cCposDisp, .T./*lOnlyString*/)+" %" 
		
		cDiaFim := DTOS(cDiaFim)
			
		BeginSql Alias cTmpQry
			
          SELECT 
               AA3.*,
               SB1.B1_DESC AA3_DESPRO,
               SA1.A1_NOME AA3_NOMCLI,
               1 AA3_ITRES,
               CASE		
	      			WHEN AA3.AA3_FILORI = %Exp:cFilAnt% THEN 0 
	      			ELSE 1
	   			END AA3_ORDEM
          FROM
               %Table:TEW% TEW
               INNER JOIN %Table:AA3% AA3 ON AA3.AA3_FILORI = TEW.TEW_FILBAT
                                         AND AA3.AA3_NUMSER = TEW.TEW_BAATD
                                         AND AA3.AA3_MSBLQL IN (' ','2') 
                                         AND AA3.%NotDel%
               INNER JOIN %Table:SB1% SB1 ON SB1.B1_FILIAL = %xFilial:SB1% 
                                         AND SB1.B1_COD = TEW.TEW_PRODUT 
                                         AND SB1.%NotDel%
               INNER JOIN %Table:SB5% SB5 ON SB5.B5_FILIAL = %xFilial:SB5% 
                                         AND SB5.B5_COD = SB1.B1_COD
                                         AND SB5.%NotDel%
               LEFT  JOIN %Table:SA1% SA1 ON SA1.A1_FILIAL = %xFilial:SA1% 
                                         AND SA1.A1_COD = AA3.AA3_CODCLI 
                                         AND SA1.A1_LOJA = AA3.AA3_LOJA
                                         AND SA1.%NotDel%
          WHERE
               TEW.TEW_FILIAL = %xFilial:TEW% AND 
               TEW.%NotDel% AND  
               TEW.TEW_RESCOD <> ' ' AND  
               TEW.TEW_RESCOD = %Exp:TFI->TFI_RESERV% AND
               SB5.B5_ISIDUNI <> '2'

          UNION
               %Exp:cStrQryDisp%
       EndSql
		
		aRet := FwLoadByAlias( oMdl, cTmpQry )
		nPosOrd := oStruAA3:GetFieldPos('AA3_ORDEM')
		nPosPrdt := oStruAA3:GetFieldPos('AA3_CODPRO')
		nPosNSer := oStruAA3:GetFieldPos('AA3_NUMSER')
		Asort(aRet,,,{ | x,y |  (Alltrim(Str(x[2,nPosOrd]) + x[2,nPosPrdt] + x[2,nPosNSer])) <  (Alltrim(Str(y[2,nPosOrd]) + y[2,nPosPrdt] + y[2,nPosNSer])) } )
		
		(cTmpQry)->(DbCloseArea())

		nPosRecsIDU++
	EndIf
EndIf
Return aRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At820Status
  Inicializador padrão para identificar as cores iniciais 
@sample 	At820Status() 
@since		11/03/2013       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At820Status(a,b,c,d,e)

Local cColorRet      := 'br_verde'
Local cTabTemp       := Alias()

If (cTabTemp)->AA3_ITRES == 1 
	If (cTabTemp)->AA3_STATUS == AA3_ESTOQUE
		cColorRet := 'br_laranja'
	Else
		cColorRet := 'br_vermelho'
	EndIf
EndIf

Return cColorRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At820MkRes
  Inicializador padrão para identificar as cores iniciais 
@sample 	At820MkRes() 
@since		11/03/2013       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At820MkRes( oModel )

Local nX          := 0
Local nY          := 0
Local aSave       := FwSaveRows(oModel)
Local oMdlTFI     := oModel:GetModel('TFI_ITENS')
Local oMdlAA3     := oModel:GetModel('AA3_BASES')

For nX := 1 To oMdlTFI:Length()

	oMdlTFI:GoLine(nX)

	oMdlTFI:SetValue('TFI_QTDAVEN',oMdlTFI:GetValue('TFI_SEPSLD'))
	If !Empty( oMdlTFI:GetValue('TFI_RESERV') ) .And. oMdlTFI:GetValue('TFI_SEPSLD') > 0
		For nY := 1 To oMdlAA3:Length()
			oMdlAA3:GoLine(nY)
			If oMdlTFI:GetValue('TFI_SEPSLD') > 0 .And. ;
				oMdlAA3:GetValue('AA3_ITRES') == 1 .And. ;
				oMdlAA3:GetValue('AA3_STATUS') == AA3_ESTOQUE
				
				oMdlAA3:SetValue('AA3_FLAG', .T. )

			EndIf
		Next nY
	EndIf

Next nX
FwRestRows( aSave, oModel )
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} At820SepAuto
	Rotina para realizar a seleção automatica dos equipamentos 
	quando a opção de Sep. Automática for selecionada pelo usuário
@since  	16/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function At820SepAuto( oMdlGeral )

Local xValorLim   := Nil
Local lProdKit    := .F.
Local aRows       := {}
Local oMdlItens   := oMdlGeral:GetModel('TFI_ITENS')
Local oMdlEquip   := oMdlGeral:GetModel('AA3_BASES')
Local aKit        := {}
Local cProdRef    := ''
Local nPosKit     := 0
Local nPosItKit   := 0
Local nEquip      := 0
Local nItens      := 0
Local lOk         := .T.
Local lCompleto   := .F.
Local cPrdBase    := ''
Local nX          := 0
Local lTemp       := .T.
Local l820Auto    := IsInCallStack( 'AT820Auto' )
Local nQtdIni     := 0
Local nKit        := 0
Local cFilTEZ		:=	xFilial('TEZ')
Local cFilSB1		:=	xFilial('SB1')

If l820Auto
	
	//  Executar o processo de auto preenchimento dos itens quando o início 
	// para a sugestão automática de separação
	aRows := FwSaveRows( oMdlGeral )
	
	DbSelectArea('TEZ')
		
	//-----------------------------------------------
	//   Verifica se há Kits para locação entre os itens locados
	// e carrega suas estruturas
	For nKit := 1 To oMdlItens:Length()
		
		TEZ->( DbSetOrder( 1 ) )
		oMdlItens:GoLine( nKit )
		cProdRef := oMdlItens:GetValue('TFI_PRODUT')
		If aScan( aKit, {|x| x[1]==cProdRef } ) == 0 .And. TEZ->( DbSeek( cFilTEZ+cProdRef ) )  // A estrutura só é carregada uma vez. E posiciona no primeiro item da tabela
			aAdd( aKit, { cProdRef, {} } )
			nPosKit++
			
			// posiciona e captura as informações dos itens do kit
			While TEZ->( !EOF() ) .And. TEZ->TEZ_FILIAL == cFilTEZ .And. TEZ->TEZ_PRODUT == cProdRef
				aAdd( aKit[nPosKit,2], { TEZ->TEZ_ITPROD, TEZ->TEZ_ITQTDE } )
				TEZ->( DbSkip() )
			EndDo
		EndIf
		
	Next nKit
	
	//--------------------------------------------------------
	//  Seleciona os itens disponíveis
	For nItens := 1 To oMdlItens:Length()
	
		oMdlItens:GoLine( nItens )

		cProdRef := oMdlItens:GetValue('TFI_PRODUT')
		nPosKit := aScan( aKit, {|x| x[1] == cProdRef } )
		nQtdIni := oMdlItens:GetValue('TFI_SEPSLD')
		
		//-----------------------------------------------------------
		//  Calcula o número de itens já separados
		If nPosKit > 0
			xValorLim := {}
			lProdKit  := .T.
		Else
			xValorLim := 0
		EndIf
		
		lCompleto := oMdlItens:GetValue('TFI_SEPSLD') == 0
		
		nEquip := 1
		While lOk .And. !lCompleto .And. nEquip <= oMdlEquip:Length()
		
			oMdlEquip:GoLine( nEquip )
			cPrdBase := oMdlEquip:GetValue('AA3_CODPRO')

			If lProdKit
				nX := aScan( aKit[nPosKit,2], {|x| x[1] == cPrdBase } )
			EndIf
			
			//--------------------------------------------------------
			//  Valida se o equipamento pode ser selecionado 
			If oMdlEquip:GetValue('AA3_DISP')==DEF_STATUS_DISPONIVEL .And. ;
				( ( lProdKit .And. oMdlEquip:Length() >= ( aKit[nPosKit,2,nX,2] * oMdlItens:GetValue('TFI_SEPSLD') ) ) .Or. ;  // verifica se o número de itens no grid de equipamentos pode
				( !lProdKit .And. oMdlEquip:Length() >= oMdlItens:GetValue('TFI_SEPSLD') ) ) // preencher completamente o item (validação genérica) a validação correta é feita no TudoOk()
				
				If lProdKit

					nPosItKit := aScan( xValorLim, {|x| x[1]==cPrdBase } )
					If nPosItKit == 0
						aAdd( xValorLim, { cPrdBase, 0 } )
						nPosItKit := Len( xValorLim )
					EndIf
					
					//-----------------------------------------------------
					//  Caso ainda não tenha atingido a quantidade
					// executa a seleção do item
					If ( aKit[nPosKit,2,nX,2] * oMdlItens:GetValue('TFI_SEPSLD') ) > xValorLim[nPosItKit,2]
						lOk := oMdlEquip:SetValue('AA3_FLAG', .T.)
						xValorLim[nPosItKit,2] += 1  // adiciona o item selecionado
					ElseIf l820Auto .And. ( aKit[nPosKit,2,nX,2] * nQtdIni ) > xValorLim[nPosItKit,2]
						lOk := oMdlEquip:SetValue('AA3_FLAG', .T.)
						xValorLim[nPosItKit,2] += 1  // adiciona o item selecionado
					EndIf

				Else

					lOk := oMdlEquip:SetValue('AA3_FLAG', .T.)
					xValorLim++

				EndIf

				//----------------------------------------------------
				//  Verifica se já completou a quantidade de itens a serem selecionados
				// quando é Kit, verifica todos os itens selecionados
				If nPosKit > 0

					nPosItKit := 1
					lTemp    := .T.
					nX := 0
					While lTemp .And. nPosItKit <= Len( aKit[nPosKit,2] )
						nX    := aScan( xValorLim, {|x|x[1] == aKit[nPosKit,2,nPosItKit,1] } )
						lTemp := lTemp .And. nX > 0 .And. ( xValorLim[nX,2] == aKit[nPosKit,2,nPosItKit,2] )
						nPosItKit++
					EndDo
					lCompleto := lTemp
					lProdKit  := .T.

				Else

					lCompleto := ( oMdlItens:GetValue('TFI_SEPSLD')==0 )

				EndIf

			EndIf
			nEquip++
		EndDo

		If lOk
			lProdKit := .F.
			lCompleto := .F.
			If ValType(xValorLim)=='A'
				aSize( xValorLim, 0 )
				xValorLim := Nil
			EndIf
		Else
			Exit
		EndIf

		oMdlEquip:GoLine( 1 )
	Next nItens
	oMdlItens:GoLine( 1 )
	FwRestRows( aRows )
EndIf
Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} At820AMk
	Marca / Desmarca todos os itens para separação no browse
@sample 	At820AMk(oBrw)
@param		ExpA1 	Objeto FwMarkBrowse .
@return	ExpL 	Verdadeiro
/*/
//------------------------------------------------------------------------------
Static Function At820AMk(oBrw)

Local aRest  := GetArea()

// posiciona no primeiro registro conforme o compartilhamento da tabela
(oBrw:Alias())->(DbSeek(xFilial(oBrw:Alias())))
While (oBrw:Alias())->(!Eof())
	At820Mk(oBrw)  // chama a rotina de marcação simples
	(oBrw:Alias())->(DbSkip())
EndDo
(oBrw:Alias())->(DbSeek(xFilial(oBrw:Alias())))

RestArea(aRest)
oBrw:Refresh()
Return .T.


//------------------------------------------------------------------------------
/*/{Protheus.doc} At820Mk
	Marca / Desmarca os itens de locação de equipamentos no browse
@sample 	At820Mk(oBrw)
@param 		ExpO1 Objeto FwMarkBrowse itens de locação de equipamentos
@return	ExpL  Verdadeiro / Falso
/*/
//------------------------------------------------------------------------------
Static Function At820Mk(oBrw)

Local cPosAlter := cValToChar( (oBrw:Alias())->( Recno() ) ) + "#"

// Verifica se o item está sendo marcado ou desmarcado
If ( !oBrw:IsMark() )
	If	A820VlSCtr( (oBrw:Alias())->TFI_CONTRT, (oBrw:Alias())->TFI_CONREV, .T., (oBrw:Alias())->TFI_SRVEXT == "1"  )	// Verifica se o contrato/revisão do equipamento está vigente
		RecLock(oBrw:Alias(),.F.)
		(oBrw:Alias())->TFI_OK  := oBrw:Mark()
		(oBrw:Alias())->(MsUnLock())
		cRecMarcados += cPosAlter // adiciona o recno as posições selecionadas
	EndIf
Else
	RecLock(oBrw:Alias(),.F.)
	(oBrw:Alias())->TFI_OK  := ""
	(oBrw:Alias())->(MsUnLock())

	cRecMarcados := StrTran( cRecMarcados, cPosAlter, "" ) // remove o recno das posições selecionadas
EndIf
Return .T.  


//-------------------------------------------------------------------
/*/{Protheus.doc} vldMark
	Valida a seleção de um equipamento para separação
@since  	16/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function VldMark( oMdlBase, cCampo, xValueNew, nLine, xValueOld)

Local lRet      := .T.
Local nSelec    := 0
Local nLinPos   := 0
Local lKit      := .F.
Local aRows     := {}
Local cPrdValid := ''
Local oMdlTd    := oMdlBase:GetModel()
Local oMdlTFI   := oMdlTd:GetModel('TFI_ITENS')
Local oMdlAA3	:= oMdlTd:GetModel('AA3_BASES')
Local oViewTFI  := FwViewActive()
Local cFilBas	:= ""
Local cIdUnic	:= ""
Local nX		:= 0
Local lFilEqDisp := .F.
Local lInterfaceOk 	:= .F.
Local lView 		:= .F.

If xValueNew  // estiver selecionando o registro
	
	If ValType(oViewTFI) == "O" .And. oViewTFI:GetModel():GetId()=="TECA820"
		lInterfaceOk := .T.
		lView := .T.
	ElseIf IsBlind()
		lInterfaceOk := .T.
		lView := .F.
	EndIf
	
	If lRet .And. lInterfaceOk .And. ;  // somente verifica a filial quando a view ativa é a separação de equipamentos
		oMdlTFI:GetValue('TFI_FILIAL') <> oMdlBase:GetValue('AA3_FILORI')  // verifica se a filial do item selecionado é diferente da filial do contrato
		
		lFilEqDisp := HasAvailFil( oMdlTFI, oMdlBase )
		
		If lFilEqDisp
			lRet := MsgNoYes( I18N(	STR0112, { oMdlTFI:GetValue("TFI_FILIAL") } ) + CRLF + ;	//"Ainda existem equipamentos disponíveis na filial do Contrato ['#1']."
										STR0113, ;	//"Tem certeza que deseja separar o equipamento de uma filial diferente?"
										STR0114 )	//"Equipamento de Filial diferente do Contrato"
		EndIf					
	Endif

	If lRet
		DbSelectArea('TEZ')
		TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
	
		lKit := TEZ->( DbSeek( xFilial('TEZ')+oMdlTFI:GetValue('TFI_PRODUT') ) )
	
		//Avalia se o item se refere a Requisicao para funcionario e o serial (base instalada) esta marcado para exigir NF
		If !Empty(oMdlTFI:GetValue('TFI_CODTGQ')) .And. oMdlAA3:GetValue("AA3_EXIGNF") == "1"
			lRet := .F.
			Help(,,'AT820ERR06',, STR0046, 1, 0) // "Esse equipamento exige emissão de NF, e essa separação foi originada de uma requisição para atendente. Não será possível marcar esse equipamento."
	
		ElseIf ( oMdlAA3:GetValue('AA3_DISP') == DEF_STATUS_OUTRO )
			lRet := .F.
			Help(,,'AT820ERR01',, STR0016, 1, 0) // 'Item já selecionado para outra alocação sendo separada.'
	
		ElseIf ( oMdlAA3:GetValue('AA3_ITRES') <> 0 .And. oMdlAA3:GetValue('AA3_STATUS') <> AA3_ESTOQUE )
			lRet := .F.
			Help(,,'AT820ERR05',, STR0048, 1, 0) // 'Item reservado indisponível em estoque'
	
		Else	
	
			If !lKit // faz a validação quando não é produto Kit
	
				aRows := FwSaveRows()
				For nLinPos := 1 To oMdlBase:Length()
					oMdlBase:GoLine( nLinPos )
					If oMdlBase:GetValue( 'AA3_FLAG', nLinPos )
						nSelec := (nSelec+1)
						oMdlBase:SetValue('AA3_KIT',.T.)
					EndIf
				Next nLinPos
				FwRestRows( aRows )
	
				If nSelec > oMdlTFI:GetValue('TFI_QTDVEN')
					lRet := .F.
					Help(,,'AT820ERR02',,STR0017 + CRLF + ; // 'Quantidade de itens superou a quantidade vendida.'
						STR0018 ,1,0) // 'Equipamento não será selecionado'
				Else
					oMdlTFI:SetValue('TFI_SEPSLD',oMdlTFI:GetValue('TFI_SEPSLD')-1)
				EndIf
	
			Else
	
				cPrdValid := At820GetPrd( oMdlTd )
				If TEZ->( DbSeek( xFilial('TEZ')+oMdlTFI:GetValue('TFI_PRODUT')+cPrdValid ) )
	
					aRows := FwSaveRows()
					For nLinPos := 1 To oMdlBase:Length()
						oMdlBase:GoLine( nLinPos )
						If oMdlBase:GetValue( 'AA3_FLAG', nLinPos ) .And. At820GetPrd( oMdlTd )==cPrdValid
							nSelec := (nSelec+1)
						EndIf
					Next nLinPos
					FwRestRows( aRows )
	
					If nSelec > ( TEZ->TEZ_ITQTDE * POSICIONE('TFI',1,(xFilial('TFI')+oMdlTFI:GetValue('TFI_COD')),'TFI_SEPSLD') )
						lRet := .F.
						Help(,,'AT820ERR03',, STR0017 + CRLF + ; // 'Quantidade de itens superou a quantidade vendida.'
							STR0019 + CRLF + ; // 'O número de equipamentos selecionados para compor o kit, supera o determinado na estrutura do kit'
							STR0020 + cValtoChar(oMdlTFI:GetValue('TFI_SEPSLD')) + CRLF + ; // 'Quantidade de Kits Vendidos: '
							STR0021 + cValtoChar(TEZ->TEZ_ITQTDE) + CRLF + ; // 'Quantidade definida: '
							STR0022 + cValtoChar(nSelec) ,1,0) // 'Quantidade selecionada: '			
					Else
						lRet := At820DcSld(oMdlTFI,oMdlBase,.F.)				
					EndIf
	
				Else
	
					lRet := .F.
					Help(,,'AT820ERR04',,STR0023,1,0) // 'Produto do tipo kit e não foi identificada sua estrutura'
				EndIf	
			EndIf
	
		EndIf
	
	EndIf
Else
	If ValType(oMdlTFI) == "O"
		DbSelectArea('TEZ')
		TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
		lKit := TEZ->( DbSeek( xFilial('TEZ')+oMdlTFI:GetValue('TFI_PRODUT') ) )
		If	!lKit
			oMdlTFI:SetValue('TFI_SEPSLD',oMdlTFI:GetValue('TFI_SEPSLD')+1)
			If lView
				oViewTFI:Refresh()
			EndIf
		Else
			lRet := At820DcSld(oMdlTFI,oMdlBase,.T.)
		EndIf
	EndIf		
Endif

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} A820VlSCtr
@sample 	A820VlSCtr( cNumContr, cRevContr, lShwMsg )
            Valida se o contrato/revisão no GCT está 'vigente' ou não
@param		cNumContr 	Número do contrato
@param		cRevContr  Revisão do contrato
@param		lShwMsg	.T.=Exibe mensagem na tela; .F.=Não exibe mensagem na tela
@return	.T. = Contrato vigente, pode separar o equipamento // .F. = Contrato não vigente, a separação do equipamento não pode ocorrer
@author	Alexandre da Costa
@since		29/03/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function A820VlSCtr( cNumContr, cRevContr, lShwMsg, lSrvExt )
Local aArea		:= GetArea() 
Local aSaveLines	:= FWSaveRows()
Local lRet			:= .T.
Local cSituac		:=	""

Default lShwMsg	:=	.T.
Default lSrvExt	    :=	.T.

DbSelectArea('CN9')
CN9->(dbSetOrder(1))
If CN9->(DbSeek( xFilial('CN9')+cNumContr + cRevContr))
	cSituac := CN9->CN9_SITUAC
	If ! Empty(cNumContr) .And. cSituac <> "05"	// Verifica se o contrato do GCT associado ao Gestão de Serviços não está VIGENTE
		//01=Cancelado;02=Elaboracao;03=Emitido;04=Aprovacao;05=Vigente;06=Paralisa.;07=Sol. Finalizacao;08=Finali.;09=Revisao;10=Revisado
	 	If	lShwMsg
			Help(,,'AT820ERR07',, STR0057, 1, 0)	//"É permitida a separação de um equipamento somente quando o contrato selecionado for considerado como vigente."
		EndIf
		lRet	:= .F.
	EndIf
Else
	If !lSrvExt
		Help(,,'AT820ERR08',, STR0087, 1, 0)	//"Contrato não gerado para esta filial, altere a filial para poder fazer a separação do equipamento!"
		lRet := .F.
	EndIf
EndIf
FWRestRows( aSaveLines )
RestArea(aArea)
Return	lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At820DcSld
	Realiza validações referente ao decrescimo do saldo, com referência
	ao kit de locação completos.
@since  	26/02/2014
@version  	P12
/*/
//-------------------------------------------------------------------
Function At820DcSld(oMdlTFI,oMdlAct,lDsMark,cFolder)

Local nInd			:= 0
Local nLinPos		:= 0
Local aComps		:= {}
Local aItens		:= {}
Local aArea			:= GetArea()
Local aRows	 		:= {}
Local nCont	 		:= 0	
Local nIni			:= 0
Local nContIt		:= 0
Local nContFl		:= 0
Local nQtdRt		:= 0
Local nPosit		:= 0
Local lEntr	 		:= .F.
Local oViewTFI	 	:= FwViewActive()
Local cFilTFI		:= xFilial("TFI")
Local cFilTEZ		:= xFilial("TEZ")
Local nSepSld		:= 0
Local lRet			:= .T.
Local nX			:= 0
Local nSep			:= 0
Local cPrdTemp 		:= ""
Local oMdlSep		:= oMdlAct:GetModel()
Local oMdlAA3		:= oMdlSep:GetModel('AA3_BASES')
Local oMdlGRN		:= oMdlSep:GetModel('AA3_GRANEL')
Default cFolder		:= "1"

aAreaTFI	:= GetArea("TFI")
DbSelectArea("TFI")
DbSetOrder(1)
If TFI->(DbSeek(cFilTFI+oMdlTFI:GetValue('TFI_COD') ))
	nQtdIni	:= TFI->TFI_SEPSLD
EndIf
RestArea(aAreaTFI)
aRows	:= FwSaveRows()	

nSepSld	:= Posicione('TFI',1,(cFilTFI+oMdlTFI:GetValue('TFI_COD')),'TFI_SEPSLD')
nSepSld	:= If(nSepSld > 0, nSepSld, 1)
For nIni := 1 To nSepSld
	Aadd(aComps,{oMdlTFI:GetValue('TFI_PRODUT'),{},{}})
Next nIni

For nInd := 1 To Len(aComps)
	DbSelectArea('TEZ')
	TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
	If TEZ->( DbSeek( cFilTEZ+oMdlTFI:GetValue('TFI_PRODUT') ) )
		While TEZ->(!EOF()) .AND. TEZ->TEZ_FILIAL == cFilTEZ .AND. TEZ->TEZ_PRODUT == oMdlTFI:GetValue('TFI_PRODUT')
			For nIni := 1 To TEZ->TEZ_ITQTDE
				Aadd(aComps[nInd][2],TEZ->TEZ_ITPROD)
			Next nIni
			TEZ->( DbSkip() )
		EndDo
	EndIf
Next nInd

For nLinPos := 1 To oMdlAA3:Length()
	oMdlAA3:GoLine( nLinPos )
	cPrdTemp := At820GetPrd( oMdlTFI:GetModel(), , "AA3_BASES" )
	If oMdlAA3:GetValue( 'AA3_FLAG', nLinPos ) .And. TEZ->( DbSeek( cFilTEZ+oMdlTFI:GetValue('TFI_PRODUT')+cPrdTemp ) )
		Aadd(aItens,{cPrdTemp,oMdlAA3:GetValue( 'AA3_NUMSER', nLinPos ),.F.,oMdlAA3:GetValue( 'AA3_EXIGNF', nLinPos) })	
	EndIf
Next nLinPos
For nLinPos := 1 To oMdlGRN:Length()
	oMdlGRN:GoLine( nLinPos )
	cPrdTemp := At820GetPrd( oMdlTFI:GetModel(), , "AA3_GRANEL" )
	If oMdlGRN:GetValue( 'AA3_QTDSEP', nLinPos ) > 0 .And. TEZ->( DbSeek( cFilTEZ+oMdlTFI:GetValue('TFI_PRODUT')+cPrdTemp ) )	
		nSep := oMdlGRN:GetValue( 'AA3_QTDSEP', nLinPos )
		For nX := 1 To nSep
			Aadd(aItens,{cPrdTemp,oMdlGRN:GetValue( 'AA3_NUMSER', nLinPos ),.F.,oMdlGRN:GetValue( 'AA3_EXIGNF', nLinPos) })		
		Next nX
	Endif
Next nLinPos

nQtdRt	:= 0
For nCont := 1 To Len(aComps)
	lEntr	:= .T.
	For nContFl := 1 To Len(aComps[nCont][2])
		For nContIt := 1 To Len(aItens)
			If aItens[nContIt][1] == aComps[nCont][2][nContFl] .AND. !aItens[nContIt][3]
				If lEntr
					Aadd(aComps[nCont][3],aItens[nContIt][2])
					aItens[nContIt][3]	:= .T.
					nPosit					:= nContIt
					lEntr					:= .F.
					Exit
				Else
					If 	aItens[nContIt][4] == aItens[nPosit][4]
						Aadd(aComps[nCont][3],aItens[nContIt][2])
						aItens[nContIt][3]	:= .T.
						Exit
					Else
						Help(,,STR0042,, STR0043, 1, 0) //'Seleção Inválida'#"Para composição do Kit, todos os equipamentos devem ter a mesma configuração referente a geração de Nota Fiscal"
						lRet	:= .F.
					EndIf
				EndIf
			EndIf
		Next nContIt
	Next nContFl
	If Len(aComps[nCont][2]) == Len(aComps[nCont][3])
		nQtdRt++
		oMdlTFI:SetValue('TFI_SEPSLD',Posicione('TFI',1,(cFilTFI+oMdlTFI:GetValue('TFI_COD')),'TFI_SEPSLD') - nQtdRt)
		lEntrou	:= .F.
	ElseIf cFolder == "1" .And. !lEntrou .AND. nCont == 1 .AND. Len(aComps[nCont][3]) < Len(aComps[nCont][2]) .AND. Len(aComps[nCont][3]) == Len(aComps[nCont][2])-1 .AND. lDsMark
		oMdlTFI:SetValue('TFI_SEPSLD',oMdlTFI:GetValue('TFI_SEPSLD')+1)
		oViewTFI:Refresh()
		lEntrou	:= .T.
	Elseif cFolder == "2" .AND. nQtdRt == 0 .And. Len(aComps[nCont][3]) < Len(aComps[nCont][2]) .AND. lDsMark
		If oMdlTFI:GetValue('TFI_SEPSLD') < oMdlTFI:GetValue('TFI_QTDAVEN')
			oMdlTFI:SetValue('TFI_SEPSLD',oMdlTFI:GetValue('TFI_SEPSLD')+1)
			oViewTFI:Refresh()
			lEntrou	:= .T.
		Endif
	EndIf
Next nCont

For nLinPos := 1 To oMdlAA3:Length()
	oMdlAA3:GoLine( nLinPos )
	oMdlAA3:SetValue('AA3_KIT',.F.)
Next nLinPos

For nLinPos := 1 To oMdlGRN:Length()
	oMdlGRN:GoLine( nLinPos )
	oMdlGRN:SetValue('AA3_GNKIT',.F.)
Next nLinPos
For nLinPos := 1 To oMdlAA3:Length()
	oMdlAA3:GoLine( nLinPos )
	For nCont := 1 To Len(aComps)
		If Len(aComps[nCont][2]) == Len(aComps[nCont][3])
			For nInd := 1 To Len(aComps[nCont][3])
				If oMdlAA3:GetValue( 'AA3_NUMSER', nLinPos) == aComps[nCont][3][nInd]
					oMdlAA3:SetValue('AA3_KIT',.T.)
				EndIf
			Next nInd
		EndIf
	Next nCont
Next nLinPos

For nLinPos := 1 To oMdlGRN:Length()
	oMdlGRN:GoLine( nLinPos )
	For nCont := 1 To Len(aComps)
		If Len(aComps[nCont][2]) == Len(aComps[nCont][3])
			For nInd := 1 To Len(aComps[nCont][3])
				If oMdlGRN:GetValue( 'AA3_NUMSER', nLinPos) == aComps[nCont][3][nInd]
					oMdlGRN:SetValue('AA3_GNKIT',.T.)
				EndIf
			Next nInd
		EndIf
	Next nCont
Next nLinPos
	
FwRestRows( aRows )
RestArea(aArea)

Return	lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At820GetLegend
	Retorna a legenda utilizado para marcação dos status da rotina
@since  	22/10/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Function At820GetLegend( nTipo )

Local oLegenda   := Nil
Local oMdlFull	 := FwModelActive()
Local oMdlAA3 	 := oMdlFull:GetModel("AA3_BASES")

Static xRet      := Nil
Static lExibeLeg := .T.

DEFAULT nTipo    := 1

If nTipo == 1

	If lExibeLeg
		oLegenda := FwLegend():New()
			oLegenda:Add('AA3_ITRES = 1 .And. AA3_DISP ="' + DEF_STATUS_SELECIONADO + '"','WHITE', STR0049) // 'Item reservado selecionado'
			oLegenda:Add('AA3_ITRES = 1 .And. AA3_STATUS ="'+AA3_ESTOQUE+'"',             'ORANGE',STR0050) // 'Item Reservado'
			oLegenda:Add('AA3_ITRES = 1 .And. AA3_STATUS <>"'+AA3_ESTOQUE+'"',            'RED',   STR0051) // 'Item Reservado Indisponível' 
			oLegenda:Add('AA3_ITRES = 0 .And. AA3_DISP ="' + DEF_STATUS_DISPONIVEL + '"', 'GREEN', STR0024) // 'Disponível para seleção'
			oLegenda:Add('AA3_ITRES = 0 .And. AA3_DISP ="' + DEF_STATUS_SELECIONADO + '"','BLUE',  STR0025) // 'Selecionado neste item'
			oLegenda:Add('AA3_ITRES = 0 .And. AA3_DISP ="' + DEF_STATUS_OUTRO + '"',      'YELLOW',STR0026) // 'Separado em outro item'		
		oLegenda:View()
		lExibeLeg := .F.
		oLegenda := Nil
		DelClassIntf()
	EndIf
	xRet := .T.

ElseIf nTipo == 2
	// processa a atualização dos itens no outros grids
	At820LegReplBase()

	If oMdlAA3:GetValue('AA3_DISP') == DEF_STATUS_OUTRO
		xRet := 'br_amarelo'
	ElseIf oMdlAA3:GetValue('AA3_DISP') == DEF_STATUS_SELECIONADO .And. oMdlAA3:GetValue('AA3_ITRES') == 1
		xRet := 'br_branco'  // item reservado selecionado
	ElseIf oMdlAA3:GetValue('AA3_ITRES') == 1 .And. oMdlAA3:GetValue('AA3_STATUS') == AA3_ESTOQUE
		xRet := 'br_laranja'  // item reservado
	ElseIf oMdlAA3:GetValue('AA3_ITRES') == 1 .And. oMdlAA3:GetValue('AA3_STATUS') <> AA3_ESTOQUE
		xRet := 'br_vermelho'  // item reservado indisponível em estoque
	ElseIf oMdlAA3:GetValue('AA3_DISP') == DEF_STATUS_SELECIONADO
		xRet := 'br_azul'  // selecionado neste item
	Else
		xRet := 'br_verde' // disponível
	EndIf
EndIf

lExibeLeg := !lExibeLeg

Return xRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At820LegReplBase
	Replica o status da base de atendimento para os demais produtos
	que possuem a mesma base
@since  	23/10/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Function At820LegReplBase()

Local oGeral      := FwModelActive()
Local oMdlAA3	  := oGeral:GetModel("AA3_BASES")
Local nLinProd    := 0
Local nLinbase    := 0
Local nLinPosPrd  := 0
Local nLinPosBas  := 0
Local cRet		  := ""
Local cBaseAtd    := ""
Local cProd       := ""
Local dDtIniPlan  := oGeral:GetModel('TFI_ITENS'):GetValue('TFI_PERINI')
Local dDtFimPlan  := oGeral:GetModel('TFI_ITENS'):GetValue('TFI_PERFIM')
Local dDtIniAval  := CTOD('')
Local dDtFimAval  := CTOD('')
Local oMdlPrds    := Nil
Local oMdlBase    := Nil
Local cMarkUse    := ''
Local aSaveLines  := {}
Local cProdAA3    := ""
Local cAA3FilOri  := ""

Static lExecutando := .F.

If oGeral:GetId() == 'TECA820' .And. !lExecutando
	
	lExecutando := .T.

	cRet		:= oMdlAA3:GetValue('AA3_SIT')
	cBaseAtd    := oMdlAA3:GetValue('AA3_NUMSER')
	cProd       := oMdlAA3:GetValue('AA3_CODPRO')
	cProdAA3 	:= cProd
	cAA3FilOri 	:= oMdlAA3:GetValue('AA3_FILORI')

	//  Busca por itens de kit para locação para ver se o produto
	// faz parte de kit
	cProd += '*' + SeekProdsRef( cProd )
	
	aSaveLines := FwSaveRows()
	oMdlPrds := oGeral:GetModel('TFI_ITENS')
	oMdlBase := oGeral:GetModel('AA3_BASES')
	
	// -------------------------------------------------------------------
	//  Identifica qual o tipo de marcação deve fazer no campo de disponibilidade
	cMarkUse := If( oMdlAA3:GetValue('AA3_DISP')=='2', DEF_STATUS_OUTRO, DEF_STATUS_DISPONIVEL )
	nLinPosPrd := oMdlPrds:GetLine()
	nLinPosBas := oMdlBase:GetLine()
	For nLinProd := 1 To oMdlPrds:Length()
		If nLinProd <> nLinPosPrd
			
			oMdlPrds:GoLine( nLinProd )
			//  Somente verifica se o produto da TFI é referência e pode ter como item
			// o produto da base
			If oMdlPrds:GetValue('TFI_PRODUT') $ cProd .Or. ;
				At820IsTWS( xFilial("SB1",oMdlBase:GetValue('AA3_FILORI')), oMdlBase:GetValue('AA3_CODPRO') )
				
				dDtIniAval := oMdlPrds:GetValue('TFI_PERINI')
				dDtFimAval := oMdlPrds:GetValue('TFI_PERFIM')
				For nLinbase := 1 To oMdlBase:Length()
					oMdlBase:GoLine(nLinbase)
					If !oMdlBase:GetValue('AA3_FLAG') .And. ;  // linha não deve estar marcada
							oMdlBase:GetValue('AA3_CODPRO') == cProdAA3 .And. ;
							oMdlBase:GetValue('AA3_FILORI') == cAA3FilOri .And. ;
							oMdlBase:GetValue('AA3_NUMSER') == cBaseAtd .And. ; // Número de série do equipamento igual
							( ( dDtIniPlan >= dDtIniAval .And. dDtIniPlan <= dDtFimAval ) .Or. ; 
								( dDtFimPlan >= dDtIniAval .And. dDtFimPlan <= dDtFimAval ) .Or. ;
								( dDtIniPlan < dDtIniAval .And. dDtFimPlan > dDtFimAval ) )
								
						oMdlBase:SetValue( 'AA3_DISP', cMarkUse )
					EndIf
				Next nLinbase
				oMdlBase:GoLine(1)
			EndIf
		
		EndIf
	Next nLinProd

	FwRestRows( aSaveLines )
	lExecutando := .F.
	oMdlPrds:GoLine( nLinPosPrd )
	oMdlBase:GoLine( nLinPosBas )
EndIf

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} SeekProdsRef
	Consulta na tabela de kit para locação se um determinado produto 
	faz parte de kit. Caso faça parte de algum kit gera query para identificar 
	todos os produtos refeRência a qual faça parte
@since  	23/10/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function SeekProdsRef( cCodProd )

Local cPrdConc	:= ''
Local cQryAlias	:= ''

DbSelectArea('TEZ')
TEZ->( DbSetOrder( 2 ) ) //TEZ_FILIAL+TEZ_ITPROD
If TEZ->( DbSeek( xFilial('TEZ')+cCodProd ) )
	cQryAlias := GetNextAlias()
	BeginSql Alias cQryAlias
		SELECT DISTINCT ( TEZ.TEZ_PRODUT )
		  FROM	%Table:TEZ% TEZ
		 WHERE TEZ_FILIAL = %xFilial:TEZ%
		   AND TEZ.TEZ_ITPROD = %Exp:cCodProd%
		   AND TEZ.%NotDel%
	EndSql
	While (cQryAlias)->( !EOF() )
		cPrdConc += '*' + (cQryAlias)->TEZ_PRODUT
		(cQryAlias)->( DbSkip() )
	EndDo
	(cQryAlias)->( DbCloseArea() )
EndIf

Return cPrdConc


//-------------------------------------------------------------------
/*/{Protheus.doc} At820TdOk
	Executa a validação e preenchimento do array que servirá de referência 
	para a gravação dos dados...
	O array 'aItensOk' será preenchido para evitar realizar loops e novamente
	a validação dentro da função de commit
@since  	24/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function At820TdOk( oMdlGeral )

Local lOk			:= .T.
Local lKitOk		:= .F.
Local aKit			:= {}
Local nPosKit		:= 0
Local nItens		:= 0
Local nEquip		:= 0
Local oMdlItens		:= oMdlGeral:GetModel('TFI_ITENS')
Local oMdlEquip		:= oMdlGeral:GetModel('AA3_BASES')
Local oMdlGranel	:= oMdlGeral:GetModel('AA3_GRANEL')
Local aRows			:= {}
Local cProdRef		:= ''
Local nQtdeProd		:= 0
Local nQtdeTot		:= 0
Local cPrdBase		:= ''
Local nPosBase		:= 0
Local nLinPos		:= 0
Local xTemp			:= Nil
Local nX			:= 0
Local cCodCli		:= ''
Local cLojCli		:= ''
Local aPrcSB1		:= {}  // { CODIGO, OK? }
Local lKit			:= .T.
Local cFilTFI		:= xFilial("TFI")
Local cFilTEZ		:= xFilial('TEZ')
Local cFilSB1		:= xFilial('SB1')
Local oMdlPvAdic 	:= oMdlGeral:GetModel('TWR_PEDIDOS')
Local nInd			:= 0
Local aComps		:= {}
Local nCont	 		:= 0	
Local nIni			:= 0
Local nContIt		:= 0
Local nContFl		:= 0
Local nPosit		:= 0
Local lEntr	 		:= .F.
Local nSepSld		:= 0
Local nSep			:= 0
Local aItens		:= {}
Local lSepOk		:= .F.

aItensOk	:= {}
aRows		:= FwSaveRows( oMdlGeral )
DbSelectArea('TEZ')
TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
DbSelectArea('SB1')
SB1->( DbSetOrder( 1 ) ) //B1_FILIAL+B1_COD

//-----------------------------------------------
//   Verifica se há Kits para locação entre os itens locados
// e carrega suas estruturas
For nItens := 1 To oMdlItens:Length()

	oMdlItens:GoLine( nItens )
	cProdRef := oMdlItens:GetValue('TFI_PRODUT')
	
	If aScan( aKit, {|x| x[1]==cProdRef } ) == 0 .And. TEZ->( MSSeek( cFilTEZ+cProdRef ) )
		// A estrutura só é carregada uma vez. E posiciona no primeiro item da tabela. 
		aAdd( aKit, {cProdRef, {}} )
		nPosKit++
		// posiciona e captura as informações dos itens do kit
		While TEZ->( !EOF() ) .And. TEZ->TEZ_FILIAL == cFilTEZ .And. TEZ->TEZ_PRODUT == cProdRef
			aAdd( aKit[nPosKit,2], { TEZ->TEZ_ITPROD, TEZ->TEZ_ITQTDE } )
			TEZ->( DbSkip() )
		EndDo
	EndIf
	
	// --------------------------------------------------------------------------------
	//  Valida se todos os itens da TFI são válidos ( relacionamento com TFL e TFJ )
	//  obs: aplica-se apenas quando origem nao é de REQUISIÇÕES
	If Empty(oMdlItens:GetValue('TFI_CODTGQ'))
		If !( lOk := At820CliLoj( @cCodCli, @cLojCli, oMdlItens:GetValue('TFI_COD') ) )
			Help(,,'AT820ORC',,STR0027 + CRLF + ; // 'Não foi possível identificar os elementos superiores (Item de Venda da Locação, Local e Orçamento de Serviços)'
				STR0028 + CRLF + ; // 'Não será possível realizar a geração correta do item.'
				STR0029 + ' = ' + oMdlItens:GetValue('TFI_COD') , 1, 0 ) // 'Código da venda '
			Exit
		EndIf
	EndIf
	If lOk .And. !lSepOk
		For nLinPos := 1 To oMdlEquip:Length()
			oMdlEquip:GoLine( nLinPos )
			If oMdlEquip:GetValue( 'AA3_FLAG', nLinPos )
				lSepOk := .T.
				Exit
			Endif
		Next nLinPos		

		For nLinPos := 1 To oMdlGranel:Length()
			oMdlGranel:GoLine( nLinPos )
			If oMdlGranel:GetValue( 'AA3_QTDSEP', nLinPos ) > 0
				lSepOk := .T.
				Exit
			Endif
		Next nLinPos
	Endif
Next nItens
If !lSepOk
	Help( , , "At820TdOk", ,STR0115, 1, 0,,,,,,{STR0116})	//"Não foi possível realizar a separação." ## "É necessário selecionar ou informar a quantidade do(s) equipamento(s) para a separação."
	lOk := .F.
Endif

If lOk
	For nItens := 1 To oMdlItens:Length()
	
		aComps := {}
		aItens := {}
		oMdlItens:GoLine( nItens )
		nSepSld := Posicione('TFI',1,(cFilTFI+oMdlItens:GetValue('TFI_COD')),'TFI_SEPSLD')
		
		If ((nSepSld - oMdlItens:GetValue('TFI_SEPSLD')) <> 0 )
			nSepSld	:= (oMdlItens:GetValue('TFI_QTDVEN')-nSepSld)
			nSepSld := (oMdlItens:GetValue('TFI_QTDVEN')-(oMdlItens:GetValue('TFI_SEPSLD')+nSepSld))
			nSepSld	:= If(nSepSld > 0, nSepSld, 1)
		Else
			nSepSld := 0
		Endif			

		For nIni := 1 To nSepSld
			Aadd(aComps,{oMdlItens:GetValue('TFI_PRODUT'),{},{}})
		Next nIni
	
		For nInd := 1 To Len(aComps)
			DbSelectArea('TEZ')
			TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
			If TEZ->( DbSeek( cFilTEZ+oMdlItens:GetValue('TFI_PRODUT') ) )
				While TEZ->(!EOF()) .AND. TEZ->TEZ_FILIAL == cFilTEZ .AND. TEZ->TEZ_PRODUT == oMdlItens:GetValue('TFI_PRODUT')
					For nIni := 1 To TEZ->TEZ_ITQTDE
						Aadd(aComps[nInd][2],TEZ->TEZ_ITPROD)
					Next nIni
					TEZ->( DbSkip() )
				EndDo
			EndIf
		Next nInd		
		
		cProdRef := oMdlItens:GetValue('TFI_PRODUT')
		nQtdeTot := oMdlItens:GetValue('TFI_QTDVEN')
		nQtdeProd := oMdlItens:GetValue('TFI_SEPSLD')
		nPosKit := aScan( aKit, {|x| x[1]==cProdRef } )
		
		If !( oMdlEquip:IsEmpty() )
			For nLinPos := 1 To oMdlEquip:Length()
				oMdlEquip:GoLine( nLinPos )
				cPrdTemp := At820GetPrd( oMdlItens:GetModel(), , "AA3_BASES" )
				If oMdlEquip:GetValue( 'AA3_FLAG', nLinPos ) .And. TEZ->( DbSeek( cFilTEZ+oMdlItens:GetValue('TFI_PRODUT')+cPrdTemp ) )
					Aadd(aItens,{cPrdTemp,oMdlEquip:GetValue( 'AA3_NUMSER', nLinPos ),.F.,oMdlEquip:GetValue( 'AA3_EXIGNF', nLinPos) })	
				EndIf
			Next nLinPos
			If nPosKit > 0
				xTemp := {}
				lKitOk := .T.
				For nLinPos := 1 To oMdlEquip:Length()
					oMdlEquip:GoLine( nLinPos )
					If !( oMdlEquip:GetValue('AA3_KIT',nLinPos) )
						oMdlEquip:LoadValue('AA3_FLAG',.F.)		
					EndIf				
				Next nLinPos
			Else
				xTemp := 0 //quando não é kit
			EndIf
			
			For nEquip := 1 To oMdlEquip:Length()
			
				oMdlEquip:GoLine( nEquip )
				cPrdBase := oMdlEquip:GetValue('AA3_CODPRO')
				cFilSB1	:= xFilial('SB1', oMdlEquip:GetValue('AA3_FILORI'))
				If SB1->( DbSeek( cFilSB1+cPrdBase ) ) .And. aScan( aPrcSB1, {|x| x[1] == cPrdBase } ) == 0
					aAdd( aPrcSB1, { cPrdBase, SB1->B1_PRV1 <> 0.00 } )
				EndIf
				
				If oMdlEquip:GetValue('AA3_FLAG')
				
					// quando for Kit, irá preencher uma lista com a quantidade de produtos selecionados 
					If nPosKit > 0
						// verifica se o produto já está na lista de itens selecionados
						If ( nPosBase := aScan( xTemp, {|pos| pos[1] == cPrdBase } ) ) > 0
							xTemp[nPosBase,2] += 1
						Else
							aAdd( xTemp, { cPrdBase, 1 } )
						EndIf
					Else
						xTemp += 1 // Adiciona 1 a quantidade de itens selecionados
					EndIf
				ElseIf lKitOk
					lKit := .F.					
				EndIf
				
			Next nEquip
		
			oMdlEquip:GoLine( 1 )
	
		Endif

		If !( oMdlGranel:IsEmpty() )
		
			For nLinPos := 1 To oMdlGranel:Length()
				oMdlGranel:GoLine( nLinPos )
				cPrdTemp := At820GetPrd( oMdlItens:GetModel(), , "AA3_GRANEL" )
				If oMdlGranel:GetValue( 'AA3_QTDSEP', nLinPos ) > 0 .And. TEZ->( DbSeek( cFilTEZ+oMdlItens:GetValue('TFI_PRODUT')+cPrdTemp ) )	
					nSep := oMdlGranel:GetValue( 'AA3_QTDSEP', nLinPos )
					For nX := 1 To nSep
						Aadd(aItens,{cPrdTemp,oMdlGranel:GetValue( 'AA3_NUMSER', nLinPos ),.F.,oMdlGranel:GetValue( 'AA3_EXIGNF', nLinPos) })		
					Next nX
				Endif
			Next nLinPos		
			If nPosKit > 0
				xTemp := {}
				lKitOk := .T.
				For nLinPos := 1 To oMdlGranel:Length()
					oMdlGranel:GoLine( nLinPos )
					If !( oMdlGranel:GetValue('AA3_GNKIT',nLinPos) )
						oMdlGranel:LoadValue('AA3_QTDSEP', 0 )
					EndIf				
				Next nLinPos
			Else
				xTemp := 0 //quando não é kit
			EndIf					

			For nEquip := 1 To oMdlGranel:Length()
			
				oMdlGranel:GoLine( nEquip )
				cPrdBase := oMdlGranel:GetValue('AA3_CODPRO')
				cFilSB1	:= xFilial('SB1', oMdlGranel:GetValue('AA3_FILORI'))
				If SB1->( DbSeek( cFilSB1+cPrdBase ) ) .And. aScan( aPrcSB1, {|x| x[1] == cPrdBase } ) == 0
					aAdd( aPrcSB1, { cPrdBase, SB1->B1_PRV1 <> 0.00 } )
				EndIf
				
				If oMdlGranel:GetValue('AA3_QTDSEP') > 0
								
					// quando for Kit, irá preencher uma lista com a quantidade de produtos selecionados 
					If nPosKit > 0
						// verifica se o produto já está na lista de itens selecionados
						If ( nPosBase := aScan( xTemp, {|pos| pos[1] == cPrdBase } ) ) > 0
							xTemp[nPosBase,2] += 1
						Else
							aAdd( xTemp, { cPrdBase, 1 } )
						EndIf
					Else
						xTemp += 1 // Adiciona 1 a quantidade de itens selecionados
					EndIf
				ElseIf lKitOk
					lKit := .F.					
				EndIf
				
			Next nEquip
				
			oMdlGranel:GoLine( 1 )	
		
		Endif

		For nCont := 1 To Len(aComps)
			lEntr	:= .T.
			For nContFl := 1 To Len(aComps[nCont][2])
				For nContIt := 1 To Len(aItens)
					If aItens[nContIt][1] == aComps[nCont][2][nContFl] .AND. !aItens[nContIt][3]
						If lEntr
							Aadd(aComps[nCont][3],aItens[nContIt][2])
							aItens[nContIt][3]	:= .T.
							nPosit					:= nContIt
							lEntr					:= .F.
							Exit
						Else
							If 	aItens[nContIt][4] == aItens[nPosit][4]
								Aadd(aComps[nCont][3],aItens[nContIt][2])
								aItens[nContIt][3]	:= .T.
								Exit
							Else
								Help(,,STR0042,, STR0043, 1, 0) //'Seleção Inválida'#"Para composição do Kit, todos os equipamentos devem ter a mesma configuração referente a geração de Nota Fiscal"
								lOk	:= .F.
							EndIf
						EndIf
					EndIf				
				Next nContIt
			Next nContFl
		Next nCont
		
		// Verifica se está completamente preenchido e adiciona aos itens válidos para gravação
		If lOk
			If nPosKit > 0
				If lKitOk
					aAdd( aItensOk, nItens )
				EndIf
			Else
				If ValType(xTemp) == "N"
					If xTemp > 0 .And. ( xTemp + nQtdeProd <= nQtdeTot )
						aAdd( aItensOk, nItens )
					EndIf
				Endif
			EndIf
		Endif

		For nContIt := 1 To Len(aItens)
			If !aItens[nContIt][3]
				lOk := .F.
				Help(" ",1,'AT820Kit',,STR0047,1,0) //"É necessario selecionar todos os itens do Kit para realizar a gravação!"
				Exit
			Endif
		Next nContIt

		If !lOk
			Exit
		Endif

	Next nItens
	
	If ( aScan( aPrcSB1, {|x| !x[2] } ) ) <> 0
		lOk := .F.
		xTemp := ''
		aEval( aPrcSB1, {|x| If( !x[2], xTemp += x[1] + CRLF, Nil ) } )
		Help(,,'AT820PRCPRD',, STR0041 + CRLF + xTemp ,1,0 ) // 'Alguns produtos estão com o preço no campo "B1_PRV1" igual a zero. Corrija para ser possível gerar Pedido de Remessa'
	EndIf	
EndIf

// valida o preenchimento do PV adicional para  
If lOk
	lOk := At820PvVld( oMdlGeral, oMdlPvAdic )
	
	If TFI->TFI_SRVEXT <> "1" .And. At820VerRev(oMdlGeral)
		Help('',1,'AT820REV',,STR0075,3)//#"O Contrato Esta em Revisão e/ou Aguardando Aprovação, favor regularizar o Contrato antes de Fazer a Separação"
		lOk := .F.
	EndIf
	
EndIf

oMdlItens:GoLine( 1 )
FwRestRows( aRows, oMdlGeral )
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} At820Grv2
	Rotina para gerar as movimentação conforme as marcações realizadas 
	pelo usuário
@since  	16/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function At820Grv2( oModel )

Local lRet     := .T.
Local aSave    := GetArea()
Local aSaveTEW := TEW->(GetArea())
Local aSaveTFI := TEW->(GetArea())

If !ISBlind()
	MsgRun( STR0037, STR0038, {|| lRet := At820Grv( oModel ) } ) // 'Executando separação dos equipamentos e pedidos de remessa' #### 'Aguarde...'
Else
	lRet := At820Grv( oModel )
EndIf
RestArea(aSaveTFI)
RestArea(aSaveTEW)
RestArea(aSave)
Return lRet 


//-------------------------------------------------------------------
/*/{Protheus.doc} At820Grv
	Rotina para gerar as movimentação conforme as marcações realizadas 
	pelo usuário
@since  	16/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Static Function At820Grv( oModel )

Local lRet					:= .T.
Local lAgrupPed			:= GetMv( 'MV_GSCLREM', , .F. )
Local nX					:= 0
Local nY					:= 0
Local lAtualizou			:= .F.
Local oMdlTFI				:= oModel:GetModel('TFI_ITENS')
Local oMdlAA3				:= oModel:GetModel('AA3_BASES')
Local oMdlGRN				:= oModel:GetModel('AA3_GRANEL')
Local oMdlTWR 				:= oModel:GetModel('TWR_PEDIDOS')
Local cUseCli				:= ''
Local cUseLoj				:= ''
Local aGrvPedido			:= {}
Local nPosPed				:= 0
Local nPosItPed				:= 0
Local aExecCabec			:= {}
Local aExecItens			:= {}
Local xAux					:= {}
Local cTmp					:= ''
Local cPedido				:= ''
Local cProdSepAnt			:= ''
Local oMdlReserv			:= Nil
Local aReservEfet			:= {}
Local lReserEfet			:= .F.
Local lGeraPedido			:= .T.
Local cVazio				:= ''
Local cTmpRecMarcados	:= cRecMarcados
Local lIntTecMnt			:= ExistFunc('At040ImpST9') .And. ExistFunc('At800OsxTec') .And. (TEW->( ColumnPos('TEW_TPOS')) > 0 ) .And. (AA3->(ColumnPos('AA3_CODBEM')) > 0)
Local cOcorPad 	:= SuperGetMv('MV_GSLOCOC', , '')
local aCabOs   	:= {}
lOCAL aAuxItens	:= {}
Local aItensOs 	:= {}
Local nOper		:= 3
Local cAtprPos  := SuperGetMv("MV_ATPRPOS",,"2")
Local cCodQueb	:= ""
Local cItemOs	:= ""
Local cCodTFJ	:= ""
Local aGrpCom	:= {}
Local aDadosOs	:= {}
Local aDdItnOs  := {}
Local nZ		:= 0
Local nK		:= 0
Local cTipoFrete := ""
Local cFilTFI				:= xFilial('TFI')
Local cFilTEW				:= xFilial('TEW')
Local cFilAA3				:= xFilial('AA3')
Local cFilSB1				:= xFilial('SB1')
Local cTxt		:= ""
Local cPrdPedTEW := ""
Local lTecAtf	:= SuperGetMv('MV_TECATF', .F.,'N') == 'S'
Local oTecProvider	:= Nil 
Local aGerMov		:= {}
Local aAreaSB1 	  	:= {}
Local aAreaAA3 	  	:= {}
Local aAreaTFI 	  	:= {}
Local aAreaTEW	  	:= {}
Local nQtdKit		:= 0
Local lKit 			:= .F.
Local cCodMovRes  	:= ""
Local cMsgErro 		:= ""
Local cFilBkp 		:= cFilAnt
Local cCliOSMont 	:= ""
Local cLojOSMont 	:= ""
Local cFilTEZ 		:= ""
Local nTotLinNaoId 	:= 0
Local xTotSep 		:= 0
Local nQtLimite 	:= 0
Local nQuantTemp 	:= 0
Local nQuantDistr 	:= 0
Local cTempProd 	:= ""
Local nQtKitTemp 	:= 0
Local nSomaDistr 	:= 0

Private lMsErroAuto		:= .F.
Private lMsHelpAuto		:= .T.
Private lAutoErrNoFile	:= .F.

DbSelectArea('SB1')
SB1->( DbSetOrder( 1 ) ) // B1_FILIAL+B1_COD
DbSelectArea("TEW")
TEW->( DbSetOrder( 7 ) ) // TEW_FILIAL+TEW_CODEQU+TEW_PRODUT+TEW_BAATD
DbSelectArea("AA3")
AA3->( DbSetOrder( 6 ) ) // AA3_FILIAL+AA3_NUMSER
DbSelectArea('TFI')
TFI->( DbSetOrder( 1 ) ) //TFI_FILIAL+TFI_COD
DbSelectArea('TEZ')
TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
DbSelectArea('ABS')
ABS->( DbSetOrder( 1 ) ) //ABS_FILIAL+ABS_LOCAL

Begin Transaction
If Len( aItensOk ) > 0
	
	For nX := 1 To Len( aItensOk )
		
		oMdlTFI:GoLine( aItensOk[nX] )
		cFilTFI := oMdlTFI:GetValue('TFI_FILIAL' )
		lGeraPedido := Empty(oMdlTFI:GetValue('TFI_CODTGQ'))
		
		If TFI->( DbSeek( cFilTFI+oMdlTFI:GetValue('TFI_COD' ) ) ) .And. ;  // Posiciona no item da TFI sendo separado
			TEW->( DbSeek( cFilTEW+oMdlTFI:GetValue('TFI_COD' ) ) ) .And. ;  // Posiciona na primeira movimentação a ser realizada do item da TFI
			( !lGeraPedido .Or. At820CliLoj( @cUseCli, @cUseLoj, oMdlTFI:GetValue('TFI_COD' ), .T. ) )  // Captura o conteúdo de cliente/loja e posiciona TFL e TFJ
			
			nPosPed := 0
			
			lReserEfet := !Empty( oMdlTFI:GetValue('TFI_RESERV') )
			If lReserEfet
				// adiciona o código da reserva e a linha da tfi que corresponde
				aAdd( aReservEfet, { oMdlTFI:GetValue('TFI_RESERV'), oMdlTFI:GetLine(), {} } )
			EndIF
			
			If lAgrupPed .And. Len( aGrvPedido ) > 0
				nPosPed := aScan( aGrvPedido, {|x| x[PED_POS_CAB,PED_CAB_CLIENTE]==cUseCli .And. x[PED_POS_CAB,PED_CAB_LOJA]==cUseLoj } )
			EndIf
			
			If lGeraPedido .And. nPosPed == 0
				
				aAdd( aGrvPedido, { Array( PED_CAB_MAX_CAMPOS )/*Cabec. Pedido*/, ;
										{ }/*Itens Pedido*/ ;
								  } )
				nPosPed := Len( aGrvPedido )
				
				ABS->( DbSeek( xFilial("ABS")+TFI->TFI_LOCAL ) )
				
				//----------------------------------------------
				//------ Preenche os dados do cabeçalho do pedido
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_ORCAMENTO ] := TFJ->TFJ_CODIGO
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CLIENTE ]   := cUseCli
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_LOJA ]      := cUseLoj
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CONDPG ]    := TFJ->TFJ_CONDPG
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_TIPOFRETE ] := TFJ->TFJ_TPFRET
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CONTR  ] 	 := TFJ->TFJ_CONTRT 
					aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_REVCTR ] 	 := TFJ->TFJ_CONREV
					
				//----------------------------------------------
				// adiciona o cliente e loja de entrega para o pedido de venda, conforme o cadastro do local de atendimento
					If !Empty(ABS->ABS_CLENTR) .And. !Empty( ABS->ABS_LJENTR )
						aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CLIENTREGA ] := ABS->ABS_CLENTR
						aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_LJENTREGA ] := ABS->ABS_LJENTR
					EndIf
				//----------------------------------------------

			EndIf
			
			// Atualizar campo de separação da TFI
			If oMdlTFI:GetValue('TFI_SEPSLD') == 0
				RecLock( 'TFI', .F. )
				TFI->TFI_SEPARA := '1' // Separado = '1 - Sim'
				TFI->TFI_SEPSLD :=  0
				TFI->( MsUnlock() )
				// remove o Recno dos itens marcados
				cTmpRecMarcados := StrTran( cTmpRecMarcados, cValToChar(TFI->(Recno()))+'#','')
			Else
				RecLock('TFI', .F.)
				TFI->TFI_SEPSLD :=  oMdlTFI:GetValue('TFI_SEPSLD')
				TFI->(MsUnlock())
			EndIf
			
			// Alterar Base de atendimento
			//  - Status
			//  - Cliente/Loja
			//  - Dt Início/Final
			//  - Local
			For nY := 1 To oMdlAA3:Length()
				
				oMdlAA3:GoLine( nY )
				
				If oMdlAA3:GetValue('AA3_FLAG')
				
					cFilAA3 := oMdlAA3:GetValue('AA3_FILIAL')
					cFilAA4 := cFilAA3
					cFilSB1 := xFilial("SB1",oMdlAA3:GetValue('AA3_FILORI'))

					If oMdlAA3:GetDataId(nY) > 0 .And. ;
						SB1->( DbSeek( cFilSB1+oMdlAA3:GetValue('AA3_CODPRO') ) )
						
						// posiciona no registro pelo recno do grid
						AA3->( DbGoTo(oMdlAA3:GetDataId(nY)) )
						
						// volta para o primeiro movimento inicial para garantir 
						// a separação dos kits conforme o agrupamento TEW_KITSEQ
						If cProdSepAnt <> oMdlAA3:GetValue('AA3_CODPRO')
							TEW->( DbSeek( cFilTEW+oMdlTFI:GetValue('TFI_COD') ) )
						EndIf

						lAtualizou := .F.
						// atualiza só o status do equipamento, as demais informações serão inseridas quando acontecer a alocação
						aAdd( xAux, { 'AA3_STATUS', AA3_SEPARADO } ) // "'07' Equipamento Separado"
						lRet := At800Status( @cTmp, xAux, oMdlAA3:GetValue('AA3_FILORI')+oMdlAA3:GetValue('AA3_NUMSER'), .T., oMdlAA3:GetValue('AA3_CODPRO') )

						// executa a atualização de código do cliente no cadastro de Bens do MNT
						If lRet .And. lIntTecMnt .And. !Empty( oMdlAA3:GetValue("AA3_CODBEM") )
							At800MntCli()
							FwModelActive(oModel)
						EndIf
						aSize( xAux, 0)
						xAux := {}

						// Atualizar a movimentação do equipamento com: 
						//  - Num. de Série
						//  - Dt Separção
						//  Utiliza a ordem com código do item da tfi, código do produto da base e o número de série
						cPrdPedTEW := At820GetPrd( oModel ) // verifica o código do produto conforme o cadastro de equivalentes
						TEW->( DbSetOrder( 7 ) ) // TEW_FILIAL+TEW_CODEQU+TEW_PRODUT+TEW_BAATD
						If TEW->( DbSeek( cFilTEW + oMdlTFI:GetValue('TFI_COD') + cPrdPedTEW + Space(TamSx3("TEW_BAATD")[1]) ) )
							
							xAux := {}
							aAdd( xAux, { 'TEW_FILBAT', oMdlAA3:GetValue('AA3_FILORI') } )
							aAdd( xAux, { 'TEW_BAATD', oMdlAA3:GetValue('AA3_NUMSER') } )
							aAdd( xAux, { 'TEW_DTSEPA', dDataBase } )
							aAdd( xAux, { 'TEW_CODCLI', cUseCli } )
							aAdd( xAux, { 'TEW_LOJCLI', cUseLoj } )
							aAdd( xAux, { 'TEW_QTDVEN', 1 } )
							
							If ( lRet := At800AtuMov( @cTmp, xAux ) )
								lAtualizou := .T.
								If oMdlAA3:GetValue('AA3_EXIGNF')=='1'
									//----------------------------------------------
									//------ Preenche os dados do cabeçalho do pedido									
									aAdd( aGrvPedido[nPosPed, PED_POS_ITEM], Array( PED_IT_MAX_CAMPOS ) )/*Array para os dados do Item*/
									nPosItPed := Len( aGrvPedido[nPosPed, PED_POS_ITEM] )											
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_ITEM ]       := StrZero( nPosItPed, TamSx3('C6_ITEM')[1] )
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PRODUTO ]    := cPrdPedTEW
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_QUANTIDADE ] := 1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_VENDA ]   := SB1->B1_PRV1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_UNIT ]    := SB1->B1_PRV1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_VALOR ]   := SB1->B1_PRV1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_TES ]        := oMdlTFI:GetValue('TFI_TES')
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_COD_EQUIP ]  := oMdlTFI:GetValue('TFI_COD')
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_NUM_SERIE ]  := oMdlAA3:GetValue('AA3_NUMSER')
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_RECNO_TEW ]  := TEW->( Recno() )
									
								EndIf
									//    Procura o pedido adicional para o cliente da prestação de serviço
									If ( oMdlTWR:SeekLine({{"TWR_DESTIN","2"},;
															{"TWR_FILPED",oMdlAA3:GetValue('AA3_FILORI')},;
															{"TWR_NUMSER",oMdlAA3:GetValue('AA3_NUMSER')},;
															{"TWR_CODTFI",oMdlTFI:GetValue('TFI_COD')};
															}) )
										
										oMdlTWR:LoadValue("TWR_CODMOV", TEW->TEW_CODMV)
										oMdlTWR:LoadValue("TWR_QTSEP", 1 )
									EndIf
									//----------------------------------------------
								
								//---------------------------------------------------------
								//  Adiciona o código da movimentação para vincular com a reserva
								If lReserEfet .And. !Empty(oMdlAA3:GetValue('AA3_ITRES')) .And. oMdlAA3:GetValue('AA3_FLAG')
									aAdd( aReservEfet[Len(aReservEfet),3], TEW->TEW_CODMV )
								EndIf

								//Verifica se existe integração TEC x ATF
								If lTecAtf .And. TecAtfSeek(TEW->TEW_BAATD, TEW->TEW_FILBAT)
									If ValType(oTecProvider) <> 'O'
										oTecProvider := TECProvider():New()
									EndIf						

									If !Empty(oMdlTFI:GetValue('TFI_RESERV')).And. !Empty(oMdlAA3:GetValue('AA3_ITRES'))
										aAreaTEW := GetArea()
										cCodMovRes := GetMovCod(oMdlTFI:GetValue('TFI_RESERV'),; //Codigo da reserva
										oMdlAA3:GetValue('AA3_NUMSER'))	 //Base de atendimento
								
										If !Empty(cCodMovRes)
											If ValType(oTecProvider) <> 'O'
												oTecProvider := TECProvider():New()
											EndIf						
					
											oTecProvider:UpdateTWU(cCodMovRes,1)
										EndIf
										RestArea(aAreaTEW)	
									EndIf
									
									oTecProvider:InsertTWI(TEW->TEW_CODMV,; 				//Codigo da Movimentação
														   TEW->TEW_BAATD,; 				//Base de atendimento
														   1,;								//Quantidade da separação
														   cUseCli,;						//Cliente
														   cUseLoj,;						//Loja
														   oMdlAA3:GetValue('AA3_EXIGNF'))	//Exig NF?
									
								EndIf
								
							Else
								lRet := .F.
								Help(,,'AT820MOV01',,STR0039 + CRLF +; // 'Atualização do movimento não foi possível'
													 STR0040 + CRLF + ;  // 'Detalhes: '
														cTmp, 1,0)
								oModel:SetErrorMessage( oModel:GetId() ,;
														"" ,;
														oModel:GetId() ,;
														"" ,;
														'AT820MOV01' ,;
														STR0039 + CRLF + STR0040 + CRLF + cTmp,;  // // 'Atualização do movimento não foi possível' ## 'Detalhes: '
														"",;
														"",;
														"" )
							EndIf
							
						Else
							// ------------------------------------------
							//  Não identificou item com o produto da base de atendimento disponível para 
							// associação 
							lRet := .F.
							Help(,,"AT820PRDMV",, STR0059, 1, 0)	//"Não foi identificado registro para associar o equipamento em separação. Contate o admnistrador do sistema"
							Help(,,"AT820PRDMV",, I18N(STR0060, {TFI->TFI_COD}), 1, 0)	//"Item de locação com o erro: '#codigo'"
							Exit
						EndIf
						
					Else
						lRet := .F.
						Exit
					EndIf
					If lRet
						//Separa o codigo do grupo para envio do workflow.
						If !Empty(TFJ->TFJ_GRPCOM)

							aAdd( aGrpCom,	{ TFJ->TFJ_CODIGO,;  //Codigo Orçamento de Serviço
											  AA3->AA3_CODPRO,;  //Codigo do Produto
											  TFJ->TFJ_GRPCOM,;  //Codigo do Grupo Comunicação
											  TFJ->TFJ_CONTRT,;  //Numero da Proposta
											  At774PlEtp("TEW",xFilial("TFI")+TEW->TEW_CODEQU)}) //Verifica se pula etapa.
						Endif
						//Inclui OS para montagem do equipamento.
						If TFI->TFI_OSMONT == "1" //Exige montagem do orçamento de serviço.
							
							If TFI->TFI_FILIAL == AA3->AA3_FILORI
								cCliOSMont := TFJ->TFJ_CODENT
								cLojOsMont := TFJ->TFJ_LOJA
							Else
								AtTWRCli( oMdlTWR, @cCliOSMont, @cLojOsMont )
								
							EndIf
																					
							If cAtprPos == "1" //Por Orçamento.
								
								If cCodQueb <> AA3->AA3_FILORI+TFJ->TFJ_CODIGO
									
									aAdd( aDadosOs,	{ cCliOSMont		,; //Cliente
													  cLojOsMont		,; //Loja
													  dDataBase			,; //Emissão
													  TFJ->TFJ_CONDPG 	,; //Cond. Pagamento
													  " "			 	,; //Tipo Orc.
													  TFJ->TFJ_CODIGO	,; //Cod. Orc.
													  " "			 	,; //Item Orc.
													  AA3->AA3_FILORI   ,; //Filial para criação da OS
													  TFJ->TFJ_FILIAL 	}) //Filial do orçamento de serviços
													  
									cCodQueb := AA3->AA3_FILORI+TFJ->TFJ_CODIGO
																				
								Endif

							Elseif cAtprPos == "2" //Nivel de Item.
								
								If cCodQueb <> AA3->AA3_FILORI+TFI->TFI_COD
									
									aAdd( aDadosOs, { cCliOSMont		,; //Cliente
													  cLojOSMont		,; //Loja
													  dDataBase			,; //Emissão
													  TFJ->TFJ_CONDPG	,; //Cond. Pagamento
													  "2"				,; //Tipo Orc.
													  TFJ->TFJ_CODIGO	,; //Cod. Orc.
													  TFI->TFI_COD		,; //Item Orc.
													  AA3->AA3_FILORI   ,; //Filial para criação da OS
													  TFJ->TFJ_FILIAL 	}) //Filial do orçamento de serviços
									
									cCodQueb := AA3->AA3_FILORI+TFI->TFI_COD
																	
								Endif
							Endif
							
							aAdd( aDdItnOs, {cCodQueb			,; 			  //Codigo que liga os itens.
											 "1"				,; 			  //Tipo = O.S.
											 AA3->AA3_CODPRO	,; 			  //Cod. Produto
											 AA3->AA3_NUMSER	,; 			  //Num. Série
											 cOcorPad 			,; 			  //Ocorrencia
											 1					,; 			  //Qtd. Sepração.
											 AA3->AA3_FILORI 	}) 			  //Fil. Original
						Endif
					Endif
				ElseIf oMdlTFI:GetValue('TFI_SEPSLD') == 0  .And. !Empty(oMdlTFI:GetValue('TFI_RESERV')) ;
															.And. !Empty(oMdlAA3:GetValue('AA3_ITRES'));
															.And. oMdlAA3:GetValue('AA3_STATUS') == "02"
				
					If lTecAtf .And. TecAtfSeek(oMdlAA3:GetValue('AA3_NUMSER'), oMdlAA3:GetValue('AA3_FILORI'))
						aAreaTEW := GetArea()
						cCodMovRes := GetMovCod(oMdlTFI:GetValue('TFI_RESERV'),; //Codigo da reserva
												oMdlAA3:GetValue('AA3_NUMSER'))	 //Base de atendimento
						If !Empty(cCodMovRes)
							If ValType(oTecProvider) <> 'O'
								oTecProvider := TECProvider():New()
							EndIf						
						
							oTecProvider:UpdateTWU(cCodMovRes,1)
						EndIf
						RestArea(aAreaTEW)							
					EndIf
				EndIf
				
				If !lRet
					Exit
				EndIf
			Next nY

			oMdlAA3:GoLine( 1 )
			
			//============================== NÃO ID ÚNICO
			//Quando for KIT para os equipamentos que não controlam ID único.
			cFilTEZ := xFilial("TEZ")
			TEZ->( DbSetOrder(1) ) // TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
			lKit := TEZ->( DbSeek( cFilTEZ+oMdlTFI:GetValue("TFI_PRODUT") ) )
			
			// inicia a repetição para a separação dos itens de granel
			nY := 1
			nTotLinNaoId := oMdlGRN:Length()
			
			xTotSep := If( lKit, {}, 0 )
			// Calcula o quanto foi de fato separado para o item nessa rotina
			nQtLimite := ( oMdlTFI:GetValue("TFI_QTDVEN") ;
							- oMdlTFI:GetValue("TFI_SEPSLD") ;
							- At820TEWSep( 	lKit, ;
											oMdlTFI:GetValue("TFI_COD"), ;
											( If( lKit, oMdlTFI:GetValue("TFI_PRODUT"), Nil ) ), ;
											oMdlTFI:GetValue("TFI_QTDVEN") ) ) 
			
			nQuantTemp := 0
			
			While nY <= nTotLinNaoId
							
				oMdlGRN:GoLine( nY )
				
				If oMdlGRN:GetValue('AA3_QTDSEP') > 0
					
					cFilAA3 := oMdlGRN:GetValue('AA3_FILIAL')
					cFilSB1 := xFilial("SB1",oMdlGRN:GetValue('AA3_FILORI'))
					
					If oMdlGRN:GetDataId(nY) > 0 .And. ;
						SB1->( DbSeek( cFilSB1+oMdlGRN:GetValue('AA3_CODPRO') ) )
						
						// posiciona no registro pelo recno do grid
						AA3->( DbGoTo(oMdlGRN:GetDataId(nY)) )

						lAtualizou := .F.
						// busca o produto conforme a filial do contrato
						cPrdPedTEW := At820GetPrd( oModel, oMdlTFI:GetValue("TFI_FILIAL"), oMdlGRN:GetId()) 
						// verifica se é kit
						// verifica se há quantidade remanescente na separação do kit do laço anterior
						// verifica se é o mesmo produto do laço anterior
						// tenta o posicionamento na tabela de kit para pegar a quantidade
						If lKit .And. ( nQtKitTemp <= 0 .Or. cTempProd <> cPrdPedTEW ) .And. ;
							TEZ->( DbSeek( cFilTEZ+oMdlTFI:GetValue("TFI_PRODUT")+cPrdPedTEW ) )
							
							nQtdKit := TEZ->TEZ_ITQTDE
							nQtKitTemp := nQtdKit
						Endif
						
						// Atualizar a movimentação do equipamento com: 
						//  - Num. de Série
						//  - Dt Separção
						//  Utiliza a ordem com código do item da tfi, código do produto da base e o número de série						
						If TEW->( DbSeek( cFilTEW + oMdlTFI:GetValue('TFI_COD') + cPrdPedTEW + Space(TamSx3("TEW_BAATD")[1]) ) )							

							xAux := {}
							
							aAdd( xAux, { 'TEW_FILBAT', oMdlGRN:GetValue('AA3_FILORI') } )
							aAdd( xAux, { 'TEW_BAATD' , oMdlGRN:GetValue('AA3_NUMSER') } )
							aAdd( xAux, { 'TEW_DTSEPA', dDataBase } )

							aAdd( xAux, { 'TEW_CODCLI', cUseCli } )
							aAdd( xAux, { 'TEW_LOJCLI', cUseLoj } )
							
							// -------------------------------------
							// mexer para receber o máximo permitido quando for kit e a quantidade maior que o limite do kit
							If lKit
								//  possui saldo do laço anterior não distribuído e este saldo será zerado 
								// por atender completa ou parcialmente ao movimento sendo atualizado
								If cTempProd == cPrdPedTEW .And. nQuantTemp > 0 .And. nQuantTemp <= nQtKitTemp
									nQuantDistr := nQuantTemp
									// calcula a quantidade restante para "fechar" o item
									If nQuantTemp < nQtKitTemp
										nQtKitTemp := ( nQtKitTemp - nQuantTemp )
									EndIf
									
									nQuantTemp := 0
									
								//  possui saldo do laço anterior mas o saldo não será zerado pois não atende completamente o kit
								ElseIf cTempProd == cPrdPedTEW .And. nQuantTemp > 0 .And. nQuantTemp > nQtKitTemp
									nQuantDistr := nQtKitTemp
									nQuantTemp := nQuantTemp - nQuantDistr
									nQtKitTemp := 0
								
								// não possui saldo do laço anterior e a quantidade separada é inferior ou igual a necessidade do kit
								ElseIf oMdlGRN:GetValue('AA3_QTDSEP') <= nQtKitTemp
									nQuantDistr := oMdlGRN:GetValue('AA3_QTDSEP')
									
									// calcula a quantidade restante para "fechar" o item
									If oMdlGRN:GetValue('AA3_QTDSEP') < nQtKitTemp
										nQtKitTemp := ( nQtKitTemp - oMdlGRN:GetValue('AA3_QTDSEP') )
									EndIf
									nQuantTemp := 0
								Else 
									// não possui saldo do laço anterior e a quantidade separa é maior que a necessidade do kit
									nQuantDistr := nQtKitTemp
									nQuantTemp := oMdlGRN:GetValue('AA3_QTDSEP') - nQtKitTemp
									nQtKitTemp := 0
								EndIf
							Else
								nQuantDistr := oMdlGRN:GetValue('AA3_QTDSEP')
							EndIf
							//  associa a quantidade distribuída com o movimento de locação
							aAdd( xAux, { 'TEW_QTDVEN', nQuantDistr } )
							
							If ( lRet := At800AtuMov( @cTmp, xAux ) )
								lAtualizou := .T.
								If oMdlGRN:GetValue('AA3_EXIGNF')=='1'
									//----------------------------------------------
									//------ Preenche os dados do cabeçalho do pedido									
									aAdd( aGrvPedido[nPosPed, PED_POS_ITEM], Array( PED_IT_MAX_CAMPOS ) )/*Array para os dados do Item*/
									nPosItPed := Len( aGrvPedido[nPosPed, PED_POS_ITEM] )											
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_ITEM ]       := StrZero( nPosItPed, TamSx3('C6_ITEM')[1] )
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PRODUTO ]    := cPrdPedTEW
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_QUANTIDADE ] := nQuantDistr
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_VENDA ]   := SB1->B1_PRV1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_UNIT ]    := SB1->B1_PRV1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_VALOR ]   := nQuantDistr * SB1->B1_PRV1
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_TES ]        := oMdlTFI:GetValue('TFI_TES')
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_COD_EQUIP ]  := oMdlTFI:GetValue('TFI_COD')
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_NUM_SERIE ]  := oMdlGRN:GetValue('AA3_NUMSER')
									aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_RECNO_TEW ]  := TEW->( Recno() )	

								EndIf
								//----------------------------------------------
								//    Procura o pedido adicional para o cliente da prestação de serviço
								If ( oMdlTWR:SeekLine({{"TWR_DESTIN","2"},;
														{"TWR_FILPED",oMdlGRN:GetValue('AA3_FILORI')},;
														{"TWR_NUMSER",oMdlGRN:GetValue('AA3_NUMSER')},;
														{"TWR_CODTFI",oMdlTFI:GetValue('TFI_COD')};
														}) )
									
									If Empty( oMdlTWR:GetValue("TWR_CODMOV") )
										oMdlTWR:LoadValue("TWR_CODMOV", TEW->TEW_CODMV)
										oMdlTWR:LoadValue("TWR_QTSEP", nQuantDistr )
									Else
										// copia os dados da linha posicionada em uma nova linha na TWR
										//  para associar a nova movimentação
										At820CpyTWR( oMdlTWR, TEW->TEW_CODMV, nQuantDistr )
									EndIf
								EndIf
								
								//---------------------------------------------------------
								//  Adiciona o código da movimentação para vincular com a reserva
								If lReserEfet .And. oMdlGRN:GetValue('AA3_QTDRES') > 0 .And. nQuantDistr > 0 
									aAdd( aReservEfet[Len(aReservEfet),3], TEW->TEW_CODMV )
									//Verifica se existe inegração do TEC x ATF.	
									If lTecAtf .And. TecAtfSeek(oMdlGRN:GetValue('AA3_NUMSER'), oMdlGRN:GetValue('AA3_FILORI'))
										aAreaTEW := GetArea()
										
										cCodMovRes := GetMovCod(oMdlTFI:GetValue('TFI_RESERV'),oMdlGRN:GetValue('AA3_NUMSER')) 
										If !Empty(cCodMovRes)
											If ValType(oTecProvider) <> 'O'
												oTecProvider := TECProvider():New()
											EndIf						
						
											If nQuantDistr < oMdlGRN:GetValue('AA3_QTDRES')
												oTecProvider:UpdateTWU(cCodMovRes,; //Codigo da reserva
														nQuantDistr) //Quantidade da da sepração

											Else
												oTecProvider:UpdateTWU(cCodMovRes,; //Codigo da reserva
													oMdlGRN:GetValue('AA3_QTDRES')) //Quantidade da reserva
											EndIf												
										EndIf
										RestArea(aAreaTEW)										
									EndIf																
								Endif				
								//Verifica se existe inegração do TEC x ATF.									
								If lTecAtf .And. TecAtfSeek(TEW->TEW_BAATD, TEW->TEW_FILBAT)
									If ValType(oTecProvider) <> 'O' 
										oTecProvider := TECProvider():New()
									EndIf
															
									oTecProvider:InsertTWI(TEW->TEW_CODMV,; 				//Codigo da movimentação
														   TEW->TEW_BAATD,;					//Base de atendimento
														   nQuantDistr,; //Quantidade de separação
														   cUseCli,;						//Cliente
														   cUseLoj,;						//Loja
														   oMdlGRN:GetValue('AA3_EXIGNF'))	//Exige NF?
								EndIf
							Else
								lRet := .F.
								Help(,,'AT820MOV01',,STR0039 + CRLF +; // 'Atualização do movimento não foi possível'
													 STR0040 + CRLF + ;  // 'Detalhes: '
														cTmp, 1,0)
							EndIf
						
						Else
						 	// ------------------------------------------
							//  Não identificou item com o produto da base de atendimento disponível para 
							// associação 
							lRet := .F.
							Help(,,"AT820PRDMV",, STR0059, 1, 0)	//"Não foi identificado registro para associar o equipamento em separação. Contate o admnistrador do sistema"
							Help(,,"AT820PRDMV",, I18N(STR0060, {TFI->TFI_COD}), 1, 0)	//"Item de locação com o erro: '#codigo'"
							Exit
						Endif
					Else
						lRet := .F.
						Exit
					EndIf
					
					If lRet
						//Separa o codigo do grupo para envio do workflow.
						If !Empty(TFJ->TFJ_GRPCOM)

							aAdd( aGrpCom,	{ TFJ->TFJ_CODIGO,;  //Codigo Orçamento de Serviço
											  AA3->AA3_CODPRO,;  //Codigo do Produto
											  TFJ->TFJ_GRPCOM,;  //Codigo do Grupo Comunicação
											  TFJ->TFJ_CONTRT,;  //Numero da Proposta
											  At774PlEtp("TEW",xFilial("TFI")+TEW->TEW_CODEQU)}) //Verifica se pula etapa.
						Endif
						//Inclui OS para montagem do equipamento.
						If TFI->TFI_OSMONT == "1" //Exige montagem do orçamento de serviço.
							
							If TFI->TFI_FILIAL == AA3->AA3_FILORI
								cCliOSMont := TFJ->TFJ_CODENT
								cLojOsMont := TFJ->TFJ_LOJA
							Else
								AtTWRCli( oMdlTWR, @cCliOSMont, @cLojOsMont )
								
							EndIf
							
							If cAtprPos == "1" //Por Orçamento.
								
								If cCodQueb <> AA3->AA3_FILORI+TFJ->TFJ_CODIGO
																
									aAdd( aDadosOs,	{ cCliOSMont		,; //Cliente
													  cLojOsMont		,; //Loja
													  dDataBase			,; //Emissão
													  TFJ->TFJ_CONDPG 	,; //Cond. Pagamento
													  " "			 	,; //Tipo Orc.
													  TFJ->TFJ_CODIGO	,; //Cod. Orc.
													  " "			 	,; //Item Orc.
													  AA3->AA3_FILORI   ,; //Filial para criação da OS
													  TFJ->TFJ_FILIAL 	}) //Filial do orçamento de serviços
													  
									cCodQueb := AA3->AA3_FILORI+TFJ->TFJ_CODIGO
																				
								Endif

							Elseif cAtprPos == "2" //Nivel de Item.
								
								If cCodQueb <> AA3->AA3_FILORI+TFI->TFI_COD
									
									aAdd( aDadosOs, { cCliOSMont		,; //Cliente
													  cLojOsMont		,; //Loja
													  dDataBase			,; //Emissão
													  TFJ->TFJ_CONDPG	,; //Cond. Pagamento
													  "2"				,; //Tipo Orc.
													  TFJ->TFJ_CODIGO	,; //Cod. Orc.
													  TFI->TFI_COD		,; //Item Orc.
													  AA3->AA3_FILORI   ,; //Filial para criação da OS
													  TFJ->TFJ_FILIAL 	}) //Filial do orçamento de serviços
									
									cCodQueb := AA3->AA3_FILORI+TFI->TFI_COD
																	
								Endif
							Endif
							
							aAdd( aDdItnOs, {cCodQueb			,; //Codigo que liga os itens.
											 "1"				,; //Tipo = O.S.
											 AA3->AA3_CODPRO	,; //Cod. Produto
											 AA3->AA3_NUMSER	,; //Num. Série
											 cOcorPad 			,; //Ocorrencia
											 nQuantDistr,;//Qtd. Sepração.
											 AA3->AA3_FILORI 	}) //Fil. Original
						Endif
					Endif
					
					//Quando não controla ID único, e existe saldo a separar, e não for KIT gera uma nova movimentação.
					If lRet .And. !lKit 
						// atuualiza a quantidade separada quando não é kit
						xTotSep += nQuantDistr

						// verifica se ainda há movimentos a serem inseridos 
						// considera se ainda há separação pendente ou se ainda não chegou ao final da separação
						
						If oMdlTFI:GetValue('TFI_SEPSLD') > 0 .Or. ;
							xTotSep < nQtLimite // insirar a verificação de ainda existir quantidade pendente para os outros equipamentos separados no item
							
							aAdd( aGerMov, { TEW->TEW_ORCSER	,; // Codigo do Orçamento.
											 TEW->TEW_CODEQU	,; // Codigo da Locação TFI.
											 TEW->TEW_PRODUT	,; // Codigo do Produto
											 0 					,; // Qtd Separada no Item
											 TEW->TEW_CODKIT 	,;
											 TEW->TEW_KITSEQ 	}) 
	
							lRet := At820InsTEW( aGerMov )
			
							aGerMov := {}
						EndIf
						
						// se a quantidade separada for menor ou igual 
						If xTotSep <= nQtLimite
							// faz a troca de linha no grid dos equipamento controlados por quantidade
							nY++
						EndIf
						
					ElseIf lRet .And. lKit
						//  identifica o produto do kit no array para controle da quantidade distribuída
						If (nK := aScan( xTotSep, { |x| x[1] == TEW->TEW_KITSEQ .And. ;
																x[2] == cPrdPedTEW } ) ) == 0
							
							aAdd( xTotSep, { TEW->TEW_KITSEQ, cPrdPedTEW, nQuantDistr, nQtdKit } )
							nK := Len(xTotSep)
						Else
							xTotSep[nK,3] += nQuantDistr
						EndIf
						
						// verifica se ainda há itens a serem distribuídos para a mesma sequência do kit e 
						// se houver cria os registros para receber as informações da movimentação
						If xTotSep[nK,3] < nQtdKit 
							aAdd( aGerMov, { TEW->TEW_ORCSER	,; // Codigo do Orçamento.
											 TEW->TEW_CODEQU	,; // Codigo da Locação TFI.
											 TEW->TEW_PRODUT	,; // Codigo do Produto
											 0 					,; // Qtd Separada no Item
											 TEW->TEW_CODKIT 	,;
											 TEW->TEW_KITSEQ 	}) 
	
							lRet := At820InsTEW( aGerMov )
			
							aGerMov := {}
						EndIf
						
						//  Verifica se a quantidade separada do equipamento já foi completamente distribuída
						// quando foi, é realizada a troca de linha no grid dos equipamentos
						nSomaDistr += nQuantDistr
						If nSomaDistr == oMdlGRN:GetValue('AA3_QTDSEP')
							nY++
							nSomaDistr := 0
						EndIf
						
					EndIf
					
				Else
					// troca a linha no grid quando não há quantidade separada no equipamento 
					nY++
				EndIf

				If !lRet
					Exit
				EndIf
				cTempProd := cPrdPedTEW
			End

			oMdlGRN:GoLine( 1 )
		Else
			lRet := .F.
			oModel:SetErrorMessage( oModel:GetId() ,;
									"" ,;
									oModel:GetId() ,;
									"" ,;
									'AT820GRV' ,;
									i18n(STR0142,{ oMdlTFI:GetValue('TFI_COD' ) }),;  // "Erro inesperado ao tentar separar o item com código (TFI_COD): [#1]."
									STR0143 + CRLF + ;  // "As causas podem ser:"
											STR0144 + CRLF +; // "- Item não encontrado na tabela TFI."
											STR0145 + CRLF +;  // "- Nenhum registro para movimentação na tabela TEW."
											STR0146,;  // "- Cliente para a remessa não identificado."
									"",;
									"" )
			Exit
		EndIf
		
		If !lRet
			Exit
		EndIf
	Next nX
	
	oMdlTFI:GoLine( 1 )

	If lRet .And. lGeraPedido 
		For nPosPed := 1 To Len( aGrvPedido )
			
			aSize( aExecCabec, 0 )
			aExecCabec := {}
			
			aSize( aExecItens, 0 )
			aExecItens := {}
			
			//------------------------------------------------------
			// Gerar Pedido para remessa dos equipamentos
			//------------------------------------------------------
			// Monta o cabeçalho do pedido
			aAdd( aExecCabec, {'C5_TIPO',    'N', Nil } )
			aAdd( aExecCabec, {'C5_CLIENTE', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CLIENTE ], Nil})
			aAdd( aExecCabec, {'C5_LOJACLI', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_LOJA ],Nil})
			aAdd( aExecCabec, {'C5_CONDPAG', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CONDPG ],Nil})
			If !Empty( aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_TIPOFRETE ] )
				cTipoFrete := Iif(aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_TIPOFRETE]=="1","C","F")
				aAdd( aExecCabec, {'C5_TPFRETE', cTipoFrete ,Nil})
			Endif
			If !Empty( aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CLIENTREGA ] ) .And. ;
				!Empty( aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_LJENTREGA ] );
				
				aAdd( aExecCabec, {'C5_CLIENT', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CLIENTREGA ] ,Nil})
				aAdd( aExecCabec, {'C5_LOJAENT', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_LJENTREGA ] ,Nil})
			Endif
			
			If !Empty( aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CONTR ] ) 
				aAdd( aExecCabec, {'C5_REMCTR', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_CONTR ] ,Nil})
			EndIf
			If !Empty( aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_REVCTR ] ) 
				aAdd( aExecCabec, {'C5_REMREV', aGrvPedido[nPosPed, PED_POS_CAB, PED_CAB_REVCTR ] ,Nil})
			EndIf
			
			For nPosItPed := 1 To Len( aGrvPedido[nPosPed, PED_POS_ITEM ] )
			
				//------------------------------------------------------
				// Monta os itens para dispara os pedidos
				aSize( xAux, 0 )
				xAux := {}
				
				aAdd( xAux, {'C6_ITEM',    aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_ITEM ], Nil } )
				aAdd( xAux, {'C6_PRODUTO', aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PRODUTO ],Nil } )
				aAdd( xAux, {'C6_QTDVEN',  aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_QUANTIDADE ],Nil } )
				aAdd( xAux, {'C6_PRCVEN',  aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_VENDA ],Nil } )
				aAdd( xAux, {'C6_PRUNIT',  aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_UNIT ],Nil } )
				aAdd( xAux, {'C6_VALOR',   aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_PR_VALOR ],Nil } )
				aAdd( xAux, {'C6_TES',     aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_TES ],Nil } )
				aAdd( xAux, {'C6_NUMSERI', aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_NUM_SERIE ],Nil } )
				
				aAdd( aExecItens, aClone( xAux ) )
			
			Next nPosItPed
			
			If Len( aExecItens ) > 0 .And. Len( aExecCabec ) > 0
				// dispara execauto para gravação do Pedido de Remessa dos itens
				lMsErroAuto := .F.
				MsExecAuto( { |x,y,z| MATA410( x, y, z ) }, aExecCabec, aExecItens, 3 )

				If lMsErroAuto
					
					lRet := .F.
					xAux := GetAutoGrLog()
					MostraErro()
				
				Else
					// Atualizar a movimentação do equipamento com: 
					//  - Pedido
					//  - Item do Pedido
					cPedido := SC5->C5_NUM
					
					For nPosItPed := 1 To Len( aGrvPedido[nPosPed, PED_POS_ITEM ] )
						
						If TEW->( DbSeek( cFilTEW + aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_COD_EQUIP ] ) )
							
							// --------------------------------------------------
							// Identifica o movimento na TFI que necessita ser atualizado
							TEW->( DbGoTo( aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_RECNO_TEW ] ) )
							
							// garante o item que deve sofrer atualização
							xAux := {}
							// --------------------------------
							// Adiciona os dados para atualização do movimento
							aAdd( xAux, { 'TEW_NUMPED', cPedido } )
							aAdd( xAux, { 'TEW_ITEMPV', aGrvPedido[ nPosPed, PED_POS_ITEM, nPosItPed, PED_IT_ITEM ] } )
						
							lRet := At800AtuMov( @cTmp, xAux )
							
							If !lRet
								Help(,,'AT820MOV02',,STR0039 + CRLF +; // 'Atualização do movimento não foi possível'
								                     STR0040 + CRLF + ; // 'Detalhes: '
								                     cTmp, 1,0)
							EndIf
							
						Else
							lRet := .F.
							Exit
						EndIf
					
					Next
			
				EndIf
			
			EndIf
			
		Next nPosPed
		oMdlTWR:GoLine(1)
		// Gera os pedidos de remessa adicionais entre as filiais
		If lRet .And. !Empty( oMdlTWR:GetValue("TWR_FILPED") )
			
			lRet := At820GerAdc( oMdlTWR )
		EndIf
	EndIf
	
	//---------------------------------------------
	//  Executa a efetivação das reservas associadas 
	// ao itens separados
	xAux := Len(aReservEfet)
	If lRet .And. xAux > 0
		
		oMdlReserv := FwLoadModel('TECA825C')
		
		DbSelectArea('TFI')
		DbSelectArea('TEW')
		
		cVazio := Space(TamSX3('TEW_SUBSTI')[1])
		
		For nX := 1 To xAux
			If Len(aReservEfet[nX,3]) > 0
				TFI->( DbSetOrder( 6 ) ) // TFI_FILIAL+TFI_RESERV		
				TEW->( DbSetOrder( 13 ) ) // TEW_FILIAL+TEW_RESERV+TEW_BAATD
				
				If TFI->( DbSeek( cFilTFI+aReservEfet[nX,1] ) ) .And. ;
					TEW->( DbSeek( cFilTEW+aReservEfet[nX,1] ) )
					
					oMdlReserv:SetOperation( MODEL_OPERATION_UPDATE )
					
					// adiciona os dados que serão utilizados para a gravação das informações
					At825CText( STR0056 )	//'Equipamento Separado'
					At825CTipo( DEF_RES_ENVIADA )
					
					lRet := oMdlReserv:Activate()
					
					If lRet
					
						oMdlTFI:GoLine(aReservEfet[nX,2])
							
						If oMdlTFI:GetValue('TFI_RESERV')==aReservEfet[nX,1]  // verifica se é o item da reserva
							
							nY := 1
							TEW->( DbSetOrder( 1 ) ) // TEW_FILIAL+TEW_CODMV
							
							// ---------------------------------------------------
							//   Pesquisa o código da movimentação com a base de atendimento
							// que havia sido utilizada na reserva... e associa a reserva
							// no campo para indicar a continuação do movimento/processo
							While lRet .And. nY <= Len(aReservEfet[nX,3])
								
								If lRet .And. TEW->( DbSeek( cFilTEW+aReservEfet[nX,3,nY] ) )
								
									oMdlReserv:GetModel('GRD_TEW'):SeekLine( { {'TEW_BAATD', TEW->TEW_BAATD}, {'TEW_SUBSTI', cVazio} } )
									lRet := oMdlReserv:GetModel('GRD_TEW'):SetValue('TEW_SUBSTI',TEW->TEW_CODMV)
								
								EndIf
								nY++
							EndDo
							
							lRet := lRet .And. oMdlReserv:VldData() .And. ;  // Valida os dados da rotina
								oMdlReserv:CommitData()   // Grava os dados
						EndIf
						
					EndIf
					
					If !lRet
						AtErroMvc( oMdlReserv )
						MostraErro()
						oMdlReserv:CancelData()
						Exit
					EndIf
					
					oMdlReserv:DeActivate()
					
				EndIf
			EndIf			
		Next nX
		
		oMdlReserv:Destroy()
	EndIf
	
	If lRet
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³SIGATEC WorkFlow # SE - Separação de Equipamentos	   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !Empty(aGrpCom)
			
			cCodTFJ := aGrpCom[1,1]

			For nX := 1 To Len(aGrpCom)

				If cCodTFJ == aGrpCom[nX,1]
					cTxt += "<b> "+STR0071+"</b> "+aGrpCom[nX,4] //"Nr. Contrato: " 
					cTxt += "<b> "+STR0069+"</b> "+aGrpCom[nX,2] //"Cod. Produto: " 
					cTxt += "<b> "+STR0070+"</b> "+AllTrim(Posicione("SB1",1,xFilial("SB1")+aGrpCom[nX,2],"B1_DESC"))+"<br>" //"Descrição: "
				Endif

				If cCodTFJ <> aGrpCom[nX,1]
					At774Mail("TFJ",aGrpCom[nX,3],"SE",cTxt,,,aGrpCom[nX,5])
					cCodTFJ := aGrpCom[nX,1]
					cTxt := "<b> "+STR0071+"</b> "+aGrpCom[nX,4] //"Nr. Contrato: " 
					cTxt += "<b> "+STR0069+"</b> "+aGrpCom[nX,2] //"Cod. Produto: "
					cTxt += "<b> "+STR0070+"</b> "+AllTrim(Posicione("SB1",1,xFilial("SB1")+aGrpCom[nX,2],"B1_DESC"))+"<br>" //"Descrição: "
				Endif

				If nX == Len(aGrpCom)
					At774Mail("TFJ",aGrpCom[nX,3],"SE",cTxt,,,aGrpCom[nX,5])
				Endif

			Next nX

		Endif
		//Gerando as OS, para equipamentos montagem.
		If Len(aDadosOS) > 0 .AND. Len(aDdItnOs) > 0
			If ExistBlock("AT820GOS") //Ponto de entrada para geração da OS.
				ExecBlock("AT820GOS",.F.,.F.,{oModel,aDadosOS,aDdItnOs})
			Else
				cCodQueb := ""
				For nZ := 1 To Len(aDadosOS)
		
					If !Empty(cCodQueb)
						// troca a filial ativa quando o equipamento é de uma outra filial
						If cFilAnt <> aDadosOS[nZ-1,8]
							cFilAnt := aDadosOS[nZ-1,8]
						EndIf
						
						TECA450( NIL, aCabOs, aItensOs, NIL, nOper )
						
						// devolve a filial ativa antes da troca pela filial do equipamento
						If cFilAnt <> cFilBkp
							cFilAnt := cFilBkp
						EndIf
						
						aCabOs := {}
						aItensOs := {}
					Endif
		
					If cAtprPos == "1" //Por Orçamento.
		
						aAdd( aCabOs, {"AB6_FILIAL", xFilial("AB6",aDadosOS[nZ,8]), Nil}) //Filial
						aAdd( aCabOs, {"AB6_CODCLI", aDadosOS[nZ,1], Nil}) //Cliente
						aAdd( aCabOs, {"AB6_LOJA"  , aDadosOS[nZ,2], Nil}) //Loja
						aAdd( aCabOs, {"AB6_EMISSA", aDadosOS[nZ,3], Nil}) //Emissão
						aAdd( aCabOs, {"AB6_CONPAG", aDadosOS[nZ,4], Nil}) //Cond. Pagamento
						aAdd( aCabOs, {"AB6_FIORCS", aDadosOS[nZ,9], Nil}) //Fil Orc Serviços
						aAdd( aCabOs, {"AB6_CDORCS", aDadosOS[nZ,6], Nil}) //Cod. Orc.
			
						cCodQueb := aDadosOS[nZ,8]+aDadosOS[nZ,6]
					
					Elseif cAtprPos == "2" //Nivel de Item.
		
						aAdd( aCabOs, {"AB6_FILIAL", xFilial("AB6",aDadosOS[nZ,8]), Nil}) //Filial
						aAdd( aCabOs, {"AB6_CODCLI", aDadosOS[nZ,1], Nil}) //Cliente
						aAdd( aCabOs, {"AB6_LOJA"  , aDadosOS[nZ,2], Nil}) //Loja
						aAdd( aCabOs, {"AB6_EMISSA", aDadosOS[nZ,3], Nil}) //Emissão
						aAdd( aCabOs, {"AB6_CONPAG", aDadosOS[nZ,4], Nil}) //Cond. Pagamento
						aAdd( aCabOs, {"AB6_TPORCS", aDadosOS[nZ,5], Nil}) //Tipo Orc.
						aAdd( aCabOs, {"AB6_FIORCS", aDadosOS[nZ,9], Nil}) //Fil Orc Serviços
						aAdd( aCabOs, {"AB6_CDORCS", aDadosOS[nZ,6], Nil}) //Cod. Orc.
						aAdd( aCabOs, {"AB6_ITORCS", aDadosOS[nZ,7], Nil}) //Item Orc.
		
						cCodQueb := aDadosOS[nZ,8]+aDadosOS[nZ,7]
			
					Endif
		
					cItemOs := StrZero(0,TAMSX3("AB7_ITEM")[1])
		
					For nK := 1 To Len(aDdItnOs)
						If cCodQueb == aDdItnOs[nK,1]
		
							cItemOs := Soma1(cItemOs)
							aAdd( aAuxItens, {"AB7_FILIAL" , xFilial("AB6",aDdItnOs[nK,7]), Nil}) //Filial
							aAdd( aAuxItens, {"AB7_ITEM"   , cItemOs, Nil } )
							aAdd( aAuxItens, {"AB7_TIPO"   , aDdItnOs[nK,2], Nil } ) // Tipo = O.S.
							aAdd( aAuxItens, {"AB7_CODPRO" , aDdItnOs[nK,3], Nil } ) // Cod. Produto
							aAdd( aAuxItens, {"AB7_NUMSER" , aDdItnOs[nK,4], Nil } ) // Num. Serie
							aAdd( aAuxItens, {"AB7_CODPRB" , aDdItnOs[nK,5], Nil } ) // Cod. Ocorrencia
							aAdd( aAuxItens, {"AB7_QTDSEP" , aDdItnOs[nK,6], Nil } ) // Quantidade
							
							aAdd( aItensOs, aClone( aAuxItens ) )
							aSize( aAuxItens, 0 )
							aAuxItens := {}
						Endif
										
						If Len(aDadosOS) == nZ .And. Len(aDdItnOs) == nK
							
							// troca a filial ativa quando o equipamento é de uma outra filial
							If cFilAnt <> aDdItnOs[nK,7]
								cFilAnt := aDdItnOs[nK,7]
							EndIf
							
							TECA450( NIL, aCabOs, aItensOs, NIL, nOper )
							
							// devolve a filial ativa antes da troca pela filial do equipamento
							If cFilAnt <> cFilBkp
								cFilAnt := cFilBkp
							EndIf
							
							aCabOs := {}
							aItensOs := {}
						Endif
						
						If lMsErroAuto
							lRet := .F.
							ConOut(STR0061) //"Erro na inclusao da Ordem de Serviço!"
							MostraErro()
						EndIf
					Next nK
				Next nZ
			Endif
		Endif
	Endif
	
	If lRet
		cRecMarcados := cTmpRecMarcados
		aSize( aItensOk, 0)
		
		//-------------------------------------------------
		// Refresh do Browse para reexecução do filtro
		If ValType(oBrw) == "O"
			oBrw:GoTo( 1, .T.)
			oBrw:Refresh(.T.)
		EndIf
		lProcess := .T.

		If ExistBlock("AT820CMT")
			ExecBlock( 'AT820CMT', .F., .F., { oModel } )
		EndIf

	Else
		DisarmTransaction()
	EndIf

Else
	lRet := .F.
EndIf
End Transaction
Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} At820CliLoj
	Posiciona e caputra as informações de cliente e loja do orçamento de serviços
@since  	16/09/2013
@version  	P11.90
/*/
//-------------------------------------------------------------------
Function At820CliLoj( cCodCli, cLojCli, cTFICod, lLoc, cFilRef )

Local lRet := .F.
Default lLoc := .F.
Default cFilRef := cFilAnt

DbSelectArea('TFI')
TFI->( DbSetOrder( 1 ) ) //TFI_FILIAL+TFI_COD
DbSelectArea('TFL')
TFL->( DbSetOrder( 1 ) ) //TFL_FILIAL+TFL_CODIGO
DbSelectArea('TFJ')
TFJ->( DbSetOrder( 1 ) ) //TFJ_FILIAL+TFJ_CODIGO

If	TFI->( DbSeek( xFilial('TFI',cFilRef)+cTFICod ) ) .And. ;
	TFL->( Dbseek( xFilial('TFL',cFilRef)+TFI->TFI_CODPAI ) ) .And. ;
	TFJ->( DbSeek( xFilial('TFJ',cFilRef)+TFL->TFL_CODPAI ) )
	
	If TFJ->TFJ_CLIPED == "2" .AND. lLoc
		DbSelectArea("ABS")
		ABS->(DbSetOrder(1))
		If ABS->(DbSeek(xFilial("ABS",cFilRef)+TFL->TFL_LOCAL))
			cCodCli := ABS->ABS_CODIGO
			cLojCli := ABS->ABS_LOJA
			lRet := .T.
		Endif
	Else
		cCodCli := TFJ->TFJ_CODENT
		cLojCli := TFJ->TFJ_LOJA
		lRet := .T.
	Endif
EndIf
Return lRet
//------------------------------------------------------------------------------
/*/{Protheus.doc} At820Mont
  Inicializador padrão para identificar as bases de atendimento, com a geração de OS igual a "sim".
@sample 	At820Mont() 
@since		13/05/2016       
@version	P12
/*/
//------------------------------------------------------------------------------
Function At820Mont(cCodPro)
Local cRet := ""
Local cNewAlias	 := GetNextAlias()
Default cCodPro := ""

If !Empty(cCodPro)

	BeginSql Alias cNewAlias
	
		SELECT AA3_OSMONT
		FROM %Table:AA3% AA3
		WHERE AA3_FILIAL = %xFilial:AA3%
			AND AA3_CODPRO = %Exp:cCodPro%
			AND AA3_OSMONT = '1'
			AND AA3.%NotDel%
			
	EndSql
	
	If (cNewAlias)->(!Eof())
		cRet := "1"
	Else
		cRet := "2"
	Endif
		
	(cNewAlias)->(dbCloseArea())
Endif

Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc} At820VerRev
	Rotina utilizada para verificar se contrato atual tem revisão aguardando efetivação e/ou Aprovação.

@author 	joni.carmo	
@since  	23/08/16
@version  	P12
/*/
//-------------------------------------------------------------------
Static Function At820VerRev(oModel)

Local aArea 	:= GetArea()
Local aRows		:= FwSaveRows( oModel )
Local lRet := .F.
Local oMdlItens	:= oModel:GetModel('TFI_ITENS')
Local cContr	:= oMdlItens:GetValue('TFI_CONTRT')
Local cAlias    := GetNextAlias()
Local nItens    := 0

For nItens := 1 To oMdlItens:Length()
	oMdlItens:GoLine( nItens )
	cContr	:= oMdlItens:GetValue('TFI_CONTRT')

	BeginSql Alias cAlias
		SELECT TFJ_CODIGO
		  FROM %Table:TFJ% TFJ
		 WHERE TFJ.TFJ_CONTRT = %Exp:cContr%
		   AND	TFJ.TFJ_STATUS IN ('2','4')
		   AND	TFJ.TFJ_FILIAL = %xFilial:TFJ%
		   AND	TFJ.%NotDel%
	EndSql

	While !(cAlias)->(Eof())
		lRet := .T.
		If lRet
			exit
		EndIf
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

	if lRet
		exit
	EndIf
next nItens

FwRestRows( aRows, oModel )
RestArea(aArea)
Return lRet

/*/{Protheus.doc} At820AvPedAd
  Validação de pré linha do grid para os pedidos adicionais
@since		28/07/2016       
@version	P12
@author 	Inovação - Gestão de Serviços
/*/
Function At820AvPedAd( oMdlG,nLine,cAcao,cCampo,e )
Local lRet := .T.

If (cAcao == "CANSETVALUE" .Or. cAcao == "SETVALUE" )

	If cCampo <> "TWR_FILPED" .And. ;
		Empty( oMdlG:GetValue("TWR_FILPED") )
	
		lRet := .F.
		Help("",1,'AT820PedAd1',,STR0117,;	//"Edição não permitida para preencher as informações do pedido adicional."
						4,1,,,,,,{STR0118})	//"Altere o conteúdo nas linhas que tenham a filial do pedido adicional preenchida."
				
	ElseIf oMdlG:GetValue("TWR_EXIGNF") <> "1" .And. ;  // não exige nf para movimentar
			!(cCampo $ "TWR_CLIENT//TWR_LOJACL//TWR_FILPED//TWR_DESTIN//TWR_PRODUT//"+; // campos que podem ser alterados
						"TWR_NUMSER//TWR_CODTFI//TWR_ATUFIL//TWR_CODMOV//TWR_EXIGNF//TWR_CNPJ//TWR_NOME" )  // diretamente pelo usuário só cliente e loja
			
		lRet := .F.
		//  não preenche erro do mvc pois se estiver com informação aErrorMessage na confirmação 
		// o processo será interrompido mesmo sem ter erro para o cliente
		//Help("",1,'AT820PedAd2',,STR0119,;	//"Campo não pode ser editado para equipamentos que não exigem NF para movimentação."
		//				4,1,,,,,,{STR0120})	//"Preencha somente os campos de cliente e loja [TWR_CLIENT e TWR_LOJACL]."
	EndIf
EndIf

Return lRet 

//------------------------------------------------------------------------------
/*/{Protheus.doc} A820FltVig
Filtro para contratos vigentes na separação
@sample 	A820FltVig() 
@since		02/08/2016       
@version	P12
/*/
//------------------------------------------------------------------------------
Function A820FltVig()
Local lRet := .F.

lRet := Posicione("CN9",1,xFilial("CN9")+TFI->TFI_CONTRT+TFI->TFI_CONREV,"CN9_SITUAC") == '05' 

Return lRet
/*/{Protheus.doc} At820PvAdc
  Gatilho na marcação/desmarcação do equipamento para realizar a inclusão de uma linha 
	no grid dos pedidos adicionais para a remessa do equipamento
	Este pedido só será gerado quando identifada filial original do equipamento diferente da filial do contrato 
@since		02/08/2016       
@version	P12
@author 	Inovação - Gestão de Serviços
/*/
Function At820PvAdc( cIdMdlBase, cIdMdlPV, aDadosTFI, lFlag, cCodTEW )

Local oMdlFull := FwModelActive()
Local oModNTew := Nil 
Local oMdlEquip := Nil
Local oMdlItLe := Nil
Local oMdlTWR := Nil
Local lOk := .T.
Local nLinha := 1
Local cCodCli := ""
Local cLojCli := ""
Local nCpo := 0
Local aCpos := 0
Local cCnpjCli := ""
Local aInfCli := {}

Default cIdMdlBase := "AA3_BASES"
Default cIdMdlPV := "TWR_PEDIDOS"
Default aDadosTFI := {}
Default cCodTEW := ""

oMdlEquip := oMdlFull:GetModel(cIdMdlBase)
oMdlTWR := oMdlFull:GetModel(cIdMdlPV)

If Len(aDadosTFI) == 0
	oMdlItLe := oMdlFull:GetModel("TFI_ITENS")
	aAdd(aDadosTFI, oMdlItLe:GetValue("TFI_FILIAL"))
	aAdd(aDadosTFI, oMdlItLe:GetValue("TFI_COD"))
EndIf

If Valtype(lFlag) <> "L"
	lFlag := oMdlEquip:GetValue("AA3_FLAG")
EndIf

If oMdlEquip:GetValue("AA3_FILORI") <> aDadosTFI[1]
	oMdlTWR:SetNoInsertLine(.F.)
	oMdlTWR:SetNoDeleteLine(.F.)
	
	If lFlag
		//-----------------------------------------------
		// captura cliente e loja para a remessa do equipamento (originais do orçamento de serviços/contrato)
		lOk := At820CliLoj( @cCodCli, @cLojCli, aDadosTFI[2] )
		cCnpjCli := At820GetCNPJ( "ENT", xFilial("SA1")+cCodCli+cLojCli )  // busca CNPJ do cliente

		oMdlTWR:GoLine(1)
		
		If oMdlTWR:Length() > 1 .Or. ! Empty( oMdlTWR:GetValue("TWR_FILPED") )
			nLinha := oMdlTWR:Length()
			lOk := ( oMdlTWR:AddLine() == nLinha+1 )
		EndIf

		//-----------------------------------------------
		// 	CRIA A LINHA PARA O PEDIDO DE REMESSA : 
		// FILIAL ORIGEM EQTO >> CLIENTE DO CONTRATO
		// captura cliente e loja para a remessa do equipamento (originais do orçamento de serviços/contrato)
		// primeiro campo é a filial de origem do pedido pois ele indica se pode editar os demais campos ou não
		lOk := lOk .And. oMdlTWR:SetValue("TWR_FILPED", oMdlEquip:GetValue("AA3_FILORI") )
		lOk := lOk .And. oMdlTWR:SetValue("TWR_DESTIN", "2" ) // determina que é o pedido da [ Filial Equip > Cliente ]
		lOk := lOk .And. oMdlTWR:SetValue("TWR_PRODUT", oMdlEquip:GetValue("AA3_CODPRO") )
		lOk := lOk .And. oMdlTWR:SetValue("TWR_NUMSER", oMdlEquip:GetValue("AA3_NUMSER") )
		lOk := lOk .And. oMdlTWR:SetValue("TWR_CODTFI", aDadosTFI[2] )
		lOk := lOk .And. oMdlTWR:SetValue("TWR_ATUFIL", "1" ) // atualiza a filial de locação na AA3

		// determina se o pedido precisa ser gerado
		lOk := lOk .And. oMdlTWR:SetValue( "TWR_EXIGNF", oMdlEquip:GetValue("AA3_EXIGNF") )

		If !Empty(cCodTEW)
			lOk := lOk .And. oMdlTWR:SetValue("TWR_CODMOV", cCodTEW )
		EndIf
		
		If !IsInCallStack("TECA820")
			oModNTew := oMdlFull:GetModel('NEW_TEW')
			If Empty(oModNTew:GetValue('TEW_FILIAL'))
				lOk := lOk .And. oModNTew:SetValue('TEW_FILIAL',oMdlEquip:GetValue("AA3_FILORI"))
			EndIf
		EndIf

		// só tenta identificar os códigos dos clientes a partir do CNPJ quando identificar o conteúdo preenchido
		If !Empty(cCnpjCli)
			// procura por algum cliente que tenha o CNPJ do cliente para remessa do equipamento
			aInfCli := At820CliByCnpj( xFilial("SA1",oMdlTWR:GetValue("TWR_FILPED"))+cCnpjCli )
			
			If Len(aInfCli) >= 2
				// campos de cliente e loja principais
				lOk := lOk .And. oMdlTWR:SetValue("TWR_CLIENT", aInfCli[1] )
				lOk := lOk .And. oMdlTWR:SetValue("TWR_LOJACL", aInfCli[2] )
				// campos de cliente e loja de entrega não serão preenchidos por padrão
			EndIf
		EndIf
		oMdlTWR:GoLine(1)
	Else
		// --------------------------------------------------
		//  Exclui a linha do pedido adicional entre a Filial do Equipamento e o Cliente
		oMdlTWR:SeekLine( { {"TWR_DESTIN", "2" },;
							{"TWR_FILPED", oMdlEquip:GetValue("AA3_FILORI")} ,;
							{"TWR_PRODUT", oMdlEquip:GetValue("AA3_CODPRO")} ,;
							{"TWR_NUMSER", oMdlEquip:GetValue("AA3_NUMSER")} ,;
							{"TWR_CODTFI", aDadosTFI[2] } } )
		
		nLinha := oMdlTWR:GetLine()
		
		If ( nLinha < oMdlTWR:Length() )
			oMdlTWR:LineShift( nLinha, oMdlTWR:Length() )
			nLinha := oMdlTWR:Length()
		End
		
		If nLinha == 1
			aCpos := oMdlTWR:GetStruct():GetFields()
			For nCpo := 1 To Len( aCpos )
				oMdlTWR:LoadValue(aCpos[nCpo,MODEL_FIELD_IDFIELD], If(aCpos[nCpo,MODEL_FIELD_TIPO]=="C","",0) )
			Next nCpo
		Else
			oMdlTWR:DeleteLine(.T.,.T.)
		EndIf
		//-----------------------------------------------
	EndIf
	oMdlTWR:SetNoInsertLine(.T.)
	oMdlTWR:SetNoDeleteLine(.T.)
EndIf

Return lOk

/*/{Protheus.doc} At820FilF3 / At820RetF3
  Consulta padrão genérica para preenchimento utilização como facilidade no preenchimento dos campos 
	necessários para o pedido de remessa adicional.
	F3 = TFI820
@since		03/08/2016       
@version	P12
@author 	Inovação - Gestão de Serviços
/*/
Function At820FilF3()
Local lRet := .T.
Local cCpoF3 := ReadVar()
Local oMdlFull := FwModelActive()
Local oMdlTWR := Nil
Local cSaveFil := cFilAnt
If IsInCallStack("AT801SUBS")
	oMdlTWR := oMdlFull:GetModel("PV_TWR")
Else
	oMdlTWR := oMdlFull:GetModel("TWR_PEDIDOS")
EndIf

cFilAnt := oMdlTWR:GetValue("TWR_FILPED")
cF3820F3 := SubString( cCpoF3, 4, Len(cCpoF3) )

If ( "TWR_CLIENT" $ cCpoF3 ) .Or. ;
	( "TWR_CLENTR" $ cCpoF3 )
// cliente
	DbSelectArea("SA1")
	SA1->( DbSetOrder( 1 ) ) // A1_FILIAL+A1_COD+A1_LOJA
	SA1->( DbSeek( xFilial("SA1") ) )
	lRet := Conpad1( NIL, NIL, NIL, "SA1CLI" )
	
ElseIf "TWR_CONDPG" $ cCpoF3
// condição de pagamento 
	DbSelectArea("SE4")
	SE4->( DbSetOrder( 1 ) ) // E4_FILIAL+E4_CODIGO
	SE4->( DbSeek( xFilial("SE4") ) )
	lRet := Conpad1( NIL, NIL, NIL, "SE4" )
	
ElseIf "TWR_TES" $ cCpoF3
// tes
	DbSelectArea("SF4")
	SF4->( DbSetOrder( 1 ) ) // F4_FILIAL+F4_CODIGO
	SF4->( DbSeek( xFilial("SF4") ) )
	lRet := Conpad1( NIL, NIL, NIL, "SF4" )
	
EndIf

cFilAnt := cSaveFil

Return lRet

/*/{Protheus.doc} At820RetF3 / At820FilF3
  Função para o retorno de conteúdo para os campos após a seleção do registro na consulta padrão
	F3 = TFI820 
@since		03/08/2016       
@version	P12
@author 	Inovação - Gestão de Serviços
/*/
Function At820RetF3()

Local oView := FwViewActive()
Local oMdl := oView:GetModel()
Local aPosLj := {}
Local oMdlTWR := Nil

If IsInCallStack("AT801SUBS")
	oMdlTWR := oMdl:GetModel("PV_TWR")
Else
	oMdlTWR := oMdl:GetModel("TWR_PEDIDOS")
EndIf

If cF3820F3 == "TWR_CLIENT"
// cliente
	cF3820Ret := SA1->A1_COD
	aPosLj := oMdlTWR:GetStruct():GetArrayPos({"TWR_LOJACL"})
	oMdlTWR:LdValueByPos(aPosLj[1], SA1->A1_LOJA)
ElseIf cF3820F3 == "TWR_CONDPG"
// condição de pagamento 
	cF3820Ret := SE4->E4_CODIGO

ElseIf cF3820F3 == "TWR_TES"
// tes
	cF3820Ret := SF4->F4_CODIGO

ElseIf cF3820F3 == "TWR_CLENTR"
// cliente de entrega
	cF3820Ret := SA1->A1_COD
	aPosLj := oMdlTWR:GetStruct():GetArrayPos({"TWR_LOJENT"})
	oMdlTWR:LdValueByPos(aPosLj[1], SA1->A1_LOJA)
EndIf

If oMdl:GetId()=="TECA820"
	oView:Refresh("TWR_PEDIDOS")
ElseIf oMdl:GetId()=="TECA801"
	oView:Refresh("PV_TWR")
EndIf

Return cF3820Ret
/*/{Protheus.doc} At820Cnpj
  Valida se o número do CNPJ do cliente corresponde ao CNPJ esperado para operação triangular
@since		04/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		cTipo, Caracter, opções são "FIL" (cnpj da filial) ou "ENT" (cnpj do cliente de entrega) 
/*/
Function At820Cnpj( oMdl, cTipo, cAvalCNPJ )
Local lRet := .F.
Local cOrcCli := ""
Local cOrcLj := ""
 
If cTipo == "FIL" .And. !Empty(cAvalCNPJ)
	lRet := ( cAvalCNPJ == At820GetCNPJ( cTipo, cEmpAnt+cFilAnt ) )
ElseIf cTipo == "ENT" .And. !Empty(cAvalCNPJ)
	lRet := At820CliLoj( @cOrcCli, @cOrcLj, oMdl:GetValue('TWR_CODTFI') )
	lRet := lRet .And. ( cAvalCNPJ == At820GetCNPJ( cTipo, xFilial("SA1")+cOrcCli+cOrcLj ) )
EndIf

Return lRet

/*/{Protheus.doc} At820GetCNPJ
  Valida se o número do CNPJ do cliente corresponde ao CNPJ esperado para operação triangular
@since		04/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		cTipo, Caracter, opções são "FIL" (cnpj da filial) ou "ENT" (cnpj do cliente de entrega) 
/*/
Static Function At820GetCNPJ( cTipo, cChave )

Local cCNPJRet := ""
Local aArea := GetArea()
Local aAreaSA1 := SA1->(GetArea())
Local aAreaSM0 := SM0->(GetArea())

If cTipo == "FIL"
	DbSelectArea("SM0")
	SM0->( DbSetOrder(1) ) // M0_CODIGO+M0_CODFIL
	If cChave == SM0->(M0_CODIGO+M0_CODFIL)
		cCNPJRet := SM0->M0_CGC
	ElseIf SM0->( DbSeek( cChave ) )
		cCNPJRet := SM0->M0_CGC
	EndIf
ElseIf cTipo == "ENT"
	If Empty(SA1->A1_CGC)
		cCNPJRet := Posicione("SA1",1,cChave,"A1_CGC")
	Else
		cCNPJRet:= SA1->A1_CGC
	EndIf
EndIf

RestArea(aAreaSM0)
RestArea(aAreaSA1)
RestArea(aArea)

Return cCNPJRet

/*/{Protheus.doc} At820CliByCnpj
  Captura o código e loja de um cliente a partir da filial e cnpj informado por parâmetro
@since		04/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		cFilCNPJ, Caracter, codigo da filial + cnpj a ter o conteúdo pesquisado
@return 		Array, pos1 => Código do Cliente, pos2 = Loja do Cliente
/*/
Static Function At820CliByCnpj( cFilCNPJ )
Local cCliFound := ""
Local cLojFound := ""
Local aArea := GetArea()
Local aAreaSA1 := SA1->(GetArea())

DbSelectArea("SA1")
SA1->( DbSetOrder( 3 ) ) //A1_FILIAL+A1_CGC

If SA1->( DbSeek( cFilCNPJ ) )
	cCliFound := SA1->A1_COD
	cLojFound := SA1->A1_LOJA
EndIf

RestArea(aAreaSA1)
RestArea(aArea)

Return { cCliFound, cLojFound }

/*/{Protheus.doc} At820GetPrd
  Captura o produto conforme o cadastro 
@since		05/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		oMdl, Objeto FwFormModel/MpFormModel, objeto principal do MVC para executar 
@param 		cFilTFI, Caracter, filial para identificar qual código de produto retornar
/*/
Function At820GetPrd( oMdl, cFilTFI, cIdMdlEquip )
Local cCodProd := ""
Local oMdlEquip := Nil
Local oMdlTFI := oMdl:GetModel("TFI_ITENS")
Local cCodTWS := ""

Default cFilTFI := oMdlTFI:GetValue("TFI_FILIAL")
Default cIdMdlEquip := "AA3_BASES"

oMdlEquip := oMdl:GetModel(cIdMdlEquip)

If oMdlEquip:GetValue("AA3_FILORI") == cFilTFI
	cCodProd := oMdlEquip:GetValue("AA3_CODPRO")
Else
	DbSelectArea("TWS")
	TWS->( DbSetOrder( 2 ) )  // TWS_FILIAL+TWS_FILPRD+TWS_PRDCOD
	If TWS->( DbSeek( xFilial("TWS")+xFilial("SB1", oMdlEquip:GetValue("AA3_FILORI"))+oMdlEquip:GetValue("AA3_CODPRO") ) )
		cCodTWS := TWS->TWS_CODIGO
		
		TWS->( DbSetOrder( 1 ) )  // TWS_FILIAL+TWS_CODIGO
		TWS->( DbSeek( xFilial("TWS")+cCodTWS ) )
		While TWS->(!EOF()) .And. TWS->TWS_CODIGO == cCodTWS
			If TWS->TWS_FILPRD == cFilTFI
				cCodProd := TWS->TWS_PRDCOD
				Exit
			Else
				TWS->(DbSkip())
			EndIf
		End
	Else
		cCodProd := oMdlEquip:GetValue("AA3_CODPRO")
	EndIf
EndIf

Return cCodProd

/*/{Protheus.doc} At820PvVld
  Valida se as informações para o pedido de remessa adicional estão ok 
@since		12/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		oMdlPrinc, Objeto MpFormModel/FwFormModel, objeto principal do mvc
@param 		oMdlPvAdic, Objeto FwFormGridModel, modelo do grid para consulta do conteúdo
/*/
Function At820PvVld( oMdlPrinc, oMdlPvAdic )

Local lOk := .T.
Local cTemp := ""
Local nItens := 0
Local lExigNF := .F.

cTemp := STR0121 + CRLF	//"Algumas linhas para pedido adicional não foram completamente preenchidas"
For nItens := 1 To oMdlPvAdic:Length()
	
	oMdlPvAdic:GoLine( nItens )
	lExigNF := oMdlPvAdic:GetValue("TWR_EXIGNF") == "1"
	
	If !Empty( oMdlPvAdic:GetValue("TWR_FILPED") ) .And. ;
		( ( lExigNF .And. ( Empty( oMdlPvAdic:GetValue("TWR_CLIENT") ) .Or.  Empty( oMdlPvAdic:GetValue("TWR_LOJACL") ) .Or. ;
			Empty( oMdlPvAdic:GetValue("TWR_PRODUT") ) .Or.  Empty( oMdlPvAdic:GetValue("TWR_TES") ) .Or. ;
			Empty( oMdlPvAdic:GetValue("TWR_CONDPG") ) ) );
		.Or. ;
		( !lExigNF .And. ( Empty( oMdlPvAdic:GetValue("TWR_CLIENT") ) .Or.  Empty( oMdlPvAdic:GetValue("TWR_LOJACL") ) ) ) )
		
		lOk := .F.
		
		If lExigNF
			cTemp += STR0122 + CRLF +;	//"Verifique os campos:"
					 STR0123 + CRLF +;	//"Cód. Cliente"
					 STR0124 + CRLF +;	//"Loja Cliente"
					 STR0125 + CRLF +;	//"Produto"
					 STR0126 + CRLF +;	//"TES"
					 STR0127 + CRLF	//"Cond.Pagto"
		Else
			cTemp += STR0122 + CRLF +;	//"Verifique os campos:"
					 STR0123 + CRLF +;	//"Cód. Cliente"
					 STR0124 + CRLF	//"Loja Cliente"
		EndIf
		
		cTemp += I18N(STR0128,;	//"Linha: #1 / Filial do Pedido: #2 / Núm. Série: #3"
					{oMdlPvAdic:GetLine(),oMdlPvAdic:GetValue("TWR_FILPED"),;
					oMdlPvAdic:GetValue("TWR_NUMSER")}) + CRLF
		Exit
	EndIf
Next nItens

If !lOk
	Help(,,'AT820PVADC',, cTemp,1,0,,,,,,{STR0129})	//"Preencha os dados corretamente para prosseguir."
EndIf
	
Return lOk

/*/{Protheus.doc} At820GerAdc
  Gera os pedidos adicionais de remessa do equipamento conforme as informações preenchidas na 
separação ou substituição de equipamentos 
@since		12/08/2016
@version	P12
@author 	Inovação - Gestão de Serviços
@param 		oMdlTWR, Objeto FwFormGridModel, modelo do grid para consulta do conteúdo
@param 		cTipoFrete, Caracter, determina qual o tipo de frete está associado com a remessa dos equipamentos no contrato/oçamento
@return 	Lógico, determina se conseguiu gerar todos os pedidos ou não
/*/
Function At820GerAdc( oMdlTWR, cTipoFrete, cContrt, cConrev )

Local lPvsOk := .T.
Local nPosPed := 0
Local aExecCabec := {}
Local aExecItens := {}
Local xAux := {}
Local cFilBkp := ""
Local oMdlTFI := oMdlTWR:GetModel():GetModel("TFI_ITENS")
Local cPedGerTWR := ""
Local cItePedGerTWR := ""

If cTipoFrete == Nil .Or. cContrt == Nil .Or. cConrev == Nil

	// posiciona no item da locação do item que está tendo o pedido adicional criado
	oMdlTFI:SeekLine({ {"TFI_COD", oMdlTWR:GetValue("TWR_CODTFI")} }) 

	cTipoFrete := oMdlTFI:GetValue("TFJ_TPFRET")
	cContrt := oMdlTFI:GetValue("TFI_CONTRT")
	cConrev := oMdlTFI:GetValue("TFI_CONREV")
EndIf

Private lMsErroAuto		:= .F.
Private lMsHelpAuto		:= .T.
Private lAutoErrNoFile	:= .F. 

For nPosPed := 1 To oMdlTWR:Length()
	
	oMdlTWR:GoLine(nPosPed)
	
	If oMdlTWR:GetValue("TWR_EXIGNF") == "1"
		aSize( aExecCabec, 0 )
		aExecCabec := {}
	
		aSize( aExecItens, 0 )
		aExecItens := {}
	
		//------------------------------------------------------
		// Gerar Pedido adicional para remessa dos equipamentos
		//------------------------------------------------------
		// Monta o cabeçalho do pedido
		aAdd( aExecCabec, {'C5_FILIAL',  oMdlTWR:GetValue("TWR_FILPED"), Nil } )
		aAdd( aExecCabec, {'C5_TIPO',    'N', Nil } )
		aAdd( aExecCabec, {'C5_CLIENTE', oMdlTWR:GetValue("TWR_CLIENT"), Nil})
		aAdd( aExecCabec, {'C5_LOJACLI', oMdlTWR:GetValue("TWR_LOJACL"), Nil})
		aAdd( aExecCabec, {'C5_CONDPAG', oMdlTWR:GetValue("TWR_CONDPG"), Nil})
	
		If !Empty(oMdlTWR:GetValue("TWR_CLENTR")) .And. !Empty(oMdlTWR:GetValue("TWR_LOJENT"))
			aAdd( aExecCabec, {'C5_CLIENT', oMdlTWR:GetValue("TWR_CLENTR"), Nil})
			aAdd( aExecCabec, {'C5_LOJAENT', oMdlTWR:GetValue("TWR_LOJENT"), Nil})
		EndIf
	
		// tipo do frete
		If !(Empty(cTipoFrete)) 
			cTipoFrete := If(cTipoFrete=="1","C","F")
			aAdd( aExecCabec, {'C5_TPFRETE', cTipoFrete ,Nil})
		EndIf
		// contrato do pedido de remessa
		If !(Empty(cContrt))  
			aAdd( aExecCabec, {'C5_REMCTR', cContrt, Nil})
		EndIf
		// revisão do contrato no pedido de remessa
		If !(Empty(cConrev))  
			aAdd( aExecCabec, {'C5_REMREV', cConrev, Nil})
		EndIf
	
		//------------------------------------------------------
		// Monta os itens para movimentar da filial dona do equipamento para a filial do contrato
		aSize( xAux, 0 )
		xAux := {}
	
		oMdlTWR:LoadValue("TWR_PEDIT",StrZero( 1, TamSx3('C6_ITEM')[1] ))
		If	IsInCallStack("At801Grv") .AND. oMdlTWR:GetValue("TWR_QTSEP") == 0
			oMdlTWR:LoadValue("TWR_QTSEP",1)
		EndIf

		aAdd( xAux, {'C6_FILIAL',  oMdlTWR:GetValue("TWR_FILPED"), Nil } )
		aAdd( xAux, {'C6_ITEM',    oMdlTWR:GetValue("TWR_PEDIT"), Nil } )
		aAdd( xAux, {'C6_PRODUTO', oMdlTWR:GetValue("TWR_PRODUT"), Nil } )
		aAdd( xAux, {'C6_QTDVEN',  oMdlTWR:GetValue("TWR_QTSEP"), Nil } )
		aAdd( xAux, {'C6_PRCVEN',  Posicione("SB1", 1,xFilial("SB1",oMdlTWR:GetValue("TWR_FILPED"))+oMdlTWR:GetValue("TWR_PRODUT"),"B1_PRV1"), Nil } )
		aAdd( xAux, {'C6_TES',     oMdlTWR:GetValue("TWR_TES"), Nil } )
		aAdd( xAux, {'C6_NUMSERI', oMdlTWR:GetValue("TWR_NUMSER"), Nil } )
	
		aAdd( aExecItens, aClone( xAux ) )
	
		// dispara execauto para gravação do Pedido de Remessa dos itens
		lMsErroAuto := .F.
		cFilBkp := cFilAnt
		cFilAnt := aExecCabec[1,2]
		MsExecAuto( { |x,y,z| MATA410( x, y, z ) }, aExecCabec, aExecItens, 3 )
	
		If lMsErroAuto
		
			lPvsOk := .F.
			xAux := GetAutoGrLog()
			MostraErro()
			cFilAnt := cFilBkp
			Exit
		Else
			cPedGerTWR := SC5->C5_NUM
			cItePedGerTWR := oMdlTWR:GetValue("TWR_PEDIT")
		EndIf
		cFilAnt := cFilBkp
	Else
		cFilBkp := cFilAnt
		cPedGerTWR := ""
		cItePedGerTWR := ""
	EndIf
	
	// Atualizar a tabela de dados adicional de remessa
	Reclock("TWR",.T.)
		TWR->TWR_FILIAL := xFilial("TWR",cFilBkp)
		TWR->TWR_CODMOV := oMdlTWR:GetValue("TWR_CODMOV")
		TWR->TWR_DESTIN := oMdlTWR:GetValue("TWR_DESTIN")
		TWR->TWR_FILPED := oMdlTWR:GetValue("TWR_FILPED")
		TWR->TWR_NUMPED := cPedGerTWR
		TWR->TWR_PEDIT  := cItePedGerTWR
		TWR->TWR_ATUFIL := oMdlTWR:GetValue("TWR_ATUFIL")
		TWR->TWR_CLIENT := oMdlTWR:GetValue("TWR_CLIENT")
		TWR->TWR_LOJACL := oMdlTWR:GetValue("TWR_LOJACL")
	TWR->(MsUnlock())
	
Next nPosPed

Return lPvsOk

//------------------------------------------------------------------------------
/*/{Protheus.doc} SelecGrn
  Carga dos equipamentos que não são controlados por ID único.
@sample 	SelecGrn(oModel) 
@since		08/08/2016       
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function SelecGrn(oModel)
Local xAux			:= ""
Local cTmpQry		:= ""
Local aRet			:= {}
Local cCodLoc		:= ""
Local oTecPvd		:= Nil
Local oStruAA3      := oModel:GetStruct()
Local nPosOrd 		:= 0
Local nPosPrdt 		:= 0 
Local nPosNSer 		:= 0

If !Empty( StrTran( cRecMarcados, "#", "" ) )
	
	xAux := StrToKArr( cRecMarcados, "#" )
	
	If Len( xAux ) >= nPosRecsGRN
		
		TFI->( DbGoTo( Val( xAux[nPosRecsGRN] ) ) )
		
		cCodLoc := TFI->TFI_COD
		
		oTecPvd := TECProvider():New()
		
		cTmpQry := oTecPvd:SelectNotId( cCodLoc )

		If !Empty(cTmpQry)
			aRet := FwLoadByAlias( oModel, cTmpQry )

			nPosOrd := oStruAA3:GetFieldPos('AA3_ORDEM')
			nPosPrdt := oStruAA3:GetFieldPos('AA3_CODPRO')
			nPosNSer := oStruAA3:GetFieldPos('AA3_NUMSER')
			Asort(aRet,,,{ | x,y |  (Alltrim(Str(x[2,nPosOrd]) + x[2,nPosPrdt] + x[2,nPosNSer])) <  (Alltrim(Str(y[2,nPosOrd]) + y[2,nPosPrdt] + y[2,nPosNSer])) } )
			
			(cTmpQry)->(DbCloseArea())
		Endif

		nPosRecsGRN++
	Endif
Endif

Return aRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} At820Disp
  Inicializador padrão para o prechimento da quantidade disponivel.
@sample 	At820Disp() 
@since		10/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Static Function At820Disp()
Local cTabTemp  := Alias()
Local oTecPvd 	:= TECProvider():New((cTabTemp)->AA3_NUMSER,(cTabTemp)->AA3_FILORI)
Local nTot 		:= 0
nTot := oTecPvd:SaldoDisponivel()

Return nTot

//------------------------------------------------------------------------------
/*/{Protheus.doc} At820VldSp
  Validação para a quantidade a ser separada, que não controla ID unico.
@sample 	At820VldSp() 
@since		11/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At820VldSp(oMdlGRN, cCmp, xVlNew, nLi , xVlOld)
Local aArea		:= GetArea()
Local oMdlAct 	:= oMdlGRN:GetModel()
lOCAL oMdlTFI 	:= oMdlAct:GetModel("TFI_ITENS")
Local aSaveLin	:= {}
Local nX		:= 0
Local nY		:= 0
Local nSepSald	:= 0
Local nSldTFI	:= 0
Local nSelec	:= 0
Local lRet 		:= .T.
Local cFilBas	:= ""
Local cIdUnic	:= ""
Local nQtdSep	:= 0
Local nLinTFI	:= oMdlTFI:GetLine()
Local lKit 		:= .F.
Local cPrdValid := ""

cFilBas	 := oMdlGRN:GetValue("AA3_FILORI")
cIdUnic  := oMdlGRN:GetValue("AA3_NUMSER")

// verifica se é um item de outra filial e avalia se há outros disponível
If cFilBas <> oMdlTFI:GetValue("TFI_FILIAL") .And. HasAvailFil( oMdlTFI, oMdlGRN, .F. )
	
	lRet := MsgNoYes( I18N(	STR0130, { oMdlTFI:GetValue("TFI_FILIAL") } ) + CRLF + ;	//"Ainda existem equipamentos disponíveis na filial do Contrato ['#1']."
								STR0131, ;	//"Tem certeza que deseja separar o equipamento de uma filial diferente?"
								STR0132 )	//"Equipamento de Filial diferente do Contrato"

EndIf

If lRet
	If oMdlGRN:GetValue("AA3_QTDSEP") > oMdlGRN:GetValue("AA3_QTDDSP") + oMdlGRN:GetValue("AA3_QTDRES") 
		lRet := .F.
		Help( , , "At820VldSp", , STR0133, 1, 0,,,,,,{STR0134}) //"Quantidade de separação maior que a quantidade disponível." ## "Informe a quantidade de separação menor ou igual a quantidade disponível."
	ElseIf ( oMdlGRN:GetValue('AA3_GNITRES') <> 0 .And. oMdlGRN:GetValue('AA3_STATUS') <> AA3_ESTOQUE )
		lRet := .F.
		Help(,,'AT820ERR05',, STR0048, 1, 0) // 'Item reservado indisponível em estoque'
	Else
		DbSelectArea('TEZ')
		TEZ->( DbSetOrder( 1 ) ) //TEZ_FILIAL+TEZ_PRODUT+TEZ_ITPROD
		//Verifica se o produto é KIT.	
		lKit := TEZ->( DbSeek( xFilial('TEZ')+oMdlTFI:GetValue('TFI_PRODUT') ) )
	Endif
EndIf

If lRet .And. !lKit //Quando não é KIT.
	aSaveLin := FwSaveRows( oMdlAct )
	For nX := 1 To oMdlGRN:Length()
		oMdlGRN:GoLine(nX)
		//Saldo para bater com a quantidade da separação.
		nSepSald := nSepSald+oMdlGRN:GetValue("AA3_QTDSEP")
	Next nX
	FwRestRows( aSaveLin, oMdlAct )

	nQtdSep := oMdlGRN:GetValue("AA3_SEPAR")+(xVlNew-xVlOld)

	If nSepSald > oMdlTFI:GetValue("TFI_QTDVEN")
		lRet := .F.
		Help( , , "At820VldSp", , STR0135, 1, 0,,,,,,{STR0136}) //"Quantidade da separação maior que a quantidade de venda." ## "Informe a quantidade da separação menor ou igual a quantidade de venda."
	Elseif nQtdSep > oMdlGRN:GetValue("AA3_QTDDSP") +  oMdlGRN:GetValue("AA3_QTDRES")
		lRet := .F.
		Help( , , "At820VldSp", , STR0137, 1, 0,,,,,,{STR0138}) //"Quantidade da separação maior que a quantidade disponível." ## "Informe a quantidade da separação menor ou igual a quantidade disponível."
	Else

		aSaveLin := FwSaveRows( oMdlAct )

		For nX := 1 To oMdlTFI:Length()
			oMdlTFI:GoLine(nX)
			//Procura nas outras partes dos Grid's de Granel.
			If oMdlGRN:SeekLine( { {'AA3_FILORI', cFilBas },{'AA3_NUMSER', cIdUnic } } ) 
			
				nQtdSep := oMdlGRN:GetValue("AA3_SEPAR")+(xVlNew-xVlOld)
				//Saldo da separação na base de atendimento.
				oMdlGRN:SetValue("AA3_SEPAR",nQtdSep)
			Endif

		Next nX

		oMdlTFI:GoLine(nLinTFI)

		nSldTFI := oMdlTFI:GetValue("TFI_SEPSLD")+(xVlOld-xVlNew)

		oMdlTFI:SetValue("TFI_SEPSLD",nSldTFI)

		FwRestRows( aSaveLin, oMdlAct )

	Endif
//Quando for Kit
ElseIf lRet .And. lKit
	//Valida se existe o produto relacionado no KIT.
	nQtdSep := oMdlGRN:GetValue("AA3_SEPAR")+(xVlNew-xVlOld)

	If nQtdSep > oMdlGRN:GetValue("AA3_QTDDSP") + oMdlGRN:GetValue("AA3_QTDRES")
		lRet := .F.
		Help( , , "At820VldSp", , STR0139, 1, 0,,,,,,{STR0140}) //"Quantidade da separação maior que a quantidade a separar." ## "Visualize outra locação e verifique a quantidade de separação."
	Else
		cPrdValid := At820GetPrd( oMdlAct, , "AA3_GRANEL" )
		If TEZ->( DbSeek( xFilial('TEZ')+oMdlTFI:GetValue('TFI_PRODUT')+cPrdValid ) )
	
			aSaveLin := FwSaveRows( oMdlAct )
	
			For nX := 1 To oMdlGRN:Length()
				oMdlGRN:GoLine( nX )
				If oMdlGRN:GetValue( 'AA3_QTDSEP', nX ) > 0 .And. At820GetPrd( oMdlAct, , "AA3_GRANEL" )==cPrdValid
					//Quantidade de separação na base de atendimento.
					nSelec := ( nSelec+oMdlGRN:GetValue( 'AA3_QTDSEP', nX ) )
				EndIf
			Next nX
	
			FwRestRows( aSaveLin, oMdlAct )
			//Valida se ultrapassa a quantidade do KIT.
			If nSelec > ( TEZ->TEZ_ITQTDE * POSICIONE('TFI',1,(xFilial('TFI')+oMdlTFI:GetValue('TFI_COD')),'TFI_SEPSLD') )
				lRet := .F.
				Help(,,'AT820ERR03',, STR0017 + CRLF + ; // "Quantidade de itens superou a quantidade vendida."
					STR0019 + CRLF + ; // "O número de equipamentos informados para compor o kit, supera o determinado na estrutura do kit"
					STR0020 + cValtoChar(oMdlTFI:GetValue('TFI_SEPSLD')) + CRLF + ; // "Quantidade de Kits Vendidos: "
					STR0021 + cValtoChar(oMdlTFI:GetValue('TFI_SEPSLD')*TEZ->TEZ_ITQTDE) + CRLF + ; // "Quantidade definida: "
					STR0141 + cValtoChar(nSelec) ,1,0) // "Quantidade informada: "			
			Else
				aSaveLin := FwSaveRows( oMdlAct )
				For nX := 1 To oMdlTFI:Length()
					oMdlTFI:GoLine(nX)
					//Procura nas outras partes dos Grid's de Granel.
					If oMdlGRN:SeekLine( { {'AA3_FILORI', cFilBas },{'AA3_NUMSER', cIdUnic } } ) 
					
						nQtdSep := oMdlGRN:GetValue("AA3_SEPAR")+(xVlNew-xVlOld)
						//Saldo da separação na base de atendimento.
						oMdlGRN:SetValue("AA3_SEPAR",nQtdSep)
					Endif
				Next nX

				FwRestRows( aSaveLin, oMdlAct )
		
				aSaveLin := FwSaveRows( oMdlAct )

				//Controla o saldo da separação na locação TFI.
				lRet := At820DcSld(oMdlTFI,oMdlGRN,.T.,"2")
				FwRestRows( aSaveLin, oMdlAct )
	
			EndIf
		Else
			lRet := .F.
			Help(,,'AT820ERR04',,STR0023,1,0) // 'Produto do tipo kit e não foi identificada sua estrutura'
		EndIf
	Endif
Endif

RestArea(aArea)

Return lRet

//------------------------------------------------------------------------------
/*/{Protheus.doc} At820GtDsp

@sample 	At820GtDsp() 
@since		11/08/2016
@version	P12
/*/
//------------------------------------------------------------------------------
Function At820GtDsp()
Local oMdlAct := FwModelActive()
Local oMdlAA3 := oMdlAct:GetModel("AA3_BASES")
Local oMdlGRN := Nil
Local cRet	  := ""

cRet := Iif(oMdlAA3:GetValue("AA3_FLAG"),"2","1")

Return cRet
//-------------------------------------------------------------------
/*/{Protheus.doc} IdErrorMvc
	Função para captura do erro gerado dentro do MVC

@sample 	IdErrorMvc()

@since  	21/10/2013
@version 	P11.90
@param  	ExpO, OBJECT, Objeto principal do MVC em que o erro aconteceu
/*/
//-------------------------------------------------------------------
Static Function IdErrorMvc( oObj )

Local xAux := oObj:GetErrorMessage()

Local cMsgErro := ;
			STR0022 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_IDFIELDERR] ) + ']' + ; // " Id do campo de erro: "
			STR0023 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_MESSAGE] ) + ']' + ;  // " Mensagem do erro:    "
			STR0024 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_SOLUCTION] ) + ']' + ;  // " Mensagem da solução: "
			STR0025 + '[' + ConvAllToChar( xAux[MODEL_MSGERR_VALUE]  ) + ']'  // " Valor atribuido:     "

Return cMsgErro


//-------------------------------------------------------------------
/*/{Protheus.doc} At820AtSld
	Atualiza o saldo dos itens granel.

/*/
//-------------------------------------------------------------------
Function At820AtSld( oModel )
Local oMdlItens  := oModel:GetModel('TFI_ITENS')
Local oMdlGrn   	:= oModel:GetModel('AA3_GRANEL') 
Local nI			:= 0
Local nX			:= 0
Local oTecPvd 	:= Nil 
Local aSaveLines := FwSaveRows()
Local nRes			:= 0

For nI := 1 To oMdlItens:Length()
	oMdlItens:GoLine(nI)
	
	If !Empty(oMdlItens:GetValue('TFI_RESERV'))
		For nX := 1 To oMdlGrn:Length()
			oMdlGrn:GoLine(nX)
			oTecPvd  := TECProvider():New(oMdlGrn:GetValue('AA3_NUMSER'),oMdlGrn:GetValue('AA3_FILORI'))
			nRes := oTecPvd:SaldoReservado(oMdlItens:GetValue('TFI_RESERV'))
			If nRes > 0
				oMdlGrn:LoadValue('AA3_QTDRES',nRes)
				oMdlGrn:SetValue('AA3_QTDSEP',oMdlGrn:GetValue('AA3_QTDRES'))
			EndIf				
			FreeObj(oTecPvd)
		Next nX	
	EndIf
Next nI

FwRestRows( aSaveLines )
Return 


/*/{Protheus.doc} AtTWRCli
	Buscar pelos valores para código de cliente e loja a serem associados com a Ordem de Serviço para montagem

@since  	03/10/2016
@version 	P12
@param  	oGridTWR, Objeto FwFormGridModel, modelo do mvc que refere-se aos pedidos adicionais para movimentação dos equipamentos
@param 		cCliOs, Caracter, referência, variável que irá receber o código do cliente
@param 		cLojOS, Caracter, referência, variável que irá receber a loja do cliente
/*/
Static Function AtTWRCli( oGridTWR, cCliOS, cLojOS )

Default cCliOs := ""
Default cLojOs := ""

If ( oGridTWR:SeekLine({{"TWR_DESTIN","2"},;
						{"TWR_FILPED", AA3->AA3_FILORI },;
						{"TWR_NUMSER", AA3->AA3_NUMSER },;
						{"TWR_CODTFI", TFI->TFI_COD    };
						}))
	
	cCliOS := oGridTWR:GetValue("TWR_CLIENT")
	cLojOS := oGridTWR:GetValue("TWR_LOJACL")
EndIf

Return

/*/{Protheus.doc} At820TWRGrn
	Inclui as linhas dos pedidos adicionais conforme a indicação da quantidade a ser separada pelo usuário
	Função executada em gatilho no campo AA3_QTDSEP
@since  	06/10/2016
@version 	P12
/*/
Function At820TWRGrn()

Local oModel := FwModelActive()
Local oMdlTFI := oModel:GetModel("TFI_ITENS")
Local oMdlGRN := oModel:GetModel("AA3_GRANEL")
Local oMdlTWR := oModel:GetModel("TWR_PEDIDOS")
Local nQtdSep := 0
Local lOk := .T.
Local lChama := .F.

If oMdlGRN:GetValue("AA3_EXIGNF") == '1' .And. ; // se exige nota fiscal para a movimentação do equipamento
	oMdlTFI:GetValue("TFI_FILIAL") <> oMdlGRN:GetValue("AA3_FILORI")  // filial do equipamento diferente da filial do contrato

	nQtdSep := oMdlGRN:GetValue("AA3_QTDSEP")
	
	// quando a quantidade 
	If nQtdSep > 0 .And. !( oMdlTWR:SeekLine({{"TWR_DESTIN","2"},;
							{"TWR_FILPED", oMdlGRN:GetValue("AA3_FILORI") },;
							{"TWR_NUMSER", oMdlGRN:GetValue("AA3_NUMSER") },;
							{"TWR_CODTFI", oMdlTFI:GetValue("TFI_COD")    };
							}))
		lChama := .T.
	ElseIf nQtdSep == 0
		lChama := .T.
	EndIf
	
	lOk := lChama .And. At820PvAdc( "AA3_GRANEL", "TWR_PEDIDOS", /*TFI*/, nQtdSep > 0, "" )
	
EndIf

Return 0

/*/{Protheus.doc} HasAvailFil
	Verifica se existe algum equipamento da filial do contrato com quantidade disponível para separação
@since  	06/10/2016
@version 	P12
@param 		oMdlTFI, Objeto FwFormGridModel, parte do modelo da tabela TFI
@param 		oMdlBase, Objeto FwFormGridModel, parte do modelo da tabela AA3 (seja id único, seja não id único)
@param 		lIdUni, Lógico, determina se é para validar Id Único ou não
@return 	Lógico, indica se há equipamentos disponíveis ou não na filial do contrato
/*/
Static Function HasAvailFil( oMdlTFI, oMdlBase, lIdUni )

Local lHas := .F.
Local aPosCpos  := {}
Local aInfCpos  := {}
Local nLinPos := 0

Default lIdUni := .T.

// campos a verificar
// 'AA3_DISP' == DEF_STATUS_DISPONIVEL
// 'AA3_FILORI' == oMdlTFI:GetValue('TFI_FILIAL')
// 'AA3_CODPRO' ==  ( considerar conversão pela tabela TWS )
If lIdUni
	aPosCpos := oMdlBase:GetStruct():GetArrayPos({'AA3_FILORI','AA3_CODPRO','AA3_DISP'})
	aInfCpos := { oMdlTFI:GetValue('TFI_FILIAL'), ;
					At820GetPrd( oMdlTFI:GetModel() ), ;
					DEF_STATUS_DISPONIVEL}
Else
	aPosCpos := oMdlBase:GetStruct():GetArrayPos({'AA3_FILORI','AA3_CODPRO','AA3_QTDDSP','AA3_SEPAR'})
	aInfCpos := { oMdlTFI:GetValue('TFI_FILIAL'), ;
					At820GetPrd( oMdlTFI:GetModel(), oMdlTFI:GetValue('TFI_FILIAL'), oMdlBase:GetId() )}
EndIf

For nLinPos := 1 To oMdlBase:Length()
	If oMdlBase:GetValueByPos( aPosCpos[1], nLinPos ) == aInfCpos[1] .And. ;  // é da mesma filial do contrato?
		oMdlBase:GetValueByPos( aPosCpos[2], nLinPos ) == aInfCpos[2] .And. ; // o código do produto está certo?
		 ( ( lIdUni .And. oMdlBase:GetValueByPos( aPosCpos[3], nLinPos ) == aInfCpos[3] ) .Or. ;  // está com status disponível?
		 ( !lIdUni .And. ;
		 		oMdlBase:GetValue('AA3_QTDSEP') > 0 .And. ;
		 		oMdlBase:GetValueByPos( aPosCpos[3], nLinPos ) > oMdlBase:GetValueByPos( aPosCpos[4], nLinPos ) ) ) // existe qtde disponível?
		 
		lHas := .T.
		Exit
	EndIf
Next nLinPos
		
Return lHas

/*/{Protheus.doc} At820TEWSep
	Calcula quantos já foram separados daquele item de locação
@since  	06/10/2016
@version 	P12
@param 		lKit, Lógico, define se o item sendo separado é kit ou não
@return 	Lógico, indica se há equipamentos disponíveis ou não na filial do contrato
/*/
Static Function At820TEWSep( lKit, cCodTFI, cCodPrdKit, nQtTFI )

Local nQtdSepTEW 	:= 0
Local cQry 			:= GetNextAlias()
Local nQtDistrTEW 	:= 0
Local nQtKit 		:= 0

BeginSQL Alias cQry

	SELECT COALESCE( SUM ( TEW_QTDVEN ) , 0 ) VAL1
	FROM %Table:TEW% TEW
	WHERE TEW_FILIAL = %xFilial:TEW%
		AND TEW_CODEQU = %Exp:cCodTFI%
		AND TEW.%NotDel%
		AND TEW_BAATD <> ' '
		AND TEW_TIPO <> '2'

EndSQL

nQtDistrTEW := (cQry)->VAL1
(cQry)->(DbCloseArea())

If lKit
	BeginSQL Alias cQry
		SELECT COALESCE( SUM ( TEZ_ITQTDE ) , 0 ) VAL1
		FROM %Table:TEZ% TEZ
		WHERE TEZ_FILIAL = %xFilial:TEZ%
			AND TEZ_PRODUT = %Exp:cCodPrdKit%
			AND TEZ.%NotDel%
	EndSQL
	
	nQtKit := (cQry)->VAL1
	(cQry)->(DbCloseArea())
EndIf

// executa a conta de "saldo" considerando se é kit ou não
If lKit
	nQtdSepTEW := ( nQtDistrTEW / nQtKit )
Else
	nQtdSepTEW := nQtDistrTEW
EndIf

Return nQtdSepTEW

/*/{Protheus.doc} At820InsTEW
	Calcula quantos já foram separados daquele item de locação
@since  	07/10/2016
@version 	P12
@param 		aGerMOv, array com os daods para a geração do novo registro para locação
@return 	Lógico, indica se conseguiu se conseguiu incluir ou não um novo registro na tabela TEW
/*/
Static Function At820InsTEW( aGerMov )

Local aAreaSB1 	:= SB1->(GetArea())
Local aAreaAA3 	:= AA3->(GetArea())
Local aAreaTFI 	:= TFI->(GetArea())
Local aAreaTEW 	:= TEW->(GetArea())
Local oMdlMov	:= NIl
Local lRet 		:= .T.
Local cMsgErro 	:= ""

oMdlMov := FwLoadModel("TECA800")
oMdlMov:SetOperation( MODEL_OPERATION_INSERT )
lRet := oMdlMov:Activate()

lRet := lRet .And. oMdlMov:SetValue( "MOVIM", "TEW_ORCSER", aGerMov[1,1] )
lRet := lRet .And. oMdlMov:SetValue( "MOVIM", "TEW_CODEQU", aGerMov[1,2] )
lRet := lRet .And. oMdlMov:SetValue( "MOVIM", "TEW_PRODUT", aGerMov[1,3] )
lRet := lRet .And. oMdlMov:SetValue( "MOVIM", "TEW_QTDVEN", aGerMov[1,4] )
lRet := lRet .And. oMdlMov:SetValue( "MOVIM", "TEW_CODKIT", aGerMov[1,5] )
lRet := lRet .And. oMdlMov:SetValue( "MOVIM", "TEW_KITSEQ", aGerMov[1,6] )

lRet := lRet .And. oMdlMov:VldData() .And. oMdlMov:CommitData()

If !lRet
	cMsgErro += IdErrorMvc( oMdlMov )
Endif

oMdlMov:DeActivate()
oMdlMov:Destroy()

RestArea(aAreaTEW)
RestArea(aAreaTFI)
RestArea(aAreaAA3)
RestArea(aAreaSB1)

Return lRet

/*/{Protheus.doc} At820CpyTWR
	Copia os dados da linha atual da TWR para uma nova linha em função da necessidade de quebra na distribuição das quantidades
de um equipamento controlado por quantidade
@since  	10/10/2016
@version 	P12
@param 		oMdlTWR, Objeto FwFormGridModel: TWR_PEDIDOS, grid com os dados da tabela TWR na separação de equipamentos
@param 		cCodTEW, Caracter, código da movimentação a ser associada com o pedido adicional
@param 		nQuantDistr, Numérico, quantidade a ser inserida para a distribuição dos equipamentos
/*/
Static Function At820CpyTWR( oMdlTWR, cCodTEW, nQuantDistr )
Local nLinAtual := oMdlTWR:GetLine()
Local aFields 	:= oMdlTWR:GetStruct():GetFields()
Local nCpos 	:= 0
Local xValor 	:= Nil

oMdlTWR:SetNoInsertLine( .F. )

oMdlTWR:AddLine()

For nCpos := 1 To Len(aFields)
	xValor := oMdlTWR:GetValue( aFields[nCpos,MODEL_FIELD_IDFIELD], nLinAtual )
	oMdlTWR:LoadValue( aFields[nCpos,MODEL_FIELD_IDFIELD], xValor )
Next nCpos

oMdlTWR:LoadValue( "TWR_CODMOV", cCodTEW )
oMdlTWR:LoadValue("TWR_QTSEP", nQuantDistr )

oMdlTWR:SetNoInsertLine( .T. )

oMdlTWR:GoLine(nLinAtual)

Return 

/*/{Protheus.doc} At820IsTWS
	Verifica se um determinado produto pertence ao cadastro de produtos semelhantes entre as filiais
@since  	10/11/2016
@version 	P12
@param 		cProdFil, Caracter, filial do produto a ser validado
@param 		cProdCod, Caracter, código do produto a ser validado
@return 	Lógico, determina se encontrou o produto cadastro em algum conjunto de produtos semelhantes
/*/
Function At820IsTWS( cProdFil, cProdCod )
Local lRet := .F.

DbSelectArea("TWS")
TWS->(DbSetOrder( 2 )) // TWS_FILIAL+TWS_FILPRD+TWS_PRDCOD 

If !Empty( cProdFil ) .And. ;
	!Empty( cProdCod ) .And. ;
	TWS->(DbSeek( xFilial("TWS")+cProdFil+cProdCod ))
	
	lRet := .T.
EndIf

Return lRet

/*/{Protheus.doc} At820FilPd
@description 	Retorna o produto de uma determinada filial quando existe no cadastro de produtos relacionados
@since  		27.01.2017
@version 		P12
@param 			cPrdBase, Caracter, Produto base sendo procurado
@param 			cFilBase, Caracter, Filial base do produto a ser produrado
@param 			cFilBusca, Caracter, Filial alvo para ter o produto pesquisado
@return 		Lógico, determina se encontrou o produto cadastro em algum conjunto de produtos semelhantes
/*/
Function At820FilPd( cPrdBase, cFilBase, cFilBusca )
Local cPrdRet := ""
Local cCodTWS := ""
Local cFilTWS := xFilial("TWS")

If At820IsTWS( cFilBase, cPrdBase )
	cCodTWS := TWS->TWS_CODIGO

	DbSelectArea("TWS")
	TWS->( DbSetOrder( 1 )) // TWS_FILIAL + TWS_CODIGO
	TWS->( DbSeek( cFilTWS + cCodTWS ) )

	While TWS->(!EOF()) .And. TWS->TWS_FILIAL  == cFilTWS .And. TWS->TWS_CODIGO == cCodTWS

		If TWS->TWS_FILPRD == cFilBusca
			cPrdRet := TWS->TWS_PRDCOD
			Exit
		EndIf
		TWS->(DbSkip())
	End
Else
	cPrdRet := cPrdBase
EndIf

Return cPrdRet
