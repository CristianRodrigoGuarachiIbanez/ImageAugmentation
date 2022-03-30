# distutils: language = c++
from libc.stdlib cimport rand, RAND_MAX
from libcpp.vector cimport vector
from libc.string cimport memcpy
from libcpp.string cimport string
from PIL import Image
import imgaug as ia
import imgaug.augmenters as iaa
from cython cimport boundscheck, wraparound
from numpy cimport ndarray, uint8_t, float64_t
from numpy import copy, asarray, ascontiguousarray, uint8, float32, float64, uint8
ctypedef unsigned char uchar
cdef class ImgAugmentation:
    cdef:
        double[:,:,:,:,:]images
        uchar[:,:] image
        unsigned int d,d1,d2
    def __cinit__(self, double[:,:,:,:,:] imgs, int rotation_range, float horizontal_flip, float vertical_flip,
                                int shear_range, int zoom_range, int noise_range, float bright_range ):
        #self.open_file(path)
        self.images = imgs[:]
        #print("shape: ",self.images.shape)
        if(self.images.size!=0):
            self.d = self.images.shape[0]
            self.d1 = self.images.shape[1]
            self.d2 = self.images.shape[2]
            #print("shape", self.d, self.d1, self.d2)
            self.select_algorithm(rotation_range, horizontal_flip, vertical_flip, shear_range, zoom_range, noise_range, bright_range)

    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef void open_file(self, string path):
        try:
            image = Image.open(path)
        except Exception as e:
            print(e)
        self.images = asarray(image, dtype=float64)
        #print(self.image.shape)

    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef int random_number(self) nogil:
        cdef int num = (rand() % 7 +1) #1 + rand()/(RAND_MAX*6.0)
        return num

    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef void select_algorithm(self, int rotation_range, float horizontal_flip, float vertical_flip,
                                int shear_range, int zoom_range, int noise_range, float bright_range ):

        cdef:
            unsigned int i,j,k
            uchar[:,:] image
            unsigned int rand_num
        for i in range(self.d):
            rand_num = int(self.random_number())
            for j in range(self.d1):
                for k in range(self.d2):
                    print("shapes", self.images[i,j,k].shape)
                    image = asarray(self.images[i,j,k], dtype=uint8)
                    self._select_algorithm(image, rand_num, rotation_range, horizontal_flip, vertical_flip, shear_range, zoom_range,
                                            noise_range, bright_range )
                    print(self.image.shape)
    cdef void _select_algorithm(self, uchar[:,:]img, int rand_num, int rotation_range, float horizontal_flip, float vertical_flip,
                                int shear_range, int zoom_range, int noise_range, float bright_range):
        print("rand number", rand_num)
        if (rand_num == 1):
            return self._rotation(img, -50, rotation_range)
        elif (rand_num == 2):
            return self._flipping(img, horizontal_flip)
        elif (rand_num == 3):
            return self._shearing(img, 0, shear_range)
        elif (rand_num == 4):
            return self._flipup(img, vertical_flip)
        elif (rand_num == 5):
            return self._cropping(img, 0.0, zoom_range)
        elif (rand_num == 6):
            return self._add_noise(img, noise_range, noise_range * 2)
        elif (rand_num == 7):
            return self._brightness(img, bright_range)

    cdef ndarray[uint8_t,ndim=2]  _rotation(self, uchar[:,:] image, int e_1, int e_2):
        rotate = iaa.Affine(rotate=(e_1, e_2));
        return rotate.augment_image(image)
    cdef ndarray[uint8_t,ndim=2]  _flipping(self, uchar[:,:] image, float p):
        flip_hr = iaa.Fliplr(p=p)
        return flip_hr.augment_image(image)
    cdef ndarray[uint8_t,ndim=2] _shearing(self, uchar[:,:] image, int strength=1, int shift_axis=0, int increase_axis=1):
        cdef:
            uchar[:,:] res

        if(shift_axis > increase_axis):
            shift_axis -= 1
        res = empty_like(a)
        index = index_exp[:] * increase_axis
        rolling = roll
        for i in range(0, a.shape[increase_axis]):
            index_i = index + (i,)
            #print(index_i)
            res[index_i] = rolling(a[index_i], -i * strength, shift_axis)
        return res
    cdef ndarray[uint8_t,ndim=2]  _flipup(self, uchar[:,:] image, float p ):
        flip_vr = iaa.Flipud(p=p)
        return flip_vr.augment_image(image)
    cdef ndarray[uint8_t,ndim=2]  _cropping(self, uchar[:,:] image, float per_1, float per_2):
        crop = iaa.Crop(percent=(per_1, per_2))  # crop image
        return crop.augment_image(image)
    cdef ndarray[uint8_t,ndim=2] _brightness(self, uchar[:,:] image, float gamma):
        contrast = iaa.GammaContrast(gamma=gamma)
        self.image = contrast.augment_image(image)
    cdef ndarray[uint8_t,ndim=2]  _add_noise(self, uchar[:,:] image, int elem_1, int elem_2):
        gaussian_noise = iaa.AdditiveGaussianNoise(elem_1, elem_2)
        return gaussian_noise.augment_image(image)

    def get_image(self):
        return self.images
    def get_rand_num(self):
        return int(self.random_number())