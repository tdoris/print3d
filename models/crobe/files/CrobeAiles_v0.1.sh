#!/bin/bash
START_TIME=$SECONDS
#openscad binary - just makes stuff tidy
OPENSCAD=/usr/bin/openscad-nightly 
render() {
  echo "*** Traitement de "${1}"...."
  tput bel
  file_name=tmp/${1}_v0.1.stl
  file_name_old=tmp/${1}_v0.1_old.stl
  # Remove the current output file
  # rm -f ${file_name}
  mv ${file_name} ${file_name_old} 2>/dev/null
  # The actual command
  ${OPENSCAD} -o ${file_name} -D 'which_model="'${1}'"' ./Crobe_Ailes.scad
  echo "*** Fin de traitement de "${1}"...."
  tput bel
}
# render them all at once! ALL THE THINGS!!
# NB the `&` means `as well as` and the `\` stops the newline
# from breaking the command, the newline just makes stuff tidy
render "Aile2Light" & render "Aile1Light" & render "Aile2" & render "Aile1"
#fin
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "finished!! execution time: $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"
