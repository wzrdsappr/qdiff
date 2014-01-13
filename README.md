qdiff
=====

Common Lisp library that allows you to create diffs of quicklisp-installed libraries

Description
-----------
This project provides an easy way to determine the differences between a local copy
of a library installed using QuickLisp and the canonical version as QuickLisp knows it.

Usage
-----
All installed systems can be checked at once using the QDIFF-ALL function.

Executing qdiff-all will display each system that is different from the canonical version
```lisp
(qdiff:qdiff-all)
```
Setting the ```:VERBOSE``` keyword will display the actual differences in each modified system
```lisp
(qdiff:qdiff-all :verbose t)
```
Setting the ```:TO-FILES``` keyword will write the differences for each system to a unified
diff file, named with the system name and date/time. The ```:TARGET-DIR``` keyword may also
be set with the name of the directory where the diff files should be created.  By default
it is set to the value of the ```*DEFAULT-PATHNAME-DEFAULTS*``` parameter.  The full path
of each file will be printed for reference.
```lisp
(qdiff:qdiff-all :to-files t :target-dir "/target/directory/path/")
```

An individual package can be checked using the QDIFF method.
```lisp
(qdiff:qdiff "project-name")
```

To create a diff for an individual package, the QDIFF-TO-FILE function can be used.
```lisp
(qdiff:qdiff-to-file "project-name" "/target/directory/path/")
```

Change Log
----------
<table>
<tr><td>2011-09-27</td><td>Hans Huebner</td><td>Original version</td></tr>
<tr><td>2011-10-01</td><td>Jonathan Lee</td>
    <td>Added the ability to find diffs on a Windows box and packaged it into a project </td></tr>
<tr><td>2011-11-10</td><td>Jonathan Lee</td>
    <td>Added the ability to generate unified diff files for an individual project or all changed projects</td></tr>
<tr><td>2014-01-12</td><td>Jonathan Lee</td>
    <td>Added code to implement the option of not creating diff files. Updated functions to handle changes in the way external-program:run works.</td></tr>
</table>

License
-------
MIT. See "LICENSE".

