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
    (title: "Servicios de Portabilidad de derechos - Aviso de Estatus de Transferencia de Derechos",
        version: "1.0",
        contact:(email: "transferenciaderechos@issste.gob.mx"))
        
PUBLIC DEFINE avEstTran RECORD ATTRIBUTE(WSError = "Tratamiento de Mensajes Aviso de Estatus de Transferencia de Derechos")
  message STRING
END RECORD

TYPE tWS6EntradaISSSTE RECORD
    inst_rec_tram      VARCHAR(2),
    nss_imss           VARCHAR(11),
    curp               VARCHAR(18),
    folio_ent_rec_tram VARCHAR(50),
    resulta_int_portab INTEGER
END RECORD

TYPE tWS6SalidaISSSTE RECORD
    codigo_resultado VARCHAR(2),
    motivo_rechazo   VARCHAR(3)
END RECORD

PUBLIC FUNCTION avisoestatustransferenciaissste(rEntradaISSSTE tWS6EntradaISSSTE)

    ATTRIBUTES(WSPost,
        WSPath = "/avisoestatustransferenciaissste",
        WSDescription = "Aviso de Estatus de Transferencia de Derechos - ISSSTE",
        WSThrows = "400:@avEstTran")
    RETURNS( tWS6SalidaISSSTE )

    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    DEFINE rWS6SalidaISSSTE tWS6SalidaISSSTE
    DEFINE SQL1       STRING
    DEFINE lExiste INTEGER
    DEFINE lExiste_r INTEGER
    DEFINE rcei_td_ws6_procedencia_otra RECORD LIKE cei_td_ws6_procedencia_otra.*
    DEFINE rcei_td_ws6_procedencia RECORD LIKE cei_td_ws6_procedencia.*

    -- Validar que las curps siguientes no tengan requerimiento de salida forzada.
