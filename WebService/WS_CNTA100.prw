#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "JSON.CH"
 
#DEFINE _cTBLSLD "ZN9"
#DEFINE GETCAB	"CN9_NUMERO,CN9_REVISA,CN9_DESCRI"

WSRESTFUL WSCNTA100 DESCRIPTION "Web service para tratativade fornecedores"

WSDATA cFornecedor AS STRING
WSDATA cLojaFornec AS STRING
WSDATA cCNPJ 		 AS STRING
WSDATA cContrato	 AS STRING
WSDATA cRevisa	 AS STRING
WSDATA cXIdExt	 AS STRING
WSDATA cConsSld AS STRING

WSMETHOD GET DESCRIPTION "Retorna fornecedor cadastrado." WSSYNTAX "/WSCNTA100/{cnpj_emp} "
WSMETHOD POST DESCRIPTION "Inclui/Atualiza fornecedor cadastrado." WSSYNTAX "/WSCNTA100/{cnpj_emp}"
 
END WSRESTFUL
 

WSMETHOD GET WSRECEIVE cFornecedor, cLoja, cContrato, cRevisa, cXIdExt,cConsSld  WSSERVICE WSCNTA100
Local i		:= 0
Local cRet	:= ""
Local cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local aStruct	:= {}
Local aJSON	:= {}
Local oJSON	:= Nil
Local aCodEmp := {}

DEFAULT ::cFornecedor	:= ""
DEFAULT ::cLojaFornec	:= ""
DEFAULT ::cContrato	:= ""
DEFAULT ::cRevisa		:= ""
DEFAULT ::cXIdExt		:= ""
DEFAULT ::cConsSld := ""

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 INICIO")

::SetContentType("application/json")

aCodEmp:=GetCodEmp(::aURLParms[1])

RpcSetType(3)
RpcSetEnv(aCodEmp[1],aCodEmp[2])

_cTBLSLD := If(_cTBLSLD == Nil .Or. Empty(_cTBLSLD),"ZN9",_cTBLSLD)

