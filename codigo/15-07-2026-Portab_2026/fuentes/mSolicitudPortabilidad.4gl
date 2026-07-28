IMPORT security
IMPORT util
IMPORT os
IMPORT FGL fgldialog
IMPORT FGL lSolicitudPortabilidad
IMPORT FGL mGeneraReporte
IMPORT FGL lReporteSolicitud
IMPORT FGL lPeriodos
IMPORT FGL clienteWS1ConsultaBasicaIMSS
IMPORT FGL clienteWS2DeterminacionProcesar
IMPORT FGL clienteWS3ConsultaRobustaIMSS
IMPORT FGL clienteWS4NotificarProcesar
IMPORT FGL clienteWS5ActualizarProcesar
IMPORT FGL clienteWS6AvisoEstatusTransferenciaIMSS
IMPORT FGL clienteDictamenBeneficioPensionario

SCHEMA dsipe

    TYPE t_datos_certificado RECORD
        rfc          STRING,   -- x500UniqueIdentifier (2.5.4.45)
        curp         STRING,   -- serialNumber (2.5.4.5) - solo aplica a persona fisica
        nombre       STRING,   -- CN (2.5.4.3) / O (2.5.4.10)
        sucursal     STRING,   -- OU (2.5.4.11) - solo presente en CSD
        email        STRING,   -- emailAddress (1.2.840.113549.1.9.1)
        pais         STRING,   -- C (2.5.4.6)
        tipo_cert    STRING,   -- "CSD" o "FIEL", segun presencia de OU
        tipo_persona STRING    -- "FISICA" u "MORAL", segun longitud del RFC
    END RECORD

    DEFINE rSalidaWS1IMSS              tRespuestaEstatusAsegurado
    DEFINE rConsultarEntrada           consultarTramiteRequest
    DEFINE r_WS2Salida                 consultarTramiteResponse
    DEFINE r_ws3SalidaIMSS             tRespuestaConsultaPeriodos
    DEFINE rCancelarEntrada            cancelarTramiteRequest
    DEFINE rWS5SalidaPROCESAR          cancelarTramiteResponse
    DEFINE lRobustaOtra                RECORD LIKE cei_td_ws3_robusta_otra.*
    DEFINE lRobustaOtraPeriodos        RECORD LIKE cei_td_ws3_robusta_periodos.*
    DEFINE lRobusta                    RECORD LIKE cei_td_ws3_robusta.*
    DEFINE rWS6SalidaIMSS              trespuestaWS
    DEFINE rInsertarEntrada            insertarTramiteRequest
    DEFINE r_ws4SalidaProcesar         insertarTramiteResponse
    DEFINE rcei_td_ws4_procesarexito   RECORD LIKE cei_td_ws4_procesarexito.*
    DEFINE rcei_td_ws5_procesarrechazo RECORD LIKE cei_td_ws5_procesarrechazo.*
    DEFINE rEntradaValidaBeneficioPensionario t_wsEntradaValidaBeneficioPensionario
    DEFINE rSalidaValidaBeneficioPensionario  t_wsSalidaValidaBeneficioPensionario
    DEFINE p_idServicio  STRING
    DEFINE p_idEbusiness STRING
    DEFINE p_idCliente   STRING

    DEFINE rDatosTemp RECORD
        regimen     STRING,
        afiliatoria STRING,
        fec_nac     DATE,
        antiguedad  INTEGER,
        nombre_completo STRING,
        rfc VARCHAR(13),
        password STRING,
        nss STRING
    END RECORD
    DEFINE rFirmaSAT RECORD LIKE cei_solicitud_firma.*

    DEFINE lSolicitud RECORD LIKE cei_solicitud.*

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

    DEFINE rDatosReporte tDatosReporte
    DEFINE rSATReporte tSATReporte
    DEFINE lbndValido SMALLINT
    DEFINE gusuario STRING
    DEFINE gid_aplicacion STRING
    DEFINE gid_app_ejecuta INTEGER
    DEFINE gcomponente STRING
    DEFINE gmuestra_listado SMALLINT
    DEFINE gCURP STRING
    DEFINE gsolo_usuario STRING

MAIN
    TYPE ltSolicitud RECORD
        folio    STRING,
        fecha    STRING,
        nss      STRING,
        correo   STRING,
        telefono STRING,
        status    STRING,
        solicitud BYTE,
        resolucion BYTE
    END RECORD

    DEFINE lSol ltSolicitud
    DEFINE arrSol DYNAMIC ARRAY OF ltSolicitud
    DEFINE idx INTEGER
    DEFINE SQL1 STRING
    DEFINE bndNueva SMALLINT
    DEFINE llnum_issste DECIMAL(10,2)
    DEFINE bndSalir  SMALLINT
    DEFINE lcontar_er INTEGER
    DEFINE cve_deleg INTEGER
    DEFINE lcontar_solicitudes INTEGER
    DEFINE vtnfaDescargas STRING

    LET clienteWS1ConsultaBasicaIMSS.WSEstatusAsegurado_WSEstatusAseguradoPortEndpoint.Address.Uri = get_endpoint_ws("wsconsultabasicaimss")
    LET clienteWS2DeterminacionProcesar.Endpoint.Address.Uri = get_endpoint_ws("wsconsultarprocesar")
    LET clienteWS3ConsultaRobustaIMSS.WSConsultaPeriodos_WSConsultaPeriodosPortEndpoint.Address.Uri = get_endpoint_ws("wsconsultarobustaimss")
    LET clienteWS4NotificarProcesar.Endpoint.Address.Uri = get_endpoint_ws("wsinsercionprocesar")
    LET clienteWS6AvisoEstatusTransferenciaIMSS.WSConclusionPortabilidad_WSConclusionPortabilidadPortEndpoint.Address.Uri = get_endpoint_ws("wsnotificarprocedenciaimss")
    LET clienteWS5ActualizarProcesar.Endpoint.Address.Uri = get_endpoint_ws("wscancelarprocesar")
    LET clienteDictamenBeneficioPensionario.Endpoint.Address.Uri = get_endpoint_ws("wsclientebenficiopensionario")
    
    DISPLAY "##############################"
    DISPLAY "## arg_val(0): ", arg_val(0), "##"
    DISPLAY "## arg_val(1): ", arg_val(1), "##"
    DISPLAY "## arg_val(2): ", arg_val(2), "##"
    DISPLAY "## arg_val(3): ", arg_val(3), "##"
    DISPLAY "##############################"

    IF arg_val(1) IS NULL OR arg_val(2) IS NULL OR arg_val(3) IS NULL THEN
        CALL fgl_winMessage("Transferencia de Derechos","Servicio disponible unicamente desde el portal SINAVID-OV o SIPE-AV","infomation")
        EXIT PROGRAM 0
    ELSE
        LET gid_aplicacion = desencriptar_argumento(arg_val(1))
        LET gusuario       = desencriptar_argumento(arg_val(1))||"-"||desencriptar_argumento(arg_val(3))
        LET gsolo_usuario  = desencriptar_argumento(arg_val(3))
        LET gCURP          = desencriptar_argumento(arg_val(2))
        LET gCURP = gCURP.toUpperCase()
    END IF

    CONNECT TO "dsipe"
    LET bndSalir = FALSE

    IF gid_aplicacion = "2" THEN
        LET SQL1 = " SELECT num_issste, nom_operador, cve_deleg",
                   "   FROM operadores_new",
                   "  WHERE usuario = '", desencriptar_argumento(arg_val(3)),"'"
        PREPARE select_operadores_new FROM SQL1
        EXECUTE select_operadores_new INTO llnum_issste, rDatosReporte.nombre_operador, cve_deleg

        LET SQL1 = " SELECT REPLACE(nombre,'DELEGACION','REPRESENTACION')",
                   "   FROM c_del_issste",
                   "  WHERE dis_cve = ", cve_deleg
        PREPARE select_representacion FROM SQL1
        EXECUTE select_representacion INTO rDatosReporte.representacion
    END IF

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM directo",
               "  WHERE curp = '", gCURP, "'",
               "    AND t_directo <> 'ER'"
    PREPARE select_directo_curp FROM SQL1
    EXECUTE select_directo_curp INTO lcontar_er

    IF lcontar_er > 1 THEN
        CALL fnMensajeER()
        RETURN
    END IF

    --IF gid_aplicacion = "1" THEN
        LET gmuestra_listado = TRUE
    --END IF
    --IF gid_aplicacion = "2" THEN
    --    LET gmuestra_listado = FALSE
    --END IF

    WHILE TRUE
        IF gmuestra_listado = TRUE THEN
        
            LET bndNueva = FALSE
            LET SQL1 = " SELECT COUNT(*)",
                       "   FROM cei_solicitud",
                       "  WHERE curp = '", gCURP, "'",
                       "    AND id_tiposolicitud = 1"
            PREPARE select_solicitudes_descargar_00 FROM SQL1
            EXECUTE select_solicitudes_descargar_00 INTO lcontar_solicitudes

            IF ui.Interface.getFrontEndName() = "GDC" THEN
                LET gid_app_ejecuta = 2
            ELSE
                LET gid_app_ejecuta = 1
            END IF

            IF lcontar_solicitudes > 0 THEN
                LET SQL1 = " SELECT folio_solicitud, fecha_solicitud, nss_imss, correo, telefono, id_estatus",
                           "   FROM cei_solicitud",
                           "  WHERE curp = '", gCURP, "'",
                           "    AND id_tiposolicitud = 1",
                           "   ORDER BY folio_solicitud DESC"
                PREPARE select_solicitudes_descargar FROM SQL1
                DECLARE curSolicitudesDes CURSOR FOR select_solicitudes_descargar
                LET idx = 1
                CALL arrSol.clear()
                FOREACH curSolicitudesDes INTO lSol.*
                    LET arrSol[idx].* = lSol.*
                    CASE lSol.status
                        WHEN "0" LET arrSol[idx].status = "Iniciada"
                        WHEN "1" LET arrSol[idx].status = "En Proceso"
                        WHEN "2" LET arrSol[idx].status = "Rechazada"
                        WHEN "3" LET arrSol[idx].status = "Procedente"
                        WHEN "4" LET arrSol[idx].status = "Cancelada"
                    END CASE
                    LOCATE arrSol[idx].solicitud IN FILE "imagen_ss.tmp"
                    CALL arrSol[idx].solicitud.readFile("img_pdf.png")
                    LOCATE arrSol[idx].resolucion IN FILE "imagen_rr.tmp"
                    CALL arrSol[idx].resolucion.readFile("img_pdf.png")
                    LET idx = idx + 1
                END FOREACH

                IF gid_app_ejecuta = 2 THEN
                    LET vtnfaDescargas = "faDescargaSolicitudes_gdc"
                ELSE
                    LET vtnfaDescargas = "faDescargaSolicitudes"
                    CALL ui.Interface.loadStyles("estilos")
                END IF
                
                OPEN WINDOW vtnDescargas WITH FORM vtnfaDescargas
                    DISPLAY ARRAY arrSol TO scr_arrsoldes.* ATTRIBUTES(ACCEPT = FALSE)
                        BEFORE DISPLAY
                            IF ui.Interface.getFrontEndName() = "GDC" THEN
                                CALL ui.Window.getCurrent().getForm().setElementHidden("descargargdc", FALSE)
                            END IF
                        ON ACTION btn_solicitud
                            CALL fnGeneraReporte(arrSol[arr_curr()].folio, gid_aplicacion, "S")
                            
                        ON ACTION btn_resolucion
                            CALL fnGeneraReporte(arrSol[arr_curr()].folio, gid_aplicacion, "R")

                        ON ACTION btn_des_sol
                            CALL fnGeneraReporte(arrSol[arr_curr()].folio, gid_aplicacion, "S")

                        ON ACTION btn_des_res
                            CALL fnGeneraReporte(arrSol[arr_curr()].folio, gid_aplicacion, "R")

                        ON ACTION btn_nueva
                            LET bndNueva = TRUE
                            --IF gid_aplicacion = "2" THEN
                            --    LET gCURP = NULL
                            --END IF
                            EXIT DISPLAY

                        ON ACTION CANCEL
                            LET bndNueva = FALSE
                            LET bndSalir = TRUE
                            EXIT DISPLAY
                    END DISPLAY
                CLOSE WINDOW vtnDescargas
            ELSE
                LET bndNueva = TRUE
            END IF
            IF bndSalir = TRUE THEN
                DISCONNECT CURRENT
                EXIT WHILE
            END IF
            IF bndNueva = TRUE THEN
                IF fnTransferenciaDerechos(gCURP) = TRUE THEN
                    DISCONNECT CURRENT
                    EXIT WHILE
                END IF
            END IF
        END IF
        IF gid_aplicacion = "2" THEN
            IF fnTransferenciaDerechos(gCURP) = TRUE THEN
                DISCONNECT CURRENT
                EXIT WHILE
            END IF
        END IF
    END WHILE
END MAIN

