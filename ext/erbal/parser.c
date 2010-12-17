
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

inline void erbal_parser_tag_open_common(erbal_parser *parser, int shift) {
  if (parser->chars_seen != 0) {
    rb_str_concat(parser->src, parser->buffer_name);
    rb_str_buf_cat(parser->src, ".concat(\"", 9);
    erbal_concat_chars_seen(parser, shift);
    rb_str_buf_cat(parser->src, "\");", 3);
    parser->chars_seen = 0;
  }
}

inline void erbal_parser_tag_open(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser, -1);
  parser->state = TAG_OPEN;
}

inline void erbal_parser_tag_open_for_output(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser, -2);
  parser->state = TAG_OPEN_FOR_OUTPUT;
}

inline void erbal_parser_tag_open_for_comment(erbal_parser *parser) {
  parser->state = TAG_OPEN_FOR_COMMENT;
}

inline void erbal_parser_non_tag(erbal_parser *parser) {
  parser->chars_seen += 1;
}

inline void erbal_parser_tag_close_common(erbal_parser *parser, int tag_size) {
  if (parser->state == TAG_OPEN_FOR_OUTPUT) {
    rb_str_concat(parser->src, parser->buffer_name);
    rb_str_buf_cat(parser->src, ".concat((", 9);
    erbal_concat_chars_seen(parser, -tag_size);
    rb_str_buf_cat(parser->src, ").to_s);", 8);
  } else if (parser->state == TAG_OPEN) {
    erbal_concat_chars_seen(parser, -tag_size);
    rb_str_buf_cat(parser->src, ";", 1);
  }

  parser->state = OUTSIDE_TAG;
  parser->chars_seen = 0;
}

inline void erbal_parser_tag_close_with_trim(erbal_parser *parser) {
  erbal_parser_tag_close_common(parser, 2);

  if (*(p + 1) == '\n') {
    p++;
  }
}

inline void erbal_parser_tag_close(erbal_parser *parser) {
  erbal_parser_tag_close_common(parser, 1);
}

inline void erbal_concat_chars_seen(erbal_parser *parser, int rewind_chars) {
  if (parser->chars_seen != 0) {
    rb_str_buf_cat(parser->src, ((p + rewind_chars) - parser->chars_seen), parser->chars_seen);
  }

  parser->chars_seen = 0;
}

inline void erbal_parser_finish(erbal_parser *parser) {
  if (parser->chars_seen != 0) {
    rb_str_concat(parser->src, parser->buffer_name);
    rb_str_buf_cat(parser->src, ".concat(\"", 9);
    erbal_concat_chars_seen(parser, 0);
    rb_str_buf_cat(parser->src, "\");", 3);
  }
  rb_str_concat(parser->src, parser->buffer_name);
}

void erbal_parser_init(erbal_parser *parser) {
  parser->state = 0;
  parser->chars_seen = 0;
  parser->src = rb_str_dup(parser->buffer_name);
  rb_str_buf_cat(parser->src, "=\"\";", 4);
  
#line 104 "parser.c"
	{
	cs = erbal_parser_start;
	ts = 0;
	te = 0;
	act = 0;
	}

#line 101 "parser.rl"
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  
#line 119 "parser.c"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
tr0:
#line 13 "parser.rl"
	{{p = ((te))-1;}{ erbal_parser_non_tag(parser); }}
	goto st1;
tr1:
#line 11 "parser.rl"
	{te = p+1;{ erbal_parser_tag_close_with_trim(parser); }}
	goto st1;
tr2:
#line 13 "parser.rl"
	{te = p+1;{ erbal_parser_non_tag(parser); }}
	goto st1;
tr6:
#line 13 "parser.rl"
	{te = p;p--;{ erbal_parser_non_tag(parser); }}
	goto st1;
tr7:
#line 12 "parser.rl"
	{te = p+1;{ erbal_parser_tag_close(parser); }}
	goto st1;
tr10:
#line 8 "parser.rl"
	{te = p;p--;{ erbal_parser_tag_open(parser); }}
	goto st1;
tr11:
#line 9 "parser.rl"
	{te = p+1;{ erbal_parser_tag_open_for_comment(parser); }}
	goto st1;
tr12:
#line 10 "parser.rl"
	{te = p+1;{ erbal_parser_tag_open_for_output(parser); }}
	goto st1;
st1:
#line 1 "NONE"
	{ts = 0;}
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 1 "NONE"
	{ts = p;}
#line 165 "parser.c"
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
#line 187 "parser.c"
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

#line 107 "parser.rl"
  erbal_parser_finish(parser);
}