If (!Empty(::cFornecedor) .And. !Empty(::cLojaFornec)) .Or. !Empty(::cCNPJ)
/*
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 COD:"+::cFornecedor)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 LOJA:"+::cLojaFornec)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 CONTRATO:"+::cContrato)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 REVISAO:"+::cRevisa)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 ID.EXTERNO:"+::cXIdExt)
*/	
	If !Empty(::cConsSld)
		cQuery := " SELECT "
		cQuery += " CN9_NUMERO,CN9_REVISA,CN9_DESCRI,"
		cQuery += _cTBLSLD+".* "
		cQuery += " FROM " + RetSqlName("CN9") + " CN9 "
		cQuery += " JOIN " + RetSqlName("CNC") + " CNC "
		cQuery += " ON(CNC.D_E_L_E_T_=' ' AND CNC_FILIAL=CN9_FILIAL AND CNC_NUMERO=CN9_NUMERO )
		cQuery += " JOIN " + RetSqlName(_cTBLSLD) + " " +  _cTBLSLD
		cQuery += "	ON(" + _cTBLSLD + ".D_E_L_E_T_=' ' AND CN9_FILIAL=" + _cTBLSLD + "_FILIAL AND CN9_NUMERO=" + _cTBLSLD + "_CONTRA )"//AND CND_XIDLIB=" + _cTBLSLD + "_NUMERO AND CND_FILIAL=" + _cTBLSLD + "_FILIAL)"
		cQuery += " JOIN " + RetSqlName("SA2") + " SA2 "
		cQuery += "	ON(SA2.D_E_L_E_T_=' ' AND CNC_CODIGO=A2_COD AND CNC_LOJA=A2_LOJA) 
		cQuery += " LEFT JOIN " + RetSqlName("CND") + " CND "
		cQuery += "	ON(CND.D_E_L_E_T_=' ' AND CN9_FILIAL=CND_FILIAL AND CN9_NUMERO=CND_CONTRA AND CN9_REVISA=CND_REVISA AND CND_XIDLIB="+ _cTBLSLD + "_NUMERO)" 
		cQuery += " WHERE
		cQuery += " CN9.D_E_L_E_T_=' '
		cQuery += " AND CN9_SITUAC='05'
		
		cQuery += If(Empty(::cContrato)	  ,""," AND CN9_NUMERO='" + ::cContrato + "' ")
		cQuery += If(Empty(::cContrato)	  ,""," AND CN9_REVISA='" + ::cRevisa + "' ")
		cQuery += If(Empty(::cFornecedor) ,""," AND CNC_CODIGO='" + ::cFornecedor + "' ")
		cQuery += If(Empty(::cLojaFornec) ,""," AND CNC_LOJA='" + ::cLojaFornec + "' ")
	Else
		cQuery := " SELECT "
		cQuery += " * "
		cQuery += " FROM " + RetSqlName("SA2") + " SA2 "
		cQuery += " WHERE "
		cQuery += " SA2.D_E_L_E_T_=' ' "
		cQuery += " AND " + If(Empty(::cCNPJ)," A2_COD='" + ::cFornecedor + "' AND A2_LOJA='" + ::cLojaFornec + "' "," AND A2_CGC='" + ::cCNPJ + "' " )
	EndIf
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), _cAlias, .F., .F.)
	
	(_cAlias)->(DbGoTop())
	If !(_cAlias)->(Eof())
		aStruct := (_cAlias)->(DbStruct())
		_cContrato := ""
		_cFilial := ""
		_cFornec := ""
		_cLjForn := ""

		While !(_cAlias)->(Eof())
			If (_cAlias)->CN9_NUMERO == _cContrato .And. (_cAlias)->&(_cTBLSLD+"_FILIAL") == _cFilial .And. (_cAlias)->&(_cTBLSLD+"_FORNEC") == _cFornec .And. (_cAlias)->&(_cTBLSLD+"_LJFORN") == _cLjForn
				aAdd( aJSON[Len(aJSON)][#&("'liberacao'")], JSONObject():New() )

				For i:= 1 To Len(aStruct)
					If Upper(Alltrim(aStruct[i][1])) $ GETCAB
//						aJSON[Len(aJSON)][1][#&("'"+aStruct[i][1]+"'")] := If(aStruct[i][2]=="N",cValToChar((_cAlias)->&(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
					Else
						aJSON[Len(aJSON)][2][#&("'"+aStruct[i][1]+"'")] := If(aStruct[i][2]=="N",cValToChar((_cAlias)->&(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
					EndIf
				Next	
			Else
				_cContrato	:= (_cAlias)->CN9_NUMERO
				_cFilial 	:= (_cAlias)->&(_cTBLSLD+"_FILIAL")
				_cFornec	:= (_cAlias)->&(_cTBLSLD+"_FORNEC")
				_cLjForn	:= (_cAlias)->&(_cTBLSLD+"_LJFORN")
				If Len(aJSON) == 0
					aAdd( aJSON, JSONObject():New() )
					aJSON[Len(aJSON)][#&("'contrato'")] := {}
					aJSON[Len(aJSON)][#&("'liberacao'")]:= {}
					aAdd( aJSON[Len(aJSON)][#&("'contrato'")] , JSONObject():New() )
					aAdd( aJSON[Len(aJSON)][#&("'liberacao'")], JSONObject():New() )
				Else
					aJSON[Len(aJSON)][#&("'contrato'")] := {}
					aJSON[Len(aJSON)][#&("'liberacao'")]:= {}
					aAdd( aJSON[Len(aJSON)][#&("'contrato'")] , JSONObject():New() )
					aAdd( aJSON[Len(aJSON)][#&("'liberacao'")], JSONObject():New() )
				EndIf
				For i:= 1 To Len(aStruct)
					If Upper(Alltrim(aStruct[i][1])) $ GETCAB
						aJSON[Len(aJSON)][#&("'contrato'")][#&("'"+aStruct[i][1]+"'")] := If(aStruct[i][2]=="N",cValToChar((_cAlias)->&(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
					Else
						aJSON[Len(aJSON)][#&("'liberacao'")][#&("'"+aStruct[i][1]+"'")] := If(aStruct[i][2]=="N",cValToChar((_cAlias)->&(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
					EndIf
				Next
			EndIf
			
		(_cAlias)->(DbSkip())
		EndDo
		oJSON := JSON():New( aJSON )
		
		::SetResponse(StrTran(oJSON:Stringify(),"\",""))
	Else
		::SetResponse('{"message":"nao foram encontrados informacoes para os dados enviados."}')
	EndIf
	If Select(_cAlias) > 0
		(_cAlias)->(DbCloseArea())
	EndIf
Else
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100: PARAMETRO INVALIDO.")
	SetRestFault(400, "id parameter is mandatory")
EndIf

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSCNTA100 FIM ")
Return .T.
 

WSMETHOD POST WSSERVICE WSCNTA100
Local lPost := .T.
Local cJson
Local oJson	
Local aContrato	:= {}
Local aFornec	:= {}
Local aPlanilha	:= {}
Local aRet := {}

Local _cContrato := ""//GetSXENum("CN9", "CN9_NUMERO")
Local _cRevisa	 := "001"

Local aCodEmp := {}

oJsonParser := tJsonParser():New()

// Exemplo de retorno de erro
If Len(::aURLParms) == 0
	SetRestFault(400, "id parameter is mandatory")
	lPost := .F.
Else
	aCodEmp:=GetCodEmp(::aURLParms[1])

	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSCNTA100 INICIO")
	// define o tipo de retorno do metodo
	::SetContentType("application/json")
	RpcSetType(3)
	//RpcSetEnv("04","04 0001   ")
	RpcSetEnv(aCodEmp[1],aCodEmp[2])
	InitPublic()
	SetsDefault()
	SetModulo('SIGAGCT','GCT')	
	// recupera o body da requisiÁ„o
	cJson := ::GetContent()
	conout('cBody>> '+cJson)
	FWJSONDeserialize(cJson,@oJson)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSCNTA100 DESERIALIZADO")	
	
	If Len(oJson:CONTRATO) > 0
		
		strJson = cJson
		lenStrJson := Len(strJson)
		aJsonfields := {}
		nRetParser := 0
		oJHM := .F.
		lRet := .F.
		
		If(lRet := oJsonParser:Json_Hash(strJson, lenStrJson, @aJsonfields, @nRetParser, @oJHM))
			ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSCNTA100 PARSE REALIZADO")
			
			Begin Transaction 
				aRet := LoadContra(oJson,@aContrato,aJsonFields,@_cContrato,@_cRevisa)
				If aRet[1]
					aRet := LoadPlanil(oJson,@aPlanilha,aJsonFields,_cContrato,_cRevisa,aRet[4]/*lRevisa*/)
					If aRet[1]						
						aRet := LoadFornec(oJson,@aFornec,aJsonFields,_cContrato,_cRevisa,aRet[4])
						If aRet[1]
							aRet := SetAcesso(/*RetCodUsr()*/,_cContrato)
							If aRet[1]
								aRet := SetCronog(_cContrato,_cRevisa)
								If aRet[1]
									UpdSituCto(aContrato)
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
				If !aRet[1]
					DisarmTransaction()
					lPost := aRet[1]
					ConOut("[USER][ERRO][" + DToC(DATE()) + " " + TIME() + "] "+aRet[3])
	   				SetRestFault(400, aRet[3])
				EndIf
			End Transaction     
		Else
			ConOut("[USER][ERRO][" + DToC(DATE()) + " " + TIME() + "] CODIGO 02")
	   		SetRestFault(400, "ERROR 02")
	   		lPost := .F.
		EndIf
	Else
		ConOut("[USER][ERRO][" + DToC(DATE()) + " " + TIME() + "] CODIGO 01")
	   	SetRestFault(400, "ERROR 01")
	EndIf
EndIf

Return lPost

/* 
WSMETHOD PUT WSSERVICE WSCNTA100
Local lPut := .F.
 
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


/*
WSMETHOD DELETE WSSERVICE WSCNTA100
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

Static Function LoadContra(oJson,aContrato,aJsonFields,_cContrato,_cRevisa)
Local nPos := ASCAN(aJsonFields[1][2][1][2],{|x| UPPER(ALLTRIM(x[2][1][1])) == "CONTRATO"}) 	
Local i	:= 0
Local aContrato := {}
Local lRevisa := .F.
Local _cIdExt := ""
Local cMsg := ""
Local lRet := .T.
//aJsonFields[1][2][1][2]['1'][2][1][1]
//aJsonFields[1][2][1][2]['1'][2][2][2]=>ARRAY DE ITENS P/ CONTRATO
//aJsonFields[1][2][1][2]['1'][2][2][2][i][1]=>COLUNA/CAMPO - CONTRATO
ConOut("LOADCONTRATO")
//sleep(3000)
conout("TYPE: " + Type("oJson"))
	//conout("len:" + str(len(oJson)))
	conout("TYPE: " + ValType(oJson))
	//sleep(2000)
SX3->(DbSetOrder(1))

RecLock("CN9",.T.)

For i := 1 To Len(aJsonFields[1][2][1][2][nPos][2][2][2])
	ConOut("LENDO CAMPO: "+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])
	//sleep(3000)
	//If SX3->(DbSeek('CN9')+Alltrim(aJsonFields[1][2][1][2][nPos][2][2][2][i][1]))
		//SLEEP(3000)
		oContrato	:= oJson:CONTRATO[nPos]:CONTRATO
		_cContrato	:= If(Alltrim(aJsonFields[1][2][1][2][nPos][2][2][2][i][1])=="CN9_NUMERO",eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}),_cContrato)
		_cIdExt		:= If(Alltrim(aJsonFields[1][2][1][2][nPos][2][2][2][i][1])=="CN9_XIDEXT",eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}),_cIdExt)
		
		aRevisa		:= GetRevisao(_cContrato,_cIdExt,@lRevisa)
		If aRevisa[1]
			_cRevisa 	:= aRevisa[2]
			
			//ConOut("CARGA DE CONTRATO ")
			//SLEEP(1000)
			ConOut("Conteudo:" + eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}))
			
			//ConOut("CARGA DE CONTRATO 02 ")
			aAdd(aContrato,{aJsonFields[1][2][1][2][nPos][2][2][2][i][1],eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})})
			
			//CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1]) := eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})		
			_cType := GetSX3Type("CN9", aJsonFields[1][2][1][2][nPos][2][2][2][i][1])
			If _cType == "NULL"
			ElseIf _cType == "N"
				CONOUT("N-"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1]+": " + eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}))
				CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1]) := Val(eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}))
				aAdd(aContrato,{aJsonFields[1][2][1][2][nPos][2][2][2][i][1],CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})
			ElseIf _cType == "D"
				CONOUT("D-"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1]+": " + eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}))
				CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1]) := CToD(eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}))
				aAdd(aContrato,{aJsonFields[1][2][1][2][nPos][2][2][2][i][1],CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})
			Else
				CONOUT("O-"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1]+": " + eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])}))
				CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1]) := eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})
				aAdd(aContrato,{aJsonFields[1][2][1][2][nPos][2][2][2][i][1],CN9->&(aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})
			EndIf
			
			/*/SX3->(DbGoTop())
			SX3->(DbSeek('CN9'))
			While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="SA1"
				If !(EMPTY(SX3->X3_OBRIGAT))
					//If (oJson[Len(oJson)]:&(SX3->X3_CAMPO)== Nil) .Or. Empty(oJson[Len(oJson)]:&(SX3->X3_CAMPO))
					//	SetRestFault(400, "id " + SX3->X3_CAMPO + " is mandatory")
					//EndIf
				EndIf 
			SX3->(DbSkip())
			EndDo
			*/
		Else
			lRet := aRevisa[1]
			cMsg := aRevisa[3]
		EndIf
	//EndIf
Next
If Len(aRevisa) > 0
	If aRevisa[1] .And. !Empty(_cRevisa)
		CN9->CN9_FILIAL := xFilial("CN9")
		CN9->CN9_NUMERO := _cContrato
		CN9->CN9_REVISA := _cRevisa
		aAdd(aContrato,{"CN9_NUMERO",CN9->CN9_NUMERO})
		aAdd(aContrato,{"CN9_REVISA",CN9->CN9_REVISA})
		CN9->(MsUnLock())
	EndIf
EndIf
Return {lRet,aContrato,cMsg,lRevisa}

Static Function LoadPlanil(oJson,aPlanilha,aJsonFields,_cContrato,_cRevisa,lRevisa,lVldSX3)
Local lRet := .T.
Local nPos := ASCAN(aJsonFields[1][2][1][2],{|x| UPPER(ALLTRIM(x[2][1][1])) == "PLANILHA"}) 
Local aPlanilha := {}
Local x := 0
Local y := 0
Local z := 0
Local lTotItem := .T.
Local cMsg := ""

DEFAULT lRevisa := .F.

//cPlan := GetSXENum("CNA", "CNA_NUMERO")

//aJsonFields[1][2][1][2]['1'][2][1][2]=>ARRAY DE LISTA DE PLANILHA
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][1]=>POSICAO PARA BUSCA DE "HEADER"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i+1][2]=>ARRAY DE ITENS P/ "HEADER"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i+1][2][j][1]=>COLUNA/CAMPO / "HEADER"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][1]=>POSICAO PARA BUSCA DE "CONTENT"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][2]=>ARRAY DE LISTA DE "CONTENT"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][2][j][2][x][1][2]=>ARRAY DE COLUNAS DE "CONTENT"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][2][j][2][x][1][2][y][1]=>ARRAY DE COLUNAS DE "CONTENT"



//aJsonFields[1][2][1][2]['1'][2][1][1]
//aJsonFields[1][2][1][2]['1'][2][2][2]=>ARRAY DE ITENS P/ CONTRATO
//aJsonFields[1][2][1][2]['1'][2][2][2][i][1]=>COLUNA/CAMPO - CONTRATO
ConOut("LOADPLANILHA")
//sleep(1000)
conout("TYPE: " + Type("oJson"))
//conout("len:" + str(len(oJson)))
conout("TYPE: " + ValType(oJson))
//sleep(2000)

SX3->(DbSetOrder(1))
For x := 1 To Len(aJsonFields[1][2][1][2][nPos][2][1][2])
	cPlan := GetSXENum("CNA", "CNA_NUMERO")
	nPos1Y := ASCAN(aJsonFields[1][2][1][2][nPos][2][1][2][x][2],{|x| UPPER(ALLTRIM(x[1])) == "HEADER"})
	RecLock("CNA",.T.)
	For y := 1 To Len(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2]) 
		If Upper(Alltrim(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])) == "CNA_CNPJ"
			aCNPJ := GetFornec(eVal({|| &("oHeader:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])}))
			If Len(aCNPJ) == 2
				If Empty(aCNPJ[1]) .Or. Empty(aCNPJ[1])
					lRet := .F.
					cMsg := "CNPJ nao existe."	
				Else
					CNA->CNA_FORNEC := aCNPJ[1]
					CNA->CNA_LJFORN := aCNPJ[2]
				EndIf
			Else
				lRet := .F.
				cMsg := "CNPJ nao existe."
			EndIf
		EndIf
		ConOut("LENDO CAMPO: "+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])
		//sleep(3000)
		//If SX3->(DbSeek('CN9')+Alltrim(aJsonFields[1][2][1][2][nPos][2][2][2][i][1]))
			//SLEEP(3000)
			oHeader  := oJson:CONTRATO[nPos]:PLANILHA[x]:HEADER
			
			//ConOut("CARGA DE CONTRATO ")
			//SLEEP(1000)
			ConOut("Conteudo:" + eVal({|| &("oHeader:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])}))
			
			//CNA->&(aJsonFields[1][2][1][2][nPos][2][1][2][1][2][nPos1Y+1][2][y][1]) := eVal({|| &("oHeader:"+aJsonFields[1][2][1][2][nPos][2][1][2][1][2][nPos1Y+1][2][y][1])}))
			_cType := GetSX3Type("CNA", aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])
			If _cType == "NULL"
			ElseIf _cType == "N"
				CNA->&(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1]) := Val(eVal({|| &("oHeader:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])}))
			ElseIf _cType == "D"
				CNA->&(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1]) := CToD(eVal({|| &("oHeader:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])}))
			Else
				CNA->&(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1]) := eVal({|| &("oHeader:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos1Y+1][2][y][1])})
			EndIf
			//ConOut("CARGA DE CONTRATO 02 ")
			//aAdd(aContrato,{aJsonFields[1][2][1][2][nPos][2][2][2][i][1],eVal({|| &("oContrato:"+aJsonFields[1][2][1][2][nPos][2][2][2][i][1])})})
			
			/*/
			If lVldSX3
				SX3->(DbGoTop())
				SX3->(DbSeek('CNA'))
				While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="CNA"
					If !(EMPTY(SX3->X3_OBRIGAT))
						//If (oJson[Len(oJson)]:&(SX3->X3_CAMPO)== Nil) .Or. Empty(oJson[Len(oJson)]:&(SX3->X3_CAMPO))
						//	SetRestFault(400, "id " + SX3->X3_CAMPO + " is mandatory")
						//EndIf
					EndIf 
				SX3->(DbSkip())
				EndDo
			EndIf
			/*/
		//EndIf
	Next
	CNA->CNA_CONTRA := _cContrato
	CNA->CNA_REVISA := _cRevisa
	CNA->CNA_FILIAL := xFilial("CNA")
	CNA->CNA_NUMERO := cPlan
	
	
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][2][j][2][x][1][2]=>ARRAY DE COLUNAS DE "CONTENT"
//aJsonFields[1][2][1][2]['1'][2][1][2][1][2][i][2][j][2][x][1][2][y][1]=>ARRAY DE COLUNAS DE "CONTENT"
	conout("[INFO][USER] WS_CNTA100/LOADPLANIL - LENDO CONTENT PLANILHA")
	
	nPos2Y := ASCAN(aJsonFields[1][2][1][2][nPos][2][1][2][x][2],{|x| UPPER(ALLTRIM(x[1])) == "CONTENT"})
	conout("LENDO CONTENT PLANILHA 001" + valtype(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2])+ STR(LEN(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2])))
	For y := 1 To Len(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2])
		RecLock("CNB",.T.)
		conout("LENDO CONTENT PLANILHA 002 ITEM " + ALLTRIM(STR(y)))
		lTotItem := .T.
	 	For z := 1 To Len(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2])
			ConOut("LENDO CAMPO: "+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1])
				oContent  := oJson:CONTRATO[nPos]:PLANILHA[x]:CONTENT[y]
				
				ConOut("Conteudo:" + eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1])}))
				If(ALLTRIM(UPPER(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1]))=="CNB_VLTOT",lTotItem := .F.,)

				_cType := GetSX3Type("CNB", aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1])
				If _cType == "NULL"
				ElseIf _cType == "N"
					CNB->&(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1]) := Val(eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1])}))
				ElseIf _cType == "D"
					CNB->&(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1]) := CToD(eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1])}))
				Else
					CNB->&(aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1]) := eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][x][2][nPos2Y][2][y][2][z][1])})
				EndIf
				
				/*/
				If lVldSX3
					SX3->(DbGoTop())
					SX3->(DbSeek('CNB'))
					While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="CNB"
						If !(EMPTY(SX3->X3_OBRIGAT))
							If (oJson[Len(oJson)]:&(SX3->X3_CAMPO)== Nil) .Or. Empty(oJson[Len(oJson)]:&(SX3->X3_CAMPO))
								SetRestFault(400, "id " + SX3->X3_CAMPO + " is mandatory")
							EndIf
						EndIf 
					SX3->(DbSkip())
					EndDo
				EndIf
				/*/
			
		Next 
		CNB->CNB_CONTRA := _cContrato
		_cTES := U_PCCalcTes(/*_cFil*/xFilial("CNB"),CNB->CNB_PRODUT/*_cPrd*/,CNA->CNA_FORNEC/*_cFornece*/,CNA->CNA_LJFORN/*_cLoja*/,/*_cMov*/,"C"/*_cTipo*/,/*_cBonif*/)
		CNB->CNB_TE		:= If (Empty(_cTES),SuperGetMv("PZ_TESGCT",.F.,"200"),_cTES)
		CNB->CNB_REVISA := _cRevisa
		CNB->CNB_FILIAL := xFilial("CNB")			
		CNB->CNB_NUMERO := cPlan
		CNB->CNB_ITEM   := StrZero(y,TamSX3("CNB_ITEM")[1]) 
		CNB->CNB_SLDMED := CNB->CNB_QUANT
		CNB->CNB_SLDREC := CNB->CNB_QUANT
		CNB->CNB_DESCRI := If(Empty(CNB->CNB_DESCRI),Posicione("SB1",1,xFilial("SB1")+CNB->CNB_PRODUT,"B1_DESC"),CNB->CNB_DESCRI)

		If lTotItem
			CNB->CNB_VLTOT := Round(CNB->CNB_QUANT*CNB->CNB_VLUNIT,TamSX3("CNB_VLTOT")[2])
		EndIf

	Next
	
	
	CNB->(MsUnLockAll())
	
	_cAlias := GetNextAlias()
	
	BeginSql Alias _cAlias
		SELECT 
		CNB_FILIAL,CNB_CONTRA,CNB_REVISA,CNB_NUMERO,SUM(CNB_VLTOT) CNB_VLTOT   
		FROM %table:CNB% CNB
		WHERE
		CNB.D_E_L_E_T_=' '
		AND CNB_FILIAL=%xfilial:CNA%
		AND CNB_CONTRA=%exp:_cContrato%
		AND CNB_REVISA=%exp:_cRevisa%
		AND CNB_NUMERO=%exp:cPlan%
		GROUP BY 
 		CNB_FILIAL,CNB_CONTRA,CNB_REVISA,CNB_NUMERO

	EndSql
	
	(_cAlias)->(DbGoTop())
	If !(_cAlias)->(Eof())
		ConOut("ATUALIZA TOTAIS DA PLANILHA")
		CNA->CNA_VLTOT:=(_cAlias)->CNB_VLTOT 
		CNA->CNA_SALDO:=(_cAlias)->CNB_VLTOT 
	EndIf
	CNA->(MsUnLock())
	ConfirmSx8()
	conout("termino leitura planilha")
