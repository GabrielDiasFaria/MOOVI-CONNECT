CLASS zsdcl_carga_requisicao_cpi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_origem,
             cd       TYPE string,
             endereco TYPE string,
             lat      TYPE REF TO decfloat34,
             lon      TYPE REF TO decfloat34,
           END OF ty_origem,
           BEGIN OF ty_veiculo,
             tipo          TYPE string,
             placa         TYPE string,
             cap_peso_kg   TYPE decfloat34,
             cap_volume_m3 TYPE decfloat34,
             hora_saida    TYPE string,
             hora_fim_turno TYPE string,
           END OF ty_veiculo,
           BEGIN OF ty_parada,
             remessa   TYPE string,
             cliente   TYPE string,
             nome      TYPE string,
             endereco  TYPE string,
             lat       TYPE REF TO decfloat34,
             lon       TYPE REF TO decfloat34,
             peso_kg   TYPE decfloat34,
             volume_m3 TYPE decfloat34,
             janela    TYPE REF TO string,
           END OF ty_parada,
           tt_paradas TYPE STANDARD TABLE OF ty_parada WITH EMPTY KEY,
           BEGIN OF ty_requisicao,
             carga_id       TYPE string,
             data_expedicao TYPE string,
             origem         TYPE ty_origem,
             veiculo        TYPE ty_veiculo,
             retornar_ao_cd TYPE abap_bool,
             paradas        TYPE tt_paradas,
           END OF ty_requisicao.
    "! Serializa os dados fornecidos conforme o contrato do CPI; não consulta nem valida cadastros.
    METHODS serializar IMPORTING is_requisicao TYPE ty_requisicao
      RETURNING VALUE(rv_json) TYPE string.
ENDCLASS.

CLASS zsdcl_carga_requisicao_cpi IMPLEMENTATION.
  METHOD serializar.
    DATA(lt_nomes) = VALUE /ui2/cl_json=>name_mappings(
      ( abap = 'RETORNAR_AO_CD' json = 'retornarAoCD' )
      ( abap = 'CAP_PESO_KG' json = 'capPesoKg' )
      ( abap = 'CAP_VOLUME_M3' json = 'capVolumeM3' )
      ( abap = 'PESO_KG' json = 'pesoKg' )
      ( abap = 'VOLUME_M3' json = 'volumeM3' ) ).
    rv_json = /ui2/cl_json=>serialize( data = is_requisicao
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case name_mappings = lt_nomes ).
  ENDMETHOD.
ENDCLASS.
