ManagedImage.config do |config|
  config.set_salt "salt"
  config.set_originals_storage(
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    provider: 'Local',
    dir: 'originals'
  )
  config.set_variants_storage(
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    provider: 'Local',
    dir: 'variants',
    url: 'http://localhost:3000/managed-images'
  )
end
