
#line 1 "parser.rl"
#include <stdio.h>
#include "parser.h"


#line 31 "parser.rl"



#line 12 "parser.c"
static const int erbal_parser_start = 4;
static const int erbal_parser_first_final = 4;
static const int erbal_parser_error = -1;

static const int erbal_parser_en_main = 4;


#line 34 "parser.rl"

static char *ts, *te, *p, *pe, *eof;
static int act, cs;

inline void erbal_parser_tag_open_common(erbal_parser *parser) {
  if (parser->state->chars_seen != 0) {
    if (parser->state->concat == OUTSIDE_CONCAT) {
      erbal_open_buffer_concat(parser, 1);
    } else if (parser->state->concat == UNSAFE_CONCAT) {
      erbal_close_and_open_buffer_concat_if_needed(parser, 1);
    }

    erbal_concat_chars_seen(parser);
    parser->state->chars_seen = 0;
  }
}

inline void erbal_parser_tag_open(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state->tag = TAG_OPEN;
}

inline void erbal_parser_tag_open_with_dash(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state->tag = TAG_OPEN;
}

inline void erbal_parser_tag_open_choose_concat(erbal_parser *parser) {
  if (strcmp(RSTRING(parser->safe_concat_keyword)->ptr, "") == 0 || strcmp(RSTRING(parser->keyword)->ptr, RSTRING(parser->safe_concat_keyword)->ptr) != 0) {
    /* Keyword doesn't match, reset the buffer to the start of the expression match and act as if a keyword wasn't seen. */
    p = parser->keyword_preceding_whitespace - 1;
    erbal_parser_tag_open_for_unsafe_concat(parser);
  } else {
    /* Rewind the buffer to preserve whitespace following the keyword. */
    p = p - (parser->keyword_trailing_whitespace - parser->keyword_end);
    erbal_parser_tag_open_for_safe_concat(parser);
  }
}

inline void erbal_parser_tag_open_for_unsafe_concat(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state->tag = TAG_OPEN_FOR_UNSAFE_CONCAT;
}

inline void erbal_parser_tag_open_for_safe_concat(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state->tag = TAG_OPEN_FOR_SAFE_CONCAT;
}

inline void erbal_parser_tag_open_for_comment(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state->tag = TAG_OPEN_FOR_COMMENT;
}

inline void erbal_parser_non_tag(erbal_parser *parser) {
  if (parser->state->chars_seen == 0) {
    parser->state->chars_seen_start = p;
  }

  parser->state->chars_seen += 1;
}

inline void erbal_parser_tag_close_common(erbal_parser *parser) {
  if (parser->state->tag == TAG_OPEN_FOR_UNSAFE_CONCAT || parser->state->tag == TAG_OPEN_FOR_SAFE_CONCAT) {
    if (parser->state->concat == OUTSIDE_CONCAT) {
      if (parser->state->tag == TAG_OPEN_FOR_SAFE_CONCAT) {
        erbal_open_buffer_concat(parser, 1);
      } else {
        erbal_open_buffer_concat(parser, 0);
      }
    } else if (parser->state->concat == SAFE_CONCAT && parser->state->tag == TAG_OPEN_FOR_UNSAFE_CONCAT) {
      erbal_close_and_open_buffer_concat_if_needed(parser, 0);
    } else if (parser->state->concat == UNSAFE_CONCAT && parser->state->tag == TAG_OPEN_FOR_SAFE_CONCAT) {
      erbal_close_and_open_buffer_concat_if_needed(parser, 1);
    }

    rb_str_buf_cat(parser->src, "#{", 2);
    erbal_concat_chars_seen(parser);
    rb_str_buf_cat(parser->src, "}", 1);
  } else if (parser->state->tag == TAG_OPEN) {
    if (parser->state->concat != OUTSIDE_CONCAT) {
      erbal_close_buffer_concat(parser);
    }

    erbal_concat_chars_seen(parser);
    rb_str_buf_cat(parser->src, ";\n", 2);
  }

  parser->state->tag = OUTSIDE_TAG;
  parser->state->chars_seen = 0;
}

inline void erbal_parser_tag_close_with_trim(erbal_parser *parser) {
  erbal_parser_tag_close_common(parser);

  if (*(p + 1) == '\n') {
    p++;
  }
}

inline void erbal_parser_tag_close(erbal_parser *parser) {
  erbal_parser_tag_close_common(parser);
}

