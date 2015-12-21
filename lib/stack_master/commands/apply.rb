module StackMaster
  module Commands
    class Apply
      include Command
      include Commander::UI
      include StackMaster::Prompter

      def initialize(config, stack_definition, options = {})
        @config = config
        @s3_config = config.stack_defaults['s3']
        @stack_definition = stack_definition
        @from_time = Time.now
        @updating = false
      end

      def perform
        diff_stacks
        unless ask?("Continue and apply the stack (y/n)? ")
          StackMaster.stdout.puts "Stack update aborted"
          return
        end
        begin
          return if stack_too_big
          upload_files if use_s3?
          create_or_update_stack
          tail_stack_events
        rescue StackMaster::CtrlC
          cancel
        end
      end

      private

      def cf
        @cf ||= StackMaster.cloud_formation_driver
      end

      def s3
        @s3 ||= StackMaster.s3_driver
      end

      def stack
        @stack ||= Stack.find(@stack_definition.region, @stack_definition.stack_name)
      end

      def proposed_stack
        @proposed_stack ||= Stack.generate(@stack_definition, @config)
      end

      def stack_exists?
        !stack.nil?
      end

      def use_s3?
        @s3_config
      end

      def diff_stacks
        StackDiffer.new(proposed_stack, stack).output_diff
      end

      def cancel
        if @updating
          if ask?("Cancel stack update?")
            StackMaster.stdout.puts "Attempting to cancel stack update"
            cf.cancel_update_stack({stack_name: @stack_definition.stack_name})
            tail_stack_events
          end
        end
      end

      def create_or_update_stack
        if stack_exists?
          update_stack
        else
          create_stack
        end
      end

      def stack_too_big
        if proposed_stack.too_big?
          StackMaster.stdout.puts 'The (space compressed) stack is larger than the limit set by AWS. See http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html'
          true
        else
          false
        end
      end

      def update_stack
        @updating = true
        cf.update_stack(stack_options)
      end

      def create_stack
        cf.create_stack(stack_options.merge(tags: proposed_stack.aws_tags))
      end

      def upload_files
        s3.upload_files(s3_options)
      end

      def stack_options
        {
          stack_name: @stack_definition.stack_name,
          template_body: proposed_stack.maybe_compressed_template_body,
          parameters: proposed_stack.aws_parameters,
          capabilities: ['CAPABILITY_IAM'],
          notification_arns: proposed_stack.notification_arns,
          stack_policy_body: proposed_stack.stack_policy_body
        }
      end

      def s3_options
        {
          bucket: @s3_config['bucket'],
          prefix: @s3_config['prefix'],
          region: @s3_config['region'],
          files: @stack_definition.files_to_upload
        }
      end

      def tail_stack_events
        StackEvents::Streamer.stream(@stack_definition.stack_name, @stack_definition.region, io: StackMaster.stdout, from: @from_time)
      end
    end
  end
end
