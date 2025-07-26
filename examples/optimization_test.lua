-- Optimization test file for LuaForge compiler
-- This file contains various examples to test the compiler's optimization capabilities

-- Constant folding tests
local const1 = 5 + 3        -- Should be optimized to 8
local const2 = 10 * 2       -- Should be optimized to 20
local const3 = 15 / 3       -- Should be optimized to 5
local const4 = 2 ^ 3        -- Should be optimized to 8
local const5 = "Hello" .. " World"  -- Should be optimized to "Hello World"

-- Boolean constant folding
local bool1 = true and false   -- Should be optimized to false
local bool2 = false or true    -- Should be optimized to true
local bool3 = not true         -- Should be optimized to false
local bool4 = not false        -- Should be optimized to true

-- Dead code elimination tests
if true then
    print("This should remain")
else
    print("This should be eliminated")  -- Dead code
end

if false then
    print("This should be eliminated")  -- Dead code
else
    print("This should remain")
end

-- While loop with constant condition
while false do
    print("This loop should be eliminated")  -- Dead code
end

-- Peephole optimizations
local x = 10
local y = x + 0     -- Should be optimized to y = x
local z = x * 1     -- Should be optimized to z = x
local w = x * 0     -- Should be optimized to w = 0

-- Boolean optimizations
local a = true
local b = false

if a and true then          -- Should be optimized to if a then
    print("Optimized and")
end

if b or false then          -- Should be optimized to if b then
    print("Optimized or")
end

-- Unreachable code after return
function test_return()
    return 42
    print("This should be eliminated")  -- Unreachable code
    local unreachable = 10              -- Unreachable code
end

-- Redundant assignments
local temp = 5
temp = 5        -- Redundant assignment (same value)
temp = 10       -- This should remain

-- Complex constant expressions
local complex1 = (5 + 3) * (10 - 2)    -- Should be optimized to 8 * 8 = 64
local complex2 = (2 ^ 3) + (4 * 5)     -- Should be optimized to 8 + 20 = 28
local complex3 = (true and false) or (not true)  -- Should be optimized to false

-- Nested constant expressions
local nested = ((1 + 2) * 3) + ((4 + 5) * 6)  -- Should be optimized to 9 + 54 = 63

-- String concatenation optimization
local str1 = "Part1" .. "Part2" .. "Part3"  -- Should be optimized to "Part1Part2Part3"

-- Mathematical identities
local identity1 = x + 0     -- Should be optimized to x
local identity2 = x - 0     -- Should be optimized to x
local identity3 = x * 1     -- Should be optimized to x
local identity4 = x / 1     -- Should be optimized to x
local identity5 = x ^ 1     -- Should be optimized to x

-- Zero optimizations
local zero1 = x * 0         -- Should be optimized to 0
local zero2 = 0 * x         -- Should be optimized to 0
local zero3 = x - x         -- Should be optimized to 0

-- Comparison optimizations
if 5 > 3 then               -- Should be optimized to if true then
    print("Always true")
end

if 2 > 5 then               -- Should be optimized to if false then (dead code)
    print("Never executed")
end

-- Loop optimizations
for i = 1, 0 do             -- Loop that never executes (dead code)
    print("Never executed")
end

for i = 5, 5 do             -- Loop that executes exactly once
    print("Executes once: " .. i)
end

-- Function with constant return
function always_returns_ten()
    return 5 + 5            -- Should be optimized to return 10
end

-- Conditional with constant condition in function
function conditional_test()
    if 1 == 1 then          -- Should be optimized to always true
        return "Always executed"
    else
        return "Never executed"  -- Dead code
    end
end

-- Test function calls
local result1 = always_returns_ten()
local result2 = conditional_test()

print("Optimization test completed")