inline VALUE erbal_escape_special_chars(erbal_parser *parser) {
  VALUE buf = rb_str_buf_new(0);
  int i, n, slashes_seen = 0;
  char *current_char;

  for (i = 0; i < parser->state->chars_seen; i++) {
    current_char = (parser->state->chars_seen_start + i);

    if (*current_char == '#' || *current_char == '`') {
      if (slashes_seen == 0) {
        rb_str_buf_cat(buf, "\\", 1);
        rb_str_buf_cat(buf, current_char, 1);
      } else {
        for (n = 0; n <= (1 * slashes_seen); n++) {
          rb_str_buf_cat(buf, "\\", 1);
        }
        rb_str_buf_cat(buf, current_char, 1);
      }

      slashes_seen = 0;
    } else if (*current_char == '\\') {
      slashes_seen++;
      rb_str_buf_cat(buf, current_char, 1);
    } else {
      rb_str_buf_cat(buf, current_char, 1);
    }
  }

  return buf;
}

inline void erbal_concat_chars_seen(erbal_parser *parser) {
  if (parser->state->chars_seen != 0) {
    if (parser->state->concat != OUTSIDE_CONCAT && parser->state->tag == OUTSIDE_TAG) {
      rb_str_concat(parser->src, erbal_escape_special_chars(parser));
    } else {
    	rb_str_buf_cat(parser->src, parser->state->chars_seen_start, parser->state->chars_seen);
    }
  }

  parser->state->chars_seen = 0;
}

inline void erbal_close_and_open_buffer_concat_if_needed(erbal_parser *parser, int safe_concat) {
  if (!parser->concat_methods_identical) {
    erbal_close_buffer_concat(parser);
    erbal_open_buffer_concat(parser, safe_concat);
  }
}

inline void erbal_open_buffer_concat(erbal_parser *parser, int safe_concat) {
  rb_str_concat(parser->src, parser->buffer_name);
  rb_str_buf_cat(parser->src, ".", 1);

  if (safe_concat) {
    rb_str_concat(parser->src, parser->safe_concat_method);
    parser->state->concat = SAFE_CONCAT;
  } else {
    rb_str_concat(parser->src, parser->unsafe_concat_method);
    parser->state->concat = UNSAFE_CONCAT;
  }

  rb_str_buf_cat(parser->src, "(", 1);
  rb_str_buf_cat(parser->src, "%Q`", 3);
}

inline void erbal_close_buffer_concat(erbal_parser *parser) {
  rb_str_buf_cat(parser->src, "`);", 3);
  parser->state->concat = OUTSIDE_CONCAT;
}

inline void erbal_parser_finish(erbal_parser *parser) {
  if (parser->state->chars_seen != 0) {
    if (parser->state->concat == OUTSIDE_CONCAT) {
      erbal_open_buffer_concat(parser, 1);
    } else if (parser->state->concat == UNSAFE_CONCAT) {
      erbal_close_and_open_buffer_concat_if_needed(parser, 1);
    }

    erbal_concat_chars_seen(parser);
  }

  if (parser->state->concat != OUTSIDE_CONCAT) {
    erbal_close_buffer_concat(parser);
  }

  rb_str_concat(parser->src, parser->buffer_name);

  if (parser->debug) {
    printf("ERBAL DEBUG: %s\n", RSTRING(rb_inspect(parser->src))->ptr);
  }
}

void erbal_parser_init(VALUE self, erbal_parser *parser) {
  parser->state->chars_seen = 0;
  parser->state->concat = OUTSIDE_CONCAT;
	parser->state->tag = OUTSIDE_TAG;

	if (strcmp(RSTRING(parser->safe_concat_method)->ptr, RSTRING(parser->unsafe_concat_method)->ptr) == 0) {
    parser->concat_methods_identical = 1;
	} else {
	  parser->concat_methods_identical = 0;
	}

  parser->src = rb_str_dup(parser->buffer_name);

  rb_iv_set(self, "@src", parser->src);

  VALUE buffer_init_val = rb_hash_aref(parser->options, ID2SYM(rb_intern("buffer_initial_value")));

  if (!NIL_P(buffer_init_val)) {
    Check_Type(buffer_init_val, T_STRING);
    rb_str_buf_cat(parser->src, " = ", 3);
    rb_str_concat(parser->src, buffer_init_val);
    rb_str_buf_cat(parser->src, ";", 1);
  } else {
    rb_str_buf_cat(parser->src, " = '';", 6);
  }

  
#line 245 "parser.c"
	{
	cs = erbal_parser_start;
	ts = 0;
	te = 0;
	act = 0;
	}

#line 258 "parser.rl"
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  
#line 260 "parser.c"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
tr0:
#line 23 "parser.rl"
	{{p = ((te))-1;}{ erbal_parser_non_tag(parser); }}
	goto st4;
tr1:
#line 21 "parser.rl"
	{te = p+1;{ erbal_parser_tag_close_with_trim(parser); }}
	goto st4;
tr2:
#line 20 "parser.rl"
	{{p = ((te))-1;}{ erbal_parser_tag_open_for_unsafe_concat(parser); }}
	goto st4;
tr8:
#line 23 "parser.rl"
	{te = p+1;{ erbal_parser_non_tag(parser); }}
	goto st4;
tr12:
#line 23 "parser.rl"
	{te = p;p--;{ erbal_parser_non_tag(parser); }}
	goto st4;
tr13:
#line 22 "parser.rl"
	{te = p+1;{ erbal_parser_tag_close(parser); }}
	goto st4;
tr16:
#line 17 "parser.rl"
	{te = p;p--;{ erbal_parser_tag_open(parser); }}
	goto st4;
tr17:
#line 19 "parser.rl"
	{te = p+1;{ erbal_parser_tag_open_for_comment(parser); }}
	goto st4;
tr18:
#line 18 "parser.rl"
	{te = p+1;{ erbal_parser_tag_open_with_dash(parser); }}
	goto st4;
tr20:
#line 20 "parser.rl"
	{te = p;p--;{ erbal_parser_tag_open_for_unsafe_concat(parser); }}
	goto st4;
tr24:
#line 9 "parser.rl"
	{ parser->keyword_trailing_whitespace = p; }
#line 29 "parser.rl"
	{te = p;p--;{ erbal_parser_tag_open_choose_concat(parser); }}
	goto st4;
st4:
#line 1 "NONE"
	{ts = 0;}
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 1 "NONE"
	{ts = p;}
#line 320 "parser.c"
	switch( (*p) ) {
		case 37: goto st5;
		case 45: goto tr10;
		case 60: goto st7;
	}
	goto tr8;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == 62 )
		goto tr13;
	goto tr12;
