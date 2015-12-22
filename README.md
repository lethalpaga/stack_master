![StackMaster](/logo.png?raw=true)

StackMaster is a sure-footed way of creating, updating and keeping track of
Amazon (AWS) CloudFormation stacks.

- See the changes you are making to a stack before you apply them
- Connect stacks
- Keep secrets secret
- Customise stacks in different environments
- Apply descriptive labels to regions

StackMaster provides an easy command line interface to managing CloudFormation
stacks defined with templates specified in either the
[SparkleFormation](http://www.sparkleformation.io) DSL or standard JSON format.

## Installation

System-wide: `gem install stack_master`

With bundler:

- Add `gem 'stack_master'` to your Gemfile.
- Run `bundle install`
- Run `bundle exec stack_master init` to generate a directory structure and stack_master.yml file

## Configuration

Stacks are defined inside a `stack_master.yml` YAML file. When running
`stack_master`, it is assumed that this file will exist in the current working
directory, or that the file is passed in with `--config
/path/to/stack_master.yml`.  Here's an example configuration file:

```
region_aliases:
  production: us-east-1
  staging: ap-southeast-2
stack_defaults:
  tags:
    application: my-awesome-app
region_defaults:
  us-east-1:
    secret_file: production.yml.gpg
    tags:
      environment: production
    notification_arns:
      - test_arn
  ap-southeast-2:
    secret_file: staging.yml.gpg
    tags:
      environment: staging
stacks:
  production:
    myapp-vpc:
      template: myapp_vpc.rb
    myapp-db:
      template: myapp_db.rb
      stack_policy_file: db_stack_policy.json
    myapp-web:
      template: myapp_web.rb
  staging:
    myapp-vpc:
      template: myapp_vpc.rb
    myapp-db:
      template: myapp_db.rb
    myapp-web:
      template: myapp_web.rb
  eu-central-1:
    myapp-vpc:
      template: myapp_vpc.rb
```

## Directories

- `templates` - CloudFormation or SparkleFormation templates.
- `polices` - Stack policies.
- `parameters` - Parameters as YAML files.
- `secrets` - GPG encrypted secret files.

## Parameters

Parameters are loaded from multiple YAML files, merged from the following lookup paths:

- parameters/[stack_name].yml
- parameters/[region]/[stack_name].yml
- parameters/[region_alias]/[stack_name].yml

A simple parameter file could look like this:

```
key_name: myapp-us-east-1
```

Keys in parameter files are automatically converted to camel case.

## Parameter Resolvers

Parameter resolvers enable dynamic resolution of parameter values. A parameter
using a resolver will be a hash with one key where the key is the name of the
resolver.

One benefit of using resolvers instead of hard coding values like VPC ID's and
resource ARNs is that the same configuration works cross region, even though
the resolved values will be different.

### Stack Output

The stack output parameter resolver looks up outputs from other stacks in the
same region. The expected format is `[stack-name]/[OutputName]`.

```yaml
vpc_id:
  stack_output: my-vpc-stack/VpcId
```

### Secret

The secret parameters resolver expects a `secret_file` to be defined in the
stack definition which is a GPG encrypted YAML file. Once decrypted and parsed,
the value provided to the secret resolver is used to lookup the associated key
in the secret file. A common use case for this is to store database passwords.

stack_master.yml:

```yaml
stacks:
  us-east-1:
    my_app:
      template: my_app.json
      secret_file: production.yml.gpg
```

secrets/production.yml.gpg, when decrypted:

```yaml
db_password: my-password
```

parameters/my_app.yml:

```yaml
db_password:
  secret: db_password
```

### Security Group

Looks up a security group by name and returns the ARN.

```yaml
ssh_sg:
  security_group: SSHSecurityGroup
```

An array of security group names can also be provided.
```yaml
ssh_sg:
  security_group:
    - SSHSecurityGroup
    - WebAccessSecurityGroup
```

### SNS Topic

Looks up an SNS topic by name and returns the ARN.

```yaml
notification_topic:
  sns_topic: PagerDuty
```

### Latest AMI by Tag

Looks up the latest AMI ID by a given set of tags.

```yaml
web_ami:
  latest_ami_by_tags: role=web,application=myapp
```

### Custom parameter resolvers

New parameter resolvers can be created in a separate gem.

To create a resolver named my_resolver:
  * Create a new gem using your favorite tool
  * The gem structure must contain the following path:
```
lib/stack_master/parameter_resolvers/my_resolver.rb
```
  * That file need to contain a class named `StackMaster::ParameterResolvers::MyResolver`
    that implements a `resolve` method and an initializer taking 2 parameters :
```ruby
module StackMaster
  module ParameterResolvers
    class MyResolver
      def initialize(config, stack_definition)
        @config = config
        @stack_definition = stack_definition
      end

      def resolve(value)
        value
      end
    end
  end
end
```
  * Note that the filename and classname are both derived from the resolver name
    passed in the parameter file. In our case, the parameters YAML would look like:
```yaml
vpc_id:
  my_resolver: dummy_value
```

## Commands

```bash
stack_master help # Display up to date docs on the commands available
stack_master init # Initialises a directory structure and stack_master.yml file
stack_master list # Lists stack definitions
stack_master apply <region-or-alias> <stack-name> # Create or update a stack
stack_master diff <region-or-alias> <stack-name> # Display a stack tempalte and parameter diff
stack_master delete <region-or-alias> <stack-name> # Delete a stack
stack_master events <region-or-alias> <stack-name> # Display events for a stack
stack_master outputs <region-or-alias> <stack-name> # Display outputs for a stack
stack_master resources <region-or-alias> <stack-name> # Display outputs for a stack
stack_master status # Displays the status of each stack
```

## Applying updates

The apply command does the following:

- Builds the proposed stack json and resolves parameters.
- Fetches the current state of the stack from CloudFormation.
- Displays a diff of the current stack and the proposed stack.
- Asks if the update should continue.
- If yes, the API call is made to update or create the stack.
- Stack events are displayed until CloudFormation has finished applying the changes.

Demo:

![Apply Demo](/apply_demo.gif?raw=true)

## Maintainers

- [Steve Hodgkiss](https://github.com/stevehodgkiss)
- [Glen Stampoultzis](https://github.com/gstamp)

## License

StackMaster uses the MIT license. See [LICENSE.txt](https://github.com/envato/stack_master/blob/master/LICENSE.txt) for details.

## Contributing

1. Fork it ( http://github.com/envato/stack_master/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
