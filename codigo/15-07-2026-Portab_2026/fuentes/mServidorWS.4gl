IMPORT com

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
    (title: "Servicios de Transferencia de Derechos",
        version: "1.0",
        contact:(email: "transferenciaderechos@issste.gob.mx"))

MAIN
    DEFINE ret INTEGER
    DEFER INTERRUPT
    CALL com.WebServiceEngine.RegisterRestService("mWS1ConsultaBasicaISSSTE"           , "consultabasicaissste")
        CALL com.WebServiceEngine.RegisterRestService("mWS3ConsultaRobustaISSSTE"          , "consultarobustaissste")
        CALL com.WebServiceEngine.RegisterRestService("mWS6AvisoEstatusTransferenciaISSSTE", "avisoestatustransferenciaissste")
        CALL com.WebServiceEngine.RegisterRestService("mWs7DictamenBeneficioPensionario", "dictamenbeneficiopensionario")

    DISPLAY "Server started"
    CALL com.WebServiceEngine.Start()
    WHILE TRUE
        LET ret = com.WebServiceEngine.ProcessServices(-1)
        CASE ret
            WHEN 0
                DISPLAY "Request processed."
            WHEN -1
                DISPLAY "Timeout reached."
            WHEN -2
                DISPLAY "Disconnected from application server."
                EXIT PROGRAM # The Application server has closed the connection
            WHEN -3
                DISPLAY "Client Connection lost."
            WHEN -4
                DISPLAY "Server interrupted with Ctrl-C."
                EXIT PROGRAM -- see SUPLATINO-6355
            WHEN -9
                DISPLAY "Unsupported operation."
            WHEN -10
                DISPLAY "Internal server error."
                EXIT PROGRAM -- see SUPLATINO-6355
            WHEN -23
                DISPLAY "Deserialization error."
            WHEN -35
                DISPLAY "No such REST operation found."
            WHEN -36
                DISPLAY "Missing REST parameter."
            OTHERWISE
                DISPLAY "Unexpected server error " || ret || "."
                EXIT WHILE
        END CASE
        IF int_flag <> 0 THEN
            LET int_flag = 0
            EXIT WHILE
        END IF
    END WHILE
    DISPLAY "Server stopped"
END MAIN
