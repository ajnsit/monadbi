MonadBi (monadbi-0.1)
============================

***Note: This repo is currently not being maintained. I may start working on this again if some fresh and promising ideas come up.***

This module provides a Class called `MonadBi` which acts as a superset of `MonadTrans`,
and provides `raise` analogous to `lift`, i.e. lifts underlying monads into the transformer.
It also provides `lower` which is the opposite of `lift`, and extracts underlying monads
from monad transformers.

Generally speaking, MonadBi represents the relationship between monads that can be
transformed into each other (atleast partially).

Natural instances are provided for many Monad Transformers.


Changelog
=========

0.1 : Intial release
