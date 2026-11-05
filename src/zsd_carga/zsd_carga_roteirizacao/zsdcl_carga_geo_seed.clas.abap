CLASS zsdcl_carga_geo_seed DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zsdcl_carga_geo_seed IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    IF sy-sysid <> 'S4H' OR sy-mandt <> '250'.
      out->write( text-001 ).
      RETURN.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD 'ZSDT_LATLONG'
      ID 'ACTVT' FIELD '02'.
    IF sy-subrc <> 0.
      out->write( text-002 ).
      RETURN.
    ENDIF.

    SELECT SINGLE vstel FROM tvst WHERE vstel = '1410' INTO @DATA(lv_vstel).
    IF sy-subrc <> 0.
      out->write( text-003 ).
      RETURN.
    ENDIF.

    DATA(ls_latlong) = VALUE zsdt_latlong(
      client = sy-mandt
      vstel = lv_vstel
      latitude = CONV #( '-23.484186575646547' )
      longitude = CONV #( '-46.855115732100540' ) ).
    TRY.
        INSERT zsdt_latlong FROM @ls_latlong.
        IF sy-subrc = 0.
          COMMIT WORK AND WAIT.
          out->write( text-004 ).
        ELSE.
          out->write( text-005 ).
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        ROLLBACK WORK.
        out->write( text-006 ).
        out->write( lx_sql->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
