require "rolify/finders"

module Rolify
  module Role
    extend Utils
    
    def self.included(base)
      base.extend Finders
    end
          
    def add_role(role_name, resource = nil, relations = [])
      #allow one object or an array of objects to be passed in
      relations = [relations] if !relations.is_a?(Array)

      role = self.class.adapter.find_or_create_by(role_name.to_s,
                                                  (resource.is_a?(Class) ? resource.to_s : resource.class.name if resource), 
                                                  (resource.id if resource && !resource.is_a?(Class)),
                                                  relations)

      #TODO: What do I need to do to make the dynamic methods work?
      if !roles.include?(role)
        self.class.define_dynamic_method(role_name, resource) if Rolify.dynamic_shortcuts
        self.class.adapter.add(self, role)
      end
      role
    end
    alias_method :grant, :add_role
    deprecate :has_role, :add_role

    def has_role?(role_name, resource = nil, relations = [])
      relations = convert_relations_to_hash(relations)

      #if relations are still empty then set relation id's to nil
      relations = fill_relations_with_nil() if relations.empty?

      self.class.adapter.where(self.roles, {:name => role_name, :resource => resource, :relations => relations}).present?
    end

    def has_all_roles?(*args)
      args.each do |arg|
        if arg.is_a? Hash
          arg[:relations] = [] if !arg.has_key? :relations

          return false if !self.has_role?(arg[:name], arg[:resource], arg[:relations])
        elsif arg.is_a?(String) || arg.is_a?(Symbol)
          return false if !self.has_role?(arg)
        else
          raise ArgumentError, "Invalid argument type: only hash or string or symbol allowed"
        end
      end
      true
    end

    #TODO: do I need to do anything to this method to make it work?
    def has_any_role?(*args)
      self.class.adapter.where(self.roles, *args).size > 0
    end
    
    def only_has_role?(role_name, resource = nil, relations = [])
      return self.has_role?(role_name,resource,relations) && self.roles.count == 1
    end

    def remove_role(role_name, resource = nil, relations = [])
      self.class.adapter.remove(self, role_name, resource, relations)
    end
    
    alias_method :revoke, :remove_role
    deprecate :has_no_role, :remove_role

    def roles_name
      self.roles.select(:name).map { |r| r.name }
    end

    def method_missing(method, *args, &block)
      if method.to_s.match(/^is_(\w+)_of[?]$/) || method.to_s.match(/^is_(\w+)[?]$/)
        if self.class.role_class.where(:name => $1).count > 0
          resource = args.first
          self.class.define_dynamic_method $1, resource
          return has_role?("#{$1}", resource)
        end
      end unless !Rolify.dynamic_shortcuts
      super
    end

    def respond_to?(method, include_private = false)
      if Rolify.dynamic_shortcuts && (method.to_s.match(/^is_(\w+)_of[?]$/) || method.to_s.match(/^is_(\w+)[?]$/))
        query = self.class.role_class.where(:name => $1)
        query = self.class.adapter.exists?(query, :resource_type) if method.to_s.match(/^is_(\w+)_of[?]$/)
        return true if query.count > 0
        false
      else
        super
      end
    end

    #TODO: DON'T DUPLICATE THIS - see role_adapter.rb
    def convert_relations_to_hash(relations)
      temp = {}
      relations = [relations] if !relations.is_a?(Array)

      relations.each do |relation|
        temp[relation.class.name.downcase + "_id"] = relation.id
      end
      temp
    end

    def fill_relations_with_nil()
      temp = {}
      Rolify.relations.each do |rel|
        temp[(rel.downcase + '_id').to_sym] = nil
      end
      return temp
    end
  end
end