Na -> LeDiS
TyNa -> Na promotion
FuncNa -> Na promotion
Num -> DiS | - DiS
------------------------------------------------
prog -> TyDS VaDS FuDS                          // first(prog) = {typedef, int, uint, bool, char, TyNa, func}
                                                // follow(prog) = {$}
TyDS -> TyD TyDS | eps                          // first(TyDS) = {typedef, eps}
                                                // follow(TyDS) = {int, uint, bool, char, TyNa, func}
TyD -> typedef TE ;                             // first(TyD) = {typedef}
                                                // follow(TyD) = {typedef}
TE -> Ty TyDeco TyNa | struct TyNa { VaDS }     // first(TE) = {int, uint, bool, char, TyNa, struct}
                                                // follow(TE) = {;}
TyDeco -> PDeco ArrDeco | eps                   // first(TyDeco) = {[, *, eps}
                                                // follow(TyDeco) = {TyNa, Na}
PDeco -> * PDeco | eps                          // first(PDeco) = {*, eps}
                                                // follow(PDeco) = {[, TyNa, Na}
ArrDeco -> [Num] ArrDeco | eps                  // first(ArrDeco) = {[, eps}
                                                // follow(ArrDeco) = {TyNa, Na}
Ty -> int | uint | bool | char | TyNa           // first(Ty) = {int, uint, bool, char, TyNa}
                                                // follow(Ty) = {Na, [, *, TyNa}
VaDS -> VaD VaDS | eps                          // first(VaDS) = {int, uint, bool, char, TyNa, eps}
                                                // follow(VaDS) = { }, func, Na, if, while, do, return, FuncNa}
VaD -> Ty TyDeco Na ;                           // first(VaD) = {int, uint, bool, char, TyNa}
                                                // follow(VaD) = {int, uint, bool, char, TyNa}
FuDS -> FuD RFuDS                               // first(FuDS) = {func}
                                                // follow(FuDS) = {$}
RFuDS -> FuD RFuDS | eps                        // first(RFuDS) = {func, eps}
                                                // follow(RFuDS) = {$}
FuD -> func Ty TyDeco Na ( PaDS ) { VaDS body } // first(FuD) = {func}
                                                // follow(FuD) = {func}
PaD -> Ty PaDTyDeco Na                          // first(PaD) = {int, uint, bool, char, TyNa}
                                                // follow(PaD) = {,}
PaDTyDeco -> PDeco PaDArrDeco | eps             // first(PaDTyDeco) = {[, * , eps}
                                                // follow(PaDTyDeco) = {Na}
PaDArrDeco -> [] ArrDeco | eps                  // first(PaDArrDeco) = {[, eps}
                                                // follow(PaDArrDeco) = {Na}
PaDS -> PaD RPaDS | eps                         // first(PaDS) = {int, uint, bool, char, TyNa, eps}
                                                // follow(PaDS) = {)}
RPaDS -> , PaD RPaDS | eps                      // first(RPaDS) = {, , eps}
                                                // follow(RPaDS) = {)}
body -> StS rSt | rSt                           // first(body) = {return, Na, if, while, do, FuncNa}
                                                // follow(body) = { } } 
rSt -> return GenE ;                            // first(rSt) = {return}
                                                // follow(rSt) = { } }
StS -> St StS | eps                             // first(StS) = {Na, if, while, do, FuncNa, eps}
                                                // follow(StS) = {return, }}
St -> if ( GenE ) { StS } MatchedElse           // first(St) = {Na, if, while, do, FuncNa}
St -> while ( GenE ) { StS }                    // follow(St) = {Na, if, while, do, FuncNa}
St -> do { StS } while ( GenE ) ;
St -> id = GenE ;                              
St -> FuncNa (ArgS) ;  
MatchedElse -> else { StS } | eps               // first(MatchedElse) = {else, eps}
                                                // follow(MatchedElse) = {Na, if, while, do, FuncNa}
GenE -> FuncNa (ArgS) | JointE                  // first(GenE) = {FuncNa, Na, *, &, -, !, (, Num, true, false}
                                                // follow(GenE) = {, , ;, ), ]}
Arg -> GenE                                     // first(Arg) = {FuncNa, Na, *, &, -, !, (, Num, true, false}
                                                // follow(Arg) = {, , )}
ArgS -> Arg RArgS | eps                         // first(ArgS) = {FuncNa, Na, *, &, -, !, (, Num, true, false, eps}
                                                // follow(ArgS) = {)}
RArgS -> , Arg RArgS | eps                      // first(RArgS) = {, , eps}
                                                // follow(RArgS) = {)}
id -> Na Rid                                    // first(id) = {Na}
                                                // follow(id) = {=, *, /, +, -, ), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, ), ]}
Rid -> idSel Rid | eps                          // first(Rid) = {., [, eps}                       
                                                // follow(Rid) =  {=, *, /, +, -, ), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, ), ]}
idSel -> .Na | [GenE]                           // first(idSel) = {., [} 
                                                // follow(idSel) = {Na}
E -> T RE                                       // first(E) = {id, -, !, *, &, (, Num, true, false}
                                                // follow(E) = {), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, )}
RE -> + T RE | - T RE | eps                     // first(RE) = {+, -, eps}
                                                // follow(RE) = {), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, )}
T -> F RT                                       // first(T) = {id, -, !, *, &, (, Num, true, false}
                                                // follow(T) = {+, -, ), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, )}
RT -> * F RT | / F RT | eps                     // first(RT) = {*, /, eps}
                                                // follow(RT) = {+, -, ), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, )}
F -> id | -F | !F | *F | &F | ( E ) | Num       // first(F) = {id, -, !, *, &, (, Num, true, false}
| true | false  
                                                // follow(F) = {*, /, +, -, ), >, >=, <, <=, ==, !=, &&, ||, ], , , ;, )}
JointE -> RelE Union                            // first(JointE) = {id, -, !, *, &, (, Num, true, false}
                                                // follow(JointE) = {], , , ;, )}
RelE -> E RRelE                                 // first(RelE) = {id, -, !, *, &, (, Num, true, false}
                                                // follow(RelE) = {&&, ||, ], , , ;, )}
RRelE -> RelOp E RRelE | eps                    // first(RRelE) = {>, >=, <, <=, ==, !=}
                                                // follow(RRelE) = {&&, ||, ], , , ;, )}
RelOp -> > | >= | < | <= | == | !=              // first(RelOp) = {>, >=, <, <=, ==, !=}

; Union -> || UnionT Union | eps                  // first(Union) = {||, eps}
;                                                 // follow(Union) = {], , , ;, ), ||}
; UnionT -> RelE Intersect                        // first(UnionT) = {id, -, !, *, &, (, Num, true, false}
;                                                 // follow(UnionT) = {||}
; Intersect -> && RelE Intersect | eps            // first(Intersect) = {&&, eps}
;                                                 // follow(Intersect) = {||}

E -> T RE
RE -> + T RE
T -> F RT

JointE -> RelE Union
Union -> Intersect UnionT
UnionT -> || RelE Intersect UnionT | eps
Intersect -> && RelE Intersect | eps


| TODO |
add CC 
add rSt -> return CC ;
add Pa -> CC
add  new *Na;
design heap system
| TODO | 