Next

_cAlias := GetNextAlias()

BeginSql Alias _cAlias
	SELECT 
	CNA_FILIAL,CNA_CONTRA,CNA_REVISA,SUM(CNA_VLTOT) CNA_VLTOT   
	FROM %table:CNA% CNA
	WHERE
	CNA.D_E_L_E_T_=' '
	AND CNA_FILIAL=%xfilial:CNA%
	AND CNA_CONTRA=%exp:_cContrato%
	AND CNA_REVISA=%exp:_cRevisa%
	GROUP BY 
	CNA_FILIAL,CNA_CONTRA,CNA_REVISA
EndSql

(_cAlias)->(DbGoTop())
If !(_cAlias)->(Eof())
	If CN9->CN9_FILIAL == (_cAlias)->CNA_FILIAL .And. CN9->CN9_NUMERO == (_cAlias)->CNA_CONTRA .And. CN9->CN9_REVISA == (_cAlias)->CNA_REVISA
		RecLock("CN9",.F.)
			CN9->CN9_VLINI += (_cAlias)->CNA_VLTOT
			CN9->CN9_VLATU += (_cAlias)->CNA_VLTOT
			CN9->CN9_SALDO += (_cAlias)->CNA_VLTOT 
		CN9->(MsUnLock())
	EndIf
