#!/bin/sh

function Check_relax {
Folders=($(find . -maxdepth 1 -type d))
E_Last=$(grep "TOTEN" ${Folders[-1]}/OUTCAR -s -R -n | tail -1 | cut -d"=" -f2 | cut -d"e" -f1)
for d in ${Folders[@]}
do
if [[ -a $d/relax.out ]]
then
  Dir_Name2=$(echo $d | rev | cut -d"/" -f1 | rev)
  Dir_Name1=$(echo $d | rev | cut -d"/" -f2 | rev)
  D=${Dir_Name1}/${Dir_Name2}
	M=$(grep "mag=" $d/relax.out -s -R -n | tail -1 | cut -d"=" -f5 )
	E=$(grep "TOTEN" $d/OUTCAR -s -R -n | tail -1 | cut -d"=" -f2 | cut -d"e" -f1)
	T=$(grep LOOP: $d/OUTCAR | awk 'BEGIN{time=0}{time+=$7}END{print time/NR}')

	if [[ $(grep "reached required accuracy - stopping structural energy minimisation" $d/relax.out) ]]
	then
		echo "$D : Relaxed!   $E $E_Last Time: $T Mag= $M"
	elif [[ $(grep "ERROR" $d/relax.out) ]]||[[ $(grep "error" $d/relax.out) ]]
	then
		echo "$D : Un-relaxed $E $E_Last Time: $T Mag= $M"
	else
		echo "$D : Proceeding $E $E_Last Time: $T Mag= $M"
	fi
fi

done
}

function Layer_relax {
Folders=($(find . -maxdepth 1 -type d))
Last_Fold=$(echo ${Folders[-1]} | rev | cut -d"/" -f1 | rev)
Slab_E_Last=$(grep "TOTEN" ${Folders[-1]}/OUTCAR -s -R -n | tail -1 | cut -d"=" -f2 | cut -d"e" -f1)
for d in ${Folders[@]}
do
if [[ -a $d/relax.out ]]
then
  Nodes=$1
	Bulk_E=$2
	Surf_Area=$3
  D=$(echo $d | rev | cut -d"/" -f1 | rev)
	M=$(grep "mag=" $d/relax.out -s -R -n | tail -1 | cut -d"=" -f5 )
	Slab_E=$(grep "TOTEN" $d/OUTCAR -s -R -n | tail -1 | cut -d"=" -f2 | cut -d"e" -f1)
	T=$(grep LOOP: $d/OUTCAR | awk 'BEGIN{time=0}{time+=$7}END{print time/NR}')
	T=$(echo "$T*$Nodes" | bc -l)
	Surf_E=$(echo "($Slab_E - $Bulk_E * $D)*16.0219/2/$Surf_Area" | bc -l)
	Surf_E_Last=$(echo "($Slab_E_Last - $Bulk_E * $Last_Fold)*16.0219/2/$Surf_Area" | bc -l)

	if [[ $(grep "reached required accuracy - stopping structural energy minimisation" $d/relax.out) ]]
	then
		echo "$D : Relaxed!   Slab_E: $Slab_E Slab_E_Last: $Slab_E_Last Surf_Area: $Surf_Area Surf_E: $Surf_E Surf_E_Last: $Surf_E_Last Time: $T Mag= $M"
	elif [[ $(grep "ERROR" $d/relax.out) ]]||[[ $(grep "error" $d/relax.out) ]]
	then
		echo "$D : Un-relaxed Slab_E: $Slab_E Slab_E_Last: $Slab_E_Last Surf_Area: $Surf_Area Surf_E: $Surf_E Surf_E_Last: $Surf_E_Last Time: $T Mag= $M"
	else
		echo "$D : Proceeding Slab_E: $Slab_E Slab_E_Last: $Slab_E_Last Surf_Area: $Surf_Area Surf_E: $Surf_E Surf_E_Last: $Surf_E_Last Time: $T Mag= $M"
	fi
fi

done
}

function Surf_Area_Cal {
Uni_Con=$(sed -n "2p" $1)
A_Vec=($(sed -n "3p" $1))
B_Vec=($(sed -n "4p" $1))
echo "A: " ${A_Vec[@]}
echo "B: " ${B_Vec[@]}
AA=$(echo "${A_Vec[0]}^2 + ${A_Vec[1]}^2 + ${A_Vec[2]}^2" | bc -l)
BB=$(echo "${B_Vec[0]}^2 + ${B_Vec[1]}^2 + ${B_Vec[2]}^2" | bc -l)
AB=$(echo "(${A_Vec[0]}*${B_Vec[0]} + ${A_Vec[1]}*${B_Vec[1]} + ${A_Vec[2]}*${B_Vec[2]})" |bc -l)

Surf_Area=$(echo $AA $BB $AB | awk '{print sqrt($1*$2 - $3^2)}')

echo "Surface Area of CONTCAR: " $Surf_Area "[A^2]"
}

