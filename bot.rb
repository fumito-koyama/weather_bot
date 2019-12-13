require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require './weather.rb'

TOKEN = 'xoxb-872847036759-860788752641-1iYOR05PVOgZ1vhEEvsuvF8R'

response = HTTP.post("https://slack.com/api/rtm.start", params: {
    token: TOKEN #ENV['SLACK_API_TOKEN']
  })

rc = JSON.parse(response.body)

url = rc['url']

EM.run do
  # Web Socketインスタンスの立ち上げ
  ws = Faye::WebSocket::Client.new(url)

  #  接続が確立した時の処理
  ws.on :open do
    p [:open]
  end

  # RTM APIから情報を受け取った時の処理
  ws.on :message do |event|
    data = JSON.parse(event.data)
    p [:message,data]
    next unless data['text']&.include? '天気'
    if weathers =  Gateway::parse!(data['text']).text
      weathers.each do |weather|
        ws.send({
          type: 'message',
          text: weather,
          channel: data['channel']
          }.to_json)
      end
    end
  end

  # 接続が切断した時の処理
  ws.on :close do |event|
    p [:close, event.code]
    ws = nil
    EM.stop
  end

end