
from libs.PyImageAugmentation cimport *
from cython cimport boundscheck, wraparound, cdivision
from libcpp.vector cimport vector
from libc.string cimport memset, memcpy
from libc.stdlib cimport malloc, free
from cython.operator cimport dereference as deref
from libcpp.memory cimport unique_ptr, make_unique
from numpy cimport ndarray, uint8_t, import_array, float32_t
from numpy import  ascontiguousarray, uint8, dstack, ndarray, asarray, float32, zeros
from libc.stdlib cimport rand, RAND_MAX
ctypedef unsigned char uchar
import_array()

cdef class PyImageDataGenerator:
    cdef:
         uchar[:,:,:,:,:] final_images
         Mat * augmentedImages
         int reserve_1, reserve_2, reserve_3
    def __cinit__(self, uchar[:,:,:,:,:] image, double angle, int crop_w, int crop_h, float bright_alpha, int contrast, int noise_mean, float stdDev):
        self.reserve_1 = image.shape[0]
        self.reserve_2 = image.shape[1]
        self.reserve_3 = image.shape[2]
        self.augmentedImages = <Mat*>malloc(self.reserve_1*self.reserve_2*self.reserve_3 *sizeof(Mat))
        self.display(image, angle, crop_w, crop_h, bright_alpha, contrast, noise_mean, stdDev)
        if(self.augmentedImages==NULL):
            raise MemoryError()

    def __deallocate__(self):
        free(self.augmentedImages)
    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef void display(self, uchar[:,:,:,:,:] image, double angle, int crop_w, int crop_h, float bright_alpha, int contrast, int noise_mean, float stdDev):
        cdef:
            int i, j, k, start, end, batch, counter=0
            Mat img
            vector[int] limits
            AugmentationManager * augmented
        batch = self.reserve_1*10/100
        end =0
        limits = self.setLimits(self.reserve_1, batch)
        start = limits[0]
        limits.erase(limits.begin()+0)
        for i in range(self.reserve_1):
            random_number = self.random_number(9)
            if(self.compareInts(i, limits)):
                end = limits[0]
                print( "index", i,"start ->", start, "end ->", end)
                self.PyAugmentedImage(self.augmentedImages, image, start, end)
                start = end
                limits.erase(limits.begin()+0)
            for j in range(self.reserve_2):
                for k in range(self.reserve_3):
                    img = self.np2Mat2D(image[i,j,k])
                    augmented = new AugmentationManager(img, random_number, angle, crop_w, crop_h, bright_alpha, contrast, noise_mean, stdDev)
                    self.augmentedImages[counter] = augmented.getAugmentedImage()
                    del augmented
                    counter+=1
        if(limits.size()>0):
            end = limits[0]
            self.PyAugmentedImage(self.augmentedImages, image, start, end)
            limits.erase(limits.begin()+0)
            if( limits.size()==0):
                self.final_images = image[:]
                print("final sizes -> ", limits.size(), image.shape, self.final_images.shape)
            else:
                pass
        else:
            self.final_images = image[:]
            print("final sizes -> ", limits.size(), image.shape, self.final_images.shape)
    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef inline vector[int] setLimits(self, int end, int steps):
        cdef:
            int i =0
            vector[int] arange
        for i in range(0,end, steps):
            arange.push_back(<int>i)
            # print("values ->", i)
        arange.push_back(end)
        return arange
    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef inline bint compareInts(self, int index, vector[int]&limits):
        cdef int value
        if(limits.size()>0):
            value = limits[0]
            #print("values compared-> ", value , index)
            if(index==value):
                return True
            else:
                return False
        else:
            print("Vector is empty!")

    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef inline Mat np2Mat2D(self, uchar[:,:] image ):
        cdef ndarray[uint8_t, ndim=2, mode ='c'] np_buff = ascontiguousarray(image, dtype=uint8)
        cdef unsigned int* im_buff = <unsigned int*> np_buff.data
        cdef int r = image.shape[0]
        cdef int c = image.shape[1]
        cdef Mat m
        m.create(r, c, CV_8UC1)
        memcpy(m.data, im_buff, r*c)
        return m
    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef inline int random_number(self, int ceiling)nogil:
        return <int>(rand()%ceiling) +1;
    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef inline void Mat2np(self, Mat&m, uchar[:,:]&img_array):
        # Create buffer to transfer data from m.data
        cdef Py_buffer buf_info

        # Define the size / len of data
        cdef size_t len = m.rows*m.cols*m.elemSize()  #m.channels()*sizeof(CV_8UC3)

        # Fill buffer
        PyBuffer_FillInfo(&buf_info, NULL, m.data, len, 1, PyBUF_FULL_RO)

        # Get Pyobject from buffer data
        Pydata  = PyMemoryView_FromBuffer(&buf_info)

        # Create ndarray with data

        #print("channels ->", m.channels(), m.depth(), CV_32F)
        assert (m.channels()<2), "this function does not support images with 3 channels"
        if m.depth() == CV_32F :
            ary = ndarray(shape=(m.rows, m.cols), buffer=Pydata, order='c', dtype=float32)
        else :
            #8-bit image
            ary = ndarray(shape=(m.rows, m.cols), buffer=Pydata, order='c', dtype=uint8)

        cdef int i, j
        for i in range(m.rows):
            for j in range(m.cols):
                img_array[i,j] = ary[i,j]

    @boundscheck(True)
    @wraparound(True)
    @cdivision(True)
    cdef inline void PyAugmentedImage(self, Mat*&images, uchar[:,:,:,:,:]&original, int start, int end):
        cdef:
            int i, j, k, m, n, counter=0
            Mat img
            uchar[:,:] img_array = zeros((120,160), dtype=uint8)
        for i in range(start,end):
            for j in range(self.reserve_2):
                for k in range(self.reserve_3):
                    img = images[counter]
                    self.Mat2np(img, img_array)
                    #print("image ->", asarray(img_array).shape, counter)
                    counter+=1
                    for m in range(img.rows):
                        for n in range(img.cols):
                            original[i,j,k,m,n] = img_array[m,n]

    def getAugmentedImages(self):
        return asarray(self.final_images,dtype=float32)
