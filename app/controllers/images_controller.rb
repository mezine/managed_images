class ImagesController < ApplicationController

  include ManagedImage::ControllerCreateMixin
  include ManagedImage::ControllerShowMixin
  include ManagedImage::ControllerResizeMixin

end
