#!/bin/sh

#==============================================================================================================================
echo "*--------------------------------------------------------------------------------*"
echo "|                                <Slab Analyzer>                                 |"
echo "| o Step 1 Surface Area Calculator                                               |"
echo "| o Step 2 Surface Energy analyzer                                               |"
echo "| o Step 3 Work function analyzer                                                |"
echo "*--------------------------------------------------------------------------------*"
read -p "몇번째 Step 을 진행할 지 정수로 적어주세요: " STEP
#==============================================================================================================================

if [[ $STEP == 1 ]]
then
ls
read -p "Surface Area 를 구할 구조의 이름을 입력해주세요: " Structure

Uni_Con=$(sed -n "2p" $Structure)
A_Vec=($(sed -n "3p" $Structure))
B_Vec=($(sed -n "4p" $Structure))
echo "A: " ${A_Vec[@]}
echo "B: " ${B_Vec[@]}
AA=$(echo "${A_Vec[0]}^2 + ${A_Vec[1]}^2 + ${A_Vec[2]}^2" | bc -l)
BB=$(echo "${B_Vec[0]}^2 + ${B_Vec[1]}^2 + ${B_Vec[2]}^2" | bc -l)
AB=$(echo "(${A_Vec[0]}*${B_Vec[0]} + ${A_Vec[1]}*${B_Vec[1]} + ${A_Vec[2]}*${B_Vec[2]})" |bc -l)

Surf_Area=$(echo $AA $BB $AB | awk '{print sqrt($1*$2 - $3^2)}')

echo "Surface Area of CONTCAR: " $Surf_Area "[A^2]"

elif [[ $STEP == 2 ]]
then
ls

elif [[ $STEP == 3 ]]
then
ls
python ~/KH_Scripts/1_Structure_generator/.Slab_Interlayer_Distance.py
Inter_Dis = $(cat Temp.txt)
Vac=$(echo -e "427\n3\n$Inter_Dis\n2\n" | vaspkit | grep "Maximum of macroscopic average" | cut -d":" -f2)
EF=$(grep E-fermi OUTCAR | cut -d":" -f2 | cut -d"X" -f1)
Work=$(echo "$Vac - $EF" | bc -l)
echo "Vacuum level: ${Vac} eV Fermi-level of Slab: ${EF} Work function: ${Work}"

fi