FUNCTION fnTransferenciaDerechos(l_CURP)
--MAIN
    DEFINE l_CURP STRING
    DEFINE wsstatus INTEGER
    DEFINE bndEstatusProceso SMALLINT
    DEFINE l_val_cer STRING
    DEFINE l_val_key STRING
    DEFINE certificado STRING
    DEFINE llave_privada STRING
    DEFINE idx INTEGER
    
    DEFINE lregimen  INTEGER
    DEFINE lbeneficio_pensionario INTEGER
    DEFINE SQL1 STRING
    DEFINE rSolicitudes RECORD LIKE cei_solicitud.*
    DEFINE arrSolicitudes DYNAMIC ARRAY OF RECORD
        folio BIGINT,
        fecha DATE,
        nss   STRING,
        email STRING,
        estatus STRING,
        imagen_s BYTE,
        imagen_r BYTE
    END RECORD
    DEFINE rfc STRING
    DEFINE password STRING
    DEFINE rcei_td_ws1_basica_otra RECORD LIKE cei_td_ws1_basica_otra.*
    DEFINE rcei_td_ws1_basica RECORD LIKE cei_td_ws1_basica.*
    DEFINE wsstatus_dictamenbenficiopensionario INTEGER
    DEFINE sfolio_solicitud STRING
    DEFINE bndSalir SMALLINT
    DEFINE lcontar_er INTEGER
    DEFINE vtnfSolicitudPortabilidad STRING

    
    DISPLAY "ID Aplicacion: ", gid_aplicacion
    DISPLAY "Usuario: ", gusuario

    CASE gid_aplicacion
        WHEN "1"
            LET gcomponente = "PORTABOV"
        WHEN "2"
            LET gcomponente = "PORTABSP"
    END CASE
    
    LET p_idServicio  = "999"
    LET p_idEbusiness = "53"
    LET p_idCliente   = "96"

    IF ui.Interface.getFrontEndName() = "GDC" THEN
        LET vtnfSolicitudPortabilidad = "fSolicitudPortabilidad_gdc"
    ELSE
        LET vtnfSolicitudPortabilidad = "fSolicitudPortabilidad"
        CALL ui.Interface.loadStyles("estilos")
    END IF

    OPTIONS INPUT WRAP
    OPEN WINDOW vtnDatosInicialesPortabilidad WITH FORM vtnfSolicitudPortabilidad
            INPUT BY NAME lSolicitud.folio_solicitud,
                          lSolicitud.id_tiposolicitud,
                          lSolicitud.id_aplicacion,
                          lSolicitud.fecha_solicitud,
                          lSolicitud.curp,
                          --lSolicitud.num_issste,
                          lSolicitud.nss_imss,
                          lSolicitud.primer_apellido,
                          lSolicitud.segundo_apellido,
                          lSolicitud.nombre,
                          lSolicitud.correo,
                          lSolicitud.telefono,
                          lSolicitud.usuario,
                          lSolicitud.ip_maquina,
                          lSolicitud.observaciones,
                          lSolicitud.id_motivorechazo,
                          lSolicitud.id_estatus,
                          lSolicitud.fecha_baja,
                          rfc, l_val_cer, l_val_key, password
            ATTRIBUTES(UNBUFFERED, ACCEPT = FALSE, CANCEL = FALSE)
                BEFORE INPUT
                    DISPLAY "txt_env_sol.png" TO txt_env_sol
                    DISPLAY "fjs_ok_grey.png" TO img_cer_ok
                    DISPLAY "fjs_ok_grey.png" TO img_llave_ok
                    CALL fnllenaComboCatTipoSolicitud()
                    CALL fnllenaComboCatAplicacion()

                    LET lSolicitud.folio_solicitud  = fnGenerarFolioSolicitud()
                    LET lSolicitud.usuario          = gusuario
                    LET lSolicitud.ip_maquina       = fgl_getenv("FGL_WEBSERVER_REMOTE_ADDR")
                    IF lSolicitud.ip_maquina IS NULL THEN
                        LET lSolicitud.ip_maquina       = fgl_getenv("FGLSERVER")
                    END IF
                    LET lSolicitud.fecha_solicitud  = CURRENT YEAR TO SECOND
                    LET lSolicitud.id_estatus       = 0
                    LET lSolicitud.id_aplicacion    = gid_app_ejecuta
                    LET lSolicitud.id_tiposolicitud = 1

                    LET bndEstatusProceso = 1

                    IF gid_aplicacion = "2" THEN
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group4",TRUE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group7",FALSE)
                    END IF

                    LET lSolicitud.curp = l_CURP
                    IF lSolicitud.curp IS NOT NULL THEN
                        LET SQL1 = " SELECT COUNT(*)",
                                   "   FROM directo",
                                   "  WHERE curp = '", lSolicitud.curp, "'",
                                   "    AND t_directo <> 'ER'"
                        PREPARE select_directo_curp_00 FROM SQL1
                        EXECUTE select_directo_curp_00 INTO lcontar_er

                        IF lcontar_er > 1 THEN
                            CALL fnMensajeER()
                            LET bndSalir = TRUE
                            EXIT INPUT
                        END IF
                        CALL ui.Dialog.getCurrent().setFieldActive("curp", FALSE)
                        IF length(lSolicitud.curp) <> 18 THEN
                            CALL fgl_winMessage("Transferencia de Derechos","La CURP debe ser de 18 digitos","information")
                            CONTINUE INPUT
                        END IF

                        CALL fnRecuperaDatosDirecto(lSolicitud.curp) RETURNING lSolicitud.nombre,
                                                                               lSolicitud.num_issste,
                                                                               lSolicitud.primer_apellido,
                                                                               lSolicitud.segundo_apellido,
                                                                               lSolicitud.fecha_baja,
                                                                               rDatosTemp.afiliatoria,
                                                                               rDatosTemp.fec_nac,
                                                                               rDatosTemp.nss
                        IF lSolicitud.nombre IS NOT NULL THEN
                            LET rDatosTemp.antiguedad = dias_cot(lSolicitud.num_issste)
                            DISPLAY rDatosTemp.fec_nac TO fec_nac
                            DISPLAY rDatosTemp.antiguedad TO antiguedad
                            DISPLAY rDatosTemp.nss TO nss
                            CALL fnRecuperaRegimen(lSolicitud.curp, lSolicitud.num_issste)
                                                                         RETURNING rDatosTemp.regimen
                            CASE rDatosTemp.afiliatoria
                                WHEN "A"
                                    LET rDatosTemp.afiliatoria = "ACTIVO"
                                WHEN "B"
                                    LET rDatosTemp.afiliatoria = "BAJA"
                                WHEN "F"
                                    LET rDatosTemp.afiliatoria = "FINADO"
                            END CASE
                            DISPLAY BY NAME rDatosTemp.afiliatoria
                            DISPLAY BY NAME lSolicitud.nombre, lSolicitud.primer_apellido, lSolicitud.segundo_apellido
                        ELSE
                            CALL mensaje("La CURP ingresada NO fue localizada, por favor verifique los datos")
                            LET bndSalir = TRUE
                            EXIT INPUT
                        END IF
                        DISPLAY BY NAME rDatosTemp.regimen
                        NEXT FIELD nss_imss
                    END IF

                AFTER FIELD nss_imss
                    IF length(lSolicitud.nss_imss) < 10 THEN
                        MESSAGE "El numero de seguridad social debe ser a 11 digitos"
                        CONTINUE INPUT
                    END IF
                    IF length(lSolicitud.nss_imss) = 10 THEN
                        LET lSolicitud.nss_imss = "0"||lSolicitud.nss_imss
                        DISPLAY BY NAME lSolicitud.nss_imss
                    END IF

                AFTER FIELD curp
                    IF length(lSolicitud.curp) <> 18 THEN
                        CALL fgl_winMessage("Transferencia de Derechos","La CURP debe ser de 18 digitos","information")
                        CONTINUE INPUT
                    END IF
                    LET SQL1 = " SELECT COUNT(*)",
                               "   FROM directo",
                               "  WHERE curp = '", lSolicitud.curp, "'",
                               "    AND t_directo <> 'ER'"
                    PREPARE select_directo_curp_01 FROM SQL1
                    EXECUTE select_directo_curp_01 INTO lcontar_er

                    IF lcontar_er > 1 THEN
                        CALL fnMensajeER()
                        LET bndSalir = TRUE
                        EXIT INPUT
                    END IF
                    
                    CALL fnRecuperaDatosDirecto(lSolicitud.curp) RETURNING lSolicitud.nombre,
                                                                           lSolicitud.num_issste,
                                                                           lSolicitud.primer_apellido,
                                                                           lSolicitud.segundo_apellido,
                                                                           lSolicitud.fecha_baja,
                                                                           rDatosTemp.afiliatoria,
                                                                           rDatosTemp.fec_nac,
                                                                           rDatosTemp.nss
                    IF lSolicitud.nombre IS NOT NULL THEN
                        LET rDatosTemp.antiguedad = dias_cot(lSolicitud.num_issste)
                        DISPLAY rDatosTemp.fec_nac TO fec_nac
                        DISPLAY rDatosTemp.antiguedad TO antiguedad
                        DISPLAY rDatosTemp.nss TO nss
                        CALL fnRecuperaRegimen(lSolicitud.curp, lSolicitud.num_issste)
                                                                     RETURNING rDatosTemp.regimen
                        CASE rDatosTemp.afiliatoria
                            WHEN "A"
                                LET rDatosTemp.afiliatoria = "ACTIVO"
                            WHEN "B"
                                LET rDatosTemp.afiliatoria = "BAJA"
                            WHEN "F"
                                LET rDatosTemp.afiliatoria = "FINADO"
                        END CASE
                        DISPLAY BY NAME rDatosTemp.afiliatoria
                        DISPLAY BY NAME lSolicitud.nombre, lSolicitud.primer_apellido, lSolicitud.segundo_apellido
                    ELSE
                        CALL mensaje("La CURP ingresada NO fue localizada, por favor verifique los datos")
                        NEXT FIELD curp
                    END IF
                    DISPLAY BY NAME rDatosTemp.regimen

                ON ACTION btn_siguiente
                    IF fnValidaCampos(lSolicitud.*) = FALSE THEN
                        CONTINUE INPUT
                    END IF
                    CALL ui.Window.getCurrent().getForm().setElementHidden("group7",FALSE)
                    CALL ui.Window.getCurrent().getForm().setElementHidden("group3",FALSE)
                    CALL ui.Window.getCurrent().getForm().setElementHidden("label19",FALSE)
                    CALL ui.Window.getCurrent().getForm().setElementHidden("group4",TRUE)
                    CALL ui.Window.getCurrent().getForm().setFieldHidden("txt_env_sol",TRUE)
                    CALL ui.Window.getCurrent().getForm().setElementHidden("label4",TRUE)
                    NEXT FIELD l_val_cer
                                
                ON ACTION btn_enviar
                    IF fnValidaCampos(lSolicitud.*) = FALSE THEN
                        CONTINUE INPUT
                    END IF
                    IF gid_aplicacion = "1" THEN
                        IF l_val_cer IS NULL OR l_val_key IS NULL OR rfc IS NULL OR password IS NULL THEN
                            CALL ui.Window.getCurrent().getForm().setElementHidden("label4",FALSE)
                            CALL ui.Window.getCurrent().getForm().setFieldHidden("txt_env_sol",FALSE)
                            MESSAGE "Seleccione los archivos de la e-firma"
                            CONTINUE INPUT
                        END IF
                        LET rDatosTemp.password = password
                        LET rSATReporte.l_val_cer = l_val_cer
                        LET rSATReporte.l_val_key = l_val_key
                        LET rSATReporte.password  = password
                        LET rSATReporte.rfc       = rfc
                    END IF

--                    IF rDatosTemp.afiliatoria = "ACTIVO" THEN
--                        CALL mensaje("Derechohabiente ACTIVO")
--
--                        CALL fnAsignaDatosReporte(lSolicitud.*)
--                        RETURNING rDatosReporte.*
--                        LET rDatosReporte.regimen = rDatosTemp.regimen
--                        LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
--                        LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
--                        LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
--                        LET rDatosReporte.codigo_resultado = "-"
--                        LET rDatosReporte.folio_procesar   = "-"
--                        LET rDatosReporte.motivo_rechazo   = "Derechohabiente ACTIVO"
--                        LET rDatosReporte.observaciones    = "Derechohabiente ACTIVO", "El proceso de Transferencia de Derechos únicamente es para derechohabientes que ya registraron su BAJA en el Instituto y no tienen registro como FINADO"
--                        CALL reporteTransferenciaNoFirmado(rDatosReporte.*)
--                        INITIALIZE rDatosReporte.* TO NULL
--
--                        --CALL reporteTransferenciaNoFirmado(lSolicitud.curp, lSolicitud.folio_solicitud, lSolicitud.fecha_solicitud,
--                        --                              lSolicitud.nombre, lSolicitud.primer_apellido,
--                        --                              lSolicitud.segundo_apellido, "-", "-", "Derechohabiente ACTIVO", "El proceso de Transferencia de Derechos únicamente es para derechohabientes que ya registraron su BAJA en el Instituto y no tienen registro como FINADO")
--                        LET rDatosTemp.afiliatoria = NULL
--                        DISPLAY BY NAME rDatosTemp.afiliatoria
--                        INITIALIZE lSolicitud.nombre, lSolicitud.primer_apellido, lSolicitud.segundo_apellido TO NULL
--                        EXIT INPUT --CONTINUE INPUT
--                    END IF
                    IF rDatosTemp.afiliatoria = "FINADO" THEN
                        CALL mensaje("Derechohabiente FINADO")

                        CALL fnAsignaDatosReporte(lSolicitud.*)
                        RETURNING rDatosReporte.*
                        LET rDatosReporte.regimen = rDatosTemp.regimen
                        LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                        LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                        LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                        LET rDatosReporte.codigo_resultado = "-"
                        LET rDatosReporte.folio_procesar   = "-"
                        LET rDatosReporte.motivo_rechazo   = "Estatus de finado en la BDUD."
                        LET rDatosReporte.observaciones    = "El registro presenta estatus finado en la Base de Datos Única de Derechohabientes, deberá presentarse en su Representación del ISSSTE para corregir su información."
                        CALL reporteTransferenciaNoFirmado(rDatosReporte.*)
                        INITIALIZE rDatosReporte.* TO NULL
                        
                        LET rDatosTemp.afiliatoria = NULL
                        INITIALIZE lSolicitud.nombre, lSolicitud.primer_apellido, lSolicitud.segundo_apellido TO NULL
                        DISPLAY BY NAME rDatosTemp.afiliatoria
                        LET gmuestra_listado = TRUE
                        LET gCURP = lSolicitud.curp
                        EXIT INPUT --CONTINUE INPUT
                    END IF
                        
                    IF lSolicitud.num_issste = 0 OR lSolicitud.num_issste IS NULL THEN
                        ERROR fnDescripcionRechazo(24)
                        CONTINUE INPUT
                    END IF

                    IF fnExisteSolicitud(lSolicitud.*) = TRUE THEN
                        CALL fgl_winMessage("Transferencia de Derechos.","Ya existe una solicitud, consulte la sección de Solicitudes para descarga","information")
                        MESSAGE ""
                        --CALL fnDescargarSolicitud(lSolicitud.curp)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("label20",FALSE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group8",FALSE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group9",FALSE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group7",TRUE)
                        LET SQL1 = " SELECT *",
                                   "   FROM cei_solicitud",
                                   "  WHERE curp = '", lSolicitud.curp, "'"
                        PREPARE select_cei_solicitudes FROM SQL1
                        DECLARE curSolicitudes CURSOR FOR select_cei_solicitudes
                        LET idx = 1
                        FOREACH curSolicitudes INTO rSolicitudes.*
                            LET arrSolicitudes[idx].email = rSolicitudes.correo
                            CASE rSolicitudes.id_estatus
                                WHEN 0 LET arrSolicitudes[idx].estatus = "Iniciada"
                                WHEN 1 LET arrSolicitudes[idx].estatus = "En Proceso"
                                WHEN 2 LET arrSolicitudes[idx].estatus = "Rechazada"
                                WHEN 3 LET arrSolicitudes[idx].estatus = "Procedente"
                                WHEN 4 LET arrSolicitudes[idx].estatus = "Cancelada"
                            END CASE
                            LET arrSolicitudes[idx].fecha = rSolicitudes.fecha_solicitud
                            
                            LOCATE arrSolicitudes[idx].imagen_r IN FILE "imagen_r.tmp"
                            CALL arrSolicitudes[idx].imagen_r.readFile("img_pdf.png")
                            
                            LOCATE arrSolicitudes[idx].imagen_s IN FILE "imagen_s.tmp"
                            CALL arrSolicitudes[idx].imagen_s.readFile("img_pdf.png")
                            
                            LET arrSolicitudes[idx].folio = rSolicitudes.folio_solicitud
                            LET arrSolicitudes[idx].nss = rSolicitudes.nss_imss
                            LET idx = idx + 1
                        END FOREACH
                        DISPLAY ARRAY arrSolicitudes TO scr_solicitudes.* ATTRIBUTES(DOUBLECLICK = btn_descargar, ACCEPT = FALSE, CANCEL = FALSE)
                            ON ACTION btn_descargar_solicitud
                                LET sfolio_solicitud = arrSolicitudes[arr_curr()].folio
                                TRY
                                    CALL fgl_putfile("S_"||lSolicitud.curp||"_"||sfolio_solicitud||"_firmada.pdf","S_"||lSolicitud.curp||"_"||sfolio_solicitud||"_firmada.pdf")
                                CATCH
                                    TRY
                                        CALL fgl_putfile("S_"||lSolicitud.curp||"_"||sfolio_solicitud||".pdf","S_"||lSolicitud.curp||"_"||sfolio_solicitud||".pdf")
                                    CATCH
                                        MESSAGE "Solicitud no disponible, intente más tarde por favor"
                                    END TRY
                                END TRY

                            ON ACTION btn_descargar_resolucion
                                LET sfolio_solicitud = arrSolicitudes[arr_curr()].folio
                                TRY
                                    CALL fgl_putfile("R_"||lSolicitud.curp||"_"||sfolio_solicitud||"_firmada.pdf","R_"||lSolicitud.curp||"_"||sfolio_solicitud||"_firmada.pdf")
                                CATCH
                                    TRY
                                        CALL fgl_putfile("R_"||lSolicitud.curp||"_"||sfolio_solicitud||".pdf","R_"||lSolicitud.curp||"_"||sfolio_solicitud||".pdf")
                                    CATCH
                                        MESSAGE "Solicitud no disponible, intente más tarde por favor"
                                    END TRY
                                END TRY
                                
                            ON ACTION cancelar2
                                CALL ui.Window.getCurrent().getForm().setElementHidden("label20",TRUE)
                                CALL ui.Window.getCurrent().getForm().setElementHidden("group8",TRUE)
                                CALL ui.Window.getCurrent().getForm().setElementHidden("group7",FALSE)
                                CALL ui.Window.getCurrent().getForm().setElementHidden("group9",TRUE)
                                EXIT DISPLAY
                        END DISPLAY
                    ELSE
                        MESSAGE "Proceso de Transfeferencia de Derechos Iniciado"
                        --IF gid_aplicacion = "1" THEN
                        --    CALL servicioSAT(l_val_cer, l_val_key, lSolicitud.curp, FALSE, lSolicitud.folio_solicitud, lSolicitud.nombre CLIPPED||" "||lSolicitud.primer_apellido CLIPPED||" "||lSolicitud.segundo_apellido CLIPPED, rDatosTemp.rfc, rDatosTemp.password, "R") RETURNING rFirmaSAT.*
                        --    IF rFirmaSAT.curp IS NULL THEN
                        --        CALL fnMensajenoSAT()
                        --        LET bndSalir = TRUE
                        --        CONTINUE INPUT
                        --    END IF
                        --END IF

                        IF fnGuardarSolicitud_cei_solicitud_inicial(lSolicitud.*) = FALSE THEN
                        
                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(2)||"-"||fnDescripcionRechazo(2)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                        IF ramo_pagaduria_637_70000(lSolicitud.num_issste) = TRUE THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 10,2)
                            LET lSolicitud.observaciones = "-"

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(10)||"-"||fnDescripcionRechazo(10)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                        WHENEVER ERROR CONTINUE
                        INSERT INTO cei_solicitud_firma VALUES(rFirmaSAT.*)
                        WHENEVER ERROR STOP

                        LET lregimen = validaRegimen(lSolicitud.num_issste, lSolicitud.curp)
                        CASE lregimen
                            WHEN 1
                                --CALL fgl_winMessage("Rastreo de Portabildiad",fnDescripcionRechazo(4),"information")
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 4,2)
                                CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = "-"
                                LET rDatosReporte.folio_procesar   = "-"
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(4)||"-"||fnDescripcionRechazo(4)
                                LET rDatosReporte.observaciones    = lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                INITIALIZE rDatosReporte.* TO NULL
                                LET gmuestra_listado = TRUE
                                LET gCURP = lSolicitud.curp
                                CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                EXIT INPUT --CONTINUE INPUT
                            WHEN 2
                                --CALL fgl_winMessage("Rastreo de Portabildiad",fnDescripcionRechazo(3),"information")
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 3,2)
                                CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones
                                
                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = "-"
                                LET rDatosReporte.folio_procesar   = "-"
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(3)||"-"||fnDescripcionRechazo(3)
                                LET rDatosReporte.observaciones    = lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                INITIALIZE rDatosReporte.* TO NULL
                                LET gmuestra_listado = TRUE
                                LET gCURP = lSolicitud.curp
                                CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                EXIT INPUT --CONTINUE INPUT
                        END CASE

                        IF fnValidaCURP(lSolicitud.folio_solicitud, lSolicitud.num_issste, lSolicitud.curp, lSolicitud.fecha_solicitud) <> 0 THEN
                            ----CALL fgl_winMessage("Rastreo de Portabildiad",fnDescripcionRechazo(5),"information")
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 5,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(5)||"-"||fnDescripcionRechazo(5)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF fnValidaEstatusDerechohabiente(lSolicitud.num_issste) = 1 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 6,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones
                            
                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(6)||"-"||fnDescripcionRechazo(6)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        CALL fnValidaBeneficioPensionario(lSolicitud.num_issste) RETURNING lbeneficio_pensionario
                        IF lbeneficio_pensionario <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 7,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(7)||"-"||fnDescripcionRechazo(7)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF presentaMarca200(lSolicitud.num_issste) <> 0 THEN
                            --CALL fgl_winMessage("Rastreo de Portabildiad",fnDescripcionRechazo(8),"information")
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 8,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(8)||"-"||fnDescripcionRechazo(8)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

