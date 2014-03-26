module Data.Quantities.DefinitionsSpec (spec) where

import Data.Either (rights)
import qualified Data.Map as M

import Data.Quantities.Data (Definition(..), Definitions(..), SimpleUnit(..),
                             baseQuant)
import Data.Quantities.Definitions
import Test.Hspec

{-# ANN module "HLint: ignore Redundant do" #-}

spec :: Spec
spec = do
    let baseDef  = BaseDefinition "meter" "length" ["m"]
        baseDict = makeDefinitions [baseDef]
        preDef  = PrefixDefinition "milli" 1e-3 ["m"]
        preDict = makeDefinitions [preDef]
        ftQuant = baseQuant 3.21 [SimpleUnit "m" "" 1]
        ftDef = UnitDefinition "foot" ftQuant ["ft", "feet"]
        ftDict = makeDefinitions [baseDef, ftDef]
        allDict = makeDefinitions [baseDef, preDef, ftDef]

    describe "makeDefinitions" $ do
      it "makes base definition" $ do
        bases baseDict M.! "meter" `shouldBe` "meter"
        conversions baseDict M.! ("meter", "meter") `shouldBe` 1
        unitsList baseDict  `shouldBe` ["meter", "m"]
        synonyms baseDict M.! "m" `shouldBe` "meter"
        unitTypes baseDict M.! "meter" `shouldBe` "length"

      it "makes prefix definition" $ do
        prefixes preDict `shouldBe` ["milli", "m"]
        prefixValues preDict M.! "milli" `shouldBe` 1e-3
        prefixSynonyms preDict M.! "m" `shouldBe` "milli"

      it "makes unit definition" $ do
        bases ftDict M.! "foot" `shouldBe` "meter"
        conversions ftDict M.! ("foot", "meter") `shouldBe` 3.21
        synonyms ftDict M.! "ft" `shouldBe` "foot"
        "foot" `elem` unitsList ftDict `shouldBe` True

    let m2    = SimpleUnit "m" "" 2
        ppm2  = SimpleUnit "meter" "" 2
        mm2   = SimpleUnit "mm" "" 2
        ppmm2 = SimpleUnit "meter" "milli" 2
        bad   = SimpleUnit "asdfdsaf" "" 2

    describe "preprocessUnit" $ do
      it "handles base" $ do
        let (Right computed) = preprocessUnit baseDict m2
        computed  `shouldBe` ppm2

      it "handles prefix" $ do
        let (Right computed) = preprocessUnit allDict mm2
        computed `shouldBe` ppmm2

      it "rejects bad unit" $ do
        let ret = preprocessUnit allDict bad
        isLeft ret `shouldBe` True

    let qm2 = baseQuant 3 [m2]
    describe "preprocessQuantity" $ do
      it "doesn't need own dict" $ do
        let (Right computed) = preprocessQuantity allDict qm2
        computed  `shouldBe` baseQuant 3 [ppm2]

    let hectDef  = PrefixDefinition "hecto" 1e-3 ["h"]
        hrDef = BaseDefinition "hour" "time" ["h", "hr"]
        hectHrDict = makeDefinitions [hectDef, hrDef]
    describe "prefixParser" $ do
      it "handles unit/prefix ambiguity" $ do
        let (pr, sym) = prefixParser hectHrDict "hr"
        pr `shouldBe` ""
        sym `shouldBe` "hr"

isLeft :: Either a b -> Bool
isLeft = null . rights . return
