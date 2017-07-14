-- | Defines an abstract language for writing code to be generated by GOOL
module Language.Drasil.Code.Imperative.AST (
    -- * AbstractCode
    Label,
    -- ** Statement Structure
    Body, Block(..),
    Statement(..), IOSt(..), IOType(..), Complex(..),
    Pattern(..), StatePattern(..), StratPattern(..), Strategies(..), ObserverPattern(..),
    Assignment(..), Declaration(..), Conditional(..),
    Iteration(..), Exception(..), Jump(..), Return(..), Value(..), Comment(..),
    Literal(..), Function(..),
    Expression(..), UnaryOp(..), BinaryOp(..),
    -- ** Overall AbstractCode Structure
    BaseType(..), Mode(..), StateType(..), Permanence(..), MethodType(..),
    Scope(..), Parameter(..), StateVar(..), Method(..), Enum(..), Class(..), 
    VarDecl, FunctionDecl, Library, Module(..), Package(..),
    AbstractCode(..),

    -- * Convenience functions
    bool,int,float,char,string,infile,outfile,listT,obj,
    methodType,methodTypeVoid,
    block,defaultValue,defaultValue',
    true,false,
    var, arg, self, svToVar,
    pubClass,privClass,privMVar,pubMVar,pubGVar,privMethod,pubMethod,constructor,
    mainMethod,
    (?!),(?<),(?<=),(?>),(?>=),(?==),(?!=),(?&&),(?||),
    (#~),(#/^),(#|),(#+),(#-),(#*),(#/),(#%),(#^),
    (&=),(&.=),(&=.),(&+=),(&-=),(&++),(&~-),(&.+=),(&.-=),(&.++),(&.~-),
    ($->),($.),($:),
    log,exp,alwaysDel,neverDel,
    assign,at,binExpr,break,cast,cast',constDecDef,extends,for,forEach,ifCond,ifExists,listDec,listDecValues,listDec',
    listOf,litBool,litChar,litFloat,litInt,litObj,litObj',litString,noElse,noParent,objDecDef,oneLiner,
    param,params,paramToVar,
    print,printLn,printStr,printStrLn,
    printFile,printFileLn,printFileStr,printFileStrLn,
    print',printLn',printStr',printStrLn',
    getInput,getFileInput,getFileInputAll,getFileInputLine,
    openFileR, openFileW, closeFile,
    return,returnVar,switch,throw,tryCatch,typ,varDec,varDecDef,while,zipBlockWith,zipBlockWith4,
    addComments,comment,commentDelimit,endCommentDelimit,prefixFirstBlock,
    getterName,setterName,convertToClass,convertToMethod,bodyReplace,funcReplace,valListReplace,
    objDecNew,objDecNewVoid,objDecNew',objDecNewVoid',objMethodCall, objMethodCallVoid, 
    listSize, listAccess, listAppend, listSlice, stringSplit,
    valStmt,funcApp,funcApp',func,continue,
    toAbsCode, getClassName, buildModule, moduleName, libs, classes, functions, ignoreMain, notMainModule, multi,
    convToClass
) where

import Data.List (zipWith4, find)
import Prelude hiding (break,print,return,log,exp)

import Language.Drasil.Code.Imperative.Helpers (capitalize)

-- Language datatype definitions
type Label = String
type Library = Label

type Body = [Block]
data Block = Block [Statement] deriving Show
data Statement = AssignState Assignment | DeclState Declaration
               | CondState Conditional | IterState Iteration | JumpState Jump
               | RetState Return
               | ValState Value
               | CommentState Comment
               | FreeState Value
               | ExceptState Exception
               | PatternState Pattern           --deals with special design patterns
               | IOState IOSt
               | ComplexState Complex
               | MultiState [Statement]
                  deriving Show
data IOSt = OpenFile Value Value Mode
          | CloseFile Value
          | Out IOType Bool StateType Value
          | In IOType StateType Value
          deriving Show
data Mode = Read
          | Write
          deriving (Eq, Show)
data IOType = Console
            | File Value
            deriving Show
data Pattern = State StatePattern
             | Strategy StratPattern
             | Observer ObserverPattern
                deriving Show
data StatePattern = InitState {fsmName :: Label, initialState :: Label}
                  | ChangeState {fsmName :: Label, toState :: Label}
                  | CheckState {fsmName :: Label, cases :: [(Label,Body)], defaultBody :: Body}     --basically a Switch statement on the current state of the FSM.
                     deriving Show
data StratPattern = RunStrategy {stratName :: Label, strategies :: Strategies, assignResultTo :: Maybe Value} deriving Show
data Strategies = Strats {strats :: [(Label, Body)], returnVal :: Maybe Value} deriving Show

--currently can only have one observer list within a given scope. 
-- Observers must be defined within this scope and must all be of type observerType.
data ObserverPattern = InitObserverList {observerType :: StateType, observers :: [Value]}   
                     | AddObserver {observerType :: StateType, observer :: Value}
                     | NotifyObservers {observerType :: StateType, receiveFunc :: Label, notifyParams :: [Value]} deriving Show
                     
data Complex = ReadLine Value Value -- ReadLine File StringVar
             | ReadAll Value Value  -- ReadAll File String[]Var
             | ListSlice StateType Value Value (Maybe Value) (Maybe Value) (Maybe Value)  -- new list var, old list var, start, stop, step
             | StringSplit Value Value Char -- new string, old string, delimiter
                 deriving Show
data Assignment = Assign Value Value
                | PlusEquals Value Value
                | PlusPlus Value deriving Show
data Declaration = VarDec Label StateType
                 | ListDec Permanence Label StateType Int
                 | ListDecValues Permanence Label StateType [Value]
                 | VarDecDef Label StateType Value
                 | ObjDecDef Label StateType Value
                 | ConstDecDef Label Literal        --the Type of the Const will be inferred by the type of Literal provided
                    deriving Show
data Conditional = If [(Value, Body)] Body             --If [(guard, result)] elseBody
                 | Switch Value [(Literal, Body)] Body      --Switch expression cases defaultBody
                    deriving Show
data Iteration = For {initState :: Statement, guard :: Value, update :: Statement, forBody :: Body}
               | ForEach Label Value Body
               | While Value Body               --While guard body
                  deriving Show
data Exception = Throw {excMsg :: String}
               | TryCatch {tryBody :: Body, catchBody :: Body}    
                 deriving Show
--This is only guaranteed to catch Exceptions explicitly thrown in the AbstractCode (i.e. with a Throw String), but in some languages might also catch errors thrown at different levels (e.g. index out of bounds).
data Jump = Break | Continue deriving Show
data Return = Ret Value deriving Show
data Value = EnumElement Label Label    --EnumElement enumName elementName
           | Expr Expression
           | FuncApp (Maybe Library) Label [Value]
           | Lit Literal
           | ObjAccess Value Function
           | StateObj (Maybe Library) StateType [Value]
           | Self
           | Var Label
           | EnumVar Label
           | ObjVar Value Value
           | ListVar Label StateType
           | Const Label
           | Global Label -- these are generation-time globals that will be filled-in
           | Arg Int                    --Arg argIndex : get command-line arguments. 
    deriving (Eq, Show)
data Literal = LitBool Bool
             | LitInt Integer
             | LitFloat Double
             | LitChar Char
             | LitStr String
    deriving (Eq, Show)
data Function = Func {funcName :: Label, funcParams :: [Value]}
              -- added sourceType to cast for now -- type checking in GOOL would be nice!
              | Cast StateType StateType      --Cast targetType sourceType : typecast
              | Get Label
              | Set Label Value
              | IndexOf Value
              | ListSize
              | ListAccess Value
              | ListAdd Value Value     --ListAdd index value
              | ListSet Value Value     --ListSet index value
              | ListPopulate Value StateType --ListPopulate size type : populates the list with a default value for its type. Ignored in languages where it's unnecessary in order to use the ListSet function.  
              | ListAppend Value
              | IterBegin | IterEnd
              | Floor | Ceiling            
    deriving (Eq, Show)
data Comment = Comment Label | CommentDelimit Label Int
    deriving (Eq, Show)
data Expression = UnaryExpr UnaryOp Value
                | BinaryExpr Value BinaryOp Value
                | Exists Value      --used to check whether the specified variable/list element/etc. is null
    deriving (Eq, Show)
data UnaryOp = Negate | SquareRoot | Abs
             | Not | Log | Exp
    deriving (Eq, Show)
data BinaryOp = Equal | NotEqual | Greater | GreaterEqual | Less | LessEqual
              | Plus | Minus | Multiply | Divide | Power | Modulo
              | And | Or
    deriving (Eq, Show)
data BaseType = Boolean | Integer | Float | Character | String | FileType Mode
    deriving (Eq, Show)
data StateType = List Permanence StateType | Base BaseType | Type Label | Iterator StateType | EnumType Label
    deriving (Eq, Show)
data Permanence = Static | Dynamic
    deriving (Eq, Show)
data MethodType = MState StateType
                | Void
                | Construct Label
data Scope = Private | Public
    deriving (Eq, Show)
data Parameter = StateParam Label StateType
               | FuncParam Label MethodType [Parameter]
-- | Int parameter for StateVar is a measure of "delete priority" (for languages with explicit destructors).
-- 0=never delete, 4=always, 1-3=language-defined.
-- This allows the programmer to specify a different set of variables to delete explicitly for different languages.
data StateVar = StateVar Label Scope Permanence StateType Int
data Method = Method Label Scope Permanence MethodType [Parameter] Body
            | GetMethod Label MethodType
            | SetMethod Label Parameter
            | MainMethod Body
data Class = Enum {
               className :: Label,
               classScope :: Scope,
               enumElements :: [Label]}
            | Class {
               className :: Label,
               parentName :: Maybe Label,       --name of the class to inherit from. 'Nothing' if this class does not inherit.
               classScope :: Scope,
               classVars :: [StateVar],
               classMethods :: [Method]}
            | MainClass {
               className :: Label,
               classVars :: [StateVar],
               classMethods :: [Method]}
type FunctionDecl = Method
type VarDecl = Declaration
data Module = Mod Label [Library] [VarDecl] [FunctionDecl] [Class]
data Package = Pack Label [Module]
data AbstractCode = AbsCode Package

---------------------------
-- Convenience Functions --
---------------------------
bool, int, float, char, string, infile, outfile :: StateType
bool = Base Boolean
int = Base Integer
float = Base Float
char = Base Character
string = Base String
infile = Base $ FileType Read
outfile = Base $ FileType Write

listT :: StateType -> StateType
listT t = List Dynamic t

obj :: Label -> StateType
obj = Type

methodType :: StateType -> MethodType
methodType t = MState t

methodTypeVoid :: MethodType
methodTypeVoid = Void

block :: [Statement] -> Block
block = Block

defaultValue :: BaseType -> Value
defaultValue (Boolean) = false
defaultValue (Integer) = litInt 0
defaultValue (Float) = litFloat 0.0
defaultValue (Character) = litChar ' '
defaultValue (String) = litString ""
defaultValue (FileType _) = error $
  "defaultValue undefined for (File _) pattern. See " ++
  "Language.Drasil.Code.Imperative.AST"
  
defaultValue' :: StateType -> Value
defaultValue' (Base b) = defaultValue b
defaultValue' _ = error "defaultValue' undefined for type"

true :: Value
true = Lit $ LitBool True

false :: Value
false = Lit $ LitBool False

var :: Label -> Value
var = Var

arg :: Int -> Value
arg = Arg 

self :: Value
self = Self

svToVar :: StateVar -> Value
svToVar (StateVar n _ _ _ _) = Self $-> Var n

pubClass :: Label -> Maybe Label -> [StateVar] -> [Method] -> Class
pubClass n p vs fs = Class n p Public vs fs

privClass :: Label -> Maybe Label -> [StateVar] -> [Method] -> Class
privClass n p vs fs = Class n p Private vs fs

privMVar :: Int -> StateType -> Label -> StateVar
privMVar del t n = StateVar n Private Dynamic t del

pubMVar :: Int -> StateType -> Label -> StateVar
pubMVar del t n = StateVar n Public Dynamic t del

pubGVar :: Int -> StateType -> Label -> StateVar
pubGVar del t n = StateVar n Public Static t del

privMethod :: MethodType -> Label -> [Parameter] -> Body -> Method
privMethod t n ps b = Method n Private Dynamic t ps b

pubMethod :: MethodType -> Label -> [Parameter] -> Body -> Method
pubMethod t n ps b = Method n Public Dynamic t ps b

constructor :: Label -> [Parameter] -> Body -> Method
constructor n ps b = Method n Public Dynamic (Construct n) ps b

mainMethod :: Body -> Method
mainMethod = MainMethod

--comparison operators (?)
(?!) :: Value -> Value  --logical Not
infixr 6 ?!
(?!) v = unExpr Not v

(?<) :: Value -> Value -> Value
infixl 4 ?<
v1 ?< v2 = binExpr v1 Less v2

(?<=) :: Value -> Value -> Value
infixl 4 ?<=
v1 ?<= v2 = binExpr v1 LessEqual v2

(?>) :: Value -> Value -> Value
infixl 4 ?>
v1 ?> v2 = binExpr v1 Greater v2

(?>=) :: Value -> Value -> Value
infixl 4 ?>=
v1 ?>= v2 = binExpr v1 GreaterEqual v2

(?==) :: Value -> Value -> Value
infixl 3 ?==
v1 ?== v2 = binExpr v1 Equal v2

(?!=) :: Value -> Value -> Value
infixl 3 ?!=
v1 ?!= v2 = binExpr v1 NotEqual v2

(?&&) :: Value -> Value -> Value
infixl 2 ?&&
v1 ?&& v2 = binExpr v1 And v2

(?||) :: Value -> Value -> Value
infixl 1 ?||
v1 ?|| v2 = binExpr v1 Or v2

--arithmetic operators (#)
(#~) :: Value -> Value  --unary negation
infixl 8 #~
(#~) v = unExpr Negate v

(#/^) :: Value -> Value     --square root
infixl 7 #/^
(#/^) v = unExpr SquareRoot v

(#|) :: Value -> Value      --absolute value
infixl 7 #|
(#|) v = unExpr Abs v

(#+) :: Value -> Value -> Value
infixl 5 #+
v1 #+ v2 = binExpr v1 Plus v2

(#-) :: Value -> Value -> Value
infixl 5 #-
v1 #- v2 = binExpr v1 Minus v2

(#*) :: Value -> Value -> Value
infixl 6 #*
v1 #* v2 = binExpr v1 Multiply v2

(#/) :: Value -> Value -> Value
infixl 6 #/
v1 #/ v2 = binExpr v1 Divide v2

(#%) :: Value -> Value -> Value
infixl 6 #%
v1 #% v2 = binExpr v1 Modulo v2

(#^) :: Value -> Value -> Value  --exponentiation
infixl 7 #^
v1 #^ v2 = binExpr v1 Power v2

--assignment operators (&)
(&=) :: Value -> Value -> Statement
infixr 1 &=
a &= b = assign a b

(&.=) :: Label -> Value -> Statement
infixr 1 &.=
a &.= b = assign (Var a) b

(&=.) :: Value -> Label -> Statement
infixr 1 &=.
a &=. b = assign a (Var b)

(&-=) :: Value -> Value -> Statement
infixl 1 &-=
n &-= v = (n &= (n #- v))

(&.-=) :: Label -> Value -> Statement
infixl 1 &.-=
n &.-= v = (n &.= (Var n #- v))

(&+=) :: Value -> Value -> Statement
infixl 1 &+=
n &+= v = AssignState $ PlusEquals n v

(&.+=) :: Label -> Value -> Statement
infixl 1 &.+=
n &.+= v = AssignState $ PlusEquals (Var n) v

(&++) :: Value -> Statement
infixl 8 &++
(&++) v = AssignState $ PlusPlus v

(&.++) :: Label -> Statement
infixl 8 &.++
(&.++) l = AssignState $ PlusPlus (Var l)

(&~-) :: Value -> Statement        --can't use &-- as the operator for this since -- is the comment symbol in Haskell
infixl 8 &~-
(&~-) v = (v &-= litInt 1)

(&.~-) :: Label -> Statement
infixl 8 &.~-
(&.~-) l = (l &.-= litInt 1)

--other operators ($)
($->) :: Value -> Value -> Value
infixl 9 $->
v $-> vr = ObjVar v vr

($.) :: Value -> Function -> Value
infixl 9 $.
v $. f = ObjAccess v f

($:) :: Label -> Label -> Value
infixl 9 $:
n $: e = EnumElement n e

log :: Value -> Value
log = unExpr Log

exp :: Value -> Value
exp = unExpr Exp

alwaysDel :: Int
alwaysDel = 4

neverDel :: Int
neverDel = 0

assign :: Value -> Value -> Statement
assign a b = AssignState $ Assign a b

at :: Label -> Function
at = ListAccess . Var

binExpr :: Value -> BinaryOp -> Value -> Value
binExpr v1 op v2 = Expr $ BinaryExpr v1 op v2

break :: Statement
break = JumpState Break

cast :: StateType -> StateType -> Function
cast = Cast

cast' :: BaseType -> BaseType -> Function
cast' t s = Cast (Base t) (Base s)

constDecDef :: Label -> Literal -> Statement
constDecDef n l = DeclState $ ConstDecDef n l

extends :: Label -> Maybe Label
extends = Just

for :: Statement -> Value -> Statement -> Body -> Statement
for initv cond upd b = IterState $ For initv cond upd b

forEach :: Label -> Value -> Body -> Statement
forEach x xs b = IterState $ ForEach x xs b

ifCond :: [(Value, Body)] -> Body -> Statement
ifCond ifResults elseResult = CondState $ If ifResults elseResult

ifExists :: Value -> Body -> Body -> Statement
ifExists v ifBody elseBody = ifCond [(Expr $ Exists v, ifBody)] elseBody

listDec :: Permanence -> Label -> StateType -> Int -> Statement
listDec lt n t s = DeclState $ ListDec lt n t s

listDec' :: Label -> StateType -> Int -> Statement
listDec' n t s = DeclState $ ListDec Dynamic n t s

listDecValues :: Label -> StateType -> [Value] -> Statement
listDecValues n t vs = DeclState $ ListDecValues Static n t vs

listOf :: Label -> StateType -> Value
l `listOf` s = ListVar l s

litBool :: Bool -> Value
litBool = Lit . LitBool

litChar :: Char -> Value
litChar = Lit . LitChar

litFloat :: Double -> Value
litFloat = Lit . LitFloat

litInt :: Integer -> Value
litInt = Lit . LitInt

litObj :: Library -> StateType -> [Value] -> Value
litObj l t vs = StateObj (Just l) t vs

litObj' :: StateType -> [Value] -> Value
litObj' t vs = StateObj Nothing t vs

litString :: Label -> Value
litString = Lit . LitStr

noElse :: Body
noElse = []

noParent :: Maybe a
noParent = Nothing

objDecDef :: Label -> StateType -> Value -> Statement
objDecDef n t v = DeclState $ ObjDecDef n t v

objDecNew :: Label -> Library -> StateType -> [Value] -> Statement
objDecNew n l t vs = DeclState $ ObjDecDef n t (StateObj (Just l) t vs)

objDecNew' :: Label -> StateType -> [Value] -> Statement
objDecNew' n t vs = DeclState $ ObjDecDef n t (StateObj Nothing t vs)

-- declare new object with parameter-less constructor
objDecNewVoid :: Label -> Library -> StateType -> Statement
objDecNewVoid n l t = objDecNew n l t []

objDecNewVoid' :: Label -> StateType -> Statement
objDecNewVoid' n t = objDecNew' n t []

listSize :: Function
listSize = ListSize

listAccess :: Value -> Function
listAccess = ListAccess

listAppend :: Value -> Function
listAppend = ListAppend

listSlice :: StateType -> Value -> Value -> (Maybe Value) -> (Maybe Value) -> (Maybe Value) -> Statement
listSlice st v1 v2 b e s = ComplexState $ ListSlice st v1 v2 b e s

stringSplit :: Value -> Value -> Char -> Statement
stringSplit v1 v2 d = ComplexState $ StringSplit v1 v2 d

oneLiner :: Statement -> Body
oneLiner s = [Block [s]]

param :: Label -> StateType -> Parameter
param = StateParam

params :: [(Label, StateType)] -> [Parameter]
params = map (\(l,st) -> StateParam l st)

paramToVar :: Parameter -> Value
paramToVar (StateParam l _) = Var l
paramToVar (FuncParam l _ _) = Var l

print :: StateType -> Value -> Statement
print s v = IOState $ Out Console False s v

printLn :: StateType -> Value -> Statement
printLn s v = IOState $ Out Console True s v

printStr :: String -> Statement
printStr s = IOState $ Out Console False string (litString s)

printStrLn :: String -> Statement
printStrLn s = IOState $ Out Console True string (litString s)

printFile :: Value -> StateType -> Value -> Statement
printFile f s v = IOState $ Out (File f) False s v

printFileLn :: Value -> StateType -> Value -> Statement
printFileLn f s v = IOState $ Out (File f) True s v

printFileStr :: Value -> String -> Statement
printFileStr f s = IOState $ Out (File f) False string (litString s)

printFileStrLn :: Value -> String -> Statement
printFileStrLn f s = IOState $ Out (File f) True string (litString s)

print' :: IOType -> StateType -> Value -> Statement
print' Console = print
print' (File f) = printFile f

printLn' :: IOType -> StateType -> Value -> Statement
printLn' Console = printLn
printLn' (File f) = printFileLn f

printStr' :: IOType -> String -> Statement
printStr' Console = printStr
printStr' (File f) = printFileStr f

printStrLn' :: IOType -> String -> Statement
printStrLn' Console = printStrLn
printStrLn' (File f) = printFileStrLn f

getInput :: StateType -> Value -> Statement
getInput s v = IOState $ In Console s v

-- file input
getFileInput :: Value -> StateType -> Value -> Statement
getFileInput f s v = IOState $ In (File f) s v

getFileInputLine :: Value -> Value -> Statement
getFileInputLine f v = ComplexState $ ReadLine f v

getFileInputAll :: Value -> Value -> Statement
getFileInputAll f v = ComplexState $ ReadAll f v

openFileR :: Value -> Value -> Statement
openFileR f n = IOState (OpenFile f n Read)

openFileW :: Value -> Value -> Statement
openFileW f n = IOState (OpenFile f n Write)

closeFile :: Value -> Statement
closeFile f = IOState (CloseFile f)

return :: Value -> Statement
return = RetState . Ret

returnVar :: Label -> Statement
returnVar = return . Var

switch :: Value -> [(Literal, Body)] -> Body -> Statement
switch v cs defBody = CondState $ Switch v cs defBody

throw :: String -> Statement
throw = ExceptState . Throw

tryCatch :: Body -> Body -> Statement
tryCatch tb cb = ExceptState $ TryCatch tb cb

typ :: StateType -> MethodType
typ = MState

unExpr :: UnaryOp -> Value -> Value
unExpr op v = Expr $ UnaryExpr op v

varDec :: Label -> StateType -> Statement
varDec n t = DeclState $ VarDec n t

varDecDef :: Label -> StateType -> Value -> Statement
varDecDef n t v = DeclState $ VarDecDef n t v

while :: Value -> Body -> Statement
while v b = IterState $ While v b

zipBlockWith :: (a -> b -> Statement) -> [a] -> [b] -> Block
zipBlockWith f a b = Block $ zipWith f a b

zipBlockWith4 :: (a -> b -> c -> d -> Statement) -> [a] -> [b] -> [c] -> [d] -> Block
zipBlockWith4 f a b c d = Block $ zipWith4 f a b c d

objMethodCall :: Value -> Label -> [Value] -> Value
objMethodCall o f ps = ObjAccess o $ Func f ps

objMethodCallVoid :: Value -> Label -> Value
objMethodCallVoid o f = objMethodCall o f []

valStmt :: Value -> Statement
valStmt = ValState

funcApp :: Library -> Label -> [Value] -> Value
funcApp lib lbl vs = FuncApp (Just lib) lbl vs

funcApp' :: Label -> [Value] -> Value
funcApp' lbl vs = FuncApp Nothing lbl vs

func :: Label -> [Value] -> Function
func = Func

continue :: Statement
continue = JumpState Continue

-----------------------
-- Comment Functions --
-----------------------
commentLength :: Int
commentLength = 75

endCommentLabel :: Label
endCommentLabel = "End"

addComments :: Label -> [Block] -> [Block]
addComments c ((Block ss):[]) =
    let cStart = commentDelimit c
        cEnd = endCommentDelimit c
    in [Block $ cStart : ss ++ [cEnd]]
addComments c ((Block ss1):bs) =
    let cStart = commentDelimit c
        cEnd = endCommentDelimit c
        (Block ssn) = last bs
    in Block(cStart : ss1) : (init bs) ++ [Block $ ssn ++ [cEnd]]
addComments _ [] = error "addComments on an empty Block"

comment :: Label -> Statement
comment = CommentState . Comment

commentDelimit :: Label -> Statement
commentDelimit s = CommentState $ CommentDelimit s commentLength

endCommentDelimit :: Label -> Statement
endCommentDelimit s = CommentState $ CommentDelimit (endCommentLabel ++ " " ++ s) commentLength

prefixFirstBlock :: Statement -> [Block] -> [Block]
prefixFirstBlock s ((Block ss):bs) = Block(s : ss) : bs
prefixFirstBlock _ [] = error "prefixFirstBlock called without a block"

-----------------------
-- Helper Functions --
-----------------------
getterName :: String -> String
getterName s = "Get" ++ capitalize s

setterName :: String -> String
setterName s = "Set" ++ capitalize s

convertToClass :: Class -> Class
convertToClass (MainClass n vs fs) = Class n Nothing Public vs fs
convertToClass (Enum _ _ _) = error "convertToClass: Cannot convert Enum-type Class to Class-type Class"
convertToClass c = c

convertToMethod :: Method -> Method
convertToMethod (GetMethod n t) = Method (getterName n) Public Dynamic t [] getBody
    where getBody = oneLiner $ return (Self$->(Var n))
convertToMethod (SetMethod n p@(StateParam pn _)) = Method (setterName n) Public Dynamic Void [p] setBody
    where setBody = oneLiner $ Self$->(Var n) &=. pn
convertToMethod (MainMethod b) = Method "main" Public Static Void [] b
convertToMethod t = t

-- | Takes a "find" Value (old), a "replace" Value (new),
-- and performs a find-and-replace with these Values on the specified Body.
bodyReplace :: Value -> Value -> Body -> Body
bodyReplace old new b = map fixBlockIndexes b
    where fixBlockIndexes (Block ss) = Block $ map (statementReplace old new) ss

--private functions
statementReplace :: Value -> Value -> Statement -> Statement
statementReplace old new (AssignState a) = AssignState $ assignReplace old new a
statementReplace old new (DeclState decl) = DeclState $ declReplace old new decl
statementReplace old new (CondState cond) = CondState $ condReplace old new cond
statementReplace old new (IterState iter) = IterState $ iterReplace old new iter
statementReplace old new (RetState (Ret val)) = RetState $ Ret $ valueReplace old new val
statementReplace old new (ValState val) = ValState $ valueReplace old new val
statementReplace old new (FreeState val) = FreeState $ valueReplace old new val
statementReplace _ _ s = s

assignReplace :: Value -> Value -> Assignment -> Assignment
assignReplace old new (Assign v1 v2) = Assign (valueReplace old new v1) (valueReplace old new v2)
assignReplace old new (PlusEquals v1 v2) = PlusEquals (valueReplace old new v1) (valueReplace old new v2)
assignReplace old new (PlusPlus v) = PlusPlus (valueReplace old new v)

declReplace :: Value -> Value -> Declaration -> Declaration
declReplace old new (VarDecDef lbl st val) = VarDecDef lbl st $ valueReplace old new val
declReplace old new (ObjDecDef lbl st val) = ObjDecDef lbl st $ valueReplace old new val
declReplace _ _ d = d

condReplace :: Value -> Value -> Conditional -> Conditional
condReplace old new (If vbs b) = If (zip fixedVals fixedBs) (bodyReplace old new b)
    where fixedVals = map (valueReplace old new) $ fst $ unzip vbs
          fixedBs   = map (bodyReplace old new) $ snd $ unzip vbs
condReplace old new (Switch val lbs defB) = Switch (valueReplace old new val) (zip lits fixedBs) (bodyReplace old new defB)
    where lits    = fst $ unzip lbs
          fixedBs = map (bodyReplace old new) $ snd $ unzip lbs

iterReplace :: Value -> Value -> Iteration -> Iteration
iterReplace old new (For s val s2 b) = For (statementReplace old new s) (valueReplace old new val) (statementReplace old new s2) (bodyReplace old new b)
iterReplace old new (ForEach lbl val b) = ForEach lbl (valueReplace old new val) (bodyReplace old new b)
iterReplace old new (While lbl b) = While lbl (bodyReplace old new b)

valListReplace :: Value -> Value -> [Value] -> [Value]
valListReplace old new vals = map (valueReplace old new) vals

exprReplace :: Value -> Value -> Expression -> Expression
exprReplace old new (UnaryExpr r v) = UnaryExpr r $ valueReplace old new v
exprReplace old new (BinaryExpr v1 r v2) = BinaryExpr (valueReplace old new v1) r (valueReplace old new v2)
exprReplace old new (Exists v) = Exists $ valueReplace old new v


funcReplace :: Value -> Value -> Function -> Function
funcReplace old new (Func lbl vals) = Func lbl $ valListReplace old new vals
funcReplace old new (Set lbl val) = Set lbl $ valueReplace old new val
funcReplace old new (IndexOf val) = IndexOf $ valueReplace old new val
funcReplace old new (ListAccess val) = ListAccess $ valueReplace old new val
funcReplace old new (ListAdd num val) = ListAdd (valueReplace old new num) (valueReplace old new val)
funcReplace old new (ListSet num val) = ListSet (valueReplace old new num) (valueReplace old new val)
funcReplace _ _ f = f

valueReplace :: Value -> Value -> Value -> Value
valueReplace old new v | v == old  = new
                       | otherwise = valueReplace' old new v

valueReplace' :: Value -> Value -> Value -> Value
valueReplace' old new (Expr e) = Expr $ exprReplace old new e
valueReplace' old new (FuncApp lib lbl vals) = FuncApp lib lbl $ valListReplace old new vals
valueReplace' old new (ObjAccess val f) = ObjAccess (valueReplace old new val) (funcReplace old new f)
valueReplace' old new (StateObj l st vals) = StateObj l st $ valListReplace old new vals
valueReplace' old new (ObjVar val lbl) = ObjVar (valueReplace old new val) lbl
valueReplace' _ _ v = v

toAbsCode :: Label -> [Module] -> AbstractCode
toAbsCode l m = AbsCode $ Pack l m 

getClassName :: Class -> Label
getClassName = className

buildModule :: Label -> [Library] -> [VarDecl] -> [FunctionDecl] -> [Class] -> Module
buildModule = Mod

moduleName :: Module -> Label
moduleName (Mod l _ _ _ _) = l

libs :: Module -> [Label]
libs (Mod _ ls _ _ _) = ls

classes :: Module -> [Class]
classes (Mod _ _ _ _ cs) = cs

functions :: Module -> [Method]
functions (Mod _ _ _ fs _) = fs

ignoreMain :: [Module] -> [Module]
ignoreMain ms = filter notMainModule ms

notMain :: Method -> Bool
notMain (MainMethod _) = False
notMain _              = True

notMainModule :: Module -> Bool
notMainModule m = foldl (&&) True (map notMain $ functions m)

multi :: [Statement] -> Statement
multi = MultiState




convToClass :: Module -> Module
convToClass (Mod n l vs fs cs) = Mod n l [] [] (replaceClass n cs vs fs)

replaceClass :: String -> [Class] -> [Declaration] -> [Method] -> [Class]
replaceClass n [] vs fs = [addToClass (pubClass n Nothing [] []) vs fs]
replaceClass n cs vs fs =   
  case find (\x -> className x == n) cs of Nothing -> (addToClass (pubClass n Nothing [] []) vs fs):cs
                                           Just c  -> (addToClass c vs fs):(removeClass cs)
  where removeClass [] = []
        removeClass (ch:ct) = if (className ch == n) 
                                then removeClass ct
                                else ch:removeClass ct
                                                       

addToClass :: Class -> [Declaration] -> [Method] -> Class
addToClass (Class n p s v m) ds fs = let containsMain = foldl (||) False (map isMain fs)
  in    
    if containsMain 
      then Class n p s (addToSV ds v) (addToMethod fs m)
      else MainClass n (addToSV ds v) (addToMethod fs m)
    where isMain (MainMethod _) = True
          isMain _              = False
addToClass (MainClass n v m) ds fs = MainClass n (addToSV ds v) (addToMethod fs m)
addToClass _ _ _ = error "Unsupported class for Java imperative to OO conversion"

addToMethod :: [Method] -> [Method] -> [Method]
addToMethod f m = m ++ (map fToM f)

fToM :: Method -> Method
fToM (Method l _ _ t ps b) = Method l Public Static t ps b
fToM m = m

addToSV :: [Declaration] -> [StateVar] -> [StateVar]
addToSV d sv = sv ++ (map dToSV d)

dToSV :: Declaration -> StateVar
dToSV (VarDec l s) = StateVar l Public Static s 0
dToSV (VarDecDef l s _) = StateVar l Public Static s 0
dToSV (ListDec p l s _) = StateVar l Public Static (List p s) 0
dToSV (ObjDecDef l s _) = StateVar l Public Static s 0
dToSV _ = error "Not implemented"