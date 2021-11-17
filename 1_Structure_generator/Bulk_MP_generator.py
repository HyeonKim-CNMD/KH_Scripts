#!~/bin/python 

import os
import shutil
from pymatgen.ext.matproj import MPRester
from pymatgen.core import structure

#1. MP DB 에서 입력한 System 의 Entries 정보를 받아옴
with MPRester("jqXXhEQv5utBHuizyo","https://materialsproject.org/rest/v2","false","false") as MPR:
    Chemsys=input("찾고자하는 물질의 Chemical system(ex. Li-Fe-O)/Formula(ex. Fe2O3)/MPID(mp-1234) 를 입력하세요: ")
    Conv_unit=input("Unitcell type 을 선택해주세요 (1: Primitive 2: Conventional) ")
    if Conv_unit == 1:
        Conv_unit=False
    if Conv_unit == 2:
        Conv_unit=True
    Materials=MPR.get_entries(Chemsys, False, "None", ['unit_cell_formula','pretty_formula','spacegroup','formation_energy_per_atom','e_above_hull','band_gap','icsd_ids','material_id','final_structure'], Conv_unit, True)   
    #2. 받아온 Entries 를 리스트로 출력
    print("{:3}: {:^20} {:^35} {:^20} {:^20} {:^20} {:^20} {:^20}".format("Num",'material_id','unit_cell_formula','spacegroup','E_form/atom','e_above_hull','band_gap','icsd_ids'))
    print("===================================================================================================================")
    for i in range(0,len(Materials)): 
        print("{:>3}: {:^20} {:^35} {:^20} {:^20} {:^20} {:^20} {:^20}".format(i,str(Materials[i].data['material_id']),str(Materials[i].data['unit_cell_formula']),str(Materials[i].data['spacegroup']['symbol']),str(Materials[i].data['formation_energy_per_atom'])[0:5],str(Materials[i].data['e_above_hull'])[0:5],str(Materials[i].data['band_gap'])[0:5],bool(Materials[i].data['icsd_ids'])))
        
    #3. 어떤 구조를 생성할 것인지 사용자 입력
    Num=int(input("어떤 구조를 생성할 지, Number 를 정수로 입력해주세요: "))
    
    #4. 해당 번호의 구조를 POSCAR 로 생성
    Materials[Num].data['final_structure'].to("poscar","POSCAR")
    Spacegroup=str(Materials[Num].data['spacegroup']['symbol']).replace("/","")
    
    with open("FolderName","w") as f:
        f.write(f"{str(Materials[Num].data['pretty_formula'])}_{str(Materials[Num].data['material_id'])}_{Spacegroup}_{str(Materials[Num].data['band_gap'])}eV")


        
