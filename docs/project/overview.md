# Project Overview
The goal of the project is to test, release and deploy an operator to index so it is easily installable.

The process is displayed below.

```mermaid

graph TD
id1(Operator locally) --> id2(PR to project) --> id3(Operator test) --> id4(Operator release to index)--> id5(Install operator on cluster)

```
Let's get started with [Project initialize](/project/init).