--                        IF traslapeMarca100(lSolicitud.num_issste) <> 0 THEN
--                            --CALL fgl_winMessage("Rastreo de Portabildiad",fnDescripcionRechazo(9),"information")
--                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 9,2)
--                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones
--
--                            CALL fnAsignaDatosReporte(lSolicitud.*)
--                            RETURNING rDatosReporte.*
--                            LET rDatosReporte.regimen = rDatosTemp.regimen
--                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
--                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
--                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
--                            LET rDatosReporte.codigo_resultado = "-"
--                            LET rDatosReporte.folio_procesar   = "-"
--                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(9)||"-"||fnDescripcionRechazo(9)
--                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
--                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
--                            INITIALIZE rDatosReporte.* TO NULL
--                            LET gmuestra_listado = TRUE
--                            LET gCURP = lSolicitud.curp
--                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
--                            EXIT INPUT --CONTINUE INPUT
--                        END IF

                        IF periodosMarca400_430(lSolicitud.num_issste) <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 10,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(10)||"-"||fnDescripcionRechazo(10)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF usuariosInvalidos(lSolicitud.num_issste) <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 11,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(11)||"-"||fnDescripcionRechazo(11)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF sueldomenor90(lSolicitud.num_issste) <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 11,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(11)||"-"||fnDescripcionRechazo(11)
                            LET rDatosReporte.observaciones = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF fechas_invertidas(lSolicitud.num_issste) <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 11,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(11)||"-"||fnDescripcionRechazo(11)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF mismo_ramo_pagaduria_mismo_cierre_o_duplicados(lSolicitud.num_issste) <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 11,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones
                            
                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(11)||"-"||fnDescripcionRechazo(11)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF antiguedad_cotizante_fondo_pensiones(lSolicitud.num_issste) < 1 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 12,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(12)||"-"||fnDescripcionRechazo(12)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF vigenteal31032007sinbonopension(lSolicitud.num_issste) <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 13,2)
                            CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(13)||"-"||fnDescripcionRechazo(13)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF bonopension_fechaingresoposterior31032007_sinHLprevia(lSolicitud.num_issste) <> 0 THEN
                            IF periodosconsistentes(lSolicitud.num_issste) <> 0 OR periodosconsistentes_campos_auditores(lSolicitud.num_issste) <> 0 THEN
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 14,2)
                                CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = "-"
                                LET rDatosReporte.folio_procesar   = "-"
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(14)||"-"||fnDescripcionRechazo(14)
                                LET rDatosReporte.observaciones = lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                INITIALIZE rDatosReporte.* TO NULL
                            
                                CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                EXIT INPUT
                            END IF
                        END IF
                        #
                        ## WS1
                        #
                        LET clienteWS1ConsultaBasicaIMSS.getEstatusAsegurado.correo            = lSolicitud.correo
                        LET clienteWS1ConsultaBasicaIMSS.getEstatusAsegurado.curp              = lSolicitud.curp
                        LET clienteWS1ConsultaBasicaIMSS.getEstatusAsegurado.fechaTramite      = util.Datetime.format(lSolicitud.fecha_solicitud,"%d/%m/%Y %H:%M:%S")
                        LET clienteWS1ConsultaBasicaIMSS.getEstatusAsegurado.institutoReceptor = "02"
                        LET clienteWS1ConsultaBasicaIMSS.getEstatusAsegurado.nss               = lSolicitud.nss_imss

                        CALL clienteWS1ConsultaBasicaIMSS.getEstatusAsegurado_g() RETURNING wsstatus
                        
                        IF wsstatus <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 51,2)
                            UPDATE cei_solicitud SET observaciones = "La solicitud de Consulta IMSS - WS1 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                             WHERE folio_solicitud = lSolicitud.folio_solicitud

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(51)||"-"||fnDescripcionRechazo(51)
                            LET rDatosReporte.observaciones = "La solicitud de Consulta IMSS - WS1 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                        
                        DISPLAY "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                        DISPLAY "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                        DISPLAY "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                        DISPLAY "Comunicacion IMSS WS1: ", wsstatus
                        LET rSalidaWS1IMSS.* = clienteWS1ConsultaBasicaIMSS.getEstatusAseguradoResponse.return.*

                        DISPLAY "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                        DISPLAY "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                        DISPLAY "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                        DISPLAY "Datos del servicio IMSS WS1: ", rSalidaWS1IMSS.*
                        
                        LET rcei_td_ws1_basica_otra.codigo_resultado = rSalidaWS1IMSS.codigoResultado
                        LET rcei_td_ws1_basica_otra.correo           = lSolicitud.correo
                        LET rcei_td_ws1_basica_otra.curp_enviada     = lSolicitud.curp
                        LET rcei_td_ws1_basica_otra.curp_solicitada  = lSolicitud.curp
                        
                        LET rcei_td_ws1_basica_otra.fecha_baja       = rSalidaWS1IMSS.fechaDeBaja
                        LET rcei_td_ws1_basica_otra.fecha_respuesta  = CURRENT YEAR TO SECOND
                        LET rcei_td_ws1_basica_otra.fecha_solicitud  = lSolicitud.fecha_solicitud
                        LET rcei_td_ws1_basica_otra.fecha_tramite    = CURRENT YEAR TO SECOND
                        LET rcei_td_ws1_basica_otra.inst_receptor    = "02"
                        LET rcei_td_ws1_basica_otra.motivo_rechazo   = rSalidaWS1IMSS.motivoRechazo
                        
                        IF rSalidaWS1IMSS.nombre IS NULL THEN
                             LET rcei_td_ws1_basica_otra.nombre       = lSolicitud.nombre
                        ELSE LET rcei_td_ws1_basica_otra.nombre       = rSalidaWS1IMSS.nombre  END IF
                        
                        LET rcei_td_ws1_basica_otra.nss_issste       = lSolicitud.num_issste
                        
                        LET rcei_td_ws1_basica_otra.nss_solicitado   = lSolicitud.nss_imss
                        
                        IF rSalidaWS1IMSS.observaciones IS NULL THEN
                             LET rcei_td_ws1_basica_otra.observaciones    = lSolicitud.observaciones, rSalidaWS1IMSS.claveError, "-", rSalidaWS1IMSS.mensajeError
                        ELSE LET rcei_td_ws1_basica_otra.observaciones    = rSalidaWS1IMSS.observaciones END IF
                        
                        IF rSalidaWS1IMSS.primerApellido IS NULL THEN
                             LET rcei_td_ws1_basica_otra.primer_apellido  = lSolicitud.primer_apellido
                        ELSE LET rcei_td_ws1_basica_otra.primer_apellido  = rSalidaWS1IMSS.primerApellido END IF
                        
                        IF rSalidaWS1IMSS.segundoApellido IS NULL THEN
                             LET rcei_td_ws1_basica_otra.segundo_apellido = lSolicitud.segundo_apellido
                        ELSE LET rcei_td_ws1_basica_otra.segundo_apellido = rSalidaWS1IMSS.segundoApellido END IF

                        CALL fnInsertacei_td_ws1_basica_otra(rcei_td_ws1_basica_otra.*)

                        LET rcei_td_ws1_basica.codigo_resultado = rSalidaWS1IMSS.codigoResultado
                        LET rcei_td_ws1_basica.curp             = rSalidaWS1IMSS.curp
                        LET rcei_td_ws1_basica.fecha_baja       = rSalidaWS1IMSS.fechaDeBaja
                        LET rcei_td_ws1_basica.fecha_respuesta  = CURRENT YEAR TO SECOND
                        LET rcei_td_ws1_basica.folio_solicitud  = lSolicitud.folio_solicitud
                        LET rcei_td_ws1_basica.motivo_rechazo   = rSalidaWS1IMSS.motivoRechazo
                        LET rcei_td_ws1_basica.nombre           = rSalidaWS1IMSS.nombre
                        LET rcei_td_ws1_basica.nss_devuelto     = rSalidaWS1IMSS.nss
                        LET rcei_td_ws1_basica.observaciones    = rSalidaWS1IMSS.observaciones, rSalidaWS1IMSS.claveError, rSalidaWS1IMSS.mensajeError
                        LET rcei_td_ws1_basica.primer_apellido  = rSalidaWS1IMSS.primerApellido
                        LET rcei_td_ws1_basica.segundo_apellido = rSalidaWS1IMSS.segundoApellido

                        CALL inserta_cei_td_ws1_basica(rcei_td_ws1_basica.*)
                        
                        IF rSalidaWS1IMSS.codigoResultado = "02" THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 15,2)
                            LET lSolicitud.observaciones = rSalidaWS1IMSS.observaciones
                            UPDATE cei_solicitud SET observaciones = lSolicitud.observaciones WHERE folio_solicitud = lSolicitud.folio_solicitud

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = rSalidaWS1IMSS.codigoResultado
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(15)||"-"||fnDescripcionRechazo(15)
                            LET rDatosReporte.observaciones    = rSalidaWS1IMSS.motivoRechazo||"-"||lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF lSolicitud.fecha_baja IS NOT NULL THEN
                            IF rSalidaWS1IMSS.fechaDeBaja > lSolicitud.fecha_baja THEN
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 16,2)
                                CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = "02"
                                LET rDatosReporte.folio_procesar   = "-"
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(16)||"-"||fnDescripcionRechazo(16)
                                LET rDatosReporte.observaciones    = lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                INITIALIZE rDatosReporte.* TO NULL
                                LET gmuestra_listado = TRUE
                                LET gCURP = lSolicitud.curp
                                CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                EXIT INPUT --CONTINUE INPUT
                            END IF
                        END IF

                        #
                        ## WS2
                        #
                        LET rConsultarEntrada.institutoReceptorTramite    = "02"
                        LET rConsultarEntrada.nssImss                     = lSolicitud.nss_imss
                        LET rConsultarEntrada.curp                        = lSolicitud.curp
                        LET rConsultarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
                        LET rConsultarEntrada.primerApellido              = lSolicitud.primer_apellido CLIPPED
                        LET rConsultarEntrada.segundoApellido             = lSolicitud.segundo_apellido CLIPPED
                        LET rConsultarEntrada.nombre                      = lSolicitud.nombre CLIPPED
                        LET rConsultarEntrada.fechaInicioTramite          = util.Datetime.format(lSolicitud.fecha_solicitud, "%d/%m/%Y %H:%M:%S" )
                        LET rConsultarEntrada.correoElectronico           = lSolicitud.correo

                        LET p_idServicio = "999"

                        CALL clienteWS2DeterminacionProcesar.consultarTramite(p_idServicio, p_idEbusiness, p_idCliente, rConsultarEntrada.*)
                        RETURNING wsstatus, r_WS2Salida

                        DISPLAY "------------------------------------------------"
                        DISPLAY "------------------------------------------------"
                        DISPLAY "------------------------------------------------"
                        DISPLAY "Comunicacion Procesar WS2: ", wsstatus

                        IF r_WS2Salida.fechaRegistroEstatus IS NOT NULL THEN
                            LET r_WS2Salida.fechaRegistroEstatus           = util.Datetime.parse(r_WS2Salida.fechaRegistroEstatus, "%d/%m/%Y %H:%M:%S")
                        END IF

                        CALL fnInserta_cei_td_ws2_procesaralta(r_WS2Salida.*, lSolicitud.folio_solicitud)

                        IF wsstatus <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 52,2)
                            UPDATE cei_solicitud SET observaciones = "La solicitud a PROCESAR experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                             WHERE folio_solicitud = lSolicitud.folio_solicitud

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(52)||"-"||fnDescripcionRechazo(52)
                            LET rDatosReporte.observaciones    = "La solicitud a PROCESAR experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        DISPLAY "------------------------------------------------"
                        DISPLAY "------------------------------------------------"
                        DISPLAY "------------------------------------------------"
                        DISPLAY "Datos Procesar WS2: ", r_WS2Salida.*

                        IF r_WS2Salida.resultadoOperacion = "02" THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 18,2)
                            
                            SELECT diagnostico||"-"||descripcion
                              INTO lSolicitud.observaciones
                              FROM cei_cat_procesar
                             WHERE dictaminacion = "CONSULTA"
                               AND diagnostico = r_WS2Salida.motivoRechazo

                            UPDATE cei_solicitud SET observaciones = lSolicitud.observaciones WHERE folio_solicitud = lSolicitud.folio_solicitud

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = r_WS2Salida.resultadoOperacion
                            LET rDatosReporte.folio_procesar   = r_WS2Salida.folioProcesar
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(18)||"-"||fnDescripcionRechazo(18)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF r_WS2Salida.resultadoOperacion = "01" THEN
                            IF r_WS2Salida.fechaOtorgamientoDerechoImss IS NOT NULL OR
                               r_WS2Salida.fechaOtorgamientoDerechoIssste IS NOT NULL THEN
                               DISPLAY "r_WS2Salida.fechaOtorgamientoDerechoImss: ", r_WS2Salida.fechaOtorgamientoDerechoImss
                               DISPLAY "r_WS2Salida.fechaOtorgamientoDerechoIssste: ", r_WS2Salida.fechaOtorgamientoDerechoIssste
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 17,2)
                                SELECT diagnostico||"-"||descripcion
                                  INTO lSolicitud.observaciones
                                  FROM cei_cat_procesar
                                 WHERE dictaminacion = "CONSULTA"
                                   AND diagnostico = r_WS2Salida.motivoRechazo
                                UPDATE cei_solicitud SET observaciones = lSolicitud.observaciones WHERE folio_solicitud = lSolicitud.folio_solicitud

                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = "02"--r_WS2Salida.resultadoOperacion
                                LET rDatosReporte.folio_procesar   = r_WS2Salida.folioProcesar
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(17)||"-"||fnDescripcionRechazo(17)
                                LET rDatosReporte.observaciones    = lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                INITIALIZE rDatosReporte.* TO NULL
                                
                                
                                LET rCancelarEntrada.curp                        = lSolicitud.curp
                                LET rCancelarEntrada.estatusSolicitado           = "02"
                                LET rCancelarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
                                LET rCancelarEntrada.institutoReceptorTramite    = "02"
                                LET rCancelarEntrada.motivoCancelacion           = "120"
                                LET rCancelarEntrada.nssImss                     = lSolicitud.nss_imss

                                LET rcei_td_ws5_procesarrechazo.codigo_resultado             = r_WS2Salida.resultadoOperacion
                                LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = r_WS2Salida.estatusDictaminacionPortabilidad
                                LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = r_WS2Salida.motivoRechazo
                                LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
                                LET rcei_td_ws5_procesarrechazo.folio_procesar               = r_WS2Salida.folioProcesar
                                LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
                                LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = r_WS2Salida.motivoRechazo
                                
                                CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)
                                
                                CALL clienteWS5ActualizarProcesar.cancelarTramite("1001", p_idEbusiness, p_idCliente, rCancelarEntrada.*)
                                RETURNING wsstatus, rWS5SalidaPROCESAR

                                IF wsstatus <> 0 THEN
                                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 49,2)
                                    UPDATE cei_solicitud SET observaciones = "La solicitud de Cancelacion a PROCESAR - WS5 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                                    WHERE folio_solicitud = lSolicitud.folio_solicitud

                                    CALL fnAsignaDatosReporte(lSolicitud.*)
                                    RETURNING rDatosReporte.*
                                    LET rDatosReporte.regimen = rDatosTemp.regimen
                                    LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                    LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                    LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                    LET rDatosReporte.codigo_resultado = "-"
                                    LET rDatosReporte.folio_procesar   = "-"
                                    LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(49)||"-"||fnDescripcionRechazo(49)
                                    LET rDatosReporte.observaciones    = "La solicitud de Cancelacion a PROCESAR - WS5 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                                    CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                    INITIALIZE rDatosReporte.* TO NULL
                                    CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                    LET gmuestra_listado = TRUE
                                    LET gCURP = lSolicitud.curp
                                    EXIT INPUT --CONTINUE INPUT
                                END IF

                                DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                                DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                                DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                                DISPLAY "Comunicacion Procesar WS5 A: ", wsstatus

                                DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                                DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                                DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                                DISPLAY "Datos Procesar WS5 A: ", rWS5SalidaPROCESAR.*

                                
                                IF rWS5SalidaPROCESAR.resultadoOperacion = "02" THEN
                                    --CALL fgl_winMessage("Portabildiad Rastreo","Inserta en cei_td_ws5_procesarrechazo","information")
                                    LET rcei_td_ws5_procesarrechazo.codigo_resultado             = rWS5SalidaPROCESAR.resultadoOperacion
                                    LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = 2
                                    LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = rWS5SalidaPROCESAR.motivoRechazo
                                    LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
                                    LET rcei_td_ws5_procesarrechazo.folio_procesar               = rWS5SalidaPROCESAR.folioProcesar
                                    LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
                                    LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = r_ws3SalidaIMSS.codigoResultado
                                    CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)
                                    
                                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 20,2)
                                    
                                    SELECT diagnostico||"-"||descripcion
                                      INTO lSolicitud.observaciones
                                      FROM cei_cat_procesar
                                     WHERE dictaminacion = "CANCELACION"
                                       AND diagnostico = rWS5SalidaPROCESAR.motivoRechazo

                                    UPDATE cei_solicitud SET observaciones = lSolicitud.observaciones WHERE folio_solicitud = lSolicitud.folio_solicitud

                                    CALL fnAsignaDatosReporte(lSolicitud.*)
                                    RETURNING rDatosReporte.*
                                    LET rDatosReporte.regimen = rDatosTemp.regimen
                                    LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                    LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                    LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                    LET rDatosReporte.codigo_resultado = rWS5SalidaPROCESAR.resultadoOperacion
                                    LET rDatosReporte.folio_procesar   = rWS5SalidaPROCESAR.folioProcesar
                                    LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(20)||"-"||fnDescripcionRechazo(20)
                                    LET rDatosReporte.observaciones    = lSolicitud.observaciones
                                    CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                    INITIALIZE rDatosReporte.* TO NULL
                                    CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                    LET gmuestra_listado = TRUE
                                    LET gCURP = lSolicitud.curp
                                    EXIT INPUT --CONTINUE INPUT
                                ## Se comento porque se considero que ya No debe pasar al WS3
                                ## y se debe quedar el estatus reportado por el WS1 - 20250618 - TK2025103932
