-- Simple Lua example for LuaForge compiler testing
-- This file demonstrates basic Lua constructs supported by LuaForge

-- Local variable declarations
local x = 10
local y = 20
local name = "LuaForge"
local isActive = true

-- Arithmetic operations
local sum = x + y
local product = x * y
local division = y / x
local modulo = y % x
local power = x ^ 2

-- String operations
local greeting = "Hello, " .. name .. "!"
local message = "Sum: " .. sum

-- Conditional statements
if x < y then
    print("x is less than y")
else
    print("x is greater than or equal to y")
end

-- Boolean operations
if isActive and x > 5 then
    print("Active and x is greater than 5")
end

if not isActive or y < 30 then
    print("Not active or y is less than 30")
end

-- While loop
local counter = 0
while counter < 5 do
    print("Counter: " .. counter)
    counter = counter + 1
end

-- For loop
for i = 1, 10 do
    print("Iteration: " .. i)
end

-- For loop with step
for i = 0, 20, 2 do
    print("Even number: " .. i)
end

-- Function definition
function add(a, b)
    return a + b
end

-- Function call
local result = add(15, 25)
print("Function result: " .. result)

-- Table creation and usage
local numbers = {1, 2, 3, 4, 5}
local person = {
    name = "John",
    age = 30,
    city = "New York"
}

-- Table access
print("First number: " .. numbers[1])
print("Person name: " .. person.name)

-- Nested function
function calculate()
    local a = 10
    local b = 20
    
    function multiply(x, y)
        return x * y
    end
    
    return multiply(a, b)
end

local nested_result = calculate()
print("Nested function result: " .. nested_result)

-- Return statement
function get_max(a, b)
    if a > b then
        return a
    else
        return b
    end
end

local max_value = get_max(x, y)
print("Maximum value: " .. max_value)