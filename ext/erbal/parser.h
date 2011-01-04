#ifndef erbal_parser_h
#define erbal_parser_h

#include "ruby.h"

typedef struct parser_state {
  unsigned int tag;
  unsigned int chars_seen;
  unsigned int in_concat;
} parser_state;

typedef struct erbal_parser {
  parser_state *state;
  unsigned int debug;
  VALUE str, src, buffer_name, options, safe_concat_method, unsafe_concat_method, keyword, safe_concat_keyword;
  char *keyword_start, *keyword_end, *keyword_trailing_whitespace, *keyword_preceding_whitespace;
} erbal_parser;

inline void erbal_parser_tag_open(erbal_parser*);
inline void erbal_parser_tag_open_with_dash(erbal_parser*);
inline void erbal_parser_tag_open_for_comment(erbal_parser*);
inline void erbal_parser_tag_open_choose_concat(erbal_parser*);
inline void erbal_parser_tag_open_for_unsafe_concat(erbal_parser*);
inline void erbal_parser_tag_open_for_safe_concat(erbal_parser*);
inline void erbal_parser_non_tag(erbal_parser*);
inline void erbal_parser_tag_close(erbal_parser*);
inline void erbal_parser_tag_close_with_trim(erbal_parser*);
inline void erbal_parser_tag_close_common(erbal_parser*, int);
inline void erbal_parser_finish(erbal_parser*);
inline void erbal_concat_chars_seen(erbal_parser*, int);
inline void erbal_parser_tag_open_common(erbal_parser*, int);
inline void erbal_open_buffer_concat(erbal_parser*, int);
inline void erbal_close_buffer_concat(erbal_parser*);
inline VALUE erbal_escape_special_chars(erbal_parser*, int);

#define TAG_OPEN                    1
#define TAG_OPEN_FOR_COMMENT        2
#define TAG_OPEN_FOR_SAFE_CONCAT    3
#define TAG_OPEN_FOR_UNSAFE_CONCAT  4
#define OUTSIDE_TAG                 5

#endif