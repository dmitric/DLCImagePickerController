About
-----

DLCImagePickerController is a fast, beautiful and fun way to filter and capture your photos with OpenGL and your iPhone.
The majority of the praise should be directed towards BradLarson for his [GPUImage](https://github.com/BradLarson/GPUImage) library.

[Here's a video of it in action](http://www.youtube.com/watch?v=2BFljDoJpB8)

Setup
------

When you clone the repo, you'll need to download GPUImage assets:

```
git submodule init
git submodule update
```

Features
---------

### Live Filters
Here are some examples of the filters that are included. These are being applied to the live camera stream.

![Filters](http://i.imgur.com/bHNAN.png)

### Radial Blur

It also has a radial blur, that you can move and pinch to your liking

![Radial blur on and off](http://i.imgur.com/RhCcV.png)

### Front Facing Camera

There is a front facing camera, however it's still buggy on capture

![Front facing camera](http://i.imgur.com/DnTHD.png)

### Apply filters/blur after capture or retake photo

After you capture the image, you can apply new filters and toggle/move/resize the blur as you please or decide to retake it

![Filters](http://i.imgur.com/TtMMm.png)

Example output
---------------

These images were produced using the sample program included in this repo

[Soft filter in nice daylight](http://i.imgur.com/0OncO.jpg)

[High contrast black and white with radial blur](http://i.imgur.com/6B4iz.jpg)


