-- Advanced Lua example for LuaForge compiler
-- This file demonstrates more complex Lua constructs and patterns

-- Advanced function definitions with multiple parameters
function fibonacci(n)
    if n <= 1 then
        return n
    else
        return fibonacci(n - 1) + fibonacci(n - 2)
    end
end

-- Function with variable arguments (simplified)
function sum_all(a, b, c)
    local total = 0
    if a then total = total + a end
    if b then total = total + b end
    if c then total = total + c end
    return total
end

-- Higher-order function simulation
function apply_operation(x, y, operation)
    if operation == "add" then
        return x + y
    elseif operation == "multiply" then
        return x * y
    elseif operation == "subtract" then
        return x - y
    else
        return 0
    end
end

-- Complex table operations
local matrix = {
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
}

-- Function to access matrix elements
function get_matrix_element(mat, row, col)
    return mat[row][col]
end

-- Function to calculate matrix sum
function matrix_sum(mat)
    local total = 0
    for i = 1, 3 do
        for j = 1, 3 do
            total = total + mat[i][j]
        end
    end
    return total
end

-- Recursive factorial function
function factorial(n)
    if n <= 1 then
        return 1
    else
        return n * factorial(n - 1)
    end
end

-- Function with multiple return values (simplified)
function divide_with_remainder(dividend, divisor)
    local quotient = dividend / divisor
    local remainder = dividend % divisor
    return quotient, remainder
end

-- Complex conditional logic
function classify_number(num)
    if num > 0 then
        if num % 2 == 0 then
            return "positive even"
        else
            return "positive odd"
        end
    elseif num < 0 then
        if num % 2 == 0 then
            return "negative even"
        else
            return "negative odd"
        end
    else
        return "zero"
    end
end

-- Advanced loop patterns
function find_prime_numbers(limit)
    local primes = {}
    local count = 0
    
    for num = 2, limit do
        local is_prime = true
        
        for i = 2, num - 1 do
            if num % i == 0 then
                is_prime = false
                break
            end
        end
        
        if is_prime then
            count = count + 1
            primes[count] = num
        end
    end
    
    return primes, count
end

-- Function with nested scopes
function complex_calculation()
    local outer_var = 10
    
    function inner_function(x)
        local inner_var = outer_var * 2
        return x + inner_var
    end
    
    local result = inner_function(5)
    return result + outer_var
end

-- String manipulation functions
function reverse_string(str)
    local reversed = ""
    local length = string.len(str)
    
    for i = length, 1, -1 do
        reversed = reversed .. string.sub(str, i, i)
    end
    
    return reversed
end

function count_vowels(str)
    local vowels = "aeiouAEIOU"
    local count = 0
    local length = string.len(str)
    
    for i = 1, length do
        local char = string.sub(str, i, i)
        if string.find(vowels, char) then
            count = count + 1
        end
    end
    
    return count
end

-- Advanced table manipulation
function merge_tables(table1, table2)
    local merged = {}
    local index = 1
    
    -- Add elements from first table
    for i = 1, #table1 do
        merged[index] = table1[i]
        index = index + 1
    end
    
    -- Add elements from second table
    for i = 1, #table2 do
        merged[index] = table2[i]
        index = index + 1
    end
    
    return merged
end

function find_max_in_table(tbl)
    local max = tbl[1]
    
    for i = 2, #tbl do
        if tbl[i] > max then
            max = tbl[i]
        end
    end
    
    return max
end

-- Main execution
local fib_result = fibonacci(10)
print("Fibonacci(10): " .. fib_result)

local sum_result = sum_all(10, 20, 30)
print("Sum result: " .. sum_result)

local operation_result = apply_operation(15, 25, "add")
print("Operation result: " .. operation_result)

local matrix_total = matrix_sum(matrix)
print("Matrix sum: " .. matrix_total)

local fact_result = factorial(5)
print("Factorial(5): " .. fact_result)

local quotient, remainder = divide_with_remainder(17, 5)
print("17 / 5 = " .. quotient .. " remainder " .. remainder)

local classification = classify_number(-7)
print("Classification of -7: " .. classification)

local primes, prime_count = find_prime_numbers(20)
print("Found " .. prime_count .. " prime numbers up to 20")

local complex_result = complex_calculation()
print("Complex calculation result: " .. complex_result)

local test_string = "Hello World"
local reversed = reverse_string(test_string)
local vowel_count = count_vowels(test_string)
print("Reversed: " .. reversed)
print("Vowel count: " .. vowel_count)

local table1 = {1, 2, 3}
local table2 = {4, 5, 6}
local merged = merge_tables(table1, table2)
local max_value = find_max_in_table(merged)
print("Max value in merged table: " .. max_value)

print("Advanced example completed successfully!")