EndIf
Return {lRet,aPlanilha,cMsg,lRevisa} 

Static Function LoadFornec(oJson,aFornec,aJsonFields,_cContrato,_cRevisa,lRevisa,lVldSX3)
Local nPos := ASCAN(aJsonFields[1][2][1][2],{|x| UPPER(ALLTRIM(x[2][1][1])) == "FORNECEDOR"})
Local x := 0
Local y := 0
Local z := 0
Local lRet := .T.
Local cMsg := ""

//aJsonFields[1][2][1][2]['1'][2][1][2]=>ARRAY DE LISTA DE FORNECEDORES
//aJsonFields[1][2][1][2]['1'][2][1][2][i][2]=>ARRAY DE ITENS P/ FORNECEDOR
//aJsonFields[1][2][1][2]['1'][2][1][2][i][2][j][1]=>COLUNA/CAMPO FORNECEDOR
conout("[INFO][USER] WS_CNTA100/LOADFORNEC - LEITURA FORNECEDOR")

	For y := 1 To Len(aJsonFields[1][2][1][2][nPos][2][1][2])
		conout("LENDO FORNECEDOR ITEM " + ALLTRIM(STR(y)))
		conout("FORNECEDOR/CONTRATO: "+_cContrato)
		SLEEP(2000)
		RecLock("CNC",.T.)
		CNC->CNC_NUMERO := _cContrato
		CNC->CNC_REVISA := _cRevisa
		CNC->CNC_FILIAL := xFilial("CNC")
	 	For z := 1 To Len(aJsonFields[1][2][1][2][nPos][2][1][2][y][2])
			ConOut("LENDO CAMPO: "+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])
				oContent  := oJson:CONTRATO[nPos]:FORNECEDOR[Y]
				
				ConOut("Conteudo:" + eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])}))
				
				If Upper(Alltrim(aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])) == "CNC_CNPJ"
					aCNPJ := GetFornec(eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])}))
					If Len(aCNPJ) == 2
						If Empty(aCNPJ[1]) .Or. Empty(aCNPJ[1])
							lRet := .F.
							cMsg := "CNPJ nao existe."	
						Else
							CNC->CNC_CODIGO := aCNPJ[1]
							CNC->CNC_LOJA 	:= aCNPJ[2]
						EndIf
					Else
						lRet := .F.
						cMsg := "CNPJ nao existe."
					EndIf
				EndIf
				_cType := GetSX3Type("CNC", aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])
				If _cType == "NULL"
				ElseIf _cType == "C"
					CNC->&(aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1]) := eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])})
				ElseIf _cType == "N"	
					CNC->&(aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1]) := Val(eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])}))
				ElseIf _cType == "D"
					CNC->&(aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1]) := CToD(eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])}))
				Else
					CNC->&(aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1]) := eVal({|| &("oContent:"+aJsonFields[1][2][1][2][nPos][2][1][2][y][2][z][1])})
				EndIf
				
				/*/
				If lVldSX3
					SX3->(DbGoTop())
					SX3->(DbSeek('CNC'))
					While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="CNC"
						If !(EMPTY(SX3->X3_OBRIGAT))
							//If (oJson[Len(oJson)]:&(SX3->X3_CAMPO)== Nil) .Or. Empty(oJson[Len(oJson)]:&(SX3->X3_CAMPO))
							//	SetRestFault(400, "id " + SX3->X3_CAMPO + " is mandatory")
							//EndIf
						EndIf 
					SX3->(DbSkip())
					EndDo
				EndIf
				/*/
				
			
		Next 
		
	Next
	
	CNC->(MsUnLockAll())
	conout("temino leitura FORNECEDOR")
	sleep(3000)
