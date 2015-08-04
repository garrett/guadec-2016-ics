#!/bin/ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'icalendar'
include Icalendar

cal = Calendar.new

page = Nokogiri::HTML(open('https://2015.guadec.org/schedule/'))

dates = page.css('h3').map(&:text)
tables = page.css('table')
headers = page.css('table').first.css('th').map(&:text)

cal.timezone do |t|
  t.tzid = 'UTC'
end

tables.inject(0) do |i, table|
  date = dates[i].split(', ').last.gsub(/(th|st|rd|nd)$/, '')

  table.css('tbody tr').each do |row|
    time = row.css('td').first.text.split(/[^0-9:]+/)

    row.css('td').inject(0) do |j, col|
      if j > 0 && !col.attr('class')[/break/i]
        starttime = DateTime.parse("#{date} 2015 #{time[0]} CEST")
        endtime = DateTime.parse("#{date} 2015 #{time[1]} CEST")
        room = headers[j].to_s.strip
        keynote = col.text[/Keynote/i] ? 'Keynote: ' : ''

        pretitle = col.text
                   .gsub(/Keynote: /i, '')
                   .gsub(/(Nocera) H/, '\\1 – H')
                   .split('–')

        title = (pretitle[1] || pretitle[0]).to_s.strip
        speaker = pretitle[1] ? pretitle[0].to_s.strip : nil
        # puts "#{starttime} - #{endtime}: #{room}: #{title}"
        speakertext = speaker ? " (#{speaker})" : ''

        cal.event do |e|
          e.dtstart = starttime.new_offset(0)
          e.dtend = endtime.new_offset(0)
          e.summary = "#{keynote}#{title.strip}#{speakertext}"
          # e.description = speaker
          e.location = room
        end
      end

      j + 1
    end
  end

  i + 1
end

puts cal.to_ical
