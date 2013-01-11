require 'rolify/adapters/base'
require 'rolify/utils'

module Rolify
  module Adapter   
    class RoleAdapter < RoleAdapterBase
      def where(relation, *args)
        conditions, values = build_conditions(relation, args)
        relation.where(conditions, *values)
      end

      def find_or_create_by(role_name, resource_type = nil, resource_id = nil, relations = [])
        relations_hash = convert_relations_to_hash(relations)
        relations_hash[:name] = role_name
        relations_hash[:resource_type] = resource_type
        relations_hash[:resource_id] = resource_id
        role_class.where(relations_hash).first_or_create(relations_hash)
      end

      def add(relation, role)
        relation.role_ids |= [role.id]
      end

      def remove(relation, role_name, resource = nil, relations = [])
        cond = { :name => role_name }
        cond[:resource_type] = (resource.is_a?(Class) ? resource.to_s : resource.class.name) if resource
        cond[:resource_id] = resource.id if resource && !resource.is_a?(Class)
        cond.merge!(convert_relations_to_hash(relations))

        roles = relation.roles.where(cond)
        if roles
          relation.roles.delete(roles)
          roles.each do |role| 
            role.destroy if role.send(ActiveSupport::Inflector.demodulize(user_class).tableize.to_sym).empty? 
          end
        end
        roles
      end

      def exists?(relation, column)
        relation.where("#{column} IS NOT NULL")
      end

      #TODO:what needs to be done here?
      def scope(relation, conditions, relations = [])
        query = relation.scoped
        query = query.joins(:roles)
        query = where(query, conditions)
        query
      end

      private

      def build_conditions(relation, args)
        conditions = []
        values = []
        args.each do |arg|
          if arg.is_a? Hash
            arg[:relations] = [] if !arg.has_key?(:relations)
            a, v = build_query(arg[:name], arg[:resource], arg[:relations])
          elsif arg.is_a?(String) || arg.is_a?(Symbol)
            a, v = build_query(arg.to_s)
          else
            raise ArgumentError, "Invalid argument type: only hash or string or a symbol allowed"
          end
          conditions << a
          values += v
        end
        conditions = conditions.join(' OR ')

        if args.is_a? Hash and !args(:relations).empty?
          puts conditions
          puts values
        end
        [ conditions, values ]
      end


      def build_query(role, resource = nil, relations = [])
        #build relations text with AND prefix
        rel_sql, rel_vals = convert_relations_to_sql(relations) if !relations.empty?

        values = []
        query = ""

        #check for any resource by name and be relation if specified
        if resource == :any
          query << "(#{role_table}.name = ?)"
          values << role
          if !relations.empty?
            query << rel_sql
            values += rel_vals
          end

        #resource not specified
        elsif resource.nil?
            query << "((#{role_table}.name = ?) AND (#{role_table}.resource_type IS NULL) AND (#{role_table}.resource_id IS NULL))"
            values = [ role]
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end

        #resource is specified
        elsif resource
          #resource is a class
          if resource.is_a? Class
            query << " ((#{role_table}.name = ?) AND (#{role_table}.resource_type = ?) AND (#{role_table}.resource_id IS NULL)"
            values << role << (resource.is_a?(Class) ? resource.to_s : resource.class.name)
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"

            query << " OR ((#{role_table}.name = ?) AND (#{role_table}.resource_type IS NULL)"
            values << role
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"

          #resource is an instance
          else
            query << " ((#{role_table}.name = ?) AND (#{role_table}.resource_type = ?) AND (#{role_table}.resource_id = ?)"
            values << role << resource.class.name << resource.id
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"

            query << " OR ((#{role_table}.name = ?) AND (#{role_table}.resource_type = ?) AND (#{role_table}.resource_id IS NULL)"
            values << role << resource.class.name
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"

            query << " OR ((#{role_table}.name = ?) AND (#{role_table}.resource_type IS NULL) AND (#{role_table}.resource_id IS NULL)"
            values << role
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"

          end
        end
        [ query, values ]
      end


=begin
      def build_query(role, resource = nil, relations = [])
        #build relations text with AND prefix
        rel_sql, rel_vals = convert_relations_to_sql(relations) if !relations.empty?
        puts 'stuff!' + rel_sql.to_s + rel_vals.to_s if !relations.empty?
        values = []
        query = ""
        if resource == :any
          query = "(#{role_table}.name = ?)"
          values << role
          if !relations.empty?
            query << rel_sql
            values += rel_vals
          end
        else
          if resource.nil?
            query = "((#{role_table}.name = ?) AND (#{role_table}.resource_type IS NULL) AND (#{role_table}.resource_id IS NULL)"
            values = [ role ]
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"
          end

          if resource
            query.insert(0, "(")
            query += " ((#{role_table}.name = ?) AND (#{role_table}.resource_type = ?) AND (#{role_table}.resource_id IS NULL)"
            values << role << (resource.is_a?(Class) ? resource.to_s : resource.class.name)
            if !relations.empty?
              query << rel_sql
              values += rel_vals
            end
            query << ")"

            if !resource.is_a? Class
              query += " OR ((#{role_table}.name = ?) AND (#{role_table}.resource_type = ?) AND (#{role_table}.resource_id = ?)"
              values << role << resource.class.name << resource.id
              if !relations.empty?
                query << rel_sql
                values += rel_vals
              end
              query << ")"
            end
            query << ")"
          end
        end
        puts "\n\nqstart:  ", query
        puts "values:", values.to_s
        [ query, values ]
      end
=end

      def convert_relations_to_hash(relations)
        temp = {}
        relations = [relations] if !relations.is_a?(Array)

        relations.each do |relation|
          temp[relation.class.name.downcase + "_id"] = relation.id
        end
        temp
      end

      def convert_relations_to_sql(relations)
        sql = ""
        values = []
        relations.each_pair do |k,v|
          if v.nil?
            sql += " AND (#{role_table}.#{k} IS NULL)"
          else
            sql += " AND (#{role_table}.#{k} = ?)"
            values << v
          end
        end
        [sql, values]
      end

    end
  end
end