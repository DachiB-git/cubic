TERMINAL = 0
NONTERMINAL = 1

lines = []

pairs = []

key_to_num = {
    "EPSILON": -1,
    "EOF": 0,
    "NAME": 256,
    "NUM": 257,
    "TYPEDEF": 258,
    "LT": 259,
    "LE": 260,
    "GT": 261,
    "GE": 262,
    "EQ": 263,
    "NE": 264,
    "AND_OP": 265,
    "OR_OP": 266,
    "IF": 267,
    "ELSE": 268,
    "WHILE": 269,
    "DO": 270,
    "STRUCT": 271,
    "RETURN": 272,
    "FUNC": 273,
    "TYNAME": 274,
    "FUNCNAME": 275,
    "TRUE": 276,
    "FALSE": 277,
    "STRLIT": 278,
    "UNTERMINATEDLIT": 279,
    "CHAR": 280,
    "SHORT": 281,
    "INT": 282,
    "UCHAR": 283,
    "USHORT": 284,
    "UINT": 285,
    "BOOL": 286,
    "ASM": 287,
    "prog": 300, 
    "TyDS": 301,
    "VaDS": 302,
    "FuDS": 303,
    "TyD": 304, 
    "TE": 305,
    "Ty": 306,
    "TyDeco": 307,
    "VaD": 308,
    "FuD": 310,
    "RFuDS": 311,
    "PaDS": 312,
    "PaD": 313,
    "RPaDS": 314,
    "body": 315,
    "StS": 316, 
    "rSt": 317,
    "St": 318,
    "GenE": 319,
    "ArgS": 320, 
    "MatchedElse": 321,
    "id": 322,
    "Rid": 323,
    "idSel": 324,
    "E": 325,
    "T": 326,
    "RE": 327,
    "F": 328, 
    "RT": 329,
    "JointE": 330,
    "RRelE": 331,
    "RelOp": 332,
    "Union": 333,
    "UnionT": 334,
    "Intersect": 335,
    "RelE": 336,
    "Arg": 337,
    "RArgS": 338,
    "PaDTyDeco": 339,
    "PDeco": 340,
    "ArrDeco": 341,
    "PaDArrDeco": 342,
    "TCPDeco": 343
}

REL_OPS = {
    "<": "LT",
    "<=": "LE",
    ">": "GT",
    ">=": "GE",
    "==": "EQ",
    "!=": "NE",
}

symbols = {}

def get_first(symbol_key):
    if symbols[symbol_key]["type"] == TERMINAL:
        return symbols[symbol_key]["first"]
    new_first = set()
    productions = symbols[symbol_key]["productions"]
    for production in productions:
        for symbol in production:
            new_first.update(get_first(symbol))
            if symbols[symbol]["type"] == NONTERMINAL and symbols[symbol]["has_epsilon_production"] == True:
                continue
            break
    return new_first

def get_follow(symbol):
    if symbols[symbol]["type"] == TERMINAL:
        return symbols[symbol]["first"]
    new_follow = symbols[symbol]["follow"]
    index = -1
    for nonterminal in sorted_nonterminals:
        if nonterminal == symbol:
            continue
        for production in symbols[nonterminal]["productions"]:
            if symbol not in production:
                continue
            index = production.index(symbol)
            if index == len(production) - 1:
                new_follow.update(get_follow(nonterminal))
                continue
            index = index + 1
            while index < len(production):
                new_follow.update([item for item in symbols[production[index]]["first"] if item != "epsilon"])
                if symbols[production[index]]["has_epsilon_production"] == False:
                    break
                index = index + 1
            if index == len(production):
                new_follow.update(get_follow(nonterminal))
    return new_follow



nonterminals = set()
terminals = set()
sorted_nonterminals = []


# symbol = {
#     "type": TERMINAL | NONTERMINAL,
#     "has_epsilon_production": False,
#     "productions": productions,
#     "first": set(),
#     "follow": set()
# }

with open("grammar.txt", "r") as f:
    lines = f.readlines()
