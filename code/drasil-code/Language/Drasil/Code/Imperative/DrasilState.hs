module Language.Drasil.Code.Imperative.DrasilState (
  DrasilState(..), inMod
) where

import Language.Drasil
import Language.Drasil.CodeSpec (AuxFile, CodeSpec, Modularity(..), Comments, 
  Verbosity, MatchedConceptMap, MatchedSpaces, ConstantRepr, ConstantStructure, 
  ConstraintBehaviour, InputModule(..), Logging, Structure, 
  ImplementationType(..))

-- Private State, used to push these options around the generator
data DrasilState = DrasilState {
  codeSpec :: CodeSpec,
  date :: String,
  modular :: Modularity,
  implType :: ImplementationType,
  inStruct :: Structure,
  conStruct :: ConstantStructure,
  conRepr :: ConstantRepr,
  logName :: String,
  logKind :: [Logging],
  commented :: [Comments],
  doxOutput :: Verbosity,
  concMatches :: MatchedConceptMap,
  spaceMatches :: MatchedSpaces,
  auxiliaries :: [AuxFile],
  sampleData :: [Expr],
  currentModule :: String,
  currentClass :: String,

  onSfwrC :: ConstraintBehaviour,
  onPhysC :: ConstraintBehaviour
}

inMod :: DrasilState -> InputModule
inMod ds = inMod' $ modular ds
  where inMod' Unmodular = Combined
        inMod' (Modular im) = im