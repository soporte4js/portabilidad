IMPORT xml
IMPORT security
IMPORT os
IMPORT FGL greruntime

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

DEFINE cadena_original STRING
DEFINE lstdel INTEGER

FUNCTION reporteTransferenciaNoFirmado(rDatosReporte)
    DEFINE rDatosReporte tDatosReporte
    DEFINE lHandler om.SaxDocumentHandler
    DEFINE lRepDinPort RECORD LIKE cei_repdinport.*
    DEFINE SQL1 STRING
    DEFINE lExiste INTEGER

    LET lExiste = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_repdinport",
               "  WHERE folio_solicitud = ", rDatosReporte.folio_solicitud
    PREPARE select_existe_reporte_transf_no_firmado FROM SQL1
    EXECUTE select_existe_reporte_transf_no_firmado INTO lExiste

    IF lExiste = 0 THEN
        LET lRepDinPort.codigo_resultado = rDatosReporte.codigo_resultado
        LET lRepDinPort.dias_cotizados   = rDatosReporte.antiguedad
        LET lRepDinPort.folio_procesar   = rDatosReporte.folio_procesar
        LET lRepDinPort.folio_solicitud  = rDatosReporte.folio_solicitud
        LET lRepDinPort.sit_afil         = rDatosReporte.situacion_afil
        IF rDatosReporte.fecha_baja = "31/12/1899" THEN
            LET lRepDinPort.fecha_baja       = NULL
        ELSE
            LET lRepDinPort.fecha_baja       = rDatosReporte.fecha_baja
        END IF

        LOCATE lRepDinPort.cerificado_b64 IN MEMORY
        LOCATE lRepDinPort.clave_b64 IN MEMORY
        LOCATE lRepDinPort.pass_cert_b64 IN MEMORY
        
        INSERT INTO cei_repdinport VALUES(lRepDinPort.*)
    END IF
    
    IF fgl_report_loadCurrentSettings("reporteResolucion.4rp") THEN
        CALL fgl_report_selectDevice("PDF")
        CALL fgl_report_selectPreview(FALSE)
        CALL fgl_report_setOutputFileName("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud)
    END IF

    LET lHandler = fgl_report_commitCurrentSettings()
     IF lHandler IS NOT NULL THEN
        START REPORT reporte_transferencia TO XML HANDLER lHandler
            IF rDatosReporte.observaciones IS NULL THEN
                LET rDatosReporte.observaciones = "-"
            END IF
            --CALL codigo_128(rDatosReporte.folio_solicitud) RETURNING rDatosReporte.folio_solicitud
            --LET rDatosReporte.folio_solicitud = "STARTB"||rDatosReporte.folio_solicitud
            OUTPUT TO REPORT reporte_transferencia(rDatosReporte.*)
        FINISH REPORT reporte_transferencia
    END IF
    IF ui.Interface.getFrontEndName() = "GDC" THEN
        IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
            CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
        END IF
    ELSE
        --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||rDatosReporte.folio_solicitud||".pdf")
        CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
    END IF
    SLEEP 2
    CALL os.Path.delete("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") RETURNING lstdel
    CALL reporteTransferenciaNoFirmadoSolicitud(rDatosReporte.*)
END FUNCTION

