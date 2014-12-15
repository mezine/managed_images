module ManagedImage::ControllerCreateMixin
  
  def create
    # image = ManagedImage.from_params('s/thesunny', params)
    image = ManagedImage.upload('site/thesunny', params[:file])
    variant = image.variants['preview']
    @image = image
    render json: image#.to_document
  end

end