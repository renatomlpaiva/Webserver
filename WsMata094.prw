#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
 
WSRESTFUL WSMATA094 DESCRIPTION "Web service para tratativade pedidos de compras"

WSDATA cAprovador	AS STRING
WSDATA cPedido 		AS STRING
WSDATA cTipo 		AS STRING
WSDATA cEmpWeb 		AS STRING
WSDATA cFilWeb 		AS STRING

WSMETHOD GET	DESCRIPTION "Retorna pedido de compra" WSSYNTAX "/WSMATA094 "
WSMETHOD POST	DESCRIPTION "Atualiza/Aprova pedido de compra" WSSYNTAX "/WSMATA094"
 
END WSRESTFUL
 
WSMETHOD GET WSRECEIVE cAprovador,cPedido,cTipo,cEmpWeb,cFilWeb  WSSERVICE WSMATA094
Local i			:= 0
Local cRet		:= ""
Local cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local aStruct	:= {}
Local aJSON		:= {}
Local oJSON		:= Nil
Local aCR_Status:= {}
Local _nI		:= 0
Local _nPosSatus:= 0
Local cCodUser	:= RetCodUsr()
Local cEmpBkp	:= ""
Local cFilBkp	:= ""

Local _cFilProc	:= ""
Local _cPedido	:= ""
Local _citem	:= ""
Local _cFornec	:= ""
Local _cLoja	:= ""
Local _lPrcSoma := .F.

Local _cStatus 	:= ""
Local _nZ		:= 0

Local _cEmpPrc	:= "|03|10|"
Local _lProcess	:= .T.
Local _lPrcLoop	:= .T.
Local _nPosCol	:= 0

DEFAULT ::cAprovador:= ""
DEFAULT ::cPedido	:= ""
DEFAULT ::cTipo		:= ""
DEFAULT ::cEmpWeb	:= "01"
DEFAULT ::cFilWeb	:= "01"

// Controle de Aprovacao : CR_STATUS                
aAdd(aCR_Status, {"01","Bloqueado p/ sistema (aguardando outros niveis)"})
aAdd(aCR_Status, {"02","Aguardando Liberacao do usuario"})                 
aAdd(aCR_Status, {"03","Pedido Liberado pelo usuario"})                    
aAdd(aCR_Status, {"04","Pedido Bloqueado pelo usuario"})                   
aAdd(aCR_Status, {"05","Pedido Liberado por outro usuario"})               
aAdd(aCR_Status, {"06","Documento Rejeitado"})

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 INICIO")
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 - EMPWEB: " + ::cEmpWeb)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 - FILWEB: " + ::cFilWeb)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 - CTIPO: " + ::cTipo)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 - PEDIDO: " + ::cPedido)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 - APROVADOR:" + ::cAprovador)

// define o tipo de retorno do metodo
::SetContentType("application/json")

	

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 COD:"+::cFornecedor)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 LOJA:"+::cLojaFornec)
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 CNPJ:"+::cCNPJ)


aEmpresas := FWLoadSM0()

