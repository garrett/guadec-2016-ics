#!/bin/ruby

require 'bundler'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'icalendar'
include Icalendar

cal = Calendar.new

xml = Nokogiri::HTML(open('https://static.gnome.org/guadec-2016/schedule.xml'))
xml.encoding = 'utf-8'

cal.timezone do |t|
  t.tzid = 'UTC'
end

xml.css('event').each do |ev|
  duration = ev.css('duration').text.split(':').map(&:to_i)
  time_start = Time.parse(ev.css('date').text)
  time_end = time_start + (duration[0] * 60 * 60) + (duration[1] * 60)
  title = ev.css('title').text.strip
  speakertext = ev.css('person').map(&:text).join(', ')
  keynote = ev.text.downcase.match('keynote') ? 'Keynote: ' : ''
  sep = speakertext.to_s.empty? ? '' : ' — '

  cal.event do |e|
    e.dtstart = time_start
    e.dtend = time_end
    e.summary = "#{keynote}#{title}#{sep}#{speakertext}"
    e.description = ev.css('abstract').text.strip
    e.location = ev.css('room').text.strip
  end
end

puts cal.to_ical