--    IF rEntradaISSSTE.curp = "AAOX720225MMCLVH11" THEN
--        LET rWS6SalidaISSSTE.codigo_resultado = "02"
--        LET rWS6SalidaISSSTE.motivo_rechazo = "221"
--        
--        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = rWS6SalidaISSSTE.codigo_resultado
--        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
--        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = util.Datetime.format(CURRENT YEAR TO SECOND,"%d/%m/%Y %H:%M:%S")
--        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
--        --LET rcei_td_ws6_procedencia_otra.folio_solicitud        = ""
--        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
--        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = rWS6SalidaISSSTE.motivo_rechazo
--        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
--        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab
--
--        CONNECT TO "dsipe"
--            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
--        DISCONNECT CURRENT
--            
--        DISCONNECT CURRENT
--        RETURN rWS6SalidaISSSTE
--    END IF
--    IF rEntradaISSSTE.curp = "PESG830313HVZRNR07" THEN
--        LET rWS6SalidaISSSTE.codigo_resultado = "02"
--        LET rWS6SalidaISSSTE.motivo_rechazo = "222"
--
--        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = rWS6SalidaISSSTE.codigo_resultado
--        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
--        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = util.Datetime.format(CURRENT YEAR TO SECOND,"%d/%m/%Y %H:%M:%S")
--        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
--        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
--        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = rWS6SalidaISSSTE.motivo_rechazo
--        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
--        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab
--
--        CONNECT TO "dsipe"
--            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
--        DISCONNECT CURRENT
--        
--        RETURN rWS6SalidaISSSTE
--    END IF
--    IF rEntradaISSSTE.curp = "CIZB670619MHGDML08" OR
--       rEntradaISSSTE.curp = "LOMC850730MJCPRL05" OR
--       rEntradaISSSTE.curp = "PICA820303HMCNRL04"
--       THEN
--        LET rWS6SalidaISSSTE.codigo_resultado = "01"
--
--        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "01"
--        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
--        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
--        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
--        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
--        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = rWS6SalidaISSSTE.motivo_rechazo
--        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
--        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab
--
--        CONNECT TO "dsipe"
--            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
--        DISCONNECT CURRENT
--        
--        RETURN rWS6SalidaISSSTE
--    END IF

    IF rEntradaISSSTE.resulta_int_portab IS NULL THEN
        CONNECT TO "dsipe"
        LET rWS6SalidaISSSTE.codigo_resultado = "02"
        LET rWS6SalidaISSSTE.motivo_rechazo = fnMotivoRechazo(23)
        DISCONNECT CURRENT
        RETURN rWS6SalidaISSSTE
    END IF

    IF (rEntradaISSSTE.resulta_int_portab <> 1 AND rEntradaISSSTE.resulta_int_portab <> 0) THEN
        CONNECT TO "dsipe"
        LET rWS6SalidaISSSTE.codigo_resultado = "02"
        LET rWS6SalidaISSSTE.motivo_rechazo = fnMotivoRechazo(23)

        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = fnMotivoRechazo(23)
        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = fnMotivoRechazo(23)
        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

        IF rEntradaISSSTE.resulta_int_portab IS NOT NULL THEN
            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
        END IF
        DISCONNECT CURRENT
        RETURN rWS6SalidaISSSTE
    END IF

    IF length(rEntradaISSSTE.inst_rec_tram) < 2 THEN
        CONNECT TO "dsipe"
        LET rWS6SalidaISSSTE.codigo_resultado = "02"
        LET rWS6SalidaISSSTE.motivo_rechazo = fnMotivoRechazo(23)

        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "02"
        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = fnMotivoRechazo(23)
        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
        DISCONNECT CURRENT
        
        RETURN rWS6SalidaISSSTE
    END IF
    
    IF rEntradaISSSTE.inst_rec_tram <> "01" THEN
        CONNECT TO "dsipe"
        LET rWS6SalidaISSSTE.codigo_resultado = "02"
        LET rWS6SalidaISSSTE.motivo_rechazo = fnMotivoRechazo(23)

        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "02"
        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = fnMotivoRechazo(23)
        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
        DISCONNECT CURRENT
        
        RETURN rWS6SalidaISSSTE
    END IF

    IF length(rEntradaISSSTE.nss_imss) <> 11 THEN
        CONNECT TO "dsipe"
        LET rWS6SalidaISSSTE.codigo_resultado = "02"
        LET rWS6SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(23)

        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "02"
        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = fnMotivoRechazo(23)
        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
        DISCONNECT CURRENT
        
        RETURN rWS6SalidaISSSTE
    END IF

    IF length(rEntradaISSSTE.curp) <> 18 THEN
        CONNECT TO "dsipe"
        LET rWS6SalidaISSSTE.codigo_resultado = "02"
        LET rWS6SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(23)

        LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "02"
        LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
        LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
        LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = fnMotivoRechazo(23)
        LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
        LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
        DISCONNECT CURRENT
        
        RETURN rWS6SalidaISSSTE
    END IF

    CONNECT TO "dsipe"
        LET lExiste   = 0
        LET lExiste_r = 0

