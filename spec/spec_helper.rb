require 'rubygems'
require "bundler/setup"

require 'rolify'
require 'rolify/matchers'
require 'ammeter/init'

ENV['ADAPTER'] ||= 'active_record'

load File.dirname(__FILE__) + "/support/adapters/#{ENV['ADAPTER']}.rb"
load File.dirname(__FILE__) + '/support/data.rb'

def reset_defaults
  Rolify.use_defaults
  Rolify.use_mongoid if ENV['ADAPTER'] == "mongoid"
end

#added third argument: a hash of additional relations to throw into the SQL
#TODO: This can be refactored without the if relations.empty? else
def provision_user(user, roles, relations = {})
  roles.each do |role|
    if relations.empty?
      if role.is_a? Array
        user.add_role *role
      else
        user.add_role role
      end
    else
      if role.is_a? Array
        user.add_role *role, relations
      else
        user.add_role role, relations
      end
    end
  end
  user
end