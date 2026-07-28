IMPORT util
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
    (title: "Servicios de Portabilidad de derechos - Consulta Robusta Inter Institutos",
        version: "1.0",
        contact:(email: "transferenciaderechos@issste.gob.mx"))

TYPE t_ws3EntradaISSSTE RECORD
    inst_rec_tram      VARCHAR(2),
    nss_imss           VARCHAR(11),
    curp               VARCHAR(18),
    fecha_ini_tram     STRING,
    correo_electronico VARCHAR(50),
    folio_ent_rec_tram VARCHAR(50)
END RECORD

TYPE t_ws3SalidaISSSTE RECORD
    codigo_resultado    VARCHAR(2),
    motivo_rechazo      VARCHAR(3),
    curp                VARCHAR(18),
    primer_apellido     VARCHAR(50),
    segundo_apellido    VARCHAR(50),
    nombre              VARCHAR(50),
    nss                 VARCHAR(11),
    fecha_baja          STRING,
    observaciones       VARCHAR(255),
    fecha_envio         STRING, --DATETIME YEAR TO SECOND,
    periodos_portados   INTEGER,
    eventos_deduccion   INTEGER,
    dias_cotizados      INTEGER,
    dias_descontados    INTEGER,
    dias_reintegrados   INTEGER,
    total_dias          INTEGER,
    arrPeriodos         DYNAMIC ARRAY OF RECORD
        fecha_inicio        STRING,
        fecha_termino       STRING,
        nombre_depen_pat    VARCHAR(255),
        nombre_pagaduria    VARCHAR(255),
        ramo_pagaduria      VARCHAR(11),
        entidad_fede_patron VARCHAR(50),
        sueldo_reg_periodo  DECIMAL(10,2),
        tipo_movimiento     VARCHAR(50)
    END RECORD
END RECORD

DEFINE rcei_td_ws3_robusta_otra RECORD LIKE cei_td_ws3_robusta_otra.*

PUBLIC FUNCTION consultarobustaissste(rWSEntradaISSSTE t_ws3EntradaISSSTE)
    ATTRIBUTES(WSPost,
        WSPath = "/consultarobustaissste",
        WSDescription = "Consulta Robusta ISSSTE")
    RETURNS(t_ws3SalidaISSSTE)

    DEFINE r_ws3SalidaISSSTE t_ws3SalidaISSSTE
    DEFINE lSolicitud                RECORD LIKE cei_solicitud.*
    DEFINE SQL1                      STRING
    DEFINE rWS3Robusta               RECORD LIKE cei_td_ws3_robusta.*
    --DEFINE rWS3RobustaPeriodosISSSTE DYNAMIC ARRAY OF RECORD LIKE cei_td_ws3_robusta_periodos_issste.*
    DEFINE rWS3RobustaPeriodos       DYNAMIC ARRAY OF RECORD
        robPer                       RECORD LIKE cei_td_ws3_robusta_periodos.*
        , usuario                    VARCHAR(8)
        , fecha_aud                  DATE
        , hora_aud                   VARCHAR(8)
        , componente_cve             VARCHAR(8)
        , ip_maquina                 VARCHAR(15)
    END RECORD
    DEFINE idx                       INTEGER
    DEFINE arrPeriodos      DYNAMIC ARRAY OF RECORD
        fecha_inicio        DATE,
        fecha_termino       DATE,
        nombre_depen_pat    VARCHAR(255),
        nombre_pagaduria    VARCHAR(255),
        num_ramo            INTEGER,
        num_pagaduria       STRING,
        entidad_fede_patron VARCHAR(50),
        sueldo_reg_periodo  DECIMAL(10,2),
        tipo_movimiento     VARCHAR(50)
        , usuario           VARCHAR(8)
        , fecha_aud         DATE
        , hora_aud          VARCHAR(8)
        , componente_cve    VARCHAR(8)
        , ip_maquina        VARCHAR(15)
    END RECORD
    DEFINE lExiste INTEGER
    DEFINE lcei_td_solicitud RECORD LIKE cei_td_solicitud.*
    DEFINE lramo_pagaduria STRING

    IF rWSEntradaISSSTE.inst_rec_tram <> "01" THEN
        CONNECT TO "dsipe"
        LET r_ws3SalidaISSSTE.codigo_resultado = "02"
        LET r_ws3SalidaISSSTE.motivo_rechazo = fnMotivoRechazo(23)
        LET r_ws3SalidaISSSTE.observaciones  = "Estructura de datos incorrecta - Instituto receptor ej. 01 "
        
        LET rcei_td_ws3_robusta_otra.codigo_resultado = r_ws3SalidaISSSTE.codigo_resultado
        LET rcei_td_ws3_robusta_otra.correo           = rWSEntradaISSSTE.correo_electronico
        LET rcei_td_ws3_robusta_otra.curp_solicitada  = rWSEntradaISSSTE.curp
        LET rcei_td_ws3_robusta_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
        LET rcei_td_ws3_robusta_otra.fecha_tramite    = rWSEntradaISSSTE.fecha_ini_tram
        LET rcei_td_ws3_robusta_otra.folio_externo    = rWSEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws3_robusta_otra.inst_receptor    = rWSEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws3_robusta_otra.motivo_rechazo   = r_ws3SalidaISSSTE.motivo_rechazo
        LET rcei_td_ws3_robusta_otra.nss_solicitado   = rWSEntradaISSSTE.nss_imss

        CALL guardar_cei_td_ws3_robusta_otra(rcei_td_ws3_robusta_otra.*)
        
        DISCONNECT CURRENT
        RETURN r_ws3SalidaISSSTE
    END IF

    IF length(rWSEntradaISSSTE.nss_imss) <> 11 THEN
        CONNECT TO "dsipe"
        LET r_ws3SalidaISSSTE.codigo_resultado = "02"
        LET r_ws3SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(23)
        LET r_ws3SalidaISSSTE.observaciones    = "Estructura de datos incorrecta - Número de Seguridad Social ej. 01234567890 (11 Caracteres - Alfanúmerico)"

        LET rcei_td_ws3_robusta_otra.codigo_resultado = r_ws3SalidaISSSTE.codigo_resultado
        LET rcei_td_ws3_robusta_otra.correo           = rWSEntradaISSSTE.correo_electronico
        LET rcei_td_ws3_robusta_otra.curp_solicitada  = rWSEntradaISSSTE.curp
        LET rcei_td_ws3_robusta_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
        LET rcei_td_ws3_robusta_otra.fecha_tramite    = rWSEntradaISSSTE.fecha_ini_tram
        LET rcei_td_ws3_robusta_otra.folio_externo    = rWSEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws3_robusta_otra.inst_receptor    = rWSEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws3_robusta_otra.motivo_rechazo   = r_ws3SalidaISSSTE.motivo_rechazo
        LET rcei_td_ws3_robusta_otra.nss_solicitado   = rWSEntradaISSSTE.nss_imss

        CALL guardar_cei_td_ws3_robusta_otra(rcei_td_ws3_robusta_otra.*)
        
        DISCONNECT CURRENT
        RETURN r_ws3SalidaISSSTE
    END IF

    IF length(rWSEntradaISSSTE.curp) <> 18 THEN
        CONNECT TO "dsipe"
        LET r_ws3SalidaISSSTE.codigo_resultado = "02"
        LET r_ws3SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(23)
        LET r_ws3SalidaISSSTE.observaciones    = "Estructura de datos incorrecta - CURP ej. AAAAYYMMDDXZZLVR20 (18 Caracteres - Alfanúmerico)"

        LET rcei_td_ws3_robusta_otra.codigo_resultado = r_ws3SalidaISSSTE.codigo_resultado
        LET rcei_td_ws3_robusta_otra.correo           = rWSEntradaISSSTE.correo_electronico
        LET rcei_td_ws3_robusta_otra.curp_solicitada  = rWSEntradaISSSTE.curp
        LET rcei_td_ws3_robusta_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
        LET rcei_td_ws3_robusta_otra.fecha_tramite    = rWSEntradaISSSTE.fecha_ini_tram
        LET rcei_td_ws3_robusta_otra.folio_externo    = rWSEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws3_robusta_otra.inst_receptor    = rWSEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws3_robusta_otra.motivo_rechazo   = r_ws3SalidaISSSTE.motivo_rechazo
        LET rcei_td_ws3_robusta_otra.nss_solicitado   = rWSEntradaISSSTE.nss_imss

        CALL guardar_cei_td_ws3_robusta_otra(rcei_td_ws3_robusta_otra.*)
        
        DISCONNECT CURRENT
        RETURN r_ws3SalidaISSSTE
    END IF

    IF validaFechaInicio(rWSEntradaISSSTE.fecha_ini_tram) = FALSE THEN
        CONNECT TO "dsipe"

        LET r_ws3SalidaISSSTE.codigo_resultado = "02"
        LET r_ws3SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(23)
        LET r_ws3SalidaISSSTE.observaciones    = "Estructura de datos incorrecta - Fecha ej. DD/MM/YYYY HH:MM:SS"
        
        LET rcei_td_ws3_robusta_otra.codigo_resultado = r_ws3SalidaISSSTE.codigo_resultado
        LET rcei_td_ws3_robusta_otra.correo           = rWSEntradaISSSTE.correo_electronico
        LET rcei_td_ws3_robusta_otra.curp_solicitada  = rWSEntradaISSSTE.curp
        LET rcei_td_ws3_robusta_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
        LET rcei_td_ws3_robusta_otra.fecha_tramite    = rWSEntradaISSSTE.fecha_ini_tram
        LET rcei_td_ws3_robusta_otra.folio_externo    = rWSEntradaISSSTE.folio_ent_rec_tram
        LET rcei_td_ws3_robusta_otra.inst_receptor    = rWSEntradaISSSTE.inst_rec_tram
        LET rcei_td_ws3_robusta_otra.motivo_rechazo   = r_ws3SalidaISSSTE.motivo_rechazo
        LET rcei_td_ws3_robusta_otra.nss_solicitado   = rWSEntradaISSSTE.nss_imss

        CALL guardar_cei_td_ws3_robusta_otra(rcei_td_ws3_robusta_otra.*)
        
        DISCONNECT CURRENT
        RETURN r_ws3SalidaISSSTE
    END IF

    CONNECT TO "dsipe"
        LET lExiste = 0
