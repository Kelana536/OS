%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/string.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: panic
; Description: Print a fatal error report.
; Parameters:
;   - %1: Source file.
;   - %2: Line number.
;   - %1: Function name.
;   - %2: Error message.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib panic
    arg pointer_t, file
    arg uint32_t,  line
    arg pointer_t, name
    arg pointer_t, error
    
    set_text_attr(FALSE, BLACK, RED)
    printf(\
        "\n\n!! ERROR TRACE !!\n| File: %s\n| Line: %d\n| Function: <%s>\n\n  %s\n\n",\
        file,\
        line,\
        name,\
        error\
    )

    strlen(error)
    lea ecx, [eax+4]

    under_loop:
        put_char("^")
        loop under_loop

    set_text_attr(FALSE, BLACK, LIGHT_WHITE)
func_end
