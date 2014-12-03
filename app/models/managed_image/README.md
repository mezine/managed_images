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