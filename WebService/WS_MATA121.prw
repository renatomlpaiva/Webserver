#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "JSON.CH"
 
WSRESTFUL WSMATA121 DESCRIPTION "Web service para tratativade pedido/NF"

WSDATA cFornecedor AS STRING
WSDATA cLojaFornec AS STRING
WSDATA cCNPJ 		 AS STRING

WSMETHOD GET DESCRIPTION "Retorna pedido/NF cadastrado." WSSYNTAX "/WSMATA121/{cnpj_emp} "
WSMETHOD POST DESCRIPTION "Inclui/Atualiza pedido/NF cadastrado." WSSYNTAX "/WSMATA121/{cnpj_emp}"
//WSMETHOD PUT DESCRIPTION "Inclui/Atualiza fornecedor cadastrado." WSSYNTAX "/WSMATA121/{cnpj_emp}"
//WSMETHOD DELETE DESCRIPTION "Exclui fornecedor cadastrado." WSSYNTAX "/WSMATA121/{cnpj_emp}"
 
END WSRESTFUL
 
// O metodo GET nao precisa necessariamente receber parametros de querystring, por exemplo:
// WSMETHOD GET WSSERVICE MATA020 

WSMETHOD GET WSRECEIVE cFornecedor, cLojaFornec, cCNPJ  WSSERVICE WSMATA121
Local i		:= 0
Local cRet	:= ""
Local cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local aStruct	:= {}
Local aJSON	:= {}
Local oJSON	:= Nil

DEFAULT ::cFornecedor	:= ""
DEFAULT ::cLojaFornec	:= ""
DEFAULT ::cCNPJ		:= ""

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 INICIO")
// define o tipo de retorno do metodo
::SetContentType("application/json")
RpcSetType(3)
RpcSetEnv("04","04 0001   ")


	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 COD:"+::cFornecedor)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 LOJA:"+::cLojaFornec)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 CNPJ:"+::cCNPJ)