--        LET SQL1 = " SELECT COUNT(*)",
--                   "   FROM cei_solicitud",
--                   "  WHERE curp = '", rWSEntradaISSSTE.curp, "'",
--                   "    AND id_estatus = 3"
--        PREPARE select_existe_solicitud_robusta FROM SQL1
--        EXECUTE select_existe_solicitud_robusta INTO lExiste
--
--        IF lExiste > 0 THEN
--            LET r_ws3SalidaISSSTE.codigo_resultado = "02"
--            LET r_ws3SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(25)
--            LET r_ws3SalidaISSSTE.observaciones    = fnDescripcionRechazo(25)
--
--            LET rcei_td_ws3_robusta_otra.codigo_resultado = r_ws3SalidaISSSTE.codigo_resultado
--            LET rcei_td_ws3_robusta_otra.correo           = rWSEntradaISSSTE.correo_electronico
--            LET rcei_td_ws3_robusta_otra.curp_solicitada  = rWSEntradaISSSTE.curp
--            LET rcei_td_ws3_robusta_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
--            LET rcei_td_ws3_robusta_otra.fecha_tramite    = rWSEntradaISSSTE.fecha_ini_tram
--            LET rcei_td_ws3_robusta_otra.folio_externo    = rWSEntradaISSSTE.folio_ent_rec_tram
--            LET rcei_td_ws3_robusta_otra.inst_receptor    = rWSEntradaISSSTE.inst_rec_tram
--            LET rcei_td_ws3_robusta_otra.motivo_rechazo   = r_ws3SalidaISSSTE.motivo_rechazo
--            LET rcei_td_ws3_robusta_otra.nss_solicitado   = rWSEntradaISSSTE.nss_imss
--            
--            CALL guardar_cei_td_ws3_robusta_otra(rcei_td_ws3_robusta_otra.*)
--            DISCONNECT CURRENT
--            RETURN r_ws3SalidaISSSTE
--        END IF
        
        LET SQL1 = " SELECT COUNT(*)",
                   "   FROM cei_solicitud",
                   "  WHERE curp = '", rWSEntradaISSSTE.curp, "'",
                   "    AND id_estatus = 1"
        PREPARE select_existe_solicitud_robusta_00 FROM SQL1
        EXECUTE select_existe_solicitud_robusta_00 INTO lExiste

        IF lExiste > 0 THEN
            CALL fnRecuperaSolicitud(rWSEntradaISSSTE.curp) RETURNING lSolicitud.*

            IF tiempo(lSolicitud.fecha_solicitud) = TRUE THEN
                LET SQL1 = " UPDATE cei_solicitud",
                           "    SET id_estatus = 2,",
                           "        id_motivorechazo = 45",
                           "  WHERE folio_solicitud = ", lSolicitud.folio_solicitud
                PREPARE update_cei_solicitud FROM SQL1
                EXECUTE update_cei_solicitud
                LET r_ws3SalidaISSSTE.codigo_resultado = "02"
                LET r_ws3SalidaISSSTE.motivo_rechazo   = fnMotivoRechazo(54) --45
                LET r_ws3SalidaISSSTE.observaciones    = fnDescripcionRechazo(54) --45

                LET rcei_td_ws3_robusta_otra.codigo_resultado = r_ws3SalidaISSSTE.codigo_resultado
                LET rcei_td_ws3_robusta_otra.correo           = rWSEntradaISSSTE.correo_electronico
                LET rcei_td_ws3_robusta_otra.curp_solicitada  = rWSEntradaISSSTE.curp
                LET rcei_td_ws3_robusta_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
                LET rcei_td_ws3_robusta_otra.fecha_tramite    = rWSEntradaISSSTE.fecha_ini_tram
                LET rcei_td_ws3_robusta_otra.folio_externo    = rWSEntradaISSSTE.folio_ent_rec_tram
                LET rcei_td_ws3_robusta_otra.inst_receptor    = rWSEntradaISSSTE.inst_rec_tram
                LET rcei_td_ws3_robusta_otra.motivo_rechazo   = r_ws3SalidaISSSTE.motivo_rechazo
                LET rcei_td_ws3_robusta_otra.nss_solicitado   = rWSEntradaISSSTE.nss_imss
                
                CALL guardar_cei_td_ws3_robusta_otra(rcei_td_ws3_robusta_otra.*)
                
                DISCONNECT CURRENT
                RETURN r_ws3SalidaISSSTE
            END IF
            
            IF lSolicitud.id_estatus = 1 THEN
                CALL arrPeriodos.clear()
                CALL validaTraslapeIG(lSolicitud.num_issste, lSolicitud.folio_solicitud)
                CALL f_obt_periodos(lSolicitud.num_issste) RETURNING arrPeriodos
                FOR idx = 1 TO arrPeriodos.getLength()
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].fecha_inicio        = arrPeriodos[idx].fecha_inicio
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].fecha_termino       = arrPeriodos[idx].fecha_termino
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].nombre_depen_pat    = arrPeriodos[idx].nombre_depen_pat
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].nombre_pagaduria    = arrPeriodos[idx].nombre_pagaduria
                    LET lramo_pagaduria = arrPeriodos[idx].num_ramo USING "&&&&&"
                    LET lramo_pagaduria = lramo_pagaduria||'-'||arrPeriodos[idx].num_pagaduria
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].ramo_pagaduria      = lramo_pagaduria--arrPeriodos[idx].num_ramo USING "&&&&&"||"-"||arrPeriodos[idx].num_ramo USING "&&&&&"||"-"||arrPeriodos[idx].num_pagaduria
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].entidad_fede_patron = arrPeriodos[idx].entidad_fede_patron
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].sueldo_reg_periodo  = arrPeriodos[idx].sueldo_reg_periodo
                    LET r_ws3SalidaISSSTE.arrPeriodos[idx].tipo_movimiento     = arrPeriodos[idx].tipo_movimiento

                    LET rWS3RobustaPeriodos[idx].robPer.entidad_patron    = arrPeriodos[idx].entidad_fede_patron
                    LET rWS3RobustaPeriodos[idx].robPer.fecha_inicio      = arrPeriodos[idx].fecha_inicio
                    LET rWS3RobustaPeriodos[idx].robPer.fecha_termino     = arrPeriodos[idx].fecha_termino
                    LET rWS3RobustaPeriodos[idx].robPer.folio_solicitud   = lSolicitud.folio_solicitud
                    LET rWS3RobustaPeriodos[idx].robPer.id_periodo_ws     = idx
                    LET rWS3RobustaPeriodos[idx].robPer.nombre_pagaduria  = arrPeriodos[idx].nombre_pagaduria
                    LET rWS3RobustaPeriodos[idx].robPer.nombre_patron     = arrPeriodos[idx].nombre_depen_pat
                    LET rWS3RobustaPeriodos[idx].robPer.patron_ramo_pag   = lramo_pagaduria--arrPeriodos[idx].num_ramo USING "&&&&&"||"-"||arrPeriodos[idx].num_pagaduria
                    LET rWS3RobustaPeriodos[idx].robPer.sueldo            = arrPeriodos[idx].sueldo_reg_periodo
                    LET rWS3RobustaPeriodos[idx].robPer.tipo_movimiento   = arrPeriodos[idx].tipo_movimiento

                    LET rWS3RobustaPeriodos[idx].usuario        = arrPeriodos[idx].usuario
                    LET rWS3RobustaPeriodos[idx].fecha_aud      = arrPeriodos[idx].fecha_aud
                    LET rWS3RobustaPeriodos[idx].hora_aud       = arrPeriodos[idx].hora_aud
                    LET rWS3RobustaPeriodos[idx].componente_cve = arrPeriodos[idx].componente_cve
                    LET rWS3RobustaPeriodos[idx].ip_maquina     = arrPeriodos[idx].ip_maquina
                    
                END FOR

                LET r_ws3SalidaISSSTE.codigo_resultado  = "01"
                LET r_ws3SalidaISSSTE.curp              = lSolicitud.curp
                LET r_ws3SalidaISSSTE.dias_cotizados    = dias_cot(lSolicitud.num_issste)
                LET r_ws3SalidaISSSTE.dias_descontados  = 0
                LET r_ws3SalidaISSSTE.dias_reintegrados = 0
                LET r_ws3SalidaISSSTE.periodos_portados = f_obt_periodos_porttados(lSolicitud.num_issste)
                LET r_ws3SalidaISSSTE.eventos_deduccion = 0 --rWS3RobustaPeriodosISSSTE.getLength() - r_ws3SalidaISSSTE.periodos_portados
                LET r_ws3SalidaISSSTE.fecha_baja        = lSolicitud.fecha_baja
                LET r_ws3SalidaISSSTE.fecha_envio       = rWSEntradaISSSTE.fecha_ini_tram
                IF lSolicitud.id_motivorechazo IS NOT NULL THEN
                    LET SQL1 = " SELECT motivo_rechazo",
                               "   FROM cei_cat_motivorechazo",
                               "  WHERE id_motivorechazo = ", lSolicitud.id_motivorechazo
                    PREPARE select_motivo_rechazo FROM SQL1
                    EXECUTE select_motivo_rechazo INTO r_ws3SalidaISSSTE.motivo_rechazo
                END IF
                LET r_ws3SalidaISSSTE.nombre            = lSolicitud.nombre
                LET r_ws3SalidaISSSTE.nss               = lSolicitud.num_issste
                LET r_ws3SalidaISSSTE.observaciones     = lSolicitud.observaciones
                LET r_ws3SalidaISSSTE.primer_apellido   = lSolicitud.primer_apellido
                LET r_ws3SalidaISSSTE.segundo_apellido  = lSolicitud.segundo_apellido
                LET r_ws3SalidaISSSTE.total_dias        = r_ws3SalidaISSSTE.dias_cotizados + r_ws3SalidaISSSTE.dias_descontados + r_ws3SalidaISSSTE.dias_reintegrados

                LET rWS3Robusta.codigo_resultado  = r_ws3SalidaISSSTE.codigo_resultado
                LET rWS3Robusta.curp              = r_ws3SalidaISSSTE.curp
                LET rWS3Robusta.dias_cotizados    = r_ws3SalidaISSSTE.dias_cotizados
                LET rWS3Robusta.dias_descontados  = r_ws3SalidaISSSTE.dias_descontados
                LET rWS3Robusta.dias_reintegrados = r_ws3SalidaISSSTE.dias_reintegrados
                LET rWS3Robusta.eventos_deduccion = r_ws3SalidaISSSTE.eventos_deduccion
                LET rWS3Robusta.fecha_baja        = r_ws3SalidaISSSTE.fecha_baja
                CALL util.Datetime.parse(r_ws3SalidaISSSTE.fecha_envio,"%d/%m/%Y %H:%M:%S") RETURNING rWS3Robusta.fecha_envio 
                LET rWS3Robusta.fecha_respuesta   = CURRENT YEAR TO SECOND
                LET rWS3Robusta.folio_solicitud   = lSolicitud.folio_solicitud
                LET rWS3Robusta.motivo_rechazo    = r_ws3SalidaISSSTE.motivo_rechazo
                LET rWS3Robusta.nombre            = r_ws3SalidaISSSTE.nombre
                LET rWS3Robusta.nss               = r_ws3SalidaISSSTE.nss
                LET rWS3Robusta.observaciones     = r_ws3SalidaISSSTE.observaciones
                LET rWS3Robusta.periodos_portados = r_ws3SalidaISSSTE.periodos_portados
                LET rWS3Robusta.primer_apellido   = r_ws3SalidaISSSTE.primer_apellido
                LET rWS3Robusta.segundo_apellido  = r_ws3SalidaISSSTE.segundo_apellido
                LET rWS3Robusta.total_dias        = r_ws3SalidaISSSTE.total_dias
                
                SELECT NVL(MAX(id_robusta),0) + 1
                  INTO rWS3Robusta.id_robusta
                  FROM cei_td_ws3_robusta
                 WHERE folio_solicitud = lSolicitud.folio_solicitud
                 
                LET lcei_td_solicitud.fecha_respuesta = rWS3Robusta.fecha_respuesta
                LET lcei_td_solicitud.folio_externo   = rWSEntradaISSSTE.folio_ent_rec_tram
                LET lcei_td_solicitud.folio_solicitud = lSolicitud.folio_solicitud
                LET lcei_td_solicitud.inst_receptor   = rWSEntradaISSSTE.inst_rec_tram
                LET lcei_td_solicitud.nss_imss        = rWSEntradaISSSTE.nss_imss
                LET lcei_td_solicitud.nss_issste      = lSolicitud.num_issste
                
                UPDATE cei_td_solicitud
                   SET folio_externo = rWSEntradaISSSTE.folio_ent_rec_tram
                 WHERE folio_solicitud = lSolicitud.folio_solicitud
                 
                CALL fnInserta_cei_td_ws3_robusta(rWS3Robusta.*)
                FOR idx = 1 TO rWS3RobustaPeriodos.getLength()
                    LET rWS3RobustaPeriodos[idx].robPer.folio_solicitud = lSolicitud.folio_solicitud
                    LET rWS3RobustaPeriodos[idx].robPer.id_robusta = rWS3Robusta.id_robusta
                        
                    CALL f_inserta_periodos(rWS3RobustaPeriodos[idx])
                END FOR
            END IF
        ELSE
            LET r_ws3SalidaISSSTE.codigo_resultado = "02"
            LET r_ws3SalidaISSSTE.motivo_rechazo = fnMotivoRechazo(45)
            LET r_ws3SalidaISSSTE.observaciones    = fnDescripcionRechazo(45)
        END IF
    DISCONNECT CURRENT

    RETURN r_ws3SalidaISSSTE
