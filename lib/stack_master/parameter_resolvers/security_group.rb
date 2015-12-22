module StackMaster
  module ParameterResolvers
    class SecurityGroup
      def initialize(config, stack_definition)
        @config = config
        @stack_definition = stack_definition
      end

      def resolve(value)
        sg_list = Array(value).map do |sg_name|
          security_group_finder.find(sg_name)
        end

        value.is_a?(Array) ? sg_list : sg_list.first
      end

      private

      def security_group_finder
        StackMaster::SecurityGroupFinder.new(@stack_definition.region)
      end
    end
  end
end
