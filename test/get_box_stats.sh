#!/bin/sh

set -u

die () {
  if [ ! -z "${@:-}" ]
  then
    echo ${@}
  fi
  exit 1
}

# Given a filename containing the abstract interpretation output return the
# number of interference iterations (i.e., outer fixpoint iterations) there
# were.
# The reuslt is stored in NUM_INTERF
getNumInterfIter() {
  if [ -z  "${1:-}" ]
  then
    die "getNumInterfIter(): no argument passed"
  fi

  grep 'Interference Iteration: ' $1 >/tmp/interf.out
  tail -n 1 /tmp/interf.out | sed -n -e 's/^.*Interference Iteration: //p' >/tmp/interf_sed.out
  NUM_INTERF=`cat /tmp/interf_sed.out`
  if [ -z "${NUM_INTERF:-}" ]
  then 
    die "Interference extraction failed"
  fi
}

# Given a filename containing the abstract interpretation output return the
# maximum number of combinational iterations (i.e., permutations of interferences)
# The reuslt is stored in NUM_PERMS
getNumPerms() {
  if [ -z  ${1:-} ]
  then
    die "getNumPerms(): no argument passed"
  fi

  PREF_STR='Max Permutations: '
  grep "$PREF_STR" "$1" >/tmp/interf.out || die "grep error (getNumPerms())"
  tail -n 1 /tmp/interf.out | sed -n -e "s/^.*$PREF_STR//p" >/tmp/interf_sed.out
  NUM_PERMS=`cat /tmp/interf_sed.out`
  if [ -z "${NUM_PERMS:-}" ]
  then 
    die "Permutation extraction failed, file: $1"
  fi
}

getNumErrors() {
  if [ -z  ${1:-} ]
  then
    die "getnumErrors(): no argument passed"
  fi

  PREF_STR='Errors found: '
  grep "$PREF_STR" "$1" >/tmp/interf.out || die "grep error (getNumErrors())"
  tail -n 1 /tmp/interf.out | sed -n -e "s/^.*$PREF_STR//p" >/tmp/interf_sed.out
  NUM_ERRS=`cat /tmp/interf_sed.out`
  if [ -z "${NUM_ERRS:-}" ]
  then 
    die "Error extraction failed, file: $1"
  fi
}


if [ -z ${1:-} ]
then
  die "First argument must be program to test"
fi

if [ ! -d ${1:-} ]
then
  die "Directory not found: $1"
fi

cd $1

# Count number of asserts in .ll file 
ASSERT_STR='.*call void @__assert_fail.*'
#ASSERT_STR='__assert_fail'
NUM_ASSERTS=$(egrep "$ASSERT_STR" main.ll | wc -l)

# Box, no combinational interferences
getNumInterfIter box_ncomb.out
getNumErrors box_ncomb.out
BOX_NCOMB_INTERF=$NUM_INTERF
BOX_NCOMB_ERRS=$NUM_ERRS
BOX_NCOMB_VERIF=$(echo "$NUM_ASSERTS - $NUM_ERRS" | bc)
BOX_NCOMB_TIME=`cat box_ncomb.time`

# Box, combinational (no constraints)
getNumInterfIter box_comb.out
getNumPerms box_comb.out
getNumErrors box_comb.out
BOX_COMB_INTERF=$NUM_INTERF
BOX_COMB_PERMS=$NUM_PERMS
BOX_COMB_ERRS=$NUM_ERRS
BOX_COMB_VERIF=$(echo "$NUM_ASSERTS - $NUM_ERRS" | bc)
BOX_COMB_TIME=`cat box_comb.time`


# Box, combinational + constraints
getNumInterfIter box_constr.out
getNumPerms box_constr.out
getNumErrors box_constr.out
BOX_CONSTR_INTERF=$NUM_INTERF
BOX_CONSTR_ERRS=$NUM_ERRS
BOX_CONSTR_VERIF=$(echo "$NUM_ASSERTS - $NUM_ERRS" | bc)
BOX_CONSTR_PERMS=$NUM_PERMS
BOX_CONSTR_TIME=`cat box_constr.time`

# Box slice with constraints
getNumInterfIter box_slice.out
getNumPerms box_slice.out
getNumErrors box_slice.out
BOX_SLICE_INTERF=$NUM_INTERF
BOX_SLICE_ERRS=$NUM_ERRS
BOX_SLICE_VERIF=$(echo "$NUM_ASSERTS - $NUM_ERRS" | bc)
BOX_SLICE_PERMS=$NUM_PERMS
BOX_SLICE_TIME=`cat box_slice_pdg.time`

