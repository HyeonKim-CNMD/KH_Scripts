import os
import re
from math import sqrt
from math import gcd
from pymatgen.core import surface
from pymatgen.core import structure
from pymatgen.core import lattice
from pymatgen.core import sites
import numpy as np


Slab_Name = input('Slab structure 파일 이름을 작성 해주세요 (Enter=CONTCAR) ')
if Slab_Name == "":
    Slab_Name="CONTCAR"
Layers = input('Slab 의 Layer 개수를 입력해주세요: ')
Slab = surface.Structure.from_file(f'{os.getcwd()}/{Slab_Name}')

MinC, MaxC = surface.get_slab_regions(Slab)[0]  # Slab 영역의 C-coordinate 최소/최대를 출력
C_OriLen = Slab.as_dict()['lattice']['c']
Slab_Height = (MaxC - MinC) * C_OriLen
Interlayer_Dis = Slab_Height/float(Layers)
print(f"Slab_Height: {Slab_Height} [A] Number of Layers: {Layers} Interlayer Distance: {Interlayer_Dis} [A]")
os.system(f"echo '{Interlayer_Dis}' > Temp.txt")