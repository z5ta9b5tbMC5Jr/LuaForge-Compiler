-- Code Generator module for LuaForge
-- Converts AST into Lua-compatible bytecode

local CodeGen = {}

-- Lua opcodes (simplified subset)
local Opcodes = {
    MOVE = 0,      -- R(A) := R(B)
    LOADK = 1,     -- R(A) := Kst(Bx)
    LOADBOOL = 2,  -- R(A) := (Bool)B; if (C) pc++
    LOADNIL = 3,   -- R(A) := ... := R(B) := nil
    GETUPVAL = 4,  -- R(A) := UpValue[B]
    GETGLOBAL = 5, -- R(A) := Gbl[Kst(Bx)]
    GETTABLE = 6,  -- R(A) := R(B)[RK(C)]
    SETGLOBAL = 7, -- Gbl[Kst(Bx)] := R(A)
    SETUPVAL = 8,  -- UpValue[B] := R(A)
    SETTABLE = 9,  -- R(A)[RK(B)] := RK(C)
    NEWTABLE = 10, -- R(A) := {} (size = B,C)
    SELF = 11,     -- R(A+1) := R(B); R(A) := R(B)[RK(C)]
    ADD = 12,      -- R(A) := RK(B) + RK(C)
    SUB = 13,      -- R(A) := RK(B) - RK(C)
    MUL = 14,      -- R(A) := RK(B) * RK(C)
    DIV = 15,      -- R(A) := RK(B) / RK(C)
    MOD = 16,      -- R(A) := RK(B) % RK(C)
    POW = 17,      -- R(A) := RK(B) ^ RK(C)
    UNM = 18,      -- R(A) := -R(B)
    NOT = 19,      -- R(A) := not R(B)
    LEN = 20,      -- R(A) := length of R(B)
    CONCAT = 21,   -- R(A) := R(B).. ... ..R(C)
    JMP = 22,      -- pc+=sBx
    EQ = 23,       -- if ((RK(B) == RK(C)) ~= A) then pc++
    LT = 24,       -- if ((RK(B) <  RK(C)) ~= A) then pc++
    LE = 25,       -- if ((RK(B) <= RK(C)) ~= A) then pc++
    TEST = 26,     -- if not (R(A) <=> C) then pc++
    TESTSET = 27,  -- if (R(B) <=> C) then R(A) := R(B) else pc++
    CALL = 28,     -- R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    TAILCALL = 29, -- return R(A)(R(A+1), ... ,R(A+B-1))
    RETURN = 30,   -- return R(A), ... ,R(A+B-2)
    FORLOOP = 31,  -- R(A)+=R(A+2); if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
    FORPREP = 32,  -- R(A)-=R(A+2); pc+=sBx
    TFORLOOP = 33, -- R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2)); if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
    SETLIST = 34,  -- R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
    CLOSE = 35,    -- close all variables in the stack up to (>=) R(A)
    CLOSURE = 36,  -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
    VARARG = 37    -- R(A), R(A+1), ..., R(A+B-1) = vararg
}

CodeGen.Opcodes = Opcodes

function CodeGen.new()
    local codegen = {
        instructions = {},
        constants = {},
        registers = {},
        next_register = 0,
        constant_map = {},
        jump_patches = {}
    }
    setmetatable(codegen, {__index = CodeGen})
    return codegen
end

function CodeGen:allocate_register()
    local reg = self.next_register
    self.next_register = self.next_register + 1
    return reg
end

function CodeGen:add_constant(value)
    local key = tostring(value) .. "_" .. type(value)
    if self.constant_map[key] then
        return self.constant_map[key]
    end
    
    local index = #self.constants
    table.insert(self.constants, value)
    self.constant_map[key] = index
    return index
end

function CodeGen:emit_instruction(opcode, a, b, c)
    a = a or 0
    b = b or 0
    c = c or 0
    
    local instruction = {
        opcode = opcode,
        a = a,
        b = b,
        c = c,
        line = 1 -- TODO: Add line number tracking
    }
    
    table.insert(self.instructions, instruction)
    return #self.instructions - 1
end

function CodeGen:patch_jump(instruction_index, target)
    if instruction_index and self.instructions[instruction_index + 1] then
        local offset = target - instruction_index - 1
        self.instructions[instruction_index + 1].b = offset
    end
end

function CodeGen:generate(ast)
    self:generate_node(ast)
    return self:create_bytecode()
end

