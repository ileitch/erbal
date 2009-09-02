require 'erbal'

class ErbalTemplateHandler < ActionView::TemplateHandler
  include ActionView::TemplateHandlers::Compilable
  def compile(template)
    ::Erbal.new("<% __in_erb_template=true %>#{template.source}", '@output_buffer').parse
  end
end