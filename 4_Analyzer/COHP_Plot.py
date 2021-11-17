import os
import abipy.data as abidata

from abipy.abilab import LobsterAnalyzer

dirpath = os.path.join(abidata.dirpath, "refs", "lobster_gaas")

# Open the all the lobster files produced in directory dirpath
# with the (optional) prefix GaAs_
PREFIX=input("Write the prefix name: (ex. GaAs_) ") 
lobana = LobsterAnalyzer.from_dir(dirpath, prefix=PREFIX)
print(lobana)

# Plot COOP + COHP + DOS.
lobana.plot(title="COOP + COHP + DOS")

# Plot COHP for all sites in from_site_index and Lobster DOS.
lobana.plot_coxp_with_dos(from_site_index=[0, 1])

# Plot orbital projections.
lobana.plot_coxp_with_dos(from_site_index=[0], with_orbitals=True)

#lobana.plot_with_ebands(ebands="out_GSR.nc")
