# Design Considerations

Use ManagedImage to store images in the cloud or on a file system.

ManagedImage fills specific needs and was not written to reinvent the wheel.

Here are features that ManagedImage provides:

* Images can be stored in  the local file system or in one of 39 cloud storage provider including Amazon S3
* Original uploaded images are stored in a private directory which cannot be accessed by users (the originals directory)
* Variants of those images are stored in a public directory and are displayed to users by through a public URL.
* The Variants directory acts like a cache. Images can be deleted and they will be regenerated the next time they are accessed.
* The base URL used to deliver the variant to the user can be changed so that we can easily use a CDN.
* The variant URL includes a securely generated hash for verification. The image is only generated if the verification has is correct. This prevents denial of service attacks.
* A ManagedImage object can be completely regenerated from its path
* A Variant of a ManagedImage object can be completely regenerated from its path. The ManagedImage object that the Variant is a representation of can be regenerated from the Variant which means the ManagedImage object can be completely regenerated from the Variant's path.
* Limit image upload by file size
* Limit image upload by image width/height


## Architecture

* ManagedImage images are stored in Fog::Storage
* ManagedImage::Variant images can be stored in a completely separate Fog::Storage as ManagedImage images


## Future

* To increase performance, when a Variant object is generated on the server, we spawn a thread that starts creating the Variant's image file. The method returns immediately. This means that we are processing the Variant in parallel with the back and forth http requests.


