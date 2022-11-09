CLASS zcl_wd_mermaid_docflow DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF c_action,
        node_click          TYPE string VALUE `actionNodeClick`,
        change_docking_side TYPE string VALUE `actionChangeDockingSide`,
      END OF c_action.
    CLASS-METHODS:
      get_inst RETURNING VALUE(result) TYPE REF TO zcl_wd_mermaid_docflow.
    METHODS:
      display IMPORTING tree    TYPE REF TO cl_gui_alv_tree
                        docflow TYPE document_flow_alv_tt.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA:
      instance TYPE REF TO zcl_wd_mermaid_docflow.
    DATA:
      tree                     TYPE REF TO cl_gui_alv_tree,
      docflow                  TYPE document_flow_alv_tt,
      diagram_container_right  TYPE REF TO cl_gui_docking_container,
      diagram_right            TYPE REF TO lcl_diagram,
      diagram_container_bottom TYPE REF TO cl_gui_docking_container,
      diagram_bottom           TYPE REF TO lcl_diagram,
      docking_side             TYPE i.
    METHODS:
      create_diagram,
      handle_parse_error_ocurred FOR EVENT parse_error_ocurred OF lcl_diagram IMPORTING error,
      handle_link_click FOR EVENT link_click OF lcl_diagram IMPORTING action frame getdata postdata query_table,
      generate_diagram_source_code RETURNING VALUE(result) TYPE string,
      build_node_id IMPORTING docflow_line  TYPE document_flow_alv_struc
                    RETURNING VALUE(result) TYPE string.
ENDCLASS.



