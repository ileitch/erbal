
#line 1 "parser.rl"
#include <stdio.h>
#include "parser.h"


#line 15 "parser.rl"



#line 12 "parser.c"
static const int erbal_parser_start = 1;
static const int erbal_parser_first_final = 1;
static const int erbal_parser_error = -1;

static const int erbal_parser_en_main = 1;


#line 18 "parser.rl"

static char *ts, *te, *p, *pe, *eof;
static int act, cs;

inline void erbal_parser_tag_open(erbal_parser *parser) {
  parser->open = 1;
  if (parser->concat) {
    parser->concat = 0;
    rb_str_buf_cat(parser->src, "\");", 3);
  }
}

inline void erbal_parser_tag_open_with_output(erbal_parser *parser) {
  erbal_parser_tag_open(parser);
  parser->output = 1;
  rb_str_concat(parser->src, parser->buffer);
  rb_str_buf_cat(parser->src, ".concat((", 9);
}

inline void erbal_parser_tag_open_with_comment(erbal_parser *parser) {
  erbal_parser_tag_open(parser);
  parser->comment = 1;
}

inline void erbal_parser_any(erbal_parser *parser) {
  if (parser->comment) {
    return;
  }

  if (parser->open) {
    rb_str_buf_cat(parser->src, p, 1);
  } else {
    if (!parser->concat) {
      parser->concat = 1;
      rb_str_concat(parser->src, parser->buffer);
      rb_str_buf_cat(parser->src, ".concat(\"", 9);
    }
    if (p[0] == '"') {
      rb_str_buf_cat(parser->src, "\\\"", 2);
    } else {
      rb_str_buf_cat(parser->src, p, 1);
    }
  }
}

inline void erbal_parser_tag_close_with_trim(erbal_parser *parser) {
  erbal_parser_tag_close(parser);
  if (p[1] == '\n') {
    p++;
  }
}

inline void erbal_parser_tag_close(erbal_parser *parser) {
  parser->open = 0;
  if (parser->output) {
    parser->output = 0;
    rb_str_buf_cat(parser->src, ").to_s);", 8);
  } else if (!parser->comment) {
    rb_str_buf_cat(parser->src, ";", 1);
  }
  parser->comment = 0;
}

inline void erbal_parser_finish(erbal_parser *parser) {
  if (parser->concat) {
    rb_str_buf_cat(parser->src, "\");", 3);
  }
  rb_str_concat(parser->src, parser->buffer);
}

void erbal_parser_init(erbal_parser *parser) {
  parser->concat = 0;
  parser->open = 0;
  parser->output = 0;
  parser->comment = 0;
  parser->src = rb_str_dup(parser->buffer);
  rb_str_buf_cat(parser->src, "=\"\";", 4);
  
#line 99 "parser.c"
	{
	cs = erbal_parser_start;
	ts = 0;
	te = 0;
	act = 0;
	}

#line 96 "parser.rl"
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  
#line 114 "parser.c"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
tr0:
#line 11 "parser.rl"
	{{p = ((te))-1;}{ erbal_parser_any(parser); }}
	goto st1;
tr1:
#line 12 "parser.rl"
	{te = p+1;{ erbal_parser_tag_close_with_trim(parser); }}
	goto st1;
tr2:
#line 11 "parser.rl"
	{te = p+1;{ erbal_parser_any(parser); }}
	goto st1;
tr6:
#line 11 "parser.rl"
	{te = p;p--;{ erbal_parser_any(parser); }}
	goto st1;
tr7:
#line 13 "parser.rl"
	{te = p+1;{ erbal_parser_tag_close(parser); }}
	goto st1;
tr10:
#line 8 "parser.rl"
	{te = p;p--;{ erbal_parser_tag_open(parser); }}
	goto st1;
tr11:
#line 9 "parser.rl"
	{te = p+1;{ erbal_parser_tag_open_with_comment(parser); }}
	goto st1;
tr12:
#line 10 "parser.rl"
	{te = p+1;{ erbal_parser_tag_open_with_output(parser); }}
	goto st1;
st1:
#line 1 "NONE"
	{ts = 0;}
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 1 "NONE"
	{ts = p;}
#line 160 "parser.c"
	switch( (*p) ) {
		case 37: goto st2;
		case 45: goto tr4;
		case 60: goto st4;
	}
	goto tr2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) == 62 )
		goto tr7;
	goto tr6;
tr4:
#line 1 "NONE"
	{te = p+1;}
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 182 "parser.c"
	if ( (*p) == 37 )
		goto st0;
	goto tr6;
st0:
	if ( ++p == pe )
		goto _test_eof0;
case 0:
	if ( (*p) == 62 )
		goto tr1;
	goto tr0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( (*p) == 37 )
		goto st5;
	goto tr6;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	switch( (*p) ) {
		case 35: goto tr11;
		case 61: goto tr12;
	}
	goto tr10;
	}
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof0: cs = 0; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 2: goto tr6;
	case 3: goto tr6;
	case 0: goto tr0;
	case 4: goto tr6;
	case 5: goto tr10;
	}
	}

	}

#line 102 "parser.rl"
  erbal_parser_finish(parser);
}
