#!/bin/sh
function Queue {
if [[ $2 = "Full" ]]
then
    #run.sh Change
    sed -i -e '/#PBS -q/c\#PBS -q full' -e "/nodes/c\#PBS -l nodes=$1:ppn=32:full" run.sh
    
    #Tag Adding
    if [[ $(grep KPAR INCAR) = "" ]]
    then
    echo "KPAR=" >> INCAR
    fi
    if [[ $(grep NCORE INCAR) = "" ]]
    then
    echo "NCORE=" >> INCAR
    fi
    if [[ $(grep NPAR INCAR) = "" ]]
    then
    echo "NPAR=" >> INCAR
    fi
    
    #INCAR Change
    sed -i -e "s/KPAR.*/KPAR=$1/g" -e "s/NCORE.*/NCORE=8/g" -e "s/NPAR.*/NPAR=4/g" INCAR
    echo "set nodes=$1:ppn=32:full"
    echo "set KPAR=$1:NCORE=8:NPAR=4"
elif [[ $2 = "Fullgen2" ]]
then
    sed -i -e '/#PBS -q/c\#PBS -q fullgen2' -e "/nodes/c\#PBS -l nodes=$1:ppn=40:fullgen2" run.sh
    
    #Tag Adding
    if [[ $(grep KPAR INCAR) = "" ]]
    then
    echo "KPAR=" >> INCAR
    fi
    if [[ $(grep NCORE INCAR) = "" ]]
    then
    echo "NCORE=" >> INCAR
    fi
    if [[ $(grep NPAR INCAR) = "" ]]
    then
    echo "NPAR=" >> INCAR
    fi
    
    #INCAR Change
    sed -i -e "s/KPAR.*/KPAR=$1/g" -e "s/NCORE.*/NCORE=10/g" -e "s/NPAR.*/NPAR=4/g" INCAR
    echo "set nodes=$1:ppn=40:fullgen2"
    echo "set KPAR=$1:NCORE=10:NPAR=4"
fi
}

function IRKPT_to_Nodes { #2. 한 작업당 2~3개의 Nodes 로 제한
#현재 남은 노드 개수 세기
NFull=$(pestat | grep "free" | grep -c "  32 ")
NFullgen2=$(pestat | grep "free" | grep -c "  40 ")
echo "# of Empty full nodes: " $NFull
echo "# of Empty fullgen2 nodes: " $NFullgen2

#현재 구조의 Irreducible KPOINTS 개수 세서 Nodes 2~4 으로 설정
rm OUTCAR
IRKPT=$(qdebug2.0 | tail -1)
echo "Irreducible Kpoints 개수: $IRKPT"
read -p "어떤 Node를 사용할까요? Full/Fullgen2: " Node_Type
read -p "Node 를 몇개 사용할까요? " NNodes

#Node 개수에 따라서, Parallelization setting
Queue $NNodes $Node_Type
}

