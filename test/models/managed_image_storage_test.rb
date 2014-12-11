require 'test_helper'

class ManagedImageStorageTest < ActiveSupport::TestCase

  setup do
    @storage = ManagedImage::Storage.new(
      local_root: File.join(Rails.root.to_path, '.data/test'),
      provider: 'Local',
      dir: 'managed-image-storage-test',
      url: '//localhost/images'
    )
  end

  test 'ManagedImage::Storage.create with String' do
    path = 'new/alphabet.txt'
    # Make sure file doesn't already exist
    @storage.destroy(path)
    assert !@storage.exists?(path)

    # Create file with text
    @storage.create(path, 'abcdefghijklmnopqrstuvwxyz')

    # Make sure file exists
    assert @storage.exists?(path)
    fog_file = @storage.get(path)
    assert_equal 'abcdefghijklmnopqrstuvwxyz', fog_file.body

    # Delete file
    @storage.destroy(path)
    assert !@storage.exists?(path)

  end

  test 'ManagedImage::Storage.create with IO' do
    path = 'new/a.txt'

    # Delete file
    @storage.destroy(path)
    assert !@storage.exists?(path)

    # Create file with IO
    File.open './test/assets/a.txt', 'r' do |io|
      @storage.create(path, io)
    end

    # Make sure file exists
    assert @storage.exists?(path)
    fog_file = @storage.get(path)
    assert_equal 'alpha', fog_file.body

    # Delete file
    @storage.destroy(path)
    assert !@storage.exists?(path)
  end

  test 'url_for' do
    assert_equal '//localhost/images/a/b/c.txt', @storage.url_for('a/b/c.txt')
  end

end