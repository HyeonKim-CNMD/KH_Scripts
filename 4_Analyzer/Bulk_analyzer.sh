#! /bin/sh

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


#==============================================================================================================================
echo "*--------------------------------------------------------------------------------*"
echo "|                                <Bulk Analyzer>                                 |"
echo "| o Step 1 ENCUT Convergence plot (Use in 1_ENCUT Folder)                        |"
echo "| o Step 2 KPOINTS Convergence plot                                              |"
echo "| o Step 3 DOS plot                                                              |"
echo "*--------------------------------------------------------------------------------*"
read -p "몇번째 Step 을 진행할 지 정수로 적어주세요: " STEP
#==============================================================================================================================

if [[ $STEP == 1 ]]
then
Check_rlx
head $(find . -maxdepth 1 -mindepth 1 -type d | head -1)/POSCAR
read -p "Write Number of Formula units of Structure!: " FU
read -p "Write the name of material: " Material
Check_relax | cut -d"/" -f2 > E_Conv.dat
echo "plot 'E_Conv.dat' using 1:(\$5-\$4)/$FU axis x1y1 title 'Energy' with linespoints lw 2 lc 'dark-pink' ps 1 pt 7, 'E_Conv.dat' using 1:7 axis x1y2 title 'Time' with linespoints lw 2 lc 'royalblue' ps 1 pt 7
set termopt enhanced
set title 'Energy cut-off convergence test of ${Material}'
set xlabel 'Energy cut-off [eV]'
set ylabel 'Energy difference [eV/FU]'
set y2label 'Time per Electronic step [Sec]'
set xrange[:]
set yrange[-0.001:0.001]
set y2range[:]
set y2tics
set ytics nomirror
set key on inside top right nobox
set term pngcairo size 640,480.00000000000000000000 enhanced font 'Helvetica, 14'
set output 'E_Conv_0.001eV.png'
replot" > E_Conv.gnu
gnuplot E_Conv.gnu
sed -i "s/0.001/0.01/g" E_Conv.gnu
gnuplot E_Conv.gnu

elif [[ $STEP == 2 ]]
then
Check_rlx
head $(find . -maxdepth 1 -mindepth 1 -type d | head -1)/POSCAR
read -p "Write Number of Formula units of Structure!: " FU
read -p "Write the name of material: " Material
Check_relax | cut -d"/" -f2 > K_Conv.dat
echo "plot 'K_Conv.dat' using (\$5-\$4)/$FU:xticlabels(1) axis x1y1 title 'Energy' with linespoints lw 2 lc 'dark-pink' ps 1 pt 7, 'K_Conv.dat' using 7:xticlabels(1) axis x1y2 title 'Time' with linespoints lw 2 lc 'royalblue' ps 1 pt 7
set termopt enhanced
set title 'Kpoints convergence test of $Material'
set xlabel 'K-mesh: LxMxN'
set ylabel 'Energy difference [eV/FU]'
set y2label 'Time per Electronic step [Sec]'
set xrange[:]
set xtics rotate by 90 right
set yrange[-0.001:0.001]
set y2range[:]
set y2tics
set ytics nomirror
set key on inside top right nobox
set term pngcairo size 640,480.00000000000000000000 enhanced font 'Helvetica, 14'
set output 'K_Conv_0.001eV.png'
replot
" > K_Conv.gnu
gnuplot K_Conv.gnu
sed -i "s/0.001/0.01/g" K_Conv.gnu
gnuplot K_Conv.gnu

fi

