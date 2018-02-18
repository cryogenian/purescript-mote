module Test.Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, log)
import Data.Exists (Exists)
import Data.Foldable (sequence_)
import Data.Maybe (Maybe, maybe)
import Data.Monoid (power)
import Mote (Mote, Plan, bracket, group, item, only, plan, skip)
import Mote.Entry (Bracket, unBracket)
import Mote.Plan (foldPlan)

type Effects = (console :: CONSOLE)

type TestBracket = Eff Effects
type Test = Eff Effects

main :: Eff Effects Unit
main = interpret $ plan spec

interpret :: Plan TestBracket (Test Unit) -> Eff Effects Unit
interpret = run 0
  where
    run depth =
      foldPlan
        (\{ label, bracket, value } -> do
          log (indent depth label)
          withBracket depth bracket value)
        log
        (\{ label, bracket, value } -> do
          log (indent depth label)
          withBracket depth bracket (run (depth + 1) value))
        sequence_
    indent :: Int -> String -> String
    indent depth s = power "--" depth <> s

    withBracket :: forall a. Int -> Maybe (Exists (Bracket TestBracket)) -> Eff Effects a -> Eff Effects a
    withBracket depth mbracket act = maybe act go mbracket
      where
        go :: Exists (Bracket TestBracket) -> Eff Effects a
        go = unBracket \before after -> do
          r <- before
          result <- act
          after r
          pure result

spec :: Mote TestBracket (Test Unit) Unit
spec = do
  group "A bunch of stuff" do
    skip $ item "Do a setup thing" do
      pure unit
    skip $ group "Some less stuff" do
      item "A thing" do
        pure unit
      only $ item "Another thing" do
        pure unit
      item "A final thing" do
        pure unit
    group "Some other less stuff" do
      bracket { before: log "> Sneak before", after: const (log "> Sneak after") } do
        item "A other thing" do
          log "Do some test bidnezz"
          pure unit
        item "A other thing 2" do
          log "Do some test bidnezz"
          pure unit
      item "Another other thing" do
        pure unit
