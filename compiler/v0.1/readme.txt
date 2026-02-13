VERSION: v0.1

Syntax rules supported by the current version are specified in the grammar.txt file;

Notes:
This is the original handwritten version in x86 32 bit assembly.

Limitations:
Type casting changes the original size of the value, i.e. if a char is cast to a pointer,
the generated assembly will request a 4 byte size memory chunk from a byte sized allocated space.
Type casting can't be used on values immediately returned by function calls.
Structure passing as value doesn't work.
Generator is currently tasked to resolve operations on constants, planned to move the logic to analysis stage in v0.2.
Desolving branch statements when supplied with constants or evaluated constant values not supported.
Register spilling not implemented.
Non top level return statements don't generate a jump to the end of function body.
Functions can have no statements.