IMPORT security
IMPORT FGL clienteSAT
SCHEMA dsipe


--TYPE t_ws2Salida  RECORD
--        codigo_resultado          VARCHAR(2),
--        motivo_rechazo            VARCHAR(3),
--        folio_procesar            VARCHAR(50),
--        fecha_reg_estatus         DATETIME YEAR TO SECOND,
--        estatus_dict_portab       INTEGER,
--        derecho_otorgado_imss     VARCHAR(130),
--        fecha_otorgamiento_imss   DATE,
--        derecho_otorgado_issste   VARCHAR(130,0),
--        fecha_otorgamiento_issste DATE
--     END RECORD

TYPE t_ws2Salida  RECORD
        codigo_resultado          VARCHAR(2),
        motivo_rechazo            VARCHAR(3),
        folio_procesar            VARCHAR(50),
        fecha_reg_estatus         VARCHAR(19),
        estatus_dict_portab       VARCHAR(2),
        derecho_otorgado_imss     VARCHAR(130),
        fecha_otorgamiento_imss   VARCHAR(10),
        derecho_otorgado_issste   VARCHAR(130),
        fecha_otorgamiento_issste VARCHAR(10)
     END RECORD

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

    LET SQL1 = " SELECT descripcion",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", lid_motivorechazo
    PREPARE select_descripcion_motivorechazo FROM SQL1
    EXECUTE select_descripcion_motivorechazo INTO ldescripcion

    
    RETURN ldescripcion
END FUNCTION

FUNCTION fnMotivoRechazo(lid_motivorechazo)
    DEFINE lid_motivorechazo INTEGER
    DEFINE ldescripcion STRING
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT motivo_rechazo",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", lid_motivorechazo
    PREPARE select_descripcion_motivorechazo02 FROM SQL1
    EXECUTE select_descripcion_motivorechazo02 INTO ldescripcion

    
    RETURN ldescripcion
END FUNCTION

FUNCTION fnObservacionesRechazo(lid_motivorechazo)
    DEFINE lid_motivorechazo INTEGER
    DEFINE ldescripcion STRING
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT observaciones",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", lid_motivorechazo
    PREPARE select_descripcion_motivorechazo03 FROM SQL1
    EXECUTE select_descripcion_motivorechazo03 INTO ldescripcion

    
    RETURN ldescripcion
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
       DISPLAY "###############################################################"
       DISPLAY "##", msg_err
       DISPLAY "###############################################################"
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


#####################################
## inserta en CEI_TD_WS2_PROCESARALTA
#####################################
FUNCTION fnInserta_cei_td_ws2_procesaralta(lSalidaWS2, lfolio_solicitud)
    DEFINE lSalidaWS2       t_ws2Salida
    DEFINE lfolio_solicitud INTEGER
    DEFINE lProcesarAlta RECORD LIKE cei_td_ws2_procesaralta.*
    

    LET lProcesarAlta.folio_solicitud        = lfolio_solicitud
    LET lProcesarAlta.codigo_resultado       = lSalidaWS2.codigo_resultado
    LET lProcesarAlta.motivo_rechazo         = lSalidaWS2.motivo_rechazo
    LET lProcesarAlta.folio_procesar         = lSalidaWS2.folio_procesar
    LET lProcesarAlta.fecha_registro_estatus = lSalidaWS2.fecha_reg_estatus
    LET lProcesarAlta.estatus_dictaminacion  = lSalidaWS2.estatus_dict_portab
    LET lProcesarAlta.derecho_imss           = lSalidaWS2.derecho_otorgado_imss
    LET lProcesarAlta.fecha_imss             = lSalidaWS2.fecha_otorgamiento_imss
    LET lProcesarAlta.derecho_issste         = lSalidaWS2.derecho_otorgado_issste
    LET lProcesarAlta.fecha_issste           = lSalidaWS2.fecha_otorgamiento_issste
    LET lProcesarAlta.fecha_respuesta        = CURRENT YEAR TO SECOND

    INSERT INTO cei_td_ws2_procesaralta
         VALUES(lProcesarAlta.*)
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


