import matplotlib.pyplot as plt
import collections
import sys

# Check command line input
if len(sys.argv) != 2:
	print "Usage: python count.py filename.txt"
	exit(0)

# Read file contents and parse them
filename = sys.argv[1]

try:
	f = open(filename)
	matches = eval(f.read())
except IOError:
	print "Could not open %s" % filename
	exit(0)

# Sort instructions
items = collections.OrderedDict(sorted(matches.items()))

# Generate title based on input file
titleMap = {
	'_all.txt'    : 'full_bench_all.bin',
	'divide.txt'  : 'divide.bin',
	'fir.txt'     : 'fir.bin',
	'jpeg.txt'    : 'full_cjpeg.bin',
	'multiply.txt': 'multiply.bin',
	'pi.txt'      : 'pi.bin',
	'rsa.txt'     : 'rsa.bin',
	'ssd.txt'     : 'ssd_full.bin',
	'ssearch.txt' : 'ssearch.bin',
	'susan.txt'   : 'susan_full.bin',
}

if filename in titleMap:
	title = titleMap[filename]
else:
	title = filename

# Plot bar chart
fig = plt.figure(figsize=(14, 10))
plt.bar(range(len(items)), items.values(), align='center')
plt.xticks(range(len(items)), items.keys(), rotation='vertical')
plt.ylabel('Instruction count')
plt.title('Dynamic profiling of '+title)
plt.xlim(-1, len(items))
fig.tight_layout()
plt.show()