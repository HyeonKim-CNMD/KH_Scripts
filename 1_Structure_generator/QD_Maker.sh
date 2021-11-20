#!/bin/sh

#======================================================================================================================

echo "*--------------------------------------------------------------------------------*"
echo "|                               <Quantum Dot Maker>                              |"
echo "| o Step 1 Bulk POSCAR to XYZ Converter                                          |"
echo "| o Step 2 Core-Shell Maker                                                      |"
echo "| o Step 3 Please delete useless bonding using VESTA -> save xyz                 |"
echo "| o Step 4 Completed xyz to VASP Converter                                       |"
echo "*--------------------------------------------------------------------------------*"
read -p "몇번째 Step 을 진행할 지 정수로 적어주세요: " STEP

#======================================================================================================================
if [[ $STEP == 1 ]]
then

#1. POSCAR to XYZ File Convert
ls
read -p "What is the Bulk POSCAR file name?: " File
pos2xyz.pl $File

#2. Find Center atom
for((i=1;i<=$(wc $File | awk '{print $1}');i++))
do
Count_X=$(sed -n "${i}p" $File | awk '{print $1}'| grep -c 0.50)
Count_Y=$(sed -n "${i}p" $File | awk '{print $2}'| grep -c 0.50)
Count_Z=$(sed -n "${i}p" $File | awk '{print $3}'| grep -c 0.50)
if [[ $Count_X -eq 1 ]]&&[[ $Count_Y -eq 1 ]]&&[[ $Count_Z -eq 1 ]]
then
break
fi
done
echo "$(expr $i - 8) th atom is center!" $(sed -n "${i}p" $File)

#3. Change Center atom as U
Origin=$(sed -n "$(expr $i - 6)p" ${File}.xyz | awk '{print $1}')
sed -i "$(expr $i - 6)s/$Origin/U/" ${File}.xyz

elif [[ $STEP == 2 ]]
then
ls
python ~/KH_Scripts/1_Structure_generator/.QD_Bulk_To_Sphere.py

elif [[ $STEP == 4 ]]
then
ls
read -p "What is Original Structure Bulk file name? " Ori
head $Ori
read -p "What is a, b, c length or Original Structure? (ex. 1 1 1) " Lx Ly Lz
read -p "What is Modified XYZ Structure File name? " XYZ
xyz2vasp.py $Lx $Ly $Lz $XYZ
ls
read -p "What is Modified VASP Structure File name? " XYZ
head $XYZ
read -p "What is the shell element and changing element? (ex. C H = C->H) " BS AS
sed -i "1,7s/$BS/$AS/g" $XYZ
fi
