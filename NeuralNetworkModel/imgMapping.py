from PIL import Image
import numpy as np
from pyparty import data_preprocess, load_mnist_images, load_mnist_labels

def ImgToInferece(imagepath):
    # 開啟圖片，並轉成灰階模式（"L"）
    image = Image.open(imagepath).convert("L")
    
    image_array = np.array(image)
    image_array = image_array.reshape(1, 28, 28)  # 調整形狀為 (1, 28, 28)
    return image_array

def conv2d_2input():
    # Description:
    # conv2d_2 input order is specified by the hardware.
    # Output:
    # inputorder: [input order(1,), [input coordinate(2,)]] 轉換前的座標陣列
    inputorder = np.zeros((18*4, 2), dtype=int)
    for i in range(4):
        for j in range(6):
            for k in range(3):
                inputorder[i*18+j*3+k] = np.array([k+i, j])
    return inputorder

def maxpoolinginput(outcoordinate):
    # Description:
    # conv2d_1 output 9 pixels simultaneously.
    # it's means maxpooling input 9 pixels simultaneously,
    # the order in the 9 pixels is according to the conv2d_1 input.
    # conv2d_1 input 9 bits parallel and corresponding to the postion of 9 output pixels.
    # 
    # Input:
    # outcoordinate: [output order(1,), [output coordinate(2,)]] 轉換後的座標陣列
    # Output:
    # incoordinate: [input order(1,), [input coordinate(2,)]] 轉換前的座標陣列
    inputorder = np.zeros((outcoordinate.shape[0]*9, 2), dtype=int)
    for i in range(outcoordinate.shape[0]):
        for j in range(3):
            for k in range(3):
                inputorder[i*9+j*3+k] = np.array([outcoordinate[i][0]*3+j, outcoordinate[i][1]*3+k])
    # 0,0 => 0,0
    # 0,1 => 0,3
    # 0,2 => 0,6
    # 1,0 => 3,0
    # 2,0 => 6,0
    # m,n => m*3,n*3
    return inputorder

def conv2d_1input(outcoordinate):
    # Description:
    # conv2d_1 input 9 pixels simultaneously that cooresponding to output 9 pixels.
    # 
    # Input:
    # outcoordinate: [output order(1,), [output coordinate(2,)]] 轉換後的座標陣列
    # Output:
    # incoordinate: [cycle(648,), input order(9,), [input coordinate(2,)]] 轉換前的座標陣列
    inputorder = np.zeros((648, 9, 2), dtype=int) # manual setting
    for maxpool_block in range(outcoordinate.shape[0]//9):
        block = outcoordinate[maxpool_block*9]
        # 0,0 => 0,0
        # 0,3 => 0,3
        # 0,6 => 0,6
        # 0,9 => 0,9
        # 3,0 => 3,0
        # 6,0 => 6,0
        # m,n => m,n
        start_row = block[0]
        start_col = block[1]
        for conv_row in range(3):
            for conv_col in range(3):
                for i in range(3):
                    for j in range(3):
                        inputorder[maxpool_block*9+conv_row*3+conv_col][i*3+j] =\
                        np.array([start_row+conv_row+i, start_col+conv_col+j])
    return inputorder

def Mapping(ImageArray, conv2d1input):
    # input:
    # ImageArray: 2維陣列，代表一張圖片的灰階
    # conv2d1input: [cycle, hardware input position, corresponding image coordinate]
    # output:
    # mappedinput: [cycle, 9-bit input] 轉換後的座標陣列
    mappedinput = np.zeros((conv2d1input.shape[0], conv2d1input.shape[1]), dtype=int)
    for i in range(conv2d1input.shape[0]):
        input_value = []
        for j in range(conv2d1input.shape[1]):
            # 取出對應的座標
            coordinate = conv2d1input[i][j]
            # 取得對應的像素值
            single_pixel_value = ImageArray[coordinate[0]][coordinate[1]]

            # 將像素值轉換為 9-bit 整數
            input_value.append(single_pixel_value)
        mappedinput[i] = np.array(input_value, dtype=int)
    return mappedinput

def write_Activation_txt(data, folderpath='./', filename='output.mem'):
    if not folderpath.endswith('/'):
        folderpath += '/'
    with open(folderpath+filename, "w") as f:
        for bitstream in data:
            for value in bitstream:
                f.write(f"{value:1b}")
            f.write("\n")

if __name__ == "__main__":
    # 轉換圖片為陣列
    imagepath = "./imgMapping/test1.jpg"
    imgarray = ImgToInferece(imagepath)

    # from MNIST dataset
    imgarray = load_mnist_images("t10k-images.idx3-ubyte")
    y_test = load_mnist_labels("t10k-labels.idx1-ubyte")
    print(y_test[9993])
    # data preprocess
    imgarray = np.array(imgarray[9993])
    imgarray = np.transpose(imgarray, (2, 0, 1))
    imgarray = data_preprocess(imgarray)
    # Generate the mapping coordinate
    map_coordinate = conv2d_2input()
    map_coordinate = maxpoolinginput(map_coordinate)
    map_coordinate = conv2d_1input(map_coordinate)

    mappeddata = Mapping(imgarray[0], map_coordinate)

    # 將 mappeddata 包裝成 9-bit 整數
    write_Activation_txt(mappeddata, folderpath='./imgMapping', filename='Activation.txt')
    