END FUNCTION

FUNCTION fnRecuperaSolicitud(lcurp)
    DEFINE lcurp      STRING
    DEFINE SQL1       STRING
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*

    LET SQL1 = " SELECT FIRST 1 *",
               "   FROM cei_solicitud",
               "  WHERE curp = '", lcurp, "'",
               "    AND id_estatus = 1",
               "    ORDER BY fecha_solicitud DESC"
    PREPARE select_ultima_cei_solciitud FROM SQL1
    EXECUTE select_ultima_cei_solciitud INTO lSolicitud.*

    RETURN lSolicitud.*
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
    
    LET SQL1 = " SELECT cuenta_ind.fecha_inicio
                      , cuenta_ind.fecha_termino",
               "      , cuenta_ind.uso_pen
                      , cuenta_ind.u_version
                      , c_pagaduria.mod_cve", 
               "   FROM cuenta_ind, c_modalidad, c_pagaduria",  
               "  WHERE cuenta_ind.num_issste = ", lde_num_issste,
               "    AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11')",
               "    AND cuenta_ind.num_ramo      = c_pagaduria.num_ramo",
               "    AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria",
               "    AND c_pagaduria.mod_cve      = c_modalidad.mod_cve",
               "    AND (c_modalidad.pensiones   = 'T')", --WS3 dias_cot
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

