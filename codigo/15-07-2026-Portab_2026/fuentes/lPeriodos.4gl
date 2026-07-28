DATABASE dsipe

GLOBALS
   DEFINE bandMin, bandMax, bandInt, ano_val, vci, i,x,aux1,aux2,  j, p,   
          tdias, total_dias, cta, tot, tdias_arr, total_dias_arr, dias_tomar, sw, diasaux
          SMALLINT

   DEFINE pag_fec_alta, pag_fec_baja,fechaaux_ini,fechaaux_fin,fecha_inin,fecha_tern, new_ft
          DATE

   DEFINE lc_sql, ls_query, ls_query_1    STRING


   DEFINE v_curp   CHAR(18)
          
   DEFINE tiempo   CHAR(20)

   DEFINE ls_importe_sm, ls_importe_uma , sdo_max_sm,  sdo_max_uma, sueldo,
          g_dias_desc
          decimal(12,2)

   DEFINE r_sm RECORD LIKE c_salario_min.*
   DEFINE r_uma RECORD LIKE cat_uma.*
   DEFINE lar_salarios DYNAMIC ARRAY OF RECORD LIKE c_salario_min.*

   DEFINE r_ci RECORD 
        rfi    LIKE cuenta_ind.fecha_inicio,
        rft    LIKE cuenta_ind.fecha_termino,
        rsdo   LIKE cuenta_ind.sueldo_issste
   END RECORD 

   DEFINE arr_tci   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD

      DEFINE arr_tci_Aux   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD

   DEFINE arr_periodos_armados   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD

   DEFINE arr   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD

  DEFINE periodo  RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
  END RECORD

   DEFINE total_per   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo,
       dias    SMALLINT,
       tdias   INT,
       marca   SMALLINT
   END RECORD

DEFINE msi_diasporBisiestos SMALLINT
DEFINE lfolio_solicitud INTEGER
DEFINE lid_robusta INTEGER
DEFINE lnum_issste DECIMAL(10,2)
DEFINE lip_maquina STRING
DEFINE lusuario STRING
DEFINE lcomponente STRING

END GLOBALS


FUNCTION integra_periodos_IMSS(ffolio_solicitud, fid_robusta, ffnum_issste, ffip_maquina, ffusuario, ffcomponente)
    DEFINE ffolio_solicitud INTEGER
    DEFINE fid_robusta INTEGER
    DEFINE ffnum_issste DECIMAL(10,2)
    DEFINE ffip_maquina STRING
    DEFINE ffusuario STRING
    DEFINE ffcomponente STRING

    DEFINE ls_existe   INTEGER

   LET lfolio_solicitud = ffolio_solicitud
   LET lid_robusta      = fid_robusta
   LET lnum_issste      = ffnum_issste
   LET lip_maquina      = ffip_maquina
   LET lusuario         = ffusuario
   LET lcomponente      = ffcomponente

   INITIALIZE arr_tci TO NULL

  ----------- CUENTA INDIVIDUAL ---------------
  DECLARE cur03 CURSOR FOR

   SELECT cei_td_ws3_robusta_periodos.fecha_inicio, 
          cei_td_ws3_robusta_periodos.fecha_termino, 
          cei_td_ws3_robusta_periodos.sueldo 
     FROM cei_td_ws3_robusta_periodos
     WHERE cei_td_ws3_robusta_periodos.folio_solicitud = ffolio_solicitud
       AND cei_td_ws3_robusta_periodos.id_robusta = fid_robusta
    ORDER BY cei_td_ws3_robusta_periodos.fecha_inicio 

    LET vci = 1

    FOREACH cur03 INTO arr_tci[vci].*
       IF arr_tci[vci].sdo = 0 OR arr_tci[vci].sdo IS NULL THEN
          LET arr_tci[vci].sdo = 0.75
       END IF
       IF (ls_existe != 0) THEN ELSE 
           --display arr_tci[vci].fi, " ",arr_tci[vci].ft, " ",arr_tci[vci].sdo
         LET vci = vci + 1
       END IF
       
    END FOREACH
    CALL arr_tci.deleteElement(vci)
    LET vci = vci - 1
    
    CALL peridos()

END FUNCTION 


FUNCTION UMA()
    LET ls_importe_uma = 0
    LET ls_query_1 = "SELECT first 1 importe FROM cat_uma ",
                     " WHERE componente_cve = 'UMA' ",
                     "   AND year(fecha_alta) = ",year(arr[p].fi)

    PREPARE pp01 FROM ls_query_1
    EXECUTE pp01 INTO ls_importe_uma

    LET sdo_max_uma = ls_importe_uma * 10

END FUNCTION

