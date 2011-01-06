require 'action_pack'
require 'erbal'

class Erbal
  module Rails
    class Rails_2_3_TemplateHandler < ActionView::TemplateHandler
      include ActionView::TemplateHandlers::Compilable
      def compile(template)
        ::Erbal.new("<% __in_erb_template=true %>#{template.source}", {:buffer => '@output_buffer'}).parse
      end
    end

    def self.version_unsupported
      raise "Sorry, this version of Erbal doesn't support Rails #{ActionPack::VERSION::MAJOR}.#{ActionPack::VERSION::MINOR}.#{ActionPack::VERSION::TINY}."
    end

    def self.register_template_handler_for_2_3
      ActionView::Template.register_template_handler :erb, Rails_2_3_TemplateHandler
      ActionView::Template.register_template_handler :rhtml, Rails_2_3_TemplateHandler
    end
  end
end

case ActionPack::VERSION::MAJOR
when 2
  case ActionPack::VERSION::MINOR
  when 3
    Erbal::Rails.register_template_handler_for_2_3
  else
    Erbal::Rails.version_unsupported
  end
else
  Erbal::Rails.version_unsupported
end
