class ImagesController < ApplicationController

  def create
    id = 'abc123'
    image = ManagedImage.upload(['site', id], params[:file])
    @image = image
    @variant = image.resize_to_fit(640, 640)
    # json = image.as_json
    # json['preview'] = variant
    render json: @variant
  end

  def create_original_only
    id = 'abc123'
    image = ManagedImage.upload(['site', id], params[:file])
    render json: image
  end

  def show
    variant = ManagedImage::Variant.from_path("#{params[:path]}.#{params[:format]}", params[:q])
    send_data variant.blob, :type => variant.mimetype, :disposition => 'inline'
  end

  def reframe
    image = ManagedImage.from_path("#{params[:path]}.#{params[:format]}")
  end

end
