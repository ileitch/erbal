#include "ruby.h"
#include "parser.h"

static VALUE cErbal;

void rb_erbal_free(erbal_parser *parser) {
  free(parser->state);
  free(parser);
}
void rb_erbal_mark(erbal_parser *parser) {
  rb_gc_mark_maybe(parser->str);
  rb_gc_mark_maybe(parser->src);
  rb_gc_mark_maybe(parser->initial_src);
  rb_gc_mark_maybe(parser->buffer_name);
  rb_gc_mark_maybe(parser->options);
  rb_gc_mark_maybe(parser->safe_concat_method);
  rb_gc_mark_maybe(parser->unsafe_concat_method);
  rb_gc_mark_maybe(parser->keyword);
  rb_gc_mark_maybe(parser->safe_concat_keyword);
}

VALUE rb_erbal_alloc(VALUE klass) {
  erbal_parser *parser = ALLOC(erbal_parser);
  parser->state = ALLOC(parser_state);
  VALUE obj = Data_Wrap_Struct(klass, rb_erbal_mark, rb_erbal_free, parser);
  return obj;
}

void rb_erbal_setup_option(VALUE self, erbal_parser* parser, VALUE* parser_option, const char* key, const char* default_value) {
  VALUE value = rb_hash_aref(parser->options, ID2SYM(rb_intern(key)));

  if (!NIL_P(value)) {
    Check_Type(value, T_STRING);
    *(parser_option) = value;
  } else {
    *(parser_option) = rb_str_new2(default_value);
  }
}

VALUE rb_erbal_initialize(int argc, VALUE *argv, VALUE self) {
  VALUE str, options;

  rb_scan_args(argc, argv, "11", &str, &options);

  Check_Type(str, T_STRING);

  erbal_parser *parser;
  Data_Get_Struct(self, erbal_parser, parser);
  parser->str = str;

  if (NIL_P(options)) {
    parser->options = rb_hash_new();
  } else {
    Check_Type(options, T_HASH);
    parser->options = options;
  }

  if (rb_hash_aref(parser->options, ID2SYM(rb_intern("debug"))) == Qtrue) {
    parser->debug = 1;
  } else {
    parser->debug = 0;
  }

  rb_erbal_setup_option(self, parser, &parser->buffer_name, "buffer", "@output_buffer");
  rb_erbal_setup_option(self, parser, &parser->safe_concat_method, "safe_concat_method", "concat");
  rb_erbal_setup_option(self, parser, &parser->unsafe_concat_method, "unsafe_concat_method", "concat");
  rb_erbal_setup_option(self, parser, &parser->safe_concat_keyword, "safe_concat_keyword", "");

	if (strcmp(RSTRING(parser->safe_concat_method)->ptr, RSTRING(parser->unsafe_concat_method)->ptr) == 0) {
    parser->concat_methods_identical = 1;
	} else {
	  parser->concat_methods_identical = 0;
	}

  parser->initial_src = rb_str_dup(parser->buffer_name);

  VALUE buffer_init_val = rb_hash_aref(parser->options, ID2SYM(rb_intern("buffer_initial_value")));
  
  if (!NIL_P(buffer_init_val)) {
    Check_Type(buffer_init_val, T_STRING);
    rb_str_buf_cat(parser->initial_src, " = ", 3);
    rb_str_concat(parser->initial_src, buffer_init_val);
    rb_str_buf_cat(parser->initial_src, ";", 1);
  } else {
    rb_str_buf_cat(parser->initial_src, " = '';", 6);
  }

  return self;
}

VALUE rb_erbal_parse(VALUE self) {
  erbal_parser *parser;
  Data_Get_Struct(self, erbal_parser, parser);
  erbal_parser_init(self, parser);
  erbal_parser_exec(parser);
  return parser->src;
}

void Init_erbal() {
  cErbal = rb_define_class("Erbal", rb_cObject);
  rb_define_alloc_func(cErbal, rb_erbal_alloc);
  rb_define_method(cErbal, "initialize", rb_erbal_initialize, -1);
  rb_define_method(cErbal, "parse", rb_erbal_parse, 0);
}
