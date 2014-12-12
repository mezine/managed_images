require 'test_helper'

class ManagedImageController < ApplicationController
  
  def create
    image = ManagedImage.upload(['test', 'managed_image_controller_test'], params[:file])
    @image = image
    render json: image
  end

  def create_with_resize
    image = ManagedImage.upload(['test', 'managed_image_controller_test'], params[:file])
    variant = image.resize_to_fit(100, 100)
    variant.generate
    render json: variant
  end

  def variant
    image = ManagedImage.from_path(params[:path])
    width = params['width'].to_i
    height = params['height'].to_i
    x1 = params['x1'].to_i
    x2 = params['x2'].to_i
    y1 = params['y1'].to_i
    y2 = params['y2'].to_i
    variant = image.new_variant(width, height, x1, x2, y1, y2)
    render json: variant
  end

end

class ManagedImageControllerTest < ActionController::TestCase

  def with_temp_routing
    with_routing do |map|
      map.draw do
        post '/create' => 'managed_image#create'
        post '/create_with_resize' => 'managed_image#create_with_resize'
        post '/variant' => 'managed_image#variant'
      end
      yield
    end
  end

  test 'should create image' do
    uploaded_file = fixture_file_upload './test/assets/640x480.jpg', 'image/jpeg', true
    with_temp_routing do
      post(:create, {'file' => uploaded_file})
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal "test/managed_image_controller_test/2187f8f15234753a19ab2304fc8ff245-640-480.jpg", json['path']
    assert_equal 640, json['width']
    assert_equal 480, json['height']
  end

  test 'should create image with variant' do
    uploaded_file = fixture_file_upload './test/assets/640x480.jpg', 'image/jpeg', true
    with_temp_routing do
      post(:create_with_resize, {'file' => uploaded_file})
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert_kind_of String, json['url']
    assert_kind_of String, json['path']
    assert_kind_of String, json['pathWithQuery']
    assert_includes json['url'], 'http://'
    assert_includes json['url'], '-640-480-100-75-0-640-0-480.jpg'
    assert_includes json['url'], '?q=' 
    refute_includes json['path'], 'http://'
    assert_includes json['path'], '-640-480-100-75-0-640-0-480.jpg'
    refute_includes json['path'], '?q=' 
    refute_includes json['pathWithQuery'], 'http://'
    assert_includes json['pathWithQuery'], '-640-480-100-75-0-640-0-480.jpg'
    assert_includes json['pathWithQuery'], '?q=' 
    assert_equal 100, json['width']
    assert_equal 75, json['height']
    assert_equal 0, json['x1']
    assert_equal 640, json['x2']
    assert_equal 0, json['y1']
    assert_equal 480, json['y2']
  end

  test 'should be able to get variant from image' do
    uploaded_file = fixture_file_upload './test/assets/640x480.jpg', 'image/jpeg', true
    # make sure the image exists
    image = ManagedImage.upload(['test', 'managed_image_controller_test'], uploaded_file)

    with_temp_routing do
      get(:variant, {
        'path' => image.path,
        'width' => '100',
        'height' => '100',
        'x1' => '80',
        'x2' => '560',
        'y1' => '0',
        'y2' => '480'
      })
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert_kind_of String, json['url']
    assert_kind_of String, json['path']
    assert_kind_of String, json['pathWithQuery']
    assert_equal 100, json['width']
    assert_equal 100, json['height']
    assert_equal 80, json['x1']
    assert_equal 560, json['x2']
    assert_equal 0, json['y1']
    assert_equal 480, json['y2']
  end

end