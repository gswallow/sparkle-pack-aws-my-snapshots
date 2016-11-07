# sparkle-pack-aws-my-snapshots
SparklePack to auto-detect EBS snapshots based on a `backup_id` AWS resource
tag.

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

See below.

## Usage

Add the pack to your Gemfile and .sfn:

Gemfile:
```ruby source 'https://rubygems.org'
gem 'sfn'
gem 'sparkle-pack-aws-aws-my-snapshots' ```

.sfn:
```ruby Configuration.new do
  sparkle_pack [ 'sparkle-pack-aws-my-snapshots' ] ...
end ```

In a SparkleFormation Template/Component/Dynamic:
```ruby block_device_mappings registry!(:volumes_from_snapshot, options) ```

The `volumes_from_snapshot` registry will return a list of block device mappings.

### Options

The registry can take an options hash:

- restorable_id: A backup_id tag to use rather than the latest
- volume_type: 'gp2', 'io1', or even 'magnetic,' if you must
- iops: provisioned IOPS, if creating io1 volumes.  Default is 3 * volume size.
- root_vol_size: the size of the root volume (/dev/sda).  Defaults to 12 GB.
