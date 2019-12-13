require 'uri'
require 'json'
require 'csv'
require 'net/http'
#require 'pry'

class Gateway
  # MAEBASHI = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=100010'
  # MINAKAMI = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=100020'
  BASE = 'http://weather.livedoor.com/forecast/webservice/json/v1?city='
  # PREFECTURES = ["北海道","青森県","岩手県","宮城県","秋田県","山形県","福島県","茨城県","栃木県","群馬県","埼玉県","千葉県","東京都","神奈川県","新潟県","富山県","石川県","福井県","山梨県","長野県","岐阜県","静岡県","愛知県","三重県","滋賀県","京都府","大阪府","兵庫県","奈良県","和歌山県","鳥取県","島根県","岡山県","広島県","山口県","徳島県","香川県","愛媛県","高知県","福岡県","佐賀県","長崎県","熊本県","大分県","宮崎県","鹿児島県","沖縄県"]

  class << self

    def parse!(text)
      generate(text).inject(Weathers.new(text)) do |weathers,url|
        res = Net::HTTP.get(URI.parse(url))#引数はURIインスタンスのみ
        weathers << Weather.new(JSON.parse(res))
        weathers
      end
    end

    private

    def generate(text)
      hash.inject([]){|a,(k,v)|a << (BASE+v) if text.include? k.chop; a}
      # element = ['100010'] if element.empty?
      # element
    end

    def hash
      @prefectures ||= CSV.read(listfile).inject({}){|h,ary| h[ary[0]] = ary[1]; h}
    end

    def listfile
      @listfile ||= File.expand_path('api_list.csv', __dir__)
    end

  end

  class Weather
    #attr_accessor :location

    def initialize(json)
      @location = json
    end

    def today
      template(0)
    end

    def tomorrow
      template(1)
    end

    def summary
      "概況: #{@location["description"]["text"]}"
    end
    
    private
    def template(i)
      <<~TEXT
      #{@location["forecasts"][i]["dateLabel"]}の#{@location["location"]["prefecture"]}(#{@location["location"]["city"]})の天気
      日付: #{@location["forecasts"][i]["date"]}
      天気: #{@location["forecasts"][i]["telop"]}
      最高気温: #{@location["forecasts"][i]["temperature"].dig("max","celsius") &.+ '度' or "情報なし"}
      最低気温: #{@location["forecasts"][i]["temperature"].dig("min","celsius") &.+ '度' or "情報なし"}
      TEXT
    end
  end

  class Weathers
    include Enumerable

    def initialize(text,weathers = [])
      @weathers = weathers
      @text = text
    end

    def <<(weather)
      @weathers << weather
    end

    def each 
      for weather in @weathers
        yield weather
      end
    end

    def text
      @weathers.map do |weather|
        <<~TEXT
        #{weather.today}

        #{weather.tomorrow}

        #{weather.summary if @text.match /概|詳/}
        TEXT
      end
    end
  end
end