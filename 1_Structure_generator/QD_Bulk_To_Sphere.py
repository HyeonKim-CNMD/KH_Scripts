#!/usr/bin/env python

import os
import sys
import shutil
from pymatgen.core import structure

#1. Bulk Structure to Molecule
Bulk_File=input("What is the xyz file name of Bulk Structure? ")
Molecule=structure.IMolecule.from_file(Bulk_File)
Bulk_Num=len(Molecule.as_dict()['sites'])
print(Molecule)

#2. input Center Atom X Coordinate
Center_Num=int(input("What is the Center Atom index? "))
Center_Site=Molecule.as_dict()['sites'][Center_Num]['xyz']

#3. get Core using radius
R=0.1
Temp=0
Cores=[]
while True:
	Core=Molecule.get_sites_in_sphere(Center_Site,R)
	if len(Core) >= Bulk_Num:
		break
	if len(Core) > Temp:
		Cores.append(Core)
		Temp=len(Core)
	R=R+0.1
for i in range(0,len(Cores)):
	print(f"{i}-th core num: {len(Cores[i])}")
i=int(input("Please write index of using core num: "))
Core=Cores[i]
Core_STR=structure.IMolecule.from_sites(Core)
Core_Num=len(Core)
print(Core_STR)

#4. Get real Core Radius
Dis=[]
Center_Num=int(input("What is the Center Atom index? "))
for i in range(0,len(Core_STR.as_dict()['sites'])):
	Dis.append(Core_STR.get_distance(Center_Num,i))
CR=max(Dis)
print(f"Core Radius = {CR} [A]")

#5. get Shell using width
Shell_Num=int(input("What is the number of shell Atoms? "))
dR=0.1
while True:
	print(f"Shell width: {dR}")
	Shell=Molecule.get_neighbors_in_shell(Center_Site,CR+(dR/2),dR/2)
	if len(Shell) >= Shell_Num:
		break
	dR=dR+0.1
Shell_STR=structure.IMolecule.from_sites(Shell)
print(Shell_STR)

#6. Add Core and Shell -> QD
QD=Core + Shell
QD=structure.IMolecule.from_sites(QD)

#7. Change shell element and U to Original Atom
Shell_Atom=input("What is the Shell element? ")
Center_Atom=input("What is the Center element? ")
QD_STR=QD.as_dict()
for i in range(len(Core_STR),len(QD_STR['sites'])):
	QD_STR['sites'][i]['name']=Shell_Atom
	QD_STR['sites'][i]['species'][0]['element']=Shell_Atom
QD_STR['sites'][Center_Num]['name']=Center_Atom
QD_STR['sites'][Center_Num]['species'][0]['element']=Center_Atom
print(QD_STR)
QD=structure.IMolecule.from_dict(QD_STR)
print(QD)

#8. Get QD Radius
Dis=[]
for i in range(0,len(QD.as_dict()['sites'])):
	Dis.append(QD.get_distance(Center_Num,i))
QDR=max(Dis)
print(f"QD Radius = {QDR} [A]")

#9. Get Boxed Structure
Dis=float(input("What is the distance btw QD? [A] "))
abc=float(Dis + 2*QDR)
POS=QD.get_boxed_structure(abc,abc,abc)

#POS_STR=POS.as_dict()
#for i in range(len(Core_STR),len(POS_STR['sites'])):
#        POS_STR['sites'][i]['name']=Shell_Atom
#        POS_STR['sites'][i]['species'][0]['element']=Shell_Atom
#POS_STR['sites'][Center_Num]['name']=Center_Atom
#POS_STR['sites'][Center_Num]['species'][0]['element']=Center_Atom
#print(POS_STR)
#POS=structure.IStructure.from_dict(POS_STR)
#print(POS)

POS.to("poscar",f"POSCAR_{Center_Atom}{Core_Num}{Shell_Atom}{Shell_Num}_D{Dis:0.2f}")
