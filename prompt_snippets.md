##Prompts
- What is the purpose of @<filepath>? Is it necessary/redundant? Can it be deleted? Make your response clear but brief.
- Apply the user guidelines and rules to refactor @<filepath>. Make your response clear but brief.
- Refactor @<filepath> so it actually tests from the project's source code. Make your response clear but brief.
- Commit the project changes. Make your response clear but brief.
- Delete build artifacts (e.g. executables) generated during the editing session. Make your response clear but brief.
- Refactor the code to actually use Mojo's built-in benchmark API. Reference `from benchmark import...`. Make your response clear but brief.
- Refactor @<filenpath> so it is general to all GPU acceleration hardware. Make your response clear but brief.
- Delete @<filepath>. Make your response clear but brief.
- Add a `main()` function to allow for @<filepath> to be executed independent from other source files. Make your response clear but brief.

##Prompt 2025-08-15
Perform a comprehensive dead code analysis on the file @<filepath>> to identify and remove unused functions and methods. Specifically:

1. **Analyze all functions and methods** in the file to determine if they are:
   - Called within the same file (internal usage)
   - Imported and used by other files in the project (external usage)
   - Part of the public API that should be preserved

2. **Use codebase search tools** to check for usage across the entire project before deletion, including:
   - Direct function calls
   - Method invocations on struct instances
   - Import statements that reference these functions

3. **Prioritize removal of methods** that appear to be unused utility functions, but verify this through systematic search

4. **Preserve essential methods** such as:
   - Constructors (`__init__`, `__del__`)
   - Core operations
   - Public API methods that may be used by external modules

5. **After each deletion**, verify that the file still compiles successfully and maintains 100% mojo_syntax.md compliance

6. **Document the cleanup** by listing which functions/methods were removed and confirming they had no dependencies

The goal is to streamline the codebase by removing dead code while preserving all functionality that is actually used within the project.
