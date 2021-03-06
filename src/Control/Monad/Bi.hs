{-# LANGUAGE PackageImports #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances, FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{- |
Module      :  Control.Monad.Bi
Copyright   :  (c) Anupam Jain 2011
License     :  GNU GPL Version 3 (see the file LICENSE)

Maintainer  :  ajnsit@gmail.com
Stability   :  experimental
Portability :  non-portable (uses ghc extensions)

MonadBi represents the relationship between monads that can be transformed into each other (atleast partially).

MonadBi acts as a superset of MonadTrans, and provides `raise` analogous to `lift`, which lifts underlying monads
into the transformer. It also provides `lower` which is the opposite of `lift`, and extracts underlying monads
from monad transformers.

Natural instances are provided for many Monad Transformers.
-}

module Control.Monad.Bi (
  MonadBi(..),
  raiseVia,
  lowerVia,
  lazyIO,
  collect,
  collectN,
) where

import "mtl" Control.Monad.Reader (ReaderT, runReaderT, ask)
import "mtl" Control.Monad.State (StateT, runStateT, get, MonadIO, liftIO)
import "mtl" Control.Monad.Trans (lift)
import Control.Monad (liftM, liftM2, join)
import System.IO.Unsafe (unsafeInterleaveIO)

-----------------------
-- Class Declaration --
-----------------------

class (Monad m1, Monad m2) => MonadBi m1 m2 where
  raise :: m2 a -> m1 a
  lower :: m1 a -> m1 (m2 a)


---------------
-- Instances --
---------------

-- The trivial Id instance
instance Monad m => MonadBi m m where
  raise = id
  lower = return

-- Creating more complicated instances from base instances
-- We need to provide a 'via' parameter which tells Haskell how to convert
-- Usually you would invoke it with undefined

raiseVia :: (MonadBi m1 m2, MonadBi m2 m3) => m2 a -> (m3 a -> m1 a)
raiseVia via = raise . (flip asTypeOf) via . raise

lowerVia :: (MonadBi m1 m2, MonadBi m2 m3) => m2 a -> (m1 a -> m1 (m3 a))
lowerVia via = join . liftM (raise . lower . (flip asTypeOf) via) . lower


----------------------------
-- Some Example Instances --
----------------------------

-- StateT
instance (Monad m) => MonadBi (StateT s m) m where
  raise = lift
  -- Composes a value that simply runs using the current values of State
  lower m = get >>= return . fmap' fst . runStateT m
    where fmap' f x = x >>= return . f

-- ReaderT
instance Monad m => MonadBi (ReaderT c m) m where
  raise = lift
  -- Composes a value that simply runs using the current values of Config
  lower m = ask >>= return . runReaderT m

-- Transformer stack (to demonstrate the usage of raiseVia and lowerVia)
instance (Monad m) => MonadBi (StateT s (ReaderT c m)) m where
  raise = raiseVia (undefined :: ReaderT c m a)
  -- Composes a value that simply runs using the current values of State
  lower = lowerVia (undefined :: ReaderT c m a)


--------------------
-- TRULY LAZY IO! --
--------------------

-- Does not execute the IO action embedded inside the monad IF the IO value is not used.
lazyIO :: (MonadBi m IO) => m a -> m a
lazyIO = join . liftM (raise . unsafeInterleaveIO) . lower


-------------------------------
-- UTILITY MONADIC FUNCTIONS --
-------------------------------

-- Uses Truly Lazy IO
collect :: (MonadBi m IO) => m a -> (a -> m b) -> m [b]
collect m f = let h = m >>= \a -> liftM2 (:) (f a) (lazyIO h) in h

collectN :: (MonadBi m IO) => Int -> m a -> (a -> m b) -> m [b]
collectN n m f = liftM (take n) (collect m f)

