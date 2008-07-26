$: << File.join(File.dirname(__FILE__), '..', 'vendor', 'feed_me', 'lib')
require 'rubygems'
require 'open-uri'
require 'dm-core'
require 'feed_me'

module Seinfeld
  class User
    include DataMapper::Resource
    property :id,    Integer, :serial => true
    property :login, String
    property :email, String
    has n, :progressions, :class_name => "Seinfeld::Progression", :order => [:created_at.desc]

    def update_progress
      transaction do
        save if new_record?
        days = scan_for_progress
        unless days.empty?
          existing = progressions(:created_at => days).map { |p| p.created_at }
          (days - existing).each do |day|
            progressions.create(:created_at => day)
          end
        end
      end
    end

    def scan_for_progress
      feed = get_feed
      feed.entries.inject({}) do |selected, entry|
        if entry.title =~ %r{^#{login} committed}
          updated = entry.updated_at
          date    = Time.utc(updated.year, updated.month, updated.day)
          selected.update date => nil
        else
          selected
        end
      end.keys.sort
    end

  private
    def get_feed
      feed = nil
      open("http://github.com/#{login}.atom") { |f| feed = FeedMe.parse(f.read) }
      feed
    end
  end

  class Progression
    include DataMapper::Resource
    property :id,         Integer, :serial => true
    property :created_at, DateTime
    belongs_to :user, :class_name => "Seinfeld::User"
  end
end