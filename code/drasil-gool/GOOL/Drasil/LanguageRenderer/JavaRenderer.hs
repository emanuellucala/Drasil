{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PostfixOperators #-}

-- | The logic to render Java code is contained in this module
module GOOL.Drasil.LanguageRenderer.JavaRenderer (
  -- * Java Code Configuration -- defines syntax of all Java code
  JavaCode(..)
) where

import Utils.Drasil (indent)

import GOOL.Drasil.CodeType (CodeType(..))
import GOOL.Drasil.ClassInterface (Label, MSBody, VSType, SVariable, SValue, 
  VSFunction, MSStatement, MSParameter, SMethod, CSStateVar, SClass, OOProg, 
  ProgramSym(..), FileSym(..), PermanenceSym(..), BodySym(..), bodyStatements, 
  oneLiner, BlockSym(..), TypeSym(..), TypeElim(..), ControlBlock(..), 
  VariableSym(..), VariableElim(..), ValueSym(..), Literal(..), 
  MathConstant(..), VariableValue(..), CommandLineArgs(..), 
  NumericExpression(..), BooleanExpression(..), Comparison(..), 
  ValueExpression(..), funcApp, selfFuncApp, extFuncApp, newObj, 
  InternalValueExp(..), objMethodCall, objMethodCallNoParams, FunctionSym(..), 
  ($.), GetSet(..), List(..), InternalList(..), Iterator(..), StatementSym(..), 
  AssignStatement(..), (&=), DeclStatement(..), IOStatement(..), 
  StringStatement(..), FuncAppStatement(..), CommentStatement(..), 
  ControlStatement(..), StatePattern(..), ObserverPattern(..), 
  StrategyPattern(..), ScopeSym(..), ParameterSym(..), MethodSym(..), 
  pubMethod, initializer, StateVarSym(..), privDVar, pubDVar, ClassSym(..), 
  ModuleSym(..), ODEInfo(..), ODEOptions(..), ODEMethod(..))
import GOOL.Drasil.RendererClasses (RenderSym, RenderFile(..), ImportSym(..), 
  ImportElim, PermElim(binding), RenderBody(..), BodyElim, RenderBlock(..), 
  BlockElim, RenderType(..), InternalTypeElim, UnaryOpSym(..), BinaryOpSym(..), 
  OpElim(uOpPrec, bOpPrec), RenderVariable(..), InternalVarElim(variableBind), 
  RenderValue(..), ValueElim(valuePrec), InternalGetSet(..), 
  InternalListFunc(..), InternalIterator(..), RenderFunction(..), 
  FunctionElim(functionType), InternalAssignStmt(..), InternalIOStmt(..), 
  InternalControlStmt(..), RenderStatement(..), StatementElim(statementTerm), 
  RenderScope(..), ScopeElim, MethodTypeSym(..), RenderParam(..), 
  ParamElim(parameterName, parameterType), RenderMethod(..), MethodElim, 
  StateVarElim, RenderClass(..), ClassElim, RenderMod(..), ModuleElim, 
  BlockCommentSym(..), BlockCommentElim)
import qualified GOOL.Drasil.RendererClasses as RC (import', perm, body, block,
  type', uOp, bOp, variable, value, function, statement, scope, parameter,
  method, stateVar, class', module', blockComment')
import GOOL.Drasil.LanguageRenderer (dot, new, elseIfLabel, forLabel, tryLabel,
  catchLabel, throwLabel, blockCmtStart, blockCmtEnd, docCmtStart, bodyStart, 
  bodyEnd, endStatement, commentStart, exceptionObj', new', args, exceptionObj, 
  mainFunc, new, listSep, access, containing, mathFunc, variableList, 
  parameterList, appendToBody, surroundBody, intValue)
import qualified GOOL.Drasil.LanguageRenderer as R (package, class', multiStmt, 
  body, printFile, param, listDec, classVar, cast, castObj, static, dynamic, 
  break, continue, private, public, blockCmt, docCmt, addComments, commentedMod,
  commentedItem)
import GOOL.Drasil.LanguageRenderer.Constructors (mkStmt, mkStateVal, mkVal,
  VSOp, unOpPrec, powerPrec, unExpr, unExpr', unExprNumDbl, typeUnExpr, binExpr,
  binExprNumDbl', typeBinExpr)
import qualified GOOL.Drasil.LanguageRenderer.LanguagePolymorphic as G (
  multiBody, block, multiBlock, int, listInnerType, obj, funcType, csc, sec, 
  cot, negateOp, equalOp, notEqualOp, greaterOp, greaterEqualOp, lessOp, 
  lessEqualOp, plusOp, minusOp, multOp, divideOp, moduloOp, var, staticVar, 
  arrayElem, litChar, litDouble, litInt, litString, valueOf, arg, argsList, 
  objAccess, objMethodCall, funcAppMixedArgs, selfFuncAppMixedArgs, 
  newObjMixedArgs, lambda, func, get, set, listAdd, listAppend, iterBegin, 
  iterEnd, listAccess, listSet, getFunc, setFunc, listAppendFunc, stmt, 
  loopStmt, emptyStmt, assign, increment, objDecNew, print, closeFile, 
  returnStmt, valStmt, comment, throw, ifCond, tryCatch, construct, param, 
  method, getMethod, setMethod, constructor, function, docFunc, buildClass, 
  implementingClass, docClass, commentedClass, modFromData, fileDoc, docMod, 
  fileFromData)
import GOOL.Drasil.LanguageRenderer.LanguagePolymorphic (docFuncRepr)
import qualified GOOL.Drasil.LanguageRenderer.CommonPseudoOO as CP (  
  bindingError, extVar, classVar, objVarSelf, iterVar, extFuncAppMixedArgs, 
  indexOf, listAddFunc, iterBeginError, iterEndError, listDecDef, 
  discardFileLine, destructorError, stateVarDef, constVar, intClass, objVar, 
  bool, arrayType, pi, notNull, printSt, arrayDec, arrayDecDef, openFileR, 
  openFileW, openFileA, forEach, docMain, mainFunction, stateVar, buildModule', 
  litArray, call', listSizeFunc, listAccessFunc', funcDecDef)
import qualified GOOL.Drasil.LanguageRenderer.CLike as C (float, double, char, 
  listType, void, notOp, andOp, orOp, self, litTrue, litFalse, litFloat, 
  inlineIf, libFuncAppMixedArgs, libNewObjMixedArgs, listSize, increment1, 
  varDec, varDecDef, listDec, extObjDecNew, switch, for, while, intFunc, 
  multiAssignError, multiReturnError)
import qualified GOOL.Drasil.LanguageRenderer.Macros as M (ifExists, decrement, 
  decrement1, runStrategy, listSlice, stringListVals, stringListLists,
  forRange, notifyObservers, checkState)
import GOOL.Drasil.AST (Terminator(..), ScopeTag(..), qualName, FileType(..), 
  FileData(..), fileD, FuncData(..), fd, ModData(..), md, updateMod, 
  MethodData(..), mthd, updateMthd, OpData(..), ParamData(..), pd, ProgData(..),
  progD, TypeData(..), td, ValData(..), vd, VarData(..), vard)
import GOOL.Drasil.CodeAnalysis (Exception(..), ExceptionType(..), exception, 
  stdExc, HasException(..))
import GOOL.Drasil.Helpers (emptyIfNull, toCode, toState, onCodeValue, 
  onStateValue, on2CodeValues, on2StateValues, on3CodeValues, on3StateValues, 
  onCodeList, onStateList, on1StateValue1List)
import GOOL.Drasil.State (GOOLState, VS, lensGStoFS, lensFStoVS, lensMStoFS,
  lensMStoVS, lensVStoFS, lensVStoMS, initialFS, modifyReturn, goolState,
  modifyReturnFunc, revFiles, addODEFilePaths, addProgNameToPaths, addODEFiles, 
  getODEFiles, addLangImport, addLangImportVS, addExceptionImports, 
  addLibImport, getModuleName, setFileType, getClassName, setCurrMain, 
  setODEDepVars, getODEDepVars, setODEOthVars, getODEOthVars, 
  setOutputsDeclared, isOutputsDeclared, getExceptions, getMethodExcMap, 
  addExceptions)

import Prelude hiding (break,print,sin,cos,tan,floor,(<>))
import Control.Lens ((^.))
import Control.Lens.Zoom (zoom)
import Control.Applicative (Applicative)
import Control.Monad (join)
import Control.Monad.State (modify, runState)
import Data.Composition ((.:))
import qualified Data.Map as Map (lookup)
import Data.List (elemIndex, nub, intercalate, sort)
import Text.PrettyPrint.HughesPJ (Doc, text, (<>), (<+>), parens, empty, 
  equals, vcat, lbrace, rbrace, colon)

jExt :: String
jExt = "java"

newtype JavaCode a = JC {unJC :: a}

instance Functor JavaCode where
  fmap f (JC x) = JC (f x)

instance Applicative JavaCode where
  pure = JC
  (JC f) <*> (JC x) = JC (f x)

instance Monad JavaCode where
  return = JC
  JC x >>= f = f x

instance OOProg JavaCode where

instance ProgramSym JavaCode where
  type Program JavaCode = ProgData
  prog n fs = modifyReturnFunc (\_ -> revFiles . addProgNameToPaths n)
    (onCodeList (progD n . map (R.package n endStatement)))
    (on2StateValues (++) (mapM (zoom lensGStoFS) fs) (onStateValue (map toCode) 
    getODEFiles))

instance RenderSym JavaCode

instance FileSym JavaCode where
  type File JavaCode = FileData 
  fileDoc m = do
    modify (setFileType Combined)
    G.fileDoc jExt top bottom m

  docMod = G.docMod jExt

instance RenderFile JavaCode where
  top _ = toCode empty
  bottom = toCode empty
  
  commentedMod = on2StateValues (on2CodeValues R.commentedMod)
  
  fileFromData = G.fileFromData (onCodeValue . fileD)

instance ImportSym JavaCode where
  type Import JavaCode = Doc
  langImport = toCode . jImport
  modImport = langImport

instance ImportElim JavaCode where
  import' = unJC

instance PermanenceSym JavaCode where
  type Permanence JavaCode = Doc
  static = toCode R.static
  dynamic = toCode R.dynamic

instance PermElim JavaCode where
  perm = unJC
  binding = error $ CP.bindingError jName

instance BodySym JavaCode where
  type Body JavaCode = Doc
  body = onStateList (onCodeList R.body)

  addComments s = onStateValue (onCodeValue (R.addComments s commentStart))

instance RenderBody JavaCode where
  multiBody = G.multiBody 

instance BodyElim JavaCode where
  body = unJC

instance BlockSym JavaCode where
  type Block JavaCode = Doc
  block = G.block

instance RenderBlock JavaCode where
  multiBlock = G.multiBlock

instance BlockElim JavaCode where
  block = unJC

instance TypeSym JavaCode where
  type Type JavaCode = TypeData
  bool = CP.bool
  int = G.int
  float = C.float
  double = C.double
  char = C.char
  string = jStringType
  infile = jInfileType
  outfile = jOutfileType
  listType = jListType
  arrayType = CP.arrayType
  listInnerType = G.listInnerType
  obj = G.obj
  funcType = G.funcType
  iterator t = t
  void = C.void

instance TypeElim JavaCode where
  getType = cType . unJC
  getTypeString = typeString . unJC
  
instance RenderType JavaCode where
  typeFromData t s d = toCode $ td t s d

instance InternalTypeElim JavaCode where
  type' = typeDoc . unJC

instance ControlBlock JavaCode where
  solveODE info opts = let (fls, s) = jODEFiles info 
    in modify (addODEFilePaths s . addODEFiles fls) >> (zoom lensMStoVS dv 
    >>= (\dpv -> 
      let odeVarType = obj (odeClassName dpv)
          odeVar = var "ode" odeVarType
          odeDepVar = var (odeVarName dpv) (arrayType float)
          initval = initVal info
          integVal = valueOf $ jODEIntVar (solveMethod opts)
          shn = variableName dpv ++ "_" ++ stH
          hndlr = var "stepHandler" (obj shn)
          odeClassName = ((++ "_ODE") . variableName)
          odeVarName = ((++ "_ode") . variableName)
      in multiBlock [
      block [
        jODEMethod opts,
        objDecDef odeVar (newObj odeVarType (map valueOf $ otherVars info)),
        arrayDecDef odeDepVar [initval],
        varDec dv],
      block [
        objDecDef hndlr (newObj (obj shn) []),
        valStmt $ objMethodCall void integVal "addStepHandler" [valueOf hndlr],
        valStmt $ objMethodCall void integVal "integrate"   
          [valueOf odeVar, tInit info, valueOf odeDepVar, tFinal info, 
          valueOf odeDepVar],
        dv &= valueOf (objVar hndlr dv)]]))
    where stH = "StepHandler"
          dv = depVar info

instance UnaryOpSym JavaCode where
  type UnaryOp JavaCode = OpData
  notOp = C.notOp
  negateOp = G.negateOp
  sqrtOp = jUnaryMath "sqrt"
  absOp = jUnaryMath "abs"
  logOp = jUnaryMath "log10"
  lnOp = jUnaryMath "log"
  expOp = jUnaryMath "exp"
  sinOp = jUnaryMath "sin"
  cosOp = jUnaryMath "cos"
  tanOp = jUnaryMath "tan"
  asinOp = jUnaryMath "asin"
  acosOp = jUnaryMath "acos"
  atanOp = jUnaryMath "atan"
  floorOp = jUnaryMath "floor"
  ceilOp = jUnaryMath "ceil"

instance BinaryOpSym JavaCode where
  type BinaryOp JavaCode = OpData
  equalOp = G.equalOp
  notEqualOp = G.notEqualOp
  greaterOp = G.greaterOp
  greaterEqualOp = G.greaterEqualOp
  lessOp = G.lessOp
  lessEqualOp = G.lessEqualOp
  plusOp = G.plusOp
  minusOp = G.minusOp
  multOp = G.multOp
  divideOp = G.divideOp
  powerOp = powerPrec $ mathFunc "pow"
  moduloOp = G.moduloOp
  andOp = C.andOp
  orOp = C.orOp

instance OpElim JavaCode where
  uOp = opDoc . unJC
  bOp = opDoc . unJC
  uOpPrec = opPrec . unJC
  bOpPrec = opPrec . unJC

instance VariableSym JavaCode where
  type Variable JavaCode = VarData
  var = G.var
  staticVar = G.staticVar
  const = var
  extVar = CP.extVar
  self = C.self
  classVar = CP.classVar R.classVar
  extClassVar = classVar
  objVar o v = join $ on3StateValues (\ovs ob vr -> if (variableName ob ++ "." 
    ++ variableName vr) `elem` ovs then toState vr else CP.objVar (toState ob) 
    (toState vr)) getODEOthVars o v
  objVarSelf = CP.objVarSelf
  arrayElem i = G.arrayElem (litInt i)
  iterVar = CP.iterVar

instance VariableElim JavaCode where
  variableName = varName . unJC
  variableType = onCodeValue varType
  
instance InternalVarElim JavaCode where
  variableBind = varBind . unJC
  variable = varDoc . unJC

instance RenderVariable JavaCode where
  varFromData b n t d = on2CodeValues (vard b n) t (toCode d)

instance ValueSym JavaCode where
  type Value JavaCode = ValData
  valueType = onCodeValue valType

instance Literal JavaCode where
  litTrue = C.litTrue
  litFalse = C.litFalse
  litChar = G.litChar
  litDouble = G.litDouble
  litFloat = C.litFloat
  litInt = G.litInt
  litString = G.litString
  litArray = CP.litArray
  litList t es = do
    zoom lensVStoMS $ modify (if null es then id else addLangImport $ utilImport
      jArrays)
    newObj (listType t) [jAsListFunc t es | not (null es)]

instance MathConstant JavaCode where
  pi = CP.pi

instance VariableValue JavaCode where
  valueOf v = G.valueOf $ join $ on2StateValues (\dvs vr -> maybe v (\i -> 
    arrayElem (toInteger i) v) (elemIndex (variableName vr) dvs)) 
    getODEDepVars v

instance CommandLineArgs JavaCode where
  arg n = G.arg (litInt n) argsList
  argsList = G.argsList args
  argExists i = listSize argsList ?> litInt (fromIntegral i)

instance NumericExpression JavaCode where
  (#~) = unExpr' negateOp
  (#/^) = unExprNumDbl sqrtOp
  (#|) = unExpr absOp
  (#+) = binExpr plusOp
  (#-) = binExpr minusOp
  (#*) = binExpr multOp
  (#/) = binExpr divideOp
  (#%) = binExpr moduloOp
  (#^) = binExprNumDbl' powerOp

  log = unExprNumDbl logOp
  ln = unExprNumDbl lnOp
  exp = unExprNumDbl expOp
  sin = unExprNumDbl sinOp
  cos = unExprNumDbl cosOp
  tan = unExprNumDbl tanOp
  csc = G.csc
  sec = G.sec
  cot = G.cot
  arcsin = unExprNumDbl asinOp
  arccos = unExprNumDbl acosOp
  arctan = unExprNumDbl atanOp
  floor = unExpr floorOp
  ceil = unExpr ceilOp

instance BooleanExpression JavaCode where
  (?!) = typeUnExpr notOp bool
  (?&&) = typeBinExpr andOp bool
  (?||) = typeBinExpr orOp bool

instance Comparison JavaCode where
  (?<) = typeBinExpr lessOp bool
  (?<=) = typeBinExpr lessEqualOp bool
  (?>) = typeBinExpr greaterOp bool
  (?>=) = typeBinExpr greaterEqualOp bool
  (?==) = jEquality
  (?!=) = typeBinExpr notEqualOp bool
  
instance ValueExpression JavaCode where
  inlineIf = C.inlineIf

  -- Exceptions from function/method calls should already be in the exception 
  -- map from the CodeInfo pass, but it's possible that one of the higher-level 
  -- functions implicitly calls these functions in the Java renderer, so we 
  -- also check here to add the exceptions from the called function to the map
  funcAppMixedArgs n t vs ns = do
    addCallExcsCurrMod n 
    G.funcAppMixedArgs n t vs ns
  selfFuncAppMixedArgs n t ps ns = do
    addCallExcsCurrMod n
    G.selfFuncAppMixedArgs dot self n t ps ns
  extFuncAppMixedArgs l n t vs ns = do
    mem <- getMethodExcMap
    modify (maybe id addExceptions (Map.lookup (qualName l n) mem))
    CP.extFuncAppMixedArgs l n t vs ns
  libFuncAppMixedArgs = C.libFuncAppMixedArgs
  newObjMixedArgs ot vs ns = addConstructorCallExcsCurrMod ot (\t -> 
    G.newObjMixedArgs (new ++ " ") t vs ns)
  extNewObjMixedArgs l ot vs ns = do
    t <- ot
    mem <- getMethodExcMap
    let tp = getTypeString t
    modify (maybe id addExceptions (Map.lookup (qualName l tp) mem))
    newObjMixedArgs (toState t) vs ns
  libNewObjMixedArgs = C.libNewObjMixedArgs

  lambda = G.lambda jLambda

  notNull = CP.notNull

instance RenderValue JavaCode where
  inputFunc = modify (addLangImportVS $ utilImport jScanner) >> mkStateVal 
    (obj jScanner) (parens $ new' <+> jScanner' <> parens (jSystem jStdIn))
  printFunc = mkStateVal void (jSystem (jStdOut `access` jPrint))
  printLnFunc = mkStateVal void (jSystem (jStdOut `access` jPrintLn))
  printFileFunc = on2StateValues (\v -> mkVal v . R.printFile jPrint . 
    RC.value) void
  printFileLnFunc = on2StateValues (\v -> mkVal v . R.printFile jPrintLn . 
    RC.value) void
  
  cast = jCast

  call = CP.call' jName
  
  valFromData p t d = on2CodeValues (vd p) t (toCode d)

instance ValueElim JavaCode where
  valuePrec = valPrec . unJC
  value = val . unJC

instance InternalValueExp JavaCode where
  objMethodCallMixedArgs' f t o ps ns = do
    ob <- o
    mem <- getMethodExcMap
    let tp = getTypeString (valueType ob)
    modify (maybe id addExceptions (Map.lookup (qualName tp f) mem))
    G.objMethodCall f t o ps ns

instance FunctionSym JavaCode where
  type Function JavaCode = FuncData
  func = G.func
  objAccess = G.objAccess

instance GetSet JavaCode where
  get = G.get
  set = G.set

instance List JavaCode where
  listSize = C.listSize
  listAdd = G.listAdd
  listAppend = G.listAppend
  listAccess = G.listAccess
  listSet = G.listSet
  indexOf = CP.indexOf jIndex

instance InternalList JavaCode where
  listSlice' = M.listSlice

instance Iterator JavaCode where
  iterBegin = G.iterBegin
  iterEnd = G.iterEnd

instance InternalGetSet JavaCode where
  getFunc = G.getFunc
  setFunc = G.setFunc

instance InternalListFunc JavaCode where
  listSizeFunc = CP.listSizeFunc
  listAddFunc _ = CP.listAddFunc jListAdd
  listAppendFunc = G.listAppendFunc jListAdd
  listAccessFunc = CP.listAccessFunc' jListAccess
  listSetFunc = jListSetFunc

instance InternalIterator JavaCode where
  iterBeginFunc _ = error $ CP.iterBeginError jName
  iterEndFunc _ = error $ CP.iterEndError jName

instance RenderFunction JavaCode where
  funcFromData d = onStateValue (onCodeValue (`fd` d))
  
instance FunctionElim JavaCode where
  functionType = onCodeValue fType
  function = funcDoc . unJC

instance InternalAssignStmt JavaCode where
  multiAssign _ _ = error $ C.multiAssignError jName

instance InternalIOStmt JavaCode where
  printSt _ _ = CP.printSt

instance InternalControlStmt JavaCode where
  multiReturn _ = error $ C.multiReturnError jName

instance RenderStatement JavaCode where
  stmt = G.stmt
  loopStmt = G.loopStmt

  emptyStmt = G.emptyStmt
  
  stmtFromData d t = toCode (d, t)

instance StatementElim JavaCode where
  statement = fst . unJC
  statementTerm = snd . unJC

instance StatementSym JavaCode where
  -- Terminator determines how statements end
  type Statement JavaCode = (Doc, Terminator)
  valStmt = G.valStmt Semi
  multi = onStateList (onCodeList R.multiStmt)

instance AssignStatement JavaCode where
  assign = G.assign Semi
  (&-=) = M.decrement
  (&+=) = G.increment
  (&++) = C.increment1
  (&--) = M.decrement1

instance DeclStatement JavaCode where
  varDec = C.varDec static dynamic
  varDecDef = C.varDecDef
  listDec n v = zoom lensMStoVS v >>= (\v' -> C.listDec (R.listDec v') 
    (litInt n) v)
  listDecDef = CP.listDecDef
  arrayDec n = CP.arrayDec (litInt n)
  arrayDecDef = CP.arrayDecDef
  objDecDef = varDecDef
  objDecNew = G.objDecNew
  extObjDecNew = C.extObjDecNew
  constDecDef = zoom lensMStoVS .: on2StateValues (mkStmt .: jConstDecDef)
  funcDecDef = CP.funcDecDef

instance IOStatement JavaCode where
  print      = jOut False Nothing printFunc
  printLn    = jOut True  Nothing printLnFunc
  printStr   = jOut False Nothing printFunc   . litString
  printStrLn = jOut True  Nothing printLnFunc . litString

  printFile f      = jOut False (Just f) (printFileFunc f)
  printFileLn f    = jOut True  (Just f) (printFileLnFunc f)
  printFileStr f   = jOut False (Just f) (printFileFunc f)   . litString
  printFileStrLn f = jOut True  (Just f) (printFileLnFunc f) . litString

  getInput v = v &= jInput v inputFunc
  discardInput = jDiscardInput inputFunc
  getFileInput f v = v &= jInput v f
  discardFileInput = jDiscardInput

  openFileR = CP.openFileR jOpenFileR
  openFileW = CP.openFileW jOpenFileWorA
  openFileA = CP.openFileA jOpenFileWorA
  closeFile = G.closeFile jClose

  getFileInputLine f v = v &= f $. jNextLineFunc
  discardFileLine = CP.discardFileLine jNextLine
  getFileInputAll f v = while (f $. jHasNextLineFunc)
    (oneLiner $ valStmt $ listAppend (valueOf v) (f $. jNextLineFunc))

instance StringStatement JavaCode where
  stringSplit d vnew s = do
    modify (addLangImport $ utilImport jArrays) 
    ss <- zoom lensMStoVS $ 
      jStringSplit vnew (jAsListFunc string [s $. jSplitFunc d])
    return $ mkStmt ss 

  stringListVals = M.stringListVals
  stringListLists = M.stringListLists

instance FuncAppStatement JavaCode where
  inOutCall = jInOutCall funcApp
  selfInOutCall = jInOutCall selfFuncApp
  extInOutCall m = jInOutCall (extFuncApp m)

instance CommentStatement JavaCode where
  comment = G.comment commentStart

instance ControlStatement JavaCode where
  break = toState $ mkStmt R.break
  continue = toState $ mkStmt R.continue

  returnStmt = G.returnStmt Semi
  
  throw = G.throw jThrowDoc Semi

  ifCond = G.ifCond bodyStart elseIfLabel bodyEnd
  switch  = C.switch

  ifExists = M.ifExists

  for = C.for bodyStart bodyEnd
  forRange = M.forRange 
  forEach = CP.forEach bodyStart bodyEnd forLabel colon
  while = C.while bodyStart bodyEnd

  tryCatch = G.tryCatch jTryCatch
  
instance StatePattern JavaCode where 
  checkState = M.checkState

instance ObserverPattern JavaCode where
  notifyObservers = M.notifyObservers

instance StrategyPattern JavaCode where
  runStrategy = M.runStrategy

instance ScopeSym JavaCode where
  type Scope JavaCode = Doc
  private = toCode R.private
  public = toCode R.public

instance RenderScope JavaCode where
  scopeFromData _ = toCode
  
instance ScopeElim JavaCode where
  scope = unJC

instance MethodTypeSym JavaCode where
  type MethodType JavaCode = TypeData
  mType = zoom lensMStoVS
  construct = G.construct

instance ParameterSym JavaCode where
  type Parameter JavaCode = ParamData
  param = G.param R.param
  pointerParam = param

instance RenderParam JavaCode where
  paramFromData v d = on2CodeValues pd v (toCode d)

instance ParamElim JavaCode where
  parameterName = variableName . onCodeValue paramVar
  parameterType = variableType . onCodeValue paramVar
  parameter = paramDoc . unJC

instance MethodSym JavaCode where
  type Method JavaCode = MethodData
  method = G.method
  getMethod = G.getMethod
  setMethod = G.setMethod
  constructor ps is b = getClassName >>= (\n -> G.constructor n ps is b)

  docMain = CP.docMain

  function = G.function
  mainFunction = CP.mainFunction string mainFunc

  docFunc = G.docFunc

  inOutMethod n = jInOut (method n)

  docInOutMethod n = jDocInOut (inOutMethod n)

  inOutFunc n = jInOut (function n)
    
  docInOutFunc n = jDocInOut (inOutFunc n)

instance RenderMethod JavaCode where
  intMethod m n s p t ps b = do
    tp <- t
    pms <- sequence ps
    bd <- b
    mem <- zoom lensMStoVS getMethodExcMap
    es <- getExceptions
    mn <- zoom lensMStoFS getModuleName
    let excs = map (unJC . toConcreteExc) $ maybe es (nub . (++ es)) 
          (Map.lookup (qualName mn n) mem)
    modify ((if m then setCurrMain else id) . addExceptionImports excs) 
    return $ toCode $ mthd $ jMethod n (map exc excs) s p tp pms bd
  intFunc = C.intFunc
  commentedFunc cmt m = on2StateValues (on2CodeValues updateMthd) m 
    (onStateValue (onCodeValue R.commentedItem) cmt)
    
  destructor _ = error $ CP.destructorError jName
  
instance MethodElim JavaCode where
  method = mthdDoc . unJC

instance StateVarSym JavaCode where
  type StateVar JavaCode = Doc
  stateVar = CP.stateVar
  stateVarDef _ = CP.stateVarDef
  constVar _ = CP.constVar (RC.perm (static :: JavaCode (Permanence JavaCode)))
  
instance StateVarElim JavaCode where
  stateVar = unJC

instance ClassSym JavaCode where
  type Class JavaCode = Doc
  buildClass = G.buildClass
  extraClass = jExtraClass
  implementingClass = G.implementingClass

  docClass = G.docClass

instance RenderClass JavaCode where
  intClass = CP.intClass R.class'
  
  inherit n = toCode $ maybe empty ((jExtends <+>) . text) n
  implements is = toCode $ jImplements <+> text (intercalate listSep is)

  commentedClass = G.commentedClass
  
instance ClassElim JavaCode where
  class' = unJC

instance ModuleSym JavaCode where
  type Module JavaCode = ModData
  buildModule n = CP.buildModule' n langImport
  
instance RenderMod JavaCode where
  modFromData n = G.modFromData n (toCode . md n)
  updateModuleDoc f = onCodeValue (updateMod f)
  
instance ModuleElim JavaCode where
  module' = modDoc . unJC

instance BlockCommentSym JavaCode where
  type BlockComment JavaCode = Doc
  blockComment lns = toCode $ R.blockCmt lns blockCmtStart blockCmtEnd
  docComment = onStateValue (\lns -> toCode $ R.docCmt lns docCmtStart 
    blockCmtEnd)

instance BlockCommentElim JavaCode where
  blockComment' = unJC

instance HasException JavaCode where
  toConcreteExc Standard = toCode $ stdExc exceptionObj
  toConcreteExc FileNotFound = toCode $ exception (javaImport io) jFNFExc
  toConcreteExc IO = toCode $ exception (javaImport io) jIOExc

odeImport :: String
odeImport = "org.apache.commons.math3.ode."

jODEMethod :: ODEOptions JavaCode -> MSStatement JavaCode
jODEMethod opts = modify (addLibImport (odeImport ++ "nonstiff." ++ it)) >> 
  varDecDef (jODEIntVar m) (newObj (obj it) (jODEParams m))
  where m = solveMethod opts
        it = jODEInt m
        jODEParams RK45 = [stepSize opts, stepSize opts, absTol opts, 
          relTol opts]
        jODEParams Adams = [litInt 3, stepSize opts, stepSize opts, absTol opts,
          relTol opts]
        jODEParams _ = error "Chosen ODE method unavailable in Java"

jODEIntVar :: ODEMethod -> SVariable JavaCode
jODEIntVar m = var "it" (obj $ jODEInt m)

jODEInt :: ODEMethod -> String
jODEInt RK45 = "DormandPrince54Integrator"
jODEInt Adams = "AdamsBashforthIntegrator"
jODEInt _ = error "Chosen ODE method unavailable in Java"

jODEFiles :: ODEInfo JavaCode -> ([FileData], GOOLState)
jODEFiles info = (map unJC fls, s ^. goolState)
  where (fls, s) = runState odeFiles initialFS
        fode = "FirstOrderDifferentialEquations"
        dv = depVar info
        ovars = otherVars info 
        odeFiles = join $ on1StateValue1List (\dpv ovs -> 
          let n = variableName dpv
              cn = n ++ "_ODE"
              dn = "d" ++ n 
              stH = "StepHandler"
              stI = "StepInterpolator"
              shn = n ++ "_" ++ stH
              ddv = var dn (arrayType float)
              y0 = var "y0" (arrayType float)
              interp = var "interpolator" (obj stI)
              othVars = map (modify (setODEOthVars (map variableName 
                ovs)) >>) ovars
              odeTempName = ((++ "_curr") . variableName)
              odeTemp = var (odeTempName dpv) (arrayType float)
          in sequence [fileDoc (buildModule cn [odeImport ++ fode] [] 
            [implementingClass cn [fode] (map privDVar othVars) 
              [initializer (map param othVars) (zip othVars 
                (map valueOf othVars)),
              pubMethod "getDimension" int [] (oneLiner $ returnStmt $ 
                litInt 1),
              pubMethod "computeDerivatives" void (map param [var "t" float, 
                var n (arrayType float), ddv]) (oneLiner $ arrayElem 0 ddv &= 
                (modify (setODEDepVars [variableName dpv, dn] . setODEOthVars 
                (map variableName ovs)) >> ode info))]]),
            fileDoc (buildModule shn (map ((odeImport ++ "sampling.") ++) 
              [stH, stI]) [] [implementingClass shn [stH] [pubDVar dv] 
                [pubMethod "init" void (map param [var "t0" float, y0, 
                  var "t" float]) (modify (addLangImport "java.util.Arrays") >> 
                    oneLiner (objVarSelf dv &= newObj (obj 
                    (getTypeString $ variableType dpv)) [funcApp "Arrays.asList"
                    (toState $ variableType dpv) [valueOf $ arrayElem 0 y0]])),
                pubMethod "handleStep" void (map param [interp, var "isLast" 
                  (toState $ typeFromData Boolean "boolean" (text "boolean"))]) 
                  (bodyStatements [
                    varDecDef odeTemp (objMethodCallNoParams (arrayType float) 
                      (valueOf interp) "getInterpolatedState"),
                    valStmt $ listAppend (valueOf $ objVarSelf dv) (valueOf 
                      (arrayElem 0 odeTemp))])]])]) 
          (zoom lensFStoVS dv) (map (zoom lensFStoVS) ovars)

jName :: String
jName = "Java"

jImport :: Label -> Doc
jImport n = text ("import " ++ n) <> endStatement

jStringType :: (RenderSym r) => VSType r
jStringType = toState $ typeFromData String jString (text jString)

jInfileType :: (RenderSym r) => VSType r
jInfileType = modifyReturn (addLangImportVS $ utilImport jScanner) $ 
  typeFromData File jScanner jScanner'

jOutfileType :: (RenderSym r) => VSType r
jOutfileType = modifyReturn (addLangImportVS $ ioImport jPrintWriter) $ 
  typeFromData File jPrintWriter (text jPrintWriter)

jExtends, jImplements, jFinal, jScanner', jThrows, jLambdaSep :: Doc
jExtends = text "extends"
jImplements = text "implements"
jFinal = text "final"
jScanner' = text jScanner
jThrows = text "throws"
jLambdaSep = text "->"

arrayList, jInteger, jFloat, jDouble, jString, jObject, jScanner, jPrintWriter, 
  jFile, jFileWriter, jIOExc, jFNFExc, jArrays, jAsList, jStdIn, jStdOut, 
  jPrint, jPrintLn, jEquals, jParseInt, jParseDbl, jParseFloat, jIndex, 
  jListAdd, jListAccess, jListSet, jClose, jNext, jNextLine, jNextBool, 
  jHasNextLine, jCharAt, jSplit, io, util :: String
arrayList = "ArrayList"
jInteger = "Integer"
jFloat = "Float"
jDouble = "Double"
jString = "String"
jObject = "Object"
jScanner = "Scanner"
jPrintWriter = "PrintWriter"
jFile = "File"
jFileWriter = "FileWriter"
jIOExc = "IOException"
jFNFExc = "FileNotFoundException"
jArrays = "Arrays"
jAsList = jArrays `access` "asList"
jStdIn = "in"
jStdOut = "out"
jPrint = "print"
jPrintLn = "println"
jEquals = "equals"
jParseInt = jInteger `access` "parseInt"
jParseDbl = jDouble `access` "parseDouble"
jParseFloat = jFloat `access` "parseFloat"
jIndex = "indexOf"
jListAdd = "add"
jListAccess = "get"
jListSet = "set"
jClose = "close"
jNext = "next"
jNextLine = "nextLine"
jNextBool = "nextBoolean"
jHasNextLine = "hasNextLine"
jCharAt = "charAt"
jSplit = "split"
io = "io"
util = "util"

javaImport, ioImport, utilImport :: String -> String
javaImport = access "java"
ioImport = javaImport . access io
utilImport = javaImport . access util

jSystem :: String -> Doc
jSystem = text . access "System"

jUnaryMath :: (Monad r) => String -> VSOp r
jUnaryMath = unOpPrec . mathFunc

jListType :: (RenderSym r) => VSType r -> VSType r
jListType t = do
  modify (addLangImportVS $ utilImport arrayList) 
  t >>= (jListType' . getType)
  where jListType' Integer = toState $ typeFromData (List Integer) 
          lstInt (text lstInt)
        jListType' Float = toState $ typeFromData (List Float) 
          lstFloat (text lstFloat)
        jListType' Double = toState $ typeFromData (List Double) 
          lstDouble (text lstDouble)
        jListType' _ = C.listType arrayList t
        lstInt = arrayList `containing` jInteger
        lstFloat = arrayList `containing` jFloat
        lstDouble = arrayList `containing` jDouble

jArrayType :: VSType JavaCode
jArrayType = arrayType (obj jObject)

jFileType :: (RenderSym r) => VSType r
jFileType = modifyReturn (addLangImportVS $ ioImport jFile) $ typeFromData File 
  jFile (text jFile)

jFileWriterType :: (RenderSym r) => VSType r
jFileWriterType = modifyReturn (addLangImportVS $ ioImport jFileWriter) $ 
  typeFromData File jFileWriter (text jFileWriter)

jAsListFunc :: VSType JavaCode -> [SValue JavaCode] -> SValue JavaCode
jAsListFunc t = funcApp jAsList (listType t)

jEqualsFunc :: SValue JavaCode -> VSFunction JavaCode
jEqualsFunc v = func jEquals bool [v]

jParseIntFunc :: SValue JavaCode -> SValue JavaCode
jParseIntFunc v = funcApp jParseInt int [v]

jParseDblFunc :: SValue JavaCode -> SValue JavaCode
jParseDblFunc v = funcApp jParseDbl double [v]

jParseFloatFunc :: SValue JavaCode -> SValue JavaCode
jParseFloatFunc v = funcApp jParseFloat float [v]

jListSetFunc :: SValue JavaCode -> SValue JavaCode -> SValue JavaCode ->
  VSFunction JavaCode
jListSetFunc v i toVal = func jListSet (onStateValue valueType v) [intValue i, toVal]

jNextFunc :: VSFunction JavaCode
jNextFunc = func jNext string []

jNextLineFunc :: VSFunction JavaCode
jNextLineFunc = func jNextLine string []

jNextBoolFunc :: VSFunction JavaCode
jNextBoolFunc = func jNextBool bool []

jHasNextLineFunc :: VSFunction JavaCode
jHasNextLineFunc = func jHasNextLine bool []

jCharAtFunc :: VSFunction JavaCode
jCharAtFunc = func jCharAt char [litInt 0]

jSplitFunc :: (RenderSym r) => Char -> VSFunction r
jSplitFunc d = func jSplit (listType string) [litString [d]]

jEquality :: SValue JavaCode -> SValue JavaCode -> SValue JavaCode
jEquality v1 v2 = v2 >>= jEquality' . getType . valueType
  where jEquality' String = objAccess v1 (jEqualsFunc v2)
        jEquality' _ = typeBinExpr equalOp bool v1 v2

jLambda :: (RenderSym r) => [r (Variable r)] -> r (Value r) -> Doc
jLambda ps ex = parens (variableList ps) <+> jLambdaSep <+> RC.value ex

jCast :: VSType JavaCode -> SValue JavaCode -> SValue JavaCode
jCast = join .: on2StateValues (\t v -> jCast' (getType t) (getType $ valueType 
  v) t v)
  where jCast' Double String _ v = jParseDblFunc (toState v)
        jCast' Float String _ v = jParseFloatFunc (toState v)
        jCast' _ _ t v = mkStateVal (toState t) (R.castObj (R.cast (RC.type' t))
          (RC.value v))

jConstDecDef :: (RenderSym r) => r (Variable r) -> r (Value r) -> Doc
jConstDecDef v def = jFinal <+> RC.type' (variableType v) <+> 
  RC.variable v <+> equals <+> RC.value def

jThrowDoc :: (RenderSym r) => r (Value r) -> Doc
jThrowDoc errMsg = throwLabel <+> new' <+> exceptionObj' <> 
  parens (RC.value errMsg)

jTryCatch :: (RenderSym r) => r (Body r) -> r (Body r) -> Doc
jTryCatch tb cb = vcat [
  tryLabel <+> lbrace,
  indent $ RC.body tb,
  rbrace <+> catchLabel <+> parens (exceptionObj' <+> text "exc") <+> 
    lbrace,
  indent $ RC.body cb,
  rbrace]

jOut :: (RenderSym r) => Bool -> Maybe (SValue r) -> SValue r -> SValue r -> 
  MSStatement r
jOut newLn f printFn v = zoom lensMStoVS v >>= jOut' . getType . valueType
  where jOut' (List (Object _)) = G.print newLn f printFn v
        jOut' (List _) = printSt newLn f printFn v
        jOut' _ = G.print newLn f printFn v

jDiscardInput :: SValue JavaCode -> MSStatement JavaCode
jDiscardInput inFn = valStmt $ inFn $. jNextFunc

jInput :: SVariable JavaCode -> SValue JavaCode -> SValue JavaCode
jInput vr inFn = do
  v <- vr
  let jInput' Integer = jParseIntFunc $ inFn $. jNextLineFunc
      jInput' Float = jParseFloatFunc $ inFn $. jNextLineFunc
      jInput' Double = jParseDblFunc $ inFn $. jNextLineFunc
      jInput' Boolean = inFn $. jNextBoolFunc
      jInput' String = inFn $. jNextLineFunc
      jInput' Char = (inFn $. jNextFunc) $. jCharAtFunc
      jInput' _ = error "Attempt to read value of unreadable type"
  jInput' (getType $ variableType v)

jOpenFileR :: (RenderSym r) => SValue r -> VSType r -> SValue r
jOpenFileR n t = newObj t [newObj jFileType [n]]

jOpenFileWorA :: (RenderSym r) => SValue r -> VSType r -> SValue r -> SValue r
jOpenFileWorA n t wa = newObj t [newObj jFileWriterType [newObj jFileType [n], 
  wa]]

jStringSplit :: (RenderSym r) => SVariable r -> SValue r -> VS Doc
jStringSplit = on2StateValues (\vnew s -> RC.variable vnew <+> equals <+> 
  new' <+> RC.type' (variableType vnew) <> parens (RC.value s))

jMethod :: (RenderSym r) => Label -> [String] -> r (Scope r) -> r (Permanence r)
  -> r (Type r) -> [r (Parameter r)] -> r (Body r) -> Doc
jMethod n es s p t ps b = vcat [
  RC.scope s <+> RC.perm p <+> RC.type' t <+> text n <> 
    parens (parameterList ps) <+> emptyIfNull es (jThrows <+> 
    text (intercalate listSep (sort es))) <+> lbrace,
  indent $ RC.body b,
  rbrace]

outputs :: SVariable JavaCode
outputs = var "outputs" jArrayType

jAssignFromArray :: Integer -> [SVariable JavaCode] -> [MSStatement JavaCode]
jAssignFromArray _ [] = []
jAssignFromArray c (v:vs) = (v &= cast (onStateValue variableType v)
  (valueOf $ arrayElem c outputs)) : jAssignFromArray (c+1) vs

jInOutCall :: (Label -> VSType JavaCode -> [SValue JavaCode] -> 
  SValue JavaCode) -> Label -> [SValue JavaCode] -> [SVariable JavaCode] -> 
  [SVariable JavaCode] -> MSStatement JavaCode
jInOutCall f n ins [] [] = valStmt $ f n void ins
jInOutCall f n ins [out] [] = assign out $ f n (onStateValue variableType out) 
  ins
jInOutCall f n ins [] [out] = assign out $ f n (onStateValue variableType out) 
  (valueOf out : ins)
jInOutCall f n ins outs both = fCall rets
  where rets = both ++ outs
        fCall [x] = assign x $ f n (onStateValue variableType x) 
          (map valueOf both ++ ins)
        fCall xs = isOutputsDeclared >>= (\odec -> modify setOutputsDeclared >>
          multi ((if odec then assign else varDecDef) outputs 
          (f n jArrayType (map valueOf both ++ ins)) : jAssignFromArray 0 xs))

jInOut :: (JavaCode (Scope JavaCode) -> JavaCode (Permanence JavaCode) -> 
    VSType JavaCode -> [MSParameter JavaCode] -> MSBody JavaCode -> 
    SMethod JavaCode) 
  -> JavaCode (Scope JavaCode) -> JavaCode (Permanence JavaCode) -> 
  [SVariable JavaCode] -> [SVariable JavaCode] -> [SVariable JavaCode] -> 
  MSBody JavaCode -> SMethod JavaCode
jInOut f s p ins [] [] b = f s p void (map param ins) b
jInOut f s p ins [v] [] b = f s p (onStateValue variableType v) (map param ins) 
  (on3StateValues (on3CodeValues surroundBody) (varDec v) b (returnStmt $ 
  valueOf v))
jInOut f s p ins [] [v] b = f s p (onStateValue variableType v) 
  (map param $ v : ins) (on2StateValues (on2CodeValues appendToBody) b 
  (returnStmt $ valueOf v))
jInOut f s p ins outs both b = f s p (returnTp rets)
  (map param $ both ++ ins) (on3StateValues (on3CodeValues surroundBody) decls 
  b (returnSt rets))
  where returnTp [x] = onStateValue variableType x
        returnTp _ = jArrayType
        returnSt [x] = returnStmt $ valueOf x
        returnSt _ = multi (arrayDec (toInteger $ length rets) outputs
          : assignArray 0 (map valueOf rets)
          ++ [returnStmt (valueOf outputs)])
        assignArray :: Integer -> [SValue JavaCode] -> [MSStatement JavaCode]
        assignArray _ [] = []
        assignArray c (v:vs) = (arrayElem c outputs &= v) : assignArray (c+1) vs
        decls = multi $ map varDec outs
        rets = both ++ outs

jDocInOut :: (RenderSym r) => (r (Scope r) -> r (Permanence r) -> [SVariable r] 
    -> [SVariable r] -> [SVariable r] -> MSBody r -> SMethod r)
  -> r (Scope r) -> r (Permanence r) -> String -> [(String, SVariable r)] -> 
  [(String, SVariable r)] -> [(String, SVariable r)] -> MSBody r -> SMethod r
jDocInOut f s p desc is [] [] b = docFuncRepr desc (map fst is) [] 
  (f s p (map snd is) [] [] b)
jDocInOut f s p desc is [o] [] b = docFuncRepr desc (map fst is) [fst o] 
  (f s p (map snd is) [snd o] [] b)
jDocInOut f s p desc is [] [both] b = docFuncRepr desc (map fst (both : is)) 
  [fst both] (f s p (map snd is) [] [snd both] b)
jDocInOut f s p desc is os bs b = docFuncRepr desc (map fst $ bs ++ is) 
  rets (f s p (map snd is) (map snd os) (map snd bs) b)
  where rets = "array containing the following values:" : map fst bs ++ 
          map fst os

jExtraClass :: (RenderSym r) => Label -> Maybe Label -> [CSStateVar r] -> 
  [SMethod r] -> SClass r
jExtraClass n = intClass n (scopeFromData Priv empty) . inherit

addCallExcsCurrMod :: String -> VS ()
addCallExcsCurrMod n = do
  cm <- zoom lensVStoFS getModuleName
  mem <- getMethodExcMap
  modify (maybe id addExceptions (Map.lookup (qualName cm n) mem))

addConstructorCallExcsCurrMod :: (RenderSym r) => VSType r -> 
  (VSType r -> SValue r) -> SValue r
addConstructorCallExcsCurrMod ot f = do
  t <- ot
  cm <- zoom lensVStoFS getModuleName
  mem <- getMethodExcMap
  let tp = getTypeString t
  modify (maybe id addExceptions (Map.lookup (qualName cm tp) mem))
  f (return t)