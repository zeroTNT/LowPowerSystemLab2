import numpy as np
import pandas as pd
c0 = [0.004165423, 0.0031891624, 0.0032300828]
c1 = [0.003233162, 0.0033364533, 0.00413077]
c2 = [0.007100456, 0.004762688]
c3 = [0.0048002545, 0.0017567765, 0.0025003594, 0.0021941971, 0.0027512268, 0.0025551633, 0.0026662666, 0.0025400685, 0.001385171, 0.0030838964]

def find_min1(c1):
    min = np.ones(len(c1))
    bitcount = np.ones(len(c1))
    for i in range(len(c1)): 
        for j in range(24):
            sub = 10
            bit = 1 / (2**(j+1))
            sub = abs(c2[i] - bit)
            if sub < min[i]:
                min[i] = bit
                bitcount[i] = j+1
    print(f"closed order-2 num{min}")
    print(f"and corresponding bitcount{bitcount}")

def find_min2(x):
    close = np.ones(len(x))
    mul_list = np.ones(len(x))
    for i in range(len(x)):
        a = 0
        mul = 1
        while(a < 1):
            a = int(x[i] * (2**mul))
            mul += 1
        a = 1 / (2**(mul-1))
        b = 1 / (2**mul-2)
        minusa = abs(x[i]-a)
        minusb = abs(x[i]-b)#0.0023839783
        # print(f"minusa:{minusa}, minusb:{minusb}")
        if (minusa < minusb):
            #print(f"{minusa}")
            close[i] = a
            mul_list[i] = mul - 1
            #print(f"closed order-2 num {a}, 2^-{mul-1}")
        else:
            print(f"{minusb}")
            close[i] = b
            mul_list[i] = mul
            #print(f"closed order-2 num {b}, 2^-{mul}")
    mul_maxmin = [np.max(mul_list), np.min(mul_list)]
    print(f"closed order-2 num list:\t[", end="")
    for i in close:
        print(f"{i}", end=", ")
    print(f"]")
    print(f"and corresponding bitcount max:{mul_maxmin[0]}, min:{mul_maxmin[1]}")

def read_file(file_path):
    # 讀取 CSV 檔案
    df = pd.read_csv(file_path)

    # 篩選出「項目欄位為 m/4」的列
    tensor_df = df['Tensor Name']
    string_df = []
    values = []
    for i in range(len(tensor_df)):
        string_df.append(str(tensor_df[i]).split("/"))
    for i in range(len(string_df)):
        if string_df[i][-1] == "FakeQuantWithMinMaxVarsPerChannel":
            filtered_df = df.iloc[i]
            values.append(filtered_df['Scale(s)'])
    for i in range(len(values)):
        values[i] = str(values[i]).split(",")
        for j in range(len(values[i])):
            values[i][j] = float(values[i][j])
    return values

if __name__ == "__main__":
    scales = read_file("quant_params.csv")
    for index in range(len(scales)):
        print(f"Conv Layer {index} Scale:")
        print(f"Origin num list:\t\t{scales[index]}")
        find_min2(scales[index])