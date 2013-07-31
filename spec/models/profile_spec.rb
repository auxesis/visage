require 'spec_helper'
require 'visage-app/models/profile'
require 'tmpdir'

describe "Profile" do

  before(:each) do
    Profile.config_path = Dir.mktmpdir
  end

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

    it "should be fetchable by id" do
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

      profile = Profile.get(profile.id)
      profile.should_not be_nil
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

      keys = profile.as_json.keys
      keys.size.should_not be(1)
      keys.should_not include('profile')
    end
  end

  describe "validations and callbacks" do
    it "should confirm presence of name when not anonymous" do
      # Anonymous profiles should not validate the presence of a name
      attributes = {}
      profile = Profile.new(attributes)
      profile.save.should_not be_true
      profile.errors.keys.should_not include(:name)

      # Named profiles should validate the presence of a name
      attributes = {:anonymous => false}
      profile = Profile.new(attributes)
      profile.save.should_not be_true
      profile.errors.keys.should include(:name)
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

  describe "serialisation" do
    it "should save each profile in a separate file" do
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

      profile.path.should == "#{Profile.config_path}/#{profile.id}.yaml"
      File.exists?(profile.path).should be_true

      loaded_profile = Profile.get(profile.id)
      loaded_profile.should == profile
    end

    it "should read a profile from a file" do
      attributes = {
        :anonymous => true,
        :name      => 'externally created profile',
        :graphs => [
          { :plugin => 'memory', :host => 'foo', :start => Time.now.to_i },
          { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
        ]
      }

      # Save the file without using the Profile class
      filename = File.join(Profile.config_path, "#{Time.now.to_i}.yaml")
      File.open(filename, 'w') {|f| f << attributes.to_yaml}

      # Read the profile using the Profile class
      id = File.basename(filename, '.yaml')
      profile = Profile.get(id)
      profile.name.should == 'externally created profile'
      profile.created_at.should be_nil
    end

    it "should return nil if the profile doesn't exist" do
      profile = Profile.get(Time.now.to_i)
      profile.should be_nil
    end
  end
end
