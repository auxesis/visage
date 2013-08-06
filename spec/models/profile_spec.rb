require 'spec_helper'
require 'visage-app/models/profile'
require 'tmpdir'

describe "Profile" do

  before(:each) do
    # Create a temporary profile data directory
    Profile.config_path = Dir.mktmpdir

    # Create stub graphs
    graphs = [
      { :plugin => 'memory', :host => 'foo', :start => Time.now.to_i },
      { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
    ]
    # Create stub profiles
    [
      {:anonymous => true,  :id => 'zzz', :created_at => Time.now - 90, :graphs => graphs},
      {:anonymous => true,  :id => 'aaa', :created_at => Time.now - 10, :graphs => graphs},
      {:anonymous => false, :id => 'yyy', :name => 'Carol', :created_at => Time.now - 80, :graphs => graphs},
      {:anonymous => false, :id => 'bbb', :name => 'Bob',   :created_at => Time.now - 20, :graphs => graphs},
    ].each do |attributes|
      filename = File.join(Profile.config_path, "#{attributes[:id]}.yaml")
      File.open(filename, 'w') {|f| f << attributes.to_yaml}
    end
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
      custom_sorting  = Profile.all(:sort => :created_at)

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

    it "should convert boolean fields on save" do
      attributes = {
        :name      => 'An example profile',
        :graphs    => [
          { :plugin => 'memory', :host => 'foo', :start => Time.now.to_i },
          { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
        ]
      }

      profile = Profile.new(attributes.merge({:anonymous => 'true'}))
      profile.save.should be_true
      profile.anonymous.class.should be(TrueClass)

      profile = Profile.new(attributes.merge({:anonymous => 'false'}))
      profile.save.should be_true
      profile.anonymous.class.should be(FalseClass)
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

    it "should be updateable" do
      attributes = {
        :name   => 'Foo bar baz',
        :graphs => [
          { :plugin => 'memory', :host => 'bar', :start => Time.now.to_i },
        ]
      }

      profile = Profile.all.first
      id      = profile.id

      profile.update_attributes(attributes).should be_true

      profile = Profile.get(id)
      profile.name.should == attributes[:name]
      profile.graphs.should == attributes[:graphs]
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
