-- Optimizer module for LuaForge
-- Applies various optimizations to the AST

local Optimizer = {}

function Optimizer.new()
    local optimizer = {}
    setmetatable(optimizer, {__index = Optimizer})
    return optimizer
end

-- Helper function to check if a node is a literal
function Optimizer:is_literal(node)
    return node and node.type == "Literal"
end

-- Helper function to get literal value
function Optimizer:get_literal_value(node)
    if self:is_literal(node) then
        return node.value
    end
    return nil
end

-- Constant folding optimization
function Optimizer:constant_folding(ast)
    return self:traverse_and_transform(ast, function(node)
        if node.type == "BinaryExpression" then
            local left_val = self:get_literal_value(node.left)
            local right_val = self:get_literal_value(node.right)
            
            if left_val ~= nil and right_val ~= nil then
                local result = nil
                local op = node.operator
                
                if op == "+" then
                    result = left_val + right_val
                elseif op == "-" then
                    result = left_val - right_val
                elseif op == "*" then
                    result = left_val * right_val
                elseif op == "/" then
                    if right_val ~= 0 then
                        result = left_val / right_val
                    end
                elseif op == "%" then
                    if right_val ~= 0 then
                        result = left_val % right_val
                    end
                elseif op == "^" then
                    result = left_val ^ right_val
                elseif op == ".." then
                    result = tostring(left_val) .. tostring(right_val)
                elseif op == "==" then
                    result = left_val == right_val
                elseif op == "~=" then
                    result = left_val ~= right_val
                elseif op == "<" then
                    result = left_val < right_val
                elseif op == ">" then
                    result = left_val > right_val
                elseif op == "<=" then
                    result = left_val <= right_val
                elseif op == ">=" then
                    result = left_val >= right_val
                elseif op == "and" then
                    result = left_val and right_val
                elseif op == "or" then
                    result = left_val or right_val
                end
                
                if result ~= nil then
                    return {
                        type = "Literal",
                        value = result,
                        raw = tostring(result)
                    }
                end
            end
        elseif node.type == "UnaryExpression" then
            local operand_val = self:get_literal_value(node.operand)
            
            if operand_val ~= nil then
                local result = nil
                local op = node.operator
                
                if op == "-" then
                    result = -operand_val
                elseif op == "not" then
                    result = not operand_val
                end
                
                if result ~= nil then
                    return {
                        type = "Literal",
                        value = result,
                        raw = tostring(result)
                    }
                end
            end
        end
        
        return node
    end)
end

-- Dead code elimination
function Optimizer:dead_code_elimination(ast)
    return self:traverse_and_transform(ast, function(node)
        if node.type == "IfStatement" then
            local condition_val = self:get_literal_value(node.condition)
            
            if condition_val ~= nil then
                if condition_val then
                    -- Condition is always true, return consequent
                    return {
                        type = "Program",
                        body = node.consequent
                    }
                else
                    -- Condition is always false, return alternate or empty
                    if node.alternate then
                        return {
                            type = "Program",
                            body = node.alternate
                        }
                    else
                        return {
                            type = "Program",
                            body = {}
                        }
                    end
                end
            end
        elseif node.type == "WhileStatement" then
            local condition_val = self:get_literal_value(node.condition)
            
            if condition_val ~= nil and not condition_val then
                -- While condition is always false, remove the loop
                return {
                    type = "Program",
                    body = {}
                }
            end
        end
        
        return node
    end)
end

-- Peephole optimization
function Optimizer:peephole_optimization(ast)
    return self:traverse_and_transform(ast, function(node)
        -- Optimize boolean expressions
        if node.type == "BinaryExpression" then
            if node.operator == "and" then
                local left_val = self:get_literal_value(node.left)
                local right_val = self:get_literal_value(node.right)
                
                -- false and X -> false
                if left_val == false then
                    return {
                        type = "Literal",
                        value = false,
                        raw = "false"
                    }
                end
                
                -- true and X -> X
                if left_val == true then
                    return node.right
                end
                
                -- X and false -> false
                if right_val == false then
                    return {
                        type = "Literal",
                        value = false,
                        raw = "false"
                    }
                end
                
                -- X and true -> X
                if right_val == true then
                    return node.left
                end
            elseif node.operator == "or" then
                local left_val = self:get_literal_value(node.left)
                local right_val = self:get_literal_value(node.right)
                
                -- true or X -> true
                if left_val == true then
                    return {
                        type = "Literal",
                        value = true,
                        raw = "true"
                    }
                end
                
                -- false or X -> X
                if left_val == false then
                    return node.right
                end
                
                -- X or true -> true
                if right_val == true then
                    return {
                        type = "Literal",
                        value = true,
                        raw = "true"
                    }
                end
                
                -- X or false -> X
                if right_val == false then
                    return node.left
                end
            end
            
            -- Arithmetic optimizations
            if node.operator == "+" then
                local left_val = self:get_literal_value(node.left)
                local right_val = self:get_literal_value(node.right)
                
                -- X + 0 -> X
                if right_val == 0 then
                    return node.left
                end
                
                -- 0 + X -> X
                if left_val == 0 then
                    return node.right
                end
            elseif node.operator == "*" then
                local left_val = self:get_literal_value(node.left)
                local right_val = self:get_literal_value(node.right)
                
                -- X * 0 -> 0
                if right_val == 0 then
                    return {
                        type = "Literal",
                        value = 0,
                        raw = "0"
                    }
                end
                
                -- 0 * X -> 0
                if left_val == 0 then
                    return {
                        type = "Literal",
                        value = 0,
                        raw = "0"
                    }
                end
                
                -- X * 1 -> X
                if right_val == 1 then
                    return node.left
                end
                
                -- 1 * X -> X
                if left_val == 1 then
                    return node.right
                end
            end
        end
        
        return node
    end)
end

-- Generic tree traversal and transformation
function Optimizer:traverse_and_transform(node, transform_func)
    if not node then return nil end
    
    -- First, recursively transform children
    local new_node = {}
    for key, value in pairs(node) do
        if type(value) == "table" then
            if value.type then
                -- Single AST node
                new_node[key] = self:traverse_and_transform(value, transform_func)
            elseif type(value) == "table" and #value > 0 then
                -- Array of nodes
                new_node[key] = {}
                for i, child in ipairs(value) do
                    local transformed = self:traverse_and_transform(child, transform_func)
                    if transformed then
                        if transformed.type == "Program" and transformed.body then
                            -- Flatten program nodes
                            for _, stmt in ipairs(transformed.body) do
                                table.insert(new_node[key], stmt)
                            end
                        else
                            table.insert(new_node[key], transformed)
                        end
                    end
                end
            else
                new_node[key] = value
            end
        else
            new_node[key] = value
        end
    end
    
    -- Then apply transformation to this node
    return transform_func(new_node)
end

return Optimizer