FUNCTION peridos()
    DEFINE a,isTraslape,noHayTraslape BOOLEAN
    DEFINE indiceTraslape, contadorAux SMALLINT
    DEFINE rcei_td_ws3_robusta_periodos_issste RECORD LIKE cei_td_ws3_robusta_periodos_issste.*
    DEFINE SQL1 STRING
    DEFINE lid_periodo_issste INTEGER
    DEFINE lcin_id BIGINT
    
    LET noHayTraslape = FALSE 
    LET contadorAux = 1


    --display "Identificapos periodos traslapados y los metemos a un arreglo"
    WHILE (noHayTraslape == FALSE) 
        FOR x=1 TO arr_tci.getLength()
            CALL f_verifica_traslape_movimiento(x,arr_tci[x].*) RETURNING isTraslape, indiceTraslape
            IF isTraslape THEN
                EXIT FOR
            ELSE
                IF x >= arr_tci.getLength() THEN 
                    LET noHayTraslape= TRUE
                    EXIT FOR  
                ELSE 
                    LET noHayTraslape= FALSE 
                END IF 
            END IF 
        END FOR

        FOR i = 1 TO arr_tci.getLength()
          --DISPLAY "%", arr_tci[i].fi ||" "|| arr_tci[i].ft||" "||arr_tci[i].sdo
        END FOR 
    END WHILE 


    #SE saca el sueldo por mes 
    FOR i = 1 TO arr_tci.getLength()
        LET arr_tci[i].sdo = arr_tci[i].sdo * 30
        --display "sdoxmes:", arr_tci[i].fi ||" "|| arr_tci[i].ft||" "||arr_tci[i].sdo
    END FOR 

  # Se procesan los registros con los topes maximos y topes minimos
  FOR i = 1 TO arr_tci.getLength()
  	LET bandInt = 0
	LET bandMax = 0 
	LET bandMin = 0

    --display i, " - ", arr_tci[i].fi ||" - "|| arr_tci[i].ft||" - "||arr_tci[i].sdo
  

      IF NOT f_salario_en_rango(arr_tci[i].*)   THEN
        LET bandMax = 1 
        CALL f_corrige_sueldo_maximo(i,arr_tci[i].sdo)
        LET bandMin = 0
        LET bandInt = 0 
        LET bandMax = 0
      ELSE 							
        IF f_salario_en_rango_min(arr_tci[i].fi,arr_tci[i].ft,arr_tci[i].sdo)== FALSE THEN
            LET bandMin = 1
            CALL f_corrige_sueldo_maximo(i,arr_tci[i].sdo)
            LET bandMin = 0
            LET bandInt = 0
            LET bandMax = 0
        ELSE
            IF  f_salario_en_rango_minmax(arr_tci[i].fi, arr_tci[i].ft,arr_tci[i].sdo)=  FALSE THEN
                LET bandInt = 1      
                CALL f_corrige_sueldo_maximo(i,arr_tci[i].sdo)
                LET bandMin = 0
                LET bandInt = 0
                LET bandMax = 0
            END IF
        END IF
   END IF
    DISPLAY "Fin for"
    DISPLAY arr_tci[i].fi ||" "|| arr_tci[i].ft||" "||arr_tci[i].sdo
  END FOR  


  CREATE TEMP TABLE arch
     (fi      DATE,
      ft      DATE,
      sdo     decimal(13,2) 
      )

  FOR i = 1 TO arr_tci.getLength()
      INSERT INTO arch values (arr_tci[i].fi,arr_tci[i].ft,arr_tci[i].sdo)
  END FOR 

   display "========================================================="

   LET SQL1 = "\n SELECT dias_descontados-dias_reintegrados",
              "\n   FROM cei_td_ws3_robusta",
              "\n  WHERE folio_solicitud = ", lfolio_solicitud --2298 --2930
   PREPARE select_dias_descontados FROM SQL1
   EXECUTE select_dias_descontados INTO g_dias_desc

   IF g_dias_desc < 0 THEN
       LET g_dias_desc = 0
    END IF


   DECLARE c2 CURSOR FOR
   SELECT *
    FROM arch
   ORDER BY 1
   FOREACH c2 INTO r_ci.* 
       LET tdias = (r_ci.rft - r_ci.rfi) + 1
       LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(r_ci.rfi, r_ci.rft)
       LET total_dias = total_dias + tdias
       display "#", r_ci.rfi,"  ",r_ci.rft,"  ",r_ci.rsdo, "  ", tdias, "  ", total_dias
   END FOREACH 
   display " total_dias ",  total_dias 
   DISPLAY "==================================="

   DECLARE c1 CURSOR FOR
   SELECT *
    FROM arch
   ORDER BY 1

   LET tot = 1
   LET  sw = 0 
   LET total_dias =  0
   LET tdias = 0
   FOREACH c1 INTO r_ci.* 

       LET total_per[tot].fi = r_ci.rfi
       LET total_per[tot].ft = r_ci.rft
       LET total_per[tot].sdo = r_ci.rsdo

       LET tdias = (r_ci.rft - r_ci.rfi) + 1
       LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(r_ci.rfi, r_ci.rft)
       LET total_dias = total_dias + tdias


       LET tdias_arr = (total_per[tot].ft - total_per[tot].fi) + 1
       LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(total_per[tot].fi, total_per[tot].ft)
       LET total_per[tot].dias = tdias_arr


       IF  g_dias_desc = 0 THEN
           LET total_per[tot].marca = ""
       ELSE
          IF total_dias = g_dias_desc THEN
               LET  sw = 1
               --LET tot = tot
               LET total_per[tot].marca = "411"
          ELSE 
             display "%", dias_tomar , "  ", diasaux , "  ", g_dias_desc, "  ", tot, "    ",total_dias, " ", tdias
           IF total_dias >= g_dias_desc AND sw = 0 THEN 

               LET dias_tomar = g_dias_desc - (diasaux + 1) -- se agrega +1 por la diferencia entre fechas, validar al 20250307
               display "!", dias_tomar , "  ", diasaux , "  ", g_dias_desc, "  ", tot
               -- Se respalda ft en el siguiete perido
               LET total_per[tot+1].ft = total_per[tot].ft 

               -- Corte del Primer periodo 
               --LET total_per[tot].ft = total_per[tot].fi + g_dias_desc
               LET total_per[tot].sdo = total_per[tot].sdo
               LET total_per[tot].marca = "411"
    
               -- Fecha del segundo periodo
               --display "total_per[tot+1].ft ", total_per[tot+1].ft 
               LET total_per[tot].ft = (total_per[tot].fi + dias_tomar)
               --display "total_per[tot+1].ft ", total_per[tot+1].ft 
               LET total_per[tot+1].fi = total_per[tot].ft + 1
               LET total_per[tot+1].sdo = total_per[tot].sdo 
               LET total_per[tot+1].marca = ""
    
               -- Sumatoria de dias del primer perido
               LET total_per[tot].dias = (total_per[tot].ft - total_per[tot].fi) 
               LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(total_per[tot].fi, total_per[tot].ft)

               -- Sumatoria de dias del arreglo + 1 
               LET total_per[tot+1].dias = (total_per[tot+1].ft - total_per[tot+1].fi) + 2
               LET msi_diasporBisiestos = msi_diasporBisiestos + f_DiasporBisiestos(total_per[tot+1].fi, total_per[tot+1].ft)
    

               LET  sw = 1 
               LET tot = tot + 1
           ELSE
               LET diasaux = diasaux + tdias
               IF sw = 0 THEN
                  LET total_per[tot].marca = "411"
               END IF 
           END IF 
          END IF 
       END IF 

       LET tot = tot + 1
   END FOREACH

   DISPLAY "=================================== dias descontados ",g_dias_desc
   FOR i = 1 TO total_per.getLength()
      DISPLAY total_per[i].fi, "   ", total_per[i].ft,"  ",total_per[i].sdo, "  ", total_per[i].dias, "  ", total_per[i].tdias, "  ",total_per[i].marca
      
      LET SQL1 = "SELECT NVL(MAX(id_periodo_issste),0) + 1",
                 "  FROM cei_td_ws3_robusta_periodos_issste",
                 " WHERE folio_solicitud = ", lfolio_solicitud
      PREPARE insert_cei_td_ws3_robusta_periodos_issste_00 FROM SQL1
      EXECUTE insert_cei_td_ws3_robusta_periodos_issste_00 INTO lid_periodo_issste

      LET rcei_td_ws3_robusta_periodos_issste.fecha_inicio      = total_per[i].fi
      LET rcei_td_ws3_robusta_periodos_issste.fecha_termino     = total_per[i].ft
      LET rcei_td_ws3_robusta_periodos_issste.folio_solicitud   = lfolio_solicitud
      LET rcei_td_ws3_robusta_periodos_issste.id_periodo_issste = lid_periodo_issste
      LET rcei_td_ws3_robusta_periodos_issste.num_ramo          = 637
      LET rcei_td_ws3_robusta_periodos_issste.num_pagaduria     = "70000"
      LET rcei_td_ws3_robusta_periodos_issste.sueldo            = total_per[i].sdo

      LET SQL1 = " INSERT INTO cei_td_ws3_robusta_periodos_issste(",
                       " id_periodo_issste,",
                       " folio_solicitud,",
                       " fecha_inicio,",
                       " fecha_termino,",
                       " num_ramo,",
                       " num_pagaduria,",
                       " sueldo,",
                       " marca,",
                       " id_robusta",
                       ")",
                " VALUES (",
                         rcei_td_ws3_robusta_periodos_issste.id_periodo_issste
                      , ", ", rcei_td_ws3_robusta_periodos_issste.folio_solicitud
                      , ", '", rcei_td_ws3_robusta_periodos_issste.fecha_inicio, "'"
                      , ", '", rcei_td_ws3_robusta_periodos_issste.fecha_termino, "'"
                      , ", ", rcei_td_ws3_robusta_periodos_issste.num_ramo
                      , ", '", rcei_td_ws3_robusta_periodos_issste.num_pagaduria, "'"
                      , ", ", rcei_td_ws3_robusta_periodos_issste.sueldo
                      , ", '", total_per[i].marca CLIPPED, "'"
                      , ", ", lid_robusta
                      , ")"
        PREPARE insert_cei_td_ws3_robusta_periodos_issste_01 FROM SQL1
        EXECUTE insert_cei_td_ws3_robusta_periodos_issste_01

        LET lcin_id = max_cin_id_cuenta_ind()

        --IF total_per[i].marca IS NOT NULL THEN
            LET SQL1 = " INSERT INTO cuenta_ind(",
                                   " num_ramo,",
                                   " num_pagaduria,",
                                   " num_issste,",
                                   " cin_id,",
                                   " u_version,",
                                   " mod_total_par,",
                                   " mod_cve,",
                                   " fecha_inicio,",
                                   " fecha_termino,",
                                   " t_movto_inicio,",
                                   " t_movto_cierre,",
                                   " periodo_afecta,",
                                   " sueldo_issste,"
        IF total_per[i].marca IS NOT NULL AND length(total_per[i].marca) > 0 THEN
                  LET SQL1 = SQL1, " uso_pen,"
        END IF
                  LET SQL1 = SQL1, " dias_licencia,",
                                   " usuario,",
                                   " fecha_aud,",
                                   " hora_aud,",
                                   " componente_cve,",
                                   " ip_maquina",
                                   ")",
                       " VALUES (",
                                 "  '637'",
                                 ", '70000'",
                                 ", ", lnum_issste,
                                 ", ", lcin_id,
                                 ", '1'",
                                 ", 'E'",
                                 ", 12",
                                 ", '", rcei_td_ws3_robusta_periodos_issste.fecha_inicio, "'",
                                 ", '", rcei_td_ws3_robusta_periodos_issste.fecha_termino, "'",
                                 ", 'A'",
                                 ", 'B'",
                                 ", 0",
                                 ", ", rcei_td_ws3_robusta_periodos_issste.sueldo
        IF total_per[i].marca IS NOT NULL AND length(total_per[i].marca) > 0 THEN
                LET SQL1 = SQL1, ", '", total_per[i].marca CLIPPED, "'"
        END IF
                LET SQL1 = SQL1, ", 0",
                                 ", '",lusuario, "'",
                                 ", '", TODAY, "'",
                                 ", '", CURRENT HOUR TO SECOND, "'",
                                 ", '", lcomponente, "'",
                                 ", '", lip_maquina,"'",
                                ")"
            --DISPLAY "lnum_issste: ", lnum_issste
            --DISPLAY "SQL1 Insertar_cuenta_individual", SQL1
            PREPARE insert_into_cuenta_ind_periodos_imss FROM SQL1
            EXECUTE insert_into_cuenta_ind_periodos_imss
        --END IF
   END FOR

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

