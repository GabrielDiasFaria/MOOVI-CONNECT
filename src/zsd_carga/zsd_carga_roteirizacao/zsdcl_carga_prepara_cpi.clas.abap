CLASS zsdcl_carga_prepara_cpi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Prepara o JSON com dados da carga e veículo fictício para teste.
    METHODS preparar IMPORTING iv_carga_id TYPE sysuuid_x16
      EXPORTING ev_json TYPE string ev_carga TYPE string ev_erro TYPE string
                et_remessas TYPE zsdcl_carga_valida_roteiro=>tt_remessas.
ENDCLASS.
CLASS zsdcl_carga_prepara_cpi IMPLEMENTATION.
  METHOD preparar.
    CLEAR: ev_json, ev_carga, ev_erro, et_remessas.
    SELECT SINGLE carga_id, status, vstel FROM zsdt_carga_h
      WHERE carga_id = @iv_carga_id INTO @DATA(ls_carga).
    IF sy-subrc <> 0 OR ls_carga-status <> '02' OR ls_carga-vstel IS INITIAL.
      ev_erro = 'Carga inexistente, não confirmada ou sem CD'. RETURN.
    ENDIF.
    AUTHORITY-CHECK OBJECT 'V_LIKP_VST'
      ID 'VSTEL' FIELD ls_carga-vstel
      ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      ev_erro = 'Sem autorização de exibição para o CD'. RETURN.
    ENDIF.
    SELECT SINGLE AddressID FROM I_ShippingPoint WHERE ShippingPoint = @ls_carga-vstel
      INTO @DATA(lv_endereco_id).
    IF sy-subrc <> 0 OR lv_endereco_id IS INITIAL.
      ev_erro = 'CD não encontrado ou sem endereço cadastrado'. RETURN.
    ENDIF.
    " A leitura privilegiada restringe-se ao endereço organizacional do CD
    " autorizado acima, com a representação padrão.
    SELECT AddressID, StreetName, HouseNumber, DistrictName, CityName, Region, PostalCode
      FROM I_OrganizationAddress WITH PRIVILEGED ACCESS
      WHERE AddressID = @lv_endereco_id AND AddressRepresentationCode = @space
      INTO TABLE @DATA(lt_endereco).
    IF lt_endereco IS INITIAL.
      ev_erro = 'Endereço organizacional do CD não encontrado'. RETURN.
    ELSEIF lines( lt_endereco ) > 1.
      ev_erro = 'Endereço organizacional do CD ambíguo'. RETURN.
    ENDIF.
    DATA(ls_endereco) = lt_endereco[ 1 ].
    IF ls_endereco-StreetName IS INITIAL OR ls_endereco-CityName IS INITIAL.
      ev_erro = 'Endereço do CD incompleto'. RETURN.
    ENDIF.
    SELECT SINGLE latitude, longitude FROM zsdt_latlong
      WHERE vstel = @ls_carga-vstel INTO @DATA(ls_geo_cd).
    IF sy-subrc <> 0.
      ev_erro = text-001. RETURN.
    ENDIF.
    IF ls_geo_cd-latitude < -90 OR ls_geo_cd-latitude > 90
       OR ls_geo_cd-longitude < -180 OR ls_geo_cd-longitude > 180.
      ev_erro = text-002. RETURN.
    ENDIF.
    SELECT vbeln FROM zsdt_carga_it WHERE carga_id = @iv_carga_id
      INTO TABLE @DATA(lt_itens).
    IF lt_itens IS INITIAL.
      ev_erro = 'Carga sem remessas'. RETURN.
    ENDIF.
    SELECT DeliveryDocument, ShipToParty, CustomerName, DeliveryStreet,
           DeliveryHouseNumber, DeliveryDistrict, DeliveryCity, DeliveryState,
           DeliveryPostalCode, GrossWeightKg, VolumeM3, Latitude, Longitude,
           CASE WHEN GrossWeightKg IS NULL THEN 'X' ELSE ' ' END AS peso_ausente,
           CASE WHEN VolumeM3 IS NULL THEN 'X' ELSE ' ' END AS volume_ausente,
           CASE WHEN Latitude IS NULL OR Longitude IS NULL THEN 'X' ELSE ' ' END AS geo_ausente
      FROM zi_carga_detalhe WHERE CargaId = @iv_carga_id
      INTO TABLE @DATA(lt_detalhe).
    IF lines( lt_detalhe ) <> lines( lt_itens ).
      ev_erro = 'Remessas da carga incompletas ou duplicadas'. RETURN.
    ENDIF.
    TRY.
        cl_system_uuid=>if_system_uuid_static~convert_uuid_x16(
          EXPORTING uuid = iv_carga_id IMPORTING uuid_c32 = DATA(lv_uuid) ).
      CATCH cx_uuid_error.
        ev_erro = 'UUID da carga inválido'. RETURN.
    ENDTRY.
    ev_carga = lv_uuid.
    DATA(ls_request) = VALUE zsdcl_carga_requisicao_cpi=>ty_requisicao(
      carga_id = ev_carga
      data_expedicao = |{ sy-datum(4) }-{ sy-datum+4(2) }-{ sy-datum+6(2) }|
      origem = VALUE #( cd = ls_carga-vstel
        endereco = |{ ls_endereco-StreetName }, { ls_endereco-HouseNumber } - { ls_endereco-DistrictName }, { ls_endereco-CityName }/{ ls_endereco-Region } { ls_endereco-PostalCode }| )
      veiculo = VALUE #( tipo = 'VUC' placa = 'TESTE' cap_peso_kg = 14000 cap_volume_m3 = 8 hora_saida = '08:00' hora_fim_turno = '18:00' ) ).
    ls_request-origem-lat = NEW decfloat34( ls_geo_cd-latitude ).
    ls_request-origem-lon = NEW decfloat34( ls_geo_cd-longitude ).
    LOOP AT lt_detalhe INTO DATA(ls_detalhe).
      IF NOT line_exists( lt_itens[ vbeln = ls_detalhe-DeliveryDocument ] )
         OR ls_detalhe-DeliveryStreet IS INITIAL OR ls_detalhe-DeliveryCity IS INITIAL
         OR ls_detalhe-ShipToParty IS INITIAL OR ls_detalhe-peso_ausente = 'X'
         OR ls_detalhe-volume_ausente = 'X'.
        ev_erro = 'Remessa com dados de endereço, cliente, peso ou volume ausentes'. RETURN.
      ENDIF.
      DATA(ls_parada) = VALUE zsdcl_carga_requisicao_cpi=>ty_parada(
        remessa = ls_detalhe-DeliveryDocument cliente = ls_detalhe-ShipToParty
        nome = ls_detalhe-CustomerName
        endereco = |{ ls_detalhe-DeliveryStreet }, { ls_detalhe-DeliveryHouseNumber } - { ls_detalhe-DeliveryDistrict }, { ls_detalhe-DeliveryCity }/{ ls_detalhe-DeliveryState } { ls_detalhe-DeliveryPostalCode }|
        peso_kg = ls_detalhe-GrossWeightKg volume_m3 = ls_detalhe-VolumeM3 ).
      IF ls_detalhe-geo_ausente <> 'X'.
        ls_parada-lat = NEW decfloat34( ls_detalhe-Latitude ).
        ls_parada-lon = NEW decfloat34( ls_detalhe-Longitude ).
      ENDIF.
      APPEND ls_parada TO ls_request-paradas.
      APPEND CONV string( ls_detalhe-DeliveryDocument ) TO et_remessas.
    ENDLOOP.
    ev_json = NEW zsdcl_carga_requisicao_cpi( )->serializar( ls_request ).
  ENDMETHOD.
ENDCLASS.
