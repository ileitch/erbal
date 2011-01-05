#include <stdio.h>
#include "parser.h"

%%{
  machine erbal_parser;

  action keyword_start { parser->keyword_start = fpc; }
  action keyword_preceding_whitespace { parser->keyword_preceding_whitespace = fpc; }
  action keyword_trailing_whitespace { parser->keyword_trailing_whitespace = fpc; }

  action keyword_end {
    parser->keyword_end = fpc;
    parser->keyword = rb_str_new(parser->keyword_start, (fpc - parser->keyword_start));
  }

  main := |*
    '<%'  => { erbal_parser_tag_open(parser); };
    '<%-' => { erbal_parser_tag_open_with_dash(parser); };
    '<%#' => { erbal_parser_tag_open_for_comment(parser); };
    '<%=' => { erbal_parser_tag_open_for_unsafe_concat(parser); };
    '-%>' => { erbal_parser_tag_close_with_trim(parser); };
    '%>'  => { erbal_parser_tag_close(parser); };
    any   => { erbal_parser_non_tag(parser); };

    '<%=' (
            [ ]* >keyword_preceding_whitespace
            [a-z]+ >keyword_start %keyword_end
            [ ]+ %keyword_trailing_whitespace
          ) => { erbal_parser_tag_open_choose_concat(parser); };
  *|;
}%%

%% write data;

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

  %% write init;
}

void erbal_parser_exec(erbal_parser *parser) {
  p = RSTRING(parser->str)->ptr;
  pe = p + strlen(p);
  %% write exec;
  erbal_parser_finish(parser);
}
