import os
import re
from math import sqrt
from math import gcd
from pymatgen.core import surface
from pymatgen.core import structure
from pymatgen.core import lattice
from pymatgen.core import sites
import numpy as np

# Layer 를 확인할 구조 이름 기입
Slab_Name = input('Slab structure 파일 이름을 작성 해주세요: ')
Bulk_Name = Slab_Name
Bulk = structure.Structure.from_file(f'{os.getcwd()}/{Bulk_Name}')
Slab = surface.Structure.from_file(f'{os.getcwd()}/{Slab_Name}')
print("======================================================================================================================================================")
print("Initial Slab Information")
print("======================================================================================================================================================")
print(Slab)
print(Slab.as_dict())

# 2. C-axis coordinate를 기준으로 Sorting
Slab_Temp = Slab.as_dict()
Elements = []
for i in range(0, len(Slab_Temp['sites'])):
    Slab_Temp['sites'][i]['label'] = i
    Elements.append((Slab_Temp['sites'][i]['species'][0]['element'], i,
                     Slab_Temp['lattice']['c'] * Slab_Temp['sites'][i]['abc'][2]))
Elements.sort(key=lambda x: x[2], reverse=True)

# 3. 10^-6 을 기준으로 1 Layer 단위로 원소를 묶음
Layer = [Elements[0]]
for i in range(0, len(Elements) - 1):
    if Elements[i][2] - Elements[i + 1][2] < 0.000001 and Elements[i][2] - Elements[i + 1][2] > -0.000001:
        Layer[-1] = Layer[-1] + Elements[i + 1]
    else:
        Layer.append(Elements[i + 1])

# 4. Layer 단위로 원소를 출력
print("======================================================================================================================================================")
print("Layers of the Slab Structure")
print("======================================================================================================================================================")
print("{0:<10} | {1:<100}".format("Layer Idx", "Element, Element number, C"))
print("------------------------------------------------------------------------------------------------------------------------------------------------------")
for i in range(0, len(Layer)):
    print("{0:<10} | {1:<100}".format(f"Layer {i}", str(Layer[i])))

# 5. 1 FU를 구조로부터 추출
Comp = []
FU = []
Temp_list = Slab.formula.split(' ')
for i in Temp_list:
    Comp = Comp + re.findall("\D+", i)
    FU = FU + re.findall("\d+", i)
FU = list(map(int, FU))
if len(FU) == 1:
    Num_FU = FU[0]
elif len(FU) == 2:
    Num_FU = gcd(*FU)
else:
    Num_FU = gcd(FU[0], FU[1])
    for i in range(2, len(FU)):
        Num_FU = gcd(Num_FU, FU[i])

FU = [int(x / Num_FU) for x in FU]

# 6. 1 FU 를 기준으로 Fixed Layer 표시
print("======================================================================================================================================================")
Cen_Layer = input("대칭성에 주의 하여 Slab Center Layer 의 Index 를 입력해주세요(ex. layer 26=26, Layer 26 + Layer 27 =26 27: ").split()
print("======================================================================================================================================================")
Cen_Layer_U = int(Cen_Layer[0])
Cen_Layer_D = int(Cen_Layer[-1])

if Cen_Layer_U < len(Layer) - Cen_Layer_D - 1:
    Max = Cen_Layer_U
else:
    Max = len(Layer) - Cen_Layer_D - 1

FU_Layer = [0] * Num_FU
for i in range(1, Max + 1):
    Comp_Temp = [0] * len(FU)

    for j in Layer[Cen_Layer_U - i:Cen_Layer_D + i + 1]:
        for k in range(0, len(FU)):
            Comp_Temp[k] = Comp_Temp[k] + j.count(Comp[k])
    print(f"# of {Comp} Elements in fixed Layers: {Comp_Temp}")

    for j in range(0, Num_FU):
        Sat = 0
        for k in range(0, len(FU)):
            if Comp_Temp[k] <= (j + 2) * FU[k] and Comp_Temp[k] >= (j + 1) * FU[k]:
                Sat += 1
                if Sat == len(FU) and FU_Layer[j] == 0:
                    FU_Layer[j] = i
            else:
                break
print(FU_Layer)

print("======================================================================================================================================================")
print("Layers of the Slab Structure")
print("======================================================================================================================================================")
print("{0:<10} | {1:<100}".format("Layer Idx", "Element, Element number, C"))
print("------------------------------------------------------------------------------------------------------------------------------------------------------")
for i in range(0, len(Layer)):
    if i in range(Cen_Layer_U, Cen_Layer_D + 1):
        print("{0:<10} | {1:<100} {2:<10}".format(f"Layer {i}", str(Layer[i]), "[Center]"))
    else:
        for j in range(0, Num_FU):
            if i in range(Cen_Layer_U - FU_Layer[j], Cen_Layer_D + FU_Layer[j] + 1):
                print("{0:<10} | {1:<100} {2:<10}".format(f"Layer {i}", str(Layer[i]), f"[{j + 1}FU_Layer]"))
                break
            elif j == Num_FU - 1:
                print("{0:<10} | {1:<100}".format(f"Layer {i}", str(Layer[i])))

# 7. 모든 Layer 에 Selective Dynamics 추가 및 Fixed Layer 의 고정
print("======================================================================================================================================================")
Temp = input("고정할 Layer 의 범위를 입력해주세요. (ex. Layer 13 ~ Layer 26 고정=13 26 입력) (Enter 키 입력시 1FU Layer Fix): ")
if Temp == "":
    Sel = []
    for i in range(Cen_Layer_U - FU_Layer[0], Cen_Layer_D + FU_Layer[0] + 1):
        Sel = Sel + list(Layer[i][1:len(Layer[i]):3])
    print(f"Fixed Layer(1FU Layer) 의 Element 번호 : {Sel}")
