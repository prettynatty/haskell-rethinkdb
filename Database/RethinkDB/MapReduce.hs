module Database.RethinkDB.MapReduce where

import Control.Monad.State
import Control.Monad.Writer

import Database.RethinkDB.Protobuf.Ql2.Term2.TermType

import Database.RethinkDB.Term
import Database.RethinkDB.Objects
import {-# SOURCE #-} qualified Database.RethinkDB.Functions as R

termToMapReduce :: (Term -> Term) -> State QuerySettings (Term, Term, Term)
termToMapReduce = undefined

toReduce :: MapReduce -> MapReduce
toReduce (Map x) = MapReduce x idt []
toReduce mr = mr

idt :: Term
idt = Term $ do
        v <- newVar
        baseTerm $ op FUNC ([v], v) ()

sameVar :: BaseTerm -> BaseArray -> Bool
sameVar (BaseTerm DATUM (Just x) _ _) [BaseTerm DATUM (Just y) _ _] = x == y
sameVar _ _ = False

notNone :: MapReduce -> Bool
notNone None{} = False
notNone _ = True

wrap :: BaseTerm -> Term
wrap = Term . return

toMapReduce :: BaseTerm -> BaseTerm -> MapReduce
toMapReduce _ t@(BaseTerm DATUM _ _ _) = None $ wrap t
toMapReduce v   (BaseTerm VAR _ w _) | sameVar v w = Map []
toMapReduce v t@(BaseTerm type' _ args optargs) = let
    args' = map (toMapReduce v) args
    optargs' = map (\(BaseAttribute k vv) -> (k, toMapReduce v vv)) optargs
    count = length $ filter notNone $ args' ++ map snd optargs'
    rebuild = (if count == 1 then rebuild0 else rebuildx) type' args' optargs'
  in if count == 0 then None $ wrap t
     else if not $ count == 1
          then rebuild else
              case (type', args') of
                (MAP, [Map m, None f]) -> Map (f : m)
                (REDUCE, [Map m, None f]) -> MapReduce m f []
                (COUNT, [Map _]) -> MapReduce [expr (const $ 1 :: Term -> Term)]
                                    (expr (R.sum :: Term -> Term)) []
                _ -> rebuild

data MapReduce =
    None Term |
    Map [Term] |
    MapReduce [Term] Term [Term]

-- (TERMTYPE a (mapreduce maps reduce finals)) -> mapreduce maps reduce ((\x -> TERMTYPE a x) : finals)

rebuild0 :: TermType -> [MapReduce] -> [(Key, MapReduce)] -> MapReduce
rebuild0 ttype args optargs = MapReduce maps reduce finals where
  ([(MapReduce maps reduce tailFinals)], headFinals) = extract False ttype args optargs
  finals = headFinals : tailFinals

rebuildx :: TermType -> [MapReduce] -> [(Key, MapReduce)] -> MapReduce
rebuildx ttype args optargs = MapReduce maps reduce finals where
  (mrs, headFinals) = extract True ttype args optargs
  maps = undefined mrs
  reduce = undefined mrs
  finals = undefined mrs

extract :: Bool -> TermType -> [MapReduce] -> [(Key, MapReduce)] -> ([MapReduce], Term)
extract = undefined

extractList :: [MapReduce] -> WriterT (State ) [MapReduce] ([Term] -> Term)
extractList = undefined