require 'spec_helper'
require 'visage-app/models/profile'

describe "Profile" do

  describe "lookup" do
    it "should provide filtering for anonymous profiles" do
      profiles = Profile.all(:anonymous => true)
      profiles.size.should > 0
      profiles.each do |profile|
        profile.anonymous.should be_true
      end
    end

    it "should provide filtering for named profiles" do
      profiles = Profile.all(:anonymous => false)
      profiles.size.should > 0
      profiles.each do |profile|
        profile.anonymous.should be_false
      end
    end

    it "should return all records on unscoped lookups" do
      anonymous = Profile.all(:anonymous => true).size
      named     = Profile.all(:anonymous => false).size
      all       = Profile.all.size

      (anonymous + named).should == all
    end

    it "should allow sorting on name" do
      default_sorting = Profile.all
      custom_sorting  = Profile.all(:sort => :name)

      default_sorting.should_not == custom_sorting
    end

    it "should allow sorting on created_at" do
      default_sorting = Profile.all
      custom_sorting = Profile.all(:sort => :created_at)

      default_sorting.should_not == custom_sorting
    end

    it "should allow ordering of records ascending or descending" do
      ascending  = Profile.all(:sort => :id, :order => :ascending)
      descending = Profile.all(:sort => :id, :order => :descending)

      ascending.reverse.should == descending
    end
  end

  describe "records" do
    it "should be fetchable by id" do
      profile = Profile.get('aaa')
      profile.should_not be_nil
    end

    it "should be saveable" do
      attributes = {
        :anonymous => true,
        :name      => 'An example profile',
        :graphs    => [
          { :plugin => 'memory', :host => 'foo', :start => Time.now.to_i },
          { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
        ]
      }

      profile = Profile.new(attributes)
      profile.save.should be_true
    end

    it "should automatically generate an id for a profile on save" do
      attributes = {
        :anonymous => true,
        :name      => 'Another example profile',
        :graphs => [
          { :plugin => 'memory', :host => 'foo', :start => Time.now.to_i },
          { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
        ]
      }

      profile = Profile.new(attributes)
      profile.save.should be_true
      profile.id.should_not be_nil
    end

    it "should be representable as JSON" do
      profile = Profile.all.first
      profile.to_json.should_not be_nil
    end
  end

  describe "validations and callbacks" do
    it "should confirm presence of name" do
      attributes = {}
      profile = Profile.new(attributes)
      profile.save.should_not be_true
      profile.errors.should_not be_nil
    end

    it "should confirm presence of graphs" do
      attributes = {}
      profile = Profile.new(attributes)
      profile.save.should_not be_true
      profile.errors.should_not be_nil
    end

    it "should automatically set created_at" do
      attributes = {
        :anonymous => true,
        :name      => 'Another example profile',
        :graphs => [
          { :plugin => 'memory', :host => 'foo', :start => Time.now.to_i },
          { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
        ]
      }

      profile = Profile.new(attributes)
      profile.save.should be_true
      profile.created_at.should_not be_nil
    end
  end
end
