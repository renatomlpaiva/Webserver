#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
 
WSRESTFUL WSSHAREDFILE DESCRIPTION "Web service para download de arquivos da base de conhecimento."

WSDATA cEmpWeb 		AS STRING
WSDATA cFilWeb 		AS STRING
WSDATA cFileWeb		AS STRING

WSMETHOD GET	DESCRIPTION "Retorna arquivo." WSSYNTAX "/WSSHAREDFILE "
 
END WSRESTFUL
 

WSMETHOD GET WSRECEIVE cEmpWeb,cFilWeb,cFileWeb  WSSERVICE WSSHAREDFILE
Local cFile := ""
Local oFile 
Local cFileOrg := ""
    
DEFAULT ::cEmpWeb	:= "01"
DEFAULT ::cFilWeb	:= "01"
DEFAULT ::cFileWeb  := ""

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSSHAREDFILE INICIO")
cFileOrg := "/dirdoc/co" + ::cEmpWeb +"/shared/"+::cFileWeb 
ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSSHAREDFILE - cFileOrg: " + cFileOrg)
oFile := FwFileReader():New(cFileOrg ) // CAMINHO ABAIXO DO ROOTPATH
// SE FOR POSSÍVEL ABRIR O ARQUIVO, LEIA-O
// SE NÃO, EXIBA O ERRO DE ABERTURA
If (oFile:Open())
    cFile := oFile:FullRead() // EFETUA A LEITURA DO ARQUIVO

    // RETORNA O ARQUIVO PARA DOWNLOAD
    ::SetHeader("Content-Disposition", "attachment; filename="+::cFileWeb)
    ::SetResponse(cFile)

    lRet := .T. // CONTROLE DE SUCESSO DA REQUISIÇÃO
Else
    SetRestFault(002, "can't load file") // GERA MENSAGEM DE ERRO CUSTOMIZADA

    lRet := .F. // CONTROLE DE SUCESSO DA REQUISIÇÃO
EndIf

ConOut("[USER][INFO][" + DToC(DATE()) + " " + TIME() + "] GET - WSSHAREDFILE FIM ")
Return lRet
 
