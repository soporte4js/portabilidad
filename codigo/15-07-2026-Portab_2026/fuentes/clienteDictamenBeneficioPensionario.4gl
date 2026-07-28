#+
#+ Generated from clienteDictamenBeneficioPensionario
#+
IMPORT com
IMPORT util

#+
#+ Global Endpoint user-defined type definition
#+
TYPE tGlobalEndpointType RECORD # Rest Endpoint
    Address RECORD # Address
        Uri STRING # URI
    END RECORD,
    Binding RECORD # Binding
        Version STRING, # HTTP Version (1.0 or 1.1)
        Cookie STRING, # Cookie to be set
        Request RECORD # HTTP request
            Headers DYNAMIC ARRAY OF RECORD # HTTP Headers
                Name STRING,
                Value STRING
            END RECORD
        END RECORD,
        Response RECORD # HTTP request
            Headers DYNAMIC ARRAY OF RECORD # HTTP Headers
                Name STRING,
                Value STRING
            END RECORD
        END RECORD,
        ConnectionTimeout INTEGER, # Connection timeout
        ReadWriteTimeout INTEGER, # Read write timeout
        CompressRequest STRING # Compression (gzip or deflate)
    END RECORD
END RECORD

PUBLIC DEFINE Endpoint tGlobalEndpointType =
    (Address:
        (Uri: "https://wsclientebenficiopensionario_debe_venir_desde_fglprofile.com"))
             --"https://issstenet.issste.gob.mx/gasapp/ws/r/wsportabilidad/dictamenbeneficiopensionario"))
             --"https://localhost:6394/ws/r/wsportabilidad/dictamenbeneficiopensionario"))

# Unexpected error details
PUBLIC DEFINE wsError RECORD
    code INTEGER,
    description STRING
END RECORD

# Error codes
PUBLIC CONSTANT C_SUCCESS = 0
PUBLIC CONSTANT C_MSGDICTPORT = 1001

# components/schemas/t_wsEntradaValidaBeneficioPensionario
PUBLIC TYPE t_wsEntradaValidaBeneficioPensionario RECORD
    nss_imss VARCHAR(44),
    curp VARCHAR(72),
    tiempo_cotizado_imss INTEGER,
    tiempo_cotizado_issste INTEGER,
    salario_prom_hl DECIMAL(12, 2),
    folio_solicitud BIGINT
END RECORD

# components/schemas/t_wsSalidaValidaBeneficioPensionario
PUBLIC TYPE t_wsSalidaValidaBeneficioPensionario RECORD
    nss_imss VARCHAR(44),
    curp VARCHAR(72),
    cve_beneficio INTEGER,
    desc_beneficio VARCHAR(120),
    derecho_pension INTEGER,
    codigo_resultado VARCHAR(8),
    observaciones VARCHAR(1020)
END RECORD

# generated msgDictPortErrorType
PUBLIC TYPE msgDictPortErrorType RECORD
    message STRING
END RECORD

PUBLIC # Tratamiento de Mensajes Dictamen de Beneficio Pensionario - Transferencia de Derechos
    DEFINE msgDictPort msgDictPortErrorType

################################################################################
# Operation /dictamenbeneficiopensionario
#
# VERB: POST
# ID:          dictaminabeneficiopensionario
# DESCRIPTION: Dictamen de Beneficio Pensionario - Transferencia de Derechos - ISSSTE
#
PUBLIC FUNCTION dictaminabeneficiopensionario(
    p_body t_wsEntradaValidaBeneficioPensionario)
    RETURNS(INTEGER, t_wsSalidaValidaBeneficioPensionario)
    DEFINE fullpath base.StringBuffer
    DEFINE contentType STRING
    DEFINE headerName STRING
    DEFINE ind INTEGER
    DEFINE req com.HttpRequest
    DEFINE resp com.HttpResponse
    DEFINE resp_body t_wsSalidaValidaBeneficioPensionario
    DEFINE json_body STRING

    TRY

        # Prepare request path
        LET fullpath = base.StringBuffer.create()
        CALL fullpath.append("/dictamenbeneficiopensionario")

        # Create request and configure it
        LET req =
            com.HttpRequest.Create(
                SFMT("%1%2", Endpoint.Address.Uri, fullpath.toString()))
        IF Endpoint.Binding.Version IS NOT NULL THEN
            CALL req.setVersion(Endpoint.Binding.Version)
        END IF
        IF Endpoint.Binding.Cookie IS NOT NULL THEN
            CALL req.setHeader("Cookie", Endpoint.Binding.Cookie)
        END IF
        IF Endpoint.Binding.Request.Headers.getLength() > 0 THEN
            FOR ind = 1 TO Endpoint.Binding.Request.Headers.getLength()
                CALL req.setHeader(
                    Endpoint.Binding.Request.Headers[ind].Name,
                    Endpoint.Binding.Request.Headers[ind].Value)
            END FOR
        END IF
        CALL Endpoint.Binding.Response.Headers.clear()
        IF Endpoint.Binding.ConnectionTimeout <> 0 THEN
            CALL req.setConnectionTimeOut(Endpoint.Binding.ConnectionTimeout)
        END IF
        IF Endpoint.Binding.ReadWriteTimeout <> 0 THEN
            CALL req.setTimeOut(Endpoint.Binding.ReadWriteTimeout)
        END IF
        IF Endpoint.Binding.CompressRequest IS NOT NULL THEN
            CALL req.setHeader(
                "Content-Encoding", Endpoint.Binding.CompressRequest)
        END IF

        # Perform request
        CALL req.setMethod("POST")
        CALL req.setHeader("Accept", "application/json")
        # Perform JSON request
        CALL req.setHeader("Content-Type", "application/json")
        LET json_body = util.JSON.stringify(p_body)
        CALL req.doTextRequest(json_body)

        # Retrieve response
        LET resp = req.getResponse()
        # Process response
        INITIALIZE resp_body TO NULL
        LET contentType = resp.getHeader("Content-Type")
        IF resp.getHeaderCount() > 0 THEN
            # Retrieve response runtime headers
            FOR ind = 1 TO resp.getHeaderCount()
                LET headerName = resp.getHeaderName(ind)
                CALL Endpoint.Binding.Response.Headers.appendElement()
                LET Endpoint.Binding.Response.Headers[
                        Endpoint.Binding.Response.Headers.getLength()].Name =
                    headerName
                LET Endpoint.Binding.Response.Headers[
                        Endpoint.Binding.Response.Headers.getLength()].Value =
                    resp.getHeader(headerName)
            END FOR
        END IF
        CASE resp.getStatusCode()

            WHEN 200 #Success
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, resp_body)
                    RETURN C_SUCCESS, resp_body.*
                END IF
                LET wsError.code = resp.getStatusCode()
                LET wsError.code = "Unexpected Content-Type"
                RETURN -1, resp_body.*

            WHEN 400 #Tratamiento de Mensajes Dictamen de Beneficio Pensionario - Transferencia de Derechos
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, msgDictPort)
                    RETURN C_MSGDICTPORT, resp_body.*
                END IF
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = "Unexpected Content-Type"
                RETURN -1, resp_body.*

            OTHERWISE
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = resp.getStatusDescription()
                RETURN -1, resp_body.*
        END CASE
    CATCH
        LET wsError.code = status
        LET wsError.description = sqlca.sqlerrm
        RETURN -1, resp_body.*
    END TRY
END FUNCTION
################################################################################
