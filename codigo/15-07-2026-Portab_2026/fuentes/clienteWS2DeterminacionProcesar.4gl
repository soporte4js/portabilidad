#+
#+ Generated from clienteConsultar
#+
IMPORT com
IMPORT XML
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
        (Uri: "https://wsconsultarprocesar_debe_venir_desde_fglprofile.com"))
             --"https://wsprocesar.com.mx/retiros/v1/999/portabilidad/determinacion"))
             
# Unexpected error details
PUBLIC DEFINE wsError RECORD
    code INTEGER,
    description STRING
END RECORD

# Error codes
PUBLIC CONSTANT C_SUCCESS = 0
PUBLIC CONSTANT C_CONSULTARTRAMITE_400 = 1001
PUBLIC CONSTANT C_CONSULTARTRAMITE_404 = 1002
PUBLIC CONSTANT C_CONSULTARTRAMITE_500 = 1003
PUBLIC CONSTANT C_CONSULTARTRAMITE_503 = 1004

# components/schemas/consultarTramiteRequest
PUBLIC TYPE consultarTramiteRequest RECORD
    institutoReceptorTramite VARCHAR(2),
    nssImss VARCHAR(11),
    curp VARCHAR(18),
    folioTramiteEntidadReceptor VARCHAR(50),
    primerApellido VARCHAR(50),
    segundoApellido VARCHAR(50),
    nombre VARCHAR(50),
    fechaInicioTramite VARCHAR(19),
    correoElectronico VARCHAR(255)
END RECORD

# components/schemas/consultarTramiteResponse
PUBLIC TYPE consultarTramiteResponse RECORD
    resultadoOperacion VARCHAR(2),
    motivoRechazo VARCHAR(3),
    folioProcesar VARCHAR(50),
    fechaRegistroEstatus VARCHAR(19),
    estatusDictaminacionPortabilidad VARCHAR(2),
    derechoOtorgadoImss VARCHAR(130),
    fechaOtorgamientoDerechoImss VARCHAR(10),
    derechoOtorgadoIssste VARCHAR(130),
    fechaOtorgamientoDerechoIssste VARCHAR(10)
END RECORD

# components/schemas/ValidationFailureDetail
PUBLIC TYPE ValidationFailureDetail RECORD
    message DYNAMIC ARRAY OF STRING,
    xmlLocation DYNAMIC ARRAY OF STRING
END RECORD

# components/schemas/ValidationFailure
PUBLIC TYPE ValidationFailure RECORD
    ValidationFailureDetail ValidationFailureDetail
END RECORD

# components/schemas/errorDetail
PUBLIC TYPE errorDetail RECORD
    codigo STRING,
    descripcion ValidationFailure,
    locacion STRING
END RECORD

# components/schemas/error
PUBLIC TYPE error RECORD
    error errorDetail
END RECORD

PUBLIC # # Bad Request  La petición enviada es incorrecta. 1.- El payload (campos y valores) no son correctos. 2.- Mensaje de error cuando los valores del header no son correctos, tanto en atributos como en valor.
    DEFINE consultarTramite_400 error
PUBLIC # # Not FoundEndpoint incorrecto
    DEFINE consultarTramite_404 STRING
PUBLIC # # Internal Server Error Mensaje genérico de error de servidor.
    DEFINE consultarTramite_500 STRING
PUBLIC # # Service Unavailable Servicio no disponible temporalmente .
    DEFINE consultarTramite_503 STRING

################################################################################
# Operation /consulta
#
# VERB: POST
# ID:          consultarTramite
# SUMMARY:     Retiros - Determinación Portabilidad Consulta Trámite
# DESCRIPTION: **NOTA:** Los campos marcados como opcional no deben enviarse si éstos no llevaran valor, por tanto, no se aceptan campos/etiquetas vacías.
#
PUBLIC FUNCTION consultarTramite(
    p_idServicio STRING,
    p_idEbusiness STRING,
    p_idCliente STRING,
    p_body consultarTramiteRequest)
    RETURNS(INTEGER, consultarTramiteResponse)
    DEFINE fullpath base.StringBuffer
    DEFINE contentType STRING
    DEFINE headerName STRING
    DEFINE ind INTEGER
    DEFINE req com.HttpRequest
    DEFINE resp com.HttpResponse
    DEFINE resp_body consultarTramiteResponse
    DEFINE xml_body xml.DomDocument
    DEFINE xml_node xml.DomNode
    DEFINE json_body STRING

    TRY

        # Prepare request path
        LET fullpath = base.StringBuffer.create()
        CALL fullpath.append("/consulta")

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
        IF p_idServicio IS NOT NULL THEN
            CALL req.setHeader("idServicio", p_idServicio)
        END IF
        IF p_idEbusiness IS NOT NULL THEN
            CALL req.setHeader("idEbusiness", p_idEbusiness)
        END IF
        IF p_idCliente IS NOT NULL THEN
            CALL req.setHeader("idCliente", p_idCliente)
        END IF
        CALL req.setHeader("Accept", "application/json, application/xml")
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

            WHEN 200 ## OK Transacción exitosa.
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, resp_body)
                    RETURN C_SUCCESS, resp_body.*
                END IF
                LET wsError.code = resp.getStatusCode()
                LET wsError.code = "Unexpected Content-Type"
                RETURN -1, resp_body.*

            WHEN 400 ## Bad Request  La petición enviada es incorrecta. 1.- El payload (campos y valores) no son correctos. 2.- Mensaje de error cuando los valores del header no son correctos, tanto en atributos como en valor.
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, consultarTramite_400)
                    RETURN C_CONSULTARTRAMITE_400, resp_body.*
                END IF
                IF contentType MATCHES "*application/xml*" THEN
                    # Parse XML response
                    LET xml_body = resp.getXmlResponse()
                    LET xml_node = xml_body.getDocumentElement()
                    CALL xml.Serializer.DomToVariable(
                        xml_node, consultarTramite_400)
                    RETURN C_CONSULTARTRAMITE_400, resp_body.*
                END IF
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = "Unexpected Content-Type"
                RETURN -1, resp_body.*

            WHEN 404 ## Not FoundEndpoint incorrecto
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, consultarTramite_404)
                    RETURN C_CONSULTARTRAMITE_404, resp_body.*
                END IF
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = "Unexpected Content-Type"
                RETURN -1, resp_body.*

            WHEN 500 ## Internal Server Error Mensaje genérico de error de servidor.
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, consultarTramite_500)
                    RETURN C_CONSULTARTRAMITE_500, resp_body.*
                END IF
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = "Unexpected Content-Type"
                RETURN -1, resp_body.*

            WHEN 503 ## Service Unavailable Servicio no disponible temporalmente .
                IF contentType MATCHES "*application/json*" THEN
                    # Parse JSON response
                    LET json_body = resp.getTextResponse()
                    CALL util.JSON.parse(json_body, consultarTramite_503)
                    RETURN C_CONSULTARTRAMITE_503, resp_body.*
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
