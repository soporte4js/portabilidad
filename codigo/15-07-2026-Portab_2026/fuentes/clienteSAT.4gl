#+
#+ Generated from cliente
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

--PUBLIC DEFINE Endpoint tGlobalEndpointType = (Address:(Uri: "http://api2.issste.gob.mx/wsfirma"))
PUBLIC DEFINE Endpoint tGlobalEndpointType = (Address:(Uri: "http://wsfirmasat_debe_venir_desde_fglprofile.com"))

# Unexpected error details
PUBLIC DEFINE wsError RECORD
    code INTEGER,
    description STRING
END RECORD

# Error codes
PUBLIC CONSTANT C_SUCCESS = 200

# components/schemas/request
PUBLIC TYPE request RECORD
    aplicacion STRING,
    folioControl STRING,
    nombre STRING,
    rfc STRING,
    password STRING,
    certificado_b64 STRING,
    clavePrivada_b64 STRING,
    documento_b64 STRING
END RECORD

PUBLIC TYPE t_val_cer STRING

################################################################################
# Operation /Firma
#
# VERB: POST
# ID:          Post_Firma
# SUMMARY:     FirmarDocumento
#
PUBLIC FUNCTION Post_Firma(p_body request, l_nombre_pdf t_val_cer) RETURNS(INTEGER)
    DEFINE fullpath base.StringBuffer
    DEFINE contentType STRING
    DEFINE headerName STRING
    DEFINE ind INTEGER
    DEFINE req com.HttpRequest
    DEFINE resp com.HttpResponse
    DEFINE json_body STRING
    DEFINE ldocumento BYTE

    TRY

        # Prepare request path
        LET fullpath = base.StringBuffer.create()
        CALL fullpath.append("/Firma")

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
        # Perform JSON request
        CALL req.setHeader("Content-Type", "application/json")
        CALL req.setHeader("Authorization","Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI0OHgxQ2dVYU4zNUx4Z0VVNWFXZ2lTNDlleEtsbURVQSJ9.J3g3pCxFMmqMhFH6y1GIQFjEMEYjopJHWipEvOzC4MA")
        LET json_body = util.JSON.stringify(p_body)
        CALL req.doTextRequest(json_body)

        # Retrieve response
        LET resp = req.getResponse()
        
        LOCATE ldocumento IN MEMORY
        CALL resp.getDataResponse(ldocumento)
        CALL ldocumento.writeFile(l_nombre_pdf)
        
        # Process response
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
                RETURN C_SUCCESS

            OTHERWISE
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = resp.getStatusDescription()
                RETURN -1
        END CASE
    CATCH
        LET wsError.code = status
        LET wsError.description = sqlca.sqlerrm
        RETURN -1
    END TRY
END FUNCTION

#
# VERB: POST
# ID:          Post_FirmaNoRequestBody
# SUMMARY:     FirmarDocumento
#
PUBLIC FUNCTION Post_FirmaNoRequestBody() RETURNS(INTEGER)
    DEFINE fullpath base.StringBuffer
    DEFINE contentType STRING
    DEFINE headerName STRING
    DEFINE ind INTEGER
    DEFINE req com.HttpRequest
    DEFINE resp com.HttpResponse

    TRY

        # Prepare request path
        LET fullpath = base.StringBuffer.create()
        CALL fullpath.append("/Firma")

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
        CALL req.doRequest()

        # Retrieve response
        LET resp = req.getResponse()
        # Process response
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
                RETURN C_SUCCESS

            OTHERWISE
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = resp.getStatusDescription()
                RETURN -1
        END CASE
    CATCH
        LET wsError.code = status
        LET wsError.description = sqlca.sqlerrm
        RETURN -1
    END TRY
END FUNCTION
#
# VERB: DELETE
# ID:          Delete_Firma
# SUMMARY:     CancelarFirma
#
PUBLIC FUNCTION Delete_Firma() RETURNS(INTEGER)
    DEFINE fullpath base.StringBuffer
    DEFINE contentType STRING
    DEFINE headerName STRING
    DEFINE ind INTEGER
    DEFINE req com.HttpRequest
    DEFINE resp com.HttpResponse

    TRY

        # Prepare request path
        LET fullpath = base.StringBuffer.create()
        CALL fullpath.append("/Firma")

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
        CALL req.setMethod("DELETE")
        CALL req.doRequest()

        # Retrieve response
        LET resp = req.getResponse()
        # Process response
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
                RETURN C_SUCCESS

            OTHERWISE
                LET wsError.code = resp.getStatusCode()
                LET wsError.description = resp.getStatusDescription()
                RETURN -1
        END CASE
    CATCH
        LET wsError.code = status
        LET wsError.description = sqlca.sqlerrm
        RETURN -1
    END TRY
END FUNCTION
################################################################################
