# About CocoaSQL

The aim of the CocoaSQL project is to deliver a de-facto database API for
Cocoa. Also, we want it to be as Cocoa compliant as possible.

# How to contribute

The easiest way to contribute to it is:

* Install [Homebrew](https://github.com/mxcl/homebrew).
* Install MySQL: `brew install mysql`
* Copy `libmysqlclient.dylib` into the project directory’s root folder.
* Install PostgreSQL: `brew install postgres`
* Copy `libpq.dylib` into the project directory’s root folder.

In order to run the tests (at least for now) you need to install both RDBM’s.