Return {lRet,aFornec,cMsg,lRevisa}


Static Function GetSX3Type(_cAlias,_cColumn)
Local _cType := ""
ConOut("GETSX3TYPE - INICIO: "+ _cAlias + " - " + _cColumn)
SX3->(DbSetOrder(2))

If SX3->(DbSeek(_cColumn))
	ConOut("GETSX3TYPE - SX3- INICIO: "+ SX3->X3_TIPO + " - " + SX3->X3_CAMPO)
	_cType := SX3->X3_TIPO
Else
	_cType := "NULL"
EndIf

ConOut("GETSX3TYPE - FIM")

Return _cType


Static Function SetAcesso(_cCodUser,_cContrato,lRevisa)
Local lRet := .T.
Local cMsg := ""

DEFAULT _cCodUser := SuperGetMv("PZ_USRGCT",.F.,"000000") /*RetCodUsr()*/

CONOUT("SET ACESSO INICIO")

If lRevisa
	If Empty(_cContrato) .Or. _cContrato == Nil
		lRet := .F.
	Else
		RecLock("CNN",.T.)
			CNN->CNN_FILIAL := xFilial("CNN")
			CNN->CNN_CONTRA := _cContrato
			CNN->CNN_USRCOD := _cCodUser
			CNN->CNN_TRACOD := "001"
		CNN->(MsUnLock())
	EndIf
