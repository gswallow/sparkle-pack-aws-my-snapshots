require 'aws-sdk-core'

rds_snapshots = ::Array.new
rds = ::Aws::RDS::Client.new

SfnRegistry.register(:all_rds_snapshots) do |filter = nil|
  if filter.nil?
    no_value!
  else
    rds_snapshots = rds.describe_db_snapshots.db_snapshots.collect do |snap|
      snap if snap.db_instance_identifier == filter
    end.compact
    rds_snapshots.sort! { |a, b| b.snapshot_create_time <=> a.snapshot_create_time }.map(&:db_snapshot_identifier)
  end
end

SfnRegistry.register(:latest_rds_snapshot) do |filter = nil|
  filter.nil? ? no_value! : rds_snapshots.first.db_snapshot_identifier
end