cEmpBkp := cEmpAnt
cFilBkp := cFilAnt
If aScan(aEmpresas,{|x| (x[1] == ::cEmpWeb .And. x[2] == ::cFilWeb)}) > 0 
	For _nZ := 1 To Len(aEmpresas)
		_lProcess := .T.
		
		cEmpAnt := aEmpresas[_nZ][1]
		cFilAnt := aEmpresas[_nZ][2]
		If Empty(::cTipo) .Or. ::cTipo $ "|2|3|6|"
			IF Empty(_cEmpPrc)
				_cEmpPrc := aEmpresas[_nZ][1]
			ElseIf !(aEmpresas[_nZ][1] $ _cEmpPrc)
				ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 FECHA EMP")		
				DbCloseAll()
				FWClearXFilialCache()
				OpenSM0(cEmpAnt+cFilAnt, .F.) //Abrir Tabela SM0 (Empresa/Filial)
				OpenSxs(,,,,cEmpAnt)
				ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 ABRE EMP "+cEmpAnt)		
				
				_cEmpPrc += "|" + aEmpresas[_nZ][1]
			Else
				_lProcess := .F.
				_lPrcLoop := .T.
			  ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC EMP LOOP:"+ aEmpresas[_nZ][1])		
			EndIf
		ElseIF !(cEmpAnt == ::cEmpWeb .And. cFilAnt == ::cFilWeb)
			_lPrcLoop := .F.
			ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC AJUST EMP")		
			cEmpAnt := ::cEmpWeb
			cFilAnt := ::cFilWeb
			
			DbCloseAll()
			FWClearXFilialCache()
			OpenSM0(cEmpAnt+cFilAnt, .F.) //Abrir Tabela SM0 (Empresa/Filial)
			OpenSxs(,,,,cEmpAnt)
			ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 ABRE EMP "+cEmpAnt)		
			
			If(cFilAnt == ::cFilWeb,,cFilAnt := ::cFilWeb)
			
		EndIf
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC EMP:"+ aEmpresas[_nZ][1])
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC EMP:"+ aEmpresas[_nZ][2])
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC EMP:"+ aEmpresas[_nZ][5])
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC EMP:"+ aEmpresas[_nZ][6])
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 PROC EMP:"+ aEmpresas[_nZ][7])
		
		IF _lProcess .And. !(cEmpAnt == ::cEmpWeb .And. cFilAnt == ::cFilWeb) .And. ::cTipo == "A"
			DbCloseAll()
			cEmpAnt := ::cEmpWeb
			cFilAnt := ::cFilWeb
			OpenSM0(::cEmpWeb+::cFilWeb, .F.) //Abrir Tabela SM0 (Empresa/Filial)
			If(cFilAnt == ::cFilWeb,,cFilAnt := ::cFilWeb)
			ConOut("cEmpAnt ==>00> " + cEmpAnt)
			ConOut("cFilAnt ==>00> " + cFilAnt)
		EndIf
		If _lProcess
			If ::cTipo == "A"
				cQuery := CRLF + " SELECT DISTINCT ACB.* "
				cQuery += ",'" + cEmpAnt + "' EMPRESA "
				cQuery += CRLF + " FROM " + RetSqlName("SC7") + " SC7 "
				cQuery += CRLF + " JOIN " + RetSqlName("AC9") + " AC9 ON(AC9.D_E_L_E_T_='' AND AC9_FILIAL='' AND AC9_ENTIDA='SC7' AND C7_FILENT=AC9_FILENT AND AC9_CODENT = "+SC7->(IndexKey(1))+") "
				cQuery += CRLF + " JOIN " + RetSqlName("ACB") + " ACB ON(ACB.D_E_L_E_T_='' AND ACB_FILIAL='' AND AC9_CODOBJ=ACB_CODOBJ) "
				cQuery += CRLF + " WHERE "
				cQuery += CRLF + " SC7.D_E_L_E_T_='' "
				cQuery += CRLF + " AND SC7.R_E_C_N_O_=" + ::cPedido
				conout("cEmpAnt >01>"+cEmpAnt)
				conout("cFilAnt >01>"+cFilAnt)
				CONOUT(cQuery)
			Else

				_cStatus := PadL(::cTipo,2,"0")
				
				cQuery := ""
				If Empty(::cTipo)
					cQuery += " SELECT "
					cQuery += " CR_STATUS, COUNT(*) COUNT "
					cQuery += " FROM ( "
				EndIf
				cQuery += " SELECT DISTINCT "
				cQuery += If(Empty(::cPedido) .Or. Empty(::cTipo)," CR_STATUS "," SCR.*")
				cQuery += ", '" + cEmpAnt + "' EMPRESA "
				ConOut("_nPosCol ==>> " + cValToChar(_nPosCol))
				cQuery += If(Empty(::cTipo),",C7_ENCER,C7_CONAPRO,C7_NUM",", C7_FILIAL,C7_NUM,C7_ITEM,C7_FORNECE,C7_LOJA,C7_TOTAL,C7_EMISSAO,C7_DATPRF,C7_COND,A2_NREDUZ,SC7.R_E_C_N_O_ id ")
				cQuery += " FROM " + RetSqlName("SCR") + " SCR "
				cQuery += " JOIN " + RetSqlName("SC7") + " SC7 ON(SC7.D_E_L_E_T_='' AND C7_FILIAL=CR_FILIAL AND C7_NUM=CR_NUM "
				cQuery += If(_cStatus == "02", " AND C7_CONAPRO='B' AND C7_ENCER<>'E' ","")
				cQuery += " ) "
				cQuery += " JOIN " + RetSqlName("SA2") + " SA2 ON(SA2.D_E_L_E_T_='' AND A2_COD=C7_FORNECE AND A2_LOJA=C7_LOJA) "
				cQuery += " WHERE "
				cQuery += " SCR.D_E_L_E_T_='' "
				cQuery += " AND CR_TIPO='PC' "
				cQuery += " AND CR_EMISSAO>'20230101'"
				cQuery += " AND (CR_STATUS='02' AND C7_ENCER<>'E' AND C7_CONAPRO='B' "
				cQuery += " 	OR CR_STATUS<>'02') "
				cQuery += If((aScan(aCR_Status,{|x| x[1] == _cStatus}))>0 .And. !(::cTipo == "9"),if(::cTipo $ "3|5"," AND CR_STATUS IN('03','05') ",if(::cTipo $ "6|7"," AND CR_STATUS IN('06','07') "," AND CR_STATUS = '" + _cStatus + "' ")),"")
				cQuery += If(::cTipo == "9", "", " AND CR_USER='" + cCodUser + "' ")
				cQuery += If(Empty(::cPedido),""," AND SC7.R_E_C_N_O_=" + ::cPedido +  " ")
				If Empty(::cTipo)
					cQuery += " ) AS TMP "
					cQuery += " GROUP BY "
					cQuery += " CR_STATUS "
				Else
					cQuery += " ORDER BY "
					cQuery += " C7_FILIAL,C7_NUM,C7_FORNECE,C7_LOJA,C7_ITEM,C7_TOTAL,C7_EMISSAO,C7_DATPRF,C7_COND,A2_NREDUZ, CR_STATUS,SC7.R_E_C_N_O_ "
				EndIf
				conout("cEmpAnt >02>"+cEmpAnt)
				conout("cFilAnt >02>"+cFilAnt)
				conout(cQuery)
			EndIf
			dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), _cAlias, .F., .F.)
			
			If Empty(::cTipo) .And. Len(aJson) < Len(aCR_Status)
				_nPosSatus := 0
				For _nI := 1 To Len(aCR_Status)
					If (_nPosStatus := aScan(aJson,{|x| x['CR_STATUS']==aCR_Status[_nI][1]})) == 0
						aAdd( aJSON, JSONObject():New() )
						aJSON[Len(aJSON)]["CR_STATUS"] := aCR_Status[_nI][1]
						aJSON[Len(aJSON)]["COUNT"] := "0"
					EndIf
				Next
			EndIf
			
			(_cAlias)->(DbGoTop())
			If !(_cAlias)->(Eof()) 
				aStruct := (_cAlias)->(DbStruct())
				
				While (_cAlias)->(!Eof()) 
				
					If !Empty(::cTipo) .And. !(::cTipo == "9") .And. !(::cTipo == "A")
						If (_cFilProc	== (_cAlias)->C7_FILIAL  .And.;
							_cPedido	== (_cAlias)->C7_NUM	 .And.;
							_citem		== (_cAlias)->C7_ITEM	 .And.;
							_cFornec	== (_cAlias)->C7_FORNECE .And.;
							_cLoja		== (_cAlias)->C7_LOJA)
							
							_lPrcSoma	:= .F.
							_lLoop		:= .F.
				
						ElseIf (_cFilProc	== (_cAlias)->C7_FILIAL  .And.;
								_cPedido	== (_cAlias)->C7_NUM	 .And.;
								_citem		!= (_cAlias)->C7_ITEM	 .And.;
								_cFornec	== (_cAlias)->C7_FORNECE .And.;
								_cLoja		== (_cAlias)->C7_LOJA) 
						
							_lPrcSoma	:= .T.
							_lLoop		:= .F.
						Else
							_lPrcSoma	:= .F.
							_lLoop		:= .T.
							aAdd( aJSON, JSONObject():New() )
						EndIf
					Else
						_lPrcSoma	:= .F.
						_lLoop		:= .T.
						_lPrcLoop	:= IF(Empty(::cTipo),_lPrcLoop,.F.)
						If Len(aJSON) == 0 
							aAdd( aJSON, JSONObject():New() )
							
						ElseIf !Empty(::cTipo) .And. Len(aJSON[Len(aJSON)]['EMPRESA']) > 0
							aAdd( aJSON, JSONObject():New() )
							
						EndIf
					EndIf
					
					If _lPrcSoma
						aJSON[Len(aJSON)][ "C7_TOTAL" ] := Transform(Val(aJSON[Len(aJSON)][ "C7_TOTAL" ]) + (_cAlias)->C7_TOTAL,X3Picture("C7_TOTAL"))
					ElseIf _lLoop
						_nPosCol := 0
				
        		For i:= 1 To Len(aStruct)
							If _nPosCol == 0
								_nPosJSON := Len(aJSON)
							Else
								_nPosJSON := _nPosCol
							EndIf
							If Alltrim(aStruct[i][1]) == "CR_USER"
								aJSON[_nPosJSON][ aStruct[i][1] ] := /*Alltrim((_cAlias)->&(aStruct[i][1]))+"-"+*/Alltrim(UsrFullName((_cAlias)->&(aStruct[i][1])))
								
							ElseIf Alltrim(aStruct[i][1]) == "CR_STATUS"
							
								If Empty(::cTipo)
							
									If (_nPosCol := aScan(aJSON,{|x| x["CR_STATUS"] == Alltrim((_cAlias)->&(aStruct[i][1]))}) ) == 0
							
										aJSON[_nPosJSON][ aStruct[i][1] ] := Alltrim((_cAlias)->&(aStruct[i][1]))
									EndIf
								Else
									aJSON[_nPosJSON][ aStruct[i][1] ] := /*Alltrim((_cAlias)->&(aStruct[i][1]))+"-"*/+ If((_nPos := aScan(aCR_Status,{|x| x[1]==Alltrim((_cAlias)->&(aStruct[i][1]))}))>0,Alltrim(aCR_Status[_nPos][2]),"")
								EndIf
							
							ElseIf Alltrim(aStruct[i][1]) == "COUNT" .And. _nPosCol > 0
							  aJSON[_nPosJSON][ aStruct[i][1] ] := Transform( Val(aJSON[_nPosJSON][aStruct[i][1]]) + (_cAlias)->&(aStruct[i][1]),X3Picture(aStruct[i][1]))
								
							ElseIf Alltrim(aStruct[i][1]) $ "|C7_EMISSAO|C7_DATPRF|"
								aJSON[_nPosJSON][ aStruct[i][1] ] := /*Alltrim((_cAlias)->&(aStruct[i][1]))+"-"*/ DToC(SToD((_cAlias)->&(aStruct[i][1]))) 
								
	 						ElseIf Alltrim(aStruct[i][1]) == "C7_FILIAL"
								aJSON[_nPosJSON][ aStruct[i][1] ] := Alltrim((_cAlias)->&(aStruct[i][1])) + " - "+ Alltrim(FWFilialName(,(_cAlias)->&(aStruct[i][1])))
						
							ElseIf Alltrim(aStruct[i][1]) == "ACB_OBJETO"
								aJSON[_nPosJSON][ aStruct[i][1] ] := Alltrim((_cAlias)->&(aStruct[i][1])) 
								aJSON[_nPosJSON][ 'URL' ] := "http://192.168.6.8:8052/co" + cEmpAnt +"/shared/"+Alltrim((_cAlias)->&(aStruct[i][1])) 
							Else
								aJSON[_nPosJSON][ aStruct[i][1] ] := If(aStruct[i][2]=="N",Transform((_cAlias)->&(aStruct[i][1]),X3Picture(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
							EndIf
							
						Next
						
					EndIf

					_lPrcSoma	:= .F.
					_lLoop		:= .T.

					If Empty(::cTipo) .Or. ::cTipo == "A"
					Else
						_cFilProc	:= (_cAlias)->C7_FILIAL
						_cPedido	:= (_cAlias)->C7_NUM
						_citem		:= (_cAlias)->C7_ITEM
						_cFornec	:= (_cAlias)->C7_FORNECE
						_cLoja		:= (_cAlias)->C7_LOJA
					EndIf
				(_cAlias)->(DbSkip())
				EndDo
				
			ElseIf Len(aJSON) == 0
				ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 Dados 01: nenhum dado retornado.")	
				aJSON := {}
				aAdd( aJSON, JSONObject():New() )
				aJSON[Len(aJSON)]["CONTENT"] := "WSMATA094 Dados: nenhum dado retornado"
			EndIf
			If Select(_cAlias) > 0
				(_cAlias)->(DbCloseArea())
			EndIf
		EndIf
		If !_lPrcLoop 
			Exit
		EndIf
	Next
Else
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 Dados 02: nenhum dado retornado.")	
	aJSON := {}
	aAdd( aJSON, JSONObject():New() )
	aJSON[Len(aJSON)]["CONTENT"] := "WSMATA094 Dados: nenhum dado retornado."
EndIf
oJSON := JsonObject():New()
oJSON:Set(aJson)

::SetResponse(oJSON:ToJSON())

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA094 FIM ")
cEmpAnt	:= cEmpBkp
cFilAnt := cFilBkp

Return .T.
 
WSMETHOD POST WSSERVICE WSMATA094
Local lPost 	:= .T.
Local cJson 	:= ""
Local oJson		:= JsonObject():New()
Local aContrato	:= {}
Local aFornec	:= {}
Local aPlanilha	:= {}
Local aCodEmp 	:= {}
Local nRecno 	:= 0
Local cAprova	:= ""
Local cObserv	:= ""
Local cCodUser	:= RetCodUsr()
Local aUser 	:= PswRet()

oJsonParser := tJsonParser():New()

	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 INICIO")
	// define o tipo de retorno do metodo
	::SetContentType("application/json")
	cUrlParam := Left(Alltrim(::aURLParms[1]),4)
	ConOut("cUrlParam==>>"+cUrlParam)
	If Len(cUrlParam)==4
		aCodEmp := {SubStr(cUrlParam,1,2),SubStr(cUrlParam,3,2)}
	EndIf
	conout("__cUserId=> "+__cUserId)
	If Len(aCodEmp) == 2 //.And. cEmpAnt == aCodEmp[1] .And. cFilAnt == aCodEmp[2]
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 1")
		RpcClearEnv()
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 2")
		DbCloseAll()
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 3")
		FWClearXFilialCache()
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 4")
		OpenSM0(aCodEmp[1]+aCodEmp[2], .F.) //Abrir Tabela SM0 (Empresa/Filial)
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 5")
		OpenSxs(,,,,aCodEmp[1])
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 6")
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP "+cEmpAnt)
		//RpcSetType(3)
		RpcSetEnv(aCodEmp[1],aCodEmp[2],"Administrador","CblP@ssw0rd135790")
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 7")
		InitPublic()
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 8")
		SetsDefault()
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 9")
		SetModulo('SIGACOM','COM')
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 ABRE EMP 10")
		
		// recupera o body da requisiÃ�â€žo
		cJson := ::GetContent()	
		conout('cBody>> '+cJson)
		//FWJSONDeserialize(cJson,@oJson)
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 DESERIALIZADO")	
		conout(cJson)
		tRet := oJson:FromJson(Alltrim(cJson))
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSPORTARIA DESERIALIZADO")	
		aColumns := oJson:GetNames()
		lPrc := .T.
		If Len(aColumns) > 0 .And. !(ValType(tRet) == "C") .And. lPrc
			aEval(aColumns,{|x| conout(x)})
			If (nPos := aScan(aColumns,{|x| Upper(Alltrim(x))=="RECNO"}))>0
				nRecno := Val(oJson[aColumns[nPos]])
			EndIf
			If (nPos := aScan(aColumns,{|x| Upper(Alltrim(x))=="APROVACAO"}))>0
				cAprova:= oJson[aColumns[nPos]]
			EndIf
			If (nPos := aScan(aColumns,{|x| Upper(Alltrim(x))=="OBSERVACAO"}))>0
				cObserv:= oJson[aColumns[nPos]]
			EndIf
			
      If nRecno > 0 .Or. !Empty(cAprova)
					ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 PARSE REALIZADO")
					If cAprova == "A"
						ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 APROVACAO PC")
					ElseIf cAprova == "R"
						ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 REJEICAO PC")
					EndIf
					
						aRet := AprovPC(nRecno,cAprova,cObserv,aUser)
						If Len(aRet) > 0
							ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 WF REALIZADO VLD RETORNO")
							If (lPost := aRet[1])
								cMsg  := aRet[2]
								ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 WF REALIZADO RETORNO: " + cMsg)
								::SetResponse(cJson+cMsg)
							Else
								cMsg  := aRet[2]
								ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 WF REALIZADO RETORNO: " + cMsg)
								SetRestFault(400, cMsg)			
							EndIf
						EndIf
				
			Else
				ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] ERRO 01")   
				SetRestFault(400, "ERROR 01")
			EndIf
		EndIf
	EndIf

Return lPost
 
Static Function LoadPC(oJson,aJsonFields)
Local lRet      := .F.
Local cMsg      := ""
Local cChaveXML := ""
Local aHeader   := {}
Local aContent  := {}
Local nPos      := 0
Local aRet		:= {.F.,"000-PROCESSAMENTO NAO REALIZADO."}
If (nPos := aScan(aJsonFields[1][2][2][2],{|x| Upper(Alltrim(x[1]))=="CHAVE_XML"})) > 0
    ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 LOAD CHAVE XML")
    cChaveXML := oJson:PEDIDO:CHAVE_XML
EndIf

If (nPos := aScan(aJsonFields[1][2][2][2],{|x| Upper(Alltrim(x[1]))=="HEADER"})) > 0
    ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 LOAD HEADER")
    aHeader := aJsonfields[1][2][2][2][nPos+1][2]
EndIf

If (nPos := aScan(aJsonFields[1][2][2][2],{|x| Upper(Alltrim(x[1]))=="CONTENT"})) > 0
    ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 LOAD CONTENT")
    aContent := aJsonfields[1][2][2][2][nPos][2]
EndIf

If Empty(cChaveXML)
    aRet := IncluiPC(aHeader,aContent)
Else
	aRet := U_PCGCTXML(cChaveXML,/*xEmp*/,/*xFil*/)
EndIf

Return aRet


Static Function IncluiPC(aHeader,aContent,nTipo)
Local lRet := .T.
Local cMsg := ""
Local aCab      := {}
Local aItens    := {}
Local aLinha    := {}
Local nPos      := 0
Local id        := 0
Local cDoc      := GetSXENum("SC7", "C7_NUM")
Local cLogFolder1 := "\log_ws"
Local cLogFolder2 := "\rest_mata121"
Local cLogFile:= "\WSMATA094_" + DToS(date()) + StrTran(Time(),":",".") +".LOG" 
Local aErros    := {}
Local i         := 0
Local nX        := 0

PRIVATE lMsErroAuto := .F.
// variÂ·vel que define que o help deve ser gravado no arquivo de log e que as informaÃ�Ä±es estâ€žo vindo â€¡ partir da rotina automÂ·tica.
Private lMsHelpAuto	:= .T.    
// forÃ�a a gravaÃ�â€žo das informaÃ�Ä±es de erro em array para manipulaÃ�â€žo da gravaÃ�â€žo ao invÃˆs de gravar direto no arquivo temporÂ·rio 
Private lAutoErrNoFile := .T. 

DEFAULT nTipo := 1

If nTipo == 1
	aEval(aContent,{|x| aAdd(aItens,{})})
	i:=0
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 VALIDA DADOS PC")
	SX3->(DbSetOrder(1))
	SX3->(DbGoTop())
	SX3->(DbSeek('SC7'))
	While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="SC7"
		If (nPos := aScan(aHeader,{|x| Upper(Alltrim(x[1]))==Upper(Alltrim(SX3->X3_CAMPO))}))>0
			aAdd(aCab,{aHeader[nPos][1],aHeader[nPos][2],Nil})
		EndIf
		
		For nX := 1 To Len(aItens)
			If (nPos := aScan(aContent[nX][2],{|x| Upper(Alltrim(x[1]))==Upper(Alltrim(SX3->X3_CAMPO))}))>0
				aAdd(aItens[nX],{aContent[nX][2][nPos][1],aContent[nX][2][nPos][2],Nil})
			EndIf
		Next
		/*If !(EMPTY(SX3->X3_OBRIGAT))
			//If (oJson[Len(oJson)]:&(SX3->X3_CAMPO)== Nil) .Or. Empty(oJson[Len(oJson)]:&(SX3->X3_CAMPO))
				//	SetRestFault(400, "id " + SX3->X3_CAMPO + " is mandatory")
			//EndIf
		EndIf*/ 
	SX3->(DbSkip())
	EndDo
ElseIf nTipo == 2
	aCab	:= aHeader
	aItens	:= aContent
EndIf

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA094 INICIO EXECAUTO")

If Len(aCab) > 0 .And. Len(aItens) > 0
    aAdd(aCab,{"C7_NUM",cDoc,Nil})
	aEval(aCab,{|x| Conout("aCab - "+x[1])})
	aEval(aItens,{|x| aEval(x,{|y| Conout("aItens - "+y[1])})})
    MATA120(1,aCab,aItens,3)
    If lMsErroAuto
		lRet := .F.
        ConOut("Erro na inclusao!")
        RollbackSx8()
        AutoGrLog(SM0->M0_CODIGO+"/"+SM0->M0_CODFIL+ " - Pedido: "+Alltrim(cDoc))
    	AutoGrLog(Replicate("-", 20))
        //Verifica se ja existe pasta para geracao de arquivo de log.
        If !(ExistDir(cLogFolder1))
            If(MakeDir(cLogFolder1)==0,conout('pasta criada com sucesso'),conout('nao foi possivel criar a pasta'+cValToChar(FError())))
        EndIf		
        If !(ExistDir(cLogFolder1+cLogFolder2))
            If(MakeDir(cLogFolder1+cLogFolder2)==0,conout('pasta criada com sucesso'),conout('nao foi possivel criar a pasta'+cValToChar(FError())))
        EndIf
        cLogFile := cLogFolder1 + cLogFolder2 + cLogFile		
        
        //funÃ�â€žo que retorna as informaÃ�Ä±es de erro ocorridos durante o processo da rotina automÂ·tica		
        aLog := GetAutoGRLog()	                                 				
        //efetua o tratamento para validar se o arquivo de log jÂ· existe		
        If !File(cLogFile)		
            If (nHandle := MSFCreate(cLogFile,0)) <> -1
                lRet := .T.			
            EndIf		
        Else
            If (nHandle := FOpen(cLogFile,2)) <> -1
                FSeek(nHandle,0,2)				
                lRet := .T.			
            EndIf		
        EndIf		
        If	lRet
            conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO MATA121 PEDIDO: '+cDoc+' - consulte arquivo de log.')                                                                                     			
            //grava as informaÃ�Ä±es de log no arquivo especificado			
            For nX := 1 To Len(aLog)				
                FWrite(nHandle,aLog[nX]+CRLF)
                aAdd(aErros,{"ExecAuto",aLog[nX]})
                conout(StrZero(nX,2)+' | '+aLog[nX])
            Next nX
            FWrite(nHandle,Replicate("-", 20)+CRLF)
            aeVAL(aCab,{|x| conout(x[1]+' >> '+ If(valtype(x[2])=="C",x[2],;
                                            If(valtype(x[2])=="N",alltrim(str(x[2])),;
                                            If(valtype(x[2])=="D",dToS(x[2]),;
                                                                x[2]))))})
            FWrite(nHandle,Replicate("-", 20)+CRLF)
            
            aeVAL(aItens,{|x| aeval(x,{|y| conout(y[1]+' >> '+ If(valtype(y[2])=="C",y[2],;
                                            If(valtype(y[2])=="N",alltrim(str(y[2])),;
                                            If(valtype(y[2])=="D",dToS(y[2]),;
                                                                y[2]))))})})
            FWrite(nHandle,Replicate("-", 20))							
            FClose(nHandle)
        Else
            conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO MATA410 PEDIDO: '+cDoc)
            For nX := 1 To Len(aLog)				
                aAdd(aErros,{"ExecAuto",aLog[nX]})
                conout(StrZero(nX,2)+' | '+aLog[nX])			
            Next nX		
        EndIf	

    Else
        ConOut("Incluido com sucesso! "+cDoc) 
        SC7->(ConfirmSx8())
		SC7->(MsUnLockAll())
    EndIf
EndIf
Return {lRet,cMsg}

/*/{Protheus.doc} AprovPC
	@type  Static Function
	@author Renato Paiva
	@since 10/08/2022
	@version P12
/*/
Static Function AprovPC(nRecno,cAprova,cObserv,aUser)//,_cEmp,cFil)
Local aRet 	:= {}
Local cTipo	:= "PC" 
Local cMsg	:= ""
Local cPedido := ""
Local lOk	:= .F.


	SAK->(DbSetOrder(2))

	If SAK->(DbSeek(xFilial("SAK")+RetCodUsr()))
		SC7->(DbGoTo(nRecno))
		cPedido := SC7->C7_NUM
		CONOUT("pEDIDO: " + SC7->C7_NUM)
		SCR->(DbSetOrder(3))
		conout(cEmpAnt+"/"+cFilAnt)
		CONOUT("FIND DOC: "+xFilial("SCR",cFilAnt) + cTipo + Padr(SC7->C7_NUM, TamSX3("CR_NUM")[1]) + SAK->AK_COD)
		If SCR->(DbSeek(xFilial("SCR") + cTipo + Padr(cPedido, TamSX3("CR_NUM")[1]) + SAK->AK_COD))
			cONOUT("RETCODUSR-001"+RetCodUsr()+">>"+SAK->AK_USER)
			__cUserId := SAK->AK_USER
			cONOUT("RETCODUSR-002"+RetCodUsr()+">>"+SAK->AK_USER)
			//-- Códigos de operações possíveis:
			//--    "001" // Liberado
			//--    "002" // Estornar
			//--    "003" // Superior
			//--    "004" // Transferir Superior
			//--    "005" // Rejeitado
			//--    "006" // Bloqueio
			//--    "007" // Visualizacao
			conout(SCR->(CR_FILIAL+CR_NUM+CR_TIPO+CR_USER+CR_APROV))
			//-- Seleciona a operação de aprovação de documentos
			If cAprova == "A"
				A094SetOp('001')
			ElseIf cAprova == "R"
				A094SetOp('005')
			EndIf
			//-- Carrega o modelo de dados e seleciona a operação de aprovação (UPDATE)
			If cAprova $ "AR"
				oModel094 := FWLoadModel('MATA094')
				oModel094:SetOperation( MODEL_OPERATION_UPDATE )
				oModel094:Activate()

				oModel094:GetModel('FieldSCR'):LoadValue("CR_OBS","[Usuario Responsavel: "+aUser[1][1]+"-"+aUser[1][2]+"] - " + cObserv)
				//-- Valida o formulário
				lOk := oModel094:VldData()
		
				If lOk
					//-- Se validou, grava o formulário
					lOk := oModel094:CommitData()
				EndIf
		
				//-- Avalia erros
				If lOk
					cMsg := "Pedido: " + SC6->C6_NUM 
					If cAprova == "A"
						cMsg += " aprovado"
					ElseIf cAprova == "R"
						cMsg += " rejeitado"
					EndIf
					cMsg += " com Sucesso"
				Else
					//-- Busca o Erro do Modelo de Dados
					aErro := oModel094:GetErrorMessage()
						
					//-- Monta o Texto que será mostrado na tela
					cMsg := "Id do formulário de origem:" + AllToChar(aErro[01]) 
					cMsg += "Id do campo de origem: "     + AllToChar(aErro[02]) 
					cMsg += "Id do formulário de erro: "  + AllToChar(aErro[03]) 
					cMsg += "Id do campo de erro: "       + AllToChar(aErro[04]) 
					cMsg += "Id do erro: "                + AllToChar(aErro[05]) 
					cMsg += "Mensagem do erro: "          + AllToChar(aErro[06]) 
					cMsg += "Mensagem da solução:"        + AllToChar(aErro[07]) 
					cMsg += "Valor atribuído: "           + AllToChar(aErro[08]) 
					cMsg += "Valor anterior: "            + AllToChar(aErro[09]) 
		
				EndIf
		
				//-- Desativa o modelo de dados
				oModel094:DeActivate()
			EndIf
		Else
			cMsg := "Documento não encontrado!"
		EndIf
	Else
		cMsg := "Aprovador nao encontrado!"	
    EndIf

aRet := {lOk,cMsg}
Return aRet
