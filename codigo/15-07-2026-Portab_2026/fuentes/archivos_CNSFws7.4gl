SCHEMA "dsipe"

   DEFINE reg_pros RECORD # lista de datos de prospectos
        fecha_alta DATE,
        fecha_elaboracion DATE,
        tipo_registro SMALLINT,
        nombre_asegurado VARCHAR(60),
        num_issste DECIMAL(11,0),
        num_solicitud SMALLINT,
        fecha_nacimiento DATE,
        sexo CHAR,
        curp VARCHAR(18),
        delegacion SMALLINT,
        fecha_ini_pagos DATE,
        fecha_ini_derechos DATE,
        pip DECIMAL(5,2),
        ramo VARCHAR(2),
        tipo VARCHAR(2),
        sal_diario_rt DECIMAL(13,2),
        sal_diario_iv DECIMAL(13,2),
        ctia_basica_pension DECIMAL(13,2),
        imp_mensual_pension DECIMAL(13,2),
        nombre_solicitante VARCHAR(60),
        fecha_solicitud DATE,
        domicilio VARCHAR(60),
        fecha_proceso DATE,
        folio_id VARCHAR(11),
        pmg_imsss DECIMAL(13,2),
        saldo_cuenta_ind DECIMAL(13,2),
        saldo_sar DECIMAL(13,2),
        saldo_fovissste DECIMAL(13,2),
        saldo_aportaciones_vol DECIMAL(13,2),
        portabilidad CHAR,
        antiguedad SMALLINT,
        anios_cotizados SMALLINT,
        tipo_regimen CHAR,
        tasa_postura DECIMAL(5,2),
        cambio_modalidad CHAR,
        modalidad VARCHAR(2),
        subdeleg SMALLINT,
        fec_oferta DATE
    END RECORD
    DEFINE ls_band_portabilidad SMALLINT
    DEFINE lrecdirecto RECORD LIKE directo.*
    DEFINE ext RECORD
        por_ext VARCHAR(5),
        por_ext_MCTT VARCHAR (1),
        codigo_tabla VARCHAR(3),
        mtl_CV  SMALLINT,
        vejez_derivada CHAR(1)
    END RECORD
    DEFINE ld_salario_prom_hl DECIMAL(13,2)
    DEFINE nom_archivo,nom_archivo_b STRING
    DEFINE pre_pros, benef base.Channel
    DEFINE list_benef_pros DYNAMIC ARRAY OF RECORD
        num_issste DECIMAL(11,0),       
        num_solicitud SMALLINT,
        nombre VARCHAR(60),
        parentesco VARCHAR(2),
        sexo CHAR,
        fecha_nacimiento DATE,
        fecha_ini_derechos DATE,
        fecha_vencimiento DATE,
        orfandad CHAR,
        fecha_ini_pagos DATE,
        folio_id VARCHAR(11),
        benefi DECIMAL(11,0) -- LMLC 31/08/2015
    END RECORD
    DEFINE n_issste_benef INTEGER
    DEFINE listBenef DYNAMIC ARRAY OF RECORD
        beneficiario STRING
    END RECORD
    DEFINE cont INTEGER
    DEFINE antiguedad_cotizante INTEGER
    
FUNCTION generarProspectosBeneficiarios(lintNumISSSTE, ltiempo_issste, ltiempo_imss, lmonto)
    DEFINE lintNumISSSTE DECIMAL(10,2)
    DEFINE ltiempo_issste INTEGER
    DEFINE ltiempo_imss INTEGER
    DEFINE lmonto DECIMAL(10)
        CALL obtieneDatosDirectos(lintNumISSSTE)
        LET ls_band_portabilidad =1

        --CALL dias_cot1(lintNumISSSTE) RETURNING antiguedad_cotizante
        LET antiguedad_cotizante = ltiempo_issste
        DISPLAY "######################################"
        DISPLAY "######################################"
        DISPLAY "######################################"
        DISPLAY "ARCHIVOS CNSF"
        DISPLAY "DIAS COTIZADOS ISSSTE: ", antiguedad_cotizante
        DISPLAY "DIAS COTIZADOS IMSS: ", ltiempo_imss
        
        # 1 Fecha de alta en la BD
        LET reg_pros.fecha_alta = TODAY

        # 2 Fecha de elaboracion
        LET reg_pros.fecha_elaboracion = TODAY

        # 3 Tipo de registro
        LET reg_pros.tipo_registro = 1

        # 4 Nombre del directo
        LET reg_pros.nombre_asegurado = lrecdirecto.apellido_paterno CLIPPED ," ",lrecdirecto.apellido_materno CLIPPED ," ",lrecdirecto.nombre CLIPPED
                                                        
        # 5 Numero ISSSTE
        LET reg_pros.num_issste=lintNumISSSTE
                        
        # 6 Numero de solicitud
        LET reg_pros.num_solicitud = validar_num_solicitud()

        # 7 Fecha de Nacimiento
        LET reg_pros.fecha_nacimiento = lrecdirecto.fec_nac

        # 8 Sexo
        IF lrecdirecto.sexo="H" THEN
            LET  reg_pros.sexo="M"
        ELSE
            LET  reg_pros.sexo="F"
        END IF

        # 9 CURP
        LET reg_pros.curp = lrecdirecto.curp

        # 10 Delegacion
        LET reg_pros.delegacion = 01

        # 11 Fecha de inicio de pagos
        LET reg_pros.fecha_ini_pagos = NULL

        #12 Fecha de inicio de derechos 
        LET reg_pros.fecha_ini_derechos=TODAY
        LET reg_pros.fecha_ini_pagos=TODAY

        # 13 PIP
        LET reg_pros.pip = 0.00

        # 14 Ramo
        LET reg_pros.ramo = "RA"

        # 15 Tipo
        LET reg_pros.tipo = "RA"

        # 16 Salario diario RT
        LET reg_pros.sal_diario_rt = 0.00

        # 17 Salario diario IV
        LET reg_pros.sal_diario_iv = 0.00

        # 18 Cuantia Basica de la pension
        LET reg_pros.ctia_basica_pension = 0.00 

        # 19 Importe mensual
        LET reg_pros.imp_mensual_pension = 0.00

        # 20 Nombre del solicitante
        LET reg_pros.nombre_solicitante = reg_pros.nombre_asegurado

        # 21 Fecha de la solicitud
        LET reg_pros.fecha_solicitud = TODAY

        # 22 Domicilio
        LET reg_pros.domicilio =  obtener_domicilio(lintNumISSSTE)

        # 23 Fecha de proceso
        LET reg_pros.fecha_proceso = TODAY

        # 24 Folio indentificador
        LET reg_pros.folio_id = NULL 

        # 25 PMG IMSSS
        LET reg_pros.pmg_imsss = 0.00

        # 26 Saldo Cuenta individual
        LET reg_pros.saldo_cuenta_ind = 0.00
        
        # 27 Saldo SAR
        # 28 Saldo FOVISSSTE
        # 29 Saldo de aportaciones voluntarias
        CALL obtener_saldos(reg_pros.num_issste,ls_band_portabilidad ) 
                                RETURNING reg_pros.saldo_sar,
                                          reg_pros.saldo_fovissste,
                                          reg_pros.saldo_aportaciones_vol,
                                          reg_pros.saldo_cuenta_ind	

        ##Quitar comentario cuando ya se tenga la bitacora cei_bit_saldos_pre funcionando
        #CALL obtener_saldos_sp(reg_pros.curp,ls_band_portabilidad) RETURNING reg_pros.saldo_sar,
        #                                  reg_pros.saldo_fovissste,
        #                                  reg_pros.saldo_aportaciones_vol,
        #                                  reg_pros.saldo_cuenta_ind	
                                          
         # 30 Portabilidad                                 
        IF ls_band_portabilidad THEN
            LET reg_pros.portabilidad = "S"
        ELSE
            LET reg_pros.portabilidad = "N"
        END IF 

        DISPLAY "######################################"
        DISPLAY "######################################"
        DISPLAY "######################################"
        DISPLAY "ARCHIVOS CNSF"
        DISPLAY "AÑOS COTIZADOS ISSSTE: ", fnObtieneanios(antiguedad_cotizante)
        DISPLAY "AÑOS COTIZADOS IMSS: ", fnObtieneanios(ltiempo_imss)
        # 31 Antiguedad 
        LET reg_pros.antiguedad=fnObtieneanios(ltiempo_issste)+fnObtieneanios(ltiempo_imss) --ARG_VAL(2) 
        
        # 32 Años reconocidos 
        LET reg_pros.anios_cotizados=fnObtieneanios(antiguedad_cotizante)--ARG_VAL(3)

        # 33 Tipo de regimen
        LET reg_pros.tipo_regimen = "S"

        # 34 Tasa de postura
        LET reg_pros.tasa_postura = tasaSubasta()

        # 35 Cambio de modalidad
        LET reg_pros.cambio_modalidad = NULL

        # 36 Modalidad
        LET reg_pros.modalidad = NULL

        # 37 Subdelegacion
        LET reg_pros.subdeleg = 999
                        
        # 38 Fecha Oferta
        LET reg_pros.fec_oferta=NULL

        # 39 Porcentaje del excedente a utilizar
        LET ext.por_ext=null    

        # 40 Porcentaje del excedente para MCTT
        LET ext.por_ext_MCTT=null

        # 41 Codigo de tablas a usar
        LET ext.codigo_tabla=NULL

        # 42 Mortalidad para CV
        LET ext.mtl_CV=1

        # 43 Pension de vejez derivada
        LET ext.vejez_derivada = ''

        # 44 Salario Promedio
        LET ld_salario_prom_hl = lmonto --ARG_VAL(4)

        LET pre_pros = base.Channel.create()
        LET benef = base.Channel.create()
        LET nom_archivo   = "Prospectos_ISSSTE.txt"
        LET nom_archivo_b = "Beneficiarios_ISSSTE.txt"
        CALL pre_pros.openFile(nom_archivo,"w")
        CALL benef.openFile(nom_archivo_b,"w")  
        CALL pre_pros.writeLine(formato_prospectos(reg_pros.*,ext.*, ld_salario_prom_hl)) 
        CALL pre_pros.close()

        ##Obtenemos Beneficiarios
        CALL list_benef_pros.clear() 
        CALL obtener_beneficiarios_pros("1",TODAY,reg_pros.num_issste,reg_pros.num_solicitud,reg_pros.fecha_ini_derechos,
                                        reg_pros.fecha_ini_pagos,reg_pros.folio_id,list_benef_pros)
                                        
        IF list_benef_pros.getLength() IS NOT NULL AND list_benef_pros.getLength()>0 THEN
            CALL beneficiarios_pros1(list_benef_pros, 'D')
        END IF
        CALL benef.close()
        CALL pre_pros.openFile("Prospectos_ISSSTE_sep.txt","w")
        CALL pre_pros.writeLine(formato_prospectos_pipe(reg_pros.*,ext.*, ld_salario_prom_hl))
        DISPLAY formato_prospectos_pipe(reg_pros.*,ext.*, ld_salario_prom_hl)
        CALL pre_pros.close()
        CALL benef.openFile("Beneficiarios_ISSSTE_sep.txt","w")
        FOR cont=1 TO listBenef.getLength() 
            CALL benef.writeLine(listBenef[cont].*)
            DISPLAY listBenef[cont].*
        END FOR 
        CALL benef.close()
END FUNCTION

--Obtiene Datos del directo
FUNCTION obtieneDatosDirectos(lintNumISSSTE)
    DEFINE lintNumISSSTE INTEGER
    DEFINE lstrDatosDirecto STRING
    LET lstrDatosDirecto="select * from directo where num_issste = ", lintNumISSSTE
    TRY
        PREPARE preDatosDirecto FROM lstrDatosDirecto
        EXECUTE preDatosDirecto INTO lrecdirecto.*
        FREE preDatosDirecto
    CATCH
    END TRY
END FUNCTION

--Valida numero de solicitud
FUNCTION validar_num_solicitud()
    DEFINE lintNumISSSTE INTEGER
    DEFINE n_solicitud SMALLINT
    DEFINE SQL1 STRING
    LET SQL1 = " SELECT MAX(num_solicitud )",
               "   FROM prospectos_ci",
               "  WHERE num_issste = ", lintNumISSSTE
    PREPARE select_max_prospectos FROM SQL1
    EXECUTE select_max_prospectos INTO n_solicitud

    IF n_solicitud <=0 OR n_solicitud IS NULL THEN
        LET n_solicitud = 1
    ELSE
        LET n_solicitud = n_solicitud + 1
    END IF
    RETURN n_solicitud
END FUNCTION

--Obtener domicilio
FUNCTION obtener_domicilio(n_issste)
    DEFINE n_issste INTEGER
    DEFINE domicilio VARCHAR(100)
    DEFINE calle            LIKe directo.calle,
           num_exterior     LIKe directo.num_exterior,
           num_interior     LIKe directo.num_interior,
           poblacion        LIKE directo.poblacion,
           codigo_postal    LIKE directo.codigo_postal,
           colonia          LIKE c_nom_colonia.nombre
    
    SELECT  nvl(c_nom_colonia.nombre,''),
            nvl(directo.calle,''),
            nvl(directo.num_exterior,''),
            nvl(directo.num_interior,''),
            nvl(directo.poblacion,''),
            nvl(directo.codigo_postal,'')
    INTO colonia,calle,num_exterior,num_interior,poblacion,codigo_postal 
    FROM directo INNER JOIN c_nom_colonia ON directo.nco_cve=c_nom_colonia.nco_cve 
    WHERE directo.num_issste=n_issste
    LET domicilio ="Calle "||calle CLIPPED||
                  " No. Ext. "||num_exterior CLIPPED||
                  " Num. Int. "||num_interior CLIPPED||
                  "col.  "||colonia CLIPPED||
                  ", "||poblacion CLIPPED||" C.P. "||codigo_postal CLIPPED
    RETURN domicilio
END FUNCTION


