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

    it "should use the safe concat method for the <%= tag if the safe_concat_keyword option is also used" do
      erbal_parse("<%= raw 1 + 1 %>", :safe_concat_method => 'safe_concat', :safe_concat_keyword => 'raw').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`\#{ 1 + 1 }`);@output_buffer"
    end

    it "should not use the safe concat method for the <%= tag if the safe_concat_keyword option is also used but not applicable" do
      erbal_parse("<%= blah 1 + 1 %>", :unsafe_concat_method => 'unsafe_concat').should == "@output_buffer = '';@output_buffer.unsafe_concat(%Q`\#{ blah 1 + 1 }`);@output_buffer"
    end

    it "should not set a default safe_concat_keyword option" do
      erbal_parse("1 + 1 is <%= raw 1 + 1 %>", :unsafe_concat_method => 'unsafe_concat', :safe_concat_keyword => nil).should == "@output_buffer = '';@output_buffer.concat(%Q`1 + 1 is `);@output_buffer.unsafe_concat(%Q`\#{ raw 1 + 1 }`);@output_buffer"
    end

    it "should allow some non a-z characters as part of the safe_concat_keyword" do
      erbal_parse("<%=!@$*=^&+ 1 + 1 %>", :safe_concat_method => 'safe_concat', :safe_concat_keyword => '!@$*=^&+').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`\#{ 1 + 1 }`);@output_buffer"
    end

    it "should preserve the whitespace following the safe_concat_keyword" do
      erbal_parse("<%= raw   1 + 1 %>", :safe_concat_method => 'safe_concat', :safe_concat_keyword => 'raw').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`\#{   1 + 1 }`);@output_buffer"
    end

    it "should not swallow the text preceding the safe concat" do
      erbal_parse("omg don't eat me! <%= raw   1 + 1 %>", :safe_concat_method => 'safe_concat', :safe_concat_keyword => 'raw').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`omg don't eat me! \#{   1 + 1 }`);@output_buffer"
    end

    it "should use the safe concat method for the <%= tag if the safe_concat_keyword option is also used and the keyword has no preceding whitespace" do
      erbal_parse("<%=raw 1 + 1 %>", :safe_concat_method => 'safe_concat', :safe_concat_keyword => 'raw').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`\#{ 1 + 1 }`);@output_buffer"
    end

    it "should not use the safe concat method for the <%= tag if the safe_concat_keyword option is also used but not applicable and the keyword has no preceding whitespace" do
      erbal_parse("omglololo <%=blah 1 + 1 %>", :unsafe_concat_method => 'unsafe_concat').should == "@output_buffer = '';@output_buffer.concat(%Q`omglololo `);@output_buffer.unsafe_concat(%Q`\#{blah 1 + 1 }`);@output_buffer"
    end

    it "should not use the safe concat method if the it is used as a helper method call" do
      erbal_parse("<%= raw(1 + 1) %>", :unsafe_concat_method => 'unsafe_concat', :safe_concat_keyword => 'raw').should == "@output_buffer = '';@output_buffer.unsafe_concat(%Q`\#{ raw(1 + 1) }`);@output_buffer"
    end

    it "should end the current safe concat and begin a new unsafe concat" do
      erbal_parse("hello <%= \"world\" %>", :unsafe_concat_method => 'unsafe_concat', :safe_concat_method => 'safe_concat').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`hello `);@output_buffer.unsafe_concat(%Q`\#{ \"world\" }`);@output_buffer"
    end

    it "should end the current unsafe concat and begin a new safe concat when at the end of the source" do
      erbal_parse("<%= \"hello\" %> world", :unsafe_concat_method => 'unsafe_concat', :safe_concat_method => 'safe_concat').should == "@output_buffer = '';@output_buffer.unsafe_concat(%Q`\#{ \"hello\" }`);@output_buffer.safe_concat(%Q` world`);@output_buffer"
    end

    it "should end the current unsafe concat and begin a new safe concat when inbetween two unsafe concats" do
      erbal_parse("<%= \"hello\" %> world <%= \"woot\" %>", :unsafe_concat_method => 'unsafe_concat', :safe_concat_method => 'safe_concat').should == "@output_buffer = '';@output_buffer.unsafe_concat(%Q`\#{ \"hello\" }`);@output_buffer.safe_concat(%Q` world `);@output_buffer.unsafe_concat(%Q`\#{ \"woot\" }`);@output_buffer"
    end

    describe "when preserving string interpolation optimizations if safe and unsafe concat methods are the same" do
      it "should use interpolation if we switch from a safe concat to an unsafe concat" do
        erbal_parse("hello <%= \"world\" %>", :unsafe_concat_method => 'concat', :safe_concat_method => 'concat').should == "@output_buffer = '';@output_buffer.concat(%Q`hello \#{ \"world\" }`);@output_buffer"
      end

      it "should use interpolation if we switch from an unsafe concat to a safe concat" do
        erbal_parse("<%= \"hello\" %> world", :unsafe_concat_method => 'concat', :safe_concat_method => 'concat').should == "@output_buffer = '';@output_buffer.concat(%Q`\#{ \"hello\" } world`);@output_buffer"
      end

      it "should use interpolation if we switch from a safe concat to an unsafe concat and then back again" do
        erbal_parse("hello <%= \"world\" %> woot", :unsafe_concat_method => 'concat', :safe_concat_method => 'concat').should == "@output_buffer = '';@output_buffer.concat(%Q`hello \#{ \"world\" } woot`);@output_buffer"
      end

      it "should use interpolation if we switch from an unsafe concat to a safe concat and then back again" do
        erbal_parse("omg <%= \"hello\" %> world", :unsafe_concat_method => 'concat', :safe_concat_method => 'concat').should == "@output_buffer = '';@output_buffer.concat(%Q`omg \#{ \"hello\" } world`);@output_buffer"
      end

      it "should not use interpolation if the unsafe and safe concat methods are not the same" do
        erbal_parse("omg <%= raw \"hello\" %> world", :unsafe_concat_method => 'concat', :safe_concat_method => 'safe_concat').should == "@output_buffer = '';@output_buffer.safe_concat(%Q`omg `);@output_buffer.concat(%Q`\#{ raw \"hello\" }`);@output_buffer.safe_concat(%Q` world`);@output_buffer" 
      end
    end
  end
end
