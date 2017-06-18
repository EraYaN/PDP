
variants = ['original','8kb','16kb','mult','div']
combinations = [
    ['8kb','mult'],
    ['8kb','div'],
    ['16kb','mult'],
    ['16kb','div'],
    ['8kb','mult','div'],
    ['16kb','mult','div']
]
benches = [
'cjpeg',
'divide',
'multiply',
'pi',
'fir',
'rsa',
'ssd',
'ssearch',
'susan',
'bench_all'
]

orig_freq = 39.58

frequency = { 'original': orig_freq, '8kb': orig_freq, '16kb': 40, 'mult': 40, 'div': 40}

original_area = 541.5
areas_increase = { 'original': 0.000, '8kb': 0.000, '16kb': 5.000, 'mult': 535.250, 'div': 115.000}
original_benchmarkScore = {
    'cjpeg':29.316,
    'divide':274.860,
    'multiply':155.283,
    'pi':845.295,
    'fir':187.538,
    'rsa':577.505,
    'ssd':860.871,
    'ssearch':475.458,
    'susan':916.970,
    'bench_all':4323.096
}
benchmarkScore_improvement = {
    'cjpeg':{'original': 0,'8kb': 4.787, '16kb': 5.831, 'mult': 0.021, 'div': 0.189},
    'divide':{'original': 0,'8kb': 1.022, '16kb': 9.945, 'mult': 37.822, 'div': 0.102},
    'multiply':{'original': 0,'8kb': 0.386, '16kb': 4.957, 'mult': 23.128, 'div': 0.046},
    'pi':{'original': 0,'8kb': 0.664, '16kb': 3.469, 'mult': 383.920, 'div': 114.009},
    'fir':{'original': 0,'8kb': 0.892, '16kb': 1.367, 'mult': 102.210, 'div': 0.000},
    'rsa':{'original': 0,'8kb': 13.224, '16kb': 17.353, 'mult': 124.255, 'div': 0.002},
    'ssd':{'original': 0,'8kb': 37.510, '16kb': 145.664, 'mult': 328.050, 'div': 2.432},
    'ssearch':{'original': 0,'8kb': 8.821, '16kb': 8.089, 'mult': 0.000, 'div': 0.000},
    'susan':{'original': 0,'8kb': 137.363, '16kb': 141.086, 'mult': 517.442, 'div': 0.659},
    'bench_all':{'original': 0,'8kb': 321.735, '16kb': 454.828, 'mult': 1516.849, 'div': 117.439}
}


def CombinedBenchmarkScore(combinedvariants,bench,freq):
    benchmarkScore = original_benchmarkScore[bench]
    for variant in combinedvariants:
        benchmarkScore -= benchmarkScore_improvement[bench][variant]
    return benchmarkScore*(orig_freq/freq)

def CombinedArea(combinedvariants):
    area = original_area
    for variant in combinedvariants:
        area += areas_increase[variant]
    return area

def BenchmarkScore(variant,bench):
    return (original_benchmarkScore[bench]-benchmarkScore_improvement[bench][variant])*(orig_freq/frequency[variant])

def Area(variant):
    return original_area+areas_increase[variant]

def Performance(benchmarkScore):
    return 1e6/benchmarkScore

def BenchmarkScorePerArea(benchmarkScore,area):
    return benchmarkScore/area

def BenchmarkScoreArea(benchmarkScore,area):
    return benchmarkScore/1e6*area

def PerformanceArea(performance,area):
    return performance*1000/area

bench = 'bench_all'

for variant in variants:
    
    benchmarkScore = BenchmarkScore(variant,bench)
    area = Area(variant)
    performance = Performance(benchmarkScore)
    benchmarkScoreperarea = BenchmarkScorePerArea(benchmarkScore,area)
    benchmarkScorearea = BenchmarkScoreArea(benchmarkScore,area)
    performancearea = PerformanceArea(performance,area)

    #print("Variant:                 {0}".format(variant))    
    #print("Benchmark:               {0}".format(bench))
    #print("BenchmarkScore:          {0:12,.3f} BS".format(benchmarkScore))
    #print("Area:                    {0:12,.3f} A_CLB".format(area))
    #print("Performance:             {0:12,.3f} 1e6/BS".format(performance))
    #print("BenchmarkScorePerArea:   {0:12,.3f} BS/A_CLB".format(benchmarkScoreperarea))
    #print("BenchmarkScoreArea:      {0:12,.3f} BS/1e6*A_CLB".format(benchmarkScorearea))
    #print("PerformanceArea:         {0:12,.3f} Perf*1e3/A_CLB".format(performancearea))
    print("{:14} & {:8} & {:10.2f} & {:10.2f} & {:10.2f} & {:10.2f} & {:10.2f} \\\\".format(
        variant,
        bench,
        benchmarkScore,
        area,
        performance,
        benchmarkScoreperarea,
        benchmarkScorearea
        )
    )

for combination in combinations:
    variant = '+'.join(combination)
    benchmarkScore = CombinedBenchmarkScore(combination,bench,40)
    area = CombinedArea(combination)
    performance = Performance(benchmarkScore)
    benchmarkScoreperarea = BenchmarkScorePerArea(benchmarkScore,area)
    benchmarkScorearea = BenchmarkScoreArea(benchmarkScore,area)
    performancearea = PerformanceArea(performance,area)

    #print("Combination:             {0}".format(variant))
    #print("Benchmark:               {0}".format(bench))
    #print("BenchmarkScore:          {0:12,.3f} BS".format(benchmarkScore))
    #print("Area:                    {0:12,.3f} A_CLB".format(area))
    #print("Performance:             {0:12,.3f} 1e6/BS".format(performance))
    #print("BenchmarkScorePerArea:   {0:12,.3f} BS/A_CLB".format(benchmarkScoreperarea))
    #print("BenchmarkScoreArea:      {0:12,.3f} BS/1e6*A_CLB".format(benchmarkScorearea))
    #print("PerformanceArea:         {0:12,.3f} Perf*1e3/A_CLB".format(performancearea))
    print("{:14} & {:8} & {:10.2f} & {:10.2f} & {:10.2f} & {:10.2f} & {:10.2f} \\\\".format(
        variant,
        bench,
        benchmarkScore,
        area,
        performance,
        benchmarkScoreperarea,
        benchmarkScorearea
        )
    )






