# Win32 Python in Docker on Linux

Just in case anybody else needs such a thing!

Example usage, to interface with CLR components:

```
# requirements.txt
pythonnet
```

```python
# your_app.py

import clr
from System.Collections.Generic import Dictionary
from System import String, Int32, Type

dict1 = Dictionary[String, String]()
dict2 = Dictionary[String, Int32]()
dict3 = Dictionary[String, Type]()
```

```dockerfile
FROM benley/wine-python-dotnet
EXPOSE 8080
RUN python your_app.py
```

Normal Python stuff should generally just work.  Compiling Python extensions
may require adding more components to the wine environment, but I'm pretty sure
it can be done.
