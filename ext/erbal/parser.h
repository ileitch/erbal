#ifndef erbal_parser_h
#define erbal_parser_h

#include "ruby.h"

typedef struct erbal_parser {
  unsigned int state, chars_seen, in_buffer_concat, debug;
  VALUE str, src, buffer_name, options, safe_concat_method, unsafe_concat_method;
} erbal_parser;

inline void erbal_parser_tag_open(erbal_parser*);
inline void erbal_parser_tag_open_with_dash(erbal_parser*);
inline void erbal_parser_tag_open_for_comment(erbal_parser*);
inline void erbal_parser_tag_open_for_unsafe_output(erbal_parser*);
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

#define TAG_OPEN                1
#define TAG_OPEN_FOR_COMMENT    2
#define TAG_OPEN_FOR_OUTPUT     3
#define OUTSIDE_TAG             4

#endif