FUNCTION f_salario_en_rango_minmax(fecha_inicio,fecha_termino, sueldo)
	DEFINE fecha_inicio, ldt_fecha_ini LIKE cuenta_ind.fecha_inicio,
			fecha_termino,ldt_fecha_fin LIKE cuenta_ind.fecha_termino,
			sueldo,menor_seis LIKE cuenta_ind.sueldo_issste,
			fecha_aux,fecha_auxt, fecha_valida DATE,
			qrySalMin STRING,
			 --tope_maximo{,tope_minimo} LIKE c_salario_min.importe,
			c1,c2,c_per, ls_band_periodo SMALLINT,
			tope DYNAMIC ARRAY OF RECORD 
				minimo LIKE cuenta_ind.sueldo_issste,
				maximo LIKE cuenta_ind.sueldo_issste
			END RECORD,
			li_bandSalMinMax BOOLEAN,
            ld_fecha_auxbus DATE
	LET c1 = 1
	LET c2 = 1
	LET c_per = 0
	LET ls_band_periodo = 0
	LET ldt_fecha_ini = "01/01/"||YEAR(fecha_inicio)
	LET ldt_fecha_fin = "31/12/"||YEAR(fecha_termino)
	LET fecha_aux = "01/02/2017"
	LET fecha_auxt = "31/01/2017"
	LET li_bandSalMinMax = TRUE

    -- INICIO INFOTEC TK - 2023023251 GARANTIA
	LET qrySalMin = "SELECT COUNT(*) FROM c_salario_min \n"
	LET qrySalMin = qrySalMin CLIPPED, "WHERE zon_cve = 'A'\n"
	LET qrySalMin = qrySalMin CLIPPED, "AND YEAR(fecha_alta) = "CLIPPED, YEAR(fecha_inicio)
	
	PREPARE prpSalMin3 FROM qrySalMin
	EXECUTE prpSalMin3 INTO c_per
	--display "CANTIDAD DE PERIODOS ANIO ::>>>",c_per,"<<<<<<"
	-- FIN INFOTEC TK - 2023023251 GARANTIA
    IF (ldt_fecha_ini IS NOT NULL OR ldt_fecha_ini CLIPPED != "") AND (fecha_auxt IS NOT NULL OR fecha_auxt CLIPPED != "")
        AND (sueldo IS NOT NULL OR sueldo CLIPPED != "") THEN 
        IF fecha_inicio < fecha_aux THEN  -- para ver si es UMA 01/02/2017
			-- INICIO INFOTEC TK - 2023023251 GARANTIA
			IF c_per > 1 THEN
				LET ldt_fecha_ini = fecha_inicio
			ELSE
				LET qrySalMin = "SELECT FIRST 1 fecha_alta FROM c_salario_min \n"
				LET qrySalMin = qrySalMin CLIPPED, " WHERE YEAR(fecha_alta) = " CLIPPED, YEAR(fecha_inicio)
				LET qrySalMin = qrySalMin CLIPPED, " AND zon_cve = 'A' "
				
				PREPARE prpSalMin4 FROM qrySalMin
				EXECUTE prpSalMin4 INTO fecha_valida

				IF fecha_valida > fecha_inicio THEN
					LET ls_band_periodo = 1
				END IF
			END IF
			-- FIN INFOTEC TK - 2023023251 GARANTIA
            --CALL tope.clear()
            {LET qrySalMin = "SELECT importe FROM c_salario_min WHERE zon_cve = 'A' AND fecha_alta IN (  ",
                            " SELECT (fecha_alta) FROM c_salario_min WHERE fecha_alta BETWEEN '"CLIPPED, fecha_inicio CLIPPED,"' AND '" CLIPPED,fecha_auxt CLIPPED,"' AND zon_cve= 'A') "}
            LET qrySalMin = "SELECT importe FROM c_salario_min\n"
            LET qrySalMin = qrySalMin CLIPPED, " WHERE\n"
            LET qrySalMin = qrySalMin CLIPPED, " fecha_alta BETWEEN '" CLIPPED, ldt_fecha_ini CLIPPED, "' AND '" CLIPPED, fecha_auxt CLIPPED, "'\n"
			-- INICIO INFOTEC TK - 2023023251 GARANTIA
			IF ls_band_periodo THEN
				 LET qrySalMin = qrySalMin CLIPPED, " OR fecha_alta IN (SELECT max(fecha_alta) FROM c_salario_min WHERE fecha_alta < '" CLIPPED, ldt_fecha_ini CLIPPED,"' and zon_cve = 'A') "
			END IF
			-- FIN INFOTEC TK - 2023023251 GARANTIA
            LET qrySalMin = qrySalMin CLIPPED, " AND zon_cve = 'A' \n"
            --LET sueldo = sueldo / 10
            LET qrySalMin = qrySalMin CLIPPED, " AND importe <= ", sueldo,"\n"		
            LET qrySalMin = qrySalMin CLIPPED, " ORDER BY fecha_alta "
                            
            PREPARE prpSalMin1 FROM qrySalMin
            DECLARE drpSalMin1 CURSOR FOR prpSalMin1
        
            FOREACH drpSalMin1 INTO tope[c1].minimo
            --display " ################################### CONSULTA ",c1," \n >>>>> ", tope[c1].minimo
                LET tope[c1].maximo = tope[c1].minimo*10
                --display "DATOS ENTRADA  >>> ",fecha_inicio, sueldo
                --display "TOPE MINIMO == >> " ,tope[c1].minimo
                --display "TOPE MAXIMO == >> " ,tope[c1].maximo
                --display "SUELDO :", sueldo,">",tope[c1].maximo," --->TOPE MAXIMO"
                IF sueldo > tope[c1].maximo  THEN
                    --display "IF sueldo > tope_maximo ===> c_salario_min"
                    LET li_bandSalMinMax = FALSE
                    --RETURN li_bandSalMinMax
                    EXIT FOREACH
                END IF
                LET c1= c1+1 
            END FOREACH
        END IF
        
        IF fecha_termino > fecha_aux THEN
            -- CALL tope.clear()
            {LET qrySalMin = "SELECT importe FROM cat_uma WHERE zon_cve = 'A' AND fecha_alta IN (  ",
                            " SELECT (fecha_alta) FROM cat_uma WHERE fecha_alta BETWEEN '"CLIPPED,fecha_aux CLIPPED,"' AND '"CLIPPED, fecha_termino CLIPPED,"' AND zon_cve= 'A') "}
			IF fecha_inicio > fecha_aux OR c_per > 1 THEN -- INFOTEC TK - 2023023251 GARANTIA
                LET ld_fecha_auxbus = fecha_inicio
            ELSE
                LET ld_fecha_auxbus = ldt_fecha_ini				
            END IF
            LET qrySalMin = "SELECT importe FROM cat_uma\n"
            LET qrySalMin = qrySalMin CLIPPED, "WHERE\n"
            LET qrySalMin = qrySalMin CLIPPED, "fecha_alta BETWEEN '" CLIPPED, ldt_fecha_ini CLIPPED, "' AND '" CLIPPED, ldt_fecha_fin CLIPPED, "'\n"
            LET qrySalMin = qrySalMin CLIPPED, "AND zon_cve = 'A'\n"
            --LET sueldo = sueldo / 10
            LET qrySalMin = qrySalMin CLIPPED, "AND importe <= ", sueldo,"\n"	
			LET qrySalMin = qrySalMin CLIPPED, "OR fecha_alta IN (SELECT max(fecha_alta) FROM cat_uma WHERE fecha_alta < '" CLIPPED, ld_fecha_auxbus CLIPPED, "' and zon_cve = 'A') \n" ## SOLUCION CORTE PERIODOS EN EL MISMO A�O RDJA LMLC	
            LET qrySalMin = qrySalMin CLIPPED, "ORDER BY fecha_alta"
            
            PREPARE prpSalMin2 FROM qrySalMin
            DECLARE drpSalMin2 CURSOR FOR prpSalMin2
            
            FOREACH drpSalMin2 INTO tope[c2].minimo
            --display " ========================== CONSULTA  ",c2," \n ---> min  ", tope[c2].minimo
                LET tope[c2].maximo = tope[c2].minimo * 10
                --display "DATOS ENTRADA  >>> ",fecha_inicio, sueldo
                --display "TOPE MAXIMO ## >> " ,tope[c2].maximo
                --display "TOPE MINIMO ## >> " ,tope[c2].minimo
                --display " ## SUELDO :", sueldo,">",tope[c2].maximo," --->TOPE MAXIMO"
                IF sueldo > tope[c2].maximo  THEN
                    --display " IF sueldo > tope_maximo ===> cat_ uma"
                    LET li_bandSalMinMax = FALSE
                    --RETURN li_bandSalMinMax
                    EXIT FOREACH
                END IF
                LET c2= c2 + 1 
            END FOREACH
        END IF
    END IF 
    IF YEAR(ldt_fecha_ini) < 1966 THEN 
        LET qrySalMin = "SELECT importe FROM c_salario_min WHERE fecha_alta = '01/01/1966' AND zon_cve = 'A'"
        PREPARE p_menor_seis1 FROM qrySalMin
        EXECUTE p_menor_seis1 INTO menor_seis

        IF sueldo > menor_seis THEN 
            LET li_bandSalMinMax = FALSE
        END IF 
    END IF 
	--display "AFTER IF BANDERA MINMAX >> " ,li_bandSalMinMax
	RETURN li_bandSalMinMax
	
END FUNCTION


FUNCTION f_verifica_traslape_movimiento(contadorExterno,lr_movimiento)

 # --- PARAMETROS DE LA FUNCION ---
 DEFINE lr_movimiento   RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD,
 # --- VARIABLES DE LA FUNCION ---
     li_num  ,contadorExterno    ,cont      SMALLINT,
     li_total          SMALLINT,
     lb_traslape       SMALLINT
 
    --display ".........ESTAMOS EN F_VERIFICA_TRASLAPE_MOVIMIENTO........"
     # --- ASUMIMOS UN ESTADO SIN TRASLAPE ---
     LET lb_traslape = FALSE
 

 
    --display "li_ttotal .... : ", arr_tci.getLength()
     # --- RECORREMOS EL ARREGLO DE CUENTA INDIVIDUAL DESTINO ---
 
 FOR li_num = 1 TO arr_tci.getLength()
   
    --display "arr_tci.getLength() .... : ", arr_tci.getLength()
    --display "li_num    .... : ", li_num
    IF contadorExterno = li_num     THEN
        IF li_num == arr_tci.getLength()   THEN 
            EXIT FOR 
        ELSE 
            LET li_num= li_num + 1
        END IF 
    ELSE 
        IF li_num > arr_tci.getLength() THEN
            CALL arr_tci.deleteElement(li_num) 
            LET li_num=li_num-1
            EXIT FOR
        END IF 
    END IF 
--display ""
--display "lr_movimiento.fecha_inicio .... : ", lr_movimiento.fi
--display "lr_movimiento.fecha_termino.... : ", lr_movimiento.ft
--display "ga_cuenta_ind[li_num].fecha_inicio.... : ",arr_tci[li_num].fi
--display "ga_cuenta_ind[li_num].fecha_termino... : ",arr_tci[li_num].ft
--display "Hey entre........."
      # --- VERIRICAMOS SI HAY TRASLAPE CON FECHA DE INICIO ---
     IF ( 
         ( lr_movimiento.fi >= arr_tci[li_num].fi  AND lr_movimiento.fi <= arr_tci[li_num].ft ) OR
          --( lr_movimiento.fi >= arr_tci[li_num].fi  AND lr_movimiento.ft <= arr_tci[li_num].ft ) OR 
         ( lr_movimiento.ft >= arr_tci[li_num].fi  AND lr_movimiento.ft <= arr_tci[li_num].ft ) OR 
         ( lr_movimiento.fi <= arr_tci[li_num].fi  AND lr_movimiento.ft >= arr_tci[li_num].ft )
        ) THEN
       LET lb_traslape = TRUE
       EXIT FOR
     END IF
      
     
     

 END FOR


 
 IF lb_traslape = TRUE THEN 
