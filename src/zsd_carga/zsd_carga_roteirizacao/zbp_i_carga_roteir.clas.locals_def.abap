CLASS lcl_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_carga,
             carga_id TYPE sysuuid_x16,
             lock TYPE REF TO zsdcl_carga_lock,
             paradas TYPE zsdcl_carga_valida_roteiro=>tt_paradas,
             confirmar TYPE abap_bool,
           END OF ty_carga,
           tt_cargas TYPE STANDARD TABLE OF ty_carga WITH EMPTY KEY.
    CLASS-DATA cargas TYPE tt_cargas.
    CLASS-METHODS limpar.
ENDCLASS.
