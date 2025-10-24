# Simplescalar installation

These instructions are tailored to linux

## 1. Clone the repository
`git clone https://github.com/toddmaustin/simplesim-3.0`

The repository is public, so you don't need an account to pull the repo

After cloning the repo, run `cd simplesim-3.0`

## 2. Configure Makefile and build
1 . `vim Makefile`
This only needs to be run if changes are desired. Most systems will not need to make any changes to this.

2. Depending on whether you wish to install PISA or alpha
- `make config-pisa`
- `make config-alpha`

Only one of these will need to be run to configure the build

3. After running the make config:
`make`
This will build the simplescalar simulator

4. After the build finishes, run `make sim-tests` to test the simulator built correctly.

5. run `vi pipeview.pl textprof.pl`. This opens two files in Vim, where you might need to change the top line of each of these files if your Perl directory is not in `/usr/bin`

## Running benchmarks

### For lab 1
1. Go to `http://www.ecs.umass.edu/ece/koren/architecture/Simplescalar/lab1.htm` and download the benchmarks.tar.gz file located on the webpage.

2. Move the `benchmarks.tar.gz` file into the `/simplesim-3.0` directory. 

3. Run `tar -xzvf benchmarks.tar.gz` to extract the benchmarks. Then run `cd benchmarks`. From now on we will be working with the `/simplesim-3.0/benchmarks` as the working directory.

4. To run a benchmark use `../sim-profile` command
- `../sim-profile -iclass true -brprof true -redir:sim [target_file.prof] [target_benchmark] [input_file_if_necessary]`
- Examples: `../sim-profile -iclass true -brprof true -redir:sim anagram.prof anagram.alpha words < anagram.in > /dev/null` and `../sim-profile -iclass true -brprof true -redir:sim go.prof go.alpha 50 9 2stone9.in > /dev/null`
- Different benchmarks have different parameters, but the output will always be in the `[target_file.prof]` file in the `/simplesim-3.0/benchmarks` directory. 

5. the pisa simulator uses different test files but the same `../sim-profile` command will be used

*** 5. To switch compiler mode ***
```
cd ..
make clean
make config-[type]
make
```
where `[type]` is either `pisa` or `alpha`