function CodeGen:generate_node(node)
    if not node then return nil end
    
    local node_type = node.type
    
    if node_type == "Program" then
        return self:generate_program(node)
    elseif node_type == "FunctionDeclaration" then
        return self:generate_function_declaration(node)
    elseif node_type == "VariableDeclaration" then
        return self:generate_variable_declaration(node)
    elseif node_type == "Assignment" then
        return self:generate_assignment(node)
    elseif node_type == "IfStatement" then
        return self:generate_if_statement(node)
    elseif node_type == "WhileStatement" then
        return self:generate_while_statement(node)
    elseif node_type == "ForStatement" then
        return self:generate_for_statement(node)
    elseif node_type == "ReturnStatement" then
        return self:generate_return_statement(node)
    elseif node_type == "ExpressionStatement" then
        return self:generate_node(node.expression)
    elseif node_type == "BinaryExpression" then
        return self:generate_binary_expression(node)
    elseif node_type == "UnaryExpression" then
        return self:generate_unary_expression(node)
    elseif node_type == "Literal" then
        return self:generate_literal(node)
    elseif node_type == "Identifier" then
        return self:generate_identifier(node)
    elseif node_type == "FunctionCall" then
        return self:generate_function_call(node)
    elseif node_type == "TableLiteral" then
        return self:generate_table_literal(node)
    else
        error("Unknown node type: " .. tostring(node_type))
    end
end

function CodeGen:generate_program(node)
    for _, stmt in ipairs(node.body) do
        self:generate_node(stmt)
    end
end

function CodeGen:generate_function_declaration(node)
    -- For simplicity, we'll treat function declarations as global assignments
    local func_reg = self:allocate_register()
    
    -- Create a closure (simplified)
    self:emit_instruction(Opcodes.CLOSURE, func_reg, 0, 0)
    
    -- Set global
    local name_const = self:add_constant(node.name)
    self:emit_instruction(Opcodes.SETGLOBAL, func_reg, name_const, 0)
    
    return func_reg
end

function CodeGen:generate_variable_declaration(node)
    local reg = self:allocate_register()
    self.registers[node.name] = reg
    
    if node.init then
        local init_reg = self:generate_node(node.init)
        if init_reg ~= reg then
            self:emit_instruction(Opcodes.MOVE, reg, init_reg, 0)
        end
    else
        self:emit_instruction(Opcodes.LOADNIL, reg, 0, 0)
    end
    
    return reg
end

function CodeGen:generate_assignment(node)
    local value_reg = self:generate_node(node.right)
    
    if node.left.type == "Identifier" then
        local target_reg = self.registers[node.left.name]
        if target_reg then
            if value_reg ~= target_reg then
                self:emit_instruction(Opcodes.MOVE, target_reg, value_reg, 0)
            end
        else
            -- Global assignment
            local name_const = self:add_constant(node.left.name)
            self:emit_instruction(Opcodes.SETGLOBAL, value_reg, name_const, 0)
        end
    end
    
    return value_reg
end

