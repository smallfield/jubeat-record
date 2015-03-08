#!/bin/env ruby
# encoding: utf-8
require "rubygems"
require "mechanize"
require "sqlite3"
require 'digest/md5'
require 'yaml'

class Mechanize
	attr_accessor :save_to
	alias :__get_orig :get
	def get(uri, parameters = [], referer = nil, headers = {})
		page = __get_orig uri, parameters, referer, headers
		if @save_to
			cookie_jar.save_as @save_to
		end
		page
	end
	private :__get_orig
end

class JubeatBase
	attr_accessor :agent, :cookie

	NUM_BSC = 1
	NUM_ADV = 2
	NUM_EXT = 3

	def initialize
		@conf             = YAML.load_file(File.expand_path("../conf.yml", __FILE__))
		@id               = @conf["id"]
		@pass             = @conf["password"]
		@cookie           = "#{File.expand_path("../cookies/", __FILE__)}/#{Digest::MD5.hexdigest(@id)}.yml"
		@agent            = Mechanize.new
		@agent.save_to    = @cookie
		@agent.user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7'
		initDb
		login @id, @pass
		ObjectSpace.define_finalizer(self, JubeatBase.finalize(self))
	end

	def JubeatBase.finalize obj
		lambda{
			print "hoge"
			obj.agent.cookie_jar.save_as(obj.cookie)
		}
	end

	def initDb
		@db = SQLite3::Database.new("score.db")
		init_sql = <<SQL
CREATE TABLE IF NOT EXISTS score (
user varchar(255),
date varchar(255),
title varchar(255),
location varchar(255),
game_center varchar(255),
level INTEGER,
score integer,
rank varchar(255));

CREATE TABLE IF NOT EXISTS songs (
id varchar(255),
name varchar(255),
artist varchar(255));

CREATE TABLE IF NOT EXISTS song_details  (
id varchar(255),
difficalty INTEGER,
level INTEGER);
SQL
		@db.execute_batch(init_sql)
	end

	def login(id, pass)
		unless FileTest.exists?(@cookie) && @agent.cookie_jar.load(@cookie) && @agent.cookies.first != nil && !@agent.cookies.first.expired?
			@agent.get('https://p.eagate.573.jp/gate/p/login.html')
			@agent.page.form_with(:action => '/gate/p/login.html'){|form|
				form.ignore_encoding_error = true
				form.field_with(:id => 'KID').value = id
				form.field_with(:id => 'pass').value = pass
				form.click_button
			}
		end
	end
end

