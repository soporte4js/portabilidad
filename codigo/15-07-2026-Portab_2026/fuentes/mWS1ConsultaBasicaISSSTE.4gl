SCHEMA dsipe

PUBLIC DEFINE serviceInfo RECORD ATTRIBUTE(WSInfo)
    title         STRING,
    description   STRING,
    termOfService STRING,
    contact       RECORD
        name      STRING,
        url       STRING,
        email     STRING
    END RECORD,
    version       STRING
END RECORD =
    (title: "Servicios de Portabilidad de derechos - Consulta Basica ISSSTE",
        version: "1.0",
        contact:(email: "transferenciaderechos@issste.gob.mx"))

TYPE t_ws1EntradaIMSS RECORD
    inst_receptor        VARCHAR(2),
    nss_imss             VARCHAR(13),
    curp                 VARCHAR(18),
    fecha_inicio_tramite STRING,
    correo               VARCHAR(255)
END RECORD

TYPE t_ws1SalidaISSSTE RECORD
    codigo_resultado VARCHAR(2),
    motivo_rechazo   VARCHAR(3),
    curp             VARCHAR(18),
    primer_apellido  VARCHAR(50),
    segundo_apellido VARCHAR(50),
    nombre           VARCHAR(50),
    nss              STRING,
    fecha_baja       STRING,
    observaciones    VARCHAR(255)
    END RECORD

PUBLIC DEFINE WS1Error RECORD ATTRIBUTE(WSError="Tratamiento de mensajes del servicio Consulta Basica IMSS")
  lmessage STRING
END RECORD

DEFINE lSolicitud RECORD LIKE cei_solicitud.*
--DEFINE rSalidaWS1IMSS              tRespuestaEstatusAsegurado
--DEFINE r_WS2Salida                 t_ws2Salida

FUNCTION consultabasicaissste( r_ws1Entrada t_ws1EntradaIMSS )
    ATTRIBUTES(WSPost, 
             WSPath="/consultabasicaissste",
             WSDescription="Consulta basica Inter Institutos - ISSSTE",
             WSThrows="400:@WS1Error")
    RETURNS t_ws1SalidaISSSTE

    DEFINE r_ws1Salida t_ws1SalidaISSSTE
    --DEFINE SQL1        STRING
    DEFINE lExiste INTEGER
    DEFINE rDatosTemp RECORD
        regimen     STRING,
        afiliatoria STRING,
        nss         STRING
    END RECORD
    DEFINE lregimen STRING
    DEFINE lvalidaCURP INTEGER

    DEFINE result_integracion_portabilidad INTEGER

    LET lExiste = 0

    IF r_ws1Entrada.inst_receptor <> "01" THEN
        CONNECT TO "dsipe"
        LET r_ws1Salida.codigo_resultado = "02"
        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(23)
        LET r_ws1Salida.observaciones    = "Estructura de datos incorrecta - Instituto receptor ej. 01 "
        DISCONNECT CURRENT
        RETURN r_ws1Salida
    END IF

    IF length(r_ws1Entrada.nss_imss) <> 11 THEN
        CONNECT TO "dsipe"
        LET r_ws1Salida.codigo_resultado = "02"
        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(23)
        LET r_ws1Salida.observaciones    = "Estructura de datos incorrecta - Número de Seguridad Social ej. 01234567890 (11 Caracteres - Alfanúmerico)"
        DISCONNECT CURRENT
        RETURN r_ws1Salida
    END IF

    IF length(r_ws1Entrada.curp) <> 18 THEN
        CONNECT TO "dsipe"
        LET r_ws1Salida.codigo_resultado = "02"
        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(23)
        LET r_ws1Salida.observaciones    = "Estructura de datos incorrecta - CURP ej. AAAAYYMMDDHMNNVR04 (18 Caracteres - Alfanúmerico)"
        DISCONNECT CURRENT
        RETURN r_ws1Salida
    END IF

    IF r_ws1Entrada.curp IS NULL                 OR
       r_ws1Entrada.fecha_inicio_tramite IS NULL OR
       r_ws1Entrada.inst_receptor IS NULL        OR
       r_ws1Entrada.nss_imss IS NULL THEN
       
        LET r_ws1Salida.codigo_resultado = "02"
        CONNECT TO "dsipe"
            LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(23)
            LET r_ws1Salida.observaciones    = fnDescripcionRechazo(23)
        DISCONNECT CURRENT
        RETURN r_ws1Salida
    END IF

    IF length(r_ws1Entrada.correo) = 0 OR r_ws1Entrada.correo IS NULL THEN
        LET r_ws1Entrada.correo = "dummy@dummy.com"
    END IF

    IF validaFechaInicio(r_ws1Entrada.fecha_inicio_tramite) = FALSE THEN
        LET r_ws1Salida.codigo_resultado = "02"
        CONNECT TO "dsipe"
            LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(23)
            LET r_ws1Salida.observaciones    = "El formato de la fecha de inicio de trámite no es válida, formato: DD/MM/YYYY HH:MM:SS"
        DISCONNECT CURRENT
        RETURN r_ws1Salida
    END IF

    CONNECT TO "dsipe"

        IF cuentaCURP(r_ws1Entrada.curp) > 1 THEN
            CALL fnRecuperaDatosDirecto2(r_ws1Entrada.curp) RETURNING lSolicitud.nombre,
                                                                     lSolicitud.num_issste,
                                                                     lSolicitud.primer_apellido,
                                                                     lSolicitud.segundo_apellido,
                                                                     lSolicitud.fecha_baja,
                                                                     rDatosTemp.afiliatoria,
                                                                     rDatosTemp.nss
            IF lSolicitud.nombre IS NOT NULL THEN
                LET lSolicitud.curp             = r_ws1Entrada.curp
                LET lSolicitud.correo           = r_ws1Entrada.correo
                LET lSolicitud.fecha_solicitud  = CURRENT YEAR TO SECOND
                LET lSolicitud.id_aplicacion    = r_ws1Entrada.inst_receptor
                LET lSolicitud.nss_imss         = r_ws1Entrada.nss_imss
                LET lSolicitud.id_tiposolicitud = 2
                LET lSolicitud.id_estatus       = 2
                LET lSolicitud.observaciones    = "Proceso iniciado desde IMSS a traves de WS1 fecha: "||lSolicitud.fecha_solicitud
                LET lSolicitud.folio_solicitud  = fnGenerarFolioSolicitud()
                IF fnGuardarSolicitud_cei_solicitud_inicial(lSolicitud) = TRUE THEN
                    UPDATE cei_solicitud
                       SET id_motivorechazo = 30
                     WHERE folio_solicitud  = lSolicitud.folio_solicitud
                END IF
            END IF
            LET r_ws1Salida.codigo_resultado = "02"
            LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(30)
            LET r_ws1Salida.observaciones    = fnDescripcionRechazo(30)
            LET lSolicitud.id_motivorechazo  = 30
            CALL fnInserta_cei_td_ws1_basica_otra(lSolicitud)
            RETURN r_ws1Salida
        END IF

        
        CALL cierraSolicitudes(r_ws1Entrada.curp)
        
