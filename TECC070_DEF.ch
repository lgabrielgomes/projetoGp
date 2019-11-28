//------------------------------------------------------------------------------
/*/{Protheus.doc} Tecc070_Def 
Defines usados dentro da rotina Tecc070 - Central do Cliente
Os codigos do Define são "reservados" por grupo para que seja possivel adicionar
mais itens futuramente. 

Todos os defines que indicam Grupos se iniciam com "M_"
Todos os defines que indicam itens de um grupo se iniciam com "I_"

* Para cara item do tipo "M_", reservar um range de casas com no minimo 99 opcoes
 	De forma que ele sempre comece como "0000100" ou "0000200" por exemplo
 	
@since		19/12/2016       
@version	P12
@author		Cesar Bianchi
/*/
//------------------------------------------------------------------------------
//Defines do Cabecalho da tree
#DEFINE M_RAIZ			'0000000'
#DEFINE M_CLIENTE		'0000001'

//Defines do Grupo Oportunidade
#DEFINE M_OPORT			'0000100'
#DEFINE I_OP_SEMPROP	'0000101'
#DEFINE I_OP_EMABERT	'0000102'
#DEFINE I_OP_ENCERRA	'0000103'
#DEFINE I_OP_CANCELA	'0000104'

//Defines do Grupo Propostas
#DEFINE M_PROPOSTAS		'0000200'
#DEFINE I_PR_EMABER		'0000201'
#DEFINE I_PR_FINALI		'0000202'
#DEFINE I_PR_VISTEC		'0000203'

//Defines do Grupo Contratos		
#DEFINE M_CONTRATOS		'0000300'
#DEFINE I_CT_VIGENT		'0000301'
#DEFINE I_CT_ENCERR		'0000302'
#DEFINE I_CT_MEDICA		'0000303'
				
//Defines do Grupo Financeiro
#DEFINE M_FINANCEIR		'0000400'
#DEFINE I_FI_TITABE		'0000401'
#DEFINE I_FI_TITBXA		'0000402'
#DEFINE I_FI_TITVEN		'0000403'
#DEFINE I_FI_PRVABE		'0000404'
#DEFINE I_FI_PRVVEN		'0000405'

//Defines do Grupo aturamento
#DEFINE M_FATURAMEN		'0000500'
#DEFINE I_FT_PEDABE		'0000501'
#DEFINE I_FT_PEDFAT		'0000502'
#DEFINE I_FT_NOTSRV		'0000503'
#DEFINE I_FT_NOTREM		'0000504'
#DEFINE I_FT_NOTRET		'0000505'
#DEFINE I_FT_NOTOTR		'0000506'

//Defines dos Locais de Atendimento
#DEFINE M_LOCAISATE		'0000600'
#DEFINE I_LA_CONTRA		'0000601'
#DEFINE I_LA_SEMCON		'0000602'

//Defines de Equipamentos
#DEFINE M_EQUIPAMEN		'0000700'
#DEFINE I_EQ_RESERV		'0000701'
#DEFINE I_EQ_LOCADO		'0000702'
#DEFINE I_EQ_DEVOLV		'0000703'
#DEFINE I_EQ_ASEPAR		'0000704'
#DEFINE I_EQ_SEPARA		'0000705'
	
//Defines Recursos Humanos
#DEFINE M_RECHUMANO		'0000800'
#DEFINE I_RH_POSTOS		'0000801'
#DEFINE I_RH_ATEND		'0000802'
#DEFINE I_RH_ATFUT		'0000803'
 	
//Defines Ordens de Servico
#DEFINE M_ORDSERICO		'0000900'
#DEFINE I_OS_SIGTEC		'0000901'
#DEFINE I_OS_SIGMNT		'0000902'
	
//Defines Armamentos
#DEFINE M_ARMAMENTO		'0001000'
#DEFINE I_AR_ARMAS		'0001001'
#DEFINE I_AR_COLETE		'0001002'
#DEFINE I_AR_MUNICO		'0001003'	

/*
OUTROS DEFINES
 */
#DEFINE ARMAS		'1'
#DEFINE COLETES		'2'
#DEFINE MUNICOES	'3'
#DEFINE GETDADOS	1
#DEFINE FWGRAPH		2
#DEFINE TIBROWSER	3 
 
