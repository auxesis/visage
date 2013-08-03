#!/usr/bin/env ruby

root = Pathname.new(File.dirname(__FILE__)).parent.parent
$: << root.join('lib').to_s
require 'visage-app/graph'
require 'visage-app/patches'
require 'digest/md5'
require 'active_model'
require 'active_support/core_ext/file/atomic'
require 'active_support/core_ext/string/conversions'

class Profile
  include ActiveModel::AttributeMethods
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations
  include ActiveModel::Dirty

  # Don't emit a single root node named after the object type with all the
  # attributes under that - make the JSON representation of the profile just
  # the attributes.
  #
  # http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html#method-i-as_json
  #
  self.include_root_in_json = false

  # Class methods
  class << self
    # Retrieve previously saved profiles.
    #
    # Provides filters for common tasks, such as:
    #
    #   - Returning anonymous or named profiles
    #   - Sorting by a particular key
    #   - Ordering the results
    #
    def all(opts={})
      sort      = opts[:sort]
      order     = opts[:order]
      # Anonymous profiles don't have names, so if we see the sort key is the
      # profile name, we automatically filter out anonymous profiles.
      anonymous = sort == :name ? false : opts[:anonymous]

      # Load up all profiles
      result = Dir.glob(File.join(self.config_path, '*.yaml'))
      result = result.map {|r| self.get(File.basename(r, '.yaml'))}

      # Filter profiles based on options
      result = result.find_all {|r| r.anonymous == anonymous} unless anonymous.nil?
      result = result.sort_by {|r| r.send(sort)} if sort
      result = result.reverse if order == :descending

      result
    end

    def get(id)
      path = File.join(self.config_path, "#{id}.yaml")
      if File.exists?(path)
        contents   = File.open(path, 'r')
        attributes = YAML::load(contents)
        self.new(attributes)
      else
        nil
      end
    end

    def config_path
      # FIXME(auxesis): look at not doing this lookup + mkdir every time
      @config_path = ENV['CONFIG_PATH']
      @config_path ||= File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'config'))
      FileUtils.mkdir_p(@config_path)

      @config_path
    end

    def config_path=(path)
      @config_path = path
    end

  end

  attr_accessor :attributes

  attribute_method_suffix  '=' # attr_writers
  define_attribute_methods [ :id, :name, :graphs, :anonymous, :created_at, :timeframe, :tags ]

  validates_presence_of :id, :graphs
  validate :name_validations

  # Instance methods
  def initialize(attributes)
    default_attributes = {
      :anonymous => true
    }
    @attributes = default_attributes.merge(attributes)
  end

  # Persist the Profile record.
  def save
    if new_record?
      self.id         = SecureRandom.hex
      self.created_at = Time.now
    else
      # created_at in submitted JSON is converted to a String. Convert to Time.
      if @attributes[:created_at].class == String
        @attributes[:created_at] = @attributes[:created_at].to_time(:local)
      end
    end

    if valid?
      File.atomic_write(self.path) do |file|
        file.write(@attributes.to_yaml)
      end
      true
    else
      false
    end
  end

  def update_attributes(attributes)
    @attributes.merge!(attributes)
    save
  end

  def path
    File.join(self.class.config_path, "#{self.id}.yaml")
  end

  def ==(other)
    self.attributes == other.attributes
  end

  private
  # Determine if the record we are operating on is newly created.
  #
  # Useful for adding additional data to records when they're being created.
  def new_record?
    !self.id
  end

  def name_validations
    self.errors.add 'name', "can't be blank" if not anonymous and name.blank?
  end

  # http://stackoverflow.com/questions/7613574/activemodel-fields-not-mapped-to-accessors
  #
  # Simulate attribute writers from method_missing
  def attribute=(attr, value)
    @attributes[attr.to_sym] = value
  end

  # Simulate attribute readers from method_missing
  def attribute(attr)
    @attributes[attr.to_sym]
  end

  # Used by ActiveModel to lookup attributes during validations.
  def read_attribute_for_validation(attr)
    @attributes[attr]
  end
end