##########################
## consumo de servicio SAT
##########################
FUNCTION servicioSAT(l_val_cer, l_val_key, l_curp, bndFirmaDoc, l_solicitud, l_nombre, lrfc, lpassword, ltipo_reporte)
    DEFINE l_val_cer    STRING
    DEFINE l_val_key    STRING
    DEFINE l_curp       STRING
    DEFINE bndFirmaDoc  SMALLINT
    DEFINE l_solicitud  BIGINT
    DEFINE l_nombre     STRING
    DEFINE lrfc         STRING
    DEFINE lpassword    STRING
    DEFINE ltipo_reporte STRING
    DEFINE lFirmaSAT    RECORD LIKE cei_solicitud_firma.*
    DEFINE rFirma       request
    DEFINE wsstatus     STRING
    DEFINE validacion   INTEGER
    DEFINE ldocumento   STRING
    DEFINE sfolio_solicitud STRING
    DEFINE SQL1         STRING
    DEFINE lExiste      INTEGER
    DEFINE lRepDinPort  RECORD LIKE cei_repdinport.*

    LET clienteSAT.Endpoint.Address.Uri = get_endpoint_ws("wsfirmasat")
    
    LET sfolio_solicitud = l_solicitud

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_repdinport",
               "  WHERE folio_solicitud = ", l_solicitud
    PREPARE select_repdinport_existe FROM SQL1
    EXECUTE select_repdinport_existe INTO lExiste

    IF lExiste > 0 THEN
        LOCATE lRepDinPort.cerificado_b64 IN MEMORY
        LOCATE lRepDinPort.clave_b64 IN MEMORY
        LOCATE lRepDinPort.pass_cert_b64 IN MEMORY
        LET SQL1 = " SELECT *",
                   "   FROM cei_repdinport",
                   "  WHERE folio_solicitud = ", l_solicitud
        PREPARE select_repdinport_01 FROM SQL1
        EXECUTE select_repdinport_01 INTO lRepDinPort.*
    END IF

    LET lFirmaSAT.cadenaoriginal   = l_val_cer
    LET lFirmaSAT.rfc              = upshift(l_val_cer.subString(1,13))
    LET lFirmaSAT.sellodigital     = l_val_key
    LET lFirmaSAT.seriecertificado = l_val_cer
    IF ltipo_reporte = "R" THEN
        LET lFirmaSAT.xmlfirmado       = "R_"||l_curp||"_"||sfolio_solicitud||".pdf"
    END IF
    IF ltipo_reporte = "S" THEN
        LET lFirmaSAT.xmlfirmado       = "S_"||l_curp||"_"||sfolio_solicitud||".pdf"
    END IF
    LET lFirmaSAT.fecha_firma      = CURRENT YEAR TO SECOND
    LET lFirmaSAT.folio_solicitud  = l_solicitud
    LET lFirmaSAT.nombre           = l_nombre
    LET lFirmaSAT.informacion = "Datos DUMMY hasta que se genere un servicio que devuelva datos"

    IF bndFirmaDoc = FALSE THEN
        LET ldocumento = "DummySentSign.pdf"
    ELSE
        LET ldocumento  = lFirmaSAT.xmlfirmado
    END IF
    
    IF validacion = 0 THEN
        LET rFirma.aplicacion    = "TRANSFERENCIA DE DERECHOS"
        LET rFirma.folioControl  = l_solicitud
        LET rFirma.folioControl = rFirma.folioControl CLIPPED
        LET rFirma.folioControl = "TDD-"||rFirma.folioControl CLIPPED
        LET rFirma.nombre        = l_nombre

        IF lExiste > 0 THEN
            LET rFirma.rfc              = lRepDinPort.rfc
            LET rFirma.password         = security.Base64.ToString(lRepDinPort.pass_cert_b64)
            LET rFirma.certificado_b64  = lRepDinPort.cerificado_b64
            LET rFirma.clavePrivada_b64 = lRepDinPort.clave_b64
        ELSE
            LET rFirma.rfc              = lrfc
            LET rFirma.password         = lpassword
            LET rFirma.certificado_b64  = security.Base64.LoadBinary(l_val_cer)
            LET rFirma.clavePrivada_b64 = security.Base64.LoadBinary(l_val_key)
        END IF

        LET rFirma.documento_b64    = security.Base64.LoadBinary(ldocumento)

        IF bndFirmaDoc = FALSE THEN
            IF ltipo_reporte = "R" THEN
                CALL clienteSAT.Post_Firma(rFirma.*, "R_"||l_curp||"_"||sfolio_solicitud||".pdf") RETURNING wsstatus
            END IF
            IF ltipo_reporte = "S" THEN
                CALL clienteSAT.Post_Firma(rFirma.*, "S_"||l_curp||"_"||sfolio_solicitud||".pdf") RETURNING wsstatus
            END IF
        ELSE
            IF ltipo_reporte = "R" THEN
                CALL clienteSAT.Post_Firma(rFirma.*, "R_"||l_curp||"_"||sfolio_solicitud||"_firmada"||".pdf") RETURNING wsstatus
            END IF
            IF ltipo_reporte = "S" THEN
                CALL clienteSAT.Post_Firma(rFirma.*, "S_"||l_curp||"_"||sfolio_solicitud||"_firmada"||".pdf") RETURNING wsstatus
            END IF
        END IF

        DISPLAY "wsstatus SAT Service: ", wsstatus

        IF wsstatus = 200 THEN
            LET lFirmaSAT.curp = l_curp
            RETURN lFirmaSAT.*
        END IF
    END IF
    RETURN lFirmaSAT.*
