*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_diagram IMPLEMENTATION.

  METHOD generate_html.
    CONSTANTS:
      style_tag TYPE string VALUE `</style>`,
      body_tag  TYPE string VALUE `</body>`.

    DATA(button_style) =  |.changeDockPositionButton \{\n|      ##NO_TEXT
                       &&     |opacity: 0;\n|                   ##NO_TEXT
                       &&     |position: fixed;\n|              ##NO_TEXT
                       &&     |top: 5px;\n|                     ##NO_TEXT
                       &&     |right: 5px;\n|                   ##NO_TEXT
                       &&     |background-color: inherit;\n|    ##NO_TEXT
                       &&     |color: inherit;\n|               ##NO_TEXT
                       &&     |border-radius: 3px;\n|           ##NO_TEXT
                       &&     |text-align: center;\n|           ##NO_TEXT
                       &&     |border-style: solid;\n|          ##NO_TEXT
                       &&     |padding: 5px;\n|                 ##NO_TEXT
                       &&     |text-decoration: none;\n|        ##NO_TEXT
                       &&     |border-width: 1px;\n|            ##NO_TEXT
                       &&     |box-shadow: 2px 2px 3px #999;\n| ##NO_TEXT
                       && |\}\n|                                ##NO_TEXT
                       && |.changeDockPositionButton:hover\{\n| ##NO_TEXT
                       &&     |opacity: 0.8;\n|                 ##NO_TEXT
                       && |\}\n|                                ##NO_TEXT
                       && |{ style_tag }\n|.

    CASE docking_side.
      WHEN cl_gui_docking_container=>dock_at_bottom.
        DATA(button_text) = |{ 'Move to Right'(001) }|.
      WHEN cl_gui_docking_container=>dock_at_right.
        button_text = 'Move to Bottom'(002).
    ENDCASE.

    DATA(button_html) =
       |<a href="#" onclick="submitSapEvent('','{ zcl_wd_mermaid_docflow=>c_action-change_docking_side }')"|
    && |class="changeDockPositionButton">{ button_text }</a>|
    && |{ body_tag }\n|.

    result = replace( val = replace( val = super->generate_html( )
                                     sub = style_tag
                                     with = button_style )
                      sub = body_tag
                      with = button_html ).

  ENDMETHOD.


  METHOD set_docking_side.
    docking_side = side.
  ENDMETHOD.

ENDCLASS.
