//
//*******
//
//	filename: MTRandom.swift
//	author: Zack Brown
//	date: 10/07/2014
//
//	Swift Mersenne Twister
//
//	Based on the awesome Objective C implementation by Adam Preble
//
//	https://github.com/preble/MTRandom
//
//*******
//
//	source
//	https://raw.githubusercontent.com/CaptainRedmuff/MTRandom/master/MTRandom/MTRandom.swift
//	changed "init()" to "override init()"
//	changed "NSDate.timeIntervalSinceReferenceDate()" to "NSDate.timeIntervalSinceReferenceDate() * 1e6" for better randomness
//	added "% NSIntegerMax" for previous option works correctly at 32-bit devices
//

let n = 624
let m = 392
let matrix_a = 0x9908b0df		/* constant vector a */
let upper_mask = 0x80000000		/* most significant w-r bits */
let lower_mask = 0x7fffffff		/* least significant r bits */

import Foundation

class MTRandom: NSObject
{
	var mt: [Int] = [Int](count: n, repeatedValue: Int.max)
	
	var mti: Int = 0
	
	override init()
	{
		super.init()
		let a: Int64 = Int64(NSDate.timeIntervalSinceReferenceDate() * 1e6)
		let _seed = Int(a & Int64(Int.max))
		seed(_seed)
	//	seed( Int( NSDate.timeIntervalSinceReferenceDate() ) )
	}
	
	convenience init(given_seed: Int)
	{
		self.init()
		self.seed(given_seed)
	}
	
	func seed(seed: Int)
	{
		println(seed)
		println(seed & 0xffffffff)
		println(mt[0])

		mt[Int(0)] = Int(seed & 0xffffffff)

		for mti in 1 ..< n {
			mt[mti] = (1_812_433_253 * (mt[mti - 1] ^ (mt[mti - 1] >> 30)) + mti)
			
			/* See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. */
			/* In the previous versions, MSBs of the seed affect   */
			/* only MSBs of the array mt[].                        */
			/* 2002/01/09 modified by Makoto Matsumoto             */
			
			mt[mti] &= 0xffffffff
			/* for >32 bit machines */
		}
	}
	
	// generates a random number on [0,0xffffffff]-interval
	func randomInteger() -> Int
	{
		var y: Int
		
		var mag01 = [0x0, matrix_a]
		/* mag01[x] = x * MATRIX_A  for x=0,1 */
		
		if(mti >= n)
		{
			/* generate N words at one time */
			var kk: Int
			
			if(mti == n + 1)	/* if init_genrand() has not been called, */
			{
				seed(5489)		/* a default initial seed is used */
			}
			
			for(kk = 0; kk < n-m; kk++)
			{
				y = (mt[kk] & upper_mask) | (mt[kk + 1] & lower_mask)
				
				mt[kk] = mt[kk + m] ^ (y >> 1) ^ mag01[y & 0x1]
			}
			
			for(;kk < n - 1; kk++)
			{
				y = (mt[kk] & upper_mask) | (mt[kk + 1] & lower_mask)
				
				mt[kk] = mt[kk+(m - n)] ^ (y >> 1) ^ mag01[y & 0x1]
			}
			
			y = (mt[n - 1] & upper_mask) | (mt[0] & lower_mask)
			
			mt[n - 1] = mt[m - 1] ^ (y >> 1) ^ mag01[y & 0x1]
			
			mti = 0;
		}
		
		y = mt[mti++];
		
		/* Tempering */
		y ^= (y >> 11)
		y ^= (y << 7) & 0x9d2c5680
		y ^= (y << 15) & 0xefc60000
		y ^= (y >> 18)
		
		return y
	}
	
	/* generates a random number on [0,1]-real-interval */
	func randomDouble() -> Double
	{
		return Double(randomInteger()) * Double(1.0 / 4294967295.0)
		/* divided by 2^32-1 */
	}
	
	/* generates a random number on [0,1)-real-interval */
	func randomDouble0To1Exclusive() -> Double
	{
		return Double(randomInteger()) * Double(1.0 / 4294967296.0)
		/* divided by 2^32 */
	}
	
	func randomBool() -> Bool
	{
		return randomInteger() < 2147483648
	}
	
	func randomIntegerFrom(start: Int, stop: Int) -> Int
	{
		let width = 1 + stop - start
		
		return start + Int(floor(randomDouble0To1Exclusive() * Double(width)))
	}
	
	func randomDoubleFrom(start: Double, stop: Double) -> Double
	{
		let range = stop - start;
		
		let random = randomDouble()
		
		return start + random * range;
	}
}