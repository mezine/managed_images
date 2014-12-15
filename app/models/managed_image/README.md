
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

### config.set_salt(salt)

Call this with the salt to use for generating the security hash. The value for `salt` must be a String.

Do not recommend putting the salt value directly in the initializer. I believe there is a more secure place to put Rails security values.

http://www.gotealeaf.com/blog/managing-environment-configuration-variables-in-rails

### config.set_originals_storage(options), config.set_variants_storage(options)

This sets the storage/location where originally uploaded images should be stored and the storage/location where variants of that image should be stored.

Typically, originals images are not public. Only variant images are public (i.e. can be viewed from a URL)

`options` is a Hash that will be passed directly to Fog::Storage.new. You can learn more about acceptable values here:

http://fog.io/storage/

The values that can be passed through depend on the specific storage `provider` you select. A typical storage provider would be Amazon S3.

There are also two special values that you can pass through.

* `dir` sets a subdirectory within a Fog::Storage object. In our example, we set a subdirectory within our `local_root`. In the example, it's unnecessary to use `dir` option because we could have just set `local_root` to the specific subdirectory; however, in something like Amazon S3, the storage provider may not provider a directory option.

* `url` is a way to set the base URL for the file. If not provided, we use the `public_url` from the storage provider; however, this is not always desirable. For example, we may not want to give the Amazon S3 storage URL. We may wish to give the URL to a Rails Controller or to a CDN. Note: Usually the `url` option need only be provided for variants.


## Uploading Images in a Controller

From your controller call the `ManagedImage.upload` method. This method  returns a `ManagedImage` image object. This method has an `#as_json` method to make it easy to return the image, as JSON, to the browser.

```ruby
class MyController < ApplicationController
  def create
    image = ManagedImage.upload('path/to/image', params['file'])
    render json: image
  end
end
```

Note that the uploaded file is placed in the `params['file']` which means:

* The image was uploaded with an `<input type="file" name="file">`
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
  image: {
    path: 'dir/to/image/1234567890abcdef-640-480.jpg'
    width: 640,
    height: 480
  },
  url: 'http://some.domain.com/dir/to/image/1234567890abcdef-640-480-320-240-0-640-0-480.jpg?q=abcdef1234567890',
  path: 'dir/to/image/1234567890abcdef-640-480-320-240-0-640-0-480.jpg',
  pathWithQuery: 'dir/to/image/1234567890abcdef-640-480-320-240-0-640-0-480.jpg?q=abcdef1234567890',
  width: 320,
  height: 240,
}
```

You can use the `url` value to display the image in the browser.

You could also send the variant image directly to the browser.

```ruby
class MyController < ApplicationController
  def create
    image = ManagedImage.upload('path/to/image', params[:file])
    variant = image.resize_to_fit(320, 320)
    send_data variant.blob, :type => variant.mimetype, :disposition => 'inline'
    render json: variant
  end
end
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
ManagedImage.upload("site/#{site.id}", params[:file], params[:variants])
```

The problem with this method is that if somebody were able to modify the value of `site.id` they might be able to create extra directories that you haven't authorized. For example, if `site.id` was `a/b/c/d/e/f/g/h/i/j/k/l/m`. If it was sufficiently long enough, they might be able to break the filesystem.

An alternative, and preferrable way to call this method is to pass an Array of Strings indtrsf of a String as the first argument.

```ruby
ManagedImage.upload(['site', site.id], params[:file], params[:variants])
```

In either case, the directory name is checked to ensure that there are no invalid characters to prevent certain security attacks like using `.` or `..` in the directory path. The only valid characters are 0-9, a-z, the dash (-) and the underscore (_). Only lowercase letters are accepted.


### Best Practices: Not Storing Variants

It's a best practice to not store the variant image in the database. This is because you can generate Variants when needed.

Once a variant URL is generated with a certain specification, the image file will not be generated again.

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