PUBLIC FUNCTION f_obt_periodos(lde_num_issste)
TYPE tPeriodos RECORD
        fecha_inicio        DATE,
        fecha_termino       DATE,
        nombre_depen_pat    VARCHAR(255),
        nombre_pagaduria    VARCHAR(255),
        num_ramo            INTEGER,
        num_pagaduria       STRING,
        entidad_fede_patron VARCHAR(50),
        sueldo_reg_periodo  DECIMAL(10,2),
        tipo_movimiento     VARCHAR(50)
        , usuario           VARCHAR(8)
        , fecha_aud         DATE
        , hora_aud          VARCHAR(8)
        , componente_cve    VARCHAR(8)
        , ip_maquina        VARCHAR(15)
    END RECORD
    DEFINE arrPeriodos      DYNAMIC ARRAY OF tPeriodos
    DEFINE rPeriodos        tPeriodos
    DEFINE ls_sqlrxt        STRING 
    DEFINE li_numreg        INTEGER 
    DEFINE lde_num_issste   LIKE directo.num_issste

    CALL arrPeriodos.clear()

   -- RECUPERAR TODOS LOS QUE NO ESTAN MARCADOS O LOS POSTERIORES A LA MARCA IG
    LET ls_sqlrxt = " SELECT  cuenta_ind.fecha_inicio
       , cuenta_ind.fecha_termino
       , rtrim(c_ramo.nombre) as ramo
       , rtrim(c_pagaduria.nombre) as pagaduria
       , c_pagaduria.num_ramo
       , c_pagaduria.num_pagaduria
       , CASE WHEN (length(c_entidad.nombre) = 0 OR c_entidad.nombre IS NULL) THEN 'CIUDAD DE MEXICO' ELSE rtrim(c_entidad.nombre) END entidad
       , cuenta_ind.sueldo_issste
       , t_movto_inicio
       , cuenta_ind.usuario
       , cuenta_ind.fecha_aud
       , cuenta_ind.hora_aud
       , cuenta_ind.componente_cve
       , cuenta_ind.ip_maquina
   FROM cuenta_ind
   INNER JOIN c_ramo on c_ramo.num_ramo = cuenta_ind.num_ramo
   INNER JOIN c_pagaduria on c_pagaduria.num_ramo = cuenta_ind.num_ramo
                         and c_pagaduria.num_pagaduria = cuenta_ind.num_pagaduria
   INNER JOIN c_modalidad on c_modalidad.mod_cve = c_pagaduria.mod_cve
    LEFT JOIN c_codigo_pos on c_codigo_pos.codigo_postal = c_pagaduria.codigo_postal
    LEFT JOIN c_entidad on c_entidad.ent_cve = c_codigo_pos.ent_cve
  WHERE cuenta_ind.num_issste = ", lde_num_issste,
    " AND (cuenta_ind.uso_pen IS NULL OR cuenta_ind.uso_pen = 410)", --Por re-portabilidad
    " AND (c_modalidad.pensiones   = 'T')", -- WS3 f_obt_periodos para la Salida
    " AND ((
         cuenta_ind.fecha_inicio > (select MAX(cind2.fecha_termino) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)
        AND (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)> 0 ) OR
            (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100) = 0 )
 ORDER BY cuenta_ind.fecha_inicio"
 
    PREPARE pr_periodos FROM ls_sqlrxt
    DECLARE cur_periodos CURSOR FOR pr_periodos
    LET li_numreg=1
    FOREACH cur_periodos
        INTO rPeriodos.fecha_inicio
           , rPeriodos.fecha_termino
           , rPeriodos.nombre_depen_pat
           , rPeriodos.nombre_pagaduria
           , rPeriodos.num_ramo
           , rPeriodos.num_pagaduria
           , rPeriodos.entidad_fede_patron
           , rPeriodos.sueldo_reg_periodo
           , rPeriodos.tipo_movimiento
           , rPeriodos.usuario
           , rPeriodos.fecha_aud
           , rPeriodos.hora_aud
           , rPeriodos.componente_cve
           , rPeriodos.ip_maquina
        IF rPeriodos.tipo_movimiento="L1" OR rPeriodos.tipo_movimiento="L2"  OR rPeriodos.tipo_movimiento="L3" OR rPeriodos.tipo_movimiento="L4"
                OR rPeriodos.tipo_movimiento="L5"  OR rPeriodos.tipo_movimiento="L6"  OR rPeriodos.tipo_movimiento="L7"  OR rPeriodos.tipo_movimiento="L8"
                OR rPeriodos.tipo_movimiento="L9"  OR rPeriodos.tipo_movimiento="L10"  OR rPeriodos.tipo_movimiento="L11" THEN 

            LET arrPeriodos[li_numreg].tipo_movimiento     = "PERIODO_NO_COTIZABLE"
        ELSE
            LET arrPeriodos[li_numreg].tipo_movimiento     = "PERIODO_COTIZABLE"
        END IF

        LET arrPeriodos[li_numreg].fecha_inicio        = rPeriodos.fecha_inicio
        LET arrPeriodos[li_numreg].fecha_termino       = rPeriodos.fecha_termino
        LET arrPeriodos[li_numreg].nombre_depen_pat    = rPeriodos.nombre_depen_pat CLIPPED
        LET arrPeriodos[li_numreg].nombre_pagaduria    = rPeriodos.nombre_pagaduria CLIPPED
        LET arrPeriodos[li_numreg].num_ramo            = rPeriodos.num_ramo
        LET arrPeriodos[li_numreg].num_pagaduria       = rPeriodos.num_pagaduria
        LET arrPeriodos[li_numreg].entidad_fede_patron = rPeriodos.entidad_fede_patron CLIPPED
        LET arrPeriodos[li_numreg].sueldo_reg_periodo  = rPeriodos.sueldo_reg_periodo
        LET arrPeriodos[li_numreg].usuario             = rPeriodos.usuario
        LET arrPeriodos[li_numreg].fecha_aud           = rPeriodos.fecha_aud
        LET arrPeriodos[li_numreg].hora_aud            = rPeriodos.hora_aud
        LET arrPeriodos[li_numreg].componente_cve      = rPeriodos.componente_cve
        LET arrPeriodos[li_numreg].ip_maquina          = rPeriodos.ip_maquina
        
        LET li_numreg = li_numreg + 1

    END FOREACH
    
    RETURN arrPeriodos
