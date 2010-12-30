require 'erbal'

if ActiveSupport.const_defined?('SafeBuffer')

  class ErbalTemplateHandler < ActionView::TemplateHandler
    include ActionView::TemplateHandlers::Compilable
    def compile(template)
      ::Erbal.new("<% __in_erb_template=true %>#{template.source}", {:buffer => '@output_buffer', :buffer_initial_value => 'ActiveSupport::SafeBuffer.new'}).parse
    end
  end

else

  class ErbalTemplateHandler < ActionView::TemplateHandler
    include ActionView::TemplateHandlers::Compilable
    def compile(template)
      ::Erbal.new("<% __in_erb_template=true %>#{template.source}", {:buffer => '@output_buffer'}).parse
    end
  end

end