{-# LANGUAGE TemplateHaskell, TupleSections #-}
module Language.Drasil.Code.ExtLibImport (genExternalLibraryCall) where

import Language.Drasil

import Language.Drasil.Chunk.Code (CodeVarChunk, CodeFuncChunk, codeName)
import Language.Drasil.CodeExpr (new, newWithNamedArgs, msgWithNamedArgs)
import Language.Drasil.Mod (Class, Func(..), Mod, Name, packmodRequires, 
  classDef, classImplements, FuncStmt(..), funcDef, ctorDef)
import Language.Drasil.Code.ExternalLibrary (ExternalLibrary, Step(..), 
  FunctionInterface(..), Result(..), Argument(..), ArgumentInfo(..), 
  Parameter(..), ClassInfo(..), MethodInfo(..), FuncType(..))
import Language.Drasil.Code.ExternalLibraryCall (ExternalLibraryCall,
  StepGroupFill(..), StepFill(..), FunctionIntFill(..), ArgumentFill(..),
  ParameterFill(..), ClassInfoFill(..), MethodInfoFill(..))

import Control.Lens (makeLenses, (^.), over)
import Control.Monad (zipWithM)
import Control.Monad.State (State, execState, get, modify)
import Data.List (nub, partition)
import Data.List.NonEmpty ((!!), toList)
import Data.Maybe (isJust)
import Prelude hiding ((!!))

data ExtLibState = ELS {
  _mods :: [Mod],
  _defs :: [FuncStmt],
  _defined :: [Name],
  _imports :: [String],
  _modExports :: [(String, String)],
  _classDefs :: [(String, String)],
  _steps :: [FuncStmt]
}
makeLenses ''ExtLibState

initELS :: ExtLibState
initELS = ELS {
  _mods = [],
  _defs = [],
  _defined = [],
  _imports = [],
  _modExports = [],
  _classDefs = [],
  _steps = []
}

-- State Modifiers

addMod :: Mod -> ExtLibState -> ExtLibState
addMod m = over mods (m:)

addDef :: Expr -> CodeVarChunk -> ExtLibState -> ExtLibState
addDef e c s = if n `elem` (s ^. defined) then s else over defs (++ [FDecDef c 
  e]) (addDefined n s)
  where n = codeName c

addFieldAsgs :: CodeVarChunk -> [CodeVarChunk] -> [Expr] -> ExtLibState -> 
  ExtLibState
addFieldAsgs o cs es = over defs (++ zipWith (FAsgObjVar o) cs es)

addDefined :: String -> ExtLibState -> ExtLibState
addDefined n = over defined (n:)

addImports :: [String] -> ExtLibState -> ExtLibState
addImports is = over imports (\l -> nub $ l ++ is)

addModExport :: (String, String) -> ExtLibState -> ExtLibState
addModExport e = over modExports (e:)

addModExports :: [(String, String)] -> ExtLibState -> ExtLibState
addModExports es = over modExports (es++)

addClassDef :: (String, String) -> ExtLibState -> ExtLibState
addClassDef d = over classDefs (d:)

addClassDefs :: [(String, String)] -> ExtLibState -> ExtLibState
addClassDefs ds = over classDefs (ds++)

addSteps :: [FuncStmt] -> ExtLibState -> ExtLibState
addSteps fs = over steps (fs++)

refreshLocal :: ExtLibState -> ExtLibState
refreshLocal s = s {_defs = [], _defined = [], _imports = []}

returnLocal :: ExtLibState -> ExtLibState -> ExtLibState
returnLocal oldS newS = newS {_defs = oldS ^. defs, 
                              _defined = oldS ^. defined, 
                              _imports = oldS ^. imports}

-- Generators

genExternalLibraryCall :: ExternalLibrary -> ExternalLibraryCall -> 
  ExtLibState
genExternalLibraryCall el elc = execState (genExtLibCall el elc) initELS

genExtLibCall :: ExternalLibrary -> ExternalLibraryCall ->
  State ExtLibState ()
genExtLibCall [] [] = return ()
genExtLibCall (sg:el) (SGF n sgf:elc) = let s = sg!!n in 
  if length s /= length sgf then error stepNumberMismatch else do
    fs <- zipWithM genStep s sgf
    modify (addSteps fs)
    genExtLibCall el elc
genExtLibCall _ _ = error stepNumberMismatch

genStep :: Step -> StepFill -> State ExtLibState FuncStmt
genStep (Call rs fi) (CallF fif) = do
  modify (addImports rs) 
  genFI fi fif
genStep (Loop fis f ss) (LoopF fifs ccList sfs) = do
  es <- zipWithM genFIVal (toList fis) (toList fifs)
  fs <- zipWithM genStep (toList ss) (toList sfs)
  return $ FWhile (foldl1 ($&&) es $&& f ccList) fs
genStep (Statement f) (StatementF ccList exList) = return $ f ccList exList
genStep _ _ = error stepTypeMismatch

genFIVal :: FunctionInterface -> FunctionIntFill -> State ExtLibState Expr
genFIVal (FI ft f as _) (FIF afs) = do
  args <- genArguments as afs
  let isNamed = isJust . fst 
      (ars, nas) = partition isNamed args
  return $ getCallFunc ft f (map snd ars) (map (\(n, e) -> 
    maybe (error "defective isNamed") (,e) n) nas) 
  where getCallFunc Function = applyWithNamedArgs 
        getCallFunc (Method o) = msgWithNamedArgs o 
        getCallFunc Constructor = newWithNamedArgs

genFI :: FunctionInterface -> FunctionIntFill -> State ExtLibState FuncStmt
genFI fi@(FI _ _ _ r) fif = do
  fiEx <- genFIVal fi fif
  return $ maybeGenAssg r fiEx 

genArguments :: [Argument] -> [ArgumentFill] -> 
  State ExtLibState [(Maybe NamedArgument, Expr)]
genArguments as afs = fmap (zip (map getName as)) (genArgumentInfos (map getAI as) afs)

genArgumentInfos :: [ArgumentInfo] -> [ArgumentFill] -> State ExtLibState [Expr]
genArgumentInfos (LockedArg e:as) afs = fmap (e:) (genArgumentInfos as afs)
genArgumentInfos (Basic _ v:as) (BasicF e:afs) = do
  modify (maybe id (addDef e) v)
  fmap (e:) (genArgumentInfos as afs)
-- FIXME: funcexpr needs to be defined, a function-valued expression
-- Uncomment the below when funcexpr is added
genArgumentInfos (Fn c _ _{-ps s-}:as) (FnF _ _{-pfs sf-}:afs) = -- do
  -- let prms = genParameters ps pfs
  -- st <- genStep s sf
  -- modify (addDef (funcexpr prms st) c)
  fmap (sy c:) (genArgumentInfos as afs)
genArgumentInfos (Class rs desc o ctor ci:as) (ClassF svs cif:afs) = do
  (c, is) <- genClassInfo o ctor n desc svs ci cif
  modify (addMod (packmodRequires n desc (rs ++ is) [c] []))
  fmap (sy o:) (genArgumentInfos as afs)
  where n = getActorName (o ^. typ)
genArgumentInfos (Record n r fs:as) (RecordF es:afs) = 
  if length fs /= length es then error recordFieldsMismatch else do
    modify (addDef (new n []) r)
    modify (addFieldAsgs r fs es)
    fmap (sy r:) (genArgumentInfos as afs)
genArgumentInfos [] [] = return []
genArgumentInfos _ _ = error argumentMismatch
  
genClassInfo :: CodeVarChunk -> CodeFuncChunk -> String -> String -> 
  [CodeVarChunk] -> ClassInfo -> ClassInfoFill -> 
  State ExtLibState (Class, [String])
genClassInfo o c n desc svs ci cif = let (mis, mifs, f) = genCI ci cif in 
  if length mis /= length mifs then error methodInfoNumberMismatch else do
    ms <- zipWithM (genMethodInfo o c n) mis mifs
    modify (addModExports ((n,n) : zip (map codeName svs) (repeat n)) . 
      addClassDefs ((n,n) : zip (map codeName svs) (repeat n)) . 
      if any isConstructor mis then id else addDef (new c []) o)
    return (f desc svs (map fst ms), concatMap snd ms)
  where genCI (Regular mis') (RegularF mifs') = (mis', mifs', classDef n)
        genCI (Implements intn mis') (ImplementsF mifs') = (mis', mifs', 
          classImplements n intn)
        genCI _ _ = error classInfoMismatch

genMethodInfo :: CodeVarChunk -> CodeFuncChunk -> String -> MethodInfo -> 
  MethodInfoFill -> State ExtLibState (Func, [String])
genMethodInfo o c _ (CI desc ps ss) (CIF pfs is sfs) = do
  let prms = genParameters ps pfs
  (fs, newS) <- withLocalState $ zipWithM genStep ss sfs
  modify (addDef (new c (map sy prms)) o)
  return (ctorDef (codeName c) desc prms is (newS ^. defs ++ fs), 
    newS ^. imports)
genMethodInfo _ _ n (MI m desc ps rDesc ss) (MIF pfs sfs) = do
  let prms = genParameters ps pfs
  (fs, newS) <- withLocalState (zipWithM genStep (toList ss) (toList sfs))
  modify (addModExport (codeName m, n) . addClassDef (codeName m, n))
  return (funcDef (codeName m) desc prms (m ^. typ) rDesc (newS ^. defs ++ fs),
    newS ^. imports)
genMethodInfo _ _ _ _ _ = error methodInfoMismatch

genParameters :: [Parameter] -> [ParameterFill] -> [CodeVarChunk]
genParameters (LockedParam c:ps) pfs = c : genParameters ps pfs
genParameters ps (UserDefined c:pfs) = c : genParameters ps pfs
genParameters (NameableParam _:ps) (NameableParamF c:pfs) = c : 
  genParameters ps pfs
genParameters [] [] = []
genParameters _ _ = error paramMismatch

maybeGenAssg :: Maybe Result -> (Expr -> FuncStmt)
maybeGenAssg Nothing = FVal
maybeGenAssg (Just (Assign c)) = FAsg c
maybeGenAssg (Just Return)  = FRet

-- Helpers

withLocalState :: State ExtLibState a -> State ExtLibState (a, ExtLibState)
withLocalState st = do
  s <- get
  modify refreshLocal
  st' <- st
  newS <- get
  modify (returnLocal s)
  return (st', newS)

getName :: Argument -> Maybe NamedArgument
getName (Arg n _) = n

getAI :: Argument -> ArgumentInfo
getAI (Arg _ ai) = ai

isConstructor :: MethodInfo -> Bool
isConstructor CI {} = True
isConstructor _ = False

elAndElc, stepNumberMismatch, stepTypeMismatch, argumentMismatch, 
  paramMismatch, recordFieldsMismatch, ciAndCif, classInfoMismatch, 
  methodInfoNumberMismatch, methodInfoMismatch :: String
elAndElc = "ExternalLibrary and ExternalLibraStepryCall have different "
stepNumberMismatch = elAndElc ++ "number of steps"
stepTypeMismatch = elAndElc ++ "order of steps"
argumentMismatch = "FunctionInterface and FunctionIntFill have different number or types of arguments"
paramMismatch = "Parameters mismatched with ParameterFills"
recordFieldsMismatch = "Different number of record fields than field values"
ciAndCif = "ClassInfo and ClassInfoFill have different "
classInfoMismatch = ciAndCif ++ "class types"
methodInfoNumberMismatch = ciAndCif ++ "number of MethodInfos/MethodInfoFills"
methodInfoMismatch = "MethodInfo and MethodInfoFill have different method types"