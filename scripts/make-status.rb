# coding: utf-8
require 'open-uri'

UPDATE_INTERVAL = 1

def get_weather()
  " " + `cat ~/stats/weather`.chomp
end

def get_funds()
  "" + `cat ~/stats/funds`.chomp
end

def get_vol()
  " " + `~/sh/vol.sh`.chomp
end

def get_battery()
  " " + `ruby sh/battery.rb`.chomp
end

def get_month()
  " " + Time.new.strftime("%b %d")
end

def get_time()
  " " + Time.new.strftime("%I:%M %p")
end

def get_music()
  " " + `echo "\`playerctl metadata 'xesam:title'\` - \`playerctl metadata 'xesam:artist'\`"`.chomp
end

def vpn?()
  `ip route show`.include?("default via 10.8.0.5 dev tun0")
end

def colorize_vpn()
  if vpn?()
    return "%{B#181818}"
  else
    return "%{B#AB4642}"
  end
end


#while true
# for some reason this works while print doesn't
STDIN.each do |line|
  system('echo', '-e', "#{line.chomp} %{r} #{colorize_vpn} #{get_music()} #{get_funds()} #{get_weather()} #{get_battery()}% #{get_vol()} #{get_month()} #{get_time()}")
#  sleep 0.5
end
