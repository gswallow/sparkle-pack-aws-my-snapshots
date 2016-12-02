# sparkle-pack-aws-my-snapshots
SparklePack that provides two registries: 

- auto-detects EBS snapshots based on a `backup_id` AWS resource
tag.
- also detects RDS snapshots based on a DB Instance Identifier.

h/t to [techshell](https://github.com/techshell) for this approach.

### Tags

- In order to use this Sparkle Pack, you must assign a `backup_id` tag
to your EBS snapshots.

### Environment variables

The following environment variables must be set in order to use this Sparkle
Pack:

- AWS_REGION
- AWS_DEFAULT_REGION (being deprecated?)
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_CUSTOMER_ID

### Use Cases

This SparklePack adds a registry entry that uses the AWS SDK to detect completed
snapshots and returns a set of block device mappings for an EC2 instance.  By
default, it will return block device mappings for GP2 volumes restored from the
latest set of snapshots based on the latest `backup_id` tag, though you can
specify an ID and other options when calling the registry.

A second registry provides snapshot identifers for an RDS database.
See below.

## Usage

Add the pack to your Gemfile and .sfn:

Gemfile:
```ruby
source 'https://rubygems.org'
gem 'sfn'
gem 'sparkle-pack-aws-my-snapshots'
```

.sfn:
```ruby
Configuration.new do
  sparkle_pack [ 'sparkle-pack-aws-my-snapshots' ] ...
end
```

### EBS Snapshots
In a SparkleFormation resource:
```ruby
block_device_mappings registry!(:ebs_volumes, options)
```

The `volumes_from_snapshot` registry will return a list of block device mappings.

#### Options

The registry can take an options hash:

- restorable_id: A backup_id tag to use rather than the latest.  By default, volumes will be created form the latest snapshot.
- io1_condition: Required.  A condition to test, in order to create io1 or gp2 volumes.
- volume_type: 'gp2', 'io1'
- provisioned_iops: provisioned IOPS, if creating io1 volumes.  Default is 300.
- delete_on_termination: Delete EBS volumes when the instance is terminated.  Defaults to true.
- root_vol_size: the size of the root volume (/dev/sda).  Defaults to 12 GB.

### RDS Snapshots
In a SparkleFormation resource,
```ruby
   d_b_snapshot_identifier registry!(:latest_rds_snapshot, 'my-db-instance')
```

The `latest_rds_snapshot` registry will return a database snapshot identifier for the
'my-db-instance' RDS instance.

```ruby
parameters(:snapshot_to_restore) do
  type 'String'
  allowed_values registry!(:all_rds_snapshots, 'my-db-instance')
end
```

The `all_rds_snapshots` will return all snapshot identifiers available for the
'my-db-instance' RDS instance.
