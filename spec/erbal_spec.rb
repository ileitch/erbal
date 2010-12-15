require 'spec_helper'

describe Erbal do
  def parse(str)
    Erbal.new(str, '@out').parse
  end

  it "should parse the <% tag" do
    parse("<% 1 + 1 %>").should == '@out=""; 1 + 1 ;@out'
  end

  it "should parse the <%= tag" do
    parse("<%= 1 + 1 %>").should == '@out="";@out.concat(( 1 + 1 ).to_s);@out'
  end

  it "should parse the comment tag <%#" do
    parse("<%# I'm a comment %>").should == '@out="";@out'
  end

  it "should swallow the following newline if the -%> tag is used" do
    parse("<%= 1 + 1 -%>\n").should == '@out="";@out.concat(( 1 + 1 ).to_s);@out'
  end

  it "should not swallow the following character if the -%> tag is used and the following character is not a newline"

  it "should swallow the preceding newline if the <%- tag is used"

  it "should concat text surrounding the tags when the opening tag is <%" do
    parse("1 + 1 is <% 1 + 1 %>. Easy!").should == '@out="";@out.concat("1 + 1 is "); 1 + 1 ;@out.concat(". Easy!");@out'
  end

  it "should concat text surrounding the tags when the opening tag is <%=" do
    parse("1 + 1 is <%= 1 + 1 %>. Easy!").should == '@out="";@out.concat("1 + 1 is ");@out.concat(2.to_s);@out.concat(". Easy!");@out'
  end
end
