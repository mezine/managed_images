# ManagedImage

## Overview

We use MangedImage to store images on our file system or in the cloud.

ManagedImage fills specific needs for our application is not simply reinventing the wheel although it will, necessarily, cover some features that can be found in other image libraries like Paperclip.

Here are features that ManagedImage provides:

* Images are  stored in  the local file system or in one of 39 cloud storage provider including Amazon S3
* Uploaded images are stored in a private directory which is not accessed by users (the originals directory)
* We show images to users by providing a URL to a variant. A variant is a variation of the original images which includes a rectangle viewport of a portion of the image and the width/height of the final image to deliver
* Variant images are stored in a public directory can can be accessed by users (the variants directory)
* Variants are generated upon request
* The entire Variants directory acts like a cache. Any images can be deleted and they will be regenerated next time they are accessed.
* We can modify the base URL which we wish to deliver to the user which allows us to easily use a CDN [TODO]
* Although generated upon request, the variant URL includes a hash for verification. If the wrong hash is provided, the image is not provided. This prevents denial of service attacks by someone just providing new width/height coordinates.
* Variant URLs are easily generated [TODO]
* A MangedImage can be stored as a String like "s/thesunny/fee8f84e2cdd414ac3e6d826ff2e313b-1500-1000.jpg". The entire ManagedImage can be recreated from the String.
* A Variant can be stored as a String that represents its path and a query string "s/thesunny/fee8f84e2cdd414ac3e6d826ff2e313b-1500-1000-640-480-0-100-0-100.jpg?q=ef0116e8a537cc328b563058360fed2b". The entire ManagedImage::Variant can be recreated from the String.
* Security checks using MD5 Hashes to prevent DOS attacks on image generation
* Limits image upload size to 25 MB

## Architecture

* ManagedImage images are stored in Fog::Storage
* ManagedImage::Variant images are stored in a separate Fog::Storage
* Fog::Storage can be a local file system of in the cloud like S3
* When we upload an image, we get back a ManagedImage object
* When we upload, we can also pass in additional parameters so that we can get back one or more ManagedImage::Variant objects.
* For ManagedImage objects that already exist, we can call the #new_variant method from the ManagedImage object and we get back a Variant. The most important value of a Variant is a URL where the Variant can be accessed from. Although we already have a URL, at this point, the variant image may or may not exist.
* The URL goes to either
    - The direct URL to the Fog::Storage where the image can be retrieved (e.g. on S3)
    - ImagesController#show
* If the image goes to Fog::Storage, then if the image is missing, we defer to the ImagesController
* When we hit the ImagesController, we look to see if the Variant already exists. If it does, we simply return it.
* If the image does not exist, we check to see if the security hash matches. If not, we return some kind of error, possibly a 404 error. If it matches, we generate the image and store it in the variants storage.


## Usage

### Configuration

First, you need to configure ManagedImage.

Create an initializer at

```
./config/initializers/managed_image.rb
```

With contents like:

```ruby
ManagedImage.config do |config|
  config.set_salt "salt"
  config.set_originals_storage(
    provider: 'Local',
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    dir: 'originals'
  )
  config.set_variants_storage(
    provider: 'Local',
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    dir: 'variants',
    url: 'http://localhost:3000/managed-images'
  )
end
```

#### config.set_salt(salt)

Call this with the salt to use for generating the security hash. The value for `salt` must be a String.

#### config.set_originals_storage(options), config.set_variants_storage(options)

This sets the location where originally uploaded images should be stored and the location where variants of that image should be stored.

Typically, originals images are not public. Only variant images are public (i.e. can be viewed from a URL)

`options` is a Hash that will be passed directly to Fog::Storage.new. You can learn more about acceptable values here:

http://fog.io/storage/

The values that can be passed through depend on the specific storage `provider` you select.

There are also two special values that you can pass through.

* `dir` sets a subdirectory with a provider that you can select. In our example, we set a subdirectory within our `local_root`. In this example, it's unnecessary because we could have just set `local_root` to the specific subdirectory; however, in something like Amazon S3, the storage provider may not provider a directory option.

* `url` is a way to set the base URL for the file. If not provided, we use the `public_url` from the storage provider; however, this is not always desirable. For example, we may not want to give the Amazon S3 storage URL. We may wish to give the URL to a Rails Controller or to a CDN. Note: Usually the `url` option need only be provided for variants.


### Uploading Images

#### ImagesController

There are two ways to upload images.

The easiest way is to upload them to `ImagesController#create` by setting up a route in `config/routes.rb`.

Here are the params:

* file: An input type="file" where the file is uploaded
* variants: An optional variants hash that describes variations of the image

TODO:

The variants hash looks something like this:

* variants
    - [name]
        + method: [resize_method]
        + width
        + height
        + [...depending on resize method]

#### Custom Controller

You can also create your own controller and call the `ManagedImage.upload` method. This method will return a `ManagedImage` instance and return, as a JSON object, a preview variant.

```ruby
image = ManagedImage.upload(subdir, uploaded_file, variants_hash)
preview_variant = image.variants[:preview]
render json: preview_variant
```

One could also return the actual image if desired:

```ruby
image = ManagedImage.upload(subdir, uploaded_file, variants_hash)
preview_variant = image.variants[:preview]
send_data preview_variant.blob, :type => 'image/jpeg', :disposition => 'inline'
```


### Creating Variants

Variants are simply variations of the same image.

Ultimately a variant is like an original image that:

1. Has been cropped to a rectangle
2. Resized

There are a number of methods to do this simply.

```ruby
# Resize to exact width/height. Does not preserve aspect ratio.
variant = image.resize(width, height)

# Resize to fit inside width/height. Preserves aspect ratio.
variant = image.resize_to_fit(width, height)

# Resize to fill exact width/height. Crops to fit. Preserves aspect ratio.
variant = image.resize_to_fill(width, height)

# Reframe allows you to specify the rectangle from the source image.
# Rectangle specifies as Float values from 0.0 to 1.0 as portion of image.
# Note that final image is rounded to nearest percent (i.e. 0.01)
variant = image.reframe(width, height, x1, y1, x2, y2)
```



### Storing ManagedImage objects in Database

After uploading an image, you can store them in a Mongoid::Document by calling `ManagedImage#to_document`. You will get back a `ManagedImage::ImageDocument` object..

```ruby
image = ManagedImage.upload(subdir, uploaded_file, variants_hash)
image_doc = image.to_document # Returns a Mongoid document object
```

You can convert that back into a ManagedImage object by calling `to_image` on the Document.

```ruby
image_document = some_document.image
managed_image = image_document.to_image
```




TODO:

* Need to allow setting variants information in different ways which are declarative (e.g. resize to fit)
* ImagesController#show should set the right :type => 'images/jpeg'. Currently its static, needs to depend on image type.
* Perhaps some way to upload temporary images?