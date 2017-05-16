#!/bin/bash

DROPBOX_HOME=~/Dropbox/group9

printf 'Building benchmarks..\n'
make -C benchmarks/pi/ images > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	printf 'Building the benchmark images succeeded.\n'
else
	printf 'Building the benchmark images failed.\n'
	exit 1
fi
make -C benchmarks/_all/ clean image_all > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	printf 'Building the combined benchmark image succeeded.\n'
else
	printf 'Building the combined benchmark image failed.\n'
	exit 2
fi

printf 'Copying generated benchmarks and design bit file..\n'

cp -f pdp_ISE/top_ml410.bit $DROPBOX_HOME/bench_all.bit
if [[ $? -eq 0 ]]; then
	printf 'Copying the design bit file succeeded.\n'
else
	printf 'Copying the design bit file failed.\n'
	exit 4
fi
cp -f benchmarks/_all/bench_all.bin $DROPBOX_HOME/bench_all.bin 
if [[ $? -eq 0 ]]; then
	printf 'Copying the combined benchmark image succeeded.\n'
else
	printf 'Copying the combined benchmark image failed.\n'
	exit 3
fi
# cp -f benchmarks/jpeg/cjpeg.bin $DROPBOX_HOME/cjpeg.bin 
# if [[ $? -eq 0 ]]; then
# 	printf 'Copying the JPEG benchmark image succeeded.\n'
# else
# 	printf 'Copying the JPEG benchmark image failed.\n'
# 	exit 3
# fi


printf 'Done. FPGA Server will take it from here.\n'