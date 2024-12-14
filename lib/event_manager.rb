require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers (number)
  number = number.gsub(/\D/, '')

  if number.length == 10
    number = number
  elsif number.length == 11 && number[0] != 1
    number = number[1..-1]
  else
    number = "bad"
  end
end

def clean_time(time)
  DateTime.strptime(time, '%m/%d/%y %k:%M')
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = Hash.new 0
days = Hash.new 0

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  number = clean_phone_numbers(row[:homephone])

  time = clean_time(row[:regdate])

  hours[time.hour] += 1 
  days[time.wday] += 1

  save_thank_you_letter(id, form_letter) 

end

time_target = hours.max_by{|k,v| v}[0]
day_target = days.max_by{|k, v| v}[0]

puts "#{time_target} #{day_target}"