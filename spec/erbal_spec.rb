require 'spec_helper'

describe Erbal do
  def erbal_parse(str, options = {:buffer => '@out'})
    Erbal.new(str, options).parse
  end

  def erubis_parse(str)
    require 'rubygems'
    require 'erubis'
    Erubis::FastEruby.new.convert(str)
  end

  it "should default to @output_buffer if the :buffer option is not specified" do
    erbal_parse("", :buffer => nil).should == "@output_buffer = '';@output_buffer"
  end

  it "should use the buffer specified via the :buffer option" do
    erbal_parse("", :buffer => "_woot").should == "_woot = '';_woot"
  end

  it "should raise an error if the value given as the :buffer option is not a string" do
    expect { erbal_parse("", :buffer => Class.new) }.should raise_error("wrong argument type Class (expected String)")
  end

  it "should default to an empty string as the initial buffer value if the :buffer_initial_value is not specified" do
    erbal_parse("", :buffer_initial_value => nil).should == "@output_buffer = '';@output_buffer"
  end

  it "should use the initial value for the buffer specified by the :buffer_initial_value option" do
    erbal_parse("", :buffer_initial_value => 'MyClass.new').should == "@output_buffer = MyClass.new;@output_buffer"
  end

  it "should raise an error if the value given as the :buffer_initial_value option is not a string" do
    expect { erbal_parse("", :buffer_initial_value => Class.new) }.should raise_error("wrong argument type Class (expected String)")
  end

  it "should parse a blank string" do
    erbal_parse("").should == "@out = '';@out"
  end

  it "should parse content without any tags" do
    erbal_parse("I love unicorns!").should == "@out = '';@out.concat(%Q`I love unicorns!`);@out"
  end

  it "should parse the <% tag" do
    erbal_parse("<% 1 + 1 %>").should == "@out = ''; 1 + 1 ;\n@out"
  end

  it "should parse the <%- tag" do
    erbal_parse("1 + 1 is <%- 1 + 1 %>").should == "@out = '';@out.concat(%Q`1 + 1 is `); 1 + 1 ;\n@out"
  end

  it "should add a line break after <% %> tags incase the tags ended with a comment" do
    erbal_parse("<% 1 + 1 # eeek comment! %> hi mom").should == "@out = ''; 1 + 1 # eeek comment! ;\n@out.concat(%Q` hi mom`);@out"
  end

  it "should parse the <%= tag" do
    erbal_parse("<%= 1 + 1 %>").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 }`);@out"
  end

  it "should parse the comment tag <%#" do
    erbal_parse("Something:<br />\n<%# I'm a comment %>").should == "@out = '';@out.concat(%Q`Something:<br />\n`);@out"
  end

  it "should swallow the following newline if the -%> tag is used" do
    erbal_parse("<%= 1 + 1 -%>\n\n").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 }\n`);@out"
  end

  it "should not swallow the following character if the -%> tag is used and the following character is not a newline" do
    erbal_parse("<%= 1 + 1 -%>Z").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 }Z`);@out"
  end

  it "should concat text surrounding the tags when the opening tag is <%" do
    erbal_parse("1 + 1 is <% 1 + 1 %>. Easy!").should == "@out = '';@out.concat(%Q`1 + 1 is `); 1 + 1 ;\n@out.concat(%Q`. Easy!`);@out"
  end

  it "should concat text surrounding the tags when the opening tag is <%=" do
    erbal_parse("1 + 1 is <%= 1 + 1 %>. Easy!").should == "@out = '';@out.concat(%Q`1 + 1 is \#{ 1 + 1 }. Easy!`);@out"
  end

  it "should not open a new buffer shift when there is more than one consecutive <%= tag" do
    erbal_parse("1 + 1 is <%= 1 + 1 %>, and 2 + 2 is <%= 2 + 2 %>. Easy!").should == "@out = '';@out.concat(%Q`1 + 1 is \#{ 1 + 1 }, and 2 + 2 is \#{ 2 + 2 }. Easy!`);@out"
  end

  describe "when escaping special characters" do
    it "should escape a hash character that signifies the start of a string interpolation when outside tags" do
      erbal_parse("<%= 1 + 1 -%> wee \#{1 + 3}").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 } wee \\\#{1 + 3}`);@out"
      eval(erbal_parse("<%= 1 + 1 -%> wee \#{1 + 3}")).should == eval(erubis_parse("<%= 1 + 1 -%> wee \#{1 + 3}"))

      erbal_parse("<%= 1 + 1 -%> wee \\\#{1 + 3}").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 } wee \\\\\\\#{1 + 3}`);@out"
      eval(erbal_parse("<%= 1 + 1 -%> wee \\\#{1 + 3}")).should == eval(erubis_parse("<%= 1 + 1 -%> wee \\\#{1 + 3}"))

      erbal_parse("<%= 1 + 1 -%> wee \\\\\\\#{1 + 3}").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 } wee \\\\\\\\\\\\\\\#{1 + 3}`);@out"
      eval(erbal_parse("<%= 1 + 1 -%> wee \\\\\\\#{1 + 3}")).should == eval(erubis_parse("<%= 1 + 1 -%> wee \\\\\\\#{1 + 3}"))

      erbal_parse('<%= 1 + 1 -%> wee #{1 + 3}').should == "@out = '';@out.concat(%Q`\#{ 1 + 1 } wee \\\#{1 + 3}`);@out"
      eval(erbal_parse('<%= 1 + 1 -%> wee #{1 + 3}')).should == eval(erubis_parse('<%= 1 + 1 -%> wee #{1 + 3}'))
    end

    it "should not escape a hash character that signifies the start of a string interpolation when inside tags" do
      erbal_parse('<%= "#{1 + 1}" -%>').should == "@out = '';@out.concat(%Q`\#{ \"\#{1 + 1}\" }`);@out"
      eval(erbal_parse('<%= "#{1 + 1}" -%>')).should == eval(erubis_parse('<%= "#{1 + 1}" -%>'))
    end

    it "should escape a backtick character that signifies the end off a buffer shift" do
      erbal_parse("weeee `").should == "@out = '';@out.concat(%Q`weeee \\``);@out"
      eval(erbal_parse("weeee `")).should == eval(erubis_parse("weeee `"));

      erbal_parse("weeee \\`").should == "@out = '';@out.concat(%Q`weeee \\\\\\``);@out"
      eval(erbal_parse("weeee \\`")).should == eval(erubis_parse("weeee \\`"))

      erbal_parse("weeee \\\\\\\`").should == "@out = '';@out.concat(%Q`weeee \\\\\\\\\\\\\\``);@out"
      eval(erbal_parse("weeee \\\\\\\`")).should == eval(erubis_parse("weeee \\\\\\\`"))
    end
  end

  describe "when using the safe_concat_method, unsafe_concat_method and safe_concat_keyword options" do
    it "should default to using 'concat' if the :safe_concat_method option is not specified" do
      erbal_parse("hello").should == "@out = '';@out.concat(%Q`hello`);@out"
    end

    it "should default to using 'concat' if the :unsafe_concat_method option is not specified" do
      erbal_parse("<%= 1 + 1 %>").should == "@out = '';@out.concat(%Q`\#{ 1 + 1 }`);@out"
    end

    it "should use the safe concat method for text outside of tags" do
      erbal_parse("hello", :safe_concat_method => 'safe_concat').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`hello`);@output_buffer"
    end

    it "should use the unsafe concat method for the <%= tag" do
      erbal_parse("<%= 1 + 1 %>", :unsafe_concat_method => 'unsafe_concat').should == "@output_buffer = '';@output_buffer.unsafe_concat(%Q`\#{ 1 + 1 }`);@output_buffer"
    end

    it "should use the safe concat method for the <%= tag if the safe_concat_key option is also used"
    it "should not use the safe concat method for the <%= tag if the safe_concat_key option is also used but not applicable"
  end
end
