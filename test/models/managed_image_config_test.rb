require 'test_helper'

class ManagedImageTest < ActiveSupport::TestCase

  test 'ManagedImage.config' do
    # NOTE:
    # These are congigured in config/initializers
    assert_equal 'salt', ManagedImage.salt
    assert_equal 'originals', ManagedImage.originals_storage.dir
    assert_equal 'variants', ManagedImage.variants_storage.dir
    assert_equal 'http://localhost:3000/managed-images', ManagedImage.variants_storage.url
    assert_equal 5000, ManagedImage.max_upload_image_size.width
    assert_equal 5000, ManagedImage.max_upload_image_size.height
    assert_equal 2560, ManagedImage.max_originals_image_size.width
    assert_equal 2560, ManagedImage.max_originals_image_size.height
  end

end