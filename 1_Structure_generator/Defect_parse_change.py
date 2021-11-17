#! ~/anaconda3/bin/python

import os
import sys
import json

#1. Defect_data.json 을 Dict 로 불러옴
with open('defect_data.json') as f:
	defect_data = json.load(f)

#2. Formation_enthalpy 파일을 출력
with open('Formation_enthalpy.dat') as f:
	print(f.read())

#3. Chemical potential 값 변경
print("*========================================================================================*")
print("| defect_data.json - Chemical potential                                                  |")
print("*========================================================================================*")
Ref_states=[]
i=0
for key, val in defect_data["mu_range"].items():
	print(f"{i}-th {key}: {val}")
	Ref_states.append(key)
	i=i+1

while True:
	Ref_index=input("Write the Reference state index to change chemical potential (Enter=Exit, ie. GaN-Ga): ")
	if Ref_index == "":
		break
	else:
		Ref_index=int(Ref_index)
	for i in defect_data["mu_range"][Ref_states[Ref_index]].keys():
		Chem=float(input(f"Write {i} chemical potential: "))
		defect_data["mu_range"][Ref_states[Ref_index]][i]=Chem

#4. Bandgap 값 변경
print("*========================================================================================*")
print("| defect_data.json - Bandgap                                                             |")
print("*========================================================================================*")
print(f"VBM: {defect_data['vbm']}")
print(f"Bandgap: {defect_data['gap']}")

with open('Bandgap.dat','r') as f:
	defect_data['vbm']=float(f.readline().strip())
	defect_data['gap']=float(f.readline().strip())
print(f"Changed into VBM:{defect_data['vbm']}, Bandgap: {defect_data['gap']}")

#5. defect_data.json 재작성
with open('defect_data.json','w') as f:
	json.dump(defect_data, f, indent=10)




