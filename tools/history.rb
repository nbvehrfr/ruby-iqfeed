require 'optparse'
require 'ostruct'
require 'pp'
require 'date'
require '../lib/history_client'

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

pp options

c = IQ::HistoryClient.new
c.open
c.get_tick_range(options[:symbol], options[:from], options[:to]) do |line|
	puts line.to_s
end

