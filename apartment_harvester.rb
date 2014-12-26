require 'open-uri'
require 'nokogiri'
require 'erb'
require 'gmail'
require 'active_record'
require 'rubygems'
require 'mechanize'
require 'uri'

gmail_credentials = YAML.load(File.read("#{File.dirname(File.dirname(__FILE__))}/config/gmail_conf.yml"))
USERNAME = gmail_credentials["username"]
PASSWORD = gmail_credentials["password"]
SLEEP_ON_ERROR = 5

@logger = Logger.new('apartment_finder.log')
@logger.info("Fetching records")




# ActiveRecort Setup
ActiveRecord::Base.establish_connection(
:adapter  => 'sqlite3',
:database => 'room_finder.db'
)

ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.tables.include? 'rooms'
    create_table :rooms do |table|
      table.column :href,     :string
    end

    add_index :rooms, :href, :unique => true
  end
end

# Our Room Class
class Room < ActiveRecord::Base
  validates :href, uniqueness: true
end



def parse_email(contact_url)
  retries = 0

  begin
    xml_elems = Nokogiri::HTML(open(contact_url))
    if xml_elems.css('a').select {|link| link['href'].include?("mailto")}.count > 0
      return URI.unescape xml_elems.css('a').select {|link| link['href'].include?("mailto")}.first['href'].split('?').first.gsub('mailto:', '')
    else
      return "no email"
    end

  rescue Exception=>e
    puts "ERROR: #{e}"
    retries += 1
    sleep SLEEP_ON_ERROR
    retry unless retries >= RETRY_COUNT
  end
end

# Construct the contact page url
def construct_contact_url(href)
  base_url = href.slice(/\A.+\.org/)
  listing_id = href.slice(/\d+/)
  contact_url = base_url + "/reply/" + listing_id
  return contact_url
end




def main(max_price)
  url = "http://sfbay.craigslist.org/search/sfc/apa?nh=3&nh=4&nh=5&nh=7&nh=9&nh=11&nh=12&nh=13&nh=14&nh=15&nh=16&nh=10&nh=20&nh=24&nh=17&nh=18&nh=19&nh=21&nh=22&nh=23&nh=164&nh=25&nh=26&nh=27&nh=1&nh=28&nh=29&nh=2&nh=118&nh=114&nh=30&pets_dog=1&minAsk=1000&maxAsk=#{max_price}"

  # Create a Mechanize agent
  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }


  a.get(url) do |page|
    doc = page.parser

    # Parse each link on the page
    links = doc.css("a").map {|link| link["href"]}.select { |link| (link.match(/\/sfc\/apa\/\d+/))? true : false  }.uniq!

    # iterate through each link
    links.sample(1).each do |post_link|
      begin

        # Create an Room check if you've already contacted it using ActiveRecord create
        # unique index will throw an effor if it's already present in the db
        href = "http://sfbay.craigslist.org#{post_link}"
        room = Room.new(:href => href)

        if room.valid?
          contact_url = construct_contact_url(room.href)
          @email_mailto = parse_email(contact_url)
          @logger.info("Emailing using the following email: #{@email_mailto}")

          #Build the text template
          text_template = "email_apartment_template_1.txt.erb"
          @first_name = "Kristen"
          @logger.info("Rendering ERB text template for #{text_template}")
          text_renderer = ERB.new(File.read("#{File.dirname(File.dirname(__FILE__))}/templates/#{text_template}"))
          @text_content = text_renderer.result(binding)


          @logger.info("Login in GMAIL as #{USERNAME} and password = #{PASSWORD}")
          gmail = Gmail.connect(USERNAME, PASSWORD)
          @logger.info("#{gmail}")
          if gmail.logged_in?

            # Began Composing the email
            email = gmail.compose
            email.to = @email_mailto
            email.subject = "Interested in Your Apartment for Rent"
            email.body = @text_content
            @logger.info("Composed the following email: #{email.inspect}")

            # Send the Email
            result = email.deliver!
          else
            @logger.error("Failed to login")
          end

          # Throttle yourself.
          sleep(30)
        else
          @logger.info("Already contacted #{@href}")
        end
      rescue Exception => e
        @logger.error(e)
        @logger.error(e.backtrace)
      end
    end
  end
end

max_price = ARGV[0]
puts max_price
main(max_price)
