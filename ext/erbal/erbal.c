#include "ruby.h"
#include "parser.h"

static VALUE cErbal;

void rb_erbal_free(erbal_parser *parser) {
  free(parser->state);
  free(parser);
}

VALUE rb_erbal_alloc(VALUE klass) {
  erbal_parser *parser = ALLOC(erbal_parser);
  parser->state = ALLOC(parser_state);
  VALUE obj = Data_Wrap_Struct(klass, 0, rb_erbal_free, parser);
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

  VALUE ivar = rb_str_new2("@");
  ivar = rb_str_cat2(ivar, key);
  rb_iv_set(self, RSTRING(ivar)->ptr, *(parser_option));
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

  rb_iv_set(self, "@options", parser->options);

  if (rb_hash_aref(parser->options, ID2SYM(rb_intern("debug"))) == Qtrue) {
    parser->debug = 1;
  } else {
    parser->debug = 0;
  }

  rb_erbal_setup_option(self, parser, &parser->buffer_name, "buffer", "@output_buffer");
  rb_erbal_setup_option(self, parser, &parser->safe_concat_method, "safe_concat_method", "concat");
  rb_erbal_setup_option(self, parser, &parser->unsafe_concat_method, "unsafe_concat_method", "concat");
  rb_erbal_setup_option(self, parser, &parser->safe_concat_keyword, "safe_concat_keyword", "");

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