END FUNCTION


##############################
## actualiza ESTATUS SOLICITUD
##############################
FUNCTION fnActualizaEstatusSolicitud(folio_solicitud, id_motivorechazo, id_estatus)
    DEFINE folio_solicitud  INTEGER
    DEFINE id_motivorechazo INTEGER
    DEFINE id_estatus       INTEGER
    DEFINE lobservaciones   STRING
    DEFINE SQL1             STRING
    DEFINE ldescripcion     STRING

    LET SQL1 = " SELECT descripcion, observaciones",
               "   FROM cei_cat_motivorechazo",
               "  WHERE id_motivorechazo = ", id_motivorechazo
    PREPARE select_observaciones_motivorechazo FROM SQL1
    EXECUTE select_observaciones_motivorechazo INTO ldescripcion, lobservaciones

    IF id_motivorechazo = 15 OR
               id_motivorechazo = 18 OR
               id_motivorechazo = 19 OR
               id_motivorechazo = 21 THEN
        LET lobservaciones = ldescripcion
    ELSE
        IF length(lobservaciones) = 0 OR lobservaciones IS NULL THEN
            LET lobservaciones = ldescripcion
        ELSE
            LET lobservaciones = ldescripcion,": ", lobservaciones
        END IF
    END IF

    LET SQL1 = " UPDATE cei_solicitud",
               "   SET id_motivorechazo = ", id_motivorechazo, 
               "     , id_estatus       = ", id_estatus
            IF id_motivorechazo = 15 OR
               id_motivorechazo = 18 OR
               id_motivorechazo = 19 OR
               id_motivorechazo = 21 THEN
               LET SQL1 = SQL1, "  WHERE folio_solicitud = ", folio_solicitud
            ELSE
               LET SQL1 = SQL1, "     , observaciones    = '", lobservaciones, "'",
                                "  WHERE folio_solicitud = ", folio_solicitud
            END IF
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
    --DEFINE file_incurpd base.Channel
    DEFINE file_incurp  base.Channel
    DEFINE SQL1         STRING
    DEFINE lDirecto     RECORD LIKE directo.*

    IF fgl_getenv("OS")= "Windows_NT" THEN
        LET cmdrun = "set DBDATE=dmy4/; set FGLWSDEBUG=9; fglrun rCURP.42r '",lCURP, "'"
        RUN cmdrun
    ELSE
        LET cmdrun = "export DBDATE=dmy4/; export FGLWSDEBUG=9; fglrun rCURP.42r '",lCURP, "'"
        RUN cmdrun
    END IF

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


