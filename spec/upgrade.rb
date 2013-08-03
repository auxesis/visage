require 'spec_helper'
require 'visage-app/models/profile'
require 'visage-app/upgrade'
require 'tmpdir'

describe "Upgrade" do

  before(:each) do
    # Create a temporary profile data directory
    Profile.config_path = Dir.mktmpdir
  end

  it "should indicate if there are upgrades to apply" do
    # Move a v2 profile.yaml in place
    source      = File.join(File.dirname(__FILE__), 'data', 'profiles.yaml.2')
    destination = File.join(Profile.config_path, 'profiles.yaml')
    FileUtils.cp(source, destination)

    # Test
    Visage::Upgrade.pending?.should be_true
  end

  it "should run upgrades idempotently" do
    # Move a v2 profile.yaml in place
    source      = File.join(File.dirname(__FILE__), 'data', 'profiles.yaml.2')
    destination = File.join(Profile.config_path, 'profiles.yaml')
    FileUtils.cp(source, destination)

    # Run the upgrade
    upgrades = Visage::Upgrade.run
    upgrades.size.should > 0

    # Second invocation of upgrade should run nothing
    upgrades = Visage::Upgrade.run
    upgrades.size.should == 0
  end

end
