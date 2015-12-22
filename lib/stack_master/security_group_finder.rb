module StackMaster
  class SecurityGroupFinder
    SecurityGroupNotFound = Class.new(StandardError)
    MultipleSecurityGroupsFound = Class.new(StandardError)

    def initialize(region)
      @resource = Aws::EC2::Resource.new(region: region)
    end

    def find(reference)
      raise ArgumentError, 'Security group references must be non-empty strings' unless reference.is_a?(String) && !reference.empty?

      # Try with a group-name first
      groups = @resource.security_groups(group_name_filter(reference))

      # If not found, try with a Name tag
      groups = @resource.security_groups(tag_name_filter(reference)) unless groups.any?

      raise SecurityGroupNotFound, "No security group with name #{reference} found" unless groups.any?
      raise MultipleSecurityGroupsFound, "More than one security group with name #{reference} found" if groups.count > 1

      groups.first.id
    end

    def group_name_filter(reference)
      {
        filters: [
          {
            name: 'group-name',
            values: [reference],
          },
        ],
      }
    end

    def tag_name_filter(reference)
      {
        filters: [
          {
            name: 'tag-key',
            values: ['Name'],
          },
          {
            name: 'tag-value',
            values: [reference],
          },
        ],
      }
    end
  end
end