--Se obtiene los saldos previos
FUNCTION obtener_saldos(n_issste,ls_band_portabilidad )-- INFOTEC TK - 2023052997
    DEFINE n_issste DECIMAL(11,0)
    DEFINE sal_n_rt_iste08,sal_n_cv_iste,sal_n_cs_iste,sal_n_ah_sol,sal_n_bono,sal_sar, sal_fovissste, sal_aportaciones, sal_cta_ind, sal_n_cv_cee, sal_n_cs, sal_n_viv97_imss DECIMAL(13,2) -- INFOTEC TK-2023052997
	DEFINE ls_band_portabilidad SMALLINT -- INFOTEC TK - 2023052997
    DEFINE lc_sql STRING 
    SET ISOLATION TO DIRTY READ 

    LET lc_sql = " select n_rt_iste08,n_cv_iste,n_cs_iste,n_ah_sol,n_bono,n_foviste08, n_rt97, n_av, n_cs, n_cv_cee, n_viv97_imss 
                   from rtpspi where n_num_sol in ((select max(n_num_sol) from rtpspi where n_numissste= ?)) and n_numissste= ?"
                
    PREPARE cursel09 FROM lc_sql 
    EXECUTE cursel09 USING n_issste,n_issste INTO sal_n_rt_iste08,sal_n_cv_iste,sal_n_cs_iste,sal_n_ah_sol,sal_n_bono,sal_fovissste, sal_sar, sal_aportaciones, 
						   sal_n_cs, sal_n_cv_cee, sal_n_viv97_imss -- INFOTEC TK-2023052997


    LET sal_cta_ind = sal_n_rt_iste08 + 
                      sal_n_cv_iste +
                      sal_n_cs_iste +
                      sal_n_ah_sol +
                      sal_n_bono +
                      sal_fovissste
				  
	IF ls_band_portabilidad THEN
		LET sal_cta_ind = sal_cta_ind +
						  sal_sar +
						  sal_n_cs +
						  sal_n_cv_cee +
						  sal_n_viv97_imss
	END IF  
					 
    DISPLAY "SALDOS",sal_sar," fov", sal_fovissste," aport", sal_aportaciones," cta_ind", sal_cta_ind
    RETURN sal_sar, sal_fovissste, sal_aportaciones, sal_cta_ind
END FUNCTION

--Se obtiene los saldos previos del servicio
FUNCTION obtener_saldos_sp(lvarcurp,ls_band_portabilidad )
    DEFINE lvarcurp VARCHAR(18)
    DEFINE sal_n_rt_iste08,sal_n_cv_iste,sal_n_cs_iste,sal_n_ah_sol,sal_n_bono,sal_sar, sal_fovissste, sal_aportaciones, sal_cta_ind, sal_n_cv_cee, sal_n_cs, sal_n_viv97_imss DECIMAL(13,2) -- INFOTEC TK-2023052997
	DEFINE ls_band_portabilidad SMALLINT -- INFOTEC TK - 2023052997
    DEFINE lc_sql STRING 
    SET ISOLATION TO DIRTY READ 

    LET lc_sql = " select SaldoRetiroI08,SaldoCVI,SaldoCuotaSocialI,SaldoAhorroSolidario,SaldoBonoMonto,SaldoFI08,SaldoRetiro97,SaldoAportacionesVoluntarias,
                   SaldoCuotaSocial,SaldoCesantiaVejez,saldoVivienda97
                   from cei_bit_saldos_pre where id_consulta in ((select max(id_consulta) from cei_bit_saldos_pre where curp= ?)) and curp= ?"
                
    PREPARE cursel10 FROM lc_sql 
    EXECUTE cursel10 USING lvarcurp,lvarcurp INTO sal_n_rt_iste08,sal_n_cv_iste,sal_n_cs_iste,sal_n_ah_sol,sal_n_bono,sal_fovissste, sal_sar, sal_aportaciones, 
						   sal_n_cs, sal_n_cv_cee, sal_n_viv97_imss

    LET sal_cta_ind = sal_n_rt_iste08 + 
                      sal_n_cv_iste +
                      sal_n_cs_iste +
                      sal_n_ah_sol +
                      sal_n_bono +
                      sal_fovissste
				  
	IF ls_band_portabilidad THEN
		LET sal_cta_ind = sal_cta_ind +
						  sal_sar +
						  sal_n_cs +
						  sal_n_cv_cee +
						  sal_n_viv97_imss
	END IF  
					 
    DISPLAY "SALDOS",sal_sar," fov", sal_fovissste," aport", sal_aportaciones," cta_ind", sal_cta_ind
    RETURN sal_sar, sal_fovissste, sal_aportaciones, sal_cta_ind
END FUNCTION


# *************************************************************************************************
# Nombre_funcion		formato_prospectos
# Nombre del equipo		ALDEBARAN
# Desarrollado_por		Santiago Hern�ndez Boxtho
# Fecha 			    Diciembre/2008
# Ultima_modificacion	Julio/2009
# Descripci�n			Formato de la cadena para integrarlo al lote de prospectos
# Entrada               registro    registro de datos de un prospecto
# Salida                renglon     formato del registro para integrarlo en el lote del prospectos
# **************************************************************************************************
FUNCTION formato_prospectos(reg_pros,ext,ld_salario_prom_hl)
    DEFINE reg_pros RECORD # lista de datos de prospectos
        fecha_alta DATE,
        fecha_elaboracion DATE,
        tipo_registro SMALLINT,
        nombre_asegurado VARCHAR(60),
        num_issste DECIMAL(11,0),
        num_solicitud SMALLINT,
        fecha_nacimiento DATE,
        sexo CHAR,
        curp VARCHAR(18),
        delegacion SMALLINT,
        fecha_ini_pagos DATE,
        fecha_ini_derechos DATE,
        pip DECIMAL(5,2),
        ramo VARCHAR(2),
        tipo VARCHAR(2),
        sal_diario_rt DECIMAL(13,2),
        sal_diario_iv DECIMAL(13,2),
        ctia_basica_pension DECIMAL(13,2),
        imp_mensual_pension DECIMAL(13,2),
        nombre_solicitante VARCHAR(60),
        fecha_solicitud DATE,
        domicilio VARCHAR(60),
        fecha_proceso DATE,
        folio_id VARCHAR(11),
        pmg_imsss DECIMAL(13,2),
        saldo_cuenta_ind DECIMAL(13,2),
        saldo_sar DECIMAL(13,2),
        saldo_fovissste DECIMAL(13,2),
        saldo_aportaciones_vol DECIMAL(13,2),
        portabilidad CHAR,
        antiguedad SMALLINT,
        anios_cotizados SMALLINT,
        tipo_regimen CHAR,
        tasa_postura DECIMAL(5,2),
        cambio_modalidad CHAR,
        modalidad VARCHAR(2),
        subdeleg SMALLINT,
        fec_oferta DATE
    END RECORD

    
     DEFINE ext RECORD
        por_ext VARCHAR(5),
        por_ext_MCTT VARCHAR (1),
        codigo_tabla VARCHAR(3),
        mtl_CV  SMALLINT,
        vejez_derivada CHAR(1)
    END RECORD
    
    DEFINE renglon STRING
	DEFINE ld_salario_prom_hl DECIMAL(13,2) -- INFOTEC TK - 2023052997
    
        # 1 Fecha de alta en la BD
    LET renglon = fechaTOstr(reg_pros.fecha_alta)
    
        # 2 Fecha de elaboralcion
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_elaboracion)  
    
        # 3 Tipo de registro
    LET renglon = renglon || completar_cadena("0",reg_pros.tipo_registro,1)
        
        # 4 Nombre 
    LET renglon = renglon || completar_cadena(" " ,reg_pros.nombre_asegurado ,60)
        
        # 5 N�mero ISSSTE
    LET renglon = renglon || completar_cadena("0" ,reg_pros.num_issste ,11)
        
        # 6 N�mero de solicitud
    LET renglon = renglon || completar_cadena("0" ,reg_pros.num_solicitud ,2)
        
        # 7 Fecha de Nacimiento
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_nacimiento)
        
        # 8 Sexo
    LET renglon = renglon || completar_cadena(" " ,reg_pros.sexo,1)
        
        # 9 CURP
    LET renglon = renglon || completar_cadena(" " ,reg_pros.curp ,18)
        
        # 10 Delegaci�n
    LET renglon = renglon || completar_cadena("0" ,reg_pros.delegacion ,2)
        
        # 11 Fecha de inicio de pagos
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_ini_pagos)
        
        # 12 Fecha de inicio de derechos
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_ini_derechos)
        
        # 13 PIP
    LET renglon = renglon || completar_cadena("0" ,eliminar_punto_dec(reg_pros.pip),5)
        
        # 14 Ramo
    LET renglon = renglon || completar_cadena(" " ,reg_pros.ramo,2)
        
        # 15 Tipo
    LET renglon = renglon || completar_cadena(" " ,reg_pros.tipo,2)
        
        # 16 Salario diario RT
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.sal_diario_rt),13)
        
        # 17 Saldo diario IV
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.sal_diario_iv),13)
        
        # 18 Cuant�a B�sica de la pensi�n
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.ctia_basica_pension),13)
    
        # 19 Importe mensual 
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.imp_mensual_pension),13 )
    
        # 20 Nombre del solicitante
    LET renglon = renglon || completar_cadena(" ",reg_pros.nombre_solicitante,60)
    
        # 21 Fecha de la solicitud
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_solicitud)
    
        # 22 Domicilio
    LET renglon = renglon || completar_cadena(" ",reg_pros.domicilio,60)
    
        # 23 Fecha de proceso
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_proceso)
    
        # 24 Folio indentificador
    LET renglon = renglon || completar_cadena(" ",reg_pros.folio_id,11)
    
        # 25 PMG IMSSS
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.pmg_imsss),13)
    
        # 26 Saldo Cuenta individual
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_cuenta_ind),13)
        
        # 27 Saldo SAR
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_sar),13)
    
        # 28 Saldo FOVISSSTE
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_fovissste),13)
        
        # 29 Saldo de aportaciones voluntarias
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_aportaciones_vol),13)
    
        # 30 Portabilidad
    LET renglon = renglon || completar_cadena(" ",reg_pros.portabilidad,1)
    
        # 31 A�os exclusivos ISSSTE
	LET renglon = renglon || completar_cadena("0",reg_pros.anios_cotizados,2) -- DEFECTO TK-2023052997
    --LET renglon = renglon || completar_cadena("0",reg_pros.antiguedad,2)

        # 32 A�os reconocidos
	LET renglon = renglon || completar_cadena("0",reg_pros.antiguedad,2) -- DEFECTO TK-2023052997
    --LET renglon = renglon || completar_cadena("0",reg_pros.anios_cotizados,2)
    
        # 33 Tipo de r�gimen
    LET renglon = renglon || completar_cadena(" ",reg_pros.tipo_regimen,1)
        
        # 34 Tasa de postura
    LET renglon = renglon || completar_cadena(" ",eliminar_punto_dec(reg_pros.tasa_postura),5)
    
        # 35 Cambio de modalidad 
    LET renglon = renglon || completar_cadena(" ",reg_pros.cambio_modalidad,1)
        
        # 36 Modalidad 
    LET renglon = renglon || completar_cadena(" ",reg_pros.modalidad,2)
    
        # 37 Subdelegaci�n 
    LET renglon = renglon || completar_cadena("0",reg_pros.subdeleg,3)
    
        # 38 Fecha de Oferta
    LET renglon = renglon || fechaTOstr(reg_pros.fec_oferta)

        # 39 Porcentaje del excedente a utilizar
    LET renglon = renglon || completar_cadena(" ",ext.por_ext,5)
        
        # 40 Porcentaje del excedente para MCTT
    LET renglon = renglon || completar_cadena(" ",ext.por_ext_MCTT,1)
        
        # 41 C�digo de tablas a usar
    LET renglon = renglon || completar_cadena(" ",ext.codigo_tabla,3)

        # 42 Mortalidad para CV
    LET renglon = renglon || completar_cadena(" ",ext.mtl_CV,1)

         #43 Pension de vejez derivada
    LET renglon = renglon || completar_cadena(" ",ext.vejez_derivada,1) #LAHA 2014/01/23

		#44 Salario promedio de vida laboral
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(ld_salario_prom_hl),13)  -- INFOTEC TK - 2023052997

--    DISPLAY "# 01 : ",reg_pros.fecha_alta
--    DISPLAY "# 02 : ",reg_pros.fecha_elaboracion
--    DISPLAY "# 03 : ",reg_pros.tipo_registro
--    DISPLAY "# 04 : ",reg_pros.nombre_asegurado
--    DISPLAY "# 05 : ",reg_pros.num_issste
--    DISPLAY "# 06 : ",reg_pros.num_solicitud
--    DISPLAY "# 07 : ",reg_pros.fecha_nacimiento
--    DISPLAY "# 08 : ",reg_pros.sexo
--    DISPLAY "# 09 : ",reg_pros.curp
--    DISPLAY "# 10 : ",reg_pros.delegacion
--    DISPLAY "# 11 : ",reg_pros.fecha_ini_pagos
--    DISPLAY "# 12 : ",reg_pros.fecha_ini_derechos
--    DISPLAY "# 13 : ",reg_pros.pip
--    DISPLAY "# 14 : ",reg_pros.ramo
--    DISPLAY "# 15 : ",reg_pros.tipo
--    DISPLAY "# 16 : ",reg_pros.sal_diario_rt
--    DISPLAY "# 17 : ",reg_pros.sal_diario_iv
--    DISPLAY "# 18 : ",reg_pros.ctia_basica_pension
--    DISPLAY "# 19 : ",reg_pros.imp_mensual_pension
--    DISPLAY "# 20 : ",reg_pros.nombre_solicitante
--    DISPLAY "# 21 : ",reg_pros.fecha_solicitud        
--    DISPLAY "# 22 : ",reg_pros.domicilio
--    DISPLAY "# 23 : ",reg_pros.fecha_proceso
--    DISPLAY "# 24 : ",reg_pros.folio_id
--    DISPLAY "# 25 : ",reg_pros.pmg_imsss
--    DISPLAY "# 26 : ",reg_pros.saldo_cuenta_ind
--    DISPLAY "# 27 : ",reg_pros.saldo_sar
--    DISPLAY "# 28 : ",reg_pros.saldo_fovissste
--    DISPLAY "# 29 : ",reg_pros.saldo_aportaciones_vol
--    DISPLAY "# 30 : ",reg_pros.portabilidad
--    DISPLAY "# 31 : ",reg_pros.antiguedad
--    DISPLAY "# 32 : ",reg_pros.anios_cotizados
--    DISPLAY "# 33 : ",reg_pros.tipo_regimen
--    DISPLAY "# 34 : ",reg_pros.tasa_postura
--    DISPLAY "# 35 : ",reg_pros.cambio_modalidad 
--    DISPLAY "# 36 : ",reg_pros.modalidad
        
    RETURN renglon   
