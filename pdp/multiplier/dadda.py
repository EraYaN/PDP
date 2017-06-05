import copy
import pprint
import math
from bitstring import BitArray

BITS = 32
FULL_ADDER = 0
HALF_ADDER = 1
UNDEFINED = 'u'

#######################################################################

def twos_comp(val, bits):
	if (val & (1 << (bits - 1))) != 0:
		val = val - (1 << bits)
	return val

#######################################################################

class HalfAdder():

	def __init__(self, a, b, s, c_out):
		self.a = a
		self.b = b
		self.sum = s
		self.c_out = c_out

	def simulate(self, a, b):
		assert UNDEFINED not in [a, b]
		s = a ^ b
		c_out = a & b
		return (s, c_out)

	def vhdl(self, label):
		portMap = "{0}: half_adder port map(a => {1}, b => {2}, s => {3}, c_out => {4});"
		return portMap.format(label, self.a, self.b, self.sum, self.c_out)

	def __str__(self):
		return 'HALF --> A: '+self.a+', B: '+self.b+', SUM: '+self.sum+', C_OUT: '+self.c_out

#######################################################################

class FullAdder():

	def __init__(self, a, b, c_in, s, c_out):
		self.a = a
		self.b = b
		self.c_in = c_in
		self.sum = s
		self.c_out = c_out

	def simulate(self, a, b, c_in):
		assert UNDEFINED not in [a, b, c_in]
		s = a ^ b ^ c_in
		c_out = (a & b) | (c_in & (a ^ b))
		return (s, c_out)

	def vhdl(self, label):
		portMap = "{0}: full_adder port map(a => {1}, b => {2}, c_in => {3}, s => {4}, c_out => {5});"
		return portMap.format(label, self.a, self.b, self.c_in, self.sum, self.c_out)

	def __str__(self):
		return 'FULL --> A: '+self.a+', B: '+self.b+', C_IN: '+self.c_in+', SUM: '+self.sum+', C_OUT: '+self.c_out

#######################################################################

class VHDLBuilder():

	def __init__(self, reduction):
		self.cols = reduction.cols
		self.signals = reduction.signals
		self.adders = reduction.adders
		self.bits = reduction.bits

	def buildIncludes(self):
		return "library ieee;\nuse ieee.std_logic_1164.all;\n"

	def buildEntity(self):
		vhdl = """\
entity dadda_mult is
	port(
		sgn    : in  std_logic;
		a, b   : in  std_logic_vector({0} downto 0);
		c_mult : out std_logic_vector({1} downto 0)
	);
end;
"""
		return vhdl.format(self.bits-1, (self.bits * 2)-1)

	def buildComponents(self):
		return """\
	component full_adder
		port(
			a, b, c_in : in  std_logic;
			s, c_out   : out std_logic
		);
	end component;

	component half_adder
		port(
			a, b     : in  std_logic;
			s, c_out : out std_logic
		);
	end component;
	"""

	def buildSignals(self):
		vhdl = ''
		partial = "\tsignal pp{0}, p{0} : std_logic_vector({1} downto 0);\n"
		
		for i in range(self.bits):
			vhdl += partial.format(i, self.bits-1)

		vhdl += "\n"
		count = 0
		maxCount = 12

		for signal in self.signals.keys():
			if signal[0] != 'p' and signal != 'sgn':
				if count == 0:
					vhdl += "\tsignal "
				if count < maxCount:
					vhdl += signal
					count += 1
				if count < maxCount - 1:
					vhdl += ", "
				else:
					vhdl += " : std_logic;\n"
					count = 0

		return vhdl[:-2] + " : std_logic;"

	def buildPPG(self):
		vhdl = ""
		partial = "\tpp{0} <= (pp{0}'range => a({0})) and b;\n"
		for i in range(self.bits):
			vhdl += partial.format(i)
		vhdl += "\n"

		for i in range(self.bits):
			partial = "\tp{0} <= pp{0} when sgn = '0' else "
			if i == self.bits-1:
				partial += "pp{0}({1}) & (not pp{0}({2} downto 0));\n"
			else:
				partial += "(not pp{0}({1})) & pp{0}({2} downto 0);\n"
			vhdl += partial.format(i, self.bits-1, self.bits-2)
		return vhdl

	def buildAdders(self):
		vhdl = ''
		counter = 0
		whitespace = len(str(len(self.adders)))

		for adder in self.adders:
			label = 'adder' + str(counter).zfill(whitespace)
			vhdl += "\t" + adder.vhdl(label) + "\n"
			counter += 1

		resultList = sum(self.cols.values(), [])[:-1]
		results = " & ".join(list(reversed(resultList)))
		vhdl += "\n\tc_mult <= {0};\n".format(results)
		return vhdl

	def build(self):
		includes = self.buildIncludes()
		entity = self.buildEntity()
		components = self.buildComponents()
		signals = self.buildSignals()
		ppg = self.buildPPG()
		adders = self.buildAdders()

		architecture  = "architecture logic of dadda_mult is"
		architecture += "\n{0}\n{1}\nbegin\n{2}\n{3}end;"
		logic = architecture.format(components, signals, ppg, adders)
		return '\n'.join([includes, entity, logic])


