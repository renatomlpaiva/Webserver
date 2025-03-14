#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "JSON.CH"
 
WSRESTFUL WSMATA020 DESCRIPTION "Web service para tratativade fornecedores"

WSDATA cFornecedor AS STRING
WSDATA cLojaFornec AS STRING
WSDATA cCNPJ 		 AS STRING

WSMETHOD GET DESCRIPTION "Retorna fornecedor cadastrado." WSSYNTAX "/wsmata020/{cnpj_emp} "
WSMETHOD POST DESCRIPTION "Inclui/Atualiza fornecedor cadastrado." WSSYNTAX "/wsmata020/{cnpj_emp}"
//WSMETHOD PUT DESCRIPTION "Inclui/Atualiza fornecedor cadastrado." WSSYNTAX "/wsmata020/{cnpj_emp}"
//WSMETHOD DELETE DESCRIPTION "Exclui fornecedor cadastrado." WSSYNTAX "/wsmata020/{cnpj_emp}"
 
END WSRESTFUL
 
// O metodo GET nao precisa necessariamente receber parametros de querystring, por exemplo:
// WSMETHOD GET WSSERVICE MATA020 

WSMETHOD GET WSRECEIVE cFornecedor, cLojaFornec, cCNPJ  WSSERVICE WSMATA020
Local i		:= 0
Local cRet	:= ""
Local cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local aStruct	:= {}
Local aJSON	:= {}
Local oJSON	:= Nil
Local lRet := .T.
Local aCodEmp := {}

DEFAULT ::cFornecedor	:= ""
DEFAULT ::cLojaFornec	:= ""
DEFAULT ::cCNPJ		:= ""

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 INICIO")
// define o tipo de retorno do metodo
::SetContentType("application/json")
aCodEmp := StaticCall(WS_CNTA100,GetCodEmp,::aURLParms[1])
RpcClearEnv()
RpcSetType(3)
RpcSetEnv(aCodEmp[1],aCodEmp[2])

