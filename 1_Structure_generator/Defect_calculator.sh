#!/bin/sh

function INCAR_Setting {
echo "
INCAR:
    ENCUT: $1
    ISMEAR: $2
    defects:
        ISTART: 0
        ICHARG: 2
        NPAR: 4
        NCORE: 7
        KPAR: 2
        LPLANE: TRUE
        NELM: 200
        ALGO: Fast
        EDIFF: 1.e-6
        PREC: Accurate
        NSW: 100
        IBRION: 2
        EDIFFG: -1.e-2
        ISIF: 2 
        SIGMA: 0.05
        ISPIN: 2
        ISYM: 0
        LASPH: True
        LORBIT: 11
        LREAL: Auto
        LVHAR: True
        LVTOT: True
        LWAVE: False
    bulk:
        ISTART: 0
        ICHARG: 2
        NPAR: 4
        NCORE: 7
        KPAR: 2
        LPLANE: TRUE
        NELM: 200
        ALGO: Normal
        EDIFF: 1.e-6
        PREC: Accurate
        NSW: 0
        IBRION: -1
        EDIFFG: -1.e-2
        ISIF: 3
        SIGMA: 0.05
        ISPIN: 2
        ISYM: 2
        LAECHG: True
        LASPH: True
        LCHARG: True
    dielectric:
        ISTART: 0
        ICHARG: 2
        NPAR: 28
        NCORE: 1
        KPAR: 2
        LPLANE: TRUE
        NELM: 200
        ALGO: Normal
        EDIFF: 1.e-6
        PREC: Accurate
        NSW: 0
        IBRION: 8
        EDIFFG: -1.e-2
        ISIF: 3
        ISMEAR: -5
        SIGMA: 0.01
        ISPIN: 2
        LAECHG: True
        LASPH: True
        LCHARG: True
        LORBIT: 11
        LPEAD: True
        LREAL: Auto
        LVHAR: True
        LWAVE: False" >> INCAR_Setting.yaml
}