Else
	CONOUT("SETACESSO - CONTRATO EM REVISAO NAO HOUVE ALTERACAO")
EndIf
CONOUT("SETACESSO FIM")
Return {lRet,_cCodUser,cMsg,lRevisa}



Static Function SetCronog(_cContrato,_cRevisa,lRevisa)
Local _cAlias := GetNextAlias()
Local _cCronog := "" 
Local cMsg := ""
Local lRet := .T.

CONOUT("SETCRONFIN - INICIO: " + _cContrato + "/" + _cRevisa)
If !Empty(_cContrato) .And. !Empty(_cRevisa)
	BeginSql Alias _cAlias
		SELECT 
		CNA_FILIAL,CNA_CONTRA,CNA_REVISA,CNA_FORNEC,CNA_LJFORN,CNA_DTINI,CNA_DTFIM,CNA_NUMERO,CNA_CRONOG
		,CN9_DTINIC,CN9_DTFIM,CN9_VENCT,CNB_XDIAVC
		,SUM(CNB_VLTOT) CNB_VLTOT   
		FROM %table:CNA% CNA
		JOIN %table:CNB% CNB 
			ON(CNB.D_E_L_E_T_=' ' 
			AND CNA_FILIAL=CNB_FILIAL
			AND CNA_NUMERO=CNB_NUMERO
			AND CNA_CONTRA=CNB_CONTRA
			AND CNA_REVISA=CNB_REVISA
			)
		JOIN %table:CN9% CN9
			ON(CN9.D_E_L_E_T_=' '
			AND CNA_FILIAL=CN9_FILIAL
			AND CNA_CONTRA=CN9_NUMERO
			AND CNA_REVISA=CN9_REVISA
			)
		WHERE
		CNA.D_E_L_E_T_=' '
		AND CNA_FILIAL=%xfilial:CNA%
		AND CNA_CONTRA=%exp:_cContrato%
		AND CNA_REVISA=%exp:_cRevisa%
		GROUP BY 
 		CNA_FILIAL,CNA_CONTRA,CNA_REVISA,CNA_FORNEC,CNA_LJFORN,CNA_DTINI,CNA_DTFIM,CNA_NUMERO,CNA_CRONOG,CN9_DTINIC,CN9_DTFIM,CN9_VENCT,CNB_XDIAVC

	EndSql
	
	While !(_cAlias)->(Eof())
		_cCronFin := CronogFin((_cAlias)->CNA_DTINI,(_cAlias)->CNA_DTFIM,(_cAlias)->CNA_CONTRA,(_cAlias)->CNA_REVISA,(_cAlias)->CN9_VENCT,(_cAlias)->CNB_VLTOT,(_cAlias)->CNA_NUMERO,lRevisa)
		_cCronCTB := CronogCTB((_cAlias)->CN9_DTINIC,(_cAlias)->CN9_DTFIM,(_cAlias)->CNA_CONTRA,(_cAlias)->CNA_REVISA,(_cAlias)->CNB_VLTOT,(_cAlias)->CNA_NUMERO,lRevisa)		
		
	(_cAlias)->(DbSkip())
	EndDo