function CodeGen:generate_if_statement(node)
    local condition_reg = self:generate_node(node.condition)
    
    -- Test condition and jump if false
    self:emit_instruction(Opcodes.TEST, condition_reg, 0, 0)
    local jump_to_else = self:emit_instruction(Opcodes.JMP, 0, 0, 0)
    
    -- Generate consequent
    for _, stmt in ipairs(node.consequent) do
        self:generate_node(stmt)
    end
    
    local jump_to_end = nil
    if node.alternate then
        jump_to_end = self:emit_instruction(Opcodes.JMP, 0, 0, 0)
    end
    
    -- Patch jump to else
    self:patch_jump(jump_to_else, #self.instructions)
    
    -- Generate alternate
    if node.alternate then
        for _, stmt in ipairs(node.alternate) do
            self:generate_node(stmt)
        end
        
        -- Patch jump to end
        self:patch_jump(jump_to_end, #self.instructions)
    end
end

function CodeGen:generate_while_statement(node)
    local loop_start = #self.instructions
    
    local condition_reg = self:generate_node(node.condition)
    
    -- Test condition and jump if false
    self:emit_instruction(Opcodes.TEST, condition_reg, 0, 0)
    local jump_to_end = self:emit_instruction(Opcodes.JMP, 0, 0, 0)
    
    -- Generate body
    for _, stmt in ipairs(node.body) do
        self:generate_node(stmt)
    end
    
    -- Jump back to condition
    local offset = loop_start - #self.instructions - 1
    self:emit_instruction(Opcodes.JMP, 0, offset, 0)
    
    -- Patch jump to end
    self:patch_jump(jump_to_end, #self.instructions)
end

function CodeGen:generate_binary_expression(node)
    local left_reg = self:generate_node(node.left)
    local right_reg = self:generate_node(node.right)
    local result_reg = self:allocate_register()
    
    local op = node.operator
    
    if op == "+" then
        self:emit_instruction(Opcodes.ADD, result_reg, left_reg, right_reg)
    elseif op == "-" then
        self:emit_instruction(Opcodes.SUB, result_reg, left_reg, right_reg)
    elseif op == "*" then
        self:emit_instruction(Opcodes.MUL, result_reg, left_reg, right_reg)
    elseif op == "/" then
        self:emit_instruction(Opcodes.DIV, result_reg, left_reg, right_reg)
    elseif op == "%" then
        self:emit_instruction(Opcodes.MOD, result_reg, left_reg, right_reg)
    elseif op == "^" then
        self:emit_instruction(Opcodes.POW, result_reg, left_reg, right_reg)
    elseif op == ".." then
        self:emit_instruction(Opcodes.CONCAT, result_reg, left_reg, right_reg)
    elseif op == "==" then
        self:emit_instruction(Opcodes.EQ, 1, left_reg, right_reg)
        self:emit_instruction(Opcodes.JMP, 0, 1, 0)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 0, 1)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 1, 0)
    elseif op == "~=" then
        self:emit_instruction(Opcodes.EQ, 0, left_reg, right_reg)
        self:emit_instruction(Opcodes.JMP, 0, 1, 0)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 0, 1)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 1, 0)
    elseif op == "<" then
        self:emit_instruction(Opcodes.LT, 1, left_reg, right_reg)
        self:emit_instruction(Opcodes.JMP, 0, 1, 0)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 0, 1)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 1, 0)
    elseif op == ">" then
        self:emit_instruction(Opcodes.LT, 1, right_reg, left_reg)
        self:emit_instruction(Opcodes.JMP, 0, 1, 0)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 0, 1)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 1, 0)
    elseif op == "<=" then
        self:emit_instruction(Opcodes.LE, 1, left_reg, right_reg)
        self:emit_instruction(Opcodes.JMP, 0, 1, 0)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 0, 1)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 1, 0)
    elseif op == ">=" then
        self:emit_instruction(Opcodes.LE, 1, right_reg, left_reg)
        self:emit_instruction(Opcodes.JMP, 0, 1, 0)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 0, 1)
        self:emit_instruction(Opcodes.LOADBOOL, result_reg, 1, 0)
    elseif op == "and" then
        -- Short-circuit evaluation for 'and'
        self:emit_instruction(Opcodes.TESTSET, result_reg, left_reg, 0)
        local jump_to_right = self:emit_instruction(Opcodes.JMP, 0, 0, 0)
        self:emit_instruction(Opcodes.MOVE, result_reg, right_reg, 0)
        self:patch_jump(jump_to_right, #self.instructions)
    elseif op == "or" then
        -- Short-circuit evaluation for 'or'
        self:emit_instruction(Opcodes.TESTSET, result_reg, left_reg, 1)
        local jump_to_right = self:emit_instruction(Opcodes.JMP, 0, 0, 0)
        self:emit_instruction(Opcodes.MOVE, result_reg, right_reg, 0)
        self:patch_jump(jump_to_right, #self.instructions)
    else
        error("Unknown binary operator: " .. op)
    end
    
    return result_reg
end

function CodeGen:generate_unary_expression(node)
    local operand_reg = self:generate_node(node.operand)
    local result_reg = self:allocate_register()
    
    if node.operator == "-" then
        self:emit_instruction(Opcodes.UNM, result_reg, operand_reg, 0)
    elseif node.operator == "not" then
        self:emit_instruction(Opcodes.NOT, result_reg, operand_reg, 0)
    else
        error("Unknown unary operator: " .. node.operator)
    end
    
    return result_reg
end

function CodeGen:generate_literal(node)
    local reg = self:allocate_register()
    
    if type(node.value) == "number" then
        local const_index = self:add_constant(node.value)
        self:emit_instruction(Opcodes.LOADK, reg, const_index, 0)
    elseif type(node.value) == "string" then
        local const_index = self:add_constant(node.value)
        self:emit_instruction(Opcodes.LOADK, reg, const_index, 0)
    elseif type(node.value) == "boolean" then
        self:emit_instruction(Opcodes.LOADBOOL, reg, node.value and 1 or 0, 0)
    elseif node.value == nil then
        self:emit_instruction(Opcodes.LOADNIL, reg, 0, 0)
    else
        error("Unknown literal type: " .. type(node.value))
    end
    
    return reg
end

function CodeGen:generate_identifier(node)
    local reg = self.registers[node.name]
    if reg then
        return reg
    else
        -- Global variable
        local result_reg = self:allocate_register()
        local name_const = self:add_constant(node.name)
        self:emit_instruction(Opcodes.GETGLOBAL, result_reg, name_const, 0)
        return result_reg
    end
end

function CodeGen:generate_function_call(node)
    local func_reg = self:generate_node(node.callee)
    local result_reg = self:allocate_register()
    
    -- Generate arguments
    local arg_regs = {}
    for _, arg in ipairs(node.arguments) do
        local arg_reg = self:generate_node(arg)
        table.insert(arg_regs, arg_reg)
    end
    
    -- Move function to result register
    if func_reg ~= result_reg then
        self:emit_instruction(Opcodes.MOVE, result_reg, func_reg, 0)
    end
    
    -- Move arguments to consecutive registers after function
    for i, arg_reg in ipairs(arg_regs) do
        if arg_reg ~= result_reg + i then
            self:emit_instruction(Opcodes.MOVE, result_reg + i, arg_reg, 0)
        end
    end
    
    -- Call function
    self:emit_instruction(Opcodes.CALL, result_reg, #arg_regs + 1, 2)
    
    return result_reg
end

function CodeGen:generate_table_literal(node)
    local reg = self:allocate_register()
    
    -- Create new table
    self:emit_instruction(Opcodes.NEWTABLE, reg, #node.elements, 0)
    
    -- Set elements
    for i, element in ipairs(node.elements) do
        local value_reg = self:generate_node(element)
        local index_const = self:add_constant(i)
        self:emit_instruction(Opcodes.SETTABLE, reg, index_const, value_reg)
    end
    
    return reg
end

function CodeGen:generate_for_statement(node)
    -- Allocate registers for loop variables
    local var_reg = self:allocate_register()
    local limit_reg = self:allocate_register()
    local step_reg = self:allocate_register()
    local loop_var_reg = self:allocate_register()
    
    -- Store loop variable name
    self.registers[node.variable] = loop_var_reg
    
    -- Generate initial values
    local start_reg = self:generate_node(node.start)
    local stop_reg = self:generate_node(node.stop)
    local step_val_reg = node.step and self:generate_node(node.step) or nil
    
    -- Move values to loop registers
    self:emit_instruction(Opcodes.MOVE, var_reg, start_reg, 0)
    self:emit_instruction(Opcodes.MOVE, limit_reg, stop_reg, 0)
    
    if step_val_reg then
        self:emit_instruction(Opcodes.MOVE, step_reg, step_val_reg, 0)
    else
        -- Default step is 1
        local one_const = self:add_constant(1)
        self:emit_instruction(Opcodes.LOADK, step_reg, one_const, 0)
    end
    
    -- FORPREP
    local forprep_jump = self:emit_instruction(Opcodes.FORPREP, var_reg, 0, 0)
    local loop_start = #self.instructions
    
    -- Copy loop variable
    self:emit_instruction(Opcodes.MOVE, loop_var_reg, var_reg, 0)
    
    -- Generate body
    for _, stmt in ipairs(node.body) do
        self:generate_node(stmt)
    end
    
    -- FORLOOP
    local forloop_offset = loop_start - #self.instructions - 1
    self:emit_instruction(Opcodes.FORLOOP, var_reg, forloop_offset, 0)
    
    -- Patch FORPREP jump
    self:patch_jump(forprep_jump, #self.instructions)
end

function CodeGen:generate_return_statement(node)
    if node.value then
        local value_reg = self:generate_node(node.value)
        self:emit_instruction(Opcodes.RETURN, value_reg, 2, 0)
    else
        self:emit_instruction(Opcodes.RETURN, 0, 1, 0)
    end
end

-- Utility functions
function CodeGen:pack_instruction(opcode, a, b, c)
    -- Pack instruction into 32-bit integer (simplified)
    return opcode | (a << 6) | (b << 14) | (c << 23)
end

function CodeGen:pack_double(value)
    -- Simple double packing (not IEEE 754 compliant)
    return string.format("%.17g", value)
end

function CodeGen:create_bytecode()
    local output = {}
    
    -- Header
    table.insert(output, "-- LuaForge Bytecode")
    table.insert(output, "-- Generated by LuaForge Compiler")
    table.insert(output, "")
    
    -- Constants section
    table.insert(output, "-- Constants:")
    for i, const in ipairs(self.constants) do
        if type(const) == "string" then
            table.insert(output, string.format("-- [%d] = %q", i, const))
        else
            table.insert(output, string.format("-- [%d] = %s", i, tostring(const)))
        end
    end
    table.insert(output, "")
    
    -- Instructions section
    table.insert(output, "-- Instructions:")
    for i, instr in ipairs(self.instructions) do
        local opname = ""
        for name, code in pairs(Opcodes) do
            if code == instr.opcode then
                opname = name
                break
            end
        end
        
        table.insert(output, string.format("-- [%d] %s %d %d %d", 
            i - 1, opname, instr.a, instr.b, instr.c))
    end
    
    return table.concat(output, "\n")
end

return CodeGen