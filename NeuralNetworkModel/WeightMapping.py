from typing import List, Dict
import numpy as np
# Load the weights and scales for the convolutional layers
def load_weights(
        folder_path: str = "./",
        npy_list: List[str] = None
        ) -> Dict[str, np.ndarray]:
    if npy_list is None:
        raise ValueError("npy_list must be provided")
    if not isinstance(npy_list, list) or not all(isinstance(f, str) for f in npy_list):
        raise TypeError("file_list 必須是字串組成的 list")
    if not isinstance(folder_path, str):
        raise TypeError("folder_path 必須是字串")
    weights = {}
    for npy_file in npy_list:
        weights[npy_file] = np.load(f"{folder_path}/{npy_file}")
    return weights

def weight_flatten(weights_list: Dict[str, np.ndarray] = None
                   ) -> np.ndarray: #numpy order: [outC,row,col,inC]
    flatten_weights = []
    merged_array = np.array([])
    for npy_list in weights_list.values():
        if len(npy_list.shape) != 4:
            raise ValueError("weights must all be 4D array")
        # Convert the weights to specific shape [outC, inC, row, col]
        weights = np.transpose(npy_list, (0, 3, 1, 2))
        # weights.shape = (i0, i1, i2, i3)
        # weights.flatten() like following nested for loop:
        # for i0 in range(i0):
        #   for i1 in range(i1):
        #       for i2 in range(i2):
        #           for i3 in range(i3):
        #               weights[i0][i1][i2][i3]
        weights = weights.flatten()
        flatten_weights.append(weights)
    
    if flatten_weights:
        merged_array = np.concatenate(flatten_weights)
    return merged_array

def pack_int8_to_16bit(array: np.ndarray,
                        output_folder: str = "./kernels",
                        filename: str = "Weight.txt") -> None:
    if array.ndim != 1:
        raise ValueError("只接受 1D 陣列")
    if array.dtype != np.int8:
        raise ValueError("陣列必須是 int8 格式")
    
    # 確保長度是偶數（補 1 個 0）
    if len(array) % 2 != 0:
        array = np.append(array, 0)

    with open(f"{output_folder}/{filename}", 'w') as f:
        for i in range(0, len(array), 2):
            high = int(array[i]) & 0xFF  # 保持 8-bit
            low  = int(array[i+1]) & 0xFF
            combined = (high << 8) | low
            f.write(f"{combined:04x}\n")

if __name__ == "__main__":
    folder_path = "./kernels"
    npy_list = [
        "conv2d_0int.npy",
        "conv2d_1int.npy",
        "conv2d_2int.npy"]
    npy_dict = load_weights(folder_path=folder_path, npy_list=npy_list)
    npy = npy_dict["conv2d_0int.npy"]
    # print(f"Loaded weights:\n {npy}")
    weights = weight_flatten(npy_dict)
    # print(f"Flattened weights:\n {weights}")
    pack_int8_to_16bit(weights, output_folder=folder_path, filename="Weight.txt")
    