END FUNCTION

FUNCTION f_obt_periodos_porttados(lde_numissste)
    DEFINE lde_numissste    LIKE directo.num_issste
    DEFINE ls_sqltxt        STRING
   DEFINE li_total          INTEGER  

    LET ls_sqltxt=  " SELECT count(*) ",
                    " FROM cuenta_ind, c_modalidad, c_pagaduria ",
                    " WHERE cuenta_ind.num_issste = ?",
                    " AND cuenta_ind.t_movto_inicio NOT IN ('L1','L2','L3','L4','L5','L6','L7','L8','L9','L10','L11') ",
                    " AND cuenta_ind.num_ramo = c_pagaduria.num_ramo ",
                    " AND cuenta_ind.num_pagaduria = c_pagaduria.num_pagaduria ",
                    " AND c_pagaduria.mod_cve = c_modalidad.mod_cve ",
                    " AND (cuenta_ind.uso_pen IS NULL OR cuenta_ind.uso_pen = 410)", -- Por re-portabilidad
                    " AND (c_modalidad.pensiones   = 'T')", --WS3 f_obt_periodos_porttados
                    " AND ((
                         cuenta_ind.fecha_inicio > (select MAX(cind2.fecha_termino) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)
                        AND (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100)> 0 ) OR
                            (select COUNT(cind2.num_issste) from cuenta_ind cind2 where cind2.num_issste = cuenta_ind.num_issste and cind2.uso_pen = 100) = 0 )"
    PREPARE sid_count_periodos FROM ls_sqltxt
    EXECUTE sid_count_periodos INTO li_total USING lde_numissste

    RETURN li_total

