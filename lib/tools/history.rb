require 'optparse'
require 'ostruct'
require 'pp'
require 'date'
require '../lib/history_client'

MONTHS=['F','G','H','J','K','M','N','Q','U','V','X','Z']

class FileObserver
	def initialize(file)
		@file = file
	end
	def update(tick)    
		@file.puts tick.to_csv		
	end
end

def client_proxy(iq_client, options, o)
  iq_client.send(options[:method], options, o)
end

def get_valid_codes(today, months)
  current_month = today.month
  valid_months = months.map{|m| MONTHS.index(m) + 1}.select{|m| m >= current_month}.map{|m| "#{MONTHS[m-1]}#{today.year-2000}"}.slice(0,2)
  valid_months = valid_months + months.slice(0, 2 - valid_months.length).map{|m| m + "#{today.year-2000+1}"} if valid_months.length < 2    
  valid_months
end

options = {}

opts = OptionParser.new do |opts|
  opts.banner = "Usage: history.rb [options]"

  opts.on("-s", "--symbol SYMBOL", "Symbol for history request") do |s|
    options[:symbol] = s 
  end

  opts.on("-f", "--from DATE", "Start date for history request") do |from|
    options[:from] = DateTime.parse(from) #Time.new(d.year, d.month, d.day, 0, 0, 0)
  end

  opts.on("-t", "--to DATE", "End date for history request") do |to|
    options[:to] = DateTime.parse(to) #Time.new(d.year, d.month, d.day, 23, 59, 59)
  end

  opts.on("-o", "--output FILE", "Output file for history data") do |output|
    options[:output] = output
  end

  opts.on("-i", "--input FILE", "Input file with list of future contracts") do |input|
    options[:input] = input
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
  mandatory = [:from, :to]                                         
  missing = mandatory.select{ |param| options[param].nil? }
#TODO fix
  if not missing.empty? || (options[:input].nil? && options[:symbol].nil?)
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
options[:duration] ||= 300 if options[:type] == :ohlc

contracts = {}
if options[:input].nil?  
	contracts[options[:symbol]] = nil
else
	contracts_file = File.open(options[:input])
	contracts_file.each do |line|
		line.chomp!
		f = line.split(';')
		contracts[f[0]] = f[3].split(',')
	end
end
from_date = options[:from]
to_date = options[:to]  
while from_date <= to_date
  contracts.keys.each do |contract|
    codes = []    
    if contracts[contract].nil?
      codes = [contract]      
    else
      codes = get_valid_codes(from_date, contracts[contract]).map{|c| "#{contract}#{c}"}      
    end
    codes.each do |code|
      output_file = File.new(code.gsub("@","")+"_" + ("%04d" % from_date.year) + ("%02d" % from_date.month) + ("%02d" % from_date.day) + ".csv", "w")
      options[:symbol] = code
      options[:from] = Time.new(from_date.year, from_date.month, from_date.day, 0, 0, 0)
      options[:to] = Time.new(from_date.year, from_date.month, from_date.day, 23, 59, 59)
      o = FileObserver.new(output_file)
      iq_client = IQ::HistoryClient.new
      iq_client.open
      client_proxy(iq_client, options, o) 
      begin        
        iq_client.run
      rescue IQ::NoDataError => e
        output_file.close
        File.delete(output_file)
      end      
    end
  end
  from_date = from_date.next  
end

# options[:output] ||= options[:symbol].gsub(/[@\$\^#]/,'') + '.csv'