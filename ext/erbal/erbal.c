#include "ruby.h"
#include "parser.h"

static VALUE cErbal;

VALUE rb_erbal_alloc(VALUE klass) {
  erbal_parser *parser = ALLOC(erbal_parser);
  VALUE obj = Data_Wrap_Struct(klass, 0, free, parser);
  return obj;
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

  VALUE buffer_name_val = rb_hash_aref(parser->options, ID2SYM(rb_intern("buffer")));

  if (!NIL_P(buffer_name_val)) {
    Check_Type(buffer_name_val, T_STRING);
    parser->buffer_name = buffer_name_val;
  } else {
    parser->buffer_name = rb_str_new2("@output_buffer");
  }

  rb_iv_set(self, "@buffer_name", parser->buffer_name);

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
