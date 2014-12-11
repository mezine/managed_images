require 'test_helper'

class ManagedImageVariantClassTest < ActiveSupport::TestCase

  test 'hexdigest_for' do
    hexdigest = ManagedImage::Variant.hexdigest_for('abc')
    assert_match '10374787ed585803bc4cdb63f92a545b', hexdigest
  end

  test 'from_path' do
    uploaded_file = fixture_file_upload './test/assets/640x480.jpg', 'image/jpeg', true
    image = ManagedImage.upload 'test/managed-image-variant-class-test', uploaded_file
    temp_variant = image.new_variant(320, 240, 10, 630, 10, 470)
    path = temp_variant.path
    hexdigest = temp_variant.hexdigest

    variant = ManagedImage::Variant.from_path(path, hexdigest)
    assert_equal 320, variant.width
    assert_equal 240, variant.height
    assert_equal 10, variant.x1
    assert_equal 630, variant.x2
    assert_equal 10, variant.y1
    assert_equal 470, variant.y2
    assert_equal true, variant.authenticated?

    variant = ManagedImage::Variant.from_path(path, 'invalid-hex')
    assert_equal 320, variant.width
    assert_equal 240, variant.height
    assert_equal 10, variant.x1
    assert_equal 630, variant.x2
    assert_equal 10, variant.y1
    assert_equal 470, variant.y2
    assert_equal false, variant.authenticated?
  end

end

