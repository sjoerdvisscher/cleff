module Cleff.Input
  ( -- * Effect
    Input (..)
  , -- * Operations
    input, inputs
  , -- * Interpretations
    runInputConst, inputToListState, runInputEff
  ) where

import           Cleff
import           Cleff.State

-- * Effect

-- | An effect that is capable of reading from some input source, such as an input stream.
data Input i :: Effect where
  Input :: Input i m i

-- * Operations

makeEffect ''Input

-- | Apply a function to the result of 'input'.
inputs :: Input i :> es => (i -> i') -> Eff es i'
inputs f = f <$> input

-- * Interpretations

-- | Run an 'Input' effect by giving a constant input value.
runInputConst :: i -> Eff (Input i ': es) ~> Eff es
runInputConst x = interpret \case
  Input -> pure x
{-# INLINE runInputConst #-}

-- | Run an 'Input' effect by going through a list of values.
inputToListState :: Eff (Input (Maybe i) ': es) ~> Eff (State [i] ': es)
inputToListState = reinterpret \case
  Input -> get >>= \case
    []      -> pure Nothing
    x : xs' -> Just x <$ put xs'
{-# INLINE inputToListState #-}

-- | Run an 'Input' effect by performing a computation for each input request.
runInputEff :: Eff es i -> Eff (Input i ': es) ~> Eff es
runInputEff m = interpret \case
  Input -> m
{-# INLINE runInputEff #-}
