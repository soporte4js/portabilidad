IMPORT FGL clienteCNSF
IMPORT FGL clienteSaldosPreliminar
IMPORT FGL archivos_CNSFws7
SCHEMA "dsipe"

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
        
PUBLIC DEFINE msgDictPort RECORD ATTRIBUTE(WSError = "Tratamiento de Mensajes Dictamen de Beneficio Pensionario - Transferencia de Derechos")
  message STRING
END RECORD

TYPE t_wsEntradaValidaBeneficioPensionario RECORD
    nss_imss               VARCHAR(11),
    curp                   VARCHAR(18),
    tiempo_cotizado_imss   INTEGER,
    tiempo_cotizado_issste INTEGER,
    salario_prom_hl        DECIMAL(12,2),
    folio_solicitud        BIGINT
END RECORD

TYPE t_wsSalidaValidaBeneficioPensionario RECORD
    nss_imss        VARCHAR(11),
    curp            VARCHAR(18),
    cve_beneficio   INTEGER,
    desc_beneficio  VARCHAR(30),
    derecho_pension INTEGER,
    codigo_resultado VARCHAR(2),
    observaciones   VARCHAR(255)
END RECORD

PUBLIC FUNCTION dictaminabeneficiopensionario( r_wsEntrada t_wsEntradaValidaBeneficioPensionario)
ATTRIBUTES(WSPost,
        WSPath = "/dictamenbeneficiopensionario",
        WSDescription = "Dictamen de Beneficio Pensionario - Transferencia de Derechos - ISSSTE",
        WSThrows = "400:@msgDictPort")
    RETURNS( t_wsSalidaValidaBeneficioPensionario )
    
    DEFINE r_wsSalida t_wsSalidaValidaBeneficioPensionario
    DEFINE SQL1        STRING
    DEFINE lDirecto    RECORD LIKE directo.*
    DEFINE ltiempo_cot INTEGER
    DEFINE ledad       INTEGER
    DEFINE ltext       TEXT
    DEFINE lProspecto  STRING
    DEFINE lBeneficiarios STRING
    DEFINE lPassword   STRING
    DEFINE lUsuario    STRING
    DEFINE lProceso    INTEGER
    DEFINE rcei_td_wspensiones_dictamen RECORD LIKE cei_td_wspensiones_dictamen.*
    DEFINE saldos_descripcionDiagnostico VARCHAR(255)
    DEFINE lid_consulta_saldos INTEGER
    DEFINE wsstatus_saldos INTEGER
    DEFINE wsstatus_cnsf INTEGER
    DEFINE lRespuesta STRING
    DEFINE anios INTEGER
    DEFINE meses INTEGER
    DEFINE dias INTEGER

    CONNECT TO "dsipe"

        LET SQL1 = "\n SELECT first 1 *",
                   "\n   FROM directo",
                   "\n  WHERE curp = '", r_wsEntrada.curp, "'",
                   "\n    AND t_directo <> 'ER'"
        --DISPLAY SQL1
        PREPARE select_datos_derechohabiente FROM SQL1
        EXECUTE select_datos_derechohabiente INTO lDirecto.*

        IF lDirecto.curp IS NULL THEN
            LET r_wsSalida.codigo_resultado = "40"
            LET r_wsSalida.observaciones = "La CURP ingresada no existe en la BDUD"
            DISCONNECT CURRENT
            RETURN r_wsSalida
        END IF

    CALL dias_cot(lDirecto.num_issste) RETURNING anios, meses, dias
    
    --LET ltiempo_cot = (dias_cot(lDirecto.num_issste)/360)
    IF meses > 6 OR (meses = 6 AND dias >= 1) THEN
        LET ltiempo_cot = anios + 1
    ELSE
        LET ltiempo_cot = anios
    END IF

    LET ledad = fnObtieneFechaNacRENAPO(r_wsEntrada.curp)
    
    LET r_wsSalida.curp            = r_wsEntrada.curp
    LET r_wsSalida.nss_imss        = r_wsEntrada.nss_imss

    DISPLAY "$$$$$$$$$$$$$$$$$$$$$$$$"
    DISPLAY "DICTAMINACION"
    DISPLAY "EDAD: ", ledad

    LET clienteSaldosPreliminar.SaldoPreliminarIssste_SaldoPreliminarIssstePortEndpoint.Address.Uri = get_endpoint_ws("wssaldospreliminar")
    LET clienteCNSF.ISucWebSWISservice_ISucWebSWISPortEndpoint.Address.Uri = get_endpoint_ws("wscnsf")
    
    IF ledad < 60 THEN
        ######################
        ## INICIO
        ## SALDOS PRELIMINAR
        ##
        ######################
        LET ns1consultarSaldoPreliminarRequest.cuerpo.curp               = r_wsEntrada.curp
        LET ns1consultarSaldoPreliminarRequest.cuerpo.nss                = r_wsEntrada.nss_imss
        LET ns1consultarSaldoPreliminarRequest.cuerpo.cveInstitutoOrigen = "5" --7
        LET ns1consultarSaldoPreliminarRequest.idssn.codoperCliente      = "ISSSTE"
        LET ns1consultarSaldoPreliminarRequest.idssn.fecha               = YEAR(TODAY)||"-"||MONTH(TODAY)||"-"||DAY(TODAY)||"T"||CURRENT HOUR TO FRACTION(3)||"-06:00"--"2023-06-02T15:55:12.738-06:00"
        LET ns1consultarSaldoPreliminarRequest.idssn.idCanal             = "13"
        LET ns1consultarSaldoPreliminarRequest.idssn.idCliente           = "96"
        LET ns1consultarSaldoPreliminarRequest.idssn.idEbusiness         = "29"
        LET ns1consultarSaldoPreliminarRequest.idssn.idPortafolio        = "27"
        LET ns1consultarSaldoPreliminarRequest.idssn.idServicio          = "697"
        LET ns1consultarSaldoPreliminarRequest.idssn.idSistema           = "17"

        CALL consultarSaldoPreliminar_g() RETURNING wsstatus_saldos

        DISPLAY "anhoVencimiento: :            ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.anhoVencimiento
        DISPLAY "apellidoMaterno:              ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.apellidoMaterno
        DISPLAY "apellidoPaterno:              ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.apellidoPaterno
        DISPLAY "curp:                         ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.curp
        DISPLAY "curpRegistrada:               ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.curpRegistrada
        DISPLAY "cveAfore:                     ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.cveAfore
        DISPLAY "cveInstitutoOrigen:           ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.cveInstitutoOrigen
        DISPLAY "descripcion:                  ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcion
        DISPLAY "descripcionDiagnostico:       ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcionDiagnostico
        DISPLAY "diagnostico:                  ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.diagnostico
        DISPLAY "estatusCuentaIndividual:      ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.estatusCuentaIndividual
        DISPLAY "estatusViviendaF:             ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.estatusViviendaF
        DISPLAY "estatusViviendaI:             ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.estatusViviendaI
        DISPLAY "folioSolicitud:               ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.folioSolicitud
        DISPLAY "nombre:                       ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.nombre
        DISPLAY "nss:                          ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.nss
        DISPLAY "resultado:                    ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.resultado
        DISPLAY "rfc:                          ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.rfc
        DISPLAY "saldoAhorroRetiroIB:          ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAhorroRetiroIB
        DISPLAY "saldoAhorroSolidario:         ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAhorroSolidario
        DISPLAY "saldoAportaCompRetiro:        ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAportaCompRetiro
        DISPLAY "saldoAportaLargoPlazo:        ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAportaLargoPlazo
        DISPLAY "saldoAportacionesVoluntarias: ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAportacionesVoluntarias
        DISPLAY "saldoBonoMonto:               ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoBonoMonto
        DISPLAY "saldoCVI:                     ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCVI
        DISPLAY "saldoCesantiaVejez:           ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCesantiaVejez
        DISPLAY "saldoCuotaSocial:             ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCuotaSocial
        DISPLAY "saldoCuotaSocialI:            ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCuotaSocialI
        DISPLAY "saldoFI08:                    ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoFI08
        DISPLAY "saldoFI08AIVS:                ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoFI08AIVS
        DISPLAY "saldoRetiro92I:               ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoRetiro92I
        DISPLAY "saldoRetiro97:                ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoRetiro97
        DISPLAY "saldoRetiroI08:               ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoRetiroI08
        DISPLAY "saldoSar92:                   ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoSar92
        DISPLAY "saldoVivienda92:              ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda92
        DISPLAY "saldoVivienda92AIVS:          ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda92AIVS
        DISPLAY "saldoVivienda97:              ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda97
        DISPLAY "saldoVivienda97AIVS:          ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda97AIVS
        DISPLAY "saldoViviendaFI92:            ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoViviendaFI92
        DISPLAY "saldoViviendaFI92AIVS:        ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoViviendaFI92AIVS

            LET SQL1 = " SELECT NVL(MAX(id_consulta), 0 ) + 1",
                       "   FROM cei_bit_saldos_pre"
            PREPARE select_max_cei_bit_saldos_pre FROM SQL1
            EXECUTE select_max_cei_bit_saldos_pre INTO lid_consulta_saldos

            LET SQL1 = " INSERT INTO cei_bit_saldos_pre(",
                                                        " id_consulta,",
                                                        " nss,",
                                                        " curp,",
                                                        " cveinstitutoorigen,",
                                                        " cveafore,",
                                                        " nombre,",
                                                        " apellidopaterno,",
                                                        " apellidomaterno,",
                                                        " rfc,",
                                                        " curpregistrada,",
                                                        " saldosar92,",
                                                        " saldoretiro97,",
                                                        " saldocuotasocial,",
                                                        " saldocesantiavejez,",
                                                        " saldovivienda97,",
                                                        " saldovivienda97aivs,",
                                                        " saldovivienda92,",
                                                        " saldovivienda92aivs,",
                                                        " saldoahorroretiroib,",
                                                        " saldoaportacionesvoluntarias,",
                                                        " saldoretiro92i,",
                                                        " saldoaportacompretiro,",
                                                        " saldoviviendafi92,",
                                                        " saldoviviendafi92aivs,",
                                                        " saldoaportalargoplazo,",
                                                        " saldofi08,",
                                                        " saldofi08aivs,",
                                                        " saldoretiroi08,",
                                                        " saldocvi,",
                                                        " saldoahorrosolidario,",
                                                        " saldocuotasociali,",
                                                        " saldobonomonto,",
                                                        " anhovencimiento,",
                                                        " estatuscuentaindividual,",
                                                        " estatusviviendai,",
                                                        " estatusviviendaf,",
                                                        " diagnostico,",
                                                        " descripciondiagnostico,",
                                                        " foliosolicitud,",
                                                        " resultado,",
                                                        " descripcion,",
                                                        " fecha_consulta",
                                                        ")",
                                              " VALUES (",
                                                           lid_consulta_saldos,
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.nss, "'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.curp,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.cveInstitutoOrigen,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.cveAfore,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.nombre,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.apellidoPaterno,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.apellidoMaterno,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.rfc,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.curpRegistrada,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoSar92,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoRetiro97,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCuotaSocial,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCesantiaVejez,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda97,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda97AIVS,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda92,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoVivienda92AIVS,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAhorroRetiroIB,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAportacionesVoluntarias,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoRetiro92I,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAportaCompRetiro,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoViviendaFI92,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoViviendaFI92AIVS,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAportaLargoPlazo,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoFI08,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoFI08AIVS,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoRetiroI08,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCVI,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoAhorroSolidario,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoCuotaSocialI,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.saldoBonoMonto,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.anhoVencimiento,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.estatusCuentaIndividual,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.estatusViviendaI,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.estatusViviendaF,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.diagnostico,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcionDiagnostico,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.folioSolicitud,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.resultado,"'",
                                                        " , '", ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcion,"'",
                                                        " , '", TODAY,"'",
                                                      ")"
            PREPARE insert_cie_bit_saldos FROM SQL1

            LET rcei_td_wspensiones_dictamen.codigo_resultado = ns1consultarSaldoPreliminarResponse.objetoRespuesta.resultado
            LET rcei_td_wspensiones_dictamen.dictamen         = saldos_descripcionDiagnostico
            LET rcei_td_wspensiones_dictamen.fecha_respuesta  = CURRENT YEAR TO SECOND
            LET rcei_td_wspensiones_dictamen.folio_solicitud  = r_wsEntrada.folio_solicitud
            LET rcei_td_wspensiones_dictamen.motivo_rechazo   = ns1consultarSaldoPreliminarResponse.objetoRespuesta.diagnostico
            LET rcei_td_wspensiones_dictamen.observaciones    = ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcion, ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcionDiagnostico

            IF wsstatus_saldos <> 0 THEN
                LET r_wsSalida.codigo_resultado = "10" --30
                LET r_wsSalida.observaciones  = "El servicio de Saldos Preliminares esta tardando mas de lo esperado intente mas tarde por favor."
                INSERT INTO cei_td_wspensiones_dictamen VALUES(rcei_td_wspensiones_dictamen.*)
                DISCONNECT CURRENT
                RETURN r_wsSalida
            END IF

            IF ns1consultarSaldoPreliminarResponse.objetoRespuesta.resultado = "01" THEN
                EXECUTE insert_cie_bit_saldos
                ###################
                ## INICIO
                ## Genera PROSPECTOS
                ##
                ###################
                    CALL archivos_CNSFws7.generarProspectosBeneficiarios(lDirecto.num_issste, r_wsEntrada.tiempo_cotizado_issste, r_wsEntrada.tiempo_cotizado_imss, r_wsEntrada.salario_prom_hl)
                ###################
                ## FIN
                ## Genera PROSPECTOS
                ##
                ###################
            END IF

        ######################
        ## FIN
        ## SALDOS PRELIMINAR
        ##
        ######################

        IF ns1consultarSaldoPreliminarResponse.objetoRespuesta.resultado = "02" THEN
            LET r_wsSalida.codigo_resultado = "20" --10
            LET r_wsSalida.derecho_pension = "N"
            LET r_wsSalida.observaciones   = "Saldos Preliminares - ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.diagnostico, " - ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcion," ", ns1consultarSaldoPreliminarResponse.objetoRespuesta.descripcionDiagnostico
            INSERT INTO cei_td_wspensiones_dictamen VALUES(rcei_td_wspensiones_dictamen.*)
            DISCONNECT CURRENT
            RETURN r_wsSalida
        END IF

        IF ns1consultarSaldoPreliminarResponse.objetoRespuesta.resultado = "01" THEN

            LOCATE ltext IN MEMORY
            CALL ltext.readFile("Beneficiarios_ISSSTE.txt")
            LET lBeneficiarios = ltext
            LOCATE ltext IN MEMORY
            CALL ltext.readFile("Prospectos_ISSSTE.txt")
            LET lProspecto     = ltext
            LET lPassword      = "t4ecAPR$gEtr"
            LET lProceso       = 1
            LET lUsuario       = "issste_ws"

            CALL WS_SAOR_ISSSTE(lUsuario, lPassword, lProceso, lProspecto, lBeneficiarios) RETURNING wsstatus_cnsf, lRespuesta

            IF wsstatus_cnsf <> 0 THEN
                LET r_wsSalida.codigo_resultado = "30" --20
                LET r_wsSalida.derecho_pension = "N"
                LET r_wsSalida.cve_beneficio = 99
                
                LET rcei_td_wspensiones_dictamen.codigo_resultado = "02"
                LET r_wsSalida.observaciones = lRespuesta
                INSERT INTO cei_td_wspensiones_dictamen VALUES(rcei_td_wspensiones_dictamen.*)
                DISCONNECT CURRENT
                RETURN r_wsSalida
            END IF

            IF lRespuesta.subString(1,3) = "000" THEN
                LET r_wsSalida.cve_beneficio   = 1
                LET r_wsSalida.derecho_pension = "S"
                LET r_wsSalida.desc_beneficio  = "RETIRO ANTICIPADO"
                LET r_wsSalida.codigo_resultado = "01"
                
                LET rcei_td_wspensiones_dictamen.dictamen         = r_wsSalida.desc_beneficio
                LET rcei_td_wspensiones_dictamen.codigo_resultado = "01"
            ELSE
                LET rcei_td_wspensiones_dictamen.codigo_resultado = "02"
                
                LET r_wsSalida.cve_beneficio   = 0
                LET r_wsSalida.derecho_pension = "N"
                LET r_wsSalida.desc_beneficio  = "SIN DERECHO"
                LET r_wsSalida.codigo_resultado = "40"

                 LET SQL1 = " SELECT concepto",
                            "   FROM cei_cat_cnsf_prospectos",
                            "  WHERE diagnostico = '", lRespuesta.subString(1,3),"'"
                 PREPARE select_diagnostico_cnsf FROM SQL1
                 EXECUTE select_diagnostico_cnsf INTO r_wsSalida.observaciones
                
                LET r_wsSalida.observaciones = "CNSF - ", r_wsSalida.observaciones
                LET rcei_td_wspensiones_dictamen.motivo_rechazo   = lRespuesta
                LET rcei_td_wspensiones_dictamen.dictamen         = r_wsSalida.desc_beneficio
            END IF

            INSERT INTO cei_td_wspensiones_dictamen VALUES(rcei_td_wspensiones_dictamen.*)
        END IF
    ELSE --mayor de 60
        DISPLAY "$$$$$$$$$$$$$$$$$$$$$$$$"
        DISPLAY "DICTAMINACION"
        DISPLAY "EDAD: ", ledad
        DISPLAY "TIEMPO COT", ltiempo_cot
        
        IF ltiempo_cot >= 25 THEN 
            IF ledad <= 64 THEN
                LET r_wsSalida.cve_beneficio   = 2
                LET r_wsSalida.derecho_pension = "S"
                LET r_wsSalida.desc_beneficio  = "CESANTIA EN EDAD AVANZADA"
                LET r_wsSalida.codigo_resultado = "01"
            ELSE --mayores de 60 aÃ±os de edad pero menores de 25 aÃ±os cotizado
                LET r_wsSalida.cve_beneficio   = 3
                LET r_wsSalida.derecho_pension = "S"
                LET r_wsSalida.desc_beneficio  = "VEJEZ"
                LET r_wsSalida.codigo_resultado = "01"
            END IF
        ELSE
            LET r_wsSalida.cve_beneficio   = 0
            LET r_wsSalida.derecho_pension = "N"
            LET r_wsSalida.desc_beneficio  = "SIN DERECHO"
            LET r_wsSalida.codigo_resultado = "50"
            LET r_wsSalida.observaciones = "EDAD - ", ledad, " - Tiempo Cotizado ", ltiempo_cot, " años"
        END IF
    END IF
    DISCONNECT CURRENT
    RETURN r_wsSalida
END FUNCTION

FUNCTION fnObtieneFechaNacRENAPO(lCURP)
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
    DEFINE ledad INTEGER
    
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

    LET ledad = obtener_edad(lrCurp.fecha_nacimiento)

    RETURN ledad
END FUNCTION

FUNCTION obtener_edad(fecha_nacimiento DATE)
    DEFINE fecha_actual DATE
    DEFINE edad INTEGER
 
    LET fecha_actual = TODAY
    LET edad = YEAR(fecha_actual) - YEAR(fecha_nacimiento)
 
    -- Ajustar si aún no ha cumplido años en el año actual
    IF MONTH(fecha_nacimiento) > MONTH(fecha_actual) OR
       (MONTH(fecha_nacimiento) = MONTH(fecha_actual) AND DAY(fecha_nacimiento) > DAY(fecha_actual)) THEN
        LET edad = edad - 1
    END IF
 
    RETURN edad
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
               "    AND (c_modalidad.pensiones   = 'T')", --WS7 dias_cot --- NO se ocupa
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

     RETURN anios, meses, dias
     
  
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