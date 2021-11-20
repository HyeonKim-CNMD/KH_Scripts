#!/bin/sh

echo "*--------------------------------------------------------------------------------*"
echo "|                             <Slab Maker and Relax>                             |"
echo "| o Step 1 Generate Slab Structure from Bulk Structure                           |"
echo "| o Step 2 Surface-oriented Bulk Structure KPT convergence test                  |"
echo "| o Step 3 Vacuum distance convergence test                                      |"
echo "| o Step 4 Layer convergence test                                                |"
echo "| o Step 5 Termination comparison                                                |"
echo "| o Step 6 Suface area size effect comparison                                    |"
echo "| o Step 7 Work function calculation                                             |"
echo "*--------------------------------------------------------------------------------*"
read -p "몇번째 Step 을 진행할 지 정수로 적어주세요: " STEP

if [[ $STEP == 1 ]]
then
ls
python ~/KH_Scripts/1_Structure_generator/.Slab_Generator_Final.py
read -p "Do the structre need to adjust the number of Layers? (Y=Enter/N): " YN
if [[ $YN == "N" ]]
then
  pass
else
  ls
  python ~/KH_Scripts/1_Structure_generator/.Slab_Adjust_Layers.py
fi

elif [[ $STEP == 2 ]]
then
echo "Please set KPOINTS to Previous Bulk Relaxation K-spacing!!"
ls
python ~/KH_Scripts/1_Structure_generator/.Slab_Surface_oriented_bulk.py

ls
read -p "제작된 Surface-oriented Bulk 구조를 입력해주세요 " Bulk
cp $Bulk POSCAR
mkdir 1_SO_Bulk
sed -i "12,200d" run.sh

echo "mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log
" >> run.sh

sed -i -e "s/NSW.*/NSW=100/" -e "s/IBRION.*/IBRION=2/" -e "s/ISIF.*/ISIF=2/" INCAR
echo "KPOINTS 간격을 Slab 의 a,b-axis 간격에 맞게 C-axis 를 설정하세요"

elif [[ $STEP == 3 ]]
then
ls
python ~/KH_Scripts/1_Structure_generator/.Slab_Vacuum_Test.py
S_Dis=$(cat Temp.txt | awk '{print $1}')
E_Dis=$(cat Temp.txt | awk '{print $2}')
I_Dis=$(cat Temp.txt | awk '{print $3}')
Filename1=$(cat Temp.txt | awk '{print $4}')
Filename2=$(cat Temp.txt | awk '{print $5}')

sed -i "12,200d" run.sh
echo "for((i=$S_Dis;i<=$E_Dis;i=i+$I_Dis))
do
mkdir 2_Vacuum
mkdir 2_Vacuum/\${i}
cp $Filename1\${i}_\\$Filename2 POSCAR
mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out
cp * 2_Vacuum/\${i}/.

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log

done
" >> run.sh

sed -i -e "s/.*ISIF.*/ISIF=2/" -e "s/.*NSW.*/NSW=0/" INCAR

elif [[ $STEP == 4 ]]
then
ls
python ~/KH_Scripts/1_Structure_generator/.Slab_Layer_Test.py
S_Lay=$(cat Temp.txt | awk '{print $1}')
E_Lay=$(cat Temp.txt | awk '{print $2}')
I_Lay=$(cat Temp.txt | awk '{print $3}')
Filename1=$(cat Temp.txt | awk '{print $4}')
Filename2=$(cat Temp.txt | awk '{print $5}')
Filename3=$(cat Temp.txt | awk '{print $6}')

sed -i "12,200d" run.sh
echo "for((i=$S_Lay;i<=$E_Lay;i=i+$I_Lay))
do
mkdir 3_Layer
mkdir 3_Layer/\${i}
cp $Filename1\${i}${Filename2}_\\$Filename3 POSCAR
mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out
cp * 3_Layer/\${i}/.

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log

done
" >> run.sh

sed -i -e "s/.*ISIF.*/ISIF=2/" -e "s/.*NSW.*/NSW=200/" -e "s/.*AMIN.*/AMIN=0.01/" INCAR

elif [[ $STEP == 5 ]]
then
ls


elif [[ $STEP == 7 ]]
then
cp CONTCAR POSCAR
sed -i "12,200d" run.sh
echo "mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log
" >> run.sh
sed -i -e "s/.*IDIPOL.*/IDIPOL=3/" -e "s/.*LVHAR.*/LVHAR=TRUE/" -e "s/.*AMIN.*/AMIN=0.01/" INCAR
fi

exit 0

