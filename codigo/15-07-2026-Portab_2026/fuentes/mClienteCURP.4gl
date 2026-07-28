IMPORT util
IMPORT FGL ConsultaPorCurpService_ConsultaPorCurpServiceHttpsSoap12Endpoint

DEFINE wsstatus     SMALLINT
DEFINE a_curpdetail DYNAMIC ARRAY OF RECORD
    curp_title      STRING,
    curp_value      STRING
END RECORD
DEFINE a_xmlstatus  DYNAMIC ARRAY OF RECORD
    mess    STRING,
    val     STRING
END RECORD
DEFINE array_length     INTEGER
DEFINE xml_array_length INTEGER
DEFINE xml_file         STRING
DEFINE i, j             INTEGER
DEFINE muestra_cadena   STRING
DEFINE rfc              VARCHAR(10)

DEFINE rcurp, rape_pat_fam, rape_mat_fam, rnombre_fam, rent_i, rsexo, rrfc VARCHAR(100)
DEFINE rfec_nac_fam DATE

MAIN
    DEFINE lCURP              STRING
    DEFINE statusCurp         STRING
    DEFINE nivelConfiabilidad INTEGER
    DEFINE curpHistoricas     STRING
    DEFINE idx                INTEGER
    DEFINE estatus_operacion  STRING
    DEFINE tipo_error         STRING
    DEFINE CodigoError        STRING
    DEFINE nacionalidad       STRING
    DEFINE file_out           base.Channel

    LET lCURP = arg_val(1)

    CALL BuscaCURP_RENAPO(lCURP) RETURNING rcurp, rape_pat_fam,
    rape_mat_fam, rnombre_fam, rent_i, rfec_nac_fam, rsexo, rrfc, statusCurp,
    nivelConfiabilidad, curpHistoricas, nacionalidad

    DISPLAY "DBDATE=",fgl_getenv("DBDATE")
    DISPLAY 10 SPACES, "###### DATOS CURP ######"
    DISPLAY "--------------------------------------------"
    DISPLAY 14 SPACES, "CURP: ", rcurp
    DISPLAY 11 SPACES, "Paterno: ", rape_pat_fam
    DISPLAY 11 SPACES, "Materno: ", rape_mat_fam
    DISPLAY 12 SPACES, "Nombre: ", rnombre_fam
    DISPLAY 14 SPACES, "Sexo: ", rsexo
    DISPLAY 10 SPACES, "Fec. Nac: ", rfec_nac_fam
    DISPLAY 7 SPACES, "Entidad Nac: ", rent_i
    DISPLAY 6 SPACES, "Nacionalidad: ", nacionalidad
    DISPLAY 8 SPACES, "StatusCurp: ", statusCurp
    DISPLAY "NivelConfiabilidad: ", nivelConfiabilidad
    DISPLAY 4 SPACES, "CURPHistoricas: ", curpHistoricas

    FOR idx = 1 TO a_xmlstatus.getLength()
        IF a_xmlstatus[idx].mess = "statusOper" THEN
            LET estatus_operacion = a_xmlstatus[idx].val
        END IF
        IF a_xmlstatus[idx].mess = "TipoError" THEN
            LET tipo_error = a_xmlstatus[idx].val
        END IF
        IF a_xmlstatus[idx].mess = "CodigoError" THEN
            LET CodigoError = a_xmlstatus[idx].val
        END IF
    END FOR

    TRY
        CALL base.Channel.create() RETURNING file_out

        CALL file_out.openFile("fileoutcurp"||lCURP||".txt","w")
        CALL file_out.writeLine(rcurp)
        CALL file_out.writeLine(rape_pat_fam)
        CALL file_out.writeLine(rape_mat_fam)
        CALL file_out.writeLine(rnombre_fam)
        CALL file_out.writeLine(rsexo)
        CALL file_out.writeLine(rfec_nac_fam)
        CALL file_out.writeLine(rent_i)
        CALL file_out.writeLine(nacionalidad)
        CALL file_out.writeLine(statusCurp)
        CALL file_out.writeLine(nivelConfiabilidad)
        CALL file_out.writeLine(curpHistoricas)
        CALL file_out.writeLine(tipo_error)
        CALL file_out.writeLine(CodigoError)
        CALL file_out.writeLine(estatus_operacion)
        CALL file_out.writeLine(rrfc)
        CALL file_out.close()
    CATCH
    END TRY
