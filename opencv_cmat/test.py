from opencv_mat import CopyNumpyArray
from numpy import zeros, uint8

z = zeros((20,10,120,160), dtype=uint8)

cop = CopyNumpyArray(z, 7)

print(cop.get_arrays().shape)