END FUNCTION


FUNCTION fechaTOstr(d)
    DEFINE d DATE
    DEFINE d_vc,str1 STRING
    LET str1=d
    IF d IS NOT NULL THEN
        IF YEAR(d) = 1 THEN
            LET d_vc = "0001"
        ELSE
            LET d_vc = YEAR(d)
        END IF
        IF MONTH(d)<10 THEN
            LET d_vc = d_vc||"0"||MONTH(d)
        ELSE
            LET d_vc = d_vc||MONTH(d)
        END IF
        
        IF DAY(d) < 10 THEN
            LET d_vc = d_vc||"0"||DAY(d)
        ELSE
            LET d_vc = d_vc||DAY(d)
        END IF
    ELSE
        LET d_vc = '        '
    END IF
    IF str1 IS NULL THEN
        LET str1=" "
    END IF
    RETURN d_vc
END FUNCTION


# *************************************************************************************************
# Nombre_funcion		completar_cadena
# Nombre del equipo		ALDEBARAN
# Desarrollado_por		Santiago Hern�ndez Boxtho
# Fecha 			    Enero/2009
# Ultima_modificacion	Enero/2009
# Descripci�n			concatena "0" a la izquierda
#                       concatena espacios en blancos  a la derecha
# Entrada               relleno     tipo de relleno "0" � " "
#                       str         cadena a concatenar
#                       longitud    'n' veces a concatenar
# Salida                str         cadena de caracteres
# **************************************************************************************************
FUNCTION completar_cadena(relleno,str,longitud)
    DEFINE relleno VARCHAR(2)
    DEFINE str,str1 STRING
    DEFINE longitud,i SMALLINT
    
    LET str1=str
    IF str<>"" OR str IS NOT NULL THEN
        LET str=str.trim()
        LET longitud = longitud - str.getLength()
    END IF
    IF str.getLength()=0 THEN
        LET str = relleno
        LET longitud = longitud - 1
    END IF
    
    IF relleno = "0" THEN
        FOR i=1 TO longitud
            LET str = relleno || str
        END FOR
    ELSE 
        FOR i=1 TO longitud
            LET str = str || " "
        END FOR
    END IF
    IF str1 IS NULL THEN
        LET str1=" "
    END IF
    
    RETURN str
END FUNCTION

# *************************************************************************************************
# Nombre_funcion		eliminar_punto_dec
# Nombre del equipo		ALDEBARAN
# Desarrollado_por		Santiago Hern�ndez Boxtho
# Fecha 			    Enero/2009
# Ultima_modificacion	Enero/2009
# Descripci�n			Elimina el punto decimal
# Entrada               dato_dec    dato decimal
# Salida                dato_str    dato sin el punto decimal
# **************************************************************************************************
FUNCTION eliminar_punto_dec(dato_dec)
    DEFINE dato_dec DECIMAL(13,2)
    DEFINE str STRING
    DEFINE indice SMALLINT
    
    LET str = dato_dec
    LET indice = str.getIndexOf(".",1)
    LET str = str.subString(1,indice-1)||str.subString(indice+1,str.getLength())
    RETURN str
END FUNCTION

--Obtiene el promedio de la tasa de postura
FUNCTION tasaSubasta()
    DEFINE lstrTasaSubasta STRING
    DEFINE ldecTasaPostura DECIMAL(5,2)
    LET lstrTasaSubasta="select sum(o.tasa_subasta)/count(*) from oferta_cnsf o, tramite_dt t 
          where o.folio_issste=t.folio_issste and fec_cad_doc>=today
          and t.cve_beneficio=1"
    PREPARE preTasaSubasta FROM lstrTasaSubasta
    EXECUTE preTasaSubasta INTO ldecTasaPostura
    RETURN ldecTasaPostura
END FUNCTION

--Obtiene la cadena con separador 
FUNCTION formato_prospectos_pipe(reg_pros,ext,ld_salario_prom_hl)
    DEFINE reg_pros RECORD # lista de datos de prospectos
        fecha_alta DATE,
        fecha_elaboracion DATE,
        tipo_registro SMALLINT,
        nombre_asegurado VARCHAR(60),
        num_issste DECIMAL(11,0),
        num_solicitud SMALLINT,
        fecha_nacimiento DATE,
        sexo CHAR,
        curp VARCHAR(18),
        delegacion SMALLINT,
        fecha_ini_pagos DATE,
        fecha_ini_derechos DATE,
        pip DECIMAL(5,2),
        ramo VARCHAR(2),
        tipo VARCHAR(2),
        sal_diario_rt DECIMAL(13,2),
        sal_diario_iv DECIMAL(13,2),
        ctia_basica_pension DECIMAL(13,2),
        imp_mensual_pension DECIMAL(13,2),
        nombre_solicitante VARCHAR(60),
        fecha_solicitud DATE,
        domicilio VARCHAR(60),
        fecha_proceso DATE,
        folio_id VARCHAR(11),
        pmg_imsss DECIMAL(13,2),
        saldo_cuenta_ind DECIMAL(13,2),
        saldo_sar DECIMAL(13,2),
        saldo_fovissste DECIMAL(13,2),
        saldo_aportaciones_vol DECIMAL(13,2),
        portabilidad CHAR,
        antiguedad SMALLINT,
        anios_cotizados SMALLINT,
        tipo_regimen CHAR,
        tasa_postura DECIMAL(5,2),
        cambio_modalidad CHAR,
        modalidad VARCHAR(2),
        subdeleg SMALLINT,
        fec_oferta DATE
    END RECORD

    
     DEFINE ext RECORD
        por_ext VARCHAR(5),
        por_ext_MCTT VARCHAR (1),
        codigo_tabla VARCHAR(3),
        mtl_CV  SMALLINT,
        vejez_derivada CHAR(1)
    END RECORD
    
    DEFINE renglon STRING
	DEFINE ld_salario_prom_hl DECIMAL(13,2)
    DEFINE lstrseparador STRING

    LET lstrseparador='|'
    LET renglon=''
    
        # 1 Fecha de alta en la BD
    LET renglon = fechaTOstr(reg_pros.fecha_alta)||lstrseparador
    
        # 2 Fecha de elaboralcion
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_elaboracion)||lstrseparador
    
        # 3 Tipo de registro
    LET renglon = renglon || completar_cadena("0",reg_pros.tipo_registro,1)||lstrseparador
        
        # 4 Nombre 
    LET renglon = renglon || reg_pros.nombre_asegurado||lstrseparador
        
        # 5 N�mero ISSSTE
    LET renglon = renglon || reg_pros.num_issste||lstrseparador
        
        # 6 N�mero de solicitud
    LET renglon = renglon || completar_cadena("0" ,reg_pros.num_solicitud ,2)||lstrseparador
        
        # 7 Fecha de Nacimiento
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_nacimiento)||lstrseparador
        
        # 8 Sexo
    LET renglon = renglon || completar_cadena(" " ,reg_pros.sexo,1)||lstrseparador
        
        # 9 CURP
    LET renglon = renglon || completar_cadena(" " ,reg_pros.curp ,18)||lstrseparador
        
        # 10 Delegaci�n
    LET renglon = renglon || completar_cadena("0" ,reg_pros.delegacion ,2)||lstrseparador
        
        # 11 Fecha de inicio de pagos
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_ini_pagos)||lstrseparador
        
        # 12 Fecha de inicio de derechos
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_ini_derechos)||lstrseparador
        
        # 13 PIP
    LET renglon = renglon || completar_cadena("0" ,eliminar_punto_dec(reg_pros.pip),5)||lstrseparador
        
        # 14 Ramo
    LET renglon = renglon || completar_cadena(" " ,reg_pros.ramo,2)||lstrseparador
        
        # 15 Tipo
    LET renglon = renglon || completar_cadena(" " ,reg_pros.tipo,2)||lstrseparador
        
        # 16 Salario diario RT
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.sal_diario_rt),13)||lstrseparador
        
        # 17 Saldo diario IV
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.sal_diario_iv),13)||lstrseparador
        
        # 18 Cuant�a B�sica de la pensi�n
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.ctia_basica_pension),13)||lstrseparador
    
        # 19 Importe mensual 
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.imp_mensual_pension),13 )||lstrseparador
    
        # 20 Nombre del solicitante
    LET renglon = renglon || reg_pros.nombre_solicitante||lstrseparador
    
        # 21 Fecha de la solicitud
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_solicitud)||lstrseparador
    
        # 22 Domicilio
    LET renglon = renglon || completar_cadena(" ",reg_pros.domicilio,60)||lstrseparador
    
        # 23 Fecha de proceso
    LET renglon = renglon || fechaTOstr(reg_pros.fecha_proceso)||lstrseparador
    
        # 24 Folio indentificador
    LET renglon = renglon || completar_cadena(" ",reg_pros.folio_id,11)||lstrseparador
    
        # 25 PMG IMSSS
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.pmg_imsss),13)||lstrseparador
    
        # 26 Saldo Cuenta individual
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_cuenta_ind),13)||lstrseparador
        
        # 27 Saldo SAR
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_sar),13)||lstrseparador
    
        # 28 Saldo FOVISSSTE
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_fovissste),13)||lstrseparador
        
        # 29 Saldo de aportaciones voluntarias
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(reg_pros.saldo_aportaciones_vol),13)||lstrseparador
    
        # 30 Portabilidad
    LET renglon = renglon || completar_cadena(" ",reg_pros.portabilidad,1)||lstrseparador
    
        # 31 A�os exclusivos ISSSTE
	LET renglon = renglon || completar_cadena("0",reg_pros.anios_cotizados,2)||lstrseparador -- DEFECTO TK-2023052997
    --LET renglon = renglon || completar_cadena("0",reg_pros.antiguedad,2)
        
        # 32 A�os reconocidos
	LET renglon = renglon || completar_cadena("0",reg_pros.antiguedad,2)||lstrseparador -- DEFECTO TK-2023052997
    --LET renglon = renglon || completar_cadena("0",reg_pros.anios_cotizados,2)
    
        # 33 Tipo de r�gimen
    LET renglon = renglon || completar_cadena(" ",reg_pros.tipo_regimen,1)||lstrseparador
        
        # 34 Tasa de postura
    LET renglon = renglon || completar_cadena(" ",eliminar_punto_dec(reg_pros.tasa_postura),5)||lstrseparador
    
        # 35 Cambio de modalidad 
    LET renglon = renglon || completar_cadena(" ",reg_pros.cambio_modalidad,1)||lstrseparador
        
        # 36 Modalidad 
    LET renglon = renglon || completar_cadena(" ",reg_pros.modalidad,2)||lstrseparador
    
        # 37 Subdelegaci�n 
    LET renglon = renglon || completar_cadena("0",reg_pros.subdeleg,3)||lstrseparador
    
        # 38 Fecha de Oferta
    LET renglon = renglon || fechaTOstr(reg_pros.fec_oferta)||lstrseparador

        # 39 Porcentaje del excedente a utilizar
    LET renglon = renglon || completar_cadena(" ",ext.por_ext,5)||lstrseparador
        
        # 40 Porcentaje del excedente para MCTT
    LET renglon = renglon || completar_cadena(" ",ext.por_ext_MCTT,1)||lstrseparador
        
        # 41 C�digo de tablas a usar
    LET renglon = renglon || completar_cadena(" ",ext.codigo_tabla,3)||lstrseparador

        # 42 Mortalidad para CV
    LET renglon = renglon || completar_cadena(" ",ext.mtl_CV,1)||lstrseparador

         #43 Pension de vejez derivada
    LET renglon = renglon || completar_cadena(" ",ext.vejez_derivada,1)||lstrseparador #LAHA 2014/01/23

		#44 Salario promedio de vida laboral
    LET renglon = renglon || completar_cadena("0",eliminar_punto_dec(ld_salario_prom_hl),13)  -- INFOTEC TK - 2023052997
        
    RETURN renglon   
END FUNCTION


