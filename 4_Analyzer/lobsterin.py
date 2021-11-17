import os
from pymatgen.io.lobster.inputs import Lobsterin

Now=os.getcwd()
print("Now calculating lobster input files...")
lobsterin = Lobsterin.standard_calculations_from_vasp_files(f"{Now}/POSCAR", f"{Now}/INCAR", f"{Now}/POTCAR", option='standard')
print("jobs done!")
lobsterin.write_lobsterin(path="lobsterin")
file=open('./lobsterin','r')
print(file.read())
