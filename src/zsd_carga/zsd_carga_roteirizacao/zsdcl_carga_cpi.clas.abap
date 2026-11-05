CLASS zsdcl_carga_cpi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Obtém token OAuth e envia a requisição de roteirização ao CPI.
    "! Erros são retornados sem credenciais ou conteúdo das respostas.
    METHODS executar
      IMPORTING iv_json       TYPE string
                iv_request_id TYPE string
      EXPORTING ev_json       TYPE string
                ev_http_code  TYPE i
                ev_erro       TYPE string.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_token,
             access_token TYPE string,
             token_type   TYPE string,
           END OF ty_token.
    METHODS post
      IMPORTING iv_destino      TYPE rfcdest
                iv_caminho      TYPE string
                iv_content_type TYPE string
                iv_body         TYPE string
                iv_token        TYPE string OPTIONAL
                iv_request_id   TYPE string OPTIONAL
      EXPORTING ev_body         TYPE string
                ev_http_code    TYPE i
                ev_erro         TYPE string.
ENDCLASS.

CLASS zsdcl_carga_cpi IMPLEMENTATION.
  METHOD executar.
    CLEAR: ev_json, ev_http_code, ev_erro.
    IF iv_json IS INITIAL OR iv_request_id IS INITIAL.
      ev_erro = 'Requisição ou identificador de requisição ausente'.
      RETURN.
    ENDIF.

    DATA lv_token_json TYPE string.
    post( EXPORTING iv_destino = 'ZCONNECT_CPI_AUTH'
                    iv_caminho = '/oauth/token'
                    iv_content_type = 'application/x-www-form-urlencoded'
                    iv_body = 'grant_type=client_credentials'
          IMPORTING ev_body = lv_token_json ev_http_code = ev_http_code ev_erro = ev_erro ).
    IF ev_erro IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA ls_token TYPE ty_token.
    TRY.
        /ui2/cl_json=>deserialize( EXPORTING json = lv_token_json CHANGING data = ls_token ).
      CATCH cx_root.
        ev_erro = 'Resposta de autenticação inválida'.
        RETURN.
    ENDTRY.
    CLEAR lv_token_json.
    IF ls_token-access_token IS INITIAL OR to_upper( ls_token-token_type ) <> 'BEARER'.
      ev_erro = 'Token OAuth ausente ou tipo não suportado'.
      RETURN.
    ENDIF.

    post( EXPORTING iv_destino = 'ZCONNECT_CPI'
                    iv_caminho = '/http/moovicola/logistica/v1/rotas'
                    iv_content_type = 'application/json'
                    iv_body = iv_json
                    iv_token = ls_token-access_token
                    iv_request_id = iv_request_id
          IMPORTING ev_body = ev_json ev_http_code = ev_http_code ev_erro = ev_erro ).
    CLEAR ls_token.
  ENDMETHOD.

  METHOD post.
    CLEAR: ev_body, ev_http_code, ev_erro.
    DATA lo_client TYPE REF TO if_http_client.
    cl_http_client=>create_by_destination(
      EXPORTING destination = iv_destino
      IMPORTING client = lo_client
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0 OR lo_client IS NOT BOUND.
      ev_erro = 'Não foi possível criar o cliente HTTP do destino'.
      RETURN.
    ENDIF.

    lo_client->propertytype_logon_popup = if_http_client=>co_disabled.
    lo_client->propertytype_redirect = if_http_client=>co_disabled.
    cl_http_utility=>set_request_uri( request = lo_client->request uri = iv_caminho ).
    lo_client->request->set_method( 'POST' ).
    lo_client->request->set_content_type( iv_content_type ).
    lo_client->request->set_header_field( name = 'Accept' value = 'application/json' ).
    IF iv_token IS NOT INITIAL.
      lo_client->request->set_header_field( name = 'Authorization' value = |Bearer { iv_token }| ).
    ENDIF.
    IF iv_request_id IS NOT INITIAL.
      lo_client->request->set_header_field( name = 'X-Request-ID' value = iv_request_id ).
    ENDIF.
    lo_client->request->set_cdata( iv_body ).
    lo_client->send( EXPORTING timeout = 30 EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      ev_erro = 'Falha de comunicação ao enviar requisição HTTP'.
    ELSE.
      lo_client->receive( EXCEPTIONS OTHERS = 1 ).
      IF sy-subrc <> 0.
        ev_erro = 'Falha de comunicação ao receber resposta HTTP'.
      ELSE.
        lo_client->response->get_status( IMPORTING code = ev_http_code ).
        IF ev_http_code < 200 OR ev_http_code >= 300.
          ev_erro = 'Serviço retornou erro HTTP'.
        ELSE.
          ev_body = lo_client->response->get_cdata( ).
        ENDIF.
      ENDIF.
    ENDIF.
    lo_client->close( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.
ENDCLASS.
