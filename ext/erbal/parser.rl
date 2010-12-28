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

inline void erbal_concat_chars_seen(erbal_parser *parser, int shift) {
  if (parser->chars_seen != 0) {
		if (parser->state == OUTSIDE_TAG) {
			/* escape quotes */
			VALUE buf;
			buf = rb_str_buf_new("");
			int slashes_seen = 0;
			int i = 0;
			for (i = 0; i <= parser->chars_seen; i++) {
				if (*(((p + shift) - parser->chars_seen) + i) == '"') {
					if (slashes_seen == 0) {
						rb_str_buf_cat(buf, '"', 1);
					} else {
						
					}
				} else {
					// rb_str_buf_cat(buf, p, 1);
				}
			}
		} else {
    	rb_str_buf_cat(parser->src, ((p + shift) - parser->chars_seen), parser->chars_seen);			
		}
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
	parser->state = OUTSIDE_TAG;
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
