require 'optparse'
require 'ostruct'
require 'pp'
require 'date'
require '../lib/history_client'

def client_proxy(iq_client, options, &block)
  iq_client.send(options[:method], options) do |line|
    block.call line
  end
end

options = {}

opts = OptionParser.new do |opts|
  opts.banner = "Usage: history.rb [options]"

  opts.on("-s", "--symbol SYMBOL", "Symbol for history request") do |s|
    options[:symbol] = s 
  end

  opts.on("-f", "--from DATE", "Start date for history request") do |from|
    d = DateTime.parse(from)
    options[:from] = Time.new(d.year, d.month, d.day, d.hour, d.min, d.sec)
  end

  opts.on("-t", "--to DATE", "End date for history request") do |to|
    d = DateTime.parse(to)
    options[:to] = Time.new(d.year, d.month, d.day, d.hour, d.min, d.sec)
  end

  opts.on("-o", "--output FILE", "Output file for history data") do |output|
    options[:output] = output
  end

  opts.on("-t", "--type [TYPE]", [:tick, :ohlc, :dwm], "Select data type (tick, ohlc, dwm)") do |type|    
    if type == :ohlc
      options[:method] = :get_ohlc_range 
    elsif type == :dwm
      options[:method] = :get_daily_range
    else
      
    end
  end

  opts.on("-d", "--duration [SECONDS]", "Candle duration in seconds for OHLC type") do |duration|
    options[:duration] = duration
  end
end

begin
  opts.parse!
  mandatory = [:symbol, :from, :to]                                         
  missing = mandatory.select{ |param| options[param].nil? }
  if not missing.empty?                                            
    puts "Missing options: #{missing.join(', ')}"                  
    puts opts
    exit                                                           
  end                                                              
rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
  puts $!.to_s
  puts optparse                                                          
  exit                                                                   
end 

options[:method] ||= :get_tick_range 
# create default output file name
options[:output] ||= options[:symbol].gsub(/[@\$\^#]/,'') + '.csv'
# default duration for ohlc is 5m
options[:duration] ||= 300 if options[:type] == :ohlc

output_file = File.new(options[:output], "w")
iq_client = IQ::HistoryClient.new
iq_client.open

client_proxy(iq_client, options) do |tick|
	output_file.puts tick.to_csv
end
output_file.close