/*
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 COD:"+::cFornecedor)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 LOJA:"+::cLojaFornec)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 CNPJ:"+::cCNPJ)
*/	
If (!Empty(::cFornecedor) .And. !Empty(::cLojaFornec)) .Or. !Empty(::cCNPJ)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 INICIO CONSULTA.")
/*	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 COD:"+::cFornecedor)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 LOJA:"+::cLojaFornec)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 CNPJ:"+::cCNPJ)
*/	
	cQuery := " SELECT "
	cQuery += " * "
	cQuery += " FROM " + RetSqlName("SA2") + " SA2 "
	cQuery += " WHERE "
	cQuery += " SA2.D_E_L_E_T_=' ' "
	cQuery += " AND " + If(Empty(::cCNPJ)," A2_COD='" + ::cFornecedor + "' AND A2_LOJA='" + ::cLojaFornec + "' "," A2_CGC='" + ALLTRIM(::cCNPJ) + "' " )
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), _cAlias, .F., .F.)
	
	(_cAlias)->(DbGoTop())
	If !(_cAlias)->(Eof())
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 GERA JSON RETORNO.")
		aStruct := (_cAlias)->(DbStruct())
		aAdd( aJSON, JSONObject():New() )
		
		//aEval(aStruct,{|x| &("aJSON[Len(aJSON)][#'"+x[1]+"'] := If(x[2]=='N',Alltrim(Str((_cAlias)->"+x[1]+")),Alltrim((_cAlias)->"+x[1]+"))")})		
		For i:= 1 To Len(aStruct)
			aJSON[Len(aJSON)][#&("'"+aStruct[i][1]+"'")] := If(aStruct[i][2]=="N",cValToChar((_cAlias)->&(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
		Next
		oJSON := JSON():New( aJSON )
		
		::SetResponse(StrTran(oJSON:Stringify(),"\",""))
	Else 
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020: PARAMETRO INVALIDO.")	
		lRet := .F.
		SetRestFault(400, 'CNPJ/CPF nao encontrato.')			
	EndIf
	If Select(_cAlias) > 0
		(_cAlias)->(DbCloseArea())
	EndIf
Else
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020: CNPJ/CPF INVALIDO.")
	SetRestFault(400, "id parameter is mandatory")
	lRet := .F.
EndIf

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA020 FIM ")
Return lRet
 
// O metodo POST pode receber parametros por querystring, por exemplo:
// WSMETHOD POST WSRECEIVE startIndex, count WSSERVICE MATA020
WSMETHOD POST WSSERVICE WSMATA020
Local lPost := .T.
Local cJson := ""
Local oJson	:= Nil
Local aContrato	:= {}
Local aFornec		:= {}
Local aPlanilha	:= {}
Local aCodEmp := {}

oJsonParser := tJsonParser():New()

// Exemplo de retorno de erro
If Len(::aURLParms) == 0
	SetRestFault(400, "id parameter is mandatory")
	lPost := .F.
Else
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA020 INICIO")
	// define o tipo de retorno do metodo
	::SetContentType("application/json")
	aCodEmp := StaticCall(WS_CNTA100,GetCodEmp,::aURLParms[1])

	RpcSetType(3)
	RpcSetEnv(aCodEmp[1],aCodEmp[1])
	InitPublic()
	SetsDefault()
	SetModulo('SIGACOM','COM')
	// recupera o body da requisiÁ„o
	cJson := ::GetContent()
	//conout('cBody>> '+cJson)
	FWJSONDeserialize(cJson,@oJson)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA020 DESERIALIZADO")	
	//conout("TYPE: " + Type("oJson"))
	//conout("len:" + str(len(oJson)))
	//conout("TYPE: " + ValType(oJson))
	//sleep(2000)
	If Len(oJson) > 0	
		strJson = cJson
		lenStrJson := Len(strJson)
		aJsonfields := {}
		nRetParser := 0
		oJHM := .F.
		lRet := .F.
		
		If(lRet := oJsonParser:Json_Hash(strJson, lenStrJson, @aJsonfields, @nRetParser, @oJHM))
			ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA020 PARSE REALIZADO")
			Begin Transaction 
				aRet := LoadFornec(oJson,aJsonFields)
				If Len(aRet) > 0
					ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA020 WF REALIZADO VLD RETORNO")
					If (lPost := aRet[1])
						
						ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA020 WF REALIZADO C/ SUCESSO")
						If SubStr(cJson,Len(cJson)) == "]"
							ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA020 WF REALIZADO ADD MSG")
							cJson := Alltrim(cJson)
							::SetResponse(SubStr(cJson,1,Len(cJson)-1)+',{"message":"Workflow de cadastro iniciado com sucesso."}]')
						Else
							::SetResponse(cJson)
						EndIf
					Else
						cMsg  := aRet[2]
						SetRestFault(400, cMsg)			
					EndIf
				EndIf
			End Transaction     
		Else
	   		ConOut("[USER][ERRO][" + DToC(DATE()) + " " + TIME() + "] ERRO 02")
	   		SetRestFault(400, "ERROR 02")
	   		lPost := .F.
		EndIf
	Else
			ConOut("[USER][ERRO][" + DToC(DATE()) + " " + TIME() + "] ERRO 01")
	   		SetRestFault(400, "ERROR 01")
	   		lPost := .F.
	EndIf
EndIf

Return lPost
 
// O metodo PUT pode receber parametros por querystring, por exemplo:
// WSMETHOD PUT WSRECEIVE startIndex, count WSSERVICE MATA020
/*WSMETHOD PUT WSSERVICE WSMATA020
Local lPut := .T.
 
// Exemplo de retorno de erro
If Len(::aURLParms) == 0
   SetRestFault(400, "id parameter is mandatory")
   lPut := .F.
Else
   // recupera o body da requisiÁ„o
   cBody := ::GetContent()
   // insira aqui o cÛdigo para operaÁ„o de atualizaÁ„o
   // exemplo de retorno de um objeto JSON
   ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"MATA020"}')
EndIf
Return lPut
 */
// O metodo DELETE pode receber parametros por querystring, por exemplo:
// WSMETHOD DELETE WSRECEIVE startIndex, count WSSERVICE MATA020
/*
WSMETHOD DELETE WSSERVICE WSMATA020
Local lDelete := .T.
 
// Exemplo de retorno de erro
If Len(::aURLParms) == 0
   SetRestFault(400, "id parameter is mandatory")
   lDelete := .F.
 
Else
   // insira aqui o cÛdigo para operaÁ„o exclus„o
   // exemplo de retorno de um objeto JSON
   ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"MATA020"}')
EndIf
Return lDelete
*/


Static Function LoadFornec(oJson,aJsonFields,cCodUsu)
Local aRet := {.F.,"[ERRO] NAO OCORREU EXECUCAO"}
Local aJsonForn := {}
Local i := 0
Local cModel := "PCWFC05"

DEFAULT oJson := Nil
DEFAULT aJsonFields := {}
DEFAULT cCodUsu := SuperGetMv("PZ_USRGCT",.F.,"000000")

aJsonForn := If(Len(aJsonFields)>0,aJsonFields[1][1][2],{})

aDados 	:= {}
		
For i:= 1 To Len(aJsonForn)
	aAdd(aDados,{"PCWFC05MOD",aJsonForn[i][1],aJsonForn[i][2]})
	conout("CARGA DE ADADOS - : " + aDados[Len(aDados)][1] + "|" +;
								    aDados[Len(aDados)][2] + "|" +;
									aDados[Len(aDados)][3] + "|")
Next

If Len(aDados) > 0
	aRet := SetWFCad(aDados,"PCWFCO5",MODEL_OPERATION_INSERT)
	If Len(aRet) > 0
		If aRet[1]
			_cTabela := "SA2"
			_aDados	 := aRet[3]
			_cTipo	 := "2"
			_nOpcao	 := 3
			_cCodDig := ""
			_cLojDig := ""
			_cFluxoSA2 := "" 
			_aAcesso := StaticCall(PCWFC04,GETACESSO,cCodUsu,"Inclus�o","1",_cTipo)
			U_PCWFC045(cCodUsu,_cTabela,_aDados,_cTipo,"1",_nOpcao,_cCodDig,_cLojDig,_cFluxoSA2,,,_aAcesso[2],"1")
		EndIF
	EndIf
EndIf

Return aRet


Static Function SetWFCad(aDados,cModel,nOperation,cCodUsu,nTipOpe,nValExe,cCodCad,cLoja,aCpoWhen,cNrProc,xPortal,cTipCad)
Local oMdlPut := Nil
Local lRet := .T.
Local cNumSPgto := ""
Local cMsg	:= ""
Local cTipUsu := "1"
Local i := 0
Local lError := .F.
Local bLastError := Nil

DEFAULT cModel := "PCWFC05"
DEFAULT nOperation := MODEL_OPERATION_INSERT 
DEFAULT aDados := {}
DEFAULT cCodUsu := "003828"

Default cNrProc		:= ""
Default xPortal 	:= .F.
Default nValExe 	:= 1
Default nTipOpe		:= 3
Default cCodCad		:= ""
Default cLoja		:= ""
Default aCpoWhen	:= {}
Default cTipCad		:= "2"

Private aCpoWhenWF	:= Aclone(aCpoWhen)
Private lPortal 	:= .T.
Private	cAreUsuWF	:= U_PCWFC05A(cCodUsu) //Retona a �rea do Usu�rio
Private cCodUsuWF	:= cCodUsu
Private cTipCadWF	:= cTipCad
Private cTipUsuWF	:= cTipUsu
Private cNrProcWF	:= cNrProc
Private nTipOpeWF	:= nTipOpe //3-Inclusao 4-Alteracao
Private nValExeWF	:= nValExe // 1-Operacao Unica  2-Operacao Dupla (Execusao e Validacao)
Private cCodCadWF	:= IIf(cTipCad=="1",Padr(cCodCad,TamSX3("B1_COD")[1]),Padr(cCodCad,TamSX3("A2_COD")[1])+Padr(cLoja,TamSX3("A2_LOJA")[1]))
Private cTitulo		:= IIf(cTipCad=="1","Produto","Fornecedor")
Private cAliasWF	:= IIf(cTipCad=="1","SB1","SA2")
Private aHeaderCad	:= {} //Estrutura SX3
Private aAreasCad	:= {} //Area do Usu�rio Solicitante ou todas as �reas quando Executor ou Validador
Private aRetCpoPre	:= {} //Campos com os valores digitados
Private aCpoUsuWF	:= {}
Private aValCpoWF	:= U_ValCpoWF() //Campos com validacao do WF
Private cMotRec		:= "" //Motivo da Recusa
Private aCposWhen	:= aCpoWhen
Private oStruModCad	:= FWFormModelStruct():NEW()  
Private aCpoOriWF	:= {} //Campos passados antes da alteracao
Private cCpoSF3		:= ""
Private aCpoValEsp	:= {"B1_DESC   ","B1_CODBAR"} //validacao de campos especificos

Private lRecusa		:= .F.
Private _lConfRec	:= .F.

Private aLstAnex := {}
Private aLsTexc := {}

bLastError := ErrorBlock( { |e|  lError := .T., cMsgError := e:DESCRIPTION,ConOut(cMsgError)  } )

Begin Sequence
	If Len(aDados) > 0
		aCpoUsuWF	:= StaticCall(PCWFC05,PCWFC05USU,cTipUsu,cCodUsu,cTipCad,cAreUsuWF)
		conout("aCpoUsuWF - " + cValToChar(len(aCpoUsuWF)))
		//sleep(4000)
		StaticCall(PCWFC05,PCWFC05SX3,cTipUsu,cCodUsu,cAreUsuWF,cTipCad)
		conout("000 model TYPE: " + Type("aHeaderCad"))


		conout("aHeaderCad" + cValToChar(Len(aHeaderCad)))
		//sleep(4000)

		conout("001 model TYPE: " + Type("oJson"))
		conout("002 model TYPE: " + Type("aDados"))
			//conout("len:" + str(len(oJson)))
		///sleep(3000)
		//conout("002 model TYPE: " + ValType(oJson))

		conout("Lendo aDados")
		For i:=1 To Len(aDados)
			CONOUT("ADADOS"+aDados[i][1]+"|"+aDados[i][2]+"|"+aDados[i][3]+"|")
		Next
		conout("Fim - Leitura aDados")

		CONOUT("WSMATA020 - INICIO PRENCHIMENTO DO MODELO")
		//sleep(2000)
		CONOUT("WSMATA020 - CARREGA MODELO")
		//oModel := FWLoadModel(cModel)
		oViewPut:= StaticCall(PCWFC05,ViewDef)
		oModel := oViewPut:oModel
		oModel:SetPost({|| .T.},,)
		//oMdlPut	:= oModel:GetModel("PCWFC05MOD")
		CONOUT("WSMATA020 - DEFINE OPERACAO")
		conout("003 oModel TYPE: " + Type("oViewPut"))
		conout("003 oModel TYPE: " + Type("oModel"))
		oModel:SetOperation(nOperation)
		CONOUT("WSMATA020 - ATIVA O MODELO")
		oModel:Activate()
		//sleep(3000)
		//oMdlPut := oModel:GetModel("PCWFC05MOD")
		//SLEEP(4000)
		CONOUT("WSMATA020 - PREENCHE O MODELO")
		//SLEEP(5000)
		For i:=1 To Len(aDados)
			CONOUT("ADADOS"+aDados[i][1]+"|"+aDados[i][2]+"|"+aDados[i][3]+"|")
			//sleep(3000)
			//oModel:SetValue(/*cField*/aDados[i][1],/*cColumn*/PadR(aDados[i][2],10),/*cValUpd*/If(ValType(aDados[i][3])=="N",aDados[i][3],If(ValType(aDados[i][3])=="D",aDados[i][3],Alltrim(aDados[i][3]))))
			oModel:LoadValue(/*cField*/aDados[i][1],/*cColumn*/PadR(aDados[i][2],10),/*cValUpd*/If(ValType(aDados[i][3])=="N",aDados[i][3],If(ValType(aDados[i][3])=="D",aDados[i][3],Alltrim(aDados[i][3]))))
		Next
		
		//SLEEP(3000)
		CONOUT("WSMATA020 - VALIDA O MODELO")
		If (lRet := oModel:VldData())
			CONOUT("WSMATA020 - VALIDACAO DO MODELO OK")
			oModel:CommitData()
		Else
			aErro := oModel:GetErrorMessage()
			VarInfo("",aErro)
			//cMsg:=aErro[MODEL_MSGERR_IDFORM]+CRLF+aErro[MODEL_MSGERR_IDFIELD]+CRLF+aErro[MODEL_MSGERR_IDFORMERR]+CRLF+aErro[MODEL_MSGERR_IDFIELDERR]+CRLF+aErro[MODEL_MSGERR_ID]+CRLF+aErro[MODEL_MSGERR_MESSAGE]+CRLF+aErro[MODEL_MSGERR_SOLUCTION]
			cMsg:=aErro[MODEL_MSGERR_IDFORM]+"|"+aErro[MODEL_MSGERR_IDFIELD]+"|"+aErro[MODEL_MSGERR_IDFORMERR]+"|"+aErro[MODEL_MSGERR_IDFIELDERR]+"|"+aErro[MODEL_MSGERR_ID]+"|"+aErro[MODEL_MSGERR_MESSAGE]+"|"+aErro[MODEL_MSGERR_SOLUCTION]			

			lRet := .F.
		EndIf
		oModel:DeActivate() 
		CONOUT("WSMATA020 - FINALIZADO")
	Else
		CONOUT("WSMATA020 - ADADOS NAO INFORMADO")
		cMsg := "OCORREU ALGUM PROBLEMA NA CARGA DE INFORMACAO, CONTATE O ADMINISTRADOR."
		lRet := .F.
	EndIf

End Sequence

ErrorBlock(bLastError)

If lError
	lRet := .F.
	cMsg := cMsgError
EndIf

Return {lRet,cMsg,aRetCpoPre}