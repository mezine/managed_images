require 'test_helper'

class ManagedImageTest < ActiveSupport::TestCase

  setup do
    @storage = ManagedImage.originals_storage
    @expected_path = 'test/managed-image-test/6b782609698c92cccfbe166478a4f4ee-2560-1696.jpg'
    @uploaded_file = fixture_file_upload './test/assets/image.jpg', 'image/jpeg', true
  end

  test 'ManagedImage.new' do
    image = ManagedImage.new('path', 640, 480)
    assert_equal 'path', image.path
    assert_equal 640, image.width
    assert_equal 480, image.height
  end

  test 'uploaded image' do
    # upload image of reasonable size
    file = fixture_file_upload './test/assets/2560x1600.jpg', 'image/jpeg', true
    image = ManagedImage.upload 'test/managed-image-test', file
    assert_equal 2560, image.width
    assert_equal 1600, image.height

    # check file exists then delete it
    assert_equal true, @storage.exists?(image.path)
    @storage.destroy image.path
    assert_equal false, @storage.exists?(image.path)
  end

  test 'not a valid image' do
    uploaded_file = fixture_file_upload './test/assets/a.txt', 'image/jpeg', true
    assert_raises ManagedImage::InvalidImageError do
      image = ManagedImage.upload 'test/managed-image-test', uploaded_file
    end
  end

  test 'uploaded image needs to be resized for originals' do

    # Upload file (original size 3696x2448)
    image = ManagedImage.upload 'test/managed-image-test', @uploaded_file

    # File uploaded
    assert_equal @expected_path, image.path
    assert_equal 2560, image.width
    assert_equal 1696, image.height

    # check file exists then delete it
    assert_equal true, @storage.exists?(@expected_path)
    ManagedImage.originals_storage.destroy(@expected_path)
    assert_equal false, @storage.exists?(@expected_path)

    # JSON
    json = image.as_json
    assert_equal 2560, json['width']
    assert_equal 1696, json['height']
    assert_equal @expected_path, json['path']
  end

  test 'uploaded image too large' do
    file = fixture_file_upload './test/assets/6000x6000.png', 'image/png', true
    assert_raises ManagedImage::UploadImageTooLargeError do
      ManagedImage.upload 'test/managed-image-test', file
    end
  end

  test 'uploaded file too large' do
    file = fixture_file_upload './test/assets/large.png', 'image/png', true
    assert_raises ManagedImage::UploadFileTooLargeError do
      ManagedImage.upload 'test/managed-image-test', file
    end
  end

end