--        LET SQL1 = " SELECT COUNT(*)",
--                   "   FROM cei_solicitud",
--                   "  WHERE curp = '", r_ws1Entrada.curp, "'",
--                   "    AND id_estatus = 3"
--        PREPARE select_cei_solicitud_issste_existe_previo FROM SQL1
--        EXECUTE select_cei_solicitud_issste_existe_previo INTO lExiste
--
--        IF lExiste > 0 THEN
--            CALL fnRecuperaDatosSolicitud(r_ws1Entrada.curp) RETURNING lSolicitud.*
--            --LET SQL1 = " UPDATE cei_solicitud",
--            --           "    SET id_estatus    = 2,",
--            --           "        observaciones = '", lSolicitud.observaciones||SFMT("Cancelada por Reproceso %1'",CURRENT YEAR TO SECOND),
--            --           "  WHERE folio_solicitud = ", lSolicitud.folio_solicitud
--            --PREPARE update_cei_solicitud_reproceso_portabilidad FROM SQL1
--            --EXECUTE update_cei_solicitud_reproceso_portabilidad
--            LET SQL1 = " UPDATE cuenta_ind",
--                       "    SET uso_pen    = NULL",
--                       "  WHERE num_issste = ", lSolicitud.num_issste,
--                       "    AND uso_pen    = 410"
--            PREPARE update_cuenta_ind_reproceso_uso_pen_410 FROM SQL1
--            EXECUTE update_cuenta_ind_reproceso_uso_pen_410
--            INITIALIZE lSolicitud.* TO NULL
--        END IF
    
        CALL fnRecuperaDatosDirecto(r_ws1Entrada.curp) RETURNING lSolicitud.nombre,
                                                                 lSolicitud.num_issste,
                                                                 lSolicitud.primer_apellido,
                                                                 lSolicitud.segundo_apellido,
                                                                 lSolicitud.fecha_baja,
                                                                 rDatosTemp.afiliatoria,
                                                                 rDatosTemp.nss
        IF lSolicitud.nombre IS NOT NULL THEN
            LET lSolicitud.curp            = r_ws1Entrada.curp
            LET lSolicitud.correo          = r_ws1Entrada.correo
            LET lSolicitud.fecha_solicitud = CURRENT YEAR TO SECOND
            LET lSolicitud.id_aplicacion   = r_ws1Entrada.inst_receptor
            LET lSolicitud.nss_imss        = r_ws1Entrada.nss_imss
            LET lSolicitud.id_tiposolicitud = 2
            LET lSolicitud.id_estatus       = 0
            LET lSolicitud.observaciones    = "Proceso iniciado desde IMSS a traves de WS1 fecha: "||lSolicitud.fecha_solicitud
            LET lSolicitud.folio_solicitud = fnGenerarFolioSolicitud()

            IF fnGuardarSolicitud_cei_solicitud_inicial(lSolicitud) = TRUE THEN

                IF rDatosTemp.afiliatoria IS NULL OR rDatosTemp.afiliatoria = "" THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(30)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(30)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 30,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF
                CASE rDatosTemp.afiliatoria
                    WHEN "A"
                        LET rDatosTemp.afiliatoria = "ACTIVO"
                    WHEN "B"
                        LET rDatosTemp.afiliatoria = "BAJA"
                    WHEN "F"
                        LET rDatosTemp.afiliatoria = "FINADO"
                END CASE
                IF rDatosTemp.afiliatoria = "ACTIVO" THEN
                    IF fnEsActivoUnicamenteYcotizaFondodePensiones(lSolicitud.num_issste) = FALSE THEN
                        LET r_ws1Salida.codigo_resultado = "02"
                        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(26)
                        LET r_ws1Salida.observaciones    = fnDescripcionRechazo(26)
                        CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 26,2)
                        DISCONNECT CURRENT
                        RETURN r_ws1Salida
                    END IF
                END IF
                IF rDatosTemp.afiliatoria = "FINADO" THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(29)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(29)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 29,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                CALL fnRecuperaRegimen(r_ws1Entrada.curp, lSolicitud.num_issste)
                                                             RETURNING rDatosTemp.regimen
                LET lregimen = validaRegimen(lSolicitud.num_issste, lSolicitud.curp)
                CASE lregimen
                    WHEN 1
                        LET r_ws1Salida.codigo_resultado = "02"
                        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(32)
                        CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 32,2)
                        DISCONNECT CURRENT
                        RETURN r_ws1Salida
                    WHEN 2
                        LET r_ws1Salida.codigo_resultado = "02"
                        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(31)
                        LET r_ws1Salida.observaciones    = fnDescripcionRechazo(31)
                        CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 31,2)
                        DISCONNECT CURRENT
                        RETURN r_ws1Salida
                END CASE
                LET lvalidaCURP = fnValidaCURP(lSolicitud.folio_solicitud, lSolicitud.num_issste, lSolicitud.curp, lSolicitud.fecha_solicitud)
                LET lvalidaCURP = 0
                IF lvalidaCURP = 2 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(27)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(27)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 27,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF lvalidaCURP = 3 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(28)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(28)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 28,2)
                    
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF fnValidaBeneficioPensionario(lSolicitud.curp) <> 0 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(33)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(33)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 33,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF presentaMarca200o300(lSolicitud.num_issste) <> 0 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(34)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(34)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 34,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF periodosMarca400_430(lSolicitud.num_issste) <> 0 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(36)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(36)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 36,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF usuariosInvalidos(lSolicitud.num_issste) <> 0 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(37)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(37)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 37,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF sueldomenor90(lSolicitud.num_issste) <> 0 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(37)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(37)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 37,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF antiguedad_cotizante_fondo_pensiones(lSolicitud.num_issste) < 1 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(38)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(38)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 38,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF


                IF vigenteal31032007sinbonopension(lSolicitud.num_issste) <> 0 THEN
                    LET r_ws1Salida.codigo_resultado = "02"
                    LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(39)
                    LET r_ws1Salida.observaciones    = fnDescripcionRechazo(39)
                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 39,2)
                    DISCONNECT CURRENT
                    RETURN r_ws1Salida
                END IF

                IF bonopension_fechaingresoposterior31032007_sinHLprevia(lSolicitud.num_issste) <> 0 THEN
                    IF periodosconsistentes(lSolicitud.num_issste) <> 0  OR periodosconsistentes_campos_auditores(lSolicitud.num_issste) <> 0 THEN
                        LET r_ws1Salida.codigo_resultado = "02"
                        LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(40)
                        LET r_ws1Salida.observaciones    = fnDescripcionRechazo(40)
                        CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 40,2)
                        DISCONNECT CURRENT
                        RETURN r_ws1Salida
                    END IF
                END IF

                CALL fnInserta_cei_td_ws1_basica_otra(lSolicitud.*)

                CALL f_actualiza_solicitud(NULL,1,lSolicitud.folio_solicitud)
                LET result_integracion_portabilidad = 1
                LET r_ws1Salida.codigo_resultado = "01"
                LET r_ws1Salida.curp             = lSolicitud.curp
                LET r_ws1Salida.fecha_baja       = lSolicitud.fecha_baja
                IF length(r_ws1Salida.fecha_baja.trim()) = 0 THEN
                    CALL fnObtieneFechaBaja(lSolicitud.num_issste) RETURNING lSolicitud.fecha_baja
                    LET r_ws1Salida.fecha_baja       = lSolicitud.fecha_baja
                END IF
                LET r_ws1Salida.nss              = rDatosTemp.nss
                LET r_ws1Salida.nombre           = lSolicitud.nombre CLIPPED
                LET r_ws1Salida.primer_apellido  = lSolicitud.primer_apellido CLIPPED
                LET r_ws1Salida.segundo_apellido = lSolicitud.segundo_apellido CLIPPED
                LET r_ws1Salida.observaciones    = lSolicitud.observaciones CLIPPED
                DISCONNECT CURRENT
                RETURN r_ws1Salida
            END IF
        ELSE
            LET r_ws1Salida.codigo_resultado = "02"
            LET r_ws1Salida.motivo_rechazo   = fnMotivoRechazo(24)
            LET r_ws1Salida.observaciones    = fnDescripcionRechazo(24)
        END IF
    DISCONNECT CURRENT
    RETURN r_ws1Salida
END FUNCTION

FUNCTION fnRecuperaDatosDirecto(lcurp)
    DEFINE lcurp STRING
    DEFINE rDirecto RECORD LIKE directo.*
    DEFINE SQL1 STRING
    DEFINE nss STRING

    LET SQL1 = " SELECT *",
               "   FROM directo",
               "  WHERE curp = '", lcurp, "'",
               "    AND t_directo <> 'ER'"
    PREPARE select_datos_directo_02 FROM SQL1
    EXECUTE select_datos_directo_02 INTO rDirecto.*

    LET nss = rDirecto.nss
    IF nss MATCHES "*[.0]" THEN
        LET nss = nss.subString(1, nss.getLength()-2)
    END IF
    
    RETURN rDirecto.nombre, rDirecto.num_issste, rDirecto.apellido_paterno,
           rDirecto.apellido_materno, rDirecto.fecha_baja, rDirecto.dto_estado, nss
END FUNCTION

FUNCTION fnRecuperaDatosDirecto2(lcurp)
    DEFINE lcurp STRING
    DEFINE rDirecto RECORD LIKE directo.*
    DEFINE SQL1 STRING
    DEFINE nss STRING

    LET SQL1 = " SELECT FIRST 1 *",
               "   FROM directo",
               "  WHERE curp = '", lcurp, "'",
               "    AND t_directo <> 'ER'"
    PREPARE select_datos_directo_03 FROM SQL1
    EXECUTE select_datos_directo_03 INTO rDirecto.*

    LET nss = rDirecto.nss
    IF nss MATCHES "*[.0]" THEN
        LET nss = nss.subString(1, nss.getLength()-2)
    END IF
    
    RETURN rDirecto.nombre, rDirecto.num_issste, rDirecto.apellido_paterno,
           rDirecto.apellido_materno, rDirecto.fecha_baja, rDirecto.dto_estado, nss
END FUNCTION

#############################
## llena COMBO tipo APLICACION
#############################
FUNCTION fnllenaComboCatAplicacion()
    DEFINE SQL1 STRING
    DEFINE rCatAplicacion RECORD LIKE cei_cat_aplicacion.*
    DEFINE cb ui.ComboBox

    CALL ui.ComboBox.forName("id_aplicacion") RETURNING cb
    
    LET SQL1 = "\n SELECT *",
               "\n   FROM cei_cat_aplicacion"
    PREPARE select_cat_aplicacion FROM SQL1
    DECLARE curCatAplicacion CURSOR FOR select_cat_aplicacion
    CALL cb.clear()
    FOREACH curCatAplicacion INTO rCatAplicacion.*
        CALL cb.addItem(rCatAplicacion.id_aplicacion,rCatAplicacion.abreviatura||" ("||rCatAplicacion.abreviatura||")")
    END FOREACH
     
END FUNCTION


#############################
## llena COMBO tipo SOLICITUD
#############################
FUNCTION fnllenaComboCatTipoSolicitud()
    DEFINE SQL1 STRING
    DEFINE rCatTipoSolicitud RECORD LIKE cei_cat_tiposolicitud.*
    DEFINE cb ui.ComboBox

    CALL ui.ComboBox.forName("id_tiposolicitud") RETURNING cb
    
    LET SQL1 = "\n SELECT *",
               "\n   FROM cei_cat_tiposolicitud"
    PREPARE select_cat_tipo_solicitud FROM SQL1
    DECLARE curCatTipoSolicitud CURSOR FOR select_cat_tipo_solicitud
    CALL cb.clear()
    FOREACH curCatTipoSolicitud INTO rCatTipoSolicitud.*
        CALL cb.addItem(rCatTipoSolicitud.id_tiposolicitud,rCatTipoSolicitud.descripcion)
    END FOREACH
END FUNCTION


######################
## ACTUALIZA SOLICITUD
######################
FUNCTION  f_actualiza_solicitud(l_idrechazo,l_estatus,l_solicitud) 
	DEFINE SQL1         STRING       
    DEFINE l_idrechazo  INTEGER 
    DEFINE l_estatus    INTEGER 
	DEFINE l_solicitud  LIKE cei_solicitud.folio_solicitud

    IF l_idrechazo IS NOT NULL THEN
        LET SQL1 = " UPDATE cei_solicitud",
                   "    SET id_motivorechazo = ", l_idrechazo,
                   "      , id_estatus       = ", l_estatus,
                   "  WHERE folio_solicitud  = ", l_solicitud
    ELSE
        LET SQL1 = " UPDATE cei_solicitud",
                   "    SET id_estatus       = ", l_estatus,
                   "  WHERE folio_solicitud  = ", l_solicitud
    END IF
    PREPARE sid_actualiza FROM SQL1
    EXECUTE sid_actualiza
    
END FUNCTION


##############################
## obtiene DESCRIPCION RECHAZO
##############################
FUNCTION fnDescripcionRechazo(lid_motivorechazo)
    DEFINE lid_motivorechazo INTEGER
    DEFINE ldescripcion STRING
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT observaciones",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", lid_motivorechazo
    PREPARE select_descripcion_motivorechazo FROM SQL1
    EXECUTE select_descripcion_motivorechazo INTO ldescripcion
    
    RETURN ldescripcion
END FUNCTION

FUNCTION fnMotivoRechazo(lid_motivorechazo)
    DEFINE lid_motivorechazo INTEGER
    DEFINE lmotivo_rechazo STRING
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT motivo_rechazo",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", lid_motivorechazo
    PREPARE select_descripcion_motivorechazo02 FROM SQL1
    EXECUTE select_descripcion_motivorechazo02 INTO lmotivo_rechazo

    
    RETURN lmotivo_rechazo
END FUNCTION


#####################
## DESCARGA SOLICITUD
#####################
FUNCTION fnDescargarSolicitud(l_val_cer)
    DEFINE l_val_cer STRING

    LET l_val_cer = l_val_cer||"_certificadaSAT.pdf"
    
    OPEN WINDOW vtnDescargarSolicitud WITH FORM "fDescargarSolicitud" ATTRIBUTES(STYLE="dialog")
        MENU
            BEFORE MENU
                DISPLAY l_val_cer TO documento_descargar
                
            ON ACTION btn_descargar
                CALL fgl_putfile(l_val_cer, l_val_cer)
                
            ON ACTION CANCEL
                EXIT MENU
        END MENU
    CLOSE WINDOW vtnDescargarSolicitud
END FUNCTION


###############################
## from fglprofile GET ENDPOINT
###############################
FUNCTION get_endpoint_ws(ws_alias)

    DEFINE ws_alias STRING
    DEFINE ws_entry STRING
    DEFINE ws_url   STRING
    DEFINE msg_err  STRING

    LET ws_entry=SFMT("ws.%1.url",ws_alias)
    
    CALL fgl_getresource(ws_entry) RETURNING ws_url

    IF ws_url.getLength()=0 THEN
       LET msg_err=SFMT("ERROR: entry '%1' not found in FGLPROFILE",ws_entry)
    END IF
    
    RETURN ws_url

