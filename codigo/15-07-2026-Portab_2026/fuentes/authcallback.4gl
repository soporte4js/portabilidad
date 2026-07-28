IMPORT security

FUNCTION getUserAuth(dbspec STRING) RETURNS (STRING,STRING)

  DEFINE un, ep STRING
  LET un = fgl_getResource("dbi.database."||dbspec||".username") 
  LET ep = fgl_getResource("dbi.database."||dbspec||".password.encrypted")
  RETURN un, decrypt_user_password(ep)

END FUNCTION

FUNCTION decrypt_user_password(enc_pass)
    DEFINE enc_pass STRING
    DEFINE txt_pass STRING
    DEFINE err_msg   STRING

    TRY
        CALL security.Base64.ToString(enc_pass) RETURNING txt_pass
    CATCH
        LET err_msg="Error while decrypting the user's password : ",STATUS
        EXIT PROGRAM
    END TRY

    RETURN txt_pass

END FUNCTION