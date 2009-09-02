#include <stdio.h>
#include "parser.h"

%%{
  machine erbal_parser;

  main := |*
    '<%'  => { erbal_parser_tag_open(parser); };
    '<%#'  => { erbal_parser_tag_open_with_comment(parser); };
    '<%=' => { erbal_parser_tag_open_with_output(parser); };
    any   => { erbal_parser_any(parser); };
    '-%>' => { erbal_parser_tag_close_with_trim(parser); };
    '%>'  => { erbal_parser_tag_close(parser); };
  *|;
}%%

%% write data;

static char *ts, *te, *p, *pe, *eof;
static int act, cs;

inline void erbal_parser_tag_open(erbal_parser *parser) {
  parser->open = 1;
  if (parser->mark) {
    parser->mark = 0;
    rb_str_cat(parser->src, "\");", 3);
  }
}

inline void erbal_parser_tag_open_with_output(erbal_parser *parser) {
  erbal_parser_tag_open(parser);
  parser->output = 1;
  rb_str_concat(parser->src, parser->buffer);
  rb_str_cat(parser->src, ".concat((", 9);
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
    rb_str_cat(parser->src, p, 1);
  } else {
    if (!parser->mark) {
      parser->mark = 1;
      rb_str_concat(parser->src, parser->buffer);
      rb_str_cat(parser->src, ".concat(\"", 9);
    }
    if (p[0] == '"') {
      rb_str_cat(parser->src, "\\\"", 2);
    } else {
      rb_str_cat(parser->src, p, 1);
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
    rb_str_cat(parser->src, ").to_s);", 8);
  } else if (!parser->comment) {
    rb_str_cat(parser->src, ";", 1);
  }
  parser->comment = 0;
}

inline void erbal_parser_finish(erbal_parser *parser) {
  if (parser->mark) {
    rb_str_cat(parser->src, "\");", 3);
  }
  rb_str_concat(parser->src, parser->buffer);
}

void erbal_parser_init(erbal_parser *parser) {
  parser->mark = 0;
  parser->open = 0;
  parser->output = 0;
  parser->comment = 0;
  parser->src = rb_str_dup(parser->buffer);
  rb_str_cat(parser->src, "=\"\";", 4);
  %% write init;
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  %% write exec;
  erbal_parser_finish(parser);
}