--display "lr_movimiento.fecha_inicio .... : ", lr_movimiento.fi
--display "lr_movimiento.fecha_termino.... : ", lr_movimiento.ft
--display "_________________________________________________________________________________________ : "
--display "lr_movimiento.fecha_inicio .... : ", arr_tci[li_num].fi
--display "lr_movimiento.fecha_termino.... : ", arr_tci[li_num].ft

    INITIALIZE arr_tci_Aux TO NULL
    IF lr_movimiento.fi = "01/01/1987" THEN
        DISPLAY lr_movimiento.fi, " - ", lr_movimiento.ft, arr_tci[li_num].fi, " - ", arr_tci[li_num].ft 
    END IF
    --DISPLAY "antes if: ", lr_movimiento.fi, " < ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " < ", arr_tci[li_num].ft 
    IF  lr_movimiento.fi <  arr_tci[li_num].fi AND lr_movimiento.ft < arr_tci[li_num].ft THEN
    --arr_tci[li_num].fi = lr_movimiento.ft + 1
        --display "primer periodo Fecha inicio menor a la fecha inicio del segundo periodo y fecha termino de primer periodo menor a fechatermino del segundo periodo"
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = arr_tci[li_num].fi -1
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo
        
        LET arr_tci_Aux[2].fi = arr_tci[li_num].fi
        LET arr_tci_Aux[2].ft = lr_movimiento.ft
        LET arr_tci_Aux[2].sdo = lr_movimiento.sdo + arr_tci[li_num].sdo

        LET arr_tci_Aux[3].fi = lr_movimiento.ft + 1
        LET arr_tci_Aux[3].ft = arr_tci[li_num].ft
        LET arr_tci_Aux[3].sdo = arr_tci[li_num].sdo    
    END IF 

    --DISPLAY "antes if: ", lr_movimiento.fi, " < ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " > ", arr_tci[li_num].ft
    IF  lr_movimiento.fi <  arr_tci[li_num].fi AND lr_movimiento.ft > arr_tci[li_num].ft THEN
    --arr_tci[li_num].fi = lr_movimiento.ft + 1
        --display "primer periodo Fecha inicio menor a la fecha inicio del segundo periodo y fecha termino de primer periodo Mayor a fechatermino del segundo periodo"
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = arr_tci[li_num].fi - 1 
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo

        --display "::::::::::::::::::::::::::::::::::2 ",arr_tci_Aux[1].*
        LET arr_tci_Aux[2].fi = arr_tci[li_num].fi
        LET arr_tci_Aux[2].ft = arr_tci[li_num].ft       
        LET arr_tci_Aux[2].sdo = lr_movimiento.sdo + arr_tci[li_num].sdo
        --display "::::::::::::::::::::::::::::::::::2 ",arr_tci_Aux[2].*
        LET arr_tci_Aux[3].fi = arr_tci[li_num].ft + 1
        LET arr_tci_Aux[3].ft = lr_movimiento.ft
        LET arr_tci_Aux[3].sdo = lr_movimiento.sdo
        --display "::::::::::::::::::::::::::::::::::3 ",arr_tci_Aux[3].*
    END IF 

    --DISPLAY "antes if: ", lr_movimiento.fi, " > ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " > ", arr_tci[li_num].ft
    IF  lr_movimiento.fi >  arr_tci[li_num].fi AND lr_movimiento.ft > arr_tci[li_num].ft THEN
    --arr_tci[li_num].fi = lr_movimiento.ft + 1
        --display "El traslape inicia desde la fecha inicio"
        LET arr_tci_Aux[1].fi  = arr_tci[li_num].fi  
        LET arr_tci_Aux[1].ft  = lr_movimiento.fi - 1
        LET arr_tci_Aux[1].sdo = arr_tci[li_num].sdo

        --display "::::::::::::::::::::::::::::::::::2 ",arr_tci_Aux[1].*
        LET arr_tci_Aux[2].fi = lr_movimiento.fi
        LET arr_tci_Aux[2].ft = arr_tci[li_num].ft       
        LET arr_tci_Aux[2].sdo = lr_movimiento.sdo + arr_tci[li_num].sdo
        --display "::::::::::::::::::::::::::::::::::2 ",arr_tci_Aux[2].*
        LET arr_tci_Aux[3].fi = arr_tci[li_num].ft + 1
        LET arr_tci_Aux[3].ft = lr_movimiento.ft
        LET arr_tci_Aux[3].sdo = lr_movimiento.sdo
        --display "::::::::::::::::::::::::::::::::::3 ",arr_tci_Aux[3].*
    END IF 

    --DISPLAY "antes if: ", lr_movimiento.fi, " = ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " < ", arr_tci[li_num].ft
    IF  lr_movimiento.fi = arr_tci[li_num].fi AND lr_movimiento.ft < arr_tci[li_num].ft THEN
    
        --display "El traslape inicia desde la fecha inicio"
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = lr_movimiento.ft 
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo + arr_tci[li_num].sdo

        --display "::::::::::::::::::::::::::::::::::2 ",arr_tci_Aux[1].*
        LET arr_tci_Aux[2].fi = lr_movimiento.ft + 1
        LET arr_tci_Aux[2].ft = arr_tci[li_num].ft
        LET arr_tci_Aux[2].sdo =  arr_tci[li_num].sdo
        --display "::::::::::::::::::::::::::::::::::3 ",arr_tci_Aux[2].*
    END IF 

    --DISPLAY "antes if: ", lr_movimiento.fi, " = ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " > ", arr_tci[li_num].ft
    IF  lr_movimiento.fi = arr_tci[li_num].fi AND lr_movimiento.ft > arr_tci[li_num].ft THEN
    
        --display "El traslape inicia desde la fecha inicio"
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = arr_tci[li_num].ft 
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo + arr_tci[li_num].sdo

        --display "::::::::::::::::::::::::::::::::::-. ",arr_tci_Aux[1].*
        LET arr_tci_Aux[2].fi = arr_tci[li_num].ft + 1
        LET arr_tci_Aux[2].ft = lr_movimiento.ft
        LET arr_tci_Aux[2].sdo =  lr_movimiento.sdo
        --display "::::::::::::::::::::::::::::::::::-. ",arr_tci_Aux[2].*
    END IF

    --DISPLAY "antes if: ", lr_movimiento.fi, " < ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " = ", arr_tci[li_num].ft
    IF  lr_movimiento.fi < arr_tci[li_num].fi AND lr_movimiento.ft = arr_tci[li_num].ft THEN
        DISPLAY "dentro if: ", lr_movimiento.fi, " < ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " = ", arr_tci[li_num].ft
        
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = arr_tci[li_num].fi - 1
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo
        
        LET arr_tci_Aux[2].fi = arr_tci[li_num].fi
        LET arr_tci_Aux[2].ft = lr_movimiento.ft
        LET arr_tci_Aux[2].sdo = lr_movimiento.sdo
    END IF

    IF  lr_movimiento.fi = arr_tci[li_num].fi AND lr_movimiento.ft = arr_tci[li_num].ft THEN
        DISPLAY "-- dentro de: ", lr_movimiento.fi, " = ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " = ",arr_tci[li_num].ft 
        -- agregado
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = arr_tci[li_num].ft
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo +  + arr_tci[li_num].sdo
    END IF

    IF  (lr_movimiento.fi <  arr_tci[li_num].fi AND lr_movimiento.ft < arr_tci[li_num].ft) AND lr_movimiento.ft > arr_tci[li_num].fi THEN
        DISPLAY "## dentro de: (", lr_movimiento.fi, " < ", arr_tci[li_num].fi, " AND ", lr_movimiento.ft, " < ",arr_tci[li_num].ft, ") AND ", lr_movimiento.ft, " > ", arr_tci[li_num].fi 
        --agregado
        LET arr_tci_Aux[1].fi  = lr_movimiento.fi
        LET arr_tci_Aux[1].ft  = arr_tci[li_num].fi
        LET arr_tci_Aux[1].sdo = lr_movimiento.sdo
        
        LET arr_tci_Aux[2].fi = arr_tci[li_num].fi + 1
        LET arr_tci_Aux[2].ft = arr_tci[li_num].ft
        LET arr_tci_Aux[2].sdo = lr_movimiento.sdo
    END IF
    
 --display "Se Borra primero",li_num
 --display  "arr_tci:" , arr_tci[li_num].*
 --display "Se borra segundo", contadorExterno 
 --display "arr_tci_2", arr_tci[contadorExterno].*

    CALL arr_tci.deleteElement(li_num)
    CALL arr_tci.deleteElement(contadorExterno)  

    FOR aux2=1 TO arr_tci_Aux.getLength() 
     --display "Paso", arr_tci_Aux[aux2].*
    LET arr_tci[arr_tci.getLength()+ 1].* = arr_tci_Aux[aux2].*
    END FOR 
END IF

 --IF lb_traslape = FALSE  THEN 
 --   CALL arr_tci.deleteElement(li_num)
 --   LET li_num=li_num-1
 --END IF 
 RETURN lb_traslape, li_num
END FUNCTION

