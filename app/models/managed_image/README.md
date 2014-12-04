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
* Needs to run in JavaScript on client and server


## Architecture

* ManagedImage images are stored in Fog::Storage
* ManagedImage::Variant images are stored in a separate Fog::Storage
* Fog::Storage can be a local file system or in the cloud like S3. Test local, deply in the cloud.
* When we upload an image, we get a ManagedImage object
* When we upload, we can also pass in additional parameters so that we can get back one or more ManagedImage::Variant objects.
* For ManagedImage objects that already exist, we can call the resize methods (like #resize, #resize_to_fit, #resize_to_fill, etc) from the ManagedImage object and we get back a Variant. The most important value of a Variant is a URL where the Variant can be accessed from.
* Just because we have a URL, the file for the image may not exist yet. Images are generated as required.
* The URL goes to either
    - The direct URL to the Fog::Storage where the image can be retrieved (e.g. on S3)
    - ImagesController#show
* If the image goes to Fog::Storage, then if the image is missing, we defer to the ImagesController
* When we hit the ImagesController, we look to see if the Variant already exists. If it does, we simply return it.
* If the image does not exist, we check to see if the security hash matches. If not, we return some kind of error, possibly a 404 error. If it matches, we generate the image and store it in the variants storage.


## Future

* To increase performance, when a Variant is generated on the server, we spawn a thread that starts creating the file. The method returns immediately. This means that we are processing the Variant in parallel with the back and forth http requests.


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

After uploading an image, you can store the image in a Mongoid::Document by calling `ManagedImage#to_document`. You will get back a `ManagedImage::ImageDocument` object..

```ruby
image = ManagedImage.upload(subdir, uploaded_file, variants_hash)
image_doc = image.to_document # Returns a Mongoid document object
```

You can convert that back into a ManagedImage object by calling `to_image` on the Document.

```ruby
image_document = some_document.image
managed_image = image_document.to_image
```


### Best Practices: Upload directory

When images are uploaded using the `ManagedImage#upload` method, the directory argument should be laid out as "#{type}/#{id}"

For example, for images that are uploaded to a site:

```ruby
ManagedImage.upload('site/12345', params[:file], params[:variants])
```




### Best Practices: Not Storing Variants

It is not necessary to store Variant images in the database. This is because  you can generate Variants when needed.

Once a variant is generated with a certain specification, that image will not be generated again.

For example, all these methods will create the exact same Variant URL assuming the original image is of size 1024x768 (aspect ratio 4:3).

```ruby
variant_1 = managed_image.resize(640, 480)
variant_2 = managed_image.resize_to_fit(640, 480)
variant_3 = managed_image.resize_to_fill(640, 480)
variant_4 = managed_image.reframe(640, 480, 0.0, 0.0, 1.0, 1.0)
# All variants refer to the same file on the server
# variant_1.url == variant_2.url == variant_3.url == variant_4.url
```

If you were to upload an image to use as a profile picture, here's how you could generate the variant at the time you want to display the image.

```html
<img src="<%= @profile_image.resize_to_fit(50, 50).url %>" width="50" height="50">
```

or

```html
<% variant = @profile.image.resize_to_fit(50, 50) %>
<img src="<%= variant.url %>" width="<%= variant.width %>" height="<%= variant.height %>">
```

Note: We'd probably use a helper in the last example.



### Storing ManagingImage objects and Variant objects in JSON (e.g. Layout Builder)

Storing images in JSON objects is more difficult because the DOM is generated in the client (browser) and not the server. This means that you don't have access to the server methods for generating variants.

The reason you can not programmatically generate the variants on the Client is because you need access to the salt to generate the secure hash. We can not provide the salt to the Client as it will break security.

**The following is a description of how to build this functionality in the Client but, we don't actually have any code to do this. This might be something I (Sunny) can do though.**

#### ClientImage

The ClientImage is a JavaScript version of ManagedImage.

```javascript
var clientImage = new ClientImage(path, width, height)
```

We generate variants by calling the resize and reframe methods off of it. It returns a promise that contains the variant.

```javascript
var resizePromise = clientImage.resize(50, 50)
// or use the promise directly
resizePromise.then(function (variant) {
  $('#profile-pic').attr({
    src: variant.url,
    width: variant.width,
    height: variant.height
  })
})
```

In ReactJS, you'd probably use the callback to call `setState` on the React Element.


##### ClientImage Configuration

For this to work, we'd need to do some configuration so that ClientImage would know which URLs to use to get back the variants.

```javascript
ClientImage.configForBrowser({
  url: 'http://localhost:3000/managed-images'
});

// resize URL: 'http://localhost:3000/managed-images/resize'
// resizeToFit URL: 'http://localhost:3000/managed-images/resize-to-fit'
```

There should also be a way to configure the ClientImage for running on the server. The salt would have to be provided:

```javascript
ClientImage.configForServer({
  salt: 'salt'
});
```


TODO:

[] Need to allow setting variants information in different ways which are declarative (e.g. resize to fit)
[x] ImagesController#show should set the right :type => 'images/jpeg'. Currently its static, needs to depend on image type.
[] Perhaps some way to upload temporary images?
[x] Make sure uploaded file is an Image
[] Provide the argument for the subdirectory as an Array with proper argument checking to prevent '../' or './'