--        LET SQL1 = "\n SELECT COUNT(*)",
--                     "\n   FROM cei_solicitud",
--                     "\n  WHERE curp = '", rEntradaISSSTE.curp, "'",
--                     "\n    AND id_estatus = 3"
--        PREPARE select_cei_solicitud_00 FROM SQL1
--        EXECUTE select_cei_solicitud_00 INTO lExiste
--
--        IF lExiste > 0 THEN
--            LET rWS6SalidaISSSTE.codigo_resultado = "02"
--            LET rWS6SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(25)
--
--            LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "02"
--            LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
--            LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
--            LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
--            LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
--            LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = fnMotivoRechazo(25)
--            LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
--            LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab
--
--                CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
--            DISCONNECT CURRENT
--            
--            RETURN rWS6SalidaISSSTE
--        END IF
        
        LET SQL1 = "\n SELECT COUNT(*)",
                     "\n   FROM cei_solicitud",
                     "\n  WHERE curp = '", rEntradaISSSTE.curp, "'",
                     "\n    AND id_estatus = 1"
        PREPARE select_cei_solicitud_01 FROM SQL1
        EXECUTE select_cei_solicitud_01 INTO lExiste

        LET SQL1 = "\n SELECT COUNT(*)",
                     "\n   FROM cei_solicitud so",
                     "\n  INNER JOIN cei_td_solicitud    td ON td.folio_solicitud = so.folio_solicitud",
                     "\n  INNER JOIN cei_td_ws3_robusta ro  ON ro.folio_solicitud = so.folio_solicitud",
                     "\n  WHERE so.curp          = '", rEntradaISSSTE.curp, "'",
                     "\n    AND td.folio_externo = '", rEntradaISSSTE.folio_ent_rec_tram, "'",
                     "\n    AND td.folio_solicitud = so.folio_solicitud",
                     "\n    AND ro.codigo_resultado = '01'",
                     "\n    AND so.id_estatus       = 1"
        PREPARE select_cei_solicitud_02 FROM SQL1
        EXECUTE select_cei_solicitud_02 INTO lExiste_r
        
        IF lExiste > 0 AND lExiste_r > 0 THEN
            LET SQL1 = "\n SELECT FIRST 1 *",
                         "\n   FROM cei_solicitud",
                         "\n  WHERE curp = '", rEntradaISSSTE.curp, "'",
                         "\n    AND id_estatus = 1",
                         "\n  ORDER BY folio_solicitud DESC"
            PREPARE select_cei_solicitud FROM SQL1
            EXECUTE select_cei_solicitud INTO lSolicitud.*

            LET rcei_td_ws6_procedencia_otra.codigo_resultado       = "01"
            LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
            LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
            LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
            LET rcei_td_ws6_procedencia_otra.folio_solicitud        = lSolicitud.folio_solicitud
            LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
            --LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = rWS6SalidaISSSTE.motivo_rechazo
            LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
            LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)

            IF rEntradaISSSTE.resulta_int_portab = 1 THEN
                BEGIN WORK
                IF marcarPeriodos(lSolicitud.num_issste, lSolicitud.folio_solicitud) = TRUE THEN
                    LET SQL1 = " UPDATE cei_solicitud",
                           "      SET id_estatus = 3",
                           "    WHERE folio_solicitud = ", lSolicitud.folio_solicitud
                    PREPARE update_solicitud_procedente FROM SQL1
                    EXECUTE update_solicitud_procedente

                    LET rWS6SalidaISSSTE.codigo_resultado = "01"

                    LET rcei_td_ws6_procedencia.codigo_resultado = rWS6SalidaISSSTE.codigo_resultado
                    LET rcei_td_ws6_procedencia.fecha_registro   = CURRENT YEAR TO SECOND
                    LET rcei_td_ws6_procedencia.folio_solicitud  = lSolicitud.folio_solicitud

                    INSERT INTO cei_td_ws6_procedencia
                         VALUES(rcei_td_ws6_procedencia.*)
                    
                    
                    COMMIT WORK
                    DISCONNECT CURRENT
                    RETURN rWS6SalidaISSSTE
                ELSE
                    ROLLBACK WORK

                    LET rWS6SalidaISSSTE.codigo_resultado = "02"
                    LET rWS6SalidaISSSTE.motivo_rechazo   = "221"
                    DISCONNECT CURRENT
                    RETURN rWS6SalidaISSSTE
                END IF
            ELSE
                LET SQL1 = " UPDATE cei_solicitud",
                           "      SET id_estatus = 2",
                           "    WHERE folio_solicitud = ", lSolicitud.folio_solicitud
                PREPARE update_solicitud_recahzada FROM SQL1
                EXECUTE update_solicitud_recahzada

                LET rWS6SalidaISSSTE.codigo_resultado = "01"
                DISCONNECT CURRENT
                RETURN rWS6SalidaISSSTE
            END IF
        ELSE
            LET rWS6SalidaISSSTE.codigo_resultado = "02"
            LET rWS6SalidaISSSTE.motivo_rechazo = "219"

            LET rcei_td_ws6_procedencia_otra.codigo_resultado       = rWS6SalidaISSSTE.codigo_resultado
            LET rcei_td_ws6_procedencia_otra.curp_solicitada        = rEntradaISSSTE.curp
            LET rcei_td_ws6_procedencia_otra.fecha_respuesta        = CURRENT YEAR TO SECOND
            LET rcei_td_ws6_procedencia_otra.folio_externo          = rEntradaISSSTE.folio_ent_rec_tram
            LET rcei_td_ws6_procedencia_otra.folio_solicitud        = lSolicitud.folio_solicitud
            LET rcei_td_ws6_procedencia_otra.inst_receptor          = rEntradaISSSTE.inst_rec_tram
            LET rcei_td_ws6_procedencia_otra.motivo_rechazo         = rWS6SalidaISSSTE.motivo_rechazo
            LET rcei_td_ws6_procedencia_otra.nss_solicitado         = rEntradaISSSTE.nss_imss
            LET rcei_td_ws6_procedencia_otra.resultado_integracion  = rEntradaISSSTE.resulta_int_portab

            CALL inserta_cei_td_ws6_procedencia_otra(rcei_td_ws6_procedencia_otra.*)
            
            DISCONNECT CURRENT
            RETURN rWS6SalidaISSSTE
        END IF
    DISCONNECT CURRENT
        
    RETURN rWS6SalidaISSSTE
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

