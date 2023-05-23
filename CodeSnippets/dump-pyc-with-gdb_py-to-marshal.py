from __future__ import print_function

import py_compile
import sys
import os

def py_to_marshal(input_file):
    """
    Create a .pyc and .marshal file for the given Python source file
    """
    base_file, ext = os.path.splitext(input_file)
    pyc_file = base_file + ".pyc"
    marshal_file = base_file + ".marshal"

    # Compile to a pyc file
    py_compile.compile(input_file, pyc_file)

    # Trim off the pyc header, leaving only the marshalled code
    if sys.version_info >= (3,7):
        # The header size is 4 bytes longer from Python 3.7
        # See: https://www.python.org/dev/peps/pep-0552
        header_size = 16
    elif sys.version_info >= (3,2):
        # Python 3.2 changed to a 3x 32-bit field header
        # See: https://www.python.org/dev/peps/pep-3147/
        header_size = 12
    else:
        # Python 2.x uses a 2x 32-bit field header
        header_size = 8

    with open(pyc_file, 'rb') as pyc_handle:
        with open(marshal_file, 'wb') as marshal_handle:
            marshal_handle.write(pyc_handle.read()[header_size:])

    return marshal_file


if __name__ == "__main__":
    print("Python %s " % sys.version)

    # Process all arguments as filenames
    for input_file in sys.argv[1:]:
        output_file = py_to_marshal(input_file)

        print("%s -> %s" % (input_file, output_file))