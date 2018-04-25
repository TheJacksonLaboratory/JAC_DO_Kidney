batch_size = 10
N = 262 # or 6716
shell_script = 'scanBestMarker_p_Erk1_m.sh'
f = open('scanBestMarker_all_p_Erk1_m.sh', 'w+')


i = 0
while i<N:
    batch = range(i+1, min(i+batch_size, N)+1)
    batch_str = " ".join([str(j) for j in batch])
    i += batch_size
    line = 'qsub -o log_output_scanBestMarker_p_Erk1_m.txt -e log_error_scanBestMarker_p_Erk1_m.txt -v col="' + batch_str + '" ' + shell_script + "\n"
    f.write(line)