#######################################################################

class Dadda:

	def __init__(self, bits, signed):
		self.bits = bits
		self.signed = signed
		self.maxNum = (bits * bits)
		self.iterations = 0
		self.carryNum = 0
		self.sumNum = 0
		self.adders = []
		self.signals = {}
		self.params = {}
		self.cols = {}
		self.setupCols()
		self.setupParams()

	def appendToCol(self, column, item):
		if column in self.cols:
			self.cols[column].append(item)
		else:
			self.cols[column] = [item]
		self.signals[item] = UNDEFINED

	def prependToCol(self, column, item):
		if column in self.cols:
			self.cols[column].insert(0, item)
		else:
			self.cols[column] = [item]
		self.signals[item] = UNDEFINED

	def setupCols(self):
		col = 0
		colOffset = 0

		# Create dict with partial products
		for i in range(self.maxNum):
			currentCol = col + colOffset
			value  = 'p'+str((int) (i / self.bits))
			value += '('+str(i % self.bits)+')'
			self.appendToCol(currentCol, value)

			if col > 0 and (col % (self.bits-1)) == 0:
				colOffset += 1
				col = 0
			else:
				col += 1

		# Insert two bits for signed operation
		self.signals['sgn'] = UNDEFINED
		self.cols[self.bits].insert(0, 'sgn')
		self.appendToCol(currentCol+1, 'sgn')

	def setupParams(self):
		height = 2
		dimension = 1
		self.params[dimension] = height
		
		while True:
			height = (int) (1.5 * self.params[dimension])

			if height < self.bits:
				dimension += 1
				self.params[dimension] = height
				self.iterations = dimension
			else:
				break

	def addAdder(self, adderType, column):
		if adderType == FULL_ADDER:
			c_in = self.cols[column].pop(0)

		a = self.cols[column].pop(0)
		b = self.cols[column].pop(0)
		s = 's' + str(self.sumNum)
		c_out = 'c' + str(self.carryNum)

		if adderType == FULL_ADDER:
			adder = FullAdder(a, b, c_in, s, c_out)
		else:
			adder = HalfAdder(a, b, s, c_out)

		self.adders.append(adder)
		self.prependToCol(column+1, c_out)
		self.appendToCol(column, s)
		self.carryNum += 1
		self.sumNum += 1

	def processCol(self, column, iteration):
		height = self.params[iteration]
		
		while True:
			# Length of column can change while iterating!
			colLength = len(self.cols[column])

			# Apply Dadda's algorithm
			if colLength <= height:
				break
			elif colLength == height + 1:
				self.addAdder(HALF_ADDER, column)
				break
			else:
				self.addAdder(FULL_ADDER, column)

	def run(self):
		# print "DADDA TREE SOLVER"
		# print "By Leon Noordam\n"

		# print "Partial products:"
		# self.printCols()

		count = 1
		for k in range(self.iterations, 0, -1):	
			for i in range(len(self.cols)):
				self.processCol(i, k)
			# print "Iteration %d (j:%d, h:%d)" % (count, k, self.params[k])
			# self.printCols()
			count += 1

		for column in range(len(self.cols)):
			colLength = len(self.cols[column])
			if colLength == 2:
				self.addAdder(HALF_ADDER, column)
			elif colLength == 3:
				self.addAdder(FULL_ADDER, column)

		# print "Final reduction"
		# self.printCols()

		fullAdderCount = 0
		halfAdderCount = 0

		# print "Resulting Adder Structure:"
		for adder in self.adders:
			# print ' ' + str(adder)
			if isinstance(adder, FullAdder):
				fullAdderCount += 1
			else:
				halfAdderCount += 1
		# print "Design consists of: %d Full and %d Half Adders\n" % (fullAdderCount, halfAdderCount)

	def simulate(self, a, b, sgn):
		# Assure that a, b and sgn are strings of bits
		assert len(a) == self.bits
		assert len(b) == self.bits
		assert len(sgn) == 1

		# Calculate partial products
		a.reverse()
		self.signals['sgn'] = 1 if sgn else 0
		for i in range(self.bits):
			partial = BitArray([a[i]] * self.bits) & b
			if self.signed:
				if i == self.bits-1:
					partial = BitArray([partial[0]]) + ~partial[1:]
				else:
					partial = ~BitArray([partial[0]]) + partial[1:]
			
			partial.reverse()
			for k in range(self.bits):
				key = 'p'+str(i)+'('+str(k)+')'
				self.signals[key] = 1 if partial[k] else 0

		# pprint.pprint(self.signals)

		# Loop through adder chain
		for adder in self.adders:
			a = self.signals[adder.a]
			b = self.signals[adder.b]

			if isinstance(adder, FullAdder):
				c_in = self.signals[adder.c_in]
				(s, c_out) = adder.simulate(a, b, c_in)
			else:
				(s, c_out) = adder.simulate(a, b)

			self.signals[adder.sum] = s
			self.signals[adder.c_out] = c_out

		# Accumulate result
		result = ''
		for col in self.cols.values():
			result += str(self.signals[col[0]])

		# Ignore carry and print results
		bits = BitArray('0b'+result)
		bits.reverse()
		bits = bits[1:]
		# print "Simulation results:"
		# print "Binary : " + bits.bin

		dec = bits.int if sgn else bits.uint
		# print "Decimal: " + str(dec)
		return dec

	def printCols(self):
		cols = copy.deepcopy(self.cols)

		# Find boundaries for string length and colulmn depth
		maxLen = 0
		maxDepth = 0
		for col in cols.values():
			for item in col:
				if len(item) > maxLen:
					maxLen = len(item)
			if len(col) > maxDepth:
				maxDepth = len(col)

		# Print the colum values
		for k in range(maxDepth):
			line = ''
			for i in range(len(cols)-1, -1, -1):
				if len(cols[i]):
					line += cols[i].pop(0).rjust(maxLen) + ' '
				else:
					line += ' ' * (maxLen + 1)
			print line
		print ''

#######################################################################

if __name__ == '__main__':

	signed = False
	reduction = Dadda(BITS, signed)
	reduction.run()

	builder = VHDLBuilder(reduction)
	print builder.build()
	exit()

	sgn = BitArray([signed])
	num = 2 ** BITS
	for i in range(num):
		for k in range(num):
			a = BitArray(uint=i, length=BITS)
			b = BitArray(uint=k, length=BITS)
			s = reduction.simulate(a, b, sgn)
			# print('%d x %d = %d' % (i, k, s))
			assert (i * k == s)

	reduction.signed = True
	reduction.run()

	sgn = BitArray([signed])
	num = 2 ** BITS / 2
	for i in range(-num, num):
		for k in range(-num, num):
			a = BitArray(int=i, length=BITS)
			b = BitArray(int=k, length=BITS)
			s = reduction.simulate(a, b, sgn)
			# print('%d x %d = %d' % (i, k, s))
			assert (i * k == s)

	print "Finished running simulation"