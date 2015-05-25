
require 'sinatra'
require 'json'
require 'active_record'
require 'sqlite3'
require 'rufus-scheduler'
require 'weather-api'
require 'date'
require 'tts'
 
class Alarm < ActiveRecord::Base
end

class Date
  def dayname
     DAYNAMES[self.wday]
  end
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'dbfile.sqlite3')

if ARGV[0] == 'reset'
  ActiveRecord::Migration.class_eval do
    drop_table :alarms do |t|
    end
  end
  ActiveRecord::Migration.class_eval do
    create_table :alarms do |t|
      t.string :name
      t.integer :hour
      t.integer :min
      t.boolean :sun, default: false
      t.boolean :mon, default: false
      t.boolean :tue, default: false 
      t.boolean :wed, default: false 
      t.boolean :thu, default: false 
      t.boolean :fri, default: false 
      t.boolean :sat, default: false 
    end
  end  
end

def check_for_alarms  
  puts "== checking times in db #{Time.now}"
  alarms = Alarm.all
  alarms.each do |a|
    puts "== #{Time.now.hour.to_i} == #{a.hour} && #{Time.now.min.to_i} == #{a.min}"
    day = Date.today.dayname[0..2].downcase
    if Time.now.hour.to_i == a.hour && Time.now.min.to_i == a.min && a[day] == true
      `mpg123 notify.mp3`
      response = Weather.lookup(2452078)
      "Good morning Ben! The forecast today shows #{response.forecasts[0].text} with a high temperature of #{response.forecasts[0].high} degrees, and a low temperature of #{response.forecasts[0].low} degrees. The forecast now shows #{response.condition.text}, and it is #{response.condition.temp} degrees. Have a great day!".play
    end
  end
  ActiveRecord::Base.connection.close
end

check_for_alarms  
scheduler = Rufus::Scheduler.new
scheduler.every '60' do    
  check_for_alarms  
end

after { ActiveRecord::Base.connection.close }

get '/alarms' do
  r = Alarm.all.to_json
  r
end

get '/alarms/:id' do |id|
  msg = ""
  begin
    if id
      r = Alarm.find(id).to_json
    else
      msg = "id not specified"
      throw msg
    end
  rescue Exception => e
    r = "{\"error\": #{msg}}"
  end
  r
end

post '/alarms' do
  msg = ""
  begin
    request.body.rewind
    o = JSON.parse(request.body.read) 
    
    a = Alarm.new
    if o['name']
      a.name = o['name']
    else
      msg = "name not specified"
      throw msg
    end
    if o['hour']
      a.hour = o['hour'].to_i
    else
      msg = "hour not specified"
      throw msg
    end
    if o['min']
      a.min = o['min'].to_i
    else
      msg = "min not specified"
      throw msg
    end 

    o['sun'] ? a.sun = o['sun'] : nil 
    o['mon'] ? a.mon = o['mon'] : nil 
    o['tue'] ? a.tue = o['tue'] : nil 
    o['wed'] ? a.wed = o['wed'] : nil 
    o['thu'] ? a.thu = o['thu'] : nil 
    o['fri'] ? a.fri = o['fri'] : nil 
    o['sat'] ? a.sat = o['sat'] : nil 
    
    a.save!
    r = a.to_json
  rescue Exception => e
    r = "{\"error\": #{msg}}"
    raise e
  end
  r
end 

put '/alarms/:id' do |id|
  msg = ""
  begin
    if id
      request.body.rewind
      o = JSON.parse(request.body.read) 
      
      a = Alarm.find(id)
      if o['name']
        a.name = o['name']
      end
      if o['hour']
        a.hour = o['hour'].to_i
      end
      if o['min']
        a.min = o['min'].to_i
      end  
      o['sun'] ? a.sun = o['sun'] : nil 
      o['mon'] ? a.mon = o['mon'] : nil 
      o['tue'] ? a.tue = o['tue'] : nil 
      o['wed'] ? a.wed = o['wed'] : nil 
      o['thu'] ? a.thu = o['thu'] : nil 
      o['fri'] ? a.fri = o['fri'] : nil 
      o['sat'] ? a.sat = o['sat'] : nil 
      
      a.save!
      r = a.to_json
    else
      msg = "id not specified"
      throw msg
    end
  rescue Exception => e
    r = "{\"error\": #{msg}}"
    raise e
  end
  r
end  

delete '/alarms/:id' do |id|
  msg = ""
  begin
    if id
      a = Alarm.find(id)
      a.destroy!
      r = id
    else
      msg = "id not specified"
      throw msg
    end
  rescue Exception => e
    r = "{\"error\": #{msg}}"
    raise e
  end
  r
end  