FUNCTION f_corrige_sueldo_maximo(li_indice,ld_sueldo)
    DEFINE
        # --- PARAMETROS DE LA FUNCION ---
        li_indice SMALLINT, # --- INDICE DEL ARREGLO DONDE ESTA EL MOVIMIENTO CON SALARIO FUERA DE RANGO ---
        ld_sueldo LIKE cuenta_ind.sueldo_issste,  # --- Sueldo que no debe rebasar ---

        # --- VARIABLES DE LA FUNCION ---
        ldt_fecha_ini DATE, -- fecha de inicio original ---
        ldt_fecha_fin DATE, -- fecha de termino original ---
        ldt_fecha_ini_temp DATE, -- fecha de inicio temporal usada para las iteraciones de intervalos de mas de un ano ---
        ldt_fecha_fin_temp DATE, -- fecha de termino temporal usada para las iteraciones de intervalos de mas de un ano ---
        ls_fecha_ini STRING, -- cadena de fechas de inicio ---
        ls_fecha_fin STRING, -- cadena de fechas de termino ---
        li_num, li_numaux SMALLINT, -- TK-2022084222 2022
        li_numaux2 SMALLINT,  --Garantia INFOTEC tk 3251
        li_num2 SMALLINT, -- indice de recorrido de arreglo --
        li_num3 SMALLINT, -- indice de recorrido de arreglo --
        li_total SMALLINT, -- total de elementos en arreglo --
        li_total2 SMALLINT, -- total de elementos en arreglo --
        li_bannomax SMALLINT, -- bandera de salario original que excede salario --
        ld_salario_max LIKE c_salario_min.importe, -- salario maximo encontrado para una fecha --
        l_cin_id LIKE cuenta_ind.cin_id, # --- del indice ---
    lar_arr   DYNAMIC ARRAY OF RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD,

   lr_arr  RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD,
        lr_cuenta_ind RECORD LIKE cuenta_ind.*,
        lb_periodos_intermedios SMALLINT, # --- INDICA SI DEBEMOS CREAR PERIODOS INTERMEDIOS EN UN INTERVALO DE TIEMPO ---
        lb_eslicencia SMALLINT,            # --- INDICA SI EL MOTIVO DE INICIO ES LICENCIA
        lc_tipolicencia LIKE cuenta_ind.t_movto_inicio  # -- INDICA EL TIPO DE MOTIVO ASOCIADO AL MOVIMIENTO

    --display "DUPLICANDO EL ARREGLO ORIGINAL"
    --display "bandera minima===========>>>",bandMin
    --display "bandera intermedia===========>>>",bandInt
    --display "bandera maxima===========>>>",bandMax
    LET ano_val = 2017
    LET li_numaux2 = 0


    # --- DUPLICAMOS EL ARREGLO DE CUENTA INDIVIDUAL ---
    LET li_total = arr_tci.getlength()

    FOR li_num = 1 TO li_total
        LET lar_arr[li_num].* = arr_tci[li_num].*
    END FOR

    # --- INICIALIZAMOS EL MOVIMIENTO NUEVO ---
    LET lr_arr.* = lar_arr[li_indice].*
  --  LET lr_cuenta_ind.cin_id = 0

    # --- BORRAMOS EL ARREGLO ORIGINAL DE CUENTA INDIVIDUAL ---
    CALL arr_tci.clear()

    # --- REGRESAMOS LOS PRIMEROS MOVIMIENTOS DE LA CUENTA INDIVIDUAL AL ARREGLO ORIGINAL
    LET li_total = li_indice - 1
    FOR li_num = 1 TO li_total
        LET arr_tci[li_num].* = lar_arr[li_num].*
    END FOR

    # --- OBTENEMOS LAS FECHAS DEL MOVIMIENTO CON SUELDO FUERA DE RANGO ---
    LET ldt_fecha_ini = lar_arr[li_indice].fi
    LET ldt_fecha_fin = lar_arr[li_indice].ft
    LET fechaaux_ini = lar_arr[li_indice].fi
    LET fechaaux_fin = lar_arr[li_indice].ft
    --display "--- ESTAMOS HACIENDO UN DESGLOSE DE UN INTERVALO DE FECHAS EN VARIOS PERIODOS CONSECUTIVOS ---"
    --display "Fecha de inicio del periodo: ", ldt_fecha_ini
    --display "Fecha de termino del periodo: ", ldt_fecha_fin
    --display "Sueldo a comparar: " || ld_sueldo

    # --- SI LAS FECHAS DE INICIO Y TERMINO PERTENECEN AL MISMO ANO ---
    IF ( YEAR(ldt_fecha_ini) == YEAR(ldt_fecha_fin) AND YEAR(ldt_fecha_ini)<>ano_val AND YEAR(ldt_fecha_fin)<>ano_val  ) THEN
        --display "Las fechas del periodo corresponden al mismo ano"
       
        # --- LAS FECHAS PERTENECEN A UN MISMO ANO, CORREGIMOS EL SUELDO TOPE ---
        # --- EL SALARIO MAXIMO DEL FINAL DEL PERIODO ---
        # --- CREAMOS LOS LIMITES DE FECHAS ---
        LET ls_fecha_ini = "01/01/" || YEAR(ldt_fecha_ini)
        LET ls_fecha_fin = "31/12/" || YEAR(ldt_fecha_ini)

        CALL f_obten_salario_fecha(ls_fecha_ini, ls_fecha_fin, ld_sueldo,fechaaux_ini,fechaaux_fin) RETURNING ld_salario_max, li_total2

        # --- SI SOLO HAY UN TOPE SALARIAL POR ANO, CORREGIMOS ---
        IF ( li_total2 == 1 ) THEN
            --display "SOLO EXISTE UN SALARIO PARA EL INTERVALO INDICADO"
            IF (ld_sueldo > ld_salario_max AND (bandInt OR bandMax)) OR (ld_sueldo < ld_salario_max AND bandMin) THEN 	-- INFOTEC TK - 2022084222 2022				
                LET lr_arr.sdo= ld_salario_max
                LET arr_tci[li_indice].* = lr_arr.*
            ELSE -- INICIO INFOTEC TK - 2022084222 2022
				IF (ld_sueldo < ld_salario_max AND bandInt OR bandMax) OR (ld_sueldo > ld_salario_max AND bandMin) THEN
               		LET lr_arr.sdo = ld_sueldo
               		LET arr_tci[li_indice].* = lr_arr.*
				END IF
            END IF -- FIN INFOTEC TK - 2022084222 2022
            --display ".SE HACE UN COSO Y SUELDO ES=", arr_tci[li_indice].sdo
        ELSE
            --display "EXISTE MAS DE UN SALARIO EN EL INTERVALO INDICADO"
            # --- EXISTEN AL MENOS DOS SUELDOS, SE DEBEN CREAR SUBPERIODOS SEGUN FECHAS DE VALIDEZ DE SUELDOS ---
            LET li_total = lar_salarios.getlength()

            # --- OBTENEMOS EL SALARIO TOPE QUE SEA MAS CERCANO A LA FECHA DE INICIO DEL PERIODO ---
			#INICIO TK-2022084222 2022
			LET li_numaux = li_total
            LET li_numaux2 = li_total
            --display "Bandera intermedia!!!",bandInt
			IF bandInt OR bandMax THEN
				FOR li_num = 1 TO li_total
					CALL ajuste_periodos_max_int(li_numaux2,li_numaux,ld_sueldo) RETURNING li_numaux
                    IF li_numaux2 > 1 THEN
                        LET li_numaux2 = li_numaux2 - 1
                    END IF
				END FOR
				LET li_total = li_numaux
            ELSE
                FOR li_num = 1 TO li_total
                    CALL ajuste_periodos_min(li_numaux2,li_numaux,ld_sueldo) RETURNING li_numaux
                    IF li_numaux2 > 1 THEN
                        LET li_numaux2 = li_numaux2 - 1
                    END IF
                END FOR
				LET li_total = li_numaux
			END IF
			#FIN TK-2022084222 2022
            FOR li_num = 1 TO li_total
                # --- CONTAMOS HASTA QUE LA FECHA DE VALIDEZ SEA MAYOR QUE LA FECHA DE INICIO DEL PERIODO ---
                IF ( lar_salarios[li_num].fecha_alta > ldt_fecha_ini ) THEN
                    # --- AL SER LA FECHA DE ALTA MAYOR A LA FECHA INICIAL, ENTONCES, USAMOS EL INDICE ANTERIOR ---
                    IF li_num > 1 THEN #Infotec tk-2022084222
                    LET li_num = li_num - 1 --rdja
                    --display "ENCONTRAMOS TOPE SALARIAL PARA FECHA INICIO"
                    --display "EL FAMOSISISMO li_num =", li_num
                    --display lar_salarios[li_num].importe
                    END IF #Infotec tk-2022084222
                    EXIT FOR
                END IF
            END FOR

            # --- TENEMOS EL INDICE LIMITE DE INICIO, BUSCAMOS EL INDICE LIMITE FINAL ---
            FOR li_num2 = 1 TO li_total
                # --- CONTAMOS HASTA QUE LA FECHA DE VALIDEZ SEA MAYOR QUE LA FECHA DE INICIO DEL PERIODO ---
                IF ( lar_salarios[li_num2].fecha_alta > ldt_fecha_fin ) THEN
                    # --- AL SER LA FECHA DE ALTA MAYOR A LA FECHA INICIAL, ENTONCES, USAMOS EL INDICE ANTERIOR ---
                    IF li_num2 > 1 THEN #Infotec tk-2022084222
                    LET li_num2 = li_num2 - 1 
                    --display "ENCONTRAMOS TOPE SALARIAL PARA FECHA FIN"
                    --display lar_salarios[li_num2].importe
                    END IF #Infotec tk-2022084222
                    EXIT FOR
                END IF
            END FOR

            # --- CREAREMOS EL CICLO QUE IRA TOMANDO LOS TOPES SALARIALES Y CREANDO LOS NUEVOS PERIODOS
            # --- A PARTIR DE LOS INDICES ENCONTRADOS ---

            LET ls_fecha_ini = ldt_fecha_ini
            IF ( li_num2 > li_total ) THEN
                LET li_num2 = li_total
            END IF

            # --- EL FINAL DEL CICLO ES li_num2 ---
            --display "FINAL DEL CICLO: "
            --display li_num2

            LET li_total = li_num2

            IF ( li_num > lar_salarios.getlength() ) THEN
                LET li_num = lar_salarios.getlength()
            END IF

            # --- EL PRINCIPIO DEL CICLO ES li_num ---
            --display "INICIO DEL CICLO: "
            --display li_num
            LET li_num2 = li_num

            # --- LOS NUEVOS MOVIMIENTOS SE VAN CREANDO A PARTIR DEL INDICE ORIGINAL ---
            LET li_num3 = li_indice

            # --- RECORREMOS DESDE EL INIDICE INICIAL HASTA EL INDICE FINAL ENCONTRADOS ---
            FOR li_num = li_num2 TO li_total
                --display "CREANDO PERIODOS INTERMEDIOS"

                LET lr_arr.fi = ls_fecha_ini

                # --- VERIFICAMOS QUE EL SUELDO TOPE NO SEA MAYOR QUE EL SUELDO ORIGINAL ---
		IF ( lar_salarios[li_num].importe < ld_sueldo AND NOT bandMin) OR (lar_salarios[li_num].importe > ld_sueldo AND bandMin) THEN --INFOTEC TK - 2022084222 2022
                    LET lr_arr.sdo = lar_salarios[li_num].importe
                ELSE
                    LET lr_arr.sdo = ld_sueldo
                END IF

                # --- EL PRIMER MOVIMIENTO DEBE TENER EL MISMO MOTIVO DE INICIO QUE EL ORIGINAL ---
                {IF ( li_num == li_num2 ) THEN
                   -- LET lr_arr.t_movto_inicio = lar_arr[li_indice].t_movto_inicio
                    # ---SE VERIFICA SI EL MOVIMIENTO DADO DE ALTA ES LICENCIA
                    --IF VerificaLicencia(lar_arr[li_indice].t_movto_inicio)THEN
                        #-- ENCENDEMOS LA BANDERA QUE NOS INDICARA SI ES QUE LA VARIALE ES LICENCIA
                    --    LET lc_tipolicencia=lar_arr[li_indice].t_movto_inicio
                     --   LET lb_eslicencia=TRUE
                    --ELSE
                     --   LET lb_eslicencia=FALSE
                  --  END IF
                ELSE
                    #SI SE ENCONTR� QUE EL MOTIVO DE INICIO DEL PRIMER ELEMENTO ES UNA LICENCIA ENTONCES �STA SE PRESERVA
                    --IF lb_eslicencia THEN
                        LET lr_arr.t_movto_inicio=lc_tipolicencia
                    ELSE
                        LET lr_arr.t_movto_inicio = "MS"
                    END IF
                END IF}

                IF ( li_num != li_total ) THEN
                    LET lr_arr.ft = lar_salarios[li_num + 1].fecha_alta - 1 UNITS DAY
                    #SI SE ENCONTR� QUE EL MOTIVO DE INICIO DEL PRIMER ELEMENTO ES UNA LICENCIA ENTONCES �STA SE PRESERVA
                   -- IF lb_eslicencia THEN
                    --    LET lr_arr.t_movto_cierre=lc_tipolicencia
                   -- ELSE
                     --   LET lr_arr.t_movto_cierre = "MS"
                   -- END IF
                ELSE
                    LET lr_arr.ft = ldt_fecha_fin
                    --LET lr_arr.t_movto_cierre = lar_arr[li_indice].t_movto_cierre
                END IF

                --display "MOVIMIENTO CREADO ES:"
                --display lr_arr.fi || "-" || lr_arr.ft || " sueldo: " || lr_arr.sdo

                # --- AGREGAMOS EL MOVIMIENTO RECIEN CREADO ---
                LET arr_tci[li_num3].* = lr_arr.*

                # --- AVANZAMOS INDICE LOCAL ---
                LET li_num3 = li_num3 + 1

                # --- AVANZAMOS LA FECHA DE INICIO ---
                LET ls_fecha_ini = lar_salarios[li_num + 1].fecha_alta
            END FOR
        END IF  --- MAS DE UN SALARIO EN UN INTERVALO DE UN ANO ---
    ELSE
        --display "Las Fechas no corresponden al mismo a�o"
        # ----display "Las fechas del periodo corresponden al mismo ano"

        # --- LAS FECHAS PERTENECEN A UN MISMO ANO, CORREGIMOS EL SUELDO TOPE ---

        # --- EL SALARIO MAXIMO DEL FINAL DEL PERIODO ---

        # --- CREAMOS LOS LIMITES DE FECHAS ---
        LET fechaaux_ini = ldt_fecha_ini
        LET fechaaux_fin = ldt_fecha_fin
        # --- ELIMINAMOS EL -1 AL A�O DE FECHA DE INICIO, ANTERIORMENTE LA SENTENCIA ERA:   LET ls_fecha_ini = "01/01/" || YEAR(ldt_fecha_ini)-1
        LET ls_fecha_ini = "01/01/" || YEAR(ldt_fecha_ini)
        LET ls_fecha_fin = "31/12/" || YEAR(ldt_fecha_fin)

        CALL f_obten_salario_fecha(ls_fecha_ini, ls_fecha_fin, ld_sueldo,fechaaux_ini,fechaaux_fin) RETURNING ld_salario_max, li_total2
        # --- SI SOLO HAY UN TOPE SALARIAL POR ANO, CORREGIMOS ---
        IF ( li_total2 == 1 ) THEN
            --display "SOLO EXISTE UN SALARIO PARA EL INTERVALO INDICADO"
	    IF (ld_sueldo > ld_salario_max AND bandInt OR bandMax) OR (ld_sueldo < ld_salario_max AND bandMin) THEN -- INFOTEC TK - 2022084222 2022				
                LET lr_arr.sdo = ld_salario_max
                LET arr_tci[li_indice].* = lr_arr.*
            ELSE -- INICIO INFOTEC TK - 2022084222 2022
				IF (ld_sueldo < ld_salario_max AND bandInt OR bandMax) OR (ld_sueldo > ld_salario_max AND bandMin) THEN
               		LET lr_arr.sdo = ld_sueldo
               		LET arr_tci[li_indice].* = lr_arr.*
				END IF
            END IF -- FIN INFOTEC TK - 2022084222 2022
			--display "SE HACE UN COSO Y SUELDO ES=", arr_tci[li_indice].sdo
        ELSE
            --display "EXISTE MAS DE UN SALARIO EN EL INTERVALO INDICADO"

            # --- EXISTEN AL MENOS DOS SUELDOS, SE DEBEN CREAR SUBPERIODOS SEGUN FECHAS DE VALIDEZ DE SUELDOS ---
            LET li_total = lar_salarios.getlength()

            # --- DEBUG
            --display "El total de elementos encontrados en el arreglo de salarios es: ", li_total
            # --- END DEBUG
			#INICIO INFOTEC TK-2022084222 2022
			LET li_numaux = li_total
            LET li_numaux2 = li_total
            --display "bandMin ????????? ||",bandMin,"Longitud de arreglo !!!! ",li_numaux
            IF bandMin THEN
                --display "Entre a ajuste_periodos_min ==========||"
                FOR li_num = 1 TO li_total -- INICIO LMLC
                    CALL ajuste_periodos_min(li_numaux2,li_numaux,ld_sueldo) RETURNING li_numaux
                    IF li_numaux2 > 1 THEN
                        LET li_numaux2 = li_numaux2 - 1
                    END IF
                END FOR
            ELSE
                FOR li_num = 1 TO li_total -- INICIO LMLC
                    CALL ajuste_periodos_max_int(li_numaux2,li_numaux,ld_sueldo) RETURNING li_numaux
                    IF li_numaux2 > 1 THEN
                        LET li_numaux2 = li_numaux2 - 1
                    END IF
                END FOR
            END IF
			--display "Despues bandMin ????????? ||",bandMin,"Longitud de arreglo !!!! ",li_numaux
			LET li_total = li_numaux-- FIN LMLC
			#FIN INFOTEC TK-2022084222 2022
            # --- OBTENEMOS EL SALARIO TOPE QUE SEA MAS CERCANO A LA FECHA DE INICIO DEL PERIODO ---
            FOR li_num = 1 TO li_total
                # --- DEBUG
                ----display "Antes de hacer cualquier chisme se tiene el elemento ", li_num," con fecha de alta: ",lar_salarios[li_num].fecha_alta
                # --- END DEBUG

                # --- CONTAMOS HASTA QUE LA FECHA DE VALIDEZ SEA MAYOR QUE LA FECHA DE INICIO DEL PERIODO ---
                IF ( lar_salarios[li_num].fecha_alta > ldt_fecha_ini ) THEN
                    # --- AL SER LA FECHA DE ALTA MAYOR A LA FECHA INICIAL, ENTONCES, USAMOS EL INDICE ANTERIOR ---
                        IF li_num > 1 THEN 
                            LET li_num = li_num - 1
                    ----display "ENCONTRAMOS TOPE SALARIAL PARA FECHA INICIO", lar_salarios[li_num].fecha_alta
                    --display "EL FAMOSOS li_num=", li_num
                        END IF 
                    IF li_num= 0 THEN
                        LET li_num = 1
                    END IF

                    --display lar_salarios[li_num].importe
                    EXIT FOR
                END IF
            END FOR

            # --- TENEMOS EL INDICE LIMITE DE INICIO, BUSCAMOS EL INDICE LIMITE FINAL ---
            FOR li_num2 = 1 TO li_total
                # --- DEBUG
                ----display "Antes de hacer cualquier chisme en el segundo for se tiene el elemento ", li_num2," con fecha de alta: ",lar_salarios[li_num2].fecha_alta
                # --- END DEBUG

                # --- CONTAMOS HASTA QUE LA FECHA DE VALIDEZ SEA MAYOR QUE LA FECHA DE INICIO DEL PERIODO ---
                IF ( lar_salarios[li_num2].fecha_alta > ldt_fecha_fin ) THEN
                    # --- AL SER LA FECHA DE ALTA MAYOR A LA FECHA INICIAL, ENTONCES, USAMOS EL INDICE ANTERIOR ---
                    IF li_num2 > 1 THEN
                        LET li_num2 = li_num2 - 1
                    END IF 
                    IF li_num2 = 0 THEN
                        LET li_num2 = 1
                    END IF

                    --display "ENCONTRAMOS TOPE SALARIAL PARA FECHA FIN"
                    --display lar_salarios[li_num2].importe
                    EXIT FOR
                END IF
            END FOR


            LET ls_fecha_ini = ldt_fecha_ini

            IF ( li_num2 > li_total ) THEN
                LET li_num2 = li_total
            END IF

            LET li_total = li_num2

            IF ( li_num > lar_salarios.getlength() ) THEN
                LET li_num = lar_salarios.getlength()
            END IF

            LET li_num2 = li_num

            LET li_num3 = li_indice

            FOR li_num = li_num2 TO li_total
                --display  "Elemento : ", li_num ," con salario: ", lar_salarios[li_num].importe," fecha de alta: ", lar_salarios[li_num].fecha_alta
            END FOR

            FOR li_num = li_num2 TO li_total
                LET lr_arr.fi = ls_fecha_ini
                
                IF ( lar_salarios[li_num].importe < ld_sueldo AND NOT bandMin) OR (lar_salarios[li_num].importe > ld_sueldo AND bandMin) THEN -- INFOTEC TK - 2022084222 2022
                    LET lr_arr.sdo = lar_salarios[li_num].importe
                ELSE
                    LET lr_arr.sdo = ld_sueldo
                END IF

                IF ( li_num != li_total ) THEN
                    LET lr_arr.ft = lar_salarios[li_num + 1].fecha_alta - 1 UNITS DAY

                ELSE
                    LET lr_arr.ft = ldt_fecha_fin
                END IF

                LET arr_tci[li_num3].* = lr_arr.*
                LET li_num3 = li_num3 + 1

                LET ls_fecha_ini = lar_salarios[li_num + 1].fecha_alta
            END FOR
        END IF --- MAS DE UN SALARIO EN UN INTERVALO DE UN ANO ---
     END IF # --- EL MOVIMIENTO TIENE O NO UN INTERVALO DE MAS DE UN ANO ---

    # --- REGRESAMOS EL RESTO DE LOS MOVIMIENTOS AL ARREGLO ORIGINAL ---
    LET li_num = arr_tci.getlength() + 1

    LET li_total = lar_arr.getlength()

    FOR li_num2 = li_indice + 1 TO li_total
        LET arr_tci[li_num].* = lar_arr[li_num2].*
        LET li_num = li_num + 1
    END FOR