END MAIN


FUNCTION BuscaCURP_RENAPO(curp)
    DEFINE curp_2, curp VARCHAR(18)
    DEFINE ape_pat_fam_2, ape_mat_fam_2, nombre_fam_2, sexo CHAR (100)
    DEFINE fec_nac_fam_2 DATE
    DEFINE ent_i_2 CHAR(02)
    DEFINE statusCurp STRING
    DEFINE nivelConfiabilidad INTEGER
    DEFINE curpHistoricas STRING
    DEFINE nacionalidad STRING

    LET ConsultaPorCurpService_ConsultaPorCurpServiceHttpsSoap12EndpointEndpoint.Address.Uri = get_endpoint_ws("mycurp")
    LET ns2consultarPorCurp.datos.cveCurp = curp
    LET ns2consultarPorCurp.datos.cveEntidadEmisora = ""
    LET ns2consultarPorCurp.datos.tipoTransaccion = "1"
    LET ns2consultarPorCurp.datos.usuario = "WS342001"
    LET ns2consultarPorCurp.datos.password = "GELO3412"

    LET wsstatus = consultarPorCurp_g()

    IF wsstatus != 0 THEN
        DISPLAY "Error >>>> :", wsstatus
    ELSE
        CALL receive_xml_string(ns2consultarPorCurpResponse.return)
        RETURNING a_curpdetail, a_xmlstatus, array_length, xml_array_length, xml_file
        CALL del_xmlfile(xml_file)


        FOR i=1 TO array_length-1
            #--DETALLE DE XML RESPONSE
            FOR j=1 TO xml_array_length
                IF a_xmlstatus[j].mess='message' AND a_xmlstatus[j+2].val='06' THEN
                    LET muestra_cadena = a_xmlstatus[j].val
                END IF

            END FOR

            IF a_curpdetail[i].curp_title = "CURP" THEN
                LET curp_2 =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "apellido1" THEN
                LET ape_pat_fam_2 =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "apellido2" THEN
                LET ape_mat_fam_2 =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "nombres" THEN
                LET nombre_fam_2 =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "fechNac" THEN
                LET fec_nac_fam_2 =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "cveEntidadNac" THEN
                LET ent_i_2=  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "sexo" THEN
                LET sexo=  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "CURP" THEN
                LET rfc =  a_curpdetail[i].curp_value
                LET rfc = curp [1,10]
            END IF
            IF a_curpdetail[i].curp_title = "nacionalidad" THEN
                LET nacionalidad =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "statusCurp" THEN
                LET statusCurp =  a_curpdetail[i].curp_value
                LET statusCurp = a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "nivelConfiabilidad" THEN
                LET nivelConfiabilidad =  a_curpdetail[i].curp_value
                LET nivelConfiabilidad = a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "curpHistoricas" THEN
                LET curpHistoricas =  a_curpdetail[i].curp_value
                LET curpHistoricas = a_curpdetail[i].curp_value
            END IF

        END FOR
    END IF

    RETURN curp_2, ape_pat_fam_2, ape_mat_fam_2, nombre_fam_2, ent_i_2,
           fec_nac_fam_2, sexo, rfc, statusCurp, nivelConfiabilidad,
           curpHistoricas, nacionalidad

END FUNCTION