--                                ELSE
--                                    CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 19,2)
--                                    LET lSolicitud.observaciones = r_ws3SalidaIMSS.observaciones
--
--                                    CALL fnAsignaDatosReporte(lSolicitud.*)
--                                    RETURNING rDatosReporte.*
--                                    LET rDatosReporte.regimen = rDatosTemp.regimen
--                                    LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
--                                    LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
--                                    LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
--                                    LET rDatosReporte.codigo_resultado = rWS5SalidaPROCESAR.resultadoOperacion
--                                    LET rDatosReporte.folio_procesar   = rWS5SalidaPROCESAR.folioProcesar
--                                    LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(19)||"-"||fnDescripcionRechazo(19)
--                                    LET rDatosReporte.observaciones    = lSolicitud.observaciones
--                                    CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
--                                    INITIALIZE rDatosReporte.* TO NULL
                                    
                                END IF
                                CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                                LET gmuestra_listado = TRUE
                                LET gCURP = lSolicitud.curp
                                EXIT INPUT --CONTINUE INPUT
                            END IF
                        END IF

                        -- Se forza la salida cuando existe un beneficio pensionario marcado en procesarr
                        IF (r_WS2Salida.fechaOtorgamientoDerechoImss   IS NOT NULL OR
                           r_WS2Salida.fechaOtorgamientoDerechoIssste IS NOT NULL) AND
                           r_WS2Salida.resultadoOperacion = "01"
                        THEN
                            EXIT INPUT
                        END IF

                        -- IF esindicado por sentencia = NO THEN
                        ----CALL fgl_winMessage("Rastreo de Portabilidad","Proceso indicado por sentencia","information")
                        #
                        ## WS3
                        #
                        LET clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado.correo                = lSolicitud.correo
                        LET clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado.curp                  = lSolicitud.curp
                        LET clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado.fechaTramite          = util.Datetime.format(lSolicitud.fecha_solicitud,"%d/%m/%Y %H:%M:%S")
                        LET clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado.folioTramiteReceptor  = lSolicitud.folio_solicitud
                        LET clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado.institutoReceptor     = "02"
                        LET clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado.nss                   = lSolicitud.nss_imss

                        
                        CALL clienteWS3ConsultaRobustaIMSS.getPeriodosAsegurado_g() RETURNING wsstatus

                        IF wsstatus <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 53,2)
                            UPDATE cei_solicitud SET observaciones = "La solicitud de Consulta Robusta IMSS - WS3 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                            WHERE folio_solicitud = lSolicitud.folio_solicitud

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(53)||"-"||fnDescripcionRechazo(53)
                            LET rDatosReporte.observaciones    = "La solicitud de Consulta Robuista IMSS - WS3 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        DISPLAY "################################################"
                        DISPLAY "################################################"
                        DISPLAY "################################################"
                        DISPLAY "Comunicacion IMSS WS3: ", wsstatus
                        
                        LET r_ws3SalidaIMSS.* = clienteWS3ConsultaRobustaIMSS.getPeriodosAseguradoResponse.resultado.*


                        DISPLAY "################################################"
                        DISPLAY "################################################"
                        DISPLAY "################################################"
                        DISPLAY "Datos IMSS WS3: ", r_ws3SalidaIMSS.*

                        IF r_ws3SalidaIMSS.codigoResultado = "01" THEN
                            LET lRobustaOtra.codigo_resultado = r_ws3SalidaIMSS.codigoResultado
                            LET lRobustaOtra.correo           = lSolicitud.correo
                            LET lRobustaOtra.curp_solicitada  = r_ws3SalidaIMSS.curp
                            LET lRobustaOtra.fecha_respuesta  = CURRENT YEAR TO SECOND
                            LET lRobustaOtra.fecha_solicitud  = r_ws3SalidaIMSS.fechaDeEnvio
                            LET lRobustaOtra.fecha_tramite    = CURRENT YEAR TO SECOND
                            LET lRobustaOtra.folio_solicitud  = lSolicitud.folio_solicitud
                            LET lRobustaOtra.inst_receptor    = lSolicitud.id_aplicacion
                            LET lRobustaOtra.motivo_rechazo   = r_ws3SalidaIMSS.motivoRechazo
                            LET lRobustaOtra.nss_solicitado   = r_ws3SalidaIMSS.nss
                            
                            LET lRobusta.codigo_resultado  = r_ws3SalidaIMSS.codigoResultado
                            LET lRobusta.curp              = r_ws3SalidaIMSS.curp
                            LET lRobusta.dias_cotizados    = r_ws3SalidaIMSS.diasCotizados
                            LET lRobusta.dias_descontados  = r_ws3SalidaIMSS.diasDescontados
                            LET lRobusta.dias_reintegrados = r_ws3SalidaIMSS.diasReintegrados
                            LET lRobusta.eventos_deduccion = r_ws3SalidaIMSS.eventosDeduccion
                            LET lRobusta.fecha_baja        = r_ws3SalidaIMSS.fechaDeBaja
                            CALL util.Datetime.parse(r_ws3SalidaIMSS.fechaDeEnvio,"%d/%m/%Y %H:%M:%S") RETURNING lRobusta.fecha_envio
                            LET lRobusta.fecha_respuesta   = CURRENT YEAR TO SECOND
                            LET lRobusta.folio_solicitud   = lSolicitud.folio_solicitud
                            LET lRobusta.motivo_rechazo    = r_ws3SalidaIMSS.motivoRechazo
                            LET lRobusta.nombre            = r_ws3SalidaIMSS.nombre
                            LET lRobusta.nss               = r_ws3SalidaIMSS.nss
                            LET lRobusta.observaciones     = r_ws3SalidaIMSS.observaciones
                            LET lRobusta.periodos_portados = r_ws3SalidaIMSS.periodosPortados
                            LET lRobusta.primer_apellido   = r_ws3SalidaIMSS.primerApellido
                            LET lRobusta.segundo_apellido  = r_ws3SalidaIMSS.segundoApellido
                            LET lRobusta.total_dias        = r_ws3SalidaIMSS.totalDeDias
                            SELECT NVL(MAX(id_robusta),0) + 1
                              INTO lRobusta.id_robusta
                              FROM cei_td_ws3_robusta
                             WHERE folio_solicitud = lSolicitud.folio_solicitud
                             
                            UPDATE cei_td_solicitud SET folio_externo = 0 WHERE folio_solicitud = lSolicitud.folio_solicitud
                            
                            CALL fnInserta_cei_td_ws3_robusta(lRobusta.*)
                            FOR idx =1 TO r_ws3SalidaIMSS.listaPeriodos.getLength()
                                IF r_ws3SalidaIMSS.listaPeriodos[idx].entidadFederativaPatron IS NULL OR length(r_ws3SalidaIMSS.listaPeriodos[idx].entidadFederativaPatron) = 0 THEN
                                    LET r_ws3SalidaIMSS.listaPeriodos[idx].entidadFederativaPatron = "ENTIDAD NO DEFINIDA"
                                END IF
                                LET lRobustaOtraPeriodos.entidad_patron   = r_ws3SalidaIMSS.listaPeriodos[idx].entidadFederativaPatron
                                LET lRobustaOtraPeriodos.fecha_inicio     = r_ws3SalidaIMSS.listaPeriodos[idx].fechaInicio
                                LET lRobustaOtraPeriodos.fecha_termino    = r_ws3SalidaIMSS.listaPeriodos[idx].fechaTermino
                                LET lRobustaOtraPeriodos.folio_solicitud  = lSolicitud.folio_solicitud
                                LET lRobustaOtraPeriodos.id_periodo_ws    = "" --Se calcula en la insercion
                                LET lRobustaOtraPeriodos.nombre_pagaduria = r_ws3SalidaIMSS.listaPeriodos[idx].RP
                                LET lRobustaOtraPeriodos.nombre_patron    = r_ws3SalidaIMSS.listaPeriodos[idx].nombreDependenciaOPatron
                                LET lRobustaOtraPeriodos.patron_ramo_pag  = r_ws3SalidaIMSS.listaPeriodos[idx].RP
                                LET lRobustaOtraPeriodos.sueldo           = r_ws3SalidaIMSS.listaPeriodos[idx].sueldoRegistradoPorPeriodo
                                LET lRobustaOtraPeriodos.tipo_movimiento  = r_ws3SalidaIMSS.listaPeriodos[idx].tipoMovimiento
                                LET lRobustaOtraPeriodos.id_robusta       = lRobusta.id_robusta
                                CALL inserta_cei_td_ws3_robusta_periodos(lRobustaOtraPeriodos.*)

--                                        LET SQL1 = " INSERT INTO cuenta_ind(",
--                                                               " num_ramo,",
--                                                               " num_pagaduria,",
--                                                               " num_issste,",
--                                                               " cin_id,",
----                                                               " u_version,",
--                                                               " mod_total_par,",
--                                                               " mod_cve,",
--                                                               " fecha_inicio,",
--                                                               " fecha_termino,",
--                                                               " t_movto_inicio,",
--                                                               " t_movto_cierre,",
--                                                               " periodo_afecta,",
--                                                               " sueldo_issste,",
--                                                               --" uso_pen,",
--                                                               " dias_licencia,",
--                                                               " usuario,",
--                                                               " fecha_aud,",
--                                                               " hora_aud,",
--                                                               " componente_cve,",
--                                                               " ip_maquina",
--                                                               ")",
--                                                   " VALUES (",
--                                                             "  '637'",
--                                                             ", '70000'",
--                                                             ", ", lSolicitud.num_issste,
--                                                             ", ", max_cin_id_cuenta_ind(),
--                                                             ", 'E'",
--                                                             ", 12",
--                                                             ", '", lRobustaOtraPeriodos.fecha_inicio, "'",
--                                                             ", '", lRobustaOtraPeriodos.fecha_termino, "'",
--                                                             ", 'A'",
--                                                             ", 'B'",
--                                                             ", 0",
--                                                             ", ", (lRobustaOtraPeriodos.sueldo*30),
--                                                             ", 0",
--                                                             ", 'A0409816'",
--                                                             ", '", TODAY, "'",
--                                                             ", '", CURRENT HOUR TO SECOND, "'",
--                                                             ", 'WS6_PORT'",
--                                                             ", '", lSolicitud.ip_maquina,"'",
--                                                            ")"
--                                        PREPARE insert_into_cuenta_ind_periodos_imss FROM SQL1
--                                        EXECUTE insert_into_cuenta_ind_periodos_imss
                            END FOR
                            CALL integra_periodos_IMSS(lSolicitud.folio_solicitud, lRobusta.id_robusta, lSolicitud.num_issste, lSolicitud.ip_maquina, gsolo_usuario, gcomponente)
                        END IF

                        IF r_ws3SalidaIMSS.codigoResultado = "02" THEN
                            LET lRobusta.folio_solicitud  = lSolicitud.folio_solicitud
                            LET lRobusta.codigo_resultado = "02"
                            LET lRobusta.fecha_envio      = CURRENT YEAR TO SECOND
                            LET lRobusta.fecha_respuesta  = CURRENT YEAR TO SECOND
                            LET lRobusta.observaciones    = r_ws3SalidaIMSS.observaciones
                            LET lRobusta.motivo_rechazo   = r_ws3SalidaIMSS.motivoRechazo
                            
                            CALL fnInserta_cei_td_ws3_robusta(lRobusta.*)
                            #
                            # WS5
                            #
                            LET rCancelarEntrada.curp                        = lSolicitud.curp
                            LET rCancelarEntrada.estatusSolicitado           = "02"
                            LET rCancelarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
                            LET rCancelarEntrada.institutoReceptorTramite    = "02"
                            LET rCancelarEntrada.motivoCancelacion           = "119" --119 --P03
                            LET rCancelarEntrada.nssImss                     = lSolicitud.nss_imss
                            CALL clienteWS5ActualizarProcesar.cancelarTramite("1001", p_idEbusiness, p_idCliente, rCancelarEntrada.*)
                            RETURNING wsstatus, rWS5SalidaPROCESAR

