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

  VALUE safe_concat_method_val = rb_hash_aref(parser->options, ID2SYM(rb_intern("safe_concat_method")));

  if (!NIL_P(safe_concat_method_val)) {
    Check_Type(safe_concat_method_val, T_STRING);
    parser->safe_concat_method = safe_concat_method_val;
  } else {
    parser->safe_concat_method = rb_str_new2("concat");
  }

  rb_iv_set(self, "@safe_concat_method", parser->safe_concat_method);

  VALUE unsafe_concat_method_val = rb_hash_aref(parser->options, ID2SYM(rb_intern("unsafe_concat_method")));

  if (!NIL_P(unsafe_concat_method_val)) {
    Check_Type(unsafe_concat_method_val, T_STRING);
    parser->unsafe_concat_method = unsafe_concat_method_val;
  } else {
    parser->unsafe_concat_method = rb_str_new2("concat");
  }

  rb_iv_set(self, "@unsafe_concat_method", parser->unsafe_concat_method);

  VALUE safe_concat_keyword_val = rb_hash_aref(parser->options, ID2SYM(rb_intern("safe_concat_keyword")));

  if (!NIL_P(safe_concat_keyword_val)) {
    Check_Type(safe_concat_keyword_val, T_STRING);
    parser->safe_concat_keyword = safe_concat_keyword_val;
  } else {
    parser->safe_concat_keyword = Qnil;
  }

  rb_iv_set(self, "@safe_concat_keyword", parser->safe_concat_keyword);

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