If (!Empty(::cFornecedor) .And. !Empty(::cLojaFornec)) .Or. !Empty(::cCNPJ)
/*	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 COD:"+::cFornecedor)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 LOJA:"+::cLojaFornec)
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 CNPJ:"+::cCNPJ)
*/	
	cQuery := " SELECT "
	cQuery += " * "
	cQuery += " FROM " + RetSqlName("SA2") + " SA2 "
	cQuery += " WHERE "
	cQuery += " SA2.D_E_L_E_T_=' ' "
	cQuery += " AND " + If(Empty(::cCNPJ)," A2_COD='" + ::cFornecedor + "' AND A2_LOJA='" + ::cLojaFornec + "' "," A2_CGC='" + ::cCNPJ + "' " )
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), _cAlias, .F., .F.)
	
	(_cAlias)->(DbGoTop())
	If !(_cAlias)->(Eof())
		aStruct := (_cAlias)->(DbStruct())
		aAdd( aJSON, JSONObject():New() )
		
		//aEval(aStruct,{|x| &("aJSON[Len(aJSON)][#'"+x[1]+"'] := If(x[2]=='N',Alltrim(Str((_cAlias)->"+x[1]+")),Alltrim((_cAlias)->"+x[1]+"))")})		
		For i:= 1 To Len(aStruct)
			aJSON[Len(aJSON)][#&("'"+aStruct[i][1]+"'")] := If(aStruct[i][2]=="N",cValToChar((_cAlias)->&(aStruct[i][1])),Alltrim((_cAlias)->&(aStruct[i][1])))
		Next
		oJSON := JSON():New( aJSON )
		
		::SetResponse(StrTran(oJSON:Stringify(),"\",""))
	EndIf
	If Select(_cAlias) > 0
		(_cAlias)->(DbCloseArea())
	EndIf
Else
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121: PARAMETRO INVALIDO.")
	SetRestFault(400, "id parameter is mandatory")
EndIf

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSMATA121 FIM ")
Return .T.
 
// O metodo POST pode receber parametros por querystring, por exemplo:
// WSMETHOD POST WSRECEIVE startIndex, count WSSERVICE MATA020
WSMETHOD POST WSSERVICE WSMATA121
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
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 INICIO")
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
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 DESERIALIZADO")	
	
	If Len(oJson:PEDIDO:CONTENT) > 0 .Or. !Empty(oJson:PEDIDO:CHAVE_XML)	
		strJson = cJson
		lenStrJson := Len(strJson)
		aJsonfields := {}
		nRetParser := 0
		oJHM := .F.
		lRet := .F.
		
		If(lRet := oJsonParser:Json_Hash(strJson, lenStrJson, @aJsonfields, @nRetParser, @oJHM))
			ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 PARSE REALIZADO")
			
			Begin Transaction 
				aRet := LoadPC(oJson,aJsonFields)
				If Len(aRet) > 0
					ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 WF REALIZADO VLD RETORNO")
					If (lPost := aRet[1])
						cMsg  := aRet[2]
						::SetResponse(cJson+cMsg)
					Else
						cMsg  := aRet[2]
						SetRestFault(400, cMsg)			
					EndIf
				EndIf
			End Transaction     
		Else
			ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] ERRO 02")
	   		SetRestFault(400, "ERROR 02")
	   		lPost := .F.
		EndIf
	Else
		ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] ERRO 01")   
	   	SetRestFault(400, "ERROR 01")
	EndIf
EndIf

Return lPost
 
// O metodo PUT pode receber parametros por querystring, por exemplo:
// WSMETHOD PUT WSRECEIVE startIndex, count WSSERVICE MATA020
/*WSMETHOD PUT WSSERVICE WSMATA121
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
WSMETHOD DELETE WSSERVICE WSMATA121
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


Static Function LoadPC(oJson,aJsonFields)
Local lRet      := .F.
Local cMsg      := ""
Local cChaveXML := """
Local aHeader   := {}
Local aContent  := {}
Local nPos      := 0
Local aRet		:= {.F.,"000-PROCESSAMENTO NAO REALIZADO."}
If (nPos := aScan(aJsonFields[1][2][2][2],{|x| Upper(Alltrim(x[1]))=="CHAVE_XML"})) > 0
    ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 LOAD CHAVE XML")
    cChaveXML := oJson:PEDIDO:CHAVE_XML
EndIf

If (nPos := aScan(aJsonFields[1][2][2][2],{|x| Upper(Alltrim(x[1]))=="HEADER"})) > 0
    ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 LOAD HEADER")
    aHeader := aJsonfields[1][2][2][2][nPos+1][2]
EndIf

If (nPos := aScan(aJsonFields[1][2][2][2],{|x| Upper(Alltrim(x[1]))=="CONTENT"})) > 0
    ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 LOAD CONTENT")
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
Local cLogFile:= "\wsmata121_" + DToS(date()) + StrTran(Time(),":",".") +".LOG" 
Local aErros    := {}
Local i         := 0
Local nX        := 0

PRIVATE lMsErroAuto := .F.
// vari·vel que define que o help deve ser gravado no arquivo de log e que as informaÁıes est„o vindo ‡ partir da rotina autom·tica.
Private lMsHelpAuto	:= .T.    
// forÁa a gravaÁ„o das informaÁıes de erro em array para manipulaÁ„o da gravaÁ„o ao invÈs de gravar direto no arquivo tempor·rio 
Private lAutoErrNoFile := .T. 

DEFAULT nTipo := 1

If nTipo == 1
	aEval(aContent,{|x| aAdd(aItens,{})})
	i:=0
	ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 VALIDA DADOS PC")
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

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] POST - WSMATA121 INICIO EXECAUTO")

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
        
        //funÁ„o que retorna as informaÁıes de erro ocorridos durante o processo da rotina autom·tica		
        aLog := GetAutoGRLog()	                                 				
        //efetua o tratamento para validar se o arquivo de log j· existe		
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
            //grava as informaÁıes de log no arquivo especificado			
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