--                            IF wsstatus <> 0 THEN
--                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 49,2)
--                                UPDATE cei_solicitud SET observaciones = "La solicitud de Cancelación a PROCESAR - WS5 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
--
--                                CALL fnAsignaDatosReporte(lSolicitud.*)
--                                RETURNING rDatosReporte.*
--                                LET rDatosReporte.regimen = rDatosTemp.regimen
--                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
--                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
--                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
--                                LET rDatosReporte.codigo_resultado = "-"
--                                LET rDatosReporte.folio_procesar   = "-"
--                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(49)||"-"||fnDescripcionRechazo(49)
--                                LET rDatosReporte.observaciones    = "La solicitud de Cancelación al PROCESAR - WS5 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
--                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
--                                INITIALIZE rDatosReporte.* TO NULL
--                                CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
--                                LET gmuestra_listado = TRUE
--                                LET gCURP = lSolicitud.curp
--                                EXIT INPUT --CONTINUE INPUT
--                            END IF

                            DISPLAY "############################"
                            DISPLAY "############################"
                            DISPLAY "############################"
                            DISPLAY "############################"
                            DISPLAY "GUARDAR PROCESARRECHAZO"
                            LET rcei_td_ws5_procesarrechazo.codigo_resultado             = rWS5SalidaPROCESAR.resultadoOperacion
                            LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = 2
                            LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = rWS5SalidaPROCESAR.motivoRechazo
                            LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
                            LET rcei_td_ws5_procesarrechazo.folio_procesar               = rWS5SalidaPROCESAR.folioProcesar
                            LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
                            LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = rWS5SalidaPROCESAR.motivoRechazo

                            DISPLAY rcei_td_ws5_procesarrechazo.codigo_resultado
                            DISPLAY rcei_td_ws5_procesarrechazo.dictaminacion_estatus
                            DISPLAY rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo
                            DISPLAY rcei_td_ws5_procesarrechazo.fecha_dictaminacion
                            DISPLAY rcei_td_ws5_procesarrechazo.folio_procesar
                            DISPLAY rcei_td_ws5_procesarrechazo.folio_solicitud
                            DISPLAY rcei_td_ws5_procesarrechazo.motivo_rechazo
                            
                            CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)
                            
--                            IF rWS5SalidaPROCESAR.resultadoOperacion = "02" THEN
--                                --LET rcei_td_ws5_procesarrechazo.codigo_resultado             = rWS5SalidaPROCESAR.resultadoOperacion
--                                --LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = 2
--                                --LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = rWS5SalidaPROCESAR.motivoRechazo
--                                --LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
--                                --LET rcei_td_ws5_procesarrechazo.folio_procesar               = rWS5SalidaPROCESAR.folioProcesar
--                                --LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
--                                --LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = r_ws3SalidaIMSS.codigoResultado
--                                --CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)
--                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 49,2)
--                                LET lSolicitud.observaciones = r_ws3SalidaIMSS.observaciones
--
--                                CALL fnAsignaDatosReporte(lSolicitud.*)
--                                RETURNING rDatosReporte.*
--                                LET rDatosReporte.regimen = rDatosTemp.regimen
--                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
--                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
--                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
--                                LET rDatosReporte.codigo_resultado = rWS5SalidaPROCESAR.folioProcesar
--                                LET rDatosReporte.folio_procesar   = rWS5SalidaPROCESAR.resultadoOperacion
--                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(49)||"-"||fnDescripcionRechazo(49)
--                                LET rDatosReporte.observaciones    = "La solicitud de Cancelación al PROCESAR - WS5 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
--                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
--                                INITIALIZE rDatosReporte.* TO NULL
--                            ELSE
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 19,2)
                                LET lSolicitud.observaciones = r_ws3SalidaIMSS.observaciones

                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = rWS5SalidaPROCESAR.folioProcesar
                                LET rDatosReporte.folio_procesar   = rWS5SalidaPROCESAR.resultadoOperacion
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(19)||"-"||fnDescripcionRechazo(19)
                                LET rDatosReporte.observaciones    = r_ws3SalidaIMSS.motivoRechazo||"-"||lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                CALL fnEliminacionPeriodos(lSolicitud.num_issste)
                                INITIALIZE rDatosReporte.* TO NULL
                            --END IF
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        ##
                        # DICTAMINIACION BENEFICIO PENSIONARIO
                        ##
                        LET rEntradaValidaBeneficioPensionario.curp                   = lSolicitud.curp
                        LET rEntradaValidaBeneficioPensionario.nss_imss               = lSolicitud.nss_imss
                        LET rEntradaValidaBeneficioPensionario.salario_prom_hl        = 0
                        LET rEntradaValidaBeneficioPensionario.tiempo_cotizado_imss   = r_ws3SalidaIMSS.totalDeDias
                        LET rEntradaValidaBeneficioPensionario.tiempo_cotizado_issste = dias_cot(lSolicitud.num_issste)
                        LET rEntradaValidaBeneficioPensionario.folio_solicitud        = lSolicitud.folio_solicitud

                        DISPLAY "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
                        DISPLAY "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
                        DISPLAY "Datos Entrada DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO curp: ", rEntradaValidaBeneficioPensionario.curp
                        DISPLAY "Datos Entrada DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO nss_imss: ", rEntradaValidaBeneficioPensionario.nss_imss
                        DISPLAY "Datos Entrada DICTAMINACION DICTAMEN BENEFICIO PENSIONARIOsalario_prom_hl: ", rEntradaValidaBeneficioPensionario.salario_prom_hl
                        DISPLAY "Datos Entrada DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO tiempo_cotizado_imss: ", rEntradaValidaBeneficioPensionario.tiempo_cotizado_imss
                        DISPLAY "Datos Entrada DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO tiempo_cotizado_issste: ", rEntradaValidaBeneficioPensionario.tiempo_cotizado_issste
                        DISPLAY "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"

                        CALL clienteDictamenBeneficioPensionario.dictaminabeneficiopensionario(rEntradaValidaBeneficioPensionario.*)
                        RETURNING wsstatus_dictamenbenficiopensionario, rSalidaValidaBeneficioPensionario.*

                        DISPLAY "......................................................"
                        DISPLAY "......................................................"
                        DISPLAY "......................................................"
                        DISPLAY "Estatus del servicio WS7: ", wsstatus_dictamenbenficiopensionario

                        IF wsstatus_dictamenbenficiopensionario <> 0 THEN
                            CALL fnEliminacionPeriodos(lSolicitud.num_issste)
                            #
                            ## WS6
                            #
                            DISPLAY "//////////////////////////////////////////////////////////"
                            DISPLAY "//////////////////////////////////////////////////////////"
                            DISPLAY "//////////////////////////////////////////////////////////"
                            DISPLAY "Cominicacion WS6: ", wsstatus
                            
                            LET rWS6SalidaIMSS.* = clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidadResponse.resultado.*

                            DISPLAY "//////////////////////////////////////////////////////////"
                            DISPLAY "Datos WS6 dictameinacion ws:"
                            DISPLAY "1claveError: ", rWS6SalidaIMSS.claveError
                            DISPLAY "1codigoResultado: ", rWS6SalidaIMSS.codigoResultado
                            DISPLAY "1mensajeError: ", rWS6SalidaIMSS.mensajeError
                            DISPLAY "1motivoRechazo: ", rWS6SalidaIMSS.motivoRechazo

                            LET SQL1 = " INSERT INTO cei_td_ws6_procedencia(folio_solicitud, codigo_resultado, motivo_rechazo, fecha_registro)",
                                       " VALUES(",
                                               " ", lSolicitud.folio_solicitud,
                                               ", '", rWS6SalidaIMSS.codigoResultado, "'",
                                               ", '", rWS6SalidaIMSS.motivoRechazo, "'",
                                               ", '", CURRENT YEAR TO SECOND, "'",
                                              ")"
                            PREPARE insert_cei_td_ws6_procedencia FROM SQL1
                            EXECUTE insert_cei_td_ws6_procedencia

                            #
                            # WS5
                            #
                            LET rCancelarEntrada.curp                        = lSolicitud.curp
                            LET rCancelarEntrada.estatusSolicitado           = "02"
                            LET rCancelarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
                            LET rCancelarEntrada.institutoReceptorTramite    = "02"
                            LET rCancelarEntrada.motivoCancelacion           = "123"
                            LET rCancelarEntrada.nssImss                     = lSolicitud.nss_imss

                            CALL clienteWS5ActualizarProcesar.cancelarTramite("1001", p_idEbusiness, p_idCliente, rCancelarEntrada.*)
                            RETURNING wsstatus, rWS5SalidaPROCESAR

                            

                            LET rcei_td_ws5_procesarrechazo.codigo_resultado             = rWS5SalidaPROCESAR.resultadoOperacion
                            LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = 2
                            LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = rWS5SalidaPROCESAR.motivoRechazo
                            LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
                            LET rcei_td_ws5_procesarrechazo.folio_procesar               = rWS5SalidaPROCESAR.folioProcesar
                            LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
                            LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = rWS5SalidaPROCESAR.resultadoOperacion
                            LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
                            
                            CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)

                            DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                            DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                            DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                            DISPLAY "Comunicacion Procesar WS5 A: ", wsstatus

                            DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                            DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                            DISPLAY "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
                            DISPLAY "Datos Procesar WS5 A: ", rWS5SalidaPROCESAR.*

                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 46,2) --123
                            LET lSolicitud.observaciones = "Por favor inténtelo nuevamente más tarde."

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(46)||"-"||fnDescripcionRechazo(46)
                            LET rDatosReporte.observaciones    = lSolicitud.observaciones
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            CALL fnEliminacionPeriodos(lSolicitud.num_issste)
                            INITIALIZE rDatosReporte.* TO NULL
                                
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF rSalidaValidaBeneficioPensionario.codigo_resultado = "10" THEN -- comunicacion con saldos preliminar
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 56,2) --123

                            CALL fnRechazoServicio_ws6_y_ws5()

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(56)||"-"||fnDescripcionRechazo(56)
                            LET rDatosReporte.observaciones    = rSalidaValidaBeneficioPensionario.codigo_resultado||"-"||fnObservacionesRechazo(56)
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF rSalidaValidaBeneficioPensionario.codigo_resultado = "20" THEN -- Rechazo por saldos preliminar
                            
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 58,2) --123
                            
                            CALL fnRechazoServicio_ws6_y_ws5()

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "02"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(58)||"-"||fnDescripcionRechazo(58)
                            LET rDatosReporte.observaciones    = rSalidaValidaBeneficioPensionario.codigo_resultado||"-"||fnObservacionesRechazo(58)
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF rSalidaValidaBeneficioPensionario.codigo_resultado = "30" THEN -- comunicacion con CNSF
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 57,2) --132

                            CALL fnRechazoServicio_ws6_y_ws5()

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(57)||"-"||fnDescripcionRechazo(57)
                            LET rDatosReporte.observaciones    = rSalidaValidaBeneficioPensionario.codigo_resultado||"-"||fnObservacionesRechazo(57)
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL

                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF

                        IF rSalidaValidaBeneficioPensionario.codigo_resultado = "40" THEN -- sin derecho <59 por saldo insuficiente
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 59,2) --134
                            
                            CALL fnRechazoServicio_ws6_y_ws5()

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnDescripcionRechazo(59)
                            LET rDatosReporte.observaciones    = rSalidaValidaBeneficioPensionario.codigo_resultado||"-"||fnObservacionesRechazo(59)
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                        
                        IF rSalidaValidaBeneficioPensionario.codigo_resultado = "50" THEN  --Mayores = 60

                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 20,2) --134
                            
                            CALL fnRechazoServicio_ws6_y_ws5()

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(20)||"-"||fnDescripcionRechazo(20)
                            LET rDatosReporte.observaciones    = rSalidaValidaBeneficioPensionario.codigo_resultado||"-"||fnObservacionesRechazo(20)
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                               
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                        

                        DISPLAY "LO QUE DEVOLVIO EL SERVICIO 7"
                        DISPLAY "Estatus del servicio 7 wsstatus_dictamenbenficiopensionario: ", wsstatus_dictamenbenficiopensionario
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO curp: ", rSalidaValidaBeneficioPensionario.curp
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO cve_beneficio: ", rSalidaValidaBeneficioPensionario.cve_beneficio
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO derecho_pension: ", rSalidaValidaBeneficioPensionario.derecho_pension
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO desc_beneficio: ", rSalidaValidaBeneficioPensionario.desc_beneficio
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO nss_imss: ", rSalidaValidaBeneficioPensionario.nss_imss
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO observaciones: ", rSalidaValidaBeneficioPensionario.observaciones
                        DISPLAY "Datos SALIDA DICTAMINACION DICTAMEN BENEFICIO PENSIONARIO codigo_resultado: ", rSalidaValidaBeneficioPensionario.codigo_resultado
                        
                        --CALL integra_periodos_IMSS(lSolicitud.folio_solicitud, lRobusta.id_robusta)

                        ----CALL fgl_winMessage("Rastreo Portabilidad","Inicia WS6 - Notificacion de procedencia","information")
                        #
                        ## WS6
                        #
                        LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.curp = lSolicitud.curp
                        LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.folioTramiteReceptor = lSolicitud.folio_solicitud
                        LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.institutoReceptor = "02"
                        LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.nss = lSolicitud.nss_imss
                        LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.resultadoIntegracionPortabilidad = 1

                        CALL clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad_g() RETURNING wsstatus

                        IF wsstatus <> 0 THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 47,2) --124
                            CALL fnEliminacionPeriodos(lSolicitud.num_issste)
                            UPDATE cei_solicitud SET observaciones = "La solicitud de Aviso de Conclusión al IMSS - WS6 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                            WHERE folio_solicitud = lSolicitud.folio_solicitud

                            CALL fnAsignaDatosReporte(lSolicitud.*)
                            RETURNING rDatosReporte.*
                            LET rDatosReporte.regimen = rDatosTemp.regimen
                            LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                            LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                            LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                            LET rDatosReporte.codigo_resultado = "-"
                            LET rDatosReporte.folio_procesar   = "-"
                            LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(47)||"-"||fnDescripcionRechazo(47)
                            LET rDatosReporte.observaciones    = "La solicitud de Aviso de Conclusión al IMSS - WS6 experimenta un tiempo de respuesta inusual. Por favor inténtelo nuevamente más tarde."
                            CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                            INITIALIZE rDatosReporte.* TO NULL
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                            
                        DISPLAY "//////////////////////////////////////////////////////////"
                        DISPLAY "//////////////////////////////////////////////////////////"
                        DISPLAY "//////////////////////////////////////////////////////////"
                        DISPLAY "Cominicacion WS6: ", wsstatus
                        
                        LET rWS6SalidaIMSS.* = clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidadResponse.resultado.*

                        DISPLAY "//////////////////////////////////////////////////////////"
                        DISPLAY "Datos WS6:"
                        DISPLAY "1claveError: ", rWS6SalidaIMSS.claveError
                        DISPLAY "1codigoResultado: ", rWS6SalidaIMSS.codigoResultado
                        DISPLAY "1mensajeError: ", rWS6SalidaIMSS.mensajeError
                        DISPLAY "1motivoRechazo: ", rWS6SalidaIMSS.motivoRechazo

                        LET SQL1 = " INSERT INTO cei_td_ws6_procedencia(folio_solicitud, codigo_resultado, motivo_rechazo, fecha_registro)",
                                   " VALUES(",
                                           " ", lSolicitud.folio_solicitud,
                                           ", '", rWS6SalidaIMSS.codigoResultado, "'",
                                           ", '", rWS6SalidaIMSS.motivoRechazo, "'",
                                           ", '", CURRENT YEAR TO SECOND, "'",
                                          ")"
                        PREPARE insert_cei_td_ws6_procedencia_01 FROM SQL1
                        EXECUTE insert_cei_td_ws6_procedencia_01

                        IF rWS6SalidaIMSS.codigoResultado = "02" THEN
                            CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 21,2)
                            
                            ----CALL fgl_winMessage("Rastreo Portabilidad","Eliminacion de periodos de Portabilidad por rechazo del IMSS","information")
                            CALL fnEliminacionPeriodos(lSolicitud.num_issste)
                            ----CALL fgl_winMessage("Rastreo Portabilidad","Inicia servicio WS5 - Actualizar estatus de la solicitud "||fnDescripcionRechazo(21),"information")
                            LET rCancelarEntrada.curp                        = lSolicitud.curp
                            LET rCancelarEntrada.estatusSolicitado           = rWS6SalidaIMSS.codigoResultado
                            LET rCancelarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
                            LET rCancelarEntrada.institutoReceptorTramite    = lSolicitud.id_tiposolicitud
                            LET rCancelarEntrada.motivoCancelacion           = "121"
                            LET rCancelarEntrada.nssImss                     = lSolicitud.nss_imss

                            LET p_idServicio = "1001"
                            CALL clienteWS5ActualizarProcesar.cancelarTramite(p_idServicio, p_idEbusiness, p_idCliente, rCancelarEntrada.*)
                            RETURNING wsstatus, rWS5SalidaPROCESAR

                            DISPLAY "(((((((((((((((((((((((((((((((((((((((((((((((((((((((((("
                            DISPLAY "//////////////////////////////////////////////////////////"
                            DISPLAY "(((((((((((((((((((((((((((((((((((((((((((((((((((((((((("
                            DISPLAY "Comunicacion Procesar WS5 B: ", wsstatus

                            DISPLAY "(((((((((((((((((((((((((((((((((((((((((((((((((((((((((("
                            DISPLAY "//////////////////////////////////////////////////////////"
                            DISPLAY "(((((((((((((((((((((((((((((((((((((((((((((((((((((((((("
                            DISPLAY "Datos Procesar WS5 B: ", rWS5SalidaPROCESAR.*
                            #
                            # WS5
                            #