FUNCTION obtener_datos_beneficiarios(n_issste,list_benef)
    DEFINE list_benef DYNAMIC ARRAY OF RECORD
                b_num_issste2 DECIMAL(11,0),
                b_curp2 VARCHAR(18),
                b_apellido_paterno2 VARCHAR(60),
                b_apellido_materno2 VARCHAR(60),
                b_nombre2 VARCHAR(60),
                b_parentesco_cve2 INTEGER, 
                b_fecha_nac2 DATE,
                b_edad2 INTEGER,
                b_sexo2 CHAR,
                b_estado2 STRING,
                b_benefi DECIMAL (11,0) --LMLC 31/08/2015
    END RECORD
    DEFINE list_directo DYNAMIC ARRAY OF RECORD
               a_num_issste DECIMAL (11,0),
               a_curp VARCHAR (18),
               ap_pate VARCHAR (40),
               ap_mate VARCHAR (40),
               nombre VARCHAR(40),
               sexo VARCHAR (5),
               estado_civil VARCHAR (5),
               rfc VARCHAR (15)
    END RECORD
    DEFINE estado_indirecto VARCHAR(3)
    DEFINE n_issste,b_ito_id, cont,d INTEGER
    DEFINE edad_ind SMALLINT
    DEFINE fecha_prorroga,fecha_limite DATE
    DEFINE tipo_prorroga CHAR
    DEFINE cursor_busca, cursor_dir string
    DEFINE dto_estado varchar (5)
    DEFINE t_directo  VARCHAR (5)
    DEFINE lc_sql STRING
    INITIALIZE fecha_prorroga TO NULL
    INITIALIZE fecha_limite TO NULL

    CALL list_benef.clear() 
    LET cont=1
    LET fecha_limite= MDY(12,31,2999)
    SET ISOLATION TO DIRTY READ
    LET d = 1
    LET  cursor_dir = "SELECT num_issste,
                              curp,
                              apellido_paterno,
                              apellido_materno,
                              nombre,
                              dto_estado,
                              sexo,
                              estado_civil,
                              t_directo,
                              rfc
                                 FROM directo
                                  WHERE num_issste = ",n_issste
                        DISPLAY "CURSOR LMLC DIRECTO ------->>>", cursor_dir
                        PREPARE select_directo_00 FROM cursor_dir
                        ##DISPLAY "CURSOR LMLC DIRECTO ------->>>", cursor_dir
                        DECLARE cur_dir_pros CURSOR FOR select_directo_00
                           FOREACH cur_dir_pros INTO list_directo[d]. a_num_issste,
                                                  list_directo[d].a_curp,
                                                  list_directo[d].ap_pate,
                                                  list_directo[d].ap_mate,
                                                  list_directo[d].nombre,
                                                  dto_estado,
                                                  list_directo[d].sexo ,
                                                  list_directo[d].estado_civil,
                                                  t_directo,
                                                  list_directo[d].rfc
                                ##DISPLAY  "-------------------------------------------------------- DATOS DIRECTO------------------------------"                       
                                ## DISPLAY  "num_issste------->  ",list_directo[d].a_num_issste
                                ##DISPLAY  "curp ------------>  ",list_directo[d].a_curp
                                ##DISPLAY  "apellido_paterno->  ",list_directo[d].ap_pate
                                ##DISPLAY  "apellido_materno->  ",list_directo[d].ap_mate
                                ##DISPLAY  "nombre----------->  ",list_directo[d].nombre
                                ##DISPLAY  "dto_estado------->  ",dto_estado
                                ##DISPLAY  "sexo------------->  ",list_directo[d].sexo 
                                ##DISPLAY  "estado_civil----->  ",list_directo[d].estado_civil
                                ##DISPLAY  "t_directo-------->  ",t_directo
                                ##DISPLAY  "rfc-------------->  ",list_directo[d].rfc
                                ##DISPLAY  "-------------------------------------------------------- DATOS DIRECTO------------------------------"
                                   IF ((dto_estado = 'A' OR dto_estado = 'B')  AND (t_directo = 'T' OR t_directo = 'P' OR t_directo = 'TP')) THEN
                                        ##DISPLAY "QUE ONDA"
                                        ##DISPLAY  "num_issste------->  ",list_directo[d].a_num_issste
                                        ##DISPLAY  "dto_estado------->  ",dto_estado

                                          LET cursor_busca=" SELECT i.ito_id,
                                                                    i.curp,
                                                                    i.apellido_paterno,
                                                                    i.apellido_materno,
                                                                    i.nombre,
                                                                    i.fecha_nac,
                                                                    i.parentesco_cve,
                                                                    i.ito_estado,
                                                                    c.num_issste AS num_issste_benef,
                                                                    d.num_issste
                                                                        FROM dicto_indicto di,indirecto i, directo d , OUTER directo c
                                                                            WHERE di.ito_id=i.ito_id and di.num_issste = d.num_issste  
                                                                            AND d.t_directo <> 'ER' 
                                                                            AND d.num_issste= ",n_issste,"
                                                                            AND i.ito_estado <> 'B' 
                                                                            AND i.ito_estado <> 'SD' 
                                                                            AND i.curp = c.curp
                                                                            AND c.t_directo <> 'ER'
                                                                            ORDER BY i.parentesco_cve,i.fecha_nac ASC"
                                                                                #DISPLAY "CURSOR BUSCA,   ",cursor_busca
                                   ELSE 
                                      IF ((dto_estado = 'F') AND (t_directo = 'T' OR t_directo = 'P' OR t_directo = 'TP')) THEN
                                             DISPLAY "QUE FALLE"
                                             DISPLAY  "num_issste------->  ",list_directo[d].a_num_issste
                                             DISPLAY  "dto_estado------->  ",dto_estado
                                                  LET cursor_busca ="SELECT i.ito_id,
                                                                            i.curp,
                                                                            i.apellido_paterno,
                                                                            i.apellido_materno, 
                                                                            i.nombre,
                                                                            i.fecha_nac,
                                                                            i.parentesco_cve,
                                                                            i.ito_estado,
                                                                            p.num_issste,
                                                                            p.num_issste_d 
                                                                                    FROM pen_ind_ci p, directo d, indirecto i, dicto_indicto di, tramite_dt t
                                                                                    WHERE p.num_issste_d = ",n_issste," 
                                                                                    AND p.num_issste_d = di.num_issste 
                                                                                    AND di.ito_id = i.ito_id
                                                                                    AND d.curp = i.curp
                                                                                    AND d.num_issste = p.num_issste
                                                                                    AND t.estatus_tramite = 9
                                                                                    AND i.ito_estado = 'D'
                                                                                    AND d.t_directo <>'ER'  
                                                                                    AND t.folio_issste = p.folio_issste
                                                                                    ORDER BY i.parentesco_cve,i.fecha_nac ASC"
                                                                                    # DISPLAY "CURSOR BUSCA,   ",cursor_busca
                                      END IF 
                                   END IF
                           END FOREACH
                           
        DECLARE cur_ito_ids CURSOR FROM cursor_busca
     
                    FOREACH cur_ito_ids INTO b_ito_id,
                             list_benef[cont].b_curp2,
                             list_benef[cont].b_apellido_paterno2, 
                             list_benef[cont].b_apellido_materno2, 
                             list_benef[cont].b_nombre2, 
                             list_benef[cont].b_fecha_nac2, 
                             list_benef[cont].b_parentesco_cve2,
                             estado_indirecto,
                             list_benef[cont].b_benefi

          #DISPLAY "ito_id ",b_ito_id
          #DISPLAY "b_curp2 ",list_benef[cont].b_curp2
          #DISPLAY "b_apellido_paterno2 ",list_benef[cont].b_apellido_paterno2
          #DISPLAY "b_apellido_materno2 ",list_benef[cont].b_apellido_materno2
          #DISPLAY "b_nombre2 ",list_benef[cont].b_nombre2
          #DISPLAY "b_fecha_nac2 " ,list_benef[cont].b_fecha_nac2
          #DISPLAY "b_parentesco_cve2 ",list_benef[cont].b_parentesco_cve2
          #DISPLAY "estado_indirecto ",estado_indirecto

#DISPLAY "CAMBIO !",cont
          
            ####### 666
            IF list_benef[cont].b_apellido_materno2 IS NULL OR list_benef[cont].b_apellido_materno2 = "" THEN
                LET list_benef[cont].b_apellido_materno2 = " "
                    #DISPLAY "S0.2"
            END IF
            ####### 666
        CALL obtener_desc(3, estado_indirecto) RETURNING list_benef[cont].b_estado2
#DISPLAY "********************"
#DISPLAY "-----S0.3-----"
#DISPLAY "S0.3",list_benef[cont].b_estado2
#DISPLAY "-----S0.3-----"
#DISPLAY "********************"
        
        LET list_benef[cont].b_num_issste2 = b_ito_id
        LET list_benef[cont].b_edad2=calcula_edad(list_benef[cont].b_fecha_nac2,TODAY)
   
            # Asignar SEXO
        IF list_benef[cont].b_parentesco_cve2=10 OR list_benef[cont].b_parentesco_cve2=40 OR
           list_benef[cont].b_parentesco_cve2=41 OR list_benef[cont].b_parentesco_cve2=50 OR
           list_benef[cont].b_parentesco_cve2=51 OR list_benef[cont].b_parentesco_cve2=70 OR
           list_benef[cont].b_parentesco_cve2=71 OR list_benef[cont].b_parentesco_cve2=72 THEN
            LET list_benef[cont].b_sexo2="H"
        ELSE 
            LET list_benef[cont].b_sexo2="M"
        END IF
        
        IF (list_benef[cont].b_parentesco_cve2=70 OR list_benef[cont].b_parentesco_cve2=80 OR 
            list_benef[cont].b_parentesco_cve2=71 OR list_benef[cont].b_parentesco_cve2=81) THEN
            LET edad_ind = calcula_edad(list_benef[cont].b_fecha_nac2,TODAY)
            --DISPLAY "SAO ... Edad (",b_ito_id,") (",list_benef[cont].b_nombre2,"): ",edad_ind
            
            IF list_benef[cont].b_edad2 >= 18 THEN
            LET fecha_prorroga=MDY(31,12,1899)
            LET tipo_prorroga=' ' 
            --DISPLAY "ENTRA SI ES MAYOR DE 18 BUSCANDO SI TIENE PRORROGA"
                SET ISOLATION TO DIRTY READ
                    LET lc_sql = " SELECT fecha_termino, u_version  " 
                                ,"   FROM prorroga                  "
                                ,"  WHERE ito_id = ?                "
                                ,"    AND fecha_termino >= TODAY    "
                   PREPARE cursel01 FROM lc_sql
                   EXECUTE cursel01 USING b_ito_id INTO fecha_prorroga,tipo_prorroga
                    
               #DISPLAY " SELECT fecha_termino, u_version
               #          FROM prorroga 
               #          WHERE ito_id = b_ito_id
               #          AND fecha_termino >",TODAY 
                
                #DISPLAY "SAO ... vigencia : ",fecha_prorroga
                
                IF sqlca.sqlcode = 0 THEN
                #display "tiene prorroga",tipo_prorroga,",",fecha_prorroga
                    IF tipo_prorroga='S' AND edad_ind <=25 AND fecha_prorroga > TODAY THEN
                        LET list_benef[cont].b_estado2 = "ESTUDIANTE " || list_benef[cont].b_estado2
                        --LET cont = cont + 1
                    END IF
                    IF tipo_prorroga='P' AND (fecha_prorroga = fecha_limite OR fecha_prorroga = MDY(12,31,2999))THEN
                    #display "llegue"
                        LET list_benef[cont].b_estado2 = "DISCAPACITADO PERMANENTE " --|| list_benef[cont].b_estado2
                        --DISPLAY "list_benef[cont].b_estado2",list_benef[cont].b_estado2
                        --LET cont = cont + 1
                    END IF
                    IF tipo_prorroga='T' AND fecha_prorroga >= TODAY THEN
                        LET list_benef[cont].b_estado2 = "DISCAPACITADO TEMPORAL " || list_benef[cont].b_estado2
                        --LET cont = cont + 1
                    END IF
                    LET cont = cont + 1
                END IF
            ELSE
                LET cont = cont + 1
            END IF
        ELSE
            LET cont = cont + 1
        END IF
        
    END FOREACH
    
    SET ISOLATION TO COMMITTED READ --Add 24/Marzo/2010
    CALL list_benef.deleteElement(cont)
    
END FUNCTION

# *************************************************************************************************
# Nombre_funcion		beneficiarios_pros
# Nombre del equipo		ALDEBARAN
# Desarrollado_por		Santiago Hern�ndez Boxtho
# Fecha 			    Enero/2008
# Ultima_modificacion	Julio/2008
# Descripci�n			Filtra el grupo familiar de un prospecto
# Entra                 list_benef      Lista de beneficiarios
#                       folio_issste_d  Folio ISSSTE del tr�mite
# Salida                
# *************************************************************************************************
FUNCTION beneficiarios_pros1(list_benef,solicitante)
    DEFINE solicitante CHAR (2)
    DEFINE list_benef DYNAMIC ARRAY OF RECORD
            num_issste DECIMAL(11,0),       
            num_solicitud SMALLINT,
            nombre VARCHAR(60),
            parentesco VARCHAR(2),
            sexo CHAR,
            fecha_nacimiento DATE,
            fecha_ini_derechos DATE,
            fecha_vencimiento DATE,
            orfandad CHAR,
            fecha_ini_pagos DATE,
            folio_id VARCHAR(11),
            benefi DECIMAL(11,0) -- LMLC 31/08/2015
        END RECORD
    DEFINE i,OK SMALLINT 
    
        # Extraer los beneficiarios
    DISPLAY "Prospecto (Beneficiarios:",list_benef.getLength(),")"
        # si el grupo familiar tiene ascendienetes  e hijos eliminar los ascendientes y dejar a los hijos como beneficiarios
    CALL f_val_50_of_hijos(list_benef)
    
    LET OK = TRUE
    LET i=2
    IF list_benef.getLength() IS NOT NULL OR list_benef.getLength()>0 THEN
        IF list_benef.getLength() > 1 THEN
            WHILE i <= list_benef.getLength()

                CASE
                    WHEN (list_benef[1].parentesco = 30 OR list_benef[1].parentesco = 40 OR list_benef[1].parentesco = 70 OR list_benef[1].parentesco = 80) AND (list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 81)
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 31 OR list_benef[1].parentesco = 41 OR list_benef[1].parentesco = 71 OR list_benef[1].parentesco = 81) AND (list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 81)
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 50 AND list_benef[i].parentesco = 60 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 60 AND list_benef[i].parentesco = 50 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 51 AND list_benef[i].parentesco = 61 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 61 AND list_benef[i].parentesco = 51 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    OTHERWISE
                        DISPLAY "(",list_benef[i].parentesco,")",list_benef[i].nombre
                        CALL list_benef.deleteElement(i)
                END CASE
            END WHILE

        END IF

        
        FOR i=1 TO list_benef.getLength()
--        Convertir parentescos para CNSF
--        ESPOSO(A)	ES
--        CONCUBINARIO/CONCUBINA	CO
--        HIJO(A)	HI
--        ASCENDIENTE	AS
            
            CASE
                WHEN (list_benef[i].parentesco = 30 OR list_benef[i].parentesco = 40)
                    LET list_benef[i].parentesco = 'ES'
                    EXIT CASE
                WHEN (list_benef[i].parentesco = 31 OR list_benef[i].parentesco = 41)
                    LET list_benef[i].parentesco = 'CO'
                    EXIT CASE
                WHEN (list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 81)
                    LET list_benef[i].parentesco = 'HI'
                    EXIT CASE
                WHEN (list_benef[i].parentesco = 50 OR list_benef[i].parentesco = 60 OR list_benef[i].parentesco = 51 OR list_benef[i].parentesco = 61)
                    LET list_benef[i].parentesco = 'AS'
                    EXIT CASE
            END CASE
            DISPLAY list_benef[i].*
            IF solicitante = 'D' THEN
                LET list_benef[i].benefi = '0000000000'
            END IF
            LET n_issste_benef=list_benef[i].benefi
            CALL benef.writeLine(formato_beneficiario(list_benef[i].*))
            LET listBenef[i].beneficiario=formato_beneficiario_pipe(list_benef[i].*)
        END FOR
    END IF
