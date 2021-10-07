module Effect.Mask where

import           Control.Monad.IO.Class (liftIO)
import           Effect
import           Effect.Internal.Base   (thisIsPureTrustMe)
import qualified UnliftIO.Exception     as Exc

data Mask :: Effect where
  Mask :: ((forall x. m x -> m x) -> m a) -> Mask m a
  UninterruptibleMask :: ((forall x. m x -> m x) -> m a) -> Mask m a
  Bracket :: m a -> (a -> m c) -> (a -> m b) -> Mask m b
  BracketOnError :: m a -> (a -> m c) -> (a -> m b) -> Mask m b

mask :: Mask :> es => ((forall x. Eff es x -> Eff es x) -> Eff es a) -> Eff es a
mask f = send $ Mask f
{-# INLINE mask #-}

mask_ :: Mask :> es => Eff es a -> Eff es a
mask_ m = mask $ const m
{-# INLINE mask_ #-}

uninterruptibleMask :: Mask :> es => ((forall x. Eff es x -> Eff es x) -> Eff es a) -> Eff es a
uninterruptibleMask f = send $ UninterruptibleMask f
{-# INLINE uninterruptibleMask #-}

uninterruptibleMask_ :: Mask :> es => Eff es a -> Eff es a
uninterruptibleMask_ m = uninterruptibleMask $ const m
{-# INLINE uninterruptibleMask_ #-}

bracket :: Mask :> es => Eff es a -> (a -> Eff es c) -> (a -> Eff es b) -> Eff es b
bracket ma mz m = send $ Bracket ma mz m
{-# INLINE bracket #-}

bracket_ :: Mask :> es => Eff es a -> Eff es c -> (a -> Eff es b) -> Eff es b
bracket_ ma mz = bracket ma (const mz)
{-# INLINE bracket_ #-}

bracketOnError :: Mask :> es => Eff es a -> (a -> Eff es c) -> (a -> Eff es b) -> Eff es b
bracketOnError ma mz m = send $ BracketOnError ma mz m
{-# INLINE bracketOnError #-}

finally :: Mask :> es => Eff es a -> Eff es b -> Eff es a
finally m mz = bracket_ (pure ()) mz (const m)
{-# INLINE finally #-}

onError :: Mask :> es => Eff es a -> Eff es b -> Eff es a
onError m mz = bracketOnError (pure ()) (const mz) (const m)
{-# INLINE onError #-}

runMask :: forall es a. Eff (Mask ': es) a -> Eff es a
runMask = thisIsPureTrustMe . reinterpret \case
  Mask f -> liftIO $ Exc.mask \restore -> withLiftIO \lift -> f (lift . restore . unliftIO)
  UninterruptibleMask f -> liftIO $ Exc.mask \restore -> withLiftIO \lift -> f (lift . restore . unliftIO)
  Bracket ma mz m -> liftIO $ Exc.bracket (unliftIO ma) (unliftIO . mz) (unliftIO . m)
  BracketOnError ma mz m -> liftIO $ Exc.bracketOnError (unliftIO ma) (unliftIO . mz) (unliftIO . m)