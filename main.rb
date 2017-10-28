#!/usr/bin/env ruby
require './lib/helpers/helpers'
require 'pry'
require 'faraday'

include Helpers

listen=-> {
  @bot_type="Listen"
  @parks=['Tauron Arena Kraków🚀', 'Kasprowy Wierch⛰', 'Gubałówka🏔', 'Jaworzyna Krynicka🗻', 'Góra Parkowa⛲️']
  @dates=%w(29.10 30.10 31.10 01.11 02.11 03.11)
  @activities=%w(Hiking🏃 Climbing🚠 Sightseeing👓 Fishing🎣 Ecocamping🏕 Offroad🚵 Skiing⛷ Snowboarding🏂 Kayaking🛶)
  @data={'default' => []}
  Telegram::Bot::Client.run(telegram_token) do |bot|
    def updateData(id, update)
      @data[id]=[] unless @data[id]
      @data[id] << update
    end

    
    bot.listen do |message|
      puts message.inspect
      is_current=-> {@data[message.chat.id][0] == @parks[0]}
      puts @data
      begin
        if message.text == '/start'
          question = 'What national park are you going to?'
          # See more: https://core.telegram.org/bots/api#replykeyboardmarkup
          answers =
              Telegram::Bot::Types::ReplyKeyboardMarkup
                  .new(keyboard: @parks, one_time_keyboard: true)
          @data[message.chat.id] = []
          bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.chat.first_name}! Lorangers welcome you🙌")
          bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('./static/lora_logo.jpg', 'jpg'))
          bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
        elsif message.text == 'Yes'
          bot.api.send_message(chat_id: message.chat.id, text: 'Travel with care')
        elsif message.text == 'No'
          bot.api.send_message(chat_id: message.chat.id, text: 'Do not forget to buy one to stay on the safe side')
        elsif message.text == 'No👎'
          bot.api.send_message(chat_id: message.chat.id, text: 'See you another day')
        elsif message.text == 'Yes👍'
          if is_current.call
            bot.api.send_message(chat_id: message.chat.id, text: 'Mostly cloudy. Chance of rain 5 percent. Not windy')
            bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('./static/cloudy.png', 'png'))
          else
            bot.api.send_message(chat_id: message.chat.id, text: 'Rain at the moment, then showers after midnight. West
winds 15 to 25 kph with gusts up to 40 kph')
            bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('./static/rainy.png', 'png'))
          end
          # bot.api.send_message(chat_id: message.chat.id, text: "#{@data[message.chat.id]}")
          answers =
              Telegram::Bot::Types::ReplyKeyboardMarkup
                  .new(keyboard: %w(Yes No), one_time_keyboard: true)
          question = "#{message.chat.first_name}, do you have a LoRa device?"
          bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
        elsif @parks.any? {|s| s==message.text}
          updateData(message.chat.id, @parks.grep(message.text).last)
          # @data[message.chat.id]=[] unless @data[message.chat.id]
          # @data[message.chat.id] <<
          answers =
              Telegram::Bot::Types::ReplyKeyboardMarkup
                  .new(keyboard: @dates, one_time_keyboard: true)
          question = 'When do you plan to go there?'
          bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
        elsif @activities.any? {|s| s==message.text}
          # @data[message.chat.id] << @dates.grep(message.text).last
          updateData(message.chat.id, @activities.grep(message.text).last)
          bot.api.send_message(chat_id: message.chat.id, text: "#{message.chat.first_name} you plan to travel to #{@data[message.chat.id][0]} at #{@data[message.chat.id][1]} doing #{@data[message.chat.id][2]}")
          kb = [
              Telegram::Bot::Types::KeyboardButton.new(text: "Show me your location, #{message.chat.first_name}", request_location: true)
          ]
          markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
          bot.api.send_message(chat_id: message.chat.id, text: 'Your location', reply_markup: markup)
        elsif @dates.any? {|s| s==message.text}
          updateData(message.chat.id, @dates.grep(message.text).last)
          answers =
              Telegram::Bot::Types::ReplyKeyboardMarkup
                  .new(keyboard: @activities, one_time_keyboard: true)
          question = 'What do you plan to do there?'
          bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
          # bot.api.send_message(chat_id: message.chat.id, text: "Welcome to #{@data[message.chat.id][0]} at #{@data[message.chat.id][1]}")
        elsif message.location
          puts message
          time_to_travel= is_current.call ? 1 : Random.rand(120...250)
          bot.api.send_message(chat_id: message.chat.id, text: "#{message.chat.first_name}, your trip to #{@data[message.chat.id][0].chop} will take approximately #{time_to_travel}mins🚙")
          sleep(7)
          bot.api.send_message(chat_id: message.chat.id, text: "According to LoRa devices the weather conditions are #{is_current.call ? 'moderate💨' : 'bad☂'}")

          bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('./static/button.jpeg', 'jpeg')) if is_current.call
          bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('./static/button.png', 'png')) unless is_current.call
          answers =
              Telegram::Bot::Types::ReplyKeyboardMarkup
                  .new(keyboard: %w(Yes👍 No👎), one_time_keyboard: true)
          question = 'Do you still plan to travel?'
          bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Your command #{message} has not been recognized")
        end
      rescue Exception => e
        # bot.api.send_message(chat_id: message.chat.id, text: "API ERROR - #{e}")
        puts e
      end
    end
  end
}

case ARGV[0]
  when "--listen"
    listen.call
  else
    puts "No arguments provided"
    return
end