function POTCAR_Maker {
POT=()
Elements=($(sed -n "6p" POSCAR))
read -p "What is the Exchange-correlation functional type? (1: GGA 2: LDA)" XC
if [[ $XC -eq 1 ]]
then
POTCAR_Folder="/usr/local/VASP/pp-54"
elif [[ $XC -eq 2 ]]
then
POTCAR_Folder="/usr/local/VASP/VASP_potentials_52/LDA/"
fi

for Element in ${Elements[@]}
do
for i in $POTCAR_Folder/*
do
A=$(basename $i)
echo $A | grep $Element
done

if [[ "$Element" == "Li" ]]||[[ "$Element" == "K" ]]||[[ "$Element" == "Cs" ]]||[[ "$Element" == "Rb" ]]||[[ "$Element" == "Be" ]]||[[ "$Element" == "Ca" ]]||[[ "$Element" == "Sr" ]]||[[ "$Element" == "Ba" ]]||[[ "$Element" == "Sc" ]]||[[ "$Element" == "Y" ]]||[[ "$Element" == "Zr" ]]||[[ "$Element" == "V" ]]
then
MP_POT="${Element}_sv"

elif [[ "$Element" == "Na" ]]||[[ "$Element" == "Mg" ]]||[[ "$Element" == "Ti" ]]||[[ "$Element" == "Hf" ]]||[[ "$Element" == "Nb" ]]||[[ "$Element" == "Ta" ]]||[[ "$Element" == "Cr" ]]||[[ "$Element" == "Mo" ]]||[[ "$Element" == "W" ]]||[[ "$Element" == "Mn" ]]||[[ "$Element" == "Tc" ]]||[[ "$Element" == "Re" ]]||[[ "$Element" == "Fe" ]]||[[ "$Element" == "Ni" ]]||[[ "$Element" == "Cu" ]]||[[ "$Element" == "Ru" ]]||[[ "$Element" == "Rh" ]]||[[ "$Element" == "Os" ]]
then
MP_POT="${Element}_pv"
t
elif [[ "$Element" == "Ga" ]]||[[ "$Element" == "Ge" ]]||[[ "$Element" == "In" ]]||[[ "$Element" == "Sn" ]]||[[ "$Element" == "Tl" ]]||[[ "$Element" == "Pb" ]]||[[ "$Element" == "At" ]]
then
MP_POT="${Element}_d"

elif [[ "$Element" == "Pr" ]]||[[ "$Element" == "Nd" ]]||[[ "$Element" == "Pm" ]]||[[ "$Element" == "Sm" ]]||[[ "$Element" == "Tb" ]]||[[ "$Element" == "Dy" ]]||[[ "$Element" == "Ho" ]]||[[ "$Element" == "Er" ]]
then
MP_POT="${Element}_3"

elif [[ "$Element" == "Bi" ]]
then
MP_POT="${Element} or ${Element}"

else
MP_POT="${Element}"
fi

read -p "What pseudo-potential of $Element gonna use? (MP_Recommand: $MP_POT) " Temp
POT+=($Temp)
cat ${POTCAR_Folder}/${Temp}/POTCAR >> POTCAR
echo ${POT[@]}
done
}

function run_sh_Maker {
echo "#!/bin/sh
#PBS -N $1
#PBS -q full
#PBS -l nodes=2:ppn=32:full

#EXE=\"/usr/local/VASP/vasp5.4.4vtst-gamma-2019\"
EXE=\"/usr/local/VASP/vasp5.4.4vtst-mkl-2019\"
#EXE=\"/usr/local/VASP/vasp5.4.4vtst-nc-2019\"

NUMBER=\`cat \$PBS_NODEFILE | wc -l\`
cd \$PBS_O_WORKDIR
mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out

Init_time=`sed -n '3p' OUTCAR | awk '{print $5, $6}'`
Used_core=`sed -n '4p' OUTCAR | awk '{print $3}'`
CPU_time=`grep 'Total CPU' OUTCAR | awk '{print $6}'`
echo $PBS_JOBID '    ' $Init_time '    '  $Used_core '     '  $CPU_time >> ~/Calculation_Time.log
" > run.sh
}

function INCAR_Maker {
echo "SYSTEM      = 

### Job Start setting
 ISTART    = 0              
 ICHARG    = 2              
# INIWAV    = 1              
# NWRITE    = 2              
#---------------------------------------------------------------------------------------
### Parallelization
 NPAR      = 4
 NCORE     = 4              
 KPAR      = 4              
# NSIM      = 4              
 LPLANE    = .TRUE.         
#---------------------------------------------------------------------------------------
### Electronic Relaxation
##1) Self consistent calculation 
 NELM      = 200            
# NELMIN    = 2              
# NELMDL    = -5             
 ALGO      = Fast          
##IALGO     = 48             
 LREAL     = Auto           

##2) Energy accuracy
 PREC      = Accurate       
 EDIFF     = 1E-06          
 ENCUT     = 520               
# NBANDS    =                
# WEIMIN    = 0              
# ADDGRID   = .TRUE.        
# NUPDOWN   = -1             

##3) Output options
LCHARG    = .TRUE.        
LWAVE     = .FALSE.         
# LELF      = .FALSE.        
# LVTOT     = .FALSE.        
#----------------------------------------------------------------------------------------
### Ionic Relaxation
##1) Self consistent calculation
 NSW       = 1000   
 IBRION    = 2          
 POTIM     = 0.01   
# SMASS     = -3 
# GGA       = PS            

##2) Symmetry
 ISYM      = 2              
 ISIF      = 3              

##3) Energy accuracy
# IVDW      = 11             
 ISPIN     = 2              
 MAGMOM    = 1000*0               
 EDIFFG    = -0.01         
#-------------------------------------------------------------------------------------------
### GGA+U calculation
# LDAU      = .TRUE.         
# LDAUTYPE  = 2              
# LDAUL     =                
# LDAUU     =                
# LDAUJ     =                
# LDAUPRINT = 2              
 LMAXMIX   = 2  #s=0, p=2, d=4, f=6

### DOS related values
 LORBIT    = 11             
# RWIGS     =                
 NEDOS     = 2000 #inc by 0.01 [eV]
 EMIN      = -10               
 EMAX      = 10               
 ISMEAR    = 0             
 SIGMA     = 0.01           

#--------------------------------------------------------------------------------------------------
### Polarization Calculation related values
#LCALCPOL=TRUE
#DIPOL=0.5 0.5 0.5
#--------------------------------------------------------------------------------------------------
### COHP Calculation related values
#LSORBIT=TRUE #Please change run.sh EXE to 'nc' type!
#-----------------------------------------------------------------------------------------------------
### HSE Functional related values
#1) B3LYP
#LHFCALC = .TRUE.
#GGA = B3
#AEXX = 0.2
#AGGAX = 0.72 
#AGGAC = 0.81
#ALDAC = 0.19
#ALGO = D
#TIME = 0.4

#2) PBE0
#LHFCALC = .TRUE. 
#ALGO = D
#TIME = 0.4 

#3) HSE06
#LHFCALC = .TRUE. 
#HFSCREEN = 0.2
#ALGO = D 
#TIME = 0.4 

#4) HF
#LHFCALC = .TRUE.   
#AEXX = 1.0   
#ALDAC = 0.0   
#AGGAC = 0
#ALGO = D 
#TIME = 0.4 
#--------------------------------------------------------------------------------------------------
### Defect Calculation related values
# NELECT    =                
#----------------------------------------------------------------------------------------------------
### Slab Calculation related values
# IDIPOL    = 3              
# AMIN      = 0.01
# LVHAR     = .TRUE.           
#----------------------------------------------------------------------------------------------------
### Band decomposed charge densities
# LPARD     = .T.            
# IBAND     = 125            
# EINT      =                
# NBMOD     = 1              
# KPUSE     = 61 62 63       
# LSEPB     = .T.            
# LSEPK     = .T. " > INCAR 
}

function KPOINTS_Maker {
read -p "What is the G-center Type? (1: Gamma(Default), 2: Monk-horst) " G_TYPE
if [[ $G_TYPE -eq 2 ]]
then
echo "Automatic mesh
0               
Monk-horst         
1 1 1         
0 0 0" > KPOINTS
else
echo "Automatic mesh
0               
Gamma   
1 1 1         
0 0 0" > KPOINTS
fi
} 


#==============================================================================================================================

echo "*--------------------------------------------------------------------------------*"
echo "|                          <Bulk Relaxation editor>                              |"
echo "| o Step 0 Download POSCAR from Materials Project                                |"
echo "| o Step 1 ENCUT Convergence Test                                                |"
echo "| o Step 2 KPOINTS Convergence Test                                              |"
echo "| o Step 3 Pseudo-potential Comparison                                           |"
echo "| o Step 4 Recalculate Relaxed Structure                                         |"
echo "| o Step 5 DOS Convergence Test                                                  |"
echo "| o Step 6 Band Convergence Test                                                 |"
echo "| o Step 7 COHP Calculation                                                      |"
echo "*--------------------------------------------------------------------------------*"
read -p "몇번째 Step 을 진행할 지 정수로 적어주세요: " STEP

#======================================================================================================================
if [[ $STEP == 0 ]]
then
python ~/KH_Scripts/1_Structure_generator/.Bulk_MP_generator.py
if [[ -a FolderName ]]
then
Folder=$(cat FolderName)
mkdir $Folder
mv POSCAR $Folder/.
cd $Folder
POTCAR_Maker
run_sh_Maker $Folder
INCAR_Maker
KPOINTS_Maker
qdebug2.0
cd -
rm FolderName
fi
fi

#======================================================================================================================
if [[ $STEP == 1 ]]
then
echo "EMAX of POTCAR: $(grep ENMAX POTCAR)"
read -p "What is the ENCUT Start, End, increment? (ex. 100 300 50) " EN_START EN_END EN_INC
sed -i "12,200d" run.sh

echo "for((i=$EN_START;i<=$EN_END;i=i+$EN_INC))
do
mkdir 1_ENCUT_Test
mkdir 1_ENCUT_Test/\${i}
sed -i \"s/ENCUT.*/ENCUT=\${i}/\" INCAR
mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out
cp * 1_ENCUT_Test/\${i}/.

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log

done
" >> run.sh

sed -i -e "s/NSW.*/NSW=0/" INCAR

fi

#======================================================================================================================
if [[ $STEP == 2 ]]
then
read -p "What is the converged ENCUT? " ENCUT
sed -i "s/ENCUT.*/ENCUT=$ENCUT/" INCAR
read -p "What is infinite axis? ex) A/B/C/AB/AC/BC/ABC:" D
echo -e "$D\n" | K_ratio
read -p "What is the KPT Start, End index? " KPT_STR KPT_END 
sed -i "12,200d" run.sh

echo "for((i=$KPT_STR;i<=$KPT_END;i++))
do
Fold=\$(echo -e \"$D\\n\${i}\" |K_ratio | sed \"1d\" | sed -n \"\${i}p\" |cut -d\"|\" -f2 | sed \"s/ : /x/g\" | cut -d\" \" -f2)

mkdir 2_KPT_Test
mkdir 2_KPT_Test/\$Fold

mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out
cp * 2_KPT_Test/\$Fold/.

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log

done
" >> run.sh

sed -i -e "s/NSW.*/NSW=100/" -e "s/IBRION.*/IBRION=2/" -e "s/ISIF.*/ISIF=3/" INCAR

fi

#======================================================================================================================
if [[ $STEP == 3 ]]
then
i=1
while [[ 1 ]]
do
read -p "Make a new POTCAR? (Enter=yes, N=Stop) " YN
if [[ ! $YN == N ]]
then
	rm POTCAR
	Folder=$(POTCAR_Maker)
	echo $Folder
	#mkdir 3_POTCAR_Comp
	#mkdir 3_POTCAR_Comp/${i}_${Folder}
	#cp * 3_POTCAR_Comp/${i}_${Folder}/
	#i=$(expr $i + 1)
else
break
fi
done
fi

#======================================================================================================================
if [[ $STEP == 4 ]]
then
cp CONTCAR POSCAR
sed -i "12,200d" run.sh
echo "mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log
" >> run.sh
fi


#======================================================================================================================
if [[ $STEP == 5 ]]
then
read -p "Before DOS Convergence, please recalculate with NSW=0 with cp CONTCAR -> POSCAR! (write enter) " YES
read -p "What is infinite axis? ex) A/B/C/AB/AC/BC/ABC:" D
echo -e "$D\n" | K_ratio
read -p "What is the KPT Start, End index? " KPT_STR KPT_END
read -p "What is the NEDOS, EMIN, EMAX? " NEDOS EMIN EMAX
read -p "What is the max l-orbital number? (s=0, p=2, d=4, f=6) " LMAXMIX
sed -i "12,200d" run.sh

echo "for((i=$KPT_STR;i<=$KPT_END;i++))
do
Fold=\$(echo -e \"$D\\n\${i}\" |K_ratio | sed \"1d\" | sed -n \"\${i}p\" |cut -d\"|\" -f2 | sed \"s/ : /x/g\" | cut -d\" \" -f2)

mkdir DOS_Conv
mkdir DOS_Conv/\$Fold

mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out
cp * DOS_Conv/\$Fold/.

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log

done
" >> run.sh

sed -i -e "s/.*ICHARG.*/ICHARG=11/" -e "s/.*LMAXMIX.*/LMAXMIX=${LMAXMIX}/" -e "s/.*NSW.*/NSW=00/" -e "s/.*LORBIT.*/LORBIT=11/" -e "s/.*EMIN.*/EMIN=${EMIN}/" -e "s/.*EMAX.*/EMAX=${EMAX}/" -e "s/.*NEDOS.*/NEDOS=${NEDOS}/" -e "s/.*ISMEAR.*/ISMEAR=-5/" -e "s/.*LCHARG.*/LCHARG=FALSE/" INCAR

fi

#======================================================================================================================
if [[ $STEP == 7 ]]
then
read -p "1. Before COHP Calculation, please recalculate with NSW>0 with cp CONTCAR -> POSCAR! (write enter) " YES
NBANDS=$(grep NBANDS OUTCAR | awk '{print $15}')
NBANDS=$(expr $NBANDS \* 3 / 2 )
read -p "What is the NEDOS, EMIN, EMAX? " NEDOS EMIN EMAX

echo "Now make fairly weighted IBZKPT using debugging"
if [[ ! $(grep LSORBIT INCAR) ]]
then
echo LSORBIT >> INCAR
fi
sed -i -e "s/.*LSORBIT.*/LSORBIT=TRUE/" -e "s/MAGMOM/\#MAGMOM/" -e "s/.*ISYM.*/ISYM=-1/" INCAR
rm OUTCAR
echo -e "vasp5.4.4vtst-nc-2019\n" | Qdebug 
cp IBZKPT KPOINTS
sed -i "12,200d" run.sh
echo "mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out

Init_time=\$(sed -n '3p' OUTCAR | awk '{print \$5, \$6}')
Used_core=\$(sed -n '4p' OUTCAR | awk '{print \$3}')
CPU_time=\$(grep 'Total CPU' OUTCAR | awk '{print \$6}')
echo \$PBS_JOBID '    ' \$Init_time '    '  \$Used_core '     '  \$CPU_time >> ~/Calculation_Time.log
" >> run.sh

sed -i -e "s/.*NSW.*/NSW=0/" -e "s/.*NPAR.*/NPAR=1/" -e "s/.*NEDOS.*/NEDOS=${NEDOS}/" -e "s/.*EMIN.*/EMIN=${EMIN}/" -e "s/.*EMAX.*/EMAX=${EMAX}/" -e "s/.*NBANDS.*/NBANDS=${NBANDS}/" -e "s/.*EDIFF     =.*/EDIFF=1E-7/" -e "s/.*ISMEAR.*/ISMEAR=-5/" -e "s/.*LORBIT.*/LORBIT=12/" -e "s/.*LWAVE.*/LWAVE=TRUE/" -e "s/.*LSORBIT.*/LSORBIT=FALSE/" -e "s/\#MAGMOM/MAGMOM/" INCAR

fi