--                            IF rWS5SalidaPROCESAR.resultadoOperacion = "02" THEN
--                                --CALL fgl_winMessage("Portabildiad Rastreo","Inserta en cei_td_ws5_procesarrechazo","information")
--                                LET rcei_td_ws5_procesarrechazo.codigo_resultado             = rWS5SalidaPROCESAR.resultadoOperacion
--                                LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = 2
--                                LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = rWS5SalidaPROCESAR.motivoRechazo
--                                LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
--                                LET rcei_td_ws5_procesarrechazo.folio_procesar               = rWS5SalidaPROCESAR.folioProcesar
--                                LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
--                                LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = rWS6SalidaIMSS.codigoResultado
--                                
--                                CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)
--                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 21,2)
--
--                                SELECT diagnostico||"-"||descripcion
--                                  INTO lSolicitud.observaciones
--                                  FROM cei_cat_procesar
--                                 WHERE dictaminacion = "CANCELACION"
--                                   AND diagnostico = rWS5SalidaPROCESAR.motivoRechazo
--
--                                UPDATE cei_solicitud SET observaciones = lSolicitud.observaciones WHERE folio_solicitud = lSolicitud.folio_solicitud
--
--                                CALL fnAsignaDatosReporte(lSolicitud.*)
--                                RETURNING rDatosReporte.*
--                                LET rDatosReporte.regimen = rDatosTemp.regimen
--                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
--                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
--                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
--                                LET rDatosReporte.codigo_resultado = rWS5SalidaPROCESAR.folioProcesar
--                                LET rDatosReporte.folio_procesar   = rWS5SalidaPROCESAR.resultadoOperacion
--                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(21)||"-"||fnDescripcionRechazo(21)
--                                LET rDatosReporte.observaciones    = lSolicitud.observaciones
--                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
--                                INITIALIZE rDatosReporte.* TO NULL
--                            ELSE
                                CALL fnActualizaEstatusSolicitud(lSolicitud.folio_solicitud, 21,2)
                                LET lSolicitud.observaciones = rWS6SalidaIMSS.motivoRechazo

                                CALL fnAsignaDatosReporte(lSolicitud.*)
                                RETURNING rDatosReporte.*
                                LET rDatosReporte.regimen = rDatosTemp.regimen
                                LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                                LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                                LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                                LET rDatosReporte.codigo_resultado = rWS6SalidaIMSS.codigoResultado
                                LET rDatosReporte.folio_procesar   = rWS5SalidaPROCESAR.resultadoOperacion
                                LET rDatosReporte.motivo_rechazo   = fnMotivoRechazo(21)||"-"||fnDescripcionRechazo(21)
                                LET rDatosReporte.observaciones    = lSolicitud.observaciones
                                CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                                INITIALIZE rDatosReporte.* TO NULL
                            --END IF
                            CALL fnGenerarFolioSolicitud() RETURNING lSolicitud.folio_solicitud
                            LET gmuestra_listado = TRUE
                            LET gCURP = lSolicitud.curp
                            EXIT INPUT --CONTINUE INPUT
                        END IF
                        ---Procesar
                        ----CALL fgl_winMessage("Rastreo Portabilidad","Inicia consumo de servicio WS4 - consulta Notificar a PROCESAR simulada","information")
                        #
                        # WS4
                        #
                        IF lSolicitud.observaciones = "-" THEN
                            LET lSolicitud.observaciones = ""
                        END IF
                        LET rInsertarEntrada.curp                        = lSolicitud.curp
                        LET rInsertarEntrada.diasCotizadosImss           = r_ws3SalidaIMSS.diasCotizados
                        LET rInsertarEntrada.diasCotizadosIssste         = rDatosTemp.antiguedad
                        LET rInsertarEntrada.diasDescontadosImss         = r_ws3SalidaIMSS.diasDescontados
                        LET rInsertarEntrada.diasDescontadosIssste       = 0
                        LET rInsertarEntrada.diasReintegradosImss        = r_ws3SalidaIMSS.diasReintegrados
                        LET rInsertarEntrada.fechaBajaImss               = rSalidaWS1IMSS.fechaDeBaja
                        LET rInsertarEntrada.fechaBajaIssste             = lSolicitud.fecha_baja
                        LET rInsertarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
                        LET rInsertarEntrada.institutoReceptorTramite    = "02"
                        LET rInsertarEntrada.nssImss                     = lSolicitud.nss_imss
                        LET rInsertarEntrada.observaciones               = lSolicitud.observaciones
                        LET rInsertarEntrada.totalDiasImss               = r_ws3SalidaIMSS.totalDeDias
                        LET rInsertarEntrada.totalDiasIssste             = dias_cot(lSolicitud.num_issste)
                        LET rInsertarEntrada.totalSemanasAnnios          = fnObtieneanios(dias_cot(lSolicitud.num_issste))
                        
                        CALL clienteWS4NotificarProcesar.insertarTramite("1000", p_idEbusiness, p_idCliente, rInsertarEntrada.*)
                        RETURNING wsstatus, r_ws4SalidaProcesar

                        IF wsstatus <> 0 THEN
                            LET rcei_td_ws4_procesarexito.folio_solicitud         = lSolicitud.folio_solicitud
                            LET rcei_td_ws4_procesarexito.codigo_resultado        = "00"
                            LET rcei_td_ws4_procesarexito.motivo_rechazo          = 0
                            LET rcei_td_ws4_procesarexito.folio_procesar          = 0
                            LET rcei_td_ws4_procesarexito.fecha_baja_imss         = r_ws3SalidaIMSS.fechaDeBaja
                            LET rcei_td_ws4_procesarexito.dias_cotizados_imss     = r_ws3SalidaIMSS.diasCotizados
                            LET rcei_td_ws4_procesarexito.dias_descontados_imss   = r_ws3SalidaIMSS.diasDescontados
                            LET rcei_td_ws4_procesarexito.dias_reintegrados_imss  = r_ws3SalidaIMSS.diasReintegrados
                            LET rcei_td_ws4_procesarexito.total_dias_imss         = r_ws3SalidaIMSS.totalDeDias
                            LET rcei_td_ws4_procesarexito.fecha_baja_issste       = lSolicitud.fecha_baja
                            LET rcei_td_ws4_procesarexito.dias_cotizados_issste   = rDatosTemp.antiguedad
                            LET rcei_td_ws4_procesarexito.dias_descontados_issste = 0
                            LET rcei_td_ws4_procesarexito.total_dias_issste       = dias_cot(lSolicitud.num_issste)
                            LET rcei_td_ws4_procesarexito.total_anios             = fnObtieneanios(dias_cot(lSolicitud.num_issste))
                            LET rcei_td_ws4_procesarexito.observaciones           = lSolicitud.observaciones
                            LET rcei_td_ws4_procesarexito.fecha_respuesta         = CURRENT YEAR TO SECOND
                            CALL fnInsertarProcesxarExito(rcei_td_ws4_procesarexito.*)
                        END IF

                        DISPLAY ")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"
                        DISPLAY ")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"
                        DISPLAY ")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"
                        DISPLAY "Comunicacion Procesar WS4: ", wsstatus

                        DISPLAY ")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"
                        DISPLAY ")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"
                        DISPLAY ")))))))))))))))))))))))))))))))))))))))))))))))))))))))))))"
                        DISPLAY "Datos Procesar WS4: ", r_ws4SalidaProcesar.*
                        DISPLAY "resultadoOperacion: ", r_ws4SalidaProcesar.resultadoOperacion

                        IF r_ws4SalidaProcesar.resultadoOperacion = "02" THEN
                            LET rcei_td_ws4_procesarexito.folio_solicitud         = lSolicitud.folio_solicitud
                            LET rcei_td_ws4_procesarexito.codigo_resultado        = r_ws4SalidaProcesar.resultadoOperacion
                            LET rcei_td_ws4_procesarexito.motivo_rechazo          = r_ws4SalidaProcesar.motivoRechazo
                            LET rcei_td_ws4_procesarexito.folio_procesar          = r_ws4SalidaProcesar.folioProcesar
                            LET rcei_td_ws4_procesarexito.fecha_baja_imss         = r_ws3SalidaIMSS.fechaDeBaja
                            LET rcei_td_ws4_procesarexito.dias_cotizados_imss     = r_ws3SalidaIMSS.diasCotizados
                            LET rcei_td_ws4_procesarexito.dias_descontados_imss   = r_ws3SalidaIMSS.diasDescontados
                            LET rcei_td_ws4_procesarexito.dias_reintegrados_imss  = r_ws3SalidaIMSS.diasReintegrados
                            LET rcei_td_ws4_procesarexito.total_dias_imss         = r_ws3SalidaIMSS.totalDeDias
                            LET rcei_td_ws4_procesarexito.fecha_baja_issste       = lSolicitud.fecha_baja
                            LET rcei_td_ws4_procesarexito.dias_cotizados_issste   = rDatosTemp.antiguedad
                            LET rcei_td_ws4_procesarexito.dias_descontados_issste = 0
                            LET rcei_td_ws4_procesarexito.total_dias_issste       = dias_cot(lSolicitud.num_issste)
                            LET rcei_td_ws4_procesarexito.total_anios             = fnObtieneanios(dias_cot(lSolicitud.num_issste))
                            LET rcei_td_ws4_procesarexito.observaciones           = lSolicitud.observaciones
                            LET rcei_td_ws4_procesarexito.fecha_respuesta         = CURRENT YEAR TO SECOND
                            CALL fnInsertarProcesxarExito(rcei_td_ws4_procesarexito.*)
                        END IF
                        IF r_ws4SalidaProcesar.resultadoOperacion = "01" THEN
                            LET rcei_td_ws4_procesarexito.folio_solicitud         = lSolicitud.folio_solicitud
                            LET rcei_td_ws4_procesarexito.codigo_resultado        = r_ws4SalidaProcesar.resultadoOperacion
                            LET rcei_td_ws4_procesarexito.motivo_rechazo          = "Aceptado"
                            LET rcei_td_ws4_procesarexito.folio_procesar          = r_ws4SalidaProcesar.folioProcesar
                            LET rcei_td_ws4_procesarexito.fecha_baja_imss         = r_ws3SalidaIMSS.fechaDeBaja
                            LET rcei_td_ws4_procesarexito.dias_cotizados_imss     = r_ws3SalidaIMSS.diasCotizados
                            LET rcei_td_ws4_procesarexito.dias_descontados_imss   = r_ws3SalidaIMSS.diasDescontados
                            LET rcei_td_ws4_procesarexito.dias_reintegrados_imss  = r_ws3SalidaIMSS.diasReintegrados
                            LET rcei_td_ws4_procesarexito.total_dias_imss         = r_ws3SalidaIMSS.totalDeDias
                            LET rcei_td_ws4_procesarexito.fecha_baja_issste       = lSolicitud.fecha_baja
                            LET rcei_td_ws4_procesarexito.dias_cotizados_issste   = rDatosTemp.antiguedad
                            LET rcei_td_ws4_procesarexito.dias_descontados_issste = 0
                            LET rcei_td_ws4_procesarexito.total_dias_issste       = dias_cot(lSolicitud.num_issste)
                            LET rcei_td_ws4_procesarexito.total_anios             = fnObtieneanios(dias_cot(lSolicitud.num_issste))
                            LET rcei_td_ws4_procesarexito.observaciones           = lSolicitud.observaciones
                            LET rcei_td_ws4_procesarexito.fecha_respuesta         = CURRENT YEAR TO SECOND
                            CALL fnInsertarProcesxarExito(rcei_td_ws4_procesarexito.*)
                        END IF
                        
                        CALL f_actualiza_solicitud(NULL,3,lSolicitud.folio_solicitud)
                        MESSAGE "Transeferencia de Derechos - Procedente" --CALL fgl_winMessage("Transferencia de Derechos","Transeferencia de Derechos - Procedente","information")
                        CALL obtieneObservacionesdeActualizacion(lSolicitud.observaciones, lSolicitud.folio_solicitud) RETURNING lSolicitud.observaciones

                        CALL fnAsignaDatosReporte(lSolicitud.*)
                        RETURNING rDatosReporte.*
                        LET rDatosReporte.regimen = rDatosTemp.regimen
                        LET rDatosReporte.fecha_nacimiento = rDatosTemp.fec_nac
                        LET rDatosReporte.antiguedad       = rDatosTemp.antiguedad
                        LET rDatosReporte.situacion_afil   = rDatosTemp.afiliatoria
                        LET rDatosReporte.codigo_resultado = "01"
                        --LET rDatosReporte.folio_procesar   = r_ws4SalidaProcesar.folioProcesar
                        LET rDatosReporte.motivo_rechazo   = "Ninguno."
                        LET rDatosReporte.observaciones    = "Ninguna."
                        CALL reporteTransferencia(rDatosReporte.*, rSATReporte.*)
                        INITIALIZE rDatosReporte.* TO NULL
                            
                        INITIALIZE lSolicitud.*, l_val_cer, l_val_key, rDatosTemp.afiliatoria, rDatosTemp.regimen, rDatosTemp.antiguedad, rDatosTemp.fec_nac, rDatosTemp.nss TO NULL
                        
                        DISPLAY "fjs_ok_grey.png" TO img_cer_ok
                        DISPLAY "fjs_ok_grey.png" TO img_llave_ok
                        --DISPLAY "ayuda.png" TO img_help
                        CALL fnllenaComboCatTipoSolicitud()
                        CALL fnllenaComboCatAplicacion()
                        
                        LET lSolicitud.folio_solicitud  = fnGenerarFolioSolicitud()
                        LET lSolicitud.usuario          = gusuario
                        LET lSolicitud.ip_maquina       = fgl_getenv("FGL_WEBSERVER_REMOTE_ADDR")
                        LET lSolicitud.fecha_solicitud  = CURRENT YEAR TO SECOND
                        LET lSolicitud.id_estatus       = 0
                        LET lSolicitud.id_aplicacion    = 1
                        LET lSolicitud.id_tiposolicitud = 1
                        DISPLAY BY NAME rDatosTemp.afiliatoria
                        DISPLAY BY NAME rDatosTemp.regimen
                        DISPLAY BY NAME rDatosTemp.antiguedad
                        DISPLAY BY NAME rDatosTemp.fec_nac
                        DISPLAY BY NAME lSolicitud.*, l_val_cer, l_val_key, rDatosTemp.afiliatoria, rDatosTemp.regimen, rDatosTemp.antiguedad, rDatosTemp.fec_nac, rDatosTemp.nss
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group4",FALSE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group7",TRUE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("group3",TRUE)
                        CALL ui.Window.getCurrent().getForm().setElementHidden("label19",TRUE)
                        LET gmuestra_listado = TRUE
                        LET gCURP = lSolicitud.curp
                        EXIT INPUT
                    END IF

                ON ACTION btn_sel_cer
                    CALL ui.Interface.frontCall("standard", "openFile", ["C:","","*.cer","Seleccione el certificado"], [certificado])
                    IF certificado IS NULL AND l_val_cer IS NULL THEN
                        DISPLAY "fjs_ok_grey.png" TO img_cer_ok
                        CONTINUE INPUT
                    END IF
                    TRY
                        IF ui.Interface.getFrontEndName() = "GDC" THEN
                            LET l_val_cer = os.Path.baseName(certificado)
                            CALL fgl_getfile(certificado,os.Path.pwd()||os.Path.separator()||l_val_cer)
                            CALL fnAbreCertificado(l_val_cer, lSolicitud.curp) RETURNING lbndValido, rDatosTemp.rfc, rDatosTemp.nombre_completo
                        ELSE
                            LET l_val_cer = certificado
                            CALL fgl_getfile(certificado,certificado)
                            CALL fnAbreCertificado(certificado, lSolicitud.curp) RETURNING lbndValido, rDatosTemp.rfc, rDatosTemp.nombre_completo
                        END IF
                        IF lbndValido = FALSE THEN
                            LET rDatosTemp.nombre_completo = "Certificado Invalido"
                            LET rDatosTemp.rfc = NULL
                            LET rfc = rDatosTemp.rfc
                            DISPLAY BY NAME rDatosTemp.nombre_completo, rDatosTemp.rfc
                            CALL fnAbreCertificado1(certificado, lSolicitud.curp) RETURNING lbndValido, rDatosTemp.rfc, rDatosTemp.nombre_completo
                            IF lbndValido = FALSE THEN
                                LET rDatosTemp.nombre_completo = "Certificado Invalido"
                                LET rDatosTemp.rfc = NULL
                                LET rfc = rDatosTemp.rfc
                                DISPLAY BY NAME rDatosTemp.nombre_completo, rDatosTemp.rfc
                            END IF
                        END IF
                        
                        IF lbndValido = TRUE THEN
                            MESSAGE ""
                            LET rfc = rDatosTemp.rfc
                            DISPLAY BY NAME rDatosTemp.nombre_completo, rDatosTemp.rfc
                            DISPLAY "fjs_ok.png" TO img_cer_ok
                        ELSE
                            MESSAGE "Los archivos de la e-firma no corresponden con los datos registrados en la BDUD"
                            DISPLAY "fjs_ok_grey.png" TO img_cer_ok
                            CONTINUE INPUT
                        END IF
                    CATCH
                        DISPLAY "fjs_ok_grey.png" TO img_cer_ok
                    END TRY
                    
                ON ACTION btn_sel_key
                    CALL ui.Interface.frontCall("standard", "openFile", ["C:","","*.key","Seleccione la llave privada"], [llave_privada])
                    IF llave_privada IS NULL AND l_val_key IS NULL THEN
                        DISPLAY "fjs_ok_grey.png" TO img_llave_ok
                        CONTINUE INPUT
                    END IF
                    TRY
                        IF ui.Interface.getFrontEndName() = "GDC" THEN
                            LET l_val_key = os.Path.baseName(llave_privada)
                            CALL fgl_getfile(llave_privada,os.Path.pwd()||os.Path.separator()||l_val_key)
                        ELSE
                            LET l_val_key = llave_privada
                            CALL fgl_getfile(llave_privada, llave_privada)
                        END IF
                        DISPLAY "fjs_ok.png" TO img_llave_ok
                    CATCH
                        DISPLAY "fjs_ok_grey.png" TO img_llave_ok
                    END TRY

                ON ACTION cancelar
                    LET bndSalir = TRUE
                    --CALL ui.Window.getCurrent().getForm().setElementHidden("group4",FALSE)
                    --CALL ui.Window.getCurrent().getForm().setElementHidden("group7",TRUE)
                    --CALL ui.Window.getCurrent().getForm().setElementHidden("group3",TRUE)
                    --CALL ui.Window.getCurrent().getForm().setElementHidden("label19",TRUE)
                    EXIT INPUT
                    
                --ON ACTION btn_nueva
                --    CALL ui.Window.getCurrent().getForm().setElementHidden("group4",FALSE)
                --    CALL ui.Window.getCurrent().getForm().setElementHidden("group7",TRUE)
                --    CALL ui.Window.getCurrent().getForm().setElementHidden("group3",TRUE)
                --    CALL ui.Window.getCurrent().getForm().setElementHidden("label19",TRUE)
                --    INITIALIZE lSolicitud.*, l_val_cer, l_val_key, rDatosTemp.afiliatoria, rDatosTemp.regimen, rDatosTemp.antiguedad, rDatosTemp.fec_nac, rDatosTemp.rfc, rDatosTemp.password TO NULL
                --        
                --        DISPLAY "fjs_ok_grey.png" TO img_cer_ok
                --        DISPLAY "fjs_ok_grey.png" TO img_llave_ok
                --        --DISPLAY "ayuda.png" TO img_help
                --        CALL fnllenaComboCatTipoSolicitud()
                --        CALL fnllenaComboCatAplicacion()
                --        
                --        LET lSolicitud.folio_solicitud  = fnGenerarFolioSolicitud()
                --        IF fgl_getenv("OS")= "Windows_NT" THEN
                --            LET lSolicitud.usuario          = fgl_getenv("USERNAME")
                --        ELSE
                --            LET lSolicitud.usuario          = fgl_getenv("USER")
                --        END IF
                --        LET lSolicitud.ip_maquina       = fgl_getenv("FGL_WEBSERVER_REMOTE_ADDR")
                --        LET lSolicitud.fecha_solicitud  = CURRENT YEAR TO SECOND
                --        LET lSolicitud.id_estatus       = 0
                --        LET lSolicitud.id_aplicacion    = 1
                --        LET lSolicitud.id_tiposolicitud = 1
                --        DISPLAY BY NAME rDatosTemp.afiliatoria
                --        DISPLAY BY NAME rDatosTemp.regimen
                --        DISPLAY BY NAME rDatosTemp.antiguedad
                --        DISPLAY BY NAME rDatosTemp.fec_nac
                --        DISPLAY BY NAME lSolicitud.*, l_val_cer, l_val_key, rDatosTemp.afiliatoria, rDatosTemp.regimen, rDatosTemp.antiguedad, rDatosTemp.fec_nac
                --        --EXIT INPUT
                --        --END INPUT
                --        NEXT FIELD curp
                ON ACTION CANCEL
                    LET bndSalir = TRUE
                    EXIT INPUT
            END INPUT
        --DISCONNECT CURRENT
    CLOSE WINDOW vtnDatosInicialesPortabilidad

    RETURN bndSalir
