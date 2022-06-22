


# PyImageAugmentation 

This python implementation helps you with augmenting images for machine learning projects. 
It converts a set of input images into a new, much larger set of slightly altered images based on standard augmentation techniques.


## Features

  - Augmentation techniques
    - E.g. affine transformations (shearing), perspective transformations (rotation, flipping), contrast changes, gaussian noise, dropout of regions, hue/saturation changes, cropping/padding, ...
    - Optimized for high performance
    - Easy to apply augmentations only to some images
    - Easy to apply augmentations in random order
  - Support for
    - Images (full support for uint8, for other dtypes see documentation)
    - Heatmaps (float32), Segmentation Maps (int), Masks (bool)
    - Keypoints/Landmarks (int/float coordinates)
    - Bounding Boxes (int/float coordinates)
  - Many helper functions
     - Example: Draw heatmaps, segmentation maps, keypoints, bounding boxes, ...
     - Example: Scale segmentation maps, average/max pool of images/maps, pad images to aspect ratios (e.g. to square them)
     - Example: Convert keypoints to distance maps, extract pixels within bounding boxes from images, clip polygon to the image plane, ...
  - Support for augmentation on multiple CPU cores


## Dependencies

 * [numpy]
 * [cython]
 * [OpenCV]

## Setup

This implementation supports python 3.4+.

To use it, you should clone the repository and place it on your local directory.
Now, go into the folder

    "/ImageAugmentation"

There, perform the following commands on the terminal:

    python3.? setup.py build_ext --inplace



