require 'aws-sdk-core'

ENV['restore_from_snapshot'] ||= 'true'
ENV['restorable_id']         ||= 'latest'

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

SparkleFormation.component(:snapshot_chooser) do

  mappings(:snapshots_by_backup_id) do
    ids.each do |id|
      snapshot_set = backup_snaps.collect do |snap|
        snap if !snap.tags.collect { |tag| tag.key == 'backup_id' && tag.value == id }.index(true).nil?
      end.compact

      set!(id.disable_camel!, :snapshots => snapshot_set.map(&:snapshot_id).sort)

    end

    snapshot_set = backup_snaps.collect do |snap|
      snap if !snap.tags.collect { |tag| tag.key == 'backup_id' && tag.value == ids.last }.index(true).nil?
    end.compact
    set!('latest'.disable_camel!, :snapshots => snapshot_set.map(&:snapshot_id).sort)
  end

  conditions.set!(
    :restore_from_snapshots,
    equals!(ref!(:restore_from_snapshots), 'true')
  )

  parameters(:restore_from_snapshots) do
    type 'String'
    default ENV['restore_from_snapshot']
    allowed_values ['true', 'false']
    description 'Restore EBS volumes from snapshot'
  end

  parameters(:restorable_id) do
    type 'String'
    allowed_values registry!(:backup_ids)
    default ENV['restorable_id']
    description 'Backup ID to restore'
  end
end