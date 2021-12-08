---
title: Predicate Generator
---

This algorithm can be used to **generate mathematical expressions**.\
*Pretty cool, right?*

{{% gitLink "https://github.com/Xallt/PredicateProj" %}}
<!--more-->

It's a generator of logical expressions with the ability to translate them to a given *language*. 

### Examples

All the output is translated to LaTeX:

|     |     |     |
|:---:|:---:|:---:|
|*Basic*|*Mathematical*|*English*|
|{{% insStatic src="img/portfolio/predicate/BasicScreenshot.png" alt="Example" %}}|{{% insStatic src="img/portfolio/predicate/MathScreenshot.png" alt="Example" %}}|{{% insStatic src="img/portfolio/predicate/EngNaturalScreenshot.png" alt="Example" %}}|
<br>
Adjacent expressions are similar because the algorithm outputs the lines in lexigraphic order

Here are actually interesting generated "statements" (not all of them are true)
In this context variables are only non-negative integers
{{% insStatic src="img/portfolio/predicate/MathFirstScreenshot.png" alt="Example" %}}

**1)** 2 is a prime number\
**2)** <del>Every single number is prime</del>\
**3)** Prime numbers exist **!**\
**5)** Every number is equal to itself\
**6)** There are numbers which are equal to themselves\
**7)** Not all numbers are prime\
**8)** <del>Prime numbers don't exist</del>\