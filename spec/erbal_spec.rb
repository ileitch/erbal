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
  
  it "should swallow newlines if the <%- tag is used" do
    parse("<%= 1 + 1 -%>\n").should == '@out="";@out.concat(( 1 + 1 ).to_s);@out'
  end

  it "should concat text surrounding the tags" do
    parse("1 + 1 is <% 1 + 1 %>. Easy!").should == '@out="";@out.concat("1 + 1 is "); 1 + 1 ;@out.concat(". Easy!");@out'
  end
end
