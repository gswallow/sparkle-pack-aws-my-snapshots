require 'aws-sdk-core'

backup_snaps = ::Array.new
restorable_id = ::String.new
selected_snaps = ::Array.new
ec2 = ::Aws::EC2::Client.new

SfnRegistry.register(:volumes_from_snapshot) do |options = {}|

  restorable_id = options.fetch('restorable_id', nil)
  volume_type = options.fetch('volume_type', 'gp2')
  iops = options.fetch('iops', 0)
  root_vol_size = options.fetch('root_vol_size', '12')

  backup_snaps = ec2.describe_snapshots(
    restorable_by_user_ids: [ ENV['AWS_CUSTOMER_ID'] ],
    filters: [
      { name: 'tag-key', values: [ 'backup_id' ] },
      { name: 'status', values: [ 'completed' ] }
    ]
  ).snapshots

  restorable_id ||= backup_snaps.collect do |snap|
    snap.tags.collect { |tag| tag.value if tag.key == "backup_id" }.compact.first
  end.sort.last

  selected_snaps = ec2.describe_snapshots(
    restorable_by_user_ids: [ ENV['AWS_CUSTOMER_ID'] ],
    filters: [
      { name: 'tag-key', values: [ 'backup_id' ] },
      { name: 'tag-value', values: [ restorable_id ] },
      { name: 'status', values: [ 'completed' ] }
    ]
  ).snapshots

  array!(
    -> {
      device_name '/dev/sda1'
      ebs do
        delete_on_termination 'true'
        volume_type 'gp2'
        volume_size root_vol_size.to_s
      end
    },
    *selected_snaps.count.times.map { |c| -> {
      device_name "/dev/sd#{(102 + c).chr}" # f, g, h, i...
      ebs do
        if volume_type == 'io1'
          iops (iops == 0 ? 3 * selected_snaps[c].volume_size : iops).to_s
        end
        delete_on_termination 'true'
        snapshot_id selected_snaps[c].snapshot_id
        volume_type volume_type
      end
      }
    }
  )
end