##EL primero inserta la cabeza de familia el segundo los demas beneficiarios
    LET OK = TRUE
    LET i=3
    IF list_benef.getLength() IS NOT NULL OR list_benef.getLength()>0 THEN
        IF list_benef.getLength() > 1 THEN
            WHILE i <= list_benef.getLength()

                CASE
                    WHEN (list_benef[1].parentesco = 30 OR list_benef[1].parentesco = 40 OR list_benef[1].parentesco = 70 OR list_benef[1].parentesco = 80) AND (list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 81)
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 31 OR list_benef[1].parentesco = 41 OR list_benef[1].parentesco = 71 OR list_benef[1].parentesco = 81) AND (list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 81)
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 50 AND list_benef[i].parentesco = 60 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 60 AND list_benef[i].parentesco = 50 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 51 AND list_benef[i].parentesco = 61 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    WHEN (list_benef[1].parentesco = 61 AND list_benef[i].parentesco = 51 AND OK = TRUE)
                        LET OK = FALSE
                        LET i = i + 1
                        EXIT CASE
                    OTHERWISE
                        DISPLAY "(",list_benef[i].parentesco,")",list_benef[i].nombre
                        CALL list_benef.deleteElement(i)
                END CASE
            END WHILE

        END IF

        
        FOR i=2 TO list_benef.getLength()
--        Convertir parentescos para CNSF
--        ESPOSO(A)	ES
--        CONCUBINARIO/CONCUBINA	CO
--        HIJO(A)	HI
--        ASCENDIENTE	AS
            
            CASE
                WHEN (list_benef[i].parentesco = 30 OR list_benef[i].parentesco = 40)
                    LET list_benef[i].parentesco = 'ES'
                    EXIT CASE
                WHEN (list_benef[i].parentesco = 31 OR list_benef[i].parentesco = 41)
                    LET list_benef[i].parentesco = 'CO'
                    EXIT CASE
                WHEN (list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 81)
                    LET list_benef[i].parentesco = 'HI'
                    EXIT CASE
                WHEN (list_benef[i].parentesco = 50 OR list_benef[i].parentesco = 60 OR list_benef[i].parentesco = 51 OR list_benef[i].parentesco = 61)
                    LET list_benef[i].parentesco = 'AS'
                    EXIT CASE
            END CASE
            DISPLAY list_benef[i].*
            
        END FOR
    END IF
END FUNCTION

