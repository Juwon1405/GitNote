> ###### Dumping all bytecode from a packaged Python application

This is a technique for extracting all imported modules from a packaged Python application as `.pyc` files, then decompiling them. The target program needs to be run from scratch, but no debugging symbols are necessary (assuming an unmodified build of Python is being used).

This was originally performed on 64-bit Linux with a Python 3.6 target. The Python scripts have since been updated to handle pyc files for Python 2.7 - 3.9.

## Theory

In Python we can leverage the fact that any module import involving a `.py*` file will eventually arrive as ready-to-execute Python code object at this function:

```c
PyObject* PyEval_EvalCode(PyObject *co, PyObject *globals, PyObject *locals);
```

If a breakpoint is set here in gdb, the C implementation for `marshal.dump()` can be called to dump the bytecode to file. Conveniently the `.pyc` format is simply a marshaled `PyCodeObject` with a small header.

The script `marshal-to-pyc.py` below can be used to convert these raw marshaled code objects into .pyc files and decompile them if desired.

The script `py-to-marshal.py` can be used to create raw marshal files from Python source files to demonstrate or test this without needing to extract marshaled code from a runtime.

### `pyc` file header

The format of pyc headers has changed between versions. The scripts handle this, but for completeness (since I haven't found it documented anywhere else all at once), here's the header format for each version:

All fields at the time of writing are written as little-endian 32-bit values.

- Python 2.7: `[magic_num][source_modified_time]`
- Python >= 3.2 ([PEP-3147](https://www.python.org/dev/peps/pep-3147/)): `[magic_num][source_modified_time][source_size]`
- Python >= 3.8 ([PEP-0552](https://www.python.org/dev/peps/pep-0552)): `[magic_num][bit-field][source_modified_time][source_size]`

These details are also noted in code comments.

## Implementation in GDB

Start the debugger in a stopped state:

```sh
gdb target_application
```

Then in the GDB console:

```
# Wait for the Python library to load if the symbol can't be found before runtime
catch load

# Run the program
run

# Continue until gdb breaks where the target Python .so is loading
continue
# ...

# Break on the target function
break PyEval_EvalCode
```

Now GDB can be automated to dump every `PyCodeObject` evaluated at runtime to disk. You may want to test and validate a single dump manually before proceeding with the `command` automated version.

```
# Index for writing multiple files
set $index = 0

# Define code dumping command (no symbols available)
# Passing $rdi here is equivalent to passing the `co` argument when debugging symbol are present
define dump_pyc
  eval "set $handle = fopen(\"%s/%d.marshal\", \"w\")", $arg0, $index
  call (void) PyMarshal_WriteObjectToFile($rdi, $handle, 4)
  call fclose($handle)
  set $index += 1
end

command
dump_pyc "/tmp/"
continue
end
```

The first argument of `PyEval_EvalCode` should be in the `rdi` register on x86_64 Linux, but it may differ on your platform. You may need to find the location of the first argument yourself, but once you know the location it can be substituted above.

## Testing

The script `py-to-marshal.py` can be used to create a marshaled code object from a Python source file for testing:

```bash
# Compile and strip header to create yourfile.marshal
python py-to-marshal.py yourfile.py

# Build the pyc header again and decompile
python marshal-to-pyc.py yourfile.marshal

# Look at the output (assuming the above didn't fail)
cat yourfile.marshal.py
```

The header for `pyc` files has changed several times to date. If you're running into errors about `bad marshal data (unknown code type)`, use this test to confirm the script works on your Python version.