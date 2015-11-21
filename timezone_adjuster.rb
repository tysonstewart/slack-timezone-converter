# Get a Slack clock emoji from a time object

def slack_clock_emoji_from_time(time)
  hour = time.hour % 12
  hour = 12 if hour == 0
  ":clock#{hour}:"
end

# Normalize times

def normalize(text)
  text.gsub(/([0-9]{1,2})([0-9]{2})( ?([aA]|[pP])[mM])/, '\1:\2\3')
end

class TimezoneAdjuster
	def initialize(current_user:, timezones:, prepended_message:)
		@current_user = current_user
		@timezones = timezones
		@prepended_message = prepended_message
	end
	def get_list_for(users:, data:)
		if data['type'] === 'message' and !data['text'].nil? and data['subtype'].nil? and data['reply_to'].nil? and data['text'].include?("@time") and
			 !data['text'].gsub(/<[^>]+>/, '').match(/[0-9](([hH]([0123456789 ?:,;.]|$))|( ?[aA][mM])|( ?[pP][mM])|(:[0-9]{2}))/).nil?
			
			# Identify time patterns
			begin
				Time.zone = users[data['user']][:tz]
				text = normalize data['text']
				time = Time.zone.parse(text).utc
				puts "[#{Time.now}] Got time #{time}"

				text = []
				i = 0
				@timezones.each do |label, offset|
					i += 1
					localtime = time + offset.to_i.hours
					emoji = slack_clock_emoji_from_time(localtime)
					message = "#{emoji} #{localtime.strftime('%H:%M')} #{label}"
					message += (i % PER_LINE.to_i == 0) ? "\n" : " "
					text << (offset == users[data['user']][:offset] ? "#{message}" : message)
				end

				text << (@prepended_message % time.to_i.to_s)

				return text.join
			rescue
				return nil
			end
		end
	end
end