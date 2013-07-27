#!/usr/bin/env ruby

root = Pathname.new(File.dirname(__FILE__)).parent.parent
$: << root.join('lib').to_s
require 'visage-app/graph'
require 'visage-app/patches'
require 'digest/md5'
require 'active_model'
require 'ostruct'

module Visage
  class Profile
    include ActiveModel::AttributeMethods
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations
    include ActiveModel::Dirty

    # Stub records, for getting the tests to pass
    RECORDS = [
      OpenStruct.new({:anonymous => true,  :id => 'zzz', :name => 'Dan',   :created_at => Time.now - 90}),
      OpenStruct.new({:anonymous => true,  :id => 'aaa', :name => 'Alice', :created_at => Time.now - 10}),
      OpenStruct.new({:anonymous => false, :id => 'yyy', :name => 'Carol', :created_at => Time.now - 80}),
      OpenStruct.new({:anonymous => false, :id => 'bbb', :name => 'Bob',   :created_at => Time.now - 20}),
    ]

    # Class methods
    class << self
      def all(opts={})
        anonymous = opts[:anonymous]
        sort      = opts[:sort]
        order     = opts[:order]
        result    = RECORDS

        result = result.find_all {|r| r.anonymous == anonymous} unless anonymous.nil?
        result = result.sort_by {|r| r.send(sort)} if sort
        result = result.reverse if order == :descending

        result
      end

      def get(id)
        RECORDS.find {|r| r.id == id}
      end
    end

    attr_accessor :attributes

    attribute_method_suffix  '=' # attr_writers
#    attribute_method_suffix  ''  # attr_readers, raises DEPRECATION warnings now
    define_attribute_methods [ :id, :name, :graphs, :anonymous, :created_at]

    validates_presence_of :id, :name, :graphs

    # Instance methods
    def initialize(attributes)
      default_attributes = {
        :anonymous => true
      }
      @attributes = default_attributes.merge(attributes)
    end

    def save
      if new_record?
        self.id         = SecureRandom.hex
        self.created_at = Time.now
      end

      if valid?
        RECORDS << OpenStruct.new(@attributes)
        true
      else
        false
      end
    end

    private
    def new_record?
      !self.id
    end

    # http://stackoverflow.com/questions/7613574/activemodel-fields-not-mapped-to-accessors
    #
    # simulate attribute writers from method_missing
    def attribute=(attr, value)
      @attributes[attr.to_sym] = value
    end

    # simulate attribute readers from method_missing
    def attribute(attr)
      @attributes[attr.to_sym]
    end

    def read_attribute_for_validation(attr)
      @attributes[attr]
    end
  end
end

