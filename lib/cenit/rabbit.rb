require 'json'
require 'openssl'
require 'bunny'

module Cenit
  class Rabbit

    def self.send_to_rabbitmq(message)
      conn = Bunny.new(:automatically_recover => false)
      conn.start

      ch = conn.create_channel
      q = ch.queue('send.to.endpoint')

      ch.default_exchange.publish(message, :routing_key => q.name)
      conn.close
    end

    def self.send_to_endpoints(message)
      puts "RABBIT: #{message = JSON.parse(message).with_indifferent_access}"
      flow = Setup::Flow.find(message[:flow_id])
      flow.translate(message) { |translation_result| notify_to_cenit(translation_result.merge(message: message, flow: flow)) }
    end

    def self.notify_to_cenit(translation)
      # Http codes:
      # 200...299 : OK
      # 300...399 : Redirect
      # 400...499 : Bad request
      # 500...599 : Internal Server Error

      response = translation[:response]
      message = translation[:message]
      exception = translation[:exception]

      notification = nil
      if message[:notification_id.to_s].blank?
        notification = Setup::Notification.new
        notification.flow_id = message[:flow_id.to_s]['$oid']
        notification.account_id = message[:account_id.to_s]['$oid']
        notification.json_data = message[:json_data.to_s].to_json
        notification.count = 0
      else
        notification = Setup::Notification.find(message[:notification_id.to_s]['$oid'])
      end

      if exception
        notification.http_status_message = exception.message
      else
        notification.http_status_code = response.code if response.present?
        notification.http_status_message = response.message if response.present?
      end
      notification.count += 1
      notification.save!
    end

  end
end
