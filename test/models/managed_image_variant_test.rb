require 'test_helper'

class ManagedImageVariantTest < ActiveSupport::TestCase

  setup do
    uploaded_file = fixture_file_upload './test/assets/640x480.jpg', 'image/jpeg', true
    @image = ManagedImage.upload 'test/managed-image-variant-test', uploaded_file
    @variant = @image.new_variant(640, 480, 10, 90, 20, 80)
  end

  test 'Validate Crop Rectangle' do
    @image.new_variant(320, 240, 0, 640, 0, 480)
    assert_raises ManagedImage::InvalidCropError do
      @image.new_variant(320, 240, -1, 640, 0, 480)
    end
    assert_raises ManagedImage::InvalidCropError do
      @image.new_variant(320, 240, 0, 640, -1, 480)
    end
    assert_raises ManagedImage::InvalidCropError do
      @image.new_variant(320, 240, 0, 641, 0, 480)
    end
    assert_raises ManagedImage::InvalidCropError do
      @image.new_variant(320, 240, 0, 640, 0, 481)
    end
    assert_raises ManagedImage::InvalidCropError do
      @image.new_variant(320, 240, 640, 0, 0, 480)
    end
    assert_raises ManagedImage::InvalidCropError do
      @image.new_variant(320, 240, 0, 640, 480, 0)
    end
  end

  test 'ManagedImage#new_variant' do
    variant = @image.new_variant(320, 240, 10, 630, 10, 470) 
    assert_respond_to variant.storage, :create
    assert_equal '8917c905a1b713db1d0f3480717e68e8', variant.hexdigest
    assert_match /^http\:\/\//, variant.url
    assert_match /640[-]480[-]320[-]240[-]10[-]630[-]10[-]470/, variant.url 
    assert_match /\?q=8917c905a1b713db1d0f3480717e68e8/, variant.url
    assert_match /640[-]480[-]320[-]240[-]10[-]630[-]10[-]470/, variant.path
    refute_match /\?q=8917c905a1b713db1d0f3480717e68e8/, variant.path
    assert_match /640[-]480[-]320[-]240[-]10[-]630[-]10[-]470/, variant.path_with_query
    assert_match /\?q=8917c905a1b713db1d0f3480717e68e8/, variant.path_with_query
    assert_equal 320, variant.width
    assert_equal 240, variant.height
    assert_equal 10, variant.x1
    assert_equal 630, variant.x2
    assert_equal 10, variant.y1
    assert_equal 470, variant.y2
    assert_equal 'image/jpeg', variant.mimetype
    assert_equal true, variant.authenticated?
    image_size = ImageSize.new(variant.blob)
    assert_equal 320, image_size.width
    assert_equal 240, image_size.height
    assert_equal true, variant.exists?
    variant.destroy
    assert_equal false, variant.exists?
  end

  test 'as_json' do
    json = @image.new_variant(320, 240, 10, 630, 10, 470).as_json
    assert_match /^http\:\/\//, json['url']
    assert_match /640[-]480[-]320[-]240[-]10[-]630[-]10[-]470/, json['url']
    assert_match /\?q=8917c905a1b713db1d0f3480717e68e8/, json['url']
    assert_match /640[-]480[-]320[-]240[-]10[-]630[-]10[-]470/, json['path']
    refute_match /\?q=8917c905a1b713db1d0f3480717e68e8/, json['path']
    assert_match /640[-]480[-]320[-]240[-]10[-]630[-]10[-]470/, json['pathWithQuery']
    assert_match /\?q=8917c905a1b713db1d0f3480717e68e8/, json['pathWithQuery']
    assert_equal 320, json['width']
    assert_equal 240, json['height']
    assert_equal 10, json['x1']
    assert_equal 630, json['x2']
    assert_equal 10, json['y1']
    assert_equal 470, json['y2']
  end

  test 'create and destroy' do
    variant = @image.new_variant(50, 80, 0, 50, 400, 480)
    variant.destroy
    assert_equal false, variant.exists?
    variant.generate
    assert_equal true, variant.exists?
    variant.destroy
    assert_equal false, variant.exists?
  end

end

