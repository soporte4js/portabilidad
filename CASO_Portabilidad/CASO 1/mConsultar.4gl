IMPORT FGL clienteWS2DeterminacionProcesar

MAIN
    DEFINE rConsultarEntrada consultarTramiteRequest
    DEFINE rConsultarSalida consultarTramiteResponse
    DEFINE wsstatus INTEGER
    DEFINE p_idServicio STRING
    DEFINE p_idEbusiness STRING
    DEFINE p_idCliente STRING

    DEFINE institutoReceptorTramite    VARCHAR(02)
    DEFINE nssImss                     VARCHAR(11)
    DEFINE curp                        VARCHAR(18)
    DEFINE folioTramiteEntidadReceptor STRING
    DEFINE primerApellido              STRING
    DEFINE segundoApellido             STRING
    DEFINE nombre                      STRING
    DEFINE fechaInicioTramite          STRING
    DEFINE correoElectronico           STRING

    LET p_idServicio = "999"
    LET p_idEbusiness = "53"
    LET p_idCliente = "96"
    
    LET clienteWS2DeterminacionProcesar.Endpoint.Address.Uri = get_endpoint_ws("wsconsultarprocesar")

    OPEN WINDOW vtnConsultaProcesar WITH FORM "fConsultar"

    INPUT BY NAME institutoReceptorTramite, nssImss, curp, folioTramiteEntidadReceptor,
                  primerApellido, segundoApellido, nombre, fechaInicioTramite, correoElectronico
                  ATTRIBUTES(UNBUFFERED, ACCEPT = FALSE, CANCEL = FALSE)
    BEFORE INPUT
        LET institutoReceptorTramite    = "02"
        LET nssImss                     = "04038362085"
        LET curp                        = "GOCJ831007HJCNRS09"
        LET folioTramiteEntidadReceptor = "12345678901234567890123456789012345678901234567890"
        LET primerApellido              = "apellidoPaterno"
        LET segundoApellido             = "apellidoMaterno"
        LET nombre                      = "nombre"
        LET fechaInicioTramite          = "08/08/2023 01:02:03"
        LET correoElectronico           = "correo_eletronico@correo.com"

        LET rConsultarEntrada.institutoReceptorTramite    = institutoReceptorTramite
        LET rConsultarEntrada.nssImss                     = nssImss
        LET rConsultarEntrada.curp                        = curp
        LET rConsultarEntrada.folioTramiteEntidadReceptor = folioTramiteEntidadReceptor
        LET rConsultarEntrada.primerApellido              = primerApellido
        LET rConsultarEntrada.segundoApellido             = segundoApellido
        LET rConsultarEntrada.nombre                      = nombre
        LET rConsultarEntrada.fechaInicioTramite          = fechaInicioTramite
        LET rConsultarEntrada.correoElectronico           = correoElectronico
        DISPLAY BY NAME rConsultarEntrada.*

        ON ACTION enviar
            LET rConsultarEntrada.institutoReceptorTramite    = institutoReceptorTramite
            LET rConsultarEntrada.nssImss                     = nssImss
            LET rConsultarEntrada.curp                        = curp
            LET rConsultarEntrada.folioTramiteEntidadReceptor = folioTramiteEntidadReceptor
            LET rConsultarEntrada.primerApellido              = primerApellido
            LET rConsultarEntrada.segundoApellido             = segundoApellido
            LET rConsultarEntrada.nombre                      = nombre
            LET rConsultarEntrada.fechaInicioTramite          = fechaInicioTramite
            LET rConsultarEntrada.correoElectronico           = correoElectronico
            DISPLAY BY NAME rConsultarEntrada.*
            DISPLAY BY NAME rConsultarEntrada.*, rConsultarSalida.*, wsstatus
            
            CALL consultarTramite(p_idServicio, p_idEbusiness, p_idCliente, rConsultarEntrada.*) RETURNING wsstatus, rConsultarSalida.*

            DISPLAY BY NAME wsstatus
            DISPLAY BY NAME rConsultarSalida.*
            
        ON ACTION CANCEL
            EXIT PROGRAM 0

        ON ACTION reiniciar
            INITIALIZE rConsultarEntrada.*, rConsultarSalida.*, wsstatus TO NULL
            LET institutoReceptorTramite    = "02"
            LET nssImss                     = "04038362085"
            LET curp                        = "GOCJ831007HJCNRS09"
            LET folioTramiteEntidadReceptor = "12345678901234567890123456789012345678901234567890"
            LET primerApellido              = "apellidoPaterno"
            LET segundoApellido             = "apellidoMaterno"
            LET nombre                      = "nombre"
            LET fechaInicioTramite          = "08/08/2023 01:02:03"
            LET correoElectronico           = "correo_eletronico@correo.com"

            LET rConsultarEntrada.institutoReceptorTramite    = institutoReceptorTramite
            LET rConsultarEntrada.nssImss                     = nssImss
            LET rConsultarEntrada.curp                        = curp
            LET rConsultarEntrada.folioTramiteEntidadReceptor = folioTramiteEntidadReceptor
            LET rConsultarEntrada.primerApellido              = primerApellido
            LET rConsultarEntrada.segundoApellido             = segundoApellido
            LET rConsultarEntrada.nombre                      = nombre
            LET rConsultarEntrada.fechaInicioTramite          = fechaInicioTramite
            LET rConsultarEntrada.correoElectronico           = correoElectronico
            DISPLAY BY NAME rConsultarEntrada.*
            DISPLAY BY NAME rConsultarEntrada.*, rConsultarSalida.*, wsstatus
            
        ON ACTION limpiar
            INITIALIZE rConsultarEntrada.*, rConsultarSalida.*, wsstatus TO NULL
            INITIALIZE institutoReceptorTramite, nssImss, curp, folioTramiteEntidadReceptor,
                  primerApellido, segundoApellido, nombre, fechaInicioTramite, correoElectronico TO NULL
            DISPLAY BY NAME rConsultarEntrada.*, rConsultarSalida.*, wsstatus
            
    END INPUT
    
    CLOSE WINDOW vtnConsultaProcesar
END MAIN

FUNCTION get_endpoint_ws(ws_alias)

    DEFINE ws_alias STRING
    DEFINE ws_entry STRING
    DEFINE ws_url   STRING
    DEFINE msg_err  STRING

    LET ws_entry=SFMT("ws.%1.url",ws_alias)
    
    CALL fgl_getresource(ws_entry) RETURNING ws_url

    IF ws_url.getLength()=0 THEN
       LET msg_err=SFMT("ERROR: entry '%1' not found in FGLPROFILE",ws_entry)
       DISPLAY "###############################################################"
       DISPLAY "##", msg_err
       DISPLAY "###############################################################"
    END IF
    
    RETURN ws_url

END FUNCTION