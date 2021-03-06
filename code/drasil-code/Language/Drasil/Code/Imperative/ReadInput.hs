module Language.Drasil.Code.Imperative.ReadInput (
  sampleInputDD, readWithDataDesc
) where

import Language.Drasil
import Language.Drasil.Code.DataDesc (DataDesc, Data(..), DataItem, Delim,
  LinePattern(..), isJunk, junkLine, repeated, singleton, singleLine)

import Control.Lens ((^.))
import Data.List (intersperse, transpose)
import Data.List.Split (wordsBy)

readWithDataDesc :: FilePath -> DataDesc -> IO [Expr]
readWithDataDesc fp dd = do 
  ins <- readFile fp
  let readDD :: DataDesc -> [String] -> [Expr]
      readDD [] (_:_) = error "extra lines encountered in sample input file"
      readDD ds [] = if all isJunk ds then [] 
        else error "some inputs missing in sample input file"
      readDD (JunkData : ds) (_:ls) = readDD ds ls
      readDD (Singleton d : ds) (l:ls) = strAsExpr (d ^. typ) l : readDD ds ls
      readDD (Line (Straight dis) dl : ds) (l:ls) = zipWith strAsExpr (map 
        (^. typ) dis) (wordsBy (==dl) l) ++ readDD ds ls
      readDD (Line (Repeat dis) dl : ds) (l:ls) = strListsAsExprs dis 
        (groupLists dis dl l) ++ readDD ds ls
      readDD (Lines (Straight dis) (Just n) dl : ds) ls = strListsAsExprs dis 
        (transpose (map (wordsBy (==dl)) (take (fromIntegral n) ls))) 
        ++ readDD ds (drop (fromIntegral n) ls)
      readDD (Lines (Straight dis) Nothing dl : _) ls = strListsAsExprs dis 
        (transpose (map (wordsBy (==dl)) ls))
      readDD (Lines (Repeat dis) (Just n) dl : ds) ls = strLists2DAsExprs dis 
        (map (groupLists dis dl) (take (fromIntegral n) ls)) 
        ++ readDD ds (drop (fromIntegral n) ls)
      readDD (Lines (Repeat dis) Nothing dl : _) ls = strLists2DAsExprs dis 
        (map (groupLists dis dl) ls)
  return $ readDD dd (lines ins)

sampleInputDD :: [DataItem] -> DataDesc
sampleInputDD cs = junkLine : intersperse junkLine (map dataDesc cs)
  where dataDesc c = toDataDesc (c ^. typ) c
        toDataDesc (Vect _) c = singleLine (repeated [c]) ','
        toDataDesc _ c = singleton c

-- helpers

strAsExpr :: Space -> String -> Expr
strAsExpr Integer s = int (read s :: Integer)
strAsExpr Natural s = int (read s :: Integer)
strAsExpr Radians s = dbl (read s :: Double)
strAsExpr Real s = dbl (read s :: Double)
strAsExpr Rational s = dbl (read s :: Double)
strAsExpr String s = str s
strAsExpr _ _ = error "strAsExpr should only be numeric space or string"

strListsAsExprs :: [DataItem] -> [[String]] -> [Expr]
strListsAsExprs cs = zipWith ($) (map (strListAsExpr . (^. typ)) cs)
  where strListAsExpr (Vect t) ss = Matrix [map (strAsExpr t) ss]
        strListAsExpr _ _ = error "strListsAsExpr called on non-vector space"

strLists2DAsExprs :: [DataItem] -> [[[String]]] -> [Expr]
strLists2DAsExprs cs = zipWith ($) (map (strList2DAsExpr . (^. typ)) cs)
  where strList2DAsExpr (Vect (Vect t)) sss = Matrix $ 
          map (map (strAsExpr t)) sss
        strList2DAsExpr _ _ = error "strLists2DAsExprs called on non-2D-vector space"

groupLists :: [DataItem] -> Delim ->  String -> [[String]]
groupLists ds dl l = transpose $ groupAdjacent (wordsBy (==dl) l)
  where groupAdjacent [] = []
        groupAdjacent es = take n es : groupAdjacent (drop n es)
        n = length ds