else:
    Upper_Fix, Lower_Fix = map(int, Temp.split())
    Sel = []
    for i in range(Upper_Fix, Lower_Fix + 1):
        Sel = Sel + list(Layer[i][1:len(Layer[i]):3])
    print(f"Fixed Layer(1FU Layer) 의 Element 번호 : {Sel}")

for i in range(0, len(Slab_Temp['sites'])):
    Slab_Temp['sites'][i]['properties'] = {'selective_dynamics': [True, True, True]}

for i in Sel:
    for j in range(0, len(Slab_Temp['sites'])):
        if i == Slab_Temp['sites'][j]['label']:
            Slab_Temp['sites'][j]['properties'] = {'selective_dynamics': [False, False, False]}
            break

# 8. 제거할 Layer 의 범위 설정 및 제거
print("======================================================================================================================================================")
Upper_Del, Lower_Del=map(int, input("남겨둘 Layer 의 범위를 입력해주세요 (ex. Layer 13 ~ Layer 26 보존=13 26 입력): ").split())
Del=[]
for i in range(0,Upper_Del):
    Del=Del+list(Layer[i][1:len(Layer[i]):3])
for i in range(Lower_Del+1,len(Layer)):
    Del=Del+list(Layer[i][1:len(Layer[i]):3])
print(f"지워지게 될 Element 위치: {Del}")
for i in Del:
    for j in range(0,len(Slab_Temp['sites'])):
        if i == Slab_Temp['sites'][j]['label']:
            del(Slab_Temp['sites'][j])
            break

Slab_Temp["miller_index"] = (1, 1, 1)
Slab_Temp["oriented_unit_cell"] = Bulk.as_dict()
Slab_Temp['shift'] = 0
Slab_Temp['scale_factor'] = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]])
Slab_Temp['energy'] = 0
Slab = surface.Slab.from_dict(Slab_Temp)
Slab = Slab.get_sorted_structure(None, False)

# 9. Vacuum distance 가 바뀌는 Slab Generation
S_Dis, E_Dis, I_Dis=input("Convergence 를 확인할 Vacuum distance 의 Start_Distance, End_Distance, Distance 증가를 입력해주세요 (ex. 8 14 1= 8~14까지 1[A] 씩 증가): ").split(" ")
Cell_type=input("Full cell 의 경우 F(or Enter), Half cell 의 경우 H 를 입력해주세요: ")
Filename1 = Slab_Name.split('g')[0] + "g"
Filename2 = Slab_Name.split('g')[1].split('_')[1]
os.system(f"echo '{S_Dis} {E_Dis} {I_Dis} {Filename1} {Filename2}' > Temp.txt")
for k in range(int(S_Dis), int(E_Dis)+1, int(I_Dis)):
    Vacuum_height=float(k)
    Slab_Temp2 = Slab_Temp
    MinC, MaxC = surface.get_slab_regions(Slab)[0]  # Slab 영역의 C-coordinate 최소/최대를 출력
    C_OriLen = Slab_Temp2['lattice']['c']
    Slab_Height = (MaxC - MinC) * C_OriLen
    C_NewLen = float(Slab_Height + Vacuum_height)
    C_ratio = float(C_OriLen / C_NewLen)  # 이시켜야할 C axis 비율 저장

    Slab_Temp2['lattice']['matrix'][2][0] = (C_NewLen / C_OriLen) * Slab_Temp2['lattice']['matrix'][2][0]  # Angstrom 기반의 Vacuum Height 재설정
    Slab_Temp2['lattice']['matrix'][2][1] = (C_NewLen / C_OriLen) * Slab_Temp2['lattice']['matrix'][2][1]  # Angstrom 기반의 Vacuum Height 재설정
    Slab_Temp2['lattice']['matrix'][2][2] = (C_NewLen / C_OriLen) * Slab_Temp2['lattice']['matrix'][2][2]  # Angstrom 기반의 Vacuum Height 재설정
    if Cell_type == "N":  # Half Cell 의 경우
        for j in range(0, len(Slab_Temp2['sites'])):
            Old_C = Slab_Temp2['sites'][j]['abc'][2]
            New_C = Old_C * C_ratio
            Slab_Temp2['sites'][j]['abc'][2] = New_C
    else:  # Full_Cell 의 경우
        for j in range(0, len(Slab_Temp2['sites'])):
            Old_C = Slab_Temp2['sites'][j]['abc'][2]
            New_C = 0.5 + ((Old_C - 0.5) * C_ratio)
            Slab_Temp2['sites'][j]['abc'][2] = New_C

    print("======================================================================================================================================================")
    Slab_Temp2["miller_index"] = (1, 1, 1)
    Slab_Temp2["oriented_unit_cell"] = Bulk.as_dict()
    Slab_Temp2['shift'] = 0
    Slab_Temp2['scale_factor'] = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]])
    Slab_Temp2['energy'] = 0

    # 10. 수정된 Dict 를 가지고 Slab 재 생성
    Slab_Final = surface.Slab.from_dict(Slab_Temp2)
    Slab_Final = Slab_Final.get_sorted_structure(None, False)
    print(Slab_Final)

    # 11. Slab 구조 파일의 재생성
    structure.IStructure.to(Slab_Final, "poscar", filename=f"{Filename1}{k}_{Filename2}")