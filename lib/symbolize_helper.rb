# Goes in lib/meta_tag_helper.rb
module ActionView
  module Helpers
    module FormHelper
      # helper to create a select drop down list for the symbolize values
      def select_sym(object, method, choices = nil, options = {}, html_options = {})

        InstanceTag.new(object, method, self, options.delete(:object)).
          to_select_sym_tag(choices, options, html_options)
      end

      def radio_sym(object, method, choices = nil, options = {})
        InstanceTag.new(object, method, self, options.delete(:object)).
          to_radio_sym_tag(choices, options)
      end
    end

    class FormBuilder
      def select_sym(method, choices = nil, options = {}, html_options = {})
        @template.select_sym(@object_name, method, choices, options, html_options)
      end

      def radio_sym(method, choices = nil, options = {})
        @template.radio_sym(@object_name, method, choices, options)
      end
    end

    class InstanceTag
      # Create a select tag and one option for each of the
      # symbolize values.
      def to_select_sym_tag(choices, options, html_options)
        choices = symbolize_values(choices)
        to_select_tag(choices, options, html_options)
      end

      def to_radio_sym_tag(choices, options)
        choices = symbolize_values(choices)
        raise ArgumentError, "No values for radio tag" unless choices
        add_default_name_and_id(options)
        v = value(object)
        tag_text = ''
        template = options.dup
        template.delete('checked')
        choices.each do |choice|
          opts = template.dup
          opts['checked'] = 'checked' if v and v == choice[1]
          opts['id'] = "#{opts['id']}_#{choice[1]}"
          tag_text << "<label>#{choice[0]}: "
          tag_text << to_radio_button_tag(choice[1], opts)
          tag_text << "</label>"
        end
        tag_text
      end

      def symbolize_values(choices)
        choices.nil? ? object.class.send("get_#{@method_name}_values") : choices
      end
    end
  end
end