END FUNCTION

FUNCTION f_salario_en_rango(lr_ar_record)

DEFINE lr_ar_record   RECORD 
       fi      LIKE cei_td_ws3_robusta_periodos.fecha_inicio,
       ft      LIKE cei_td_ws3_robusta_periodos.fecha_termino,
       sdo     LIKE cei_td_ws3_robusta_periodos.sueldo
   END RECORD,

 # --- VARIABLES DE LA FUNCION ---
 ldt_fecha_actual DATE,
 ld_salario_max LIKE c_salario_min.importe,
 lb_es_valido SMALLINT,
 ldt_fecha_inicio DATE, # --- inicio y termino de salario tope
 ldt_fecha_termino DATE,
 ld_salario_tope_ini LIKE plaza.sueldo_issste,
 ld_salario_tope_fin LIKE plaza.sueldo_issste,
 ls_sql STRING,
 d_fecsm DATE,
 salmin DECIMAL(10,2),
 l_imp  DECIMAL(10,2),
 cont_sm SMALLINT

  DEFINE ld_fecha_p       SMALLINT
  DEFINE fecha_uma,fechauma DATE
  DEFINE version,uversion CHAR(1)
  DEFINE importe,importes DECIMAL(12,2)

 LET lb_es_valido = TRUE

 LET ldt_fecha_actual = TODAY

 IF ( YEAR(lr_ar_record.fi) != YEAR(ldt_fecha_actual) ) THEN

   IF (YEAR(lr_ar_record.fi) < 1966) THEN
      LET lc_sql = "SELECT importe FROM c_salario_min WHERE fecha_alta = '01/01/1966' AND zon_cve = 'A' "
      PREPARE cursel04 FROM lc_sql
      EXECUTE cursel04 INTO ld_salario_max
   ELSE

      LET ld_fecha_p = YEAR(lr_ar_record.fi)
      LET ld_fecha_p = ld_fecha_p + 1 

      IF ld_fecha_p = YEAR(ldt_fecha_actual) THEN
         LET lc_sql = "SELECT salario_minimo FROM c_zona WHERE zon_cve = 'A' AND YEAR(fecha_msm) = YEAR(?) "
         PREPARE cursel05 FROM lc_sql
         EXECUTE cursel05 USING lr_ar_record.fi INTO ld_salario_max
         CALL get_Uma() RETURNING fecha_uma, version, importe       
        IF lr_ar_record.fi >= fecha_uma AND  version = 1 THEN
            LET ld_salario_max= importe
        END IF 
      ELSE
         LET lc_sql = "SELECT MAX(importe) FROM c_salario_min WHERE zon_cve = 'A' AND fecha_alta = ( ",
                      "    SELECT MAX(fecha_alta) FROM c_salario_min WHERE fecha_alta <= ? AND zon_cve = 'A') "
         PREPARE cursel06 FROM lc_sql
         EXECUTE cursel06 USING lr_ar_record.fi INTO ld_salario_max
         CALL get_Uma() RETURNING fecha_uma, version, importe       
         IF lr_ar_record.fi >= fecha_uma AND  version = 1 THEN
            LET ld_salario_max= importe
      END IF
   END IF
   END IF

   LET ld_salario_max = ld_salario_max * 10

   IF ( lr_ar_record.sdo > ld_salario_max ) THEN
     LET lb_es_valido = FALSE
     RETURN lb_es_valido
   END IF

 ELSE
    LET lc_sql = "SELECT salario_minimo FROM c_zona WHERE zon_cve = 'A' AND fecha_msm = ( ",
                 "   SELECT MAX(fecha_msm) FROM c_zona WHERE fecha_msm <= ? AND zon_cve= 'A') "
    PREPARE cursel07 FROM lc_sql
    EXECUTE cursel07 USING lr_ar_record.fi INTO ld_salario_max
    CALL get_Uma() RETURNING fecha_uma, version, importe       
        IF lr_ar_record.fi >= fecha_uma AND  version = 1 THEN
            LET ld_salario_max= importe
        END IF 

   LET ld_salario_max = ld_salario_max * 10

   IF ( lr_ar_record.sdo > ld_salario_max ) THEN
     LET lb_es_valido = FALSE
     RETURN lb_es_valido
   END IF
 END IF

 # --- SI LA FECHA DE CIERRE ES NULA, YA NO REVISAMOS ---
 IF ( lr_ar_record.ft IS NULL ) THEN
   RETURN lb_es_valido
 END IF

 IF ( YEAR(lr_ar_record.ft) != YEAR(ldt_fecha_actual) ) THEN

    LET ld_fecha_p = YEAR(lr_ar_record.fi)
    LET ld_fecha_p = ld_fecha_p + 1 

    IF ld_fecha_p = YEAR(ldt_fecha_actual) THEN
       LET lc_sql = "SELECT salario_minimo FROM c_zona WHERE zon_cve = 'A' AND YEAR(fecha_msm) = YEAR(?) "
       PREPARE cursel08 FROM lc_sql
       EXECUTE cursel08 USING lr_ar_record.fi INTO ld_salario_max
       CALL get_Uma() RETURNING fecha_uma, version, importe       
        IF lr_ar_record.fi >= fecha_uma AND  version = 1 THEN
            LET ld_salario_max= importe
        END IF     
    ELSE
       LET lc_sql = "SELECT MAX(importe) FROM c_salario_min WHERE zon_cve = 'A' AND fecha_alta = ( ",
                    "    SELECT MAX(fecha_alta) FROM c_salario_min WHERE fecha_alta <= ? AND zon_cve= 'A') "
       PREPARE cursel09 FROM lc_sql
       EXECUTE cursel09 USING lr_ar_record.ft INTO ld_salario_max
         CALL get_Uma() RETURNING fecha_uma, version, importe       
        IF lr_ar_record.ft >= fecha_uma AND  version = 1 THEN
            LET ld_salario_max= importe
        END IF        
    END IF

   # --- EL SALARIO SE MULTIPLICA POR 10 ---
   LET ld_salario_max = ld_salario_max * 10


   IF ( lr_ar_record.sdo > ld_salario_max ) THEN
     LET lb_es_valido = FALSE
     RETURN lb_es_valido
   END IF

 ELSE
    LET lc_sql = "SELECT salario_minimo FROM c_zona WHERE zon_cve = 'A' AND fecha_msm = ( ",
                 "     SELECT MAX(fecha_msm) FROM c_zona WHERE fecha_msm <= ? AND zon_cve= 'A') "
    PREPARE cursel10 FROM lc_sql
    EXECUTE cursel10 USING lr_ar_record.ft INTO ld_salario_max
     CALL get_Uma() RETURNING fecha_uma, version, importe       
    IF lr_ar_record.ft >= fecha_uma AND  version = 1 THEN
        LET ld_salario_max= importe
    END IF     

    LET ld_salario_max = ld_salario_max * 10

    IF ( lr_ar_record.sdo > ld_salario_max ) THEN
     LET lb_es_valido = FALSE
     RETURN lb_es_valido
   END IF
 END IF

 RETURN lb_es_valido


