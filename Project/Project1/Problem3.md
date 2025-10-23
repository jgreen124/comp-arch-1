# Problem 3: Simplescalar setup and benchmark instructions

This file will go through the procedure to set up the Simplescalar instructions as well as how to run the benchmarks as well. Furthermore, it will answer the questions from the labs as well.

## Install Simplesim

Here is a step by step method to install simplesim-3.0

Open a terminal and run the following commands

To install the files locally:
`git clone https://github.com/toddmaustin/simplesim-3.0`
`cd ./simplesim-3.0`

If you need to make changes to the compile options:
`vi Makefile`, and edit the Makefile as needed. Most systems will not need to do this.

`make config-alpha`

`make`

`make sim-tests` - This just verifies installation with no errors

`vi pipeview.pl textprof.pl` - This opens two files in vi/vim, in which the only change that is potentially necessary will be to change the perl path located at the top of each file. This can also be done with any other text editor, but probably won't need to be touched with a normal Perl install

This is the end of the installation. We can verify the install with some more benchmarks: `./sim-cache tests-alpha/bin/test-math`
- You should see `-1e-17 == -1e-17 Worked!` as the output of the sim-cache test


## Run benchmarks

Go to `https://www.ecs.umass.edu/ece/koren/architecture/Simplescalar`. This link has both benchmarks we need to run

### Lab Experiment 1

Click on the `Lab experiment 1` hyperlink. About a quarter of the way down the page, there is a `benchmarks.tar.gz` compressed file. Download that file and extract it within the `simplesim-3.0` folder. In short:

```
[your home directory]
|
|
|____[simplesim-3.0]
        |
        |
        |____[benchmarks]
```

Once extracted, navigate to the `simplesim-3.0/benchmarks` directory of the two folders (i.e. the [your home directory] folder from the above tree)

To run the anagram benchmark

#### Table 1: Benchmark data from the different tests

| Benchmark | Total # of instructions | Load % | Store % | Uncond Branch % | Cond Branch % | Integer Computation % | Floating pt Computation % |
|-----------|------------------------|--------|---------|-----------------|---------------|----------------------|---------------------------|
| Anagram | 25597624 | 25.36 | 9.93 | 4.46 | 10.30 | 44.63 | 5.31 |
| Compress 95 | 88190 | 1.61 | 79.18 | 0.19 | 5.73 | 13.27 | 0.00 |
| Go | 545811998 | 30.62 | 8.17 | 2.58 | 10.96 | 47.64 | 0.03 |
| GCC | 337341166 | 24.67 | 11.47 | 4.12 | 13.33 | 46.30 | 0.11 |