FUNCTION inserta_cei_td_ws6_procedencia_otra(lcei_td_ws6_procedencia_otra)
    DEFINE lcei_td_ws6_procedencia_otra RECORD LIKE cei_td_ws6_procedencia_otra.*
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT NVL(MAX(folio_consulta),0) + 1",
               "   FROM cei_td_ws6_procedencia_otra"
    PREPARE select_max_cei_td_ws6_procedencia_otra FROM SQL1
    EXECUTE select_max_cei_td_ws6_procedencia_otra INTO lcei_td_ws6_procedencia_otra.folio_consulta

    LET SQL1 = " INSERT INTO cei_td_ws6_procedencia_otra(",
                        " folio_consulta,",
                        " inst_receptor,",
                        " nss_solicitado,",
                        " curp_solicitada,",
                        " folio_externo,",
                        " resultado_integracion,",
                        " fecha_respuesta,",
                        " codigo_resultado,",
                        " motivo_rechazo,",
                        " folio_solicitud",
                        ")",
              "VALUES (", lcei_td_ws6_procedencia_otra.folio_consulta,
                      ", '",lcei_td_ws6_procedencia_otra.inst_receptor, "'",
                      ", '",lcei_td_ws6_procedencia_otra.nss_solicitado, "'",
                      ", '",lcei_td_ws6_procedencia_otra.curp_solicitada, "'",
                      ", '",lcei_td_ws6_procedencia_otra.folio_externo, "'",
                      ", '",lcei_td_ws6_procedencia_otra.resultado_integracion, "'",
                      ", '",lcei_td_ws6_procedencia_otra.fecha_respuesta, "'",
                      ", '",lcei_td_ws6_procedencia_otra.codigo_resultado, "'",
                      ", '",lcei_td_ws6_procedencia_otra.motivo_rechazo, "'",
                      ", '",lcei_td_ws6_procedencia_otra.folio_solicitud, "'",
                     ")"
    PREPARE insert_cei_td_ws6_procedencia_otra FROM SQL1
    EXECUTE insert_cei_td_ws6_procedencia_otra
END FUNCTION

FUNCTION marcarPeriodos(lnum_issste, lFolioSolicitud)
    DEFINE lnum_issste DECIMAL(10,2)
    DEFINE lFolioSolicitud  BIGINT
    DEFINE SQL1             STRING
    DEFINE lrowid BIGINT

    

    LET SQL1 = "\n      SELECT  cuenta_ind.rowid",
               "\n        FROM cuenta_ind",
               "\n  INNER JOIN c_ramo       ON c_ramo.num_ramo            = cuenta_ind.num_ramo",
               "\n  INNER JOIN c_pagaduria  ON c_pagaduria.num_ramo       = cuenta_ind.num_ramo",
               "\n                         AND c_pagaduria.num_pagaduria  = cuenta_ind.num_pagaduria",
               "\n  INNER JOIN c_modalidad  ON c_modalidad.mod_cve        = c_pagaduria.mod_cve",
               "\n  INNER JOIN c_codigo_pos ON c_codigo_pos.codigo_postal = c_pagaduria.codigo_postal",
               "\n    INNER JOIN c_entidad  ON c_entidad.ent_cve          = c_codigo_pos.ent_cve",
               "\n   WHERE cuenta_ind.num_issste = ", lnum_issste,
               " AND (cuenta_ind.uso_pen IS NULL OR cuenta_ind.uso_pen = 410)", --Por re-portabilidad
               "\n     AND LEFT (cuenta_ind.t_movto_inicio,1) <> 'L'",
               "\n     AND (c_modalidad.pensiones   = 'T')", --WS6 marcarPeriodos
               " AND ((
                         cuenta_ind.fecha_inicio > (select MAX(cind2.fecha_termino) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)
                        AND (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)> 0 ) OR
                            (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100) = 0 )",
               "\n  ORDER BY cuenta_ind.fecha_inicio"
    PREPARE select_update_from_cuenta_ind  FROM SQL1
    DECLARE curUpdatecuentaInd CURSOR FOR select_update_from_cuenta_ind
    FOREACH curUpdatecuentaInd INTO lrowid

        CALL fnInserta_bit_cuenta_ind(lrowid, lFolioSolicitud)
        
        LET SQL1 = " UPDATE cuenta_ind",
                   "    SET uso_pen        = '410'",
                   "      ,   usuario      = 'TDIMSS'",
                   "      , fecha_aud      = '", TODAY, "'",
                   "      , hora_aud       = '", CURRENT HOUR TO SECOND, "'",
                   "      , componente_cve = 'PORTABWS'",
                   "      , ip_maquina     = '192.168.2.219'",
                   "  WHERE rowid = ",lrowid,
                   "    AND (uso_pen IS NULL OR uso_pen <> 410)"
        PREPARE update_cuenta_ind FROM SQL1
        EXECUTE update_cuenta_ind
    
    END FOREACH
    
    RETURN TRUE