END FUNCTION

FUNCTION f_inserta_periodos(r_consRobPeriodos)
    DEFINE r_consRobPeriodos RECORD
        robPer              RECORD LIKE cei_td_ws3_robusta_periodos.*
        , usuario           VARCHAR(8)
        , fecha_aud         DATE
        , hora_aud          VARCHAR(8)
        , componente_cve    VARCHAR(8)
        , ip_maquina        VARCHAR(15)
    END RECORD
    DEFINE ls_query                 STRING
    DEFINE SQL1                     STRING

    LET SQL1 = " SELECT NVL(MAX(id_periodo_ws),0) + 1",
               "   FROM cei_td_ws3_robusta_periodos"
    PREPARE select_max_cei_td_ws3_robusta_periodos FROM SQL1
    EXECUTE select_max_cei_td_ws3_robusta_periodos INTO r_consRobPeriodos.robPer.id_periodo_ws

    --WHENEVER ERROR CONTINUE

        LET ls_query="\n INSERT INTO cei_td_ws3_robusta_periodos(",
                              "\n    id_periodo_ws",
                              "\n  , folio_solicitud",
                              "\n  , fecha_inicio",
                              "\n  , fecha_termino",
                              "\n  , nombre_patron",
                              "\n  , nombre_pagaduria",
                              "\n  , patron_ramo_pag",
                              "\n  , entidad_patron",
                              "\n  , sueldo",
                              "\n  , tipo_movimiento",
                              "\n  , id_robusta",
                              "\n  , usuario",
                              "\n  , fecha_aud",
                              "\n  , hora_aud",
                              "\n  , componente_cve",
                              "\n  , ip_maquina",
                              "\n  )",
         "\n VALUES("       , r_consRobPeriodos.robPer.id_periodo_ws
                   , "\n,  ", r_consRobPeriodos.robPer.folio_solicitud
                   , "\n, '", r_consRobPeriodos.robPer.fecha_inicio, "'"
                   , "\n, '", r_consRobPeriodos.robPer.fecha_termino, "'"
                   , "\n, '", r_consRobPeriodos.robPer.nombre_patron, "'"
                   , "\n, '", r_consRobPeriodos.robPer.nombre_pagaduria, "'"
                   , "\n, '", r_consRobPeriodos.robPer.patron_ramo_pag, "'"
                   , "\n, '", r_consRobPeriodos.robPer.entidad_patron, "'"
                   , "\n,  ", r_consRobPeriodos.robPer.sueldo
                   , "\n, '", r_consRobPeriodos.robPer.tipo_movimiento, "'"
                   , "\n,  ", r_consRobPeriodos.robPer.id_robusta
                   , "\n, '", r_consRobPeriodos.usuario, "'"
                   , "\n, '", r_consRobPeriodos.fecha_aud, "'"
                   , "\n, '", r_consRobPeriodos.hora_aud, "'"
                   , "\n, '", r_consRobPeriodos.componente_cve, "'"
                   , "\n, '", r_consRobPeriodos.ip_maquina, "'"
         ,"\n)"
         
        PREPARE insert_cei_td_ws3_robusta_periodos FROM ls_query
        EXECUTE insert_cei_td_ws3_robusta_periodos
    --WHENEVER ERROR STOP
END FUNCTION

