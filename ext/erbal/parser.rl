#include <stdio.h>
#include "parser.h"

%%{
  machine erbal_parser;

  main := |*
    '<%'  => { erbal_parser_tag_open(parser); };
    '<%-' => { erbal_parser_tag_open_with_dash(parser); };
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

inline void erbal_parser_tag_open_common(erbal_parser *parser, int shift) {
  if (parser->chars_seen != 0) {
    if (!parser->in_buffer_shift) {
      erbal_open_buffer_shift(parser);
    }

    erbal_concat_chars_seen(parser, shift);
    parser->chars_seen = 0;
  }
}

inline void erbal_parser_tag_open(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser, -1);
  parser->state = TAG_OPEN;
}

inline void erbal_parser_tag_open_with_dash(erbal_parser *parser) {
  erbal_parser_tag_open_common(parser, -2);
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
    if (!parser->in_buffer_shift) {
      erbal_open_buffer_shift(parser);
    }

    rb_str_buf_cat(parser->src, "#{", 2);
    erbal_concat_chars_seen(parser, -tag_size);
    rb_str_buf_cat(parser->src, "}", 1);
  } else if (parser->state == TAG_OPEN) {
    if (parser->in_buffer_shift) {
      erbal_close_buffer_shift(parser);
    }

    erbal_concat_chars_seen(parser, -tag_size);
    rb_str_buf_cat(parser->src, ";\n", 2);
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

inline VALUE erbal_escape_special_chars(erbal_parser *parser, int shift) {
  VALUE buf = rb_str_buf_new(0);
  int i, n, slashes_seen = 0;
  char *current_char;

  for (i = 0; i < parser->chars_seen; i++) {
    current_char = (((p + shift) - parser->chars_seen) + i);

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

inline void erbal_concat_chars_seen(erbal_parser *parser, int shift) {
  if (parser->chars_seen != 0) {
    if (parser->in_buffer_shift && parser->state == OUTSIDE_TAG) {
      rb_str_concat(parser->src, erbal_escape_special_chars(parser, shift));
    } else {
    	rb_str_buf_cat(parser->src, ((p + shift) - parser->chars_seen), parser->chars_seen);
    }
  }

  parser->chars_seen = 0;
}

inline void erbal_open_buffer_shift(erbal_parser *parser) {
  rb_str_concat(parser->src, parser->buffer_name);
  rb_str_buf_cat(parser->src, " << %Q`", 7);
  parser->in_buffer_shift = 1;
}

inline void erbal_close_buffer_shift(erbal_parser *parser) {
  rb_str_buf_cat(parser->src, "`;", 2);
  parser->in_buffer_shift = 0;
}

inline void erbal_parser_finish(erbal_parser *parser) {
  if (parser->chars_seen != 0) {
    if (!parser->in_buffer_shift) {
      erbal_open_buffer_shift(parser);
    }

    erbal_concat_chars_seen(parser, 0);
  }

  if (parser->in_buffer_shift) {
    erbal_close_buffer_shift(parser);
  }

  rb_str_concat(parser->src, parser->buffer_name);

  if (parser->debug) {
    printf("ERBAL DEBUG: %s\n", RSTRING(rb_inspect(parser->src))->ptr);
  }
}

void erbal_parser_init(erbal_parser *parser) {
  parser->chars_seen = 0;
  parser->in_buffer_shift = 0;
	parser->state = OUTSIDE_TAG;
  parser->debug = 0;

  if (rb_hash_aref(parser->options, ID2SYM(rb_intern("debug"))) == Qtrue) {
    parser->debug = 1;
  }

  parser->src = rb_str_dup(parser->buffer_name);
  rb_str_buf_cat(parser->src, " = '';", 6);
  %% write init;
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  %% write exec;
  erbal_parser_finish(parser);
}
