require 'erbal'

class Erbal
  module Rails
    class Rails_2_3_10_TemplateHandler < ActionView::TemplateHandler
      include ActionView::TemplateHandlers::Compilable
      def compile(template)
        ::Erbal.new("<% __in_erb_template=true %>#{template.source}", {:buffer => '@output_buffer', :buffer_initial_value => 'ActiveSupport::SafeBuffer.new',
          :safe_concat_method => 'safe_concat', :unsafe_concat_method => 'concat', :safe_concat_keyword => 'raw'}).parse
      end
    end

    def self.version_unsupported
      raise "Sorry, this version of Erbal doesn't support Rails #{ActionPack::VERSION::MAJOR}.#{ActionPack::VERSION::MINOR}.#{ActionPack::VERSION::TINY}."
    end

    def self.register_template_handler(handler_class)
      ActionView::Template.register_template_handler :erb, handler_class
    end

    def self.register_template_handler_for_2_3_10
      register_template_handler(Rails_2_3_10_TemplateHandler)
    end
  end
end

case ActionPack::VERSION::MAJOR
when 2
  case ActionPack::VERSION::MINOR
  when 3
    case ActionPack::VERSION::TINY
    when 10
      Erbal::Rails.register_template_handler_for_2_3_10
    else
      Erbal::Rails.version_unsupported
    end
  else
    Erbal::Rails.version_unsupported
  end
else
  Erbal::Rails.version_unsupported
end