END FUNCTION


###################
## recupera REGIMEN
###################
FUNCTION fnRecuperaRegimen(lcurp, lnum_issste)
    DEFINE lcurp STRING
    DEFINE lnum_issste INTEGER
    DEFINE lregimen STRING
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT tipo_regimen",
               "   FROM cat_regimen",
               "  WHERE tipo_regimen =",
               " (SELECT cve_regimen",
               "   FROM eleccion",
               "  WHERE curp = '", lcurp, "'",
               "    AND num_issste = ", lnum_issste,
               ")"
    PREPARE select_regimenord_01 FROM SQL1
    EXECUTE select_regimenord_01 INTO lregimen
    CASE lregimen
        WHEN "RO"
            LET lregimen = "REGIMEN ORDINARIO"
        WHEN "DT"
            LET lregimen = "REGIMEN DECIMO TRANSITORIO"
        WHEN "IN"
            LET lregimen = "REGIMEN INACTIVO"
    END CASE

    RETURN lregimen
END FUNCTION


###################
## solicitud EXISTE
###################
FUNCTION fnExisteSolicitud(lSolicitud)
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    DEFINE SQL1    STRING
    DEFINE lExiste INTEGER

    LET lExiste = 0
    LET SQL1 = "\n SELECT COUNT(*)",
               "\n   FROM cei_solicitud",
               "\n  WHERE curp = '", lSolicitud.curp, "'"
              ,"\n    AND id_estatus = 3"
    PREPARE select_existe_solicitud_01 FROM SQL1
    EXECUTE select_existe_solicitud_01 INTO lExiste

    IF lExiste > 0 THEN
        RETURN TRUE
    END IF
    
    RETURN FALSE
END FUNCTION


##############################
## actualiza ESTATUS SOLICITUD
##############################
FUNCTION fnActualizaEstatusSolicitud(folio_solicitud, id_motivorechazo, id_estatus)
    DEFINE folio_solicitud  INTEGER
    DEFINE id_motivorechazo INTEGER
    DEFINE id_estatus       INTEGER
    DEFINE lobservaciones   STRING
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT observaciones",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", id_motivorechazo
    PREPARE select_observaciones_motivorechazo FROM SQL1
    EXECUTE select_observaciones_motivorechazo INTO lobservaciones
    
    LET SQL1 = " UPDATE cei_solicitud",
               "   SET id_motivorechazo = ", id_motivorechazo, 
               "     , id_estatus       = ", id_estatus,
               "     , observaciones    = '", lobservaciones, "'",
               "  WHERE folio_solicitud = ", folio_solicitud
    PREPARE select_estatus_solicitud FROM SQL1
    EXECUTE select_estatus_solicitud
END FUNCTION


#################
## valida REGIMEN
#################
FUNCTION validaRegimen(lnum_issste, lCURP)
DEFINE lnum_issste  DECIMAL(8,0)
DEFINE lCURP        STRING
DEFINE lRegimen     STRING
DEFINE SQL1         STRING

    LET SQL1 = " SELECT cve_regimen",
               "   FROM eleccion",
               "  WHERE num_issste = ", lnum_issste,
               "    AND curp       = '", lCURP, "'"
    PREPARE select_regimenord FROM SQL1
    EXECUTE select_regimenord INTO lRegimen

    CASE lRegimen
        WHEN "RO"
            RETURN 0
        WHEN "DT"
            RETURN 1
        OTHERWISE
            RETURN 2
    END CASE

    RETURN 0
END FUNCTION

FUNCTION fnValidaCURP(lfolio_solicitud, lnum_issste, lCURP, lfecha_solicitud)
    DEFINE lfolio_solicitud BIGINT
    DEFINE lnum_issste  DECIMAL(8,0)
    DEFINE lCURP        STRING
    DEFINE lfecha_solicitud DATETIME YEAR TO SECOND
    DEFINE cmdrun       STRING
    DEFINE lrCurp RECORD
        curp               STRING,
        apellido_paterno   STRING,
        apellido_materno   STRING,
        nombre             STRING,
        sexo               STRING,
        fecha_nacimiento   STRING,
        entidad_nacimiento STRING,
        nacionalidad       STRING,
        statusCurp         STRING,
        nivelConfiabilidad STRING,
        curpHistoricas     STRING,
        tipo_error         STRING,
        CodigoError        STRING,
        estatus_operacion  STRING,
        rfc                STRING,
        crip               STRING
    END RECORD
    DEFINE file_incurp  base.Channel
    DEFINE SQL1         STRING
    DEFINE lDirecto     RECORD LIKE directo.*
    
    LET cmdrun = "fglrun rCURP.42r '",lCURP, "'"
    DISPLAY cmdrun
    RUN cmdrun

    TRY
        CALL base.Channel.create() RETURNING file_incurp
        CALL file_incurp.openFile("fileoutcurp"||lCURP||".txt","r")
        LET lrCurp.curp               = file_incurp.readLine()
        LET lrCurp.apellido_paterno   = file_incurp.readLine()
        LET lrCurp.apellido_materno   = file_incurp.readLine()
        LET lrCurp.nombre             = file_incurp.readLine()
        LET lrCurp.sexo               = file_incurp.readLine()
        LET lrCurp.fecha_nacimiento   = file_incurp.readLine()
        LET lrCurp.entidad_nacimiento = file_incurp.readLine()
        LET lrCurp.nacionalidad       = file_incurp.readLine()
        LET lrCurp.statusCurp         = file_incurp.readLine()
        LET lrCurp.nivelConfiabilidad = file_incurp.readLine()
        LET lrCurp.curpHistoricas     = file_incurp.readLine()
        LET lrCurp.tipo_error         = file_incurp.readLine()
        LET lrCurp.CodigoError        = file_incurp.readLine()
        LET lrCurp.estatus_operacion  = file_incurp.readLine()
        LET lrCurp.rfc                = file_incurp.readLine()
        CALL file_incurp.close()
    CATCH
    END TRY


    IF fgl_getenv("OS")= "Windows_NT" THEN
        RUN "del *.txt"
    ELSE
        RUN "rm *.txt"
    END IF

    LET SQL1 = "\n SELECT *",
               "\n   FROM directo",
               "\n  WHERE num_issste = ", lnum_issste
    PREPARE select_directo_02 FROM SQL1
    EXECUTE select_directo_02 INTO lDirecto.*

    IF (lrCurp.curp IS NULL OR lrCurp.curp = "") THEN
        RETURN 2
    END IF

    IF (lrCurp.curp <> lDirecto.curp CLIPPED) THEN
        RETURN 2
    END IF
    IF (lrCurp.apellido_materno <> lDirecto.apellido_materno) THEN
        RETURN 2
    END IF
    IF (lrCurp.apellido_paterno <> lDirecto.apellido_paterno) THEN
        RETURN 2
    END IF
    IF (lrCurp.entidad_nacimiento <> lDirecto.ent_cve) THEN
        RETURN 2
    END IF
    IF (lrCurp.nombre <> lDirecto.nombre) THEN
        RETURN 2
    END IF
    IF (lrCurp.sexo <> lDirecto.sexo) THEN
        RETURN 2
    END IF
    IF (lrCurp.fecha_nacimiento <> lDirecto.fec_nac) THEN
        RETURN 2
    END IF
    IF lrCurp.statusCurp = "BD" OR
       lrCurp.statusCurp = "BSU" OR
       lrCurp.statusCurp = "BAP" OR
       lrCurp.statusCurp = "BDM" OR
       lrCurp.statusCurp = "BDP" OR
       lrCurp.statusCurp = "BDJ"
    THEN
        RETURN 3
    END IF
    CALL fnGuardarCURP(lrCurp.*, lfolio_solicitud, lfecha_solicitud)

    RETURN 0
END FUNCTION

FUNCTION fnGuardarCURP(lrCurp, lfolio_solicitud, lfecha_solicitud)
    DEFINE lrCurp RECORD
        curp               STRING,
        apellido_paterno   STRING,
        apellido_materno   STRING,
        nombre             STRING,
        sexo               STRING,
        fecha_nacimiento   STRING,
        entidad_nacimiento STRING,
        nacionalidad       STRING,
        statusCurp         STRING,
        nivelConfiabilidad STRING,
        curpHistoricas     STRING,
        tipo_error         STRING,
        CodigoError        STRING,
        estatus_operacion  STRING,
        rfc                STRING,
        crip               STRING
    END RECORD
    DEFINE lfolio_solicitud BIGINT
    DEFINE lfecha_solicitud DATETIME YEAR TO SECOND
    DEFINE SQL1 STRING

    LET SQL1 = " INSERT INTO cei_td_wsrenapo(folio_solicitud, fecha_consulta,",
               " curp_vigente, primer_apellido, segundo_apellido, nombre, sexo,",
               " fecha_nac, entidad_nac, nacionalidad, estatus_curp, nivel_confiabilidad,",
               " curp_historica, tipo_error, codigo_error, estatus_operacion) ",
               "   VALUES (",
                         "'", lfolio_solicitud, "'"
                       , ",'", lfecha_solicitud, "'"
                       , ",'", lrCurp.curp CLIPPED, "'"
                       , ",'", lrCurp.apellido_paterno CLIPPED, "'"
                       , ",'", lrCurp.apellido_materno CLIPPED, "'"
                       , ",'", lrCurp.nombre, "'"
                       , ",'", lrCurp.sexo, "'"
                       , ",'", lrCurp.fecha_nacimiento, "'"
                       , ",'", lrCurp.entidad_nacimiento, "'"
                       , ",'", lrCurp.nacionalidad, "'"
                       , ",'", lrCurp.statusCurp, "'"
                       , ",'", lrCurp.nivelConfiabilidad, "'"
                       , ",'", lrCurp.curpHistoricas, "'"
                       , ",'", lrCurp.tipo_error, "'"
                       , ",'", lrCurp.CodigoError, "'"
                       , ",'", lrCurp.estatus_operacion, "'"
                       , ")"
    PREPARE select_insert_into FROM SQL1
    EXECUTE select_insert_into
END FUNCTION

FUNCTION fnValidaEstatusDerechohabiente(lnum_issste)
    DEFINE lnum_issste DECIMAL(8,0)
    DEFINE SQL1        STRING
    DEFINE ldto_estado STRING

    LET SQL1 = " SELECT dto_estado",
               "   FROM directo",
               "  WHERE num_issste = ", lnum_issste
    PREPARE select_dto_estado_directo FROM SQL1
    EXECUTE select_dto_estado_directo INTO ldto_estado

    IF ldto_estado CLIPPED = "" OR ldto_estado IS NULL OR ldto_estado CLIPPED = " " THEN
        RETURN 1
    END IF

    CASE ldto_estado
        WHEN "A"
        WHEN "B"
        WHEN "F"
        OTHERWISE
            RETURN 2
    END CASE

    RETURN 0
END FUNCTION