END FUNCTION

FUNCTION fnInserta_bit_cuenta_ind(lrowid, lFolioSolicitud)
    DEFINE lrowid          BIGINT
    DEFINE lFolioSolicitud BIGINT
    DEFINE rCuentaInd      RECORD LIKE cuenta_ind.*
    DEFINE SQL1            STRING

    DEFINE l_sid           INTEGER
    DEFINE l_pid           INTEGER
    DEFINE l_hostname      VARCHAR(15)
    DEFINE l_username      VARCHAR(8)
    
    DEFINE l_host          CHAR(30)
    DEFINE l_usuario       VARCHAR(8)
    DEFINE l_app           VARCHAR(20)
    DEFINE l_ip            VARCHAR(15)
    
    DEFINE l_hora          VARCHAR(8)
    
    DEFINE ncomponente_cve CHAR(8)
    DEFINE nip_maquina     CHAR(15)

    LET SQL1 = "\n SELECT *",
               "\n   FROM cuenta_ind",
               "\n  WHERE rowid = ", lrowid
    PREPARE select_cuenta_ind_rec FROM SQL1
    EXECUTE select_cuenta_ind_rec INTO rCuentaInd.*

    LET SQL1 = "\n SELECT DBINFO('sessionid')",
               "\n   FROM systables",
               "\n  WHERE tabid = 1"
    PREPARE select_dbinfo FROM SQL1
    EXECUTE select_dbinfo INTO l_sid

    LET SQL1 = "\n SELECT pid, hostname, username",
               "\n   FROM sysmaster:syssessions",
               "\n  WHERE sid = ", l_sid
    PREPARE select_sysmastersessions FROM SQL1
    EXECUTE select_sysmastersessions INTO l_pid , l_hostname, l_username

    LET l_username = "TDIMSS"

    LET SQL1 = "\n SELECT host, pid, usuario, app, ip",
               "\n   FROM bit_gral",
               "\n  WHERE pid = ", l_pid
    PREPARE select_bit_gral FROM SQL1
    EXECUTE select_bit_gral INTO l_host, l_pid, l_usuario, l_app, l_ip

    IF l_usuario IS NULL THEN
        DISPLAY "systables: l_sid:", l_sid
        DISPLAY "syssessions", l_pid,"-", l_hostname,"-", l_username
        DISPLAY "bit_gral:", l_host,"-", l_pid,"-", l_usuario,"-", l_app, l_ip
        LET l_usuario = "TDIMSS"
    END IF

    IF l_app IS NULL THEN
        LET l_app = "PORTABWS"
    END IF

    LET l_hora	= CURRENT HOUR TO MINUTE

    LET ncomponente_cve = "PORTABWS"
    LET nip_maquina     = "192.168.2.219"

    IF l_app IS NULL THEN
        LET l_app = 'N/I'
    END IF

    IF l_host IS NULL THEN
        LET l_host = l_hostname
    END IF

    IF l_ip IS NULL THEN
        LET l_ip = l_hostname
        LET nip_maquina = l_ip
    END IF

    LET SQL1 = " INSERT INTO bit_cuenta_ind("
                                        , "\n f_bit_ci"
        IF rCuentaInd.num_ramo IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, num_ramo"
        END IF
                         LET SQL1 = SQL1, "\n, num_pagaduria"
        IF rCuentaInd.num_issste IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, num_issste"
        END IF
        IF rCuentaInd.cin_id IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, cin_id"
        END IF
                         LET SQL1 = SQL1, "\n, u_version"
                                        , "\n, mod_total_par"
        IF rCuentaInd.mod_cve IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, mod_cve"
        END IF
                         LET SQL1 = SQL1, "\n, fecha_inicio"
                                        , "\n, fecha_termino"
                                        , "\n, t_movto_inicio"
                                        , "\n, t_movto_cierre"
        IF rCuentaInd.periodo_afecta IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, periodo_afecta"
        END IF
                         LET SQL1 = SQL1, "\n, sueldo_issste"
        IF rCuentaInd.uso_pen IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, uso_pen"
        END IF
        IF rCuentaInd.dias_licencia IS NOT NULL THEN
                         LET SQL1 = SQL1, "\n, dias_licencia"
        END IF
                         LET SQL1 = SQL1, "\n, usuario"
                                        , "\n, fecha_aud"
                                        , "\n, hora_aud"
                                        , "\n, componente_cve"
                                        , "\n, ip_maquina"
                                        , "\n, aplicativo"
                                        , "\n, usuario_act"
                                        , "\n, fecha_aud_act"
                                        , "\n, hora_aud_act"
                                        , "\n, componente_act"
                                        , "\n, ip_maquina_act"
                                        , "\n, folio_solicitud"
                                        , ")"
                                  , "\n  VALUES ("
                                            , "\n 0"
        IF rCuentaInd.num_ramo IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.num_ramo
        END IF
                             LET SQL1 = SQL1, "\n, '", rCuentaInd.num_pagaduria, "'"
        IF rCuentaInd.num_issste IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.num_issste
        END IF
        IF rCuentaInd.cin_id IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.cin_id
        END IF
                             LET SQL1 = SQL1, "\n, '", rCuentaInd.u_version, "'"
                                            , "\n, '", rCuentaInd.mod_total_par, "'"
        IF rCuentaInd.mod_cve IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.mod_cve
        END IF
                             LET SQL1 = SQL1, "\n, '", rCuentaInd.fecha_inicio, "'"
                                            , "\n, '", rCuentaInd.fecha_termino, "'"
                                            , "\n, '", rCuentaInd.t_movto_inicio, "'"
                                            , "\n, '", rCuentaInd.t_movto_cierre, "'"
        IF rCuentaInd.periodo_afecta IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.periodo_afecta
        END IF
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.sueldo_issste
        IF rCuentaInd.uso_pen IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.uso_pen
        END IF
        IF rCuentaInd.dias_licencia IS NOT NULL THEN
                             LET SQL1 = SQL1, "\n, '", rCuentaInd.dias_licencia, "'"
        END IF
                             LET SQL1 = SQL1, "\n, '", rCuentaInd.usuario, "'"
                                            , "\n, '", rCuentaInd.fecha_aud, "'"
                                            , "\n, '", rCuentaInd.hora_aud, "'"
                                            , "\n, '", rCuentaInd.componente_cve, "'"
                                            , "\n, '", rCuentaInd.ip_maquina, "'"
                                            , "\n, '", l_app, "'"
                                            , "\n, '", l_usuario, "'"
                                            , "\n, '", TODAY, "'"
                                            , "\n, '", l_hora, "'"
                                            , "\n, '", ncomponente_cve, "'"
                                            , "\n, '", nip_maquina, "'"
                                            , "\n,  ", lFolioSolicitud
                                            , ")"
        TRY
            DISPLAY "Insercion a bit_cuenta_ind:", SQL1
            PREPARE insert_bit_cuenta_ind FROM SQL1
            EXECUTE insert_bit_cuenta_ind
        CATCH
            DISPLAY SQL1
            DISPLAY sqlca.sqlcode
        END TRY
END FUNCTION