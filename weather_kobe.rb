# encoding: utf-8

require 'twitter'
require 'rss'
require 'scanf'
require 'json'
require 'oauth'
require 'uri'
load '/home/yutaono/weather_kobe/twitter_keys.rb'

### Twitter Setting
USER_NAME = 'weather_kobe'
Twitter.configure do |cnf|
  cnf.consumer_key = getCK()
  cnf.consumer_secret = getCS()
  cnf.oauth_token = getAT()
  cnf.oauth_token_secret = getATS()
end

def str_from_end(string, n)
  return string[string.length-n..string.length]
end

def ignore_html_tag(string)
  string.gsub!(/<("[^"]*"|'[^']*'|[^'">])*>/, "")
end

def getChanceOfRainfall(iday)
  uri = URI.parse('http://weather.jp.msn.com/RSS.aspx?wealocations=wc:JAXX0040&weadegreetype=C&culture=ja-JP')
  rss = RSS::Parser.parse(uri, false)
  str = rss.channel.item(0).description
  tenki = ignore_html_tag(str).split("%")
  return str_from_end(tenki[iday], 2)
end

def forecast(iday)
  c = "℃"
  rss = RSS::Parser.parse("http://rss.weather.yahoo.co.jp/rss/days/6310.xml")
  tenki_info = rss.channel.item(iday).description.scanf("%s - %d"+c+"/%d"+c)
  tenki = tenki_info[0]
  max = tenki_info[1]
  min = tenki_info[2]

  # 今日か明日、どちらの天気をつかうか設定
  if(iday==0)
    yesterday = Time.now-(60*24*60)
    preday = yesterday.strftime("%Y/%m/%d")
    day_str = "今日"
    theday = Time.now.strftime("%Y/%m/%d")
  end
  if(iday==1)
    today = Time.now
    preday = today.strftime("%Y/%m/%d")
    day_str = "明日"
    tommorow = Time.now+(60*24*60)
    theday = tommorow.strftime("%Y/%m/%d")
  end

  cor = getChanceOfRainfall(iday).to_i

  # 過去の天気ログから情報引き出し
  para = false
  logtxt = open("/home/yutaono/weather_kobe/log.txt", "a+")
  while l = logtxt.gets
    if(l.include?(preday))
      preday_info = l.chomp.split(",")
    end
    if(l.include?(theday))
      para = true
    end
  end
  if !para
    logtxt.write theday + ", " + tenki + ", " + max.to_s + ", " + min.to_s + ", " + cor.to_s + "\n"
  end

  # 気温差を計算
  diff_max = "%+d"%(max - preday_info[2].to_i)
  diff_min = "%+d"%(min - preday_info[3].to_i)

  # 暑い時、寒い時の内容を設定
  atuisamui = ""
  if (max <= 13 || min < 9)
    atuisamui = "寒いのでヒートテック的なものを着ていきましょう。"
  elsif (max >= 28 || min >= 23)
    atuisamui = "暑いので熱中症に注意しましょう"

  end

  # 降水確率と天気から内容を設定
#  cor = getChanceOfRainfall(iday).to_i
  umbrella = ""
  if(tenki.include?("雨") || cor>= 50)
    umbrella = "、傘が必要です。"
  elsif (tenki.include?("晴") && cor<= 10)
    umbrella = "、洗濯日和です。"
  else
    umbrella = "す。"
  end

  rstr = day_str + "の神戸の天気は" + tenki + "、最高" + max.to_s + c + "(" + diff_max.to_s + ")/最低" + min.to_s + c + "(" + diff_min.to_s + ")です。"
  rstr += "降水確率は" + cor.to_s + "%で" + umbrella
  rstr += atuisamui
  return rstr
end

today = Time.now
if today.hour < 12
  Twitter.update(forecast(0))
#  p forecast(0)
else
  Twitter.update(forecast(1))
#  p forecast(1)
end

# フォロー返し
follower = Twitter.follower_ids(USER_NAME).ids
fol = Twitter.friend_ids(USER_NAME).ids
fan = follower - fol
fan.each do |f|
  name = Twitter.user(f)["screen_name"]
  Twitter.follow(f)
end






