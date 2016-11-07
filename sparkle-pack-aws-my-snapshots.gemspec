Gem::Specification.new do |s|
  s.name = 'sparkle-pack-aws-my-snapshots'
  s.version = '0.0.1'
  s.licenses = ['MIT']
  s.summary = 'AWS My Snapshots SparklePack'
  s.description = 'SparklePack to detect snapshots based on backup_set and backup_id tags'
  s.authors = ['Greg Swallow']
  s.email = 'gswallow@indigobio.com'
  s.homepage = 'https://github.com/gswallow/sparkle-pack-aws-my-snapshots'
  s.files = Dir[ 'lib/sparkleformation/registry/*' ] + %w(sparkle-pack-aws-my-snapshots.gemspec lib/sparkle-pack-aws-my-snapshots.rb)
  s.add_runtime_dependency 'aws-sdk-core', '~> 2'
end
