SCHEMA dsipe


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


FUNCTION validacionesIniciales(lnum_issste, lCURP)
    DEFINE lnum_issste  DECIMAL(8,0)
    DEFINE lCURP        STRING

    DEFINE SQL1         STRING
    DEFINE validacion   INTEGER
    
    
    DEFINE cmd          STRING
    
    DEFINE dto_estado   STRING
    DEFINE fecha_baja   DATE

    DEFINE luso_pen         INTEGER
    
    DEFINE fecha_inicio     DATE
    DEFINE fecha_termino    DATE
    
    DEFINE arrFechas      DYNAMIC ARRAY OF RECORD
        fecha_inicio     DATE,
        fecha_termino    DATE
    END RECORD

    

    

    
    DEFINE idx           INTEGER
    DEFINE idxj          INTEGER

    DEFINE uso_pen         INTEGER
    DEFINE bndUsoPenIG     SMALLINT
    DEFINE lcontar         INTEGER
    DEFINE t_movto_cierre STRING
    DEFINE cmdrun         STRING

    LET validacion = 0



    --Proceso para obtener la sentencia


    IF validacion = 0 THEN
        CALL FGL_WINMESSAGE("Rastreo de Portabilidad","Validacion pensionario directo, ¿De donde se obtiene este dato?","information")
    END IF
    --presenta beneficio pensionario directo --cat_marcas_hl
    --RESULTADO DEL MODULO DE PENSION
--    IF validacion = 0 THEN
--        LET SQL1 = " SELECT COUNT(*)",
--                   "   FROM pension",
--                   "  WHERE num_issste = ", lnum_issste
--        PREPARE select_datos_penbeneficiopen FROM SQL1
--        EXECUTE select_datos_penbeneficiopen INTO luso_pen
--
--        IF lDatospen.vigencia = 0 THEN
--            LET validacion = 8
--        END IF
--    END IF

    -- Mismo ramo-pagaduria
    IF validacion = 0 THEN
        LET luso_pen = 0
        
    END IF

    --Antiguedad >=1 dia al fondo de pensiones
    IF validacion = 0 THEN
        LET fecha_inicio = NULL
        LET fecha_termino = NULL
        LET SQL1 = " SELECT fecha_inicio, fecha_termino",
                   "   FROM cuenta_ind",
                   "  WHERE num_issste = ", lnum_issste
        PREPARE select_antiguedadfondopensiones FROM SQL1
        DECLARE curfondoPensiones CURSOR FOR select_antiguedadfondopensiones
        FOREACH curfondoPensiones INTO fecha_inicio, fecha_termino
            IF fecha_inicio = fecha_termino THEN
                LET validacion = 16
                EXIT FOREACH
            END IF
            
            IF fecha_inicio > fecha_termino THEN
                LET validacion = 16
                EXIT FOREACH
            END IF

            IF fecha_inicio IS NULL OR fecha_termino IS NULL THEN   
                LET validacion = 16
                EXIT FOREACH
            END IF
            IF (fecha_termino - fecha_inicio) < 1 THEN
                LET validacion = 16
                EXIT FOREACH
            END IF
        END FOREACH
        RETURN 16
    END IF

    IF validacion = 0 THEN
        CALL FGL_WINMESSAGE("Rastreo de Portabilidad","valida ¿Tiene registro de bono de pensión o su fecha de ingreso es posterior al 31/03/2007 sin HL previa?, validar si todo esto aplica","information")
    END IF
    -- ¿Tiene registro de bono de pensión o su fecha de ingreso es posterior al 31/03/2007 sin HL previa?
    {IF validacion = 0 THEN
        LET lcontar = 0
        LET SQL1 = " SELECT COUNT(*)",
                   "   FROM eleccion",
                   " WHERE num_issste = ", lnum_issste
        PREPARE select_eleccion FROM SQL1
        EXECUTE select_eleccion INTO luso_pen

        IF luso_pen = 0 THEN
            LET validacion = 18
        END IF
    END IF

    IF validacion = 0 THEN
        LET lcontar = 0
        LET SQL1 = " SELECT COUNT(*)",
                   "   FROM directo",
                   "  WHERE num_issste = ", lnum_issste,
                   "    AND fecha_alta >= '31/03/2007'",
                   "    AND dto_estado = 'A'"
        PREPARE select_ingresoposteriorfechaybono FROM SQL1
        EXECUTE select_ingresoposteriorfechaybono INTO lcontar

        IF lcontar > 0 THEN
            LET lcontar = 0
            LET SQL1 = " SELECT COUNT(*)",
                       "   FROM cuenta_ind",
                       "  WHERE num_issste = ", lnum_issste,
                       "    AND fecha_inicio < '31/03/2007'"
            PREPARE select_conta_HL FROM SQL1
            EXECUTE select_conta_HL INTO lcontar
        END IF

        IF lcontar > 0 THEN
            LET SQL1 = " SELECT fecha_inicio, fecha_termino, t_movto_inicio",
                       "   FROM cuenta_ind",
                       "  WHERE num_issste = ", lnum_issste,
                       "    AND t_movto_inicio = 'R'"
            PREPARE select_anio_anterior_reingreso FROM SQL1
            DECLARE curanioAnteriorREeingreso CURSOR FOR select_anio_anterior_reingreso
            FOREACH curanioAnteriorREeingreso INTO fecha_inicio, fecha_termino, t_movto_cierre
                IF (fecha_termino+365) < 365 THEN
                    LET validacion = 18
                END IF
            END FOREACH
        ELSE
            LET validacion = 18
        END IF
    END IF}

    RETURN 0
END FUNCTION
