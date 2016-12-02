require 'aws-sdk-core'

backup_snaps = ::Array.new
ids = ::Array.new
ec2 = ::Aws::EC2::Client.new

backup_snaps = ec2.describe_snapshots(
  restorable_by_user_ids: [ ENV['AWS_CUSTOMER_ID'] ],
  filters: [
    { name: 'tag-key', values: [ 'backup_id' ] },
    { name: 'status', values: [ 'completed' ] }
  ]
).snapshots

ids = backup_snaps.collect do |snap|
  snap.tags.collect { |tag| tag.value if tag.key == 'backup_id' }.compact.first
end.uniq.sort

SfnRegistry.register(:backup_ids) do
  ids << 'latest'
end

SfnRegistry.register(:ebs_volumes) do |options = {}|

  volume_size = options.fetch(:volume_size, 0)
  volume_count = options.fetch(:volume_count, 0)
  provisioned_iops = options.fetch(:provisioned_iops, 0)
  delete_on_termination = options.fetch(:delete_on_termination, 'true')
  root_vol_size = options.fetch(:root_vol_size, '12')

  array!(
    -> {
      device_name '/dev/sda1'
      ebs do
        delete_on_termination 'true'
        volume_type 'gp2'
        volume_size root_vol_size
      end
    },
    *volume_count.to_i.times.map { |c| -> {
      device_name "/dev/sd#{(102 + c).chr}" # f, g, h, i...
      ebs do
        delete_on_termination delete_on_termination
        snapshot_id if!(options[:restore_condition], select!(c, map!(:snapshots_by_backup_id, ref!(:restorable_id), :snapshots)), no_value!)
        volume_size if!(options[:restore_condition], no_value!, volume_size)
        volume_type if!(options[:io1_condition], 'io1', 'gp2')
        iops if!(options[:io1_condition], provisioned_iops, no_value!)
      end
      }
    }
  )
end
