#INCLUDE "PROTHEUS.CH"

#DEFINE _cTable "ZN9"

User Function SENDMSG()



Return lRet



Static Function SendMsgD88(nIdGrupo,cDecGrp,cAssunto,cMessagem)
Local lRet      := .F.
Local cSend     := ""
Local cUrl      := SupetGetMv("PZ_URLD88",.F.,"https://petz.doc88.com.br")
Local cApi      := SupetGetMv("PZ_APIMSG",.F.,"/api/v2/petz/notification")
Local aSendTipo := Separa(Alltrim(SupetGetMv("PZ_SENDTP",.F.,".T.;.T.;.T.")),";")
Local cLink     := SupetGetMv("PZ_LINKOBR",.F.,"/obras/contratos")

DEFAULT nIdGrupo := 3600

cSend := '{ '
cSend += ' "id_grupo": '+ cValtoChar(nIdGrupo) +',' 
cSend += '	"desc_grupo": "'+ cDecGrp + '", '
cSend += '	"card": '  + If(aSendTipo[1],'true','false')+',' 
cSend += '	"email": ' + If(aSendTipo[2],'true','false')+','   
cSend += '	"push": '  + If(aSendTipo[3],'true','false')+','  
cSend += '	"link": "' + cLink + '", '
cSend += '	"assunto": "' + cAssunto + '" '
cSend += '	"mensagem" :"' + cMessagem + '" '
cSend += ' } '

HttpPost(cUrl + cLink /*<cUrl>*/, /*[ cGetParms ]*/, /*[ cPostParms ]*/, /*[ nTimeOut ]*/, /*[ aHeadStr ]*/, /*[ @cHeaderGet ]*/ )

Return lRet

Static Function SendLibSld(_cFilial)
Local _cAlias   := GetNextAlias()
Local _cTblLbSld:= "%"+RetSqlName(_cTable)+"%"
Local _cWhere   := "%"+_cTable+"_STATUS='2'"+"%"
Local nIdGrupo
Local cDecGrp
Local cAssunto
Local cMessagem
Local lSend := .T.
Local aAreaZN9 := ZN9->(GetArea())


BeginSql Alias _cAlias
	SELECT 
    ZT4_STATUS,
    ZN9.*,ZN9.R_E_C_N_O_ REC_ZN9
	FROM %exp:_cTblLbSld% ZN9
    JOIN %table:ZT4% ZT4
        ON(ZT4.D_E_L_E_T_=' ' 
        AND ZT4_ID=ZN9_IDAPRV 
        )
	WHERE
    ZN9.D_E_L_E_T_=' '
    AND %exp:_cWhere%
EndSql

(_cAlias)->(DbGotop())

While !(_cAlias)->(Eof())
    /*
    If (_cAlias)->ZT4_STATUS == "2"
        If (lSend := SendMsgD88(nIdGrupo,cDecGrp,cAssunto,cMessagem))
            ConOut("[USER][INFO] WS_SENDMSG - ENVIO DO POST COM SUCESSO - "+(_cAlias)->&(_cTable+"_NUMERO"))
        Else    
            ConOut("[USER][INFO] WS_SENDMSG - NAO FOI POSSIVEL O POST"+(_cAlias)->&(_cTable+"_NUMERO"))
        EndIf
    EndIf
    */
    If lSend 
        ZN9->(DbGoTo((_cAlias)->REC_ZN9))
        If ZN9->(Recno()) == (_cAlias)->REC_ZN9 .And. (_cAlias)->ZT4_STATUS == "2"
            RecLock("ZN9",.F.)
                ZN9->ZN9_STATUS := '3'
            ZN9->(MsUnLock())
        //ElseIf (_cAlias)->ZT4_STATUS == ""
        EndIf
    EndIf
(_cAlias)->(DbSkip())
EndDo
RestArea(aAreaZN9)
Return

Static Function SendCngFin(_cFilial)
Local lRet      := .F.
Local cUrl      := SuperGetMv("PZ_WSSUSE1",.F.,"http://vm147.office1.simplesmenteuse.com.br/SuseToolsBatch/consumoPrevistoDeObjetoDeContratoWebService/salvar")
Local cToken    := SuperGetMv("PZ_SUSETOK",.F.,"0fYNgUlm5eAZ3YIISb2tiw==")
Local _cAlias   := GetNextAlias()
Local _cIdExt   := Space(TamSX3("CNS_XIDEXT")[1])

Local cGetParms := ""
Local cPostParms:= ""
Local nTimeOut  := Val(SuperGetMv("PZ_TWSPOST",.F.,"60"))
Local aHeadStr  := {}
Local cHeadRet:= ""
Local sPostRet  := Nil
Local lHttpPost := .F.

Local strJson   
Local lenStrJson
Local aJsonfields
Local nRetParser
Local oJHM      
Local oJsonParser
Local cJson
Local oJson
Local nPosX := 0

DEFAULT _cFilial    := xFilial("CNF")

ConOut('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'][SENDCNGFIN] INICIO')

_cFilial := xFilial("CNF",PadR(_cFilial,FwSizeFilial()))

aadd(aHeadStr,'Content-Type: application/json')
aadd(aHeadStr,'token: ' + cToken)