--    IF lrCurp.curp IS NOT NULL OR lrCurp.curp <> "" THEN
--        LET cmdrun = "fglrun rCURPDetalle.42r '",lrCurp.apellido_paterno CLIPPED,"'",
--               " '",lrCurp.apellido_materno CLIPPED, "'"
--             , " '",lrCurp.nombre CLIPPED,"'"
--             , " '",lrCurp.fecha_nacimiento,"'"
--             , " '",lrCurp.sexo CLIPPED,"'"
--        RUN cmdrun
--    END IF
--
--    TRY
--        CALL base.Channel.create() RETURNING file_incurpd
--        CALL file_incurpd.openFile("fileoutcurpdetalle"||lCURP||".txt","r")
--        LET lrCurp.curp               = file_incurpd.readLine()
--        LET lrCurp.crip               = file_incurpd.readLine()
--        CALL file_incurpd.close()
--    CATCH
--    END TRY
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
        DISPLAY "COMPARA RENAPO-DIRECTO CURP: ",lrCurp.curp, " - ", lDirecto.curp 
        RETURN 2
    END IF
    IF (lrCurp.apellido_materno <> lDirecto.apellido_materno) THEN
        DISPLAY "COMPARA RENAPO-DIRECTO apellido_materno: ",lrCurp.apellido_materno, " - ", lDirecto.apellido_materno 
        RETURN 2
    END IF
    IF (lrCurp.apellido_paterno <> lDirecto.apellido_paterno) THEN
        DISPLAY "COMPARA RENAPO-DIRECTO apellido_paterno: ",lrCurp.apellido_paterno, " - ", lDirecto.apellido_paterno 
        RETURN 2
    END IF
    IF (lrCurp.entidad_nacimiento <> lDirecto.ent_cve) THEN
        DISPLAY "COMPARA RENAPO-DIRECTO entidad_nacimiento: ",lrCurp.entidad_nacimiento, " - ", lDirecto.ent_cve 
        RETURN 2
    END IF
    IF (lrCurp.nombre <> lDirecto.nombre) THEN
        DISPLAY "COMPARA RENAPO-DIRECTO nombre: ",lrCurp.nombre, " - ", lDirecto.nombre 
        RETURN 2
    END IF
    --IF (lrCurp.rfc.subString(1,10) <> lDirecto.rfc[1,10]) THEN
    --    RETURN 2
    --END IF
    IF (lrCurp.sexo <> lDirecto.sexo) THEN
        DISPLAY "COMPARA RENAPO-DIRECTO sexo: ",lrCurp.sexo, " - ", lDirecto.sexo 
        RETURN 2
    END IF
    IF (lrCurp.fecha_nacimiento <> lDirecto.fec_nac) THEN
        DISPLAY "COMPARA RENAPO-DIRECTO fec_nac: ",lrCurp.fecha_nacimiento, " - ", lDirecto.fec_nac 
        RETURN 2
    END IF
    IF lrCurp.statusCurp = "BD" OR
       lrCurp.statusCurp = "BSU" OR
       lrCurp.statusCurp = "BAP" OR
       lrCurp.statusCurp = "BDM" OR
       lrCurp.statusCurp = "BDP" OR
       lrCurp.statusCurp = "BDJ"
    THEN
        DISPLAY "RENAPO statusCurp: ",lrCurp.statusCurp
        RETURN 3
    END IF
    --CALL FGL_WINMESSAGE("Rastreo Portabilidad","Ya valido RENAPO, Guardara en cei_td_wsrenapo","information")
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
                       , ",'", lrCurp.curp, "'"
                       , ",'", lrCurp.apellido_paterno, "'"
                       , ",'", lrCurp.apellido_materno, "'"
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

