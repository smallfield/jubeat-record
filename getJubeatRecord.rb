#!/bin/env ruby
# -*- encoding: utf-8 -*-
require "rubygems"
require "mechanize"
require "sqlite3"
require 'digest/md5'
require 'yaml'

def addDb date, title, location, game_center, level, score, rank
	db=SQLite3::Database.new("score.db")
	if(db.get_first_value('select count(*) from score where date=?', date) == 0)
		db.execute("insert into score values (?, ?, ?, ?, ?, ?, ?)", date, 
			title, location, game_center, level, score, rank)
		return true
	end
	return false
end

# main from here
agent = Mechanize.new
agent.user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7'

conf=YAML.load_file(File.expand_path('../conf.yml', __FILE__))
id = conf["id"]
pass = conf["password"]

digest = Digest::MD5.hexdigest(id)
	unless FileTest.exists?('./'+digest+'.yml') && agent.cookie_jar.load('./'+digest+'.yml') && agent.cookies[0] != nil && !agent.cookies[0].expired?
	agent.get('https://p.eagate.573.jp/gate/p/login.html')
	agent.page.form_with(:action => '/gate/p/login.html'){|form|
		form.ignore_encoding_error = true
			form.field_with(:id => 'KID').value = id
			form.field_with(:id => 'pass').value = pass
			form.click_button
	}
end

flag = true
["http://p.eagate.573.jp/game/jubeat/prop/p/playdata/history.html",
# "http://p.eagate.573.jp/game/jubeat/prop/p/playdata/history.html?page=2",
# "http://p.eagate.573.jp/game/jubeat/prop/p/playdata/history.html?page=3"
].each {|url|
	break unless flag
		agent.get(url)
		agent.page.search("div.history_container2").each do |div|
		/.*プレー日時：(.*) プレー店舗：(.*) \/ (.*)$/ =~ div.at(".data1_info").inner_text
		date = Regexp.last_match[1].strip
		location = Regexp.last_match[2].strip
		game_center = Regexp.last_match[3].strip
		title = div.at(".result_music > a").inner_text
		case  div.at("ul li.level img")["src"]
		when /dif_0/
		level = 1
		when /dif_1/
		level = 2
		when /dif_2/
		level = 3
		end
		/([0-9]+) \/ ([A-Z]+) \/ (.*)/ =~ div.at("ul li.score").inner_text
		score = Regexp.last_match[1]
		rank = Regexp.last_match[3]
		flag = flag && addDb( date, title, location, game_center, level, score, rank)
		end
}

# save cookie for next time.
agent.cookie_jar.save_as('./' + digest + '.yml')
