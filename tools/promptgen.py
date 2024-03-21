from sys import argv
import yaml
import os.path
import re

is_annotation = re.compile(r"(--|//) _LLMHWS_(.+)_(BEGIN|END)_")

class name_generator:
    def __init__(self, extension:str):
        extension = extension.lower()
        if extension == "vhd":
            self.language = "vhdl"
        elif extension == "v" or extension == "sv":
            self.language = "verilog"
        else:
            raise f"Unsupported file extension `{extension}`"
    def generate_name(self, base:str, isbegin:bool) -> str:
        out = ""
        if self.language == "vhdl":
            out = "-- "
        elif self.language == "verilog":
            out = "// "
        out += "_LLMHWS_" + base
        if isbegin:
            out += "_BEGIN_"
        else:
            out += "_END_"
        return out

if __name__ == "__main__":
    if len(argv) != 3:
        print("Usage: python " + argv[0] + " <SRC-path> <llm-name> <output-path>")
        exit(1)
    yamlpath = argv[1]
    llmname = argv[2]

    with open(yamlpath, "r") as srcin:
        metadata = yaml.safe_load(srcin)
    
    print(metadata)

    srcroot = os.path.dirname(yamlpath)
    for record in metadata:
        path = record["path"]
        units = record["units"]
        sourcepath = os.path.join(srcroot, path)
        _, extension = os.path.splitext(sourcepath)
        namegen = name_generator(extension[1:])
        for unit in units:
            # Print the instruction header
            print("There's a comment in the following code describing what you are supposed to do to make it work. Modify the code according to that comment. ")
            print("")
            header_line = namegen.generate_name("HEADER_COMMENT", False)
            unit_begin_line = namegen.generate_name(unit, True)
            unit_end_line = namegen.generate_name(unit, False)
            with open(sourcepath, "r") as fin:
                state = "header"
                for line in fin:
                    _line = line.strip()
                    if state == "header":
                        # Purge the header first
                        if _line == header_line:
                            state = "normal"
                    elif state == "unit":
                        # Wait for the unit to end
                        if _line == unit_end_line:
                            state = "normal"
                    else:
                        # Keep the lines. Meanwhile, wait for the unit to begin
                        if _line == unit_begin_line:
                            # Insert the LLM instruction in lieu of the first line of the unit
                            print(f"-- Instructions for {llmname}: Write the correct state transition logic here. Do not change anything else. ")
                            state = "unit"
                        else:
                            # Only print the lines that are not LLMHWS-related annotations
                            if is_annotation.match(line) == None:
                                print(line, end="")
