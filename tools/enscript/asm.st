/**
 * Name: asm
 * Description: Assembler listings.
 * Author: Markku Rossi <mtr@iki.fi>
 */

state asm extends HighlightEntry
{
  /* Comments. */
  /(;|^[ \t]*;).*/ {
    comment_face (true);
    language_print ($0);
/*    call (eat_one_line); */ 
    comment_face (false);
  }

  /* label and instruction on one line. */
  /^([^\t ]+:)([ \t]+)([^ \t]+)/ {
    function_name_face (true);
    language_print ($1);
    function_name_face (false);
    
    language_print ($2);

    keyword_face (true);
    language_print ($3);
    keyword_face (false);
  }
  
  /* Labels are averything at the beginning of the line, ending to ':' */
  /^[^\t ]+:/ {
    function_name_face (true);
    language_print ($0);
    function_name_face (false);
  }

  /* Asm operands are indented. */
  /^([ \t]+)([^ \t]+)/ {
    language_print ($1);

    keyword_face (true);
    language_print ($2);
    keyword_face (false);
  }

  /* Assignments. */
  /^([^ \t]+)([ \t]*:=.*)/ {
    function_name_face (true);
    language_print ($1);
    function_name_face (false);
    language_print ($2);
  }
  
  /* And finally, highlight string constants. */
  /\"/ {
    string_face (true);
    language_print ($0);
    call (c_string);
    string_face (false);
  }
}


/*
Local variables:
mode: c
End:
*/
