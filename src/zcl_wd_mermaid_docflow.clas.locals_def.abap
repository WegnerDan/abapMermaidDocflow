*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section
CLASS lcl_diagram DEFINITION INHERITING FROM zcl_wd_gui_mermaid_js_diagram.
  PUBLIC SECTION.
    METHODS:
      set_docking_side IMPORTING side TYPE i.
  PROTECTED SECTION.
    METHODS:
      generate_html REDEFINITION.
  PRIVATE SECTION.
    DATA:
      docking_side TYPE i.
ENDCLASS.