FUNCTION reporteTransferenciaNoFirmadoSolicitud(rDatosReporte)
    DEFINE rDatosReporte tDatosReporte
    DEFINE lHandler om.SaxDocumentHandler

    IF fgl_report_loadCurrentSettings("reporteSolicitud.4rp") THEN
        CALL fgl_report_selectDevice("PDF")
        CALL fgl_report_selectPreview(FALSE)
        CALL fgl_report_setOutputFileName("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud)
    END IF

    LET lHandler = fgl_report_commitCurrentSettings()
     IF lHandler IS NOT NULL THEN
        START REPORT reporte_transferencia TO XML HANDLER lHandler
            IF rDatosReporte.observaciones IS NULL THEN
                LET rDatosReporte.observaciones = "-"
            END IF
            --CALL codigo_128(rDatosReporte.folio_solicitud) RETURNING rDatosReporte.folio_solicitud
            --LET rDatosReporte.folio_solicitud = "STARTB"||rDatosReporte.folio_solicitud
            OUTPUT TO REPORT reporte_transferencia(rDatosReporte.*)
        FINISH REPORT reporte_transferencia
    END IF
    IF ui.Interface.getFrontEndName() = "GDC" THEN
        IF os.Path.exists("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
            CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
        END IF
    ELSE
        --CALL FGL_PUTFILE("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||rDatosReporte.folio_solicitud||".pdf")
        CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
    END IF
    SLEEP 1
    CALL os.Path.delete("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") RETURNING lstdel
    
END FUNCTION

FUNCTION ReporteTransferenciaNoFirmadoResolucion(rDatosReporte)
    DEFINE rDatosReporte tDatosReporte
    DEFINE lHandler om.SaxDocumentHandler
    DEFINE lRepDinPort RECORD LIKE cei_repdinport.*
    DEFINE SQL1 STRING
    DEFINE lExiste INTEGER

    LET lExiste = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_repdinport",
               "  WHERE folio_solicitud = ", rDatosReporte.folio_solicitud
    PREPARE select_existe_reporte_no_firmado_res FROM SQL1
    EXECUTE select_existe_reporte_no_firmado_res INTO lExiste

    IF lExiste = 0 THEN
        LET lRepDinPort.codigo_resultado = rDatosReporte.codigo_resultado
        LET lRepDinPort.dias_cotizados   = rDatosReporte.antiguedad
        LET lRepDinPort.folio_procesar   = rDatosReporte.folio_procesar
        LET lRepDinPort.folio_solicitud  = rDatosReporte.folio_solicitud
        LET lRepDinPort.sit_afil         = rDatosReporte.situacion_afil
        IF rDatosReporte.fecha_baja = "31/12/1899" THEN
            LET lRepDinPort.fecha_baja       = NULL
        ELSE
            LET lRepDinPort.fecha_baja       = rDatosReporte.fecha_baja
        END IF

        LOCATE lRepDinPort.cerificado_b64 IN MEMORY
        LOCATE lRepDinPort.clave_b64 IN MEMORY
        LOCATE lRepDinPort.pass_cert_b64 IN MEMORY
        
        INSERT INTO cei_repdinport VALUES(lRepDinPort.*)
    END IF
    
    IF fgl_report_loadCurrentSettings("reporteResolucion.4rp") THEN
        CALL fgl_report_selectDevice("PDF")
        CALL fgl_report_selectPreview(FALSE)
        CALL fgl_report_setOutputFileName("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud)
    END IF

    LET lHandler = fgl_report_commitCurrentSettings()
     IF lHandler IS NOT NULL THEN
        START REPORT reporte_transferencia TO XML HANDLER lHandler
            IF rDatosReporte.observaciones IS NULL THEN
                LET rDatosReporte.observaciones = "-"
            END IF
            --CALL codigo_128(rDatosReporte.folio_solicitud) RETURNING rDatosReporte.folio_solicitud
            --LET rDatosReporte.folio_solicitud = "STARTB"||rDatosReporte.folio_solicitud
            OUTPUT TO REPORT reporte_transferencia(rDatosReporte.*)
        FINISH REPORT reporte_transferencia
    END IF
    IF ui.Interface.getFrontEndName() = "GDC" THEN
        IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
            CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
        END IF
    ELSE
        --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||rDatosReporte.folio_solicitud||".pdf")
        CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
    END IF
    SLEEP 2
    CALL os.Path.delete("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") RETURNING lstdel
END FUNCTION
##############################
## FIRMADOS SAT
##############################
FUNCTION reporteTransferencia(rDatosReporte, rSATReporte)
    DEFINE rDatosReporte tDatosReporte
    DEFINE rSATReporte tSATReporte
    DEFINE lHandler om.SaxDocumentHandler
    DEFINE rFirmaSAT RECORD LIKE cei_solicitud_firma.*
    DEFINE lRepDinPort RECORD LIKE cei_repdinport.*
    DEFINE SQL1 STRING
    DEFINE lExiste INTEGER

    LET lExiste = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_repdinport",
               "  WHERE folio_solicitud = ", rDatosReporte.folio_solicitud
    PREPARE select_existe_reporte_transferencia FROM SQL1
    EXECUTE select_existe_reporte_transferencia INTO lExiste

    IF lExiste = 0 THEN
        LET lRepDinPort.codigo_resultado = rDatosReporte.codigo_resultado
        LET lRepDinPort.dias_cotizados   = rDatosReporte.antiguedad
        LET lRepDinPort.folio_procesar   = rDatosReporte.folio_procesar
        LET lRepDinPort.folio_solicitud  = rDatosReporte.folio_solicitud
        LET lRepDinPort.sit_afil         = rDatosReporte.situacion_afil
        IF rDatosReporte.fecha_baja = "31/12/1899" THEN
            LET lRepDinPort.fecha_baja       = NULL
        ELSE
            LET lRepDinPort.fecha_baja       = rDatosReporte.fecha_baja
        END IF

        IF rDatosReporte.usuario.subString(1,1) = "1" THEN
            LOCATE lRepDinPort.cerificado_b64 IN MEMORY
            LOCATE lRepDinPort.clave_b64      IN MEMORY
            LOCATE lRepDinPort.pass_cert_b64  IN MEMORY
            
            LET lRepDinPort.cerificado_b64  = security.Base64.LoadBinary(rSATReporte.l_val_cer)
            LET lRepDinPort.clave_b64       = security.Base64.LoadBinary(rSATReporte.l_val_key)
            LET lRepDinPort.nom_arch_cert   = rSATReporte.l_val_cer
            LET lRepDinPort.nombre_arch_cve = rSATReporte.l_val_key
            LET lRepDinPort.pass_cert_b64   = security.Base64.FromString(rSATReporte.password)
            LET lRepDinPort.rfc             = rSATReporte.rfc
        ELSE
            LOCATE lRepDinPort.cerificado_b64 IN MEMORY
            LOCATE lRepDinPort.clave_b64      IN MEMORY
            LOCATE lRepDinPort.pass_cert_b64  IN MEMORY
        END IF

        LET SQL1 = " INSERT INTO cei_repdinport(",
                                              "  folio_solicitud",
                                              ", sit_afil",
                                              ", dias_cotizados",
                                              ", rfc",
                                              ", cerificado_b64",
                                              ", clave_b64",
                                              ", pass_cert_b64",
                                              ", nom_arch_cert",
                                              ", nombre_arch_cve",
                                              ", codigo_resultado",
                                              ", folio_procesar",
                                              ", fecha_baja",
                                              ")",
                                    " VALUES("
                                    ,        lRepDinPort.folio_solicitud
                                    , ", '", lRepDinPort.sit_afil, "'"
                                    , ",  ", lRepDinPort.dias_cotizados
                                    , ", '", lRepDinPort.rfc, "'"
                                    , ", ?"
                                    , ", ?"
                                    , ", ?"
                                    , ", '", lRepDinPort.nom_arch_cert, "'"
                                    , ", '", lRepDinPort.nombre_arch_cve, "'"
                                    , ", '", lRepDinPort.codigo_resultado, "'"
                                    , ", '", lRepDinPort.folio_procesar, "'"
                                    , ", '", lRepDinPort.fecha_baja, "'"
                                    ,")"
        PREPARE insert_cei_repdinport FROM SQL1
        EXECUTE insert_cei_repdinport USING lRepDinPort.cerificado_b64, lRepDinPort.clave_b64, lRepDinPort.pass_cert_b64
    END IF

    IF fgl_report_loadCurrentSettings("reporteResolucion.4rp") THEN
        CALL fgl_report_selectDevice("PDF")
        CALL fgl_report_selectPreview(FALSE)
        CALL fgl_report_setOutputFileName("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud)
    END IF
    LET lHandler = fgl_report_commitCurrentSettings()
     IF lHandler IS NOT NULL THEN
        START REPORT reporte_transferencia TO XML HANDLER lHandler
            IF rDatosReporte.observaciones IS NULL THEN
                LET rDatosReporte.observaciones = "-"
            END IF
            --CALL codigo_128(rDatosReporte.folio_solicitud) RETURNING rDatosReporte.folio_solicitud
            --LET rDatosReporte.folio_solicitud = "STARTB"||rDatosReporte.folio_solicitud
            OUTPUT TO REPORT reporte_transferencia(rDatosReporte.*)
        FINISH REPORT reporte_transferencia
    END IF
    IF rDatosReporte.usuario.subString(1,1) = "1" THEN
        CALL servicioSAT(rSATReporte.l_val_cer, rSATReporte.l_val_key, rDatosReporte.curp, TRUE, rDatosReporte.folio_solicitud, rDatosReporte.nombre CLIPPED||" "||rDatosReporte.primer_apellido CLIPPED||" "||rDatosReporte.segundo_apellido CLIPPED, rSATReporte.rfc, rSATReporte.password, "R") RETURNING rFirmaSAT.*
    END IF
    IF rFirmaSAT.curp IS NULL THEN
        IF ui.Interface.getFrontEndName() = "GDC" THEN
            IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
                CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            END IF
        ELSE
            --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
        END IF
    ELSE
        TRY
            IF ui.Interface.getFrontEndName() = "GDC" THEN
                IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf") = TRUE THEN
                    CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
                END IF
            ELSE
                --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
                CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
            END IF
            --RUN "cp "||rDatosReporte.curp||"_certificadaSAT"||".pdf"||" /trabajo/sipe/sipeav/tmp/"||rDatosReporte.curp||"_certificadaSAT"||".pdf"
            --CALL ui.Interface.frontCall("standard", "launchURL", [ "http://10.1.52.254/"||rDatosReporte.curp||"_certificadaSAT"||".pdf" ], [] )
        CATCH
            IF ui.Interface.getFrontEndName() = "GDC" THEN
                IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
                    CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
                END IF
            ELSE
                --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
                CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            END IF
            --RUN "cp "||rDatosReporte.curp||".pdf"||" /trabajo/sipe/sipeav/tmp/"||rDatosReporte.curp||".pdf"
            --CALL ui.Interface.frontCall("standard", "launchURL", [ "http://10.1.52.254/"||rDatosReporte.curp||".pdf" ], [] )
        END TRY
    END IF
    SLEEP 2
    CALL reporteTransferencia_solicitud(rDatosReporte.*, rSATReporte.*)
END FUNCTION

FUNCTION reporteTransferencia_solicitud(rDatosReporte, rSATReporte)
    DEFINE rDatosReporte tDatosReporte
    DEFINE rSATReporte tSATReporte
    DEFINE lHandler om.SaxDocumentHandler
    DEFINE rFirmaSAT RECORD LIKE cei_solicitud_firma.*

    IF fgl_report_loadCurrentSettings("reporteSolicitud.4rp") THEN
        CALL fgl_report_selectDevice("PDF")
        CALL fgl_report_selectPreview(FALSE)
        CALL fgl_report_setOutputFileName("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud)
    END IF
    LET lHandler = fgl_report_commitCurrentSettings()
     IF lHandler IS NOT NULL THEN
        START REPORT reporte_transferencia TO XML HANDLER lHandler
            IF rDatosReporte.observaciones IS NULL THEN
                LET rDatosReporte.observaciones = "-"
            END IF
            --CALL codigo_128(rDatosReporte.folio_solicitud) RETURNING rDatosReporte.folio_solicitud
            --LET rDatosReporte.folio_solicitud = "STARTB"||rDatosReporte.folio_solicitud
            OUTPUT TO REPORT reporte_transferencia(rDatosReporte.*)
        FINISH REPORT reporte_transferencia
    END IF
    IF rDatosReporte.usuario.subString(1,1) = "1" THEN
        CALL servicioSAT(rSATReporte.l_val_cer, rSATReporte.l_val_key, rDatosReporte.curp, TRUE, rDatosReporte.folio_solicitud, rDatosReporte.nombre CLIPPED||" "||rDatosReporte.primer_apellido CLIPPED||" "||rDatosReporte.segundo_apellido CLIPPED, rSATReporte.rfc, rSATReporte.password, "S") RETURNING rFirmaSAT.*
    END IF
    IF rFirmaSAT.curp IS NULL THEN
        IF ui.Interface.getFrontEndName() = "GDC" THEN
            IF os.Path.exists("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
                CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            END IF
        ELSE
            --CALL FGL_PUTFILE("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
        END IF
    ELSE
        TRY
            IF ui.Interface.getFrontEndName() = "GDC" THEN
                IF os.Path.exists("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf") = TRUE THEN
                    CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
                END IF
            ELSE
                --CALL FGL_PUTFILE("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
                CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
            END IF
            --RUN "cp "||rDatosReporte.curp||"_certificadaSAT"||".pdf"||" /trabajo/sipe/sipeav/tmp/"||rDatosReporte.curp||"_certificadaSAT"||".pdf"
            --CALL ui.Interface.frontCall("standard", "launchURL", [ "http://10.1.52.254/"||rDatosReporte.curp||"_certificadaSAT"||".pdf" ], [] )
        CATCH
            IF ui.Interface.getFrontEndName() = "GDC" THEN
                IF os.Path.exists("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
                    CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
                END IF
            ELSE
                --CALL FGL_PUTFILE("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
                CALL CopArcRpt("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            END IF
            --RUN "cp "||rDatosReporte.curp||".pdf"||" /trabajo/sipe/sipeav/tmp/"||rDatosReporte.curp||".pdf"
            --CALL ui.Interface.frontCall("standard", "launchURL", [ "http://10.1.52.254/"||rDatosReporte.curp||".pdf" ], [] )
        END TRY
    END IF

    SLEEP 1
    CALL os.Path.delete("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf") RETURNING lstdel
    CALL os.Path.delete("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") RETURNING lstdel
    CALL os.Path.delete("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf") RETURNING lstdel
    CALL os.Path.delete("S_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") RETURNING lstdel
    CALL os.Path.delete(rSATReporte.l_val_cer) RETURNING lstdel
    CALL os.Path.delete(rSATReporte.l_val_key) RETURNING lstdel
    CALL os.Path.delete(rSATReporte.l_val_cer.subString(1,length(rSATReporte.l_val_cer)-3)||"crt") RETURNING lstdel
END FUNCTION

FUNCTION reporteTransferenciaResolucion(rDatosReporte, rSATReporte)
    DEFINE rDatosReporte tDatosReporte
    DEFINE rSATReporte tSATReporte
    DEFINE lHandler om.SaxDocumentHandler
    DEFINE rFirmaSAT RECORD LIKE cei_solicitud_firma.*
    DEFINE lRepDinPort RECORD LIKE cei_repdinport.*
    DEFINE SQL1 STRING
    DEFINE lExiste INTEGER

    LET lExiste = 0
    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cei_repdinport",
               "  WHERE folio_solicitud = ", rDatosReporte.folio_solicitud
    PREPARE select_existe_reporte_transferencia_res FROM SQL1
    EXECUTE select_existe_reporte_transferencia_res INTO lExiste

    IF lExiste = 0 THEN
        LET lRepDinPort.codigo_resultado = rDatosReporte.codigo_resultado
        LET lRepDinPort.dias_cotizados   = rDatosReporte.antiguedad
        LET lRepDinPort.folio_procesar   = rDatosReporte.folio_procesar
        LET lRepDinPort.folio_solicitud  = rDatosReporte.folio_solicitud
        LET lRepDinPort.sit_afil         = rDatosReporte.situacion_afil

        IF rDatosReporte.usuario.subString(1,1) = "1" THEN
            LOCATE lRepDinPort.cerificado_b64 IN MEMORY
            LOCATE lRepDinPort.clave_b64      IN MEMORY
            LOCATE lRepDinPort.pass_cert_b64  IN MEMORY
            
            LET lRepDinPort.cerificado_b64  = security.Base64.LoadBinary(rSATReporte.l_val_cer)
            LET lRepDinPort.clave_b64       = security.Base64.LoadBinary(rSATReporte.l_val_key)
            LET lRepDinPort.nom_arch_cert   = rSATReporte.l_val_cer
            LET lRepDinPort.nombre_arch_cve = rSATReporte.l_val_key
            LET lRepDinPort.pass_cert_b64   = security.Base64.FromString(rSATReporte.password)
            LET lRepDinPort.rfc             = rSATReporte.rfc
        ELSE
            LOCATE lRepDinPort.cerificado_b64 IN MEMORY
            LOCATE lRepDinPort.clave_b64      IN MEMORY
            LOCATE lRepDinPort.pass_cert_b64  IN MEMORY
        END IF
        
        INSERT INTO cei_repdinport VALUES(lRepDinPort.*)
    END IF

    IF fgl_report_loadCurrentSettings("reporteResolucion.4rp") THEN
        CALL fgl_report_selectDevice("PDF")
        CALL fgl_report_selectPreview(FALSE)
        CALL fgl_report_setOutputFileName("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud)
    END IF
    LET lHandler = fgl_report_commitCurrentSettings()
     IF lHandler IS NOT NULL THEN
        START REPORT reporte_transferencia TO XML HANDLER lHandler
            IF rDatosReporte.observaciones IS NULL THEN
                LET rDatosReporte.observaciones = "-"
            END IF
            --CALL codigo_128(rDatosReporte.folio_solicitud) RETURNING rDatosReporte.folio_solicitud
            --LET rDatosReporte.folio_solicitud = "STARTB"||rDatosReporte.folio_solicitud
            OUTPUT TO REPORT reporte_transferencia(rDatosReporte.*)
        FINISH REPORT reporte_transferencia
    END IF
    IF rDatosReporte.usuario.subString(1,1) = "1" THEN
        CALL servicioSAT(rSATReporte.l_val_cer, rSATReporte.l_val_key, rDatosReporte.curp, TRUE, rDatosReporte.folio_solicitud, rDatosReporte.nombre CLIPPED||" "||rDatosReporte.primer_apellido CLIPPED||" "||rDatosReporte.segundo_apellido CLIPPED, rSATReporte.rfc, rSATReporte.password, "R") RETURNING rFirmaSAT.*
    END IF
    IF rFirmaSAT.curp IS NULL THEN
        IF ui.Interface.getFrontEndName() = "GDC" THEN
            IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
                CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            END IF
        ELSE
            --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
        END IF
    ELSE
        TRY
            IF ui.Interface.getFrontEndName() = "GDC" THEN
                IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf") = TRUE THEN
                    CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
                END IF
            ELSE
                --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
                CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf")
            END IF
            --RUN "cp "||rDatosReporte.curp||"_certificadaSAT"||".pdf"||" /trabajo/sipe/sipeav/tmp/"||rDatosReporte.curp||"_certificadaSAT"||".pdf"
            --CALL ui.Interface.frontCall("standard", "launchURL", [ "http://10.1.52.254/"||rDatosReporte.curp||"_certificadaSAT"||".pdf" ], [] )
        CATCH
            IF ui.Interface.getFrontEndName() = "GDC" THEN
                IF os.Path.exists("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") = TRUE THEN
                    CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
                END IF
            ELSE
                --CALL FGL_PUTFILE("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf",rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
                CALL CopArcRpt("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf")
            END IF
            --RUN "cp "||rDatosReporte.curp||".pdf"||" /trabajo/sipe/sipeav/tmp/"||rDatosReporte.curp||".pdf"
            --CALL ui.Interface.frontCall("standard", "launchURL", [ "http://10.1.52.254/"||rDatosReporte.curp||".pdf" ], [] )
        END TRY
    END IF
    SLEEP 2
    CALL os.Path.delete("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||".pdf") RETURNING lstdel
    CALL os.Path.delete("R_"||rDatosReporte.curp||"_"||rDatosReporte.folio_solicitud||"_firmada"||".pdf") RETURNING lstdel
END FUNCTION

FUNCTION codigo_128(cod_val)

    DEFINE cod_val BIGINT,
           i SMALLINT,
           aux_str,barcode STRING

    LET aux_str=cod_val

    LET barcode=""

    FOR i=1 TO aux_str.getLength()
        LET barcode=barcode,",",aux_str.getCharAt(i)
    END FOR

    RETURN barcode

END FUNCTION

REPORT reporte_transferencia(lDatosReporte)
    DEFINE lDatosReporte tDatosReporte
    DEFINE lanio_fecha STRING
    DEFINE lmes_fecha  STRING
    DEFINE ldia_fecha  STRING
    DEFINE lfecha_solicitud STRING

    DEFINE imagen1 BYTE
    DEFINE imagen2 BYTE
    DEFINE imagen3 BYTE
    DEFINE sello_digital STRING
    DEFINE nom_comp_sol STRING
    DEFINE bndAplicacion STRING

    FORMAT
        FIRST PAGE HEADER
            LOCATE imagen1 IN MEMORY
            LOCATE imagen2 IN MEMORY
            LOCATE imagen3 IN MEMORY

            CALL imagen1.readFile("logo_issste.png")
            CALL imagen2.readFile("logo_gobierno_mexico.png")
            CALL imagen3.readFile("logo_conamer.png")

            LET ldia_fecha  = lDatosReporte.fecha_solicitud.subString(9,10)
            LET lmes_fecha  = lDatosReporte.fecha_solicitud.subString(6,7)
            LET lanio_fecha = lDatosReporte.fecha_solicitud.subString(1,4)
            LET lfecha_solicitud = ldia_fecha||"/"||lmes_fecha||"/"||lanio_fecha
            PRINTX imagen1, imagen2, imagen3, lfecha_solicitud
        ON EVERY ROW
            LET cadena_original = lDatosReporte.nombre||"|"||lDatosReporte.primer_apellido||lDatosReporte.segundo_apellido||lDatosReporte.motivo_rechazo||lDatosReporte.observaciones||lDatosReporte.fecha_nacimiento
            LET sello_digital = fnSignKey(cadena_original)
            
            IF lDatosReporte.observaciones IS NULL THEN
                LET lDatosReporte.observaciones = "-"
            END IF

            IF lDatosReporte.codigo_resultado = "01" THEN
                LET lDatosReporte.codigo_resultado = "Procedente"
            ELSE
                LET lDatosReporte.codigo_resultado = "Rechazada"
            END IF
            LET bndAplicacion = lDatosReporte.usuario.subString(1,1)
            LET nom_comp_sol = lDatosReporte.nombre CLIPPED||" "||lDatosReporte.primer_apellido CLIPPED||" "||lDatosReporte.segundo_apellido CLIPPED
            PRINTX lDatosReporte.*, sello_digital, nom_comp_sol, bndAplicacion
END REPORT

FUNCTION fnSignKey(cadena_original)
    DEFINE cadena_original STRING
    DEFINE lkey            xml.CryptoKey
    DEFINE bytesHex        STRING
    DEFINE lComputeHash    STRING
    DEFINE lsello_digital  STRING

    LET lkey = xml.CryptoKey.Create("http://www.w3.org/2000/09/xmldsig#rsa-sha1")
    CALL lkey.loadPEM("IsssteCert.pem")
    LET bytesHex = security.HexBinary.FromString(cadena_original)
    CALL ComputeHash(bytesHex, "MD5") RETURNING lComputeHash

    LET lsello_digital = xml.Signature.SignString(lkey,lComputeHash)
    DISPLAY "Signature:", xml.Signature.SignString(lkey,lComputeHash)

    DISPLAY "Verify:", xml.Signature.VerifyString(lkey, lComputeHash, xml.Signature.SignString(lkey,lComputeHash))

    RETURN lsello_digital
        
END FUNCTION

FUNCTION ComputeHash(toDigest, algorithm)

    DEFINE toDigest  STRING
    DEFINE algorithm STRING
    DEFINE result    STRING
    DEFINE dgst security.Digest

    TRY
        LET dgst = security.Digest.CreateDigest(algorithm)
        CALL dgst.AddStringData(toDigest)
        LET result = dgst.DoBase64Digest()
    CATCH
        DISPLAY "ERROR : ", status, " - ", sqlca.sqlerrm
        EXIT PROGRAM(-1)
    END TRY

    RETURN result
END FUNCTION

FUNCTION CopArcRpt(lArchivo)
    DEFINE lArchivo STRING
    DEFINE SQL1 STRING
    DEFINE GRtaTmp1 STRING
    DEFINE GRtaRpt1 STRING
    DEFINE GUrlRpt1 STRING
    DEFINE comando STRING
    DEFINE rutaLaunchURL STRING

    LET SQL1 = " SELECT ruta",
               "   FROM cat_rutas",
               "  WHERE sistema = 1",
               "    AND variable = 'GRTATMP1'"
    PREPARE select_cat_rutas_GRTATMP FROM SQL1
    EXECUTE select_cat_rutas_GRTATMP INTO GRtaTmp1
    LET GRtaTmp1 = GRtaTmp1 CLIPPED

    LET SQL1 = " SELECT ruta",
               "   FROM cat_rutas",
               "  WHERE sistema = 1",
               "    AND variable = 'GRTARPT1'"
    PREPARE select_cat_rutas_GRTARPT FROM SQL1
    EXECUTE select_cat_rutas_GRTARPT INTO GRtaRpt1
    LET GRtaRpt1 = GRtaRpt1 CLIPPED

    LET SQL1 = " SELECT ruta",
               "   FROM cat_rutas",
               "  WHERE sistema = 1",
               "    AND variable = 'GURLRPT1'"
    PREPARE select_cat_rutas_GURLRPT FROM SQL1
    EXECUTE select_cat_rutas_GURLRPT INTO GUrlRpt1
    LET GUrlRpt1 = GUrlRpt1 CLIPPED

    LET comando = "scp -q "||lArchivo||" "||GRtaTmp1||lArchivo
    DISPLAY "Comando scp Portabilidad copia a GRTATMP1: ", comando
    RUN comando

    LET comando = "scp -q "||GRtaTmp1||lArchivo||" "||GRtaRpt1||lArchivo
    DISPLAY "Comando scp Portabilidad copia a GRTARPT1: ", comando
    RUN comando

    IF GUrlRpt1 NOT MATCHES "http*" THEN
        LET rutaLaunchURL = "http:"||GUrlRpt1||lArchivo
    ELSE
        LET rutaLaunchURL = GUrlRpt1||lArchivo
    END IF
    DISPLAY "rutaLaunchURL: ", rutaLaunchURL

    IF os.Path.exists(GRtaTmp1||lArchivo) = FALSE THEN
        IF lArchivo.getCharAt(1) = "S" THEN
            MESSAGE "Solicitud no disponible"
        ELSE
            MESSAGE "Resolución no disponible"
        END IF
    ELSE
        --Cambiar por fgl_putfile
        CALL ui.Interface.frontCall("standard", "launchURL", [ rutaLaunchURL ], [] )
    END IF
END FUNCTION