EndIf
CONOUT("SETCRONFIN - FIM: " + _cContrato + "/" + _cRevisa)
Return {lRet,,cMsg,lRevisa}

Static Function CronogFin(_cDtIni,_cDtFim,_cContrato,_cRevisa,_cDiaVenc,_nValPlan,_cNumPlan,lRevisa)
Local _cCronog := ""
Local _dData := SToD("")
Local aCronog := {}
Local n := 0
Local nValor := 0
Local nValAjust := 0

DEFAULT _cDiaVenc := "01"

_cCronog := GetSXENum("CNF", "CNF_NUMERO")
_dData := SToD(_cDtIni)

CONOUT("CRONOGFIN - INICIO: " + _cContrato + "/" + _cRevisa+" - "+_cDtIni+" = "+_cDtFim)
While _dData <= SToD(_cDtFim)
	n++
	RecLock("CNF",.T.)
		CNF->CNF_FILIAL := xFilial("CNF")
		CNF->CNF_NUMERO := _cCronog
		CNF->CNF_CONTRA := _cContrato
		CNF->CNF_REVISA := _cRevisa
		CNF->CNF_PARCEL := StrZero(n,TamSX3("CNF_PARCEL")[1])
		CNF->CNF_COMPET := StrZero(Month(_dData),2) + "/" + cValToChar(Year(_dData))
		CNF->CNF_PRUMED := _dData
		CNF->CNF_DTVENC := SToD(cValToChar(Year(_dData))+StrZero(Month(_dData),2)+_cDiaVenc)
		CNF->CNF_TXMOED := 1
		CNF->CNF_PERIOD := "1"
		CNF->CNF_DIAPAR := 30
	
		CronFinItm(_cCronog,_cContrato,_cRevisa,StrZero(n,TamSX3("CNF_PARCEL")[1])/*_cParcela*/,_cNumPlan,lRevisa)
	
	
	_dData := LastDay(_dData)+1
EndDo
CNF->(MsUnLockAll())
ConfirmSx8()
nValor := Round(_nValPlan/n,TamSX3("CNF_VLPREV")[1])

nValAjust := _nValPlan-(nValor*n)


TcSqlExec("UPDATE " + RetSqlName("CNF") + " SET CNF_MAXPAR='" + Alltrim(Str(n)) + "',CNF_VLPREV=" + Alltrim(Str(nValor))  + ",CNF_SALDO="+ Alltrim(Str(nValor)) +;
		 "WHERE D_E_L_E_T_=' ' AND CNF_FILIAL='" + xFilial("CNF") + "' AND CNF_CONTRA='" + _cContrato + "' AND CNF_REVISA='" + _cRevisa + "' AND CNF_NUMERO='" + _cCronog + "'")

TcSqlExec("UPDATE " + RetSqlName("CNA") + " SET CNA_CRONOG='" + _cCronog + "' "+;
		 "WHERE D_E_L_E_T_=' ' AND CNA_FILIAL='" + xFilial("CNF") + "' AND CNA_CONTRA='" + _cContrato + "' AND CNA_REVISA='" + _cRevisa + "' AND CNA_NUMERO='"+ _cNumPlan + "' ")

Return _cCronog

Static Function CronFinItm(_cCronog,_cContrato,_cRevisa,_cParcela,_cNumPlan,lRevisa)
Local _cAlias := GetNextAlias()
Local lRet := .T.
Local cMsg := ""

BeginSql Alias _cAlias
		SELECT 
		CNB_FILIAL,CNB_NUMERO,CNB_ITEM
		FROM %table:CNA% CNA
		JOIN %table:CNB% CNB 
			ON(CNB.D_E_L_E_T_=' ' 
			AND CNA_FILIAL=CNB_FILIAL
			AND CNA_NUMERO=CNB_NUMERO
			AND CNA_CONTRA=CNB_CONTRA
			AND CNA_REVISA=CNB_REVISA
			)
		WHERE
		CNA.D_E_L_E_T_=' '
		AND CNA_FILIAL=%xfilial:CNA%
		AND CNA_CONTRA=%exp:_cContrato%
		AND CNA_REVISA=%exp:_cRevisa%
		AND CNA_NUMERO=%exp:_cNumPlan%
EndSql

(_cAlias)->(DbGoTop())

While !(_cAlias)->(Eof())
	RecLock("CNS",.T.)
		CNS->CNS_FILIAL := xFilial("CNF")
		CNS->CNS_CRONOG := _cCronog
		CNS->CNS_CONTRA := _cContrato
		CNS->CNS_REVISA := _cRevisa
		CNS->CNS_PARCEL := _cParcela
		CNS->CNS_PLANI  := _cNumPlan
		CNS->CNS_ITEM   := (_cAlias)->CNB_ITEM
		CNS->CNS_PRVQTD := 1
		CNS->CNS_SLDQTD := 1

(_cAlias)->(DbSkip())
EndDo
CNS->(MsUnLockAll())

Return 

Static Function CronogCTB(_cDtIni,_cDtFim,_cContrato,_cRevisa,_nValPlan,_cNumPlan,lRevisa)
Local _cCronog := GetSXENum("CNV", "CNV_NUMERO")
Local _dData := SToD("")
Local aCronog := {}
Local n := 0
Local nValor := 0
Local nValAjust := 0

//DEFAULT _cDiaVenc := "01"

_dData := SToD(_cDtIni)

CONOUT("CRONOGCTB - INICIO: " + _cContrato + "/" + _cRevisa+" - "+_cDtIni+" = "+_cDtFim)

RecLock("CNV",.T.)
	CNV->CNV_FILIAL := xFilial("CNV")
	CNV->CNV_CONTRA := _cContrato
	CNV->CNV_REVISA := _cRevisa
	CNV->CNV_NUMERO := _cCronog 
	CNV->CNV_PLANIL := _cNumPlan
	CNV->CNV_TXMOED := 1
	CNV->CNV_CONTA  := ""
	CNV->CNV_PERIOD := "1"
	CNV->CNV_DIAPAR := 30