tr10:
#line 1 "NONE"
	{te = p+1;}
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 342 "parser.c"
	if ( (*p) == 37 )
		goto st0;
	goto tr12;
st0:
	if ( ++p == pe )
		goto _test_eof0;
case 0:
	if ( (*p) == 62 )
		goto tr1;
	goto tr0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( (*p) == 37 )
		goto st8;
	goto tr12;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 35: goto tr17;
		case 45: goto tr18;
		case 61: goto tr19;
	}
	goto tr16;
tr19:
#line 1 "NONE"
	{te = p+1;}
	goto st9;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
#line 378 "parser.c"
	switch( (*p) ) {
		case 32: goto tr21;
		case 33: goto tr22;
		case 36: goto tr22;
		case 38: goto tr22;
		case 61: goto tr22;
		case 64: goto tr22;
		case 94: goto tr22;
	}
	if ( (*p) > 43 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr23;
	} else if ( (*p) >= 42 )
		goto tr22;
	goto tr20;
tr21:
#line 8 "parser.rl"
	{ parser->keyword_preceding_whitespace = p; }
	goto st1;
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 402 "parser.c"
	switch( (*p) ) {
		case 32: goto st1;
		case 33: goto tr4;
		case 36: goto tr4;
		case 38: goto tr4;
		case 61: goto tr4;
		case 64: goto tr4;
		case 94: goto tr4;
	}
	if ( (*p) > 43 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr5;
	} else if ( (*p) >= 42 )
		goto tr4;
	goto tr2;
tr4:
#line 7 "parser.rl"
	{ parser->keyword_start = p; }
	goto st2;
tr22:
#line 8 "parser.rl"
	{ parser->keyword_preceding_whitespace = p; }
#line 7 "parser.rl"
	{ parser->keyword_start = p; }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 432 "parser.c"
	if ( (*p) == 32 )
		goto tr6;
	goto tr2;
tr6:
#line 11 "parser.rl"
	{
    parser->keyword_end = p;
    parser->keyword = rb_str_new(parser->keyword_start, (p - parser->keyword_start));
  }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 447 "parser.c"
	if ( (*p) == 32 )
		goto st10;
	goto tr24;
tr5:
#line 7 "parser.rl"
	{ parser->keyword_start = p; }
	goto st3;
tr23:
#line 8 "parser.rl"
	{ parser->keyword_preceding_whitespace = p; }
#line 7 "parser.rl"
	{ parser->keyword_start = p; }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 465 "parser.c"
	if ( (*p) == 32 )
		goto tr6;
	if ( 97 <= (*p) && (*p) <= 122 )
		goto st3;
	goto tr2;
	}
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof0: cs = 0; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 5: goto tr12;
	case 6: goto tr12;
	case 0: goto tr0;
	case 7: goto tr12;
	case 8: goto tr16;
	case 9: goto tr20;
	case 1: goto tr2;
	case 2: goto tr2;
	case 10: goto tr24;
	case 3: goto tr2;
	}
	}

	}

#line 264 "parser.rl"
  erbal_parser_finish(parser);
}
