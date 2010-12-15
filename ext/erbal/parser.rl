#include <stdio.h>
#include "parser.h"

%%{
  machine erbal_parser;

  main := |*
    '<%'  => { erbal_parser_tag_open(parser); };
    '<%#' => { erbal_parser_tag_open_for_comment(parser); };
    '<%=' => { erbal_parser_tag_open_for_output(parser); };
    '-%>' => { erbal_parser_tag_close_with_trim(parser); };
    '%>'  => { erbal_parser_tag_close(parser); };
    any   => { erbal_parser_non_tag(parser); };
  *|;
}%%

%% write data;

static char *ts, *te, *p, *pe, *eof;
static int act, cs;

inline void erbal_parser_tag_open_common(erbal_parser *parser) {
  if (parser->chars_seen != 0) {
    erbal_concat_chars_seen(parser);
    rb_str_buf_cat(parser->src, "\");", 3);
    parser->chars_seen = 0;
  }  
}

inline void erbal_parser_tag_open(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state = TAG_OPEN;


  // parser->open = 1;
  // if (parser->concat) {
  //   parser->concat = 0;
  //   rb_str_buf_cat(parser->src, "\");", 3);
  // }
}

inline void erbal_parser_tag_open_for_output(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser);
  parser->state = TAG_OPEN_FOR_OUTPUT;

  // erbal_parser_tag_open(parser);
  // parser->output = 1;
  // rb_str_concat(parser->src, parser->buffer_name);
  // rb_str_buf_cat(parser->src, ".concat((", 9);
}

inline void erbal_parser_tag_open_for_comment(erbal_parser *parser) {
  parser->state = TAG_OPEN_FOR_COMMENT;
  // erbal_parser_tag_open(parser);
  // parser->comment = 1;
}

inline void erbal_parser_non_tag(erbal_parser *parser) {
  parser->chars_seen += 1;

  // if (parser->comment) {
  //   return;
  // }
  //
  // if (parser->open) {
  //
  //   rb_str_buf_cat(parser->src, p, 1);
  // } else {
  //   if (!parser->concat) {
  //     parser->concat = 1;
  //     rb_str_concat(parser->src, parser->buffer_name);
  //     rb_str_buf_cat(parser->src, ".concat(\"", 9);
  //   }
  //   if (p[0] == '"') {
  //     rb_str_buf_cat(parser->src, "\\\"", 2);
  //   } else {
  //     rb_str_buf_cat(parser->src, p, 1);
  //   }
  // }
}

inline void erbal_parser_tag_close_with_trim(erbal_parser *parser) {
  if (p[1] == '\n') {
    p--;
  }

  erbal_parser_tag_close(parser);
  
  // erbal_parser_tag_close(parser);
  // if (p[1] == '\n') {
  //   p++;
  // }
}

inline void erbal_parser_tag_close(erbal_parser *parser) {
  if (parser->state == TAG_OPEN_FOR_OUTPUT) {
    rb_str_concat(parser->src, parser->buffer_name);
    rb_str_buf_cat(parser->src, ".concat((", 9);
    erbal_concat_chars_seen(parser);
    rb_str_buf_cat(parser->src, ").to_s);", 8);
  } else if (parser->state == TAG_OPEN) {
    erbal_concat_chars_seen(parser);
    rb_str_buf_cat(parser->src, ";", 1);
  }

  parser->state = OUTSIDE_TAG;
  parser->chars_seen = 0;

  // parser->open = 0;
  // if (parser->output) {
  //   parser->output = 0;
  //   rb_str_buf_cat(parser->src, ").to_s);", 8);
  // } else if (!parser->comment) {
  //   rb_str_buf_cat(parser->src, ";", 1);
  // }
  // parser->comment = 0;
}

inline void erbal_concat_chars_seen(erbal_parser *parser) {
  if (parser->chars_seen != 0) {
    rb_str_buf_cat(parser->src, ((p - 1) - parser->chars_seen), parser->chars_seen);    
  }
}

inline void erbal_parser_finish(erbal_parser *parser) {
  // if (parser->concat) {
  //   rb_str_buf_cat(parser->src, "\");", 3);
  // }
  rb_str_concat(parser->src, parser->buffer_name);
}

void erbal_parser_init(erbal_parser *parser) {
  parser->state = 0;
  parser->chars_seen = 0;
  parser->src = rb_str_dup(parser->buffer_name);
  rb_str_buf_cat(parser->src, "=\"\";", 4);
  %% write init;
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  %% write exec;
  erbal_parser_finish(parser);
}
