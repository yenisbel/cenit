module Forms
  class ImportTranslator
    include Mongoid::Document

    belongs_to :data_type, class_name: Setup::DataType.to_s, inverse_of: nil
    belongs_to :translator, class_name: Setup::Translator.to_s, inverse_of: nil

    field :file, type: String
    field :data, type: String

    validates_presence_of :translator

    #TODO Validate presence of one of data or file

    rails_admin do
      visible false
      register_instance_option(:discard_submit_buttons) { true }
      edit do
        field :translator do
          inline_edit false
          inline_add false
          associated_collection_cache_all { true }
          associated_collection_scope do
            data_type = bindings[:object].try(:data_type)
            Proc.new { |scope|
              scope.any_in(target_data_type: [nil, data_type]).and(type: :Import)
            }
          end
        end

        field :file do
          render do
            bindings[:form].file_field(self.name, self.html_attributes.reverse_merge(data: { fileupload: true }))
          end
        end

        field :data do
          html_attributes do
            {cols: '74', rows: '15'}
          end
        end
      end
    end
  end
end
