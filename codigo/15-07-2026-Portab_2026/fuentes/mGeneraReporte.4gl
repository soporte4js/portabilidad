IMPORT os
SCHEMA dsipe

TYPE tDatosReporte RECORD
        curp             STRING,
        folio_solicitud  STRING,
        fecha_solicitud  STRING,
        nombre           STRING,
        primer_apellido  STRING,
        segundo_apellido STRING,
        folio_procesar   STRING,
        codigo_resultado STRING,
        motivo_rechazo   STRING,
        observaciones    STRING,
        fecha_nacimiento STRING,
        regimen          STRING,
        nss_issste       STRING,
        situacion_afil   STRING,
        fecha_baja       STRING,
        antiguedad       STRING,
        nss_imss         STRING,
        correo           STRING,
        telefono         STRING,
        usuario          STRING,
        nombre_operador  STRING,
        representacion   STRING
    END RECORD

    TYPE tSATReporte RECORD
        l_val_cer STRING,
        l_val_key STRING,
        rfc       STRING,
        password  STRING
    END RECORD

FUNCTION fnGeneraReporte(lfolio_solicitud, lid_aplicacion, lTipoReporte)
    DEFINE lfolio_solicitud BIGINT
    DEFINE lid_aplicacion INTEGER
    DEFINE lTipoReporte STRING
    DEFINE SQL1 STRING
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    DEFINE rDatosTemp RECORD
        afiliatoria STRING,
        fec_nac DATE,
        nss STRING,
        regimen STRING
    END RECORD
    DEFINE lRepDinPort RECORD LIKE cei_repdinport.*
    DEFINE sfolio_solicitud STRING

    DEFINE rDatosReporte tDatosReporte
    DEFINE rSATReporte tSATReporte
    DEFINE lExisteNuevo INTEGER

    DEFINE nombre_archivo STRING

    LET lExisteNuevo = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_repdinport",
               "  WHERE folio_solicitud = ", lfolio_solicitud
    PREPARE select_existe_cei_repdinport FROM SQL1
    EXECUTE select_existe_cei_repdinport INTO lExisteNuevo

    LET SQL1 = " SELECT *",
               "   FROM cei_solicitud",
               "  WHERE folio_solicitud = ", lfolio_solicitud
    PREPARE select_recupera_solicitud FROM SQL1

    IF lExisteNuevo > 0 THEN
        EXECUTE select_recupera_solicitud INTO lSolicitud.*

        CALL fnRecuperaDatosDirecto(lSolicitud.curp)
             RETURNING lSolicitud.nombre,
                       lSolicitud.num_issste,
                       lSolicitud.primer_apellido,
                       lSolicitud.segundo_apellido,
                       lSolicitud.fecha_baja,
                       rDatosTemp.afiliatoria,
                       rDatosTemp.fec_nac,
                       rDatosTemp.nss

        LOCATE lRepDinPort.cerificado_b64 IN MEMORY
        LOCATE lRepDinPort.clave_b64      IN MEMORY
        LOCATE lRepDinPort.pass_cert_b64  IN MEMORY
        
        LET SQL1 = " SELECT *",
                   "   FROM cei_repdinport",
                   "  WHERE folio_solicitud = ", lfolio_solicitud
        PREPARE select_cei_repdinport FROM SQL1
        EXECUTE select_cei_repdinport INTO lRepDinPort.*

        CALL fnRecuperaRegimen(lSolicitud.curp, lSolicitud.num_issste) RETURNING rDatosTemp.regimen

        CALL fnAsignaDatosReporte(lSolicitud.*) RETURNING rDatosReporte.*
        LET rDatosReporte.regimen = rDatosTemp.regimen
        LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
        LET rDatosReporte.antiguedad       = lRepDinPort.dias_cotizados
        LET rDatosReporte.situacion_afil   = lRepDinPort.sit_afil
        IF lRepDinPort.codigo_resultado IS NULL THEN
            LET rDatosReporte.codigo_resultado = "-"
        ELSE
            LET rDatosReporte.codigo_resultado = lRepDinPort.codigo_resultado
        END IF
        IF lRepDinPort.folio_procesar IS NULL THEN
            LET rDatosReporte.folio_procesar   = "-"
        ELSE
            LET rDatosReporte.folio_procesar   = lRepDinPort.folio_procesar
        END IF
        IF lSolicitud.id_motivorechazo IS NOT NULL THEN
            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(lSolicitud.id_motivorechazo)||"-"||fnDescripcionRechazo(lSolicitud.id_motivorechazo)
        ELSE
            LET rDatosReporte.motivo_rechazo = "-"
        END IF
        LET rDatosReporte.observaciones    = lSolicitud.observaciones
        LET rDatosReporte.fecha_baja       = lRepDinPort.fecha_baja
        
        IF lid_aplicacion = 1 THEN
            IF lTipoReporte = "S" THEN
                CALL reporteTransferencia_solicitud(rDatosReporte.*, rSATReporte.*)
            ELSE
                CALL reporteTransferenciaResolucion(rDatosReporte.*, rSATReporte.*)
            END IF
        ELSE
            IF lTipoReporte = "S" THEN
                CALL reporteTransferenciaNoFirmadoSolicitud(rDatosReporte.*)
            ELSE
                CALL ReporteTransferenciaNoFirmadoResolucion(rDatosReporte.*)
            END IF
        END IF
    ELSE
        EXECUTE select_recupera_solicitud INTO lSolicitud.*
        LET sfolio_solicitud = lSolicitud.folio_solicitud
        TRY
            LET nombre_archivo = lTipoReporte||"_"||lSolicitud.curp||"_", sfolio_solicitud CLIPPED,"_firmada.pdf"
            IF os.Path.exists(nombre_archivo) = TRUE THEN
                CALL CopArcRpt(nombre_archivo)
            ELSE
                LET nombre_archivo = lTipoReporte||"_"||lSolicitud.curp||"_", sfolio_solicitud CLIPPED,".pdf"
                IF os.Path.exists(nombre_archivo) = TRUE THEN
                    CALL CopArcRpt(nombre_archivo)
                ELSE
                    MESSAGE "Solicitud no disponible: ", nombre_archivo
                    DISPLAY "No existe No firmado"
                END IF
            END IF
        CATCH
            MESSAGE "Solicitud no disponible: ", nombre_archivo
            DISPLAY "Error por algo: ", status
        END TRY
    END IF
END FUNCTION