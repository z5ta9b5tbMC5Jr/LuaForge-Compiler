-- LuaForge - Advanced Lua Subset Compiler
-- Main entry point for the compiler

-- Load modules
local Lexer = require("src.lexer.lexer")
local Parser = require("src.parser.parser")
local Optimizer = require("src.optimizer.optimizer")
local CodeGen = require("src.codegen.codegen")

-- Compiler version
local VERSION = "1.0.0"

-- Compilation phases
local function compile_file(input_file, output_file, options)
    options = options or {}
    local optimization_level = options.optimization_level or 0
    local debug_info = options.debug_info or false
    
    print("LuaForge Compiler v" .. VERSION)
    print("Compiling: " .. input_file)
    
    -- Read source file
    local file = io.open(input_file, "r")
    if not file then
        error("Could not open file: " .. input_file)
    end
    
    local source = file:read("*all")
    file:close()
    
    -- Phase 1: Lexical Analysis
    print("Phase 1: Lexical Analysis...")
    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    
    -- Phase 2: Syntactic Analysis
    print("Phase 2: Syntactic Analysis...")
    local parser = Parser.new(tokens)
    local ast = parser:parse()
    
    -- Phase 3: Optimization
    if optimization_level > 0 then
        print("Phase 3: Optimization (Level " .. optimization_level .. ")...")
        local optimizer = Optimizer.new()
        
        if optimization_level >= 1 then
            ast = optimizer:constant_folding(ast)
            ast = optimizer:dead_code_elimination(ast)
        end
        
        if optimization_level >= 2 then
            ast = optimizer:peephole_optimization(ast)
        end
    else
        print("Phase 3: Optimization (Skipped)...")
    end
    
    -- Phase 4: Code Generation
    print("Phase 4: Bytecode Generation...")
    local codegen = CodeGen.new()
    local bytecode = codegen:generate(ast)
    
    -- Write output file
    local out_file = io.open(output_file, "w")
    if not out_file then
        error("Could not create output file: " .. output_file)
    end
    
    out_file:write(bytecode)
    out_file:close()
    
    print("Compilation completed successfully!")
    print("Output: " .. output_file)
end

-- Command line interface
local function show_usage()
    print("LuaForge Compiler v" .. VERSION)
    print("Usage: lua luaforge.lua <command> [options]")
    print("")
    print("Commands:")
    print("  compile <input.lua>     Compile Lua file to bytecode")
    print("")
    print("Options:")
    print("  -o <output>            Specify output file")
    print("  -O <level>             Optimization level (0-2, default: 0)")
    print("  -g                     Include debug information")
    print("")
    print("Examples:")
    print("  lua luaforge.lua compile script.lua")
    print("  lua luaforge.lua compile script.lua -o script.luac")
    print("  lua luaforge.lua compile script.lua -O 2")
end

-- Parse command line arguments
local function parse_args(args)
    if #args == 0 then
        show_usage()
        return
    end
    
    local command = args[1]
    
    if command == "compile" then
        if #args < 2 then
            print("Error: No input file specified")
            show_usage()
            return
        end
        
        local input_file = args[2]
        local output_file = input_file:gsub("\.lua$", ".luac")
        local options = {
            optimization_level = 0,
            debug_info = false
        }
        
        -- Parse options
        local i = 3
        while i <= #args do
            local arg = args[i]
            
            if arg == "-o" then
                i = i + 1
                if i <= #args then
                    output_file = args[i]
                else
                    print("Error: -o requires an argument")
                    return
                end
            elseif arg == "-O" then
                i = i + 1
                if i <= #args then
                    local level = tonumber(args[i])
                    if level and level >= 0 and level <= 2 then
                        options.optimization_level = level
                    else
                        print("Error: Invalid optimization level. Use 0, 1, or 2")
                        return
                    end
                else
                    print("Error: -O requires an argument")
                    return
                end
            elseif arg == "-g" then
                options.debug_info = true
            else
                print("Error: Unknown option: " .. arg)
                show_usage()
                return
            end
            
            i = i + 1
        end
        
        -- Compile the file
        local success, err = pcall(compile_file, input_file, output_file, options)
        if not success then
            print("Compilation failed: " .. err)
            os.exit(1)
        end
    else
        print("Error: Unknown command: " .. command)
        show_usage()
        os.exit(1)
    end
end

-- Main entry point
parse_args(arg)