function Run_sh_Maker {
echo "#!/bin/sh
#PBS -N 
#PBS -q full
#PBS -l nodes=1:ppn=28:full

EXE=\"/usr/local/VASP/vasp5.4.4vtst-gamma-2019\"
#EXE=\"/usr/local/VASP/vasp5.4.4vtst-mkl-2019\"
#EXE=\"/usr/local/VASP/vasp5.4.4vtst-nc-2019\"

NUMBER=\`cat \$PBS_NODEFILE | wc -l\`
cd \$PBS_O_WORKDIR
mpirun -machinefile \$PBS_NODEFILE -np \$NUMBER \$EXE > relax.out" > run.sh
}

function Gamma_KPOINTS_Maker {
echo "System
0
Gamma
1 1 1" > KPOINTS
}


#==============================================================================================================================

echo "*------------------------------------------------------------------------------------------------------------*"
echo "|                         <Defect Calculation editor>                                                        |"
echo "| It needs vaspkits and pycdt and bandgap                                                                    |"
echo "| o Step 0 Write INCAR_Setting.yaml                                                                          |"
echo "| o Step 1 Generate Defected Structure using PyCDT                                                           |"
echo "| o Step 2 Copy & Paste run.sh and Gamma-centered KPOINTS, back up POSCAR (Use in PyCDT generated folder)    |"
echo "| o Step 3 Parse relaxed structure energies using PyCDT (Use in PyCDT generated folder)                      |"
echo "| o Step 4 Calculate Formation Enthalpy and Chemical potential (Use in chemical potential folder)            |"
echo "| o Step 5 VBM and Bandgap parser (Use in Bandgap calculation folder)                                        |"
echo "| o Step 6 Change Chemical potential, E-fermi, Bandgap in 'defect_data.json' (Use in PyCDT generated folder) |"
echo "| o Step 7 Calculate correction energies using PyCDT                                                         |"
echo "| o Step 8 Draw Formation energy diagram (x=E_F, y=DFE)                                                      |"
echo "*------------------------------------------------------------------------------------------------------------*"
read -p "몇번째 Step 을 진행할 지 정수로 적어주세요: " STEP

#======================================================================================================================
if [[ $STEP == 0 ]]
then
read -p "Write the ENCUT of structure: " ENCUT
read -p "Write the ISMEAR of structure: " ISMEAR
INCAR_Setting $ENCUT $ISMEAR

#======================================================================================================================
elif [[ $STEP == 1 ]]
then
ls
read -p "Write the Relaxed unitcell name: " STRUCTURE
read -p "Write the max number of Atoms in supercell: " MAX_ATOM
if [[ ! "$MAX_ATOM" == "" ]]
then
MAX_ATOM="-n $MAX_ATOM"
fi
read -p "Write the conduction type of structure (1: Insulator 2: Semiconductor): " INS_SEMI
if [[ $INS_SEMI -eq 1 ]]
then
INS_SEMI="-t insulator"
elif [[ $INS_SEMI -eq 2 ]]
then
INS_SEMI="-t semiconductor"
fi
read -p "Write the generate of Native antisites (1: No 2: Yes): " NOANTI
if [[ $NOANTI -eq 1 ]]
then
NOANTI="-noa"
else
NOANTI=""
fi
read -p "Write the substitution elements if you needs (Enter = no substitution, ie. C Ga O == C sub -> Ga, O): " SUBS
if [[ ! "$SUBS" == "" ]]
then
SUBS="--sub $SUBS"
fi

read -p "Write the interstitial elements if you needs (Enter = no interstitials, ie. Ga O == Ga, O interstitials): " INTS
if [[ ! "$INTS" == "" ]]
then
INTS="-ii $INTS"
fi

read -p "Write the file name of INCAR Settings: " INPUT_SET
if [[ ! "$INPUT_SET" == "" ]]
then
INPUT_SET="-is $INPUT_SET"
fi
echo $STRUCTURE $MAX_ATOM $INS_SEMI $INTERSTITIALS $NOANTI $SUBS $INTS $INPUT_SET
pycdt generate_input -s $STRUCTURE $MAX_ATOM $INS_SEMI $INTERSTITIALS $NOANTI $SUBS $INTS $INPUT_SET

#======================================================================================================================
elif [[ $STEP == 2 ]]
then
Run_sh_Maker
Gamma_KPOINTS_Maker
Here=$(pwd)
for i in $(find . -maxdepth 2 -mindepth 1 -type d)
do
cp $i/POSCAR $i/POSCAR_ori
cp $i/KPOINTS $i/KPOINTS_ori
cp KPOINTS run.sh $i/.
done
#======================================================================================================================
elif [[ $STEP == 3 ]]
then
pycdt parse_output

#======================================================================================================================
elif [[ $STEP == 4 ]]
then
echo "Free energies of relaxed structures"
echo "========================================================================================================"
for i in $(find . -maxdepth 1 -mindepth 1 -type d)
do
Elements=$(sed -n "6p" $i/CONTCAR)
Numbers=$(sed -n "7p" $i/CONTCAR)
Energy=$(grep TOTEN $i/OUTCAR | tail -1 | awk '{print $5}')
echo "$i : $Elements=$Numbers Energy: $Energy"
done
echo "*====================================================================================*"
echo "| Formation Enthalpy equation is,                                                    |"
echo "| H_Prod = E_Prod - (b*E_React1 + c*E_React2 + ...)                                  |"
echo "|        = b*u_React1 + c*u_React2 + ...                                             |"
echo "*====================================================================================*"

read -p "Write Product Name: " Prod
read -p "Write E_Prod [eV/FU] (ie. 11.26/4): " E_Prod
E_Prod=$(echo "$E_Prod" | bc -l)
Eq_str="H_$Prod = E_$Prod"
Eq="$E_Prod"

i=0
React=()
C=()
E_React=()
while [[ 1 ]]
do

read -p "Write Reactant Name (Enter=Exit): " React_Temp
if [[ "$React_Temp" == "" ]]
then
break
fi
React+=($React_Temp)

read -p "Write C of E_React$i: " C_Temp
C+=($C_Temp)
read -p "Write E_React$i [eV/FU] (ie. 11.26/4): " E_React_Temp
E_React_Temp=$(echo "$E_React_Temp" | bc -l)
E_React+=($E_React_Temp)

Eq_str+=" -${C_Temp}E_$React_Temp"
Eq+=" - $C_Temp * $E_React_Temp"
i=$(expr $i + 1)
done

H_Form=$(echo "$Eq" | bc -l)
echo $Eq_str
echo -e "$H_Form = $Eq \n"
echo $Eq_str >> Formation_enthalpy.dat
echo -e "$H_Form = $Eq" >> Formation_enthalpy.dat

for((i=0;i<${#React[@]};i++))
do
echo "$i ${React[$i]} : ${C[$i]} X ${E_React[$i]}"
done
read -p "Write React number having const. chemical potential: " Con
if [[ ! "$Con" == "" ]]
then
for((i=0;i<${#React[@]};i++))
do
if [[ ! $i -eq $Con ]]
then
React_Temp=(${React[@]})
React_Temp[$i]="${React[$i]}-poor"
E_React_Temp=(${E_React[@]})
E_React_Temp[$i]=$(echo "($H_Form + ${C[$Con]} * ${E_React[$Con]})/${C[$i]} + ${E_React[$i]}" | bc -l)
echo "Chemical Potential: (${React_Temp[@]})=(${E_React_Temp[@]})"
echo "Chemical Potential: (${React_Temp[@]})=(${E_React_Temp[@]})" >> Formation_enthalpy.dat
fi
done

else
for((i=0;i<${#React[@]};i++))
do
React_Temp=(${React[@]})
React_Temp[$i]="${React[$i]}-poor"
E_React_Temp=(${E_React[@]})
E_React_Temp[$i]=$(echo "$H_Form / ${C[$i]} + ${E_React[$i]}" | bc -l)
echo "Chemical Potential: (${React_Temp[@]})=(${E_React_Temp[@]})"
echo "Chemical Potential: (${React_Temp[@]})=(${E_React_Temp[@]})" >> Formation_enthalpy.dat
done
fi
echo "" >> Formation_enthalpy.dat

#======================================================================================================================
elif [[ $STEP == 5 ]]
then
BGAP=($(analyze-hse.sh | tail -1 | awk '{printf $3}'))
VBM=$(analyze-hse.sh | tail -1 | awk '{printf $6}')
echo -e "$VBM\n$BGAP" > Bandgap.dat
cat Bandgap.dat

#======================================================================================================================
elif [[ $STEP == 6 ]]
then
python ~/bin/My_scripts/defect_parse_change.py

elif [[ $STEP == 7 ]]
then
read -p "Write the correction method (1: Freysoldt 2: Kumagai) " TYPE
if [[ $TYPE -eq 1 ]]
then
TYPE="freysoldt"
elif [[ $TYPE -eq 2 ]]
then
TYPE="kumagai"
fi

#encut change in finite_site_corrections.py
read -p "Write the ENCUT of the defected structure: " ENCUT
sed -i "s/encut = defect_entry.parameters.get( 'encut', 860)/encut = defect_entry.parameters.get( 'encut', $ENCUT)/" /home/khyeon/anaconda3/envs/pycdt/lib/python3.7/site-packages/pycdt-2.0.5-py3.7.egg/pycdt/corrections/finite_size_charge_correction.py 


pycdt compute_corrections -c $TYPE

elif [[ $STEP == 8 ]]
then
pycdt compute_formation_energies -p -f png > Charge_transition.dat

fi
