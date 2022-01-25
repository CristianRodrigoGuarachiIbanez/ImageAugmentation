# distutils: language = c++

from libcpp.vector cimport vector
from libc.string cimport memcpy
from cython cimport boundscheck, wraparound
from libc.stdlib cimport malloc, free
from numpy cimport ndarray, uint8_t
from numpy import copy, asarray, ascontiguousarray, uint8, float32, dstack, ndarray

from opencv_mat cimport *
ctypedef unsigned char uchar


cdef class CopyNumpyArray:
    cdef:
        vector[vector[vector[Mat]]] mat_arrays
        int dim,dim1,r,c,n_copies
    def __cinit__(self, uchar[:,:,:,:] data, int copies):
        self.dim = data.shape[0]
        self.dim1 = data.shape[1]
        self.r = data.shape[2]
        self.c = data.shape[3]
        self.n_copies = copies
        self.copy_imgArray(data, copies)
    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef Mat np2Mat2D(self, uchar[:,:] data):
        assert (data.ndim==2), "ASSERT::1 channel grayscale only!!"

        cdef ndarray[uint8_t, ndim=2, mode ='c'] np_buff = ascontiguousarray(data, dtype=uint8)
        cdef unsigned int* im_buff = <unsigned int*> np_buff.data

        cdef Mat m
        m.create(self.r, self.c, CV_8UC1)
        memcpy(m.data, im_buff, self.r*self.c)
        return m
    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef void copy_imgArray(self, uchar[:,:,:,:] data, int c):
        cdef:
            int i,j
            #Mat img
            Mat copied
            vector[vector[Mat]] imgs
            vector[Mat] copies

        for i in range(self.dim):
            for j in range(self.dim1):
                img = self.np2Mat2D(data[i,j,:,:])
                for _ in range(c):
                    #img.copyTo(copied)
                    copies.push_back(img)
                    #print(img.cols, img.rows)
                imgs.push_back(copies)
                copies.clear()
                #print(imgs.size())
            self.mat_arrays.push_back(imgs)
            imgs.clear()
            #print(self.mat_arrays.size())

    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef object Mat2np(self, Mat m):
        # Create buffer to transfer data from m.data
        cdef Py_buffer buf_info
        # Define the size / len of data
        cdef size_t len = m.rows*m.cols*m.elemSize()#m.channels()*sizeof(CV_8UC3)
        # Fill buffer
        PyBuffer_FillInfo(&buf_info, NULL, m.data, len, 1, PyBUF_FULL_RO)
        # Get Pyobject from buffer data
        Pydata  = PyMemoryView_FromBuffer(&buf_info)

        # Create ndarray with data
        # the dimension of the output array is 2 if the image is grayscale
        if m.channels() >1 :
            shape_array = (m.rows, m.cols, m.channels())
        else:
            shape_array = (m.rows, m.cols)

        if m.depth() == CV_32F :
            ary = ndarray(shape=shape_array, buffer=Pydata, order='c', dtype=float32)
        else :
        #8-bit image
            ary = ndarray(shape=shape_array, buffer=Pydata, order='c', dtype=uint8)

        if m.channels() == 3:
            # BGR -> RGB
            ary = dstack((ary[...,2], ary[...,1], ary[...,0]))

        # Convert to numpy array
        pyarr = asarray(ary)
        return pyarr

    @boundscheck(False)  # Deactivate bounds checking
    @wraparound(False)
    cdef ndarray[uint8_t, ndim=4] vec2np(self):
        #print(self.mat_arrays.size(), self.n_copies)
        cdef int i,j,k
        arrays = []
        for i in range(self.dim):
            seq = []
            for j in range(self.dim1):
                copies=[]
                for k in range(self.n_copies):
                    #print(self.Mat2np(self.mat_arrays[i][j][k]).shape)
                    copies.append(self.Mat2np(self.mat_arrays[i][j][k]))
                seq.append(copies)
            arrays.append(seq)
        return asarray(arrays, dtype=uint8)

    def get_arrays(self):
        return self.vec2np()