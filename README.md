Charon
===========
Simple report tool which generate report on state of maintenance branch in repository.

# Contributing
------------
Contributions welcome, but make sure your code passes checkstyle and respects the [formatting style](https://github.com/wildfly/wildfly-core/tree/master/ide-configs/eclipse/formatter.xml) before submitting a PR.  Furthermore, all new files must contain the JBOSS copyright notice, templates for different IDEs can be found [here](https://github.com/wildfly/wildfly-core/tree/master/ide-configs/eclipse).

## Commit Guidelines
Where possible, please try to link a commit to the GitHub issue that it aims to solve.  Commit messages should be in the format "Issue #\<Insert issue number here\>: \<Insert relevant message\>". Note, ensure that there is a space before "#<Issue number>" so that GitHub can automatically transform the string into a link to the relevant issue. 

#Configuration
------------
Currently Charon is just a script which depends on:
* GIT
* SVN
* BASH
* CLOC 
	* https://github.com/AlDanial/cloc
	
All above dependencies must be met in order  to run.

#Input
------------
Accepted input must be in form of regular CSV values. Default delimiter character is ';'.
Record values are as follows:
* ID of entry
* Contact URI
* Repository type: GIT,SVN, ARCHIVE
* Repository URL
* Maintenance branch if any
* Tag present in EAP - if any
* Version of artifact present in EAP/WFLY
* Maven GroupID
* Difference in commits between maintenance branch and tag
* CLOC report
* Comment

#Execution
Simply call script with path to input file, as follows:
```
report.sh ./config/inputEAP7.x.txt
```

#Outcome
Report should be present in **report** directory.