BeginSql Alias _cAlias
	SELECT 
		CNS_CONTRA,CNS_PRVQTD
        ,CNB_PRODUT,CNB_VLUNIT
        ,CNF_DTVENC
        ,CNF.R_E_C_N_O_ REC_CNF
        ,CNS.R_E_C_N_O_ REC_CNS
        ,CNB.R_E_C_N_O_ REC_CNB
        ,CN9.R_E_C_N_O_ REC_CN9
	FROM %table:CNF% CNF
    JOIN %table:CNS% CNS
        ON(CNS.D_E_L_E_T_=' ' 
            AND CNS_FILIAL=CNF_FILIAL
            AND CNS_CRONOG=CNF_NUMERO 
            AND CNS_PARCEL=CNF_PARCEL 
            AND CNS_CONTRA=CNF_CONTRA 
            AND CNS_REVISA=CNF_REVISA
        )
    JOIN %table:CNB% CNB
        ON(CNB.D_E_L_E_T_=' '
            AND CNB_FILIAL=CNS_FILIAL
            AND CNB_NUMERO=CNS_PLANI AND CNB_ITEM=CNS_ITEM
            AND CNB_CONTRA=CNS_CONTRA AND CNB_REVISA=CNS_REVISA
        )
    JOIN %table:CN9% CN9
        ON(CN9.D_E_L_E_T_=' '
            AND CN9_FILIAL=CNS_FILIAL
            AND CN9_NUMERO=CNS_CONTRA
            AND CN9_REVISA=CNS_REVISA
            AND CN9_XIDEXT<>%exp:_cIdExt%)
	WHERE
    	CNF.D_E_L_E_T_=' '
        AND CNF_FILIAL=%exp:_cFilial%
EndSql

(_cAlias)->(DbGoTop())

While (_cAlias)->(!Eof()) 
    ConOut('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'][SENDCNGFIN] PROCESSANDO - '+(_cAlias)->CNS_CONTRA )
    ConOut('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'][SENDCNGFIN] PROCESSANDO - '+ValType((_cAlias)->CNB_PRODUT ))
        cPostParms := '{ '
        cPostParms += ' "numero" : "",
        cPostParms += ' "numeroDoContrato" : "' + Alltrim((_cAlias)->CNS_CONTRA) + '", '
        cPostParms += ' "codigo" : "' + Alltrim((_cAlias)->CNB_PRODUT) + '", '
        cPostParms += ' "dataDoLancamento" : "' + DToC(SToD((_cAlias)->CNF_DTVENC)) + '", '
        cPostParms += ' "historicoDoLancamento" : "", '
        cPostParms += ' "valorDoLancamento" : "' + cValToChar(ROUND((_cAlias)->CNS_PRVQTD*(_cAlias)->CNB_VLUNIT,TamSX3("CNB_VLUNIT")[2])) + '" '
        cPostParms += ' } '
    
        ConOut('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'][SENDCNGFIN] PROCESSANDO - POST INICIO ' + CRLF + cPostParms )

        sPostRet := HttpPost(cUrl, cGetParms, cPostParms, nTimeOut, aHeadStr, @cHeadRet )

        ConOut('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'][SENDCNGFIN] PROCESSANDO - POST FIM ' + CRLF + cPostParms )

		If empty(sPostRet)
			conout('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'] [WSSENDMSG-SENDCNGFIN] Retentativa ERRO INICIO LOG POST: ')
			nPos := AT("STATUS:", UPPER(cHeadRet))
			If	SubStr(cHeadRet,nPos+8,3) $ "|200|201|202|204|"
    			conout('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'] [WSSENDMSG-SENDCNGFIN] Retentativa SUCESSO POST - ' + SubStr(cHeadRet,nPos+8,3) )      			
				lHttpPost:=.T.
			Else
				lHttpPost:=.F.
				conout(cHeadRet)
			EndIf
			conout('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'] [WSSENDMSG-SENDCNGFIN] Retentativa ERRO FIM LOG POST: ')
		Else
            nPos := AT("HTTP/", UPPER(cHeadRet))
            
			If	SubStr(cHeadRet,nPos+9,3) $ "|200|201|202|204|"
    			conout('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'] [WSSENDMSG-SENDCNGFIN] SUCESSO SEND POST - ' + SubStr(cHeadRet,nPos+9,3) )      			
				lHttpPost:=.T.

                cJson       := strJson := sPostRet
                lenStrJson  := Len(Alltrim(strJson))
                aJsonfields := {}
                nRetParser  := 0
                oJHM        := Nil
                oJsonParser := tJsonParser():New()
                
                FWJSONDeserialize(cJson,@oJson)
                
                If(lRet := oJsonParser:Json_Hash(strJson, lenStrJson, @aJsonfields, @nRetParser, @oJHM))
                    If (nPosX := aScan(aJsonfields[1][2],{|x| Upper(Alltrim(x[1])) == "NUMEROGERADO"})) > 0
                        If CNS->(DbGoTo((_cAlias)->REC_CNS))
                            RecLock("CNS",.F.)
                                CNS->CNS_XIDEXT := aJsonfields[1][2][nPosX][2]
                            CNS->(MsUnLock())
                            conout('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'] [WSSENDMSG-SENDCNGFIN] POST SALVA IDEXTERNO - ' + CNS->CNS_XIDEXT)      			
                        EndIf
                    EndIf
                EndIf

			Else
                conout('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'] [WSSENDMSG-SENDCNGFIN] ERRO POST - ' + SubStr(cHeadRet,nPos+9,3) + CRLF + cHeadRet)      			
            	lHttpPost:=.F.
			EndIf


		EndIf

        If lHttpPost

        EndIf
    Sleep(100)
(_cAlias)->(DbSkip())
EndDo
ConOut('[INFO][USER] ['+DTOC(date())+ ' - '+Time()+'][SENDCNGFIN] FIM')
Return lRet