FUNCTION receive_xml_string(string_from_ws)
DEFINE string_from_ws STRING
DEFINE r         om.XmlReader
DEFINE a         om.SaxAttributes
DEFINE e         STRING
DEFINE i, l, j   INTEGER
DEFINE rand_val  INTEGER
DEFINE xml_file  STRING
DEFINE ch        base.Channel
DEFINE da_today  STRING
DEFINE mo_today  STRING
DEFINE ye_today  STRING
DEFINE h_today   DATETIME HOUR TO HOUR
DEFINE m_today   DATETIME MINUTE TO MINUTE
DEFINE s_today   DATETIME SECOND  TO SECOND
DEFINE r_tag     DYNAMIC ARRAY OF RECORD
    tag   STRING,
    val   STRING
END RECORD
DEFINE r_status  DYNAMIC ARRAY OF RECORD
    mess    STRING,
    val     STRING
END RECORD
DEFINE cnt, cnt2, cnt3   INTEGER
DEFINE a_curpdetail DYNAMIC ARRAY OF RECORD
    curp_title    STRING,
    curp_value    STRING
END RECORD
DEFINE a_xmlstatus DYNAMIC ARRAY OF RECORD
mess   STRING,
val    STRING
END RECORD

   --generating a file to work easly with xmlreader class
   LET ch = base.Channel.create()
   LET rand_val = util.Math.rand(4)
   LET da_today = DAY(TODAY)
   LET mo_today = MONTH(TODAY)
   LET ye_today = YEAR(TODAY)
   LET h_today = CURRENT
   LET m_today = CURRENT
   LET s_today = CURRENT

   LET xml_file = "curp_", da_today, mo_today, ye_today, "_",h_today, m_today, s_today || rand_val, ".xml"

   CALL ch.openFile( xml_file, "w" )
   CALL ch.write(string_from_ws)
   CALL ch.close()
   --using xmlreader class to read xml file
   LET r = om.XmlReader.createFileReader(xml_file)
   LET a = r.getAttributes()
   LET l = 0
   LET cnt = 1
   LET cnt2 = 1
   LET cnt3 = 1
   LET e = r.read()
   WHILE e IS NOT NULL
      CASE e
        WHEN "StartElement"
           LET l=l+1
           LET r_tag[cnt].tag= r.getTagName()
           LET cnt2 = cnt
           LET a = r.getAttributes()
           FOR i=1 to a.getLength()
              DISPLAY l SPACES,"  ",  a.getName(i)," = ", a.getValueByIndex(i)
              LET r_status[i].mess = a.getName(i)
              LET r_status[i].val = a.getValueByIndex(i)
              LET cnt3 = i
           END FOR
           LET cnt = cnt + 1
        WHEN "Characters"
           LET r_tag[cnt2].val = r.getCharacters()
           LET cnt2 = cnt + 1
        WHEN "EndElement"
           LET l=l-1
      END CASE
      LET e=r.read()
    END WHILE

   FOR i=1 TO cnt-1
      IF i=1 THEN
         LET a_curpdetail[i].curp_title = r_tag[i].tag
         LET a_curpdetail[i].curp_value = "xml_status"
         FOR j=1 TO cnt3
            LET a_xmlstatus[j].mess = r_status[j].mess
            LET a_xmlstatus[j].val = r_status[j].val
         END FOR
      ELSE
         LET a_curpdetail[i].curp_title = r_tag[i].tag
         LET a_curpdetail[i].curp_value =  r_tag[i].val
      END IF
   END FOR
   RETURN a_curpdetail, a_xmlstatus, cnt, cnt3, xml_file
END FUNCTION
--
#4JS: Function that deletes a file
--arguments= 1: file to delete
--
FUNCTION del_xmlfile(file)
DEFINE file  STRING
DEFINE cmd    STRING
   IF fgl_getenv("OS")= "Windows_NT" THEN
      LET cmd = "del /F ", file
      RUN cmd
   ELSE
      LET cmd = "rm ", file
      RUN cmd
   END IF
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
    END IF

    RETURN ws_url

END FUNCTION