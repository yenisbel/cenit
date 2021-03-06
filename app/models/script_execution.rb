class ScriptExecution < Setup::Task

  default_origin :admin

  belongs_to :script, class_name: Script.to_s, inverse_of: nil

  before_save do
    self.script = Script.where(id: message['script_id']).first
  end

  def run(message)
    if (script = Script.where(id: (script_id = message[:script_id])).first)
      result =
        case result = script.run(message[:input])
        when Hash, Array
          JSON.pretty_generate(result)
        else
          result.to_s
        end
      attachment =
        if result.present?
          {
            filename: "#{script.name.collectionize}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.txt",
            contentType: 'text/plain',
            body: result
          }
        else
          nil
        end
      notify(message: "'#{script.name}' result" + (result.present? ? '' : ' was empty'),
             type: :notice,
             attachment: attachment,
             skip_notification_level: message[:skip_notification_level])
    else
      fail "Script with id #{script_id} not found"
    end
  end
end
