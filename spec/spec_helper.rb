$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
`rake compile`
require 'erbal'
RSpec.configure do |config|
  config.after :suite do
    puts
    `rake clean`
  end
end