for line in lines:
    [nonterminal, productions] = line.rstrip("\n").split(" -> ")
    productions = [production.strip(" ").split(" ") for production in productions.split(" | ")]
    pairs.append({nonterminal : productions})
    nonterminals.add(nonterminal)
    sorted_nonterminals.append(nonterminal)
for pair in pairs:
    for key, productions in dict.items(pair):
        symbols[key] = {
            "type": NONTERMINAL,
            "has_epsilon_production": False,
            "productions": productions,
            "first": set(),
            "follow": set(),
        }
        for production in productions:
            for symbol in production:
                if symbol == "epsilon":
                    symbols[key]["has_epsilon_production"] = True
                if symbol not in nonterminals:
                    terminals.add(symbol)
                    symbols[symbol] = {
                        "type": TERMINAL,
                        "has_epsilon_production": False,
                        "productions": [],
                        "first": set([symbol]),
                        "follow": set(),
                    }

for nonterminal in nonterminals:
    symbols[nonterminal]["first"] = get_first(nonterminal)
# for nonterminal in nonterminals:
#     print(nonterminal, symbols[nonterminal])

symbols["prog"]["follow"] = set(["EOF"])

for nonterminal in sorted_nonterminals:
    symbols[nonterminal]["follow"] = get_follow(nonterminal)
    
functions = []

def emit_function_prologue(symbol):
    functions.append(f"init_{symbol}:\n")
    functions.append("push ebp\n")
    functions.append("mov ebp, esp\n")
    functions.append("sub esp, 4\n")

def emit_function_epilogue():
    functions.append("leave\n")
    functions.append("ret\n")

def emit_get_linked_list(symbol):
    functions.append("push 0\n")
    functions.append(f"push {symbol}\n")
    functions.append("call get_linked_list\n")
    functions.append("add esp, 8\n")
    functions.append("mov dword [ebp-4], eax\n")

def emit_linked_list_append(symbol):
    functions.append(f"push {symbol}\n")
    functions.append(f"push dword [ebp-4]\n")
    functions.append(f"call linked_list_append\n")
    functions.append(f"add esp, 8\n")

def emit_jump_table_init(first, nonterminal):
    functions.append(f"push dword [ebp-4]\n")
    functions.append(f"push {first}\n")
    functions.append(f"push {nonterminal}\n")
    functions.append(f"push dword [ebp+8]\n")
    functions.append(f"call jump_table_init\n")
    functions.append(f"add esp, 16\n")

def emit_jump_table_init_eps(follow, nonterminal):
    functions.append(f"push EPSILON\n")
    functions.append(f"push {follow}\n")
    functions.append(f"push {nonterminal}\n")
    functions.append(f"push dword [ebp+8]\n")
    functions.append(f"call jump_table_init\n")
    functions.append(f"add esp, 16\n")

for nonterminal in sorted_nonterminals:
    emit_function_prologue(nonterminal)
    for production in symbols[nonterminal]["productions"]:
        if "epsilon" in production:
            continue
        list_created = False
        for symbol in production:
            if symbol not in key_to_num:
                symbol = f"0x{symbol.encode('utf-8').hex()}"
            if list_created == False:
                emit_get_linked_list(symbol)
                list_created = True
                continue
            emit_linked_list_append(symbol)
        for symbol in production:
            first_without_eps = [symbol for symbol in symbols[symbol]["first"] if symbol != "epsilon"]
            for first in first_without_eps:
                if first not in key_to_num:
                    first = f"0x{first.encode('utf-8').hex()}"
                emit_jump_table_init(first, nonterminal)
            if symbols[symbol]["has_epsilon_production"] == True:
                continue
            break
    if symbols[nonterminal]["has_epsilon_production"] == True:
        for follow in symbols[nonterminal]["follow"]:
            if follow not in key_to_num:
                    follow = f"0x{follow.encode('utf-8').hex()}"
            emit_jump_table_init_eps(follow, nonterminal)


    emit_function_epilogue()

with open("parser_gen.asm", "w") as f:
    f.writelines(functions)