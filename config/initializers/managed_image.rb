ManagedImage.config do |config|
  config.set_originals_storage Fog::Storage.new(
    local_root: File.join(Rails.root.to_path, '.data/managed-images/originals'),
    provider: 'Local'
  )
  config.set_variants_storage Fog::Storage.new(
    local_root: File.join(Rails.root.to_path, '.data/managed-images/variants'),
    provider: 'Local'
  )
end

Rails.application.config.managed_images.originals_storage = {
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    provider: 'Local',
    dir: 'originals'
}
Rails.application.config.managed_images.variants_storage = {
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    provider: 'Local',
    dir: 'originals'
}