# *************************************************************************************************
# Nombre_funcion		obtener_beneficiarios_pros
# Nombre del equipo		SAO
# Desarrollado_por		SAO
# Fecha 			    MAYO/2013
# Ultima_modificacion	MAYO/2013
# Descripci�n			Obtiene los beneficiarios de un prospecto
# Entrada               n_issste N�mero ISSSTE del Solicitante
# Salida                
# **************************************************************************************************
FUNCTION obtener_beneficiarios_pros(lintCveBeneficio,ldteFecTramite, vl_n_issste, vl_num_solicitud, vl_fec_ini_derechos, ldteFechaIniPagos, 
vl_folio_id, list_benef_pros)
    DEFINE vl_n_issste DECIMAL(11,0)
    DEFINE vl_num_solicitud,i,OK_DELETE_ITEM,a,c,b,d,con,contador SMALLINT
    DEFINE vl_folio_id VARCHAR(11)
     # Lista de beneficiarios para prospectos
    DEFINE list_benef_pros DYNAMIC ARRAY OF RECORD
            num_issste DECIMAL(11,0),       
            num_solicitud SMALLINT,
            nombre VARCHAR(60),
            parentesco VARCHAR(2),
            sexo CHAR,
            fecha_nacimiento DATE,
            fecha_ini_derechos DATE,
            fecha_vencimiento DATE,
            orfandad CHAR,
            fecha_ini_pagos DATE,
            folio_id VARCHAR(11),
            benefi DECIMAL(11,0) -- LMLC 31/08/2015
        END RECORD
     # Lista de beneficiarios que se extraen de datos_logica.4gl
    DEFINE list_benef DYNAMIC ARRAY OF RECORD
                b_num_issste2 DECIMAL(11,0),
                b_curp2 VARCHAR(18),
                b_apellido_paterno2 VARCHAR(60),
                b_apellido_materno2 VARCHAR(60),
                b_nombre2 VARCHAR(60),
                b_parentesco_cve2 INTEGER, 
                b_fecha_nac2 DATE,
                b_edad2 INTEGER,
                b_sexo2 CHAR,
                b_estado2 STRING,
                b_benefi DECIMAL (11,0) --LMLC 31/08/2015 sirve
    END RECORD
    DEFINE dto_estado VARCHAR(5)
    DEFINE valida, 
            beneficiario,
            benef,
            verifica_prorroga,
            valido_curp,
            verifica_prorroga1,
            benef1,
            sql_query2,
            sql_query,
            sql_query0 string
    DEFINE curp varchar (50)
    DEFINE n_issst_e INTEGER
    DEFINE ito_estado VARCHAR(5)
    DEFINE ito_id,dia INTEGER
    DEFINE cve_beneficio INTEGER
    DEFINE valida_Fecha_M INT   -----------Variable que validara si el trabajador esta fallecido
    DEFINE fecha_prorroga,fecha_fallecimiento DATE
    DEFINE fecha_limite DATE
    DEFINE it_estado VARCHAR(5)
    DEFINE anio_fallecimiento, anio_nacimiento INT
    DEFINE mes_fallecimiento, mes_nacimiento INT
    DEFINE lintCveBeneficio INTEGER --D.A.T.C.
    DEFINE vl_fec_limite, vl_fec_ini_derechos, vl_fec_prorroga, ldteFechaIniPagos DATE
    DEFINE vl_tipo_prorroga CHAR
    DEFINE ldteFecTramite DATE

    #DISPLAY "********************"
    #DISPLAY "0.1-",vl_n_issste
    #DISPLAY "********************"
        
    LET vl_fec_limite=MDY (01,01,0001)
    LET OK_DELETE_ITEM = FALSE

    CALL obtener_datos_beneficiarios(vl_n_issste,list_benef)
    #DISPLAY "SAO ... ------->>",list_benef.getLength(),"  beneficiarios obtenidos"
    #DISPLAY "vl_n_issste ... ",vl_n_issste, " Numero Issste"
    #DISPLAY "********************"
    DISPLAY "S0.4-",list_benef.getLength()
    #DISPLAY "********************"
          
    LET a=list_benef.getLength()
    LET c=1
    LET b=1

    FOR i=1 TO a
        LET n_issst_e =''
        LET dto_estado=''
        LET valida =''
        INITIALIZE fecha_prorroga TO NULL
        INITIALIZE fecha_limite TO NULL 
        LET valido_curp = "select COUNT(*) from directo where curp like '",list_benef[c].b_curp2,"' and nombre like '",list_benef[c].b_nombre2,"' and apellido_paterno like '",list_benef[c].b_apellido_paterno2,"' and apellido_materno like NVL ('",list_benef[c].b_apellido_materno2,"',' ') and fec_nac = to_date ('",list_benef[c].b_fecha_nac2,"','%d/%m/%Y')"
        #DISPLAY ">>>VALIDA  ",valido_curp
        DECLARE valid_c CURSOR FROM valido_curp
        FOREACH valid_c INTO con
            DISPLAY "con, ",c,", ",con
            IF con <> 0 THEN
            LET valida = "select num_issste,curp from directo where curp like '",list_benef[c].b_curp2,"' and nombre like '",list_benef[c].b_nombre2,"' and apellido_paterno like '",list_benef[c].b_apellido_paterno2,"' and apellido_materno like NVL ('",list_benef[c].b_apellido_materno2,"',' ') and fec_nac = to_date ('",list_benef[c].b_fecha_nac2,"','%d/%m/%Y') and t_directo <> 'ER' "
            DECLARE valid_a CURSOR FROM valida
                FOREACH valid_a INTO n_issst_e,curp
                    DISPLAY "CURP CNSF, ",curp, ", ",c
                    LET d = c
                    DISPLAY d,'VALOR ANTERIOR DEL CONTADOR C'
                    IF curp <> 'NULL' THEN
                        LET beneficiario= "select dto_estado from directo where num_issste= ",n_issst_e
                                DISPLAY"SELECT BENEFICIARIO   ","select dto_estado from directo where num_issste= ",n_issst_e
                        DECLARE cur_muer CURSOR FROM beneficiario
                        FOREACH cur_muer INTO dto_estado
                            DISPLAY "dto_estado  ,",dto_estado
                            IF dto_estado = 'F' then
                                DISPLAY "ELIMINO EL ARCHIVO",n_issst_e ," , " ,dto_estado
                                CALL list_benef.deleteElement(c)
                                DISPLAY list_benef.getLength()
                                LET c = d -1
                                DISPLAY c," CONTADOR DESPUES DE QUITAR EL REGISTRO PARA QUE NO LO PINTE"
                               CONTINUE FOREACH     --APE Ticket I-014260 04/08/2016
                            ELSE
                                # (1) N�mero de seguridad social
                                LET list_benef_pros[c].num_issste = vl_n_issste

                                DISPLAY "benf 1",list_benef_pros[c].num_issste
                                LET list_benef_pros[c].benefi = n_issst_e
                                 
                                 # (2) N�mero de solicitud
                                LET list_benef_pros[c].num_solicitud = vl_num_solicitud
                                DISPLAY "NUMERO DE SOLICITUD",list_benef_pros[c].num_solicitud
                                 # (3) Nombre
                                DISPLAY ">>>curp  ",curp
                                DISPLAY ">>>n_issst_e  ",n_issst_e
                                DISPLAY ">>>list_benef[i].b_curp2  ",list_benef[c].b_curp2
                                LET list_benef_pros[c].nombre = list_benef[c].b_apellido_paterno2 CLIPPED," "||
                                                            list_benef[c].b_apellido_materno2 CLIPPED," "||
                                                            list_benef[c].b_nombre2 CLIPPED
                                                                                
                                DISPLAY "Nombre: ",list_benef_pros[c].nombre
                                #####SE VOLVIO A VALIDAR EL ESTATUS DE LOS BENEFICIARIOS YA QUE EN ESTE PUNTO VUELVE A IMPACTAR A LOS BENEFICIARIOS RVH
                                 # (4) Parentesco
                                LET list_benef_pros[c].parentesco=list_benef[c].b_parentesco_cve2
                                 DISPLAY "Parentesco: ",list_benef[c].b_parentesco_cve2
                                 # (5) Sexo (M/F)
                                IF list_benef[c].b_sexo2 = "H" THEN
                                    LET list_benef_pros[c].sexo = "M"
                                ELSE
                                    LET list_benef_pros[c].sexo = "F"
                                END IF
                                 DISPLAY "sexo",list_benef_pros[c].sexo

                                 # (6) Fecha de nacimiento
                                LET list_benef_pros[c].fecha_nacimiento = list_benef[c].b_fecha_nac2
                                 DISPLAY "Fecha de nacimiento",list_benef[c].b_fecha_nac2
                                 
                                 # (7) Fecha de inicio de derechos
                                 ##Se realiza la validacion de los derechos para los hijos nacidos despues de 9 meses del trabajador fallecido fallecido

                                DISPLAY "vl_n_issste, ;)",vl_n_issste -----Numero de Issste Directo
                                DISPLAY "num_issste_b",n_issst_e      -----N�mero de Issste Beneficiario

                                LET sql_query2 = "SELECT MAX (cve_beneficio) 
                                                  FROM tramite_dt 
                                                  WHERE no_issste_d =",vl_n_issste,"  and estatus_tramite <> 3"
                                  
                                DISPLAY sql_query2
                                PREPARE prp_2 FROM sql_query2
                                EXECUTE prp_2  INTO cve_beneficio

                                LET sql_query0 = "SELECT count (*)
                                                 FROM fecha_fallecimiento 
                                                 WHERE num_issste=",vl_n_issste
                                DISPLAY sql_query0
                                PREPARE prp_10 FROM sql_query0
                                EXECUTE prp_10  INTO valida_Fecha_M
                                DISPLAY "valida_Fecha_M, ", valida_Fecha_M

                                IF valida_Fecha_M = 0 THEN
                                    LET list_benef_pros[c].fecha_ini_derechos = vl_fec_ini_derechos
                                    DISPLAY "Fecha de inicio de derechos",vl_fec_ini_derechos
                                ELSE
                                    LET sql_query = "SELECT fecha_fallecimiento
                                                     FROM fecha_fallecimiento 
                                                     WHERE num_issste=",vl_n_issste
                                    DISPLAY sql_query
                                    PREPARE prp_1 FROM sql_query
                                    EXECUTE prp_1  INTO fecha_fallecimiento
                                    
                                    DISPLAY "fecha_fallecimiento: ",fecha_fallecimiento
                                    DISPLAY "list_benef[cont].fecha_nacimiento: ",list_benef[c].b_fecha_nac2
                        
                                    LET dia = Estandarizar_Meses_Periodo(fecha_fallecimiento,list_benef[c].b_fecha_nac2)
                                    DISPLAY "TOTAL DE DIAS: ",dia
                                    DISPLAY "EL BENEFICIO ES: ",cve_beneficio

                                    LET anio_fallecimiento = YEAR(fecha_fallecimiento)
                                    LET anio_nacimiento= YEAR(list_benef[c].b_fecha_nac2)
                                    LET mes_fallecimiento = MONTH(fecha_fallecimiento)
                                    LET mes_nacimiento= MONTH(list_benef[c].b_fecha_nac2)
                        
                                    DISPLAY "año_fallecimiento: ",anio_fallecimiento
                                    DISPLAY "año_nacimiento: ",list_benef[c].b_fecha_nac2
                                    ---pendiente OR cve_beneficio = 20 OR cve_beneficio = 1
                                    IF cve_beneficio = 7  OR cve_beneficio = 9 OR cve_beneficio = 10 
                                    OR cve_beneficio = 26 OR cve_beneficio = 40 OR cve_beneficio =429 OR cve_beneficio =430
                                    OR cve_beneficio = 432 OR cve_beneficio =442 OR cve_beneficio =443 OR cve_beneficio =445 THEN
                                        IF dia <= 300 AND anio_nacimiento >= anio_fallecimiento AND mes_nacimiento >= mes_fallecimiento  THEN 
                                        display "ENTRO 1"
                                            LET list_benef_pros[c].fecha_ini_derechos = list_benef[c].b_fecha_nac2
                                        ELSE
                                        display "ENTRO  2"
                                            LET list_benef_pros[c].fecha_ini_derechos = vl_fec_ini_derechos
                                        END IF
                                    DISPLAY "list_benef[cont].fecha_ini_derechos , ;)",list_benef_pros[c].fecha_ini_derechos
                                    ELSE
                                        LET list_benef_pros[c].fecha_ini_derechos = vl_fec_ini_derechos
                                    END IF    
                                END IF
                                # (8) Fecha de vencimiento
                                LET benef = "select ito_id,ito_estado from indirecto where curp like '",list_benef[c].b_curp2,"' and nombre like '",list_benef[c].b_nombre2,"' and apellido_paterno like '",list_benef[c].b_apellido_paterno2,"'and fecha_nac = to_date ('",list_benef[c].b_fecha_nac2,"','%d/%m/%Y')"
                                DISPLAY "benef, ",benef
                                DECLARE cur_bene CURSOR FROM benef
                                FOREACH cur_bene INTO ito_id,ito_estado
                                    DISPLAY "ito_id, ",ito_id,", ",c
                                    DISPLAY "it_estado, ",it_estado,", ",c
                                    LET verifica_prorroga1="SELECT count(*)  FROM prorroga WHERE ito_id =", ito_id
                                    DISPLAY "verifica_prorroga1, ",verifica_prorroga1
                                    DECLARE cur_prorro1 CURSOR FROM verifica_prorroga1
                                    FOREACH cur_prorro1 INTO contador
                                        IF contador<>0 THEN
                                            LET verifica_prorroga="SELECT fecha_termino, u_version  FROM prorroga WHERE ito_id =", ito_id
                                            DECLARE cur_prorro3 CURSOR FROM verifica_prorroga
                                            FOREACH cur_prorro3 INTO vl_fec_prorroga,vl_tipo_prorroga
                                                DISPLAY "vl_fec_prorroga, ",vl_fec_prorroga,", ",c
                                                DISPLAY "vl_tipo_prorroga, ",vl_tipo_prorroga,", ",c   
                                                DISPLAY vl_fec_prorroga," ,vl_fec_prorroga"
                                                ###RVH 5-09-2013 Se pondra una condicion ya que en algunos casos de los beneficiarios en la tabla de prorroga 
                                                IF vl_fec_prorroga >= '31/12/2099' THEN
                                                    DISPLAY "Cambio de Fecha 31/12/2099 a 01/01/0001"
                                                    LET vl_fec_prorroga = '01/01/0001'
                                                END IF
                                                IF list_benef_pros[c].parentesco=70 OR list_benef_pros[c].parentesco=80 OR list_benef_pros[c].parentesco=71 OR list_benef_pros[c].parentesco=81 THEN
                                                    CASE
                                                        WHEN (vl_tipo_prorroga='S')
                                                            DISPLAY "HOLA S vl_tipo_prorroga, ",vl_tipo_prorroga,", ",list_benef_pros[c].fecha_vencimiento
                                                            LET list_benef_pros[c].fecha_vencimiento = vl_fec_prorroga
                                                            EXIT CASE
                                                        WHEN (vl_tipo_prorroga='T')
                                                            DISPLAY "HOLA T vl_tipo_prorroga, ",vl_tipo_prorroga,", ",list_benef_pros[c].fecha_vencimiento
                                                            LET list_benef_pros[c].fecha_vencimiento = vl_fec_prorroga
                                                            EXIT CASE
                                                        WHEN (vl_tipo_prorroga='P')
                                                            DISPLAY "HOLA P vl_tipo_prorroga, ",vl_tipo_prorroga,", ",list_benef_pros[c].fecha_vencimiento
                                                            LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                                                            DISPLAY list_benef_pros[c].fecha_vencimiento
                                                            EXIT CASE
                                                        WHEN list_benef[c].b_edad2 >= 18
                                                            DISPLAY "SE BORRA JAJAJAJA ;( "
                                                            LET OK_DELETE_ITEM = TRUE
                                                            EXIT CASE
                                                        OTHERWISE
                                                        DISPLAY "vencimiento +18",vl_tipo_prorroga
                                                        LET list_benef_pros[c].fecha_vencimiento = MDY ( MONTH(list_benef_pros[c].fecha_nacimiento) , DAY(list_benef_pros[c].fecha_nacimiento), YEAR(list_benef_pros[c].fecha_nacimiento)+18 )
                                                        EXIT CASE
                                                    END CASE 
                                                END IF  
                                                IF list_benef_pros[c].parentesco=30 OR list_benef_pros[c].parentesco=31 OR list_benef_pros[c].parentesco=40 OR list_benef_pros[c].parentesco=41 THEN
                                                    --DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                                    LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001 )
                                                    DISPLAY list_benef_pros[c].fecha_vencimiento
                                                    DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                                END IF
                                                IF list_benef_pros[c].parentesco=50 OR list_benef_pros[c].parentesco=51 OR list_benef_pros[c].parentesco=60 OR list_benef_pros[c].parentesco=61 THEN
                                                    --DISPLAY "list_benef_pros[c].parentesco=abuelo padre abuela o madre ",list_benef_pros[c].fecha_vencimiento
                                                    LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001 )
                                                    DISPLAY list_benef_pros[c].fecha_vencimiento
                                                    DISPLAY "list_benef_pros[c].parentesco=abuelo padre abuela o madre ",list_benef_pros[c].fecha_vencimiento
                                                END IF
                                            END FOREACH
                                        ELSE 
                                            IF list_benef_pros[c].parentesco=70 OR list_benef_pros[c].parentesco=80 OR list_benef_pros[c].parentesco=71 OR list_benef_pros[c].parentesco=81 THEN
                                                 DISPLAY "vencimiento +18",vl_tipo_prorroga
                                                 LET list_benef_pros[c].fecha_vencimiento = MDY ( MONTH(list_benef_pros[c].fecha_nacimiento) , DAY(list_benef_pros[c].fecha_nacimiento), YEAR(list_benef_pros[c].fecha_nacimiento)+18 )
                                            END IF
                                             IF list_benef_pros[c].parentesco=30 OR list_benef_pros[c].parentesco=31 OR list_benef_pros[c].parentesco=40 OR list_benef_pros[c].parentesco=41 THEN
                                                        DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                                        LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                                                        #DISPLAY list_benef_pros[c].fecha_vencimiento
                                             END IF
                                             IF list_benef_pros[c].parentesco=50 OR list_benef_pros[c].parentesco=51 OR list_benef_pros[c].parentesco=60 OR list_benef_pros[c].parentesco=61 THEN
                                                        #DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                                        LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                                                        #DISPLAY list_benef_pros[c].fecha_vencimiento
                                             END IF
                                        END IF
                                        # (9) Orfandad (N/S/D)
                                        DISPLAY "TERMINO, " , b
                                        CASE
                                            WHEN (list_benef_pros[c].parentesco=70 OR list_benef_pros[c].parentesco=80)
                                                LET list_benef_pros[c].orfandad = "S"
                                                EXIT CASE
                                            WHEN (list_benef_pros[c].parentesco=71 OR list_benef_pros[c].parentesco=81)
                                                LET list_benef_pros[c].orfandad = "D"
                                                EXIT CASE
                                            OTHERWISE
                                                LET list_benef_pros[c].orfandad = "N"
                                                EXIT CASE
                                        END CASE    
                                        DISPLAY "Orfandad",list_benef_pros[c].orfandad
                                         # (10) Fecha de inicio de pagos
                                        LET sql_query0 = "SELECT count (*)
                                                         FROM fecha_fallecimiento 
                                                         WHERE num_issste=",vl_n_issste
                                        DISPLAY sql_query0
                                        PREPARE prp_0 FROM sql_query0
                                        EXECUTE prp_0  INTO valida_Fecha_M
                                        DISPLAY "valida_Fecha_M, ", valida_Fecha_M
                                        IF valida_Fecha_M = 0 THEN
                                            LET list_benef_pros[c].fecha_ini_pagos = list_benef_pros[c].fecha_ini_derechos                
                                            DISPLAY "Fecha de inicio de pagos",list_benef_pros[c].fecha_ini_derechos
                                        ELSE
                                            IF dia <= 300 AND anio_nacimiento >= anio_fallecimiento AND mes_nacimiento >= mes_fallecimiento  THEN 
                                                LET list_benef_pros[c].fecha_ini_pagos = list_benef[c].b_fecha_nac2
                                            ELSE
                                                LET list_benef_pros[c].fecha_ini_pagos = list_benef_pros[c].fecha_ini_derechos
                                            END IF
                                        END IF
                                        LET list_benef_pros[c].fecha_ini_pagos=validaFechaIniPagos(lintCveBeneficio,ldteFecTramite,list_benef_pros[c].fecha_ini_pagos) 
                                         # (11) Folio Identificador
                                        LET list_benef_pros[c].folio_id = vl_folio_id
                                        DISPLAY "Folio Identificador",vl_folio_id 
                                         # Verificar si hay que eliminar un registro
                                        IF OK_DELETE_ITEM = TRUE THEN
                                            CALL list_benef_pros.deleteElement(c)
                                            CALL list_benef.deleteElement(c)
                                            LET OK_DELETE_ITEM = FALSE
                                        ELSE
                                            
                                        END IF
                                        DISPLAY "SAO: Beneficiarios Cool",c
                                        LET n_issste_benef = list_benef[c].b_benefi
                                    END FOREACH
                                END FOREACH                                                      
                            END IF
                        END FOREACH
                    END IF      
                END FOREACH
            ELSE
                # (1) N�mero de seguridad social
                LET list_benef_pros[c].num_issste = vl_n_issste
                
                DISPLAY "benf",list_benef_pros[c].num_issste
                 
                 # (2) N�mero de solicitud
                LET list_benef_pros[c].num_solicitud = vl_num_solicitud
                DISPLAY "NUMERO DE SOLICITUD",list_benef_pros[c].num_solicitud
                 # (3) Nombre
                DISPLAY ">>>curp  ",curp
                DISPLAY ">>>n_issst_e  ",n_issst_e
                DISPLAY ">>>list_benef[i].b_curp2  ",list_benef[c].b_curp2
                LET list_benef_pros[c].nombre = list_benef[c].b_apellido_paterno2 CLIPPED," "||
                                            list_benef[c].b_apellido_materno2 CLIPPED," "||
                                            list_benef[c].b_nombre2 CLIPPED
                DISPLAY "Nombre: ",list_benef_pros[c].nombre
                #####SE VOLVIO A VALIDAR EL ESTATUS DE LOS BENEFICIARIOS YA QUE EN ESTE PUNTO VUELVE A IMPACTAR A LOS BENEFICIARIOS RVH
                 # (4) Parentesco
                LET list_benef_pros[c].parentesco=list_benef[c].b_parentesco_cve2
                 DISPLAY "Parentesco: ",list_benef[c].b_parentesco_cve2
                 # (5) Sexo (M/F)
                IF list_benef[c].b_sexo2 = "H" THEN
                    LET list_benef_pros[c].sexo = "M"
                ELSE
                    LET list_benef_pros[c].sexo = "F"
                END IF
                 DISPLAY "sexo",list_benef_pros[c].sexo
                 # (6) Fecha de nacimiento
                LET list_benef_pros[c].fecha_nacimiento = list_benef[c].b_fecha_nac2
                DISPLAY "Fecha de nacimiento",list_benef[c].b_fecha_nac2
                # (7) Fecha de inicio de derechoss
                DISPLAY "vl_n_issste, ;)",vl_n_issste -----Numero de Issste Directo
                DISPLAY "num_issste_b",n_issst_e      -----N�mero de Issste Beneficiario
                LET sql_query2 = "SELECT MAX (cve_beneficio) 
                                  FROM tramite_dt 
                                  WHERE no_issste_d =",vl_n_issste,"  and estatus_tramite <> 3"
                DISPLAY sql_query2
                PREPARE prp_211 FROM sql_query2
                EXECUTE prp_211 INTO cve_beneficio

                LET sql_query0 = "SELECT count (*)
                                 FROM fecha_fallecimiento 
                                 WHERE num_issste=",vl_n_issste
                DISPLAY sql_query0
                PREPARE prp_1011 FROM sql_query0
                EXECUTE prp_1011  INTO valida_Fecha_M
                DISPLAY "valida_Fecha_M, ", valida_Fecha_M
                IF valida_Fecha_M = 0 THEN
                    LET list_benef_pros[c].fecha_ini_derechos = vl_fec_ini_derechos
                    DISPLAY "Fecha de inicio de derechos",vl_fec_ini_derechos
                ELSE
                    LET sql_query = "SELECT fecha_fallecimiento
                                         FROM fecha_fallecimiento 
                                         WHERE num_issste=",vl_n_issste
                    DISPLAY sql_query
                    PREPARE prp_111 FROM sql_query
                    EXECUTE prp_111 INTO fecha_fallecimiento
                    DISPLAY "fecha_fallecimiento: ",fecha_fallecimiento
                    DISPLAY "list_benef[cont].fecha_nacimiento: ",list_benef[c].b_fecha_nac2
                    LET dia = Estandarizar_Meses_Periodo(fecha_fallecimiento,list_benef[c].b_fecha_nac2)
                    DISPLAY "TOTAL DE DIAS: ",dia
                    DISPLAY "EL BENEFICIO ES: ",cve_beneficio
                    LET anio_fallecimiento = YEAR(fecha_fallecimiento)
                    LET anio_nacimiento= YEAR(list_benef[c].b_fecha_nac2)
                    LET mes_fallecimiento = MONTH(fecha_fallecimiento)
                    LET mes_nacimiento= MONTH(list_benef[c].b_fecha_nac2)
                    DISPLAY "año_fallecimiento: ",anio_fallecimiento
                    DISPLAY "año_nacimiento: ",list_benef[c].b_fecha_nac2
                    ---pendiente OR cve_beneficio = 20 OR cve_beneficio = 1
                    IF cve_beneficio = 7  OR cve_beneficio = 9 OR cve_beneficio = 10 
                    OR cve_beneficio = 26 OR cve_beneficio = 40 OR cve_beneficio =429 OR cve_beneficio =430
                    OR cve_beneficio = 432 OR cve_beneficio =442 OR cve_beneficio =443 OR cve_beneficio =445 THEN
                        IF dia <= 300 AND anio_nacimiento >= anio_fallecimiento AND mes_nacimiento >= mes_fallecimiento  THEN 
                            display "ENTRO ;) 1"
                                LET list_benef_pros[c].fecha_ini_derechos = list_benef[c].b_fecha_nac2
                        ELSE
                            display "ENTRO ;) 2"
                            LET list_benef_pros[c].fecha_ini_derechos = vl_fec_ini_derechos
                        END IF
                        DISPLAY "list_benef[cont].fecha_ini_derechos , ;)",list_benef_pros[c].fecha_ini_derechos
                    ELSE
                        LET list_benef_pros[c].fecha_ini_derechos = vl_fec_ini_derechos
                    END IF    
                END IF
                # (8) Fecha de vencimiento
                LET benef1 = "select ito_id,ito_estado from indirecto where curp like '",list_benef[c].b_curp2,"' and nombre like '",list_benef[c].b_nombre2,"' and apellido_paterno like '",list_benef[c].b_apellido_paterno2,"'and fecha_nac = to_date ('",list_benef[c].b_fecha_nac2,"','%d/%m/%Y')"
                DISPLAY "benef1, ",benef1
                DECLARE cur_bene1 CURSOR FROM benef1
                FOREACH cur_bene1 INTO ito_id,ito_estado
                    DISPLAY "sin directo ito_id, ",ito_id,", ",c
                    DISPLAY "sin directo ito_estado, ",ito_estado,", ",c
                    LET verifica_prorroga1="SELECT count(*)  FROM prorroga WHERE ito_id =", ito_id
                    DISPLAY "verifica_prorroga1, ",verifica_prorroga1
                    DECLARE cur_prorro CURSOR FROM verifica_prorroga1
                    FOREACH cur_prorro INTO contador
                        IF contador<>0 THEN
                            LET verifica_prorroga="SELECT fecha_termino, u_version  FROM prorroga WHERE ito_id =", ito_id
                            DECLARE cur_prorro4 CURSOR FROM verifica_prorroga
                            FOREACH cur_prorro4 INTO vl_fec_prorroga,vl_tipo_prorroga
                                DISPLAY "vl_fec_prorroga, ",vl_fec_prorroga,", ",c
                                DISPLAY "vl_tipo_prorroga, ",vl_tipo_prorroga,", ",c
                                IF vl_fec_prorroga >= '31/12/2099' THEN
                                    DISPLAY "Cambio de Fecha 31/12/2099 a 01/01/0001"
                                    LET vl_fec_prorroga = '01/01/0001'
                                END IF
                                IF list_benef_pros[c].parentesco=70 OR list_benef_pros[c].parentesco=80 OR list_benef_pros[c].parentesco=71 OR list_benef_pros[c].parentesco=81 THEN
                                    CASE
                                        WHEN (vl_tipo_prorroga='S')
                                            DISPLAY "HOLA S vl_tipo_prorroga, ",vl_tipo_prorroga,", ",list_benef_pros[c].fecha_vencimiento
                                            LET list_benef_pros[c].fecha_vencimiento = vl_fec_prorroga
                                            EXIT CASE
                                        WHEN (vl_tipo_prorroga='T')
                                            DISPLAY "HOLA T vl_tipo_prorroga, ",vl_tipo_prorroga,", ",list_benef_pros[c].fecha_vencimiento
                                            LET list_benef_pros[c].fecha_vencimiento = vl_fec_prorroga
                                            EXIT CASE
                                        WHEN (vl_tipo_prorroga='P')
                                            DISPLAY "HOLA P vl_tipo_prorroga, ",vl_tipo_prorroga,", ",list_benef_pros[c].fecha_vencimiento
                                            LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                                            EXIT CASE
                                        WHEN list_benef[c].b_edad2 >= 18
                                            DISPLAY "SE BORRA JAJAJAJA ;( "
                                            LET OK_DELETE_ITEM = TRUE
                                            EXIT CASE
                                        OTHERWISE
                                            DISPLAY "vencimiento +18   1",vl_tipo_prorroga
                                            LET list_benef_pros[c].fecha_vencimiento = MDY ( MONTH(list_benef_pros[c].fecha_nacimiento) , DAY(list_benef_pros[c].fecha_nacimiento), YEAR(list_benef_pros[c].fecha_nacimiento)+18 )
                                            EXIT CASE
                                    END CASE 
                                END IF  
                                IF list_benef_pros[c].parentesco=30 OR list_benef_pros[c].parentesco=31 OR list_benef_pros[c].parentesco=40 OR list_benef_pros[c].parentesco=41 THEN
                                    DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                    LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                                END IF
                                IF list_benef_pros[c].parentesco=50 OR list_benef_pros[c].parentesco=51 OR list_benef_pros[c].parentesco=60 OR list_benef_pros[c].parentesco=61 THEN
                                    DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                    LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                                END IF
                            END FOREACH
                        ELSE
                            IF list_benef_pros[c].parentesco=70 OR list_benef_pros[c].parentesco=80 OR list_benef_pros[c].parentesco=71 OR list_benef_pros[c].parentesco=81 THEN
                                 LET list_benef_pros[c].fecha_vencimiento = MDY ( MONTH(list_benef_pros[c].fecha_nacimiento) , DAY(list_benef_pros[c].fecha_nacimiento), YEAR(list_benef_pros[c].fecha_nacimiento)+18 )
                                 DISPLAY "vencimiento +18  2",list_benef_pros[c].fecha_vencimiento
                            END IF
                            
                            IF list_benef_pros[c].parentesco=30 OR list_benef_pros[c].parentesco=31 OR list_benef_pros[c].parentesco=40 OR list_benef_pros[c].parentesco=41 THEN
                                DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                            END IF
                            IF list_benef_pros[c].parentesco=50 OR list_benef_pros[c].parentesco=51 OR list_benef_pros[c].parentesco=60 OR list_benef_pros[c].parentesco=61 THEN
                                DISPLAY "list_benef_pros[c].parentesco=esposo o esposa ",list_benef_pros[c].fecha_vencimiento
                                LET list_benef_pros[c].fecha_vencimiento = MDY (01,01,0001)
                            END IF
                        END IF
                        # (9) Orfandad (N/S/D)
                        DISPLAY "TERMINO, " , b
                        CASE
                            WHEN (list_benef_pros[c].parentesco=70 OR list_benef_pros[c].parentesco=80)
                                LET list_benef_pros[c].orfandad = "S"
                                EXIT CASE
                            WHEN (list_benef_pros[c].parentesco=71 OR list_benef_pros[c].parentesco=81)
                                LET list_benef_pros[c].orfandad = "D"
                                EXIT CASE
                            OTHERWISE
                                LET list_benef_pros[c].orfandad = "N"
                                EXIT CASE
                        END CASE    
                        DISPLAY "Orfandad",list_benef_pros[c].orfandad
                         # (10) Fecha de inicio de pagos
                        LET list_benef_pros[c].fecha_ini_pagos=validaFechaIniPagos(lintCveBeneficio,ldteFecTramite,ldteFechaIniPagos)             
                        DISPLAY "Fecha de inicio de pagos", ldteFechaIniPagos
                        DISPLAY "vl_folio_id , ", vl_folio_id,"  ,", list_benef_pros[c].folio_id
                         # (11) Folio Identificador
                        LET list_benef_pros[c].folio_id = vl_folio_id
                        DISPLAY "Folio Identificador",vl_folio_id
                         # Verificar si hay que eliminar un registro
                        IF OK_DELETE_ITEM = TRUE THEN
                            CALL list_benef_pros.deleteElement(c)
                            CALL list_benef.deleteElement(c)
                            LET OK_DELETE_ITEM = FALSE
                        ELSE
                        END IF
                        DISPLAY "SAO: Beneficiarios ",c
                    END FOREACH
                END FOREACH
            DISPLAY "SAO: Beneficiarios ",c
            END IF      
        END FOREACH
        IF (lintCveBeneficio = 1 OR lintCveBeneficio = 2 OR lintCveBeneficio = 3 OR lintCveBeneficio = 18 OR 
        lintCveBeneficio = 20) THEN
        --    LET list_benef_pros[c].fecha_ini_pagos = ldteFechaIniPagos                
       --     DISPLAY "Fecha de inicio de pagos por beneficio", ldteFechaIniPagos
        END IF
        LET c = c + 1   
        DISPLAY "C FINAL",c
    END FOR
