import os
from pymatgen.core import surface
from pymatgen.core import structure
from pymatgen.core import lattice
from pymatgen.core import sites
import numpy as np

#1. Centrize 또는 Vacuumirize 할 구조 이름 기입
Slab_Name=input('Slab structure 파일 이름을 작성 해주세요: ')
Bulk_Name=Slab_Name
Bulk=structure.Structure.from_file(f'{os.getcwd()}/{Bulk_Name}')
Slab=surface.Structure.from_file(f'{os.getcwd()}/{Slab_Name}')

#2. 변형된 Slab의 Center 맞추기
Cell_type=input('Half cell 인지 Full cell 인지 선택해주세요 ex) H(half)/F(Full): ')
if Cell_type=="F":
    Slab=surface.center_slab(Slab)   
    print(f"Slab's center is adjusted\n")      

print(Slab)
print(Slab.as_dict())
    
#3. Vacuum level 재조정하기
Vacuum_height=input("Angstrom 단위로 Vacuum level 을 기입해주세요 ex) 15.3(Vacuum adjust)/N(No adjust, default): ")
if not Vacuum_height=="" or Vacuum_height=="N":
    Vacuum_height=float(Vacuum_height)   
  
    #4. Slab Height 구하기
    MinC,MaxC=surface.get_slab_regions(Slab)[0] #Slab 영역의 C-coordinate 최소/최대를 출력
    C_OriLen=Slab.as_dict()['lattice']['c']
    Slab_Height=(MaxC-MinC)*C_OriLen
    print(f'Slab height Calcutated: {Slab_Height}\n')

    #5. Lattice from Slab Class -> Vacuum height 수정
    Slab_Temp=Slab.as_dict()
    C_NewLen=float(Slab_Height+Vacuum_height)
    Slab_Temp['lattice']['matrix'][2][0]=(C_NewLen/C_OriLen)*Slab_Temp['lattice']['matrix'][2][0] #Angstrom 기반의 Vacuum Height 재설정
    Slab_Temp['lattice']['matrix'][2][1]=(C_NewLen/C_OriLen)*Slab_Temp['lattice']['matrix'][2][1] #Angstrom 기반의 Vacuum Height 재설정
    Slab_Temp['lattice']['matrix'][2][2]=(C_NewLen/C_OriLen)*Slab_Temp['lattice']['matrix'][2][2] #Angstrom 기반의 Vacuum Height 재설정
    C_ratio=float(C_OriLen/C_NewLen) #이동시켜야할 C axis 비율 저장
    
    #6. Sites 의 C coordination 수정
    if Cell_type=="F": #Full Cell 의 경우
        for j in range(0,len(Slab_Temp['sites'])):
            Old_C=Slab_Temp['sites'][j]['abc'][2]
            New_C=0.5+((Old_C-0.5)*C_ratio)
            Slab_Temp['sites'][j]['abc'][2]=New_C

    else: #Half_Cell 의 경우
        for j in range(0,len(Slab_Temp['sites'])):
            Old_C=Slab_Temp['sites'][j]['abc'][2]
            New_C=Old_C*C_ratio
            Slab_Temp['sites'][j]['abc'][2]=New_C

print(Slab_Temp)
    
#4. 부족한 properties 추가
Slab_Temp["miller_index"]=(1, 1, 1)
Slab_Temp["oriented_unit_cell"]=Bulk.as_dict()
Slab_Temp['shift']=0
Slab_Temp['scale_factor']=np.array([[1, 0, 0],[0, 1, 0],[0, 0, 1]])
Slab_Temp['energy']=0


    
#7. 수정된 Dict 를 가지고 Slab 재 생성
Slab_Final=surface.Slab.from_dict(Slab_Temp)
Slab_Final=Slab_Final.get_sorted_structure(None,False)
print(Slab_Final)

#8. Slab 구조 파일의 재생성
structure.IStructure.to(Slab_Final,"poscar",filename=Slab_Name)