END FUNCTION


FUNCTION f_salario_en_rango_min(fecha_inicio,fecha_fin, sueldo)
	DEFINE fecha_inicio,ldt_fecha_ini LIKE cuenta_ind.fecha_inicio,
	       fecha_fin,ldt_fecha_fin LIKE cuenta_ind.fecha_termino,
			sueldo,menor_seis LIKE cuenta_ind.sueldo_issste,
			qrySalMin STRING,
			tope DYNAMIC ARRAY OF RECORD 
				minimo LIKE cuenta_ind.sueldo_issste
			END RECORD,
			li_bandSalMin,c1 SMALLINT
			
	LET li_bandSalMin = 1
	LET c1 = 1
	LET ldt_fecha_ini = "01/01/"||YEAR(fecha_inicio)
	LET ldt_fecha_fin=  "31/12/"||YEAR(fecha_fin)

 	IF (ldt_fecha_ini IS NOT NULL OR ldt_fecha_ini CLIPPED != "") AND (ldt_fecha_fin IS NOT NULL OR ldt_fecha_fin CLIPPED != "") 
        AND (sueldo IS NOT NULL OR sueldo CLIPPED != "") THEN 
        LET qrySalMin = "SELECT importe FROM c_salario_min\n"
            LET qrySalMin = qrySalMin CLIPPED, "WHERE\n"
            LET qrySalMin = qrySalMin CLIPPED, "fecha_alta BETWEEN '" CLIPPED, ldt_fecha_ini CLIPPED, "' AND '" CLIPPED, 
                            ldt_fecha_fin CLIPPED, "'\n"
            LET qrySalMin = qrySalMin CLIPPED, "AND zon_cve = 'A'\n"
            LET qrySalMin = qrySalMin CLIPPED, "AND importe >= ", sueldo,"\n"	
            --LET qrySalMin = qrySalMin CLIPPED, "AND componente_cve = 'CAT_SMIN'\n"
            LET qrySalMin = qrySalMin CLIPPED, "AND u_version NOT IN ('1')"
            LET qrySalMin = qrySalMin CLIPPED, "ORDER BY fecha_alta"
                            
            PREPARE prpSalMin0 FROM qrySalMin
            DECLARE drpSalMin0 CURSOR FOR prpSalMin0
        
            FOREACH drpSalMin0 INTO tope[c1].minimo
                IF sueldo < tope[c1].minimo  THEN
                    LET li_bandSalMin = FALSE
                    EXIT FOREACH
                END IF
                LET c1= c1+1 
		END FOREACH
    END IF
    IF YEAR(ldt_fecha_ini) < 1966 THEN 
        LET qrySalMin = "SELECT importe FROM c_salario_min WHERE fecha_alta = '01/01/1966' AND zon_cve = 'A'"
        PREPARE p_menor_seis FROM qrySalMin
        EXECUTE p_menor_seis INTO menor_seis
        IF sueldo < menor_seis THEN 
            LET li_bandSalMin = FALSE
        END IF 
    END IF  
	RETURN li_bandSalMin
	
END FUNCTION

FUNCTION get_Uma()
    DEFINE datos_uma RECORD LIKE cat_uma.*
    DEFINE query STRING  	
     DEFINE fecha_alta DATE 	
    DEFINE fecha_alt SMALLINT	
    LET fecha_alt = YEAR (TODAY)
    LET query = "SELECT fecha_inicio, u_version, importe FROM cat_uma where fecha_alta =(select max(fecha_alta) from cat_uma)"
    PREPARE getUma FROM query
    EXECUTE getUma  INTO datos_uma.fecha_inicio, datos_uma.u_version,datos_uma.importe
    RETURN datos_uma.fecha_inicio, datos_uma.u_version,datos_uma.importe	
END FUNCTION 