# Debugging output incase you wanna see what the variables are defined as
#echo "Box Non-Comb time: $BOX_NCOMB_TIME"
#echo "Box Non-Comb errors: $BOX_NCOMB_ERRS"
#echo "Box Non-Comb verif: $BOX_NCOMB_VERIF"
#echo "Box Non-Comb Interf. Iter: $BOX_NCOMB_INTERF"
#
#echo "Oct Non-Comb time: $OCT_NCOMB_TIME"
#echo "Oct Non-Comb errors: $OCT_NCOMB_ERRS"
#echo "Oct Non-Comb verif: $OCT_NCOMB_VERIF"
#echo "Oct Non-Comb Interf. Iter: $OCT_NCOMB_INTERF"
#
#echo "Box Comb time: $BOX_COMB_TIME"
#echo "Box Comb errors: $BOX_COMB_ERRS"
#echo "Box Comb errors: $BOX_COMB_VERIF"
#echo "Box Comb Interf. Iter: $BOX_COMB_INTERF"
#echo "Box Comb Perms: $BOX_COMB_PERMS"
#
#echo "Oct Comb time: $OCT_COMB_TIME"
#echo "Oct Comb errors: $OCT_COMB_ERRS"
#echo "Oct Comb errors: $OCT_COMB_VERIF"
#echo "Oct Comb Interf. Iter: $OCT_COMB_INTERF"
#echo "Oct Comb Perms: $OCT_COMB_PERMS"
#
#echo "Box Constr time: $BOX_CONSTR_TIME"
#echo "Box Constr errors: $BOX_CONSTR_ERRS"
#echo "Box Constr errors: $BOX_CONSTR_VERIF"
#echo "Box Constr Interf. Iter: $BOX_CONSTR_INTERF"
#echo "Box Constr Perms: $BOX_CONSTR_PERMS"
#
#echo "Oct Constr time: $OCT_CONSTR_TIME"
#echo "OCT Constr errors: $OCT_CONSTR_ERRS"
#echo "OCT Constr errors: $OCT_CONSTR_VERIF"
#echo "Oct Constr Interf. Iter: $OCT_CONSTR_INTERF"
#echo "Oct Constr Perms: $OCT_CONSTR_PERMS"
#
#echo "Box Slice time: $BOX_SLICE_TIME"
#echo "Box Slice errors: $BOX_SLICE_ERRS"
#echo "Box Slice errors: $BOX_SLICE_VERIF"
#echo "Box Slice Interf. Iter: $BOX_SLICE_INTERF"
#echo "Box Slice Perms: $BOX_SLICE_PERMS"
#
#echo "Oct Slice time: $OCT_SLICE_TIME"
#echo "OCT Slice errors: $OCT_SLICE_ERRS"
#echo "OCT Slice errors: $OCT_SLICE_VERIF"
#echo "Oct Slice Interf. Iter: $OCT_SLICE_INTERF"
#echo "Oct Slice Perms: $OCT_SLICE_PERMS"

# Remove trailing slash on test name
TEST_NAME="${1%/}"
LOC=`wc -l <main.c`
THREADS='XXX'

#echo "$BOX_NCOMB_TIME & $BOX_NCOMB_INTERF & $OCT_NCOMB_TIME & $OCT_NCOMB_INTERF & $BOX_COMB_TIME & $BOX_COMB_INTERF & $BOX_COMB_PERMS & $OCT_COMB_TIME & $OCT_COMB_INTERF & $OCT_COMB_PERMS & $BOX_CONSTR_TIME & $BOX_CONSTR_INTERF & $BOX_CONSTR_PERMS & $OCT_CONSTR_TIME & $OCT_CONSTR_INTERF & $OCT_CONSTR_PERMS \\\\"


# Benchmarks description with name and LOC
#echo "$TEST_NAME & $LOC & $THREADS \\\\"

# Main statistics with runtime and errors found
#echo "$TEST_NAME \
#& $BOX_NCOMB_TIME & $BOX_NCOMB_ERRS \
#& $OCT_NCOMB_TIME & $OCT_NCOMB_ERRS \
#& $BOX_COMB_TIME & $BOX_COMB_ERRS \
#& $OCT_COMB_TIME & $OCT_COMB_ERRS \
#& $BOX_CONSTR_TIME & $BOX_CONSTR_ERRS \
#& $OCT_CONSTR_TIME & $OCT_CONSTR_ERRS \
#& $BOX_SLICE_TIME & $BOX_SLICE_ERRS \
#& $OCT_SLICE_TIME & $OCT_SLICE_ERRS \\\\"
echo "$TEST_NAME \
& $BOX_NCOMB_TIME & $BOX_NCOMB_VERIF \
& $BOX_COMB_TIME & $BOX_COMB_VERIF \
& $BOX_CONSTR_TIME & $BOX_CONSTR_VERIF \
& $BOX_SLICE_TIME & $BOX_SLICE_VERIF \\\\"


# Secondary statistics showing number of iterations
#echo "$TEST_NAME \
#& $BOX_NCOMB_INTERF \
#& $OCT_NCOMB_INTERF \
#& $BOX_COMB_INTERF & $BOX_COMB_PERMS \
#& $OCT_COMB_INTERF & $OCT_COMB_PERMS \
#& $BOX_CONSTR_INTERF & $BOX_CONSTR_PERMS \
#& $OCT_CONSTR_INTERF & $OCT_CONSTR_PERMS \
#& $BOX_SLICE_INTERF & $BOX_SLICE_PERMS \
#& $OCT_SLICE_INTERF & $OCT_SLICE_PERMS \\\\"


cd - >&/dev/null