END FUNCTION

FUNCTION f_inserta_periodos_imss(r_consRobPeriodos_issste)
    DEFINE r_consRobPeriodos_issste RECORD LIKE cei_td_ws3_robusta_periodos_issste.*
    DEFINE ls_query                 STRING
    DEFINE SQL1                     STRING

    LET SQL1 = " SELECT NVL(MAX(id_periodo_issste),0) + 1",
               "   FROM cei_td_ws3_robusta_periodos_issste"
    PREPARE select_max_cei_td_ws3_robusta_periodos_issste FROM SQL1
    EXECUTE select_max_cei_td_ws3_robusta_periodos_issste INTO r_consRobPeriodos_issste.id_periodo_issste

    --WHENEVER ERROR CONTINUE

        LET ls_query="INSERT INTO cei_td_ws3_robusta_periodos_issste VALUES(?, ?, ?, ?, ?, ?, ?)"
        PREPARE sid_insertperiodosimss FROM ls_query
        EXECUTE sid_insertperiodosimss USING  r_consRobPeriodos_issste.*
    --WHENEVER ERROR STOP
END FUNCTION

FUNCTION fnInsertaRobusta_otraws3(rRobusta_otra)
    DEFINE rRobusta_otra RECORD LIKE cei_td_ws3_robusta_otra.*
    DEFINE SQL1 STRING

    LET SQL1 = " SELECT NVL(MAX(folio_consulta),0) + 1",
               "   FROM cei_td_ws3_robusta_otra"
    PREPARE select_max_folio_consulta FROM SQL1
    EXECUTE select_max_folio_consulta INTO rRobusta_otra.folio_externo
    LET rRobusta_otra.folio_consulta = rRobusta_otra.folio_externo

    --WHENEVER ERROR CONTINUE
    INSERT INTO cei_td_ws3_robusta_otra VALUES(rRobusta_otra.*)
    --WHENEVER ERROR STOP
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

    --WHENEVER ERROR CONTINUE
        INSERT INTO cei_td_ws4_procesarexito VALUES(rcei_td_ws4_procesarexito.*)
    --WHENEVER ERROR STOP
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

FUNCTION fnEliminacionPeriodos(lnum_issste)
    DEFINE lnum_issste BIGINT
    DEFINE SQL1            STRING

    LET SQL1 = " DELETE FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "   AND num_ramo = '637'",
               "   AND num_pagaduria = '70000'"
    PREPARE delete_periodos_cuenta_ind FROM SQL1
    EXECUTE delete_periodos_cuenta_ind
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

FUNCTION mensaje(lmensaje)
    DEFINE lmensaje STRING
    DEFINE ltitulo STRING
    LET ltitulo = "Transferencia de Derechos."
    CALL fgl_winMessage(ltitulo,lmensaje,"information")
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

FUNCTION fnValidaBeneficioPensionario(lnum_issste)
    DEFINE lnum_issste DECIMAL(10,2)
    DEFINE SQL1 STRING
    DEFINE lbeneficio INTEGER

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM tramite_dt",
               "  WHERE no_issste_d = ", lnum_issste,
               "    AND cve_beneficio in (1,2,3)",
               "    AND estatus_tramite = 22"
    PREPARE select_beneficiopensionario FROM SQL1
    EXECUTE select_beneficiopensionario INTO lbeneficio

    IF lbeneficio > 1 THEN
        RETURN 1
    END IF
    
    RETURN 0
END FUNCTION

FUNCTION ramo_pagaduria_637_70000(lnum_issste)
    DEFINE lnum_issste DECIMAL(10,2)
    DEFINE SQL1 STRING
    DEFINE lcontar INTEGER

    LET SQL1 = " SELECT COUNT(*)",
               "   FROM cuenta_ind",
               "  WHERE num_issste = ", lnum_issste,
               "    AND num_ramo = 637",
               "    AND num_pagaduria = '70000'"
    PREPARE select_cuenta_ind_ramo_637_pagaduria_70000 FROM SQL1
    EXECUTE select_cuenta_ind_ramo_637_pagaduria_70000 INTO lcontar
    
    IF lcontar > 0 THEN
        RETURN TRUE
    END IF
    
    RETURN FALSE
END FUNCTION


FUNCTION fnRechazoServicio_ws6_y_ws5()
    DEFINE wsstatus INTEGER
    DEFINE SQL1 STRING
    DEFINE folio_consulta BIGINT

    -- Esta funcion parte de que haya un rechazo en el dictamen
    
    LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.curp                 = lSolicitud.curp
    LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.folioTramiteReceptor = lSolicitud.folio_solicitud
    LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.institutoReceptor    = "02"
    LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.nss                  = lSolicitud.nss_imss
    LET clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad.resultadoIntegracionPortabilidad = 0

    CALL clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidad_g() RETURNING wsstatus
    LET rWS6SalidaIMSS.* = clienteWS6AvisoEstatusTransferenciaIMSS.concluirPortabilidadResponse.resultado.*

    IF wsstatus <> 0 THEN -- No hubo conexion con el servicio
        LET rWS6SalidaIMSS.codigoResultado = "02"
        LET rWS6SalidaIMSS.motivoRechazo = "124"
    END IF

    IF rWS6SalidaIMSS.codigoResultado IS NULL THEN
        LET rWS6SalidaIMSS.codigoResultado = "02"
        LET rWS6SalidaIMSS.motivoRechazo = "124"
    END IF

    -- fallo de conexion, excepcion, etc

    LET SQL1 = " SELECT NVL(MAX(folio_consulta), 0) + 1",
               " FROM cei_td_ws6_procedencia_otra"
    PREPARE select_max_folio_consulta_00 FROM SQL1
    EXECUTE select_max_folio_consulta_00 INTO folio_consulta

    LET SQL1 = " INSERT INTO cei_td_ws6_procedencia_otra(",
                                                        "folio_consulta,",
                                                        " inst_receptor,",
                                                        " nss_solicitado,",
                                                        " curp_solicitada,",
                                                        " folio_externo,",
                                                        " resultado_integracion,",
                                                        " fecha_respuesta,",
                                                        " codigo_resultado,",
                                                        " motivo_rechazo,",
                                                        " folio_solicitud)",
                                            "VALUES(", folio_consulta,
                                               ", '02'",
                                               ", '", lSolicitud.nss_imss, "'",
                                               ", '", lSolicitud.curp, "'",
                                               ", '0'",
                                               ", 0",
                                               ", '", CURRENT YEAR TO SECOND, "'",
                                               ", '", rWS6SalidaIMSS.codigoResultado, "'",
                                               ", '", rWS6SalidaIMSS.motivoRechazo, "'",
                                               ", ", lSolicitud.folio_solicitud,
                                            ")"
    PREPARE insert_cei_td_ws6_procedencia_otra FROM SQL1
    EXECUTE insert_cei_td_ws6_procedencia_otra

    #
    # WS5
    #        
    LET rCancelarEntrada.curp                        = lSolicitud.curp
    LET rCancelarEntrada.estatusSolicitado           = "02"
    LET rCancelarEntrada.folioTramiteEntidadReceptor = lSolicitud.folio_solicitud
    LET rCancelarEntrada.institutoReceptorTramite    = "02"
    LET rCancelarEntrada.motivoCancelacion           = "120" --120 sin beneficio pensionario posible 
    LET rCancelarEntrada.nssImss                     = lSolicitud.nss_imss

    LET p_idServicio = "1001"
    CALL clienteWS5ActualizarProcesar.cancelarTramite(p_idServicio, p_idEbusiness, p_idCliente, rCancelarEntrada.*)
    RETURNING wsstatus, rWS5SalidaPROCESAR

    IF wsstatus <> 0 THEN
        LET rWS5SalidaPROCESAR.resultadoOperacion = "02"
        LET rWS5SalidaPROCESAR.motivoRechazo      = "126" -- falla de comunicacion de rechazo
    END IF

    IF rWS5SalidaPROCESAR.resultadoOperacion IS NULL THEN
        LET rWS5SalidaPROCESAR.resultadoOperacion = "02"
        LET rWS5SalidaPROCESAR.motivoRechazo      = "126" -- falla de comunicacion de rechazo
    END IF

    LET rcei_td_ws5_procesarrechazo.codigo_resultado             = rWS5SalidaPROCESAR.resultadoOperacion
    LET rcei_td_ws5_procesarrechazo.dictaminacion_estatus        = 2
    LET rcei_td_ws5_procesarrechazo.dictaminacion_motivo_rechazo = rWS5SalidaPROCESAR.motivoRechazo
    LET rcei_td_ws5_procesarrechazo.fecha_dictaminacion          = CURRENT YEAR TO SECOND
    LET rcei_td_ws5_procesarrechazo.folio_procesar               = rWS5SalidaPROCESAR.folioProcesar
    LET rcei_td_ws5_procesarrechazo.folio_solicitud              = lSolicitud.folio_solicitud
    LET rcei_td_ws5_procesarrechazo.motivo_rechazo               = rWS5SalidaPROCESAR.motivoRechazo
    
    CALL insertar_cei_td_ws5_procesarrechazo(rcei_td_ws5_procesarrechazo.*)

    CALL fnEliminacionPeriodos(lSolicitud.num_issste)