FUNCTION f_inserta_periodos_issste(r_consRobPeriodos_issste)
    DEFINE r_consRobPeriodos_issste RECORD LIKE cei_td_ws3_robusta_periodos_issste.*
    DEFINE ls_query                 STRING
    DEFINE SQL1                     STRING

    LET SQL1 = " SELECT NVL(MAX(id_periodo_issste),0) + 1",
               "   FROM cei_td_ws3_robusta_periodos_issste"
    PREPARE select_max_cei_td_ws3_robusta_periodos_issste FROM SQL1
    EXECUTE select_max_cei_td_ws3_robusta_periodos_issste INTO r_consRobPeriodos_issste.id_periodo_issste

    --WHENEVER ERROR CONTINUE

        LET ls_query="\n INSERT INTO cei_td_ws3_robusta_periodos_issste (",
                              "\n    id_periodo_issste",
                              "\n  , folio_solicitud",
                              "\n  , fecha_inicio",
                              "\n  , fecha_termino",
                              "\n  , num_ramo",
                              "\n  , num_pagaduria",
                              "\n  , sueldo",
                              "\n  )",
         "\n VALUES("      , r_consRobPeriodos_issste.id_periodo_issste
                   , "\n, ", r_consRobPeriodos_issste.folio_solicitud
                   , "\n, '", r_consRobPeriodos_issste.fecha_inicio, "'"
                   , "\n, '", r_consRobPeriodos_issste.fecha_termino, "'"
                   , "\n, '", r_consRobPeriodos_issste.num_ramo, "'"
                   , "\n, '", r_consRobPeriodos_issste.num_pagaduria, "'"
                   , "\n, ", r_consRobPeriodos_issste.sueldo
         ,"\n)"
         
        PREPARE insert_cei_td_ws3_robusta_periodos_issste FROM ls_query
        EXECUTE insert_cei_td_ws3_robusta_periodos_issste
    --WHENEVER ERROR STOP
END FUNCTION

FUNCTION existePeriodosPortados(lfolio_solicitud)
    DEFINE lfolio_solicitud INTEGER
    DEFINE SQL1 STRING
    DEFINE lExiste INTEGER

    LET lExiste = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_td_ws3_robusta_periodos_issste",
               "  WHERE folio_solicitud = ", lfolio_solicitud
    PREPARE select_cont_periodos_portados FROM SQL1
    EXECUTE select_cont_periodos_portados INTO lExiste

    IF lExiste > 0 THEN
        RETURN TRUE
    END IF

    RETURN FALSE
END FUNCTION

FUNCTION validaFechaInicio(lfecha)
    DEFINE lfecha STRING
    DEFINE lyear  STRING

    IF lfecha.getLength() <> 19 THEN
        DISPLAY "vacio"
        RETURN FALSE
    END IF

    IF lfecha.subString(5,5) = "-" OR lfecha.subString(5,5) = "/" THEN
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

FUNCTION guardar_cei_td_ws3_robusta_otra(lcei_td_ws3_robusta_otra)
    DEFINE lcei_td_ws3_robusta_otra RECORD LIKE cei_td_ws3_robusta_otra.*
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT NVL(MAX(folio_consulta),0) + 1",
               "   FROM cei_td_ws3_robusta_otra"
    PREPARE select_max_folio_00 FROM SQL1
    EXECUTE select_max_folio_00 INTO lcei_td_ws3_robusta_otra.folio_consulta

    LET SQL1 = " INSERT INTO cei_td_ws3_robusta_otra(folio_consulta,",
                                                   " inst_receptor,",
                                                   " nss_solicitado,",
                                                   " curp_solicitada,",
                                                   " fecha_tramite,",
                                                   " correo,",
                                                   " folio_externo,",
                                                   " fecha_respuesta,",
                                                   " motivo_rechazo,",
                                                   " codigo_resultado)",
               "VALUES ( ", lcei_td_ws3_robusta_otra.folio_consulta,
                     ", '", lcei_td_ws3_robusta_otra.inst_receptor, "'",
                     ", '", lcei_td_ws3_robusta_otra.nss_solicitado, "'",
                     ", '", lcei_td_ws3_robusta_otra.curp_solicitada, "'",
                     ", '", lcei_td_ws3_robusta_otra.fecha_tramite, "'",
                     ", '", lcei_td_ws3_robusta_otra.correo, "'",
                     ", '", lcei_td_ws3_robusta_otra.folio_externo, "'",
                     ", '", lcei_td_ws3_robusta_otra.fecha_respuesta, "'",
                     ", '", lcei_td_ws3_robusta_otra.motivo_rechazo, "'",
                     ", '", lcei_td_ws3_robusta_otra.codigo_resultado, "'",
                     ")"
    PREPARE insert_cei_td_ws3_robusta_otra FROM SQL1
    EXECUTE insert_cei_td_ws3_robusta_otra
END FUNCTION

FUNCTION fnInserta_cei_td_ws3_robusta(rRobusta)
    DEFINE rRobusta RECORD LIKE cei_td_ws3_robusta.*

    INSERT INTO cei_td_ws3_robusta
         VALUES (rRobusta.*)
END FUNCTION

FUNCTION insert_cei_td_solicitud(lcei_td_solicitud)
    DEFINE SQL1 STRING
    DEFINE lcei_td_solicitud RECORD LIKE cei_td_solicitud.*

    IF lcei_td_solicitud.folio_externo IS NOT NULL THEN
        LET SQL1 = "\n INSERT INTO cei_td_solicitud(folio_solicitud, inst_receptor, nss_imss, nss_issste, fecha_respuesta)",
                   "\n      VALUES(", lcei_td_solicitud.folio_solicitud,
                   "\n           ,'", lcei_td_solicitud.inst_receptor USING "&&", "'",
                   "\n           , '", lcei_td_solicitud.nss_imss,"'",
                   "\n           , '", lcei_td_solicitud.nss_issste, "'",
                   "\n           , '", CURRENT YEAR TO SECOND, "'",
                   "\n )"
    ELSE
        LET SQL1 = "\n INSERT INTO cei_td_solicitud(folio_solicitud, inst_receptor, folio_externo, nss_imss, nss_issste, fecha_respuesta)",
                   "\n      VALUES(", lcei_td_solicitud.folio_solicitud,
                   "\n           ,'", lcei_td_solicitud.inst_receptor USING "&&", "'",
                   "\n           ,'", lcei_td_solicitud.folio_externo, "'",
                   "\n           , '", lcei_td_solicitud.nss_imss,"'",
                   "\n           , '", lcei_td_solicitud.nss_issste, "'",
                   "\n           , '", CURRENT YEAR TO SECOND, "'",
                   "\n )"
    END IF
        DISPLAY "Insertat cei_td_solcitud: ", SQL1
        PREPARE insert_cei_td_solcitud FROM SQL1
        EXECUTE insert_cei_td_solcitud