While _dData <= SToD(_cDtFim)
	n++
	RecLock("CNW",.T.)
		CNW->CNW_FILIAL :=  xFilial("CNW")
		CNW->CNW_CONTRA := _cContrato
		CNW->CNW_REVISA := _cRevisa
		CNW->CNW_NUMERO := _cCronog
		CNW->CNW_PARCEL := StrZero(n,TamSX3("CNW_PARCEL")[1])
		CNW->CNW_COMPET := StrZero(Month(_dData),2) + "/" + cValToChar(Year(_dData))
		CNW->CNW_DTPREV := _dData
		CNW->CNW_HIST   := ""
		CNW->CNW_CC     := ""
		CNW->CNW_ITEMCT := ""
		CNW->CNW_CLVL   := ""
		CNW->CNW_FLGAPR := '2'

	_dData := LastDay(_dData)+1
EndDo
ConfirmSx8()
CNV->(MsUnLockAll())
CNW->(MsUnLockAll())

nValor := Round(_nValPlan/n,TamSX3("CNW_VLPREV")[1])

nValAjust := _nValPlan-(nValor*n)

TcSqlExec("UPDATE " + RetSqlName("CNW") + " SET CNW_VLPREV=" + cValToChar(nValor) +;
		 "WHERE D_E_L_E_T_=' ' AND CNW_FILIAL='" + xFilial("CNW") + "' AND CNW_CONTRA='" + _cContrato + "' "+;
		 " AND CNW_REVISA='" + _cRevisa + "' AND CNW_NUMERO='" + _cCronog + "' ")

Return _cCronog


Static Function GetFornec(_cCNPJ)
Local _cAlias	:= GetNextAlias()
Local _cCodigo	:= ""
Local _cLoja	:= ""

DEFAULT _cCNPJ := ""
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] WSCNTA100 - GETFORNEC -  INICIO")
BeginSql Alias _cAlias
		SELECT 
		A2_COD,A2_LOJA
		FROM %table:SA2% SA2
		WHERE
		SA2.D_E_L_E_T_=' '
		AND A2_CGC=%exp:_cCNPJ%
EndSql

(_cAlias)->(DbGoTop())

If (_cAlias)->(!Eof())
	_cCodigo:= (_cAlias)->A2_COD
	_cLoja	:= (_cAlias)->A2_LOJA
EndIF

(_cAlias)->(DbCloseArea())
ConOut("_cCodigo: " + _cCodigo)
ConOut("_cLoja: " + _cLoja)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] WSCNTA100 - GETFORNEC -  FIM")

Return {_cCodigo,_cLoja}



Static Function GetRevisao(_cContrato,_cIdExt)
Local _cRevisa := ""
Local _cAlias := GetNextAlias()
Local lRet := .T.
Local lRevisa := .F.
Local cMsg := ""

DEFAULT _cContrato	:= ""
DEFAULT _cIdExt		:= ""

conout("_cContrato: " + _cContrato)
conout("_cIdExt: " + _cIdExt)

If !Empty(_cContrato) .And. !Empty(_cIdExt)
	BeginSql Alias _cAlias
			SELECT 
			CN9_NUMERO,
			MAX(CN9_REVISA) CN9_REVISA
			FROM %table:CN9% CN9
			WHERE
			CN9.D_E_L_E_T_=' '
			AND CN9_XIDEXT=%exp:_cIdExt%
			GROUP BY 
			CN9_NUMERO
	EndSql

	(_cAlias)->(DbGoTop())
	If (_cAlias)->(!Eof())
		conout("CN9_NUMERO: " + (_cAlias)->CN9_NUMERO)
		conout("CN9_REVISA: " + (_cAlias)->CN9_REVISA)
		
		If Alltrim((_cAlias)->CN9_NUMERO) == Alltrim(_cContrato)
			_cRevisa := Soma1((_cAlias)->CN9_REVISA)
			lRevisa := .T.
		ElseIf Empty((_cAlias)->CN9_NUMERO)
			_cRevisa := "001"	
		Else
			lRet := .F.
			cMsg := "CN9_NUMERO diferente para CN9_XIDEXT"
		EndIf
	Else
		_cRevisa := "001"
	EndIf
Else
	_cRevisa := "001"
EndIf

Return {lRet,_cRevisa,cMsg,lRevisa}


Static Function UpdSituCto(aContrato)
Local cUpdate := ""

cUpdate := " UPDATE " + RetSqlName("CN9")  
cUpdate += " SET CN9_SITUAC='10' "
cUpdate += " WHERE "
cUpdate += " D_E_L_E_T_=' ' "
cUpdate += " AND CN9_NUMERO='" + PadR(aContrato[aScan(aContrato,{|x| Upper(Alltrim(x[1]))=="CN9_NUMERO"})][2],TamSX3("CN9_NUMERO")[1]) + "' "
cUpdate += " AND CN9_REVISA<'" + PadR(aContrato[aScan(aContrato,{|x| Upper(Alltrim(x[1]))=="CN9_REVISA"})][2],TamSX3("CN9_REVISA")[1]) + "' "

conout("AJUSTA SITUACAO DO CONTRATO:" + CRLF + cUpdate)

Return (TcSqlExec(cUpdate) == 0)


Static Function GetCodEmp(cCNPJ)
Local aRet := Array(2)
OpenSM0()
SM0->(DbSetOrder(1))
SM0->(DbGoTop())
conout('--PROCURA EMP >>>'+cCNPJ)
While SM0->(!EoF()) 
conout('--PROCURA EMP-->> '+SM0->M0_CGC)
	if (SM0->M0_CGC==cCNPJ .And. SubStr(SM0->M0_CODFIL,1,2) == "04") .Or. Empty(cCnpj)
	conout('!---achou--- '+cCnpj+' - '+SM0->M0_CODIGO+'/'+SM0->M0_CODFIL)
		aRet[1] := SM0->M0_CODIGO
		aRet[2] := SM0->M0_CODFIL
		Exit
 	EndIf
SM0->(DbSkip())
EndDo
Return aRet