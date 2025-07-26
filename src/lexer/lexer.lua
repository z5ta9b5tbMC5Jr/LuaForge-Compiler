-- Lexer module for LuaForge
-- Tokenizes Lua source code

local Lexer = {}

-- Token types
local TokenType = {
    -- Literals
    NUMBER = "NUMBER",
    STRING = "STRING",
    IDENTIFIER = "IDENTIFIER",
    
    -- Keywords
    KEYWORD = "KEYWORD",
    
    -- Operators
    OPERATOR = "OPERATOR",
    
    -- Delimiters
    DELIMITER = "DELIMITER",
    
    -- Special
    EOF = "EOF",
    NEWLINE = "NEWLINE"
}

Lexer.TokenType = TokenType

-- Lua keywords
local keywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
    ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
    ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
    ["while"] = true
}

function Lexer.new(source)
    local lexer = {
        source = source,
        position = 1,
        line = 1,
        column = 1
    }
    setmetatable(lexer, {__index = Lexer})
    return lexer
end

function Lexer:current_char()
    if self.position <= #self.source then
        return self.source:sub(self.position, self.position)
    end
    return nil
end

function Lexer:peek_char(offset)
    offset = offset or 1
    local pos = self.position + offset
    if pos <= #self.source then
        return self.source:sub(pos, pos)
    end
    return nil
end

function Lexer:advance()
    if self.position <= #self.source then
        local char = self:current_char()
        self.position = self.position + 1
        
        if char == "\n" then
            self.line = self.line + 1
            self.column = 1
        else
            self.column = self.column + 1
        end
        
        return char
    end
    return nil
end

function Lexer:skip_whitespace()
    while self:current_char() and self:current_char():match("%s") and self:current_char() ~= "\n" do
        self:advance()
    end
end

function Lexer:skip_comment()
    if self:current_char() == "-" and self:peek_char() == "-" then
        -- Single line comment
        while self:current_char() and self:current_char() ~= "\n" do
            self:advance()
        end
        return true
    end
    return false
end

function Lexer:read_string(quote)
    local value = ""
    self:advance() -- skip opening quote
    
    while self:current_char() and self:current_char() ~= quote do
        local char = self:current_char()
        if char == "\\" then
            self:advance()
            local escaped = self:current_char()
            if escaped == "n" then
                value = value .. "\n"
            elseif escaped == "t" then
                value = value .. "\t"
            elseif escaped == "r" then
                value = value .. "\r"
            elseif escaped == "\\" then
                value = value .. "\\"
            elseif escaped == "\"" then
                value = value .. "\""
            elseif escaped == "'" then
                value = value .. "'"
            else
                value = value .. escaped
            end
        else
            value = value .. char
        end
        self:advance()
    end
    
    if self:current_char() == quote then
        self:advance() -- skip closing quote
    else
        error("Unterminated string at line " .. self.line)
    end
    
    return value
end

function Lexer:read_number()
    local value = ""
    local has_dot = false
    
    while self:current_char() and (self:current_char():match("%d") or (self:current_char() == "." and not has_dot)) do
        if self:current_char() == "." then
            has_dot = true
        end
        value = value .. self:current_char()
        self:advance()
    end
    
    return value
end

function Lexer:read_identifier()
    local value = ""
    
    while self:current_char() and (self:current_char():match("%w") or self:current_char() == "_") do
        value = value .. self:current_char()
        self:advance()
    end
    
    return value
end

function Lexer:create_token(type, value, line, column)
    return {
        type = type,
        value = value,
        line = line or self.line,
        column = column or self.column
    }
end

function Lexer:tokenize()
    local tokens = {}
    
    while self:current_char() do
        local char = self:current_char()
        local start_line = self.line
        local start_column = self.column
        
        -- Skip whitespace (except newlines)
        if char:match("%s") and char ~= "\n" then
            self:skip_whitespace()
        
        -- Handle newlines
        elseif char == "\n" then
            table.insert(tokens, self:create_token(TokenType.NEWLINE, "\n", start_line, start_column))
            self:advance()
        
        -- Skip comments
        elseif self:skip_comment() then
            -- Comment was skipped
        
        -- String literals
        elseif char == '"' or char == "'" then
            local value = self:read_string(char)
            table.insert(tokens, self:create_token(TokenType.STRING, value, start_line, start_column))
        
        -- Number literals
        elseif char:match("%d") then
            local value = self:read_number()
            table.insert(tokens, self:create_token(TokenType.NUMBER, value, start_line, start_column))
        
        -- Identifiers and keywords
        elseif char:match("%a") or char == "_" then
            local value = self:read_identifier()
            local token_type = keywords[value] and TokenType.KEYWORD or TokenType.IDENTIFIER
            table.insert(tokens, self:create_token(token_type, value, start_line, start_column))
        
        -- Two-character operators
        elseif char == "=" and self:peek_char() == "=" then
            table.insert(tokens, self:create_token(TokenType.OPERATOR, "==", start_line, start_column))
            self:advance()
            self:advance()
        elseif char == "~" and self:peek_char() == "=" then
            table.insert(tokens, self:create_token(TokenType.OPERATOR, "~=", start_line, start_column))
            self:advance()
            self:advance()
        elseif char == "<" and self:peek_char() == "=" then
            table.insert(tokens, self:create_token(TokenType.OPERATOR, "<=", start_line, start_column))
            self:advance()
            self:advance()
        elseif char == ">" and self:peek_char() == "=" then
            table.insert(tokens, self:create_token(TokenType.OPERATOR, ">=", start_line, start_column))
            self:advance()
            self:advance()
        elseif char == "." and self:peek_char() == "." then
            table.insert(tokens, self:create_token(TokenType.OPERATOR, "..", start_line, start_column))
            self:advance()
            self:advance()
        
        -- Single-character operators
        elseif char:match("[+%-*/%^<>=]") then
            table.insert(tokens, self:create_token(TokenType.OPERATOR, char, start_line, start_column))
            self:advance()
        
        -- Delimiters
        elseif char:match("[(){}%[%],;.]") then
            table.insert(tokens, self:create_token(TokenType.DELIMITER, char, start_line, start_column))
            self:advance()
        
        else
            error("Unexpected character '" .. char .. "' at line " .. self.line .. ", column " .. self.column)
        end
    end
    
    table.insert(tokens, self:create_token(TokenType.EOF, nil, self.line, self.column))
    return tokens
end

return Lexer