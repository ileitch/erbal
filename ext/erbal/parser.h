#ifndef erbal_parser_h
#define erbal_parser_h

#include "ruby.h"

typedef struct erbal_parser {
  const char *buf[1000];
  int output, open, mark, offset;
  VALUE str, src, buffer;
} erbal_parser;

inline void erbal_parser_tag_open(erbal_parser*);
inline void erbal_parser_tag_open_with_output(erbal_parser*);
inline void erbal_parser_any(erbal_parser*);
inline void erbal_parser_tag_close(erbal_parser*);
inline void erbal_parser_tag_close_with_trim(erbal_parser*);
inline void erbal_parser_finish(erbal_parser*);

#endif
