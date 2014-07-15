SF Room Finder
=====================

I was tired of having to email all craigslist room-shared ads manually, so I automated it. Happy to say I found a room (ok, chicken cage) for $800/month that way.

### Requirements

A gmail account and ideally, a raspberry pi or something to run it on continuously.

### Installing

1. Run `bundle install`
2. Under templates, write your own custom message. Remember to mention some interesting facts about yourself to ensure you get a reply.
3. Create a gmail_conf.yml file and enter your email/password as modeled in the gmail_conf.yml.example.

### Running

`$ ruby shared_room_harvester.rb <your_max_price>`

Your max price is an int. Example: `ruby shared_room_harvester.rb 1000`


### Cron Time

This script is a perfect use case for a raspberry pi. 

First setup your rvm enviroment inside of RVM: `rvm cron setup`

Then setup a cron for it to run every minute:

`* * * * * ruby path_to_room-finder/shared_room_harvester.rb`

### Contributing

Issues + Pull Request.
