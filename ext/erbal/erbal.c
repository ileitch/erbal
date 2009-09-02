#include "ruby.h"
#include "parser.h"

static VALUE cErbal;

void rb_erbal_free(void *data) {
  if(data) {
    free(data);
  }
}

VALUE rb_erbal_alloc(VALUE klass) {
  erbal_parser *parser = ALLOC_N(erbal_parser, 1);
  VALUE obj = Data_Wrap_Struct(klass, NULL, rb_erbal_free, parser);
  return obj;
}

VALUE rb_erbal_initialize(VALUE self, VALUE str, VALUE buffer) {
  Check_Type(str, T_STRING);
  Check_Type(buffer, T_STRING);
  erbal_parser *parser = NULL;
  Data_Get_Struct(self, erbal_parser, parser);
  parser->buffer = buffer;
  parser->str = str;
  return self;
}

VALUE rb_erbal_parse(VALUE self) {
  erbal_parser *parser = NULL;
  Data_Get_Struct(self, erbal_parser, parser);
  erbal_parser_init(parser);
  erbal_parser_exec(parser);
  return parser->src;
}

void Init_erbal() {
  cErbal = rb_define_class("Erbal", rb_cObject);
  rb_define_alloc_func(cErbal, rb_erbal_alloc);
  rb_define_method(cErbal, "initialize", rb_erbal_initialize, 2);
  rb_define_method(cErbal, "parse", rb_erbal_parse, 0);
}
