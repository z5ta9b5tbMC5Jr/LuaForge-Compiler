# LuaForge - Advanced Lua Subset Compiler

Um compilador avançado que transforma código Lua em bytecode com otimizações personalizadas.

## Características

### Funcionalidades Implementadas
- ✅ **Análise Léxica**: Tokenização completa do código Lua
- ✅ **Análise Sintática**: Construção de AST (Abstract Syntax Tree)
- ✅ **Otimizações**: Constant folding, dead code elimination, peephole optimization
- ✅ **Geração de Bytecode**: Conversão para bytecode compatível com Lua
- ✅ **Interface de Linha de Comando**: Compilação com diferentes níveis de otimização

### Estrutura do Projeto
```
LuaForge/
├── luaforge.lua          # Ponto de entrada principal
├── src/
│   ├── lexer/
│   │   └── lexer.lua     # Análise léxica
│   ├── parser/
│   │   └── parser.lua    # Análise sintática
│   ├── optimizer/
│   │   └── optimizer.lua # Otimizações
│   └── codegen/
│       └── codegen.lua   # Geração de bytecode
├── examples/
│   ├── simple.lua        # Exemplo básico
│   └── optimization_test.lua # Teste de otimizações
└── README.md
```

### Subconjunto Lua Suportado
- Declarações de variáveis locais
- Declarações de funções
- Estruturas de controle (if/then/else, while, for)
- Expressões aritméticas e lógicas
- Operadores de comparação
- Literais (números, strings, booleanos, nil)
- Chamadas de função
- Tabelas básicas
- Comandos return

## Uso

### Compilação Básica
```bash
lua luaforge.lua compile input.lua
```

### Compilação com Otimizações
```bash
lua luaforge.lua compile input.lua -O 2
```

### Especificar Arquivo de Saída
```bash
lua luaforge.lua compile input.lua -o output.luac
```

### Opções Disponíveis
- `-o <arquivo>`: Especifica o arquivo de saída
- `-O <nível>`: Define o nível de otimização (0-2)
- `-g`: Inclui informações de debug

## Desenvolvimento

### Fases de Compilação
1. **Análise Léxica**: Converte código fonte em tokens
2. **Análise Sintática**: Constrói AST a partir dos tokens
3. **Otimização**: Aplica transformações para melhorar o código
4. **Geração de Bytecode**: Produz bytecode final

### Otimizações Implementadas
- **Constant Folding**: Avalia expressões constantes em tempo de compilação
- **Dead Code Elimination**: Remove código inalcançável
- **Peephole Optimization**: Otimizações locais no bytecode

## Exemplos

### Código de Entrada
```lua
local x = 5 + 3
local y = x * 2
if y > 10 then
    print("Grande")
else
    print("Pequeno")
end
```

### Compilação
```bash
lua luaforge.lua compile exemplo.lua -O 2
```

## Créditos

**Desenvolvido por: Bypass-dev**

Este compilador foi desenvolvido como um projeto educacional para demonstrar os conceitos fundamentais de construção de compiladores, incluindo análise léxica, sintática, otimização e geração de código.