FUNCTION fnValidaBeneficioPensionario(lcurp)
    DEFINE lcurp VARCHAR(18)
    DEFINE SQL1 STRING
    DEFINE lbeneficio INTEGER

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM tramite_dt",
               "  WHERE curp = '", lcurp, "'",
               "    AND cve_beneficio in (1,2,3)",
               "    AND estatus_tramite >= 22"
    PREPARE select_beneficiopensionario FROM SQL1
    EXECUTE select_beneficiopensionario INTO lbeneficio

    IF lbeneficio > 1 THEN
        RETURN 1
    END IF
    
    RETURN 0
END FUNCTION

FUNCTION presentaMarca200o300(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE luso_pen    INTEGER

    LET luso_pen = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND (uso_pen = 200 OR uso_pen = 300)"
    PREPARE select_cuenta_indperiodos200 FROM SQL1
    EXECUTE select_cuenta_indperiodos200 INTO luso_pen

    IF luso_pen > 0 THEN
        RETURN 1
    END IF

    RETURN 0
END FUNCTION

FUNCTION traslapeMarca100(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1 STRING
DEFINE fecha_inicio  DATE
DEFINE fecha_termino DATE
DEFINE uso_pen       INTEGER
DEFINE lcontar       INTEGER
DEFINE bndIG         SMALLINT
    
    LET SQL1 = " SELECT fecha_inicio, fecha_termino, uso_pen",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               " ORDER BY fecha_termino DESC"
    PREPARE select_cuenta_ind_01 FROM SQL1
    DECLARE curCuentaIndTraslapesIG CURSOR FOR select_cuenta_ind_01
    LET bndIG = FALSE
    FOREACH curCuentaIndTraslapesIG INTO fecha_inicio, fecha_termino, uso_pen
        IF uso_pen = 100 THEN
            LET bndIG = TRUE
            EXIT FOREACH
        END IF
    END FOREACH

    IF bndIG = TRUE THEN
        LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND fecha_inicio > '", fecha_termino, "'"
        PREPARE select_count_mas_registros FROM SQL1
        EXECUTE select_count_mas_registros INTO lcontar

        IF lcontar = 0 THEN
            RETURN 1
        END IF
    END IF

    RETURN 0
END FUNCTION

FUNCTION periodosMarca400_430(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar     INTEGER

    LET lcontar = 0
    LET SQL1 = " SELECT COUNT(*)",
                   "   FROM cuenta_ind",
                   "  WHERE num_issste = ", lnum_issste,
                   "    AND uso_pen BETWEEN 400 AND 430",
                   "    AND uso_pen <> 410" --Para re-portabilidad
        PREPARE select_cuenta_ind_periodos400 FROM SQL1
        EXECUTE select_cuenta_ind_periodos400 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF
    RETURN 0
END FUNCTION

#####################
## usuarios INVALIDOS
#####################
FUNCTION usuariosInvalidos(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar     INTEGER

    LET lcontar = 0
        LET SQL1 = "\n SELECT COUNT(*)",
                   "\n   FROM cuenta_ind",
                   "\n  INNER JOIN c_pagaduria ON c_pagaduria.num_ramo      = cuenta_ind.num_ramo",
                   "\n                        AND c_pagaduria.num_pagaduria = cuenta_ind.num_pagaduria",
                   "\n  INNER JOIN c_modalidad ON c_modalidad.mod_cve = c_pagaduria.mod_cve",
                   "\n  WHERE cuenta_ind.num_issste = ", lnum_issste,
                   "\n    AND (c_modalidad.pensiones   = 'T')",
                   "\n    AND cuenta_ind.uso_pen IS NULL",
                   "\n    AND UPPER(cuenta_ind.usuario) = 'RHDEZ'"
        PREPARE select_usuario_invalido00 FROM SQL1
        EXECUTE select_usuario_invalido00 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF

        LET lcontar = 0
        LET SQL1 = "\n SELECT COUNT(*)",
                   "\n   FROM cuenta_ind",
                   "\n  INNER JOIN c_pagaduria ON c_pagaduria.num_ramo      = cuenta_ind.num_ramo",
                   "\n                        AND c_pagaduria.num_pagaduria = cuenta_ind.num_pagaduria",
                   "\n  INNER JOIN c_modalidad ON c_modalidad.mod_cve = c_pagaduria.mod_cve",
                   "\n  WHERE cuenta_ind.num_issste = ", lnum_issste,
                   "\n    AND (c_modalidad.pensiones   = 'T')",
                   "\n    AND cuenta_ind.uso_pen IS NULL",
                   "\n    AND UPPER(cuenta_ind.usuario) LIKE 'SAVD%'"
        PREPARE select_usuario_invalido01 FROM SQL1
        EXECUTE select_usuario_invalido01 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF

        LET lcontar = 0
        LET SQL1 = " SELECT COUNT(*)",
                   "   FROM cuenta_ind",
                   "  INNER JOIN c_pagaduria ON c_pagaduria.num_ramo      = cuenta_ind.num_ramo",
                   "                        AND c_pagaduria.num_pagaduria = cuenta_ind.num_pagaduria",
                   "  INNER JOIN c_modalidad ON c_modalidad.mod_cve = c_pagaduria.mod_cve",
                   "  WHERE num_issste = ", lnum_issste,
                   "    AND uso_pen IS NULL",
                   "    AND (c_modalidad.pensiones   = 'T')",
                   "    AND NOT(", -- Preguntar si debe haber con A
                   "           UPPER(cuenta_ind.usuario) LIKE 'A%'",
                   "        OR UPPER(cuenta_ind.usuario) LIKE 'SPI%'",
                   "        OR UPPER(cuenta_ind.usuario) LIKE 'M%'",
                   "        OR UPPER(cuenta_ind.usuario) LIKE 'B%'",
                   "        OR UPPER(cuenta_ind.usuario) LIKE 'I%'",
                   "        OR cuenta_ind.usuario MATCHES '[0-9]*'",
                   "        OR UPPER(cuenta_ind.usuario) = 'TDIMSS'",
                   "        )"
        PREPARE select_usuario_invalido02 FROM SQL1
        EXECUTE select_usuario_invalido02 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF

    RETURN 0
END FUNCTION

FUNCTION sueldomenor90(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar     INTEGER

    LET lcontar = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND uso_pen IS NULL",
               "    AND sueldo_issste = .90"
    PREPARE select_cuenta_ind_04saldo90 FROM SQL1
    EXECUTE select_cuenta_ind_04saldo90 INTO lcontar

    IF lcontar > 0 THEN
        RETURN 1
    END IF

    RETURN 0
END FUNCTION

FUNCTION fechas_invertidas(lnum_issste)
DEFINE lnum_issste   DECIMAL(8,0)
DEFINE SQL1          STRING
DEFINE lcontar       INTEGER
DEFINE fecha_inicio  DATE
DEFINE fecha_termino DATE

    LET SQL1 = " SELECT fecha_inicio, fecha_termino",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste
    PREPARE select_cuenta_ind_invertidas FROM SQL1
    
    DECLARE curCuentaIndFechasInvertidas CURSOR FOR select_cuenta_ind_invertidas
    LET lcontar = 0
    FOREACH curCuentaIndFechasInvertidas INTO fecha_inicio, fecha_termino
        IF fecha_inicio > fecha_termino THEN
            LET lcontar = lcontar + 1
            EXIT FOREACH
        END IF
    END FOREACH

    IF lcontar > 0 THEN
        RETURN 1
    END IF
    
    RETURN 0
END FUNCTION

FUNCTION mismo_ramo_pagaduria_mismo_cierre_o_duplicados(lnum_issste)
DEFINE lnum_issste   DECIMAL(8,0)
DEFINE SQL1          STRING
DEFINE arrFechasMismoRamoPag       DYNAMIC ARRAY OF RECORD
        num_ramo         INTEGER,
        num_pagaduria    STRING,
        fecha_inicio     DATE,
        fecha_termino    DATE,
        t_motivo_cierre  STRING
    END RECORD

DEFINE num_ramo         INTEGER
DEFINE num_pagaduria    STRING
DEFINE t_motivo_cierre  STRING
DEFINE fecha_inicio     DATE
DEFINE fecha_termino    DATE
DEFINE idx              INTEGER
DEFINE idxi             INTEGER
DEFINE idxj             INTEGER

    LET SQL1 = " SELECT num_ramo, num_pagaduria, fecha_inicio, fecha_termino, t_movto_cierre",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               " ORDER BY fecha_termino"
    PREPARE select_cuenta_ind_mismoramopag FROM SQL1
        
    DECLARE curCuentaIndramopagdup CURSOR FOR select_cuenta_ind_mismoramopag
    LET idx = 1
    FOREACH curCuentaIndramopagdup INTO num_ramo, num_pagaduria, fecha_inicio, fecha_termino, t_motivo_cierre
        LET arrFechasMismoRamoPag[idx].num_ramo        = num_ramo
        LET arrFechasMismoRamoPag[idx].num_pagaduria   = num_pagaduria
        LET arrFechasMismoRamoPag[idx].fecha_inicio    = fecha_inicio
        LET arrFechasMismoRamoPag[idx].fecha_termino   = fecha_termino
        LET arrFechasMismoRamoPag[idx].t_motivo_cierre = t_motivo_cierre
        LET idx = idx + 1
    END FOREACH

    FOR idxi = 1 TO arrFechasMismoRamoPag.getLength()
        FOR idxj = idxi + 1 TO arrFechasMismoRamoPag.getLength()
            IF (arrFechasMismoRamoPag[idxi].num_ramo        = arrFechasMismoRamoPag[idxj].num_ramo)
           AND (arrFechasMismoRamoPag[idxi].num_pagaduria   = arrFechasMismoRamoPag[idxj].num_pagaduria)
           AND (arrFechasMismoRamoPag[idxi].t_motivo_cierre = arrFechasMismoRamoPag[idxj].t_motivo_cierre)
           AND (arrFechasMismoRamoPag[idxi].fecha_inicio = arrFechasMismoRamoPag[idxj].fecha_inicio)
           AND (arrFechasMismoRamoPag[idxi].fecha_termino = arrFechasMismoRamoPag[idxj].fecha_termino)
            THEN
                RETURN 1
            END IF
        END FOR
    END FOR

    RETURN 0
END FUNCTION

FUNCTION antiguedad_cotizante_fondo_pensiones(lnum_issste)
DEFINE lnum_issste   DECIMAL(8,0)
DEFINE antiguedad_cotizante INTEGER
    LET antiguedad_cotizante = 0

    CALL dias_cot(lnum_issste) RETURNING antiguedad_cotizante

    RETURN antiguedad_cotizante
END FUNCTION

FUNCTION dias_cot(lde_num_issste)
    DEFINE ld_fecha_inicio   DATE 
    DEFINE ld_fecha_termino  DATE 
    DEFINE lde_num_issste    DECIMAL(8,0)
    DEFINE dias,  meses,  anios, ttdias           INTEGER
    DEFINE ls_query    STRING
    DEFINE ls_existe   INTEGER
   DEFINE arr_tci   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cuenta_ind.fecha_inicio,
       ft      LIKE cuenta_ind.fecha_termino
   END RECORD
  DEFINE  vci     SMALLINT
  DEFINE  lUP      SMALLINT
    DEFINE uv       CHAR(1)
    DEFINE  ii      SMALLINT
    DEFINE  tdias   SMALLINT
    DEFINE msi_diasporBisiestos SMALLINT
    DEFINE  i       SMALLINT
    DEFINE SQL1     STRING


  
    INITIALIZE arr_tci TO NULL

    LET ls_query = " SELECT COUNT(*)       "
                  ,"   FROM cat_marcas_hl  "
                  ,"  WHERE id_marca = ?   "
                  ,"    AND stat_marca = 1 "
                  ,"    AND id_marca <> 410"  --Para re-portabilidad
    PREPARE pprExiste FROM ls_query
    
    LET SQL1 = " SELECT cuenta_ind.fecha_inicio, cuenta_ind.fecha_termino,",
               "        cuenta_ind.uso_pen, cuenta_ind.u_version, c_pagaduria.mod_cve", 
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",  
               "  WHERE cuenta_ind.num_issste    = ", lde_num_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --WS1 dias_cot
               -- Se obtienen los periodos posteriores a la ultima marca  de IG
               "    AND ((
                         cuenta_ind.fecha_inicio > (select MAX(cind2.fecha_termino) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)
                        AND (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)> 0 ) OR
                            (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100) = 0 )",
               " ORDER BY cuenta_ind.fecha_inicio"
    PREPARE select_cuenta_ind_dias_cotizados FROM SQL1
    DECLARE curCuentaIndPeriodos CURSOR FOR select_cuenta_ind_dias_cotizados
    LET vci = 1
    FOREACH curCuentaIndPeriodos INTO arr_tci[vci].*,lUP, uv
       EXECUTE pprExiste USING lUP INTO ls_existe
       IF (ls_existe != 0) THEN ELSE 
         LET vci = vci + 1
       END IF
    END FOREACH
    
    LET vci = vci - 1
    LET ld_fecha_inicio=arr_tci[1].fi

    LET ld_fecha_termino= arr_tci[arr_tci.getLength()].ft
    LET ii = 1
    LET ttdias  = 0
    LET msi_diasporBisiestos = 0
    FOR i = 0 + 1 TO vci
     
        IF arr_tci[i].ft IS NULL OR arr_tci[i].ft = "" THEN
           LET arr_tci[i].ft = TODAY
        END IF
    
       IF arr_tci[i].fi <  arr_tci[i].ft AND i = 1 THEN
          LET tdias = (arr_tci[i].ft - arr_tci[i].fi) + 1
          LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(arr_tci[i].fi, arr_tci[i].ft)
          LET ii = i
          LET ttdias = ttdias + tdias
          LET tdias = 0
       ELSE 
          IF arr_tci[i].fi < arr_tci[ii].ft AND arr_tci[i].ft <= arr_tci[ii].ft THEN
             LET ttdias = ttdias + tdias
             LET tdias = 0
             CONTINUE FOR
          END IF

          IF arr_tci[i].fi < arr_tci[ii].ft AND arr_tci[i].ft > arr_tci[ii].ft THEN
             LET tdias = (arr_tci[i].ft - ((arr_tci[ii].ft)+1)) + 1
             LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(arr_tci[ii].ft+1, arr_tci[i].ft)
             LET ii = i  
             LET ttdias = ttdias + tdias
             LET tdias = 0
          END IF
          IF arr_tci[i].fi >= arr_tci[ii].ft AND arr_tci[i].ft > arr_tci[ii].ft THEN
             LET tdias = (arr_tci[i].ft - arr_tci[i].fi) + 1
             LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(arr_tci[i].fi, arr_tci[i].ft)
             LET ii = i
             LET ttdias = ttdias + tdias
             LET tdias = 0
          END IF
       END IF
    END FOR  
    CALL cal_mdy22(ttdias)  RETURNING  anios, meses, dias 

     RETURN ttdias
     
  
END FUNCTION

FUNCTION f_DiasporBisiestos(ldt_fecha_inicio, ldt_fecha_fin)
DEFINE
  ldt_fecha_inicio DATE
 ,ldt_fecha_fin DATE
 ,ldt_fecha_aux DATE
 ,lc_fecha_aux CHAR(10)
 ,lsi_anio SMALLINT
 ,lsi_diasporBisiestos SMALLINT

    LET lsi_diasporBisiestos = 0
    LET lsi_anio = YEAR(ldt_fecha_inicio)
    WHILE lsi_anio <=YEAR(ldt_fecha_fin)
        IF fac_ad_bisiesto1(lsi_anio) THEN
            LET lc_fecha_aux="29/02/", lsi_anio USING "&&&&"
            LET ldt_fecha_aux=lc_fecha_aux
            IF ldt_fecha_inicio <= ldt_fecha_aux AND ldt_fecha_fin >= ldt_fecha_aux THEN
                LET lsi_diasporBisiestos = lsi_diasporBisiestos + 1
            END IF
        END IF
        LET lsi_anio = lsi_anio + 1
    END WHILE

  RETURN lsi_diasporBisiestos
END FUNCTION

FUNCTION cal_mdy22(li_dias)                     
DEFINE   li_dias, anios, meses, dias INTEGER
    LET anios = li_dias/360
    LET meses = (li_dias - (anios*360))/30
    LET dias = li_dias - (anios*360) - (meses*30)

    RETURN anios, meses, dias                   
END FUNCTION 


FUNCTION fac_ad_bisiesto1(li_anio)  	
DEFINE	li_anio,	li_bis_aux		INTEGER,
	    ls_bisiesto		SMALLINT
				
	LET ls_bisiesto = 0	
	#Obtener el modulo para saber si el anio de fec fin es bisiesto
 	LET li_bis_aux = li_anio MOD 4 
 				
 	IF li_bis_aux = 0 THEN	
 		# --- Es divisible entre 4 --- #			
 		LET li_bis_aux = li_anio MOD 100		
 		IF li_bis_aux <> 0 THEN
 			# --- No es divisible entre 100, es bisiesto --- #
 			LET ls_bisiesto = 1						
 		ELSE		
 			# --- Es divisible entre 100 --- #				
 			LET li_bis_aux = li_anio MOD 400
 						
 			IF li_bis_aux = 0 THEN 			
 				# --- Divisible entre 400, es bisiesto --- #
 				LET ls_bisiesto = 1								
 			ELSE
 				# --- No es divisible entre 400, no es bisiesto --- #
 				LET ls_bisiesto = 0
 			END IF
 		END IF		
 	END IF
 							
 	RETURN ls_bisiesto
 
END FUNCTION

FUNCTION vigenteal31032007sinbonopension(lnum_issste) --validacion 113 Inconsistencia en r�gimen pensionario (Activo LISSSTE sin Bono).
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar1     INTEGER
DEFINE lcontar2     INTEGER


    LET lcontar1 = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",  
               "  WHERE cuenta_ind.num_issste    = ", lnum_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --WS1 vigenteal31032007sinbonopension
               "    AND '31/03/2007' BETWEEN cuenta_ind.fecha_inicio AND cuenta_ind.fecha_termino"
    PREPARE select_antiguedadfondopensiones_01 FROM SQL1
    EXECUTE select_antiguedadfondopensiones_01 INTO lcontar1

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM bono_pension",
               " WHERE num_issste = ", lnum_issste
    PREPARE select_eleccion_bono FROM SQL1
    EXECUTE select_eleccion_bono INTO lcontar2

    -- Atencion correo 2024-01-12 13:00 hrs aprox
    --1 = VEGENTE y  0 = SIN BONO

    IF lcontar1 = 1 AND lcontar2 = 0 THEN -- Estuvo Vigente y Sin Bono
        RETURN 1 -- rechazo 113
    END IF
        
    RETURN 0
END FUNCTION

FUNCTION bonopension_fechaingresoposterior31032007_sinHLprevia(lnum_issste) --validacion 18- 218
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar     INTEGER

    LET lcontar = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM bono_pension",
               " WHERE num_issste = ", lnum_issste
    PREPARE select_bono_pension01 FROM SQL1
    EXECUTE select_bono_pension01 INTO lcontar
    DISPLAY "1.-fechaingresoposterior31032007"

    IF lcontar > 0 THEN
        RETURN 0 -- Pasa
    END IF

    LET lcontar = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste      = ", lnum_issste,
               "    AND fecha_inicio    > '31/03/2007'",
               "    AND t_movto_inicio  IN ('A','R')"
    PREPARE select_fecha_ingreso_posterior FROM SQL1
    EXECUTE select_fecha_ingreso_posterior INTO lcontar

    IF lcontar > 0 THEN

        LET lcontar = 0
        LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",  
               "  WHERE cuenta_ind.num_issste    = ", lnum_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --WS1 bonopension_fechaingresoposterior31032007_sinHLprevia
               "    AND cuenta_ind.fecha_inicio < '31/03/2007'",
               "    AND cuenta_ind.fecha_aud BETWEEN '31/03/2007' AND '30/09/2009'"
        PREPARE select_fecha_ingreso_posteriorsinHLprev01 FROM SQL1
        EXECUTE select_fecha_ingreso_posteriorsinHLprev01 INTO lcontar 

        IF lcontar > 0 THEN
            RETURN 1 -- 18- rechazo 218
        END IF
    END IF
    

    RETURN 0 -- Pasa
END FUNCTION

FUNCTION periodosconsistentes(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE arrPeriodok DYNAMIC ARRAY OF RECORD
    fecha_inicio     DATE,
    fecha_termino    DATE,
    t_movto_cierre   STRING
END RECORD
DEFINE fecha_inicio   DATE
DEFINE fecha_termino  DATE
DEFINE t_movto_cierre STRING
DEFINE idx            INTEGER
DEFINE idxi           INTEGER
DEFINE idxj           INTEGER
DEFINE lnum_ramo       DECIMAL
DEFINE lnum_pagaduria  STRING

    LET SQL1 = " SELECT DISTINCT num_ramo, num_pagaduria",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste
    PREPARE select_cuenta_ind_ramopagaduria FROM SQL1
    DECLARE curRamoPag CURSOR FOR select_cuenta_ind_ramopagaduria

    FOREACH curRamoPag INTO lnum_ramo, lnum_pagaduria
        LET SQL1 = " SELECT fecha_inicio, fecha_termino, t_movto_cierre",
                   "   FROM cuenta_ind",
                   "  WHERE num_issste = ", lnum_issste,
                   "    AND num_ramo = ", lnum_ramo,
                   "    AND num_pagaduria = '", lnum_pagaduria, "'",
                   " ORDER BY fecha_inicio"
        PREPARE select_cuenta_ind_periodosok FROM SQL1
            
        DECLARE curCuentaIndPeriodosok CURSOR FOR select_cuenta_ind_periodosok
        LET idx = 1
        CALL arrPeriodok.clear()
        FOREACH curCuentaIndPeriodosok INTO fecha_inicio, fecha_termino, t_movto_cierre
            LET arrPeriodok[idx].fecha_inicio    = fecha_inicio
            LET arrPeriodok[idx].fecha_termino   = fecha_termino
            LET arrPeriodok[idx].t_movto_cierre = t_movto_cierre
            LET idx = idx + 1
        END FOREACH

        IF arrPeriodok.getLength() > 1 THEN
            FOR idxi = 1 TO arrPeriodok.getLength()
                FOR idxj = idxi + 1 TO arrPeriodok.getLength()
                    IF arrPeriodok[idxj].fecha_termino IS NULL THEN
                        LET arrPeriodok[idxj].fecha_termino = TODAY
                    END IF
                    IF arrPeriodok[idxi].fecha_termino IS NULL THEN
                        LET arrPeriodok[idxi].fecha_termino = TODAY
                    END IF
                    IF (arrPeriodok[idxi].fecha_inicio > arrPeriodok[idxj].fecha_inicio)
                    OR(arrPeriodok[idxi].fecha_termino > arrPeriodok[idxj].fecha_termino) THEN
                     RETURN 1
                    END IF
                END FOR
            END FOR
        END IF
        
    END FOREACH

    RETURN 0
END FUNCTION

FUNCTION periodosconsistentes_campos_auditores(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar     INTEGER

    LET lcontar = 0
    
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",  
               "  WHERE cuenta_ind.num_issste    = ", lnum_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --WS1 periodosconsistentes_campos_auditores
               "    AND cuenta_ind.fecha_inicio < '31/03/2007'",
               "    AND cuenta_ind.fecha_aud BETWEEN '31/03/2007' AND '31/03/2009'"
    PREPARE select_cuenta_ind_periodosok_CA FROM SQL1
    EXECUTE select_cuenta_ind_periodosok_CA INTO lcontar

    IF lcontar > 0 THEN
        RETURN 1 --rechazo 114
    END IF

    RETURN 0 --Pasa
END FUNCTION

FUNCTION fnGenerarFoliocei_td_ws1_basica_otra()
    DEFINE SQL1 STRING
    DEFINE lFolioSolicitud BIGINT

    LET SQL1 = "\n SELECT NVL(MAX(folio_consulta),0) + 1",
               "\n    FROM cei_td_ws1_basica_otra"
    PREPARE select_folio_cei_td_ws1_basica_otra FROM SQL1
    EXECUTE select_folio_cei_td_ws1_basica_otra INTO lFolioSolicitud

    RETURN lFolioSolicitud
END FUNCTION

FUNCTION fnGenerarFolioSolicitud()
    DEFINE SQL1 STRING
    DEFINE lFolioSolicitud BIGINT

    --LET SQL1 = "\n SELECT NVL(MAX(folio_solicitud),0) + 1",
    --           "\n    FROM cei_solicitud"
    LET SQL1 = " SELECT seq_portabilidad.NEXTVAL",
               "   FROM systables",
               "  WHERE tabid = 1"
    PREPARE select_folio_cei_solicitud FROM SQL1
    EXECUTE select_folio_cei_solicitud INTO lFolioSolicitud

    RETURN lFolioSolicitud
END FUNCTION

FUNCTION fnGuardarSolicitud_cei_solicitud_inicial(lSolicitud)
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    DEFINE lbndGuardada SMALLINT
    DEFINE SQL1 STRING

    LET lbndGuardada = TRUE 
    TRY
        --CALL FGL_WINMESSAGE("Rastreo Portabilidad","Guardara en cei_solicitud","information")
        LET SQL1 = " INSERT INTO cei_solicitud(",
                                              "  folio_solicitud",
                                              ", id_tiposolicitud",
                                              ", id_aplicacion",
                                              ", fecha_solicitud",
                                              ", num_issste",
                                              ", nss_imss",
                                              ", curp",
                                              ", primer_apellido",
                                              ", segundo_apellido",
                                              ", nombre",
                                              ", fecha_baja",
                                              ", correo",
                                              ", telefono",
                                              ", usuario",
                                              ", ip_maquina",
                                              ", observaciones",
                                              --", id_motivorechazo",
                                              ", id_estatus",
                                              ")",
                 " VALUES (",
                                 lSolicitud.folio_solicitud,
                           ", ", lSolicitud.id_tiposolicitud,
                           ", ", lSolicitud.id_aplicacion,
                           ", '", lSolicitud.fecha_solicitud, "'",
                           ", ", lSolicitud.num_issste,
                           ", '", lSolicitud.nss_imss, "'",
                           ", '", lSolicitud.curp, "'",
                           ", '", lSolicitud.primer_apellido CLIPPED, "'",
                           ", '", lSolicitud.segundo_apellido CLIPPED, "'",
                           ", '", lSolicitud.nombre CLIPPED, "'",
                           ", '", lSolicitud.fecha_baja, "'",
                           ", '", lSolicitud.correo, "'",
                           ", '", lSolicitud.telefono, "'",
                           ", '", lSolicitud.usuario, "'",
                           ", '", lSolicitud.ip_maquina, "'",
                           ", '", lSolicitud.observaciones, "'",
                           --", ", lSolicitud.id_motivorechazo,
                           ", ", lSolicitud.id_estatus,
                 "        )"
        --DISPLAY "SQL1_cei_solicitud: ", SQL1
        PREPARE insert_cei_solicitud_00 FROM SQL1
        EXECUTE insert_cei_solicitud_00
        --INSERT INTO cei_solicitud VALUES(lSolicitud.*)

        --CALL FGL_WINMESSAGE("Rastreo Portabilidad","Guardara en cei_td_solicitud","information")
        LET SQL1 = "\n INSERT INTO cei_td_solicitud(folio_solicitud, inst_receptor, nss_imss, nss_issste, fecha_respuesta)",
                   "\n      VALUES(", lSolicitud.folio_solicitud,
                   --"\n           ,'", lSolicitud.id_tiposolicitud USING "&&", "'",
                   "\n           , '01'",
                   "\n           , '", lSolicitud.nss_imss,"'",
                   "\n           , '", lSolicitud.num_issste, "'",
                   "\n           , '", CURRENT YEAR TO SECOND, "'",
                   "\n )"
        PREPARE insert_cei_td_solcitud FROM SQL1
        EXECUTE insert_cei_td_solcitud
    CATCH
        LET lbndGuardada = FALSE
    END TRY
        
    RETURN lbndGuardada
END FUNCTION

FUNCTION fnGenerarFolioSolicitud_externo()
    DEFINE SQL1          STRING
    DEFINE lFolioExterno VARCHAR(50)

    LET SQL1 = "\n SELECT NVL(MAX(folio_externo),0) + 1",
               "\n   FROM cei_td_solicitud"
    PREPARE select_folio_externo_cie_td_solicitud FROM SQL1
    EXECUTE select_folio_externo_cie_td_solicitud INTO lFolioExterno
    
    LET lFolioExterno = lFolioExterno

    RETURN lFolioExterno
END FUNCTION

FUNCTION fnInserta_cei_td_ws1_basica_otra(lSolicitud)
    DEFINE lSolicitud              RECORD LIKE cei_solicitud.*
    DEFINE lcei_td_ws1_basica_otra RECORD LIKE cei_td_ws1_basica_otra.*
    DEFINE lid_motivorechazo       STRING

    --Genera Folio
    CALL fnGenerarFoliocei_td_ws1_basica_otra() RETURNING lcei_td_ws1_basica_otra.folio_consulta
    
    LET lcei_td_ws1_basica_otra.fecha_solicitud  = lSolicitud.fecha_solicitud
    LET lcei_td_ws1_basica_otra.inst_receptor    = lSolicitud.id_tiposolicitud
    LET lcei_td_ws1_basica_otra.nss_solicitado   = lSolicitud.nss_imss
    LET lcei_td_ws1_basica_otra.curp_solicitada  = lSolicitud.curp
    LET lcei_td_ws1_basica_otra.fecha_tramite    = lSolicitud.fecha_solicitud
    LET lcei_td_ws1_basica_otra.correo           = lSolicitud.correo
    LET lcei_td_ws1_basica_otra.curp_enviada     = lSolicitud.curp
    LET lcei_td_ws1_basica_otra.primer_apellido  = lSolicitud.primer_apellido
    LET lcei_td_ws1_basica_otra.segundo_apellido = lSolicitud.segundo_apellido
    LET lcei_td_ws1_basica_otra.nombre           = lSolicitud.nombre
    LET lcei_td_ws1_basica_otra.nss_issste       = lSolicitud.num_issste
    LET lcei_td_ws1_basica_otra.fecha_baja       = lSolicitud.fecha_baja
    LET lcei_td_ws1_basica_otra.observaciones    = lSolicitud.observaciones
    LET lcei_td_ws1_basica_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
    IF lSolicitud.id_motivorechazo IS NOT NULL THEN
        LET lid_motivorechazo = lSolicitud.id_motivorechazo
        LET lid_motivorechazo = lid_motivorechazo USING "&&"
        LET lcei_td_ws1_basica_otra.motivo_rechazo   = lid_motivorechazo
    END IF
    LET lcei_td_ws1_basica_otra.codigo_resultado = "01"
    
    INSERT INTO cei_td_ws1_basica_otra VALUES (lcei_td_ws1_basica_otra.*)
    
END FUNCTION

FUNCTION insertar_cei_td_ws5_procesarrechazo(lcei_td_ws5_procesarrechazo)
    DEFINE lcei_td_ws5_procesarrechazo RECORD LIKE cei_td_ws5_procesarrechazo.*

    INSERT INTO cei_td_ws5_procesarrechazo
        VALUES (lcei_td_ws5_procesarrechazo.*)
END FUNCTION

FUNCTION obtieneObservacionesdeActualizacion(lobservaciones, lsolicitud)
    DEFINE lsolicitud BIGINT
    DEFINE lobservaciones STRING
    DEFINE SQL1 STRING
    DEFINE nobservaciones STRING

    LET SQL1 = "SELECT observaciones",
               "  FROM cei_solicitud",
               " WHERE folio_solicitud = ", lsolicitud
    PREPARE select_observaciones FROM SQL1
    EXECUTE select_observaciones INTO nobservaciones

    IF nobservaciones IS NOT NULL THEN
        LET lobservaciones = nobservaciones
    END IF

    RETURN lobservaciones
END FUNCTION

FUNCTION dictamenBeneficioPensionario()
    DEFINE lbeneficio_pensionario INTEGER
    DEFINE lexiste INTEGER
    DEFINE SQL1 STRING

    LET lbeneficio_pensionario = 0
    LET lexiste = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM systables",
               "  where tabname = 'dictamenbeneficiopensionario'"
    PREPARE select_lexiste_tabla_dictamenbeneficiopensionario FROM SQL1
    EXECUTE select_lexiste_tabla_dictamenbeneficiopensionario INTO lexiste

    IF lexiste > 0 THEN
        LET SQL1 = " SELECT dictamen",
                   "   FROM dictamenbeneficiopensionario"
        PREPARE select_dictamen_beneficiopensionario FROM SQL1
        EXECUTE select_dictamen_beneficiopensionario INTO lbeneficio_pensionario
    ELSE
        LET SQL1 = " SELECT beneficio",
               "   FROM cei_beneficiopensionario"
        PREPARE select_beneficiopensionario01 FROM SQL1
        EXECUTE select_beneficiopensionario01 INTO lbeneficio_pensionario
    END IF
      
    IF lbeneficio_pensionario = 1 THEN
        RETURN 1
    END IF
    
    RETURN lbeneficio_pensionario
END FUNCTION

FUNCTION fnInsertaRobusta_otraws3(rRobusta_otra)
    DEFINE rRobusta_otra RECORD LIKE cei_td_ws3_robusta_otra.*
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT NVL(MAX(folio_consulta),0) + 1",
               "   FROM cei_td_ws3_robusta_otra"
    PREPARE select_max_folio_consulta FROM SQL1
    EXECUTE select_max_folio_consulta INTO rRobusta_otra.folio_externo
    LET rRobusta_otra.folio_consulta = rRobusta_otra.folio_externo

    INSERT INTO cei_td_ws3_robusta_otra VALUES(rRobusta_otra.*)
    
END FUNCTION

FUNCTION inserta_cei_td_ws3_robusta_periodos(lRobustaOtraPeriodos)
    DEFINE lRobustaOtraPeriodos RECORD LIKE cei_td_ws3_robusta_periodos.*
    DEFINE SQL1                 STRING

    LET SQL1 = " SELECT NVL(MAX(id_periodo_ws),0) + 1",
               "   FROM cei_td_ws3_robusta_periodos"
    PREPARE select_max_folio_periodo_ws FROM SQL1
    EXECUTE select_max_folio_periodo_ws INTO lRobustaOtraPeriodos.id_periodo_ws
    
    INSERT INTO cei_td_ws3_robusta_periodos
         VALUES (lRobustaOtraPeriodos.*)
END FUNCTION

FUNCTION fnEliminacionPeriodos(folio_solicitud)
    DEFINE folio_solicitud BIGINT
    DEFINE SQL1            STRING

    LET SQL1 = " DELETE FROM cei_td_ws3_robusta_periodos",
               "  WHERE folio_solicitud = ", folio_solicitud
    PREPARE delete_cei_td_ws3_robusta_periodos FROM SQL1
    EXECUTE delete_cei_td_ws3_robusta_periodos
END FUNCTION

FUNCTION fnInserta_cei_td_ws3_robusta(rRobusta)
    DEFINE rRobusta RECORD LIKE cei_td_ws3_robusta.*

    INSERT INTO cei_td_ws3_robusta
         VALUES (rRobusta.*)
END FUNCTION

FUNCTION fnObtieneanios(li_dias)
        DEFINE   li_dias,
                 anios,
                 meses,
                 dias    integer
        LET anios = li_dias/360
        LET meses = (li_dias - (anios*360))/30
        LET dias = li_dias - (anios*360) - (meses*30)

        IF (meses > 6 AND dias > 0) THEN
            LET anios = anios + 1
        END IF
        
     RETURN anios                   
END FUNCTION

FUNCTION fnInsertarProcesxarExito(rcei_td_ws4_procesarexito)
    DEFINE rcei_td_ws4_procesarexito RECORD LIKE cei_td_ws4_procesarexito.*

        INSERT INTO cei_td_ws4_procesarexito VALUES(rcei_td_ws4_procesarexito.*)
    
END FUNCTION

FUNCTION fnRecuperaDatosSolicitud(lCURP)
    DEFINE lCURP STRING
    DEFINE SQL1  STRING
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*

    LET SQL1 = " SELECT *",
               "   FROM cei_solicitud",
               "  WHERE curp = '", lCURP, "'",
               "    AND id_estatus = 3"
    PREPARE select_datos_cei_solicitud00 FROM SQL1
    EXECUTE select_datos_cei_solicitud00 INTO lSolicitud.*

    IF lSolicitud.num_issste IS NULL THEN
        LET SQL1 = " SELECT *",
                "   FROM cei_solicitud",
                "  WHERE curp = '", lCURP, "'",
                "    AND id_estatus = 1"
        PREPARE select_datos_cei_solicitud01 FROM SQL1
        EXECUTE select_datos_cei_solicitud01 INTO lSolicitud.*
    END IF

    RETURN lSolicitud.*
END FUNCTION

FUNCTION cuentaCURP(lcurp)
    DEFINE lcurp STRING
    DEFINE SQL1 STRING
    DEFINE lcontar INTEGER

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM directo",
               "  WHERE curp = '", lcurp, "'",
               "    AND t_directo <> 'ER'"
    PREPARE select_datos_directo_0000 FROM SQL1
    EXECUTE select_datos_directo_0000 INTO lcontar

    RETURN lcontar
END FUNCTION

FUNCTION validaFechaInicio(lfecha)
    DEFINE lfecha STRING
    DEFINE lyear  STRING

    IF lfecha.getLength() <> 19 THEN
        DISPLAY "vacio"
        RETURN FALSE
    END IF

    IF lfecha.subString(3,3) <> "/" OR lfecha.subString(6,6) <> "/"
    OR lfecha.subString(14,14) <> ":" OR lfecha.subString(17,17) <> ":" THEN
        DISPLAY "delimitadores"
        RETURN FALSE
    END IF

    IF lfecha.subString(1,2) <> "01" AND
       lfecha.subString(1,2) <> "02" AND
       lfecha.subString(1,2) <> "03" AND
       lfecha.subString(1,2) <> "04" AND
       lfecha.subString(1,2) <> "05" AND
       lfecha.subString(1,2) <> "06" AND
       lfecha.subString(1,2) <> "07" AND
       lfecha.subString(1,2) <> "08" AND
       lfecha.subString(1,2) <> "09" AND
       lfecha.subString(1,2) <> "10" AND
       lfecha.subString(1,2) <> "11" AND
       lfecha.subString(1,2) <> "12" AND
       lfecha.subString(1,2) <> "13" AND
       lfecha.subString(1,2) <> "14" AND
       lfecha.subString(1,2) <> "15" AND
       lfecha.subString(1,2) <> "16" AND
       lfecha.subString(1,2) <> "17" AND
       lfecha.subString(1,2) <> "18" AND
       lfecha.subString(1,2) <> "19" AND
       lfecha.subString(1,2) <> "20" AND
       lfecha.subString(1,2) <> "21" AND
       lfecha.subString(1,2) <> "22" AND
       lfecha.subString(1,2) <> "23" AND
       lfecha.subString(1,2) <> "24" AND
       lfecha.subString(1,2) <> "25" AND
       lfecha.subString(1,2) <> "26" AND
       lfecha.subString(1,2) <> "27" AND
       lfecha.subString(1,2) <> "28" AND
       lfecha.subString(1,2) <> "29" AND
       lfecha.subString(1,2) <> "30" AND
       lfecha.subString(1,2) <> "31"
    THEN
        DISPLAY "dias"
        RETURN FALSE
    END IF

    IF lfecha.subString(4,5) <> "01" AND
       lfecha.subString(4,5) <> "02" AND
       lfecha.subString(4,5) <> "03" AND
       lfecha.subString(4,5) <> "04" AND
       lfecha.subString(4,5) <> "05" AND
       lfecha.subString(4,5) <> "06" AND
       lfecha.subString(4,5) <> "07" AND
       lfecha.subString(4,5) <> "08" AND
       lfecha.subString(4,5) <> "09" AND
       lfecha.subString(4,5) <> "10" AND
       lfecha.subString(4,5) <> "11" AND
       lfecha.subString(4,5) <> "12"
    THEN
        DISPLAY "meses"
        RETURN FALSE
    END IF

    LET lyear = YEAR(TODAY)
    IF lfecha.subString(7,10) <> lyear THEN
        DISPLAY "años"
        RETURN FALSE
    END IF

    IF lfecha.subString(12,13) <> "00" AND
       lfecha.subString(12,13) <> "01" AND
       lfecha.subString(12,13) <> "02" AND
       lfecha.subString(12,13) <> "03" AND
       lfecha.subString(12,13) <> "04" AND
       lfecha.subString(12,13) <> "05" AND
       lfecha.subString(12,13) <> "06" AND
       lfecha.subString(12,13) <> "07" AND
       lfecha.subString(12,13) <> "08" AND
       lfecha.subString(12,13) <> "09" AND
       lfecha.subString(12,13) <> "10" AND
       lfecha.subString(12,13) <> "11" AND
       lfecha.subString(12,13) <> "12" AND
       lfecha.subString(12,13) <> "13" AND
       lfecha.subString(12,13) <> "14" AND
       lfecha.subString(12,13) <> "15" AND
       lfecha.subString(12,13) <> "16" AND
       lfecha.subString(12,13) <> "17" AND
       lfecha.subString(12,13) <> "18" AND
       lfecha.subString(12,13) <> "19" AND
       lfecha.subString(12,13) <> "20" AND
       lfecha.subString(12,13) <> "21" AND
       lfecha.subString(12,13) <> "22" AND
       lfecha.subString(12,13) <> "23" AND
       lfecha.subString(12,13) <> "24"
    THEN
        DISPLAY "horas"
        RETURN FALSE
    END IF

    IF lfecha.subString(15,16) <> "00" AND
       lfecha.subString(15,16) <> "01" AND
       lfecha.subString(15,16) <> "02" AND
       lfecha.subString(15,16) <> "03" AND
       lfecha.subString(15,16) <> "04" AND
       lfecha.subString(15,16) <> "05" AND
       lfecha.subString(15,16) <> "06" AND
       lfecha.subString(15,16) <> "07" AND
       lfecha.subString(15,16) <> "08" AND
       lfecha.subString(15,16) <> "09" AND
       lfecha.subString(15,16) <> "10" AND
       lfecha.subString(15,16) <> "11" AND
       lfecha.subString(15,16) <> "12" AND
       lfecha.subString(15,16) <> "13" AND
       lfecha.subString(15,16) <> "14" AND
       lfecha.subString(15,16) <> "15" AND
       lfecha.subString(15,16) <> "16" AND
       lfecha.subString(15,16) <> "17" AND
       lfecha.subString(15,16) <> "18" AND
       lfecha.subString(15,16) <> "19" AND
       lfecha.subString(15,16) <> "20" AND
       lfecha.subString(15,16) <> "21" AND
       lfecha.subString(15,16) <> "22" AND
       lfecha.subString(15,16) <> "23" AND
       lfecha.subString(15,16) <> "24" AND
       lfecha.subString(15,16) <> "25" AND
       lfecha.subString(15,16) <> "26" AND
       lfecha.subString(15,16) <> "27" AND
       lfecha.subString(15,16) <> "28" AND
       lfecha.subString(15,16) <> "29" AND
       lfecha.subString(15,16) <> "30" AND
       lfecha.subString(15,16) <> "31" AND
       lfecha.subString(15,16) <> "32" AND
       lfecha.subString(15,16) <> "33" AND
       lfecha.subString(15,16) <> "34" AND
       lfecha.subString(15,16) <> "35" AND
       lfecha.subString(15,16) <> "36" AND
       lfecha.subString(15,16) <> "37" AND
       lfecha.subString(15,16) <> "38" AND
       lfecha.subString(15,16) <> "39" AND
       lfecha.subString(15,16) <> "40" AND
       lfecha.subString(15,16) <> "41" AND
       lfecha.subString(15,16) <> "42" AND
       lfecha.subString(15,16) <> "43" AND
       lfecha.subString(15,16) <> "44" AND
       lfecha.subString(15,16) <> "45" AND
       lfecha.subString(15,16) <> "46" AND
       lfecha.subString(15,16) <> "47" AND
       lfecha.subString(15,16) <> "48" AND
       lfecha.subString(15,16) <> "49" AND
       lfecha.subString(15,16) <> "50" AND
       lfecha.subString(15,16) <> "51" AND
       lfecha.subString(15,16) <> "52" AND
       lfecha.subString(15,16) <> "53" AND
       lfecha.subString(15,16) <> "54" AND
       lfecha.subString(15,16) <> "55" AND
       lfecha.subString(15,16) <> "56" AND
       lfecha.subString(15,16) <> "57" AND
       lfecha.subString(15,16) <> "58" AND
       lfecha.subString(15,16) <> "59"
    THEN
        DISPLAY "minutos"
        RETURN FALSE
    END IF

    IF lfecha.subString(18,19) <> "00" AND
       lfecha.subString(18,19) <> "01" AND
       lfecha.subString(18,19) <> "02" AND
       lfecha.subString(18,19) <> "03" AND
       lfecha.subString(18,19) <> "04" AND
       lfecha.subString(18,19) <> "05" AND
       lfecha.subString(18,19) <> "06" AND
       lfecha.subString(18,19) <> "07" AND
       lfecha.subString(18,19) <> "08" AND
       lfecha.subString(18,19) <> "09" AND
       lfecha.subString(18,19) <> "10" AND
       lfecha.subString(18,19) <> "11" AND
       lfecha.subString(18,19) <> "12" AND
       lfecha.subString(18,19) <> "13" AND
       lfecha.subString(18,19) <> "14" AND
       lfecha.subString(18,19) <> "15" AND
       lfecha.subString(18,19) <> "16" AND
       lfecha.subString(18,19) <> "17" AND
       lfecha.subString(18,19) <> "18" AND
       lfecha.subString(18,19) <> "19" AND
       lfecha.subString(18,19) <> "20" AND
       lfecha.subString(18,19) <> "21" AND
       lfecha.subString(18,19) <> "22" AND
       lfecha.subString(18,19) <> "23" AND
       lfecha.subString(18,19) <> "24" AND
       lfecha.subString(18,19) <> "25" AND
       lfecha.subString(18,19) <> "26" AND
       lfecha.subString(18,19) <> "27" AND
       lfecha.subString(18,19) <> "28" AND
       lfecha.subString(18,19) <> "29" AND
       lfecha.subString(18,19) <> "30" AND
       lfecha.subString(18,19) <> "31" AND
       lfecha.subString(18,19) <> "32" AND
       lfecha.subString(18,19) <> "33" AND
       lfecha.subString(18,19) <> "34" AND
       lfecha.subString(18,19) <> "35" AND
       lfecha.subString(18,19) <> "36" AND
       lfecha.subString(18,19) <> "37" AND
       lfecha.subString(18,19) <> "38" AND
       lfecha.subString(18,19) <> "39" AND
       lfecha.subString(18,19) <> "40" AND
       lfecha.subString(18,19) <> "41" AND
       lfecha.subString(18,19) <> "42" AND
       lfecha.subString(18,19) <> "43" AND
       lfecha.subString(18,19) <> "44" AND
       lfecha.subString(18,19) <> "45" AND
       lfecha.subString(18,19) <> "46" AND
       lfecha.subString(18,19) <> "47" AND
       lfecha.subString(18,19) <> "48" AND
       lfecha.subString(18,19) <> "49" AND
       lfecha.subString(18,19) <> "50" AND
       lfecha.subString(18,19) <> "51" AND
       lfecha.subString(18,19) <> "52" AND
       lfecha.subString(18,19) <> "53" AND
       lfecha.subString(18,19) <> "54" AND
       lfecha.subString(18,19) <> "55" AND
       lfecha.subString(18,19) <> "56" AND
       lfecha.subString(18,19) <> "57" AND
       lfecha.subString(18,19) <> "58" AND
       lfecha.subString(18,19) <> "59"
    THEN
        DISPLAY "segundos"
        RETURN FALSE
    END IF

    RETURN TRUE
    
END FUNCTION

FUNCTION f_validaEstructuraEmail(lv_cuentaMail)
DEFINE ls_cadenasValidas STRING, --Contiene los caracteres validos
       lv_cuentaMail     VARCHAR(100),--Contiene email a validar
	     lsi_idxInicial    SMALLINT,--Variables para el For
       lsi_idxFinal      SMALLINT,
       lsi_estrucMail    SMALLINT,--1-nombre, 2-dominio, 3-.com  <--fase de validacion del Email	
       lb_respuesta      BOOLEAN, --respuesta a regresar
	     lsi_posicion      SMALLINT  --Variable para buscar la posici�n de una cadena             

  --devuelve la excepcion a la funcion llamante, para que sea ella quien lo maneje
  WHENEVER ANY ERROR RAISE

  --definicion de caracteres validos
	LET ls_cadenasValidas = '1234567890-_.^~abcdefghijklmn�opqrstuvwxyzABCDEFGHIJKLMN�OPQRSTUVWXYZ'

  --Primera fase de la estructura del email
	LET lsi_estrucMail = 1	
  --preparamos respuesta en FALSE
	LET lb_respuesta = FALSE
  --Obtiene Longitud de la cadena email	
	LET lsi_idxFinal = length(lv_cuentaMail)
  -- Desde la posicion 1 hasta la longitud
	FOR lsi_idxInicial = 1 TO lsi_idxFinal
    --Parte del cuerpo del correo donde se encuentra
    CASE lsi_estrucMail
      --.com .net .mx, etc.
	    WHEN 3
        LET lsi_posicion = ls_cadenasValidas.getIndexOf( lv_cuentaMail[lsi_idxInicial] , 1 ) 
        --Si encuentra el caracter como cadena valida
        IF lsi_posicion > 0 THEN
          --Si es la ultima posicion
          IF lsi_idxInicial = lsi_idxFinal THEN 
            LET lb_respuesta = TRUE				
          END IF
        ELSE				
          EXIT FOR
        END IF 
      WHEN 2
        LET lsi_posicion = ls_cadenasValidas.getIndexOf( lv_cuentaMail[lsi_idxInicial] , 1 )
        --Si encuentra el caracter como cadena valida
        IF lsi_posicion > 0 THEN 	
        ELSE	
          EXIT FOR
        END IF 
        IF lv_cuentaMail[lsi_idxInicial] = "." THEN		
          --Cambia al .com .net .mx
          LET lsi_estrucMail = 3
        END IF
            
      WHEN 1
        --No puede empezer con @	
        IF lv_cuentaMail[1] = "@" THEN
          EXIT FOR
        END IF
        LET lsi_posicion = ls_cadenasValidas.getIndexOf( lv_cuentaMail[lsi_idxInicial] , 1 )
        IF (lsi_posicion > 0) OR (lv_cuentaMail[lsi_idxInicial] = "@") OR (lv_cuentaMail[lsi_idxInicial] = ".") THEN			
          IF (lv_cuentaMail[lsi_idxInicial] = "@") AND (lv_cuentaMail[lsi_idxInicial+1] = ".") THEN
            EXIT FOR
          END IF
        ELSE				
          EXIT FOR
        END IF 
			IF lv_cuentaMail[lsi_idxInicial] = "@" THEN
        --Pasa al dominio del correo
				LET lsi_estrucMail = 2
			END IF	
    END CASE
	END FOR

	RETURN lb_respuesta
  
END FUNCTION

FUNCTION cierraSolicitudes(lcurp)
    DEFINE lcurp STRING
    DEFINE lfecha_solicitud DATE
    DEFINE lfolio_solicitud BIGINT
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT fecha_solicitud, folio_solicitud",
               "   FROM cei_solicitud",
               "  WHERE curp = '", lcurp, "'",
               "    AND id_estatus = 1"
    PREPARE select_curp_cierre FROM SQL1
    DECLARE curSeleccionaCierre CURSOR FOR select_curp_cierre
    
    FOREACH curSeleccionaCierre INTO lfecha_solicitud, lfolio_solicitud
        IF tiempo(lfecha_solicitud) = TRUE THEN
            LET SQL1 = " UPDATE cei_solicitud",
                       "    SET id_estatus = 2",
                       "      , id_motivorechazo = 42 ",
                       "  WHERE folio_solicitud = ", lfolio_solicitud,
                       "    AND id_estatus = 1"
            PREPARE update_cei_solicitud FROM SQL1
            EXECUTE update_cei_solicitud
        END IF
    END FOREACH
END FUNCTION

FUNCTION tiempo(lfecha)
    DEFINE lfecha DATETIME YEAR TO SECOND
    DEFINE fecha_actual DATETIME YEAR TO SECOND
    DEFINE diferencia INTERVAL DAY(4) TO SECOND
    DEFINE t_transcurrido INTERVAL HOUR TO SECOND

    LET fecha_actual = CURRENT YEAR TO SECOND

    LET diferencia = fecha_actual - lfecha

    LET t_transcurrido = "00:04:59"
    
    IF diferencia > t_transcurrido THEN

        RETURN TRUE
    END IF
    
    RETURN FALSE
END FUNCTION

FUNCTION fnEsActivoUnicamenteYcotizaFondodePensiones(num_issste)
    DEFINE num_issste DECIMAL(10)
    DEFINE SQL1 STRING
    DEFINE lcontar INTEGER

    LET SQL1 = " SELECT COUNT(cuenta_ind.num_issste)", 
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",
               "   WHERE cuenta_ind.num_issste    = ", num_issste,
               "     AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "     AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "     AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "     AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "     AND (c_modalidad.pensiones   = 'T')", --WS1 fnEsActivoUnicamenteYcotizaFondodePensiones
               "     AND cuenta_ind.fecha_termino IS NULL"
   PREPARE select_count_fondo_pensiones FROM SQL1
   EXECUTE select_count_fondo_pensiones INTO lcontar

    IF lcontar > 0 THEN
        RETURN FALSE
    END IF

   RETURN TRUE
END FUNCTION

FUNCTION fnObtieneFechaBaja(lnum_issste)
    DEFINE lnum_issste DECIMAL(10,2)
    DEFINE SQL1 STRING
    DEFINE lfecha_baja DATE

    LET SQL1 = " SELECT MAX(fecha_termino)", 
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",
               "  WHERE cuenta_ind.num_issste    = ", lnum_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --WS1 fnObtieneFechaBaja
               "    AND cuenta_ind.fecha_termino IS NOT NULL"
    PREPARE select_fecha_baja_cuenta_ind FROM SQL1
    EXECUTE select_fecha_baja_cuenta_ind INTO lfecha_baja
    
    RETURN lfecha_baja
END FUNCTION