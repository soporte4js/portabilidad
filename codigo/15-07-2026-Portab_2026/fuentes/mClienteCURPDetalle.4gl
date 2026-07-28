IMPORT util
GLOBALS "ConsultaCurpDetalleService_ConsultaCurpDetalleServiceHttpsSoap12Endpoint.inc"

DEFINE wsstatus SMALLINT
DEFINE a_curpdetail DYNAMIC ARRAY OF RECORD
    curp_title    STRING,
    curp_value    STRING 
END RECORD
DEFINE a_xmlstatus DYNAMIC ARRAY OF RECORD
    mess    STRING,
    val     STRING 
END RECORD
DEFINE array_length     INTEGER
DEFINE xml_array_length INTEGER
DEFINE xml_file    STRING
DEFINE i, j INTEGER
DEFINE muestra_cadena STRING
DEFINE curp_fam VARCHAR(18)

--FUNCTION fnBuscaCURPDetalle(lapellido_paterno, lapellido_materno, lnombres, lfecha_nac, lsexo)
MAIN
    DEFINE lapellido_paterno STRING 
    DEFINE lapellido_materno STRING
    DEFINE lnombres          STRING
    DEFINE lfecha_nac        DATE
    DEFINE lsexo             STRING
    DEFINE crip              STRING
    DEFINE file_out          base.Channel

    LET lapellido_paterno = arg_val(1)
    LET lapellido_materno = arg_val(2)
    LET lnombres          = arg_val(3)
    LET lfecha_nac        = arg_val(4)
    LET lsexo             = arg_val(5)

    CALL BuscaCURP_RENAPO_detalle(lapellido_paterno, lapellido_materno, lnombres, lfecha_nac, lsexo)
    RETURNING curp_fam, crip
    
    DISPLAY "###### DATOS CURP DETALLE ######"
    DISPLAY "--------------------------------------------"
    DISPLAY "CURP: ", curp_fam
    DISPLAY "CRIP: ", crip

    TRY
        CALL base.Channel.create() RETURNING file_out
        CALL file_out.openFile("fileoutcurpdetalle"||curp_fam||".txt","w")
        CALL file_out.writeLine(curp_fam)
        CALL file_out.writeLine(crip)
        CALL file_out.close()
    CATCH
    END TRY
    
    --RETURN curp_fam, crip
END MAIN

FUNCTION BuscaCURP_RENAPO_detalle(ape_pat_fam, ape_mat_fam, nombre_fam, fec_nac_fam, sexo)
    
    DEFINE ape_pat_fam,ape_mat_fam, nombre_fam, sexo VARCHAR(100)
    DEFINE fec_nac_fam DATE
    DEFINE crip STRING
    
    LET ConsultaCurpDetalleService_ConsultaCurpDetalleServiceHttpsSoap12EndpointEndpoint.Address.Uri = get_endpoint_ws("mycurpdetalle")
        LET ns2consultarCurpDetalle.datos.cveAlfaEntFedNac  = "" 
        LET ns2consultarCurpDetalle.datos.cveEntidadEmisora = ""
        LET ns2consultarCurpDetalle.datos.cveUsuario        = "wsgestion" 
        LET ns2consultarCurpDetalle.datos.fechaNacimiento   = fec_nac_fam
        LET ns2consultarCurpDetalle.datos.nombre            = nombre_fam
        LET ns2consultarCurpDetalle.datos.password          = "wsgestion2011"
        LET ns2consultarCurpDetalle.datos.primerApellido    = ape_pat_fam
        LET ns2consultarCurpDetalle.datos.segundoApellido   = ape_mat_fam
        LET ns2consultarCurpDetalle.datos.sexo              = sexo
        LET ns2consultarCurpDetalle.datos.tipoTransaccion   = "1"
    
  LET wsstatus = consultarCurpDetalle_g()
  
   IF wsstatus != 0 THEN
        DISPLAY "Error >>>> :", wsError.code
        DISPLAY "Error >>>> :", wsError.codeNS 
        DISPLAY "Error >>>> :", wsError.description 
        DISPLAY "Error >>>> :", wsError.action 
   ELSE
   CALL receive_xml_string_detalle(ns2consultarCurpDetalleResponse.return) 
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
                LET curp_fam =  a_curpdetail[i].curp_value
            END IF
            IF a_curpdetail[i].curp_title = "crip" THEN
                LET crip =  a_curpdetail[i].curp_value
            END IF
            
        END FOR
    END IF
    RETURN curp_fam, crip
END FUNCTION

FUNCTION receive_xml_string_detalle(string_from_ws)
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
           FOR i=1 to a.getLength()
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
   IF FGL_GETENV("OS")= "Windows_NT" THEN
      LET cmd = "del /F ", file
      --RUN cmd
   ELSE 
      LET cmd = "rm ", file
      --RUN cmd
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