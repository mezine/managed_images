
# ManagedImage

## Configuration

First, you need to configure ManagedImage.

Create an initializer at

```
./config/initializers/managed_image.rb
```

With contents like:

```ruby
ManagedImage.config do |config|
  # Set the salt for the generation of the authentication Hash. The actual
  # salt should be stored in something secure like an Environment variable.
  config.set_salt "salt"
  # Configure Fog::Storage for the original images which cannot be accessed
  # online and are used for creating the resized variants.
  config.set_originals_storage(
    provider: 'Local',
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    dir: 'originals'
  )
  # Configure Fog::Storage for the images which can be accessed online.
  # They are generated from the original images.
  config.set_variants_storage(
    provider: 'Local',
    local_root: File.join(Rails.root.to_path, '.data/managed-images'),
    dir: 'variants',
    url: 'http://localhost:3000/managed-images'
  )
  # Set the maximum uploaded image dimensions
  # The limit is to prevent DOS attacks by filling a PNG or JPEG with an image
  # the takes up too much RAM.
  config.set_max_upload_image_size(5000, 5000)
  # Sets the maximum size that the image is stored at.
  # Images larger than this size are resized.
  # Since all the smaller images are resized from this original image size,
  # we want it to (a) be big enough to support any image size we may wish to
  # support including Retina images but (b) be small enough that the storage
  # issues won't become a problem.
  config.set_max_originals_image_size(2560, 2560)
end
```

### config.set_salt(salt)

Call this with the salt to use for generating the security hash. The value for `salt` must be a String.

Do not recommend putting the salt value directly in the initializer. These values should probably be stored in an Environment variable.

http://www.gotealeaf.com/blog/managing-environment-configuration-variables-in-rails


### config.set_originals_storage(options), config.set_variants_storage(options)

This sets the storage/location where originally uploaded images should be stored and the storage/location where variants of that image should be stored.

Typically, originals images are not available for public access.

The variant images (resized versions of the originals) are public (i.e. can be viewed from a URL).

`options` is a Hash that will be passed directly to Fog::Storage.new. You can learn more about acceptable values here:

http://fog.io/storage/

The values that can be passed through depend on the specific storage provider you select. A typical storage provider would be Amazon S3.

There are also two special values that you can pass through.

* `dir` sets a subdirectory within a Fog::Storage object. In our example, we set a subdirectory within our `local_root`. In the example, it's unnecessary to use `dir` option because we could have just set `local_root` to the specific subdirectory; however, in something like Amazon S3, the storage provider may not provider a directory option.

* `url` is a way to set the base URL for the file. If not provided, we use the `public_url` from the storage provider; however, this is not always desirable. For example, we may not want to give the Amazon S3 storage URL. We may wish to give the URL to a Rails Controller or to a CDN. Note: Usually the `url` option need only be provided for variants.


### config.set_max_upload_image_size(width, height)

Use this to set the maximum image width/height of an uploaded image. If an image is uploaded that is larger than this size, then the upload will fail. Typically, we want this image to be as large as we can expect a user to upload and expect us to accept.

Note: This is not the size of the image that we store. We always resize images to make sure they are no larger then the `max_originals_image_size` set below.


### config.set_max_originals_image_size(width, height)

This is the largest image size that we will store on our servers. If the image is larger than this size, it is resample to fit within the width/height. For example, if an image was uploaded at 5000x4000 pixels but we only supports a max of 2560x2560, the image would be resampled down to 2560x2048 to fit. Note that the aspect ratio would be preserved.


## Uploading Images in a Controller

### Uploading and Returning an Image JSON Object

From your controller call the `ManagedImage.upload` method. This method  returns a `ManagedImage` image object. This method has an `#as_json` method to make it easy to return the image, as JSON, to the browser.

```ruby
class MyController < ApplicationController
  def create
    image = ManagedImage.upload('path/to/image', params['file'])
    render json: image
  end
end
```

In this example, the uploaded file is put in the `params['file']` param which means:

* The image was uploaded with `<input type="file" name="file">`
* The form would have to be `<form enctype="multipart/form-data">`

The returned JSON object looks something like this:

```javascript
{
  path: 'dir/to/image/1234567890abcdef-640-480.jpg'
  width: 640,
  height: 480
}
```

The returned JSON object does not contain a URL for the image because a ManagedImage object cannot be displayed directly.

You can only display variants of an image.

### Uploading and Returning a Variant JSON Object

So, more typically, if you wanted to display the image immediately after retrieving the JSON object, you'd return a variant instead.

```ruby
class MyController < ApplicationController
  def create
    image = ManagedImage.upload('path/to/image', params[:file])
    variant = image.resize_to_fit(320, 320)
    render json: variant
  end
end
```

The example above uses the `resize_to_fit` method which will resize the image so that it preserves its aspect ratio and fits within the width/height given in the arguments.

The returned JSON object would look something like this:

```javascript
{
  url: 'http://some.domain.com/dir/to/image/1234567890abcdef-640-480-320-240-0-640-0-480.jpg?q=abcdef1234567890',
  path: 'dir/to/image/1234567890abcdef-640-480-320-240-0-640-0-480.jpg',
  pathWithQuery: 'dir/to/image/1234567890abcdef-640-480-320-240-0-640-0-480.jpg?q=abcdef1234567890',
  width: 320,
  height: 240,
}
```

You can use the `url` value to display the image in the browser.


### #show the image to the user

The user accesses the image at a URL. Create a route to a #show method in the controller something like this:

```ruby
Rails.applications.routes.draw do
  get '/managed-images/*path' => 'my_controller#show'
end
```

In the controller's `#show` method, we create the variant from the path and the params[:q] which contains the authentication hexdigest.

```ruby
class MyController < ApplicationController
  def show
    variant = ManagedImage::Variant.from_path("#{params[:path]}.#{params[:format]}", params[:q])
    send_data variant.blob, :type => variant.mimetype, :disposition => 'inline'
  end
end
```

We return the image by using `send_data` to return a blob and mimetype.


### Combining Controller Return JSON Values

The library is deliberately minimal to allow the maximum flexibility on how you return JSON values.

For example, if you wanted to, you could return the original image, a preview variant and a thumbnail variant in a controller by using something like this:

```ruby
class MyController < ApplicationController
  def create
    image = ManagedImage.upload('path/to/image', params[:file])
    preview = image.resize_to_fit(320, 320)
    thumbnail = image.resize_to_fit(100, 100)
    json = {
      image: image,
      preview: preview,
      thumbnail: thumbnail
    }
    render json: json
  end
end
```


### Best Practices: Upload directory

When images are uploaded using the `ManagedImage#upload` method, the directory argument should be laid out as "#{type}/#{id}"

For example, for images that are uploaded to a site:

```ruby
ManagedImage.upload("site/#{site.id}", params[:file])
```

The problem with this method is that if somebody were able to modify the value of `site.id` they might be able to create extra directories that you haven't authorized. For example, if `site.id` was `a/b/c/d/e/f/g/h/i/j/k/l/m`. If it was sufficiently long enough, they might be able to break the filesystem.

An alternative, and preferrable way to call this method is to pass an Array of Strings indtrsf of a String as the first argument.

```ruby
ManagedImage.upload(['site', site.id], params[:file])
```

In either case, the directory name is checked to ensure that there are no invalid characters to prevent certain security attacks like using `.` or `..` in the directory path. The only valid characters are 0-9, a-z, the dash (-) and the underscore (_). Only lowercase letters are accepted.


### Best Practices: Not Storing Variants

It's a best practice to not store the variant image in the database. This is because you can generate Variants when needed.

Once a variant URL is generated with a certain specification, the image file will not be generated again.

For example, all these methods will create the exact same Variant URL assuming the original image is of size 1024x768 (aspect ratio 4:3).

```ruby
variant_1 = managed_image.resize_to_fit(640, 480)
variant_2 = managed_image.reframe(640, 480, 0, 1024, 0, 768)
# NOTE: Assuming original image size is 1024x768
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


## UNDER CONSTRUCTION / IN PROGRESS

### Storing ManagingImage objects and Variant objects in JSON (e.g. Layout Builder)

Storing images in JSON objects is more difficult because the DOM is generated in the client (browser) and not the server. This means that you don't have access to the server methods for generating variants.

The reason you can not programmatically generate the variants on the Client is because you need access to the salt to generate the secure hash. We can not provide the salt to the Client as it will break security.

**The following is a description of how to build this functionality in the Client but, we don't actually have any code to do this. This might be something I (Sunny) can do though.**

#### ClientImage

The ClientImage is a JavaScript version of ManagedImage. The same library can be used both in the browser (client) or when generating HTML on the server using Isomorphic JavaScript. These libraries are JavaScript libraries so they won't work directly from Ruby code.

```javascript
var clientImage = new ClientImage(path, width, height)
```

We generate variants by calling the resize and reframe methods off of it. It returns a promise that contains the variant.

```javascript
ClientImage.resize(50, 50).then(function (variant) {
  $('#profile-pic').attr({
    src: variant.url,
    width: variant.width,
    height: variant.height
  })
})
```

In ReactJS, you'd probably do something like this:

```javascript
React.create({
  // ...
  onChangeLayout: function () {
    // ...
    ClientImage.resize(newSize.width, newSize.height).then(function (variant) {
      this.setState({
        profileVariant: variant
      })
    })
  },
  //...
  render: function () {
    // ...
  }
});
```


#### How ClientImage#resize Works

In the Background the call to the `resize` method on the Client (Browser) would do an AJAX request to the server to get back the Variant URL.

In the call on the server, we would have some JavaScript code that can generate the image URL with the salt. Since this code runs on the server, we can put the salt into the JavaScript code.


##### Configuring ClientImage

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

[x] Need to allow setting variants information in different ways which are declarative (e.g. resize to fit)
[x] ImagesController#show should set the right :type => 'images/jpeg'. Currently its static, needs to depend on image type.
[x] Make sure uploaded file is an Image
[x] Provide the argument for the subdirectory as an Array with proper argument checking to prevent '../' or './'