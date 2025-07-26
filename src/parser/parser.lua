-- Parser module for LuaForge
-- Converts tokens into an Abstract Syntax Tree (AST)

local Parser = {}

-- AST Node Types
local ASTNode = {
    -- Statements
    PROGRAM = "Program",
    FUNCTION_DECLARATION = "FunctionDeclaration",
    VARIABLE_DECLARATION = "VariableDeclaration",
    ASSIGNMENT = "Assignment",
    IF_STATEMENT = "IfStatement",
    WHILE_STATEMENT = "WhileStatement",
    FOR_STATEMENT = "ForStatement",
    RETURN_STATEMENT = "ReturnStatement",
    EXPRESSION_STATEMENT = "ExpressionStatement",
    
    -- Expressions
    BINARY_EXPRESSION = "BinaryExpression",
    UNARY_EXPRESSION = "UnaryExpression",
    LITERAL = "Literal",
    IDENTIFIER = "Identifier",
    FUNCTION_CALL = "FunctionCall",
    TABLE_LITERAL = "TableLiteral",
    MEMBER_EXPRESSION = "MemberExpression"
}

Parser.ASTNode = ASTNode

function Parser.new(tokens)
    local parser = {
        tokens = tokens,
        current = 1
    }
    setmetatable(parser, {__index = Parser})
    return parser
end

function Parser:peek(offset)
    offset = offset or 0
    local index = self.current + offset
    if index <= #self.tokens then
        return self.tokens[index]
    end
    return nil
end

function Parser:advance()
    if self.current <= #self.tokens then
        self.current = self.current + 1
    end
end

function Parser:match(...)
    local token = self:peek()
    if not token then return false end
    
    for _, tokenType in ipairs({...}) do
        if token.type == tokenType then
            return true
        end
    end
    return false
end

function Parser:consume(tokenType, message)
    local token = self:peek()
    if not token or token.type ~= tokenType then
        error(message or ("Expected " .. tokenType .. ", got " .. (token and token.type or "EOF")))
    end
    self:advance()
    return token
end

function Parser:parse()
    local statements = {}
    
    while self:peek() do
        local stmt = self:parseStatement()
        if stmt then
            table.insert(statements, stmt)
        end
    end
    
    return {
        type = ASTNode.PROGRAM,
        body = statements
    }
end

function Parser:parseStatement()
    local token = self:peek()
    if not token then return nil end
    
    if token.type == "KEYWORD" then
        if token.value == "function" then
            return self:parseFunctionDeclaration()
        elseif token.value == "local" then
            return self:parseVariableDeclaration()
        elseif token.value == "if" then
            return self:parseIfStatement()
        elseif token.value == "while" then
            return self:parseWhileStatement()
        elseif token.value == "for" then
            return self:parseForStatement()
        elseif token.value == "return" then
            return self:parseReturnStatement()
        end
    end
    
    -- Try assignment or expression statement
    local expr = self:parseExpression()
    
    -- Check if it's an assignment
    if self:match("OPERATOR") and self:peek().value == "=" then
        self:advance() -- consume '='
        local value = self:parseExpression()
        return {
            type = ASTNode.ASSIGNMENT,
            left = expr,
            right = value
        }
    end
    
    return {
        type = ASTNode.EXPRESSION_STATEMENT,
        expression = expr
    }
end

function Parser:parseFunctionDeclaration()
    self:consume("KEYWORD") -- consume 'function'
    local name = self:consume("IDENTIFIER").value
    
    self:consume("DELIMITER") -- consume '('
    
    local params = {}
    while not self:match("DELIMITER") or self:peek().value ~= ")" do
        local param = self:consume("IDENTIFIER").value
        table.insert(params, param)
        
        if self:match("DELIMITER") and self:peek().value == "," then
            self:advance()
        end
    end
    
    self:consume("DELIMITER") -- consume ')'
    
    local body = {}
    while not (self:match("KEYWORD") and self:peek().value == "end") do
        local stmt = self:parseStatement()
        if stmt then
            table.insert(body, stmt)
        end
    end
    
    self:consume("KEYWORD") -- consume 'end'
    
    return {
        type = ASTNode.FUNCTION_DECLARATION,
        name = name,
        params = params,
        body = body
    }
end

function Parser:parseVariableDeclaration()
    self:consume("KEYWORD") -- consume 'local'
    local name = self:consume("IDENTIFIER").value
    
    local init = nil
    if self:match("OPERATOR") and self:peek().value == "=" then
        self:advance() -- consume '='
        init = self:parseExpression()
    end
    
    return {
        type = ASTNode.VARIABLE_DECLARATION,
        name = name,
        init = init
    }
end

function Parser:parseIfStatement()
    self:consume("KEYWORD") -- consume 'if'
    local condition = self:parseExpression()
    self:consume("KEYWORD") -- consume 'then'
    
    local consequent = {}
    while not (self:match("KEYWORD") and (self:peek().value == "else" or self:peek().value == "elseif" or self:peek().value == "end")) do
        local stmt = self:parseStatement()
        if stmt then
            table.insert(consequent, stmt)
        end
    end
    
    local alternate = nil
    if self:match("KEYWORD") and self:peek().value == "else" then
        self:advance() -- consume 'else'
        alternate = {}
        while not (self:match("KEYWORD") and self:peek().value == "end") do
            local stmt = self:parseStatement()
            if stmt then
                table.insert(alternate, stmt)
            end
        end
    end
    
    self:consume("KEYWORD") -- consume 'end'
    
    return {
        type = ASTNode.IF_STATEMENT,
        condition = condition,
        consequent = consequent,
        alternate = alternate
    }
