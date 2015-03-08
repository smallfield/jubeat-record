#!/bin/env ruby
# encoding: utf-8
require_relative 'JubeatBase.rb'

class JubeatSongDataFetcher < JubeatBase
	def addDb id, name, artist, bsc, adv, ext
		if(@db.get_first_value('SELECT COUNT(*) FROM SONGS WHERE ID = ?', id) == 0)
			@db.execute("INSERT INTO songs values (?, ?, ?)", id, name, artist)
			@db.execute("INSERT INTO song_details VALUES (?, ?, ?)", id, NUM_BSC, bsc)
			@db.execute("INSERT INTO song_details VALUES (?, ?, ?)", id, NUM_ADV, adv)
			@db.execute("INSERT INTO song_details VALUES (?, ?, ?)", id, NUM_EXT, ext)
			return true
		end
		false
	end

	# main from here
	def run
		flag = true
		["http://p.eagate.573.jp/game/jubeat/prop/p/information/music_list1.html",
		   "http://p.eagate.573.jp/game/jubeat/prop/p/information/music_list1.html?page=2",
		   "http://p.eagate.573.jp/game/jubeat/prop/p/information/music_list2.html",
		   "http://p.eagate.573.jp/game/jubeat/prop/p/information/music_list2.html?page=2",
		].each {|url|
			break unless flag
			@agent.get(url)
			@agent.page.search("div#music_data > ul > li").each do |li|
				# 画像URLからIDを抜き出す
				/\/id([[:digit:]]+)\.[a-z]{3,4}$/.match(li.search("img.jk").attribute("src").text.strip)
				id     = $~[1]
				name   = li.search("div.name > span").text.strip
				artist = li.search("div.name > text()").text.strip
				bsc    = li.search("div.level span.bsc").text.strip
				adv    = li.search("div.level span.adv").text.strip
				ext    = li.search("div.level span.ext").text.strip
				addDb id, name, artist, bsc, adv, ext
			end

		}
	end
end

# here we go
JubeatSongDataFetcher.new.run
