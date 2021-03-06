require 'uri'
require 'json'
require 'csv'
require 'net/http'
# require 'pry'

class Gateway
  BASE = 'http://weather.livedoor.com/forecast/webservice/json/v1?city='.freeze

  class << self
    # 天気のjsonのコレクションをを返す、空の場合nilを返す
    def parse!(text)
      generate(text).each_with_object(Weathers.new(text)) {|url, weathers|
        res = Net::HTTP.get(URI.parse(url)) # 引数はURIインスタンスのみ
        weathers << Weather.new(JSON.parse(res))
      }.check
    end

    private

    # 都道府県に応じたAPIのURLを作って配列で返す
    def generate(text)
      hash.each_with_object([]) {|(k, v), ary| ary << (BASE + v) if text.include? k.chop }
    end

    # csvを読み込んで{'都道府県' => '都道府県ID'}ハッシュで返す
    def hash
      @hash ||= CSV.read(listfile).each_with_object({}) {|ary, h| h[ary[0]] = ary[1] }
    end

    # 絶対パス生成
    def listfile
      @listfile ||= File.expand_path("api_list.csv", __dir__)
    end
  end

  class Weather
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
        最高気温: #{@location["forecasts"][i]["temperature"].dig("max", "celsius") &.+ "度" or "情報なし"}
        最低気温: #{@location["forecasts"][i]["temperature"].dig("min", "celsius") &.+ "度" or "情報なし"}
      TEXT
    end
  end

  class Weathers
    include Enumerable

    def initialize(text, weathers = [])
      @weathers = weathers
      @text = text
    end

    def <<(weather)
      @weathers << weather
      self
    end

    def check
      @weathers.empty? ? nil : self
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

          #{weather.summary if @text.match(/概|詳/)}
        TEXT
      end
    end
  end
end