end

function Parser:parseWhileStatement()
    self:consume("KEYWORD") -- consume 'while'
    local condition = self:parseExpression()
    self:consume("KEYWORD") -- consume 'do'
    
    local body = {}
    while not (self:match("KEYWORD") and self:peek().value == "end") do
        local stmt = self:parseStatement()
        if stmt then
            table.insert(body, stmt)
        end
    end
    
    self:consume("KEYWORD") -- consume 'end'
    
    return {
        type = ASTNode.WHILE_STATEMENT,
        condition = condition,
        body = body
    }
end

function Parser:parseForStatement()
    self:consume("KEYWORD") -- consume 'for'
    local variable = self:consume("IDENTIFIER").value
    self:consume("OPERATOR") -- consume '='
    local start = self:parseExpression()
    self:consume("DELIMITER") -- consume ','
    local stop = self:parseExpression()
    
    local step = nil
    if self:match("DELIMITER") and self:peek().value == "," then
        self:advance()
        step = self:parseExpression()
    end
    
    self:consume("KEYWORD") -- consume 'do'
    
    local body = {}
    while not (self:match("KEYWORD") and self:peek().value == "end") do
        local stmt = self:parseStatement()
        if stmt then
            table.insert(body, stmt)
        end
    end
    
    self:consume("KEYWORD") -- consume 'end'
    
    return {
        type = ASTNode.FOR_STATEMENT,
        variable = variable,
        start = start,
        stop = stop,
        step = step,
        body = body
    }
end

function Parser:parseReturnStatement()
    self:consume("KEYWORD") -- consume 'return'
    
    local value = nil
    if not (self:match("KEYWORD") and self:peek().value == "end") and self:peek() then
        value = self:parseExpression()
    end
    
    return {
        type = ASTNode.RETURN_STATEMENT,
        value = value
    }
end

-- Expression parsing with operator precedence
local precedence = {
    ["or"] = 1,
    ["and"] = 2,
    ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["~="] = 3, ["=="] = 3,
    [".."] = 4,
    ["+"] = 5, ["-"] = 5,
    ["*"] = 6, ["/"] = 6, ["%"] = 6,
    ["^"] = 7
}

function Parser:parseExpression(minPrec)
    minPrec = minPrec or 0
    local left = self:parsePrimary()
    
    while true do
        local token = self:peek()
        if not token or token.type ~= "OPERATOR" then break end
        
        local prec = precedence[token.value]
        if not prec or prec < minPrec then break end
        
        local op = token.value
        self:advance()
        
        local right = self:parseExpression(prec + 1)
        
        left = {
            type = ASTNode.BINARY_EXPRESSION,
            operator = op,
            left = left,
            right = right
        }
    end
    
    return left
end

function Parser:parsePrimary()
    local token = self:peek()
    if not token then
        error("Unexpected end of input")
    end
    
    if token.type == "NUMBER" then
        self:advance()
        return {
            type = ASTNode.LITERAL,
            value = tonumber(token.value),
            raw = token.value
        }
    elseif token.type == "STRING" then
        self:advance()
        return {
            type = ASTNode.LITERAL,
            value = token.value,
            raw = token.value
        }
    elseif token.type == "KEYWORD" and (token.value == "true" or token.value == "false" or token.value == "nil") then
        self:advance()
        local value = token.value
        if value == "true" then value = true
        elseif value == "false" then value = false
        else value = nil end
        
        return {
            type = ASTNode.LITERAL,
            value = value,
            raw = token.value
        }
    elseif token.type == "IDENTIFIER" then
        local name = token.value
        self:advance()
        
        -- Check for function call
        if self:match("DELIMITER") and self:peek().value == "(" then
            self:advance() -- consume '('
            
            local args = {}
            while not (self:match("DELIMITER") and self:peek().value == ")") do
                local arg = self:parseExpression()
                table.insert(args, arg)
                
                if self:match("DELIMITER") and self:peek().value == "," then
                    self:advance()
                end
            end
            
            self:consume("DELIMITER") -- consume ')'
            
            return {
                type = ASTNode.FUNCTION_CALL,
                callee = {
                    type = ASTNode.IDENTIFIER,
                    name = name
                },
                arguments = args
            }
        end
        
        return {
            type = ASTNode.IDENTIFIER,
            name = name
        }
    elseif token.type == "DELIMITER" and token.value == "(" then
        self:advance() -- consume '('
        local expr = self:parseExpression()
        self:consume("DELIMITER") -- consume ')'
        return expr
    elseif token.type == "DELIMITER" and token.value == "{" then
        return self:parseTableLiteral()
    elseif token.type == "OPERATOR" and (token.value == "-" or token.value == "not") then
        local op = token.value
        self:advance()
        local operand = self:parsePrimary()
        return {
            type = ASTNode.UNARY_EXPRESSION,
            operator = op,
            operand = operand
        }
    end
    
    error("Unexpected token: " .. token.type .. " (" .. tostring(token.value) .. ")")
end

function Parser:parseTableLiteral()
    self:consume("DELIMITER") -- consume '{'
    
    local elements = {}
    
    while not (self:match("DELIMITER") and self:peek().value == "}") do
        local element = self:parseExpression()
        table.insert(elements, element)
        
        if self:match("DELIMITER") and self:peek().value == "," then
            self:advance()
        end
    end
    
    self:consume("DELIMITER") -- consume '}'
    
    return {
        type = ASTNode.TABLE_LITERAL,
        elements = elements
    }
end

return Parser