END FUNCTION

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

FUNCTION tiempo(lfecha)
    DEFINE lfecha DATETIME YEAR TO SECOND
    DEFINE fecha_actual DATETIME YEAR TO SECOND
    DEFINE diferencia INTERVAL DAY(4) TO SECOND
    DEFINE t_transcurrido INTERVAL HOUR TO SECOND

    LET fecha_actual = CURRENT YEAR TO SECOND

    LET diferencia = fecha_actual - lfecha

    DISPLAY "Fecha: ", lfecha
    DISPLAY "Fecha Actual: ", fecha_actual

    LET t_transcurrido = "00:04:59"
    
    IF diferencia > t_transcurrido THEN

        RETURN TRUE
    END IF
    
    RETURN FALSE
END FUNCTION

FUNCTION validaTraslapeIG(lnum_issste, lFolioSolicitud)
    DEFINE lnum_issste DECIMAL(10,2)
    DEFINE SQL1 STRING
    DEFINE fecha_termino DATE
    DEFINE rCuentaInd RECORD LIKE cuenta_ind.*
    DEFINE rCuentaIndNew RECORD LIKE cuenta_ind.*
    DEFINE lrowid BIGINT
    DEFINE lFolioSolicitud BIGINT

    CALL validaExisteIG(lnum_issste) RETURNING fecha_termino
    
    LET SQL1 = " SELECT ci.*, ci.rowid
                   FROM cuenta_ind ci 
                  INNER JOIN c_pagaduria p ON p.num_ramo = ci.num_ramo AND p.num_pagaduria = ci.num_pagaduria
                  INNER JOIN c_modalidad m ON m.mod_cve  = p.mod_cve 
                  WHERE ci.num_issste IN (SELECT ci2.num_issste 
                                            FROM cuenta_ind ci2
                                           WHERE ci2.num_issste = ci.num_issste 
                                             AND ci2.fecha_inicio< '",fecha_termino, "' 
                                             AND (ci2.fecha_termino > '",fecha_termino, "'
                                             AND ci2.uso_pen is null))
                    AND ci.fecha_inicio < '",fecha_termino, "'
                    AND (ci.fecha_termino IS NULL OR ci.fecha_termino > '",fecha_termino, "')
                    AND m.pensiones = 'T'
                    AND ci.num_issste = ",lnum_issste,"
                    AND ci.uso_pen IS NULL
                ORDER BY fecha_termino"
    PREPARE select_cuenta_ind_01 FROM SQL1
    DECLARE curCuentaIndTraslapesIG CURSOR FOR select_cuenta_ind_01
    FOREACH curCuentaIndTraslapesIG INTO rCuentaInd.*, lrowid

    CALL fnInserta_bit_cuenta_ind_ws3(lrowid, lFolioSolicitud)    
        LET rCuentaIndNew.*           = rCuentaInd.*

        LET rCuentaIndNew.fecha_inicio    = fecha_termino + 1
        LET rCuentaIndNew.usuario         = "TDIMSS"
        LET rCuentaIndNew.fecha_aud       = TODAY
        LET rCuentaIndNew.hora_aud        = CURRENT HOUR TO SECOND
        LET rCuentaIndNew.componente_cve  = "PORTABWS"
        LET rCuentaIndNew.ip_maquina      = "192.168.2.219"
        LET rCuentaIndNew.t_movto_inicio  = "MS"


                LET rCuentaIndNew.cin_id  = max_cin_id_cuenta_ind()
                
                INSERT INTO cuenta_ind VALUES(rCuentaIndNew.*)
                
                LET SQL1 = " UPDATE cuenta_ind",
                           "    SET fecha_termino = '",fecha_termino,"'",
                           "  WHERE cin_id = ",rCuentaInd.cin_id
                PREPARE update_cuenta_ind_traslapeIG FROM SQL1
                EXECUTE update_cuenta_ind_traslapeIG

                IF rCuentaInd.t_movto_cierre = "B" THEN
                    LET SQL1 = " UPDATE cuenta_ind",
                               "    SET t_movto_cierre = 'MS'",
                               "  WHERE cin_id = ",rCuentaInd.cin_id
                    PREPARE update_cuenta_ind_traslapeIG_00 FROM SQL1
                    EXECUTE update_cuenta_ind_traslapeIG_00
                END IF
        --COMMIT WORK
        
    END FOREACH
END FUNCTION

FUNCTION max_cin_id_cuenta_ind()
    DEFINE lmax_cin_id BIGINT
    DEFINE SQL1 STRING

    WHILE TRUE
        TRY
            LET SQL1 = " SELECT MAX(ult_folio) + 1",
                       "   FROM folio_ci"
            PREPARE select_max_cind_id FROM SQL1
            EXECUTE select_max_cind_id INTO lmax_cin_id

            LET SQL1 = "UPDATE folio_ci",
                       "   SET ult_folio = ", lmax_cin_id
            PREPARE update_folio_ci FROM SQL1
            EXECUTE update_folio_ci
        CATCH
            DISPLAY "obteniendo folio_ci: ",lmax_cin_id
            DISPLAY "status: ", status
            SLEEP 1
        END TRY
        IF status = 0 THEN
            EXIT WHILE
        END IF
    END WHILE

    RETURN lmax_cin_id
END FUNCTION

FUNCTION validaExisteIG(lnum_issste)
    DEFINE lnum_issste DECIMAL(10,2)
    DEFINE fecha_termino DATE
    DEFINE SQL1 STRING
    
    LET SQL1 = " SELECT MAX(fecha_termino)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND uso_pen = 100"
    PREPARE select_existe_IG_00 FROM SQL1
    EXECUTE select_existe_IG_00 INTO fecha_termino

    RETURN fecha_termino
    
END FUNCTION

FUNCTION fnInserta_bit_cuenta_ind_ws3(lrowid, lFolioSolicitud)
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
                             LET SQL1 = SQL1, "\n,  ", rCuentaInd.dias_licencia, "'"
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