END FUNCTION

FUNCTION fnAsignaDatosReporte(lSolicitud)
    DEFINE lSolicitud RECORD LIKE cei_solicitud.*
    DEFINE SQL1 STRING
    DEFINE lnss STRING
    DEFINE cadena STRING

    LET SQL1 = " SELECT nss",
               "   FROM directo",
               "  WHERE num_issste = ", lSolicitud.num_issste
    PREPARE select_nss_from_directo FROM SQL1

    EXECUTE select_nss_from_directo INTO lnss

    IF lnss MATCHES "*[.0]" THEN
        LET cadena = lnss
        LET lnss = cadena.subString(1, cadena.getIndexOf(".", 1)-1)
    END IF

    LET rDatosReporte.correo           = lSolicitud.correo
    LET rDatosReporte.curp             = lSolicitud.curp
    LET rDatosReporte.fecha_baja       = lSolicitud.fecha_baja
    LET rDatosReporte.fecha_solicitud  = lSolicitud.fecha_solicitud
    LET rDatosReporte.folio_solicitud  = lSolicitud.folio_solicitud
    LET rDatosReporte.nombre           = lSolicitud.nombre
    LET rDatosReporte.nss_imss         = lSolicitud.nss_imss
    LET rDatosReporte.nss_issste       = lnss
    LET rDatosReporte.observaciones    = lSolicitud.observaciones
    LET rDatosReporte.primer_apellido  = lSolicitud.primer_apellido
    LET rDatosReporte.segundo_apellido = lSolicitud.segundo_apellido
    LET rDatosReporte.telefono         = lSolicitud.telefono
    LET rDatosReporte.usuario          = lSolicitud.usuario

    RETURN rDatosReporte.*
    
END FUNCTION

FUNCTION fnAbreCertificado(certificado, curp)
    DEFINE certificado STRING
    DEFINE curp STRING
    DEFINE archivo_bc base.Channel
    DEFINE comando STRING
    DEFINE rfc STRING
    DEFINE archivo_crt STRING
    DEFINE linea_leida STRING
    DEFINE lcurp STRING
    DEFINE nombre STRING
    DEFINE rDatosCertificadoSAT t_datos_certificado

    LET archivo_crt = certificado.subString(1,certificado.getLength()-4)||".crt"

    CALL fn_obtener_datos_certificado(certificado) RETURNING rDatosCertificadoSAT
    LET rfc = rDatosCertificadoSAT.rfc
    LET nombre = rDatosCertificadoSAT.nombre
    LET curp = rDatosCertificadoSAT.curp
    DISPLAY "1.", rfc
    DISPLAY "2.", nombre
    DISPLAY "3.", curp

    RETURN TRUE, rfc, nombre

    LET comando = "openssl x509 -inform DER -in "||certificado||" -subject -noout > "||archivo_crt
    DISPLAY "comando:", comando
    RUN comando
    
    CALL base.Channel.create() RETURNING archivo_bc
    CALL archivo_bc.openFile(archivo_crt, "r")
    
    CALL archivo_bc.readLine() RETURNING linea_leida
    DISPLAY "linea_leida:", linea_leida
    DISPLAY "rstart:", linea_leida.getIndexOf("UniqueIdentifier", 1) + 17
    DISPLAY "rend:", linea_leida.getIndexOf("UniqueIdentifier", 1) + 28
    LET rfc = linea_leida.subString(linea_leida.getIndexOf("UniqueIdentifier", 1) + 17, linea_leida.getIndexOf("UniqueIdentifier", 1) + 28)
    IF length(rfc) = 12 THEN
        DISPLAY "rend:", linea_leida.getIndexOf("UniqueIdentifier", 1) + 29
        LET rfc = linea_leida.subString(linea_leida.getIndexOf("UniqueIdentifier", 1) + 17, linea_leida.getIndexOf("UniqueIdentifier", 1) + 29)
    END IF
    DISPLAY "rfc:", rfc
    DISPLAY "start:", linea_leida.getIndexOf("serialNumber", 1) + 13
    DISPLAY "end:",linea_leida.getIndexOf("serialNumber", 1)
    DISPLAY "end1:",linea_leida.getIndexOf("serialNumber", 1) + 30
    LET lcurp = linea_leida.subString(linea_leida.getIndexOf("serialNumber", 1) + 13, linea_leida.getIndexOf("serialNumber", 1) + 30)
    DISPLAY "lcurp:", lcurp

    LET nombre = linea_leida.subString(linea_leida.getIndexOf("name", 1) + 5, linea_leida.getIndexOf("/", linea_leida.getIndexOf("name", 1) + 7) - 1)
    DISPLAY "nombre:", nombre
    DISPLAY "curp:", curp
    DISPLAY "lcurp:", lcurp
    IF curp = lcurp THEN
        DISPLAY "datosopen:", rfc
        DISPLAY "datosopen:", nombre
        RETURN TRUE, rfc, nombre
    END IF
    
    RETURN FALSE, rfc, nombre
END FUNCTION

FUNCTION fn_obtener_datos_certificado(p_ruta_cer STRING)
    RETURNS t_datos_certificado

    DEFINE l_cmd            STRING
    DEFINE l_archivo_tmp     STRING
    DEFINE l_ch              base.Channel
    DEFINE l_linea           STRING
    DEFINE l_valor           STRING
    DEFINE l_pos             INTEGER
    DEFINE l_pos_slash       INTEGER
    DEFINE l_es_windows      BOOLEAN
    DEFINE l_borrado         INTEGER
    DEFINE l_datos           t_datos_certificado

    INITIALIZE l_datos.* TO NULL

    IF fgl_getenv("OS") MATCHES "*Windows*" THEN
        LET l_es_windows = TRUE
    ELSE
        LET l_es_windows = (os.Path.separator() = "\\")
    END IF

    LET l_archivo_tmp = fgl_getenv("TMPDIR")
    IF l_archivo_tmp IS NULL OR l_archivo_tmp = "" THEN
        IF l_es_windows THEN
            LET l_archivo_tmp = fgl_getenv("TEMP")
        ELSE
            LET l_archivo_tmp = "/tmp"
        END IF
    END IF
    LET l_archivo_tmp = os.Path.join(l_archivo_tmp, "subject_" || fgl_getpid() || ".txt")

    LET l_cmd = "openssl x509 -in \"", p_ruta_cer, "\" -inform DER -noout -subject ",
                "-nameopt utf8,sep_multiline > \"", l_archivo_tmp, "\" 2>&1"

    RUN l_cmd

    LET l_ch = base.Channel.create()
    CALL l_ch.openFile(l_archivo_tmp, "r")

    WHILE l_ch.read([l_linea])
        LET l_linea = l_linea.trim()

        CASE

            -- RFC (formato nuevo: solo RFC; formato viejo: "RFC / CURP")
            WHEN l_linea.getIndexOf("x500UniqueIdentifier", 1) = 1 OR
                 l_linea.getIndexOf("2.5.4.45", 1) = 1
                LET l_pos = l_linea.getIndexOf("=", 1)
                IF l_pos > 0 THEN
                    LET l_valor = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                    LET l_pos_slash = l_valor.getIndexOf("/", 1)
                    IF l_pos_slash > 0 THEN
                        LET l_datos.rfc  = l_valor.subString(1, l_pos_slash - 1).trim()
                        LET l_datos.curp = l_valor.subString(l_pos_slash + 1, l_valor.getLength()).trim()
                    ELSE
                        LET l_datos.rfc = l_valor
                    END IF
                END IF

            -- CURP (formato nuevo, campo separado; solo aplica a persona fisica)
            WHEN l_linea.getIndexOf("serialNumber", 1) = 1 OR
                 l_linea.getIndexOf("2.5.4.5", 1) = 1
                LET l_pos = l_linea.getIndexOf("=", 1)
                IF l_pos > 0 THEN
                    LET l_datos.curp = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                END IF

            -- Sucursal: solo presente en CSD (diferenciador CSD vs FIEL)
            WHEN l_linea.getIndexOf("OU=", 1) = 1 OR
                 l_linea.getIndexOf("2.5.4.11", 1) = 1
                LET l_pos = l_linea.getIndexOf("=", 1)
                IF l_pos > 0 THEN
                    LET l_datos.sucursal = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                END IF

            -- Email
            WHEN l_linea.getIndexOf("emailAddress", 1) = 1 OR
                 l_linea.getIndexOf("1.2.840.113549.1.9.1", 1) = 1
                LET l_pos = l_linea.getIndexOf("=", 1)
                IF l_pos > 0 THEN
                    LET l_datos.email = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                END IF

            -- Pais
            WHEN l_linea.getIndexOf("C=", 1) = 1 OR
                 l_linea.getIndexOf("2.5.4.6", 1) = 1
                LET l_pos = l_linea.getIndexOf("=", 1)
                IF l_pos > 0 THEN
                    LET l_datos.pais = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                END IF

            -- Nombre / razon social: prioridad O= > name= > CN=
            WHEN l_linea.getIndexOf("O=", 1) = 1 AND
                 l_linea.getIndexOf("OU=", 1) <> 1
                LET l_pos = l_linea.getIndexOf("=", 1)
                IF l_pos > 0 THEN
                    LET l_datos.nombre = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                END IF

            WHEN l_linea.getIndexOf("name=", 1) = 1 OR
                 l_linea.getIndexOf("2.5.4.41", 1) = 1
                IF l_datos.nombre IS NULL OR l_datos.nombre = "" THEN
                    LET l_pos = l_linea.getIndexOf("=", 1)
                    IF l_pos > 0 THEN
                        LET l_datos.nombre = l_linea.subString(l_pos + 1, l_linea.getLength()).trim()
                    END IF
                END IF

            WHEN l_linea.getIndexOf("CN=", 1) = 1
                IF l_datos.nombre IS NULL OR l_datos.nombre = "" THEN
                    LET l_datos.nombre = l_linea.subString(4, l_linea.getLength()).trim()
                END IF

            -- Captura de cualquier campo no reconocido, para revision manual
            OTHERWISE
                IF l_linea.getIndexOf("=", 1) > 0 THEN
                    DISPLAY "fn_obtener_datos_certificado: campo no procesado -> ", l_linea
                END IF

        END CASE
    END WHILE

    CALL l_ch.close()

    IF os.Path.exists(l_archivo_tmp) THEN
        LET l_borrado = os.Path.delete(l_archivo_tmp)
        IF NOT l_borrado THEN
            DISPLAY "Advertencia: no se pudo borrar el archivo temporal ", l_archivo_tmp
        END IF
    END IF

    IF l_datos.sucursal IS NOT NULL AND l_datos.sucursal <> "" THEN
        LET l_datos.tipo_cert = "CSD"
    ELSE
        LET l_datos.tipo_cert = "FIEL"
    END IF

    IF l_datos.rfc IS NOT NULL THEN
        IF l_datos.rfc.getLength() = 13 THEN
            LET l_datos.tipo_persona = "FISICA"
        ELSE
            IF l_datos.rfc.getLength() = 12 THEN
                LET l_datos.tipo_persona = "MORAL"
                LET l_datos.curp = NULL
            END IF
        END IF
    END IF

    RETURN l_datos

END FUNCTION

FUNCTION fnAbreCertificado1(certificado, curp)
    DEFINE certificado STRING
    DEFINE curp STRING
    DEFINE archivo_bc base.Channel
    DEFINE comando STRING
    DEFINE rfc STRING
    DEFINE archivo_crt STRING
    DEFINE linea_leida STRING
    DEFINE lcurp STRING
    DEFINE nombre STRING

    LET archivo_crt = certificado.subString(1,certificado.getLength()-4)||".crt"

    LET comando = "openssl x509 -inform DER -in "||certificado||" -subject -noout > "||archivo_crt
    DISPLAY "comando:", comando
    RUN comando

    CALL base.Channel.create() RETURNING archivo_bc
    CALL archivo_bc.openFile(archivo_crt, "r")
    CALL archivo_bc.readLine() RETURNING linea_leida

    DISPLAY "linea_leida:", linea_leida
    LET rfc = linea_leida.subString(linea_leida.getIndexOf("UniqueIdentifier", 1) + 19, linea_leida.getIndexOf("UniqueIdentifier", 1) + 31)
    DISPLAY "rfc:", rfc
    LET lcurp = linea_leida.subString(linea_leida.getIndexOf("serialNumber", 1) + 15, linea_leida.getIndexOf("serialNumber", 1) + 32)
    DISPLAY "curp:", curp
    LET nombre = linea_leida.subString(linea_leida.getIndexOf("name", 1) + 7, linea_leida.getIndexOf(",", linea_leida.getIndexOf("name", 1) + 7) - 1)
    DISPLAY "nombre:", nombre
    IF curp = lcurp THEN
        RETURN TRUE, rfc, nombre
    END IF
    
    RETURN FALSE, rfc, nombre
END FUNCTION

FUNCTION fnMensajeER()
    DEFINE vtnfMensajeER STRING

    IF ui.Interface.getFrontEndName() = "GDC" THEN
        LET vtnfMensajeER = "fMensajeER_gdc"
    ELSE
        LET vtnfMensajeER = "fMensajeER"
    END IF
    
    OPEN WINDOW vtnMensajeER WITH FORM vtnfMensajeER
        MENU
            ON ACTION ACCEPT
                EXIT MENU
        END MENU
    CLOSE WINDOW vtnMensajeER
END FUNCTION

FUNCTION fnMensajenoSAT()
    DEFINE vtnfMensajeSAT STRING

    IF ui.Interface.getFrontEndName() = "GDC" THEN
        LET vtnfMensajeSAT = "fMensajenoSAT_gdc"
    ELSE
        LET vtnfMensajeSAT = "fMensajenoSAT"
    END IF
    
    OPEN WINDOW vtnMensajenoSAT WITH FORM vtnfMensajeSAT
        MENU
            ON ACTION ACCEPT
                EXIT MENU
        END MENU
    CLOSE WINDOW vtnMensajenoSAT
END FUNCTION

FUNCTION desencriptar_argumento(clave_enc)
    DEFINE clave_str STRING
    DEFINE clave_enc STRING
    DEFINE err_msg   STRING
    
    TRY
        CALL security.Base64.ToString(clave_enc) RETURNING clave_str
    CATCH
        LET err_msg="Error al desencriptar la clave : ",status
        ERROR err_msg
    END TRY

    RETURN clave_str
    
END FUNCTION