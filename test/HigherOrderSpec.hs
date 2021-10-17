-- | This module is adapted from https://github.com/polysemy-research/polysemy/blob/master/test/HigherOrderSpec.hs,
-- originally BSD3 license, authors Sandy Maguire et al.
module HigherOrderSpec where

import           Cleff
import           Cleff.Reader
import           Test.Hspec

spec :: Spec
spec = parallel $ describe "Reader local" $ do
  it "should nest with itself" $ do
    let foo = runPure . runReader "hello" $ do
                local (++ " world") $ do
                  local (++ "!") $ do
                    ask
    foo `shouldBe` "hello world!"