FUNCTION f_obten_salario_fecha(ldt_fecha_ini, ldt_fecha_fin, ld_sueldo,fechaaux_ini,fechaaux_fin)

    DEFINE
        # --- PARAMETROS DE LA FUNCION ---
        ldt_fecha_ini DATE,
        ldt_fecha_fin DATE,
        fechaaux_ini DATE,
        fechaaux_fin DATE, 
	-- INICIO INFOTEC TK - 2022084222 2022
		fecha_term_min DATE, 
		fecha_ini_uma DATE,
		fecha_ini_salmin DATE, 
	-- FIN INFOTEC TK - 2022084222 2022
		fecha_ene  DATE,
		fecha_feb  DATE,
        fecha_year SMALLINT,
        ld_sueldo LIKE cuenta_ind.sueldo_issste,
        

        # --- VARIABLES DE LA FUNCION ---
        ld_salario_max LIKE c_salario_min.importe,
        ls_sql STRING,
        lstr_querysal STRING,
        li_num SMALLINT,
        li_num_aux SMALLINT,
        li_total SMALLINT,
        ls_str STRING,
        ld_sueldo_fijo LIKE c_salario_min.importe     # ---SUELDO FIJO A 1966


    DEFINE ld_fecha_p  SMALLINT
    DEFINE ld_fecha_valsal, ls_band_periodo, c_per SMALLINT -- INFOTEC TK - 2023023251 GARANTIA
     DEFINE fecha_a DATE
     DEFINE fecha_uma, fecha_valida DATE -- INFOTEC TK - 2023023251 GARANTIA
    DEFINE version CHAR(1)
    DEFINE importe DECIMAL(12,2)

    CALL lar_salarios.clear()

    LET li_total = 0
	LET fecha_ini_uma = "01/02/2017"
	LET fecha_term_min = "31/01/2017"
    LET fecha_tern = fechaaux_fin

      LET ld_fecha_p = YEAR(ldt_fecha_ini)
      LET ld_fecha_p = ld_fecha_p + 1                                       
      LET ld_fecha_valsal=YEAR(ldt_fecha_ini)                                                                      

	LET lstr_querysal = "SELECT COUNT(*) FROM c_salario_min \n"
	LET lstr_querysal = lstr_querysal CLIPPED, "WHERE zon_cve = 'A'\n"
	LET lstr_querysal = lstr_querysal CLIPPED, "AND YEAR(fecha_alta) = "CLIPPED, YEAR(fechaaux_ini)
	
	PREPARE prpContPer FROM lstr_querysal
	EXECUTE prpContPer INTO c_per
	
	--display "Despliega Per CANTIDAD DE PERIODOS ANIO ::>>>",c_per,"<<<<<<"
	
	IF NOT c_per > 1 THEN 
		LET lstr_querysal = "SELECT fecha_alta FROM c_salario_min \n"
		LET lstr_querysal = lstr_querysal CLIPPED, "WHERE YEAR(fecha_alta) = " CLIPPED, YEAR(fechaaux_ini)
		LET lstr_querysal = lstr_querysal CLIPPED, " AND zon_cve = 'A' " 
		
		PREPARE prpfecAlt FROM lstr_querysal
		EXECUTE prpfecAlt INTO fecha_valida

		IF fecha_valida > fechaaux_ini THEN
			LET ls_band_periodo = 1
		END IF
	END IF                                                                 

        IF (YEAR(ldt_fecha_ini)< 1966 ) THEN
           LET lc_sql = "SELECT importe FROM c_salario_min WHERE fecha_alta = '01/01/1966' AND zon_cve = 'A' "
           PREPARE cursel03 FROM lc_sql
           EXECUTE cursel03 INTO ld_sueldo_fijo
        END IF
		#INICIO TK-2022084222 2022
		IF (bandMax = 0 AND bandInt = 0) OR (bandMin AND YEAR(ldt_fecha_ini) > 1966 ) THEN
			LET ld_sueldo = ld_sueldo / 10
		END IF
		IF ((bandMax OR bandInt) AND fechaaux_fin <= fecha_ini_uma) OR bandMin  THEN 
			LET ls_sql = ""
			LET ls_sql = "SELECT * FROM c_salario_min\n"
			LET ls_sql = ls_sql CLIPPED, "WHERE zon_cve = 'A'\n"
			IF bandMin =1 THEN 
				LET ls_sql = ls_sql CLIPPED, "AND importe > ", ld_sueldo ,"\n"
				LET ls_sql = ls_sql CLIPPED, "AND fecha_alta BETWEEN '" CLIPPED, ldt_fecha_ini CLIPPED,"' AND '" CLIPPED,ldt_fecha_fin CLIPPED, "'\n"
			ELSE
				LET ls_sql = ls_sql CLIPPED, "AND importe <= ", ld_sueldo ,"\n"
				LET ls_sql = ls_sql CLIPPED, "AND fecha_alta BETWEEN '" CLIPPED, ldt_fecha_ini CLIPPED,"' AND '" CLIPPED,fechaaux_fin CLIPPED, "'\n"
			END IF
            IF bandMin THEN 
                LET ls_sql = ls_sql CLIPPED, "AND u_version != '1'\n"
            END IF
			IF ls_band_periodo THEN
				LET ls_sql = ls_sql CLIPPED, "OR fecha_alta IN (SELECT max(fecha_alta) FROM c_salario_min WHERE fecha_alta < '"CLIPPED, ldt_fecha_ini CLIPPED,"' and zon_cve = 'A' AND u_version != '1')"
			END IF  
			LET ls_sql = ls_sql CLIPPED, "ORDER BY fecha_alta"
		END IF
		IF bandMin = 0 THEN
			IF fechaaux_ini >= fecha_ini_uma THEN
                LET ls_sql = "SELECT zon_cve, fecha_alta, u_version, importe, usuario, fecha_aud, hora_aud, componente_cve, ip_maquina FROM cat_uma\n"
                LET ls_sql = ls_sql CLIPPED, "WHERE\n"
                LET ls_sql = ls_sql CLIPPED, "fecha_alta BETWEEN '" CLIPPED, {fechaaux_ini}ldt_fecha_ini CLIPPED, "' AND '" CLIPPED, fechaaux_fin CLIPPED, "'\n"
                LET ls_sql = ls_sql CLIPPED, "AND zon_cve = 'A'\n"
                LET ls_sql = ls_sql CLIPPED, "AND importe <= ", ld_sueldo,"\n"
	       LET ls_sql = ls_sql CLIPPED, "OR fecha_alta IN (SELECT max(fecha_alta) FROM cat_uma WHERE fecha_alta < '"CLIPPED, ldt_fecha_ini CLIPPED,"' and zon_cve = 'A')\n"
                --END IF
                LET ls_sql = ls_sql CLIPPED, "ORDER BY fecha_alta"
			END IF
			IF fechaaux_ini < fecha_ini_uma AND fechaaux_fin > fecha_ini_uma THEN
				LET ls_sql = "SELECT * FROM c_salario_min\n"
				LET ls_sql = ls_sql CLIPPED, "WHERE\n"
				LET ls_sql = ls_sql CLIPPED, "fecha_alta BETWEEN '" CLIPPED, ldt_fecha_ini CLIPPED, "' AND '" CLIPPED, fecha_term_min CLIPPED, "'\n"
				LET ls_sql = ls_sql CLIPPED, "AND zon_cve = 'A'\n"
				LET ls_sql = ls_sql CLIPPED, "AND importe <= ", ld_sueldo,"\n"
                IF fechaaux_ini >= fecha_ini_uma THEN 
                    LET ls_sql = ls_sql CLIPPED, "AND u_version = '1'\n"
                END IF 
				IF ls_band_periodo THEN
					LET ls_sql = ls_sql CLIPPED, "OR fecha_alta IN (SELECT max(fecha_alta) FROM c_salario_min WHERE fecha_alta < '"CLIPPED, ldt_fecha_ini CLIPPED,"' and zon_cve = 'A')"
				END IF
				LET ls_sql = ls_sql CLIPPED, "UNION ALL\n"
				LET ls_sql = ls_sql CLIPPED, "SELECT zon_cve, fecha_alta, u_version, importe, usuario, fecha_aud, hora_aud, componente_cve, ip_maquina FROM cat_uma\n"
				LET ls_sql = ls_sql CLIPPED, "WHERE\n"
				LET ls_sql = ls_sql CLIPPED, "fecha_alta BETWEEN '" CLIPPED, fecha_ini_uma CLIPPED, "' AND '" CLIPPED, ldt_fecha_fin CLIPPED, "'\n"
				LET ls_sql = ls_sql CLIPPED, "AND zon_cve = 'A'\n"
				LET ls_sql = ls_sql CLIPPED, "AND importe <= ", ld_sueldo,"\n"
				LET ls_sql = ls_sql CLIPPED, "ORDER BY fecha_alta"
			END IF
		END IF
		
        PREPARE s_salmin FROM ls_sql
        DECLARE c_salmin CURSOR FOR s_salmin

        LET li_num = 1
        FOREACH c_salmin INTO lar_salarios[li_num].*
            IF (YEAR(ldt_fecha_ini) < 1966) AND (YEAR(lar_salarios[li_num].fecha_alta) < 1966) THEN
                LET lar_salarios[li_num].importe=ld_sueldo_fijo
            END IF
			IF NOT bandMin THEN --INFOTEC TK - 2022084222 2022	
				LET ld_salario_max = lar_salarios[li_num].importe * 10
				LET lar_salarios[li_num].importe = ld_salario_max
			ELSE
				LET ld_salario_max = lar_salarios[li_num].importe
                
			END IF
            LET li_num = li_num + 1
        END FOREACH
        CALL lar_salarios.deleteelement(li_num)
        LET li_total = lar_salarios.getlength()
        
        IF li_total > 1 THEN 
        
        ELSE
            IF (YEAR(ldt_fecha_ini) < 1966) THEN
                LET ld_salario_max = ld_sueldo_fijo
                IF NOT bandMin THEN --INFOTEC TK - 2022084222 2022
                    LET ld_salario_max = ld_salario_max * 10
                ELSE
                    LET ld_salario_max = ld_salario_max
                END IF
            END IF
            LET li_total = 1
        END IF 
        
    RETURN ld_salario_max, li_total

END FUNCTION

FUNCTION ajuste_periodos_min(li_numaux_2,li_numaux,ld_sueldo)
	DEFINE li_numaux,li_num,li_numaux_2 SMALLINT
	DEFINE		ld_sueldo LIKE c_salario_min.importe
	LET li_num = li_numaux

	IF li_num > 1 AND li_numaux_2 > 1 THEN -- INFOTEC TK 2023042760
		IF ((lar_salarios[li_numaux_2].importe <= ld_sueldo AND lar_salarios[li_numaux_2 - 1].importe <= ld_sueldo) OR 
           (lar_salarios[li_numaux_2].importe = lar_salarios[li_numaux_2 - 1].importe)) THEN
			CALL lar_salarios.deleteElement(li_numaux_2)
			LET li_numaux = li_numaux-1
		END IF
	END IF
	
	RETURN li_numaux
END FUNCTION

FUNCTION ajuste_periodos_max_int(li_numaux2,li_numaux, ld_sueldo)
	DEFINE li_numaux,li_num,li_numaux2 SMALLINT
	DEFINE		ld_sueldo LIKE c_salario_min.importe
	LET li_num = li_numaux
	IF li_num > 1 AND li_numaux2 > 1 THEN -- INFOTEC TK 2023042760
		IF ((lar_salarios[li_numaux2].importe >= ld_sueldo AND lar_salarios[li_numaux2 - 1].importe >= ld_sueldo) OR 
            (lar_salarios[li_numaux2].importe = lar_salarios[li_numaux2 - 1].importe)) THEN
			CALL lar_salarios.deleteElement(li_numaux2)
			LET li_numaux = li_numaux-1
		END IF

	END IF
	
	RETURN li_numaux
END FUNCTION