END FUNCTION

FUNCTION obtener_desc(op, str)
    DEFINE op SMALLINT
    DEFINE str STRING
    CASE op
        WHEN 1
            CASE str
                WHEN "T"    RETURN 'TRABAJADOR'
                WHEN "P"    RETURN 'PENSIONADO'
                WHEN "TP"   RETURN 'TRABAJADOR PENSIONADO'
                WHEN "A"    RETURN 'ACTIVO'
                WHEN 'B'    RETURN 'BAJA' 
                WHEN 'F'    RETURN 'FALLECIDO'
            END CASE
        WHEN 2
            CASE str
                WHEN 'T'    RETURN 'CON SERVICIO MEDICO'
                WHEN 'F'    RETURN 'SIN SERVICIO MEDICO'
            END CASE 
        WHEN 3
            CASE str
                WHEN 'SD'   RETURN 'SIN DERECHOS' --No se env�a Mayores de edad solo con prorroga
                WHEN 'CD'   RETURN 'CONSERVACI�N DE DERECHOS'
                WHEN 'B'    RETURN 'BAJA'
                WHEN 'A'    RETURN 'VIGENTE'
                WHEN 'D'    RETURN 'DEUDO' -----NANCY R. 17/06/2013 
            END CASE        
    END CASE
    RETURN " "
END FUNCTION

--Calcula la edad 
FUNCTION calcula_edad(f_i,f_f)
    DEFINE f_i,f_f DATE
    DEFINE lintdiasDif,anios,lintDiasDes INT
    LET lintdiasDif=f_f-f_i
    LET lintDiasDes=(lintdiasDif/365)/4
    LET anios=(lintdiasDif-lintDiasDes)/365
    RETURN anios
END FUNCTION 


# *****************************************************************************#
# Nombre_funcion		f_val_50_of_hijos
# Nombre del equipo		ALDEBARAN
# Desarrollado_por		Santiago Hern�ndez Boxtho
# Fecha 			    Julio/2009
# Ultima_modificacion	Julio/2009
# Descripci�n			Funci�n que validad un grupo familiar si tiene 
#                       ascendientes e hijos entonces elimina a los ascendientes
#                       y permanece lso hijos.
# Entra                 list_benef      Lista de beneficiarios
# Salida                N/A
# *****************************************************************************#
FUNCTION f_val_50_of_hijos(list_benef)
    DEFINE list_benef DYNAMIC ARRAY OF RECORD
            num_issste DECIMAL(11,0),       
            num_solicitud SMALLINT,
            nombre VARCHAR(60),
            parentesco VARCHAR(2),
            sexo CHAR,
            fecha_nacimiento DATE,
            fecha_ini_derechos DATE,
            fecha_vencimiento DATE,
            orfandad CHAR,
            fecha_ini_pagos DATE,
            folio_id VARCHAR(11),
            benefi DECIMAL(11,0) -- LMLC 31/08/2015
    END RECORD
    DEFINE i, band_hijos SMALLINT
    LET band_hijos = FALSE
    IF list_benef.getLength()IS NOT NULL AND list_benef.getLength() > 0 AND 
      (list_benef[1].parentesco = 50 OR list_benef[1].parentesco = 51 OR list_benef[1].parentesco = 60 OR list_benef[1].parentesco = 61 )THEN
         -- Si hay Ascendientes (50,51,60,61) buscar si hay hijos ()
        FOR i = 2 TO list_benef.getLength()
            IF list_benef[i].parentesco = 70 OR list_benef[i].parentesco = 71 OR list_benef[i].parentesco = 80 OR list_benef[i].parentesco = 81 THEN
                LET band_hijos = TRUE
                EXIT FOR
            END IF
        END FOR
        -- Si hay hijos con ascendientes eliminar ascendientes
        IF band_hijos = TRUE THEN
            FOR i = 1 TO list_benef.getLength()
                IF list_benef[i].parentesco = 50 OR 
                   list_benef[i].parentesco = 51 OR 
                   list_benef[i].parentesco = 60 OR 
                   list_benef[i].parentesco = 61 THEN
                    CALL list_benef.deleteElement(i)
                    LET i = i - 1
                END IF
            END FOR
        END IF
    END IF
    
END FUNCTION


# *************************************************************************************************
# Nombre_funcion		formato_beneficiario
# Nombre del equipo		ALDEBARAN
# Desarrollado_por		Santiago Hern�ndez Boxtho
# Fecha 			    Enero/2009
# Ultima_modificacion	Julio/2009
# Descripci�n			Formato de la cadena para integrarlo al lote de beneficiarios
# Entrada               registro    registro de datos de un benficiario
# Salida                renglon     formato del registro para integrarlo en el lote del beneficiarios
# *************************************************************************************************
FUNCTION formato_beneficiario(beneficiario)
    DEFINE beneficiario  RECORD    # datos del beneficiario
        num_issste DECIMAL(11,0),       
        num_solicitud SMALLINT,
        nombre VARCHAR(60),
        parentesco VARCHAR(2),
        sexo CHAR,
        fecha_nacimiento DATE,
        fecha_ini_derechos DATE,
        fecha_vencimiento DATE,
        orfandad CHAR,
        fecha_ini_pagos DATE,
        folio_id VARCHAR(11),
        benefi DECIMAL(11,0) -- LMLC 31/08/2015
    END RECORD
    DEFINE fecha_ini_derechos2 DATE
    DEFINE renglon STRING
    LET fecha_ini_derechos2= beneficiario.fecha_ini_derechos -1
    
    LET renglon = completar_cadena('0',beneficiario.num_issste,11)
    LET renglon = renglon || completar_cadena('0',beneficiario.num_solicitud,2)
    LET renglon = renglon || completar_cadena(' ',beneficiario.nombre,60)
    LET renglon = renglon || completar_cadena('0',beneficiario.parentesco,2)
    LET renglon = renglon || completar_cadena(' ',beneficiario.sexo,1)
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_nacimiento)
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_ini_derechos)
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_vencimiento)
    LET renglon = renglon || completar_cadena(' ',beneficiario.orfandad,1)
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_ini_pagos)
    LET renglon = renglon || completar_cadena(' ',beneficiario.folio_id,11)
    LET renglon = renglon || completar_cadena('0',n_issste_benef,11)

    RETURN renglon
