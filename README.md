### Learning Pathway

### Setup

```
$ git clone https://github.com/rewinfrey/learning_pathway.git
$ cd learning_pathway
$ bundle
```

### Run Tests

```
$ cd learning_pathway
$ bundle exec rspec
```

### Run Program

```
$ cd learning_pathway
$ bin/plan data/domain_order.csv data/student_tests.csv
```

### Approach

To start, I decided that a graph-like data structure would allow me to easily figure
out the next domain / standard for a given student. I opted to use a hash map, whose
keys are a domain / standard, and whose value represents its proceeding domain / standard.
I refer to this structure in the code as the `domain_order_map` and is constructed
via the `DomainMapper` class:

```ruby
{
  "K.RF"=>"K.RL",
  "K.RL"=>"K.RI",
  "K.RI"=>"1.RF",
  ...
  "6.RI"=>"6.RL",
  "6.RL"=>nil
}
```

Depending on the `DomainMapper` class is the `CurriculumBuilder` class. The `CurriculumBuilder`
has a single public method named `plan`. Despite the final version of `CurriculumBulder`
containing a single public method, the majority of the heavy lifting occurs within
private methods. The majority of those methods were initially test-driven and those
tests / steps can be found in the git log.

To build up the learning pathway, I chose to first determine the starting
domain / standard for a given student's test scores. From there, I used the `domain_order_map`
to determine the next possible domain / standard combination, and verify if that next
domain / standard combination is applicable for the student given their test scores.
If the student has not yet mastered that domain / stadandard the algorithm adds it to the student's
curriculum. If the student has mastered that domain / standard the algorithm continues traversing
through the `domain_order_map` until the next applicable domain / standard for that
student is found. This process repeats until the curriculum length for that student reaches
the maximum size (5), or the end of the `domain_order_map` is reached. A student data structure
is returned containing the student's name and learning pathway. The algorithm iterates over each
student until a curriculum has been built for all students:

```ruby
[["Albin Stanton", "K.RI", "1.RI", "2.RF", "2.RI", "3.RF"],
 ["Erik Purdy", "1.RL", "1.RI", "2.RI", "2.RL", "2.L"],
 ["Aimee Cole", "K.RF", "K.RL", "1.RF", "1.RL", "1.RI"], ...]
```

I strove to make this code as generic as possible to support as many different types
of input as I could imagine. I left comments in the code in areas that I thought
were interesting, or helped to further explain my intention if this were part of
larger application.

I paid special attention to computational space by using `CSV.foreach` rather than `CSV.read`
to prevent loading potentially large CSV files into memory. I memoized results when possible,
and when iterating over collections tried to optimistically locate the target with a fall back
to a pessimistic enumeration if necessary. The worst case computational complexity for portions
of the algorithm is O(n^2).

This was a fun and interesting challenge, and I look forward to hearing feedback from the team!

== Setup ==

Our mission is to provide the best learning experiences to students, personalized
to their unique learning pathway. One aspect of that personalization is academic level:
students should work on content that is challenging, but not out of reach.

When a student first enters our system, we use their existing standardized test scores
as a way to bootstrap the correct level. If a student comes in below grade level, they
can work on something simpler than their classmates, whereas if they are way above
grade level, then they can work on more challenging material.

In this exercise, you'll take students' standardized test scores, and use some heuristics
to produce a draft learning pathway for the student.

The sample files provided work with just the reading standards, although this same approach
would be used for math, social studies, or alternate standard systems. If you're curious,
you can read more details about the reading standards here: http://www.corestandards.org/ELA-Literacy/

== Input Files ==

There are two input files:

1/ domain_order.csv -- The Common Core State Standards are grouped broadly into domains -
for example, Reading Literature (RL) is the study of fictional text, whereas
Reading Informational Text (RI) is non-fiction. This file contains the recommended order
in which a student should work through the domains.

Each row represents the ordering for a given grade level. For example, this row:

    K,RF,RL,RI

... means that students should work first on K.RF, K.RL, then K.RI.

2/ student_tests.csv -- Each student takes a standardized test aligned to the Common Core,
and for each domain, they are given an approximate grade level. The student should work
on material at the grade level for which they tested - for example, if they received
a grade of 1 for domain RL, then they should study the RL standards at the 1st grade level.

Each row represents a single student's scores; there is one column for each domain. If the student
was tested in that domain, then the grade level that they were assessed at appears in the column.

For example, in this file:

     Student Name,RF,RL,RI
     Barbara Geary,2,2,K

Barbara tested at the 2nd grade level in Reading Foundations and Reading Literature, but she's struggling
at the Kindergarten level in Reading Informational Text.

== Expected Output ==

Your program should take the two input CSVs, and produce the learning path for each student.

* If a student has no scores, then start at the beginning (with K.RF, in the example data)
* For a given domain, students shouldn't have to repeat content that they have already
mastered. For example, if a student has tested 2.RL, then they should not do K.RL or 1.RL.
* Learning path should contain up to five units (if no content is left, then fewer units are ok)
* This should be able to work with a different set of input, including a different set of
domains that may or may not be Common Core.
