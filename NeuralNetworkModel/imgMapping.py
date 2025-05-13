from PIL import Image
import numpy as np
from pyparty import data_preprocess
def ArrayMapping():
    """
    這個函數的具體實現可以根據需求進行修改。
    """
    pass
def ImgToInferece(imagepath):
    # 開啟圖片，並轉成灰階模式（"L"）
    image = Image.open(imagepath).convert("L")
    
    image_array = np.array(image)
    image_array = image_array.reshape(1, 28, 28)  # 調整形狀為 (1, 28, 28)
    return image_array


def maxpool3x3(outcoordinate):
    # input:
    # outcoordinate: (batch, row, col) 單一個轉換後的座標陣列
    # output:
    # incoordinate: (batch, row, col) 轉換前的座標陣列
    
    # 0,0 => 1,1
    # 0,1 => 1,4
    # 0,2 => 1,7
    # 1,0 => 4,1
    # 1,1 => 4,4
    # 1,2 => 4,7
    length = outcoordinate.shape[0]
    centercoordinate = outcoordinate*3+1
    incoordinate = np.zeros((length, 3, 3, 2), dtype=int)
    for out in range(length):
        singlecoordinate = np.zeros((3, 3, 2))
        for i in range(3):
            for j in range(3):
                index = np.zeros((2), dtype=int)
                index = centercoordinate[out][0]+i-1, centercoordinate[out][1]+j-1
                singlecoordinate[i][j] = index
        incoordinate[out] = singlecoordinate
    return incoordinate
def conv3x3(outcoordinate):
    # input:
    # outcoordinate: [elements, [coordinate(2,)]] 轉換後的座標陣列
    # output:
    # incoordinate: [elements, kernel row, kernel col, corresponding input coordinate) 轉換前的座標陣列
    length = outcoordinate.shape[0]
    centercoordinate = outcoordinate+1
    incoordinate = np.zeros((length, 3, 3, 2), dtype=int)
    for out in range(length):
        singlecoordinate = np.zeros((3, 3, 2))
        for i in range(3):
            for j in range(3):
                index = np.zeros((2), dtype=int)
                index = centercoordinate[out][0]+i-1, centercoordinate[out][1]+j-1
                singlecoordinate[i][j] = index
        incoordinate[out] = singlecoordinate
    return incoordinate
def coordinate2index():
    # output:
    # conv2d1input: [cycle, hardware input position, [corresponding image coordinate]] 轉換前的座標陣列

    # conv2d_2 的 input 需要放入 24 次 3x1 的 input pixel
    conv2d2input = np.zeros((24, 3, 2), dtype=int)
    for i in range(24):
        conv2d2input[i] = np.array([[(i//6), (i%6)], [(i//6)+1, (i%6)], [(i//6)+2, (i%6)]])
    # 其中 3x1 的 pixel 會由上到下依序由前一層的 maxpooling 給予 共 24*3=72 個 pixel
    # conv2d2input 相當於 maxpooling 後的 output pixel
    
    # 依conv2d_2 input 順序排列 maxpooling output 座標
    maxpoolingoutput= np.reshape(conv2d2input, (24*3, 2))
    # maxpoolingoutput[i] = conv2d2input[i//3][i%3]
    # conv2d2input[i][j] = maxpoolingoutput[i*3+j]

    # 依照 maxpooling output pixel 回推所需要的 conv2d_1 output pixel
    maxpoolinginput = maxpool3x3(maxpoolingoutput)

    # 依 maxpooling output 順序排列 maxpooling input 座標
    conv2d1output = np.reshape(maxpoolinginput, (72, 3*3, 2))
    conv2d1output = np.reshape(maxpoolinginput, (72*9, 2))
    # maxpoolinginput[i][j][k] = conv2d1output[i*9+j*3+k]
    # conv2d1output[i] = maxpoolinginput[i//9][(i%9)//3][i%3]

    # 依照 conv2d_1 output pixel 回推所需要的 conv2d_1 input pixel
    conv2d1input = conv3x3(conv2d1output)

    # 依 conv2d_1 output 順序排列 conv2d_1 input 座標
    conv2d1input = np.reshape(conv2d1input, (648, 3*3, 2))
    # 由於 conv2d_1 的運算方式會同時輸入 9 個 inptu pixel，會同時輸出 3*3=9 個 output pixel
    # 且 conv2d_1 的 input pixel 在這 9 個 output pixel 的內部座標是相同的
    
    # 不知怎地，很剛好不用按照 conv2d_1 input 的方式重新 reshape ，就能得到 conv2d1input input 的順序
    return conv2d1input
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
    imgarray = data_preprocess(imgarray)
    
    map_coordinate = coordinate2index()
    mappeddata = Mapping(imgarray[0], map_coordinate)

    # 將 mappeddata 包裝成 9-bit 整數
    write_Activation_txt(mappeddata, folderpath='./imgMapping', filename='Activation.txt')
