#ifndef erbal_parser_h
#define erbal_parser_h

#include "ruby.h"

typedef struct parser_state {
  unsigned int tag;
  unsigned int chars_seen;
  unsigned int concat;
  char *chars_seen_start;
} parser_state;

typedef struct erbal_parser {
  parser_state *state;
  unsigned int debug, concat_methods_identical;
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
inline void erbal_parser_tag_close_common(erbal_parser*);
inline void erbal_parser_finish(erbal_parser*);
inline void erbal_concat_chars_seen(erbal_parser*);
inline void erbal_parser_tag_open_common(erbal_parser*);
inline void erbal_open_buffer_concat(erbal_parser*, int);
inline void erbal_close_buffer_concat(erbal_parser*);
inline void erbal_close_and_open_buffer_concat_if_needed(erbal_parser*, int);
inline VALUE erbal_escape_special_chars(erbal_parser*);

#define TAG_OPEN                    1
#define TAG_OPEN_FOR_COMMENT        2
#define TAG_OPEN_FOR_SAFE_CONCAT    3
#define TAG_OPEN_FOR_UNSAFE_CONCAT  4
#define OUTSIDE_TAG                 5

#define SAFE_CONCAT     1
#define UNSAFE_CONCAT   2
#define OUTSIDE_CONCAT  3

#endif