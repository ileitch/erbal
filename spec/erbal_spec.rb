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

  it "should parse a blank string" do
    erbal_parse("").should == "@out = '';@out"
  end

  it "should parse content without any tags" do
    erbal_parse("I love unicorns!").should == "@out = '';@out << %Q`I love unicorns!`;@out"
  end

  it "should parse the <% tag" do
    erbal_parse("<% 1 + 1 %>").should == "@out = ''; 1 + 1 ;\n@out"
  end

  it "should parse the <%- tag" do
    erbal_parse("1 + 1 is <%- 1 + 1 %>").should == "@out = '';@out << %Q`1 + 1 is `; 1 + 1 ;\n@out"
  end

  it "should add a line break after <% %> tags incase the tags ended with a comment" do
    erbal_parse("<% 1 + 1 # eeek comment! %> hi mom").should == "@out = ''; 1 + 1 # eeek comment! ;\n@out << %Q` hi mom`;@out"
  end

  it "should parse the <%= tag" do
    erbal_parse("<%= 1 + 1 %>").should == "@out = '';@out << %Q`\#{ 1 + 1 }`;@out"
  end

  it "should parse the comment tag <%#" do
    erbal_parse("Something:<br />\n<%# I'm a comment %>").should == "@out = '';@out << %Q`Something:<br />\n`;@out"
  end

  it "should swallow the following newline if the -%> tag is used" do
    erbal_parse("<%= 1 + 1 -%>\n\n").should == "@out = '';@out << %Q`\#{ 1 + 1 }\n`;@out"
  end

  it "should not swallow the following character if the -%> tag is used and the following character is not a newline" do
    erbal_parse("<%= 1 + 1 -%>Z").should == "@out = '';@out << %Q`\#{ 1 + 1 }Z`;@out"
  end

  it "should concat text surrounding the tags when the opening tag is <%" do
    erbal_parse("1 + 1 is <% 1 + 1 %>. Easy!").should == "@out = '';@out << %Q`1 + 1 is `; 1 + 1 ;\n@out << %Q`. Easy!`;@out"
  end

  it "should concat text surrounding the tags when the opening tag is <%=" do
    erbal_parse("1 + 1 is <%= 1 + 1 %>. Easy!").should == "@out = '';@out << %Q`1 + 1 is \#{ 1 + 1 }. Easy!`;@out"
  end

  it "should not open a new buffer shift when there is more than one consecutive <%= tag" do
    erbal_parse("1 + 1 is <%= 1 + 1 %>, and 2 + 2 is <%= 2 + 2 %>. Easy!").should == "@out = '';@out << %Q`1 + 1 is \#{ 1 + 1 }, and 2 + 2 is \#{ 2 + 2 }. Easy!`;@out"
  end

  it "should escape a hash character that signifies the start of a string interpolation when outside tags" do
    erbal_parse("<%= 1 + 1 -%> wee \#{1 + 3}").should == "@out = '';@out << %Q`\#{ 1 + 1 } wee \\\#{1 + 3}`;@out"
    eval(erbal_parse("<%= 1 + 1 -%> wee \#{1 + 3}")).should == eval(erubis_parse("<%= 1 + 1 -%> wee \#{1 + 3}"))

    erbal_parse("<%= 1 + 1 -%> wee \\\#{1 + 3}").should == "@out = '';@out << %Q`\#{ 1 + 1 } wee \\\\\\\#{1 + 3}`;@out"
    eval(erbal_parse("<%= 1 + 1 -%> wee \\\#{1 + 3}")).should == eval(erubis_parse("<%= 1 + 1 -%> wee \\\#{1 + 3}"))

    erbal_parse("<%= 1 + 1 -%> wee \\\\\\\#{1 + 3}").should == "@out = '';@out << %Q`\#{ 1 + 1 } wee \\\\\\\\\\\\\\\#{1 + 3}`;@out"
    eval(erbal_parse("<%= 1 + 1 -%> wee \\\\\\\#{1 + 3}")).should == eval(erubis_parse("<%= 1 + 1 -%> wee \\\\\\\#{1 + 3}"))

    erbal_parse('<%= 1 + 1 -%> wee #{1 + 3}').should == "@out = '';@out << %Q`\#{ 1 + 1 } wee \\\#{1 + 3}`;@out"
    eval(erbal_parse('<%= 1 + 1 -%> wee #{1 + 3}')).should == eval(erubis_parse('<%= 1 + 1 -%> wee #{1 + 3}'))
  end

  it "should not escape a hash character that signifies the start of a string interpolation when inside tags" do
    erbal_parse('<%= "#{1 + 1}" -%>').should == "@out = '';@out << %Q`\#{ \"\#{1 + 1}\" }`;@out"
    eval(erbal_parse('<%= "#{1 + 1}" -%>')).should == eval(erubis_parse('<%= "#{1 + 1}" -%>'))
  end

  it "should escape a backtick character that signifies the end off a buffer shift" do
    erbal_parse("weeee `").should == "@out = '';@out << %Q`weeee \\``;@out"
    eval(erbal_parse("weeee `")).should == eval(erubis_parse("weeee `"));

    erbal_parse("weeee \\`").should == "@out = '';@out << %Q`weeee \\\\\\``;@out"
    eval(erbal_parse("weeee \\`")).should == eval(erubis_parse("weeee \\`"))

    erbal_parse("weeee \\\\\\\`").should == "@out = '';@out << %Q`weeee \\\\\\\\\\\\\\``;@out"
    eval(erbal_parse("weeee \\\\\\\`")).should == eval(erubis_parse("weeee \\\\\\\`"))
  end
end
