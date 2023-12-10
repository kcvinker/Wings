incpath = r"C:\Users\kcvin\OneDrive\Programming\D_Lang\Wings"           # IMPORTANT VAR
dbgcmd = ["dmd", f"-I=\"{incpath}\"", "-m64", "-debug", "-i", "-run"]   # IMPORTANT VAR
rlscmd = ["dmd", f"-I=\"{incpath}\"", "-m64", "-release", "-i"]         # IMPORTANT VAR