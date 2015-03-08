#!/bin/env ruby
# encoding: utf-8
require_relative 'JubeatBase.rb'

class JubeatRecorder < JubeatBase
	def addDb user, date, title, location, game_center, level, score, rank
		@db = SQLite3::Database.new("score.db")
		if(@db.get_first_value('SELECT COUNT(*) FROM SCORE WHERE DATE=?', date) == 0)
			@db.execute("INSERT INTO SCORE VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
				   user, date, title, location, game_center, level, score, rank)
			return true
		end
		return false
	end

	def run
		flag = true
		["http://p.eagate.573.jp/game/jubeat/prop/p/playdata/history.html",
# "http://p.eagate.573.jp/game/jubeat/prop/p/playdata/history.html?page=2",
# "http://p.eagate.573.jp/game/jubeat/prop/p/playdata/history.html?page=3"
		].each {|url|
			break unless flag
			@agent.get(url)
			@agent.page.search("div.history_container2").each do |div|
				# プレー日時、場所、店舗、曲名、楽曲のランクを取得
				/.*プレー日時：(.*) プレー店舗：(.*) \/ (.*)$/ =~ div.at(".data1_info").inner_text
				date = Regexp.last_match[1].strip
				location = Regexp.last_match[2].strip
				game_center = Regexp.last_match[3].strip
				title = div.at(".result_music > a").inner_text
				case  div.at("ul li.level img")["src"]
				when /dif_0/
					level = NUM_BSC
				when /dif_1/
					level = NUM_ADV
				when /dif_2/
					level = NUM_EXT
				end
				
				# スコアとランクを取得
				/([0-9]+) \/ ([A-Z]+) \/ (.*)/ =~ div.at("ul li.score").inner_text
				score = Regexp.last_match[1]
				rank = Regexp.last_match[3]
				flag = flag && addDb(@id, date, title, location, game_center, level, score, rank)
			end
		}
	end
end

# here we go
JubeatRecorder.new.run