FUNCTION presentaMarca200(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE luso_pen    INTEGER

    LET luso_pen = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND uso_pen = 200"
    PREPARE select_cuenta_indperiodos200 FROM SQL1
    EXECUTE select_cuenta_indperiodos200 INTO luso_pen

    RETURN luso_pen
END FUNCTION

FUNCTION traslapeMarca100(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1 STRING
DEFINE fecha_inicio  DATE
DEFINE fecha_termino DATE
DEFINE uso_pen       INTEGER
DEFINE lcontar       INTEGER
DEFINE bndIG         SMALLINT
DEFINE arrRegistros  DYNAMIC ARRAY OF RECORD
        fecha_inicio  DATE,
        fecha_termino DATE,
        uso_pen       INTEGER
        END RECORD
DEFINE idx INTEGER
DEFINE idxj INTEGER

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND uso_pen = 100 "
    PREPARE select_cuenta_ind_00 FROM SQL1
    EXECUTE select_cuenta_ind_00 INTO lcontar

    IF lcontar = 1 THEN
        RETURN 1
    END IF

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND uso_pen is null "
    PREPARE select_cuenta_ind_05 FROM SQL1
    EXECUTE select_cuenta_ind_05 INTO lcontar

    IF lcontar = 1 THEN
        RETURN 0
    END IF

    LET SQL1 = " SELECT fecha_inicio, fecha_termino, uso_pen",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               " ORDER BY fecha_termino"
    PREPARE select_cuenta_ind_01 FROM SQL1
    DECLARE curCuentaIndTraslapesIG CURSOR FOR select_cuenta_ind_01
    LET bndIG = FALSE
    LET idx = 1
    LET idxj = 1
    FOREACH curCuentaIndTraslapesIG INTO fecha_inicio, fecha_termino, uso_pen
        LET arrRegistros[idx].fecha_inicio  = fecha_inicio
        LET arrRegistros[idx].fecha_termino = fecha_termino
        LET arrRegistros[idx].uso_pen       = uso_pen
        IF uso_pen = 100 THEN
            FOR idxj = 1 TO idx
                IF arrRegistros[idxj].uso_pen IS NULL THEN
                    LET bndIG = TRUE
                    EXIT FOR
                END IF
            END FOR
            IF bndIG = TRUE THEN
                EXIT FOREACH
            END IF
        END IF
        LET idx = idx + 1
    END FOREACH

    IF bndIG = TRUE THEN
        RETURN 1
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
                   "    AND uso_pen BETWEEN 400 AND 430"
        PREPARE select_cuenta_ind_periodos400 FROM SQL1
        EXECUTE select_cuenta_ind_periodos400 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF
    RETURN 0
END FUNCTION

FUNCTION usuarioInvalido(lnum_issste)
DEFINE lnum_issste DECIMAL(8,0)
DEFINE SQL1        STRING
DEFINE lcontar     INTEGER

    LET lcontar = 0
    LET SQL1 = "\n SELECT COUNT(*)",
               "\n   FROM cuenta_ind",
               "\n  WHERE num_issste = ", lnum_issste,
               "\n    AND NOT (",
               "\n               UPPER(usuario) LIKE 'A%'",
               "\n           AND UPPER(usuario) LIKE 'SPI%'",
               "\n           AND UPPER(usuario) LIKE 'M%'",
               "\n           AND UPPER(usuario) LIKE 'B%'",
               "\n           AND UPPER(usuario) LIKE 'I%'",
               "\n )"
    PREPARE select_usuario_invalido03 FROM SQL1
    EXECUTE select_usuario_invalido03 INTO lcontar

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
                   "\n  WHERE num_issste = ", lnum_issste,
                   "\n    AND UPPER(usuario) = 'RHDEZ'",
                   "\n    AND uso_pen IS NULL"
        PREPARE select_usuario_invalido00 FROM SQL1
        EXECUTE select_usuario_invalido00 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF

        LET lcontar = 0
        LET SQL1 = "\n SELECT COUNT(*)",
                   "\n   FROM cuenta_ind",
                   "\n  WHERE num_issste = ", lnum_issste,
                   "\n    AND UPPER(usuario) LIKE 'SAVD%'",
                   "\n    AND uso_pen IS NULL"
        PREPARE select_usuario_invalido01 FROM SQL1
        EXECUTE select_usuario_invalido01 INTO lcontar

        IF lcontar > 0 THEN
            RETURN 1
        END IF

        LET lcontar = 0
        LET SQL1 = "\n SELECT COUNT(*)",
                   "\n   FROM cuenta_ind",
                   "\n  WHERE num_issste = ", lnum_issste,
                   "\n    AND NOT (",
                   "\n              UPPER(usuario) LIKE 'A%'",
                   "\n          OR UPPER(usuario) LIKE 'SPI%'",
                   "\n          OR UPPER(usuario) LIKE 'M%'",
                   "\n          OR UPPER(usuario) LIKE 'B%'",
                   "\n          OR UPPER(usuario) LIKE 'I%'",
                   "\n          OR usuario MATCHES '[0-9]*'",
                   "\n )",
                   "\n    AND uso_pen IS NULL"
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
               "    AND sueldo_issste < .90",
               "\n    AND uso_pen IS NULL"
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
    PREPARE pprExiste FROM ls_query
    
    LET SQL1 = " SELECT cuenta_ind.fecha_inicio, cuenta_ind.fecha_termino,",
               "        cuenta_ind.uso_pen, cuenta_ind.u_version, c_pagaduria.mod_cve", 
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",  
               "  WHERE cuenta_ind.num_issste    = ", lde_num_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --dias_cot
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
               "    AND (c_modalidad.pensiones   = 'T')", --vigenteal31032007sinbonopension
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

FUNCTION bonopension_fechaingresoposterior31032007_sinHLprevia(lnum_issste) --validacion 114
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
               "    AND (c_modalidad.pensiones   = 'T')", --bonopension_fechaingresoposterior31032007_sinHLprevia
               "    AND cuenta_ind.fecha_inicio < '31/03/2007'"
        PREPARE select_fecha_ingreso_posteriorsinHLprev01 FROM SQL1
        EXECUTE select_fecha_ingreso_posteriorsinHLprev01 INTO lcontar 

        IF lcontar > 0 THEN
            RETURN 1 -- rechazo 114
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
               "    AND (c_modalidad.pensiones   = 'T')", --periodosconsistentes_campos_auditores
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

    MESSAGE ""

    RETURN lFolioSolicitud
END FUNCTION

FUNCTION fnGuardarSolicitud_cei_solicitud_inicial(lSolicitud)
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    DEFINE lbndGuardada SMALLINT
    DEFINE SQL1 STRING

    LET lbndGuardada = TRUE 
    TRY
        --CALL FGL_WINMESSAGE("Rastreo Portabilidad","Guardara en cei_solicitud","information")
        INSERT INTO cei_solicitud VALUES(lSolicitud.*)

        --CALL FGL_WINMESSAGE("Rastreo Portabilidad","Guardara en cei_td_solicitud","information")
        LET SQL1 = "\n INSERT INTO cei_td_solicitud(folio_solicitud, inst_receptor,nss_imss, nss_issste, fecha_respuesta)",
                   "\n      VALUES(", lSolicitud.folio_solicitud,
                   --"\n           ,'", lSolicitud.id_tiposolicitud USING "&&", "'",
                   "\n           , '02'",
                   "\n           , '", lSolicitud.nss_imss,"'",
                   "\n           , '", lSolicitud.num_issste, "'",
                   "\n           , '", CURRENT YEAR TO SECOND, "'",
                   "\n )"
        DISPLAY SQL1
        PREPARE insert_cei_td_solcitud FROM SQL1
        EXECUTE insert_cei_td_solcitud
    CATCH
        DISPLAY "SQLCODE: ", sqlca.sqlcode
        DISPLAY "SQLCODE: ", sqlca.sqlerrm
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
    
    RETURN lFolioExterno
END FUNCTION

FUNCTION fnInsertacei_td_ws1_basica_otra(lcei_td_ws1_basica_otra)
    DEFINE lcei_td_ws1_basica_otra RECORD LIKE cei_td_ws1_basica_otra.*

    --Genera Folio
    CALL fnGenerarFoliocei_td_ws1_basica_otra() RETURNING lcei_td_ws1_basica_otra.folio_consulta
    
    --WHENEVER ERROR CONTINUE
        INSERT INTO cei_td_ws1_basica_otra VALUES (lcei_td_ws1_basica_otra.*)
    --WHENEVER ERROR STOP
END FUNCTION

FUNCTION inserta_cei_td_ws1_basica(lcei_td_ws1_basica)
    DEFINE lcei_td_ws1_basica RECORD LIKE cei_td_ws1_basica.*
    
    --WHENEVER ERROR CONTINUE
        INSERT INTO cei_td_ws1_basica VALUES (lcei_td_ws1_basica.*)
    --WHENEVER ERROR STOP
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
           rDirecto.apellido_materno, rDirecto.fecha_baja, rDirecto.dto_estado, rDirecto.fec_nac, nss
END FUNCTION

FUNCTION fnValidaCampos(lSolicitud)
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    
    IF lSolicitud.id_tiposolicitud IS NULL THEN ERROR "Seleccione el tipo de solicitud" RETURN FALSE END IF
    IF lSolicitud.curp             IS NULL OR length(lSolicitud.curp) <> 18 THEN ERROR "Capture la CURP correctamente"                 RETURN FALSE END IF    
    IF  f_validaEstructuraEmail (lSolicitud.correo) = 0 THEN  
        ERROR "Capture el correo con el formato [cuenta]@[dominio.com]\n Ej. cuenta_mail@midominio.com"
        RETURN FALSE
    END IF  
    IF length( lSolicitud.telefono  ) < 10 THEN ERROR "Capture el teléfono A 10 digitos" RETURN FALSE END IF
    --IF lSolicitud.observaciones    IS NULL THEN ERROR "Capture las observaciones"        RETURN FALSE END IF

    IF lSolicitud.nss_imss      IS NULL THEN ERROR "Capture el numero de IMSS"       RETURN FALSE END IF

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

FUNCTION fnObtieneRFCRENAPO_nombre_completo(lCURP)
    DEFINE lCURP        STRING
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
    
    LET cmdrun = "fglrun rCURP.42r '",lCURP, "'"
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

    RETURN lrCurp.rfc, lrCurp.nombre CLIPPED||" "||lrCurp.apellido_paterno CLIPPED||" "||lrCurp.apellido_materno CLIPPED
END FUNCTION