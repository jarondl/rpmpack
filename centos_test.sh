#!/bin/bash

echo "registering container with docker"
"${TEST_SRCDIR}/rpmpack/centos_with_rpm" || { echo "failed to register"; exit 1; }


failed=0
cmds=("rpm -Vvv rpmtest" "find /var/lib/rpmtest -printf '%u\t%g\t%m\t%p\t%s\t%l'")
goldens=("golden_V.txt" "golden_find.txt")
for (( i=0; i<"${#cmds[@]}"; i++ )); do
echo "test ${i}: install the package and run ${cmds[$i]}"
OUT=$(docker run bazel:centos_with_rpm sh -c "rpm -ivvv /root/rpmtest.rpm > /dev/null && rpm -Vvv rpmtest")
if [[ $? -ne 0 ]]; then
    echo "docker or rpm install or rpm -V failed"
    failed=1
else
    echo "rpm install OK"
fi

d=$(diff "${TEST_SRCDIR}/rpmpack/testdata/golden_V.txt" <(echo "${OUT}"))
if [[ $? -eq 0 ]]; then
    echo "files equal"
elif [[ $? -eq 1 ]]; then
    echo "unexpected rpm -V output (diff want->got):"
    echo "${d}"
    failed=1
else
    echo "diff failed with exit code $?"
    failed=1
fi

if [[ "${failed}" -ne "0" ]]; then
    echo "failed"
    exit 1
fi

