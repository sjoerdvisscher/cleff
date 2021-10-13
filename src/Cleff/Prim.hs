{-# LANGUAGE UnboxedTuples #-}
{-# OPTIONS_GHC -Wno-orphans #-}
module Cleff.Prim where

import           Cleff
import           Control.Monad.Primitive (PrimMonad (..))
import           GHC.Exts                (RealWorld, State#)
import           GHC.IO                  (IO (IO))

data Prim :: Effect where
  Primitive :: (State# RealWorld -> (# State# RealWorld, a #)) -> Prim m a

instance Prim :> es => PrimMonad (Eff es) where
  type PrimState (Eff es) = RealWorld
  primitive = send . Primitive

runPrim :: IOE :> es => Eff (Prim ': es) a -> Eff es a
runPrim = interpretIO \case
  Primitive m -> IO m
{-# INLINE runPrim #-}