CLASS zcl_wd_mermaid_docflow IMPLEMENTATION.


  METHOD get_inst.
    IF instance IS NOT BOUND.
      instance = NEW #( ).
    ENDIF.
    result = instance.
  ENDMETHOD.


  METHOD display.
    IF docking_side = 0.
      docking_side = cl_gui_docking_container=>dock_at_bottom.
    ENDIF.
    IF diagram_container_bottom IS NOT BOUND.
      create_diagram( ).
    ENDIF.
    me->docflow = docflow.
    me->tree = tree.

    CASE docking_side.
      WHEN cl_gui_docking_container=>dock_at_bottom.
        diagram_container_right->set_visible( EXPORTING visible = abap_false
                                              EXCEPTIONS OTHERS = 0 ).
        diagram_container_bottom->set_visible( EXPORTING visible = abap_true
                                               EXCEPTIONS OTHERS = 0 ).
        diagram_bottom->set_docking_side( docking_side ).
        diagram_bottom->set_source_code_string( generate_diagram_source_code( ) ).
        diagram_bottom->display( ).
      WHEN cl_gui_docking_container=>dock_at_right.
        diagram_container_right->set_visible( EXPORTING visible = abap_true
                                              EXCEPTIONS OTHERS = 0 ).
        diagram_container_bottom->set_visible( EXPORTING visible = abap_false
                                               EXCEPTIONS OTHERS = 0 ).
        diagram_right->set_docking_side( docking_side ).
        diagram_right->set_source_code_string( generate_diagram_source_code( ) ).
        diagram_right->display( ).
    ENDCASE.

  ENDMETHOD.


  METHOD create_diagram.
    diagram_container_bottom = NEW #( side = cl_gui_docking_container=>dock_at_bottom
                                      extension = 100 ).
    diagram_container_right = NEW #( side = cl_gui_docking_container=>dock_at_right
                                     extension = 800 ).

    diagram_bottom = NEW lcl_diagram( parent = diagram_container_bottom ).
    diagram_right = NEW lcl_diagram( parent = diagram_container_right ).

    DATA(diagram_config) = diagram_bottom->get_configuration( ).
    diagram_config-security_level = 'loose'.
    diagram_bottom->set_configuration( diagram_config ).
    diagram_right->set_configuration( diagram_config ).

    diagram_bottom->set_scrollbars_hidden( abap_false ).
    diagram_right->set_scrollbars_hidden( abap_false ).

    SET HANDLER handle_parse_error_ocurred
                handle_link_click
    FOR diagram_bottom.
    SET HANDLER handle_parse_error_ocurred
                handle_link_click
    FOR diagram_right.
  ENDMETHOD.


  METHOD handle_parse_error_ocurred.
    MESSAGE error TYPE 'I'.
  ENDMETHOD.


  METHOD handle_link_click.
    CASE action.
      WHEN c_action-node_click.
        DATA(docflow_index) = ||.
        LOOP AT query_table ASSIGNING FIELD-SYMBOL(<param>).
          docflow_index = docflow_index && <param>-value.
        ENDLOOP.
        tree->set_selected_nodes( EXPORTING it_selected_nodes = VALUE #( ( CONV i( docflow_index ) ) )
                                  EXCEPTIONS OTHERS = 1 ).
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
          EXPORTING
            functioncode = 'BEAN' " "display document
          EXCEPTIONS
            OTHERS       = 0.
      WHEN c_action-change_docking_side.
        CASE docking_side.
          WHEN cl_gui_docking_container=>dock_at_bottom.
            docking_side = cl_gui_docking_container=>dock_at_right.
          WHEN cl_gui_docking_container=>dock_at_right.
            docking_side = cl_gui_docking_container=>dock_at_bottom.
        ENDCASE.
        CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
          EXPORTING
            functioncode = '='
          EXCEPTIONS
            OTHERS       = 0.
    ENDCASE.
  ENDMETHOD.


  METHOD generate_diagram_source_code.
    TYPES:
      BEGIN OF ty_node,
        id      TYPE string,
        docnum  TYPE document_flow_alv_struc-docnum,
        itemnum TYPE document_flow_alv_struc-itemnum,
        value   TYPE string,
      END OF ty_node,
      ty_nodes         TYPE TABLE OF ty_node,
      ty_range_itemnum TYPE RANGE OF document_flow_alv_struc-itemnum.
    CONSTANTS:
      crlf     LIKE cl_abap_char_utilities=>cr_lf VALUE cl_abap_char_utilities=>cr_lf,
      itemnum0 TYPE document_flow_alv_struc-itemnum VALUE '000000'.
    DATA:
      nodes TYPE ty_nodes,
      links TYPE TABLE OF string.

    LOOP AT docflow TRANSPORTING NO FIELDS WHERE itemnum <> itemnum0.
      DATA(item_mode) = abap_true.
      EXIT.
    ENDLOOP.

    " build nodes table
    LOOP AT docflow ASSIGNING FIELD-SYMBOL(<docflow_line>).
      DATA(docflow_index) = sy-tabix.
      IF item_mode = abap_true
      AND <docflow_line>-itemnum = itemnum0.
        CONTINUE.
      ENDIF.
      DATA(node_id) = build_node_id( <docflow_line> ).
      IF NOT line_exists( nodes[ id = node_id ] ).
        IF item_mode = abap_false
        OR <docflow_line>-itemnum = itemnum0.
          DATA(node_item_text) = |{ <docflow_line>-doctype } { condense( |{ <docflow_line>-docnum ALPHA = OUT }| ) }|.
        ELSE.
          node_item_text = |{ <docflow_line>-doctype } { condense( |{ <docflow_line>-docnum ALPHA = OUT }| ) } / {
                                                         condense( |{ <docflow_line>-itemnum ALPHA = OUT }| ) }|.
        ENDIF.
        APPEND VALUE #( id = node_id
                        docnum = <docflow_line>-docnum
                        itemnum = <docflow_line>-itemnum
                        value = | { node_id }[{ SWITCH #( <docflow_line>-focus
                                                            WHEN abap_true THEN |[{ node_item_text }]|
                                                            WHEN abap_false THEN node_item_text ) }] |
        ) TO nodes.
      ENDIF.
      APPEND |click { node_id } call submitSapEvent("{ docflow_index }","actionNodeClick");| TO links.
    ENDLOOP.

    " TB -> top to bottom
    " LR -> left to right
    CASE docking_side.
      WHEN cl_gui_docking_container=>dock_at_bottom.
        DATA(chart_flow) = |LR|.
      WHEN cl_gui_docking_container=>dock_at_right.
        chart_flow = |TB|.
    ENDCASE.

    " build diagram source code with nodes and node texts
    result =  |flowchart { chart_flow }\n|
           && REDUCE string( INIT val = ||
                             FOR node IN nodes
                             NEXT val = val && node-value && crlf ).

    " build source code with node relationships
    LOOP AT nodes ASSIGNING FIELD-SYMBOL(<node>).
      DATA(child_nodes) = ||.

      IF item_mode = abap_true.
        DATA(range_itemnum) = VALUE ty_range_itemnum( ( sign = 'I'
                                                        option = 'EQ'
                                                        low = <node>-itemnum ) ).
      ENDIF.

      LOOP AT docflow ASSIGNING <docflow_line> WHERE docnuv = <node>-docnum
                                               AND itemnuv IN range_itemnum.
        node_id = build_node_id( <docflow_line> ).
        IF child_nodes IS INITIAL.
          child_nodes = node_id.
        ELSE.
          child_nodes = |{ child_nodes } & { node_id }|.
        ENDIF.
      ENDLOOP.
      IF child_nodes IS NOT INITIAL.
        result = |{ result }{ <node>-id } --> { child_nodes }\n|.
      ENDIF.
    ENDLOOP.

    " append click actions to diagram source code
    result = result && crlf && concat_lines_of( table = links
                                                sep = crlf ).


  ENDMETHOD.


  METHOD build_node_id.
    result = docflow_line-docnum && docflow_line-itemnum.
  ENDMETHOD.



ENDCLASS.
