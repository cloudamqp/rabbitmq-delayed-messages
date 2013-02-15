require 'bunny'

B = Bunny.new ENV['CLOUDAMQP_URL']
B.start

DELAYED_QUEUE='work.later'
DESTINATION_QUEUE='work.now'

def publish
  ch = B.create_channel
  # declare a queue with the DELAYED_QUEUE name
  ch.queue(DELAYED_QUEUE, arguments: {
    # set the dead-letter exchange to the default queue
    'x-dead-letter-exchange' => '',
    # when the message expires, set change the routing key into the destination queue name
    'x-dead-letter-routing-key' => DESTINATION_QUEUE,
    # the time in milliseconds to keep the message in the queue
    'x-message-ttl' => 3000
  })
  # publish to the default exchange with the the delayed queue name as routing key,
  # so that the message ends up in the newly declared delayed queue
  ch.default_exchange.publish 'message content', routing_key: DELAYED_QUEUE
  puts "#{Time.now}: Published the message"
  ch.close
end

def subscribe
  ch = B.create_channel
  # declare the destination queue
  q = ch.queue DESTINATION_QUEUE, durable: true 
  q.subscribe do |delivery, headers, body|
    puts "#{Time.now}: Got the message"
  end
end

subscribe()
publish()

sleep