END FUNCTION

--fomato Benef con separador
FUNCTION formato_beneficiario_pipe(beneficiario)
    DEFINE beneficiario  RECORD    # datos del beneficiario
        num_issste DECIMAL(11,0),       
        num_solicitud SMALLINT,
        nombre VARCHAR(60),
        parentesco VARCHAR(2),
        sexo CHAR,
        fecha_nacimiento DATE,
        fecha_ini_derechos DATE,
        fecha_vencimiento DATE,
        orfandad CHAR,
        fecha_ini_pagos DATE,
        folio_id VARCHAR(11),
        benefi DECIMAL(11,0) -- LMLC 31/08/2015
    END RECORD
    DEFINE fecha_ini_derechos2 DATE
    DEFINE renglon STRING
    DEFINE lstrseparador STRING
    
    LET lstrseparador='|'
    LET renglon=''
    
    LET fecha_ini_derechos2= beneficiario.fecha_ini_derechos -1
    LET renglon = completar_cadena('0',beneficiario.num_issste,11) ||lstrseparador
    LET renglon = renglon || completar_cadena('0',beneficiario.num_solicitud,2) ||lstrseparador
    LET renglon = renglon || completar_cadena(' ',beneficiario.nombre,60) ||lstrseparador
    LET renglon = renglon || completar_cadena('0',beneficiario.parentesco,2) ||lstrseparador
    LET renglon = renglon || completar_cadena(' ',beneficiario.sexo,1) ||lstrseparador
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_nacimiento) ||lstrseparador
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_ini_derechos) ||lstrseparador
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_vencimiento) ||lstrseparador
    LET renglon = renglon || completar_cadena(' ',beneficiario.orfandad,1)||lstrseparador
    LET renglon = renglon || fechaTOstr(beneficiario.fecha_ini_pagos)||lstrseparador
    LET renglon = renglon || completar_cadena(' ',beneficiario.folio_id,11)||lstrseparador
    LET renglon = renglon || completar_cadena('0',n_issste_benef,11)

    RETURN renglon
END FUNCTION



### Estandariza MESES a 30 dias y ANIOS a 360 dias. 
FUNCTION Estandarizar_Meses_Periodo(fecha_inicial, fecha_final)
    DEFINE fecha_inicial, fecha_final DATE
    DEFINE dias_tiempo_estandar INTEGER
    DEFINE fecha_auxiliar DATE
    DEFINE mes_inicial, mes_final, meses_diferencia INTEGER
    DEFINE dia_inicial, dia_final, dias_diferencia INTEGER
    
    INITIALIZE fecha_auxiliar TO NULL
    INITIALIZE mes_inicial, mes_final, meses_diferencia TO NULL
    INITIALIZE dia_inicial, dia_final, dias_diferencia TO NULL
    LET dias_tiempo_estandar = 0
    
    ### Acomodar el orden de fechas si la fecha inicial 
    ### es m�s vieja que la fecha final.
    IF fecha_inicial > fecha_final THEN
        LET fecha_auxiliar = fecha_inicial
        LET fecha_inicial = fecha_final
        LET fecha_final = fecha_auxiliar
        ---ayuda_revision---DISPLAY "Acomodo fechas............."
    END IF
    
    ---ayuda_revision---DISPLAY "fecha_final: ", fecha_final
    ---Obtrener los meses de las fechas y su diferencia.
    LET mes_inicial = MONTH(fecha_inicial)
    LET mes_final = MONTH(fecha_final)
    LET meses_diferencia = mes_final - mes_inicial
    ---Obtrener los dias de las fechas y su diferencia.
    LET dia_inicial = DAY(fecha_inicial)
    LET dia_final = DAY(fecha_final)
    LET dias_diferencia = dia_final - dia_inicial

    IF mes_inicial = mes_final AND YEAR(fecha_inicial) = YEAR(fecha_final) THEN
        IF mes_inicial = 1 OR mes_inicial = 2 OR mes_inicial = 3 OR mes_inicial = 5 OR mes_inicial = 7 OR mes_inicial = 8 OR mes_inicial = 10 OR mes_inicial = 12 THEN
            CASE
                WHEN mes_inicial = 2 AND dia_final < 28 ---<--- Compensar mes y cerrar fecha inicial.
                    LET dia_final = dia_final

                WHEN mes_inicial = 2 AND dia_final >= 28
                    LET fecha_final = fecha_final + 1
                    IF NOT( mes_final = MONTH(fecha_final) ) THEN
                        IF dia_final = 28 THEN
                            LET dia_final = dia_final + 2
                        ELSE ---<--- DEBE SER BISIESTO (29/FEB) -------
                            LET dia_final = dia_final + 1
                        END IF
                    END IF
                    LET fecha_final = fecha_final - 1
                    
                WHEN mes_inicial <> 2 AND dia_final <= 30 ---<--- Compensar mes y cerrar fecha inicial.
                    LET dia_final = dia_final

                WHEN mes_inicial <> 2 AND dia_final = 31
                    LET dia_final = 30
            END CASE
        {ELSE
            LET dia_final = dia_final}
        END IF
        
        IF DAY(fecha_inicial) = DAY(fecha_final) THEN
            LET dias_tiempo_estandar = 1
        ELSE
            LET dias_tiempo_estandar = (dia_final - dia_inicial) + 1
        END IF
        ---ayuda_revision---DISPLAY "Fecha inicial MOVIDA y final IGUAL: ", fecha_inicial, " - ", fecha_final
    ELSE
        IF mes_inicial = 1 OR mes_inicial = 2 OR mes_inicial = 3 OR mes_inicial = 5 OR mes_inicial = 7 OR mes_inicial = 8 OR mes_inicial = 10 OR mes_inicial = 12 THEN
            CASE
                WHEN mes_inicial = 2 AND dia_inicial < 28 ---<--- Compensar mes y cerrar fecha inicial.
                    LET fecha_inicial = fecha_inicial + ( (28 - dia_inicial) + 1 )
                    ---ayuda_revision---DISPLAY "< FEB-28 / +1: ", fecha_inicial
                    IF mes_inicial = MONTH(fecha_inicial) THEN ---<--- DEBE SER BISIESTO (29/FEB) -------
                        LET dias_tiempo_estandar = dias_tiempo_estandar + 1
                        LET fecha_inicial = fecha_inicial + 1
                        ---ayuda_revision---DISPLAY "FEB LIM BIS: ", fecha_inicial
                    END IF
                    LET dias_tiempo_estandar = (30 - dia_inicial) + 1
                    ---ayuda_revision---DISPLAY "------ fecha_inicial:", fecha_inicial

                WHEN mes_inicial = 2 AND dia_inicial >= 28
                    LET dias_tiempo_estandar = (30 - dia_inicial) + 1
                    LET fecha_inicial = fecha_inicial + 1
                    IF mes_inicial = MONTH(fecha_inicial) AND DAY(fecha_inicial) = 29 THEN ---<--- DEBE SER BISIESTO (29/FEB) -------
                        ---LET dias_tiempo_estandar = dia_inicial + 1
                        LET fecha_inicial = fecha_inicial + 1
                        ---ayuda_revision------DISPLAY "LIM1---29: ", dias_tiempo_estandar
                    {ELSE
                        LET dias_tiempo_estandar = dias_tiempo_estandar + 2
                        LET fecha_inicial = fecha_inicial + 1 --- Pasar al sig. mes.}
                    END IF
                    ---ayuda_revision------DISPLAY "LIM1(FEB>=28): ", dias_tiempo_estandar

                WHEN mes_inicial <> 2 AND dia_inicial <= 30 ---<--- Compensar mes y cerrar fecha inicial.
                    LET dias_tiempo_estandar = (30 - dia_inicial) + 1
                    LET fecha_inicial = fecha_inicial + (31 - dia_inicial) + 1 --- Pasar al sig. mes.

                WHEN mes_inicial <> 2 AND dia_inicial = 31
                    LET dias_tiempo_estandar = 1
                    LET fecha_inicial = fecha_inicial + 1 --- Pasar al sig. mes.
            END CASE
        ELSE
            LET dias_tiempo_estandar = (30 - dia_inicial) + 1
            LET fecha_inicial = fecha_inicial + (30 - dia_inicial) + 1
        END IF
        
        IF fecha_inicial < fecha_final THEN
            IF mes_final = 1 OR mes_final = 2 OR mes_final = 3 OR mes_final = 5 OR mes_final = 7 OR mes_final = 8 OR mes_final = 10 OR mes_final = 12 THEN
                CASE
                    WHEN mes_final = 2 AND dia_final < 28
                        LET dias_tiempo_estandar = dias_tiempo_estandar + dia_final

                    WHEN mes_final = 2 AND dia_final >= 28
                        LET fecha_final = fecha_final + 1
                        IF NOT( mes_final = MONTH(fecha_final) ) THEN
                            ---ayuda_revision------DISPLAY "LIM2:::"
                            IF dia_final = 28 THEN
                                LET dias_tiempo_estandar = dias_tiempo_estandar + dia_final + 2
                                ---ayuda_revision------DISPLAY "LIM2---28: ", fecha_final, dias_tiempo_estandar
                            ELSE ---<--- DEBE SER BISIESTO (29/FEB) -------
                                LET dias_tiempo_estandar = dias_tiempo_estandar + dia_final + 1
                                ---ayuda_revision------DISPLAY "LIM2---29: ", fecha_final, dias_tiempo_estandar
                            END IF
                        ELSE
                            LET dias_tiempo_estandar = dias_tiempo_estandar + dia_final
                            ---ayuda_revision------DISPLAY "dias_tiempo_estandar + dia_final", dias_tiempo_estandar, dia_final
                        END IF
                        LET fecha_final = fecha_final - 1

                    WHEN mes_final <> 2 AND dia_final <= 30
                        LET dias_tiempo_estandar = dias_tiempo_estandar + dia_final

                    WHEN mes_final <> 2 AND dia_final = 31
                        LET dias_tiempo_estandar = dias_tiempo_estandar + 30
                END CASE
            ELSE
                LET dias_tiempo_estandar = dias_tiempo_estandar + dia_final
            END IF
            LET fecha_final = fecha_final - dia_final + 1
        ELSE
            IF fecha_inicial = fecha_final THEN
                LET dias_tiempo_estandar = dias_tiempo_estandar + 1
            END IF
        END IF
        
        ---ayuda_revision------DISPLAY "Fecha inicial MOVIDA y final IGUAL: ", fecha_inicial, " - ", fecha_final
        WHILE fecha_inicial < fecha_final ---AND NOT(  MONTH(fecha_inicial) = MONTH(fecha_final) ) AND NOT(  YEAR(fecha_inicial) = YEAR(fecha_final) )
            LET dias_tiempo_estandar = dias_tiempo_estandar + 30
            LET fecha_inicial = fecha_inicial + INTERVAL(1) MONTH TO MONTH
            ---DISPLAY "MES+: ", fecha_inicial, " | dias_tiempo_estandar: ", dias_tiempo_estandar
        END WHILE
    END IF
    
    ---ayuda_revision------DISPLAY ">>>", dias_tiempo_estandar
    ---ayuda_revision------DISPLAY "Fecha inicial MOVIDA y final IGUAL: ", fecha_inicial, " - ", fecha_final
        
    RETURN dias_tiempo_estandar
END FUNCTION

--Validacion de los 5 anios fecha inicio de pagos
FUNCTION validaFechaIniPagos(lsmiCveBeneficio,ldteFechaTramite,ldteFecIniPago)
    DEFINE lsmiCveBeneficio SMALLINT
    DEFINE ldteFechaTramite DATE
    DEFINE ldteAuxFecIniPag DATE
    DEFINE ldteFecIniPago DATE

            IF lsmiCveBeneficio=9 OR lsmiCveBeneficio=26 OR lsmiCveBeneficio=40 THEN
                LET ldteAuxFecIniPag=MDY( MONTH(ldteFechaTramite),DAY(ldteFechaTramite),YEAR(ldteFechaTramite)-5)
                IF ldteFecIniPago < ldteAuxFecIniPag THEN
                    LET ldteFecIniPago = ldteAuxFecIniPag
                END IF
            END IF  
   RETURN  ldteFecIniPago
END FUNCTION 


FUNCTION dias_cot1(lde_num_issste)
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
               "    AND (c_modalidad.pensiones   = 'T')", --CNSF NO se ocupa
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
          LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos1(arr_tci[i].fi, arr_tci[i].ft)
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
             LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos1(arr_tci[ii].ft+1, arr_tci[i].ft)
             LET ii = i  
             LET ttdias = ttdias + tdias
             LET tdias = 0
          END IF
          IF arr_tci[i].fi >= arr_tci[ii].ft AND arr_tci[i].ft > arr_tci[ii].ft THEN
             LET tdias = (arr_tci[i].ft - arr_tci[i].fi) + 1
             LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos1(arr_tci[i].fi, arr_tci[i].ft)
             LET ii = i
             LET ttdias = ttdias + tdias
             LET tdias = 0
          END IF
       END IF
    END FOR  
    CALL cal_mdy221(ttdias)  RETURNING  anios, meses, dias 

     RETURN ttdias
     
  
END FUNCTION

FUNCTION f_DiasporBisiestos1(ldt_fecha_inicio, ldt_fecha_fin)
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
        IF fac_ad_bisiesto11(lsi_anio) THEN
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

FUNCTION cal_mdy221(li_dias)                     
DEFINE   li_dias, anios, meses, dias INTEGER
    LET anios = li_dias/360
    LET meses = (li_dias - (anios*360))/30
    LET dias = li_dias - (anios*360) - (meses*30)

    RETURN anios, meses, dias                   
END FUNCTION 


FUNCTION fac_ad_bisiesto11(li_anio)  	
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