#==============================================================================================================================
echo "*--------------------------------------------------------------------------------*"
echo "|                                <Slab Analyzer>                                 |"
echo "| o Step 1 Vacuum distance convergence plot                                      |"
echo "| o Step 2 Surface Area Calculator                                               |"
echo "| o Step 3 Surface Energy convergence plot                                       |"
echo "| o Step 4 Work function analyzer                                                |"
echo "*--------------------------------------------------------------------------------*"
read -p "????????? Step ??? ????????? ??? ????????? ???????????????: " STEP
#==============================================================================================================================

if [[ $STEP == 1 ]]
then
Check_rlx
head $(find . -maxdepth 1 -mindepth 1 -type d | head -1)/POSCAR
read -p "Write Number of Formula units of Structure!: " FU
read -p "Write the name of material: " Material
Check_relax | cut -d"/" -f2 > V_Conv.dat
echo "plot 'V_Conv.dat' using 1:(\$5-\$4)/$FU axis x1y1 title 'Energy' with linespoints lw 2 lc 'dark-pink' ps 1 pt 7, 'V_Conv.dat' using 1:7 axis x1y2 title 'Time' with linespoints lw 2 lc 'royalblue' ps 1 pt 7
set termopt enhanced
set title 'Vacuum distance convergence test of ${Material}'
set xlabel 'Vacuum distance [A]'
set ylabel 'Energy difference [eV/FU]'
set y2label 'Time per Electronic step [Sec]'
set xrange[:]
set yrange[-0.001:0.001]
set y2range[:]
set y2tics
set ytics nomirror
set key on inside top right nobox
set term pngcairo size 640,480.00000000000000000000 enhanced font 'Helvetica, 14'
set output 'V_Conv_0.001eV.png'
replot" > V_Conv.gnu
gnuplot V_Conv.gnu
sed -i "s/0.001/0.01/g" V_Conv.gnu
gnuplot V_Conv.gnu

elif [[ $STEP == 2 ]]
then
ls
read -p "Surface Area ??? ?????? ????????? ????????? ??????????????????: " Structure
Surf_Area_Cal $Structure

elif [[ $STEP == 3 ]]
then
ls
Check_rlx
head $(find . -maxdepth 1 -mindepth 1 -type d | head -1)/run.sh
read -p "Write the number of node used: " Nodes
read -p "Write the name of material: " Material
read -p "Write Bulk structure energy per Formula unit: " Bulk
Surf_Area_Cal $(find . -maxdepth 1 -mindepth 1 -type d | head -1)/POSCAR
read -p "Write Slab surface area: " Surf_Area
Layer_relax $Nodes $Bulk $Surf_Area > L_Conv.dat

echo "plot 'L_Conv.dat' using 1:(\$13-\$11) axis x1y1 title 'Energy' with linespoints lw 2 lc 'dark-pink' ps 1 pt 7, 'L_Conv.dat' using 1:15 axis x1y2 title 'Time' with linespoints lw 2 lc 'royalblue' ps 1 pt 7
set termopt enhanced
set title 'Layer thickness convergence test of ${Material}'
set xlabel 'Number of Layers'
set ylabel \"Surface Energy difference [J/m^2]\"
set y2label 'Time per Electronic step [Sec]'
set xrange[:]
set yrange[-0.001:0.001]
set y2range[:]
set y2tics
set ytics nomirror
set key on inside top right nobox
set term pngcairo size 640,480.00000000000000000000 enhanced font 'Helvetica, 14'
set output 'L_Conv_0.001eV.png'
replot" > L_Conv.gnu
gnuplot L_Conv.gnu
sed -i "s/0.001/0.01/g" L_Conv.gnu
gnuplot L_Conv.gnu

elif [[ $STEP == 4 ]]
then
ls
python ~/KH_Scripts/4_Analyzer/.Slab_Interlayer_Distance.py
Inter_Dis=$(cat Temp.txt)
Vac=$(echo -e "427\n3\n$Inter_Dis\n2\n" | vaspkit | grep "Maximum of macroscopic average" | cut -d":" -f2)
EF=$(grep E-fermi OUTCAR |tail -1| cut -d":" -f2 | cut -d"X" -f1)
Work=$(echo "$Vac - $EF" | bc -l)
echo "Vacuum level: ${Vac} eV Fermi-level of Slab: ${EF} Work function: ${Work}"

fi