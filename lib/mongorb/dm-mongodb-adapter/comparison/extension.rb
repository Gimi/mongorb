# encoding: utf-8

module DataMapper
  class Query
    module Conditions

      core_comparison_slugs = Comparison.slugs

      class NotComparison < EqualToComparison
        # TODO this smells bad, something has to be done in Comparison and AbstractComparison,
        # or I have to copy the methods from EqualToComparison.
        AbstractComparison.descendants << self

        slug :ne

        def matches?(record) !super end

        # @api private
        def to_mongo_hash
          {subject.name => {"$ne" => value}}
        end

        def comparator_string; '$ne' end
      end

      # TODO Range
      class ExclusionComparison < InclusionComparison
        AbstractComparison.descendants << self

        slug :nin

        def matches?(record) !super end

        def comparator_string; '$nin' end
      end

      class ModuloComparison < AbstractComparison
        slug :mod

        def matches?(record)
          record_value = record_value record
          expected     = self.expected

          !record_value.nil? and !expected.nil? and record_value % expected[0] == expected[1]
        end

        def valid?
          loaded_value.is_a?(Array) and
          loaded_value.size == 2 and
          loaded_value.all? { |e| e.is_a?(Integer) } and
          loaded_value[0] > loaded_value[1]
        end

        def comparator_string; '$mod' end
      end

      class AllComparison < InclusionComparison
        AbstractComparison.descendants << self

        slug :all

        def comparator_string; '$all' end

        private

        # @api private
        def matche_property?(record)
          record_value = record_value record
          expected     = self.expected

          !record_value.nil? and
          !expected.nil? and
          record_value.respond_to?(:include?) ? expected.all? { |e| record_value.include? e } : expected.include?(record_value)
        end
      end

      # TODO
      # Should this slug rename to some other names? Since Symbol#size is defined in Ruby 1.9.2. Hmmm...
      class SizeComparison < AbstractComparison
        include RelationshipHandler

        slug :size

        def valid?
          # TODO record_valud shoud be enumerable
          loaded_value.is_a?(Integer)
        end

        def comparator_string; '$size' end

        private

        # @api private
        def typecast(value)
          value
        end

        # @api private
        def match_property?(record)
          record_value = record_value record

          !record_value.nil and
          record_value.respond_to(:size) and
          expected === record_value.size
        end
      end

      class ExistsComparison < AbstractComparison
        slug :exists

        def valid?
          [true, false].any? { |b| b === loaded_value }
        end

        def comparator_string; '$exists' end

        def matches?(record)
          expected === !record_value(record).nil?
        end

        private

        # @api private
        def typecast(value)
          case value
          when 0
            false
          else
            !!value
          end
        end
      end

      class TypeComparison < AbstractComparison
        @@types = {
          'Double' => 1,
          'String' => 2,
          'Object' => 3,
          'Array'  => 4,
          'Binary' => 5,
          'ObjectId' => 7,
          'Boolean'  => 8,
          'Date' => 9,
          'Null' => 10,
          'Regexp' => 11,
          'JavaScript' => 13,
          'Symbol' => 14,
          'ScopedJavaScript' => 15,
          'Integer32' => 16,
          'Time' => 17,
          'Integer64' => 18,
          'Minkey' => 255,
          'Maxkey' => 127
        }

        slug :type

        def matches?(record)
        end

        def valid?
          loaded_value.is_a?(Integer)
        end

        private

        # @api private
        def typecast(value)
        end
      end

      class ElementMatchComparison < AbstractComparison
        slug :elemMatch

        private

        # @api private
        def typecast(value)
        end
      end

      # since dm load its core_ext/symbol automatically, we have to do this by ourselves.
      (Comparison.slugs - core_comparison_slugs).each do |sym|
        Symbol.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{sym}
              #{"warn \"explicit use of '#{sym}' operator is deprecated (#{caller[0]})\"" if sym == :eql || sym == :in}
              DataMapper::Query::Operator.new(self, #{sym.inspect})
            end
          RUBY
      end

    end # Conditions
  end # Query
end # DataMapper
